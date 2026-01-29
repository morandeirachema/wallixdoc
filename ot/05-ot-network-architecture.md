# OT Network Architecture

Designing and securing industrial network architectures.

## The Purdue Model

The Purdue Enterprise Reference Architecture (PERA) is the foundation of OT network design:

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Purdue Model / ISA-95 Levels                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Level 5  ┌─────────────────────────────────────────────────────┐   │
│  Enterprise│   Internet, Cloud Services, Remote Sites           │   │
│           └─────────────────────────────────────────────────────┘   │
│                                   │                                  │
│  ═══════════════════════════════════════════════════════════════    │
│                        Enterprise Firewall                           │
│  ═══════════════════════════════════════════════════════════════    │
│                                   │                                  │
│  Level 4  ┌─────────────────────────────────────────────────────┐   │
│  Business │   ERP, Email, Business Applications, Corporate IT    │   │
│  Planning └─────────────────────────────────────────────────────┘   │
│                                   │                                  │
│  ═══════════════════════════════════════════════════════════════    │
│                        IT/OT Firewall (DMZ)                          │
│  ═══════════════════════════════════════════════════════════════    │
│                                   │                                  │
│  Level 3.5┌─────────────────────────────────────────────────────┐   │
│  DMZ      │   Historian Mirror, Jump Server, Patch Server       │   │
│           └─────────────────────────────────────────────────────┘   │
│                                   │                                  │
│  ═══════════════════════════════════════════════════════════════    │
│                        OT Firewall                                   │
│  ═══════════════════════════════════════════════════════════════    │
│                                   │                                  │
│  Level 3  ┌─────────────────────────────────────────────────────┐   │
│  Site     │   SCADA Server, Historian, Engineering Workstation  │   │
│  Operations└────────────────────────────────────────────────────┘   │
│                                   │                                  │
│  Level 2  ┌─────────────────────────────────────────────────────┐   │
│  Area     │   HMI, Local SCADA, OPC Gateway                     │   │
│  Supervisory└───────────────────────────────────────────────────┘   │
│                                   │                                  │
│  Level 1  ┌─────────────────────────────────────────────────────┐   │
│  Basic    │   PLC, DCS Controller, RTU, Safety Controller       │   │
│  Control  └─────────────────────────────────────────────────────┘   │
│                                   │                                  │
│  Level 0  ┌─────────────────────────────────────────────────────┐   │
│  Process  │   Sensors, Actuators, Field Devices                 │   │
│           └─────────────────────────────────────────────────────┘   │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Zone and Conduit Model (IEC 62443)

IEC 62443 introduces zones and conduits for security architecture:

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Zones and Conduits                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   ZONE: A logical or physical grouping of assets that share         │
│         common security requirements                                 │
│                                                                      │
│   CONDUIT: The communication path between zones, providing          │
│            security functions                                        │
│                                                                      │
│   ┌─────────────────┐                ┌─────────────────┐            │
│   │   Zone A        │    Conduit     │   Zone B        │            │
│   │   (SL2)         │◄══════════════►│   (SL3)         │            │
│   │                 │   Firewall     │                 │            │
│   │  Assets with    │   + VPN        │  Assets with    │            │
│   │  similar        │   + Logging    │  higher         │            │
│   │  security       │                │  security       │            │
│   │  requirements   │                │  requirements   │            │
│   └─────────────────┘                └─────────────────┘            │
│                                                                      │
│   Security Level (SL) assigned based on:                             │
│   • Asset criticality                                                │
│   • Threat exposure                                                  │
│   • Regulatory requirements                                          │
│   • Consequence of compromise                                        │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Security Levels

| Level | Target | Description |
|-------|--------|-------------|
| **SL 0** | None | No specific requirements |
| **SL 1** | Casual/Accidental | Protection against unintentional errors |
| **SL 2** | Intentional/Simple | Protection against intentional attacks with low resources |
| **SL 3** | Intentional/Sophisticated | Protection against sophisticated attacks |
| **SL 4** | State-Sponsored | Protection against nation-state attacks |

## Network Segmentation Strategies

### Macro-Segmentation

