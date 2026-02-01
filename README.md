# WALLIX PAM4OT Documentation

<p align="center">
  <img src="https://www.wallix.com/wp-content/uploads/2021/03/wallix-logo.svg" alt="WALLIX Logo" width="200"/>
</p>

<p align="center">
  <strong>Privileged Access Management for Operational Technology</strong><br/>
  <em>Secure access to critical infrastructure with enterprise-grade PAM</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/PAM4OT-12.1.x-0066cc?style=flat-square" alt="Version"/>
  <img src="https://img.shields.io/badge/Debian-12-a80030?style=flat-square" alt="Debian"/>
  <img src="https://img.shields.io/badge/PostgreSQL-15+-336791?style=flat-square" alt="PostgreSQL"/>
  <img src="https://img.shields.io/badge/IEC_62443-Compliant-228b22?style=flat-square" alt="IEC 62443"/>
  <img src="https://img.shields.io/badge/NIST_800--82-Compliant-228b22?style=flat-square" alt="NIST"/>
</p>

---

## Overview

**PAM4OT** is WALLIX's unified privileged access management solution designed for OT/industrial environments. Built on WALLIX Bastion 12.x, it provides:

- **Secure Remote Access** - Controlled access to critical systems through a single gateway
- **Strong Authentication** - MFA with FIDO2, LDAP/AD, Kerberos, SAML/OIDC
- **Session Recording** - Full audit trail with video replay, OCR, and keystroke logging
- **Password Management** - Encrypted vault with automatic credential rotation
- **Industrial Protocol Support** - Native proxying for Modbus, DNP3, OPC UA, S7comm

---

## Documentation Structure

```
wallixdoc/
│
├── docs/                         # Technical Documentation (66 sections)
│   ├── pam/                      # PAM/WALLIX Core (47 sections, 00-46)
│   │   ├── 00-05  Getting Started & Configuration
│   │   ├── 06-09  Authentication, Authorization & Sessions
│   │   ├── 10-15  API, HA, Monitoring & Best Practices
│   │   ├── 16-24  Deployment, Operations & Compliance
│   │   ├── 25-32  JIT Access, Performance & Infrastructure
│   │   └── 33-46  Advanced Features & Security
│   │
│   └── ot/                       # OT Foundational (19 sections, 00-18)
│       ├── 00     OT Fundamentals (16-week learning path)
│       ├── 01-09  Overview, Architecture & Protocols
│       ├── 05-10  Air-Gapped & Offline Operations
│       ├── 06-08  Compliance & Integration
│       ├── 11-17  Vendor Access & Safety
│       └── 18     Training & Certifications
│
├── install/                      # Multi-Site Deployment
│   ├── HOWTO.md                  # Complete installation guide
│   └── 00-10-*.md                # Step-by-step procedures
│
├── pre/                          # Pre-Production Lab (14 guides)
│   ├── README.md                 # Lab overview and architecture
│   ├── 01-infrastructure-setup.md    # VMware vSphere/ESXi 8.0+
│   ├── 04-fortiauthenticator-setup.md # FortiAuthenticator MFA
│   ├── 05-wallix-rds-setup.md    # WALLIX RDS configuration
│   └── 01-14-*.md                # Complete lab setup
│
└── examples/                     # Automation Examples
    ├── ansible/                  # Ansible playbooks and roles
    ├── terraform/                # Infrastructure as Code
    └── api/                      # REST API samples (Python, curl)
```

---

## Quick Navigation

### By Role

