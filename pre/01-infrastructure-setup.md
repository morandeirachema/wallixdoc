# 01 - Infrastructure Setup

## VM Provisioning for Pre-Production Lab

This guide covers provisioning all VMs for the lab environment.

---

## Prerequisites

### VMware vSphere/ESXi Environment

| Component | Requirement |
|-----------|-------------|
| **Hypervisor** | VMware vSphere 7.0+ or ESXi 7.0+ |
| **vCenter Server** | Recommended for centralized VM management and HA features |
| **Storage** | VMFS or NFS datastore with at least 2TB free space |
| **Network** | Distributed vSwitch (recommended) or Standard vSwitch |
| **ESXi Hosts** | 2+ hosts recommended for vSphere HA and DRS |
| **vSphere Licenses** | Standard or Enterprise Plus for HA features |

### Templates and Images

- Debian 12 (Bookworm) OVA template or ISO
- Ubuntu 22.04 LTS ISO
- Windows Server 2022 ISO
- FortiAuthenticator OVA (from Fortinet Support Portal)

### Network VLANs

6 VLANs configured with port groups:
- VLAN 100: Enterprise (10.10.0.0/24)
- VLAN 110: OT DMZ (10.10.1.0/24)
- VLAN 120: Site Operations (10.10.2.0/24)
- VLAN 130: Area Supervisory (10.10.3.0/24)
- VLAN 140: Basic Control (10.10.4.0/24)
- VLAN 150: Process (10.10.5.0/24)

---

## Network Configuration

### VMware vSwitch Setup

#### Option 1: Distributed vSwitch (Recommended)

```bash
# Create Distributed vSwitch via vCenter
# Navigate to: Networking > New Distributed Switch

Name: WALLIX Bastion-DVS
Version: 7.0.0 or later
Number of uplinks: 2 (for redundancy)

# Create Port Groups for each VLAN:
# - WALLIX Bastion-Enterprise (VLAN 100)
# - WALLIX Bastion-OT-DMZ (VLAN 110)
# - WALLIX Bastion-Site-Ops (VLAN 120)
# - WALLIX Bastion-Area-Supervisory (VLAN 130)
# - WALLIX Bastion-Basic-Control (VLAN 140)
# - WALLIX Bastion-Process (VLAN 150)

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
esxcli network vswitch standard portgroup add --portgroup-name="WALLIX Bastion-Enterprise" --vswitch-name=vSwitch1
esxcli network vswitch standard portgroup set --portgroup-name="WALLIX Bastion-Enterprise" --vlan-id=100

esxcli network vswitch standard portgroup add --portgroup-name="WALLIX Bastion-OT-DMZ" --vswitch-name=vSwitch1
esxcli network vswitch standard portgroup set --portgroup-name="WALLIX Bastion-OT-DMZ" --vlan-id=110

# Repeat for other VLANs...
```

### VLAN Setup

| VLAN ID | Name | Subnet | Gateway | Purpose |
|---------|------|--------|---------|---------|
| 100 | Enterprise | 10.10.0.0/24 | 10.10.0.1 | Corporate IT, AD, SIEM |
| 110 | OT DMZ | 10.10.1.0/24 | 10.10.1.1 | WALLIX Bastion, HAProxy, MFA |
| 120 | Site Operations | 10.10.2.0/24 | 10.10.2.1 | SCADA, Engineering WS |
| 130 | Area Supervisory | 10.10.3.0/24 | 10.10.3.1 | HMI Panels, OPC UA |
| 140 | Basic Control | 10.10.4.0/24 | 10.10.4.1 | PLCs, RTUs |
| 150 | Process | 10.10.5.0/24 | 10.10.5.1 | Field devices (simulated) |

### DNS Configuration

Create these DNS records (on AD DC or existing DNS):

```
; Forward Zone: lab.local
dc-lab          A     10.10.1.10
wallix-node1    A     10.10.1.11
wallix-node2    A     10.10.1.12
wallix          A     10.10.1.100   ; VIP
siem-lab        A     10.10.1.50
monitor-lab     A     10.10.1.60
linux-test      A     10.10.2.10
windows-test    A     10.10.2.20
network-test    A     10.10.2.30
plc-sim         A     10.10.3.10
```

