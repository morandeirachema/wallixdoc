# Break Glass Procedures - Emergency Access

> Emergency access procedures when normal PAM, SSO, or MFA channels are unavailable

---

## Document Information

| Property | Value |
|----------|-------|
| **Purpose** | Emergency access procedures for when normal PAM authentication channels fail |
| **Classification** | Confidential - Restricted Distribution |
| **Authorization Required** | CISO or IT Director approval before invocation |
| **Review Frequency** | Quarterly, or after any break glass invocation |
| **Version** | 1.0 |
| **Last Updated** | February 2026 |

---

## Table of Contents

- [Break Glass Procedures - Emergency Access](#break-glass-procedures---emergency-access)
  - [Document Information](#document-information)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [When to Invoke Break Glass](#when-to-invoke-break-glass)
    - [Invocation Criteria](#invocation-criteria)
    - [Severity Classification](#severity-classification)
  - [Break Glass Account Inventory](#break-glass-account-inventory)
    - [Pre-Created Emergency Accounts](#pre-created-emergency-accounts)
      - [Bastion Break Glass Accounts](#bastion-break-glass-accounts)
      - [Target System Break Glass Accounts](#target-system-break-glass-accounts)
      - [Infrastructure Break Glass Accounts](#infrastructure-break-glass-accounts)
    - [Credential Storage](#credential-storage)
  - [Emergency Access Procedures](#emergency-access-procedures)
    - [Scenario A: Access Manager Down](#scenario-a-access-manager-down)
    - [Scenario B: FortiAuthenticator Down](#scenario-b-fortiauthenticator-down)
    - [Scenario C: HAProxy Down](#scenario-c-haproxy-down)
    - [Scenario D: Bastion Cluster Down](#scenario-d-bastion-cluster-down)
    - [Scenario E: Full Site Down](#scenario-e-full-site-down)
    - [Scenario F: Complete PAM Stack Down](#scenario-f-complete-pam-stack-down)
  - [Break Glass Account Management](#break-glass-account-management)
    - [Account Creation](#account-creation)
    - [Secure Storage](#secure-storage)
    - [Credential Rotation](#credential-rotation)
    - [Quarterly Testing](#quarterly-testing)
  - [Post Break Glass Procedures](#post-break-glass-procedures)
    - [Step 1: Audit Trail](#step-1-audit-trail)
    - [Step 2: Re-Secure Systems](#step-2-re-secure-systems)
    - [Step 3: Credential Rotation](#step-3-credential-rotation)
    - [Step 4: Incident Report](#step-4-incident-report)
  - [Authorization and Approval Matrix](#authorization-and-approval-matrix)
    - [Approval Authority](#approval-authority)
    - [Approval Process](#approval-process)
    - [Emergency Contact List](#emergency-contact-list)
  - [Cross-References](#cross-references)

---

## Overview

Break glass procedures provide emergency access to critical systems when normal authentication channels (SSO, MFA, session brokering) are unavailable. These procedures bypass standard security controls and must be:

- **Authorized** before use (CISO or IT Director approval)
- **Audited** completely (every action logged)
- **Time-limited** (revoked as soon as normal channels are restored)
- **Reviewed** after each invocation (post-incident analysis)

```
+===============================================================================+
|  BREAK GLASS DECISION TREE                                                    |
+===============================================================================+
|                                                                               |
|  Normal Access Flow:                                                          |
|  User → Access Manager (SSO) → FortiAuth (MFA) → HAProxy → Bastion → Target   |
|                                                                               |
|  Break Glass Bypass Levels:                                                   |
|                                                                               |
|  Level 1: AM Down      → Direct Bastion access (bypass SSO)                   |
|  Level 2: MFA Down     → Local auth fallback (bypass MFA)                     |
|  Level 3: HAProxy Down → Direct Bastion IP (bypass LB)                        |
|  Level 4: Bastion Down → Cross-site emergency access                          |
|  Level 5: Full Stack   → Direct target access with sealed credentials         |
|                                                                               |
|  Each level requires escalating authorization.                                |
|                                                                               |
+===============================================================================+
```

---

## When to Invoke Break Glass

### Invocation Criteria

Break glass procedures should **only** be invoked when **all** of the following are true:

- [ ] Normal authentication channel is confirmed unavailable (not just slow)
- [ ] The outage affects critical business operations
- [ ] Standard troubleshooting has been attempted (see [12-contingency-plan.md](12-contingency-plan.md))
- [ ] An authorized approver has granted permission
- [ ] The break glass invocation is logged in the incident tracking system

### Severity Classification

| Severity | Condition | Break Glass Level | Approver |
|----------|-----------|-------------------|----------|
| **SEV-1** | Complete PAM stack down, critical operations blocked | Level 5 | CISO |
| **SEV-2** | Bastion cluster down at one or more sites | Level 4 | IT Director |
| **SEV-3** | Access Manager or MFA unavailable | Level 1-2 | Operations Manager |
| **SEV-4** | HAProxy down, workaround available | Level 3 | On-call Engineer |

---

## Break Glass Account Inventory

### Pre-Created Emergency Accounts

These accounts must be created during initial deployment and tested quarterly.

#### Bastion Break Glass Accounts

| Account | Purpose | Authentication | Sites |
|---------|---------|----------------|-------|
| `bg-admin-site1` | Emergency Bastion admin | Local password | Site 1 |
| `bg-admin-site2` | Emergency Bastion admin | Local password | Site 2 |
| `bg-admin-site3` | Emergency Bastion admin | Local password | Site 3 |
| `bg-admin-site4` | Emergency Bastion admin | Local password | Site 4 |
| `bg-admin-site5` | Emergency Bastion admin | Local password | Site 5 |
| `bg-operator` | Emergency session operator | Local password | All sites |

#### Target System Break Glass Accounts

| Account | Target Type | Authentication | Storage |
|---------|-------------|----------------|---------|
| `bg-windows-admin` | Windows servers | Local Administrator | Sealed envelope / vault |
| `bg-linux-root` | Linux servers (SSH key) | SSH key pair | Sealed envelope / vault |
| `bg-ot-operator` | OT systems via RDS | Local password | Sealed envelope / vault |
| `bg-network-admin` | Network equipment | Local password | Sealed envelope / vault |

#### Infrastructure Break Glass Accounts

| Account | Component | Authentication | Storage |
|---------|-----------|----------------|---------|
| `haproxy-admin` | HAProxy servers | SSH key | Sealed envelope / vault |
| `bastion-console` | Bastion IPMI/iLO | Local password | Sealed envelope / vault |
| `rds-localadmin` | WALLIX RDS servers | Local Administrator | Sealed envelope / vault |
| `db-root` | MariaDB (Bastion) | Local password | Sealed envelope / vault |

### Credential Storage

```
+===============================================================================+
|  BREAK GLASS CREDENTIAL STORAGE                                               |
+===============================================================================+
|                                                                               |
|  Primary Storage:                                                             |
|  +-------------------------------+                                            |
|  | Enterprise Password Vault     |  ← Online, requires vault authentication   |
|  | (CyberArk / HashiCorp Vault)  |                                            |
|  +-------------------------------+                                            |
|                                                                               |
|  Secondary Storage (Offline):                                                 |
|  +-------------------------------+                                            |
|  | Physical Safe (Site 1 DC)     |  ← Sealed envelopes, dual-key access       |
|  | Physical Safe (Site 3 DC)     |  ← Geographically separated backup         |
|  +-------------------------------+                                            |
|                                                                               |
|  Each sealed envelope contains:                                               |
|  - Account username                                                           |
|  - Password (printed, not digital)                                            |
|  - SSH private key (USB drive, encrypted)                                     |
|  - Instructions for the specific scenario                                     |
|                                                                               |
+===============================================================================+
```

---

## Emergency Access Procedures

### Scenario A: Access Manager Down

**Condition**: Both Access Managers are down. SSO authentication and session brokering unavailable. Bastions and HAProxy are operational.

**Break Glass Level**: 1
**Approver**: Operations Manager

**Procedure**:

```bash
# Step 1: Confirm AM is down (both nodes)
curl -sf https://am.company.com/health || echo "AM-1 DOWN"
curl -sf https://am-secondary.company.com/health || echo "AM-2 DOWN"

# Step 2: Enable local authentication fallback on each Bastion
# Repeat for all affected sites
for site in 1 2 3 4 5; do
  ssh bg-admin@bastion1-site${site}.company.com <<'REMOTE'
    wabadmin auth configure --method local --fallback enable
    echo "Local auth enabled on Site ${site}"
REMOTE
done

# Step 3: Users authenticate directly to Bastion
# URL: https://bastion-siteX.company.com (via HAProxy VIP)
# Username: bg-operator (or their local Bastion account if it exists)
# Password: [From break glass credential storage]

# Step 4: Log the break glass invocation
echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') BREAK-GLASS-INVOKED level=1 scenario=AM-down approver=[NAME] operator=[NAME]" \
  >> /var/log/break-glass-audit.log
```

**User Instructions**:

```
BREAK GLASS - ACCESS MANAGER DOWN
==================================
1. Open browser: https://bastion-siteX.company.com
2. Do NOT click "Login with SSO"
3. Use the "Local Login" form
4. Username: [your local Bastion account or bg-operator]
5. Password: [provided by operations team]
6. NOTE: MFA may still be required if FortiAuthenticator is operational
7. All sessions are being recorded for audit purposes
```

**Validation**:
- [ ] Users can authenticate via local login
- [ ] Sessions to target systems work
- [ ] Session recording is active
- [ ] Break glass invocation logged

---

### Scenario B: FortiAuthenticator Down

**Condition**: Both FortiAuthenticator nodes are down. MFA challenges fail. SSO and Bastion are operational.

**Break Glass Level**: 2
**Approver**: Operations Manager

**Procedure**:

```bash
# Step 1: Confirm FortiAuthenticator is down
nc -zvu 10.20.0.60 1812  # Primary
nc -zvu 10.20.0.61 1812  # Secondary

# Step 2: Temporarily disable MFA requirement on each Bastion
for site in 1 2 3 4 5; do
  ssh bg-admin@bastion1-site${site}.company.com <<'REMOTE'
    wabadmin auth configure --mfa-mode disabled
    echo "MFA disabled on Site ${site}"
REMOTE
done

# Step 3: Users authenticate with username/password only (no MFA token)
# SSO may still work if AM is up (without MFA step)

# Step 4: Log the break glass invocation
echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') BREAK-GLASS-INVOKED level=2 scenario=MFA-down approver=[NAME] operator=[NAME]" \
  >> /var/log/break-glass-audit.log

# Step 5: IMPORTANT - Set a time limit for MFA bypass
# Schedule re-check in 2 hours:
echo "wabadmin auth configure --mfa-mode required" | at now + 2 hours
```

**Security Note**: With MFA disabled, authentication relies solely on passwords. Monitor for unusual login patterns during this period.

**Validation**:
- [ ] Users can authenticate without MFA token
- [ ] SSO flow completes (if AM is up) without MFA step
- [ ] Session recording is active
- [ ] MFA bypass is time-limited
- [ ] Break glass invocation logged

---

### Scenario C: HAProxy Down

**Condition**: Both HAProxy nodes at a site are down. VIP is unreachable. Bastion nodes are operational.

**Break Glass Level**: 3
**Approver**: On-call Engineer

**Procedure**:

```bash
# Step 1: Confirm HAProxy pair is down
ping -c 3 -W 2 10.10.X.100  # VIP
ping -c 3 -W 2 10.10.X.5    # HAProxy-1
ping -c 3 -W 2 10.10.X.6    # HAProxy-2

# Step 2: Direct users to Bastion IP addresses
# Users connect directly to:
#   Bastion-1: https://10.10.X.11
#   Bastion-2: https://10.10.X.12

# Step 3: Update DNS (if TTL allows quick propagation)
# Change: bastion-siteX.company.com → 10.10.X.11
# Or add: bastion-direct-siteX.company.com → 10.10.X.11

# Step 4: Update Access Manager to use direct Bastion URL
curl -X PATCH https://am.company.com/api/v1/bastions/bastion-siteX \
  -H "Authorization: Bearer AM_API_KEY" \
  -d '{"url": "https://10.10.X.11"}'

# Step 5: Log the break glass invocation
echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') BREAK-GLASS-INVOKED level=3 scenario=HAProxy-down site=X approver=[NAME] operator=[NAME]" \
  >> /var/log/break-glass-audit.log
```

**User Instructions**:

```
BREAK GLASS - LOAD BALANCER DOWN AT SITE X
============================================
1. Do NOT use bastion-siteX.company.com (VIP is down)
2. Connect directly to:
   - Primary:   https://10.10.X.11  (Bastion-1)
   - Secondary: https://10.10.X.12  (Bastion-2)
3. You may see a certificate warning (hostname mismatch) - proceed
4. Authentication works as normal (SSO/MFA still active)
5. All sessions are recorded for audit
```

**Validation**:
- [ ] Users can connect directly to Bastion IPs
- [ ] SSO authentication works (if AM is up)
- [ ] Access Manager updated with direct Bastion URL
- [ ] Break glass invocation logged

---

### Scenario D: Bastion Cluster Down

**Condition**: Both Bastion nodes at a site are down. No PAM access at that site. Other sites are operational.

**Break Glass Level**: 4
**Approver**: IT Director

**Procedure**:

```bash
# Step 1: Confirm both Bastion nodes are down
ping -c 3 -W 2 10.10.X.11  # Bastion-1
ping -c 3 -W 2 10.10.X.12  # Bastion-2

# Step 2: Disable site in Access Manager
curl -X PATCH https://am.company.com/api/v1/bastions/bastion-siteX \
  -H "Authorization: Bearer AM_API_KEY" \
  -d '{"enabled": false}'

# Step 3: Redirect users to nearest alternative site
# Site mapping for failover:
#   Site 1 users → Site 2 (bastion-site2.company.com)
#   Site 2 users → Site 1 (bastion-site1.company.com)
#   Site 3 users → Site 2 (bastion-site2.company.com)
#   Site 4 users → Site 5 (bastion-site5.company.com)
#   Site 5 users → Site 4 (bastion-site4.company.com)

# Step 4: Verify alternative site has capacity
wabadmin license status  # On alternative site

# Step 5: If users need access to site-specific targets only reachable
# from the down site, consider cross-site target configuration
# (temporary - add targets to alternative site's Bastion)

# Step 6: Log the break glass invocation
echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') BREAK-GLASS-INVOKED level=4 scenario=Bastion-down site=X approver=[NAME] operator=[NAME]" \
  >> /var/log/break-glass-audit.log
```

**User Instructions**:

```
BREAK GLASS - BASTION DOWN AT SITE X
======================================
1. Site X PAM service is temporarily unavailable
2. Connect to your designated failover site:
   - Site 1 users → https://bastion-site2.company.com
   - Site 2 users → https://bastion-site1.company.com
   - Site 3 users → https://bastion-site2.company.com
   - Site 4 users → https://bastion-site5.company.com
   - Site 5 users → https://bastion-site4.company.com
3. Authentication works as normal (SSO/MFA)
4. Some site-specific targets may not be reachable from alternative sites
5. Contact operations@company.com if you need access to site-specific targets
```

**Validation**:
- [ ] Users redirected to alternative site successfully
- [ ] Alternative site has sufficient license capacity
- [ ] Access Manager routing updated
- [ ] Break glass invocation logged

---

### Scenario E: Full Site Down

**Condition**: Entire datacenter site is down (power, network, physical disaster). All site components unreachable.

**Break Glass Level**: 4
**Approver**: IT Director

**Procedure**:

```bash
# Step 1: Confirm full site loss
ping -c 3 -W 2 10.10.X.100  # HAProxy VIP
ping -c 3 -W 2 10.10.X.11   # Bastion-1
ping -c 3 -W 2 10.10.X.12   # Bastion-2
ping -c 3 -W 2 10.10.X.30   # WALLIX RDS
# All unreachable = full site loss confirmed

# Step 2: Follow Scenario D procedure for user redirection
# Step 3: Additionally address OT access:
#   - OT users must use WALLIX RDS at an alternative site
#   - If OT targets are only reachable from the down site, OT access
#     is unavailable until site is restored

# Step 4: Activate disaster recovery plan
# See 12-contingency-plan.md, Scenario 15: Full Site Loss

# Step 5: Log the break glass invocation
echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') BREAK-GLASS-INVOKED level=4 scenario=full-site-down site=X approver=[NAME] operator=[NAME]" \
  >> /var/log/break-glass-audit.log
```

**Validation**:
- [ ] Users redirected to alternative sites
- [ ] OT access impact assessed and communicated
- [ ] Disaster recovery plan activated
- [ ] Stakeholders notified
- [ ] Break glass invocation logged

---

### Scenario F: Complete PAM Stack Down

**Condition**: All PAM components are unavailable (all Bastions, all AMs, or a combination that prevents any PAM access). Critical operations require immediate target system access.

**Break Glass Level**: 5
**Approver**: CISO

**This is the most severe break glass scenario. Direct target access bypasses all PAM controls.**

**Procedure**:

```bash
# Step 1: Obtain CISO authorization (verbal + written confirmation)
# Document: approver name, time, reason, expected duration

# Step 2: Retrieve sealed credentials from physical safe
# Primary safe: Site 1 DC
# Secondary safe: Site 3 DC
# Requires dual-key access (two authorized personnel)

# Step 3: Access target systems directly using sealed credentials

# For Windows targets:
# Use bg-windows-admin account
# RDP directly to target: mstsc /v:target-server.company.com

# For Linux targets:
# Use bg-linux-root SSH key
ssh -i /path/to/bg-linux-root.key root@target-server.company.com

# For OT targets:
# Use bg-ot-operator account
# RDP directly to WALLIX RDS: mstsc /v:10.10.X.30

# For network equipment:
# Use bg-network-admin account
ssh bg-network-admin@switch01.company.com

# Step 4: CRITICAL - Log every action manually
# Since PAM is not recording sessions, maintain a manual log:
echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') DIRECT-ACCESS user=[NAME] target=[TARGET] protocol=[PROTOCOL] reason=[REASON]" \
  >> /var/log/break-glass-direct-access.log

# Step 5: Set a hard time limit (maximum 4 hours)
# Schedule credential rotation after break glass ends

# Step 6: Log the break glass invocation
echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') BREAK-GLASS-INVOKED level=5 scenario=complete-PAM-down approver=[NAME] operator=[NAME]" \
  >> /var/log/break-glass-audit.log
```

**Critical Security Requirements for Level 5**:

- [ ] Two authorized personnel present (four-eyes principle)
- [ ] Every command executed is documented in the manual log
- [ ] Time limit enforced (maximum 4 hours before re-authorization)
- [ ] Only critical operations performed (no exploratory access)
- [ ] All sealed credentials rotated immediately after PAM is restored

**Validation**:
- [ ] CISO authorization obtained and documented
- [ ] Sealed credentials retrieved with dual-key access
- [ ] Manual access log maintained throughout
- [ ] Time limit enforced
- [ ] Break glass invocation logged

---

## Break Glass Account Management

### Account Creation

Create break glass accounts during initial deployment (Phase 3, see [HOWTO.md](HOWTO.md)).

```bash
# Create Bastion break glass admin accounts (per site)
for site in 1 2 3 4 5; do
  ssh bastion1-site${site}.company.com <<REMOTE
    # Create break glass admin
    wabadmin user create \
      --username "bg-admin-site${site}" \
      --email "bg-admin-site${site}@company.com" \
      --auth-method local \
      --password "[GENERATED_SECURE_PASSWORD]" \
      --role admin \
      --description "Break glass emergency admin account"

    # Create break glass operator
    wabadmin user create \
      --username "bg-operator" \
      --email "bg-operator@company.com" \
      --auth-method local \
      --password "[GENERATED_SECURE_PASSWORD]" \
      --role operator \
      --description "Break glass emergency operator account"

    # Disable MFA for break glass accounts (they are used when MFA is down)
    wabadmin user configure \
      --username "bg-admin-site${site}" \
      --mfa-exempt true

    wabadmin user configure \
      --username "bg-operator" \
      --mfa-exempt true
REMOTE
done
```

### Secure Storage

```bash
# 1. Generate strong passwords for all break glass accounts
openssl rand -base64 24  # Per account

# 2. Print credentials (do NOT store digitally outside vault)
# 3. Place in tamper-evident sealed envelopes
# 4. Store in physical safe with dual-key access
# 5. Store a copy in enterprise password vault (if available independently of PAM)

# Sealed envelope contents per account:
# - Account username
# - Password (printed)
# - Applicable systems/sites
# - Brief usage instructions
# - Date sealed
# - Envelope serial number
```

### Credential Rotation

```bash
# Rotate break glass credentials quarterly (or after any invocation)

# 1. Generate new passwords
NEW_PASSWORD=$(openssl rand -base64 24)

# 2. Update Bastion break glass accounts
wabadmin user change-password \
  --username "bg-admin-siteX" \
  --new-password "${NEW_PASSWORD}"

# 3. Update target system break glass accounts
# (Windows, Linux, OT, network - coordinate with system owners)

# 4. Create new sealed envelopes with updated credentials
# 5. Destroy old sealed envelopes (shred)
# 6. Update enterprise password vault
# 7. Log the rotation
echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') BG-CREDENTIAL-ROTATION accounts=[LIST] rotated-by=[NAME]" \
  >> /var/log/break-glass-audit.log
```

### Quarterly Testing

```bash
# Test break glass accounts quarterly to ensure they work

# Test Plan:
- [ ] Verify bg-admin-siteX can log in to each Bastion (local auth)
- [ ] Verify bg-operator can log in and create sessions
- [ ] Verify bg-windows-admin can RDP to a test Windows target
- [ ] Verify bg-linux-root SSH key works on a test Linux target
- [ ] Verify sealed envelopes are intact and accounted for
- [ ] Verify enterprise password vault entries are current
- [ ] Document test results and any issues

# After testing:
# - Rotate all tested credentials (they were used)
# - Update sealed envelopes
# - File test results
```

---

## Post Break Glass Procedures

After every break glass invocation, complete the following steps within 24 hours of normal service restoration.

### Step 1: Audit Trail

```bash
# Collect all break glass audit logs
cat /var/log/break-glass-audit.log
cat /var/log/break-glass-direct-access.log  # Level 5 only

# Collect Bastion audit logs for the break glass period
wabadmin log export \
  --start "[BREAK_GLASS_START_TIME]" \
  --end "[BREAK_GLASS_END_TIME]" \
  --output /audit/break-glass-incident-[DATE].log

# Review all sessions created during break glass period
wabadmin session list \
  --start "[BREAK_GLASS_START_TIME]" \
  --end "[BREAK_GLASS_END_TIME]"
```

### Step 2: Re-Secure Systems

```bash
# 1. Disable local auth fallback (if enabled in Scenario A)
for site in 1 2 3 4 5; do
  ssh bastion1-site${site}.company.com \
    "wabadmin auth configure --method local --fallback disable"
done

# 2. Re-enable MFA (if disabled in Scenario B)
for site in 1 2 3 4 5; do
  ssh bastion1-site${site}.company.com \
    "wabadmin auth configure --mfa-mode required"
done

# 3. Revert DNS changes (if made in Scenario C)
# Restore: bastion-siteX.company.com → 10.10.X.100 (VIP)

# 4. Revert Access Manager URL changes
curl -X PATCH https://am.company.com/api/v1/bastions/bastion-siteX \
  -H "Authorization: Bearer AM_API_KEY" \
  -d '{"url": "https://bastion-siteX.company.com", "enabled": true}'

# 5. Re-enable disabled sites in Access Manager
```

### Step 3: Credential Rotation

```bash
# MANDATORY: Rotate all break glass credentials that were used

# 1. Identify which accounts were used
grep "BREAK-GLASS\|DIRECT-ACCESS" /var/log/break-glass-audit.log

# 2. Rotate those credentials immediately
# Follow "Credential Rotation" procedure above

# 3. For Level 5 (direct target access):
#    Rotate ALL sealed credentials, even unused ones
#    (envelope seals were broken to retrieve them)
```

### Step 4: Incident Report

Complete within 5 business days:

```markdown
# Break Glass Incident Report

## Summary
- **Date/Time**: [Invocation start] to [Normal service restored]
- **Break Glass Level**: [1-5]
- **Scenario**: [A-F]
- **Approver**: [Name, Title]
- **Operator(s)**: [Names]

## Root Cause
[Why normal channels were unavailable - link to contingency incident]

## Actions Taken During Break Glass
| Time | Action | Operator | Target |
|------|--------|----------|--------|
| HH:MM | [Description] | [Name] | [System] |

## Systems Accessed
[List all systems accessed via break glass credentials]

## Security Impact Assessment
- Were any unauthorized actions detected? [Yes/No]
- Were credentials potentially exposed? [Yes/No]
- Were all actions logged? [Yes/No]

## Credentials Rotated
- [ ] Break glass Bastion accounts
- [ ] Break glass target accounts
- [ ] Sealed envelopes replaced
- [ ] Password vault updated

## Recommendations
[Changes to prevent future break glass invocations]
```

---

## Authorization and Approval Matrix

### Approval Authority

| Break Glass Level | Approver | Backup Approver | Notification |
|-------------------|----------|-----------------|--------------|
| **Level 1** (AM down) | Operations Manager | Senior Sysadmin | IT Director |
| **Level 2** (MFA down) | Operations Manager | Senior Sysadmin | IT Director, Security |
| **Level 3** (HAProxy down) | On-call Engineer | Operations Manager | Operations Manager |
| **Level 4** (Bastion/site down) | IT Director | CISO | CISO, CIO |
| **Level 5** (Complete PAM down) | CISO | CIO | CIO, Legal, Compliance |

### Approval Process

```
+===============================================================================+
|  BREAK GLASS APPROVAL FLOW                                                    |
+===============================================================================+
|                                                                               |
|  1. Operator identifies need for break glass                                  |
|       ↓                                                                       |
|  2. Operator contacts approver (phone call - not email)                       |
|       ↓                                                                       |
|  3. Approver verifies:                                                        |
|     - Normal channels are genuinely unavailable                               |
|     - Standard recovery has been attempted                                    |
|     - Business impact justifies break glass                                   |
|       ↓                                                                       |
|  4. Approver grants verbal authorization                                      |
|       ↓                                                                       |
|  5. Operator executes break glass procedure                                   |
|       ↓                                                                       |
|  6. Approver sends written confirmation (email) within 1 hour                 |
|       ↓                                                                       |
|  7. Post break glass procedures executed within 24 hours                      |
|                                                                               |
+===============================================================================+
```

### Emergency Contact List

| Role | Primary | Phone | Email |
|------|---------|-------|-------|
| **CISO** | [Name] | [Phone] | ciso@company.com |
| **IT Director** | [Name] | [Phone] | it-director@company.com |
| **Operations Manager** | [Name] | [Phone] | ops-manager@company.com |
| **On-call Engineer** | [Rotation] | [On-call phone] | oncall@company.com |
| **WALLIX Support** | N/A | [Support phone] | support@wallix.com |

---

## Cross-References

| Document | Relevance |
|----------|-----------|
| [12-contingency-plan.md](12-contingency-plan.md) | Disaster recovery (attempt before break glass) |
| [03-access-manager-integration.md](03-access-manager-integration.md) | SSO/MFA configuration details |
| [05-haproxy-setup.md](05-haproxy-setup.md) | HAProxy troubleshooting |
| [06-bastion-active-active.md](06-bastion-active-active.md) | Bastion cluster recovery |
| [07-bastion-active-passive.md](07-bastion-active-passive.md) | Bastion cluster recovery |
| [10-testing-validation.md](10-testing-validation.md) | Post-recovery validation |
| [HOWTO.md](HOWTO.md) | Initial break glass account setup (Phase 3) |

---

**Document Version**: 1.0
**Last Updated**: February 2026
