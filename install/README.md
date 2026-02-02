# WALLIX Bastion Multi-Site Installation

<p align="center">
  <strong>Production deployment guide with Fortigate MFA integration</strong><br/>
  <sub>Powered by WALLIX Bastion 12.x</sub>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/WALLIX-12.1.x-0066cc?style=flat-square" alt="Version"/>
  <img src="https://img.shields.io/badge/Sites-4-green?style=flat-square" alt="Sites"/>
  <img src="https://img.shields.io/badge/Nodes-8-blue?style=flat-square" alt="Nodes"/>
  <img src="https://img.shields.io/badge/Fortigate-MFA-ee3124?style=flat-square" alt="Fortigate"/>
</p>

---

## Overview

| Scope | Details |
|-------|---------|
| **Sites** | 4 (synchronized within single CPD) |
| **Nodes** | 8 total (2 per site) |
| **HA Modes** | Active-Active at each site |
| **MFA** | Fortigate with FortiAuthenticator |
| **Timeline** | 30 days |

---

## Architecture

### 4-Site Synchronized Architecture (Single CPD)

```
+===============================================================================+
|  4-SITE SYNCHRONIZED ARCHITECTURE (Single CPD)                                |
+===============================================================================+
|                                                                               |
|                            +------------------+                               |
|                            | FortiAuthenticator|                              |
|                            |   (MFA Server)   |                               |
|                            +--------+---------+                               |
|                                     | RADIUS                                  |
|        +-------------+-------------+-------------+-------------+              |
|        |             |             |             |             |              |
|  +-----v-----+ +-----v-----+ +-----v-----+ +-----v-----+                      |
|  | Fortigate | | Fortigate | | Fortigate | | Fortigate |                      |
|  |  Site 1   | |  Site 2   | |  Site 3   | |  Site 4   |                      |
|  +-----+-----+ +-----+-----+ +-----+-----+ +-----+-----+                      |
|        |             |             |             |                            |
|  +-----v-----+ +-----v-----+ +-----v-----+ +-----v-----+                      |
|  | HAProxy   | | HAProxy   | | HAProxy   | | HAProxy   |                      |
|  | 1a + 1b   | | 2a + 2b   | | 3a + 3b   | | 4a + 4b   |                      |
|  | (HA/VRRP) | | (HA/VRRP) | | (HA/VRRP) | | (HA/VRRP) |                      |
|  +-----+-----+ +-----+-----+ +-----+-----+ +-----+-----+                      |
|        |             |             |             |                            |
|  +-----v-----+ +-----v-----+ +-----v-----+ +-----v-----+                      |
|  | WALLIX    | | WALLIX    | | WALLIX    | | WALLIX    |                      |
|  | Bastion   | | Bastion   | | Bastion   | | Bastion   |                      |
|  | 1a + 1b   | | 2a + 2b   | | 3a + 3b   | | 4a + 4b   |                      |
|  | (HA)      | | (HA)      | | (HA)      | | (HA)      |                      |
|  +-----+-----+ +-----+-----+ +-----+-----+ +-----+-----+                      |
|        |             |             |             |                            |
|  +-----v-----+ +-----v-----+ +-----v-----+ +-----v-----+                      |
|  | WALLIX    | | WALLIX    | | WALLIX    | | WALLIX    |                      |
|  |   RDS     | |   RDS     | |   RDS     | |   RDS     |                      |
|  +-----+-----+ +-----+-----+ +-----+-----+ +-----+-----+                      |
|        |             |             |             |                            |
|  +-----v-----+ +-----v-----+ +-----v-----+ +-----v-----+                      |
|  | Windows   | | Windows   | | Windows   | | Windows   |                      |
|  | RHEL 10/9 | | RHEL 10/9 | | RHEL 10/9 | | RHEL 10/9 |                      |
|  +-----------+ +-----------+ +-----------+ +-----------+                      |
|                                                                               |
|  <====================== MULTI-SITE SYNC (HTTPS 443) ======================>  |
|                                                                               |
+===============================================================================+
```

| Site | Config | Nodes | HA Mode | Target Systems |
|------|--------|-------|---------|----------------|
| 1 | HA Cluster | 2 | Active-Active | Windows Server 2022, RHEL 10/9 |
| 2 | HA Cluster | 2 | Active-Active | Windows Server 2022, RHEL 10/9 |
| 3 | HA Cluster | 2 | Active-Active | Windows Server 2022, RHEL 10/9 |
| 4 | HA Cluster | 2 | Active-Active | Windows Server 2022, RHEL 10/9 |

