import boto3
import operator
import botocore
import datetime
import re
import json

SOURCE_REGION = 'ap-northeast-2'
INSTANCE_PREFIX = 'customer-tokyo-rds'

iam = boto3.client('iam')


##
def get_account():
    account_ids = []
    try:
        iam.get_user()
    except Exception as e:
        account_ids.append(re.search(r'(arn:aws:sts::)([0-9]+)', str(e)).groups()[1])
        ACCOUNT = account_ids[0]
        
        return ACCOUNT
        
def byTimestamp(snap):
    if 'SnapshotCreateTime' in snap:
        return datetime.datetime.isoformat(snap['SnapshotCreateTime'])
    else:
        return datetime.datetime.isoformat(datetime.datetime.now())
    
    
def stop_prev_rds():
    account = get_account()
    source_client = boto3.client('rds', SOURCE_REGION)
    
    INSTANCES = source_client.describe_db_instances()
    for instance in INSTANCES["DBInstances"]:
        db_instance_id = instance["DBInstanceIdentifier"]
        
        if db_instance_id.startswith(INSTANCE_PREFIX):
            try:
                response = source_client.stop_db_instance(
                    DBInstanceIdentifier=db_instance_id
                    )
                    
                print('[%s] stopping..' % (db_instance_id))
                # print(response)
                
            except botocore.exceptions.ClientError as e:
                print(e)
            
        else:
            continue
        
        
##
def lambda_handler(event, context):
    stop_prev_rds()
    return {
        'statusCode': 200,
        'body': json.dumps('Good Job!')
    }

if __name__ == '__main__':
    lambda_handler(None, None)