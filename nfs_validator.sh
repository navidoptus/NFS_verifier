#!/bin/bash

# Script Name: nfs_mount_verifier_html_report.sh
# Description: Verifies NFS mounts, generates HTML report with success rate.
# Author: Navid Rastegani
# Email: navid.rastegani@optus.com.au

# --- Configuration ---
# TEMP_FILE - Not needed
# REPORT_FILE - Now for HTML, dynamic

# --- Usage Function ---
usage() {
    echo "Usage: $0 {--capture|--verify}"
    echo "  --capture          Capture state of NFS mounts (no report)."
    echo "  --verify           Verify state and generate HTML report."
    echo " "
    echo "CSV format: ServerName,MountPoint,StateFile (one server per line)"
    exit 1
}

# --- Capture State Function (Unchanged from no_rw_test version) ---
capture_state() {
    local server_name="$1"
    local mount_point="$2"
    local state_file="$3"

    echo "--- Capture Mode for Server: $server_name ---"

    if [ ! -d "$mount_point" ]; then
        echo "Error: Mount point '$mount_point' for '$server_name' does not exist."
        return 1
    fi
    echo "Mount point '$mount_point' exists for '$server_name'."

    mount_info=$(mount | grep "$mount_point")
    mount_info="${mount_info:-Not mounted}" # Handle empty mount_info
    echo "Captured mount info for '$server_name'."

    permissions=$(stat -c "%a" "$mount_point")
    owner=$(stat -c "%U" "$mount_point")
    group=$(stat -c "%G" "$mount_point")
    echo "Captured permissions for '$server_name'."

    echo "Saving state to '$state_file' for '$server_name'..."
    echo "Server Name:" > "$state_file"
    echo "$server_name" >> "$state_file"
    echo "Mount Info:" >> "$state_file"
    echo "$mount_info" >> "$state_file"
    echo "Permissions:" >> "$state_file"
    echo "$permissions" >> "$state_file"
    echo "Owner:" >> "$state_file"
    echo "$owner" >> "$state_file"
    echo "Group:" >> "$state_file"
    echo "$group" >> "$state_file"

    echo "State captured for '$server_name' and saved to '$state_file'."
    return 0
}


