# Industrial Protocols Deep Dive

Understanding the communication protocols that power industrial systems.

## Protocol Landscape Overview

Industrial protocols evolved over decades, resulting in a complex ecosystem:

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Industrial Protocol Timeline                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   1970s ───────────────────────────────────────────────────► 2020s   │
│                                                                      │
│   Serial/Fieldbus        Industrial Ethernet       Modern IIoT      │
│   ─────────────          ─────────────────         ──────────       │
│   • Modbus RTU           • Modbus TCP              • MQTT           │
│   • HART                 • EtherNet/IP             • OPC UA         │
│   • PROFIBUS             • PROFINET                • REST APIs      │
│   • DNP3 Serial          • DNP3 TCP/IP             • AMQP           │
│   • DeviceNet            • S7comm                  • Sparkplug B    │
│                          • BACnet/IP                                │
│                          • IEC 61850                                │
│                                                                      │
│   Still in use today     Primary protocols         Enterprise edge  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Protocol Categories

| Category | Purpose | Examples |
|----------|---------|----------|
| **Fieldbus** | Device-level communication | Modbus, PROFIBUS, DeviceNet |
| **Industrial Ethernet** | Plant-level networking | EtherNet/IP, PROFINET |
| **SCADA/Telecontrol** | Wide-area monitoring | DNP3, IEC 60870-5 |
| **Building Automation** | HVAC, lighting | BACnet, LonWorks |
| **Power Systems** | Substation automation | IEC 61850, DNP3 |
| **IIoT/Cloud** | IT integration | OPC UA, MQTT |

## Modbus

### Overview

The oldest and most widely deployed industrial protocol:

| Attribute | Value |
|-----------|-------|
| **Year Introduced** | 1979 |
| **Developer** | Modicon (now Schneider) |
| **Variants** | RTU (Serial), ASCII (Serial), TCP (Ethernet) |
| **Port** | 502 (TCP) |
| **Security** | None built-in |

### Modbus Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Modbus Master/Slave Model                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│                        ┌────────────┐                                │
│                        │   Master   │                                │
│                        │  (Client)  │                                │
│                        │ HMI/SCADA  │                                │
│                        └─────┬──────┘                                │
│                              │                                       │
│              Request/Response│Protocol                               │
│                              │                                       │
│         ┌────────────────────┼────────────────────┐                  │
│         │                    │                    │                  │
│         ▼                    ▼                    ▼                  │
│   ┌──────────┐        ┌──────────┐        ┌──────────┐              │
│   │  Slave   │        │  Slave   │        │  Slave   │              │
│   │ (Server) │        │ (Server) │        │ (Server) │              │
│   │  ID: 1   │        │  ID: 2   │        │  ID: 3   │              │
│   └──────────┘        └──────────┘        └──────────┘              │
│      PLC                 VFD               Sensor                    │
│                                                                      │
│   Master initiates all communication                                 │
│   Slaves only respond when polled                                    │
│   One master, multiple slaves (1-247)                                │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Modbus Data Model

| Register Type | Address Range | Size | Access |
|---------------|---------------|------|--------|
| **Coils** | 00001-09999 | 1 bit | Read/Write |
| **Discrete Inputs** | 10001-19999 | 1 bit | Read Only |
| **Input Registers** | 30001-39999 | 16 bit | Read Only |
| **Holding Registers** | 40001-49999 | 16 bit | Read/Write |

### Common Modbus Function Codes

| Code | Function | Description |
|------|----------|-------------|
| 01 | Read Coils | Read digital outputs |
| 02 | Read Discrete Inputs | Read digital inputs |
| 03 | Read Holding Registers | Read analog outputs |
| 04 | Read Input Registers | Read analog inputs |
| 05 | Write Single Coil | Write single digital output |
| 06 | Write Single Register | Write single analog output |
| 15 | Write Multiple Coils | Write multiple digital outputs |
| 16 | Write Multiple Registers | Write multiple analog outputs |

