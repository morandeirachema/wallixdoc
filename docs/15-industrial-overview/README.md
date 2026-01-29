# 15 - Industrial PAM Overview

## Table of Contents

1. [Introduction to Industrial PAM](#introduction-to-industrial-pam)
2. [OT vs IT Security Challenges](#ot-vs-it-security-challenges)
3. [WALLIX Industrial Solutions](#wallix-industrial-solutions)
4. [Industrial Security Landscape](#industrial-security-landscape)
5. [Regulatory Frameworks](#regulatory-frameworks)
6. [Industrial PAM Use Cases](#industrial-pam-use-cases)

---

## Introduction to Industrial PAM

### Why Industrial Environments Need PAM

```
+===============================================================================+
|                    INDUSTRIAL PAM IMPERATIVE                                  |
+===============================================================================+
|                                                                               |
|  THE CONVERGENCE CHALLENGE                                                    |
|  =========================                                                    |
|                                                                               |
|         TRADITIONAL (Isolated)              MODERN (Connected)               |
|                                                                               |
|         +-----------------+                +-----------------+               |
|         |   IT Network    |                |   IT Network    |               |
|         |                 |                |                 |               |
|         |  Corporate      |                |  Corporate      |               |
|         |  Systems        |                |  Systems        |               |
|         +-----------------+                +--------+--------+               |
|                                                     |                        |
|              AIR GAP                          +-----+-----+                  |
|         - - - - - - - - -                      |   DMZ     |                  |
|                                               | Historian |                  |
|         +-----------------+                  +-----+-----+                  |
|         |   OT Network    |                        |                        |
|         |                 |                +-------+-------+                 |
|         |  SCADA/ICS      |                |   OT Network  |                 |
|         |  (Isolated)     |                |   (Connected) |                 |
|         +-----------------+                +---------------+                 |
|                                                                               |
|  RISK FACTORS:                                                                |
|  * Remote access requirements increasing                                     |
|  * Vendor maintenance needs                                                  |
|  * IT/OT convergence exposing industrial systems                            |
|  * Legacy systems with no native security                                   |
|  * Compliance requirements (NIS2, IEC 62443)                                |
|  * Nation-state threats targeting critical infrastructure                   |
|                                                                               |
+===============================================================================+
```

### Industrial Sectors Requiring PAM

```
+===============================================================================+
|                    INDUSTRIAL SECTORS                                         |
+===============================================================================+
|                                                                               |
|  +-----------------------------------------------------------------------+ |
|  | ENERGY & UTILITIES                                                       | |
|  | ---------------------                                                    | |
|  | * Power generation (thermal, nuclear, renewable)                         | |
|  | * Transmission & distribution (substations, SCADA)                       | |
|  | * Oil & gas (upstream, midstream, downstream)                           | |
|  | * Water treatment & distribution                                         | |
|  | * Natural gas pipelines                                                  | |
|  +-----------------------------------------------------------------------+ |
|                                                                               |
|  +-----------------------------------------------------------------------+ |
|  | MANUFACTURING                                                            | |
|  | -----------------                                                        | |
|  | * Automotive assembly lines                                              | |
|  | * Pharmaceutical production                                              | |
|  | * Food & beverage processing                                             | |
|  | * Chemical manufacturing                                                 | |
|  | * Semiconductor fabrication                                              | |
|  | * Discrete & process manufacturing                                       | |
|  +-----------------------------------------------------------------------+ |
|                                                                               |
|  +-----------------------------------------------------------------------+ |
|  | TRANSPORTATION                                                           | |
|  | -----------------                                                        | |
|  | * Rail signaling systems                                                 | |
|  | * Air traffic control                                                    | |
|  | * Port & maritime operations                                             | |
|  | * Traffic management systems                                             | |
|  | * Pipeline monitoring                                                    | |
|  +-----------------------------------------------------------------------+ |
|                                                                               |
|  +-----------------------------------------------------------------------+ |
|  | CRITICAL INFRASTRUCTURE                                                  | |
|  | -------------------------                                                | |
|  | * Nuclear facilities                                                     | |
|  | * Defense industrial base                                                | |
|  | * Emergency services                                                     | |
|  | * Telecommunications                                                     | |
|  | * Healthcare (medical devices, building systems)                         | |
|  +-----------------------------------------------------------------------+ |
|                                                                               |
+===============================================================================+
```

---

## OT vs IT Security Challenges

### Fundamental Differences

```
+===============================================================================+
|                    OT vs IT SECURITY COMPARISON                               |
+===============================================================================+
|                                                                               |
|  +-------------------+------------------------+----------------------------+ |
|  | Characteristic    | IT Environment         | OT Environment             | |
|  +-------------------+------------------------+----------------------------+ |
|  | Primary Goal      | Confidentiality        | Availability & Safety      | |
|  | (CIA Triad)       | Integrity              | Integrity                  | |
|  |                   | Availability           | Confidentiality            | |
|  +-------------------+------------------------+----------------------------+ |
|  | System Lifetime   | 3-5 years              | 15-30+ years               | |
|  +-------------------+------------------------+----------------------------+ |
|  | Patching          | Regular (monthly)      | Rare (annual or never)     | |
|  +-------------------+------------------------+----------------------------+ |
|  | Downtime          | Scheduled maintenance  | Catastrophic (24/7 ops)    | |
|  | Tolerance         | acceptable             |                            | |
|  +-------------------+------------------------+----------------------------+ |
|  | Change Control    | Agile/frequent         | Extremely rigorous         | |
|  +-------------------+------------------------+----------------------------+ |
|  | Protocols         | Standard (TCP/IP)      | Proprietary (Modbus, DNP3) | |
|  +-------------------+------------------------+----------------------------+ |
|  | Security Tools    | Mature ecosystem       | Limited, specialized       | |
|  +-------------------+------------------------+----------------------------+ |
|  | Impact of Breach  | Data loss, financial   | Physical damage, injury,   | |
|  |                   |                        | environmental, death       | |
|  +-------------------+------------------------+----------------------------+ |
|  | Network Scanning  | Standard practice      | Can crash systems          | |
|  +-------------------+------------------------+----------------------------+ |
|  | Authentication    | Centralized (AD)       | Often local, shared creds  | |
|  +-------------------+------------------------+----------------------------+ |
|                                                                               |
+===============================================================================+
```

### OT-Specific Security Challenges

```
+===============================================================================+
|                    OT SECURITY CHALLENGES                                     |
+===============================================================================+
|                                                                               |
|  LEGACY SYSTEMS                                                               |
|  ==============                                                               |
|                                                                               |
|  * Windows XP/2000 still running critical processes                          |
|  * No security patches available                                             |
|  * Cannot install endpoint protection                                        |
|  * Hardcoded credentials in applications                                     |
|  * Proprietary protocols with no encryption                                  |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  VENDOR ACCESS                                                                |
|  =============                                                                |
|                                                                               |
|  * Multiple vendors requiring remote access                                  |
|  * Shared credentials among vendor technicians                               |
|  * VPN connections directly into OT network                                  |
|  * No visibility into vendor activities                                      |
|  * 24/7 support requirements                                                 |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  OPERATIONAL CONSTRAINTS                                                      |
|  =======================                                                      |
|                                                                               |
|  * Cannot disrupt production for security                                    |
|  * Maintenance windows are rare                                              |
|  * Testing in production is dangerous                                        |
|  * Staff prioritize operations over security                                 |
|  * Security tools can impact real-time performance                           |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  CREDENTIAL MANAGEMENT                                                        |
|  =====================                                                        |
|                                                                               |
|  * Default passwords never changed                                           |
|  * Shared accounts ("operator", "admin")                                     |
|  * Passwords written on sticky notes                                         |
|  * Same password across all devices                                          |
|  * No password expiration or rotation                                        |
|  * Credentials embedded in HMI configurations                                |
|                                                                               |
+===============================================================================+
```

---

## WALLIX Industrial Solutions

### WALLIX OT Portfolio

```
+===============================================================================+
|                    WALLIX INDUSTRIAL SOLUTIONS                                |
+===============================================================================+
|                                                                               |
|  +-----------------------------------------------------------------------+ |
|  |                     WALLIX BASTION FOR OT                                | |
|  |                                                                          | |
|  |  Core PAM platform adapted for industrial environments                   | |
|  |                                                                          | |
|  |  +--------------------------------------------------------------------+ | |
|  |  | * Industrial protocol support (Modbus, DNP3, OPC, etc.)            | | |
|  |  | * Lightweight deployment (minimal footprint)                        | | |
|  |  | * Air-gapped environment support                                    | | |
|  |  | * Real-time session monitoring without latency impact              | | |
|  |  | * Vendor access management                                          | | |
|  |  | * IEC 62443 compliance support                                      | | |
|  |  +--------------------------------------------------------------------+ | |
|  +-----------------------------------------------------------------------+ |
|                                                                               |
|  +-----------------------------------------------------------------------+ |
|  |                     WALLIX ACCESS MANAGER                                | |
|  |                                                                          | |
|  |  Web portal for secure remote access                                     | |
|  |                                                                          | |
|  |  +--------------------------------------------------------------------+ | |
|  |  | * HTML5 clientless access (no software on vendor laptops)          | | |
|  |  | * Browser-based HMI/SCADA access                                    | | |
|  |  | * Controlled vendor entry point                                     | | |
|  |  | * Session recording for compliance                                  | | |
|  |  +--------------------------------------------------------------------+ | |
|  +-----------------------------------------------------------------------+ |
|                                                                               |
|  +-----------------------------------------------------------------------+ |
|  |                     WALLIX BESTSAFE (PEDM)                               | |
|  |                                                                          | |
|  |  Endpoint privilege management for engineering workstations              | |
|  |                                                                          | |
|  |  +--------------------------------------------------------------------+ | |
|  |  | * Least privilege on operator workstations                         | | |
|  |  | * Application whitelisting for OT software                         | | |
|  |  | * USB device control                                                | | |
|  |  | * Protect engineering stations                                      | | |
|  |  +--------------------------------------------------------------------+ | |
|  +-----------------------------------------------------------------------+ |
|                                                                               |
+===============================================================================+
```

### Why WALLIX for Industrial

```
+===============================================================================+
|                    WALLIX OT ADVANTAGES                                       |
+===============================================================================+
|                                                                               |
|  1. PROXY-BASED ARCHITECTURE                                                  |
|  ===========================                                                  |
|                                                                               |
|  +-----------------------------------------------------------------------+ |
|  |                                                                          | |
|  |  [x] No agents on legacy OT systems                                       | |
|  |  [x] No software installation on PLCs/RTUs                                | |
|  |  [x] No impact on real-time performance                                   | |
|  |  [x] Works with any device that has network access                        | |
|  |  [x] Transparent to end systems                                           | |
|  |                                                                          | |
|  +-----------------------------------------------------------------------+ |
|                                                                               |
|  2. EUROPEAN SECURITY HERITAGE                                                |
|  =============================                                                |
|                                                                               |
|  +-----------------------------------------------------------------------+ |
|  |                                                                          | |
|  |  [x] ANSSI certified (French National Cybersecurity Agency)               | |
|  |  [x] Common Criteria EAL3+ certified                                      | |
|  |  [x] Trusted by European critical infrastructure                          | |
|  |  [x] Data sovereignty (no cloud dependency required)                      | |
|  |  [x] NIS/NIS2 Directive alignment                                         | |
|  |                                                                          | |
|  +-----------------------------------------------------------------------+ |
|                                                                               |
|  3. INDUSTRIAL PROTOCOL EXPERTISE                                             |
|  ================================                                             |
|                                                                               |
|  +-----------------------------------------------------------------------+ |
|  |                                                                          | |
|  |  [x] Native support for industrial protocols                              | |
|  |  [x] Protocol-aware session inspection                                    | |
|  |  [x] OT-specific session recording                                        | |
|  |  [x] Partnership with OT security vendors                                 | |
|  |  [x] Understanding of ICS/SCADA environments                              | |
|  |                                                                          | |
|  +-----------------------------------------------------------------------+ |
|                                                                               |
|  4. DEPLOYMENT FLEXIBILITY                                                    |
|  =========================                                                    |
|                                                                               |
|  +-----------------------------------------------------------------------+ |
|  |                                                                          | |
|  |  [x] On-premises deployment (no cloud required)                           | |
|  |  [x] Air-gapped environment support                                       | |
|  |  [x] Small footprint for distributed sites                                | |
|  |  [x] Hardened appliance option                                            | |
|  |  [x] Virtual or physical deployment                                       | |
|  |                                                                          | |
|  +-----------------------------------------------------------------------+ |
|                                                                               |
+===============================================================================+
```

---

## Industrial Security Landscape

### Purdue Model (ISA-95)

```
+===============================================================================+
|                    PURDUE MODEL / ISA-95                                      |
+===============================================================================+
|                                                                               |
|  The Purdue Model defines security zones in industrial environments:          |
|                                                                               |
|  +-----------------------------------------------------------------------+ |
|  | LEVEL 5: Enterprise Network                                              | |
|  | -----------------------------                                            | |
|  | * Corporate IT systems                                                   | |
|  | * Email, ERP, business applications                                      | |
|  | * Internet connectivity                                                  | |
|  +-----------------------------------------------------------------------+ |
|                              |                                                |
|                    =====================                                     |
|                       IT/OT DMZ (Level 3.5)                                  |
|                    =====================                                     |
|                              |                                                |
|  +-----------------------------------------------------------------------+ |
|  | LEVEL 4: Site Business Planning & Logistics                              | |
|  | -------------------------------------------                              | |
|  | * MES (Manufacturing Execution System)                                   | |
|  | * Historian servers                                                      | |
|  | * Production scheduling                                                  | |
|  +-----------------------------------------------------------------------+ |
|                              |                                                |
|  +-----------------------------------------------------------------------+ |
|  | LEVEL 3: Site Manufacturing Operations                                   | |
|  | -----------------------------------------                                | |
|  | * SCADA servers                                                          | |
|  | * Engineering workstations                                               | |
|  | * Patch management servers                                               | |
|  |                                                                          | |
|  |  +===================================================================+  | |
|  |  |           WALLIX BASTION DEPLOYMENT ZONE                          |  | |
|  |  |                                                                    |  | |
|  |  |   Secure access to Levels 0-2 from Levels 3-5                     |  | |
|  |  +===================================================================+  | |
|  |                                                                          | |
|  +-----------------------------------------------------------------------+ |
|                              |                                                |
|  +-----------------------------------------------------------------------+ |
|  | LEVEL 2: Area Supervisory Control                                        | |
|  | ------------------------------------                                     | |
|  | * HMI (Human Machine Interface)                                          | |
|  | * Operator workstations                                                  | |
|  | * Local SCADA                                                            | |
|  +-----------------------------------------------------------------------+ |
|                              |                                                |
|  +-----------------------------------------------------------------------+ |
|  | LEVEL 1: Basic Control                                                   | |
|  | -----------------------                                                  | |
|  | * PLC (Programmable Logic Controller)                                    | |
|  | * RTU (Remote Terminal Unit)                                             | |
|  | * DCS controllers                                                        | |
|  +-----------------------------------------------------------------------+ |
|                              |                                                |
|  +-----------------------------------------------------------------------+ |
|  | LEVEL 0: Physical Process                                                | |
|  | --------------------------                                               | |
|  | * Sensors, actuators, motors                                             | |
|  | * Physical equipment                                                     | |
|  | * Field devices                                                          | |
|  +-----------------------------------------------------------------------+ |
|                                                                               |
+===============================================================================+
```

### Industrial Attack Surface

```
+===============================================================================+
|                    INDUSTRIAL ATTACK SURFACE                                  |
+===============================================================================+
|                                                                               |
|  COMMON ATTACK VECTORS                                                        |
|  =====================                                                        |
|                                                                               |
|  1. REMOTE ACCESS                                                             |
|     +-- Compromised VPN credentials                                          |
|     +-- Vendor laptop infection                                              |
|     +-- Unsecured remote desktop                                             |
|     +-- Jump host compromise                                                 |
|                                                                               |
|  2. INSIDER THREAT                                                            |
|     +-- Disgruntled employee                                                 |
|     +-- Accidental misconfiguration                                          |
|     +-- Social engineering                                                   |
|     +-- Credential sharing                                                   |
|                                                                               |
|  3. SUPPLY CHAIN                                                              |
|     +-- Compromised vendor software                                          |
|     +-- Malicious firmware updates                                           |
|     +-- Infected replacement parts                                           |
|     +-- Third-party integrator access                                        |
|                                                                               |
|  4. IT/OT CONVERGENCE                                                         |
|     +-- Lateral movement from IT                                             |
|     +-- Historian server compromise                                          |
|     +-- DMZ breach                                                           |
|     +-- Shared credentials IT/OT                                             |
|                                                                               |
|  NOTABLE INDUSTRIAL ATTACKS                                                   |
|  ==========================                                                   |
|                                                                               |
|  +-----------------------------------------------------------------------+ |
|  | Attack          | Year | Impact                                         | |
|  +-----------------+------+------------------------------------------------+ |
|  | Stuxnet         | 2010 | Iranian nuclear centrifuges destroyed          | |
|  | Ukraine Grid    | 2015 | 230,000 people without power                   | |
|  | TRITON/TRISIS   | 2017 | Safety systems targeted (petrochemical)        | |
|  | Norsk Hydro     | 2019 | $70M+ ransomware damage                        | |
|  | Colonial Pipeline| 2021| US East Coast fuel shortage                    | |
|  | Oldsmar Water   | 2021 | Attempted water poisoning                      | |
|  +-----------------+------+------------------------------------------------+ |
|                                                                               |
+===============================================================================+
```

---

## Regulatory Frameworks

### Industrial Security Regulations

```
+===============================================================================+
|                    REGULATORY FRAMEWORKS                                      |
+===============================================================================+
|                                                                               |
|  INTERNATIONAL STANDARDS                                                      |
|  =======================                                                      |
|                                                                               |
|  +-----------------------------------------------------------------------+ |
|  | IEC 62443 (ISA/IEC)                                                      | |
|  | ---------------------                                                    | |
|  | "Industrial Automation and Control Systems Security"                     | |
|  | * Comprehensive framework for OT security                               | |
|  | * Security levels (SL 1-4)                                              | |
|  | * Zones and conduits model                                              | |
|  | * Product certification program                                         | |
|  +-----------------------------------------------------------------------+ |
|                                                                               |
|  +-----------------------------------------------------------------------+ |
|  | NIST Cybersecurity Framework (CSF)                                       | |
|  | ----------------------------------                                       | |
|  | * Identify, Protect, Detect, Respond, Recover                           | |
|  | * Widely adopted in US critical infrastructure                          | |
|  | * Maps to other standards                                               | |
|  +-----------------------------------------------------------------------+ |
|                                                                               |
|  +-----------------------------------------------------------------------+ |
|  | NIST SP 800-82                                                           | |
|  | ------------------                                                       | |
|  | "Guide to ICS Security"                                                  | |
|  | * Specific guidance for industrial systems                              | |
|  | * Risk assessment methodology                                           | |
|  | * Security architecture recommendations                                 | |
|  +-----------------------------------------------------------------------+ |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  EUROPEAN REGULATIONS                                                         |
|  ====================                                                         |
|                                                                               |
|  +-----------------------------------------------------------------------+ |
|  | NIS2 Directive (2022/2555)                                               | |
|  | --------------------------                                               | |
|  | * Expanded scope to more sectors                                        | |
|  | * Mandatory incident reporting (24 hours)                               | |
|  | * Supply chain security requirements                                    | |
|  | * Personal liability for management                                     | |
|  | * Fines up to 10M EUR or 2% global revenue                              | |
|  | * Deadline: October 2024 transposition                                  | |
|  +-----------------------------------------------------------------------+ |
|                                                                               |
|  +-----------------------------------------------------------------------+ |
|  | EU Cybersecurity Act                                                     | |
|  | ------------------------                                                 | |
|  | * ENISA permanent mandate                                               | |
|  | * EU-wide certification framework                                       | |
|  | * Industrial product certification                                      | |
|  +-----------------------------------------------------------------------+ |
|                                                                               |
|  SECTOR-SPECIFIC                                                              |
|  ===============                                                              |
|                                                                               |
|  * NERC CIP (North American electric grid)                                   |
|  * TSA Pipeline Security Directives (US pipelines)                          |
|  * Nuclear: 10 CFR 73.54 (US), various national regulations                 |
|  * Maritime: IMO Guidelines, BIMCO                                           |
|  * Rail: TSA Rail Security Directives                                        |
|                                                                               |
+===============================================================================+
```

---

## Industrial PAM Use Cases

### Primary Use Cases

```
+===============================================================================+
|                    INDUSTRIAL PAM USE CASES                                   |
+===============================================================================+
|                                                                               |
|  USE CASE 1: VENDOR REMOTE ACCESS                                             |
|  ================================                                             |
|                                                                               |
|  Challenge:                                                                   |
|  * Multiple equipment vendors need access                                    |
|  * Each vendor has different support personnel                               |
|  * Access needed 24/7 for critical issues                                    |
|  * No visibility into vendor activities                                      |
|                                                                               |
|  WALLIX Solution:                                                             |
|  +-----------------------------------------------------------------------+ |
|  | * Secure web portal for all vendor access                               | |
|  | * Individual accounts per technician (no shared credentials)            | |
|  | * Just-in-time access with approval workflow                            | |
|  | * Full session recording for audit                                      | |
|  | * Time-limited access windows                                           | |
|  | * Protocol filtering (only necessary access)                            | |
|  +-----------------------------------------------------------------------+ |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  USE CASE 2: OPERATOR ACCESS CONTROL                                          |
|  ===================================                                          |
|                                                                               |
|  Challenge:                                                                   |
|  * Shared "operator" accounts                                                |
|  * No individual accountability                                              |
|  * Same credentials used across shifts                                       |
|  * Critical operations lack audit trail                                      |
|                                                                               |
|  WALLIX Solution:                                                             |
|  +-----------------------------------------------------------------------+ |
|  | * Individual user authentication before HMI access                      | |
|  | * Credential injection (operators don't know passwords)                 | |
|  | * Session recording for every HMI interaction                           | |
|  | * Role-based access (operator vs. supervisor)                           | |
|  | * Shift-based access scheduling                                         | |
|  +-----------------------------------------------------------------------+ |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  USE CASE 3: ENGINEERING WORKSTATION SECURITY                                 |
|  ============================================                                 |
|                                                                               |
|  Challenge:                                                                   |
|  * Engineering workstations have direct PLC access                          |
|  * Programming changes can impact production                                 |
|  * USB drives used for program transfer                                      |
|  * Internet access on same systems                                           |
|                                                                               |
|  WALLIX Solution:                                                             |
|  +-----------------------------------------------------------------------+ |
|  | * All PLC access through WALLIX gateway                                 | |
|  | * Approval required for programming sessions                            | |
|  | * Session recording of all engineering changes                          | |
|  | * File transfer monitoring and logging                                  | |
|  | * PEDM for workstation privilege control                                | |
|  +-----------------------------------------------------------------------+ |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  USE CASE 4: MULTI-SITE MANAGEMENT                                            |
|  =================================                                            |
|                                                                               |
|  Challenge:                                                                   |
|  * Dozens/hundreds of remote sites                                           |
|  * Limited on-site IT support                                               |
|  * Inconsistent security across sites                                       |
|  * Central SOC needs visibility                                             |
|                                                                               |
|  WALLIX Solution:                                                             |
|  +-----------------------------------------------------------------------+ |
|  | * Distributed Bastion deployment at each site                           | |
|  | * Centralized management and policy                                     | |
|  | * Unified audit and reporting                                           | |
|  | * Local operation even if WAN fails                                     | |
|  | * Central SOC real-time monitoring                                      | |
|  +-----------------------------------------------------------------------+ |
|                                                                               |
+===============================================================================+
```

---

## Next Steps

Continue to [16 - OT Architecture](../16-ot-architecture/README.md) for detailed industrial deployment architectures.