---

## VM Specifications

### WALLIX Bastion Nodes (x2)

```
+===============================================================================+
|  WALLIX Bastion NODE SPECIFICATION                                                    |
+===============================================================================+
|                                                                               |
|  Name:        wallix-node1 / wallix-node2                                     |
|  OS:          Debian 12 (Bookworm)                                            |
|                                                                               |
|  COMPUTE                          STORAGE                                     |
|  -------                          -------                                     |
|  vCPU:     4                      OS Disk:    50 GB (SSD)                     |
|  RAM:      16 GB                  Data Disk:  150 GB (SSD)                    |
|                                                                               |
|  NETWORK                                                                      |
|  -------                                                                      |
|  NIC 1:    Management VLAN (10.10.1.0/24)                                     |
|                                                                               |
|  Node 1: 10.10.1.11                                                           |
|  Node 2: 10.10.1.12                                                           |
|  VIP:    10.10.1.100                                                          |
|                                                                               |
+===============================================================================+
```

### Active Directory DC

```
+===============================================================================+
|  ACTIVE DIRECTORY SPECIFICATION                                               |
+===============================================================================+
|                                                                               |
|  Name:        dc-lab                                                          |
|  OS:          Windows Server 2022                                             |
|  IP:          10.10.1.10                                                      |
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
|  - Certificate Services (optional)                                            |
|                                                                               |
|  Domain: LAB.LOCAL                                                            |
|                                                                               |
+===============================================================================+
```

### SIEM Server

```
+===============================================================================+
|  SIEM SPECIFICATION                                                           |
+===============================================================================+
|                                                                               |
|  Name:        siem-lab                                                        |
|  OS:          Ubuntu 22.04 LTS                                                |
|  IP:          10.10.1.50                                                      |
|                                                                               |
|  COMPUTE                          STORAGE                                     |
|  -------                          -------                                     |
|  vCPU:     4                      OS Disk:    100 GB                          |
|  RAM:      16 GB                  Data Disk:  400 GB (logs)                   |
|                                                                               |
|  OPTIONS (choose one)                                                         |
|  -------------------                                                          |
|  - Splunk Enterprise (trial license)                                          |
|  - Elastic Stack (ELK)                                                        |
|  - Wazuh                                                                      |
|                                                                               |
+===============================================================================+
```

### Monitoring Server

