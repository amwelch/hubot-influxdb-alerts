[![Build Status](https://travis-ci.org/amwelch-oss/hubot-influxdb-alerts.svg?branch=master)](https://travis-ci.org/amwelch-oss/hubot-influxdb-alerts) [![npm version](https://badge.fury.io/js/hubot-influxdb-alerts.svg)](http://badge.fury.io/js/hubot-influxdb-alerts)

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

###Note: This is a temporary measure. I will add in a better way to do the complex config shortly
The rest of the config is handled in a json file in config/hubot-influx-config.json in the project directory
	#Used to connect to influx
	"connection": {
          "username": "foo-user",
          "password": "bar-password",
          "host": "localhost",
          "port": "8086
 	},
	"default_database": "my-database" #if database is not specified in query config use this
 	"queries": {
		"my-database":{
			#This query will only run when the user specifies it with influx run test-no-alert. It does not generate any alerts
			"test-no-alert": {	
				"query": "SOMEINFLUXDBQUERY"
			},
			"test-alert": {
				#This query will send the error message "template" to chat for every row that returns. The template will be filled in with the columns in "columns".
				"query": "select firstname,lastname from foo",
				"alert": true",
				"alert_msg": {
					"template": "Danger, {0} {1} everything is broken",
					"columns": ["firstname", "lastname"]
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
