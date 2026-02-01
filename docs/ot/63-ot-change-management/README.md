# 63 - OT Change Management and PAM Integration

## Table of Contents

1. [OT Change Management Overview](#ot-change-management-overview)
2. [Change Management Architecture](#change-management-architecture)
3. [Change Classification](#change-classification)
4. [Change Windows](#change-windows)
5. [Change Request Workflow](#change-request-workflow)
6. [Pre-Change Procedures](#pre-change-procedures)
7. [Change Execution](#change-execution)
8. [Post-Change Verification](#post-change-verification)
9. [Rollback Procedures](#rollback-procedures)
10. [Emergency Changes](#emergency-changes)
11. [Audit and Compliance](#audit-and-compliance)
12. [ITSM Integration](#itsm-integration)

---

## OT Change Management Overview

### Why OT Change Management Differs from IT

```
+===============================================================================+
|                 OT VS IT CHANGE MANAGEMENT                                    |
+===============================================================================+

  IT CHANGE MANAGEMENT                    OT CHANGE MANAGEMENT
  =====================                   =====================

  +-----------------------------+         +-----------------------------+
  | Focus: Data & Services      |         | Focus: Physical Processes   |
  +-----------------------------+         +-----------------------------+
  | Downtime: Business impact   |         | Downtime: Production loss,  |
  |                             |         | Safety risk, Environmental  |
  +-----------------------------+         +-----------------------------+
  | Rollback: Usually quick     |         | Rollback: May require       |
  |           and automated     |         | physical intervention       |
  +-----------------------------+         +-----------------------------+
  | Testing: Dev/QA/Prod        |         | Testing: Limited, may need  |
  |          environments       |         | process shutdown            |
  +-----------------------------+         +-----------------------------+
  | Change Windows: Flexible    |         | Change Windows: Aligned     |
  |                             |         | with production cycles      |
  +-----------------------------+         +-----------------------------+
  | Approvers: IT management    |         | Approvers: Operations,      |
  |                             |         | Safety, Engineering, Maint  |
  +-----------------------------+         +-----------------------------+
  | Rollback Time: Minutes      |         | Rollback Time: Hours/Days   |
  +-----------------------------+         +-----------------------------+
  | Failure Impact: Service     |         | Failure Impact: Safety,     |
  |                 disruption  |         | environment, equipment      |
  +-----------------------------+         +-----------------------------+

  --------------------------------------------------------------------------

  OT-SPECIFIC CHANGE CONSIDERATIONS
  =================================

  SAFETY IMPLICATIONS
  +------------------------------------------------------------------------+
  |                                                                        |
  | * Safety Instrumented Systems (SIS) must remain operational            |
  | * Changes may affect emergency shutdown procedures                     |
  | * Human-machine interface changes affect operator response             |
  | * Process interlocks must be verified post-change                      |
  |                                                                        |
  +------------------------------------------------------------------------+

  PROCESS CONTINUITY
  +------------------------------------------------------------------------+
  |                                                                        |
  | * 24/7 operations cannot be interrupted                                |
  | * Batch processes have specific change windows                         |
  | * Continuous processes require hot-standby capabilities                |
  | * Seasonal/campaign production affects timing                          |
  |                                                                        |
  +------------------------------------------------------------------------+

  EQUIPMENT CONSTRAINTS
  +------------------------------------------------------------------------+
  |                                                                        |
  | * Legacy systems may not support modern patching                       |
  | * Vendor approval may be required for changes                          |
  | * Firmware updates may require physical access                         |
  | * Some changes require equipment restart/power cycle                   |
  |                                                                        |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### Regulatory Drivers for OT Change Management

| Standard | Change Management Requirements |
|----------|-------------------------------|
| **IEC 62443-2-1** | Formal change management procedures, risk assessment before changes |
| **IEC 62443-2-3** | Patch management processes specific to IACS environments |
| **NIST 800-82** | Configuration management and change control for ICS |
| **NERC CIP-010** | Configuration change management for bulk electric systems |
| **FDA 21 CFR Part 11** | Electronic records change control, audit trails |
| **NRC 10 CFR 73.54** | Cyber security program change control for nuclear facilities |
| **NIS2 Directive** | Change management as part of risk management measures |
| **API 1164** | Pipeline SCADA change management requirements |

### PAM Role in OT Change Management

```
+===============================================================================+
|                 PAM INTEGRATION IN CHANGE MANAGEMENT                          |
+===============================================================================+

  WALLIX Bastion provides essential controls for OT change management:

  +------------------------------------------------------------------------+
  |                                                                        |
  |  1. ACCESS CONTROL                                                     |
  |     +------------------------------------------------------------+    |
  |     | * Time-bound access aligned with change windows             |    |
  |     | * Approval workflows linked to change tickets               |    |
  |     | * Emergency access for break-glass situations               |    |
  |     | * Vendor access for maintenance windows                     |    |
  |     +------------------------------------------------------------+    |
  |                                                                        |
  |  2. AUDIT & ACCOUNTABILITY                                             |
  |     +------------------------------------------------------------+    |
  |     | * Session recording of all change activities                |    |
  |     | * Command logging for compliance evidence                   |    |
  |     | * Before/after configuration capture                        |    |
  |     | * Tie sessions to change ticket IDs                         |    |
  |     +------------------------------------------------------------+    |
  |                                                                        |
  |  3. CREDENTIAL MANAGEMENT                                              |
  |     +------------------------------------------------------------+    |
  |     | * Controlled checkout of privileged credentials             |    |
  |     | * Automatic rotation after change windows                   |    |
  |     | * Shared account accountability                             |    |
  |     | * Vendor credential lifecycle management                    |    |
  |     +------------------------------------------------------------+    |
  |                                                                        |
  |  4. INTEGRATION                                                        |
  |     +------------------------------------------------------------+    |
  |     | * ITSM/ServiceNow integration for ticket validation         |    |
  |     | * SIEM integration for change activity monitoring           |    |
  |     | * Webhook notifications for change events                   |    |
  |     | * API automation for change workflows                       |    |
  |     +------------------------------------------------------------+    |
  |                                                                        |
  +------------------------------------------------------------------------+

+===============================================================================+
```

---

## Change Management Architecture

### OT Change Management with PAM Integration

```
+===============================================================================+
|               OT CHANGE MANAGEMENT ARCHITECTURE                               |
+===============================================================================+

                                    ENTERPRISE ZONE
  +-------------------------------------------------------------------------+
  |                                                                         |
  |   +-------------------+        +-------------------+                    |
  |   |    ServiceNow     |        |    Change         |                    |
  |   |    Change Mgmt    |<------>|    Advisory       |                    |
  |   |                   |        |    Board (CAB)    |                    |
  |   +--------+----------+        +-------------------+                    |
  |            |                                                            |
  |            | REST API                                                   |
  |            v                                                            |
  +-------------------------------------------------------------------------+
                                    |
                           +--------+--------+
                           |    FIREWALL     |
                           +--------+--------+
                                    |
                                OT DMZ ZONE
  +-------------------------------------------------------------------------+
  |                                                                         |
  |   +===================================================================+ |
  |   |                    WALLIX BASTION                                 | |
  |   |                                                                   | |
  |   |  +---------------------+    +----------------------------+        | |
  |   |  | Change Window       |    | Approval Workflow          |        | |
  |   |  | Enforcement         |    | Engine                     |        | |
  |   |  |                     |    |                            |        | |
  |   |  | * Time frames       |    | * Ticket validation        |        | |
  |   |  | * Blackout periods  |    | * Multi-level approval     |        | |
  |   |  | * Schedule sync     |    | * Quorum requirements      |        | |
  |   |  +---------------------+    +----------------------------+        | |
  |   |                                                                   | |
  |   |  +---------------------+    +----------------------------+        | |
  |   |  | Session Manager     |    | Credential Vault           |        | |
  |   |  |                     |    |                            |        | |
  |   |  | * Recording         |    | * Checkout/checkin         |        | |
  |   |  | * Real-time monitor |    | * Post-change rotation     |        | |
  |   |  | * Command logging   |    | * Vendor credentials       |        | |
  |   |  +---------------------+    +----------------------------+        | |
  |   |                                                                   | |
  |   +===================================================================+ |
  |                                                                         |
  |   +-------------------+        +-------------------+                    |
  |   |  Change Database  |        |  Backup/Restore   |                    |
  |   |  (Config Backup)  |        |  Server           |                    |
  |   +-------------------+        +-------------------+                    |
  |                                                                         |
  +-------------------------------------------------------------------------+
                                    |
                           +--------+--------+
                           |    FIREWALL     |
                           +--------+--------+
                                    |
                               CONTROL ZONE
  +-------------------------------------------------------------------------+
  |                                                                         |
  |   +-------------+   +-------------+   +-------------+   +-------------+ |
  |   |   SCADA     |   |    HMI      |   | Engineering |   |   Safety    | |
  |   |   Server    |   |  Stations   |   | Workstation |   |   System    | |
  |   +-------------+   +-------------+   +-------------+   +-------------+ |
  |                                                                         |
  +-------------------------------------------------------------------------+
                                    |
                           +--------+--------+
                           |    FIREWALL     |
                           +--------+--------+
                                    |
                               FIELD ZONE
  +-------------------------------------------------------------------------+
  |                                                                         |
  |   +-------+    +-------+    +-------+    +-------+    +-------+         |
  |   | PLC-1 |    | PLC-2 |    | RTU-1 |    | RTU-2 |    |  VFD  |         |
  |   +-------+    +-------+    +-------+    +-------+    +-------+         |
  |                                                                         |
  +-------------------------------------------------------------------------+

+===============================================================================+
```

### Change Flow Integration

```
+===============================================================================+
|                    CHANGE REQUEST TO EXECUTION FLOW                           |
+===============================================================================+

  +--------+     +----------+     +---------+     +--------+     +----------+
  | Change |     | ITSM     |     | WALLIX  |     | Access |     | Target   |
  | Reqstr |     | System   |     | Bastion |     | Grant  |     | System   |
  +---+----+     +----+-----+     +----+----+     +----+---+     +----+-----+
      |               |                |               |              |
      |  1. Submit    |                |               |              |
      |  Change Req   |                |               |              |
      |-------------->|                |               |              |
      |               |                |               |              |
      |               | 2. CAB Review  |               |              |
      |               |--------------->|               |              |
      |               |   (Approval)   |               |              |
      |               |                |               |              |
      |               | 3. Create PAM  |               |              |
      |               |    Access Req  |               |              |
      |               |--------------->|               |              |
      |               |                |               |              |
      |               |                | 4. Validate   |              |
      |               |                |    Ticket     |              |
      |               |<---------------|    & Time     |              |
      |               |                |               |              |
      |               |                | 5. Queue      |              |
      |               |                |    Access     |              |
      |               |                |-------------->|              |
      |               |                |               |              |
      |  6. Notify:   |                |               |              |
      |  Access Ready |                |               |              |
      |<--------------|----------------|               |              |
      |               |                |               |              |
      |  7. Connect via PAM            |               |              |
      |--------------------------------|-------------->|              |
      |               |                |               |              |
      |               |                | 8. Session    |              |
      |               |                |    Recording  |------------->|
      |               |                |               |              |
      |               |                | 9. Change     |              |
      |               |                |    Execution  |------------->|
      |               |                |               |              |
      |               | 10. Status     |               |              |
      |               |     Update     |               |              |
      |               |<---------------|<--------------|              |
      |               |                |               |              |
      |               | 11. Close      |               |              |
      |               |     Ticket     | 12. Revoke    |              |
      |               |--------------->|     Access    |              |
      |               |                |-------------->|              |
      |               |                |               |              |

+===============================================================================+
```

---

## Change Classification

### OT Change Types

```
+===============================================================================+
|                    OT CHANGE CLASSIFICATION                                   |
+===============================================================================+

  CHANGE TYPE 1: NORMAL CHANGES
  =============================

  +------------------------------------------------------------------------+
  | Description: Standard changes requiring full CAB review and approval    |
  +------------------------------------------------------------------------+
  | Examples:                                                               |
  | * PLC firmware upgrades                                                 |
  | * SCADA software updates                                                |
  | * Network configuration changes                                         |
  | * New device integration                                                |
  | * Control logic modifications                                           |
  +------------------------------------------------------------------------+
  | Approval: Full CAB (Operations, Safety, Engineering, IT)               |
  | Lead Time: 5-10 business days                                           |
  | PAM Config: Standard approval workflow, scheduled access window         |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  CHANGE TYPE 2: STANDARD/PRE-APPROVED CHANGES
  =============================================

  +------------------------------------------------------------------------+
  | Description: Low-risk, routine changes with pre-defined procedures      |
  +------------------------------------------------------------------------+
  | Examples:                                                               |
  | * Password rotation                                                     |
  | * Routine backup operations                                             |
  | * Log collection tasks                                                  |
  | * Scheduled maintenance checks                                          |
  | * Pre-approved vendor patches                                           |
  +------------------------------------------------------------------------+
  | Approval: Pre-approved by CAB, single manager approval                  |
  | Lead Time: 1-2 business days                                            |
  | PAM Config: Simplified workflow, recurring access windows               |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  CHANGE TYPE 3: EMERGENCY CHANGES
  =================================

  +------------------------------------------------------------------------+
  | Description: Urgent changes to restore operations or address safety     |
  +------------------------------------------------------------------------+
  | Examples:                                                               |
  | * Equipment failure response                                            |
  | * Critical security patches                                             |
  | * Process safety corrections                                            |
  | * Production-critical bug fixes                                         |
  +------------------------------------------------------------------------+
  | Approval: Emergency CAB (subset), post-implementation review            |
  | Lead Time: Immediate to 4 hours                                         |
  | PAM Config: Break-glass access, expedited approval, post-hoc review     |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  CHANGE TYPE 4: SAFETY-CRITICAL CHANGES
  ======================================

  +------------------------------------------------------------------------+
  | Description: Changes affecting Safety Instrumented Systems (SIS)        |
  +------------------------------------------------------------------------+
  | Examples:                                                               |
  | * SIS logic modifications                                               |
  | * Emergency shutdown system changes                                     |
  | * Fire & gas system updates                                             |
  | * Interlock modifications                                               |
  +------------------------------------------------------------------------+
  | Approval: Full CAB + Safety Manager + Process Safety Review             |
  | Lead Time: 10-20 business days                                          |
  | PAM Config: Dual-control (4-eyes), enhanced recording, dual approval    |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### WALLIX Change Type Configuration

```json
{
    "change_classifications": [
        {
            "type": "normal",
            "name": "Normal OT Change",
            "authorization_policy": {
                "approval_required": true,
                "approver_groups": ["CAB-OT", "Operations-Managers"],
                "quorum": {
                    "enabled": true,
                    "minimum": 2
                },
                "timeout_hours": 72,
                "access_validity_hours": 8,
                "is_recorded": true,
                "is_critical": true,
                "require_ticket": true,
                "ticket_systems": ["servicenow"]
            }
        },
        {
            "type": "standard",
            "name": "Standard Pre-Approved Change",
            "authorization_policy": {
                "approval_required": true,
                "approver_groups": ["Operations-Managers"],
                "quorum": {
                    "enabled": false
                },
                "timeout_hours": 24,
                "access_validity_hours": 4,
                "is_recorded": true,
                "is_critical": false,
                "require_ticket": true,
                "ticket_systems": ["servicenow"]
            }
        },
        {
            "type": "emergency",
            "name": "Emergency Change",
            "authorization_policy": {
                "approval_required": true,
                "approver_groups": ["Emergency-CAB", "On-Call-Manager"],
                "quorum": {
                    "enabled": false
                },
                "timeout_hours": 1,
                "access_validity_hours": 4,
                "is_recorded": true,
                "is_critical": true,
                "require_ticket": false,
                "post_session_ticket_required": true,
                "break_glass_enabled": true
            }
        },
        {
            "type": "safety_critical",
            "name": "Safety-Critical Change",
            "authorization_policy": {
                "approval_required": true,
                "approver_groups": ["CAB-OT", "Safety-Manager", "Process-Safety"],
                "quorum": {
                    "enabled": true,
                    "minimum": 3
                },
                "dual_control": true,
                "timeout_hours": 168,
                "access_validity_hours": 4,
                "is_recorded": true,
                "is_critical": true,
                "require_ticket": true,
                "require_moc_reference": true
            }
        }
    ]
}
```

---

## Change Windows

### Maintenance Window Configuration

```
+===============================================================================+
|                    OT CHANGE WINDOW MANAGEMENT                                |
+===============================================================================+

  MAINTENANCE WINDOW TYPES
  ========================

  +------------------------------------------------------------------------+
  | Type              | Duration    | Access Level    | Use Case           |
  +-------------------+-------------+-----------------+--------------------+
  | Planned Outage    | 4-8 hours   | Full access     | Major upgrades,    |
  |                   |             |                 | firmware updates   |
  +-------------------+-------------+-----------------+--------------------+
  | Reduced Operation | 2-4 hours   | Limited access  | Non-critical       |
  |                   |             |                 | patches, config    |
  +-------------------+-------------+-----------------+--------------------+
  | Hot Maintenance   | 30-60 min   | Minimal access  | Hot-standby        |
  |                   |             |                 | systems only       |
  +-------------------+-------------+-----------------+--------------------+
  | Turnaround        | Days-Weeks  | Full access     | Annual/bi-annual   |
  |                   |             |                 | major maintenance  |
  +-------------------+-------------+-----------------+--------------------+
  | Emergency         | As needed   | Break-glass     | Unplanned outages, |
  |                   |             |                 | incidents          |
  +-------------------+-------------+-----------------+--------------------+

  --------------------------------------------------------------------------

  PRODUCTION SCHEDULE INTEGRATION
  ===============================

  WALLIX time frames aligned with production cycles:

  +------------------------------------------------------------------------+
  |                                                                        |
  |  CONTINUOUS PROCESS (Refinery, Chemical Plant)                         |
  |                                                                        |
  |  +------------------------------------------------------------------+  |
  |  |  Sun   Mon   Tue   Wed   Thu   Fri   Sat                         |  |
  |  |  +---+ +---+ +---+ +---+ +---+ +---+ +---+                        |  |
  |  |  |   | |   | | X | |   | |   | |   | |   |  X = Maint Window     |  |
  |  |  +---+ +---+ +---+ +---+ +---+ +---+ +---+      02:00-06:00      |  |
  |  |                                                                   |  |
  |  |  Reduced throughput window: Tuesday 02:00-06:00                   |  |
  |  |  Turnaround: Scheduled annually                                   |  |
  |  +------------------------------------------------------------------+  |
  |                                                                        |
  |  BATCH PROCESS (Pharmaceutical, Food & Beverage)                       |
  |                                                                        |
  |  +------------------------------------------------------------------+  |
  |  |  Mon   Tue   Wed   Thu   Fri   Sat   Sun                         |  |
  |  |  +---+ +---+ +---+ +---+ +---+ +---+ +---+                        |  |
  |  |  | B | | B | | B | | B | | B | | X | | X |  B = Batch Running    |  |
  |  |  +---+ +---+ +---+ +---+ +---+ +---+ +---+  X = Maint Window     |  |
  |  |                                                                   |  |
  |  |  Weekend maintenance: Saturday 06:00 - Sunday 18:00               |  |
  |  +------------------------------------------------------------------+  |
  |                                                                        |
  |  DISCRETE MANUFACTURING (Assembly Lines)                               |
  |                                                                        |
  |  +------------------------------------------------------------------+  |
  |  |  Shift 1      Shift 2      Shift 3      Maintenance              |  |
  |  |  06:00-14:00  14:00-22:00  22:00-06:00  Shift Change             |  |
  |  |  +----------+ +----------+ +----------+ +----------+             |  |
  |  |  |  PROD    | |  PROD    | |  PROD    | |  MAINT   |             |  |
  |  |  +----------+ +----------+ +----------+ +----------+             |  |
  |  |                                                                   |  |
  |  |  Maintenance windows: 05:30-06:30, 13:30-14:30, 21:30-22:30       |  |
  |  +------------------------------------------------------------------+  |
  |                                                                        |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### Time Frame Configuration in WALLIX

```json
{
    "time_frames": [
        {
            "name": "continuous-process-maintenance",
            "description": "Reduced throughput maintenance window for continuous process",
            "periods": [
                {
                    "days": ["tuesday"],
                    "start_time": "02:00",
                    "end_time": "06:00"
                }
            ],
            "timezone": "America/Chicago",
            "change_types": ["normal", "standard"]
        },
        {
            "name": "batch-process-weekend",
            "description": "Weekend maintenance for batch processing",
            "periods": [
                {
                    "days": ["saturday"],
                    "start_time": "06:00",
                    "end_time": "23:59"
                },
                {
                    "days": ["sunday"],
                    "start_time": "00:00",
                    "end_time": "18:00"
                }
            ],
            "timezone": "America/Chicago",
            "change_types": ["normal", "standard", "safety_critical"]
        },
        {
            "name": "shift-change-windows",
            "description": "Brief maintenance during shift changes",
            "periods": [
                {
                    "days": ["monday", "tuesday", "wednesday", "thursday", "friday"],
                    "start_time": "05:30",
                    "end_time": "06:30"
                },
                {
                    "days": ["monday", "tuesday", "wednesday", "thursday", "friday"],
                    "start_time": "13:30",
                    "end_time": "14:30"
                },
                {
                    "days": ["monday", "tuesday", "wednesday", "thursday", "friday"],
                    "start_time": "21:30",
                    "end_time": "22:30"
                }
            ],
            "timezone": "America/Chicago",
            "change_types": ["standard"]
        },
        {
            "name": "emergency-always",
            "description": "Emergency access available 24/7",
            "periods": [
                {
                    "days": ["monday", "tuesday", "wednesday", "thursday",
                             "friday", "saturday", "sunday"],
                    "start_time": "00:00",
                    "end_time": "23:59"
                }
            ],
            "timezone": "UTC",
            "change_types": ["emergency"],
            "requires_approval": true
        }
    ]
}
```

### Blackout Period Enforcement

```
+===============================================================================+
|                    BLACKOUT PERIOD CONFIGURATION                              |
+===============================================================================+

  BLACKOUT PERIODS = No changes permitted except emergencies

  +------------------------------------------------------------------------+
  | Period Type        | Duration        | Enforcement                     |
  +--------------------+-----------------+---------------------------------+
  | Year-End Freeze    | Dec 15 - Jan 5  | Block all normal/standard       |
  | Peak Production    | Varies          | Block non-essential changes     |
  | Regulatory Audit   | Audit week      | Block all except emergency      |
  | Safety Standdown   | As declared     | Block all changes               |
  +--------------------+-----------------+---------------------------------+

  WALLIX Configuration:
  +------------------------------------------------------------------------+
  | {                                                                      |
  |     "blackout_periods": [                                              |
  |         {                                                              |
  |             "name": "year-end-freeze",                                 |
  |             "start": "2026-12-15T00:00:00Z",                           |
  |             "end": "2026-01-05T23:59:59Z",                             |
  |             "blocked_change_types": ["normal", "standard"],            |
  |             "message": "Year-end production freeze in effect"          |
  |         },                                                             |
  |         {                                                              |
  |             "name": "q4-peak-production",                              |
  |             "start": "2026-10-01T00:00:00Z",                           |
  |             "end": "2026-12-14T23:59:59Z",                             |
  |             "blocked_change_types": ["normal"],                        |
  |             "allow_with_override": true,                               |
  |             "override_approvers": ["VP-Operations"]                    |
  |         }                                                              |
  |     ]                                                                  |
  | }                                                                      |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### Turnaround Window Management

```bash
# Create turnaround authorization with extended access
wabadmin authorization create \
    --name "turnaround-2026-q2" \
    --description "Q2 2026 Plant Turnaround - Full Maintenance Access" \
    --user-group "Turnaround-Team" \
    --target-group "All-OT-Systems" \
    --time-frame "turnaround-q2-2026" \
    --approval-required \
    --approver-groups "Turnaround-Manager,Safety-Manager" \
    --recorded \
    --critical \
    --max-concurrent-sessions 50

# Define turnaround time frame
wabadmin time-frame create \
    --name "turnaround-q2-2026" \
    --start "2026-04-01T00:00:00" \
    --end "2026-04-21T23:59:59" \
    --timezone "America/Chicago" \
    --description "Q2 2026 Annual Turnaround"
```

---

## Change Request Workflow

### Request Initiation

```
+===============================================================================+
|                    CHANGE REQUEST WORKFLOW                                    |
+===============================================================================+

  STEP 1: REQUEST INITIATION
  ==========================

  +------------------------------------------------------------------------+
  |                                                                        |
  |  CHANGE REQUEST FORM                                                   |
  |                                                                        |
  |  +------------------------------------------------------------------+  |
  |  | Requestor Information                                            |  |
  |  | * Name: _______________________                                  |  |
  |  | * Department: _________________                                  |  |
  |  | * Contact: ____________________                                  |  |
  |  +------------------------------------------------------------------+  |
  |                                                                        |
  |  +------------------------------------------------------------------+  |
  |  | Change Details                                                   |  |
  |  | * Title: _______________________                                 |  |
  |  | * Description: ________________                                  |  |
  |  | * Justification: ______________                                  |  |
  |  | * Affected Systems: ___________                                  |  |
  |  | * Change Type: [ ] Normal [ ] Standard [ ] Emergency [ ] Safety  |  |
  |  +------------------------------------------------------------------+  |
  |                                                                        |
  |  +------------------------------------------------------------------+  |
  |  | Scheduling                                                       |  |
  |  | * Requested Start: ____________                                  |  |
  |  | * Estimated Duration: _________                                  |  |
  |  | * Preferred Window: ___________                                  |  |
  |  +------------------------------------------------------------------+  |
  |                                                                        |
  |  +------------------------------------------------------------------+  |
  |  | Risk Assessment                                                  |  |
  |  | * Production Impact: [ ] None [ ] Low [ ] Medium [ ] High        |  |
  |  | * Safety Impact: [ ] None [ ] Low [ ] Medium [ ] High            |  |
  |  | * Rollback Plan: [ ] Documented [ ] Tested                       |  |
  |  +------------------------------------------------------------------+  |
  |                                                                        |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### Impact Assessment Matrix

```
+===============================================================================+
|                    OT CHANGE IMPACT ASSESSMENT                                |
+===============================================================================+

  IMPACT CATEGORIES
  =================

  +------------------------------------------------------------------------+
  | Category         | Low (1)          | Medium (2)       | High (3)       |
  +------------------+------------------+------------------+----------------+
  | Production       | No impact        | Reduced          | Full           |
  |                  |                  | throughput       | stoppage       |
  +------------------+------------------+------------------+----------------+
  | Safety           | No SIS impact    | Partial SIS      | SIS bypass     |
  |                  |                  | modification     | required       |
  +------------------+------------------+------------------+----------------+
  | Environment      | No release       | Potential minor  | Potential      |
  |                  | potential        | release          | major release  |
  +------------------+------------------+------------------+----------------+
  | Equipment        | Software only    | Firmware/config  | Hardware       |
  |                  |                  |                  | modification   |
  +------------------+------------------+------------------+----------------+
  | Recovery         | < 1 hour         | 1-4 hours        | > 4 hours      |
  +------------------+------------------+------------------+----------------+

  --------------------------------------------------------------------------

  RISK SCORE CALCULATION
  ======================

  Risk Score = (Impact x Probability) + Safety Factor

  +------------------------------------------------------------------------+
  | Score Range | Classification | Approval Required                       |
  +-------------+----------------+-----------------------------------------+
  | 1-4         | Low            | Manager approval                        |
  | 5-9         | Medium         | CAB approval                            |
  | 10-15       | High           | CAB + Safety Manager                    |
  | 16+         | Critical       | CAB + Safety + VP Operations            |
  +-------------+----------------+-----------------------------------------+

+===============================================================================+
```

### Approval Workflow Configuration

```
+===============================================================================+
|                    APPROVAL WORKFLOW STAGES                                   |
+===============================================================================+

  NORMAL CHANGE APPROVAL FLOW
  ===========================

  +--------+    +----------+    +--------+    +----------+    +---------+
  |Request |    | Technical|    | Safety |    |   CAB    |    | Access  |
  |Submitted    | Review   |    | Review |    | Approval |    | Granted |
  +---+----+    +----+-----+    +----+---+    +----+-----+    +----+----+
      |              |              |              |              |
      |  Submit      |              |              |              |
      |------------->|              |              |              |
      |              |              |              |              |
      |              | Assess       |              |              |
      |              | feasibility  |              |              |
      |              |------------->|              |              |
      |              |              |              |              |
      |              |              | Review       |              |
      |              |              | safety       |              |
      |              |              | implications |              |
      |              |              |------------->|              |
      |              |              |              |              |
      |              |              |              | CAB votes    |
      |              |              |              | (quorum)     |
      |              |              |              |------------->|
      |              |              |              |              |
      |              |              |              |              | WALLIX
      |              |              |              |              | creates
      |              |              |              |              | access
      |              |              |              |              |
      |<-------------|--------------|--------------|--------------|
      |        Notification: Approved, Access Window Scheduled    |
      |                                                           |

  --------------------------------------------------------------------------

  SAFETY-CRITICAL CHANGE APPROVAL FLOW
  =====================================

  +--------+   +----------+   +--------+   +----------+   +-------+   +------+
  |Request |   | Process  |   | Safety |   |Independent   |  CAB  |   |Access|
  |Submit  |   | Hazard   |   | Review |   | Review   |   |Approve|   |Grant |
  +---+----+   +----+-----+   +---+----+   +----+-----+   +---+---+   +--+---+
      |             |             |             |             |          |
      |  Submit     |             |             |             |          |
      |------------>|             |             |             |          |
      |             |             |             |             |          |
      |             | PHA/HAZOP   |             |             |          |
      |             | Review      |             |             |          |
      |             |------------>|             |             |          |
      |             |             |             |             |          |
      |             |             | SIL Impact  |             |          |
      |             |             | Assessment  |             |          |
      |             |             |------------>|             |          |
      |             |             |             |             |          |
      |             |             |             | Independent |          |
      |             |             |             | SIS Review  |          |
      |             |             |             |------------>|          |
      |             |             |             |             |          |
      |             |             |             |             | Full CAB |
      |             |             |             |             | + Safety |
      |             |             |             |             |--------->|
      |             |             |             |             |          |
      |             |             |             |             |   4-Eyes |
      |             |             |             |             |   Access |
      |             |             |             |             |          |

+===============================================================================+
```

### PAM Authorization Alignment

```json
{
    "change_authorization_mapping": {
        "normal_change": {
            "authorization_template": "normal-change-access",
            "settings": {
                "approval_required": true,
                "approver_groups": ["OT-CAB", "Operations-Manager"],
                "quorum": 2,
                "time_frame": "approved-maintenance-windows",
                "max_duration_hours": 8,
                "require_comment": true,
                "require_ticket": true,
                "is_recorded": true,
                "post_session_rotation": false
            }
        },
        "standard_change": {
            "authorization_template": "standard-change-access",
            "settings": {
                "approval_required": true,
                "approver_groups": ["Operations-Manager"],
                "quorum": 1,
                "time_frame": "standard-maintenance-windows",
                "max_duration_hours": 4,
                "require_comment": true,
                "require_ticket": true,
                "is_recorded": true,
                "post_session_rotation": false
            }
        },
        "safety_critical_change": {
            "authorization_template": "safety-critical-access",
            "settings": {
                "approval_required": true,
                "approver_groups": ["OT-CAB", "Safety-Manager", "Process-Safety"],
                "quorum": 3,
                "dual_control": true,
                "time_frame": "approved-maintenance-windows",
                "max_duration_hours": 4,
                "require_comment": true,
                "require_ticket": true,
                "require_moc_reference": true,
                "is_recorded": true,
                "is_critical": true,
                "post_session_rotation": true
            }
        }
    }
}
```

---

## Pre-Change Procedures

### Configuration Backup Procedures

```
+===============================================================================+
|                    PRE-CHANGE BACKUP PROCEDURES                               |
+===============================================================================+

  AUTOMATED PRE-CHANGE BACKUP WORKFLOW
  ====================================

  +------------------------------------------------------------------------+
  |                                                                        |
  |  Change Window Opens                                                   |
  |         |                                                              |
  |         v                                                              |
  |  +------------------+                                                  |
  |  | Trigger Backup   |  WALLIX API webhook on access grant              |
  |  | Automation       |                                                  |
  |  +--------+---------+                                                  |
  |           |                                                            |
  |           v                                                            |
  |  +------------------+     +------------------+     +------------------+ |
  |  | PLC Config       |     | SCADA Config     |     | HMI Config       | |
  |  | Backup           |     | Backup           |     | Backup           | |
  |  +--------+---------+     +--------+---------+     +--------+---------+ |
  |           |                        |                        |          |
  |           v                        v                        v          |
  |  +----------------------------------------------------------------+    |
  |  |                      Backup Repository                          |    |
  |  |                                                                 |    |
  |  |  /backups/pre-change/                                           |    |
  |  |    CHG0012345/                                                  |    |
  |  |      2026-02-01T08:00:00/                                       |    |
  |  |        plc-01_config.bin                                        |    |
  |  |        plc-01_logic.acd                                         |    |
  |  |        scada-server_db.bak                                      |    |
  |  |        hmi-station-01_project.mer                               |    |
  |  |        manifest.json                                            |    |
  |  |                                                                 |    |
  |  +----------------------------------------------------------------+    |
  |           |                                                            |
  |           v                                                            |
  |  +------------------+                                                  |
  |  | Verify Backup    |  Checksum validation, integrity check            |
  |  | Integrity        |                                                  |
  |  +--------+---------+                                                  |
  |           |                                                            |
  |           v                                                            |
  |  +------------------+                                                  |
  |  | Update Change    |  Record backup status in ITSM                    |
  |  | Ticket           |                                                  |
  |  +--------+---------+                                                  |
  |           |                                                            |
  |           v                                                            |
  |  +------------------+                                                  |
  |  | Proceed with     |  Only if backup verified                         |
  |  | Change Execution |                                                  |
  |  +------------------+                                                  |
  |                                                                        |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### Pre-Change Automation Script

```python
#!/usr/bin/env python3
"""
Pre-Change Backup Automation for OT Systems
Triggered by WALLIX access grant webhook
"""

import requests
import hashlib
import json
from datetime import datetime
from pathlib import Path

WALLIX_API = "https://bastion.company.com/api"
SERVICENOW_API = "https://company.service-now.com/api/now"
BACKUP_ROOT = "/backups/pre-change"

def backup_plc_config(plc_host, change_id, session_token):
    """Backup PLC configuration before change"""
    backup_dir = Path(BACKUP_ROOT) / change_id / datetime.utcnow().isoformat()
    backup_dir.mkdir(parents=True, exist_ok=True)

    # Use WALLIX session to access PLC
    # This varies by PLC vendor (Rockwell, Siemens, etc.)
    backup_file = backup_dir / f"{plc_host}_config.bin"

    # Vendor-specific backup command through PAM session
    # Example for Rockwell/Allen-Bradley:
    # rslogix_backup(plc_host, backup_file, session_token)

    # Calculate checksum
    with open(backup_file, 'rb') as f:
        checksum = hashlib.sha256(f.read()).hexdigest()

    return {
        "file": str(backup_file),
        "checksum": checksum,
        "timestamp": datetime.utcnow().isoformat()
    }

def verify_backup_integrity(backup_manifest):
    """Verify all backups completed successfully"""
    for backup in backup_manifest["backups"]:
        with open(backup["file"], 'rb') as f:
            actual_checksum = hashlib.sha256(f.read()).hexdigest()
        if actual_checksum != backup["checksum"]:
            return False, f"Checksum mismatch for {backup['file']}"
    return True, "All backups verified"

def update_change_ticket(change_id, backup_status):
    """Update ServiceNow change ticket with backup status"""
    headers = {
        "Authorization": f"Bearer {SERVICENOW_TOKEN}",
        "Content-Type": "application/json"
    }

    payload = {
        "work_notes": f"Pre-change backup completed: {backup_status}",
        "u_backup_verified": backup_status["verified"]
    }

    response = requests.patch(
        f"{SERVICENOW_API}/table/change_request/{change_id}",
        headers=headers,
        json=payload
    )
    return response.status_code == 200

def main(webhook_payload):
    """Main pre-change workflow triggered by WALLIX webhook"""
    change_id = webhook_payload["ticket_id"]
    target_systems = webhook_payload["target_systems"]
    session_token = webhook_payload["session_token"]

    backup_manifest = {
        "change_id": change_id,
        "timestamp": datetime.utcnow().isoformat(),
        "backups": []
    }

    for system in target_systems:
        if system["type"] == "plc":
            backup = backup_plc_config(system["host"], change_id, session_token)
            backup_manifest["backups"].append(backup)

    # Verify all backups
    verified, message = verify_backup_integrity(backup_manifest)
    backup_manifest["verified"] = verified
    backup_manifest["verification_message"] = message

    # Update change ticket
    update_change_ticket(change_id, backup_manifest)

    # Return status - blocks change if backup failed
    return verified
```

### Rollback Plan Verification Checklist

```
+===============================================================================+
|                    ROLLBACK PLAN VERIFICATION                                 |
+===============================================================================+

  PRE-CHANGE ROLLBACK CHECKLIST
  =============================

  +------------------------------------------------------------------------+
  |                                                                        |
  |  [ ] DOCUMENTATION                                                     |
  |      [ ] Rollback procedure documented                                 |
  |      [ ] Step-by-step instructions verified                            |
  |      [ ] Estimated rollback time defined                               |
  |      [ ] Rollback decision criteria specified                          |
  |                                                                        |
  |  [ ] BACKUPS                                                           |
  |      [ ] Configuration backups completed                               |
  |      [ ] Backup integrity verified (checksums)                         |
  |      [ ] Backup restoration tested (if possible)                       |
  |      [ ] Backup location accessible                                    |
  |                                                                        |
  |  [ ] ACCESS                                                            |
  |      [ ] Rollback credentials available                                |
  |      [ ] Emergency access procedures tested                            |
  |      [ ] Vendor support contact confirmed (if needed)                  |
  |      [ ] WALLIX break-glass account verified                           |
  |                                                                        |
  |  [ ] RESOURCES                                                         |
  |      [ ] Rollback team identified                                      |
  |      [ ] Team availability confirmed for change window                 |
  |      [ ] Communication plan established                                |
  |      [ ] Escalation path defined                                       |
  |                                                                        |
  |  [ ] TESTING                                                           |
  |      [ ] Rollback tested in non-production (if available)              |
  |      [ ] Known issues documented                                       |
  |      [ ] Workarounds prepared                                          |
  |                                                                        |
  +------------------------------------------------------------------------+

+===============================================================================+
```

---

## Change Execution

### Time-Bound Access Grants

```
+===============================================================================+
|                    CHANGE EXECUTION ACCESS CONTROL                            |
+===============================================================================+

  TIME-BOUND ACCESS FLOW
  ======================

  +------------------------------------------------------------------------+
  |                                                                        |
  |  Change Window:  08:00 - 12:00 (4 hours)                               |
  |  Access Grant:   08:00 - 12:00                                         |
  |                                                                        |
  |  Timeline:                                                             |
  |                                                                        |
  |  07:30  [Notification] Access window opens in 30 minutes               |
  |         |                                                              |
  |  08:00  [ACCESS GRANTED] Session can begin                             |
  |         |==========================================|                   |
  |         |                                          |                   |
  |         |  Active Change Execution Window          |                   |
  |         |                                          |                   |
  |         |  * Session recording active              |                   |
  |         |  * Real-time monitoring enabled          |                   |
  |         |  * Command logging active                |                   |
  |         |                                          |                   |
  |  11:30  [Warning] 30 minutes remaining                                 |
  |         |                                          |                   |
  |  11:45  [Warning] 15 minutes remaining                                 |
  |         |                                          |                   |
  |  12:00  [ACCESS REVOKED] Session terminated                            |
  |         |==========================================|                   |
  |         |                                                              |
  |  12:00  [Auto-logout] All active sessions ended                        |
  |         |                                                              |
  |  12:05  [Credential rotation] Target passwords rotated                 |
  |         |                                                              |
  |  12:10  [Post-change] Verification window begins                       |
  |                                                                        |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### Real-Time Monitoring Dashboard

```
+===============================================================================+
|                    CHANGE EXECUTION MONITORING                                |
+===============================================================================+

  +------------------------------------------------------------------------+
  |  WALLIX Change Monitoring Dashboard                                    |
  +------------------------------------------------------------------------+
  |                                                                        |
  |  Change: CHG0012345 - PLC Firmware Upgrade                             |
  |  Status: IN PROGRESS                                                   |
  |  Window: 08:00 - 12:00 (2:15 remaining)                                |
  |                                                                        |
  +------------------------------------------------------------------------+
  |                                                                        |
  |  ACTIVE SESSIONS                                                       |
  |  +------------------------------------------------------------------+  |
  |  | User         | Target       | Protocol | Duration | Status      |  |
  |  +------------------------------------------------------------------+  |
  |  | jsmith       | PLC-UNIT-01  | S7comm   | 01:23:45 | Active      |  |
  |  | mjohnson     | SCADA-SVR-01 | RDP      | 00:45:12 | Active      |  |
  |  | vendor_abb   | PLC-UNIT-02  | SSH      | 00:30:00 | Active      |  |
  |  +------------------------------------------------------------------+  |
  |                                                                        |
  |  COMMAND LOG (Last 10)                                                 |
  |  +------------------------------------------------------------------+  |
  |  | Time     | User    | Command                        | Risk       |  |
  |  +------------------------------------------------------------------+  |
  |  | 09:42:15 | jsmith  | DOWNLOAD_PROGRAM               | Medium     |  |
  |  | 09:41:30 | jsmith  | STOP_PLC                       | High       |  |
  |  | 09:40:45 | jsmith  | BACKUP_CONFIG                  | Low        |  |
  |  +------------------------------------------------------------------+  |
  |                                                                        |
  |  ALERTS                                                                |
  |  +------------------------------------------------------------------+  |
  |  | [!] 09:41:30 - High-risk command executed: STOP_PLC              |  |
  |  | [i] 09:30:00 - Vendor session started within policy              |  |
  |  +------------------------------------------------------------------+  |
  |                                                                        |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### Go/No-Go Checkpoints

```
+===============================================================================+
|                    CHANGE EXECUTION CHECKPOINTS                               |
+===============================================================================+

  CHECKPOINT 1: PRE-EXECUTION VERIFICATION
  =========================================

  +------------------------------------------------------------------------+
  |  Time: Change Window Start                                             |
  |                                                                        |
  |  Checklist:                                                            |
  |  [x] Backup completed and verified                                     |
  |  [x] Rollback plan confirmed                                           |
  |  [x] Change team assembled                                             |
  |  [x] Communications channels open                                      |
  |  [x] PAM access granted                                                |
  |                                                                        |
  |  Decision: [GO] / [NO-GO]                                              |
  |  Approver: ___________________                                         |
  +------------------------------------------------------------------------+

  CHECKPOINT 2: MID-CHANGE ASSESSMENT
  ====================================

  +------------------------------------------------------------------------+
  |  Time: 50% of window elapsed                                           |
  |                                                                        |
  |  Checklist:                                                            |
  |  [ ] Change progressing as planned                                     |
  |  [ ] No unexpected errors                                              |
  |  [ ] Safety systems unaffected                                         |
  |  [ ] Sufficient time for completion + verification                     |
  |                                                                        |
  |  Decision: [CONTINUE] / [ROLLBACK]                                     |
  |  Approver: ___________________                                         |
  +------------------------------------------------------------------------+

  CHECKPOINT 3: PRE-CUTOVER VERIFICATION
  ======================================

  +------------------------------------------------------------------------+
  |  Time: Before production cutover                                       |
  |                                                                        |
  |  Checklist:                                                            |
  |  [ ] Change implementation complete                                    |
  |  [ ] Initial testing passed                                            |
  |  [ ] No critical alarms                                                |
  |  [ ] Ready for production traffic                                      |
  |                                                                        |
  |  Decision: [CUTOVER] / [ROLLBACK]                                      |
  |  Approver: ___________________                                         |
  +------------------------------------------------------------------------+

  CHECKPOINT 4: POST-CHANGE VALIDATION
  =====================================

  +------------------------------------------------------------------------+
  |  Time: After change completion                                         |
  |                                                                        |
  |  Checklist:                                                            |
  |  [ ] Functional testing complete                                       |
  |  [ ] Safety systems verified                                           |
  |  [ ] Performance within parameters                                     |
  |  [ ] No operator complaints                                            |
  |                                                                        |
  |  Decision: [CLOSE] / [EXTENDED MONITORING] / [ROLLBACK]                |
  |  Approver: ___________________                                         |
  +------------------------------------------------------------------------+

+===============================================================================+
```

---

## Post-Change Verification

### Functional Testing Procedures

```
+===============================================================================+
|                    POST-CHANGE VERIFICATION                                   |
+===============================================================================+

  FUNCTIONAL TEST CHECKLIST
  =========================

  +------------------------------------------------------------------------+
  |                                                                        |
  |  CONTROL SYSTEM VERIFICATION                                           |
  |                                                                        |
  |  [ ] PLC Communication                                                 |
  |      [ ] All I/O points responding                                     |
  |      [ ] Communication with SCADA verified                             |
  |      [ ] Historian data collection active                              |
  |                                                                        |
  |  [ ] SCADA/HMI Functionality                                           |
  |      [ ] All graphics displaying correctly                             |
  |      [ ] Alarm system operational                                      |
  |      [ ] Trend displays updating                                       |
  |      [ ] Operator controls responsive                                  |
  |                                                                        |
  |  [ ] Process Control                                                   |
  |      [ ] Control loops in auto mode                                    |
  |      [ ] Setpoints tracking correctly                                  |
  |      [ ] Interlocks functional                                         |
  |      [ ] Analog values within range                                    |
  |                                                                        |
  +------------------------------------------------------------------------+

  SAFETY SYSTEM VERIFICATION
  ==========================

  +------------------------------------------------------------------------+
  |                                                                        |
  |  SAFETY INSTRUMENTED SYSTEM (SIS)                                      |
  |                                                                        |
  |  [ ] SIS Status                                                        |
  |      [ ] All SIS controllers online                                    |
  |      [ ] No diagnostic faults                                          |
  |      [ ] Bypass/override count unchanged                               |
  |                                                                        |
  |  [ ] Safety Function Tests                                             |
  |      [ ] Emergency shutdown test (simulated)                           |
  |      [ ] Fire & gas system check                                       |
  |      [ ] Critical interlock verification                               |
  |                                                                        |
  |  [ ] Documentation                                                     |
  |      [ ] SIS modification log updated                                  |
  |      [ ] Test results documented                                       |
  |      [ ] Safety manager sign-off                                       |
  |                                                                        |
  +------------------------------------------------------------------------+

  PERFORMANCE VALIDATION
  ======================

  +------------------------------------------------------------------------+
  |                                                                        |
  |  [ ] System Performance                                                |
  |      [ ] CPU utilization within limits                                 |
  |      [ ] Memory usage acceptable                                       |
  |      [ ] Network latency normal                                        |
  |      [ ] Scan times within specification                               |
  |                                                                        |
  |  [ ] Process Performance                                               |
  |      [ ] Production rates normal                                       |
  |      [ ] Quality parameters acceptable                                 |
  |      [ ] No unusual alarms                                             |
  |      [ ] Operator feedback positive                                    |
  |                                                                        |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### Post-Change API Notification

```python
#!/usr/bin/env python3
"""
Post-Change Verification and Notification
Updates ITSM and revokes PAM access after successful change
"""

import requests
import json
from datetime import datetime

def verify_change_success(change_id, target_systems):
    """Run post-change verification tests"""
    verification_results = {
        "change_id": change_id,
        "timestamp": datetime.utcnow().isoformat(),
        "tests": []
    }

    for system in target_systems:
        test_result = {
            "system": system["host"],
            "tests": []
        }

        # Communication test
        comm_test = test_communication(system)
        test_result["tests"].append({
            "name": "communication",
            "passed": comm_test
        })

        # Functional test
        func_test = test_functionality(system)
        test_result["tests"].append({
            "name": "functionality",
            "passed": func_test
        })

        verification_results["tests"].append(test_result)

    # Calculate overall success
    all_passed = all(
        test["passed"]
        for system in verification_results["tests"]
        for test in system["tests"]
    )
    verification_results["success"] = all_passed

    return verification_results

def update_itsm_completion(change_id, verification_results):
    """Update ServiceNow with change completion status"""
    headers = {
        "Authorization": f"Bearer {SERVICENOW_TOKEN}",
        "Content-Type": "application/json"
    }

    if verification_results["success"]:
        state = "closed"
        close_code = "successful"
        notes = "Change completed successfully. All verification tests passed."
    else:
        state = "review"
        close_code = "unsuccessful"
        notes = "Change requires review. Some verification tests failed."

    payload = {
        "state": state,
        "close_code": close_code,
        "close_notes": notes,
        "work_notes": json.dumps(verification_results, indent=2)
    }

    response = requests.patch(
        f"{SERVICENOW_API}/table/change_request/{change_id}",
        headers=headers,
        json=payload
    )
    return response.json()

def revoke_pam_access(change_id):
    """Revoke PAM access after change completion"""
    headers = {
        "Authorization": f"Bearer {WALLIX_API_TOKEN}",
        "Content-Type": "application/json"
    }

    # Find all access grants for this change
    response = requests.get(
        f"{WALLIX_API}/authorizations",
        headers=headers,
        params={"ticket_id": change_id}
    )

    for auth in response.json():
        # Revoke each authorization
        requests.delete(
            f"{WALLIX_API}/authorizations/{auth['id']}",
            headers=headers
        )

    return True

def trigger_credential_rotation(target_systems):
    """Rotate credentials on changed systems"""
    headers = {
        "Authorization": f"Bearer {WALLIX_API_TOKEN}",
        "Content-Type": "application/json"
    }

    for system in target_systems:
        # Get accounts for this device
        response = requests.get(
            f"{WALLIX_API}/devices/{system['device_id']}/accounts",
            headers=headers
        )

        for account in response.json():
            # Trigger rotation
            requests.post(
                f"{WALLIX_API}/accounts/{account['id']}/rotate",
                headers=headers
            )

def main(change_id, target_systems):
    """Post-change completion workflow"""

    # Verify change success
    verification = verify_change_success(change_id, target_systems)

    # Update ITSM
    update_itsm_completion(change_id, verification)

    # Revoke PAM access
    revoke_pam_access(change_id)

    # Rotate credentials
    trigger_credential_rotation(target_systems)

    return verification["success"]
```

---

## Rollback Procedures

### Automated Rollback Triggers

```
+===============================================================================+
|                    ROLLBACK TRIGGER CONDITIONS                                |
+===============================================================================+

  AUTOMATIC ROLLBACK TRIGGERS
  ===========================

  +------------------------------------------------------------------------+
  | Trigger                      | Threshold            | Action           |
  +------------------------------+----------------------+------------------+
  | Safety system fault          | Any SIS alarm        | Immediate halt   |
  |                              |                      | + notify         |
  +------------------------------+----------------------+------------------+
  | Communication loss           | > 30 seconds         | Auto-rollback    |
  |                              |                      | after 5 min      |
  +------------------------------+----------------------+------------------+
  | Critical alarm rate          | > 10/minute          | Pause + review   |
  +------------------------------+----------------------+------------------+
  | Process deviation            | > 2 sigma from       | Alert + review   |
  |                              | baseline             |                  |
  +------------------------------+----------------------+------------------+
  | Change window exceeded       | Window end reached   | Force complete   |
  |                              |                      | or rollback      |
  +------------------------------+----------------------+------------------+

  --------------------------------------------------------------------------

  ROLLBACK DECISION MATRIX
  ========================

  +------------------------------------------------------------------------+
  |                                                                        |
  |  +------------------------+                                            |
  |  | Issue Detected         |                                            |
  |  +----------+-------------+                                            |
  |             |                                                          |
  |             v                                                          |
  |  +------------------------+         +------------------------+         |
  |  | Safety Impact?         |---YES-->| IMMEDIATE ROLLBACK     |         |
  |  +----------+-------------+         | + Emergency Protocol   |         |
  |             |NO                     +------------------------+         |
  |             v                                                          |
  |  +------------------------+         +------------------------+         |
  |  | Production Critical?   |---YES-->| EXPEDITED ROLLBACK     |         |
  |  +----------+-------------+         | (< 15 minutes)         |         |
  |             |NO                     +------------------------+         |
  |             v                                                          |
  |  +------------------------+         +------------------------+         |
  |  | Workaround Available?  |---YES-->| DOCUMENT & CONTINUE    |         |
  |  +----------+-------------+         | Schedule fix           |         |
  |             |NO                     +------------------------+         |
  |             v                                                          |
  |  +------------------------+         +------------------------+         |
  |  | Time Remaining > 2hr?  |---YES-->| TROUBLESHOOT           |         |
  |  +----------+-------------+         | Set deadline           |         |
  |             |NO                     +------------------------+         |
  |             v                                                          |
  |  +------------------------+                                            |
  |  | PLANNED ROLLBACK       |                                            |
  |  +------------------------+                                            |
  |                                                                        |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### Manual Rollback Procedures

```
+===============================================================================+
|                    MANUAL ROLLBACK PROCEDURES                                 |
+===============================================================================+

  PLC CONFIGURATION ROLLBACK
  ==========================

  +------------------------------------------------------------------------+
  |                                                                        |
  |  Step 1: Prepare for Rollback                                          |
  |  +------------------------------------------------------------------+  |
  |  | [ ] Notify operations of pending rollback                        |  |
  |  | [ ] Confirm backup file location and integrity                   |  |
  |  | [ ] Verify rollback access through WALLIX                        |  |
  |  | [ ] Stage rollback documentation                                 |  |
  |  +------------------------------------------------------------------+  |
  |                                                                        |
  |  Step 2: Execute Rollback                                              |
  |  +------------------------------------------------------------------+  |
  |  | # Access PLC through WALLIX                                      |  |
  |  | wabadmin session start --target plc-unit-01 --account plc_admin  |  |
  |  |                                                                  |  |
  |  | # Vendor-specific rollback commands                              |  |
  |  | # Rockwell/Allen-Bradley:                                        |  |
  |  | rslogix5000 --restore /backups/CHG0012345/plc-01_config.acd      |  |
  |  |                                                                  |  |
  |  | # Siemens S7:                                                    |  |
  |  | step7 --download /backups/CHG0012345/plc-01_config.wld           |  |
  |  +------------------------------------------------------------------+  |
  |                                                                        |
  |  Step 3: Verify Rollback                                               |
  |  +------------------------------------------------------------------+  |
  |  | [ ] Compare running config to backup                             |  |
  |  | [ ] Verify all I/O points responding                             |  |
  |  | [ ] Confirm process parameters normal                            |  |
  |  | [ ] Check safety interlocks                                      |  |
  |  +------------------------------------------------------------------+  |
  |                                                                        |
  |  Step 4: Document and Close                                            |
  |  +------------------------------------------------------------------+  |
  |  | [ ] Update change ticket with rollback details                   |  |
  |  | [ ] Record root cause (if known)                                 |  |
  |  | [ ] Schedule follow-up actions                                   |  |
  |  | [ ] Notify stakeholders of rollback completion                   |  |
  |  +------------------------------------------------------------------+  |
  |                                                                        |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### Emergency Rollback Access

```json
{
    "emergency_rollback_authorization": {
        "name": "emergency-rollback-access",
        "description": "Break-glass access for emergency rollback procedures",
        "user_group": "Emergency-Response-Team",
        "target_group": "All-OT-Critical-Systems",

        "approval_policy": {
            "approval_required": true,
            "approver_groups": ["On-Call-Manager", "Shift-Supervisor"],
            "quorum": 1,
            "timeout_minutes": 15,
            "bypass_after_timeout": false
        },

        "access_settings": {
            "max_duration_hours": 2,
            "is_recorded": true,
            "is_critical": true,
            "real_time_monitoring": true,
            "notification_on_start": ["security-ops@company.com", "ot-manager@company.com"]
        },

        "time_frame": "always",

        "post_session_actions": {
            "rotate_credentials": true,
            "require_incident_report": true,
            "notify_management": true
        }
    }
}
```

---

## Emergency Changes

### Break-Glass Procedures

```
+===============================================================================+
|                    EMERGENCY CHANGE PROCEDURES                                |
+===============================================================================+

  BREAK-GLASS ACCESS FLOW
  =======================

  +------------------------------------------------------------------------+
  |                                                                        |
  |  Emergency Detected                                                    |
  |         |                                                              |
  |         v                                                              |
  |  +------------------+                                                  |
  |  | Declare Emergency|  Contact: On-Call Manager                        |
  |  | (Phone/Radio)    |  Document: Time, Nature, Affected Systems        |
  |  +--------+---------+                                                  |
  |           |                                                            |
  |           v                                                            |
  |  +------------------+                                                  |
  |  | Request Break-   |  Via: WALLIX Portal / Emergency Hotline          |
  |  | Glass Access     |  Provide: Name, Employee ID, Justification       |
  |  +--------+---------+                                                  |
  |           |                                                            |
  |           v                                                            |
  |  +------------------+         +------------------+                     |
  |  | Approver         |   15    | Escalate to      |                     |
  |  | Available?       |--min--->| Backup Approver  |                     |
  |  +--------+---------+ timeout +--------+---------+                     |
  |           |YES                         |                               |
  |           v                            v                               |
  |  +------------------+         +------------------+                     |
  |  | Verbal Approval  |         | Verbal Approval  |                     |
  |  | (Recorded)       |         | (Recorded)       |                     |
  |  +--------+---------+         +--------+---------+                     |
  |           |                            |                               |
  |           +-------------+--------------+                               |
  |                         |                                              |
  |                         v                                              |
  |  +------------------------------------------------------------------+  |
  |  |                    WALLIX BASTION                                |  |
  |  |                                                                  |  |
  |  |  +------------------------------------------------------------+  |  |
  |  |  | EMERGENCY ACCESS GRANTED                                   |  |  |
  |  |  |                                                            |  |  |
  |  |  | User: jsmith                                               |  |  |
  |  |  | Approver: shift_supervisor                                 |  |  |
  |  |  | Reason: Equipment failure - compressor trip                |  |  |
  |  |  | Duration: 2 hours (max)                                    |  |  |
  |  |  | Recording: ACTIVE                                          |  |  |
  |  |  | Real-time Monitoring: ACTIVE                               |  |  |
  |  |  +------------------------------------------------------------+  |  |
  |  |                                                                  |  |
  |  +------------------------------------------------------------------+  |
  |                         |                                              |
  |                         v                                              |
  |  +------------------+                                                  |
  |  | Execute Emergency|  All actions recorded                            |
  |  | Remediation      |  Commands logged                                 |
  |  +--------+---------+                                                  |
  |           |                                                            |
  |           v                                                            |
  |  +------------------+                                                  |
  |  | Session End      |  Automatic access revocation                     |
  |  +--------+---------+  Credential rotation triggered                   |
  |           |                                                            |
  |           v                                                            |
  |  +------------------+                                                  |
  |  | Post-Hoc Review  |  Within 24 hours                                 |
  |  | Required         |  Emergency CAB review                            |
  |  +------------------+                                                  |
  |                                                                        |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### Expedited Approval Configuration

```bash
# Create emergency approval workflow
wabadmin approval-policy create \
    --name "emergency-ot-approval" \
    --description "Expedited approval for OT emergencies" \
    --approvers "On-Call-Manager,Shift-Supervisor,Emergency-CAB" \
    --timeout 15m \
    --timeout-action "escalate" \
    --escalate-to "Plant-Manager" \
    --notify-email \
    --notify-sms \
    --require-verbal-confirmation

# Create emergency authorization
wabadmin authorization create \
    --name "emergency-ot-access" \
    --user-group "OT-Engineers" \
    --target-group "Critical-OT-Systems" \
    --approval-policy "emergency-ot-approval" \
    --time-frame "always" \
    --max-duration 2h \
    --recorded \
    --critical \
    --real-time-monitor \
    --post-session-rotate \
    --require-incident-ticket
```

### Post-Hoc Documentation Requirements

```
+===============================================================================+
|                    POST-EMERGENCY DOCUMENTATION                               |
+===============================================================================+

  EMERGENCY CHANGE REPORT (Required within 24 hours)
  ==================================================

  +------------------------------------------------------------------------+
  |                                                                        |
  |  SECTION 1: EMERGENCY DETAILS                                          |
  |  +------------------------------------------------------------------+  |
  |  | Date/Time of Emergency: _______________________                  |  |
  |  | Duration: _______________________                                |  |
  |  | Emergency Type: [ ] Equipment [ ] Safety [ ] Security [ ] Other  |  |
  |  | Affected Systems: _______________________                        |  |
  |  +------------------------------------------------------------------+  |
  |                                                                        |
  |  SECTION 2: RESPONSE                                                   |
  |  +------------------------------------------------------------------+  |
  |  | Responder(s): _______________________                            |  |
  |  | Approver: _______________________                                |  |
  |  | Approval Method: [ ] Portal [ ] Phone [ ] In-Person              |  |
  |  | Access Granted: _______________________                          |  |
  |  | Session ID(s): _______________________                           |  |
  |  +------------------------------------------------------------------+  |
  |                                                                        |
  |  SECTION 3: ACTIONS TAKEN                                              |
  |  +------------------------------------------------------------------+  |
  |  | Description of actions: _______________________                  |  |
  |  | Configuration changes: _______________________                   |  |
  |  | Commands executed: (attached from session recording)             |  |
  |  +------------------------------------------------------------------+  |
  |                                                                        |
  |  SECTION 4: ROOT CAUSE ANALYSIS                                        |
  |  +------------------------------------------------------------------+  |
  |  | Root cause: _______________________                              |  |
  |  | Contributing factors: _______________________                    |  |
  |  | Could this have been prevented? _______________________          |  |
  |  +------------------------------------------------------------------+  |
  |                                                                        |
  |  SECTION 5: FOLLOW-UP ACTIONS                                          |
  |  +------------------------------------------------------------------+  |
  |  | Permanent fix required: [ ] Yes [ ] No                           |  |
  |  | Change ticket created: _______________________                   |  |
  |  | Preventive measures: _______________________                     |  |
  |  | Lessons learned: _______________________                         |  |
  |  +------------------------------------------------------------------+  |
  |                                                                        |
  |  SECTION 6: APPROVALS                                                  |
  |  +------------------------------------------------------------------+  |
  |  | Responder signature: _______________________ Date: _______       |  |
  |  | Manager signature: _______________________ Date: _______         |  |
  |  | Safety review (if applicable): ____________ Date: _______        |  |
  |  +------------------------------------------------------------------+  |
  |                                                                        |
  +------------------------------------------------------------------------+

+===============================================================================+
```

---

## Audit and Compliance

### Change Audit Trail

```
+===============================================================================+
|                    CHANGE MANAGEMENT AUDIT TRAILS                             |
+===============================================================================+

  WALLIX AUDIT EVENTS FOR CHANGE MANAGEMENT
  ==========================================

  +------------------------------------------------------------------------+
  | Event Type                  | Details Captured                         |
  +-----------------------------+------------------------------------------+
  | change.request.created      | Requestor, target, justification,        |
  |                             | ticket ID, timestamp                      |
  +-----------------------------+------------------------------------------+
  | change.approval.requested   | Approvers notified, timeout,              |
  |                             | quorum requirements                       |
  +-----------------------------+------------------------------------------+
  | change.approval.granted     | Approver identity, approval time,         |
  |                             | comments, conditions                      |
  +-----------------------------+------------------------------------------+
  | change.approval.denied      | Approver identity, denial reason,         |
  |                             | timestamp                                 |
  +-----------------------------+------------------------------------------+
  | change.access.granted       | Access window, target systems,            |
  |                             | authorized user, session ID               |
  +-----------------------------+------------------------------------------+
  | change.session.started      | Session ID, source IP, target,            |
  |                             | protocol, timestamp                       |
  +-----------------------------+------------------------------------------+
  | change.command.executed     | Command text, user, target,               |
  |                             | timestamp, risk level                     |
  +-----------------------------+------------------------------------------+
  | change.session.ended        | Session ID, duration, bytes transferred,  |
  |                             | recording location                        |
  +-----------------------------+------------------------------------------+
  | change.access.revoked       | Revocation reason, automatic/manual,      |
  |                             | credential rotation status                |
  +-----------------------------+------------------------------------------+
  | change.verification.passed  | Test results, verifier identity,          |
  |                             | timestamp                                 |
  +-----------------------------+------------------------------------------+
  | change.rollback.initiated   | Trigger, initiator, affected systems      |
  +-----------------------------+------------------------------------------+

+===============================================================================+
```

### Regulatory Evidence Matrix

```
+===============================================================================+
|                    COMPLIANCE EVIDENCE FOR CHANGE MANAGEMENT                  |
+===============================================================================+

  IEC 62443-2-1 (IACS Security Management)
  ========================================

  +------------------------------------------------------------------------+
  | Requirement          | WALLIX Evidence                                 |
  +----------------------+-------------------------------------------------+
  | 4.3.3.3 Change Mgmt  | Change request records, approval workflows,    |
  |                      | session recordings, audit logs                  |
  +----------------------+-------------------------------------------------+
  | 4.3.3.4 Backup/Rec   | Pre-change backup records, restore tests,      |
  |                      | rollback documentation                          |
  +----------------------+-------------------------------------------------+
  | 4.3.3.5 Config Mgmt  | Configuration snapshots, change tracking,      |
  |                      | version history                                 |
  +----------------------+-------------------------------------------------+

  --------------------------------------------------------------------------

  FDA 21 CFR Part 11 (Electronic Records)
  =======================================

  +------------------------------------------------------------------------+
  | Requirement          | WALLIX Evidence                                 |
  +----------------------+-------------------------------------------------+
  | 11.10(e) Audit trail | Complete audit trail with timestamps,          |
  |                      | user identification, before/after states       |
  +----------------------+-------------------------------------------------+
  | 11.10(k) Authority   | Role-based access, approval workflows,         |
  |                      | change control procedures                       |
  +----------------------+-------------------------------------------------+
  | 11.50 Signature      | Approval records with electronic signatures,   |
  |                      | approver identity, timestamps                   |
  +----------------------+-------------------------------------------------+

  --------------------------------------------------------------------------

  NERC CIP-010 (Configuration Change Management)
  ==============================================

  +------------------------------------------------------------------------+
  | Requirement          | WALLIX Evidence                                 |
  +----------------------+-------------------------------------------------+
  | R1.1 Baseline        | Configuration backups, baseline records         |
  +----------------------+-------------------------------------------------+
  | R1.2 Authorize       | Approval workflows, CAB records                 |
  |      Changes         |                                                 |
  +----------------------+-------------------------------------------------+
  | R1.3 Update          | Post-change documentation, configuration        |
  |      Baseline        | updates                                         |
  +----------------------+-------------------------------------------------+
  | R1.4 Test Changes    | Test environment records, verification tests   |
  +----------------------+-------------------------------------------------+
  | R1.5 Security        | Security impact assessments, vulnerability     |
  |      Patches         | analysis                                        |
  +----------------------+-------------------------------------------------+

  --------------------------------------------------------------------------

  NRC 10 CFR 73.54 (Nuclear Cyber Security)
  =========================================

  +------------------------------------------------------------------------+
  | Requirement          | WALLIX Evidence                                 |
  +----------------------+-------------------------------------------------+
  | (g)(1) Change        | Formal change control procedures,              |
  |        Control       | security impact analysis                        |
  +----------------------+-------------------------------------------------+
  | (g)(2) Config Mgmt   | Configuration baselines, change tracking       |
  +----------------------+-------------------------------------------------+
  | (h) Audit            | Complete audit trails, monitoring records,     |
  |                      | session recordings                              |
  +----------------------+-------------------------------------------------+

+===============================================================================+
```

### Change Management KPIs

```
+===============================================================================+
|                    CHANGE MANAGEMENT METRICS                                  |
+===============================================================================+

  KEY PERFORMANCE INDICATORS
  ==========================

  +------------------------------------------------------------------------+
  |                                                                        |
  |  CHANGE SUCCESS METRICS                                                |
  |  +------------------------------------------------------------------+  |
  |  | Metric                        | Target      | Calculation         |  |
  |  +-------------------------------+-------------+---------------------+  |
  |  | Change Success Rate           | > 95%       | Successful /        |  |
  |  |                               |             | Total Changes       |  |
  |  +-------------------------------+-------------+---------------------+  |
  |  | Rollback Rate                 | < 5%        | Rollbacks /         |  |
  |  |                               |             | Total Changes       |  |
  |  +-------------------------------+-------------+---------------------+  |
  |  | Emergency Change Rate         | < 10%       | Emergency /         |  |
  |  |                               |             | Total Changes       |  |
  |  +-------------------------------+-------------+---------------------+  |
  |  | Mean Time to Implement        | < 4 hours   | Avg implementation  |  |
  |  |                               |             | duration            |  |
  |  +-------------------------------+-------------+---------------------+  |
  |  | First-Time Success Rate       | > 90%       | Changes without     |  |
  |  |                               |             | rework              |  |
  |  +-------------------------------+-------------+---------------------+  |
  |                                                                        |
  |  PAM-SPECIFIC METRICS                                                  |
  |  +------------------------------------------------------------------+  |
  |  | Metric                        | Target      | Calculation         |  |
  |  +-------------------------------+-------------+---------------------+  |
  |  | Approval Response Time        | < 2 hours   | Request to          |  |
  |  |                               |             | approval time       |  |
  |  +-------------------------------+-------------+---------------------+  |
  |  | Access Window Utilization     | > 80%       | Active time /       |  |
  |  |                               |             | Granted time        |  |
  |  +-------------------------------+-------------+---------------------+  |
  |  | Session Recording Coverage    | 100%        | Recorded /          |  |
  |  |                               |             | Total sessions      |  |
  |  +-------------------------------+-------------+---------------------+  |
  |  | Post-Change Rotation Rate     | 100%        | Rotated /           |  |
  |  |                               |             | Changed accounts    |  |
  |  +-------------------------------+-------------+---------------------+  |
  |  | Ticket Linkage Rate           | 100%        | Sessions with       |  |
  |  |                               |             | valid tickets       |  |
  |  +-------------------------------+-------------+---------------------+  |
  |                                                                        |
  +------------------------------------------------------------------------+

  REPORTING QUERIES
  =================

  # Monthly change success rate
  wabadmin report --type change-metrics --period monthly \
      --metric success_rate --output csv

  # Emergency change analysis
  wabadmin audit --filter "change_type=emergency" --last 90d \
      --group-by month --export emergency-changes.csv

  # Approval response times
  wabadmin report --type approval-metrics --period weekly \
      --metric response_time --output json

+===============================================================================+
```

---

## ITSM Integration

### ServiceNow Integration

```
+===============================================================================+
|                    SERVICENOW CHANGE MANAGEMENT INTEGRATION                   |
+===============================================================================+

  INTEGRATION ARCHITECTURE
  ========================

  +------------------------------------------------------------------------+
  |                                                                        |
  |   ServiceNow                                   WALLIX Bastion          |
  |   +------------------+                    +------------------+         |
  |   |                  |   REST API (TLS)   |                  |         |
  |   | Change Request   +<------------------>+ Authorization    |         |
  |   |                  |   Bi-directional   | Workflow         |         |
  |   +--------+---------+                    +--------+---------+         |
  |            |                                       |                   |
  |            v                                       v                   |
  |   +------------------+                    +------------------+         |
  |   |                  |   Webhooks         |                  |         |
  |   | Approval Flow    +<------------------>+ Approval Engine  |         |
  |   |                  |                    |                  |         |
  |   +--------+---------+                    +--------+---------+         |
  |            |                                       |                   |
  |            v                                       v                   |
  |   +------------------+                    +------------------+         |
  |   |                  |   Session Events   |                  |         |
  |   | Work Notes       +<-------------------+ Audit Log        |         |
  |   |                  |                    |                  |         |
  |   +------------------+                    +------------------+         |
  |                                                                        |
  +------------------------------------------------------------------------+

  INTEGRATION FLOWS
  =================

  FLOW 1: Change Approval -> PAM Access Grant
  -------------------------------------------

  1. Change ticket approved in ServiceNow
  2. ServiceNow triggers WALLIX webhook
  3. WALLIX creates time-bound authorization
  4. WALLIX notifies requestor of access availability

  FLOW 2: PAM Session -> Change Work Notes
  -----------------------------------------

  1. User starts session through WALLIX
  2. WALLIX validates change ticket
  3. Session events posted to ServiceNow work notes
  4. Session completion updates change ticket

  FLOW 3: Emergency Access -> Incident Creation
  ----------------------------------------------

  1. Emergency access requested in WALLIX
  2. WALLIX creates incident in ServiceNow
  3. Session recorded and linked to incident
  4. Post-session, change request created for permanent fix

+===============================================================================+
```

### ServiceNow API Integration

```python
#!/usr/bin/env python3
"""
ServiceNow <-> WALLIX Bastion Change Management Integration
"""

import requests
import json
from datetime import datetime, timedelta

# Configuration
SERVICENOW_INSTANCE = "company.service-now.com"
SERVICENOW_API = f"https://{SERVICENOW_INSTANCE}/api/now"
WALLIX_API = "https://bastion.company.com/api"

class ChangeManagementIntegration:

    def __init__(self, snow_token, wallix_token):
        self.snow_headers = {
            "Authorization": f"Bearer {snow_token}",
            "Content-Type": "application/json"
        }
        self.wallix_headers = {
            "Authorization": f"Bearer {wallix_token}",
            "Content-Type": "application/json"
        }

    def validate_change_ticket(self, ticket_number):
        """Validate change ticket exists and is approved"""
        response = requests.get(
            f"{SERVICENOW_API}/table/change_request",
            headers=self.snow_headers,
            params={
                "sysparm_query": f"number={ticket_number}",
                "sysparm_fields": "sys_id,number,state,start_date,end_date,assignment_group"
            }
        )

        if response.status_code != 200:
            return {"valid": False, "error": "Ticket not found"}

        tickets = response.json().get("result", [])
        if not tickets:
            return {"valid": False, "error": "Ticket not found"}

        ticket = tickets[0]

        # Validate ticket state (implement = 2)
        if ticket["state"] != "2":
            return {"valid": False, "error": "Change not in implement state"}

        # Validate time window
        now = datetime.utcnow()
        start = datetime.fromisoformat(ticket["start_date"].replace("Z", "+00:00"))
        end = datetime.fromisoformat(ticket["end_date"].replace("Z", "+00:00"))

        if not (start <= now <= end):
            return {"valid": False, "error": "Outside change window"}

        return {
            "valid": True,
            "ticket": ticket,
            "remaining_time": (end - now).total_seconds()
        }

    def create_pam_authorization(self, change_ticket, user, targets):
        """Create time-bound PAM authorization for approved change"""

        validation = self.validate_change_ticket(change_ticket)
        if not validation["valid"]:
            raise ValueError(validation["error"])

        # Calculate access duration (remaining change window)
        duration_hours = min(
            validation["remaining_time"] / 3600,
            8  # Max 8 hours
        )

        payload = {
            "authorization_name": f"change-{change_ticket}",
            "description": f"Access for change ticket {change_ticket}",
            "user_group": user,
            "target_group": targets,
            "active": True,
            "is_recorded": True,
            "is_critical": True,
            "approval_required": False,  # Already approved in ServiceNow
            "has_comment": True,
            "time_frames": [{
                "start": datetime.utcnow().isoformat(),
                "end": (datetime.utcnow() + timedelta(hours=duration_hours)).isoformat()
            }],
            "metadata": {
                "change_ticket": change_ticket,
                "servicenow_sysid": validation["ticket"]["sys_id"]
            }
        }

        response = requests.post(
            f"{WALLIX_API}/authorizations",
            headers=self.wallix_headers,
            json=payload
        )

        return response.json()

    def update_change_worknotes(self, ticket_sysid, message):
        """Update ServiceNow change ticket with work notes"""
        payload = {
            "work_notes": f"[WALLIX PAM] {message}"
        }

        response = requests.patch(
            f"{SERVICENOW_API}/table/change_request/{ticket_sysid}",
            headers=self.snow_headers,
            json=payload
        )

        return response.status_code == 200

    def on_session_start(self, session_data):
        """Webhook handler for session start events"""
        ticket = session_data.get("ticket_id")
        if not ticket:
            return

        # Get ServiceNow sys_id
        validation = self.validate_change_ticket(ticket)
        if not validation["valid"]:
            return

        message = (
            f"Session started\n"
            f"User: {session_data['user']}\n"
            f"Target: {session_data['target']}\n"
            f"Protocol: {session_data['protocol']}\n"
            f"Session ID: {session_data['session_id']}\n"
            f"Time: {datetime.utcnow().isoformat()}"
        )

        self.update_change_worknotes(
            validation["ticket"]["sys_id"],
            message
        )

    def on_session_end(self, session_data):
        """Webhook handler for session end events"""
        ticket = session_data.get("ticket_id")
        if not ticket:
            return

        validation = self.validate_change_ticket(ticket)
        if not validation["valid"]:
            return

        message = (
            f"Session ended\n"
            f"User: {session_data['user']}\n"
            f"Duration: {session_data['duration']}\n"
            f"Session ID: {session_data['session_id']}\n"
            f"Recording: {session_data['recording_url']}"
        )

        self.update_change_worknotes(
            validation["ticket"]["sys_id"],
            message
        )

    def create_emergency_incident(self, emergency_data):
        """Create incident for emergency access"""
        payload = {
            "short_description": f"Emergency OT Access: {emergency_data['reason']}",
            "description": (
                f"Emergency access granted through WALLIX PAM\n\n"
                f"User: {emergency_data['user']}\n"
                f"Target Systems: {', '.join(emergency_data['targets'])}\n"
                f"Approver: {emergency_data['approver']}\n"
                f"Reason: {emergency_data['reason']}\n"
                f"Session ID: {emergency_data['session_id']}"
            ),
            "category": "Security",
            "subcategory": "Emergency Access",
            "impact": "2",
            "urgency": "1",
            "assignment_group": "OT Security"
        }

        response = requests.post(
            f"{SERVICENOW_API}/table/incident",
            headers=self.snow_headers,
            json=payload
        )

        return response.json()

# WALLIX Webhook Configuration
WEBHOOK_CONFIG = {
    "webhooks": [
        {
            "name": "servicenow-session-start",
            "event": "session.started",
            "url": "https://automation.company.com/wallix/session-start",
            "method": "POST",
            "headers": {
                "Authorization": "Bearer ${AUTOMATION_TOKEN}"
            },
            "payload_template": {
                "session_id": "${session.id}",
                "user": "${session.user}",
                "target": "${session.target}",
                "protocol": "${session.protocol}",
                "ticket_id": "${session.ticket_id}"
            }
        },
        {
            "name": "servicenow-session-end",
            "event": "session.ended",
            "url": "https://automation.company.com/wallix/session-end",
            "method": "POST",
            "headers": {
                "Authorization": "Bearer ${AUTOMATION_TOKEN}"
            },
            "payload_template": {
                "session_id": "${session.id}",
                "user": "${session.user}",
                "duration": "${session.duration}",
                "recording_url": "${session.recording_url}",
                "ticket_id": "${session.ticket_id}"
            }
        }
    ]
}
```

### Change Ticket Linking Configuration

```bash
# Configure ServiceNow integration in WALLIX
wabadmin integration add --type servicenow \
    --name "snow-change-management" \
    --instance "company.service-now.com" \
    --client-id "${SNOW_CLIENT_ID}" \
    --client-secret "${SNOW_CLIENT_SECRET}" \
    --table "change_request" \
    --validate-on-access

# Enable ticket validation for OT authorizations
wabadmin authorization update "ot-change-access" \
    --require-ticket \
    --ticket-integration "snow-change-management" \
    --validate-ticket-state "implement" \
    --validate-ticket-window

# Configure automatic work note updates
wabadmin webhook create \
    --name "snow-worknotes" \
    --events "session.started,session.ended,approval.granted" \
    --url "https://automation.company.com/wallix/snow-update" \
    --auth-header "Bearer ${AUTOMATION_TOKEN}"
```

---

## Related Documentation

| Document | Description |
|----------|-------------|
| [JIT Access](../34-jit-access/README.md) | Time-bound access and approval workflows |
| [OT Architecture](../16-ot-architecture/README.md) | Zone-based deployment for OT |
| [IEC 62443 Compliance](../20-iec62443-compliance/README.md) | Industrial security standards |
| [Incident Response](../32-incident-response/README.md) | Emergency response procedures |
| [OT Integration](../22-ot-integration/README.md) | SIEM and CMDB integration |
| [Compliance Evidence](../48-compliance-evidence/README.md) | Audit evidence collection |

---

## External References

| Resource | URL |
|----------|-----|
| WALLIX Documentation | https://pam.wallix.one/documentation |
| IEC 62443-2-3 Patch Management | https://www.iec.ch/62443 |
| NIST SP 800-82 Rev 3 | https://csrc.nist.gov/publications/detail/sp/800-82/rev-3/final |
| ISA/IEC 62443 Standards | https://www.isa.org/standards-and-publications/isa-standards/isa-iec-62443-series-of-standards |
| ServiceNow Change Management | https://docs.servicenow.com/bundle/change-management |
| NERC CIP Standards | https://www.nerc.com/pa/Stand/Pages/CIPStandards.aspx |

---

<p align="center">
  <sub>WALLIX PAM4OT - OT Change Management Guide - February 2026</sub>
</p>