```
+===============================================================================+
|  OBSERVABILITY SPECIFICATION                                                  |
+===============================================================================+
|                                                                               |
|  Name:        monitor-lab                                                     |
|  OS:          Ubuntu 22.04 LTS                                                |
|  IP:          10.10.1.60                                                      |
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

### Test Target VMs

```
+===============================================================================+
|  TEST TARGETS                                                                 |
+===============================================================================+
|                                                                               |
|  LINUX TEST (SSH Target)                                                      |
|  -----------------------                                                      |
|  Name:    linux-test                                                          |
|  OS:      Ubuntu 22.04 LTS                                                    |
|  IP:      10.10.2.10                                                          |
|  vCPU:    2 / RAM: 4 GB / Disk: 40 GB                                         |
|                                                                               |
|  WINDOWS TEST (RDP Target)                                                    |
|  -------------------------                                                    |
|  Name:    windows-test                                                        |
|  OS:      Windows Server 2022                                                 |
|  IP:      10.10.2.20                                                          |
|  vCPU:    2 / RAM: 8 GB / Disk: 60 GB                                         |
|                                                                               |
|  NETWORK DEVICE (SSH/Telnet Target)                                           |
|  ----------------------------------                                           |
|  Name:    network-test                                                        |
|  OS:      VyOS 1.4 or pfSense                                                 |
|  IP:      10.10.2.30                                                          |
|  vCPU:    1 / RAM: 2 GB / Disk: 20 GB                                         |
|                                                                               |
|  PLC SIMULATOR (OT Target)                                                    |
|  -------------------------                                                    |
|  Name:    plc-sim                                                             |
|  OS:      Ubuntu 22.04 + OpenPLC/Modbus sim                                   |
|  IP:      10.10.3.10                                                          |
|  vCPU:    1 / RAM: 2 GB / Disk: 20 GB                                         |
|                                                                               |
+===============================================================================+
```

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
export GOVC_INSECURE=true  # Use false for production with valid certs
export GOVC_DATACENTER=Datacenter1
export GOVC_DATASTORE=Datastore1
export GOVC_NETWORK="WALLIX Bastion-OT-DMZ"
export GOVC_RESOURCE_POOL=/Datacenter1/host/Cluster1/Resources

# Create WALLIX Bastion Node 1
govc vm.create \
  -m 16384 \
  -c 4 \
  -disk 50GB \
  -disk.controller pvscsi \
  -net.adapter vmxnet3 \
  -net "WALLIX Bastion-OT-DMZ" \
  -on=false \
  wallix-node1

# Add second disk for data
govc vm.disk.create \
  -vm wallix-node1 \
  -size 150GB \
  -name data

# Create WALLIX Bastion Node 2
govc vm.create \
  -m 16384 \
  -c 4 \
  -disk 50GB \
  -disk.controller pvscsi \
  -net.adapter vmxnet3 \
  -net "WALLIX Bastion-OT-DMZ" \
  -on=false \
  wallix-node2

govc vm.disk.create \
  -vm wallix-node2 \
  -size 150GB \
  -name data

# Create HAProxy Node 1
govc vm.create \
  -m 4096 \
  -c 2 \
  -disk 20GB \
  -disk.controller pvscsi \
  -net.adapter vmxnet3 \
  -net "WALLIX Bastion-OT-DMZ" \
  -on=false \
  haproxy-1

# Create HAProxy Node 2
govc vm.create \
  -m 4096 \
  -c 2 \
  -disk 20GB \
  -disk.controller pvscsi \
  -net.adapter vmxnet3 \
  -net "WALLIX Bastion-OT-DMZ" \
  -on=false \
  haproxy-2

# Verify VMs created
govc ls /Datacenter1/vm
```

#### Method 2: Using PowerCLI (Windows/PowerShell)

```powershell
# Install VMware PowerCLI
Install-Module -Name VMware.PowerCLI -Scope CurrentUser

# Connect to vCenter
Connect-VIServer -Server vcenter.company.com -User administrator@vsphere.local -Password YourPassword

# Get references
$datacenter = Get-Datacenter -Name "Datacenter1"
$cluster = Get-Cluster -Name "Cluster1"
$datastore = Get-Datastore -Name "Datastore1"
$portGroup = Get-VDPortgroup -Name "WALLIX Bastion-OT-DMZ"

# Create WALLIX Bastion Node 1
$vm1 = New-VM -Name "wallix-node1" `
  -VMHost (Get-Cluster "Cluster1" | Get-VMHost | Select-Object -First 1) `
  -Datastore $datastore `
  -DiskGB 50 `
  -DiskStorageFormat Thin `
  -MemoryGB 16 `
  -NumCpu 4 `
  -GuestId debian11_64Guest `
  -NetworkName $portGroup

# Add second disk for data
New-HardDisk -VM $vm1 -CapacityGB 150 -StorageFormat Thin

# Create WALLIX Bastion Node 2
$vm2 = New-VM -Name "wallix-node2" `
  -VMHost (Get-Cluster "Cluster1" | Get-VMHost | Select-Object -First 1) `
  -Datastore $datastore `
  -DiskGB 50 `
  -DiskStorageFormat Thin `
  -MemoryGB 16 `
  -NumCpu 4 `
  -GuestId debian11_64Guest `
  -NetworkName $portGroup

New-HardDisk -VM $vm2 -CapacityGB 150 -StorageFormat Thin

# List all VMs
Get-VM | Where-Object {$_.Name -like "wallix*"} | Format-Table Name, PowerState, NumCpu, MemoryGB
```

