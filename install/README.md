# WALLIX Bastion Multi-Site Installation

<p align="center">
  <strong>Production deployment guide for OT/Industrial environments</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/WALLIX-12.1.x-0066cc?style=flat-square" alt="Version"/>
  <img src="https://img.shields.io/badge/Sites-3-green?style=flat-square" alt="Sites"/>
  <img src="https://img.shields.io/badge/Nodes-5-blue?style=flat-square" alt="Nodes"/>
  <img src="https://img.shields.io/badge/IEC_62443-Compliant-228b22?style=flat-square" alt="Compliance"/>
</p>

---

## Overview

| Scope | Details |
|-------|---------|
| **Sites** | 3 (HQ, Plant, Field Office) |
| **Nodes** | 5 total (2+2+1) |
| **HA Modes** | Active-Active, Active-Passive, Standalone |
| **Timeline** | 30 days |

---

## Architecture

```
                    ┌─────────────────────┐
                    │    CORPORATE WAN    │
                    └──────────┬──────────┘
           ┌───────────────────┼───────────────────┐
           │                   │                   │
           ▼                   ▼                   ▼
    ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
    │   SITE A    │     │   SITE B    │     │   SITE C    │
    │     HQ      │     │   Plant     │     │   Field     │
    ├─────────────┤     ├─────────────┤     ├─────────────┤
    │ ┌───┐ ┌───┐ │     │ ┌───┐ ┌───┐ │     │   ┌───┐     │
    │ │N1 │ │N2 │ │     │ │N1 │ │N2 │ │     │   │N1 │     │
    │ └─┬─┘ └─┬─┘ │     │ └─┬─┘ └─┬─┘ │     │   └─┬─┘     │
    │   └──┬──┘   │     │   └──┬──┘   │     │     │       │
    │    [VIP]    │◄───►│    [VIP]    │◄───►│  [Local]    │
    │ Active-Act. │     │ Active-Pass │     │ Standalone  │
    └─────────────┘     └─────────────┘     └─────────────┘
```

| Site | Config | Nodes | HA Mode | Use Case |
|------|--------|-------|---------|----------|
| A | HA Cluster | 2 | Active-Active | Primary management |
| B | HA Cluster | 2 | Active-Passive | DR capability |
| C | Standalone | 1 | N/A | Offline operation |

---

## Documents

| File | Purpose |
|------|---------|
| [HOWTO.md](./HOWTO.md) | Complete step-by-step guide (1700+ lines) |
| [00-debian-luks-installation.md](./00-debian-luks-installation.md) | Debian 12 + LUKS setup |
| [01-prerequisites.md](./01-prerequisites.md) | Requirements checklist |
| [02-site-a-primary.md](./02-site-a-primary.md) | Site A HA cluster |
| [03-site-b-secondary.md](./03-site-b-secondary.md) | Site B HA cluster |
| [04-site-c-remote.md](./04-site-c-remote.md) | Site C standalone |
| [05-multi-site-sync.md](./05-multi-site-sync.md) | Cross-site sync |
| [06-ot-network-config.md](./06-ot-network-config.md) | OT protocols |
| [07-security-hardening.md](./07-security-hardening.md) | Hardening |
| [08-validation-testing.md](./08-validation-testing.md) | Go-live checklist |
| [09-architecture-diagrams.md](./09-architecture-diagrams.md) | Diagrams & ports |
| [10-postgresql-streaming-replication.md](./10-postgresql-streaming-replication.md) | DB HA |

---

## Timeline

```
Week 1          Week 2          Week 3          Week 4
────────────────────────────────────────────────────────
PLANNING        SITE A + B      SITE C + SYNC   HARDENING
• Prerequisites • HA clusters   • Standalone    • Security
• Network       • Basic config  • Multi-site    • Testing
• VMs           • Testing       • OT protocols  • Go-live
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
| PostgreSQL | 15+ |

### Network Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 22 | TCP | SSH access |
| 443 | TCP | Web UI / API |
| 3389 | TCP | RDP proxy |
| 5432 | TCP | PostgreSQL |
| 5404-5406 | UDP | Cluster sync |

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
sudo -u postgres psql -c "SELECT version();"

# Recent audit
wabadmin audit --last 10
```

---

## Security Features

| Category | Features |
|----------|----------|
| Authentication | MFA, LDAP/AD, Kerberos, OIDC/SAML |
| Authorization | RBAC, approval workflows, JIT access |
| Sessions | Recording, keystroke logging, 4-eyes |
| Credentials | Vault, auto-rotation, injection |
| Encryption | AES-256-GCM, TLS 1.3, LUKS, Argon2ID |

---

## Compliance

| Standard | Coverage |
|----------|----------|
| IEC 62443 | Full |
| NIST 800-82 | Full |
| NIS2 | Full |
| ISO 27001 | Partial |
| SOC 2 | Partial |

---

## Resources

| Resource | Link |
|----------|------|
| Documentation | https://pam.wallix.one/documentation |
| Support | https://support.wallix.com |
| Main Docs | [../docs/README.md](../docs/README.md) |

---

<p align="center">
  <a href="./HOWTO.md">Full Guide</a> •
  <a href="./01-prerequisites.md">Prerequisites</a> •
  <a href="./08-validation-testing.md">Validation</a>
</p>
