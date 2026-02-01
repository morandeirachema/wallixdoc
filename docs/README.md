# WALLIX PAM4OT Documentation

> Complete reference for **PAM4OT** (Privileged Access Management for OT) — 64 sections covering PAM fundamentals, industrial/OT security, cloud deployment, operations, and compliance.
>
> PAM4OT is built on WALLIX Bastion 12.x technology, specifically designed for operational technology environments.

---

## Documentation Structure

This documentation is organized into two main categories:

```
docs/
├── pam/    # PAM/WALLIX Core (47 sections)
│           # Authentication, authorization, password management,
│           # session recording, API, deployment, operations
│
└── ot/     # OT Foundational (17 sections)
            # Industrial protocols, IEC 62443, SCADA/ICS,
            # air-gapped environments, OT safety, vendor access
```

---

## PAM / WALLIX Core Documentation

### Getting Started (pam/)

| # | Section | Description |
|---|---------|-------------|
| 00 | [Official Resources](./pam/00-official-resources/README.md) | Curated links to official WALLIX docs and PDFs |
| 01 | [Quick Start](./pam/01-quick-start/README.md) | Quick installation and configuration guide |
| 02 | [Introduction](./pam/02-introduction/README.md) | WALLIX overview, product suite, market positioning |
| 03 | [Architecture](./pam/03-architecture/README.md) | Deployment models, component architecture |
| 04 | [Core Components](./pam/04-core-components/README.md) | Session Manager, Password Manager, Access Manager |
| 05 | [Configuration](./pam/05-configuration/README.md) | Object model, domains, devices, accounts |

### Authentication & Authorization (pam/)

| # | Section | Description |
|---|---------|-------------|
| 06 | [Authentication](./pam/06-authentication/README.md) | MFA, SSO, LDAP/AD, OIDC/SAML, Kerberos |
| 07 | [Authorization](./pam/07-authorization/README.md) | RBAC, approval workflows, time windows |
| 25 | [JIT Access](./pam/25-jit-access/README.md) | Just-In-Time access, approval workflows, time-bounded access |
| 34 | [LDAP/AD Integration](./pam/34-ldap-ad-integration/README.md) | Active Directory, LDAP sync, group mapping |
| 35 | [Kerberos Authentication](./pam/35-kerberos-authentication/README.md) | Kerberos, SPNEGO, keytab, cross-realm trust |
| 40 | [FIDO2 & Hardware MFA](./pam/40-fido2-hardware-mfa/README.md) | FIDO2/WebAuthn, YubiKey, smart cards, passwordless |

### Password & Session Management (pam/)

| # | Section | Description |
|---|---------|-------------|
| 08 | [Password Management](./pam/08-password-management/README.md) | Vault, rotation, checkout workflows |
| 09 | [Session Management](./pam/09-session-management/README.md) | Recording, monitoring, audit trails |
| 33 | [Password Rotation Troubleshooting](./pam/33-password-rotation-troubleshooting/README.md) | Rotation failures, SSH keys, custom scripts |
| 38 | [Command Filtering](./pam/38-command-filtering/README.md) | Command whitelisting/blacklisting, regex patterns |
| 39 | [Session Recording Playback](./pam/39-session-recording-playback/README.md) | Playback, OCR search, forensics, export |
| 42 | [SSH Key Lifecycle](./pam/42-ssh-key-lifecycle/README.md) | SSH key generation, rotation, revocation, CA, HSM |
| 43 | [Service Account Lifecycle](./pam/43-service-account-lifecycle/README.md) | Service account governance, rotation, decommissioning |
| 44 | [Session Sharing & Collaboration](./pam/44-session-sharing/README.md) | Multi-user sessions, dual-control, training |
| 45 | [User Self-Service Portal](./pam/45-user-self-service/README.md) | Password management, MFA enrollment, credential checkout |
| 46 | [Privileged Task Automation](./pam/46-privileged-task-automation/README.md) | Automated privileged tasks, service accounts, runbooks |

### Discovery & Onboarding (pam/)

| # | Section | Description |
|---|---------|-------------|
| 41 | [Account Discovery & Onboarding](./pam/41-account-discovery/README.md) | Discovery scanning, orphaned accounts, bulk import |

### API & Automation (pam/)

| # | Section | Description |
|---|---------|-------------|
| 10 | [API & Automation](./pam/10-api-automation/README.md) | REST API, scripting, DevOps integration |
| 17 | [API Reference](./pam/17-api-reference/README.md) | Complete REST API documentation |

### Deployment & Infrastructure (pam/)

