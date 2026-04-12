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
10. [User Offboarding — Token Deprovisioning](#user-offboarding--token-deprovisioning)
11. [FortiAuthenticator Backup and Recovery](#fortiauthenticator-backup-and-recovery)
12. [Compliance Mapping](#compliance-mapping)
13. [Security Best Practices](#security-best-practices)
14. [Quick Reference](#quick-reference)

---

## Integration Architecture

> **Deployment scope:** FortiAuthenticator is deployed as a **per-site HA pair**
> in the Cyber VLAN. It is NOT a shared or centralized service. This guide
> applies to each site independently. Repeat the configuration for each of the
> 5 sites, pointing to the local site's FortiAuthenticator pair.
>
> RADIUS traffic (1812/UDP) from Bastion (DMZ VLAN) to FortiAuthenticator
> (Cyber VLAN) crosses the Fortigate inter-VLAN boundary. MFA method is
> TOTP only via FortiToken Mobile — no push notification.

```
+===============================================================================+
|            FORTIAUTHENTICATOR MFA FLOW (LDAP + RADIUS) — PER SITE            |
+===============================================================================+
|                                                                               |
|  DMZ VLAN                                    Cyber VLAN (same site)           |
|  --------                                    ----------------------------      |
|                                                                               |
|  PHASE 1 -- Primary Authentication (WALLIX validates credentials via LDAP)    |
|  -----------------------------------------------------------------------      |
|                                                                               |
|   User Browser         WALLIX Bastion           Active Directory (per-site)   |
|   ============         ==============           ==========================     |
|        |                     |                          |                     |
|   1.   |--- Credentials ---->|                          |                     |
|        |                     |--- LDAPS (636/TCP) ----->|                     |
|        |                     |     via Fortigate        | Validate password   |
|        |                     |<-- LDAP success ---------|                     |
|        |                     |                          |                     |
|  PHASE 2 -- Second Factor (WALLIX calls FortiAuthenticator via RADIUS)        |
|  -----------------------------------------------------------------------      |
|                                                                               |
|   User Browser         WALLIX Bastion          FortiAuthenticator (per-site)  |
|   ============         ==============          ============================   |
|        |                     |                          |                     |
|        |                     |--- RADIUS (1812/UDP) --->|                     |
|        |                     |     via Fortigate        | 2. Validate TOTP   |
|        |<-- "Enter OTP" -----|<-- RADIUS Challenge -----|                     |
|        |                     |                          |                     |
|   3.   |--- TOTP code ------>|                          |                     |
|        |                     |--- RADIUS Access-Req --->|                     |
|        |                     |<-- RADIUS Access-Acc ----|                     |
|        |<-- Session Start ---|                          |                     |
|        |                     |                          |                     |
+===============================================================================+
```

### Connection Summary

FortiAuthenticator maintains two distinct connections for two separate purposes:

Each connection crosses the Fortigate inter-VLAN boundary (DMZ VLAN to Cyber
VLAN within the same site). This configuration applies per-site independently.

| Connection | Direction | Protocol | Port | When | Purpose |
|-----------|-----------|----------|------|------|---------|
| Bastion (DMZ) → FortiAuth (Cyber VLAN) | Bastion initiates | RADIUS | 1812/UDP | Every login | Verify TOTP second factor |
| FortiAuth (Cyber VLAN) → AD DC (Cyber VLAN) | FortiAuth initiates | LDAPS | 636/TCP | Every 15 min | Sync user list for token assignment |
| Bastion (DMZ) → AD DC (Cyber VLAN) | Bastion initiates | LDAPS | 636/TCP | Every login | Validate AD password (Phase 1) |

**Why FortiAuth needs AD connectivity:**
FortiAuth must know which users exist in order to assign FortiTokens to them. It syncs the user list from AD periodically (every 15 minutes). Without this sync, every user would need to be created manually in FortiAuth — impractical at scale across 5 sites.

**What FortiAuth does NOT do:**
FortiAuth does **not** validate passwords. WALLIX performs password validation directly against AD in Phase 1 before RADIUS is ever called. FortiAuth only receives the username in the RADIUS request and uses it solely to look up the assigned token and return a TOTP challenge.

> **FortiAuthenticator RADIUS policy** must set First Factor to **None**. Setting it to LDAP would cause double password validation (WALLIX already validated it) and will break authentication in this deployment.

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
| **Appliance** | FortiAuthenticator 6.4+ (hardware or VM — model not specified) |
| **Firmware Version** | 6.4+ required (6.6+ recommended for latest features) |
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

> **Per-site configuration.** Each site has its own FortiAuthenticator HA pair
> in the Cyber VLAN. The table below uses `10.X.Y.Z` notation where `X`
> represents the site number. Replicate this configuration for each site.
> RADIUS traffic crosses the Fortigate inter-VLAN boundary (DMZ to Cyber VLAN).
> Access Manager nodes (client-managed) also register as RADIUS clients.

| Source | Destination | Port | Protocol | Description |
|--------|-------------|------|----------|-------------|
| Bastion Node 1 (DMZ VLAN, site N) | FortiAuth Primary (Cyber VLAN, site N) | 1812 | UDP | RADIUS Auth |
| Bastion Node 2 (DMZ VLAN, site N) | FortiAuth Primary (Cyber VLAN, site N) | 1812 | UDP | RADIUS Auth |
| Bastion Node 1 (DMZ VLAN, site N) | FortiAuth Secondary (Cyber VLAN, site N) | 1812 | UDP | RADIUS Auth (failover) |
| Bastion Node 2 (DMZ VLAN, site N) | FortiAuth Secondary (Cyber VLAN, site N) | 1812 | UDP | RADIUS Auth (failover) |
| Bastion nodes (both) | FortiAuth Primary/Secondary | 1813 | UDP | RADIUS Accounting |
| Access Manager 1 (10.100.1.10) | FortiAuth (all sites) | 1812 | UDP | RADIUS Auth (AM MFA, client-managed AM) |
| Access Manager 2 (10.100.2.10) | FortiAuth (all sites) | 1812 | UDP | RADIUS Auth (AM MFA, client-managed AM) |
| FortiAuth Primary (Cyber VLAN) | AD DC (Cyber VLAN, same site) | 636 | TCP | LDAPS user sync (every 15 min) |
| FortiAuth Primary | FortiAuth Secondary | 8009 | TCP | HA sync (config + token replication) |
| FortiAuth Primary | SMTP Server | 587 | TCP | Token enrollment emails |
| FortiAuth Primary | NTP servers | 123 | UDP | Time sync (critical for TOTP) |
| FortiAuth Primary | FortiGuard Servers | 443 | TCP | License validation, updates |
| Administrators | FortiAuth Primary | 443 | TCP | Web UI management |

#### Network Architecture

Per-site layout — DMZ VLAN and Cyber VLAN separated by Fortigate:

```
+=============================================================================+
|          FORTIAUTHENTICATOR NETWORK PLACEMENT (PER SITE)                    |
+=============================================================================+
|                                                                             |
|  DMZ VLAN                            Cyber VLAN (same site)                |
|  --------                            ----------------------------           |
|                                                                             |
|  +------------------+  +------------------+                                |
|  | WALLIX Bastion   |  | WALLIX Bastion   |                                |
|  | Node 1 (DMZ)     |  | Node 2 (DMZ)     |                                |
|  +--------+---------+  +--------+---------+                                |
|           |                     |                                          |
|           +----------+----------+                                          |
|                      |                                                     |
|                 RADIUS 1812/UDP                                             |
|                 (via Fortigate                                              |
|                  inter-VLAN)                                               |
|                      |                                                     |
|     +----------------+-------------------+                                 |
|     v                                    v                                 |
|  +---------------------+  +---------------------+                          |
|  | FortiAuthenticator  |  | FortiAuthenticator  |                          |
|  | Primary (6.4+)      |  | Secondary (6.4+)    |                          |
|  | Cyber VLAN          |  | Cyber VLAN          |                          |
|  +---------+-----------+  +----------+----------+                          |
|            |                         |                                     |
|            +----------HA Sync--------+                                     |
|            |  (8009/TCP)                                                   |
|            |                                                               |
|       LDAPS 636/TCP                                                        |
|            |                                                               |
|  +---------v----------+                                                    |
|  |  AD Domain         |                                                    |
|  |  Controller        |                                                    |
|  |  (per-site,        |                                                    |
|  |   Cyber VLAN)      |                                                    |
|  +--------------------+                                                    |
|                                                                             |
+=============================================================================+
```

#### Firewall Rules

```bash
# FortiGate firewall rules for FortiAuthenticator MFA

# Rule 1: WALLIX Bastion nodes to FortiAuthenticator (RADIUS) - all 5 sites
# Source:      10.10.1.11, 10.10.1.12  (Site 1)
#              10.10.2.11, 10.10.2.12  (Site 2)
#              10.10.3.11, 10.10.3.12  (Site 3)
#              10.10.4.11, 10.10.4.12  (Site 4)
#              10.10.5.11, 10.10.5.12  (Site 5)
# Destination: 10.20.0.60              (FortiAuthenticator primary)
#              10.20.0.61              (FortiAuthenticator secondary)
# Port:        1812/UDP, 1813/UDP
# Action:      ACCEPT
# Log:         Enable

# Rule 1b: Access Manager nodes to FortiAuthenticator (RADIUS)
# Source:      10.100.1.10             (Access Manager 1, DC-A)
#              10.100.2.10             (Access Manager 2, DC-B)
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

4. Create one RADIUS client per node using the table below.
   Use the SAME shared secret for all clients.

   +------------------+---------------+-----------------------------------+
   | Name             | Client IP     | Description                       |
   +------------------+---------------+-----------------------------------+
   | WALLIX-Site1-N1  | 10.10.1.11    | Site 1 Bastion Node 1             |
   | WALLIX-Site1-N2  | 10.10.1.12    | Site 1 Bastion Node 2             |
   | WALLIX-Site2-N1  | 10.10.2.11    | Site 2 Bastion Node 1             |
   | WALLIX-Site2-N2  | 10.10.2.12    | Site 2 Bastion Node 2             |
   | WALLIX-Site3-N1  | 10.10.3.11    | Site 3 Bastion Node 1             |
   | WALLIX-Site3-N2  | 10.10.3.12    | Site 3 Bastion Node 2             |
   | WALLIX-Site4-N1  | 10.10.4.11    | Site 4 Bastion Node 1             |
   | WALLIX-Site4-N2  | 10.10.4.12    | Site 4 Bastion Node 2             |
   | WALLIX-Site5-N1  | 10.10.5.11    | Site 5 Bastion Node 1             |
   | WALLIX-Site5-N2  | 10.10.5.12    | Site 5 Bastion Node 2             |
   | AccessManager-1  | 10.100.1.10   | Access Manager 1 (DC-A)           |
   | AccessManager-2  | 10.100.2.10   | Access Manager 2 (DC-B)           |
   +------------------+---------------+-----------------------------------+

   For each entry:
   Secret:         [Strong shared secret, 32+ characters]
   Authentication: [x] Enable
   Profile:        Default

5. Click OK after each entry.

> **Warning:** Any Bastion node or Access Manager node NOT registered here will
> receive RADIUS reject responses. MFA will silently fail for users on that site.
```

### 1.2 Configure Authentication Policy

```
1. Navigate to: Authentication > RADIUS Service > Policies

2. Create new policy:
   Name:           WALLIX-MFA-Policy

   Matching Rules:
   - RADIUS Client: WALLIX-Site1-N1, WALLIX-Site1-N2,
                    WALLIX-Site2-N1, WALLIX-Site2-N2,
                    WALLIX-Site3-N1, WALLIX-Site3-N2,
                    WALLIX-Site4-N1, WALLIX-Site4-N2,
                    WALLIX-Site5-N1, WALLIX-Site5-N2,
                    AccessManager-1, AccessManager-2

   Authentication:
   - First Factor:  None (WALLIX already validated via LDAP — do NOT set LDAP here)
   - Second Factor: FortiToken

   Options:
   [ ] Allow Push Notification  (NOT used in this deployment)
   [x] Allow OTP               (TOTP via FortiToken Mobile — required)
   [ ] Allow SMS               (NOT used in this deployment)

   Timeout: 60 seconds

3. Click OK
```

### 1.3 Sync Users from Active Directory

```
1. Navigate to: Authentication > User Management > Remote Users

2. Configure Primary LDAP Remote User Sync:
   Name:           AD-WALLIX-Users
   Server:         10.20.0.10 (dc.company.com)
   Port:           636 (LDAPS)
   Base DN:        OU=Users,OU=WALLIX,DC=company,DC=com
   Bind DN:        CN=svc-fortiauth,OU=Service Accounts,DC=company,DC=com
   Bind Password:  [Service account password]

   User Filter:    (&(objectClass=user)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))
   Group Filter:   (objectClass=group)

   Sync Schedule:  Every 15 minutes

   > The user filter excludes disabled AD accounts, preventing license waste
   > and ensuring deprovisioned users cannot authenticate.

3. Configure Failover LDAP source (DC2):
   Name:           AD-WALLIX-Users-Failover
   Server:         10.20.0.11 (dc2.company.com)
   Port:           636 (LDAPS)
   (same Bind DN, Base DN, and Filter as above)
   Role:           Failover (secondary)

4. Click "Test" on both entries to verify connectivity

5. Click "Sync Now" for initial sync on primary
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

### 2.3 Configure Failover

```bash
# Add secondary FortiAuthenticator (use IP, not hostname — DNS must not be a dependency in failover path)
wabadmin auth radius add \
    --name "FortiAuth-Secondary" \
    --server "10.20.0.61" \
    --port 1812 \
    --secret "[shared-secret]" \
    --priority 2

# Configure failover
# --failover-timeout: seconds to wait for primary before switching
# 10s is safe — 5s can cause false failovers under FortiAuth load
wabadmin auth radius failover \
    --primary "FortiAuth-Primary" \
    --secondary "FortiAuth-Secondary" \
    --failover-timeout 10 \
    --failback-delay 300
```

> **Note:** Run this on **every** WALLIX Bastion node (10 total). The secondary FortiAuth at `10.20.0.61` must also have all 12 RADIUS clients and the WALLIX-MFA-Policy configured — user/token data syncs automatically between appliances if FortiAuth HA is enabled (see [High Availability Configuration](#high-availability-configuration)).

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
   - TOTP code received
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
# - Approve TOTP code on phone, OR
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
   - Approve TOTP code on phone

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

### FortiAuthenticator Appliance Sync (Primary ↔ Secondary)

The two FortiAuth appliances must replicate user data, token assignments, and configuration. Without this, the secondary has no users and will reject all authentication.

```bash
# On FortiAuth PRIMARY (10.20.0.60) — configure HA sync:
config system ha
  set mode active-passive
  set password [HA-sync-password]
  set peer-ip 10.20.0.61
  set peer-port 8009
  set sync-enable enable
  set sync-interval 60
end

# On FortiAuth SECONDARY (10.20.0.61) — configure HA sync:
config system ha
  set mode active-passive
  set password [HA-sync-password]
  set peer-ip 10.20.0.60
  set peer-port 8009
  set sync-enable enable
  set sync-interval 60
end
```

**Via Web UI (both appliances):**

```
1. System > Administration > High Availability
2. Mode:          Active-Passive
3. HA Password:   [same on both appliances]
4. Peer IP:       10.20.0.61 (on primary) / 10.20.0.60 (on secondary)
5. Sync Objects:  [x] Users and tokens
                  [x] RADIUS clients and policies
                  [x] LDAP server configuration
6. Click "Apply"
```

**Verify sync is working:**

```bash
# On FortiAuth primary (CLI):
diagnose ha status
# Expected: Peer Status: Connected, Last Sync: <timestamp within 5 minutes>

# Check token count matches on both appliances:
# FortiAuth Primary  > Authentication > FortiToken > Summary
# FortiAuth Secondary > Authentication > FortiToken > Summary
# Token counts must match. Mismatch = sync broken.
```

> **Critical:** If HA sync is not configured, the secondary FortiAuth will have no users or tokens. RADIUS failover will succeed at the network level but fail at the authentication level — users will get "authentication failed" during a FortiAuth outage. Verify sync before go-live.

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

## User Offboarding — Token Deprovisioning

When a user leaves the organization, complete these steps **in order** to prevent unauthorized access and reclaim the FortiToken license.

### Offboarding Checklist

```
[ ] 1. Disable the user in Active Directory (blocks LDAP auth)
[ ] 2. Revoke FortiToken in FortiAuthenticator (blocks MFA factor)
[ ] 3. Disable or delete the user in WALLIX Bastion
[ ] 4. Verify the user cannot authenticate (test with wabadmin)
[ ] 5. Document in the access removal ticket
```

### Step-by-Step

**Step 1 — Revoke token on FortiAuthenticator:**

```
1. Login to FortiAuthenticator > Authentication > User Management > Remote Users
2. Search for the user
3. Click Edit > Token Assignment > Revoke Token
4. Confirm — the FortiToken license is released back to the pool
```

```bash
# Or via FortiAuth CLI:
# (Navigate to the user entry and remove token assignment)
diagnose fortitoken revoke [serial-number]
```

**Step 2 — Disable user in WALLIX:**

```bash
# Disable the user account
wabadmin user disable --login "[username]"

# Verify the user can no longer authenticate
wabadmin auth test --user "[username]" --provider radius
# Expected: "Authentication failed - user disabled"

# Audit: confirm last session was closed
wabadmin audit search --user "[username]" --last 7d
```

**Step 3 — Verify AD account is disabled (triggers automatic FortiAuth sync within 15 min):**

```bash
# From any domain-joined host:
Get-ADUser "[username]" -Properties Enabled | Select Enabled
# Expected: Enabled: False
```

> **License impact:** FortiToken Mobile licenses are consumed per token provisioned, not per active user. Always revoke the token (Step 1) — disabling the AD account alone does **not** free the license.

---

## FortiAuthenticator Backup and Recovery

FortiAuthenticator holds all token-to-user mappings and RADIUS policies. Loss of this data requires re-enrolling all users.

### Scheduled Backup

```bash
# On FortiAuthenticator (CLI) — configure automated backup to SFTP:
config system backup
  set status enable
  set protocol sftp
  set server "10.20.0.50"
  set username "backup-user"
  set directory "/backups/fortiauth"
  set hour 2
  set minute 0
  set max-backup 14
end

# Trigger immediate backup:
execute backup config sftp 10.20.0.50 /backups/fortiauth [password]
```

**Via Web UI:**

```
1. System > Maintenance > Backup & Restore
2. Backup Type:   Configuration + User data + Token assignments
3. Schedule:      Daily at 02:00
4. Destination:   SFTP (10.20.0.50)
5. Retention:     14 days
6. Click "Save"
```

### Verify Backup

```bash
# Confirm backup file arrived on SFTP server:
ls -lh /backups/fortiauth/
# Expected: FAC_*.bak files updated within last 24 hours

# Test restore to secondary (before go-live only):
# FortiAuth Secondary > System > Maintenance > Backup & Restore > Restore
# Select the backup file, confirm restore, verify user count matches primary
```

> **RPO target:** Daily backup = up to 24 hours of data loss if primary fails catastrophically. If RTO/RPO requirements are stricter, rely on HA sync (near-real-time) and keep backups as cold fallback.

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
