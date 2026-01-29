# OT Threat Modeling

Systematic approaches to identifying and analyzing threats in industrial environments.

## Why OT Threat Modeling is Different

```
┌─────────────────────────────────────────────────────────────────────┐
│                    IT vs OT Threat Modeling                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   IT Threat Modeling Focus:                                          │
│   ─────────────────────────                                          │
│   • Data confidentiality                                             │
│   • User authentication                                              │
│   • Application vulnerabilities                                      │
│   • Network access                                                   │
│                                                                      │
│   OT Threat Modeling Must Add:                                       │
│   ────────────────────────────                                       │
│   • Physical process understanding                                   │
│   • Safety system interactions                                       │
│   • Real-time requirements                                           │
│   • Physics-based consequences                                       │
│   • Human-machine interactions                                       │
│   • Multi-vendor ecosystems                                          │
│                                                                      │
│   Key Difference:                                                    │
│   ───────────────                                                    │
│   IT: "What data could be stolen?"                                   │
│   OT: "What could explode, spill, or kill?"                          │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Consequence-Driven Approach

Start with worst-case outcomes and work backwards:

### Step 1: Identify High-Consequence Events

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Consequence Identification                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   For Each System, Identify:                                         │
│                                                                      │
│   1. SAFETY Consequences                                             │
│      • Personnel injury/fatality                                     │
│      • Public harm                                                   │
│      • Environmental release                                         │
│                                                                      │
│   2. OPERATIONAL Consequences                                        │
│      • Production loss                                               │
│      • Equipment damage                                              │
│      • Quality impact                                                │
│                                                                      │
│   3. FINANCIAL Consequences                                          │
│      • Direct costs                                                  │
│      • Regulatory fines                                              │
│      • Reputation damage                                             │
│                                                                      │
│   Example: Chemical Reactor                                          │
│   ┌───────────────────────────────────────────────────────────────┐ │
│   │ High-Consequence Event: Runaway reaction                      │ │
│   │                                                               │ │
│   │ Safety: Explosion risk, toxic release, fatalities             │ │
│   │ Operational: Reactor destroyed, months to rebuild             │ │
│   │ Financial: $50M+ in damages, regulatory shutdown              │ │
│   └───────────────────────────────────────────────────────────────┘ │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Step 2: Map Attack Paths to Consequences

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Attack Path Analysis                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Target: Runaway Reaction in Chemical Reactor                       │
│                                                                      │
│   How Could an Attacker Cause This?                                  │
│                                                                      │
│   Path 1: Temperature Control Manipulation                           │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │ Access HMI → Change temperature setpoint → Reaction runs hot│   │
│   │           → Safety system should trip                       │   │
│   │           → If SIS compromised: Catastrophic failure        │   │
│   └─────────────────────────────────────────────────────────────┘   │
│                                                                      │
│   Path 2: Cooling System Disable                                     │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │ Access PLC → Stop cooling pumps → Temperature rises         │   │
│   │           → Alarms disabled or ignored                      │   │
│   │           → Runaway condition                               │   │
│   └─────────────────────────────────────────────────────────────┘   │
│                                                                      │
│   Path 3: Reactant Flow Manipulation                                 │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │ Access DCS → Increase feed rate → Excess reactants          │   │
│   │           → Exothermic reaction accelerates                 │   │
│   │           → Pressure buildup                                │   │
│   └─────────────────────────────────────────────────────────────┘   │
│                                                                      │
│   Path 4: Sensor Spoofing                                            │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │ Inject false sensor data → Operator sees "normal"           │   │
│   │                         → Actual conditions dangerous       │   │
│   │                         → No intervention                   │   │
│   └─────────────────────────────────────────────────────────────┘   │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## STRIDE for OT

Apply STRIDE model with OT-specific considerations:

| Threat | IT Context | OT Context |
|--------|------------|------------|
| **Spoofing** | Fake user identity | Fake sensor data, spoofed control commands |
| **Tampering** | Modify data in transit | Modify setpoints, PLC logic, firmware |
| **Repudiation** | Deny action taken | Deny unauthorized command, hide changes |
| **Information Disclosure** | Data breach | Process data leak, recipe theft |
| **Denial of Service** | System unavailable | Process stops, safety system offline |
| **Elevation of Privilege** | Gain admin access | Gain engineering access, bypass interlocks |

### STRIDE Applied to OT Components

```
┌─────────────────────────────────────────────────────────────────────┐
│                    STRIDE Analysis: HMI System                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Asset: Operator HMI Workstation                                    │
│                                                                      │
│   ┌───────────────┬───────────────────────────────────────────────┐ │
│   │ Threat        │ OT-Specific Scenario                          │ │
│   ├───────────────┼───────────────────────────────────────────────┤ │
│   │ Spoofing      │ Attacker mimics operator to issue commands    │ │
│   │               │ Fake display showing "normal" when dangerous  │ │
│   ├───────────────┼───────────────────────────────────────────────┤ │
│   │ Tampering     │ Modify HMI screens to hide alarms             │ │
│   │               │ Change setpoint limits displayed              │ │
│   ├───────────────┼───────────────────────────────────────────────┤ │
│   │ Repudiation   │ Operator denies issuing dangerous command     │ │
│   │               │ No audit trail of changes                     │ │
│   ├───────────────┼───────────────────────────────────────────────┤ │
│   │ Info Disc.    │ Screen capture of process data                │ │
│   │               │ Credential theft from HMI                     │ │
│   ├───────────────┼───────────────────────────────────────────────┤ │
│   │ DoS           │ HMI crashes, operator blind                   │ │
│   │               │ Screen freeze during critical operation       │ │
│   ├───────────────┼───────────────────────────────────────────────┤ │
│   │ Elevation     │ Operator gains engineer access                │ │
│   │               │ Bypass safety interlocks                      │ │
│   └───────────────┴───────────────────────────────────────────────┘ │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Attack Trees

