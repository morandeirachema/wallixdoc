# IEC 62443 Deep Dive

The primary international standard for industrial cybersecurity.

## Standard Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                    IEC 62443 Structure                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   IEC 62443: Industrial Automation and Control System Security       │
│   (Also known as ISA/IEC 62443 or ISA-99)                            │
│                                                                      │
│   Document Series:                                                   │
│   ─────────────────                                                  │
│                                                                      │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │  1-X: GENERAL (Concepts, Terminology, Metrics)               │   │
│   │  ├── 62443-1-1: Terminology and concepts                     │   │
│   │  ├── 62443-1-2: Master glossary                              │   │
│   │  ├── 62443-1-3: System security conformance metrics          │   │
│   │  └── 62443-1-4: IACS security lifecycle                      │   │
│   └─────────────────────────────────────────────────────────────┘   │
│                                                                      │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │  2-X: POLICIES & PROCEDURES (Asset Owner)                    │   │
│   │  ├── 62443-2-1: Security program for IACS                    │   │
│   │  ├── 62443-2-2: IACS protection ratings                      │   │
│   │  ├── 62443-2-3: Patch management                             │   │
│   │  ├── 62443-2-4: Requirements for service providers           │   │
│   │  └── 62443-2-5: Implementation guidance for asset owners     │   │
│   └─────────────────────────────────────────────────────────────┘   │
│                                                                      │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │  3-X: SYSTEM (System Integrators)                            │   │
│   │  ├── 62443-3-1: Security technologies                        │   │
│   │  ├── 62443-3-2: Security risk assessment                     │   │
│   │  └── 62443-3-3: System security requirements                 │   │
│   └─────────────────────────────────────────────────────────────┘   │
│                                                                      │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │  4-X: COMPONENT (Product Vendors)                            │   │
│   │  ├── 62443-4-1: Product development requirements             │   │
│   │  └── 62443-4-2: Component security requirements              │   │
│   └─────────────────────────────────────────────────────────────┘   │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Stakeholder Responsibilities

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Who Does What?                                    │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   ASSET OWNER (You, the end user)                                    │
│   ───────────────────────────────                                    │
│   Responsibilities:                                                  │
│   • Define security requirements based on risk                       │
│   • Specify target security levels                                   │
│   • Manage security throughout lifecycle                             │
│   • Comply with 62443-2-X series                                     │
│                                                                      │
│   SYSTEM INTEGRATOR                                                  │
│   ─────────────────                                                  │
│   Responsibilities:                                                  │
│   • Design systems to meet asset owner requirements                  │
│   • Implement zones and conduits                                     │
│   • Document system architecture                                     │
│   • Comply with 62443-3-X series                                     │
│                                                                      │
│   PRODUCT VENDOR                                                     │
│   ──────────────                                                     │
│   Responsibilities:                                                  │
│   • Develop secure products                                          │
│   • Provide security documentation                                   │
│   • Support product security lifecycle                               │
│   • Comply with 62443-4-X series                                     │
│                                                                      │
│   MAINTENANCE/SERVICE PROVIDER                                       │
│   ────────────────────────────                                       │
│   Responsibilities:                                                  │
│   • Maintain security during service                                 │
│   • Follow asset owner policies                                      │
│   • Comply with 62443-2-4                                            │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Security Levels (SL)

### Understanding Security Levels

| Level | Threat Source | Description |
|-------|---------------|-------------|
| **SL 0** | None | No specific requirements |
| **SL 1** | Casual/Coincidental | Protection against unintentional, accidental violations |
| **SL 2** | Intentional/Simple Means | Protection against intentional violation using simple means, low resources |
| **SL 3** | Intentional/Sophisticated | Protection against sophisticated attacks with moderate resources |
| **SL 4** | Intentional/Extended | Protection against state-sponsored attacks with extensive resources |

