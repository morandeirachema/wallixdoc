# Operational Incident Playbooks

## "It's 2 AM and Something is Broken" Guide

Real-world scenarios with step-by-step resolution procedures.

---

## Scenario 1: WALLIX Service is Down

### Symptoms
- Users report "cannot connect" or "page not loading"
- Monitoring alerts for service unavailability
- Web UI returns 502/503 errors

### Immediate Actions (First 5 minutes)

```bash
# 1. Check service status
systemctl status wallix-pam4ot

# 2. Check for obvious errors
journalctl -u wallix-pam4ot --since "10 min ago" | tail -50

# 3. Check disk space (common cause)
df -h

# 4. Check memory
free -h

# 5. Check database connectivity
sudo mysql -e "SELECT 1;"
```

### Decision Tree

```
+===============================================================================+
|                   SERVICE DOWN DECISION TREE                                 |
+===============================================================================+

  Service status?
  |
  +-- "Active (running)" but users can't connect
  |   |
  |   +-- Check network: ping wallix-server
  |   +-- Check ports: ss -tuln | grep -E "(443|22|3389)"
  |   +-- Check firewall: iptables -L -n
  |   +-- Check load balancer (if applicable)
  |
  +-- "Failed" or "Inactive"
  |   |
  |   +-- Check logs: journalctl -u wallix-pam4ot -n 100
  |   |
  |   +-- Common errors:
  |       |
  |       +-- "Database connection failed"
  |       |   --> Go to Scenario 2: Database Issues
  |       |
  |       +-- "Cannot bind to port"
  |       |   --> Check: ss -tuln | grep <port>
  |       |   --> Kill process using port or change config
  |       |
  |       +-- "License expired"
  |       |   --> Contact WALLIX support
  |       |   --> Check: wabadmin license-info
  |       |
  |       +-- "Configuration error"
  |       |   --> Check: wabadmin config --verify
  |       |   --> Restore last known good config
  |
  +-- Service won't start after restart
      |
      +-- Try: systemctl restart wallix-pam4ot
      +-- If fails: Check disk space, memory, database
      +-- If still fails: Boot to safe mode / restore backup

+===============================================================================+
```

### Resolution Steps

**If disk full:**
```bash
# Find large files
du -h /var/lib/wallix/ | sort -rh | head -20
du -h /var/log/wallix/ | sort -rh | head -20

# Quick fix: Remove old logs
find /var/log/wallix/ -name "*.log.*" -mtime +7 -delete

# Quick fix: Archive old recordings
find /var/lib/wallix/recordings/ -mtime +30 -exec mv {} /backup/ \;

# Restart service
systemctl restart wallix-pam4ot
```

**If memory exhausted:**
```bash
# Check what's using memory
ps aux --sort=-%mem | head -10

# Restart service (frees memory)
systemctl restart wallix-pam4ot

# If recurring, increase RAM or optimize config
```

**If configuration corrupt:**
```bash
# Verify configuration
wabadmin config --verify

# Restore from backup
wabadmin config --restore /var/backup/wallix/config-YYYYMMDD.tar.gz

# Restart service
systemctl restart wallix-pam4ot
```

### Post-Incident

1. Document incident timeline
2. Review logs for root cause
3. Update monitoring to catch earlier
4. Consider preventive measures

---

## Scenario 2: Database Issues

### Symptoms
- Service starts but users can't login
- "Database connection error" in logs
- Session data not saving

### Immediate Actions

```bash
# 1. Check MariaDB status
systemctl status mariadb

# 2. Check MariaDB logs
tail -100 /var/log/mysql/error.log

# 3. Test database connectivity
sudo mysql -e "SELECT 1;"

# 4. Check database connections
sudo mysql -e "SHOW STATUS LIKE 'Threads_connected';"
```

### Decision Tree

```
+===============================================================================+
|                   DATABASE ISSUE DECISION TREE                               |
+===============================================================================+

  MariaDB status?
  |
  +-- "Active (running)"
  |   |
  |   +-- Can connect with mysql?
  |       |
  |       +-- Yes --> Check WALLIX DB user permissions
  |       |           Check max_connections limit
  |       |           Check disk space for DB
  |       |
  |       +-- No --> Check mysql authentication
  |                  Check MariaDB logs for errors
  |
  +-- "Failed" or "Inactive"
  |   |
  |   +-- Check logs: journalctl -u mariadb
  |   |
  |   +-- Common errors:
  |       |
  |       +-- "No space left on device"
  |       |   --> Free disk space
  |       |   --> Move binary log files if necessary
  |       |
  |       +-- "Could not open file"
  |       |   --> Check permissions
  |       |   --> Check for corruption
  |       |
  |       +-- "InnoDB recovery mode"
  |       |   --> Database crashed, check consistency
  |       |   --> May need to restore from backup

+===============================================================================+
```

