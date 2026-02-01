# 53 - Account Discovery and Onboarding

## Table of Contents

1. [Account Discovery Overview](#account-discovery-overview)
2. [Discovery Architecture](#discovery-architecture)
3. [Discovery Methods](#discovery-methods)
4. [Linux/Unix Discovery](#linuxunix-discovery)
5. [Windows Discovery](#windows-discovery)
6. [Database Discovery](#database-discovery)
7. [Network Device Discovery](#network-device-discovery)
8. [Cloud Account Discovery](#cloud-account-discovery)
9. [Automated Onboarding](#automated-onboarding)
10. [Risk Assessment](#risk-assessment)
11. [Scheduled Discovery](#scheduled-discovery)
12. [Discovery Scripts](#discovery-scripts)

---

## Account Discovery Overview

### Why Discovery Matters

Account discovery is the foundation of effective Privileged Access Management. Organizations cannot protect what they do not know exists.

```
+==============================================================================+
|                    THE DISCOVERY IMPERATIVE                                   |
+==============================================================================+
|                                                                               |
|  VISIBILITY GAP                                                               |
|  ==============                                                               |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |                                                                        |   |
|  |   Known Accounts          Unknown Accounts (Shadow IT)                |   |
|  |   in PAM System           Outside PAM Control                         |   |
|  |                                                                        |   |
|  |   +-------------+         +-----------------------------------+       |   |
|  |   |             |         |                                   |       |   |
|  |   |   MANAGED   |         |  * Orphaned service accounts      |       |   |
|  |   |             |         |  * Developer test accounts        |       |   |
|  |   |  Rotated    |         |  * Legacy admin accounts          |       |   |
|  |   |  Monitored  |         |  * Shared credentials             |       |   |
|  |   |  Audited    |         |  * Default vendor accounts        |       |   |
|  |   |             |         |  * Embedded application accounts  |       |   |
|  |   +-------------+         +-----------------------------------+       |   |
|  |        20%                            80%                             |   |
|  |                                                                        |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
|  Discovery closes this visibility gap by systematically identifying          |
|  all privileged accounts across the enterprise.                              |
|                                                                               |
+==============================================================================+
```

### Shadow IT Risks

| Risk Category | Description | Business Impact |
|---------------|-------------|-----------------|
| **Unmanaged Credentials** | Passwords never rotated, no audit trail | Compliance violations, breach exposure |
| **Orphaned Accounts** | Accounts belonging to departed employees | Unauthorized access, insider threats |
| **Shared Accounts** | Multiple users sharing single credential | No accountability, audit failures |
| **Default Accounts** | Vendor defaults never changed | Easy attack vector, known exploits |
| **Service Accounts** | Over-privileged, never reviewed | Lateral movement, persistence |
| **Local Admin Sprawl** | Inconsistent local admin accounts | Inconsistent security, hard to audit |

### Discovery Value Proposition

```
+==============================================================================+
|                    DISCOVERY BENEFITS                                         |
+==============================================================================+
|                                                                               |
|  BEFORE DISCOVERY                      AFTER DISCOVERY                        |
|  ================                      ===============                        |
|                                                                               |
|  * Unknown account count               * Complete inventory                   |
|  * Manual tracking in spreadsheets     * Centralized database                 |
|  * Reactive security posture           * Proactive risk management            |
|  * Compliance gaps                     * Audit-ready documentation            |
|  * Inconsistent access controls        * Standardized policies                |
|  * Unknown attack surface              * Quantified risk exposure             |
|                                                                               |
|  Key Metrics Improved:                                                        |
|  +-------------------------------------------------------------------+       |
|  | Metric                    | Before    | After     | Improvement  |       |
|  +---------------------------+-----------+-----------+--------------+       |
|  | Accounts under management | 200       | 2,500     | 1,150%       |       |
|  | Mean time to onboard      | 2 weeks   | 2 hours   | 99%          |       |
|  | Orphaned account rate     | Unknown   | < 5%      | Measurable   |       |
|  | Compliance audit findings | 15        | 2         | 87%          |       |
|  +-------------------------------------------------------------------+       |
|                                                                               |
+==============================================================================+
```

---

## Discovery Architecture

### System Overview

```
+==============================================================================+
|                    DISCOVERY ARCHITECTURE                                     |
+==============================================================================+
|                                                                               |
|                         +---------------------------+                         |
|                         |    WALLIX BASTION         |                         |
|                         |    Discovery Engine       |                         |
|                         +-------------+-------------+                         |
|                                       |                                       |
|         +-----------------------------+-----------------------------+         |
|         |                             |                             |         |
|         v                             v                             v         |
|  +-------------+               +-------------+               +-------------+  |
|  |  SCHEDULED  |               |  ON-DEMAND  |               |   EVENT     |  |
|  |   SCANS     |               |   SCANS     |               |  TRIGGERED  |  |
|  +------+------+               +------+------+               +------+------+  |
|         |                             |                             |         |
|         +-----------------------------+-----------------------------+         |
|                                       |                                       |
|                                       v                                       |
|                         +---------------------------+                         |
|                         |    DISCOVERY MANAGER      |                         |
|                         |                           |                         |
|                         |  * Scan orchestration     |                         |
|                         |  * Result aggregation     |                         |
|                         |  * Deduplication          |                         |
|                         |  * Classification         |                         |
|                         +-------------+-------------+                         |
|                                       |                                       |
|         +-----------------------------+-----------------------------+         |
|         |                             |                             |         |
|         v                             v                             v         |
|  +-------------+               +-------------+               +-------------+  |
|  |   NETWORK   |               |  DIRECTORY  |               |    AGENT    |  |
|  |   SCANNER   |               |  SCANNER    |               |    BASED    |  |
|  +------+------+               +------+------+               +------+------+  |
|         |                             |                             |         |
|         |                             |                             |         |
|  +------v------+               +------v------+               +------v------+  |
|  | Port Scan   |               | LDAP/AD     |               | Local Agent |  |
|  | SSH Enum    |               | Azure AD    |               | Inventory   |  |
|  | SNMP Query  |               | SCIM        |               | File Scan   |  |
|  +-------------+               +-------------+               +-------------+  |
|                                                                               |
+==============================================================================+
```

### Data Flow

```
+==============================================================================+
|                    DISCOVERY DATA FLOW                                        |
+==============================================================================+
|                                                                               |
|  1. SCAN                    2. COLLECT                   3. ANALYZE          |
|  ========                   =========                    =========           |
|                                                                               |
|  +----------+               +----------+                +----------+         |
|  | Network  |-------------->| Raw      |--------------->| Account  |         |
|  | Targets  |  Enumerate    | Account  |   Classify     | Inventory|         |
|  +----------+               | Data     |                +----------+         |
|                             +----------+                     |               |
|                                                              v               |
|  4. CORRELATE               5. ASSESS                   6. ONBOARD          |
|  ============               ========                    =========           |
|                                                                               |
|  +----------+               +----------+                +----------+         |
|  | Existing |<--------------| Risk     |<---------------| Approval |         |
|  | PAM Data |   Compare     | Score    |   Prioritize   | Workflow |         |
|  +----------+               +----------+                +----------+         |
|       |                          |                           |               |
|       v                          v                           v               |
|  +----------+               +----------+                +----------+         |
|  | Delta    |               | Report & |                | Managed  |         |
|  | Report   |               | Alert    |                | Account  |         |
|  +----------+               +----------+                +----------+         |
|                                                                               |
+==============================================================================+
```

### Component Integration

| Component | Purpose | Integration Point |
|-----------|---------|-------------------|
| Discovery Engine | Orchestrates scan jobs | WALLIX core scheduler |
| Network Scanner | Port-based discovery | Nmap, custom scripts |
| Directory Scanner | LDAP/AD enumeration | LDAP connector |
| Agent Collector | Local system inventory | WALLIX Discovery Agent |
| Classification Engine | Account categorization | Rule-based engine |
| Onboarding Workflow | Automated provisioning | WALLIX API |

---

## Discovery Methods

### Network Scanning (Port-Based)

```
+==============================================================================+
|                    NETWORK-BASED DISCOVERY                                    |
+==============================================================================+
|                                                                               |
|  PORT SCANNING APPROACH                                                       |
|  ======================                                                       |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |  Step 1: Define scan targets (CIDR ranges)                            |   |
|  |                                                                        |   |
|  |  192.168.1.0/24    - Server VLAN                                      |   |
|  |  10.0.0.0/16       - Data center                                      |   |
|  |  172.16.0.0/12     - Branch offices                                   |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |  Step 2: Port-to-service mapping                                      |   |
|  |                                                                        |   |
|  |  +--------+----------------+---------------------------+              |   |
|  |  | Port   | Service        | Discovery Action          |              |   |
|  |  +--------+----------------+---------------------------+              |   |
|  |  | 22     | SSH            | Linux/Unix enumeration    |              |   |
|  |  | 23     | Telnet         | Legacy device detection   |              |   |
|  |  | 3389   | RDP            | Windows enumeration       |              |   |
|  |  | 5985   | WinRM HTTP     | Windows remote mgmt       |              |   |
|  |  | 5986   | WinRM HTTPS    | Windows remote mgmt       |              |   |
|  |  | 1433   | SQL Server     | Database account scan     |              |   |
|  |  | 3306   | MySQL          | Database account scan     |              |   |
|  |  | 5432   | PostgreSQL     | Database account scan     |              |   |
|  |  | 1521   | Oracle         | Database account scan     |              |   |
|  |  | 161    | SNMP           | Network device discovery  |              |   |
|  |  | 389    | LDAP           | Directory enumeration     |              |   |
|  |  | 636    | LDAPS          | Secure directory enum     |              |   |
|  |  +--------+----------------+---------------------------+              |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
+==============================================================================+
```

### LDAP/AD Enumeration

```
+==============================================================================+
|                    LDAP/AD ENUMERATION                                        |
+==============================================================================+
|                                                                               |
|  PRIVILEGED GROUP DISCOVERY                                                   |
|  ==========================                                                   |
|                                                                               |
|  Target Groups:                                                               |
|  +-----------------------------------------------------------------------+   |
|  | Group                              | Risk Level | Action              |   |
|  +------------------------------------+------------+---------------------+   |
|  | Domain Admins                      | Critical   | Immediate onboard   |   |
|  | Enterprise Admins                  | Critical   | Immediate onboard   |   |
|  | Schema Admins                      | Critical   | Immediate onboard   |   |
|  | Administrators (Built-in)          | High       | Priority onboard    |   |
|  | Account Operators                  | High       | Priority onboard    |   |
|  | Backup Operators                   | High       | Priority onboard    |   |
|  | Server Operators                   | Medium     | Scheduled onboard   |   |
|  | Print Operators                    | Low        | Review and decide   |   |
|  | Remote Desktop Users               | Medium     | Scheduled onboard   |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
|  SERVICE ACCOUNT DETECTION                                                    |
|  =========================                                                    |
|                                                                               |
|  Indicators:                                                                  |
|  * Account name prefixes: svc_, service_, app_                               |
|  * Password never expires flag                                               |
|  * User cannot change password flag                                          |
|  * No interactive logon recorded                                             |
|  * ServicePrincipalName (SPN) attribute set                                  |
|                                                                               |
+==============================================================================+
```

### SSH Key Scanning

```
+==============================================================================+
|                    SSH KEY DISCOVERY                                          |
+==============================================================================+
|                                                                               |
|  AUTHORIZED KEYS ANALYSIS                                                     |
|  ========================                                                     |
|                                                                               |
|  Scan locations:                                                              |
|  /home/*/.ssh/authorized_keys                                                 |
|  /root/.ssh/authorized_keys                                                   |
|  /etc/ssh/authorized_keys (centralized)                                       |
|                                                                               |
|  Information extracted:                                                       |
|  +-----------------------------------------------------------------------+   |
|  | Field            | Example                      | Risk Indicator     |   |
|  +------------------+------------------------------+--------------------+   |
|  | Key type         | ssh-rsa, ecdsa, ed25519      | Weak algorithms    |   |
|  | Key size         | 2048, 4096 bits              | < 2048 = weak      |   |
|  | Comment/ID       | user@hostname                | Key ownership      |   |
|  | Options          | from="", command=""          | Restrictions       |   |
|  | Last modified    | File timestamp               | Stale keys         |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
|  Risk flags:                                                                  |
|  * Keys without comments (unknown origin)                                    |
|  * RSA keys < 2048 bits                                                      |
|  * Keys older than 365 days                                                  |
|  * Keys with no source IP restrictions                                       |
|  * Duplicate keys across multiple systems                                    |
|                                                                               |
+==============================================================================+
```

### Service Account Detection

```
+==============================================================================+
|                    SERVICE ACCOUNT INDICATORS                                 |
+==============================================================================+
|                                                                               |
|  DETECTION HEURISTICS                                                         |
|  ====================                                                         |
|                                                                               |
|  Name Patterns:                                                               |
|  +-----------------------------------------------------------------------+   |
|  | Pattern          | Example              | Confidence                  |   |
|  +------------------+----------------------+-----------------------------+   |
|  | svc_*            | svc_backup           | High                        |   |
|  | service_*        | service_monitoring   | High                        |   |
|  | app_*            | app_webserver        | High                        |   |
|  | sa_*             | sa_database          | High                        |   |
|  | *_svc            | backup_svc           | Medium                      |   |
|  | *_service        | web_service          | Medium                      |   |
|  | sys*             | sysadmin             | Low (verify)                |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
|  Behavioral Indicators:                                                       |
|  * No interactive logon history                                              |
|  * Logon only from specific hosts                                            |
|  * 24/7 activity pattern                                                     |
|  * Password age > 365 days                                                   |
|  * Member of high-privilege groups                                           |
|                                                                               |
+==============================================================================+
```

---

## Linux/Unix Discovery

### SSH Account Scanning

```
+==============================================================================+
|                    LINUX SSH ACCOUNT DISCOVERY                                |
+==============================================================================+
|                                                                               |
|  DISCOVERY SCRIPT                                                             |
|  ================                                                             |
|                                                                               |
|  #!/bin/bash                                                                  |
|  # linux_account_discovery.sh                                                 |
|  # Discovers privileged accounts on Linux systems                             |
|                                                                               |
|  OUTPUT_FILE="/tmp/discovery_$(hostname)_$(date +%Y%m%d).json"                |
|                                                                               |
|  # Get system info                                                            |
|  HOSTNAME=$(hostname -f)                                                      |
|  IP_ADDR=$(hostname -I | awk '{print $1}')                                    |
|                                                                               |
|  # Discover accounts with UID 0 (root equivalent)                             |
|  echo "Scanning for UID 0 accounts..."                                        |
|  awk -F: '$3 == 0 {print $1}' /etc/passwd                                     |
|                                                                               |
|  # Discover accounts with sudo privileges                                     |
|  echo "Scanning sudo configuration..."                                        |
|  grep -v '^#' /etc/sudoers 2>/dev/null | grep -v '^$'                        |
|  cat /etc/sudoers.d/* 2>/dev/null | grep -v '^#' | grep -v '^$'              |
|                                                                               |
|  # Discover accounts in wheel/sudo group                                      |
|  echo "Scanning privileged groups..."                                         |
|  getent group wheel sudo admin 2>/dev/null                                    |
|                                                                               |
|  # List all local accounts                                                    |
|  echo "Enumerating local accounts..."                                         |
|  awk -F: '$3 >= 1000 || $3 == 0 {print $1":"$3":"$6":"$7}' /etc/passwd       |
|                                                                               |
+==============================================================================+
```

### /etc/passwd and /etc/shadow Analysis

```
+==============================================================================+
|                    PASSWD/SHADOW ANALYSIS                                     |
+==============================================================================+
|                                                                               |
|  PASSWD FILE FIELDS                                                           |
|  ==================                                                           |
|                                                                               |
|  username:x:UID:GID:GECOS:home:shell                                          |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  | Field    | Discovery Use                                              |   |
|  +----------+------------------------------------------------------------+   |
|  | username | Account identifier                                         |   |
|  | UID      | 0 = root, < 1000 = system, >= 1000 = user                  |   |
|  | GID      | Primary group membership                                   |   |
|  | GECOS    | Account description/owner                                  |   |
|  | home     | Home directory (service accounts often /dev/null)         |   |
|  | shell    | /bin/bash = interactive, /sbin/nologin = service          |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
|  SHADOW FILE ANALYSIS                                                         |
|  ====================                                                         |
|                                                                               |
|  username:hash:lastchange:min:max:warn:inactive:expire:reserved               |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  | Field      | Discovery Use                                            |   |
|  +------------+----------------------------------------------------------+   |
|  | hash       | Empty = no password, ! = locked, * = disabled            |   |
|  | lastchange | Days since Jan 1 1970 password changed                   |   |
|  | max        | Max days between changes (99999 = never expires)         |   |
|  | expire     | Account expiration date                                  |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
|  RISK INDICATORS                                                              |
|  ===============                                                              |
|                                                                               |
|  * Empty password hash (no authentication required)                          |
|  * Password age > 365 days                                                   |
|  * max = 99999 (password never expires)                                      |
|  * Multiple UID 0 accounts                                                   |
|  * Accounts with interactive shell but no recent login                       |
|                                                                               |
+==============================================================================+
```

### Sudo Configuration Discovery

```
+==============================================================================+
|                    SUDO CONFIGURATION ANALYSIS                                |
+==============================================================================+
|                                                                               |
|  SUDOERS PARSING                                                              |
|  ===============                                                              |
|                                                                               |
|  File locations:                                                              |
|  /etc/sudoers                                                                 |
|  /etc/sudoers.d/*                                                             |
|                                                                               |
|  Entry types to discover:                                                     |
|  +-----------------------------------------------------------------------+   |
|  | Entry Type        | Example                    | Risk Level          |   |
|  +-------------------+----------------------------+---------------------+   |
|  | User ALL=(ALL)    | admin ALL=(ALL) ALL        | Critical            |   |
|  | NOPASSWD          | deploy ALL=(ALL) NOPASSWD  | Critical            |   |
|  | Group %wheel      | %wheel ALL=(ALL) ALL       | High                |   |
|  | Command alias     | Cmnd_Alias BACKUP = ...    | Medium              |   |
|  | Specific commands | user ALL=/usr/bin/systemctl| Low                 |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
|  Discovery output:                                                            |
|  {                                                                            |
|    "host": "srv-prod-01",                                                     |
|    "sudo_entries": [                                                          |
|      {                                                                        |
|        "principal": "admin",                                                  |
|        "principal_type": "user",                                              |
|        "hosts": "ALL",                                                        |
|        "runas": "ALL",                                                        |
|        "commands": "ALL",                                                     |
|        "nopasswd": false,                                                     |
|        "risk_level": "critical"                                               |
|      }                                                                        |
|    ]                                                                          |
|  }                                                                            |
|                                                                               |
+==============================================================================+
```

### Cron Job Account Detection

```
+==============================================================================+
|                    CRON JOB ACCOUNT DISCOVERY                                 |
+==============================================================================+
|                                                                               |
|  CRON LOCATIONS TO SCAN                                                       |
|  ======================                                                       |
|                                                                               |
|  System cron:                                                                 |
|  /etc/crontab                                                                 |
|  /etc/cron.d/*                                                                |
|  /etc/cron.daily/*                                                            |
|  /etc/cron.hourly/*                                                           |
|  /etc/cron.weekly/*                                                           |
|  /etc/cron.monthly/*                                                          |
|                                                                               |
|  User cron:                                                                   |
|  /var/spool/cron/crontabs/*                                                   |
|  /var/spool/cron/*                                                            |
|                                                                               |
|  ANALYSIS FOCUS                                                               |
|  ==============                                                               |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  | Check                    | Risk                                       |   |
|  +--------------------------+--------------------------------------------+   |
|  | Jobs running as root     | Privilege escalation vector                |   |
|  | Scripts with credentials | Embedded passwords                         |   |
|  | External script calls    | Supply chain risk                          |   |
|  | Network operations       | May contain service account creds          |   |
|  | Database connections     | Database credentials in scripts            |   |
|  +--------------------------+--------------------------------------------+   |
|                                                                               |
|  # Discovery command                                                          |
|  for user in $(cut -f1 -d: /etc/passwd); do                                   |
|    crontab -l -u $user 2>/dev/null && echo "User: $user"                      |
|  done                                                                         |
|                                                                               |
+==============================================================================+
```

---

## Windows Discovery

### Local Administrator Enumeration

```
+==============================================================================+
|                    WINDOWS LOCAL ADMIN DISCOVERY                              |
+==============================================================================+
|                                                                               |
|  POWERSHELL DISCOVERY SCRIPT                                                  |
|  ===========================                                                  |
|                                                                               |
|  # Get local administrators group members                                     |
|  Get-LocalGroupMember -Group "Administrators" | Select-Object `              |
|      Name, ObjectClass, PrincipalSource                                       |
|                                                                               |
|  # Output format:                                                             |
|  # Name                    ObjectClass  PrincipalSource                       |
|  # ----                    -----------  ---------------                       |
|  # DOMAIN\Domain Admins    Group        ActiveDirectory                       |
|  # DOMAIN\IT-Support       Group        ActiveDirectory                       |
|  # COMPUTER\Administrator  User         Local                                 |
|  # COMPUTER\svc_backup     User         Local                                 |
|                                                                               |
|  REMOTE ENUMERATION                                                           |
|  ==================                                                           |
|                                                                               |
|  # Enumerate across multiple servers                                          |
|  $servers = Get-Content "servers.txt"                                         |
|  foreach ($server in $servers) {                                              |
|      Invoke-Command -ComputerName $server -ScriptBlock {                      |
|          Get-LocalGroupMember -Group "Administrators"                         |
|      } -Credential $cred                                                      |
|  }                                                                            |
|                                                                               |
|  RISK ASSESSMENT CRITERIA                                                     |
|  =======================                                                      |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  | Finding                        | Risk    | Action                     |   |
|  +--------------------------------+---------+----------------------------+   |
|  | Local admin enabled            | High    | Disable or manage via PAM  |   |
|  | Multiple local admins          | Medium  | Review and consolidate     |   |
|  | Service accounts as admin      | High    | Reduce privileges          |   |
|  | Unknown domain accounts        | High    | Investigate and document   |   |
|  | Default Administrator active   | High    | Rename and manage via PAM  |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
+==============================================================================+
```

### Service Account Detection

```
+==============================================================================+
|                    WINDOWS SERVICE ACCOUNT DISCOVERY                          |
+==============================================================================+
|                                                                               |
|  SERVICE ENUMERATION                                                          |
|  ===================                                                          |
|                                                                               |
|  # Get all services and their logon accounts                                  |
|  Get-WmiObject Win32_Service | Select-Object `                                |
|      Name, DisplayName, StartName, State, StartMode |                         |
|      Where-Object { $_.StartName -notlike "LocalSystem" -and                  |
|                     $_.StartName -notlike "NT AUTHORITY\*" }                  |
|                                                                               |
|  # Output example:                                                            |
|  # Name         DisplayName           StartName              State            |
|  # ----         -----------           ---------              -----            |
|  # SQLAgent     SQL Server Agent      DOMAIN\svc_sql         Running          |
|  # BackupExec   Backup Exec Agent     DOMAIN\svc_backup      Running          |
|  # AppPool      IIS Application Pool  DOMAIN\svc_web         Running          |
|                                                                               |
|  SERVICE ACCOUNT CATEGORIES                                                   |
|  ==========================                                                   |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  | Account Type           | Managed by       | PAM Action                |   |
|  +------------------------+------------------+---------------------------+   |
|  | LocalSystem            | Windows          | No action needed          |   |
|  | Local Service          | Windows          | No action needed          |   |
|  | Network Service        | Windows          | No action needed          |   |
|  | Domain service account | Active Directory | Onboard to PAM            |   |
|  | Local service account  | Local SAM        | Onboard to PAM            |   |
|  | gMSA                   | Active Directory | Document, may not need    |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
+==============================================================================+
```

### Scheduled Task Accounts

```
+==============================================================================+
|                    SCHEDULED TASK ACCOUNT DISCOVERY                           |
+==============================================================================+
|                                                                               |
|  TASK ENUMERATION                                                             |
|  ================                                                             |
|                                                                               |
|  # Get scheduled tasks with custom credentials                                |
|  Get-ScheduledTask | ForEach-Object {                                         |
|      $task = $_                                                               |
|      $principal = $task.Principal                                             |
|      if ($principal.UserId -and                                               |
|          $principal.UserId -notlike "SYSTEM" -and                             |
|          $principal.UserId -notlike "LOCAL SERVICE") {                        |
|          [PSCustomObject]@{                                                   |
|              TaskName = $task.TaskName                                        |
|              TaskPath = $task.TaskPath                                        |
|              UserId = $principal.UserId                                       |
|              LogonType = $principal.LogonType                                 |
|              State = $task.State                                              |
|          }                                                                    |
|      }                                                                        |
|  }                                                                            |
|                                                                               |
|  RISK INDICATORS                                                              |
|  ===============                                                              |
|                                                                               |
|  * Tasks running as domain admin                                              |
|  * Tasks with "Password" LogonType (stored credentials)                       |
|  * Tasks calling scripts with embedded credentials                            |
|  * Disabled tasks with stored credentials (cleanup needed)                    |
|                                                                               |
+==============================================================================+
```

### Domain Admin Detection

```
+==============================================================================+
|                    DOMAIN ADMIN DISCOVERY                                     |
+==============================================================================+
|                                                                               |
|  PRIVILEGED GROUP ENUMERATION                                                 |
|  ============================                                                 |
|                                                                               |
|  # Import AD module                                                           |
|  Import-Module ActiveDirectory                                                |
|                                                                               |
|  # Get Domain Admins                                                          |
|  Get-ADGroupMember -Identity "Domain Admins" -Recursive |                     |
|      Select-Object Name, SamAccountName, ObjectClass                          |
|                                                                               |
|  # Get Enterprise Admins                                                      |
|  Get-ADGroupMember -Identity "Enterprise Admins" -Recursive |                 |
|      Select-Object Name, SamAccountName, ObjectClass                          |
|                                                                               |
|  # Get Schema Admins                                                          |
|  Get-ADGroupMember -Identity "Schema Admins" -Recursive |                     |
|      Select-Object Name, SamAccountName, ObjectClass                          |
|                                                                               |
|  NESTED GROUP ANALYSIS                                                        |
|  =====================                                                        |
|                                                                               |
|  # Find all paths to Domain Admins                                            |
|  function Get-NestedGroupMembership {                                         |
|      param([string]$GroupName, [string]$Path = "")                            |
|      $members = Get-ADGroupMember -Identity $GroupName                        |
|      foreach ($member in $members) {                                          |
|          $currentPath = "$Path -> $($member.Name)"                            |
|          if ($member.ObjectClass -eq "group") {                               |
|              Get-NestedGroupMembership -GroupName $member.Name `              |
|                  -Path $currentPath                                           |
|          } else {                                                             |
|              Write-Output "$currentPath"                                      |
|          }                                                                    |
|      }                                                                        |
|  }                                                                            |
|                                                                               |
+==============================================================================+
```

---

## Database Discovery

### PostgreSQL Role Enumeration

```
+==============================================================================+
|                    POSTGRESQL ACCOUNT DISCOVERY                               |
+==============================================================================+
|                                                                               |
|  ROLE ENUMERATION QUERIES                                                     |
|  ========================                                                     |
|                                                                               |
|  -- List all roles with attributes                                            |
|  SELECT rolname, rolsuper, rolinherit, rolcreaterole,                         |
|         rolcreatedb, rolcanlogin, rolreplication,                             |
|         rolconnlimit, rolvaliduntil                                           |
|  FROM pg_roles                                                                |
|  ORDER BY rolsuper DESC, rolcreaterole DESC;                                  |
|                                                                               |
|  -- Find superuser accounts (highest risk)                                    |
|  SELECT rolname FROM pg_roles WHERE rolsuper = true;                          |
|                                                                               |
|  -- Find accounts with no password expiration                                 |
|  SELECT rolname FROM pg_roles                                                 |
|  WHERE rolcanlogin = true AND rolvaliduntil IS NULL;                          |
|                                                                               |
|  -- Find role memberships                                                     |
|  SELECT r.rolname as role,                                                    |
|         m.rolname as member,                                                  |
|         g.rolname as grantor                                                  |
|  FROM pg_auth_members am                                                      |
|  JOIN pg_roles r ON am.roleid = r.oid                                         |
|  JOIN pg_roles m ON am.member = m.oid                                         |
|  JOIN pg_roles g ON am.grantor = g.oid;                                       |
|                                                                               |
|  DISCOVERY OUTPUT FORMAT                                                      |
|  ======================                                                       |
|                                                                               |
|  {                                                                            |
|    "database_type": "postgresql",                                             |
|    "host": "db-prod-01.company.com",                                          |
|    "port": 5432,                                                              |
|    "accounts": [                                                              |
|      {                                                                        |
|        "name": "postgres",                                                    |
|        "is_superuser": true,                                                  |
|        "can_login": true,                                                     |
|        "password_expires": null,                                              |
|        "risk_level": "critical"                                               |
|      }                                                                        |
|    ]                                                                          |
|  }                                                                            |
|                                                                               |
+==============================================================================+
```

### MySQL User Discovery

```
+==============================================================================+
|                    MYSQL ACCOUNT DISCOVERY                                    |
+==============================================================================+
|                                                                               |
|  USER ENUMERATION QUERIES                                                     |
|  ========================                                                     |
|                                                                               |
|  -- List all users with host restrictions                                     |
|  SELECT User, Host, authentication_string,                                    |
|         password_expired, account_locked                                      |
|  FROM mysql.user;                                                             |
|                                                                               |
|  -- Find users with global privileges                                         |
|  SELECT User, Host,                                                           |
|         Super_priv, Grant_priv, Create_user_priv,                             |
|         Reload_priv, Shutdown_priv, File_priv                                 |
|  FROM mysql.user                                                              |
|  WHERE Super_priv = 'Y' OR Grant_priv = 'Y';                                  |
|                                                                               |
|  -- Find users with ALL PRIVILEGES                                            |
|  SELECT DISTINCT grantee FROM information_schema.user_privileges              |
|  WHERE privilege_type = 'SUPER';                                              |
|                                                                               |
|  -- Check for accounts without passwords                                      |
|  SELECT User, Host FROM mysql.user                                            |
|  WHERE authentication_string = '' OR authentication_string IS NULL;           |
|                                                                               |
|  -- Find accounts accessible from any host                                    |
|  SELECT User FROM mysql.user WHERE Host = '%';                                |
|                                                                               |
|  RISK CLASSIFICATION                                                          |
|  ===================                                                          |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  | Finding                        | Risk Level | Remediation             |   |
|  +--------------------------------+------------+-------------------------+   |
|  | root@% (any host)              | Critical   | Restrict to localhost   |   |
|  | Empty password                 | Critical   | Set strong password     |   |
|  | SUPER privilege                | High       | Review necessity        |   |
|  | GRANT privilege                | High       | Limit to DBA only       |   |
|  | FILE privilege                 | Medium     | Remove if not needed    |   |
|  +--------------------------------+------------+-------------------------+   |
|                                                                               |
+==============================================================================+
```

### Oracle Database Accounts

```
+==============================================================================+
|                    ORACLE ACCOUNT DISCOVERY                                   |
+==============================================================================+
|                                                                               |
|  USER ENUMERATION QUERIES                                                     |
|  ========================                                                     |
|                                                                               |
|  -- List all database users                                                   |
|  SELECT username, account_status, lock_date,                                  |
|         expiry_date, default_tablespace, profile                              |
|  FROM dba_users                                                               |
|  ORDER BY account_status, username;                                           |
|                                                                               |
|  -- Find users with DBA role                                                  |
|  SELECT grantee FROM dba_role_privs                                           |
|  WHERE granted_role = 'DBA';                                                  |
|                                                                               |
|  -- Find users with SYSDBA/SYSOPER privileges                                 |
|  SELECT * FROM v$pwfile_users;                                                |
|                                                                               |
|  -- Find users with powerful system privileges                                |
|  SELECT grantee, privilege FROM dba_sys_privs                                 |
|  WHERE privilege IN (                                                         |
|      'ALTER SYSTEM', 'CREATE USER', 'DROP USER',                              |
|      'GRANT ANY PRIVILEGE', 'BECOME USER'                                     |
|  );                                                                           |
|                                                                               |
|  -- Check password profile settings                                           |
|  SELECT profile, resource_name, limit                                         |
|  FROM dba_profiles                                                            |
|  WHERE resource_type = 'PASSWORD';                                            |
|                                                                               |
|  DEFAULT ACCOUNTS TO CHECK                                                    |
|  =========================                                                    |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  | Account      | Default Password | Risk if Active                     |   |
|  +--------------+------------------+------------------------------------+   |
|  | SYS          | change_on_install| Full database control              |   |
|  | SYSTEM       | manager          | Full database control              |   |
|  | DBSNMP       | dbsnmp           | Monitoring access                  |   |
|  | OUTLN        | outln            | Schema access                      |   |
|  | SCOTT        | tiger            | Sample data access                 |   |
|  +--------------+------------------+------------------------------------+   |
|                                                                               |
+==============================================================================+
```

---

## Network Device Discovery

### SNMP-Based Discovery

```
+==============================================================================+
|                    SNMP NETWORK DEVICE DISCOVERY                              |
+==============================================================================+
|                                                                               |
|  SNMP ENUMERATION                                                             |
|  ================                                                             |
|                                                                               |
|  # Discover device information via SNMP                                       |
|  snmpwalk -v2c -c <community> <device_ip> sysDescr.0                          |
|  snmpwalk -v2c -c <community> <device_ip> sysName.0                           |
|                                                                               |
|  # Common MIBs for user enumeration                                           |
|  +-----------------------------------------------------------------------+   |
|  | OID                        | Description                              |   |
|  +----------------------------+------------------------------------------+   |
|  | 1.3.6.1.4.1.9.9.43.1.1     | Cisco local users (CISCO-CONFIG-MAN)     |   |
|  | 1.3.6.1.4.1.2636.3.40.1    | Juniper user accounts                    |   |
|  +----------------------------+------------------------------------------+   |
|                                                                               |
|  DEVICE TYPE DETECTION                                                        |
|  =====================                                                        |
|                                                                               |
|  sysObjectID mappings:                                                        |
|  1.3.6.1.4.1.9.*     -> Cisco                                                 |
|  1.3.6.1.4.1.2636.*  -> Juniper                                               |
|  1.3.6.1.4.1.25461.* -> Palo Alto                                             |
|  1.3.6.1.4.1.12356.* -> Fortinet                                              |
|  1.3.6.1.4.1.3375.*  -> F5                                                    |
|                                                                               |
+==============================================================================+
```

### SSH User Enumeration

```
+==============================================================================+
|                    NETWORK DEVICE SSH ENUMERATION                             |
+==============================================================================+
|                                                                               |
|  CISCO IOS USER DISCOVERY                                                     |
|  ========================                                                     |
|                                                                               |
|  # Connect and enumerate users                                                |
|  show running-config | include username                                       |
|                                                                               |
|  # Output example:                                                            |
|  # username admin privilege 15 secret 5 $1$abc...                             |
|  # username readonly privilege 1 secret 5 $1$def...                           |
|  # username backup privilege 7 secret 5 $1$ghi...                             |
|                                                                               |
|  JUNIPER JUNOS USER DISCOVERY                                                 |
|  ============================                                                 |
|                                                                               |
|  # Show configured users                                                      |
|  show configuration system login                                              |
|                                                                               |
|  # Output example:                                                            |
|  # user admin {                                                               |
|  #     class super-user;                                                      |
|  #     authentication { encrypted-password "..."; }                           |
|  # }                                                                          |
|                                                                               |
|  PALO ALTO USER DISCOVERY                                                     |
|  ========================                                                     |
|                                                                               |
|  # Show administrators                                                        |
|  show admins all                                                              |
|                                                                               |
|  # Output example:                                                            |
|  # admin        superuser      Local                                          |
|  # readonly     devicereader   Local                                          |
|                                                                               |
+==============================================================================+
```

### TACACS/RADIUS Account Detection

```
+==============================================================================+
|                    TACACS/RADIUS ACCOUNT DISCOVERY                            |
+==============================================================================+
|                                                                               |
|  AAA CONFIGURATION ANALYSIS                                                   |
|  ==========================                                                   |
|                                                                               |
|  Discovery approach:                                                          |
|  1. Identify devices using TACACS+/RADIUS                                     |
|  2. Query AAA server for user database                                        |
|  3. Map users to device access levels                                         |
|                                                                               |
|  TACACS+ Server Query (Cisco ISE/ACS)                                         |
|  -------------------------------------                                        |
|                                                                               |
|  # Via API or database query                                                  |
|  SELECT username, group_name, enabled                                         |
|  FROM tacacs_users                                                            |
|  WHERE enabled = 1;                                                           |
|                                                                               |
|  RADIUS Server Query (FreeRADIUS)                                             |
|  ---------------------------------                                            |
|                                                                               |
|  # Query radcheck table                                                       |
|  SELECT username, attribute, value                                            |
|  FROM radcheck;                                                               |
|                                                                               |
|  # Query group memberships                                                    |
|  SELECT username, groupname                                                   |
|  FROM radusergroup;                                                           |
|                                                                               |
|  DISCOVERY OUTPUT                                                             |
|  ================                                                             |
|                                                                               |
|  {                                                                            |
|    "aaa_type": "tacacs",                                                      |
|    "server": "ise.company.com",                                               |
|    "accounts": [                                                              |
|      {                                                                        |
|        "username": "netadmin",                                                |
|        "groups": ["network-admins"],                                          |
|        "privilege_level": 15,                                                 |
|        "devices_accessible": ["all-network-devices"]                          |
|      }                                                                        |
|    ]                                                                          |
|  }                                                                            |
|                                                                               |
+==============================================================================+
```

---

## Cloud Account Discovery

### AWS IAM Enumeration

```
+==============================================================================+
|                    AWS IAM ACCOUNT DISCOVERY                                  |
+==============================================================================+
|                                                                               |
|  IAM USER ENUMERATION                                                         |
|  ====================                                                         |
|                                                                               |
|  # List all IAM users                                                         |
|  aws iam list-users --query 'Users[*].[UserName,CreateDate,PasswordLastUsed]' |
|                                                                               |
|  # Get user details including MFA                                             |
|  aws iam list-mfa-devices --user-name <username>                              |
|                                                                               |
|  # List access keys                                                           |
|  aws iam list-access-keys --user-name <username>                              |
|                                                                               |
|  # Check access key last used                                                 |
|  aws iam get-access-key-last-used --access-key-id <key_id>                    |
|                                                                               |
|  SERVICE ACCOUNT (ROLE) DISCOVERY                                             |
|  ================================                                             |
|                                                                               |
|  # List all roles                                                             |
|  aws iam list-roles --query 'Roles[*].[RoleName,CreateDate]'                  |
|                                                                               |
|  # Find roles with admin access                                               |
|  for role in $(aws iam list-roles --query 'Roles[*].RoleName' --output text); |
|  do                                                                           |
|    policies=$(aws iam list-attached-role-policies --role-name $role \         |
|               --query 'AttachedPolicies[*].PolicyArn' --output text)          |
|    if echo "$policies" | grep -q "AdministratorAccess"; then                  |
|      echo "ADMIN ROLE: $role"                                                 |
|    fi                                                                         |
|  done                                                                         |
|                                                                               |
|  RISK INDICATORS                                                              |
|  ===============                                                              |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  | Finding                        | Risk Level | Action                  |   |
|  +--------------------------------+------------+-------------------------+   |
|  | User without MFA               | High       | Enforce MFA             |   |
|  | Access key > 90 days old       | Medium     | Rotate key              |   |
|  | Unused access key              | Medium     | Disable/delete          |   |
|  | AdministratorAccess policy     | High       | Review necessity        |   |
|  | Root account access keys       | Critical   | Delete immediately      |   |
|  | Console access + programmatic  | Medium     | Review necessity        |   |
|  +--------------------------------+------------+-------------------------+   |
|                                                                               |
+==============================================================================+
```

### Azure AD Service Principals

```
+==============================================================================+
|                    AZURE AD SERVICE PRINCIPAL DISCOVERY                       |
+==============================================================================+
|                                                                               |
|  SERVICE PRINCIPAL ENUMERATION                                                |
|  =============================                                                |
|                                                                               |
|  # Using Azure CLI                                                            |
|  az ad sp list --all --query "[].{Name:displayName,AppId:appId,Type:servicePrincipalType}"                    |
|                                                                               |
|  # Find service principals with high-privilege roles                          |
|  az role assignment list --all --query "[?principalType=='ServicePrincipal']" |
|                                                                               |
|  # Using Microsoft Graph API                                                  |
|  GET https://graph.microsoft.com/v1.0/servicePrincipals                       |
|  Authorization: Bearer <token>                                                |
|                                                                               |
|  APP REGISTRATION DISCOVERY                                                   |
|  ==========================                                                   |
|                                                                               |
|  # List all app registrations                                                 |
|  az ad app list --all --query "[].{Name:displayName,AppId:appId}"             |
|                                                                               |
|  # Find apps with credentials                                                 |
|  az ad app list --all --query "[?passwordCredentials || keyCredentials]"      |
|                                                                               |
|  # Check credential expiration                                                |
|  az ad app credential list --id <app_id>                                      |
|                                                                               |
|  RISK ASSESSMENT                                                              |
|  ===============                                                              |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  | Finding                        | Risk Level | Action                  |   |
|  +--------------------------------+------------+-------------------------+   |
|  | SP with Owner/Contributor      | High       | Review and document     |   |
|  | Credentials expiring soon      | Medium     | Plan rotation           |   |
|  | Credentials already expired    | High       | Rotate immediately      |   |
|  | SP with no recent sign-ins     | Medium     | Consider removal        |   |
|  | Multi-tenant app registration  | Medium     | Verify necessity        |   |
|  +--------------------------------+------------+-------------------------+   |
|                                                                               |
+==============================================================================+
```

### GCP Service Accounts

```
+==============================================================================+
|                    GCP SERVICE ACCOUNT DISCOVERY                              |
+==============================================================================+
|                                                                               |
|  SERVICE ACCOUNT ENUMERATION                                                  |
|  ===========================                                                  |
|                                                                               |
|  # List all service accounts in project                                       |
|  gcloud iam service-accounts list --project=<project_id>                      |
|                                                                               |
|  # Get service account details                                                |
|  gcloud iam service-accounts describe <sa_email>                              |
|                                                                               |
|  # List service account keys                                                  |
|  gcloud iam service-accounts keys list --iam-account=<sa_email>               |
|                                                                               |
|  IAM BINDING ANALYSIS                                                         |
|  ====================                                                         |
|                                                                               |
|  # Get IAM policy for project                                                 |
|  gcloud projects get-iam-policy <project_id>                                  |
|                                                                               |
|  # Find service accounts with Owner role                                      |
|  gcloud projects get-iam-policy <project_id> \                                |
|      --flatten="bindings[].members" \                                         |
|      --filter="bindings.role:roles/owner" \                                   |
|      --format="value(bindings.members)"                                       |
|                                                                               |
|  KEY AGE ANALYSIS                                                             |
|  ================                                                             |
|                                                                               |
|  # Find keys older than 90 days                                               |
|  for sa in $(gcloud iam service-accounts list --format="value(email)"); do    |
|    echo "Service Account: $sa"                                                |
|    gcloud iam service-accounts keys list --iam-account=$sa \                  |
|        --format="table(name,validAfterTime,validBeforeTime)"                  |
|  done                                                                         |
|                                                                               |
|  DISCOVERY OUTPUT                                                             |
|  ================                                                             |
|                                                                               |
|  {                                                                            |
|    "cloud_provider": "gcp",                                                   |
|    "project": "prod-project-123",                                             |
|    "service_accounts": [                                                      |
|      {                                                                        |
|        "email": "app-sa@prod-project-123.iam.gserviceaccount.com",            |
|        "display_name": "Application Service Account",                         |
|        "roles": ["roles/editor"],                                             |
|        "keys": [                                                              |
|          {                                                                    |
|            "key_id": "abc123",                                                |
|            "created": "2024-01-01",                                           |
|            "expires": "2025-01-01",                                           |
|            "age_days": 390                                                    |
|          }                                                                    |
|        ],                                                                     |
|        "risk_level": "high"                                                   |
|      }                                                                        |
|    ]                                                                          |
|  }                                                                            |
|                                                                               |
+==============================================================================+
```

---

## Automated Onboarding

### Discovery to Onboarding Workflow

```
+==============================================================================+
|                    AUTOMATED ONBOARDING WORKFLOW                              |
+==============================================================================+
|                                                                               |
|  WORKFLOW STAGES                                                              |
|  ===============                                                              |
|                                                                               |
|  +----------+     +----------+     +----------+     +----------+             |
|  |  DISCOVER |---->| CLASSIFY |---->|  APPROVE |---->|  ONBOARD |             |
|  +----------+     +----------+     +----------+     +----------+             |
|       |                |                |                |                    |
|       v                v                v                v                    |
|  +---------+      +---------+      +---------+      +---------+              |
|  | Scan    |      | Apply   |      | Route to|      | Create  |              |
|  | targets |      | rules   |      | approver|      | in PAM  |              |
|  +---------+      +---------+      +---------+      +---------+              |
|                                                                               |
|  CLASSIFICATION RULES                                                         |
|  ====================                                                         |
|                                                                               |
|  {                                                                            |
|    "classification_rules": [                                                  |
|      {                                                                        |
|        "name": "domain_admin",                                                |
|        "conditions": {                                                        |
|          "group_membership": ["Domain Admins", "Enterprise Admins"]           |
|        },                                                                     |
|        "actions": {                                                           |
|          "risk_level": "critical",                                            |
|          "domain": "Critical-Infrastructure",                                 |
|          "rotation_policy": "30days",                                         |
|          "approval_required": true,                                           |
|          "approver_group": "security-team"                                    |
|        }                                                                      |
|      },                                                                       |
|      {                                                                        |
|        "name": "service_account",                                             |
|        "conditions": {                                                        |
|          "name_pattern": "^(svc_|service_|app_).*",                           |
|          "no_interactive_login": true                                         |
|        },                                                                     |
|        "actions": {                                                           |
|          "risk_level": "high",                                                |
|          "domain": "Service-Accounts",                                        |
|          "rotation_policy": "90days",                                         |
|          "approval_required": false                                           |
|        }                                                                      |
|      },                                                                       |
|      {                                                                        |
|        "name": "local_admin",                                                 |
|        "conditions": {                                                        |
|          "account_name": "Administrator",                                     |
|          "account_type": "local"                                              |
|        },                                                                     |
|        "actions": {                                                           |
|          "risk_level": "high",                                                |
|          "domain": "Local-Admins",                                            |
|          "rotation_policy": "30days"                                          |
|        }                                                                      |
|      }                                                                        |
|    ]                                                                          |
|  }                                                                            |
|                                                                               |
+==============================================================================+
```

### Bulk Import Procedures

```
+==============================================================================+
|                    BULK IMPORT PROCEDURES                                     |
+==============================================================================+
|                                                                               |
|  CSV IMPORT FORMAT                                                            |
|  =================                                                            |
|                                                                               |
|  device_name,host,domain,account_name,login,credential_type,password         |
|  srv-prod-01,192.168.1.10,Production,root@srv-prod-01,root,password,          |
|  srv-prod-02,192.168.1.11,Production,root@srv-prod-02,root,password,          |
|  srv-prod-03,192.168.1.12,Production,admin@srv-prod-03,admin,ssh_key,         |
|                                                                               |
|  API BULK IMPORT                                                              |
|  ===============                                                              |
|                                                                               |
|  POST /api/v2/bulk/import                                                     |
|  Content-Type: application/json                                               |
|  Authorization: Bearer <token>                                                |
|                                                                               |
|  {                                                                            |
|    "import_type": "accounts",                                                 |
|    "options": {                                                               |
|      "create_devices": true,                                                  |
|      "create_domains": true,                                                  |
|      "update_existing": false,                                                |
|      "dry_run": false                                                         |
|    },                                                                         |
|    "data": [                                                                  |
|      {                                                                        |
|        "device": {                                                            |
|          "device_name": "srv-prod-01",                                        |
|          "host": "192.168.1.10",                                              |
|          "domain": "Production"                                               |
|        },                                                                     |
|        "services": [                                                          |
|          {"service_name": "SSH", "protocol": "SSH", "port": 22}               |
|        ],                                                                     |
|        "accounts": [                                                          |
|          {                                                                    |
|            "account_name": "root@srv-prod-01",                                |
|            "login": "root",                                                   |
|            "credentials": {                                                   |
|              "type": "password",                                              |
|              "password": "INITIAL_PASSWORD"                                   |
|            },                                                                 |
|            "auto_change_password": true                                       |
|          }                                                                    |
|        ]                                                                      |
|      }                                                                        |
|    ]                                                                          |
|  }                                                                            |
|                                                                               |
|  IMPORT RESPONSE                                                              |
|  ===============                                                              |
|                                                                               |
|  {                                                                            |
|    "status": "success",                                                       |
|    "summary": {                                                               |
|      "total_records": 150,                                                    |
|      "devices_created": 50,                                                   |
|      "accounts_created": 150,                                                 |
|      "errors": 0                                                              |
|    },                                                                         |
|    "details": [...]                                                           |
|  }                                                                            |
|                                                                               |
+==============================================================================+
```

### Account Classification Rules

```
+==============================================================================+
|                    ACCOUNT CLASSIFICATION MATRIX                              |
+==============================================================================+
|                                                                               |
|  CLASSIFICATION CRITERIA                                                      |
|  =======================                                                      |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  | Attribute          | Critical    | High        | Medium    | Low      |   |
|  +--------------------+-------------+-------------+-----------+----------+   |
|  | Privilege level    | Root/Admin  | Sudo/Power  | Standard  | ReadOnly |   |
|  | System type        | Production  | Staging     | Dev       | Test     |   |
|  | Data sensitivity   | PII/PCI     | Internal    | Public    | None     |   |
|  | Access scope       | Enterprise  | Department  | Team      | Personal |   |
|  | Compliance scope   | SOX/PCI     | HIPAA       | Internal  | None     |   |
|  +--------------------+-------------+-------------+-----------+----------+   |
|                                                                               |
|  RESULTING POLICIES                                                           |
|  ==================                                                           |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  | Risk Level  | Rotation   | Checkout    | MFA      | Approval         |   |
|  +-------------+------------+-------------+----------+------------------+   |
|  | Critical    | 7 days     | Exclusive   | Required | Dual approval    |   |
|  | High        | 30 days    | Exclusive   | Required | Single approval  |   |
|  | Medium      | 90 days    | Shared OK   | Optional | Auto-approve     |   |
|  | Low         | 180 days   | Shared OK   | Optional | Auto-approve     |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
+==============================================================================+
```

---

## Risk Assessment

### Orphaned Account Detection

```
+==============================================================================+
|                    ORPHANED ACCOUNT DETECTION                                 |
+==============================================================================+
|                                                                               |
|  DETECTION METHODS                                                            |
|  =================                                                            |
|                                                                               |
|  1. HR System Correlation                                                     |
|     - Compare account owners against active employee list                     |
|     - Flag accounts belonging to terminated employees                         |
|                                                                               |
|  2. Last Login Analysis                                                       |
|     - Identify accounts with no login > 90 days                               |
|     - Cross-reference with expected usage patterns                            |
|                                                                               |
|  3. Manager Verification                                                      |
|     - Periodic attestation campaigns                                          |
|     - Manager confirms account necessity                                      |
|                                                                               |
|  DETECTION QUERY                                                              |
|  ===============                                                              |
|                                                                               |
|  # Windows - Find accounts with no recent logon                               |
|  Get-ADUser -Filter * -Properties LastLogonDate |                             |
|      Where-Object { $_.LastLogonDate -lt (Get-Date).AddDays(-90) -and         |
|                     $_.Enabled -eq $true } |                                  |
|      Select-Object Name, SamAccountName, LastLogonDate                        |
|                                                                               |
|  # Linux - Check last login times                                             |
|  lastlog | awk '$NF != "in" && NR > 1 {print $1}'                             |
|                                                                               |
|  REMEDIATION WORKFLOW                                                         |
|  ====================                                                         |
|                                                                               |
|  +----------+     +----------+     +----------+     +----------+             |
|  |  DETECT  |---->|  NOTIFY  |---->|  VERIFY  |---->|  ACTION  |             |
|  | Orphaned |     |  Owner/  |     |  Still   |     |  Disable |             |
|  | Account  |     |  Manager |     |  Needed? |     |  or Keep |             |
|  +----------+     +----------+     +----------+     +----------+             |
|                                                                               |
+==============================================================================+
```

### Shared Account Identification

```
+==============================================================================+
|                    SHARED ACCOUNT IDENTIFICATION                              |
+==============================================================================+
|                                                                               |
|  DETECTION INDICATORS                                                         |
|  ====================                                                         |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  | Indicator                   | Detection Method                        |   |
|  +-----------------------------+-----------------------------------------+   |
|  | Multiple source IPs        | Analyze login source diversity          |   |
|  | Concurrent sessions        | Monitor simultaneous active sessions    |   |
|  | Generic naming             | Pattern match: admin, operator, shared  |   |
|  | No individual attribution  | Missing employee association            |   |
|  | Distributed knowledge      | Password known by multiple people       |   |
|  +-----------------------------+-----------------------------------------+   |
|                                                                               |
|  ANALYSIS QUERY                                                               |
|  ==============                                                               |
|                                                                               |
|  # Find accounts with logins from multiple IPs in 24 hours                    |
|  SELECT account_name,                                                         |
|         COUNT(DISTINCT source_ip) as unique_ips,                              |
|         COUNT(*) as login_count                                               |
|  FROM session_logs                                                            |
|  WHERE timestamp > NOW() - INTERVAL '24 hours'                                |
|  GROUP BY account_name                                                        |
|  HAVING COUNT(DISTINCT source_ip) > 3;                                        |
|                                                                               |
|  REMEDIATION OPTIONS                                                          |
|  ===================                                                          |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  | Option               | Description                    | Use Case     |   |
|  +----------------------+--------------------------------+--------------+   |
|  | Convert to personal  | Create individual accounts     | Standard     |   |
|  | Implement PAM        | Managed shared credential      | Necessary    |   |
|  | Service account      | Automated, non-human access    | Automation   |   |
|  | Eliminate            | Remove account entirely        | Deprecated   |   |
|  +----------------------+--------------------------------+--------------+   |
|                                                                               |
+==============================================================================+
```

### Privileged Account Inventory

```
+==============================================================================+
|                    PRIVILEGED ACCOUNT INVENTORY                               |
+==============================================================================+
|                                                                               |
|  INVENTORY STRUCTURE                                                          |
|  ===================                                                          |
|                                                                               |
|  {                                                                            |
|    "inventory_date": "2026-02-01",                                            |
|    "organization": "Company Inc.",                                            |
|    "summary": {                                                               |
|      "total_accounts": 2547,                                                  |
|      "critical_accounts": 45,                                                 |
|      "high_risk_accounts": 312,                                               |
|      "managed_by_pam": 1890,                                                  |
|      "unmanaged": 657,                                                        |
|      "orphaned": 23                                                           |
|    },                                                                         |
|    "by_category": {                                                           |
|      "domain_admin": 15,                                                      |
|      "local_admin": 892,                                                      |
|      "service_account": 456,                                                  |
|      "database_admin": 89,                                                    |
|      "network_device": 234,                                                   |
|      "cloud_iam": 567,                                                        |
|      "application": 294                                                       |
|    },                                                                         |
|    "risk_score": {                                                            |
|      "overall": 72,                                                           |
|      "trend": "improving",                                                    |
|      "last_assessment": "2026-01-15"                                          |
|    }                                                                          |
|  }                                                                            |
|                                                                               |
|  RISK SCORING MODEL                                                           |
|  ==================                                                           |
|                                                                               |
|  Score = (Unmanaged / Total) * 40 +                                           |
|          (No_Rotation / Managed) * 30 +                                       |
|          (Shared / Total) * 20 +                                              |
|          (Orphaned / Total) * 10                                              |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  | Score Range | Risk Level | Action Required                           |   |
|  +-------------+------------+-------------------------------------------+   |
|  | 0-25        | Low        | Maintain current practices                |   |
|  | 26-50       | Moderate   | Address gaps within 90 days               |   |
|  | 51-75       | High       | Immediate remediation plan needed         |   |
|  | 76-100      | Critical   | Emergency action required                 |   |
|  +-------------+------------+-------------------------------------------+   |
|                                                                               |
+==============================================================================+
```

---

## Scheduled Discovery

### Periodic Scanning Configuration

```
+==============================================================================+
|                    SCHEDULED DISCOVERY CONFIGURATION                          |
+==============================================================================+
|                                                                               |
|  SCHEDULE DEFINITIONS                                                         |
|  ====================                                                         |
|                                                                               |
|  {                                                                            |
|    "discovery_schedules": [                                                   |
|      {                                                                        |
|        "name": "daily_windows_scan",                                          |
|        "description": "Daily Windows local admin discovery",                  |
|        "schedule": "0 2 * * *",                                               |
|        "target_type": "windows",                                              |
|        "scope": {                                                             |
|          "domains": ["corp.company.com"],                                     |
|          "ou_filter": "OU=Servers,DC=corp,DC=company,DC=com"                  |
|        },                                                                     |
|        "discovery_types": ["local_admins", "services"],                       |
|        "notification": {                                                      |
|          "on_new_account": true,                                              |
|          "recipients": ["security@company.com"]                               |
|        }                                                                      |
|      },                                                                       |
|      {                                                                        |
|        "name": "weekly_linux_scan",                                           |
|        "description": "Weekly Linux privileged account scan",                 |
|        "schedule": "0 3 * * 0",                                               |
|        "target_type": "linux",                                                |
|        "scope": {                                                             |
|          "ip_ranges": ["192.168.1.0/24", "10.0.0.0/16"]                       |
|        },                                                                     |
|        "discovery_types": ["root_accounts", "sudo_users", "ssh_keys"],        |
|        "credentials": {                                                       |
|          "account": "discovery_svc",                                          |
|          "from_vault": true                                                   |
|        }                                                                      |
|      },                                                                       |
|      {                                                                        |
|        "name": "monthly_cloud_scan",                                          |
|        "description": "Monthly cloud IAM discovery",                          |
|        "schedule": "0 4 1 * *",                                               |
|        "target_type": "cloud",                                                |
|        "scope": {                                                             |
|          "providers": ["aws", "azure", "gcp"],                                |
|          "accounts": ["prod", "staging"]                                      |
|        },                                                                     |
|        "discovery_types": ["iam_users", "service_accounts", "api_keys"]       |
|      }                                                                        |
|    ]                                                                          |
|  }                                                                            |
|                                                                               |
+==============================================================================+
```

### Change Detection and Alerting

```
+==============================================================================+
|                    CHANGE DETECTION AND ALERTING                              |
+==============================================================================+
|                                                                               |
|  CHANGE TYPES MONITORED                                                       |
|  ======================                                                       |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  | Change Type              | Alert Level | Action                       |   |
|  +--------------------------+-------------+------------------------------+   |
|  | New privileged account   | High        | Notify + queue for onboard   |   |
|  | Account deleted          | Medium      | Log and verify legitimate    |   |
|  | Privilege escalation     | Critical    | Immediate notification       |   |
|  | Password age exceeded    | Medium      | Schedule rotation            |   |
|  | New service account      | High        | Review and classify          |   |
|  | Orphaned account detected| Medium      | Start remediation workflow   |   |
|  | Shared account activity  | High        | Alert security team          |   |
|  +--------------------------+-------------+------------------------------+   |
|                                                                               |
|  ALERT CONFIGURATION                                                          |
|  ===================                                                          |
|                                                                               |
|  {                                                                            |
|    "alert_rules": [                                                           |
|      {                                                                        |
|        "name": "new_domain_admin",                                            |
|        "condition": {                                                         |
|          "event": "account_discovered",                                       |
|          "group_membership": "Domain Admins"                                  |
|        },                                                                     |
|        "actions": [                                                           |
|          {"type": "email", "to": "security@company.com"},                     |
|          {"type": "siem", "severity": "high"},                                |
|          {"type": "ticket", "system": "servicenow", "priority": "P1"}         |
|        ]                                                                      |
|      },                                                                       |
|      {                                                                        |
|        "name": "unmanaged_root_account",                                      |
|        "condition": {                                                         |
|          "event": "account_discovered",                                       |
|          "account_type": "root",                                              |
|          "not_in_pam": true                                                   |
|        },                                                                     |
|        "actions": [                                                           |
|          {"type": "email", "to": "pam-admins@company.com"},                   |
|          {"type": "auto_onboard", "domain": "Pending-Review"}                 |
|        ]                                                                      |
|      }                                                                        |
|    ]                                                                          |
|  }                                                                            |
|                                                                               |
|  DELTA REPORT FORMAT                                                          |
|  ===================                                                          |
|                                                                               |
|  {                                                                            |
|    "report_date": "2026-02-01",                                               |
|    "comparison_period": "2026-01-25 to 2026-02-01",                           |
|    "changes": {                                                               |
|      "new_accounts": [                                                        |
|        {"host": "srv-new-01", "account": "admin", "discovered": "2026-01-28"} |
|      ],                                                                       |
|      "removed_accounts": [                                                    |
|        {"host": "srv-old-01", "account": "root", "last_seen": "2026-01-20"}   |
|      ],                                                                       |
|      "privilege_changes": [                                                   |
|        {"account": "jsmith", "change": "added to Domain Admins"}              |
|      ]                                                                        |
|    }                                                                          |
|  }                                                                            |
|                                                                               |
+==============================================================================+
```

---

## Discovery Scripts

### Linux Discovery Script

```bash
#!/bin/bash
#==============================================================================
# Linux Account Discovery Script for WALLIX Bastion
# Discovers privileged accounts and generates onboarding data
#==============================================================================

set -euo pipefail

# Configuration
OUTPUT_DIR="/tmp/wallix_discovery"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
HOSTNAME=$(hostname -f)
OUTPUT_FILE="${OUTPUT_DIR}/discovery_${HOSTNAME}_${TIMESTAMP}.json"

# Create output directory
mkdir -p "${OUTPUT_DIR}"

# Initialize JSON output
cat > "${OUTPUT_FILE}" << EOF
{
  "discovery_timestamp": "$(date -Iseconds)",
  "hostname": "${HOSTNAME}",
  "ip_addresses": $(hostname -I | tr ' ' '\n' | grep -v '^$' | jq -R . | jq -s .),
  "os_info": "$(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'"' -f2)",
  "accounts": []
}
EOF

echo "Starting Linux account discovery on ${HOSTNAME}..."

# Function to add account to JSON
add_account() {
    local login="$1"
    local uid="$2"
    local shell="$3"
    local home="$4"
    local privileges="$5"
    local risk_level="$6"

    local temp_file=$(mktemp)
    jq --arg login "$login" \
       --arg uid "$uid" \
       --arg shell "$shell" \
       --arg home "$home" \
       --arg privileges "$privileges" \
       --arg risk "$risk_level" \
       '.accounts += [{
         "login": $login,
         "uid": ($uid | tonumber),
         "shell": $shell,
         "home_directory": $home,
         "privileges": $privileges,
         "risk_level": $risk,
         "credential_type": "password",
         "needs_onboarding": true
       }]' "${OUTPUT_FILE}" > "${temp_file}"
    mv "${temp_file}" "${OUTPUT_FILE}"
}

# Discover UID 0 accounts (root equivalent)
echo "Scanning for UID 0 accounts..."
while IFS=: read -r login _ uid _ _ home shell; do
    if [ "$uid" -eq 0 ]; then
        add_account "$login" "$uid" "$shell" "$home" "root_equivalent" "critical"
    fi
done < /etc/passwd

# Discover accounts in sudo/wheel group
echo "Scanning sudo/wheel group members..."
for group in sudo wheel admin; do
    if getent group "$group" > /dev/null 2>&1; then
        members=$(getent group "$group" | cut -d: -f4 | tr ',' '\n')
        for member in $members; do
            if [ -n "$member" ]; then
                user_info=$(getent passwd "$member" 2>/dev/null || echo "")
                if [ -n "$user_info" ]; then
                    uid=$(echo "$user_info" | cut -d: -f3)
                    shell=$(echo "$user_info" | cut -d: -f7)
                    home=$(echo "$user_info" | cut -d: -f6)
                    add_account "$member" "$uid" "$shell" "$home" "sudo_${group}" "high"
                fi
            fi
        done
    fi
done

# Discover sudoers entries
echo "Analyzing sudoers configuration..."
SUDOERS_USERS=""
if [ -r /etc/sudoers ]; then
    SUDOERS_USERS=$(grep -v '^#' /etc/sudoers 2>/dev/null | \
                   grep -E '^[a-zA-Z]' | \
                   grep -v '^Defaults' | \
                   grep -v '^Cmnd_Alias' | \
                   grep -v '^User_Alias' | \
                   awk '{print $1}' | \
                   grep -v '^%' | \
                   sort -u || true)
fi

# Check sudoers.d
if [ -d /etc/sudoers.d ]; then
    for file in /etc/sudoers.d/*; do
        if [ -r "$file" ]; then
            MORE_USERS=$(grep -v '^#' "$file" 2>/dev/null | \
                        grep -E '^[a-zA-Z]' | \
                        grep -v '^Defaults' | \
                        awk '{print $1}' | \
                        grep -v '^%' || true)
            SUDOERS_USERS="${SUDOERS_USERS}
${MORE_USERS}"
        fi
    done
fi

for user in $(echo "$SUDOERS_USERS" | sort -u | grep -v '^$'); do
    user_info=$(getent passwd "$user" 2>/dev/null || echo "")
    if [ -n "$user_info" ]; then
        uid=$(echo "$user_info" | cut -d: -f3)
        shell=$(echo "$user_info" | cut -d: -f7)
        home=$(echo "$user_info" | cut -d: -f6)
        add_account "$user" "$uid" "$shell" "$home" "sudoers_entry" "high"
    fi
done

# Add SSH key information
echo "Scanning SSH authorized keys..."
temp_file=$(mktemp)
jq '.ssh_keys = []' "${OUTPUT_FILE}" > "${temp_file}"
mv "${temp_file}" "${OUTPUT_FILE}"

find /home -name "authorized_keys" -type f 2>/dev/null | while read -r keyfile; do
    user=$(echo "$keyfile" | cut -d'/' -f3)
    key_count=$(wc -l < "$keyfile" 2>/dev/null || echo "0")

    temp_file=$(mktemp)
    jq --arg user "$user" \
       --arg keyfile "$keyfile" \
       --arg count "$key_count" \
       '.ssh_keys += [{
         "user": $user,
         "keyfile": $keyfile,
         "key_count": ($count | tonumber)
       }]' "${OUTPUT_FILE}" > "${temp_file}"
    mv "${temp_file}" "${OUTPUT_FILE}"
done

# Check root authorized_keys
if [ -f /root/.ssh/authorized_keys ]; then
    key_count=$(wc -l < /root/.ssh/authorized_keys 2>/dev/null || echo "0")
    temp_file=$(mktemp)
    jq --arg count "$key_count" \
       '.ssh_keys += [{
         "user": "root",
         "keyfile": "/root/.ssh/authorized_keys",
         "key_count": ($count | tonumber)
       }]' "${OUTPUT_FILE}" > "${temp_file}"
    mv "${temp_file}" "${OUTPUT_FILE}"
fi

# Remove duplicate accounts
temp_file=$(mktemp)
jq '.accounts |= unique_by(.login)' "${OUTPUT_FILE}" > "${temp_file}"
mv "${temp_file}" "${OUTPUT_FILE}"

# Add summary
temp_file=$(mktemp)
jq '.summary = {
  "total_accounts": (.accounts | length),
  "critical_accounts": ([.accounts[] | select(.risk_level == "critical")] | length),
  "high_risk_accounts": ([.accounts[] | select(.risk_level == "high")] | length),
  "ssh_keys_found": ([.ssh_keys[].key_count] | add // 0)
}' "${OUTPUT_FILE}" > "${temp_file}"
mv "${temp_file}" "${OUTPUT_FILE}"

echo "Discovery complete. Output saved to: ${OUTPUT_FILE}"
echo "Summary:"
jq '.summary' "${OUTPUT_FILE}"
```

### Windows Discovery Script

```powershell
#==============================================================================
# Windows Account Discovery Script for WALLIX Bastion
# Discovers privileged accounts and generates onboarding data
#==============================================================================

param(
    [string]$OutputPath = "C:\Temp\WallixDiscovery",
    [switch]$IncludeServices,
    [switch]$IncludeScheduledTasks
)

$ErrorActionPreference = "Stop"
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$Hostname = $env:COMPUTERNAME
$OutputFile = Join-Path $OutputPath "discovery_${Hostname}_${Timestamp}.json"

# Create output directory
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

Write-Host "Starting Windows account discovery on $Hostname..."

# Initialize discovery object
$Discovery = @{
    discovery_timestamp = (Get-Date -Format "o")
    hostname = $Hostname
    domain = $env:USERDOMAIN
    os_info = (Get-CimInstance Win32_OperatingSystem).Caption
    accounts = @()
    services = @()
    scheduled_tasks = @()
}

# Discover local administrators
Write-Host "Scanning local administrators..."
try {
    $LocalAdmins = Get-LocalGroupMember -Group "Administrators" -ErrorAction SilentlyContinue
    foreach ($admin in $LocalAdmins) {
        $accountInfo = @{
            name = $admin.Name
            object_class = $admin.ObjectClass
            principal_source = $admin.PrincipalSource.ToString()
            risk_level = "high"
            needs_onboarding = $true
        }

        # Check if it's the built-in Administrator
        if ($admin.Name -like "*\Administrator") {
            $accountInfo.risk_level = "critical"
            $accountInfo.is_builtin = $true
        }

        # Check if it's Domain Admins group
        if ($admin.Name -like "*\Domain Admins") {
            $accountInfo.risk_level = "critical"
            $accountInfo.note = "Nested domain admin access"
        }

        $Discovery.accounts += $accountInfo
    }
} catch {
    Write-Warning "Could not enumerate local administrators: $_"
}

# Discover local users with admin privileges
Write-Host "Scanning local user accounts..."
try {
    $LocalUsers = Get-LocalUser | Where-Object { $_.Enabled -eq $true }
    foreach ($user in $LocalUsers) {
        # Check if already in list
        if ($Discovery.accounts.name -notcontains "$Hostname\$($user.Name)") {
            $accountInfo = @{
                name = "$Hostname\$($user.Name)"
                object_class = "User"
                principal_source = "Local"
                enabled = $user.Enabled
                password_last_set = $user.PasswordLastSet
                password_expires = $user.PasswordExpires
                last_logon = $user.LastLogon
                risk_level = "medium"
                needs_onboarding = $true
            }

            # Flag accounts with password issues
            if ($null -eq $user.PasswordLastSet -or
                $user.PasswordLastSet -lt (Get-Date).AddDays(-365)) {
                $accountInfo.risk_level = "high"
                $accountInfo.password_age_warning = $true
            }

            $Discovery.accounts += $accountInfo
        }
    }
} catch {
    Write-Warning "Could not enumerate local users: $_"
}

# Discover service accounts
if ($IncludeServices) {
    Write-Host "Scanning service accounts..."
    try {
        $Services = Get-CimInstance Win32_Service | Where-Object {
            $_.StartName -and
            $_.StartName -notlike "LocalSystem" -and
            $_.StartName -notlike "NT AUTHORITY\*" -and
            $_.StartName -notlike "NT SERVICE\*"
        }

        foreach ($svc in $Services) {
            $serviceInfo = @{
                service_name = $svc.Name
                display_name = $svc.DisplayName
                start_name = $svc.StartName
                state = $svc.State
                start_mode = $svc.StartMode
                risk_level = "high"
                needs_onboarding = $true
            }
            $Discovery.services += $serviceInfo

            # Add service account to accounts list if not present
            if ($Discovery.accounts.name -notcontains $svc.StartName) {
                $Discovery.accounts += @{
                    name = $svc.StartName
                    object_class = "ServiceAccount"
                    source = "WindowsService"
                    associated_services = @($svc.Name)
                    risk_level = "high"
                    needs_onboarding = $true
                }
            }
        }
    } catch {
        Write-Warning "Could not enumerate services: $_"
    }
}

# Discover scheduled task accounts
if ($IncludeScheduledTasks) {
    Write-Host "Scanning scheduled task accounts..."
    try {
        $Tasks = Get-ScheduledTask | Where-Object { $_.State -ne "Disabled" }

        foreach ($task in $Tasks) {
            $principal = $task.Principal
            if ($principal.UserId -and
                $principal.UserId -notlike "SYSTEM" -and
                $principal.UserId -notlike "LOCAL SERVICE" -and
                $principal.UserId -notlike "NETWORK SERVICE") {

                $taskInfo = @{
                    task_name = $task.TaskName
                    task_path = $task.TaskPath
                    user_id = $principal.UserId
                    logon_type = $principal.LogonType.ToString()
                    state = $task.State.ToString()
                    risk_level = if ($principal.LogonType -eq "Password") { "high" } else { "medium" }
                    needs_onboarding = $true
                }
                $Discovery.scheduled_tasks += $taskInfo
            }
        }
    } catch {
        Write-Warning "Could not enumerate scheduled tasks: $_"
    }
}

# Add summary
$Discovery.summary = @{
    total_accounts = $Discovery.accounts.Count
    critical_accounts = ($Discovery.accounts | Where-Object { $_.risk_level -eq "critical" }).Count
    high_risk_accounts = ($Discovery.accounts | Where-Object { $_.risk_level -eq "high" }).Count
    service_accounts = $Discovery.services.Count
    scheduled_task_accounts = $Discovery.scheduled_tasks.Count
}

# Save to JSON
$Discovery | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputFile -Encoding UTF8

Write-Host "`nDiscovery complete. Output saved to: $OutputFile"
Write-Host "`nSummary:"
Write-Host "  Total Accounts: $($Discovery.summary.total_accounts)"
Write-Host "  Critical: $($Discovery.summary.critical_accounts)"
Write-Host "  High Risk: $($Discovery.summary.high_risk_accounts)"
Write-Host "  Service Accounts: $($Discovery.summary.service_accounts)"
Write-Host "  Scheduled Tasks: $($Discovery.summary.scheduled_task_accounts)"
```

### API Onboarding Script

```python
#!/usr/bin/env python3
"""
WALLIX Bastion Account Onboarding Script
Imports discovered accounts into WALLIX Bastion via REST API

Reference: https://pam.wallix.one/documentation/admin-doc/bastion_en_administration_guide.pdf
"""

import json
import requests
import argparse
import logging
from datetime import datetime
from pathlib import Path

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class WallixOnboarder:
    def __init__(self, host: str, api_key: str, verify_ssl: bool = True):
        self.base_url = f"https://{host}/api/v2"
        self.headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
            "Accept": "application/json"
        }
        self.verify_ssl = verify_ssl
        self.session = requests.Session()
        self.session.headers.update(self.headers)
        self.session.verify = verify_ssl

    def test_connection(self) -> bool:
        """Test API connectivity"""
        try:
            response = self.session.get(f"{self.base_url}/health")
            return response.status_code == 200
        except Exception as e:
            logger.error(f"Connection test failed: {e}")
            return False

    def get_or_create_domain(self, domain_name: str, description: str = None) -> dict:
        """Get existing domain or create new one"""
        # Check if domain exists
        response = self.session.get(
            f"{self.base_url}/domains",
            params={"search": domain_name}
        )

        if response.status_code == 200:
            domains = response.json().get("data", [])
            for domain in domains:
                if domain.get("domain_name") == domain_name:
                    logger.info(f"Found existing domain: {domain_name}")
                    return domain

        # Create new domain
        domain_data = {
            "domain_name": domain_name,
            "description": description or f"Auto-created by discovery on {datetime.now().isoformat()}"
        }

        response = self.session.post(
            f"{self.base_url}/domains",
            json=domain_data
        )

        if response.status_code == 201:
            logger.info(f"Created new domain: {domain_name}")
            return response.json().get("data", {})
        else:
            logger.error(f"Failed to create domain: {response.text}")
            return None

    def get_or_create_device(self, device_name: str, host: str, domain: str) -> dict:
        """Get existing device or create new one"""
        # Check if device exists
        response = self.session.get(
            f"{self.base_url}/devices",
            params={"search": device_name}
        )

        if response.status_code == 200:
            devices = response.json().get("data", [])
            for device in devices:
                if device.get("device_name") == device_name:
                    logger.info(f"Found existing device: {device_name}")
                    return device

        # Create new device
        device_data = {
            "device_name": device_name,
            "host": host,
            "domain": domain,
            "description": f"Auto-discovered on {datetime.now().isoformat()}"
        }

        response = self.session.post(
            f"{self.base_url}/devices",
            json=device_data
        )

        if response.status_code == 201:
            logger.info(f"Created new device: {device_name}")
            return response.json().get("data", {})
        else:
            logger.error(f"Failed to create device: {response.text}")
            return None

    def create_service(self, device_name: str, protocol: str, port: int) -> dict:
        """Create service on device"""
        service_data = {
            "service_name": protocol,
            "protocol": protocol,
            "port": port
        }

        response = self.session.post(
            f"{self.base_url}/devices/{device_name}/services",
            json=service_data
        )

        if response.status_code == 201:
            logger.info(f"Created service {protocol} on {device_name}")
            return response.json().get("data", {})
        elif response.status_code == 409:
            logger.info(f"Service {protocol} already exists on {device_name}")
            return {"service_name": protocol}
        else:
            logger.error(f"Failed to create service: {response.text}")
            return None

    def create_account(self, device_name: str, account_data: dict) -> dict:
        """Create account on device"""
        response = self.session.post(
            f"{self.base_url}/devices/{device_name}/accounts",
            json=account_data
        )

        if response.status_code == 201:
            logger.info(f"Created account: {account_data.get('account_name')}")
            return response.json().get("data", {})
        elif response.status_code == 409:
            logger.warning(f"Account already exists: {account_data.get('account_name')}")
            return None
        else:
            logger.error(f"Failed to create account: {response.text}")
            return None

    def onboard_discovery_file(self, discovery_file: str, domain: str,
                               default_password: str = None, dry_run: bool = False) -> dict:
        """Process discovery file and onboard accounts"""

        with open(discovery_file, 'r') as f:
            discovery_data = json.load(f)

        results = {
            "processed": 0,
            "created": 0,
            "skipped": 0,
            "errors": 0,
            "details": []
        }

        hostname = discovery_data.get("hostname", "unknown")
        ip_addresses = discovery_data.get("ip_addresses", [])
        host = ip_addresses[0] if ip_addresses else hostname

        # Determine appropriate domain based on risk level
        accounts = discovery_data.get("accounts", [])

        if dry_run:
            logger.info("DRY RUN MODE - No changes will be made")

        # Ensure domain exists
        if not dry_run:
            self.get_or_create_domain(domain)
            self.get_or_create_device(hostname, host, domain)
            self.create_service(hostname, "SSH", 22)

        for account in accounts:
            results["processed"] += 1
            login = account.get("login")
            risk_level = account.get("risk_level", "medium")

            # Skip system accounts
            if login in ["nobody", "daemon", "bin", "sys"]:
                results["skipped"] += 1
                results["details"].append({
                    "account": login,
                    "action": "skipped",
                    "reason": "system account"
                })
                continue

            account_name = f"{login}@{hostname}"

            account_payload = {
                "account_name": account_name,
                "login": login,
                "description": f"Discovered {risk_level} risk account",
                "credentials": {
                    "type": account.get("credential_type", "password")
                },
                "auto_change_password": True
            }

            # Set password if provided
            if default_password and account_payload["credentials"]["type"] == "password":
                account_payload["credentials"]["password"] = default_password

            if dry_run:
                logger.info(f"[DRY RUN] Would create account: {account_name}")
                results["created"] += 1
            else:
                result = self.create_account(hostname, account_payload)
                if result:
                    results["created"] += 1
                    results["details"].append({
                        "account": account_name,
                        "action": "created",
                        "risk_level": risk_level
                    })
                else:
                    results["errors"] += 1
                    results["details"].append({
                        "account": account_name,
                        "action": "error"
                    })

        return results


def main():
    parser = argparse.ArgumentParser(description="WALLIX Bastion Account Onboarding")
    parser.add_argument("--host", required=True, help="WALLIX Bastion hostname")
    parser.add_argument("--api-key", required=True, help="API key for authentication")
    parser.add_argument("--discovery-file", required=True, help="Path to discovery JSON file")
    parser.add_argument("--domain", required=True, help="Target domain for onboarding")
    parser.add_argument("--default-password", help="Default password for new accounts")
    parser.add_argument("--dry-run", action="store_true", help="Simulate without making changes")
    parser.add_argument("--no-verify-ssl", action="store_true", help="Disable SSL verification")

    args = parser.parse_args()

    onboarder = WallixOnboarder(
        host=args.host,
        api_key=args.api_key,
        verify_ssl=not args.no_verify_ssl
    )

    if not onboarder.test_connection():
        logger.error("Failed to connect to WALLIX Bastion")
        return 1

    logger.info("Connected to WALLIX Bastion successfully")

    results = onboarder.onboard_discovery_file(
        discovery_file=args.discovery_file,
        domain=args.domain,
        default_password=args.default_password,
        dry_run=args.dry_run
    )

    logger.info(f"\nOnboarding Summary:")
    logger.info(f"  Processed: {results['processed']}")
    logger.info(f"  Created: {results['created']}")
    logger.info(f"  Skipped: {results['skipped']}")
    logger.info(f"  Errors: {results['errors']}")

    return 0 if results['errors'] == 0 else 1


if __name__ == "__main__":
    exit(main())
```

---

## Related Documentation

- [04 - Configuration & Object Model](../04-configuration/README.md) - Understanding WALLIX object hierarchy
- [07 - Password Management](../07-password-management/README.md) - Credential rotation and vault management
- [09 - API & Automation](../09-api-automation/README.md) - REST API integration patterns
- [26 - API Reference](../26-api-reference/README.md) - Complete API documentation
- [30 - Operational Runbooks](../30-operational-runbooks/README.md) - Day-to-day operational procedures

## External Resources

- [WALLIX Documentation Portal](https://pam.wallix.one/documentation)
- [WALLIX REST API Samples](https://github.com/wallix/wbrest_samples)
- [WALLIX Terraform Provider](https://registry.terraform.io/providers/wallix/wallix-bastion)
- [NIST SP 800-53 Access Control](https://csrc.nist.gov/publications/detail/sp/800-53/rev-5/final)
