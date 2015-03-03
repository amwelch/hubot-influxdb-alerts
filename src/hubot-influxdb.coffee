influx = require('../node_modules/influx')
nconf = require("nconf")

cwd = process.cwd()

DEFAULTS_FILE = "#{__dirname}/data/defaults.json"
CONFIG_FILE = "#{cwd}/config/hubot-influx-config.json"

a = require(DEFAULTS_FILE)
b = require(CONFIG_FILE)

nconf.argv()
    .env()
    .file('environment', CONFIG_FILE)
    .file('defaults', DEFAULTS_FILE)

show_help = (msg) ->
  default_db = nconf.get("default_database")
 
  if !default_db
    default_db = "None Set"

  buf = "Influx for Hubot\n\n"
  buf += "Commands: \n"
  buf += nconf.get("COMMAND_STRINGS").join("\n")
  buf += "\n\n"
  buf += "Default Database: #{default_db}"

  msg.send buf

new_alert = (robot, msg, query_name, data, columns) ->
  alert_key = _form_alert_key(query_name, data, columns, [])

  #Used to lookup the hashed key when a user acks an alert
  id = Math.floor(Math.random()*nconf.get("HUBOT_INFLUXALERTS_RANDOM_ID_MAX"))
  alert_id = "incident_#{id}"
  robot.brain.set(alert_id, alert_key)

#  msg.send "Setting #{alert_id} #{alert_key}"

  database =  find_query_db(query_name)

  query_config = nconf.get("queries")[database][query_name]
 
  event =
      status: nconf.get("OPEN")
      assigned: 0
      ts: (new Date).getTime()

  serialized = JSON.stringify(event)
  robot.brain.set(alert_key, serialized)

  buf = make_alert_message(query_config, data, columns, msg)
  buf += "\n"
  buf += "To claim this alert use the id #{id}. \"influx claim #{id}\"\n"
  msg.send buf


make_alert_message = (query_object, data, columns, msg) ->
  query_columns = query_object.alert_msg.columns
  template = query_object.alert_msg.template
  for col,i in query_object.alert_msg.columns
    template = template.replace("{#{i}}", data[columns.indexOf(col)])
  return template

hashCode = (str) ->
  hash = 0
  if (str.length == 0)
    return hash
  for i in str
    char = str.charCodeAt(i)
    hash = ((hash<<5)-hash)+char
    hash = hash & hash
  
  hash


_form_alert_key = (query_name, points, columns, ignore_fields) ->

  if !ignore_fields
    ignore_fields = []

  #Default ignore
  ignore_fields.push("metric")
  
  hash_points = []
  for col,i in columns
    if col in ignore_fields
      continue
    hash_points.push points[i]
          
  hashCode(query_name + hash_points.join(""))

ack_alert = (robot, msg, id, user) ->
  alert_key = robot.brain.get("incident_#{id}")
  if !alert_key
    msg.send "Didn't recognize alert with id #{id}. Please try again."
  else
    alert_str = robot.brain.get(alert_key)
    if !alert_str
      msg.send "There was an error retrieving this alert"
    else
      alert = JSON.parse(alert_str)
      alert.ack_ts = (new Date).getTime()
      alert.ack_user = user
      alert.status = nconf.get("ACK")
      robot.brain.set(alert_key, JSON.stringify(alert))
      buf= "Thank you #{user} for handling alert #{id}!\n"
      buf += "You get a gold star (goldstar)."
      msg.send buf

process_alert = (robot, msg, query_name, data, columns) ->
  alert_key = _form_alert_key(query_name, data, columns, [])
  alert = robot.brain.get(alert_key)
  if alert
    alert_obj = JSON.parse(alert)
    #If it's been acknowledged wait 6 hours before reposting
    if alert_obj.status == nconf.get("ACK")
      ack_ts = alert_obj.ack_ts
      cur_ts = (new Date).getTime()
      hours = nconf.get("HUBOT_INFLUXALERTS_HOURS_BEFORE_ACK_REPOST")
      interval = nconf.get("ONE_HOUR_MS")*hours
      if cur_ts - ack_ts > interval

        new_alert(robot, msg, query_name, data, columns)
                    
    else
      created_ts = alert_obj.ts
      cur_ts = (new Date).getTime()
      hours = nconf.get("HUBOT_INFLUXALERTS_HOURS_BEFORE_REPOST")
      interval = nconf.get("ONE_HOUR_MS")*hours
      if cur_ts - created_ts > interval

        new_alert(robot, msg, query_name, data, columns)
      else
          
  else
    new_alert(robot, msg, query_name, data, columns)
       

