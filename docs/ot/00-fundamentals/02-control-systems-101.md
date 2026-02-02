# Control Systems 101

Understanding the hardware and software that runs industrial processes.

## The Control System Hierarchy

Industrial control systems are organized in layers, from field devices to enterprise systems:

```
┌──────────────────────────────────────────────────────────────────────┐
│                    Purdue Model / ISA-95                             │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Level 5   ┌─────────────────────────────────────────────────────┐  │
│   Enterprise│  ERP, Business Systems, Corporate Network           │  │
│             └─────────────────────────────────────────────────────┘  │
│                                    │                                 │
│   ════════════════════════════════════════════════════════════════   │
│                          IT/OT Boundary                              │
│   ════════════════════════════════════════════════════════════════   │
│                                    │                                 │
│   Level 4   ┌─────────────────────────────────────────────────────┐  │
│   Site      │  Site Business Planning, Logistics                  │  │
│   Business  └─────────────────────────────────────────────────────┘  │
│                                    │                                 │
│   Level 3.5 ┌─────────────────────────────────────────────────────┐  │
│   DMZ       │  Historian Mirror, Jump Server, Patch Server        │  │
│             └─────────────────────────────────────────────────────┘  │
│                                    │                                 │
│   Level 3   ┌─────────────────────────────────────────────────────┐  │
│   Operations│  SCADA Server, Historian, Engineering Workstation   │  │
│   Management└─────────────────────────────────────────────────────┘  │
│                                    │                                 │
│   Level 2   ┌─────────────────────────────────────────────────────┐  │
│   Supervisory│  HMI, OPC Server, Local SCADA                      │  │
│   Control   └─────────────────────────────────────────────────────┘  │
│                                    │                                 │
│   Level 1   ┌─────────────────────────────────────────────────────┐  │
│   Basic     │  PLC, DCS Controller, RTU, Safety Controller        │  │
│   Control   └─────────────────────────────────────────────────────┘  │
│                                    │                                 │
│   Level 0   ┌─────────────────────────────────────────────────────┐  │
│   Process   │  Sensors, Actuators, Valves, Motors, Drives         │  │
│             └─────────────────────────────────────────────────────┘  │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

## Programmable Logic Controllers (PLCs)

### What is a PLC?

A PLC is a ruggedized computer designed to control industrial processes:

```
┌──────────────────────────────────────────────────────────────────────┐
│                    PLC Architecture                                  │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   ┌────────────────────────────────────────────────────────────┐     │
│   │                         PLC Rack                           │     │
│   │                                                            │     │
│   │  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐    │     │
│   │  │ Power  │ │  CPU   │ │  DI    │ │  DO    │ │  AI    │    │     │
│   │  │ Supply │ │        │ │ Module │ │ Module │ │ Module │    │     │
│   │  │        │ │        │ │        │ │        │ │        │    │     │
│   │  │  24V   │ │ Program│ │ 16 ch  │ │ 16 ch  │ │ 8 ch   │    │     │
│   │  │  DC    │ │ Memory │ │ 24VDC  │ │ 24VDC  │ │ 4-20mA │    │     │
│   │  └────────┘ └───┬────┘ └───┬────┘ └───┬────┘ └───┬────┘    │     │
│   │                 │          │          │          │         │     │
│   │                 └──────────┴──────────┴──────────┘         │     │
│   │                         Backplane Bus                      │     │
│   └────────────────────────────────────────────────────────────┘     │
│                                                                      │
│   DI = Digital Input (On/Off sensors)                                │
│   DO = Digital Output (On/Off control)                               │
│   AI = Analog Input (Variable sensors like 4-20mA)                   │
│   AO = Analog Output (Variable control like 0-10V)                   │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

### PLC Scan Cycle

PLCs execute code in a continuous **scan cycle**:

```
┌──────────────────────────────────────────────────────────────────────┐
│                    PLC Scan Cycle                                    │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│                    ┌──────────────────┐                              │
│            ┌──────►│  1. Read Inputs  │                              │
│            │       │   (DI, AI)       │                              │
│            │       └────────┬─────────┘                              │
│            │                │                                        │
│            │                ▼                                        │
│            │       ┌──────────────────┐                              │
│            │       │ 2. Execute Logic │                              │
│            │       │   (Program)      │                              │
│            │       └────────┬─────────┘                              │
│            │                │                                        │
│            │                ▼                                        │
│            │       ┌──────────────────┐                              │
│            │       │ 3. Write Outputs │                              │
│            │       │   (DO, AO)       │                              │
│            │       └────────┬─────────┘                              │
│            │                │                                        │
│            │                ▼                                        │
│            │       ┌──────────────────┐                              │
│            │       │ 4. Communications│                              │
│            │       │   (Network I/O)  │                              │
│            │       └────────┬─────────┘                              │
│            │                │                                        │
│            └────────────────┘                                        │
│                                                                      │
│   Typical scan time: 5-50 milliseconds                               │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

**Security implication**: Attack code injected into PLC program executes every scan cycle.

### PLC Operating Modes

| Mode | Description | Security Relevance |
|------|-------------|--------------------|
| **RUN** | Normal operation, executing program | Attacks modify running logic |
| **PROGRAM** | Accepts program changes | Upload/download possible |
| **REMOTE** | Mode changeable via network | Remote takeover possible |
| **STOP** | Program not executing | Process stops, outputs off |

### PLC Programming Languages

IEC 61131-3 defines five standard languages:

| Language | Type | Use Case |
|----------|------|----------|
| **Ladder Logic (LD)** | Graphical | Discrete control, electricians |
| **Function Block (FBD)** | Graphical | Process control, data flow |
| **Structured Text (ST)** | Textual | Complex calculations, IT-like |
| **Instruction List (IL)** | Textual | Low-level, assembly-like |
| **Sequential Function Chart (SFC)** | Graphical | State machines, batch |

**Ladder Logic example** (most common):

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Ladder Logic Example                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Start a pump when level is low AND start button pressed,           │
│   stop when level is high OR stop button pressed:                    │
│                                                                      │
│   Rung 1: Start Logic                                                │
│   ──┤ ├─────────┤ ├─────────┤/├──────────────────────────( )──       │
│     Low_Level   Start_PB    Running                      Pump_On     │
│                                                                      │
│   Rung 2: Seal-in (Keep running)                                     │
│   ──┤ ├──────────────────────┤/├──────────────────────────( )──      │
│     Pump_On                  Stop_PB                     Pump_On     │
│                                                                      │
│   Rung 3: High Level Stop                                            │
│   ──┤ ├─────────────────────────────────────────────────(RST)──      │
│     High_Level                                          Pump_On      │
│                                                                      │
│   Symbols:                                                           │
│   ──┤ ├── = Normally Open contact (true when signal is ON)           │
│   ──┤/├── = Normally Closed contact (true when signal is OFF)        │
│   ──( )── = Output coil                                              │
│   ─(RST)─ = Reset coil                                               │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Major PLC Vendors

| Vendor | Common Families | Protocol |
|--------|-----------------|----------|
| **Siemens** | S7-300, S7-400, S7-1200, S7-1500 | S7comm, PROFINET |
| **Allen-Bradley (Rockwell)** | ControlLogix, CompactLogix | EtherNet/IP, CIP |
| **Schneider Electric** | Modicon M340, M580 | Modbus, EtherNet/IP |
| **ABB** | AC500, AC800M | PROFINET, CC-Link |
| **Mitsubishi** | MELSEC iQ-R, FX5 | CC-Link, SLMP |
| **Omron** | NJ/NX Series, CP1 | EtherNet/IP, EtherCAT |

## Distributed Control Systems (DCS)

### DCS vs PLC

```
┌─────────────────────────────────────────────────────────────────────┐
│                    DCS vs PLC Comparison                             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Characteristic        PLC                    DCS                   │
│   ─────────────────────────────────────────────────────────────────  │
│   Architecture          Standalone             Distributed           │
│   Typical Use           Discrete mfg           Process control       │
│   Scan Time             Fast (ms)              Slower (100ms-1s)     │
│   I/O Count             10s to 100s            1000s to 10000s       │
│   Integration           Add-on                 Built-in              │
│   Operator Interface    Separate HMI           Integrated consoles   │
│   Redundancy            Optional               Standard              │
│   Programming           Ladder, FBD            Function blocks       │
│   Cost                  Lower                  Higher                │
│   Vendors               Many                   Few (ABB, Emerson,    │
│                                                Honeywell, Yokogawa)  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### DCS Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Typical DCS Architecture                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│                    ┌─────────────────────┐                           │
│                    │   Engineering       │                           │
│                    │   Workstation       │                           │
│                    └──────────┬──────────┘                           │
│                               │                                      │
│   ┌───────────┬───────────────┼───────────────┬───────────┐          │
│   │           │               │               │           │          │
│   ▼           ▼               ▼               ▼           ▼          │
│ ┌─────┐   ┌─────┐       ┌──────────┐     ┌─────┐     ┌─────┐        │
│ │ Op  │   │ Op  │       │ History  │     │ Op  │     │ Op  │        │
│ │Stn 1│   │Stn 2│       │ Server   │     │Stn 3│     │Stn 4│        │
│ └──┬──┘   └──┬──┘       └────┬─────┘     └──┬──┘     └──┬──┘        │
│    │         │               │              │           │            │
│    └─────────┴───────┬───────┴──────┬───────┴───────────┘            │
│                      │              │                                │
│              ════════════════════════════════                        │
│                    Control Network                                   │
│              ════════════════════════════════                        │
│                      │              │                                │
│              ┌───────┴───┐    ┌─────┴─────┐                          │
│              │Controller │    │Controller │                          │
│              │    #1     │    │    #2     │                          │
│              │(Redundant)│    │(Redundant)│                          │
│              └─────┬─────┘    └─────┬─────┘                          │
│                    │                │                                │
│              ══════════════════════════════                          │
│                    I/O Network                                       │
│              ══════════════════════════════                          │
│                    │                │                                │
│              ┌─────┴───┐      ┌─────┴───┐                            │
│              │ Remote  │      │ Remote  │                            │
│              │ I/O #1  │      │ I/O #2  │                            │
│              └─────────┘      └─────────┘                            │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Major DCS Vendors

