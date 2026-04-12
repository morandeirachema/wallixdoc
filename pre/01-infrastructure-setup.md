# 01 - Infrastructure Setup

## VM Provisioning for Pre-Production Lab

This guide covers provisioning all 12 VMs for the pre-production lab environment. The lab simulates one site of the production architecture using 4 VLANs (Management, DMZ, Cyber, Targets). Fortigate handles inter-VLAN routing.

---

## Prerequisites

### VMware vSphere/ESXi Environment

| Component | Requirement |
|-----------|-------------|
| **Hypervisor** | VMware vSphere 8.0+ or ESXi 8.0+ |
| **vCenter Server** | Recommended for centralized VM management |
| **Storage** | VMFS or NFS datastore with at least 1.2TB free space |
| **Network** | Distributed vSwitch (recommended) or Standard vSwitch |
| **ESXi Hosts** | 1+ hosts (2 recommended for resilience) |

### Templates and Images

- Debian 12 (Bookworm) OVA template or ISO
- Ubuntu 22.04 LTS ISO
- Windows Server 2022 ISO
- FortiAuthenticator 6.4+ OVA (from Fortinet Support Portal: https://support.fortinet.com)

### Network VLANs

4 VLANs configured with port groups:
- VLAN 100: Management (10.10.0.0/24)
- VLAN 110: DMZ (10.10.1.x)
- VLAN 120: Cyber (10.10.1.x)
- VLAN 130: Targets (10.10.2.0/24)

Note: DMZ (VLAN 110) and Cyber (VLAN 120) share the 10.10.1.x range but are separate VLANs. Fortigate performs inter-VLAN routing between them.

---

## Network Configuration

### VMware vSwitch Setup

#### Option 1: Distributed vSwitch (Recommended)

```bash
# Create Distributed vSwitch via vCenter
# Navigate to: Networking > New Distributed Switch

Name: LAB-DVS
Version: 8.0.0 or later
Number of uplinks: 2 (for redundancy)

# Create Port Groups for each VLAN:
# - LAB-Management   (VLAN 100)
# - LAB-DMZ          (VLAN 110)
# - LAB-Cyber        (VLAN 120)
# - LAB-Targets      (VLAN 130)

# Port Group Security Settings:
Promiscuous Mode: Reject
MAC Address Changes: Reject
Forged Transmits: Reject
```

#### Option 2: Standard vSwitch (Alternative)

```bash
# Create via ESXi Host Client or vSphere CLI
esxcli network vswitch standard add --vswitch-name=vSwitch1
esxcli network vswitch standard uplink add --uplink-name=vmnic1 --vswitch-name=vSwitch1

# Add port groups for each VLAN
esxcli network vswitch standard portgroup add \
  --portgroup-name="LAB-Management" --vswitch-name=vSwitch1
esxcli network vswitch standard portgroup set \
  --portgroup-name="LAB-Management" --vlan-id=100

esxcli network vswitch standard portgroup add \
  --portgroup-name="LAB-DMZ" --vswitch-name=vSwitch1
esxcli network vswitch standard portgroup set \
  --portgroup-name="LAB-DMZ" --vlan-id=110

esxcli network vswitch standard portgroup add \
  --portgroup-name="LAB-Cyber" --vswitch-name=vSwitch1
esxcli network vswitch standard portgroup set \
  --portgroup-name="LAB-Cyber" --vlan-id=120

esxcli network vswitch standard portgroup add \
  --portgroup-name="LAB-Targets" --vswitch-name=vSwitch1
esxcli network vswitch standard portgroup set \
  --portgroup-name="LAB-Targets" --vlan-id=130
```

### VLAN Design

| VLAN ID | Name | Subnet | Gateway | Purpose |
|---------|------|--------|---------|---------|
| 100 | Management | 10.10.0.0/24 | 10.10.0.1 | Wazuh SIEM, Prometheus/Grafana |
| 110 | DMZ | 10.10.1.x | 10.10.1.1 | HAProxy, WALLIX Bastion, WALLIX RDS |
| 120 | Cyber | 10.10.1.x | 10.10.1.1 | FortiAuthenticator, AD DC |
| 130 | Targets | 10.10.2.0/24 | 10.10.2.1 | Windows Server 2022, RHEL targets |

### DNS Configuration

Create DNS records on dc-lab (lab.local):

```
; Forward Zone: lab.local
siem-lab          A     10.10.0.10
monitor-lab       A     10.10.0.20
haproxy-1         A     10.10.1.5
haproxy-2         A     10.10.1.6
wallix            A     10.10.1.100   ; HAProxy VIP
wallix-bastion    A     10.10.1.11
wallix-rds        A     10.10.1.30
fortiauth         A     10.10.1.50
dc-lab            A     10.10.1.60
win-srv-01        A     10.10.2.10
win-srv-02        A     10.10.2.11
rhel10-srv        A     10.10.2.20
rhel9-srv         A     10.10.2.21
```

---

## VM Specifications

### Management Zone — VLAN 100, 10.10.0.0/24

```
+===============================================================================+
|  SIEM SERVER SPECIFICATION                                                    |
+===============================================================================+
|                                                                               |
|  Name:        siem-lab                                                        |
|  OS:          Ubuntu 22.04 LTS                                                |
|  IP:          10.10.0.10/24  (VLAN 100 - Management)                         |
|                                                                               |
|  COMPUTE                          STORAGE                                     |
|  -------                          -------                                     |
|  vCPU:     4                      OS Disk:    100 GB                          |
|  RAM:      16 GB                  Data Disk:  400 GB (logs)                   |
|                                                                               |
|  STACK                                                                        |
|  -----                                                                        |
|  - Wazuh SIEM (manager + indexer + dashboard)                                 |
|                                                                               |
+===============================================================================+
```

```
+===============================================================================+
|  OBSERVABILITY SPECIFICATION                                                  |
+===============================================================================+
|                                                                               |
|  Name:        monitor-lab                                                     |
|  OS:          Ubuntu 22.04 LTS                                                |
|  IP:          10.10.0.20/24  (VLAN 100 - Management)                         |
|                                                                               |
|  COMPUTE                          STORAGE                                     |
|  -------                          -------                                     |
|  vCPU:     2                      OS Disk:    100 GB                          |
|  RAM:      8 GB                                                               |
|                                                                               |
|  STACK                                                                        |
|  -----                                                                        |
|  - Prometheus (metrics collection)                                            |
|  - Grafana (dashboards)                                                       |
|  - Alertmanager (alerts)                                                      |
|                                                                               |
+===============================================================================+
```

### DMZ Zone — VLAN 110, 10.10.1.x

```
+===============================================================================+
|  HAPROXY SPECIFICATION (x2 nodes)                                             |
+===============================================================================+
|                                                                               |
|  haproxy-1:  10.10.1.5/24   (MASTER, priority 101)                           |
|  haproxy-2:  10.10.1.6/24   (BACKUP, priority 100)                           |
|  VIP:        10.10.1.100    (Keepalived VRRP, Active-Passive)                 |
|  OS:         Debian 12                                                        |
|                                                                               |
|  COMPUTE                          STORAGE                                     |
|  -------                          -------                                     |
|  vCPU:     2                      OS Disk:    20 GB                           |
|  RAM:      4 GB                                                               |
|                                                                               |
+===============================================================================+
```

```
+===============================================================================+
|  WALLIX BASTION SPECIFICATION (single node)                                   |
+===============================================================================+
|                                                                               |
|  Name:        wallix-bastion                                                  |
|  OS:          WALLIX Bastion 12.1.x HW Appliance                             |
|  IP:          10.10.1.11/24  (VLAN 110 - DMZ)                                |
|                                                                               |
|  COMPUTE                          STORAGE                                     |
|  -------                          -------                                     |
|  vCPU:     4                      OS Disk:    50 GB                           |
|  RAM:      16 GB                  Data Disk:  150 GB                          |
|                                                                               |
|  NOTE: Single node — no bastion-replication, no MariaDB HA cluster           |
|                                                                               |
+===============================================================================+
```

```
+===============================================================================+
|  WALLIX RDS SPECIFICATION                                                     |
+===============================================================================+
|                                                                               |
|  Name:        wallix-rds                                                      |
|  OS:          Windows Server 2022                                             |
|  IP:          10.10.1.30/24  (VLAN 110 - DMZ)                                |
|                                                                               |
|  COMPUTE                          STORAGE                                     |
|  -------                          -------                                     |
|  vCPU:     4                      OS Disk:    100 GB                          |
|  RAM:      8 GB                                                               |
|                                                                               |
|  ROLES                                                                        |
|  -----                                                                        |
|  - WALLIX RDS (RemoteApp / RDP session manager)                               |
|  - Remote Desktop Services role                                               |
|                                                                               |
+===============================================================================+
```

### Cyber Zone — VLAN 120, 10.10.1.x

```
+===============================================================================+
|  FORTIAUTHENTICATOR SPECIFICATION (single node)                               |
+===============================================================================+
|                                                                               |
|  Name:        fortiauth                                                       |
|  OS:          FortiAuthenticator 6.4+                                        |
|  IP:          10.10.1.50/24  (VLAN 120 - Cyber)                              |
|                                                                               |
|  COMPUTE                          STORAGE                                     |
|  -------                          -------                                     |
|  vCPU:     2                      OS Disk:    40 GB                           |
|  RAM:      4 GB                                                               |
|                                                                               |
|  NOTE: Single node, no HA pair. TOTP only (no Push notifications).           |
|  Direct LDAP access to dc-lab (same Cyber VLAN, no inter-VLAN routing).      |
|                                                                               |
+===============================================================================+
```

```
+===============================================================================+
|  ACTIVE DIRECTORY SPECIFICATION                                               |
+===============================================================================+
|                                                                               |
|  Name:        dc-lab                                                          |
|  OS:          Windows Server 2022                                             |
|  IP:          10.10.1.60/24  (VLAN 120 - Cyber)                              |
|                                                                               |
|  COMPUTE                          STORAGE                                     |
|  -------                          -------                                     |
|  vCPU:     2                      OS Disk:    60 GB                           |
|  RAM:      4 GB                                                               |
|                                                                               |
|  ROLES                                                                        |
|  -----                                                                        |
|  - Active Directory Domain Services                                           |
|  - DNS Server                                                                 |
|  - Certificate Services (for LDAPS)                                           |
|                                                                               |
|  Domain: LAB.LOCAL                                                            |
|  NOTE: Bastion (DMZ) reaches AD via Fortigate inter-VLAN routing.            |
|        FortiAuth (same Cyber VLAN) reaches AD directly.                      |
|                                                                               |
+===============================================================================+
```

### Targets Zone — VLAN 130, 10.10.2.0/24

```
+===============================================================================+
|  TEST TARGETS — VLAN 130 (10.10.2.0/24)                                      |
+===============================================================================+
|                                                                               |
|  WINDOWS SERVER 2022 — GENERAL TARGET (RDP/WinRM)                            |
|  -------------------------------------------------                           |
|  Name:    win-srv-01                                                          |
|  IP:      10.10.2.10/24                                                      |
|  vCPU:    2 / RAM: 8 GB / Disk: 60 GB                                        |
|                                                                               |
|  WINDOWS SERVER 2022 — SQL SERVER TARGET (RDP/WinRM)                         |
|  ----------------------------------------------------                        |
|  Name:    win-srv-02                                                          |
|  IP:      10.10.2.11/24                                                      |
|  vCPU:    4 / RAM: 16 GB / Disk: 100 GB                                      |
|                                                                               |
|  RHEL 10 — LINUX APP SERVER (SSH)                                            |
|  ----------------------------------                                           |
|  Name:    rhel10-srv                                                          |
|  IP:      10.10.2.20/24                                                      |
|  vCPU:    2 / RAM: 4 GB / Disk: 40 GB                                        |
|                                                                               |
|  RHEL 9 — LEGACY LINUX SERVER (SSH)                                          |
|  ------------------------------------                                         |
|  Name:    rhel9-srv                                                           |
|  IP:      10.10.2.21/24                                                      |
|  vCPU:    2 / RAM: 4 GB / Disk: 40 GB                                        |
|                                                                               |
+===============================================================================+
```

---

## VM Inventory Summary

| VM Name | VLAN | IP Address | OS | Resources |
|---------|------|------------|-----|-----------|
| `siem-lab` | 100 (Mgmt) | 10.10.0.10 | Ubuntu 22.04 | 4 vCPU, 16GB, 500GB |
| `monitor-lab` | 100 (Mgmt) | 10.10.0.20 | Ubuntu 22.04 | 2 vCPU, 8GB, 100GB |
| `haproxy-1` | 110 (DMZ) | 10.10.1.5 | Debian 12 | 2 vCPU, 4GB, 20GB |
| `haproxy-2` | 110 (DMZ) | 10.10.1.6 | Debian 12 | 2 vCPU, 4GB, 20GB |
| `wallix-bastion` | 110 (DMZ) | 10.10.1.11 | WALLIX 12.1.x | 4 vCPU, 16GB, 200GB |
| `wallix-rds` | 110 (DMZ) | 10.10.1.30 | Windows Server 2022 | 4 vCPU, 8GB, 100GB |
| `fortiauth` | 120 (Cyber) | 10.10.1.50 | FortiAuthenticator 6.4+ | 2 vCPU, 4GB, 40GB |
| `dc-lab` | 120 (Cyber) | 10.10.1.60 | Windows Server 2022 | 2 vCPU, 4GB, 60GB |
| `win-srv-01` | 130 (Targets) | 10.10.2.10 | Windows Server 2022 | 2 vCPU, 8GB, 60GB |
| `win-srv-02` | 130 (Targets) | 10.10.2.11 | Windows Server 2022 | 4 vCPU, 16GB, 100GB |
| `rhel10-srv` | 130 (Targets) | 10.10.2.20 | RHEL 10 | 2 vCPU, 4GB, 40GB |
| `rhel9-srv` | 130 (Targets) | 10.10.2.21 | RHEL 9 | 2 vCPU, 4GB, 40GB |

**Total: 12 VMs**

---

## Provisioning Steps

### Step 1: Create VMs on VMware vSphere/ESXi

#### Method 1: Using govc CLI (Recommended for Automation)

```bash
# Install govc (VMware vSphere CLI)
# Download from: https://github.com/vmware/govmomi/releases

# Set environment variables
export GOVC_URL=vcenter.company.com
export GOVC_USERNAME=administrator@vsphere.local
export GOVC_PASSWORD=YourPassword
export GOVC_INSECURE=true
export GOVC_DATACENTER=Datacenter1
export GOVC_DATASTORE=Datastore1
export GOVC_RESOURCE_POOL=/Datacenter1/host/Cluster1/Resources

# --- Management VLAN 100 ---

# siem-lab (Wazuh SIEM)
govc vm.create -m 16384 -c 4 -disk 100GB -disk.controller pvscsi \
  -net.adapter vmxnet3 -net "LAB-Management" -on=false siem-lab
govc vm.disk.create -vm siem-lab -size 400GB -name data

# monitor-lab (Prometheus + Grafana)
govc vm.create -m 8192 -c 2 -disk 100GB -disk.controller pvscsi \
  -net.adapter vmxnet3 -net "LAB-Management" -on=false monitor-lab

# --- DMZ VLAN 110 ---

# haproxy-1 (HAProxy Primary)
govc vm.create -m 4096 -c 2 -disk 20GB -disk.controller pvscsi \
  -net.adapter vmxnet3 -net "LAB-DMZ" -on=false haproxy-1

# haproxy-2 (HAProxy Backup)
govc vm.create -m 4096 -c 2 -disk 20GB -disk.controller pvscsi \
  -net.adapter vmxnet3 -net "LAB-DMZ" -on=false haproxy-2

# wallix-bastion (single node)
govc vm.create -m 16384 -c 4 -disk 50GB -disk.controller pvscsi \
  -net.adapter vmxnet3 -net "LAB-DMZ" -on=false wallix-bastion
govc vm.disk.create -vm wallix-bastion -size 150GB -name data

# wallix-rds (Windows RDS)
govc vm.create -m 8192 -c 4 -disk 100GB -disk.controller pvscsi \
  -net.adapter vmxnet3 -net "LAB-DMZ" -on=false wallix-rds

# --- Cyber VLAN 120 ---

# fortiauth (FortiAuthenticator - single node, TOTP only)
# Note: Use OVA import for FortiAuthenticator
govc import.ova \
  -name=fortiauth \
  -ds=Datastore1 \
  -net="LAB-Cyber" \
  -pool=/Datacenter1/host/Cluster1/Resources \
  FortiAuthenticator_VM64.ova
govc vm.change -vm fortiauth -c 2 -m 4096

# dc-lab (Active Directory DC)
govc vm.create -m 4096 -c 2 -disk 60GB -disk.controller pvscsi \
  -net.adapter vmxnet3 -net "LAB-Cyber" -on=false dc-lab

# --- Targets VLAN 130 ---

# win-srv-01 (General Windows target)
govc vm.create -m 8192 -c 2 -disk 60GB -disk.controller pvscsi \
  -net.adapter vmxnet3 -net "LAB-Targets" -on=false win-srv-01

# win-srv-02 (SQL Server target)
govc vm.create -m 16384 -c 4 -disk 100GB -disk.controller pvscsi \
  -net.adapter vmxnet3 -net "LAB-Targets" -on=false win-srv-02

# rhel10-srv (RHEL 10 app server)
govc vm.create -m 4096 -c 2 -disk 40GB -disk.controller pvscsi \
  -net.adapter vmxnet3 -net "LAB-Targets" -on=false rhel10-srv

# rhel9-srv (RHEL 9 legacy server)
govc vm.create -m 4096 -c 2 -disk 40GB -disk.controller pvscsi \
  -net.adapter vmxnet3 -net "LAB-Targets" -on=false rhel9-srv

# Verify all VMs created
govc ls /Datacenter1/vm
```

#### Method 2: Using PowerCLI (Windows/PowerShell)

```powershell
# Install VMware PowerCLI
Install-Module -Name VMware.PowerCLI -Scope CurrentUser

# Connect to vCenter
Connect-VIServer -Server vcenter.company.com -User administrator@vsphere.local -Password YourPassword

$datastore = Get-Datastore -Name "Datastore1"
$host1     = Get-Cluster "Cluster1" | Get-VMHost | Select-Object -First 1

# wallix-bastion (single node, DMZ VLAN 110)
$bastion = New-VM -Name "wallix-bastion" `
  -VMHost $host1 -Datastore $datastore `
  -DiskGB 50 -DiskStorageFormat Thin `
  -MemoryGB 16 -NumCpu 4 `
  -GuestId debian11_64Guest `
  -NetworkName "LAB-DMZ"
New-HardDisk -VM $bastion -CapacityGB 150 -StorageFormat Thin

# fortiauth (Cyber VLAN 120) - use OVA import via GUI
# dc-lab (Cyber VLAN 120)
New-VM -Name "dc-lab" `
  -VMHost $host1 -Datastore $datastore `
  -DiskGB 60 -DiskStorageFormat Thin `
  -MemoryGB 4 -NumCpu 2 `
  -GuestId windows2022srv_64Guest `
  -NetworkName "LAB-Cyber"

# Verify
Get-VM | Format-Table Name, PowerState, NumCpu, MemoryGB
```

#### Method 3: vCenter Web UI (Manual)

```
For each VM, use New Virtual Machine wizard:
- Compatibility: ESXi 8.0 or later
- Guest OS Family: Linux (Debian 12) or Windows
- Assign to the correct port group (LAB-Management / LAB-DMZ / LAB-Cyber / LAB-Targets)
- SCSI Controller: VMware Paravirtual
- Network adapter: VMXNET3
```

---

### Step 2: Base OS Installation

#### Debian 12 (haproxy-1, haproxy-2)

```bash
# During install: hostname haproxy-1, domain lab.local, SSH server only

# After install, configure network (haproxy-1):
cat > /etc/network/interfaces << 'EOF'
auto lo
iface lo inet loopback

auto ens192
iface ens192 inet static
    address 10.10.1.5/24
    gateway 10.10.1.1
    dns-nameservers 10.10.1.60
    dns-search lab.local
EOF
systemctl restart networking

hostnamectl set-hostname haproxy-1.lab.local

cat >> /etc/hosts << 'EOF'
10.10.0.10  siem-lab.lab.local siem-lab
10.10.0.20  monitor-lab.lab.local monitor-lab
10.10.1.5   haproxy-1.lab.local haproxy-1
10.10.1.6   haproxy-2.lab.local haproxy-2
10.10.1.11  wallix-bastion.lab.local wallix-bastion
10.10.1.100 wallix.lab.local wallix
10.10.1.60  dc-lab.lab.local dc-lab
EOF

apt update && apt upgrade -y
```

#### WALLIX Bastion Node (wallix-bastion)

```bash
# Installed from WALLIX Bastion 12.1.x ISO/appliance
# After install, set IP:

cat > /etc/network/interfaces << 'EOF'
auto lo
iface lo inet loopback

auto ens192
iface ens192 inet static
    address 10.10.1.11/24
    gateway 10.10.1.1
    dns-nameservers 10.10.1.60
    dns-search lab.local
EOF
systemctl restart networking

hostnamectl set-hostname wallix-bastion.lab.local

cat >> /etc/hosts << 'EOF'
10.10.0.10  siem-lab.lab.local siem-lab
10.10.0.20  monitor-lab.lab.local monitor-lab
10.10.1.5   haproxy-1.lab.local haproxy-1
10.10.1.6   haproxy-2.lab.local haproxy-2
10.10.1.100 wallix.lab.local wallix
10.10.1.50  fortiauth.lab.local fortiauth
10.10.1.60  dc-lab.lab.local dc-lab
EOF
```

#### Ubuntu 22.04 (siem-lab, monitor-lab)

```bash
# siem-lab (Management VLAN, 10.10.0.10):
cat > /etc/netplan/00-installer-config.yaml << 'EOF'
network:
  version: 2
  ethernets:
    ens192:
      addresses: [10.10.0.10/24]
      routes:
        - to: default
          via: 10.10.0.1
      nameservers:
        addresses: [10.10.1.60]
        search: [lab.local]
EOF
netplan apply

# monitor-lab (Management VLAN, 10.10.0.20):
# Same config, change address to 10.10.0.20
```

---

### Step 3: NTP Configuration

All servers must be time-synchronized. Use the AD DC as the NTP source:

```bash
# On all Linux VMs:
cat > /etc/chrony/chrony.conf << 'EOF'
server dc-lab.lab.local iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
EOF

systemctl restart chrony
chronyc tracking
```

---

### Step 4: VMware Network Verification

```bash
# Verify port group VLAN assignments using govc
export GOVC_URL=vcenter.company.com
export GOVC_USERNAME=administrator@vsphere.local

# List all port groups
govc ls network

# Verify VLAN IDs
govc host.portgroup.info "LAB-Management" | grep VLAN    # Expect: 100
govc host.portgroup.info "LAB-DMZ"        | grep VLAN    # Expect: 110
govc host.portgroup.info "LAB-Cyber"      | grep VLAN    # Expect: 120
govc host.portgroup.info "LAB-Targets"    | grep VLAN    # Expect: 130
```

```powershell
# Via PowerCLI
Get-VDPortgroup | Where-Object {$_.Name -like "LAB-*"} | `
  Format-Table Name, VlanConfiguration, NumPorts
```

---

### Step 5: Connectivity Verification

```bash
# From any management workstation, verify reachability:

# Management zone
ping -c 2 10.10.0.10   # siem-lab
ping -c 2 10.10.0.20   # monitor-lab

# DMZ zone (via routing)
ping -c 2 10.10.1.5    # haproxy-1
ping -c 2 10.10.1.6    # haproxy-2
ping -c 2 10.10.1.100  # HAProxy VIP
ping -c 2 10.10.1.11   # wallix-bastion
ping -c 2 10.10.1.30   # wallix-rds

# Cyber zone (via routing)
ping -c 2 10.10.1.50   # fortiauth
ping -c 2 10.10.1.60   # dc-lab

# Targets zone (via routing)
ping -c 2 10.10.2.10   # win-srv-01
ping -c 2 10.10.2.11   # win-srv-02
ping -c 2 10.10.2.20   # rhel10-srv
ping -c 2 10.10.2.21   # rhel9-srv
```

---

## Storage Layout Reference

```
+===============================================================================+
|  STORAGE ALLOCATION — 12 VMs                                                  |
+===============================================================================+
|                                                                               |
|  Management (VLAN 100)                                                        |
|  siem-lab:        500 GB  (100 OS + 400 logs)                                |
|  monitor-lab:     100 GB                                                      |
|                                                                               |
|  DMZ (VLAN 110)                                                               |
|  haproxy-1:        20 GB                                                      |
|  haproxy-2:        20 GB                                                      |
|  wallix-bastion:  200 GB  (50 OS + 150 data)                                 |
|  wallix-rds:      100 GB                                                      |
|                                                                               |
|  Cyber (VLAN 120)                                                             |
|  fortiauth:        40 GB                                                      |
|  dc-lab:           60 GB                                                      |
|                                                                               |
|  Targets (VLAN 130)                                                           |
|  win-srv-01:       60 GB                                                      |
|  win-srv-02:      100 GB                                                      |
|  rhel10-srv:       40 GB                                                      |
|  rhel9-srv:        40 GB                                                      |
|  -------                                                                      |
|  TOTAL:         1,280 GB (~1.3 TB) + snapshots overhead                      |
|                                                                               |
+===============================================================================+
```

---

*Last updated: April 2026 | WALLIX Bastion 12.1.x | FortiAuthenticator 6.4+*

<p align="center">
  <a href="./README.md">← Overview</a> •
  <a href="./02-active-directory-setup.md">Next: Active Directory Setup →</a>
</p>