Large-scale network division:

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Macro-Segmentation Example                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│                        Corporate Network                             │
│                    ┌─────────────────────────┐                       │
│                    │   Level 4-5             │                       │
│                    │   IT Systems            │                       │
│                    └───────────┬─────────────┘                       │
│                                │                                     │
│                         ┌──────┴──────┐                              │
│                         │   DMZ       │                              │
│                         │  Firewall   │                              │
│                         └──────┬──────┘                              │
│                                │                                     │
│                    ┌───────────┴───────────┐                         │
│                    │      OT DMZ           │                         │
│                    │   (Level 3.5)         │                         │
│                    └───────────┬───────────┘                         │
│                                │                                     │
│         ┌──────────────────────┼──────────────────────┐              │
│         │                      │                      │              │
│   ┌─────┴─────┐          ┌─────┴─────┐         ┌──────┴────┐        │
│   │  Plant A  │          │  Plant B  │         │  Utility  │        │
│   │  Zone     │          │  Zone     │         │  Zone     │        │
│   └───────────┘          └───────────┘         └───────────┘        │
│                                                                      │
│   Each plant/area is a separate zone with dedicated firewall        │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Micro-Segmentation

Finer-grained segmentation within zones:

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Micro-Segmentation Within Plant Zone              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Plant A Zone                                                       │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │                                                             │   │
│   │   ┌───────────────┐   ┌───────────────┐   ┌─────────────┐  │   │
│   │   │  Process      │   │  Packaging    │   │  Utility    │  │   │
│   │   │  Control      │   │  Line         │   │  Systems    │  │   │
│   │   │  Cell         │   │  Cell         │   │  Cell       │  │   │
│   │   │               │   │               │   │             │  │   │
│   │   │  ┌───────┐    │   │  ┌───────┐    │   │  ┌───────┐  │  │   │
│   │   │  │ PLC 1 │    │   │  │ PLC 3 │    │   │  │ BMS   │  │  │   │
│   │   │  │ PLC 2 │    │   │  │ Robot │    │   │  │ HVAC  │  │  │   │
│   │   │  │ HMI   │    │   │  │ HMI   │    │   │  │ Fire  │  │  │   │
│   │   │  └───────┘    │   │  └───────┘    │   │  └───────┘  │  │   │
│   │   │               │   │               │   │             │  │   │
│   │   └───────┬───────┘   └───────┬───────┘   └──────┬──────┘  │   │
│   │           │                   │                  │         │   │
│   │           └─────────┬─────────┴──────────────────┘         │   │
│   │                     │                                      │   │
│   │              ┌──────┴──────┐                                │   │
│   │              │  Industrial │                                │   │
│   │              │  Firewall   │                                │   │
│   │              └──────┬──────┘                                │   │
│   │                     │                                      │   │
│   │              ┌──────┴──────┐                                │   │
│   │              │ Plant Level │                                │   │
│   │              │   SCADA     │                                │   │
│   │              └─────────────┘                                │   │
│   │                                                             │   │
│   └─────────────────────────────────────────────────────────────┘   │
│                                                                      │
│   Each cell is isolated - lateral movement prevented                 │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## DMZ Architecture

The OT DMZ is the critical boundary between IT and OT:

