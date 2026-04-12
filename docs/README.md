# WALLIX Bastion Documentation

> Complete reference for **WALLIX Bastion 12.1.x** with FortiAuthenticator
> MFA — 50 sections covering PAM fundamentals, authentication, session
> management, deployment, operations, compliance, and licensing.
>
> Deployment: 5-site on-premises multi-datacenter, bare metal hardware
> appliances and VMs, MPLS backbone. FortiAuthenticator 6.4+ HA pair per
> site. Access Manager is client-managed.

---

## Documentation Structure

```
docs/
└── pam/    # PAM/WALLIX Core (50 sections, 00-49)
            # Authentication, authorization, password management,
            # session recording, API, deployment, operations,
            # FortiAuthenticator MFA integration, Access Manager, licensing
```

---

## Group 1 — Fundamentals

Core concepts and initial orientation. Start here before anything else.

| # | Section | Description |
|---|---------|-------------|
| 00 | [Official Resources](./pam/00-official-resources/README.md) | Curated links to official WALLIX documentation, PDFs, and support portal |
| 01 | [Quick Start](./pam/01-quick-start/README.md) | First-run walkthrough: UI tour, initial objects, learning path by role |
| 02 | [Introduction](./pam/02-introduction/README.md) | WALLIX company overview, product suite, PAM market positioning vs CyberArk |
| 03 | [Architecture](./pam/03-architecture/README.md) | 5-site MPLS topology, per-site VLAN design, proxy vs agent model, data flows |
| 04 | [Core Components](./pam/04-core-components/README.md) | Session Manager, Password Manager, Access Manager — roles and interactions |
| 05 | [Configuration](./pam/05-configuration/README.md) | Object model (domains, devices, accounts, authorizations), configuration walkthroughs |

---

## Group 2 — Authentication & Identity

How users prove their identity to WALLIX Bastion and how the MFA chain works.

| # | Section | Description |
|---|---------|-------------|
| 06 | [Authentication](./pam/06-authentication/README.md) | LDAP/AD per-site, RADIUS/FortiAuth TOTP chain, Kerberos SSO, SAML, OIDC |
| 07 | [Authorization](./pam/07-authorization/README.md) | RBAC, access policies, approval workflows, time windows, JIT |
| 34 | [LDAP/AD Integration](./pam/34-ldap-ad-integration/README.md) | Per-site AD DC (Cyber VLAN), LDAPS over Fortigate, group sync, troubleshooting |
| 35 | [Kerberos Authentication](./pam/35-kerberos-authentication/README.md) | Kerberos SPNEGO, keytab generation, cross-realm trust, Windows SSO |
| 49 | [AD + FortiAuthenticator 2FA](./pam/49-ad-fortiauthenticator-2fa/README.md) | End-to-end 2FA integration: LDAP Phase 1 + TOTP Phase 2 via FortiAuth 6.4+ |

---

## Group 3 — Session & Credential Management

How sessions are proxied, recorded, and credentials are stored and injected.

| # | Section | Description |
|---|---------|-------------|
| 08 | [Password Management](./pam/08-password-management/README.md) | Credential vault (AES-256), automatic rotation, checkout/checkin workflows |
| 09 | [Session Management](./pam/09-session-management/README.md) | Session recording, real-time monitoring, keystroke logging, audit trail |
| 38 | [Command Filtering](./pam/38-command-filtering/README.md) | Command whitelisting/blacklisting, regex patterns, SSH and RDP restrictions |
| 39 | [Session Recording Playback](./pam/39-session-recording-playback/README.md) | Playback controls, OCR text search, forensic export, retention policies |
| 43 | [Session Sharing & Collaboration](./pam/43-session-sharing/README.md) | Multi-user session sharing, dual-control (4-eyes), supervisor monitoring |

---

## Group 4 — Deployment & Infrastructure

Installing, sizing, and configuring the Bastion infrastructure.

| # | Section | Description |
|---|---------|-------------|
| 11 | [High Availability](./pam/11-high-availability/README.md) | Active-Active and Active-Passive HA models, Pacemaker/Corosync, MariaDB replication |
| 16 | [Deployment Options](./pam/16-cloud-deployment/README.md) | On-premises deployment patterns: bare metal appliances and VMs only |
| 19 | [System Requirements](./pam/19-system-requirements/README.md) | Hardware sizing, CPU/RAM/disk for each component, capacity planning |
| 20 | [Upgrade Guide](./pam/20-upgrade-guide/README.md) | Version upgrade procedures, HA cluster rolling upgrades, pre/post checks |
| 32 | [Load Balancer Configuration](./pam/32-load-balancer/README.md) | HAProxy Active-Passive with Keepalived VRRP, health checks, SSL termination |
| 36 | [Network Configuration](./pam/36-network-validation/README.md) | Firewall rules (Fortigate inter-VLAN), DNS, NTP, connectivity validation |

