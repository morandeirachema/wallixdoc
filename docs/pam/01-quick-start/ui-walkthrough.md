# WALLIX User Interface Walkthrough

## Complete Guide to Web UI Navigation

This guide walks through both the Administrator and User interfaces with detailed explanations of every section.

---

## Interface Overview

```
+===============================================================================+
|                   WALLIX WEB INTERFACES                                       |
+===============================================================================+

  ADMINISTRATOR UI                           USER PORTAL
  ================                           ===========

  https://bastion/admin                      https://bastion/

  +---------------------------+              +---------------------------+
  |  Full system config       |              |  Session launcher         |
  |  Device management        |              |  My authorizations        |
  |  User administration      |              |  Password checkout        |
  |  Audit and compliance     |              |  Session history (own)    |
  |  System monitoring        |              |  Account settings         |
  +---------------------------+              +---------------------------+

  WHO USES IT                                WHO USES IT
  -----------                                -----------
  - System administrators                    - End users
  - Security team                            - IT operators
  - Auditors                                 - Engineers
  - Help desk (limited)                      - Vendors

+===============================================================================+
```

---

## Part 1: Administrator Interface

### 1.1 Login and Dashboard

**URL**: `https://bastion.company.com/admin`

```
+===============================================================================+
|                   ADMIN DASHBOARD                                             |
+===============================================================================+
|                                                                               |
|  +-- Navigation Menu --+  +-- Main Content Area ---------------------------+  |
|  |                     |  |                                                 | |
|  | [Dashboard]         |  |  SYSTEM STATUS                                  | |
|  |                     |  |  ==============                                 | |
|  | Configuration       |  |                                                 | |
|  |  +-- Domains        |  |  Active Sessions: [====] 23                     | |
|  |  +-- Devices        |  |  Licensed Users:  [=======] 145/200             | |
|  |  +-- Users          |  |  Disk Usage:      [==] 45%                      | |
|  |  +-- User Groups    |  |  CPU Load:        [=] 12%                       | |
|  |  +-- Target Groups  |  |                                                 | |
|  |  +-- Authorizations |  |  RECENT ALERTS                                  | |
|  |  +-- Approvals      |  |  =============                                  | |
|  |                     |  |  [!] Password rotation failed: srv-db-01        | |
|  | Audit               |  |  [i] New user logged in: jsmith                 | |
|  |  +-- Sessions       |  |  [!] Failed login attempt: unknown user         | |
|  |  +-- Logs           |  |                                                 | |
|  |  +-- Reports        |  |  QUICK ACTIONS                                  | |
|  |                     |  |  =============                                  | |
|  | System              |  |  [+ Add Device] [+ Add User] [View Sessions]    | |
|  |  +-- Status         |  |                                                 | |
|  |  +-- Settings       |  +-------------------------------------------------+ |
|  |  +-- Backup         |                                                      |
|  +---------------------+                                                      |
|                                                                               |
+===============================================================================+
```

**Dashboard Elements:**

| Element | Description |
|---------|-------------|
| Active Sessions | Real-time count of users connected through WALLIX |
| Licensed Users | Current usage vs license capacity |
| Disk Usage | Recording storage consumption |
| CPU Load | System performance indicator |
| Recent Alerts | Password failures, login issues, system events |
| Quick Actions | Shortcuts to common tasks |

---

### 1.2 Configuration Menu

#### Domains

**Path**: Configuration > Domains

```
+===============================================================================+
|  DOMAINS                                                    [+ Add Domain]    |
+===============================================================================+
|                                                                               |
|  Name              | Type    | Devices | Description                          |
|  ------------------|---------|---------|------------------------------------- |
|  IT-Production     | Local   | 45      | Production servers                   |
|  IT-Development    | Local   | 23      | Development environment              |
|  Network-Devices   | Local   | 18      | Switches, routers, firewalls         |
|  OT-Level2         | Local   | 12      | SCADA and HMI systems                |
|  OT-Level1         | Local   | 8       | PLCs and controllers                 |
|  Service-Accounts  | Global  | -       | Cross-device service accounts        |
|                                                                               |
+===============================================================================+
```

**Domain Types:**
- **Local Domain**: Accounts are specific to devices in this domain
- **Global Domain**: Accounts are shared across multiple devices (e.g., AD accounts)

