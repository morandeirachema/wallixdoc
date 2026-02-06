# 04 - FortiAuthenticator MFA Setup

## Multi-Factor Authentication with FortiAuthenticator

This guide covers deploying and configuring FortiAuthenticator to provide MFA (RADIUS + TOTP/FortiToken Mobile) for WALLIX Bastion users.

---

## Architecture

```
+===============================================================================+
|                    FORTIAUTHENTICATOR MFA ARCHITECTURE                        |
+===============================================================================+
|                                                                               |
|  WALLIX Bastion Nodes            FortiAuthenticator           Active Directory|
|  =============                   ====================         ================|
|                                                                               |
|  +--------------+                +-----------------+          +-----------+   |
|  |WALLIXBastion1|----RADIUS----->| FortiAuth       |---LDAP-->|    AD     |   |
|  |10.10.1.11    |    (1812)      | 10.10.1.50      |  (389)   |10.10.0.10 |   |
|  +--------------+                |                 |          +-----------+   |
|                                  | MFA Validation: |                          |
|  +--------------+                | - LDAP Auth     |                          |
|  |WALLIXBastion2|----RADIUS----->| - TOTP/Token    |                          |
|  |10.10.1.12    |                | - Push Notify   |                          |
|  +--------------+                +-----------------+                          |
|                                       |                                       |
|                                       v                                       |
|                               +-----------------+                             |
|                               | FortiToken      |                             |
|                               | Mobile App      |                             |
|                               | (User's Phone)  |                             |
|                               +-----------------+                             |
|                                                                               |
+===============================================================================+
```

---

## Prerequisites

- FortiAuthenticator VM image (download from Fortinet Support Portal)
- Active Directory configured and accessible
- Network connectivity from WALLIX Bastion nodes to FortiAuth (port 1812/UDP)
- Users created in Active Directory

---

## Step 1: Deploy FortiAuthenticator VM

### VM Specifications

```
Hostname: fortiauth.lab.local
OS: FortiAuthenticator 6.5.x
vCPU: 2
RAM: 4 GB
Disk: 40 GB
Network: OT DMZ (10.10.1.0/24)
IP: 10.10.1.50/24
Gateway: 10.10.1.1
DNS: 10.10.0.10
```

### Initial Deployment

#### VMware vSphere/ESXi (Recommended)

**Download FortiAuthenticator OVA:**
- Visit: https://support.fortinet.com
- Navigate to: Downloads > FortiAuthenticator
- Download: FortiAuthenticator VM (OVA format) version 6.5.x or later

**Deploy OVA using vCenter:**

```
1. Log into vCenter Server (https://vcenter.company.com)
2. Navigate to VMs and Templates
3. Right-click datacenter/folder > Deploy OVF Template
4. Select local file: FortiAuthenticator_VM64.ovf

DEPLOYMENT WIZARD:
- Name: fortiauth
- Folder: WALLIX Bastion
- Compute Resource: Select cluster/host
- Review Details: Verify publisher (Fortinet)
- Storage: Select datastore
- Network Mapping:
  - Source Network: VM Network
  - Destination Network: WALLIX Bastion-OT-DMZ (VLAN 110)
- Customize template:
  - Admin Password: FortiAuth2026!
  - IP Address: 10.10.1.50
  - Netmask: 255.255.255.0
  - Gateway: 10.10.1.1
  - DNS: 10.10.0.10
- Power on after deployment: Yes

5. Click Finish and wait for deployment to complete
```

**Deploy OVA using govc CLI:**

```bash
# Set environment variables
export GOVC_URL=vcenter.company.com
export GOVC_USERNAME=administrator@vsphere.local
export GOVC_PASSWORD=YourPassword
export GOVC_INSECURE=true
export GOVC_DATACENTER=Datacenter1
export GOVC_DATASTORE=Datastore1
export GOVC_NETWORK="WALLIX Bastion-OT-DMZ"

# Import OVA
govc import.ova \
  -name=fortiauth \
  -ds=Datastore1 \
  -net="WALLIX Bastion-OT-DMZ" \
  -pool=/Datacenter1/host/Cluster1/Resources \
  FortiAuthenticator_VM64.ova

# Configure VM properties
govc vm.change -vm fortiauth -c 2 -m 4096

# Power on VM
govc vm.power -on fortiauth

# Wait for VM to boot
sleep 60

# Get IP address
govc vm.ip fortiauth
```

