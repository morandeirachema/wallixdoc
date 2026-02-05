# Prerequisites - 5-Site WALLIX Bastion Deployment with Access Manager Integration

> Comprehensive prerequisites checklist for deploying 5 WALLIX Bastion sites integrated with 2 WALLIX Access Managers in HA configuration

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

## Deployment Overview

### Architecture Summary

This deployment consists of:

| Component | Quantity | Configuration | Location |
|-----------|----------|---------------|----------|
| **WALLIX Access Manager** | 2 | HA (Active-Passive) | 2 separate datacenters (not managed by us) |
| **WALLIX Bastion Sites** | 5 | Each site: 2 HW appliances (HA) | geographically distributed datacenters (separate buildings) |
| **HAProxy Load Balancer** | 10 | 2 per site (Active-Passive) | Each datacenter site |
| **WALLIX RDS Jump Host** | 5 | 1 per site | Each datacenter site |

### Key Architectural Principles

- **Network Isolation**: Access Managers communicate with Bastions via MPLS (NO direct Bastion-to-Bastion communication)
- **High Availability**: Both Active-Active and Active-Passive options documented (see [02-ha-architecture.md](02-ha-architecture.md))
- **Centralized Management**: Access Managers provide SSO, MFA, and session brokering
- **Split Licensing**: Access Manager pool (500 sessions) + Bastion pool (450 sessions shared across 5 sites)

```
+===============================================================================+
|  5-SITE DEPLOYMENT OVERVIEW                                                   |
+===============================================================================+
|                                                                               |
|  Access Manager 1 (DC-A)  <---HA--->  Access Manager 2 (DC-B)                 |
|  - SSO / MFA                          - SSO / MFA                             |
|  - Session Brokering                  - Session Brokering                     |
|  - License Management                 - License Management                    |
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
|  Each Site Contains:                                                          |
|  - 2x HAProxy (Active-Passive with Keepalived VRRP)                           |
|  - 2x WALLIX Bastion HW Appliances (Active-Active or Active-Passive)          |
|  - 1x WALLIX RDS (Jump host for OT RemoteApp access)                          |
|                                                                               |
+===============================================================================+
```

---

## Hardware Requirements

### Per-Site Hardware Summary

Each of the 5 sites requires:

| Component | Quantity | Purpose |
|-----------|----------|---------|
| HAProxy Servers | 2 | Active-Passive load balancer pair |
| WALLIX Bastion Appliances | 2 | Active-Active or Active-Passive HA cluster |
| WALLIX RDS Server | 1 | Jump host for OT access via RemoteApp |

### Total Hardware (All 5 Sites)

| Component | Total Quantity | Notes |
|-----------|----------------|-------|
| HAProxy Servers | 10 | 2 per site |
| WALLIX Bastion HW Appliances | 10 | 2 per site |
| WALLIX RDS Servers | 5 | 1 per site |

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

### Hardware Checklist

```
+===============================================================================+
|  HARDWARE READINESS CHECKLIST (Per Site)                                      |
+===============================================================================+

Site 1 (Site 1 DC):
[ ] 2x HAProxy servers provisioned (physical or VM)
[ ] 2x WALLIX Bastion HW appliances received and racked
[ ] 1x WALLIX RDS server (Windows Server 2022) ready
[ ] All servers have redundant power supplies (physical)
[ ] All servers have IPMI/iLO access configured
[ ] All servers have network cables connected (bonded NICs)

Site 2 (Site 2 DC):
[ ] 2x HAProxy servers provisioned
[ ] 2x WALLIX Bastion HW appliances received and racked
[ ] 1x WALLIX RDS server ready
[ ] IPMI/iLO configured
[ ] Network connectivity verified

Site 3 (Site 3 DC):
[ ] 2x HAProxy servers provisioned
[ ] 2x WALLIX Bastion HW appliances received and racked
[ ] 1x WALLIX RDS server ready
[ ] IPMI/iLO configured
[ ] Network connectivity verified

Site 4 (Site 4 DC):
[ ] 2x HAProxy servers provisioned
[ ] 2x WALLIX Bastion HW appliances received and racked
[ ] 1x WALLIX RDS server ready
[ ] IPMI/iLO configured
[ ] Network connectivity verified

Site 5 (Site 5 DC):
[ ] 2x HAProxy servers provisioned
[ ] 2x WALLIX Bastion HW appliances received and racked
[ ] 1x WALLIX RDS server ready
[ ] IPMI/iLO configured
[ ] Network connectivity verified

+===============================================================================+
```