---

## Group 5 — Access Manager & Licensing

Access Manager integration (client-managed) and WALLIX licensing.

| # | Section | Description |
|---|---------|-------------|
| 46 | [Access Manager](./pam/46-access-manager/README.md) | AM overview, client-managed scope, Bastion-side API user and key provisioning |
| 47 | [Licensing Guide](./pam/47-licensing/README.md) | Licensing models (Session, Password, Discovery), HA licensing, multi-site activation |
| 48 | [AM Bastion Connectivity](./pam/48-access-manager-bastion-connectivity/README.md) | Bastion-side API integration, SAML SP config, session brokering, HA routing |

---

## Group 6 — Operations & Monitoring

Day-to-day administration, monitoring, troubleshooting, and CLI reference.

| # | Section | Description |
|---|---------|-------------|
| 10 | [API & Automation](./pam/10-api-automation/README.md) | REST API usage, scripting with Python/Ansible/Terraform, DevOps integration |
| 12 | [Monitoring & Observability](./pam/12-monitoring-observability/README.md) | Prometheus metrics, Grafana dashboards, Alertmanager, SIEM log forwarding |
| 13 | [Troubleshooting](./pam/13-troubleshooting/README.md) | Diagnostic procedures, log analysis, LDAP/AD and certificate issue resolution |
| 14 | [Best Practices](./pam/14-best-practices/README.md) | Security hardening checklist, operational design patterns, configuration hygiene |
| 21 | [Operational Runbooks](./pam/21-operational-runbooks/README.md) | Daily/weekly/monthly procedures, alert escalation, failover testing, break-glass |
| 22 | [FAQ & Known Issues](./pam/22-faq-known-issues/README.md) | Common questions, known limitations, compatibility notes |
| 31 | [wabadmin CLI Reference](./pam/31-wabadmin-reference/README.md) | Complete wabadmin command reference: syntax, flags, examples, output formats |

---

## Group 7 — Compliance & Security

Audit evidence, compliance frameworks, incident response, and JIT access.

| # | Section | Description |
|---|---------|-------------|
| 23 | [Incident Response](./pam/23-incident-response/README.md) | Security incident playbooks, account compromise, session termination procedures |
| 24 | [Compliance & Audit](./pam/24-compliance-audit/README.md) | SOC 2 Type II, ISO 27001, NIS2, PCI-DSS, HIPAA — control mapping and evidence |
| 25 | [JIT Access](./pam/25-jit-access/README.md) | Just-In-Time privileged access, time-bounded grants, approval workflow design |
| 37 | [Compliance Evidence](./pam/37-compliance-evidence/README.md) | Evidence collection procedures, audit artifact packaging, attestation sign-off |

---

## Group 8 — Advanced Features

Account lifecycle management, SSH key governance, automation, and self-service.

| # | Section | Description |
|---|---------|-------------|
| 27 | [Vendor-Specific Integration](./pam/27-vendor-integration/README.md) | Cisco IOS/NX-OS, Microsoft Windows Server 2022, Red Hat RHEL 9/10 specifics |
| 40 | [Account Discovery & Onboarding](./pam/40-account-discovery/README.md) | Discovery scanning, orphaned account detection, bulk import via CSV |
| 41 | [SSH Key Lifecycle](./pam/41-ssh-key-lifecycle/README.md) | SSH key generation, rotation, revocation, CA-based trust, HSM integration |
| 42 | [Service Account Lifecycle](./pam/42-service-account-lifecycle/README.md) | Service account governance, rotation scheduling, decommissioning procedures |
| 44 | [User Self-Service Portal](./pam/44-user-self-service/README.md) | Self-service password management, MFA enrollment, credential checkout request |
| 45 | [Privileged Task Automation](./pam/45-privileged-task-automation/README.md) | Automated privileged operations, scheduled runbooks, service account scripting |

---

## Group 9 — Performance & Recovery

Capacity, certificates, disaster recovery, backup, and rotation troubleshooting.

