# Emergency Vendor Access Procedure

## Full Operational Runbook for OT/Industrial Environments

This document provides complete procedures for granting emergency vendor access to critical OT systems.

---

## When to Use This Procedure

```
+===============================================================================+
|                      EMERGENCY ACCESS DECISION TREE                           |
+===============================================================================+

  Is there an active incident affecting:
  - Production/Safety systems?
  - Critical infrastructure?
  - Regulatory compliance?
            |
            v
       +----+----+
       |   YES   |-------> USE THIS PROCEDURE
       +---------+
            |
           NO
            |
            v
  Can access wait for normal approval workflow?
            |
            v
       +----+----+
       |   YES   |-------> Use standard WALLIX Bastion request
       +---------+
            |
           NO
            |
            v
       USE THIS PROCEDURE (with justification)

+===============================================================================+
```

---

## Prerequisites

### Required Contacts (Fill Before Emergency)

| Role | Name | Phone | Email | Backup |
|------|------|-------|-------|--------|
| OT Manager | __________ | __________ | __________ | __________ |
| Plant Manager | __________ | __________ | __________ | __________ |
| Security Lead | __________ | __________ | __________ | __________ |
| WALLIX Bastion Admin | __________ | __________ | __________ | __________ |
| Vendor Contact | __________ | __________ | __________ | __________ |

### Pre-Staged Items

- [ ] Emergency vendor accounts created (disabled) in WALLIX Bastion
- [ ] Vendor NDAs and access agreements on file
- [ ] Emergency credential envelopes sealed and stored
- [ ] Breakglass account credentials in secure location
- [ ] Communication templates prepared

---

## Procedure Overview

```
+===============================================================================+
|                    EMERGENCY ACCESS WORKFLOW                                  |
+===============================================================================+

  PHASE 1: AUTHORIZATION (5-15 min)
  =================================
  1.1 Incident declared
  1.2 Verbal approval from OT Manager + Security Lead
  1.3 Log authorization in incident ticket

  PHASE 2: ACCESS PROVISIONING (5-10 min)
  =======================================
  2.1 Enable pre-staged vendor account
  2.2 Assign target system authorization
  2.3 Set time-limited access window
  2.4 Notify monitoring team

  PHASE 3: SUPERVISED SESSION (Duration varies)
  =============================================
  3.1 Vendor connects via WALLIX Bastion
  3.2 Real-time session monitoring enabled
  3.3 All actions recorded
  3.4 Escort observes if required

  PHASE 4: ACCESS TERMINATION (5-10 min)
  ======================================
  4.1 Vendor confirms work complete
  4.2 Disable vendor account immediately
  4.3 Rotate any exposed credentials
  4.4 Export session recording

  PHASE 5: POST-ACCESS REVIEW (Within 24 hours)
  =============================================
  5.1 Review session recording
  5.2 Document all changes made
  5.3 Security team sign-off
  5.4 Update incident ticket

+===============================================================================+
```

---

## Phase 1: Authorization

### 1.1 Declare Emergency

```bash
# Create incident ticket with:
- Incident ID: INC-YYYYMMDD-XXXX
- System(s) affected
- Business impact (production, safety, regulatory)
- Vendor name and contact
- Requested access scope
- Estimated duration
```

### 1.2 Obtain Verbal Approval

**Minimum Two Approvals Required:**

| Scenario | Approver 1 | Approver 2 |
|----------|------------|------------|
| Production impact | OT Manager | Plant Manager |
| Safety system | OT Manager | Safety Officer |
| Regulatory/Compliance | OT Manager | Security Lead |
| After hours | On-call OT Lead | On-call Security |

**Approval Script:**
```
"This is [Your Name] requesting emergency vendor access authorization.

Incident: [INC-YYYYMMDD-XXXX]
Vendor: [Vendor Name]
System: [Target System]
Reason: [Brief description]
Duration: [Estimated hours]

Do you authorize this emergency access? Please confirm verbally."
```

### 1.3 Log Authorization

