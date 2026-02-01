# Pre-Production Lab Environment

## WALLIX PAM4OT Lab for Testing, Learning, and Team Integration

This guide covers setting up a pre-production environment that **closely mirrors a real OT/Industrial environment** following the Purdue Model and IEC 62443 zone architecture.

### Lab Features
- 2x WALLIX PAM4OT nodes in Active-Active HA with HAProxy LB
- 2x HAProxy load balancers in HA with Keepalived VIP
- 1x WALLIX RDS Session Manager for RDP session management
- 1x FortiAuthenticator for MFA (RADIUS/TOTP)
- Full Purdue Model zones (Levels 0-4)
- Industrial protocol simulators (Modbus, DNP3, OPC UA, S7, EtherNet/IP)
- PLCs, RTUs, HMIs, SCADA, Historians
- Engineering Workstations
- Vendor remote access scenarios
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
| **Storage** | VMFS or NFS datastore with at least 2TB available space |
| **Network** | Distributed vSwitch preferred, Standard vSwitch acceptable |
| **Templates** | Debian 12 OVA template recommended for rapid deployment |

### Hardware Resources (Total)

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| **CPU** | 48 vCPU | 64 vCPU |
| **RAM** | 128 GB | 192 GB |
| **Storage** | 1.5 TB | 2 TB |
| **Network** | 1 Gbps | 10 Gbps |

### Network Configuration

- 6 VLANs configured on vSwitch (Enterprise, OT DMZ, Site Ops, Area Supervisory, Basic Control, Process)
- Port groups created for each VLAN with appropriate security policies
- Network connectivity to corporate Active Directory and DNS
- Internet access for downloading software packages (can be restricted post-deployment)

---

## Architecture Overview - Purdue Model

```
+===============================================================================+
|                    PRE-PRODUCTION LAB - PURDUE MODEL ARCHITECTURE             |
+===============================================================================+

  LEVEL 4/5 - ENTERPRISE/DMZ (10.10.0.0/24)
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
  ----------------------------- FIREWALL L4/L3 -----------------------------
                                     |
  LEVEL 3.5 - OT DMZ (10.10.1.0/24)
  ==================================
                 +-----------+               +-----------+
                 |  HAProxy  |               |  HAProxy  |
                 |    LB-1   |<-- VRRP HA -->|    LB-2   |
                 |10.10.1.5  |               |10.10.1.6  |
                 +-----------+               +-----------+
                       |      VIP: 10.10.1.100     |
                       +-------------+-------------+
                                     |
                 +-----------+               +-----------+
                 |  PAM4OT   |               |  PAM4OT   |
                 |  NODE-1   |<-- HA Sync -->|  NODE-2   |
                 |10.10.1.11 |               |10.10.1.12 |
                 +-----------+               +-----------+
                       |                           |
       +---------------+---------------+-----------+----------+
       |               |               |           |          |
  +-----------+  +-----------+  +-----------+ +-----------+ +-----------+
  | Historian |  |WALLIX RDS |  |FortiAuth  | |   SIEM    | | Monitoring|
  | (PI/OSI)  |  | Session   |  |   (MFA)   | | (Wazuh)   | |Prometheus |
  |10.10.1.20 |  |   Mgr     |  |10.10.1.50 | |10.10.0.50 | |10.10.1.60 |
  +-----------+  |10.10.1.30 |  +-----------+ +-----------+ +-----------+
                 +-----------+
                                     |
  ----------------------------- FIREWALL L3/L2 -----------------------------
                                     |
  LEVEL 3 - SITE OPERATIONS (10.10.2.0/24)
  =========================================
       +-----------+-----------+-----------+-----------+
       |           |           |           |           |
  +---------+ +---------+ +---------+ +---------+
  |  SCADA  | | Eng WS  | | Windows | |  Linux  |
  |  Server | | (HMI)   | | Server  | | Jump    |
  |10.10.2.10|10.10.2.20|10.10.2.30|10.10.2.40|
  +---------+ +---------+ +---------+ +---------+
                                     |
  ----------------------------- FIREWALL L2/L1 -----------------------------
                                     |
  LEVEL 2 - AREA SUPERVISORY (10.10.3.0/24)
  ==========================================
       +-----------+-----------+-----------+-----------+
       |           |           |           |           |
  +---------+ +---------+ +---------+ +---------+
  |   HMI   | |   HMI   | | Network | |  OPC UA |
  | Panel 1 | | Panel 2 | | Switch  | |  Server |
  |10.10.3.10|10.10.3.11|10.10.3.1 |10.10.3.20|
  +---------+ +---------+ +---------+ +---------+
                                     |
  ----------------------------- FIREWALL L1/L0 -----------------------------
                                     |
  LEVEL 1 - BASIC CONTROL (10.10.4.0/24)
  =======================================
       +-----------+-----------+-----------+-----------+
       |           |           |           |           |
  +---------+ +---------+ +---------+ +---------+
  |  PLC-1  | |  PLC-2  | |  RTU-1  | |  RTU-2  |
  | Modbus  | | S7comm  | |  DNP3   | |  DNP3   |
  |10.10.4.10|10.10.4.11|10.10.4.20|10.10.4.21|
  +---------+ +---------+ +---------+ +---------+
                                     |
  LEVEL 0 - PROCESS (10.10.5.0/24) - Field Devices
  =================================================
       +-----------+-----------+-----------+-----------+
       |           |           |           |           |
  +---------+ +---------+ +---------+ +---------+
  | Sensors | | Sensors | | Actuator| | Actuator|
  | (I/O)   | | (Analog)| | (Valve) | | (Motor) |
  |10.10.5.x|10.10.5.x |10.10.5.x |10.10.5.x |
  +---------+ +---------+ +---------+ +---------+

+===============================================================================+
```

