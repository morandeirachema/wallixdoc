# Incident Response Playbooks

This section provides step-by-step playbooks for responding to security incidents involving WALLIX Bastion.

---

## Table of Contents

1. [Incident Classification](#incident-classification)
2. [Credential Compromise Response](#credential-compromise-response)
3. [Ransomware Attack Response](#ransomware-attack-response)
4. [Unauthorized Access Detection](#unauthorized-access-detection)
5. [Data Breach Response](#data-breach-response)
6. [Service Outage Response](#service-outage-response)
7. [Cluster Failure Recovery](#cluster-failure-recovery)
8. [Database Corruption Recovery](#database-corruption-recovery)
9. [Certificate Compromise Response](#certificate-compromise-response)
10. [Forensics & Evidence Preservation](#forensics--evidence-preservation)
11. [Post-Incident Review](#post-incident-review)
12. [Communication Templates](#communication-templates)

---

## Incident Classification

### Severity Levels

| Level | Description | Response Time | Examples |
|-------|-------------|---------------|----------|
| **P1 - Critical** | Complete system outage or active breach | 15 minutes | Ransomware, complete HA failure |
| **P2 - High** | Major functionality impacted or suspected breach | 1 hour | Credential compromise, partial outage |
| **P3 - Medium** | Limited impact, workaround available | 4 hours | Single node failure, performance degradation |
| **P4 - Low** | Minor issue, no immediate impact | 24 hours | Warning alerts, non-critical bugs |

### Incident Response Team

| Role | Responsibilities |
|------|------------------|
| **Incident Commander** | Overall coordination, decisions, communication |
| **Technical Lead** | Technical investigation and remediation |
| **Security Analyst** | Threat analysis, forensics, indicators |
| **Communications** | Stakeholder updates, documentation |
| **Management** | Escalation, resource allocation |

---

## Credential Compromise Response

### Playbook: Compromised Privileged Account

**Severity:** P2 - High
**Trigger:** Known or suspected compromise of a managed account

```
┌─────────────────────────────────────────────────────────────────┐
│              CREDENTIAL COMPROMISE RESPONSE                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  PHASE 1: CONTAIN (0-15 min)                                   │
│  ─────────────────────────                                      │
│  □ Identify compromised account(s)                             │
│  □ Immediately rotate compromised credentials                  │
│  □ Terminate active sessions using those credentials           │
│  □ Disable account access if needed                            │
│                                                                 │
│  PHASE 2: ASSESS (15-60 min)                                   │
│  ─────────────────────────                                      │
│  □ Determine scope of compromise                               │
│  □ Identify affected systems                                   │
│  □ Review audit logs for unauthorized access                   │
│  □ Identify lateral movement                                   │
│                                                                 │
│  PHASE 3: ERADICATE (1-4 hours)                                │
│  ─────────────────────────────                                  │
│  □ Rotate all potentially affected credentials                 │
│  □ Review and revoke suspicious authorizations                 │
│  □ Check for persistence mechanisms                            │
│  □ Verify no backdoors installed                               │
│                                                                 │
│  PHASE 4: RECOVER (4-24 hours)                                 │
│  ───────────────────────────                                    │
│  □ Restore normal operations                                   │
│  □ Implement additional monitoring                             │
│  □ Document incident                                           │
│  □ Conduct post-incident review                                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Phase 1: Containment (0-15 minutes)

**Step 1: Identify Compromised Account**
```bash
# Get account details
wabadmin account show <account_id>

# Check recent access
wabadmin audit --filter "account=<account_name>" --last 24h
```

**Step 2: Immediate Credential Rotation**
```bash
# Force immediate rotation with new password
NEW_PASS=$(openssl rand -base64 32)
wabadmin account rotate <account_id> --force --password "$NEW_PASS"

# Verify rotation succeeded
wabadmin account show <account_id> --last-rotation
```

**Step 3: Terminate Active Sessions**
```bash
# Find all sessions using this account
wabadmin sessions --filter "account=<account_name>" --status active

# Terminate all sessions
wabadmin sessions --filter "account=<account_name>" --kill-all --confirm

# Verify no active sessions
wabadmin sessions --filter "account=<account_name>" --status active
```

**Step 4: Disable Account Access (if needed)**
```bash
# Disable the account temporarily
wabadmin account disable <account_id>

# Or disable all authorizations using this account
wabadmin authorizations --filter "account=<account_name>" --disable-all
```

### Phase 2: Assessment (15-60 minutes)

**Step 1: Determine Compromise Scope**
```bash
# Export all activity for the account
wabadmin audit --filter "account=<account_name>" --last 7d \
  --export /tmp/compromise-audit.csv

# Identify unique sessions
wabadmin sessions --filter "account=<account_name>" --last 7d \
  --export /tmp/compromise-sessions.csv

# Check for unusual patterns
wabadmin audit --filter "account=<account_name>" --last 7d \
  --analyze-patterns
```

**Step 2: Identify Affected Systems**
```bash
# List all targets accessed with this account
wabadmin audit --filter "account=<account_name>" --last 7d \
  --group-by target

# Check for privilege escalation
wabadmin audit --filter "account=<account_name>" --last 7d \
  --filter "event_type IN (sudo,privilege_change,user_add)"
```

**Step 3: Review for Lateral Movement**
```bash
# Check if other accounts were accessed from same sessions
wabadmin audit --filter "source_ip IN (compromised_ips)" --last 7d

# Look for credential harvesting attempts
wabadmin audit --filter "event_type=password_view" --last 7d
```

### Phase 3: Eradication (1-4 hours)

**Step 1: Rotate Related Credentials**
```bash
# Rotate all accounts on affected targets
for device_id in $(wabadmin audit --filter "account=<account_name>" \
  --last 7d --output device_id --unique); do
    wabadmin rotation --device "$device_id" --execute
done

# Rotate accounts accessed by potentially compromised user
wabadmin accounts --accessed-by <user_name> --last 7d | \
  while read account_id; do
    wabadmin account rotate "$account_id" --force
  done
```

**Step 2: Review Authorizations**
```bash
# List all authorizations for affected user
wabadmin authorizations --filter "user=<user_name>" --list

# Disable suspicious authorizations
wabadmin authorization disable <auth_id>
```

**Step 3: Check for Persistence**
```bash
# On each affected target, check for:
# - New user accounts
# - Modified authorized_keys
# - Scheduled tasks/cron jobs
# - Installed backdoors

# Review session recordings for attacker actions
wabadmin recording export <session_id> --output /tmp/forensics/
```

### Phase 4: Recovery (4-24 hours)

**Step 1: Restore Operations**
```bash
# Re-enable account with new credentials
wabadmin account enable <account_id>

# Re-enable legitimate authorizations
wabadmin authorization enable <auth_id>

# Verify connectivity
wabadmin connectivity-test --account <account_id>
```

**Step 2: Enhanced Monitoring**
```bash
# Enable detailed audit logging for affected accounts
wabadmin account set <account_id> --audit-level verbose

# Set up alerts for suspicious activity
wabadmin alert add --name "compromised-account-monitoring" \
  --filter "account=<account_name>" \
  --action email,siem
```

---

## Ransomware Attack Response

### Playbook: Ransomware Detection and Response

**Severity:** P1 - Critical
**Trigger:** Ransomware detected on WALLIX systems or managed targets

```
┌─────────────────────────────────────────────────────────────────┐
│              RANSOMWARE RESPONSE PLAYBOOK                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  IMMEDIATE ACTIONS (0-5 min)                                   │
│  ─────────────────────────                                      │
│  □ ISOLATE affected systems from network                       │
│  □ DO NOT power off (preserve memory evidence)                 │
│  □ Activate incident response team                             │
│  □ Begin timeline documentation                                │
│                                                                 │
│  ASSESSMENT (5-30 min)                                         │
│  ──────────────────────                                         │
│  □ Identify ransomware variant                                 │
│  □ Determine encryption scope                                  │
│  □ Check backup integrity                                      │
│  □ Assess WALLIX Bastion status                                │
│                                                                 │
│  CONTAINMENT (30-60 min)                                       │
│  ───────────────────────                                        │
│  □ Block lateral movement                                      │
│  □ Rotate ALL credentials                                      │
│  □ Disable compromised access paths                            │
│  □ Preserve evidence                                           │
│                                                                 │
│  RECOVERY (1-72 hours)                                         │
│  ─────────────────────                                          │
│  □ Restore from clean backups                                  │
│  □ Rebuild if necessary                                        │
│  □ Re-establish trust                                          │
│  □ Gradual service restoration                                 │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Immediate Actions (0-5 minutes)

**Step 1: Network Isolation**
```bash
# If WALLIX is NOT affected - use it to isolate targets:
wabadmin sessions --kill-all --confirm  # Terminate all sessions

# Block new session establishment
wabadmin service pause session-manager

# If WALLIX IS affected:
# - Physically disconnect network cables
# - Do NOT shut down (preserve evidence)
# - Contact incident response immediately
```

**Step 2: Activate Response Team**
- Call incident response hotline
- Assemble technical team
- Notify management
- Begin documentation

### Assessment (5-30 minutes)

**Step 1: Check WALLIX Status**
```bash
# From backup management station:
# Check if WALLIX is accessible
ping bastion.example.com
curl -k https://bastion.example.com/api/v3.12/status

# If accessible, check system health
ssh admin@bastion-oob  # Out-of-band management
wabadmin status
wabadmin health-check

# Check for signs of encryption
ls -la /var/lib/wallix/
ls -la /var/lib/postgresql/
find /var/lib/wallix -name "*.encrypted" -o -name "*.locked"
```

**Step 2: Verify Backup Integrity**
```bash
# From backup server (isolated):
wabadmin backup --verify /path/to/latest/backup.tar.gz

# Check backup creation dates
ls -la /var/backup/wallix/

# Verify backup not encrypted
file /var/backup/wallix/latest.tar.gz
```

### Containment (30-60 minutes)

**Step 1: Emergency Credential Rotation**
```bash
# If WALLIX is operational:
# Rotate ALL managed credentials immediately
wabadmin rotation --all --force --execute

# If WALLIX is compromised:
# Access targets directly and change passwords
# Document all manual changes
```

**Step 2: Preserve Evidence**
```bash
# Create memory dump (if trained)
# Capture network traffic
# Export all audit logs
wabadmin audit --all --export /tmp/incident/audit-export.csv

# Export session recordings
wabadmin recordings --last 48h --export /tmp/incident/recordings/

# Create disk image if possible
```

### Recovery (1-72 hours)

**Step 1: Restore WALLIX (if compromised)**
```bash
# On clean hardware/VM:
# 1. Fresh Debian 12 installation
# 2. Install WALLIX Bastion
# 3. Restore from verified clean backup

wabadmin restore --full --input /backup/wallix-clean.tar.gz

# 4. Generate new SSL certificates
# 5. Rotate all internal credentials
# 6. Re-establish AD/LDAP connectivity
# 7. Verify all integrations
```

**Step 2: Gradual Service Restoration**
```bash
# 1. Restore critical systems first
wabadmin authorization enable --filter "tier=1"

# 2. Verify each system before allowing access
wabadmin connectivity-test --tier 1

# 3. Monitor closely for reinfection
wabadmin audit --realtime --filter "event_type=session_start"

# 4. Gradually restore remaining systems
```

---

## Unauthorized Access Detection

### Playbook: Detecting and Responding to Unauthorized Access

**Severity:** P2 - High
**Trigger:** Alerts or reports of unauthorized system access

### Detection Indicators

| Indicator | Detection Method |
|-----------|------------------|
| Unusual login times | Audit log analysis |
| Access from new locations | GeoIP analysis |
| Multiple failed logins | Authentication logs |
| Access to unusual targets | Authorization bypass attempts |
| Privilege escalation | Sudo/admin command logging |
| Data exfiltration | Session recording analysis |

### Response Procedure

**Step 1: Confirm Unauthorized Access**
```bash
# Review suspicious activity
wabadmin audit --filter "user=<suspect_user>" --last 24h --verbose

# Check for authorization bypass
wabadmin audit --filter "event_type=authorization_denied" --last 24h

# Compare with normal behavior patterns
wabadmin user show <username> --behavior-baseline
wabadmin audit --filter "user=<username>" --analyze-anomalies
```

**Step 2: Immediate Containment**
```bash
# Disable user account
wabadmin user disable <username>

# Terminate all active sessions
wabadmin sessions --filter "user=<username>" --kill-all

# Lock associated accounts
wabadmin accounts --accessed-by <username> --last 24h --lock-all
```

**Step 3: Investigation**
```bash
# Export all user activity
wabadmin audit --filter "user=<username>" --export /tmp/investigation/

# Get session recordings
wabadmin recordings --filter "user=<username>" --export /tmp/investigation/recordings/

# Identify accessed credentials
wabadmin accounts --accessed-by <username> --last 30d > /tmp/investigation/accessed-accounts.txt
```

**Step 4: Remediation**
```bash
# Rotate all accessed credentials
while read account_id; do
    wabadmin account rotate "$account_id" --force
done < /tmp/investigation/accessed-accounts.txt

# Review and update authorizations
wabadmin authorizations --review --all
```

---

## Data Breach Response

### Playbook: Responding to Data Breach

**Severity:** P1 - Critical
**Trigger:** Confirmed or suspected data exfiltration

### Immediate Actions

```bash
# 1. Activate breach response team
# 2. Begin legal hold on all evidence
# 3. Notify legal and compliance teams

# Preserve all audit data
wabadmin audit --all --export /secure/breach/audit-$(date +%Y%m%d-%H%M%S).csv

# Preserve session recordings
wabadmin recordings --all --preserve --legal-hold

# Document current state
wabadmin status --full > /secure/breach/system-state.txt
wabadmin users --list > /secure/breach/users.txt
wabadmin authorizations --list > /secure/breach/authorizations.txt
```

### Investigation Steps

```bash
# 1. Identify timeframe of breach
# 2. Identify compromised accounts
# 3. Identify accessed data
# 4. Identify exfiltration method

# Analyze session recordings for data access
wabadmin recordings --search "SELECT * FROM" --last 30d
wabadmin recordings --search "password" --last 30d
wabadmin recordings --search "credit_card" --last 30d

# Export findings for legal review
wabadmin report --type breach-analysis --output /secure/breach/report.pdf
```

### Notification Requirements

| Jurisdiction | Requirement | Timeline |
|--------------|-------------|----------|
| GDPR (EU) | Notify authority + affected individuals | 72 hours |
| CCPA (California) | Notify affected individuals | "Expeditiously" |
| HIPAA (US Healthcare) | Notify HHS + affected individuals | 60 days |
| PCI-DSS | Notify card brands + acquiring bank | Immediate |

---

## Service Outage Response

### Playbook: WALLIX Service Outage

**Severity:** P1/P2 depending on scope
**Trigger:** WALLIX Bastion unavailable or degraded

### Initial Assessment

```bash
# Check service status (if accessible)
systemctl status wallix-bastion
wabadmin status

# Check system resources
df -h
free -h
top -bn1 | head -20

# Check network connectivity
ping -c 3 localhost
netstat -tlnp | grep -E "(443|22)"

# Check database
systemctl status postgresql
sudo -u postgres psql -c "SELECT 1;"
```

### Recovery Procedures

**Scenario 1: Service Not Starting**
```bash
# Check logs
journalctl -u wallix-bastion --since "1 hour ago" -n 100

# Check configuration
wabadmin config --verify

# Attempt restart
systemctl restart wallix-bastion

# If config issue, restore from backup
wabadmin restore --config-only --input /var/backup/wallix/daily/latest.tar.gz
```

**Scenario 2: Database Issues**
```bash
# Check PostgreSQL status
systemctl status postgresql
sudo -u postgres pg_isready

# Check for corrupt tables
sudo -u postgres psql -d wallix -c "
SELECT relname FROM pg_class
WHERE relkind = 'r' AND relpages = 0 AND reltuples > 0;"

# Repair if needed
sudo -u postgres psql -d wallix -c "REINDEX DATABASE wallix;"
```

**Scenario 3: HA Failover Not Working**
```bash
# Check cluster status
crm status

# Force failover if needed
crm resource move wallix-bastion node-b

# After recovery, clear constraints
crm resource clear wallix-bastion
```

### Escalation Matrix

| Duration | Action |
|----------|--------|
| 0-15 min | Technical team investigation |
| 15-30 min | Notify management |
| 30-60 min | Activate backup access procedures |
| 1-4 hours | Execute business continuity plan |
| 4+ hours | Engage vendor support |

---

## Cluster Failure Recovery

### Playbook: Complete HA Cluster Failure

**Severity:** P1 - Critical
**Trigger:** Both HA nodes unavailable

### Recovery Procedure

**Step 1: Assess Both Nodes**
```bash
# Access via out-of-band management (ILO, DRAC, IPMI)
# Check hardware status
# Check boot status

# If one node recoverable:
# Boot that node first
```

**Step 2: Identify Node with Latest Data**
```bash
# On each node (if accessible):
sudo -u postgres psql -c "SELECT pg_last_wal_receive_lsn();"

# Compare LSN positions
# Node with higher LSN has more recent data
```

**Step 3: Recover Primary Node**
```bash
# Boot node with latest data
# Start in standalone mode

# Disable cluster temporarily
systemctl stop pacemaker
systemctl stop corosync

# Start WALLIX standalone
systemctl start postgresql
systemctl start wallix-bastion

# Verify functionality
wabadmin status
wabadmin health-check
```

**Step 4: Recover Secondary Node**
```bash
# On secondary node:
# Clean existing data
systemctl stop postgresql
rm -rf /var/lib/postgresql/15/main/*

# Re-initialize from primary
pg_basebackup -h primary-node -D /var/lib/postgresql/15/main -U replicator -P

# Start PostgreSQL in standby mode
systemctl start postgresql

# Verify replication
sudo -u postgres psql -c "SELECT * FROM pg_stat_wal_receiver;"
```

**Step 5: Restore Cluster**
```bash
# On both nodes:
systemctl start corosync
systemctl start pacemaker

# Verify cluster status
crm status
crm_verify -L

# Test failover
crm node standby node-b
# Verify services on node-a
crm node online node-b
```

---

## Database Corruption Recovery

### Playbook: PostgreSQL Database Corruption

**Severity:** P1 - Critical
**Trigger:** Database errors, missing data, or integrity failures

### Assessment

```bash
# Check PostgreSQL status
systemctl status postgresql

# Check for errors
sudo -u postgres psql -c "SELECT * FROM pg_stat_database WHERE datname = 'wallix';"

# Check for corruption
sudo -u postgres pg_dump wallix > /dev/null
# If this fails, corruption is likely

# Identify corrupt tables
sudo -u postgres psql -d wallix -c "
SELECT schemaname, tablename
FROM pg_tables
WHERE schemaname = 'public';"
```

### Recovery Options

**Option 1: Repair in Place (Minor Corruption)**
```bash
# Stop WALLIX
systemctl stop wallix-bastion

# Attempt repair
sudo -u postgres psql -d wallix -c "REINDEX DATABASE wallix;"
sudo -u postgres psql -d wallix -c "VACUUM FULL ANALYZE;"

# Restart and verify
systemctl start wallix-bastion
wabadmin verify --database
```

**Option 2: Restore from Backup (Major Corruption)**
```bash
# Stop all services
systemctl stop wallix-bastion
systemctl stop postgresql

# Backup current (corrupt) database for analysis
sudo -u postgres pg_dump wallix > /tmp/corrupt-db-backup.sql 2>&1

# Drop and recreate
sudo -u postgres dropdb wallix
sudo -u postgres createdb wallix

# Restore from backup
sudo -u postgres pg_restore -d wallix /var/backup/wallix/database-latest.dump

# Restart services
systemctl start postgresql
systemctl start wallix-bastion

# Verify
wabadmin verify --database
wabadmin health-check
```

**Option 3: Point-in-Time Recovery**
```bash
# If WAL archiving enabled:
# Restore base backup
sudo -u postgres pg_restore /path/to/base_backup

# Configure recovery
cat > /var/lib/postgresql/15/main/recovery.signal << EOF
restore_command = 'cp /path/to/wal_archive/%f %p'
recovery_target_time = '2024-01-15 14:30:00'
recovery_target_action = 'promote'
EOF

# Start PostgreSQL
systemctl start postgresql

# After recovery completes, verify data
```

---

## Certificate Compromise Response

### Playbook: SSL/TLS Certificate Compromise

**Severity:** P2 - High
**Trigger:** Private key exposure or certificate compromise

### Immediate Actions

```bash
# 1. Revoke compromised certificate with CA
# Contact your CA immediately

# 2. Generate new key and CSR
openssl genrsa -out /etc/wallix/ssl/server.key.new 4096
openssl req -new -key /etc/wallix/ssl/server.key.new \
  -out /tmp/server.csr \
  -subj "/CN=bastion.example.com/O=Company/C=US"

# 3. Submit CSR to CA for emergency issuance
# Obtain new certificate

# 4. Install new certificate
cp /etc/wallix/ssl/server.key.new /etc/wallix/ssl/server.key
cp /path/to/new/server.crt /etc/wallix/ssl/server.crt

# 5. Reload services
systemctl reload wallix-bastion

# 6. Verify new certificate
echo | openssl s_client -connect localhost:443 2>/dev/null | \
  openssl x509 -noout -subject -dates -serial
```

### Post-Compromise Actions

```bash
# Review access during compromise period
wabadmin audit --filter "time_range=(compromise_start,now)" --export

# Check for man-in-the-middle attacks
# Review session recordings during period

# Update certificate pinning if used
# Notify clients of certificate change
```

---

## Forensics & Evidence Preservation

### Evidence Collection Procedure

**Before Starting:**
- Document all actions with timestamps
- Use write-blockers for disk imaging
- Maintain chain of custody
- Work on copies, not originals

### Collecting Evidence

```bash
# 1. Document current state
date > /evidence/collection-start.txt
wabadmin status >> /evidence/collection-start.txt
ps aux >> /evidence/collection-start.txt
netstat -tlnp >> /evidence/collection-start.txt

# 2. Export audit logs
wabadmin audit --all --export /evidence/audit-complete.csv

# 3. Export session recordings
wabadmin recordings --all --export /evidence/recordings/

# 4. Export configuration
wabadmin config --export /evidence/config-backup.tar.gz

# 5. Collect system logs
cp -r /var/log/wallix /evidence/logs/
cp -r /var/log/auth.log /evidence/logs/
cp -r /var/log/syslog /evidence/logs/

# 6. Create checksums
find /evidence -type f -exec sha256sum {} \; > /evidence/checksums.txt

# 7. Sign evidence package
gpg --sign /evidence/checksums.txt
```

### Chain of Custody

| Date/Time | Action | Person | Signature |
|-----------|--------|--------|-----------|
| | Evidence collected | | |
| | Evidence transferred to | | |
| | Evidence stored at | | |
| | Evidence accessed by | | |

---

## Post-Incident Review

### Review Checklist

```
□ Timeline of incident documented
□ Root cause identified
□ Impact assessment completed
□ Remediation actions documented
□ Lessons learned identified
□ Improvement recommendations made
□ Follow-up actions assigned
□ Report distributed to stakeholders
```

### Post-Incident Report Template

```markdown
# Incident Report: [Incident ID]

## Executive Summary
- Incident type:
- Severity:
- Duration:
- Impact:

## Timeline
| Time | Event |
|------|-------|
| | Incident detected |
| | Response initiated |
| | Containment achieved |
| | Eradication completed |
| | Recovery completed |

## Root Cause Analysis
[Detailed analysis]

## Impact Assessment
- Systems affected:
- Users affected:
- Data affected:
- Business impact:

## Response Effectiveness
- What worked well:
- What could be improved:

## Recommendations
1. [Recommendation 1]
2. [Recommendation 2]
3. [Recommendation 3]

## Follow-up Actions
| Action | Owner | Due Date | Status |
|--------|-------|----------|--------|
| | | | |
```

---

## Communication Templates

### Internal Notification

```
Subject: [P1/P2] Security Incident - [Brief Description]

Status: [Active/Contained/Resolved]
Severity: [P1/P2/P3/P4]
Started: [Date/Time]

Summary:
[2-3 sentences describing the incident]

Current Status:
[What is being done]

Impact:
[Who/what is affected]

Next Update: [Time]

Contact: [Incident Commander]
```

### Management Escalation

```
Subject: ESCALATION: [Incident ID] - [Brief Description]

Incident Type: [Type]
Severity: [Level]
Duration: [Time since detection]

Business Impact:
- [Impact 1]
- [Impact 2]

Actions Taken:
- [Action 1]
- [Action 2]

Resources Needed:
- [Resource 1]
- [Resource 2]

Decision Required:
[Specific decision needed from management]

Incident Commander: [Name]
Contact: [Phone/Email]
```

### User Communication

```
Subject: [Service Name] Access Temporarily Affected

Dear Users,

We are currently experiencing an issue with [service] that may affect your ability to [action].

Status: [Working to resolve / Monitoring]
Expected Resolution: [Time estimate if available]

Workaround:
[If available, describe alternative access method]

We apologize for any inconvenience and will provide updates as the situation progresses.

IT Security Team
```

---

*Document Version: 1.0*
*Last Updated: January 2026*
*Review Frequency: Quarterly*
