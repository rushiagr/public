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
    chmod 755 /usr/local/bin/lsvm

    printf "${GREEN}Setup successful! Why not try 'lsvm' immediately? :)${NORMAL}\n"
}
main
