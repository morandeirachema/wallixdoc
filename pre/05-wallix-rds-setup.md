# 05 - WALLIX RDS Session Manager Setup

## WALLIX RDS for RDP Session Management

This guide covers deploying and configuring WALLIX RDS (Remote Desktop Session Manager) for advanced RDP session proxying, recording, and analysis.

---

## Architecture

```
+===============================================================================+
|                    WALLIX RDS ARCHITECTURE                                    |
+===============================================================================+
|                                                                               |
|  Users                PAM4OT Cluster         WALLIX RDS        Windows Targets|
|  =====                =============          ===========        ==============|
|                                                                               |
|  +------+             +-----------+          +-----------+      +-----------+ |
|  |Client|---RDP----->| PAM4OT    |---RDP--->| WALLIX    |--RDP>| Windows   | |
|  |      |  (3389)    | (Proxy)   | (3390)   | RDS       |(3389)| Server    | |
|  +------+            |10.10.1.11 |          |10.10.1.30 |      |10.10.2.30 | |
|                      +-----------+          +-----------+      +-----------+ |
|                             |                     |                          |
|                             |                     |                          |
|                      +-----------+          +-----------+                    |
|                      | PAM4OT    |          | Features: |                    |
|                      | (Backup)  |          | - OCR     |                    |
|                      |10.10.1.12 |          | - Video   |                    |
|                      +-----------+          | - Metadata|                    |
|                                             +-----------+                    |
|                                                    |                          |
|                                                    v                          |
|                                             +-----------+                    |
|                                             | Session   |                    |
|                                             | Storage   |                    |
|                                             +-----------+                    |
|                                                                               |
+===============================================================================+
```

---

## What is WALLIX RDS?

WALLIX RDS (Remote Desktop Session Manager) is a Windows-based component that provides:

- **Enhanced RDP Proxying**: Advanced RDP session handling
- **Session Recording**: High-quality video recording with OCR
- **Keystroke Logging**: Complete audit trail of user actions
- **OCR Analysis**: Text extraction from RDP sessions for compliance
- **Application Control**: Monitor and control application usage
- **File Transfer Monitoring**: Track clipboard and file transfers

---

## Prerequisites

- Windows Server 2022 VM
- WALLIX Bastion cluster operational
- Network connectivity: PAM4OT <-> RDS <-> Windows Targets
- WALLIX Bastion license with RDS support
- 100GB+ storage for session recordings

---

## Step 1: Deploy Windows Server VM

### VM Specifications

```
Hostname: wallix-rds.lab.local
OS: Windows Server 2022 Standard
vCPU: 4
RAM: 8 GB
Disk 1: 80 GB (OS + Application)
Disk 2: 200 GB (Session Storage - optional)
Network: OT DMZ (10.10.1.0/24)
IP: 10.10.1.30/24
Gateway: 10.10.1.1
DNS: 10.10.0.10
```

### Windows Server Installation

**PowerShell (as Administrator):**

```powershell
# Set computer name
Rename-Computer -NewName "wallix-rds" -Restart

# After reboot, configure static IP
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 10.10.1.30 `
    -PrefixLength 24 -DefaultGateway 10.10.1.1

Set-DnsClientServerAddress -InterfaceAlias "Ethernet" `
    -ServerAddresses 10.10.0.10,8.8.8.8

# Set timezone
Set-TimeZone -Name "Eastern Standard Time"

# Enable RDP (for management)
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' `
    -Name "fDenyTSConnections" -Value 0

Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

# Disable IE Enhanced Security (for downloads)
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}" `
    -Name "IsInstalled" -Value 0

Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}" `
    -Name "IsInstalled" -Value 0
```

---

## Step 2: Join Active Directory (Optional)

```powershell
# Join AD domain
$domain = "lab.local"
$username = "Administrator"
$password = ConvertTo-SecureString "LabAdmin123!" -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($username, $password)