### Resolution Steps

**If too many connections:**
```bash
# Check current connections
sudo mysql -e "
SELECT user, count(*)
FROM information_schema.processlist
GROUP BY user
ORDER BY count(*) DESC;"

# Kill idle connections
sudo mysql -e "
SELECT CONCAT('KILL ', id, ';')
FROM information_schema.processlist
WHERE command = 'Sleep'
AND time > 3600;"

# Increase max_connections if needed (requires restart)
# Edit /etc/mysql/mariadb.conf.d/50-server.cnf: max_connections = 200
```

**If database won't start:**
```bash
# Check for lock files
ls -la /var/lib/mysql/*.pid

# Remove stale lock file (ONLY if MariaDB truly not running)
rm /var/lib/mysql/*.pid

# Start MariaDB
systemctl start mariadb

# If corruption suspected, try recovery
sudo mysql_upgrade --force
```

**If data corruption:**
```bash
# Stop WALLIX to prevent more writes
systemctl stop wallix-pam4ot

# Check database consistency
mysqldump wallix > /dev/null
# If fails, database is corrupted

# Restore from backup
systemctl stop mariadb
sudo mysql wallix < /var/backup/wallix/database.sql
systemctl start mariadb
systemctl start wallix-pam4ot
```

---

## Scenario 3: Users Can't Authenticate

### Symptoms
- Login fails with "Invalid credentials"
- MFA not working
- LDAP sync errors

### Immediate Actions

```bash
# 1. Check if local admin can login
# Try admin account in web UI

# 2. Check LDAP connectivity
ldapsearch -x -H ldaps://dc.company.com:636 \
  -D "CN=wallix-svc,OU=Service,DC=company,DC=com" \
  -W -b "DC=company,DC=com" "(sAMAccountName=testuser)"

# 3. Check authentication logs
grep -i "auth" /var/log/wallix/application.log | tail -50

# 4. Check NTP (for MFA)
timedatectl status
```

### Decision Tree

```
+===============================================================================+
|                   AUTHENTICATION FAILURE DECISION TREE                       |
+===============================================================================+

  Who is affected?
  |
  +-- ALL users (including local admin)
  |   |
  |   +-- Database issue --> Scenario 2
  |   +-- Service issue --> Scenario 1
  |
  +-- Only LDAP users
  |   |
  |   +-- Check LDAP server reachable
  |   +-- Check LDAP service account password
  |   +-- Check LDAP certificate (if LDAPS)
  |   +-- Check LDAP sync status
  |
  +-- Only MFA users
  |   |
  |   +-- Check NTP synchronization
  |   +-- Check RADIUS server (if used)
  |   +-- Check user's MFA device (resync?)
  |
  +-- Specific user only
      |
      +-- Check if account locked
      +-- Check if account expired
      +-- Check if password expired
      +-- Reset password and try again

+===============================================================================+
```

### Resolution Steps

**If LDAP service account expired:**
```bash
# Test with new password
ldapsearch -x -H ldaps://dc.company.com:636 \
  -D "CN=wallix-svc,OU=Service,DC=company,DC=com" \
  -w "NEW_PASSWORD" -b "DC=company,DC=com" "(sAMAccountName=testuser)"

# Update in WALLIX
# Configuration > Authentication > LDAP > Edit > Update Password
```

**If NTP out of sync (MFA failing):**
```bash
# Check time offset
chronyc tracking

# Force sync
chronyc makestep

# Verify
date
timedatectl status
```

**If user locked out:**
```bash
# Check account status (via Web UI or API)
wabadmin user show <username>

# Unlock account
wabadmin user unlock <username>

# Or reset failed login counter
# Configuration > Users > <user> > Reset Lockout
```

**Emergency: Allow local auth bypass**
```bash
# Enable local authentication fallback (temporary!)
# Configuration > Authentication > Settings > Enable Local Fallback

# After LDAP fixed, disable fallback
```

---

## Scenario 4: Sessions Failing to Connect

### Symptoms
- Users can login but sessions fail
- "Connection refused" or "Timeout" errors
- Some targets work, others don't

