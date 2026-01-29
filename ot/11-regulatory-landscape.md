# OT Regulatory Landscape

Sector-specific cybersecurity requirements beyond IEC 62443.

## Regulatory Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                    OT Cybersecurity Regulations                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Framework Standards (Apply Broadly):                               │
│   ─────────────────────────────────────                              │
│   • IEC 62443 - Industrial automation security                       │
│   • NIST Cybersecurity Framework - Risk management                   │
│   • ISO 27001 - Information security management                      │
│                                                                      │
│   Sector-Specific Regulations:                                       │
│   ────────────────────────────                                       │
│   • NERC CIP - North American electric utilities                     │
│   • TSA Pipeline Directives - US pipelines                           │
│   • NIS2 Directive - EU essential services                           │
│   • CFATS - US chemical facilities                                   │
│   • AWIA - US water utilities                                        │
│   • FDA 21 CFR Part 11 - Pharmaceutical manufacturing                │
│   • Nuclear (10 CFR 73.54) - US nuclear facilities                   │
│                                                                      │
│   Regional Regulations:                                              │
│   ─────────────────────                                              │
│   • EU: NIS2 Directive, GDPR (data aspects)                          │
│   • US: Sector-specific (NERC, TSA, CFATS)                           │
│   • UK: NIS Regulations, Security of Network and Info Systems        │
│   • Australia: SOCI Act                                              │
│   • Singapore: CCoP for Critical Infrastructure                      │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## NERC CIP (Electric Utilities)

### Overview

| Attribute | Value |
|-----------|-------|
| **Full Name** | North American Electric Reliability Corporation Critical Infrastructure Protection |
| **Applicability** | Bulk Electric System (BES) owners and operators |
| **Geography** | US, Canada, portions of Mexico |
| **Enforcement** | FERC (US), Provincial regulators (Canada) |
| **Penalties** | Up to $1 million per day per violation |

### NERC CIP Standards