### Modbus TCP Packet Structure

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Modbus TCP Frame                                  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │  Transaction │  Protocol  │  Length  │ Unit │ Function │  Data  ││
│  │     ID       │    ID      │          │  ID  │   Code   │        ││
│  │   2 bytes    │  2 bytes   │  2 bytes │ 1b   │  1 byte  │ N bytes││
│  └─────────────────────────────────────────────────────────────────┘│
│                                                                      │
│  Example: Read 10 holding registers starting at 40001               │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │ 00 01 │ 00 00 │ 00 06 │ 01 │ 03 │ 00 00 │ 00 0A │             │ │
│  │ TxID  │ Proto │ Len   │ ID │ Fn │ Start │ Count │             │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Modbus Security Concerns

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Modbus Vulnerabilities                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   1. NO AUTHENTICATION                                               │
│      Any device can send commands                                    │
│      No concept of user identity                                     │
│                                                                      │
│   2. NO ENCRYPTION                                                   │
│      All data sent in cleartext                                      │
│      Easy to sniff and understand                                    │
│                                                                      │
│   3. NO INTEGRITY                                                    │
│      No protection against modification                              │
│      Commands can be injected                                        │
│                                                                      │
│   4. LIMITED FUNCTION VALIDATION                                     │
│      Device may accept any valid command                             │
│      Application must implement limits                               │
│                                                                      │
│   Attack Scenarios:                                                  │
│   • Replay attacks (record and resend commands)                      │
│   • Man-in-the-middle (modify values in transit)                     │
│   • Denial of service (flood with requests)                          │
│   • Unauthorized writes (change setpoints, stop processes)           │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## DNP3 (Distributed Network Protocol)

### Overview

Primary SCADA protocol for utilities:

| Attribute | Value |
|-----------|-------|
| **Year Introduced** | 1993 |
| **Developer** | Westronic (based on IEC 60870) |
| **Use Case** | Electric utilities, water, oil/gas |
| **Port** | 20000 (TCP/UDP) |
| **Security** | Secure Authentication (DNP3-SA) |

### DNP3 Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    DNP3 Master/Outstation Model                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│                    ┌────────────────────┐                            │
│                    │     DNP3 Master    │                            │
│                    │   (Control Center) │                            │
│                    └──────────┬─────────┘                            │
│                               │                                      │
│               ┌───────────────┼───────────────┐                      │
│               │               │               │                      │
│               ▼               ▼               ▼                      │
│         ┌───────────┐   ┌───────────┐   ┌───────────┐               │
│         │ Outstation│   │ Outstation│   │ Outstation│               │
│         │  (RTU)    │   │  (RTU)    │   │  (IED)    │               │
│         │ Addr: 1   │   │ Addr: 2   │   │ Addr: 3   │               │
│         └───────────┘   └───────────┘   └───────────┘               │
│                                                                      │
│   Key Features:                                                      │
│   • Unsolicited responses (event-driven)                             │
│   • Time synchronization                                             │
│   • Multiple data types (binary, analog, counters)                   │
│   • File transfer capability                                         │
│   • Secure authentication (v5+)                                      │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### DNP3 Data Types

| Object Group | Description |
|--------------|-------------|
| 1 | Binary Input |
| 2 | Binary Input Change |
| 3 | Double-bit Binary Input |
| 10 | Binary Output |
| 12 | Control Relay Output Block |
| 20 | Counter |
| 30 | Analog Input |
| 40 | Analog Output |
| 50 | Time and Date |

### DNP3 Secure Authentication

DNP3-SA (version 5+) adds security:

| Feature | Description |
|---------|-------------|
| **Challenge-Response** | HMAC-based authentication |
| **Session Keys** | Pre-shared or certificate-based |
| **Aggressive Mode** | Authenticate with each message |
| **Critical Messages** | Controls always authenticated |

## OPC UA (Unified Architecture)

### Overview

Modern, secure industrial interoperability standard:

