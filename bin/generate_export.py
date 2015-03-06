#! /usr/bin/env python
import json
import os

CONFIG_FILE = "../config/hubot-influx-config.json"

#Write each key as an environment variable

f = json.load(open(CONFIG_FILE))

buf = 'export '

for k,v in f.iteritems():
    buf += "{}='{}' ".format(k,json.dumps(v))

buf += '; echo "Environment set!"'
#Output the command
print buf