#### Method 3: Using vCenter Web UI (Manual)

```
1. Log into vCenter Server (https://vcenter.company.com)
2. Navigate to VMs and Templates
3. Right-click on datacenter/folder > New Virtual Machine
4. Select "Create a new virtual machine"

Configuration for WALLIX Bastion Node 1:
- Name: wallix-node1
- Folder: WALLIX Bastion (create if needed)
- Compute Resource: Select cluster/host
- Storage: Select datastore (VMFS or NFS)
- Compatibility: ESXi 7.0 or later
- Guest OS Family: Linux
- Guest OS Version: Debian GNU/Linux 11 (64-bit)
- CPU: 4 vCPU
- Memory: 16 GB
- New Hard Disk 1: 50 GB (Thin Provision)
- New Hard Disk 2: 150 GB (Thin Provision)
- New Network: WALLIX Bastion-OT-DMZ (VMXNET3 adapter)
- SCSI Controller: VMware Paravirtual

Repeat for wallix-node2 and other VMs.
```

#### Alternative: Using Proxmox (If VMware Not Available)

```bash
# NOTE: VMware vSphere/ESXi is the recommended platform
# Use Proxmox only if VMware is not available in your environment

# Create WALLIX Bastion Node 1
qm create 101 --name wallix-node1 --memory 16384 --cores 4 \
  --net0 virtio,bridge=vmbr0,tag=110 \
  --scsi0 local-lvm:50 \
  --scsi1 local-lvm:150

# Create WALLIX Bastion Node 2
qm create 102 --name wallix-node2 --memory 16384 --cores 4 \
  --net0 virtio,bridge=vmbr0,tag=110 \
  --scsi0 local-lvm:50 \
  --scsi1 local-lvm:150
```

#### Method 4: Using Terraform with vSphere Provider (Infrastructure as Code)

Full Terraform example available in `scripts/provision-vms.sh` directory.

```hcl
# main.tf - VMware vSphere Infrastructure as Code
terraform {
  required_providers {
    vsphere = {
      source  = "hashicorp/vsphere"
      version = "~> 2.0"
    }
  }
}

provider "vsphere" {
  vsphere_server       = "vcenter.company.com"
  user                 = var.vsphere_user
  password             = var.vsphere_password
  allow_unverified_ssl = true  # Set to false for production
}

# Data sources
data "vsphere_datacenter" "dc" {
  name = "Datacenter1"
}

data "vsphere_datastore" "datastore" {
  name          = "Datastore1"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_compute_cluster" "cluster" {
  name          = "Cluster1"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "ot_dmz" {
  name          = "WALLIX Bastion-OT-DMZ"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "debian_template" {
  name          = "debian-12-template"
  datacenter_id = data.vsphere_datacenter.dc.id
}

# WALLIX Bastion Node 1
resource "vsphere_virtual_machine" "wallix_node1" {
  name             = "wallix-node1"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  folder           = "WALLIX Bastion"

  num_cpus = 4
  memory   = 16384
  guest_id = "debian11_64Guest"

  network_interface {
    network_id   = data.vsphere_network.ot_dmz.id
    adapter_type = "vmxnet3"
  }

  disk {
    label            = "os"
    size             = 50
    thin_provisioned = true
  }

  disk {
    label            = "data"
    size             = 150
    unit_number      = 1
    thin_provisioned = true
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.debian_template.id

    customize {
      linux_options {
        host_name = "wallix-node1"
        domain    = "lab.local"
      }

      network_interface {
        ipv4_address = "10.10.1.11"
        ipv4_netmask = 24
      }

      ipv4_gateway    = "10.10.1.1"
      dns_server_list = ["10.10.0.10"]
    }
  }
}

# WALLIX Bastion Node 2
resource "vsphere_virtual_machine" "wallix_node2" {
  name             = "wallix-node2"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  folder           = "WALLIX Bastion"

  num_cpus = 4
  memory   = 16384
  guest_id = "debian11_64Guest"

  network_interface {
    network_id   = data.vsphere_network.ot_dmz.id
    adapter_type = "vmxnet3"
  }

  disk {
    label            = "os"
    size             = 50
    thin_provisioned = true
  }

  disk {
    label            = "data"
    size             = 150
    unit_number      = 1
    thin_provisioned = true
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.debian_template.id

    customize {
      linux_options {
        host_name = "wallix-node2"
        domain    = "lab.local"
      }

      network_interface {
        ipv4_address = "10.10.1.12"
        ipv4_netmask = 24
      }

      ipv4_gateway    = "10.10.1.1"
      dns_server_list = ["10.10.0.10"]
    }
  }
}

# Outputs
output "wallix_node1_ip" {
  value = vsphere_virtual_machine.wallix_node1.default_ip_address
}

output "wallix_node2_ip" {
  value = vsphere_virtual_machine.wallix_node2.default_ip_address
}
```

