# WALLIX RDS Jump Host Setup for OT RemoteApp Access

> Configuration guide for WALLIX RDS servers providing secure RemoteApp access to OT systems (industrial control, SCADA)

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Hardware and Software Requirements](#hardware-and-software-requirements)
4. [Windows Server 2022 Installation](#windows-server-2022-installation)
5. [WALLIX RDS Installation](#wallix-rds-installation)
6. [RemoteApp Configuration](#remoteapp-configuration)
7. [Integration with WALLIX Bastion](#integration-with-wallix-bastion)
8. [OT Target Configuration](#ot-target-configuration)
9. [Security Hardening](#security-hardening)
10. [Session Recording](#session-recording)
11. [Testing Procedures](#testing-procedures)
12. [Troubleshooting](#troubleshooting)

---

## Overview

### Purpose

WALLIX RDS (Remote Desktop Service) provides a secure jump host for accessing OT (Operational Technology) systems through RemoteApp sessions. This architecture provides:

- **Additional isolation layer** for critical OT infrastructure
- **RDP-only access** via RemoteApp (no direct SSH/RDP to OT targets)
- **Full session recording** with OCR and keystroke logging
- **Centralized credential management** for OT accounts

### Deployment Model

| Parameter | Value |
|-----------|-------|
| **Deployment per Site** | 1 WALLIX RDS server |
| **Total Deployment** | 5 RDS servers (1 per site) |
| **Operating System** | Windows Server 2022 |
| **Access Method** | RemoteApp via RDP |
| **Target Systems** | OT workstations, ICS, SCADA |

### Why Jump Host for OT?

OT systems require additional security controls:

| Requirement | Solution |
|-------------|----------|
| **Network Segregation** | RDS in DMZ, no direct OT network access from user endpoints |
| **Protocol Restriction** | RDP-only, no SSH/Telnet/proprietary protocols |
| **Session Isolation** | Each user gets isolated RemoteApp session |
| **Audit Trail** | Full session recording mandatory for compliance |
| **Zero Trust** | Users never touch OT network directly |

---

## Architecture

### Single Site Architecture

```
+===============================================================================+
|  WALLIX RDS ARCHITECTURE - SINGLE SITE                                        |
+===============================================================================+
|                                                                               |
|  End User Workstation                                                         |
|         |                                                                     |
|         | RDP (3389/tcp)                                                      |
|         v                                                                     |
|  +------+------+        +------+------+                                       |
|  | HAProxy-1   |  VRRP  | HAProxy-2   |  Load Balancer HA Pair                |
|  | (Active)    |<------>| (Passive)   |  VIP: 10.10.X.100                     |
|  +------+------+        +------+------+                                       |
|         |                      |                                              |
|         +----------+-----------+                                              |
|                    | RDP (3389/tcp)                                           |
|                    v                                                          |
|         +----------+----------+       +----------+----------+                 |
|         | WALLIX Bastion-1    |  HA   | WALLIX Bastion-2    |  Active-Active  |
|         | - Auth & Recording  |<----->| - Auth & Recording  |  Cluster        |
|         | - Credential Vault  |       | - Credential Vault  |                 |
|         +----------+----------+       +----------+----------+                 |
|                    |                             |                            |
|                    +-------------+---------------+                            |
|                                  | RDP Proxied (via Bastion)                  |
|                                  v                                            |
|                    +-------------+--------------+                             |
|                    |      WALLIX RDS            |  Windows Server 2022        |
|                    |      10.10.X.30            |  - RemoteApp Host           |
|                    |      - RDP RemoteApp       |  - Session Recording        |
|                    |      - OCR & Keystroke Log |  - Isolated Environment     |
|                    +-------------+--------------+                             |
|                                  |                                            |
|                    +-------------+--------------+                             |
|                    | RDP to OT Targets          |  Via RemoteApp Only         |
|                    v                            |                             |
|  +----------------+----------------+-------------+-------------+              |
|  |                |                |             |             |              |
|  v                v                v             v             v              |
|  +---------+  +---------+  +---------+  +---------+  +---------+              |
|  | SCADA   |  | ICS     |  | HMI     |  | PLC     |  | OT      |  OT Systems  |
|  | System  |  | Server  |  | Panel   |  | Gateway |  | Workst. |              |
|  +---------+  +---------+  +---------+  +---------+  +---------+              |
|                                                                               |
+===============================================================================+
```

### Multi-Site Deployment

```
+===============================================================================+
|  5-SITE WALLIX RDS DEPLOYMENT                                                 |
+===============================================================================+
|                                                                               |
|  Site 1 (DC-1)          Site 2 (DC-2)          Site 3 (DC-3)                  |
|  +--------------+        +--------------+        +--------------+             |
|  | WALLIX RDS   |        | WALLIX RDS   |        | WALLIX RDS   |             |
|  | 10.10.1.30   |        | 10.10.2.30   |        | 10.10.3.30   |             |
|  +--------------+        +--------------+        +--------------+             |
|         |                       |                       |                     |
|         v                       v                       v                     |
|  OT Targets (Site 1)    OT Targets (Site 2)    OT Targets (Site 3)            |
|                                                                               |
|  Site 4 (DC-4)          Site 5 (DC-5)                                         |
|  +--------------+        +--------------+                                     |
|  | WALLIX RDS   |        | WALLIX RDS   |                                     |
|  | 10.10.4.30   |        | 10.10.5.30   |                                     |
|  +--------------+        +--------------+                                     |
|         |                       |                                             |
|         v                       v                                             |
|  OT Targets (Site 4)    OT Targets (Site 5)                                   |
|                                                                               |
|  NOTE: Each RDS server is site-local, NO cross-site RDS access                |
|                                                                               |
+===============================================================================+
```

### Access Flow

```
+===============================================================================+
|  OT ACCESS FLOW - FROM USER TO SCADA SYSTEM                                   |
+===============================================================================+
|                                                                               |
|  Step 1: User Authentication                                                  |
|  +-----------+    HTTPS (443)    +---------------+                            |
|  | End User  | -----------------> | WALLIX Bastion | MFA + LDAP/AD            |
|  +-----------+                    +-------+-------+                           |
|                                           |                                   |
|  Step 2: Session Request                  v                                   |
|                            +---------------+----------------+                 |
|                            | Credential Vault               |                 |
|                            | - OT account auto-checkout     |                 |
|                            +---------------+----------------+                 |
|                                           |                                   |
|  Step 3: RDP Proxy to RDS                 v                                   |
|                            +---------------+----------------+                 |
|                            | WALLIX RDS (RemoteApp)         |                 |
|                            | - User gets isolated session   |                 |
|                            | - RDP client appears on screen |                 |
|                            +---------------+----------------+                 |
|                                           |                                   |
|  Step 4: RemoteApp Launch                 v                                   |
|                            +---------------+----------------+                 |
|                            | Remote Desktop Connection      |                 |
|                            | (mstsc.exe as RemoteApp)       |                 |
|                            +---------------+----------------+                 |
|                                           |                                   |
|  Step 5: OT Target Access                 v                                   |
|                            +---------------+----------------+                 |
|                            | SCADA / ICS / OT System        |                 |
|                            | - Session fully recorded       |                 |
|                            | - OCR + keystroke logging      |                 |
|                            +--------------------------------+                 |
|                                                                               |
|  Recording Points:                                                            |
|  - WALLIX Bastion: Records RDP to RDS (user -> RemoteApp)                     |
|  - WALLIX RDS: Records RemoteApp to OT target (RDS -> SCADA)                  |
|                                                                               |
+===============================================================================+
```

---

## Hardware and Software Requirements

### Per-Site RDS Server

| Component | Specification | Notes |
|-----------|---------------|-------|
| **CPU** | 4 vCPU | Intel Xeon or equivalent |
| **RAM** | 8 GB | 16 GB for > 20 concurrent users |
| **Disk** | 100 GB SSD | Includes OS + RDS software |
| **Network** | 1 GbE | Dedicated NIC recommended |
| **OS** | Windows Server 2022 Standard | Desktop Experience required |

### Software Requirements

| Component | Version | License Required |
|-----------|---------|------------------|
| **Windows Server 2022** | Standard or Datacenter | Yes (per server) |
| **Remote Desktop Services** | Included in WS2022 | RDS CAL required per user |
| **WALLIX RDS Agent** | 12.1.x | Included with Bastion license |
| **.NET Framework** | 4.8+ | Included in WS2022 |
| **PowerShell** | 5.1+ | Included in WS2022 |

### Licensing Breakdown

| License | Quantity per Site | Total (5 Sites) |
|---------|-------------------|-----------------|
| **Windows Server 2022** | 1 | 5 |
| **RDS CAL (Device)** | 1 per concurrent user | Calculate per site |
| **WALLIX RDS License** | Included in Bastion pool | N/A |

**Example**: Site 1 has 50 OT users → 50 RDS Device CALs required

---

## Windows Server 2022 Installation

### Pre-Installation Checklist

- [ ] Windows Server 2022 ISO downloaded (build 20348 or newer)
- [ ] Server hostname decided (e.g., `rds-site1.domain.local`)
- [ ] Static IP address assigned (e.g., `10.10.1.30`)
- [ ] DNS and NTP servers configured
- [ ] Domain credentials available (if joining AD domain)

### Installation Steps

#### Step 1: Install Windows Server 2022

```powershell
# Boot from ISO and select:
# - Windows Server 2022 Standard (Desktop Experience)
# - Custom installation
# - Create single partition for OS

# After first boot, set Administrator password
# Password complexity: min 12 characters, uppercase, lowercase, digit, special
```

#### Step 2: Configure Network

```powershell
# Set static IP address
New-NetIPAddress -InterfaceAlias "Ethernet" `
  -IPAddress 10.10.1.30 `
  -PrefixLength 24 `
  -DefaultGateway 10.10.1.1

# Set DNS servers
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" `
  -ServerAddresses 10.10.0.10,10.10.0.11

# Set hostname
Rename-Computer -NewName "rds-site1" -Restart
```

#### Step 3: Join Active Directory Domain (Optional)

```powershell
# Join domain for centralized user management
Add-Computer -DomainName "corp.domain.local" `
  -Credential (Get-Credential) `
  -Restart

# After restart, verify domain membership
(Get-WmiObject Win32_ComputerSystem).Domain
# Expected: corp.domain.local
```

#### Step 4: Windows Updates

```powershell
# Install all critical updates
Install-Module PSWindowsUpdate -Force
Get-WindowsUpdate -Install -AcceptAll -AutoReboot

# Verify no pending updates
Get-WindowsUpdate
```

#### Step 5: Disable Unnecessary Services

```powershell
# Disable services not needed for RDS
$services = @(
  'DiagTrack',      # Telemetry
  'dmwappushservice', # WAP Push
  'WSearch',        # Windows Search (optional)
  'SysMain'         # Superfetch
)

foreach ($svc in $services) {
  Set-Service -Name $svc -StartupType Disabled
  Stop-Service -Name $svc -ErrorAction SilentlyContinue
}
```

---

## WALLIX RDS Installation

### Pre-Installation Steps

#### Step 1: Download WALLIX RDS Installer

Contact WALLIX support or download from customer portal:

```
https://pam.wallix.one/downloads/rds/
Filename: wallix-rds-12.1.x-win64.msi
```

#### Step 2: Prerequisites Check

```powershell
# Verify .NET Framework 4.8+
Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\' | Get-ItemProperty -Name Version

# Expected: Version 4.8.xxxxx
```

#### Step 3: Firewall Rules

```powershell
# Allow RDP (3389) from Bastion appliances only
New-NetFirewallRule -DisplayName "WALLIX Bastion RDP Access" `
  -Direction Inbound -Protocol TCP -LocalPort 3389 `
  -RemoteAddress 10.10.1.11,10.10.1.12 `
  -Action Allow

# Block RDP from all other sources
Set-NetFirewallRule -DisplayName "Remote Desktop*" -Enabled False
```

### Installation Process

#### Step 1: Run WALLIX RDS Installer

```powershell
# Silent installation
msiexec /i wallix-rds-12.1.x-win64.msi /qn /L*v wallix-rds-install.log

# Interactive installation (recommended for first-time setup)
.\wallix-rds-12.1.x-win64.msi
```

**Installation Wizard Options**:

| Option | Value |
|--------|-------|
| **Installation Directory** | `C:\Program Files\WALLIX\RDS` |
| **Service Account** | `NT AUTHORITY\SYSTEM` (default) |
| **WALLIX Bastion IP** | `10.10.1.11,10.10.1.12` (both cluster nodes) |
| **RDS Role** | RemoteApp Server |

#### Step 2: Verify Installation

```powershell
# Check WALLIX RDS service
Get-Service -Name "WALLIXRDSService"
# Expected: Running, Automatic startup

# Verify installed version
Get-ItemProperty HKLM:\Software\WALLIX\RDS | Select-Object Version
# Expected: 12.1.x
```

#### Step 3: Configure Connection to Bastion

Edit `C:\Program Files\WALLIX\RDS\config\bastion.conf`:

```ini
[bastion]
# Primary Bastion node
primary_host=10.10.1.11
primary_port=443
primary_cert_verify=true

# Secondary Bastion node (HA)
secondary_host=10.10.1.12
secondary_port=443
secondary_cert_verify=true

# Shared secret (obtain from WALLIX Bastion)
shared_secret=<REDACTED - obtain from wabadmin>

# Session recording settings
recording_enabled=true
recording_path=C:\WALLIXRecordings

# OCR settings
ocr_enabled=true
ocr_language=en-US

# Logging
log_level=INFO
log_path=C:\Program Files\WALLIX\RDS\logs
```

#### Step 4: Restart WALLIX RDS Service

```powershell
Restart-Service -Name "WALLIXRDSService"

# Verify connection to Bastion
Test-NetConnection -ComputerName 10.10.1.11 -Port 443
Test-NetConnection -ComputerName 10.10.1.12 -Port 443
```

---

## RemoteApp Configuration

### Overview

RemoteApp allows publishing specific applications (e.g., Remote Desktop Connection) without providing full desktop access.

### Step 1: Install Remote Desktop Session Host Role

```powershell
# Install RDS Session Host role
Install-WindowsFeature -Name RDS-RD-Server -IncludeManagementTools -Restart

# After restart, verify role installation
Get-WindowsFeature -Name RDS-RD-Server
# Expected: Installed
```

### Step 2: Configure RemoteApp Programs

```powershell
# Import RemoteApp PowerShell module
Import-Module RemoteDesktop

# Publish Remote Desktop Connection (mstsc.exe) as RemoteApp
New-RDRemoteApp -CollectionName "OT Access" `
  -DisplayName "OT Remote Desktop" `
  -FilePath "C:\Windows\System32\mstsc.exe" `
  -Alias "ot-rdp" `
  -ShowInWebAccess $true

# Verify RemoteApp published
Get-RDRemoteApp -CollectionName "OT Access"
```

### Step 3: Configure Session Collection

```powershell
# Create RDS Session Collection
New-RDSessionCollection -CollectionName "OT Access" `
  -SessionHost "rds-site1.domain.local" `
  -Description "Secure access to OT systems via RemoteApp"

# Configure session timeout
Set-RDSessionCollectionConfiguration -CollectionName "OT Access" `
  -MaxIdleTimeMin 30 `
  -BrokenConnectionAction Disconnect `
  -MaxDisconnectionTimeMin 60
```

### Step 4: Configure User Access

```powershell
# Grant AD group access to RemoteApp
$users = @("DOMAIN\OT-Operators", "DOMAIN\OT-Engineers")

foreach ($user in $users) {
  Add-RDSessionHost -CollectionName "OT Access" `
    -SessionHost "rds-site1.domain.local" `
    -UserGroup $user
}

# Verify user groups
Get-RDSessionCollectionConfiguration -CollectionName "OT Access" | Select-Object UserGroup
```

### Step 5: Configure RemoteApp RDP Parameters

```powershell
# Create RDP file template for OT access
$rdpContent = @"
use multimon:i:0
screen mode id:i:2
desktopwidth:i:1920
desktopheight:i:1080
session bpp:i:32
compression:i:1
keyboardhook:i:2
audiocapturemode:i:0
videoplaybackmode:i:1
connection type:i:7
networkautodetect:i:1
bandwidthautodetect:i:1
displayconnectionbar:i:1
enableworkspacereconnect:i:0
disable wallpaper:i:0
allow font smoothing:i:1
allow desktop composition:i:1
disable full window drag:i:0
disable menu anims:i:0
disable themes:i:0
disable cursor setting:i:0
bitmapcachepersistenable:i:1
autoreconnection enabled:i:1
authentication level:i:2
prompt for credentials:i:0
negotiate security layer:i:1
remoteapplicationmode:i:1
alternate shell:s:rdpinit.exe
remoteapplicationprogram:s:mstsc
remoteapplicationname:s:OT Remote Desktop
remoteapplicationcmdline:s:
"@

$rdpContent | Out-File -FilePath "C:\RemoteApp\ot-access.rdp" -Encoding ASCII
```

---

## Integration with WALLIX Bastion

### On WALLIX Bastion Appliance

#### Step 1: Register WALLIX RDS Server

```bash
# SSH to Bastion appliance
ssh admin@10.10.1.11

# Register RDS server
wabadmin rds add \
  --name "rds-site1" \
  --host "10.10.1.30" \
  --port 3389 \
  --type "windows2022" \
  --description "Site 1 OT Jump Host"

# Generate shared secret
wabadmin rds generate-secret --name "rds-site1"
# Copy output to RDS bastion.conf file
```

#### Step 2: Create RDS Device in Bastion

```bash
# Add RDS as a device
wabadmin device add \
  --name "rds-site1-ot" \
  --host "10.10.1.30" \
  --description "Site 1 OT RemoteApp Access" \
  --device-type "rds"

# Add RDP service
wabadmin service add \
  --device "rds-site1-ot" \
  --service-type "rdp" \
  --port 3389 \
  --protocol "rdp"
```

#### Step 3: Create Credential Vault for OT Accounts

```bash
# Create domain for OT accounts
wabadmin domain add \
  --name "OT-Production" \
  --description "OT system accounts"

# Add OT service account
wabadmin account add \
  --domain "OT-Production" \
  --login "ot_admin" \
  --account-type "service" \
  --password-rotation-enabled true \
  --password-rotation-interval 30

# Link account to RDS device
wabadmin target add \
  --device "rds-site1-ot" \
  --account "ot_admin" \
  --domain "OT-Production"
```

#### Step 4: Configure Authorization

```bash
# Create authorization for OT operators
wabadmin authorization add \
  --name "OT-Access-Site1" \
  --user-group "OT-Operators" \
  --target-group "OT-RDS" \
  --approval-required false \
  --recording-mandatory true \
  --session-timeout 3600

# Enable session recording with OCR
wabadmin authorization modify \
  --name "OT-Access-Site1" \
  --recording-protocol "rdp" \
  --ocr-enabled true \
  --keystroke-logging true
```

---

## OT Target Configuration

### Target System Preparation

For each OT system accessible via WALLIX RDS:

#### Windows-based OT Targets

```powershell
# On OT target (e.g., SCADA workstation)

# Enable RDP
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' `
  -Name "fDenyTSConnections" -Value 0

# Allow RDP from RDS server only
New-NetFirewallRule -DisplayName "RDP from WALLIX RDS" `
  -Direction Inbound -Protocol TCP -LocalPort 3389 `
  -RemoteAddress 10.10.1.30 `
  -Action Allow

# Configure NLA (Network Level Authentication)
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' `
  -Name "UserAuthentication" -Value 1

# Create local account for WALLIX access
$password = ConvertTo-SecureString "ComplexPassword123!" -AsPlainText -Force
New-LocalUser -Name "wallix_rds" `
  -Password $password `
  -Description "WALLIX RDS access account" `
  -PasswordNeverExpires $true

# Add to Remote Desktop Users group
Add-LocalGroupMember -Group "Remote Desktop Users" -Member "wallix_rds"
```

#### Linux-based OT Targets (via RDP wrapper)

```bash
# Install xrdp for RDP access
sudo apt-get update
sudo apt-get install -y xrdp

# Configure xrdp to accept from RDS only
sudo nano /etc/xrdp/xrdp.ini
# Add: allowed_ips=10.10.1.30

# Restart xrdp
sudo systemctl restart xrdp

# Create service account
sudo useradd -m -s /bin/bash wallix_rds
echo "wallix_rds:ComplexPassword123!" | sudo chpasswd
```

### Bastion Configuration for OT Targets

```bash
# Add each OT target as a device
wabadmin device add \
  --name "scada-hmi-01" \
  --host "10.50.1.10" \
  --description "SCADA HMI Panel 01" \
  --device-type "windows"

# Add RDP service
wabadmin service add \
  --device "scada-hmi-01" \
  --service-type "rdp" \
  --port 3389 \
  --protocol "rdp"

# Add account credentials
wabadmin account add \
  --device "scada-hmi-01" \
  --login "wallix_rds" \
  --password "ComplexPassword123!" \
  --auto-change-password true

# Create connection policy (via RDS)
wabadmin connection-policy add \
  --name "OT-SCADA-Access" \
  --via-device "rds-site1-ot" \
  --target-device "scada-hmi-01" \
  --protocol "rdp" \
  --recording-enabled true
```

---

## Security Hardening

### Windows Hardening (RDS Server)

#### Step 1: Disable Unnecessary Features

```powershell
# Disable features not needed
Disable-WindowsOptionalFeature -Online -FeatureName "SMB1Protocol"
Disable-WindowsOptionalFeature -Online -FeatureName "TelnetClient"

# Remove PowerShell v2 (security risk)
Disable-WindowsOptionalFeature -Online -FeatureName "MicrosoftWindowsPowerShellV2Root"
```

#### Step 2: Configure Security Policies

```powershell
# Export security template
secedit /export /cfg C:\security-baseline.inf

# Key policies to enforce:
# - Account lockout: 5 failed attempts
# - Password policy: 14 char minimum, 90 day expiry
# - Audit: Log all logon/logoff events
# - User Rights: Deny network logon to local accounts

# Import hardened template
secedit /configure /db secedit.sdb /cfg C:\security-hardened.inf
```

#### Step 3: Enable Audit Logging

```powershell
# Enable detailed audit logging
auditpol /set /category:"Logon/Logoff" /success:enable /failure:enable
auditpol /set /category:"Account Logon" /success:enable /failure:enable
auditpol /set /category:"Object Access" /success:enable /failure:enable

# Forward logs to SIEM
# Configure Windows Event Forwarding or install log shipper (e.g., Winlogbeat)
```

#### Step 4: Restrict Local Logon

```powershell
# Prevent local Administrator logon (force domain accounts)
$policy = Get-WmiObject -Namespace root\rsop\computer -Class RSOP_SecuritySettings
# Configure via GPO: Computer Config -> Windows Settings -> Security Settings
#                    -> Local Policies -> User Rights Assignment
#                    -> Deny log on locally: Administrators
```

### Network Hardening

#### Step 1: Firewall Rules (Strict)

```powershell
# Block all inbound by default
Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultInboundAction Block

# Allow only from Bastion (RDP)
New-NetFirewallRule -DisplayName "WALLIX Bastion RDP" `
  -Direction Inbound -Protocol TCP -LocalPort 3389 `
  -RemoteAddress 10.10.1.11,10.10.1.12 `
  -Action Allow

# Allow DNS and NTP outbound only
New-NetFirewallRule -DisplayName "DNS Outbound" `
  -Direction Outbound -Protocol UDP -RemotePort 53 `
  -RemoteAddress 10.10.0.10,10.10.0.11 `
  -Action Allow

New-NetFirewallRule -DisplayName "NTP Outbound" `
  -Direction Outbound -Protocol UDP -RemotePort 123 `
  -RemoteAddress 10.10.0.20 `
  -Action Allow
```

#### Step 2: Disable IPv6 (if not used)

```powershell
# Disable IPv6 on all adapters
Get-NetAdapter | ForEach-Object {
  Disable-NetAdapterBinding -Name $_.Name -ComponentID ms_tcpip6
}
```

### Application Hardening

#### Step 1: Restrict RemoteApp to Approved Applications Only

```powershell
# Remove all published RemoteApps except RDP client
Get-RDRemoteApp | Where-Object { $_.Alias -ne "ot-rdp" } | Remove-RDRemoteApp

# Verify only approved app is published
Get-RDRemoteApp
# Expected: Only "ot-rdp" (mstsc.exe)
```

#### Step 2: Disable RemoteApp Command Line

```powershell
# Prevent users from passing arbitrary command-line arguments
Set-RDRemoteApp -CollectionName "OT Access" `
  -Alias "ot-rdp" `
  -RequiredCommandLine "" `
  -CommandLineSetting DoNotAllow
```

---

## Session Recording

### Recording Configuration on WALLIX Bastion

```bash
# Enable full session recording for RDS access
wabadmin recording-policy add \
  --name "OT-RDS-Recording" \
  --protocol "rdp" \
  --video-enabled true \
  --ocr-enabled true \
  --keystroke-logging true \
  --retention-days 365

# Apply to all OT authorizations
wabadmin authorization modify \
  --name "OT-Access-Site1" \
  --recording-policy "OT-RDS-Recording"
```

### Recording Storage

```bash
# Configure recording storage path
wabadmin system config \
  --recording-path "/var/wab/recordings" \
  --recording-compression gzip \
  --recording-format "wbm"

# Set up archive to NAS/SAN
wabadmin system config \
  --archive-enabled true \
  --archive-path "nfs://nas-server/wallix-archives" \
  --archive-schedule "0 2 * * *"  # Daily at 2 AM
```

### OCR Configuration

```bash
# Enable OCR for text extraction
wabadmin ocr config \
  --enabled true \
  --language "en-US,es-ES,fr-FR" \
  --confidence-threshold 0.8 \
  --index-enabled true  # For full-text search

# Verify OCR engine
wabadmin ocr test --sample-image /tmp/test-screenshot.png
```

### Playback and Forensics

```bash
# Search session recordings
wabadmin recording search \
  --user "jdoe" \
  --device "scada-hmi-01" \
  --date-from "2026-01-01" \
  --date-to "2026-02-05"

# Export recording for audit
wabadmin recording export \
  --session-id "a1b2c3d4-e5f6-7890-abcd-ef1234567890" \
  --format "mp4" \
  --output "/tmp/audit-evidence.mp4"

# Generate session transcript (OCR text)
wabadmin recording transcript \
  --session-id "a1b2c3d4-e5f6-7890-abcd-ef1234567890" \
  --output "/tmp/session-transcript.txt"
```

---

## Testing Procedures

### Functional Testing

#### Test 1: RDP Access to WALLIX RDS

```powershell
# From end-user workstation
mstsc /v:10.10.1.100 /w:1920 /h:1080

# Expected:
# - HAProxy VIP redirects to Bastion
# - Bastion prompts for MFA
# - After auth, RemoteApp session to RDS starts
# - User sees "OT Remote Desktop" RemoteApp
```

#### Test 2: RemoteApp Launch

```powershell
# From WALLIX RDS RemoteApp session
# Launch Remote Desktop Connection (mstsc.exe)
# Connect to OT target: 10.50.1.10 (SCADA HMI)

# Expected:
# - RDP connection to OT target succeeds
# - Credentials auto-injected by Bastion
# - Session recorded with video + OCR
```

#### Test 3: Session Recording Verification

```bash
# On Bastion appliance
wabadmin recording list --user "testuser" --limit 1

# Verify recording file exists
ls -lh /var/wab/recordings/

# Play back recording
wabadmin recording playback \
  --session-id "<session-id>" \
  --start-time 0 \
  --duration 60
```

### Security Testing

#### Test 4: Direct RDS Access Blocked

```bash
# Attempt direct RDP to RDS from unauthorized IP
mstsc /v:10.10.1.30

# Expected: Connection refused (firewall blocks non-Bastion IPs)
```

#### Test 5: Unauthorized RemoteApp Access

```powershell
# Attempt to launch unauthorized application via RemoteApp
# Expected: Access denied, only mstsc.exe allowed
```

### Performance Testing

#### Test 6: Concurrent Sessions

```powershell
# Simulate 20 concurrent OT access sessions
1..20 | ForEach-Object -Parallel {
  mstsc /v:10.10.1.100 /admin
}

# Monitor RDS performance
Get-Counter '\Terminal Services Session(*)\*' -MaxSamples 10 -SampleInterval 5
```

### Integration Testing

#### Test 7: HA Failover (Bastion Cluster)

```bash
# Shut down primary Bastion node
ssh admin@10.10.1.11
wabadmin shutdown

# Attempt OT access via RDS
# Expected: HAProxy redirects to secondary (10.10.1.12), session succeeds
```

---

## Troubleshooting

### Common Issues

#### Issue 1: RDP Connection to RDS Fails

**Symptoms**: Connection refused or timeout when accessing RDS via Bastion

**Diagnosis**:

```powershell
# On RDS server, check WALLIX RDS service
Get-Service -Name "WALLIXRDSService"

# Check firewall rules
Get-NetFirewallRule -DisplayName "*WALLIX*" | Select-Object DisplayName, Enabled, Action

# Test network connectivity from Bastion
Test-NetConnection -ComputerName 10.10.1.30 -Port 3389
```

**Resolution**:

```powershell
# Restart WALLIX RDS service
Restart-Service -Name "WALLIXRDSService"

# Re-enable firewall rule
Enable-NetFirewallRule -DisplayName "WALLIX Bastion RDP Access"
```

#### Issue 2: RemoteApp Not Launching

**Symptoms**: RemoteApp session starts but mstsc.exe does not appear

**Diagnosis**:

```powershell
# Check RemoteApp configuration
Get-RDRemoteApp -CollectionName "OT Access"

# Check event logs
Get-WinEvent -LogName "Microsoft-Windows-TerminalServices-RemoteConnectionManager/Operational" -MaxEvents 20
```

**Resolution**:

```powershell
# Re-publish RemoteApp
Remove-RDRemoteApp -CollectionName "OT Access" -Alias "ot-rdp"
New-RDRemoteApp -CollectionName "OT Access" `
  -DisplayName "OT Remote Desktop" `
  -FilePath "C:\Windows\System32\mstsc.exe" `
  -Alias "ot-rdp"
```

#### Issue 3: Session Recording Missing

**Symptoms**: Sessions complete but no recording file in Bastion

**Diagnosis**:

```bash
# On Bastion, check recording policy
wabadmin recording-policy list

# Check disk space
df -h /var/wab/recordings

# Check WALLIX RDS logs
tail -f "C:\Program Files\WALLIX\RDS\logs\recording.log"
```

**Resolution**:

```bash
# Verify recording policy applied to authorization
wabadmin authorization show --name "OT-Access-Site1"

# Force enable recording
wabadmin authorization modify \
  --name "OT-Access-Site1" \
  --recording-mandatory true

# Clear disk space if needed
wabadmin recording archive --older-than 90
```

#### Issue 4: OT Target Credential Injection Fails

**Symptoms**: RDP connection to OT target prompts for credentials (should auto-inject)

**Diagnosis**:

```bash
# Check target configuration
wabadmin target list --device "scada-hmi-01"

# Verify account credentials
wabadmin account show --device "scada-hmi-01" --login "wallix_rds"

# Test credential checkout
wabadmin account checkout \
  --device "scada-hmi-01" \
  --login "wallix_rds" \
  --duration 60
```

**Resolution**:

```bash
# Update account credentials
wabadmin account modify \
  --device "scada-hmi-01" \
  --login "wallix_rds" \
  --password "NewPassword123!" \
  --credential-injection true

# Test credential injection
wabadmin target test \
  --device "scada-hmi-01" \
  --service "rdp" \
  --account "wallix_rds"
```

### Log Locations

| Component | Log Path | Description |
|-----------|----------|-------------|
| **WALLIX RDS Service** | `C:\Program Files\WALLIX\RDS\logs\service.log` | Service status, errors |
| **Session Recording** | `C:\Program Files\WALLIX\RDS\logs\recording.log` | Recording events |
| **RemoteApp** | `C:\Windows\Logs\RemoteApp\*.log` | RemoteApp launches |
| **Windows Event Log** | Event Viewer → Applications and Services → Microsoft → Windows → TerminalServices | RDP session events |
| **WALLIX Bastion** | `/var/log/wallix/wabengine.log` | Bastion-side RDS integration |

### Performance Tuning

#### Optimize RDP Settings for Low Latency

```powershell
# Configure RDP performance settings
$rdpSettings = @{
  "BitmapCacheSize" = 32768
  "OffscreenSupportLevel" = 1
  "MenuAnimations" = 0
  "VisualEffects" = 0
}

foreach ($setting in $rdpSettings.GetEnumerator()) {
  Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" `
    -Name $setting.Key -Value $setting.Value
}

# Restart Terminal Services
Restart-Service -Name "TermService"
```

#### Increase Session Host Capacity

```powershell
# Increase max concurrent sessions (default: 2)
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" `
  -Name "MaxInstanceCount" -Value 50

# Adjust session timeout for idle connections
Set-RDSessionCollectionConfiguration -CollectionName "OT Access" `
  -MaxIdleTimeMin 15 `
  -MaxDisconnectionTimeMin 30
```

---

## Next Steps

After completing WALLIX RDS setup:

1. **Configure Licensing**: [09-licensing.md](09-licensing.md) - License pools and integration
2. **End-to-End Testing**: [10-testing-validation.md](10-testing-validation.md) - Validate full deployment
3. **Operational Runbooks**: [/docs/pam/21-operational-runbooks/](../docs/pam/21-operational-runbooks/) - Day-2 operations

---

## References

### WALLIX Documentation
- WALLIX Bastion 12.x Admin Guide: https://pam.wallix.one/documentation
- WALLIX RDS Configuration: https://pam.wallix.one/documentation/rds

### Microsoft Documentation
- Windows Server 2022 RDS: https://learn.microsoft.com/windows-server/remote/remote-desktop-services/
- RemoteApp: https://learn.microsoft.com/windows-server/remote/remote-desktop-services/rds-create-collection

### Internal Documentation
- PAM Core: [/docs/pam/](../docs/pam/)
- Session Recording: [/docs/pam/09-session-management/](../docs/pam/09-session-management/)
- OT Security Best Practices: [/docs/pam/14-best-practices/](../docs/pam/14-best-practices/)

---

*WALLIX RDS provides secure, audited access to OT systems through RemoteApp isolation, ensuring compliance with industrial control system security standards.*