```
# Add to incident ticket:
Authorization Log:
- Approver 1: [Name], [Role], [Time], [Method: Phone/Teams/In-person]
- Approver 2: [Name], [Role], [Time], [Method: Phone/Teams/In-person]
- Authorized by: [Your Name]
- Authorization time: [YYYY-MM-DD HH:MM UTC]
```

---

## Phase 2: Access Provisioning

### 2.1 Enable Vendor Account

**Via WALLIX Bastion Web UI:**

```
1. Login to WALLIX Bastion admin console
   URL: https://wallix.company.com/admin

2. Navigate to: Configuration > Users > External/Vendors

3. Locate pre-staged vendor account:
   - Search: vendor-[company]-emergency

4. Enable account:
   - Click account name
   - Set Status: Enabled
   - Set Expiration: [Current time + approved duration]

5. Save changes
```

**Via CLI (faster):**

```bash
# SSH to WALLIX Bastion node
ssh admin@wallix.company.com

# Enable vendor account with time limit
wabadmin user enable vendor-siemens-emergency \
    --expire-hours 4 \
    --reason "INC-20260129-0042 - Emergency turbine repair"

# Verify
wabadmin user show vendor-siemens-emergency
```

### 2.2 Assign Target Authorization

**Via Web UI:**

```
1. Navigate to: Configuration > Authorizations

2. Create temporary authorization:
   - Name: EMERGENCY-INC-20260129-0042
   - User: vendor-siemens-emergency
   - Target Group: [Specific systems only]
   - Start: Now
   - End: [Approved duration]
   - Recording: MANDATORY
   - Approval: Not required (pre-approved)

3. Save and activate
```

**Via CLI:**

```bash
# Create time-limited authorization
wabadmin authorization create \
    --name "EMERGENCY-INC-20260129-0042" \
    --user "vendor-siemens-emergency" \
    --target-group "Turbine-Control-Systems" \
    --start-time "now" \
    --duration "4h" \
    --recording mandatory \
    --approval none \
    --comment "Emergency access per INC-20260129-0042"
```

### 2.3 Configure Access Window

```bash
# Set absolute expiration (belt and suspenders)
wabadmin user set-expiry vendor-siemens-emergency \
    --absolute "2026-01-29T18:00:00Z"

# Enable session time limit
wabadmin authorization modify "EMERGENCY-INC-20260129-0042" \
    --max-session-duration 60 \
    --idle-timeout 15
```

### 2.4 Notify Monitoring Team

```bash
# Send notification to SOC/Monitoring
cat << 'EOF' | mail -s "ALERT: Emergency Vendor Access Activated" soc@company.com
EMERGENCY VENDOR ACCESS NOTIFICATION

Incident: INC-20260129-0042
Vendor: Siemens Energy
Account: vendor-siemens-emergency
Target Systems: Turbine-Control-Systems
Access Window: 2026-01-29 14:00 - 18:00 UTC
Authorized By: John Smith (OT Manager), Jane Doe (Security Lead)

ACTION REQUIRED:
- Enable real-time session monitoring
- Alert on any unusual commands
- Contact OT team immediately if concerns

WALLIX Bastion Session Monitoring: https://wallix.company.com/audit/live
EOF
```

---

## Phase 3: Supervised Session

### 3.1 Vendor Connection Instructions

Provide to vendor:

```
EMERGENCY ACCESS INSTRUCTIONS
=============================

Connection Details:
- URL: https://wallix.company.com
- Username: vendor-siemens-emergency
- Password: [Provided separately via secure channel]
- MFA: Required (use provided token)

Steps:
1. Navigate to https://wallix.company.com
2. Enter username and password
3. Complete MFA challenge
4. Select authorized target system from list
5. Click "Connect"

IMPORTANT:
- All sessions are recorded
- Access expires at [TIME]
- Contact [PHONE] if issues

Target Systems Available:
- turbine-ctrl-01 (Turbine Control Primary)
- turbine-ctrl-02 (Turbine Control Backup)
```

### 3.2 Enable Real-Time Monitoring

**SOC/Monitoring Team Actions:**