Add-Computer -DomainName $domain -Credential $credential -Restart
```

---

## Step 3: Install Prerequisites

### Install .NET Framework

```powershell
# Install .NET Framework 4.8
Install-WindowsFeature -Name NET-Framework-45-Features -IncludeAllSubFeature

# Install .NET Framework 3.5 (if required)
Install-WindowsFeature -Name NET-Framework-Core
```

### Install Visual C++ Redistributables

```powershell
# Download and install VC++ Redistributables (2015-2022)
# Download from: https://aka.ms/vs/17/release/vc_redist.x64.exe

$vcredist = "C:\Temp\vc_redist.x64.exe"
Invoke-WebRequest -Uri "https://aka.ms/vs/17/release/vc_redist.x64.exe" -OutFile $vcredist
Start-Process -FilePath $vcredist -Args "/install /quiet /norestart" -Wait
```

### Install ODBC Drivers (for database connectivity)

```powershell
# Install PostgreSQL ODBC driver
# Download from: https://www.postgresql.org/ftp/odbc/versions/msi/

# Or use chocolatey:
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

choco install psqlodbc -y
```

---

## Step 4: Download WALLIX RDS Software

### From WALLIX Support Portal

1. Login to WALLIX Support: `https://support.wallix.com`
2. Navigate to: **Downloads > WALLIX Bastion > Session Managers**
3. Download: `WALLIX_Session_Manager_12.x_x64.exe`

**Or via command line:**

```powershell
# Create download directory
New-Item -Path "C:\Temp\WALLIX" -ItemType Directory -Force

# Download installer (replace URL with actual download link from support portal)
# Note: You'll need a valid support account

# Example:
# Invoke-WebRequest -Uri "https://support.wallix.com/downloads/..." `
#     -OutFile "C:\Temp\WALLIX\WALLIX_Session_Manager_12.1.10_x64.exe"
```

---

## Step 5: Install WALLIX RDS

### Installation Steps

**Run installer as Administrator:**

```powershell
# Run the installer
Start-Process -FilePath "C:\Temp\WALLIX\WALLIX_Session_Manager_12.1.10_x64.exe" `
    -Wait -Verb RunAs
```

**Installation Wizard:**

```
+===============================================================================+
|  WALLIX SESSION MANAGER INSTALLATION WIZARD                                   |
+===============================================================================+

STEP 1: Welcome
  [Next]

STEP 2: License Agreement
  [x] I accept the terms in the License Agreement
  [Next]

STEP 3: Installation Type
  (x) Complete Installation
  ( ) Custom Installation
  [Next]

STEP 4: Installation Folder
  Destination: C:\Program Files\WALLIX\SessionManager\
  [Next]

STEP 5: Database Configuration
  Database Type: PostgreSQL
  Host: 10.10.1.11 (PAM4OT Primary)
  Port: 5432
  Database Name: wallix_bastion
  Username: postgres
  Password: [enter PAM4OT DB password]

  [Test Connection]
  Result: Connection successful

  [Next]

STEP 6: Session Storage Configuration
  Session Recording Path: D:\WALLIX\Sessions\
  (or C:\WALLIX\Sessions\ if single disk)

  [Next]

STEP 7: Service Account
  (x) Use Local System Account
  ( ) Use specific account

  [Next]

STEP 8: Ready to Install
  [Install]

STEP 9: Installation Complete
  [x] Start WALLIX Session Manager service
  [Finish]

+===============================================================================+
```

---

## Step 6: Configure WALLIX RDS Service

### Service Configuration

```powershell
# Verify service is installed
Get-Service -Name "WallixSessionManager"

# Configure service to start automatically
Set-Service -Name "WallixSessionManager" -StartupType Automatic

# Start service
Start-Service -Name "WallixSessionManager"

# Check service status
Get-Service -Name "WallixSessionManager" | Select-Object Status, StartType
```

### Firewall Configuration

