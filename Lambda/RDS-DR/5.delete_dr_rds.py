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
        
def byTimestamp(instance):
    if 'InstanceCreateTime' in instance:
        return datetime.datetime.isoformat(instance['InstanceCreateTime'])
    else:
        return datetime.datetime.isoformat(datetime.datetime.now())
    
    
def del_prev_rds():
    account = get_account()
    source_client = boto3.client('rds', SOURCE_REGION)
    
    INSTANCES = source_client.describe_db_instances()
    FILTERED_INSTANCES = filter(lambda x: x["DBInstanceIdentifier"].startswith(INSTANCE_PREFIX), INSTANCES["DBInstances"])
    SORTED_INSTANCES = sorted(FILTERED_INSTANCES, key=byTimestamp, reverse=True)
    latest_instance_id = SORTED_INSTANCES[0]["DBInstanceIdentifier"]
    
    for instance in SORTED_INSTANCES:
        db_instance_id = instance["DBInstanceIdentifier"]

        if latest_instance_id == db_instance_id:
            print('[%s] is lastest. Not delete.' % (db_instance_id))
            continue
        else:
            try:
                response = source_client.delete_db_instance(
                    DBInstanceIdentifier=db_instance_id,
                    SkipFinalSnapshot=True
                    )
                    
                print('[%s] deleting..' % (db_instance_id))
                # print(response)
                
            except botocore.exceptions.ClientError as e:
                print(e)
            

##
def lambda_handler(event, context):
    del_prev_rds()
    return {
        'statusCode': 200,
        'body': json.dumps('Good Job!')
    }

if __name__ == '__main__':
    lambda_handler(None, None)