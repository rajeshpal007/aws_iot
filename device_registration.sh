#!/bin/sh

##########################################################################
#   EXECUTION CMD:: sh device_registration.sh {DEVICE_ID}                #
#   THIS SCRIPT ACCEPTS THREE ARGUMENT [DEVICE_ID]                       #
#   PREREQUISITE: aws cli with credential                                #
#   Owner:- Rajesh Pal for Interview with Intelligent B, Dubai           # 
##########################################################################

#-----------------------------VARIABLE DECLERATIONS--------------------------------------------
DEVICE_ID=$1
CERTIFICATE_PATH=./$DEVICE_ID
mkdir -p $CERTIFICATE_PATH > /dev/null 2>&1
TIME_STAMP="date +%Y-%m-%d.%H:%M:%S"
LOG_DIR=./
LOG_FILE=$LOG_DIR/device_provision_logs.log
PATH_PEM_KEY=$CERTIFICATE_PATH/key.pem
PATH_PEM_CRT=$CERTIFICATE_PATH/crt.pem
PATH_PEM_ROOTCA=$CERTIFICATE_PATH/AmazonRootCA1.pem
WEB_PATH_PEM_ROOTCA="https://www.amazontrust.com/repository/AmazonRootCA1.pem"

echo `aws iot create-keys-and-certificate --set-as-active --certificate-pem-outfile $PATH_PEM_CRT  --private-key-outfile $PATH_PEM_KEY` > certificate
CERTIFICATE_ARN=`cat certificate|grep  "certificateArn" |awk '{print $3}'|tr -d ,|tr -d '"'`
THING_NAME=$DEVICE_ID
THING_TYPE="iotDevice"
POLICY_NAME="iot-policy"
SHADOW_NAME="EmptyShadow"
STATUS="Provisioned"

#----------------------------CREATE AND UPDATING THING ----------------------------------------
#Creating new thing
create_thing(){
echo "[`$TIME_STAMP`] Creating thing with name:[$THING_NAME]" 2>&1 | tee -a $LOG_FILE
#Creating things
aws iot create-thing --thing-name $THING_NAME > /dev/null 2>&1
if [ $? -eq 0 ]; 
then
        echo "[`$TIME_STAMP`] Thing [$THING_NAME] successfully created" 2>&1 | tee -a $LOG_FILE
else
        echo "[`$TIME_STAMP`] Thing [$THING_NAME] creation failed" 2>&1 | tee -a $LOG_FILE
fi


#Create thing-type iotDevice
aws iot create-thing-type --thing-type-name $THING_TYPE  --thing-type-properties "thingTypeDescription=iot device type 1, searchableAttributes=device"
if [ $? -eq 0 ]; 
then
        echo "[`$TIME_STAMP`] Thing type [$THING_TYPE] successfully updated." 2>&1 | tee -a $LOG_FILE
else
        echo "[`$TIME_STAMP`] Thing type [$THING_TYPE] creation failed" 2>&1 | tee -a $LOG_FILE
fi


#Updating thing-type-name
aws iot update-thing --thing-name $THING_NAME --thing-type-name $THING_TYPE > /dev/null 2>&1
if [ $? -eq 0 ]; 
then
        echo "[`$TIME_STAMP`] Thing [$THING_NAME] successfully updated to thing type [$THING_TYPE]" 2>&1 | tee -a $LOG_FILE
else
        echo "[`$TIME_STAMP`] Thing [$THING_NAME] updation failed" 2>&1 | tee -a $LOG_FILE
fi

#Attach policy 
aws iot attach-policy --policy-name $POLICY_NAME --target $CERTIFICATE_ARN  > /dev/null 2>&1  
if [ $? -eq 0 ]; 
then
        echo "[`$TIME_STAMP`] Policy [$POLICY_NAME] successfully attached to thing [$THING_NAME]" 2>&1 | tee -a $LOG_FILE
else
        echo "[`$TIME_STAMP`] Policy [$POLICY_NAME] failed to attach to thing [$THING_NAME]" 2>&1 | tee -a $LOG_FILE
fi
}


#--------------------GET CERTIFICATES TO DEVICE -------------------------------------
attach_certificate(){
wget -O $PATH_PEM_ROOTCA $WEB_PATH_PEM_ROOTCA > /dev/null 2>&1

if [ $? -eq 0 ]; 
then
        echo "[`$TIME_STAMP`] Root certificate downloaded successfully at [$PATH_PEM_ROOTCA]" 2>&1 | tee -a $LOG_FILE
else
        echo "[`$TIME_STAMP`] Root certificate download failed." 2>&1 | tee -a $LOG_FILE
fi


aws iot attach-thing-principal --thing-name $THING_NAME --principal $CERTIFICATE_ARN > /dev/null 2>&1
if [ $? -eq 0 ]; 
then
        echo "[`$TIME_STAMP`] Thing [$THING_NAME] successfully attached to ARN  [$CERTIFICATE_ARN]" 2>&1 | tee -a $LOG_FILE
else
        echo "[`$TIME_STAMP`] Thing [$THING_NAME] failed to attach to[$CERTIFICATE_ARN]" 2>&1 | tee -a $LOG_FILE
fi
}


#-----------------------------------CERTIFICATE DELETE------------------------------------------------------
update_cert(){
CERT_ARN=`aws iot list-thing-principals --thing-name $THING_NAME|grep arn|tr -d '", '`
CERT_ID=`aws iot list-thing-principals --thing-name $THING_NAME|grep arn|tr -d '", '|cut -d / -f 2`
aws iot list-policies | jq '.policies|.[]|.policyName' | tr -d '"' > policy
aws iot detach-thing-principal --thing-name $THING_NAME --principal $CERT_ARN
while read policyName; 
do
aws iot detach-policy --policy-name  $policyName --target $CERT_ARN
done <policy
aws iot update-certificate --certificate-id $CERT_ID --new-status INACTIVE
aws iot delete-certificate --certificate-id $CERT_ID
if [ $? -eq 0 ];
then
        echo "[`$TIME_STAMP`] Certificate with certificateID [$CERTIFICATE_ARN] successfully deleted" 2>&1 | tee -a $LOG_FILE
fi
}


#-----------------------------------FUNCTION CALLS-------------------------------------
if [ -z "$1" ] ;
then
        echo "[`$TIME_STAMP`] Argument [Device Id] missing" 2>&1 | tee -a $LOG_FILE
else
        #checking if thing already exists 
        aws iot list-things | jq '.things|.[]|.thingName' | tr -d '"' | grep $THING_NAME  > /dev/null 2>&1 
if [ $? -eq 0 ]; 
then
        echo "[`$TIME_STAMP`] Thing [$THING_NAME] already exists" 2>&1 | tee -a $LOG_FILE

#check to get if certificate is attached
CERT_COUNT=`aws iot list-thing-principals --thing-name $THING_NAME|grep arn|tr -d '", '|wc -l`
if [ $CERT_COUNT -gt 0 ];
then 
        update_cert
fi

else
        create_thing
        attach_certificate
fi

fi

rm -rf *certificate*