```
┌─────────────────────────────────────────────────────────────────────┐
│                    OT DMZ Architecture                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   IT Network (Level 4)                                               │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │   ERP, MES Client, Business Applications                    │   │
│   └──────────────────────────┬──────────────────────────────────┘   │
│                              │                                       │
│                       ┌──────┴──────┐                                │
│                       │  Firewall 1 │ (North)                        │
│                       │  (IT-facing)│                                │
│                       └──────┬──────┘                                │
│                              │                                       │
│   OT DMZ (Level 3.5)         │                                       │
│   ┌──────────────────────────┼──────────────────────────────────┐   │
│   │                          │                                  │   │
│   │   ┌───────────┐    ┌─────┴─────┐    ┌───────────┐          │   │
│   │   │ Historian │    │   Patch   │    │   Jump    │          │   │
│   │   │  Mirror   │    │  Server   │    │  Server   │          │   │
│   │   │           │    │  (WSUS)   │    │   (PAM)   │          │   │
│   │   └───────────┘    └───────────┘    └───────────┘          │   │
│   │                                                             │   │
│   │   ┌───────────┐    ┌───────────┐    ┌───────────┐          │   │
│   │   │   AV/     │    │  Remote   │    │   OPC     │          │   │
│   │   │  Update   │    │  Access   │    │  Gateway  │          │   │
│   │   │  Server   │    │   VPN     │    │           │          │   │
│   │   └───────────┘    └───────────┘    └───────────┘          │   │
│   │                                                             │   │
│   └──────────────────────────┼──────────────────────────────────┘   │
│                              │                                       │
│                       ┌──────┴──────┐                                │
│                       │  Firewall 2 │ (South)                        │
│                       │ (OT-facing) │                                │
│                       └──────┬──────┘                                │
│                              │                                       │
│   OT Network (Level 3)       │                                       │
│   ┌──────────────────────────┴──────────────────────────────────┐   │
│   │   SCADA, Historian, Engineering Workstations                │   │
│   └─────────────────────────────────────────────────────────────┘   │
│                                                                      │
│   Key Principles:                                                    │
│   • Two firewalls - different vendors if possible                    │
│   • No direct IT-to-OT communication                                 │
│   • All data flows through DMZ services                              │
│   • DMZ servers initiate connections (push/pull)                     │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### DMZ Service Functions

| Service | Purpose | Data Flow |
|---------|---------|-----------|
| **Historian Mirror** | Replicate process data to IT | OT → DMZ → IT |
| **Patch Server** | Stage and test patches | IT → DMZ, DMZ → OT |
| **Jump Server** | Secure remote access | IT → DMZ → OT |
| **AV Update Server** | Distribute signature updates | IT → DMZ → OT |
| **OPC Gateway** | Protocol conversion | Bidirectional, controlled |
| **File Transfer** | Move files between networks | Either direction, scanned |

## Firewall Design

### Industrial Firewall Requirements

| Requirement | IT Firewall | OT Firewall |
|-------------|-------------|-------------|
| **Form Factor** | Rack mount | DIN rail or rack |
| **Environment** | Data center | Plant floor |
| **Protocols** | IT (HTTP, DNS, etc.) | Industrial (Modbus, EtherNet/IP) |
| **Latency** | Milliseconds OK | Microseconds for some |
| **Redundancy** | Active/passive | Active/active often |
| **Management** | Centralized | Local + centralized |

### Firewall Rule Philosophy

```
┌─────────────────────────────────────────────────────────────────────┐
│                    OT Firewall Rule Design                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Principle: Explicit allow, default deny                            │
│                                                                      │
│   Good OT Firewall Rules:                                            │
│   ─────────────────────────                                          │
│   Rule 1: ALLOW  10.1.1.10 → 10.2.1.20:502 (Modbus)                 │
│   Rule 2: ALLOW  10.1.1.11 → 10.2.1.20:502 (Modbus)                 │
│   Rule 3: ALLOW  10.1.1.5  → 10.2.1.0/24:44818 (EtherNet/IP)        │
│   Rule N: DENY   ANY → ANY (Log)                                    │
│                                                                      │
│   Bad IT-style Rules (too permissive for OT):                       │
│   ─────────────────────────────────────────────                      │
│   Rule 1: ALLOW  10.1.0.0/16 → 10.2.0.0/16:ANY                      │
│   Rule 2: DENY   ANY → ANY                                          │
│                                                                      │
│   OT-Specific Considerations:                                        │
│   • List specific host IPs, not subnets                              │
│   • Specify exact ports/protocols                                    │
│   • Direction matters (initiated by which side)                      │
│   • Consider protocol-aware inspection                               │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Deep Packet Inspection for Industrial Protocols

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Protocol-Aware Firewall Rules                     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Basic Rule (port-based):                                           │
│   ALLOW  HMI → PLC:502                                               │
│   Result: All Modbus traffic allowed                                 │
│                                                                      │
│   DPI Rule (function-aware):                                         │
│   ALLOW  HMI → PLC:502  Modbus FC 03,04 (Read only)                 │
│   DENY   HMI → PLC:502  Modbus FC 05,06,15,16 (Write)               │
│                                                                      │
│   Result: HMI can monitor but not control                            │
│                                                                      │
│   ─────────────────────────────────────────────────────────────────  │
│                                                                      │
│   Advanced Rules (register-aware):                                   │
│   ALLOW  Eng_WS → PLC:502  Modbus FC 03 Reg 40001-40100             │
│   ALLOW  Eng_WS → PLC:502  Modbus FC 06 Reg 40050                   │
│   DENY   Eng_WS → PLC:502  Modbus FC 16 Reg ANY                     │
│                                                                      │
│   Result: Engineer can read registers and write to one setpoint     │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Remote Access Architecture