```
┌─────────────────────────────────────────────────────────────────────┐
│                    NERC CIP Standards Summary                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   CIP-002: BES Cyber System Categorization                           │
│   ──────────────────────────────────────────                         │
│   • Identify and categorize BES Cyber Systems                        │
│   • High, Medium, Low impact categories                              │
│                                                                      │
│   CIP-003: Security Management Controls                              │
│   ─────────────────────────────────────────                          │
│   • Cyber security policies                                          │
│   • Leadership and governance                                        │
│   • Low impact requirements                                          │
│                                                                      │
│   CIP-004: Personnel and Training                                    │
│   ─────────────────────────────────                                  │
│   • Security awareness training                                      │
│   • Personnel risk assessment                                        │
│   • Access management program                                        │
│                                                                      │
│   CIP-005: Electronic Security Perimeter                             │
│   ──────────────────────────────────────                             │
│   • Electronic Security Perimeter (ESP)                              │
│   • Electronic Access Points (EAP)                                   │
│   • Interactive Remote Access                                        │
│                                                                      │
│   CIP-006: Physical Security of BES Cyber Systems                    │
│   ──────────────────────────────────────────────                     │
│   • Physical Security Plan                                           │
│   • Visitor control program                                          │
│   • Physical Access Control Systems                                  │
│                                                                      │
│   CIP-007: System Security Management                                │
│   ───────────────────────────────────                                │
│   • Ports and services                                               │
│   • Security patch management                                        │
│   • Malicious code prevention                                        │
│   • Security event monitoring                                        │
│   • System access controls                                           │
│                                                                      │
│   CIP-008: Incident Reporting and Response                           │
│   ─────────────────────────────────────────                          │
│   • Cyber Security Incident Response Plan                            │
│   • Incident reporting requirements                                  │
│                                                                      │
│   CIP-009: Recovery Plans                                            │
│   ──────────────────────────                                         │
│   • Recovery plan requirements                                       │
│   • Backup and recovery testing                                      │
│                                                                      │
│   CIP-010: Configuration Change Management and Assessments           │
│   ─────────────────────────────────────────────────────────          │
│   • Configuration change management                                  │
│   • Configuration monitoring                                         │
│   • Vulnerability assessments                                        │
│                                                                      │
│   CIP-011: Information Protection                                    │
│   ─────────────────────────────                                      │
│   • Information protection                                           │
│   • BES Cyber System Information disposal                            │
│                                                                      │
│   CIP-012: Communications Between Control Centers                    │
│   ─────────────────────────────────────────────────                  │
│   • Real-time data protection                                        │
│   • Control center communication protection                          │
│                                                                      │
│   CIP-013: Supply Chain Risk Management                              │
│   ──────────────────────────────────────                             │
│   • Vendor risk management                                           │
│   • Software integrity and authenticity                              │
│                                                                      │
│   CIP-014: Physical Security                                         │
│   ──────────────────────────                                         │
│   • Transmission station/substation physical security                │
│   • Third-party vulnerability assessment                             │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### BES Cyber System Categories

| Category | Impact | Example Assets | Requirements |
|----------|--------|----------------|--------------|
| **High** | Blackout > 15 minutes | Control centers, large generators | Full CIP compliance |
| **Medium** | Regional impact | Substations, medium generators | Most CIP requirements |
| **Low** | Limited impact | Small facilities | Reduced requirements |

## TSA Pipeline Security Directives

### Overview

| Attribute | Value |
|-----------|-------|
| **Authority** | Transportation Security Administration |
| **Applicability** | US pipeline owners/operators |
| **Trigger** | Colonial Pipeline attack (2021) |
| **Status** | Mandatory directives since 2021 |

### Key Requirements

```
┌─────────────────────────────────────────────────────────────────────┐
│                    TSA Pipeline Directives                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Security Directive 1 (May 2021):                                   │
│   ─────────────────────────────────                                  │
│   • Report cybersecurity incidents to CISA                           │
│   • Designate Cybersecurity Coordinator                              │
│   • Review current practices                                         │
│   • Identify gaps and remediation measures                           │
│                                                                      │
│   Security Directive 2A/2B (2021-2022):                              │
│   ────────────────────────────────────                               │
│   • Implement specific mitigation measures                           │
│   • Develop and implement cybersecurity contingency/recovery plan    │
│   • Conduct architecture design review                               │
│   • Network segmentation policies and controls                       │
│   • Access control measures                                          │
│   • Continuous monitoring and detection                              │
│   • Patch management                                                 │
│                                                                      │
│   Security Directive 2C/2D (2022-2023):                              │
│   ────────────────────────────────────                               │
│   • Annual cybersecurity assessment plan                             │
│   • Implement Cybersecurity Implementation Plan                      │
│   • Testing requirements                                             │
│                                                                      │
│   Key Outcomes Required:                                             │
│   ───────────────────────                                            │
│   • Network segmentation between IT and OT                           │
│   • Multifactor authentication for remote access                     │
│   • Security monitoring and detection capabilities                   │
│   • Patch management for critical systems                            │
│   • Incident response and recovery capabilities                      │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## NIS2 Directive (European Union)

### Overview

| Attribute | Value |
|-----------|-------|
| **Full Name** | Network and Information Security Directive 2 |
| **Applicability** | Essential and Important entities in EU |
| **Effective** | October 2024 |
| **Penalties** | Up to €10M or 2% global turnover |

### Covered Sectors

