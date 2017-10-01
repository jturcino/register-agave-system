#!/usr/bin/env bash

source functions.sh

# TEMPLATES
execution_template="execution-template.json"
storage_template="storage-template.json"

# GENERAL DEFAULTS
systype="EXECUTION"
template="$(cat $execution_template)"
port="22"
workdir="$HOME"
savedir="$HOME"

# EXECUTION-SPECIFIC DEFAULTS
max_sys_jobs="50"
max_user_sys_jobs="50"
execution_type="CLI"
HELP="
This script creates an Agave execution or storage system for the user on the current 
system. The JSON used to create the system is saved to the current directory. If not 
specified using command line arguments, the current username and hostname will be used 
to generate the system ID, and the system type will be execution. Addtionally, ssh 
keys will be created for the system if not given with command line arguments. Several 
options are also available as detailed in the description below, with default values 
in parentheses.

Usage: ./register-me.sh [OPTIONS]

General options:
  -h, --help			Prints this message
  -z, --token			Agave access token (current saved token)
  -u, --username		System owner username (current username)
  -n, --hostame			Hostname of the systems (current hostname)
  -s, --systemid		ID of system (username-hostname)
  -t, --type			EXECUTION or STORAGE (EXECUTION)
  -w, --workdir			Work directory (home directory)
  -p, --port 			Port number (22)
  -pub, --pubkey		Public sshkey (generated with ssh-keygen)
  -priv, --privkey		Private sshkey (generated with ssh-keygen)
  -d, --savedir                 Path to directory in which to save JSON (~)

Execution-specific options:
  --processors			Maximum processors per node (current processor count)
  --max-sys-jobs		Maximum jobs allowed (50)
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
        -t|--type) shift;
            systype="$1"
            shift ;;
        -w|--workdir) shift;
            workdir="$1"
            shift ;;
        -p|--port) shift;
            port="$1"
            shift ;;
        -pub|--pubkey) shift;
            pubkey="$1"
            shift ;;
        -priv|--privkey) shift;
            privkey="$1"
            shift ;;
        -d|--savedir) shift;
            savedir="$1"
            shift ;;
        --processors) shift;
            processors="$1"
            shift ;;
        --max-sys-jobs) shift;
            max_sys_jobs="$1"
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

# check for system type
if ! [ "$systype" == "EXECUTION" ] && ! [ "$systype" == "STORAGE" ]; then
    echo "Given system type was not EXECUTION or STORAGE. Please specify one of these with the -t flag, or leave blank for default EXECUTION."
    exit 0
fi

# init keys, variables, and template
keys="PORT"
variables="port"
if [ "$systype" == "EXECUTION" ]; then
    if [ -z "$processors" ]; then
        processors="$(get_processors)"
    fi
    echo "Processors: $processors"
    keys="$keys MAX_SYS_JOBS MAX_USER_SYS_JOBS EXECUTION_TYPE PROCESSORS"
    variables="$variables max_sys_jobs max_user_sys_jobs execution_type processors"
else
    template="$(cat $storage_template)"
fi

# GET DEFAULTS IF NECESSARY
token="$(get_token "$token")"
echo "Access token: $token"

username="$(get_username "$username")"
echo "Owner: $username"

host="$(get_host "$host")"
echo "Host: $host"

sysid="$(get_sysid "$username" "$host" "$sysid")"
echo "System ID: $sysid"

# get/make sshkeys if not provided
if [ -z "$privkey" ] || [ -z "$pubkey" ]; then
    echo "Generating SSH keys"
    privkey="$(get_privkey "$sysid")"
    pubkey="$(get_pubkey "$sysid")"
fi
echo "Set sshkeys"

# set remaining keys and variables
keys="$keys USERNAME HOST SYSID WORKDIR PUBKEY PRIVKEY"
variables="$variables username host sysid workdir pubkey privkey"

# SUBSTITUTE VALUES IN TEMPLATE
echo "Substituting values from template"
num_subs=$(echo $keys | wc -w)
for i in $(seq 1 $num_subs); do
    key="\{$(get_list_item "$keys" "$i")\}"
    var="$(get_list_item "$variables" "$i")"
    var_value="${!var}"
    template="$(substitute "$template" "$key" "$var_value")"
done

# SAVE TEMPLATE IN HOME DIR
jsonfile="$savedir/$sysid.json"
format_json "$template" "$jsonfile"
echo "Saved JSON description to $jsonfile"

# SUBMIT TO AGAVE 
#systems-addupdate -z $token -F $jsonfile
