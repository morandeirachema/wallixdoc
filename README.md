# WALLIX Bastion + FortiAuthenticator MFA

<p align="center">
  <img src="https://www.wallix.com/wp-content/uploads/2021/03/wallix-logo.svg" alt="WALLIX" width="180"/>
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="https://upload.wikimedia.org/wikipedia/commons/6/62/Fortinet_logo.svg" alt="Fortinet" width="180"/>
</p>

<p align="center">
  <strong>Enterprise Privileged Access Management</strong><br/>
  <em>4-Site Synchronized Architecture with Fortinet MFA Integration</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/WALLIX_Bastion-12.1.x-0066cc?style=for-the-badge" alt="WALLIX"/>
  <img src="https://img.shields.io/badge/FortiAuthenticator-6.4+-ee3124?style=for-the-badge" alt="FortiAuth"/>
  <img src="https://img.shields.io/badge/ISO_27001-Compliant-228b22?style=for-the-badge" alt="ISO"/>
</p>

---

## Project Overview

This repository contains comprehensive documentation for deploying **WALLIX Bastion PAM** with **FortiAuthenticator MFA** in a 4-site synchronized enterprise architecture.

| Aspect | Details |
|--------|---------|
| **Solution** | Privileged Access Management (PAM) |
| **Authentication** | FortiAuthenticator with FortiToken Mobile/Push |
| **Architecture** | 4 synchronized sites in single CPD |
| **High Availability** | Active-Active clustering per site |
| **Target Systems** | Windows Server 2022, RHEL 10, RHEL 9 |
| **Documentation** | 46 comprehensive sections |

---

## Architecture

```
+===============================================================================+
|                     4-SITE SYNCHRONIZED ARCHITECTURE                          |
+===============================================================================+
|                                                                               |
|                          +--------------------+                               |
|                          |  FortiAuthenticator |                              |
|                          |    (HW Appliance)   |                              |
|                          |     RADIUS MFA      |                              |
|                          +---------+----------+                               |
|                                    |                                          |
|         +------------+-------------+-------------+------------+               |
|         |            |             |             |            |               |
|    +----v----+  +----v----+  +----v----+  +----v----+                         |
|    |  Site 1 |  |  Site 2 |  |  Site 3 |  |  Site 4 |                         |
|    +---------+  +---------+  +---------+  +---------+                         |
|                                                                               |
|    Each Site:                                                                 |
|    +-----------------------------------------------------------------------+  |
|    |  Fortigate FW --> HAProxy (2x HA) --> WALLIX (2x HA) --> WALLIX RDS   |  |
|    +-----------------------------------------------------------------------+  |
|                                    |                                          |
|                          +---------v----------+                               |
|                          |   Target Systems   |                               |
|                          | Windows Server 2022|                               |
|                          |  RHEL 10 / RHEL 9  |                               |
|                          +--------------------+                               |
|                                                                               |
+===============================================================================+
```

### Component Stack

| Layer | Component | Type | Quantity/Site |
|-------|-----------|------|---------------|
| **MFA** | FortiAuthenticator | HW Appliance | 1 (shared) |
| **Firewall** | Fortigate | HW Appliance | 1 |
| **Load Balancer** | HAProxy + Keepalived | VM | 2 (HA pair) |
| **PAM** | WALLIX Bastion | HW Appliance | 2 (HA pair) |
| **RDP Gateway** | WALLIX RDS | VM | 1 |
| **Targets** | Windows/RHEL | VM | N |

---

## Quick Start

| Step | Description | Link |
|:----:|-------------|------|
| **1** | Review architecture and requirements | [Architecture](./docs/pam/03-architecture/README.md) |
| **2** | Set up pre-production lab | [Lab Guide](./pre/README.md) |
| **3** | Configure FortiAuthenticator MFA | [FortiAuth Setup](./pre/04-fortiauthenticator-setup.md) |
| **4** | Deploy WALLIX Bastion | [Installation](./install/HOWTO.md) |
| **5** | Integrate with Active Directory | [AD Integration](./docs/pam/34-ldap-ad-integration/README.md) |
| **6** | Configure Fortigate integration | [Fortigate MFA](./docs/pam/46-fortigate-integration/README.md) |

