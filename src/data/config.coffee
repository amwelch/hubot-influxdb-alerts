nconf = require('nconf')
defaults = require('hubot-influx-defaults.json')

#Args, env, config file

#States for an alert
exports.OPEN = 0
exports.ACK  = 1

CONFIG_FILE = "../../config/hubot-influx-config.json"
options = 
    store: defaults

nconf.argv().env().file({file: CONFIG_FILE}).defaults(options)

#Alerts are assigned a random id betwen [0, max - 1]
exports.RANDOM_ID_MAX = 1001

#Timing
exports.ONE_HOUR_MS = 1000*60*60

#Help Text
exports.commands = [
]

#TODO set these from env variables

timing_variables = [
    "hours_before_repost"
    "hours_before_ack_repost"
    "alert_check_interval"
]

for variable in timing_variables
  exports[variable] = nconf.get(variable)