**When to Use:**
- Create domains by function (IT-Prod, IT-Dev, OT-Level2)
- Create domains by location (Site-A, Site-B, Remote)
- Create domains by compliance (PCI, SOX, NERC-CIP)

---

#### Devices

**Path**: Configuration > Devices

```
+===============================================================================+
|  DEVICES                                                     [+ Add Device]   |
+===============================================================================+
|                                                                               |
|  Search: [_______________] [Filter: All Domains v] [Status: All v]            |
|                                                                               |
|  Status | Name            | Host           | Domain        | Services         |
|  -------|-----------------|----------------|---------------|----------------- |
|  [OK]   | srv-web-01      | 10.1.10.10     | IT-Production | SSH, HTTPS       |
|  [OK]   | srv-db-01       | 10.1.10.20     | IT-Production | SSH, MariaDB     |
|  [!]    | srv-app-03      | 10.1.10.33     | IT-Production | SSH, RDP         |
|  [OK]   | hmi-line1       | 192.168.100.10 | OT-Level2     | RDP, VNC         |
|  [OK]   | plc-pump-01     | 192.168.50.10  | OT-Level1     | SSH Tunnel       |
|                                                                               |
|  [Edit] [Delete] [Test Connection] [View Accounts]                            |
|                                                                               |
+===============================================================================+
```

**Device Configuration Screen:**

```
+===============================================================================+
|  DEVICE: srv-web-01                                                           |
+===============================================================================+
|                                                                               |
|  GENERAL                           | SERVICES                                 |
|  =======                           | ========                                 |
|                                    |                                          |
|  Name: [srv-web-01        ]        | [+ Add Service]                          |
|  Host: [10.1.10.10        ]        |                                          |
|  Domain: [IT-Production   v]       | Type  | Port | Status | Subprotocols     |
|  Description:                      | ------|------|--------|----------------  |
|  [Production web server   ]        | SSH   | 22   | [OK]   | Shell, SCP       |
|  [                        ]        | HTTPS | 443  | [OK]   | -                |
|                                    |                                          |
|  ----------------------------------|                                          |
|                                    | ACCOUNTS                                 |
|  DEVICE SETTINGS                   | ========                                 |
|  ===============                   |                                          |
|                                    | [+ Add Account]                          |
|  [x] Enable device                 |                                          |
|  [ ] Require approval              | Name  | Checkout | Rotation | Status     |
|  Alias: [web1             ]        | ------|----------|----------|----------  |
|                                    | root  | Enabled  | Daily    | [OK]       |
|                                    | admin | Disabled | Weekly   | [OK]       |
|                                    | svc   | Disabled | Never    | [!]        | 
|                                    |                                          |
+===============================================================================+
```

---

#### Users

**Path**: Configuration > Users

```
+===============================================================================+
|  USERS                                                         [+ Add User]   |
+===============================================================================+
|                                                                               |
|  Search: [_______________] [Source: All v] [Status: Active v]                 |
|                                                                               |
|  Status | Username    | Full Name       | Source | Groups        | Last Login |
|  -------|-------------|-----------------|--------|---------------|----------- |
|  [OK]   | jsmith      | John Smith      | LDAP   | IT-Admins     | 10 min ago |
|  [OK]   | mwilson     | Mary Wilson     | LDAP   | OT-Engineers  | 2 hours    |
|  [OK]   | admin       | Administrator   | Local  | Super-Admins  | 5 min ago  |
|  [!]    | contractor1 | Vendor Access   | Local  | Vendors       | Never      |
|  [X]    | olduser     | Former Employee | LDAP   | (Disabled)    | 90 days    |
|                                                                               |
+===============================================================================+
```

**User Details Screen:**