### Security Level Types

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Security Level Types                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   SL-T (Target)                                                      │
│   ─────────────                                                      │
│   • What level of security is NEEDED                                 │
│   • Determined by risk assessment                                    │
│   • Based on threat analysis and consequence                         │
│                                                                      │
│   SL-C (Capability)                                                  │
│   ─────────────────                                                  │
│   • What level the system/component CAN provide                      │
│   • Determined by vendor/integrator                                  │
│   • Documented in security documentation                             │
│                                                                      │
│   SL-A (Achieved)                                                    │
│   ───────────────                                                    │
│   • What level is ACTUALLY achieved                                  │
│   • Determined by assessment after implementation                    │
│   • Must meet or exceed SL-T                                         │
│                                                                      │
│   Goal: SL-A ≥ SL-T (Achieved meets or exceeds Target)               │
│                                                                      │
│   Example:                                                           │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │ Zone: Reactor Control                                       │   │
│   │ SL-T: 3 (Sophisticated threats, high consequence)           │   │
│   │ SL-C: 3 (System designed for SL3)                           │   │
│   │ SL-A: 3 (Assessment confirms SL3 achieved)                  │   │
│   │ Status: COMPLIANT                                           │   │
│   └─────────────────────────────────────────────────────────────┘   │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Zones and Conduits

### Zone Definition

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Zone Concept                                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   ZONE: A logical or physical grouping of assets that:               │
│   • Share common security requirements                               │
│   • Have a defined security level                                    │
│   • Are protected by common security controls                        │
│                                                                      │
│   Zone Characteristics:                                              │
│   ─────────────────────                                              │
│   • Has a defined boundary                                           │
│   • Contains assets with similar security needs                      │
│   • Has an assigned Security Level                                   │
│   • Minimizes cross-zone communication                               │
│                                                                      │
│   Example Zones:                                                     │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │                                                             │   │
│   │    ┌───────────────────┐    ┌───────────────────┐          │   │
│   │    │   Enterprise      │    │   Manufacturing   │          │   │
│   │    │   Zone (SL1)      │    │   Zone (SL2)      │          │   │
│   │    │                   │    │                   │          │   │
│   │    │   • ERP           │    │   • MES           │          │   │
│   │    │   • Email         │    │   • Historian     │          │   │
│   │    │   • Web           │    │   • Engineering   │          │   │
│   │    └─────────┬─────────┘    └─────────┬─────────┘          │   │
│   │              │                        │                     │   │
│   │              └────────────┬───────────┘                     │   │
│   │                           │                                 │   │
│   │                    ┌──────┴──────┐                          │   │
│   │                    │   Conduit   │                          │   │
│   │                    │  (Firewall) │                          │   │
│   │                    └──────┬──────┘                          │   │
│   │                           │                                 │   │
│   │              ┌────────────┴───────────┐                     │   │
│   │              │                        │                     │   │
│   │    ┌─────────┴─────────┐    ┌─────────┴─────────┐          │   │
│   │    │   Control         │    │   Safety          │          │   │
│   │    │   Zone (SL3)      │    │   Zone (SL4)      │          │   │
│   │    │                   │    │                   │          │   │
│   │    │   • DCS           │    │   • SIS           │          │   │
│   │    │   • PLC           │    │   • ESD           │          │   │
│   │    │   • HMI           │    │   • F&G           │          │   │
│   │    └───────────────────┘    └───────────────────┘          │   │
│   │                                                             │   │
│   └─────────────────────────────────────────────────────────────┘   │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Conduit Definition

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Conduit Concept                                   │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   CONDUIT: A logical grouping of communication channels that:        │
│   • Connects two or more zones                                       │
│   • Provides security functions                                      │
│   • Controls data flow between zones                                 │
│                                                                      │
│   Conduit Components:                                                │
│   ───────────────────                                                │
│   • Firewalls                                                        │
│   • Data diodes                                                      │
│   • VPN gateways                                                     │
│   • Protocol converters                                              │
│   • Authentication systems                                           │
│                                                                      │
│   Conduit Requirements:                                              │
│   ─────────────────────                                              │
│   • Must protect the higher-SL zone                                  │
│   • Access control (who can communicate)                             │
│   • Data flow control (what data can pass)                           │
│   • Logging and monitoring                                           │
│                                                                      │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │                                                             │   │
│   │   Zone A (SL2)          Conduit          Zone B (SL3)       │   │
│   │   ┌──────────┐    ┌───────────────┐    ┌──────────┐        │   │
│   │   │          │    │               │    │          │        │   │
│   │   │  Assets  │◄──►│  • Firewall   │◄──►│  Assets  │        │   │
│   │   │          │    │  • Logging    │    │          │        │   │
│   │   │          │    │  • Auth       │    │          │        │   │
│   │   └──────────┘    └───────────────┘    └──────────┘        │   │
│   │                                                             │   │
│   │   Conduit must provide SL3 protection for Zone B            │   │
│   │                                                             │   │
│   └─────────────────────────────────────────────────────────────┘   │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Foundational Requirements (FR)