| Role | Recommended Path |
|------|------------------|
| **New to PAM4OT** | [Introduction](./docs/pam/02-introduction/README.md) → [Architecture](./docs/pam/03-architecture/README.md) → [Core Components](./docs/pam/04-core-components/README.md) |
| **System Administrator** | [Installation](./install/README.md) → [Configuration](./docs/pam/05-configuration/README.md) → [Troubleshooting](./docs/pam/13-troubleshooting/README.md) |
| **Security Engineer** | [Authentication](./docs/pam/06-authentication/README.md) → [FIDO2 MFA](./docs/pam/40-fido2-hardware-mfa/README.md) → [Best Practices](./docs/pam/14-best-practices/README.md) → [Incident Response](./docs/pam/23-incident-response/README.md) |
| **OT/ICS Engineer** | [OT Fundamentals](./docs/ot/00-fundamentals/README.md) → [Industrial Overview](./docs/ot/01-industrial-overview/README.md) → [Protocols](./docs/ot/03-industrial-protocols/README.md) → [SCADA Access](./docs/ot/04-scada-ics-access/README.md) |
| **DevOps/Automation** | [API Reference](./docs/pam/17-api-reference/README.md) → [Deployment](./docs/pam/16-cloud-deployment/README.md) → [Ansible Examples](./examples/ansible/README.md) |
| **Compliance Officer** | [IEC 62443](./docs/ot/06-iec62443-compliance/README.md) → [Compliance Audit](./docs/pam/24-compliance-audit/README.md) → [Evidence Collection](./docs/pam/37-compliance-evidence/README.md) |

### By Team

| Team | Key Documents |
|------|---------------|
| **Networking** | [Architecture Diagrams](./install/09-architecture-diagrams.md) • [OT Architecture](./docs/ot/02-ot-architecture/README.md) • [Network Validation](./docs/pam/36-network-validation/README.md) |
| **Identity/IAM** | [Authentication](./docs/pam/06-authentication/README.md) • [LDAP/AD Integration](./docs/pam/34-ldap-ad-integration/README.md) • [Kerberos](./docs/pam/35-kerberos-authentication/README.md) • [FIDO2 MFA](./docs/pam/40-fido2-hardware-mfa/README.md) |
| **Security** | [Session Recording](./docs/pam/39-session-recording-playback/README.md) • [Incident Response](./docs/pam/23-incident-response/README.md) • [Command Filtering](./docs/pam/38-command-filtering/README.md) |
| **Infrastructure** | [High Availability](./docs/pam/11-high-availability/README.md) • [Backup & Restore](./docs/pam/30-backup-restore/README.md) • [Disaster Recovery](./docs/pam/29-disaster-recovery/README.md) • [Load Balancer](./docs/pam/32-load-balancer/README.md) |
| **OT/Industrial** | [Industrial Protocols](./docs/ot/03-industrial-protocols/README.md) • [OT Jump Host](./docs/ot/12-ot-jump-host/README.md) • [Vendor Remote Access](./docs/ot/11-vendor-remote-access/README.md) • [Engineering Workstation Access](./docs/ot/14-engineering-workstation-access/README.md) |
| **Operations** | [Operational Runbooks](./docs/pam/21-operational-runbooks/README.md) • [wabadmin CLI](./docs/pam/31-wabadmin-reference/README.md) • [Monitoring](./docs/pam/12-monitoring-observability/README.md) |

---

## Key Features

| Category | Capabilities |
|----------|-------------|
| **Authentication** | MFA (FIDO2/WebAuthn, TOTP, YubiKey, FortiAuthenticator), LDAP/AD, Kerberos SSO, OIDC/SAML, X.509 Certificates |
| **Authorization** | RBAC, approval workflows, time-based access, JIT privileged access |
| **Session Management** | Video recording, OCR search, real-time monitoring, keystroke logging, session sharing |
| **Password Management** | AES-256 encrypted vault, automatic rotation, SSH key lifecycle, credential checkout |
| **Industrial Protocols** | Modbus TCP, DNP3, OPC UA, EtherNet/IP, S7comm, IEC 61850 |
| **High Availability** | Active-Active clustering, PostgreSQL streaming replication, automatic failover |
| **OT Security** | Air-gapped operations, offline credential cache, safety procedure integration (LOTO, SIS) |

---

## Compliance Coverage

| Standard | Coverage | Standard | Coverage |
|----------|----------|----------|----------|
| **IEC 62443** | Full | **SOC 2 Type II** | Full |
| **NIST 800-82** | Full | **ISO 27001** | Full |
| **NIS2 Directive** | Full | **PCI-DSS** | Full |
| **NERC CIP** | Full | **HIPAA** | Full |

