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
+===============================================================================+
|                    TROUBLESHOOTING METHODOLOGY                                |
+===============================================================================+
|                                                                               |
|  STEP 1: IDENTIFY                                                             |
|  ================                                                             |
|  * What is the exact error message?                                           |
|  * Who is affected? (One user, all users, specific targets)                   |
|  * When did it start?                                                         |
|  * What changed recently?                                                     |
|                                                                               |
|                    |                                                          |
|                    v                                                          |
|                                                                               |
|  STEP 2: ISOLATE                                                              |
|  ===============                                                              |
|  * Reproduce the issue                                                        |
|  * Test with different users/targets                                          |
|  * Test direct connectivity (bypass WALLIX)                                   |
|  * Check if issue is consistent or intermittent                               |
|                                                                               |
|                    |                                                          |
|                    v                                                          |
|                                                                               |
|  STEP 3: ANALYZE                                                              |
|  ==============                                                               |
|  * Check relevant logs                                                        |
|  * Verify configuration                                                       |
|  * Check network connectivity                                                 |
|  * Review recent changes                                                      |
|                                                                               |
|                    |                                                          |
|                    v                                                          |
|                                                                               |
|  STEP 4: RESOLVE                                                              |
|  =============                                                                |
|  * Apply fix                                                                  |
|  * Test resolution                                                            |
|  * Document solution                                                          |
|  * Implement prevention measures                                              |
|                                                                               |
+===============================================================================+
```

---

## Connection Issues

### SSH Connection Failures

```
+===============================================================================+
|                    SSH CONNECTION ISSUES                                      |
+===============================================================================+
|                                                                               |
|  ISSUE: "Connection refused"                                                  |
|  ===========================                                                  |
|                                                                               |
|  Symptoms:                                                                    |
|  * User receives "Connection refused" error                                   |
|  * Session doesn't establish                                                  |
|                                                                               |
|  Diagnostic Steps:                                                            |
|                                                                               |
|  1. Test direct connectivity from Bastion to target:                          |
|     $ ssh -v root@target-server                                               |
|                                                                               |
|  2. Check if SSH service is running on target:                                |
|     $ systemctl status sshd   (on target)                                     |
|                                                                               |
|  3. Check firewall rules:                                                     |
|     $ iptables -L -n | grep 22   (on target)                                  |
|                                                                               |
|  4. Verify port configuration in WALLIX:                                      |
|     Service configured for correct port?                                      |
|                                                                               |
|  Common Causes:                                                               |
|  * SSH service not running on target                                          |
|  * Firewall blocking port 22                                                  |
|  * Wrong port configured in service                                           |
|  * Network routing issues                                                     |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  ISSUE: "Host key verification failed"                                        |
|  ======================================                                       |
|                                                                               |
|  Symptoms:                                                                    |
|  * Connection fails with host key error                                       |
|  * Works for some targets but not others                                      |
|                                                                               |
|  Diagnostic Steps:                                                            |
|                                                                               |
|  1. Check if target host key changed:                                         |
|     $ ssh-keyscan target-server                                               |
|                                                                               |
|  2. Clear cached host key in WALLIX (if target rebuilt):                      |
|     Admin UI > Devices > Device > Clear Host Key                              |
|                                                                               |
|  Common Causes:                                                               |
|  * Target server rebuilt/reinstalled                                          |
|  * Target IP changed but name didn't                                          |
|  * Man-in-the-middle (security concern!)                                      |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  ISSUE: "Permission denied"                                                   |
|  ===========================                                                  |
|                                                                               |
|  Symptoms:                                                                    |
|  * SSH connection establishes but auth fails                                  |
|  * "Permission denied (publickey,password)"                                   |
|                                                                               |
|  Diagnostic Steps:                                                            |
|                                                                               |
|  1. Verify password in vault is correct:                                      |
|     API: GET /api/accounts/{account}/password                                 |
|                                                                               |
|  2. Test credential manually:                                                 |
|     $ ssh root@target  (enter password from vault)                            |
|                                                                               |
|  3. Check target authentication settings:                                     |
|     /etc/ssh/sshd_config > PasswordAuthentication yes?                        |
|                                                                               |
|  4. Check if account is locked on target:                                     |
|     $ passwd -S username  (on target)                                         |
|                                                                               |
|  Common Causes:                                                               |
|  * Password out of sync (rotation failed)                                     |
|  * Account locked on target                                                   |
|  * SSH key expected but password provided                                     |
|  * Root login disabled on target                                              |
|                                                                               |
+===============================================================================+
```

### RDP Connection Failures

```
+===============================================================================+
|                    RDP CONNECTION ISSUES                                      |
+===============================================================================+
|                                                                               |
|  ISSUE: "Unable to connect" / Timeout                                         |
|  ====================================                                         |
|                                                                               |
|  Diagnostic Steps:                                                            |
|                                                                               |
|  1. Test direct RDP from Bastion:                                             |
|     $ nc -zv target-server 3389                                               |
|                                                                               |
|  2. Check RDP service on target:                                              |
|     - Is Remote Desktop enabled?                                              |
|     - Windows Firewall rules?                                                 |
|                                                                               |
|  3. Check Network Level Authentication (NLA) settings:                        |
|     - Target requires NLA but WALLIX configured for lower?                    |
|                                                                               |
|  Common Causes:                                                               |
|  * RDP not enabled on target                                                  |
|  * Firewall blocking port 3389                                                |
|  * NLA mismatch                                                               |
|  * Target not accepting connections (max reached)                             |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  ISSUE: "CredSSP" or NLA Errors                                               |
|  ===============================                                              |
|                                                                               |
|  Symptoms:                                                                    |
|  * "CredSSP encryption oracle remediation" error                              |
|  * "Authentication error" with NLA targets                                    |
|                                                                               |
|  Solution:                                                                    |
|                                                                               |
|  1. Check WALLIX service security level configuration:                        |
|     Service > RDP > Security Level: NLA (if target requires)                  |
|                                                                               |
|  2. For domain accounts, verify:                                              |
|     - Kerberos configuration if using SSO                                     |
|     - Domain controller connectivity                                          |
|                                                                               |
|  3. If target has CredSSP patch issues:                                       |
|     - Update target Windows                                                   |
|     - Or temporarily lower security (not recommended)                         |
|                                                                               |
+===============================================================================+
```

---

## Authentication Issues

### User Authentication Failures

```
+===============================================================================+
|                    USER AUTHENTICATION ISSUES                                 |
+===============================================================================+
|                                                                               |
|  ISSUE: "Invalid credentials" for LDAP/AD users                               |
|  ==============================================                               |
|                                                                               |
|  Diagnostic Steps:                                                            |
|                                                                               |
|  1. Test LDAP connectivity:                                                   |
|     $ ldapsearch -x -H ldaps://dc.company.com -D "bind_user" -W               |
|                                                                               |
|  2. Verify user exists in LDAP:                                               |
|     $ ldapsearch -x -H ldaps://dc.company.com \                               |
|       -D "bind_user" -W -b "DC=company,DC=com" \                              |
|       "(sAMAccountName=username)"                                             |
|                                                                               |
|  3. Check WALLIX LDAP configuration:                                          |
|     - Bind credentials correct?                                               |
|     - Base DN correct?                                                        |
|     - User filter correct?                                                    |
|                                                                               |
|  4. Check WALLIX logs:                                                        |
|     $ tail -f /var/log/wabengine/wabengine.log | grep -i ldap                 |
|                                                                               |
|  Common Causes:                                                               |
|  * LDAP bind credentials expired                                              |
|  * SSL certificate issues                                                     |
|  * User not in correct OU (search scope)                                      |
|  * Account disabled in AD                                                     |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  ISSUE: MFA/RADIUS failures                                                   |
|  ===========================                                                  |
|                                                                               |
|  Diagnostic Steps:                                                            |
|                                                                               |
|  1. Test RADIUS connectivity:                                                 |
|     $ radtest username password radius-server 1812 sharedsecret               |
|                                                                               |
|  2. Check RADIUS server logs                                                  |
|                                                                               |
|  3. Verify shared secret matches                                              |
|                                                                               |
|  4. Check WALLIX RADIUS configuration:                                        |
|     - Server address correct?                                                 |
|     - Port correct (1812)?                                                    |
|     - Shared secret correct?                                                  |
|                                                                               |
|  Common Causes:                                                               |
|  * Shared secret mismatch                                                     |
|  * RADIUS server unreachable                                                  |
|  * User not enrolled in MFA                                                   |
|  * Token expired/desynchronized                                               |
|                                                                               |
+===============================================================================+
```

---

## Session Issues

### Session Recording Issues

```
+===============================================================================+
|                    SESSION RECORDING ISSUES                                   |
+===============================================================================+
|                                                                               |
|  ISSUE: Sessions not being recorded                                           |
|  ==================================                                           |
|                                                                               |
|  Diagnostic Steps:                                                            |
|                                                                               |
|  1. Check authorization settings:                                             |
|     Authorization > is_recorded = true?                                       |
|                                                                               |
|  2. Check recording storage:                                                  |
|     $ df -h /var/wab/recorded                                                 |
|     Is there disk space available?                                            |
|                                                                               |
|  3. Check recording directory permissions:                                    |
|     $ ls -la /var/wab/recorded                                                |
|     Owner should be wabadmin                                                  |
|                                                                               |
|  4. Check for recording errors in logs:                                       |
|     $ grep -i "recording" /var/log/wabengine/wabengine.log                    |
|                                                                               |
|  Common Causes:                                                               |
|  * Recording disabled in authorization                                        |
|  * Disk full on recording storage                                             |
|  * Permission issues on recording directory                                   |
|  * NFS mount issues (if external storage)                                     |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  ISSUE: Recording playback fails                                              |
|  ===============================                                              |
|                                                                               |
|  Diagnostic Steps:                                                            |
|                                                                               |
|  1. Check recording file exists:                                              |
|     $ ls -la /var/wab/recorded/YYYY/MM/DD/session_id.wab                      |
|                                                                               |
|  2. Check file integrity:                                                     |
|     $ file /var/wab/recorded/.../session_id.wab                               |
|                                                                               |
|  3. Check playback component:                                                 |
|     $ systemctl status wabplayback                                            |
|                                                                               |
|  Common Causes:                                                               |
|  * Recording file corrupted                                                   |
|  * Session ended abnormally (incomplete recording)                            |
|  * Playback service not running                                               |
|  * Browser codec issues (HTML5 player)                                        |
|                                                                               |
+===============================================================================+
```

---

## Password Rotation Issues

### Rotation Failures

```
+===============================================================================+
|                    PASSWORD ROTATION ISSUES                                   |
+===============================================================================+
|                                                                               |
|  ISSUE: Rotation fails - Connection error                                     |
|  ========================================                                     |
|                                                                               |
|  Diagnostic Steps:                                                            |
|                                                                               |
|  1. Test connectivity from Bastion:                                           |
|     SSH: $ ssh root@target                                                    |
|     WinRM: $ Test-WSMan target                                                |
|                                                                               |
|  2. Verify rotation account credentials:                                      |
|     Can you manually connect with rotation account?                           |
|                                                                               |
|  3. Check firewall rules:                                                     |
|     Required ports open from Bastion to target?                               |
|                                                                               |
|  Resolution:                                                                  |
|  * Fix network connectivity                                                   |
|  * Update rotation account password if expired                                |
|  * Verify target service is running                                           |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  ISSUE: Rotation fails - Permission denied                                    |
|  =========================================                                    |
|                                                                               |
|  Diagnostic Steps:                                                            |
|                                                                               |
|  1. Check rotation account permissions:                                       |
|     Linux: Can account run passwd command?                                    |
|     Windows: Has account password reset permissions?                          |
|                                                                               |
|  2. Check sudo configuration (Linux):                                         |
|     /etc/sudoers: rotation_user ALL=(ALL) NOPASSWD: /usr/bin/passwd           |
|                                                                               |
|  3. Check AD delegation (Windows):                                            |
|     Does rotation account have "Reset Password" right?                        |
|                                                                               |
|  Resolution:                                                                  |
|  * Grant appropriate permissions to rotation account                          |
|  * Use account with sufficient privileges                                     |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  ISSUE: Password changed but vault not updated                                |
|  =============================================                                |
|                                                                               |
|  Symptoms:                                                                    |
|  * Sessions fail after rotation                                               |
|  * Rotation shows "success" but password doesn't work                         |
|                                                                               |
|  Diagnostic Steps:                                                            |
|                                                                               |
|  1. Check verification step in rotation:                                      |
|     Did verification pass or was it skipped?                                  |
|                                                                               |
|  2. Try manual login with vault password:                                     |
|     Get password from API, try to login                                       |
|                                                                               |
|  Resolution:                                                                  |
|  * Trigger reconciliation                                                     |
|  * Manually update vault with correct password                                |
|  * Review rotation plugin/connector                                           |
|                                                                               |
+===============================================================================+
```

---

## Performance Issues

### Slow Sessions

```
+===============================================================================+
|                    PERFORMANCE ISSUES                                         |
+===============================================================================+
|                                                                               |
|  ISSUE: Slow session establishment                                            |
|  =================================                                            |
|                                                                               |
|  Diagnostic Steps:                                                            |
|                                                                               |
|  1. Measure time for each phase:                                              |
|     * User authentication                                                     |
|     * Authorization check                                                     |
|     * Credential retrieval                                                    |
|     * Target connection                                                       |
|                                                                               |
|  2. Check database performance:                                               |
|     $ mysql -u wabadmin -e "SHOW PROCESSLIST"                                 |
|                                                                               |
|  3. Check system resources:                                                   |
|     $ top -b -n 1 | head -20                                                  |
|     $ free -m                                                                 |
|     $ df -h                                                                   |
|                                                                               |
|  4. Check network latency:                                                    |
|     $ ping target-server                                                      |
|     $ traceroute target-server                                                |
|                                                                               |
|  Common Causes:                                                               |
|  * LDAP/AD slow response                                                      |
|  * Database queries slow                                                      |
|  * Network latency to targets                                                 |
|  * DNS resolution slow                                                        |
|  * System resource exhaustion                                                 |
|                                                                               |
|  -------------------------------------------------------------------------- - |
|                                                                               |
|  ISSUE: High CPU/Memory usage                                                 |
|  ===============================                                              |
|                                                                               |
|  Diagnostic Steps:                                                            |
|                                                                               |
|  1. Check process resource usage:                                             |
|     $ ps aux --sort=-%mem | head -10                                          |
|     $ ps aux --sort=-%cpu | head -10                                          |
|                                                                               |
|  2. Check active session count:                                               |
|     API: GET /api/sessions/current                                            |
|                                                                               |
|  3. Check recording storage I/O:                                              |
|     $ iostat -x 1 5                                                           |
|                                                                               |
|  Optimization:                                                                |
|  * Increase resources if undersized                                           |
|  * Move recordings to faster storage                                          |
|  * Add cluster nodes for load distribution                                    |
|  * Review session limits                                                      |
|                                                                               |
+===============================================================================+
```

---

## Log Analysis

### Log Locations

```
+===============================================================================+
|                         LOG LOCATIONS                                         |
+===============================================================================+
|                                                                               |
|  WALLIX SERVICE LOGS                                                          |
|  ===================                                                          |
|                                                                               |
|  /var/log/wabengine/                                                          |
|  +-- wabengine.log           # Main application log                           |
|  +-- wabproxy.log            # Session proxy log                              |
|  +-- wabpassword.log         # Password manager log                           |
|                                                                               |
|  /var/log/wabaudit/                                                           |
|  +-- audit.log               # Audit trail                                    |
|                                                                               |
|  /var/log/wabsessions/                                                        |
|  +-- sessions.log            # Session activity log                           |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  SYSTEM LOGS                                                                  |
|  ===========                                                                  |
|                                                                               |
|  /var/log/syslog             # System messages                                |
|  /var/log/auth.log           # Authentication (PAM)                           |
|  /var/lib/mysql/             # Database logs                                  |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  USEFUL LOG COMMANDS                                                          |
|  ===================                                                          |
|                                                                               |
|  # Real-time monitoring                                                       |
|  $ tail -f /var/log/wabengine/wabengine.log                                   |
|                                                                               |
|  # Search for errors                                                          |
|  $ grep -i error /var/log/wabengine/*.log                                     |
|                                                                               |
|  # Filter by session ID                                                       |
|  $ grep "SES-123456" /var/log/wabengine/*.log                                 |
|                                                                               |
|  # Filter by user                                                             |
|  $ grep "user=jsmith" /var/log/wabaudit/audit.log                             |
|                                                                               |
|  # Filter by timestamp                                                        |
|  $ awk '/2024-01-15 10:/ {print}' /var/log/wabengine/wabengine.log            |
|                                                                               |
+===============================================================================+
```

---

## Diagnostic Tools

### Built-in Diagnostics

```
+===============================================================================+
|                      DIAGNOSTIC TOOLS                                         |
+===============================================================================+
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
|  $ wabldaptest --server dc.company.com --bind-dn "user" --bind-pw "pass"      |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  NETWORK DIAGNOSTICS                                                          |
|  ===================                                                          |
|                                                                               |
|  # Test target connectivity                                                   |
|  $ nc -zv target-server 22        # SSH                                       |
|  $ nc -zv target-server 3389      # RDP                                       |
|  $ nc -zv target-server 636       # LDAPS                                     |
|                                                                               |
|  # DNS resolution                                                             |
|  $ nslookup target-server                                                     |
|  $ dig target-server                                                          |
|                                                                               |
|  # Network path                                                               |
|  $ traceroute target-server                                                   |
|  $ mtr target-server                                                          |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  DATABASE DIAGNOSTICS                                                         |
|  ====================                                                         |
|                                                                               |
|  # Check database connectivity                                                |
|  $ mysql -u wabadmin -e "SELECT VERSION();"                                   |
|                                                                               |
|  # Check active connections                                                   |
|  $ mysql -u wabadmin -e "SELECT COUNT(*) FROM information_schema.processlist;"|
|                                                                               |
|  # Check database size                                                        |
|  $ mysql -u wabadmin -e "SELECT table_schema, ROUND(SUM(data_length+index_length)/1024/1024,2) AS 'Size (MB)' FROM information_schema.tables WHERE table_schema='wabdb';" |
|                                                                               |
|  # Check replication status (if HA)                                           |
|  $ mysql -u wabadmin -e "SHOW SLAVE STATUS\G"                                 |
|                                                                               |
+===============================================================================+
```

---

## Database Tuning

### MariaDB Tuning Guide

```
+===============================================================================+
|                   MARIADB TUNING FOR WALLIX                                   |
+===============================================================================+

  MEMORY CONFIGURATION
  ====================

  Edit /etc/mysql/mariadb.conf.d/50-server.cnf:

  +------------------------------------------------------------------------+
  | # Connection Settings                                                  |
  | max_connections = 200            # Adjust based on concurrent users    |
  |                                                                        |
  | # Memory Settings (for 16GB RAM system)                                |
  | innodb_buffer_pool_size = 4GB    # 25% of total RAM                    |
  | innodb_log_file_size = 1GB       # Redo log size                       |
  | key_buffer_size = 256MB          # For MyISAM indexes                  |
  | query_cache_size = 0             # Disabled in MariaDB 10.1.7+         |
  |                                                                        |
  | # InnoDB Settings                                                      |
  | innodb_log_buffer_size = 64MB    # Log buffer                          |
  | innodb_flush_log_at_trx_commit = 1                                     |
  | innodb_file_per_table = 1                                              |
  |                                                                        |
  | # Performance Settings                                                 |
  | innodb_io_capacity = 200         # For SSD storage                     |
  | innodb_io_capacity_max = 2000    # For SSD storage                     |
  |                                                                        |
  | # Logging                                                              |
  | slow_query_log = 1                                                     |
  | long_query_time = 1              # Log queries > 1 second              |
  | log_queries_not_using_indexes = 1                                      |
  | general_log = 0                  # Enable for debugging only           |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  SIZING GUIDELINES
  =================

  +------------------------------------------------------------------------+
  | System RAM | buffer_pool    | log_file_size   | key_buf  | Connections |
  +------------+----------------+-----------------+----------+-------------+
  | 8 GB       | 2 GB           | 512 MB          | 128 MB   | 100         |
  | 16 GB      | 4 GB           | 1 GB            | 256 MB   | 200         |
  | 32 GB      | 8 GB           | 2 GB            | 512 MB   | 400         |
  | 64 GB      | 16 GB          | 4 GB            | 1 GB     | 500         |
  +------------+----------------+-----------------+----------+-------------+

  --------------------------------------------------------------------------

  REPLICATION TUNING
  ==================

  For HA clusters with MariaDB replication:

  +------------------------------------------------------------------------+
  | # Primary server settings                                              |
  | server-id = 1                                                          |
  | log_bin = /var/log/mysql/mariadb-bin                                   |
  | binlog_format = ROW                                                    |
  | sync_binlog = 1                  # Durability setting                  |
  | gtid_strict_mode = 1             # Enable strict GTID mode             |
  |                                                                        |
  | # Replica server settings                                              |
  | server-id = 2                                                          |
  | relay_log = /var/log/mysql/relay-bin                                   |
  | read_only = 1                                                          |
  | log_slave_updates = 1                                                  |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  INNODB OPTIMIZATION
  ====================

  +------------------------------------------------------------------------+
  | # InnoDB settings for high-transaction workloads                       |
  | innodb_flush_method = O_DIRECT                                         |
  | innodb_doublewrite = 1                                                 |
  | innodb_thread_concurrency = 0    # Auto-detect                         |
  | innodb_read_io_threads = 4                                             |
  | innodb_write_io_threads = 4                                            |
  | innodb_autoinc_lock_mode = 2     # Interleaved mode                    |
  | innodb_buffer_pool_instances = 8 # For large buffer pools              |
  | innodb_purge_threads = 4                                               |
  | innodb_stats_on_metadata = 0     # Disable for performance             |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  CONNECTION POOLING
  ==================

  For high-concurrency environments, consider ProxySQL:

  /etc/proxysql.cnf:
  +------------------------------------------------------------------------+
  | datadir="/var/lib/proxysql"                                            |
  |                                                                        |
  | admin_variables=                                                       |
  | {                                                                      |
  |     admin_credentials="admin:admin"                                    |
  |     mysql_ifaces="127.0.0.1:6032"                                      |
  | }                                                                      |
  |                                                                        |
  | mysql_variables=                                                       |
  | {                                                                      |
  |     threads=4                                                          |
  |     max_connections=2048                                               |
  |     default_query_delay=0                                              |
  |     interfaces="0.0.0.0:6033"                                          |
  |     server_version="10.6.12-MariaDB"                                   |
  | }                                                                      |
  |                                                                        |
  | mysql_servers=                                                         |
  | (                                                                      |
  |     { address="127.0.0.1", port=3306, hostgroup=0 }                    |
  | )                                                                      |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### Database Performance Monitoring

```
+===============================================================================+
|                   DATABASE PERFORMANCE MONITORING                             |
+===============================================================================+

  KEY METRICS TO MONITOR
  ======================

  +------------------------------------------------------------------------+
  | Metric                    | Warning      | Critical     | Query        |
  +---------------------------+--------------+--------------+--------------+
  | Active connections        | > 80%        | > 95%        | PROCESSLIST  |
  | Connection wait time      | > 100ms      | > 500ms      | PROCESSLIST  |
  | Buffer pool hit ratio     | < 95%        | < 90%        | GLOBAL_STAT  |
  | Transaction rate          | Trend        | Trend        | GLOBAL_STAT  |
  | Replication lag           | > 1 MB       | > 10 MB      | SLAVE STATUS |
  | Table fragmentation       | > 10%        | > 20%        | TABLE_STAT   |
  | Table bloat               | > 20%        | > 40%        | Custom       |
  | Long-running queries      | > 5 min      | > 15 min     | PROCESSLIST  |
  +---------------------------+--------------+--------------+--------------+

  --------------------------------------------------------------------------

  MONITORING QUERIES
  ==================

  Buffer Pool Hit Ratio:
  +------------------------------------------------------------------------+
  | SELECT                                                                 |
  |   (1 - (Innodb_buffer_pool_reads / Innodb_buffer_pool_read_requests))  |
  |   * 100 AS buffer_pool_hit_ratio                                       |
  | FROM (SELECT VARIABLE_VALUE AS Innodb_buffer_pool_reads                |
  |       FROM information_schema.GLOBAL_STATUS                            |
  |       WHERE VARIABLE_NAME = 'Innodb_buffer_pool_reads') r,             |
  |      (SELECT VARIABLE_VALUE AS Innodb_buffer_pool_read_requests        |
  |       FROM information_schema.GLOBAL_STATUS                            |
  |       WHERE VARIABLE_NAME = 'Innodb_buffer_pool_read_requests') rr;    |
  | -- Should be > 95% for good performance                                |
  +------------------------------------------------------------------------+

  Connection Statistics:
  +------------------------------------------------------------------------+
  | SELECT                                                                 |
  |   command AS state,                                                    |
  |   COUNT(*) as connections,                                             |
  |   MAX(time) as longest_duration_sec                                    |
  | FROM information_schema.processlist                                    |
  | GROUP BY command;                                                      |
  +------------------------------------------------------------------------+

  Table Fragmentation:
  +------------------------------------------------------------------------+
  | SELECT                                                                 |
  |   table_schema, table_name,                                            |
  |   data_free,                                                           |
  |   data_length,                                                         |
  |   ROUND(data_free * 100.0 / NULLIF(data_length + data_free, 0), 2)     |
  |     AS fragmentation_ratio                                             |
  | FROM information_schema.tables                                         |
  | WHERE data_free > 1000000                                              |
  | ORDER BY fragmentation_ratio DESC                                      |
  | LIMIT 20;                                                              |
  +------------------------------------------------------------------------+

  Slow Query Log Analysis:
  +------------------------------------------------------------------------+
  | -- Enable slow query log first:                                        |
  | -- SET GLOBAL slow_query_log = 1;                                      |
  | -- SET GLOBAL long_query_time = 1;                                     |
  |                                                                        |
  | -- Then analyze with mysqldumpslow:                                    |
  | -- mysqldumpslow -s t /var/log/mysql/mariadb-slow.log                  |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  INDEX OPTIMIZATION
  ==================

  Find Missing Indexes:
  +------------------------------------------------------------------------+
  | -- Use EXPLAIN to identify full table scans                            |
  | EXPLAIN SELECT * FROM your_table WHERE column = 'value';               |
  |                                                                        |
  | -- Check for tables with no indexes (except PRIMARY)                   |
  | SELECT table_schema, table_name                                        |
  | FROM information_schema.tables t                                       |
  | WHERE table_type = 'BASE TABLE'                                        |
  |   AND NOT EXISTS (                                                     |
  |     SELECT 1 FROM information_schema.statistics s                      |
  |     WHERE s.table_schema = t.table_schema                              |
  |       AND s.table_name = t.table_name                                  |
  |       AND s.index_name != 'PRIMARY'                                    |
  |   );                                                                   |
  +------------------------------------------------------------------------+

  Unused Indexes:
  +------------------------------------------------------------------------+
  | -- Enable userstat for index usage tracking                            |
  | -- SET GLOBAL userstat = 1;                                            |
  |                                                                        |
  | SELECT                                                                 |
  |   table_schema, table_name, index_name,                                |
  |   rows_read                                                            |
  | FROM information_schema.index_statistics                               |
  | WHERE rows_read = 0                                                    |
  |   AND index_name != 'PRIMARY'                                          |
  | ORDER BY table_schema, table_name;                                     |
  |                                                                        |
  | -- Consider dropping unused indexes to improve write performance       |
  +------------------------------------------------------------------------+

+===============================================================================+
```

---

## Advanced Troubleshooting

### System-Level Diagnostics

```
+===============================================================================+
|                   ADVANCED SYSTEM DIAGNOSTICS                                 |
+===============================================================================+

  PROCESS ANALYSIS
  ================

  Identify Resource-Intensive Processes:
  +------------------------------------------------------------------------+
  | # Top CPU consumers                                                    |
  | ps aux --sort=-%cpu | head -15                                         |
  |                                                                        |
  | # Top memory consumers                                                 |
  | ps aux --sort=-%mem | head -15                                         |
  |                                                                        |
  | # WALLIX-specific processes                                            |
  | ps aux | grep -E "(wab|wallix|mysql|mariadb)" | sort -k4 -rn           |
  |                                                                        |
  | # Process tree for WALLIX services                                     |
  | pstree -p $(pgrep -f wallix-bastion)                                   |
  +------------------------------------------------------------------------+

  Thread Analysis:
  +------------------------------------------------------------------------+
  | # Count threads per process                                            |
  | ps -eLf | grep wallix | wc -l                                          |
  |                                                                        |
  | # Thread states                                                        |
  | ps -eLo pid,tid,state,comm | grep wallix | sort | uniq -c              |
  |                                                                        |
  | # Stuck threads (D state = uninterruptible sleep)                      |
  | ps -eLo pid,tid,state,wchan,comm | grep -E "^.* D "                    |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  FILE DESCRIPTOR ANALYSIS
  ========================

  +------------------------------------------------------------------------+
  | # Current file descriptor usage                                        |
  | cat /proc/sys/fs/file-nr                                               |
  | # Output: allocated  free  max                                         |
  |                                                                        |
  | # File descriptors by process                                          |
  | for pid in $(pgrep -f wallix); do                                      |
  |   echo "PID $pid: $(ls /proc/$pid/fd 2>/dev/null | wc -l) fds"         |
  | done                                                                   |
  |                                                                        |
  | # Socket connections per process                                       |
  | for pid in $(pgrep -f wallix); do                                      |
  |   echo "PID $pid sockets:"                                             |
  |   ss -tnp | grep "pid=$pid"                                            |
  | done                                                                   |
  |                                                                        |
  | # If running out of file descriptors:                                  |
  | # 1. Check current limit: ulimit -n                                    |
  | # 2. Increase in /etc/security/limits.conf:                            |
  | #    wallix soft nofile 65536                                          |
  | #    wallix hard nofile 65536                                          |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  NETWORK TROUBLESHOOTING
  =======================

  Connection State Analysis:
  +------------------------------------------------------------------------+
  | # Connection states summary                                            |
  | ss -s                                                                  |
  |                                                                        |
  | # Detailed TCP connections                                             |
  | ss -tn | awk '{print $1}' | sort | uniq -c | sort -rn                  |
  |                                                                        |
  | # Connections to specific port (e.g., 22 for SSH)                      |
  | ss -tn state established '( dport = :22 or sport = :22 )'              |
  |                                                                        |
  | # TIME_WAIT accumulation (potential issue)                             |
  | ss -tn state time-wait | wc -l                                         |
  | # If high, consider tuning:                                            |
  | # net.ipv4.tcp_fin_timeout = 15                                        |
  | # net.ipv4.tcp_tw_reuse = 1                                            |
  +------------------------------------------------------------------------+

  Network Latency Testing:
  +------------------------------------------------------------------------+
  | # Measure latency to target                                            |
  | hping3 -S -p 22 -c 10 target-server                                    |
  |                                                                        |
  | # TCP connection time                                                  |
  | time timeout 5 bash -c 'cat < /dev/null > /dev/tcp/target-server/22'   |
  |                                                                        |
  | # Continuous monitoring                                                |
  | mtr --report --report-cycles 100 target-server                         |
  +------------------------------------------------------------------------+

  Packet Capture:
  +------------------------------------------------------------------------+
  | # Capture traffic for specific session                                 |
  | tcpdump -i eth0 host target-server -w /tmp/capture.pcap                |
  |                                                                        |
  | # Capture SSH traffic                                                  |
  | tcpdump -i eth0 port 22 -w /tmp/ssh-capture.pcap                       |
  |                                                                        |
  | # Capture with timing for latency analysis                             |
  | tcpdump -i eth0 -tt host target-server                                 |
  |                                                                        |
  | # Filter for connection issues (RST, SYN without ACK)                  |
  | tcpdump -i eth0 'tcp[tcpflags] & (tcp-rst) != 0'                       |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  MEMORY ANALYSIS
  ===============

  +------------------------------------------------------------------------+
  | # Memory overview                                                      |
  | free -h                                                                |
  |                                                                        |
  | # Detailed memory info                                                 |
  | cat /proc/meminfo | grep -E "(MemTotal|MemFree|MemAvail|Buffers|Cache)"|
  |                                                                        |
  | # Memory per WALLIX process                                            |
  | for pid in $(pgrep -f wallix); do                                      |
  |   name=$(cat /proc/$pid/comm 2>/dev/null)                              |
  |   mem=$(ps -o rss= -p $pid 2>/dev/null)                                |
  |   echo "$name ($pid): $((mem/1024)) MB"                                |
  | done                                                                   |
  |                                                                        |
  | # Memory mapping for specific process                                  |
  | pmap -x $(pgrep -f wallix-bastion | head -1)                           |
  |                                                                        |
  | # OOM killer candidates                                                |
  | for pid in $(pgrep -f wallix); do                                      |
  |   echo "$pid: $(cat /proc/$pid/oom_score 2>/dev/null)"                 |
  | done                                                                   |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  DISK I/O ANALYSIS
  =================

  +------------------------------------------------------------------------+
  | # Real-time I/O statistics                                             |
  | iostat -xz 1 5                                                         |
  |                                                                        |
  | # I/O by process                                                       |
  | iotop -b -n 1 | head -20                                               |
  |                                                                        |
  | # Disk latency                                                         |
  | ioping -c 10 /var/lib/wallix                                           |
  |                                                                        |
  | # Check for I/O wait                                                   |
  | vmstat 1 5                                                             |
  | # Column 'wa' shows I/O wait percentage                                |
  |                                                                        |
  | # Identify I/O bottleneck                                              |
  | # High %util with low throughput = disk saturation                     |
  | # High await = I/O latency issues                                      |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### Application-Level Troubleshooting

```
+===============================================================================+
|                   APPLICATION TROUBLESHOOTING                                 |
+===============================================================================+

  SESSION DEBUGGING
  =================

  Enable Debug Logging:
  +------------------------------------------------------------------------+
  | # Temporary debug logging                                              |
  | wabadmin log-level set --component session-proxy --level DEBUG         |
  |                                                                        |
  | # Reproduce issue                                                      |
  |                                                                        |
  | # Capture logs                                                         |
  | tail -f /var/log/wallix/session-proxy.log | tee /tmp/debug.log         |
  |                                                                        |
  | # Reset log level after debugging                                      |
  | wabadmin log-level set --component session-proxy --level INFO          |
  +------------------------------------------------------------------------+

  Session Trace:
  +------------------------------------------------------------------------+
  | # Trace specific session                                               |
  | wabadmin session trace --session-id SES-123456                         |
  |                                                                        |
  | # Output includes:                                                     |
  | # - Authentication steps                                               |
  | # - Authorization checks                                               |
  | # - Credential retrieval                                               |
  | # - Connection establishment                                           |
  | # - Protocol negotiation                                               |
  | # - Timing for each step                                               |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  AUTHENTICATION DEBUGGING
  ========================

  LDAP Debugging:
  +------------------------------------------------------------------------+
  | # Test LDAP connectivity                                               |
  | ldapsearch -x -H ldaps://dc.company.com:636 \                          |
  |   -D "CN=wallix-svc,OU=Service,DC=company,DC=com" \                    |
  |   -W -b "DC=company,DC=com" \                                          |
  |   "(sAMAccountName=testuser)"                                          |
  |                                                                        |
  | # Test with SSL debugging                                              |
  | LDAPTLS_REQCERT=never ldapsearch -x -H ldaps://dc.company.com:636 \    |
  |   -D "CN=wallix-svc,OU=Service,DC=company,DC=com" \                    |
  |   -W -d 255 \                                                          |
  |   "(sAMAccountName=testuser)"                                          |
  |                                                                        |
  | # Check LDAP certificate                                               |
  | echo | openssl s_client -connect dc.company.com:636 2>/dev/null | \    |
  |   openssl x509 -noout -subject -dates                                  |
  +------------------------------------------------------------------------+

  RADIUS/MFA Debugging:
  +------------------------------------------------------------------------+
  | # Test RADIUS server                                                   |
  | radtest username password radius-server 1812 shared-secret             |
  |                                                                        |
  | # Verbose test                                                         |
  | radtest -x username password radius-server 1812 shared-secret          |
  |                                                                        |
  | # Check RADIUS server logs                                             |
  | # On FreeRADIUS:                                                       |
  | tail -f /var/log/freeradius/radius.log                                 |
  +------------------------------------------------------------------------+

  Kerberos Debugging:
  +------------------------------------------------------------------------+
  | # List Kerberos tickets                                                |
  | klist                                                                  |
  |                                                                        |
  | # Get ticket for testing                                               |
  | kinit username@REALM.COM                                               |
  |                                                                        |
  | # Test service ticket                                                  |
  | kvno host/target-server.company.com                                    |
  |                                                                        |
  | # Enable Kerberos debug                                                |
  | export KRB5_TRACE=/tmp/krb5.log                                        |
  | # Run authentication test                                              |
  | cat /tmp/krb5.log                                                      |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  PASSWORD ROTATION DEBUGGING
  ===========================

  +------------------------------------------------------------------------+
  | # Enable rotation debugging                                            |
  | wabadmin log-level set --component password-manager --level DEBUG      |
  |                                                                        |
  | # Trigger rotation manually                                            |
  | wabadmin account rotate <account_id> --verbose                         |
  |                                                                        |
  | # Check rotation connector                                             |
  | wabadmin connector test --connector-id <connector_id> \                |
  |   --target <target> --account <account>                                |
  |                                                                        |
  | # View rotation queue                                                  |
  | wabadmin rotation --queue --verbose                                    |
  |                                                                        |
  | # Check connector configuration                                        |
  | wabadmin connector show <connector_id> --config                        |
  +------------------------------------------------------------------------+

  Common Rotation Issues:
  +------------------------------------------------------------------------+
  | Error                         | Possible Cause          | Solution     |
  +-------------------------------+-------------------------+--------------+
  | Connection timeout            | Network/firewall        | Check route  |
  | Authentication failed         | Bad rotation creds      | Update creds |
  | Permission denied             | Insufficient privileges | Grant access |
  | Password complexity failed    | Policy mismatch         | Adjust policy|
  | Account locked                | Too many attempts       | Unlock acct  |
  | Protocol error                | Connector mismatch      | Verify conn. |
  +-------------------------------+-------------------------+--------------+

  --------------------------------------------------------------------------

  CLUSTER TROUBLESHOOTING
  =======================

  +------------------------------------------------------------------------+
  | # Detailed cluster status                                              |
  | crm status full                                                        |
  |                                                                        |
  | # Resource history                                                     |
  | crm resource history <resource_name>                                   |
  |                                                                        |
  | # Check for failures                                                   |
  | crm_failcount -r <resource_name> -N <node_name> -G                     |
  |                                                                        |
  | # View cluster configuration                                           |
  | crm configure show                                                     |
  |                                                                        |
  | # Cluster verification                                                 |
  | crm_verify -L -V                                                       |
  |                                                                        |
  | # Check corosync membership                                            |
  | corosync-cmapctl | grep members                                        |
  |                                                                        |
  | # Check quorum status                                                  |
  | corosync-quorumtool -s                                                 |
  |                                                                        |
  | # Network connectivity between nodes                                   |
  | corosync-cfgtool -s                                                    |
  +------------------------------------------------------------------------+

  Resource Recovery:
  +------------------------------------------------------------------------+
  | # Clear resource failures                                              |
  | crm resource cleanup <resource_name>                                   |
  |                                                                        |
  | # Force resource restart                                               |
  | crm resource restart <resource_name>                                   |
  |                                                                        |
  | # Move resource to specific node                                       |
  | crm resource move <resource_name> <node_name>                          |
  |                                                                        |
  | # Clear location constraint after move                                 |
  | crm resource clear <resource_name>                                     |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### Diagnostic Data Collection

```
+===============================================================================+
|                   DIAGNOSTIC DATA COLLECTION                                  |
+===============================================================================+

  SUPPORT BUNDLE GENERATION
  =========================

  +------------------------------------------------------------------------+
  | # Generate comprehensive diagnostic bundle                             |
  | wabadmin support-bundle --output /tmp/wallix-diag-$(date +%Y%m%d).tar.gz
  |                                                                        |
  | # Bundle includes:                                                     |
  | # - Configuration files (sanitized)                                    |
  | # - Recent logs (last 7 days)                                          |
  | # - System information                                                 |
  | # - Database statistics                                                |
  | # - Network configuration                                              |
  | # - Cluster status (if applicable)                                     |
  | # - License information                                                |
  +------------------------------------------------------------------------+

  Manual Collection Script:
  +------------------------------------------------------------------------+
  | #!/bin/bash                                                            |
  | # /opt/scripts/collect-diagnostics.sh                                  |
  |                                                                        |
  | DIAG_DIR="/tmp/wallix-diag-$(date +%Y%m%d-%H%M%S)"                     |
  | mkdir -p "$DIAG_DIR"                                                   |
  |                                                                        |
  | # System info                                                          |
  | uname -a > "$DIAG_DIR/system-info.txt"                                 |
  | cat /etc/os-release >> "$DIAG_DIR/system-info.txt"                     |
  | uptime >> "$DIAG_DIR/system-info.txt"                                  |
  |                                                                        |
  | # Resource usage                                                       |
  | free -h > "$DIAG_DIR/memory.txt"                                       |
  | df -h > "$DIAG_DIR/disk.txt"                                           |
  | top -bn1 | head -30 > "$DIAG_DIR/top.txt"                              |
  | ps auxf > "$DIAG_DIR/processes.txt"                                    |
  |                                                                        |
  | # Network                                                              |
  | ss -tuln > "$DIAG_DIR/listening-ports.txt"                             |
  | ss -tn > "$DIAG_DIR/connections.txt"                                   |
  | ip addr > "$DIAG_DIR/ip-config.txt"                                    |
  | ip route > "$DIAG_DIR/routes.txt"                                      |
  |                                                                        |
  | # Services                                                             |
  | systemctl status wallix-bastion > "$DIAG_DIR/service-status.txt" 2>&1  |
  | wabadmin status >> "$DIAG_DIR/service-status.txt" 2>&1                 |
  |                                                                        |
  | # Logs (last 1000 lines each)                                          |
  | tail -1000 /var/log/wallix/application.log > "$DIAG_DIR/app.log"       |
  | tail -1000 /var/log/wallix/session-proxy.log > "$DIAG_DIR/proxy.log"   |
  | journalctl -u wallix-bastion --since "1 hour ago" > "$DIAG_DIR/jrnl.log"
  |                                                                        |
  | # Database (if accessible)                                             |
  | sudo mysql -e "SELECT VERSION();" > "$DIAG_DIR/db.txt" 2>&1            |
  | sudo mysql -e "SHOW PROCESSLIST;" \                                    |
  |   >> "$DIAG_DIR/db.txt" 2>&1                                           |
  |                                                                        |
  | # Cluster (if applicable)                                              |
  | crm status > "$DIAG_DIR/cluster.txt" 2>&1 || true                      |
  |                                                                        |
  | # Create archive                                                       |
  | tar -czvf "$DIAG_DIR.tar.gz" -C /tmp "$(basename $DIAG_DIR)"           |
  | rm -rf "$DIAG_DIR"                                                     |
  |                                                                        |
  | echo "Diagnostic bundle created: $DIAG_DIR.tar.gz"                     |
  +------------------------------------------------------------------------+

+===============================================================================+
```

---

## Additional Troubleshooting Guides

For specific troubleshooting scenarios, see these detailed guides:

| Guide | Description |
|-------|-------------|
| [Network Troubleshooting](./network-troubleshooting.md) | VIP, firewall, DNS, connectivity issues |
| [SIEM Troubleshooting](./siem-troubleshooting.md) | Log forwarding, CEF format, Splunk/ELK issues |
| [LDAP/AD Troubleshooting](./ldap-ad-troubleshooting.md) | LDAP connectivity, authentication, group sync |
| [Certificate Management](./certificate-management.md) | SSL/TLS certificates, renewal, troubleshooting |

---

## Next Steps

Continue to [13 - Best Practices](../13-best-practices/README.md) for operational recommendations.
