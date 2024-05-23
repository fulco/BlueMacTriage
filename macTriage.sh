#!/bin/bash

# Mac Forensics Triage Script - Comprehensive Version
# Author: Fulco
# Version: 0.1a

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Create a directory to store the results
OUTPUT_DIR="/tmp/mac_forensics_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTPUT_DIR"

# Function to collect system information
collect_system_info() {
    echo "Collecting system information..."
    system_profiler SPSoftwareDataType > "$OUTPUT_DIR/system_info.txt"
    system_profiler SPHardwareDataType >> "$OUTPUT_DIR/system_info.txt"
    system_profiler SPNetworkDataType >> "$OUTPUT_DIR/system_info.txt"
    uname -a >> "$OUTPUT_DIR/system_info.txt"
}

# Function to collect user information
collect_user_info() {
    echo "Collecting user information..."
    dscl . list /Users > "$OUTPUT_DIR/users.txt"
    dscl . -list /Groups > "$OUTPUT_DIR/groups.txt"
    for user in $(dscl . list /Users); do
        echo "User: $user" >> "$OUTPUT_DIR/user_details.txt"
        dscl . -read /Users/"$user" >> "$OUTPUT_DIR/user_details.txt"
    done
}

# Function to collect running processes and network connections
collect_processes_network() {
    echo "Collecting running processes and network connections..."
    ps aux > "$OUTPUT_DIR/processes.txt"
    lsof > "$OUTPUT_DIR/open_files.txt"
    netstat -an > "$OUTPUT_DIR/network_connections.txt"
}

# Function to collect installed applications
collect_installed_apps() {
    echo "Collecting installed applications..."
    ls /Applications > "$OUTPUT_DIR/installed_apps.txt"
}

# Function to collect system logs
collect_system_logs() {
    echo "Collecting system logs..."
    cp /var/log/system.log "$OUTPUT_DIR/system.log"
    cp /var/log/kernel.log "$OUTPUT_DIR/kernel.log"
    cp /var/log/install.log "$OUTPUT_DIR/install.log"
    cp /var/log/appfirewall.log "$OUTPUT_DIR/appfirewall.log"
    cp /var/log/secure.log "$OUTPUT_DIR/secure.log"
}

# Function to collect browser history (Safari, Chrome, Firefox)
collect_browser_history() {
    echo "Collecting browser history..."
    
    # Safari
    if [ -d "/Users/$USER/Library/Safari" ]; then
        cp -r "/Users/$USER/Library/Safari" "$OUTPUT_DIR/Safari_History"
    fi
    
    # Chrome
    if [ -d "/Users/$USER/Library/Application Support/Google/Chrome" ]; then
        cp -r "/Users/$USER/Library/Application Support/Google/Chrome" "$OUTPUT_DIR/Chrome_History"
    fi
    
    # Firefox
    if [ -d "/Users/$USER/Library/Application Support/Firefox" ]; then
        cp -r "/Users/$USER/Library/Application Support/Firefox" "$OUTPUT_DIR/Firefox_History"
    fi
}

# Function to collect persistence mechanisms
collect_persistence_mechanisms() {
    echo "Collecting persistence mechanisms..."
    ls /Library/LaunchDaemons > "$OUTPUT_DIR/launchdaemons.txt"
    ls /Library/LaunchAgents > "$OUTPUT_DIR/launchagents.txt"
    crontab -l > "$OUTPUT_DIR/crontab.txt"
    ls /etc/cron.* > "$OUTPUT_DIR/cronjobs.txt"
}

# Function to collect detailed network configurations
collect_network_configurations() {
    echo "Collecting network configurations..."
    ifconfig -a > "$OUTPUT_DIR/network_config.txt"
    scutil --dns > "$OUTPUT_DIR/dns_config.txt"
    scutil --proxy > "$OUTPUT_DIR/proxy_config.txt"
}

# Function to collect disk and file system information
collect_disk_info() {
    echo "Collecting disk and file system information..."
    df -h > "$OUTPUT_DIR/disk_usage.txt"
    diskutil list > "$OUTPUT_DIR/disk_list.txt"
    diskutil info -all > "$OUTPUT_DIR/disk_info.txt"
}

# Function to collect security settings
collect_security_settings() {
    echo "Collecting security settings..."
    csrutil status > "$OUTPUT_DIR/sip_status.txt"
    fdesetup status > "$OUTPUT_DIR/filevault_status.txt"
    spctl --status > "$OUTPUT_DIR/gatekeeper_status.txt"
}

# Function to capture clipboard data
capture_clipboard_data() {
    echo "Capturing clipboard data..."
    pbpaste > "$OUTPUT_DIR/clipboard.txt"
}

# Function to hash important binaries and system files
hash_binaries() {
    echo "Hashing important binaries and system files..."
    md5 /bin/* > "$OUTPUT_DIR/bin_hashes.txt"
    md5 /sbin/* >> "$OUTPUT_DIR/bin_hashes.txt"
    md5 /usr/bin/* >> "$OUTPUT_DIR/bin_hashes.txt"
    md5 /usr/sbin/* >> "$OUTPUT_DIR/bin_hashes.txt"
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
    echo "Forensics data collection complete. Data saved in $OUTPUT_DIR"
}

# Execute the main function
main
# Zip the resultant directory
echo "Zipping the resultant directory..."
zip -r "../$OUTPUT_DIR.zip" "$OUTPUT_DIR"
echo "Zipped file saved as $OUTPUT_DIR.zip"
# Clean up the temporary directory
rm -rf "$OUTPUT_DIR"
echo "Temporary directory cleaned up"
