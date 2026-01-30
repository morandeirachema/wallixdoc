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
  <img src="https://img.shields.io/badge/MariaDB-10.6+-003545?style=flat-square" alt="MariaDB"/>
  <img src="https://img.shields.io/badge/IEC_62443-Compliant-228b22?style=flat-square" alt="IEC 62443"/>
  <img src="https://img.shields.io/badge/NIST_800--82-Compliant-228b22?style=flat-square" alt="NIST"/>
</p>

---

## Overview

**PAM4OT** is WALLIX's unified privileged access management solution designed for OT/industrial environments. Built on WALLIX Bastion 12.x, it provides:

- **Secure Remote Access** - Controlled access to critical systems through a single gateway
- **Strong Authentication** - MFA with FortiAuthenticator, LDAP/AD, Kerberos, SAML/OIDC
- **Session Recording** - Full audit trail with video replay and keystroke logging
- **Password Management** - Encrypted vault with automatic credential rotation
- **Industrial Protocol Support** - Native proxying for Modbus, DNP3, OPC UA, S7comm

---

## Documentation Structure

```
wallix/
│
├── docs/                         # Product Documentation
│   ├── 01-14  Core PAM           # Authentication, sessions, passwords, HA
│   ├── 15-23  Industrial/OT      # IEC 62443, SCADA, protocols, air-gapped
│   ├── 24-29  Deployment         # Cloud, containers, API, upgrades
│   └── 30-33  Operations         # Runbooks, compliance, incident response
│
├── install/                      # Multi-Site Deployment
│   ├── HOWTO.md                  # Complete installation guide
│   └── 00-10-*.md                # Step-by-step procedures
│
├── pre/                          # Pre-Production Lab
│   ├── 01-10-*.md                # Lab setup and validation
│   └── scripts/                  # Automation scripts
│
└── examples/                     # Code Examples
    ├── terraform/                # Infrastructure as Code
    └── api/                      # REST API samples
```

---

## Quick Navigation

### By Role

| Role | Recommended Path |
|------|------------------|
| **New to PAM4OT** | [Introduction](./docs/01-introduction/README.md) → [Architecture](./docs/02-architecture/README.md) → [Core Components](./docs/03-core-components/README.md) |
| **System Administrator** | [Installation](./install/README.md) → [Configuration](./docs/04-configuration/README.md) → [Troubleshooting](./docs/12-troubleshooting/README.md) |
| **Security Engineer** | [Authentication](./docs/05-authentication/README.md) → [Best Practices](./docs/13-best-practices/README.md) → [Incident Response](./docs/32-incident-response/README.md) |
| **OT/ICS Engineer** | [Industrial Overview](./docs/15-industrial-overview/README.md) → [Protocols](./docs/17-industrial-protocols/README.md) → [SCADA Access](./docs/18-scada-ics-access/README.md) |
| **DevOps/Automation** | [API Reference](./docs/26-api-reference/README.md) → [Cloud Deployment](./docs/24-cloud-deployment/README.md) → [Examples](./examples/README.md) |
| **Compliance Officer** | [IEC 62443](./docs/20-iec62443-compliance/README.md) → [Compliance Audit](./docs/33-compliance-audit/README.md) |

### By Team

| Team | Key Documents |
|------|---------------|
| **Networking** | [Architecture Diagrams](./install/09-architecture-diagrams.md) • [Network Segmentation](./docs/16-ot-architecture/network-segmentation-validation.md) • [Network Troubleshooting](./docs/12-troubleshooting/network-troubleshooting.md) |
| **Identity/IAM** | [Authentication](./docs/05-authentication/README.md) • [FortiAuthenticator](./docs/05-authentication/fortiauthenticator-integration.md) • [Kerberos](./docs/05-authentication/kerberos-configuration.md) • [LDAP Troubleshooting](./docs/12-troubleshooting/ldap-ad-troubleshooting.md) |
| **Security/SIEM** | [SIEM Integration](./docs/22-ot-integration/README.md) • [Incident Response](./docs/32-incident-response/README.md) • [SIEM Troubleshooting](./docs/12-troubleshooting/siem-troubleshooting.md) |
| **Monitoring/Observability** | [Alertmanager Integrations](./docs/13-best-practices/alertmanager-integrations.md) • [Alert Escalation](./docs/30-operational-runbooks/alert-escalation.md) • [Pre-prod Observability](./pre/08-observability.md) |
| **Infrastructure** | [High Availability](./docs/10-high-availability/README.md) • [Backup & Recovery](./docs/30-operational-runbooks/backup-recovery.md) • [Failover Testing](./docs/30-operational-runbooks/failover-testing.md) |
| **OT/Industrial** | [Industrial Protocols](./docs/17-industrial-protocols/README.md) • [Protocol Validation](./docs/17-industrial-protocols/protocol-security-validation.md) • [Emergency Vendor Access](./docs/30-operational-runbooks/emergency-vendor-access.md) |

---

## Key Features

| Category | Capabilities |
|----------|-------------|
| **Authentication** | MFA (FortiAuthenticator, TOTP, FIDO2), LDAP/AD, Kerberos SSO, OIDC/SAML, X.509 Certificates |
| **Authorization** | RBAC, approval workflows, time-based access, JIT privileged access |
| **Session Management** | Video recording, real-time monitoring, keystroke logging, session sharing |
| **Password Management** | AES-256 encrypted vault, automatic rotation, SSH key management, credential checkout |
| **Industrial Protocols** | Modbus TCP, DNP3, OPC UA, EtherNet/IP, S7comm, IEC 61850 |
| **High Availability** | Active-Active clustering, MariaDB HA replication, automatic failover |