```bash
# Via WALLIX Bastion Web UI:
1. Navigate to: Audit > Live Sessions
2. Filter by user: vendor-siemens-emergency
3. Click "Monitor" on active session
4. Enable alerts for:
   - Command patterns: rm, del, format, shutdown, reboot
   - File access: /etc/*, config/*, *.conf
   - Network: outbound connections

# Via CLI - Stream session to terminal:
wabadmin session monitor --user vendor-siemens-emergency --live

# Enable command alerting:
wabadmin alert create \
    --session-user "vendor-siemens-emergency" \
    --pattern "rm|delete|format|shutdown|reboot|wget|curl" \
    --action notify \
    --recipient soc@company.com
```

### 3.3 Session Recording Verification

```bash
# Verify recording is active
wabadmin session list --user vendor-siemens-emergency --status active

# Expected output:
# SESSION_ID    USER                      TARGET          START_TIME           RECORDING
# sess-12345    vendor-siemens-emergency  turbine-ctrl-01 2026-01-29 14:05:23  ACTIVE
```

### 3.4 Physical Escort (If Required)

For highest-security environments:

```
ESCORT CHECKLIST:
[ ] Escort assigned: _______________
[ ] Escort briefed on allowed activities
[ ] Escort has communication device
[ ] Escort knows emergency stop procedure
[ ] Physical access badge issued (if needed)
[ ] Escort log started
```

---

## Phase 4: Access Termination

### 4.1 Confirm Work Complete

```
VENDOR COMPLETION CHECKLIST:
[ ] Vendor confirms all work complete
[ ] Vendor confirms no ongoing connections needed
[ ] Vendor provides summary of changes made
[ ] Vendor confirms no credentials saved locally
```

### 4.2 Disable Account Immediately

```bash
# Disable vendor account
wabadmin user disable vendor-siemens-emergency \
    --reason "Work complete per INC-20260129-0042"

# Remove temporary authorization
wabadmin authorization delete "EMERGENCY-INC-20260129-0042" \
    --force

# Verify no active sessions
wabadmin session list --user vendor-siemens-emergency --status active
# Should return: No active sessions

# Force disconnect if session still active
wabadmin session terminate --user vendor-siemens-emergency --all \
    --reason "Emergency access window closed"
```

### 4.3 Rotate Exposed Credentials

```bash
# If vendor accessed systems with stored credentials, rotate them:
wabadmin password rotate --device turbine-ctrl-01 --account service-user
wabadmin password rotate --device turbine-ctrl-02 --account service-user

# Verify rotation
wabadmin password status --device turbine-ctrl-01 --account service-user
```

### 4.4 Export Session Recording

```bash
# Export session recording for review
wabadmin session export \
    --session-id sess-12345 \
    --format video \
    --output /secure-storage/incidents/INC-20260129-0042/

# Also export command log
wabadmin session export \
    --session-id sess-12345 \
    --format commands \
    --output /secure-storage/incidents/INC-20260129-0042/

# Generate access report
wabadmin report generate \
    --type vendor-access \
    --user vendor-siemens-emergency \
    --start "2026-01-29" \
    --end "2026-01-30" \
    --output /secure-storage/incidents/INC-20260129-0042/access-report.pdf
```

---

## Phase 5: Post-Access Review

### 5.1 Review Session Recording

**Within 24 hours, review for:**

```
SESSION REVIEW CHECKLIST:
[ ] Commands executed match stated purpose
[ ] No unauthorized file access
[ ] No data exfiltration attempts
[ ] No persistence mechanisms installed
[ ] No unauthorized configuration changes
[ ] No credential harvesting
[ ] Session duration within approved window
```

### 5.2 Document Changes Made

```
CHANGE DOCUMENTATION:
=====================
Incident: INC-20260129-0042
Vendor: Siemens Energy
Date: 2026-01-29

Changes Made:
1. [Description of change 1]
   - System: turbine-ctrl-01
   - File/Setting: /etc/turbine/config.xml
   - Before: [value]
   - After: [value]

2. [Description of change 2]
   ...

Verification:
- [ ] Changes tested and working
- [ ] Backups available for rollback
- [ ] Documentation updated
```

### 5.3 Security Sign-Off