### Secure Remote Access Requirements

| Requirement | Implementation |
|-------------|----------------|
| **Authentication** | MFA, certificate-based |
| **Authorization** | Role-based, time-limited |
| **Audit** | Session recording, command logging |
| **Isolation** | Jump server, no direct access |
| **Network Path** | VPN, through DMZ only |

### Remote Access Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Secure Remote Access Pattern                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Remote User                                                        │
│   ┌──────────────┐                                                  │
│   │   Vendor     │                                                  │
│   │   Laptop     │                                                  │
│   └──────┬───────┘                                                  │
│          │                                                          │
│          │ HTTPS (443)                                              │
│          ▼                                                          │
│   ┌──────────────┐                                                  │
│   │   Internet   │                                                  │
│   └──────┬───────┘                                                  │
│          │                                                          │
│          │ VPN (IPsec/TLS)                                          │
│          ▼                                                          │
│   ┌──────────────────────────────────────────────────────────────┐  │
│   │   Corporate Perimeter                                        │  │
│   │   ┌────────────┐                                             │  │
│   │   │  VPN       │                                             │  │
│   │   │ Gateway    │                                             │  │
│   │   └─────┬──────┘                                             │  │
│   └─────────┼────────────────────────────────────────────────────┘  │
│             │                                                        │
│             │ Authenticated session                                  │
│             ▼                                                        │
│   ┌──────────────────────────────────────────────────────────────┐  │
│   │   OT DMZ                                                     │  │
│   │   ┌────────────────────────────────────────────────────┐     │  │
│   │   │   PAM / Jump Server                                │     │  │
│   │   │   ┌───────────────────────────────────────────┐    │     │  │
│   │   │   │ • MFA verification                        │    │     │  │
│   │   │   │ • Approval workflow                       │    │     │  │
│   │   │   │ • Session recording                       │    │     │  │
│   │   │   │ • Credential injection                    │    │     │  │
│   │   │   │ • Time-limited access                     │    │     │  │
│   │   │   └───────────────────────────────────────────┘    │     │  │
│   │   └────────────────────────┬───────────────────────────┘     │  │
│   └────────────────────────────┼─────────────────────────────────┘  │
│                                │                                     │
│                                │ Proxied connection                  │
│                                ▼                                     │
│   ┌──────────────────────────────────────────────────────────────┐  │
│   │   OT Network                                                 │  │
│   │   ┌────────────┐    ┌────────────┐    ┌────────────┐        │  │
│   │   │   PLC      │    │   HMI      │    │   DCS      │        │  │
│   │   └────────────┘    └────────────┘    └────────────┘        │  │
│   └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
│   User never has direct network access to OT                         │
│   All sessions proxied through PAM                                   │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Data Diode Architectures

