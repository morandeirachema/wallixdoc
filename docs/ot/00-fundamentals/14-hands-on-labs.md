# Hands-On OT Security Labs

Building practical skills through safe experimentation.

## Lab Safety Principles

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Lab Safety Rules                                  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   CRITICAL: Never test on production systems without authorization   │
│                                                                      │
│   Lab Environment Rules:                                             │
│   ─────────────────────                                              │
│   1. Use isolated networks (no connection to production)             │
│   2. Use VMs or dedicated hardware                                   │
│   3. Document all activities                                         │
│   4. Keep tools updated                                              │
│   5. Learn safely, break things on purpose                           │
│                                                                      │
│   Legal Considerations:                                              │
│   ─────────────────────                                              │
│   • Only test systems you own or have permission to test             │
│   • Understand local computer crime laws                             │
│   • Don't connect to internet without isolation                      │
│   • Don't scan external networks                                     │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Home Lab Options

### Basic Lab (Minimal Cost)

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Basic OT Security Lab (~$200)                     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Hardware:                                                          │
│   • Any PC/laptop with 8GB+ RAM (existing)                           │
│   • Raspberry Pi 4 ($50) - optional but useful                       │
│   • Small network switch ($20)                                       │
│   • Ethernet cables                                                  │
│                                                                      │
│   Software (Free):                                                   │
│   • VirtualBox or VMware Workstation Player                          │
│   • OpenPLC (open source PLC)                                        │
│   • ScadaBR (open source SCADA)                                      │
│   • ModbusPal (Modbus simulator)                                     │
│   • Wireshark                                                        │
│   • Kali Linux                                                       │
│                                                                      │
│   Architecture:                                                      │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │  Host PC                                                    │   │
│   │  ┌───────────────────────────────────────────────────────┐  │   │
│   │  │               VirtualBox                              │  │   │
│   │  │  ┌─────────┐  ┌─────────┐  ┌─────────┐              │  │   │
│   │  │  │ OpenPLC │  │ScadaBR  │  │  Kali   │              │  │   │
│   │  │  │  VM     │  │   VM    │  │  Linux  │              │  │   │
│   │  │  └────┬────┘  └────┬────┘  └────┬────┘              │  │   │
│   │  │       └────────────┴────────────┘                    │  │   │
│   │  │                Host-Only Network                      │  │   │
│   │  └───────────────────────────────────────────────────────┘  │   │
│   └─────────────────────────────────────────────────────────────┘   │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Intermediate Lab (~$500-1000)

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Intermediate OT Security Lab                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Additional Hardware:                                               │
│   • Arduino + I/O modules ($50) - simulate field devices             │
│   • USB-RS485 adapter ($15) - serial communication                   │
│   • Click PLC from Automation Direct ($80) - real PLC                │
│   • Industrial Ethernet switch ($100) - managed, VLAN capable        │
│   • Small HMI panel ($150-300) - optional                            │
│                                                                      │
│   Architecture:                                                      │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │                                                             │   │
│   │  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │   │
│   │  │   Click     │    │   OpenPLC   │    │   Arduino   │     │   │
│   │  │    PLC      │    │  (Soft PLC) │    │ (I/O Sim)   │     │   │
│   │  └──────┬──────┘    └──────┬──────┘    └──────┬──────┘     │   │
│   │         │                  │                  │             │   │
│   │         └──────────────────┴──────────────────┘             │   │
│   │                          │                                  │   │
│   │               ┌──────────┴──────────┐                       │   │
│   │               │  Industrial Switch  │                       │   │
│   │               │    (Managed)        │                       │   │
│   │               └──────────┬──────────┘                       │   │
│   │                          │                                  │   │
│   │         ┌────────────────┼────────────────┐                 │   │
│   │         │                │                │                 │   │
│   │    ┌────┴────┐    ┌──────┴──────┐  ┌──────┴──────┐         │   │
│   │    │ScadaBR/ │    │ Engineering │  │   Attack    │         │   │
│   │    │ Ignition│    │ Workstation │  │    VM       │         │   │
│   │    └─────────┘    └─────────────┘  └─────────────┘         │   │
│   │                                                             │   │
│   └─────────────────────────────────────────────────────────────┘   │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Advanced Lab ($2000+)