| Attribute | Value |
|-----------|-------|
| **Year Introduced** | 2008 |
| **Organization** | OPC Foundation |
| **Transport** | TCP, HTTPS, WebSocket |
| **Port** | 4840 (default) |
| **Security** | Built-in (TLS, certificates, signing) |

### OPC UA Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    OPC UA Client/Server Model                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │                       OPC UA Server                         │   │
│   │  ┌──────────────────────────────────────────────────────┐   │   │
│   │  │                  Address Space                       │   │   │
│   │  │   Objects ─► Variables ─► Methods ─► Events          │   │   │
│   │  │      │            │           │          │           │   │   │
│   │  │   Folders    Data Points  Functions   Alarms         │   │   │
│   │  └──────────────────────────────────────────────────────┘   │   │
│   │                                                             │   │
│   │  ┌──────────────────────────────────────────────────────┐   │   │
│   │  │                   Security Layer                     │   │   │
│   │  │  • User Authentication (anonymous, user/pass, cert)  │   │   │
│   │  │  • Message Security (sign, sign+encrypt)             │   │   │
│   │  │  • Transport Security (TLS)                          │   │   │
│   │  └──────────────────────────────────────────────────────┘   │   │
│   └─────────────────────────────────────────────────────────────┘   │
│                               ▲                                      │
│                               │                                      │
│              ┌────────────────┼────────────────┐                     │
│              │                │                │                     │
│              ▼                ▼                ▼                     │
│        ┌──────────┐    ┌──────────┐    ┌──────────┐                 │
│        │ OPC UA   │    │ OPC UA   │    │ OPC UA   │                 │
│        │ Client   │    │ Client   │    │ Client   │                 │
│        │ (HMI)    │    │(Historian│    │(MES)     │                 │
│        └──────────┘    └──────────┘    └──────────┘                 │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### OPC UA Security Modes

| Mode | Signing | Encryption | Use Case |
|------|---------|------------|----------|
| **None** | No | No | Testing only |
| **Sign** | Yes | No | Integrity required |
| **SignAndEncrypt** | Yes | Yes | Full security |

### OPC UA Security Policies

| Policy | Algorithm | Status |
|--------|-----------|--------|
| None | None | Testing only |
| Basic128Rsa15 | RSA-1024, AES-128 | Deprecated |
| Basic256 | RSA-2048, AES-256 | Legacy |
| Basic256Sha256 | RSA-2048, SHA-256, AES-256 | Current standard |
| Aes128_Sha256_RsaOaep | AES-128-CBC, RSA-OAEP | Recommended |
| Aes256_Sha256_RsaPss | AES-256-CBC, RSA-PSS | Most secure |

## EtherNet/IP and CIP

### Overview

Rockwell Automation's industrial protocol:

| Attribute | Value |
|-----------|-------|
| **Year Introduced** | 2001 |
| **Organization** | ODVA |
| **Base Protocol** | CIP (Common Industrial Protocol) |
| **Port** | 44818 (TCP), 2222 (UDP) |
| **Security** | CIP Security (TLS-based) |

### EtherNet/IP Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    CIP Protocol Layers                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   ┌──────────────────────────────────────────────────────────────┐  │
│   │                 Application Layer                            │  │
│   │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐        │  │
│   │  │ Assembly │ │Parameter │ │ Message  │ │ Safety   │        │  │
│   │  │  Object  │ │  Object  │ │  Router  │ │ Object   │        │  │
│   │  └──────────┘ └──────────┘ └──────────┘ └──────────┘        │  │
│   └──────────────────────────────────────────────────────────────┘  │
│                              │                                       │
│   ┌──────────────────────────┴───────────────────────────────────┐  │
│   │            Common Industrial Protocol (CIP)                  │  │
│   │        Object-oriented messaging, routing                    │  │
│   └──────────────────────────────────────────────────────────────┘  │
│                              │                                       │
│   ┌──────────────────────────┴───────────────────────────────────┐  │
│   │              Network Adaptations                             │  │
│   │  ┌────────────┐ ┌────────────┐ ┌────────────┐               │  │
│   │  │ EtherNet/IP│ │ DeviceNet  │ │ ControlNet │               │  │
│   │  │ (Ethernet) │ │ (CAN-based)│ │ (Coax)     │               │  │
│   │  └────────────┘ └────────────┘ └────────────┘               │  │
│   └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### CIP Security

Introduced in 2015, provides:

| Feature | Description |
|---------|-------------|
| **EtherNet/IP Integrity** | HMAC protection for implicit I/O |
| **EtherNet/IP Confidentiality** | AES encryption for I/O |
| **CIP Security Objects** | Key management, certificates |
| **TLS/DTLS** | Secure explicit messaging |

## PROFINET

### Overview

Siemens' industrial Ethernet protocol:

| Attribute | Value |
|-----------|-------|
| **Year Introduced** | 2003 |
| **Organization** | PROFIBUS & PROFINET International (PI) |
| **Classes** | Conformance Classes A, B, C |
| **Security** | PROFINET Security (2020+) |

### PROFINET Classes

| Class | Real-Time | Use Case |
|-------|-----------|----------|
| **CC-A** | None (TCP/IP) | Non-time-critical |
| **CC-B** | RT (soft real-time) | Typical automation |
| **CC-C** | IRT (isochronous) | Motion control |

### PROFINET Security

New security features (v2.4+):

| Feature | Description |
|---------|-------------|
| **Integrity Class** | CRC-32 or AES-128-CMAC |
| **Confidentiality** | Optional AES-128-GCM |
| **Authentication** | Certificate-based |
| **Key Management** | Centralized security controller |

## IEC 61850

### Overview

Power systems communication standard:

| Attribute | Value |
|-----------|-------|
| **Year Introduced** | 2003 |
| **Organization** | IEC TC 57 |
| **Use Case** | Substation automation, protection |
| **Security** | IEC 62351 (overlay) |

### IEC 61850 Communication Services

| Service | Protocol | Purpose |
|---------|----------|---------|
| **MMS** | TCP/IP | Configuration, read/write |
| **GOOSE** | Layer 2 | Fast event distribution |
| **Sampled Values** | Layer 2 | Raw measurement streaming |
| **Time Sync** | SNTP/PTP | Time synchronization |

### GOOSE (Generic Object Oriented Substation Event)

```
┌─────────────────────────────────────────────────────────────────────┐
│                    GOOSE Communication                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Publisher                          Subscribers                     │
│   ┌──────────┐                      ┌──────────┐                     │
│   │Protection│───── Multicast ─────►│Protection│                     │
│   │  Relay   │      Ethernet        │  Relay   │                     │
│   │  (IED)   │          │           │  (IED)   │                     │
│   └──────────┘          │           └──────────┘                     │
│                         │           ┌──────────┐                     │
│                         └──────────►│  Bay     │                     │
│                                     │Controller│                     │
│                                     └──────────┘                     │
│                                                                      │
│   Characteristics:                                                   │
│   • Layer 2 multicast (no IP)                                        │
│   • Sub-millisecond latency                                          │
│   • Retransmission with increasing interval                          │
│   • Used for protection signals                                      │
│                                                                      │
│   Security Challenge:                                                │
│   • No encryption (must be fast)                                     │
│   • Layer 2 = hard to firewall                                       │
│   • Spoofing could cause incorrect trips                             │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## S7comm (Siemens)

### Overview

Siemens proprietary PLC protocol:

| Attribute | Value |
|-----------|-------|
| **Versions** | S7comm (classic), S7comm-Plus (S7-1500) |
| **Transport** | ISO-TSAP over TCP (port 102) |
| **Security** | S7comm-Plus has optional encryption |

### S7comm Security Concerns

```
┌─────────────────────────────────────────────────────────────────────┐
│                    S7comm Vulnerabilities                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Classic S7comm (S7-300/400):                                       │
│   • No authentication                                                │
│   • No encryption                                                    │
│   • Password protection is weak (replay possible)                    │
│   • Read/write memory directly                                       │
│   • Start/stop CPU                                                   │
│                                                                      │
│   S7comm-Plus (S7-1200/1500):                                        │
│   • Anti-replay mechanism                                            │
│   • Optional encryption                                              │
│   • Better, but not fully secure                                     │
│                                                                      │
│   Notable Attacks:                                                   │
│   • Stuxnet used S7comm to target PLCs                               │
│   • Multiple Siemens CVEs related to S7comm                          │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Serial Communications

### RS-232/RS-485

Still prevalent in industrial environments:

| Standard | Wires | Distance | Nodes | Use Case |
|----------|-------|----------|-------|----------|
| **RS-232** | 3-9 | 15m | Point-to-point | Serial console |
| **RS-422** | 4 | 1200m | Point-to-point | Long distance |
| **RS-485** | 2-4 | 1200m | Up to 32 | Multidrop bus |

### Serial Protocol Considerations

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Serial Communication Security                     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Advantages (from security perspective):                            │
│   • No IP = not directly internet-accessible                         │
│   • Physical access required                                         │
│   • Not easily scannable from network                                │
│                                                                      │
│   Disadvantages:                                                     │
│   • No encryption                                                    │
│   • No authentication                                                │
│   • Physical tap = full access                                       │
│   • Often converted to TCP via terminal servers                      │
│                                                                      │
│   Serial-to-Ethernet Converters:                                     │
│   ┌───────────┐    ┌──────────────┐    ┌───────────┐                │
│   │  Legacy   │───►│   Serial     │───►│  Network  │                │
│   │   PLC     │RS485│  Server     │TCP │  Client   │                │
│   │  (secure?)│    │  (exposed!) │    │           │                │
│   └───────────┘    └──────────────┘    └───────────┘                │
│                                                                      │
│   Serial servers often expose raw protocol over TCP                  │
│   Authentication? Usually none.                                      │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Protocol Security Comparison

| Protocol | Authentication | Encryption | Integrity | Assessment |
|----------|---------------|------------|-----------|------------|
| Modbus | None | None | None | Insecure |
| DNP3 | Optional (SA) | None | Optional | Improving |
| OPC UA | Yes | Yes | Yes | Secure by design |
| EtherNet/IP | Optional (CIP Security) | Optional | Optional | Improving |
| PROFINET | Optional (2020+) | Optional | Optional | Improving |
| IEC 61850 | Optional (62351) | Optional | Optional | Context-dependent |
| S7comm | Weak/None | Optional | None | Insecure |
| BACnet | Optional (SC) | Optional | Optional | Improving |

## Securing Insecure Protocols

When protocols lack security, use compensating controls:

### Network Segmentation

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Segmentation for Legacy Protocols                 │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Enterprise Network                                                 │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │                          IT Zone                            │   │
│   └──────────────────────────────┬──────────────────────────────┘   │
│                                  │                                   │
│                           ┌──────┴──────┐                            │
│                           │  Firewall   │                            │
│                           │ (Allow only │                            │
│                           │ OPC UA/443) │                            │
│                           └──────┬──────┘                            │
│                                  │                                   │
│   ┌──────────────────────────────┴──────────────────────────────┐   │
│   │                         OT DMZ                              │   │
│   │  ┌───────────┐    ┌───────────┐    ┌───────────┐           │   │
│   │  │ Historian │    │  OPC UA   │    │   Jump    │           │   │
│   │  │  Mirror   │    │  Gateway  │    │  Server   │           │   │
│   │  └───────────┘    └───────────┘    └───────────┘           │   │
│   └──────────────────────────────┬──────────────────────────────┘   │
│                                  │                                   │
│                           ┌──────┴──────┐                            │
│                           │  Firewall   │                            │
│                           │ (Strict     │                            │
│                           │  rules)     │                            │
│                           └──────┬──────┘                            │
│                                  │                                   │
│   ┌──────────────────────────────┴──────────────────────────────┐   │
│   │                      Control Zone                           │   │
│   │  ┌───────────┐    ┌───────────┐    ┌───────────┐           │   │
│   │  │   PLC     │    │    HMI    │    │  Legacy   │           │   │
│   │  │ (Modbus)  │    │           │    │   DCS     │           │   │
│   │  └───────────┘    └───────────┘    └───────────┘           │   │
│   └─────────────────────────────────────────────────────────────┘   │
│                                                                      │
│   Modbus stays in Control Zone - never crosses firewall directly     │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Protocol-Aware Firewalls

Deep packet inspection for industrial protocols:

| Feature | Benefit |
|---------|---------|
| **Function code filtering** | Block write commands from untrusted sources |
| **Register range restrictions** | Only allow access to specific addresses |
| **Rate limiting** | Prevent DoS attacks |
| **Anomaly detection** | Alert on unusual traffic patterns |

### Secure Tunneling

```
┌─────────────────────────────────────────────────────────────────────┐
│                    VPN Wrapping for Legacy Protocols                 │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Site A                            WAN                    Site B    │
│   ┌──────────┐    ┌──────────┐              ┌──────────┐   ┌──────┐ │
│   │  SCADA   │───►│  VPN     │══════════════│  VPN     │──►│ RTU  │ │
│   │  Master  │    │ Gateway  │  Encrypted   │ Gateway  │   │      │ │
│   │          │    │          │   Tunnel     │          │   │      │ │
│   └──────────┘    └──────────┘              └──────────┘   └──────┘ │
│                                                                      │
│   DNP3 traffic inside IPsec/TLS tunnel                               │
│   Provides: Encryption, authentication, integrity                    │
│   DNP3 protocol itself unchanged                                     │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Protocol Analysis Tools

| Tool | Purpose | Protocols |
|------|---------|-----------|
| **Wireshark** | Packet capture/analysis | All (with dissectors) |
| **Modscan** | Modbus master simulator | Modbus TCP/RTU |
| **Triangle MicroWorks** | DNP3 testing | DNP3 |
| **Prosys OPC UA Client** | OPC UA browsing | OPC UA |
| **Siemens SIMATIC** | S7 tools | S7comm |
| **Nmap + scripts** | Protocol scanning | Various |

## Key Takeaways

1. **Most legacy protocols have no security** - design compensating controls
2. **OPC UA is the future** - secure by design, use when possible
3. **Network segmentation is critical** - isolate insecure protocols
4. **Protocol-aware inspection** - use DPI firewalls for industrial traffic
5. **Serial to IP conversion** - major security risk, segment carefully
6. **Vendor lock-in is real** - each vendor ecosystem has different protocols
7. **Real-time requirements** - security cannot add unacceptable latency

## Study Questions

1. Why does Modbus use a live zero (4 mA) for its analog signal range?

2. What is the security advantage of DNP3's unsolicited response mode?

3. Why can't you simply firewall GOOSE traffic in a substation?

4. What happens if you enable OPC UA encryption on a system not designed for it?

5. How would you secure a legacy Modbus RTU device that cannot be upgraded?

## Practical Exercises

1. Set up Wireshark and capture Modbus TCP traffic
2. Identify function codes and register addresses
3. Use a Modbus simulator to generate traffic
4. Practice reading protocol documentation

## Next Steps

Continue to [05-ot-network-architecture.md](05-ot-network-architecture.md) to learn how to design secure OT networks.

## References

- Modbus Organization: https://modbus.org/specs.php
- DNP3 Users Group: https://www.dnp.org/
- OPC Foundation: https://opcfoundation.org/
- ODVA (CIP/EtherNet/IP): https://www.odva.org/
- PROFIBUS/PROFINET International: https://www.profibus.com/
- IEC 61850 Information: https://iec61850.tissue-db.com/
