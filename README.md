# NFS Mount Point Verifier

## Overview
A Bash script for validating NFS mount points across multiple servers. Particularly useful for system administrators managing storage cutovers or NFS configuration changes.

## Key Features
- Automated verification of multiple NFS mount points
- CSV-based input for bulk server processing
- Comprehensive mount point validation
- Detailed reporting with state comparison
- Error handling with graceful recovery

## Prerequisites
- Bash shell environment
- Standard Linux utilities (mount, stat, grep, sed, touch, rm, date)
- Write permissions in script directory
- Read/write access to NFS mount points

## CSV Configuration
The script requires a CSV file with the following fields:

```csv
ServerName,MountPoint,StateFile
webserver-01,/mnt/nfs_data,/tmp/nfs_state_web01.txt
appserver-02,/mnt/nfs_logs,/tmp/nfs_state_app02.txt
db-server-03,/mnt/nfs_backup,/tmp/nfs_state_db03.txt
```

### Field Descriptions
- **ServerName**: Unique server identifier
- **MountPoint**: NFS mount point directory path
- **StateFile**: Path for state information storage

## Usage Instructions

### Script Setup
1. Download the script:
   ```bash
   curl -O nfs_mount_verifier_csv_input.sh
   ```

2. Set execution permissions:
   ```bash
   chmod +x nfs_mount_verifier_csv_input.sh
   ```

### Capture Mode
Run the script with --capture flag:
```bash
./nfs_mount_verifier_csv_input.sh --capture
```

The script will:
1. Request CSV file path
2. Validate mount point existence
3. Capture mount details and permissions
4. Perform read/write testing
5. Save state information

### Verify Mode
Execute with --verify flag:
```bash
./nfs_mount_verifier_csv_input.sh --verify
```

The script will:
1. Request CSV file path
2. Compare current state against saved state
3. Generate verification reports
4. Display console summary

## Output Format

### Console Summary
```
Verification Summary for Server: webserver-01
---------------------
Mount Information: Consistent
Permissions:       Consistent
Owner:             Consistent
Group:             Consistent
Read/Write Test:   Consistent
---------------------
```

### Detailed Reports
The script generates `verification_report_<ServerName>.txt` containing:
- Server identification
- Mount point details
- State comparison results
- Verification timestamps
- Test outcomes

## Error Handling
The script manages common issues:
- Invalid script arguments
- Missing CSV files
- Non-existent mount points
- Missing state files
- Failed read/write tests

## Repository Structure
```
.
├── nfs_mount_verifier_csv_input.sh
├── README.md
├── servers.csv.example
└── LICENSE
```

## Support
For issues or contributions, please use the GitHub repository's issue tracker.

## License
This project is licensed under the MIT License - see the LICENSE file for details.