Deploy with Terraform:

```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Deploy infrastructure
terraform apply -auto-approve

# Verify VMs created
terraform show
```

---

### VMware Storage Configuration

#### Datastore Requirements

```
+===============================================================================+
|  VMWARE STORAGE LAYOUT FOR WALLIX Bastion LAB                                        |
+===============================================================================+
|                                                                               |
|  DATASTORE TYPE: VMFS 6 or NFS                                                |
|  MINIMUM CAPACITY: 2 TB                                                       |
|  RECOMMENDED: VMFS on SSD or NVMe for better performance                      |
|                                                                               |
|  STORAGE ALLOCATION:                                                          |
|  ------------------                                                           |
|  WALLIX Bastion Nodes (2x):         ~400 GB (200 GB each)                             |
|  HAProxy Nodes (2x):        ~40 GB  (20 GB each)                              |
|  Active Directory:          ~60 GB                                            |
|  FortiAuthenticator:        ~40 GB                                            |
|  WALLIX RDS:                ~100 GB                                           |
|  SIEM/Monitoring:           ~600 GB                                           |
|  Test Targets (10+ VMs):    ~500 GB                                           |
|  Snapshots/Overhead:        ~260 GB (recommended 15% overhead)                |
|  ------------------------                                                     |
|  TOTAL:                     ~2 TB                                             |
|                                                                               |
|  THIN PROVISIONING: Recommended to optimize space usage                       |
|  THICK PROVISIONING: Use for production WALLIX Bastion nodes for guaranteed IOPS      |
|                                                                               |
+===============================================================================+
```

#### Storage Best Practices

**For VMware vSphere:**

```bash
# Create dedicated datastore for WALLIX Bastion (if using iSCSI/FC)
# Use Storage DRS for automatic load balancing

# Configure storage policies via vCenter
# Navigate to: Policies and Profiles > VM Storage Policies

Storage Policy: WALLIX Bastion-Production
- Storage Type: VMFS
- Storage Tier: High Performance (SSD/NVMe)
- Encryption: Optional (vSAN encryption or VM encryption)
- Replication: vSphere Replication for DR

# Apply to WALLIX Bastion VMs:
govc vm.change -vm wallix-node1 -storage-policy "WALLIX Bastion-Production"
govc vm.change -vm wallix-node2 -storage-policy "WALLIX Bastion-Production"
```

**NFS Datastore (Alternative):**

```bash
# Add NFS datastore via vCenter
# Navigate to: Storage > New Datastore

Datastore Type: NFS
NFS Version: NFS 4.1 (recommended)
Folder: /export/wallix-lab
Server: nas.company.com
Mount Options: Default

# Mount on all ESXi hosts in cluster
```

#### VM Disk Configuration

**Use VMware Paravirtual SCSI (PVSCSI) for performance:**

```bash
# Configure PVSCSI for new VMs
govc vm.create \
  -m 16384 \
  -c 4 \
  -disk 50GB \
  -disk.controller pvscsi \
  -net.adapter vmxnet3 \
  wallix-node1

# Or via PowerCLI
New-VM -Name "wallix-node1" `
  -HardDiskControllerType ParaVirtual `
  ...
```

**Disk layout for WALLIX Bastion nodes:**

