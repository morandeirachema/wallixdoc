# WALLIX Bastion 12.x Documentation

<p align="center">
  <img src="https://www.wallix.com/wp-content/uploads/2021/03/wallix-logo.svg" alt="WALLIX Logo" width="250"/>
</p>

<p align="center">
  <strong>Enterprise Privileged Access Management</strong><br>
  <sub>Comprehensive Documentation for WALLIX Bastion 12.x</sub>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/WALLIX%20Bastion-12.1.x-0066cc?style=for-the-badge" alt="WALLIX Version"/>
  <img src="https://img.shields.io/badge/Debian-12%20Bookworm-a80030?style=for-the-badge" alt="Debian Version"/>
  <img src="https://img.shields.io/badge/PostgreSQL-15%2B-336791?style=for-the-badge" alt="PostgreSQL"/>
  <img src="https://img.shields.io/badge/IEC%2062443-Compliant-228b22?style=for-the-badge" alt="IEC 62443"/>
</p>

<p align="center">
  <a href="#quick-navigation">Quick Navigation</a> •
  <a href="#whats-included">What's Included</a> •
  <a href="#getting-started">Getting Started</a> •
  <a href="#support">Support</a>
</p>

---

## Overview

This repository contains comprehensive documentation for **WALLIX Bastion 12.x**, the leading Privileged Access Management (PAM) solution for IT and OT environments.

### Repository Structure

```
wallix/
├── README.md              ← You are here
├── CLAUDE.md              ← AI assistant context file
├── docs/                  ← Product documentation (30 sections)
│   ├── README.md          ← Documentation index
│   ├── 00-official-resources/  ← Curated official WALLIX links
│   ├── 01-introduction/
│   ├── 02-getting-started/
│   ├── ...
│   └── 29-upgrade-guide/
├── install/               ← Multi-site OT installation guide
│   ├── README.md          ← Installation overview
│   ├── HOWTO.md           ← Step-by-step guide (1600+ lines)
│   └── 00-10-*.md         ← Detailed installation procedures
└── examples/              ← Code examples for automation
    ├── terraform/         ← Infrastructure as Code examples
    └── api/               ← REST API examples (Python, curl)
```

---

## Quick Navigation

| Need | Go To | Description |
|------|-------|-------------|
| **Learn about WALLIX** | [docs/](./docs/README.md) | Complete product documentation |
| **Install WALLIX** | [install/](./install/README.md) | Multi-site OT deployment guide |
| **Step-by-step setup** | [install/HOWTO.md](./install/HOWTO.md) | Comprehensive installation walkthrough |
| **API Reference** | [docs/26-api-reference/](./docs/26-api-reference/README.md) | REST API documentation |
| **Upgrade Guide** | [docs/29-upgrade-guide/](./docs/29-upgrade-guide/README.md) | Version upgrade procedures |
| **Official Resources** | [docs/00-official-resources/](./docs/00-official-resources/README.md) | Curated WALLIX links and PDFs |
| **Code Examples** | [examples/](./examples/README.md) | Terraform and API examples |

---

## What's Included

### Product Documentation (`/docs`)

Complete WALLIX Bastion 12.x documentation covering:

| Category | Sections | Topics |
|----------|----------|--------|
| **Fundamentals** | 01-04 | Introduction, Getting Started, Core Components, Architecture |
| **Security** | 05-08 | Authentication, Authorization, Password Management, Session Management |
| **Integration** | 09-12 | API Automation, Directory Integration, SIEM, External Auth |
| **Deployment** | 13-15 | High Availability, Backup/Recovery, Performance Tuning |
| **OT/Industrial** | 16-18 | OT Architecture, Industrial Protocols, Safety Systems |
| **Advanced** | 19-23 | Troubleshooting, Best Practices, Use Cases, Migration, Disaster Recovery |
| **Modern Infrastructure** | 24-27 | Cloud Deployment, Containers, API Reference, CLI Tools |
| **Reference** | 28-30 | System Requirements, Upgrade Guide, Appendices |

### Installation Guide (`/install`)

Production-ready deployment guide for multi-site OT environments:

| Document | Purpose |
|----------|---------|
| **README.md** | Project overview, architecture diagrams, quick start |
| **HOWTO.md** | Complete step-by-step installation (1600+ lines) |
| **01-prerequisites.md** | Hardware, software, network requirements |
| **02-site-a-primary.md** | Primary site HA cluster (Active-Active) |
| **03-site-b-secondary.md** | Secondary site HA cluster (Active-Passive) |
| **04-site-c-remote.md** | Remote standalone with offline capability |
| **05-multi-site-sync.md** | Cross-site synchronization |
| **06-ot-network-config.md** | OT protocol integration |
| **07-security-hardening.md** | Security hardening procedures |
| **08-validation-testing.md** | Testing and go-live checklist |

---

## Getting Started

### For New Users

```
1. Start with docs/01-introduction/     → Understand WALLIX capabilities
2. Review docs/02-getting-started/      → Basic concepts and terminology
3. Check docs/28-system-requirements/   → Verify your infrastructure
```

### For Installation

```
1. Read install/README.md               → Understand deployment architecture
2. Follow install/HOWTO.md              → Step-by-step installation guide
3. Complete install/08-validation.md    → Verify your deployment
```

### For Upgrades

```
1. Review docs/29-upgrade-guide/        → Understand upgrade paths
2. Backup current installation          → Follow backup procedures
3. Execute upgrade                      → Version-specific instructions
```

---

## Key Features (12.x)

### What's New in WALLIX Bastion 12.x

| Feature | Description |
|---------|-------------|
| **OpenID Connect (OIDC)** | Native SSO with Azure AD, Okta, Keycloak |
| **Enhanced RDP** | Resolution enforcement, improved compression |
| **Argon2ID** | Modern key derivation (replaces bcrypt for new installs) |
| **LUKS Disk Encryption** | Whole disk encryption on new installations |
| **PostgreSQL 15+** | Required database version for optimal performance |
| **Debian 12** | Required OS for new 12.x installations |

### Security Highlights

```
┌─────────────────────────────────────────────────────────────────┐
│                    SECURITY FEATURES                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Authentication           Authorization          Audit          │
│  ══════════════           ═════════════          ═════          │
│  • MFA (TOTP/FIDO2)       • RBAC Policies        • Session      │
│  • LDAP/AD                • Time Windows           Recording    │
│  • Kerberos SSO           • Approval Flows       • Keystroke    │
│  • OIDC/SAML              • JIT Access             Logging      │
│  • Certificate Auth       • Least Privilege      • Tamper-proof │
│                                                    Logs         │
│                                                                 │
│  Encryption               Credential Mgmt        Compliance     │
│  ══════════════           ═══════════════        ══════════     │
│  • AES-256-GCM            • Secure Vault         • IEC 62443    │
│  • TLS 1.3                • Auto Rotation        • NIST 800-82  │
│  • LUKS Disk              • SSH Key Mgmt         • NIS2         │
│  • Argon2ID               • No Exposure          • ISO 27001    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Compliance

This documentation supports compliance with:

| Standard | Description | Coverage |
|----------|-------------|----------|
| **IEC 62443** | Industrial Automation and Control Systems Security | Full |
| **NIST 800-82** | Guide to Industrial Control Systems Security | Full |
| **NIS2 Directive** | EU Network and Information Security | Full |
| **ISO 27001** | Information Security Management | Partial |
| **SOC 2 Type II** | Service Organization Control | Partial |

---

## Support

### Official Resources

| Resource | URL |
|----------|-----|
| **WALLIX Documentation** | https://pam.wallix.one/documentation |
| **Support Portal** | https://support.wallix.com |
| **Release Notes** | https://pam.wallix.one/documentation/release-notes |

### Quick Reference

```bash
# Check WALLIX status
systemctl status wallix-bastion
wabadmin status

# View license info
wabadmin license-info

# Check cluster health (HA)
crm status

# View recent audit
wabadmin audit --last 20
```

---

## Version Information

| Item | Value |
|------|-------|
| **Documentation Version** | 3.0 |
| **WALLIX Bastion Version** | 12.1.x |
| **Last Updated** | January 2026 |

---

## License

This documentation is provided for WALLIX Bastion deployment and administration purposes. WALLIX Bastion is a commercial product requiring valid licensing.

---

<p align="center">
  <strong>WALLIX Bastion 12.x Documentation</strong><br>
  <sub>Enterprise Privileged Access Management</sub>
</p>

<p align="center">
  <a href="./docs/README.md">Documentation</a> •
  <a href="./install/README.md">Installation Guide</a> •
  <a href="./examples/README.md">Examples</a> •
  <a href="./docs/00-official-resources/README.md">Official Resources</a>
</p>
