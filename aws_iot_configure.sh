#!/bin/sh

##########################################################################
#   EXECUTION CMD:: sh aws_iot_configure.sh                              #
#   PREREQUISITE: aws cli with credential                                #
#   Owner:- Rajesh Pal for Interview with Intelligent B, Dubai           # 
##########################################################################

#-----------------------------VARIABLE DECLERATIONS--------------------------------------------
TIME_STAMP="date +%Y-%m-%d.%H:%M:%S"
LOG_DIR=./
LOG_FILE=$LOG_DIR/device_provision_logs.log
POLICY_FILE="file://policy.json"

THING_TYPE="iotDevice"
POLICY_NAME="iot-policy"

#----------------------------CREATE THING TYPE AND POLICY --------------------------------------
#Create thing-type iotDevice
create_thing_type(){
aws iot create-thing-type --thing-type-name $THING_TYPE  --thing-type-properties "thingTypeDescription=iot device type 1, searchableAttributes=device"
if [ $? -eq 0 ]; 
then
        echo "[`$TIME_STAMP`] Thing type [$THING_TYPE] successfully created." 2>&1 | tee -a $LOG_FILE
else
        echo "[`$TIME_STAMP`] Thing type [$THING_TYPE] creation failed" 2>&1 | tee -a $LOG_FILE
fi
}

#Create policy
create_policy(){
aws iot create-policy --policy-name $POLICY_NAME --policy-document $POLICY_FILE

if [ $? -eq 0 ]; 
then
        echo "[`$TIME_STAMP`] Policy [$POLICY_NAME] successfully created" 2>&1 | tee -a $LOG_FILE
else
        echo "[`$TIME_STAMP`] Policy [$POLICY_NAME] creation failed" 2>&1 | tee -a $LOG_FILE
fi
}

#-----------------------------------FUNCTION CALLS-------------------------------------
create_thing_type
create_policy