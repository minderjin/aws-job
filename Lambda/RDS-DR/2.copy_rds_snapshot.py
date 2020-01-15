import boto3
import operator
import botocore
import datetime
import re
import json

SOURCE_REGION = 'ap-northeast-1'
TARGET_REGION = 'ap-northeast-2'
DB_OPTION_GRP = 'customer-rds-ora112-opt-grp'
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

##
def byTimestamp(snap):
    if 'SnapshotCreateTime' in snap:
        return datetime.datetime.isoformat(snap['SnapshotCreateTime'])
    else:
        return datetime.datetime.isoformat(datetime.datetime.now())

##
def copy_latest_snapshot():
    account = get_account();
    source_client = boto3.client('rds', SOURCE_REGION)
    target_client = boto3.client('rds', TARGET_REGION)

    response = source_client.describe_db_snapshots(
        SnapshotType='manual',
        IncludeShared=False,
        IncludePublic=False
    )

    if len(response['DBSnapshots']) == 0:
        raise Exception("No automated snapshots found")
    
    snapshots_per_project = {}
    for snapshot in response['DBSnapshots']:        
        if snapshot['Status'] != 'available':
            continue
            
        if snapshot['DBInstanceIdentifier'] != INSTANCES[0]:
            continue
        
        if snapshot['DBInstanceIdentifier'] not in snapshots_per_project.keys():
            snapshots_per_project[snapshot['DBInstanceIdentifier']] = {}

        snapshots_per_project[snapshot['DBInstanceIdentifier']][snapshot['DBSnapshotIdentifier']] = snapshot['SnapshotCreateTime']
    
    
    for project in snapshots_per_project:
        sorted_list = sorted(snapshots_per_project[project].items(), key=operator.itemgetter(1), reverse=True)
        source_snap = sorted_list[0][0];
        copy_name = (re.sub('lambda-', 'copy-', source_snap))
        
        print(copy_name)

        try:
            target_client.describe_db_snapshots(
                DBSnapshotIdentifier=copy_name
            )
        except:
            source_snap_arn = 'arn:aws:rds:%s:%s:snapshot:%s' %  (SOURCE_REGION, account, source_snap)
                    
            response = target_client.copy_db_snapshot(
                SourceDBSnapshotIdentifier=source_snap_arn,
                TargetDBSnapshotIdentifier=copy_name,
                CopyTags=True,
                OptionGroupName=DB_OPTION_GRP
            )
            print(response)

            if response['DBSnapshot']['Status'] != "pending" and response['DBSnapshot']['Status'] != "available":
                raise Exception("Copy operation for " + copy_name + " failed!")
                
            print("Copied " + source_snap)

            continue

        print("Already copied")
        
##
def remove_old_snapshots():
    #source_client = boto3.client('rds', SOURCE_REGION)
    target_client = boto3.client('rds', TARGET_REGION)

    response = target_client.describe_db_snapshots(
        SnapshotType='manual'
    )

    if len(response['DBSnapshots']) == 0:
        raise Exception("No manual snapshots in Frankfurt found")

    snapshots_per_project = {}
    for snapshot in response['DBSnapshots']:
        if snapshot['Status'] != 'available':
            continue

        if snapshot['DBInstanceIdentifier'] not in snapshots_per_project.keys():
            snapshots_per_project[snapshot['DBInstanceIdentifier']] = {}

        snapshots_per_project[snapshot['DBInstanceIdentifier']][snapshot['DBSnapshotIdentifier']] = snapshot[
            'SnapshotCreateTime']

    for project in snapshots_per_project:
        if len(snapshots_per_project[project]) > 1:
            sorted_list = sorted(snapshots_per_project[project].items(), key=operator.itemgetter(1), reverse=True)
            to_remove = [i[0] for i in sorted_list[1:]]

            for snapshot in to_remove:
                print("Removing " + snapshot)
                target_client.delete_db_snapshot(
                    DBSnapshotIdentifier=snapshot
                )

##
def lambda_handler(event, context):
    copy_latest_snapshot()
    # remove_old_snapshots()
    return {
        'statusCode': 200,
        'body': json.dumps('Good Job!')
    }

if __name__ == '__main__':
    lambda_handler(None, None)