```
+===============================================================================+
|  USER: jsmith                                                                 |
+===============================================================================+
|                                                                               |
|  IDENTITY                          | AUTHENTICATION                           |
|  ========                          | ==============                           |
|                                    |                                          |
|  Username: jsmith                  | Primary: LDAP (Active Directory)         |
|  Full Name: John Smith             | Secondary: FortiToken (Configured)       |
|  Email: jsmith@company.com         |                                          |
|  Phone: +1-555-0123                | [ ] Force password change                |
|  Source: LDAP                      | [x] Account enabled                      |
|                                    | [ ] Account locked                       |
|  ----------------------------------|                                          |
|                                    | SESSIONS                                 |
|  GROUP MEMBERSHIP                  | ========                                 |
|  ================                  |                                          |
|                                    | Active: 2                                |
|  [x] IT-Admins                     | Today: 5                                 |
|  [x] Linux-Operators               | This Week: 23                            |
|  [ ] Windows-Admins                |                                          |
|  [ ] OT-Engineers                  | [View Session History]                   |
|  [ ] Vendors                       |                                          |
|                                    |                                          |
+===============================================================================+
```

---

#### Authorizations

**Path**: Configuration > Authorizations

This is the **core access control configuration**. Authorizations link users to targets.

```
+===============================================================================+
|  AUTHORIZATIONS                                          [+ Add Authorization]|
+===============================================================================+
|                                                                               |
|  Name              | User Group    | Target Group    | Status   | Sessions    |
|  ------------------|---------------|-----------------|----------|------------ |
|  IT-Admins-Linux   | IT-Admins     | Linux-Prod-Root | Active   | 145 today   |
|  OT-Eng-HMI        | OT-Engineers  | HMI-Operator    | Active   | 23 today    |
|  Vendor-PLC-Maint  | Vendors       | PLC-Maintenance | Approval | 0 pending   |
|  Emergency-Access  | Super-Admins  | All-Systems     | Active   | 2 today     |
|                                                                               |
+===============================================================================+
```

**Authorization Configuration:**

```
+===============================================================================+
|  AUTHORIZATION: IT-Admins-Linux                                               |
+===============================================================================+
|                                                                               |
|  BASIC SETTINGS                    | SECURITY SETTINGS                        |
|  ==============                    | =================                        |
|                                    |                                          |
|  Name: [IT-Admins-Linux    ]       | Recording:                               |
|  Description:                      |   [x] Session recording enabled          |
|  [Linux root access for IT ]       |   [x] Keystroke logging                  |
|                                    |   [ ] OCR for RDP                        |
|  User Group: [IT-Admins    v]      |                                          |
|  Target Group: [Linux-Prod v]      | Approval:                                |
|                                    |   [ ] Require approval                   |
|  ----------------------------------|   Approvers: [               v]          |
|                                    |                                          |
|  ALLOWED SUBPROTOCOLS              | Time Restrictions:                       |
|  ====================              |   [ ] Limit access times                 |
|                                    |   Days: [Mon-Fri         v]              |
|  SSH:                              |   Hours: [08:00 - 18:00  v]              |
|  [x] Shell                         |                                          |
|  [x] SCP (file transfer)           | 4-Eyes:                                  |
|  [x] SFTP (file transfer)          |   [ ] Require supervisor                 |
|  [ ] X11 forwarding                |   Supervisor group: [         v]         |
|  [ ] Port forwarding               |                                          |
|                                    | Critical Commands:                       |
|  RDP:                              |   [ ] Block dangerous commands           |
|  [x] Drive mapping                 |   Commands: [rm -rf, shutdown ]          |
|  [x] Clipboard                     |                                          |
|  [ ] Printer redirect              |                                          |
|                                    |                                          |
+===============================================================================+
```

**Key Authorization Settings Explained:**

| Setting | Purpose | When to Enable |
|---------|---------|----------------|
| Recording | Capture session for audit | Always for privileged access |
| Keystroke Logging | Capture text in SSH sessions | Compliance, forensics |
| OCR for RDP | Extract text from RDP video | Searching RDP recordings |
| Require Approval | Workflow before access | Sensitive systems, vendors |
| Time Restrictions | Limit access hours | Business hours only, maintenance windows |
| 4-Eyes | Require observer | Critical changes, compliance |
| Command Blocking | Prevent dangerous commands | Safety, compliance |

---

### 1.3 Audit Menu

#### Sessions (Active)

**Path**: Audit > Sessions > Current

