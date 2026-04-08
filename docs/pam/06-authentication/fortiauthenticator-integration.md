# FortiAuthenticator MFA Integration

## Configuring FortiAuthenticator as MFA Provider for WALLIX Bastion

This guide covers complete integration of FortiAuthenticator with WALLIX Bastion for multi-factor authentication.

---

## Table of Contents

1. [Integration Architecture](#integration-architecture)
2. [Prerequisites](#prerequisites)
3. [Step 1: Configure FortiAuthenticator](#step-1-configure-fortiauthenticator)
4. [Step 2: Configure WALLIX](#step-2-configure-wallix)
5. [Step 3: Test MFA Integration](#step-3-test-mfa-integration)
6. [Step 4: User Enrollment](#step-4-user-enrollment)
7. [Troubleshooting](#troubleshooting)
8. [MFA Bypass Procedures](#mfa-bypass-procedures)
9. [High Availability Configuration](#high-availability-configuration)
10. [Compliance Mapping](#compliance-mapping)
11. [Security Best Practices](#security-best-practices)
12. [Quick Reference](#quick-reference)

---

## Integration Architecture

```
+===============================================================================+
|                    FORTIAUTHENTICATOR MFA FLOW                                |
+===============================================================================+
|                                                                               |
|   User Browser         WALLIX Bastion          FortiAuthenticator             |
|   ============         ==============          ==================             |
|        |                     |                          |                     |
|   1.   |--- Credentials ---->|                          |                     |
|        |                     |--- RADIUS Access-Req --->|                     |
|        |                     |                          | 2. Validate user    |
|        |                     |                          |    Trigger Push/OTP |
|        |<-- MFA Challenge ---|<-- RADIUS Challenge -----|                     |
|        |                     |                          |                     |
|   3.   |--- OTP / Approve -->|                          |                     |
|        |                     |--- RADIUS Access-Req --->|                     |
|        |                     |<-- RADIUS Access-Acc ----|                     |
|        |<-- Session Start ---|                          |                     |
|        |                     |                          |                     |
|   MFA methods: FortiToken Mobile (push)  |  Hardware Token (OTP)            |
|                SMS OTP  |  Email OTP  |  TOTP (any authenticator app)        |
|                                                                               |
+===============================================================================+
```

---

## Prerequisites

### Pre-Implementation Checklist

Complete all items before starting the FortiAuthenticator MFA integration:

- [ ] FortiAuthenticator appliance deployed and accessible (VM or hardware)
- [ ] FortiAuthenticator firmware version 6.4 or later installed
- [ ] Valid FortiAuthenticator base license activated
- [ ] FortiToken licenses purchased for all users requiring MFA
- [ ] Active Directory operational and reachable from FortiAuthenticator
- [ ] AD service account created for FortiAuthenticator LDAP sync
- [ ] DNS resolution working between all components
- [ ] NTP time synchronization configured on all components
- [ ] Firewall rules configured for RADIUS and LDAPS traffic
- [ ] WALLIX Bastion deployed and operational (version 12.x recommended)
- [ ] SSL certificate installed on FortiAuthenticator web interface
- [ ] SMTP server configured for token enrollment emails

### FortiAuthenticator Requirements

#### Hardware / Virtual Appliance

| Item | Requirement |
|------|-------------|
| **Appliance Model** | FortiAuthenticator VM, 200F, 400F, or higher |
| **Firmware Version** | 6.4+ recommended (6.6+ for latest features) |
| **CPU** | 2+ vCPU (VM), dedicated (hardware) |
| **RAM** | 4 GB minimum, 8 GB recommended |
| **Disk** | 60 GB minimum for logs and user database |
| **Network** | Static IP address with DNS record |

#### Licensing

```
+=============================================================================+
|                  FORTIAUTHENTICATOR LICENSING                               |
+=============================================================================+
|                                                                             |
|  Required Licenses:                                                         |
|  ==================                                                         |
|                                                                             |
|  1. FortiAuthenticator Base License                                         |
|     - Included with appliance purchase                                      |
|     - Enables RADIUS, LDAP, user management                                 |
|                                                                             |
|  2. FortiToken Licenses (per user)                                          |
|     - FortiToken Mobile: software token (iOS/Android)                       |
|     - FortiToken Hardware: physical OTP key fob                             |
|     - Purchased in packs (5, 25, 100, 1000 users)                           |
|                                                                             |
|  3. FortiCare Support (recommended)                                         |
|     - Firmware updates and security patches                                 |
|     - Technical support access                                              |
|                                                                             |
|  Licensing Example (100 users):                                             |
|  =================================                                          |
|  FortiAuthenticator VM base      x1                                         |
|  FortiToken Mobile 100-pack      x1                                         |
|  FortiCare 24x7 1-year           x1                                         |
|                                                                             |
+=============================================================================+
```

> **Note:** FortiToken Mobile licenses are perpetual. Hardware tokens have a battery life of approximately 5 years.

#### Firmware Verification

```bash
# Verify FortiAuthenticator firmware version
# Via CLI (SSH to FortiAuthenticator):
get system status

# Expected output should show:
# Version: FortiAuthenticator-VM v6.6.1
# Serial-Number: FAC-VMTM22XXXXXX
# Firmware Signature: OK

# Via Web UI:
# Dashboard > System Information > Firmware Version
```

### Active Directory Requirements

FortiAuthenticator must sync users from Active Directory to assign FortiTokens.

#### AD Service Account

```
+=============================================================================+
|                  AD SERVICE ACCOUNT FOR FORTIAUTHENTICATOR                  |
+=============================================================================+
|                                                                             |
|  Account Name:    svc-fortiauth                                             |
|  Location:        OU=Service Accounts,DC=company,DC=com                     |
|  Password:        [Strong, 24+ characters, _REDACTED]                       |
|  Password Expiry: Never (service account)                                   |
|                                                                             |
|  Required Permissions:                                                      |
|  =====================                                                      |
|  - Read all user properties (userPrincipalName, mail, memberOf)             |
|  - Read group membership                                                    |
|  - Enumerate OU structure                                                   |
|  - No write permissions needed (read-only sync)                             |
|                                                                             |
|  Delegation (PowerShell):                                                   |
|  ========================                                                   |
|  Base DN:   DC=company,DC=com                                               |
|  Scope:     This object and all descendant objects                          |
|  Type:      Read all properties                                             |
|                                                                             |
+=============================================================================+
```

**Create the service account:**

```bash
# PowerShell on Domain Controller
New-ADUser -Name "svc-fortiauth" `
  -Path "OU=Service Accounts,DC=company,DC=com" `
  -UserPrincipalName "svc-fortiauth@company.com" `
  -AccountPassword (ConvertTo-SecureString "PASSWORD_REDACTED" -AsPlainText -Force) `
  -Enabled $true `
  -PasswordNeverExpires $true `
  -CannotChangePassword $true `
  -Description "FortiAuthenticator LDAP sync service account"
```

#### AD Groups for MFA Scope

Create AD groups to control which users require MFA:

```bash
# PowerShell on Domain Controller

# Group for all MFA-enrolled users
New-ADGroup -Name "PAM-MFA-Users" `
  -Path "OU=PAM,OU=Groups,DC=company,DC=com" `
  -GroupScope Global `
  -GroupCategory Security `
  -Description "Users enrolled in FortiToken MFA for WALLIX"

# Group for MFA-exempt users (break-glass, service accounts)
New-ADGroup -Name "PAM-MFA-Exempt" `
  -Path "OU=PAM,OU=Groups,DC=company,DC=com" `
  -GroupScope Global `
  -GroupCategory Security `
  -Description "Users exempt from MFA requirement"

# Add users to MFA group
Add-ADGroupMember -Identity "PAM-MFA-Users" `
  -Members "jadmin","joperator","jauditor"
```

#### AD Connectivity Test

```bash
# From FortiAuthenticator CLI, test LDAP connectivity:
diagnose debug application radiusd -1
diagnose debug enable

# From WALLIX Bastion, test AD reachability:
ldapsearch -x -H ldaps://dc.company.com:636 \
  -D "CN=svc-fortiauth,OU=Service Accounts,DC=company,DC=com" \
  -W \
  -b "DC=company,DC=com" \
  "(sAMAccountName=jadmin)" dn mail memberOf
```

### Network Requirements

#### Port Matrix

> **Note:** FortiAuthenticator is shared across all 5 sites (10.20.0.0/24 Authentication Services subnet). Replace `X` with the site number (1–5) for each site's Bastion node IPs.

| Source                              | Destination                      | Port | Protocol | Description                  |
|-------------------------------------|----------------------------------|------|----------|------------------------------|
| WALLIX Bastion Node 1 (10.10.X.11)  | FortiAuthenticator (10.20.0.60)  | 1812 | UDP      | RADIUS Authentication        |
| WALLIX Bastion Node 1 (10.10.X.11)  | FortiAuthenticator (10.20.0.60)  | 1813 | UDP      | RADIUS Accounting            |
| WALLIX Bastion Node 2 (10.10.X.12)  | FortiAuthenticator (10.20.0.60)  | 1812 | UDP      | RADIUS Authentication        |
| WALLIX Bastion Node 2 (10.10.X.12)  | FortiAuthenticator (10.20.0.60)  | 1813 | UDP      | RADIUS Accounting            |
| FortiAuthenticator (10.20.0.60)     | AD DC1 (10.20.0.10)              | 636  | TCP      | LDAPS (user sync, primary)   |
| FortiAuthenticator (10.20.0.60)     | AD DC2 (10.20.0.11)              | 636  | TCP      | LDAPS (user sync, failover)  |
| FortiAuthenticator (10.20.0.60)     | AD DC1 (10.20.0.10)              | 389  | TCP      | LDAP (fallback only)         |
| FortiAuthenticator (10.20.0.60)     | SMTP Server                      | 587  | TCP      | Token enrollment emails      |
| FortiAuthenticator (10.20.0.60)     | NTP (10.20.0.20 / 10.20.0.21)    | 123  | UDP      | Time sync (critical for OTP) |
| FortiAuthenticator (10.20.0.60)     | FortiGuard Servers               | 443  | TCP      | License validation, updates  |
| Administrators                      | FortiAuthenticator (10.20.0.60)  | 443  | TCP      | Web UI management            |
| Users (mobile devices)              | FortiGuard Push Servers          | 443  | TCP      | Push notifications           |

#### Network Architecture

```
+=============================================================================+
|              FORTIAUTHENTICATOR NETWORK PLACEMENT                           |
+=============================================================================+
|                                                                             |
|                          +------------------+                               |
|                          |   AD Domain      |                               |
|                          |   Controller     |                               |
|                          |  10.20.0.10      |                               |
|                          +--------+---------+                               |
|                                   |                                         |
|                              LDAPS (636)                                    |
|                                   |                                         |
|                       +-----------v----------+                              |
|                       |  FortiAuthenticator  |                              |
|                       |  10.20.0.60          |                              |
|                       |  fortiauth.company   |                              |
|                       |  .com                |                              |
|                       +-----------+----------+                              |
|                                   |                                         |
|                          RADIUS (1812/1813)                                 |
|                                   |                                         |
|                     +-------------+-------------+                           |
|                     |                           |                           |
|            +--------v--------+         +--------v--------+                  |
|            | WALLIX Bastion  |         | WALLIX Bastion  |                  |
|            | Node 1          |         | Node 2          |                  |
|            | 10.10.X.11      |         | 10.10.X.12      |                  |
|            +-----------------+         +-----------------+                  |
|                                                                             |
+=============================================================================+
```

#### Firewall Rules

```bash
# FortiGate firewall rules for FortiAuthenticator MFA

# Rule 1: WALLIX Bastion to FortiAuthenticator (RADIUS) - all 5 sites
# Source:      10.10.1.11, 10.10.1.12  (Site 1 Bastion nodes, repeat per site)
#              10.10.2.11, 10.10.2.12  (Site 2)
#              10.10.3.11...10.10.5.12 (Sites 3-5)
# Destination: 10.20.0.60              (FortiAuthenticator primary)
#              10.20.0.61              (FortiAuthenticator secondary)
# Port:        1812/UDP, 1813/UDP
# Action:      ACCEPT
# Log:         Enable

# Rule 2: FortiAuthenticator to AD (LDAPS)
# Source:      10.20.0.60              (FortiAuthenticator)
# Destination: 10.20.0.10, 10.20.0.11 (AD DC1 and DC2)
# Port:        636/TCP
# Action:      ACCEPT
# Log:         Enable

# Rule 3: FortiAuthenticator to SMTP (enrollment emails)
# Source:      10.20.0.60
# Destination: SMTP Server
# Port:        587/TCP
# Action:      ACCEPT

# Rule 4: FortiAuthenticator to FortiGuard (license + push)
# Source:      10.20.0.60
# Destination: Any (FortiGuard cloud IPs)
# Port:        443/TCP
# Action:      ACCEPT
```

#### Network Connectivity Validation

Run these tests **before** starting the integration:

```bash
# From WALLIX Bastion Node 1 - test RADIUS port to primary FortiAuth
nc -zvu 10.20.0.60 1812
# Expected: Connection to 10.20.0.60 1812 port [udp/radius] succeeded!

# From WALLIX Bastion Node 2 - test RADIUS port to primary FortiAuth
nc -zvu 10.20.0.60 1812

# From WALLIX Bastion Node 1 - test RADIUS port to secondary FortiAuth
nc -zvu 10.20.0.61 1812

# From FortiAuthenticator - test LDAPS to AD DC1
openssl s_client -connect 10.20.0.10:636 -showcerts </dev/null 2>/dev/null | head -5
# Expected: Shows AD certificate chain

# From FortiAuthenticator - test SMTP
nc -zv smtp.company.com 587
# Expected: Connection succeeded

# DNS resolution test (all components)
nslookup fortiauth.company.com
nslookup dc.company.com
nslookup wallix.company.com
```

### Time Synchronization (Critical)

OTP tokens are time-based (TOTP). Clock drift between FortiAuthenticator and FortiToken devices causes authentication failures.

```bash
# On FortiAuthenticator (CLI):
diagnose system ntp status
# Expected: synchronized, offset < 1 second

# On WALLIX Bastion:
chronyc tracking
# Expected: Leap status: Normal, System time offset < 0.001 seconds

# On AD Domain Controller:
w32tm /query /status
# Expected: Leap Indicator: 0 (no warning)
```

**NTP Configuration:**

```bash
# On WALLIX Bastion - ensure NTP is configured
cat /etc/chrony/chrony.conf
# Should include:
# server 10.20.0.20 iburst   (NTP1)
# server 10.20.0.21 iburst   (NTP2)

# On FortiAuthenticator (CLI):
config system ntp
  set ntpsync enable
  set type custom
  config ntpserver
    edit 1
      set server "10.20.0.20"
    next
    edit 2
      set server "10.20.0.21"
    next
  end
end
```

> **Warning:** A clock difference of more than 30 seconds between FortiAuthenticator and the TOTP token will cause OTP validation to fail. Always configure NTP on all components before enabling MFA.

### SMTP Configuration for Token Enrollment

FortiAuthenticator sends enrollment emails with activation codes and QR links.

```bash
# On FortiAuthenticator (CLI):
config system email-server
  set server "smtp.company.com"
  set port 587
  set security starttls
  set authenticate enable
  set username "fortiauth-noreply@company.com"
  set password PASSWORD_REDACTED
end

# Test email delivery:
diagnose test email send admin@company.com "MFA Test" "FortiAuth email test"
```

**Via Web UI:**

```
1. Navigate to: System > Messaging > SMTP Servers
2. Configure:
   Server:     smtp.company.com
   Port:       587
   Security:   STARTTLS
   Username:   fortiauth-noreply@company.com
   Password:   [SMTP password]
   From:       "FortiAuthenticator" <fortiauth-noreply@company.com>
3. Click "Test" to send test email
```

### SSL Certificate for FortiAuthenticator Web UI

```bash
# Import corporate CA-signed certificate (recommended over self-signed)
# On FortiAuthenticator (CLI):
config system certificate local
  edit "fortiauth-cert"
    # Upload via Web UI: System > Administration > Certificates
  next
end

# Via Web UI:
# 1. System > Certificates > Local Certificates
# 2. Import: certificate.crt + private.key + ca-chain.crt
# 3. System > Administration > System Access
# 4. Set HTTPS certificate: fortiauth-cert
```

### Prerequisites Summary

```
+=============================================================================+
|                  PREREQUISITES VALIDATION SUMMARY                           |
+=============================================================================+
|                                                                             |
|  Component              Check                          Status               |
|  =====================  =============================  ======               |
|                                                                             |
|  FortiAuthenticator     Firmware 6.4+                  [ ]                  |
|  FortiAuthenticator     Base license active            [ ]                  |
|  FortiAuthenticator     FortiToken licenses loaded     [ ]                  |
|  FortiAuthenticator     Static IP + DNS record         [ ]                  |
|  FortiAuthenticator     SSL certificate installed      [ ]                  |
|  FortiAuthenticator     SMTP configured and tested     [ ]                  |
|  FortiAuthenticator     NTP synchronized               [ ]                  |
|                                                                             |
|  Active Directory       DC reachable from FortiAuth    [ ]                  |
|  Active Directory       Service account created        [ ]                  |
|  Active Directory       LDAPS (636) connectivity OK    [ ]                  |
|  Active Directory       PAM-MFA-Users group created    [ ]                  |
|                                                                             |
|  WALLIX Bastion         Version 12.x operational       [ ]                  |
|  WALLIX Bastion         RADIUS port to FortiAuth open  [ ]                  |
|  WALLIX Bastion         NTP synchronized               [ ]                  |
|                                                                             |
|  Network                Firewall rules configured      [ ]                  |
|  Network                DNS resolution working         [ ]                  |
|  Network                All connectivity tests pass    [ ]                  |
|                                                                             |
|  All checks must be [ x ] before proceeding to Step 1                       |
|                                                                             |
+=============================================================================+
```

---

## Step 1: Configure FortiAuthenticator

### 1.1 Create RADIUS Client for WALLIX

**Via FortiAuthenticator Web UI:**

```
1. Login to FortiAuthenticator
   URL: https://fortiauth.company.com

2. Navigate to: Authentication > RADIUS Service > Clients

3. Click "Create New"

4. Configure RADIUS Client:
   Name:           WALLIX-Cluster
   Client IP/Name: 10.10.1.11
   Secret:         [Strong shared secret - save this!]
   Description:    WALLIX Primary Node

   Authentication:
   [x] Enable
   [ ] Authorize only (no auth)

   Profile:        Default

5. Click OK

6. Repeat for second node:
   Name:           WALLIX-Node2
   Client IP/Name: 10.10.1.12
   Secret:         [Same shared secret]
```

### 1.2 Configure Authentication Policy

```
1. Navigate to: Authentication > RADIUS Service > Policies

2. Create new policy:
   Name:           WALLIX-MFA-Policy

   Matching Rules:
   - RADIUS Client: WALLIX-Cluster, WALLIX-Node2

   Authentication:
   - First Factor:  LDAP (or Local)
   - Second Factor: FortiToken

   Options:
   [x] Allow Push Notification
   [x] Allow OTP
   [ ] Allow SMS (optional)

   Timeout: 60 seconds

3. Click OK
```

### 1.3 Sync Users from Active Directory

```
1. Navigate to: Authentication > User Management > Remote Users

2. Configure LDAP Remote User Sync:
   Name:           AD-WALLIX-Users
   Server:         10.20.0.10 (dc.company.com)
   Port:           636 (LDAPS)
   Base DN:        OU=Users,OU=WALLIX,DC=company,DC=com
   Bind DN:        CN=svc-fortiauth,OU=Service Accounts,DC=company,DC=com
   Bind Password:  [Service account password]

   User Filter:    (objectClass=user)
   Group Filter:   (objectClass=group)

   Sync Schedule:  Every 15 minutes

3. Click "Test" to verify connectivity

4. Click "Sync Now" for initial sync
```

### 1.4 Assign FortiTokens to Users

**For FortiToken Mobile:**

```
1. Navigate to: Authentication > User Management > Local Users
   (or Remote Users if synced from AD)

2. Select user (e.g., jadmin)

3. Click "Edit"

4. Token Assignment:
   Token Type:     FortiToken Mobile
   Delivery:       Email activation code

5. Click "Provision Token"

6. User receives email with activation instructions
```

**For Hardware Tokens:**

```
1. Navigate to: Authentication > FortiToken > Hardware Tokens

2. Import tokens (from CSV or manually)

3. Assign to user:
   - Select token serial number
   - Click "Assign"
   - Select user
```

---

## Step 2: Configure WALLIX

### 2.1 Configure RADIUS Authentication

**Via WALLIX Web UI:**

```
1. Login to WALLIX Admin
   URL: https://wallix.company.com/admin

2. Navigate to: Configuration > Authentication > External Auth

3. Click "Add RADIUS Server"

4. Configure Primary RADIUS Server:
   Name:               FortiAuth-Primary
   Server Address:     fortiauth.company.com
   Authentication Port: 1812
   Accounting Port:    1813
   Shared Secret:      [Same secret from FortiAuth]
   Timeout:            30 seconds
   Retries:            3

5. Click "Test Connection" - should return "Success"

6. Click "Save"
```

**Via CLI:**

```bash
# Add FortiAuthenticator as RADIUS server
wabadmin auth radius add \
    --name "FortiAuth-Primary" \
    --server "fortiauth.company.com" \
    --port 1812 \
    --secret "[shared-secret]" \
    --timeout 30 \
    --retries 3

# Test connection
wabadmin auth radius test "FortiAuth-Primary"
```

### 2.2 Configure MFA Policy

**Via Web UI:**

```
1. Navigate to: Configuration > Authentication > MFA Policy

2. Configure MFA Settings:

   MFA Provider:       RADIUS (FortiAuth-Primary)

   MFA Required For:
   [x] All users
   [ ] Admin users only
   [ ] Specific groups

   Enforcement:
   [x] Web UI login
   [x] SSH proxy login
   [x] RDP proxy login
   [x] API authentication

   Bypass Options:
   [ ] Allow bypass for internal IPs
   [ ] Allow bypass for specific users

   Timeout:           60 seconds (match FortiAuth policy)

3. Click "Save"
```

**Via CLI:**

```bash
# Enable MFA for all users
wabadmin auth mfa enable \
    --provider radius \
    --server "FortiAuth-Primary" \
    --scope all \
    --enforce web,ssh,rdp,api

# Verify configuration
wabadmin auth mfa status
```

### 2.2b Map AD Groups to WALLIX Profiles (RADIUS Attributes)

FortiAuthenticator returns RADIUS `Class` attributes that WALLIX uses to automatically assign user profiles — eliminating manual profile assignment after AD sync.

**Configure RADIUS Reply Attributes on FortiAuthenticator:**

```
1. Navigate to: Authentication > RADIUS Service > Policies > WALLIX-MFA-Policy

2. Under "RADIUS Attributes" > "Reply Attributes", add:

   Attribute: Class (25)
   Value:     PAM-Admin
   Condition: User is member of CN=PAM-Linux-Admins,OU=PAM,OU=Groups,DC=company,DC=com

   Attribute: Class (25)
   Value:     PAM-Operator
   Condition: User is member of CN=PAM-Operators,OU=PAM,OU=Groups,DC=company,DC=com

   Attribute: Class (25)
   Value:     PAM-Auditor
   Condition: User is member of CN=PAM-Auditors,OU=PAM,OU=Groups,DC=company,DC=com

3. Click OK
```

**Configure WALLIX to Map RADIUS Class Attribute to Profiles:**

```bash
# Map RADIUS Class attribute values to WALLIX user profiles
wabadmin auth radius profile-map \
    --attribute Class \
    --value "PAM-Admin" \
    --wallix-profile administrator

wabadmin auth radius profile-map \
    --attribute Class \
    --value "PAM-Operator" \
    --wallix-profile operator

wabadmin auth radius profile-map \
    --attribute Class \
    --value "PAM-Auditor" \
    --wallix-profile auditor

# Verify mappings are active
wabadmin auth radius profile-map --list
```

> **Note:** If FortiAuthenticator cannot return a `Class` attribute (user not in a mapped group), WALLIX falls back to the default profile configured in the RADIUS server settings. Always set a safe default (e.g., `user` profile with no target access).

**AD Group → WALLIX Profile Mapping Summary:**

| AD Group (CN) | RADIUS Class Value | WALLIX Profile |
|---------------|-------------------|----------------|
| PAM-Linux-Admins | PAM-Admin | administrator |
| PAM-Operators | PAM-Operator | operator |
| PAM-Auditors | PAM-Auditor | auditor |
| PAM-MFA-Exempt | _(no MFA required)_ | _(per local config)_ |

---

### 2.3 Configure Failover (Optional)

```bash
# Add secondary FortiAuthenticator for HA
wabadmin auth radius add \
    --name "FortiAuth-Secondary" \
    --server "fortiauth-dr.company.com" \
    --port 1812 \
    --secret "[shared-secret]" \
    --priority 2

# Configure failover
wabadmin auth radius failover \
    --primary "FortiAuth-Primary" \
    --secondary "FortiAuth-Secondary" \
    --failover-timeout 5
```

---

## Step 3: Test MFA Integration

### 3.1 Test from WALLIX

```bash
# Test RADIUS authentication
wabadmin auth test \
    --provider radius \
    --user "jadmin" \
    --password "[password]"

# Expected flow:
# 1. Password validated
# 2. FortiToken push sent to user's phone
# 3. User approves push
# 4. "Authentication successful" message
```

### 3.2 Test User Login

```
1. Open browser to https://wallix.company.com

2. Enter credentials:
   Username: jadmin
   Password: [AD password]

3. Click "Login"

4. MFA Challenge appears:
   "Waiting for FortiToken authentication..."

5. On FortiToken Mobile app:
   - Push notification received
   - Review login details
   - Tap "Approve"

6. Login completes, dashboard appears
```

### 3.3 Test SSH Proxy Login

```bash
# Connect via SSH
ssh jadmin@wallix.company.com

# Enter password when prompted
Password: [AD password]

# MFA prompt appears:
# "FortiToken verification required. Check your mobile app or enter OTP:"

# Either:
# - Approve push notification on phone, OR
# - Enter 6-digit OTP from FortiToken

# After MFA, target selection appears
```

---

## Step 4: User Enrollment

### 4.1 Self-Service Enrollment

Configure FortiAuthenticator for self-service:

```
1. FortiAuth > Authentication > Self-Service Portal

2. Enable Self-Service:
   [x] Enable self-service portal
   URL: https://fortiauth.company.com/self-service

3. Allowed Actions:
   [x] FortiToken Mobile enrollment
   [x] Password change
   [ ] Account recovery

4. Email user instructions:
```

**User Enrollment Email Template:**

```
Subject: Enable Multi-Factor Authentication for WALLIX

Dear [User],

Multi-factor authentication (MFA) is now required for WALLIX access.

ENROLLMENT STEPS:

1. Install FortiToken Mobile app:
   - iOS: App Store > Search "FortiToken Mobile"
   - Android: Play Store > Search "FortiToken Mobile"

2. Activate your token:
   - Open email on your mobile device
   - Click activation link (or scan QR code)
   - FortiToken app opens and registers automatically

3. Test your login:
   - Go to https://wallix.company.com
   - Enter username and password
   - Approve push notification on phone

NEED HELP?
Contact IT Support: support@company.com or ext. 1234

Thank you,
IT Security Team
```

### 4.2 Admin-Assisted Enrollment

```bash
# Generate enrollment token for user
# On FortiAuthenticator:
1. User Management > Users > [select user]
2. Token > Provision FortiToken Mobile
3. Send activation email

# On WALLIX, verify user can authenticate:
wabadmin auth test --user "[username]" --provider radius
```

---

## Troubleshooting

### Common Issues

#### "RADIUS server not responding"

```bash
# Check network connectivity
nc -zvu fortiauth.company.com 1812

# Check firewall rules
iptables -L -n | grep 1812

# Verify shared secret matches
# On WALLIX:
wabadmin auth radius show "FortiAuth-Primary"

# On FortiAuthenticator:
# Authentication > RADIUS Service > Clients > WALLIX-Cluster
```

#### "MFA timeout - no response"

```bash
# Check FortiAuthenticator logs
# FortiAuth > Monitor > Logs > Authentication

# Common causes:
# - User didn't receive push (check FortiToken app)
# - User's token not properly activated
# - Network latency (increase timeout)

# Increase timeout:
wabadmin auth mfa set-timeout 90
```

#### "Invalid OTP"

```bash
# Check time synchronization
# FortiAuthenticator and WALLIX must have synchronized time

# On WALLIX:
chronyc tracking

# On FortiAuthenticator:
# System > Administration > Time

# If tokens are out of sync:
# FortiAuth > Authentication > FortiToken > [token] > Resync
```

#### "User not found in RADIUS"

```bash
# Verify user exists in FortiAuthenticator
# FortiAuth > User Management > Remote Users > Search

# Force LDAP sync
# FortiAuth > Authentication > Remote User Sync > Sync Now

# Check LDAP filter in FortiAuth includes the user
```

### Debug Mode

```bash
# Enable RADIUS debug logging on WALLIX
wabadmin log level radius debug

# View real-time logs
tail -f /var/log/wabengine/radius.log

# Test with debug output
wabadmin auth test \
    --user "jadmin" \
    --provider radius \
    --debug

# Disable debug when done
wabadmin log level radius info
```

---

## MFA Bypass Procedures

### Temporary Bypass (Emergency)

```bash
# For emergencies when FortiAuthenticator is unavailable

# Option 1: Bypass for specific user (time-limited)
wabadmin auth mfa bypass \
    --user "jadmin" \
    --duration 1h \
    --reason "FortiAuth maintenance"

# Option 2: Use breakglass account (pre-configured without MFA)
# Account: breakglass-admin
# This should be heavily monitored

# Log all bypass events
wabadmin audit search --type mfa-bypass --last 24h
```

### Disable MFA (Maintenance Window)

```bash
# Schedule maintenance window
# NEVER do this without approval

# Temporarily disable MFA (replace dates with actual maintenance window)
wabadmin auth mfa disable \
    --scheduled-start "YYYY-MM-DDTHH:MM:SSZ" \
    --scheduled-end "YYYY-MM-DDTHH:MM:SSZ" \
    --reason "FortiAuthenticator upgrade"

# Notifications sent automatically to security team
```

---

## High Availability Configuration

### FortiAuthenticator HA

```
FortiAuth Primary:    fortiauth.company.com     (10.20.0.60)  VLAN 20
FortiAuth Secondary:  fortiauth-dr.company.com  (10.20.0.61)  VLAN 20
```

Both appliances are in the shared Authentication Services subnet (`10.20.0.0/24`), reachable from all 5 sites via MPLS.

### WALLIX RADIUS Failover

```bash
# Configure both FortiAuth servers (run on each WALLIX Bastion node)
wabadmin auth radius add \
    --name "FortiAuth-Primary" \
    --server "10.20.0.60" \
    --port 1812 \
    --secret "[secret]" \
    --priority 1

wabadmin auth radius add \
    --name "FortiAuth-Secondary" \
    --server "10.20.0.61" \
    --port 1812 \
    --secret "[secret]" \
    --priority 2

# Enable automatic failover
wabadmin auth radius failover enable \
    --check-interval 30 \
    --failback-delay 300
```

---

## Compliance Mapping

FortiToken MFA satisfies multi-factor authentication requirements across all frameworks applicable to this deployment.

| Framework | Control | Requirement | How FortiToken Satisfies It |
|-----------|---------|-------------|----------------------------|
| **ISO 27001** | A.9.4.2 | Secure log-on procedures | Dual-factor login enforced for all privileged sessions |
| **ISO 27001** | A.9.4.3 | Password management system | Token lifecycle managed; hardware tokens replaced every 5 years |
| **SOC 2 Type II** | CC6.1 | Logical access controls | MFA enforced for Web UI, SSH proxy, RDP proxy, and API |
| **SOC 2 Type II** | CC6.7 | Restricted access to system components | Possession factor (FortiToken) prevents credential-only attacks |
| **NIS2 Directive** | Art. 21(2)(j) | Multi-factor authentication | Strong authentication required for remote and privileged access |
| **PCI-DSS v4** | 8.4.2 | MFA for all non-console admin access | FortiToken Mobile/Hardware satisfies possession factor |
| **GDPR** | Art. 32 | Appropriate technical security measures | MFA is a recognized technical control for access security |

### Evidence Collection for Audits

```bash
# Export MFA authentication summary (last 90 days)
wabadmin report generate \
    --type mfa-audit \
    --from "$(date -d '90 days ago' +%Y-%m-%d)" \
    --to "$(date +%Y-%m-%d)" \
    --format pdf \
    --output /var/backup/audit/mfa-audit-$(date +%Y%m%d).pdf

# List all users with MFA enabled
wabadmin auth mfa user-list --status enabled

# List users without MFA (each requires documented exception)
wabadmin auth mfa user-list --status disabled

# Export RADIUS accounting log (authentication events with timestamps)
wabadmin audit export \
    --type radius-accounting \
    --last 90d \
    --output /var/backup/audit/radius-accounting-$(date +%Y%m%d).csv

# Count MFA authentications by method (for SOC 2 evidence)
wabadmin audit stats --type mfa --group-by method --last 30d
```

---

## Security Best Practices

### Token Security

```
1. Require PIN on FortiToken Mobile app
2. Enable biometric unlock (fingerprint/face)
3. Disable token backup to cloud
4. Revoke tokens immediately when user leaves
5. Regular token inventory audits
```

### RADIUS Security

```
1. Use strong shared secrets (32+ characters)
2. Enable RADIUS accounting for audit trail
3. Limit RADIUS clients to WALLIX IPs only
4. Use separate VLAN for RADIUS traffic
5. Monitor for RADIUS authentication failures
```

### Monitoring

```bash
# Alert: MFA failures spike (possible brute force or service issue)
wabadmin alert create \
    --name "MFA-Failure-Spike" \
    --condition "mfa_failures > 5 in 5m" \
    --action email \
    --recipient security@company.com

# Alert: RADIUS server unreachable (MFA unavailable)
wabadmin alert create \
    --name "RADIUS-Unreachable" \
    --condition "radius_server_status == down" \
    --action email,pagerduty \
    --recipient oncall@company.com

# Alert: MFA bypass used (always warrants investigation)
wabadmin alert create \
    --name "MFA-Bypass-Used" \
    --condition "mfa_bypass_count > 0 in 1h" \
    --action email \
    --recipient security@company.com

# Daily MFA summary report
wabadmin report schedule \
    --type mfa-summary \
    --frequency daily \
    --recipient security@company.com
```

**Key Prometheus Metrics to Monitor** (via `/metrics/12-monitoring-observability/`):

| Metric | Alert Threshold | Meaning |
|--------|----------------|---------|
| `wallix_mfa_failures_total` | > 10 in 5 min | Possible attack or FortiAuth outage |
| `wallix_radius_latency_ms` | > 3000 ms avg | FortiAuth performance degradation |
| `wallix_radius_server_up` | == 0 | FortiAuth unreachable — MFA unavailable |
| `wallix_mfa_bypass_total` | > 0 | Any bypass event requires audit review |
| `wallix_token_expired_count` | > 5% of users | Mass token expiry — proactive re-enrollment |

---

## Quick Reference

### FortiAuthenticator Reference

| Purpose              | Value                                       |
|----------------------|---------------------------------------------|
| Admin Console (Pri.) | https://fortiauth.company.com/admin         |
| Admin Console (Sec.) | https://fortiauth-dr.company.com/admin      |
| Self-Service Portal  | https://fortiauth.company.com/self-service  |
| Primary IP           | 10.20.0.60 (VLAN 20)                        |
| Secondary IP         | 10.20.0.61 (VLAN 20)                        |
| RADIUS Auth Port     | 1812/UDP                                    |
| RADIUS Acct Port     | 1813/UDP                                    |

### WALLIX MFA Commands

```bash
# Check MFA status
wabadmin auth mfa status

# Test MFA for user
wabadmin auth test --user USERNAME --provider radius

# Bypass MFA temporarily
wabadmin auth mfa bypass --user USERNAME --duration 1h

# View MFA audit logs
wabadmin audit search --type mfa --last 24h
```

---

<p align="center">
  <a href="./README.md">← Back to Authentication</a>
</p>