**Deploy OVA using PowerCLI:**

```powershell
# Connect to vCenter
Connect-VIServer -Server vcenter.company.com

# Import OVA
$ovfConfig = Get-OvfConfiguration -Ovf "C:\Downloads\FortiAuthenticator_VM64.ova"

# Configure network properties
$ovfConfig.NetworkMapping.VM_Network.Value = "WALLIX Bastion-OT-DMZ"
$ovfConfig.Common.ip0.Value = "10.10.1.50"
$ovfConfig.Common.netmask0.Value = "255.255.255.0"
$ovfConfig.Common.gateway.Value = "10.10.1.1"
$ovfConfig.Common.dns1.Value = "10.10.0.10"

# Deploy OVA
Import-VApp -Source "C:\Downloads\FortiAuthenticator_VM64.ova" `
  -OvfConfiguration $ovfConfig `
  -Name "fortiauth" `
  -VMHost (Get-Cluster "Cluster1" | Get-VMHost | Select-Object -First 1) `
  -Datastore "Datastore1" `
  -DiskStorageFormat Thin

# Start VM
Start-VM -VM "fortiauth"
```

#### Alternative: Proxmox (If VMware Not Available)

```bash
# NOTE: VMware vSphere/ESXi is the recommended platform
# Use Proxmox only if VMware is not available

# Download QCOW2 image from Fortinet Support Portal
# https://support.fortinet.com

# Deploy QCOW2 to Proxmox
qm create 150 --name fortiauth --memory 4096 --cores 2 \
  --net0 virtio,bridge=vmbr0,tag=110

# Import disk
qm importdisk 150 fortiauthenticator.qcow2 local-lvm

# Attach disk and configure boot
qm set 150 --scsi0 local-lvm:vm-150-disk-0
qm set 150 --boot c --bootdisk scsi0

# Start VM
qm start 150
```

---

## Step 2: Initial Configuration

### Console Access

```bash
# On first boot, login via console:
# Username: admin
# Password: (blank - will prompt to set)

# Set new admin password when prompted
New Password: FortiAuth2026!
Confirm: FortiAuth2026!
```

### Network Configuration

```bash
# Configure network via CLI
config system interface
    edit port1
        set mode static
        set ip 10.10.1.50/24
        set allowaccess ping https ssh
    next
end

config system dns
    set primary 10.10.0.10
    set secondary 8.8.8.8
end

config router static
    edit 1
        set device port1
        set gateway 10.10.1.1
    next
end

# Set hostname
config system global
    set hostname fortiauth
    set timezone "America/New_York"
end
```

### Web UI Access

Access FortiAuthenticator at: `https://10.10.1.50`

```
Username: admin
Password: FortiAuth2026!
```

---

## Step 3: Configure Active Directory Integration

### LDAP Server Configuration

**Navigate to: Authentication > LDAP**

Click **Create New** and configure:

```
+===============================================================================+
|  LDAP SERVER CONFIGURATION                                                    |
+===============================================================================+
|                                                                               |
|  GENERAL                                                                      |
|  -------                                                                      |
|  Name:                  LAB-AD                                                |
|  Server Name/IP:        dc-lab.lab.local                                      |
|  Port:                  389                                                   |
|  Common Name ID:        sAMAccountName                                        |
|  Distinguished Name:    DC=lab,DC=local                                       |
|                                                                               |
|  AUTHENTICATION                                                               |
|  --------------                                                               |
|  Bind Type:             Regular                                               |
|  Username:              CN=wallix-svc,OU=Service Accounts,OU=WALLIX Bastion,DC=lab,   |
|                         DC=local                                              |
|  Password:              WallixSvc123!                                         |
|                                                                               |
|  SEARCH OPTIONS                                                               |
|  --------------                                                               |
|  User Search Base:      OU=Users,OU=WALLIX Bastion,DC=lab,DC=local            |
|  Group Search Base:     OU=Groups,OU=WALLIX Bastion,DC=lab,DC=local           |
|                                                                               |
|  [x] Enable LDAP Server                                                       |
|                                                                               |
+===============================================================================+
```

### Test LDAP Connection

```
1. Click "Test User Credentials"
2. Enter test username: jadmin
3. Enter test password: JohnAdmin123!
4. Result: "Authentication successful"
```

---

