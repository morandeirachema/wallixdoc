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
| 11 | [Monitoring & Observability](./11-monitoring-observability/README.md) | Prometheus, Grafana, alerting, logs |
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

### Enterprise Deployment (24-29)

| # | Section | Description |
|---|---------|-------------|
| 24 | [Deployment Options](./24-cloud-deployment/README.md) | On-premises VMs, bare metal, Terraform IaC |
| 25 | [Container Deployment](./25-container-deployment/README.md) | Not recommended for OT (see VM alternatives) |
| 26 | [API Reference](./26-api-reference/README.md) | Complete REST API documentation |
| 27 | [Error Reference](./27-error-reference/README.md) | Error codes, causes, remediation |
| 28 | [System Requirements](./28-system-requirements/README.md) | Hardware sizing, performance tuning |
| 29 | [Upgrade Guide](./29-upgrade-guide/README.md) | Version upgrades, HA procedures |

### Operations & Compliance (30-34)

| # | Section | Description |
|---|---------|-------------|
| 30 | [Operational Runbooks](./30-operational-runbooks/README.md) | Daily/weekly/monthly procedures |
| 31 | [FAQ & Known Issues](./31-faq-known-issues/README.md) | Common questions, limitations |
| 32 | [Incident Response](./32-incident-response/README.md) | Security playbooks, forensics |
| 33 | [Compliance & Audit](./33-compliance-audit/README.md) | SOC2, ISO27001, PCI-DSS, HIPAA, GDPR |
| 34 | [JIT Access](./34-jit-access/README.md) | Just-In-Time access, approval workflows, time-bounded access |

### Vendor Integration (36)

| # | Section | Description |
|---|---------|-------------|
| 36 | [Vendor-Specific Integration](./36-vendor-integration/README.md) | Cisco, Juniper, Palo Alto, Siemens, ABB, Rockwell, Schneider |

### Advanced Integration (37+)

| # | Section | Description |
|---|---------|-------------|
| 37 | [SIEM Integration](./37-siem-integration/README.md) | Splunk, Elastic, Sentinel, QRadar, CEF/Syslog |
| 38 | [Certificate Management](./38-certificate-management/README.md) | TLS/SSL, CSR generation, renewal, Let's Encrypt, HSM |
| 39 | [Disaster Recovery](./39-disaster-recovery/README.md) | DR runbooks, RTO/RPO, failover procedures, PITR, split-brain |
| 40 | [Backup and Restore](./40-backup-restore/README.md) | Full/selective backup, PITR, offsite storage, disaster recovery |
| 41 | [wabadmin CLI Reference](./41-wabadmin-reference/README.md) | Complete CLI command reference, syntax, examples |
| 43 | [Monitoring and Alerting](./43-monitoring-alerting/README.md) | Prometheus, Grafana, SNMP, health checks, SLA reporting |
| 46 | [Kerberos Authentication](./46-kerberos-authentication/README.md) | Kerberos, SPNEGO, keytab, cross-realm trust, constrained delegation |
| 47 | [Network Configuration](./47-network-validation/README.md) | Network requirements, firewall rules, DNS, NTP, validation procedures |
| 48 | [Compliance Evidence](./48-compliance-evidence/README.md) | Evidence collection, audit artifacts, attestation |
| 49 | [Command Filtering](./49-command-filtering/README.md) | Command whitelisting/blacklisting, regex patterns, blocking |
| 50 | [Session Recording Playback](./50-session-recording-playback/README.md) | Playback, OCR search, forensics, export, integrity verification |
| 51 | [Offline & Sneakernet Operations](./51-offline-operations/README.md) | Air-gapped operations, credential cache, secure media transfer |
| 52 | [FIDO2 & Hardware MFA](./52-fido2-hardware-mfa/README.md) | FIDO2/WebAuthn, YubiKey, smart cards, passwordless, offline MFA |
| 53 | [Account Discovery & Onboarding](./53-account-discovery/README.md) | Discovery scanning, orphaned accounts, bulk import, risk assessment |

---

## Quick Start Paths

### By Role

```
Architect       → 01 → 02 → 10 → 13 → 24
Engineer        → 01 → 03 → 04 → 07 → 09
Security        → 05 → 52 → 06 → 34 → 08 → 50 → 32 → 33
Operations      → 30 → 12 → 27 → 31
OT/Industrial   → 15 → 16 → 17 → 20 → 23
DevOps          → 09 → 26 → 25 → examples/
Compliance      → 33 → 34 → 20 → 08 → 50 → 06
```

### By Task

| Task | Path |
|------|------|
| First deployment | 01 → 28 → [install/HOWTO.md](../install/HOWTO.md) |
| Troubleshoot issue | 31 → 12 → 27 |
| Prepare for audit | 33 → 08 → 50 → 30 |
| Review session recordings | 50 → 08 → 32 |
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
| Deployment | 24-25 | Complete |
| API & Reference | 26-29 | Complete |
| Operations | 30-31 | Complete |
| Compliance | 32-34 | Complete |
| Vendor Integration | 36 | Complete |
| Advanced Integration | 37+ | Complete |

---

<p align="center">
  <sub>49 Sections • 58,000+ Lines • February 2026</sub>
</p>