### Immediate Actions

```bash
# 1. Test connectivity from WALLIX to target
ping target-server
nc -zv target-server 22

# 2. Check session proxy logs
tail -100 /var/log/wallix/session-proxy.log | grep -i error

# 3. Check target account credentials
wabadmin account verify root@target-server

# 4. Test direct connection (from WALLIX server)
ssh root@target-server
```

### Decision Tree

```
+===============================================================================+
|                   SESSION FAILURE DECISION TREE                              |
+===============================================================================+

  How many targets affected?
  |
  +-- ALL targets
  |   |
  |   +-- Session proxy service issue
  |   +-- Network issue (WALLIX can't reach anything)
  |   +-- Firewall change blocking outbound
  |   +-- Check: systemctl status wallix-session-proxy
  |
  +-- Specific targets only
  |   |
  |   +-- Test network: ping target; nc -zv target 22
  |   |
  |   +-- If network OK:
  |       |
  |       +-- Check credentials: wabadmin account verify
  |       +-- Check service config (port, protocol)
  |       +-- Check target firewall
  |       +-- Check target service (sshd, RDP, etc.)
  |
  +-- One protocol only (e.g., all RDP fails)
      |
      +-- Protocol-specific proxy issue
      +-- Port blocked by firewall
      +-- Certificate issue (for RDP NLA)

+===============================================================================+
```

### Resolution Steps

**If credentials changed on target:**
```bash
# Update password in WALLIX
wabadmin account update root@target-server --password "NewPassword123!"

# Or trigger reconciliation
wabadmin account reconcile root@target-server

# Verify
wabadmin account verify root@target-server
```

**If target firewall blocking:**
```bash
# From WALLIX server, test ports
nc -zv target-server 22
nc -zv target-server 3389

# Ask network team to check firewall rules
# WALLIX IP should be allowed to target on required ports
```

**If SSH host key changed:**
```bash
# Check for host key error in logs
grep "Host key verification" /var/log/wallix/session-proxy.log

# Update known hosts (careful - verify this is expected!)
ssh-keygen -R target-server
ssh-keyscan target-server >> /etc/ssh/ssh_known_hosts
```

---

## Scenario 5: Cluster Failover Issues

### Symptoms
- Primary node failed
- Standby not taking over
- Split-brain situation

### Immediate Actions

```bash
# 1. Check cluster status
crm status

# 2. Check quorum
corosync-quorumtool -s

# 3. Check network between nodes
ping node2
corosync-cfgtool -s

# 4. Check for split-brain
# Are both nodes claiming to be primary?
```

### Decision Tree

```
+===============================================================================+
|                   CLUSTER FAILURE DECISION TREE                              |
+===============================================================================+

  What does 'crm status' show?
  |
  +-- "OFFLINE" node
  |   |
  |   +-- Check if node is physically running
  |   +-- Check network between nodes
  |   +-- Check corosync: systemctl status corosync
  |   +-- Check pacemaker: systemctl status pacemaker
  |
  +-- Resources "FAILED"
  |   |
  |   +-- Check which resource failed
  |   +-- Check resource logs
  |   +-- Clear failure: crm resource cleanup <resource>
  |   +-- If recurring, investigate root cause
  |
  +-- Split-brain (both nodes primary)
  |   |
  |   +-- CRITICAL: Stop one node immediately
  |   +-- Stop: crm node standby <node2>
  |   +-- Investigate network partition cause
  |   +-- Reconcile data before bringing back
  |
  +-- No quorum
      |
      +-- Need majority of nodes
      +-- If truly only one node left:
      +-- Consider: crm configure property no-quorum-policy=ignore
      +-- (Temporary for emergency!)

+===============================================================================+
```

### Resolution Steps

**If node won't join cluster:**
```bash
# On failed node, restart cluster services
systemctl restart corosync
systemctl restart pacemaker

# Check node status
crm node status

# If still offline, check corosync
corosync-cmapctl | grep members
```

**If resource won't start:**
```bash
# Check resource status
crm resource status <resource>

# View failure reason
crm resource failcount <resource> show

# Clear failures and retry
crm resource cleanup <resource>

# If still fails, check resource configuration
crm configure show <resource>
```

**If split-brain detected:**
```bash
# CRITICAL: This can cause data corruption!

# 1. Identify which node has latest data
# Check MariaDB binary log position on both nodes

# 2. Stop cluster on one node
crm node standby node2

# 3. Verify remaining node is fully operational

# 4. Before bringing node2 back:
#    - Resync database from primary
#    - Verify data consistency

# 5. Rejoin node
crm node online node2
```

