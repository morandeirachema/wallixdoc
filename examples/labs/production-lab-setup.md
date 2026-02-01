# Production-Like Lab Setup

> **Objective**: Create a lab environment that closely simulates a real production deployment with HA, load balancing, MFA, and Active Directory integration.

---

## Architecture Overview

```
+===============================================================================+
|                    PRODUCTION-LIKE LAB ARCHITECTURE                           |
+===============================================================================+
|                                                                               |
|  VLAN 10 (Management/Bastion Network) - 192.168.10.0/24                      |
|  ┌─────────────────────────────────────────────────────────────────────┐     |
|  │                                                                       │     |
|  │                    USERS / ADMINISTRATORS                             │     |
|  │                            │                                          │     |
|  │                            │ HTTPS                                    │     |
|  │                            ▼                                          │     |
|  │               ┌──────────────────────────┐                            │     |
|  │               │   HAProxy VIP (Floating) │                            │     |
|  │               │   192.168.10.100         │                            │     |
|  │               └────┬──────────────┬──────┘                            │     |
|  │                    │              │                                   │     |
|  │         ┌──────────┘              └──────────┐                        │     |
|  │         │                                    │                        │     |
|  │         ▼                                    ▼                        │     |
|  │  ┌─────────────┐                     ┌─────────────┐                 │     |
|  │  │  HAProxy-1  │                     │  HAProxy-2  │                 │     |
|  │  │  Primary    │◄──Keepalived VRRP──►│  Backup     │                 │     |
|  │  │ .10.11      │                     │  .10.12     │                 │     |
|  │  └──────┬──────┘                     └──────┬──────┘                 │     |
|  │         │                                    │                        │     |
|  │         └──────────┬──────────────┬──────────┘                        │     |
|  │                    │              │                                   │     |
|  │                    ▼              ▼                                   │     |
|  │         ┌──────────────┐   ┌──────────────┐                          │     |
|  │         │ WALLIX       │   │ WALLIX       │                          │     |
|  │         │ Bastion-1    │◄─►│ Bastion-2    │                          │     |
|  │         │ Primary      │   │ Secondary    │                          │     |
|  │         │ .10.21       │   │ .10.22       │                          │     |
|  │         └──────┬───────┘   └──────┬───────┘                          │     |
|  │                │                   │                                  │     |
|  │                │   PostgreSQL Replication                             │     |
|  │                │   Pacemaker/Corosync Cluster                         │     |
|  │                │                                                      │     |
|  │         ┌──────▼────────┐                                             │     |
|  │         │ WALLIX RDS    │                                             │     |
|  │         │ (Session Mgr) │                                             │     |
|  │         │ .10.30        │                                             │     |
|  │         └───────────────┘                                             │     |
|  │                                                                       │     |
|  │         ┌──────────────┐   ┌──────────────┐                          │     |
|  │         │ Active       │   │ FortiAuth    │                          │     |
|  │         │ Directory    │   │ (MFA)        │                          │     |
|  │         │ DC           │   │ .10.50       │                          │     |
|  │         │ .10.40       │   └──────────────┘                          │     |
|  │         └──────────────┘                                              │     |
|  │                                                                       │     |
|  └───────────────────────────────────────────────────────────────────────┘     |
|                                                                               |
|                                     │                                         |
|                                     │ Firewall / Router                       |
|                                     │                                         |
|  VLAN 20 (Target Network) - 192.168.20.0/24                                  |
|  ┌─────────────────────────────────────────────────────────────────────┐     |
|  │                                                                       │     |
|  │         ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐      │     |
|  │         │ Linux    │  │ Windows  │  │ OT/PLC   │  │ Network  │      │     |
|  │         │ Server   │  │ Server   │  │ Simulator│  │ Device   │      │     |
|  │         │ .20.10   │  │ .20.20   │  │ .20.30   │  │ .20.40   │      │     |
|  │         └──────────┘  └──────────┘  └──────────┘  └──────────┘      │     |
|  │                                                                       │     |
|  └───────────────────────────────────────────────────────────────────────┘     |
|                                                                               |
+===============================================================================+
```

---

## Lab Components

| Component | Quantity | Purpose | IP Address |
|-----------|----------|---------|------------|
| **HAProxy-1** | 1 | Primary load balancer | 192.168.10.11 |
| **HAProxy-2** | 1 | Backup load balancer | 192.168.10.12 |
| **HAProxy VIP** | 1 | Floating IP (Keepalived) | 192.168.10.100 |
| **WALLIX Bastion-1** | 1 | Primary PAM node | 192.168.10.21 |
| **WALLIX Bastion-2** | 1 | Secondary PAM node | 192.168.10.22 |
| **WALLIX RDS** | 1 | Session manager | 192.168.10.30 |
| **Active Directory** | 1 | User directory | 192.168.10.40 |
| **FortiAuthenticator** | 1 | MFA server | 192.168.10.50 |
| **Linux Targets** | 2+ | Test servers | 192.168.20.10-19 |
| **Windows Targets** | 1+ | RDP servers | 192.168.20.20-29 |
| **OT Simulators** | 1+ | PLC/SCADA sims | 192.168.20.30-39 |