```powershell
# Allow RDP connections from PAM4OT nodes
New-NetFirewallRule -DisplayName "WALLIX RDS - RDP from PAM4OT" `
    -Direction Inbound -LocalPort 3389 -Protocol TCP -Action Allow `
    -RemoteAddress 10.10.1.11,10.10.1.12

# Allow HTTPS for management (optional)
New-NetFirewallRule -DisplayName "WALLIX RDS - HTTPS Management" `
    -Direction Inbound -LocalPort 8443 -Protocol TCP -Action Allow
```

---

## Step 7: Register RDS with PAM4OT

### Via PAM4OT Web UI

**Login to PAM4OT Admin: `https://10.10.1.100/admin`**

1. Navigate to: **Configuration > Session Managers**
2. Click **Add Session Manager**

```
+===============================================================================+
|  SESSION MANAGER CONFIGURATION                                                |
+===============================================================================+
|                                                                               |
|  GENERAL                                                                      |
|  -------                                                                      |
|  Name:                  RDS-Primary                                           |
|  Description:           WALLIX RDS Session Manager                            |
|  Type:                  WALLIX Session Manager (RDS)                          |
|                                                                               |
|  CONNECTION                                                                   |
|  ----------                                                                   |
|  Host:                  10.10.1.30                                            |
|  Port:                  3389                                                  |
|  Protocol:              RDP                                                   |
|                                                                               |
|  AUTHENTICATION                                                               |
|  --------------                                                               |
|  Username:              wallixrds                                             |
|  Password:              [auto-generated or custom]                            |
|                                                                               |
|  SESSION RECORDING                                                            |
|  -----------------                                                            |
|  [x] Enable session recording                                                 |
|  [x] Enable OCR (text extraction)                                             |
|  [x] Enable keystroke logging                                                 |
|  Recording Quality:     High (1080p)                                          |
|  Storage Path:          D:\WALLIX\Sessions\                                   |
|                                                                               |
|  ADVANCED                                                                     |
|  --------                                                                     |
|  Max Concurrent Sessions: 50                                                  |
|  Session Timeout:         8 hours                                             |
|  [x] Enable clipboard monitoring                                              |
|  [x] Enable file transfer monitoring                                          |
|                                                                               |
|  [Save]                                                                       |
|                                                                               |
+===============================================================================+
```

### Via REST API

```bash
# From Linux client or PAM4OT node
curl -k -X POST "https://10.10.1.100/api/sessionmanagers" \
    -H "X-Auth-Token: $API_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "sessionmanager_name": "RDS-Primary",
        "sessionmanager_type": "WALLIX_RDS",
        "host": "10.10.1.30",
        "port": 3389,
        "enable_recording": true,
        "enable_ocr": true,
        "recording_quality": "high",
        "max_sessions": 50
    }'
```

---

## Step 8: Configure Session Routing

### Create Connection Policy

**In PAM4OT Web UI:**

**Navigate to: Configuration > Connection Policies**

```
+===============================================================================+
|  CONNECTION POLICY - RDP VIA RDS                                              |
+===============================================================================+
|                                                                               |
|  Name:                  Windows-RDP-via-RDS                                   |
|  Description:           Route all Windows RDP sessions through WALLIX RDS     |
|                                                                               |
|  CRITERIA                                                                     |
|  --------                                                                     |
|  Protocol:              RDP                                                   |
|  Target Domain:         Windows-Servers (or specific domain)                  |
|  Target OS:             Windows Server 2016/2019/2022                         |
|                                                                               |
|  ROUTING                                                                      |
|  -------                                                                      |
|  Session Manager:       RDS-Primary (10.10.1.30)                              |
|  [x] Use session manager for all matching connections                         |
|                                                                               |
|  RECORDING OPTIONS                                                            |
|  -----------------                                                            |
|  [x] Enable session recording                                                 |
|  [x] Enable OCR                                                               |
|  [x] Enable keystroke logging                                                 |
|  [x] Monitor clipboard                                                        |
|  [x] Monitor file transfers                                                   |
|                                                                               |
+===============================================================================+
```