| # | Section | Description |
|---|---------|-------------|
| 11 | [High Availability](./pam/11-high-availability/README.md) | Clustering, DR, backup, failover |
| 16 | [Deployment Options](./pam/16-cloud-deployment/README.md) | On-premises VMs, bare metal, Terraform IaC |
| 19 | [System Requirements](./pam/19-system-requirements/README.md) | Hardware sizing, performance tuning |
| 20 | [Upgrade Guide](./pam/20-upgrade-guide/README.md) | Version upgrades, HA procedures |
| 26 | [Performance Benchmarks](./pam/26-performance-benchmarks/README.md) | Capacity planning, load testing, optimization |
| 28 | [Certificate Management](./pam/28-certificate-management/README.md) | TLS/SSL, CSR generation, renewal, Let's Encrypt, HSM |
| 29 | [Disaster Recovery](./pam/29-disaster-recovery/README.md) | DR runbooks, RTO/RPO, failover procedures, PITR |
| 30 | [Backup and Restore](./pam/30-backup-restore/README.md) | Full/selective backup, PITR, offsite storage |
| 32 | [Load Balancer Configuration](./pam/32-load-balancer/README.md) | HAProxy, Nginx, F5, health checks, SSL termination |
| 36 | [Network Configuration](./pam/36-network-validation/README.md) | Firewall rules, DNS, NTP, validation procedures |

### Vendor Integration (pam/)

| # | Section | Description |
|---|---------|-------------|
| 27 | [Vendor-Specific Integration](./pam/27-vendor-integration/README.md) | Cisco, Juniper, Palo Alto, Siemens, ABB, Rockwell |

### Operations & Monitoring (pam/)

| # | Section | Description |
|---|---------|-------------|
| 12 | [Monitoring & Observability](./pam/12-monitoring-observability/README.md) | Prometheus, Grafana, alerting, logs |
| 13 | [Troubleshooting](./pam/13-troubleshooting/README.md) | Diagnostics, common issues, log analysis |
| 14 | [Best Practices](./pam/14-best-practices/README.md) | Security hardening, design patterns |
| 18 | [Error Reference](./pam/18-error-reference/README.md) | Error codes, causes, remediation |
| 21 | [Operational Runbooks](./pam/21-operational-runbooks/README.md) | Daily/weekly/monthly procedures |
| 22 | [FAQ & Known Issues](./pam/22-faq-known-issues/README.md) | Common questions, limitations |
| 31 | [wabadmin CLI Reference](./pam/31-wabadmin-reference/README.md) | Complete CLI command reference, syntax, examples |

### Compliance & Security (pam/)

| # | Section | Description |
|---|---------|-------------|
| 23 | [Incident Response](./pam/23-incident-response/README.md) | Security playbooks, forensics |
| 24 | [Compliance & Audit](./pam/24-compliance-audit/README.md) | SOC2, ISO27001, PCI-DSS, HIPAA, GDPR |
| 37 | [Compliance Evidence](./pam/37-compliance-evidence/README.md) | Evidence collection, audit artifacts, attestation |

### Reference (pam/)

| # | Section | Description |
|---|---------|-------------|
| 15 | [Appendix](./pam/15-appendix/README.md) | Glossary, quick reference, cheat sheets |

---

## OT Foundational Documentation

### OT Fundamentals (ot/)

**Start Here**: If you're new to OT/ICS security, begin with the fundamentals guide.

| # | Section | Description |
|---|---------|-------------|
| 00 | [OT Cybersecurity Fundamentals](./ot/00-fundamentals/README.md) | 16-week learning path for IT professionals transitioning to OT security |

**Learning Path Modules** (within 00-fundamentals/):
- 01-ot-fundamentals.md - Control theory, process control basics
- 02-control-systems-101.md - PLC, RTU, DCS, HMI, SCADA architecture
- 03-ot-vs-it-security.md - Mindset shift, CIA triad reversal
- 04-industrial-protocols.md - Modbus, DNP3, OPC UA, EtherNet/IP
- 05-ot-network-architecture.md - Purdue Model, zones/conduits
- 06-legacy-systems.md - Securing unpatchable systems
- 07-ot-threat-landscape.md - APT groups, ICS malware
- 08-ot-threat-modeling.md - Attack trees, STRIDE for OT
- 09-ot-incident-response.md - Safety-first IR, forensics
- 10-iec62443-deep-dive.md - Security levels, compliance
- 11-regulatory-landscape.md - NERC CIP, CFATS, NIS2
- 12-vendor-risk-management.md - Third-party access, supply chain
- 13-ot-security-career.md - Certifications, career paths
- 14-hands-on-labs.md - Lab setup, practice environments
- 15-resources.md - Books, courses, communities, tools

### OT Overview & Architecture (ot/)

| # | Section | Description |
|---|---------|-------------|
| 01 | [Industrial Overview](./ot/01-industrial-overview/README.md) | OT vs IT security, regulatory landscape |
| 02 | [OT Architecture](./ot/02-ot-architecture/README.md) | Zone deployment, IEC 62443 zones 0-5 |
| 09 | [Industrial Best Practices](./ot/09-industrial-best-practices/README.md) | OT security design, incident response |
| 12 | [OT Jump Host](./ot/12-ot-jump-host/README.md) | OT jump server configuration, industrial access |

