#!/usr/bin/env bash

source functions.sh

# DEFAULTS
execution_template="execution-template.json"
max_sys_jobs="50"
port="22"
max_user_sys_jobs="50"
execution_type="CLI"
savedir="$HOME"
HELP="
This script creates an Agave execution system for the user on the current system. 
The JSON used to create the system is saved to the current directory. If not 
specified using command line arguments, the current username and hostname will be 
used to generate the system ID. Addtionally, ssh keys will be created for the 
systems if not given with command line arguments. Several options are also available 
as detailed in the description below, with default values in parentheses.

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
  --savedir			Path to directory in which to save JSON (~)
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
        --savedir) shift;
            savedir="$1"
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
token="$(get_token $token)"
echo "Access token: $token"

username="$(get_username $username)"
echo "Owner: $username"

host="$(get_host $host)"
echo "Host: $host"

sysid="$(get_sysid $sysid $username $host)"
echo "System ID: $sysid"

workdir="$(get_workdir $workdir)"
echo "Work directory: $workdir"

processors="$(get_processors)"
echo "Processors: $processors"

# get/make sshkeys if not provided
if [ -z "$privkey" ] || [ -z "$pubkey" ]; then
    echo "SSH keys not provided; generating..."
    privkey="$(get_privkey $sysid)"
    pubkey="$(get_pubkey $sysid)"
fi
echo "Set sshkeys"

# set template, keys, and variables lists
template=`cat $execution_template`
keys="MAX_SYS_JOBS PORT MAX_USER_SYS_JOBS EXECUTION_TYPE USERNAME HOST SYSID PROCESSORS WORK PUBKEY PRIVKEY"
variables="max_sys_jobs port max_user_sys_jobs execution_type username host sysid processors workdir pubkey privkey"

# SUBSTITUTE VALUES IN TEMPLATE
echo "Substituting values from template"
num_subs=$(echo $keys | wc -w)
for i in $(seq 1 $num_subs); do
    key="\{$(get_list_item "$keys" $i)\}"
    var="$(get_list_item "$variables" $i)"
    var_value="${!var}"
    template="$(substitute "$template" "$key" "$var_value")"
done

# SAVE TEMPLATE IN HOME DIR
jsonfile="$savedir/$sysid.json"
format_json "$template" "$jsonfile"
echo "Saved JSON description to $jsonfile"

# SUBMIT TO AGAVE 
#systems-addupdate -z $token -F $jsonfile
