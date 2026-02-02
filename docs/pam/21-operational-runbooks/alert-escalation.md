# Alert Escalation Procedures

## Response Procedures Linked to Monitoring Alerts

This document defines response procedures for each alert type and escalation paths.

---

## Alert Severity Definitions

```
+===============================================================================+
|                         ALERT SEVERITY LEVELS                                 |
+===============================================================================+

  CRITICAL (P1)                    HIGH (P2)
  =============                    =========
  - Service down                   - Degraded performance
  - Data loss risk                 - Redundancy lost
  - Security breach                - Approaching capacity
  - Response: 15 min               - Response: 1 hour

  MEDIUM (P3)                      LOW (P4)
  ===========                      ========
  - Minor degradation              - Informational
  - Non-critical failure           - Scheduled maintenance
  - Response: 4 hours              - Response: Next business day

+===============================================================================+
```

---

## Alert Response Matrix

| Alert | Severity | Response Time | Primary | Escalation |
|-------|----------|---------------|---------|------------|
| WALLIX BastionNodeDown | Critical | 15 min | On-call SRE | OT Manager |
| MariaDBDown | Critical | 15 min | DBA On-call | OT Manager |
| VIPNotResponding | Critical | 15 min | Network Team | SRE Lead |
| HighCPU (>90%) | High | 1 hour | On-call SRE | SRE Lead |
| HighMemory (>90%) | High | 1 hour | On-call SRE | SRE Lead |
| DiskSpaceCritical (<10%) | High | 1 hour | On-call SRE | Storage Team |
| ReplicationLag (>5min) | High | 1 hour | DBA On-call | SRE Lead |
| AuthenticationFailures (>10/5m) | High | 1 hour | Security | SOC Lead |
| CertificateExpiring (<7d) | Medium | 4 hours | On-call SRE | Security |
| BackupFailed | Medium | 4 hours | On-call SRE | DBA On-call |

---

## Alert: WALLIX BastionNodeDown

### Definition
One or more WALLIX Bastion nodes are not responding to health checks.

### Immediate Actions (0-5 minutes)

```bash
# Step 1: Verify alert is real
ping wallix-node1.company.com
curl -sk https://wallix-node1.company.com/

# Step 2: Check if VIP is still responding
curl -sk https://wallix.company.com/
# If VIP works, HA is functioning

# Step 3: Check cluster status
ssh admin@wallix-node2 "pcs status"
```

### Investigation (5-15 minutes)

```bash
# If node unreachable via network:
# - Check VM console (vSphere/Hyper-V)
# - Check physical server (if bare metal)
# - Check network switch ports

# If node reachable but service down:
ssh admin@wallix-node1

# Check service status
systemctl status wallix-bastion
journalctl -u wallix-bastion --since "10 minutes ago"

# Check system resources
top -bn1 | head -20
df -h
free -m
```

### Resolution Actions

**Service crashed:**
```bash
systemctl restart wallix-bastion
systemctl status wallix-bastion
```

**Out of memory:**
```bash
# Identify memory hog
ps aux --sort=-%mem | head -10

# Clear session cache if needed
wabadmin cache clear

# Restart service
systemctl restart wallix-bastion
```

**Disk full:**
```bash
# Find large files
du -sh /var/wab/* | sort -h

# Clear old recordings (if policy allows)
wabadmin recording cleanup --older-than 90d
```

### Escalation

| Time | Action |
|------|--------|
| 0 min | On-call SRE begins investigation |
| 15 min | If not resolved, escalate to SRE Lead |
| 30 min | If not resolved, escalate to OT Manager |
| 60 min | If not resolved, activate incident commander |

---

## Alert: MariaDBDown

### Definition
MariaDB database is not responding on one or both nodes.

### Immediate Actions

```bash
# Check database status
systemctl status mariadb
sudo mysql -e "SELECT 1;"

# Check if this is primary or replica
sudo mysql -e "SHOW SLAVE STATUS\G" | grep -E "Slave_IO_Running|Slave_SQL_Running"
# If both are Yes = replica, if command returns empty = primary
```

### Resolution Actions

**Service stopped:**
```bash
systemctl start mariadb
systemctl status mariadb
```

**Corrupt data files:**
```bash
# Check MariaDB logs
tail -100 /var/log/mysql/error.log

# If corruption detected on replica:
# Rebuild from primary
systemctl stop mariadb
rm -rf /var/lib/mysql/*
mariabackup --backup --target-dir=/tmp/backup --host=wallix-node1 --user=replicator --password=xxx
mariabackup --prepare --target-dir=/tmp/backup
mariabackup --copy-back --target-dir=/tmp/backup
chown -R mysql:mysql /var/lib/mysql
systemctl start mariadb
```

**Primary failed - promote replica:**
```bash
# On replica:
sudo mysql -e "STOP SLAVE; RESET SLAVE ALL;"

# Verify it's now primary
sudo mysql -e "SHOW SLAVE STATUS\G"
# Should return empty (no slave configured)
```

---

## Alert: HighCPU

### Definition
CPU usage exceeds 90% for more than 5 minutes.

### Investigation

```bash
# Identify CPU-consuming processes
top -bn1 | head -20
ps aux --sort=-%cpu | head -10

# Check for runaway sessions
wabadmin session list --status active

# Check for stuck jobs
wabadmin job list --status running
```

### Resolution Actions

**Too many concurrent sessions:**
```bash
# Check session count
wabadmin session count

# If above capacity, enable session limiting
wabadmin config set session.max_concurrent 50

# Identify heavy sessions
wabadmin session list --sort cpu
```

**Runaway process:**
```bash
# Identify and investigate
ps aux | grep [process-name]

# If safe to kill
kill -15 [PID]

# Force kill if needed
kill -9 [PID]
```

---