| Vendor | Platform | Industries |
|--------|----------|------------|
| **Emerson** | DeltaV, Ovation | Process, Power |
| **Honeywell** | Experion PKS | Refining, Chemicals |
| **ABB** | 800xA | Process, Mining |
| **Yokogawa** | CENTUM VP | Process, Pharma |
| **Siemens** | PCS 7 | Process, Pharma |
| **Schneider** | Foxboro, Triconex | Process, Safety |

## Remote Terminal Units (RTUs)

### What is an RTU?

RTUs are ruggedized data collection devices for remote, unmanned sites:

```
┌─────────────────────────────────────────────────────────────────────┐
│                    RTU at Remote Site                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Remote Site (e.g., pump station)                                   │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │                                                             │   │
│   │  ┌─────────┐   ┌─────────┐   ┌─────────┐   ┌─────────┐     │   │
│   │  │  Flow   │   │ Pressure│   │  Level  │   │  Pump   │     │   │
│   │  │ Sensor  │   │ Sensor  │   │ Sensor  │   │ Motor   │     │   │
│   │  └────┬────┘   └────┬────┘   └────┬────┘   └────┬────┘     │   │
│   │       │             │             │             │           │   │
│   │       └─────────────┴──────┬──────┴─────────────┘           │   │
│   │                            │                                │   │
│   │                     ┌──────┴──────┐                         │   │
│   │                     │     RTU     │                         │   │
│   │                     │  • Data acq │                         │   │
│   │                     │  • Local    │                         │   │
│   │                     │    control  │                         │   │
│   │                     │  • Comms    │                         │   │
│   │                     └──────┬──────┘                         │   │
│   │                            │                                │   │
│   └────────────────────────────┼────────────────────────────────┘   │
│                                │                                    │
│                      Cellular/Radio/Satellite                       │
│                                │                                    │
│                                ▼                                    │
│                    ┌─────────────────────┐                          │
│                    │   Central SCADA     │                          │
│                    │   Control Center    │                          │
│                    └─────────────────────┘                          │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### RTU vs PLC

| Feature | RTU | PLC |
|---------|-----|-----|
| **Environment** | Outdoor, extreme | Indoor, controlled |
| **Communication** | Long distance, unreliable | Local network |
| **Power** | Battery, solar backup | Grid power |
| **I/O** | Fewer points | Many points |
| **Primary Function** | Data collection | Process control |
| **Autonomy** | Operates standalone | Requires network |

## Human-Machine Interface (HMI)

### What is an HMI?

HMIs provide operator visualization and control:

```
┌─────────────────────────────────────────────────────────────────────┐
│                    HMI Screen Example                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  TANK FARM OVERVIEW                    [Alarms: 2]  14:32:05  │  │
│  ├───────────────────────────────────────────────────────────────┤  │
│  │                                                               │  │
│  │      Tank 101        Tank 102        Tank 103                 │  │
│  │     ┌───────┐       ┌───────┐       ┌───────┐                 │  │
│  │     │███████│       │███████│       │██     │                 │  │
│  │     │███████│       │███    │       │       │                 │  │
│  │     │███████│       │       │       │       │                 │  │
│  │     └───────┘       └───────┘       └───────┘                 │  │
│  │       85.2%           43.7%           12.1%                   │  │
│  │                                       [LOW]                   │  │
│  │                                                               │  │
│  │  ─────────────────────────────────────────────────────────    │  │
│  │  Pump P-101     Pump P-102     Pump P-103                     │  │
│  │  [RUNNING]      [STOPPED]      [FAULT]                        │  │
│  │   1250 GPM        0 GPM          ---                          │  │
│  │                                                               │  │
│  │  [START P-102]  [ACKNOWLEDGE ALARMS]  [SYSTEM STATUS]         │  │
│  │                                                               │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  HMI Functions:                                                      │
│  • Real-time process visualization                                   │
│  • Operator commands (start/stop/setpoint)                           │
│  • Alarm management                                                  │
│  • Trend displays                                                    │
│  • Report generation                                                 │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### HMI Security Concerns

