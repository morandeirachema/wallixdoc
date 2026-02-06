# 28 - System Requirements

## Table of Contents

1. [Hardware Requirements](#hardware-requirements)
2. [Software Requirements](#software-requirements)
3. [Network Requirements](#network-requirements)
4. [Storage Requirements](#storage-requirements)
5. [Sizing Guidelines](#sizing-guidelines)
6. [Performance Tuning](#performance-tuning)
7. [Capacity Planning](#capacity-planning)

---

## Hardware Requirements

### Physical/Virtual Server Specifications

```
+===============================================================================+
|                   HARDWARE REQUIREMENTS                                       |
+===============================================================================+

  MINIMUM REQUIREMENTS
  ====================

  +-------------------------------------------------------------------------+
  | Component        | Minimum                | Notes                       |
  +------------------+------------------------+-----------------------------+
  | CPU              | 4 cores (x86_64)       | 64-bit required             |
  | Memory           | 8 GB RAM               | More for active sessions    |
  | System Disk      | 100 GB SSD             | OS + Application            |
  | Data Disk        | 200 GB SSD             | Database + Config           |
  | Recording Disk   | 500 GB+                | Depends on retention        |
  | Network          | 1 Gbps                 | Dual NIC recommended        |
  +------------------+------------------------+-----------------------------+

  --------------------------------------------------------------------------

  RECOMMENDED REQUIREMENTS BY DEPLOYMENT SIZE
  ===========================================

  SMALL (< 100 concurrent sessions)
  +-------------------------------------------------------------------------+
  | Component        | Specification          | Notes                       |
  +------------------+------------------------+-----------------------------+
  | CPU              | 4 cores                |                             |
  | Memory           | 16 GB RAM              |                             |
  | System Disk      | 100 GB SSD             |                             |
  | Data Disk        | 200 GB SSD             | IOPS: 3000+                 |
  | Recording Disk   | 500 GB                 | ~1 month retention          |
  | Network          | 1 Gbps                 |                             |
  +------------------+------------------------+-----------------------------+

  MEDIUM (100-500 concurrent sessions)
  +-------------------------------------------------------------------------+
  | Component        | Specification          | Notes                       |
  +------------------+------------------------+-----------------------------+
  | CPU              | 8 cores                |                             |
  | Memory           | 32 GB RAM              |                             |
  | System Disk      | 100 GB SSD             |                             |
  | Data Disk        | 500 GB SSD             | IOPS: 5000+                 |
  | Recording Disk   | 2 TB                   | External NAS recommended    |
  | Network          | 1 Gbps (dual)          |                             |
  +------------------+------------------------+-----------------------------+

  LARGE (500-1000 concurrent sessions)
  +------------------------------------------------------------------------+
  | Component        | Specification          | Notes                       |
  +------------------+------------------------+-----------------------------+
  | CPU              | 16 cores               |                             |
  | Memory           | 64 GB RAM              |                             |
  | System Disk      | 100 GB SSD             |                             |
  | Data Disk        | 1 TB SSD               | IOPS: 10000+                |
  | Recording Disk   | 5 TB+                  | External NAS/SAN required   |
  | Network          | 10 Gbps                |                             |
  +------------------+------------------------+-----------------------------+

  ENTERPRISE (1000+ concurrent sessions)
  +-------------------------------------------------------------------------+
  | Component        | Specification          | Notes                       |
  +------------------+------------------------+-----------------------------+
  | CPU              | 32+ cores              |                             |
  | Memory           | 128+ GB RAM            |                             |
  | System Disk      | 200 GB SSD             |                             |
  | Data Disk        | 2 TB SSD               | IOPS: 20000+, NVMe          |
  | Recording Disk   | 10 TB+                 | High-performance NAS/SAN    |
  | Network          | 10 Gbps (bonded)       |                             |
  +------------------+------------------------+-----------------------------+

  --------------------------------------------------------------------------

  VIRTUAL MACHINE SPECIFICATIONS
  ==============================

  VMware vSphere:
  +-------------------------------------------------------------------------+
  | Setting                    | Recommendation                             |
  +----------------------------+--------------------------------------------+
  | Hardware Version           | 13+ (vSphere 6.5+)                         |
  | CPU Reservation            | 50% of allocated                           |
  | Memory Reservation         | 75% of allocated                           |
  | Disk Controller            | VMware Paravirtual SCSI                    |
  | Network Adapter            | VMXNET3                                    |
  | Disk Provisioning          | Thick Provision Eager Zeroed               |
  +----------------------------+--------------------------------------------+

  Microsoft Hyper-V:
  +-------------------------------------------------------------------------+
  | Setting                    | Recommendation                             |
  +----------------------------+--------------------------------------------+
  | Generation                 | Generation 2                               |
  | Dynamic Memory             | Disabled (use fixed)                       |
  | Virtual Processor          | 4+ (based on size)                         |
  | Network Adapter            | Synthetic adapter                          |
  | Disk                       | Fixed size VHDX                            |
  +----------------------------+--------------------------------------------+

  KVM/QEMU:
  +-------------------------------------------------------------------------+
  | Setting                    | Recommendation                             |
  +----------------------------+--------------------------------------------+
  | Machine Type               | q35                                        |
  | CPU Model                  | host-passthrough                           |
  | Disk Bus                   | VirtIO                                     |
  | Network                    | VirtIO                                     |
  | Memory                     | Static allocation                          |
  +----------------------------+--------------------------------------------+

+===============================================================================+
```

---

## Software Requirements

### Operating System and Dependencies

```
+===============================================================================+
|                   SOFTWARE REQUIREMENTS                                       |
+===============================================================================+

  SUPPORTED OPERATING SYSTEMS
  ===========================

  WALLIX Bastion Appliance (Recommended):
  +------------------------------------------------------------------------+
  | Type               | Description                                       |
  +--------------------+---------------------------------------------------+
  | WALLIX Appliance   | Pre-configured, hardened Linux appliance          |
  |                    | Includes all dependencies                         |
  |                    | Recommended for production                        |
  +--------------------+---------------------------------------------------+

  Manual Installation (if supported):
  +-------------------------------------------------------------------------+
  | OS                 | Version              | Notes                       |
  +--------------------+----------------------+-----------------------------+
  | Debian             | 12 (Bookworm)        | REQUIRED for 12.x installs  |
  | Debian             | 11 (Bullseye)        | Migration only not for new  |
  | Ubuntu Server      | 22.04 LTS            | With WALLIX repo            |
  | Ubuntu Server      | 24.04 LTS            | With WALLIX repo            |
  | RHEL               | 8.x                  | Enterprise support          |
  | RHEL               | 9.x                  | Enterprise support          |
  +--------------------+----------------------+-----------------------------+

  --------------------------------------------------------------------------

  DATABASE REQUIREMENTS
  =====================

  +-------------------------------------------------------------------------+
  | Component          | Version              | Notes                       |
  +--------------------+----------------------+-----------------------------+
  | MariaDB            | 10.6, 10.11, 11.x    | Internal or external        |
  |                    |                      | 10.6+ REQUIRED for 12.x     |
  +--------------------+----------------------+-----------------------------+

  External Database Requirements:
  * MariaDB 10.11+ recommended for WALLIX 12.x
  * UTF-8 encoding
  * At least 10,000 max_connections
  * Sufficient shared_buffers (25% of RAM)
  * For HA: Streaming replication configured

  --------------------------------------------------------------------------

  BROWSER REQUIREMENTS (Web UI)
  =============================

  +-------------------------------------------------------------------------+
  | Browser            | Minimum Version      | Notes                       |
  +--------------------+----------------------+-----------------------------+
  | Google Chrome      | 90+                  | Recommended                 |
  | Mozilla Firefox    | 90+                  | Supported                   |
  | Microsoft Edge     | 90+                  | Chromium-based              |
  | Safari             | 14+                  | macOS/iOS                   |
  +--------------------+----------------------+-----------------------------+

  Requirements:
  * JavaScript enabled
  * Cookies enabled
  * WebSocket support (for HTML5 sessions)
  * TLS 1.2+ support

  --------------------------------------------------------------------------

  CLIENT REQUIREMENTS
  ===================

  SSH Clients:
  +-------------------------------------------------------------------------+
  | Client             | Version              | Notes                       |
  +--------------------+----------------------+-----------------------------+
  | OpenSSH            | 7.0+                 | Linux/macOS                 |
  | PuTTY              | 0.70+                | Windows                     |
  | SecureCRT          | 8.0+                 | Cross-platform              |
  | Windows OpenSSH    | 8.0+                 | Windows 10/11               |
  +--------------------+----------------------+-----------------------------+

  RDP Clients:
  +-------------------------------------------------------------------------+
  | Client             | Version              | Notes                       |
  +--------------------+----------------------+-----------------------------+
  | mstsc.exe          | Windows built-in     | All Windows versions        |
  | Microsoft RD       | Any                  | macOS/iOS/Android           |
  | FreeRDP            | 2.0+                 | Linux                       |
  | Remmina            | 1.4+                 | Linux                       |
  +--------------------+----------------------+-----------------------------+

  --------------------------------------------------------------------------

  INTEGRATION REQUIREMENTS
  ========================

  LDAP/Active Directory:
  +-------------------------------------------------------------------------+
  | Component          | Version              | Notes                       |
  +--------------------+----------------------+-----------------------------+
  | Active Directory   | 2012 R2+             | LDAPS recommended           |
  | OpenLDAP           | 2.4+                 | TLS required                |
  | FreeIPA            | 4.6+                 | Supported                   |
  +--------------------+----------------------+-----------------------------+

  SIEM Systems:
  +-------------------------------------------------------------------------+
  | SIEM               | Integration          | Protocol                    |
  +--------------------+----------------------+-----------------------------+
  | Splunk             | HEC, Syslog          | TCP/TLS, HTTP               |
  | IBM QRadar         | Syslog, LEEF         | TCP/TLS                     |
  | ArcSight           | Syslog, CEF          | TCP/TLS                     |
  | Elastic/ELK        | Syslog, API          | TCP/TLS, HTTP               |
  | Microsoft Sentinel | Syslog, API          | TCP/TLS, HTTP               |
  +--------------------+----------------------+-----------------------------+

+===============================================================================+
```

---

## Network Requirements

### Ports and Protocols

```
+===============================================================================+
|                   NETWORK REQUIREMENTS                                        |
+===============================================================================+

  INBOUND PORTS (To WALLIX Bastion)
  =================================

  +------------------------------------------------------------------------+
  | Port     | Protocol | Source           | Description                   |
  +----------+----------+------------------+-------------------------------+
  | 443      | TCP      | Users, API       | HTTPS Web UI, REST API        |
  | 22       | TCP      | Users            | SSH Proxy                     |
  | 3389     | TCP      | Users            | RDP Proxy                     |
  | 5900     | TCP      | Users            | VNC Proxy                     |
  | 23       | TCP      | Users            | Telnet Proxy (if enabled)     |
  | 3306     | TCP      | HA Peer          | MariaDB replication           |
  | 443      | TCP      | HA Peer          | Cluster sync                  |
  +----------+----------+------------------+-------------------------------+

  --------------------------------------------------------------------------

  OUTBOUND PORTS (From WALLIX Bastion)
  ====================================

  +------------------------------------------------------------------------+
  | Port     | Protocol | Destination      | Description                   |
  +----------+----------+------------------+-------------------------------+
  | 22       | TCP      | Targets          | SSH to targets                |
  | 3389     | TCP      | Targets          | RDP to targets                |
  | 5900     | TCP      | Targets          | VNC to targets                |
  | 23       | TCP      | Targets          | Telnet to targets             |
  | 389      | TCP      | LDAP Server      | LDAP authentication           |
  | 636      | TCP      | LDAP Server      | LDAPS authentication          |
  | 88       | TCP/UDP  | KDC              | Kerberos authentication       |
  | 464      | TCP/UDP  | KDC              | Kerberos password change      |
  | 1812     | UDP      | RADIUS Server    | RADIUS authentication         |
  | 1813     | UDP      | RADIUS Server    | RADIUS accounting             |
  | 514      | UDP      | Syslog Server    | Syslog (unencrypted)          |
  | 6514     | TCP      | Syslog Server    | Syslog over TLS               |
  | 443      | TCP      | NTP Server       | HTTPS time sync               |
  | 123      | UDP      | NTP Server       | NTP time sync                 |
  | 443      | TCP      | WALLIX Update    | Software updates              |
  | 3306     | TCP      | External DB      | External MariaDB              |
  +----------+----------+------------------+-------------------------------+

  --------------------------------------------------------------------------

  INDUSTRIAL PROTOCOL PORTS (If Used)
  ===================================

  +------------------------------------------------------------------------+
  | Port     | Protocol | Description                                      |
  +----------+----------+--------------------------------------------------+
  | 502      | TCP      | Modbus TCP                                       |
  | 20000    | TCP      | DNP3                                             |
  | 4840     | TCP      | OPC UA                                           |
  | 44818    | TCP      | EtherNet/IP                                      |
  | 102      | TCP      | IEC 61850 MMS                                    |
  | 47808    | UDP      | BACnet/IP                                        |
  +----------+----------+--------------------------------------------------+

  --------------------------------------------------------------------------

  NETWORK REQUIREMENTS
  ====================

  Bandwidth:
  +------------------------------------------------------------------------+
  | Session Type    | Bandwidth per Session | Notes                        |
  +-----------------+-----------------------+------------------------------+
  | SSH             | 10-50 Kbps            | Text-based                   |
  | RDP (Standard)  | 100-500 Kbps          | With compression             |
  | RDP (HD Video)  | 2-5 Mbps              | Video/CAD applications       |
  | VNC             | 100-500 Kbps          | Depends on resolution        |
  +-----------------+-----------------------+------------------------------+

  Latency:
  +------------------------------------------------------------------------+
  | Requirement              | Maximum Latency                             |
  +--------------------------+---------------------------------------------+
  | User to WALLIX           | < 100ms (interactive sessions)              |
  | WALLIX to Target         | < 50ms (session quality)                    |
  | WALLIX to Database       | < 10ms (local or same datacenter)           |
  | HA Cluster Nodes         | < 5ms (synchronous replication)             |
  +--------------------------+---------------------------------------------+

  DNS Resolution:
  * All target hostnames must be resolvable
  * Internal DNS recommended
  * DNS caching enabled on WALLIX

+===============================================================================+
```

---

## Storage Requirements

### Storage Configuration

```
+===============================================================================+
|                   STORAGE REQUIREMENTS                                        |
+===============================================================================+

  STORAGE LAYOUT
  ==============

  +------------------------------------------------------------------------+
  |                                                                        |
  |   Recommended Disk Layout                                              |
  |                                                                        |
  |   +------------------+  +------------------+  +------------------+     |
  |   | /                |  | /var/wab         |  | /var/wab/recorded|     |
  |   | (System)         |  | (Data)           |  | (Recordings)     |     |
  |   |                  |  |                  |  |                  |     |
  |   | 100 GB SSD       |  | 200 GB+ SSD      |  | 500 GB+ HDD/NAS  |     |
  |   |                  |  |                  |  |                  |     |
  |   | - OS             |  | - MariaDB        |  | - Session videos |     |
  |   | - Application    |  | - Config files   |  | - Audit data     |     |
  |   | - Logs           |  | - Temp data      |  | - Keystroke logs |     |
  |   +------------------+  +------------------+  +------------------+     |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  RECORDING STORAGE SIZING
  ========================

  Storage per session hour:
  +------------------------------------------------------------------------+
  | Protocol    | Quality        | Storage/Hour  | Notes                   |
  +-------------+----------------+---------------+-------------------------+
  | SSH         | Text only      | 1-5 MB        | Commands, output        |
  | SSH         | Full recording | 5-20 MB       | With timing data        |
  | RDP         | Standard       | 50-100 MB     | 1024x768, 16-bit        |
  | RDP         | High Quality   | 200-500 MB    | 1920x1080, 32-bit       |
  | RDP         | Video/CAD      | 500 MB - 1 GB | High frame rate         |
  | VNC         | Standard       | 30-80 MB      | Varies by activity      |
  +-------------+----------------+---------------+-------------------------+

  Monthly Storage Calculation:
  +------------------------------------------------------------------------+
  |                                                                        |
  | Formula:                                                               |
  |                                                                        |
  | Storage (GB) = Sessions/day x Avg Duration (hrs) x Storage Rate x Days |
  |                                                                        |
  | Example (Medium deployment):                                           |
  |   200 sessions/day x 2 hours x 100 MB x 30 days                        |
  |   = 200 x 2 x 0.1 GB x 30                                              |
  |   = 1,200 GB/month                                                     |
  |   = 1.2 TB/month                                                       |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  STORAGE RECOMMENDATIONS
  =======================

  +------------------------------------------------------------------------+
  | Storage Type         | Use Case                                        |
  +----------------------+-------------------------------------------------+
  | Local SSD            | System, Database, Config                        |
  | NFS/NAS              | Session recordings (HA environments)            |
  | SAN (iSCSI/FC)       | High-performance recording storage              |
  | Object Storage (S3)  | Long-term archive (with lifecycle policy)       |
  +----------------------+-------------------------------------------------+

  NAS/NFS Configuration:
  +------------------------------------------------------------------------+
  | Setting              | Recommendation                                  |
  +----------------------+-------------------------------------------------+
  | NFS Version          | NFSv4.1+                                        |
  | Mount Options        | rw,hard,intr,rsize=1048576,wsize=1048576        |
  | Permissions          | wab:wab ownership, 750 permissions              |
  | Performance          | 1 Gbps+ dedicated, low latency                  |
  +----------------------+-------------------------------------------------+

+===============================================================================+
```

---

## Sizing Guidelines

### Deployment Sizing Calculator

```
+===============================================================================+
|                   SIZING GUIDELINES                                           |
+===============================================================================+

  SIZING FACTORS
  ==============

  +------------------------------------------------------------------------+
  | Factor                    | Impact on Sizing                           |
  +---------------------------+--------------------------------------------+
  | Concurrent Sessions       | CPU, Memory (primary factor)               |
  | Total Users               | Database size, License                     |
  | Total Devices             | Database size, Memory                      |
  | Session Recording         | Storage I/O, Disk space                    |
  | RDP vs SSH Ratio          | CPU (RDP more intensive)                   |
  | Password Rotation         | Background CPU usage                       |
  | Retention Period          | Storage requirements                       |
  +---------------------------+--------------------------------------------+

  --------------------------------------------------------------------------

  SIZING CALCULATOR
  =================

  Input Your Requirements:
  +------------------------------------------------------------------------+
  | Parameter                        | Value        | Your Value           |
  +----------------------------------+--------------+----------------------+
  | Peak concurrent sessions         | ___          | [             ]      |
  | Average session duration (hours) | ___          | [             ]      |
  | Sessions per day                 | ___          | [             ]      |
  | Percentage RDP sessions          | ___%         | [             ]      |
  | Recording retention (days)       | ___          | [             ]      |
  | Total users                      | ___          | [             ]      |
  | Total devices                    | ___          | [             ]      |
  +----------------------------------+--------------+----------------------+

  Calculated Requirements:
  +------------------------------------------------------------------------+
  | Resource          | Formula                        | Result            |
  +-------------------+--------------------------------+-------------------+
  | CPU Cores         | (Sessions x 0.05) + 2          | ___               |
  | Memory (GB)       | (Sessions x 0.05) + 4          | ___               |
  | DB Storage (GB)   | (Users x 0.1) + (Devices x 0.2)| ___               |
  | Recording (GB/mo) | Sessions/day x Duration x Rate | ___               |
  +-------------------+--------------------------------+-------------------+

  --------------------------------------------------------------------------

  QUICK SIZING REFERENCE
  ======================

  +------------------------------------------------------------------------+
  | Concurrent   | CPU    | Memory  | Database | Recording   | Network     |
  | Sessions     | Cores  | (GB)    | (GB)     | (GB/month)  | (Gbps)      |
  +--------------+--------+---------+----------+-------------+-------------+
  | 25           | 4      | 8       | 50       | 150         | 1           |
  | 50           | 4      | 16      | 100      | 300         | 1           |
  | 100          | 8      | 16      | 150      | 600         | 1           |
  | 250          | 8      | 32      | 250      | 1,500       | 1           |
  | 500          | 16     | 64      | 500      | 3,000       | 10          |
  | 1000         | 32     | 128     | 1,000    | 6,000       | 10          |
  | 2000         | 64     | 256     | 2,000    | 12,000      | 10 (bonded) |
  +--------------+--------+---------+----------+-------------+-------------+

  Note: These are estimates. Actual requirements depend on session types,
  recording quality, and usage patterns. Add 30% buffer for growth.

+===============================================================================+
```

---

## Performance Tuning

### System Optimization

```
+===============================================================================+
|                   PERFORMANCE TUNING                                          |
+===============================================================================+

  MARIADB TUNING
  ==============

  /etc/mysql/mariadb.conf.d/50-server.cnf:
  +------------------------------------------------------------------------+
  | # Memory Settings                                                      |
  | shared_buffers = 4GB              # 25% of total RAM                   |
  | effective_cache_size = 12GB       # 75% of total RAM                   |
  | work_mem = 256MB                  # Per-operation memory               |
  | maintenance_work_mem = 1GB        # For maintenance operations         |
  |                                                                        |
  | # Connection Settings                                                  |
  | max_connections = 500             # Based on expected load             |
  |                                                                        |
  | # Write Performance                                                    |
  | wal_buffers = 64MB                                                     |
  | checkpoint_completion_target = 0.9                                     |
  | synchronous_commit = on           # Data safety                        |
  |                                                                        |
  | # Query Planning                                                       |
  | random_page_cost = 1.1            # For SSD storage                    |
  | effective_io_concurrency = 200    # For SSD storage                    |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  WALLIX APPLICATION TUNING
  =========================

  /etc/opt/wab/wabengine/wabengine.conf:
  +------------------------------------------------------------------------+
  | [performance]                                                          |
  | # Session handling                                                     |
  | max_concurrent_sessions = 1000                                         |
  | session_pool_size = 100                                                |
  | session_timeout = 3600                                                 |
  |                                                                        |
  | # Recording                                                            |
  | recording_buffer_size = 8MB                                            |
  | recording_compression = true                                           |
  | recording_compression_level = 6                                        |
  |                                                                        |
  | # Database connections                                                 |
  | db_pool_size = 50                                                      |
  | db_pool_max_overflow = 20                                              |
  |                                                                        |
  | # Cache settings                                                       |
  | auth_cache_ttl = 300                                                   |
  | policy_cache_ttl = 60                                                  |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  LINUX SYSTEM TUNING
  ===================

  /etc/sysctl.conf:
  +------------------------------------------------------------------------+
  | # Network tuning                                                       |
  | net.core.somaxconn = 65535                                             |
  | net.core.netdev_max_backlog = 65535                                    |
  | net.ipv4.tcp_max_syn_backlog = 65535                                   |
  | net.ipv4.ip_local_port_range = 1024 65535                              |
  |                                                                        |
  | # TCP tuning                                                           |
  | net.ipv4.tcp_tw_reuse = 1                                              |
  | net.ipv4.tcp_fin_timeout = 15                                          |
  | net.ipv4.tcp_keepalive_time = 300                                      |
  | net.ipv4.tcp_keepalive_probes = 5                                      |
  | net.ipv4.tcp_keepalive_intvl = 15                                      |
  |                                                                        |
  | # Memory tuning                                                        |
  | vm.swappiness = 10                                                     |
  | vm.dirty_ratio = 40                                                    |
  | vm.dirty_background_ratio = 10                                         |
  |                                                                        |
  | # File descriptors                                                     |
  | fs.file-max = 2097152                                                  |
  +------------------------------------------------------------------------+

  /etc/security/limits.conf:
  +------------------------------------------------------------------------+
  | wab soft nofile 65535                                                  |
  | wab hard nofile 65535                                                  |
  | wab soft nproc 65535                                                   |
  | wab hard nproc 65535                                                   |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  PERFORMANCE MONITORING
  ======================

  Key Metrics to Monitor:
  +------------------------------------------------------------------------+
  | Metric                 | Warning Threshold | Critical Threshold        |
  +------------------------+-------------------+---------------------------+
  | CPU Usage              | > 70%             | > 90%                     |
  | Memory Usage           | > 80%             | > 95%                     |
  | Disk I/O Wait          | > 20%             | > 40%                     |
  | Active DB Connections  | > 80% of max      | > 95% of max              |
  | Session Response Time  | > 2 seconds       | > 5 seconds               |
  | Recording Queue        | > 1000 items      | > 5000 items              |
  +------------------------+-------------------+---------------------------+

  Monitoring Commands:
  +------------------------------------------------------------------------+
  | # System overview                                                      |
  | wab-admin status                                                       |
  |                                                                        |
  | # Active sessions                                                      |
  | wab-admin session-count                                                |
  |                                                                        |
  | # Database connections                                                 |
  | sudo mysql -e "SHOW PROCESSLIST;" | wc -l                              |
  |                                                                        |
  | # System resources                                                     |
  | htop                                                                   |
  | iostat -x 5                                                            |
  +------------------------------------------------------------------------+

+===============================================================================+
```

---

## Capacity Planning

### Growth Planning

```
+===============================================================================+
|                   CAPACITY PLANNING                                           |
+===============================================================================+

  GROWTH FACTORS
  ==============

  +------------------------------------------------------------------------+
  | Factor                    | Typical Annual Growth                      |
  +---------------------------+--------------------------------------------+
  | Users                     | 10-20%                                     |
  | Devices                   | 15-25%                                     |
  | Sessions                  | 20-30%                                     |
  | Recording Storage         | 25-40%                                     |
  +---------------------------+--------------------------------------------+

  --------------------------------------------------------------------------

  CAPACITY PLANNING CHECKLIST
  ===========================

  QUARTERLY REVIEW
  +------------------------------------------------------------------------+
  | [ ] Current peak session count vs capacity                             |
  | [ ] Storage utilization and growth rate                                |
  | [ ] CPU and memory utilization trends                                  |
  | [ ] License usage vs limits                                            |
  | [ ] Backup storage requirements                                        |
  +------------------------------------------------------------------------+

  ANNUAL REVIEW
  +------------------------------------------------------------------------+
  | [ ] Project next year's growth                                         |
  | [ ] Plan hardware upgrades if needed                                   |
  | [ ] Review retention policies                                          |
  | [ ] Plan license renewal/upgrade                                       |
  | [ ] Review disaster recovery capacity                                  |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  SCALABILITY OPTIONS
  ===================

  Vertical Scaling (Scale Up):
  +------------------------------------------------------------------------+
  | Current     | Upgrade To   | Capacity Gain                             |
  +-------------+--------------+-------------------------------------------+
  | 4 CPU       | 8 CPU        | ~80% more sessions                        |
  | 16 GB RAM   | 32 GB RAM    | ~50% more concurrent sessions             |
  | HDD Storage | SSD Storage  | 3-5x I/O performance                      |
  +-------------+--------------+-------------------------------------------+

  Horizontal Scaling (Scale Out):
  +------------------------------------------------------------------------+
  | Architecture      | Capacity                                           |
  +-------------------+----------------------------------------------------+
  | Single Node       | Up to 500 concurrent sessions                      |
  | HA Pair           | Up to 1000 concurrent sessions (with failover)     |
  | Multi-Site        | 2000+ sessions (distributed)                       |
  +-------------------+----------------------------------------------------+

  --------------------------------------------------------------------------

  RECORDING RETENTION PLANNING
  ============================

  +------------------------------------------------------------------------+
  |                                                                        |
  |   Retention vs Storage Calculator                                      |
  |                                                                        |
  |   Current monthly recording: _____ GB                                  |
  |   Desired retention period:  _____ months                              |
  |                                                                        |
  |   Required storage = Monthly x Retention x 1.2 (buffer)                |
  |                                                                        |
  |   Example:                                                             |
  |   1,000 GB/month x 12 months x 1.2 = 14,400 GB (14.4 TB)               |
  |                                                                        |
  +------------------------------------------------------------------------+

  Archive Strategy:
  +------------------------------------------------------------------------+
  | Age              | Storage Tier      | Access                          |
  +------------------+-------------------+---------------------------------+
  | 0-30 days        | Primary SSD/NAS   | Immediate                       |
  | 30-90 days       | Secondary NAS     | Fast (minutes)                  |
  | 90-365 days      | Archive storage   | Slow (hours)                    |
  | 365+ days        | Cold storage/tape | Offline (days)                  |
  +------------------+-------------------+---------------------------------+

+===============================================================================+
```

---

## Performance Benchmarks

### Baseline Performance Metrics

```
+===============================================================================+
|                   PERFORMANCE BENCHMARKS                                     |
+===============================================================================+

  TESTED CONFIGURATION
  ====================

  Test Environment:
  +------------------------------------------------------------------------+
  | Component        | Specification                                        |
  +------------------+------------------------------------------------------+
  | Hardware         | 16 vCPU, 64 GB RAM, NVMe SSD                         |
  | OS               | Debian 12 (Bookworm)                                 |
  | WALLIX Version   | 12.1.x                                               |
  | MariaDB          | 10.11.x with optimized settings                      |
  | Network          | 10 Gbps, < 1ms latency to targets                    |
  +------------------+------------------------------------------------------+

  --------------------------------------------------------------------------

  SESSION ESTABLISHMENT BENCHMARKS
  ================================

  SSH Session Establishment:
  +------------------------------------------------------------------------+
  | Metric                          | Value          | Notes               |
  +---------------------------------+----------------+---------------------+
  | Average connection time         | 0.8 - 1.2 sec  | Auth + connection   |
  | Authentication only             | 0.2 - 0.4 sec  | LDAP + MFA          |
  | Target connection               | 0.3 - 0.5 sec  | Network dependent   |
  | Session initialization          | 0.2 - 0.3 sec  | Recording start     |
  | 99th percentile                 | 2.0 sec        | Under load          |
  +---------------------------------+----------------+---------------------+

  RDP Session Establishment:
  +------------------------------------------------------------------------+
  | Metric                          | Value          | Notes               |
  +---------------------------------+----------------+---------------------+
  | Average connection time         | 2.0 - 3.5 sec  | Auth + NLA + video  |
  | Authentication only             | 0.3 - 0.5 sec  | LDAP + MFA          |
  | Target connection (NLA)         | 0.8 - 1.5 sec  | NLA negotiation     |
  | First frame displayed           | 1.5 - 2.5 sec  | Screen visible      |
  | 99th percentile                 | 5.0 sec        | Under load          |
  +---------------------------------+----------------+---------------------+

  VNC Session Establishment:
  +------------------------------------------------------------------------+
  | Metric                          | Value          | Notes               |
  +---------------------------------+----------------+---------------------+
  | Average connection time         | 1.0 - 2.0 sec  | Auth + connection   |
  | First frame displayed           | 1.2 - 2.2 sec  | Screen visible      |
  +---------------------------------+----------------+---------------------+

  --------------------------------------------------------------------------

  THROUGHPUT BENCHMARKS
  =====================

  Maximum Concurrent Sessions:
  +------------------------------------------------------------------------+
  | System Size      | SSH Sessions | RDP Sessions | Mixed (50/50)         |
  +------------------+--------------+--------------+-----------------------+
  | Small (4C/16GB)  | 200          | 100          | 150                   |
  | Medium (8C/32GB) | 500          | 250          | 375                   |
  | Large (16C/64GB) | 1000         | 500          | 750                   |
  | XL (32C/128GB)   | 2000         | 1000         | 1500                  |
  +------------------+--------------+--------------+-----------------------+

  Sessions Per Second (New Session Rate):
  +------------------------------------------------------------------------+
  | System Size      | SSH          | RDP          | Mixed                 |
  +------------------+--------------+--------------+-----------------------+
  | Small            | 10/sec       | 5/sec        | 7/sec                 |
  | Medium           | 25/sec       | 12/sec       | 18/sec                |
  | Large            | 50/sec       | 25/sec       | 37/sec                |
  | XL               | 100/sec      | 50/sec       | 75/sec                |
  +------------------+--------------+--------------+-----------------------+

  --------------------------------------------------------------------------

  CREDENTIAL OPERATION BENCHMARKS
  ===============================

  Password Operations:
  +------------------------------------------------------------------------+
  | Operation                       | Average Time   | 99th Percentile     |
  +---------------------------------+----------------+---------------------+
  | Password checkout               | 50 - 100 ms    | 200 ms              |
  | Password injection (SSH)        | 20 - 50 ms     | 100 ms              |
  | Password injection (RDP)        | 50 - 100 ms    | 200 ms              |
  | Password rotation (Linux)       | 1 - 3 sec      | 5 sec               |
  | Password rotation (Windows)     | 2 - 5 sec      | 10 sec              |
  | Bulk rotation (100 accounts)    | 2 - 5 min      | 10 min              |
  +---------------------------------+----------------+---------------------+

  --------------------------------------------------------------------------

  API PERFORMANCE BENCHMARKS
  ==========================

  API Response Times:
  +------------------------------------------------------------------------+
  | Endpoint                        | Average        | 99th Percentile     |
  +---------------------------------+----------------+---------------------+
  | GET /api/v2/users (list 100)    | 50 ms          | 150 ms              |
  | GET /api/v2/devices (list 100)  | 40 ms          | 120 ms              |
  | POST /api/v2/users (create)     | 80 ms          | 200 ms              |
  | POST /api/v2/sessions/search    | 100 ms         | 300 ms              |
  | GET /api/v2/audit/logs          | 150 ms         | 500 ms              |
  +---------------------------------+----------------+---------------------+

  API Throughput:
  +------------------------------------------------------------------------+
  | Operation                       | Requests/sec   | Notes               |
  +---------------------------------+----------------+---------------------+
  | Read operations                 | 500 - 1000     | GET endpoints       |
  | Write operations                | 100 - 200      | POST/PUT/DELETE     |
  | Bulk operations                 | 50 - 100       | Batch imports       |
  +---------------------------------+----------------+---------------------+

  --------------------------------------------------------------------------

  RECORDING PERFORMANCE BENCHMARKS
  ================================

  Recording Storage and I/O:
  +------------------------------------------------------------------------+
  | Protocol        | Recording Rate | Disk I/O      | Storage/Hour        |
  +-----------------+----------------+---------------+---------------------+
  | SSH (text)      | 10 - 50 KB/s   | Minimal       | 5 - 20 MB           |
  | SSH (full)      | 50 - 200 KB/s  | Low           | 20 - 80 MB          |
  | RDP (standard)  | 200 - 500 KB/s | Medium        | 100 - 200 MB        |
  | RDP (HD)        | 500 KB - 2 MB/s| High          | 200 - 500 MB        |
  | VNC             | 100 - 400 KB/s | Medium        | 50 - 150 MB         |
  +-----------------+----------------+---------------+---------------------+

  Recording Playback:
  +------------------------------------------------------------------------+
  | Operation                       | Performance    | Notes               |
  +---------------------------------+----------------+---------------------+
  | Playback start (local)          | < 2 sec        | First frame         |
  | Playback start (NAS)            | 2 - 5 sec      | Network dependent   |
  | Search indexing (per hour rec)  | 30 - 60 sec    | OCR processing      |
  | Search query (indexed)          | 0.5 - 2 sec    | Full-text search    |
  +---------------------------------+----------------+---------------------+

+===============================================================================+
```

### Performance Testing Methodology

```
+===============================================================================+
|                   PERFORMANCE TESTING PROCEDURES                             |
+===============================================================================+

  LOAD TESTING PROCEDURE
  ======================

  Preparation:
  +------------------------------------------------------------------------+
  | 1. Configure test environment matching production specs                |
  | 2. Create test users and targets (representative sample)               |
  | 3. Disable non-essential logging during baseline tests                 |
  | 4. Establish baseline metrics with single user                         |
  +------------------------------------------------------------------------+

  Test Scenarios:
  +------------------------------------------------------------------------+
  | Scenario          | Description                    | Duration          |
  +-------------------+--------------------------------+-------------------+
  | Ramp-up           | Gradually increase sessions    | 30 min            |
  | Steady state      | Hold at target load            | 60 min            |
  | Spike             | Sudden session surge           | 5 min             |
  | Endurance         | Sustained load over time       | 4-8 hours         |
  +-------------------+--------------------------------+-------------------+

  --------------------------------------------------------------------------

  KEY METRICS TO MEASURE
  ======================

  System Metrics:
  +------------------------------------------------------------------------+
  | Metric                          | Threshold      | Alert Level         |
  +---------------------------------+----------------+---------------------+
  | CPU utilization                 | < 70%          | > 85%               |
  | Memory utilization              | < 80%          | > 90%               |
  | Disk I/O wait                   | < 10%          | > 20%               |
  | Network utilization             | < 70%          | > 85%               |
  | Database connections            | < 80% of max   | > 90% of max        |
  +---------------------------------+----------------+---------------------+

  Application Metrics:
  +------------------------------------------------------------------------+
  | Metric                          | Target         | Unacceptable        |
  +---------------------------------+----------------+---------------------+
  | Session establishment time      | < 2 sec        | > 5 sec             |
  | API response time (p95)         | < 200 ms       | > 1 sec             |
  | Authentication time             | < 500 ms       | > 2 sec             |
  | Error rate                      | < 0.1%         | > 1%                |
  | Session failure rate            | < 0.01%        | > 0.1%              |
  +---------------------------------+----------------+---------------------+

  --------------------------------------------------------------------------

  BENCHMARK COMMANDS
  ==================

  System Performance:
  +------------------------------------------------------------------------+
  | # CPU and memory                                                       |
  | vmstat 1 60 | tee /tmp/vmstat.log                                      |
  |                                                                        |
  | # Disk I/O                                                             |
  | iostat -x 1 60 | tee /tmp/iostat.log                                   |
  |                                                                        |
  | # Network                                                              |
  | sar -n DEV 1 60 | tee /tmp/network.log                                 |
  |                                                                        |
  | # Process details                                                      |
  | pidstat -p $(pgrep -d, -f wallix) 1 60 | tee /tmp/process.log          |
  +------------------------------------------------------------------------+

  Database Performance:
  +------------------------------------------------------------------------+
  | # Connection count                                                     |
  | watch -n 5 "sudo mysql -e 'SHOW PROCESSLIST;' | wc -l"                 |
  |                                                                        |
  | # Slow queries                                                         |
  | sudo mysql -e "SELECT * FROM performance_schema.events_statements_summary_by_digest |
  |   ORDER BY SUM_TIMER_WAIT DESC LIMIT 10;"                              |
  |                                                                        |
  | # Cache hit ratio                                                      |
  | sudo mysql -e "SHOW GLOBAL STATUS LIKE 'Innodb_buffer_pool_read%';"    |
  |   # Calculate hit ratio from read_requests vs reads                    |
  +------------------------------------------------------------------------+

  Application Performance:
  +------------------------------------------------------------------------+
  | # Active sessions                                                      |
  | wabadmin sessions --active --count                                     |
  |                                                                        |
  | # Session establishment timing                                         |
  | time ssh -o ProxyCommand="ssh -W %h:%p wallix-user@bastion"            |
  |   target-user@target-server hostname                                   |
  |                                                                        |
  | # API response time                                                    |
  | curl -w "%{time_total}" -o /dev/null -s                                |
  |   -H "Authorization: Bearer $TOKEN"                                    |
  |   https://bastion/api/v2/users                                         |
  +------------------------------------------------------------------------+

+===============================================================================+
```

---

## See Also

**Related Sections:**
- [26 - Performance Benchmarks](../26-performance-benchmarks/README.md) - Capacity planning and load testing
- [16 - Cloud Deployment](../16-cloud-deployment/README.md) - On-premises deployment patterns

**Related Documentation:**
- [Install Guide](/install/README.md) - Deployment architecture and sizing

**Official Resources:**
- [WALLIX Documentation](https://pam.wallix.one/documentation)

---

## Next Steps

Continue to [29 - Upgrade Guide](../20-upgrade-guide/README.md) for version upgrade procedures.
