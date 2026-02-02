# Breakglass Access Procedures

## Emergency Administrative Access When Normal Authentication Fails

This document provides procedures for emergency access when WALLIX Bastion normal authentication is unavailable.

---

## When to Use Breakglass

```
+===============================================================================+
|                       BREAKGLASS DECISION TREE                                |
+===============================================================================+

  Can you authenticate to WALLIX Bastion normally?
            |
            v
       +----+----+
       |   YES   |-------> DO NOT use breakglass
       +---------+
            |
           NO
            |
            v
  Is the issue with YOUR credentials only?
            |
            v
       +----+----+
       |   YES   |-------> Contact IT Help Desk for password reset
       +---------+
            |
           NO (System-wide auth failure)
            |
            v
  Is FortiAuthenticator (MFA) down?
            |
            v
       +----+----+
       |   YES   |-------> Use MFA Bypass procedure (Section 2)
       +---------+
            |
           NO
            |
            v
  Is Active Directory down?
            |
            v
       +----+----+
       |   YES   |-------> Use Local Admin procedure (Section 3)
       +---------+
            |
           NO
            |
            v
  Is WALLIX Bastion completely inaccessible?
            |
            v
       +----+----+
       |   YES   |-------> Use Full Breakglass procedure (Section 4)
       +---------+

+===============================================================================+
```

---

## Section 1: Breakglass Account Inventory

### Pre-Configured Emergency Accounts

| Account | Type | MFA | Storage Location | Custodians |
|---------|------|-----|------------------|------------|
| `breakglass-admin` | Local WALLIX Bastion Admin | Disabled | Sealed envelope in safe | IT Director, CISO |
| `emergency-ops` | Local WALLIX Bastion Operator | Disabled | Sealed envelope in safe | OT Manager, IT Director |
| `root` (node1) | Linux root | N/A | HSM/Password vault | IT Director, CTO |
| `root` (node2) | Linux root | N/A | HSM/Password vault | IT Director, CTO |

### Storage Locations

```
PRIMARY LOCATION:
- Building: Corporate HQ
- Room: Server Room A, Safe #3
- Access: Dual key (IT Director + CISO)

SECONDARY LOCATION:
- Building: DR Site
- Room: Secure Cabinet B
- Access: IT Director key
```

---

## Section 2: MFA Bypass (FortiAuthenticator Down)

### Scenario
FortiAuthenticator is unavailable but AD and WALLIX Bastion are functioning.

### Authorization Required
- Verbal approval from: Security Lead OR IT Director

### Procedure

```bash
# Step 1: Verify FortiAuth is actually down
ping fortiauth.company.com
curl -sk https://fortiauth.company.com/

# Step 2: Check if MFA bypass account exists
# This account should be pre-configured with MFA disabled

# Step 3: Login with MFA bypass account
# URL: https://wallix.company.com
# Username: emergency-ops
# Password: [Retrieved from secure storage]

# Step 4: If bypass account doesn't exist, use CLI
ssh root@wallix-node1

# Temporarily disable MFA (requires root)
wabadmin auth mfa disable --temporary --duration 2h \
    --reason "FortiAuth outage" \
    --approved-by "Security Lead Name"

# Step 5: Login normally with AD credentials
# MFA will be skipped for 2 hours

# Step 6: After FortiAuth restored
wabadmin auth mfa enable
```

### Logging Requirements

```
MFA BYPASS LOG
==============
Date/Time: ____________________
Reason: FortiAuthenticator unavailable
Authorized by: ____________________
Bypass duration: ____________________
Users who logged in during bypass:
- ____________________
- ____________________
MFA restored: ____________________
```

---

## Section 3: Local Admin Access (AD Down)

### Scenario
Active Directory is unavailable, cannot authenticate LDAP users.

### Authorization Required
- Verbal approval from: IT Director OR OT Manager

### Procedure