---

## Documents

| File | Purpose |
|------|---------|
| [HOWTO.md](./HOWTO.md) | Complete step-by-step guide |
| [00-debian-luks-installation.md](./00-debian-luks-installation.md) | Debian 12 + LUKS setup |
| [01-prerequisites.md](./01-prerequisites.md) | Requirements checklist |
| [02-site-a-primary.md](./02-site-a-primary.md) | Site 1 HA cluster |
| [03-site-b-secondary.md](./03-site-b-secondary.md) | Site 2 HA cluster |
| [05-multi-site-sync.md](./05-multi-site-sync.md) | Cross-site sync |
| [07-security-hardening.md](./07-security-hardening.md) | Hardening |
| [08-validation-testing.md](./08-validation-testing.md) | Go-live checklist |
| [09-architecture-diagrams.md](./09-architecture-diagrams.md) | Diagrams & ports |
| [10-mariadb-replication.md](./10-mariadb-replication.md) | DB HA |

---

## Timeline

```
Week 1          Week 2          Week 3          Week 4
────────────────────────────────────────────────────────
PLANNING        SITES 1 + 2     SITES 3 + 4     HARDENING
• Prerequisites • HA clusters   • HA clusters   • Security
• Network       • Fortigate MFA • Multi-site    • Testing
• VMs           • Testing       • sync          • Go-live
```

---

## Requirements

### Hardware (per node)

| Spec | Minimum | Recommended |
|------|---------|-------------|
| CPU | 4 vCPU | 8 vCPU |
| RAM | 8 GB | 16 GB |
| OS Disk | 100 GB SSD | 200 GB NVMe |
| Data Disk | 250 GB SSD | 500 GB NVMe |

### Software

| Component | Version |
|-----------|---------|
| WALLIX Bastion | 12.1.x |
| Debian | 12 (Bookworm) |
| MariaDB | 10.11+ |
| FortiAuthenticator | 6.4+ |

### Network Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 22 | TCP | SSH access |
| 443 | TCP | Web UI / API |
| 3389 | TCP | RDP proxy |
| 3306 | TCP | MariaDB |
| 5404-5406 | UDP | Cluster sync |
| 1812/1813 | UDP | RADIUS (FortiAuth) |

---

## Quick Start

```bash
# 1. Check prerequisites
cat 01-prerequisites.md

# 2. Follow main guide
cat HOWTO.md

# 3. Verify installation
systemctl status wallix-bastion
wabadmin status
crm status  # HA only
```

---

## Verification Commands

```bash
# Service status
systemctl status wallix-bastion

# Cluster health (HA)
crm status

# License check
wabadmin license-info

# Database
sudo -u postgres psql -c "SELECT * FROM pg_stat_replication;"

# Recent audit
wabadmin audit --last 10
```

---

## Security Features

| Category | Features |
|----------|----------|
| Authentication | Fortigate MFA, LDAP/AD, Kerberos, OIDC/SAML |
| Authorization | RBAC, approval workflows, JIT access |
| Sessions | Recording, keystroke logging, 4-eyes |
| Credentials | Vault, auto-rotation, injection |
| Encryption | AES-256-GCM, TLS 1.3, LUKS, Argon2ID |

---

## Compliance

| Standard | Coverage |
|----------|----------|
| ISO 27001 | Full |
| SOC 2 Type II | Full |
| NIS2 | Full |
| PCI-DSS | Full |
| HIPAA | Partial |

---

## Resources

| Resource | Link |
|----------|------|
| Documentation | https://pam.wallix.one/documentation |
| Support | https://support.wallix.com |
| Main Docs | [../docs/README.md](../docs/README.md) |

---

## Next Steps

After completing installation:

| Step | Document |
|------|----------|
| Configure authentication | [Authentication Guide](../docs/pam/06-authentication/README.md) |
| Configure Fortigate MFA | [Fortigate Integration](../docs/pam/47-fortigate-integration/README.md) |
| Set up monitoring | [Monitoring & Observability](../docs/pam/12-monitoring-observability/README.md) |
| Review best practices | [Best Practices](../docs/pam/14-best-practices/README.md) |
| Set up operational procedures | [Operational Runbooks](../docs/pam/21-operational-runbooks/README.md) |

For pre-production testing, see the [Pre-Production Lab Guide](../pre/README.md).

---

<p align="center">
  <a href="./HOWTO.md">Full Guide</a> •
  <a href="./01-prerequisites.md">Prerequisites</a> •
  <a href="./08-validation-testing.md">Validation</a>
</p>
