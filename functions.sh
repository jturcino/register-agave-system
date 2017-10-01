#!/usr/bin/env bash

# TOKEN
function refresh_token() {
    local newtoken=`echo $(auth-tokens-refresh -S) | rev | cut -d ' ' -f 1 | rev`
    echo "$newtoken"
}
function get_token() {
    local token="$1"
    if [ -z "$token" ]; then
        token="$(refresh_token)"
    fi
    echo "$token"
}

# USERNAME
function get_username() {
    local username="$1"
    if [ -z "$username" ]; then
        username="$(whoami)"
    fi
    echo "$username"
}

# HOSTNAME
function get_host() {
    local host="$1"
    if [ -z "$host" ]; then
        host="$(hostname -d)"
    fi
    echo "$host"
}

# SYSID
function get_sysid() {
    local username="$1"
    local host="$2"
    local sysid="$3"
    if [ -z "$sysid" ]; then
        sysid="$(echo ${username}-${host} | tr '.' '-')"
    fi
    echo $sysid
}

# PROCESSORS
function get_processors() {
    local system=`uname`
    if [ "$system" == "Linux" ]; then
        if [ $(type -t lscpu) ]; then
            processors=`lscpu -p | grep -v "^#" | sort -u -n -t, -k 2,4 | wc -l`
        else
            processors=`getconf _NPROCESSORS_ONLN`
        fi
    elif [ "$system" == "FreeBSD" ]; then
        if [ $(type -t lscpu) ]; then
            processors=`lscpu -p | grep -v "^#" | sort -u -n -t, -k 2,4 | wc -l`
        else
            processors=`getconf NPROCESSORS_ONLN`
        fi
    elif [ "$system" == "Darwin" ]; then
        processors=`sysctl -n hw.physicalcpu_max`
    else
        echo "Current system not a recognized type; please provide processors (-p) at the command line"
        exit 0
    fi
    echo "$processors"
}

# SSHKEYS
function generate_sshkeys() {
    local keyfile="$1"
    ssh-keygen -q -f $keyfile -N ""
    cat ${keyfile}.pub >> $HOME/.ssh/authorized_keys
}
function get_privkey {
    local sysid="$1"
    local privkeyfile="$HOME/.ssh/agave_$(echo $sysid | tr '-' '_')"
    # if file does not exist, generate keys
    if ! [ -e "$privkeyfile" ]; then
        generate_sshkeys $privkeyfile
    fi
    cat $privkeyfile | awk '{printf "%s\\n", $0}'
}
function get_pubkey {
    local sysid="$1"
    local pubkeyfile="$HOME/.ssh/agave_$(echo $sysid | tr '-' '_').pub"
    # if file does not exist, generate keys
    if ! [ -e "$pubkeyfile" ]; then
        generate_sshkeys ${pubkeyfile%.pub}
    fi
    cat $pubkeyfile
}

# UTILS
# get 1-based index from space-delimited list
function get_list_item() {
    local list="$1"
    local index="$2"
    echo "$list" | cut -d ' ' -f $index
}
# for a given template, substitute a key for a value
function substitute() {
    local template="$1"
    local key="$2"
    local value="$3"
    echo "${template//$key/$value}"
} 
# output formatted JSON to a file
function format_json() {
    local json="$1"
    local file="$2"
    local sbuffer=""
    local indent=""
    for i in $json; do
        local lastchar="${i: -1}"
        local last2chars="${i: -2}"
        if [[ "$lastchar" =~ [\{\[] ]]; then
            echo "${sbuffer}$i" | sed 's/ //' >> $file
            indent="$indent    "
            sbuffer="$indent"
        elif [ "$lastchar" == "," ] && ! [ "$last2chars" == "}," ] && ! [ "$last2chars" == "]," ]; then
            sbuffer="${sbuffer} $i"
            echo "$sbuffer" | sed 's/ //' >> $file
            sbuffer="$indent"
        elif [[ "$lastchar" =~ [\]\}] ]] || [ "$last2chars" == "}," ] || [ "$last2chars" == "]," ]; then
            if ! [ -z "${sbuffer// }" ]; then
                echo "$sbuffer" | sed 's/ //' >> $file
            fi
            indent="${indent%    }"
            echo "${indent}$i" >> $file
            sbuffer="$indent"
        else
            sbuffer="${sbuffer} $i"
        fi
    done
}