# --- Verify State Function (Modified to return statuses) ---
verify_state() {
    local server_name="$1"
    local mount_point="$2"
    local state_file="$3"

    echo "--- Verify Mode for Server: $server_name ---"

    local REPORT_FILE="verification_report_${server_name}.txt" # Still create text reports

    if [ ! -d "$mount_point" ]; then
        echo "Error: Mount point '$mount_point' for '$server_name' does not exist."
        return 1
    fi
    if [ ! -f "$state_file" ]; then
        echo "Error: State file '$state_file' not found for server '$server_name'."
        return 1
    fi

    current_mount_info=$(mount | grep "$mount_point")
    current_mount_info="${current_mount_info:-Not mounted}" # Handle empty current_mount_info
    current_permissions=$(stat -c "%a" "$mount_point")
    current_owner=$(stat -c "%U" "$mount_point")
    current_group=$(stat -c "%G" "$mount_point")

    previous_mount_info=$(sed -n '4p' "$state_file")
    previous_permissions=$(sed -n '6p' "$state_file")
    previous_owner=$(sed -n '8p' "$state_file")
    previous_group=$(sed -n '10p' "$state_file")

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
    echo "Generating text report: '$REPORT_FILE' for '$server_name'..."
    echo "NFS Mount Verification Report for Server: $server_name" > "$REPORT_FILE"
    echo "------------------------------------" >> "$REPORT_FILE"
    echo "Server Name: $server_name" >> "$REPORT_FILE"
    echo "Mount Point: $mount_point" >> "$REPORT_FILE"
    echo "State File: $state_file" >> "$REPORT_FILE"
    echo "$(date)" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"

    echo "--- Mount Information Check ---" >> "$REPORT_FILE"
    echo "Previous: $(echo "$previous_mount_info" | tr -d '[:space:]')" >> "$REPORT_FILE"
    echo "Current: $(echo "$current_mount_info" | tr -d '[:space:]')" >> "$REPORT_FILE"
    echo "Status: $mount_status" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"

    echo "--- Permissions Check ---" >> "$REPORT_FILE"
    echo "Previous: $(echo "$previous_permissions" | tr -d '[:space:]')" >> "$REPORT_FILE"
    echo "Current: $(echo "$current_permissions" | tr -d '[:space:]')" >> "$REPORT_FILE"
    echo "Status: $permissions_status" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"

    echo "--- Owner Check ---" >> "$REPORT_FILE"
    echo "Previous: $(echo "$previous_owner" | tr -d '[:space:]')" >> "$REPORT_FILE"
    echo "Current: $(echo "$current_owner" | tr -d '[:space:]')" >> "$REPORT_FILE"
    echo "Status: $owner_status" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"

    echo "--- Group Check ---" >> "$REPORT_FILE"
    echo "Previous: $(echo "$previous_group" | tr -d '[:space:]')" >> "$REPORT_FILE"
    echo "Current: $(echo "$current_group" | tr -d '[:space:]')" >> "$REPORT_FILE"
    echo "Status: $group_status" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "------------------------------------" >> "$REPORT_FILE"
    echo "Text report saved to '$REPORT_FILE' for '$server_name'" >> "$REPORT_FILE"

    echo "Verification Summary for Server: $server_name"
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
        echo "--- Batch Capture Mode ---"
        while IFS=, read -r server_name mount_point state_file; do
            if [ -n "$server_name" ] && [ -n "$mount_point" ]; then
                capture_state "$server_name" "$mount_point" "$state_file"
                echo "----------------------"
            fi
        done < "$SERVERS_CSV_FILE"
        echo "--- Capture Mode Finished ---"

    ;;
    --verify)
        echo "--- Batch Verify Mode ---"
        while IFS=, read -r server_name mount_point state_file; do
            if [ -n "$server_name" ] && [ -n "$mount_point" ]; then
                result_string=$(verify_state "$server_name" "$mount_point" "$state_file")
                verification_results+=("$result_string") # Add result string to array
                echo "----------------------"
            fi
        done < "$SERVERS_CSV_FILE"
        echo "--- Verify Mode Finished ---"

        # Generate HTML Report
        HTML_REPORT_FILE="nfs_verification_report.html"
        echo "Generating HTML Report: $HTML_REPORT_FILE"

        generate_html_report "$HTML_REPORT_FILE" "${verification_results[@]}"

        echo "HTML Report saved to: $HTML_REPORT_FILE"

    ;;
    *)
        usage
    ;;
esac

exit 0


# --- Function to Generate HTML Report ---
generate_html_report() {
    local html_file="$1"
    local results_array=("${@:2}") # Array of results strings

    # HTML Header
    cat > "$html_file" <<HTML_HEADER
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>NFS Mount Verification Report</title>
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
    <h1 class="report-title">NFS Mount Verification Report</h1>
    <div class="summary-box">
        <h2>Verification Summary</h2>
        <p>This report summarizes the NFS mount verification for servers listed in the CSV file.</p>
        <p><b>Author:</b> Navid Rastegani, <b>Email:</b> navid.rastegani@optus.com.au</p>
HTML_HEADER

    # HTML Table Header
    cat >> "$html_file" <<HTML_TABLE_HEADER
        <table>
            <thead>
                <tr>
                    <th>Server Name</th>
                    <th>Mount Info</th>
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
                    <td class="${mount_status}">${mount_status}</td>
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
        <p><b>Overall Verification Success Rate:</b> <span style="font-size: 1.2em;">${success_rate_percentage}%</span> (${passed_servers} out of ${total_servers} servers passed all checks).</p>
    </div>
</body>
</html>
HTML_TABLE_FOOTER

    echo "HTML report generated: $html_file"
}
