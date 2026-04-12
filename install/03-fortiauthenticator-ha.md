# Per-Site FortiAuthenticator HA Pair Setup

> Deployment guide for the per-site FortiAuthenticator HA pair (Primary + Secondary) located in the Cyber VLAN at each of the 5 sites

---

## Document Information

| Property | Value |
|----------|-------|
| **Purpose** | Per-site FortiAuthenticator HA configuration |
| **Deployment Model** | 2 FortiAuthenticator appliances per site (Primary/Secondary) in Cyber VLAN |
| **Version** | FortiAuthenticator 6.4+ |
| **Prerequisites** | [01-network-design.md](01-network-design.md), [04-ad-per-site.md](04-ad-per-site.md) |
| **Last Updated** | April 2026 |

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Prerequisites and Planning](#prerequisites-and-planning)
3. [Installation](#installation)
4. [Primary FortiAuthenticator Configuration](#primary-fortiauthenticator-configuration)
5. [HA Pairing Configuration](#ha-pairing-configuration)
6. [RADIUS Server Configuration for WALLIX Bastion](#radius-server-configuration-for-wallix-bastion)
7. [AD/LDAP Connection Setup](#adldap-connection-setup)
8. [FortiToken Configuration](#fortitoken-configuration)
9. [Failover Testing](#failover-testing)
10. [Operational Procedures](#operational-procedures)

---

## Architecture Overview

Each of the 5 sites has its own independent FortiAuthenticator HA pair deployed in the **Cyber VLAN**. This is entirely separate from the DMZ VLAN that hosts the WALLIX Bastion appliances, HAProxy, and RDS.

```
+===============================================================================+
|  PER-SITE FORTIAUTHENTICATOR HA ARCHITECTURE                                  |
+===============================================================================+
|                                                                               |
|  DMZ VLAN (10.10.X.0/25)                                                      |
|  +-----------------------------------------------------------------------+    |
|  |  HAProxy VIP (10.10.X.100)                                            |    |
|  |  +------------------+  +------------------+  +------------------+    |    |
|  |  | HAProxy-1        |  | HAProxy-2        |  | WALLIX RDS       |    |    |
|  |  | 10.10.X.5        |  | 10.10.X.6        |  | 10.10.X.30       |    |    |
|  |  +------------------+  +------------------+  +------------------+    |    |
|  |  +------------------+  +------------------+                          |    |
|  |  | Bastion-1        |  | Bastion-2        |  RADIUS 1812/1813 UDP    |    |
|  |  | 10.10.X.11       |  | 10.10.X.12       |------>                   |    |
|  |  +------------------+  +------------------+       |                  |    |
|  +-----------------------------------------------------------------------+    |
|                                                       | Fortigate         |    |
|                                       Inter-VLAN routing (Fortigate)      |    |
|                                                       |                   |    |
|  Cyber VLAN (10.10.X.128/25)                          v                   |    |
|  +-----------------------------------------------------------------------+    |
|  |  +---------------------------+  +---------------------------+          |    |
|  |  | FortiAuthenticator-1     |  | FortiAuthenticator-2     |          |    |
|  |  | PRIMARY                  |  | SECONDARY                |          |    |
|  |  | 10.10.X.50               |  | 10.10.X.51               |          |    |
|  |  | VIP: 10.10.X.52          |  |                          |          |    |
|  |  +---------------------------+  +---------------------------+          |    |
|  |                  ^                            ^                        |    |
|  |                  | LDAP 389 TCP               | LDAP 389 TCP          |    |
|  |  +---------------------------+                                         |    |
|  |  | Active Directory DC      |                                         |    |
|  |  | 10.10.X.60               |                                         |    |
|  |  +---------------------------+                                         |    |
|  +-----------------------------------------------------------------------+    |
|                                                                               |
+===============================================================================+
```

### VLAN Assignment Summary (Per Site)

| VLAN | Subnet | Components |
|------|--------|------------|
| **DMZ VLAN** | 10.10.X.0/25 | HAProxy-1/2, Bastion-1/2, WALLIX RDS |
| **Cyber VLAN** | 10.10.X.128/25 | FortiAuthenticator-1/2, Active Directory |

Where `X` = site number (1-5).

### IP Addressing (Cyber VLAN, Per Site)

| Component | IP Address | Notes |
|-----------|------------|-------|
| FortiAuthenticator-1 (Primary) | 10.10.X.50 | Handles RADIUS requests normally |
| FortiAuthenticator-2 (Secondary) | 10.10.X.51 | Standby, auto-promotes on primary failure |
| FortiAuth VIP (Management) | 10.10.X.52 | Shared management VIP, floats to active node |
| Active Directory DC | 10.10.X.60 | See [04-ad-per-site.md](04-ad-per-site.md) |

### Inter-VLAN Traffic (via Fortigate)

| Source | Destination | Port | Protocol | Purpose |
|--------|-------------|------|----------|---------|
| Bastion (DMZ) | FortiAuth-1 (Cyber) | 1812 | UDP | RADIUS authentication |
| Bastion (DMZ) | FortiAuth-1 (Cyber) | 1813 | UDP | RADIUS accounting |
| Bastion (DMZ) | FortiAuth-2 (Cyber) | 1812 | UDP | RADIUS failover |
| Bastion (DMZ) | FortiAuth-2 (Cyber) | 1813 | UDP | RADIUS failover accounting |
| FortiAuth-1 (Cyber) | AD DC (Cyber) | 389 | TCP | LDAP user sync |
| FortiAuth-2 (Cyber) | AD DC (Cyber) | 389 | TCP | LDAP user sync (secondary) |
| FortiAuth-1 (Cyber) | AD DC (Cyber) | 636 | TCP | LDAPS (recommended) |
| FortiAuth-1 (Cyber) | FortiAuth-2 (Cyber) | 443 | TCP | HA replication/sync |

---

## Prerequisites and Planning

### Hardware Requirements

| Component | Specification | Notes |
|-----------|---------------|-------|
| **Model** | FortiAuthenticator 300F or VM | Sized for ~25 users per site |
| **CPU** | 4+ cores | Hardware or vCPU |
| **RAM** | 8+ GB | |
| **Disk** | 100+ GB | Logs, user database |
| **Network** | 2x 1 GbE NICs | Management + Cyber VLAN |
| **Quantity** | 2 per site | Primary + Secondary |

**Total across 5 sites**: 10 FortiAuthenticator instances (2 per site)

### Information Required Before Starting

Before deploying FortiAuthenticator at a site, confirm the following:

| Item | Source | Notes |
|------|--------|-------|
| Site number (X) | Network team | Determines IP scheme |
| Cyber VLAN ID | Network team | VLAN for Cyber segment |
| AD domain name | [04-ad-per-site.md](04-ad-per-site.md) | e.g., `company.local` |
| AD service account | AD team | For LDAP bind (read-only) |
| RADIUS shared secret | Security team | Used by WALLIX Bastion |
| FortiToken licenses | Fortinet | Quantity: ~25 per site + spare |
| FortiAuthenticator license | Fortinet | 300F or VM license |

### Pre-Deployment Checklist

```
+===============================================================================+
|  FORTIAUTHENTICATOR PRE-DEPLOYMENT CHECKLIST (Per Site)                       |
+===============================================================================+

Hardware / VM:
[ ] FortiAuthenticator-1 (Primary) provisioned in Cyber VLAN
[ ] FortiAuthenticator-2 (Secondary) provisioned in Cyber VLAN
[ ] IP addresses assigned: X.50 (primary), X.51 (secondary), X.52 (VIP)
[ ] Network connectivity from Cyber VLAN to DMZ VLAN verified (via Fortigate)
[ ] Connectivity from Cyber VLAN to AD DC (X.60) verified

Fortigate Inter-VLAN Rules:
[ ] Bastion (DMZ) → FortiAuth-1 (Cyber): 1812/1813 UDP ALLOWED
[ ] Bastion (DMZ) → FortiAuth-2 (Cyber): 1812/1813 UDP ALLOWED
[ ] FortiAuth (Cyber) → AD DC (Cyber): 389/636 TCP ALLOWED
[ ] FortiAuth-1 ↔ FortiAuth-2: 443 TCP ALLOWED (HA sync)

Licenses and Credentials:
[ ] FortiAuthenticator license file available
[ ] FortiToken Mobile licenses available (quantity: ~30 per site)
[ ] AD service account credentials available (read-only)
[ ] RADIUS shared secret defined for WALLIX Bastion

+===============================================================================+
```

---

## Installation

### FortiAuthenticator-1 (Primary)

**Access initial setup via console or browser (default IP: 192.168.1.99)**

#### Step 1: Basic Network Configuration

```
System > Network > Interfaces

port1 (Management):
  Mode: Static
  IP/Netmask: 10.10.X.50 / 255.255.255.128
  Default Gateway: 10.10.X.129   (Cyber VLAN gateway / Fortigate)
  Administrative Access: HTTPS, SSH

port2 (HA):
  Mode: Static
  IP/Netmask: 192.168.100.1 / 255.255.255.0   (dedicated HA link)
  Administrative Access: None
```

#### Step 2: Hostname and DNS

```
System > Administration > System Access

Hostname: fortiauthenticator1-siteX
DNS Primary: 10.10.X.60      (local AD/DNS)
DNS Secondary: <corporate DNS>
```

#### Step 3: Apply License

```
System > Administration > Licensing

Upload license file received from Fortinet.
Restart if prompted.
```

#### Step 4: Apply FortiToken Licenses

```
Authentication > FortiTokens > Licenses

Upload FortiToken Mobile license file.
Confirm token allocation (e.g., 30 tokens).
```

---

## Primary FortiAuthenticator Configuration

### System Time

```
System > Administration > System Time

NTP Server: 10.10.X.60   (AD can serve NTP) or site NTP server
Timezone: <site timezone>
Sync now to verify.
```

> Critical: All nodes (FortiAuth, Bastion, AD) must be NTP-synchronized. TOTP tokens have a 30-second window; clock drift causes authentication failures.

### Administrator Account

```
System > Administrators > Create New

Username: fortiadmin
Password: <strong password, vault-stored>
Profile: super_admin
Two-Factor Auth: Enabled (FortiToken)
```

---

## HA Pairing Configuration

FortiAuthenticator uses a Primary/Secondary HA model. The Primary handles all RADIUS requests; the Secondary stays synchronized and promotes automatically if the Primary is unreachable.

### On FortiAuthenticator-1 (Primary)

#### Step 1: Enable HA

```
System > High Availability

HA Status: Enable
Role: Master
Peer IP Address: 192.168.100.2     (HA link IP of Secondary)
HA Password: <shared HA secret>
Virtual IP (cluster): 10.10.X.52  (floats to active node)
```

#### Step 2: HA Interface

```
System > Network > HA Interface: port2 (192.168.100.1)
```

#### Step 3: Synchronization Settings

```
HA Sync: Enable all items:
  [x] Local users
  [x] RADIUS clients
  [x] Policies and rules
  [x] FortiToken data
  [x] LDAP configurations
  [x] Certificates
```

Apply and save. The Primary begins advertising to the Secondary.

### On FortiAuthenticator-2 (Secondary)

#### Step 1: Basic Network (Cyber VLAN)

```
port1: 10.10.X.51 / 255.255.255.128
Gateway: 10.10.X.129
port2 (HA): 192.168.100.2 / 255.255.255.0
```

#### Step 2: Enable HA as Secondary

```
System > High Availability

HA Status: Enable
Role: Slave
Peer IP Address: 192.168.100.1    (HA link IP of Primary)
HA Password: <same shared HA secret>
```

Apply. The Secondary connects to the Primary and performs initial full sync.

### Verify HA Status

On Primary:

```
System > High Availability > Status

  Master: FortiAuthenticator-1 (10.10.X.50) - ACTIVE
  Slave:  FortiAuthenticator-2 (10.10.X.51) - IN SYNC
  Cluster VIP: 10.10.X.52
  Last Sync: <timestamp>
  Sync State: Synchronized
```

Both appliances must show "Synchronized" before proceeding.

---

## RADIUS Server Configuration for WALLIX Bastion

Each WALLIX Bastion appliance is registered as a RADIUS client on FortiAuthenticator.

### Step 1: Create RADIUS Clients

```
Authentication > RADIUS Service > Clients > Create New

Client Name: wallix-bastion1-siteX
Client IP: 10.10.X.11
Secret: <shared RADIUS secret>
Description: WALLIX Bastion Node 1 - Site X

--- repeat for node 2 ---

Client Name: wallix-bastion2-siteX
Client IP: 10.10.X.12
Secret: <shared RADIUS secret>
Description: WALLIX Bastion Node 2 - Site X
```

> Use the same RADIUS shared secret for both nodes. Store it in the secrets vault. Configure the same secret on the Bastion side (see [07-bastion-active-active.md](07-bastion-active-active.md) or [08-bastion-active-passive.md](08-bastion-active-passive.md)).

### Step 2: RADIUS Policy

```
Authentication > RADIUS Service > Policies > Create New

Policy Name: bastion-mfa-siteX
RADIUS Clients: wallix-bastion1-siteX, wallix-bastion2-siteX
Authentication: AD + FortiToken (two-factor)
LDAP Source: AD-SiteX (configured in next section)
Token Type: FortiToken Mobile (TOTP)
Realm: company.local
```

### Step 3: RADIUS Attributes

Configure the following attributes to be returned on successful authentication:

```
Attribute: Reply-Message
Value: Authentication successful

Attribute: Class
Value: WALLIX_BASTION_USER
```

---

## AD/LDAP Connection Setup

Each FortiAuthenticator connects to the **local site's AD** (in the same Cyber VLAN).

### Step 1: Create LDAP Remote Authentication Server

```
Authentication > Remote Auth. Servers > LDAP > Create New

Name: AD-SiteX
Server: 10.10.X.60            (local AD in Cyber VLAN)
Port: 389 (or 636 for LDAPS)
Secure: LDAPS recommended
Base DN: DC=company,DC=local
Bind DN: CN=svc_fortiauth,OU=Service Accounts,DC=company,DC=local
Bind Password: <svc_fortiauth password>

User Object Class: user
Username Attribute: sAMAccountName
Group Object Class: group
```

Test the connection using the "Test Connectivity" button before saving.

### Step 2: Import AD Users (or Sync)

```
Authentication > User Management > Import Remote Users

Source: AD-SiteX
Search Base: OU=Privileged Users,DC=company,DC=local
Filter: (objectClass=user)
Action: Import + Keep synchronized
```

This imports the ~25 privileged users at each site into FortiAuthenticator's local database, enabling MFA enrollment.

### Step 3: MFA Enrollment Policy

```
Authentication > User Management > User Groups > Create New

Group: SiteX-Privileged-Users
Members: imported AD users
MFA Required: Yes
Token Type: FortiToken Mobile
Grace Period: 0 days (enforce immediately)
```

---

## FortiToken Configuration

### Assign FortiToken Mobile to Users

```
Authentication > FortiTokens > FortiToken Mobile > Assign

For each user in SiteX-Privileged-Users group:
  User: <username>
  Token: FortiToken Mobile (auto-provisioned via email or QR code)
  Status: Active
```

### Token Delivery Method

```
Authentication > FortiTokens > FortiToken Mobile > Settings

Delivery: Email activation link
Activation Timeout: 72 hours
Require HTTPS: Yes
OTP Algorithm: TOTP (Time-based, RFC 6238)
OTP Digits: 6
OTP Interval: 30 seconds
```

### Token Enrollment Process (Per User)

1. User receives activation email with link.
2. User installs FortiToken Mobile on smartphone.
3. User scans QR code or enters activation code.
4. User performs test authentication to verify token works.
5. IT confirms enrollment in FortiAuthenticator console.

---

## Failover Testing

Perform these tests after completing primary and HA configurations.

### Test 1: Verify Primary RADIUS Authentication

From a WALLIX Bastion node:

```bash
# Install radtest on Bastion (testing only)
apt-get install -y freeradius-utils

# Test RADIUS against Primary FortiAuth
radtest <username> <AD-password+OTP> 10.10.X.50 0 <radius-shared-secret>

# Expected output:
# Received Access-Accept
```

### Test 2: Verify Secondary RADIUS Authentication

```bash
# Test against Secondary FortiAuth directly
radtest <username> <AD-password+OTP> 10.10.X.51 0 <radius-shared-secret>

# Expected output:
# Received Access-Accept
```

### Test 3: HA Failover (Primary Shutdown)

```
+===============================================================================+
|  HA FAILOVER TEST PROCEDURE                                                   |
+===============================================================================+
|                                                                               |
|  Pre-condition: Both nodes synchronized, RADIUS working on both.              |
|                                                                               |
|  Step 1: On FortiAuthenticator-1 (Primary), power off or stop HA service.    |
|                                                                               |
|  Step 2: Wait ~30 seconds for Secondary to detect Primary failure.            |
|                                                                               |
|  Step 3: Verify Secondary promoted to Master:                                 |
|          - Check System > HA Status on FortiAuth-2                            |
|          - FortiAuth-2 should show: Role = Master                             |
|          - Cluster VIP (10.10.X.52) should be held by FortiAuth-2             |
|                                                                               |
|  Step 4: Test RADIUS from Bastion (should succeed via FortiAuth-2):           |
|          radtest <user> <pw+OTP> 10.10.X.51 0 <secret>                        |
|                                                                               |
|  Step 5: Restore FortiAuthenticator-1. Verify it rejoins as Slave.           |
|          - FortiAuth-1 should show: Role = Slave                              |
|          - Sync State: Synchronized                                           |
|                                                                               |
|  Pass Criteria: RADIUS auth succeeds within 60 seconds of Primary failure.   |
|                                                                               |
+===============================================================================+
```

### Test 4: Bastion-Side Failover Behavior

Configure WALLIX Bastion with both RADIUS servers (Primary + Secondary) so it retries the secondary automatically:

```bash
# On Bastion (wabadmin)
wabadmin auth configure \
  --method radius \
  --primary-server 10.10.X.50 \
  --secondary-server 10.10.X.51 \
  --shared-secret "RADIUS_SECRET" \
  --timeout 5 \
  --retry 2
```

Simulate Primary failure. Bastion should fail over to Secondary within the timeout period (5 seconds × 2 retries = ~10 seconds maximum).

---

## Operational Procedures

### Daily Health Check

```bash
# Verify HA sync status (on Primary)
# GUI: System > High Availability > Status
# CLI: diag sys ha status

# Expected:
# Master: FortiAuth-1 - ACTIVE
# Slave:  FortiAuth-2 - SYNCHRONIZED
```

### Token Management

```
# Revoke a lost token:
Authentication > FortiTokens > FortiToken Mobile > select token > Revoke

# Re-issue token (user gets new activation email):
Authentication > User Management > Users > select user > Re-assign Token
```

### Log Review

```
# Authentication logs:
Logging > Log Access > Authentication Events

# Filter by: date range, username, success/failure
# Export for SIEM: Logging > Remote Logging > Syslog (forward to SIEM)
```

### Syslog Integration

```
System > Logging > Remote Logging

Enable: Yes
Server: <SIEM IP>
Port: 514 (UDP) or 6514 (TCP+TLS)
Facility: local0
Level: Information
```

---

## Cross-References

| Topic | Document |
|-------|----------|
| Per-site AD/LDAP integration | [04-ad-per-site.md](04-ad-per-site.md) |
| Network design and VLAN layout | [01-network-design.md](01-network-design.md) |
| Bastion RADIUS configuration (Active-Active) | [07-bastion-active-active.md](07-bastion-active-active.md) |
| Bastion RADIUS configuration (Active-Passive) | [08-bastion-active-passive.md](08-bastion-active-passive.md) |
| FortiAuth HA failover scenario | [13-contingency-plan.md](13-contingency-plan.md) |
| Break glass when FortiAuth is down | [14-break-glass-procedures.md](14-break-glass-procedures.md) |
| Full site deployment order | [05-site-deployment.md](05-site-deployment.md) |
