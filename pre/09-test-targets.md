# 09 - Test Targets Setup

## Configuring Windows Server and RHEL Targets for WALLIX Testing

This guide covers setting up realistic enterprise test targets including Windows Server 2022 and RHEL 10/9 systems for PAM testing with Fortigate MFA integration.

> **Lab configuration**: 4 target VMs in **Targets VLAN (VLAN 130), 10.10.2.0/24**. WALLIX Bastion (DMZ VLAN 110) accesses them via Fortigate inter-VLAN routing. MFA uses TOTP only — no Push notifications.

---

## Target Architecture Overview

```
+===============================================================================+
|  TEST TARGET ARCHITECTURE — TARGETS VLAN 130 (10.10.2.0/24)                  |
+===============================================================================+
|                                                                               |
|  WINDOWS SERVER 2022 TARGETS                                                  |
|                                                                               |
|  +---------------------------+  +---------------------------+                 |
|  | win-srv-01                |  | win-srv-02                |                 |
|  | 10.10.2.10                |  | 10.10.2.11                |                 |
|  | General Purpose / RDP     |  | SQL Server / RDP          |                 |
|  | WinRM 5985/5986           |  | WinRM 5985/5986           |                 |
|  +---------------------------+  +---------------------------+                 |
|                                                                               |
|  RHEL TARGETS                                                                 |
|                                                                               |
|  +---------------------------+  +---------------------------+                 |
|  | rhel10-srv                |  | rhel9-srv                 |                 |
|  | 10.10.2.20                |  | 10.10.2.21                |                 |
|  | RHEL 10 App Server / SSH  |  | RHEL 9 Legacy Server/SSH  |                 |
|  +---------------------------+  +---------------------------+                 |
|                                                                               |
|  All targets reached from wallix-bastion (10.10.1.11, DMZ VLAN 110)          |
|  via Fortigate inter-VLAN routing. 4 VMs total.                              |
|                                                                               |
+===============================================================================+
```

---

## Target Summary

### Windows Server 2022 Targets

| Target | IP | Role | Protocols | Resources |
|--------|-----|------|-----------|-----------|
| win-srv-01 | 10.10.2.10 | General Purpose | RDP, WinRM | 2 vCPU, 8GB RAM, 60GB |
| win-srv-02 | 10.10.2.11 | SQL Server | RDP, WinRM | 4 vCPU, 16GB RAM, 100GB |

### RHEL Targets

| Target | IP | Role | Protocols | Resources |
|--------|-----|------|-----------|-----------|
| rhel10-srv | 10.10.2.20 | Linux App Server (RHEL 10) | SSH | 2 vCPU, 4GB RAM, 40GB |
| rhel9-srv | 10.10.2.21 | Legacy Linux Server (RHEL 9) | SSH | 2 vCPU, 4GB RAM, 40GB |

---

## Windows Server 2022 Setup

### General Purpose Server (win-srv-01)

```powershell
# On win-srv-01 VM (10.10.2.10)

# Set hostname
Rename-Computer -NewName "win-srv-01" -Restart

# Configure static IP
New-NetIPAddress -InterfaceAlias "Ethernet0" -IPAddress 10.10.2.10 -PrefixLength 24 -DefaultGateway 10.10.2.1
Set-DnsClientServerAddress -InterfaceAlias "Ethernet0" -ServerAddresses 10.10.1.60

# Join domain
$Credential = Get-Credential  # Enter domain admin credentials
Add-Computer -DomainName "lab.local" -Credential $Credential -Restart

# Enable RDP
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

# Configure NLA (Network Level Authentication)
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "UserAuthentication" -Value 1

# Enable WinRM for remote management
Enable-PSRemoting -Force
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*" -Force

# Configure WinRM for HTTPS (production recommended)
$cert = New-SelfSignedCertificate -DnsName "win-srv-01.lab.local" -CertStoreLocation Cert:\LocalMachine\My
winrm create winrm/config/Listener?Address=*+Transport=HTTPS "@{Hostname=`"win-srv-01.lab.local`";CertificateThumbprint=`"$($cert.Thumbprint)`"}"

