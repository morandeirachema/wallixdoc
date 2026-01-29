# OT Cybersecurity Fundamentals

A comprehensive guide for IT professionals transitioning to Operational Technology (OT) security.

## Purpose

This guide bridges the knowledge gap between IT security and OT/ICS security. If you're a sysadmin, network engineer, or security professional starting a career in industrial cybersecurity, this is your foundation.

## Who This Guide Is For

| Background | What You'll Learn |
|------------|-------------------|
| **IT Sysadmin** | Why OT is fundamentally different, not just "old IT" |
| **Network Engineer** | Industrial protocols, real-time constraints, deterministic networking |
| **Security Analyst** | OT threat modeling, ICS-specific attack patterns |
| **Pentester** | Safe assessment approaches, what NOT to do in OT |
| **Compliance Professional** | IEC 62443, NERC CIP, sector-specific regulations |

## Learning Path

### Phase 1: Foundation (Weeks 1-4)

| Order | Section | Description |
|-------|---------|-------------|
| 1 | [01-ot-fundamentals](01-ot-fundamentals.md) | Control theory, process control basics, why availability matters |
| 2 | [02-control-systems-101](02-control-systems-101.md) | PLC, RTU, DCS, HMI, SCADA architecture |
| 3 | [03-ot-vs-it-security](03-ot-vs-it-security.md) | Mindset shift, CIA triad reversal, operational constraints |

### Phase 2: Technical Deep Dive (Weeks 5-8)

| Order | Section | Description |
|-------|---------|-------------|
| 4 | [04-industrial-protocols](04-industrial-protocols.md) | Modbus, DNP3, OPC UA, EtherNet/IP, serial communications |
| 5 | [05-ot-network-architecture](05-ot-network-architecture.md) | Purdue Model, zones/conduits, industrial firewalls |
| 6 | [06-legacy-systems](06-legacy-systems.md) | Securing unpatchable systems, compensating controls |

### Phase 3: Threats and Defense (Weeks 9-12)

| Order | Section | Description |
|-------|---------|-------------|
| 7 | [07-ot-threat-landscape](07-ot-threat-landscape.md) | APT groups, attack patterns, ICS malware analysis |
| 8 | [08-ot-threat-modeling](08-ot-threat-modeling.md) | Attack trees, STRIDE for OT, consequence-driven analysis |
| 9 | [09-ot-incident-response](09-ot-incident-response.md) | Safety-first IR, forensics, recovery procedures |

### Phase 4: Compliance and Governance (Weeks 13-16)

| Order | Section | Description |
|-------|---------|-------------|
| 10 | [10-iec62443-deep-dive](10-iec62443-deep-dive.md) | Security levels, zones/conduits, compliance mapping |
| 11 | [11-regulatory-landscape](11-regulatory-landscape.md) | NERC CIP, CFATS, NIS2, sector-specific requirements |
| 12 | [12-vendor-risk-management](12-vendor-risk-management.md) | Third-party access, supply chain security |

### Phase 5: Career Development (Ongoing)

| Order | Section | Description |
|-------|---------|-------------|
| 13 | [13-ot-security-career](13-ot-security-career.md) | Certifications, skills matrix, career paths |
| 14 | [14-hands-on-labs](14-hands-on-labs.md) | Lab setup, safe practice environments |
| 15 | [15-resources](15-resources.md) | Books, courses, communities, tools |

## Quick Reference

### The OT Security Mindset

```
┌─────────────────────────────────────────────────────────────────────┐
│                    IT vs OT Security Priorities                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   IT Security (CIA)              OT Security (AIC)                   │
│   ─────────────────              ─────────────────                   │
│   1. Confidentiality             1. Availability                     │
│   2. Integrity                   2. Integrity                        │
│   3. Availability                3. Confidentiality                  │
│                                                                      │
│   "Protect the data"             "Keep the process running safely"   │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Key Differences at a Glance

| Aspect | IT | OT |
|--------|----|----|
| **Primary Goal** | Protect data | Maintain safe operations |
| **Downtime Tolerance** | Hours acceptable | Seconds catastrophic |
| **Patching** | Monthly cycles | Years between updates |
| **System Lifespan** | 3-5 years | 15-30 years |
| **Network** | Dynamic, cloud-connected | Static, air-gapped |
| **Failure Impact** | Data loss, reputation | Physical damage, safety |
| **Change Windows** | Planned maintenance | Annual turnarounds |

### Critical Safety Principle

```
┌─────────────────────────────────────────────────────────────────────┐
│  SAFETY FIRST - ALWAYS                                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  In OT environments:                                                 │
│                                                                      │
│  • NEVER test on production systems without authorization            │
│  • NEVER assume you understand the physical process                  │
│  • NEVER disable safety systems for "security improvements"          │
│  • ALWAYS coordinate with operations before any changes              │
│  • ALWAYS have rollback procedures ready                             │
│  • ALWAYS prioritize human safety over security controls             │
│                                                                      │
│  Security that endangers people is not security.                     │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Industry Sectors

