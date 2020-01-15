import botocore
import datetime
import re
import logging
import json
import boto3

REGION='ap-northeast-1'
INSTANCES = ['customer-tokyo-rds']

def create_rds_snapshot():
     source = boto3.client('rds', region_name=REGION)
     for instance in INSTANCES:
         try:
             timestamp = str(datetime.datetime.now().strftime('%Y-%m-%d-%H-%M-%S'))
             snapshot = "{0}-{1}-{2}".format(instance,"snapshot",timestamp)
             print("[%s] snapshot is creating.." % snapshot)
             
             response = source.create_db_snapshot(DBSnapshotIdentifier=snapshot, DBInstanceIdentifier=instance)
             print(response)
         except botocore.exceptions.ClientError as e:
             raise Exception("Could not create snapshot: %s" % e)

def lambda_handler(event, context):
    create_rds_snapshot()
    return {
        'statusCode': 200,
        'body': json.dumps('Good Job!')
    }