---

## Network Requirements

### Network Topology Overview

```
+===============================================================================+
|  NETWORK TOPOLOGY - ACCESS MANAGER TO BASTION SITES                           |
+===============================================================================+
|                                                                               |
|  Access Manager 1 (DC-A)           Access Manager 2 (DC-B)                    |
|  IP: <AM1-IP>                      IP: <AM2-IP>                               |
|         |                                 |                                   |
|         +----------------+----------------+                                   |
|                          |                                                    |
|                    MPLS Network                                               |
|         Bandwidth: 100+ Mbps per site                                         |
|         Latency: < 50ms RTT preferred                                         |
|                          |                                                    |
|         +----------------+----------------+----------------+                  |
|         |                |                |                |                  |
|    Site 1           Site 2           Site 3           Site 4,5                |
|   10.10.1.0/24     10.10.2.0/24     10.10.3.0/24     10.10.4-5.0/24           |
|         |                |                |                |                  |
|    HAProxy VIP      HAProxy VIP      HAProxy VIP      HAProxy VIP             |
|    10.10.1.100      10.10.2.100      10.10.3.100      10.10.4-5.100           |
|         |                |                |                |                  |
|  Bastion Nodes     Bastion Nodes     Bastion Nodes     Bastion Nodes          |
|  10.10.1.11-12     10.10.2.11-12     10.10.3.11-12     10.10.4-5.11-12        |
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

| Component | IP Address | Notes |
|-----------|------------|-------|
| HAProxy-1 | 10.10.1.5 | Active node |
| HAProxy-2 | 10.10.1.6 | Passive node |
| HAProxy VIP | 10.10.1.100 | Keepalived virtual IP |
| Bastion-1 | 10.10.1.11 | Active (or Active-Active) |
| Bastion-2 | 10.10.1.12 | Active or Passive |
| WALLIX RDS | 10.10.1.30 | Jump host |

**Repeat similar allocation for Sites 2-5 with appropriate subnets (10.10.2.0/24, 10.10.3.0/24, etc.)**

---

### Firewall Rules: Access Manager ↔ Bastion

| Source | Destination | Port | Protocol | Purpose | Mandatory |
|--------|-------------|------|----------|---------|-----------|
| Access Manager | Bastion (HAProxy VIP) | 443 | TCP/HTTPS | API, session brokering | Yes |
| Bastion | Access Manager | 443 | TCP/HTTPS | SSO callbacks, health checks | Yes |
| Bastion | FortiAuthenticator | 1812 | UDP | RADIUS authentication | Yes |
| Bastion | FortiAuthenticator | 1813 | UDP | RADIUS accounting | Yes |
| Bastion | Active Directory | 389 | TCP | LDAP authentication | Yes |
| Bastion | Active Directory | 636 | TCP | LDAPS (secure LDAP) | Recommended |
| Bastion | Active Directory | 88 | TCP/UDP | Kerberos authentication | Optional |
| Bastion | Active Directory | 464 | TCP/UDP | Kerberos password change | Optional |
| Bastion | NTP Server | 123 | UDP | Time synchronization | Yes |
| Bastion | DNS Server | 53 | UDP/TCP | Name resolution | Yes |
| Bastion | SIEM/Syslog | 514 | UDP | Syslog (unencrypted) | Optional |
| Bastion | SIEM/Syslog | 6514 | TCP | Syslog over TLS | Recommended |

---

### Firewall Rules: Bastion ↔ Bastion (HA Cluster, Within Site)

| Source | Destination | Port | Protocol | Purpose | Mandatory |
|--------|-------------|------|----------|---------|-----------|
| Bastion-1 | Bastion-2 | 3306 | TCP | MariaDB replication | Yes |
| Bastion-2 | Bastion-1 | 3306 | TCP | MariaDB replication | Yes |
| Bastion-1 | Bastion-2 | 5404-5406 | UDP | Corosync cluster heartbeat | Yes (if using Pacemaker/Corosync) |
| Bastion-1 | Bastion-2 | 2224 | TCP | Pacemaker cluster | Yes (if using Pacemaker) |
| Bastion-1 | Bastion-2 | 443 | TCP/HTTPS | Configuration sync | Yes |

**IMPORTANT**: There is NO direct Bastion-to-Bastion communication BETWEEN sites (Site 1 ↔ Site 2, etc.). All inter-site coordination happens via Access Managers.

---

### Firewall Rules: HAProxy ↔ Bastion (Within Site)

| Source | Destination | Port | Protocol | Purpose | Mandatory |
|--------|-------------|------|----------|---------|-----------|
| HAProxy | Bastion-1 | 443 | TCP/HTTPS | Load balancing to Bastion | Yes |
| HAProxy | Bastion-2 | 443 | TCP/HTTPS | Load balancing to Bastion | Yes |
| HAProxy | Bastion-1 | 22 | TCP | SSH proxy | Yes |
| HAProxy | Bastion-2 | 22 | TCP | SSH proxy | Yes |
| HAProxy | Bastion-1 | 3389 | TCP | RDP proxy | Yes |
| HAProxy | Bastion-2 | 3389 | TCP | RDP proxy | Yes |

---

### Firewall Rules: Bastion → Target Systems

| Source | Destination | Port | Protocol | Purpose | Mandatory |
|--------|-------------|------|----------|---------|-----------|
| Bastion | Windows Servers | 3389 | TCP | RDP access | Yes |
| Bastion | Windows Servers | 5985-5986 | TCP | WinRM (HTTP/HTTPS) | Optional |
| Bastion | Linux Servers (RHEL 10/9) | 22 | TCP | SSH access | Yes |
| Bastion | Database Servers | 1521 | TCP | Oracle DB | As needed |
| Bastion | Database Servers | 3306 | TCP | MySQL/MariaDB | As needed |
| Bastion | Database Servers | 5432 | TCP | PostgreSQL | As needed |
| Bastion | Database Servers | 1433 | TCP | Microsoft SQL Server | As needed |

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

Firewall Rules:
[ ] Access Manager → Bastion (HTTPS 443) allowed
[ ] Bastion → Access Manager (HTTPS 443) allowed
[ ] Bastion → FortiAuthenticator (RADIUS 1812/1813) allowed
[ ] Bastion → Active Directory (LDAP 389/636, Kerberos 88/464) allowed
[ ] Bastion → NTP, DNS allowed
[ ] Bastion → Target systems (SSH 22, RDP 3389, etc.) allowed
[ ] HAProxy → Bastion nodes (HTTPS 443, SSH 22, RDP 3389) allowed
[ ] Bastion-1 ↔ Bastion-2 (MariaDB 3306, Corosync 5404-5406) allowed (per site)
[ ] Bastion → SIEM/Syslog (514/6514) allowed (optional)

IP Addressing:
[ ] IP addresses allocated for all components (HAProxy, Bastion, RDS)
[ ] HAProxy VIP addresses reserved (1 per site)
[ ] Static IP assignments documented
[ ] IP routing verified between all network segments

VLANs and Subnets:
[ ] Network subnets defined for each site
[ ] VLANs configured (if applicable)
[ ] VLAN trunking configured on switches

+===============================================================================+
```

