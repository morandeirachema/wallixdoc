# PAM Security Incident Response

## Handling Security Incidents Involving PAM4OT

This document provides incident response procedures specific to PAM4OT security events.

---

## Incident Classification

```
+===============================================================================+
|                      PAM SECURITY INCIDENT TYPES                              |
+===============================================================================+

  CREDENTIAL COMPROMISE              SESSION HIJACKING
  =====================              =================
  - Password leak/exposure           - Unauthorized session access
  - Credential stuffing attack       - Session token theft
  - Brute force success              - Man-in-the-middle attack
  - Insider theft                    - Replay attack

  PRIVILEGE ESCALATION               UNAUTHORIZED ACCESS
  ====================               ===================
  - Role manipulation                - Bypass of PAM controls
  - Approval workflow bypass         - Direct target access
  - Admin account compromise         - Policy violation
  - Shadow admin creation            - After-hours access

+===============================================================================+
```

---

## Incident Severity Matrix

| Severity | Description | Response Time | Example |
|----------|-------------|---------------|---------|
| SEV-1 | Active breach, data exfiltration | Immediate (15 min) | Credential vault compromised |
| SEV-2 | Confirmed unauthorized access | 1 hour | Admin account misuse |
| SEV-3 | Suspicious activity, potential breach | 4 hours | Multiple failed auth attempts |
| SEV-4 | Policy violation, no active threat | 24 hours | Unauthorized session recording access |

---

## Incident Response Playbooks

### Playbook 1: Credential Compromise

**Trigger:** Suspected or confirmed credential leak

```bash
# IMMEDIATE ACTIONS (0-15 minutes)

# Step 1: Identify compromised credentials
wabadmin audit search --type auth --last 24h | grep -i "[suspected-user]"

# Step 2: Disable compromised account immediately
wabadmin user disable [username]

# Step 3: Kill all active sessions for user
wabadmin session kill --user [username] --all

# Step 4: Check for lateral movement
wabadmin audit search --user [username] --last 7d > /tmp/user-audit.log

# Step 5: Rotate all target credentials accessed by user
wabadmin password rotate --accessed-by [username] --since "7 days ago"
```

**Investigation Phase:**

```bash
# Step 6: Export complete audit trail
wabadmin audit export --user [username] --format csv > /tmp/incident-audit.csv

# Step 7: Review session recordings
wabadmin recording list --user [username] --last 7d

# Step 8: Check for policy changes
wabadmin audit search --type config --user [username]

# Step 9: Identify accessed systems
wabadmin audit search --type session --user [username] --last 30d | \
  awk '{print $5}' | sort | uniq -c | sort -rn

# Step 10: Export for forensics
wabadmin audit export --user [username] --all --format json > /evidence/audit-full.json
```

**Remediation:**

```bash
# Step 11: Reset user credentials (if account to be restored)
wabadmin user passwd [username]

# Step 12: Require MFA re-enrollment
wabadmin user mfa reset [username]

# Step 13: Apply restrictive policy temporarily
wabadmin user group add [username] --group "Restricted Access"

# Step 14: Re-enable account only after verification
wabadmin user enable [username]
```

---

### Playbook 2: Session Hijacking

**Trigger:** Suspected unauthorized session access or session token theft

```bash
# IMMEDIATE ACTIONS (0-15 minutes)

# Step 1: Identify suspicious sessions
wabadmin session list --status active | grep -E "(unusual-ip|unusual-time)"

# Step 2: Kill suspicious session immediately
wabadmin session kill --id [session-id]

# Step 3: Block source IP
wabadmin blacklist add [attacker-ip] --duration 24h --reason "Session hijacking"

# Step 4: Invalidate all session tokens for affected user
wabadmin session token invalidate --user [username]

# Step 5: Force re-authentication
wabadmin user force-reauth [username]
```

**Investigation:**

```bash
# Step 6: Compare session metadata
wabadmin session show --id [legitimate-session-id]
wabadmin session show --id [suspicious-session-id]

# Look for:
# - Different source IPs
# - Different user agents
# - Impossible travel (geolocation)
# - Session resumed after timeout

# Step 7: Check for token leakage
# Review application logs for token exposure
grep -i "token\|session" /var/log/wab*/access.log | tail -100

# Step 8: Analyze network traffic (if captured)
tshark -r /tmp/capture.pcap -Y "http contains session"
```

---

### Playbook 3: Privilege Escalation

**Trigger:** Unauthorized role changes or approval workflow bypass

