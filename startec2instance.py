import boto3

ec2 = boto3.client('ec2', region_name='ap-south-1')

def is_dev(instance):
    tag = {'Key':'Environment', 'Value':'Dev'}
    is_dev = False
    if tag in instance['Tags']:
        is_dev = True
    return is_dev

def is_stopped(instance):
    is_stopped = False
    if instance['State']['Name'] == 'stopped':
        is_stopped = True
    return is_stopped

instance_attr = ec2.describe_instances() 

reservations = instance_attr['Reservations'] 

def lambda_handler(event, context):
    for reservation in reservations: 
        for instance in reservation['Instances']: 
            if (is_dev(instance) and is_stopped(instance)): 
                instance_id = instance['InstanceId'] 
                ec2.start_instances(InstanceIds=[instance_id]) 