---

## Software Requirements

### Operating Systems

| Component | Operating System | Version | Notes |
|-----------|------------------|---------|-------|
| **WALLIX Bastion** | Pre-installed on appliance | WALLIX Bastion 12.1.x | Hardened Linux (Debian-based) |
| **HAProxy** | Debian 12 (Bookworm) or RHEL 9 | Latest stable | 64-bit |
| **WALLIX RDS** | Windows Server 2022 | Standard or Datacenter | 64-bit |

### Database Requirements

WALLIX Bastion includes an embedded MariaDB database.

| Component | Version | Notes |
|-----------|---------|-------|
| **MariaDB** | 10.11+ | Included with WALLIX Bastion 12.x |
| **HA Replication** | MariaDB Galera or Streaming | For Active-Active or Active-Passive |

**Note**: For WALLIX Bastion 12.x, MariaDB 10.6+ is REQUIRED. MariaDB 10.11+ is recommended for optimal performance.

---

### External Dependencies

| Service | Purpose | Version/Notes |
|---------|---------|---------------|
| **Active Directory** | User authentication and authorization | AD DS 2012 R2+ |
| **FortiAuthenticator** | MFA (RADIUS) | Version 6.4+ |
| **NTP Server** | Time synchronization | NTP or Chrony |
| **DNS Server** | Name resolution | Internal DNS recommended |
| **SIEM/Syslog** | Centralized logging | Splunk, QRadar, ELK, etc. (optional) |

---

### Browser Requirements (End Users)

