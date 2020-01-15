import boto3
import operator
import botocore
import datetime
import re
import json

SOURCE_REGION = 'ap-northeast-2'
DB_SUBNET_GRP = 'customer-ora112-sub-grp'
DB_OPTION_GRP = 'customer-ora112-opt-grp'
DB_PARAM_GRP = 'customer-ora112-para-grp'
INSTANCES = ['customer-tokyo-rds']

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
        
##
def restore_latest_snapshot():
    account = get_account()
    source_client = boto3.client('rds', SOURCE_REGION)
    
    response = source_client.describe_db_snapshots(
        SnapshotType='automated',
        IncludeShared=False,
        IncludePublic=False
    )
    
    source = boto3.client('rds', region_name=SOURCE_REGION)
    
    for instance in INSTANCES:
        source_snaps = source.describe_db_snapshots(DBInstanceIdentifier=instance)['DBSnapshots']
        lastest_source_snap = sorted(source_snaps, key=byTimestamp, reverse=True)[0]['DBSnapshotIdentifier']
        lastest_source_snap_arn = sorted(source_snaps, key=byTimestamp, reverse=True)[0]['DBSnapshotArn']
        instance_id = (re.sub('copy-', '', lastest_source_snap))
                
        print('>>>>> lastest_source_snap >>>>>')
        print(lastest_source_snap)
        
        print('Will Restore [%s] from snapshot [%s] ' % (instance_id, lastest_source_snap))
        
        try:
            source.describe_db_instances(
                DBInstanceIdentifier=instance_id
            )
        except botocore.exceptions.ClientError as e:
            print(e)
                        
            response = source.restore_db_instance_from_db_snapshot(
                DBInstanceIdentifier=instance_id,  #Required
                DBSnapshotIdentifier=lastest_source_snap,  #Required
                DBInstanceClass='db.r5.large',
                Port=1521,
                AvailabilityZone='ap-northeast-2a',
                DBSubnetGroupName=DB_SUBNET_GRP,
                MultiAZ=False,
                PubliclyAccessible=False,
                AutoMinorVersionUpgrade=False,
                LicenseModel='license-included',
                DBName='ORCL',
                OptionGroupName=DB_OPTION_GRP,
                VpcSecurityGroupIds=[
                    'sg-016fdc0eff80c740f'
                ],
                CopyTagsToSnapshot=True,
                DBParameterGroupName=DB_PARAM_GRP,
                DeletionProtection=False
            )
            
            if response['ResponseMetadata']['HTTPStatusCode'] != 200:
                raise Exception("Restore operation for " + instance_id + " failed! Process is " + response['DBInstance']['DBInstanceStatus'])
            print("[" + instance_id + "] Restoring Job is ok. Process is " + response['DBInstance']['DBInstanceStatus'] + ".")
            
            continue
            
        print('Already restored.')
        
        
##
def lambda_handler(event, context):
    restore_latest_snapshot()
    return {
        'statusCode': 200,
        'body': json.dumps('Good Job!')
    }

if __name__ == '__main__':
    lambda_handler(None, None)