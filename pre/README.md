# Pre-Production Lab Environment

## WALLIX Bastion Lab for Testing, Learning, and Team Integration

This guide covers setting up a pre-production environment that **closely mirrors a real enterprise environment** with Fortigate MFA integration.

### Lab Features
- 2x WALLIX Bastion nodes in Active-Active HA with HAProxy LB
- 2x HAProxy load balancers in HA with Keepalived VIP
- 1x WALLIX RDS Session Manager for RDP session management
- 1x FortiAuthenticator for MFA (RADIUS/FortiToken)
- Windows Server 2022 targets
- RHEL 10 and RHEL 9 targets
- Active Directory integration with MFA
- SIEM/SOC integration
- Observability/monitoring stack

---

## Prerequisites

### VMware vSphere/ESXi Environment

| Component | Requirement |
|-----------|-------------|
| **Hypervisor** | VMware vSphere 7.0+ or ESXi 7.0+ |
| **vCenter Server** | Optional but recommended for HA cluster management |
| **Storage** | VMFS or NFS datastore with at least 1TB available space |
| **Network** | Distributed vSwitch preferred, Standard vSwitch acceptable |
| **Templates** | Debian 12 OVA template recommended for rapid deployment |

### Hardware Resources (Total)

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| **CPU** | 32 vCPU | 48 vCPU |
| **RAM** | 64 GB | 128 GB |
| **Storage** | 1 TB | 1.5 TB |
| **Network** | 1 Gbps | 10 Gbps |

### Network Configuration

- 3 VLANs configured on vSwitch (Management, DMZ, Servers)
- Port groups created for each VLAN with appropriate security policies
- Network connectivity to corporate Active Directory and DNS
- Internet access for downloading software packages (can be restricted post-deployment)

---

## Architecture Overview

```
+===============================================================================+
|                    PRE-PRODUCTION LAB - ENTERPRISE ARCHITECTURE               |
+===============================================================================+

  MANAGEMENT NETWORK (10.10.0.0/24)
  ==========================================
                              CORPORATE NETWORK
                                     |
                       +-------------+-------------+
                       |                           |
                 +-----------+               +-----------+
                 |    AD     |               |   SIEM    |
                 |  DC-LAB   |               |  (SOC)    |
                 |10.10.0.10 |               |10.10.0.50 |
                 +-----------+               +-----------+
                                     |
  ----------------------------- FORTIGATE FIREWALL ----------------------------
                                     |
  DMZ NETWORK (10.10.1.0/24)
  ==================================
       +-----------+               +-----------+
       | Fortigate |               |FortiAuth  |
       | Firewall  |               |   (MFA)   |
       |10.10.1.1  |               |10.10.1.50 |
       +-----------+               +-----------+
             |                           |
             +-----------+---------------+
                         |
                 +-----------+               +-----------+
                 |  HAProxy  |               |  HAProxy  |
                 |    LB-1   |<-- VRRP HA -->|    LB-2   |
                 |10.10.1.5  |               |10.10.1.6  |
                 +-----------+               +-----------+
                       |      VIP: 10.10.1.100     |
                       +-------------+-------------+
                                     |
                 +-----------+               +-----------+
                 |  WALLIX   |               |  WALLIX   |
                 | Bastion-1 |<-- HA Sync -->| Bastion-2 |
                 |10.10.1.11 |               |10.10.1.12 |
                 +-----------+               +-----------+
                       |                           |
       +---------------+---------------+-----------+
       |               |               |           |
  +-----------+  +-----------+  +-----------+ +-----------+
  |WALLIX RDS |  |   SIEM    | | Monitoring|
  | Session   |  | (Wazuh)   | |Prometheus |
  |   Mgr     |  |10.10.0.50 | |10.10.1.60 |
  |10.10.1.30 |  +-----------+ +-----------+
  +-----------+
                                     |
  ----------------------------- INTERNAL FIREWALL ----------------------------
                                     |
  SERVER NETWORK (10.10.2.0/24)
  ==========================================================================
               +------------+------------+------------+
               |            |            |            |
          +----------+ +----------+ +----------+ +----------+
          | Windows  | | Windows  | | RHEL 10  | | RHEL 9   |
          | Server   | | Server   | | Server   | | (Legacy) |
          |10.10.2.10| |10.10.2.11| |10.10.2.20| |10.10.2.21|
          +----------+ +----------+ +----------+ +----------+

+===============================================================================+
```

---

## Network Zones

| Zone | VLAN | Subnet | Purpose |
|------|------|--------|---------|
| Management | 100 | 10.10.0.0/24 | Corporate IT, AD, SIEM |
| DMZ | 110 | 10.10.1.0/24 | WALLIX, HAProxy, FortiAuthenticator |
| Servers | 120 | 10.10.2.0/24 | Windows Server, RHEL targets |

---

## VM Inventory

### Management Zone - 10.10.0.0/24

| VM Name | IP Address | OS | Purpose | Resources |
|---------|------------|-----|---------|-----------|
| `dc-lab` | 10.10.0.10 | Windows Server 2022 | Active Directory | 2 vCPU, 4GB RAM, 60GB |
| `siem-lab` | 10.10.0.50 | Ubuntu 22.04 | SIEM/SOC (Wazuh) | 4 vCPU, 16GB RAM, 500GB |

### DMZ Zone - 10.10.1.0/24

