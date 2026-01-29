# WALLIX PAM4OT Documentation

> Complete reference for **PAM4OT** (Privileged Access Management for OT) — 34 sections covering PAM fundamentals, industrial/OT security, cloud deployment, operations, and compliance.
>
> PAM4OT is built on WALLIX Bastion 12.x technology, specifically designed for operational technology environments.

---

## Documentation Map

### Core PAM (01-14)

| # | Section | Description |
|---|---------|-------------|
| 00 | [Official Resources](./00-official-resources/README.md) | Curated links to official WALLIX docs and PDFs |
| 01 | [Introduction](./01-introduction/README.md) | WALLIX overview, product suite, market positioning |
| 02 | [Architecture](./02-architecture/README.md) | Deployment models, component architecture |
| 03 | [Core Components](./03-core-components/README.md) | Session Manager, Password Manager, Access Manager |
| 04 | [Configuration](./04-configuration/README.md) | Object model, domains, devices, accounts |
| 05 | [Authentication](./05-authentication/README.md) | MFA, SSO, LDAP/AD, OIDC/SAML, Kerberos |
| 06 | [Authorization](./06-authorization/README.md) | RBAC, approval workflows, time windows |
| 07 | [Password Management](./07-password-management/README.md) | Vault, rotation, checkout workflows |
| 08 | [Session Management](./08-session-management/README.md) | Recording, monitoring, audit trails |
| 09 | [API & Automation](./09-api-automation/README.md) | REST API, scripting, DevOps integration |
| 10 | [High Availability](./10-high-availability/README.md) | Clustering, DR, backup, failover |
| 12 | [Troubleshooting](./12-troubleshooting/README.md) | Diagnostics, common issues, log analysis |
| 13 | [Best Practices](./13-best-practices/README.md) | Security hardening, design patterns |
| 14 | [Appendix](./14-appendix/README.md) | Glossary, quick reference, cheat sheets |

### Industrial / OT Security (15-23)

| # | Section | Description |
|---|---------|-------------|
| 15 | [Industrial Overview](./15-industrial-overview/README.md) | OT vs IT security, regulatory landscape |
| 16 | [OT Architecture](./16-ot-architecture/README.md) | Zone deployment, IEC 62443 zones 0-5 |
| 17 | [Industrial Protocols](./17-industrial-protocols/README.md) | Modbus, DNP3, OPC UA, IEC 61850, S7comm |
| 18 | [SCADA/ICS Access](./18-scada-ics-access/README.md) | HMI, PLC programming, vendor maintenance |
| 19 | [Air-Gapped Environments](./19-airgapped-environments/README.md) | Isolated deployments, data diodes |
| 20 | [IEC 62443 Compliance](./20-iec62443-compliance/README.md) | Security levels SL1-4, audit evidence |
| 21 | [Industrial Use Cases](./21-industrial-use-cases/README.md) | Power, Oil & Gas, Manufacturing, Water |
| 22 | [OT Integration](./22-ot-integration/README.md) | SIEM, CMDB, monitoring platforms |
| 23 | [Industrial Best Practices](./23-industrial-best-practices/README.md) | OT security design, incident response |

### Enterprise & Cloud (24-29)

| # | Section | Description |
|---|---------|-------------|
| 24 | [Cloud Deployment](./24-cloud-deployment/README.md) | AWS, Azure, GCP, Terraform IaC |
| 25 | [Container Deployment](./25-container-deployment/README.md) | Docker, Kubernetes, Helm, OpenShift |
| 26 | [API Reference](./26-api-reference/README.md) | Complete REST API documentation |
| 27 | [Error Reference](./27-error-reference/README.md) | Error codes, causes, remediation |
| 28 | [System Requirements](./28-system-requirements/README.md) | Hardware sizing, performance tuning |
| 29 | [Upgrade Guide](./29-upgrade-guide/README.md) | Version upgrades, HA procedures |

### Operations & Compliance (30-33)

| # | Section | Description |
|---|---------|-------------|
| 30 | [Operational Runbooks](./30-operational-runbooks/README.md) | Daily/weekly/monthly procedures |
| 31 | [FAQ & Known Issues](./31-faq-known-issues/README.md) | Common questions, limitations |
| 32 | [Incident Response](./32-incident-response/README.md) | Security playbooks, forensics |
| 33 | [Compliance & Audit](./33-compliance-audit/README.md) | SOC2, ISO27001, PCI-DSS, HIPAA, GDPR |

---

## Quick Start Paths

### By Role

```
Architect       → 01 → 02 → 10 → 13 → 24
Engineer        → 01 → 03 → 04 → 07 → 09
Security        → 05 → 06 → 08 → 32 → 33
Operations      → 30 → 12 → 27 → 31
OT/Industrial   → 15 → 16 → 17 → 20 → 23
DevOps          → 09 → 26 → 25 → examples/
Compliance      → 33 → 20 → 08 → 06
```

### By Task

| Task | Path |
|------|------|
| First deployment | 01 → 28 → [install/HOWTO.md](../install/HOWTO.md) |
| Troubleshoot issue | 31 → 12 → 27 |
| Prepare for audit | 33 → 08 → 30 |
| Set up automation | 09 → 26 → [examples/](../examples/README.md) |

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

| Category | Sections | Status |
|----------|----------|--------|
| Core PAM | 01-14 | Complete |
| Industrial/OT | 15-23 | Complete |
| Cloud/Container | 24-25 | Complete |
| API & Reference | 26-29 | Complete |
| Operations | 30-31 | Complete |
| Compliance | 32-33 | Complete |

---

<p align="center">
  <sub>34 Sections • 38,000+ Lines • January 2026</sub>
</p>