For high-security environments requiring one-way data flow:

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Data Diode Implementation                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   OT Network (Protected)                                             │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │                                                             │   │
│   │   ┌───────────┐    ┌───────────┐    ┌───────────┐          │   │
│   │   │   SCADA   │    │ Historian │    │    DCS    │          │   │
│   │   └─────┬─────┘    └─────┬─────┘    └───────────┘          │   │
│   │         │                │                                  │   │
│   │         └────────────────┤                                  │   │
│   │                          │                                  │   │
│   │                   ┌──────┴──────┐                           │   │
│   │                   │   Diode     │                           │   │
│   │                   │   Sender    │                           │   │
│   │                   └──────┬──────┘                           │   │
│   │                          │                                  │   │
│   └──────────────────────────┼──────────────────────────────────┘   │
│                              │                                       │
│                              │ Fiber optic                           │
│                              │ (TX only, no RX)                      │
│                              │                                       │
│                              ▼                                       │
│   ┌──────────────────────────────────────────────────────────────┐  │
│   │                   DATA DIODE HARDWARE                        │  │
│   │                   (One-way optical link)                     │  │
│   └──────────────────────────────────────────────────────────────┘  │
│                              │                                       │
│                              │ Fiber optic                           │
│                              │ (RX only, no TX)                      │
│                              ▼                                       │
│   ┌──────────────────────────────────────────────────────────────┐  │
│   │                   ┌──────┴──────┐                            │  │
│   │                   │   Diode     │                            │  │
│   │                   │  Receiver   │                            │  │
│   │                   └──────┬──────┘                            │  │
│   │                          │                                   │  │
│   │   IT/DMZ Network         │                                   │  │
│   │                   ┌──────┴──────┐                            │  │
│   │                   │  Historian  │                            │  │
│   │                   │   Replica   │                            │  │
│   │                   └─────────────┘                            │  │
│   │                                                              │  │
│   └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
│   Data flows OUT of OT only - cannot receive commands                │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Data Diode Use Cases

| Use Case | Description |
|----------|-------------|
| **Historian Replication** | Copy process data to business network |
| **Log Export** | Send security logs to SIEM |
| **Regulatory Reporting** | Transmit compliance data |
| **Safety System Monitoring** | Monitor without risk of interference |

## Wireless Networks in OT

### Industrial Wireless Standards

| Standard | Frequency | Range | Use Case |
|----------|-----------|-------|----------|
| **WirelessHART** | 2.4 GHz | 200m | Process instrumentation |
| **ISA100.11a** | 2.4 GHz | 200m | Process automation |
| **Wi-Fi (802.11)** | 2.4/5 GHz | 100m | General plant networking |
| **Private LTE/5G** | Various | 1km+ | Wide area, high bandwidth |
| **LoRaWAN** | Sub-GHz | 10km+ | Low-power sensors |

### Wireless Security Considerations