## Step 4: Configure RADIUS Service

### RADIUS Server Settings

**Navigate to: Authentication > RADIUS Service > Clients**

Click **Create New**:

```
+===============================================================================+
|  RADIUS CLIENT CONFIGURATION - WALLIX Bastion NODE 1                          |
+===============================================================================+
|                                                                               |
|  Name:                  WALLIX Bastion-Node1                                  |
|  IP/Netmask:            10.10.1.11/32                                         |
|  Secret:                WallixRadius2026!                                     |
|  Authentication Type:   PAP                                                   |
|                                                                               |
+===============================================================================+
```

Click **Create New** again for Node 2:

```
+===============================================================================+
|  RADIUS CLIENT CONFIGURATION - WALLIX Bastion NODE 2                          |
+===============================================================================+
|                                                                               |
|  Name:                  WALLIX Bastion-Node2                                  |
|  IP/Netmask:            10.10.1.12/32                                         |
|  Secret:                WallixRadius2026!                                     |
|  Authentication Type:   PAP                                                   |
|                                                                               |
+===============================================================================+
```

### RADIUS Policy Configuration

**Navigate to: Authentication > RADIUS Service > Policies**

Click **Create New**:

```
+===============================================================================+
|  RADIUS POLICY CONFIGURATION                                                  |
+===============================================================================+
|                                                                               |
|  Name:                  WALLIX Bastion-MFA-Policy                             |
|  Authentication Method: Local user database or remote authentication          |
|                                                                               |
|  LDAP SETTINGS                                                                |
|  --------------                                                               |
|  LDAP Server:           LAB-AD                                                |
|  [x] Enable LDAP authentication                                               |
|                                                                               |
|  TWO-FACTOR AUTHENTICATION                                                    |
|  -------------------------                                                    |
|  [x] Require two-factor authentication                                        |
|  Token Type:            FortiToken Mobile                                     |
|                                                                               |
|  ACCOUNTING                                                                   |
|  ----------                                                                   |
|  [x] Enable RADIUS accounting                                                 |
|                                                                               |
+===============================================================================+
```

---

## Step 5: Import Users from Active Directory

### User Import

**Navigate to: Authentication > User Management > Local Users**

Click **Import > LDAP**:

```
+===============================================================================+
|  LDAP USER IMPORT                                                             |
+===============================================================================+
|                                                                               |
|  LDAP Server:           LAB-AD                                                |
|  Search Filter:         (objectClass=user)                                    |
|  Base DN:               OU=Users,OU=WALLIX Bastion,DC=lab,DC=local            |
|                                                                               |
|  USERS TO IMPORT:                                                             |
|  ----------------                                                             |
|  [x] jadmin (John Admin)                                                      |
|  [x] soperator (Sarah Operator)                                               |
|  [x] mauditor (Mike Auditor)                                                  |
|  [x] lnetwork (Lisa Network)                                                  |
|  [x] totengineer (Tom OT Engineer)                                            |
|                                                                               |
|  Import Settings:                                                             |
|  [x] Enable two-factor authentication for imported users                      |
|  [x] Send activation email                                                    |
|                                                                               |
+===============================================================================+
```

Click **Import**.

---

## Step 6: Configure FortiToken Mobile

### Enable FortiToken Mobile

**Navigate to: Authentication > FortiTokens > FortiToken Mobile**

```
+===============================================================================+
|  FORTITOKEN MOBILE CONFIGURATION                                              |
+===============================================================================+
|                                                                               |
|  [x] Enable FortiToken Mobile                                                 |
|                                                                               |
|  SETTINGS                                                                     |
|  --------                                                                     |
|  Token Lifetime:            60 seconds                                        |
|  Drift:                     1                                                 |
|  Length:                    6 digits                                          |
|                                                                               |
|  USER ACTIVATION                                                              |
|  ---------------                                                              |
|  [x] Allow users to self-activate tokens                                      |
|  [x] Send activation code via email                                           |
|  [x] Display QR code for manual activation                                    |
|                                                                               |
+===============================================================================+
```

### Generate Activation Codes for Users

**For each imported user:**

1. Navigate to: **Authentication > User Management > Local Users**
2. Click user (e.g., `jadmin`)
3. Click **Tokens** tab
4. Click **Send Activation Code**

```
Activation Method:
( ) Email
(x) Display QR Code

[Generate QR Code]
```

