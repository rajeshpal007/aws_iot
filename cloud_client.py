# -*- coding: utf-8 -*-
"""
Created on Tue Sept 1013 17:15:39 2019

@author: Rajesh Kumar Pal
@parameters: device_id

This program sends a randomly selected status to AWS IOT.
    all_status = ["boot", "shutdown", "good", "faulty_001", "faulty_002", "faulty_003"]
    Sent : {'device_id': '20', 'status': 'boot', 'date': '2019-09-11 13:35:35.381172'}
"""

import sys
import random
from datetime import datetime
import json
import logging
import time

# Import SDK packages
from AWSIoTPythonSDK.MQTTLib import AWSIoTMQTTClient
from AWSIoTPythonSDK.MQTTLib import AWSIoTMQTTShadowClient
from AWSIoTPythonSDK.exception.AWSIoTExceptions import connectTimeoutException, subscribeTimeoutException, disconnectTimeoutException

arguments = sys.argv[1:]
count = len(arguments)
device_id = str(sys.argv[1])

IOT_AWS_END_POINT = "a2rsf4h7v07xok-ats.iot.us-west-2.amazonaws.com"
ROOT_PEM = "./" + device_id + "/" + "AmazonRootCA1.pem"
PEM_KEY = "./" + device_id + "/" + "key.pem"
PEM_CRT = "./" + device_id + "/" + "crt.pem"

#Create and configure logger 
logging.basicConfig(filename="newfile.log", 
                    format='%(asctime)s %(message)s', 
                    filemode='w') 
  
#Creating log object 
log=logging.getLogger() 

def configure_for_cert():
    myMQTTClient = AWSIoTMQTTClient(device_id)
    myMQTTClient.configureEndpoint( IOT_AWS_END_POINT, 8883)
    myMQTTClient.configureCredentials(ROOT_PEM,
                                  PEM_KEY,
                                  PEM_CRT)

    myMQTTClient.configureOfflinePublishQueueing(-1)    # Infinite offline Publish queueing
    myMQTTClient.configureDrainingFrequency(2)          # Draining: 2 Hz
    myMQTTClient.configureConnectDisconnectTimeout(20)  # 10 sec
    myMQTTClient.configureMQTTOperationTimeout(20)      # 5 sec
    return myMQTTClient

def reliable_connect(client):
    can_still_retry = 3
    connection_status = False

    while can_still_retry != 0 and connection_status == False:
        try:
            #print("Try " + str(4 - can_still_retry))
            can_still_retry = can_still_retry - 1
            connection_status = client.connect()
        except connectTimeoutException:
            # log the failure
            log.critical("Connection timed out")
            if can_still_retry != 0:
                continue
    return connection_status


def upload_device_status__random():

    all_status = ["boot", "shutdown", "good", "faulty_001", "faulty_002", "faulty_003"]
    status = random.choice(all_status)
    time_now = datetime.now() # current date and time

    mqttclient = configure_for_cert()
    connection_status = False
    mqttclient.connect()

    message_json = {'device_id': device_id,'status': status, 'date': str(time_now)}
    connection_status = reliable_connect(mqttclient)
    if connection_status == False:
        log.info("Connection timed out. Will try after some time.")
        return

    mqttclient.publish("sensor", json.dumps(message_json), 0)
    print ("Sent : " + str(message_json))
    mqttclient.disconnect()


if __name__ == '__main__':
    # Let the world know that I am still running
    if device_id == None or device_id == '':
        log.critical("Can't do anything without device id.")
    upload_device_status__random()
    # Let the world know that I am done
