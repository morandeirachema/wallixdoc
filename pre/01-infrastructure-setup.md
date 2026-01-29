# 01 - Infrastructure Setup

## VM Provisioning for Pre-Production Lab

This guide covers provisioning all VMs for the lab environment.

---

## Prerequisites

- Hypervisor: VMware vSphere, Proxmox, Hyper-V, or cloud (AWS/Azure/GCP)
- Network: 3 VLANs configured (Management, IT Test, OT Test)
- ISO images ready:
  - Debian 12 (Bookworm)
  - Ubuntu 22.04 LTS
  - Windows Server 2022

---

## Network Configuration

### VLAN Setup

| VLAN ID | Name | Subnet | Gateway | Purpose |
|---------|------|--------|---------|---------|
| 10 | Management | 10.10.1.0/24 | 10.10.1.1 | Infrastructure |
| 20 | IT-Test | 10.10.2.0/24 | 10.10.2.1 | IT test targets |
| 30 | OT-Test | 10.10.3.0/24 | 10.10.3.1 | OT simulation |

### DNS Configuration

Create these DNS records (on AD DC or existing DNS):

```
; Forward Zone: lab.local
dc-lab          A     10.10.1.10
pam4ot-node1    A     10.10.1.11
pam4ot-node2    A     10.10.1.12
pam4ot          A     10.10.1.100   ; VIP
siem-lab        A     10.10.1.50
monitor-lab     A     10.10.1.60
linux-test      A     10.10.2.10
windows-test    A     10.10.2.20
network-test    A     10.10.2.30
plc-sim         A     10.10.3.10
```

---

## VM Specifications

### PAM4OT Nodes (x2)

```
+------------------------------------------------------------------------------+
|  PAM4OT NODE SPECIFICATION                                                   |
+------------------------------------------------------------------------------+
|                                                                              |
|  Name:        pam4ot-node1 / pam4ot-node2                                   |
|  OS:          Debian 12 (Bookworm)                                          |
|                                                                              |
|  COMPUTE                          STORAGE                                   |
|  -------                          -------                                   |
|  vCPU:     4                      OS Disk:    50 GB (SSD)                   |
|  RAM:      16 GB                  Data Disk:  150 GB (SSD)                  |
|                                                                              |
|  NETWORK                                                                    |
|  -------                                                                    |
|  NIC 1:    Management VLAN (10.10.1.0/24)                                  |
|                                                                              |
|  Node 1: 10.10.1.11                                                        |
|  Node 2: 10.10.1.12                                                        |
|  VIP:    10.10.1.100                                                       |
|                                                                              |
+------------------------------------------------------------------------------+
```

### Active Directory DC

```
+------------------------------------------------------------------------------+
|  ACTIVE DIRECTORY SPECIFICATION                                              |
+------------------------------------------------------------------------------+
|                                                                              |
|  Name:        dc-lab                                                        |
|  OS:          Windows Server 2022                                           |
|  IP:          10.10.1.10                                                    |
|                                                                              |
|  COMPUTE                          STORAGE                                   |
|  -------                          -------                                   |
|  vCPU:     2                      OS Disk:    60 GB                         |
|  RAM:      4 GB                                                             |
|                                                                              |
|  ROLES                                                                      |
|  -----                                                                      |
|  - Active Directory Domain Services                                         |
|  - DNS Server                                                               |
|  - Certificate Services (optional)                                          |
|                                                                              |
|  Domain: LAB.LOCAL                                                          |
|                                                                              |
+------------------------------------------------------------------------------+
```

### SIEM Server

```
+------------------------------------------------------------------------------+
|  SIEM SPECIFICATION                                                          |
+------------------------------------------------------------------------------+
|                                                                              |
|  Name:        siem-lab                                                      |
|  OS:          Ubuntu 22.04 LTS                                              |
|  IP:          10.10.1.50                                                    |
|                                                                              |
|  COMPUTE                          STORAGE                                   |
|  -------                          -------                                   |
|  vCPU:     4                      OS Disk:    100 GB                        |
|  RAM:      16 GB                  Data Disk:  400 GB (logs)                 |
|                                                                              |
|  OPTIONS (choose one)                                                       |
|  -------------------                                                        |
|  - Splunk Enterprise (trial license)                                        |
|  - Elastic Stack (ELK)                                                      |
|  - Wazuh                                                                    |
|                                                                              |
+------------------------------------------------------------------------------+
```

### Monitoring Server

```
+------------------------------------------------------------------------------+
|  OBSERVABILITY SPECIFICATION                                                 |
+------------------------------------------------------------------------------+
|                                                                              |
|  Name:        monitor-lab                                                   |
|  OS:          Ubuntu 22.04 LTS                                              |
|  IP:          10.10.1.60                                                    |
|                                                                              |
|  COMPUTE                          STORAGE                                   |
|  -------                          -------                                   |
|  vCPU:     2                      OS Disk:    100 GB                        |
|  RAM:      8 GB                                                             |
|                                                                              |
|  STACK                                                                      |
|  -----                                                                      |
|  - Prometheus (metrics collection)                                          |
|  - Grafana (dashboards)                                                     |
|  - Alertmanager (alerts)                                                    |
|                                                                              |
+------------------------------------------------------------------------------+
```