Components for serious practitioners:
- Siemens S7-1200 or Allen-Bradley Micro800 PLC ($500+)
- Industrial HMI panel
- Safety relay (for safety system training)
- Data diode or industrial firewall
- Multiple network segments

## Lab Exercises

### Exercise 1: Modbus Protocol Analysis

**Objective**: Capture and understand Modbus TCP traffic

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Lab 1: Modbus Analysis                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Setup:                                                             │
│   ──────                                                             │
│   1. Install ModbusPal (Java-based Modbus simulator)                 │
│   2. Configure as Modbus TCP server on port 502                      │
│   3. Add holding registers with values                               │
│   4. Start Wireshark, filter: tcp.port == 502                        │
│                                                                      │
│   Tasks:                                                             │
│   ──────                                                             │
│   1. Connect with a Modbus client (QModMaster, pymodbus)             │
│   2. Read holding registers (function code 03)                       │
│   3. Write to registers (function code 06, 16)                       │
│   4. Analyze packets in Wireshark                                    │
│                                                                      │
│   Questions to Answer:                                               │
│   ────────────────────                                               │
│   • What is the structure of a Modbus TCP request?                   │
│   • How does the response identify what was requested?               │
│   • What happens with an invalid request?                            │
│   • Can you see any authentication?                                  │
│                                                                      │
│   Code Example (Python):                                             │
│   ───────────────────────                                            │
│   from pymodbus.client import ModbusTcpClient                        │
│                                                                      │
│   client = ModbusTcpClient('localhost', port=502)                    │
│   client.connect()                                                   │
│                                                                      │
│   # Read 10 holding registers starting at address 0                  │
│   result = client.read_holding_registers(0, 10, unit=1)              │
│   print(result.registers)                                            │
│                                                                      │
│   # Write value 100 to register 5                                    │
│   client.write_register(5, 100, unit=1)                              │
│                                                                      │
│   client.close()                                                     │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Exercise 2: PLC Programming Basics

**Objective**: Understand PLC logic and potential attack vectors

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Lab 2: PLC Programming                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Setup:                                                             │
│   ──────                                                             │
│   1. Install OpenPLC Runtime on Linux VM                             │
│   2. Install OpenPLC Editor on workstation                           │
│   3. Connect to runtime via web interface (port 8080)                │
│                                                                      │
│   Task 1: Create Simple Logic                                        │
│   ─────────────────────────────                                      │
│   Create ladder logic for:                                           │
│   • Start/stop motor control                                         │
│   • Tank level monitoring                                            │
│   • Timer-based operations                                           │
│                                                                      │
│   Task 2: Understand Attack Surface                                  │
│   ─────────────────────────────────                                  │
│   • Examine web interface (authentication?)                          │
│   • Try to upload modified program                                   │
│   • Monitor Modbus while running                                     │
│   • What happens when you stop the PLC?                              │
│                                                                      │
│   Task 3: Implement Safety Logic                                     │
│   ─────────────────────────────────                                  │
│   • Add high-level interlock                                         │
│   • Add emergency stop                                               │
│   • Test bypass attempts                                             │
│                                                                      │
│   Questions:                                                         │
│   ──────────                                                         │
│   • How would an attacker modify PLC logic remotely?                 │
│   • What changes would cause physical damage?                        │
│   • How would you detect unauthorized changes?                       │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Exercise 3: Network Segmentation

