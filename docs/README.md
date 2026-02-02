# WALLIX Bastion Documentation

> Complete reference for **WALLIX Bastion** with Fortigate MFA — 47 sections covering PAM fundamentals, authentication, session management, deployment, operations, and compliance.
>
> Built on WALLIX Bastion 12.x technology with integrated Fortinet multi-factor authentication.

---

## Documentation Structure

This documentation is organized in a single PAM category:

```
docs/
└── pam/    # PAM/WALLIX Core (47 sections)
            # Authentication, authorization, password management,
            # session recording, API, deployment, operations,
            # Fortigate MFA integration
```

---

## PAM / WALLIX Core Documentation

### Getting Started (00-05)

| # | Section | Description |
|---|---------|-------------|
| 00 | [Official Resources](./pam/00-official-resources/README.md) | Curated links to official WALLIX docs and PDFs |
| 01 | [Quick Start](./pam/01-quick-start/README.md) | Quick installation and configuration guide |
| 02 | [Introduction](./pam/02-introduction/README.md) | WALLIX overview, product suite, market positioning |
| 03 | [Architecture](./pam/03-architecture/README.md) | Deployment models, component architecture |
| 04 | [Core Components](./pam/04-core-components/README.md) | Session Manager, Password Manager, Access Manager |
| 05 | [Configuration](./pam/05-configuration/README.md) | Object model, domains, devices, accounts |

### Authentication & Authorization (06-07)

| # | Section | Description |
|---|---------|-------------|
| 06 | [Authentication](./pam/06-authentication/README.md) | MFA, SSO, LDAP/AD, OIDC/SAML, Kerberos, FortiAuthenticator |
| 07 | [Authorization](./pam/07-authorization/README.md) | RBAC, approval workflows, time windows |

### Credential & Session Management (08-09)

| # | Section | Description |
|---|---------|-------------|
| 08 | [Password Management](./pam/08-password-management/README.md) | Vault, rotation, checkout workflows |
| 09 | [Session Management](./pam/09-session-management/README.md) | Recording, monitoring, audit trails |

### API & Automation (10)

| # | Section | Description |
|---|---------|-------------|
| 10 | [API & Automation](./pam/10-api-automation/README.md) | REST API, scripting, DevOps integration |

### Infrastructure & High Availability (11-14)

| # | Section | Description |
|---|---------|-------------|
| 11 | [High Availability](./pam/11-high-availability/README.md) | Clustering, DR, backup, failover |
| 12 | [Monitoring & Observability](./pam/12-monitoring-observability/README.md) | Prometheus, Grafana, alerting, logs |
| 13 | [Troubleshooting](./pam/13-troubleshooting/README.md) | Diagnostics, common issues, log analysis |
| 14 | [Best Practices](./pam/14-best-practices/README.md) | Security hardening, design patterns |

### Reference & Appendix (15-22)

| # | Section | Description |
|---|---------|-------------|
| 15 | [Appendix](./pam/15-appendix/README.md) | Glossary, quick reference, cheat sheets |
| 16 | [Deployment Options](./pam/16-cloud-deployment/README.md) | On-premises VMs, bare metal, Terraform IaC |
| 17 | [API Reference](./pam/17-api-reference/README.md) | Complete REST API documentation |
| 18 | [Error Reference](./pam/18-error-reference/README.md) | Error codes, causes, remediation |
| 19 | [System Requirements](./pam/19-system-requirements/README.md) | Hardware sizing, performance tuning |
| 20 | [Upgrade Guide](./pam/20-upgrade-guide/README.md) | Version upgrades, HA procedures |
| 21 | [Operational Runbooks](./pam/21-operational-runbooks/README.md) | Daily/weekly/monthly procedures |
| 22 | [FAQ & Known Issues](./pam/22-faq-known-issues/README.md) | Common questions, limitations |

### Compliance & Incident Response (23-25)

| # | Section | Description |
|---|---------|-------------|
| 23 | [Incident Response](./pam/23-incident-response/README.md) | Security playbooks, forensics |
| 24 | [Compliance & Audit](./pam/24-compliance-audit/README.md) | SOC2, ISO27001, PCI-DSS, HIPAA, GDPR |
| 25 | [JIT Access](./pam/25-jit-access/README.md) | Just-In-Time access, approval workflows, time-bounded access |

### Performance & Infrastructure (26-32)

