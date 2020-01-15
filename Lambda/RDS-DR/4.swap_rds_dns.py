import boto3
import botocore
import datetime
import json

SOURCE_REGION = 'ap-northeast-2'
HOSTED_ZONE_NAME = 'rds.dr.internal'
RECORD_SET_NAME = 'customer.rds.dr.internal'
INSTANCE_PREFIX = 'customer-tokyo-rds'

iam = boto3.client('iam')

        
def byTimestamp(instance):
    if 'InstanceCreateTime' in instance:
        return datetime.datetime.isoformat(instance['InstanceCreateTime'])
    else:
        return datetime.datetime.isoformat(datetime.datetime.now())
    
    
def swap_rds_dns():
    # rds
    rds_client = boto3.client('rds', SOURCE_REGION)
    
    INSTANCES = rds_client.describe_db_instances()
    FILTERED_INSTANCES = filter(lambda x: x["DBInstanceIdentifier"].startswith(INSTANCE_PREFIX), INSTANCES["DBInstances"])
    SORTED_INSTANCES = sorted(FILTERED_INSTANCES, key=byTimestamp, reverse=True)
    latest_instance_id = SORTED_INSTANCES[0]["DBInstanceIdentifier"]
    
    print(">>> " + latest_instance_id)
    
    # route53
    route53_client = boto3.client('route53')
    
    HOSTED_ZONES = route53_client.list_hosted_zones()
    FILTERED_HOSTED = filter(lambda x: x["Name"].startswith(HOSTED_ZONE_NAME), HOSTED_ZONES["HostedZones"])
    
    hosted_zone_id = FILTERED_HOSTED[0]['Id']
    latest_instance_dns = SORTED_INSTANCES[0]["Endpoint"]["Address"]
    
    print(">>> hosted_zone_id >>> " + hosted_zone_id)
    print(">>> record_set_name >>> " + RECORD_SET_NAME)
    print(">>> latest_instance_dns >>> " + latest_instance_dns)
        
    try:
        response = route53_client.change_resource_record_sets(
            HostedZoneId=hosted_zone_id,
            ChangeBatch={
                'Changes': [
                    {
                        'Action': 'UPSERT',
                        'ResourceRecordSet': {
                            'Name': RECORD_SET_NAME,
                            'Type': 'CNAME',
                            'TTL': 300,
                            'ResourceRecords': [
                                {
                                    'Value': latest_instance_dns
                                }
                            ]
                        }
                    }
                ]
            }
        )
            
        print('[%s] record is changed [%s]' % (RECORD_SET_NAME,latest_instance_dns))
        print(response)
        
    except botocore.exceptions.ClientError as e:
        print(e)
        

##
def lambda_handler(event, context):
    swap_rds_dns()
    return {
        'statusCode': 200,
        'body': json.dumps('Good Job!')
    }

if __name__ == '__main__':
    lambda_handler(None, None)