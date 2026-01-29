# 00 - Quick Start Guide

## Your First 30 Minutes with WALLIX PAM4OT

This guide gets you operational quickly. Read this first, then explore deeper sections.

---

## What is PAM? (2 minutes)

```
+==============================================================================+
|                   WHY PAM EXISTS                                             |
+==============================================================================+

  THE PROBLEM (Without PAM)
  =========================

  Traditional Access:
  +------------------------------------------------------------------------+
  |                                                                        |
  |   User -----> SSH/RDP -----> Server                                    |
  |         (direct connection)                                            |
  |                                                                        |
  |   Issues:                                                              |
  |   - Shared passwords ("everyone uses root")                            |
  |   - No audit trail ("who logged in last Tuesday?")                     |
  |   - No session recording ("what did the vendor do?")                   |
  |   - Password sprawl ("500 servers = 500 passwords")                    |
  |   - No emergency cutoff ("revoke access NOW")                          |
  |                                                                        |
  +------------------------------------------------------------------------+

  THE SOLUTION (With PAM)
  =======================

  PAM-Controlled Access:
  +------------------------------------------------------------------------+
  |                                                                        |
  |   User -----> WALLIX -----> Server                                     |
  |         (authenticated)  (credential injected)                         |
  |                                                                        |
  |   Benefits:                                                            |
  |   - Individual accountability (each user has own login)                |
  |   - Full audit trail (who, what, when, where)                          |
  |   - Session recording (video playback of every action)                 |
  |   - Centralized passwords (vault manages all credentials)              |
  |   - Instant revocation (disable user = no access anywhere)             |
  |                                                                        |
  +------------------------------------------------------------------------+

+==============================================================================+
```

---

## WALLIX Components (3 minutes)

```
+==============================================================================+
|                   WALLIX BASTION COMPONENTS                                  |
+==============================================================================+

  WHAT DOES EACH COMPONENT DO?
  ============================

  +------------------------------------------------------------------------+
  |                                                                        |
  |  +------------------+                                                  |
  |  | ACCESS MANAGER   |  "The Front Door"                                |
  |  +------------------+                                                  |
  |  | - Web portal for users                                              |
  |  | - Admin console for configuration                                   |
  |  | - API for automation                                                |
  |  | - Authentication (login/MFA)                                        |
  |  +------------------+                                                  |
  |           |                                                            |
  |           v                                                            |
  |  +------------------+                                                  |
  |  | SESSION MANAGER  |  "The Traffic Cop"                               |
  |  +------------------+                                                  |
  |  | - Proxies all connections (SSH, RDP, VNC, etc.)                     |
  |  | - Records sessions (video + keystrokes)                             |
  |  | - Enforces policies (time limits, command blocking)                 |
  |  | - Injects credentials (user never sees password)                    |
  |  +------------------+                                                  |
  |           |                                                            |
  |           v                                                            |
  |  +------------------+                                                  |
  |  | PASSWORD MANAGER |  "The Vault"                                     |
  |  +------------------+                                                  |
  |  | - Stores all credentials encrypted                                  |
  |  | - Rotates passwords automatically                                   |
  |  | - Provides credentials on-demand                                    |
  |  | - Verifies passwords still work                                     |
  |  +------------------+                                                  |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  HOW THEY WORK TOGETHER
  ======================

  1. User logs into ACCESS MANAGER (web portal)
  2. User selects a target server
  3. SESSION MANAGER retrieves password from PASSWORD MANAGER
  4. SESSION MANAGER connects to target, injects password
  5. User works normally, session is recorded
  6. Session ends, recording is stored for audit

+==============================================================================+
```

---

## Key Concepts (5 minutes)

### The Object Hierarchy