**Objective**: Practice OT network design and firewall rules

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Lab 3: Network Segmentation                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Setup:                                                             │
│   ──────                                                             │
│   Create 3 VMs:                                                      │
│   • pfSense firewall (between zones)                                 │
│   • Engineering workstation (Ubuntu)                                 │
│   • PLC/SCADA simulator (OpenPLC + ScadaBR)                          │
│                                                                      │
│   Network Design:                                                    │
│   ────────────────                                                   │
│   ┌────────────────────────────────────────────────────────────┐    │
│   │  Corporate Network: 192.168.1.0/24                         │    │
│   │       │                                                    │    │
│   │   ┌───┴───┐                                                │    │
│   │   │pfSense│                                                │    │
│   │   └───┬───┘                                                │    │
│   │       │                                                    │    │
│   │  DMZ: 192.168.2.0/24                                       │    │
│   │       │                                                    │    │
│   │   ┌───┴───┐                                                │    │
│   │   │pfSense│                                                │    │
│   │   └───┬───┘                                                │    │
│   │       │                                                    │    │
│   │  OT Network: 192.168.3.0/24                                │    │
│   └────────────────────────────────────────────────────────────┘    │
│                                                                      │
│   Tasks:                                                             │
│   ──────                                                             │
│   1. Configure pfSense with 3 interfaces                             │
│   2. Create firewall rules:                                          │
│      • Allow Corporate → DMZ: HTTPS only                             │
│      • Allow DMZ → OT: Modbus (502), specific IPs                    │
│      • Deny OT → Internet                                            │
│      • Log all denied traffic                                        │
│   3. Test rules from each zone                                       │
│   4. Analyze firewall logs                                           │
│                                                                      │
│   Challenge:                                                         │
│   ──────────                                                         │
│   Try to bypass firewall rules from Corporate to OT                  │
│   Document what worked and what was blocked                          │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Exercise 4: OT Traffic Analysis

**Objective**: Baseline normal traffic and detect anomalies

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Lab 4: Traffic Baselining                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Setup:                                                             │
│   ──────                                                             │
│   1. Running OT lab (PLC + SCADA + HMI)                              │
│   2. Mirror port or network TAP                                      │
│   3. Zeek (formerly Bro) or tcpdump                                  │
│                                                                      │
│   Task 1: Capture Normal Traffic                                     │
│   ─────────────────────────────────                                  │
│   • Capture 30 minutes of "normal" operation                         │
│   • Document: What protocols? What patterns?                         │
│   • What are the normal polling intervals?                           │
│   • What register ranges are accessed?                               │
│                                                                      │
│   Task 2: Inject Anomalous Traffic                                   │
│   ─────────────────────────────────                                  │
│   From attack VM, generate:                                          │
│   • Port scan (nmap)                                                 │
│   • Unusual Modbus requests                                          │
│   • High-frequency polling                                           │
│   • Write to registers (unauthorized)                                │
│                                                                      │
│   Task 3: Detect Anomalies                                           │
│   ──────────────────────────                                         │
│   • Compare anomalous to baseline                                    │
│   • What indicators stand out?                                       │
│   • Create detection rules                                           │
│                                                                      │
│   Detection Rule Example (Snort/Suricata):                           │
│   ────────────────────────────────────────                           │
│   # Alert on Modbus write to register 100+                           │
│   alert tcp any any -> any 502 (msg:"Modbus Write High Register";    │
│     content:"|00 00|"; offset:2; depth:2;                            │
│     content:"|00 06|"; offset:7; depth:2;                            │
│     byte_test:2,>,99,8; sid:1000001;)                                │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Exercise 5: Attack and Defense

**Objective**: Understand attacks and how to defend against them

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Lab 5: Attack Simulation                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   WARNING: Only perform on YOUR OWN isolated lab!                    │
│                                                                      │
│   Attack Scenario 1: Modbus Manipulation                             │
│   ──────────────────────────────────────                             │
│   Attacker goal: Change setpoint to dangerous value                  │
│                                                                      │
│   Steps:                                                             │
│   1. Scan network for Modbus devices (nmap -sV -p 502)               │
│   2. Read current register values                                    │
│   3. Write malicious value to setpoint register                      │
│   4. Observe effect on simulated process                             │
│                                                                      │
│   Defense:                                                           │
│   • What would have prevented this?                                  │
│   • How would you detect it?                                         │
│   • Implement firewall rule to block                                 │
│                                                                      │
│   Attack Scenario 2: Replay Attack                                   │
│   ─────────────────────────────────                                  │
│   Attacker goal: Replay commands to cause repeated action            │
│                                                                      │
│   Steps:                                                             │
│   1. Capture legitimate Modbus write command                         │
│   2. Replay captured packet with tcpreplay                           │
│   3. Observe effect                                                  │
│                                                                      │
│   Defense:                                                           │
│   • Why did this work?                                               │
│   • What protocol features would prevent it?                         │
│   • How would you detect replay attacks?                             │
│                                                                      │
│   Attack Scenario 3: Man-in-the-Middle                               │
│   ────────────────────────────────────                               │
│   Attacker goal: Modify values in transit                            │
│                                                                      │
│   Steps:                                                             │
│   1. ARP spoof to get in traffic path                                │
│   2. Modify Modbus values passing through                            │
│   3. Forward modified traffic                                        │
│                                                                      │
│   Tools: ettercap, mitmproxy with custom scripts                     │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## CTF Platforms