5. User scans QR code with **FortiToken Mobile app** (iOS/Android)

---

## Step 7: Test RADIUS Authentication

### Test from FortiAuthenticator

**Navigate to: Monitor > Authentication > RADIUS**

Click **Test Authentication**:

```
+===============================================================================+
|  RADIUS AUTHENTICATION TEST                                                   |
+===============================================================================+
|                                                                               |
|  Username:              jadmin                                                |
|  Password:              JohnAdmin123!                                         |
|  RADIUS Client:         WALLIX Bastion-Node1                                  |
|                                                                               |
|  [Test Authentication]                                                        |
|                                                                               |
|  RESULT:                                                                      |
|  -------                                                                      |
|  Status: Success (Access-Accept)                                              |
|  Authentication Method: LDAP + FortiToken Mobile                              |
|  User Groups: WALLIX Bastion-Admins, Linux-Admins, Windows-Admins             |
|                                                                               |
+===============================================================================+
```

### Test from WALLIX Bastion Node

```bash
# SSH to WALLIX Bastion node
ssh root@10.10.1.11

# Install RADIUS test client
apt install -y freeradius-utils

# Test RADIUS authentication
radtest jadmin "JohnAdmin123!123456" 10.10.1.50 0 WallixRadius2026!

# Expected output:
# Sent Access-Request Id 42 from 0.0.0.0:33456 to 10.10.1.50:1812 length 77
# Received Access-Accept Id 42 from 10.10.1.50:1812 to 0.0.0.0:33456 length 20

# Note: "123456" is the TOTP code from FortiToken Mobile app
```

---

## Authentication Flow

### User Login Process

```
+===============================================================================+
|  MFA AUTHENTICATION FLOW                                                      |
+===============================================================================+

1. User accesses WALLIX Bastion Web UI (https://10.10.1.100)

2. Login page prompts:
   Username: jadmin
   Password: JohnAdmin123!123456
            └─ AD Password ─┘└─ TOTP ─┘

3. WALLIX Bastion sends RADIUS Access-Request to FortiAuth (10.10.1.50:1812)
   - Username: jadmin
   - Password: JohnAdmin123!123456

4. FortiAuth validates:
   a. Splits password into AD password + TOTP code
   b. Validates AD password via LDAP (dc-lab:389)
   c. Validates TOTP code against FortiToken Mobile seed

5. FortiAuth returns RADIUS Access-Accept with user attributes:
   - User Groups: WALLIX Bastion-Admins, Linux-Admins
   - Session-Timeout: 28800 (8 hours)

6. WALLIX Bastion grants access based on RADIUS response

+===============================================================================+
```

---

## User Instructions

### Setting Up FortiToken Mobile

**Send to users:**

```
Subject: Set up Multi-Factor Authentication for WALLIX Bastion

Dear User,

To access WALLIX Bastion, you must configure two-factor authentication using FortiToken Mobile.

STEP 1: Install FortiToken Mobile App
  - iOS: https://apps.apple.com/app/fortitoken-mobile/id500007723
  - Android: https://play.google.com/store/apps/details?id=com.fortinet.android.ftm

STEP 2: Scan QR Code
  1. Open FortiToken Mobile app
  2. Tap "+" to add token
  3. Tap "Scan QR Code"
  4. Scan the QR code attached to this email

STEP 3: Login to WALLIX Bastion
  1. Go to https://wallix.lab.local
  2. Username: <your AD username>
  3. Password: <your AD password><6-digit code from app>
     Example: If your AD password is "MyPass123!" and FortiToken shows "456789"
              Enter: MyPass123!456789

Need help? Contact IT Support.
```

---

## Monitoring and Logging

### View Authentication Logs

**Navigate to: Monitor > Authentication > RADIUS**

```
+===================================================================================+
| Time       | User       | Client                | Result        | Reason          |
+===================================================================================+
| 10:23:45   | jadmin     | WALLIX Bastion-Node1  | Success       | LDAP + Token OK |
| 10:22:13   | soperator  | WALLIX Bastion-Node2  | Success       | LDAP + Token OK |
| 10:20:05   | totengineer| WALLIX Bastion-Node1  | Failed        | Invalid token   |
| 10:18:32   | lnetwork   | WALLIX Bastion-Node2  | Success       | LDAP + Token OK |
+===================================================================================+
```

### Enable Syslog Forwarding