```
+===============================================================================+
|  ACTIVE SESSIONS                                                              |
+===============================================================================+
|                                                                               |
|  [Refresh] [Export]                  Filter: [All Users v] [All Targets v]    |
|                                                                               |
|  User        | Target          | Protocol | Started     | Duration | Actions  |
|  ------------|-----------------|----------|-------------|----------|--------- |
|  jsmith      | srv-web-01/root | SSH      | 09:15:23    | 0:45:12  | [Eye]    |
|  mwilson     | hmi-line1/oper  | RDP      | 09:32:01    | 0:28:44  | [Eye]    |
|  admin       | srv-db-01/admin | SSH      | 10:00:05    | 0:00:40  | [Eye]    |
|                                                                               |
|  Actions: [Eye] = Shadow session (view in real-time)                          |
|           [X]   = Terminate session                                           |
|                                                                               |
+===============================================================================+
```

**Shadowing a Session:**

When you click the eye icon to shadow:

```
+===============================================================================+
|  SHADOW SESSION: jsmith -> srv-web-01/root                                    |
+===============================================================================+
|                                                                               |
|  +-- Real-time View ------------------------------------------------+         |
|  |                                                                  |         |
|  |  jsmith@srv-web-01:~$ tail -f /var/log/apache2/error.log         |         |
|  |  [Thu Jan 29 09:45:12] [error] Connection refused                |         |
|  |  [Thu Jan 29 09:45:15] [error] Connection refused                |         |
|  |  jsmith@srv-web-01:~$ systemctl status apache2                   |         |
|  |  apache2.service - Apache Web Server                             |         |
|  |     Active: active (running) since Thu 2026-01-29 08:00:00       |         |
|  |  jsmith@srv-web-01:~$ _                                          |         |
|  |                                                                  |         |
|  +------------------------------------------------------------------+         |
|                                                                               |
|  Controls: [Terminate Session] [Send Message] [Take Control]                  |
|                                                                               |
|  NOTE: User cannot see that they are being observed                           |
|                                                                               |
+===============================================================================+
```

---

#### Sessions (History)

**Path**: Audit > Sessions > History

```
+===============================================================================+
|  SESSION HISTORY                                                              |
+===============================================================================+
|                                                                               |
|  Date Range: [2026-01-01] to [2026-01-29]  [Search]                           |
|  Search: [________________]  User: [All v]  Target: [All v]                   |
|                                                                               |
|  User      | Target        | Protocol | Start       | End         | Duration  |
|  ----------|---------------|----------|-------------|-------------|---------- |
|  jsmith    | srv-web-01    | SSH      | Jan 29 09:15| Jan 29 10:00| 0:45:00   |
|  mwilson   | hmi-line1     | RDP      | Jan 29 09:32| Jan 29 10:15| 0:43:00   |
|  vendor1   | plc-pump-01   | Tunnel   | Jan 28 14:00| Jan 28 16:30| 2:30:00   |
|                                                                               |
|  Click row to view recording                                                  |
|                                                                               |
+===============================================================================+
```

**Session Recording Playback:**

```
+===============================================================================+
|  SESSION RECORDING: jsmith -> srv-web-01/root                                 |
+===============================================================================+
|                                                                               |
|  +-- Playback Window -----------------------------------------------+         |
|  |                                                                   |        |
|  |  jsmith@srv-web-01:~$ cd /var/log                                 |        |
|  |  jsmith@srv-web-01:/var/log$ ls -la                               |        |
|  |  total 2048                                                       |        |
|  |  drwxr-xr-x  12 root root   4096 Jan 29 08:00 .                   |        |
|  |  -rw-r-----   1 root adm  123456 Jan 29 10:00 syslog              |        |
|  |  jsmith@srv-web-01:/var/log$ _                                    |        |
|  |                                                                   |        |
|  +-------------------------------------------------------------------+        |
|                                                                               |
|  [|<] [<] [Play/Pause] [>] [>|]     Speed: [1x v]     00:15:30 / 00:45:00     |
|                                                                               |
|  Timeline: [====|===============================================]             |
|                                                                               |
|  Search commands: [rm -rf          ] [Search]                                 |
|  Jump to: [_____] [Go]                                                        |
|                                                                               |
|  Metadata:                                                                    |
|  - User: jsmith                                                               |
|  - Target: srv-web-01                                                         |
|  - Account: root                                                              |
|  - Start: 2026-01-29 09:15:23                                                 |
|  - End: 2026-01-29 10:00:23                                                   |
|  - Commands executed: 47                                                      |
|  - Files transferred: 2                                                       |
|                                                                               |
+===============================================================================+
```