```
┌─────────────────────────────────────────────────────────────────────┐
│                    NIS2 Sector Coverage                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   ESSENTIAL ENTITIES (Higher Requirements):                          │
│   ─────────────────────────────────────────                          │
│   • Energy (electricity, oil, gas, hydrogen)                         │
│   • Transport (air, rail, water, road)                               │
│   • Banking and financial market infrastructure                      │
│   • Health                                                           │
│   • Drinking water                                                   │
│   • Wastewater                                                       │
│   • Digital infrastructure                                           │
│   • Public administration                                            │
│   • Space                                                            │
│                                                                      │
│   IMPORTANT ENTITIES:                                                │
│   ───────────────────                                                │
│   • Postal and courier services                                      │
│   • Waste management                                                 │
│   • Chemicals manufacturing                                          │
│   • Food production and distribution                                 │
│   • Manufacturing (medical devices, computers,                       │
│     machinery, motor vehicles)                                       │
│   • Digital providers                                                │
│   • Research                                                         │
│                                                                      │
│   Key Requirements:                                                  │
│   ─────────────────                                                  │
│   • Risk management measures                                         │
│   • Incident handling                                                │
│   • Business continuity                                              │
│   • Supply chain security                                            │
│   • Security in acquisition/development                              │
│   • Vulnerability handling and disclosure                            │
│   • Cryptography and encryption policies                             │
│   • Human resources security                                         │
│   • Access control policies                                          │
│   • Asset management                                                 │
│                                                                      │
│   Incident Reporting:                                                │
│   ───────────────────                                                │
│   • Early warning: within 24 hours                                   │
│   • Incident notification: within 72 hours                           │
│   • Final report: within 1 month                                     │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## CFATS (Chemical Facilities)

### Overview

| Attribute | Value |
|-----------|-------|
| **Full Name** | Chemical Facility Anti-Terrorism Standards |
| **Authority** | CISA (DHS) |
| **Applicability** | Facilities with Chemicals of Interest (COI) |
| **Focus** | Physical and cyber security |

### Risk-Based Performance Standards (RBPS)

| RBPS | Focus |
|------|-------|
| 1 | Restrict area perimeter |
| 2 | Secure site assets |
| 3 | Screen and control access |
| 4 | Deter, detect, and delay |
| 5 | Shipping, receipt, and storage |
| 6 | Theft, diversion, and sabotage |
| 7 | Sabotage of process/release |
| 8 | Cyber security |
| 9 | Response |
| 10 | Monitoring |
| 11 | Training |
| 12 | Personnel surety |
| 13 | Elevated threats |
| 14 | Specific threats |
| 15 | Reporting |
| 16 | Officials and employees |
| 17 | Records |
| 18 | Safeguarding information |

## Water Sector (AWIA)

### America's Water Infrastructure Act

```
┌─────────────────────────────────────────────────────────────────────┐
│                    AWIA Requirements                                 │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Applicability: Community water systems serving > 3,300 people      │
│                                                                      │
│   Risk and Resilience Assessment (RRA):                              │
│   ─────────────────────────────────────                              │
│   Must assess risks to:                                              │
│   • Physical security                                                │
│   • Cybersecurity                                                    │
│   • Monitoring practices                                             │
│   • Chemical handling                                                │
│   • Operation and maintenance                                        │
│   • Financial infrastructure                                         │
│   • Use/storage/handling of chemicals                                │
│   • Operation and maintenance                                        │
│   • Monitoring practices                                             │
│                                                                      │
│   Emergency Response Plan (ERP):                                     │
│   ─────────────────────────────                                      │
│   Must address:                                                      │
│   • Strategies/resources to improve resilience                       │
│   • Plans/procedures for responding to attacks                       │
│   • Actions/equipment for public health protection                   │
│   • Identification of alternate water sources                        │
│                                                                      │
│   Deadlines (Based on Population Served):                            │
│   ──────────────────────────────────────                             │
│   • >100,000: Completed (2020)                                       │
│   • 50,000-99,999: Completed (2021)                                  │
│   • 3,301-49,999: Completed (2022)                                   │
│                                                                      │
│   Recertification: Every 5 years                                     │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Pharmaceutical (FDA)

### 21 CFR Part 11

| Aspect | Requirement |
|--------|-------------|
| **Scope** | Electronic records and signatures |
| **Validation** | Systems must be validated |
| **Audit trails** | Record who, what, when |
| **Access controls** | Limit system access |
| **Authority checks** | Verify user authorization |
| **Operational checks** | Enforce operational sequences |
| **Device checks** | Validate input device/source |

### Computer System Validation (CSV)

Pharmaceutical OT must be validated per GAMP5 principles.

## Nuclear (US NRC)

