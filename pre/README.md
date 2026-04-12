# Pre-Production Lab Environment

## WALLIX Bastion Lab for Testing, Learning, and Team Integration

This guide covers setting up a pre-production environment that simulates **one site (Site 1) of the production architecture**, simplified — same VLAN design but no HA clustering for Bastion or FortiAuthenticator.

### Lab Features
- 1x WALLIX Bastion 12.1.x (single node, no cluster)
- 2x HAProxy load balancers (Active-Passive with Keepalived VIP) — VIP failover tested in lab
- 1x WALLIX RDS for RDP session proxying (DMZ VLAN)
- 1x FortiAuthenticator 6.4+ (single node, Cyber VLAN) — TOTP only
- 1x Active Directory DC (Cyber VLAN)
- Windows Server 2022 and RHEL 10/9 targets (Targets VLAN)
- SIEM/Wazuh and Prometheus/Grafana (Management VLAN)

---

## Prerequisites

### VMware vSphere/ESXi Environment

| Component | Requirement |
|-----------|-------------|
| **Hypervisor** | VMware vSphere 8.0+ or ESXi 8.0+ |
| **vCenter Server** | Optional but recommended for VM management |
| **Storage** | VMFS or NFS datastore with at least 1.2TB available space |
| **Network** | Distributed vSwitch preferred, Standard vSwitch acceptable |
| **Templates** | Debian 12 OVA template recommended for rapid deployment |

### Hardware Resources (Total — 12 VMs)

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| **CPU** | 28 vCPU | 40 vCPU |
| **RAM** | 80 GB | 120 GB |
| **Storage** | 1.2 TB | 1.5 TB |
| **Network** | 1 Gbps | 10 Gbps |

### Network Configuration

- 4 VLANs configured on vSwitch (Management, DMZ, Cyber, Targets)
- Port groups created for each VLAN with appropriate security policies
- Fortigate firewall handles inter-VLAN routing (DMZ <-> Cyber <-> Targets)
- AD DC and DNS accessible from all zones via Fortigate routing

---

## Architecture Overview

```
+===============================================================================+
|              PRE-PRODUCTION LAB - SINGLE SITE (SITE 1 SIMULATION)            |
+===============================================================================+
|                                                                               |
|  MANAGEMENT VLAN 100 (10.10.0.0/24)                                          |
|  +--------------------------+     +----------------------------+              |
|  |  siem-lab 10.10.0.10     |     |  monitor-lab 10.10.0.20    |              |
|  |  Ubuntu 22.04            |     |  Ubuntu 22.04              |              |
|  |  Wazuh SIEM              |     |  Prometheus + Grafana      |              |
|  +--------------------------+     +----------------------------+              |
|                                                                               |
|  ===================== FORTIGATE INTER-VLAN ROUTING ========================  |
|                                                                               |
|  DMZ VLAN 110 (10.10.1.x)                                                    |
|  +------------+   +------------+                                              |
|  | haproxy-1  |   | haproxy-2  |  VIP: 10.10.1.100 (Keepalived VRRP)        |
|  | 10.10.1.5  |<->| 10.10.1.6  |  Active-Passive                             |
|  +-----+------+   +-----+------+                                              |
|        |                |                                                     |
|        +-------+--------+                                                     |
|                |                                                              |
|  +-------------+-------------------+  +------------------------------+       |
|  | wallix-bastion  10.10.1.11      |  | wallix-rds  10.10.1.30      |       |
|  | WALLIX Bastion 12.1.x (single)  |  | Windows Server 2022         |       |
|  +----------------------------------+  +------------------------------+       |
|                                                                               |
|  CYBER VLAN 120 (10.10.1.x)                                                  |
|  +-----------------------------+   +--------------------------------+         |
|  | fortiauth  10.10.1.50       |   | dc-lab  10.10.1.60             |         |
|  | FortiAuthenticator 6.4+     |   | Windows Server 2022 (AD DC)    |         |
|  | Single node, TOTP only      |   | Domain: lab.local              |         |
|  +-----------------------------+   +--------------------------------+         |
|                                                                               |
|  ======================== FORTIGATE FIREWALL ================================  |
|                                                                               |
|  TARGETS VLAN 130 (10.10.2.0/24)                                             |
|  +----------------+  +----------------+  +-------------+  +-------------+    |
|  | win-srv-01     |  | win-srv-02     |  | rhel10-srv  |  | rhel9-srv   |    |
|  | 10.10.2.10     |  | 10.10.2.11     |  | 10.10.2.20  |  | 10.10.2.21  |    |
|  | WinSrv 2022    |  | WinSrv 2022    |  | RHEL 10     |  | RHEL 9      |    |
|  | General target |  | SQL target     |  | App server  |  | Legacy srv  |    |
|  +----------------+  +----------------+  +-------------+  +-------------+    |
|                                                                               |
+===============================================================================+
```

