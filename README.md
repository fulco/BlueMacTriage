# BlueMacTriage

**BlueMacTriage** is a comprehensive Mac forensics triage bash script designed for Intel-based Macs. This script collects a variety of forensic data from a suspect system to assist in initial forensic investigations.

## Features

- Collects detailed system information
- Gathers user and group information
- Captures running processes and network connections
- Lists installed applications
- Collects system logs
- Retrieves browser history (Safari, Chrome, Firefox)
- Identifies persistence mechanisms (LaunchDaemons, LaunchAgents, cron jobs)
- Captures detailed network configurations
- Gathers disk and file system information
- Checks security settings (SIP, FileVault, Gatekeeper)
- Captures clipboard data
- Hashes important binaries and system files
- Zips the collected data and cleans up the temporary directory

## Usage

### Prerequisites

Ensure you have root privileges to run the script:

```bash
sudo ./macTriage.sh
```

### Installation

1. Clone the repository:

```bash
git clone https://github.com/fulco/BlueMacTriage.git
```

2. Navigate to the repository directory:

```bash
cd BlueMacTriage
```

3. Make the script executable:

```bash
chmod +x macTriage.sh
```

### Running the Script

Run the script with root privileges:

```bash
sudo ./macTriage.sh
```

The script will create a directory in `/tmp` with the collected forensic data. The directory name will include the date and time the script was run, for example: `/tmp/mac_forensics_(date +%Y%m%d_%H%M%S)`.

Once the data is collected, the script will zip the directory and save it as `/tmp/mac_forensics_(date +%Y%m%d_%H%M%S).zip`. The temporary directory will then be cleaned up.

## Output

The script collects and stores data in the following files within the output directory:

- `system_info.txt`: Detailed system information
- `users.txt`: List of users
- `groups.txt`: List of groups
- `user_details.txt`: Detailed information for each user
- `processes.txt`: List of running processes
- `open_files.txt`: List of open files
- `network_connections.txt`: Network connections
- `installed_apps.txt`: List of installed applications
- `system.log`: System log
- `kernel.log`: Kernel log
- `install.log`: Install log
- `appfirewall.log`: Application firewall log
- `secure.log`: Secure log
- `Safari_History`: Safari history files
- `Chrome_History`: Chrome history files
- `Firefox_History`: Firefox history files
- `launchdaemons.txt`: List of LaunchDaemons
- `launchagents.txt`: List of LaunchAgents
- `crontab.txt`: User's crontab
- `cronjobs.txt`: List of cron jobs
- `network_config.txt`: Network configuration
- `dns_config.txt`: DNS configuration
- `proxy_config.txt`: Proxy configuration
- `disk_usage.txt`: Disk usage
- `disk_list.txt`: List of disks
- `disk_info.txt`: Detailed disk information
- `sip_status.txt`: System Integrity Protection status
- `filevault_status.txt`: FileVault status
- `gatekeeper_status.txt`: Gatekeeper status
- `clipboard.txt`: Clipboard data
- `bin_hashes.txt`: Hashes of important binaries

## Contributing

Contributions are welcome! Please fork the repository and submit a pull request for any improvements or additional features.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contact

For any questions or feedback, please reach out to [Fulco] at [security@fulco.net].

---

This README provides an overview of the macTriage script, how to use it, and what output to expect. Feel free to customize it further based on your preferences and specific details.

---ß

### Tested on MacOS Sonoma 14.5