```
SCSI Controller 0 (Paravirtual):
  - Hard Disk 1: 50 GB (OS) - Thin Provisioned
  - Hard Disk 2: 150 GB (Data/Databases) - Thick Provisioned Eager Zeroed

Rationale:
- OS disk can be thin (mostly static)
- Data disk should be thick for consistent IOPS (databases, logs)
- Eager zeroed provides best performance for database workloads
```

---

### Step 2: Base OS Installation

#### Debian 12 for WALLIX Bastion Nodes

```bash
# During installation:
# - Hostname: wallix-node1 (or wallix-node2)
# - Domain: lab.local
# - Root password: (set secure password)
# - Partitioning: Guided - use entire disk with LVM
# - Software: SSH server only

# After installation, configure network:
cat > /etc/network/interfaces << 'EOF'
auto lo
iface lo inet loopback

auto ens192
iface ens192 inet static
    address 10.10.1.11/24      # Use .12 for node2
    gateway 10.10.1.1
    dns-nameservers 10.10.1.10
    dns-search lab.local
EOF

# Set hostname
hostnamectl set-hostname wallix-node1.lab.local

# Configure /etc/hosts
cat >> /etc/hosts << 'EOF'
10.10.1.10  dc-lab.lab.local dc-lab
10.10.1.11  wallix-node1.lab.local wallix-node1
10.10.1.12  wallix-node2.lab.local wallix-node2
10.10.1.100 wallix.lab.local wallix
EOF

# Update system
apt update && apt upgrade -y

# Install prerequisites
apt install -y curl wget gnupg2 ca-certificates lsb-release \
    software-properties-common apt-transport-https \
    ntp ntpdate chrony
```

#### Ubuntu 22.04 for SIEM/Monitor

```bash
# After base install:
# Set static IP
cat > /etc/netplan/00-installer-config.yaml << 'EOF'
network:
  version: 2
  ethernets:
    ens192:
      addresses:
        - 10.10.1.50/24    # Use .60 for monitor-lab
      routes:
        - to: default
          via: 10.10.1.1
      nameservers:
        addresses:
          - 10.10.1.10
        search:
          - lab.local
EOF

netplan apply
```

---

### Step 3: NTP Configuration

All servers must be time-synchronized:

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

#### Verify vSwitch Configuration

```bash
# Using govc CLI
export GOVC_URL=vcenter.company.com
export GOVC_USERNAME=administrator@vsphere.local

# List all port groups
govc ls network

# Verify port group settings
govc host.portgroup.info -json "WALLIX Bastion-OT-DMZ" | jq

# Check VLAN configuration
govc host.portgroup.info "WALLIX Bastion-OT-DMZ" | grep VLAN

# Expected output:
#   VLAN ID: 110
```

**Using PowerCLI:**

```powershell
# Connect to vCenter
Connect-VIServer -Server vcenter.company.com

# List all port groups
Get-VDPortgroup | Where-Object {$_.Name -like "WALLIX Bastion*"} | Format-Table Name, VlanConfiguration, NumPorts

# Verify VM network assignments
Get-VM | Where-Object {$_.Name -like "wallix*"} | Get-NetworkAdapter | Format-Table Parent, Name, NetworkName, Type

# Expected output:
# Parent        Name            NetworkName     Type
# ------        ----            -----------     ----
# wallix-node1  Network adapter WALLIX Bastion-OT-DMZ   Vmxnet3
# wallix-node2  Network adapter WALLIX Bastion-OT-DMZ   Vmxnet3
```

**Verify network adapter type:**

```bash
# Ensure VMXNET3 is used (not E1000)
govc vm.info -json wallix-node1 | jq '.VirtualMachines[].Config.Hardware.Device[] | select(.DeviceInfo.Label | contains("Network")) | .DeviceInfo.Summary'

# Should output: "WALLIX Bastion-OT-DMZ" with VMXNET3 adapter
```

#### Verify VM Connectivity