| # | Section | Description |
|---|---------|-------------|
| 26 | [Performance Benchmarks](./pam/26-performance-benchmarks/README.md) | Session throughput benchmarks, capacity planning, load test results |
| 28 | [Certificate Management](./pam/28-certificate-management/README.md) | TLS/SSL lifecycle: CSR generation, CA signing, renewal, Let's Encrypt, HSM |
| 29 | [Disaster Recovery](./pam/29-disaster-recovery/README.md) | DR runbooks, RTO/RPO targets, failover procedures, point-in-time recovery |
| 30 | [Backup and Restore](./pam/30-backup-restore/README.md) | Full and selective backup procedures, offsite storage, restore validation |
| 33 | [Password Rotation Troubleshooting](./pam/33-password-rotation-troubleshooting/README.md) | Rotation failure diagnosis, SSH key rotation issues, custom rotation scripts |

---

## Group 10 — Reference

Glossary, complete API reference, and error code catalog.

| # | Section | Description |
|---|---------|-------------|
| 15 | [Appendix](./pam/15-appendix/README.md) | Glossary of PAM terms, quick reference cards, CyberArk-to-WALLIX comparison |
| 17 | [API Reference](./pam/17-api-reference/README.md) | Complete REST API documentation: endpoints, parameters, request/response examples |
| 18 | [Error Reference](./pam/18-error-reference/README.md) | Error codes catalog with causes, log locations, and remediation steps |

---

## Quick Start Paths

### By Role

| Role | Recommended Path |
|------|-----------------|
| **Architect** | 02 → 03 → 11 → 16 → 19 → 32 → [install/README.md](../install/README.md) |
| **Deployment Engineer** | 03 → 04 → 05 → 11 → 32 → 36 → [install/HOWTO.md](../install/HOWTO.md) |
| **Security Engineer** | 06 → 34 → 49 → 07 → 25 → 09 → 39 → 23 → 24 |
| **Operations** | 21 → 13 → 14 → 18 → 31 → 12 |
| **DevOps / Automation** | 10 → 17 → [examples/](../examples/README.md) |
| **Compliance Officer** | 24 → 37 → 25 → 09 → 39 → 07 |
| **Access Manager Team** | 46 → 48 → [install/03-access-manager-integration.md](../install/03-access-manager-integration.md) |

### By Task

| Task | Path |
|------|------|
| First deployment (5-site) | 02 → 19 → [install/HOWTO.md](../install/HOWTO.md) |
| Set up FortiAuthenticator MFA | 06 → 49 → [pre/04-fortiauthenticator-setup.md](../pre/04-fortiauthenticator-setup.md) |
| Configure per-site AD/LDAP | 06 → 34 → [pre/06-ad-integration.md](../pre/06-ad-integration.md) |
| Register Bastion with Access Manager | 46 → 48 → [install/03-access-manager-integration.md](../install/03-access-manager-integration.md) |
| Set up HA cluster | 11 → 32 → [install/06-bastion-active-active.md](../install/06-bastion-active-active.md) |
| Prepare for audit | 24 → 37 → 09 → 39 → 21 |
| Troubleshoot authentication | 06 → 34 → 13 → 31 |
| Review session recordings | 39 → 09 → 23 |
| Configure backup and DR | 30 → 29 → [install/12-contingency-plan.md](../install/12-contingency-plan.md) |
| Automate with REST API | 10 → 17 → [examples/](../examples/README.md) |

---

## Version Coverage

| Component | Version | Notes |
|-----------|---------|-------|
| **WALLIX Bastion** | 12.1.x | On-premises, bare metal hardware appliances and VMs |
| **FortiAuthenticator** | 6.4+ | Per-site HA pair in Cyber VLAN — TOTP only via FortiToken Mobile |
| **HAProxy** | 2.8+ | Active-Passive per site with Keepalived VRRP |
| **MariaDB** | 10.11+ | Galera/replication for Bastion HA clustering |
| **Last Updated** | April 2026 | |

---

## Conventions

| Symbol | Meaning |
|--------|---------|
| `code` | Commands, configuration snippets, API calls |
| **Bold** | Important terms, UI element names |
| > Quote | Tips, warnings, and contextual notes |
| [CLIENT TEAM] | Action performed by the client's team, not us |
| [OUR SCOPE] | Action performed by our deployment team |

---

## Coverage Summary

| Category | Sections | Location |
|----------|----------|----------|
| PAM Core | 50 (00–49) | docs/pam/ |
| Installation Guide | 14 | install/ |
| Pre-Production Lab | 13 | pre/ |
| Automation Examples | 3 | examples/ |
| **Total PAM sections** | **50** | |

---

<p align="center">
  <sub>50 Sections • WALLIX Bastion 12.1.x • FortiAuthenticator 6.4+ • April 2026</sub>
</p>