# Open WinRM ports
New-NetFirewallRule -Name "WinRM-HTTP" -DisplayName "WinRM HTTP" -Enabled True -Direction Inbound -Protocol TCP -LocalPort 5985 -Action Allow
New-NetFirewallRule -Name "WinRM-HTTPS" -DisplayName "WinRM HTTPS" -Enabled True -Direction Inbound -Protocol TCP -LocalPort 5986 -Action Allow

# Create local test accounts (for non-domain testing)
$Password = ConvertTo-SecureString "WinAdmin123!" -AsPlainText -Force
New-LocalUser -Name "localadmin" -Password $Password -FullName "Local Administrator"
Add-LocalGroupMember -Group "Administrators" -Member "localadmin"

$SvcPassword = ConvertTo-SecureString "SvcAccount123!" -AsPlainText -Force
New-LocalUser -Name "svc-app" -Password $SvcPassword -FullName "Application Service Account"
Add-LocalGroupMember -Group "Users" -Member "svc-app"
```

### SQL Server Target (win-srv-02)

```powershell
# On win-srv-02 VM (10.10.2.11)

# Set hostname
Rename-Computer -NewName "win-srv-02" -Restart

# Configure network
New-NetIPAddress -InterfaceAlias "Ethernet0" -IPAddress 10.10.2.11 -PrefixLength 24 -DefaultGateway 10.10.2.1
Set-DnsClientServerAddress -InterfaceAlias "Ethernet0" -ServerAddresses 10.10.1.60

# Join domain
$Credential = Get-Credential
Add-Computer -DomainName "lab.local" -Credential $Credential -Restart

# Enable RDP and WinRM (same as win-srv-01)
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
Enable-PSRemoting -Force

# Install SQL Server (download SQL Server Express for lab)
# https://www.microsoft.com/en-us/sql-server/sql-server-downloads

# Create SQL admin account
$Password = ConvertTo-SecureString "SqlAdmin123!" -AsPlainText -Force
New-LocalUser -Name "sqladmin" -Password $Password -FullName "SQL Server Administrator"
Add-LocalGroupMember -Group "Administrators" -Member "sqladmin"

# Create SQL service account
$SvcPassword = ConvertTo-SecureString "SqlSvc123!" -AsPlainText -Force
New-LocalUser -Name "svc-sql" -Password $SvcPassword -FullName "SQL Server Service Account"

# Open SQL Server port (after installation)
New-NetFirewallRule -Name "SQL-Server" -DisplayName "SQL Server" -Enabled True -Direction Inbound -Protocol TCP -LocalPort 1433 -Action Allow
```

<!-- win-srv-03 not deployed in the lab (only win-srv-01 and win-srv-02) -->

---

## RHEL 10 Setup

### Web Server (rhel10-srv)

```bash
# On rhel10-srv VM (10.10.2.20)

# Set hostname
hostnamectl set-hostname rhel10-srv.lab.local

# Configure network
cat > /etc/NetworkManager/system-connections/eth0.nmconnection << 'EOF'
[connection]
id=eth0
type=ethernet
interface-name=eth0

[ipv4]
method=manual
addresses=10.10.2.20/24
gateway=10.10.2.1
dns=10.10.1.60
dns-search=lab.local

[ipv6]
method=disabled
EOF

chmod 600 /etc/NetworkManager/system-connections/eth0.nmconnection
nmcli connection reload
nmcli connection up eth0

# Update system
dnf update -y

# Install SSH server (should be installed by default)
dnf install -y openssh-server
systemctl enable --now sshd

# Configure SSH for key-based authentication
sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd

# Install web server
dnf install -y nginx
systemctl enable --now nginx

# Configure firewall
firewall-cmd --permanent --add-service=ssh
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --reload