### 10 CFR 73.54

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Nuclear Cyber Security Requirements               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Critical Digital Assets (CDAs):                                    │
│   ───────────────────────────────                                    │
│   Digital computer and communication systems that:                   │
│   • Perform safety, security, or emergency preparedness              │
│   • Could adversely impact safety/security if compromised            │
│                                                                      │
│   Requirements:                                                      │
│   ─────────────                                                      │
│   • Cyber Security Plan approved by NRC                              │
│   • Protect CDAs from cyber attacks                                  │
│   • Defensive architecture (defense in depth)                        │
│   • Assessment and mitigation                                        │
│   • Incident response and recovery                                   │
│                                                                      │
│   Key Controls:                                                      │
│   ─────────────                                                      │
│   • Deterministic isolation (no wireless, internet)                  │
│   • Media controls (strict USB/removable media)                      │
│   • Configuration management                                         │
│   • Continuous monitoring                                            │
│                                                                      │
│   Penalty: License revocation, criminal penalties                    │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Maritime (MTSA)

### Maritime Transportation Security Act

| Requirement | Description |
|-------------|-------------|
| **Facility Security Plan** | Address cybersecurity threats |
| **Vessel Security Plan** | Protect shipboard control systems |
| **USCG Guidance** | NVIC 01-20 on cyber risk management |

## Regulation Comparison

| Regulation | Scope | Mandatory? | Penalties | OT Focus |
|------------|-------|------------|-----------|----------|
| **NERC CIP** | Electric grid | Yes | $1M/day | High |
| **TSA Pipeline** | Pipelines | Yes | Civil/criminal | High |
| **NIS2** | EU essential services | Yes | 2% turnover | Medium |
| **CFATS** | Chemical | Yes | $25K/day | Medium |
| **AWIA** | Water | Yes | EPA enforcement | Medium |
| **FDA 21 CFR 11** | Pharma | Yes | Warning letters | Medium |
| **NRC 73.54** | Nuclear | Yes | License revocation | Very High |

## Preparing for Compliance

### General Approach

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Compliance Preparation Steps                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   1. Determine Applicability                                         │
│      ─────────────────────────                                       │
│      • Which regulations apply to your organization?                 │
│      • What assets are in scope?                                     │
│      • What classification (High/Medium/Low)?                        │
│                                                                      │
│   2. Gap Assessment                                                  │
│      ──────────────────                                              │
│      • Map current state to requirements                             │
│      • Identify gaps                                                 │
│      • Prioritize by risk and deadline                               │
│                                                                      │
│   3. Remediation Plan                                                │
│      ────────────────────                                            │
│      • Address gaps systematically                                   │
│      • Allocate resources                                            │
│      • Track progress                                                │
│                                                                      │
│   4. Documentation                                                   │
│      ─────────────                                                   │
│      • Policies and procedures                                       │
│      • Evidence of compliance                                        │
│      • Audit trails                                                  │
│                                                                      │
│   5. Ongoing Compliance                                              │
│      ────────────────────                                            │
│      • Regular assessments                                           │
│      • Continuous monitoring                                         │
│      • Update for regulatory changes                                 │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Key Takeaways

1. **Know your sector** - regulations vary significantly by industry
2. **Multiple regulations may apply** - especially for multi-sector operations
3. **OT-specific requirements** - most regulations now address OT explicitly
4. **Penalties are real** - enforcement is increasing
5. **Reporting requirements** - know your notification timelines
6. **Documentation is essential** - auditors need evidence
7. **Stay current** - regulations evolve rapidly

## Study Questions

1. Which NERC CIP standard addresses network segmentation?

2. How do TSA Pipeline Security Directives differ from NERC CIP?

3. What incident reporting timeline does NIS2 require?

4. Why does nuclear have stricter cybersecurity requirements than other sectors?

5. How would you handle compliance if your organization operates in multiple sectors?

## Next Steps

Continue to [12-vendor-risk-management.md](12-vendor-risk-management.md) to learn about managing third-party OT risks.

## References

- NERC CIP Standards: https://www.nerc.com/pa/Stand/Pages/CIPStandards.aspx
- TSA Pipeline Security: https://www.tsa.gov/sd-pipeline-2021-02c
- NIS2 Directive: https://eur-lex.europa.eu/
- CISA CFATS: https://www.cisa.gov/cfats
- EPA AWIA: https://www.epa.gov/waterresilience/awia
- FDA 21 CFR Part 11: https://www.fda.gov/
- NRC 10 CFR 73.54: https://www.nrc.gov/
