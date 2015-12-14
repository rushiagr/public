# Run as:
# sudo sh -c "$(wget -q https://raw.githubusercontent.com/rushiagr/public/master/scripts/lsvm.sh -O -)"



main() {
    # Code to colour output copied from oh-my-zsh: https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh

    # Use colors, but only if connected to a terminal, and that terminal
    # supports them.
    if which tput >/dev/null 2>&1; then
        ncolors=$(tput colors)
    fi

    if [ -t 1 ] && [ -n "$ncolors" ] && [ "$ncolors" -ge 8 ]; then
      RED="$(tput setaf 1)"
      GREEN="$(tput setaf 2)"
      YELLOW="$(tput setaf 3)"
      BLUE="$(tput setaf 4)"
      BOLD="$(tput bold)"
      NORMAL="$(tput sgr0)"
    else
      RED=""
      GREEN=""
      YELLOW=""
      BLUE=""
      BOLD=""
      NORMAL=""
    fi

    # Check if running as root or not
    if [ "$(id -u)" -ne "0" ]; then
        printf "${RED}NOT running as root! Please run this script with sudo privileges.${NORMAL}\n"
        exit
    fi

    printf "${GREEN}Installing python packages awscli, boto3 and prettytable ...${NORMAL}\n"
    sleep 2
    sudo pip install awscli boto3 prettytable
    printf "${GREEN}Please provide your aws access and secret key.${NORMAL}\n"
    printf "${YELLOW}  Note: ${NORMAL}${GREEN}Input 'Default region name' as 'ap-southeast-1' for Singapore, and similarly for others.${NORMAL}\n"
    printf "${YELLOW}  Note: ${NORMAL}${GREEN}Keep 'Default output format' empty${NORMAL}\n"

    aws configure

    cat > /usr/local/bin/lsvm <<EOF
#!/usr/bin/python

# -*- coding: utf-8 -*-
import boto3
import botocore
import prettytable
import sys

show_vol_info=False

unique_name=''

if len(sys.argv) == 2:
    if sys.argv[1] in ['-h', '--help']:
        print '''lsvm [-h] [-s] [<name>]
    -h      Prints helptext and exits
    -s      Prints sizes of VM disks in GB, starting with root disk
    <name>  Only prints VM whose name contains '<name>'
'''
        sys.exit()
    elif sys.argv[1] == '-s':
        show_vol_info=True
    else:
        unique_name=sys.argv[1]

if show_vol_info:
    table = prettytable.PrettyTable(['ID', 'Name', 'Status', 'Flavor', 'IP', 'Vols(GB)'])
else:
    table = prettytable.PrettyTable(['ID', 'Name', 'Status', 'Flavor', 'IP', 'Vols'])
table.left_padding_width=0
table.right_padding_width=1
table.border=False

try:
    ec2 = boto3.resource('ec2')
except (botocore.exceptions.NoRegionError, botocore.exceptions.NoCredentialsError) as e:
    # TODO(rushiagr): instead of telling people to run credentials, ask
    # credentials here itself
    print 'Credentials and region not configured? Run "aws configure" to configure it.'
    # TODO(rushiagr): let people provide singapore, and guess region name from
    # that.
    print 'Provide region as "ap-southeast-1" for Singapore.'
    sys.exit()

instances = ec2.instances.all()

instances_to_print = []

if unique_name == '':
    instances_to_print = instances
else:
    for i in instances:
        if i.tags is not None and len(i.tags) > 0:
            for tag in i.tags:
                if tag['Key'] == 'Name' and tag['Value'].lower().find(unique_name) > -1:
                    instances_to_print.append(i)
                    break

for i in instances_to_print:
    row = [i.id,
        i.tags[0]['Value'] if i.tags is not None else '',
        i.state['Name'],
        i.instance_type,
        i.public_ip_address]
    if show_vol_info:
        row.append([vol.size for vol in i.volumes.all()])
    else:
        row.append(len(i.block_device_mappings))
    table.add_row(row)


print table.get_string(sortby='Status')
EOF
    cat > /usr/local/bin/mkvm <<EOF
#!/usr/bin/python

# -*- coding: utf-8 -*-
import boto3
import sys

#todo http://boto3.readthedocs.org/en/latest/reference/services/ec2.html#EC2.ServiceResource.create_instances

ec2 = boto3.resource('ec2')

flavor_names = ['t1.micro', 'm1.small', 'm1.medium', 'm1.large', 'm1.xlarge', 'm3.medium', 'm3.large', 'm3.xlarge', 'm3.2xlarge', 'm4.large', 'm4.xlarge', 'm4.2xlarge', 'm4.4xlarge', 'm4.10xlarge', 't2.micro', 't2.small', 't2.medium', 't2.large', 'm2.xlarge', 'm2.2xlarge', 'm2.4xlarge', 'cr1.8xlarge', 'i2.xlarge', 'i2.2xlarge', 'i2.4xlarge', 'i2.8xlarge', 'hi1.4xlarge', 'hs1.8xlarge', 'c1.medium', 'c1.xlarge', 'c3.large', 'c3.xlarge', 'c3.2xlarge', 'c3.4xlarge', 'c3.8xlarge', 'c4.large', 'c4.xlarge', 'c4.2xlarge', 'c4.4xlarge', 'c4.8xlarge', 'cc1.4xlarge', 'cc2.8xlarge', 'g2.2xlarge', 'cg1.4xlarge', 'r3.large', 'r3.xlarge', 'r3.2xlarge', 'r3.4xlarge', 'r3.8xlarge', 'd2.xlarge', 'd2.2xlarge', 'd2.4xlarge', 'd2.8xlarge']

print 'Only Ubuntu image supported as of now'
print 'Available flavors:', flavor_names

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
EOF
    chmod 755 /usr/local/bin/lsvm
    chmod 755 /usr/local/bin/mkvm

    printf "${GREEN}Setup successful! Why not try 'lsvm' or 'mkvm' immediately? :)${NORMAL}\n"
}
main
