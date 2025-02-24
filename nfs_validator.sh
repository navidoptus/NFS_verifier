#!/bin/bash

# Script Name: nfs_mount_verifier_remote.sh
# Description: Verifies NFS mounts on remote servers via SSH, generates HTML report.
# Author: Navid Rastegani
# Email: navid.rastegani@optus.com.au

# --- Configuration ---
# TEMP_FILE - Not needed
# REPORT_FILE - Now for HTML, dynamic

# --- Usage Function ---
usage() {
    echo "Usage: $0 {--capture|--verify}"
    echo "  --capture          Capture pre-cutover state on remote servers (no report)."
    echo "  --verify           Verify post-cutover state on remote servers and generate HTML report."
    echo " "
    echo "CSV format: ServerName,RemoteHost,SSHUser,MountPoint,StateFile (one server per line)"
    echo "  - ServerName:  Descriptive name for the server (used in reports)."
    echo "  - RemoteHost:  Hostname or IP address of the remote server."
    echo "  - SSHUser:     Username for SSH access to the remote server."
    echo "  - MountPoint:  NFS mount point path on the remote server."
    echo "  - StateFile:   Path to the state file on the jump host (where this script runs)."
    exit 1
}

# --- Capture State Function (Remote Execution via SSH) ---
capture_state() {
    local server_name="$1"
    local remote_host="$2"
    local ssh_user="$3"
    local mount_point="$4"
    local state_file="$5"

    echo "--- PRE-CUTOVER CAPTURE: Server: $server_name (Remote Host: $remote_host) ---"

    # Check if mount point directory exists on the remote server
    if ! ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$ssh_user@$remote_host" "test -d '$mount_point'"; then
        echo "Error: Mount point directory '$mount_point' for '$server_name' (Remote Host: $remote_host) does not exist or is not accessible."
        return 1
    fi
    echo "Mount point directory '$mount_point' exists on '$server_name' (Remote Host: $remote_host)."

    # Capture mount information from the remote server
    mount_info=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$ssh_user@$remote_host" "mount | grep '$mount_point'")
    mount_info="${mount_info:-Not mounted}" # Handle empty mount_info
    echo "Captured mount info (pre-cutover) from '$server_name' (Remote Host: $remote_host)."

    # Capture directory permissions, owner, and group from the remote server
    permissions=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$ssh_user@$remote_host" "stat -c '%a' '$mount_point'")
    owner=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$ssh_user@$remote_host" "stat -c '%U' '$mount_point'")
    group=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$ssh_user@$remote_host" "stat -c '%G' '$mount_point'")
    echo "Captured permissions (pre-cutover) from '$server_name' (Remote Host: $remote_host)."

    # Save state to file (on the jump host - where this script runs)
    echo "Saving PRE-CUTOVER state to '$state_file' (on jump host) for '$server_name' (Remote Host: $remote_host)..."
    echo "Server Name:" > "$state_file"
    echo "$server_name" >> "$state_file"
    echo "Remote Host:" >> "$state_file" # Added Remote Host to state file
    echo "$remote_host" >> "$state_file" # Added Remote Host to state file
    echo "Mount Info:" >> "$state_file"
    echo "$mount_info" >> "$state_file"
    echo "Permissions:" >> "$state_file"
    echo "$permissions" >> "$state_file"
    echo "Owner:" >> "$state_file"
    echo "$owner" >> "$state_file"
    echo "Group:" >> "$state_file"
    echo "$group" >> "$state_file"

    echo "PRE-CUTOVER state captured for '$server_name' (Remote Host: $remote_host) and saved to '$state_file' (on jump host)."
    return 0
}


