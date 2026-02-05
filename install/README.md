# WALLIX Bastion - 5-Site Multi-Datacenter Deployment with Access Manager Integration

> Enterprise deployment guide for 5 WALLIX Bastion sites integrated with 2 WALLIX Access Managers in HA configuration

---

## Architecture Overview

This installation guide covers the deployment of a multi-site WALLIX PAM infrastructure:

| Component | Quantity | Configuration |
|-----------|----------|---------------|
| **WALLIX Access Manager** | 2 | HA (Active-Passive), separate datacenters |
| **WALLIX Bastion Sites** | 5 | Each in separate datacenter |
| **HAProxy per Site** | 2 | Active-Passive load balancer pair |
| **Bastion Appliances per Site** | 2 | Active-Active OR Active-Passive (both documented) |
| **WALLIX RDS** | 1 per site | Jump host for OT RemoteApp access |
| **Network** | MPLS | Connectivity between Access Managers and Bastions |

---

## Network Topology

```
+===============================================================================+
|  5-SITE MULTI-DATACENTER ARCHITECTURE WITH ACCESS MANAGER INTEGRATION        |
+===============================================================================+
|                                                                               |
|  +--------------------------+      +--------------------------+               |
|  | Access Manager 1 (DC-A)  |      | Access Manager 2 (DC-B)  |               |
|  | - SSO / MFA              |      | - SSO / MFA              |               |
|  | - Session Brokering      | HA   | - Session Brokering      |               |
|  | - License Management     |<---->| - License Management     |               |
|  +-----------+--------------+      +--------------+-----------+               |
|              |                                    |                           |
|              +------------------------------------+                           |
|                           MPLS Network                                        |
|       +-------------------+----+----+----+--------------------+               |
|       |                   |         |         |               |               |
|  +----v----+         +----v----+   ...   +----v----+    +----v----+          |
|  | Site 1  |         | Site 2  |         | Site 4  |    | Site 5  |          |
|  |   |         |   |         |   |    |   |          |
|  | (DC-1) |         | (DC-2) |         | (DC-4) |    | (DC-5) |          |
|  +---------+         +---------+         +---------+    +---------+          |
|                                                                               |
|  Each Site Contains:                                                          |
|  - 2x HAProxy (Active-Passive)                                                |
|  - 2x WALLIX Bastion HW Appliances (Active-Active or Active-Passive)         |
|  - 1x WALLIX RDS (Jump host for OT RemoteApp)                                |
|                                                                               |
|  NO direct Bastion-to-Bastion communication between sites                    |
|                                                                               |
+===============================================================================+
```

---

## Key Architecture Principles

### Network Isolation
- **Access Manager ↔ Bastion**: MPLS connectivity
- **Bastion ↔ Bastion**: NO direct communication between sites
- **Site Internal**: Full connectivity between HAProxy, Bastion, RDS

### High Availability Options
- **Active-Active**: Both Bastion appliances handle traffic simultaneously (load balancing)
- **Active-Passive**: One primary, one standby (automatic failover)
- See [02-ha-architecture.md](02-ha-architecture.md) for detailed comparison

### Access Patterns
1. **Native Access**: Windows/Linux via SSH, RDP, VNC
2. **OT Access**: Via WALLIX RDS jump host using RemoteApp (RDP only)

### Licensing Model
- **Split Pools**:
  - Access Manager license pool (managed centrally)
  - Bastion license pool (shared across 5 sites)
- See [09-licensing.md](09-licensing.md) for integration details

---

## Integration with Access Manager

The WALLIX Access Manager provides centralized management:

| Function | Description |
|----------|-------------|
| **SSO Integration** | Single Sign-On for end users |
| **MFA** | Multi-factor authentication via FortiAuthenticator |
| **Session Brokering** | Routes user sessions to appropriate Bastion site |
| **License Integration** | Centralized license pool management (optional) |

**Important**: Access Managers are managed by a separate team. This guide covers the Bastion-side integration configuration only.

---

## Deployment Timeline

| Phase | Duration | Tasks |
|-------|----------|-------|
| **Phase 1: Planning** | Week 1 | Prerequisites, network design, licensing |
| **Phase 2: Access Manager Integration** | Week 2 | SSO, MFA, session brokering setup |
| **Phase 3: Site 1 Deployment** | Week 3-4 | HAProxy, Bastion cluster, RDS, testing |
| **Phase 4: Site 2 Deployment** | Week 5 | Replicate Site 1 configuration |
| **Phase 5: Site 3 Deployment** | Week 6 | Replicate Site 1 configuration |
| **Phase 6: Site 4 Deployment** | Week 7 | Replicate Site 1 configuration |
| **Phase 7: Site 5 Deployment** | Week 8 | Replicate Site 1 configuration |
| **Phase 8: Final Integration** | Week 9 | License pooling, testing, optimization |
| **Phase 9: Go-Live** | Week 10 | Production cutover, documentation handoff |

