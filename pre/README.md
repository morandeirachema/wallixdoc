# Pre-Production Lab Environment

## WALLIX PAM4OT Lab for Testing, Learning, and Team Integration

This guide covers setting up a pre-production environment with:
- 2x WALLIX PAM4OT nodes in Active-Active HA
- Active Directory integration
- SIEM integration
- Observability/monitoring stack
- Test VMs for validation

---

## Architecture Overview

```
+===============================================================================+
|                      PRE-PRODUCTION LAB ARCHITECTURE                          |
+===============================================================================+

                              CORPORATE NETWORK
                                     |
                       +-------------+-------------+
                       |                           |
                 +-----------+               +-----------+
                 |    AD     |               |   SIEM    |
                 |  DC-LAB   |               | SPLUNK/ELK|
                 |10.10.1.10 |               |10.10.1.50 |
                 +-----------+               +-----------+

                       +-------------+-------------+
                       |      VIP: 10.10.1.100     |
                       |                           |
                 +-----------+               +-----------+
                 |  PAM4OT   |               |  PAM4OT   |
                 |  NODE-1   |<-- HA Sync -->|  NODE-2   |
                 |10.10.1.11 |               |10.10.1.12 |
                 +-----------+               +-----------+
                       |                           |
                       +-------------+-------------+
                                     |
       +-----------+-----------+-----------+-----------+-----------+
       |           |           |           |           |           |
       v           v           v           v           v           v
  +---------+ +---------+ +---------+ +---------+ +---------+
  | Linux   | | Windows | | Network | | OT SIM  | | Monitor |
  | Test VM | | Test VM | | Device  | | (PLC)   | | Stack   |
  |10.10.2.10 |10.10.2.20 |10.10.2.30 |10.10.3.10 |10.10.1.60
  +---------+ +---------+ +---------+ +---------+ +---------+

  NETWORK SEGMENTS:
  - 10.10.1.0/24 = Management/Infrastructure
  - 10.10.2.0/24 = IT Test Targets
  - 10.10.3.0/24 = OT Test Targets (isolated)

+===============================================================================+
```

---

## VM Inventory

| VM Name | IP Address | OS | Purpose | Resources |
|---------|------------|-----|---------|-----------|
| `dc-lab` | 10.10.1.10 | Windows Server 2022 | Active Directory | 2 vCPU, 4GB RAM, 60GB |
| `pam4ot-node1` | 10.10.1.11 | Debian 12 | PAM4OT Primary | 4 vCPU, 16GB RAM, 200GB |
| `pam4ot-node2` | 10.10.1.12 | Debian 12 | PAM4OT Secondary | 4 vCPU, 16GB RAM, 200GB |
| `siem-lab` | 10.10.1.50 | Ubuntu 22.04 | Splunk/ELK Stack | 4 vCPU, 16GB RAM, 500GB |
| `monitor-lab` | 10.10.1.60 | Ubuntu 22.04 | Prometheus/Grafana | 2 vCPU, 8GB RAM, 100GB |
| `linux-test` | 10.10.2.10 | Ubuntu 22.04 | SSH Target | 2 vCPU, 4GB RAM, 40GB |
| `windows-test` | 10.10.2.20 | Windows Server 2022 | RDP Target | 2 vCPU, 8GB RAM, 60GB |
| `network-test` | 10.10.2.30 | VyOS/pfSense | Network Device | 1 vCPU, 2GB RAM, 20GB |
| `plc-sim` | 10.10.3.10 | Linux | OT/PLC Simulator | 1 vCPU, 2GB RAM, 20GB |

**VIP (Virtual IP)**: 10.10.1.100 (floats between PAM4OT nodes)

---

## Quick Start

| Step | Document | Time |
|------|----------|------|
| 1 | [Infrastructure Setup](./01-infrastructure-setup.md) | 2 hours |
| 2 | [Active Directory Setup](./02-active-directory-setup.md) | 1 hour |
| 3 | [PAM4OT Node Installation](./03-pam4ot-installation.md) | 2 hours |
| 4 | [HA Active-Active Configuration](./04-ha-active-active.md) | 2 hours |
| 5 | [AD Integration](./05-ad-integration.md) | 1 hour |
| 6 | [Test Targets Setup](./06-test-targets.md) | 1 hour |
| 7 | [SIEM Integration](./07-siem-integration.md) | 2 hours |
| 8 | [Observability Stack](./08-observability.md) | 2 hours |
| 9 | [Validation & Testing](./09-validation-testing.md) | 2 hours |
| 10 | [Team Handoff Guides](./10-team-handoffs.md) | - |

