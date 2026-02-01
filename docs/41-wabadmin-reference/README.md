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
# MFA Enabled:     Yes (TOTP)
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

**Related:** See [High Availability documentation](../10-high-availability/README.md) for detailed cluster management.

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

## External References

- [WALLIX Documentation Portal](https://pam.wallix.one/documentation)
- [WALLIX Admin Guide PDF](https://pam.wallix.one/documentation/admin-doc/bastion_en_administration_guide.pdf)
- [REST API Reference](../26-api-reference/README.md)
- [Operational Runbooks](../30-operational-runbooks/README.md)
- [WALLIX Support Portal](https://support.wallix.com)

---

## Next Steps

Continue to [27 - Error Reference](../27-error-reference/README.md) for error codes and troubleshooting.

---

*Document Version: 1.0*
*Last Updated: January 2026*