| Browser | Minimum Version | Notes |
|---------|----------------|-------|
| Google Chrome | 90+ | Recommended |
| Mozilla Firefox | 90+ | Supported |
| Microsoft Edge | 90+ | Chromium-based |
| Safari | 14+ | macOS/iOS |

**Requirements**:
- JavaScript enabled
- Cookies enabled
- WebSocket support (for HTML5 sessions)
- TLS 1.2+ support

---

### Client Software (Administrators)

| Client | Purpose | Notes |
|--------|---------|-------|
| OpenSSH | SSH client | Linux/macOS/Windows 10+ |
| PuTTY | SSH client | Windows |
| mstsc.exe | RDP client | Windows built-in |
| Microsoft Remote Desktop | RDP client | macOS/iOS/Android |

---

### Software Checklist

```
+===============================================================================+
|  SOFTWARE READINESS CHECKLIST                                                 |
+===============================================================================+

WALLIX Bastion Appliances:
[ ] WALLIX Bastion 12.1.x pre-installed on hardware appliances
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

## Access Manager Prerequisites

**IMPORTANT**: The 2 WALLIX Access Managers are managed by a separate team and are NOT part of this deployment. However, we need to coordinate with the Access Manager team for integration.

### Access Manager Information Needed

| Information | Description | Responsibility |
|-------------|-------------|----------------|
| **Access Manager URLs** | HTTPS endpoints for both AM instances | AM team provides |
| **Access Manager IPs** | IP addresses of AM1 and AM2 | AM team provides |
| **HA Configuration** | Active-Passive details (which is primary) | AM team provides |
| **API Endpoints** | REST API URLs for session brokering | AM team provides |
| **API Credentials** | Service account for Bastion → AM communication | AM team creates |
| **SSL Certificates** | CA certificates for HTTPS communication | AM team provides |

---

### Access Manager Integration Points

The Access Managers provide the following services to the Bastion sites:

| Service | Description | Integration Method |
|---------|-------------|--------------------|
| **SSO Integration** | Single Sign-On for end users | SAML 2.0 or OIDC |
| **MFA** | Multi-factor authentication via FortiAuthenticator | RADIUS proxy through AM |
| **Session Brokering** | Routes user sessions to appropriate Bastion site | REST API calls |
| **License Integration** | Centralized license pool management (optional) | AM API |

---

### Access Manager Checklist

```
+===============================================================================+
|  ACCESS MANAGER INTEGRATION CHECKLIST                                         |
+===============================================================================+

Access Manager Information:
[ ] Access Manager 1 URL and IP address documented
[ ] Access Manager 2 URL and IP address documented
[ ] HA configuration details received (Active-Passive roles)
[ ] Failover mechanism understood (automatic or manual)

API Integration:
[ ] API endpoints documented (session brokering, health checks)
[ ] API service account credentials received (username/password or API key)
[ ] API rate limits and quotas documented
[ ] API authentication method confirmed (Bearer token, OAuth 2.0, etc.)

SSL/TLS Certificates:
[ ] CA certificates for Access Manager HTTPS endpoints obtained
[ ] CA certificates installed on all Bastion nodes
[ ] Certificate trust chain verified

SSO Configuration:
[ ] SSO method confirmed (SAML 2.0, OIDC, or LDAP passthrough)
[ ] SSO metadata exchanged (if SAML)
[ ] SSO endpoints configured on Access Manager side
[ ] Test user accounts created for SSO testing

MFA Configuration:
[ ] FortiAuthenticator RADIUS configuration on Access Manager confirmed
[ ] RADIUS shared secrets exchanged (AM ↔ FortiAuth, Bastion ↔ FortiAuth)
[ ] MFA policy defined (when MFA is required)

Session Brokering:
[ ] Session brokering rules defined (which users go to which sites)
[ ] Load balancing algorithm configured (round-robin, least-loaded, etc.)
[ ] Health check endpoints configured on Bastion side

Coordination with AM Team:
[ ] Deployment timeline communicated to AM team
[ ] Maintenance windows coordinated
[ ] Contact information for AM team documented (email, phone, Slack)
[ ] Escalation procedures agreed upon

