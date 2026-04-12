# WALLIX Bastion + FortiAuthenticator MFA

<p align="center">
  <strong>Enterprise Privileged Access Management</strong><br/>
  <em>5-Site Multi-Datacenter Architecture with Per-Site Fortinet MFA</em><br/><br/>
  <strong>WALLIX BASTION</strong> + <strong>FORTINET</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/WALLIX_Bastion-12.1.x-0066cc?style=for-the-badge" alt="WALLIX"/>
  <img src="https://img.shields.io/badge/FortiAuthenticator-6.4+-ee3124?style=for-the-badge" alt="FortiAuth"/>
  <img src="https://img.shields.io/badge/ISO_27001-Compliant-228b22?style=for-the-badge" alt="ISO"/>
</p>

---

## Project Overview

This repository contains comprehensive documentation for deploying **WALLIX Bastion PAM** with **FortiAuthenticator MFA** in a 5-site multi-datacenter enterprise architecture. Each site is fully autonomous, with its own HA FortiAuthenticator pair and Active Directory, connected to a client-managed Access Manager via MPLS.

| Aspect | Details |
|--------|---------|
| **Solution** | Privileged Access Management (PAM) |
| **Authentication** | Per-site FortiAuthenticator HA pair with FortiToken Mobile (TOTP) |
| **Architecture** | 5 independent sites via MPLS, 2 client-managed Access Managers (HA) |
| **VLAN Design** | DMZ VLAN (Bastion, HAProxy, RDS) + Cyber VLAN (FortiAuth, AD) per site |
| **High Availability** | Active-Active or Active-Passive per site |
| **Target Systems** | Windows Server 2022, RHEL 10, RHEL 9, OT (via RDS) |
| **Scale** | ~100-200 targets per site, ~25 privileged users per site |

---

## Architecture

```
+===============================================================================+
|  5-SITE ARCHITECTURE — DUAL VLAN PER SITE, CLIENT-MANAGED ACCESS MANAGER     |
+===============================================================================+
|                                                                               |
|  +----------------------+      +----------------------+                       |
|  | Access Manager 1     |      | Access Manager 2     |                       |
|  | (DC-A) — CLIENT HA   | HA   | (DC-B) — CLIENT HA   |                       |
|  | Session Brokering    |<---->| Session Brokering    |                       |
|  +----------+-----------+      +-----------+----------+                       |
|             |                              |                                  |
|             +-----------MPLS--------------+                                  |
|                              |                                                |
|      +----------+------------+------------+----------+                        |
|      |          |            |            |          |                        |
|  +---v---+  +---v---+    +---v---+    +---v---+  +---v---+                    |
|  | Site1 |  | Site2 |    | Site3 |    | Site4 |  | Site5 |                    |
|  +---+---+  +---+---+    +---+---+    +---+---+  +---+---+                    |
|      |                                                                        |
|  Per-site detail (identical at all 5 sites):                                  |
|  +--DMZ VLAN (10.10.X.0/25)---------------------------------------------+   |
|  |  HAProxy x2 (HA) --> WALLIX Bastion x2 (HA) --> RDS --> OT targets    |   |
|  +-----------------------------------------------------------------------+   |
|  +--Cyber VLAN (10.10.X.128/25)------------------------------------------+   |
|  |  FortiAuthenticator x2 (HA pair) + Active Directory DC               |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
|  NO direct Bastion-to-Bastion communication between sites                     |
+===============================================================================+
```

### Component Stack

| Layer | Component | Placement | Total |
|-------|-----------|-----------|-------|
| **Broker** | WALLIX Access Manager | Client DC-A / DC-B (HA) | 2 — client-managed |
| **MFA** | FortiAuthenticator HA pair | Cyber VLAN, per site | 10 (2 per site) |
| **Directory** | Active Directory DC | Cyber VLAN, per site | 5 (1 per site) |
| **Load Balancer** | HAProxy + Keepalived | DMZ VLAN, per site | 10 (2 per site) |
| **PAM** | WALLIX Bastion HW Appliance | DMZ VLAN, per site | 10 (2 per site) |
| **Jump Host** | WALLIX RDS | DMZ VLAN, per site | 5 (1 per site) |
| **Network** | MPLS | AM ↔ Sites | No direct site-to-site |

---

## Quick Start

