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
| 00 | [Quick Start](./pam/00-quick-start/README.md) | Quick installation and configuration guide |
| 01 | [Introduction](./pam/01-introduction/README.md) | WALLIX overview, product suite, market positioning |
| 02 | [Architecture](./pam/02-architecture/README.md) | Deployment models, component architecture |
| 03 | [Core Components](./pam/03-core-components/README.md) | Session Manager, Password Manager, Access Manager |
| 04 | [Configuration](./pam/04-configuration/README.md) | Object model, domains, devices, accounts |

### Authentication & Authorization (pam/)

| # | Section | Description |
|---|---------|-------------|
| 05 | [Authentication](./pam/05-authentication/README.md) | MFA, SSO, LDAP/AD, OIDC/SAML, Kerberos |
| 06 | [Authorization](./pam/06-authorization/README.md) | RBAC, approval workflows, time windows |
| 34 | [JIT Access](./pam/34-jit-access/README.md) | Just-In-Time access, approval workflows, time-bounded access |
| 45 | [LDAP/AD Integration](./pam/45-ldap-ad-integration/README.md) | Active Directory, LDAP sync, group mapping |
| 46 | [Kerberos Authentication](./pam/46-kerberos-authentication/README.md) | Kerberos, SPNEGO, keytab, cross-realm trust |
| 52 | [FIDO2 & Hardware MFA](./pam/52-fido2-hardware-mfa/README.md) | FIDO2/WebAuthn, YubiKey, smart cards, passwordless |

### Password & Session Management (pam/)

| # | Section | Description |
|---|---------|-------------|
| 07 | [Password Management](./pam/07-password-management/README.md) | Vault, rotation, checkout workflows |
| 08 | [Session Management](./pam/08-session-management/README.md) | Recording, monitoring, audit trails |
| 44 | [Password Rotation Troubleshooting](./pam/44-password-rotation-troubleshooting/README.md) | Rotation failures, SSH keys, custom scripts |
| 49 | [Command Filtering](./pam/49-command-filtering/README.md) | Command whitelisting/blacklisting, regex patterns |
| 50 | [Session Recording Playback](./pam/50-session-recording-playback/README.md) | Playback, OCR search, forensics, export |
| 56 | [SSH Key Lifecycle](./pam/56-ssh-key-lifecycle/README.md) | SSH key generation, rotation, revocation, CA, HSM |
| 57 | [Service Account Lifecycle](./pam/57-service-account-lifecycle/README.md) | Service account governance, rotation, decommissioning |
| 58 | [Session Sharing & Collaboration](./pam/58-session-sharing/README.md) | Multi-user sessions, dual-control, training |
| 59 | [User Self-Service Portal](./pam/59-user-self-service/README.md) | Password management, MFA enrollment, credential checkout |
| 60 | [Privileged Task Automation](./pam/60-privileged-task-automation/README.md) | Automated privileged tasks, service accounts, runbooks |

### Discovery & Onboarding (pam/)

| # | Section | Description |
|---|---------|-------------|
| 53 | [Account Discovery & Onboarding](./pam/53-account-discovery/README.md) | Discovery scanning, orphaned accounts, bulk import |

### API & Automation (pam/)

| # | Section | Description |
|---|---------|-------------|
| 09 | [API & Automation](./pam/09-api-automation/README.md) | REST API, scripting, DevOps integration |
| 26 | [API Reference](./pam/26-api-reference/README.md) | Complete REST API documentation |

### Deployment & Infrastructure (pam/)