---

## Network Zones

| Zone | VLAN | Subnet | Purpose |
|------|------|--------|---------|
| Management | 100 | 10.10.0.0/24 | Lab ops: Wazuh SIEM, Prometheus/Grafana |
| DMZ | 110 | 10.10.1.0/24 | HAProxy x2, WALLIX Bastion x1, WALLIX RDS x1 |
| Cyber | 120 | 10.10.1.0/24* | FortiAuthenticator x1, Active Directory DC x1 |
| Targets | 130 | 10.10.2.0/24 | Windows Server 2022 x2, RHEL 10 x1, RHEL 9 x1 |

*DMZ (VLAN 110) and Cyber (VLAN 120) share the 10.10.1.x /24 range but are on separate VLANs. Fortigate handles inter-VLAN routing. This mirrors production where DMZ and Cyber are logically separated by VLAN, not by subnet prefix.

---

## VM Inventory

### Management Zone — VLAN 100, 10.10.0.0/24

| VM Name | IP Address | OS | Purpose | Resources |
|---------|------------|-----|---------|-----------|
| `siem-lab` | 10.10.0.10 | Ubuntu 22.04 | Wazuh SIEM | 4 vCPU, 16GB RAM, 500GB |
| `monitor-lab` | 10.10.0.20 | Ubuntu 22.04 | Prometheus + Grafana | 2 vCPU, 8GB RAM, 100GB |

### DMZ Zone — VLAN 110, 10.10.1.x

| VM Name | IP Address | OS | Purpose | Resources |
|---------|------------|-----|---------|-----------|
| `haproxy-1` | 10.10.1.5 | Debian 12 | HAProxy Primary | 2 vCPU, 4GB RAM, 20GB |
| `haproxy-2` | 10.10.1.6 | Debian 12 | HAProxy Backup | 2 vCPU, 4GB RAM, 20GB |
| HAProxy VIP | 10.10.1.100 | — | Keepalived VRRP VIP | — |
| `wallix-bastion` | 10.10.1.11 | WALLIX Bastion 12.1.x | Bastion (single node) | 4 vCPU, 16GB RAM, 200GB |
| `wallix-rds` | 10.10.1.30 | Windows Server 2022 | WALLIX RDS | 4 vCPU, 8GB RAM, 100GB |

### Cyber Zone — VLAN 120, 10.10.1.x

| VM Name | IP Address | OS | Purpose | Resources |
|---------|------------|-----|---------|-----------|
| `fortiauth` | 10.10.1.50 | FortiAuthenticator 6.4+ | MFA (TOTP, single node) | 2 vCPU, 4GB RAM, 40GB |
| `dc-lab` | 10.10.1.60 | Windows Server 2022 | Active Directory DC | 2 vCPU, 4GB RAM, 60GB |

### Targets Zone — VLAN 130, 10.10.2.0/24