+===============================================================================+
```

---

## Licensing Requirements

### License Pools

The licensing is split into two separate pools:

#### Access Manager License Pool

| Component | Quantity | Concurrent Sessions | Notes |
|-----------|----------|---------------------|-------|
| Access Manager 1 | 1 | Part of 500 session pool | Managed by AM team |
| Access Manager 2 | 1 | Part of 500 session pool | Managed by AM team |
| **Total AM Sessions** | - | **500 concurrent** | Shared between 2 AM instances |

**License Type**: Concurrent sessions (not named users)

**Managed By**: Access Manager team (not part of this deployment)

---

#### Bastion License Pool

| Component | Quantity | Concurrent Sessions | Notes |
|-----------|----------|---------------------|-------|
| Site 1 Bastion Cluster | 2 appliances | Shared pool | Active-Active or Active-Passive |
| Site 2 Bastion Cluster | 2 appliances | Shared pool | Active-Active or Active-Passive |
| Site 3 Bastion Cluster | 2 appliances | Shared pool | Active-Active or Active-Passive |
| Site 4 Bastion Cluster | 2 appliances | Shared pool | Active-Active or Active-Passive |
| Site 5 Bastion Cluster | 2 appliances | Shared pool | Active-Active or Active-Passive |
| **Total Bastion Sessions** | 10 appliances | **450 concurrent** | Shared across all 5 sites |

**License Type**: Concurrent sessions (not named users)

**Managed By**: This team (Bastion deployment)

**HA Licensing**: Each HA cluster (2 appliances) counts as **1 license**, not 2.

---

### Total Licensed Capacity

| Pool | Concurrent Sessions | Notes |
|------|---------------------|-------|
| Access Manager | 500 | Managed by AM team |
| Bastion | 450 | Managed by Bastion team |
| **Total** | **950** | Combined capacity |

---

### License Activation

| Component | Activation Method | Notes |
|-----------|-------------------|-------|
| **Access Manager** | License server or online activation | Managed by AM team |
| **Bastion** | License file uploaded via Web UI or CLI | Requires license key from WALLIX |

**License File Format**: `.lic` file provided by WALLIX

**License Renewal**: Subscription-based (annual or multi-year)

---

### Licensing Checklist

```
+===============================================================================+
|  LICENSING READINESS CHECKLIST                                                |
+===============================================================================+

Access Manager Licenses (Managed by AM Team):
[ ] Access Manager license pool confirmed: 500 concurrent sessions
[ ] License activation keys received from WALLIX
[ ] License server access credentials available (if applicable)
[ ] License expiration date documented
[ ] License renewal process understood

Bastion Licenses (Managed by Bastion Team):
[ ] Bastion license pool purchased: 450 concurrent sessions
[ ] License file (.lic) received from WALLIX (or license key)
[ ] License activation method confirmed (Web UI or CLI)
[ ] License expiration date documented
[ ] License renewal process understood
[ ] License support contact information documented

License Pooling Configuration:
[ ] License pooling method confirmed (API-based or local)
[ ] Access Manager license pool accessible from Bastions (if integrated)
[ ] License usage monitoring configured (alerts at 80%, 90% capacity)

Compliance:
[ ] License terms and conditions reviewed
[ ] Named user vs. concurrent session licensing understood
[ ] Over-licensing strategy defined (buffer for growth)

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

| Record Type | Hostname | IP Address | Purpose |
|-------------|----------|------------|---------|
| A | bastion-site1.company.com | 10.10.1.100 | HAProxy VIP (Site 1) |
| A | bastion-site2.company.com | 10.10.2.100 | HAProxy VIP (Site 2) |
| A | bastion-site3.company.com | 10.10.3.100 | HAProxy VIP (Site 3) |
| A | bastion-site4.company.com | 10.10.4.100 | HAProxy VIP (Site 4) |
| A | bastion-site5.company.com | 10.10.5.100 | HAProxy VIP (Site 5) |
| CNAME | bastion.company.com | bastion-site1.company.com | User-facing alias (optional) |

**Additional DNS Records (Internal)**:

| Record Type | Hostname | IP Address | Purpose |
|-------------|----------|------------|---------|
| A | bastion1-node1.company.com | 10.10.1.11 | Site 1 Bastion Node 1 |
| A | bastion1-node2.company.com | 10.10.1.12 | Site 1 Bastion Node 2 |
| A | haproxy1-1.company.com | 10.10.1.5 | Site 1 HAProxy-1 |
| A | haproxy1-2.company.com | 10.10.1.6 | Site 1 HAProxy-2 |
| ... | (repeat for Sites 2-5) | ... | ... |

**DNS Resolution Requirements**:
- Forward DNS: All Bastion and HAProxy hostnames resolvable
- Reverse DNS (PTR): Recommended for audit logs and troubleshooting
- Internal DNS: Active Directory DNS or internal DNS server
- External DNS: If Bastion is accessible from Internet (optional)

