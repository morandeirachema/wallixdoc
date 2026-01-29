# Securing Legacy Systems

Protecting systems that cannot be patched, upgraded, or replaced.

## The Legacy Reality

In OT environments, "legacy" doesn't mean "old and should be replaced" - it often means "critical and cannot be changed":

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Why Legacy Systems Persist                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   System Age in OT:                                                  │
│   ─────────────────                                                  │
│   • IT system: "It's 5 years old, time to replace"                   │
│   • OT system: "It's 25 years old, working perfectly, don't touch"   │
│                                                                      │
│   Why We Can't Just Replace:                                         │
│   ──────────────────────────                                         │
│   1. Process Integration                                             │
│      - Custom logic tuned over decades                               │
│      - Undocumented tribal knowledge                                 │
│      - Risk of introducing bugs                                      │
│                                                                      │
│   2. Cost                                                            │
│      - Replacement: $2M                                              │
│      - Extended downtime: $5M                                        │
│      - Re-certification: $500K                                       │
│      - Re-training: $200K                                            │
│                                                                      │
│   3. Availability                                                    │
│      - New systems need qualification                                │
│      - Changeover requires plant shutdown                            │
│      - Regulatory approval may be needed                             │
│                                                                      │
│   4. Vendor Lock-in                                                  │
│      - Proprietary protocols                                         │
│      - No migration path                                             │
│      - Single-source dependency                                      │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Common Legacy System Types

| System Type | Era | Typical Issues |
|-------------|-----|----------------|
| **Windows XP/2003 HMI** | 2001-2014 | End of support, no patches |
| **DOS-based HMI** | 1985-2000 | No network security, no updates |
| **Old PLCs (S5, PLC-5)** | 1980s-1990s | No authentication, cleartext protocols |
| **Serial-only devices** | All eras | No encryption, physical access = full access |
| **Proprietary DCS** | 1980s-2000s | Vendor-specific, limited security |
| **Single-board computers** | All eras | Custom OS, no update mechanism |

## Risk Assessment for Legacy Systems

### Step 1: Inventory and Characterize

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Legacy System Inventory                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   For each legacy system, document:                                  │
│                                                                      │
│   ┌───────────────────────────────────────────────────────────────┐ │
│   │ Asset: HMI-REACTOR-01                                         │ │
│   ├───────────────────────────────────────────────────────────────┤ │
│   │ OS: Windows XP SP3                                            │ │
│   │ Function: Reactor control interface                           │ │
│   │ Criticality: HIGH (safety system interface)                   │ │
│   │ Network: Plant A control network                              │ │
│   │ Protocols: OPC DA, SMBv1                                      │ │
│   │ Authentication: Local accounts only                           │ │
│   │ Last Patch: April 2014 (EOL)                                  │ │
│   │ Vendor Support: None                                          │ │
│   │ Replacement Plan: None (process-specific)                     │ │
│   │ Known Vulnerabilities: MS08-067, MS17-010, many others        │ │
│   │ Compensating Controls: (see below)                            │ │
│   └───────────────────────────────────────────────────────────────┘ │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Step 2: Vulnerability Assessment

For legacy systems, traditional vulnerability scanning is dangerous:

| Approach | Risk | Alternative |
|----------|------|-------------|
| Active scanning | System crash | Passive monitoring |
| Penetration testing | Process disruption | Offline environment testing |
| Patch compliance | No patches available | Compensating controls |

### Step 3: Determine Acceptable Risk

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Risk Acceptance Framework                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Options for Each Legacy System:                                    │
│                                                                      │
│   1. MITIGATE: Implement compensating controls                       │
│      When: System is critical, no alternative                        │
│                                                                      │
│   2. TRANSFER: Isolate completely, limit blast radius                │
│      When: Cannot adequately protect but must keep                   │
│                                                                      │
│   3. ACCEPT: Document risk, monitor closely                          │
│      When: Low criticality, high replacement cost                    │
│                                                                      │
│   4. AVOID: Replace or retire the system                             │
│      When: Risk exceeds value, replacement available                 │
│                                                                      │
│   Decision Matrix:                                                   │
│   ─────────────────────────────────────────────────────────────────  │
│                    Criticality                                       │
│                    Low         High                                  │
│   Vulnerability    ┌───────────┬───────────┐                         │
│   High            │  Accept/   │  Mitigate │                         │
│                   │  Avoid     │           │                         │
│                   ├───────────┼───────────┤                         │
│   Low             │  Accept    │  Mitigate │                         │
│                   │            │  /Monitor │                         │
│                   └───────────┴───────────┘                         │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Compensating Controls