---

## Network Zones (IEC 62443 / Purdue Model)

| Zone | VLAN | Subnet | Purdue Level | Purpose |
|------|------|--------|--------------|---------|
| Enterprise | 100 | 10.10.0.0/24 | L4/L5 | Corporate IT, AD, SIEM |
| OT DMZ | 110 | 10.10.1.0/24 | L3.5 | PAM4OT, HAProxy, Historian |
| Site Operations | 120 | 10.10.2.0/24 | L3 | SCADA, Engineering WS |
| Area Supervisory | 130 | 10.10.3.0/24 | L2 | HMI Panels, OPC UA |
| Basic Control | 140 | 10.10.4.0/24 | L1 | PLCs, RTUs |
| Process | 150 | 10.10.5.0/24 | L0 | Field devices (simulated) |

---

## VM Inventory

### Enterprise Zone (L4/L5) - 10.10.0.0/24

| VM Name | IP Address | OS | Purpose | Resources |
|---------|------------|-----|---------|-----------|
| `dc-lab` | 10.10.0.10 | Windows Server 2022 | Active Directory | 2 vCPU, 4GB RAM, 60GB |
| `siem-lab` | 10.10.0.50 | Ubuntu 22.04 | SIEM/SOC (Splunk/Wazuh) | 4 vCPU, 16GB RAM, 500GB |
| `vendor-jump` | 10.10.0.60 | Windows 10 | Vendor access workstation | 2 vCPU, 8GB RAM, 60GB |

### OT DMZ Zone (L3.5) - 10.10.1.0/24

| VM Name | IP Address | OS | Purpose | Resources |
|---------|------------|-----|---------|-----------|
| `haproxy-1` | 10.10.1.5 | Debian 12 | HAProxy LB Primary | 2 vCPU, 4GB RAM, 20GB |
| `haproxy-2` | 10.10.1.6 | Debian 12 | HAProxy LB Secondary | 2 vCPU, 4GB RAM, 20GB |
| `pam4ot-node1` | 10.10.1.11 | Debian 12 | PAM4OT Primary | 4 vCPU, 16GB RAM, 200GB |
| `pam4ot-node2` | 10.10.1.12 | Debian 12 | PAM4OT Secondary | 4 vCPU, 16GB RAM, 200GB |
| `historian` | 10.10.1.20 | Windows Server 2022 | OSIsoft PI / Historian | 4 vCPU, 16GB RAM, 200GB |
| `wallix-rds` | 10.10.1.30 | Windows Server 2022 | WALLIX RDS Session Manager | 4 vCPU, 8GB RAM, 100GB |
| `fortiauth` | 10.10.1.50 | FortiAuthenticator | MFA Server (RADIUS/TOTP) | 2 vCPU, 4GB RAM, 40GB |
| `monitor-lab` | 10.10.1.60 | Ubuntu 22.04 | Prometheus/Grafana | 2 vCPU, 8GB RAM, 100GB |

### Site Operations (L3) - 10.10.2.0/24

| VM Name | IP Address | OS | Purpose | Resources |
|---------|------------|-----|---------|-----------|
| `scada-server` | 10.10.2.10 | Windows Server 2022 | SCADA Server (Ignition) | 4 vCPU, 16GB RAM, 100GB |
| `eng-workstation` | 10.10.2.20 | Windows 10 | Engineering WS (TIA Portal) | 4 vCPU, 16GB RAM, 100GB |
| `windows-server` | 10.10.2.30 | Windows Server 2022 | General Windows target | 2 vCPU, 8GB RAM, 60GB |
| `linux-jump` | 10.10.2.40 | Ubuntu 22.04 | Linux jump server | 2 vCPU, 4GB RAM, 40GB |