| Concern | Description |
|---------|-------------|
| **Shared workstations** | Multiple operators, one login |
| **No authentication** | Direct physical access |
| **Screen capture** | Process data visible on screen |
| **USB ports** | Removable media for updates |
| **Remote access** | VPN/RDP for off-site support |

### Major HMI Platforms

| Vendor | Platform | Notes |
|--------|----------|-------|
| **Siemens** | WinCC | Integrates with S7 PLCs |
| **Rockwell** | FactoryTalk View | Allen-Bradley ecosystem |
| **GE** | iFIX, CIMPLICITY | Broad protocol support |
| **Inductive Automation** | Ignition | Java-based, modern |
| **AVEVA** | InTouch | Historian integration |
| **Schneider** | Vijeo Citect | Mining, utilities |

## SCADA Systems

### What is SCADA?

**Supervisory Control and Data Acquisition** - coordinates distributed control systems:

```
┌─────────────────────────────────────────────────────────────────────┐
│                    SCADA Architecture                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│                       SCADA Control Center                           │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │                                                             │   │
│   │   ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐       │   │
│   │   │ Operator│  │ Operator│  │ Engineer│  │ History │       │   │
│   │   │ Console │  │ Console │  │ Workst  │  │ Server  │       │   │
│   │   └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘       │   │
│   │        └────────────┴────────────┴────────────┘             │   │
│   │                          │                                  │   │
│   │                   ┌──────┴──────┐                           │   │
│   │                   │   SCADA     │                           │   │
│   │                   │   Server    │                           │   │
│   │                   │  (Primary/  │                           │   │
│   │                   │   Backup)   │                           │   │
│   │                   └──────┬──────┘                           │   │
│   │                          │                                  │   │
│   └──────────────────────────┼──────────────────────────────────┘   │
│                              │                                      │
│              ┌───────────────┼───────────────┐                      │
│              │               │               │                      │
│           Cellular        Radio          Satellite                  │
│              │               │               │                      │
│              ▼               ▼               ▼                      │
│   ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │
│   │  Substation  │  │ Pump Station │  │   Well Site  │              │
│   │    RTU/IED   │  │     RTU      │  │     RTU      │              │
│   └──────────────┘  └──────────────┘  └──────────────┘              │
│                                                                      │
│   SCADA Functions:                                                   │
│   • Aggregate data from remote sites                                 │
│   • Centralized monitoring and control                               │
│   • Alarm management                                                 │
│   • Historical data collection                                       │
│   • Report generation                                                │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### SCADA vs DCS vs PLC

| System | Scope | Control Speed | Geographic Area |
|--------|-------|---------------|-----------------|
| **PLC** | Single machine/process | Milliseconds | Single location |
| **DCS** | Entire plant | 100ms - seconds | Single site |
| **SCADA** | Distributed sites | Seconds - minutes | Wide area |

## Historians

### What is a Historian?

Specialized time-series database for process data:

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Historian Architecture                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Process Data Sources                                               │
│   ┌──────┐ ┌──────┐ ┌──────┐                                         │
│   │ PLC  │ │ DCS  │ │ RTU  │                                         │
│   └──┬───┘ └──┬───┘ └──┬───┘                                         │
│      │        │        │                                             │
│      └────────┴────────┴───────────┐                                 │
│                                    │                                 │
│                             ┌──────┴──────┐                          │
│                             │  Historian  │                          │
│                             │   Server    │                          │
│                             │             │                          │
│                             │ • Collect   │                          │
│                             │ • Compress  │                          │
│                             │ • Store     │                          │
│                             │ • Retrieve  │                          │
│                             └──────┬──────┘                          │
│                                    │                                 │
│      ┌────────────┬────────────────┼────────────────┐                │
│      │            │                │                │                │
│      ▼            ▼                ▼                ▼                │
│  ┌───────┐   ┌───────┐        ┌───────┐       ┌───────┐              │
│  │ Trend │   │Report │        │  MES  │       │ Analytics│            │
│  │Display│   │  Gen  │        │System │       │ Platform│            │
│  └───────┘   └───────┘        └───────┘       └───────┘              │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Major Historian Platforms

| Vendor | Product | Notes |
|--------|---------|-------|
| **OSIsoft** | PI System | Industry leader, now AVEVA |
| **GE** | Proficy Historian | GE ecosystem |
| **Honeywell** | Uniformance PHD | Experion integration |
| **Rockwell** | FactoryTalk Historian | A-B integration |
| **InfluxData** | InfluxDB | Open source, IT-style |
| **Canary Labs** | Canary | Affordable, fast |

### Security Relevance

- Historians contain operational data - valuable for reconnaissance
- Often placed in DMZ for IT access
- Can be used to detect anomalies (baseline comparison)
- Historical trends reveal process patterns attackers could exploit

## Engineering Workstations

### What is an Engineering Workstation?

Computers used to program, configure, and maintain control systems:

| Function | Tools | Risk |
|----------|-------|------|
| **PLC Programming** | Studio 5000, TIA Portal | Logic modification |
| **HMI Development** | FactoryTalk, WinCC | Screen manipulation |
| **DCS Configuration** | DeltaV Explorer, PKS | Controller changes |
| **Network Config** | Switch/router management | Network manipulation |

### Security Concerns

```
┌─────────────────────────────────────────────────────────────────────┐
│           Engineering Workstation Risks                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │                                                             │   │
│   │   HIGH RISK: Engineering workstations have "keys to        │   │
│   │   the kingdom" - direct access to modify control logic     │   │
│   │                                                             │   │
│   │   Common Issues:                                            │   │
│   │   • Shared among multiple engineers                         │   │
│   │   • USB ports enabled for project transfer                  │   │
│   │   • Internet access for software updates                    │   │
│   │   • Running outdated OS (vendor support)                    │   │
│   │   • Portable laptops that travel between sites             │   │
│   │   • Dual-homed (IT and OT networks)                         │   │
│   │                                                             │   │
│   │   Protection Requirements:                                  │   │
│   │   • Strong authentication (MFA)                             │   │
│   │   • Session recording                                       │   │
│   │   • Change control workflows                                │   │
│   │   • Network segmentation                                    │   │
│   │   • Application whitelisting                                │   │
│   │                                                             │   │
│   └─────────────────────────────────────────────────────────────┘   │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Industrial Network Equipment

