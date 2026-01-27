# 01 - Prerequisites

## Table of Contents

1. [Hardware Requirements](#hardware-requirements)
2. [Network Requirements](#network-requirements)
3. [Software Requirements](#software-requirements)
4. [Licensing](#licensing)
5. [Pre-Installation Checklist](#pre-installation-checklist)

---

## Hardware Requirements

### Site A - Primary (HA Cluster)

```
+==============================================================================+
|                   SITE A HARDWARE REQUIREMENTS                               |
+==============================================================================+

  PRIMARY NODE (wallix-a1.site-a.company.com)
  ===========================================

  +------------------------------------------------------------------------+
  | Component          | Minimum              | Recommended                 |
  +--------------------+----------------------+-----------------------------+
  | CPU                | 8 vCPU               | 16 vCPU                     |
  | RAM                | 16 GB                | 32 GB                       |
  | OS Disk            | 100 GB SSD           | 200 GB NVMe                 |
  | Data Disk          | 500 GB SSD           | 1 TB NVMe                   |
  | Recording Storage  | 2 TB                 | 5 TB (shared NFS/iSCSI)     |
  | Network            | 2x 1 Gbps            | 2x 10 Gbps (bonded)         |
  +--------------------+----------------------+-----------------------------+

  SECONDARY NODE (wallix-a2.site-a.company.com)
  =============================================

  +------------------------------------------------------------------------+
  | Component          | Minimum              | Recommended                 |
  +--------------------+----------------------+-----------------------------+
  | CPU                | 8 vCPU               | 16 vCPU                     |
  | RAM                | 16 GB                | 32 GB                       |
  | OS Disk            | 100 GB SSD           | 200 GB NVMe                 |
  | Data Disk          | 500 GB SSD           | 1 TB NVMe                   |
  | Recording Storage  | 2 TB                 | 5 TB (shared NFS/iSCSI)     |
  | Network            | 2x 1 Gbps            | 2x 10 Gbps (bonded)         |
  +--------------------+----------------------+-----------------------------+

  SHARED STORAGE (recordings)
  ===========================

  +------------------------------------------------------------------------+
  | Type               | Capacity             | Notes                       |
  +--------------------+----------------------+-----------------------------+
  | NFS Server         | 10 TB                | NFSv4, high IOPS            |
  | or iSCSI SAN       | 10 TB                | Multipath configured        |
  +--------------------+----------------------+-----------------------------+

+==============================================================================+
```

### Site B - Secondary (HA Cluster)

```
+==============================================================================+
|                   SITE B HARDWARE REQUIREMENTS                               |
+==============================================================================+

  PRIMARY NODE (wallix-b1.site-b.company.com)
  ===========================================

  +------------------------------------------------------------------------+
  | Component          | Minimum              | Recommended                 |
  +--------------------+----------------------+-----------------------------+
  | CPU                | 4 vCPU               | 8 vCPU                      |
  | RAM                | 8 GB                 | 16 GB                       |
  | OS Disk            | 100 GB SSD           | 200 GB NVMe                 |
  | Data Disk          | 250 GB SSD           | 500 GB NVMe                 |
  | Recording Storage  | 1 TB                 | 2 TB (shared NFS/iSCSI)     |
  | Network            | 2x 1 Gbps            | 2x 1 Gbps (bonded)          |
  +--------------------+----------------------+-----------------------------+

  SECONDARY NODE (wallix-b2.site-b.company.com)
  =============================================

  Same specifications as primary node.

+==============================================================================+
```

### Site C - Remote (Standalone)

```
+==============================================================================+
|                   SITE C HARDWARE REQUIREMENTS                               |
+==============================================================================+

  STANDALONE NODE (wallix-c1.site-c.company.com)
  ==============================================

  +------------------------------------------------------------------------+
  | Component          | Minimum              | Recommended                 |
  +--------------------+----------------------+-----------------------------+
  | CPU                | 4 vCPU               | 8 vCPU                      |
  | RAM                | 8 GB                 | 16 GB                       |
  | OS Disk            | 100 GB SSD           | 200 GB NVMe                 |
  | Data Disk          | 250 GB SSD           | 500 GB NVMe                 |
  | Recording Storage  | 500 GB               | 1 TB (local)                |
  | Network            | 1x 1 Gbps            | 2x 1 Gbps (bonded)          |
  +--------------------+----------------------+-----------------------------+

  Note: Site C operates in standalone mode with local storage.
  Recordings are replicated to Site A during maintenance windows.

+==============================================================================+
```

---

## Network Requirements

### IP Address Allocation

```
+==============================================================================+
|                   NETWORK ADDRESS PLAN                                       |
+==============================================================================+

  SITE A - PRIMARY (10.100.0.0/16)
  =================================

  +------------------------------------------------------------------------+
  | Network            | CIDR                 | Purpose                     |
  +--------------------+----------------------+-----------------------------+
  | Management         | 10.100.1.0/24        | Admin access, monitoring    |
  | User Access        | 10.100.2.0/24        | User connections            |
  | OT DMZ             | 10.100.10.0/24       | OT network gateway          |
  | HA Heartbeat       | 10.100.254.0/30      | Cluster communication       |
  +--------------------+----------------------+-----------------------------+

  IP Assignments - Site A:
  +------------------------------------------------------------------------+
  | Host               | Management IP        | HA Heartbeat IP             |
  +--------------------+----------------------+-----------------------------+
  | wallix-a1          | 10.100.1.10          | 10.100.254.1                |
  | wallix-a2          | 10.100.1.11          | 10.100.254.2                |
  | wallix-vip         | 10.100.1.100         | (Virtual IP)                |
  +--------------------+----------------------+-----------------------------+

  --------------------------------------------------------------------------

  SITE B - SECONDARY (10.200.0.0/16)
  ==================================

  +------------------------------------------------------------------------+
  | Network            | CIDR                 | Purpose                     |
  +--------------------+----------------------+-----------------------------+
  | Management         | 10.200.1.0/24        | Admin access, monitoring    |
  | User Access        | 10.200.2.0/24        | User connections            |
  | OT DMZ             | 10.200.10.0/24       | OT network gateway          |
  | HA Heartbeat       | 10.200.254.0/30      | Cluster communication       |
  +--------------------+----------------------+-----------------------------+

  IP Assignments - Site B:
  +------------------------------------------------------------------------+
  | Host               | Management IP        | HA Heartbeat IP             |
  +--------------------+----------------------+-----------------------------+
  | wallix-b1          | 10.200.1.10          | 10.200.254.1                |
  | wallix-b2          | 10.200.1.11          | 10.200.254.2                |
  | wallix-vip         | 10.200.1.100         | (Virtual IP)                |
  +--------------------+----------------------+-----------------------------+

  --------------------------------------------------------------------------

  SITE C - REMOTE (10.300.0.0/16)
  ===============================

  +------------------------------------------------------------------------+
  | Network            | CIDR                 | Purpose                     |
  +--------------------+----------------------+-----------------------------+
  | Management         | 10.50.1.0/24         | Admin access, monitoring    |
  | User Access        | 10.50.2.0/24         | User connections            |
  | OT DMZ             | 10.50.10.0/24        | OT network gateway          |
  +--------------------+----------------------+-----------------------------+

  IP Assignments - Site C:
  +------------------------------------------------------------------------+
  | Host               | Management IP        | Notes                       |
  +--------------------+----------------------+-----------------------------+
  | wallix-c1          | 10.50.1.10           | Standalone                  |
  +--------------------+----------------------+-----------------------------+

+==============================================================================+
```

### Firewall Requirements

```
+==============================================================================+
|                   FIREWALL RULES                                             |
+==============================================================================+

  INBOUND TO WALLIX BASTION
  =========================

  +------------------------------------------------------------------------+
  | Source             | Port      | Protocol | Purpose                     |
  +--------------------+-----------+----------+-----------------------------+
  | Admin Workstations | 443       | TCP      | Web UI Administration       |
  | Users              | 443       | TCP      | Web UI / HTML5 Sessions     |
  | Users              | 22        | TCP      | SSH Proxy                   |
  | Users              | 3389      | TCP      | RDP Proxy                   |
  | Users              | 5900      | TCP      | VNC Proxy                   |
  | Monitoring         | 161       | UDP      | SNMP                        |
  | Syslog Server      | 514       | UDP/TCP  | Syslog                      |
  +--------------------+-----------+----------+-----------------------------+

  OUTBOUND FROM WALLIX BASTION
  ============================

  +------------------------------------------------------------------------+
  | Destination        | Port      | Protocol | Purpose                     |
  +--------------------+-----------+----------+-----------------------------+
  | Target Devices     | 22        | TCP      | SSH to targets              |
  | Target Devices     | 3389      | TCP      | RDP to targets              |
  | Target Devices     | 5900      | TCP      | VNC to targets              |
  | Target Devices     | 23        | TCP      | Telnet to targets           |
  | Target Devices     | 502       | TCP      | Modbus TCP                  |
  | Target Devices     | 102       | TCP      | S7comm (Siemens)            |
  | Target Devices     | 44818     | TCP      | EtherNet/IP                 |
  | LDAP/AD            | 389/636   | TCP      | Authentication              |
  | DNS                | 53        | UDP/TCP  | Name resolution             |
  | NTP                | 123       | UDP      | Time sync                   |
  | SMTP               | 25/587    | TCP      | Email alerts                |
  +--------------------+-----------+----------+-----------------------------+

  INTER-SITE COMMUNICATION
  ========================

  +------------------------------------------------------------------------+
  | Source             | Destination | Port    | Purpose                    |
  +--------------------+-------------+---------+----------------------------+
  | Site A Bastion     | Site B VIP  | 443     | Configuration sync         |
  | Site A Bastion     | Site C      | 443     | Configuration sync         |
  | Site B Bastion     | Site A VIP  | 443     | Configuration sync         |
  | Site C Bastion     | Site A VIP  | 443     | Configuration sync         |
  | All Sites          | All Sites   | 5432    | PostgreSQL replication     |
  +--------------------+-------------+---------+----------------------------+

  HA CLUSTER INTERNAL (per site)
  ==============================

  +------------------------------------------------------------------------+
  | Source             | Destination | Port    | Purpose                    |
  +--------------------+-------------+---------+----------------------------+
  | Node 1             | Node 2      | 5432    | PostgreSQL streaming       |
  | Node 1             | Node 2      | 5405    | Corosync cluster           |
  | Node 1             | Node 2      | 7789    | DRBD (if used)             |
  | Node 2             | Node 1      | 5432    | PostgreSQL streaming       |
  | Node 2             | Node 1      | 5405    | Corosync cluster           |
  | Node 2             | Node 1      | 7789    | DRBD (if used)             |
  +--------------------+-------------+---------+----------------------------+

+==============================================================================+
```

### DNS Requirements

```
+==============================================================================+
|                   DNS RECORDS                                                |
+==============================================================================+

  REQUIRED DNS ENTRIES
  ====================

  Forward Records (A):
  +------------------------------------------------------------------------+
  | Hostname                          | IP Address      | Site             |
  +-----------------------------------+-----------------+------------------+
  | wallix-a1.site-a.company.com      | 10.100.1.10     | Site A           |
  | wallix-a2.site-a.company.com      | 10.100.1.11     | Site A           |
  | wallix.site-a.company.com         | 10.100.1.100    | Site A (VIP)     |
  | wallix-b1.site-b.company.com      | 10.200.1.10     | Site B           |
  | wallix-b2.site-b.company.com      | 10.200.1.11     | Site B           |
  | wallix.site-b.company.com         | 10.200.1.100    | Site B (VIP)     |
  | wallix.site-c.company.com         | 10.50.1.10      | Site C           |
  +-----------------------------------+-----------------+------------------+

  Global Access Record (GSLB or GeoDNS recommended):
  +------------------------------------------------------------------------+
  | Hostname                          | Target                             |
  +-----------------------------------+------------------------------------+
  | wallix.company.com                | wallix.site-a.company.com (primary)|
  |                                   | wallix.site-b.company.com (backup) |
  +-----------------------------------+------------------------------------+

  Reverse Records (PTR):
  +------------------------------------------------------------------------+
  | IP Address        | Hostname                                           |
  +-------------------+----------------------------------------------------+
  | 10.100.1.10       | wallix-a1.site-a.company.com                       |
  | 10.100.1.11       | wallix-a2.site-a.company.com                       |
  | 10.100.1.100      | wallix.site-a.company.com                          |
  | 10.200.1.10       | wallix-b1.site-b.company.com                       |
  | 10.200.1.11       | wallix-b2.site-b.company.com                       |
  | 10.200.1.100      | wallix.site-b.company.com                          |
  | 10.50.1.10        | wallix.site-c.company.com                          |
  +-------------------+----------------------------------------------------+

+==============================================================================+
```

---

## Software Requirements

### Operating System

```
+==============================================================================+
|                   OS REQUIREMENTS                                            |
+==============================================================================+

  SUPPORTED OPERATING SYSTEMS (WALLIX 12.x)
  =========================================

  +------------------------------------------------------------------------+
  | OS                 | Version              | Status                      |
  +--------------------+----------------------+-----------------------------+
  | Debian             | 12 (Bookworm)        | Primary - RECOMMENDED      |
  | Debian             | 11 (Bullseye)        | Supported (legacy)          |
  | Ubuntu Server      | 22.04 LTS            | Supported                   |
  | Ubuntu Server      | 24.04 LTS            | Supported                   |
  | RHEL               | 9.x                  | Supported                   |
  | RHEL               | 8.x                  | Supported                   |
  +--------------------+----------------------+-----------------------------+

  RECOMMENDED: Debian 12 (Bookworm) - Native platform for WALLIX 12.x

  --------------------------------------------------------------------------

  REQUIRED PACKAGES (pre-install)
  ===============================

  # Debian/Ubuntu
  apt update && apt install -y \
    openssh-server \
    curl \
    gnupg \
    lsb-release \
    ca-certificates \
    ntp \
    net-tools \
    tcpdump \
    rsync

  # RHEL/CentOS
  dnf install -y \
    openssh-server \
    curl \
    gnupg2 \
    ca-certificates \
    chrony \
    net-tools \
    tcpdump \
    rsync

+==============================================================================+
```

### Database Requirements

```
+==============================================================================+
|                   DATABASE REQUIREMENTS                                      |
+==============================================================================+

  POSTGRESQL VERSION
  ==================

  +------------------------------------------------------------------------+
  | Version            | Status               | Notes                       |
  +--------------------+----------------------+-----------------------------+
  | PostgreSQL 16      | Recommended          | Best performance            |
  | PostgreSQL 15      | Supported            | Good compatibility          |
  | PostgreSQL 14      | Minimum              | Legacy support              |
  +--------------------+----------------------+-----------------------------+

  DATABASE SIZING
  ===============

  +------------------------------------------------------------------------+
  | Site               | Expected Users       | Recommended DB Size         |
  +--------------------+----------------------+-----------------------------+
  | Site A (Primary)   | 500+ users           | 100 GB                      |
  | Site B (Secondary) | 200 users            | 50 GB                       |
  | Site C (Remote)    | 50 users             | 20 GB                       |
  +--------------------+----------------------+-----------------------------+

  POSTGRESQL CONFIGURATION (recommended)
  ======================================

  # /etc/postgresql/16/main/postgresql.conf

  max_connections = 500
  shared_buffers = 8GB              # 25% of RAM
  effective_cache_size = 24GB       # 75% of RAM
  maintenance_work_mem = 2GB
  checkpoint_completion_target = 0.9
  wal_buffers = 64MB
  default_statistics_target = 100
  random_page_cost = 1.1
  effective_io_concurrency = 200
  min_wal_size = 1GB
  max_wal_size = 4GB
  max_worker_processes = 8
  max_parallel_workers_per_gather = 4
  max_parallel_workers = 8

+==============================================================================+
```

---

## Licensing

### License Requirements

```
+==============================================================================+
|                   LICENSING                                                  |
+==============================================================================+

  LICENSE TYPES REQUIRED
  ======================

  +------------------------------------------------------------------------+
  | Component          | License Type         | Quantity per Site           |
  +--------------------+----------------------+-----------------------------+
  | WALLIX Bastion     | Per-user or Per-target| Based on usage             |
  | Session Manager    | Included             | N/A                         |
  | Password Manager   | Included             | N/A                         |
  | HA Cluster         | Add-on               | 1 per HA site               |
  | Recording Storage  | Included             | N/A                         |
  +--------------------+----------------------+-----------------------------+

  LICENSE CALCULATION
  ===================

  Site A (Primary HQ):
  - Concurrent users: 100
  - Named users: 500
  - Target devices: 1000 (IT + OT)

  Site B (Secondary Plant):
  - Concurrent users: 50
  - Named users: 200
  - Target devices: 500

  Site C (Remote Site):
  - Concurrent users: 20
  - Named users: 50
  - Target devices: 200

  --------------------------------------------------------------------------

  LICENSE FILE DEPLOYMENT
  =======================

  License files are deployed during installation:

  1. Obtain license file from WALLIX support portal
  2. Save as: /etc/opt/wab/license.key
  3. Verify: wab-admin license-check

  IMPORTANT: WALLIX 12.x does NOT support legacy license formats.
  Contact WALLIX support if upgrading from versions prior to 12.0.

+==============================================================================+
```

---

## Pre-Installation Checklist

### Site A Checklist

```
+==============================================================================+
|                   SITE A PRE-INSTALLATION CHECKLIST                          |
+==============================================================================+

  HARDWARE
  ========
  [ ] Primary node provisioned (wallix-a1)
  [ ] Secondary node provisioned (wallix-a2)
  [ ] Shared storage configured (NFS/iSCSI)
  [ ] Network interfaces configured (2x per node)
  [ ] HA heartbeat network configured

  NETWORK
  =======
  [ ] IP addresses assigned per plan
  [ ] DNS forward records created
  [ ] DNS reverse records created
  [ ] Firewall rules configured
  [ ] VIP address reserved

  SOFTWARE
  ========
  [ ] Debian 12 installed on both nodes
  [ ] SSH access verified
  [ ] NTP configured and synchronized
  [ ] Required packages installed

  SECURITY
  ========
  [ ] SSL certificates obtained (or plan for Let's Encrypt)
  [ ] Admin credentials documented (secure storage)
  [ ] LDAP/AD connectivity verified
  [ ] Network segmentation verified

  DOCUMENTATION
  =============
  [ ] IP address plan documented
  [ ] Credentials stored in password manager
  [ ] Runbook prepared for operations team
  [ ] Backup strategy documented

+==============================================================================+
```

### Site B Checklist

```
+==============================================================================+
|                   SITE B PRE-INSTALLATION CHECKLIST                          |
+==============================================================================+

  HARDWARE
  ========
  [ ] Primary node provisioned (wallix-b1)
  [ ] Secondary node provisioned (wallix-b2)
  [ ] Shared storage configured (NFS/iSCSI)
  [ ] Network interfaces configured
  [ ] HA heartbeat network configured

  NETWORK
  =======
  [ ] IP addresses assigned per plan
  [ ] DNS records created
  [ ] Firewall rules configured
  [ ] Site-to-site VPN verified (to Site A)
  [ ] VIP address reserved

  SOFTWARE
  ========
  [ ] Debian 12 installed on both nodes
  [ ] SSH access verified
  [ ] NTP configured
  [ ] Required packages installed

+==============================================================================+
```

### Site C Checklist

```
+==============================================================================+
|                   SITE C PRE-INSTALLATION CHECKLIST                          |
+==============================================================================+

  HARDWARE
  ========
  [ ] Standalone node provisioned (wallix-c1)
  [ ] Local storage configured
  [ ] Network interface configured

  NETWORK
  =======
  [ ] IP address assigned per plan
  [ ] DNS records created
  [ ] Firewall rules configured
  [ ] Site-to-site VPN verified (to Site A)

  SOFTWARE
  ========
  [ ] Debian 12 installed
  [ ] SSH access verified
  [ ] NTP configured
  [ ] Required packages installed

  SPECIAL CONSIDERATIONS
  ======================
  [ ] Limited bandwidth plan for replication
  [ ] Local backup storage available
  [ ] Air-gap capability if required

+==============================================================================+
```

---

**Next Step**: [02-site-a-primary.md](./02-site-a-primary.md) - Primary Site Installation