---

## Step 9: Test RDP Session Through RDS

### From Windows Client

1. Launch **Remote Desktop Connection** (mstsc.exe)
2. Computer: `10.10.1.100` (PAM4OT VIP)
3. Click **Connect**

**Login prompt:**
```
Username: jadmin@windows-server01
Password: JohnAdmin123!123456
         └─ AD Password ─┘└─ TOTP ─┘
```

4. Session will be proxied through:
   - PAM4OT (10.10.1.11 or .12)
   - WALLIX RDS (10.10.1.30)
   - Target Windows Server (10.10.2.30)

### Verify Session Recording

**In PAM4OT Web UI:**

1. Navigate to: **Audit > Session Recordings**
2. Find session: `jadmin @ windows-server01`
3. Click **Play**
4. Verify:
   - [ ] Video playback works
   - [ ] OCR text is extracted
   - [ ] Keystrokes are logged
   - [ ] Clipboard events are captured

---

## Monitoring and Management

### View Active Sessions

**On WALLIX RDS Server:**

```powershell
# View active RDP sessions
qwinsta

# View WALLIX Session Manager logs
Get-EventLog -LogName Application -Source "WALLIX*" -Newest 50

# Monitor session storage usage
Get-ChildItem -Path "D:\WALLIX\Sessions\" -Recurse |
    Measure-Object -Property Length -Sum |
    Select-Object @{Name="SizeGB";Expression={[math]::Round($_.Sum/1GB, 2)}}
```

### Performance Monitoring

```powershell
# Monitor CPU and Memory usage
Get-Counter '\Processor(_Total)\% Processor Time','\Memory\Available MBytes' -SampleInterval 5 -MaxSamples 10

# Monitor disk I/O
Get-Counter '\PhysicalDisk(_Total)\Disk Reads/sec','\PhysicalDisk(_Total)\Disk Writes/sec' -SampleInterval 5 -MaxSamples 10
```

---

## Storage Management

### Session Recording Retention

**Configure retention policy in PAM4OT:**

```
Configuration > System > Session Recording

Retention Policy:
  Keep recordings for: 90 days
  Archive old recordings to: \\nas\wallix-archive\
  Delete recordings after archival: Yes
```

### Automatic Cleanup

**PowerShell script for cleanup (run as scheduled task):**

```powershell
# cleanup-sessions.ps1

$SessionPath = "D:\WALLIX\Sessions\"
$RetentionDays = 90
$ArchivePath = "\\nas\wallix-archive\"

# Get sessions older than retention period
$OldSessions = Get-ChildItem -Path $SessionPath -Recurse -File |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$RetentionDays) }

foreach ($session in $OldSessions) {
    # Archive to NAS
    $DestPath = Join-Path $ArchivePath $session.Name
    Copy-Item -Path $session.FullName -Destination $DestPath -Force

    # Verify copy and delete original
    if (Test-Path $DestPath) {
        Remove-Item -Path $session.FullName -Force
        Write-Host "Archived and deleted: $($session.Name)"
    }
}
```

**Schedule cleanup task:**

```powershell
# Create scheduled task to run daily at 2 AM
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File C:\Scripts\cleanup-sessions.ps1"

$Trigger = New-ScheduledTaskTrigger -Daily -At 2am

$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount

Register-ScheduledTask -TaskName "WALLIX-RDS-Cleanup" `
    -Action $Action -Trigger $Trigger -Principal $Principal `
    -Description "Archive and clean old WALLIX RDS sessions"
```

---

## Troubleshooting

### Issue: RDS service won't start

```powershell
# Check service status
Get-Service -Name "WallixSessionManager"

# Check event logs
Get-EventLog -LogName Application -Source "WALLIX*" -Newest 10

# Verify database connectivity
Test-NetConnection -ComputerName 10.10.1.11 -Port 5432

# Restart service
Restart-Service -Name "WallixSessionManager"
```