| VM Name | IP Address | OS | Purpose | Resources |
|---------|------------|-----|---------|-----------|
| `win-srv-01` | 10.10.2.10 | Windows Server 2022 | General Windows target | 2 vCPU, 8GB RAM, 60GB |
| `win-srv-02` | 10.10.2.11 | Windows Server 2022 | SQL Server target | 4 vCPU, 16GB RAM, 100GB |
| `rhel10-srv` | 10.10.2.20 | RHEL 10 | Linux app server | 2 vCPU, 4GB RAM, 40GB |
| `rhel9-srv` | 10.10.2.21 | RHEL 9 | Legacy Linux server | 2 vCPU, 4GB RAM, 40GB |

**Total VMs**: 12

---

## Quick Start

| Step | Document | Time |
|------|----------|------|
| 1 | [Infrastructure Setup](./01-infrastructure-setup.md) | 4 hours |
| 2 | [Active Directory Setup](./02-active-directory-setup.md) | 1 hour |
| 3 | [HAProxy Load Balancers](./03-haproxy-setup.md) | 1 hour |
| 4 | [FortiAuthenticator MFA Setup](./04-fortiauthenticator-setup.md) | 1 hour |
| 5 | [WALLIX RDS Session Manager](./05-wallix-rds-setup.md) | 1 hour |
| 6 | [AD Integration with MFA](./06-ad-integration.md) | 1 hour |
| 7 | [WALLIX Bastion Installation](../install/HOWTO.md) | 2 hours |
| 8 | [HA Reference Guide](./08-ha-active-active.md) | reference only |
| 9 | [Test Targets Setup](./09-test-targets.md) | 2 hours |
| 10 | [SIEM Integration](./10-siem-integration.md) | 2 hours |
| 11 | [Observability Stack](./11-observability.md) | 2 hours |
| 12 | [Validation & Testing](./12-validation-testing.md) | 2 hours |
| 13 | [Team Handoff Guides](./13-team-handoffs.md) | — |
| 14 | [Battery Tests (Client Demos)](./14-battery-tests.md) | 4 hours |

**Total Estimated Time**: ~24 hours (3 days)

---

## Network Requirements

### Firewall Rules

```
+===============================================================================+
|  FIREWALL RULES                                                               |
+===============================================================================+
|                                                                               |
|  USERS -> DMZ VIP                                                             |
|  -------------------------------------------------------------------          |
|  Users            -> VIP (10.10.1.100) : 443       Web UI (HTTPS)            |
|  Users            -> VIP (10.10.1.100) : 22        SSH Proxy                 |
|  Users            -> VIP (10.10.1.100) : 3389      RDP Proxy                 |
|                                                                               |
|  DMZ INTERNAL (HAProxy -> Bastion)                                            |
|  -------------------------------------------------------------------          |
|  haproxy-1/2      -> wallix-bastion    : 443,22,3389  Load balanced          |
|  haproxy-1        <-> haproxy-2        : VRRP       Keepalived               |
|                                                                               |
|  DMZ -> CYBER (inter-VLAN via Fortigate)                                      |
|  -------------------------------------------------------------------          |
|  wallix-bastion   -> fortiauth (Cyber) : 1812/1813 UDP  RADIUS MFA           |
|  wallix-bastion   -> dc-lab (Cyber)    : 636 TCP        LDAPS                |
|  wallix-bastion   -> dc-lab (Cyber)    : 389 TCP        LDAP                 |
|  wallix-bastion   -> dc-lab (Cyber)    : 88 TCP/UDP     Kerberos             |
|                                                                               |
|  CYBER INTERNAL (intra-VLAN, no routing needed)                               |
|  -------------------------------------------------------------------          |
|  fortiauth        -> dc-lab            : 389 TCP        LDAP (user sync)     |
|                                                                               |
|  DMZ -> TARGETS (inter-VLAN via Fortigate)                                    |
|  -------------------------------------------------------------------          |
|  wallix-bastion   -> win-srv-*         : 3389      RDP to Windows            |
|  wallix-bastion   -> win-srv-*         : 5985/5986 WinRM                     |
|  wallix-bastion   -> rhel*-srv         : 22        SSH to Linux              |
|                                                                               |
|  MANAGEMENT -> ALL (metrics and logs)                                         |
|  -------------------------------------------------------------------          |
|  monitor-lab      -> all nodes         : 9100      Prometheus node exporter  |
|  all nodes        -> siem-lab          : 514/6514  Syslog                    |
|                                                                               |
+===============================================================================+
```

