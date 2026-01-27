# 12 - Troubleshooting

## Table of Contents

1. [Troubleshooting Methodology](#troubleshooting-methodology)
2. [Connection Issues](#connection-issues)
3. [Authentication Issues](#authentication-issues)
4. [Session Issues](#session-issues)
5. [Password Rotation Issues](#password-rotation-issues)
6. [Performance Issues](#performance-issues)
7. [Log Analysis](#log-analysis)
8. [Diagnostic Tools](#diagnostic-tools)

---

## Troubleshooting Methodology

### Systematic Approach

```
+==============================================================================+
|                    TROUBLESHOOTING METHODOLOGY                                |
+==============================================================================+
|                                                                               |
|  STEP 1: IDENTIFY                                                             |
|  ================                                                             |
|  * What is the exact error message?                                          |
|  * Who is affected? (One user, all users, specific targets)                  |
|  * When did it start?                                                        |
|  * What changed recently?                                                    |
|                                                                               |
|                    |                                                          |
|                    v                                                          |
|                                                                               |
|  STEP 2: ISOLATE                                                              |
|  ===============                                                              |
|  * Reproduce the issue                                                       |
|  * Test with different users/targets                                         |
|  * Test direct connectivity (bypass WALLIX)                                  |
|  * Check if issue is consistent or intermittent                              |
|                                                                               |
|                    |                                                          |
|                    v                                                          |
|                                                                               |
|  STEP 3: ANALYZE                                                              |
|  ==============                                                               |
|  * Check relevant logs                                                       |
|  * Verify configuration                                                      |
|  * Check network connectivity                                                |
|  * Review recent changes                                                     |
|                                                                               |
|                    |                                                          |
|                    v                                                          |
|                                                                               |
|  STEP 4: RESOLVE                                                              |
|  =============                                                                |
|  * Apply fix                                                                 |
|  * Test resolution                                                           |
|  * Document solution                                                         |
|  * Implement prevention measures                                             |
|                                                                               |
+==============================================================================+
```

---

## Connection Issues

### SSH Connection Failures

```
+==============================================================================+
|                    SSH CONNECTION ISSUES                                      |
+==============================================================================+
|                                                                               |
|  ISSUE: "Connection refused"                                                  |
|  ===========================                                                  |
|                                                                               |
|  Symptoms:                                                                    |
|  * User receives "Connection refused" error                                  |
|  * Session doesn't establish                                                 |
|                                                                               |
|  Diagnostic Steps:                                                            |
|                                                                               |
|  1. Test direct connectivity from Bastion to target:                         |
|     $ ssh -v root@target-server                                              |
|                                                                               |
|  2. Check if SSH service is running on target:                               |
|     $ systemctl status sshd   (on target)                                    |
|                                                                               |
|  3. Check firewall rules:                                                     |
|     $ iptables -L -n | grep 22   (on target)                                 |
|                                                                               |
|  4. Verify port configuration in WALLIX:                                      |
|     Service configured for correct port?                                     |
|                                                                               |
|  Common Causes:                                                               |
|  * SSH service not running on target                                         |
|  * Firewall blocking port 22                                                 |
|  * Wrong port configured in service                                          |
|  * Network routing issues                                                    |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  ISSUE: "Host key verification failed"                                        |
|  ======================================                                       |
|                                                                               |
|  Symptoms:                                                                    |
|  * Connection fails with host key error                                      |
|  * Works for some targets but not others                                     |
|                                                                               |
|  Diagnostic Steps:                                                            |
|                                                                               |
|  1. Check if target host key changed:                                        |
|     $ ssh-keyscan target-server                                              |
|                                                                               |
|  2. Clear cached host key in WALLIX (if target rebuilt):                     |
|     Admin UI > Devices > Device > Clear Host Key                             |
|                                                                               |
|  Common Causes:                                                               |
|  * Target server rebuilt/reinstalled                                         |
|  * Target IP changed but name didn't                                         |
|  * Man-in-the-middle (security concern!)                                     |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  ISSUE: "Permission denied"                                                   |
|  ===========================                                                  |
|                                                                               |
|  Symptoms:                                                                    |
|  * SSH connection establishes but auth fails                                 |
|  * "Permission denied (publickey,password)"                                  |
|                                                                               |
|  Diagnostic Steps:                                                            |
|                                                                               |
|  1. Verify password in vault is correct:                                     |
|     API: GET /api/accounts/{account}/password                                |
|                                                                               |
|  2. Test credential manually:                                                 |
|     $ ssh root@target  (enter password from vault)                           |
|                                                                               |
|  3. Check target authentication settings:                                    |
|     /etc/ssh/sshd_config > PasswordAuthentication yes?                       |
|                                                                               |
|  4. Check if account is locked on target:                                    |
|     $ passwd -S username  (on target)                                        |
|                                                                               |
|  Common Causes:                                                               |
|  * Password out of sync (rotation failed)                                    |
|  * Account locked on target                                                  |
|  * SSH key expected but password provided                                    |
|  * Root login disabled on target                                             |
|                                                                               |
+==============================================================================+
```

### RDP Connection Failures

```
+==============================================================================+
|                    RDP CONNECTION ISSUES                                      |
+==============================================================================+
|                                                                               |
|  ISSUE: "Unable to connect" / Timeout                                         |
|  ====================================                                         |
|                                                                               |
|  Diagnostic Steps:                                                            |
|                                                                               |
|  1. Test direct RDP from Bastion:                                            |
|     $ nc -zv target-server 3389                                              |
|                                                                               |
|  2. Check RDP service on target:                                             |
|     - Is Remote Desktop enabled?                                             |
|     - Windows Firewall rules?                                                |
|                                                                               |
|  3. Check Network Level Authentication (NLA) settings:                        |
|     - Target requires NLA but WALLIX configured for lower?                   |
|                                                                               |
|  Common Causes:                                                               |
|  * RDP not enabled on target                                                 |
|  * Firewall blocking port 3389                                               |
|  * NLA mismatch                                                              |
|  * Target not accepting connections (max reached)                            |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  ISSUE: "CredSSP" or NLA Errors                                               |
|  ===============================                                              |
|                                                                               |
|  Symptoms:                                                                    |
|  * "CredSSP encryption oracle remediation" error                             |
|  * "Authentication error" with NLA targets                                   |
|                                                                               |
|  Solution:                                                                    |
|                                                                               |
|  1. Check WALLIX service security level configuration:                        |
|     Service > RDP > Security Level: NLA (if target requires)                 |
|                                                                               |
|  2. For domain accounts, verify:                                             |
|     - Kerberos configuration if using SSO                                    |
|     - Domain controller connectivity                                         |
|                                                                               |
|  3. If target has CredSSP patch issues:                                       |
|     - Update target Windows                                                  |
|     - Or temporarily lower security (not recommended)                        |
|                                                                               |
+==============================================================================+
```

---

## Authentication Issues

### User Authentication Failures

```
+==============================================================================+
|                    USER AUTHENTICATION ISSUES                                 |
+==============================================================================+
|                                                                               |
|  ISSUE: "Invalid credentials" for LDAP/AD users                               |
|  ==============================================                               |
|                                                                               |
|  Diagnostic Steps:                                                            |
|                                                                               |
|  1. Test LDAP connectivity:                                                   |
|     $ ldapsearch -x -H ldaps://dc.company.com -D "bind_user" -W              |
|                                                                               |
|  2. Verify user exists in LDAP:                                               |
|     $ ldapsearch -x -H ldaps://dc.company.com \                              |
|       -D "bind_user" -W -b "DC=company,DC=com" \                             |
|       "(sAMAccountName=username)"                                            |
|                                                                               |
|  3. Check WALLIX LDAP configuration:                                          |
|     - Bind credentials correct?                                              |
|     - Base DN correct?                                                       |
|     - User filter correct?                                                   |
|                                                                               |
|  4. Check WALLIX logs:                                                        |
|     $ tail -f /var/log/wabengine/wabengine.log | grep -i ldap                |
|                                                                               |
|  Common Causes:                                                               |
|  * LDAP bind credentials expired                                             |
|  * SSL certificate issues                                                    |
|  * User not in correct OU (search scope)                                     |
|  * Account disabled in AD                                                    |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  ISSUE: MFA/RADIUS failures                                                   |
|  ===========================                                                  |
|                                                                               |
|  Diagnostic Steps:                                                            |
|                                                                               |
|  1. Test RADIUS connectivity:                                                 |
|     $ radtest username password radius-server 1812 sharedsecret              |
|                                                                               |
|  2. Check RADIUS server logs                                                  |
|                                                                               |
|  3. Verify shared secret matches                                              |
|                                                                               |
|  4. Check WALLIX RADIUS configuration:                                        |
|     - Server address correct?                                                |
|     - Port correct (1812)?                                                   |
|     - Shared secret correct?                                                 |
|                                                                               |
|  Common Causes:                                                               |
|  * Shared secret mismatch                                                    |
|  * RADIUS server unreachable                                                 |
|  * User not enrolled in MFA                                                  |
|  * Token expired/desynchronized                                              |
|                                                                               |
+==============================================================================+
```

---

## Session Issues

### Session Recording Issues

```
+==============================================================================+
|                    SESSION RECORDING ISSUES                                   |
+==============================================================================+
|                                                                               |
|  ISSUE: Sessions not being recorded                                           |
|  ==================================                                           |
|                                                                               |
|  Diagnostic Steps:                                                            |
|                                                                               |
|  1. Check authorization settings:                                             |
|     Authorization > is_recorded = true?                                      |
|                                                                               |
|  2. Check recording storage:                                                  |
|     $ df -h /var/wab/recorded                                                |
|     Is there disk space available?                                           |
|                                                                               |
|  3. Check recording directory permissions:                                    |
|     $ ls -la /var/wab/recorded                                               |
|     Owner should be wabadmin                                                 |
|                                                                               |
|  4. Check for recording errors in logs:                                       |
|     $ grep -i "recording" /var/log/wabengine/wabengine.log                   |
|                                                                               |
|  Common Causes:                                                               |
|  * Recording disabled in authorization                                       |
|  * Disk full on recording storage                                            |
|  * Permission issues on recording directory                                  |
|  * NFS mount issues (if external storage)                                    |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  ISSUE: Recording playback fails                                              |
|  ===============================                                              |
|                                                                               |
|  Diagnostic Steps:                                                            |
|                                                                               |
|  1. Check recording file exists:                                              |
|     $ ls -la /var/wab/recorded/YYYY/MM/DD/session_id.wab                     |
|                                                                               |
|  2. Check file integrity:                                                     |
|     $ file /var/wab/recorded/.../session_id.wab                              |
|                                                                               |
|  3. Check playback component:                                                 |
|     $ systemctl status wabplayback                                           |
|                                                                               |
|  Common Causes:                                                               |
|  * Recording file corrupted                                                  |
|  * Session ended abnormally (incomplete recording)                           |
|  * Playback service not running                                              |
|  * Browser codec issues (HTML5 player)                                       |
|                                                                               |
+==============================================================================+
```

---

## Password Rotation Issues

### Rotation Failures

```
+==============================================================================+
|                    PASSWORD ROTATION ISSUES                                   |
+==============================================================================+
|                                                                               |
|  ISSUE: Rotation fails - Connection error                                     |
|  ========================================                                     |
|                                                                               |
|  Diagnostic Steps:                                                            |
|                                                                               |
|  1. Test connectivity from Bastion:                                           |
|     SSH: $ ssh root@target                                                   |
|     WinRM: $ Test-WSMan target                                               |
|                                                                               |
|  2. Verify rotation account credentials:                                      |
|     Can you manually connect with rotation account?                          |
|                                                                               |
|  3. Check firewall rules:                                                     |
|     Required ports open from Bastion to target?                              |
|                                                                               |
|  Resolution:                                                                  |
|  * Fix network connectivity                                                  |
|  * Update rotation account password if expired                               |
|  * Verify target service is running                                          |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  ISSUE: Rotation fails - Permission denied                                    |
|  =========================================                                    |
|                                                                               |
|  Diagnostic Steps:                                                            |
|                                                                               |
|  1. Check rotation account permissions:                                       |
|     Linux: Can account run passwd command?                                   |
|     Windows: Has account password reset permissions?                         |
|                                                                               |
|  2. Check sudo configuration (Linux):                                         |
|     /etc/sudoers: rotation_user ALL=(ALL) NOPASSWD: /usr/bin/passwd          |
|                                                                               |
|  3. Check AD delegation (Windows):                                            |
|     Does rotation account have "Reset Password" right?                       |
|                                                                               |
|  Resolution:                                                                  |
|  * Grant appropriate permissions to rotation account                         |
|  * Use account with sufficient privileges                                    |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  ISSUE: Password changed but vault not updated                                |
|  =============================================                                |
|                                                                               |
|  Symptoms:                                                                    |
|  * Sessions fail after rotation                                              |
|  * Rotation shows "success" but password doesn't work                        |
|                                                                               |
|  Diagnostic Steps:                                                            |
|                                                                               |
|  1. Check verification step in rotation:                                      |
|     Did verification pass or was it skipped?                                 |
|                                                                               |
|  2. Try manual login with vault password:                                     |
|     Get password from API, try to login                                      |
|                                                                               |
|  Resolution:                                                                  |
|  * Trigger reconciliation                                                    |
|  * Manually update vault with correct password                               |
|  * Review rotation plugin/connector                                          |
|                                                                               |
+==============================================================================+
```

---

## Performance Issues

### Slow Sessions

```
+==============================================================================+
|                    PERFORMANCE ISSUES                                         |
+==============================================================================+
|                                                                               |
|  ISSUE: Slow session establishment                                            |
|  =================================                                            |
|                                                                               |
|  Diagnostic Steps:                                                            |
|                                                                               |
|  1. Measure time for each phase:                                              |
|     * User authentication                                                    |
|     * Authorization check                                                    |
|     * Credential retrieval                                                   |
|     * Target connection                                                      |
|                                                                               |
|  2. Check database performance:                                               |
|     $ psql -U wabadmin -c "SELECT * FROM pg_stat_activity"                   |
|                                                                               |
|  3. Check system resources:                                                   |
|     $ top -b -n 1 | head -20                                                 |
|     $ free -m                                                                 |
|     $ df -h                                                                   |
|                                                                               |
|  4. Check network latency:                                                    |
|     $ ping target-server                                                     |
|     $ traceroute target-server                                               |
|                                                                               |
|  Common Causes:                                                               |
|  * LDAP/AD slow response                                                     |
|  * Database queries slow                                                     |
|  * Network latency to targets                                                |
|  * DNS resolution slow                                                       |
|  * System resource exhaustion                                                |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  ISSUE: High CPU/Memory usage                                                 |
|  ===============================                                              |
|                                                                               |
|  Diagnostic Steps:                                                            |
|                                                                               |
|  1. Check process resource usage:                                             |
|     $ ps aux --sort=-%mem | head -10                                         |
|     $ ps aux --sort=-%cpu | head -10                                         |
|                                                                               |
|  2. Check active session count:                                               |
|     API: GET /api/sessions/current                                           |
|                                                                               |
|  3. Check recording storage I/O:                                              |
|     $ iostat -x 1 5                                                          |
|                                                                               |
|  Optimization:                                                                |
|  * Increase resources if undersized                                          |
|  * Move recordings to faster storage                                         |
|  * Add cluster nodes for load distribution                                   |
|  * Review session limits                                                     |
|                                                                               |
+==============================================================================+
```

---

## Log Analysis

### Log Locations

```
+==============================================================================+
|                         LOG LOCATIONS                                         |
+==============================================================================+
|                                                                               |
|  WALLIX SERVICE LOGS                                                          |
|  ===================                                                          |
|                                                                               |
|  /var/log/wabengine/                                                          |
|  +-- wabengine.log           # Main application log                          |
|  +-- wabproxy.log            # Session proxy log                             |
|  +-- wabpassword.log         # Password manager log                          |
|                                                                               |
|  /var/log/wabaudit/                                                           |
|  +-- audit.log               # Audit trail                                   |
|                                                                               |
|  /var/log/wabsessions/                                                        |
|  +-- sessions.log            # Session activity log                          |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  SYSTEM LOGS                                                                  |
|  ===========                                                                  |
|                                                                               |
|  /var/log/syslog             # System messages                               |
|  /var/log/auth.log           # Authentication (PAM)                          |
|  /var/log/postgresql/        # Database logs                                 |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  USEFUL LOG COMMANDS                                                          |
|  ===================                                                          |
|                                                                               |
|  # Real-time monitoring                                                       |
|  $ tail -f /var/log/wabengine/wabengine.log                                  |
|                                                                               |
|  # Search for errors                                                          |
|  $ grep -i error /var/log/wabengine/*.log                                    |
|                                                                               |
|  # Filter by session ID                                                       |
|  $ grep "SES-123456" /var/log/wabengine/*.log                                |
|                                                                               |
|  # Filter by user                                                             |
|  $ grep "user=jsmith" /var/log/wabaudit/audit.log                            |
|                                                                               |
|  # Filter by timestamp                                                        |
|  $ awk '/2024-01-15 10:/ {print}' /var/log/wabengine/wabengine.log           |
|                                                                               |
+==============================================================================+
```

---

## Diagnostic Tools

### Built-in Diagnostics

```
+==============================================================================+
|                      DIAGNOSTIC TOOLS                                         |
+==============================================================================+
|                                                                               |
|  WALLIX DIAGNOSTIC COMMANDS                                                   |
|  ==========================                                                   |
|                                                                               |
|  # Service status check                                                       |
|  $ waservices status                                                          |
|                                                                               |
|  # Configuration validation                                                   |
|  $ waconfig --check                                                           |
|                                                                               |
|  # Database connectivity test                                                 |
|  $ wadbcheck                                                                  |
|                                                                               |
|  # Full system diagnostic                                                     |
|  $ wabdiag --full                                                             |
|                                                                               |
|  # LDAP connectivity test                                                     |
|  $ wabldaptest --server dc.company.com --bind-dn "user" --bind-pw "pass"     |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  NETWORK DIAGNOSTICS                                                          |
|  ===================                                                          |
|                                                                               |
|  # Test target connectivity                                                   |
|  $ nc -zv target-server 22        # SSH                                      |
|  $ nc -zv target-server 3389      # RDP                                      |
|  $ nc -zv target-server 636       # LDAPS                                    |
|                                                                               |
|  # DNS resolution                                                             |
|  $ nslookup target-server                                                     |
|  $ dig target-server                                                          |
|                                                                               |
|  # Network path                                                               |
|  $ traceroute target-server                                                   |
|  $ mtr target-server                                                          |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  DATABASE DIAGNOSTICS                                                         |
|  ====================                                                         |
|                                                                               |
|  # Check database connectivity                                                |
|  $ psql -U wabadmin -c "SELECT version();"                                   |
|                                                                               |
|  # Check active connections                                                   |
|  $ psql -U wabadmin -c "SELECT count(*) FROM pg_stat_activity;"              |
|                                                                               |
|  # Check database size                                                        |
|  $ psql -U wabadmin -c "SELECT pg_size_pretty(pg_database_size('wabdb'));"   |
|                                                                               |
|  # Check replication status (if HA)                                           |
|  $ psql -U wabadmin -c "SELECT * FROM pg_stat_replication;"                  |
|                                                                               |
+==============================================================================+
```

---

## Next Steps

Continue to [13 - Best Practices](../13-best-practices/README.md) for operational recommendations.