See [Compliance & Audit Guide](./docs/pam/24-compliance-audit/README.md) for detailed mapping.

---

## Technical Requirements

| Component | Specification |
|-----------|---------------|
| **Operating System** | Debian 12 (Bookworm) |
| **Database** | PostgreSQL 15+ with streaming replication |
| **Clustering** | Pacemaker/Corosync |
| **Encryption** | AES-256-GCM, TLS 1.3, LUKS disk encryption |
| **Key Derivation** | Argon2ID |
| **Deployment** | On-premises (bare metal, VMs) - No cloud/containers |
| **Hypervisor (Pre-Prod Lab)** | VMware vSphere/ESXi 8.0+ |

See [System Requirements](./docs/pam/19-system-requirements/README.md) for detailed sizing.

---

## Quick Reference

### Essential Commands

```bash
# Service Management
systemctl status wallix-bastion
wabadmin status

# Cluster Health
crm status
pcs status

# Database Replication
sudo -u postgres psql -c "SELECT * FROM pg_stat_replication;"

# License & Audit
wabadmin license-info
wabadmin audit --last 20
```

### Key Ports

| Port | Service | Port | Service |
|------|---------|------|---------|
| 443 | HTTPS/Web UI | 22 | SSH Proxy |
| 636 | LDAPS | 88 | Kerberos |
| 1812 | RADIUS (MFA) | 5432 | PostgreSQL |
| 514/6514 | Syslog | 502 | Modbus |

---

## Getting Started

### 1. Pre-Production Lab (Recommended)

Start with the [Pre-Production Lab Guide](./pre/README.md) to build a test environment:

```
Lab Environment
├── VMware vSphere/ESXi 8.0+ cluster
├── Active Directory domain controller
├── HAProxy load balancer (2x)
├── FortiAuthenticator MFA server
├── WALLIX Bastion (Active-Active HA)
├── WALLIX RDS (Remote Desktop Services)
└── Test targets (Linux, Windows, network devices)
```

### 2. Production Deployment

Follow the [Multi-Site Installation Guide](./install/README.md) for production:

```
Production Architecture
├── Site A: Primary HQ (Active-Active HA)
├── Site B: Secondary Plant (Active-Passive DR)
└── Site C: Remote Field (Standalone + Offline)
```

### 3. Automation

Explore [Examples](./examples/README.md) for automation:

- **Ansible** - Device provisioning, user management, health checks
- **Terraform** - Infrastructure as Code for resource management
- **Python API** - Custom integrations and scripting
- **curl Scripts** - Quick API operations

---

## Official Resources

| Resource | URL |
|----------|-----|
| Documentation Portal | https://pam.wallix.one/documentation |
| Support Portal | https://support.wallix.com |
| Terraform Provider | https://registry.terraform.io/providers/wallix/wallix-bastion |
| REST API Samples | https://github.com/wallix/wbrest_samples |
| WALLIX GitHub | https://github.com/wallix |

---

## PAM Core Documentation (docs/pam/)

### Getting Started

| Section | Description |
|---------|-------------|
| [00 - Official Resources](./docs/pam/00-official-resources/README.md) | Curated links to official WALLIX documentation |
| [01 - Quick Start](./docs/pam/01-quick-start/README.md) | Quick installation and configuration guide |
| [02 - Introduction](./docs/pam/02-introduction/README.md) | Company and product overview |
| [03 - Architecture](./docs/pam/03-architecture/README.md) | System architecture and deployment models |
| [04 - Core Components](./docs/pam/04-core-components/README.md) | Session Manager, Password Manager, Access Manager |
| [05 - Configuration](./docs/pam/05-configuration/README.md) | Object model, domains, devices, accounts |

### Security & Access Control

