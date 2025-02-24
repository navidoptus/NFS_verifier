# NFS Mount Point Verifier 

## Overview
A Bash script for validating NFS mount points with HTML report generation capabilities. The script focuses on mount information and permissions verification, providing both detailed text reports and a consolidated HTML summary with success rates.

## Key Features
- Mount point and permission validation
- CSV-based input for bulk server processing
- HTML report generation with success rate calculation
- Individual text reports for detailed analysis
- Error handling with graceful recovery
- No read/write testing for improved performance

## Prerequisites
- Bash shell environment
- Standard Linux utilities (mount, stat, grep, sed, date, awk)
- Write permissions in script directory

## CSV Configuration
The script requires a CSV file with the following fields:

```csv
ServerName,MountPoint,StateFile
webserver-01,/mnt/nfs_data,/tmp/nfs_state_web01.txt
appserver-02,/mnt/nfs_logs,/tmp/nfs_state_app02.txt
db-server-03,/mnt/nfs_backup,/tmp/nfs_state_db03.txt
```

### Field Descriptions
- **ServerName**: Unique server identifier used in reporting
- **MountPoint**: NFS mount point directory path
- **StateFile**: Path for storing state information

## Usage Instructions

### Script Setup
1. Download the script:
   ```bash
   curl -O nfs_validator.sh
   ```

2. Set execution permissions:
   ```bash
   chmod +x nfs_validator.sh
   ```

### Capture Mode
Run the script with --capture flag:
```bash
./nfs_validator.sh --capture
```

The script will:
1. Request CSV file path
2. Validate mount point existence
3. Capture mount details and permissions
4. Save state information

### Verify Mode
Execute with --verify flag:
```bash
./nfs_validator.sh --verify
```

The script will:
1. Request CSV file path
2. Compare current state against saved state
3. Generate individual text reports
4. Create consolidated HTML report
5. Display console summary

## Output Format

### Console Summary
```
Verification Summary for Server: webserver-01
---------------------
Mount Info:    PASS
Permissions:   PASS
Owner:         PASS
Group:         PASS
---------------------
```

### Text Reports
The script generates `verification_report_<ServerName>.txt` containing:
- Server identification
- Mount point details
- State comparison results
- Verification timestamps
- Detailed comparison of each check

### HTML Report
Generates `nfs_verification_report.html` featuring:
- Tabulated results for all servers
- Status indicators (PASS/FAIL) with colour coding
- Overall success rate percentage
- Total servers verified
- Pass/fail statistics

## Verification Checks
The script verifies:
1. Mount Information
   - Mount point existence
   - NFS configuration
   - Mount options

2. Access Controls
   - Directory permissions
   - Owner settings
   - Group settings

## Error Handling
The script manages common issues:
- Invalid script arguments
- Missing CSV files
- Non-existent mount points
- Missing state files
- Empty mount information

## Repository Structure
```
.
├── nfs_validator.sh
├── README.md
├── servers.csv.example
└── LICENSE
```

## Support
For issues or contributions, please use the GitHub repository's issue tracker.

## License
This project is licensed under the MIT License - see the LICENSE file for details.

## Author
Navid Rastegani  
Email: navid.rastegani@optus.com.au