**Total Timeline**: 10 weeks (2.5 months)

---

## Installation Documentation Structure

### Planning & Design
- [00-prerequisites.md](00-prerequisites.md) - Hardware, network, licensing requirements
- [01-network-design.md](01-network-design.md) - MPLS topology, connectivity, ports
- [02-ha-architecture.md](02-ha-architecture.md) - Active-Active vs Active-Passive comparison

### Access Manager Integration
- [03-access-manager-integration.md](03-access-manager-integration.md) - SSO, MFA, brokering, licensing

### Site Deployment
- [04-site-deployment.md](04-site-deployment.md) - Per-site deployment template
- [05-haproxy-setup.md](05-haproxy-setup.md) - HAProxy configuration
- [06-bastion-active-active.md](06-bastion-active-active.md) - Active-Active cluster setup
- [07-bastion-active-passive.md](07-bastion-active-passive.md) - Active-Passive cluster setup
- [08-rds-jump-host.md](08-rds-jump-host.md) - WALLIX RDS for OT RemoteApp

### Operations
- [09-licensing.md](09-licensing.md) - License pools and integration
- [10-testing-validation.md](10-testing-validation.md) - End-to-end testing procedures
- [11-architecture-diagrams.md](11-architecture-diagrams.md) - Network diagrams and port reference

### Quick Start
- **[HOWTO.md](HOWTO.md)** - Main step-by-step installation guide

---

## Hardware Requirements (Per Site)

### HAProxy Servers (2x per site)

| Component | Specification |
|-----------|---------------|
| **CPU** | 4 vCPU |
| **RAM** | 8 GB |
| **Disk** | 50 GB SSD |
| **Network** | 2x 1 GbE (redundant) |
| **OS** | Debian 12 or RHEL 9 |

### WALLIX Bastion HW Appliances (2x per site)

| Component | Specification |
|-----------|---------------|
| **Model** | WALLIX Bastion HW Appliance (specific model TBD) |
| **CPU** | 8+ cores (HW appliance) |
| **RAM** | 16+ GB |
| **Disk** | 500 GB+ (session recordings) |
| **Network** | 2x 1 GbE (redundant, bonded) |
| **IPMI/iLO** | Required for remote management |

### WALLIX RDS (1x per site)

| Component | Specification |
|-----------|---------------|
| **CPU** | 4 vCPU |
| **RAM** | 8 GB |
| **Disk** | 100 GB |
| **Network** | 1 GbE |
| **OS** | Windows Server 2022 |

---

## Network Requirements

### MPLS Connectivity
- **Bandwidth**: Minimum 100 Mbps between Access Managers and each site
- **Latency**: < 50ms round-trip preferred
- **Redundancy**: Dual MPLS paths recommended

### Ports (Access Manager ↔ Bastion)

| Source | Destination | Port | Protocol | Purpose |
|--------|-------------|------|----------|---------|
| Access Manager | Bastion | 443 | TCP/HTTPS | API, session brokering |
| Bastion | Access Manager | 443 | TCP/HTTPS | SSO callbacks, health checks |
| Bastion | FortiAuthenticator | 1812 | UDP | RADIUS authentication |
| Bastion | FortiAuthenticator | 1813 | UDP | RADIUS accounting |

See [01-network-design.md](01-network-design.md) for complete port matrix.

---

## Licensing Summary

### License Pools

| Pool | Components | Sessions | Notes |
|------|------------|----------|-------|
| **Access Manager** | 2 AM instances (HA) | 500 concurrent | Managed centrally |
| **Bastion** | 10 Bastion appliances (5 sites × 2) | 450 concurrent | Shared across sites |

**HA Licensing**: Each HA cluster counts as 1 license (not 2).

**Total Licensed Capacity**: 950 concurrent sessions (500 AM + 450 Bastion)

See [09-licensing.md](09-licensing.md) for detailed configuration and integration.

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

**Cross-site connectivity**: Sites are interconnected within datacenter site fabric, but Bastions do NOT communicate directly (all traffic routes through Access Managers via MPLS).

---

## Target Systems

### Native Access (via Bastion)
- **Windows Server 2022** - RDP, WinRM
- **RHEL 10** - SSH
- **RHEL 9** - SSH (legacy)
- **Other Linux** - SSH

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
- No standby waste: All hardware actively used
- Transparent failover: HAProxy distributes load

