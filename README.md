# WALLIX PAM4OT Documentation

<p align="center">
  <img src="https://www.wallix.com/wp-content/uploads/2021/03/wallix-logo.svg" alt="WALLIX Logo" width="200"/>
</p>

<p align="center">
  <strong>Privileged Access Management for Operational Technology</strong><br/>
  <sub>Powered by WALLIX Bastion 12.x</sub>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/PAM4OT-12.1.x-0066cc?style=flat-square" alt="Version"/>
  <img src="https://img.shields.io/badge/Debian-12-a80030?style=flat-square" alt="Debian"/>
  <img src="https://img.shields.io/badge/PostgreSQL-15+-336791?style=flat-square" alt="PostgreSQL"/>
  <img src="https://img.shields.io/badge/IEC_62443-Compliant-228b22?style=flat-square" alt="Compliance"/>
  <img src="https://img.shields.io/badge/NIST_800--82-Compliant-228b22?style=flat-square" alt="NIST"/>
</p>

> **PAM4OT** is WALLIX's unified privileged access management solution designed specifically for OT/industrial environments. It provides secure remote access, strong authentication, just-in-time access, session recording, and password management for critical infrastructure.

---

## Quick Links

| | | |
|:---:|:---:|:---:|
| [**Documentation**](./docs/README.md) | [**Installation**](./install/README.md) | [**Examples**](./examples/README.md) |
| 34 comprehensive sections | Multi-site OT deployment | Terraform & API code |
| [**FAQ**](./docs/31-faq-known-issues/README.md) | [**Runbooks**](./docs/30-operational-runbooks/README.md) | [**Compliance**](./docs/33-compliance-audit/README.md) |
| Common questions & issues | Operational procedures | SOC2, ISO27001, PCI-DSS |

---

## What's Inside

```
wallix/
├── docs/                    # Product documentation
│   ├── 01-14                # Core PAM (auth, sessions, passwords, HA)
│   ├── 15-23                # Industrial/OT security
│   ├── 24-29                # Cloud, containers, API, upgrades
│   └── 30-33                # Operations, compliance, incident response
├── install/                 # Multi-site deployment guide
│   ├── HOWTO.md             # Step-by-step installation (1700+ lines)
│   └── 00-10-*.md           # Site-specific procedures
└── examples/                # Code examples
    ├── terraform/           # IaC provider & resources
    └── api/                 # Python client & curl scripts
```

---

## Get Started

### By Role

| Role | Start Here |
|------|------------|
| **New to WALLIX** | [Introduction](./docs/01-introduction/README.md) → [Architecture](./docs/02-architecture/README.md) |
| **Installing** | [Prerequisites](./install/01-prerequisites.md) → [HOWTO](./install/HOWTO.md) |
| **Migrating from CyberArk** | [Migration Guide](./docs/11-migration-from-cyberark/README.md) |
| **OT/Industrial** | [Industrial Overview](./docs/15-industrial-overview/README.md) → [IEC 62443](./docs/20-iec62443-compliance/README.md) |
| **DevOps/Automation** | [API Reference](./docs/26-api-reference/README.md) → [Examples](./examples/README.md) |
| **Operations** | [Runbooks](./docs/30-operational-runbooks/README.md) → [Troubleshooting](./docs/12-troubleshooting/README.md) |
| **Compliance** | [Compliance Guide](./docs/33-compliance-audit/README.md) |

---

## Key Features

| Category | Capabilities |
|----------|-------------|
| **Authentication** | MFA (TOTP/FIDO2), LDAP/AD, Kerberos, OIDC/SAML, Certificates |
| **Authorization** | RBAC, approval workflows, time windows, JIT access |
| **Sessions** | Recording, real-time monitoring, keystroke logging |
| **Credentials** | Encrypted vault, automatic rotation, SSH key management |
| **Encryption** | AES-256-GCM, TLS 1.3, LUKS disk, Argon2ID |
| **Protocols** | SSH, RDP, VNC, HTTP/S, Telnet, Modbus, OPC UA, DNP3 |

---

## Compliance Coverage

| Framework | Status | Framework | Status |
|-----------|--------|-----------|--------|
| IEC 62443 | Full | SOC 2 Type II | Full |
| NIST 800-82 | Full | ISO 27001 | Full |
| NIS2 | Full | PCI-DSS | Full |
| HIPAA | Full | GDPR | Full |

---

## Technical Stack

| Component | Version |
|-----------|---------|
| Operating System | Debian 12 (Bookworm) |
| Database | PostgreSQL 15+ |
| Clustering | Pacemaker/Corosync |
| Encryption | AES-256-GCM, TLS 1.3 |

---

## Quick Commands

```bash
# Service status
systemctl status wallix-bastion
wabadmin status

# Cluster health
crm status

# License info
wabadmin license-info

# Recent audit
wabadmin audit --last 20
```

---

## Resources

| Resource | Link |
|----------|------|
| Official Docs | https://pam.wallix.one/documentation |
| Support Portal | https://support.wallix.com |
| Terraform Provider | https://registry.terraform.io/providers/wallix/wallix-bastion |
| GitHub | https://github.com/wallix |

---

<p align="center">
  <sub>WALLIX Bastion 12.x Documentation • Version 4.0 • January 2026</sub>
</p>