**Total VMs**: 11 (minimum)

---

## Hardware Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **CPU** | 24 cores | 32+ cores |
| **RAM** | 64 GB | 96 GB |
| **Storage** | 500 GB SSD | 1 TB NVMe |
| **Network** | 2x 1 Gbps NICs | 2x 10 Gbps NICs |

---

## Phase 1: Network Setup (30 minutes)

### Step 1.1: Create VLANs

**VLAN 10 - Management/Bastion Network:**
```
VLAN ID: 10
Subnet: 192.168.10.0/24
Gateway: 192.168.10.1
DHCP: Disabled (static IPs only)
DNS: 192.168.10.40 (AD server)
```

**VLAN 20 - Target Network:**
```
VLAN ID: 20
Subnet: 192.168.20.0/24
Gateway: 192.168.20.1
DHCP: Disabled
DNS: 192.168.10.40
```

### Step 1.2: Configure Hypervisor Virtual Networks

**VMware vSphere/ESXi:**
```bash
# Create port groups
vSphere Client > Networking > Port Groups > Add
  - Name: VLAN10-Management
  - VLAN ID: 10

  - Name: VLAN20-Targets
  - VLAN ID: 20
```

**Proxmox:**
```bash
# Edit /etc/network/interfaces
auto vmbr10
iface vmbr10 inet static
    address 192.168.10.1/24
    bridge-ports none
    bridge-stp off
    bridge-fd 0

auto vmbr20
iface vmbr20 inet static
    address 192.168.20.1/24
    bridge-ports none
    bridge-stp off
    bridge-fd 0
```

---

## Phase 2: Active Directory Setup (45 minutes)

### Step 2.1: Deploy AD Server

**VM Specifications:**
```
Hostname: ad-lab01.company.local
OS: Windows Server 2022
vCPU: 4
RAM: 8 GB
Disk: 80 GB
Network: VLAN 10
IP: 192.168.10.40
```

### Step 2.2: Install AD Domain Services

**PowerShell (run as Administrator):**
```powershell
# Set static IP
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 192.168.10.40 `
    -PrefixLength 24 -DefaultGateway 192.168.10.1
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 192.168.10.40

# Install AD DS role
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Promote to domain controller
Import-Module ADDSDeployment
Install-ADDSForest `
    -DomainName "company.local" `
    -DomainNetbiosName "COMPANY" `
    -ForestMode "WinThreshold" `
    -DomainMode "WinThreshold" `
    -InstallDns:$true `
    -SafeModeAdministratorPassword (ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force) `
    -Force:$true

# VM will reboot
```

### Step 2.3: Create OUs and Users

**After reboot, run:**
```powershell
# Create Organizational Units
New-ADOrganizationalUnit -Name "PAM-Users" -Path "DC=company,DC=local"
New-ADOrganizationalUnit -Name "PAM-Groups" -Path "DC=company,DC=local"

# Create security groups
New-ADGroup -Name "PAM-Admins" -GroupScope Global `
    -Path "OU=PAM-Groups,DC=company,DC=local"
New-ADGroup -Name "PAM-Engineers" -GroupScope Global `
    -Path "OU=PAM-Groups,DC=company,DC=local"
New-ADGroup -Name "PAM-Auditors" -GroupScope Global `
    -Path "OU=PAM-Groups,DC=company,DC=local"

# Create test users
New-ADUser -Name "John Admin" -GivenName "John" -Surname "Admin" `
    -SamAccountName "jadmin" -UserPrincipalName "jadmin@company.local" `
    -Path "OU=PAM-Users,DC=company,DC=local" `
    -AccountPassword (ConvertTo-SecureString "UserP@ss123!" -AsPlainText -Force) `
    -Enabled $true

New-ADUser -Name "Jane Engineer" -GivenName "Jane" -Surname "Engineer" `
    -SamAccountName "jengineer" -UserPrincipalName "jengineer@company.local" `
    -Path "OU=PAM-Users,DC=company,DC=local" `
    -AccountPassword (ConvertTo-SecureString "UserP@ss123!" -AsPlainText -Force) `
    -Enabled $true