When you cannot patch, you must compensate:

### 1. Network Isolation

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Legacy System Isolation                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Before (flat network):                                             │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │                                                             │   │
│   │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐        │   │
│   │  │ Modern  │  │ Modern  │  │ Legacy  │  │ Legacy  │        │   │
│   │  │   PLC   │──│   HMI   │──│   HMI   │──│   DCS   │        │   │
│   │  └─────────┘  └─────────┘  └─────────┘  └─────────┘        │   │
│   │                                                             │   │
│   │   All systems on same network, legacy systems exposed       │   │
│   │                                                             │   │
│   └─────────────────────────────────────────────────────────────┘   │
│                                                                      │
│   After (isolated):                                                  │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │                                                             │   │
│   │  Modern Network                Legacy Cell                  │   │
│   │  ┌─────────────────────┐      ┌─────────────────────┐      │   │
│   │  │  ┌───────┐ ┌─────┐ │      │  ┌───────┐ ┌─────┐  │      │   │
│   │  │  │Modern │ │Mod. │ │      │  │Legacy │ │Leg. │  │      │   │
│   │  │  │ PLC   │ │HMI  │ │      │  │ HMI   │ │DCS  │  │      │   │
│   │  │  └───────┘ └─────┘ │      │  └───────┘ └─────┘  │      │   │
│   │  └──────────┬──────────┘      └──────────┬─────────┘      │   │
│   │             │                            │                 │   │
│   │             │    ┌─────────────────┐     │                 │   │
│   │             └───►│    Firewall     │◄────┘                 │   │
│   │                  │  (strict rules) │                       │   │
│   │                  └─────────────────┘                       │   │
│   │                                                             │   │
│   │   Legacy systems isolated, traffic strictly controlled      │   │
│   │                                                             │   │
│   └─────────────────────────────────────────────────────────────┘   │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### 2. Protocol Wrapping/Proxying

Convert insecure protocols to secure ones at the boundary:

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Protocol Proxy for Legacy Systems                 │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Modern Client                                                      │
│   ┌───────────────────┐                                             │
│   │   OPC UA Client   │                                             │
│   │   (Secure)        │                                             │
│   └─────────┬─────────┘                                             │
│             │                                                        │
│             │ OPC UA (TLS, Auth)                                     │
│             ▼                                                        │
│   ┌───────────────────────────────────────────────────────────────┐ │
│   │                    PROTOCOL GATEWAY                           │ │
│   │   ┌──────────────────────────────────────────────────────┐    │ │
│   │   │  • Terminates secure connection                      │    │ │
│   │   │  • Authenticates and authorizes requests             │    │ │
│   │   │  • Translates to legacy protocol                     │    │ │
│   │   │  • Rate limits requests                              │    │ │
│   │   │  • Logs all activity                                 │    │ │
│   │   └──────────────────────────────────────────────────────┘    │ │
│   └─────────┬─────────────────────────────────────────────────────┘ │
│             │                                                        │
│             │ OPC DA (No auth, cleartext)                            │
│             ▼                                                        │
│   ┌───────────────────┐                                             │
│   │   Legacy HMI      │                                             │
│   │   (Insecure)      │                                             │
│   └───────────────────┘                                             │
│                                                                      │
│   Security provided at boundary, legacy system unchanged             │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### 3. Application Whitelisting

For systems that cannot run modern endpoint protection:

| Product | Platform Support | Notes |
|---------|------------------|-------|
| **Carbon Black App Control** | Windows XP+ | Enterprise-grade |
| **McAfee Application Control** | Windows XP+ | Legacy support |
| **Bit9** | Windows XP+ | Now Carbon Black |
| **Airlock Digital** | Windows/Linux | Lightweight |

Implementation approach:

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Application Whitelisting Process                  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   1. LEARN MODE (2-4 weeks)                                          │
│      • Install agent in monitoring mode                              │
│      • Observe all running applications                              │
│      • Build baseline of normal executables                          │
│                                                                      │
│   2. TEST MODE (2-4 weeks)                                           │
│      • Enable blocking with alerts                                   │
│      • Monitor for false positives                                   │
│      • Refine whitelist                                              │
│                                                                      │
│   3. ENFORCE MODE                                                    │
│      • Block unauthorized executables                                │
│      • Alert on violations                                           │
│      • Maintain change control for updates                           │
│                                                                      │
│   Key Consideration:                                                 │
│   • Whitelist must include vendor tools and update processes         │
│   • Changes require coordination with operations                     │
│   • Test thoroughly before enforcement                               │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### 4. Host-Based Firewalls