### Test Target VMs

```
+------------------------------------------------------------------------------+
|  TEST TARGETS                                                                |
+------------------------------------------------------------------------------+

  LINUX TEST (SSH Target)
  -----------------------
  Name:    linux-test
  OS:      Ubuntu 22.04 LTS
  IP:      10.10.2.10
  vCPU:    2
  RAM:     4 GB
  Disk:    40 GB

  WINDOWS TEST (RDP Target)
  -------------------------
  Name:    windows-test
  OS:      Windows Server 2022
  IP:      10.10.2.20
  vCPU:    2
  RAM:     8 GB
  Disk:    60 GB

  NETWORK DEVICE (SSH/Telnet Target)
  ----------------------------------
  Name:    network-test
  OS:      VyOS 1.4 or pfSense
  IP:      10.10.2.30
  vCPU:    1
  RAM:     2 GB
  Disk:    20 GB

  PLC SIMULATOR (OT Target)
  -------------------------
  Name:    plc-sim
  OS:      Ubuntu 22.04 + OpenPLC/Modbus sim
  IP:      10.10.3.10
  vCPU:    1
  RAM:     2 GB
  Disk:    20 GB

+------------------------------------------------------------------------------+
```

---

## Provisioning Steps

### Step 1: Create VMs

#### Using VMware vSphere

```bash
# Example using govc CLI
export GOVC_URL=vcenter.company.com
export GOVC_USERNAME=administrator@vsphere.local
export GOVC_PASSWORD=password
export GOVC_INSECURE=true

# Create PAM4OT Node 1
govc vm.create -m 16384 -c 4 -disk 50GB -net "Management" pam4ot-node1
govc vm.disk.create -vm pam4ot-node1 -size 150GB -name data

# Create PAM4OT Node 2
govc vm.create -m 16384 -c 4 -disk 50GB -net "Management" pam4ot-node2
govc vm.disk.create -vm pam4ot-node2 -size 150GB -name data
```

#### Using Proxmox

```bash
# Create PAM4OT Node 1
qm create 101 --name pam4ot-node1 --memory 16384 --cores 4 \
  --net0 virtio,bridge=vmbr0,tag=10 \
  --scsi0 local-lvm:50 \
  --scsi1 local-lvm:150

# Create PAM4OT Node 2
qm create 102 --name pam4ot-node2 --memory 16384 --cores 4 \
  --net0 virtio,bridge=vmbr0,tag=10 \
  --scsi0 local-lvm:50 \
  --scsi1 local-lvm:150
```

#### Using Terraform (vSphere)

```hcl
# main.tf
provider "vsphere" {
  vsphere_server = "vcenter.company.com"
  user           = var.vsphere_user
  password       = var.vsphere_password
}

resource "vsphere_virtual_machine" "pam4ot_node1" {
  name             = "pam4ot-node1"
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id

  num_cpus = 4
  memory   = 16384

  network_interface {
    network_id = data.vsphere_network.management.id
  }

  disk {
    label = "os"
    size  = 50
  }

  disk {
    label       = "data"
    size        = 150
    unit_number = 1
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.debian_template.id
  }
}
```

---

### Step 2: Base OS Installation

#### Debian 12 for PAM4OT Nodes

```bash
# During installation:
# - Hostname: pam4ot-node1 (or pam4ot-node2)
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
hostnamectl set-hostname pam4ot-node1.lab.local

# Configure /etc/hosts
cat >> /etc/hosts << 'EOF'
10.10.1.10  dc-lab.lab.local dc-lab
10.10.1.11  pam4ot-node1.lab.local pam4ot-node1
10.10.1.12  pam4ot-node2.lab.local pam4ot-node2
10.10.1.100 pam4ot.lab.local pam4ot
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

### Step 4: Verify Connectivity

```bash
# From PAM4OT nodes, verify all connectivity:

echo "=== DNS Resolution ==="
nslookup dc-lab.lab.local
nslookup pam4ot-node1.lab.local
nslookup pam4ot-node2.lab.local

echo "=== Ping Tests ==="
ping -c 3 dc-lab.lab.local
ping -c 3 pam4ot-node2.lab.local    # From node1
ping -c 3 siem-lab.lab.local

echo "=== Port Tests ==="
nc -zv dc-lab.lab.local 636         # LDAPS
nc -zv dc-lab.lab.local 88          # Kerberos
nc -zv siem-lab.lab.local 514       # Syslog
```

---

## Infrastructure Checklist

| Check | Command | Expected |
|-------|---------|----------|
| PAM4OT Node 1 reachable | `ping 10.10.1.11` | Success |
| PAM4OT Node 2 reachable | `ping 10.10.1.12` | Success |
| AD DC reachable | `ping 10.10.1.10` | Success |
| DNS resolution | `nslookup pam4ot.lab.local` | Returns 10.10.1.100 |
| NTP sync | `chronyc tracking` | Synchronized |
| Inter-node communication | From node1: `ping pam4ot-node2` | Success |

---

<p align="center">
  <a href="./README.md">← Back</a> •
  <a href="./02-active-directory-setup.md">Next: Active Directory Setup →</a>
</p>