### Area Supervisory (L2) - 10.10.3.0/24

| VM Name | IP Address | OS | Purpose | Resources |
|---------|------------|-----|---------|-----------|
| `hmi-panel-1` | 10.10.3.10 | Windows 10 IoT | HMI Operator Panel 1 | 2 vCPU, 4GB RAM, 40GB |
| `hmi-panel-2` | 10.10.3.11 | Windows 10 IoT | HMI Operator Panel 2 | 2 vCPU, 4GB RAM, 40GB |
| `opcua-server` | 10.10.3.20 | Ubuntu 22.04 | OPC UA Gateway | 2 vCPU, 4GB RAM, 40GB |
| `network-switch` | 10.10.3.1 | VyOS | Managed Industrial Switch | 1 vCPU, 2GB RAM, 20GB |

### Basic Control (L1) - 10.10.4.0/24

| VM Name | IP Address | OS | Purpose | Resources |
|---------|------------|-----|---------|-----------|
| `plc-modbus` | 10.10.4.10 | Ubuntu + OpenPLC | PLC Simulator (Modbus TCP) | 1 vCPU, 2GB RAM, 20GB |
| `plc-s7` | 10.10.4.11 | Ubuntu + Snap7 | PLC Simulator (S7comm) | 1 vCPU, 2GB RAM, 20GB |
| `rtu-dnp3-1` | 10.10.4.20 | Ubuntu + OpenDNP3 | RTU Simulator (DNP3) | 1 vCPU, 2GB RAM, 20GB |
| `rtu-dnp3-2` | 10.10.4.21 | Ubuntu + OpenDNP3 | RTU Simulator (DNP3) | 1 vCPU, 2GB RAM, 20GB |
| `plc-ethernetip` | 10.10.4.30 | Ubuntu | PLC Simulator (EtherNet/IP) | 1 vCPU, 2GB RAM, 20GB |

### VIPs and Floating IPs

| VIP | Purpose | Nodes |
|-----|---------|-------|
| `10.10.1.100` | PAM4OT Cluster VIP | haproxy-1, haproxy-2 |
| `10.10.1.101` | Internal cluster VIP | pam4ot-node1, pam4ot-node2 |

**Total VMs**: 24 (minimum for realistic OT lab with MFA and RDS)

---

## VMware Deployment Workflow

### Recommended Deployment Approach

For VMware vSphere/ESXi environments, we recommend the following workflow:

**1. Prepare VMware Environment**
- Create VLANs and port groups on Distributed vSwitch or Standard vSwitch
- Create VM folder structure (PAM4OT > Production)
- Prepare Debian 12 and Ubuntu 22.04 templates
- Ensure datastore has sufficient space (2TB+)

**2. Automated Deployment (Recommended)**
- Use Terraform with vSphere provider for VM provisioning
- Refer to `scripts/provision-vms.sh` for complete Terraform configuration
- Leverage OVA/OVF templates for rapid deployment
- Use cloud-init for automated OS configuration

**3. Manual Deployment (Alternative)**
- Deploy VMs via vCenter Web UI
- Use govc CLI for scriptable deployments
- Use PowerCLI for Windows-based automation

**4. VMware-Specific Optimizations**
- Use VMXNET3 network adapters for better performance
- Enable VMware Paravirtual SCSI controllers
- Configure VM anti-affinity rules for HA nodes
- Enable CPU and memory hot-add for flexibility
- Configure VM snapshots before major changes

### VMware HA Considerations

For production-like HA testing:

```
1. Create DRS anti-affinity rule for PAM4OT nodes
   - pam4ot-node1 and pam4ot-node2 should run on different ESXi hosts

2. Enable vSphere HA with:
   - Host Failure Response: Restart VMs
   - VM Monitoring: Enabled
   - VM Restart Priority: High (for PAM4OT nodes)

3. Configure vMotion network for live migrations

4. Test failover scenarios:
   - ESXi host failure
   - Network failure
   - Storage failure
```

### Creating Debian 12 Template for VMware

