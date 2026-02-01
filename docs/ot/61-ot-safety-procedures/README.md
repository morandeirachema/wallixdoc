# 61 - OT Safety Procedures and PAM Integration

This guide covers the integration of WALLIX Bastion PAM with Operational Technology (OT) safety procedures, ensuring that privileged access management supports rather than hinders safety-critical operations.

---

## Table of Contents

1. [OT Safety Overview](#ot-safety-overview)
2. [Safety Architecture](#safety-architecture)
3. [Lockout/Tagout (LOTO) Integration](#lockouttagout-loto-integration)
4. [Safety Instrumented Systems (SIS)](#safety-instrumented-systems-sis)
5. [Change Management for Safety Systems](#change-management-for-safety-systems)
6. [Maintenance Mode Operations](#maintenance-mode-operations)
7. [Emergency Access Procedures](#emergency-access-procedures)
8. [Dual Control and Four-Eyes Principle](#dual-control-and-four-eyes-principle)
9. [Safety Interlocks](#safety-interlocks)
10. [Audit and Compliance](#audit-and-compliance)
11. [Training Requirements](#training-requirements)

---

## OT Safety Overview

### Why Safety Matters in OT Environments

```
+===============================================================================+
|                    OT SAFETY FUNDAMENTALS                                     |
+===============================================================================+

  SAFETY VS SECURITY PRIORITY
  ===========================

  In OT environments, safety takes precedence over security:

  +------------------------------------------------------------------------+
  |                                                                        |
  |   PRIORITY ORDER IN OT                                                 |
  |                                                                        |
  |   1. SAFETY          Personnel and environmental protection            |
  |   2. AVAILABILITY    Production continuity                             |
  |   3. INTEGRITY       Data and process accuracy                         |
  |   4. CONFIDENTIALITY Information protection                            |
  |                                                                        |
  |   CRITICAL PRINCIPLE:                                                  |
  |   PAM must NEVER prevent access to safety systems in emergencies       |
  |   PAM must NEVER delay safety-critical operations                      |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  CONSEQUENCES OF SAFETY FAILURES
  ===============================

  +------------------------------------------------------------------------+
  | Category           | Examples                                          |
  +--------------------+---------------------------------------------------+
  | Personnel Safety   | - Burns, electrocution, chemical exposure         |
  |                    | - Crushing, falls, confined space incidents       |
  |                    | - Fatalities                                      |
  +--------------------+---------------------------------------------------+
  | Environmental      | - Chemical releases, spills                       |
  |                    | - Air/water contamination                         |
  |                    | - Long-term ecological damage                     |
  +--------------------+---------------------------------------------------+
  | Equipment Damage   | - Catastrophic equipment failure                  |
  |                    | - Fire, explosion                                 |
  |                    | - Production line destruction                     |
  +--------------------+---------------------------------------------------+
  | Business Impact    | - Extended downtime (weeks/months)                |
  |                    | - Regulatory fines, license revocation            |
  |                    | - Reputational damage, lawsuits                   |
  +--------------------+---------------------------------------------------+

+===============================================================================+
```

### Regulatory Framework

```
+===============================================================================+
|                    SAFETY REGULATORY REQUIREMENTS                             |
+===============================================================================+

  KEY STANDARDS AND REGULATIONS
  =============================

  +------------------------------------------------------------------------+
  | Standard         | Focus                      | PAM Relevance          |
  +------------------+----------------------------+------------------------+
  | IEC 61508        | Functional Safety of E/E/PE| Safety system access   |
  |                  | Safety-Related Systems     | control and audit      |
  +------------------+----------------------------+------------------------+
  | IEC 62443        | Industrial Automation      | Zone-based access,     |
  |                  | Security                   | authentication, audit  |
  +------------------+----------------------------+------------------------+
  | IEC 61511        | Process Industry Safety    | SIS access controls,   |
  |                  | Instrumented Systems       | bypass management      |
  +------------------+----------------------------+------------------------+
  | OSHA 1910.147    | Control of Hazardous       | LOTO procedures,       |
  |                  | Energy (LOTO)              | verification, audit    |
  +------------------+----------------------------+------------------------+
  | OSHA PSM         | Process Safety Management  | MOC, training,         |
  |                  | (29 CFR 1910.119)          | incident investigation |
  +------------------+----------------------------+------------------------+
  | EPA RMP          | Risk Management Program    | Emergency procedures,  |
  |                  | (40 CFR 68)                | training verification  |
  +------------------+----------------------------+------------------------+
  | NFPA 70E         | Electrical Safety          | Arc flash, LOTO,       |
  |                  |                            | work permits           |
  +------------------+----------------------------+------------------------+
  | ISA 84           | SIS (aligned with          | SIS access, bypass,    |
  |                  | IEC 61511)                 | testing                |
  +------------------+----------------------------+------------------------+

  --------------------------------------------------------------------------

  SAFETY INTEGRITY LEVELS (SIL)
  =============================

  IEC 61508/61511 defines Safety Integrity Levels:

  +------------------------------------------------------------------------+
  | SIL  | PFD (avg)        | Risk Reduction    | PAM Requirements         |
  +------+------------------+-------------------+--------------------------+
  | SIL 1| 0.1 to 0.01      | 10 to 100         | Basic access controls    |
  |      |                  |                   | Session recording        |
  +------+------------------+-------------------+--------------------------+
  | SIL 2| 0.01 to 0.001    | 100 to 1,000      | MFA required             |
  |      |                  |                   | Approval workflows       |
  +------+------------------+-------------------+--------------------------+
  | SIL 3| 0.001 to 0.0001  | 1,000 to 10,000   | Dual authorization       |
  |      |                  |                   | Real-time monitoring     |
  +------+------------------+-------------------+--------------------------+
  | SIL 4| 0.0001 to 0.00001| 10,000 to 100,000 | Maximum controls         |
  |      |                  |                   | Continuous verification  |
  +------+------------------+-------------------+--------------------------+

  PFD = Probability of Failure on Demand (lower = safer)

+===============================================================================+
```

---

## Safety Architecture

### Safety Zones and PAM Integration

```
+===============================================================================+
|                    OT SAFETY ARCHITECTURE                                     |
+===============================================================================+


                   +------------------------------------------+
                   |            ENTERPRISE ZONE               |
                   |          (IT Network - Level 5)          |
                   |                                          |
                   |   [ERP]  [Email]  [Office Apps]          |
                   +-----------------+------------------------+
                                     |
                         +-----------+-----------+
                         |    ENTERPRISE DMZ     |
                         |   WALLIX Access Mgr   |
                         +-----------+-----------+
                                     |
          +==========================+==========================+
          |                     IT/OT DMZ                       |
          |                   (Level 3.5)                       |
          |                                                     |
          |    +===========================================+    |
          |    |        WALLIX BASTION CLUSTER             |    |
          |    |                                           |    |
          |    |   +-------+   +-------+   +-----------+   |    |
          |    |   |Primary|<->|Standby|   |Recording  |   |    |
          |    |   | Node  |   | Node  |   |Storage    |   |    |
          |    |   +-------+   +-------+   +-----------+   |    |
          |    |                                           |    |
          |    +===========================================+    |
          |                                                     |
          +==========================+==========================+
                                     |
          +==========================+==========================+
          |               PROCESS CONTROL ZONE                  |
          |                    (Level 2-3)                      |
          |                                                     |
          |   +---------------+  +---------------+              |
          |   |    SCADA      |  | Engineering   |              |
          |   |   Servers     |  | Workstations  |              |
          |   +-------+-------+  +-------+-------+              |
          |           |                  |                      |
          +===========|==================|======================+
                      |                  |
          +===========|==================|======================+
          |           |   SAFETY ZONE    |                      |
          |           |    (Level 1)     |                      |
          |           |                  |                      |
          |   +-------+-------+  +-------+-------+              |
          |   |     HMI       |  |   Safety      |              |
          |   |   Stations    |  |   PLCs (SIS)  |              |
          |   +---------------+  +-------+-------+              |
          |                              |                      |
          |                      +-------+-------+              |
          |                      | Safety Logic  |              |
          |                      |   Solver      |              |
          |                      +---------------+              |
          |                                                     |
          +==========================+==========================+
                                     |
          +==========================+==========================+
          |                  FIELD ZONE                         |
          |                   (Level 0)                         |
          |                                                     |
          |   +-------+  +-------+  +-------+  +-------+        |
          |   |Sensors|  |  ESD  |  | Final |  | Fire  |        |
          |   |       |  |Valves |  |Elements|  |  Gas  |        |
          |   +-------+  +-------+  +-------+  +-------+        |
          |                                                     |
          +=======================================================+


  LEGEND
  ======

  WALLIX BASTION: Central access point for all OT/Safety access
  Safety PLCs (SIS): Safety Instrumented Systems controllers
  ESD: Emergency Shutdown Devices
  Final Elements: Valves, breakers, actuators controlled by SIS

+===============================================================================+
```

### Access Flow for Safety Systems

```
+===============================================================================+
|                    SAFETY SYSTEM ACCESS FLOW                                  |
+===============================================================================+

  STANDARD ACCESS FLOW (Non-Emergency)
  ====================================

                              +-------------------+
                              |   User Request    |
                              |  (via WALLIX AM)  |
                              +---------+---------+
                                        |
                                        v
                              +-------------------+
                              |   MFA Challenge   |
                              |  (TOTP/Hardware)  |
                              +---------+---------+
                                        |
                                        v
                              +-------------------+
                              | Training Check    |
                              | (Safety cert OK?) |
                              +---------+---------+
                                        |
                         +--------------+---------------+
                         |                              |
                    [Not Valid]                    [Valid]
                         |                              |
                         v                              v
               +-------------------+         +-------------------+
               |   Access Denied   |         | Approval Required?|
               | (Training Needed) |         +---------+---------+
               +-------------------+                   |
                                        +--------------+---------------+
                                        |                              |
                                   [Yes - SIS]                    [No - HMI]
                                        |                              |
                                        v                              v
                              +-------------------+         +-------------------+
                              | Dual Approval     |         | Session Started   |
                              | (2 Approvers)     |         | (With Recording)  |
                              +---------+---------+         +-------------------+
                                        |
                                        v
                              +-------------------+
                              | Session Started   |
                              | (Full Monitoring) |
                              +-------------------+


  EMERGENCY ACCESS FLOW
  =====================

                              +-------------------+
                              | Emergency Event   |
                              | (Safety Incident) |
                              +---------+---------+
                                        |
                                        v
                              +-------------------+
                              |   Break-Glass     |
                              |     Access        |
                              +---------+---------+
                                        |
                                        v
                              +-------------------+
                              |  Single Approver  |
                              | (Shift Supervisor)|
                              +---------+---------+
                                        |
                                        v
                              +-------------------+
                              | Immediate Access  |
                              | (Logged, Alerted) |
                              +---------+---------+
                                        |
                                        v
                              +-------------------+
                              | Post-Incident     |
                              | Review Required   |
                              +-------------------+

+===============================================================================+
```

---

## Lockout/Tagout (LOTO) Integration

### LOTO Overview and PAM Integration

```
+===============================================================================+
|                    LOTO AND PAM INTEGRATION                                   |
+===============================================================================+

  LOTO FUNDAMENTALS
  =================

  Lockout/Tagout (LOTO) is a safety procedure to ensure that dangerous
  machines are properly shut off and not restarted before maintenance
  or servicing is completed.

  +------------------------------------------------------------------------+
  | LOTO Step                | PAM Integration                             |
  +--------------------------+---------------------------------------------+
  | 1. Prepare for shutdown  | Check maintenance window is scheduled       |
  | 2. Notify affected       | ITSM ticket created, approvals obtained     |
  | 3. Equipment shutdown    | Session access granted for authorized user  |
  | 4. Isolation             | Verify LOTO status via integration          |
  | 5. Release stored energy | Session recorded for compliance             |
  | 6. Verify isolation      | Checklist completion logged                 |
  | 7. Apply locks/tags      | LOTO status recorded in PAM metadata        |
  | 8. Perform maintenance   | Maintenance sessions tracked                |
  | 9. Remove locks/tags     | LOTO release logged with verification       |
  | 10. Restore equipment    | Return-to-service session initiated         |
  +--------------------------+---------------------------------------------+

+===============================================================================+
```

### PAM-Enforced LOTO Workflow

```
+===============================================================================+
|                    PAM-ENFORCED LOTO WORKFLOW                                 |
+===============================================================================+

  PHASE 1: LOTO INITIATION
  ========================

  +------------------------------------------------------------------------+
  |                                                                        |
  | PRE-WORK REQUIREMENTS                                                  |
  |                                                                        |
  | [ ] 1. Work order/permit created in ITSM                               |
  | [ ] 2. Job Safety Analysis (JSA) completed                             |
  | [ ] 3. LOTO procedure identified for equipment                         |
  | [ ] 4. Authorized person assigned                                      |
  | [ ] 5. PAM access request submitted                                    |
  |                                                                        |
  +------------------------------------------------------------------------+

  WALLIX Configuration for LOTO Access:
  +------------------------------------------------------------------------+
  | # Authorization for LOTO procedures                                    |
  | Authorization: LOTO-Access                                             |
  |   User Groups: [Maintenance-Technicians]                               |
  |   Target Groups: [Industrial-Control-Systems]                          |
  |   Approval Required: Yes (Shift-Supervisor)                            |
  |   Time Restriction: Maintenance Windows Only                           |
  |   Prerequisites:                                                       |
  |     - Valid LOTO Training Certificate                                  |
  |     - Active Work Permit (via API integration)                         |
  |   Session Recording: Mandatory (Video + Keystroke)                     |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  PHASE 2: ENERGY ISOLATION VERIFICATION
  ======================================

  Integration with LOTO Management System:

  +------------------------------------------------------------------------+
  |                                                                        |
  |   LOTO STATUS CHECK (API Integration)                                  |
  |                                                                        |
  |   +-----------------------------------------------------------------+  |
  |   |  WALLIX                       LOTO System                       |  |
  |   |    |                              |                             |  |
  |   |    |  1. Access Request           |                             |  |
  |   |    +----------------------------->|                             |  |
  |   |    |                              |                             |  |
  |   |    |  2. Check LOTO Status        |                             |  |
  |   |    |<-----------------------------|                             |  |
  |   |    |     Equipment: Pump-001      |                             |  |
  |   |    |     Status: LOCKED OUT       |                             |  |
  |   |    |     Lock #: L-2024-0542      |                             |  |
  |   |    |     Authorized: John Smith   |                             |  |
  |   |    |                              |                             |  |
  |   |    |  3. Verify Lock Owner        |                             |  |
  |   |    +----------------------------->|                             |  |
  |   |    |                              |                             |  |
  |   |    |  4. Owner Confirmed          |                             |  |
  |   |    |<-----------------------------|                             |  |
  |   |    |                              |                             |  |
  |   |    |  5. Grant Access             |                             |  |
  |   |    |                              |                             |  |
  |   +-----------------------------------------------------------------+  |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  PHASE 3: MAINTENANCE SESSION
  ============================

  Session Recording Requirements:
  +------------------------------------------------------------------------+
  | Recording Element        | Captured                                    |
  +--------------------------+---------------------------------------------+
  | Video (RDP/VNC)          | Full screen recording, searchable OCR      |
  | Commands (SSH)           | All commands with timestamps                |
  | File Transfers           | Logged with hash verification              |
  | Duration                 | Start/end times, idle periods              |
  | Metadata                 | Work order #, LOTO lock #, equipment ID    |
  +--------------------------+---------------------------------------------+

  --------------------------------------------------------------------------

  PHASE 4: RETURN-TO-SERVICE
  ==========================

  +------------------------------------------------------------------------+
  |                                                                        |
  | RETURN-TO-SERVICE CHECKLIST                                            |
  |                                                                        |
  | [ ] 1. All maintenance work completed                                  |
  | [ ] 2. Tools and materials removed                                     |
  | [ ] 3. Guards and safety devices reinstalled                           |
  | [ ] 4. Area cleared of personnel                                       |
  | [ ] 5. LOTO locks removed by authorized person                         |
  | [ ] 6. Equipment inspected before energization                         |
  | [ ] 7. Return-to-service approved in WALLIX                            |
  | [ ] 8. Equipment returned to operation                                 |
  |                                                                        |
  +------------------------------------------------------------------------+

  WALLIX Return-to-Service Workflow:
  +------------------------------------------------------------------------+
  | # API endpoint for LOTO release                                        |
  | POST /api/v3.12/loto/release                                           |
  | {                                                                      |
  |   "equipment_id": "PUMP-001",                                          |
  |   "lock_number": "L-2024-0542",                                        |
  |   "released_by": "jsmith",                                             |
  |   "verification_checklist": {                                          |
  |     "work_completed": true,                                            |
  |     "area_cleared": true,                                              |
  |     "guards_installed": true,                                          |
  |     "supervisor_verification": "mjones"                                |
  |   },                                                                   |
  |   "timestamp": "2026-02-01T14:30:00Z"                                  |
  | }                                                                      |
  +------------------------------------------------------------------------+

+===============================================================================+
```

---

## Safety Instrumented Systems (SIS)

### SIS Access Control Requirements

```
+===============================================================================+
|                    SIS ACCESS CONTROLS                                        |
+===============================================================================+

  SIS OVERVIEW
  ============

  Safety Instrumented Systems (SIS) are designed to bring a process to a
  safe state when predetermined conditions are violated. Access to SIS
  must be strictly controlled.

  +------------------------------------------------------------------------+
  | SIS Component          | Access Control Requirements                   |
  +------------------------+-----------------------------------------------+
  | Safety Logic Solver    | - Dual authorization mandatory                |
  |                        | - Engineering mode only during outage         |
  |                        | - All changes require MOC approval            |
  +------------------------+-----------------------------------------------+
  | Safety PLC             | - Read-only access for monitoring             |
  |                        | - Programming requires supervisor approval    |
  |                        | - Firmware changes: Plant manager approval    |
  +------------------------+-----------------------------------------------+
  | ESD System             | - View status: Operations team                |
  |                        | - Reset ESD: Dual approval required           |
  |                        | - Bypass: 4-eyes + time-limited               |
  +------------------------+-----------------------------------------------+
  | Fire & Gas             | - Monitoring: Control room access             |
  |                        | - Configuration: Engineering + Safety mgr     |
  |                        | - Testing: Scheduled maintenance window       |
  +------------------------+-----------------------------------------------+

  --------------------------------------------------------------------------

  WALLIX CONFIGURATION FOR SIS ACCESS
  ===================================

  User Group: SIS-Engineers
  +------------------------------------------------------------------------+
  | # SIS Engineering Access Authorization                                 |
  | Authorization: SIS-Engineering-Access                                  |
  |   User Groups: [SIS-Engineers]                                         |
  |   Target Groups: [SIS-Controllers]                                     |
  |   Approval:                                                            |
  |     Required: Yes                                                      |
  |     Approvers: [Plant-Manager, Safety-Manager]                         |
  |     Minimum Approvals: 2                                               |
  |     Timeout: 30 minutes                                                |
  |   Time Restrictions:                                                   |
  |     Allowed Days: Monday-Friday                                        |
  |     Allowed Hours: 06:00-18:00 (unless emergency)                      |
  |     Maintenance Windows: Required                                      |
  |   Session Settings:                                                    |
  |     Recording: Mandatory                                               |
  |     Real-time Monitoring: Enabled                                      |
  |     Command Restrictions: No format, no firmware flash                 |
  |   Prerequisites:                                                       |
  |     - SIS Training Certificate (current)                               |
  |     - MOC Approval Number                                              |
  |     - Risk Assessment Reference                                        |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### Dual Authorization for SIS Changes

```
+===============================================================================+
|                    DUAL AUTHORIZATION FOR SIS                                 |
+===============================================================================+

  DUAL AUTHORIZATION WORKFLOW
  ===========================


                    +-----------------------+
                    |   Engineer Requests   |
                    |     SIS Access        |
                    +-----------+-----------+
                                |
                                v
                    +-----------------------+
                    |   Request Details     |
                    | - Target: SIS-PLC-01  |
                    | - MOC #: MOC-2024-089 |
                    | - Duration: 2 hours   |
                    | - Purpose: Logic mod  |
                    +-----------+-----------+
                                |
               +----------------+----------------+
               |                                 |
               v                                 v
    +---------------------+          +---------------------+
    |   Approver 1        |          |   Approver 2        |
    |   (Plant Manager)   |          |   (Safety Manager)  |
    +----------+----------+          +----------+----------+
               |                                 |
               v                                 v
    +---------------------+          +---------------------+
    |   Review Request    |          |   Review Request    |
    | - Check MOC status  |          | - Verify risk assmt |
    | - Verify schedule   |          | - Check SIL impact  |
    | - Confirm personnel |          | - Review procedures |
    +----------+----------+          +----------+----------+
               |                                 |
               v                                 v
    +---------------------+          +---------------------+
    |   Approve/Reject    |          |   Approve/Reject    |
    +----------+----------+          +----------+----------+
               |                                 |
               +----------------+----------------+
                                |
                                v
                    +-----------------------+
                    |   Both Approved?      |
                    +-----------+-----------+
                                |
               +----------------+----------------+
               |                                 |
          [No - Rejected]                  [Yes - Approved]
               |                                 |
               v                                 v
    +---------------------+          +---------------------+
    |   Access Denied     |          |   Session Started   |
    |   Notify Engineer   |          | - Real-time monitor |
    +---------------------+          | - Full recording    |
                                     | - Alert on commands |
                                     +---------------------+


  WALLIX 4-EYES CONFIGURATION
  ===========================

  +------------------------------------------------------------------------+
  | # 4-Eyes Approval Policy for SIS                                       |
  | Approval Policy: SIS-Dual-Control                                      |
  |   Approval Groups:                                                     |
  |     - Group 1: [Plant-Managers]                                        |
  |     - Group 2: [Safety-Managers]                                       |
  |   Requirements:                                                        |
  |     - Minimum 1 from each group                                        |
  |     - Cannot self-approve                                              |
  |     - Approvers must have SIS training                                 |
  |   Notification:                                                        |
  |     - Email + SMS to all potential approvers                           |
  |     - Escalation after 15 minutes                                      |
  |   Logging:                                                             |
  |     - Full audit of approval chain                                     |
  |     - Timestamp and IP of each approval                                |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### SIS Bypass Procedures

```
+===============================================================================+
|                    SIS BYPASS PROCEDURES                                      |
+===============================================================================+

  BYPASS PHILOSOPHY
  =================

  SIS bypasses are sometimes necessary for maintenance, testing, or
  process conditions. However, bypasses MUST be:
  - Time-limited
  - Monitored continuously
  - Documented with compensating controls
  - Approved at appropriate management level

  +------------------------------------------------------------------------+
  | Bypass Type          | Approval Level        | Max Duration            |
  +----------------------+-----------------------+-------------------------+
  | Single input bypass  | Shift Supervisor      | 8 hours                 |
  | Multiple input       | Operations Manager    | 24 hours                |
  | Full logic bypass    | Plant Manager +       | 72 hours (with review   |
  |                      | Safety Manager        | every 24 hours)         |
  | Emergency bypass     | Control Room (logged) | Until safe state        |
  +----------------------+-----------------------+-------------------------+

  --------------------------------------------------------------------------

  PAM-CONTROLLED BYPASS WORKFLOW
  ==============================

  +------------------------------------------------------------------------+
  |                                                                        |
  | STEP 1: BYPASS REQUEST                                                 |
  |                                                                        |
  | Engineer initiates bypass request through WALLIX:                      |
  |                                                                        |
  | +-------------------------------------------------------------------+  |
  | | Bypass Request Form                                               |  |
  | | =====================                                             |  |
  | |                                                                   |  |
  | | Equipment: SIS-PLC-01                                             |  |
  | | Function: High-High Level Trip (LAHH-101)                         |  |
  | | Bypass Type: Single Input                                         |  |
  | | Reason: Transmitter calibration                                   |  |
  | | Duration Requested: 4 hours                                       |  |
  | | Compensating Measures:                                            |  |
  | |   [X] Manual monitoring every 15 minutes                          |  |
  | |   [X] Portable alarm installed                                    |  |
  | |   [X] Operator stationed at equipment                             |  |
  | | Work Permit #: WP-2026-0234                                       |  |
  | |                                                                   |  |
  | +-------------------------------------------------------------------+  |
  |                                                                        |
  +------------------------------------------------------------------------+

  +------------------------------------------------------------------------+
  |                                                                        |
  | STEP 2: AUTOMATIC NOTIFICATIONS                                        |
  |                                                                        |
  | WALLIX automatically notifies:                                         |
  | - Control room operators                                               |
  | - Shift supervisor                                                     |
  | - Safety department                                                    |
  | - SIEM/SOC (security correlation)                                      |
  |                                                                        |
  +------------------------------------------------------------------------+

  +------------------------------------------------------------------------+
  |                                                                        |
  | STEP 3: BYPASS ACTIVATION                                              |
  |                                                                        |
  | Upon approval:                                                         |
  | - Bypass timer starts                                                  |
  | - Visual indicator on HMI (flashing)                                   |
  | - Audit log entry created                                              |
  | - Continuous monitoring enabled                                        |
  |                                                                        |
  +------------------------------------------------------------------------+

  +------------------------------------------------------------------------+
  |                                                                        |
  | STEP 4: BYPASS MONITORING                                              |
  |                                                                        |
  | During bypass:                                                         |
  | - 30-minute reminder alerts                                            |
  | - 1-hour supervisor notification                                       |
  | - Auto-escalation at 75% duration                                      |
  | - Automatic removal at expiration (unless extended)                    |
  |                                                                        |
  +------------------------------------------------------------------------+

  +------------------------------------------------------------------------+
  |                                                                        |
  | STEP 5: BYPASS REMOVAL                                                 |
  |                                                                        |
  | When bypass is removed:                                                |
  | - Verification that function is operational                            |
  | - Documentation of bypass period                                       |
  | - All incidents during bypass documented                               |
  | - Final audit log entry                                                |
  |                                                                        |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### Emergency Shutdown Access

```
+===============================================================================+
|                    EMERGENCY SHUTDOWN ACCESS                                  |
+===============================================================================+

  ESD ACCESS REQUIREMENTS
  =======================

  Emergency Shutdown (ESD) systems must be accessible during emergencies
  but protected against unauthorized activation.

  +------------------------------------------------------------------------+
  | ESD Action           | Normal Access         | Emergency Access        |
  +----------------------+-----------------------+-------------------------+
  | View ESD status      | All operators         | All operators           |
  | Reset ESD (after     | Shift Supervisor +    | Control Room +          |
  | safe condition)      | Field Verification    | Field Verification      |
  | Initiate ESD         | Field buttons (no PAM)| Field buttons (no PAM)  |
  | Configure ESD logic  | Engineering (MOC)     | Not during emergency    |
  +----------------------+-----------------------+-------------------------+

  CRITICAL PRINCIPLE:
  ===================
  Physical ESD buttons must NEVER require PAM authentication.
  ESD initiation is a safety function that must be immediate.

  PAM ROLE IN ESD:
  ================
  - Control access to ESD configuration systems
  - Audit ESD reset procedures
  - Track ESD testing and maintenance
  - Document post-incident ESD activities

+===============================================================================+
```

---

## Change Management for Safety Systems

### Management of Change (MOC) Integration

```
+===============================================================================+
|                    MOC AND PAM INTEGRATION                                    |
+===============================================================================+

  MOC WORKFLOW WITH WALLIX
  ========================


                    +-------------------------+
                    |    Change Requested     |
                    |   (Engineering, Maint)  |
                    +------------+------------+
                                 |
                                 v
                    +-------------------------+
                    |   MOC Record Created    |
                    |   in Change Mgmt System |
                    +------------+------------+
                                 |
                                 v
                    +-------------------------+
                    |   Safety Review         |
                    | - Impact on SIS?        |
                    | - SIL verification?     |
                    | - Risk assessment       |
                    +------------+------------+
                                 |
                                 v
                    +-------------------------+
                    |   Approvals Obtained    |
                    | - Engineering Manager   |
                    | - Safety Manager        |
                    | - Operations Manager    |
                    +------------+------------+
                                 |
                                 v
                    +-------------------------+
                    |   WALLIX Access Granted |
                    | - MOC # linked to       |
                    |   authorization         |
                    | - Time-limited access   |
                    +------------+------------+
                                 |
                                 v
                    +-------------------------+
                    |   Change Implemented    |
                    | - Session recorded      |
                    | - Commands logged       |
                    +------------+------------+
                                 |
                                 v
                    +-------------------------+
                    |   Post-Change Testing   |
                    | - FAT/SAT verification  |
                    | - SIS proof test        |
                    +------------+------------+
                                 |
                                 v
                    +-------------------------+
                    |   MOC Closure           |
                    | - Session recordings    |
                    |   attached to MOC       |
                    | - Audit trail complete  |
                    +-------------------------+


  WALLIX MOC INTEGRATION API
  ==========================

  +------------------------------------------------------------------------+
  | # Check MOC status before granting access                              |
  | GET /api/v3.12/external/moc/status                                     |
  | {                                                                      |
  |   "moc_number": "MOC-2026-0089",                                       |
  |   "status": "approved",                                                |
  |   "target_equipment": ["SIS-PLC-01", "SIS-PLC-02"],                    |
  |   "approved_users": ["jsmith", "mjones"],                              |
  |   "valid_from": "2026-02-01T06:00:00Z",                                |
  |   "valid_until": "2026-02-03T18:00:00Z",                               |
  |   "safety_review": {                                                   |
  |     "completed": true,                                                 |
  |     "sil_impact": "none",                                              |
  |     "reviewer": "safety_manager"                                       |
  |   }                                                                    |
  | }                                                                      |
  +------------------------------------------------------------------------+

  +------------------------------------------------------------------------+
  | # Link session to MOC for audit                                        |
  | POST /api/v3.12/sessions/{session_id}/metadata                         |
  | {                                                                      |
  |   "moc_number": "MOC-2026-0089",                                       |
  |   "work_permit": "WP-2026-0234",                                       |
  |   "change_type": "SIS_LOGIC_MODIFICATION"                              |
  | }                                                                      |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### Pre-Change Safety Review

```
+===============================================================================+
|                    PRE-CHANGE SAFETY REVIEW                                   |
+===============================================================================+

  SAFETY REVIEW CHECKLIST
  =======================

  Before any access to safety systems, the following must be verified:

  +------------------------------------------------------------------------+
  |                                                                        |
  | DOCUMENTATION REVIEW                                                   |
  |                                                                        |
  | [ ] MOC approved and current                                           |
  | [ ] Risk assessment completed                                          |
  | [ ] SIL verification (if SIS change)                                   |
  | [ ] Procedure reviewed and approved                                    |
  | [ ] Rollback plan documented                                           |
  |                                                                        |
  +------------------------------------------------------------------------+

  +------------------------------------------------------------------------+
  |                                                                        |
  | PERSONNEL VERIFICATION                                                 |
  |                                                                        |
  | [ ] Personnel have required training certificates                      |
  | [ ] Personnel authorized in MOC                                        |
  | [ ] Buddy system in place (if required)                                |
  | [ ] Communications established                                         |
  |                                                                        |
  +------------------------------------------------------------------------+

  +------------------------------------------------------------------------+
  |                                                                        |
  | SYSTEM PREPARATION                                                     |
  |                                                                        |
  | [ ] Backup of current configuration                                    |
  | [ ] Test environment validated (if applicable)                         |
  | [ ] Monitoring enhanced                                                |
  | [ ] Communications to control room                                     |
  | [ ] Compensating measures in place                                     |
  |                                                                        |
  +------------------------------------------------------------------------+

  WALLIX PREREQUISITE CHECKS
  ==========================

  +------------------------------------------------------------------------+
  | # Authorization prerequisite configuration                             |
  | Authorization: Safety-System-Change                                    |
  |   Prerequisites:                                                       |
  |     - API Check:                                                       |
  |         endpoint: /api/moc/verify                                      |
  |         parameters: { "user": "{user}", "target": "{target}" }         |
  |         expected_result: { "status": "approved" }                      |
  |     - Training Check:                                                  |
  |         required_certs: [SIS-TRAINING, FUNCTIONAL-SAFETY]              |
  |         max_age_days: 365                                              |
  |     - Time Window:                                                     |
  |         check: maintenance_window_active                               |
  |   Failure Action: Deny with message                                    |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### Post-Change Verification

```
+===============================================================================+
|                    POST-CHANGE VERIFICATION                                   |
+===============================================================================+

  VERIFICATION REQUIREMENTS
  =========================

  After any safety system change, verify:

  +------------------------------------------------------------------------+
  | Verification Step        | Method                  | Documentation     |
  +--------------------------+-------------------------+-------------------+
  | Function test            | Simulate input, verify  | Test record       |
  |                          | output                  | signed off        |
  +--------------------------+-------------------------+-------------------+
  | Logic verification       | Review logic vs design  | Engineering       |
  |                          | specification           | sign-off          |
  +--------------------------+-------------------------+-------------------+
  | Alarm test               | Trigger alarms, verify  | Alarm test        |
  |                          | annunciation            | checklist         |
  +--------------------------+-------------------------+-------------------+
  | Integration test         | End-to-end with field   | FAT/SAT           |
  |                          | devices                 | protocol          |
  +--------------------------+-------------------------+-------------------+
  | Documentation update     | P&IDs, cause/effect,    | Revision          |
  |                          | SIS manual              | control           |
  +--------------------------+-------------------------+-------------------+

  SESSION RECORDING ATTACHMENT
  ============================

  +------------------------------------------------------------------------+
  | # Attach session recording to MOC for compliance                       |
  | POST /api/v3.12/moc/{moc_id}/attachments                               |
  | {                                                                      |
  |   "session_id": "sess-2026-02-01-14523",                               |
  |   "attachment_type": "session_recording",                              |
  |   "description": "SIS logic modification session",                     |
  |   "retention": "7_years"                                               |
  | }                                                                      |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### Rollback Procedures

```
+===============================================================================+
|                    ROLLBACK PROCEDURES                                        |
+===============================================================================+

  ROLLBACK TRIGGERS
  =================

  +------------------------------------------------------------------------+
  | Trigger                          | Action                              |
  +----------------------------------+-------------------------------------+
  | Post-change testing fails        | Restore from backup configuration   |
  | Unexpected process behavior      | Revert to previous version          |
  | Safety function not responding   | IMMEDIATE restore, notify safety    |
  | SIL verification fails           | Restore and re-evaluate change      |
  +----------------------------------+-------------------------------------+

  ROLLBACK WORKFLOW
  =================

  +------------------------------------------------------------------------+
  |                                                                        |
  | ROLLBACK CHECKLIST                                                     |
  |                                                                        |
  | [ ] 1. Confirm rollback decision with approvers                        |
  | [ ] 2. Notify control room and affected personnel                      |
  | [ ] 3. Retrieve backup configuration (verified)                        |
  | [ ] 4. Apply rollback through PAM session                              |
  | [ ] 5. Verify restoration of previous function                         |
  | [ ] 6. Document rollback reason and actions                            |
  | [ ] 7. Update MOC status                                               |
  | [ ] 8. Schedule post-incident review                                   |
  |                                                                        |
  +------------------------------------------------------------------------+

  WALLIX ROLLBACK AUTHORIZATION
  =============================

  +------------------------------------------------------------------------+
  | # Emergency rollback authorization                                     |
  | Authorization: Safety-Rollback                                         |
  |   User Groups: [SIS-Engineers, Safety-Managers]                        |
  |   Target Groups: [SIS-Controllers]                                     |
  |   Approval:                                                            |
  |     Required: Yes                                                      |
  |     Approvers: [Safety-Manager, Operations-Manager]                    |
  |     Minimum Approvals: 1 (emergency)                                   |
  |     Timeout: 5 minutes (expedited)                                     |
  |   Priority: High                                                       |
  |   Notification: Immediate to all stakeholders                          |
  +------------------------------------------------------------------------+

+===============================================================================+
```

---

## Maintenance Mode Operations

### Entering Maintenance Mode

```
+===============================================================================+
|                    MAINTENANCE MODE PROCEDURES                                |
+===============================================================================+

  MAINTENANCE MODE OVERVIEW
  =========================

  Maintenance mode is a controlled operational state where:
  - Normal production may be suspended or reduced
  - Safety systems may have approved bypasses
  - Enhanced monitoring is in place
  - Access controls may be modified (documented)

  +------------------------------------------------------------------------+
  | Maintenance Mode State | Access Control Changes                        |
  +------------------------+-----------------------------------------------+
  | Scheduled Maintenance  | - Maintenance team access enabled             |
  |                        | - Vendor access windows activated             |
  |                        | - Production access may be restricted         |
  +------------------------+-----------------------------------------------+
  | Emergency Maintenance  | - Break-glass procedures available            |
  |                        | - Reduced approval requirements               |
  |                        | - All access fully logged                     |
  +------------------------+-----------------------------------------------+
  | Turnaround/Shutdown    | - Broad maintenance access                    |
  |                        | - Safety systems may be de-energized          |
  |                        | - LOTO extensively used                       |
  +------------------------+-----------------------------------------------+

  --------------------------------------------------------------------------

  MAINTENANCE MODE ACTIVATION
  ===========================

  +------------------------------------------------------------------------+
  |                                                                        |
  | STEP 1: Schedule Maintenance Window                                    |
  |                                                                        |
  | POST /api/v3.12/maintenance-window                                     |
  | {                                                                      |
  |   "name": "Pump-Area-Maintenance-Feb2026",                             |
  |   "start_time": "2026-02-15T06:00:00Z",                                |
  |   "end_time": "2026-02-15T18:00:00Z",                                  |
  |   "affected_assets": ["PUMP-001", "PUMP-002", "VLV-101"],              |
  |   "maintenance_type": "scheduled",                                     |
  |   "authorization_changes": {                                           |
  |     "enable_groups": ["Pump-Maintenance-Team"],                        |
  |     "enable_vendors": ["ABB-Service"],                                 |
  |     "restrict_production": true                                        |
  |   },                                                                   |
  |   "approvals": {                                                       |
  |     "operations_manager": "approved",                                  |
  |     "maintenance_manager": "approved"                                  |
  |   }                                                                    |
  | }                                                                      |
  |                                                                        |
  +------------------------------------------------------------------------+

  +------------------------------------------------------------------------+
  |                                                                        |
  | STEP 2: Pre-Maintenance Checklist                                      |
  |                                                                        |
  | [ ] All work permits issued                                            |
  | [ ] LOTO procedures in place                                           |
  | [ ] Affected personnel notified                                        |
  | [ ] Control room informed                                              |
  | [ ] Vendor access credentials verified                                 |
  | [ ] Session recording confirmed active                                 |
  | [ ] Emergency contacts updated                                         |
  |                                                                        |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### Reduced Access During Maintenance

```
+===============================================================================+
|                    ACCESS CONTROL DURING MAINTENANCE                          |
+===============================================================================+

  ACCESS MATRIX DURING MAINTENANCE
  ================================

  +------------------------------------------------------------------------+
  | User Type          | Normal Mode        | Maintenance Mode             |
  +--------------------+--------------------+------------------------------+
  | Production         | Full access        | View-only (safety)           |
  | Operators          |                    |                              |
  +--------------------+--------------------+------------------------------+
  | Maintenance        | Limited/Approved   | Full access to assigned      |
  | Technicians        |                    | equipment                    |
  +--------------------+--------------------+------------------------------+
  | Vendors            | No access          | Time-boxed access to         |
  |                    |                    | specific equipment           |
  +--------------------+--------------------+------------------------------+
  | Engineers          | Read-only          | Programming access           |
  |                    |                    | (with approval)              |
  +--------------------+--------------------+------------------------------+
  | Safety Team        | Monitoring         | Enhanced monitoring +        |
  |                    |                    | bypass management            |
  +--------------------+--------------------+------------------------------+

  WALLIX MAINTENANCE MODE POLICY
  ==============================

  +------------------------------------------------------------------------+
  | # Maintenance window authorization policy                              |
  | Authorization: Maintenance-Window-Access                               |
  |   Condition: maintenance_window_active = true                          |
  |   User Groups: [Maintenance-Team, Approved-Vendors]                    |
  |   Target Groups: [Maintenance-Window-Assets]                           |
  |   Restrictions:                                                        |
  |     - Only assets in maintenance window                                |
  |     - Session recording mandatory                                      |
  |     - File transfer logged                                             |
  |   Auto-Expire: When maintenance window ends                            |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### Maintenance Completion Verification

```
+===============================================================================+
|                    MAINTENANCE COMPLETION                                     |
+===============================================================================+

  COMPLETION CHECKLIST
  ====================

  +------------------------------------------------------------------------+
  |                                                                        |
  | BEFORE EXITING MAINTENANCE MODE                                        |
  |                                                                        |
  | [ ] All work orders closed                                             |
  | [ ] All LOTO locks removed                                             |
  | [ ] All bypasses removed and verified                                  |
  | [ ] Equipment tested and operational                                   |
  | [ ] Area inspected and cleared                                         |
  | [ ] Documentation completed                                            |
  | [ ] Session recordings reviewed (critical work)                        |
  | [ ] Vendor access disabled                                             |
  | [ ] Normal operations readiness confirmed                              |
  |                                                                        |
  +------------------------------------------------------------------------+

  RETURN TO NORMAL OPERATIONS
  ===========================

  +------------------------------------------------------------------------+
  | # Close maintenance window                                             |
  | PUT /api/v3.12/maintenance-window/{window_id}/close                    |
  | {                                                                      |
  |   "closure_verification": {                                            |
  |     "all_work_complete": true,                                         |
  |     "loto_removed": true,                                              |
  |     "bypasses_removed": true,                                          |
  |     "equipment_tested": true,                                          |
  |     "verified_by": "shift_supervisor"                                  |
  |   },                                                                   |
  |   "notes": "All pump maintenance completed successfully",              |
  |   "close_time": "2026-02-15T16:45:00Z"                                 |
  | }                                                                      |
  +------------------------------------------------------------------------+

+===============================================================================+
```

---

## Emergency Access Procedures

### Life-Safety Emergency Access

```
+===============================================================================+
|                    LIFE-SAFETY EMERGENCY ACCESS                               |
+===============================================================================+

  EMERGENCY ACCESS PRINCIPLES
  ===========================

  +------------------------------------------------------------------------+
  |                                                                        |
  | CRITICAL PRINCIPLE                                                     |
  | ==================                                                     |
  |                                                                        |
  | In a life-safety emergency, human safety takes absolute priority.      |
  | PAM must NEVER delay emergency response actions.                       |
  |                                                                        |
  | Emergency access must be:                                              |
  | - Immediate (no waiting for approvals)                                 |
  | - Logged (for post-incident review)                                    |
  | - Audited (within 24 hours)                                            |
  | - Justified (documented reason)                                        |
  |                                                                        |
  +------------------------------------------------------------------------+

  EMERGENCY ACCESS TRIGGERS
  =========================

  +------------------------------------------------------------------------+
  | Emergency Type           | Access Required        | Approval            |
  +--------------------------+------------------------+---------------------+
  | Fire/Explosion           | ESD, Fire suppression  | None (auto-log)     |
  | Chemical release         | Isolation valves, ESD  | None (auto-log)     |
  | Personnel injury         | Equipment isolation    | Shift supervisor    |
  | Process upset (safety)   | Safety system access   | Control room        |
  | Environmental release    | Containment systems    | Shift supervisor    |
  +--------------------------+------------------------+---------------------+

+===============================================================================+
```

### Break-Glass Procedures

```
+===============================================================================+
|                    BREAK-GLASS FOR SAFETY INCIDENTS                           |
+===============================================================================+

  BREAK-GLASS WORKFLOW
  ====================


                    +-------------------------+
                    |    Emergency Declared   |
                    +------------+------------+
                                 |
                                 v
                    +-------------------------+
                    |   Break-Glass Request   |
                    | - Select emergency type |
                    | - Identify target       |
                    +------------+------------+
                                 |
                                 v
                    +-------------------------+
                    |   Shift Supervisor      |
                    |   Acknowledgment        |
                    | (15-second timeout)     |
                    +------------+------------+
                                 |
                    +------------+------------+
                    |                         |
               [Acknowledged]           [Timeout]
                    |                         |
                    v                         v
           +---------------+         +---------------+
           |   Immediate   |         |   Immediate   |
           |    Access     |         |    Access     |
           |   (Logged)    |         | (Auto-logged) |
           +-------+-------+         +-------+-------+
                   |                         |
                   +------------+------------+
                                |
                                v
                    +-------------------------+
                    |   Post-Emergency        |
                    | - Incident report       |
                    | - Access review         |
                    | - Credential rotation   |
                    +-------------------------+


  WALLIX BREAK-GLASS CONFIGURATION
  ================================

  +------------------------------------------------------------------------+
  | # Break-glass authorization                                            |
  | Authorization: Emergency-Break-Glass                                   |
  |   User Groups: [All-Operators, All-Technicians]                        |
  |   Target Groups: [All-Safety-Systems]                                  |
  |   Trigger: emergency_declared = true                                   |
  |   Approval:                                                            |
  |     Mode: Expedited                                                    |
  |     Approvers: [Shift-Supervisors]                                     |
  |     Timeout: 15 seconds (then auto-grant with logging)                 |
  |   Logging:                                                             |
  |     Level: Maximum                                                     |
  |     Recording: Video + Keystroke + Metadata                            |
  |     Retention: 10 years (regulatory)                                   |
  |   Notifications:                                                       |
  |     Immediate: [Control-Room, Safety-Manager, Plant-Manager]           |
  |     Post-Incident: [Compliance, Legal]                                 |
  |   Auto-Expire: 4 hours (requires renewal or incident closure)          |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### Post-Incident Documentation

```
+===============================================================================+
|                    POST-INCIDENT DOCUMENTATION                                |
+===============================================================================+

  DOCUMENTATION REQUIREMENTS
  ==========================

  After any emergency access, document:

  +------------------------------------------------------------------------+
  |                                                                        |
  | IMMEDIATE (Within 24 hours)                                            |
  |                                                                        |
  | [ ] Incident report filed                                              |
  | [ ] All emergency access reviewed                                      |
  | [ ] Session recordings secured                                         |
  | [ ] Credentials rotated (if exposed)                                   |
  | [ ] Preliminary timeline created                                       |
  |                                                                        |
  +------------------------------------------------------------------------+

  +------------------------------------------------------------------------+
  |                                                                        |
  | SHORT-TERM (Within 7 days)                                             |
  |                                                                        |
  | [ ] Detailed incident analysis                                         |
  | [ ] Root cause investigation initiated                                 |
  | [ ] Corrective actions identified                                      |
  | [ ] Session recordings analyzed                                        |
  | [ ] Regulatory notifications (if required)                             |
  |                                                                        |
  +------------------------------------------------------------------------+

  +------------------------------------------------------------------------+
  |                                                                        |
  | LONG-TERM (Within 30 days)                                             |
  |                                                                        |
  | [ ] Root cause analysis completed                                      |
  | [ ] Corrective actions implemented                                     |
  | [ ] Procedures updated                                                 |
  | [ ] Training updated (if needed)                                       |
  | [ ] Lessons learned documented                                         |
  | [ ] Compliance evidence package completed                              |
  |                                                                        |
  +------------------------------------------------------------------------+

  EVIDENCE PACKAGE FOR REGULATORS
  ===============================

  +------------------------------------------------------------------------+
  | # Export compliance evidence package                                   |
  | POST /api/v3.12/incidents/{incident_id}/evidence-package               |
  | {                                                                      |
  |   "include": {                                                         |
  |     "session_recordings": true,                                        |
  |     "audit_logs": true,                                                |
  |     "approval_chain": true,                                            |
  |     "user_training_records": true,                                     |
  |     "authorization_policies": true,                                    |
  |     "system_configuration": true                                       |
  |   },                                                                   |
  |   "time_range": {                                                      |
  |     "start": "2026-02-01T00:00:00Z",                                   |
  |     "end": "2026-02-02T23:59:59Z"                                      |
  |   },                                                                   |
  |   "format": "regulatory_compliance",                                   |
  |   "encryption": "required"                                             |
  | }                                                                      |
  +------------------------------------------------------------------------+

+===============================================================================+
```

---

## Dual Control and Four-Eyes Principle

### Requiring Multiple Approvers

```
+===============================================================================+
|                    DUAL CONTROL REQUIREMENTS                                  |
+===============================================================================+

  DUAL CONTROL OVERVIEW
  =====================

  Dual control (4-eyes principle) requires two independent individuals to
  authorize high-risk actions. This prevents:
  - Single-point-of-compromise attacks
  - Insider threats
  - Accidental critical changes
  - Unauthorized modifications

  +------------------------------------------------------------------------+
  | Action Type                    | Approval Requirement                  |
  +--------------------------------+---------------------------------------+
  | SIS logic modification         | 2 approvers (different departments)  |
  | Safety bypass > 4 hours        | 2 approvers + management              |
  | ESD reset                      | Field + Control room                 |
  | Firmware update (safety PLC)   | Engineering + Safety + Management    |
  | Emergency shutdown override    | 2 supervisors                         |
  | Break-glass credential access  | 1 approver + post-review             |
  +--------------------------------+---------------------------------------+

  WALLIX DUAL APPROVAL CONFIGURATION
  ==================================

  +------------------------------------------------------------------------+
  | # Dual control policy                                                  |
  | Approval Policy: Dual-Control-Safety                                   |
  |   Type: Multi-Group                                                    |
  |   Groups:                                                              |
  |     - Group A: [Operations-Supervisors]                                |
  |       Required: 1                                                      |
  |     - Group B: [Safety-Department]                                     |
  |       Required: 1                                                      |
  |   Constraints:                                                         |
  |     - Same person cannot approve in both groups                        |
  |     - Requester cannot be approver                                     |
  |     - Approvers must have safety training                              |
  |   Timeout:                                                             |
  |     Standard: 30 minutes                                               |
  |     Emergency: 5 minutes (then escalate)                               |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### Witness Verification

```
+===============================================================================+
|                    WITNESS VERIFICATION                                       |
+===============================================================================+

  WITNESS REQUIREMENTS
  ====================

  For critical safety operations, a witness must verify actions:

  +------------------------------------------------------------------------+
  | Operation                  | Witness Requirement                       |
  +----------------------------+-------------------------------------------+
  | SIS proof testing          | Independent witness (not test performer)  |
  | LOTO application           | Second authorized person verifies         |
  | LOTO removal               | Original lock owner + supervisor          |
  | Safety system commissioning| Safety engineer + Operations              |
  | Configuration restore      | Engineering + Safety verification         |
  +----------------------------+-------------------------------------------+

  WALLIX WITNESS WORKFLOW
  =======================

  +------------------------------------------------------------------------+
  |                                                                        |
  | WITNESS VERIFICATION PROCESS                                           |
  |                                                                        |
  |   1. Primary user initiates session                                    |
  |   2. WALLIX prompts for witness verification                           |
  |   3. Witness authenticates (separate credentials)                      |
  |   4. Session begins with dual monitoring                               |
  |   5. Critical actions require witness confirmation                     |
  |   6. Session recording shows both participants                         |
  |                                                                        |
  +------------------------------------------------------------------------+

  +------------------------------------------------------------------------+
  | # Witness verification authorization                                   |
  | Authorization: Safety-With-Witness                                     |
  |   User Groups: [Safety-Technicians]                                    |
  |   Target Groups: [SIS-Testing-Interfaces]                              |
  |   Witness Required: true                                               |
  |   Witness Groups: [Safety-Engineers, Operations-Supervisors]           |
  |   Witness Constraints:                                                 |
  |     - Cannot be same person as primary                                 |
  |     - Must have SIS training                                           |
  |     - Must be on-site                                                  |
  |   Session Settings:                                                    |
  |     - Witness login tracked                                            |
  |     - All actions attributed to primary                                |
  |     - Witness acknowledgment for critical steps                        |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### Real-Time Supervision

```
+===============================================================================+
|                    REAL-TIME SUPERVISION                                      |
+===============================================================================+

  SUPERVISION REQUIREMENTS
  ========================

  Certain operations require real-time supervision by authorized personnel:

  +------------------------------------------------------------------------+
  | Operation               | Supervisor Role          | WALLIX Feature    |
  +-------------------------+--------------------------+-------------------+
  | Vendor maintenance      | Monitor all commands     | Live session view |
  | SIS modifications       | Verify each step         | Session shadowing |
  | Emergency procedures    | Guide actions            | Real-time chat    |
  | Training/mentoring      | Observe and coach        | Observer mode     |
  +-------------------------+--------------------------+-------------------+

  LIVE SESSION MONITORING
  =======================

  +------------------------------------------------------------------------+
  |                                                                        |
  | SUPERVISOR MONITORING INTERFACE                                        |
  |                                                                        |
  | +----------------------------------------------------------------+    |
  | |  Active Sessions - Safety Systems                              |    |
  | +----------------------------------------------------------------+    |
  | |                                                                |    |
  | |  Session: SESS-2026-0201-14523                                 |    |
  | |  User: jsmith (Maintenance Technician)                         |    |
  | |  Target: SIS-PLC-01 (Safety PLC)                               |    |
  | |  Duration: 00:23:45                                            |    |
  | |  Status: ACTIVE - MONITORED                                    |    |
  | |                                                                |    |
  | |  [View Live]  [Shadow Session]  [Send Message]  [Terminate]    |    |
  | |                                                                |    |
  | |  Recent Commands:                                              |    |
  | |  14:23:12 - READ_CONFIG block_1                                |    |
  | |  14:24:05 - DOWNLOAD_PROJECT                                   |    |
  | |  14:24:45 - MODIFY_BLOCK safety_trip_1      <-- ALERT          |    |
  | |                                                                |    |
  | +----------------------------------------------------------------+    |
  |                                                                        |
  +------------------------------------------------------------------------+

  ALERT-ON-COMMAND CONFIGURATION
  ==============================

  +------------------------------------------------------------------------+
  | # Alert configuration for safety-critical commands                     |
  | Alert Rule: SIS-Critical-Commands                                      |
  |   Target Groups: [SIS-Controllers]                                     |
  |   Commands:                                                            |
  |     - Pattern: "MODIFY_BLOCK|DOWNLOAD|UPLOAD|FORMAT|FIRMWARE"          |
  |     - Severity: Critical                                               |
  |   Actions:                                                             |
  |     - Notify: [Safety-Supervisors, Control-Room]                       |
  |     - Highlight: In monitoring interface                               |
  |     - Log: Enhanced detail level                                       |
  |   Response Options:                                                    |
  |     - Allow (with acknowledgment)                                      |
  |     - Block (requires override)                                        |
  |     - Terminate session                                                |
  +------------------------------------------------------------------------+

+===============================================================================+
```

---

## Safety Interlocks

### PAM Integration with Safety PLCs

```
+===============================================================================+
|                    SAFETY INTERLOCK INTEGRATION                               |
+===============================================================================+

  INTERLOCK OVERVIEW
  ==================

  Safety interlocks are protective mechanisms that prevent unsafe operations.
  PAM can integrate with interlock systems to:
  - Verify interlock status before granting access
  - Prevent access to equipment with active interlocks
  - Document interlock overrides

  +------------------------------------------------------------------------+
  | Interlock Type          | PAM Integration                              |
  +-------------------------+----------------------------------------------+
  | Equipment interlock     | Check status before maintenance access       |
  | Process interlock       | Verify safe state before engineering access  |
  | Safety interlock (SIS)  | Require bypass approval before access        |
  | Personnel interlock     | Verify area clearance before energization    |
  +-------------------------+----------------------------------------------+

  INTERLOCK STATUS CHECK
  ======================

  +------------------------------------------------------------------------+
  | # Check interlock status via API before access                         |
  | GET /api/v3.12/external/interlocks/status                              |
  | {                                                                      |
  |   "equipment_id": "PUMP-001",                                          |
  |   "interlocks": [                                                      |
  |     {                                                                  |
  |       "id": "IL-001",                                                  |
  |       "description": "High pressure trip",                             |
  |       "status": "ARMED",                                               |
  |       "safe_for_maintenance": false                                    |
  |     },                                                                 |
  |     {                                                                  |
  |       "id": "IL-002",                                                  |
  |       "description": "Vibration trip",                                 |
  |       "status": "BYPASSED",                                            |
  |       "bypass_reason": "Sensor replacement",                           |
  |       "bypass_expires": "2026-02-01T18:00:00Z",                        |
  |       "safe_for_maintenance": true                                     |
  |     }                                                                  |
  |   ],                                                                   |
  |   "overall_safe_for_maintenance": false                                |
  | }                                                                      |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### Interlock Verification Before Access

```
+===============================================================================+
|                    INTERLOCK VERIFICATION                                     |
+===============================================================================+

  VERIFICATION WORKFLOW
  =====================


            +---------------------------+
            |  Access Request to        |
            |  Equipment (PUMP-001)     |
            +-------------+-------------+
                          |
                          v
            +---------------------------+
            |  Query Interlock Status   |
            |  (API to Safety System)   |
            +-------------+-------------+
                          |
             +------------+------------+
             |                         |
        [Safe State]            [Active Interlock]
             |                         |
             v                         v
   +-------------------+     +-------------------+
   |  Access Granted   |     |  Access Blocked   |
   |  (Standard flow)  |     |  Show interlock   |
   +-------------------+     |  status & options |
                             +---------+---------+
                                       |
                          +------------+------------+
                          |                         |
                     [Request                 [Cancel
                      Bypass]                  Request]
                          |                         |
                          v                         v
            +---------------------------+  +------------------+
            |  Bypass Approval Flow     |  |  Access Denied   |
            |  (Dual authorization)     |  +------------------+
            +-------------+-------------+
                          |
                          v
            +---------------------------+
            |  Access Granted           |
            |  (With bypass monitoring) |
            +---------------------------+


  WALLIX INTERLOCK INTEGRATION
  ============================

  +------------------------------------------------------------------------+
  | # Authorization with interlock check                                   |
  | Authorization: Equipment-Maintenance                                   |
  |   Prerequisites:                                                       |
  |     - Interlock Check:                                                 |
  |         api_endpoint: /api/interlocks/status                           |
  |         parameters: { "equipment": "{target.equipment_id}" }           |
  |         condition: "overall_safe_for_maintenance == true"              |
  |     - If Condition Fails:                                              |
  |         action: "prompt_for_bypass"                                    |
  |         bypass_authorization: "Interlock-Bypass"                       |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### Permit-to-Work Integration

```
+===============================================================================+
|                    PERMIT-TO-WORK INTEGRATION                                 |
+===============================================================================+

  PERMIT-TO-WORK OVERVIEW
  =======================

  Permit-to-Work (PTW) systems ensure safe work execution by documenting
  hazards, precautions, and authorizations. PAM integration ensures:
  - Access only granted with valid permit
  - Session linked to permit for audit
  - Automatic access revocation when permit expires

  +------------------------------------------------------------------------+
  | Permit Type              | PAM Integration                             |
  +--------------------------+---------------------------------------------+
  | Hot Work Permit          | Verify active before welding system access  |
  | Confined Space Entry     | Check atmosphere tests, rescue plan         |
  | Electrical Work Permit   | Verify LOTO in place                        |
  | Excavation Permit        | Confirm underground checks complete         |
  | General Work Permit      | Basic authorization verification            |
  +--------------------------+---------------------------------------------+

  PTW VERIFICATION FLOW
  =====================

  +------------------------------------------------------------------------+
  | # Permit verification API call                                         |
  | GET /api/v3.12/external/permits/verify                                 |
  | Request:                                                               |
  | {                                                                      |
  |   "permit_number": "PTW-2026-0542",                                    |
  |   "user": "jsmith",                                                    |
  |   "equipment": "PUMP-001"                                              |
  | }                                                                      |
  |                                                                        |
  | Response:                                                              |
  | {                                                                      |
  |   "permit_valid": true,                                                |
  |   "permit_type": "electrical_work",                                    |
  |   "hazards_identified": ["electrical_shock", "arc_flash"],             |
  |   "precautions_required": ["LOTO", "PPE_arc_rated"],                   |
  |   "valid_from": "2026-02-01T06:00:00Z",                                |
  |   "valid_until": "2026-02-01T18:00:00Z",                               |
  |   "authorized_personnel": ["jsmith", "mjones"],                        |
  |   "supervisor": "rjohnson",                                            |
  |   "loto_reference": "LOTO-2026-0234"                                   |
  | }                                                                      |
  +------------------------------------------------------------------------+

  WALLIX PTW AUTHORIZATION
  ========================

  +------------------------------------------------------------------------+
  | # Authorization requiring valid permit                                 |
  | Authorization: Permit-Required-Access                                  |
  |   Prerequisites:                                                       |
  |     - Permit Check:                                                    |
  |         api_endpoint: /api/permits/verify                              |
  |         parameters:                                                    |
  |           permit_number: "{request.permit_number}"                     |
  |           user: "{user.name}"                                          |
  |           equipment: "{target.equipment_id}"                           |
  |         condition: "permit_valid == true"                              |
  |   Session Metadata:                                                    |
  |     - permit_number: "{request.permit_number}"                         |
  |     - permit_type: "{permit.type}"                                     |
  |     - supervisor: "{permit.supervisor}"                                |
  |   Auto-Expire:                                                         |
  |     - When: permit.valid_until reached                                 |
  |     - Action: Terminate session with warning                           |
  +------------------------------------------------------------------------+

+===============================================================================+
```

---

## Audit and Compliance

### Safety Audit Trails

```
+===============================================================================+
|                    SAFETY AUDIT TRAILS                                        |
+===============================================================================+

  AUDIT REQUIREMENTS
  ==================

  Safety-related access requires comprehensive audit trails for:
  - Regulatory compliance (OSHA, EPA, industry standards)
  - Incident investigation
  - Continuous improvement
  - Legal protection

  +------------------------------------------------------------------------+
  | Audit Element           | Retention        | Access                    |
  +-------------------------+------------------+---------------------------+
  | Session recordings      | 7-10 years       | Safety/Compliance/Legal   |
  | Access logs             | 7-10 years       | Security/Compliance       |
  | Approval chains         | 7-10 years       | Compliance/Management     |
  | Configuration changes   | Life of equipment| Engineering/Safety        |
  | Training records        | Employment + 5y  | HR/Safety/Compliance      |
  | Bypass records          | 10 years         | Safety/Regulatory         |
  +-------------------------+------------------+---------------------------+

  AUDIT LOG CONTENT
  =================

  +------------------------------------------------------------------------+
  | # Safety system access log entry                                       |
  | {                                                                      |
  |   "timestamp": "2026-02-01T14:23:45.123Z",                             |
  |   "event_type": "session_start",                                       |
  |   "user": {                                                            |
  |     "id": "jsmith",                                                    |
  |     "full_name": "John Smith",                                         |
  |     "department": "Maintenance",                                       |
  |     "training_certs": ["SIS-001", "LOTO-002", "SAFETY-003"]            |
  |   },                                                                   |
  |   "target": {                                                          |
  |     "id": "SIS-PLC-01",                                                |
  |     "type": "Safety_PLC",                                              |
  |     "sil_level": 3,                                                    |
  |     "location": "Unit-2-Control-Room"                                  |
  |   },                                                                   |
  |   "authorization": {                                                   |
  |     "policy": "SIS-Engineering-Access",                                |
  |     "approvers": ["mjones", "rjohnson"],                               |
  |     "moc_reference": "MOC-2026-0089",                                  |
  |     "work_permit": "PTW-2026-0542"                                     |
  |   },                                                                   |
  |   "session": {                                                         |
  |     "id": "SESS-2026-0201-14523",                                      |
  |     "protocol": "SSH",                                                 |
  |     "recording": true,                                                 |
  |     "monitoring": "real_time"                                          |
  |   },                                                                   |
  |   "source": {                                                          |
  |     "ip": "10.20.30.40",                                               |
  |     "hostname": "ENG-WS-05"                                            |
  |   }                                                                    |
  | }                                                                      |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### OSHA/Regulatory Evidence

```
+===============================================================================+
|                    REGULATORY EVIDENCE GENERATION                             |
+===============================================================================+

  OSHA PSM EVIDENCE (29 CFR 1910.119)
  ===================================

  +------------------------------------------------------------------------+
  | PSM Element             | WALLIX Evidence                              |
  +-------------------------+----------------------------------------------+
  | Employee Participation  | Training verification, access records        |
  | Process Safety Info     | Access to P&ID systems logged                |
  | Process Hazard Analysis | PHA review session recordings                |
  | Operating Procedures    | Procedure access and compliance logs         |
  | Training                | Training certificate verification            |
  | Contractors             | Vendor session recordings, approvals         |
  | Pre-Startup Review      | Commissioning session recordings             |
  | Mechanical Integrity    | Maintenance access logs, work orders         |
  | Hot Work                | Hot work permit verification                 |
  | MOC                     | Change implementation recordings             |
  | Incident Investigation  | Session recordings, audit trails             |
  | Emergency Planning      | Emergency access logs, drill records         |
  | Compliance Audits       | Complete audit trail export                  |
  +-------------------------+----------------------------------------------+

  EVIDENCE EXPORT
  ===============

  +------------------------------------------------------------------------+
  | # Export OSHA PSM compliance evidence                                  |
  | POST /api/v3.12/compliance/export                                      |
  | {                                                                      |
  |   "standard": "OSHA_PSM",                                              |
  |   "time_range": {                                                      |
  |     "start": "2025-02-01T00:00:00Z",                                   |
  |     "end": "2026-02-01T23:59:59Z"                                      |
  |   },                                                                   |
  |   "elements": [                                                        |
  |     "training_verification",                                           |
  |     "contractor_access",                                               |
  |     "moc_sessions",                                                    |
  |     "emergency_access",                                                |
  |     "hot_work_permits"                                                 |
  |   ],                                                                   |
  |   "format": "regulatory_package",                                      |
  |   "include_recordings": true                                           |
  | }                                                                      |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### Incident Investigation Support

```
+===============================================================================+
|                    INCIDENT INVESTIGATION SUPPORT                             |
+===============================================================================+

  INVESTIGATION DATA SOURCES
  ==========================

  +------------------------------------------------------------------------+
  | Data Source             | Information Provided                         |
  +-------------------------+----------------------------------------------+
  | Session recordings      | Exact actions taken, commands issued         |
  | Audit logs              | Who, what, when, where                       |
  | Approval records        | Authorization chain, approvers               |
  | Training records        | Competency at time of incident               |
  | Configuration history   | Changes made, previous state                 |
  | Alert history           | Warnings that may have been ignored          |
  +-------------------------+----------------------------------------------+

  INVESTIGATION WORKFLOW
  ======================

  +------------------------------------------------------------------------+
  |                                                                        |
  | STEP 1: IDENTIFY RELEVANT SESSIONS                                     |
  |                                                                        |
  | # Search for sessions related to incident                              |
  | GET /api/v3.12/sessions/search                                         |
  | {                                                                      |
  |   "time_range": {                                                      |
  |     "start": "2026-02-01T12:00:00Z",                                   |
  |     "end": "2026-02-01T16:00:00Z"                                      |
  |   },                                                                   |
  |   "targets": ["PUMP-001", "SIS-PLC-01", "HMI-STATION-05"],             |
  |   "include_recordings": true                                           |
  | }                                                                      |
  |                                                                        |
  +------------------------------------------------------------------------+

  +------------------------------------------------------------------------+
  |                                                                        |
  | STEP 2: REVIEW SESSION CONTENT                                         |
  |                                                                        |
  | For each identified session:                                           |
  | - Review video recording                                               |
  | - Search keystroke logs                                                |
  | - Identify commands that may have contributed                          |
  | - Note any warnings or alerts during session                           |
  |                                                                        |
  +------------------------------------------------------------------------+

  +------------------------------------------------------------------------+
  |                                                                        |
  | STEP 3: GENERATE INVESTIGATION REPORT                                  |
  |                                                                        |
  | POST /api/v3.12/investigation/report                                   |
  | {                                                                      |
  |   "incident_id": "INC-2026-0023",                                      |
  |   "sessions": ["SESS-001", "SESS-002", "SESS-003"],                    |
  |   "include": {                                                         |
  |     "user_details": true,                                              |
  |     "approval_chains": true,                                           |
  |     "training_status": true,                                           |
  |     "command_sequences": true,                                         |
  |     "configuration_changes": true,                                     |
  |     "alert_history": true                                              |
  |   },                                                                   |
  |   "format": "investigation_package"                                    |
  | }                                                                      |
  |                                                                        |
  +------------------------------------------------------------------------+

+===============================================================================+
```

---

## Training Requirements

### Safety Training Verification

```
+===============================================================================+
|                    TRAINING VERIFICATION                                      |
+===============================================================================+

  TRAINING REQUIREMENTS
  =====================

  +------------------------------------------------------------------------+
  | Role                    | Required Training              | Validity    |
  +-------------------------+--------------------------------+-------------+
  | OT Operator             | Basic Safety Orientation       | 1 year      |
  |                         | HMI Operation                  | 2 years     |
  +-------------------------+--------------------------------+-------------+
  | Maintenance Technician  | Basic Safety Orientation       | 1 year      |
  |                         | LOTO Procedures                | 1 year      |
  |                         | Equipment-Specific Training    | 2 years     |
  +-------------------------+--------------------------------+-------------+
  | Instrument Technician   | Basic Safety Orientation       | 1 year      |
  |                         | SIS Awareness                  | 1 year      |
  |                         | Calibration Procedures         | 2 years     |
  +-------------------------+--------------------------------+-------------+
  | SIS Engineer            | Functional Safety (TUV/exida)  | 3 years     |
  |                         | SIS Design and Maintenance     | 2 years     |
  |                         | Vendor-Specific Certification  | As required |
  +-------------------------+--------------------------------+-------------+
  | Vendor/Contractor       | Site Safety Orientation        | Per visit   |
  |                         | Equipment-Specific Training    | Current     |
  +-------------------------+--------------------------------+-------------+

  WALLIX TRAINING INTEGRATION
  ===========================

  +------------------------------------------------------------------------+
  | # Training verification in authorization                               |
  | Authorization: SIS-Access                                              |
  |   Prerequisites:                                                       |
  |     Training Requirements:                                             |
  |       - Certificate: "FUNCTIONAL_SAFETY"                               |
  |         Max Age: 1095 days (3 years)                                   |
  |       - Certificate: "SIS_MAINTENANCE"                                 |
  |         Max Age: 730 days (2 years)                                    |
  |       - Certificate: "VENDOR_SPECIFIC"                                 |
  |         Vendor: "{target.vendor}"                                      |
  |         Current: true                                                  |
  |     API Verification:                                                  |
  |       Endpoint: /api/training/verify                                   |
  |       Parameters:                                                      |
  |         user: "{user.id}"                                              |
  |         certificates: ["FUNCTIONAL_SAFETY", "SIS_MAINTENANCE"]         |
  |     On Failure:                                                        |
  |       Action: Deny                                                     |
  |       Message: "Training requirements not met"                         |
  |       Notification: [Training-Department, User-Manager]                |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### Certification Tracking

```
+===============================================================================+
|                    CERTIFICATION TRACKING                                     |
+===============================================================================+

  CERTIFICATION DATABASE INTEGRATION
  ==================================

  +------------------------------------------------------------------------+
  | # Query user certifications                                            |
  | GET /api/v3.12/users/{user_id}/certifications                          |
  | Response:                                                              |
  | {                                                                      |
  |   "user_id": "jsmith",                                                 |
  |   "certifications": [                                                  |
  |     {                                                                  |
  |       "id": "CERT-001",                                                |
  |       "type": "FUNCTIONAL_SAFETY",                                     |
  |       "provider": "TUV_Rheinland",                                     |
  |       "level": "FS_Engineer",                                          |
  |       "issued_date": "2024-05-15",                                     |
  |       "expiry_date": "2027-05-15",                                     |
  |       "status": "valid"                                                |
  |     },                                                                 |
  |     {                                                                  |
  |       "id": "CERT-002",                                                |
  |       "type": "SIS_MAINTENANCE",                                       |
  |       "provider": "Company_Internal",                                  |
  |       "level": "Advanced",                                             |
  |       "issued_date": "2025-03-20",                                     |
  |       "expiry_date": "2027-03-20",                                     |
  |       "status": "valid"                                                |
  |     },                                                                 |
  |     {                                                                  |
  |       "id": "CERT-003",                                                |
  |       "type": "LOTO_AUTHORIZED",                                       |
  |       "provider": "Company_Internal",                                  |
  |       "issued_date": "2025-01-10",                                     |
  |       "expiry_date": "2026-01-10",                                     |
  |       "status": "expiring_soon"                                        |
  |     }                                                                  |
  |   ]                                                                    |
  | }                                                                      |
  +------------------------------------------------------------------------+

  EXPIRATION ALERTS
  =================

  +------------------------------------------------------------------------+
  | # Certification expiration monitoring                                  |
  | Alert Rule: Certification-Expiring                                     |
  |   Check Frequency: Daily                                               |
  |   Conditions:                                                          |
  |     - Certificate expires within 30 days                               |
  |     - Certificate required for active authorizations                   |
  |   Actions:                                                             |
  |     30 days: Email user and manager                                    |
  |     14 days: Email user, manager, training department                  |
  |     7 days: Email all + highlight in access requests                   |
  |     0 days: Disable affected authorizations                            |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### Training Expiration Handling

```
+===============================================================================+
|                    TRAINING EXPIRATION HANDLING                               |
+===============================================================================+

  EXPIRATION WORKFLOW
  ===================


              +---------------------------+
              | Training Certificate      |
              | Approaching Expiration    |
              +-------------+-------------+
                            |
              +-------------+-------------+
              |             |             |
         [30 Days]     [14 Days]     [7 Days]
              |             |             |
              v             v             v
       +-----------+  +-----------+  +-----------+
       |  Notify   |  |  Notify   |  |  Notify   |
       |  User +   |  | + Training|  | + Manager |
       |  Manager  |  |   Dept    |  | Warning   |
       +-----------+  +-----------+  +-----------+
                            |
                            v
              +---------------------------+
              |       Expiration Day      |
              +-------------+-------------+
                            |
              +-------------+-------------+
              |                           |
         [Renewed]                 [Not Renewed]
              |                           |
              v                           v
       +-------------+           +---------------+
       | Access      |           | Authorization |
       | Continues   |           | Suspended     |
       +-------------+           +-------+-------+
                                         |
                                         v
                                +---------------+
                                | Grace Period  |
                                | (If critical) |
                                +-------+-------+
                                         |
                                         v
                                +---------------+
                                | Full Access   |
                                | Revocation    |
                                +---------------+


  GRACE PERIOD FOR CRITICAL ROLES
  ================================

  +------------------------------------------------------------------------+
  | # Grace period policy for safety-critical certifications               |
  | Policy: Safety-Training-Grace                                          |
  |   Conditions:                                                          |
  |     - User is critical safety personnel                                |
  |     - Training scheduled within 14 days                                |
  |     - Manager approval obtained                                        |
  |   Grace Period: 14 days maximum                                        |
  |   Restrictions During Grace:                                           |
  |     - No SIS modifications                                             |
  |     - Supervised access only                                           |
  |     - Enhanced monitoring                                              |
  |   Documentation:                                                       |
  |     - Grace period approval logged                                     |
  |     - Training completion verified                                     |
  +------------------------------------------------------------------------+

+===============================================================================+
```

---

## Compliance Mapping

### Standards Compliance Matrix

```
+===============================================================================+
|                    COMPLIANCE MAPPING                                         |
+===============================================================================+

  WALLIX SAFETY COMPLIANCE MATRIX
  ================================

  +------------------------------------------------------------------------+
  | Standard        | Requirement              | WALLIX Capability         |
  +-----------------+--------------------------+---------------------------+
  | IEC 61508       | Competency management    | Training verification     |
  |                 | Access control           | Authorization policies    |
  |                 | Modification tracking    | Session recording, audit  |
  |                 | Documentation            | Compliance reports        |
  +-----------------+--------------------------+---------------------------+
  | IEC 62443       | Zone-based access        | Authorization by zone     |
  |                 | Authentication (FR1)     | MFA, certificate auth     |
  |                 | Authorization (FR2)      | RBAC, approval workflows  |
  |                 | Audit (FR2)              | Session recording         |
  +-----------------+--------------------------+---------------------------+
  | IEC 61511       | SIS access control       | Dual authorization        |
  |                 | Bypass management        | Time-limited bypass       |
  |                 | Proof test support       | Witness verification      |
  |                 | Change management        | MOC integration           |
  +-----------------+--------------------------+---------------------------+
  | OSHA 1910.147   | LOTO verification        | LOTO system integration   |
  |                 | Authorized personnel     | Training verification     |
  |                 | Documentation            | Complete audit trail      |
  +-----------------+--------------------------+---------------------------+
  | OSHA PSM        | Training records         | Training verification     |
  |                 | Contractor controls      | Vendor access management  |
  |                 | MOC                      | MOC integration           |
  |                 | Incident investigation   | Session recordings        |
  +-----------------+--------------------------+---------------------------+
  | NFPA 70E        | Qualified persons        | Training verification     |
  |                 | Energized work permits   | PTW integration           |
  |                 | LOTO                     | LOTO verification         |
  +-----------------+--------------------------+---------------------------+

+===============================================================================+
```

---

## Summary

This guide covers the integration of WALLIX Bastion PAM with OT safety procedures:

1. **Safety Overview**: Regulatory requirements, safety-first principles
2. **Safety Architecture**: Zone-based access, safety system placement
3. **LOTO Integration**: PAM-enforced lockout/tagout workflows
4. **SIS Access**: Dual authorization, bypass management, ESD access
5. **Change Management**: MOC integration, pre/post-change verification
6. **Maintenance Mode**: Controlled access during maintenance windows
7. **Emergency Access**: Break-glass procedures, post-incident documentation
8. **Dual Control**: 4-eyes principle, witness verification, real-time supervision
9. **Safety Interlocks**: Integration with interlock systems, permit-to-work
10. **Audit and Compliance**: Complete audit trails, regulatory evidence
11. **Training**: Verification, certification tracking, expiration handling

---

## External References

- IEC 61508: Functional Safety of E/E/PE Safety-Related Systems - [https://webstore.iec.ch/publication/5515](https://webstore.iec.ch/publication/5515)
- IEC 62443: Industrial Communication Networks Security - [https://webstore.iec.ch/publication/7029](https://webstore.iec.ch/publication/7029)
- IEC 61511: Functional Safety - Process Industries - [https://webstore.iec.ch/publication/5527](https://webstore.iec.ch/publication/5527)
- OSHA 1910.147: Control of Hazardous Energy (LOTO) - [https://www.osha.gov/laws-regs/regulations/standardnumber/1910/1910.147](https://www.osha.gov/laws-regs/regulations/standardnumber/1910/1910.147)
- OSHA PSM (29 CFR 1910.119): Process Safety Management - [https://www.osha.gov/laws-regs/regulations/standardnumber/1910/1910.119](https://www.osha.gov/laws-regs/regulations/standardnumber/1910/1910.119)
- NFPA 70E: Electrical Safety in the Workplace - [https://www.nfpa.org/codes-and-standards/all-codes-and-standards/list-of-codes-and-standards/detail?code=70E](https://www.nfpa.org/codes-and-standards/all-codes-and-standards/list-of-codes-and-standards/detail?code=70E)
- WALLIX Documentation Portal - [https://pam.wallix.one/documentation](https://pam.wallix.one/documentation)
- ISA/IEC 62443 Cybersecurity Certificate Program - [https://www.isa.org/certification/certificate-programs/cybersecurity](https://www.isa.org/certification/certificate-programs/cybersecurity)

---

## Next Steps

Continue to [62 - OT Compliance Frameworks](../62-ot-compliance-frameworks/README.md) for detailed compliance framework implementations.
