# Scope & Proposal Template

## Engagement Scoping, Effort Estimation, and Statement of Work

This document is used during pre-sales to define the engagement scope, estimate
effort, and produce a Statement of Work (SOW) that both parties can sign. A
precise scope protects the client from scope creep and protects the delivery
team from under-priced engagements.

Complete the ROI worksheet in `05-business-case-roi.md` before using this
template — the scope must be calibrated to the risk level and budget range
already established.

---

## Table of Contents

1. [Engagement Phases Overview](#1-engagement-phases-overview)
2. [Scope Definition Inputs](#2-scope-definition-inputs)
3. [Effort Estimation by Component](#3-effort-estimation-by-component)
4. [Statement of Work Template](#4-statement-of-work-template)
5. [Deliverables Catalogue](#5-deliverables-catalogue)
6. [Assumptions and Exclusions](#6-assumptions-and-exclusions)
7. [Dependency and Risk Register](#7-dependency-and-risk-register)
8. [Pricing Model Reference](#8-pricing-model-reference)
9. [Change Request Process](#9-change-request-process)

---

## 1. Engagement Phases Overview

Every WALLIX PAM engagement follows a standard phase structure regardless
of size. The scope of each phase varies; the sequence does not.

```
+===============================================================================+
|  ENGAGEMENT PHASES                                                           |
+===============================================================================+
|                                                                               |
|  Phase 0     Phase 1      Phase 2       Phase 3       Phase 4               |
|  Pre-Sales   Discovery    Deployment    Hardening     Handover               |
|  --------    ---------    ----------    ---------     --------               |
|  Business    Assessment   Install       MFA config    Training               |
|  case        Workshops    Configure     Compliance    Docs                   |
|  Scope       Design       Integrate     Testing       Sign-off               |
|  SOW         Arch sign-   AD/LDAP       Pen test      Runbooks               |
|              off          Session rec   Go-live       Hypercare              |
|                                                                               |
|  Typical     2-4 weeks    2-6 weeks     2-4 weeks     2-4 weeks             |
|  duration                                                                    |
|                                                                               |
+===============================================================================+
```

Phase 0 (pre-sales) is not billed unless the client requests a paid discovery
sprint before committing to the full engagement. This is common in large or
complex environments.

---

## 2. Scope Definition Inputs

Collect these inputs from `01-discovery-assessment.md` before sizing the
engagement. Scope drives price. Missing inputs lead to change requests.

### 2.1 Environment Size Parameters

| Parameter | Client Value | Impact on Scope |
|-----------|-------------|-----------------|
| Number of sites | | Major — each additional site adds deployment effort |
| Bastion nodes per site (HA model) | | Major — Active-Active vs Active-Passive changes effort |
| Number of Access Manager nodes | | Medium — HA adds integration and test effort |
| Number of target systems in scope | | Medium — proportional to integration and test effort |
| Number of privileged users | | Medium — proportional to onboarding and training effort |
| Number of third-party vendors | | Medium — JIT configuration multiplies by vendor count |
| OT systems in scope | | High — OT adds protocol coverage, latency testing, safety checks |
| FortiAuthenticator nodes | | Medium — HA adds configuration and sync effort |
| SIEM integration required | | Medium — platform-specific connector configuration |
| AD/LDAP domains in scope | | Medium — each forest/domain requires separate integration |

### 2.2 Complexity Multipliers

Apply these multipliers to base estimates when the environment has the
following characteristics:

| Condition | Multiplier | Reason |
|-----------|-----------|--------|
| First PAM deployment (no prior experience) | +30% | More design workshops, more client education |
| Legacy OT systems in scope | +25% | Protocol coverage, latency testing, safety validation |
| Multiple AD forests | +20% per additional forest | Each forest requires separate LDAP integration |
| Air-gapped environment | +40% | Manual artefact transfer, no remote access |
| Regulated environment (PCI, NIS2, IEC 62443) | +15% | Compliance documentation and evidence collection |
| Existing PAM tool to migrate from | +20% | Account migration, parallel running period |
| Custom SIEM integration (non-standard platform) | +30% | Connector development or syslog normalisation |

---

## 3. Effort Estimation by Component

Use these base estimates for a single-site, single-domain, non-OT deployment.
Apply multipliers from Section 2.2 as needed.

### 3.1 Phase 1 — Discovery and Design

| Activity | Effort (days) | Who |
|----------|--------------|-----|
| Kickoff workshop (on-site or remote) | 1 | Senior consultant |
| AD/LDAP environment assessment | 1 | Senior consultant |
| Network and firewall review | 0.5 | Senior consultant |
| Target system inventory and protocol review | 1 | Senior consultant + client team |
| Architecture design document | 2 | Senior consultant |
| Architecture review and sign-off workshop | 0.5 | Senior consultant |
| Pre-production lab setup (if client lab available) | 2 | Senior consultant |
| **Phase 1 total (base)** | **8** | |

### 3.2 Phase 2 — Deployment and Integration

| Activity | Effort (days) | Who |
|----------|--------------|-----|
| Bastion installation (per node) | 0.5 | Senior consultant |
| Bastion HA configuration (Pacemaker/Corosync) | 1 | Senior consultant |
| HAProxy installation and Keepalived configuration | 1 | Senior consultant |
| TLS certificate installation and validation | 0.5 | Senior consultant |
| AD/LDAP integration and user group mapping | 1 | Senior consultant |
| FortiAuthenticator RADIUS integration | 1 | Senior consultant |
| Target device onboarding (per 20 targets) | 1 | Consultant |
| User account and role configuration | 1 | Consultant |
| Session recording configuration and validation | 0.5 | Consultant |
| Password vault initial population (per 20 accounts) | 0.5 | Consultant |
| SIEM integration (standard platform) | 1 | Senior consultant |
| Access Manager integration (if in scope) | 2 | Senior consultant |
| **Phase 2 total (base, single site)** | **10–12** | |

### 3.3 Phase 3 — Hardening and Testing

| Activity | Effort (days) | Who |
|----------|--------------|-----|
| Firewall rule review and tightening | 0.5 | Senior consultant |
| MFA rollout and token provisioning (per 50 users) | 1 | Consultant |
| JIT access configuration and workflow testing | 1 | Senior consultant |
| Credential rotation configuration and testing | 1 | Senior consultant |
| HA failover testing | 0.5 | Senior consultant + client team |
| End-to-end user acceptance testing | 1 | Consultant + client team |
| Compliance evidence collection (if required) | 1 | Senior consultant |
| Security review / internal pen test coordination | 0.5 | Senior consultant |
| Go-live preparation and checklist review | 0.5 | Senior consultant |
| **Phase 3 total (base)** | **7** | |

### 3.4 Phase 4 — Handover and Hypercare

| Activity | Effort (days) | Who |
|----------|--------------|-----|
| Administrator training (half-day session) | 0.5 | Senior consultant |
| Operator training (half-day session, per site) | 0.5 | Consultant |
| Operations runbook finalisation | 1 | Senior consultant |
| Break-glass procedure documentation and rehearsal | 0.5 | Senior consultant |
| Handover workshop and Q&A | 0.5 | Senior consultant |
| Hypercare support (2 weeks, remote) | 2 | Consultant |
| Final project report | 1 | Senior consultant |
| **Phase 4 total (base)** | **6** | |

### 3.5 Multi-Site Scaling

For each additional site beyond the first, apply the following incremental
effort estimates (assuming the design and AD integration are already complete):

| Additional Site Activity | Effort (days) |
|-------------------------|--------------|
| Site infrastructure deployment (Bastion HA + HAProxy) | 3 |
| Site-local FortiAuthenticator configuration | 1 |
| Target device onboarding (per 20 targets) | 1 |
| Site-local testing and validation | 1 |
| Site-local operator training | 0.5 |
| **Per additional site (base)** | **6–8** |

### 3.6 Effort Summary Template

```
+===============================================================================+
|  EFFORT SUMMARY — [CLIENT NAME]                                              |
+===============================================================================+
|                                                                               |
|  Phase 1 — Discovery & Design                                                |
|    Base estimate:                           ____  days                       |
|    Complexity multipliers:                  ____  days                       |
|    Phase 1 total:                           ____  days                       |
|                                                                               |
|  Phase 2 — Deployment & Integration                                          |
|    Base (Site 1):                           ____  days                       |
|    Additional sites (____  × 7 days):       ____  days                       |
|    OT systems (if in scope):                ____  days                       |
|    Complexity multipliers:                  ____  days                       |
|    Phase 2 total:                           ____  days                       |
|                                                                               |
|  Phase 3 — Hardening & Testing                                               |
|    Base estimate:                           ____  days                       |
|    Complexity multipliers:                  ____  days                       |
|    Phase 3 total:                           ____  days                       |
|                                                                               |
|  Phase 4 — Handover & Hypercare                                              |
|    Base estimate:                           ____  days                       |
|    Additional site training:                ____  days                       |
|    Phase 4 total:                           ____  days                       |
|                                                                               |
|  TOTAL EFFORT:                              ____  days                       |
|  CONTINGENCY (15%):                         ____  days                       |
|  TOTAL INCLUDING CONTINGENCY:               ____  days                       |
|                                                                               |
+===============================================================================+
```

---

## 4. Statement of Work Template

Replace all `[bracketed]` fields with client-specific values.

---

```
STATEMENT OF WORK
WALLIX Bastion Privileged Access Management Deployment

Client:               [CLIENT LEGAL NAME]
Engagement Reference: [REFERENCE NUMBER]
Date:                 [DATE]
Version:              1.0

1. ENGAGEMENT OVERVIEW

[CONSULTING FIRM] will deploy WALLIX Bastion 12.1.x as a Privileged Access
Management (PAM) solution for [CLIENT NAME]. The deployment covers [N] sites
and targets the integration of [N] AD domains, [N] FortiAuthenticator nodes,
and approximately [N] target devices.

The engagement is structured in four phases as described in this document.

2. SCOPE OF WORK

2.1 In Scope

  Infrastructure Deployment
  - Installation and configuration of WALLIX Bastion on [N] nodes at [N] sites
  - HA configuration (Active-[Active/Passive]) per site
  - HAProxy installation and Keepalived VRRP configuration at [N] sites
  - WALLIX Access Manager installation and configuration ([N] nodes)
  - TLS certificate deployment and validation

  Authentication Integration
  - Active Directory / LDAP integration for [N] domain(s): [DOMAIN NAMES]
  - FortiAuthenticator RADIUS integration at [N] sites
  - MFA rollout for [N] privileged users
  - [FortiToken 200 hardware / FortiToken Mobile software] provisioning

  Target Onboarding
  - Device configuration for approximately [N] target systems
  - Protocol coverage: [SSH / RDP / VNC / Telnet / HTTP — list applicable]
  - Session recording configuration and validation for all target types

  Credential Management
  - Password vault initial population for [N] accounts
  - Automatic rotation configuration for [N] account types
  - Break-glass account configuration and procedure documentation

  Access Control
  - RBAC configuration for [N] user roles: [LIST ROLES]
  - JIT access workflow configuration for [N] target groups
  - Third-party / vendor access portal configuration

  Monitoring and Compliance
  - SIEM integration: [PLATFORM NAME]
  - Session recording retention policy: [N] days
  - Compliance evidence package: [GDPR / NIS2 / IEC 62443 / PCI-DSS]

2.2 Out of Scope (see Section 6 for full exclusions list)

  - Procurement of hardware, licenses, or FortiToken devices
  - Network infrastructure changes beyond firewall rule recommendations
  - Active Directory design, remediation, or domain controller deployment
  - SIEM platform installation or configuration beyond the Bastion connector
  - Physical site access, cabling, or rack installation
  - Penetration testing (can be added as a separate work order)
  - Ongoing managed service or 24/7 operational support

3. DELIVERABLES

  Phase 1:  Architecture Design Document (ADD)
            Pre-production lab validation report
  Phase 2:  Deployment configuration record (per site)
            Integration test results
  Phase 3:  HA failover test report
            UAT sign-off sheet
            Compliance evidence package
  Phase 4:  Administrator operations runbook
            Break-glass procedure document
            Final project report with recommendations

4. TIMELINE

  Phase 1 — Discovery & Design:      Weeks 1–[N]
  Phase 2 — Deployment & Integration: Weeks [N]–[N]
  Phase 3 — Hardening & Testing:      Weeks [N]–[N]
  Phase 4 — Handover & Hypercare:     Weeks [N]–[N]
  Target go-live:                     [DATE]
  Hypercare end:                      [DATE]

  All timelines are contingent on the client dependencies listed in
  Section 7 being met on schedule.

5. EFFORT AND COMMERCIAL TERMS

  Total estimated effort:     [N] consulting days
  Contingency (included):     [N] consulting days (15%)
  Daily rate (senior):        €[RATE]
  Daily rate (consultant):    €[RATE]
  Total professional services: €[AMOUNT]

  Expenses (travel, accommodation):  [Billed at cost / Included / Capped at €N]
  Software licenses:                 [Procured by client / Supplied by us]
  Payment terms:                     [30% on signature / 40% at Phase 2 start / 30% at go-live]

6. ASSUMPTIONS

  The following assumptions are made in preparing this Statement of Work.
  Material changes to these assumptions will be addressed via the change
  request process in Section 9.

  Infrastructure
  - Client will provide [N] physical or virtual servers meeting WALLIX
    minimum specifications before Phase 2 begins.
  - All target systems are network-reachable from the Bastion at Phase 2 start.
  - DNS is resolvable for all target hostnames from the Bastion.
  - NTP is synchronised across all components.

  Active Directory
  - AD is operational and reachable from the Bastion network segment.
  - A service account with read access to the relevant OUs will be provided.
  - User accounts for all [N] privileged users exist in AD.

  FortiAuthenticator
  - FortiAuthenticator [N.N] or later is installed or will be installed
    before Phase 2 begins.
  - FortiToken licenses are procured and available for import.
  - FortiToken hardware devices (if applicable) are on-site before Phase 3.

  Network
  - Firewall rules between Bastion and target VLANs will be approved and
    implemented within [N] business days of the rule specification provided
    at the end of Phase 1.
  - A VLAN or network segment for the Bastion DMZ is available and configured.

  Client Availability
  - A named client technical contact is available for at least [N] hours
    per week throughout the engagement.
  - A client AD administrator is available for the AD integration sessions
    in Phase 2 (estimated [N] hours total).
  - Operations managers are available for go-live and training sessions.

7. EXCLUSIONS

  The following items are explicitly excluded from this Statement of Work:

  - Hardware procurement, physical installation, and rack/stack work
  - WALLIX Bastion software licenses (procured by client)
  - FortiToken hardware devices and FortiToken license procurement
  - Active Directory health remediation (DNS, replication, time sync)
  - Network design or firewall platform configuration
  - SIEM platform installation, tuning, or managed service
  - Endpoint agent deployment (not required by WALLIX Bastion)
  - Security awareness training for general staff
  - Custom development (API integrations, custom connectors, automation)
  - Post-hypercare support (covered by separate support agreement)
  - Compliance audit execution or certification

8. ACCEPTANCE CRITERIA

  Phase 1 accepted when:
  - Architecture Design Document reviewed and signed by client technical lead.

  Phase 2 accepted when:
  - All Bastion nodes operational and reachable.
  - AD/LDAP authentication functioning for all in-scope user groups.
  - Session recording validated for at least one target per protocol type.

  Phase 3 accepted when:
  - HA failover tested and documented with client witness.
  - MFA enforced for all in-scope users.
  - Compliance evidence package reviewed by client compliance owner.
  - UAT sign-off sheet completed and signed.

  Phase 4 (project closure) accepted when:
  - All deliverables listed in Section 3 have been handed over.
  - Final project report accepted.
  - Hypercare period completed.

9. CHANGE REQUEST PROCESS

  Any change to scope, timeline, or commercial terms requires a written
  Change Request (CR). The process is:

  1. Either party raises a CR in writing (email is sufficient).
  2. [CONSULTING FIRM] provides an impact assessment within [3] business days:
     scope change, effort impact, cost impact, timeline impact.
  3. Client approves or rejects the CR in writing.
  4. Approved CRs are appended to this SOW and take effect immediately.

  Work arising from an approved CR will not begin until the commercial
  terms are agreed. If a CR requires significant additional effort, a
  partial payment may be required before the work begins.

AUTHORISED SIGNATURES

[CONSULTING FIRM]                    [CLIENT]
Name:  ____________________          Name:  ____________________
Title: ____________________          Title: ____________________
Date:  ____________________          Date:  ____________________
```

---

## 5. Deliverables Catalogue

Reference this catalogue when defining deliverables in the SOW. Each
deliverable has a standard format and acceptance criteria.

| Deliverable | Phase | Format | Owner | Acceptance |
|-------------|-------|--------|-------|-----------|
| Architecture Design Document (ADD) | 1 | PDF/Markdown | Senior consultant | Client technical lead sign-off |
| Pre-production lab report | 1 | PDF | Senior consultant | Client technical review |
| Deployment configuration record | 2 | Markdown per site | Consultant | Client technical lead review |
| AD/LDAP integration test results | 2 | Test report | Consultant | Client AD admin sign-off |
| FortiAuthenticator integration test | 2 | Test report | Consultant | Client security team sign-off |
| HA failover test report | 3 | Test report with screenshots | Senior consultant | Client witness signature |
| UAT sign-off sheet | 3 | Form | Consultant + client | Client technical lead signature |
| MFA rollout completion record | 3 | User list + status | Consultant | Client security owner sign-off |
| Compliance evidence package | 3 | PDF dossier | Senior consultant | Client compliance owner review |
| Operations runbook | 4 | Markdown | Senior consultant | Client admin team review |
| Break-glass procedure | 4 | Markdown | Senior consultant | Physical copy in client safe |
| Final project report | 4 | PDF | Senior consultant | Client project sponsor sign-off |

---

## 6. Assumptions and Exclusions

### 6.1 Client Responsibilities (RACI — Client)

The client is responsible for the following items throughout the engagement.
Delays in these items will affect the timeline and may trigger a CR.

| Item | Deadline | Contact |
|------|---------|---------|
| Server provisioning (specs from ADD) | Before Phase 2 start | Infrastructure team |
| Network VLAN creation | Before Phase 2 start | Network team |
| Firewall rule implementation | Within 3 days of specification | Network/security team |
| AD service account creation | Before Phase 2 Day 1 | AD admin |
| FortiToken license procurement | Before Phase 3 start | Procurement |
| FortiToken hardware delivery (if applicable) | Before Phase 3 start | Procurement |
| User list (privileged users) for MFA rollout | Before Phase 3 start | IT manager |
| Vendor / contractor list for JIT configuration | Before Phase 3 start | IT manager |
| Operations manager availability for UAT | Phase 3 schedule | Operations |
| Secure safe for break-glass credentials | Before go-live | Facilities / security |

### 6.2 Standard Exclusions

Include these exclusions in every SOW unless explicitly agreed otherwise:

- Hardware procurement and physical installation
- Software license procurement (WALLIX, FortiToken, OS)
- Active Directory remediation (DNS, replication issues, schema updates)
- Network design or changes to existing network infrastructure
- SIEM platform deployment and configuration beyond the Bastion log connector
- Security awareness training for non-privileged users
- Custom API development or automation beyond standard Bastion APIs
- Post-hypercare operational support (governed by a separate support agreement)
- Penetration testing (available as a separate work order)
- Application-layer integration (ERP, ITSM, CMDB beyond API samples)

---

## 7. Dependency and Risk Register

Maintain this register throughout the engagement and review it at every
weekly status meeting.

| # | Dependency / Risk | Probability | Impact | Owner | Mitigation |
|---|------------------|------------|--------|-------|-----------|
| 1 | Server provisioning delayed | Medium | High | Client infra team | Confirm server readiness date at Phase 1 close; add to critical path |
| 2 | Firewall rules blocked by change freeze | Medium | High | Client network team | Identify freeze dates in Phase 1; schedule rules before freeze |
| 3 | AD service account permissions insufficient | Low | Medium | Client AD admin | Test account permissions in Phase 1 lab; document required permissions |
| 4 | FortiToken hardware delayed | Low | High | Client procurement | Order at SOW signature; track delivery against Phase 3 start date |
| 5 | OT maintenance window unavailable | Medium | High | Client OT team | Confirm window in Phase 1; if none available, limit Phase 2 to DMZ only |
| 6 | Legacy target system incompatible | Low | Medium | Senior consultant | Test each protocol type in pre-production lab before production rollout |
| 7 | Client AD admin unavailable | Low | Medium | Client IT manager | Name a backup AD contact in Phase 1 kickoff |
| 8 | Network latency exceeds HMI tolerance | Low | High | Senior consultant | Latency test mandatory in pre-production; document results and exceptions |
| 9 | Client change management board delays | Medium | Medium | Client PM | Include PAM changes in next CAB cycle; schedule CAB dates in Phase 1 |
| 10 | Scope expansion requested mid-engagement | High | Medium | Senior consultant | Enforce CR process; do not absorb additional scope without written approval |

---

## 8. Pricing Model Reference

### 8.1 Engagement Types

| Engagement Type | Structure | Typical Use Case |
|----------------|-----------|-----------------|
| Fixed-price | Agreed scope, fixed fee, CR process for changes | Well-defined environments, standard deployments |
| Time and materials | Daily rate, monthly invoicing | Complex or unknown environments, OT, large multi-site |
| Phased fixed-price | Fixed price per phase, scope locked at phase start | Phased rollouts, budget approval per phase |
| Retainer | Monthly fee for defined ongoing services | Post-deployment operations support, health checks |

### 8.2 Rate Card Reference

| Role | Indicative Daily Rate |
|------|-----------------------|
| Principal consultant / architect | €1,400–€1,800 |
| Senior consultant | €1,100–€1,400 |
| Consultant | €800–€1,100 |
| Project manager (if separate) | €900–€1,200 |

Rates vary by region and client contract. Use the rate card applicable to
the specific client agreement.

### 8.3 License Sizing Reference

WALLIX Bastion is licensed per named user and per target account. Provide
these inputs to the WALLIX account team for a formal quote:

| Input | Value |
|-------|-------|
| Number of named privileged users | |
| Number of managed target accounts | |
| Number of Bastion nodes | |
| HA required (yes/no) | |
| Access Manager nodes | |
| Session recording retention (months) | |
| FortiToken quantity (hardware/software) | |

**Reference:** `docs/pam/48-licensing/` for WALLIX licensing model detail.

---

## 9. Change Request Process

### 9.1 Change Request Form

Use this form for all scope changes, regardless of size.

```
CHANGE REQUEST
Engagement Reference: ____________________________
CR Number:           ____________________________  (sequential)
Date Raised:         ____________________________
Raised By:           ____________________________

DESCRIPTION OF CHANGE
____________________________________________________________________
____________________________________________________________________
____________________________________________________________________

REASON FOR CHANGE
[ ] Client requirement change
[ ] Environment differs from discovery assumptions
[ ] Technical blocker requires alternative approach
[ ] Regulatory or compliance requirement added
[ ] Other: ____________________________

IMPACT ASSESSMENT (completed by consulting firm)

Scope impact:      ____________________________________________________
Effort impact:     ____  additional days
Cost impact:       € ____________________
Timeline impact:   ____  additional days / no change
Dependencies:      ____________________________________________________

APPROVAL

Consulting Firm:   ____________________  Date: ____________________
Client Approval:   ____________________  Date: ____________________
Status:            [ ] Approved  [ ] Rejected  [ ] Pending
```

### 9.2 CR Principles

- Every scope change, no matter how small, requires a signed CR.
- Verbal agreements are not valid. "We agreed in the meeting" is not sufficient.
- The consulting team should never begin work on a CR before client approval.
- CRs are numbered sequentially and appended to the SOW.
- A CR that adds more than 5 days of effort requires a partial payment
  confirmation before work begins.

---

*Related documents in this toolkit:*
- *[Discovery & Assessment](01-discovery-assessment.md) — inputs for the scope definition*
- *[Business Case & ROI](05-business-case-roi.md) — establish budget range before scoping*
- *[Engagement Playbook](03-engagement-playbook.md) — delivery timeline and milestone detail*
- *[Training & Change Management](07-training-change-mgmt.md) — Phase 4 handover planning*