| Step | Description | Link |
|:----:|-------------|------|
| **1** | Review architecture and requirements | [Architecture](./docs/pam/03-architecture/README.md) |
| **2** | Set up pre-production lab | [Lab Guide](./pre/README.md) |
| **3** | Deploy FortiAuthenticator HA per site | [FortiAuth HA](./install/03-fortiauthenticator-ha.md) |
| **4** | Integrate Active Directory per site | [AD per Site](./install/04-ad-per-site.md) |
| **5** | Deploy WALLIX Bastion | [Installation](./install/HOWTO.md) |
| **6** | Verify Access Manager connectivity (client team) | [AM Integration](./install/15-access-manager-integration.md) |

---

## Documentation Structure

```
wallixdoc/
├── docs/pam/                    # 48 PAM Documentation Sections
│   ├── 00-05   Getting Started
│   ├── 06-09   Authentication & Sessions
│   ├── 10-14   API, HA & Operations
│   ├── 15-25   Reference & Compliance
│   ├── 26-39   Infrastructure & Security
│   └── 40-48   Advanced Features, Access Manager & Licensing
│
├── install/                     # 5-Site Deployment Guides (18 files)
│   ├── HOWTO.md                 # Master 10-week installation walkthrough
│   ├── 00-prerequisites.md      # Hardware, network, VLAN, scale
│   ├── 01-network-design.md     # MPLS, DMZ/Cyber VLAN, port matrix
│   ├── 02-ha-architecture.md    # Active-Active vs Active-Passive
│   ├── 03-fortiauthenticator-ha.md  # Per-site FortiAuth HA pair setup
│   ├── 04-ad-per-site.md        # Per-site Active Directory integration
│   ├── 05-site-deployment.md    # Per-site deployment template
│   ├── 06-haproxy-setup.md      # HAProxy + Keepalived VRRP
│   ├── 07-bastion-active-active.md  # Master/Master cluster
│   ├── 08-bastion-active-passive.md # Master/Slave cluster
│   ├── 09-rds-jump-host.md      # WALLIX RDS for OT RemoteApp
│   ├── 10-licensing.md          # Bastion licensing (AM = client)
│   ├── 11-testing-validation.md # End-to-end test procedures
│   ├── 12-architecture-diagrams.md  # Network diagrams, port reference
│   ├── 13-contingency-plan.md   # DR, failover, business continuity
│   ├── 14-break-glass-procedures.md # Emergency access
│   └── 15-access-manager-integration.md # Bastion-side AM config only
│
├── pre/                         # Pre-Production Lab (14 guides)
│   ├── 01-infrastructure        # VMware vSphere/ESXi setup
│   ├── 04-fortiauthenticator    # MFA configuration
│   └── 09-test-targets          # Windows/RHEL setup
│
└── examples/                    # Automation
    ├── ansible/                 # Playbooks and roles
    ├── terraform/               # Infrastructure as Code
    └── api/                     # REST API samples
```

---

## Navigation by Role

| Role | Start Here |
|------|------------|
| **Project Manager** | [Introduction](./docs/pam/02-introduction/README.md) → [Architecture](./docs/pam/03-architecture/README.md) |
| **System Administrator** | [Installation](./install/README.md) → [Configuration](./docs/pam/05-configuration/README.md) |
| **Security Engineer** | [Authentication](./docs/pam/06-authentication/README.md) → [FortiAuth MFA](./docs/pam/06-authentication/fortiauthenticator-integration.md) |
| **Network Engineer** | [Architecture Diagrams](./install/12-architecture-diagrams.md) → [Load Balancer](./docs/pam/32-load-balancer/README.md) |
| **Identity/IAM Team** | [AD per Site](./install/04-ad-per-site.md) → [AD Integration](./docs/pam/34-ldap-ad-integration/README.md) |
| **DevOps Engineer** | [API Reference](./docs/pam/17-api-reference/README.md) → [Ansible](./examples/ansible/README.md) |
| **Compliance Officer** | [Compliance Audit](./docs/pam/24-compliance-audit/README.md) → [Evidence](./docs/pam/37-compliance-evidence/README.md) |
| **Operations Team** | [Runbooks](./docs/pam/21-operational-runbooks/README.md) → [CLI Reference](./docs/pam/31-wabadmin-reference/README.md) |

---

## Key Capabilities

| Category | Features |
|----------|----------|
| **Authentication** | FortiToken Mobile (TOTP), LDAP/AD per site, Kerberos SSO, RADIUS |
| **Session Control** | Video recording, OCR search, keystroke logging, real-time monitoring |
| **Password Vault** | AES-256 encryption, automatic rotation, credential checkout |
| **Access Control** | RBAC, approval workflows, JIT access, time-based restrictions |
| **High Availability** | Active-Active clustering, MariaDB replication, automatic failover |
| **Compliance** | ISO 27001, SOC 2, NIS2, PCI-DSS, HIPAA, GDPR |

