# NagiosIpsetStatus

Nagios plugin for check ipset status and specified set status. Supports directly usage and Nagios/Icinga usage.

## Options

- `-h (--help)` - Shows help message.
- `-s (--set-name)` - Specify ipset set name. Only for directly usage.
- `-n (--nagios)` - Enable Nagios/Icinga usage. Showing ipset info requiring use log file with ipset status.
- `-p (--log-path)` - Specify path to log file with ipset status. Only for Nagios/Icinga usage (usage: `-p <path> | --log-path=<path>`).

## Usage

Notice: curent user must be root or user with sudo access.

Put [check_ipset.sh](https://github.com/zevilz/NagiosIpsetStatus/blob/master/check_ipset.sh) to nagios plugins directory (usually `/usr/lib*/nagios/plugins`). Than make file executable (`chmod +x check_ipset.sh`).

### Directly usage

```bash
./check_ipset.sh -s <ipset_set_name>
```

### Nagios/Icinga usage

Add following check command object to your commands file
```bash
object CheckCommand "ipset" {
	import "plugin-check-command"
	command = [ PluginDir + "/check_ipset.sh" ]
	arguments = {
		"-n" = {}
		"-p" = "$log_path$"
	}
}
```

Than add service definition to your services with `check_command = "ipset"`.

Supported vars:
- `log_path` - Sets full path to log file with ipset status.

Log file is required for show ipset sets info because the nagios user does not have the rights to access to ipset command. Put [get_ipset_info.sh](https://github.com/zevilz/NagiosIpsetStatus/blob/master/get_ipset_info.sh) in any directory.

Than add script to cron
```bash
*/1 * * * * bash <full_path_to_script> -p <full_path_to_log_file> -s <ipset_set_name>
```

Script creates/updates log file in specified path and make it readable only for users in `nagios` group and for user `nagios`.

## Changelog
- 24.12.2017 - 1.0.0 - released
