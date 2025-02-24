# NFS Mount Point Verifier

## Overview
A Bash script for validating NFS mount points on remote Linux servers from a central jump host. The script generates comprehensive HTML reports and is particularly useful for verifying NFS configurations during storage cutovers or system changes across distributed environments.

## Key Features
- Remote NFS mount point verification via SSH
- HTML report generation with success rate calculation
- CSV-based input for bulk server processing
- Detailed state comparison reporting
- Pre and post-cutover verification workflow
- Error handling with graceful recovery

## Prerequisites
- Bash shell environment
- Standard Linux utilities (mount, stat, grep, sed, date, ssh)
- SSH access to remote servers
- Write permissions on jump host
- Web browser for HTML report viewing

## CSV Configuration
The script requires a CSV file with the following fields:

```csv
ServerName,RemoteHost,SSHUser,MountPoint,StateFile
webserver-01,webserver-01.internal,nfs_admin,/mnt/nfs_data,/tmp/nfs_state_web01.txt
appserver-02,10.0.10.50,ops_user,/mnt/nfs_logs,/tmp/nfs_state_app02.txt
db-server-03,db-server.prod,backup_svc,/mnt/nfs_backup,/tmp/nfs_state_db03.txt
```

### Field Descriptions
- **ServerName**: Unique server identifier used in reporting
- **RemoteHost**: Hostname or IP of the remote server
- **SSHUser**: Username for SSH connection
- **MountPoint**: NFS mount point directory path
- **StateFile**: Path for storing state information (on jump host)

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

3. Configure SSH access:
   - Set up SSH key-based authentication (recommended)
   - Ensure SSHUser has required permissions on remote hosts

### Pre-Cutover Capture Mode
Run the script with --capture flag:
```bash
./nfs_validator.sh --capture
```

The script will:
1. Request CSV file path
2. Connect to each remote server via SSH
3. Validate mount point existence
4. Capture mount details and permissions
5. Save state information on jump host

### Post-Cutover Verify Mode
Execute with --verify flag:
```bash
./nfs_validator.sh --verify
```

The script will:
1. Request CSV file path
2. Connect to remote servers via SSH
3. Compare current state against saved state
4. Generate individual text reports
5. Create consolidated HTML report
6. Display console summary

## Output Format

### Console Summary
```
Verification Summary for Server: webserver-01 (Remote Host: webserver-01.internal)
---------------------
Mount Info:    PASS
Permissions:   PASS
Owner:         PASS
Group:         PASS
---------------------
```

### Text Reports
The script generates `verification_report_<ServerName>.txt` containing:
- Server and remote host identification
- Mount point details
- Pre and post-cutover state comparison
- Verification timestamps
- Detailed comparison results

### HTML Report
Generates `nfs_verification_report.html` featuring:
- Tabulated results for all servers
- Remote host information
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
- SSH connection failures
- Invalid script arguments
- Missing CSV files
- Non-existent mount points
- Missing state files
- Authentication errors

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