# --- Verify State Function (Remote Execution via SSH) ---
verify_state() {
    local server_name="$1"
    local remote_host="$2"
    local ssh_user="$3"
    local mount_point="$4"
    local state_file="$5"

    echo "--- POST-CUTOVER VERIFICATION: Server: $server_name (Remote Host: $remote_host) ---"

    local REPORT_FILE="verification_report_${server_name}.txt" # Still create text reports

    # Check if mount point directory exists on the remote server
    if ! ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$ssh_user@$remote_host" "test -d '$mount_point'"; then
        echo "Error: Mount point directory '$mount_point' for '$server_name' (Remote Host: $remote_host) does not exist or is not accessible."
        return 1
    fi
    # Check if state file exists (on the jump host)
    if [ ! -f "$state_file" ]; then
        echo "Error: State file '$state_file' not found (on jump host) for server '$server_name'. Did you run capture mode BEFORE cutover?"
        return 1
    fi

    # Capture current state from remote server via SSH
    current_mount_info=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$ssh_user@$remote_host" "mount | grep '$mount_point'")
    current_mount_info="${current_mount_info:-Not mounted}"
    current_permissions=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$ssh_user@$remote_host" "stat -c '%a' '$mount_point'")
    current_owner=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$ssh_user@$remote_host" "stat -c '%U' '$mount_point'")
    current_group=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$ssh_user@$remote_host" "stat -c '%G' '$mount_point'")

    # Read previous state from state file (on jump host)
    echo "Reading PRE-CUTOVER state from '$state_file' (on jump host) for '$server_name' (Remote Host: $remote_host)..."
    previous_remote_host=$(sed -n '4p' "$state_file") # Line 4: Remote Host from state file
    previous_mount_info=$(sed -n '6p' "$state_file")
    previous_permissions=$(sed -n '8p' "$state_file")
    previous_owner=$(sed -n '10p' "$state_file")
    previous_group=$(sed -n '12p' "$state_file")

    # Initialize statuses
    local mount_status="FAIL"
    local permissions_status="FAIL"
    local owner_status="FAIL"
    local group_status="FAIL"

    # --- Compare Mount Information ---
    if [[ "$(echo "$previous_mount_info" | tr -d '[:space:]')" == "$(echo "$current_mount_info" | tr -d '[:space:]')" ]]; then
        mount_status="PASS"
    fi

    # --- Compare Permissions ---
    if [[ "$(echo "$previous_permissions" | tr -d '[:space:]')" == "$(echo "$current_permissions" | tr -d '[:space:]')" ]]; then
        permissions_status="PASS"
    fi

    # --- Compare Owner ---
    if [[ "$(echo "$previous_owner" | tr -d '[:space:]')" == "$(echo "$current_owner" | tr -d '[:space:]')" ]]; then
        owner_status="PASS"
    fi

    # --- Compare Group ---
    if [[ "$(echo "$previous_group" | tr -d '[:space:]')" == "$(echo "$current_group" | tr -d '[:space:]')" ]]; then
        group_status="PASS"
    fi

    # Generate TEXT report (still helpful for detailed info)
    echo "Generating text report: '$REPORT_FILE' for '$server_name' (Remote Host: $remote_host)..."
    echo "NFS Mount Verification Report (POST-CUTOVER) for Server: $server_name (Remote Host: $remote_host)" > "$REPORT_FILE"
    echo "------------------------------------" >> "$REPORT_FILE"
    echo "Server Name: $server_name" >> "$REPORT_FILE"
    echo "Remote Host: $remote_host" >> "$REPORT_FILE" # Added Remote Host to report
    echo "Mount Point (Remote): $mount_point" >> "$REPORT_FILE" # Clarified Remote
    echo "State File (Pre-Cutover State - on jump host): $state_file" >> "$REPORT_FILE" # Clarified location
    echo "$(date)" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"

    echo "--- Mount Information Check ---" >> "$REPORT_FILE"
    echo "PRE-CUTOVER Mount Info: $(echo "$previous_mount_info" | tr -d '[:space:]')" >> "$REPORT_FILE"
    echo "POST-CUTOVER Mount Info (Remote): $(echo "$current_mount_info" | tr -d '[:space:]')" >> "$REPORT_FILE" # Clarified Remote
    echo "Status: $mount_status" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"

    echo "--- Permissions Check ---" >> "$REPORT_FILE"
    echo "PRE-CUTOVER Permissions: $(echo "$previous_permissions" | tr -d '[:space:]')" >> "$REPORT_FILE"
    echo "POST-CUTOVER Permissions (Remote): $(echo "$current_permissions" | tr -d '[:space:]')" >> "$REPORT_FILE" # Clarified Remote
    echo "Status: $permissions_status" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"

    echo "--- Owner Check ---" >> "$REPORT_FILE"
    echo "PRE-CUTOVER Owner: $(echo "$previous_owner" | tr -d '[:space:]')" >> "$REPORT_FILE"
    echo "POST-CUTOVER Owner (Remote): $(echo "$current_owner" | tr -d '[:space:]')" >> "$REPORT_FILE" # Clarified Remote
    echo "Status: $owner_status" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"

    echo "--- Group Check ---" >> "$REPORT_FILE"
    echo "PRE-CUTOVER Group: $(echo "$previous_group" | tr -d '[:space:]')" >> "$REPORT_FILE"
    echo "POST-CUTOVER Group (Remote): $(echo "$current_group" | tr -d '[:space:]')" >> "$REPORT_FILE" # Clarified Remote
    echo "Status: $group_status" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "------------------------------------" >> "$REPORT_FILE"
    echo "Text report (POST-CUTOVER Verification) saved to '$REPORT_FILE' for '$server_name' (Remote Host: $remote_host)" >> "$REPORT_FILE"

    echo "Verification Summary (POST-CUTOVER) for Server: $server_name (Remote Host: $remote_host)"
    echo "---------------------"
    echo "Mount Info:    $mount_status"
    echo "Permissions:   $permissions_status"
    echo "Owner:         $owner_status"
    echo "Group:         $group_status"
    echo "---------------------"

    # Return statuses as a string for processing in main script
    echo "$server_name,$mount_status,$permissions_status,$owner_status,$group_status"
}