New-ADUser -Name "Bob Auditor" -GivenName "Bob" -Surname "Auditor" `
    -SamAccountName "bauditor" -UserPrincipalName "bauditor@company.local" `
    -Path "OU=PAM-Users,DC=company,DC=local" `
    -AccountPassword (ConvertTo-SecureString "UserP@ss123!" -AsPlainText -Force) `
    -Enabled $true

# Add users to groups
Add-ADGroupMember -Identity "PAM-Admins" -Members "jadmin"
Add-ADGroupMember -Identity "PAM-Engineers" -Members "jengineer"
Add-ADGroupMember -Identity "PAM-Auditors" -Members "bauditor"
```

### Step 2.4: Configure DNS

```powershell
# Add forward lookup zones if needed
Add-DnsServerPrimaryZone -Name "company.local" -ZoneFile "company.local.dns"

# Create A records for lab components
Add-DnsServerResourceRecordA -Name "haproxy-vip" -ZoneName "company.local" -IPv4Address "192.168.10.100"
Add-DnsServerResourceRecordA -Name "haproxy1" -ZoneName "company.local" -IPv4Address "192.168.10.11"
Add-DnsServerResourceRecordA -Name "haproxy2" -ZoneName "company.local" -IPv4Address "192.168.10.12"
Add-DnsServerResourceRecordA -Name "wallix1" -ZoneName "company.local" -IPv4Address "192.168.10.21"
Add-DnsServerResourceRecordA -Name "wallix2" -ZoneName "company.local" -IPv4Address "192.168.10.22"
Add-DnsServerResourceRecordA -Name "wallix-rds" -ZoneName "company.local" -IPv4Address "192.168.10.30"
Add-DnsServerResourceRecordA -Name "fortiauth" -ZoneName "company.local" -IPv4Address "192.168.10.50"

# Create CNAME for PAM access
Add-DnsServerResourceRecordCName -Name "pam" -ZoneName "company.local" -HostNameAlias "haproxy-vip.company.local"
```

---

## Phase 3: FortiAuthenticator MFA Setup (60 minutes)

### Step 3.1: Deploy FortiAuthenticator VM

**VM Specifications:**
```
Hostname: fortiauth.company.local
OS: FortiAuthenticator (download from Fortinet)
vCPU: 2
RAM: 4 GB
Disk: 40 GB
Network: VLAN 10
IP: 192.168.10.50
```

### Step 3.2: Initial Configuration

**Via Console or Web UI (https://192.168.10.50):**

1. **Basic Setup:**
   ```
   Login: admin / (no password - first login)
   Set new admin password: FortiAuth123!

   System > Network > Interface
   - Interface: port1
   - IP/Netmask: 192.168.10.50/24
   - Gateway: 192.168.10.1
   - DNS: 192.168.10.40
   ```

2. **Set Hostname and Time:**
   ```
   System > Settings
   - Hostname: fortiauth.company.local
   - Timezone: Your timezone

   System > Time
   - NTP Server: pool.ntp.org
   - Enable NTP: Yes
   ```

### Step 3.3: Configure LDAP Connection to AD

**Authentication > LDAP > Create New:**
```
Name: Company-AD
Server Name/IP: 192.168.10.40
Server Port: 389
Common Name Identifier: sAMAccountName
Distinguished Name: CN=Users,DC=company,DC=local
Bind Type: Regular
Bind Distinguished Name: CN=Administrator,CN=Users,DC=company,DC=local
Password: (your AD admin password)

Test Connection: Click to verify
```

### Step 3.4: Configure RADIUS for WALLIX

**Authentication > RADIUS Service > Create New:**
```
Name: WALLIX-Bastion
Authentication Type: PAP
Clients:
  - Name: WALLIX-1
    IP/Netmask: 192.168.10.21/32
    Secret: WallixRadius2024!

  - Name: WALLIX-2
    IP/Netmask: 192.168.10.22/32
    Secret: WallixRadius2024!

Default User Group: Company-AD-Users
```

### Step 3.5: Enable FortiToken Mobile

**Authentication > FortiTokens > Mobile:**
```
Enable FortiToken Mobile: Yes
Allow User Self-Registration: Yes
Token Lifetime: 60 seconds
```

### Step 3.6: Create User and Assign Token

**Authentication > User Management > Local Users > Import from LDAP:**
```
LDAP Server: Company-AD
Search Filter: (sAMAccountName=jadmin)
Import User: jadmin

After import:
  Edit User: jadmin
  - Enable Two-Factor Authentication: Yes
  - Token Type: FortiToken Mobile
  - Send Activation Code: Email or show QR code
