# WALLIX Bastion 12.x - Multi-Site OT Installation Guide

<p align="center">
  <img src="https://www.wallix.com/wp-content/uploads/2021/03/wallix-logo.svg" alt="WALLIX Logo" width="200"/>
</p>

<p align="center">
  <strong>Enterprise Privileged Access Management for Industrial Environments</strong>
</p>

<p align="center">
  <a href="#executive-summary">Executive Summary</a> •
  <a href="#architecture">Architecture</a> •
  <a href="#deployment-scenarios">Scenarios</a> •
  <a href="#quick-start">Quick Start</a> •
  <a href="#documentation">Documentation</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/WALLIX-12.1.x-blue" alt="WALLIX Version"/>
  <img src="https://img.shields.io/badge/Debian-12%20Bookworm-red" alt="Debian Version"/>
  <img src="https://img.shields.io/badge/IEC%2062443-Compliant-green" alt="IEC 62443"/>
  <img src="https://img.shields.io/badge/PostgreSQL-15%2B-blue" alt="PostgreSQL"/>
</p>

---

## Table of Contents

- [Executive Summary](#executive-summary)
- [Business Value](#business-value)
- [Architecture Overview](#architecture-overview)
  - [Multi-Site Topology](#multi-site-topology)
  - [Network Architecture](#network-architecture)
  - [Component Architecture](#component-architecture)
  - [Data Flow Architecture](#data-flow-architecture)
- [Deployment Scenarios](#deployment-scenarios)
- [System Requirements](#system-requirements)
- [Quick Start](#quick-start)
- [Documentation Structure](#documentation-structure)
- [Security & Compliance](#security--compliance)
- [Project Planning](#project-planning)
- [Support & Resources](#support--resources)
- [Changelog](#changelog)

---

## Executive Summary

This repository provides **production-ready** installation and configuration documentation for deploying **WALLIX Bastion 12.x** in a multi-site Operational Technology (OT) environment.

### What This Guide Covers

| Scope | Description |
|-------|-------------|
| **3 Sites** | Primary HQ, Secondary Plant, Remote Field Office |
| **5 Nodes** | 2 HA nodes (Site A) + 2 HA nodes (Site B) + 1 Standalone (Site C) |
| **High Availability** | Pacemaker/Corosync clustering with automatic failover |
| **OT Integration** | Universal tunneling for Modbus, S7comm, OPC UA, DNP3 |
| **Offline Capable** | Cached authentication for air-gapped environments |
| **IEC 62443 Compliant** | Industrial security controls and zone segmentation |

### Target Audience

| Role | Primary Documents |
|------|-------------------|
| **Project Managers** | README.md, HOWTO.md (Planning sections) |
| **Infrastructure Architects** | 01-prerequisites.md, 05-multi-site-sync.md |
| **System Engineers** | 02-site-a-primary.md, 03-site-b-secondary.md, 04-site-c-remote.md |
| **OT Engineers** | 06-ot-network-config.md |
| **Security Teams** | 07-security-hardening.md |
| **QA/Operations** | 08-validation-testing.md |

### Deployment Timeline

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        30-DAY DEPLOYMENT TIMELINE                           │
├─────────────────────────────────────────────────────────────────────────────┤
│ Week 1    │ Week 2         │ Week 3         │ Week 4                        │
│ Days 1-5  │ Days 6-12      │ Days 13-20     │ Days 21-30                    │
├───────────┼────────────────┼────────────────┼───────────────────────────────┤
│ PLANNING  │ SITE A + B     │ SITE C + SYNC  │ HARDENING + VALIDATION        │
│           │                │                │                               │
│ • Prereqs │ • Site A HA    │ • Site C       │ • Security hardening          │
│ • Network │ • Site B HA    │ • Multi-site   │ • Compliance validation       │
│ • Licenses│ • Basic config │ • OT networks  │ • UAT testing                 │
│ • VMs     │ • Initial test │ • Protocols    │ • Go-live                     │
└───────────┴────────────────┴────────────────┴───────────────────────────────┘
```

---

## Business Value

### Why WALLIX Bastion for OT Environments?

| Challenge | WALLIX Solution |
|-----------|-----------------|
| **Regulatory Compliance** | Built-in IEC 62443, NIST 800-82, NIS2 controls |
| **Privileged Access Risk** | Session recording, MFA, just-in-time access |
| **OT Protocol Visibility** | Universal tunneling with protocol inspection |
| **Air-Gapped Sites** | Offline authentication with cached credentials |
| **Multi-Vendor Equipment** | Single PAM solution for IT and OT assets |
| **Incident Response** | Tamper-evident session logs for forensics |

### ROI Drivers

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           RETURN ON INVESTMENT                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  RISK REDUCTION                    OPERATIONAL EFFICIENCY                   │
│  ═══════════════                   ══════════════════════                   │
│  • 90% reduction in               • 60% faster access                       │
│    credential-based attacks         provisioning                            │
│  • 100% session auditability      • 40% reduction in                        │
│  • Zero standing privileges         support tickets                         │
│                                   • Single pane of glass                    │
│                                                                             │
│  COMPLIANCE                        INSURANCE                                │
│  ══════════════                    ═════════════                            │
│  • Audit-ready reports            • Lower cyber insurance                   │
│  • Automated evidence               premiums                                │
│    collection                     • Documented security                     │
│  • Continuous compliance            controls                                │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Architecture Overview

### Multi-Site Topology

```
                              ╔═══════════════════════════════════════════════════════════════╗
                              ║                    CORPORATE WAN / MPLS                       ║
                              ╚═══════════════════════════════════════════════════════════════╝
                                        │                    │                    │
                                        │                    │                    │
                    ┌───────────────────┴────────┐ ┌────────┴────────┐ ┌────────┴───────────────────┐
                    │                            │ │                 │ │                            │
                    ▼                            │ │                 │ │                            ▼
    ╔═══════════════════════════════════╗       │ │                 │ │       ╔═══════════════════════════════════╗
    ║           SITE A - PRIMARY        ║       │ │                 │ │       ║         SITE C - REMOTE           ║
    ║         Headquarters (HQ)         ║       │ │                 │ │       ║        Field Office               ║
    ╠═══════════════════════════════════╣       │ │                 │ │       ╠═══════════════════════════════════╣
    ║                                   ║       │ │                 │ │       ║                                   ║
    ║  ┌─────────────────────────────┐  ║       │ │                 │ │       ║  ┌─────────────────────────────┐  ║
    ║  │    WALLIX HA CLUSTER        │  ║       │ │                 │ │       ║  │    WALLIX STANDALONE        │  ║
    ║  │    (Active-Active)          │  ║       │ │                 │ │       ║  │    (Offline-Capable)        │  ║
    ║  │                             │  ║       │ │                 │ │       ║  │                             │  ║
    ║  │  ┌─────────┐ ┌─────────┐   │  ║       │ │                 │ │       ║  │      ┌─────────┐            │  ║
    ║  │  │ Node 1  │ │ Node 2  │   │  ║       │ │                 │ │       ║  │      │ Node 1  │            │  ║
    ║  │  │ Active  │ │ Active  │   │  ║       │ │                 │ │       ║  │      │ Primary │            │  ║
    ║  │  └────┬────┘ └────┬────┘   │  ║       │ │                 │ │       ║  │      └────┬────┘            │  ║
    ║  │       │           │        │  ║       │ │                 │ │       ║  │           │                 │  ║
    ║  │       └─────┬─────┘        │  ║       │ │                 │ │       ║  │           │                 │  ║
    ║  │             │              │  ║       │ │                 │ │       ║  │           │                 │  ║
    ║  │        ┌────┴────┐         │  ║       │ │                 │ │       ║  │      ┌────┴────┐            │  ║
    ║  │        │ VIP/VRR │         │  ║◄──────┼─┼────── SYNC ─────┼─┼──────►║  │      │ Local   │            │  ║
    ║  │        │ Pool    │         │  ║       │ │                 │ │       ║  │      │ Cache   │            │  ║
    ║  │        └────┬────┘         │  ║       │ │                 │ │       ║  │      └────┬────┘            │  ║
    ║  └─────────────┼──────────────┘  ║       │ │                 │ │       ║  └───────────┼─────────────────┘  ║
    ║                │                 ║       │ │                 │ │       ║              │                    ║
    ╠════════════════╪═════════════════╣       │ │                 │ │       ╠══════════════╪════════════════════╣
    ║           OT NETWORK             ║       │ │                 │ │       ║         OT NETWORK                ║
    ║  ┌─────┐ ┌─────┐ ┌─────┐        ║       │ │                 │ │       ║  ┌─────┐ ┌─────┐                  ║
    ║  │ PLC │ │ HMI │ │ RTU │        ║       │ │                 │ │       ║  │ PLC │ │ RTU │                  ║
    ║  └─────┘ └─────┘ └─────┘        ║       │ │                 │ │       ║  └─────┘ └─────┘                  ║
    ╚═══════════════════════════════════╝       │ │                 │ │       ╚═══════════════════════════════════╝
                                                │ │                 │ │
                                                │ ▼                 │ │
                                                │ ╔═════════════════════════════════════╗
                                                │ ║        SITE B - SECONDARY           ║
                                                │ ║         Manufacturing Plant         ║
                                                │ ╠═════════════════════════════════════╣
                                                │ ║                                     ║
                                                │ ║  ┌─────────────────────────────┐    ║
                                                │ ║  │    WALLIX HA CLUSTER        │    ║
                                                │ ║  │    (Active-Passive)         │    ║
                                                │ ║  │                             │    ║
                                                │ ║  │  ┌─────────┐ ┌─────────┐   │    ║
                                                │ ║  │  │ Node 1  │ │ Node 2  │   │    ║
                                                │ ║  │  │ Active  │ │ Standby │   │    ║
                                                │ ║  │  └────┬────┘ └────┬────┘   │    ║
                                                │ ║  │       │           │        │    ║
                                                │ ║  │       └─────┬─────┘        │    ║
                                                └─║──│◄────────────┤              │    ║
                                                  ║  │        ┌────┴────┐         │    ║
                                                  ║  │        │   VIP   │         │    ║
                                                  ║  │        └────┬────┘         │    ║
                                                  ║  └─────────────┼──────────────┘    ║
                                                  ║                │                   ║
                                                  ╠════════════════╪═══════════════════╣
                                                  ║           OT NETWORK               ║
                                                  ║  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐  ║
                                                  ║  │ PLC │ │ DCS │ │ HMI │ │SCADA│  ║
                                                  ║  └─────┘ └─────┘ └─────┘ └─────┘  ║
                                                  ╚═════════════════════════════════════╝
```

### Site Configuration Summary

| Site | Location | Configuration | Nodes | HA Mode | Connectivity | Primary Use Case |
|------|----------|---------------|-------|---------|--------------|------------------|
| **A** | Headquarters | HA Cluster | 2 | Active-Active | Always Online | Central management, primary access |
| **B** | Manufacturing | HA Cluster | 2 | Active-Passive | Always Online | Regional access, DR capability |
| **C** | Field Office | Standalone | 1 | N/A | Intermittent | Edge access, offline operation |

### Network Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                              NETWORK SEGMENTATION MODEL                                      │
├─────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                             │
│   ZONE 5 - Enterprise          ┌─────────────────────────────────────────────────────────┐ │
│   (Corporate IT)               │  Active Directory │ SIEM │ Email │ Business Apps       │ │
│                                └─────────────────────────────────────────────────────────┘ │
│                                                     │                                       │
│   ═══════════════════════════════════════════════════════════════════════════════════════  │
│                                              FIREWALL                                       │
│   ═══════════════════════════════════════════════════════════════════════════════════════  │
│                                                     │                                       │
│   ZONE 4 - Site Business       ┌─────────────────────────────────────────────────────────┐ │
│   (IT/OT DMZ)                  │            ★ WALLIX BASTION ★                           │ │
│                                │     (Session Recording, Access Control, Audit)          │ │
│                                └─────────────────────────────────────────────────────────┘ │
│                                                     │                                       │
│   ═══════════════════════════════════════════════════════════════════════════════════════  │
│                                          OT FIREWALL                                        │
│   ═══════════════════════════════════════════════════════════════════════════════════════  │
│                                                     │                                       │
│   ZONE 3 - Site Operations     ┌─────────────────────────────────────────────────────────┐ │
│   (SCADA/DCS)                  │  Historian │ Engineering Workstations │ SCADA Servers   │ │
│                                └─────────────────────────────────────────────────────────┘ │
│                                                     │                                       │
│   ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─  │
│                                                     │                                       │
│   ZONE 2 - Area Control        ┌─────────────────────────────────────────────────────────┐ │
│   (Process Control)            │  HMI Panels │ Area PLCs │ Safety Controllers            │ │
│                                └─────────────────────────────────────────────────────────┘ │
│                                                     │                                       │
│   ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─  │
│                                                     │                                       │
│   ZONE 1 - Basic Control       ┌─────────────────────────────────────────────────────────┐ │
│   (Field Devices)              │  Sensors │ Actuators │ I/O Modules │ RTUs               │ │
│                                └─────────────────────────────────────────────────────────┘ │
│                                                     │                                       │
│   ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─  │
│                                                     │                                       │
│   ZONE 0 - Process             ┌─────────────────────────────────────────────────────────┐ │
│   (Physical Equipment)         │  Motors │ Valves │ Pumps │ Physical Process            │ │
│                                └─────────────────────────────────────────────────────────┘ │
│                                                                                             │
└─────────────────────────────────────────────────────────────────────────────────────────────┘
```

### Component Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                           WALLIX BASTION 12.x COMPONENT STACK                               │
├─────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────────────────────┐   │
│  │                              ACCESS LAYER                                            │   │
│  │  ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───────────┐             │   │
│  │  │   SSH     │ │    RDP    │ │   VNC     │ │   HTTP    │ │  Custom   │             │   │
│  │  │  Proxy    │ │   Proxy   │ │   Proxy   │ │   Proxy   │ │  Tunnel   │             │   │
│  │  │ Port 22   │ │ Port 3389 │ │ Port 5900 │ │ Port 443  │ │ Universal │             │   │
│  │  └───────────┘ └───────────┘ └───────────┘ └───────────┘ └───────────┘             │   │
│  └─────────────────────────────────────────────────────────────────────────────────────┘   │
│                                          │                                                  │
│  ┌─────────────────────────────────────────────────────────────────────────────────────┐   │
│  │                            SESSION LAYER                                             │   │
│  │  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐   │   │
│  │  │ Session Manager │ │ Session Recorder│ │ Real-time Audit │ │ Session Sharing │   │   │
│  │  │                 │ │ (Video/Metadata)│ │ (OCR/Patterns)  │ │ (4-Eyes Review) │   │   │
│  │  └─────────────────┘ └─────────────────┘ └─────────────────┘ └─────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────────────────────┘   │
│                                          │                                                  │
│  ┌─────────────────────────────────────────────────────────────────────────────────────┐   │
│  │                          AUTHORIZATION LAYER                                         │   │
│  │  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐   │   │
│  │  │ Policy Engine   │ │ Approval        │ │ Time Windows    │ │ MFA Validation  │   │   │
│  │  │ (Rules/Groups)  │ │ Workflows       │ │ (Schedules)     │ │ (TOTP/FIDO2)    │   │   │
│  │  └─────────────────┘ └─────────────────┘ └─────────────────┘ └─────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────────────────────┘   │
│                                          │                                                  │
│  ┌─────────────────────────────────────────────────────────────────────────────────────┐   │
│  │                         AUTHENTICATION LAYER                                         │   │
│  │  ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───────────┐             │   │
│  │  │   LDAP    │ │   RADIUS  │ │ Kerberos  │ │   OIDC    │ │   SAML    │             │   │
│  │  │ (AD/LDAP) │ │  (2FA)    │ │  (SSO)    │ │ (Azure AD)│ │ (Okta)    │             │   │
│  │  └───────────┘ └───────────┘ └───────────┘ └───────────┘ └───────────┘             │   │
│  └─────────────────────────────────────────────────────────────────────────────────────┘   │
│                                          │                                                  │
│  ┌─────────────────────────────────────────────────────────────────────────────────────┐   │
│  │                            DATA LAYER                                                │   │
│  │  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐   │   │
│  │  │ PostgreSQL 15+  │ │ Credential Vault│ │ Session Storage │ │ Config Store    │   │   │
│  │  │ (Metadata/Audit)│ │ (AES-256-GCM)   │ │ (Recordings)    │ │ (Policies)      │   │   │
│  │  └─────────────────┘ └─────────────────┘ └─────────────────┘ └─────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────────────────────┘   │
│                                          │                                                  │
│  ┌─────────────────────────────────────────────────────────────────────────────────────┐   │
│  │                         INFRASTRUCTURE LAYER                                         │   │
│  │  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐   │   │
│  │  │ Debian 12       │ │ Pacemaker/      │ │ PostgreSQL      │ │ Corosync        │   │   │
│  │  │ (Bookworm)      │ │ Corosync (HA)   │ │ (Streaming Rep) │ │ (Cluster Comm)  │   │   │
│  │  └─────────────────┘ └─────────────────┘ └─────────────────┘ └─────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                             │
└─────────────────────────────────────────────────────────────────────────────────────────────┘
```

### Data Flow Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                              SESSION ACCESS FLOW                                             │
├─────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                             │
│    ┌──────────┐         ┌──────────────────────────────────────────┐         ┌──────────┐  │
│    │          │         │            WALLIX BASTION                │         │          │  │
│    │   USER   │         │                                          │         │  TARGET  │  │
│    │          │         │  ┌────────┐  ┌────────┐  ┌────────────┐ │         │  DEVICE  │  │
│    │ Engineer │────1───►│  │ Auth   │  │ Policy │  │ Credential │ │         │          │  │
│    │          │         │  │ Check  │  │ Check  │  │   Inject   │ │         │   PLC    │  │
│    └──────────┘         │  └───┬────┘  └───┬────┘  └─────┬──────┘ │         │   HMI    │  │
│                         │      │           │             │        │         │   RTU    │  │
│         ▲               │      ▼           ▼             ▼        │         │          │  │
│         │               │  ┌────────────────────────────────────┐ │         └────▲─────┘  │
│         │               │  │         SESSION BROKER             │ │              │        │
│         │               │  │  • Proxy Connection                │ │              │        │
│         │               │  │  • Inject Credentials              │─┼──────4──────►│        │
│         │               │  │  • Record Session                  │ │              │        │
│         │               │  │  • Monitor Commands                │ │              │        │
│         │               │  └────────────────────────────────────┘ │              │        │
│         │               │                    │                    │              │        │
│         │               │                    ▼                    │              │        │
│         │               │  ┌────────────────────────────────────┐ │              │        │
│         │               │  │        SESSION RECORDER            │ │              │        │
│         │               │  │  • Video capture                   │ │              │        │
│         │               │  │  • Keystroke logging               │ │              │        │
│         │               │  │  • Metadata extraction             │◄┼──────5───────┤        │
│         │               │  │  • OCR for screen content          │ │              │        │
│         6               │  └────────────────────────────────────┘ │                       │
│         │               │                    │                    │                       │
│         │               │                    ▼                    │                       │
│         │               │  ┌────────────────────────────────────┐ │                       │
│         │               │  │          AUDIT LOG                 │ │                       │
│         └───────────────┼──│  • Who accessed what               │ │                       │
│                         │  │  • When and for how long           │ │                       │
│                         │  │  • What commands were executed     │ │                       │
│                         │  │  • Session recording available     │ │                       │
│                         │  └────────────────────────────────────┘ │                       │
│                         └──────────────────────────────────────────┘                       │
│                                                                                             │
│   FLOW: 1. User authenticates (MFA) → 2. Policy evaluated → 3. Credentials retrieved      │
│         4. Proxied connection to target → 5. Session recorded → 6. Audit trail created    │
│                                                                                             │
└─────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## Deployment Scenarios

### Scenario Decision Matrix

| Factor | Site A (Primary) | Site B (Secondary) | Site C (Remote) |
|--------|------------------|--------------------|--------------------|
| **Uptime Requirement** | 99.99% | 99.9% | 99% |
| **Users** | 50-200 | 20-50 | 5-15 |
| **OT Devices** | 100+ | 50-100 | 10-30 |
| **Network Bandwidth** | 1 Gbps+ | 100 Mbps+ | Variable/Limited |
| **HA Configuration** | Active-Active | Active-Passive | Standalone |
| **Failover Time** | < 30 seconds | < 60 seconds | N/A |
| **Offline Operation** | No | No | Yes (24h cache) |
| **Central Management** | Master | Replica | Replica |

### HA Mode Comparison

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                           HIGH AVAILABILITY MODES                                           │
├─────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                             │
│   ACTIVE-ACTIVE (Site A)                    ACTIVE-PASSIVE (Site B)                        │
│   ══════════════════════                    ════════════════════════                        │
│                                                                                             │
│   ┌─────────┐     ┌─────────┐              ┌─────────┐     ┌─────────┐                     │
│   │ Node 1  │     │ Node 2  │              │ Node 1  │     │ Node 2  │                     │
│   │ ACTIVE  │     │ ACTIVE  │              │ ACTIVE  │     │ STANDBY │                     │
│   │ (50%)   │     │ (50%)   │              │ (100%)  │     │ (0%)    │                     │
│   └────┬────┘     └────┬────┘              └────┬────┘     └────┬────┘                     │
│        │               │                        │               │                          │
│        └───────┬───────┘                        └───────┬───────┘                          │
│                │                                        │                                  │
│         ┌──────┴──────┐                          ┌──────┴──────┐                           │
│         │  VIP Pool   │                          │  Single VIP │                           │
│         │ Round-Robin │                          │   Failover  │                           │
│         └─────────────┘                          └─────────────┘                           │
│                                                                                             │
│   Pros:                                    Pros:                                            │
│   • Load distribution                      • Simple configuration                          │
│   • Higher throughput                      • Lower resource usage                          │
│   • No single point of failure             • Predictable failover                          │
│                                                                                             │
│   Cons:                                    Cons:                                            │
│   • Complex configuration                  • Standby node idle                             │
│   • Session affinity required              • Full load on single node                      │
│   • Higher resource requirements           • Longer failover time                          │
│                                                                                             │
└─────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## System Requirements

### Hardware Requirements

| Component | Minimum | Recommended | High Performance |
|-----------|---------|-------------|------------------|
| **CPU** | 4 vCPU | 8 vCPU | 16+ vCPU |
| **RAM** | 8 GB | 16 GB | 32+ GB |
| **OS Disk** | 100 GB SSD | 200 GB NVMe | 500 GB NVMe |
| **Data Disk** | 250 GB SSD | 500 GB NVMe | 1+ TB NVMe |
| **Network** | 1 Gbps | 10 Gbps | 25 Gbps |

### Software Requirements

| Component | Required Version | Notes |
|-----------|------------------|-------|
| **WALLIX Bastion** | 12.1.x | Latest stable release |
| **Operating System** | Debian 12 (Bookworm) | Required for new installations |
| **PostgreSQL** | 15+ (15, 16, or 17) | 15+ required for 12.x |
| **Pacemaker** | 2.1+ | HA clustering |
| **Corosync** | 3.1+ | Cluster communication |

### Network Requirements

| Traffic Type | Ports | Protocol | Direction |
|--------------|-------|----------|-----------|
| **SSH Access** | 22 | TCP | Inbound |
| **RDP Access** | 3389 | TCP | Inbound |
| **Web UI** | 443 | TCP | Inbound |
| **Cluster Sync** | 5404-5406 | UDP | Between nodes |
| **PostgreSQL Streaming** | 5432 | TCP | Between nodes |
| **PCSD (Cluster Mgmt)** | 2224 | TCP | Between nodes |

---

## Quick Start

### Prerequisites Checklist

```bash
# Verify you have:
[ ] Valid WALLIX license for all nodes
[ ] Debian 12 installation media
[ ] Network connectivity between all sites
[ ] Firewall rules approved and implemented
[ ] DNS entries for all nodes and VIPs
[ ] SSL certificates (or plan for self-signed)
[ ] Administrator credentials for target systems
[ ] Backup storage location identified
```

### Installation Order

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        RECOMMENDED INSTALLATION ORDER                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   PHASE 1: PREPARATION (Days 1-5)                                          │
│   ─────────────────────────────────                                         │
│   ┌──────────────────────────────────────────────────────────────────┐     │
│   │  1.1  Review 01-prerequisites.md                                 │     │
│   │  1.2  Complete infrastructure checklist                          │     │
│   │  1.3  Deploy base VMs at all sites                               │     │
│   │  1.4  Verify network connectivity                                │     │
│   │  1.5  Obtain and stage WALLIX licenses                           │     │
│   └──────────────────────────────────────────────────────────────────┘     │
│                                     │                                       │
│                                     ▼                                       │
│   PHASE 2: PRIMARY SITE (Days 6-10)                                        │
│   ──────────────────────────────────                                        │
│   ┌──────────────────────────────────────────────────────────────────┐     │
│   │  2.1  Install Site A Node 1 (02-site-a-primary.md)               │     │
│   │  2.2  Configure base settings                                     │     │
│   │  2.3  Install Site A Node 2                                       │     │
│   │  2.4  Configure HA cluster (Active-Active)                        │     │
│   │  2.5  Validate failover                                           │     │
│   └──────────────────────────────────────────────────────────────────┘     │
│                                     │                                       │
│                                     ▼                                       │
│   PHASE 3: SECONDARY SITE (Days 11-15)                                     │
│   ────────────────────────────────────                                      │
│   ┌──────────────────────────────────────────────────────────────────┐     │
│   │  3.1  Install Site B Node 1 (03-site-b-secondary.md)             │     │
│   │  3.2  Install Site B Node 2                                       │     │
│   │  3.3  Configure HA cluster (Active-Passive)                       │     │
│   │  3.4  Validate failover                                           │     │
│   └──────────────────────────────────────────────────────────────────┘     │
│                                     │                                       │
│                                     ▼                                       │
│   PHASE 4: REMOTE SITE (Days 16-18)                                        │
│   ─────────────────────────────────                                         │
│   ┌──────────────────────────────────────────────────────────────────┐     │
│   │  4.1  Install Site C Node (04-site-c-remote.md)                  │     │
│   │  4.2  Configure offline capabilities                              │     │
│   │  4.3  Test offline authentication                                 │     │
│   └──────────────────────────────────────────────────────────────────┘     │
│                                     │                                       │
│                                     ▼                                       │
│   PHASE 5: INTEGRATION (Days 19-23)                                        │
│   ─────────────────────────────────                                         │
│   ┌──────────────────────────────────────────────────────────────────┐     │
│   │  5.1  Configure multi-site sync (05-multi-site-sync.md)          │     │
│   │  5.2  Set up OT networks (06-ot-network-config.md)               │     │
│   │  5.3  Configure industrial protocols                              │     │
│   │  5.4  Test cross-site failover                                    │     │
│   └──────────────────────────────────────────────────────────────────┘     │
│                                     │                                       │
│                                     ▼                                       │
│   PHASE 6: HARDENING & VALIDATION (Days 24-30)                             │
│   ────────────────────────────────────────────                              │
│   ┌──────────────────────────────────────────────────────────────────┐     │
│   │  6.1  Apply security hardening (07-security-hardening.md)        │     │
│   │  6.2  Execute validation tests (08-validation-testing.md)        │     │
│   │  6.3  Complete compliance documentation                           │     │
│   │  6.4  Conduct UAT with stakeholders                               │     │
│   │  6.5  Go-live                                                     │     │
│   └──────────────────────────────────────────────────────────────────┘     │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Quick Verification Commands

```bash
# Check WALLIX service status
systemctl status wallix-bastion

# Verify cluster health (HA nodes)
crm status

# Test database connectivity
sudo -u postgres psql -c "SELECT version();"

# Verify license status
wabadmin license-info

# Check session proxy status
wabadmin status

# View recent authentications
wabadmin audit --last 10
```

---

## Documentation Structure

### File Overview

```
install/
├── README.md                       # This file - Overview and quick start
├── HOWTO.md                        # Comprehensive step-by-step guide (1600+ lines)
├── 00-debian-luks-installation.md  # Debian 12 + LUKS installation for VMs
├── 01-prerequisites.md             # Hardware, software, network requirements
├── 02-site-a-primary.md            # Primary site HA cluster installation
├── 03-site-b-secondary.md          # Secondary site HA cluster installation
├── 04-site-c-remote.md             # Remote standalone installation
├── 05-multi-site-sync.md           # Cross-site synchronization
├── 06-ot-network-config.md         # OT network and protocol setup
├── 07-security-hardening.md        # Security hardening procedures
├── 08-validation-testing.md        # Testing and go-live checklist
├── 09-architecture-diagrams.md     # Detailed diagrams, services, and ports
└── 10-postgresql-streaming-replication.md  # Database HA configuration
```

### Document Purpose

| Document | Purpose | When to Use |
|----------|---------|-------------|
| **README.md** | Project overview, architecture, quick reference | Project kickoff, stakeholder briefings |
| **HOWTO.md** | Complete step-by-step deployment guide | During installation, troubleshooting |
| **00-debian-luks-installation.md** | Debian 12 + LUKS setup for VMs | Phase 1, VM preparation |
| **01-prerequisites.md** | Infrastructure requirements | Before procurement, during planning |
| **02-site-a-primary.md** | Primary site installation | Phase 2 of deployment |
| **03-site-b-secondary.md** | Secondary site installation | Phase 3 of deployment |
| **04-site-c-remote.md** | Remote site installation | Phase 4 of deployment |
| **05-multi-site-sync.md** | Multi-site configuration | Phase 5 of deployment |
| **06-ot-network-config.md** | OT protocol setup | Phase 5 of deployment |
| **07-security-hardening.md** | Security configuration | Phase 6 of deployment |
| **08-validation-testing.md** | Testing procedures | Phase 6, before go-live |
| **09-architecture-diagrams.md** | Visual diagrams, services, ports | Reference during all phases |
| **10-postgresql-streaming-replication.md** | Database HA setup | HA cluster configuration |

---

## Security & Compliance

### Compliance Standards

| Standard | Description | Coverage |
|----------|-------------|----------|
| **IEC 62443** | Industrial Automation and Control Systems Security | Full |
| **NIST 800-82** | Guide to Industrial Control Systems Security | Full |
| **NIS2 Directive** | EU Network and Information Security | Full |
| **ISO 27001** | Information Security Management | Partial |
| **SOC 2 Type II** | Service Organization Control | Partial |

### Security Features

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         SECURITY FEATURES MATRIX                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   AUTHENTICATION                          AUTHORIZATION                     │
│   ══════════════                          ═════════════                     │
│   ☑ Multi-Factor Authentication           ☑ Role-Based Access Control       │
│   ☑ LDAP/Active Directory                 ☑ Time-Based Access Windows       │
│   ☑ RADIUS Integration                    ☑ Approval Workflows              │
│   ☑ Kerberos SSO                          ☑ Just-In-Time Access             │
│   ☑ OIDC/SAML (Azure AD, Okta)           ☑ Least Privilege Enforcement     │
│   ☑ Certificate Authentication            ☑ Emergency Access Procedures     │
│                                                                             │
│   SESSION SECURITY                        AUDIT & COMPLIANCE                │
│   ════════════════                        ══════════════════                │
│   ☑ Session Recording (Video)             ☑ Tamper-Evident Logs             │
│   ☑ Keystroke Logging                     ☑ Real-Time Alerting              │
│   ☑ Command Filtering                     ☑ Compliance Reports              │
│   ☑ Session Sharing (4-Eyes)              ☑ Session Playback                │
│   ☑ Automatic Session Termination         ☑ SIEM Integration                │
│   ☑ Clipboard Control                     ☑ Retention Policies              │
│                                                                             │
│   CREDENTIAL MANAGEMENT                   ENCRYPTION                        │
│   ═════════════════════                   ══════════════                    │
│   ☑ Secure Credential Vault               ☑ AES-256-GCM (Vault)             │
│   ☑ Automatic Password Rotation           ☑ Argon2ID (Key Derivation)       │
│   ☑ SSH Key Management                    ☑ TLS 1.3 (Transport)             │
│   ☑ Credential Injection                  ☑ LUKS (Disk Encryption)          │
│   ☑ No Credential Exposure                ☑ High Security Ciphers           │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Cryptographic Standards

| Function | Algorithm | Key Size | Standard |
|----------|-----------|----------|----------|
| **Key Derivation** | Argon2ID | 256-bit | OWASP Recommended |
| **Vault Encryption** | AES-256-GCM | 256-bit | NIST FIPS 197 |
| **Transport Security** | TLS 1.3 | 256-bit | RFC 8446 |
| **Disk Encryption** | LUKS2/AES-XTS | 512-bit | dm-crypt |
| **Password Hashing** | bcrypt | Work factor 12 | OpenBSD |

---

## Project Planning

### Team Roles

| Role | Responsibilities | Required Skills |
|------|------------------|-----------------|
| **Project Manager** | Timeline, resources, stakeholder communication | PM, WALLIX familiarity |
| **Infrastructure Architect** | Design, network planning, capacity | Architecture, networking |
| **System Engineer** | Installation, configuration, HA setup | Linux, WALLIX, clustering |
| **OT Engineer** | Protocol configuration, device integration | SCADA, PLCs, industrial protocols |
| **Security Engineer** | Hardening, compliance, audit configuration | Security, compliance frameworks |
| **QA Engineer** | Testing, validation, documentation | Testing methodologies |

### Resource Estimation

| Site | Nodes | Engineer Days | Estimated Effort |
|------|-------|---------------|------------------|
| **Site A** | 2 | 5 | Primary HA cluster |
| **Site B** | 2 | 4 | Secondary HA cluster |
| **Site C** | 1 | 2 | Standalone |
| **Integration** | - | 5 | Multi-site sync, OT |
| **Hardening** | - | 3 | Security, compliance |
| **Validation** | - | 3 | Testing, UAT |
| **Buffer** | - | 3 | Contingency |
| **Total** | 5 | **25 days** | Full deployment |

### Risk Matrix

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Network latency issues | Medium | High | Pre-deployment network testing |
| License delivery delays | Low | High | Order licenses 2 weeks early |
| OT device incompatibility | Medium | Medium | Pilot testing with sample devices |
| HA failover issues | Low | High | Extensive failover testing |
| Integration conflicts | Medium | Medium | Staged rollout, rollback plan |

---

## Support & Resources

### Official Resources

| Resource | URL | Purpose |
|----------|-----|---------|
| **WALLIX Documentation** | https://pam.wallix.one/documentation | Official product documentation |
| **Support Portal** | https://support.wallix.com | Technical support tickets |
| **Release Notes** | https://pam.wallix.one/documentation/release-notes | Version-specific information |
| **Knowledge Base** | https://support.wallix.com/kb | Common issues and solutions |

### Emergency Contacts

| Situation | Contact | Response Time |
|-----------|---------|---------------|
| **P1 - Production Down** | WALLIX Support Hotline | < 1 hour |
| **P2 - Major Impact** | Support Portal | < 4 hours |
| **P3 - Minor Impact** | Support Portal | < 8 hours |
| **P4 - Enhancement** | Support Portal | Best effort |

### Useful Commands Reference

```bash
# Service Management
systemctl status wallix-bastion    # Check service status
systemctl restart wallix-bastion   # Restart service
journalctl -u wallix-bastion -f    # Follow logs

# Cluster Management (HA)
crm status                         # Cluster status
crm resource restart wallix        # Restart cluster resource
pcs status                         # Alternative cluster status

# Administration
wabadmin status                    # WALLIX status
wabadmin license-info              # License information
wabadmin backup                    # Create backup
wabadmin audit --last 50           # Recent audit entries

# Database
sudo -u postgres psql              # PostgreSQL shell
sudo -u postgres pg_dump wallix    # Database backup

# Network Diagnostics
ss -tlnp | grep wallix             # Listening ports
curl -k https://localhost/api/health  # Health check
```

---

## Changelog

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | January 2026 | Infrastructure Team | Initial release |

---

## Related Documentation

- [Main Documentation Index](../docs/README.md) - Complete WALLIX Bastion documentation
- [API Reference](../docs/26-api-reference/README.md) - REST API documentation
- [System Requirements](../docs/28-system-requirements/README.md) - Detailed requirements
- [Upgrade Guide](../docs/29-upgrade-guide/README.md) - Version upgrade procedures

---

<p align="center">
  <strong>WALLIX Bastion 12.x Multi-Site OT Installation Guide</strong><br>
  <sub>Enterprise Privileged Access Management for Industrial Environments</sub><br>
  <sub>Document Version 1.0 | January 2026</sub>
</p>

<p align="center">
  <a href="./HOWTO.md">📖 Full Installation Guide</a> •
  <a href="./01-prerequisites.md">📋 Prerequisites</a> •
  <a href="./08-validation-testing.md">✅ Validation</a>
</p>