```bash
# Step 1: Verify AD is actually down
nc -zv dc-lab.company.com 636
ldapsearch -x -H ldaps://dc-lab.company.com:636 -D "test" -W

# Step 2: Retrieve local admin credentials
# Location: Sealed envelope in Server Room Safe #3
# Requires: Dual authorization

# Step 3: Login with local admin account
# URL: https://wallix.company.com
# Username: breakglass-admin
# Password: [From sealed envelope]

# Step 4: Perform necessary administrative tasks

# Step 5: When AD is restored
# - Verify LDAP authentication working
# - Re-seal breakglass credentials if used
# - Rotate breakglass password

# Step 6: Document all actions taken
wabadmin audit search --user breakglass-admin --last 24h > /tmp/breakglass-audit.log
```

### Post-Incident Actions

```bash
# Rotate breakglass password
wabadmin user passwd breakglass-admin
# Enter new strong password

# Update sealed envelope
# Print new password
# Seal in new envelope
# Store in safe
# Destroy old envelope

# Verify rotation
wabadmin user show breakglass-admin
```

---

## Section 4: Full Breakglass (WALLIX Bastion Inaccessible)

### Scenario
WALLIX Bastion web UI and services are completely unavailable. Need direct system access.

### Authorization Required
- Verbal approval from: CTO OR IT Director AND Security Lead

### Procedure

```bash
# Step 1: Access server console
# - VMware: vSphere console
# - Hyper-V: VM console
# - Physical: iLO/iDRAC/IPMI

# Step 2: Retrieve root credentials
# Location: HSM or Password Vault (CyberArk/1Password)
# Requires: Dual authorization

# Step 3: Login as root
# Username: root
# Password: [From secure storage]

# Step 4: Diagnose the issue
systemctl status wallix-bastion
journalctl -u wallix-bastion --since "30 minutes ago"
df -h
free -m
top -bn1

# Step 5: Attempt recovery
# If service crashed:
systemctl restart wallix-bastion

# If disk full:
du -sh /var/wab/* | sort -h
# Clear space as needed

# If database issue:
systemctl status mariadb
sudo mysql -e "SELECT 1"

# Step 6: Verify recovery
curl -sk https://localhost/
wabadmin status

# Step 7: Document all actions
# Save all command output to file
script -a /root/breakglass-$(date +%Y%m%d).log
# ... perform actions ...
exit  # Stop recording
```

---

## Section 5: Direct Target Access (WALLIX Bastion Completely Failed)

### Scenario
WALLIX Bastion cannot be recovered quickly, but critical systems need immediate access.

### WARNING
```
+===============================================================================+
|                              EXTREME CAUTION                                  |
+===============================================================================+
|                                                                               |
|  Direct target access bypasses ALL PAM controls:                              |
|  - No session recording                                                       |
|  - No credential injection                                                    |
|  - No audit trail in WALLIX Bastion                                                   |
|                                                                               |
|  Use ONLY when:                                                               |
|  - Safety or life is at risk                                                  |
|  - Critical production impact                                                 |
|  - WALLIX Bastion cannot be recovered within acceptable timeframe                     |
|                                                                               |
|  MUST have written authorization from:                                        |
|  - CTO or CEO                                                                 |
|  - Documented in incident ticket                                              |
|                                                                               |
+===============================================================================+
```

### Procedure

```bash
# Step 1: Retrieve direct target credentials
# Location: Emergency credential safe
# Requires: CTO/CEO written authorization

# Step 2: Access target directly
ssh root@linux-target  # For SSH
# or
mstsc /v:windows-target  # For RDP

# Step 3: MANUALLY LOG ALL ACTIONS
# Start screen recording if possible
# Document every command/action in real-time

# Example manual log:
cat >> /root/emergency-access-$(date +%Y%m%d).log << EOF
Time: $(date)
Target: linux-target
User: root
Actions:
- Checked service status
- Restarted application
- Verified functionality
EOF

# Step 4: After work complete
# - Rotate target credentials IMMEDIATELY
# - Import manual logs to security system
# - Complete incident report
```

