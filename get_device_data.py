#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
@author: rajesh
"""
import json
import os
import boto3
import logging
from datetime import datetime, timedelta
from boto3.dynamodb.conditions import Attr, Key
from dateutil.relativedelta import relativedelta
from datetime import date

os.environ['AWS_DEFAULT_REGION'] = 'us-east-2'
os.environ['AWS_DYNAMODB_ENDPOINT'] = 'https://dynamodb.us-east-2.amazonaws.com'

def get_all(device_id):
    table = "sensor_data"
    dbClient = boto3.resource('dynamodb',
                              region_name = os.environ['AWS_DEFAULT_REGION'],
                              endpoint_url = os.environ['AWS_DYNAMODB_ENDPOINT'])
    association = dbClient.Table(table)
    try:
        response = association.scan(
               FilterExpression=Attr('device_id').contains(device_id),
           )
    except:
        print("Error: I know")
    print(response)
    if response['ResponseMetadata']['HTTPStatusCode'] != 200:
        response = {'status': 400, 'message': "Bad input.", "data" : ""}
        return response

    if "Items" in response:
        items = response['Items']
        len_items = len(items)
    else:
        print("None")
        len_items = 0
        
    if len_items == 0:
        response = {'status': 400, 'message': "Device not found"}
        return response
    
    else:
      status_list = []
      status_info = {}
      for dp in items:
        print(dp)
        status_info = {"status": dp["status"], "device_id": dp['device_id'], "time": dp["sort_key"]}
        status_list.append(status_info)

    return status_list

def lambda_handler(event, context):
    print( event)
    if 0 == len(event) or None == event:
        print( 'Nothing to do')
        response = {'status': 400, 'message': "Bad input.", "data" : ""}
        return response

    if 'data' not in event:
        print( 'Nothing to do')
        response = {'status': 400, 'message': "Bad input.", "data" : ""}
        return response

    dataset = event['data']

    if len(dataset) == 0:
        response = {'status': 400, 'message': "Bad input."}
        return response

    #return dataset
    item = dataset["device_id"]
    #return item
    if item != "":
        clist = get_all(item)
        return clist
    response = {'status': 400, 'message': "device_id is mandatory."}
    return response
#lambda_handler(event=None, context=None)