Visual representation of attack paths:

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Attack Tree: Cause Overpressure                   │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│                    [Cause Vessel Overpressure]                       │
│                              │                                       │
│           ┌──────────────────┼──────────────────┐                    │
│           │                  │                  │                    │
│           ▼                  ▼                  ▼                    │
│   [Increase Inflow]   [Block Outflow]   [Disable Safety]             │
│           │                  │                  │                    │
│     ┌─────┴─────┐      ┌─────┴─────┐     ┌─────┴─────┐               │
│     │           │      │           │     │           │               │
│     ▼           ▼      ▼           ▼     ▼           ▼               │
│ [Change    [Open   [Close     [Modify [Disable   [Spoof              │
│  setpoint]  valve]  valve]    PLC    relief    pressure              │
│     │         │       │      logic]   valve]   sensor]               │
│     │         │       │        │        │         │                  │
│     ▼         ▼       ▼        ▼        ▼         ▼                  │
│ [Access   [Access [Access  [Access  [Physical [Inject                │
│  HMI]     DCS]    PLC]     Eng WS]  access]   false                  │
│                                               data]                  │
│                                                                      │
│   AND/OR Logic:                                                      │
│   • Overpressure requires (Increase OR Block) AND (Disable Safety)   │
│   • Attacker needs multiple successes for catastrophic outcome       │
│                                                                      │
│   Defense Priority:                                                  │
│   • Protect safety systems (highest priority)                        │
│   • Protect multiple paths (defense in depth)                        │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Crown Jewels Analysis

Identify the most critical assets:

### Asset Criticality Matrix

| Asset | Compromise Impact | Accessibility | Priority |
|-------|-------------------|---------------|----------|
| **Safety PLC** | Catastrophic | Low (isolated) | Critical |
| **DCS Controller** | Major | Medium | High |
| **Engineering WS** | Major | High (network) | High |
| **HMI** | Moderate | High | Medium |
| **Historian** | Low-Moderate | High | Medium |
| **OPC Server** | Moderate | High | Medium |

### Crown Jewels Identification Process

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Crown Jewels Analysis Process                     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Step 1: List all OT assets                                         │
│   ──────────────────────────                                         │
│   • Control systems (DCS, PLC, RTU)                                  │
│   • Safety systems (SIS, ESD)                                        │
│   • Network infrastructure                                           │
│   • Support systems (historian, engineering)                         │
│                                                                      │
│   Step 2: Score each asset                                           │
│   ────────────────────────                                           │
│   Impact if compromised:                                             │
│   • Safety impact (1-5)                                              │
│   • Operational impact (1-5)                                         │
│   • Financial impact (1-5)                                           │
│                                                                      │
│   Step 3: Identify dependencies                                      │
│   ─────────────────────────────                                      │
│   • What does this asset control?                                    │
│   • What depends on this asset?                                      │
│   • Single point of failure?                                         │
│                                                                      │
│   Step 4: Prioritize protection                                      │
│   ────────────────────────────                                       │
│   Focus security resources on highest-impact assets                  │
│                                                                      │
│   Example Output:                                                    │
│   ┌──────────────┬────────┬────────┬──────────┬───────────────────┐ │
│   │ Asset        │ Safety │ Ops    │ Finance  │ Total (weighted)  │ │
│   ├──────────────┼────────┼────────┼──────────┼───────────────────┤ │
│   │ SIS/ESD      │   5    │   3    │    4     │ 45 (5×5+3+4)     │ │
│   │ DCS Primary  │   4    │   5    │    5     │ 30 (4×5+5+5)     │ │
│   │ Eng WS       │   3    │   4    │    3     │ 22 (3×5+4+3)     │ │
│   │ HMI          │   2    │   4    │    2     │ 16 (2×5+4+2)     │ │
│   │ Historian    │   1    │   2    │    3     │ 10 (1×5+2+3)     │ │
│   └──────────────┴────────┴────────┴──────────┴───────────────────┘ │
│                                                                      │
│   Safety-weighted because safety impacts are irreversible            │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Process-Based Threat Modeling