```bash
# SSH to WALLIX Bastion nodes
ssh root@10.10.1.11

# From WALLIX Bastion nodes, verify all connectivity:

echo "=== VMware Tools Status ==="
systemctl status open-vm-tools
vmware-toolbox-cmd -v

echo "=== Network Interface ==="
ip addr show ens192
# Verify VMXNET3: ethtool -i ens192 | grep driver
# Expected: driver: vmxnet3

echo "=== DNS Resolution ==="
nslookup dc-lab.lab.local
nslookup wallix-node1.lab.local
nslookup wallix-node2.lab.local

echo "=== Ping Tests ==="
ping -c 3 dc-lab.lab.local
ping -c 3 wallix-node2.lab.local    # From node1
ping -c 3 siem-lab.lab.local

echo "=== Port Tests ==="
nc -zv dc-lab.lab.local 636         # LDAPS
nc -zv dc-lab.lab.local 88          # Kerberos
nc -zv siem-lab.lab.local 514       # Syslog

echo "=== MTU Check (should be 1500) ==="
ip link show ens192 | grep mtu

echo "=== Verify Default Gateway ==="
ip route show default
ping -c 3 10.10.1.1    # Gateway
```

#### VMware-Specific Network Tests

```bash
# Test vMotion compatibility (if using vSphere HA)
govc vm.migrate -host=esxi-host2.company.com wallix-node1

# Monitor network stats
govc metric.sample -n 10 wallix-node1 net.usage.average

# Check for network errors
govc vm.info -json wallix-node1 | jq '.VirtualMachines[].Summary.QuickStats.OverallCpuUsage'
```

---

## Infrastructure Checklist

### VMware vSphere Environment

| Check | Command | Expected |
|-------|---------|----------|
| vCenter accessible | Browse to `https://vcenter.company.com` | Login successful |
| Port groups created | `govc ls network` | All 6 VLANs listed |
| Datastore space | `govc datastore.info Datastore1` | >2TB available |
| ESXi hosts online | `govc ls host` | All hosts powered on |
| Templates available | `govc ls vm/templates` | Debian 12, Ubuntu 22.04 templates |

### VM Deployment

| Check | Command | Expected |
|-------|---------|----------|
| VMs created | `govc ls vm/WALLIX Bastion` | All 24 VMs listed |
| VMs powered on | `govc vm.info wallix-node1` | Power state: poweredOn |
| VMXNET3 adapters | `govc vm.info wallix-node1` | Network adapter: VMXNET3 |
| PVSCSI controllers | `govc vm.info wallix-node1` | SCSI: VMware paravirtual |
| VMware Tools running | From VM: `systemctl status open-vm-tools` | Active (running) |

### Network Connectivity

| Check | Command | Expected |
|-------|---------|----------|
| WALLIX Bastion Node 1 reachable | `ping 10.10.1.11` | Success |
| WALLIX Bastion Node 2 reachable | `ping 10.10.1.12` | Success |
| HAProxy 1 reachable | `ping 10.10.1.5` | Success |
| HAProxy 2 reachable | `ping 10.10.1.6` | Success |
| AD DC reachable | `ping 10.10.0.10` | Success |
| FortiAuth reachable | `ping 10.10.1.50` | Success |
| DNS resolution | `nslookup wallix.lab.local` | Returns 10.10.1.100 |
| NTP sync | From VM: `chronyc tracking` | Synchronized |
| Inter-node communication | From node1: `ping wallix-node2` | Success |
| VLAN isolation | From node1: `ping 10.10.4.10` (PLC) | Success (via routing) |

### Storage

| Check | Command | Expected |
|-------|---------|----------|
| Datastore mounted | `govc datastore.info Datastore1` | State: available |
| VM disks present | `govc vm.info wallix-node1` | 2 disks: 50GB + 150GB |
| Disk provisioning | `govc datastore.disk.info` | Thin or thick as configured |
| IOPS performance | From VM: `fio --name=test --rw=randread --bs=4k` | >1000 IOPS |

---

## VMware Quick Reference

### Common govc Commands