---

## Scenario 6: Password Rotation Failures

### Symptoms
- Multiple accounts failing to rotate
- Stale passwords in vault
- Compliance alerts

### Immediate Actions

```bash
# 1. Check rotation status
wabadmin rotation --status
wabadmin rotation --failed

# 2. Check specific account
wabadmin account show root@target-server

# 3. Test connectivity to target
wabadmin account verify root@target-server

# 4. Check rotation logs
grep -i rotation /var/log/wallix/password-manager.log | tail -50
```

### Resolution Steps

**If target unreachable:**
```bash
# Verify network
ping target-server
nc -zv target-server 22

# If target is down, rotation will fail
# Mark for later retry:
wabadmin rotation --schedule root@target-server --delay 4h
```

**If credentials incorrect:**
```bash
# Someone changed password outside WALLIX

# Option 1: Get current password, update WALLIX
wabadmin account update root@target-server --password "CurrentPassword123!"

# Option 2: Use reconciliation account
wabadmin account reconcile root@target-server

# Retry rotation
wabadmin account rotate root@target-server
```

**If password policy mismatch:**
```bash
# Target rejects password (complexity requirements)

# Check WALLIX password policy
wabadmin policy show <policy-name>

# Update policy to match target requirements
# Configuration > Password Policies > Edit

# Retry rotation
wabadmin account rotate root@target-server
```

---

## Scenario 7: Session Recording Issues

### Symptoms
- Recordings not being created
- Playback not working
- Storage filling up

### Immediate Actions

```bash
# 1. Check recording storage
df -h /var/lib/wallix/recordings/

# 2. Check recent recordings exist
ls -la /var/lib/wallix/recordings/ | tail -20

# 3. Check recording service
systemctl status wallix-recording

# 4. Check recording logs
tail -50 /var/log/wallix/recording.log
```

### Resolution Steps

**If storage full:**
```bash
# Find oldest recordings
ls -la /var/lib/wallix/recordings/ | head -20

# Archive old recordings
find /var/lib/wallix/recordings/ -mtime +90 -exec mv {} /archive/ \;

# Or delete if retention policy allows
find /var/lib/wallix/recordings/ -mtime +365 -delete

# Restart recording service
systemctl restart wallix-recording
```

**If playback not working:**
```bash
# Check recording file exists
ls -la /var/lib/wallix/recordings/<session-id>/

# Check file permissions
stat /var/lib/wallix/recordings/<session-id>/*

# Check playback service
systemctl status wallix-playback
```

---

## Scenario 8: Emergency Access Needed

### Symptoms
- Critical system needs access
- WALLIX is completely unavailable
- No time to troubleshoot

### Emergency Procedure

```
+===============================================================================+
|                   EMERGENCY ACCESS PROCEDURE                                 |
+===============================================================================+

  *** FOLLOW ONLY IF WALLIX COMPLETELY UNAVAILABLE ***

  1. AUTHORIZATION
     +------------------------------------------------------------------+
     | Call emergency authorization contact:                            |
     | - Primary: [Name] [Phone]                                        |
     | - Secondary: [Name] [Phone]                                      |
     | - Escalation: [Name] [Phone]                                     |
     |                                                                  |
     | Document: Ticket#, Approver Name, Time, Reason                   |
     +------------------------------------------------------------------+

  2. RETRIEVE EMERGENCY CREDENTIALS
     +------------------------------------------------------------------+
     | Location: [Physical safe / Password manager / Sealed envelope]   |
     |                                                                  |
     | Two-person rule: Both must be present to access                  |
     |                                                                  |
     | Log retrieval: Sign log book with time and reason                |
     +------------------------------------------------------------------+

  3. ACCESS TARGET DIRECTLY
     +------------------------------------------------------------------+
     | ssh -o LogLevel=VERBOSE root@critical-server 2>&1 | tee ~/emergency.log
     |                                                                  |
     | Document EVERY command you run                                   |
     +------------------------------------------------------------------+

  4. AFTER EMERGENCY
     +------------------------------------------------------------------+
     | [ ] Change password immediately after use                        |
     | [ ] Update WALLIX with new password when available               |
     | [ ] Write incident report                                        |
     | [ ] Review why WALLIX was unavailable                            |
     | [ ] Improve DR procedures                                        |
     +------------------------------------------------------------------+

+===============================================================================+
```