The 7 Foundational Requirements form the core of IEC 62443:

### FR Overview

| FR | Name | Focus |
|----|------|-------|
| FR 1 | Identification and Authentication Control | Who is accessing? |
| FR 2 | Use Control | What can they do? |
| FR 3 | System Integrity | Is it tampered? |
| FR 4 | Data Confidentiality | Is data protected? |
| FR 5 | Restricted Data Flow | How does data move? |
| FR 6 | Timely Response to Events | Do we detect issues? |
| FR 7 | Resource Availability | Is it available? |

### FR 1: Identification and Authentication Control

```
┌─────────────────────────────────────────────────────────────────────┐
│                    FR 1: IAC Requirements by SL                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   SR 1.1: Human User Identification and Authentication               │
│   ─────────────────────────────────────────────────────              │
│   SL1: Identify and authenticate all users                           │
│   SL2: Unique identification per user                                │
│   SL3: Multi-factor authentication                                   │
│   SL4: Hardware-based authentication                                 │
│                                                                      │
│   SR 1.2: Software Process Identification and Authentication         │
│   ────────────────────────────────────────────────────────           │
│   SL1: Identify all software processes                               │
│   SL2: Authenticate software processes                               │
│   SL3: Mutual authentication between components                      │
│   SL4: Hardware-based process authentication                         │
│                                                                      │
│   SR 1.3: Account Management                                         │
│   ────────────────────────────                                       │
│   SL1: Support account management                                    │
│   SL2: Enforce role-based accounts                                   │
│   SL3: Automated provisioning/deprovisioning                         │
│   SL4: Continuous account validation                                 │
│                                                                      │
│   SR 1.4: Identifier Management                                      │
│   ─────────────────────────────                                      │
│   SL1: Unique identifiers                                            │
│   SL2: Prevent identifier reuse                                      │
│   SL3: Automated identifier lifecycle                                │
│   SL4: Hardware-protected identifiers                                │
│                                                                      │
│   Additional: SR 1.5-1.13 cover:                                     │
│   • Authenticator management                                         │
│   • Wireless access management                                       │
│   • Strength of authentication                                       │
│   • PKI certificates                                                 │
│   • Public key authentication                                        │
│   • Authenticator feedback                                           │
│   • Unsuccessful login attempts                                      │
│   • System use notification                                          │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### FR 2: Use Control

```
┌─────────────────────────────────────────────────────────────────────┐
│                    FR 2: UC Requirements by SL                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   SR 2.1: Authorization Enforcement                                  │
│   ─────────────────────────────────                                  │
│   SL1: Enforce assigned authorizations                               │
│   SL2: Enforce least privilege                                       │
│   SL3: Enforce separation of duties                                  │
│   SL4: Dual authorization for critical functions                     │
│                                                                      │
│   SR 2.2: Wireless Use Control                                       │
│   ─────────────────────────────                                      │
│   SL1: Control wireless access                                       │
│   SL2: Restrict wireless to authorized devices                       │
│   SL3: Implement wireless IDS                                        │
│   SL4: Physical containment of wireless signals                      │
│                                                                      │
│   SR 2.3: Use Control for Portable Devices                           │
│   ─────────────────────────────────────────                          │
│   SL1: Control portable device connectivity                          │
│   SL2: Scan devices before connection                                │
│   SL3: Only organization-controlled devices                          │
│   SL4: Hardware-authenticated devices only                           │
│                                                                      │
│   SR 2.4: Mobile Code                                                │
│   ─────────────────────                                              │
│   SL1: Control mobile code execution                                 │
│   SL2: Code signing verification                                     │
│   SL3: Sandbox mobile code                                           │
│   SL4: Prohibit mobile code execution                                │
│                                                                      │
│   Additional: SR 2.5-2.12 cover:                                     │
│   • Session lock, remote session termination                         │
│   • Concurrent session control                                       │
│   • Auditable events, audit storage                                  │
│   • Timestamps, audit log protection                                 │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### FR 3: System Integrity