```

---

## Phase 4: HAProxy Load Balancer Setup (90 minutes)

### Step 4.1: Deploy HAProxy-1

**VM Specifications:**
```
Hostname: haproxy1.company.local
OS: Debian 12
vCPU: 2
RAM: 4 GB
Disk: 20 GB
Network: VLAN 10
IP: 192.168.10.11
```

**Installation:**
```bash
# Set hostname
hostnamectl set-hostname haproxy1.company.local

# Configure static IP
cat > /etc/network/interfaces << 'EOF'
auto lo
iface lo inet loopback

auto ens192
iface ens192 inet static
    address 192.168.10.11/24
    gateway 192.168.10.1
    dns-nameservers 192.168.10.40
    dns-search company.local
EOF

systemctl restart networking

# Update and install HAProxy + Keepalived
apt update && apt upgrade -y
apt install -y haproxy keepalived vim

# Enable IP forwarding
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
echo "net.ipv4.ip_nonlocal_bind=1" >> /etc/sysctl.conf
sysctl -p
```

### Step 4.2: Configure HAProxy

**Edit /etc/haproxy/haproxy.cfg:**
```haproxy
global
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

    # SSL Configuration
    ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256
    ssl-default-bind-options ssl-min-ver TLSv1.2 no-tls-tickets

defaults
    log     global
    mode    http
    option  httplog
    option  dontlognull
    timeout connect 5000
    timeout client  50000
    timeout server  50000
    errorfile 400 /etc/haproxy/errors/400.http
    errorfile 403 /etc/haproxy/errors/403.http
    errorfile 408 /etc/haproxy/errors/408.http
    errorfile 500 /etc/haproxy/errors/500.http
    errorfile 502 /etc/haproxy/errors/502.http
    errorfile 503 /etc/haproxy/errors/503.http
    errorfile 504 /etc/haproxy/errors/504.http

# Stats Interface
listen stats
    bind *:8080
    stats enable
    stats uri /stats
    stats refresh 30s
    stats auth admin:HAProxyStats123!

# WALLIX Bastion HTTPS Frontend
frontend wallix_https
    bind 192.168.10.100:443 ssl crt /etc/haproxy/certs/wallix.pem
    mode http
    default_backend wallix_bastions

    # Security headers
    http-response set-header X-Frame-Options SAMEORIGIN
    http-response set-header X-Content-Type-Options nosniff
    http-response set-header X-XSS-Protection "1; mode=block"

# WALLIX Bastion Backend
backend wallix_bastions
    mode http
    balance roundrobin
    option httpchk GET /
    http-check expect status 200

    # Session persistence (sticky sessions)
    cookie SERVERID insert indirect nocache

    server wallix1 192.168.10.21:443 check ssl verify none cookie wallix1
    server wallix2 192.168.10.22:443 check ssl verify none cookie wallix2

# WALLIX SSH Proxy Frontend
frontend wallix_ssh
    bind 192.168.10.100:22
    mode tcp
    default_backend wallix_ssh_backend

backend wallix_ssh_backend
    mode tcp
    balance leastconn
    option tcp-check

    server wallix1 192.168.10.21:22 check
    server wallix2 192.168.10.22:22 check

# WALLIX RDP Proxy Frontend
frontend wallix_rdp
    bind 192.168.10.100:3389
    mode tcp
    default_backend wallix_rdp_backend

backend wallix_rdp_backend
    mode tcp
    balance leastconn
    option tcp-check

    server wallix1 192.168.10.21:3389 check
    server wallix2 192.168.10.22:3389 check
```

### Step 4.3: Generate Self-Signed Certificate (for lab)

```bash
# Create certificate directory
mkdir -p /etc/haproxy/certs

# Generate self-signed certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/haproxy/certs/wallix.key \
    -out /etc/haproxy/certs/wallix.crt \
    -subj "/C=US/ST=Lab/L=Lab/O=Company/CN=pam.company.local"

# Combine for HAProxy
cat /etc/haproxy/certs/wallix.crt /etc/haproxy/certs/wallix.key > /etc/haproxy/certs/wallix.pem
chmod 600 /etc/haproxy/certs/wallix.pem

# Restart HAProxy
systemctl restart haproxy
systemctl enable haproxy
```

### Step 4.4: Configure Keepalived (Primary)

**Edit /etc/keepalived/keepalived.conf:**
```conf
vrrp_script chk_haproxy {
    script "/usr/bin/killall -0 haproxy"
    interval 2
    weight 2
}

vrrp_instance VI_1 {
    state MASTER
    interface ens192
    virtual_router_id 51
    priority 101
    advert_int 1

    authentication {
        auth_type PASS
        auth_pass KeepAlive2024!
    }

    virtual_ipaddress {
        192.168.10.100/24
    }

    track_script {
        chk_haproxy
    }
}
```

**Start Keepalived:**
```bash
systemctl restart keepalived
systemctl enable keepalived