# --- Main Script Logic ---
if [ "$#" -ne 1 ]; then
    usage
fi

MODE="$1"

read -p "Enter path to servers CSV file: " SERVERS_CSV_FILE
if [ ! -f "$SERVERS_CSV_FILE" ]; then
    echo "Error: CSV file '$SERVERS_CSV_FILE' not found."
    exit 1
fi

# Array to store verification results for HTML report
declare -a verification_results=()

case "$MODE" in
    --capture)
        echo "--- PRE-CUTOVER CAPTURE MODE STARTED (Remote Servers via SSH) ---"
        while IFS=, read -r server_name remote_host ssh_user mount_point state_file; do
            if [ -n "$server_name" ] && [ -n "$remote_host" ] && [ -n "$ssh_user" ] && [ -n "$mount_point" ]; then
                echo "Processing server '$server_name' (Remote Host: $remote_host) for PRE-CUTOVER capture..."
                capture_state "$server_name" "$remote_host" "$ssh_user" "$mount_point" "$state_file"
                echo "----------------------"
            fi
        done < "$SERVERS_CSV_FILE"
        echo "--- PRE-CUTOVER CAPTURE MODE FINISHED (Remote Servers via SSH) ---"

    ;;
    --verify)
        echo "--- POST-CUTOVER VERIFICATION MODE STARTED (Remote Servers via SSH) ---"
        while IFS=, read -r server_name remote_host ssh_user mount_point state_file; do
            if [ -n "$server_name" ] && [ -n "$remote_host" ] && [ -n "$ssh_user" ] && [ -n "$mount_point" ]; then
                echo "Processing server '$server_name' (Remote Host: $remote_host) for POST-CUTOVER verification..."
                result_string=$(verify_state "$server_name" "$remote_host" "$ssh_user" "$mount_point" "$state_file")
                verification_results+=("$result_string") # Add result string to array
                echo "----------------------"
            fi
        done < "$SERVERS_CSV_FILE"
        echo "--- POST-CUTOVER VERIFICATION MODE FINISHED (Remote Servers via SSH) ---"

        # Generate HTML Report
        HTML_REPORT_FILE="nfs_verification_report.html"
        echo "Generating POST-CUTOVER HTML Report (for Remote Servers): $HTML_REPORT_FILE"

        generate_html_report "$HTML_REPORT_FILE" "${verification_results[@]}"

        echo "POST-CUTOVER HTML Report (for Remote Servers) saved to: $HTML_REPORT_FILE"

    ;;
    *)
        usage
    ;;