| SR | Requirement | SL1 | SL2 | SL3 | SL4 |
|----|-------------|-----|-----|-----|-----|
| 3.1 | Communication integrity | CRC | Crypto hash | Digital sig | HW crypto |
| 3.2 | Malicious code protection | Detect | Block | Sandbox | HW isolation |
| 3.3 | Security functionality verification | Basic | Enhanced | Continuous | HW-based |
| 3.4 | Software/information integrity | Verify | Sign | HW verify | HW attest |
| 3.5 | Input validation | Basic | Enhanced | Strict | HW-enforced |
| 3.6 | Deterministic output | Defined | Verified | Attested | HW-attested |
| 3.7 | Error handling | Basic | Enhanced | Fail-secure | HW fail-secure |
| 3.8 | Session integrity | Basic | Crypto | Mutual auth | HW session |
| 3.9 | Protection of audit info | Protect | Sign | Tamper-proof | HW protect |

### FR 4-7: Brief Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                    FR 4-7 Summary                                    │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   FR 4: Data Confidentiality                                         │
│   ─────────────────────────────                                      │
│   • Information confidentiality                                      │
│   • Cryptographic protection                                         │
│   • Use of cryptography (algorithms, key management)                 │
│   • Public key infrastructure                                        │
│                                                                      │
│   FR 5: Restricted Data Flow                                         │
│   ─────────────────────────────                                      │
│   • Network segmentation                                             │
│   • Zone boundary protection                                         │
│   • General purpose person-to-person communication restriction       │
│   • Application partitioning                                         │
│                                                                      │
│   FR 6: Timely Response to Events                                    │
│   ─────────────────────────────────                                  │
│   • Audit log accessibility                                          │
│   • Continuous monitoring                                            │
│   • Event reporting, denial of service protection                    │
│                                                                      │
│   FR 7: Resource Availability                                        │
│   ─────────────────────────────                                      │
│   • Denial of service protection                                     │
│   • Resource management                                              │
│   • Control system backup                                            │
│   • Control system recovery                                          │
│   • Emergency power, network/security configuration                  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Risk Assessment (62443-3-2)

### Risk Assessment Process