**Total Estimated Time**: ~15 hours

---

## Network Requirements

### Firewall Rules

```
+===============================================================================+
| SOURCE          | DESTINATION       | PORT      | PURPOSE                      |
+===============================================================================+
| Users           | VIP (10.10.1.100) | 443       | Web UI                       |
| Users           | VIP (10.10.1.100) | 22        | SSH Proxy                    |
| Users           | VIP (10.10.1.100) | 3389      | RDP Proxy                    |
| PAM4OT nodes    | dc-lab            | 636       | LDAPS                        |
| PAM4OT nodes    | dc-lab            | 88        | Kerberos                     |
| PAM4OT nodes    | siem-lab          | 514/6514  | Syslog                       |
| PAM4OT nodes    | Test targets      | 22,3389   | Session proxying             |
| pam4ot-node1    | pam4ot-node2      | 3306/3307 | MariaDB replication          |
| pam4ot-node1    | pam4ot-node2      | 5404-5406 | Corosync cluster             |
| monitor-lab     | PAM4OT nodes      | 9100      | Prometheus metrics           |
+===============================================================================+
```

---

## Credentials Reference (Lab Only)

> **WARNING**: Change all passwords before any production use!

| System | Username | Password | Purpose |
|--------|----------|----------|---------|
| AD Domain | Administrator | `LabAdmin123!` | Domain admin |
| AD Domain | wallix-svc | `WallixSvc123!` | LDAP bind account |
| PAM4OT | admin | `Pam4otAdmin123!` | Web UI admin |
| PAM4OT | wabadmin | `WabAdmin123!` | CLI admin |
| MariaDB | root | `DbAdmin123!` | Database |
| Linux Test | root | `LinuxRoot123!` | SSH target |
| Windows Test | Administrator | `WinAdmin123!` | RDP target |
| Splunk | admin | `SplunkAdmin123!` | SIEM admin |
| Grafana | admin | `GrafanaAdmin123!` | Monitoring |

---

## Team Integration Points

| Team | Integration | Documentation |
|------|-------------|---------------|
| **Networking** | Firewall rules, VLANs, VIP | [Network Handoff](./10-team-handoffs.md#networking) |
| **SIEM/Security** | Log forwarding, alerts | [SIEM Handoff](./10-team-handoffs.md#siem) |
| **Observability** | Metrics, dashboards | [Observability Handoff](./10-team-handoffs.md#observability) |
| **Identity/IAM** | AD groups, MFA | [IAM Handoff](./10-team-handoffs.md#identity) |
| **OT/Industrial** | Protocol testing, PLCs | [OT Handoff](./10-team-handoffs.md#ot) |

---

## Lab Objectives Checklist

### Phase 1: Core Platform
- [ ] PAM4OT HA cluster operational
- [ ] VIP failover tested
- [ ] AD authentication working
- [ ] Basic session management functional

### Phase 2: Integration
- [ ] SIEM receiving logs
- [ ] Prometheus scraping metrics
- [ ] Grafana dashboards operational
- [ ] Alerts configured

### Phase 3: Testing
- [ ] SSH session through PAM4OT
- [ ] RDP session through PAM4OT
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
├── README.md                      # This file
├── 01-infrastructure-setup.md     # VM provisioning
├── 02-active-directory-setup.md   # AD configuration
├── 03-pam4ot-installation.md      # PAM4OT base install
├── 04-ha-active-active.md         # HA cluster setup
├── 05-ad-integration.md           # LDAP/Kerberos config
├── 06-test-targets.md             # Test VMs setup
├── 07-siem-integration.md         # Splunk/ELK setup
├── 08-observability.md            # Prometheus/Grafana
├── 09-validation-testing.md       # Test procedures
├── 10-team-handoffs.md            # Team documentation
└── scripts/                       # Automation scripts
    ├── provision-vms.sh
    ├── setup-ad.ps1
    └── test-suite.sh
```

---

<p align="center">
  <a href="./01-infrastructure-setup.md">Start: Infrastructure Setup →</a>
</p>