## Alert: DiskSpaceCritical

### Definition
Disk usage on /var/wab exceeds 90%.

### Immediate Actions

```bash
# Check disk usage
df -h /var/wab

# Find largest directories
du -sh /var/wab/* | sort -h | tail -10
```

### Resolution Actions

**Session recordings consuming space:**
```bash
# Check recording storage
du -sh /var/wab/recorded/

# Archive old recordings
wabadmin recording archive --older-than 30d --destination /backup/recordings/

# Clean up archived recordings (after backup verified)
wabadmin recording cleanup --older-than 90d --archived-only
```

**Log files consuming space:**
```bash
# Check log sizes
du -sh /var/log/wab*/*

# Rotate logs
logrotate -f /etc/logrotate.d/wallix-bastion

# Clean old logs
find /var/log -name "*.gz" -mtime +30 -delete
```

**Temporary files:**
```bash
# Clean temp files
rm -rf /var/wab/tmp/*
wabadmin cache clear
```

---

## Alert: ReplicationLag

### Definition
MariaDB replication lag exceeds threshold (default: 60 seconds).

### Investigation

```bash
# Check lag on primary
sudo mysql -e "SHOW SLAVE STATUS\G" | grep -E "(Slave_IO_Running|Slave_SQL_Running|Seconds_Behind_Master|Master_Log_File|Read_Master_Log_Pos)"

# Check network latency
ping wallix-node2 -c 10
```

### Resolution Actions

**Network congestion:**
```bash
# Check network throughput
iperf3 -c wallix-node2 -t 10

# If bandwidth issue, work with network team
```

**Replica under load:**
```bash
# Check replica CPU/IO
ssh wallix-node2 "top -bn1 | head -10"
ssh wallix-node2 "iostat -x 1 5"

# If replica overloaded, reduce queries
```

**Rebuild replica (if lag too large):**
```bash
# On replica:
systemctl stop mariadb
rm -rf /var/lib/mysql/*
mariabackup --backup --target-dir=/tmp/backup --host=wallix-node1 --user=replicator --password=xxx
mariabackup --prepare --target-dir=/tmp/backup
mariabackup --copy-back --target-dir=/tmp/backup
chown -R mysql:mysql /var/lib/mysql
systemctl start mariadb
```

---

## Alert: AuthenticationFailures

### Definition
More than 10 authentication failures in 5 minutes.

### Investigation

```bash
# Check recent failures
wabadmin audit search --type auth-failure --last 15m

# Identify source IPs
wabadmin audit search --type auth-failure --last 15m | \
  awk '{print $3}' | sort | uniq -c | sort -rn
```

### Resolution Actions

**Brute force attack:**
```bash
# Block offending IP
iptables -A INPUT -s [ATTACKER-IP] -j DROP

# Or via WALLIX Bastion
wabadmin blacklist add [ATTACKER-IP] --duration 24h

# Alert security team
```

**User account issue:**
```bash
# Check if specific user
wabadmin audit search --type auth-failure --user jadmin --last 15m

# Check user status
wabadmin user show jadmin

# Reset user if needed
wabadmin user unlock jadmin
```

**LDAP issue:**
```bash
# Test LDAP connectivity
wabadmin ldap test "LAB.LOCAL"

# Check if mass failures (LDAP down)
wabadmin ldap status
```

---

## Escalation Contact List

| Role | Primary | Phone | Backup | Phone |
|------|---------|-------|--------|-------|
| On-call SRE | ________ | ________ | ________ | ________ |
| SRE Lead | ________ | ________ | ________ | ________ |
| DBA On-call | ________ | ________ | ________ | ________ |
| Network Team | ________ | ________ | ________ | ________ |
| Security/SOC | ________ | ________ | ________ | ________ |
| OT Manager | ________ | ________ | ________ | ________ |

---

## Alert Notification Configuration

### Alertmanager Routes

```yaml
# /etc/alertmanager/alertmanager.yml
route:
  receiver: 'default'
  group_by: ['alertname', 'severity']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h

  routes:
    # Critical alerts - immediate
    - match:
        severity: critical
      receiver: 'critical-pagerduty'
      group_wait: 0s
      repeat_interval: 15m

    # High alerts - 1 hour
    - match:
        severity: high
      receiver: 'high-slack'
      repeat_interval: 1h

    # Security alerts
    - match:
        category: security
      receiver: 'security-team'

receivers:
  - name: 'default'
    email_configs:
      - to: 'ops@company.com'

  - name: 'critical-pagerduty'
    pagerduty_configs:
      - service_key: 'xxxxx'
        severity: critical

  - name: 'high-slack'
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/xxx/xxx/xxx'
        channel: '#wallix-alerts'

  - name: 'security-team'
    email_configs:
      - to: 'security@company.com'
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/xxx/xxx/xxx'
        channel: '#security-alerts'
```

---

## Post-Incident Review Template

```
POST-INCIDENT REVIEW
====================

Incident ID: ____________________
Date: ____________________
Duration: ____________________
Severity: ____________________

TIMELINE:
- Alert fired: __:__
- Acknowledged: __:__
- Investigation started: __:__
- Root cause identified: __:__
- Resolution applied: __:__
- Alert cleared: __:__

ROOT CAUSE:
____________________________________________
____________________________________________

RESOLUTION:
____________________________________________
____________________________________________

PREVENTION:
[ ] Monitoring improvement needed
[ ] Runbook update needed
[ ] Capacity planning needed
[ ] Training needed

ACTION ITEMS:
1. ________________________________________
2. ________________________________________
3. ________________________________________

SIGN-OFF:
- Incident responder: ______________ Date: ______
- Team lead: ______________ Date: ______
```

---

<p align="center">
  <a href="./README.md">← Back to Runbooks</a>
</p>