```
+==============================================================================+
|                   WALLIX OBJECT MODEL                                        |
+==============================================================================+

  UNDERSTANDING THE HIERARCHY
  ===========================

  Think of it like organizing files:

  +------------------------------------------------------------------------+
  |                                                                        |
  |  DOMAIN (folder)                                                       |
  |  +-- "Production-OT"                                                   |
  |      |                                                                 |
  |      +-- DEVICE (server/equipment)                                     |
  |      |   +-- "plc-line1" (10.10.1.10)                                  |
  |      |   +-- "plc-line2" (10.10.1.11)                                  |
  |      |   +-- "hmi-station1" (10.10.1.20)                               |
  |      |                                                                 |
  |      +-- Each DEVICE has SERVICES (how to connect)                     |
  |      |   +-- SSH (port 22)                                             |
  |      |   +-- RDP (port 3389)                                           |
  |      |   +-- VNC (port 5900)                                           |
  |      |                                                                 |
  |      +-- Each DEVICE has ACCOUNTS (credentials)                        |
  |          +-- "root" (password in vault)                                |
  |          +-- "admin" (password in vault)                               |
  |          +-- "operator" (password in vault)                            |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  CONNECTING USERS TO TARGETS
  ===========================

  +------------------------------------------------------------------------+
  |                                                                        |
  |  USER GROUPS              TARGET GROUPS           AUTHORIZATION        |
  |  +-----------+            +------------+          +-------------+      |
  |  | OT-Admins |---+    +---| PLC-Root   |          |             |      |
  |  +-----------+   |    |   +------------+          | OT-Admins   |      |
  |                  +----+                      +--->| can access  |      |
  |  +-----------+   |    |   +------------+    |     | PLC-Root    |      |
  |  | Operators |---+    +---| HMI-User   |----+     | via SSH     |      |
  |  +-----------+            +------------+          | recorded    |      |
  |                                                   +-------------+      |
  |                                                                        |
  |  USER GROUP: Collection of users (e.g., all OT administrators)         |
  |  TARGET GROUP: Collection of accounts (e.g., all PLC root accounts)    |
  |  AUTHORIZATION: Links user group to target group with policies         |
  |                                                                        |
  +------------------------------------------------------------------------+

+==============================================================================+
```

### Quick Terminology

| Term | What It Means | Example |
|------|---------------|---------|
| **Domain** | Container for organizing devices | "Production-OT", "Test-Lab" |
| **Device** | A server, PLC, HMI, or any target | "plc-line1" at 10.10.1.10 |
| **Service** | Protocol to connect | SSH, RDP, VNC, Telnet |
| **Account** | Credentials on a device | "root" on "plc-line1" |
| **User** | Person logging into WALLIX | "jsmith" |
| **User Group** | Collection of users | "OT-Administrators" |
| **Target Group** | Collection of accounts | "All-PLC-Root-Accounts" |
| **Authorization** | Permission linking users to targets | "OT-Admins can access PLCs" |

---

## Your First Tasks (10 minutes)

### Task 1: Check System Health

```bash
# Is WALLIX running?
systemctl status wallix-pam4ot

# Quick health check
wabadmin status

# Check license
wabadmin license-info

# If clustered, check cluster
crm status
```

**Expected output:**
```
WALLIX PAM4OT Status: Running
  - Access Manager: OK
  - Session Manager: OK
  - Password Manager: OK
  - Database: OK
```

### Task 2: View Active Sessions

```bash
# List all active sessions
wabadmin sessions --status active

# Count active sessions
wabadmin sessions --status active --count
```

### Task 3: Check Recent Audit

```bash
# Last 10 audit events
wabadmin audit --last 10

# Failed logins in last hour
wabadmin audit --type auth.failure --since "1 hour ago"
```

### Task 4: Access the Web Console

1. Open browser: `https://<wallix-ip>`
2. Login with your admin credentials
3. Navigate to: **Audit > Sessions** to see recorded sessions
4. Navigate to: **Configuration > Devices** to see managed targets

---

## Common Day-1 Questions

### "How do I add a new server?"

```
Configuration > Devices > Add Device

Fill in:
- Device name: srv-prod-01
- Host: 192.168.1.100
- Domain: Production
- Description: Production web server

Then add service (SSH/RDP) and account (root/admin)
```

### "How do I give someone access?"

```
1. Ensure user exists (Configuration > Users)
2. Ensure user is in a group (Configuration > User Groups)
3. Ensure target is in a group (Configuration > Target Groups)
4. Create authorization linking them (Configuration > Authorizations)
```

### "How do I see what someone did?"

```
Audit > Sessions > Find the session > Click to view recording

Or via CLI:
wabadmin sessions --user jsmith --date 2024-01-15
wabadmin recording play <session-id>
```

### "How do I rotate a password?"

```bash
# Rotate single account
wabadmin account rotate root@srv-prod-01

# Rotate all accounts in domain
wabadmin rotation --domain Production --execute
```

### "How do I terminate a session NOW?"

```bash
# List active sessions
wabadmin sessions --status active

# Kill specific session
wabadmin session kill <session-id>

# Kill all sessions for a user
wabadmin sessions --user jsmith --kill-all
```

---

## What NOT to Do