---

#### Logs

**Path**: Audit > Logs

```
+===============================================================================+
|  AUDIT LOGS                                                                   |
+===============================================================================+
|                                                                               |
|  Filter: [All Events v]  Severity: [All v]  Date: [Today v]  [Export CSV]     |
|                                                                               |
|  Time        | Severity | Category       | User    | Event                    |
|  ------------|----------|----------------|---------|------------------------- |
|  10:01:15    | INFO     | Session        | jsmith  | Session started          |
|  10:00:05    | INFO     | Authentication | admin   | Login successful (MFA)   |
|  09:58:30    | WARNING  | Password       | system  | Rotation failed: srv-db  |
|  09:45:00    | INFO     | Configuration  | admin   | Device added: srv-app-04 |
|  09:30:22    | ERROR    | Authentication | unknown | Login failed (3 times)   |
|  09:15:23    | INFO     | Session        | jsmith  | Session ended            |
|                                                                               |
|  Click row for full event details                                             |
|                                                                               |
+===============================================================================+
```

---

### 1.4 System Menu

#### Status

**Path**: System > Status

```
+===============================================================================+
|  SYSTEM STATUS                                                                |
+===============================================================================+
|                                                                               |
|  SERVICES                                                                     |
|  ========                                                                     |
|                                                                               |
|  Service              | Status  | CPU   | Memory | Actions                    |
|  ---------------------|---------|-------|--------|--------------------------  |
|  Session Manager      | [OK]    | 15%   | 2.1 GB | [Restart] [Logs]           |
|  Password Manager     | [OK]    | 2%    | 0.5 GB | [Restart] [Logs]           |
|  Access Manager       | [OK]    | 8%    | 1.2 GB | [Restart] [Logs]           |
|  MariaDB              | [OK]    | 5%    | 1.8 GB | [Restart] [Logs]           |
|  Web Server           | [OK]    | 3%    | 0.3 GB | [Restart] [Logs]           |
|                                                                               |
|  -------------------------------------------------------------------------    |
|                                                                               |
|  CLUSTER STATUS (if HA enabled)                                               |
|  ==============                                                               |
|                                                                               |
|  Node             | Role    | Status | Sync Status  | Last Heartbeat          |
|  -----------------|---------|--------|--------------|------------------------ |
|  bastion-01       | Primary | [OK]   | Master       | Now                     |
|  bastion-02       | Standby | [OK]   | Streaming    | 2 sec ago               |
|                                                                               |
|  -------------------------------------------------------------------------    |
|                                                                               |
|  STORAGE                                                                      |
|  =======                                                                      |
|                                                                               |
|  Mount Point        | Size   | Used  | Free  | Usage                          |
|  -------------------|--------|-------|-------|------------------------------  |
|  / (root)           | 50 GB  | 12 GB | 38 GB | [====          ] 24%           |
|  /var/wab/recorded  | 500 GB | 230GB | 270GB | [=========     ] 46%           |
|  /var/lib/mysql     | 100 GB | 45 GB | 55 GB | [========      ] 45%           |
|                                                                               |
+===============================================================================+
```

---

## Part 2: User Portal

### 2.1 User Login and Home

**URL**: `https://bastion.company.com/`

```
+===============================================================================+
|  WALLIX ACCESS PORTAL                                                         |
+===============================================================================+
|                                                                               |
|  Welcome, John Smith                              [Settings] [Logout]         |
|                                                                               |
|  +-- My Targets ---------------------------------------------------+          |
|  |                                                                  |         |
|  |  Search: [_______________]  Filter: [All v]                      |         |
|  |                                                                  |         |
|  |  Recent:                                                         |         |
|  |  [>] srv-web-01 / root (SSH)         Last used: 10 min ago       |         |
|  |  [>] hmi-line1 / operator (RDP)      Last used: 2 hours ago      |         |
|  |                                                                  |         |
|  |  All Targets:                                                    |         |
|  |                                                                  |         |
|  |  [>] srv-db-01 / admin (SSH)                                     |         |
|  |  [>] srv-app-01 / root (SSH)                                     |         |
|  |  [>] srv-app-02 / root (SSH)                                     |         |
|  |  [>] switch-core-01 / admin (SSH)                                |         |
|  |  [>] hmi-line1 / operator (RDP)                                  |         |
|  |  [>] hmi-line2 / operator (RDP)                                  |         |
|  |                                                                  |         |
|  +------------------------------------------------------------------+         |
|                                                                               |
+===============================================================================+
```

