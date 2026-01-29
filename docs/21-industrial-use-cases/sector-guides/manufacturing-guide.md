# Manufacturing Sector Deployment Guide

## WALLIX PAM4OT for Discrete and Process Manufacturing

---

## Industry Overview

```
+==============================================================================+
|                   MANUFACTURING PAM CHALLENGES                               |
+==============================================================================+

  ENVIRONMENT CHARACTERISTICS
  ===========================

  - Multiple production lines with independent PLCs
  - Mix of OEMs (Siemens, Rockwell, Mitsubishi, Schneider)
  - MES integration requirements
  - Vendor maintenance for specialized equipment
  - FDA/GMP compliance (pharmaceutical, food)
  - Just-in-time production (downtime = $$$)

  COMMON DEVICE TYPES
  ===================

  +------------------------------------------------------------------------+
  | Device Category     | Examples                    | Typical Protocols   |
  +---------------------+-----------------------------+---------------------+
  | PLCs                | S7-1500, ControlLogix, M340 | S7comm, EtherNet/IP |
  | HMIs                | Siemens, Wonderware, AVEVA  | RDP, VNC            |
  | SCADA               | Ignition, WinCC, FactoryTalk| RDP, HTTPS          |
  | Robots              | FANUC, KUKA, ABB            | Proprietary         |
  | CNC Machines        | Mazak, DMG MORI, Haas       | Proprietary, FTP    |
  | Vision Systems      | Cognex, Keyence             | Ethernet, FTP       |
  | MES                 | SAP, Rockwell, AVEVA        | HTTPS, OPC UA       |
  +---------------------+-----------------------------+---------------------+

+==============================================================================+
```

---

## Reference Architecture

```
+==============================================================================+
|                   MANUFACTURING NETWORK ARCHITECTURE                         |
+==============================================================================+

                         ENTERPRISE ZONE (Level 4-5)
                    +--------------------------------+
                    |  ERP, Business Applications    |
                    +---------------+----------------+
                                    |
                    +---------------v----------------+
                    |         DMZ (Level 3.5)        |
                    |  +-------------------------+   |
                    |  | WALLIX Primary Cluster  |   |
                    |  | Historian Mirror        |   |
                    |  | Remote Access Gateway   |   |
                    |  +-------------------------+   |
                    +---------------+----------------+
                                    |
                    +---------------v----------------+
                    |    MANUFACTURING ZONE          |
                    |    (Level 3 - Site Operations) |
                    +---------------+----------------+
                                    |
        +---------------------------+---------------------------+
        |                           |                           |
+-------v-------+           +-------v-------+           +-------v-------+
| CELL ZONE 1   |           | CELL ZONE 2   |           | CELL ZONE 3   |
| (Assembly)    |           | (Machining)   |           | (Packaging)   |
+---------------+           +---------------+           +---------------+
| WALLIX Edge   |           | WALLIX Edge   |           | WALLIX Edge   |
| Line 1 PLCs   |           | CNC Machines  |           | Packaging PLCs|
| Assembly Robots|           | Robot Cell    |           | Vision Systems|
| Quality HMI   |           | Tool Preset   |           | Label Printers|
+---------------+           +---------------+           +---------------+

+==============================================================================+
```

---

## Device Configuration Examples

### Siemens S7 PLC Access

```
Device Configuration:
- Name: plc-assembly-line1
- Host: 192.168.10.10
- Domain: MFG-Assembly
- Description: Siemens S7-1500 Assembly Line 1

Service (for TIA Portal):
- Type: SSH Tunnel
- Local Port: 102
- Description: S7comm for TIA Portal

Authorization:
- User Group: PLC-Engineers
- Recording: Required
- Approval: Not required for monitoring
- Approval: Required for program changes
```

### Rockwell ControlLogix Access

```
Device Configuration:
- Name: plc-machining-cell1
- Host: 192.168.20.10
- Domain: MFG-Machining
- Description: Allen-Bradley ControlLogix Cell 1

Service (for Studio 5000):
- Type: SSH Tunnel
- Local Port: 44818
- Description: EtherNet/IP for Studio 5000

Authorization:
- User Group: Controls-Engineers
- Recording: Required
- 4-Eyes: Required for safety-related changes
```

### SCADA HMI Access

