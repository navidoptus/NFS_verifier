#!/bin/bash

# Script Name: nfs_mount_verifier_no_rw_test.sh
# Description: Verifies and validates NFS mount points for multiple servers from a CSV file,
#              without read/write test, focusing on mount info and permissions.

# --- Configuration ---
# TEMP_FILE="test_file_$$" - No longer needed
# REPORT_FILE="verification_report.txt" - REPORT_FILE is now dynamic

# --- Usage Function ---
usage() {
    echo "Usage: $0 {--capture|--verify}"
    echo "  --capture          Capture the current state of NFS mounts for servers in CSV."
    echo "  --verify           Verify the current state against captured state for servers in CSV."
    echo " "
    echo "CSV file format should be: ServerName,MountPoint,StateFile (one server per line)"
    echo "Example CSV content:"
    echo "server1,/mnt/nfs_mount1,state_server1.txt"
    echo "server2,/mnt/nfs_mount2,state_server2.txt"
    exit 1
}

# --- Capture State Function ---
capture_state() {
    local server_name="$1"
    local mount_point="$2"
    local state_file="$3"

    echo "--- Capture Mode for Server: $server_name ---"

    # Check if mount point directory exists
    if [ ! -d "$mount_point" ]; then
        echo "Error: Mount point directory '$mount_point' for server '$server_name' does not exist."
        return 1
    fi

    echo "Mount point directory '$mount_point' for server '$server_name' exists."

    # Capture mount information
    mount_info=$(mount | grep "$mount_point")
    if [ -z "$mount_info" ]; then
        mount_info="Not mounted"
        echo "Warning: No mount information found for '$mount_point' on server '$server_name'."
    else
        echo "Captured mount information for server '$server_name'."
    fi

    # Capture directory permissions, owner, and group
    permissions=$(stat -c "%a" "$mount_point")
    owner=$(stat -c "%U" "$mount_point")
    group=$(stat -c "%G" "$mount_point")
    echo "Captured directory permissions, owner, and group for server '$server_name'."

    # Save state to file
    echo "Saving state to '$state_file' for server '$server_name'..."
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
    # No Read/Write Test in state file

    echo "State captured and saved to '$state_file' for server '$server_name'."
    return 0
}

