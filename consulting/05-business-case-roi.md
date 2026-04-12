# Business Case & ROI Guide

## Justifying PAM Investment to Executive Stakeholders

This guide is used before the technical engagement begins. Its purpose is to
help the client secure internal budget approval and executive sponsorship. The
conversation happens with CFOs, CISOs, and risk committees — not with IT teams.

Lead with risk quantification. Follow with compliance obligation. Close with
operational efficiency. Never open with product features.

---

## Table of Contents

1. [The Executive Conversation](#1-the-executive-conversation)
2. [Quantifying the Breach Risk](#2-quantifying-the-breach-risk)
3. [Compliance Fine Exposure](#3-compliance-fine-exposure)
4. [Cyber Insurance Impact](#4-cyber-insurance-impact)
5. [Operational Cost Savings](#5-operational-cost-savings)
6. [ROI Calculation Worksheet](#6-roi-calculation-worksheet)
7. [Presenting to the Board](#7-presenting-to-the-board)
8. [Objection Handling](#8-objection-handling)
9. [One-Page Executive Summary Template](#9-one-page-executive-summary-template)
10. [Reference Data](#10-reference-data)

---

## 1. The Executive Conversation

### 1.1 The Opening Frame

Before any number is presented, establish the risk context. Executives approve
budgets for problems they understand, not for technology they do not.

**For the CFO:**

> "The financial exposure from a privileged access breach in your environment
> is not theoretical. It has a calculable range based on your sector, headcount,
> and data profile. What we are proposing is a control that directly reduces
> the probability of that event and caps your liability exposure. The investment
> is a fraction of the expected loss if the event occurs without the control
> in place."

**For the CISO:**

> "Privileged credentials are the primary lateral movement vector in every
> major breach category — ransomware, APT, insider threat. PAM does not
> eliminate all risk, but it eliminates the single highest-leverage attack
> path. It also provides the audit trail that regulators and insurers require
> after an incident."

**For the board or risk committee:**

> "We are asking for approval to implement a control that addresses the
> number one root cause of significant cyber losses: compromised privileged
> access. Regulatory frameworks now mandate this control. Our cyber insurer
> has flagged its absence as a coverage condition. The question is not
> whether to implement it but how quickly."

### 1.2 What Executives Need to Approve a Budget

A successful business case answers four questions:

| Question | Section That Answers It |
|----------|------------------------|
| What is the cost of not acting? | Sections 2, 3, 4 |
| What does the investment cost? | Section 6 |
| What do we get for that investment? | Sections 5, 6 |
| What is the payback period? | Section 6 |

---

## 2. Quantifying the Breach Risk

### 2.1 Industry Benchmark Data

Use these figures in client conversations. Cite the source when presenting
to executives — credibility depends on external validation.

| Metric | Value | Source |
|--------|-------|--------|
| Average total cost of a data breach | $4.88M | IBM Cost of a Data Breach 2024 |
| Average cost per record compromised | $165 | IBM Cost of a Data Breach 2024 |
| Breaches involving stolen credentials | 80% | Verizon DBIR 2024 |
| Breaches involving privileged access abuse | 74% | Verizon DBIR 2024 |
| Mean time to identify a breach | 194 days | IBM Cost of a Data Breach 2024 |
| Mean time to contain a breach | 64 days | IBM Cost of a Data Breach 2024 |
| Cost reduction with PAM deployed | ~$1.1M average | IBM Cost of a Data Breach 2024 |
| Ransomware average payment (large enterprise) | $2.0M+ | Sophos State of Ransomware 2024 |

**References:**
- [IBM Cost of a Data Breach Report 2024](https://www.ibm.com/reports/data-breach)
- [Verizon Data Breach Investigations Report 2024](https://www.verizon.com/business/resources/reports/dbir/)
- [Sophos State of Ransomware 2024](https://www.sophos.com/en-us/content/state-of-ransomware)

### 2.2 Breach Cost by Sector

Adjust the baseline cost by sector when presenting to specific clients:

| Sector | Average Breach Cost | Notable Multiplier |
|--------|--------------------|--------------------|
| Healthcare | $9.77M | Highest of any sector |
| Financial services | $6.08M | Regulatory fines compound total |
| Industrial / manufacturing | $4.73M | OT downtime adds operational loss |
| Energy / utilities | $4.72M | NIS2 / NERC CIP fines compound |
| Retail | $2.96M | Card data scope expands to PCI-DSS |
| Public sector | $2.60M | Lower but reputational impact high |

### 2.3 Annualized Loss Expectancy Model

To produce a defensible financial figure for the client's CFO, use the
Annualized Loss Expectancy (ALE) model:

```
ALE  =  Single Loss Expectancy (SLE)  ×  Annual Rate of Occurrence (ARO)

SLE  =  Asset Value  ×  Exposure Factor

Example for a mid-size industrial client:
  - Estimated breach cost (SLE):          €3,500,000
  - Industry breach probability per year: 27% (Ponemon 2024)
  - ALE (pre-control):                    €945,000

With PAM deployed:
  - Residual breach probability:          ~8%  (74% risk reduction)
  - ALE (post-control):                   €280,000

Annual risk reduction:                    €665,000
```

**Tip:** Present the ALE reduction — not just the breach cost — to the CFO.
The reduction is the annual value of the investment.

### 2.4 Breach Cost Components

Break down the total breach cost to make it tangible. Not all components
feel real until named:

```
+===============================================================================+
|  BREACH COST COMPONENTS                                                      |
+===============================================================================+
|                                                                               |
|  Direct Costs                      Indirect Costs                            |
|  --------------------------------  --------------------------------           |
|  Forensic investigation            Customer churn and lost revenue           |
|  Incident response (external)      Reputational damage                       |
|  Legal and regulatory defence      Share price impact (listed companies)     |
|  Regulatory notification costs     Increased insurance premiums              |
|  Credit monitoring for victims     Staff time (months of remediation)        |
|  System rebuild and hardening      Operational disruption                    |
|  Ransom payment (if applicable)    Future audit and compliance costs         |
|  Data recovery                     Executive distraction and board time      |
|                                                                               |
+===============================================================================+
```

---

## 3. Compliance Fine Exposure

### 3.1 GDPR

GDPR fines are the most visible compliance risk in European engagements.
The regulation explicitly requires appropriate technical controls for
privileged access to personal data.

| Tier | Maximum Fine | Trigger |
|------|-------------|---------|
| Tier 1 | €10M or 2% of global annual turnover | Processor obligations, record-keeping |
| Tier 2 | €20M or 4% of global annual turnover | Core principles, data subject rights, unlawful processing |

**Article 32** requires "appropriate technical and organisational measures"
including "a process for regularly testing, assessing and evaluating the
effectiveness of technical and organisational measures." PAM directly
satisfies this requirement.

Notable fines relevant to privileged access failures:
- Meta (Ireland): €1.2B — systematic personal data transfer without controls
- British Airways: £20M — inadequate security controls (ICO, post-breach)
- Marriott: £18.4M — failure to implement adequate access controls

**Reference:** [GDPR Enforcement Tracker](https://www.enforcementtracker.com)

### 3.2 NIS2 Directive

NIS2 came into force in October 2024. It applies to essential and important
entities across energy, water, transport, health, digital infrastructure,
and manufacturing above 50 employees.

| Tier | Maximum Fine |
|------|-------------|
| Essential entities | €10M or 2% of global annual turnover |
| Important entities | €7M or 1.4% of global annual turnover |

Article 21 explicitly requires MFA for privileged access. Non-compliance
after a security incident will trigger supervisory authority investigation.

**Reference:** [NIS2 Directive Full Text](https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX%3A32022L2555)

### 3.3 PCI-DSS v4.0

Requirement 8.4.2 mandates MFA for all access into the cardholder data
environment (CDE). Non-compliance blocks PCI-DSS certification and can
result in card scheme fines of $5,000–$100,000 per month.

### 3.4 Compliance Fine Summary for Client Presentations

```
+===============================================================================+
|  COMPLIANCE FINE EXPOSURE SUMMARY                                            |
+===============================================================================+
|                                                                               |
|  Framework    Applies If             Max Fine                                |
|  ----------   --------------------   ---------------------------------        |
|  GDPR         EU data processed      €20M or 4% global turnover              |
|  NIS2         Essential/important    €10M or 2% global turnover              |
|               entity in EU                                                   |
|  PCI-DSS      Card payments          $5k–$100k/month + certification loss    |
|  NERC CIP     US electric utility    $1M/day per violation                   |
|  HIPAA        US health data         $100–$50,000 per violation              |
|                                                                               |
|  PAM addresses the privileged access control gap in all of the above.        |
|                                                                               |
+===============================================================================+
```

---

## 4. Cyber Insurance Impact

### 4.1 The Insurance Underwriter's View

Cyber insurers now routinely decline coverage or apply exclusions for
organisations without PAM controls. The absence of PAM is a material
underwriting factor.

Common conditions now appearing in cyber insurance questionnaires:

- Is MFA enforced for all privileged access?
- Are privileged session activities logged and retained?
- Are privileged credentials stored in a vault with rotation?
- Is third-party access to critical systems monitored and time-limited?

A "no" answer to any of these does not always block coverage, but it triggers
higher premiums or specific exclusions for credential-based attacks.

### 4.2 Premium Impact Data

| PAM Control Maturity | Typical Premium Impact |
|---------------------|----------------------|
| No PAM, no MFA | Baseline or declined |
| MFA only (no session recording) | 10–15% reduction |
| Full PAM (vault + MFA + recording) | 20–35% reduction |
| PAM + SIEM integration + JIT | Up to 40% reduction |

Source: Marsh Cyber Benchmarking Report 2023; Aon Cyber Insurance Market
Insights 2024.

**References:**
- [Marsh Cyber Insurance Market Report](https://www.marsh.com/en/services/cyber-risk/insights.html)
- [Aon Cyber Solutions](https://www.aon.com/cyber-solutions)

### 4.3 Making the Insurance Argument

For a client paying €500,000/year in cyber insurance premiums:

```
Current premium:                    €500,000/year
Estimated reduction with PAM:       25%
Annual saving:                      €125,000/year
PAM investment (5-site deployment): ~€200,000 (license + implementation)
Payback from insurance alone:       1.6 years
```

Present this calculation with the client's actual premium figure for
maximum impact.

---

## 5. Operational Cost Savings

PAM generates measurable operational savings beyond risk reduction. These
are secondary arguments — useful for CFOs who are already convinced on risk.

### 5.1 Offboarding Time Reduction

Without PAM: removing a departing employee's privileged access requires
updating accounts on every managed system individually. With PAM: one action
(disable in AD) revokes all access.

| Environment Size | Manual Offboarding Time | PAM Offboarding Time | Annual Saving (at €70/hr) |
|-----------------|------------------------|----------------------|--------------------------|
| 50 privileged users | 4h per user | < 5 min | ~€11,200/year |
| 200 privileged users | 4h per user | < 5 min | ~€44,800/year |
| 500 privileged users | 4h per user | < 5 min | ~€112,000/year |

### 5.2 Audit Preparation Time Reduction

Without PAM: preparing a privileged access review for an external auditor
requires extracting logs from multiple systems, correlating them manually,
and producing reports that may have gaps.

With PAM: a structured access report covering all sessions, all users, and
all targets is generated in minutes from the Bastion interface.

Typical saving: 2–5 days of senior engineer time per audit cycle.

### 5.3 Incident Response Time Reduction

When an incident occurs, the first question is always: "Who had access to
that system and what did they do?" Without PAM, answering this question
takes days of log correlation.

With PAM, the answer is a filtered session search: every connection to the
affected target, with full video and keystroke recording, is available in
under five minutes.

Typical saving: 40–60% reduction in time-to-answer for privileged access
forensic questions.

### 5.4 Password Reset Elimination

Automatic credential rotation eliminates a significant volume of service
desk password reset tickets for shared accounts and break-glass credentials.

At a typical IT service desk rate of 20–30 minutes per privileged password
reset, and a large organisation with 500 managed accounts rotating quarterly:

```
Resets per year:   500 accounts × 4 rotations = 2,000 manual resets
Time saved:        2,000 × 25 min = 833 hours
Cost saved:        833 hours × €50/hr = €41,650/year
```

---

## 6. ROI Calculation Worksheet

Use this worksheet in client meetings. Complete with the client's actual
figures to produce a personalised business case.

### 6.1 Risk Reduction Value

```
+===============================================================================+
|  ROI WORKSHEET — RISK REDUCTION                                              |
+===============================================================================+
|                                                                               |
|  A. Breach Cost Estimate                                                     |
|     Industry average breach cost:           € ____________________           |
|     Sector adjustment (see Section 2.2):    × ____________________           |
|     Client-specific adjustment:             × ____________________           |
|     Estimated Single Loss Expectancy (SLE): € ____________________           |
|                                                                               |
|  B. Breach Probability                                                       |
|     Industry annual breach probability:       ____________________  %        |
|     Client risk profile adjustment:           ____________________  %        |
|     Annual Rate of Occurrence (ARO):          ____________________           |
|                                                                               |
|  C. Pre-Control ALE                                                          |
|     ALE = SLE × ARO:                        € ____________________           |
|                                                                               |
|  D. Post-Control ALE                                                         |
|     Risk reduction with PAM (use 74%):      - ____________________  %       |
|     Residual ARO:                             ____________________           |
|     Residual ALE:                           € ____________________           |
|                                                                               |
|  E. Annual Risk Reduction                                                    |
|     Pre-control ALE minus residual ALE:     € ____________________           |
|                                                                               |
+===============================================================================+
```

### 6.2 Compliance Value

```
+===============================================================================+
|  ROI WORKSHEET — COMPLIANCE                                                  |
+===============================================================================+
|                                                                               |
|  Applicable frameworks:  [ ] GDPR  [ ] NIS2  [ ] PCI-DSS  [ ] NERC CIP     |
|                          [ ] HIPAA [ ] ISO 27001  [ ] Other: ____            |
|                                                                               |
|  Maximum fine exposure (sum of applicable):  € ____________________          |
|  Probability of fine without PAM (estimate): ____________________  %         |
|  Annualised fine exposure:                   € ____________________          |
|                                                                               |
+===============================================================================+
```

### 6.3 Insurance Value

```
+===============================================================================+
|  ROI WORKSHEET — INSURANCE                                                   |
+===============================================================================+
|                                                                               |
|  Current annual cyber insurance premium:     € ____________________          |
|  Estimated reduction with full PAM:          ____________________  %         |
|  Annual premium saving:                      € ____________________          |
|                                                                               |
+===============================================================================+
```

### 6.4 Operational Value

```
+===============================================================================+
|  ROI WORKSHEET — OPERATIONAL SAVINGS                                         |
+===============================================================================+
|                                                                               |
|  Offboarding time saving (annual):           € ____________________          |
|  Audit preparation saving (annual):          € ____________________          |
|  Password reset elimination (annual):        € ____________________          |
|  Incident response saving (annual):          € ____________________          |
|  Total operational saving:                   € ____________________          |
|                                                                               |
+===============================================================================+
```

### 6.5 Total Business Case

```
+===============================================================================+
|  ROI SUMMARY                                                                 |
+===============================================================================+
|                                                                               |
|  Annual Benefits                                                             |
|  ------------------------------------------                                 |
|  Risk reduction value (E from 6.1):         € ____________________          |
|  Compliance fine avoidance (from 6.2):      € ____________________          |
|  Insurance premium reduction (from 6.3):    € ____________________          |
|  Operational savings (from 6.4):            € ____________________          |
|  Total annual benefit:                      € ____________________          |
|                                                                               |
|  Investment                                                                  |
|  ------------------------------------------                                 |
|  Software licenses (Year 1):                € ____________________          |
|  Implementation services:                   € ____________________          |
|  Hardware (if applicable):                  € ____________________          |
|  Training:                                  € ____________________          |
|  Year 1 total investment:                   € ____________________          |
|                                                                               |
|  Ongoing annual cost (Year 2+):             € ____________________          |
|  (Maintenance + support + internal effort)                                   |
|                                                                               |
|  Metrics                                                                     |
|  ------------------------------------------                                 |
|  Net Year 1 benefit (benefit - investment): € ____________________          |
|  ROI Year 1: (benefit / investment - 1):      ____________________ %        |
|  Payback period: (investment / benefit):      ____________________ months   |
|  3-year NPV (at ____% discount rate):       € ____________________          |
|                                                                               |
+===============================================================================+
```

---

## 7. Presenting to the Board

### 7.1 What Boards Hear vs. What They Need

Most PAM presentations to boards fail because they contain too much
technology and too little risk language. Boards approve risk budgets, not
technology budgets.

| What consultants say | What boards hear | What boards need |
|---------------------|-----------------|-----------------|
| "We need PAM" | "IT wants more tools" | "Our privileged access risk is unquantified and unmitigated" |
| "WALLIX Bastion proxies sessions" | "Something sits in the network" | "Every admin action is logged, recorded, and attributable" |
| "MFA blocks credential attacks" | "Two-factor authentication" | "Stolen passwords cannot grant access — the attack surface is eliminated" |
| "Session recording enables forensics" | "We record screen sessions" | "If an incident occurs, we can show regulators exactly what happened" |

### 7.2 The Three-Slide Board Summary

If given limited time with a board or executive committee, reduce to three
points:

**Slide 1 — The Risk**
> 80% of breaches begin with compromised privileged credentials. Our
> estimated exposure if this occurs is €[SLE]. We currently have no
> control that prevents a stolen password from accessing our most sensitive
> systems.

**Slide 2 — The Control**
> PAM eliminates this attack vector. It enforces multi-factor authentication
> on every privileged connection, records every session, and removes
> standing access. Our insurance broker has indicated this control will
> reduce our premium by approximately €[saving].

**Slide 3 — The Investment**
> The total Year 1 investment is €[cost]. The annual risk reduction value
> is €[ALE reduction]. Payback is [N] months. We recommend approving
> the programme to proceed.

---

## 8. Objection Handling

| Objection | Response |
|-----------|----------|
| "We have not been breached yet." | "The average organisation is breached 194 days before they know it. The absence of a known breach is not evidence of the absence of a breach. It is evidence of a gap in detection." |
| "We have a firewall and antivirus." | "Perimeter controls address network-level attacks. Privileged access abuse happens inside the perimeter — from a compromised endpoint, a phished credential, or a malicious insider. PAM is the control layer for post-perimeter threats." |
| "This is too expensive." | "The investment is €[cost]. The expected annual loss without the control is €[ALE]. The payback period is [N] months. The question is not whether we can afford it — it is whether we can afford not to implement it before an incident occurs." |
| "We will do it next year." | "NIS2 is already in force. Our next insurance renewal is in [N] months. A breach between now and next year occurs with [ARO]% probability and costs an estimated €[SLE]. The cost of delay is measurable." |
| "Our team can build something in-house." | "A PAM capability built in-house requires development, maintenance, audit certification, and ongoing vulnerability management. WALLIX is certified and audited. In-house solutions rarely meet compliance evidence requirements without significant investment." |
| "We already have CyberArk / BeyondTrust." | "This engagement evaluates the current control coverage against your specific environment. If the existing tool is fully deployed and meeting your requirements, we will say so. If there are gaps, we will quantify them." |

---

## 9. One-Page Executive Summary Template

Use this template to produce a deliverable for the client after the
business case meeting. Fill in the client's values from the ROI worksheet.

---

```
PRIVILEGED ACCESS MANAGEMENT — BUSINESS CASE SUMMARY
Client: ____________________________    Date: ____________________________

RISK CONTEXT
Current privileged access controls are insufficient to prevent credential-
based attacks on critical systems. Industry data indicates that 80% of
breaches involve compromised credentials, and 74% involve privileged access
abuse. The client's estimated annual loss exposure from this risk is €[ALE].

COMPLIANCE OBLIGATION
The client is subject to [GDPR / NIS2 / PCI-DSS / IEC 62443]. Applicable
maximum fines total €[fine exposure]. Article 21 of NIS2 / Requirement 8.4.2
of PCI-DSS / SR 1.5 of IEC 62443 specifically mandates MFA and privileged
session control — controls not currently in place.

INSURANCE
The current cyber insurance premium is €[premium]. The underwriter has
indicated that PAM deployment will reduce the premium by approximately
[N]%, saving €[saving] annually. Absence of PAM is flagged as a coverage
condition in the renewal questionnaire.

PROPOSED INVESTMENT
Year 1 total (license + implementation):    €[cost]
Annual recurring cost (Year 2+):            €[annual]

RETURN ON INVESTMENT
Annual risk reduction value:                €[ALE reduction]
Annual insurance saving:                    €[premium saving]
Annual operational savings:                 €[operational]
Total annual benefit:                       €[total benefit]
Payback period:                             [N] months
3-year net benefit:                         €[3yr NPV]

RECOMMENDATION
Approve the PAM programme. Begin with privileged access to [IT / OT / both]
systems. Target go-live: [date]. Full ROI achieved within [N] months.
```

---

## 10. Reference Data

| Source | Data Point | URL |
|--------|-----------|-----|
| IBM Cost of a Data Breach 2024 | $4.88M average breach cost; 194-day MTTI | https://www.ibm.com/reports/data-breach |
| Verizon DBIR 2024 | 80% breaches involve credentials | https://www.verizon.com/business/resources/reports/dbir/ |
| Sophos State of Ransomware 2024 | $2M+ average ransom payment | https://www.sophos.com/en-us/content/state-of-ransomware |
| Ponemon Institute 2024 | 27% annual breach probability | https://www.ponemon.org |
| Marsh Cyber Benchmarking | 20–35% premium reduction with PAM | https://www.marsh.com/en/services/cyber-risk/insights.html |
| GDPR Enforcement Tracker | Fine database by country and sector | https://www.enforcementtracker.com |
| NIS2 Directive | Article 21 MFA requirement | https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX%3A32022L2555 |
| ENISA NIS2 Implementation | Supervisory authority guidance | https://www.enisa.europa.eu/topics/cybersecurity-policy/nis-directive-new |

---

*Related documents in this toolkit:*
- *[Discovery & Assessment](01-discovery-assessment.md) — gather the inputs for the ROI worksheet*
- *[MFA Strategy Guide](02-mfa-strategy-guide.md) — technical detail behind the MFA control*
- *[Engagement Playbook](03-engagement-playbook.md) — deliver the business case in Phase 0*