```bash
# Deploy Debian 12 ISO to vSphere
# Install with minimal packages
# After installation:

# Install VMware Tools (open-vm-tools)
apt update
apt install -y open-vm-tools cloud-init qemu-guest-agent

# Clean up
apt clean
rm -rf /tmp/*
history -c

# Shutdown and convert to template
shutdown -h now

# In vCenter: Right-click VM > Template > Convert to Template
```

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
| 7 | [PAM4OT Node Installation](./07-pam4ot-installation.md) | 2 hours |
| 8 | [HA Active-Active Configuration](./08-ha-active-active.md) | 2 hours |
| 9 | [OT Targets Setup](./09-test-targets.md) | 3 hours |
| 10 | [SIEM Integration](./10-siem-integration.md) | 2 hours |
| 11 | [Observability Stack](./11-observability.md) | 2 hours |
| 12 | [Validation & Testing](./12-validation-testing.md) | 2 hours |
| 13 | [Team Handoff Guides](./13-team-handoffs.md) | - |
| 14 | [Battery Tests (Client Demos)](./14-battery-tests.md) | 4 hours |

**Total Estimated Time**: ~26 hours (3-4 days)

---

## Network Requirements

### Inter-Zone Firewall Rules (IEC 62443 Compliant)

```
+===============================================================================+
|  FIREWALL RULES BY PURDUE LEVEL                                               |
+===============================================================================+

ENTERPRISE (L4) <-> OT DMZ (L3.5)
---------------------------------
| Users           | VIP (10.10.1.100) | 443       | Web UI (HTTPS)              |
| Users           | VIP (10.10.1.100) | 22        | SSH Proxy                   |
| Users           | VIP (10.10.1.100) | 3389      | RDP Proxy                   |
| PAM4OT nodes    | dc-lab (L4)       | 636       | LDAPS                       |
| PAM4OT nodes    | dc-lab (L4)       | 88        | Kerberos                    |
| PAM4OT nodes    | siem-lab (L4)     | 514/6514  | Syslog                      |
| Vendor-jump     | VIP               | 443       | Vendor remote access        |

OT DMZ (L3.5) INTERNAL
----------------------
| haproxy-1/2     | pam4ot-node1/2    | 443,22    | Load balanced traffic       |
| pam4ot-node1    | pam4ot-node2      | 3306/3307 | MariaDB replication         |
| pam4ot-node1    | pam4ot-node2      | 5404-5406 | Corosync cluster            |
| pam4ot-node1    | pam4ot-node2      | 2242      | SSH tunnel (replication)    |
| haproxy-1       | haproxy-2         | 8405      | VRRP/Keepalived             |
| monitor-lab     | PAM4OT nodes      | 9100      | Prometheus metrics          |

OT DMZ (L3.5) <-> SITE OPS (L3)
-------------------------------
| PAM4OT          | scada-server      | 3389      | RDP to SCADA                |
| PAM4OT          | eng-workstation   | 3389      | RDP to Eng WS               |
| PAM4OT          | linux-jump        | 22        | SSH to jump server          |
| historian       | scada-server      | 5020      | Historian data collection   |

SITE OPS (L3) <-> AREA (L2)
---------------------------
| scada-server    | hmi-panel-*       | 502       | Modbus to HMI               |
| scada-server    | opcua-server      | 4840      | OPC UA                      |
| eng-workstation | hmi-panel-*       | 3389      | RDP to HMI                  |
| PAM4OT (via L3) | hmi-panel-*       | 3389,22   | Proxied access              |

AREA (L2) <-> CONTROL (L1)
--------------------------
| opcua-server    | plc-*             | 502,102   | Modbus/S7 to PLCs           |
| opcua-server    | rtu-*             | 20000     | DNP3 to RTUs                |
| hmi-panel-*     | plc-*             | 502       | Modbus to PLCs              |
| PAM4OT (via L2) | plc-*,rtu-*       | 22        | SSH maintenance             |

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
├── README.md                            # This file
├── 01-infrastructure-setup.md           # VM provisioning
├── 02-active-directory-setup.md         # AD configuration
├── 03-haproxy-setup.md                  # HAProxy LB with Keepalived
├── 04-fortiauthenticator-setup.md       # FortiAuth MFA configuration
├── 05-wallix-rds-setup.md               # WALLIX RDS Session Manager
├── 06-ad-integration.md                 # LDAP/Kerberos/MFA integration
├── 07-pam4ot-installation.md            # PAM4OT base install
├── 08-ha-active-active.md               # HA cluster setup
├── 09-test-targets.md                   # Test VMs setup
├── 10-siem-integration.md               # Splunk/Wazuh setup
├── 11-observability.md                  # Prometheus/Grafana
├── 12-validation-testing.md             # Test procedures
├── 13-team-handoffs.md                  # Team documentation
├── 14-battery-tests.md                  # Client demo test suite
└── scripts/                             # Automation scripts
    ├── provision-vms.sh
    ├── setup-ad.ps1
    └── test-suite.sh
```

---

<p align="center">
  <a href="./01-infrastructure-setup.md">Start: Infrastructure Setup →</a>
</p>