---

## Technical Specifications

| Component | Specification |
|-----------|---------------|
| **WALLIX Bastion** | Version 12.1.x (HW Appliance) |
| **FortiAuthenticator** | Version 6.4+ (per-site HA pair) |
| **Active Directory** | Windows Server 2022 (per-site DC) |
| **Operating System** | Debian 12 (Bookworm) — Bastion/HAProxy |
| **Database** | MariaDB 10.11+ with streaming replication |
| **Clustering** | bastion-replication + Keepalived VRRP |
| **Load Balancer** | HAProxy 2.x (Active-Passive per site) |
| **Encryption** | AES-256-GCM, TLS 1.3, LUKS |
| **Protocols** | SSH, RDP, WinRM, HTTPS |

### Key Network Ports

| Port | Service | Port | Service |
|:----:|---------|:----:|---------|
| 443 | HTTPS / Web UI | 22 | SSH Proxy |
| 3389 | RDP Proxy | 5985/5986 | WinRM |
| 636 | LDAPS (Bastion → AD) | 389 | LDAP (FortiAuth → AD) |
| 1812/1813 | RADIUS (Bastion → FortiAuth) | 3306 | MariaDB replication |

---

## Pre-Production Lab

Build a complete test environment before production deployment:

```
Lab Components
├── VMware vSphere/ESXi 8.0+
├── Active Directory Domain Controller
├── FortiAuthenticator HA pair (MFA — TOTP)
├── HAProxy Load Balancers (2x Active-Passive)
├── WALLIX Bastion (2x Active-Active)
├── WALLIX RDS Session Manager
├── Windows Server 2022 (test target)
├── RHEL 10 Server (test target)
└── RHEL 9 Server (legacy target)
```

**[Start Lab Setup →](./pre/README.md)**

---

## Documentation Sections

### Core (00-14)

| # | Section | Description |
|:-:|---------|-------------|
| 00-05 | [Getting Started](./docs/pam/01-quick-start/README.md) | Introduction, architecture, configuration |
| 06-07 | [Authentication](./docs/pam/06-authentication/README.md) | MFA, authorization, access control |
| 08-09 | [Sessions & Passwords](./docs/pam/08-password-management/README.md) | Vault, recording, rotation |
| 10-14 | [Operations](./docs/pam/12-monitoring-observability/README.md) | API, HA, monitoring, troubleshooting |

### Reference (15-32)

| # | Section | Description |
|:-:|---------|-------------|
| 15-22 | [Reference](./docs/pam/17-api-reference/README.md) | API docs, CLI, runbooks, FAQ |
| 23-25 | [Compliance](./docs/pam/24-compliance-audit/README.md) | Audit, incident response, JIT access |
| 26-32 | [Infrastructure](./docs/pam/29-disaster-recovery/README.md) | DR, backup, certificates, load balancer |

### Advanced (33-48)

| # | Section | Description |
|:-:|---------|-------------|
| 33-39 | [Security](./docs/pam/34-ldap-ad-integration/README.md) | AD, Kerberos, command filtering |
| 40-45 | [Features](./docs/pam/40-account-discovery/README.md) | Discovery, SSH keys, self-service |
| 46-48 | [Access Manager & Licensing](./docs/pam/47-access-manager/README.md) | Access Manager, licensing, connectivity |

---

## Quick Commands

```bash
# Service Status
systemctl status wallix-bastion
wabadmin status

# Cluster Health
bastion-replication --status

# Database Replication
mysql -e "SHOW SLAVE STATUS\G"
mysql -e "SHOW MASTER STATUS\G"

# Audit Log
wabadmin audit --last 20

# License Info
wabadmin license-info
```

---

## Resources

| Resource | Link |
|----------|------|
| WALLIX Documentation | https://pam.wallix.one/documentation |
| WALLIX Support | https://support.wallix.com |
| Terraform Provider | https://registry.terraform.io/providers/wallix/wallix-bastion |
| REST API Samples | https://github.com/wallix/wbrest_samples |

---

<p align="center">
  <strong>48 Documentation Sections</strong> ·
  <strong>5-Site Architecture</strong> ·
  <strong>Per-Site FortiAuthenticator MFA</strong>
</p>

<p align="center">
  <sub>WALLIX Bastion 12.1.x · FortiAuthenticator 6.4+ · April 2026</sub>
</p>
