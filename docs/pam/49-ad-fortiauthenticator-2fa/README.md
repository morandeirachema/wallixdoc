# 49 - Active Directory + FortiAuthenticator 300F: Complete 2FA Integration

## Production Deployment Guide for WALLIX Bastion

This guide provides end-to-end, production-ready procedures to integrate WALLIX Bastion with Active Directory for identity management and FortiAuthenticator 300F for two-factor authentication (2FA). Every step is ordered by component (AD first, FortiAuthenticator second, WALLIX third) and validated with testable checkpoints.

**Scope:** Single-domain Active Directory, FortiAuthenticator 300F (hardware appliance) with FortiToken Mobile, WALLIX Bastion 12.x, 5-site multi-datacenter deployment.

---

## Table of Contents

1. [Solution Architecture](#1-solution-architecture)
2. [Authentication Flow — How It Works](#2-authentication-flow--how-it-works)
3. [Prerequisites and Planning](#3-prerequisites-and-planning)
4. [Phase 1: Active Directory Preparation](#4-phase-1-active-directory-preparation)
5. [Phase 2: FortiAuthenticator 300F Configuration](#5-phase-2-fortiauthenticator-300f-configuration)
6. [Phase 3: WALLIX Bastion Configuration](#6-phase-3-wallix-bastion-configuration)
7. [Phase 4: End-to-End Testing](#7-phase-4-end-to-end-testing)
8. [Phase 5: User Enrollment at Scale](#8-phase-5-user-enrollment-at-scale)
9. [High Availability](#9-high-availability)
10. [Operational Procedures](#10-operational-procedures)
11. [Security Hardening](#11-security-hardening)
12. [Monitoring and Alerting](#12-monitoring-and-alerting)
13. [Troubleshooting](#13-troubleshooting)
14. [Compliance Mapping](#14-compliance-mapping)
15. [Go-Live Checklist](#15-go-live-checklist)
16. [Quick Reference Card](#16-quick-reference-card)

---

## 1. Solution Architecture

### 1.1 Component Roles

| Component | Role | What It Does | What It Does NOT Do |
|-----------|------|--------------|---------------------|
| **Active Directory** | Identity Provider | Stores users, groups, passwords; validates credentials via LDAPS | Does not perform 2FA |
| **FortiAuthenticator 300F** | MFA Provider | Manages FortiTokens, validates OTP/push via RADIUS | Does NOT validate passwords |
| **WALLIX Bastion** | PAM Gateway | Orchestrates login flow: LDAP Phase 1 + RADIUS Phase 2 | Does not store AD passwords |

### 1.2 Network Architecture

```
+===============================================================================+
|                  2FA INTEGRATION -- NETWORK ARCHITECTURE                      |
+===============================================================================+
|                                                                               |
|  USERS (Web UI / SSH / RDP)                                                   |
|  ==========================                                                   |
|        |                                                                      |
|        v  (443, 22, 3389)                                                     |
|                                                                               |
|  +--------------------------------------------------------------------+       |
|  |                     WALLIX BASTION NODES                           |       |
|  |   Site 1: 10.10.1.11, 10.10.1.12                                   |       |
|  |   Site 2: 10.10.2.11, 10.10.2.12                                   |       |
|  |   Site 3: 10.10.3.11, 10.10.3.12                                   |       |
|  |   Site 4: 10.10.4.11, 10.10.4.12                                   |       |
|  |   Site 5: 10.10.5.11, 10.10.5.12                                   |       |
|  +--+-----------------------+-----------------------------------------+       |
|     |                       |                                                 |
|     | LDAPS (636/TCP)       | RADIUS (1812/UDP)                               |
|     | Phase 1: Password     | Phase 2: OTP/Push                               |
|     |                       |                                                 |
|     v                       v                                                 |
|  +------------------+   +----------------------+                              |
|  | Active Directory |   | FortiAuthenticator   |                              |
|  | DC1: 10.20.0.10  |   | 300F Primary         |                              |
|  | DC2: 10.20.0.11  |   | 10.20.0.60           |                              |
|  +------------------+   |                      |                              |
|     ^                   | FortiAuth Secondary  |                              |
|     |                   | 10.20.0.61           |                              |
|     | LDAPS (636/TCP)    +----------+----------+                              |
|     | User sync                     |                                         |
|     +-------------------------------+                                         |
|                                                                               |
|  SHARED INFRASTRUCTURE VLAN: 10.20.0.0/24                                     |
+===============================================================================+
```

### 1.3 Port Matrix

| # | Source                         | Destination                 | Port     | Protocol | Purpose |
|---|--------------------------------|-----------------------------|----------|----------|---------|
| 1 | WALLIX Bastion (all nodes)     | AD DC1/DC2                  | 636/TCP  | LDAPS    | Password validation (Phase 1) |
| 2 | WALLIX Bastion (all nodes)     | FortiAuth Primary           | 1812/UDP | RADIUS   | OTP/push validation (Phase 2) |
| 3 | WALLIX Bastion (all nodes)     | FortiAuth Primary           | 1813/UDP | RADIUS   | Accounting (audit trail) |
| 4 | WALLIX Bastion (all nodes)     | FortiAuth Secondary         | 1812/UDP | RADIUS   | Failover MFA |
| 5 | WALLIX Bastion (all nodes)     | FortiAuth Secondary         | 1813/UDP | RADIUS   | Failover accounting |
| 6 | Access Manager 1 (10.100.1.10) | FortiAuth Primary/Secondary | 1812/UDP | RADIUS   | AM MFA |
| 7 | Access Manager 2 (10.100.2.10) | FortiAuth Primary/Secondary | 1812/UDP | RADIUS   | AM MFA |
| 8 | FortiAuth Primary              | AD DC1/DC2                  | 636/TCP  | LDAPS    | User sync (every 15 min) |
| 9 | FortiAuth Primary              | SMTP Server                 | 587/TCP  | SMTP/TLS | Token enrollment emails |
| 10 | FortiAuth Primary             | NTP (10.20.0.20/21)         | 123/UDP  | NTP      | Time sync (critical for OTP) |
| 11 | FortiAuth Primary             | FortiGuard Servers          | 443/TCP  | HTTPS    | License validation, updates |
| 12 | FortiAuth Primary             | FortiAuth Secondary         | 8009/TCP | HA Sync  | Configuration + token replication |
| 13 | Administrators                | FortiAuth Primary           | 443/TCP  | HTTPS    | Web UI management |
| 14 | User mobile devices           | FortiGuard Push Servers     | 443/TCP  | HTTPS    | Push notifications |

---

## 2. Authentication Flow — How It Works

```
+================================================================================+
|                2FA LOGIN FLOW (STEP BY STEP)                                   |
+================================================================================+
|                                                                                |
|  User                WALLIX Bastion        Active Directory   FortiAuth 300F   |
|  ====                ==============        ================   ==============   |
|    |                       |                      |                  |         |
|    | 1. Username + Password|                      |                  |         |
|    |---------------------->|                      |                  |         |
|    |                       |                      |                  |         |
|    |                       | 2. LDAP Bind (636)   |                  |         |
|    |                       |--------------------->|                  |         |
|    |                       |                      | 3. Validate      |         |
|    |                       |                      |    password      |         |
|    |                       | 4. Bind Success      |                  |         |
|    |                       |<---------------------|                  |         |
|    |                       |                      |                  |         |
|    |                       | 5. Fetch memberOf    |                  |         |
|    |                       |--------------------->|                  |         |
|    |                       | 6. Group list        |                  |         |
|    |                       |<---------------------|                  |         |
|    |                       |                      |                  |         |
|    |                       |  *** PHASE 1 COMPLETE -- password valid ***       |
|    |                       |                      |                  |         |
|    |                       | 7. RADIUS Access-Req |                  |         |
|    |                       |   (username only,    |                  |         |
|    |                       |    no password)      |                  |         |
|    |                       |---------------------------------------->|         |
|    |                       |                      |                  |         |
|    |                       |                      |  8. Lookup user  |         |
|    |                       |                      |     + token      |         |
|    |                       |                      |                  |         |
|    |                       | 9. RADIUS Challenge  |                  |         |
|    |                       |<----------------------------------------|         |
|    |                       |                      |                  |         |
|    | 10. "Enter OTP" or    |                      |                  |         |
|    |     Push notification |                      |                  |         |
|    |<----------------------|                      |                  |         |
|    |                       |                      |                  |         |
|    | 11. OTP / Push Approve|                      |                  |         |
|    |---------------------->|                      |                  |         |
|    |                       |                      |                  |         |
|    |                       | 12. RADIUS Access-Req (OTP)             |         |
|    |                       |---------------------------------------->|         |
|    |                       |                      |                  |         |
|    |                       |                      | 13. Validate OTP |         |
|    |                       |                      |                  |         |
|    |                       | 14. RADIUS Access-Accept                |         |
|    |                       |<----------------------------------------|         |
|    |                       |                      |                  |         |
|    |  *** PHASE 2 COMPLETE -- 2FA verified ***     |                  |        |
|    |                       |                      |                  |         |
|    | 15. Session started   |                      |                  |         |
|    |<----------------------|                      |                  |         |
|    |                       |                      |                  |         |
+================================================================================+
```

**Critical design principle:** FortiAuthenticator RADIUS policy must set First Factor to **None**. WALLIX already validated the password via LDAP. If FortiAuth is set to LDAP, it causes double password validation and **will break authentication**.

---

## 3. Prerequisites and Planning

### 3.1 Hardware and Software Requirements

| Component               | Requirement                 | Details |
|-------------------------|-----------------------------|-------------------------------------------------|
| **FortiAuthenticator**  | 300F hardware appliance     | Rack-mounted, 1U, dual power supply |
| **FortiAuth Firmware**  | 6.4+ (6.6+ recommended)     | Check: `get system status` via CLI |
| **FortiToken Licenses** | Per-user FortiToken Mobile  | Purchased in packs (5, 25, 100, 1000) |
| **FortiCare Support**   | Active subscription         | Required for firmware updates |
| **Active Directory**    | Windows Server 2016+ DFL    | Domain functional level 2016 or higher |
| **AD CS**               | Enterprise CA deployed      | Required for LDAPS certificates on DCs |
| **WALLIX Bastion**      | Version 12.x                | All nodes at same version |
| **NTP**                 | All components synchronized | Maximum drift: 30 seconds (OTP fails beyond this) |
| **DNS**                 | Forward and reverse records | All components must resolve each other by FQDN |

### 3.2 Accounts to Create

| Account            | Where                  | Purpose                         | Password Policy |
|--------------------|------------------------|---------------------------------|-----------------|
| `svc_wallix`       | Active Directory       | WALLIX LDAP bind (read-only)    | Never expires, 24+ chars |
| `svc-fortiauth`    | Active Directory       | FortiAuth LDAP sync (read-only) | Never expires, 24+ chars |
| `breakglass-admin` | WALLIX Bastion (local) | Emergency access without MFA    | Stored in safe, rotated quarterly |

### 3.3 AD Groups to Create

| Group Name       | Scope           | Purpose |
|------------------|-----------------|---------|
| `PAM-MFA-Users`  | Global Security | Users enrolled in FortiToken MFA |
| `PAM-MFA-Exempt` | Global Security | Break-glass/service accounts exempt from MFA |
| `PAM-Admins`     | Global Security | WALLIX administrator profile |
| `PAM-Operators`  | Global Security | WALLIX operator profile |
| `PAM-Auditors`   | Global Security | WALLIX auditor profile (read-only) |

### 3.4 Information to Gather Before Starting

Complete this worksheet before proceeding:

```
+=============================================================================+
|                    PRE-IMPLEMENTATION WORKSHEET                             |
+=============================================================================+
|                                                                             |
|  ACTIVE DIRECTORY                                                           |
|  ================                                                           |
|  Domain FQDN:          ____________________________  (e.g., company.com)    |
|  NetBIOS Name:         ____________________________  (e.g., COMPANY)        |
|  DC1 FQDN:             ____________________________                         |
|  DC1 IP:               ____________________________                         |
|  DC2 FQDN:             ____________________________                         |
|  DC2 IP:               ____________________________                         |
|  Base DN:              ____________________________  (e.g., DC=company,DC=com
|  Users OU:             ____________________________                         |
|  Service Accounts OU:  ____________________________                         |
|  PAM Groups OU:        ____________________________                         |
|  CA Certificate:       [ ] Exported  [ ] Copied to Bastion                  |
|                                                                             |
|  FORTIAUTHENTICATOR 300F                                                    |
|  ========================                                                   |
|  Primary FQDN:         ____________________________                         |
|  Primary IP:           ____________________________                         |
|  Secondary FQDN:       ____________________________  (if HA)                |
|  Secondary IP:         ____________________________  (if HA)                |
|  RADIUS Shared Secret: ____________________________  (32+ chars)            |
|  HA Sync Password:     ____________________________  (if HA)                |
|  Admin Password:       ____________________________                         |
|  SMTP Server:          ____________________________                         |
|  SMTP From Address:    ____________________________                         |
|                                                                             |
|  WALLIX BASTION                                                             |
|  ==============                                                             |
|  Admin URL:            ____________________________                         |
|  Node IPs:             ____________________________  (all sites)            |
|  Access Manager IPs:   ____________________________  (if applicable)        |
|  NTP Servers:          ____________________________                         |
|                                                                             |
+=============================================================================+
```

### 3.5 Prerequisites Validation Checklist

Complete **every** item before proceeding to Phase 1:

```
+=============================================================================+
|                    PREREQUISITES VALIDATION                                 |
+=============================================================================+
|                                                                             |
|  INFRASTRUCTURE                                                             |
|  ==============                                                             |
|  [ ] Active Directory operational with LDAPS (port 636) enabled             |
|  [ ] AD CS deployed -- DCs have valid LDAPS certificates                    |
|  [ ] FortiAuthenticator 300F rack-mounted, powered, IP assigned             |
|  [ ] FortiAuth firmware 6.4+ verified (get system status)                   |
|  [ ] FortiAuth base license activated                                       |
|  [ ] FortiToken Mobile licenses loaded (count matches user count)           |
|  [ ] WALLIX Bastion 12.x deployed and operational on all nodes              |
|  [ ] DNS records created for FortiAuth (forward + reverse)                  |
|                                                                             |
|  NETWORK                                                                    |
|  =======                                                                    |
|  [ ] Firewall rules configured per Port Matrix (Section 1.3)                |
|  [ ] LDAPS (636/TCP) open: all Bastion nodes -> AD DCs                      |
|  [ ] LDAPS (636/TCP) open: FortiAuth -> AD DCs                              |
|  [ ] RADIUS (1812/UDP) open: all Bastion nodes -> FortiAuth                 |
|  [ ] RADIUS (1813/UDP) open: all Bastion nodes -> FortiAuth                 |
|  [ ] SMTP (587/TCP) open: FortiAuth -> SMTP server                          |
|  [ ] NTP (123/UDP) open: all components -> NTP servers                      |
|  [ ] HA sync (8009/TCP) open: FortiAuth Primary <-> Secondary               |
|                                                                             |
|  TIME SYNCHRONIZATION (CRITICAL FOR OTP)                                    |
|  =======================================                                    |
|  [ ] NTP configured on all WALLIX Bastion nodes                             |
|  [ ] NTP configured on FortiAuthenticator 300F                              |
|  [ ] NTP configured on AD Domain Controllers                                |
|  [ ] Clock drift verified < 5 seconds across all components                 |
|                                                                             |
|  CERTIFICATES                                                               |
|  ============                                                               |
|  [ ] AD CA root certificate exported (PEM format)                           |
|  [ ] CA certificate imported into WALLIX Bastion trust store                |
|  [ ] CA certificate imported into FortiAuthenticator trust store            |
|  [ ] LDAPS connectivity verified with OpenSSL from each Bastion node        |
|                                                                             |
|  ALL ITEMS MUST BE [x] BEFORE PROCEEDING TO PHASE 1                         |
|                                                                             |
+=============================================================================+
```

---

## 4. Phase 1: Active Directory Preparation

### 4.1 Create Organizational Unit Structure

Run on a Domain Controller (PowerShell as Domain Admin):

```powershell
# Create OU structure for PAM-related objects
New-ADOrganizationalUnit -Name "PAM" `
  -Path "DC=company,DC=com" `
  -Description "WALLIX Bastion PAM objects"

New-ADOrganizationalUnit -Name "Service Accounts" `
  -Path "OU=PAM,DC=company,DC=com" `
  -Description "PAM service accounts"

New-ADOrganizationalUnit -Name "Groups" `
  -Path "OU=PAM,DC=company,DC=com" `
  -Description "PAM security groups"
```

### 4.2 Create Service Accounts

#### Service Account for WALLIX Bastion (LDAP Bind)

```powershell
# Create WALLIX LDAP bind service account
New-ADUser -Name "svc_wallix" `
  -SamAccountName "svc_wallix" `
  -UserPrincipalName "svc_wallix@company.com" `
  -Path "OU=Service Accounts,OU=PAM,DC=company,DC=com" `
  -Description "WALLIX Bastion LDAP bind -- read-only directory access" `
  -AccountPassword (Read-Host -AsSecureString "Enter password for svc_wallix") `
  -Enabled $true `
  -PasswordNeverExpires $true `
  -CannotChangePassword $true `
  -AllowReversiblePasswordEncryption $false

# Security hardening -- prevent interactive logon
Set-ADUser -Identity "svc_wallix" -AccountNotDelegated $true

# Verify creation
Get-ADUser -Identity "svc_wallix" -Properties * | Select-Object `
  Name, SamAccountName, Enabled, PasswordNeverExpires, `
  UserPrincipalName, DistinguishedName
```

#### Service Account for FortiAuthenticator (LDAP Sync)

```powershell
# Create FortiAuthenticator sync service account
New-ADUser -Name "svc-fortiauth" `
  -SamAccountName "svc-fortiauth" `
  -UserPrincipalName "svc-fortiauth@company.com" `
  -Path "OU=Service Accounts,OU=PAM,DC=company,DC=com" `
  -Description "FortiAuthenticator LDAP sync -- read-only directory access" `
  -AccountPassword (Read-Host -AsSecureString "Enter password for svc-fortiauth") `
  -Enabled $true `
  -PasswordNeverExpires $true `
  -CannotChangePassword $true `
  -AllowReversiblePasswordEncryption $false

Set-ADUser -Identity "svc-fortiauth" -AccountNotDelegated $true

# Verify creation
Get-ADUser -Identity "svc-fortiauth" -Properties * | Select-Object `
  Name, SamAccountName, Enabled, PasswordNeverExpires, DistinguishedName
```

> **Security note:** Both service accounts require only **read** permissions to the directory. The default "Authenticated Users" read access is sufficient. Do not grant write, delete, or reset-password permissions.

### 4.3 Create Security Groups

```powershell
# MFA enrollment groups
New-ADGroup -Name "PAM-MFA-Users" `
  -Path "OU=Groups,OU=PAM,DC=company,DC=com" `
  -GroupScope Global `
  -GroupCategory Security `
  -Description "Users enrolled in FortiToken MFA for WALLIX Bastion"

New-ADGroup -Name "PAM-MFA-Exempt" `
  -Path "OU=Groups,OU=PAM,DC=company,DC=com" `
  -GroupScope Global `
  -GroupCategory Security `
  -Description "Users exempt from MFA (break-glass, service accounts)"

# WALLIX profile mapping groups
New-ADGroup -Name "PAM-Admins" `
  -Path "OU=Groups,OU=PAM,DC=company,DC=com" `
  -GroupScope Global `
  -GroupCategory Security `
  -Description "Maps to WALLIX administrator profile"

New-ADGroup -Name "PAM-Operators" `
  -Path "OU=Groups,OU=PAM,DC=company,DC=com" `
  -GroupScope Global `
  -GroupCategory Security `
  -Description "Maps to WALLIX operator profile"

New-ADGroup -Name "PAM-Auditors" `
  -Path "OU=Groups,OU=PAM,DC=company,DC=com" `
  -GroupScope Global `
  -GroupCategory Security `
  -Description "Maps to WALLIX auditor profile (read-only)"

# Verify all groups created
Get-ADGroup -Filter 'Name -like "PAM-*"' -SearchBase "OU=Groups,OU=PAM,DC=company,DC=com" |
  Format-Table Name, GroupScope, GroupCategory, DistinguishedName -AutoSize
```

### 4.4 Assign Users to Groups

```powershell
# Add initial administrators
Add-ADGroupMember -Identity "PAM-Admins" -Members "jadmin","kadmin"
Add-ADGroupMember -Identity "PAM-MFA-Users" -Members "jadmin","kadmin"

# Add operators
Add-ADGroupMember -Identity "PAM-Operators" -Members "joperator","koperator"
Add-ADGroupMember -Identity "PAM-MFA-Users" -Members "joperator","koperator"

# Add auditors
Add-ADGroupMember -Identity "PAM-Auditors" -Members "jauditor"
Add-ADGroupMember -Identity "PAM-MFA-Users" -Members "jauditor"

# Exempt break-glass accounts from MFA
Add-ADGroupMember -Identity "PAM-MFA-Exempt" -Members "breakglass-admin"

# Verify membership
Get-ADGroupMember -Identity "PAM-MFA-Users" | Format-Table Name, SamAccountName
Get-ADGroupMember -Identity "PAM-Admins" | Format-Table Name, SamAccountName
```

### 4.5 Harden Service Accounts with GPO

Create a Group Policy Object to prevent interactive logon for service accounts:

```powershell
# Option 1: GPO (recommended for enterprise)
# Create GPO: "PAM-ServiceAccount-Restrictions"
# Link to: OU=Service Accounts,OU=PAM,DC=company,DC=com
#
# Computer Configuration > Policies > Windows Settings > Security Settings >
#   Local Policies > User Rights Assignment:
#
#   "Deny log on locally":                    svc_wallix, svc-fortiauth
#   "Deny log on through Remote Desktop":     svc_wallix, svc-fortiauth
#   "Deny log on as a batch job":             svc_wallix, svc-fortiauth
#   "Deny access to this computer from network": (do NOT add -- they need LDAP)

# Option 2: Direct (if GPO not practical)
# Already set AccountNotDelegated in Step 4.2
```

### 4.6 Verify LDAPS Is Enabled

```powershell
# On Domain Controller -- verify LDAPS certificate exists
Get-ChildItem Cert:\LocalMachine\My | Where-Object {
  $_.EnhancedKeyUsageList -match "Server Authentication"
} | Format-List Subject, NotAfter, Thumbprint, HasPrivateKey

# Test LDAPS is listening
Test-NetConnection -ComputerName dc.company.com -Port 636

# If LDAPS is NOT enabled, AD CS must issue a certificate to the DC.
# Simplest method: ensure "Domain Controller Authentication" template is published.
```

### 4.7 Export CA Certificate

The CA certificate is needed by both WALLIX Bastion and FortiAuthenticator to trust the DCs' LDAPS certificates.

```powershell
# Export root CA certificate (on CA server or any domain-joined machine)
certutil -ca.cert C:\Temp\company-ca.cer

# Convert to PEM format (if needed, do this on a Linux box)
# openssl x509 -inform DER -in company-ca.cer -out company-ca.pem

# Alternative: export via web enrollment
# https://ca-server.company.com/certsrv
# Download CA certificate > Base 64 encoded
```

### 4.8 Phase 1 Validation

Run these checks from a WALLIX Bastion node:

```bash
# 1. DNS resolution
nslookup dc.company.com
# Expected: returns 10.20.0.10

# 2. LDAPS connectivity
nc -zv dc.company.com 636
# Expected: Connection to dc.company.com 636 port [tcp/ldaps] succeeded!

# 3. Certificate validation
echo | openssl s_client -connect dc.company.com:636 2>/dev/null | \
  openssl x509 -noout -subject -issuer -dates
# Expected: shows valid cert with correct subject and future expiry

# 4. LDAP bind test with WALLIX service account
ldapsearch -x -H ldaps://dc.company.com:636 \
  -D "CN=svc_wallix,OU=Service Accounts,OU=PAM,DC=company,DC=com" \
  -W \
  -b "DC=company,DC=com" \
  "(sAMAccountName=jadmin)" \
  dn displayName mail memberOf
# Expected: returns user DN with group memberships

# 5. Verify PAM groups are visible
ldapsearch -x -H ldaps://dc.company.com:636 \
  -D "CN=svc_wallix,OU=Service Accounts,OU=PAM,DC=company,DC=com" \
  -W \
  -b "OU=Groups,OU=PAM,DC=company,DC=com" \
  "(objectClass=group)" cn
# Expected: lists PAM-MFA-Users, PAM-Admins, PAM-Operators, PAM-Auditors, PAM-MFA-Exempt
```

```
+=============================================================================+
|  PHASE 1 CHECKPOINT                                                         |
+=============================================================================+
|                                                                             |
|  [ ] Service accounts created: svc_wallix, svc-fortiauth                    |
|  [ ] Security groups created: PAM-MFA-Users, PAM-Admins, PAM-Operators,     |
|      PAM-Auditors, PAM-MFA-Exempt                                           |
|  [ ] Users assigned to appropriate groups                                   |
|  [ ] LDAPS enabled and certificate valid on all DCs                         |
|  [ ] CA certificate exported (PEM format)                                   |
|  [ ] LDAP bind test successful from Bastion nodes                           |
|  [ ] Service accounts hardened (no interactive logon)                       |
|                                                                             |
|  ALL ITEMS MUST BE [x] BEFORE PROCEEDING TO PHASE 2                         |
|                                                                             |
+=============================================================================+
```

---

## 5. Phase 2: FortiAuthenticator 300F Configuration

### 5.1 Initial Appliance Setup

#### Rack Mount and Power On

The FortiAuthenticator 300F is a 1U rack-mount appliance. Connect:
- Port 1 (mgmt) to the management/shared infrastructure VLAN (10.20.0.0/24)
- Dual power supplies to separate power feeds (redundancy)
- Console cable for initial configuration

#### CLI Initial Configuration

Connect via serial console (9600 baud, 8N1):

```bash
# Set hostname
config system global
  set hostname "fortiauth"
end

# Configure network interface
config system interface
  edit "port1"
    set ip 10.20.0.60 255.255.255.0
    set allowaccess ping https ssh snmp
  next
end

# Set default gateway
config router static
  edit 1
    set gateway 10.20.0.1
    set device "port1"
  next
end

# Configure DNS
config system dns
  set primary 10.20.0.10
  set secondary 10.20.0.11
end

# Set admin password (change from default)
config system admin
  edit "admin"
    set password PASSWORD_REDACTED
  next
end
```

#### Verify Basic Connectivity

```bash
# From FortiAuthenticator CLI:
execute ping 10.20.0.10       # AD DC1
execute ping 10.20.0.11       # AD DC2
execute ping 10.20.0.1        # Gateway
execute ping 10.10.1.11       # WALLIX Bastion Site 1, Node 1

# Verify firmware version
get system status
# Expected: Version: FortiAuthenticator-300F v6.6.x
```

### 5.2 Configure NTP (Critical)

OTP tokens are time-based (TOTP). Clock drift > 30 seconds causes authentication failures.

```bash
# FortiAuthenticator CLI:
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

# Verify NTP sync
diagnose system ntp status
# Expected: synchronized, offset < 1 second
```

### 5.3 Install SSL Certificate

```
Via Web UI (https://10.20.0.60):

1. System > Certificates > Local Certificates
2. Click "Import"
3. Upload:
   - Certificate:  fortiauth.company.com.crt  (signed by corporate CA)
   - Private Key:  fortiauth.company.com.key
   - CA Chain:     company-ca-chain.crt
4. Click "OK"

5. System > Administration > System Access
6. HTTPS Server Certificate: select "fortiauth.company.com"
7. Click "Apply"
```

### 5.4 Configure SMTP for Token Enrollment Emails

```bash
# FortiAuthenticator CLI:
config system email-server
  set server "smtp.company.com"
  set port 587
  set security starttls
  set authenticate enable
  set username "fortiauth-noreply@company.com"
  set password PASSWORD_REDACTED
end

# Test email delivery
diagnose test email send admin@company.com "FortiAuth Test" "Email delivery test"
```

**Via Web UI:**

```
1. System > Messaging > SMTP Servers
2. Configure:
   Server:     smtp.company.com
   Port:       587
   Security:   STARTTLS
   Username:   fortiauth-noreply@company.com
   Password:   [SMTP password]
   From:       "FortiAuthenticator" <fortiauth-noreply@company.com>
3. Click "Test" to verify delivery
```

### 5.5 Import CA Certificate for LDAPS

FortiAuthenticator needs the AD CA certificate to trust the DCs' LDAPS connections.

```
Via Web UI:

1. System > Certificates > CA Certificates
2. Click "Import"
3. Upload: company-ca.pem (exported in Phase 1, Step 4.7)
4. Name: "Company-Root-CA"
5. Click "OK"
```

### 5.6 Configure LDAP User Sync from Active Directory

```
Via Web UI:

1. Authentication > Remote Auth. Servers > LDAP

2. Click "Create New"

3. Configure Primary LDAP Server:
   Name:                AD-Primary
   Primary Server:      10.20.0.10  (dc.company.com)
   Port:                636
   Security:            Secure (LDAPS)
   CA Certificate:      Company-Root-CA
   Bind Type:           Regular Bind
   Username:            CN=svc-fortiauth,OU=Service Accounts,OU=PAM,DC=company,DC=com
   Password:            [svc-fortiauth password]
   Base DN:             DC=company,DC=com

4. Click "Test" -- must return "Connection successful"

5. Click "OK"
```

**Configure User Sync:**

```
Via Web UI:

1. Authentication > User Management > Remote Users

2. Click "Import"

3. Select LDAP Source: AD-Primary

4. Configure Import:
   Remote LDAP:         AD-Primary
   Base DN:             OU=Users,DC=company,DC=com
   User Filter:         (&(objectClass=user)(memberOf=CN=PAM-MFA-Users,OU=Groups,OU=PAM,DC=company,DC=com)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))
   Username Attribute:  sAMAccountName
   Email Attribute:     mail

   Import Schedule:     Every 15 minutes

5. Click "Import" for initial sync

6. Verify: user count matches PAM-MFA-Users group membership
```

> **Filter explanation:** The user filter imports only users who are (a) members of PAM-MFA-Users, (b) not disabled in AD (userAccountControl bit 2). This prevents importing service accounts or disabled users, saving FortiToken licenses.

### 5.7 Create RADIUS Clients

Every WALLIX Bastion node and Access Manager node must be registered as a RADIUS client. Unregistered sources receive RADIUS reject responses silently.

```
Via Web UI:

1. Authentication > RADIUS Service > Clients

2. Create one entry per node using the SAME shared secret:

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

   For EACH entry:
   Secret:         [Same shared secret -- 32+ characters, alphanumeric + symbols]
   Authentication: [x] Enable
   Accounting:     [x] Enable (for audit trail)
```

> **Warning:** Any Bastion or Access Manager node NOT registered here will have MFA silently fail. Users on that node will see "RADIUS server not responding." Always verify the client count matches your node count (10 Bastions + 2 Access Managers = 12 clients).

### 5.8 Create RADIUS Authentication Policy

```
Via Web UI:

1. Authentication > RADIUS Service > Policies

2. Click "Create New"

3. Configure:
   Name:             WALLIX-MFA-Policy

   Matching Rules:
   RADIUS Clients:   [Select ALL 12 clients created in Step 5.7]

   Authentication:
   +==========================================================+
   |                                                          |
   |  First Factor:   None                                    |
   |                  ^^^^                                    |
   |  THIS IS CRITICAL. WALLIX validates the password via     |
   |  LDAP. FortiAuth only validates the second factor.       |
   |  Setting this to "LDAP" causes DOUBLE password           |
   |  validation and BREAKS the deployment.                   |
   |                                                          |
   |  Second Factor:  FortiToken                              |
   |                                                          |
   +==========================================================+

   Options:
   [x] Allow Push Notification
   [x] Allow OTP (manual code entry)
   [ ] Allow SMS (optional -- requires SMS gateway)

   Timeout:        60 seconds (time for user to respond to push/enter OTP)

4. Click "OK"
```

### 5.9 Configure RADIUS Reply Attributes (Group-to-Profile Mapping)

FortiAuthenticator can return RADIUS `Class` attributes that WALLIX uses to automatically assign profiles based on AD group membership.

```
Via Web UI:

1. Authentication > RADIUS Service > Policies > WALLIX-MFA-Policy

2. Under "RADIUS Attributes" > "Reply Attributes", add:

   Attribute: Class (25)
   Value:     PAM-Admin
   Condition: User is member of CN=PAM-Admins,OU=Groups,OU=PAM,DC=company,DC=com

   Attribute: Class (25)
   Value:     PAM-Operator
   Condition: User is member of CN=PAM-Operators,OU=Groups,OU=PAM,DC=company,DC=com

   Attribute: Class (25)
   Value:     PAM-Auditor
   Condition: User is member of CN=PAM-Auditors,OU=Groups,OU=PAM,DC=company,DC=com

3. Click "OK"
```

### 5.10 Assign FortiTokens to Users

#### FortiToken Mobile (Recommended)

```
Via Web UI:

1. Authentication > User Management > Remote Users

2. Select a user (e.g., jadmin)

3. Click "Edit" > Token Assignment

4. Configure:
   Token Type:     FortiToken Mobile
   Delivery:       Email activation code

5. Click "Provision Token"

6. User receives email with:
   - Activation QR code
   - Manual activation URL
   - Instructions to install FortiToken Mobile app

7. Repeat for each user in PAM-MFA-Users group
```

**Bulk Token Assignment:**

```
Via Web UI:

1. Authentication > User Management > Remote Users
2. Select multiple users (checkbox)
3. Actions > "Provision FortiToken Mobile"
4. Delivery: Email
5. Click "OK" -- all selected users receive enrollment emails
```

#### FortiToken Hardware (Alternative)

```
Via Web UI:

1. Authentication > FortiToken > Hardware Tokens
2. Import token seed file (provided by Fortinet with hardware tokens)
3. For each token:
   - Select serial number
   - Click "Assign"
   - Select user
   - Record: user <-> token serial mapping
```

### 5.11 Phase 2 Validation

```bash
# On FortiAuthenticator CLI:

# 1. Verify LDAP sync is working
diagnose debug application radiusd -1
diagnose debug enable
# Check logs for successful LDAP sync

# 2. Verify user count
# Web UI: Authentication > User Management > Remote Users
# Count must match PAM-MFA-Users membership in AD

# 3. Verify RADIUS service is running
diagnose system radius-server status
# Expected: RADIUS service: running

# 4. Verify NTP sync
diagnose system ntp status
# Expected: synchronized, offset < 1s
```

```
+=============================================================================+
|  PHASE 2 CHECKPOINT                                                         |
+=============================================================================+
|                                                                             |
|  [ ] FortiAuth 300F configured with static IP, hostname, DNS                |
|  [ ] NTP synchronized (drift < 1 second)                                    |
|  [ ] SSL certificate installed for web UI                                   |
|  [ ] SMTP configured and test email sent successfully                       |
|  [ ] AD CA certificate imported                                             |
|  [ ] LDAP user sync configured and initial sync completed                   |
|  [ ] User count in FortiAuth matches PAM-MFA-Users in AD                    |
|  [ ] All 12 RADIUS clients created (10 Bastions + 2 Access Managers)        |
|  [ ] RADIUS policy created: First Factor = None, Second Factor = FortiToken |
|  [ ] RADIUS reply attributes configured for group-to-profile mapping        |
|  [ ] FortiTokens assigned to at least 2 test users                          |
|  [ ] Test users have activated FortiToken Mobile on their phones            |
|                                                                             |
|  ALL ITEMS MUST BE [x] BEFORE PROCEEDING TO PHASE 3                         |
|                                                                             |
+=============================================================================+
```

---

## 6. Phase 3: WALLIX Bastion Configuration

### 6.1 Import AD CA Certificate

Run on **every** WALLIX Bastion node:

```bash
# Copy CA certificate to Bastion (from jump host or SCP)
scp company-ca.pem admin@10.10.1.11:/tmp/

# Convert to CRT if needed
openssl x509 -inform PEM -in /tmp/company-ca.pem -out /tmp/company-ca.crt

# Add to system trust store
sudo cp /tmp/company-ca.crt /usr/local/share/ca-certificates/company-ca.crt
sudo update-ca-certificates
# Expected: 1 added

# Verify certificate is trusted
openssl verify -CApath /etc/ssl/certs/ /tmp/company-ca.crt
# Expected: /tmp/company-ca.crt: OK

# Test LDAPS with trusted certificate
openssl s_client -connect dc.company.com:636 \
  -CApath /etc/ssl/certs/ \
  -verify_return_error </dev/null 2>&1 | grep "Verify return code"
# Expected: Verify return code: 0 (ok)
```

### 6.2 Configure LDAP Domain (AD Integration)

**Via Web UI:**

```
1. Login to WALLIX Admin: https://wallix.company.com/admin

2. Navigate to: Configuration > Authentication Domains > LDAP

3. Click "Add"

4. Configure:
   Name:                    Corporate-AD
   Description:             Primary Active Directory domain
   Enabled:                 [x] Yes

   CONNECTION
   ----------
   Server 1 (Primary):     dc.company.com
   Port:                    636
   Use SSL/TLS:             [x] LDAPS
   Server 2 (Failover):    dc2.company.com
   Port:                    636

   BIND CREDENTIALS
   ----------------
   Bind DN:                 CN=svc_wallix,OU=Service Accounts,OU=PAM,DC=company,DC=com
   Bind Password:           [svc_wallix password]

   SEARCH SETTINGS
   ---------------
   Base DN:                 DC=company,DC=com
   User Base DN:            DC=company,DC=com
   Group Base DN:           OU=Groups,OU=PAM,DC=company,DC=com

   USER FILTER
   -----------
   User Filter:             (&(objectClass=user)(sAMAccountName={login})(!(userAccountControl:1.2.840.113556.1.4.803:=2)))
   Login Attribute:         sAMAccountName

   ATTRIBUTE MAPPING
   -----------------
   Display Name:            displayName
   Email:                   mail
   Groups:                  memberOf

   ADVANCED
   --------
   Connection Timeout:      10 seconds
   Search Scope:            Subtree
   Nested Groups:           [x] Enable
   Certificate Validation:  [x] Verify server certificate

5. Click "Test Connection"
   Expected: "Connection successful -- X users found"

6. Click "Save"
```

**Via CLI:**

```bash
# Add LDAP domain
wabadmin ldap add \
    --name "Corporate-AD" \
    --server "dc.company.com" \
    --port 636 \
    --ssl \
    --bind-dn "CN=svc_wallix,OU=Service Accounts,OU=PAM,DC=company,DC=com" \
    --bind-password "[password]" \
    --base-dn "DC=company,DC=com" \
    --user-filter "(&(objectClass=user)(sAMAccountName={login})(!(userAccountControl:1.2.840.113556.1.4.803:=2)))" \
    --login-attribute "sAMAccountName" \
    --display-name-attribute "displayName" \
    --email-attribute "mail"

# Add failover DC
wabadmin ldap server add \
    --domain "Corporate-AD" \
    --server "dc2.company.com" \
    --port 636 \
    --ssl \
    --priority 2

# Test connection
wabadmin ldap test "Corporate-AD"
# Expected: Connection successful
```

### 6.3 Configure User and Group Synchronization

```bash
# Run initial user import (preview first)
wabadmin ldap import --domain "Corporate-AD" --preview
# Review the list -- verify only expected users appear

# Import users
wabadmin ldap import --domain "Corporate-AD" \
  --filter "(memberOf=CN=PAM-MFA-Users,OU=Groups,OU=PAM,DC=company,DC=com)"

# Configure scheduled sync (every 4 hours)
wabadmin ldap sync schedule \
    --domain "Corporate-AD" \
    --interval "0 */4 * * *" \
    --sync-users \
    --sync-groups \
    --disable-removed-users
```

### 6.4 Configure Group-to-Profile Mapping

```bash
# Map AD groups to WALLIX profiles
wabadmin ldap group-map add \
    --domain "Corporate-AD" \
    --ldap-group "CN=PAM-Admins,OU=Groups,OU=PAM,DC=company,DC=com" \
    --wallix-profile administrator \
    --priority 1

wabadmin ldap group-map add \
    --domain "Corporate-AD" \
    --ldap-group "CN=PAM-Operators,OU=Groups,OU=PAM,DC=company,DC=com" \
    --wallix-profile operator \
    --priority 2

wabadmin ldap group-map add \
    --domain "Corporate-AD" \
    --ldap-group "CN=PAM-Auditors,OU=Groups,OU=PAM,DC=company,DC=com" \
    --wallix-profile auditor \
    --priority 3

# Verify mappings
wabadmin ldap group-map list --domain "Corporate-AD"
```

### 6.5 Configure RADIUS Server (FortiAuthenticator)

**Via Web UI:**

```
1. Navigate to: Configuration > Authentication > External Auth

2. Click "Add RADIUS Server"

3. Configure Primary:
   Name:               FortiAuth-Primary
   Server Address:     fortiauth.company.com  (10.20.0.60)
   Authentication Port: 1812
   Accounting Port:    1813
   Shared Secret:      [Same secret configured in FortiAuth RADIUS clients]
   Timeout:            30 seconds
   Retries:            3
   Priority:           1

4. Click "Test Connection"
   Expected: "RADIUS server reachable"

5. Click "Save"

6. Add Secondary (if HA):
   Name:               FortiAuth-Secondary
   Server Address:     10.20.0.61  (use IP -- DNS must not be a dependency in failover)
   Authentication Port: 1812
   Accounting Port:    1813
   Shared Secret:      [Same shared secret]
   Timeout:            30 seconds
   Retries:            3
   Priority:           2

7. Click "Save"
```

**Via CLI:**

```bash
# Add primary RADIUS server
wabadmin auth radius add \
    --name "FortiAuth-Primary" \
    --server "fortiauth.company.com" \
    --port 1812 \
    --secret "[shared-secret]" \
    --timeout 30 \
    --retries 3

# Add secondary (failover)
wabadmin auth radius add \
    --name "FortiAuth-Secondary" \
    --server "10.20.0.61" \
    --port 1812 \
    --secret "[shared-secret]" \
    --priority 2

# Configure automatic failover
wabadmin auth radius failover \
    --primary "FortiAuth-Primary" \
    --secondary "FortiAuth-Secondary" \
    --failover-timeout 10 \
    --failback-delay 300

# Test RADIUS
wabadmin auth radius test "FortiAuth-Primary"
```

### 6.6 Configure MFA Policy

**Via Web UI:**

```
1. Navigate to: Configuration > Authentication > MFA Policy

2. Configure:

   MFA Provider:       RADIUS (FortiAuth-Primary)

   MFA Required For:
   [x] All users
   [ ] Admin users only
   [ ] Specific groups

   Enforcement Scope:
   [x] Web UI login
   [x] SSH proxy login
   [x] RDP proxy login
   [x] API authentication

   Bypass Options:
   [ ] Allow bypass for internal IPs
   [ ] Allow bypass for specific users
   Note: Use PAM-MFA-Exempt group in AD + local config for break-glass

   Timeout:           60 seconds (must match FortiAuth RADIUS policy timeout)

3. Click "Save"
```

**Via CLI:**

```bash
# Enable MFA
wabadmin auth mfa enable \
    --provider radius \
    --server "FortiAuth-Primary" \
    --scope all \
    --enforce web,ssh,rdp,api

# Verify
wabadmin auth mfa status
```

### 6.7 Configure RADIUS Class Attribute Mapping

Map the RADIUS `Class` attribute returned by FortiAuthenticator to WALLIX profiles:

```bash
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

# Verify
wabadmin auth radius profile-map --list
```

**Group-to-Profile Mapping Summary:**

| AD Group       | RADIUS Class | WALLIX Profile       | Access Level |
|----------------|--------------|----------------------|--------------|
| PAM-Admins     | PAM-Admin    | administrator        | Full admin |
| PAM-Operators  | PAM-Operator | operator             | Manage targets, no admin |
| PAM-Auditors   | PAM-Auditor  | auditor              | Read-only, session review |
| PAM-MFA-Exempt | _(no MFA)_   | _(per local config)_ | Break-glass only |

### 6.8 Configure Break-Glass Account

Create a local account that can authenticate without MFA when FortiAuthenticator is unavailable:

```bash
# Create local break-glass account
wabadmin user add \
    --login "breakglass-admin" \
    --display-name "Break Glass Emergency Account" \
    --password "[strong-password, stored in physical safe]" \
    --profile administrator \
    --auth-type local

# Exempt from MFA
wabadmin auth mfa bypass \
    --user "breakglass-admin" \
    --permanent \
    --reason "Break-glass emergency account -- exempt by policy"

# Configure alerting for any use of this account
wabadmin alert create \
    --name "BreakGlass-Used" \
    --condition "login_user == breakglass-admin" \
    --action email \
    --recipient security@company.com
```

> **Policy:** The break-glass password must be stored in a physical safe or HSM. Its use triggers an immediate security alert. Rotate quarterly. Every use must be documented in an incident ticket.

### 6.9 Replicate Configuration to All Nodes

The LDAP domain, RADIUS server, and MFA policy configuration must be present on **every** WALLIX Bastion node. Depending on your deployment:

- **Clustered Bastion:** Configuration replicates automatically between cluster members
- **Standalone nodes:** Repeat Steps 6.1 through 6.8 on each node, or use the WALLIX API to push configuration:

```bash
# Script to replicate config via API (run from management host)
for NODE_IP in 10.10.1.11 10.10.1.12 10.10.2.11 10.10.2.12 \
               10.10.3.11 10.10.3.12 10.10.4.11 10.10.4.12 \
               10.10.5.11 10.10.5.12; do
  echo "=== Configuring $NODE_IP ==="
  # Import CA certificate
  ssh admin@$NODE_IP "sudo cp /tmp/company-ca.crt /usr/local/share/ca-certificates/ && sudo update-ca-certificates"
  # Verify LDAP
  ssh admin@$NODE_IP "wabadmin ldap test Corporate-AD"
  # Verify RADIUS
  ssh admin@$NODE_IP "wabadmin auth radius test FortiAuth-Primary"
  # Verify MFA
  ssh admin@$NODE_IP "wabadmin auth mfa status"
done
```

### 6.10 Phase 3 Validation

```bash
# 1. Verify LDAP domain is configured and connected
wabadmin ldap list
wabadmin ldap test "Corporate-AD"
# Expected: Connection successful

# 2. Verify user search works
wabadmin ldap search "Corporate-AD" "jadmin"
# Expected: User found with correct attributes

# 3. Verify group mappings
wabadmin ldap group-map list --domain "Corporate-AD"
# Expected: 3 mappings (Admin, Operator, Auditor)

# 4. Verify RADIUS configuration
wabadmin auth radius show "FortiAuth-Primary"
# Expected: Server details displayed

# 5. Verify MFA is enabled
wabadmin auth mfa status
# Expected: MFA enabled, provider RADIUS, scope all
```

```
+=============================================================================+
|  PHASE 3 CHECKPOINT                                                         |
+=============================================================================+
|                                                                             |
|  [ ] CA certificate imported on all Bastion nodes                           |
|  [ ] LDAP domain "Corporate-AD" configured with LDAPS                       |
|  [ ] LDAP connection test successful from all nodes                         |
|  [ ] User import/sync completed -- user count matches AD                    |
|  [ ] Group-to-profile mappings configured                                   |
|  [ ] RADIUS server "FortiAuth-Primary" configured and reachable             |
|  [ ] RADIUS failover to "FortiAuth-Secondary" configured (if HA)            |
|  [ ] MFA policy enabled for Web UI, SSH, RDP, and API                       |
|  [ ] RADIUS Class attribute mappings configured                             |
|  [ ] Break-glass account created and alert configured                       |
|  [ ] Configuration replicated to ALL Bastion nodes                          |
|                                                                             |
|  ALL ITEMS MUST BE [x] BEFORE PROCEEDING TO PHASE 4                         |
|                                                                             |
+=============================================================================+
```

---

## 7. Phase 4: End-to-End Testing

### 7.1 Test RADIUS Authentication from CLI

```bash
# Test on WALLIX Bastion
wabadmin auth test \
    --provider radius \
    --user "jadmin" \
    --password "[password]"

# Expected flow:
# 1. Password validated against LDAP
# 2. FortiToken push sent to jadmin's phone
# 3. jadmin approves push
# 4. Output: "Authentication successful"
```

### 7.2 Test Web UI Login

```
1. Open browser: https://wallix.company.com

2. Enter credentials:
   Username: jadmin
   Password: [AD password]

3. Click "Login"

4. MFA challenge appears:
   "Waiting for FortiToken authentication..."

5. On FortiToken Mobile app:
   - Push notification appears
   - Review: "Login to WALLIX Bastion"
   - Tap "Approve"

6. Login completes -- dashboard appears

7. Verify correct profile applied:
   - Check user profile in top-right menu
   - jadmin (PAM-Admins member) should have "administrator" profile
```

### 7.3 Test SSH Proxy Login

```bash
# From a client workstation:
ssh jadmin@wallix.company.com

# Step 1: Password prompt
Password: [AD password]

# Step 2: MFA prompt
# "FortiToken verification required. Enter OTP or approve push:"

# Option A: Enter 6-digit OTP from FortiToken Mobile
OTP: 123456

# Option B: Approve push notification on phone

# Step 3: Target selection appears
# jadmin has access to the following targets:
# 1. linux-server-01 (SSH)
# 2. linux-server-02 (SSH)
# Select target: 1
```

### 7.4 Test RDP Proxy Login

```
1. Open Remote Desktop Connection
2. Computer: wallix.company.com
3. Username: jadmin
4. Enter AD password
5. MFA prompt appears -- enter OTP or approve push
6. RDP target selection appears
7. Connect to target
```

### 7.5 Test Failure Scenarios

| Test Case              | Action                        | Expected Result |
|------------------------|-------------------------------|-----------------|
| Wrong AD password      | Enter incorrect password      | "Invalid credentials" — no MFA prompt (LDAP fails in Phase 1) |
| Wrong OTP              | Enter invalid 6-digit code    | "Authentication failed — invalid OTP" |
| OTP timeout            | Do not respond within 60s     | "Authentication timeout — MFA not completed" |
| Disabled AD account    | Disable user in AD, try login | "Authentication failed — account disabled" |
| No FortiToken assigned | Try user without token        | "User not enrolled in MFA" |
| Break-glass account    | Login as breakglass-admin     | Login succeeds without MFA prompt; alert email sent |
| FortiAuth unreachable  | Block RADIUS port, try login  | Failover to secondary; if both down, MFA bypass or deny per policy |

### 7.6 Test from Every Site

```bash
# Validate from each Bastion node
for NODE in 10.10.1.11 10.10.1.12 10.10.2.11 10.10.2.12 \
            10.10.3.11 10.10.3.12 10.10.4.11 10.10.4.12 \
            10.10.5.11 10.10.5.12; do
  echo "=== Testing from $NODE ==="
  ssh admin@$NODE "wabadmin auth test --user jadmin --provider radius --debug"
  echo ""
done
```

```
+=============================================================================+
|  PHASE 4 CHECKPOINT                                                         |
+=============================================================================+
|                                                                             |
|  [ ] CLI RADIUS test passed (wabadmin auth test)                            |
|  [ ] Web UI login with MFA -- push notification approved                    |
|  [ ] Web UI login with MFA -- manual OTP entry                              |
|  [ ] SSH proxy login with MFA passed                                        |
|  [ ] RDP proxy login with MFA passed                                        |
|  [ ] Wrong password correctly rejected (no MFA prompt)                      |
|  [ ] Wrong OTP correctly rejected                                           |
|  [ ] OTP timeout correctly handled                                          |
|  [ ] Disabled AD account correctly rejected                                 |
|  [ ] Break-glass login works without MFA + alert triggered                  |
|  [ ] Profile correctly assigned based on AD group membership                |
|  [ ] Test passed from ALL Bastion nodes (all 5 sites)                       |
|                                                                             |
|  ALL ITEMS MUST BE [x] BEFORE PROCEEDING TO PHASE 5                         |
|                                                                             |
+=============================================================================+
```

---

## 8. Phase 5: User Enrollment at Scale

### 8.1 Enrollment Strategy

| Approach                | When to Use                       | Effort |
|-------------------------|-----------------------------------|--------|
| **Admin-assisted**      | < 50 users, high-touch            | Admin provisions token per user |
| **Self-service portal** | 50–500 users, standard onboarding | Users self-enroll via portal |
| **Bulk email**          | > 500 users, mass rollout         | Admin sends enrollment emails in bulk |

### 8.2 Self-Service Portal Configuration

```
On FortiAuthenticator Web UI:

1. Authentication > Self-Service Portal

2. Enable Self-Service:
   [x] Enable self-service portal
   URL: https://fortiauth.company.com/self-service

3. Allowed Actions:
   [x] FortiToken Mobile enrollment
   [x] Password change (via AD)
   [ ] Account recovery

4. Authentication:
   LDAP Source:  AD-Primary  (users authenticate with AD credentials)

5. Click "Save"
```

### 8.3 User Communication Template

Send this to all users before enabling MFA enforcement:

```
Subject: ACTION REQUIRED -- Enable Multi-Factor Authentication for WALLIX

Dear [User],

Starting [DATE], multi-factor authentication (MFA) will be required for all
WALLIX Bastion access. You must enroll your mobile device before this date.

ENROLLMENT STEPS (5 minutes):

1. INSTALL the FortiToken Mobile app:
   - iOS:     App Store > Search "FortiToken Mobile" by Fortinet
   - Android: Play Store > Search "FortiToken Mobile" by Fortinet

2. CHECK YOUR EMAIL for an activation message from FortiAuthenticator
   Subject: "FortiToken Mobile Activation"
   - Open this email ON YOUR MOBILE DEVICE
   - Tap the activation link (or scan the QR code with FortiToken app)
   - FortiToken registers automatically

3. TEST YOUR LOGIN:
   - Go to https://wallix.company.com
   - Enter your username and password as usual
   - When prompted, approve the push notification on your phone
     OR enter the 6-digit code shown in FortiToken Mobile

WHAT CHANGES:
- You will see a second prompt after entering your password
- Approve the push notification (recommended) or type the 6-digit code
- Nothing else changes -- same username, same password, same targets

NEED HELP?
Contact IT Support: support@company.com | Extension 1234
Support hours: Mon-Fri 08:00-18:00

Thank you,
IT Security Team
```

### 8.4 Phased Rollout Plan

| Phase               | Timeline | Users                             | MFA Setting |
|---------------------|----------|-----------------------------------|-------------|
| **Pilot**           | Week 1–2 | IT admins (5–10 users)            | MFA enforced for pilot group |
| **Early adopters**  | Week 3–4 | IT staff + security (20–50 users) | MFA enforced for enrolled users |
| **General rollout** | Week 5–8 | All PAM users                     | MFA enforced for all users |
| **Enforcement**     | Week 9+  | All users                         | MFA required — no exceptions except break-glass |

### 8.5 Bulk Token Provisioning

```
On FortiAuthenticator Web UI:

1. Authentication > User Management > Remote Users
2. Filter: Show users without tokens
3. Select All (or select batch)
4. Actions > "Provision FortiToken Mobile"
5. Delivery: Email
6. Click "OK"

Monitor: Authentication > FortiToken > Token Status
- Total provisioned: should match PAM-MFA-Users count
- Activated: increases as users complete enrollment
- Pending: users who haven't activated yet -- follow up after 7 days
```

---

## 9. High Availability

### 9.1 FortiAuthenticator HA (Active-Passive)

```
Primary:    fortiauth.company.com     10.20.0.60
Secondary:  fortiauth-dr.company.com  10.20.0.61
```

**On FortiAuth PRIMARY (10.20.0.60):**

```bash
config system ha
  set mode active-passive
  set password [HA-sync-password]
  set peer-ip 10.20.0.61
  set peer-port 8009
  set sync-enable enable
  set sync-interval 60
end
```

**On FortiAuth SECONDARY (10.20.0.61):**

```bash
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
3. HA Password:   [same on both]
4. Peer IP:       10.20.0.61 (on primary) / 10.20.0.60 (on secondary)
5. Sync Objects:  [x] Users and tokens
                  [x] RADIUS clients and policies
                  [x] LDAP server configuration
6. Click "Apply"
```

**Verify HA sync:**

```bash
# On FortiAuth primary CLI:
diagnose ha status
# Expected: Peer Status: Connected, Last Sync: <timestamp within 5 minutes>

# Verify token count matches on both appliances:
# Primary  > Authentication > FortiToken > Summary
# Secondary > Authentication > FortiToken > Summary
# Token counts MUST match. Mismatch = sync broken.
```

> **Critical:** Without HA sync, the secondary FortiAuth has no users or tokens. RADIUS failover succeeds at the network level but fails at authentication — users get "authentication failed" during an outage. Verify sync before go-live.

### 9.2 Active Directory HA

WALLIX Bastion supports multiple LDAP servers per domain with automatic failover:

```bash
# Already configured in Phase 3 (Step 6.2):
# Server 1 (Priority 1): dc.company.com:636
# Server 2 (Priority 2): dc2.company.com:636
#
# Failover behavior:
# - Try servers in priority order
# - Connection timeout: 10 seconds per server
# - Failed server retry: 60 seconds
# - Health check: 30 seconds
```

### 9.3 WALLIX RADIUS Failover

```bash
# Already configured in Phase 3 (Step 6.5):
# Primary:   FortiAuth-Primary   (fortiauth.company.com / 10.20.0.60)
# Secondary: FortiAuth-Secondary (10.20.0.61)
# Failover timeout: 10 seconds
# Failback delay: 300 seconds (5 minutes)
```

### 9.4 HA Validation Test

```bash
# Test 1: AD failover
# Simulate DC1 outage (e.g., block port 636 to DC1)
wabadmin auth test --user "jadmin" --provider ldap --debug
# Expected: Failover to DC2, authentication succeeds (may take up to 10s)

# Test 2: FortiAuth failover
# Simulate FortiAuth primary outage (e.g., block port 1812 to 10.20.0.60)
wabadmin auth test --user "jadmin" --provider radius --debug
# Expected: Failover to secondary, MFA succeeds

# Test 3: Break-glass (both FortiAuth down)
# Block RADIUS to both 10.20.0.60 and 10.20.0.61
# Login as breakglass-admin with local password
# Expected: Login succeeds without MFA; alert sent
```

---

## 10. Operational Procedures

### 10.1 User Onboarding

```
ONBOARDING CHECKLIST -- New PAM User
====================================

[ ] 1. Create user account in Active Directory (or verify existing)
[ ] 2. Add user to PAM-MFA-Users group in AD
[ ] 3. Add user to appropriate role group (PAM-Admins, PAM-Operators, or PAM-Auditors)
[ ] 4. Wait 15 minutes for FortiAuth LDAP sync (or trigger manual sync)
[ ] 5. Provision FortiToken Mobile in FortiAuth (sends enrollment email)
[ ] 6. User installs FortiToken Mobile app and activates token
[ ] 7. Wait for next WALLIX LDAP sync (or trigger: wabadmin ldap sync --domain Corporate-AD)
[ ] 8. Verify login: wabadmin auth test --user "[username]" --provider radius
[ ] 9. Assign user to appropriate WALLIX target groups (if not handled by AD group mapping)
[ ] 10. Confirm user can access their assigned targets through WALLIX
```

### 10.2 User Offboarding

Complete these steps **in order**:

```
OFFBOARDING CHECKLIST -- Remove PAM User
=========================================

[ ] 1. Disable user account in Active Directory
       PowerShell: Disable-ADAccount -Identity "[username]"
       Effect: Blocks LDAP authentication immediately (Phase 1)

[ ] 2. Revoke FortiToken on FortiAuthenticator
       Web UI: User Management > Remote Users > [user] > Token > Revoke
       Effect: Releases FortiToken license back to pool

[ ] 3. Remove user from PAM groups in AD
       PowerShell: Remove-ADGroupMember -Identity "PAM-MFA-Users" -Members "[username]"
       Effect: User excluded from next FortiAuth sync

[ ] 4. Disable or delete user in WALLIX Bastion
       CLI: wabadmin user disable --login "[username]"
       Effect: Blocks any remaining session access

[ ] 5. Verify the user cannot authenticate
       CLI: wabadmin auth test --user "[username]" --provider radius
       Expected: "Authentication failed"

[ ] 6. Audit last sessions
       CLI: wabadmin audit search --user "[username]" --last 30d
       Review for any anomalous activity

[ ] 7. Document in access removal ticket
```

> **License impact:** FortiToken Mobile licenses are consumed per provisioned token, not per active user. Always revoke the token (Step 2) — disabling the AD account alone does NOT free the license.

### 10.3 Service Account Password Rotation

#### WALLIX Bind Account (svc_wallix)

```powershell
# Step 1: Change password in AD
Set-ADAccountPassword -Identity "svc_wallix" `
  -OldPassword (Read-Host -AsSecureString "Current password") `
  -NewPassword (Read-Host -AsSecureString "New password")
```

```bash
# Step 2: Update WALLIX Bastion configuration (ALL nodes)
wabadmin ldap update --domain "Corporate-AD" --bind-password "[new-password]"

# Step 3: Test
wabadmin ldap test "Corporate-AD"
# Expected: Connection successful
```

#### FortiAuth Sync Account (svc-fortiauth)

```powershell
# Step 1: Change password in AD
Set-ADAccountPassword -Identity "svc-fortiauth" `
  -OldPassword (Read-Host -AsSecureString "Current password") `
  -NewPassword (Read-Host -AsSecureString "New password")
```

```
# Step 2: Update FortiAuthenticator
# Web UI: Authentication > Remote Auth. Servers > LDAP > AD-Primary > Edit
# Update: Password field
# Click: Test > OK
```

#### RADIUS Shared Secret Rotation

```
RADIUS secret rotation requires coordinated changes on FortiAuth AND all WALLIX nodes.
Schedule during a maintenance window.

1. FortiAuth: Authentication > RADIUS Service > Clients
   Update shared secret on ALL 12 client entries

2. WALLIX: Update on ALL 10 Bastion nodes:
   wabadmin auth radius update --name "FortiAuth-Primary" --secret "[new-secret]"
   wabadmin auth radius update --name "FortiAuth-Secondary" --secret "[new-secret]"

3. Test from each node:
   wabadmin auth radius test "FortiAuth-Primary"
```

### 10.4 FortiToken Resynchronization

If a user's OTP codes are rejected (clock drift on device):

```
On FortiAuthenticator Web UI:

1. Authentication > User Management > Remote Users > [user]
2. Token > click "Resync"
3. Ask user for two consecutive OTP codes:
   Code 1: ______
   Code 2: ______
4. FortiAuth recalculates the time offset
5. User can authenticate again
```

### 10.5 MFA Bypass (Emergency)

```bash
# Temporary bypass for a specific user (time-limited)
wabadmin auth mfa bypass \
    --user "jadmin" \
    --duration 1h \
    --reason "FortiAuth maintenance window -- ticket INC-12345"

# Verify bypass is active
wabadmin auth mfa bypass --list

# Bypass expires automatically. To revoke early:
wabadmin auth mfa bypass --revoke --user "jadmin"

# Audit: review all bypass events
wabadmin audit search --type mfa-bypass --last 24h
```

---

## 11. Security Hardening

### 11.1 RADIUS Security

| Control                 | Implementation                                | Why |
|-------------------------|-----------------------------------------------|-----------------------------------------------|
| Strong shared secret    | 32+ characters, alphanumeric + symbols        | Prevents brute-force of RADIUS authentication |
| Limit RADIUS clients    | Only registered Bastion/AM IPs accepted       | Prevents rogue RADIUS clients |
| Enable accounting       | RADIUS accounting on port 1813                | Creates audit trail of all MFA events |
| Separate VLAN           | FortiAuth on shared infra VLAN (10.20.0.0/24) | Isolates authentication traffic |
| No RADIUS over internet | All traffic over MPLS/VPN                     | RADIUS uses MD5 — not safe over public networks |

### 11.2 LDAPS Security

| Control                | Implementation | Why |
|------------------------|---------------------------------------|---------------------------------|
| TLS 1.2+ only          | Disable TLS 1.0/1.1 on DCs and WALLIX | Prevents downgrade attacks |
| Certificate validation | Enable `verify_hostname` in WALLIX    | Prevents MITM attacks |
| Strong ciphers         | AES-256-GCM, CHACHA20-POLY1305        | Prevents weak cipher exploitation |
| Certificate monitoring | Alert 30 days before DC cert expiry   | Prevents surprise LDAPS outages |

### 11.3 FortiToken Security

```
1. Require PIN on FortiToken Mobile app
   FortiAuth > Authentication > FortiToken > Settings > [x] Require PIN

2. Enable biometric unlock (fingerprint / face)
   FortiAuth > Authentication > FortiToken > Settings > [x] Allow Biometric

3. Disable token backup to cloud
   FortiAuth > Authentication > FortiToken > Settings > [ ] Allow Cloud Backup
   Reason: prevents token cloning

4. Set token drift tolerance
   FortiAuth > Authentication > FortiToken > Settings
   Drift Tolerance: 1 interval (+/-30 seconds)
   Higher values reduce security, lower values cause false rejections

5. Enable push notification details
   FortiAuth > Authentication > FortiToken > Settings
   [x] Show source IP in push notification
   [x] Show service name in push notification
   Reason: helps users detect phishing attempts
```

### 11.4 Break-Glass Security

```
+=============================================================================+
|                    BREAK-GLASS ACCOUNT POLICY                               |
+=============================================================================+
|                                                                             |
|  Account:          breakglass-admin                                         |
|  Auth Type:        Local (NOT LDAP -- must work when AD is down)            |
|  MFA:              Exempt                                                   |
|  Profile:          administrator                                            |
|                                                                             |
|  CONTROLS:                                                                  |
|  =========                                                                  |
|  [ ] Password stored in physical safe or HSM (NOT in password manager)      |
|  [ ] Password complexity: 20+ characters, generated randomly                |
|  [ ] Password rotated quarterly                                             |
|  [ ] Access logged -- every login triggers email to security@company.com    |
|  [ ] Every use documented in incident ticket                                |
|  [ ] Dual-control: requires two people (one has username, one has password) |
|  [ ] Tested quarterly (verify it still works)                               |
|  [ ] Reviewed annually (is it still needed? should scope change?)           |
|                                                                             |
+=============================================================================+
```

---

## 12. Monitoring and Alerting

### 12.1 WALLIX Alerts

```bash
# Alert: MFA authentication failure spike
wabadmin alert create \
    --name "MFA-Failure-Spike" \
    --condition "mfa_failures > 5 in 5m" \
    --action email \
    --recipient security@company.com

# Alert: RADIUS server unreachable
wabadmin alert create \
    --name "RADIUS-Unreachable" \
    --condition "radius_server_status == down" \
    --action email,pagerduty \
    --recipient oncall@company.com

# Alert: MFA bypass used (always investigate)
wabadmin alert create \
    --name "MFA-Bypass-Used" \
    --condition "mfa_bypass_count > 0 in 1h" \
    --action email \
    --recipient security@company.com

# Alert: Break-glass account used
wabadmin alert create \
    --name "BreakGlass-Login" \
    --condition "login_user == breakglass-admin" \
    --action email \
    --recipient security@company.com

# Alert: LDAP sync failure
wabadmin alert create \
    --name "LDAP-Sync-Failure" \
    --condition "ldap_sync_status == failed" \
    --action email \
    --recipient pam-admin@company.com
```

### 12.2 Key Metrics to Monitor

| Metric | Alert Threshold | Response |
|--------|----------------|----------|
| `wallix_mfa_failures_total` | > 10 in 5 min | Investigate: attack or FortiAuth issue |
| `wallix_radius_latency_ms` | > 3000 ms avg | FortiAuth performance degradation |
| `wallix_radius_server_up` | == 0 | FortiAuth unreachable — activate break-glass |
| `wallix_mfa_bypass_total` | > 0 | Any bypass requires audit review |
| `wallix_ldap_sync_errors` | > 0 | LDAP sync broken — user changes not propagating |
| `wallix_token_expired_count` | > 5% of users | Mass token expiry — re-enrollment campaign |

### 12.3 FortiAuthenticator Monitoring

```bash
# FortiAuth CLI health checks:
diagnose system radius-server status    # RADIUS service health
diagnose ha status                      # HA sync status
diagnose system ntp status              # NTP sync (critical for OTP)
get system performance status           # CPU, memory, disk

# Web UI dashboards:
# Dashboard > Authentication Activity  -- login success/failure trends
# Dashboard > Token Status             -- provisioned, activated, pending
# Monitor > Logs > Authentication      -- real-time auth events
```

### 12.4 Daily Health Check Script

```bash
#!/bin/bash
# daily-2fa-healthcheck.sh -- run from any Bastion node

echo "=== 2FA HEALTH CHECK -- $(date) ==="
echo ""

echo "--- LDAP Connectivity ---"
wabadmin ldap test "Corporate-AD"

echo ""
echo "--- RADIUS Connectivity ---"
wabadmin auth radius test "FortiAuth-Primary"
wabadmin auth radius test "FortiAuth-Secondary"

echo ""
echo "--- MFA Status ---"
wabadmin auth mfa status

echo ""
echo "--- NTP Status ---"
chronyc tracking | head -5

echo ""
echo "--- LDAP Sync Status ---"
wabadmin ldap sync-status "Corporate-AD"

echo ""
echo "--- Recent MFA Failures (last 24h) ---"
wabadmin audit search --type mfa --status failed --last 24h | tail -10

echo ""
echo "--- MFA Bypasses (last 24h) ---"
wabadmin audit search --type mfa-bypass --last 24h

echo ""
echo "=== END HEALTH CHECK ==="
```

---

## 13. Troubleshooting

### 13.1 Diagnostic Decision Tree

```
+=============================================================================+
|                    2FA TROUBLESHOOTING -- DECISION TREE                     |
+=============================================================================+
|                                                                             |
|  USER CANNOT LOGIN                                                          |
|  =================                                                          |
|                                                                             |
|  Q: Does the user get a password prompt?                                    |
|  |                                                                          |
|  +-- NO  --> WALLIX Bastion unreachable                                     |
|  |           Check: DNS, network, WALLIX service, HAProxy                   |
|  |                                                                          |
|  +-- YES --> Does the password get accepted?                                |
|       |                                                                     |
|       +-- NO  --> LDAP ISSUE (Phase 1 fails)                                |
|       |           Check: AD account, password, LDAP config                  |
|       |           Jump to: Section 13.2                                     |
|       |                                                                     |
|       +-- YES --> Does the MFA prompt appear?                               |
|            |                                                                |
|            +-- NO  --> MFA not configured for this user/node                |
|            |           Check: MFA policy, user group, Bastion config        |
|            |           Jump to: Section 13.3                                |
|            |                                                                |
|            +-- YES --> Does MFA succeed?                                    |
|                 |                                                           |
|                 +-- NO  --> RADIUS/FORTIAUTH ISSUE (Phase 2 fails)          |
|                 |           Check: OTP, push, token, FortiAuth              |
|                 |           Jump to: Section 13.4                           |
|                 |                                                           |
|                 +-- YES --> USER CAN LOGIN -- issue is elsewhere            |
|                             Check: profile, targets, authorization          |
|                                                                             |
+=============================================================================+
```

### 13.2 LDAP Issues (Phase 1 Failures)

#### "Connection refused" or "Connection timed out"

```bash
# Test LDAPS connectivity
nc -zv dc.company.com 636
# If fails: firewall, DNS, or LDAPS not enabled on DC

# Test certificate
echo | openssl s_client -connect dc.company.com:636 2>/dev/null | \
  openssl x509 -noout -subject -dates
# If fails: certificate expired or mismatched

# Check WALLIX logs
grep -i "ldap" /var/log/wabengine/wabengine.log | tail -20
```

#### "Invalid credentials" or "Bind failed"

```bash
# Test service account bind manually
ldapsearch -x -H ldaps://dc.company.com:636 \
  -D "CN=svc_wallix,OU=Service Accounts,OU=PAM,DC=company,DC=com" \
  -W \
  -b "DC=company,DC=com" \
  "(objectClass=*)" -s base
# If fails: wrong password or account locked/disabled

# Check service account status in AD (PowerShell):
# Get-ADUser -Identity svc_wallix -Properties Enabled,LockedOut,PasswordExpired
```

#### "User not found"

```bash
# Search with the exact filter WALLIX uses
ldapsearch -x -H ldaps://dc.company.com:636 \
  -D "CN=svc_wallix,OU=Service Accounts,OU=PAM,DC=company,DC=com" \
  -W \
  -b "DC=company,DC=com" \
  "(&(objectClass=user)(sAMAccountName=jadmin))" dn
# If no results: user in different OU, wrong Base DN, or filter excludes them
```

### 13.3 MFA Not Triggering

```bash
# Verify MFA is enabled
wabadmin auth mfa status
# If disabled: re-enable with wabadmin auth mfa enable

# Verify RADIUS server configured
wabadmin auth radius show "FortiAuth-Primary"
# If missing: re-add per Phase 3 Step 6.5

# Verify user is not exempt
wabadmin auth mfa bypass --list | grep "jadmin"
# If listed: bypass is active -- wait for expiry or revoke
```

### 13.4 RADIUS/FortiAuth Issues (Phase 2 Failures)

#### "RADIUS server not responding"

```bash
# Test RADIUS port connectivity
nc -zvu fortiauth.company.com 1812
# If fails: firewall blocking UDP 1812

# Verify shared secret matches
wabadmin auth radius show "FortiAuth-Primary"
# Compare secret with FortiAuth > Authentication > RADIUS Service > Clients

# Check FortiAuth is running
# FortiAuth CLI: diagnose system radius-server status
```

#### "Invalid OTP"

```bash
# Check time synchronization -- most common cause of OTP rejection
chronyc tracking                          # On WALLIX Bastion
# FortiAuth CLI: diagnose system ntp status

# If clocks differ by > 30 seconds, fix NTP first

# Resync user's token on FortiAuth:
# Web UI: User Management > [user] > Token > Resync
# Requires two consecutive OTP codes from the user
```

#### "User not found in RADIUS"

```bash
# Verify user exists in FortiAuth
# FortiAuth Web UI: Authentication > User Management > Remote Users > Search

# If not found: trigger manual LDAP sync
# FortiAuth Web UI: Authentication > Remote User Sync > Sync Now

# Verify user is in PAM-MFA-Users AD group
# PowerShell: Get-ADGroupMember -Identity "PAM-MFA-Users" | Where Name -eq "jadmin"
```

#### "MFA timeout — no response"

```bash
# User didn't receive push notification:
# 1. Check phone has internet connectivity
# 2. Check FortiToken app is installed and token activated
# 3. Check push notification permissions on phone
# 4. Try manual OTP entry instead of push

# Increase timeout if network latency is high:
wabadmin auth mfa set-timeout 90
```

### 13.5 Debug Logging

```bash
# Enable RADIUS debug logging on WALLIX
wabadmin log level radius debug

# View real-time RADIUS logs
tail -f /var/log/wabengine/radius.log

# Test with full debug output
wabadmin auth test \
    --user "jadmin" \
    --provider radius \
    --debug

# IMPORTANT: Disable debug when done (verbose logging impacts performance)
wabadmin log level radius info
```

```bash
# FortiAuth debug logging:
diagnose debug application radiusd -1
diagnose debug enable

# Watch RADIUS events in real-time
# (disable when done):
diagnose debug disable
```

---

## 14. Compliance Mapping

FortiToken MFA with WALLIX Bastion satisfies multi-factor authentication requirements across major frameworks:

| Framework          | Control       | Requirement                    | How This Deployment Satisfies It |
|--------------------|---------------|--------------------------------|----------------------------------|
| **ISO 27001:2022** | A.8.5         | Secure authentication          | LDAP password + FortiToken OTP/push |
| **ISO 27001:2022** | A.5.15        | Access control                 | Group-based profile assignment from AD |
| **SOC 2 Type II**  | CC6.1         | Logical access controls        | MFA enforced for all privileged sessions |
| **SOC 2 Type II**  | CC6.7         | Restrict system components     | Possession factor prevents credential-only attacks |
| **NIS2 Directive** | Art. 21(2)(j) | Multi-factor authentication    | Strong auth for all remote and privileged access |
| **PCI-DSS v4**     | 8.4.2         | MFA for non-console admin      | FortiToken satisfies possession factor requirement |
| **GDPR**           | Art. 32       | Appropriate technical measures | MFA is a recognized technical control |
| **NIST 800-53**    | IA-2(1)       | MFA for privileged accounts    | Two distinct factors: knowledge + possession |

### Audit Evidence Collection

```bash
# MFA authentication report (last 90 days)
wabadmin report generate \
    --type mfa-audit \
    --from "$(date -d '90 days ago' +%Y-%m-%d)" \
    --to "$(date +%Y-%m-%d)" \
    --format pdf \
    --output /var/backup/audit/mfa-audit-$(date +%Y%m%d).pdf

# List all users with MFA enabled
wabadmin auth mfa user-list --status enabled

# List users WITHOUT MFA (each requires documented exception)
wabadmin auth mfa user-list --status disabled

# Export RADIUS accounting log
wabadmin audit export \
    --type radius-accounting \
    --last 90d \
    --output /var/backup/audit/radius-accounting-$(date +%Y%m%d).csv

# MFA stats by method
wabadmin audit stats --type mfa --group-by method --last 30d
```

---

## 15. Go-Live Checklist

```
+=============================================================================+
|                    PRODUCTION GO-LIVE CHECKLIST                             |
+=============================================================================+
|                                                                             |
|  PHASE 1: ACTIVE DIRECTORY                                                  |
|  [ ] Service accounts created and tested (svc_wallix, svc-fortiauth)        |
|  [ ] Service accounts hardened (no interactive logon, no delegation)        |
|  [ ] Security groups created (PAM-MFA-Users, PAM-Admins, etc.)              |
|  [ ] Users assigned to correct groups                                       |
|  [ ] LDAPS enabled on all Domain Controllers                                |
|  [ ] CA certificate exported and distributed                                |
|  [ ] LDAP bind test successful from all Bastion nodes                       |
|                                                                             |
|  PHASE 2: FORTIAUTHENTICATOR 300F                                           |
|  [ ] Firmware 6.4+ verified                                                 |
|  [ ] NTP synchronized (drift < 1 second)                                    |
|  [ ] SSL certificate installed                                              |
|  [ ] SMTP configured and tested                                             |
|  [ ] LDAP user sync configured and validated                                |
|  [ ] All 12 RADIUS clients registered                                       |
|  [ ] RADIUS policy: First Factor = None, Second Factor = FortiToken         |
|  [ ] RADIUS reply attributes configured                                     |
|  [ ] FortiTokens provisioned and activated for all users                    |
|  [ ] HA configured and sync verified (if applicable)                        |
|                                                                             |
|  PHASE 3: WALLIX BASTION                                                    |
|  [ ] CA certificate imported on ALL nodes                                   |
|  [ ] LDAP domain configured and tested on ALL nodes                         |
|  [ ] RADIUS servers configured on ALL nodes                                 |
|  [ ] MFA policy enabled (Web UI, SSH, RDP, API)                             |
|  [ ] Group-to-profile mappings configured                                   |
|  [ ] RADIUS Class attribute mappings configured                             |
|  [ ] Break-glass account created with alert                                 |
|                                                                             |
|  PHASE 4: END-TO-END TESTING                                                |
|  [ ] Web UI login with push notification -- PASSED                          |
|  [ ] Web UI login with manual OTP -- PASSED                                 |
|  [ ] SSH proxy login with MFA -- PASSED                                     |
|  [ ] RDP proxy login with MFA -- PASSED                                     |
|  [ ] Wrong password rejection (no MFA prompt) -- PASSED                     |
|  [ ] Wrong OTP rejection -- PASSED                                          |
|  [ ] Timeout handling -- PASSED                                             |
|  [ ] Disabled AD account rejection -- PASSED                                |
|  [ ] Break-glass login (no MFA + alert) -- PASSED                           |
|  [ ] Correct profile assignment from AD groups -- PASSED                    |
|  [ ] Test from ALL 10 Bastion nodes -- PASSED                               |
|  [ ] AD failover test -- PASSED                                             |
|  [ ] FortiAuth failover test -- PASSED                                      |
|                                                                             |
|  PHASE 5: ENROLLMENT                                                        |
|  [ ] All users enrolled and tokens activated                                |
|  [ ] User communication sent                                                |
|  [ ] Self-service portal configured (if applicable)                         |
|  [ ] Support team briefed on 2FA troubleshooting                            |
|                                                                             |
|  OPERATIONAL READINESS                                                      |
|  [ ] Monitoring alerts configured (MFA failures, RADIUS down, bypass used)  |
|  [ ] Daily health check script deployed                                     |
|  [ ] FortiAuth backup configured and tested                                 |
|  [ ] Password rotation schedule documented                                  |
|  [ ] Onboarding/offboarding procedures documented                           |
|  [ ] Break-glass password stored securely and tested                        |
|  [ ] Runbook reviewed by security team                                      |
|  [ ] Change ticket approved                                                 |
|                                                                             |
|  SIGN-OFF                                                                   |
|  [ ] IT Security Lead:     _______________  Date: ___________               |
|  [ ] PAM Administrator:    _______________  Date: ___________               |
|  [ ] Network Engineer:     _______________  Date: ___________               |
|  [ ] Change Manager:       _______________  Date: ___________               |
|                                                                             |
+=============================================================================+
```

---

## 16. Quick Reference Card

### Component Access

| Component | URL / Address | Port | Credentials |
|-----------|---------------|------|-------------|
| FortiAuth Primary Web UI | https://fortiauth.company.com | 443 | admin / [password in safe] |
| FortiAuth Secondary Web UI | https://fortiauth-dr.company.com | 443 | admin / [password in safe] |
| FortiAuth Self-Service | https://fortiauth.company.com/self-service | 443 | User AD credentials |
| WALLIX Admin UI | https://wallix.company.com/admin | 443 | [AD or local admin] |
| AD DC1 | dc.company.com | 636 (LDAPS) | svc_wallix / [password] |
| AD DC2 | dc2.company.com | 636 (LDAPS) | svc_wallix / [password] |

### Essential WALLIX CLI Commands

```bash
# LDAP
wabadmin ldap list                           # List configured LDAP domains
wabadmin ldap test "Corporate-AD"            # Test LDAP connectivity
wabadmin ldap search "Corporate-AD" "user"   # Search for user in AD
wabadmin ldap sync-status "Corporate-AD"     # Check sync status
wabadmin ldap sync --domain "Corporate-AD"   # Trigger manual sync

# RADIUS / MFA
wabadmin auth radius test "FortiAuth-Primary"     # Test RADIUS
wabadmin auth mfa status                          # Check MFA status
wabadmin auth test --user "user" --provider radius # Test full auth flow
wabadmin auth mfa bypass --user "user" --duration 1h --reason "ticket" # Emergency bypass
wabadmin auth mfa bypass --list                   # List active bypasses
wabadmin auth mfa bypass --revoke --user "user"   # Revoke bypass

# Audit
wabadmin audit search --type mfa --last 24h       # Recent MFA events
wabadmin audit search --type mfa-bypass --last 24h # Recent bypasses
wabadmin audit search --user "user" --last 7d      # User activity

# Debug
wabadmin log level radius debug              # Enable RADIUS debug logs
tail -f /var/log/wabengine/radius.log        # Watch RADIUS logs
wabadmin log level radius info               # Disable debug (always do this)
```

### FortiAuthenticator CLI Commands

```bash
get system status                            # Firmware version and serial
diagnose system ntp status                   # NTP sync status
diagnose system radius-server status         # RADIUS service health
diagnose ha status                           # HA sync status
diagnose debug application radiusd -1        # Enable RADIUS debug
diagnose debug enable                        # Start debug output
diagnose debug disable                       # Stop debug output
execute backup config sftp [server] [path] [password]  # Manual backup
```

### Network Connectivity Tests

```bash
# From WALLIX Bastion -- test LDAPS to AD
nc -zv dc.company.com 636

# From WALLIX Bastion -- test RADIUS to FortiAuth
nc -zvu fortiauth.company.com 1812

# From FortiAuth CLI -- test LDAPS to AD
execute ping 10.20.0.10

# Verify LDAPS certificate
echo | openssl s_client -connect dc.company.com:636 2>/dev/null | \
  openssl x509 -noout -subject -dates

# Full LDAP bind test
ldapsearch -x -H ldaps://dc.company.com:636 \
  -D "CN=svc_wallix,OU=Service Accounts,OU=PAM,DC=company,DC=com" \
  -W -b "DC=company,DC=com" "(sAMAccountName=jadmin)" dn
```

---

## Related Documentation

- [34 - LDAP/AD Integration](../34-ldap-ad-integration/README.md) — Detailed LDAP configuration and troubleshooting
- [06 - Authentication](../06-authentication/README.md) — Authentication methods overview
- [06 - FortiAuthenticator MFA](../06-authentication/fortiauthenticator-integration.md) — FortiAuth deep-dive
- [35 - Kerberos Authentication](../35-kerberos-authentication/README.md) — Optional SSO with Kerberos
- [13 - Troubleshooting](../13-troubleshooting/README.md) — General troubleshooting guide
- [30 - Backup & Restore](../30-backup-restore/fortiauthenticator-backup.md) — FortiAuth backup procedures

## External References

- [WALLIX Bastion Administration Guide](https://pam.wallix.one/documentation/admin-doc/bastion_en_administration_guide.pdf)
- [FortiAuthenticator Administration Guide](https://docs.fortinet.com/product/fortiauthenticator/)
- [FortiToken Mobile User Guide](https://docs.fortinet.com/product/fortitoken-mobile/)
- [Microsoft AD LDAP Reference](https://docs.microsoft.com/en-us/windows/win32/adsi/ldap-adsi-provider)
- [RFC 2865 — RADIUS Protocol](https://datatracker.ietf.org/doc/html/rfc2865)
- [RFC 6238 — TOTP Algorithm](https://datatracker.ietf.org/doc/html/rfc6238)

---

*Version 1.0 — 2026-04-10*