Understanding the process to understand the threats:

### Process Flow Analysis

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Process Flow Threat Analysis                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Example: Water Treatment Process                                   │
│                                                                      │
│   Raw Water → Coagulation → Filtration → Chlorination → Distribution│
│       │           │            │             │              │        │
│       ▼           ▼            ▼             ▼              ▼        │
│   ┌───────┐   ┌───────┐   ┌───────┐    ┌───────┐      ┌───────┐    │
│   │Intake │   │Chemical│   │Filter │    │Chlorine│      │ Pump  │    │
│   │ Valve │   │ Dosing │   │Control│    │ Dosing │      │Control│    │
│   └───────┘   └───────┘   └───────┘    └───────┘      └───────┘    │
│                                                                      │
│   Threat Analysis by Stage:                                          │
│   ─────────────────────────                                          │
│                                                                      │
│   Intake:                                                            │
│   • Threat: Valve manipulation                                       │
│   • Consequence: No water, or contaminated source                    │
│                                                                      │
│   Coagulation:                                                       │
│   • Threat: Wrong chemical dosing                                    │
│   • Consequence: Treatment failure, turbid water                     │
│                                                                      │
│   Chlorination:                                                      │
│   • Threat: Over-dosing or under-dosing                              │
│   • Consequence: Chemical hazard (over) or public health (under)     │
│   • This is the CRITICAL stage                                       │
│                                                                      │
│   Distribution:                                                      │
│   • Threat: Pump manipulation                                        │
│   • Consequence: No water pressure, service disruption               │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Scenarios and Tabletop Exercises

### Scenario Development

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Threat Scenario Template                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Scenario: Ransomware Impact on Chemical Plant                      │
│                                                                      │
│   BACKGROUND:                                                        │
│   Your chemical plant operates 24/7 producing industrial solvents.   │
│   IT and OT networks are connected through a DMZ.                    │
│                                                                      │
│   INJECT 1 (Day 1, 14:00):                                           │
│   Security team detects ransomware encryption on IT file servers.    │
│   Email is down. Active Directory is compromised.                    │
│   Q: What is your immediate response for OT?                         │
│                                                                      │
│   INJECT 2 (Day 1, 16:00):                                           │
│   Operator reports HMI in production area is showing ransom note.    │
│   Cannot confirm if PLC/DCS are affected.                            │
│   Q: Do you shut down production? How do you assess OT impact?       │
│                                                                      │
│   INJECT 3 (Day 2, 08:00):                                           │
│   Assessment shows DCS is not encrypted but engineering WS is.       │
│   You have no backup of recent PLC programs.                         │
│   Q: How do you validate OT integrity? Can you continue operations?  │
│                                                                      │
│   INJECT 4 (Day 3):                                                  │
│   Attacker claims they have your chemical formulas and customer      │
│   data. Threatens to release if ransom not paid.                     │
│   Q: Does this change your response?                                 │
│                                                                      │
│   DISCUSSION POINTS:                                                 │
│   • When do you involve safety personnel?                            │
│   • How do you communicate with operators during incident?           │
│   • What manual procedures exist?                                    │
│   • How long can you operate without IT systems?                     │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Risk Assessment Framework

### Combining Likelihood and Impact