```
┌─────────────────────────────────────────────────────────────────────┐
│                    62443-3-2 Risk Assessment Process                 │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Step 1: System Characterization                                    │
│   ───────────────────────────────                                    │
│   • Identify assets and their functions                              │
│   • Document network architecture                                    │
│   • Identify interfaces and dependencies                             │
│   • Map data flows                                                   │
│                                                                      │
│   Step 2: Threat Identification                                      │
│   ─────────────────────────────                                      │
│   • Identify threat sources                                          │
│   • Determine threat capabilities                                    │
│   • Map threats to assets                                            │
│                                                                      │
│   Step 3: Vulnerability Identification                               │
│   ─────────────────────────────────────                              │
│   • Identify existing vulnerabilities                                │
│   • Assess compensating controls                                     │
│   • Determine exploitability                                         │
│                                                                      │
│   Step 4: Consequence Assessment                                     │
│   ────────────────────────────────                                   │
│   • Determine potential impact                                       │
│   • Consider safety, operational, financial                          │
│   • Rate severity                                                    │
│                                                                      │
│   Step 5: Risk Calculation                                           │
│   ─────────────────────────────                                      │
│   Risk = Likelihood × Consequence                                    │
│   Assign risk level to each threat/asset combination                 │
│                                                                      │
│   Step 6: Security Level Assignment                                  │
│   ───────────────────────────────────                                │
│   • Determine SL-T based on risk                                     │
│   • Assign SL-T to each zone                                         │
│   • Document rationale                                               │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Product Security (62443-4-2)

### Component Security Requirements

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Component Requirements by Type                    │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Component Types Defined:                                           │
│   ─────────────────────────                                          │
│   • Software application                                             │
│   • Embedded device                                                  │
│   • Host device                                                      │
│   • Network device                                                   │
│                                                                      │
│   Requirements Apply to Each Type:                                   │
│   ─────────────────────────────────                                  │
│                                                                      │
│   CR 1: Identification and Authentication                            │
│   • Human user authentication                                        │
│   • Software process authentication                                  │
│   • Account management                                               │
│   • Authenticator management                                         │
│   • Password-based authentication                                    │
│   • Public key authentication                                        │
│                                                                      │
│   CR 2: Use Control                                                  │
│   • Authorization enforcement                                        │
│   • Use control for portable devices                                 │
│   • Mobile code protection                                           │
│   • Audit events                                                     │
│                                                                      │
│   CR 3: System Integrity                                             │
│   • Communication integrity                                          │
│   • Malware protection                                               │
│   • Security functionality verification                              │
│   • Input validation                                                 │
│                                                                      │
│   CR 4-7: Similar structure...                                       │
│                                                                      │
│   Certification Levels:                                              │
│   ─────────────────────                                              │
│   Products can be certified at SL1, SL2, SL3, or SL4                 │
│   by accredited testing labs (ISASecure, TÜV)                        │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Practical Implementation

### Implementation Steps

1. **Inventory and Characterize** - Know what you have
2. **Define Zones** - Group assets by function and security needs
3. **Assess Risk** - Determine SL-T for each zone
4. **Gap Analysis** - Compare SL-T vs current state
5. **Implement Controls** - Close gaps systematically
6. **Verify and Validate** - Confirm SL-A ≥ SL-T
7. **Maintain** - Ongoing monitoring and improvement

### Common Zones in Industrial Facilities

| Zone | Typical SL | Contents |
|------|------------|----------|
| **Enterprise** | SL1 | ERP, email, business apps |
| **DMZ** | SL2 | Historian mirror, jump server |
| **Manufacturing** | SL2-3 | MES, engineering WS, historian |
| **Control** | SL3 | DCS, PLC, SCADA, HMI |
| **Safety** | SL3-4 | SIS, ESD, fire & gas |
| **Remote Sites** | SL2 | RTU, field devices |

## Certification and Compliance

### Certification Programs

| Program | Focus | Certifies |
|---------|-------|-----------|
| **ISASecure EDSA** | Embedded Device | Products (SL1-4) |
| **ISASecure SSA** | System Security | Systems |
| **ISASecure SDLA** | Development Lifecycle | Vendor processes |
| **TÜV Rheinland** | Various | Products and systems |

### Evidence for Compliance

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Compliance Documentation                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Required Documentation:                                            │
│   ───────────────────────                                            │
│                                                                      │
│   1. Asset Inventory                                                 │
│      • List of all IACS components                                   │
│      • Criticality classification                                    │
│      • Owner and location                                            │
│                                                                      │
│   2. Zone and Conduit Model                                          │
│      • Zone definitions and boundaries                               │
│      • Conduit specifications                                        │
│      • Data flow diagrams                                            │
│                                                                      │
│   3. Risk Assessment                                                 │
│      • Threat analysis                                               │
│      • Vulnerability assessment                                      │
│      • Risk ratings                                                  │
│      • SL-T assignments with rationale                               │
│                                                                      │
│   4. Security Measures                                               │
│      • Controls implemented per SR                                   │
│      • Compensating controls documented                              │
│      • Residual risk accepted                                        │
│                                                                      │
│   5. Policies and Procedures                                         │
│      • Security policies                                             │
│      • Operational procedures                                        │
│      • Incident response plan                                        │
│      • Change management                                             │
│                                                                      │
│   6. Verification Evidence                                           │
│      • Test results                                                  │
│      • Audit reports                                                 │
│      • SL-A determination                                            │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Key Takeaways

1. **Understand the structure** - 4 series for different stakeholders
2. **Security Levels matter** - SL1-4 define protection depth
3. **Zones and conduits** - the architectural foundation
4. **7 Foundational Requirements** - cover all security aspects
5. **Risk-based approach** - SL-T determined by risk assessment
6. **Lifecycle perspective** - security throughout system life
7. **Documentation is key** - compliance requires evidence

## Study Questions

1. What is the difference between SL-T, SL-C, and SL-A?

2. Why would a safety zone require SL4 while a manufacturing zone might only need SL2?

3. What are the responsibilities of an asset owner vs. a system integrator?

4. How does FR1 (IAC) change from SL1 to SL4?

5. What is the purpose of a conduit, and what security functions must it provide?

## Practical Exercise

Design a zone and conduit model for:
- Small manufacturing plant
- One production line with 2 PLCs and 2 HMIs
- Historian for data collection
- Engineering workstation
- Corporate connectivity for reporting

Assign appropriate SL-T to each zone and justify.

## Next Steps

Continue to [11-regulatory-landscape.md](11-regulatory-landscape.md) to understand sector-specific regulations beyond IEC 62443.

## References

- ISA/IEC 62443 Series: https://www.isa.org/isa99
- ISASecure Certification: https://isasecure.org/
- IEC 62443 Overview: https://www.iec.ch/
- CISA 62443 Resources: https://www.cisa.gov/ics
