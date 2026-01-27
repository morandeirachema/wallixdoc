# WALLIX Bastion 12.x - Multi-Site OT Installation Guide

<p align="center">
  <strong>Enterprise Privileged Access Management for Industrial Environments</strong>
</p>

<p align="center">
  <a href="#overview">Overview</a> •
  <a href="#architecture">Architecture</a> •
  <a href="#quick-start">Quick Start</a> •
  <a href="#documentation">Documentation</a> •
  <a href="#compliance">Compliance</a>
</p>

---

## Overview

This repository provides comprehensive installation and configuration documentation for deploying **WALLIX Bastion 12.x** in a multi-site Operational Technology (OT) environment.

### Deployment Scope

| Site | Role | Configuration | Purpose |
|------|------|---------------|---------|
| **Site A** | Primary HQ | HA Cluster (Active-Active) | Central management, primary access |
| **Site B** | Secondary Plant | HA Cluster (Active-Passive) | Regional access, failover capability |
| **Site C** | Remote Field | Standalone (Offline-capable) | Edge site, limited connectivity |

### Key Features

- **High Availability** - Pacemaker/Corosync clustering with automatic failover
- **Multi-Site Synchronization** - Centralized policy management with distributed enforcement
- **OT Protocol Support** - Universal tunneling for Modbus, S7comm, OPC UA, and more
- **Offline Capability** - Cached authentication for air-gapped environments
- **IEC 62443 Compliance** - Built-in security controls for industrial environments

---

## Architecture

```
                           CORPORATE NETWORK
                                  │
           ┌──────────────────────┼──────────────────────┐
           │                      │                      │
    ┌──────┴──────┐        ┌──────┴──────┐        ┌──────┴──────┐
    │   SITE A    │        │   SITE B    │        │   SITE C    │
    │   PRIMARY   │        │  SECONDARY  │        │   REMOTE    │
    │             │        │             │        │             │
    │ ┌─────────┐ │        │ ┌─────────┐ │        │ ┌─────────┐ │
    │ │ WALLIX  │ │◄──────►│ │ WALLIX  │ │◄──────►│ │ WALLIX  │ │
    │ │  (HA)   │ │  Sync  │ │  (HA)   │ │  Sync  │ │(Standal)│ │
    │ └────┬────┘ │        │ └────┬────┘ │        │ └────┬────┘ │
    │      │      │        │      │      │        │      │      │
    │ ┌────┴────┐ │        │ ┌────┴────┐ │        │ ┌────┴────┐ │
    │ │   OT    │ │        │ │   OT    │ │        │ │   OT    │ │
    │ │ NETWORK │ │        │ │ NETWORK │ │        │ │ NETWORK │ │
    │ └─────────┘ │        │ └─────────┘ │        │ └─────────┘ │
    └─────────────┘        └─────────────┘        └─────────────┘
```

---

## Quick Start

### Prerequisites

- **Debian 12 (Bookworm)** - Required for WALLIX 12.x
- **PostgreSQL 15+** - Database backend
- **Minimum 8 vCPU, 16GB RAM** per node
- **Valid WALLIX license**

### Installation Order

```
1. Prerequisites    → Review requirements, prepare infrastructure
2. Site A Primary   → Install HA cluster at headquarters
3. Site B Secondary → Install HA cluster at secondary plant
4. Site C Remote    → Install standalone at remote site
5. Multi-Site Sync  → Configure cross-site synchronization
6. OT Integration   → Set up industrial protocol support
7. Security         → Apply hardening and compliance controls
8. Validation       → Test and verify installation
```

### Fastest Path to Production

```bash
# 1. Read the HOWTO guide for step-by-step instructions
cat HOWTO.md

# 2. Complete prerequisites checklist
cat 01-prerequisites.md

# 3. Follow site-by-site installation
cat 02-site-a-primary.md
cat 03-site-b-secondary.md
cat 04-site-c-remote.md

# 4. Configure and validate
cat 05-multi-site-sync.md
cat 08-validation-testing.md
```

---

## Documentation

| Document | Description | Audience |
|----------|-------------|----------|
| [HOWTO.md](./HOWTO.md) | Step-by-step installation guide | All |
| [01-prerequisites.md](./01-prerequisites.md) | Hardware, network, software requirements | Infrastructure |
| [02-site-a-primary.md](./02-site-a-primary.md) | Primary site HA cluster installation | Engineers |
| [03-site-b-secondary.md](./03-site-b-secondary.md) | Secondary site HA cluster installation | Engineers |
| [04-site-c-remote.md](./04-site-c-remote.md) | Remote standalone installation | Engineers |
| [05-multi-site-sync.md](./05-multi-site-sync.md) | Cross-site synchronization setup | Architects |
| [06-ot-network-config.md](./06-ot-network-config.md) | OT network and protocol integration | OT Engineers |
| [07-security-hardening.md](./07-security-hardening.md) | Security hardening procedures | Security |
| [08-validation-testing.md](./08-validation-testing.md) | Testing and go-live checklist | QA/Operations |

---

## Compliance

This installation guide is designed to support compliance with:

| Standard | Description |
|----------|-------------|
| **IEC 62443** | Industrial Automation and Control Systems Security |
| **NIST 800-82** | Guide to Industrial Control Systems Security |
| **NIS2 Directive** | EU Network and Information Security |
| **ISO 27001** | Information Security Management |

### Security Features

- **Argon2ID** key derivation (12.x default)
- **AES-256-GCM** encryption for vault
- **Whole disk encryption** (LUKS) on new installations
- **High security ciphers** for SSH/TLS
- **Session recording** with tamper-evident logs
- **MFA enforcement** for privileged users

---

## System Requirements

### Hardware (per node)

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| CPU | 4 vCPU | 8+ vCPU |
| RAM | 8 GB | 16+ GB |
| OS Disk | 100 GB SSD | 200 GB NVMe |
| Data Disk | 250 GB SSD | 500 GB NVMe |
| Network | 1 Gbps | 10 Gbps |

### Software

| Component | Version |
|-----------|---------|
| WALLIX Bastion | 12.1.x |
| Operating System | Debian 12 (Bookworm) |
| PostgreSQL | 15+ |
| Pacemaker | 2.1+ |

---

## Support

| Resource | Link |
|----------|------|
| WALLIX Documentation | https://pam.wallix.one/documentation |
| WALLIX Support Portal | https://support.wallix.com |
| Release Notes | https://pam.wallix.one/documentation/release-notes |

---

## Version Information

| Item | Value |
|------|-------|
| Document Version | 1.0 |
| WALLIX Version | 12.1.x |
| Last Updated | January 2026 |
| Author | Infrastructure Team |

---

## License

This documentation is provided for WALLIX Bastion deployment purposes. WALLIX Bastion is a commercial product requiring valid licensing.

---

<p align="center">
  <sub>Built for secure industrial environments</sub>
</p>