# Verify VIP is assigned
ip addr show ens192 | grep 192.168.10.100
```

### Step 4.5: Deploy and Configure HAProxy-2

**Repeat Step 4.1-4.3 with these changes:**
```
Hostname: haproxy2.company.local
IP: 192.168.10.12

Keepalived config changes:
  state BACKUP
  priority 100
```

**Test Failover:**
```bash
# On HAProxy-1, stop HAProxy
systemctl stop haproxy

# On HAProxy-2, verify VIP moved
ip addr show ens192 | grep 192.168.10.100
# Should now show on HAProxy-2

# Restart HAProxy-1
systemctl start haproxy
# VIP should move back to HAProxy-1
```

---

## Phase 5: WALLIX Bastion HA Cluster (120 minutes)

### Step 5.1: Deploy WALLIX Bastion-1

**VM Specifications:**
```
Hostname: wallix1.company.local
OS: Debian 12
vCPU: 8
RAM: 16 GB
Disk 1: 100 GB (OS)
Disk 2: 200 GB (Data)
Network 1: VLAN 10 (192.168.10.21)
Network 2: VLAN 20 (192.168.20.21) - for target access
```

**Base Installation:**
```bash
# Set hostname
hostnamectl set-hostname wallix1.company.local

# Configure Management Network (VLAN 10)
cat > /etc/network/interfaces << 'EOF'
auto lo
iface lo inet loopback

# Management Interface
auto ens192
iface ens192 inet static
    address 192.168.10.21/24
    gateway 192.168.10.1
    dns-nameservers 192.168.10.40
    dns-search company.local

# Target Network Interface
auto ens224
iface ens224 inet static
    address 192.168.20.21/24
EOF

systemctl restart networking
```

**Install WALLIX Bastion:**
```bash
# Follow official installation guide
# Download from: https://support.wallix.com

# Example installation (version may vary)
wget https://download.wallix.com/bastion_12.1.x_amd64.deb
dpkg -i bastion_12.1.x_amd64.deb

# Initial configuration
wabadmin setup
# Follow prompts:
#   - Admin password: WallixAdmin2024!
#   - Organization: Company Lab
#   - License: (upload your lab license)
```

### Step 5.2: Configure PostgreSQL for Replication

**On WALLIX-1 (Primary):**
```bash
# Edit PostgreSQL config
cat >> /etc/postgresql/15/main/postgresql.conf << 'EOF'
listen_addresses = '*'
wal_level = replica
max_wal_senders = 10
wal_keep_size = 1GB
hot_standby = on
EOF

# Configure replication authentication
cat >> /etc/postgresql/15/main/pg_hba.conf << 'EOF'
# Replication connections
host    replication     replicator      192.168.10.22/32        md5
EOF

# Create replication user
sudo -u postgres psql << 'EOF'
CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'ReplicaPass2024!';
EOF

# Restart PostgreSQL
systemctl restart postgresql
```

### Step 5.3: Deploy WALLIX Bastion-2

**Repeat Step 5.1 with these changes:**
```
Hostname: wallix2.company.local
IP VLAN 10: 192.168.10.22
IP VLAN 20: 192.168.20.22
```

**Configure as Replica:**
```bash
# Stop PostgreSQL
systemctl stop postgresql