```bash
# IMMEDIATE ACTIONS (0-15 minutes)

# Step 1: Identify escalated permissions
wabadmin user show [username] --permissions
wabadmin audit search --type permission --user [username] --last 24h

# Step 2: Revert unauthorized role changes
wabadmin user group remove [username] --group "[unauthorized-group]"

# Step 3: Check for shadow admin accounts
wabadmin user list --role admin | diff - /baseline/admin-users.txt

# Step 4: Disable any unauthorized admin accounts
wabadmin user disable [shadow-admin]

# Step 5: Review approval workflow logs
wabadmin approval list --approved-by [suspected-approver] --last 7d
```

**Investigation:**

```bash
# Step 6: Audit all configuration changes
wabadmin audit search --type config --last 7d > /tmp/config-audit.log

# Step 7: Check for policy modifications
wabadmin policy diff --baseline /baseline/policies.json

# Step 8: Review group membership changes
wabadmin audit search --type group --last 7d

# Step 9: Check for direct database modifications
sudo mysql wabdb -e "
SELECT * FROM audit_log
WHERE table_name IN ('users', 'groups', 'permissions')
AND timestamp > NOW() - INTERVAL 7 DAY
ORDER BY timestamp DESC;"
```

---

### Playbook 4: Unauthorized Direct Target Access

**Trigger:** Access to targets bypassing PAM4OT controls

```bash
# IMMEDIATE ACTIONS (0-15 minutes)

# Step 1: Identify unauthorized access on targets
# Check target system logs for direct logins

# On Linux targets:
grep "Accepted" /var/log/auth.log | grep -v "pam4ot"

# On Windows targets:
# Event ID 4624 with LogonType 10 (RDP) not from PAM4OT IPs

# Step 2: Force credential rotation on affected targets
wabadmin password rotate --device [target-name] --all-accounts

# Step 3: Block network access if possible
# Add firewall rules to block direct access

# Step 4: Check if PAM was bypassed or credentials leaked
wabadmin audit search --device [target-name] --last 7d
```

**Investigation:**

```bash
# Step 5: Cross-reference PAM sessions with target logs
# Export PAM session data
wabadmin session list --device [target-name] --last 7d > /tmp/pam-sessions.log

# Compare with target authentication logs
# Identify logins not matching PAM sessions

# Step 6: Check for stored credentials
# Search for credential storage outside PAM
# Review password managers, scripts, configuration files

# Step 7: Identify access path
# How did attacker get credentials?
# - Credential file on target
# - Insider knowledge
# - Previous PAM session recording
```

---

## Evidence Collection

### Required Evidence for All Incidents

```bash
# Create evidence directory
mkdir -p /evidence/incident-$(date +%Y%m%d-%H%M%S)
cd /evidence/incident-$(date +%Y%m%d-%H%M%S)

# 1. PAM4OT audit logs
wabadmin audit export --last 30d --format json > pam-audit.json

# 2. System logs
journalctl --since "7 days ago" > system-journal.log
cp /var/log/wab*/*.log ./

# 3. Authentication logs
cp /var/log/auth.log* ./

# 4. Network connections at time of incident
ss -tnp > network-connections.txt
netstat -an > netstat-output.txt

# 5. Process list
ps auxf > process-list.txt

# 6. Session recordings (if applicable)
wabadmin recording export --session-id [id] --output ./recordings/

# 7. Configuration snapshot
wabadmin config export > pam-config.json

# 8. User and permission snapshot
wabadmin user list --all --format json > users.json
wabadmin group list --all --format json > groups.json

# 9. Create integrity hash
find . -type f -exec sha256sum {} \; > evidence-hashes.sha256

# 10. Create sealed archive
tar -czvf ../incident-evidence-$(date +%Y%m%d).tar.gz .
sha256sum ../incident-evidence-$(date +%Y%m%d).tar.gz > ../evidence-archive.sha256
```

### Chain of Custody

```
EVIDENCE CHAIN OF CUSTODY
=========================

Incident ID: ____________________
Evidence ID: ____________________

Collection:
- Collected by: ____________________
- Date/Time: ____________________
- Location: ____________________
- Method: ____________________

Transfers:
| Date/Time | From | To | Purpose | Signature |
|-----------|------|-----|---------|-----------|
| _________ | ____ | ___ | _______ | _________ |
| _________ | ____ | ___ | _______ | _________ |

Storage:
- Location: ____________________
- Access controls: ____________________
- Encryption: [ ] Yes  [ ] No
```

---

## Communication Templates

### Initial Notification (Internal)