### Post-Access Requirements

```
DIRECT ACCESS INCIDENT REPORT
=============================
[ ] All actions documented in log
[ ] Screen recording saved (if available)
[ ] Target credentials rotated
[ ] WALLIX Bastion restored and verified
[ ] Security team notified
[ ] Incident ticket completed
[ ] Post-incident review scheduled
```

---

## Section 6: Credential Rotation After Breakglass

### Rotate WALLIX Bastion Breakglass Accounts

```bash
# Generate new strong password
NEW_PASS=$(openssl rand -base64 24)

# Rotate breakglass-admin password
wabadmin user passwd breakglass-admin "$NEW_PASS"

# Print for sealed envelope
echo "breakglass-admin: $NEW_PASS" | lp -d secure-printer

# Verify login works with new password
# (test in incognito browser)

# Seal new credentials in envelope
# Store in designated safe
# Destroy old envelope
```

### Rotate Target Credentials

```bash
# If direct target access was used, rotate those credentials

# For targets managed by WALLIX Bastion
wabadmin password rotate --device linux-target --account root
wabadmin password rotate --device windows-target --account Administrator

# Verify rotation
wabadmin password status --device linux-target --account root
```

### Rotate Linux Root Passwords

```bash
# Generate new root password
NEW_ROOT_PASS=$(openssl rand -base64 24)

# On each WALLIX Bastion node
echo "root:$NEW_ROOT_PASS" | chpasswd

# Store in HSM/password vault
# Update sealed envelope if applicable
```

---

## Section 7: Breakglass Audit Report

After any breakglass event, complete this report within 24 hours:

```
BREAKGLASS INCIDENT REPORT
==========================

INCIDENT DETAILS
----------------
Date: ____________________
Time (start): ____________________
Time (end): ____________________
Duration: ____________________
Incident ID: ____________________

AUTHORIZATION
-------------
Authorized by: ____________________
Authorization method: [ ] Verbal [ ] Written [ ] Email
Authorization timestamp: ____________________

BREAKGLASS TYPE USED
--------------------
[ ] MFA Bypass (Section 2)
[ ] Local Admin (Section 3)
[ ] Full Breakglass (Section 4)
[ ] Direct Target Access (Section 5)

REASON FOR BREAKGLASS
---------------------
Root cause: ____________________
Systems affected: ____________________
Business impact: ____________________

ACTIONS TAKEN
-------------
1. ____________________
2. ____________________
3. ____________________
4. ____________________

PERSONNEL INVOLVED
------------------
- Name: ______________ Role: ______________
- Name: ______________ Role: ______________

POST-INCIDENT ACTIONS
---------------------
[ ] Breakglass credentials rotated
[ ] Target credentials rotated (if applicable)
[ ] Audit logs exported and archived
[ ] Sealed envelopes replaced
[ ] Root cause addressed
[ ] Security team briefed

REVIEW SIGN-OFF
---------------
IT Director: ______________ Date: ______
Security Lead: ______________ Date: ______
OT Manager (if OT involved): ______________ Date: ______
```

---

## Section 8: Testing Breakglass Procedures

### Quarterly Test Schedule

```
BREAKGLASS TEST SCHEDULE
========================

Q1 (January):
[ ] Verify breakglass account can login
[ ] Test MFA bypass procedure
[ ] Verify credential storage locations

Q2 (April):
[ ] Full breakglass drill (simulated)
[ ] Test credential rotation procedure
[ ] Verify dual authorization process

Q3 (July):
[ ] Verify breakglass account can login
[ ] Test local admin access
[ ] Review and update documentation

Q4 (October):
[ ] Full DR drill including breakglass
[ ] Test direct target access procedure
[ ] Annual credential rotation
```

---

<p align="center">
  <a href="./README.md">← Back to Runbooks</a>
</p>