# Create admin account
useradd -m -s /bin/bash webadmin
echo "WebAdmin123!" | passwd --stdin webadmin
usermod -aG wheel webadmin

# Create service account
useradd -m -s /bin/bash svc-nginx
echo "NginxSvc123!" | passwd --stdin svc-nginx

# Configure sudo for webadmin
echo "webadmin ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/webadmin

# Create SSH key directory for WALLIX key injection
mkdir -p /home/webadmin/.ssh
chmod 700 /home/webadmin/.ssh
touch /home/webadmin/.ssh/authorized_keys
chmod 600 /home/webadmin/.ssh/authorized_keys
chown -R webadmin:webadmin /home/webadmin/.ssh

# Join AD domain (optional - for centralized authentication)
dnf install -y realmd sssd oddjob oddjob-mkhomedir adcli samba-common-tools
realm join --user=Administrator lab.local
```

<!-- rhel10-db not deployed in the lab (only rhel10-srv and rhel9-srv) -->

### Legacy Server RHEL 9 (rhel9-srv)

```bash
# On rhel9-srv VM (10.10.2.21)

# Set hostname
hostnamectl set-hostname rhel9-srv.lab.local

# Configure network
cat > /etc/NetworkManager/system-connections/eth0.nmconnection << 'EOF'
[connection]
id=eth0
type=ethernet
interface-name=eth0

[ipv4]
method=manual
addresses=10.10.2.21/24
gateway=10.10.2.1
dns=10.10.1.60
dns-search=lab.local

[ipv6]
method=disabled
EOF

chmod 600 /etc/NetworkManager/system-connections/eth0.nmconnection
nmcli connection reload
nmcli connection up eth0

# Update system
dnf update -y

# Install common packages
dnf install -y \
    openssh-server \
    httpd \
    java-11-openjdk \
    python3 \
    git

# Enable services
systemctl enable --now sshd
systemctl enable --now httpd

# Configure firewall
firewall-cmd --permanent --add-service=ssh
firewall-cmd --permanent --add-service=http
firewall-cmd --reload

# Create legacy app admin account
useradd -m -s /bin/bash appadmin
echo "AppAdmin123!" | passwd --stdin appadmin
usermod -aG wheel appadmin

# Create legacy service account
useradd -m -s /bin/bash svc-legacy
echo "LegacySvc123!" | passwd --stdin svc-legacy

# Configure sudo
echo "appadmin ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/appadmin

# SSH key setup for WALLIX
mkdir -p /home/appadmin/.ssh
chmod 700 /home/appadmin/.ssh
touch /home/appadmin/.ssh/authorized_keys
chmod 600 /home/appadmin/.ssh/authorized_keys
chown -R appadmin:appadmin /home/appadmin/.ssh
```

---

## Adding Targets to WALLIX Bastion

### Create Domains

```
Configuration > Domains > Add

1. Windows-Servers
   - Type: Local
   - Description: Windows Server 2022 targets

2. Linux-RHEL
   - Type: Local
   - Description: RHEL 10 and RHEL 9 targets
```

### Create Devices

```
# Windows Servers
Configuration > Devices > Add

Device: win-srv-01
- Host: 10.10.2.10
- Domain: Windows-Servers
- Description: General Purpose Windows Server
- Services:
  - RDP (port 3389)
  - WinRM HTTP (port 5985)
  - WinRM HTTPS (port 5986)
- Accounts:
  - localadmin / WinAdmin123!
  - svc-app / SvcAccount123!

Device: win-srv-02
- Host: 10.10.2.11
- Domain: Windows-Servers
- Description: SQL Server
- Services:
  - RDP (port 3389)
  - WinRM (ports 5985/5986)
- Accounts:
  - sqladmin / SqlAdmin123!
  - svc-sql / SqlSvc123!

# RHEL Servers
Device: rhel10-srv
- Host: 10.10.2.20
- Domain: Linux-RHEL
- Description: RHEL 10 Linux App Server
- Services:
  - SSH (port 22)