---

## Compliance Coverage

| Standard | Coverage | Standard | Coverage |
|----------|----------|----------|----------|
| **IEC 62443** | Full | **SOC 2 Type II** | Full |
| **NIST 800-82** | Full | **ISO 27001** | Full |
| **NIS2 Directive** | Full | **PCI-DSS** | Full |
| **NERC CIP** | Full | **HIPAA** | Full |

See [Compliance & Audit Guide](./docs/33-compliance-audit/README.md) for detailed mapping.

---

## Technical Requirements

| Component | Specification |
|-----------|---------------|
| **Operating System** | Debian 12 (Bookworm) |
| **Database** | MariaDB 10.6+ with HA replication (ports 3306/3307) |
| **Clustering** | Pacemaker/Corosync |
| **Encryption** | AES-256-GCM, TLS 1.3, LUKS disk encryption |
| **Key Derivation** | Argon2ID |
| **MFA** | FortiAuthenticator via RADIUS |

See [System Requirements](./docs/28-system-requirements/README.md) for detailed sizing.

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
sudo mysql -e "SHOW SLAVE STATUS\G"

# License & Audit
wabadmin license-info
wabadmin audit --last 20
```

### Key Ports

| Port | Service | Port | Service |
|------|---------|------|---------|
| 443 | HTTPS/Web UI | 22 | SSH Proxy |
| 636 | LDAPS | 88 | Kerberos |
| 1812 | RADIUS (MFA) | 3306 | MariaDB |
| 514/6514 | Syslog | 502 | Modbus |

---

## Getting Started

### 1. Pre-Production Lab (Recommended)

Start with our [Pre-Production Lab Guide](./pre/README.md) to build a test environment:

```
Pre-Production Lab
├── AD/LDAP test domain
├── FortiAuthenticator MFA
├── PAM4OT HA cluster
├── Test targets (Linux/Windows/OT)
└── Monitoring stack (Prometheus/Grafana)
```

### 2. Production Deployment

Follow the [Multi-Site Installation Guide](./install/README.md) for production:

```
Production Architecture
├── Site A: Primary HQ (Active-Active HA)
├── Site B: Secondary Plant (Active-Passive DR)
└── Site C: Remote Field (Standalone + Offline)
```

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

## Document Index

### Core Documentation (docs/)

| Section | Description |
|---------|-------------|
| [01 - Introduction](./docs/01-introduction/README.md) | Company and product overview |
| [02 - Architecture](./docs/02-architecture/README.md) | System architecture and deployment models |
| [03 - Core Components](./docs/03-core-components/README.md) | Session Manager, Password Manager, Access Manager |
| [04 - Configuration](./docs/04-configuration/README.md) | Object model, domains, devices, accounts |
| [05 - Authentication](./docs/05-authentication/README.md) | MFA, SSO, LDAP/AD, Kerberos, OIDC/SAML |
| [06 - Authorization](./docs/06-authorization/README.md) | RBAC, approval workflows, JIT access |
| [07 - Password Management](./docs/07-password-management/README.md) | Credential vault, rotation, checkout |
| [08 - Session Management](./docs/08-session-management/README.md) | Recording, monitoring, audit trails |
| [09 - API & Automation](./docs/09-api-automation/README.md) | REST API, DevOps integration |
| [10 - High Availability](./docs/10-high-availability/README.md) | Clustering, DR, failover |
| [11 - Monitoring & Observability](./docs/11-monitoring-observability/README.md) | Prometheus, Grafana, alerting |
| [12 - Troubleshooting](./docs/12-troubleshooting/README.md) | Diagnostics, log analysis |
| [13 - Best Practices](./docs/13-best-practices/README.md) | Security hardening, operations |

### Industrial/OT Documentation

| Section | Description |
|---------|-------------|
| [15 - Industrial Overview](./docs/15-industrial-overview/README.md) | OT vs IT, regulatory requirements |
| [16 - OT Architecture](./docs/16-ot-architecture/README.md) | Zone deployment, IEC 62443 zones |
| [17 - Industrial Protocols](./docs/17-industrial-protocols/README.md) | Modbus, DNP3, OPC UA, IEC 61850 |
| [18 - SCADA/ICS Access](./docs/18-scada-ics-access/README.md) | HMI, PLC, vendor maintenance |
| [19 - Air-Gapped Environments](./docs/19-airgapped-environments/README.md) | Isolated deployments, data diodes |
| [20 - IEC 62443 Compliance](./docs/20-iec62443-compliance/README.md) | Security levels, audit evidence |

### Operations & Reference

| Section | Description |
|---------|-------------|
| [26 - API Reference](./docs/26-api-reference/README.md) | Complete REST API documentation |
| [27 - Error Reference](./docs/27-error-reference/README.md) | Error codes and remediation |
| [28 - System Requirements](./docs/28-system-requirements/README.md) | Hardware, sizing, performance |
| [30 - Operational Runbooks](./docs/30-operational-runbooks/README.md) | Daily/weekly/monthly procedures |
| [31 - FAQ & Known Issues](./docs/31-faq-known-issues/README.md) | Common questions, compatibility |
| [32 - Incident Response](./docs/32-incident-response/README.md) | Security incident playbooks |
| [33 - Compliance & Audit](./docs/33-compliance-audit/README.md) | SOC2, ISO27001, PCI-DSS, HIPAA |

---

<p align="center">
  <sub>WALLIX PAM4OT Documentation • Version 5.0 • January 2026</sub>
</p>