This guide covers OT security across major industrial sectors:

| Sector | Key Systems | Primary Regulations |
|--------|-------------|---------------------|
| **Power & Utilities** | SCADA, EMS, DCS | NERC CIP, IEC 62351 |
| **Oil & Gas** | SCADA, DCS, Safety Systems | API 1164, CFATS, TSA Pipeline |
| **Manufacturing** | PLC, MES, Robotics | IEC 62443, NIST CSF |
| **Water/Wastewater** | SCADA, RTU | AWIA, IEC 62443 |
| **Transportation** | Rail control, Traffic | TSA directives, IEC 62278 |
| **Chemical** | DCS, SIS | CFATS, IEC 61511 |
| **Pharmaceutical** | DCS, BPCS | FDA 21 CFR Part 11, GMP |

## Certification Path

```
Entry Level                     Mid-Career                    Senior
────────────────────────────────────────────────────────────────────────

CompTIA Security+  ───────►  GICSP  ───────────────►  GRID
       │                       │                        │
       │                       │                        │
       ▼                       ▼                        ▼
CompTIA CySA+  ────────►  CSSA (SANS)  ──────────►  GCIA + GCIP
       │                       │                        │
       │                       │                        │
       ▼                       ▼                        ▼
CCNA/Network+  ────────►  ISA/IEC 62443  ─────────►  CISSP + GRID
                              Specialist

────────────────────────────────────────────────────────────────────────
  0-2 years                  2-5 years                  5+ years
```

## How to Use This Guide

### For Self-Study

1. Read sections in order (they build on each other)
2. Complete hands-on labs after each section
3. Build a home lab (see [14-hands-on-labs](14-hands-on-labs.md))
4. Join OT security communities (see [15-resources](15-resources.md))

### For Team Training

1. Assign one section per week
2. Conduct group discussions after each section
3. Run tabletop exercises using scenarios provided
4. Track progress through competency checklists

### For Reference

1. Use section headers to jump to specific topics
2. Reference quick-reference tables during assessments
3. Link to official standards and vendor documentation

## Prerequisites

Before starting, you should have:

- [ ] Basic networking knowledge (TCP/IP, routing, firewalls)
- [ ] Linux command line familiarity
- [ ] Understanding of basic security concepts
- [ ] Willingness to think differently about security

## Relationship to WALLIX Documentation

This OT fundamentals guide complements the WALLIX Bastion documentation:

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Documentation Structure                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   ot/                          docs/                                 │
│   ├── OT Fundamentals          ├── 15-industrial-overview/           │
│   │   (This Guide)             │   (PAM in OT context)               │
│   │                            ├── 16-ot-architecture/               │
│   │   WHY OT is different      │   (WALLIX deployment)               │
│   │   WHAT you need to know    ├── 17-industrial-protocols/          │
│   │   HOW to think about OT    │   (Protocol support)                │
│   │                            └── 18-23: Implementation             │
│   │                                                                  │
│   └── Foundation knowledge     └── WALLIX-specific guidance          │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

Read the `/ot` guide first to understand OT fundamentals, then the `/docs` sections for WALLIX-specific implementation.

## Contributing

This guide evolves with the OT security landscape. Contributions welcome:

- Real-world case studies (anonymized)
- Updated threat intelligence
- New compliance requirements
- Lab exercises and scenarios

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | January 2026 | Initial release |

---

**Ready to begin?** Start with [01-ot-fundamentals.md](01-ot-fundamentals.md)