### Industrial Switches

Different from IT switches:

| Feature | IT Switch | Industrial Switch |
|---------|-----------|-------------------|
| **Temperature** | 0-40°C | -40 to +75°C |
| **Mounting** | Rack | DIN rail |
| **Power** | AC | 24VDC redundant |
| **Certification** | None | Class I Div 2, ATEX |
| **MTBF** | 5-10 years | 20+ years |
| **Protocols** | Standard | Modbus, PROFINET |

### Industrial Firewalls

Purpose-built for OT:

| Vendor | Products | Notes |
|--------|----------|-------|
| **Fortinet** | FortiGate Rugged | OT protocol inspection |
| **Palo Alto** | PA-220R | Industrial form factor |
| **Cisco** | IE series | ISA/IEC 62443 certified |
| **Tofino (Belden)** | Tofino Firewall | DPI for industrial protocols |
| **Claroty** | SRA | Secure Remote Access |

### Data Diodes

One-way communication devices:

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Data Diode Operation                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   OT Network                               IT Network                │
│   (Protected)                              (Lower Trust)             │
│                                                                      │
│   ┌──────────┐    ┌──────────────┐    ┌──────────┐                  │
│   │ Control  │───►│  Data Diode  │───►│ Business │                  │
│   │ System   │    │              │    │ Systems  │                  │
│   └──────────┘    │  TX ──────►  │    └──────────┘                  │
│                   │              │                                   │
│   Data flows      │  ◄── None    │    No return path                │
│   OUT only        │              │    physically impossible          │
│                   └──────────────┘                                   │
│                                                                      │
│   Hardware-enforced one-way communication                            │
│   Attackers cannot send data back to OT network                      │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Protocol Converters