---

## Credentials Reference (Lab Only)

> **WARNING**: Change all passwords before any production use!

| System | Username | Password | Purpose |
|--------|----------|----------|---------|
| AD Domain | Administrator | `LabAdmin123!` | Domain admin |
| AD Domain | wallix-svc | `WallixSvc123!` | LDAP bind account |
| WALLIX | admin | `WallixAdmin123!` | Web UI admin |
| WALLIX | wabadmin | `WabAdmin123!` | CLI admin |
| MariaDB | root | `DbAdmin123!` | Database |
| Linux Test | root | `LinuxRoot123!` | SSH target |
| Windows Test | Administrator | `WinAdmin123!` | RDP target |
| Wazuh | admin | `WazuhAdmin123!` | SIEM admin |
| Grafana | admin | `GrafanaAdmin123!` | Monitoring |
| FortiAuth | admin | `FortiAdmin123!` | MFA admin |

---

## Team Integration Points

| Team | Integration | Documentation |
|------|-------------|---------------|
| **Networking** | Firewall rules, VLANs, VIP | [Network Handoff](./13-team-handoffs.md#networking) |
| **SIEM/Security** | Log forwarding, alerts | [SIEM Handoff](./13-team-handoffs.md#siem) |
| **Observability** | Metrics, dashboards | [Observability Handoff](./13-team-handoffs.md#observability) |
| **Identity/IAM** | AD groups, MFA | [IAM Handoff](./13-team-handoffs.md#identity) |

---

## Lab Objectives Checklist

### Phase 1: Core Platform
- [ ] WALLIX Bastion single node operational
- [ ] HAProxy VIP failover tested (haproxy-1 <-> haproxy-2)
- [ ] AD authentication working (LDAPS to dc-lab on Cyber VLAN)
- [ ] FortiAuthenticator TOTP MFA working
- [ ] Basic session management functional

### Phase 2: Integration
- [ ] SIEM (Wazuh) receiving logs from Bastion
- [ ] Prometheus scraping metrics from all nodes
- [ ] Grafana dashboards operational
- [ ] Alerts configured

### Phase 3: Testing
- [ ] SSH session through WALLIX Bastion
- [ ] RDP session through WALLIX Bastion with RDS
- [ ] Password rotation tested
- [ ] Session recording verified
- [ ] HAProxy VIP failover verified

### Phase 4: Team Validation
- [ ] Networking team sign-off
- [ ] SIEM team sign-off
- [ ] Observability team sign-off
- [ ] Security team sign-off

---

## Files in This Directory

```
pre/
├── README.md                            # This file
├── 01-infrastructure-setup.md           # VM provisioning (4 VLANs)
├── 02-active-directory-setup.md         # AD DC in Cyber VLAN (10.10.1.60)
├── 03-haproxy-setup.md                  # HAProxy Active-Passive with Keepalived
├── 04-fortiauthenticator-setup.md       # FortiAuth MFA (single node, Cyber VLAN)
├── 05-wallix-rds-setup.md               # WALLIX RDS (DMZ VLAN)
├── 06-ad-integration.md                 # LDAP/Kerberos/MFA integration
├── 08-ha-active-active.md               # HA reference guide (production reference)
├── 09-test-targets.md                   # Windows/RHEL test VMs (Targets VLAN)
├── 10-siem-integration.md               # Wazuh SIEM (Management VLAN)
├── 11-observability.md                  # Prometheus/Grafana (Management VLAN)
├── 12-validation-testing.md             # Test procedures
├── 13-team-handoffs.md                  # Team documentation
└── 14-battery-tests.md                  # Client demo test suite
```

---

*Last updated: April 2026 | WALLIX Bastion 12.1.x | FortiAuthenticator 6.4+*

<p align="center">
  <a href="./01-infrastructure-setup.md">Start: Infrastructure Setup →</a>
</p>