| # | Section | Description |
|---|---------|-------------|
| 26 | [Performance Benchmarks](./pam/26-performance-benchmarks/README.md) | Capacity planning, load testing, optimization |
| 27 | [Vendor-Specific Integration](./pam/27-vendor-integration/README.md) | Cisco, Microsoft, Red Hat |
| 28 | [Certificate Management](./pam/28-certificate-management/README.md) | TLS/SSL, CSR generation, renewal, Let's Encrypt, HSM |
| 29 | [Disaster Recovery](./pam/29-disaster-recovery/README.md) | DR runbooks, RTO/RPO, failover procedures, PITR |
| 30 | [Backup and Restore](./pam/30-backup-restore/README.md) | Full/selective backup, PITR, offsite storage |
| 31 | [wabadmin CLI Reference](./pam/31-wabadmin-reference/README.md) | Complete CLI command reference, syntax, examples |
| 32 | [Load Balancer Configuration](./pam/32-load-balancer/README.md) | HAProxy, Nginx, F5, health checks, SSL termination |

### Advanced Authentication (33-40)

| # | Section | Description |
|---|---------|-------------|
| 33 | [Password Rotation Troubleshooting](./pam/33-password-rotation-troubleshooting/README.md) | Rotation failures, SSH keys, custom scripts |
| 34 | [LDAP/AD Integration](./pam/34-ldap-ad-integration/README.md) | Active Directory, LDAP sync, group mapping |
| 35 | [Kerberos Authentication](./pam/35-kerberos-authentication/README.md) | Kerberos, SPNEGO, keytab, cross-realm trust |
| 36 | [Network Configuration](./pam/36-network-validation/README.md) | Firewall rules, DNS, NTP, validation procedures |
| 37 | [Compliance Evidence](./pam/37-compliance-evidence/README.md) | Evidence collection, audit artifacts, attestation |
| 38 | [Command Filtering](./pam/38-command-filtering/README.md) | Command whitelisting/blacklisting, regex patterns |
| 39 | [Session Recording Playback](./pam/39-session-recording-playback/README.md) | Playback, OCR search, forensics, export |
| 40 | [FIDO2 & Hardware MFA](./pam/40-fido2-hardware-mfa/README.md) | FIDO2/WebAuthn, YubiKey, smart cards, passwordless |

### Advanced Features (41-47)

| # | Section | Description |
|---|---------|-------------|
| 41 | [Account Discovery & Onboarding](./pam/41-account-discovery/README.md) | Discovery scanning, orphaned accounts, bulk import |
| 42 | [SSH Key Lifecycle](./pam/42-ssh-key-lifecycle/README.md) | SSH key generation, rotation, revocation, CA, HSM |
| 43 | [Service Account Lifecycle](./pam/43-service-account-lifecycle/README.md) | Service account governance, rotation, decommissioning |
| 44 | [Session Sharing & Collaboration](./pam/44-session-sharing/README.md) | Multi-user sessions, dual-control, training |
| 45 | [User Self-Service Portal](./pam/45-user-self-service/README.md) | Password management, MFA enrollment, credential checkout |
| 46 | [Privileged Task Automation](./pam/46-privileged-task-automation/README.md) | Automated privileged tasks, service accounts, runbooks |
| 47 | [Fortigate Integration](./pam/47-fortigate-integration/README.md) | Fortigate firewall, FortiAuthenticator MFA, SSL VPN |

---

## Quick Start Paths

### By Role

```
Architect       → pam/02 → pam/03 → pam/11 → pam/14 → pam/16
Engineer        → pam/02 → pam/04 → pam/05 → pam/08 → pam/10
Security        → pam/06 → pam/47 → pam/40 → pam/07 → pam/25 → pam/09 → pam/39 → pam/23
Operations      → pam/21 → pam/13 → pam/18 → pam/31
DevOps          → pam/10 → pam/17 → examples/
Compliance      → pam/24 → pam/25 → pam/09 → pam/39 → pam/07
```

### By Task

| Task | Path |
|------|------|
| First deployment | pam/02 → pam/19 → [install/HOWTO.md](../install/HOWTO.md) |
| Troubleshoot issue | pam/31 → pam/13 → pam/18 |
| Prepare for audit | pam/24 → pam/09 → pam/39 → pam/21 |
| Review session recordings | pam/39 → pam/09 → pam/23 |
| Set up automation | pam/10 → pam/17 → [examples/](../examples/README.md) |
| Configure Fortigate MFA | pam/06 → pam/47 → [pre/04-fortiauthenticator-setup.md](../pre/04-fortiauthenticator-setup.md) |

---

## Version Coverage

| Product | Version |
|---------|---------|
| WALLIX Bastion | 12.x (12.0, 12.1.x) |
| WALLIX Access Manager | 5.x |
| WALLIX PEDM | 3.x |
| FortiAuthenticator | 6.4+ |

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
| **Total** | **47** | | **Complete** |

---

<p align="center">
  <sub>47 Sections • PAM with Fortigate MFA • February 2026</sub>
</p>