```
+==============================================================================+
|                   COMMON MISTAKES TO AVOID                                   |
+==============================================================================+

  DON'T:
  ======

  [X] Give everyone admin access "to make it easier"
      -> Use proper authorizations with least privilege

  [X] Disable session recording "for performance"
      -> Recording overhead is minimal, audit value is huge

  [X] Skip MFA "because it's annoying"
      -> MFA prevents 99% of credential theft attacks

  [X] Create one big authorization for "all users to all targets"
      -> Create specific authorizations per role/function

  [X] Ignore rotation failures "it's just one account"
      -> Failed rotations mean passwords may be compromised

  [X] Test changes in production first
      -> Always test in non-production, then promote

  DO:
  ===

  [✓] Start restrictive, add permissions as needed
  [✓] Enable recording for ALL sessions
  [✓] Require MFA for admin and critical access
  [✓] Monitor rotation status daily
  [✓] Review audit logs weekly
  [✓] Test disaster recovery quarterly

+==============================================================================+
```

---

## Emergency Procedures

### WALLIX is Down - Users Can't Connect

```bash
# 1. Check service status
systemctl status wallix-pam4ot

# 2. Check logs for errors
journalctl -u wallix-pam4ot --since "10 min ago" | tail -50

# 3. Check database
sudo -u postgres psql -c "SELECT 1;"

# 4. Try restart
systemctl restart wallix-pam4ot

# 5. If clustered, check other node
ssh wallix-node2 "systemctl status wallix-pam4ot"
```

### Need Emergency Access to Critical System

```bash
# If WALLIX is down and you need emergency access:
# 1. Use documented break-glass procedure
# 2. Access target directly with emergency credentials
# 3. Document EVERYTHING you do
# 4. Change password immediately after
# 5. Report incident to security team
```

### Suspected Security Breach

```bash
# 1. Terminate ALL active sessions immediately
wabadmin sessions --kill-all --confirm

# 2. Disable suspected compromised accounts
wabadmin user disable <username>

# 3. Export audit logs for investigation
wabadmin audit --export --output /tmp/audit-export.json

# 4. Notify security team
# 5. Do NOT rotate passwords until forensics complete
```

---

## Next Steps

| Your Goal | Read This Next |
|-----------|----------------|
| Understand PAM deeply | [01 - Introduction](../01-introduction/README.md) |
| Deploy WALLIX | [Install Guide](../../install/README.md) |
| Configure devices | [04 - Configuration](../04-configuration/README.md) |
| Set up authentication | [05 - Authentication](../05-authentication/README.md) |
| Learn about OT security | [OT Training](../../ot/README.md) |
| Troubleshoot issues | [12 - Troubleshooting](../12-troubleshooting/README.md) |
| See learning paths | [Learning Paths](./learning-paths.md) |

---

## Quick Reference Card

```
+==============================================================================+
|                   WALLIX QUICK REFERENCE                                     |
+==============================================================================+

  ESSENTIAL COMMANDS
  ==================

  Health Check:
    systemctl status wallix-pam4ot
    wabadmin status
    wabadmin health-check

  Sessions:
    wabadmin sessions --status active
    wabadmin session kill <id>
    wabadmin sessions --kill-all --confirm

  Users:
    wabadmin users list
    wabadmin user show <username>
    wabadmin user disable <username>

  Audit:
    wabadmin audit --last 20
    wabadmin audit --user <username> --date <YYYY-MM-DD>

  Passwords:
    wabadmin account rotate <account>
    wabadmin rotation --status
    wabadmin rotation --failed

  Cluster (if applicable):
    crm status
    crm_mon -1

  --------------------------------------------------------------------------

  KEY PORTS
  =========

  443   - Web UI / API (HTTPS)
  22    - SSH proxy
  3389  - RDP proxy
  5432  - PostgreSQL (internal)
  5404-5406 - Cluster sync (UDP)

  --------------------------------------------------------------------------

  KEY PATHS
  =========

  /etc/opt/wab/          - Configuration files
  /var/lib/wallix/       - Data and recordings
  /var/log/wallix/       - Log files
  /var/backup/wallix/    - Backups

  --------------------------------------------------------------------------

  WEB UI NAVIGATION
  =================

  Audit > Sessions        - View/replay recorded sessions
  Audit > Logs            - View audit trail
  Configuration > Devices - Manage target servers
  Configuration > Users   - Manage user accounts
  Configuration > Auth.   - Manage access permissions
  Monitoring > Dashboard  - System health overview

+==============================================================================+
```

---

<p align="center">
  <a href="./learning-paths.md">Learning Paths</a> •
  <a href="../01-introduction/README.md">Deep Dive</a> •
  <a href="../../install/README.md">Installation</a>
</p>
