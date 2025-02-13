#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Mac Forensics Triage Script Consolidated
# Author: Fulco
# Version: 0.3

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" >&2
    exit 1
fi

# Create an output directory and error log
OUTPUT_DIR="/tmp/mac_forensics_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTPUT_DIR"
ERROR_LOG="$OUTPUT_DIR/error.log"
touch "$ERROR_LOG"

# Function to log errors
log_error() {
    echo "ERROR: $1" | tee -a "$ERROR_LOG"
}

# Collect system information
collect_system_info() {
    echo "Collecting system information..."
    {
        system_profiler SPSoftwareDataType
        system_profiler SPHardwareDataType
        system_profiler SPNetworkDataType
        uname -a
    } > "$OUTPUT_DIR/system_info.txt" 2>>"$ERROR_LOG"
}

# Collect user and group information
collect_user_info() {
    echo "Collecting user and group information..."
    dscl . list /Users > "$OUTPUT_DIR/users.txt" 2>>"$ERROR_LOG"
    dscl . list /Groups > "$OUTPUT_DIR/groups.txt" 2>>"$ERROR_LOG"
    while read -r user; do
        echo "User: $user" >> "$OUTPUT_DIR/user_details.txt"
        dscl . -read /Users/"$user" >> "$OUTPUT_DIR/user_details.txt" 2>>"$ERROR_LOG"
    done < "$OUTPUT_DIR/users.txt"
}

# Collect running processes and network connections
collect_processes_network() {
    echo "Collecting running processes and network connections..."
    ps aux > "$OUTPUT_DIR/processes.txt" 2>>"$ERROR_LOG"
    if command -v lsof >/dev/null; then
        lsof > "$OUTPUT_DIR/open_files.txt" 2>>"$ERROR_LOG"
    else
        log_error "lsof command not found."
    fi
    netstat -an > "$OUTPUT_DIR/network_connections.txt" 2>>"$ERROR_LOG"
}

# Collect installed applications list
collect_installed_apps() {
    echo "Collecting installed applications..."
    ls /Applications > "$OUTPUT_DIR/installed_apps.txt" 2>>"$ERROR_LOG"
}

# Collect common system log files
collect_system_logs() {
    echo "Collecting system logs..."
    for logfile in /var/log/system.log /var/log/kernel.log /var/log/install.log /var/log/appfirewall.log /var/log/secure.log; do
        if [ -f "$logfile" ]; then
            cp "$logfile" "$OUTPUT_DIR/" 2>>"$ERROR_LOG"
        else
            log_error "$logfile not found."
        fi
    done
}

# Collect browser history (Safari, Chrome, Firefox) for all non-system users
collect_browser_history() {
    echo "Collecting browser history..."
    for user in $(dscl . list /Users | grep -v '^_'); do
        # Get the user's home directory
        user_home=$(dscl . -read /Users/"$user" NFSHomeDirectory | awk '{print $2}')
        if [ ! -d "$user_home" ]; then
            log_error "Home directory for user $user not found."
            continue
        fi

        # Define browser mappings (name: relative path)
        for browser in "Safari:Library/Safari" "Chrome:Library/Application Support/Google/Chrome" "Firefox:Library/Application Support/Firefox"; do
            IFS=":" read -r name rel_path <<< "$browser"
            if [ -d "$user_home/$rel_path" ]; then
                mkdir -p "$OUTPUT_DIR/$user/${name}_History"
                cp -r "$user_home/$rel_path" "$OUTPUT_DIR/$user/${name}_History" 2>>"$ERROR_LOG"
            fi
        done
    done
}

# Collect persistence mechanisms (LaunchDaemons, LaunchAgents, cron jobs)
collect_persistence_mechanisms() {
    echo "Collecting persistence mechanisms..."
    ls /Library/LaunchDaemons > "$OUTPUT_DIR/launchdaemons.txt" 2>>"$ERROR_LOG"
    ls /Library/LaunchAgents > "$OUTPUT_DIR/launchagents.txt" 2>>"$ERROR_LOG"
    crontab -l > "$OUTPUT_DIR/crontab.txt" 2>>"$ERROR_LOG" || log_error "No crontab for current user."
    ls /etc/cron.* > "$OUTPUT_DIR/cronjobs.txt" 2>>"$ERROR_LOG"
}

# Collect detailed network configurations
collect_network_configurations() {
    echo "Collecting network configurations..."
    ifconfig -a > "$OUTPUT_DIR/network_config.txt" 2>>"$ERROR_LOG"
    scutil --dns > "$OUTPUT_DIR/dns_config.txt" 2>>"$ERROR_LOG"
    scutil --proxy > "$OUTPUT_DIR/proxy_config.txt" 2>>"$ERROR_LOG"
}

# Collect disk and filesystem information
collect_disk_info() {
    echo "Collecting disk and file system information..."
    df -h > "$OUTPUT_DIR/disk_usage.txt" 2>>"$ERROR_LOG"
    diskutil list > "$OUTPUT_DIR/disk_list.txt" 2>>"$ERROR_LOG"
    diskutil info -all > "$OUTPUT_DIR/disk_info.txt" 2>>"$ERROR_LOG"
}

# Collect security settings (SIP, FileVault, Gatekeeper)
collect_security_settings() {
    echo "Collecting security settings..."
    csrutil status > "$OUTPUT_DIR/sip_status.txt" 2>>"$ERROR_LOG"
    fdesetup status > "$OUTPUT_DIR/filevault_status.txt" 2>>"$ERROR_LOG"
    spctl --status > "$OUTPUT_DIR/gatekeeper_status.txt" 2>>"$ERROR_LOG"
}

# Capture clipboard data (if available)
capture_clipboard_data() {
    echo "Capturing clipboard data..."
    if command -v pbpaste >/dev/null; then
        pbpaste > "$OUTPUT_DIR/clipboard.txt" 2>>"$ERROR_LOG"
    else
        log_error "pbpaste command not found."
    fi
}

# Hash important binaries and system files
hash_binaries() {
    echo "Hashing important binaries and system files..."
    md5 /bin/* /sbin/* /usr/bin/* /usr/sbin/* > "$OUTPUT_DIR/bin_hashes.txt" 2>>"$ERROR_LOG"
}

# Zip the results and clean up
zip_and_cleanup() {
    echo "Zipping the collected data..."
    ZIP_FILE="$HOME/${OUTPUT_DIR##*/}.zip"
    zip -r "$ZIP_FILE" "$OUTPUT_DIR" >/dev/null 2>>"$ERROR_LOG"
    
    if [ -s "$ZIP_FILE" ]; then
        echo "Zipped file saved as $ZIP_FILE"
        echo "Cleaning up temporary directory..."
        rm -rf "$OUTPUT_DIR"
    else
        log_error "Zip file creation failed or the zip file is empty. Not deleting the temporary directory."
    fi
}

# Main function that runs all collection routines
main() {
    collect_system_info
    collect_user_info
    collect_processes_network
    collect_installed_apps
    collect_system_logs
    collect_browser_history
    collect_persistence_mechanisms
    collect_network_configurations
    collect_disk_info
    collect_security_settings
    capture_clipboard_data
    hash_binaries
    zip_and_cleanup

    echo "Forensics data collection complete."
    if [ -s "$ERROR_LOG" ]; then
        echo "Errors were encountered during execution. Check $ERROR_LOG for details."
    fi
}

main