---

## Scenario 9: Suspected Security Breach

### Symptoms
- Unusual login activity
- Unauthorized session attempts
- SIEM alert for suspicious behavior

### Immediate Actions

```bash
# 1. DO NOT alert the attacker - gather evidence first

# 2. Check active sessions
wabadmin sessions --status active

# 3. Check recent authentication
wabadmin audit --type auth --since "1 hour ago"

# 4. Check specific user activity
wabadmin audit --user <suspicious-user> --since "24 hours ago"
```

### Decision Tree

```
+===============================================================================+
|                   SECURITY INCIDENT DECISION TREE                            |
+===============================================================================+

  What type of suspicious activity?
  |
  +-- Failed logins from unknown IP
  |   |
  |   +-- Block IP at firewall
  |   +-- Check if any succeeded
  |   +-- Review account targeted
  |   +-- Enable additional monitoring
  |
  +-- Successful login from unusual location
  |   |
  |   +-- Verify with user (call them!)
  |   +-- If unauthorized:
  |       +-- Terminate session immediately
  |       +-- Disable account
  |       +-- Rotate all accessed credentials
  |       +-- Forensic review of session recording
  |
  +-- Unusual commands in session
  |   |
  |   +-- Review session recording
  |   +-- Terminate session if ongoing threat
  |   +-- Determine what was accessed/modified
  |   +-- Incident response per policy
  |
  +-- Credential exfiltration suspected
      |
      +-- Terminate ALL active sessions
      +-- Disable suspected accounts
      +-- Rotate ALL credentials immediately
      +-- Full security audit

+===============================================================================+
```

### Resolution Steps

**Terminate suspicious session:**
```bash
# Find session ID
wabadmin sessions --status active

# Terminate immediately
wabadmin session kill <session-id> --reason "Security incident"
```

**Disable compromised account:**
```bash
# Disable user
wabadmin user disable <username>

# Force logout from all sessions
wabadmin sessions --user <username> --kill-all
```

**Export evidence:**
```bash
# Export audit logs
wabadmin audit --user <username> --since "7 days ago" \
  --output /forensics/audit-<username>-$(date +%Y%m%d).json

# Export session recordings
wabadmin recordings --user <username> --since "7 days ago" \
  --copy-to /forensics/recordings/
```

---

## Scenario 10: Performance Degradation

### Symptoms
- Sessions slow to connect
- Web UI sluggish
- High CPU/memory usage

### Immediate Actions

```bash
# 1. Check system resources
top -bn1 | head -20

# 2. Check disk I/O
iostat -x 1 5

# 3. Check active connections
ss -s
wabadmin sessions --status active --count

# 4. Check database performance
sudo mysql -e "SHOW STATUS LIKE 'Threads_connected';"
```

### Resolution Steps

**If too many sessions:**
```bash
# Check session count vs capacity
wabadmin sessions --status active --count

# If at capacity, consider:
# - Terminate idle sessions
# - Scale up hardware
# - Add cluster node
```

**If database slow:**
```bash
# Check slow queries
sudo mysql -e "
SELECT id, user, host, db, time, state, info
FROM information_schema.processlist
WHERE command != 'Sleep'
ORDER BY time DESC
LIMIT 10;"

# Check if optimization needed
sudo mysql wallix -e "
SELECT table_name, data_free
FROM information_schema.tables
WHERE table_schema = 'wallix' AND data_free > 10000000
ORDER BY data_free DESC;"

# Run optimization if needed
sudo mysql wallix -e "OPTIMIZE TABLE users, sessions, audit_log;"
```

---

## Quick Reference: Emergency Commands

```bash
# Service control
systemctl status wallix-pam4ot
systemctl restart wallix-pam4ot
systemctl stop wallix-pam4ot

# Session management
wabadmin sessions --status active
wabadmin session kill <id>
wabadmin sessions --kill-all --confirm

# User management
wabadmin user disable <username>
wabadmin user unlock <username>

# Account management
wabadmin account verify <account>
wabadmin account rotate <account>

# Cluster management
crm status
crm resource cleanup <resource>
crm node standby <node>

# Logs
journalctl -u wallix-pam4ot --since "1 hour ago"
tail -f /var/log/wallix/application.log
```

---

<p align="center">
  <a href="./README.md">Incident Response</a> •
  <a href="../12-troubleshooting/README.md">Troubleshooting</a> •
  <a href="../30-operational-runbooks/README.md">Runbooks</a>
</p>