```
SECURITY REVIEW SIGN-OFF
========================

Incident: INC-20260129-0042
Review Date: _______________
Reviewer: _______________

[ ] Session recording reviewed - no concerns
[ ] All changes documented and approved
[ ] Credentials rotated as required
[ ] No security violations detected
[ ] Incident ticket updated and closed

Signature: ___________________ Date: ___________

OR

[ ] CONCERNS IDENTIFIED - Escalate to:
    Details: _________________________________
```

### 5.4 Update Incident Ticket

```
INCIDENT CLOSURE NOTES:
=======================
- Emergency access granted: 2026-01-29 14:00 UTC
- Access terminated: 2026-01-29 17:45 UTC
- Total access duration: 3 hours 45 minutes
- Session recording location: /secure-storage/incidents/INC-20260129-0042/
- Changes made: [Summary]
- Security review: Completed, no concerns
- Credentials rotated: Yes
- Status: CLOSED
```

---

## Appendix A: Pre-Staged Vendor Accounts

Create these accounts in advance (disabled):

| Vendor | Account Name | Target Group | Max Duration |
|--------|--------------|--------------|--------------|
| Siemens | vendor-siemens-emergency | Siemens-Systems | 8 hours |
| ABB | vendor-abb-emergency | ABB-Systems | 8 hours |
| Schneider | vendor-schneider-emergency | Schneider-Systems | 8 hours |
| Rockwell | vendor-rockwell-emergency | Rockwell-Systems | 8 hours |
| Honeywell | vendor-honeywell-emergency | Honeywell-Systems | 8 hours |
| Generic | vendor-other-emergency | Limited-Access | 4 hours |

**Setup Script:**

```bash
#!/bin/bash
# Create pre-staged vendor accounts

vendors=("siemens" "abb" "schneider" "rockwell" "honeywell" "other")

for vendor in "${vendors[@]}"; do
    wabadmin user create \
        --username "vendor-${vendor}-emergency" \
        --display-name "Emergency - ${vendor^}" \
        --email "vendor-emergency@company.com" \
        --status disabled \
        --type external \
        --mfa required \
        --comment "Pre-staged emergency vendor account"
done
```

---

## Appendix B: Breakglass Procedure

**When WALLIX Bastion is Unavailable:**

```
+===============================================================================+
|                    BREAKGLASS ACCESS (WALLIX Bastion DOWN)                            |
+===============================================================================+

  WARNING: Use ONLY when WALLIX Bastion is completely unavailable

  1. Retrieve breakglass credentials from:
     Location: [Secure safe / HSM / Sealed envelope location]
     Custodians: [Name 1], [Name 2] (dual control required)

  2. Log all access manually:
     - Start time
     - End time
     - Person accessing
     - Systems accessed
     - Commands run
     - Reason for access

  3. After WALLIX Bastion restored:
     - Import manual logs to WALLIX Bastion
     - Rotate ALL breakglass credentials
     - Reseal new credentials
     - Report to security within 24 hours

+===============================================================================+
```

---

## Appendix C: Quick Reference Card

Print and post in control rooms:

```
+===============================================================================+
|              EMERGENCY VENDOR ACCESS - QUICK REFERENCE                        |
+===============================================================================+

  STEP 1: GET APPROVAL
  - Call OT Manager: ____________
  - Call Security Lead: ____________
  - Log in ticket: INC-YYYYMMDD-XXXX

  STEP 2: ENABLE ACCESS
  - WALLIX Bastion: https://wallix.company.com/admin
  - Enable: vendor-[name]-emergency
  - Set expiry time

  STEP 3: NOTIFY SOC
  - Email: soc@company.com
  - Phone: ____________

  STEP 4: AFTER WORK COMPLETE
  - Disable account IMMEDIATELY
  - Rotate credentials
  - Export recording

  STEP 5: WITHIN 24 HOURS
  - Review recording
  - Security sign-off
  - Close ticket

  EMERGENCY CONTACTS:
  - WALLIX Bastion Admin: ____________
  - OT Manager: ____________
  - Security: ____________

+===============================================================================+
```

---

<p align="center">
  <a href="./README.md">← Back to Runbooks</a>
</p>