### Issue: Sessions not being recorded

```powershell
# Check session storage path exists
Test-Path "D:\WALLIX\Sessions\"

# Check disk space
Get-PSDrive D

# Verify permissions on session storage directory
Get-Acl "D:\WALLIX\Sessions\"

# Service account should have full control
```

### Issue: Poor RDP session performance

```powershell
# Check CPU usage
Get-Counter '\Processor(_Total)\% Processor Time'

# Check memory usage
Get-Counter '\Memory\Available MBytes'

# Increase RDS server resources if consistently high
```

---

## Security Best Practices

### 1. Network Security

```powershell
# Restrict RDP access to PAM4OT nodes only
Remove-NetFirewallRule -DisplayName "Remote Desktop*"

New-NetFirewallRule -DisplayName "WALLIX RDS - RDP from PAM4OT" `
    -Direction Inbound -LocalPort 3389 -Protocol TCP -Action Allow `
    -RemoteAddress 10.10.1.11,10.10.1.12
```

### 2. Encryption

```
- Use TLS 1.2+ for RDP connections
- Enable NLA (Network Level Authentication)
- Use strong RDP encryption (High level)
```

### 3. Monitoring

```
- Monitor for unauthorized access attempts
- Alert on service failures
- Track session storage usage
- Log all administrative actions
```

---

## Backup and Recovery

### Backup Configuration

```powershell
# Backup WALLIX RDS configuration
$BackupPath = "\\nas\wallix-backup\rds\"
$Date = Get-Date -Format "yyyy-MM-dd"

# Backup configuration files
Copy-Item -Path "C:\Program Files\WALLIX\SessionManager\Config\*" `
    -Destination "$BackupPath\Config-$Date\" -Recurse -Force

# Export registry settings
reg export "HKLM\SOFTWARE\WALLIX" "$BackupPath\Registry-$Date.reg" /y
```

### Disaster Recovery

```powershell
# Restore from backup
1. Reinstall WALLIX RDS on new server
2. Restore configuration files from backup
3. Import registry settings
4. Re-register with PAM4OT
5. Test RDP session routing
```

---

## Performance Tuning

### Recommended Settings

```powershell
# Increase RDP session limits
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" `
    -Name "MaxInstanceCount" -Value 100

# Optimize video encoding for recordings
# Configure in: C:\Program Files\WALLIX\SessionManager\Config\video.conf
# Codec: H.264
# Bitrate: 2 Mbps (balance quality vs. storage)
# FPS: 15 (sufficient for most sessions)
```

---

## Quick Reference

### WALLIX RDS Details

| Component | Value |
|-----------|-------|
| **Hostname** | wallix-rds.lab.local |
| **IP Address** | 10.10.1.30 |
| **OS** | Windows Server 2022 |
| **RDP Port** | 3389 |
| **Session Storage** | D:\WALLIX\Sessions\ |

### Service Management

| Command | Purpose |
|---------|---------|
| `Get-Service WallixSessionManager` | Check service status |
| `Start-Service WallixSessionManager` | Start service |
| `Restart-Service WallixSessionManager` | Restart service |
| `Stop-Service WallixSessionManager` | Stop service |

---

## Verification Checklist

| Check | Status |
|-------|--------|
| Windows Server installed and configured | [ ] |
| Prerequisites installed (.NET, VC++, ODBC) | [ ] |
| WALLIX RDS software installed | [ ] |
| Service running and configured | [ ] |
| Registered with PAM4OT | [ ] |
| Connection policy created | [ ] |
| Test RDP session successful | [ ] |
| Session recording verified | [ ] |
| OCR and keystroke logging working | [ ] |
| Retention policy configured | [ ] |

---

<p align="center">
  <a href="./04-fortiauthenticator-setup.md">← Previous: FortiAuth MFA Setup</a> •
  <a href="./06-ad-integration.md">Next: AD Integration with MFA →</a>
</p>