**Cons:**
- More complex configuration (MariaDB multi-master replication)
- Requires split-brain protection (Pacemaker/Corosync)
- Session state synchronization overhead

**Use Case**: Sites with 100+ concurrent sessions, high availability critical

See [06-bastion-active-active.md](06-bastion-active-active.md) for setup.

---

### Active-Passive Bastion Cluster (Simpler, Lower Load)

**Pros:**
- Simpler configuration (single primary node)
- Faster failover (no replication conflict resolution)
- Lower operational complexity
- Easier troubleshooting

**Cons:**
- 50% capacity utilization (passive node idle)
- Failover interruption (30-60 seconds)
- Passive node hardware underutilized

**Use Case**: Sites with < 100 concurrent sessions, simplicity preferred

See [07-bastion-active-passive.md](07-bastion-active-passive.md) for setup.

---

## Prerequisites Checklist

Before starting deployment:

### Network
- [ ] MPLS circuits installed and tested
- [ ] Firewall rules configured (Access Manager ↔ Bastion)
- [ ] DNS records created for all components
- [ ] NTP servers configured and reachable
- [ ] SSL certificates obtained (wildcard or per-host)

### Hardware
- [ ] 10x WALLIX Bastion HW appliances received and racked
- [ ] 10x HAProxy servers (VMs or physical) provisioned
- [ ] 5x WALLIX RDS servers (Windows Server 2022) ready
- [ ] IPMI/iLO access configured for all appliances

### Access Manager
- [ ] Access Manager HA configuration documented
- [ ] SSO integration method confirmed (SAML, OIDC, LDAP)
- [ ] FortiAuthenticator RADIUS configuration provided
- [ ] Session brokering API endpoints available

### Licensing
- [ ] Access Manager license pool confirmed (500 sessions)
- [ ] Bastion license pool purchased (450 sessions)
- [ ] License activation keys received
- [ ] License server access credentials available

### Security
- [ ] AD/LDAP service account created for user sync
- [ ] FortiAuthenticator RADIUS shared secret obtained
- [ ] Encryption keys generated (database, sessions)
- [ ] Backup storage configured (offsite)

---

## Quick Start Guide

1. **Read Prerequisites**: [00-prerequisites.md](00-prerequisites.md)
2. **Design Network**: [01-network-design.md](01-network-design.md)
3. **Choose HA Model**: [02-ha-architecture.md](02-ha-architecture.md)
4. **Integrate Access Manager**: [03-access-manager-integration.md](03-access-manager-integration.md)
5. **Deploy Site 1**: [04-site-deployment.md](04-site-deployment.md)
6. **Replicate Sites 2-5**: Repeat Site 1 deployment
7. **Configure Licensing**: [09-licensing.md](09-licensing.md)
8. **Test End-to-End**: [10-testing-validation.md](10-testing-validation.md)

**Full walkthrough**: See [HOWTO.md](HOWTO.md)

---

## Support and Resources

### Official Documentation
- WALLIX Bastion 12.x Admin Guide: https://pam.wallix.one/documentation
- WALLIX Access Manager Guide: https://pam.wallix.one/documentation
- FortiAuthenticator Guide: https://docs.fortinet.com/product/fortiauthenticator

### Internal Resources
- **PAM Documentation**: [/docs/pam/](../docs/pam/)
- **Pre-Production Lab**: [/pre/](../pre/) - Test environment setup
- **Automation Examples**: [/examples/](../examples/) - Ansible, API scripts

### Architecture Diagrams
- See [11-architecture-diagrams.md](11-architecture-diagrams.md) for detailed network topology, data flows, and port matrices

---

## Version Information

| Component | Version |
|-----------|---------|
| WALLIX Bastion | 12.1.x |
| WALLIX Access Manager | 5.2.x |
| FortiAuthenticator | 6.4+ |
| HAProxy | 2.8+ |
| MariaDB | 10.11+ |
| Windows Server (RDS) | 2022 |

---

## Architecture Summary

**Deployment Model**: 5-site multi-datacenter with centralized Access Manager

**HA Strategy**: Choice of Active-Active (high capacity) or Active-Passive (simplicity)

**Network**: MPLS-based, isolated sites, no direct inter-site Bastion communication

**Licensing**: Split pools (AM + Bastion), centralized management

**Access Patterns**: Native (Windows/Linux) + Jump host (OT RemoteApp)

**Timeline**: 10 weeks end-to-end deployment

---

*For questions or clarifications, refer to the detailed installation guides linked above.*

**Next Step**: Review [HOWTO.md](HOWTO.md) for step-by-step deployment instructions.