---

### NTP Requirements

| Requirement | Description | Notes |
|-------------|-------------|-------|
| **NTP Servers** | Minimum 2 NTP servers | Redundancy |
| **Time Synchronization** | All Bastion nodes synchronized within 1 second | Critical for Kerberos and audit logs |
| **Time Zone** | UTC or consistent time zone across all sites | Recommended: UTC |
| **NTP Protocol** | NTPv4 or Chrony | Chrony recommended for better accuracy |

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

| Component | Backup Frequency | Retention Period | Estimated Size |
|-----------|------------------|------------------|----------------|
| **WALLIX Configuration** | Daily | 30 days | 100 MB per site |
| **WALLIX Database** | Daily | 30 days | 1-10 GB per site (depends on usage) |
| **Session Recordings** | Continuous | 90 days (configurable) | 2 TB per site (depends on session volume) |
| **HAProxy Configuration** | After changes | 30 days | 10 MB per site |
| **Audit Logs** | Daily | 365 days | 10-50 GB per site per year |

---

### Backup Storage Options

| Option | Description | Pros | Cons |
|--------|-------------|------|------|
| **NFS Share** | Network File System mount | Native Linux support, easy integration | Requires NFS server |
| **CIFS/SMB Share** | Windows file share | Integrates with Windows environments | Requires Samba client |
| **S3-compatible Storage** | Object storage (AWS S3, MinIO) | Scalable, off-site storage | Requires S3 API support |
| **Dedicated Backup Appliance** | Veeam, Commvault, Veritas | Enterprise backup features | Additional licensing cost |

---

### Backup Storage Sizing

**Per-Site Backup Storage** (example for 90-day retention):

| Data Type | Size | Notes |
|-----------|------|-------|
| Configuration backups | 3 GB | 100 MB × 30 days |
| Database backups | 300 GB | 10 GB × 30 days |
| Session recordings | 2 TB | 90 days retention |
| Audit logs | 5 GB | 1 year retention |
| **Total per site** | **~2.3 TB** | Approximate |

**Total for 5 Sites**: ~11.5 TB (with 90-day recording retention)

**Recommendation**: Provision 15-20 TB for growth and buffer.

---

### Backup Infrastructure

| Component | Specification | Notes |
|-----------|---------------|-------|
| **Backup Server** | Dedicated NAS or backup appliance | Separate from production |
| **Storage Capacity** | 15-20 TB | For 5 sites with 90-day retention |
| **Network Connectivity** | 1 GbE minimum | 10 GbE recommended for faster backups |
| **Redundancy** | RAID 6 or RAID 10 | Protect against disk failures |
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
[ ] WALLIX Bastion 12.1.x verified on appliances
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
- **Software**: WALLIX Bastion 12.1.x, Debian 12/RHEL 9 for HAProxy, Windows Server 2022 for RDS
- **Access Manager**: SSO, MFA, session brokering (managed by separate team)
- **Licensing**: 500 AM sessions + 450 Bastion sessions (split pools)
- **Security**: SSL certificates, service accounts, encryption keys, firewall rules
- **DNS/NTP**: DNS records for all components, NTP synchronization
- **Backup**: 15-20 TB backup storage, daily backups, 90-day retention

**Next Steps**:
1. Complete this prerequisites checklist
2. Review network design in [01-network-design.md](01-network-design.md)
3. Choose HA architecture in [02-ha-architecture.md](02-ha-architecture.md)
4. Coordinate with Access Manager team using [03-access-manager-integration.md](03-access-manager-integration.md)
5. Begin Site 1 deployment following [04-site-deployment.md](04-site-deployment.md)

---

## Related Documentation

| Document | Description |
|----------|-------------|
| [README.md](README.md) | Main installation guide overview |
| [01-network-design.md](01-network-design.md) | MPLS topology, connectivity, detailed port matrix |
| [02-ha-architecture.md](02-ha-architecture.md) | Active-Active vs Active-Passive comparison |
| [03-access-manager-integration.md](03-access-manager-integration.md) | SSO, MFA, brokering, licensing integration |
| [04-site-deployment.md](04-site-deployment.md) | Per-site deployment template |
| [HOWTO.md](HOWTO.md) | Step-by-step installation walkthrough |

---

## Version Information

| Item | Value |
|------|-------|
| Documentation Version | 1.0 |
| WALLIX Bastion Version | 12.1.x |
| Last Updated | February 2026 |
| Author | PAM Deployment Team |