```bash
# Environment setup
export GOVC_URL=vcenter.company.com
export GOVC_USERNAME=administrator@vsphere.local
export GOVC_PASSWORD=yourpassword
export GOVC_INSECURE=true  # For self-signed certs

# VM operations
govc vm.info wallix-node1                    # VM details
govc vm.power -on wallix-node1               # Power on
govc vm.power -off wallix-node1              # Power off
govc vm.power -reset wallix-node1            # Reset
govc vm.ip wallix-node1                      # Get IP address
govc vm.console wallix-node1                 # Open console

# Snapshots
govc snapshot.create -vm wallix-node1 "Pre-Config"     # Create
govc snapshot.revert -vm wallix-node1 "Pre-Config"     # Revert
govc snapshot.remove -vm wallix-node1 "Pre-Config"     # Delete

# Monitoring
govc metric.sample wallix-node1 cpu.usage.average     # CPU usage
govc metric.sample wallix-node1 mem.usage.average     # Memory usage
govc metric.sample wallix-node1 net.usage.average     # Network usage

# Datastore
govc datastore.ls Datastore1                          # List files
govc datastore.info Datastore1                        # Datastore info
govc datastore.disk.info Datastore1                   # Disk usage

# Network
govc ls network                                       # List networks
govc host.portgroup.info "WALLIX Bastion-OT-DMZ"              # Port group info
govc vm.network.change -vm wallix-node1 -net "WALLIX Bastion-OT-DMZ"  # Change network

# Templates
govc vm.markastemplate wallix-node1                   # Convert to template
govc vm.clone -vm debian-12-template new-vm           # Clone from template
```

### Common PowerCLI Commands

```powershell
# Connect
Connect-VIServer -Server vcenter.company.com

# VM operations
Get-VM -Name "wallix-node1"
Start-VM -VM "wallix-node1"
Stop-VM -VM "wallix-node1" -Confirm:$false
Restart-VM -VM "wallix-node1" -Confirm:$false

# Get VM details
Get-VM "wallix-node1" | Get-VMGuest
Get-VM "wallix-node1" | Get-HardDisk
Get-VM "wallix-node1" | Get-NetworkAdapter

# Snapshots
New-Snapshot -VM "wallix-node1" -Name "Pre-Config"
Get-Snapshot -VM "wallix-node1" -Name "Pre-Config" | Set-VM -Confirm:$false
Remove-Snapshot -Snapshot (Get-Snapshot -VM "wallix-node1" -Name "Pre-Config") -Confirm:$false

# Monitoring
Get-Stat -Entity (Get-VM "wallix-node1") -Stat cpu.usage.average -Realtime
Get-Stat -Entity (Get-VM "wallix-node1") -Stat mem.usage.average -Realtime

# Network changes
Get-VM "wallix-node1" | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName "WALLIX Bastion-OT-DMZ" -Confirm:$false

# Bulk operations
Get-VM | Where-Object {$_.Name -like "wallix*"} | Start-VM
```

### VMware vCenter Web UI Shortcuts

```
VMs and Templates:
  https://vcenter.company.com/ui/app/vm

Hosts and Clusters:
  https://vcenter.company.com/ui/app/host

Networking:
  https://vcenter.company.com/ui/app/network

Storage:
  https://vcenter.company.com/ui/app/datastore

Monitoring > Performance:
  https://vcenter.company.com/ui/app/performance
```

### Troubleshooting

```bash
# VM not getting IP address
govc vm.info -json wallix-node1 | jq '.VirtualMachines[].Guest'
# Check: VMware Tools status, DHCP server, network adapter

# Network connectivity issues
govc vm.info wallix-node1 | grep Network
# Verify: Port group, VLAN ID, network adapter type

# Storage performance issues
govc metric.sample wallix-node1 disk.usage.average
govc datastore.info Datastore1
# Check: IOPS, latency, datastore capacity

# VM won't power on
govc vm.info wallix-node1
govc events wallix-node1
# Check: Resource pool limits, datastore space, host capacity
```

---

<p align="center">
  <a href="./README.md">← Back</a> •
  <a href="./02-active-directory-setup.md">Next: Active Directory Setup →</a>
</p>