```
┌─────────────────────────────────────────────────────────────────────┐
│                    OT Risk Matrix                                    │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│                              LIKELIHOOD                              │
│                    Low      Medium     High      Critical            │
│                ┌─────────┬─────────┬─────────┬─────────┐            │
│   IMPACT       │         │         │         │         │            │
│                │         │         │         │         │            │
│   Critical     │  HIGH   │CRITICAL │CRITICAL │CRITICAL │            │
│   (Safety)     │         │         │         │         │            │
│                ├─────────┼─────────┼─────────┼─────────┤            │
│   High         │ MEDIUM  │  HIGH   │  HIGH   │CRITICAL │            │
│   (Major ops)  │         │         │         │         │            │
│                ├─────────┼─────────┼─────────┼─────────┤            │
│   Medium       │   LOW   │ MEDIUM  │  HIGH   │  HIGH   │            │
│   (Production) │         │         │         │         │            │
│                ├─────────┼─────────┼─────────┼─────────┤            │
│   Low          │   LOW   │   LOW   │ MEDIUM  │ MEDIUM  │            │
│   (Minor)      │         │         │         │         │            │
│                └─────────┴─────────┴─────────┴─────────┘            │
│                                                                      │
│   Note: Any safety impact automatically elevates to at least HIGH    │
│                                                                      │
│   Risk Response:                                                     │
│   CRITICAL: Immediate action required, escalate to executive         │
│   HIGH: Address within 30 days, significant resources                │
│   MEDIUM: Address within 90 days, planned remediation                │
│   LOW: Accept or address opportunistically                           │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Threat Modeling Tools

| Tool | Focus | Notes |
|------|-------|-------|
| **Microsoft Threat Modeling Tool** | General | Good starting point |
| **OWASP Threat Dragon** | Web/App | Open source |
| **IriusRisk** | Enterprise | Automation focus |
| **CAIRIS** | Security requirements | Academic |
| **Lucidchart/Draw.io** | Diagrams | Manual, flexible |
| **MITRE ATT&CK Navigator** | TTP mapping | ICS-specific available |

## Output Documentation

### Threat Model Report Structure

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Threat Model Report Template                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   1. EXECUTIVE SUMMARY                                               │
│      • Scope of assessment                                           │
│      • Key findings                                                  │
│      • Top risks                                                     │
│      • Recommended actions                                           │
│                                                                      │
│   2. SYSTEM DESCRIPTION                                              │
│      • Architecture diagrams                                         │
│      • Asset inventory                                               │
│      • Data flow diagrams                                            │
│      • Trust boundaries                                              │
│                                                                      │
│   3. THREAT IDENTIFICATION                                           │
│      • Threat actors considered                                      │
│      • Attack vectors analyzed                                       │
│      • STRIDE/other methodology results                              │
│                                                                      │
│   4. RISK ANALYSIS                                                   │
│      • Vulnerability assessment                                      │
│      • Impact analysis                                               │
│      • Likelihood assessment                                         │
│      • Risk ratings                                                  │
│                                                                      │
│   5. MITIGATIONS                                                     │
│      • Existing controls                                             │
│      • Recommended controls                                          │
│      • Residual risk                                                 │
│                                                                      │
│   6. PRIORITIZED ACTION PLAN                                         │
│      • Quick wins                                                    │
│      • Medium-term improvements                                      │
│      • Long-term strategic changes                                   │
│                                                                      │
│   APPENDICES                                                         │
│      • Attack trees                                                  │
│      • Detailed technical findings                                   │
│      • References                                                    │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Key Takeaways

1. **Start with consequences** - what could go wrong physically?
2. **Understand the process** - you cannot threat model what you don't understand
3. **Identify crown jewels** - not all assets are equal
4. **Map attack paths** - multiple paths to same outcome
5. **Consider safety** - safety impacts get highest priority
6. **Document everything** - threat models inform security decisions
7. **Review regularly** - threats and systems change

## Study Questions

1. Why should OT threat modeling start with consequences rather than vulnerabilities?

2. How does STRIDE need to be modified for OT environments?

3. What makes a safety system a "crown jewel" even if it's isolated?

4. How would you model the threat of an insider with legitimate PLC programming access?

5. Why are tabletop exercises valuable for OT threat modeling?

## Practical Exercise

Conduct a threat model for a simple OT system:
- Water pump station with 3 pumps
- PLC controlling pump speed based on tank level
- HMI for operator control
- Connected to central SCADA via VPN

Identify:
1. High-consequence events
2. Attack paths (at least 3)
3. Crown jewels
4. Top 5 threats with risk ratings

## Next Steps

Continue to [09-ot-incident-response.md](09-ot-incident-response.md) to learn how to respond when threats become reality.

## References

- NIST SP 800-82 Rev. 2 - Risk Management
- IEC 62443-3-2 - Security Risk Assessment for System Design
- MITRE ATT&CK for ICS: https://attack.mitre.org/techniques/ics/
- CISA: Cyber Security Evaluation Tool (CSET)
- Consequence-driven Cyber-informed Engineering (CCE) - INL