| VM Name | IP Address | OS | Purpose | Resources |
|---------|------------|-----|---------|-----------|
| `haproxy-1` | 10.10.1.5 | Debian 12 | HAProxy LB Primary | 2 vCPU, 4GB RAM, 20GB |
| `haproxy-2` | 10.10.1.6 | Debian 12 | HAProxy LB Secondary | 2 vCPU, 4GB RAM, 20GB |
| `wallix-node1` | 10.10.1.11 | Debian 12 | WALLIX Bastion Primary | 4 vCPU, 16GB RAM, 200GB |
| `wallix-node2` | 10.10.1.12 | Debian 12 | WALLIX Bastion Secondary | 4 vCPU, 16GB RAM, 200GB |
| `wallix-rds` | 10.10.1.30 | Windows Server 2022 | WALLIX RDS Session Manager | 4 vCPU, 8GB RAM, 100GB |
| `fortiauth` | 10.10.1.50 | FortiAuthenticator | MFA Server (RADIUS/FortiToken) | 2 vCPU, 4GB RAM, 40GB |
| `monitor-lab` | 10.10.1.60 | Ubuntu 22.04 | Prometheus/Grafana | 2 vCPU, 8GB RAM, 100GB |

### Server Zone - 10.10.2.0/24

| VM Name | IP Address | OS | Purpose | Resources |
|---------|------------|-----|---------|-----------|
| `win-srv-01` | 10.10.2.10 | Windows Server 2022 | General Windows target | 2 vCPU, 8GB RAM, 60GB |
| `win-srv-02` | 10.10.2.11 | Windows Server 2022 | SQL Server target | 4 vCPU, 16GB RAM, 100GB |
| `rhel10-srv` | 10.10.2.20 | RHEL 10 | Linux application server | 2 vCPU, 4GB RAM, 40GB |
| `rhel9-srv` | 10.10.2.21 | RHEL 9 | Legacy Linux server | 2 vCPU, 4GB RAM, 40GB |

### VIPs and Floating IPs

| VIP | Purpose | Nodes |
|-----|---------|-------|
| `10.10.1.100` | WALLIX Cluster VIP | haproxy-1, haproxy-2 |
| `10.10.1.101` | Internal cluster VIP | wallix-node1, wallix-node2 |

**Total VMs**: 13 (minimum for realistic enterprise lab with MFA and RDS)

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
| 8 | [HA Active-Active Configuration](./08-ha-active-active.md) | 2 hours |
| 9 | [Test Targets Setup](./09-test-targets.md) | 2 hours |
| 10 | [SIEM Integration](./10-siem-integration.md) | 2 hours |
| 11 | [Observability Stack](./11-observability.md) | 2 hours |
| 12 | [Validation & Testing](./12-validation-testing.md) | 2 hours |
| 13 | [Team Handoff Guides](./13-team-handoffs.md) | - |
| 14 | [Battery Tests (Client Demos)](./14-battery-tests.md) | 4 hours |

**Total Estimated Time**: ~24 hours (3 days)

---

## Network Requirements

### Firewall Rules

```
+===============================================================================+
|  FIREWALL RULES                                                               |
+===============================================================================+

MANAGEMENT <-> DMZ
---------------------------------
| Users           | VIP (10.10.1.100) | 443       | Web UI (HTTPS)              |
| Users           | VIP (10.10.1.100) | 22        | SSH Proxy                   |
| Users           | VIP (10.10.1.100) | 3389      | RDP Proxy                   |
| WALLIX nodes    | dc-lab (L4)       | 636       | LDAPS                       |
| WALLIX nodes    | dc-lab (L4)       | 88        | Kerberos                    |
| WALLIX nodes    | siem-lab (L4)     | 514/6514  | Syslog                      |
| WALLIX nodes    | fortiauth         | 1812/1813 | RADIUS MFA                  |

DMZ INTERNAL
----------------------
| haproxy-1/2     | wallix-node1/2    | 443,22    | Load balanced traffic       |
| wallix-node1    | wallix-node2      | 3306      | MariaDB replication         |
| wallix-node1    | wallix-node2      | 5404-5406 | Corosync cluster            |
| haproxy-1       | haproxy-2         | 8405      | VRRP/Keepalived             |
| monitor-lab     | WALLIX nodes      | 9100      | Prometheus metrics          |

DMZ <-> SERVERS
-------------------------------
| WALLIX          | win-srv-*         | 3389      | RDP to Windows              |
| WALLIX          | win-srv-*         | 5985/5986 | WinRM                       |
| WALLIX          | rhel*-srv         | 22        | SSH to Linux                |

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
- [ ] WALLIX HA cluster operational
- [ ] VIP failover tested
- [ ] AD authentication working
- [ ] FortiAuthenticator MFA working
- [ ] Basic session management functional

### Phase 2: Integration
- [ ] SIEM receiving logs
- [ ] Prometheus scraping metrics
- [ ] Grafana dashboards operational
- [ ] Alerts configured

### Phase 3: Testing
- [ ] SSH session through WALLIX
- [ ] RDP session through WALLIX with RDS
- [ ] Password rotation tested
- [ ] Session recording verified
- [ ] Failover tested

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
├── 01-infrastructure-setup.md           # VM provisioning
├── 02-active-directory-setup.md         # AD configuration
├── 03-haproxy-setup.md                  # HAProxy LB with Keepalived
├── 04-fortiauthenticator-setup.md       # FortiAuth MFA configuration
├── 05-wallix-rds-setup.md               # WALLIX RDS Session Manager
├── 06-ad-integration.md                 # LDAP/Kerberos/MFA integration
├── 08-ha-active-active.md               # HA cluster setup
├── 09-test-targets.md                   # Windows/RHEL test VMs setup
├── 10-siem-integration.md               # Wazuh setup
├── 11-observability.md                  # Prometheus/Grafana
├── 12-validation-testing.md             # Test procedures
├── 13-team-handoffs.md                  # Team documentation
└── 14-battery-tests.md                  # Client demo test suite
```

---

<p align="center">
  <a href="./01-infrastructure-setup.md">Start: Infrastructure Setup →</a>
</p>