### Industrial Protocols & Access (ot/)

| # | Section | Description |
|---|---------|-------------|
| 03 | [Industrial Protocols](./ot/03-industrial-protocols/README.md) | Modbus, DNP3, OPC UA, IEC 61850, S7comm |
| 04 | [SCADA/ICS Access](./ot/04-scada-ics-access/README.md) | HMI, PLC programming, vendor maintenance |
| 14 | [Engineering Workstation Access](./ot/14-engineering-workstation-access/README.md) | EWS access patterns, PLC programming |
| 16 | [Historian Access](./ot/16-historian-access/README.md) | Historian security, data diode integration |
| 17 | [RTU Field Access](./ot/17-rtu-field-access/README.md) | Remote terminal unit access, field device management |

### Air-Gapped & Offline (ot/)

| # | Section | Description |
|---|---------|-------------|
| 05 | [Air-Gapped Environments](./ot/05-airgapped-environments/README.md) | Isolated deployments, data diodes |
| 10 | [Offline & Sneakernet Operations](./ot/10-offline-operations/README.md) | Air-gapped operations, credential cache, secure media |

### Compliance & Use Cases (ot/)

| # | Section | Description |
|---|---------|-------------|
| 06 | [IEC 62443 Compliance](./ot/06-iec62443-compliance/README.md) | Security levels SL1-4, audit evidence |
| 07 | [Industrial Use Cases](./ot/07-industrial-use-cases/README.md) | Power, Oil & Gas, Manufacturing, Water |
| 08 | [OT Integration](./ot/08-ot-integration/README.md) | SIEM, CMDB, monitoring platforms |

### OT Operations & Safety (ot/)

| # | Section | Description |
|---|---------|-------------|
| 11 | [Vendor Remote Access](./ot/11-vendor-remote-access/README.md) | Third-party vendor access, contractor management |
| 13 | [OT Safety Procedures](./ot/13-ot-safety-procedures/README.md) | LOTO integration, SIS access, emergency procedures |
| 15 | [OT Change Management](./ot/15-ot-change-management/README.md) | Change windows, safety-critical changes, rollback |

---

## Quick Start Paths

### By Role

```
Architect       → pam/02 → pam/03 → pam/11 → pam/14 → pam/16
Engineer        → pam/02 → pam/04 → pam/05 → pam/08 → pam/10
Security        → pam/06 → pam/40 → pam/07 → pam/25 → pam/09 → pam/39 → pam/23 → pam/24
Operations      → pam/21 → pam/13 → pam/18 → pam/31
OT/Industrial   → ot/00-fundamentals → ot/01 → ot/02 → ot/03 → ot/06 → ot/09
DevOps          → pam/10 → pam/17 → examples/
Compliance      → pam/24 → pam/25 → ot/06 → pam/09 → pam/39 → pam/07
```

### By Task

| Task | Path |
|------|------|
| First deployment | pam/02 → pam/19 → [install/HOWTO.md](../install/HOWTO.md) |
| Troubleshoot issue | pam/31 → pam/13 → pam/18 |
| Prepare for audit | pam/24 → pam/09 → pam/39 → pam/21 |
| Review session recordings | pam/39 → pam/09 → pam/23 |
| Set up automation | pam/10 → pam/17 → [examples/](../examples/README.md) |
| Learn OT fundamentals | ot/00-fundamentals (start here for OT basics) |
| Deploy OT zone architecture | ot/01 → ot/02 → ot/03 → ot/09 |
| Configure SCADA access | ot/04 → ot/03 → ot/12 → ot/14 |
| Air-gapped deployment | ot/05 → ot/10 → ot/12 |
| IEC 62443 compliance | ot/06 → pam/37 → pam/24 → ot/13 |

---

## Version Coverage

| Product | Version |
|---------|---------|
| WALLIX Bastion | 12.x (12.0, 12.1.x) |
| WALLIX Access Manager | 5.x |
| WALLIX PEDM | 3.x |

### What's New in 12.x

- OpenID Connect (OIDC) authentication
- Single Sign-On without credential re-entry
- RDP resolution enforcement
- LUKS disk encryption by default
- Debian 12 (Bookworm) base
- Argon2ID key derivation

---

## Conventions

| Symbol | Meaning |
|--------|---------|
| `code` | Commands, config, API calls |
| **Bold** | Important terms, UI elements |
| > Quote | Tips and notes |

---

## Coverage Summary

| Category | Sections | Location | Status |
|----------|----------|----------|--------|
| PAM Core | 47 | docs/pam/ | Complete |
| OT Foundational | 18 | docs/ot/ | Complete |
| **Total** | **65** | | **Complete** |

---

<p align="center">
  <sub>65 Sections • 47 PAM + 18 OT (including 16-module fundamentals) • February 2026</sub>
</p>
