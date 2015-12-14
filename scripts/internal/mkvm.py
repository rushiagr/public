import boto3
import sys

#todo http://boto3.readthedocs.org/en/latest/reference/services/ec2.html#EC2.ServiceResource.create_instances

ec2 = boto3.resource('ec2')

flavor_names = ['t1.micro', 'm1.small', 'm1.medium', 'm1.large', 'm1.xlarge', 'm3.medium', 'm3.large', 'm3.xlarge', 'm3.2xlarge', 'm4.large', 'm4.xlarge', 'm4.2xlarge', 'm4.4xlarge', 'm4.10xlarge', 't2.micro', 't2.small', 't2.medium', 't2.large', 'm2.xlarge', 'm2.2xlarge', 'm2.4xlarge', 'cr1.8xlarge', 'i2.xlarge', 'i2.2xlarge', 'i2.4xlarge', 'i2.8xlarge', 'hi1.4xlarge', 'hs1.8xlarge', 'c1.medium', 'c1.xlarge', 'c3.large', 'c3.xlarge', 'c3.2xlarge', 'c3.4xlarge', 'c3.8xlarge', 'c4.large', 'c4.xlarge', 'c4.2xlarge', 'c4.4xlarge', 'c4.8xlarge', 'cc1.4xlarge', 'cc2.8xlarge', 'g2.2xlarge', 'cg1.4xlarge', 'r3.large', 'r3.xlarge', 'r3.2xlarge', 'r3.4xlarge', 'r3.8xlarge', 'd2.xlarge', 'd2.2xlarge', 'd2.4xlarge', 'd2.8xlarge']

print 'Only Ubuntu image supported as of now'

selected_flavor=''
while True:
    sys.stdout.write("Select flavor ['l' to list]: ")
    flavor=raw_input()
    if flavor.lower() == 'l':
        print flavor_names
        continue
    elif flavor in flavor_names:
        selected_flavor=flavor
        break
    else:
        print 'Invalid flavor name.'

keypairs = ec2.key_pairs.all()
keypair_names = [kp.name for kp in keypairs]
print 'Available key pairs:', keypair_names
sys.stdout.write("Select keypair: ")
selected_keypair=raw_input()

secgroups = ec2.security_groups.all()
secgroups = [sg for sg in secgroups]
secgroup_name_id_dict = {}
for sg in secgroups:
    if sg.tags is not None:
        secgroup_name_id_dict[sg.tags[0]['Value']] = sg.id
#import pdb; pdb.set_trace()
secgroup_names = [sg.tags[0]['Value'] for sg in secgroups if sg.tags is not None]
print 'Available security groups:', secgroup_names
sys.stdout.write("Select security group. None to create new one: ")
selected_security_group_name=raw_input()

sys.stdout.write("Enter root volume size in GBs: ")
selected_vol_size=raw_input()

# TODO(rushiagr): specify 'name' (i.e. tag for vm)

ec2.create_instances(DryRun=False, ImageId='ami-96f1c1c4', MinCount=1,
        MaxCount=1, KeyName=selected_keypair, InstanceType=flavor, BlockDeviceMappings=[{'DeviceName':
            '/dev/sda1', 'Ebs': {"VolumeSize": int(selected_vol_size)}}],
        SecurityGroupIds=[secgroup_name_id_dict[selected_security_group_name]])
        #SecurityGroups=[selected_security_group])





# TODO: do the validation mess some other day
#while True:
#    sys.stdout.write("Select keypair ['l' to list, 'c' to create new]: ")
#    inp=raw_input()
#    if inp.lower() == 'l':
#        keypairs = ec.key_pairs.all()
#        keypair_names = [kp.name for kp in kps]
#        print keypair_names
#        continue
#    elif inp.lower() == 'c':
#        while True:
#            sys.stdout.write('Please provide a keypair name: ')
#            kp_name=raw_input()
#            if kp_name:
#                break
#        break
#    else:
#
#        print 'Invalid flavor name.'