Even on Windows XP, you can restrict network access:

```
Windows XP Built-in Firewall Configuration:
─────────────────────────────────────────────
# Enable firewall
netsh firewall set opmode enable

# Allow only specific IP to connect on OPC port
netsh firewall add portopening TCP 135 "OPC" ENABLE CUSTOM 10.1.1.5

# Block all other inbound
netsh firewall set opmode enable DISABLE DISABLE ENABLE

# Note: Windows XP firewall is basic but better than nothing
```

### 5. USB and Removable Media Control

```
┌─────────────────────────────────────────────────────────────────────┐
│                    USB Control for Legacy Systems                    │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Physical Controls:                                                 │
│   ─────────────────                                                  │
│   • USB port blockers (physical devices)                             │
│   • Sealed/locked enclosures                                         │
│   • Port epoxy (permanent, use with caution)                         │
│                                                                      │
│   Software Controls (where possible):                                │
│   ────────────────────────────────────                               │
│   • Disable USB mass storage via registry (Windows)                  │
│   • Device whitelisting (specific device IDs)                        │
│   • Removable media scanning stations                                │
│                                                                      │
│   Windows XP USB Disable (registry):                                 │
│   HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\UsbStor      │
│   Set "Start" to 4 (disabled)                                        │
│                                                                      │
│   Note: May break legitimate USB needs (keyboards, etc.)             │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### 6. Enhanced Monitoring

When you cannot prevent attacks, detect them quickly:

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Legacy System Monitoring                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Network-Level Monitoring:                                          │
│   ─────────────────────────                                          │
│   • Full packet capture (passive)                                    │
│   • NetFlow/IPFIX for traffic analysis                               │
│   • Protocol-aware IDS (Suricata with OT rules)                      │
│   • Anomaly detection (new connections, volume changes)              │
│                                                                      │
│   Asset-Level Monitoring (if supported):                             │
│   ─────────────────────────────────────                              │
│   • Windows Event Logs (forwarded to SIEM)                           │
│   • Process monitoring (new processes)                               │
│   • File integrity monitoring                                        │
│   • Registry change detection                                        │
│                                                                      │
│   OT-Specific Monitoring:                                            │
│   ───────────────────────                                            │
│   • Configuration change detection                                   │
│   • Firmware integrity verification                                  │
│   • Logic change detection (PLC/DCS)                                 │
│   • Unauthorized command detection                                   │
│                                                                      │
│   Tools:                                                             │
│   • Claroty, Nozomi Networks, Dragos for OT-specific                 │
│   • Zeek (formerly Bro) for network analysis                         │
│   • OSSEC for host-based (limited legacy support)                    │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### 7. Physical Security

Often the best protection for systems that cannot be secured technically:

| Control | Implementation |
|---------|----------------|
| **Locked enclosures** | Prevent physical access to ports |
| **Dedicated rooms** | Control room access control |
| **Camera surveillance** | Monitor physical interaction |
| **Access logs** | Badge reader entry logging |
| **Tamper detection** | Seals, sensors on enclosures |

## Windows-Specific Legacy Controls

### Windows XP/2003 Security

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Hardening Windows XP for OT                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Registry Hardening:                                                │
│   ─────────────────────                                              │
│   # Disable SMBv1 (where possible)                                   │
│   HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\             │
│   LanmanServer\Parameters                                            │
│   SMB1 = 0                                                           │
│                                                                      │
│   # Disable Remote Registry                                          │
│   Set RemoteRegistry service to Disabled                             │
│                                                                      │
│   # Disable Autorun                                                  │
│   HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\                     │
│   CurrentVersion\Policies\Explorer                                   │
│   NoDriveTypeAutoRun = 255                                           │
│                                                                      │
│   Service Hardening:                                                 │
│   ─────────────────                                                  │
│   Disable unnecessary services:                                      │
│   • Alerter                                                          │
│   • Messenger                                                        │
│   • Remote Desktop (if not needed)                                   │
│   • Telnet                                                           │
│   • SNMP (if not needed)                                             │
│                                                                      │
│   Account Security:                                                  │
│   ────────────────                                                   │
│   • Rename Administrator account                                     │
│   • Disable Guest account                                            │
│   • Strong password policy (via local policy)                        │
│   • Account lockout after failed attempts                            │
│                                                                      │
│   Note: Test all changes in non-production first!                    │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Extended Security Updates (ESU)

Microsoft offers paid extended support for some legacy OS:

| OS | ESU Availability | Note |
|----|------------------|------|
| Windows XP | Ended 2019 | Custom support only |
| Windows 7 | Through 2023 | Available for purchase |
| Windows Server 2008 | Through 2023 | Available for purchase |
| Windows Server 2012 | Through 2026 | Available for purchase |

## PLC/RTU-Specific Controls

### Legacy PLC Security

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Legacy PLC Compensating Controls                  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Network Controls:                                                  │
│   ─────────────────                                                  │
│   • Place PLC on dedicated VLAN                                      │
│   • Firewall: Allow only specific IPs to connect                     │
│   • Firewall: Allow only required ports/protocols                    │
│   • Block all internet-bound traffic                                 │
│                                                                      │
│   Access Controls:                                                   │
│   ────────────────                                                   │
│   • If PLC has password feature, use it                              │
│   • Change default passwords                                         │
│   • Restrict physical access to PLC cabinet                          │
│   • Use PAM for engineering workstation access                       │
│                                                                      │
│   Monitoring:                                                        │
│   ──────────                                                         │
│   • Log all connections to PLC                                       │
│   • Monitor for configuration/logic changes                          │
│   • Alert on unauthorized programming sessions                       │
│   • Baseline normal traffic patterns                                 │
│                                                                      │
│   Configuration Management:                                          │
│   ─────────────────────────                                          │
│   • Maintain offline backup of PLC program                           │
│   • Version control for all logic changes                            │
│   • Document and approve all modifications                           │
│   • Regular comparison to known-good baseline                        │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Serial Device Security

### Securing RS-232/RS-485 Devices

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Serial Device Security                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Challenge: No native security in serial protocols                  │
│                                                                      │
│   Physical Security:                                                 │
│   ─────────────────                                                  │
│   • Secure wiring in conduit                                         │
│   • Lock serial port access panels                                   │
│   • Use tamper-evident seals                                         │
│                                                                      │
│   Serial Server Security:                                            │
│   ───────────────────────                                            │
│   When converting serial to IP, secure the server:                   │
│                                                                      │
│   ┌───────────┐    ┌──────────────┐    ┌───────────┐                │
│   │  Legacy   │───►│   Secure     │◄───│  Modern   │                │
│   │   PLC     │RS485│   Serial     │TLS │  Client   │                │
│   │           │    │   Gateway    │    │           │                │
│   └───────────┘    └──────────────┘    └───────────┘                │
│                                                                      │
│   Gateway features:                                                  │
│   • Authentication required for TCP connection                       │
│   • TLS encryption on network side                                   │
│   • IP address filtering                                             │
│   • Session logging                                                  │
│   • Rate limiting                                                    │
│                                                                      │
│   Products: Moxa NPort, Digi PortServer, Lantronix                   │
│             (Configure security features!)                           │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Virtual Patching

Using security devices to block exploits for unpatched systems:

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Virtual Patching Architecture                     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Concept: Block exploit traffic at the network level                │
│                                                                      │
│   ┌───────────────────────────────────────────────────────────────┐ │
│   │   Network Traffic                                             │ │
│   │        │                                                      │ │
│   │        ▼                                                      │ │
│   │   ┌─────────────────────────────────────────────────────────┐ │ │
│   │   │            IPS / Virtual Patch Device                   │ │ │
│   │   │                                                         │ │ │
│   │   │   Signature: MS17-010 (EternalBlue)                     │ │ │
│   │   │   Action: BLOCK                                         │ │ │
│   │   │                                                         │ │ │
│   │   │   Signature: MS08-067 (Conficker)                       │ │ │
│   │   │   Action: BLOCK                                         │ │ │
│   │   │                                                         │ │ │
│   │   │   Signature: CVE-2014-XXXX (Windows XP exploit)         │ │ │
│   │   │   Action: BLOCK                                         │ │ │
│   │   │                                                         │ │ │
│   │   └─────────────────────────────────────────────────────────┘ │ │
│   │        │                                                      │ │
│   │        ▼ (Clean traffic only)                                 │ │
│   │   ┌─────────────────────────────────────────────────────────┐ │ │
│   │   │   Unpatched Legacy System                               │ │ │
│   │   │   (Windows XP)                                          │ │ │
│   │   └─────────────────────────────────────────────────────────┘ │ │
│   │                                                               │ │
│   └───────────────────────────────────────────────────────────────┘ │
│                                                                      │
│   Products: TrendMicro TippingPoint, Palo Alto, Fortinet            │
│             (with ICS-specific signature packs)                      │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Documentation Requirements

For every legacy system, maintain:

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Legacy System Documentation                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Required Documentation:                                            │
│   ───────────────────────                                            │
│                                                                      │
│   1. System Profile                                                  │
│      • Hardware specifications                                       │
│      • Software versions (OS, applications)                          │
│      • Network configuration                                         │
│      • User accounts                                                 │
│                                                                      │
│   2. Risk Assessment                                                 │
│      • Known vulnerabilities                                         │
│      • Threat scenarios                                              │
│      • Impact analysis                                               │
│      • Risk acceptance sign-off                                      │
│                                                                      │
│   3. Compensating Controls                                           │
│      • Network controls implemented                                  │
│      • Host controls implemented                                     │
│      • Physical controls implemented                                 │
│      • Monitoring in place                                           │
│                                                                      │
│   4. Change Management                                               │
│      • Approval process                                              │
│      • Authorized personnel                                          │
│      • Backup/recovery procedures                                    │
│                                                                      │
│   5. Review Schedule                                                 │
│      • Annual risk review                                            │
│      • Compensating control verification                             │
│      • Technology refresh assessment                                 │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Migration Planning

Even with compensating controls, plan for eventual migration:

### Migration Assessment Criteria

| Factor | Trigger for Migration |
|--------|----------------------|
| **Vendor support** | No replacement parts available |
| **Vulnerability severity** | Critical unmitigatable vulnerability |
| **Compliance** | Regulatory requirement |
| **Business need** | Capability not available in legacy |
| **Integration** | Cannot connect to modern systems |
| **Cost** | Compensating controls exceed replacement |

### Migration Approach

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Legacy System Migration Path                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Phase 1: Assessment (3-6 months)                                   │
│   ─────────────────────────────────                                  │
│   • Document current system completely                               │
│   • Identify replacement options                                     │
│   • Assess integration requirements                                  │
│   • Estimate costs and timeline                                      │
│                                                                      │
│   Phase 2: Parallel Operation (6-12 months)                          │
│   ──────────────────────────────────────────                         │
│   • Install new system alongside legacy                              │
│   • Configure to mirror functionality                                │
│   • Test thoroughly in non-production                                │
│   • Train operators on new system                                    │
│                                                                      │
│   Phase 3: Cutover (During planned outage)                           │
│   ─────────────────────────────────────────                          │
│   • Switch production to new system                                  │
│   • Keep legacy available for rollback                               │
│   • Monitor closely                                                  │
│                                                                      │
│   Phase 4: Decommission (After stability period)                     │
│   ──────────────────────────────────────────────                     │
│   • Archive configuration and documentation                          │
│   • Securely dispose of hardware                                     │
│   • Update asset inventory                                           │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Key Takeaways

1. **Legacy is reality** - accept it and plan accordingly
2. **Document everything** - you cannot secure what you don't understand
3. **Network isolation is primary** - segment legacy systems aggressively
4. **Monitoring compensates** - if you cannot prevent, detect quickly
5. **Physical security matters** - when technical controls fail
6. **Plan for migration** - even if it is years away
7. **Risk acceptance is formal** - document decisions and get sign-off

## Study Questions

1. Why might application whitelisting be more effective than antivirus on legacy systems?

2. A Windows XP HMI cannot be patched for MS17-010 (EternalBlue). What compensating controls would you implement?

3. How does virtual patching work, and what are its limitations?

4. Why is physical security particularly important for legacy systems?

5. When should you recommend replacing a legacy system despite the cost?

## Practical Exercise

You discover a Windows 2003 Server running a critical historian application. The system:
- Cannot be patched (vendor unsupported)
- Cannot be upgraded (application incompatible)
- Must communicate with modern SCADA server
- Has USB ports used monthly for data export

Design a compensating control strategy.

## Next Steps

Continue to [07-ot-threat-landscape.md](07-ot-threat-landscape.md) to understand the threats targeting OT environments.

## References

- NIST SP 800-82 Rev. 2 - Section 6.2.1 Patch Management
- ICS-CERT: Recommended Practices for Managing Legacy Systems
- CISA: Understanding Patch Management
- Dragos Year in Review (annual threat reports)