### ICS-Focused CTFs

| Platform | Type | Notes |
|----------|------|-------|
| **GRFICSv2** | Free/Online | Virtual environment |
| **Microcorruption** | Free/Online | Embedded systems CTF |
| **SANS NetWars ICS** | Paid/Event | Competition format |
| **HTB ICS Challenges** | Paid | HackTheBox platform |

### GRFICSv2 Setup

```
┌─────────────────────────────────────────────────────────────────────┐
│                    GRFICSv2 Setup Guide                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   GRFICSv2 (Graphical Realism Framework for ICS) provides:           │
│   • Virtual chemical plant                                           │
│   • PLCs (OpenPLC based)                                             │
│   • HMI                                                              │
│   • Historian                                                        │
│   • Multiple attack scenarios                                        │
│                                                                      │
│   Requirements:                                                      │
│   • VirtualBox or VMware                                             │
│   • 16GB+ RAM recommended                                            │
│   • 50GB disk space                                                  │
│                                                                      │
│   Download:                                                          │
│   • https://github.com/Fortiphyd/GRFICSv2                            │
│                                                                      │
│   Components:                                                        │
│   • simulation_vm: Physical process simulation                       │
│   • plc_vm: OpenPLC runtime                                          │
│   • hmi_vm: ScadaBR HMI                                              │
│   • engineering_vm: PLCOpenEditor                                    │
│                                                                      │
│   Challenges Include:                                                │
│   • Reconnaissance                                                   │
│   • Process understanding                                            │
│   • Attack execution                                                 │
│   • Detection evasion                                                │
│   • Incident response                                                │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Building Muscle Memory

### Weekly Practice Routine

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Weekly Lab Practice Schedule                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Monday (1 hour): Protocol Analysis                                 │
│   • Capture traffic from your lab                                    │
│   • Identify all protocols                                           │
│   • Document one protocol in detail                                  │
│                                                                      │
│   Wednesday (1 hour): Attack Practice                                │
│   • Pick one attack technique                                        │
│   • Execute in lab                                                   │
│   • Document steps and IOCs                                          │
│                                                                      │
│   Friday (1 hour): Defense Practice                                  │
│   • Write detection rule for Wednesday's attack                      │
│   • Implement additional controls                                    │
│   • Test effectiveness                                               │
│                                                                      │
│   Weekend (2 hours): Project Work                                    │
│   • CTF challenge                                                    │
│   • Lab expansion                                                    │
│   • Documentation                                                    │
│                                                                      │
│   Track Progress:                                                    │
│   • Techniques practiced                                             │
│   • Protocols analyzed                                               │
│   • Detection rules created                                          │
│   • CTF challenges completed                                         │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Key Takeaways

1. **Build a lab** - hands-on practice is essential
2. **Start simple** - VMs and simulators before real hardware
3. **Learn protocols deeply** - understand at the packet level
4. **Practice attacks** - to understand how to defend
5. **Create detections** - turn knowledge into rules
6. **Document everything** - builds your reference library
7. **Join CTFs** - competitive learning accelerates growth

## Next Steps

Continue to [15-resources.md](15-resources.md) for comprehensive learning resources, books, and community links.