# Remove data directory
rm -rf /var/lib/postgresql/15/main/*

# Create base backup from primary
sudo -u postgres pg_basebackup -h 192.168.10.21 -D /var/lib/postgresql/15/main \
    -U replicator -P -v -R -X stream -C -S wallix2_slot

# Create standby signal
touch /var/lib/postgresql/15/main/standby.signal

# Start PostgreSQL
systemctl start postgresql

# Verify replication
sudo -u postgres psql -c "SELECT * FROM pg_stat_replication;"
```

### Step 5.4: Configure Pacemaker Cluster

**On both WALLIX-1 and WALLIX-2:**
```bash
# Install Pacemaker and Corosync
apt install -y pacemaker corosync pcs resource-agents

# Set hacluster password (same on both nodes)
echo "hacluster:ClusterPass2024!" | chpasswd

# Start pcsd
systemctl start pcsd
systemctl enable pcsd
```

**On WALLIX-1 only:**
```bash
# Authenticate nodes
pcs host auth wallix1.company.local wallix2.company.local \
    -u hacluster -p ClusterPass2024!

# Create cluster
pcs cluster setup wallix-cluster \
    wallix1.company.local wallix2.company.local

# Start cluster
pcs cluster start --all
pcs cluster enable --all

# Disable STONITH (lab only - use in production)
pcs property set stonith-enabled=false
pcs property set no-quorum-policy=ignore

# Create WALLIX resource
pcs resource create wallix-service systemd:wallix-bastion \
    op monitor interval=30s

# Create PostgreSQL resource
pcs resource create postgresql-service systemd:postgresql \
    op monitor interval=30s

# Set resource constraints
pcs constraint colocation add wallix-service with postgresql-service

# Verify cluster status
pcs status
```

---

## Phase 6: WALLIX RDS Session Manager (45 minutes)

### Step 6.1: Deploy WALLIX RDS VM

**VM Specifications:**
```
Hostname: wallix-rds.company.local
OS: Windows Server 2022
vCPU: 4
RAM: 8 GB
Disk: 80 GB
Network: VLAN 10
IP: 192.168.10.30
```

### Step 6.2: Install RDS Session Manager

**On Windows Server:**

1. **Install WALLIX Session Manager (WAS) component:**
   ```
   Download from WALLIX support portal
   Run installer: WALLIX_Session_Manager_12.x.exe

   Installation settings:
   - Install Path: C:\Program Files\WALLIX\SessionManager
   - Bastion Server: 192.168.10.21 (or use VIP 192.168.10.100)
   - API Key: (generate from WALLIX Bastion Web UI)
   ```

2. **Configure in WALLIX Bastion Web UI:**
   ```
   Login to https://192.168.10.100

   Configuration > Session Managers > Add
   - Name: RDS-SessionMgr
   - Host: 192.168.10.30
   - Type: WALLIX Session Manager
   - Enable: Yes
   ```

---

## Phase 7: WALLIX Integration Configuration (60 minutes)

### Step 7.1: Configure AD Integration in WALLIX

**Web UI: Configuration > Authentication > Domains:**
```
Add Domain:
  - Name: Company-AD
  - Type: Active Directory
  - Domain: company.local
  - LDAP URL: ldap://192.168.10.40:389
  - Base DN: DC=company,DC=local
  - Bind DN: CN=Administrator,CN=Users,DC=company,DC=local
  - Bind Password: (your AD admin password)
  - User Filter: (sAMAccountName={0})
  - Group Filter: (member={0})

Test Connection: Success

Enable Domain: Yes
Set as Default Domain: Yes
```

**Map AD Groups to WALLIX User Groups:**
```
Configuration > User Groups > Add
  - Name: Admins
  - Type: LDAP Group
  - LDAP Group DN: CN=PAM-Admins,OU=PAM-Groups,DC=company,DC=local
  - Profile: Administrator

Configuration > User Groups > Add
  - Name: Engineers
  - Type: LDAP Group
  - LDAP Group DN: CN=PAM-Engineers,OU=PAM-Groups,DC=company,DC=local
  - Profile: User

Configuration > User Groups > Add
  - Name: Auditors
  - Type: LDAP Group
  - LDAP Group DN: CN=PAM-Auditors,OU=PAM-Groups,DC=company,DC=local
  - Profile: Auditor
```

### Step 7.2: Configure FortiAuthenticator MFA

**Web UI: Configuration > Authentication > RADIUS:**
```
Add RADIUS Server:
  - Name: FortiAuth-MFA
  - Primary Server: 192.168.10.50
  - Port: 1812
  - Secret: WallixRadius2024!
  - Timeout: 30 seconds
  - Enable: Yes

Test Connection: Success
```

**Enable MFA for User Groups:**
```
Configuration > User Groups > Admins > Edit
  - Two-Factor Authentication: Required
  - RADIUS Server: FortiAuth-MFA

Configuration > User Groups > Engineers > Edit
  - Two-Factor Authentication: Required
  - RADIUS Server: FortiAuth-MFA
```

### Step 7.3: Configure SSO (Optional)

**For Kerberos SSO:**
```
Configuration > Authentication > Kerberos
  - Realm: COMPANY.LOCAL
  - KDC: 192.168.10.40
  - Admin Server: 192.168.10.40
  - Default Domain: company.local

Create keytab on AD server:
  ktpass -princ HTTP/pam.company.local@COMPANY.LOCAL \
         -mapuser COMPANY\wallix-service \
         -pass ServicePass123! \
         -out wallix.keytab

Upload keytab to WALLIX
```

---

## Phase 8: Target Systems Setup (45 minutes)

### Step 8.1: Deploy Linux Target

**VM Specifications:**
```
Hostname: linux-srv01.company.local
OS: Debian 12
vCPU: 2
RAM: 4 GB
Disk: 40 GB
Network: VLAN 20
IP: 192.168.20.10
```

**Configuration:**
```bash
# Set hostname and IP
hostnamectl set-hostname linux-srv01.company.local

cat > /etc/network/interfaces << 'EOF'
auto lo
iface lo inet loopback

auto ens192
iface ens192 inet static
    address 192.168.20.10/24
    gateway 192.168.20.1
    dns-nameservers 192.168.10.40
    dns-search company.local
EOF

systemctl restart networking

# Join AD domain (optional)
apt install -y realmd sssd sssd-tools adcli krb5-user

realm join -U Administrator company.local

# Create local accounts for testing
useradd -m -s /bin/bash serviceacct
echo 'serviceacct:ServicePass123!' | chpasswd

# Enable SSH
systemctl enable ssh
systemctl start ssh
```

### Step 8.2: Deploy Windows Target

**VM Specifications:**
```
Hostname: win-srv01.company.local
OS: Windows Server 2022
vCPU: 4
RAM: 8 GB
Disk: 60 GB
Network: VLAN 20
IP: 192.168.20.20
```

**PowerShell Configuration:**
```powershell
# Set static IP
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 192.168.20.20 `
    -PrefixLength 24 -DefaultGateway 192.168.20.1
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 192.168.10.40

# Set hostname
Rename-Computer -NewName "win-srv01" -Restart

# After reboot, join domain
Add-Computer -DomainName "company.local" -Credential (Get-Credential) -Restart

# Enable RDP
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' `
    -Name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
```

### Step 8.3: Add Targets to WALLIX

**Web UI: Configuration > Devices:**
```
Add Device:
  - Name: linux-srv01
  - Host: 192.168.20.10
  - Description: Linux target server
  - Domain: Company-Servers (create if needed)

Add Service:
  - Type: SSH
  - Port: 22

Add Account:
  - Account Name: serviceacct
  - Login: serviceacct
  - Auto-rotation: Enabled
  - Password: ServicePass123!

---

Add Device:
  - Name: win-srv01
  - Host: 192.168.20.20
  - Description: Windows RDP server
  - Domain: Company-Servers

Add Service:
  - Type: RDP
  - Port: 3389

Add Account:
  - Account Name: Administrator
  - Login: company.local\Administrator
  - Auto-rotation: Enabled
```

---

## Phase 9: Testing and Validation (60 minutes)

### Test 1: User Authentication with MFA

**Steps:**
1. Navigate to https://pam.company.local (HAProxy VIP)
2. Login as `jadmin@company.local`
3. Enter AD password: `UserP@ss123!`
4. Enter FortiToken code from mobile app
5. Verify successful login

**Expected Result:** ✓ User authenticated with MFA

---

### Test 2: HA Failover

**Steps:**
```bash
# On WALLIX-1
systemctl stop wallix-bastion

# Verify cluster failover
pcs status
# Should show wallix-service running on wallix2

# On HAProxy-1
systemctl stop haproxy

# Verify VIP moved to HAProxy-2
ip addr show | grep 192.168.10.100
```

**Expected Result:** ✓ Services failed over automatically

---

### Test 3: SSH Session Through WALLIX

**Steps:**
1. Login to WALLIX as `jengineer@company.local`
2. Navigate to My Authorizations
3. Select linux-srv01 / serviceacct
4. Launch SSH session
5. Run commands and verify recording

**Expected Result:** ✓ Session recorded and accessible in audit logs

---

### Test 4: RDP Session via RDS

**Steps:**
1. Login to WALLIX as `jadmin@company.local`
2. Select win-srv01 / Administrator
3. Launch RDP session
4. Verify connection through Session Manager
5. Perform actions and close session

**Expected Result:** ✓ RDP session proxied through WALLIX RDS

---

### Test 5: Password Rotation

**Web UI Steps:**
```
Configuration > Accounts > serviceacct@linux-srv01
- Click "Rotate Now"
- Verify new password generated
- Test login with new password works
```

**Expected Result:** ✓ Password rotated successfully

---

## Production Readiness Checklist

### Security

- [ ] Replace self-signed certificates with valid SSL certs
- [ ] Enable STONITH in Pacemaker (production clusters)
- [ ] Configure firewall rules between VLANs
- [ ] Enable audit logging to SIEM
- [ ] Implement backup strategy for all VMs
- [ ] Configure log retention policies
- [ ] Enable session recording for all protocols
- [ ] Review and harden SSH/RDP configurations

### High Availability

- [ ] Test manual failover procedures
- [ ] Test automated failover scenarios
- [ ] Document RTO/RPO requirements
- [ ] Configure monitoring and alerting
- [ ] Set up backup HAProxy pair
- [ ] Configure database backup replication
- [ ] Test disaster recovery procedures

### Integration

- [ ] Verify AD group synchronization
- [ ] Test MFA for all user groups
- [ ] Validate RADIUS accounting
- [ ] Configure session recording retention
- [ ] Test password rotation schedules
- [ ] Verify LDAP connection resilience
- [ ] Configure email notifications

### Monitoring

- [ ] Set up health checks for all services
- [ ] Configure Prometheus exporters
- [ ] Create Grafana dashboards
- [ ] Set up alerting (email, Slack, PagerDuty)
- [ ] Monitor disk space on all VMs
- [ ] Track session connection metrics
- [ ] Monitor HAProxy backend health

---

## Network Diagram with IP Addresses

```
+===============================================================================+
|  VLAN 10 (Management) - 192.168.10.0/24                                       |
+===============================================================================+
|                                                                               |
|  .11        .12         .100 (VIP)                                            |
|  HAProxy-1  HAProxy-2   Keepalived                                            |
|      │          │            │                                                |
|      └──────────┴────────────┘                                                |
|                 │                                                             |
|        ┌────────┴────────┐                                                    |
|        │                 │                                                    |
|      .21              .22                                                     |
|   WALLIX-1        WALLIX-2                                                    |
|   (Primary)       (Secondary)                                                 |
|                                                                               |
|      .30              .40              .50                                    |
|   WALLIX RDS      Active Directory   FortiAuth                                |
|                                                                               |
+===============================================================================+
|  VLAN 20 (Targets) - 192.168.20.0/24                                          |
+===============================================================================+
|                                                                               |
|    .10            .20            .30            .40                           |
|  Linux-srv01   Win-srv01      OT-Simulator   Network-Device                  |
|                                                                               |
+===============================================================================+
```

---

## Troubleshooting

### Issue: Cannot access HAProxy VIP

```bash
# Check Keepalived status
systemctl status keepalived

# Verify VIP assignment
ip addr show | grep 192.168.10.100

# Check VRRP communication
tcpdump -i ens192 vrrp

# View Keepalived logs
journalctl -u keepalived -f
```

### Issue: AD authentication fails

```bash
# On WALLIX, test LDAP connection
ldapsearch -x -H ldap://192.168.10.40 -D "CN=Administrator,CN=Users,DC=company,DC=local" \
    -W -b "DC=company,DC=local" "(sAMAccountName=jadmin)"

# Check WALLIX logs
tail -f /var/log/wallix/authentication.log

# Verify DNS resolution
nslookup company.local 192.168.10.40
```

### Issue: MFA not working

```bash
# On WALLIX, test RADIUS
radtest jadmin UserP@ss123! 192.168.10.50 0 WallixRadius2024!

# Check FortiAuthenticator logs
# Web UI > Log & Report > Authentication Log

# Verify RADIUS secret matches
# FortiAuth and WALLIX must have same secret
```

### Issue: Cluster failover not working

```bash
# Check cluster status
pcs status

# Verify corosync communication
corosync-cfgtool -s

# Check resource status
pcs resource show

# Test manual failover
pcs resource move wallix-service wallix2.company.local
```

---

## Next Steps

After completing this lab:

1. **Implement monitoring**: [Monitoring Guide](../../docs/pam/11-monitoring-observability/README.md)
2. **Configure advanced features**: [Best Practices](../../docs/pam/13-best-practices/README.md)
3. **Test disaster recovery**: [DR Guide](../../docs/pam/39-disaster-recovery/README.md)
4. **Production deployment**: [Install Guide](../../install/README.md)

---

## Bill of Materials (BOM)

| Component | Quantity | CPU | RAM | Storage | Purpose |
|-----------|----------|-----|-----|---------|---------|
| HAProxy | 2 | 2 | 4 GB | 20 GB | Load balancing |
| WALLIX Bastion | 2 | 8 | 16 GB | 300 GB | PAM cluster |
| WALLIX RDS | 1 | 4 | 8 GB | 80 GB | Session manager |
| Active Directory | 1 | 4 | 8 GB | 80 GB | User directory |
| FortiAuthenticator | 1 | 2 | 4 GB | 40 GB | MFA |
| Linux Targets | 2 | 2 | 4 GB | 40 GB | Test servers |
| Windows Targets | 1 | 4 | 8 GB | 60 GB | RDP server |
| OT Simulator | 1 | 2 | 4 GB | 40 GB | PLC/SCADA sim |
| **Total** | **11** | **36** | **68 GB** | **700 GB** | |

---

<p align="center">
  <strong>Production-Like Lab Setup Complete</strong><br/>
  <sub>HA • Load Balancing • MFA • Active Directory • 11 VMs</sub>
</p>