- Accounts:
  - webadmin / WebAdmin123!
  - svc-nginx / NginxSvc123!

Device: rhel9-srv
- Host: 10.10.2.21
- Domain: Linux-RHEL
- Description: RHEL 9 Legacy Linux Server
- Services:
  - SSH (port 22)
- Accounts:
  - appadmin / AppAdmin123!
  - svc-legacy / LegacySvc123!
```

### Create Target Groups

```
Configuration > Target Groups > Add

Group: All-Windows-Servers
- Members: win-srv-01, win-srv-02

Group: All-Linux-Servers
- Members: rhel10-srv, rhel9-srv

Group: Database-Servers
- Members: win-srv-02

Group: App-Servers
- Members: rhel10-srv, rhel9-srv
```

### Create Authorizations

```
# Role-based access with Fortigate MFA

Authorization: Windows-Admin-Access
- User Group: LDAP-Windows-Admins
- Target Group: All-Windows-Servers
- Services: RDP, WinRM
- Recording: Enabled
- MFA: FortiToken (via FortiAuthenticator)

Authorization: Linux-Admin-Access
- User Group: LDAP-Linux-Admins
- Target Group: All-Linux-Servers
- Services: SSH
- Recording: Enabled
- MFA: FortiToken (via FortiAuthenticator)

Authorization: DBA-Access
- User Group: LDAP-DBAs
- Target Group: Database-Servers
- Services: SSH, RDP
- Recording: Enabled
- Approval: Required for production systems
- MFA: FortiToken (via FortiAuthenticator)

Authorization: Emergency-Access
- User Group: LDAP-Emergency-Responders
- Target Group: All-Windows-Servers, All-Linux-Servers
- Services: SSH, RDP, WinRM
- Recording: Enabled
- Time Limit: 4 hours
- Approval: Required
- MFA: FortiToken (via FortiAuthenticator)
```

---

## Testing Connectivity

### Test Windows RDP Access

```bash
# From WALLIX Bastion or jump host

# Test RDP connectivity
nmap -p 3389 10.10.2.10 10.10.2.11

# Test WinRM connectivity
nmap -p 5985,5986 10.10.2.10 10.10.2.11

# Test WinRM authentication (from Linux with pywinrm)
pip3 install pywinrm

python3 << 'EOF'
import winrm

session = winrm.Session(
    'http://10.10.2.10:5985/wsman',
    auth=('localadmin', 'WinAdmin123!'),
    transport='ntlm'
)
result = session.run_cmd('hostname')
print(f"Hostname: {result.std_out.decode()}")
EOF
```

### Test Linux SSH Access

```bash
# Test SSH connectivity
nmap -p 22 10.10.2.20 10.10.2.21

# Test SSH authentication
ssh webadmin@10.10.2.20 'hostname; whoami'   # rhel10-srv
ssh appadmin@10.10.2.21 'hostname; whoami'   # rhel9-srv

# Test SSH key-based access (after WALLIX key injection)
ssh -i /path/to/wallix_key webadmin@10.10.2.20
```

### Test Through WALLIX Bastion

```bash
# SSH through WALLIX (transparent mode)
ssh -J wallixuser@wallix.lab.local webadmin@rhel10-srv

# SSH with WALLIX proxy syntax
ssh wallixuser:webadmin:rhel10-srv@wallix.lab.local

# RDP through WALLIX (connect to VIP, select target)
# Use RDP client to connect to 10.10.1.100 (HAProxy VIP)
# Login: wallixuser:localadmin:win-srv-01
```

---

## Password Rotation Testing

### Windows Password Rotation

```powershell
# On WALLIX, configure rotation policy:
# Configuration > Devices > win-srv-01 > Accounts > localadmin
# - Enable automatic rotation
# - Rotation period: 30 days
# - Complexity: 16 chars, upper/lower/numbers/special

# Test rotation script (WALLIX uses internally)
$NewPassword = ConvertTo-SecureString "NewPassword123!" -AsPlainText -Force
Set-LocalUser -Name "localadmin" -Password $NewPassword

