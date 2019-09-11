# aws_iot

Steps:
1. Make an account on AWS.

2. Checkout Repo at linux.
├── aws_iot_configure.sh
├── aws_lambda
│   └── get_device_data.py
├── cloud_client.py
├── device_registration.sh
├── gui
│   └── index.html
├── iot-api-swagger.yaml
└── rule.json

3. On AWS 
   3.1 [On IOT Core]Create a Rule to forward all messages from [TOPIC] sensor to DynamoDB table senosor_data.
   3.2 [On Lambda] Create a lambda named get_device_data from file get_device_data.py
   3.3 Create API using iot-api-swagger.yaml
   
4. On Linux CLI / Device Registration
  4.1 Configure AWS CLI
  4.2 [Run] aws_iot_configure.sh 
  4.3 [Run]device_registration.sh <device_id> [4 times]
  
5. On Linux CLI / Device Status Data push to AWS
  5.1 [Run] python3 cloud_client.py <device_id> 
      This will send status data to AWS IoT
  
6. GUI Preparation 
   6.1 Get API SDK for GUI with javascript format. Save on Disk.
   6.2 Move index.html parallel to apigClient.js.
   6.3 Open index.html. Fill <device_id>. 



  