---

## Documentation Structure

```
wallixdoc/
├── docs/pam/                    # 46 PAM Documentation Sections
│   ├── 00-05   Getting Started
│   ├── 06-09   Authentication & Sessions
│   ├── 10-14   API, HA & Operations
│   ├── 15-25   Reference & Compliance
│   ├── 26-39   Infrastructure & Security
│   └── 40-46   Advanced Features & Fortigate
│
├── install/                     # Multi-Site Deployment Guides
│   ├── HOWTO.md                 # Complete installation walkthrough
│   └── 00-10 *.md               # Step-by-step procedures
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
| **Security Engineer** | [Authentication](./docs/pam/06-authentication/README.md) → [Fortigate MFA](./docs/pam/46-fortigate-integration/README.md) |
| **Network Engineer** | [Architecture Diagrams](./install/09-architecture-diagrams.md) → [Load Balancer](./docs/pam/32-load-balancer/README.md) |
| **Identity/IAM Team** | [AD Integration](./docs/pam/34-ldap-ad-integration/README.md) → [Kerberos](./docs/pam/35-kerberos-authentication/README.md) |
| **DevOps Engineer** | [API Reference](./docs/pam/17-api-reference/README.md) → [Ansible](./examples/ansible/README.md) |
| **Compliance Officer** | [Compliance Audit](./docs/pam/24-compliance-audit/README.md) → [Evidence](./docs/pam/37-compliance-evidence/README.md) |
| **Operations Team** | [Runbooks](./docs/pam/21-operational-runbooks/README.md) → [CLI Reference](./docs/pam/31-wabadmin-reference/README.md) |

---

## Key Capabilities

| Category | Features |
|----------|----------|
| **Authentication** | FortiToken Mobile/Push, LDAP/AD, Kerberos SSO, RADIUS |
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
| **FortiAuthenticator** | Version 6.4+ (HW Appliance) |
| **Operating System** | Debian 12 (Bookworm) |
| **Database** | MariaDB 10.11+ with streaming replication |
| **Clustering** | Pacemaker/Corosync |
| **Load Balancer** | HAProxy 2.x with Keepalived VRRP |
| **Encryption** | AES-256-GCM, TLS 1.3, LUKS |
| **Protocols** | SSH, RDP, WinRM, HTTPS |

### Network Ports

| Port | Service | Port | Service |
|:----:|---------|:----:|---------|
| 443 | HTTPS/Web UI | 22 | SSH Proxy |
| 3389 | RDP Proxy | 5985/5986 | WinRM |
| 636 | LDAPS | 88 | Kerberos |
| 1812/1813 | RADIUS | 3306 | MariaDB |

---

## Pre-Production Lab

Build a complete test environment before production deployment:

```
Lab Components
├── VMware vSphere/ESXi 8.0+
├── Active Directory Domain Controller
├── FortiAuthenticator (MFA)
├── HAProxy Load Balancers (2x HA)
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

### Advanced (33-46)

| # | Section | Description |
|:-:|---------|-------------|
| 33-39 | [Security](./docs/pam/34-ldap-ad-integration/README.md) | AD, Kerberos, command filtering |
| 40-45 | [Features](./docs/pam/40-account-discovery/README.md) | Discovery, SSH keys, self-service |
| 46 | [Fortigate](./docs/pam/46-fortigate-integration/README.md) | **FortiAuthenticator MFA integration** |

---

## Quick Commands

```bash
# Service Status
systemctl status wallix-bastion
wabadmin status

# Cluster Health
crm status
pcs status

# Database Replication
mysql -e "SHOW SLAVE STATUS\G"

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
  <strong>46 Documentation Sections</strong> ·
  <strong>4-Site Architecture</strong> ·
  <strong>FortiAuthenticator MFA</strong>
</p>

<p align="center">
  <sub>WALLIX Bastion 12.1.x · FortiAuthenticator 6.4+ · February 2026</sub>
</p>