| Section | Description |
|---------|-------------|
| [06 - Authentication](./docs/pam/06-authentication/README.md) | MFA, SSO, LDAP/AD, Kerberos, OIDC/SAML, FortiAuthenticator |
| [07 - Authorization](./docs/pam/07-authorization/README.md) | RBAC, approval workflows, time windows |
| [25 - JIT Access](./docs/pam/25-jit-access/README.md) | Just-In-Time access, approval workflows |
| [34 - LDAP/AD Integration](./docs/pam/34-ldap-ad-integration/README.md) | Active Directory integration |
| [35 - Kerberos Authentication](./docs/pam/35-kerberos-authentication/README.md) | Kerberos, SPNEGO, SSO |
| [40 - FIDO2 & Hardware MFA](./docs/pam/40-fido2-hardware-mfa/README.md) | FIDO2/WebAuthn, YubiKey, passwordless |

### Credential Management

| Section | Description |
|---------|-------------|
| [08 - Password Management](./docs/pam/08-password-management/README.md) | Credential vault, rotation, checkout |
| [33 - Password Rotation Troubleshooting](./docs/pam/33-password-rotation-troubleshooting/README.md) | Rotation failures and remediation |
| [42 - SSH Key Lifecycle](./docs/pam/42-ssh-key-lifecycle/README.md) | SSH key management, rotation, CA |
| [43 - Service Account Lifecycle](./docs/pam/43-service-account-lifecycle/README.md) | Service account governance |

### Session Management

| Section | Description |
|---------|-------------|
| [09 - Session Management](./docs/pam/09-session-management/README.md) | Recording, monitoring, audit trails |
| [38 - Command Filtering](./docs/pam/38-command-filtering/README.md) | Command whitelisting/blacklisting |
| [39 - Session Recording Playback](./docs/pam/39-session-recording-playback/README.md) | Playback, OCR search, forensics |
| [44 - Session Sharing](./docs/pam/44-session-sharing/README.md) | Multi-user sessions, dual-control |

### Infrastructure & Operations

| Section | Description |
|---------|-------------|
| [10 - API & Automation](./docs/pam/10-api-automation/README.md) | REST API, DevOps integration |
| [11 - High Availability](./docs/pam/11-high-availability/README.md) | Clustering, DR, failover |
| [12 - Monitoring & Observability](./docs/pam/12-monitoring-observability/README.md) | Prometheus, Grafana, alerting |
| [13 - Troubleshooting](./docs/pam/13-troubleshooting/README.md) | Diagnostics, log analysis |
| [14 - Best Practices](./docs/pam/14-best-practices/README.md) | Security hardening, operations |
| [16 - Deployment Options](./docs/pam/16-cloud-deployment/README.md) | On-premises deployment patterns |
| [17 - API Reference](./docs/pam/17-api-reference/README.md) | Complete REST API documentation |
| [18 - Error Reference](./docs/pam/18-error-reference/README.md) | Error codes and remediation |
| [19 - System Requirements](./docs/pam/19-system-requirements/README.md) | Hardware, sizing, performance |
| [20 - Upgrade Guide](./docs/pam/20-upgrade-guide/README.md) | Version upgrades, HA procedures |
| [21 - Operational Runbooks](./docs/pam/21-operational-runbooks/README.md) | Daily/weekly/monthly procedures |
| [22 - FAQ & Known Issues](./docs/pam/22-faq-known-issues/README.md) | Common questions, compatibility |
| [26 - Performance Benchmarks](./docs/pam/26-performance-benchmarks/README.md) | Capacity planning, load testing |
| [28 - Certificate Management](./docs/pam/28-certificate-management/README.md) | TLS/SSL, CSR, renewal |
| [29 - Disaster Recovery](./docs/pam/29-disaster-recovery/README.md) | DR runbooks, RTO/RPO, PITR |
| [30 - Backup and Restore](./docs/pam/30-backup-restore/README.md) | Backup, restore, disaster recovery |
| [31 - wabadmin CLI Reference](./docs/pam/31-wabadmin-reference/README.md) | Complete CLI command reference |
| [32 - Load Balancer](./docs/pam/32-load-balancer/README.md) | HAProxy, health checks, SSL |
| [36 - Network Configuration](./docs/pam/36-network-validation/README.md) | Firewall rules, DNS, NTP |

### Advanced Features