```
Device Configuration:
- Name: hmi-supervisor-station
- Host: 192.168.30.100
- Domain: MFG-SCADA
- Description: Ignition SCADA Supervisor

Service:
- Type: RDP
- Port: 3389
- NLA: Enabled

Account:
- Name: operator
- Auto-rotation: Disabled (shared account)
- Credential injection: Enabled

Authorization:
- User Group: Shift-Operators
- Recording: Required
- Time Restriction: Shift hours only
```

---

## User Roles and Access Matrix

```
+==============================================================================+
|                   MANUFACTURING ACCESS MATRIX                                |
+==============================================================================+

                           | Shift    | Line    | Controls | Maintenance | Vendor
  Target                   | Operator | Lead    | Engineer | Tech        |
  -------------------------+----------+---------+----------+-------------+--------
  SCADA HMI (view)         |    X     |    X    |    X     |      X      |
  SCADA HMI (operate)      |    X     |    X    |    X     |             |
  SCADA HMI (config)       |          |         |    X     |             |
  PLC (monitor)            |          |    X    |    X     |      X      |   X
  PLC (program)            |          |         |    X     |             |   X*
  Robot (teach)            |          |         |    X     |      X      |   X*
  Robot (program)          |          |         |    X     |             |   X*
  CNC (operate)            |    X     |    X    |          |      X      |
  CNC (program)            |          |    X    |          |      X      |
  Vision (config)          |          |         |    X     |             |   X*
  MES (view)               |    X     |    X    |    X     |      X      |
  MES (admin)              |          |         |          |             |

  * = Requires approval and 4-eyes supervision

+==============================================================================+
```

---

## Compliance Considerations

### FDA 21 CFR Part 11 (Pharmaceutical/Food)

| Requirement | WALLIX Implementation |
|-------------|----------------------|
| Electronic signatures | User authentication + MFA |
| Audit trails | Session recording, command logging |
| System access controls | RBAC authorizations |
| Authority checks | Approval workflows |
| Device checks | Source IP restrictions |
| Training documentation | Access review reports |

### IEC 62443 for Manufacturing

| Security Level | WALLIX Configuration |
|----------------|---------------------|
| SL 1 | Password auth, basic recording |
| SL 2 | MFA, full recording, approval for changes |
| SL 3 | Hardware MFA, 4-eyes, command filtering |
| SL 4 | Air-gapped deployment, HSM, biometrics |

---

## Implementation Checklist

### Phase 1: Assessment and Planning

- [ ] Inventory all production equipment
- [ ] Map network segments and firewall rules
- [ ] Identify OEM vendor access requirements
- [ ] Document current access methods
- [ ] Define user roles and responsibilities
- [ ] Select pilot production line

### Phase 2: Core Deployment

- [ ] Deploy WALLIX in manufacturing DMZ
- [ ] Configure LDAP/AD integration
- [ ] Enable MFA for all users
- [ ] Create domain structure by production area
- [ ] Onboard pilot line devices
- [ ] Configure vendor access policies

### Phase 3: Production Rollout

- [ ] Expand to all production lines
- [ ] Train operators and engineers
- [ ] Integrate with MES (if applicable)
- [ ] Configure SIEM integration
- [ ] Establish monitoring dashboards
- [ ] Document procedures

### Phase 4: Optimization

- [ ] Automate device onboarding
- [ ] Implement change management integration
- [ ] Quarterly access reviews
- [ ] Annual compliance audit
- [ ] Continuous improvement

---

## Best Practices

```
+==============================================================================+
|                   MANUFACTURING BEST PRACTICES                               |
+==============================================================================+

  PRODUCTION CONTINUITY
  =====================
  [✓] Test WALLIX failover during maintenance windows
  [✓] Maintain emergency bypass procedures
  [✓] Cache credentials for network failures
  [✓] Minimize session establishment latency

  VENDOR MANAGEMENT
  =================
  [✓] Require WALLIX access for all vendor work
  [✓] Time-limit vendor authorizations
  [✓] Record ALL vendor sessions
  [✓] Rotate credentials after vendor access
  [✓] Review vendor session recordings

  CHANGE CONTROL
  ==============
  [✓] Require approval for PLC program changes
  [✓] Use 4-eyes for safety-critical modifications
  [✓] Tag sessions with change ticket numbers
  [✓] Archive recordings with change documentation

+==============================================================================+
```

---

<p align="center">
  <a href="./oil-gas-guide.md">Oil & Gas</a> •
  <a href="../README.md">Use Cases</a> •
  <a href="../../20-iec62443-compliance/README.md">IEC 62443</a>
</p>
