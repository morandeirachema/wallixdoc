# 41 - wabadmin CLI Reference

> Complete command-line reference for WALLIX Bastion 12.x administration.

---

## Table of Contents

1. [Overview](#overview)
2. [Command Syntax Reference](#command-syntax-reference)
3. [Authentication and Session Commands](#authentication-and-session-commands)
4. [User Management Commands](#user-management-commands)
5. [Device Management Commands](#device-management-commands)
6. [Account Management Commands](#account-management-commands)
7. [Authorization Management Commands](#authorization-management-commands)
8. [Password Operations Commands](#password-operations-commands)
9. [Session Management Commands](#session-management-commands)
10. [Cluster and HA Commands](#cluster-and-ha-commands)
11. [Backup Commands](#backup-commands)
12. [License Commands](#license-commands)
13. [Audit and Log Commands](#audit-and-log-commands)
14. [System Status Commands](#system-status-commands)
15. [Configuration Commands](#configuration-commands)
16. [Troubleshooting Commands](#troubleshooting-commands)

---

## Overview

### When to Use CLI vs GUI vs API

| Interface | Best For | Access Method |
|-----------|----------|---------------|
| wabadmin CLI | Automation, scripting, SSH access, cron jobs, bulk operations | SSH to Bastion server |
| Web GUI | Interactive management, visualization, dashboards | Browser via HTTPS |
| REST API | External integration, DevOps, custom applications | HTTPS API calls |

### CLI Advantages

- Scriptable for automation and cron jobs
- Available when web interface is down
- Faster for bulk operations
- Ideal for disaster recovery scenarios
- Can be used in CI/CD pipelines

### Prerequisites

- SSH access to WALLIX Bastion server
- User account with appropriate permissions (admin or operator role for most commands)
- Commands typically run as `wabadmin` user or with `sudo`

### Basic Usage

```bash
wabadmin <command> [subcommand] [options] [arguments]
wabadmin --help                  # Show general help
wabadmin <command> --help        # Show command-specific help
wabadmin --version               # Show version
```

---

## Command Syntax Reference

### Complete Command Table

| Category | Command | Description |
|----------|---------|-------------|
| **General** | `wabadmin status` | Show system status |
| | `wabadmin health-check` | Comprehensive health assessment |
| | `wabadmin version` | Display version |
| **Users** | `wabadmin users` | List all users |
| | `wabadmin user add` | Create user |
| | `wabadmin user show` | Display user details |
| | `wabadmin user modify` | Update user |
| | `wabadmin user delete` | Remove user |
| | `wabadmin user disable/enable` | Disable/enable user |
| | `wabadmin user unlock` | Unlock locked account |
| | `wabadmin user reset-pwd` | Reset password |
| | `wabadmin user reset-mfa` | Reset MFA enrollment |
| **Devices** | `wabadmin devices` | List devices |
| | `wabadmin device add` | Create device |
| | `wabadmin device show` | Display device details |
| | `wabadmin device modify` | Update device |
| | `wabadmin device delete` | Remove device |
| | `wabadmin device test` | Test connectivity |
| | `wabadmin device import/export` | Bulk import/export |
| **Accounts** | `wabadmin accounts` | List accounts |
| | `wabadmin account add` | Create account |
| | `wabadmin account show` | Display account details |
| | `wabadmin account rotate` | Trigger password rotation |
| | `wabadmin account checkout` | Checkout credential |
| | `wabadmin account checkin` | Return credential |
| | `wabadmin account verify` | Verify credentials |
| **Authorizations** | `wabadmin authorizations` | List authorizations |
| | `wabadmin authorization add` | Create authorization |
| | `wabadmin approvals` | List pending approvals |
| | `wabadmin approval approve/deny` | Process approval |
| **Sessions** | `wabadmin sessions` | List sessions |
| | `wabadmin session show` | Display session details |
| | `wabadmin session kill` | Terminate session |
| | `wabadmin recordings` | List recordings |
| | `wabadmin recording export` | Export recording |
| **Cluster/HA** | `wabadmin cluster status` | Show cluster status |
| | `wabadmin cluster failover` | Initiate failover |
| | `wabadmin sync-status` | Show sync status |
| | `wabadmin node standby/online` | Control node |
| **Backup** | `wabadmin backup` | Create backup |
| | `wabadmin restore` | Restore from backup |
| **License** | `wabadmin license-info` | Show license info |
| | `wabadmin license-usage` | Show usage stats |
| | `wabadmin license-install` | Install license |
| **Audit** | `wabadmin audit` | Query audit logs |
| | `wabadmin logs` | View system logs |
| | `wabadmin log-level` | Get/set log level |
| **Config** | `wabadmin config` | View/modify config |
| | `wabadmin ldap-sync` | Sync with LDAP/AD |
| | `wabadmin certificates` | Manage certificates |
| **Diagnostics** | `wabadmin connectivity-test` | Test target connectivity |
| | `wabadmin support-bundle` | Generate support bundle |
| | `wabadmin verify` | Verify system integrity |

---

## Authentication and Session Commands

### wabadmin login

```bash
# Interactive login
wabadmin login --user admin
Password: ********
# Output: Login successful. Session expires in 30 minutes.

# Login with API key
wabadmin login --user admin --api-key "eyJhbGciOiJIUzI1NiIs..."

# Extended timeout
wabadmin login --user admin --timeout 60
```

**Options:** `--user`, `--password`, `--api-key`, `--timeout`

**Common Errors:**
- `Invalid credentials` - Wrong password. Verify credentials.
- `Account locked` - Too many failures. Contact admin.
- `MFA required` - Provide MFA code with `--mfa` option.

**Related:** `wabadmin logout`, `wabadmin whoami`

### wabadmin logout

End current CLI session.

```bash
# End session
wabadmin logout
# Output: Session ended successfully.

# Force logout (ignore errors)
wabadmin logout --force
```

### wabadmin whoami

Display current authenticated user information.

```bash
wabadmin whoami
# Output:
# User: admin
# Role: Administrator
# Groups: admins, auditors
# Session expires: 2026-01-31 15:30:00 UTC
```

---

## User Management Commands

### wabadmin users

```bash
# List all users
wabadmin users
# Output:
# ID       Username    Display Name       Status   Auth Type   Groups
# usr_001  admin       Administrator      active   local       admins
# usr_002  jsmith      John Smith         active   ldap        engineers

# Filter by status
wabadmin users --status active

# Filter by group
wabadmin users --group engineers

# Export to CSV
wabadmin users --format csv --export /tmp/users.csv

# JSON output
wabadmin users --format json
```

**Options:** `--filter`, `--format`, `--count`, `--export`, `--status`, `--group`, `--auth-type`

### wabadmin user show

Display detailed user information.

```bash
wabadmin user show jsmith
# Output:
# User Details: jsmith
# ====================
# ID:              usr_002
# Username:        jsmith
# Display Name:    John Smith
# Email:           jsmith@company.com
# Status:          active
# Auth Type:       ldap
# MFA Enabled:     Yes (FortiToken)
# Groups:          engineers, ot_operators
# Created:         2025-06-15 08:00:00 UTC
# Last Login:      2026-01-31 10:30:00 UTC
# Last Password:   2026-01-15 00:00:00 UTC
# Failed Logins:   0
# Locked:          No
```

### wabadmin user add

```bash
# Create user with generated password
wabadmin user add newuser --display-name "New User" --email "newuser@company.com"
# Output: Username: newuser, Temporary password: Xk9#mP2$vL5@nQ

# Create with specific groups and MFA
wabadmin user add jdoe \
    --display-name "Jane Doe" \
    --email "jdoe@company.com" \
    --groups "operators,engineers" \
    --mfa-required true
```

**Options:** `--display-name`, `--email`, `--password`, `--groups`, `--auth-type`, `--mfa-required`, `--force-pwd-change`

**Common Errors:**
- `Username already exists` - Use unique username.
- `Password too weak` - Meet complexity requirements.

### wabadmin user modify / delete / disable / unlock

```bash
# Modify user
wabadmin user modify jsmith --email "john.smith@company.com"
wabadmin user modify jsmith --add-groups "approvers"

# Delete user
wabadmin user delete vendor1 --force

# Disable/enable
wabadmin user disable jsmith
wabadmin user enable jsmith

# Unlock locked account
wabadmin user unlock jsmith

# Reset password
wabadmin user reset-pwd jsmith
# Output: New temporary password: Tm4#pK9@wN2!qL

# Reset MFA
wabadmin user reset-mfa jsmith
```

---

## Device Management Commands

### wabadmin devices

```bash
# List all devices
wabadmin devices
# Output:
# ID       Name           Host         Domain        Type        Status
# dev_001  web-server-01  10.0.1.10    production    server      online
# dev_003  plc-line1      10.10.1.10   ot_devices    industrial  online

# Filter by domain
wabadmin devices --domain ot_devices

# Filter by protocol
wabadmin devices --protocol ssh
```

### wabadmin device add / test

```bash
# Add SSH device
wabadmin device add web-server-02 \
    --host 10.0.1.11 \
    --domain production \
    --type server \
    --protocol ssh \
    --port 22

# Add multi-protocol device
wabadmin device add multi-server \
    --host 10.0.1.50 \
    --protocols "ssh:22,rdp:3389"

# Test connectivity
wabadmin device test web-server-01
# Output:
# Service  Port  Status  Latency
# ssh      22    OK      5ms

# Test with account verification
wabadmin device test web-server-01 --service ssh --account root
# Output: Authentication: OK (password)
```

### wabadmin device show

Display device details.

```bash
wabadmin device show plc-line1
# Output:
# Device Details: plc-line1
# ========================
# ID:              dev_003
# Name:            plc-line1
# Alias:           PLC-LINE-1
# Host:            10.10.1.10
# Domain:          ot_devices
# Type:            industrial
# Description:     Production Line 1 PLC Controller
# Status:          online
# Last Seen:       2026-01-31 14:45:00 UTC
# Created:         2025-03-20 10:00:00 UTC
#
# Services:
# ---------
# Protocol    Port    Subprotocols
# ssh         22      SSH_SHELL_SESSION, SSH_SCP
# telnet      23      TELNET
#
# Accounts:
# ---------
# Name        Type      Last Rotation       Auto Rotate
# root        local     2026-01-15          Yes (90 days)
# admin       local     2026-01-15          Yes (90 days)
```

### wabadmin device modify / delete

```bash
# Modify device host
wabadmin device modify plc-line1 --host 10.10.1.15

# Update description
wabadmin device modify plc-line1 --description "Production Line 1 PLC - Updated"

# Add new service/protocol
wabadmin device modify plc-line1 --add-service "vnc:5900"

# Delete device (with confirmation)
wabadmin device delete old-server
# WARNING: This will delete device 'old-server' and all associated accounts.
# Associated accounts: 3
# Type 'old-server' to confirm: old-server
# Output: Device old-server deleted successfully. Deleted accounts: 3

# Force delete without confirmation
wabadmin device delete old-server --force
```

### wabadmin device import / export

```bash
# Export to CSV
wabadmin device export --format csv --output /tmp/devices.csv
# Output: Exported 25 devices to /tmp/devices.csv

# Export to JSON
wabadmin device export --format json --output /tmp/devices.json

# Import from CSV (with preview)
wabadmin device import --input /tmp/new-devices.csv --dry-run
# Output:
# Import preview (dry run):
#   Devices to create: 10
#   Devices to update: 0
#   Errors: 0
# No changes made.

# Execute import
wabadmin device import --input /tmp/new-devices.csv
# Output: Imported 10 devices successfully.
```

**Common Errors:**
- `Connection refused` - Service not running on target. Check target service.
- `Connection timeout` - Firewall blocking access. Check firewall rules.
- `Host not found` - DNS resolution failed. Check DNS or use IP address.

---

## Account Management Commands

### wabadmin accounts

```bash
# List accounts
wabadmin accounts
# Output:
# ID       Name   Device          Domain       Type   Auto Rotate
# acc_001  root   web-server-01   production   local  Yes (30d)

# Filter by device
wabadmin accounts --device web-server-01

# Filter by rotation status
wabadmin accounts --filter "rotation_status=failed"
```

### wabadmin account add / rotate / checkout

```bash
# Add account with password
wabadmin account add root \
    --device web-server-02 \
    --type local \
    --password "SecureP@ss123!" \
    --auto-rotate true \
    --rotation-period 30d

# Rotate password
wabadmin account rotate acc_001
# Output:
# Connecting to target... OK
# Changing password... OK
# Verifying new password... OK

# Force rotation with verbose output
wabadmin account rotate acc_001 --force --verbose

# Checkout credential
wabadmin account checkout acc_001 --reason "Maintenance #12345" --duration 60
# Output: Password: Xk9#mP2$vL5@nQ8!wM4$rT, Expires in 60 minutes

# Check in credential
wabadmin account checkin chk_001

# Verify credentials
wabadmin account verify acc_001
```

### wabadmin account show

Display detailed account information.

```bash
wabadmin account show acc_001
# Output:
# Account Details: root@web-server-01
# ===================================
# ID:                 acc_001
# Name:               root
# Device:             web-server-01 (10.0.1.10)
# Domain:             production
# Type:               local
# Credential Type:    password
# Status:             active
#
# Rotation Settings:
# ------------------
# Auto Rotate:        Yes
# Rotation Period:    30 days
# Last Rotation:      2026-01-15 02:00:00 UTC
# Next Rotation:      2026-02-14 02:00:00 UTC
# Rotation Status:    Success
#
# Checkout Policy:
# ----------------
# Checkout Mode:      exclusive
# Max Duration:       60 minutes
# Require Reason:     Yes
#
# Usage Statistics:
# -----------------
# Total Checkouts:    45
# Last Checkout:      2026-01-31 10:00:00 UTC
# Last Checkout By:   jsmith
```

**Common Rotation Errors:**
- `Connection refused` - Target unreachable. Check network connectivity.
- `Authentication failed` - Current password invalid. Manual password update required.
- `Permission denied` - Insufficient rights. Check account permissions on target.
- `Password complexity failed` - New password does not meet target policy.

---

## Authorization Management Commands

### wabadmin authorizations / approvals

```bash
# List authorizations
wabadmin authorizations
# Output:
# ID        Name                User Group     Target Group   Recorded  Approval
# auth_001  admins-to-servers   admins         all_servers    Yes       No
# auth_002  engineers-to-plcs   ot_engineers   plc_devices    Yes       Yes

# Create authorization
wabadmin authorization add \
    --name "operators-to-hmi" \
    --user-group "operators" \
    --target-group "hmi_stations" \
    --recorded true

# Create time-limited authorization with approval
wabadmin authorization add \
    --name "vendor-maint-CHG123" \
    --user-group "vendor-acme" \
    --target-group "maintenance-targets" \
    --start-time "2026-02-01T22:00:00" \
    --end-time "2026-02-02T06:00:00" \
    --approval-required true \
    --approvers "ot_supervisors"

# List pending approvals
wabadmin approvals --status pending
# Output:
# ID       Requestor  Target               Authorization        Requested At
# apr_001  vendor1    robot-ctrl-1/admin   vendors-to-robots    2026-01-31 14:00

# Approve/deny requests
wabadmin approval approve apr_001 --comment "Approved for maintenance"
wabadmin approval deny apr_002 --comment "Requires supervisor approval"
```

### wabadmin authorization show / modify / delete

```bash
# Show authorization details
wabadmin authorization show auth_002
# Output:
# Authorization Details: engineers-to-plcs
# =========================================
# ID:                 auth_002
# Name:               engineers-to-plcs
# Description:        OT Engineers access to PLC devices
# Status:             active
#
# User Group:         ot_engineers (15 members)
# Target Group:       plc_devices (25 devices)
# Accounts:           root, admin, engineer
#
# Settings:
# ---------
# Recorded:           Yes
# Critical:           No
# Approval Required:  Yes
# Approval Timeout:   30 minutes
# Approvers:          ot_supervisors, ot_managers
#
# Time Restrictions:
# ------------------
# Enabled:            Yes
# Days:               Monday-Friday
# Hours:              08:00 - 18:00
# Timezone:           America/New_York

# Modify authorization
wabadmin authorization modify auth_001 --approval-required true --approvers "admins"

# Modify time restrictions
wabadmin authorization modify auth_002 \
    --time-restrictions true \
    --allowed-days "mon,tue,wed,thu,fri" \
    --allowed-hours "08:00-18:00"

# Delete authorization
wabadmin authorization delete auth_005 --confirm
```

---

## Password Operations Commands

### wabadmin rotation

```bash
# View rotation queue
wabadmin rotation --queue
# Output:
# ID       Account              Device          Scheduled For
# rot_001  root@web-server-01   web-server-01   2026-02-01 02:00

# View rotation history
wabadmin rotation --history --last 7d

# View failed rotations
wabadmin rotation --failed
# Output:
# ID       Account              Device          Error
# rot_102  root@legacy-server   legacy-server   Connection timeout

# Retry failed rotation
wabadmin rotation --retry rot_102

# Rotate all accounts in target group
wabadmin rotation --target-group "production-servers" --execute

# Dry run
wabadmin rotation --filter "password_age > 60d" --dry-run
# Output: Would rotate: 2 accounts
```

**Options:** `--queue`, `--history`, `--failed`, `--retry`, `--target-group`, `--last`, `--execute`, `--dry-run`

**Rotation Troubleshooting:**

| Error | Cause | Solution |
|-------|-------|----------|
| Connection timeout | Target unreachable | Check network/firewall |
| Authentication failed | Current password invalid | Manual password update |
| Permission denied | Insufficient rights | Check account permissions |
| Password policy violation | Complexity not met | Adjust password policy |
| Account locked | Too many failures | Unlock account on target |

---

## Session Management Commands

### wabadmin sessions / recordings

```bash
# List active sessions
wabadmin sessions --status active
# Output:
# ID        User     Device        Account  Protocol  Duration
# ses_001   jsmith   plc-line1     root     ssh       30m

# Filter sessions
wabadmin sessions --user jsmith --last 7d
wabadmin sessions --protocol rdp --status active

# Session details
wabadmin session show ses_001

# Terminate session
wabadmin session kill ses_001 --reason "Security incident"

# Terminate all sessions for user
wabadmin sessions --user compromised_user --kill-all

# List recordings
wabadmin recordings --last 7d
# Output:
# ID       Session   User     Device        Date               Size    Duration
# rec_001  ses_001   jsmith   plc-line1     2026-01-31 14:00   2.5 MB  35m

# Search recordings
wabadmin recordings --search "rm -rf" --last 30d

# Export recording
wabadmin recording export rec_001 --output /tmp/recording.wab
wabadmin recording export rec_001 --format mp4 --output /tmp/session.mp4

# Verify recording integrity
wabadmin recording verify rec_001
# Output:
# Verifying recording rec_001...
#
# Recording ID:    rec_001
# Session ID:      ses_001
# File:            /var/lib/wallix/recordings/2026/01/31/rec_001.wab
# Size:            2,621,440 bytes
# Checksum:        SHA256: abc123def456...
# Signature:       Valid
# Tamper Detection: No tampering detected
#
# Recording integrity verified successfully.
```

**Session Command Options:**

| Command | Options |
|---------|---------|
| `sessions` | `--status`, `--user`, `--device`, `--protocol`, `--last`, `--format`, `--kill-all` |
| `session show` | `--verbose` |
| `session kill` | `--reason`, `--notify`, `--force` |
| `recordings` | `--user`, `--device`, `--last`, `--search`, `--format` |
| `recording export` | `--format`, `--output`, `--start-time`, `--end-time` |

---

## Cluster and HA Commands

### wabadmin cluster status / failover

```bash
# Cluster status
wabadmin cluster status
# Output:
# Cluster: wallix-prod
# Mode: Active-Passive
# Status: Healthy
#
# Node            Role      Status   Services   Replication
# bastion-node1   Primary   Online   Running    N/A (Primary)
# bastion-node2   Standby   Online   Ready      In sync (0 sec lag)
#
# Virtual IP: 192.168.1.10 (on bastion-node1)

# Detailed status
wabadmin cluster status --verbose

# Synchronization status
wabadmin sync-status
# Output:
# Database Replication: In sync, Lag: 0 bytes
# Configuration Sync: Synchronized

# Manual failover
wabadmin cluster failover --confirm
# Type 'FAILOVER' to confirm: FAILOVER
# Output: Failover complete. New primary: bastion-node2

# Node control
wabadmin node standby bastion-node1
# Output: Putting bastion-node1 in standby mode... Node is now in standby.

wabadmin node online bastion-node1
# Output: Bringing bastion-node1 online... Node is now online.
```

**Cluster Status Indicators:**

| Status | Meaning | Action |
|--------|---------|--------|
| Healthy | All nodes operational | None required |
| Degraded | One node offline | Investigate failed node |
| Split Brain | Both nodes think they are primary | Manual intervention required |
| Replication Lag | Standby behind primary | Check network/IO |

**Related:** See [High Availability documentation](../11-high-availability/README.md) for detailed cluster management.

---

## Backup Commands

### wabadmin backup / restore

```bash
# Full backup
wabadmin backup --full --output /var/backup/wallix/full-$(date +%Y%m%d).tar.gz
# Output:
# Database: OK (1.2 GB)
# Configuration: OK (15 MB)
# Backup created: full-20260131.tar.gz (1.3 GB)

# Configuration-only backup
wabadmin backup --config-only --output /var/backup/wallix/config.tar.gz

# Encrypted backup
wabadmin backup --full --encrypt --output /var/backup/wallix/encrypted.tar.gz
# Enter encryption password: ********

# Verify backup
wabadmin backup --verify /var/backup/wallix/full-20260131.tar.gz
# Output: Backup verification successful.

# List backups
wabadmin backup --list

# Full restore
wabadmin restore --full --input /var/backup/wallix/full-20260131.tar.gz
# Type 'RESTORE' to confirm: RESTORE

# Configuration-only restore
wabadmin restore --config-only --input /var/backup/wallix/config.tar.gz
```

**Backup Options:**

| Option | Description |
|--------|-------------|
| `--full` | Full backup (all data) |
| `--config-only` | Configuration only (no recordings) |
| `--database-only` | Database only |
| `--output, -o` | Output file path |
| `--encrypt` | Encrypt backup with password |
| `--verify` | Verify backup after creation or verify existing backup |
| `--list` | List available backups |

**Common Errors:**
- `Insufficient disk space` - Free disk space before backup.
- `Permission denied` - Check directory permissions.
- `Database locked` - Wait for active operations to complete.

**Backup Best Practices:**
- Daily configuration backups with 30-day retention
- Weekly full backups with 90-day retention
- Monthly offsite backups with 1-year retention
- Always verify backups after creation

---

## License Commands

### wabadmin license-info / license-usage

```bash
# License information
wabadmin license-info
# Output:
# Customer: ACME Corporation
# License Type: Enterprise
# Valid Until: 2026-12-31 (334 days remaining)
#
# Limits:
# Max Sessions: 1000
# Max Users: 500
# Max Devices: 2000
#
# Features: Session Recording, Password Management, HA Clustering

# License usage
wabadmin license-usage --report
# Output:
# Peak Concurrent Sessions: 78
# Current Users: 150 (30% of 500)
# Current Devices: 500 (25% of 2000)

# Install new license
wabadmin license-install --file /tmp/new-license.lic
wabadmin license-install --key "XXXX-XXXX-XXXX-XXXX"
# Output: License installed successfully.
```

**License Thresholds:**

| Usage Level | Recommendation |
|-------------|----------------|
| 0-60% | Normal operation |
| 60-80% | Plan capacity increase |
| 80-90% | Initiate license expansion |
| 90%+ | Critical - risk of denial |

---

## Audit and Log Commands

### wabadmin audit / logs

```bash
# Recent audit events
wabadmin audit --last 24h
# Output:
# Timestamp            Event Type        User     Target           Status
# 2026-01-31 14:30:00  session.start     jsmith   plc-line1/root   success
# 2026-01-31 13:30:00  auth.login_failed unknown  (web)            failure

# Filter by event type
wabadmin audit --event-type "auth.login_failed" --last 7d

# Filter by user
wabadmin audit --user jsmith --last 30d --summary
# Output:
# Event Type          Count  Last Occurrence
# session.start       45     2026-01-31 14:30
# auth.login          52     2026-01-31 13:00

# Export audit logs
wabadmin audit --last 30d --export /tmp/audit.json --format json
wabadmin audit --last 24h --format cef --export /tmp/audit.cef

# View system logs
wabadmin logs --last 100
wabadmin logs --component session-proxy --last 50
wabadmin logs --follow

# Set log level
wabadmin log-level
wabadmin log-level set --component session-proxy --level DEBUG
wabadmin log-level reset --all
```

**Event Types:**

| Event | Description |
|-------|-------------|
| `auth.login` | User login |
| `auth.login_failed` | Failed login attempt |
| `auth.logout` | User logout |
| `session.start` | Session established |
| `session.end` | Session closed normally |
| `session.terminate` | Session forcibly terminated |
| `approval.request` | Access approval requested |
| `approval.granted` | Access approval granted |
| `approval.denied` | Access approval denied |
| `password.rotate` | Password rotated |
| `password.checkout` | Credential checked out |
| `config.change` | Configuration modified |
| `user.create` | User created |
| `user.modify` | User modified |
| `user.delete` | User deleted |

**Audit Options:**

| Option | Description |
|--------|-------------|
| `--filter, -f` | Filter expression |
| `--last` | Events from last N hours/days (e.g., 24h, 7d) |
| `--user` | Filter by user |
| `--event-type` | Filter by event type |
| `--severity` | Filter: info, warning, error, critical |
| `--export` | Export to file |
| `--format` | Output: table, json, csv, cef |
| `--summary` | Show event summary/statistics |

**Log Components:**

| Component | Description |
|-----------|-------------|
| `application` | Main application log |
| `session-proxy` | Session proxy log |
| `password-manager` | Password manager log |
| `api` | REST API log |
| `database` | Database operations log |

---

## System Status Commands

### wabadmin status / health-check

```bash
# Basic status
wabadmin status
# Output:
# WALLIX Bastion Status
# Version: 12.1.1
# Status: Running
# Uptime: 47 days
# Active Sessions: 15
# Cluster: Active-Passive (Healthy)

# Detailed status
wabadmin status --verbose

# Health check
wabadmin health-check
# Output:
# Component              Status   Details
# System Services        OK       All services running
# Database               OK       Connected
# Disk Space             OK       24% used
# Cluster Status         OK       All nodes healthy
# Certificates           WARNING  1 expires in 45 days
#
# Overall Status: HEALTHY (1 warning)

# Verify system integrity
wabadmin verify --full
# Output:
# System Integrity Verification
# =============================
#
# Component                     Status    Details
# ----------------------------------------------------------------
# Configuration Files           OK        All files present, valid
# Database Schema               OK        Schema version matches
# Encryption Keys               OK        Keys accessible, valid
# Recording Files               OK        12,500 files verified
# Session Data                  OK        Consistent with database
# User Permissions              OK        No orphaned permissions
# Authorization Rules           OK        All rules valid
# Certificate Chain             OK        Valid chain of trust
# Audit Log Integrity           OK        No gaps detected
#
# Verification complete. No issues found.
```

**Health Check Components:**

| Component | Description | Warning Threshold |
|-----------|-------------|-------------------|
| System Services | All services running | Any stopped |
| Database | Database connectivity | Connection errors |
| Disk Space | Available storage | > 70% used |
| Memory | Memory utilization | > 80% used |
| Cluster Status | HA cluster health | Node offline |
| Database Replication | Replication lag | > 1 MB lag |
| License | License validity | < 30 days remaining |
| Certificates | SSL certificate expiry | < 60 days remaining |

---

## Configuration Commands

### wabadmin config / ldap-sync / certificates

```bash
# Show configuration
wabadmin config --show

# Get specific value
wabadmin config --get session_timeout
# Output: session_timeout: 30 minutes

# Set configuration
wabadmin config --set session_timeout=45

# Verify configuration
wabadmin config --verify
# Output: Configuration valid. No issues found.

# LDAP sync status
wabadmin ldap-sync --status
# Output:
# Server: ldaps://dc.company.com:636
# Last Sync: 2026-01-31 14:00:00 UTC
# Users synced: 150

# Force LDAP sync
wabadmin ldap-sync --run

# Test LDAP connection
wabadmin ldap-sync --test

# List certificates
wabadmin certificates --list
# Output:
# Name         Path                          Expires      Status
# Web SSL      /etc/wallix/ssl/server.crt    2026-06-15   OK
# Syslog TLS   /etc/wallix/ssl/syslog.crt    2026-03-17   Warning

# Check expiring certificates
wabadmin certificates --expiring 90d

# Show certificate details
wabadmin certificates --show "Web SSL"
# Output:
# Certificate: Web SSL
# --------------------
# Path:         /etc/wallix/ssl/server.crt
# Subject:      CN=bastion.company.com
# Issuer:       CN=Company CA
# Valid From:   2025-06-15 00:00:00 UTC
# Valid Until:  2026-06-15 23:59:59 UTC
# Days Until Expiry: 135
# Key Type:     RSA 4096
# Fingerprint:  SHA256:abc123def456...
```

**Configuration Parameters:**

| Parameter | Description | Default |
|-----------|-------------|---------|
| `session_timeout` | Session timeout in minutes | 30 |
| `max_failed_logins` | Max failed login attempts | 5 |
| `lockout_duration` | Lockout duration in minutes | 15 |
| `mfa_required` | Require MFA for admin users | true |
| `max_session_duration` | Max session duration in hours | 8 |
| `recording_enabled` | Enable session recording | true |
| `keystroke_logging` | Enable keystroke logging | true |

---

## Troubleshooting Commands

### wabadmin connectivity-test / support-bundle

```bash
# Test specific target
wabadmin connectivity-test --target plc-line1
# Output:
# Network: OK (3ms)
# Services: ssh (22): OK, telnet (23): OK

# Test with credential verification
wabadmin connectivity-test --target plc-line1 --account root
# Output: Authentication: OK (password)

# Test sample of targets
wabadmin connectivity-test --sample 10
# Output: Passed: 9/10, Failed: 1 (hmi-station1 - rdp timeout)

# Test all targets in domain
wabadmin connectivity-test --domain ot_devices

# Generate support bundle
wabadmin support-bundle --output /tmp/wallix-support.tar.gz
# Output: Bundle created: wallix-support.tar.gz (45 MB)

# Maintenance mode
wabadmin maintenance-mode --enable
# Output: Maintenance mode enabled. New sessions blocked.

wabadmin maintenance-mode --disable
```

### wabadmin dr-promote

Promote DR site to primary (disaster recovery).

```bash
# On secondary site - promote to primary
wabadmin dr-promote --confirm
# WARNING: This will promote this site to primary.
# Current primary site will be demoted.
# Type 'PROMOTE' to confirm: PROMOTE
# Output:
# Promoting to primary...
# Step 1/4: Promoting database... Done
# Step 2/4: Starting services... Done
# Step 3/4: Updating configuration... Done
# Step 4/4: Verifying operation... Done
#
# Site promoted to primary successfully.
```

### wabadmin key-management

Manage encryption keys.

```bash
# Show key status
wabadmin key-management --status
# Output:
# Master Key Status
# =================
# Key ID:        mk-2025-001
# Created:       2025-01-01 00:00:00 UTC
# Algorithm:     AES-256-GCM
# Status:        Active

# Rotate master key (requires planning)
wabadmin key-management rotate-master-key --confirm
# WARNING: This operation will re-encrypt all stored credentials.
# Duration may take 30+ minutes depending on vault size.
# Ensure all backup systems are updated after completion.
```

**Diagnostic Tools Summary:**

| Tool | Purpose | When to Use |
|------|---------|-------------|
| `connectivity-test` | Test target connectivity | Connection issues |
| `support-bundle` | Generate diagnostics | Support cases |
| `verify` | System integrity check | Post-upgrade, incidents |
| `maintenance-mode` | Block new sessions | Planned maintenance |
| `dr-promote` | DR site promotion | Disaster recovery |

---

## Quick Reference

### Common Command Combinations

```bash
# Morning health check
wabadmin status && wabadmin health-check && wabadmin cluster status

# Check for issues
wabadmin audit --event-type "auth.login_failed" --last 24h
wabadmin rotation --failed
wabadmin sessions --status active

# Before maintenance
wabadmin backup --full --output /var/backup/pre-maint-$(date +%Y%m%d).tar.gz
wabadmin maintenance-mode --enable

# After maintenance
wabadmin maintenance-mode --disable
wabadmin health-check && wabadmin verify --full

# Emergency response
wabadmin sessions --kill-all --confirm
wabadmin user disable <compromised_user>
wabadmin audit --user <compromised_user> --export /tmp/incident.json
```

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| 2 | Invalid arguments |
| 3 | Permission denied |
| 4 | Resource not found |
| 5 | Connection error |
| 6 | Authentication failed |
| 10 | Configuration error |
| 20 | Cluster error |
| 30 | Database error |

### Environment Variables

| Variable | Description |
|----------|-------------|
| `WABADMIN_USER` | Default username for login |
| `WABADMIN_API_KEY` | API key for authentication |
| `WABADMIN_TIMEOUT` | Default command timeout in seconds |
| `WABADMIN_FORMAT` | Default output format (table, json, csv) |
| `WABADMIN_NO_COLOR` | Disable colored output |

### Scripting Examples

```bash
#!/bin/bash
# Daily health check script

# Set error handling
set -e

echo "=== WALLIX Bastion Daily Health Check ==="
echo "Date: $(date)"
echo ""

# Check status
echo "--- System Status ---"
wabadmin status

# Check for failed rotations
echo ""
echo "--- Failed Rotations ---"
FAILED=$(wabadmin rotation --failed --count 2>/dev/null || echo "0")
if [ "$FAILED" -gt 0 ]; then
    echo "WARNING: $FAILED failed rotations"
    wabadmin rotation --failed
else
    echo "No failed rotations"
fi

# Check for failed logins
echo ""
echo "--- Failed Logins (last 24h) ---"
wabadmin audit --event-type "auth.login_failed" --last 24h --count

# Check disk space
echo ""
echo "--- Disk Usage ---"
df -h /var/lib/wallix /var/log/wallix 2>/dev/null || df -h /

# Check cluster status
echo ""
echo "--- Cluster Status ---"
wabadmin cluster status 2>/dev/null || echo "Standalone deployment"

echo ""
echo "=== Health Check Complete ==="
```

---

## Real-World Usage Scenarios

This section provides practical, production-ready examples for common administrative tasks.

### Scenario 1: Daily Password Rotation Health Check

**Use Case:** Automated cron job to verify password rotation status and alert on failures.

```bash
#!/bin/bash
# /opt/scripts/wallix-rotation-check.sh
# Daily password rotation health check
# Run via cron: 0 8 * * * /opt/scripts/wallix-rotation-check.sh

LOG_FILE="/var/log/wallix/rotation-check.log"
ALERT_EMAIL="sysadmin@company.com"
FAILED_ROTATIONS=0

echo "=== WALLIX Password Rotation Check ===" | tee -a "$LOG_FILE"
echo "Date: $(date)" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Check rotation status for last 24 hours
echo "Checking accounts rotated in last 24 hours..." | tee -a "$LOG_FILE"
ROTATED=$(wabadmin account list --filter "last_rotation>=$(date -d '1 day ago' +%Y-%m-%d)" --format json)

if [ -z "$ROTATED" ]; then
    echo "WARNING: No password rotations in last 24 hours" | tee -a "$LOG_FILE"
fi

# Check for failed rotations
echo "" | tee -a "$LOG_FILE"
echo "Checking for failed rotations..." | tee -a "$LOG_FILE"
FAILED=$(wabadmin account list --filter "rotation_status=failed" --format json)

if [ -n "$FAILED" ]; then
    FAILED_COUNT=$(echo "$FAILED" | jq '. | length')
    echo "CRITICAL: $FAILED_COUNT accounts with failed rotation" | tee -a "$LOG_FILE"
    echo "$FAILED" | jq -r '.[] | "  - \(.device_name):\(.account_name) - \(.rotation_error)"' | tee -a "$LOG_FILE"
    FAILED_ROTATIONS=1
fi

# Check accounts overdue for rotation
echo "" | tee -a "$LOG_FILE"
echo "Checking for overdue rotations (>90 days)..." | tee -a "$LOG_FILE"
OVERDUE=$(wabadmin account list --filter "days_since_rotation>90" --format json)

if [ -n "$OVERDUE" ]; then
    OVERDUE_COUNT=$(echo "$OVERDUE" | jq '. | length')
    echo "WARNING: $OVERDUE_COUNT accounts overdue for rotation" | tee -a "$LOG_FILE"
    echo "$OVERDUE" | jq -r '.[] | "  - \(.device_name):\(.account_name) - \(.days_since_rotation) days"' | tee -a "$LOG_FILE"
fi

# Send alert if failures detected
if [ $FAILED_ROTATIONS -eq 1 ]; then
    echo "" | tee -a "$LOG_FILE"
    echo "Sending alert email..." | tee -a "$LOG_FILE"
    mail -s "WALLIX: Password Rotation Failures Detected" "$ALERT_EMAIL" < "$LOG_FILE"
fi

echo "" | tee -a "$LOG_FILE"
echo "=== Check Complete ===" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
```

**Cron Configuration:**
```bash
# Add to /etc/cron.d/wallix-checks
0 8 * * * root /opt/scripts/wallix-rotation-check.sh
```

**Expected Output:**
```
=== WALLIX Password Rotation Check ===
Date: 2026-02-04 08:00:15

Checking accounts rotated in last 24 hours...
Found 45 accounts rotated

Checking for failed rotations...
CRITICAL: 2 accounts with failed rotation
  - srv-db-01:oracle - Connection timeout
  - srv-web-05:root - Authentication failed

Checking for overdue rotations (>90 days)...
WARNING: 3 accounts overdue for rotation
  - legacy-server:admin - 125 days
  - test-vm:root - 95 days
  - backup-nas:service - 110 days

Sending alert email...

=== Check Complete ===
```

### Scenario 2: Emergency Session Termination

**Use Case:** Immediately kill a suspicious active session and lock the user account.

```bash
#!/bin/bash
# /opt/scripts/wallix-kill-session.sh <session-id>
# Emergency session termination with user lockout

SESSION_ID="$1"

if [ -z "$SESSION_ID" ]; then
    echo "Usage: $0 <session-id>"
    exit 1
fi

echo "=== Emergency Session Termination ==="
echo "Session ID: $SESSION_ID"
echo ""

# Get session details
echo "1. Retrieving session information..."
SESSION_INFO=$(wabadmin session show "$SESSION_ID" --format json)

if [ -z "$SESSION_INFO" ]; then
    echo "ERROR: Session not found"
    exit 1
fi

USERNAME=$(echo "$SESSION_INFO" | jq -r '.username')
TARGET=$(echo "$SESSION_INFO" | jq -r '.target_device')
PROTOCOL=$(echo "$SESSION_INFO" | jq -r '.protocol')

echo "   User: $USERNAME"
echo "   Target: $TARGET"
echo "   Protocol: $PROTOCOL"
echo ""

# Kill the session
echo "2. Terminating session..."
wabadmin session kill "$SESSION_ID" --reason "Security incident - unauthorized activity detected"

if [ $? -eq 0 ]; then
    echo "   ✓ Session terminated successfully"
else
    echo "   ✗ Failed to terminate session"
    exit 1
fi
echo ""

# Lock the user account
echo "3. Locking user account..."
wabadmin user disable "$USERNAME" --reason "Account locked due to security incident"

if [ $? -eq 0 ]; then
    echo "   ✓ User account locked"
else
    echo "   ✗ Failed to lock account"
fi
echo ""

# Create incident report
INCIDENT_FILE="/var/log/wallix/incidents/incident-$(date +%Y%m%d-%H%M%S).txt"
mkdir -p /var/log/wallix/incidents

cat > "$INCIDENT_FILE" <<EOF
WALLIX Security Incident Report
================================

Timestamp: $(date)
Incident ID: INC-$(date +%Y%m%d-%H%M%S)

Session Details:
  Session ID: $SESSION_ID
  Username: $USERNAME
  Target Device: $TARGET
  Protocol: $PROTOCOL

Actions Taken:
  1. Session terminated
  2. User account disabled

Next Steps:
  - Review session recording
  - Investigate user activity
  - Contact security team
  - Review target system for compromise

---
Generated by: wallix-kill-session.sh
EOF

echo "4. Incident report created: $INCIDENT_FILE"
echo ""
echo "=== Termination Complete ==="
echo ""
echo "NEXT STEPS:"
echo "  1. Review session recording:"
echo "     wabadmin session recording $SESSION_ID"
echo "  2. View full audit trail:"
echo "     wabadmin audit --user $USERNAME --last 24h"
echo "  3. Check target system logs on: $TARGET"
echo "  4. Contact: security@company.com"
```

**Usage Example:**
```bash
# Terminate session SES-2026-0204-ABC123
/opt/scripts/wallix-kill-session.sh SES-2026-0204-ABC123
```

### Scenario 3: Bulk Device Onboarding from CSV

**Use Case:** Import 100+ servers from CSV file with automatic account discovery.

```bash
#!/bin/bash
# /opt/scripts/wallix-bulk-import.sh <csv-file>
# Bulk import devices from CSV with validation

CSV_FILE="$1"
LOG_FILE="/var/log/wallix/bulk-import-$(date +%Y%m%d-%H%M%S).log"
SUCCESS_COUNT=0
FAILED_COUNT=0

if [ -z "$CSV_FILE" ] || [ ! -f "$CSV_FILE" ]; then
    echo "Usage: $0 <csv-file>"
    echo "CSV Format: hostname,ip_address,os_type,domain,description"
    exit 1
fi

echo "=== WALLIX Bulk Device Import ===" | tee -a "$LOG_FILE"
echo "CSV File: $CSV_FILE" | tee -a "$LOG_FILE"
echo "Started: $(date)" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Validate CSV header
HEADER=$(head -n1 "$CSV_FILE")
EXPECTED="hostname,ip_address,os_type,domain,description"

if [ "$HEADER" != "$EXPECTED" ]; then
    echo "ERROR: Invalid CSV header" | tee -a "$LOG_FILE"
    echo "Expected: $EXPECTED" | tee -a "$LOG_FILE"
    echo "Got: $HEADER" | tee -a "$LOG_FILE"
    exit 1
fi

# Process each device
echo "Processing devices..." | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

tail -n +2 "$CSV_FILE" | while IFS=',' read -r hostname ip_address os_type domain description; do
    echo "[$((SUCCESS_COUNT + FAILED_COUNT + 1))] Processing: $hostname ($ip_address)" | tee -a "$LOG_FILE"

    # Validate IP address
    if ! echo "$ip_address" | grep -qE '^([0-9]{1,3}\.){3}[0-9]{1,3}$'; then
        echo "   ✗ FAILED: Invalid IP address" | tee -a "$LOG_FILE"
        ((FAILED_COUNT++))
        continue
    fi

    # Test connectivity
    if ! ping -c 1 -W 2 "$ip_address" &>/dev/null; then
        echo "   ⚠ WARNING: Device not reachable (continuing anyway)" | tee -a "$LOG_FILE"
    fi

    # Create device
    wabadmin device add \
        --name "$hostname" \
        --host "$ip_address" \
        --type "$os_type" \
        --domain "$domain" \
        --description "$description" \
        --auto-discover-accounts \
        >> "$LOG_FILE" 2>&1

    if [ $? -eq 0 ]; then
        echo "   ✓ SUCCESS: Device created" | tee -a "$LOG_FILE"
        ((SUCCESS_COUNT++))

        # Trigger account discovery
        echo "   → Triggering account discovery..." | tee -a "$LOG_FILE"
        wabadmin device discover-accounts "$hostname" >> "$LOG_FILE" 2>&1
    else
        echo "   ✗ FAILED: Device creation failed (see log)" | tee -a "$LOG_FILE"
        ((FAILED_COUNT++))
    fi

    echo "" | tee -a "$LOG_FILE"

    # Rate limiting to avoid overwhelming the system
    sleep 1
done

# Summary
echo "=== Import Complete ===" | tee -a "$LOG_FILE"
echo "Finished: $(date)" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "Summary:" | tee -a "$LOG_FILE"
echo "  Success: $SUCCESS_COUNT devices" | tee -a "$LOG_FILE"
echo "  Failed:  $FAILED_COUNT devices" | tee -a "$LOG_FILE"
echo "  Total:   $((SUCCESS_COUNT + FAILED_COUNT)) devices" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "Log file: $LOG_FILE" | tee -a "$LOG_FILE"
```

**Example CSV File (devices.csv):**
```csv
hostname,ip_address,os_type,domain,description
srv-web-01,10.10.2.10,linux,Production,Web Server - Apache
srv-web-02,10.10.2.11,linux,Production,Web Server - Nginx
srv-db-01,10.10.2.20,linux,Production,Database Server - PostgreSQL
srv-db-02,10.10.2.21,linux,Production,Database Server - MySQL
win-dc-01,10.10.0.10,windows,Management,Active Directory DC
win-app-01,10.10.2.30,windows,Production,Windows App Server
```

**Usage:**
```bash
/opt/scripts/wallix-bulk-import.sh /tmp/devices.csv
```

### Scenario 4: Weekly Compliance Report Generation

**Use Case:** Automated weekly compliance report for audit purposes.

```bash
#!/bin/bash
# /opt/scripts/wallix-compliance-report.sh
# Weekly compliance report generation
# Run via cron: 0 9 * * 1 /opt/scripts/wallix-compliance-report.sh

REPORT_DIR="/var/reports/wallix"
REPORT_DATE=$(date +%Y-%m-%d)
REPORT_FILE="$REPORT_DIR/compliance-report-$REPORT_DATE.txt"
WEEK_AGO=$(date -d '7 days ago' +%Y-%m-%d)

mkdir -p "$REPORT_DIR"

cat > "$REPORT_FILE" <<EOF
================================================================================
                    WALLIX BASTION COMPLIANCE REPORT
================================================================================

Report Date: $REPORT_DATE
Period: $WEEK_AGO to $REPORT_DATE
Generated: $(date)

================================================================================
1. SESSION ACTIVITY SUMMARY
================================================================================

EOF

# Session statistics
echo "Total sessions this week:" >> "$REPORT_FILE"
wabadmin sessions --filter "start_date>=$WEEK_AGO" --count >> "$REPORT_FILE"

echo "" >> "$REPORT_FILE"
echo "Sessions by protocol:" >> "$REPORT_FILE"
wabadmin sessions --filter "start_date>=$WEEK_AGO" --group-by protocol --count >> "$REPORT_FILE"

echo "" >> "$REPORT_FILE"
echo "Top 10 users by session count:" >> "$REPORT_FILE"
wabadmin sessions --filter "start_date>=$WEEK_AGO" --group-by username --count --limit 10 >> "$REPORT_FILE"

cat >> "$REPORT_FILE" <<EOF

================================================================================
2. PASSWORD ROTATION COMPLIANCE
================================================================================

EOF

echo "Accounts with successful rotation:" >> "$REPORT_FILE"
wabadmin account list --filter "rotation_status=success,last_rotation>=$WEEK_AGO" --count >> "$REPORT_FILE"

echo "" >> "$REPORT_FILE"
echo "Accounts with failed rotation:" >> "$REPORT_FILE"
wabadmin account list --filter "rotation_status=failed" --format table >> "$REPORT_FILE"

echo "" >> "$REPORT_FILE"
echo "Accounts overdue for rotation (>90 days):" >> "$REPORT_FILE"
wabadmin account list --filter "days_since_rotation>90" --format table >> "$REPORT_FILE"

cat >> "$REPORT_FILE" <<EOF

================================================================================
3. USER ACCOUNT AUDIT
================================================================================

EOF

echo "Total active users:" >> "$REPORT_FILE"
wabadmin users --filter "status=active" --count >> "$REPORT_FILE"

echo "" >> "$REPORT_FILE"
echo "New users created this week:" >> "$REPORT_FILE"
wabadmin users --filter "created>=$WEEK_AGO" --format table >> "$REPORT_FILE"

echo "" >> "$REPORT_FILE"
echo "Disabled users:" >> "$REPORT_FILE"
wabadmin users --filter "status=disabled" --format table >> "$REPORT_FILE"

echo "" >> "$REPORT_FILE"
echo "Users with MFA enabled:" >> "$REPORT_FILE"
MFA_ENABLED=$(wabadmin users --filter "mfa_enabled=true" --count)
TOTAL_USERS=$(wabadmin users --count)
MFA_PERCENT=$((MFA_ENABLED * 100 / TOTAL_USERS))
echo "  $MFA_ENABLED / $TOTAL_USERS ($MFA_PERCENT%)" >> "$REPORT_FILE"

cat >> "$REPORT_FILE" <<EOF

================================================================================
4. SECURITY EVENTS
================================================================================

EOF

echo "Failed login attempts:" >> "$REPORT_FILE"
wabadmin audit --filter "event_type=login_failed,timestamp>=$WEEK_AGO" --count >> "$REPORT_FILE"

echo "" >> "$REPORT_FILE"
echo "Emergency session terminations:" >> "$REPORT_FILE"
wabadmin audit --filter "event_type=session_killed,timestamp>=$WEEK_AGO" --format table >> "$REPORT_FILE"

echo "" >> "$REPORT_FILE"
echo "Administrative changes:" >> "$REPORT_FILE"
wabadmin audit --filter "event_type=config_change,timestamp>=$WEEK_AGO" --format table >> "$REPORT_FILE"

cat >> "$REPORT_FILE" <<EOF

================================================================================
5. SYSTEM HEALTH
================================================================================

EOF

echo "Cluster status:" >> "$REPORT_FILE"
wabadmin ha-status >> "$REPORT_FILE"

echo "" >> "$REPORT_FILE"
echo "Database replication lag:" >> "$REPORT_FILE"
wabadmin db-replication-status >> "$REPORT_FILE"

echo "" >> "$REPORT_FILE"
echo "Storage usage:" >> "$REPORT_FILE"
wabadmin storage-status >> "$REPORT_FILE"

cat >> "$REPORT_FILE" <<EOF

================================================================================
END OF REPORT
================================================================================

Report generated by: wallix-compliance-report.sh
For questions, contact: compliance@company.com

EOF

# Send report via email
echo "Compliance report generated: $REPORT_FILE"
echo "Sending report via email..."

mail -s "WALLIX Compliance Report - $REPORT_DATE" \
     -a "$REPORT_FILE" \
     compliance@company.com,soc@company.com \
     <<< "Weekly WALLIX compliance report attached. Please review."

echo "Report sent successfully"
```

**Cron Configuration:**
```bash
# Run every Monday at 9 AM
0 9 * * 1 root /opt/scripts/wallix-compliance-report.sh
```

### Scenario 5: Credential Checkout with Auto-Checkin

**Use Case:** Temporary credential checkout for maintenance window with automatic return.

```bash
#!/bin/bash
# /opt/scripts/wallix-checkout-credential.sh <device> <account> <duration-minutes>
# Checkout credential with automatic checkin after specified duration

DEVICE="$1"
ACCOUNT="$2"
DURATION="${3:-60}"  # Default 60 minutes

if [ -z "$DEVICE" ] || [ -z "$ACCOUNT" ]; then
    echo "Usage: $0 <device> <account> [duration-minutes]"
    echo "Example: $0 srv-db-01 oracle 120"
    exit 1
fi

echo "=== WALLIX Credential Checkout ==="
echo "Device: $DEVICE"
echo "Account: $ACCOUNT"
echo "Duration: $DURATION minutes"
echo ""

# Checkout credential
echo "Checking out credential..."
CHECKOUT_RESULT=$(wabadmin account checkout "$DEVICE:$ACCOUNT" --format json)

if [ $? -ne 0 ]; then
    echo "ERROR: Checkout failed"
    exit 1
fi

PASSWORD=$(echo "$CHECKOUT_RESULT" | jq -r '.password')
CHECKOUT_ID=$(echo "$CHECKOUT_RESULT" | jq -r '.checkout_id')

echo "✓ Credential checked out successfully"
echo ""
echo "Checkout ID: $CHECKOUT_ID"
echo "Password: $PASSWORD"
echo ""
echo "⚠ IMPORTANT: Credential will auto-checkin in $DURATION minutes"
echo ""

# Schedule automatic checkin
(
    sleep $((DURATION * 60))
    echo "Auto-checkin at $(date)..."
    wabadmin account checkin "$CHECKOUT_ID"
    echo "Credential returned to vault"
) &

echo "Auto-checkin scheduled (PID: $!)"
echo ""
echo "To manually checkin before timeout:"
echo "  wabadmin account checkin $CHECKOUT_ID"
```

**Usage Examples:**
```bash
# Checkout for 60 minutes (default)
/opt/scripts/wallix-checkout-credential.sh srv-db-01 oracle

# Checkout for 2 hours
/opt/scripts/wallix-checkout-credential.sh srv-db-01 oracle 120

# Checkout for emergency (4 hours)
/opt/scripts/wallix-checkout-credential.sh srv-web-01 root 240
```

### Quick Reference Command Cheatsheet

```bash
# Daily Operations
wabadmin status                                    # System health check
wabadmin sessions --active                          # View active sessions
wabadmin account list --filter rotation_status=failed  # Check rotation failures

# User Management
wabadmin user disable jsmith --reason "Terminated"  # Disable user
wabadmin user reset-mfa jsmith                      # Reset MFA for user
wabadmin users --filter last_login<$(date -d '90 days ago' +%Y-%m-%d)  # Inactive users

# Emergency Operations
wabadmin session kill SES-123 --reason "Security incident"  # Kill session
wabadmin user unlock jsmith                         # Unlock locked account
wabadmin ha-failover                                # Force HA failover

# Reporting
wabadmin sessions --filter "start_date>=2026-02-01" --count  # Monthly sessions
wabadmin audit --user jsmith --last 7d               # User activity last week
wabadmin account list --filter days_since_rotation>90  # Overdue rotations

# Bulk Operations
wabadmin device import devices.csv                   # Import devices from CSV
wabadmin account rotate --filter "auto_rotate=true"  # Rotate all auto-rotate accounts
wabadmin user export users.csv                       # Export all users

# Troubleshooting
wabadmin health-check                                # Comprehensive health check
wabadmin db-replication-status                       # Check DB replication
wabadmin logs --tail 100 --follow                    # Tail system logs
```

---

## External References

- [WALLIX Documentation Portal](https://pam.wallix.one/documentation)
- [WALLIX Admin Guide PDF](https://pam.wallix.one/documentation/admin-doc/bastion_en_administration_guide.pdf)
- [REST API Reference](../17-api-reference/README.md)
- [Operational Runbooks](../21-operational-runbooks/README.md)
- [WALLIX Support Portal](https://support.wallix.com)

---

## See Also

**Related Sections:**
- [17 - API Reference](../17-api-reference/README.md) - REST API documentation
- [10 - API & Automation](../10-api-automation/README.md) - API usage and automation
- [13 - Troubleshooting](../13-troubleshooting/README.md) - Diagnostics using CLI

**Official Resources:**
- [WALLIX Documentation](https://pam.wallix.one/documentation)

---

## Next Steps

Continue to [27 - Error Reference](../18-error-reference/README.md) for error codes and troubleshooting.

---

*Document Version: 1.0*
*Last Updated: January 2026*