esac

exit 0


# --- Function to Generate HTML Report (Updated for Remote Context) ---
generate_html_report() {
    local html_file="$1"
    local results_array=("${@:2}") # Array of results strings

    # HTML Header
    cat > "$html_file" <<HTML_HEADER
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>NFS Mount Verification Report (Post-Cutover - Remote Servers)</title> # Updated title
    <style>
        body { font-family: sans-serif; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .pass { color: green; font-weight: bold; }
        .fail { color: red; font-weight: bold; }
        .summary-box { border: 1px solid #ccc; padding: 15px; margin-bottom: 20px; border-radius: 5px; }
        .report-title { text-align: center; margin-bottom: 20px; }
    </style>
</head>
<body>
    <h1 class="report-title">NFS Mount Verification Report (Post-Cutover - Remote Servers)</h1> # Updated heading
    <div class="summary-box">
        <h2>Post-Cutover Verification Summary (Remote Servers)</h2> # Updated summary heading
        <p>This report summarizes the NFS mount verification performed AFTER the storage cutover for <b>remote servers</b> listed in the CSV file. It compares the current (post-cutover) configuration against the baseline captured BEFORE the cutover.</p> # Clarified for remote servers
        <p><b>Note:</b> This report reflects the verification of NFS mount points on <b>remote servers accessed via SSH</b> from this jump host.</p> # Added important note about remote access
        <p><b>Author:</b> Navid Rastegani, <b>Email:</b> navid.rastegani@optus.com.au</p>
HTML_HEADER

    # HTML Table Header
    cat >> "$html_file" <<HTML_TABLE_HEADER
        <table>
            <thead>
                <tr>
                    <th>Server Name</th>
                    <th>Remote Host</th> <th>Mount Info</th>
                    <th>Permissions</th>
                    <th>Owner</th>
                    <th>Group</th>
                </tr>
            </thead>
            <tbody>
HTML_TABLE_HEADER

    local total_servers=0
    local passed_servers=0

    # HTML Table Rows - Process each result string from the array
    for result_string in "${results_array[@]}"; do
        total_servers=$((total_servers + 1))
        IFS=, read -r server_name mount_status permissions_status owner_status group_status <<< "$result_string"
        IFS=, read -r server_name remote_host <<< "$result_string" # Extract remote_host for HTML table

        local overall_status="PASS" # Assume PASS initially for each server
        if [[ "$mount_status" == "FAIL" || "$permissions_status" == "FAIL" || "$owner_status" == "FAIL" || "$group_status" == "FAIL" ]]; then
            overall_status="FAIL"
            failed_servers=$((failed_servers + 1))
        else
            passed_servers=$((passed_servers + 1))
        fi

        cat >> "$html_file" <<HTML_TABLE_ROW
                <tr>
                    <td>$server_name</td>
                    <td>$remote_host</td> <td class="${mount_status}">${mount_status}</td>
                    <td class="${permissions_status}">${permissions_status}</td>
                    <td class="${owner_status}">${owner_status}</td>
                    <td class="${group_status}">${group_status}</td>
                </tr>
HTML_TABLE_ROW
    done

    # HTML Table Footer and Summary
    local success_rate_percentage="0"
    if [[ "$total_servers" -gt 0 ]]; then
        success_rate_percentage=$(awk "BEGIN {printf \"%.2f\", ($passed_servers / $total_servers) * 100}")
    fi

    cat >> "$html_file" <<HTML_TABLE_FOOTER
            </tbody>
        </table>
        <p><b>Overall Post-Cutover Verification Success Rate (Remote Servers):</b> <span style="font-size: 1.2em;">${success_rate_percentage}%</span> (${passed_servers} out of ${total_servers} servers passed all checks).</p> # Updated summary text
    </div>
</body>
</html>
HTML_TABLE_FOOTER

    echo "HTML report (POST-CUTOVER - Remote Servers) generated: $html_file" # Updated completion message
}