**Navigate to: System > Log Settings > Remote Logging**

```
+===============================================================================+
|  SYSLOG CONFIGURATION                                                         |
+===============================================================================+
|                                                                               |
|  [x] Enable syslog                                                            |
|                                                                               |
|  Server 1:              10.10.0.50 (siem-lab)                                 |
|  Port:                  514                                                   |
|  Protocol:              UDP                                                   |
|  Facility:              local7                                                |
|                                                                               |
|  Log Level:             Informational                                         |
|                                                                               |
|  [x] Log all authentication events                                            |
|  [x] Log RADIUS accounting                                                    |
|                                                                               |
+===============================================================================+
```

---

## Troubleshooting

### Issue: RADIUS authentication fails

```bash
# On FortiAuthenticator, check logs:
diagnose debug application radiusd -1
diagnose debug enable

# Check RADIUS client configuration
get authentication radius policy

# Verify LDAP connectivity
execute ldap-server test LAB-AD

# Check user token status
diagnose fortitoken-mobile list
```

### Issue: TOTP code not accepted

```
Common causes:
1. Time drift between FortiAuth and mobile device
   - Solution: Ensure both are NTP-synced

2. Wrong token seed
   - Solution: Re-activate token by scanning new QR code

3. Token expired
   - Solution: Check token lifetime (default 60 seconds)
```

### Issue: User not found

```bash
# Verify user imported from LDAP
execute ldap-user search LAB-AD jadmin

# Re-import user if needed
Authentication > User Management > Local Users > Import > LDAP
```

---

## Security Best Practices

### 1. Token Configuration

```
- Token lifetime: 60 seconds (balance security vs. usability)
- Token length: 6 digits minimum
- Drift tolerance: 1 (allow ±30 seconds for time sync issues)
```

### 2. RADIUS Client Restrictions

```
- Use unique RADIUS secrets for each client
- Restrict by IP address (/32 netmask)
- Enable RADIUS accounting for audit trail
```

### 3. User Management

```
- Enforce MFA for all privileged users
- Disable MFA for service accounts (use separate auth method)
- Regular token re-activation (annually)
```

### 4. Monitoring

```
- Monitor failed authentication attempts
- Alert on multiple failed MFA attempts (potential brute force)
- Log all RADIUS Access-Accept/Reject events
```

---

## Configuration Backup

### Backup FortiAuthenticator Config

**Navigate to: System > Maintenance > Backup**

```
Backup Type: Configuration + User Database
Encryption: Yes
Password: FortiAuthBackup2026!

[Download Backup]

Save to: /secure/backups/fortiauth-backup-<date>.tgz
```

### Restore from Backup

**Navigate to: System > Maintenance > Restore**

```
Upload backup file: fortiauth-backup-<date>.tgz
Encryption Password: FortiAuthBackup2026!

[Restore]
```

---

## Quick Reference

### FortiAuthenticator Details

| Component | Value |
|-----------|-------|
| **Hostname** | fortiauth.lab.local |
| **IP Address** | 10.10.1.50/24 |
| **Admin URL** | https://10.10.1.50 |
| **Admin User** | admin |
| **Admin Pass** | FortiAuth2026! |

### RADIUS Configuration

| Setting | Value |
|---------|-------|
| **RADIUS Port** | 1812 (UDP) |
| **RADIUS Secret** | WallixRadius2026! |
| **Auth Type** | PAP |
| **LDAP Server** | dc-lab.lab.local:389 |

### TOTP Settings

| Setting | Value |
|---------|-------|
| **Token Lifetime** | 60 seconds |
| **Token Length** | 6 digits |
| **Drift Tolerance** | ±1 interval |

---

## Verification Checklist

| Check | Status |
|-------|--------|
| FortiAuth accessible via HTTPS | [ ] |
| LDAP connection to AD successful | [ ] |
| RADIUS clients configured for WALLIX Bastion nodes | [ ] |
| Users imported from AD | [ ] |
| FortiToken Mobile tokens activated | [ ] |
| Test RADIUS authentication successful | [ ] |
| Syslog forwarding configured | [ ] |
| Configuration backup created | [ ] |

---

<p align="center">
  <a href="./03-haproxy-setup.md">← Previous: HAProxy Setup</a> •
  <a href="./05-wallix-rds-setup.md">Next: WALLIX RDS Setup →</a>
</p>