---

### 2.2 Launching a Session

When user clicks a target:

```
+===============================================================================+
|  CONNECT TO: srv-web-01 / root                                                |
+===============================================================================+
|                                                                               |
|  Connection Options:                                                          |
|                                                                               |
|  Protocol: SSH                                                                |
|                                                                               |
|  Subprotocols:                                                                |
|  [x] Shell (command line)                                                     |
|  [ ] SCP (file transfer)                                                      |
|  [ ] SFTP (file transfer)                                                     |
|                                                                               |
|  Connection Method:                                                           |
|  ( ) HTML5 (in browser)     <- Recommended                                    |
|  ( ) Native SSH client                                                        |
|                                                                               |
|  Ticket/Reason (optional):                                                    |
|  [INC-12345 - Investigating web server error  ]                               |
|                                                                               |
|                          [Cancel]  [Connect]                                  |
|                                                                               |
+===============================================================================+
```

**HTML5 Session View:**

```
+===============================================================================+
|  SESSION: srv-web-01 / root                        [Disconnect] [Full Screen] |
+===============================================================================+
|                                                                               |
|  +-- Terminal --------------------------------------------------------+       |
|  |                                                                     |      |
|  |  root@srv-web-01:~#                                                 |      |
|  |  root@srv-web-01:~# hostname                                        |      |
|  |  srv-web-01                                                         |      |
|  |  root@srv-web-01:~# uptime                                          |      |
|  |   10:15:23 up 45 days, 12:30,  1 user,  load average: 0.15          |      |
|  |  root@srv-web-01:~# df -h                                           |      |
|  |  Filesystem      Size  Used Avail Use% Mounted on                   |      |
|  |  /dev/sda1        50G   12G   38G  24% /                            |      |
|  |  root@srv-web-01:~# _                                               |      |
|  |                                                                     |      |
|  +---------------------------------------------------------------------+      |
|                                                                               |
|  Status: Connected | Duration: 00:05:23 | Recording: Active                   |
|                                                                               |
+===============================================================================+
```

---

### 2.3 Password Checkout (if enabled)

```
+===============================================================================+
|  PASSWORD CHECKOUT                                                            |
+===============================================================================+
|                                                                               |
|  Available for checkout:                                                      |
|                                                                               |
|  Target              | Account | Status    | Actions                          |
|  --------------------|---------|-----------|--------------------------------  |
|  srv-db-01           | admin   | Available | [Checkout]                       |
|  srv-app-01          | svc     | Available | [Checkout]                       |
|  firewall-01         | admin   | In Use    | Checked out by: mwilson          |
|                                                                               |
+===============================================================================+
```

**Checkout Dialog:**

```
+===============================================================================+
|  CHECKOUT PASSWORD: srv-db-01 / admin                                         |
+===============================================================================+
|                                                                               |
|  Reason for checkout:                                                         |
|  [Manual database maintenance - ticket INC-54321         ]                    |
|                                                                               |
|  Duration: [1 hour v]                                                         |
|                                                                               |
|  [ ] Show password on screen (will be logged)                                 |
|  [x] Copy to clipboard                                                        |
|                                                                               |
|  WARNING: This action is logged and audited.                                  |
|                                                                               |
|                                [Cancel]  [Checkout]                           |
|                                                                               |
+===============================================================================+
```

**After Checkout:**

```
+===============================================================================+
|  PASSWORD CHECKED OUT                                                         |
+===============================================================================+
|                                                                               |
|  Target: srv-db-01                                                            |
|  Account: admin                                                               |
|                                                                               |
|  Password: [*************] [Show] [Copy]                                      |
|                                                                               |
|  Expires: 2026-01-29 11:15:00 (in 59 minutes)                                 |
|                                                                               |
|  [Check In Early]                                                             |
|                                                                               |
|  Note: Password will be automatically rotated after check-in                  |
|                                                                               |
+===============================================================================+
```

---

### 2.4 Approval Requests (if workflow enabled)

