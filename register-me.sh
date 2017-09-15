#!/usr/bin/env bash

# FUNCTIONS
function refresh_token() {
    local newtoken=`echo $(auth-tokens-refresh -S) | rev | cut -d ' ' -f 1 | rev`
    echo "$newtoken"
}

# DEFAULTS
execution_template="execution-template.json"
max_sys_jobs="50"
port="22"
max_user_sys_jobs="50"
execution_type="CLI"
HELP="
This script creates an Agave execution system for the user on the current system. The JSON used to create the system is saved to the current directory. If not specified using command line arguments, the current username and hostname will be used to generate the system ID. Addtionally, ssh keys will be created for the systems if not given with command line arguments. Several options are also available as detailed in the description below, with default values in parentheses.

Usage: ./register-me.sh [OPTIONS]

Options:
  -h, --help			Prints this message
  -z, --token			Agave access token (current saved token)
  -u, --username		System owner username (current username)
  -n, --hostame			Hostname of the systems (current hostname)
  -s, --systemid		ID of system (username-hostname)
  -p, --processors		Maximum processors per node (current processor count)
  -w, --workdir			Work directory (home directory)
  -pub, --pubkey		Public sshkey (generated with ssh-keygen)
  -priv, --privkey		Private sshkey (generated with ssh-keygen)
  --max-sys-jobs		Maximum jobs allowed (50)
  --port			Port number (22)
  --max-user-sys-jobs		Maximum jobs allowed per user (50)
  --execution-type		Execution system type (CLI)
"

# ARGPARSE
while [[ $# -gt 1 ]]; do
    key="$1"
    case $key in
        -z|--token) shift;
            token="$1"
            shift ;;
        -u|--username) shift;
            username="$1"
            shift ;;
        -n|--hostname) shift;
            host="$1"
            shift ;;
        -s|--systemid) shift;
            sysid="$1"
            shift ;;
        -p|--processors) shift;
            processors="$1"
            shift ;;
        -w|--workdir) shift;
            workdir="$1"
            shift ;;
        -pub|--pubkey) shift;
            pubkey="$1"
            shift ;;
        -priv|--privkey) shift;
            privkey="$1"
            shift ;;
        --max-sys-jobs) shift;
            max_sys_jobs="$1"
            shift ;;
        --port) shift;
            port="$1"
            shift ;;
        --max-user-sys-jobs) shift;
            max_user_sys_jobs="$1"
            shift ;;
        --execution-type) shift;
            execution_type="$1"
            shift ;;
        *) echo $HELP
            exit 0
    esac
done

# check for help request
if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    echo "$HELP"
    exit 0
fi

# GET DEFAULTS IF NECESSARY
# token is saved access token
if [ -z "$token" ]; then
    token=$(refresh_token)
fi
echo "Using access token $token"

# username is current user
if [ -z "$username" ]; then
    username=`whoami`
fi
echo "Setting owner as $username"

# host is base hostname
if [ -z "$host" ]; then
    host=`hostname -d`
fi
echo "Setting host to $host"

# build sysid from username and host
if [ -z "$sysid" ]; then
    sysid=`echo $username-$host | tr '.' '-'`
fi
echo "Setting system ID to $sysid"

# default workdir is homedir
if [ -z "$workdir" ]; then
    workdir=`echo $HOME`
fi
echo "Setting $sysid work directory to $workdir"

# calculate processors based on system type
if [ "$(uname)" == "Linux" ]; then
    if [ $(type -t lscpu) ]; then
        processors=`lscpu -p | grep -v "^#" | sort -u -n -t, -k 2,4 | wc -l`
    else
        processors=`getconf _NPROCESSORS_ONLN`
    fi
elif [ "$(uname)" == "FreeBSD" ]; then
    if [ $(type -t lscpu) ]; then
        processors=`lscpu -p | grep -v "^#" | sort -u -n -t, -k 2,4 | wc -l`
    else
        processors=`getconf NPROCESSORS_ONLN`
    fi
elif [ "$(uname)" == "Darwin" ]; then
    processors=`sysctl -n hw.physicalcpu_max`
else
    echo "Current system not a recognized type; please provide processors (-p) at the command line"
    exit 0
fi
echo "Setting processor count to $processors"

# get or make sshkeys
if [ -z "$privkey" ] || [ -z "$pubkey" ]; then
    sshkeyfile="$HOME/.ssh/$(echo $sysid | tr '-' '_')_sshkey"
    if ! [ -e "$sshkeyfile" ] || ! [ -e "$sshkeyfile.pub" ]; then
        echo "Generating sshkeys for $sysid"
        ssh-keygen -q -f $sshkeyfile -N $sysid
    else
        echo "Fetching existing sshkeys for $sysid"
    fi
    privkey=`cat $sshkeyfile | awk '{printf "%s\\n", $0}'`
    pubkey=`cat $sshkeyfile.pub`
fi

# SUBSTITUTE VALUES IN TEMPLATE
echo "Substituting values from template"
template=`cat $execution_template`
template=`echo ${template//\{USERNAME\}/$username}`
template=`echo ${template//\{HOST\}/$host}`
template=`echo ${template//\{SYSID\}/$sysid}`
template=`echo ${template//\{PROCESSORS\}/$processors}`
template=`echo ${template//\{WORK\}/$workdir}`
template=`echo ${template//\{PUBKEY\}/$pubkey}`
template=`echo ${template//\{PRIVKEY\}/$privkey}`
template=`echo ${template//\{MAX_SYS_JOBS\}/$max_sys_jobs}`
template=`echo ${template//\{PORT\}/$port}`
template=`echo ${template//\{MAX_USER_SYS_JOBS\}/$max_user_sys_jobs}`
template=`echo ${template//\{EXECUTION_TYPE\}/$execution_type}`

# SAVE TEMPLATE IN HOME DIR
jsonfile="$sysid.json"
echo $template >> $jsonfile
echo "Saved JSON description to $jsonfile"

# SUBMIT TO AGAVE 
#curl -sk -H "Authorization: Bearer $token" -X POST -F "fileToUpload=@$jsonfile" 'https://agave.iplantc.org/systems/v2/?pretty=true'
systems-addupdate -z $token -F $jsonfile
