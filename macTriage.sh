#!/bin/bash

# Mac Forensics Triage Script
# Author: Fulco
# Version: 0.2

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# Create a directory to store the results
OUTPUT_DIR="/tmp/mac_forensics_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTPUT_DIR"

# Initialize error log
ERROR_LOG="$OUTPUT_DIR/error.log"
touch "$ERROR_LOG"

function log_error {
    echo "ERROR: $1" | tee -a "$ERROR_LOG"
}

# Function to collect system information
collect_system_info() {
    echo "Collecting system information..."
    {
        system_profiler SPSoftwareDataType
        system_profiler SPHardwareDataType
        system_profiler SPNetworkDataType
        uname -a
    } > "$OUTPUT_DIR/system_info.txt" 2>>"$ERROR_LOG"
}

# Function to collect user information
collect_user_info() {
    echo "Collecting user information..."
    dscl . list /Users 2>>"$ERROR_LOG" > "$OUTPUT_DIR/users.txt"
    dscl . list /Groups 2>>"$ERROR_LOG" > "$OUTPUT_DIR/groups.txt"
    while read -r user; do
        echo "User: $user" >> "$OUTPUT_DIR/user_details.txt"
        dscl . -read /Users/"$user" >> "$OUTPUT_DIR/user_details.txt" 2>>"$ERROR_LOG"
    done < "$OUTPUT_DIR/users.txt"
}

# Function to collect running processes and network connections
collect_processes_network() {
    echo "Collecting running processes and network connections..."
    ps aux > "$OUTPUT_DIR/processes.txt" 2>>"$ERROR_LOG"
    if command -v lsof >/dev/null 2>&1; then
        lsof > "$OUTPUT_DIR/open_files.txt" 2>>"$ERROR_LOG"
    else
        log_error "lsof command not found."
    fi
    netstat -an > "$OUTPUT_DIR/network_connections.txt" 2>>"$ERROR_LOG"
}

# Function to collect installed applications
collect_installed_apps() {
    echo "Collecting installed applications..."
    ls /Applications > "$OUTPUT_DIR/installed_apps.txt" 2>>"$ERROR_LOG"
}

# Function to collect system logs
collect_system_logs() {
    echo "Collecting system logs..."
    LOG_FILES=(
        "/var/log/system.log"
        "/var/log/kernel.log"
        "/var/log/install.log"
        "/var/log/appfirewall.log"
        "/var/log/secure.log"
    )
    for log_file in "${LOG_FILES[@]}"; do
        if [ -f "$log_file" ]; then
            cp "$log_file" "$OUTPUT_DIR/" 2>>"$ERROR_LOG"
        else
            log_error "$log_file not found."
        fi
    done
}

# Function to collect browser history (Safari, Chrome, Firefox) for all users
collect_browser_history() {
    echo "Collecting browser history..."
    USERS=$(dscl . list /Users | grep -v '^_') # Exclude system users
    for user in $USERS; do
        USER_HOME=$(dscl . -read /Users/"$user" NFSHomeDirectory | awk '{print $2}')
        if [ -d "$USER_HOME" ]; then
            # Safari
            if [ -d "$USER_HOME/Library/Safari" ]; then
                mkdir -p "$OUTPUT_DIR/$user/Safari_History"
                cp -r "$USER_HOME/Library/Safari" "$OUTPUT_DIR/$user/Safari_History" 2>>"$ERROR_LOG"
            fi
            # Chrome
            if [ -d "$USER_HOME/Library/Application Support/Google/Chrome" ]; then
                mkdir -p "$OUTPUT_DIR/$user/Chrome_History"
                cp -r "$USER_HOME/Library/Application Support/Google/Chrome" "$OUTPUT_DIR/$user/Chrome_History" 2>>"$ERROR_LOG"
            fi
            # Firefox
            if [ -d "$USER_HOME/Library/Application Support/Firefox" ]; then
                mkdir -p "$OUTPUT_DIR/$user/Firefox_History"
                cp -r "$USER_HOME/Library/Application Support/Firefox" "$OUTPUT_DIR/$user/Firefox_History" 2>>"$ERROR_LOG"
            fi
        else
            log_error "Home directory for user $user not found."
        fi
    done
}

# Function to collect persistence mechanisms
collect_persistence_mechanisms() {
    echo "Collecting persistence mechanisms..."
    ls /Library/LaunchDaemons > "$OUTPUT_DIR/launchdaemons.txt" 2>>"$ERROR_LOG"
    ls /Library/LaunchAgents > "$OUTPUT_DIR/launchagents.txt" 2>>"$ERROR_LOG"
    crontab -l > "$OUTPUT_DIR/crontab.txt" 2>>"$ERROR_LOG"
    ls /etc/cron.* > "$OUTPUT_DIR/cronjobs.txt" 2>>"$ERROR_LOG"
}

# Function to collect detailed network configurations
collect_network_configurations() {
    echo "Collecting network configurations..."
    ifconfig -a > "$OUTPUT_DIR/network_config.txt" 2>>"$ERROR_LOG"
    scutil --dns > "$OUTPUT_DIR/dns_config.txt" 2>>"$ERROR_LOG"
    scutil --proxy > "$OUTPUT_DIR/proxy_config.txt" 2>>"$ERROR_LOG"
}

# Function to collect disk and file system information
collect_disk_info() {
    echo "Collecting disk and file system information..."
    df -h > "$OUTPUT_DIR/disk_usage.txt" 2>>"$ERROR_LOG"
    diskutil list > "$OUTPUT_DIR/disk_list.txt" 2>>"$ERROR_LOG"
    diskutil info -all > "$OUTPUT_DIR/disk_info.txt" 2>>"$ERROR_LOG"
}

# Function to collect security settings
collect_security_settings() {
    echo "Collecting security settings..."
    csrutil status > "$OUTPUT_DIR/sip_status.txt" 2>>"$ERROR_LOG"
    fdesetup status > "$OUTPUT_DIR/filevault_status.txt" 2>>"$ERROR_LOG"
    spctl --status > "$OUTPUT_DIR/gatekeeper_status.txt" 2>>"$ERROR_LOG"
}

# Function to capture clipboard data
capture_clipboard_data() {
    echo "Capturing clipboard data..."
    if command -v pbpaste >/dev/null 2>&1; then
        pbpaste > "$OUTPUT_DIR/clipboard.txt" 2>>"$ERROR_LOG"
    else
        log_error "pbpaste command not found."
    fi
}

# Function to hash important binaries and system files
hash_binaries() {
    echo "Hashing important binaries and system files..."
    HASH_FILE="$OUTPUT_DIR/bin_hashes.txt"
    {
        md5 /bin/* /sbin/* /usr/bin/* /usr/sbin/* 2>>"$ERROR_LOG"
    } >> "$HASH_FILE"
}

# Function to zip the resultant directory and clean up
zip_and_cleanup() {
    echo "Zipping the resultant directory..."
    ZIP_FILE="$HOME/${OUTPUT_DIR##*/}.zip"
    zip -r "$ZIP_FILE" "$OUTPUT_DIR" >/dev/null 2>>"$ERROR_LOG"
    
    if [ -f "$ZIP_FILE" ] && [ -s "$ZIP_FILE" ]; then
        echo "Zipped file saved as $ZIP_FILE"
        echo "Cleaning up temporary directory..."
        rm -rf "$OUTPUT_DIR"
        echo "Temporary directory cleaned up"
    else
        log_error "Zip file creation failed or the zip file is empty. Not deleting the temporary directory."
    fi
}

# Main function to call all other functions
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

# Execute the main function
main