```
+===============================================================================+
|  REQUEST ACCESS                                                               |
+===============================================================================+
|                                                                               |
|  Target: plc-pump-01 / engineer                                               |
|                                                                               |
|  This target requires approval before access.                                 |
|                                                                               |
|  Reason for access:                                                           |
|  [Scheduled maintenance - CHG-98765                      ]                    |
|  [Need to update PLC firmware per vendor advisory        ]                    |
|                                                                               |
|  Requested duration: [2 hours v]                                              |
|                                                                               |
|  Requested time:                                                              |
|  ( ) Now                                                                      |
|  (x) Scheduled: [2026-01-30] [14:00]                                          |
|                                                                               |
|                                [Cancel]  [Submit Request]                     |
|                                                                               |
+===============================================================================+
```

**Approval Status:**

```
+===============================================================================+
|  MY ACCESS REQUESTS                                                           |
+===============================================================================+
|                                                                               |
|  Target          | Requested     | Status   | Approver   | Actions            |
|  ----------------|---------------|----------|------------|------------------- |
|  plc-pump-01     | Jan 30 14:00  | Pending  | -          | [Cancel]           |
|  srv-db-01       | Jan 28 10:00  | Approved | jmanager   | [Connect]          |
|  hmi-line3       | Jan 25 09:00  | Denied   | jmanager   | [View Reason]      |
|                                                                               |
+===============================================================================+
```

---

### 2.5 My Session History

```
+===============================================================================+
|  MY SESSION HISTORY                                                           |
+===============================================================================+
|                                                                               |
|  Date Range: [Last 7 Days v]  [Export]                                        |
|                                                                               |
|  Date        | Target        | Account | Protocol | Duration | Ticket         |
|  ------------|---------------|---------|----------|----------|--------------- |
|  Jan 29 09:15| srv-web-01    | root    | SSH      | 0:45:00  | INC-12345      |
|  Jan 28 14:00| srv-db-01     | admin   | SSH      | 1:30:00  | CHG-98765      |
|  Jan 28 10:30| hmi-line1     | operator| RDP      | 2:15:00  | -              |
|  Jan 27 16:00| switch-core   | admin   | SSH      | 0:20:00  | INC-12340      |
|                                                                               |
|  Total sessions this week: 12                                                 |
|  Total time: 8 hours 15 minutes                                               |
|                                                                               |
+===============================================================================+
```

---

## Part 3: Common Tasks Reference

### For Administrators

| Task | Path |
|------|------|
| Add new device | Configuration > Devices > Add Device |
| Add new user | Configuration > Users > Add User |
| Grant access to target | Configuration > Authorizations > Add Authorization |
| View active sessions | Audit > Sessions > Current |
| Review session recording | Audit > Sessions > History > Click session |
| Check password rotation | Configuration > Devices > [device] > Accounts |
| Force password rotation | Configuration > Devices > [device] > Accounts > Rotate |
| Approve access request | Configuration > Approvals > Pending |
| Terminate active session | Audit > Sessions > Current > [session] > Terminate |
| Export audit report | Audit > Reports > Generate |
| Check system health | System > Status |
| Backup configuration | System > Backup |

### For End Users

| Task | Path |
|------|------|
| Connect to target | Home > Click target > Connect |
| Checkout password | Password Checkout > Select account > Checkout |
| Request access (approval needed) | Home > Click target > Submit Request |
| View my sessions | My History |
| Change my password | Settings > Change Password |
| Configure MFA | Settings > Authentication |
| View my pending requests | My Requests |

---

## Part 4: Keyboard Shortcuts

### HTML5 Sessions

| Shortcut | Action |
|----------|--------|
| `Ctrl+Alt+End` | Send Ctrl+Alt+Del to target |
| `F11` | Toggle full screen |
| `Ctrl+Shift+V` | Paste from local clipboard |
| `Ctrl+Shift+C` | Copy to local clipboard |

### Navigation

| Shortcut | Action |
|----------|--------|
| `Alt+H` | Go to Home/Dashboard |
| `Alt+S` | Go to Sessions |
| `Alt+C` | Go to Configuration |
| `/` | Focus search box |

---

<p align="center">
  <a href="./README.md">Quick Start</a> •
  <a href="./learning-paths.md">Learning Paths</a> •
  <a href="../../install/HOWTO.md">Installation</a>
</p>
