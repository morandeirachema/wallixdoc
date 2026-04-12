# Competitive Positioning Guide

## WALLIX vs. CyberArk, BeyondTrust, Delinea, and Senhasegura

This guide supports pre-sales conversations where the client is evaluating
multiple PAM vendors, has an incumbent tool they are unhappy with, or is
challenging WALLIX on feature parity or brand recognition.

Read this before any competitive situation. Never attack a competitor directly.
Position on fit, deployment model, and total cost — not on product comparison.

---

## Table of Contents

1. [Competitive Landscape Overview](#1-competitive-landscape-overview)
2. [WALLIX Positioning Principles](#2-wallix-positioning-principles)
3. [WALLIX vs. CyberArk](#3-wallix-vs-cyberark)
4. [WALLIX vs. BeyondTrust](#4-wallix-vs-beyondtrust)
5. [WALLIX vs. Delinea (Thycotic / CyberArk Secret Server)](#5-wallix-vs-delinea)
6. [WALLIX vs. Senhasegura](#6-wallix-vs-senhasegura)
7. [Handling the "We Already Have X" Objection](#7-handling-the-we-already-have-x-objection)
8. [RFP and Evaluation Process Guidance](#8-rfp-and-evaluation-process-guidance)
9. [Win / Loss Patterns](#9-win--loss-patterns)

---

## 1. Competitive Landscape Overview

The PAM market is mature. The four major competitors in enterprise deals are:

| Vendor | Headquarters | PAM Approach | Market Position |
|--------|-------------|-------------|----------------|
| **CyberArk** | US / Israel | Agent-based + vault-centric | Market leader by revenue; strongest brand in US and large enterprise |
| **BeyondTrust** | US | Endpoint privilege + remote access | Strong in endpoint privilege management and legacy remote access |
| **Delinea** | US | Vault-centric (ex-Thycotic + Centrify) | Mid-market and SME; Secret Server widely deployed |
| **Senhasegura** | Brazil | Vault + session management | Strong in Latin America and growing in Southern Europe |
| **WALLIX** | France | Session management + vault | Strong in Europe, regulated industries, OT, and multi-site deployments |

**Important context:** In European engagements — especially regulated industries,
public sector, OT, and NIS2-scope clients — WALLIX competes from a position of
strength. The European origin, GDPR-native architecture, and on-premises-first
model are genuine differentiators. Do not open a European deal defensively.

---

## 2. WALLIX Positioning Principles

### 2.1 The Core WALLIX Strengths

Lead with these in every competitive conversation. These are factual,
verifiable, and resonate with European clients:

| Strength | Why It Matters to the Client |
|---------|------------------------------|
| European company, European data sovereignty | No US CLOUD Act exposure on session recordings or vault data |
| On-premises native | Most competitors started SaaS-first; WALLIX was built for on-prem and bare-metal |
| OT / ICS deployment experience | CyberArk and BeyondTrust are IT-centric; WALLIX has documented OT patterns |
| ANSSI-certified (France) | Highest assurance certification in France; relevant across European regulated sectors |
| Simpler architecture | No agents required on targets; proxy-based model reduces deployment complexity |
| Lower total cost of ownership | Licensing model is straightforward; no hidden connector costs or per-target fees |
| WALLIX Access Manager | Single portal across all Bastion sites; competitors require separate infrastructure |
| NIS2 / IEC 62443 alignment | Pre-built compliance mappings for European frameworks |

### 2.2 What to Avoid

- Do not claim WALLIX "beats" any competitor on feature count. In a feature
  comparison, CyberArk will always win on breadth. Win on fit.
- Do not disparage competitor products directly. It damages credibility.
- Do not promise features that are on the roadmap but not in 12.1.x.
- Do not quote competitor pricing. Market pricing changes frequently.

### 2.3 The Reframe

When a client says "CyberArk has more features," reframe to the deployment
question:

> "The relevant question is not which product has more features on a datasheet.
> It is which product your team can deploy, operate, and maintain in your
> specific environment — on-premises, across five sites, with OT targets and
> a small IT security team. Feature sets that are never deployed deliver no
> value. Let us walk through the deployment model that fits your environment
> and your team."

---

## 3. WALLIX vs. CyberArk

### 3.1 CyberArk Profile

CyberArk is the dominant vendor by revenue and brand recognition, particularly
in large US enterprises and financial services. Their flagship products are
Privileged Access Manager (PAM - Self-Hosted, formerly on-prem) and Privilege
Cloud (SaaS).

**CyberArk strengths:**
- Largest ecosystem of integrations and connectors
- Strongest brand recognition with large enterprise CISOs and US-based auditors
- Mature endpoint privilege management (EPM)
- Deep ITSM integrations (ServiceNow, Jira)

**CyberArk weaknesses in European on-prem deals:**
- Complexity: CyberArk deployments require significant professional services
  and internal expertise to maintain. TCO is significantly higher.
- Agent-based model: many connectors require agents on target systems — a
  major friction point in OT environments
- SaaS pressure: Privilege Cloud is cloud-hosted in US datacenters — problematic
  for clients with data sovereignty requirements
- Cost: license costs are substantially higher than WALLIX across all tiers
- Operational overhead: larger internal team required to operate and tune
- Overkill for mid-size deployments: designed for large enterprise; imposes
  large-enterprise complexity on organisations that do not need it

### 3.2 Head-to-Head Positioning

| Dimension | WALLIX | CyberArk | WALLIX Advantage |
|-----------|--------|---------|-----------------|
| Deployment model | On-prem native | On-prem + SaaS (Privilege Cloud) | On-prem clients avoid SaaS pressure |
| Data sovereignty | EU / on-prem | US datacenters for Privilege Cloud | Critical for NIS2 / GDPR clients |
| Architecture | Agentless proxy | Agent-based + vault-centric | No agents on OT targets; simpler deployment |
| OT / ICS support | Native patterns | Limited; requires workarounds | Documented OT deployment; serial-to-IP; Purdue model |
| Deployment complexity | Medium | High | Smaller team can deploy and operate |
| Time to value | 6–10 weeks | 3–6 months | Faster go-live; lower implementation cost |
| TCO (3 years) | Lower | Significantly higher | Lower license + lower services + lower internal headcount |
| European compliance | ANSSI-certified; NIS2-ready | US-centric compliance posture | Resonates with European regulators |
| Vendor support | European support team | US-centric; European through partners | Time zone alignment for European clients |

### 3.3 Talking Points for CyberArk Competitive Situations

**When the client says "CyberArk is the industry standard":**

> "CyberArk is the most widely deployed PAM tool in large US enterprises.
> In European on-premises environments — particularly those with NIS2
> obligations, OT systems, or data sovereignty requirements — the deployment
> model and data residency of Privilege Cloud make it a poor fit. WALLIX is
> ANSSI-certified, designed for on-prem, and operationally maintainable
> by a team of your size. The 'standard' is the one that your team can
> actually deploy and sustain."

**When the client has CyberArk deployed but underused:**

> "This is a pattern we see regularly. CyberArk was deployed, discovered to
> be complex, and is now covering 20% of the originally intended scope.
> The investment was made but the value was not delivered. We should look
> at what is actually deployed and what is not, and assess whether the
> coverage gap can be addressed by extending CyberArk or whether replacing
> with a more operable solution is more efficient. We will not recommend
> replacement unless the numbers support it."

**When the client is in a formal CyberArk evaluation:**

> "We welcome competitive evaluations. We would ask that the evaluation
> criteria include a proof-of-concept deployment in your environment —
> not just a product demo — and that the criteria include time-to-deploy,
> operational effort post-deployment, and total cost of ownership over
> three years. WALLIX consistently wins when the evaluation measures
> those dimensions."

---

## 4. WALLIX vs. BeyondTrust

### 4.1 BeyondTrust Profile

BeyondTrust is strongest in endpoint privilege management (EPM) and legacy
remote access (formerly Bomgar). Their PAM offering is a combination of
Password Safe (vault) and Remote Support / Privileged Remote Access.

**BeyondTrust strengths:**
- Endpoint privilege management (least-privilege on Windows/Mac endpoints)
- Remote support tooling with vendor management features
- Strong in managed service provider (MSP) markets

**BeyondTrust weaknesses:**
- PAM vault and session management are less mature than CyberArk or WALLIX
- Portfolio is fragmented (multiple acquisitions — Bomgar, Lieberman, Avecto)
- OT support is limited
- Session recording quality is lower than WALLIX for complex RDP/VNC scenarios
- Less relevant for pure privileged session management use cases

### 4.2 Head-to-Head Positioning

| Dimension | WALLIX | BeyondTrust | WALLIX Advantage |
|-----------|--------|------------|-----------------|
| Session management depth | High — full video + OCR + keystroke | Medium — session proxying less mature | WALLIX session recording quality is superior |
| OT / ICS | Native patterns | Limited | Documented OT deployment model |
| Vault maturity | High | Medium | WALLIX vault is the core product, not an add-on |
| Endpoint privilege management | Out of scope for WALLIX | Strong (Endpoint Privilege Management) | Not a WALLIX capability — acknowledge honestly |
| Remote support | Not in scope | Strong (Privileged Remote Access) | If vendor remote support tooling is primary need, BeyondTrust may fit better |
| European compliance | ANSSI-certified | US-centric | Same advantage as vs. CyberArk |

### 4.3 When BeyondTrust Is the Better Choice

Be honest in competitive situations. If the client's primary requirement is
endpoint least-privilege management (removing admin rights from end-user
workstations), BeyondTrust EPM is a stronger fit than WALLIX. WALLIX is a
PAM platform, not an endpoint privilege tool. Acknowledge this and focus
on the privileged session and vault use cases where WALLIX excels.

---

## 5. WALLIX vs. Delinea

### 5.1 Delinea Profile

Delinea was formed by the merger of Thycotic and Centrify (2021). Their
flagship products are Secret Server (vault) and Connection Manager (session
management). They target mid-market and SME clients.

**Delinea strengths:**
- Strong vault capabilities (Secret Server is widely adopted)
- Lower price point than CyberArk
- Cloud and on-prem options
- Active mid-market customer base

**Delinea weaknesses:**
- Session recording and management capabilities are less mature than WALLIX
- Post-merger integration is incomplete — some product overlap and support
  inconsistency
- OT support is limited
- European compliance posture is weaker than WALLIX
- Access Manager equivalent (single portal across sites) is less developed

### 5.2 Head-to-Head Positioning

| Dimension | WALLIX | Delinea | WALLIX Advantage |
|-----------|--------|--------|-----------------|
| Session management maturity | High | Medium | WALLIX session proxy is the core product |
| Multi-site architecture | WALLIX Access Manager aggregates all sites | Per-site management | WALLIX is purpose-built for multi-site |
| OT support | Native | Limited | Same advantage as vs. CyberArk and BeyondTrust |
| Vault maturity | High | High (Secret Server is mature) | Draw — Delinea vault is genuinely strong |
| Post-merger stability | Single product line | Integration still in progress | WALLIX product line is coherent and stable |
| European compliance | ANSSI-certified | US-centric | European clients prefer WALLIX |

### 5.3 Delinea Displacement Pattern

When a client has Delinea Secret Server deployed but wants to improve session
management and recording:

> "Secret Server is a solid credential vault. If it is working well for your
> team, you may not need to replace it. We should evaluate whether WALLIX
> Bastion can sit in front of your existing vault as the session management
> layer, rather than replacing the vault entirely. That reduces migration
> risk and allows you to improve session control and recording without a
> full platform change."

---

## 6. WALLIX vs. Senhasegura

### 6.1 Senhasegura Profile

Senhasegura (Brazil) is a growing PAM vendor with strong presence in Latin
America and increasing traction in Southern Europe and the Middle East. They
compete primarily on price and feature completeness.

**Senhasegura strengths:**
- Competitive pricing — often significantly cheaper than WALLIX or CyberArk
- Full-stack PAM: vault + session + discovery + DevOps secrets
- Growing European reference base
- Active development roadmap

**Senhasegura weaknesses:**
- Smaller European support and services ecosystem
- Less mature OT deployment experience
- Brand recognition is low with European enterprise buyers and regulators
- ANSSI-equivalent certification not held
- Implementation partner network in Europe is thin

### 6.2 When Senhasegura Wins on Price

If the client is choosing Senhasegura primarily on price, the conversation
shifts to total cost of ownership and risk:

> "Senhasegura's license cost is lower. The total cost of deployment,
> including implementation services, training, and the internal effort to
> operate and maintain the platform, needs to be evaluated over three years.
> Additionally, for NIS2 or IEC 62443 compliance purposes, regulatory
> evidence packages are better established for WALLIX with European-certified
> documentation. If price is the primary driver, we should build the three-year
> TCO comparison so the decision is based on complete data."

---

## 7. Handling the "We Already Have X" Objection

When a client already has a competitor deployed, do not immediately attempt
displacement. Investigate first.

### 7.1 Discovery Questions for Incumbent Displacement

Ask these questions before proposing any replacement:

| Question | What the Answer Reveals |
|---------|------------------------|
| What percentage of your target scope is currently onboarded? | < 50% coverage = deployment failure risk |
| How many full-time staff manage the platform? | High headcount = operational burden |
| When was the platform last upgraded? | Old versions = growing technical debt |
| Are session recordings being actively reviewed? | "No" = tool is shelfware |
| Are any targets bypassing the PAM tool for convenience? | Bypass = adoption failure |
| What is the annual maintenance and support cost? | Drives TCO comparison |
| Has the tool met your compliance audit requirements? | "Partially" = evidence gaps |

### 7.2 The Coverage Gap Assessment

If the incumbent is deployed but has gaps, offer to perform a coverage gap
assessment before proposing displacement:

> "Before recommending any change, we would like to understand what you
> actually have deployed today versus what was originally in scope. In our
> experience, the conversation changes significantly once you have a precise
> view of coverage, operational cost, and open gaps. We can do that assessment
> in a half-day workshop and give you a factual basis for the decision."

### 7.3 When Not to Displace

Do not recommend displacing a well-deployed incumbent when:
- Coverage is above 80% of intended scope
- The client team is skilled and satisfied with the tool
- A replacement would trigger a multi-year migration project
- The compliance evidence package is already established and accepted

In these cases, position WALLIX as the OT layer or the multi-site overlay
rather than a full replacement.

---

## 8. RFP and Evaluation Process Guidance

### 8.1 Shaping the Evaluation Criteria

When a client is running an RFP, attempt to influence the evaluation criteria
before the RFP is issued. The criteria that favour WALLIX are:

| Criterion | Why It Favours WALLIX |
|-----------|----------------------|
| On-premises deployment capability | WALLIX is on-prem native |
| OT / ICS protocol support | WALLIX has documented OT patterns |
| Proof-of-concept in client environment | WALLIX deploys faster |
| Data residency requirements | WALLIX stores no data in cloud |
| European regulatory certification | ANSSI certification |
| Total cost of ownership over 3 years | WALLIX TCO is lower |
| Time to production coverage | WALLIX deploys faster |
| Internal staff required to operate | WALLIX requires smaller team |

### 8.2 RFP Response Principles

- Answer every question directly. Do not deflect or over-qualify.
- Where WALLIX does not have a feature, say so clearly and explain the
  workaround or roadmap item.
- Include a proof-of-concept offer in every RFP response.
- Include a named reference client (with permission) in the same sector.
- Include the compliance certification documentation (ANSSI, CC) as an annex.

### 8.3 Proof of Concept Strategy

A well-run PoC is WALLIX's strongest competitive tool. Propose a 2-week PoC
in the client's pre-production lab with the following success criteria defined
upfront:

1. Bastion deployed and AD-integrated within 3 days
2. 10 target devices onboarded within 5 days
3. MFA enforced for all test users within 7 days
4. HA failover demonstrated within 10 days
5. Session recording replayed and compliance report generated within 14 days

Define these criteria in writing before the PoC starts. A PoC without agreed
success criteria can be reinterpreted by a competitor at evaluation time.

---

## 9. Win / Loss Patterns

### 9.1 WALLIX Typically Wins When

- Client is European, regulated, and has on-premises infrastructure
- OT or multi-site deployment is a significant component of scope
- The client has previously experienced a complex PAM deployment failure
- Data sovereignty is a board-level requirement
- Speed of deployment and lower operational overhead are evaluation criteria
- The evaluation includes a PoC in the client's environment
- The compliance framework is IEC 62443, NIS2, or ANSSI-adjacent

### 9.2 WALLIX Typically Loses When

- The client's CISO has a prior CyberArk relationship and will not run a PoC
- The procurement is driven by a US-based parent company's global standard
- The evaluation is done purely on analyst report rankings (Gartner Magic
  Quadrant positions CyberArk as leader)
- The client's primary need is endpoint privilege management (not PAM)
- The deal requires an existing professional services partner already engaged
  with a competitor

### 9.3 Loss Recovery

When WALLIX loses a competitive deal, gather the following information for
future positioning:

- What was the stated primary reason for the decision?
- What was the unstated reason (budget / politics / relationship)?
- Which evaluation criteria did WALLIX lose on?
- What was the winning vendor's key differentiator as perceived by the client?
- Was a PoC run? If not, why not?

Log losses in the engagement CRM. Patterns across losses are more valuable
than any single deal analysis.

---

*Related documents in this toolkit:*
- *[Business Case & ROI](05-business-case-roi.md) — TCO comparison arguments*
- *[Scope & Proposal Template](06-scope-proposal-template.md) — PoC scoping*
- *[Discovery & Assessment](01-discovery-assessment.md) — incumbent assessment questions*