# --- Verify State Function ---
verify_state() {
    local server_name="$1"
    local mount_point="$2"
    local state_file="$3"

    echo "--- Verify Mode for Server: $server_name ---"

    # Define report file name dynamically based on server name
    local REPORT_FILE="verification_report_${server_name}.txt"

    # Check if mount point directory exists
    if [ ! -d "$mount_point" ]; then
        echo "Error: Mount point directory '$mount_point' for server '$server_name' does not exist."
        return 1
    fi
    echo "Mount point directory '$mount_point' for server '$server_name' exists."

    # Check if state file exists
    if [ ! -f "$state_file" ]; then
        echo "Error: State file '$state_file' not found for server '$server_name'. Please run in capture mode first."
        return 1
    fi
    echo "State file '$state_file' found for server '$server_name'."

    # Capture current state
    current_mount_info=$(mount | grep "$mount_point")
    if [ -z "$current_mount_info" ]; then
        current_mount_info="Not mounted"
        echo "Warning: No current mount information found for '$mount_point' on server '$server_name'."
    fi
    current_permissions=$(stat -c "%a" "$mount_point")
    current_owner=$(stat -c "%U" "$mount_point")
    current_group=$(stat -c "%G" "$mount_point")

    # No current_rw_test_result capture

    # Read previous state from file
    echo "Reading previous state from '$state_file' for server '$server_name'..."
    previous_server_name=$(sed -n '2p' "$state_file") # Line 2: Server Name (though we already have it)
    previous_mount_info=$(sed -n '4p' "$state_file") # Line 4: Mount Info
    previous_permissions=$(sed -n '6p' "$state_file") # Line 6: Permissions
    previous_owner=$(sed -n '8p' "$state_file")       # Line 8: Owner
    previous_group=$(sed -n '10p' "$state_file")       # Line 10: Group
    # No previous_rw_test_result read

    echo "Generating verification report to '$REPORT_FILE' for server '$server_name'..."
    # Start report generation
    echo "NFS Mount Point Verification Report for Server: $server_name" > "$REPORT_FILE"
    echo "------------------------------------" >> "$REPORT_FILE"
    echo "Server Name: $server_name" >> "$REPORT_FILE"
    echo "Mount Point: $mount_point" >> "$REPORT_FILE"
    echo "State File: $state_file" >> "$REPORT_FILE"
    echo "$(date)" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"

    # --- Compare Mount Information ---
    echo "--- Mount Information Check ---" >> "$REPORT_FILE"
    echo "Previous Mount Info: $(echo "$previous_mount_info" | tr -d '[:space:]')" >> "$REPORT_FILE"
    echo "Current Mount Info: $(echo "$current_mount_info" | tr -d '[:space:]')" >> "$REPORT_FILE"
    if [[ "$(echo "$previous_mount_info" | tr -d '[:space:]')" == "$(echo "$current_mount_info" | tr -d '[:space:]')" ]]; then
        mount_status="Consistent"
        echo "Mount Information: PASS - Mount information is consistent for server '$server_name'."
        echo "Status: PASS" >> "$REPORT_FILE"
    else
        mount_status="Different"
        echo "Mount Information: FAIL - Mount information has changed for server '$server_name'!"
        echo "Status: FAIL" >> "$REPORT_FILE"
    fi
    echo "" >> "$REPORT_FILE"

    # --- Compare Permissions ---
    echo "--- Permissions Check ---" >> "$REPORT_FILE"
    echo "Previous Permissions: $(echo "$previous_permissions" | tr -d '[:space:]')" >> "$REPORT_FILE"
    echo "Current Permissions: $(echo "$current_permissions" | tr -d '[:space:]')" >> "$REPORT_FILE"
    if [[ "$(echo "$previous_permissions" | tr -d '[:space:]')" == "$(echo "$current_permissions" | tr -d '[:space:]')" ]]; then
        permissions_status="Consistent"
        echo "Permissions: PASS - Permissions are consistent for server '$server_name'."
        echo "Status: PASS" >> "$REPORT_FILE"
    else
        permissions_status="Different"
        echo "Permissions: FAIL - Permissions have changed for server '$server_name'!"
        echo "Status: FAIL" >> "$REPORT_FILE"
    fi
    echo "" >> "$REPORT_FILE"

    # --- Compare Owner ---
    echo "--- Owner Check ---" >> "$REPORT_FILE"
    echo "Previous Owner: $(echo "$previous_owner" | tr -d '[:space:]')" >> "$REPORT_FILE"
    echo "Current Owner: $(echo "$current_owner" | tr -d '[:space:]')" >> "$REPORT_FILE"
    if [[ "$(echo "$previous_owner" | tr -d '[:space:]')" == "$(echo "$current_owner" | tr -d '[:space:]')" ]]; then
        owner_status="Consistent"
        echo "Owner: PASS - Owner is consistent for server '$server_name'."
        echo "Status: PASS" >> "$REPORT_FILE"
    else
        owner_status="Different"
        echo "Owner: FAIL - Owner has changed for server '$server_name'!"
        echo "Status: FAIL" >> "$REPORT_FILE"
    fi
    echo "" >> "$REPORT_FILE"

    # --- Compare Group ---
    echo "--- Group Check ---" >> "$REPORT_FILE"
    echo "Previous Group: $(echo "$previous_group" | tr -d '[:space:]')" >> "$REPORT_FILE"
    echo "Current Group: $(echo "$current_group" | tr -d '[:space:]')" >> "$REPORT_FILE"
    if [[ "$(echo "$previous_group" | tr -d '[:space:]')" == "$(echo "$current_group" | tr -d '[:space:]')" ]]; then
        group_status="Consistent"
        echo "Group: PASS - Group is consistent for server '$server_name'."
        echo "Status: PASS" >> "$REPORT_FILE"
    else
        group_status="Different"
        echo "Group: FAIL - Group has changed for server '$server_name'!"
        echo "Status: FAIL" >> "$REPORT_FILE"
    fi
    echo "" >> "$REPORT_FILE"

    # --- Read/Write Test Check --- - Removed

    echo "------------------------------------" >> "$REPORT_FILE"
    echo "Report generated at '$REPORT_FILE' for server '$server_name'" >> "$REPORT_FILE"

    echo ""
    echo "Verification Summary for Server: $server_name"
    echo "---------------------"
    echo "Mount Information: $mount_status"
    echo "Permissions:     $permissions_status"
    echo "Owner:           $owner_status"
    echo "Group:           $group_status"
    # No Read/Write Test in summary
    echo "---------------------"
    echo "Detailed report saved to '$REPORT_FILE' for server '$server_name'."

    return 0
}

# --- Main Script Logic ---
if [ "$#" -ne 1 ]; then
    usage
fi

MODE="$1"

# Ask for CSV file input
read -p "Enter the path to the servers CSV file: " SERVERS_CSV_FILE

# Check if the provided CSV file exists
if [ ! -f "$SERVERS_CSV_FILE" ]; then
    echo "Error: Servers CSV file '$SERVERS_CSV_FILE' not found."
    exit 1
fi

case "$MODE" in
    --capture)
        echo "--- Batch Capture Mode Started ---"
        while IFS=, read -r server_name mount_point state_file; do
            if [ -n "$server_name" ] && [ -n "$mount_point" ]; then # Skip empty lines or lines without server_name/mount_point
                capture_state "$server_name" "$mount_point" "$state_file"
                echo "------------------------------------"
            fi
        done < "$SERVERS_CSV_FILE"
        echo "--- Batch Capture Mode Finished ---"
        ;;
    --verify)
        echo "--- Batch Verify Mode Started ---"
        while IFS=, read -r server_name mount_point state_file; do
            if [ -n "$server_name" ] && [ -n "$mount_point" ]; then # Skip empty lines or lines without server_name/mount_point
                verify_state "$server_name" "$mount_point" "$state_file"
                echo "------------------------------------"
            fi
        done < "$SERVERS_CSV_FILE"
        echo "--- Batch Verify Mode Finished ---"
        ;;
    *)
        usage
        ;;
esac

exit 0