```
Subject: [SEV-X] PAM Security Incident - [Brief Description]

INCIDENT SUMMARY
================
Incident ID: INC-YYYYMMDD-XXX
Severity: SEV-X
Status: Active/Investigating/Contained/Resolved
Time Detected: YYYY-MM-DD HH:MM UTC

DESCRIPTION
-----------
[Brief description of the incident]

IMPACT
------
- Systems affected: [List]
- Users affected: [Count/List]
- Data at risk: [Description]

ACTIONS TAKEN
-------------
1. [Immediate action 1]
2. [Immediate action 2]

NEXT STEPS
----------
1. [Planned action 1]
2. [Planned action 2]

CONTACTS
--------
- Incident Commander: [Name]
- Technical Lead: [Name]
- Next update: [Time]
```

### Status Update Template

```
Subject: UPDATE [X]: [SEV-X] PAM Security Incident - [Brief Description]

STATUS: [Active/Contained/Resolved]
Time: YYYY-MM-DD HH:MM UTC

PROGRESS SINCE LAST UPDATE
--------------------------
- [Action completed 1]
- [Action completed 2]

CURRENT ACTIVITIES
------------------
- [In-progress action 1]
- [In-progress action 2]

BLOCKERS/ISSUES
---------------
- [Issue 1 - if any]

TIMELINE UPDATE
---------------
- Expected containment: [Time]
- Expected resolution: [Time]

NEXT UPDATE: [Time]
```

---

## Post-Incident Activities

### Incident Report Template

```
PAM SECURITY INCIDENT REPORT
============================

EXECUTIVE SUMMARY
-----------------
[2-3 sentence summary for leadership]

INCIDENT DETAILS
----------------
Incident ID: ____________________
Severity: ____________________
Duration: ____________________
Systems Affected: ____________________

TIMELINE
--------
| Time (UTC) | Event |
|------------|-------|
| __________ | Incident began |
| __________ | Incident detected |
| __________ | Response initiated |
| __________ | Incident contained |
| __________ | Incident resolved |
| __________ | Post-incident review |

ROOT CAUSE ANALYSIS
-------------------
[Detailed technical root cause]

IMPACT ASSESSMENT
-----------------
- Data exposure: [ ] Yes  [ ] No
  If yes: ____________________
- Compliance impact: [ ] Yes  [ ] No
  If yes: ____________________
- Business impact: ____________________

REMEDIATION ACTIONS
-------------------
1. [Immediate fix]
2. [Short-term mitigation]
3. [Long-term improvement]

LESSONS LEARNED
---------------
- What went well: ____________________
- What could improve: ____________________

RECOMMENDATIONS
---------------
1. [Recommendation 1]
2. [Recommendation 2]

SIGN-OFF
--------
Security Lead: ______________ Date: ______
IT Director: ______________ Date: ______
Compliance: ______________ Date: ______
```

---

## Monitoring and Detection

### Key Indicators to Monitor

```yaml
# Prometheus alert rules for security incidents

groups:
  - name: pam_security
    rules:
      # Multiple failed authentications
      - alert: BruteForceAttempt
        expr: rate(pam_auth_failures_total[5m]) > 10
        for: 2m
        labels:
          severity: high
          category: security
        annotations:
          description: "Possible brute force attack: {{ $value }} failures/min"

      # After-hours admin activity
      - alert: AfterHoursAdminAccess
        expr: pam_admin_sessions_active > 0 and hour() < 6 or hour() > 20
        for: 1m
        labels:
          severity: medium
          category: security

      # Multiple session terminations
      - alert: MassSessionTermination
        expr: rate(pam_sessions_terminated_total[5m]) > 5
        for: 1m
        labels:
          severity: high
          category: security

      # Credential access anomaly
      - alert: UnusualCredentialAccess
        expr: rate(pam_credential_checkouts_total[1h]) > 20
        for: 5m
        labels:
          severity: medium
          category: security

      # Configuration changes
      - alert: SecurityConfigChange
        expr: increase(pam_config_changes_total{type="security"}[5m]) > 0
        for: 0m
        labels:
          severity: high
          category: security
```

---

## Quick Reference

### Emergency Contacts

| Role | Primary | Phone | Backup | Phone |
|------|---------|-------|--------|-------|
| Security Lead | ________ | ________ | ________ | ________ |
| Incident Commander | ________ | ________ | ________ | ________ |
| SOC Lead | ________ | ________ | ________ | ________ |
| IT Director | ________ | ________ | ________ | ________ |
| Legal Counsel | ________ | ________ | ________ | ________ |

### Critical Commands

```bash
# Kill all sessions for user
wabadmin session kill --user [username] --all

# Disable user immediately
wabadmin user disable [username]

# Block IP address
wabadmin blacklist add [ip] --duration 24h

# Force password rotation
wabadmin password rotate --device [target] --all-accounts

# Export audit for incident
wabadmin audit export --user [username] --format json > incident-audit.json
```

---

<p align="center">
  <a href="./README.md">← Back to Incident Response</a>
</p>