| Section | Description |
|---------|-------------|
| [27 - Vendor Integration](./docs/pam/27-vendor-integration/README.md) | Cisco, Siemens, ABB, Rockwell |
| [41 - Account Discovery](./docs/pam/41-account-discovery/README.md) | Discovery scanning, bulk import |
| [45 - User Self-Service](./docs/pam/45-user-self-service/README.md) | Self-service portal |
| [46 - Privileged Task Automation](./docs/pam/46-privileged-task-automation/README.md) | Automated privileged operations |

### Compliance & Security

| Section | Description |
|---------|-------------|
| [23 - Incident Response](./docs/pam/23-incident-response/README.md) | Security incident playbooks |
| [24 - Compliance & Audit](./docs/pam/24-compliance-audit/README.md) | SOC2, ISO27001, PCI-DSS, HIPAA |
| [37 - Compliance Evidence](./docs/pam/37-compliance-evidence/README.md) | Evidence collection, attestation |

### Reference

| Section | Description |
|---------|-------------|
| [15 - Appendix](./docs/pam/15-appendix/README.md) | Glossary, quick reference, cheat sheets |

---

## OT Foundational Documentation (docs/ot/)

### Fundamentals & Learning

| Section | Description |
|---------|-------------|
| [00 - OT Cybersecurity Fundamentals](./docs/ot/00-fundamentals/README.md) | 16-week learning path for IT professionals (control theory, protocols, threats, compliance) |

### Overview & Architecture

| Section | Description |
|---------|-------------|
| [01 - Industrial Overview](./docs/ot/01-industrial-overview/README.md) | OT vs IT security, regulatory landscape |
| [02 - OT Architecture](./docs/ot/02-ot-architecture/README.md) | Zone deployment, IEC 62443 zones |
| [09 - Industrial Best Practices](./docs/ot/09-industrial-best-practices/README.md) | OT security design |
| [12 - OT Jump Host](./docs/ot/12-ot-jump-host/README.md) | Jump server configuration |

### Protocols & Access

| Section | Description |
|---------|-------------|
| [03 - Industrial Protocols](./docs/ot/03-industrial-protocols/README.md) | Modbus, DNP3, OPC UA, IEC 61850 |
| [04 - SCADA/ICS Access](./docs/ot/04-scada-ics-access/README.md) | HMI, PLC programming, vendor maintenance |
| [14 - Engineering Workstation Access](./docs/ot/14-engineering-workstation-access/README.md) | EWS access patterns |
| [16 - Historian Access](./docs/ot/16-historian-access/README.md) | Historian security, data diode |
| [17 - RTU Field Access](./docs/ot/17-rtu-field-access/README.md) | Remote terminal unit access |

### Air-Gapped & Offline

| Section | Description |
|---------|-------------|
| [05 - Air-Gapped Environments](./docs/ot/05-airgapped-environments/README.md) | Isolated deployments, data diodes |
| [10 - Offline Operations](./docs/ot/10-offline-operations/README.md) | Credential cache, sneakernet |

### Compliance & Integration

| Section | Description |
|---------|-------------|
| [06 - IEC 62443 Compliance](./docs/ot/06-iec62443-compliance/README.md) | Security levels, audit evidence |
| [07 - Industrial Use Cases](./docs/ot/07-industrial-use-cases/README.md) | Power, Oil & Gas, Manufacturing |
| [08 - OT Integration](./docs/ot/08-ot-integration/README.md) | SIEM, CMDB, monitoring |

### Operations & Safety

| Section | Description |
|---------|-------------|
| [11 - Vendor Remote Access](./docs/ot/11-vendor-remote-access/README.md) | Third-party vendor access |
| [13 - OT Safety Procedures](./docs/ot/13-ot-safety-procedures/README.md) | LOTO integration, SIS access |
| [15 - OT Change Management](./docs/ot/15-ot-change-management/README.md) | Change windows, rollback |

### Training & Career Development

| Section | Description |
|---------|-------------|
| [18 - OT Training & Certifications](./docs/ot/18-ot-training-certifications/README.md) | Professional certifications (GICSP, GRID), training providers, career paths |

---

<p align="center">
  <sub>66 Sections • 47 PAM + 19 OT • Pre-Production Lab • February 2026</sub>
</p>