| # | Section | Description |
|---|---------|-------------|
| 10 | [High Availability](./pam/10-high-availability/README.md) | Clustering, DR, backup, failover |
| 24 | [Deployment Options](./pam/24-cloud-deployment/README.md) | On-premises VMs, bare metal, Terraform IaC |
| 28 | [System Requirements](./pam/28-system-requirements/README.md) | Hardware sizing, performance tuning |
| 29 | [Upgrade Guide](./pam/29-upgrade-guide/README.md) | Version upgrades, HA procedures |
| 35 | [Performance Benchmarks](./pam/35-performance-benchmarks/README.md) | Capacity planning, load testing, optimization |
| 38 | [Certificate Management](./pam/38-certificate-management/README.md) | TLS/SSL, CSR generation, renewal, Let's Encrypt, HSM |
| 39 | [Disaster Recovery](./pam/39-disaster-recovery/README.md) | DR runbooks, RTO/RPO, failover procedures, PITR |
| 40 | [Backup and Restore](./pam/40-backup-restore/README.md) | Full/selective backup, PITR, offsite storage |
| 42 | [Load Balancer Configuration](./pam/42-load-balancer/README.md) | HAProxy, Nginx, F5, health checks, SSL termination |
| 47 | [Network Configuration](./pam/47-network-validation/README.md) | Firewall rules, DNS, NTP, validation procedures |

### Vendor Integration (pam/)

| # | Section | Description |
|---|---------|-------------|
| 36 | [Vendor-Specific Integration](./pam/36-vendor-integration/README.md) | Cisco, Juniper, Palo Alto, Siemens, ABB, Rockwell |

### Operations & Monitoring (pam/)

| # | Section | Description |
|---|---------|-------------|
| 11 | [Monitoring & Observability](./pam/11-monitoring-observability/README.md) | Prometheus, Grafana, alerting, logs |
| 12 | [Troubleshooting](./pam/12-troubleshooting/README.md) | Diagnostics, common issues, log analysis |
| 13 | [Best Practices](./pam/13-best-practices/README.md) | Security hardening, design patterns |
| 27 | [Error Reference](./pam/27-error-reference/README.md) | Error codes, causes, remediation |
| 30 | [Operational Runbooks](./pam/30-operational-runbooks/README.md) | Daily/weekly/monthly procedures |
| 31 | [FAQ & Known Issues](./pam/31-faq-known-issues/README.md) | Common questions, limitations |
| 41 | [wabadmin CLI Reference](./pam/41-wabadmin-reference/README.md) | Complete CLI command reference, syntax, examples |

### Compliance & Security (pam/)

| # | Section | Description |
|---|---------|-------------|
| 32 | [Incident Response](./pam/32-incident-response/README.md) | Security playbooks, forensics |
| 33 | [Compliance & Audit](./pam/33-compliance-audit/README.md) | SOC2, ISO27001, PCI-DSS, HIPAA, GDPR |
| 48 | [Compliance Evidence](./pam/48-compliance-evidence/README.md) | Evidence collection, audit artifacts, attestation |

### Reference (pam/)

| # | Section | Description |
|---|---------|-------------|
| 14 | [Appendix](./pam/14-appendix/README.md) | Glossary, quick reference, cheat sheets |

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
Architect       → pam/01 → pam/02 → pam/10 → pam/13 → pam/24
Engineer        → pam/01 → pam/03 → pam/04 → pam/07 → pam/09
Security        → pam/05 → pam/52 → pam/06 → pam/34 → pam/08 → pam/50 → pam/32 → pam/33
Operations      → pam/30 → pam/12 → pam/27 → pam/31
OT/Industrial   → ot/00-fundamentals → ot/01 → ot/02 → ot/03 → ot/06 → ot/09
DevOps          → pam/09 → pam/26 → examples/
Compliance      → pam/33 → pam/34 → ot/20 → pam/08 → pam/50 → pam/06
```

### By Task

| Task | Path |
|------|------|
| First deployment | pam/01 → pam/28 → [install/HOWTO.md](../install/HOWTO.md) |
| Troubleshoot issue | pam/31 → pam/12 → pam/27 |
| Prepare for audit | pam/33 → pam/08 → pam/50 → pam/30 |
| Review session recordings | pam/50 → pam/08 → pam/32 |
| Set up automation | pam/09 → pam/26 → [examples/](../examples/README.md) |
| Learn OT fundamentals | ot/00-fundamentals (start here for OT basics) |
| Deploy OT zone architecture | ot/01 → ot/02 → ot/03 → ot/09 |
| Configure SCADA access | ot/04 → ot/03 → ot/12 → ot/14 |
| Air-gapped deployment | ot/05 → ot/10 → ot/12 |
| IEC 62443 compliance | ot/06 → pam/48 → pam/33 → ot/13 |

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