```
┌─────────────────────────────────────────────────────────────────────┐
│                    OT Wireless Security                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Challenges:                                                        │
│   • RF signals extend beyond physical boundaries                     │
│   • Interference from other equipment                                │
│   • Legacy devices may not support WPA2/WPA3                         │
│   • Real-time requirements limit encryption options                  │
│                                                                      │
│   Best Practices:                                                    │
│   ─────────────────                                                  │
│   1. Separate OT wireless from IT wireless (different SSIDs/VLANs)   │
│   2. Use WPA3 Enterprise where possible                              │
│   3. Certificate-based authentication                                │
│   4. Wireless IDS/IPS for rogue AP detection                         │
│   5. Physical RF surveys to limit coverage area                      │
│   6. Consider wired alternatives for critical systems                │
│                                                                      │
│   Architecture:                                                      │
│                                                                      │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │  Wireless Controller (in DMZ)                               │   │
│   └──────────────────────────┬──────────────────────────────────┘   │
│                              │                                       │
│          ┌───────────────────┼───────────────────┐                   │
│          │                   │                   │                   │
│          ▼                   ▼                   ▼                   │
│   ┌────────────┐      ┌────────────┐      ┌────────────┐            │
│   │   AP #1    │      │   AP #2    │      │   AP #3    │            │
│   │  (Area A)  │      │  (Area B)  │      │  (Area C)  │            │
│   └────────────┘      └────────────┘      └────────────┘            │
│                                                                      │
│   Each area may have different security policies                     │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Network Monitoring

### What to Monitor

| Layer | Monitor For |
|-------|-------------|
| **Network** | Traffic patterns, new devices, port scans |
| **Protocol** | Invalid commands, unusual function codes |
| **Application** | Configuration changes, firmware updates |
| **Behavioral** | Deviations from baseline |

### OT Network Monitoring Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    OT Network Monitoring                             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   OT Network                                                         │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │                                                             │   │
│   │  ┌───────┐  ┌───────┐  ┌───────┐  ┌───────┐               │   │
│   │  │  PLC  │  │  HMI  │  │  DCS  │  │ SCADA │               │   │
│   │  └───┬───┘  └───┬───┘  └───┬───┘  └───┬───┘               │   │
│   │      │          │          │          │                    │   │
│   │      └──────────┴──────────┴──────────┘                    │   │
│   │                      │                                      │   │
│   │              ┌───────┴───────┐                              │   │
│   │              │   Industrial  │                              │   │
│   │              │    Switch     │                              │   │
│   │              │  (SPAN port)  │                              │   │
│   │              └───────┬───────┘                              │   │
│   │                      │                                      │   │
│   │              ┌───────┴───────┐                              │   │
│   │              │    Network    │                              │   │
│   │              │    TAP        │                              │   │
│   │              └───────┬───────┘                              │   │
│   │                      │                                      │   │
│   └──────────────────────┼──────────────────────────────────────┘   │
│                          │                                           │
│                          │ Mirrored traffic                          │
│                          ▼                                           │
│   ┌──────────────────────────────────────────────────────────────┐  │
│   │   Monitoring Zone (Out of Band)                              │  │
│   │                                                              │  │
│   │   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │  │
│   │   │   OT IDS    │    │  Network    │    │   Asset     │     │  │
│   │   │ (Claroty,   │    │  Recorder   │    │  Inventory  │     │  │
│   │   │  Nozomi,    │    │             │    │             │     │  │
│   │   │  Dragos)    │    │             │    │             │     │  │
│   │   └──────┬──────┘    └─────────────┘    └─────────────┘     │  │
│   │          │                                                   │  │
│   │          │ Alerts                                            │  │
│   │          ▼                                                   │  │
│   │   ┌─────────────┐                                            │  │
│   │   │    SIEM     │                                            │  │
│   │   │ (Splunk,    │                                            │  │
│   │   │  Elastic)   │                                            │  │
│   │   └─────────────┘                                            │  │
│   │                                                              │  │
│   └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
│   Passive monitoring - no packets injected into OT network          │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Common Port Reference

| Port | Protocol | Description |
|------|----------|-------------|
| 20000 | DNP3 | SCADA protocol |
| 102 | S7comm | Siemens PLC |
| 502 | Modbus TCP | Industrial protocol |
| 2222 | EtherNet/IP (UDP) | Implicit I/O |
| 4840 | OPC UA | Industrial interoperability |
| 44818 | EtherNet/IP (TCP) | Explicit messaging |
| 47808 | BACnet | Building automation |
| 1911-1912 | Niagara Fox | Building automation |
| 18245-18246 | GE SRTP | GE PLCs |
| 5094 | HART-IP | Process instrumentation |

## Key Takeaways

1. **Purdue Model provides structure** - use it as your reference architecture
2. **Zones and conduits** - group assets by security requirements
3. **DMZ is mandatory** - never connect IT directly to OT
4. **Defense in depth** - multiple layers of security
5. **Protocol-aware firewalls** - basic port filtering isn't enough
6. **Remote access through PAM** - no direct VPN to OT
7. **Passive monitoring** - don't inject traffic into OT networks
8. **Wireless is risky** - prefer wired where possible

## Study Questions

1. What is the purpose of the OT DMZ, and what services typically reside there?

2. Why might you use two firewalls from different vendors in a DMZ architecture?

3. How does a data diode provide stronger security than a firewall?

4. What is the difference between macro-segmentation and micro-segmentation?

5. Why is passive network monitoring preferred for OT environments?

## Design Exercise

Design a network architecture for:
- Manufacturing plant with 3 production lines
- Corporate connectivity required for production reporting
- Remote vendor access needed for PLC maintenance
- Regulatory requirement for air-gapped safety systems

## Next Steps

Continue to [06-legacy-systems.md](06-legacy-systems.md) to learn how to secure systems that cannot be patched or upgraded.

## References

- NIST SP 800-82 Rev. 2 - Guide to ICS Security
- IEC 62443-3-2 - Security Risk Assessment and System Design
- CISA - Recommended Practice: Improving ICS Cybersecurity with Defense-in-Depth Strategies
- ISA/IEC 62443-3-3 - System Security Requirements and Security Levels
