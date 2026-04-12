# WALLIX Bastion - 5-Site Multi-Datacenter Deployment Guide

> Enterprise deployment guide for 5 WALLIX Bastion sites with per-site FortiAuthenticator HA and per-site Active Directory

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Key Architecture Principles](#key-architecture-principles)
3. [Deployment Timeline](#deployment-timeline)
4. [Installation Documentation Structure](#installation-documentation-structure)
5. [Hardware Requirements (Per Site)](#hardware-requirements-per-site)
6. [Network Requirements](#network-requirements)
7. [Licensing Summary](#licensing-summary)
8. [Site Locations](#site-locations)
9. [Target Systems](#target-systems)
10. [Deployment Models](#deployment-models)
11. [Prerequisites Checklist](#prerequisites-checklist)
12. [Quick Start Guide](#quick-start-guide)
13. [Support and Resources](#support-and-resources)
14. [Version Information](#version-information)

---

## Architecture Overview

This installation guide covers the deployment of a multi-site WALLIX PAM infrastructure with per-site security components:

| Component | Quantity | Configuration | Notes |
|-----------|----------|---------------|-------|
| **WALLIX Access Manager** | 2 | Client-managed HA (Active-Passive) | Not deployed by us |
| **WALLIX Bastion Sites** | 5 | Each in separate datacenter | Our scope |
| **HAProxy per Site** | 2 | Active-Passive load balancer pair | DMZ VLAN |
| **Bastion Appliances per Site** | 2 | Active-Active OR Active-Passive (both documented) | DMZ VLAN |
| **WALLIX RDS** | 1 per site | Jump host for OT RemoteApp access | DMZ VLAN |
| **FortiAuthenticator per Site** | 2 | Active-Passive HA pair (per site) | Cyber VLAN |
| **Active Directory DC per Site** | 1 | Per-site domain controller | Cyber VLAN |
| **Network** | MPLS | Connectivity between sites and AM | 10 Gbps backbone |

---

## Network Topology

```
+===============================================================================+
|  5-SITE MULTI-DATACENTER ARCHITECTURE                                         |
+===============================================================================+
|                                                                               |
|  Client-Managed (Not Our Scope):                                              |
|  +--------------------------+      +--------------------------+               |
|  | Access Manager 1 (DC-A)  |      | Access Manager 2 (DC-B)  |               |
|  | - SSO / Session Brokering|      | - SSO / Session Brokering|               |
|  +-----------+--------------+      +--------------+-----------+               |
|              |         MPLS                       |                           |
|              +------------------------------------+                           |
|                           MPLS Network                                        |
|       +-------------------+----+----+----+--------------------+               |
|       |                   |         |         |               |               |
|  +----v----+         +----v----+   ...   +----v----+    +----v----+           |
|  | Site 1  |         | Site 2  |         | Site 4  |    | Site 5  |           |
|  | (DC-1)  |         | (DC-2)  |         | (DC-4)  |    | (DC-5)  |           |
|  +---------+         +---------+         +---------+    +---------+           |
|                                                                               |
|  Each Site Contains (Our Scope):                                              |
|  DMZ VLAN (10.10.X.0/25):                                                    |
|  - 2x HAProxy (Active-Passive), 2x WALLIX Bastion, 1x WALLIX RDS             |
|  Cyber VLAN (10.10.X.128/25):                                                 |
|  - 2x FortiAuthenticator (Primary .50 / Secondary .51, VIP .52)               |
|  - 1x Active Directory DC (.60)                                               |
|                                                                               |
|  NO direct Bastion-to-Bastion communication between sites                     |
|                                                                               |
+===============================================================================+
```

---

## Key Architecture Principles

### VLAN Separation Per Site

Each site uses two VLANs, with Fortigate handling inter-VLAN routing:

| VLAN | Subnet | Components | Purpose |
|------|--------|------------|---------|
| **DMZ VLAN** | 10.10.X.0/25 | HAProxy, Bastion, RDS | User-facing access layer |
| **Cyber VLAN** | 10.10.X.128/25 | FortiAuthenticator HA, AD DC | Authentication backend |

Where X = site number (1-5).

### Per-Site Authentication

- **MFA**: Each site has its own independent FortiAuthenticator HA pair (Primary at X.50, Secondary at X.51, VIP at X.52)
- **Identity**: Each site has its own Active Directory DC at X.60
- **TOTP only**: FortiToken Mobile (TOTP, 30-second window); push notifications are NOT configured
- **No centralized MFA**: Bastion connects to the local Cyber VLAN FortiAuth, not a remote/shared instance

### Access Manager (Client-Managed)

- The Access Manager (AM) is installed and operated by the client team
- Our role is Bastion-side integration only: SAML SP registration, health check endpoints
- AM provides optional SAML SSO; RADIUS authentication via FortiAuth works independently of AM
- See [15-access-manager-integration.md](15-access-manager-integration.md)

### High Availability Options

- **Active-Active**: Both Bastion appliances handle traffic simultaneously (load balancing)
- **Active-Passive**: One primary, one standby (automatic failover)
- See [02-ha-architecture.md](02-ha-architecture.md) for detailed comparison

### Access Patterns

1. **Native Access**: Windows/Linux via SSH, RDP, VNC
2. **OT Access**: Via WALLIX RDS jump host using RemoteApp (RDP only)

---

## Deployment Timeline

| Phase | Duration | Tasks |
|-------|----------|-------|
| **Phase 1: Planning** | Week 1 | Prerequisites, network design, VLAN design |
| **Phase 2: FortiAuth HA Setup** | Week 2 | Per-site FortiAuth HA, FortiToken, LDAP/AD |
| **Phase 3: Site 1 Deployment** | Week 3-4 | HAProxy, Bastion cluster, RDS, testing |
| **Phase 4: Site 2 Deployment** | Week 5 | Replicate Site 1 configuration |
| **Phase 5: Site 3 Deployment** | Week 6 | Replicate Site 1 configuration |
| **Phase 6: Site 4 Deployment** | Week 7 | Replicate Site 1 configuration |
| **Phase 7: Site 5 Deployment** | Week 8 | Replicate Site 1 configuration |
| **Phase 8: Final Integration** | Week 9 | Testing, AM coordination, optimization |
| **Phase 9: Go-Live** | Week 10 | Production cutover, documentation handoff |

**Total Timeline**: 10 weeks (2.5 months)

---

## Installation Documentation Structure

### Planning and Design

- [00-prerequisites.md](00-prerequisites.md) - Hardware, network, licensing requirements
- [01-network-design.md](01-network-design.md) - MPLS topology, VLAN design, ports
- [02-ha-architecture.md](02-ha-architecture.md) - Active-Active vs Active-Passive comparison

### Per-Site Infrastructure

- [03-fortiauthenticator-ha.md](03-fortiauthenticator-ha.md) - Per-site FortiAuth HA pair setup
- [04-ad-per-site.md](04-ad-per-site.md) - Per-site Active Directory / LDAP integration
- [05-site-deployment.md](05-site-deployment.md) - Per-site deployment template

### Site Components

- [06-haproxy-setup.md](06-haproxy-setup.md) - HAProxy configuration (DMZ VLAN)
- [07-bastion-active-active.md](07-bastion-active-active.md) - Active-Active cluster setup
- [08-bastion-active-passive.md](08-bastion-active-passive.md) - Active-Passive cluster setup
- [09-rds-jump-host.md](09-rds-jump-host.md) - WALLIX RDS for OT RemoteApp (DMZ VLAN)

### Operations

- [10-licensing.md](10-licensing.md) - License sizing and configuration
- [11-testing-validation.md](11-testing-validation.md) - End-to-end testing procedures
- [12-architecture-diagrams.md](12-architecture-diagrams.md) - Network diagrams and port reference

### Access Manager Integration (Bastion-side)

- [15-access-manager-integration.md](15-access-manager-integration.md) - SAML SP config, health checks

### Emergency and Recovery

- [13-contingency-plan.md](13-contingency-plan.md) - DR, backup strategy, failure scenarios
- [14-break-glass-procedures.md](14-break-glass-procedures.md) - Emergency access procedures

### Quick Start

- **[HOWTO.md](HOWTO.md)** - Main step-by-step installation guide

---

## Hardware Requirements (Per Site)

### HAProxy Servers (2x per site, DMZ VLAN)

| Component | Specification |
|-----------|---------------|
| **CPU** | 4 vCPU |
| **RAM** | 8 GB |
| **Disk** | 50 GB SSD |
| **Network** | 2x 1 GbE (redundant) |
| **OS** | Debian 12 or RHEL 9 |

### WALLIX Bastion HW Appliances (2x per site, DMZ VLAN)

| Component | Specification |
|-----------|---------------|
| **Model** | WALLIX Bastion HW Appliance (specific model TBD) |
| **CPU** | 8+ cores (HW appliance) |
| **RAM** | 16+ GB |
| **Disk** | 500 GB+ (session recordings) |
| **Network** | 2x 1 GbE (redundant, bonded) |
| **IPMI/iLO** | Required for remote management |

### WALLIX RDS (1x per site, DMZ VLAN)

| Component | Specification |
|-----------|---------------|
| **CPU** | 4 vCPU |
| **RAM** | 8 GB |
| **Disk** | 100 GB |
| **Network** | 1 GbE |
| **OS** | Windows Server 2022 |

### FortiAuthenticator (2x per site, Cyber VLAN)

| Component | Specification |
|-----------|---------------|
| **Model** | FortiAuthenticator VM (FAC-VM) or physical |
| **CPU** | 4 vCPU |
| **RAM** | 8 GB |
| **Disk** | 50 GB |
| **Version** | 6.4+ |
| **Licenses** | FortiToken Mobile (FTM-ELIC) |

### Active Directory DC (1x per site, Cyber VLAN)

| Component | Specification |
|-----------|---------------|
| **CPU** | 2-4 vCPU |
| **RAM** | 4-8 GB |
| **Disk** | 80 GB |
| **OS** | Windows Server 2022 |
| **Role** | Active Directory Domain Services |

---

## Network Requirements

### MPLS Connectivity

- **Bandwidth**: Minimum 100 Mbps between sites and AM
- **Latency**: < 50ms round-trip preferred
- **Redundancy**: Dual MPLS paths recommended

### Per-Site VLAN Design

| VLAN | Subnet | Gateway | Purpose |
|------|--------|---------|---------|
| **DMZ VLAN** | 10.10.X.0/25 | 10.10.X.1 (Fortigate) | User access layer |
| **Cyber VLAN** | 10.10.X.128/25 | 10.10.X.129 (Fortigate) | Authentication backend |

### Critical Port Requirements

| Source | Destination | Port | Protocol | Purpose |
|--------|-------------|------|----------|---------|
| Users | HAProxy VIP (DMZ) | 443 | TCP | Bastion web UI |
| Users | HAProxy VIP (DMZ) | 22 | TCP | SSH proxy |
| Users | HAProxy VIP (DMZ) | 3389 | TCP | RDP proxy |
| HAProxy | Bastion (DMZ) | 443, 22, 3389 | TCP | Load balancing |
| Bastion (DMZ) | FortiAuth (Cyber) | 1812, 1813 | UDP | RADIUS (inter-VLAN) |
| Bastion (DMZ) | AD DC (Cyber) | 636 | TCP | LDAPS (inter-VLAN) |
| Bastion (DMZ) | AM (MPLS) | 443 | TCP | SAML, health check |

Inter-VLAN routing (DMZ ↔ Cyber) is handled by Fortigate per site.

See [01-network-design.md](01-network-design.md) for complete port matrix.

---

## Licensing Summary

### Bastion Licensing (Our Scope)

| Component | Quantity | Sessions | Notes |
|-----------|----------|----------|-------|
| **Bastion** | 10 appliances (5 sites × 2) | 150 concurrent total | 30/site |
| **FortiToken Mobile** | 150 licenses recommended | N/A | FTM-ELIC per user |

**Sizing Rationale**: 25 privileged users × 5 sites = 125 max simultaneous sessions. 150 provides +20% buffer.

**HA Licensing**: Each HA cluster counts as 1 license (not 2). Both nodes in a pair are covered by a single license.

### Access Manager Licensing (Client-Managed)

AM licensing is managed by the client team. Not within our deployment scope.

See [10-licensing.md](10-licensing.md) for detailed configuration.

---

## Site Locations

5 geographically distributed datacenter sites:

| Site | Location | Building |
|------|----------|----------|
| **Site 1** | Site 1 DC | Building A |
| **Site 2** | Site 2 DC | Building B |
| **Site 3** | Site 3 DC | Building C |
| **Site 4** | Site 4 DC | Building D |
| **Site 5** | Site 5 DC | Building E |

**Cross-site connectivity**: Sites are interconnected via MPLS. Bastions do NOT communicate directly — all inter-site session routing goes through the client-managed Access Managers.

---

## Target Systems

### Native Access (via Bastion)

- **Windows Server 2022** - RDP, WinRM
- **RHEL 10** - SSH
- **RHEL 9** - SSH (legacy)
- **Other Linux** - SSH

**Scale**: ~100-200 target servers per site.

### OT Systems (via WALLIX RDS Jump Host)

- **Industrial Control Systems** - RDP via RemoteApp
- **SCADA Systems** - RDP via RemoteApp
- **OT Workstations** - RDP via RemoteApp

**Rationale**: OT systems require additional isolation via jump host due to security policies.

---

## Deployment Models

### Active-Active Bastion Cluster (Recommended for High Load)

**Pros:**
- Load balancing: Both appliances handle traffic simultaneously
- Maximum capacity: Full utilization of both appliances
- Transparent failover: HAProxy distributes load

**Cons:**
- More complex configuration (bastion-replication Master/Master)
- Session state synchronization overhead

**Use Case**: Sites with 20+ concurrent sessions expected, HA critical

See [07-bastion-active-active.md](07-bastion-active-active.md) for setup.

---

### Active-Passive Bastion Cluster (Simpler, Lower Load)

**Pros:**
- Simpler configuration (single primary node)
- Faster failover (no replication conflict resolution)
- Lower operational complexity

**Cons:**
- Passive node idle during normal operation
- 30-60 second failover interruption

**Use Case**: Sites with lighter load, simplicity preferred for initial deployment

See [08-bastion-active-passive.md](08-bastion-active-passive.md) for setup.

---

## Prerequisites Checklist

Before starting deployment:

### Network

- [ ] MPLS circuits installed and tested (all sites + AM reachable)
- [ ] DMZ VLAN (10.10.X.0/25) and Cyber VLAN (10.10.X.128/25) configured per site
- [ ] Fortigate inter-VLAN routing rules created (DMZ ↔ Cyber, RADIUS + LDAPS)
- [ ] DNS records created for all components (DMZ and Cyber per site)
- [ ] NTP servers configured and reachable
- [ ] SSL certificates obtained (wildcard or per-host)

### Hardware

- [ ] 10x WALLIX Bastion HW appliances received and racked (DMZ VLAN, 2/site)
- [ ] 10x HAProxy servers provisioned (DMZ VLAN, 2/site)
- [ ] 5x WALLIX RDS servers (Windows Server 2022) ready (DMZ VLAN, 1/site)
- [ ] 10x FortiAuthenticator VMs provisioned (Cyber VLAN, 2/site)
- [ ] 5x Active Directory DCs provisioned (Cyber VLAN, 1/site)
- [ ] IPMI/iLO access configured for all Bastion appliances

### Access Manager (Client-Side)

- [ ] Client AM team contact established
- [ ] SAML IdP metadata URL obtained from client AM team
- [ ] Bastion registration parameters agreed upon (health check URL, SAML metadata URL)

### Licensing

- [ ] Bastion license pool purchased (150 concurrent sessions total)
- [ ] FortiToken Mobile licenses obtained (150 FTM-ELIC recommended)
- [ ] License activation keys received
- [ ] Client AM licensing confirmed with client team (not our scope)

### Security

- [ ] Per-site AD/LDAP service account created for Bastion LDAP sync
- [ ] Per-site FortiAuthenticator RADIUS shared secret defined
- [ ] FortiToken Mobile enrollment plan confirmed with security team
- [ ] Encryption keys generated (database, sessions)
- [ ] Backup storage configured (offsite)

---

## Quick Start Guide

1. **Read Prerequisites**: [00-prerequisites.md](00-prerequisites.md)
2. **Design Network**: [01-network-design.md](01-network-design.md) (both VLANs)
3. **Choose HA Model**: [02-ha-architecture.md](02-ha-architecture.md)
4. **Set Up FortiAuth HA (Site 1)**: [03-fortiauthenticator-ha.md](03-fortiauthenticator-ha.md)
5. **Configure AD/LDAP**: [04-ad-per-site.md](04-ad-per-site.md)
6. **Deploy Site 1**: [05-site-deployment.md](05-site-deployment.md)
7. **Replicate Sites 2-5**: Repeat per-site steps (FortiAuth + Bastion + RDS)
8. **Verify Licensing**: [10-licensing.md](10-licensing.md)
9. **Test End-to-End**: [11-testing-validation.md](11-testing-validation.md)
10. **Coordinate AM Registration**: [15-access-manager-integration.md](15-access-manager-integration.md)

**Full walkthrough**: See [HOWTO.md](HOWTO.md)

---

## Support and Resources

### Official Documentation

- WALLIX Bastion 12.x Admin Guide: https://pam.wallix.one/documentation/admin-doc/bastion_en_administration_guide.pdf
- WALLIX Bastion User Guide: https://pam.wallix.one/documentation/user-doc/bastion_en_user_guide.pdf
- FortiAuthenticator Guide: https://docs.fortinet.com/product/fortiauthenticator
- WALLIX Support Portal: https://support.wallix.com

### Internal Resources

- **PAM Documentation**: [/docs/pam/](../docs/pam/)
- **Pre-Production Lab**: [/pre/](../pre/) - Test environment setup
- **Automation Examples**: [/examples/](../examples/) - Ansible, API scripts

### Architecture Diagrams

- See [12-architecture-diagrams.md](12-architecture-diagrams.md) for detailed network topology, data flows, and port matrices

---

## Version Information

| Component | Version |
|-----------|---------|
| WALLIX Bastion | 12.1.x |
| FortiAuthenticator | 6.4+ |
| HAProxy | 2.8+ |
| MariaDB | 10.11+ |
| Windows Server (RDS) | 2022 |
| Document Version | 2.0 |
| Last Updated | April 2026 |

---

## Architecture Summary

**Deployment Model**: 5-site multi-datacenter, per-site FortiAuth HA + AD, client-managed Access Manager

**HA Strategy**: Choice of Active-Active (high capacity) or Active-Passive (simplicity) per site

**Network**: MPLS-based, isolated sites, DMZ + Cyber VLAN per site, Fortigate inter-VLAN routing

**Licensing**: 150 concurrent Bastion sessions (30/site); AM licensing is client-managed

**MFA**: FortiToken Mobile (TOTP only, 30-second window), per-site FortiAuth HA

**Access Patterns**: Native (Windows/Linux) + Jump host (OT RemoteApp)

**Timeline**: 10 weeks end-to-end deployment

---

*For questions or clarifications, refer to the detailed installation guides linked above.*

**Next Step**: Review [HOWTO.md](HOWTO.md) for step-by-step deployment instructions.
