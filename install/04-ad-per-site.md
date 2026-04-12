# Per-Site Active Directory Integration

> Configuration guide for the per-site Active Directory domain controller located in the Cyber VLAN, and its integration with WALLIX Bastion and FortiAuthenticator

---

## Document Information

| Property | Value |
|----------|-------|
| **Purpose** | Per-site AD integration with WALLIX Bastion and FortiAuthenticator |
| **Deployment Model** | 1 AD domain controller per site in Cyber VLAN |
| **Version** | WALLIX Bastion 12.1.x, FortiAuthenticator 6.4+ |
| **Prerequisites** | [01-network-design.md](01-network-design.md), [03-fortiauthenticator-ha.md](03-fortiauthenticator-ha.md) |
| **Last Updated** | April 2026 |

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [AD Domain Controller Requirements](#ad-domain-controller-requirements)
3. [Service Account Requirements](#service-account-requirements)
4. [DNS Configuration](#dns-configuration)
5. [WALLIX Bastion LDAP/AD Integration](#wallix-bastion-ldapad-integration)
6. [FortiAuthenticator LDAP Connection to AD](#fortiauthenticator-ldap-connection-to-ad)
7. [OU and Group Structure](#ou-and-group-structure)
8. [Verification and Testing](#verification-and-testing)
9. [Operational Procedures](#operational-procedures)

---

## Architecture Overview

Each site has its own AD domain controller in the **Cyber VLAN**. Both WALLIX Bastion (in the DMZ VLAN) and FortiAuthenticator (also in the Cyber VLAN) connect to this local AD.

```
+===============================================================================+
|  PER-SITE AD INTEGRATION ARCHITECTURE                                         |
+===============================================================================+
|                                                                               |
|  DMZ VLAN (10.10.X.0/25)                                                      |
|  +-----------------------------------------------------------------------+    |
|  |  +------------------+  +------------------+                           |    |
|  |  | WALLIX Bastion-1 |  | WALLIX Bastion-2 |                           |    |
|  |  | 10.10.X.11       |  | 10.10.X.12       |                           |    |
|  |  +--------+---------+  +--------+---------+                           |    |
|  +-----------|---------------------|--------------------------------------+    |
|              |                     |                                           |
|    LDAPS 636 | TCP (via Fortigate) |                                           |
|              +----------+----------+                                           |
|                         |                                                      |
|  Cyber VLAN (10.10.X.128/25)       |                                           |
|  +-----------------------------------------------------------------------+    |
|  |                       v                                               |    |
|  |  +-----------------------------------------------+                   |    |
|  |  |  Active Directory DC (10.10.X.60)             |                   |    |
|  |  |  Windows Server 2022                          |                   |    |
|  |  |  Roles: AD DS, DNS                            |                   |    |
|  |  +-----------------------------------------------+                   |    |
|  |            ^                          ^                               |    |
|  |  LDAP 389  |                          | LDAP 389 TCP                  |    |
|  |  TCP       |                          |                               |    |
|  |  +------------------+  +---------------------------+                  |    |
|  |  | FortiAuth-1      |  | FortiAuth-2               |                  |    |
|  |  | 10.10.X.50       |  | 10.10.X.51                |                  |    |
|  |  +------------------+  +---------------------------+                  |    |
|  +-----------------------------------------------------------------------+    |
|                                                                               |
|  Traffic Rules (via Fortigate):                                               |
|  Bastion (DMZ) -> AD (Cyber): LDAPS 636 TCP   ALLOWED                         |
|  Bastion (DMZ) -> AD (Cyber): LDAP 389 TCP    ALLOWED (fallback)              |
|  FortiAuth (Cyber) -> AD (Cyber): LDAP 389 TCP ALLOWED (same VLAN)            |
|                                                                               |
+===============================================================================+
```

### Connection Summary

| Source | Destination | Port | Protocol | Purpose |
|--------|-------------|------|----------|---------|
| Bastion-1/2 (DMZ) | AD DC (Cyber) | 636 | TCP/LDAPS | User/group lookup (preferred) |
| Bastion-1/2 (DMZ) | AD DC (Cyber) | 389 | TCP/LDAP | Fallback LDAP |
| Bastion-1/2 (DMZ) | AD DC (Cyber) | 3268 | TCP | Global Catalog |
| Bastion-1/2 (DMZ) | AD DC (Cyber) | 88 | TCP/UDP | Kerberos (optional) |
| FortiAuth-1/2 (Cyber) | AD DC (Cyber) | 389 | TCP/LDAP | User sync for MFA |
| FortiAuth-1/2 (Cyber) | AD DC (Cyber) | 636 | TCP/LDAPS | Secure user sync (recommended) |

---

## AD Domain Controller Requirements

### Hardware Specification

| Component | Specification | Notes |
|-----------|---------------|-------|
| **CPU** | 4 vCPU | 2 GHz+ |
| **RAM** | 8 GB | More for large user bases |
| **Disk** | 100 GB+ | OS + AD database |
| **Network** | 1x 1 GbE NIC | In Cyber VLAN |
| **OS** | Windows Server 2022 | Standard or Datacenter |
| **Roles** | AD DS, DNS Server | Required roles |

**Quantity**: 1 AD DC per site (standalone at each site)

**Total across 5 sites**: 5 AD domain controllers

> Note: Sites have independent AD domain controllers. All sites share the same AD forest and domain (`company.local`), with each site's DC being a domain controller for that domain. Replication between site DCs occurs over the MPLS backbone and is configured separately by the AD team.

### Windows Server Roles

```
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
Install-WindowsFeature -Name DNS -IncludeManagementTools

# Promote to DC (on first site DC - adjust for additional sites)
Install-ADDSDomainController `
  -DomainName "company.local" `
  -SiteName "SiteX" `
  -InstallDns `
  -Credential (Get-Credential) `
  -Force
```

---

## Service Account Requirements

### Accounts to Create in AD

| Account | Purpose | Permissions Required |
|---------|---------|---------------------|
| `svc_wallix_bastion` | WALLIX Bastion LDAP bind | Read-only: users, groups, OUs |
| `svc_fortiauth` | FortiAuthenticator LDAP bind | Read-only: users, groups, OUs |

### Create Service Accounts

```powershell
# Create service accounts in a dedicated OU
New-ADUser -Name "svc_wallix_bastion" `
           -SamAccountName "svc_wallix_bastion" `
           -UserPrincipalName "svc_wallix_bastion@company.local" `
           -Path "OU=Service Accounts,DC=company,DC=local" `
           -AccountPassword (ConvertTo-SecureString "<password>" -AsPlainText -Force) `
           -PasswordNeverExpires $true `
           -CannotChangePassword $true `
           -Enabled $true `
           -Description "WALLIX Bastion LDAP bind account - read only"

New-ADUser -Name "svc_fortiauth" `
           -SamAccountName "svc_fortiauth" `
           -UserPrincipalName "svc_fortiauth@company.local" `
           -Path "OU=Service Accounts,DC=company,DC=local" `
           -AccountPassword (ConvertTo-SecureString "<password>" -AsPlainText -Force) `
           -PasswordNeverExpires $true `
           -CannotChangePassword $true `
           -Enabled $true `
           -Description "FortiAuthenticator LDAP bind account - read only"
```

### Assign Minimum Permissions

Both accounts need read-only access to query user and group objects. No write permissions are required.

```powershell
# Delegate read access on the Privileged Users OU
$ou = "OU=Privileged Users,DC=company,DC=local"

# Grant "Read all properties" to svc_wallix_bastion
dsacls $ou /G "COMPANY\svc_wallix_bastion:GR;;"

# Grant "Read all properties" to svc_fortiauth
dsacls $ou /G "COMPANY\svc_fortiauth:GR;;"
```

### Password Policy for Service Accounts

| Setting | Value |
|---------|-------|
| Password expiry | Never (rotate manually every 12 months) |
| Minimum length | 20+ characters |
| Complexity | Uppercase, lowercase, digit, special char |
| Change on next logon | No |
| Storage | Secrets vault only (do not store in plaintext files) |

---

## DNS Configuration

### AD-Integrated DNS (Recommended)

The AD DC serves DNS for the Cyber VLAN. Configure Bastion and FortiAuth to use the local AD DC as their primary DNS server.

### Forward Lookup Zone: `company.local`

Verify the following records exist (AD creates them automatically on DC promotion):

```
# Site X AD/DNS records
dc-siteX.company.local      A    10.10.X.60
company.local               NS   dc-siteX.company.local

# Verify with nslookup from Bastion
nslookup company.local 10.10.X.60
nslookup dc-siteX.company.local 10.10.X.60
```

### DNS for FortiAuthenticator and Bastion

Configure the following DNS settings on each appliance:

| Appliance | Primary DNS | Secondary DNS |
|-----------|-------------|---------------|
| WALLIX Bastion-1/2 (Site X) | 10.10.X.60 (local AD) | Corporate DNS |
| FortiAuth-1/2 (Site X) | 10.10.X.60 (local AD) | Corporate DNS |

> Use the local site AD as primary DNS for fastest resolution. The corporate DNS is secondary for external names.

### Reverse Lookup Zone

Create PTR records for all Cyber VLAN components:

```powershell
# On AD DC (PowerShell)
Add-DnsServerResourceRecordPtr `
  -ZoneName "10.10.in-addr.arpa" `
  -Name "60" `
  -PtrDomainName "dc-siteX.company.local"
```

---

## WALLIX Bastion LDAP/AD Integration

Configure this on the primary WALLIX Bastion node. The configuration replicates to the secondary node automatically.

### Step 1: Configure LDAP Authentication

```bash
# On WALLIX Bastion (wabadmin)
wabadmin ldap configure \
  --name "AD-SiteX" \
  --server 10.10.X.60 \
  --port 636 \
  --use-ssl true \
  --base-dn "DC=company,DC=local" \
  --bind-dn "CN=svc_wallix_bastion,OU=Service Accounts,DC=company,DC=local" \
  --bind-password "<password>" \
  --user-class user \
  --user-attr sAMAccountName \
  --group-class group \
  --group-attr cn \
  --sync-interval 300
```

Alternatively, configure via the WALLIX Bastion Web UI:

```
Configuration > Authentication > LDAP > Add

Type: Active Directory
Display Name: AD-SiteX
Host: 10.10.X.60
Port: 636
SSL: Yes (verify certificate)
Base DN: DC=company,DC=local
Login attribute: sAMAccountName
Bind DN: CN=svc_wallix_bastion,OU=Service Accounts,DC=company,DC=local
Bind password: <password>
```

### Step 2: Map AD Groups to Bastion Profiles

```
Configuration > Authentication > LDAP > AD-SiteX > Group Mapping

AD Group: CN=PAM-Admins,OU=Groups,DC=company,DC=local
  -> Bastion Profile: administrator

AD Group: CN=PAM-Users,OU=Groups,DC=company,DC=local
  -> Bastion Profile: user

AD Group: CN=PAM-Readonly,OU=Groups,DC=company,DC=local
  -> Bastion Profile: auditor
```

### Step 3: Configure LDAP Synchronization

```bash
# Force sync to verify connectivity
wabadmin ldap sync --name "AD-SiteX"

# Expected output:
# Sync started: AD-SiteX
# Users found: 25
# Groups found: 3
# Sync completed: 25 users imported
```

### Step 4: Verify in Web UI

```
Reports > Authentication > LDAP sync history

Last sync: <timestamp>
Status: Success
Users: 25
Groups: 3
```

---

## FortiAuthenticator LDAP Connection to AD

Configure on FortiAuthenticator-1 (Primary). The HA sync replicates this to FortiAuthenticator-2.

### Step 1: Create LDAP Server Entry

```
Authentication > Remote Auth. Servers > LDAP > Create New

Name: AD-SiteX
Primary Server Name/IP: 10.10.X.60
Port: 389 (or 636 for LDAPS)
Secure Connection: LDAPS (recommended)
Certificate: Import AD DC certificate or trust root CA

Distinguished Name: DC=company,DC=local
Bind Type: Regular
Username: svc_fortiauth@company.local
Password: <password>

User Object Class: user
Username Attribute: sAMAccountName
Member Of Attribute: memberOf
Email Attribute: mail
```

Test the connection before saving.

### Step 2: User Import Configuration

```
Authentication > User Management > Import Remote Users

Source: AD-SiteX
Search Base: OU=Privileged Users,DC=company,DC=local
Search Filter: (&(objectClass=user)(memberOf=CN=PAM-Users,OU=Groups,DC=company,DC=local))
Keep Synchronized: Yes
Sync Interval: 5 minutes
```

### Step 3: FortiAuthenticator User Authentication Flow

```
+===============================================================================+
|  FORTIAUTHENTICATOR AUTHENTICATION FLOW                                       |
+===============================================================================+
|                                                                               |
|  1. WALLIX Bastion receives user login (username + password + OTP)            |
|                                                                               |
|  2. Bastion sends RADIUS Access-Request to FortiAuth-1 (10.10.X.50)          |
|                                                                               |
|  3. FortiAuth validates credentials against AD (LDAP bind as user):           |
|     - Checks username/password via AD-SiteX (10.10.X.60)                     |
|     - Verifies OTP against FortiToken Mobile                                  |
|                                                                               |
|  4. If valid: FortiAuth returns RADIUS Access-Accept to Bastion               |
|     If invalid: FortiAuth returns RADIUS Access-Reject to Bastion             |
|                                                                               |
|  5. Bastion grants or denies the session based on RADIUS response             |
|                                                                               |
+===============================================================================+
```

---

## OU and Group Structure

Recommended OU structure in AD for PAM users at each site:

```
DC=company,DC=local
|
+-- OU=Sites
|   +-- OU=SiteX
|       +-- OU=Privileged Users       (all PAM users for this site)
|       +-- OU=Service Accounts       (svc_wallix_bastion, svc_fortiauth)
|
+-- OU=Groups
    +-- CN=PAM-Admins                 (full Bastion admin access)
    +-- CN=PAM-Users                  (standard privileged access)
    +-- CN=PAM-Readonly               (auditor/read-only access)
    +-- CN=PAM-SiteX-Approvers        (JIT access approvers for Site X)
```

### Required Groups

| Group | Members | Bastion Role |
|-------|---------|--------------|
| `PAM-Admins` | Site IT admins | Bastion Administrator |
| `PAM-Users` | Privileged operators | Bastion User |
| `PAM-Readonly` | Auditors, management | Bastion Auditor |
| `PAM-SiteX-Approvers` | Team leads | JIT Access Approver |

---

## Verification and Testing

### Test 1: LDAP Connectivity from Bastion

```bash
# From Bastion-1
ldapsearch -H ldaps://10.10.X.60:636 \
  -D "CN=svc_wallix_bastion,OU=Service Accounts,DC=company,DC=local" \
  -w "<password>" \
  -b "DC=company,DC=local" \
  "(sAMAccountName=testuser)"

# Expected: Returns user object with attributes
```

### Test 2: LDAP Connectivity from FortiAuth

```
Authentication > Remote Auth. Servers > LDAP > AD-SiteX > Test Connectivity

Input username: testuser
Expected result: Connection Successful, user found
```

### Test 3: End-to-End Authentication

```bash
# From Bastion (after full configuration)
wabadmin auth test --user testuser@company.local

# Expected:
# LDAP lookup: OK (user found in AD)
# RADIUS (FortiAuth): OK (Access-Accept received)
# Login result: GRANTED
```

### Test 4: Group Membership Sync

```bash
# Add user to PAM-Admins in AD, then verify Bastion picks it up
wabadmin ldap sync --name "AD-SiteX"
wabadmin user list | grep testuser

# Expected: testuser listed with administrator profile
```

---

## Operational Procedures

### LDAP Sync Troubleshooting

```bash
# Check LDAP sync status
wabadmin ldap status --name "AD-SiteX"

# Force manual sync
wabadmin ldap sync --name "AD-SiteX" --verbose

# Common issues:
# - Certificate error: Import AD DC SSL cert into Bastion trust store
# - Bind failure: Verify svc_wallix_bastion password and account status
# - No users found: Check base-dn and user-filter settings
```

### AD Account Lockout

If `svc_wallix_bastion` or `svc_fortiauth` becomes locked:

```powershell
# On AD DC
Unlock-ADAccount -Identity svc_wallix_bastion
Unlock-ADAccount -Identity svc_fortiauth
```

Then check for the cause (bad password configured on Bastion or FortiAuth) before unblocking.

### Service Account Password Rotation

When rotating service account passwords:

1. Update password in AD.
2. Update LDAP bind password in WALLIX Bastion (`Configuration > Authentication > LDAP > AD-SiteX`).
3. Update LDAP bind password in FortiAuthenticator (`Authentication > Remote Auth. Servers > LDAP > AD-SiteX`).
4. Verify sync resumes successfully.
5. Update password in the secrets vault.
6. Document rotation in the change log.

---

## Cross-References

| Topic | Document |
|-------|----------|
| FortiAuthenticator HA pair setup | [03-fortiauthenticator-ha.md](03-fortiauthenticator-ha.md) |
| Network design and VLAN layout | [01-network-design.md](01-network-design.md) |
| Full site deployment order | [05-site-deployment.md](05-site-deployment.md) |
| Bastion Active-Active cluster | [07-bastion-active-active.md](07-bastion-active-active.md) |
| Bastion Active-Passive cluster | [08-bastion-active-passive.md](08-bastion-active-passive.md) |
| AD failure scenario | [13-contingency-plan.md](13-contingency-plan.md) |
| Break glass when AD is unreachable | [14-break-glass-procedures.md](14-break-glass-procedures.md) |
