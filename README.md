# register-agave-system
Register your current system as an agave execution system

## Set up
This repo requires use of the [Agave CLI](https://bitbucket.org/agaveapi/cli). Once the CLI is set up, simply clone the repo in a directory of your choice.
```
git clone https://github.com/jturcino/register-agave-system.git
```

## Options and use
The simplest way to use the script to simply by running it! This will use your current system settings by default.
```
./register-system.sh
```

There are command-line options available many aspects of the system, such as owner username, system id, work directory, and sshkeys. The full list of options are avilable at any time using the `-h` flag.
```
$ ./register-system.sh -h

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
```

The JSON description used to generate the system will be stored in the directory specified with the `--savedir` flag (defaults to `$HOME`). If you wish to make any manual edits to the system, simply edit the file to your liking and update the system with `systems-addupdate`.
```
systems-addupdate -F $JSONFILE
```
