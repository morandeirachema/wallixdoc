# 21 - Industrial Use Cases

## Table of Contents

1. [Power & Utilities](#power--utilities)
2. [Oil & Gas](#oil--gas)
3. [Manufacturing](#manufacturing)
4. [Water & Wastewater](#water--wastewater)
5. [Transportation](#transportation)
6. [Pharmaceutical](#pharmaceutical)
7. [Vendor Remote Access](#vendor-remote-access)

---

## Power & Utilities

### Electric Grid Operations

```
+==============================================================================+
|                   POWER & UTILITIES USE CASE                                 |
+==============================================================================+

  SCENARIO: Regional electric utility with generation, transmission, and
  distribution assets. Must comply with NERC CIP requirements.

  ARCHITECTURE
  ============

  +------------------------------------------------------------------------+
  |                                                                        |
  |   CORPORATE NETWORK                                                    |
  |   +------------------------------------------------------------------+ |
  |   |  [SOC/SIEM]  [Corporate AD]  [NERC CIP Compliance]               | |
  |   +------------------------------------------------------------------+ |
  |                               |                                        |
  |                    +----------+----------+                             |
  |                    |    WALLIX Access    |                             |
  |                    |    Manager (DMZ)    |                             |
  |                    +----------+----------+                             |
  |                               |                                        |
  |   +---------------------------+---------------------------+            |
  |   |                           |                           |            |
  |   v                           v                           v            |
  |                                                                        |
  |  GENERATION           TRANSMISSION            DISTRIBUTION             |
  |  +---------------+    +---------------+    +---------------+           |
  |  | WALLIX        |    | WALLIX        |    | WALLIX        |           |
  |  | Bastion       |    | Bastion       |    | Bastion       |           |
  |  | (Plant Site)  |    | (Control Ctr) |    | (Dispatch)    |           |
  |  +-------+-------+    +-------+-------+    +-------+-------+           |
  |          |                    |                    |                   |
  |  +-------+-------+    +-------+-------+    +-------+-------+           |
  |  | - DCS         |    | - EMS/SCADA   |    | - DMS/OMS     |           |
  |  | - Turbine     |    | - RTUs        |    | - SCADA       |           |
  |  | - Generator   |    | - Substation  |    | - Smart Meter |           |
  |  | - Boiler      |    |   IEDs        |    |   Systems     |           |
  |  +---------------+    +---------------+    +---------------+           |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  NERC CIP COMPLIANCE MAPPING
  ===========================

  +------------------+---------------------------------------------------+
  | NERC CIP         | WALLIX Implementation                             |
  +------------------+---------------------------------------------------+
  |                  |                                                   |
  | CIP-004-6        | Security awareness training tracking via          |
  | Personnel &      | user management and authorization policies        |
  | Training         |                                                   |
  |                  |                                                   |
  +------------------+---------------------------------------------------+
  |                  |                                                   |
  | CIP-005-6        | WALLIX as Electronic Access Point (EAP)           |
  | Electronic       | All interactive remote access through Bastion    |
  | Security         | Session recording and monitoring                  |
  | Perimeter        | Intermediate system requirement satisfied         |
  |                  |                                                   |
  +------------------+---------------------------------------------------+
  |                  |                                                   |
  | CIP-007-6 R5     | Access control via authorization policies         |
  | System Access    | Password management and rotation                  |
  | Control          | Account lifecycle management                      |
  |                  | Shared account elimination                        |
  |                  |                                                   |
  +------------------+---------------------------------------------------+
  |                  |                                                   |
  | CIP-007-6 R4     | Full session logging                              |
  | Security Event   | SIEM integration for alerting                     |
  | Monitoring       | Real-time session monitoring                      |
  |                  |                                                   |
  +------------------+---------------------------------------------------+
  |                  |                                                   |
  | CIP-011-2        | Session recording for BES Cyber Information       |
  | Information      | Credential vault protects sensitive data          |
  | Protection       | Access logging for all information access         |
  |                  |                                                   |
  +------------------+---------------------------------------------------+

  --------------------------------------------------------------------------

  SPECIFIC CONFIGURATIONS
  =======================

  Substation Access (IEC 61850):
  +------------------------------------------------------------------------+
  | Authorization: substation_engineers -> substation_ieds                 |
  | Protocols: SSH, HTTPS (for IED web interfaces)                         |
  | Time Window: Maintenance windows only (scheduled)                      |
  | Approval: Required from control center operator                        |
  | Recording: Full session + keystroke logging                            |
  +------------------------------------------------------------------------+

  EMS/SCADA Access:
  +------------------------------------------------------------------------+
  | Authorization: scada_operators -> ems_servers                          |
  | Protocols: RDP, SSH                                                    |
  | Time Window: 24/7 (operational)                                        |
  | Approval: Not required for operators, required for admin access        |
  | Recording: Full session recording                                      |
  | MFA: Required                                                          |
  +------------------------------------------------------------------------+

+==============================================================================+
```

---

## Oil & Gas

### Pipeline Operations

```
+==============================================================================+
|                   OIL & GAS USE CASE                                         |
+==============================================================================+

  SCENARIO: Midstream pipeline company with central control and remote
  pump stations, compressor stations, and metering facilities.

  ARCHITECTURE
  ============

  +------------------------------------------------------------------------+
  |                                                                        |
  |                     CENTRAL CONTROL CENTER                             |
  |                     ======================                             |
  |                                                                        |
  |   +------------------------------------------------------------------+ |
  |   |                      WALLIX BASTION HA                           | |
  |   |                                                                  | |
  |   |  +---------------+                    +---------------+          | |
  |   |  |   Node 1      |<------------------>|   Node 2      |          | |
  |   |  |   (Active)    |       Sync         |   (Standby)   |          | |
  |   |  +---------------+                    +---------------+          | |
  |   |                                                                  | |
  |   +------------------------------+-----------------------------------+ |
  |                                  |                                     |
  |   +------------------------------+-----------------------------------+ |
  |   |                                                                  | |
  |   |   [SCADA Master]    [Historian]    [Engineering WS]             | |
  |   |                                                                  | |
  |   +------------------------------------------------------------------+ |
  |                                  |                                     |
  |                            WAN / MPLS                                  |
  |                            (or Satellite)                              |
  |                                  |                                     |
  |   +------------------------------+-----------------------------------+ |
  |   |              |               |               |                   | |
  |   v              v               v               v                   | |
  |                                                                        |
  | +----------+ +----------+ +----------+ +----------+ +----------+       |
  | |Pump Stn 1| |Pump Stn 2| |Compressor| |Metering  | |Tank Farm |       |
  | |          | |          | |Station   | |Station   | |          |       |
  | | [RTU]    | | [RTU]    | | [PLC]    | | [Flow    | | [Level   |       |
  | | [VFD]    | | [VFD]    | | [Turbine]| |  Computer| |  Sensors]|       |
  | +----------+ +----------+ +----------+ +----------+ +----------+       |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  ACCESS SCENARIOS
  ================

  1. OPERATOR ACCESS (Control Center)
     +------------------------------------------------------------------+
     | User: control_operators (group)                                  |
     | Targets: SCADA Master, Historian (read-only)                     |
     | Protocol: RDP to SCADA workstations                              |
     | Time: 24/7 shift coverage                                        |
     | MFA: Required                                                    |
     | Recording: Full video recording                                  |
     +------------------------------------------------------------------+

  2. ENGINEER ACCESS (Remote Sites)
     +------------------------------------------------------------------+
     | User: field_engineers (group)                                    |
     | Targets: RTUs, PLCs at pump/compressor stations                  |
     | Protocol: SSH, Modbus TCP (via approved tools)                   |
     | Time: Business hours + emergency                                 |
     | Approval: Required for PLC programming                           |
     | MFA: Required                                                    |
     | Recording: Full + command logging                                |
     +------------------------------------------------------------------+

  3. VENDOR ACCESS (Turbine Maintenance)
     +------------------------------------------------------------------+
     | User: vendor_turbine_mfg (temporary account)                     |
     | Targets: Compressor station turbine controller                   |
     | Protocol: RDP to vendor jump box, then serial/proprietary        |
     | Time: Scheduled maintenance window only                          |
     | Approval: Required (plant manager + control room)                |
     | Escort: Control room operator monitors session                   |
     | MFA: Required                                                    |
     | Recording: Full + 4-eyes supervision                             |
     +------------------------------------------------------------------+

  --------------------------------------------------------------------------

  PIPELINE-SPECIFIC CONSIDERATIONS
  =================================

  +------------------------------------------------------------------------+
  |                                                                        |
  | LATENCY TOLERANCE                                                      |
  | - Remote sites via satellite may have 500ms+ latency                   |
  | - WALLIX proxy adds minimal overhead (<10ms typically)                 |
  | - Configure session timeouts appropriately                             |
  |                                                                        |
  | EMERGENCY BYPASS                                                       |
  | - Document emergency procedures for PAM failure                        |
  | - Local console access at remote sites                                 |
  | - Break-glass credentials in secure envelopes                          |
  |                                                                        |
  | REGULATORY                                                             |
  | - TSA Pipeline Security Directive compliance                           |
  | - DOT PHMSA requirements                                               |
  | - API 1164 cybersecurity guidelines                                    |
  |                                                                        |
  +------------------------------------------------------------------------+

+==============================================================================+
```

---

## Manufacturing

### Discrete Manufacturing Plant

```
+==============================================================================+
|                   MANUFACTURING USE CASE                                     |
+==============================================================================+

  SCENARIO: Automotive parts manufacturing facility with multiple production
  lines, robotics, and MES integration.

  ARCHITECTURE
  ============

  +------------------------------------------------------------------------+
  |                                                                        |
  |   ENTERPRISE LEVEL (Purdue Level 4-5)                                  |
  |   +------------------------------------------------------------------+ |
  |   |  [ERP]    [Corporate IT]    [Engineering CAD]                    | |
  |   +------------------------------------------------------------------+ |
  |                               |                                        |
  |                    +----------+----------+                             |
  |                    |    IT/OT FIREWALL   |                             |
  |                    +----------+----------+                             |
  |                               |                                        |
  |   MANUFACTURING DMZ (Level 3.5)                                        |
  |   +------------------------------------------------------------------+ |
  |   |                      WALLIX BASTION                              | |
  |   |                                                                  | |
  |   |  +-----------------+  +-----------------+  +-----------------+   | |
  |   |  | Session Manager |  | Password Manager|  | Access Manager  |   | |
  |   |  +-----------------+  +-----------------+  +-----------------+   | |
  |   |                                                                  | |
  |   |  [MES Server]    [Historian]    [Patch Server]                   | |
  |   +------------------------------------------------------------------+ |
  |                               |                                        |
  |                    +----------+----------+                             |
  |                    |    OT FIREWALL      |                             |
  |                    +----------+----------+                             |
  |                               |                                        |
  |   CONTROL LEVEL (Purdue Level 2-3)                                     |
  |   +------------------------------------------------------------------+ |
  |   |                                                                  | |
  |   |  +-------------+  +-------------+  +-------------+               | |
  |   |  | Line 1      |  | Line 2      |  | Line 3      |               | |
  |   |  | SCADA/HMI   |  | SCADA/HMI   |  | SCADA/HMI   |               | |
  |   |  +------+------+  +------+------+  +------+------+               | |
  |   |         |                |                |                      | |
  |   +------------------------------------------------------------------+ |
  |                               |                                        |
  |   FIELD LEVEL (Purdue Level 0-1)                                       |
  |   +------------------------------------------------------------------+ |
  |   |                                                                  | |
  |   |  [Robot Controllers]  [PLCs]  [VFDs]  [Vision Systems]           | |
  |   |                                                                  | |
  |   +------------------------------------------------------------------+ |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  AUTHORIZATION MATRIX
  ====================

  +----------------------+----------+----------+----------+----------+
  | User Group           | MES      | SCADA/   | PLCs     | Robots   |
  |                      | Server   | HMI      |          |          |
  +----------------------+----------+----------+----------+----------+
  | Production Operators | -        | View     | -        | -        |
  | Production Supervisors| View    | Full     | -        | -        |
  | Process Engineers    | Full     | Full     | View     | View     |
  | Controls Engineers   | -        | Full     | Full     | Full     |
  | IT Administrators    | Admin    | -        | -        | -        |
  | Vendors (Robot)      | -        | -        | -        | Specific |
  | Vendors (PLC)        | -        | -        | Specific | -        |
  +----------------------+----------+----------+----------+----------+

  --------------------------------------------------------------------------

  ROBOT PROGRAMMING SCENARIO
  ==========================

  Robots require special handling due to safety implications:

  +------------------------------------------------------------------------+
  |                                                                        |
  | PRE-PROGRAMMING CHECKLIST                                              |
  | -------------------------                                              |
  |                                                                        |
  | [ ] 1. Robot cell locked out (LOTO verified)                           |
  | [ ] 2. Safety systems confirmed in manual mode                         |
  | [ ] 3. Approval obtained via WALLIX workflow                           |
  | [ ] 4. Change ticket created in ITSM                                   |
  | [ ] 5. Backup of current robot program                                 |
  |                                                                        |
  | WALLIX CONFIGURATION                                                   |
  | -------------------                                                    |
  |                                                                        |
  | Authorization: robot_programmers -> robot_controllers                  |
  | Approval: Required (2 approvers: Controls Lead + Safety Officer)       |
  | Time Window: Scheduled maintenance only                                |
  | Protocol: Vendor-specific (KUKA, Fanuc, ABB)                           |
  | Recording: Full session + file transfer logging                        |
  |                                                                        |
  | POST-PROGRAMMING                                                       |
  | ---------------                                                        |
  |                                                                        |
  | [ ] 1. Program verified in simulation mode                             |
  | [ ] 2. Session recording archived                                      |
  | [ ] 3. Change ticket closed                                            |
  | [ ] 4. Password rotation (if using shared service account)             |
  |                                                                        |
  +------------------------------------------------------------------------+

+==============================================================================+
```

---

## Water & Wastewater

### Municipal Water System

```
+==============================================================================+
|                   WATER & WASTEWATER USE CASE                                |
+==============================================================================+

  SCENARIO: Municipal water utility with treatment plants, pump stations,
  and distribution network.

  ARCHITECTURE
  ============

  +------------------------------------------------------------------------+
  |                                                                        |
  |                          CONTROL CENTER                                |
  |                          ==============                                |
  |                                                                        |
  |   +------------------------------------------------------------------+ |
  |   |                      WALLIX BASTION                              | |
  |   |   (Central Hub for all facility access)                          | |
  |   +------------------------------+-----------------------------------+ |
  |                                  |                                     |
  |   +------------------------------+-----------------------------------+ |
  |   |                                                                  | |
  |   |   [Central SCADA]    [GIS System]    [Work Order System]         | |
  |   |                                                                  | |
  |   +------------------------------------------------------------------+ |
  |                                  |                                     |
  |                            Municipal WAN                               |
  |                                  |                                     |
  |         +------------------------+------------------------+            |
  |         |                        |                        |            |
  |         v                        v                        v            |
  |                                                                        |
  |  TREATMENT PLANT           PUMP STATIONS            DISTRIBUTION       |
  |  +----------------+        +----------------+        +----------------+ |
  |  |                |        |                |        |                | |
  |  | [SCADA Server] |        | [RTU/PLC]      |        | [Pressure      | |
  |  | [Historian]    |        | [VFDs]         |        |  Monitors]     | |
  |  | [Lab System]   |        | [Level         |        | [Flow Meters]  | |
  |  |                |        |  Sensors]      |        | [Valves]       | |
  |  +----------------+        +----------------+        +----------------+ |
  |                                                                        |
  |  LOCAL HMI                 REMOTE (Cellular/Radio)   REMOTE            |
  |  On-site access            Limited bandwidth         Field devices     |
  |  via WALLIX                                                            |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  WATER-SPECIFIC SECURITY REQUIREMENTS
  =====================================

  America's Water Infrastructure Act (AWIA) Section 2013:

  +------------------------------------------------------------------------+
  | Requirement                    | WALLIX Implementation                 |
  +--------------------------------+---------------------------------------+
  |                                |                                       |
  | Risk Assessment                | Asset inventory via WALLIX devices    |
  |                                | Access pattern analysis               |
  |                                |                                       |
  +--------------------------------+---------------------------------------+
  |                                |                                       |
  | Monitoring of SCADA Systems    | Full session recording                |
  |                                | Real-time session monitoring          |
  |                                | SIEM integration for alerting         |
  |                                |                                       |
  +--------------------------------+---------------------------------------+
  |                                |                                       |
  | Chemical Handling Systems      | Restricted access to dosing controls  |
  |                                | Approval workflow for changes         |
  |                                | Audit trail for all access            |
  |                                |                                       |
  +--------------------------------+---------------------------------------+
  |                                |                                       |
  | Detection of Intrusions        | Failed login alerting                 |
  |                                | Unusual access pattern detection      |
  |                                | Integration with IDS/IPS              |
  |                                |                                       |
  +--------------------------------+---------------------------------------+

  --------------------------------------------------------------------------

  CRITICAL ACCESS SCENARIOS
  =========================

  1. CHEMICAL DOSING SYSTEM ACCESS (HIGHEST RISK)
     +------------------------------------------------------------------+
     | Targets: Chlorine, fluoride, pH adjustment systems               |
     | Access: Treatment plant operators only                           |
     | MFA: Required (smart card + PIN)                                 |
     | Approval: Plant supervisor approval required                     |
     | Monitoring: Real-time 4-eyes supervision                         |
     | Recording: Full session + command logging                        |
     | Time: Scheduled dosing adjustment windows                        |
     |                                                                  |
     | ALERT TRIGGERS:                                                  |
     | - Any setpoint change > 10%                                      |
     | - Access outside normal hours                                    |
     | - Failed authentication attempts                                 |
     +------------------------------------------------------------------+

  2. PUMP STATION REMOTE ACCESS
     +------------------------------------------------------------------+
     | Targets: RTUs at remote pump stations                            |
     | Access: SCADA technicians                                        |
     | Protocol: SSH, Modbus TCP                                        |
     | Bandwidth: May be limited (cellular/radio)                       |
     | Considerations: Minimize session data transfer                   |
     | Recording: Keystroke logging (lower bandwidth than video)        |
     +------------------------------------------------------------------+

+==============================================================================+
```

---

## Transportation

### Rail Operations

```
+==============================================================================+
|                   TRANSPORTATION (RAIL) USE CASE                             |
+==============================================================================+

  SCENARIO: Regional rail operator with signaling systems, train control,
  and station automation.

  ARCHITECTURE
  ============

  +------------------------------------------------------------------------+
  |                                                                        |
  |                     RAIL OPERATIONS CENTER                             |
  |                     =====================                              |
  |                                                                        |
  |   +------------------------------------------------------------------+ |
  |   |                      WALLIX BASTION                              | |
  |   |   +----------------------------------------------------------+   | |
  |   |   |  Session Manager  |  Password Vault  |  Access Manager   |   | |
  |   |   +----------------------------------------------------------+   | |
  |   +------------------------------+-----------------------------------+ |
  |                                  |                                     |
  |   +------------------------------+-----------------------------------+ |
  |   |                                                                  | |
  |   |   [Train Control]  [Signaling SCADA]  [Passenger Info]          | |
  |   |                                                                  | |
  |   +------------------------------------------------------------------+ |
  |                                  |                                     |
  |                      Rail Communication Network                        |
  |                      (Private fiber / radio)                           |
  |                                  |                                     |
  |     +----------------------------+----------------------------+        |
  |     |                            |                            |        |
  |     v                            v                            v        |
  |                                                                        |
  |  SIGNALING ZONE           STATION SYSTEMS           TRACKSIDE          |
  |  +----------------+       +----------------+       +----------------+   |
  |  |                |       |                |       |                |   |
  |  | [Interlocking]|       | [CCTV/Access]  |       | [Track         |   |
  |  | [Signals]     |       | [Ticketing]    |       |  Circuits]     |   |
  |  | [Points/      |       | [Platform      |       | [Axle          |   |
  |  |  Switches]    |       |  Screens]      |       |  Counters]     |   |
  |  |                |       |                |       |                |   |
  |  +----------------+       +----------------+       +----------------+   |
  |                                                                        |
  |  SAFETY-CRITICAL          PASSENGER-FACING         SAFETY-CRITICAL     |
  |  SIL 4 Systems            Non-safety               SIL 2-3 Systems     |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  SIGNALING SYSTEM ACCESS (SAFETY-CRITICAL)
  ==========================================

  Signaling systems are SIL 4 (Safety Integrity Level) - highest criticality.
  Any unauthorized change could cause collisions or derailments.

  +------------------------------------------------------------------------+
  |                                                                        |
  | ACCESS REQUIREMENTS                                                    |
  | ===================                                                    |
  |                                                                        |
  | User Group: signaling_engineers                                        |
  | Certification: Must hold valid signaling competency certificate        |
  | Access Type: Read-only by default, maintenance mode for changes        |
  |                                                                        |
  | AUTHORIZATION POLICY                                                   |
  |                                                                        |
  | +----------------------------------------------------------------+    |
  | | Condition          | Requirement                                |    |
  | +--------------------+--------------------------------------------+    |
  | | Any access         | MFA (hardware token)                       |    |
  | | View configuration | Approval from shift manager                |    |
  | | Modify settings    | 4-eyes approval (2 engineers)              |    |
  | | Safety-critical    | Possession of safety key + approval        |    |
  | |   changes          |                                            |    |
  | +--------------------+--------------------------------------------+    |
  |                                                                        |
  | SESSION MONITORING                                                     |
  |                                                                        |
  | - Real-time monitoring by control room supervisor                      |
  | - Automatic alert on any setpoint change                               |
  | - Session recording with 7-year retention (regulatory)                 |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  RAIL-SPECIFIC REGULATIONS
  =========================

  +------------------+------------------------------------------------------+
  | Regulation       | WALLIX Compliance                                    |
  +------------------+------------------------------------------------------+
  |                  |                                                      |
  | EN 50129         | Audit trail for all safety system access             |
  | (Safety Systems) | Proof of competent person access                     |
  |                  |                                                      |
  +------------------+------------------------------------------------------+
  |                  |                                                      |
  | TSA Security     | Remote access through approved gateway (WALLIX)      |
  | Directives       | MFA for all remote access                            |
  |                  | Continuous monitoring                                |
  |                  |                                                      |
  +------------------+------------------------------------------------------+
  |                  |                                                      |
  | NIS2 Directive   | Incident reporting (SIEM integration)                |
  | (EU)             | Supply chain security (vendor access control)        |
  |                  | Risk management documentation                        |
  |                  |                                                      |
  +------------------+------------------------------------------------------+

+==============================================================================+
```

---

## Pharmaceutical

### GxP Manufacturing Environment

```
+==============================================================================+
|                   PHARMACEUTICAL USE CASE                                    |
+==============================================================================+

  SCENARIO: Pharmaceutical manufacturing facility producing FDA-regulated
  products. Must comply with 21 CFR Part 11 and GMP requirements.

  ARCHITECTURE
  ============

  +------------------------------------------------------------------------+
  |                                                                        |
  |   CORPORATE / QUALITY SYSTEMS                                          |
  |   +------------------------------------------------------------------+ |
  |   |  [QMS]  [Document Control]  [LIMS]  [Corporate AD]               | |
  |   +------------------------------------------------------------------+ |
  |                               |                                        |
  |                    +----------+----------+                             |
  |                    |    WALLIX BASTION   |                             |
  |                    |  (21 CFR Part 11    |                             |
  |                    |   compliant config) |                             |
  |                    +----------+----------+                             |
  |                               |                                        |
  |   MANUFACTURING EXECUTION                                              |
  |   +------------------------------------------------------------------+ |
  |   |                                                                  | |
  |   |   [MES/Batch]    [Historian]    [Recipe Management]              | |
  |   |                                                                  | |
  |   +------------------------------------------------------------------+ |
  |                               |                                        |
  |   PROCESS CONTROL                                                      |
  |   +------------------------------------------------------------------+ |
  |   |                                                                  | |
  |   |   [DCS - Formulation]  [DCS - Filling]  [Clean Utilities]        | |
  |   |                                                                  | |
  |   +------------------------------------------------------------------+ |
  |                               |                                        |
  |   EQUIPMENT / SKIDS                                                    |
  |   +------------------------------------------------------------------+ |
  |   |                                                                  | |
  |   |   [Bioreactors]  [Chromatography]  [Lyophilizers]  [CIP/SIP]     | |
  |   |                                                                  | |
  |   +------------------------------------------------------------------+ |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  21 CFR PART 11 COMPLIANCE
  =========================

  WALLIX configuration for FDA electronic records/signatures:

  +------------------------------------------------------------------------+
  | 21 CFR Part 11 Requirement     | WALLIX Implementation                 |
  +--------------------------------+---------------------------------------+
  |                                |                                       |
  | 11.10(a) - Validation          | Documented validation protocol        |
  |                                | IQ/OQ/PQ documentation                |
  |                                |                                       |
  +--------------------------------+---------------------------------------+
  |                                |                                       |
  | 11.10(b) - Legible copies      | Session recordings exportable         |
  |                                | Audit logs in standard formats        |
  |                                |                                       |
  +--------------------------------+---------------------------------------+
  |                                |                                       |
  | 11.10(c) - Record protection   | Tamper-evident audit logs             |
  |                                | Hash chain for log integrity          |
  |                                |                                       |
  +--------------------------------+---------------------------------------+
  |                                |                                       |
  | 11.10(d) - Limited access      | Role-based access control             |
  |                                | Authorization policies                |
  |                                |                                       |
  +--------------------------------+---------------------------------------+
  |                                |                                       |
  | 11.10(e) - Audit trails        | Complete session audit trail          |
  |                                | Keystroke logging                     |
  |                                | Timestamp for all actions             |
  |                                |                                       |
  +--------------------------------+---------------------------------------+
  |                                |                                       |
  | 11.10(g) - Authority checks    | Approval workflows                    |
  |                                | Electronic signature verification     |
  |                                |                                       |
  +--------------------------------+---------------------------------------+
  |                                |                                       |
  | 11.10(k) - Device checks       | Session source verification           |
  |                                | Device-based policies                 |
  |                                |                                       |
  +--------------------------------+---------------------------------------+
  |                                |                                       |
  | 11.50 - Signature manifestations| Recorded user identity in session    |
  |                                | Date/time stamp                       |
  |                                |                                       |
  +--------------------------------+---------------------------------------+
  |                                |                                       |
  | 11.100 - Unique identification | Individual user accounts              |
  |                                | No shared accounts                    |
  |                                | Unique credentials per user           |
  |                                |                                       |
  +--------------------------------+---------------------------------------+
  |                                |                                       |
  | 11.300 - ID code/password      | Password complexity                   |
  | controls                       | Unique IDs, periodic expiration       |
  |                                | Account lockout                       |
  |                                |                                       |
  +--------------------------------+---------------------------------------+

  --------------------------------------------------------------------------

  BATCH RECORD ACCESS SCENARIO
  ============================

  +------------------------------------------------------------------------+
  |                                                                        |
  | CRITICAL PROCESS PARAMETER CHANGES                                     |
  | ==================================                                     |
  |                                                                        |
  | Any change to critical process parameters requires:                    |
  |                                                                        |
  | 1. ELECTRONIC APPROVAL                                                 |
  |    - WALLIX approval workflow triggered                                |
  |    - Approvers: QA + Production Supervisor                             |
  |    - Reason for change documented                                      |
  |                                                                        |
  | 2. SESSION ACCESS                                                      |
  |    - MFA required (21 CFR Part 11 compliant signature)                 |
  |    - Full session recording (video + keystrokes)                       |
  |    - Real-time monitoring available for QA                             |
  |                                                                        |
  | 3. AUDIT TRAIL                                                         |
  |    - Before/after values captured                                      |
  |    - User identity, timestamp, reason recorded                         |
  |    - Tamper-evident log entry                                          |
  |                                                                        |
  | 4. RETENTION                                                           |
  |    - Session recording retained for batch record retention period      |
  |    - Typically 1 year after product expiry (3-7 years total)           |
  |                                                                        |
  +------------------------------------------------------------------------+

+==============================================================================+
```

---

## Vendor Remote Access

### Secure Third-Party Access

```
+==============================================================================+
|                   VENDOR REMOTE ACCESS USE CASE                              |
+==============================================================================+

  SCENARIO: Managing secure remote access for equipment vendors, system
  integrators, and third-party service providers.

  ARCHITECTURE
  ============

  +------------------------------------------------------------------------+
  |                                                                        |
  |   INTERNET                                                             |
  |       |                                                                |
  |       v                                                                |
  |   +------------------+                                                 |
  |   |   Vendor User    |  (Equipment manufacturer, integrator)           |
  |   +--------+---------+                                                 |
  |            |                                                           |
  |            | HTTPS (443)                                               |
  |            v                                                           |
  |   +------------------+                                                 |
  |   |   WALLIX Access  |  External-facing web portal                     |
  |   |   Manager (DMZ)  |  MFA enforced, certificate pinned               |
  |   +--------+---------+                                                 |
  |            |                                                           |
  |            | Internal                                                  |
  |            v                                                           |
  |   +------------------+                                                 |
  |   |   WALLIX Bastion |  Proxy, recording, vault                        |
  |   |   (Internal)     |                                                 |
  |   +--------+---------+                                                 |
  |            |                                                           |
  |            v                                                           |
  |   +--------------------------------------------------+                 |
  |   |              VENDOR ACCESS TARGETS               |                 |
  |   |                                                  |                 |
  |   |   [Robot Controllers]  [PLCs]  [HMI Servers]     |                 |
  |   |   [Specialized Equipment]  [DCS]                 |                 |
  |   |                                                  |                 |
  |   +--------------------------------------------------+                 |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  VENDOR ONBOARDING WORKFLOW
  ==========================

  +------------------------------------------------------------------------+
  |                                                                        |
  | STEP 1: VENDOR REGISTRATION                                            |
  | ---------------------------                                            |
  |                                                                        |
  | - Vendor company registered in WALLIX                                  |
  | - Vendor domain created for isolation                                  |
  | - Service agreement uploaded (SLA, NDA, security requirements)         |
  | - Primary contact designated                                           |
  |                                                                        |
  | STEP 2: USER ACCOUNT CREATION                                          |
  | -----------------------------                                          |
  |                                                                        |
  | - Individual user accounts (NO shared accounts)                        |
  | - Account expiration set (max 1 year, renewable)                       |
  | - MFA token provisioned (TOTP, hardware token, or email OTP)           |
  | - Terms of use acceptance required                                     |
  |                                                                        |
  | STEP 3: ACCESS AUTHORIZATION                                           |
  | ----------------------------                                           |
  |                                                                        |
  | - Specific targets assigned (only their equipment)                     |
  | - Time windows defined (maintenance windows only)                      |
  | - Approval workflow configured (plant manager + OT security)           |
  | - Protocol restrictions (only needed protocols)                        |
  |                                                                        |
  | STEP 4: ACCESS REQUEST FLOW                                            |
  | ---------------------------                                            |
  |                                                                        |
  |   Vendor           Plant Manager     OT Security      WALLIX           |
  |     |                   |               |               |              |
  |     | Request access    |               |               |              |
  |     +------------------>|               |               |              |
  |     |                   | Approve?      |               |              |
  |     |                   +-------------->|               |              |
  |     |                   |               | Approve?      |              |
  |     |                   |               +-------------->|              |
  |     |                   |               |               | Grant        |
  |     |<------------------+---------------+---------------+ Access       |
  |     |                                                   |              |
  |     | Connect via Access Manager                        |              |
  |     +-------------------------------------------------->|              |
  |     |                                                   |              |
  |     |                    SESSION RECORDED               |              |
  |     |<=================================================>|              |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  VENDOR ACCESS POLICIES
  ======================

  +-------------------------+----------------------------------------------+
  | Policy Element          | Configuration                                |
  +-------------------------+----------------------------------------------+
  |                         |                                              |
  | Account Validity        | Maximum 1 year, requires renewal             |
  |                         | Automatic deactivation after project end     |
  |                         |                                              |
  +-------------------------+----------------------------------------------+
  |                         |                                              |
  | Authentication          | MFA required (no exceptions)                 |
  |                         | Password: 16+ chars, complex                 |
  |                         | Certificate authentication preferred         |
  |                         |                                              |
  +-------------------------+----------------------------------------------+
  |                         |                                              |
  | Time Restrictions       | Business hours only by default               |
  |                         | After-hours requires special approval        |
  |                         | No access during production peak             |
  |                         |                                              |
  +-------------------------+----------------------------------------------+
  |                         |                                              |
  | Target Restrictions     | Only authorized equipment                    |
  |                         | No lateral movement                          |
  |                         | No access to enterprise systems              |
  |                         |                                              |
  +-------------------------+----------------------------------------------+
  |                         |                                              |
  | Protocol Restrictions   | Only required protocols                      |
  |                         | Block: SSH tunneling, file transfer (unless  |
  |                         |        specifically approved)                |
  |                         |                                              |
  +-------------------------+----------------------------------------------+
  |                         |                                              |
  | Monitoring              | Full session recording (video + keystrokes)  |
  |                         | Real-time monitoring option for critical     |
  |                         | Alert on suspicious commands                 |
  |                         |                                              |
  +-------------------------+----------------------------------------------+
  |                         |                                              |
  | File Transfer           | Disabled by default                          |
  |                         | If required: separate approval, logged       |
  |                         | Malware scan on all uploads                  |
  |                         |                                              |
  +-------------------------+----------------------------------------------+

  --------------------------------------------------------------------------

  EMERGENCY VENDOR ACCESS
  =======================

  +------------------------------------------------------------------------+
  |                                                                        |
  | For urgent equipment issues requiring vendor support:                  |
  |                                                                        |
  | 1. On-call plant manager receives call                                 |
  | 2. Verifies vendor identity (callback to known number)                 |
  | 3. Approves emergency access via WALLIX mobile app                     |
  | 4. Access granted for limited time (2-4 hours)                         |
  | 5. Session actively monitored by OT staff                              |
  | 6. Post-session review required within 24 hours                        |
  |                                                                        |
  | EMERGENCY APPROVAL THRESHOLD:                                          |
  | - Single approver for < 4 hours                                        |
  | - Two approvers for extended access                                    |
  | - Automatic escalation if no response in 15 minutes                    |
  |                                                                        |
  +------------------------------------------------------------------------+

+==============================================================================+
```

---

## Next Steps

Continue to [22 - OT Integration](../22-ot-integration/README.md) for detailed integration configurations.
