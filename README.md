 [![npm version](https://badge.fury.io/js/hubot-influxdb-alerts.svg)](http://badge.fury.io/js/hubot-influxdb-alerts)

# hubot-influxdb-alerts
Create and manage alerts in your chatroom using hubot and influxdb
Runs pre-set influxdb queries periodically. If any queries return a result each row generates a seperate alert into chat.

##Configuration

The following options can be set as environment variables:

	#Required
	HUBOT_INFLUXALERTS_AUTO_ALERT_ROOM #the chat room to post alerts to
	
	#Optional
	HUBOT_INFLUXALERTS_HOURS_BEFORE_REPOST #Hours between posting an unclaimed alert. Default: 3
	HUBOT_INFLUX_ALERTS_HOURS_BEFORE_ACK_REPOST #Hours between posting a claimed alert: Default 12 
	HUBOT_INFLUX_ALERT_CHECK_INTERVAL #Time in ms between running the queries 60000


The rest of the config is handled in a json file in config/hubot-influx-config.json in the project directory

Authenticate with influxdb

       {
          "connection": {
          "username": "foo-user",
          "password": "bar-password",
          "host": "localhost",
          "port": "8086"
          },
          "default_database": "my-database", #if database is not specified in query config use this

Register queries

          "queries": {
            "my-database": {

This query will only run when a user calls influx run test-no-alert. It will not generate any alerts

              "test-no-alert": {
                "query": "SOMEINFLUXDBQUERY"
              },

This query is run as part of the alert suite. For each row "template" is written to chat with the template variables
filled in using the columns in "columns".

              "test-alert": {
                "query": "select firstname,lastname from foo",
                "alert": true,
                "alert_msg": {
                  "template": "Danger, {0} {1} everything is broken",
                  "columns": ["firstname", "lastname"]
                }
              }
            }
          }
        }

##Commands

	influx alerts {off|on}  #Manually toggle alerts on or off
	influx show 		#Show Available Queries
	influx run QUERY_NAME	#Run a query
	influx alerts check	#Run all the alert queries
	influx claim ID		#Claim an alert

##Author

Alexander Welch <amwelch3 (at) gmail.com>

##License

MIT
