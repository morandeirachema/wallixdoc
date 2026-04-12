# Prerequisites - 5-Site WALLIX Bastion Deployment

> Comprehensive prerequisites checklist for deploying 5 WALLIX Bastion sites with per-site FortiAuthenticator HA pairs and per-site Active Directory

---

## Table of Contents

1. [Deployment Overview](#deployment-overview)
2. [Hardware Requirements](#hardware-requirements)
3. [Network Requirements](#network-requirements)
4. [Software Requirements](#software-requirements)
5. [Access Manager Prerequisites](#access-manager-prerequisites)
6. [Licensing Requirements](#licensing-requirements)
7. [Security Prerequisites](#security-prerequisites)
8. [DNS and NTP Requirements](#dns-and-ntp-requirements)
9. [Backup Storage Requirements](#backup-storage-requirements)
10. [Pre-Deployment Checklist](#pre-deployment-checklist)

---

> **Architecture note**: Each of the 5 sites contains its own independent FortiAuthenticator HA pair (Primary + Secondary) and its own Active Directory domain controller, both located in the **Cyber VLAN**. The WALLIX Bastion appliances, HAProxy, and RDS are in the **DMZ VLAN**. The Fortigate firewall handles inter-VLAN routing. The Access Manager is client-managed; our scope is Bastion-side integration only.

---

## Deployment Overview

### Architecture Summary

This deployment consists of:

| Component | Quantity | Configuration | Location |
|-----------|----------|---------------|----------|
| **WALLIX Access Manager** | 2 | HA (Active-Passive), client-managed | 2 separate datacenters (NOT our deployment) |
| **WALLIX Bastion Sites** | 5 | Each site: 2 HW appliances (HA) | Geographically distributed datacenters |
| **HAProxy Load Balancer** | 10 | 2 per site (Active-Passive) | DMZ VLAN at each site |
| **WALLIX RDS Jump Host** | 5 | 1 per site | DMZ VLAN at each site |
| **FortiAuthenticator** | 10 | 2 per site (Primary/Secondary HA pair) | Cyber VLAN at each site |
| **Active Directory DC** | 5 | 1 per site | Cyber VLAN at each site |

**Scale**: Approximately 100-200 target servers per site; approximately 25 privileged users per site.

### Key Architectural Principles

- **VLAN Separation**: DMZ VLAN (Bastion, HAProxy, RDS) is separate from Cyber VLAN (FortiAuth HA pair, AD). Fortigate provides inter-VLAN routing.
- **Per-Site MFA**: Each site has its own FortiAuthenticator HA pair in the Cyber VLAN — no centralized FortiAuth.
- **Per-Site AD**: Each site has its own AD domain controller in the Cyber VLAN. Both Bastion and FortiAuth connect to the local site's AD.
- **No Inter-Site Bastion Communication**: Bastions do NOT communicate directly between sites. All inter-site traffic routes through the Access Manager via MPLS.
- **Access Manager is Client-Managed**: We configure only the Bastion-side integration. See [15-access-manager-integration.md](15-access-manager-integration.md).
- **High Availability**: Both Active-Active and Active-Passive options documented (see [02-ha-architecture.md](02-ha-architecture.md)).

```
+===============================================================================+
|  5-SITE DEPLOYMENT OVERVIEW                                                   |
+===============================================================================+
|                                                                               |
|  Access Manager 1 (DC-A)  <---HA--->  Access Manager 2 (DC-B)                 |
|  CLIENT-MANAGED                       CLIENT-MANAGED                          |
|          |                                    |                               |
|          +------------------------------------+                               |
|                          MPLS Network                                         |
|       +-------------------+----+----+----+--------------------+               |
|       |                   |         |         |               |               |
|  +----v----+         +----v----+   ...   +----v----+    +----v----+           |
|  | Site 1  |         | Site 2  |         | Site 4  |    | Site 5  |           |
|  | (DC-1)  |         | (DC-2)  |         | (DC-4)  |    | (DC-5)  |           |
|  +---------+         +---------+         +---------+    +---------+           |
|                                                                               |
|  Each Site Contains (DMZ VLAN):                                               |
|  - 2x HAProxy (Active-Passive with Keepalived VRRP)                           |
|  - 2x WALLIX Bastion HW Appliances (Active-Active or Active-Passive)          |
|  - 1x WALLIX RDS (Jump host for OT RemoteApp access)                          |
|                                                                               |
|  Each Site Contains (Cyber VLAN):                                             |
|  - 2x FortiAuthenticator (Primary/Secondary HA pair)                          |
|  - 1x Active Directory domain controller                                      |
|  - ~100-200 target servers (Windows Server 2022, RHEL 10/9)                   |
|                                                                               |
+===============================================================================+
```

---

## Hardware Requirements

### Per-Site Hardware Summary

Each of the 5 sites requires:

| Component | Quantity | VLAN | Purpose |
|-----------|----------|------|---------|
| HAProxy Servers | 2 | DMZ | Active-Passive load balancer pair |
| WALLIX Bastion Appliances | 2 | DMZ | Active-Active or Active-Passive HA cluster |
| WALLIX RDS Server | 1 | DMZ | Jump host for OT access via RemoteApp |
| FortiAuthenticator | 2 | Cyber | Primary/Secondary HA pair for RADIUS MFA |
| Active Directory DC | 1 | Cyber | LDAP/AD for user authentication and lookup |

### Total Hardware (All 5 Sites)

| Component | Total Quantity | Notes |
|-----------|----------------|-------|
| HAProxy Servers | 10 | 2 per site, DMZ VLAN |
| WALLIX Bastion HW Appliances | 10 | 2 per site, DMZ VLAN |
| WALLIX RDS Servers | 5 | 1 per site, DMZ VLAN |
| FortiAuthenticator | 10 | 2 per site, Cyber VLAN |
| Active Directory DC | 5 | 1 per site, Cyber VLAN |

---

### HAProxy Servers (2 per site)

**Deployment**: Virtual machines or physical servers

| Component | Specification | Notes |
|-----------|---------------|-------|
| **CPU** | 4 vCPU | 2 GHz+ per core |
| **RAM** | 8 GB | DDR4 recommended |
| **Disk** | 50 GB SSD | System and logs |
| **Network** | 2x 1 GbE NICs | Redundant bonded interfaces |
| **OS** | Debian 12 or RHEL 9 | 64-bit |

**Per Site**: 2 HAProxy servers (Active-Passive with Keepalived VRRP)

**Total for 5 Sites**: 10 HAProxy servers

---

### WALLIX Bastion HW Appliances (2 per site)

**Deployment**: Hardware appliances (specific model to be confirmed with WALLIX)

| Component | Specification | Notes |
|-----------|---------------|-------|
| **Model** | WALLIX Bastion HW Appliance | Contact WALLIX for sizing |
| **CPU** | 8+ cores | Hardware appliance (x86_64) |
| **RAM** | 16+ GB | Depending on concurrent sessions |
| **System Disk** | 500 GB+ SSD/NVMe | OS, application, database |
| **Recording Disk** | 2 TB+ | Session recordings (NAS/SAN optional) |
| **Network** | 2x 1 GbE NICs | Bonded for redundancy |
| **IPMI/iLO** | Required | Remote management and monitoring |
| **Redundant PSU** | Yes | Recommended for HA |

**Per Site**: 2 WALLIX Bastion appliances (Active-Active or Active-Passive)

**Total for 5 Sites**: 10 WALLIX Bastion appliances

**Recording Storage Calculation**:
- Estimate: 100-200 MB per RDP session hour
- Estimate: 5-20 MB per SSH session hour
- Retention period: 90 days recommended
- Example: 100 sessions/day × 2 hours × 100 MB × 90 days = 1.8 TB per site

---

### WALLIX RDS (1 per site)

**Deployment**: Windows Server 2022 (VM or physical)

| Component | Specification | Notes |
|-----------|---------------|-------|
| **CPU** | 4 vCPU | 2 GHz+ per core |
| **RAM** | 8 GB | More for concurrent OT sessions |
| **Disk** | 100 GB | C: drive for OS and apps |
| **Network** | 1 GbE NIC | Single NIC sufficient |
| **OS** | Windows Server 2022 | Standard or Datacenter |
| **RDS Licenses** | Per user or per device | Required for RemoteApp |

**Per Site**: 1 WALLIX RDS server

**Total for 5 Sites**: 5 WALLIX RDS servers

**Purpose**: Jump host for Operational Technology (OT) access using RemoteApp (RDP-only protocols)

---

### FortiAuthenticator HA Pair (2 per site, Cyber VLAN)

**Deployment**: Hardware appliance (e.g., FortiAuthenticator 300F) or VM in Cyber VLAN

| Component | Specification | Notes |
|-----------|---------------|-------|
| **Model** | FortiAuthenticator 300F or equivalent VM | Sized for ~25 users per site |
| **CPU** | 4+ cores | Hardware or vCPU |
| **RAM** | 8+ GB | |
| **Disk** | 100+ GB | Logs, user database |
| **Network** | 2x 1 GbE NICs | Management (Cyber VLAN) + HA link |
| **VLAN** | Cyber VLAN | Separate from DMZ VLAN |

**Per Site**: 2 FortiAuthenticator appliances (Primary + Secondary HA pair)

**Total for 5 Sites**: 10 FortiAuthenticator appliances

**Cyber VLAN IPs**:
- FortiAuthenticator-1 (Primary): `10.10.X.50`
- FortiAuthenticator-2 (Secondary): `10.10.X.51`
- FortiAuth VIP (Management): `10.10.X.52`

See [03-fortiauthenticator-ha.md](03-fortiauthenticator-ha.md) for full setup guide.

---

### Active Directory Domain Controller (1 per site, Cyber VLAN)

**Deployment**: Windows Server 2022 VM in Cyber VLAN

| Component | Specification | Notes |
|-----------|---------------|-------|
| **CPU** | 4 vCPU | 2 GHz+ |
| **RAM** | 8 GB | |
| **Disk** | 100 GB+ | OS + AD database |
| **Network** | 1x 1 GbE NIC | In Cyber VLAN |
| **OS** | Windows Server 2022 | Standard or Datacenter |
| **Roles** | AD DS, DNS Server | Required |
| **VLAN** | Cyber VLAN | Separate from DMZ VLAN |

**Per Site**: 1 AD domain controller

**Total for 5 Sites**: 5 AD domain controllers

**Cyber VLAN IP**: `10.10.X.60` (where X = site number)

See [04-ad-per-site.md](04-ad-per-site.md) for full integration guide.

---

### Hardware Checklist

```
+===============================================================================+
|  HARDWARE READINESS CHECKLIST (Per Site)                                      |
+===============================================================================+

Site 1 (Site 1 DC) - DMZ VLAN:
[ ] 2x HAProxy servers provisioned (physical or VM)
[ ] 2x WALLIX Bastion HW appliances received and racked
[ ] 1x WALLIX RDS server (Windows Server 2022) ready
[ ] All servers have redundant power supplies (physical)
[ ] All servers have IPMI/iLO access configured
[ ] All servers have network cables connected (bonded NICs)

Site 1 (Site 1 DC) - Cyber VLAN:
[ ] 2x FortiAuthenticator provisioned (10.10.1.50, 10.10.1.51)
[ ] 1x Windows Server 2022 for AD DC provisioned (10.10.1.60)
[ ] Inter-VLAN firewall rules configured on Fortigate (Cyber <-> DMZ)
[ ] FortiAuthenticator licenses available (300F or VM)
[ ] FortiToken Mobile licenses available (~30 per site)

Repeat per-site checklist for Sites 2-5 (adjust IPs: 10.10.X.50-60).

+===============================================================================+
```

---

## Network Requirements

### Network Topology Overview

```
+===============================================================================+
|  NETWORK TOPOLOGY - PER-SITE VLAN DESIGN                                      |
+===============================================================================+
|                                                                               |
|  Access Manager 1 (DC-A)  <--HA-->  Access Manager 2 (DC-B)  [CLIENT-MANAGED] |
|         |                                 |                                   |
|         +----------------+----------------+                                   |
|                          MPLS Network                                         |
|                          |                                                    |
|         +----------------+----------------+----------------+                  |
|         |                |                |                |                  |
|    Site 1 (X=1)     Site 2 (X=2)     Site 3 (X=3)    Sites 4-5               |
|                                                                               |
|  Per-Site VLAN Design (where X = site number 1-5):                           |
|                                                                               |
|  DMZ VLAN (10.10.X.0/25):                                                    |
|    HAProxy VIP:    10.10.X.100                                                |
|    HAProxy-1:      10.10.X.5                                                  |
|    HAProxy-2:      10.10.X.6                                                  |
|    Bastion-1:      10.10.X.11                                                 |
|    Bastion-2:      10.10.X.12                                                 |
|    WALLIX RDS:     10.10.X.30                                                 |
|                                                                               |
|  Cyber VLAN (10.10.X.128/25):                                                 |
|    FortiAuth-1:    10.10.X.50                                                 |
|    FortiAuth-2:    10.10.X.51                                                 |
|    FortiAuth VIP:  10.10.X.52                                                 |
|    AD DC:          10.10.X.60                                                 |
|                                                                               |
|  Fortigate (10.10.X.1) routes between DMZ VLAN and Cyber VLAN.               |
|                                                                               |
+===============================================================================+
```

### MPLS Connectivity Requirements

| Parameter | Requirement | Notes |
|-----------|-------------|-------|
| **Bandwidth** | 100 Mbps minimum per site | 200+ Mbps recommended for production |
| **Latency** | < 50ms RTT preferred | < 100ms acceptable |
| **Packet Loss** | < 0.1% | For real-time session quality |
| **Redundancy** | Dual MPLS paths recommended | For failover |
| **QoS** | Recommended for session traffic | Prioritize SSH/RDP sessions |

**Total MPLS Bandwidth**: 500 Mbps minimum (100 Mbps × 5 sites)

---

### IP Address Allocation (Example)

Adjust according to your network design.

#### Site 1 (Site 1 DC)

**DMZ VLAN (10.10.1.0/25)**:

| Component | IP Address | Notes |
|-----------|------------|-------|
| HAProxy-1 | 10.10.1.5 | Active node |
| HAProxy-2 | 10.10.1.6 | Passive node |
| HAProxy VIP | 10.10.1.100 | Keepalived virtual IP |
| Bastion-1 | 10.10.1.11 | Active (or Active-Active) |
| Bastion-2 | 10.10.1.12 | Active or Passive |
| WALLIX RDS | 10.10.1.30 | Jump host |
| Fortigate (DMZ interface) | 10.10.1.1 | Default gateway for DMZ VLAN |

**Cyber VLAN (10.10.1.128/25)**:

| Component | IP Address | Notes |
|-----------|------------|-------|
| FortiAuthenticator-1 | 10.10.1.50 | Primary RADIUS |
| FortiAuthenticator-2 | 10.10.1.51 | Secondary RADIUS |
| FortiAuth VIP | 10.10.1.52 | Management VIP (floats to active) |
| Active Directory DC | 10.10.1.60 | LDAP/DNS for this site |
| Fortigate (Cyber interface) | 10.10.1.129 | Default gateway for Cyber VLAN |

**Repeat the same pattern for Sites 2-5, substituting X = 2, 3, 4, 5 in the third octet.**

---

### Firewall Rules: Access Manager ↔ Bastion (MPLS)

| Source         | Destination           | Port | Protocol  | Purpose                      | Mandatory |
|----------------|-----------------------|------|-----------|------------------------------|-----------|
| Access Manager | Bastion (HAProxy VIP) | 443  | TCP/HTTPS | API, session brokering       | Yes |
| Bastion        | Access Manager        | 443  | TCP/HTTPS | SSO callbacks, health checks | Yes |

### Firewall Rules: Bastion (DMZ) ↔ Cyber VLAN (via Fortigate, Per Site)

| Source | Destination | Port | Protocol | Purpose | Mandatory |
|--------|-------------|------|----------|---------|-----------|
| Bastion (DMZ) | FortiAuth-1 (Cyber) | 1812 | UDP | RADIUS authentication | Yes |
| Bastion (DMZ) | FortiAuth-1 (Cyber) | 1813 | UDP | RADIUS accounting | Yes |
| Bastion (DMZ) | FortiAuth-2 (Cyber) | 1812 | UDP | RADIUS failover | Yes |
| Bastion (DMZ) | FortiAuth-2 (Cyber) | 1813 | UDP | RADIUS failover accounting | Yes |
| Bastion (DMZ) | AD DC (Cyber) | 636 | TCP | LDAPS user/group lookup | Yes |
| Bastion (DMZ) | AD DC (Cyber) | 389 | TCP | LDAP (fallback) | Recommended |
| Bastion (DMZ) | AD DC (Cyber) | 3268 | TCP | Global Catalog | Optional |
| Bastion (DMZ) | AD DC (Cyber) | 88 | TCP/UDP | Kerberos | Optional |

### Firewall Rules: Cyber VLAN Internal (Same VLAN, No Fortigate Needed)

| Source | Destination | Port | Protocol | Purpose | Mandatory |
|--------|-------------|------|----------|---------|-----------|
| FortiAuth-1 (Cyber) | AD DC (Cyber) | 389 | TCP | LDAP user sync | Yes |
| FortiAuth-1 (Cyber) | AD DC (Cyber) | 636 | TCP | LDAPS user sync (recommended) | Yes |
| FortiAuth-2 (Cyber) | AD DC (Cyber) | 389 | TCP | LDAP user sync | Yes |
| FortiAuth-1 (Cyber) | FortiAuth-2 (Cyber) | 443 | TCP | HA replication sync | Yes |

### Firewall Rules: General

| Source         | Destination           | Port | Protocol  | Purpose                      | Mandatory |
|----------------|-----------------------|------|-----------|------------------------------|-----------|
| Bastion        | NTP Server            | 123  | UDP       | Time synchronization         | Yes |
| Bastion        | DNS Server            | 53   | UDP/TCP   | Name resolution              | Yes |
| Admin Network  | Bastion               | 2242 | TCP       | CLI administration (SSH)     | Yes |
| Bastion        | SMTP Server           | 25   | TCP       | SMTP notifications           | Yes |
| Bastion        | SMTP Server           | 587  | TCP       | SMTP+STARTTLS notifications  | Recommended |
| Bastion        | SIEM/Syslog           | 514  | UDP       | Syslog (unencrypted)         | Optional |
| Bastion        | SIEM/Syslog           | 6514 | TCP       | Syslog over TLS              | Recommended |

---

### Firewall Rules: Bastion ↔ Bastion (HA Cluster, Within Site)

| Source    | Destination | Port      | Protocol  | Purpose                              | Mandatory |
|-----------|-------------|-----------|-----------|--------------------------------------|-----------|
| Bastion-1 | Bastion-2   | 2242      | TCP       | SSH tunnel for DB replication (autossh) | Yes |
| Bastion-2 | Bastion-1   | 2242      | TCP       | SSH tunnel for DB replication (autossh) | Yes |
| Bastion-1 | Bastion-2   | 3306      | TCP       | MariaDB replication (via SSH tunnel)   | Yes |
| Bastion-2 | Bastion-1   | 3306      | TCP       | MariaDB replication (via SSH tunnel)   | Yes |
| Bastion-1 | Bastion-2   | 3307      | TCP       | MariaDB replication source port        | Yes |
| Bastion-2 | Bastion-1   | 3307      | TCP       | MariaDB replication source port        | Yes |
| Bastion-1 | Bastion-2   | 443       | TCP/HTTPS | Configuration sync                     | Yes |

**IMPORTANT**: There is NO direct Bastion-to-Bastion communication BETWEEN sites (Site 1 ↔ Site 2, etc.). All inter-site coordination happens via Access Managers.

---

### Firewall Rules: HAProxy ↔ Bastion (Within Site)

| Source  | Destination | Port | Protocol  | Purpose                   | Mandatory |
|---------|-------------|------|-----------|---------------------------|-----------|
| HAProxy | Bastion-1   | 443  | TCP/HTTPS | Load balancing to Bastion | Yes |
| HAProxy | Bastion-2   | 443  | TCP/HTTPS | Load balancing to Bastion | Yes |
| HAProxy | Bastion-1   | 22   | TCP       | SSH proxy                 | Yes |
| HAProxy | Bastion-2   | 22   | TCP       | SSH proxy                 | Yes |
| HAProxy | Bastion-1   | 3389 | TCP       | RDP proxy                 | Yes |
| HAProxy | Bastion-2   | 3389 | TCP       | RDP proxy                 | Yes |

---

### Firewall Rules: Bastion → Target Systems

| Source  | Destination               | Port       | Protocol | Purpose              | Mandatory |
|---------|---------------------------|------------|----------|----------------------|-----------|
| Bastion | Windows Servers           | 3389       | TCP      | RDP access           | Yes |
| Bastion | Windows Servers           | 5985-5986  | TCP      | WinRM (HTTP/HTTPS)   | Optional |
| Bastion | Linux Servers (RHEL 10/9) | 22         | TCP      | SSH access           | Yes |
| Bastion | Database Servers          | 1521       | TCP      | Oracle DB            | As needed |
| Bastion | Database Servers          | 3306       | TCP      | MySQL/MariaDB        | As needed |
| Bastion | Database Servers          | 5432       | TCP      | PostgreSQL           | As needed |
| Bastion | Database Servers          | 1433       | TCP      | Microsoft SQL Server | As needed |

---

### Bandwidth Planning

| Session Type | Bandwidth per Session | Notes |
|--------------|----------------------|-------|
| SSH (text) | 10-50 Kbps | Command-line interface |
| SSH (interactive) | 50-200 Kbps | Text editors, interactive tools |
| RDP (standard) | 100-500 Kbps | 1024×768, 16-bit color, compression |
| RDP (HD video) | 2-5 Mbps | 1920×1080, 32-bit color, video |
| VNC | 100-500 Kbps | Varies by resolution and activity |

**Example Calculation (Per Site)**:
- 50 concurrent SSH sessions × 100 Kbps = 5 Mbps
- 50 concurrent RDP sessions × 500 Kbps = 25 Mbps
- Total per site: ~30 Mbps + 30% buffer = 40 Mbps
- Total for 5 sites: 200 Mbps

**MPLS requirement (100 Mbps per site)** covers typical usage with buffer for peak loads.

---

### Network Checklist

```
+===============================================================================+
|  NETWORK READINESS CHECKLIST                                                  |
+===============================================================================+

MPLS Connectivity:
[ ] MPLS circuits installed between Access Managers and all 5 sites
[ ] Bandwidth verified: 100+ Mbps per site
[ ] Latency tested: < 50ms RTT between AM and each site
[ ] Redundant MPLS paths configured (if applicable)
[ ] QoS policies configured for session traffic (optional)

VLAN Design (Per Site):
[ ] DMZ VLAN created (10.10.X.0/25): HAProxy, Bastion, RDS
[ ] Cyber VLAN created (10.10.X.128/25): FortiAuth HA pair, AD DC
[ ] Fortigate configured as inter-VLAN router (DMZ <-> Cyber)
[ ] VLAN trunking configured on switches

Fortigate Inter-VLAN Firewall Rules (Per Site):
[ ] Bastion (DMZ) → FortiAuth-1 (Cyber): 1812/1813 UDP ALLOWED
[ ] Bastion (DMZ) → FortiAuth-2 (Cyber): 1812/1813 UDP ALLOWED
[ ] Bastion (DMZ) → AD DC (Cyber): 636 TCP ALLOWED (LDAPS)
[ ] Bastion (DMZ) → AD DC (Cyber): 389 TCP ALLOWED (LDAP fallback)
[ ] FortiAuth (Cyber) → AD DC (Cyber): 389/636 TCP ALLOWED (same VLAN)
[ ] FortiAuth-1 ↔ FortiAuth-2: 443 TCP ALLOWED (HA sync)

Other Firewall Rules:
[ ] Access Manager → Bastion (HTTPS 443 via MPLS) allowed
[ ] Bastion → Access Manager (HTTPS 443 via MPLS) allowed
[ ] Bastion → NTP, DNS allowed
[ ] Bastion → Target systems (SSH 22, RDP 3389, WinRM 5985/5986) allowed
[ ] HAProxy → Bastion nodes (HTTPS 443, SSH 22, RDP 3389) allowed
[ ] Bastion-1 ↔ Bastion-2 (SSH 2242, MariaDB 3306/3307) allowed (per site)
[ ] Bastion → SIEM/Syslog (514/6514) allowed (optional)

IP Addressing:
[ ] DMZ VLAN IPs allocated: HAProxy (X.5, X.6, X.100), Bastion (X.11, X.12), RDS (X.30)
[ ] Cyber VLAN IPs allocated: FortiAuth (X.50, X.51, X.52), AD DC (X.60)
[ ] Static IP assignments documented
[ ] IP routing verified between DMZ and Cyber VLANs

+===============================================================================+
```

---

## Software Requirements

### Operating Systems

| Component          | Operating System               | Version                | Notes |
|--------------------|--------------------------------|------------------------|-------|
| **WALLIX Bastion** | Pre-installed on appliance     | WALLIX Bastion 12.3.2  | Hardened Linux (Debian-based) |
| **HAProxy**        | Debian 12 (Bookworm) or RHEL 9 | Latest stable          | 64-bit |
| **WALLIX RDS**     | Windows Server 2022            | Standard or Datacenter | 64-bit |

### Database Requirements

WALLIX Bastion includes an embedded MariaDB database.

| Component          | Version                     | Notes |
|--------------------|-----------------------------|-------|
| **MariaDB**        | 10.11+                      | Included with WALLIX Bastion 12.x |
| **HA Replication** | `bastion-replication` (built-in) | Master/Master or Master/Slave mode |

**Note**: For WALLIX Bastion 12.x, MariaDB 10.6+ is REQUIRED. MariaDB 10.11+ is recommended for optimal performance.

---

### External Dependencies

| Service                | Purpose                               | Version/Notes |
|------------------------|---------------------------------------|---------------|
| **Active Directory**   | User authentication and authorization | AD DS 2012 R2+ |
| **FortiAuthenticator** | MFA (RADIUS)                          | Version 6.4+ |
| **NTP Server**         | Time synchronization                  | NTP or Chrony |
| **DNS Server**         | Name resolution                       | Internal DNS recommended |
| **SIEM/Syslog**        | Centralized logging                   | Splunk, QRadar, ELK, etc. (optional) |

---

### Browser Requirements (End Users)

| Browser         | Minimum Version | Notes |
|-----------------|-----------------|-------|
| Google Chrome   | 90+             | Recommended |
| Mozilla Firefox | 90+             | Supported |
| Microsoft Edge  | 90+             | Chromium-based |
| Safari          | 14+             | macOS/iOS |

**Requirements**:
- JavaScript enabled
- Cookies enabled
- WebSocket support (for HTML5 sessions)
- TLS 1.2+ support

---

### Client Software (Administrators)

| Client                   | Purpose    | Notes |
|--------------------------|------------|-------|
| OpenSSH                  | SSH client | Linux/macOS/Windows 10+ |
| PuTTY                    | SSH client | Windows |
| mstsc.exe                | RDP client | Windows built-in |
| Microsoft Remote Desktop | RDP client | macOS/iOS/Android |

---

### Software Checklist

```
+===============================================================================+
|  SOFTWARE READINESS CHECKLIST                                                 |
+===============================================================================+

WALLIX Bastion Appliances:
[ ] WALLIX Bastion 12.3.2 pre-installed on hardware appliances
[ ] License keys obtained from WALLIX (see Licensing section)
[ ] MariaDB 10.11+ included in appliance image

HAProxy Servers:
[ ] Debian 12 (Bookworm) or RHEL 9 installed on all 10 HAProxy servers
[ ] HAProxy 2.8+ package available (will be installed during setup)
[ ] Keepalived package available for VIP management

WALLIX RDS Servers:
[ ] Windows Server 2022 installed on all 5 RDS servers
[ ] RDS licenses available (per user or per device)
[ ] Remote Desktop Services role ready to install
[ ] Windows updates applied

External Services:
[ ] Active Directory domain controllers reachable from all sites
[ ] FortiAuthenticator RADIUS server configured and reachable
[ ] NTP server(s) configured and reachable
[ ] DNS servers configured for name resolution
[ ] SIEM/Syslog server ready to receive logs (optional)

+===============================================================================+
```

---

### WALLIX Bastion Disk Space Requirements

Per the official WALLIX Bastion 12.3.2 deployment guide:

| Partition | Quota/Limit | Notes |
|-----------|-------------|-------|
| `/var/log` | 10 GB (9.8 GB usable + 200 MiB buffer) | System logs; enforced via btrfs quota |
| `/home` | 4 GB (+ 200 MiB buffer) | User data; enforced via btrfs quota |
| `/var/wab` | No fixed quota | Session recordings; size depends on usage |

**Disk Space Monitoring Thresholds**:

| Condition | Trigger | Action |
|-----------|---------|--------|
| Almost full | 90% usage on `/` or `/var/log` or `/var/wab` | Notification every 2 hours |
| Full | < 100 MiB free on `/` or `/var/wab`, or < 100 MiB free quota on `/var/log` | SSH/RDP proxies shut down; notification every 15 minutes |
| Recovery | 500 MiB available on affected partition | Proxies restored; notifications stop |

> **Note**: If `/var/log` or `/home` exceeds quota during install/upgrade, the quota is not activated automatically. Use `btrfs quota enable` and `btrfs qgroup limit` to manually re-enable.

---

### HA Database Replication Prerequisites

Before configuring WALLIX Bastion HA (Master/Master or Master/Slave):

| Requirement | Reason |
|-------------|--------|
| All nodes on same subnet (max 1 router between) | Prevents latency and HA issues |
| All nodes running the same WALLIX Bastion version | Prevents replication errors |
| Encryption initialized on all nodes | Ensures secure replication |
| All nodes synchronized via NTP to the same timezone | Prevents replication timestamp issues; cross-timezone replication not supported |
| IPv4 addresses only (no FQDN/IPv6) | FQDN and IPv6 not supported in HA configuration |
| Dedicated admin interface recommended per node | Separates admin traffic from user traffic |

**HA Limitations**:
- Audit tables are NOT replicated (each node maintains its own)
- SMTP server must be configured on each node independently
- API provisioning must not be simultaneous on both nodes (Master/Master)
- VM cloning is not supported for creating HA nodes
- Password changes and rotation schedules only on primary Master
- In Master/Slave: no "change password at check-in"; approvals only on Master
- In Master/Master: approvals are replicated between both nodes

**Not replicated between nodes**: Audit, Recording Options, Configuration Options, Connection Messages, Audit Logs, Network, Time Service, SNMP, SMTP Server, Service Control, SIEM Integration, GPG fingerprint, device certificates.

---

### Compatibility Matrix (WALLIX Bastion 12.3.2)

**RDP Target Servers**:
- Windows 7/8/8.1/10/11 Pro and Enterprise
- Windows Server 2003 / 2008 / 2008 R2 / 2012 / 2012 R2 / 2016 / 2019 / 2022 / 2025
- xRDP

**SSH Clients**: Cygwin, FileZilla, OpenSSH, PuTTY, WinSCP

**SSH Servers**: Cisco IOS SSH Server, OpenSSH

**RDP Clients**: FreeRDP (Linux), rdesktop (Linux), Remmina, Remote Desktop Connection / MSTSC (Windows)

**VNC Servers**: macOS Screen Sharing, RealVNC (up to v6.11), TigerVNC, TightVNC, UltraVNC

**REST API**: v3.8, v3.12

**SAML Identity Providers**: AWS IAM Identity Center, GCP, inWebo, Microsoft Entra ID (ex Azure AD), Okta, PingIdentity, WALLIX IDaaS (ex Trustelem)

**Supported ICAP Servers**: ClamAV+c-icap, Falcongaze Secure Tower, Forcepoint WebSense, GLIMPS Malware, McAfee Web Gateway, FortiSandbox (>=4.4.6), Trend Vision One ZTSA

**Smart Cards**: Gemalto SafeNet IDPrime MD, Yubico YubiKey 5 NFC

**Web Browsers**: Chrome (2 latest stable), Edge (2 latest stable), Firefox (2 latest + ESR), Safari (2 latest, default UI only)

---

## Access Manager Prerequisites

> **IMPORTANT**: The 2 WALLIX Access Managers are installed, configured, and operated by the **client's team**. They are NOT part of this deployment. Our only responsibility is to configure the Bastion-side integration after all sites are deployed.

### What the Client AM Team Provides to Us

| Information | Description | When Needed |
|-------------|-------------|-------------|
| **AM URLs** | HTTPS endpoints for AM1 and AM2 | Phase: AM integration (Week 9) |
| **AM IPs** | IP addresses of AM1 and AM2 | Phase: AM integration |
| **CA Certificate** | HTTPS CA cert for secure communication | Phase: AM integration |
| **SAML IdP Metadata** | URL or XML file for SSO setup | Phase: AM integration |
| **API Credentials** | API key for Bastion → AM API calls | Phase: AM integration |
| **Bastion API Key** | API key AM will use to call Bastion | Phase: AM integration |

### Access Manager Coordination Checklist

```
+===============================================================================+
|  ACCESS MANAGER COORDINATION CHECKLIST                                        |
+===============================================================================+

Coordination with Client AM Team:
[ ] AM team contact information documented (email, phone, escalation)
[ ] Deployment timeline communicated to AM team
[ ] Integration window scheduled (Week 9 of deployment)
[ ] AM team confirms AM is operational before integration begins

Information to Request from AM Team:
[ ] AM1 URL and IP address
[ ] AM2 URL and IP address
[ ] HTTPS CA certificate (PEM)
[ ] SAML IdP metadata URL (or XML file)
[ ] API base URL and API key for Bastion registration
[ ] Confirmation that MPLS routes to Bastion sites are configured

Our Deliverables to AM Team:
[ ] Per-site HAProxy VIP addresses (Bastion URLs)
[ ] Per-site health check endpoint URLs
[ ] Per-site API keys generated from Bastion
[ ] SP metadata XML from each Bastion site

Note: Full Bastion-side integration procedure is in
      15-access-manager-integration.md

+===============================================================================+
```

---

## Licensing Requirements

### License Pools

| Pool | Managed By | Scope | Notes |
|------|------------|-------|-------|
| **Access Manager License** | Client AM team | AM-side sessions | NOT our responsibility |
| **WALLIX Bastion License** | Our deployment team | PAM enforcement sessions | Our responsibility |
| **FortiAuthenticator License** | Our deployment team | Per-site FortiAuth appliances | Our responsibility |
| **FortiToken Mobile License** | Our deployment team | ~30 tokens per site (25 users + spare) | Our responsibility |

#### Access Manager License

> **Managed by the client's AM team. Not our deployment responsibility.**

We do not purchase, activate, or manage AM licenses. The client team handles AM licensing independently.

---

#### WALLIX Bastion License Pool

| Component | Quantity | Notes |
|-----------|----------|-------|
| Site 1 Bastion Cluster | 2 appliances = 1 HA license | Active-Active or Active-Passive |
| Site 2 Bastion Cluster | 2 appliances = 1 HA license | Active-Active or Active-Passive |
| Site 3 Bastion Cluster | 2 appliances = 1 HA license | Active-Active or Active-Passive |
| Site 4 Bastion Cluster | 2 appliances = 1 HA license | Active-Active or Active-Passive |
| Site 5 Bastion Cluster | 2 appliances = 1 HA license | Active-Active or Active-Passive |

**Total appliances**: 10 (across 5 sites)

**License model**: Concurrent sessions, shared across all 5 sites.

**Scale**: ~25 privileged users per site × 5 sites = ~125 simultaneous target sessions maximum. Recommendation: purchase **150 concurrent session license** to provide growth buffer.

**HA Licensing**: Each HA cluster (2 appliances) counts as **1 license**, not 2.

**License Type**: Concurrent sessions (not named users)

---

#### FortiAuthenticator and FortiToken Licenses

| Component | Quantity | Notes |
|-----------|----------|-------|
| FortiAuthenticator 300F (or VM) license | 10 (2 per site × 5 sites) | Per-appliance license |
| FortiToken Mobile | ~150 tokens | ~30 per site × 5 sites (25 users + spare) |

**Managed By**: Our deployment team (purchase with site hardware)

---

### License Activation

| Component | Activation Method | Notes |
|-----------|-------------------|-------|
| **Bastion** | License file uploaded via Web UI or CLI | `.lic` file from WALLIX |
| **FortiAuthenticator** | License file uploaded via FortiAuth Web UI | From Fortinet support portal |
| **FortiToken Mobile** | License file uploaded via FortiAuth Web UI | Activates token quota |

---

### Licensing Checklist

```
+===============================================================================+
|  LICENSING READINESS CHECKLIST                                                |
+===============================================================================+

Bastion Licenses (Our Responsibility):
[ ] Bastion concurrent session license purchased (recommend: 150 sessions)
[ ] License file (.lic) received from WALLIX
[ ] License expiration date documented
[ ] License renewal process understood

FortiAuthenticator Licenses (Our Responsibility):
[ ] FortiAuthenticator license for all 10 appliances obtained
[ ] FortiToken Mobile license obtained (~150 tokens total)
[ ] License files received from Fortinet

Access Manager Licenses (Client AM Team):
[ ] Client AM team confirms AM is licensed and operational
[ ] AM licensing does not affect our deployment timeline
[ ] Note in project docs: AM licensing is client's responsibility

License Monitoring:
[ ] Bastion license usage alerts configured (warn at 80% capacity)
[ ] FortiToken quota usage monitored in FortiAuthenticator console

+===============================================================================+
```

---

## Security Prerequisites

### SSL/TLS Certificates

| Component | Certificate Type | Subject Alternative Names (SANs) | Notes |
|-----------|------------------|-----------------------------------|-------|
| HAProxy VIP (Site 1) | Wildcard or multi-SAN | bastion-site1.company.com | Public CA or internal CA |
| HAProxy VIP (Site 2) | Wildcard or multi-SAN | bastion-site2.company.com | Public CA or internal CA |
| HAProxy VIP (Site 3) | Wildcard or multi-SAN | bastion-site3.company.com | Public CA or internal CA |
| HAProxy VIP (Site 4) | Wildcard or multi-SAN | bastion-site4.company.com | Public CA or internal CA |
| HAProxy VIP (Site 5) | Wildcard or multi-SAN | bastion-site5.company.com | Public CA or internal CA |

**Certificate Requirements**:
- Minimum key size: 2048-bit RSA or 256-bit ECC
- Signature algorithm: SHA-256 or better (no SHA-1)
- Validity period: 1-2 years
- Format: PEM format (certificate, private key, CA chain)

**Wildcard Option**: Use wildcard certificate `*.company.com` for all sites

---

### Service Accounts

| Service Account | Purpose | Required Permissions | Notes |
|-----------------|---------|----------------------|-------|
| **AD/LDAP Bind Account** | WALLIX → AD authentication and user lookup | Read-only on Users and Groups OUs | Non-expiring password |
| **RADIUS Shared Secret** | WALLIX → FortiAuthenticator RADIUS | RADIUS client authentication | 32+ character secret |
| **Access Manager API Account** | WALLIX → Access Manager API calls | API read/write permissions | API key or OAuth credentials |
| **Database Replication Account** | MariaDB replication (Bastion-1 ↔ Bastion-2) | REPLICATION SLAVE, REPLICATION CLIENT | Per-site account |
| **Backup Account** | WALLIX → Backup storage (NFS/CIFS) | Read/write on backup share | SMB or NFS credentials |

---

### Encryption Keys and Secrets

| Secret | Purpose | Generation Method | Storage |
|--------|---------|-------------------|---------|
| **Database Encryption Key** | MariaDB at-rest encryption | Generated by WALLIX during setup | Stored in WALLIX secure vault |
| **Session Recording Encryption** | Recording file encryption | Generated by WALLIX during setup | Stored in WALLIX secure vault |
| **SSH Host Keys** | WALLIX Bastion SSH server identity | Generated by WALLIX during setup | Stored in `/etc/ssh/` |
| **TLS Private Keys** | HTTPS/SSL private keys | Generated with CSR or imported | Stored in WALLIX certificate store |

---

### Firewall and Network Security

| Security Control | Description | Responsibility |
|------------------|-------------|----------------|
| **Firewall Rules** | Restrict access to only required ports (see Network section) | Network team |
| **Network Segmentation** | Isolate Bastion DMZ from target networks | Network team |
| **IPS/IDS** | Intrusion detection/prevention (optional) | Security team |
| **DDoS Protection** | Protection for HTTPS endpoints (if public-facing) | Security team |

---

### Security Hardening

| Hardening Measure | Description | Implementation |
|-------------------|-------------|----------------|
| **OS Hardening** | CIS benchmarks for Debian 12 / RHEL 9 (HAProxy servers) | Bastion team |
| **WALLIX Hardening** | Appliance security configuration (done by WALLIX) | Pre-hardened appliance |
| **Password Policies** | Strong password policies for service accounts | AD/Security team |
| **Audit Logging** | Enable audit logging on all Bastion appliances | Bastion team |
| **LUKS Disk Encryption** | Full-disk encryption on WALLIX appliances (if supported) | Optional (check with WALLIX) |

---

### Security Checklist

```
+===============================================================================+
|  SECURITY READINESS CHECKLIST                                                 |
+===============================================================================+

SSL/TLS Certificates:
[ ] SSL certificates obtained for all 5 HAProxy VIPs (or wildcard cert)
[ ] Certificate files in PEM format (certificate, private key, CA chain)
[ ] Certificate validity verified (not expired, trusted CA)
[ ] Private keys securely stored (not committed to version control)
[ ] Certificate installation tested on HAProxy servers

Service Accounts:
[ ] AD/LDAP bind account created with read-only permissions
[ ] AD/LDAP bind account password documented (in secure vault)
[ ] AD/LDAP bind account password set to never expire
[ ] RADIUS shared secret generated (32+ characters, secure random)
[ ] RADIUS shared secret documented (in secure vault)
[ ] Access Manager API account credentials received
[ ] Database replication accounts created (per site)
[ ] Backup account created for NFS/CIFS backup storage

Encryption and Secrets:
[ ] Database encryption key generation plan documented
[ ] Session recording encryption enabled (default in WALLIX 12.x)
[ ] SSH host keys will be generated during initial setup
[ ] TLS private keys securely stored

Firewall Rules:
[ ] Firewall rules implemented as per Network Requirements section
[ ] Firewall rules tested (connectivity verified)
[ ] Firewall rule documentation updated

Network Security:
[ ] Network segmentation in place (DMZ isolation)
[ ] IPS/IDS configured (if applicable)
[ ] DDoS protection configured (if public-facing)

OS Hardening:
[ ] HAProxy servers hardened per CIS benchmarks (Debian 12 / RHEL 9)
[ ] Unnecessary services disabled on HAProxy servers
[ ] WALLIX Bastion appliances pre-hardened (verify with WALLIX)

Audit and Compliance:
[ ] Audit logging enabled on all Bastion appliances
[ ] Audit log retention policy defined (90 days minimum recommended)
[ ] Compliance requirements documented (ISO 27001, SOC 2, NIS2, etc.)
[ ] Security team notified of deployment timeline

+===============================================================================+
```

---

## DNS and NTP Requirements

### DNS Requirements

| Record Type | Hostname                  | IP Address                | Purpose |
|-------------|---------------------------|---------------------------|---------|
| A           | bastion-site1.company.com | 10.10.1.100               | HAProxy VIP (Site 1) |
| A           | bastion-site2.company.com | 10.10.2.100               | HAProxy VIP (Site 2) |
| A           | bastion-site3.company.com | 10.10.3.100               | HAProxy VIP (Site 3) |
| A           | bastion-site4.company.com | 10.10.4.100               | HAProxy VIP (Site 4) |
| A           | bastion-site5.company.com | 10.10.5.100               | HAProxy VIP (Site 5) |
| CNAME       | bastion.company.com       | bastion-site1.company.com | User-facing alias (optional) |

**Additional DNS Records (Internal)**:

| Record Type | Hostname                   | IP Address | Purpose |
|-------------|----------------------------|------------|---------|
| A           | bastion1-node1.company.com | 10.10.1.11 | Site 1 Bastion Node 1 |
| A           | bastion1-node2.company.com | 10.10.1.12 | Site 1 Bastion Node 2 |
| A           | haproxy1-1.company.com     | 10.10.1.5  | Site 1 HAProxy-1 |
| A           | haproxy1-2.company.com     | 10.10.1.6  | Site 1 HAProxy-2 |
| ...         | (repeat for Sites 2-5)     | ...        | ... |

**DNS Resolution Requirements**:
- Forward DNS: All Bastion and HAProxy hostnames resolvable
- Reverse DNS (PTR): Recommended for audit logs and troubleshooting
- Internal DNS: Active Directory DNS or internal DNS server
- External DNS: If Bastion is accessible from Internet (optional)

---

### NTP Requirements

| Requirement               | Description                                    | Notes |
|---------------------------|------------------------------------------------|-------|
| **NTP Servers**           | Minimum 2 NTP servers                          | Redundancy |
| **Time Synchronization**  | All Bastion nodes synchronized within 1 second | Critical for Kerberos and audit logs |
| **Time Zone**             | UTC or consistent time zone across all sites   | Recommended: UTC |
| **NTP Protocol**          | NTPv4 or Chrony                                | Chrony recommended for better accuracy |

**NTP Server Candidates**:
- Internal NTP server (Active Directory DCs)
- External NTP: `pool.ntp.org`, `time.google.com`, `time.cloudflare.com`

**Clock Skew Tolerance**:
- Kerberos: Maximum 5 minutes (300 seconds)
- RADIUS: Maximum 1 minute (60 seconds) recommended
- Database replication: Maximum 1 second

---

### DNS and NTP Checklist

```
+===============================================================================+
|  DNS AND NTP READINESS CHECKLIST                                              |
+===============================================================================+

DNS Records:
[ ] A records created for all 5 HAProxy VIPs (bastion-site1-5.company.com)
[ ] A records created for all Bastion nodes (node1/node2 per site)
[ ] A records created for all HAProxy nodes (haproxy1-1, haproxy1-2, etc.)
[ ] CNAME record created for user-facing alias (bastion.company.com, optional)
[ ] PTR (reverse DNS) records created for all IP addresses
[ ] DNS propagation verified (nslookup/dig from all sites)
[ ] DNS resolution tested from all Bastion and HAProxy nodes

NTP Configuration:
[ ] NTP servers identified (internal or external)
[ ] NTP firewall rules allowed (UDP 123)
[ ] NTP servers reachable from all sites (ping/telnet)
[ ] NTP configuration tested on one HAProxy server
[ ] NTP configuration tested on one Bastion appliance (if accessible)
[ ] Time zone configured consistently (UTC recommended)
[ ] Clock skew between sites verified (< 1 second)

Time Synchronization Testing:
[ ] All HAProxy nodes time-synchronized (within 1 second)
[ ] All Bastion nodes time-synchronized (within 1 second)
[ ] Active Directory DCs time-synchronized (Kerberos requirement)
[ ] FortiAuthenticator time-synchronized (RADIUS requirement)

+===============================================================================+
```

---

## Backup Storage Requirements

### Backup Targets

| Component                   | Backup Frequency | Retention Period       | Estimated Size |
|-----------------------------|------------------|------------------------|----------------|
| **WALLIX Configuration**    | Daily            | 30 days                | 100 MB per site |
| **WALLIX Database**         | Daily            | 30 days                | 1-10 GB per site (depends on usage) |
| **Session Recordings**      | Continuous       | 90 days (configurable) | 2 TB per site (depends on session volume) |
| **HAProxy Configuration**   | After changes    | 30 days                | 10 MB per site |
| **Audit Logs**              | Daily            | 365 days               | 10-50 GB per site per year |

---

### Backup Storage Options

| Option                         | Description                    | Pros                                   | Cons |
|--------------------------------|--------------------------------|----------------------------------------|------|
| **NFS Share**                  | Network File System mount      | Native Linux support, easy integration | Requires NFS server |
| **CIFS/SMB Share**             | Windows file share             | Integrates with Windows environments   | Requires Samba client |
| **S3-compatible Storage**      | Object storage (AWS S3, MinIO) | Scalable, off-site storage             | Requires S3 API support |
| **Dedicated Backup Appliance** | Veeam, Commvault, Veritas      | Enterprise backup features             | Additional licensing cost |

---

### Backup Storage Sizing

**Per-Site Backup Storage** (example for 90-day retention):

| Data Type             | Size        | Notes |
|-----------------------|-------------|-------|
| Configuration backups | 3 GB        | 100 MB × 30 days |
| Database backups      | 300 GB      | 10 GB × 30 days |
| Session recordings    | 2 TB        | 90 days retention |
| Audit logs            | 5 GB        | 1 year retention |
| **Total per site**    | **~2.3 TB** | Approximate |

**Total for 5 Sites**: ~11.5 TB (with 90-day recording retention)

**Recommendation**: Provision 15-20 TB for growth and buffer.

---

### Backup Infrastructure

| Component                | Specification                     | Notes |
|--------------------------|-----------------------------------|-------|
| **Backup Server**        | Dedicated NAS or backup appliance | Separate from production |
| **Storage Capacity**     | 15-20 TB                          | For 5 sites with 90-day retention |
| **Network Connectivity** | 1 GbE minimum                     | 10 GbE recommended for faster backups |
| **Redundancy**           | RAID 6 or RAID 10                 | Protect against disk failures |
| **Off-Site Replication** | Replicate to secondary datacenter | Disaster recovery |

---

### Backup Checklist

```
+===============================================================================+
|  BACKUP STORAGE READINESS CHECKLIST                                           |
+===============================================================================+

Backup Storage:
[ ] Backup storage solution identified (NFS, CIFS, S3, backup appliance)
[ ] Backup storage capacity provisioned (15-20 TB for 5 sites)
[ ] Backup storage server reachable from all Bastion sites
[ ] Backup storage account credentials created (if applicable)
[ ] Backup storage mounted and tested on one Bastion node

Backup Policies:
[ ] Backup schedule defined (daily for config/DB, continuous for recordings)
[ ] Backup retention policy defined (30 days config, 90 days recordings, etc.)
[ ] Backup rotation policy defined (weekly full, daily incremental)
[ ] Off-site replication configured (if disaster recovery required)

Backup Testing:
[ ] Backup script/tool tested on one site
[ ] Restore procedure tested (configuration restore)
[ ] Restore procedure tested (database restore)
[ ] Restore procedure tested (session recording restore)
[ ] Restore time documented (RTO: Recovery Time Objective)

Disaster Recovery:
[ ] Disaster recovery plan documented
[ ] RPO (Recovery Point Objective) defined (e.g., 24 hours)
[ ] RTO (Recovery Time Objective) defined (e.g., 4 hours)
[ ] DR testing schedule defined (quarterly recommended)

+===============================================================================+
```

---

## Pre-Deployment Checklist

### Master Checklist (All Sites)

Use this master checklist to track readiness across all prerequisites.

```
+===============================================================================+
|  MASTER PRE-DEPLOYMENT CHECKLIST                                              |
+===============================================================================+

HARDWARE (All 5 Sites):
[ ] 10x HAProxy servers provisioned (2 per site)
[ ] 10x WALLIX Bastion HW appliances received and racked (2 per site)
[ ] 5x WALLIX RDS servers ready (1 per site)
[ ] IPMI/iLO access configured for all appliances
[ ] Redundant power supplies verified
[ ] Network cabling installed (bonded NICs)

NETWORK (All Sites):
[ ] MPLS circuits installed and tested (100+ Mbps per site)
[ ] MPLS latency verified (< 50ms RTT)
[ ] IP addresses allocated and documented
[ ] Firewall rules implemented (AM ↔ Bastion, Bastion ↔ Targets, etc.)
[ ] HAProxy VIP addresses reserved (1 per site)
[ ] Network connectivity tested between all components

SOFTWARE (All Sites):
[ ] WALLIX Bastion 12.3.2 verified on appliances
[ ] Debian 12 or RHEL 9 installed on HAProxy servers
[ ] Windows Server 2022 installed on RDS servers
[ ] Operating system updates applied
[ ] Active Directory reachable from all sites
[ ] FortiAuthenticator RADIUS reachable from all sites

ACCESS MANAGER INTEGRATION:
[ ] Access Manager URLs and IPs documented
[ ] API endpoints and credentials received
[ ] SSL/TLS CA certificates obtained and installed
[ ] SSO configuration details received
[ ] Session brokering rules defined
[ ] Coordination meeting held with AM team

LICENSING:
[ ] Bastion license file obtained (450 concurrent sessions)
[ ] License activation method confirmed
[ ] License expiration date documented
[ ] Access Manager license pool confirmed (500 sessions, managed by AM team)

SECURITY:
[ ] SSL/TLS certificates obtained for all 5 sites
[ ] AD/LDAP bind account created
[ ] RADIUS shared secret generated
[ ] Access Manager API credentials received
[ ] Database replication accounts created
[ ] Backup account created
[ ] Firewall rules implemented and tested

DNS AND NTP:
[ ] DNS A records created for all HAProxy VIPs and nodes
[ ] DNS propagation verified
[ ] NTP servers configured and reachable
[ ] Time synchronization verified (< 1 second clock skew)

BACKUP STORAGE:
[ ] Backup storage provisioned (15-20 TB)
[ ] Backup storage reachable from all sites
[ ] Backup policies defined (schedule, retention)
[ ] Restore procedure tested

DOCUMENTATION:
[ ] Network diagram created with all IP addresses
[ ] Deployment timeline communicated to all teams
[ ] Contact list documented (network, security, AM team, WALLIX support)
[ ] Escalation procedures defined

TEAM READINESS:
[ ] Deployment team identified (engineers, project manager)
[ ] Maintenance windows scheduled (for each site)
[ ] Change management approvals obtained
[ ] Rollback plan documented

+===============================================================================+
```

---

## Summary

This prerequisites document outlines all requirements for deploying 5 WALLIX Bastion sites integrated with 2 WALLIX Access Managers. Key points:

- **Hardware**: 10 HAProxy servers, 10 Bastion appliances, 5 RDS servers
- **Network**: MPLS connectivity (100+ Mbps per site), firewall rules, IP addressing
- **Software**: WALLIX Bastion 12.3.2, Debian 12/RHEL 9 for HAProxy, Windows Server 2022 for RDS
- **Access Manager**: SSO, MFA, session brokering (managed by separate team)
- **Licensing**: 500 AM sessions + 450 Bastion sessions (split pools)
- **Security**: SSL certificates, service accounts, encryption keys, firewall rules
- **DNS/NTP**: DNS records for all components, NTP synchronization
- **Backup**: 15-20 TB backup storage, daily backups, 90-day retention

**Next Steps**:
1. Complete this prerequisites checklist
2. Review network design in [01-network-design.md](01-network-design.md)
3. Choose HA architecture in [02-ha-architecture.md](02-ha-architecture.md)
4. Coordinate with Access Manager team using [15-access-manager-integration.md](15-access-manager-integration.md)
5. Begin Site 1 deployment following [05-site-deployment.md](05-site-deployment.md)

---

## Related Documentation

| Document                                                             | Description |
|----------------------------------------------------------------------|-------------|
| [README.md](README.md)                                               | Main installation guide overview |
| [01-network-design.md](01-network-design.md)                         | MPLS topology, connectivity, detailed port matrix |
| [02-ha-architecture.md](02-ha-architecture.md)                       | Active-Active vs Active-Passive comparison |
| [15-access-manager-integration.md](15-access-manager-integration.md) | SSO, MFA, brokering, licensing integration |
| [05-site-deployment.md](05-site-deployment.md)                       | Per-site deployment template |
| [HOWTO.md](HOWTO.md)                                                 | Step-by-step installation walkthrough |

---

## Version Information

| Item                   | Value |
|------------------------|-------|
| Documentation Version  | 1.0 |
| WALLIX Bastion Version | 12.3.2 |
| Last Updated           | February 2026 |
| Author                 | PAM Deployment Team |