influx_clients = {}

connect = ->
  #Client for each database
  influx_connect_config = nconf.get("connection")

  queries = nconf.get("queries")
  if queries
    for database in Object.keys(nconf.get("queries"))
      if (!influx_clients[database])
        influx_connect_config['database'] = database
        influx_clients[database] = influx(influx_connect_config)

print_queries = (msg) ->
  query_config = nconf.get("queries")
  if !query_config
    msg.send "No queries configured"
    return

  buf = ""
  for database in Object.keys(query_config)
    buf += "Database: #{database}\n"
    queries = query_config[database]
    for query_name in Object.keys(queries)
      query = queries[query_name].query
      buf += "\t#{query_name}:\t#{query}\n"
  msg.send buf

user_query = (query_str, database, msg) ->
  influx_connect_config = nconf.get("connection")
  if !influx_clients[database]
    influx_connect_config['database'] = database
    influx_clients[database] = influx(influx_connect_config)

  influx_clients[database].query(query_str, (e, return_series) ->
    msg.send format_query_result(return_series)
  )

find_query_db = (query_name) ->
  query_config = nconf.get("queries")
  query_db = false
  for database in Object.keys(query_config)
    for q in Object.keys(query_config[database])
      if (query_name == q)
        query_db = database
  return query_db

run_query = (query_name, msg) ->
  query_config = nconf.get("queries")
  query_db = find_query_db(query_name)

  if !query_db
    buf = "Could not find #{query_name}.\n"
    buf += "To see available queries run \"influx show\"\n"
    buf += "To run an arbitrary query use \"influx query\"\n"
    msg.send buf
  else
    query = query_config[query_db][query_name].query
    influx_clients[query_db].query(query, (e, return_series) ->
      msg.send format_query_result(return_series)
    )

format_query_result = (query_json) ->
  for result in query_json
    columns = result.columns
    data = result.points
    buf = columns.join("\t\t") + "\n"
    for row in data
      buf += row.join("\t\t") + "\n"

  buf += "\n"
  return buf
        

check_alert = (robot, msg, query_name, query, database) ->
  influx_clients[database].query(query, (e, results) ->
    for data in results
      columns = data.columns
      for result in data.points
        process_alert(robot, msg, query_name, result, columns)
  )


check_for_alerts = (robot, msg) ->
  connect()
  for database in Object.keys(nconf.get("queries"))
    for query_name in Object.keys(nconf.get("queries")[database])
      query_config = nconf.get("queries")[database][query_name]
      if query_config.alert
        query = query_config.query
        check_alert(robot, msg, query_name, query, database)

module.exports = (robot) ->

  alertIntervalId = false

  robot.hear /influx alerts on/i, (msg) ->
    if alertIntervalId
      msg.send "Alert checking already on"
      return

    alertIntervalId = setInterval () ->
      check_for_alerts(robot, msg)
    , nconf.get("ALERT_HUBOT_INFLUXALERTS_CHECK_INTERVAL")
    msg.send "Alert checking toggled on (corpsethumb)"

  robot.hear /influx alerts off/i, (msg) ->
    if !alertIntervalId
      msg.send "Alert checking already off (dealwithit)"
      return
    clearInterval(alertIntervalId)
    msg.send "Alert checking toggled off (okay)"

  robot.hear /influx show/i, (msg) ->
    connect()
    print_queries(msg)

  robot.hear /influx run (.*)/i, (msg) ->
    connect()
    run_query(msg.match[1], msg)

  robot.hear /influx query (.*)/i, (msg) ->
    query_pat = ///\"([^\"]+)\"\s*([^\s]*)///i

    msg.send msg.match[1]
    
    query_args = msg.match[1].match query_pat
    if !query_args
      buf = "Badly formatted query args."
      buf += "influx query \"QUERY\" [database]"
      msg.send buf

      return
          
    query = query_args[1]
    database = query_args[2]
    if not database
      database = nconf.get("default_database")
      if not database
        msg.send "No Database specified and no default set. Cannot query"
        return
      msg.send "Using default database #{database}"

    user_query(query, database, msg)

  robot.hear /influx help/i, (msg) ->
    show_help(msg)

  robot.hear /influx alerts check/i, (msg) ->
    connect()
    check_for_alerts(robot, msg)

  robot.hear /influx claim (.*)/i, (msg) ->
    id = msg.match[1]
    user = msg.message.user.name
    ack_alert(robot, msg, id, user)

