# register-agave-system
Register your current system as an agave execution or storage system

## Set up
This repo requires use of the [Agave CLI](https://bitbucket.org/agaveapi/cli). Once the CLI is set up, simply clone the repo in a directory of your choice.
```
git clone https://github.com/jturcino/register-agave-system.git
```

## Options and use
The simplest way to use the script to simply by running it! This will register an **execution** system using your current system settings, with your `$HOME` directory as the `$WORK` directory of the system.
```
./register-system.sh
```

Alternately, you can create a **storage** system with your current system settings, including your `$HOME` directory as the primary storage directory, with the `-t` flag.
```
./register-system -t STORAGE
```

There are command-line options available many aspects of the system, such as owner username, system id, work directory, and sshkeys. The full list of options are avilable at any time using the `-h` flag. Some options are not applicable to storage system registration; these have only `--` flags and are listed under `Execution-specific options`.
```
$ ./register-system.sh -h

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
  -d, --savedir         Path to directory in which to save JSON (~)

Execution-specific options:
  --processors			Maximum processors per node (current processor count)
  --max-sys-jobs		Maximum jobs allowed (50)
  --max-user-sys-jobs	Maximum jobs allowed per user (50)
  --execution-type		Execution system type (CLI)
```

The JSON description used to generate the system will be stored in the directory specified with the `--savedir` flag (defaults to `$HOME` if flag not used). If you wish to make any manual edits to the system, simply edit the file to your liking and update the system with `systems-addupdate`.
```
systems-addupdate -F $JSONFILE
```
