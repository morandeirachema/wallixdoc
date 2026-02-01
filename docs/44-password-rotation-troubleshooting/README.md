# 44 - Password Rotation Troubleshooting

## Table of Contents

1. [Password Rotation Overview](#password-rotation-overview)
2. [Rotation Architecture](#rotation-architecture)
3. [Common Rotation Errors](#common-rotation-errors)
4. [Linux/Unix Rotation Issues](#linuxunix-rotation-issues)
5. [Windows Rotation Issues](#windows-rotation-issues)
6. [Network Device Rotation Issues](#network-device-rotation-issues)
7. [Database Account Rotation](#database-account-rotation)
8. [SSH Key Rotation Issues](#ssh-key-rotation-issues)
9. [Connector Troubleshooting](#connector-troubleshooting)
10. [Reconciliation Procedures](#reconciliation-procedures)
11. [Rotation Queue Management](#rotation-queue-management)
12. [Diagnostic Commands and Scripts](#diagnostic-commands-and-scripts)

---

## Password Rotation Overview

### How Password Rotation Works

Password rotation in WALLIX Bastion is an automated process that changes credentials on target systems while maintaining synchronization with the credential vault.

```
+==============================================================================+
|                   PASSWORD ROTATION LIFECYCLE                                 |
+==============================================================================+
|                                                                               |
|  PHASE 1: TRIGGER                                                             |
|  ================                                                             |
|  * Scheduled rotation (cron-based)                                           |
|  * On-demand rotation (manual trigger)                                       |
|  * Post-session rotation (after checkout return)                             |
|  * Policy-triggered rotation (compliance requirement)                        |
|                                                                               |
|  PHASE 2: PRE-ROTATION CHECKS                                                 |
|  ============================                                                 |
|  * Verify target connectivity                                                |
|  * Validate current credentials                                              |
|  * Check for active sessions (optional block)                                |
|  * Verify rotation account permissions                                       |
|                                                                               |
|  PHASE 3: PASSWORD GENERATION                                                 |
|  ============================                                                 |
|  * Apply password policy rules                                               |
|  * Cryptographic random generation                                           |
|  * Password history validation                                               |
|  * Complexity requirement verification                                       |
|                                                                               |
|  PHASE 4: PASSWORD CHANGE                                                     |
|  ========================                                                     |
|  * Connect to target via connector                                           |
|  * Execute password change command                                           |
|  * Handle prompts and confirmations                                          |
|  * Parse response for success/failure                                        |
|                                                                               |
|  PHASE 5: VERIFICATION                                                        |
|  ====================                                                         |
|  * Attempt authentication with new password                                  |
|  * Verify login success                                                      |
|  * Test expected permissions (optional)                                      |
|                                                                               |
|  PHASE 6: VAULT UPDATE                                                        |
|  =====================                                                        |
|  * Encrypt new password                                                      |
|  * Store in credential vault                                                 |
|  * Update password history                                                   |
|  * Log rotation event                                                        |
|                                                                               |
+==============================================================================+
```

### Components Involved in Rotation

| Component | Role | Location |
|-----------|------|----------|
| Password Manager Service | Orchestrates rotation workflow | `wabpassword` service |
| Rotation Scheduler | Triggers scheduled rotations | `wabscheduler` service |
| Credential Vault | Stores encrypted passwords | PostgreSQL database |
| Target Connectors | Execute password changes | Plugin-based system |
| Rotation Account | Account with change privileges | Configured per device |

### Rotation Log Locations

| Log File | Purpose |
|----------|---------|
| `/var/log/wab/wabpassword.log` | Primary rotation log |
| `/var/log/wab/wabscheduler.log` | Scheduler operations |
| `/var/log/wab/wabengine.log` | General application events |
| `/var/log/wab/wabaudit.log` | Audit trail of rotations |

---

## Rotation Architecture

### Password Rotation Flow Diagram

```
+==============================================================================+
|                   PASSWORD ROTATION ARCHITECTURE                              |
+==============================================================================+
|                                                                               |
|    +------------------+                                                       |
|    |    SCHEDULER     |     Cron-based triggers                              |
|    |    SERVICE       |     (wabscheduler)                                   |
|    +--------+---------+                                                       |
|             |                                                                 |
|             | Rotation Request                                                |
|             v                                                                 |
|    +------------------+                                                       |
|    |    ROTATION      |     Coordinates all phases                           |
|    |    ORCHESTRATOR  |     (wabpassword)                                    |
|    +--------+---------+                                                       |
|             |                                                                 |
|             |                                                                 |
|     +-------+-------+-------+-------+                                         |
|     |       |       |       |       |                                         |
|     v       v       v       v       v                                         |
|  +------+ +------+ +------+ +------+ +------+                                 |
|  | SSH  | |WinRM | | SNMP | | SQL  | |Custom|   Target Connectors             |
|  | Conn | | Conn | | Conn | | Conn | | Conn |                                 |
|  +--+---+ +--+---+ +--+---+ +--+---+ +--+---+                                 |
|     |        |        |        |        |                                     |
|     v        v        v        v        v                                     |
|  +------+ +------+ +------+ +------+ +------+                                 |
|  |Linux | |Windows| |Network| |Oracle| |Custom|   Target Systems              |
|  |Server| |Server | |Device | | DB   | |Target|                               |
|  +------+ +------+ +------+ +------+ +------+                                 |
|                                                                               |
+==============================================================================+
|                                                                               |
|   ROTATION REQUEST FLOW                                                       |
|   =====================                                                       |
|                                                                               |
|   +-------------+    +-------------+    +-------------+    +-------------+   |
|   |  1. Queue   |    | 2. Connect  |    | 3. Change   |    | 4. Verify   |   |
|   |   Request   |--->|  to Target  |--->|  Password   |--->|  New Pwd    |   |
|   +-------------+    +-------------+    +-------------+    +------+------+   |
|                                                                    |          |
|                                                      +-------------+          |
|                                                      |                        |
|                                                      v                        |
|   +-------------+    +-------------+         +-------------+                  |
|   | 6. Complete |    | 5. Update   |         |  Success?   |                  |
|   |   Rotation  |<---|   Vault     |<--------|    Yes      |                  |
|   +-------------+    +-------------+         +------+------+                  |
|                                                      |                        |
|                                                      | No                     |
|                                                      v                        |
|                                              +-------------+                  |
|                                              | 7. Error    |                  |
|                                              |   Handling  |                  |
|                                              +-------------+                  |
|                                                      |                        |
|                                      +---------------+---------------+        |
|                                      |               |               |        |
|                                      v               v               v        |
|                               +-----------+  +-----------+  +-----------+    |
|                               |   Retry   |  |Reconcile  |  |  Alert    |    |
|                               |           |  |           |  |   Admin   |    |
|                               +-----------+  +-----------+  +-----------+    |
|                                                                               |
+==============================================================================+
```

### Port Requirements for Rotation

| Target Type | Protocol | Port | Notes |
|-------------|----------|------|-------|
| Linux/Unix | SSH | 22 | Default, configurable |
| Windows Local | WinRM HTTP | 5985 | Unencrypted |
| Windows Local | WinRM HTTPS | 5986 | Encrypted (recommended) |
| Windows Domain | LDAP | 389 | Domain controller |
| Windows Domain | LDAPS | 636 | Encrypted (recommended) |
| Cisco IOS | SSH | 22 | SSH v2 required |
| Cisco IOS | Telnet | 23 | Not recommended |
| Juniper JunOS | SSH | 22 | SSH v2 required |
| Palo Alto | SSH | 22 | SSH v2 required |
| Oracle DB | Oracle Net | 1521 | Default listener port |
| PostgreSQL | PostgreSQL | 5432 | Default port |
| MySQL/MariaDB | MySQL | 3306 | Default port |
| MS SQL Server | TDS | 1433 | Default instance |

---

## Common Rotation Errors

### Error Code Reference

```
+==============================================================================+
|                   ROTATION ERROR CODES                                        |
+==============================================================================+

  WAB-4001: ROTATION_FAILED
  =========================

  Message: "Password rotation failed for account '{account}' on device '{device}'"

  Common Causes:
  * Target system unreachable
  * Current credentials invalid
  * Password policy violation
  * Connector misconfiguration

  Resolution Steps:
  1. Check target connectivity
  2. Verify current credentials work
  3. Review password policy compatibility
  4. Test connector configuration

  Log Example:
  +------------------------------------------------------------------------+
  | 2024-01-27 02:00:00 ERROR [wabpassword] WAB-4001: Password rotation    |
  | failed for account 'root@srv-prod-01' - Connection refused             |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  WAB-4002: ROTATION_VERIFICATION_FAILED
  ======================================

  Message: "Password changed but verification failed"
  Severity: CRITICAL

  This is a critical error - password may be desynchronized!

  Common Causes:
  * Network issue during verification
  * Target rejected new password after accepting change
  * Concurrent password change by another process
  * Target requires password change delay

  Resolution Steps:
  1. DO NOT attempt another rotation immediately
  2. Manually test current vault password on target
  3. If vault password fails, trigger reconciliation
  4. If vault password works, mark rotation as successful

  +------------------------------------------------------------------------+
  | EMERGENCY RECOVERY:                                                    |
  | $ wabadmin password verify <device>/<account>                          |
  | $ wabadmin password reconcile <device>/<account> --force               |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  WAB-4003: CONNECTOR_ERROR
  =========================

  Message: "Connector error: {specific error message}"

  Common Causes:
  * Connector not installed or configured
  * Protocol version mismatch
  * Missing dependencies
  * Incorrect connector type for target

  Resolution Steps:
  1. Verify connector is installed: wabadmin connector list
  2. Test connector: wabadmin connector test <connector-id>
  3. Check connector configuration matches target
  4. Review connector logs for specific error

  --------------------------------------------------------------------------

  WAB-4004: CONNECTION_TIMEOUT
  ============================

  Message: "Connection to target timed out after {seconds} seconds"

  Common Causes:
  * Network latency or routing issues
  * Firewall blocking connection
  * Target system overloaded
  * DNS resolution slow

  Resolution Steps:
  1. Test basic connectivity: ping <target>
  2. Test port access: nc -zv <target> <port>
  3. Check firewall rules
  4. Increase timeout if network latency is expected

  --------------------------------------------------------------------------

  WAB-4005: AUTHENTICATION_FAILED
  ================================

  Message: "Authentication failed with current credentials"

  Common Causes:
  * Vault password is out of sync
  * Account locked on target
  * Password expired on target
  * SSH key invalid or revoked

  Resolution Steps:
  1. Manually verify vault credentials
  2. Check account status on target
  3. Trigger reconciliation if needed
  4. Verify SSH key if key-based auth

  --------------------------------------------------------------------------

  WAB-4006: PASSWORD_POLICY_VIOLATION
  ====================================

  Message: "New password does not meet target password policy"

  Common Causes:
  * WALLIX policy less strict than target
  * Special characters not allowed by target
  * Password length mismatch
  * Password history conflict

  Resolution Steps:
  1. Review target password policy
  2. Adjust WALLIX password policy to match or exceed target
  3. Check password history requirements
  4. Test with simpler password policy temporarily

  --------------------------------------------------------------------------

  WAB-4007: PERMISSION_DENIED
  ===========================

  Message: "Insufficient permissions to change password"

  Common Causes:
  * Rotation account lacks password change rights
  * sudo not configured properly (Linux)
  * AD delegation not set (Windows)
  * Account is protected (built-in accounts)

  Resolution Steps:
  1. Verify rotation account permissions
  2. Check sudo configuration for Linux targets
  3. Verify AD delegation for Windows domain accounts
  4. Some accounts (root, Administrator) may have restrictions

  --------------------------------------------------------------------------

  WAB-4008: TARGET_ACCOUNT_LOCKED
  ================================

  Message: "Target account is locked and cannot be modified"

  Common Causes:
  * Too many failed authentication attempts
  * Account explicitly locked by admin
  * Security policy triggered lockout

  Resolution Steps:
  1. Unlock account on target system
  2. Review authentication failure logs
  3. Check for brute force attempts
  4. Consider increasing lockout threshold

  --------------------------------------------------------------------------

  WAB-4009: CONCURRENT_SESSION_BLOCK
  ===================================

  Message: "Rotation blocked due to active session"

  Common Causes:
  * Active session using the account
  * Rotation policy set to block during active sessions

  Resolution Steps:
  1. Wait for session to end
  2. If urgent, terminate session (with approval)
  3. Consider modifying rotation policy
  4. Schedule rotation during maintenance window

  --------------------------------------------------------------------------

  WAB-4010: ROTATION_QUEUE_FULL
  ==============================

  Message: "Rotation queue is full, request rejected"

  Common Causes:
  * Too many pending rotations
  * Previous rotations stuck
  * System performance issue

  Resolution Steps:
  1. Check rotation queue: wabadmin rotation --queue
  2. Clear stuck rotations
  3. Investigate why rotations are accumulating
  4. Increase queue size if legitimate

+==============================================================================+
```

---

## Linux/Unix Rotation Issues

### SSH Connection Failures

```
+==============================================================================+
|                   SSH CONNECTION FAILURES                                     |
+==============================================================================+

  ISSUE: Connection Refused
  =========================

  Error Message:
  +------------------------------------------------------------------------+
  | ssh: connect to host 10.10.1.50 port 22: Connection refused            |
  +------------------------------------------------------------------------+

  Diagnostic Steps:

  1. Verify SSH service is running on target:
     $ ssh admin@target "systemctl status sshd"

     If SSH is down, start it:
     $ ssh admin@target "sudo systemctl start sshd"

  2. Check if port 22 is listening:
     From Bastion: $ nc -zv 10.10.1.50 22

     Expected output:
     +--------------------------------------------------------------------+
     | Connection to 10.10.1.50 22 port [tcp/ssh] succeeded!              |
     +--------------------------------------------------------------------+

  3. Check firewall on target:
     $ ssh admin@target "sudo iptables -L INPUT -n | grep 22"
     $ ssh admin@target "sudo firewall-cmd --list-ports"

  4. Verify no IP restrictions in sshd_config:
     $ ssh admin@target "grep -E 'AllowUsers|AllowGroups|DenyUsers' /etc/ssh/sshd_config"

  --------------------------------------------------------------------------

  ISSUE: Host Key Verification Failed
  ====================================

  Error Message:
  +------------------------------------------------------------------------+
  | Host key verification failed.                                          |
  | The authenticity of host '10.10.1.50' can't be established.            |
  +------------------------------------------------------------------------+

  Common Causes:
  * Target server was reinstalled
  * IP address changed but hostname same
  * Potential MITM attack (investigate!)

  Resolution:

  1. Clear cached host key in WALLIX:
     Admin UI > Devices > [device] > Clear Host Key

     Or via CLI:
     $ wabadmin device clear-hostkey <device-name>

  2. Manually accept new host key:
     $ ssh-keyscan 10.10.1.50 >> /var/lib/wallix/.ssh/known_hosts

  3. If persistent, verify it's not a security issue:
     Compare: $ ssh-keyscan 10.10.1.50
     With known good key from target: $ cat /etc/ssh/ssh_host_ed25519_key.pub

  --------------------------------------------------------------------------

  ISSUE: Connection Timeout
  =========================

  Error Message:
  +------------------------------------------------------------------------+
  | ssh: connect to host 10.10.1.50 port 22: Connection timed out          |
  +------------------------------------------------------------------------+

  Diagnostic Steps:

  1. Test network path:
     $ ping -c 4 10.10.1.50
     $ traceroute 10.10.1.50

  2. Check for firewall blocking:
     $ sudo iptables -L OUTPUT -n | grep 22

  3. Test with increased timeout:
     $ ssh -o ConnectTimeout=30 root@10.10.1.50

  4. Check MTU issues (especially with VPNs):
     $ ping -c 4 -M do -s 1472 10.10.1.50

+==============================================================================+
```

### Sudo/Privilege Issues

```
+==============================================================================+
|                   SUDO AND PRIVILEGE ISSUES                                   |
+==============================================================================+

  ISSUE: sudo: no tty present
  ===========================

  Error Message:
  +------------------------------------------------------------------------+
  | sudo: no tty present and no askpass program specified                  |
  +------------------------------------------------------------------------+

  Cause: sudo requires a TTY but SSH is running without one

  Resolution:

  1. Disable requiretty for rotation account:
     On target, add to /etc/sudoers.d/wallix:
     +--------------------------------------------------------------------+
     | Defaults:wallix_rotate !requiretty                                 |
     | wallix_rotate ALL=(ALL) NOPASSWD: /usr/bin/passwd, /usr/sbin/chpasswd
     +--------------------------------------------------------------------+

  2. Or configure SSH to allocate PTY:
     In WALLIX connector settings, enable "Request PTY"

  --------------------------------------------------------------------------

  ISSUE: sudo: password required
  ===============================

  Error Message:
  +------------------------------------------------------------------------+
  | [sudo] password for wallix_rotate:                                     |
  | sudo: 1 incorrect password attempt                                     |
  +------------------------------------------------------------------------+

  Cause: NOPASSWD not configured for rotation commands

  Resolution:

  1. Configure passwordless sudo for rotation commands:
     $ sudo visudo -f /etc/sudoers.d/wallix-rotation

     Add:
     +--------------------------------------------------------------------+
     | # WALLIX Password Rotation - created $(date)                       |
     | wallix_rotate ALL=(ALL) NOPASSWD: /usr/bin/passwd *                |
     | wallix_rotate ALL=(ALL) NOPASSWD: /usr/sbin/chpasswd               |
     | wallix_rotate ALL=(ALL) NOPASSWD: /usr/bin/chage *                 |
     +--------------------------------------------------------------------+

  2. Verify syntax:
     $ sudo visudo -cf /etc/sudoers.d/wallix-rotation

     Expected output:
     +--------------------------------------------------------------------+
     | /etc/sudoers.d/wallix-rotation: parsed OK                          |
     +--------------------------------------------------------------------+

  --------------------------------------------------------------------------

  ISSUE: User not in sudoers
  ==========================

  Error Message:
  +------------------------------------------------------------------------+
  | wallix_rotate is not in the sudoers file. This incident will be reported.
  +------------------------------------------------------------------------+

  Resolution:

  1. Add rotation user to sudo group:
     $ sudo usermod -aG sudo wallix_rotate
     $ sudo usermod -aG wheel wallix_rotate   # RHEL/CentOS

  2. Or create dedicated sudoers file as shown above

  --------------------------------------------------------------------------

  ISSUE: Permission denied for /etc/shadow
  =========================================

  Error Message:
  +------------------------------------------------------------------------+
  | chpasswd: (user testuser) pam_chauthtok() failed                       |
  | error changing password for testuser                                   |
  +------------------------------------------------------------------------+

  Cause: chpasswd needs root privileges or specific PAM configuration

  Resolution:

  1. Ensure rotation runs as root or via sudo:
     Connector config: "Elevation: sudo"

  2. Check PAM configuration:
     $ sudo cat /etc/pam.d/chpasswd

+==============================================================================+
```

### PAM Module Errors

```
+==============================================================================+
|                   PAM MODULE ERRORS                                           |
+==============================================================================+

  ISSUE: PAM Authentication Error
  ================================

  Error Message:
  +------------------------------------------------------------------------+
  | passwd: Authentication token manipulation error                         |
  | passwd: password unchanged                                             |
  +------------------------------------------------------------------------+

  Diagnostic Steps:

  1. Check PAM configuration:
     $ cat /etc/pam.d/passwd
     $ cat /etc/pam.d/common-password   # Debian/Ubuntu
     $ cat /etc/pam.d/system-auth       # RHEL/CentOS

  2. Review authentication log:
     $ sudo tail -50 /var/log/auth.log      # Debian/Ubuntu
     $ sudo tail -50 /var/log/secure        # RHEL/CentOS

  3. Common PAM issues:
     * pam_cracklib rejecting password
     * pam_pwquality enforcing stricter policy
     * pam_unix password hash type mismatch

  --------------------------------------------------------------------------

  ISSUE: PAM Password Quality Check Failed
  =========================================

  Error Message:
  +------------------------------------------------------------------------+
  | BAD PASSWORD: The password fails the dictionary check                  |
  | BAD PASSWORD: The password is shorter than 8 characters                |
  | BAD PASSWORD: The password contains less than 3 character classes      |
  +------------------------------------------------------------------------+

  Resolution:

  1. Check pam_pwquality/pam_cracklib settings:
     $ grep -E "pam_pwquality|pam_cracklib" /etc/pam.d/*

  2. Review pwquality configuration:
     $ cat /etc/security/pwquality.conf

     Sample output:
     +--------------------------------------------------------------------+
     | minlen = 12                                                        |
     | dcredit = -1                                                       |
     | ucredit = -1                                                       |
     | lcredit = -1                                                       |
     | ocredit = -1                                                       |
     +--------------------------------------------------------------------+

  3. Align WALLIX password policy:
     Match or exceed target requirements in WALLIX password policy

  --------------------------------------------------------------------------

  ISSUE: Password in history
  ==========================

  Error Message:
  +------------------------------------------------------------------------+
  | passwd: Have exhausted maximum number of retries for service           |
  | Password has been already used. Choose another.                        |
  +------------------------------------------------------------------------+

  Cause: pam_unix or pam_pwhistory remembering old passwords

  Resolution:

  1. Check password history setting:
     $ grep remember /etc/pam.d/*

     Example:
     +--------------------------------------------------------------------+
     | password sufficient pam_unix.so remember=12 use_authtok            |
     +--------------------------------------------------------------------+

  2. Align WALLIX password history:
     Password Policy > History > "remember_count" >= target setting

+==============================================================================+
```

### Password Complexity Rejections

```
+==============================================================================+
|                   PASSWORD COMPLEXITY REJECTIONS                              |
+==============================================================================+

  Troubleshooting Password Policy Mismatches
  ==========================================

  Step 1: Identify target password requirements

  Linux (pwquality):
  +------------------------------------------------------------------------+
  | $ cat /etc/security/pwquality.conf                                     |
  | $ grep -E "minlen|dcredit|ucredit|lcredit|ocredit" /etc/pam.d/*       |
  +------------------------------------------------------------------------+

  Step 2: Compare with WALLIX policy

  +------------------------------------------------------------------------+
  | $ wabadmin policy show <policy-name>                                   |
  |                                                                        |
  | Password Policy: linux-servers                                         |
  | --------------------------------                                       |
  | Minimum Length: 14                                                     |
  | Uppercase Required: 1                                                  |
  | Lowercase Required: 1                                                  |
  | Digits Required: 1                                                     |
  | Special Characters Required: 1                                         |
  | Allowed Special: !@#$%^&*()_+-=[]{}|;:,.<>?                           |
  +------------------------------------------------------------------------+

  Step 3: Adjust WALLIX policy to meet or exceed target

  +------------------------------------------------------------------------+
  | Common Adjustments:                                                    |
  | * Increase minimum length if target requires more                      |
  | * Add required character classes                                       |
  | * Remove special characters not allowed by target                      |
  | * Increase password history retention                                  |
  +------------------------------------------------------------------------+

  Step 4: Test password generation

  $ wabadmin policy test-generate <policy-name> --count 10

  Sample output:
  +------------------------------------------------------------------------+
  | Generated passwords:                                                   |
  | 1. Kj8#mNp2$Qw5!vXz                                                   |
  | 2. Yt4@hBn7%Lm3*Cv                                                    |
  | ...                                                                    |
  | All passwords meet policy requirements.                                |
  +------------------------------------------------------------------------+

+==============================================================================+
```

---

## Windows Rotation Issues

### WinRM Connection Failures

```
+==============================================================================+
|                   WINRM CONNECTION FAILURES                                   |
+==============================================================================+

  ISSUE: WinRM Connection Refused
  ================================

  Error Message:
  +------------------------------------------------------------------------+
  | WinRM cannot complete the operation. Verify that the specified         |
  | computer name is valid, that the computer is accessible over the       |
  | network, and that a firewall exception for the WinRM service is enabled|
  +------------------------------------------------------------------------+

  Diagnostic Steps:

  1. Test WinRM connectivity from Bastion:
     $ curl -v -k https://10.10.2.50:5986/wsman

     Or for HTTP:
     $ curl -v http://10.10.2.50:5985/wsman

  2. Verify WinRM is running on target (PowerShell):
     +--------------------------------------------------------------------+
     | PS> Get-Service WinRM | Select Status, StartType                   |
     | PS> winrm enumerate winrm/config/listener                          |
     +--------------------------------------------------------------------+

  3. Enable WinRM if needed:
     +--------------------------------------------------------------------+
     | PS> Enable-PSRemoting -Force                                       |
     | PS> Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*"       |
     | PS> Restart-Service WinRM                                          |
     +--------------------------------------------------------------------+

  4. Configure HTTPS listener:
     +--------------------------------------------------------------------+
     | PS> $cert = New-SelfSignedCertificate -DnsName "server.domain.com" |
     |     -CertStoreLocation Cert:\LocalMachine\My                       |
     | PS> winrm create winrm/config/Listener?Address=*+Transport=HTTPS   |
     |     @{Hostname="server";CertificateThumbprint="$($cert.Thumbprint)"}
     +--------------------------------------------------------------------+

  --------------------------------------------------------------------------

  ISSUE: WinRM Authentication Error
  ==================================

  Error Message:
  +------------------------------------------------------------------------+
  | WinRM cannot process the request. The following error with errorcode   |
  | 0x8009030e occurred while using Negotiate authentication: A specified  |
  | logon session does not exist.                                          |
  +------------------------------------------------------------------------+

  Common Causes:
  * CredSSP required but not configured
  * Kerberos ticket issues
  * NTLM disabled on target

  Resolution:

  1. Check authentication settings:
     +--------------------------------------------------------------------+
     | PS> winrm get winrm/config/service/auth                            |
     |                                                                    |
     | Auth                                                               |
     |     Basic = true                                                   |
     |     Kerberos = true                                                |
     |     Negotiate = true                                               |
     |     Certificate = false                                            |
     |     CredSSP = false                                                |
     +--------------------------------------------------------------------+

  2. Enable Basic auth (for testing only):
     +--------------------------------------------------------------------+
     | PS> Set-Item WSMan:\localhost\Service\Auth\Basic -Value $true      |
     +--------------------------------------------------------------------+

  3. For domain accounts, ensure Kerberos is working:
     +--------------------------------------------------------------------+
     | PS> klist                                                          |
     | PS> Test-WSMan -ComputerName server.domain.com -Authentication Kerberos
     +--------------------------------------------------------------------+

  --------------------------------------------------------------------------

  ISSUE: WinRM Timeout
  ====================

  Error Message:
  +------------------------------------------------------------------------+
  | The WinRM client sent a request to an HTTP server and got a response   |
  | that said the requested resource was not available within the timeout. |
  +------------------------------------------------------------------------+

  Resolution:

  1. Increase timeout in WALLIX connector:
     Connection Timeout: 120 seconds
     Operation Timeout: 300 seconds

  2. Check network latency:
     $ ping 10.10.2.50

  3. Verify Windows not overloaded:
     Check CPU, memory, pending updates

  --------------------------------------------------------------------------

  ISSUE: SSL Certificate Error
  ============================

  Error Message:
  +------------------------------------------------------------------------+
  | The SSL certificate contains a common name (CN) that does not match    |
  | the hostname.                                                          |
  +------------------------------------------------------------------------+

  Resolution:

  1. Use IP-based certificate or fix hostname:
     +--------------------------------------------------------------------+
     | PS> $cert = New-SelfSignedCertificate -DnsName "10.10.2.50",       |
     |     "server.domain.com" -CertStoreLocation Cert:\LocalMachine\My   |
     +--------------------------------------------------------------------+

  2. Configure WALLIX to skip certificate validation:
     Connector > SSL Verification: Disabled
     (Not recommended for production)

  3. Import target certificate to WALLIX trust store:
     $ wabadmin certificate import --file target-cert.pem --trust

+==============================================================================+
```

### Kerberos Errors

```
+==============================================================================+
|                   KERBEROS ERRORS                                             |
+==============================================================================+

  ISSUE: KDC_ERR_PREAUTH_FAILED
  =============================

  Error Message:
  +------------------------------------------------------------------------+
  | Kerberos preauthentication failed                                      |
  | KDC_ERR_PREAUTH_FAILED: Pre-authentication information was invalid     |
  +------------------------------------------------------------------------+

  Common Causes:
  * Incorrect password
  * Time synchronization issue
  * Account locked in AD

  Resolution:

  1. Verify password is correct

  2. Check time synchronization:
     $ date                                  # On WALLIX
     $ w32tm /query /status                  # On Windows

     Time difference should be < 5 minutes

  3. Sync time if needed:
     $ sudo ntpdate -u dc.domain.com

  --------------------------------------------------------------------------

  ISSUE: KDC_ERR_C_PRINCIPAL_UNKNOWN
  ===================================

  Error Message:
  +------------------------------------------------------------------------+
  | Client 'wallix_svc@DOMAIN.COM' not found in Kerberos database          |
  +------------------------------------------------------------------------+

  Resolution:

  1. Verify account exists in AD:
     +--------------------------------------------------------------------+
     | PS> Get-ADUser -Identity wallix_svc                                |
     +--------------------------------------------------------------------+

  2. Check UPN is correct:
     +--------------------------------------------------------------------+
     | PS> Get-ADUser wallix_svc -Properties UserPrincipalName            |
     +--------------------------------------------------------------------+

  3. Verify realm configuration in WALLIX:
     $ cat /etc/krb5.conf

  --------------------------------------------------------------------------

  ISSUE: KDC_ERR_S_PRINCIPAL_UNKNOWN
  ===================================

  Error Message:
  +------------------------------------------------------------------------+
  | Server not found in Kerberos database                                  |
  +------------------------------------------------------------------------+

  Resolution:

  1. Verify SPN is registered:
     +--------------------------------------------------------------------+
     | PS> setspn -L servername                                           |
     +--------------------------------------------------------------------+

  2. Register SPN if missing:
     +--------------------------------------------------------------------+
     | PS> setspn -A HTTP/server.domain.com server$                       |
     | PS> setspn -A WSMAN/server.domain.com server$                      |
     +--------------------------------------------------------------------+

  --------------------------------------------------------------------------

  ISSUE: Clock Skew Too Great
  ===========================

  Error Message:
  +------------------------------------------------------------------------+
  | KRB5KRB_AP_ERR_SKEW: Clock skew too great                              |
  +------------------------------------------------------------------------+

  Resolution:

  1. Check time difference:
     $ date && ssh admin@dc.domain.com "date"

  2. Configure NTP on WALLIX:
     $ sudo systemctl enable chronyd
     $ sudo chronyc sources

  3. Force time sync:
     $ sudo chronyc makestep

+==============================================================================+
```

### Domain Controller Issues

```
+==============================================================================+
|                   DOMAIN CONTROLLER ISSUES                                    |
+==============================================================================+

  ISSUE: Cannot Connect to Domain Controller
  ===========================================

  Diagnostic Steps:

  1. Test LDAP connectivity:
     $ ldapsearch -x -H ldap://dc.domain.com -D "CN=bind,OU=Service,DC=domain,DC=com" \
       -W -b "DC=domain,DC=com" "(sAMAccountName=testuser)"

  2. Test LDAPS connectivity:
     $ openssl s_client -connect dc.domain.com:636 </dev/null

  3. Verify DNS resolution:
     $ nslookup _ldap._tcp.domain.com
     $ nslookup _kerberos._tcp.domain.com

  --------------------------------------------------------------------------

  ISSUE: Insufficient Permissions to Reset Password
  ==================================================

  Error Message:
  +------------------------------------------------------------------------+
  | Access is denied. Insufficient permissions to reset password.          |
  +------------------------------------------------------------------------+

  Resolution:

  1. Delegate "Reset Password" right:

     In Active Directory Users and Computers:
     a. Right-click target OU > Delegate Control
     b. Add WALLIX service account
     c. Select "Reset user passwords and force password change"
     d. Complete wizard

  2. Verify delegation:
     +--------------------------------------------------------------------+
     | PS> Get-ADOrganizationalUnit -Identity "OU=Servers,DC=domain,DC=com" |
     |     -Properties nTSecurityDescriptor |                              |
     |     Select -ExpandProperty nTSecurityDescriptor |                   |
     |     Select -ExpandProperty Access |                                 |
     |     Where-Object {$_.IdentityReference -like "*wallix*"}            |
     +--------------------------------------------------------------------+

  3. Test reset manually:
     +--------------------------------------------------------------------+
     | PS> Set-ADAccountPassword -Identity testuser -Reset `              |
     |     -NewPassword (ConvertTo-SecureString "TestP@ss123" -AsPlainText -Force)
     +--------------------------------------------------------------------+

  --------------------------------------------------------------------------

  ISSUE: Password Does Not Meet Domain Policy
  ============================================

  Error Message:
  +------------------------------------------------------------------------+
  | The password does not meet the length, complexity, or history          |
  | requirement of the domain.                                             |
  +------------------------------------------------------------------------+

  Resolution:

  1. Check domain password policy:
     +--------------------------------------------------------------------+
     | PS> Get-ADDefaultDomainPasswordPolicy                              |
     |                                                                    |
     | ComplexityEnabled           : True                                 |
     | LockoutDuration             : 00:30:00                             |
     | LockoutObservationWindow    : 00:30:00                             |
     | LockoutThreshold            : 5                                    |
     | MaxPasswordAge              : 90.00:00:00                          |
     | MinPasswordAge              : 1.00:00:00                           |
     | MinPasswordLength           : 14                                   |
     | PasswordHistoryCount        : 24                                   |
     +--------------------------------------------------------------------+

  2. Check Fine-Grained Password Policy (if applicable):
     +--------------------------------------------------------------------+
     | PS> Get-ADFineGrainedPasswordPolicy -Filter * |                    |
     |     Select Name, Precedence, MinPasswordLength                     |
     +--------------------------------------------------------------------+

  3. Update WALLIX policy to match:
     Admin > Password Policies > [Policy] > Edit
     Match all domain requirements

+==============================================================================+
```

### Password Policy Conflicts

```
+==============================================================================+
|                   PASSWORD POLICY CONFLICTS                                   |
+==============================================================================+

  WALLIX vs Target Policy Comparison Table
  =========================================

  +------------------------------------------------------------------------+
  | Setting            | WALLIX Policy | Windows Policy | Action Required |
  +--------------------+---------------+----------------+-----------------+
  | Min Length         | 12            | 14             | Increase WALLIX |
  | Max Length         | 128           | 128            | OK              |
  | Complexity         | Enabled       | Enabled        | OK              |
  | History            | 12            | 24             | Increase WALLIX |
  | Min Age            | 0             | 1 day          | May need wait   |
  | Special Chars      | All           | Limited        | Restrict WALLIX |
  +--------------------+---------------+----------------+-----------------+

  Common Conflicts and Solutions:

  1. Minimum Password Age:
     Windows enforces waiting period between password changes

     Solution: Schedule rotations with sufficient interval

  2. Password History:
     Windows remembers more passwords than WALLIX generates unique

     Solution: Increase WALLIX history or reduce complexity temporarily

  3. Special Character Restrictions:
     Some Windows systems restrict certain special characters

     Solution: Configure WALLIX allowed_characters to match:
     +--------------------------------------------------------------------+
     | "special_characters": "!@#$%^&*()_+-=[]{}|;:,.<>?"                 |
     | Remove: \ / " '  (characters that may cause issues)                |
     +--------------------------------------------------------------------+

+==============================================================================+
```

---

## Network Device Rotation Issues

### Cisco Specific Errors

```
+==============================================================================+
|                   CISCO IOS/IOS-XE ROTATION ISSUES                            |
+==============================================================================+

  ISSUE: Enable Mode Failure
  ==========================

  Error Message:
  +------------------------------------------------------------------------+
  | % Error in authentication.                                             |
  | % Bad secrets                                                          |
  +------------------------------------------------------------------------+

  Diagnostic Steps:

  1. Verify enable password is stored correctly:
     $ wabadmin account show cisco-switch/admin --show-enable-password

  2. Test manually:
     $ ssh admin@cisco-switch
     cisco-switch> enable
     Password: [enter enable password]

  3. Check enable configuration on device:
     +--------------------------------------------------------------------+
     | cisco-switch# show running-config | include enable                 |
     | enable secret 5 $1$xxxx$xxxxxxxxxxxxxxxxxxxxxxx                    |
     +--------------------------------------------------------------------+

  --------------------------------------------------------------------------

  ISSUE: Username Not Recognized
  ==============================

  Error Message:
  +------------------------------------------------------------------------+
  | % Login invalid                                                        |
  +------------------------------------------------------------------------+

  Resolution:

  1. Check AAA configuration:
     +--------------------------------------------------------------------+
     | cisco-switch# show aaa authentication login                        |
     | cisco-switch# show running-config | section aaa                    |
     +--------------------------------------------------------------------+

  2. Verify local user exists:
     +--------------------------------------------------------------------+
     | cisco-switch# show running-config | include username               |
     | username admin privilege 15 secret 5 $1$xxxx$xxxx                  |
     +--------------------------------------------------------------------+

  3. If using TACACS/RADIUS, check server connectivity

  --------------------------------------------------------------------------

  ISSUE: Password Change Command Failed
  =====================================

  Error Message:
  +------------------------------------------------------------------------+
  | % Invalid input detected at '^' marker.                                |
  +------------------------------------------------------------------------+

  Cause: Wrong command for IOS version or user type

  Cisco IOS Password Change Commands:
  +------------------------------------------------------------------------+
  | # For local users:                                                     |
  | configure terminal                                                     |
  | username admin privilege 15 secret NewPassword123!                     |
  | end                                                                    |
  | write memory                                                           |
  |                                                                        |
  | # For enable password:                                                 |
  | configure terminal                                                     |
  | enable secret NewEnablePass123!                                        |
  | end                                                                    |
  | write memory                                                           |
  +------------------------------------------------------------------------+

  Resolution:
  1. Verify connector uses correct command template
  2. Check IOS version compatibility
  3. Ensure user has configure terminal access

  --------------------------------------------------------------------------

  ISSUE: Configuration Not Saved
  ==============================

  Symptom: Password works after rotation but fails after device reboot

  Cause: "write memory" or "copy running-config startup-config" not executed

  Resolution:

  Ensure connector template includes save:
  +------------------------------------------------------------------------+
  | configure terminal                                                     |
  | username {username} privilege 15 secret {password}                     |
  | end                                                                    |
  | write memory                                                           |
  | exit                                                                   |
  +------------------------------------------------------------------------+

+==============================================================================+
```

### Juniper Specific Errors

```
+==============================================================================+
|                   JUNIPER JUNOS ROTATION ISSUES                               |
+==============================================================================+

  ISSUE: Configuration Commit Failed
  ===================================

  Error Message:
  +------------------------------------------------------------------------+
  | error: configuration check-out failed                                  |
  | error: could not lock configuration database                           |
  +------------------------------------------------------------------------+

  Cause: Another user has exclusive configuration lock

  Resolution:

  1. Check who has the lock:
     +--------------------------------------------------------------------+
     | user@juniper> show system commit                                   |
     | user@juniper> show system users                                    |
     +--------------------------------------------------------------------+

  2. Clear lock (if authorized):
     +--------------------------------------------------------------------+
     | user@juniper> clear system commit                                  |
     | user@juniper> request system logout user other-user                |
     +--------------------------------------------------------------------+

  --------------------------------------------------------------------------

  ISSUE: Password Rejected by Policy
  ===================================

  Error Message:
  +------------------------------------------------------------------------+
  | error: password does not meet minimum requirements                     |
  +------------------------------------------------------------------------+

  Resolution:

  1. Check JunOS password requirements:
     +--------------------------------------------------------------------+
     | user@juniper> show configuration system login password             |
     |                                                                    |
     | minimum-length 12;                                                 |
     | minimum-changes 4;                                                 |
     | minimum-character-changes 6;                                       |
     +--------------------------------------------------------------------+

  2. Adjust WALLIX policy to match

  --------------------------------------------------------------------------

  JunOS Password Change Commands:
  +------------------------------------------------------------------------+
  | configure                                                              |
  | set system login user {username} authentication plain-text-password   |
  | # (interactive prompt for password)                                   |
  | commit                                                                 |
  | exit                                                                   |
  +------------------------------------------------------------------------+

+==============================================================================+
```

### Palo Alto Specific Errors

```
+==============================================================================+
|                   PALO ALTO ROTATION ISSUES                                   |
+==============================================================================+

  ISSUE: API Authentication Failed
  =================================

  Error Message:
  +------------------------------------------------------------------------+
  | <response status="error">                                              |
  |   <msg>Invalid credentials.</msg>                                      |
  | </response>                                                            |
  +------------------------------------------------------------------------+

  Resolution:

  1. Verify API key is valid:
     +--------------------------------------------------------------------+
     | $ curl -k "https://firewall/api/?type=keygen&user=admin&password=xxx"
     +--------------------------------------------------------------------+

  2. Check admin role has API access:
     +--------------------------------------------------------------------+
     | Device > Administrators > [admin] > Administrator Type             |
     | Ensure "Enable API access" is checked                              |
     +--------------------------------------------------------------------+

  --------------------------------------------------------------------------

  ISSUE: Commit Failed
  ====================

  Error Message:
  +------------------------------------------------------------------------+
  | <response status="error">                                              |
  |   <msg>Configuration commit failed</msg>                               |
  | </response>                                                            |
  +------------------------------------------------------------------------+

  Resolution:

  1. Check for pending changes by other admins
  2. Verify configuration is valid
  3. Check if device is in maintenance mode

  --------------------------------------------------------------------------

  PAN-OS Password Change (CLI):
  +------------------------------------------------------------------------+
  | configure                                                              |
  | set mgt-config users {username} password                               |
  | # (interactive prompt)                                                 |
  | commit                                                                 |
  | exit                                                                   |
  +------------------------------------------------------------------------+

  PAN-OS Password Change (API):
  +------------------------------------------------------------------------+
  | POST /api/?type=config&action=set&                                     |
  |      xpath=/config/mgt-config/users/entry[@name='admin']              |
  |      &element=<phash>$1$xxxx$xxxx</phash>                              |
  +------------------------------------------------------------------------+

+==============================================================================+
```

### TACACS/RADIUS Conflicts

```
+==============================================================================+
|                   TACACS/RADIUS CONFLICTS                                     |
+==============================================================================+

  ISSUE: Password Changed Locally But TACACS User Unchanged
  ==========================================================

  Problem: Network device uses TACACS/RADIUS for authentication
           WALLIX rotated local password but users authenticate via TACACS

  Solution Options:

  1. Rotate password on TACACS/RADIUS server instead:
     Configure WALLIX to target TACACS/RADIUS server

  2. If device has fallback local auth:
     Ensure local user is only for emergency/break-glass
     Document that TACACS is primary auth

  3. Disable local authentication:
     +--------------------------------------------------------------------+
     | cisco-switch(config)# aaa authentication login default group tacacs+ none
     +--------------------------------------------------------------------+

  --------------------------------------------------------------------------

  ISSUE: TACACS Server Rejecting New Password
  ============================================

  Resolution:

  1. Verify TACACS server allows password changes:
     Check TACACS server configuration

  2. If Cisco ISE:
     +--------------------------------------------------------------------+
     | Administration > Identity Management > Users                        |
     | Verify user password policy allows WALLIX-generated passwords       |
     +--------------------------------------------------------------------+

+==============================================================================+
```

---

## Database Account Rotation

### PostgreSQL Errors

```
+==============================================================================+
|                   POSTGRESQL ROTATION ISSUES                                  |
+==============================================================================+

  ISSUE: Connection Refused
  =========================

  Error Message:
  +------------------------------------------------------------------------+
  | psql: error: could not connect to server: Connection refused           |
  | Is the server running on host "10.10.3.50" and accepting               |
  | TCP/IP connections on port 5432?                                       |
  +------------------------------------------------------------------------+

  Resolution:

  1. Check PostgreSQL is listening on network:
     +--------------------------------------------------------------------+
     | $ grep listen_addresses /etc/postgresql/15/main/postgresql.conf    |
     | listen_addresses = '*'  # or specific IP                           |
     +--------------------------------------------------------------------+

  2. Check pg_hba.conf allows connection:
     +--------------------------------------------------------------------+
     | host    all    wallix_rotate    10.10.1.0/24    scram-sha-256      |
     +--------------------------------------------------------------------+

  --------------------------------------------------------------------------

  ISSUE: Password Authentication Failed
  =====================================

  Error Message:
  +------------------------------------------------------------------------+
  | FATAL: password authentication failed for user "wallix_rotate"         |
  +------------------------------------------------------------------------+

  Resolution:

  1. Verify current password:
     $ PGPASSWORD='current_password' psql -h target -U wallix_rotate -c "SELECT 1"

  2. If password mismatch, reconcile:
     $ wabadmin password reconcile postgres-server/wallix_rotate

  --------------------------------------------------------------------------

  ISSUE: Insufficient Privileges
  ==============================

  Error Message:
  +------------------------------------------------------------------------+
  | ERROR: must be superuser to alter users                                |
  | ERROR: permission denied to alter user                                 |
  +------------------------------------------------------------------------+

  Resolution:

  PostgreSQL requires superuser or specific grants to change passwords:

  Option 1: Grant CREATEROLE privilege:
  +------------------------------------------------------------------------+
  | ALTER USER wallix_rotate WITH CREATEROLE;                              |
  +------------------------------------------------------------------------+

  Option 2: Grant password change via function (more secure):
  +------------------------------------------------------------------------+
  | CREATE OR REPLACE FUNCTION change_password(username text, newpass text)|
  | RETURNS void AS $$                                                     |
  | BEGIN                                                                  |
  |   EXECUTE format('ALTER USER %I PASSWORD %L', username, newpass);      |
  | END;                                                                   |
  | $$ LANGUAGE plpgsql SECURITY DEFINER;                                  |
  |                                                                        |
  | GRANT EXECUTE ON FUNCTION change_password TO wallix_rotate;            |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  PostgreSQL Password Change Command:
  +------------------------------------------------------------------------+
  | ALTER USER {username} WITH PASSWORD '{new_password}';                  |
  +------------------------------------------------------------------------+

+==============================================================================+
```

### MySQL Errors

```
+==============================================================================+
|                   MYSQL/MARIADB ROTATION ISSUES                               |
+==============================================================================+

  ISSUE: Access Denied
  ====================

  Error Message:
  +------------------------------------------------------------------------+
  | ERROR 1045 (28000): Access denied for user 'wallix_rotate'@'10.10.1.5' |
  | (using password: YES)                                                  |
  +------------------------------------------------------------------------+

  Resolution:

  1. Verify user exists with correct host:
     +--------------------------------------------------------------------+
     | SELECT user, host FROM mysql.user WHERE user = 'wallix_rotate';    |
     +--------------------------------------------------------------------+

  2. Grant access from WALLIX IP:
     +--------------------------------------------------------------------+
     | CREATE USER 'wallix_rotate'@'10.10.1.5' IDENTIFIED BY 'password';  |
     | GRANT ALL ON *.* TO 'wallix_rotate'@'10.10.1.5' WITH GRANT OPTION; |
     +--------------------------------------------------------------------+

  --------------------------------------------------------------------------

  ISSUE: Password Does Not Meet Policy
  =====================================

  Error Message:
  +------------------------------------------------------------------------+
  | ERROR 1819 (HY000): Your password does not satisfy the current policy |
  | requirements                                                           |
  +------------------------------------------------------------------------+

  Resolution:

  1. Check MySQL password policy:
     +--------------------------------------------------------------------+
     | SHOW VARIABLES LIKE 'validate_password%';                          |
     |                                                                    |
     | +--------------------------------------+--------+                   |
     | | Variable_name                        | Value  |                  |
     | +--------------------------------------+--------+                   |
     | | validate_password.check_user_name    | ON     |                  |
     | | validate_password.length             | 8      |                  |
     | | validate_password.mixed_case_count   | 1      |                  |
     | | validate_password.number_count       | 1      |                  |
     | | validate_password.policy             | MEDIUM |                  |
     | | validate_password.special_char_count | 1      |                  |
     +--------------------------------------------------------------------+

  2. Align WALLIX policy accordingly

  --------------------------------------------------------------------------

  MySQL Password Change Commands:
  +------------------------------------------------------------------------+
  | # MySQL 5.7+                                                           |
  | ALTER USER '{username}'@'{host}' IDENTIFIED BY '{new_password}';       |
  | FLUSH PRIVILEGES;                                                      |
  |                                                                        |
  | # MariaDB                                                              |
  | SET PASSWORD FOR '{username}'@'{host}' = PASSWORD('{new_password}');   |
  | FLUSH PRIVILEGES;                                                      |
  +------------------------------------------------------------------------+

+==============================================================================+
```

### Oracle Errors

```
+==============================================================================+
|                   ORACLE DATABASE ROTATION ISSUES                             |
+==============================================================================+

  ISSUE: ORA-01017 Invalid Username/Password
  ==========================================

  Error Message:
  +------------------------------------------------------------------------+
  | ORA-01017: invalid username/password; logon denied                     |
  +------------------------------------------------------------------------+

  Resolution:

  1. Verify case sensitivity (Oracle 11g+ has case-sensitive passwords):
     +--------------------------------------------------------------------+
     | SELECT VALUE FROM V$PARAMETER WHERE NAME='sec_case_sensitive_logon';
     +--------------------------------------------------------------------+

  2. Check account status:
     +--------------------------------------------------------------------+
     | SELECT username, account_status FROM dba_users                     |
     | WHERE username = 'WALLIX_ROTATE';                                  |
     +--------------------------------------------------------------------+

  --------------------------------------------------------------------------

  ISSUE: ORA-28001 Password Expired
  ==================================

  Error Message:
  +------------------------------------------------------------------------+
  | ORA-28001: the password has expired                                    |
  +------------------------------------------------------------------------+

  Resolution:

  1. Unlock and unexpire:
     +--------------------------------------------------------------------+
     | ALTER USER wallix_rotate IDENTIFIED BY new_password ACCOUNT UNLOCK; |
     +--------------------------------------------------------------------+

  2. Set profile to prevent expiration for service accounts:
     +--------------------------------------------------------------------+
     | CREATE PROFILE svc_profile LIMIT PASSWORD_LIFE_TIME UNLIMITED;     |
     | ALTER USER wallix_rotate PROFILE svc_profile;                      |
     +--------------------------------------------------------------------+

  --------------------------------------------------------------------------

  ISSUE: ORA-28003 Password Verification Failed
  ==============================================

  Error Message:
  +------------------------------------------------------------------------+
  | ORA-28003: password verification for the specified password failed     |
  +------------------------------------------------------------------------+

  Resolution:

  1. Check password verify function:
     +--------------------------------------------------------------------+
     | SELECT LIMIT FROM dba_profiles                                     |
     | WHERE profile='DEFAULT' AND resource_name='PASSWORD_VERIFY_FUNCTION';
     +--------------------------------------------------------------------+

  2. Review password function requirements:
     +--------------------------------------------------------------------+
     | SELECT text FROM dba_source                                        |
     | WHERE name = 'VERIFY_FUNCTION_11G' ORDER BY line;                  |
     +--------------------------------------------------------------------+

  --------------------------------------------------------------------------

  Oracle Password Change Command:
  +------------------------------------------------------------------------+
  | ALTER USER {username} IDENTIFIED BY "{new_password}";                  |
  +------------------------------------------------------------------------+

  Note: Quotes required if password contains special characters

+==============================================================================+
```

---

## SSH Key Rotation Issues

### Key Deployment Failures

```
+==============================================================================+
|                   SSH KEY ROTATION ISSUES                                     |
+==============================================================================+

  SSH KEY ROTATION WORKFLOW
  =========================

  +------------------------------------------------------------------------+
  | 1. Generate new key pair on WALLIX                                     |
  |    |                                                                   |
  |    v                                                                   |
  | 2. Connect to target using current key                                 |
  |    |                                                                   |
  |    v                                                                   |
  | 3. Add new public key to authorized_keys                               |
  |    |                                                                   |
  |    v                                                                   |
  | 4. Verify new key works                                                |
  |    |                                                                   |
  |    v                                                                   |
  | 5. Remove old public key from authorized_keys                          |
  |    |                                                                   |
  |    v                                                                   |
  | 6. Store new private key in vault                                      |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  ISSUE: Key Deployment Permission Denied
  ========================================

  Error Message:
  +------------------------------------------------------------------------+
  | Permission denied: ~/.ssh/authorized_keys                              |
  | Could not write to authorized_keys file                                |
  +------------------------------------------------------------------------+

  Diagnostic Steps:

  1. Check .ssh directory permissions:
     $ ls -la ~/.ssh/

     Expected:
     +--------------------------------------------------------------------+
     | drwx------  2 user user 4096 Jan 27 10:00 .                        |
     | -rw-------  1 user user  400 Jan 27 10:00 authorized_keys          |
     +--------------------------------------------------------------------+

  2. Fix permissions:
     $ chmod 700 ~/.ssh
     $ chmod 600 ~/.ssh/authorized_keys
     $ chown -R user:user ~/.ssh

  3. Check SELinux context (RHEL/CentOS):
     $ ls -Z ~/.ssh/authorized_keys
     $ restorecon -Rv ~/.ssh

  --------------------------------------------------------------------------

  ISSUE: Old Key Still Valid After Rotation
  ==========================================

  Cause: Old key not removed from authorized_keys

  Resolution:

  1. Verify rotation removed old key:
     $ cat ~/.ssh/authorized_keys | wc -l

     Should only have current key

  2. Manually remove old key if present:
     $ grep -v "old_key_fingerprint" ~/.ssh/authorized_keys > temp
     $ mv temp ~/.ssh/authorized_keys

  3. Configure connector to remove old keys:
     Connector > "Remove Previous Keys": Enabled

  --------------------------------------------------------------------------

  ISSUE: Key Type Not Supported
  =============================

  Error Message:
  +------------------------------------------------------------------------+
  | no matching key exchange method found                                  |
  | no matching host key type found                                        |
  +------------------------------------------------------------------------+

  Resolution:

  1. Check target SSH version:
     $ ssh -V   # on target

  2. Use compatible key type:

     Modern systems: Ed25519 (recommended)
     Older systems: RSA 4096
     Legacy systems: RSA 2048

  3. Configure WALLIX key generation:
     Password Policy > SSH Key > Type: rsa-4096 (for compatibility)

  --------------------------------------------------------------------------

  ISSUE: Key Verification Failed
  ==============================

  Error Message:
  +------------------------------------------------------------------------+
  | New key authentication failed during verification                      |
  +------------------------------------------------------------------------+

  Possible Causes:
  * authorized_keys file format error
  * Key not properly added
  * sshd config restricts key types

  Resolution:

  1. Check authorized_keys format:
     Each key should be on single line, starting with:
     ssh-ed25519, ssh-rsa, ecdsa-sha2-nistp256, etc.

  2. Check sshd_config:
     $ grep -E "PubkeyAcceptedKeyTypes|PubkeyAcceptedAlgorithms" /etc/ssh/sshd_config

  3. Test key manually:
     $ ssh -i /tmp/new_key user@target

+==============================================================================+
```

### Authorized Keys Permission Problems

```
+==============================================================================+
|                   AUTHORIZED_KEYS PERMISSIONS                                 |
+==============================================================================+

  REQUIRED PERMISSIONS
  ====================

  +------------------------------------------------------------------------+
  | Path                      | Permissions | Owner        | Notes         |
  +---------------------------+-------------+--------------+---------------+
  | /home/user                | 755 or 700  | user:user    | Home dir      |
  | /home/user/.ssh           | 700         | user:user    | SSH dir       |
  | /home/user/.ssh/authorized_keys | 600   | user:user    | Keys file     |
  +---------------------------+-------------+--------------+---------------+

  NOTE: SSH daemon is very strict about permissions and will refuse
        to use authorized_keys if permissions are too open.

  --------------------------------------------------------------------------

  DIAGNOSTIC SCRIPT
  =================

  Run on target to diagnose SSH key issues:

  +------------------------------------------------------------------------+
  | #!/bin/bash                                                            |
  | # ssh-permission-check.sh                                              |
  |                                                                        |
  | USER=$1                                                                |
  | HOME_DIR=$(getent passwd "$USER" | cut -d: -f6)                        |
  |                                                                        |
  | echo "Checking SSH permissions for $USER"                              |
  | echo "Home directory: $HOME_DIR"                                       |
  | echo "---"                                                             |
  |                                                                        |
  | # Check home directory                                                 |
  | perms=$(stat -c %a "$HOME_DIR" 2>/dev/null)                            |
  | owner=$(stat -c %U:%G "$HOME_DIR" 2>/dev/null)                         |
  | echo "Home dir: $perms (need 755 or 700), Owner: $owner (need $USER)"  |
  |                                                                        |
  | # Check .ssh directory                                                 |
  | if [ -d "$HOME_DIR/.ssh" ]; then                                       |
  |   perms=$(stat -c %a "$HOME_DIR/.ssh")                                 |
  |   owner=$(stat -c %U:%G "$HOME_DIR/.ssh")                              |
  |   echo ".ssh dir: $perms (need 700), Owner: $owner"                    |
  | else                                                                   |
  |   echo ".ssh directory MISSING"                                        |
  | fi                                                                     |
  |                                                                        |
  | # Check authorized_keys                                                |
  | if [ -f "$HOME_DIR/.ssh/authorized_keys" ]; then                       |
  |   perms=$(stat -c %a "$HOME_DIR/.ssh/authorized_keys")                 |
  |   owner=$(stat -c %U:%G "$HOME_DIR/.ssh/authorized_keys")              |
  |   echo "authorized_keys: $perms (need 600), Owner: $owner"             |
  |   echo "Key count: $(wc -l < "$HOME_DIR/.ssh/authorized_keys")"        |
  | else                                                                   |
  |   echo "authorized_keys file MISSING"                                  |
  | fi                                                                     |
  +------------------------------------------------------------------------+

  Usage: $ sudo ./ssh-permission-check.sh username

+==============================================================================+
```

---

## Connector Troubleshooting

### How to Test Connectors

```
+==============================================================================+
|                   CONNECTOR TESTING                                           |
+==============================================================================+

  LISTING AVAILABLE CONNECTORS
  ============================

  $ wabadmin connector list

  Output:
  +------------------------------------------------------------------------+
  | ID   | Name              | Type   | Status  | Version                  |
  +------+-------------------+--------+---------+--------------------------+
  | 1    | ssh-linux         | SSH    | Active  | 1.5.2                    |
  | 2    | winrm-local       | WinRM  | Active  | 1.4.0                    |
  | 3    | winrm-domain      | WinRM  | Active  | 1.4.0                    |
  | 4    | cisco-ios-ssh     | SSH    | Active  | 1.3.1                    |
  | 5    | oracle-sqlplus    | SQL    | Active  | 1.2.0                    |
  +------+-------------------+--------+---------+--------------------------+

  --------------------------------------------------------------------------

  TESTING A CONNECTOR
  ===================

  $ wabadmin connector test <connector-id> \
      --target <device-name> \
      --account <account-name> \
      --verbose

  Example:
  +------------------------------------------------------------------------+
  | $ wabadmin connector test ssh-linux --target srv-prod-01 \            |
  |     --account root --verbose                                           |
  |                                                                        |
  | Testing connector: ssh-linux                                           |
  | Target: srv-prod-01 (10.10.1.50:22)                                    |
  | Account: root                                                          |
  |                                                                        |
  | [1/5] Retrieving credentials from vault...    OK                       |
  | [2/5] Connecting to target...                 OK (0.3s)                |
  | [3/5] Authenticating...                       OK                       |
  | [4/5] Testing password change capability...   OK                       |
  | [5/5] Disconnecting...                        OK                       |
  |                                                                        |
  | Connector test PASSED                                                  |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  TEST-ROTATE (DRY RUN)
  =====================

  Test rotation without actually changing password:

  $ wabadmin password test-rotate <device>/<account> --dry-run --verbose

  Output:
  +------------------------------------------------------------------------+
  | Dry-run rotation for: srv-prod-01/root                                 |
  |                                                                        |
  | [1/7] Checking pre-conditions...              OK                       |
  |   - No active sessions                                                 |
  |   - Rotation account available                                         |
  |                                                                        |
  | [2/7] Generating new password...              OK                       |
  |   - Length: 20 characters                                              |
  |   - Complexity: Meets policy                                           |
  |   - History check: Not in last 12 passwords                            |
  |                                                                        |
  | [3/7] Connecting to target...                 OK (0.5s)                |
  |                                                                        |
  | [4/7] Would execute password change:                                   |
  |   Command: echo "root:XXXXXXXX" | chpasswd                             |
  |   [DRY-RUN: Not executed]                                              |
  |                                                                        |
  | [5/7] Would verify new password...            [SKIPPED]                |
  |                                                                        |
  | [6/7] Would update vault...                   [SKIPPED]                |
  |                                                                        |
  | [7/7] Disconnecting...                        OK                       |
  |                                                                        |
  | Dry-run rotation COMPLETED                                             |
  +------------------------------------------------------------------------+

+==============================================================================+
```

### Debug Mode and Logging

```
+==============================================================================+
|                   CONNECTOR DEBUG MODE                                        |
+==============================================================================+

  ENABLING DEBUG LOGGING
  ======================

  Temporary debug (runtime):
  +------------------------------------------------------------------------+
  | $ wabadmin log-level set --component password-manager --level DEBUG    |
  |                                                                        |
  | # Perform rotation                                                     |
  | $ wabadmin password rotate srv-prod-01/root                            |
  |                                                                        |
  | # Watch debug output                                                   |
  | $ tail -f /var/log/wab/wabpassword.log                                 |
  |                                                                        |
  | # Reset log level                                                      |
  | $ wabadmin log-level set --component password-manager --level INFO     |
  +------------------------------------------------------------------------+

  Permanent debug (configuration):
  +------------------------------------------------------------------------+
  | Edit /etc/wallix/wabpassword.conf:                                     |
  |                                                                        |
  | [logging]                                                              |
  | level = DEBUG                                                          |
  | connector_debug = true                                                 |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  DEBUG LOG EXAMPLE
  =================

  +------------------------------------------------------------------------+
  | 2024-01-27 02:00:00.001 DEBUG [password-manager] Starting rotation     |
  |   device=srv-prod-01 account=root trigger=scheduled                    |
  |                                                                        |
  | 2024-01-27 02:00:00.005 DEBUG [password-manager] Pre-conditions check  |
  |   active_sessions=0 rotation_account=wallix_rotate                     |
  |                                                                        |
  | 2024-01-27 02:00:00.010 DEBUG [password-manager] Password generation   |
  |   policy=linux-servers length=20 complexity=high                       |
  |                                                                        |
  | 2024-01-27 02:00:00.015 DEBUG [connector:ssh-linux] Connecting         |
  |   host=10.10.1.50 port=22 user=wallix_rotate timeout=30                |
  |                                                                        |
  | 2024-01-27 02:00:00.350 DEBUG [connector:ssh-linux] Connected          |
  |   ssh_version=OpenSSH_8.4 key_exchange=curve25519-sha256               |
  |                                                                        |
  | 2024-01-27 02:00:00.400 DEBUG [connector:ssh-linux] Executing          |
  |   command="sudo chpasswd" input="root:***"                             |
  |                                                                        |
  | 2024-01-27 02:00:00.550 DEBUG [connector:ssh-linux] Response           |
  |   exit_code=0 output=""                                                |
  |                                                                        |
  | 2024-01-27 02:00:00.555 DEBUG [password-manager] Verification          |
  |   method=ssh_login user=root                                           |
  |                                                                        |
  | 2024-01-27 02:00:00.850 DEBUG [password-manager] Verification OK       |
  |                                                                        |
  | 2024-01-27 02:00:00.860 DEBUG [password-manager] Vault update          |
  |   account_id=srv-prod-01/root encryption=AES-256-GCM                   |
  |                                                                        |
  | 2024-01-27 02:00:00.900 INFO  [password-manager] Rotation complete     |
  |   device=srv-prod-01 account=root status=SUCCESS duration=899ms        |
  +------------------------------------------------------------------------+

+==============================================================================+
```

### Connector Timeout Tuning

```
+==============================================================================+
|                   CONNECTOR TIMEOUT CONFIGURATION                             |
+==============================================================================+

  TIMEOUT SETTINGS
  ================

  +------------------------------------------------------------------------+
  | Timeout Type        | Default | Description                            |
  +---------------------+---------+----------------------------------------+
  | connection_timeout  | 30s     | Time to establish connection           |
  | operation_timeout   | 60s     | Time for password change operation     |
  | verification_timeout| 30s     | Time to verify new password            |
  | total_timeout       | 180s    | Maximum total rotation time            |
  +---------------------+---------+----------------------------------------+

  --------------------------------------------------------------------------

  ADJUSTING TIMEOUTS
  ==================

  Per-connector configuration:
  +------------------------------------------------------------------------+
  | $ wabadmin connector configure ssh-linux \                             |
  |     --connection-timeout 60 \                                          |
  |     --operation-timeout 120 \                                          |
  |     --verification-timeout 60                                          |
  +------------------------------------------------------------------------+

  Per-device override:
  +------------------------------------------------------------------------+
  | Admin > Devices > [device] > Rotation Settings                         |
  | Connection Timeout: 60 seconds                                         |
  | Operation Timeout: 120 seconds                                         |
  +------------------------------------------------------------------------+

  Global configuration (/etc/wallix/wabpassword.conf):
  +------------------------------------------------------------------------+
  | [timeouts]                                                             |
  | connection = 60                                                        |
  | operation = 120                                                        |
  | verification = 60                                                      |
  | total = 300                                                            |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  RECOMMENDED SETTINGS BY NETWORK TYPE
  =====================================

  +------------------------------------------------------------------------+
  | Network Type         | Connection | Operation | Verification          |
  +----------------------+------------+-----------+------------------------+
  | Local (LAN)          | 30s        | 60s       | 30s                    |
  | WAN (same region)    | 45s        | 90s       | 45s                    |
  | WAN (cross-region)   | 60s        | 120s      | 60s                    |
  | VPN/Tunnel           | 90s        | 180s      | 90s                    |
  | High-latency/OT      | 120s       | 300s      | 120s                   |
  +----------------------+------------+-----------+------------------------+

+==============================================================================+
```

---

## Reconciliation Procedures

### When to Reconcile

```
+==============================================================================+
|                   WHEN TO RECONCILE                                           |
+==============================================================================+

  RECONCILIATION TRIGGERS
  =======================

  Automatic reconciliation should occur when:

  1. Password rotation verification fails (WAB-4002)
  2. Session authentication fails after successful rotation
  3. Manual password change detected on target
  4. Account recovery from backup
  5. Initial onboarding of existing accounts

  +------------------------------------------------------------------------+
  | RECONCILIATION DECISION TREE                                           |
  |                                                                        |
  | Session/Rotation Failed?                                               |
  |   |                                                                    |
  |   +-- No --> Normal operation                                          |
  |   |                                                                    |
  |   +-- Yes --> Is vault password current on target?                     |
  |                |                                                       |
  |                +-- Unknown --> Test vault password manually            |
  |                |    |                                                  |
  |                |    +-- Works --> Mark account as healthy              |
  |                |    |                                                  |
  |                |    +-- Fails --> Need reconciliation                  |
  |                |                                                       |
  |                +-- Yes --> Investigate other causes                    |
  |                |                                                       |
  |                +-- No --> Need reconciliation                          |
  +------------------------------------------------------------------------+

+==============================================================================+
```

### Manual Reconciliation Steps

```
+==============================================================================+
|                   MANUAL RECONCILIATION PROCEDURE                             |
+==============================================================================+

  STEP 1: VERIFY CURRENT STATE
  ============================

  Check what password WALLIX thinks is current:
  +------------------------------------------------------------------------+
  | $ wabadmin account show srv-prod-01/root --show-password               |
  |                                                                        |
  | Account: srv-prod-01/root                                              |
  | Status: ERROR (verification failed)                                    |
  | Last Rotation: 2024-01-27 02:00:00                                     |
  | Password: Kj8#mNp2$Qw5!vXzY9                                           |
  | Last Verified: 2024-01-26 02:00:00                                     |
  +------------------------------------------------------------------------+

  Test if this password works on target:
  +------------------------------------------------------------------------+
  | $ ssh root@srv-prod-01                                                 |
  | Password: [enter password from above]                                  |
  |                                                                        |
  | If fails: Need reconciliation                                          |
  | If works: Mark as verified (no reconciliation needed)                  |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  STEP 2: OBTAIN CURRENT TARGET PASSWORD
  ======================================

  Options to get the actual password on target:

  Option A: Use break-glass account
  +------------------------------------------------------------------------+
  | $ ssh breakglass@srv-prod-01                                           |
  | $ sudo cat /etc/shadow | grep root                                     |
  |                                                                        |
  | Note: This shows hash, not password. Need to know or reset password.   |
  +------------------------------------------------------------------------+

  Option B: Use reconciliation account
  +------------------------------------------------------------------------+
  | $ ssh wallix_recon@srv-prod-01                                         |
  | $ sudo passwd root                                                     |
  | New password: [set known password]                                     |
  +------------------------------------------------------------------------+

  Option C: Console/IPMI access
  Boot to single user mode and reset password

  --------------------------------------------------------------------------

  STEP 3: RECONCILE IN WALLIX
  ===========================

  Method A: Via CLI
  +------------------------------------------------------------------------+
  | $ wabadmin password reconcile srv-prod-01/root                         |
  |                                                                        |
  | Enter current target password: ********                                |
  | Verifying password on target... OK                                     |
  | Updating vault... OK                                                   |
  | Reconciliation complete.                                               |
  |                                                                        |
  | # Optional: Trigger immediate rotation after reconcile                 |
  | $ wabadmin password rotate srv-prod-01/root                            |
  +------------------------------------------------------------------------+

  Method B: Via API
  +------------------------------------------------------------------------+
  | POST /api/v1/accounts/srv-prod-01/root/reconcile                       |
  | {                                                                      |
  |   "current_password": "the_actual_target_password"                     |
  | }                                                                      |
  +------------------------------------------------------------------------+

  Method C: Via Admin UI
  +------------------------------------------------------------------------+
  | Admin > Devices > srv-prod-01 > Accounts > root > Actions > Reconcile  |
  | Enter current password > Verify > Update                               |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  STEP 4: VERIFY RECONCILIATION
  =============================

  +------------------------------------------------------------------------+
  | $ wabadmin password verify srv-prod-01/root                            |
  |                                                                        |
  | Verifying password for srv-prod-01/root...                             |
  | Connection: OK                                                         |
  | Authentication: OK                                                     |
  | Status: VERIFIED                                                       |
  |                                                                        |
  | $ wabadmin account show srv-prod-01/root                               |
  |                                                                        |
  | Account: srv-prod-01/root                                              |
  | Status: HEALTHY                                                        |
  | Last Verified: 2024-01-27 10:30:00                                     |
  +------------------------------------------------------------------------+

+==============================================================================+
```

---

## Rotation Queue Management

### Clearing Stuck Rotations

```
+==============================================================================+
|                   ROTATION QUEUE MANAGEMENT                                   |
+==============================================================================+

  VIEWING THE ROTATION QUEUE
  ==========================

  $ wabadmin rotation --queue

  Output:
  +------------------------------------------------------------------------+
  | Rotation Queue Status                                                  |
  | ---------------------                                                  |
  | Pending: 15                                                            |
  | In Progress: 3                                                         |
  | Failed (retry pending): 5                                              |
  | Total: 23                                                              |
  |                                                                        |
  | Queue Contents:                                                        |
  +------+-------------------+----------+---------+------------------------+
  | ID   | Account           | Status   | Retries | Scheduled              |
  +------+-------------------+----------+---------+------------------------+
  | 1001 | srv-01/root       | pending  | 0       | 2024-01-27 02:00:00    |
  | 1002 | srv-02/root       | pending  | 0       | 2024-01-27 02:00:00    |
  | 1003 | srv-03/root       | running  | 0       | 2024-01-27 02:00:00    |
  | 1004 | srv-04/root       | failed   | 3       | 2024-01-27 02:30:00    |
  | 1005 | win-01/Admin      | pending  | 0       | 2024-01-27 02:00:00    |
  +------+-------------------+----------+---------+------------------------+

  --------------------------------------------------------------------------

  CLEARING STUCK ROTATIONS
  ========================

  Identify stuck rotations:
  +------------------------------------------------------------------------+
  | $ wabadmin rotation --queue --status running --age ">30m"              |
  |                                                                        |
  | Rotations running > 30 minutes:                                        |
  | ID 1003: srv-03/root - running for 45 minutes                          |
  +------------------------------------------------------------------------+

  Cancel a specific stuck rotation:
  +------------------------------------------------------------------------+
  | $ wabadmin rotation cancel 1003                                        |
  |                                                                        |
  | Cancelling rotation 1003 for srv-03/root...                            |
  | Rotation cancelled. Account marked for manual review.                  |
  +------------------------------------------------------------------------+

  Clear all failed rotations:
  +------------------------------------------------------------------------+
  | $ wabadmin rotation clear-failed --all                                 |
  |                                                                        |
  | Cleared 5 failed rotations.                                            |
  | Accounts require manual reconciliation:                                |
  |   - srv-04/root                                                        |
  |   - srv-05/admin                                                       |
  |   - win-03/Administrator                                               |
  |   - db-01/oracle                                                       |
  |   - fw-01/admin                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  RETRY FAILED ROTATIONS
  ======================

  Retry specific rotation:
  +------------------------------------------------------------------------+
  | $ wabadmin rotation retry 1004                                         |
  |                                                                        |
  | Retrying rotation for srv-04/root...                                   |
  | Queued for immediate retry.                                            |
  +------------------------------------------------------------------------+

  Retry all failed with specific error:
  +------------------------------------------------------------------------+
  | $ wabadmin rotation retry-all --error "connection timeout"             |
  |                                                                        |
  | 3 rotations queued for retry.                                          |
  +------------------------------------------------------------------------+

+==============================================================================+
```

### Priority and Scheduling

```
+==============================================================================+
|                   ROTATION PRIORITY AND SCHEDULING                            |
+==============================================================================+

  PRIORITY LEVELS
  ===============

  +------------------------------------------------------------------------+
  | Priority | Description                  | Use Case                     |
  +----------+------------------------------+------------------------------+
  | CRITICAL | Immediate execution          | Security incident response   |
  | HIGH     | Next available slot          | Urgent operational need      |
  | NORMAL   | Standard queue processing    | Scheduled rotations          |
  | LOW      | After all normal complete    | Bulk rotations               |
  +----------+------------------------------+------------------------------+

  Set rotation priority:
  +------------------------------------------------------------------------+
  | $ wabadmin password rotate srv-prod-01/root --priority critical        |
  |                                                                        |
  | CRITICAL priority rotation queued.                                     |
  | Estimated start: Immediate (next available worker)                     |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  SCHEDULING OPTIONS
  ==================

  Immediate rotation:
  +------------------------------------------------------------------------+
  | $ wabadmin password rotate srv-prod-01/root --now                      |
  +------------------------------------------------------------------------+

  Scheduled rotation:
  +------------------------------------------------------------------------+
  | $ wabadmin password rotate srv-prod-01/root \                          |
  |     --schedule "2024-01-28 02:00:00"                                   |
  +------------------------------------------------------------------------+

  Rotation window configuration:
  +------------------------------------------------------------------------+
  | Admin > Password Policies > [Policy] > Rotation Window                 |
  |                                                                        |
  | Window Start: 02:00                                                    |
  | Window End: 06:00                                                      |
  | Timezone: UTC                                                          |
  | Days: Monday, Wednesday, Friday                                        |
  |                                                                        |
  | Block if active session: Yes                                           |
  | Retry interval: 30 minutes                                             |
  | Max retries: 3                                                         |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  BULK ROTATION MANAGEMENT
  ========================

  Queue bulk rotation:
  +------------------------------------------------------------------------+
  | $ wabadmin password rotate-bulk \                                      |
  |     --device-group "linux-servers" \                                   |
  |     --priority low \                                                   |
  |     --rate-limit 10/minute                                             |
  |                                                                        |
  | Queued 150 rotations.                                                  |
  | Estimated completion: 15 minutes                                       |
  +------------------------------------------------------------------------+

  Monitor bulk rotation:
  +------------------------------------------------------------------------+
  | $ wabadmin rotation --queue --bulk-job 12345                           |
  |                                                                        |
  | Bulk Job: 12345                                                        |
  | Total: 150                                                             |
  | Completed: 45 (30%)                                                    |
  | Failed: 2 (1%)                                                         |
  | Remaining: 103                                                         |
  | ETA: 12 minutes                                                        |
  +------------------------------------------------------------------------+

+==============================================================================+
```

---

## Diagnostic Commands and Scripts

### Complete Troubleshooting Toolkit

```
+==============================================================================+
|                   DIAGNOSTIC COMMANDS REFERENCE                               |
+==============================================================================+

  SERVICE STATUS COMMANDS
  =======================

  +------------------------------------------------------------------------+
  | # Check all WALLIX services                                            |
  | $ wabadmin status                                                      |
  |                                                                        |
  | # Check password manager specifically                                  |
  | $ systemctl status wabpassword                                         |
  | $ systemctl status wabscheduler                                        |
  |                                                                        |
  | # View service logs                                                    |
  | $ journalctl -u wabpassword --since "1 hour ago"                       |
  | $ journalctl -u wabscheduler --since "1 hour ago"                      |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  ACCOUNT AND PASSWORD COMMANDS
  =============================

  +------------------------------------------------------------------------+
  | # List all managed accounts                                            |
  | $ wabadmin account list                                                |
  |                                                                        |
  | # Show account details                                                 |
  | $ wabadmin account show <device>/<account>                             |
  |                                                                        |
  | # Show password (requires authorization)                               |
  | $ wabadmin account show <device>/<account> --show-password             |
  |                                                                        |
  | # Check account health                                                 |
  | $ wabadmin account health <device>/<account>                           |
  |                                                                        |
  | # List accounts with issues                                            |
  | $ wabadmin account list --status error                                 |
  | $ wabadmin account list --status sync-failed                           |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  ROTATION COMMANDS
  =================

  +------------------------------------------------------------------------+
  | # Trigger manual rotation                                              |
  | $ wabadmin password rotate <device>/<account>                          |
  |                                                                        |
  | # Dry-run rotation (test without changing)                             |
  | $ wabadmin password test-rotate <device>/<account> --dry-run           |
  |                                                                        |
  | # Verify current password                                              |
  | $ wabadmin password verify <device>/<account>                          |
  |                                                                        |
  | # Reconcile password                                                   |
  | $ wabadmin password reconcile <device>/<account>                       |
  |                                                                        |
  | # View rotation history                                                |
  | $ wabadmin password history <device>/<account> --last 10               |
  |                                                                        |
  | # View rotation queue                                                  |
  | $ wabadmin rotation --queue                                            |
  |                                                                        |
  | # Cancel rotation                                                      |
  | $ wabadmin rotation cancel <rotation-id>                               |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  CONNECTOR COMMANDS
  ==================

  +------------------------------------------------------------------------+
  | # List connectors                                                      |
  | $ wabadmin connector list                                              |
  |                                                                        |
  | # Show connector configuration                                         |
  | $ wabadmin connector show <connector-id> --config                      |
  |                                                                        |
  | # Test connector                                                       |
  | $ wabadmin connector test <connector-id> --target <device> \           |
  |     --account <account> --verbose                                      |
  |                                                                        |
  | # Configure connector timeouts                                         |
  | $ wabadmin connector configure <connector-id> \                        |
  |     --connection-timeout 60 --operation-timeout 120                    |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  POLICY COMMANDS
  ===============

  +------------------------------------------------------------------------+
  | # List password policies                                               |
  | $ wabadmin policy list                                                 |
  |                                                                        |
  | # Show policy details                                                  |
  | $ wabadmin policy show <policy-name>                                   |
  |                                                                        |
  | # Test password generation                                             |
  | $ wabadmin policy test-generate <policy-name> --count 5                |
  |                                                                        |
  | # Validate password against policy                                     |
  | $ wabadmin policy validate <policy-name> --password "TestP@ss123"      |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  LOG ANALYSIS COMMANDS
  =====================

  +------------------------------------------------------------------------+
  | # View rotation errors                                                 |
  | $ grep -i "error\|fail" /var/log/wab/wabpassword.log | tail -50        |
  |                                                                        |
  | # Filter by account                                                    |
  | $ grep "srv-prod-01/root" /var/log/wab/wabpassword.log | tail -50      |
  |                                                                        |
  | # View today's rotations                                               |
  | $ grep "$(date +%Y-%m-%d)" /var/log/wab/wabpassword.log | \            |
  |     grep "rotation complete"                                           |
  |                                                                        |
  | # Count rotation outcomes                                              |
  | $ grep "rotation complete" /var/log/wab/wabpassword.log | \            |
  |     grep "$(date +%Y-%m-%d)" | \                                       |
  |     awk '{print $NF}' | sort | uniq -c                                 |
  +------------------------------------------------------------------------+

+==============================================================================+
```

### Diagnostic Scripts

```
+==============================================================================+
|                   DIAGNOSTIC SCRIPTS                                          |
+==============================================================================+

  ROTATION HEALTH CHECK SCRIPT
  ============================

  Save as: /opt/wallix/scripts/rotation-health-check.sh

  +------------------------------------------------------------------------+
  | #!/bin/bash                                                            |
  | # rotation-health-check.sh - WALLIX Password Rotation Health Check     |
  |                                                                        |
  | echo "=================================="                              |
  | echo "WALLIX Rotation Health Check"                                    |
  | echo "Date: $(date)"                                                   |
  | echo "=================================="                              |
  | echo                                                                   |
  |                                                                        |
  | # Check service status                                                 |
  | echo "1. Service Status"                                               |
  | echo "---"                                                             |
  | systemctl is-active wabpassword > /dev/null && \                       |
  |   echo "   Password Manager: RUNNING" || \                             |
  |   echo "   Password Manager: STOPPED [!]"                              |
  | systemctl is-active wabscheduler > /dev/null && \                      |
  |   echo "   Scheduler: RUNNING" || \                                    |
  |   echo "   Scheduler: STOPPED [!]"                                     |
  | echo                                                                   |
  |                                                                        |
  | # Check queue status                                                   |
  | echo "2. Queue Status"                                                 |
  | echo "---"                                                             |
  | wabadmin rotation --queue --summary 2>/dev/null || \                   |
  |   echo "   Unable to query queue"                                      |
  | echo                                                                   |
  |                                                                        |
  | # Check for recent failures                                            |
  | echo "3. Recent Failures (last 24h)"                                   |
  | echo "---"                                                             |
  | FAILURES=$(grep -c "rotation.*failed" /var/log/wab/wabpassword.log \   |
  |   2>/dev/null || echo "0")                                             |
  | echo "   Total failures: $FAILURES"                                    |
  |                                                                        |
  | if [ "$FAILURES" -gt 0 ]; then                                         |
  |   echo "   Recent failed accounts:"                                    |
  |   grep "rotation.*failed" /var/log/wab/wabpassword.log | \             |
  |     tail -5 | awk '{print "     - " $0}'                               |
  | fi                                                                     |
  | echo                                                                   |
  |                                                                        |
  | # Check accounts with issues                                           |
  | echo "4. Accounts Requiring Attention"                                 |
  | echo "---"                                                             |
  | wabadmin account list --status error 2>/dev/null | head -10 || \       |
  |   echo "   Unable to query accounts"                                   |
  | echo                                                                   |
  |                                                                        |
  | # Check disk space for vault                                           |
  | echo "5. Disk Space"                                                   |
  | echo "---"                                                             |
  | df -h /var/lib/wallix | tail -1 | \                                    |
  |   awk '{print "   Vault storage: " $5 " used (" $4 " available)"}'     |
  | echo                                                                   |
  |                                                                        |
  | echo "=================================="                              |
  | echo "Check complete"                                                  |
  | echo "=================================="                              |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  TARGET CONNECTIVITY TEST SCRIPT
  ================================

  Save as: /opt/wallix/scripts/test-target-connectivity.sh

  +------------------------------------------------------------------------+
  | #!/bin/bash                                                            |
  | # test-target-connectivity.sh - Test rotation connectivity to target   |
  |                                                                        |
  | TARGET=$1                                                              |
  | PORT=${2:-22}                                                          |
  | TIMEOUT=${3:-5}                                                        |
  |                                                                        |
  | if [ -z "$TARGET" ]; then                                              |
  |   echo "Usage: $0 <target> [port] [timeout]"                           |
  |   echo "Example: $0 srv-prod-01 22 5"                                  |
  |   exit 1                                                               |
  | fi                                                                     |
  |                                                                        |
  | echo "Testing connectivity to $TARGET:$PORT"                           |
  | echo "---"                                                             |
  |                                                                        |
  | # DNS resolution                                                       |
  | echo -n "DNS resolution: "                                             |
  | IP=$(getent hosts "$TARGET" | awk '{print $1}')                        |
  | if [ -n "$IP" ]; then                                                  |
  |   echo "OK ($IP)"                                                      |
  | else                                                                   |
  |   echo "FAILED"                                                        |
  |   exit 1                                                               |
  | fi                                                                     |
  |                                                                        |
  | # Ping test                                                            |
  | echo -n "ICMP ping: "                                                  |
  | if ping -c 1 -W 2 "$TARGET" > /dev/null 2>&1; then                     |
  |   echo "OK"                                                            |
  | else                                                                   |
  |   echo "FAILED (may be blocked)"                                       |
  | fi                                                                     |
  |                                                                        |
  | # Port test                                                            |
  | echo -n "Port $PORT: "                                                 |
  | if nc -zw"$TIMEOUT" "$TARGET" "$PORT" 2>/dev/null; then                |
  |   echo "OPEN"                                                          |
  | else                                                                   |
  |   echo "CLOSED/FILTERED"                                               |
  |   exit 1                                                               |
  | fi                                                                     |
  |                                                                        |
  | # SSH banner (if port 22)                                              |
  | if [ "$PORT" -eq 22 ]; then                                            |
  |   echo -n "SSH banner: "                                               |
  |   BANNER=$(echo "" | nc -w2 "$TARGET" 22 2>/dev/null | head -1)        |
  |   if [ -n "$BANNER" ]; then                                            |
  |     echo "$BANNER"                                                     |
  |   else                                                                 |
  |     echo "Not received"                                                |
  |   fi                                                                   |
  | fi                                                                     |
  |                                                                        |
  | echo "---"                                                             |
  | echo "Connectivity test complete"                                      |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  BULK RECONCILIATION SCRIPT
  ==========================

  Save as: /opt/wallix/scripts/bulk-reconcile.sh

  +------------------------------------------------------------------------+
  | #!/bin/bash                                                            |
  | # bulk-reconcile.sh - Reconcile multiple accounts from file            |
  |                                                                        |
  | ACCOUNTS_FILE=$1                                                       |
  | LOG_FILE="/var/log/wallix/bulk-reconcile-$(date +%Y%m%d-%H%M%S).log"   |
  |                                                                        |
  | if [ -z "$ACCOUNTS_FILE" ] || [ ! -f "$ACCOUNTS_FILE" ]; then          |
  |   echo "Usage: $0 <accounts-file>"                                     |
  |   echo "File format: device/account,password (one per line)"           |
  |   exit 1                                                               |
  | fi                                                                     |
  |                                                                        |
  | echo "Starting bulk reconciliation..."                                 |
  | echo "Log file: $LOG_FILE"                                             |
  |                                                                        |
  | TOTAL=$(wc -l < "$ACCOUNTS_FILE")                                      |
  | CURRENT=0                                                              |
  | SUCCESS=0                                                              |
  | FAILED=0                                                               |
  |                                                                        |
  | while IFS=, read -r ACCOUNT PASSWORD; do                               |
  |   CURRENT=$((CURRENT + 1))                                             |
  |   echo -n "[$CURRENT/$TOTAL] $ACCOUNT: "                               |
  |                                                                        |
  |   if echo "$PASSWORD" | wabadmin password reconcile "$ACCOUNT" \       |
  |       >> "$LOG_FILE" 2>&1; then                                        |
  |     echo "OK"                                                          |
  |     SUCCESS=$((SUCCESS + 1))                                           |
  |   else                                                                 |
  |     echo "FAILED"                                                      |
  |     FAILED=$((FAILED + 1))                                             |
  |   fi                                                                   |
  | done < "$ACCOUNTS_FILE"                                                |
  |                                                                        |
  | echo "---"                                                             |
  | echo "Complete: $SUCCESS succeeded, $FAILED failed"                    |
  | echo "See $LOG_FILE for details"                                       |
  +------------------------------------------------------------------------+

+==============================================================================+
```

### Quick Reference Card

```
+==============================================================================+
|                   QUICK REFERENCE CARD                                        |
+==============================================================================+

  COMMON ROTATION COMMANDS
  ========================

  wabadmin password rotate <device>/<account>      # Trigger rotation
  wabadmin password verify <device>/<account>      # Verify password
  wabadmin password reconcile <device>/<account>   # Reconcile password
  wabadmin password history <device>/<account>     # View history

  wabadmin rotation --queue                        # View queue
  wabadmin rotation cancel <id>                    # Cancel rotation
  wabadmin rotation retry <id>                     # Retry failed

  wabadmin connector test <id> --target <d> --account <a>  # Test connector

  --------------------------------------------------------------------------

  LOG FILE LOCATIONS
  ==================

  /var/log/wab/wabpassword.log     # Rotation operations
  /var/log/wab/wabscheduler.log    # Scheduler operations
  /var/log/wab/wabaudit.log        # Audit trail
  /var/log/wab/wabengine.log       # General operations

  --------------------------------------------------------------------------

  COMMON ERROR CODES
  ==================

  WAB-4001  Rotation failed (general)
  WAB-4002  Verification failed (CRITICAL)
  WAB-4003  Connector error
  WAB-4004  Connection timeout
  WAB-4005  Authentication failed
  WAB-4006  Password policy violation
  WAB-4007  Permission denied

  --------------------------------------------------------------------------

  EMERGENCY PROCEDURES
  ====================

  1. Verification failed (WAB-4002):
     - DO NOT retry immediately
     - Manually test vault password on target
     - If password wrong: wabadmin password reconcile <device>/<account>

  2. Account locked:
     - Unlock on target system
     - Wait for lockout period
     - Trigger manual rotation

  3. Vault out of sync:
     - wabadmin password reconcile <device>/<account>
     - Enter actual target password when prompted

+==============================================================================+
```

---

## Related Documentation

- [07 - Password Management](../07-password-management/README.md) - Password management fundamentals
- [12 - Troubleshooting](../12-troubleshooting/README.md) - General troubleshooting guide
- [27 - Error Code Reference](../27-error-reference/README.md) - Complete error code list
- [30 - Operational Runbooks](../30-operational-runbooks/README.md) - Operational procedures

---

## External References

- WALLIX Bastion Administration Guide: https://pam.wallix.one/documentation/admin-doc/bastion_en_administration_guide.pdf
- WALLIX Support Portal: https://support.wallix.com
- WALLIX REST API Samples: https://github.com/wallix/wbrest_samples

---

*Document Version: 1.0 | Last Updated: January 2026 | WALLIX Bastion 12.1.x*