# Verify account still works
Test-NetConnection -ComputerName win-srv-01 -Port 3389
```

### Linux Password Rotation

```bash
# WALLIX can rotate Linux passwords via SSH
# Configure rotation in WALLIX:
# Configuration > Devices > rhel10-srv > Accounts > webadmin
# - Enable automatic rotation
# - Rotation period: 30 days

# Manual rotation test
echo "webadmin:NewPassword123!" | chpasswd

# Or using expect script (WALLIX uses similar)
expect << 'EOF'
spawn passwd webadmin
expect "New password:"
send "NewPassword123!\r"
expect "Retype new password:"
send "NewPassword123!\r"
expect eof
EOF
```

### SSH Key Rotation

```bash
# WALLIX can manage SSH keys
# Configure key rotation in WALLIX:
# Configuration > Devices > rhel10-srv > Accounts > webadmin
# - Enable SSH key management
# - Key type: ED25519 (recommended) or RSA 4096
# - Rotation period: 90 days

# WALLIX injects public key to target
# Keys stored in: /home/webadmin/.ssh/authorized_keys

# Verify key format
cat /home/webadmin/.ssh/authorized_keys
# ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... wallix-managed@bastion
```

---

## Target Verification Checklist

| Target | IP | Network | SSH/RDP | WinRM | AD Joined | WALLIX Config | Auth Test | Recording |
|--------|-----|---------|---------|-------|-----------|---------------|-----------|-----------|
| win-srv-01 | 10.10.2.10 | VLAN 130 | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| win-srv-02 | 10.10.2.11 | VLAN 130 | [ ] | [ ] | [ ] | [ ] | [ ] | [ ] |
| rhel10-srv | 10.10.2.20 | VLAN 130 | [ ] | N/A | [ ] | [ ] | [ ] | [ ] |
| rhel9-srv  | 10.10.2.21 | VLAN 130 | [ ] | N/A | [ ] | [ ] | [ ] | [ ] |

---

## Quick Reference: Target Ports

| Protocol | Port | Target Types | Notes |
|----------|------|--------------|-------|
| RDP | 3389 | Windows | Session recording via WALLIX RDS |
| WinRM HTTP | 5985 | Windows | Unencrypted, use for testing only |
| WinRM HTTPS | 5986 | Windows | Production recommended |
| SSH | 22 | RHEL | Key or password authentication |
| SQL Server | 1433 | win-srv-02 | Database access |

---

## Troubleshooting

### Windows RDP Issues

```powershell
# Check RDP service
Get-Service -Name TermService

# Check firewall rule
Get-NetFirewallRule -DisplayGroup "Remote Desktop" | Select DisplayName, Enabled

# Check NLA setting
(Get-ItemProperty 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp').UserAuthentication

# Test port
Test-NetConnection -ComputerName localhost -Port 3389
```

### Windows WinRM Issues

```powershell
# Check WinRM service
Get-Service -Name WinRM

# Check listener
winrm enumerate winrm/config/listener

# Test locally
Test-WSMan -ComputerName localhost

# Check firewall
Get-NetFirewallRule -Name "WinRM*" | Select Name, Enabled
```

### Linux SSH Issues

```bash
# Check SSH service
systemctl status sshd

# Check SSH config
sshd -T | grep -E "passwordauthentication|pubkeyauthentication"

# Check firewall
firewall-cmd --list-services

# Test authentication
ssh -v webadmin@localhost

# Check authorized_keys permissions
ls -la /home/webadmin/.ssh/
```

*Last updated: April 2026 | WALLIX Bastion 12.1.x | 4 targets in Targets VLAN 130 (10.10.2.0/24) | TOTP MFA only*

---

<p align="center">
  <a href="./08-ha-active-active.md">← Previous: HA Reference Guide</a> •
  <a href="./10-siem-integration.md">Next: SIEM Integration →</a>
</p>