Bridge incompatible systems:

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Protocol Converter Example                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Legacy System                           Modern System              │
│   (Modbus RTU)                           (EtherNet/IP)              │
│                                                                      │
│   ┌──────────┐    ┌──────────────┐    ┌──────────┐                  │
│   │  Old PLC │    │   Protocol   │    │  New PLC │                  │
│   │  (1990s) │◄──►│  Converter   │◄──►│  (2020s) │                  │
│   └──────────┘    └──────────────┘    └──────────┘                  │
│        │                                     │                       │
│   RS-485 Serial                         Ethernet                    │
│   Modbus RTU                           EtherNet/IP                  │
│                                                                      │
│   Common Conversions:                                                │
│   • Modbus RTU ◄──► Modbus TCP                                       │
│   • DNP3 Serial ◄──► DNP3 TCP                                        │
│   • PROFIBUS ◄──► PROFINET                                           │
│   • OPC DA ◄──► OPC UA                                               │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## System Life Cycles

| Phase | IT Duration | OT Duration | Security Implication |
|-------|-------------|-------------|---------------------|
| **Design** | Months | Years | Security requirements set |
| **Deployment** | Days-weeks | Months | Configuration locked |
| **Operations** | 3-5 years | 15-30 years | Long vulnerability window |
| **End of Life** | Replaced | Kept running | Legacy security gaps |

## Key Takeaways

1. **PLCs are the workhorses** - understand the scan cycle and programming
2. **DCS controls large processes** - integrated, redundant, expensive
3. **SCADA coordinates distribution** - wide area, unreliable communications
4. **Historians store everything** - valuable target for reconnaissance
5. **Engineering workstations are high-value targets** - access to modify logic
6. **Industrial networks are different** - ruggedized, deterministic, long-lived

## Study Questions

1. What is the difference between a PLC scan time and a DCS controller cycle time?

2. Why might an RTU continue operating when communication to the central SCADA is lost?

3. What makes an engineering workstation a more attractive target than an HMI station?

4. Why are historians often placed in the OT DMZ rather than directly on the control network?

5. What are the security implications of a 30-year equipment life cycle?

## Hands-On Practice

1. Set up a free PLC simulator (OpenPLC, Factory I/O)
2. Program basic ladder logic
3. Connect to an HMI simulator
4. Capture and analyze Modbus traffic

## Next Steps

Continue to [03-ot-vs-it-security.md](03-ot-vs-it-security.md) to understand the fundamental mindset differences between IT and OT security.

## References

- ISA-99/IEC 62443 Industrial Automation and Control Systems Security
- NIST SP 800-82 Rev. 2 Guide to ICS Security
- IEC 61131-3 Programmable Controllers Programming Languages
- Vendor documentation for specific platforms
