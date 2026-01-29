# 18 - SCADA/ICS Access Management

## Table of Contents

1. [SCADA Access Overview](#scada-access-overview)
2. [HMI Access Control](#hmi-access-control)
3. [PLC/RTU Programming Access](#plcrtu-programming-access)
4. [DCS Access Management](#dcs-access-management)
5. [Safety System Access](#safety-system-access)
6. [Vendor Remote Access](#vendor-remote-access)
7. [Historian Access](#historian-access)
8. [Access Workflow Examples](#access-workflow-examples)

---

## SCADA Access Overview

### SCADA Components Requiring PAM

```
+===============================================================================+
|                    SCADA COMPONENTS FOR PAM                                   |
+===============================================================================+
|                                                                               |
|  SCADA SYSTEM COMPONENTS                                                      |
|  =======================                                                      |
|                                                                               |
|  +-----------------------------------------------------------------------+ |
|  |                                                                          | |
|  |   +------------------------------------------------------------------+  | |
|  |   |                    LEVEL 3: SITE OPERATIONS                       |  | |
|  |   |                                                                   |  | |
|  |   |   +-------------+  +-------------+  +-------------+             |  | |
|  |   |   | SCADA       |  | Historian   |  | Engineering |             |  | |
|  |   |   | Server      |  | Server      |  | Workstation |             |  | |
|  |   |   |             |  |             |  |             |             |  | |
|  |   |   | Windows/    |  | Windows/    |  | Windows     |             |  | |
|  |   |   | Linux       |  | Linux       |  |             |             |  | |
|  |   |   +-------------+  +-------------+  +-------------+             |  | |
|  |   |                                                                   |  | |
|  |   |   PAM: RDP/SSH access, session recording, MFA                    |  | |
|  |   +------------------------------------------------------------------+  | |
|  |                                                                          | |
|  |   +------------------------------------------------------------------+  | |
|  |   |                    LEVEL 2: AREA CONTROL                          |  | |
|  |   |                                                                   |  | |
|  |   |   +-------------+  +-------------+  +-------------+             |  | |
|  |   |   | HMI         |  | HMI         |  | Operator    |             |  | |
|  |   |   | Station 1   |  | Station 2   |  | Console     |             |  | |
|  |   |   |             |  |             |  |             |             |  | |
|  |   |   | Windows     |  | Windows     |  | Windows/    |             |  | |
|  |   |   | Embedded    |  | Embedded    |  | Linux       |             |  | |
|  |   |   +-------------+  +-------------+  +-------------+             |  | |
|  |   |                                                                   |  | |
|  |   |   PAM: RDP/VNC access, individual accountability                 |  | |
|  |   +------------------------------------------------------------------+  | |
|  |                                                                          | |
|  |   +------------------------------------------------------------------+  | |
|  |   |                    LEVEL 1: BASIC CONTROL                         |  | |
|  |   |                                                                   |  | |
|  |   |   +-------------+  +-------------+  +-------------+             |  | |
|  |   |   | PLC         |  | RTU         |  | DCS         |             |  | |
|  |   |   |             |  |             |  | Controller  |             |  | |
|  |   |   | Allen-Bradley|  | ABB, SEL    |  |             |             |  | |
|  |   |   | Siemens, etc|  | Emerson     |  | Honeywell   |             |  | |
|  |   |   +-------------+  +-------------+  +-------------+             |  | |
|  |   |                                                                   |  | |
|  |   |   PAM: Access via jump hosts, approval required                  |  | |
|  |   +------------------------------------------------------------------+  | |
|  |                                                                          | |
|  +-----------------------------------------------------------------------+ |
|                                                                               |
+===============================================================================+
```

### Access Matrix

```
+===============================================================================+
|                    SCADA ACCESS MATRIX                                        |
+===============================================================================+
|                                                                               |
|  +-----------------+-------------------------------------------------------+ |
|  |                 |              TARGET SYSTEMS                           | |
|  |                 +---------+---------+---------+---------+-------------+ |
|  | USER ROLE       | SCADA   | HMI     | Eng WS  | PLC/RTU | Historian   | |
|  |                 | Server  |         |         |         |             | |
|  +-----------------+---------+---------+---------+---------+-------------+ |
|  | Operator        | View    | Full    |   -     |   -     | View        | |
|  | (Shift)         | only    |         |         |         |             | |
|  +-----------------+---------+---------+---------+---------+-------------+ |
|  | Supervisor      | View    | Full    | View    |   -     | View        | |
|  |                 |         |         |         |         |             | |
|  +-----------------+---------+---------+---------+---------+-------------+ |
|  | Control Engr    | Config  | Config  | Full    | Program | Full        | |
|  |                 |         |         |         |(Approval|             | |
|  +-----------------+---------+---------+---------+---------+-------------+ |
|  | SCADA Admin     | Full    | Config  | Full    |   -     | Full        | |
|  |                 |         |         |         |         |             | |
|  +-----------------+---------+---------+---------+---------+-------------+ |
|  | Vendor          | Specific| Specific| Specific| Specific|    -        | |
|  | (Time-limited)  | systems | systems | systems |(Approval|             | |
|  +-----------------+---------+---------+---------+---------+-------------+ |
|                                                                               |
|  WALLIX AUTHORIZATION MAPPING                                                 |
|  ============================                                                 |
|                                                                               |
|  Each cell = WALLIX Authorization with specific settings:                    |
|  * User Group = Role                                                         |
|  * Target Group = System type                                                |
|  * Subprotocols = Allowed actions                                            |
|  * Approval = Required for sensitive access                                  |
|  * Recording = Always enabled                                                |
|  * Time frame = Shift hours or business hours                                |
|                                                                               |
+===============================================================================+
```

---

## HMI Access Control

### HMI Architecture

```
+===============================================================================+
|                    HMI ACCESS CONTROL                                         |
+===============================================================================+
|                                                                               |
|  CHALLENGE: SHARED HMI ACCOUNTS                                               |
|  ==============================                                               |
|                                                                               |
|  Typical HMI setup:                                                           |
|  * "Operator" account used by all shift personnel                            |
|  * "Supervisor" account shared among supervisors                             |
|  * No individual accountability                                              |
|  * Passwords never changed                                                   |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  WALLIX SOLUTION                                                              |
|  ===============                                                              |
|                                                                               |
|                                                                               |
|       +--------------------------------------------------------------+       |
|       |                    CONTROL ROOM                              |       |
|       |                                                              |       |
|       |   +-----------+  +-----------+  +-----------+              |       |
|       |   | Operator  |  | Operator  |  | Supervisor|              |       |
|       |   |  Smith    |  |  Jones    |  |  Wilson   |              |       |
|       |   +-----+-----+  +-----+-----+  +-----+-----+              |       |
|       |         |              |              |                      |       |
|       +---------|--------------|--------------|----------------------+       |
|                 |              |              |                               |
|                 |   Individual credentials   |                               |
|                 |              |              |                               |
|                 v              v              v                               |
|         +====================================================+               |
|         |              WALLIX BASTION                        |               |
|         |                                                     |               |
|         |  1. Authenticate individual user                   |               |
|         |  2. Check authorization (role-based)               |               |
|         |  3. Start recording                                |               |
|         |  4. Inject HMI credentials (user never sees)       |               |
|         |  5. Connect to HMI                                 |               |
|         |                                                     |               |
|         +=======================+============================+               |
|                                 |                                            |
|                    Credential injection                                      |
|                    (shared HMI account)                                      |
|                                 |                                            |
|                                 v                                            |
|         +-----------------------------------------------------+              |
|         |                    HMI STATIONS                     |              |
|         |                                                     |              |
|         |   +-----------+  +-----------+  +-----------+     |              |
|         |   |   HMI 1   |  |   HMI 2   |  |   HMI 3   |     |              |
|         |   |           |  |           |  |           |     |              |
|         |   | Account:  |  | Account:  |  | Account:  |     |              |
|         |   | Operator  |  | Operator  |  | Supervisor|     |              |
|         |   | (injected)|  | (injected)|  | (injected)|     |              |
|         |   +-----------+  +-----------+  +-----------+     |              |
|         |                                                     |              |
|         +-----------------------------------------------------+              |
|                                                                               |
|  RESULT:                                                                      |
|  =======                                                                      |
|  [x] Individual accountability (Smith's session vs Jones' session)             |
|  [x] Session recording shows exactly who did what                              |
|  [x] HMI passwords can be rotated without user impact                          |
|  [x] Role-based access (Operator vs Supervisor privileges)                     |
|                                                                               |
+===============================================================================+
```

### HMI Configuration Example

```
+===============================================================================+
|                    HMI WALLIX CONFIGURATION                                   |
+===============================================================================+
|                                                                               |
|  DEVICE CONFIGURATION                                                         |
|  ====================                                                         |
|                                                                               |
|  {                                                                            |
|      "device_name": "HMI-Station-01",                                        |
|      "host": "192.168.10.20",                                                |
|      "domain": "SCADA-Control",                                              |
|      "description": "Control Room HMI Station 1"                             |
|  }                                                                            |
|                                                                               |
|  SERVICE CONFIGURATION                                                        |
|  =====================                                                        |
|                                                                               |
|  {                                                                            |
|      "service_name": "RDP",                                                  |
|      "protocol": "RDP",                                                      |
|      "port": 3389,                                                           |
|      "security_level": "NLA",                                                |
|      "subprotocols": {                                                       |
|          "clipboard": false,                                                 |
|          "drive_redirection": false,                                         |
|          "printer": false                                                    |
|      }                                                                        |
|  }                                                                            |
|                                                                               |
|  ACCOUNT CONFIGURATION                                                        |
|  =====================                                                        |
|                                                                               |
|  {                                                                            |
|      "account_name": "Operator@HMI-Station-01",                              |
|      "login": "Operator",                                                     |
|      "device": "HMI-Station-01",                                             |
|      "credentials": {                                                         |
|          "type": "password",                                                  |
|          "password": "********"                                              |
|      },                                                                       |
|      "auto_change_password": true,                                           |
|      "change_password_interval_days": 30                                     |
|  }                                                                            |
|                                                                               |
|  AUTHORIZATION                                                                |
|  =============                                                                |
|                                                                               |
|  {                                                                            |
|      "authorization_name": "operators-hmi-access",                           |
|      "user_group": "Control-Room-Operators",                                 |
|      "target_group": "HMI-Stations",                                         |
|                                                                               |
|      "is_recorded": true,                                                     |
|      "is_critical": false,                                                    |
|      "approval_required": false,                                              |
|                                                                               |
|      "time_frames": ["shift-hours-24x7"],                                    |
|      "subprotocols": ["RDP"]                                                 |
|  }                                                                            |
|                                                                               |
+===============================================================================+
```

---

## PLC/RTU Programming Access

### PLC Access Control

```
+===============================================================================+
|                    PLC PROGRAMMING ACCESS                                     |
+===============================================================================+
|                                                                               |
|  RISK: PLC Programming                                                        |
|  =====================                                                        |
|                                                                               |
|  PLC programming changes can:                                                |
|  * Stop production                                                           |
|  * Cause equipment damage                                                    |
|  * Create safety hazards                                                     |
|  * Be difficult to reverse                                                   |
|                                                                               |
|  THEREFORE: Highest level of control required                                |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  WALLIX PLC ACCESS WORKFLOW                                                   |
|  ==========================                                                   |
|                                                                               |
|                                                                               |
|     +-------------+                                                          |
|     |  Engineer   |                                                          |
|     |  Request    |                                                          |
|     +------+------+                                                          |
|            |                                                                  |
|            | 1. Request access (with ticket/justification)                   |
|            v                                                                  |
|     +==================+                                                     |
|     | WALLIX BASTION   |                                                     |
|     |                  |                                                     |
|     | 2. Check auth    |                                                     |
|     | 3. APPROVAL REQ  |--------------------------------------+              |
|     +========+=========+                                      |              |
|              |                                                 |              |
|              |                                                 v              |
|              |                                       +-----------------+     |
|              |                                       |   Supervisor    |     |
|              |                                       |                 |     |
|              |                                       | 4. Review &     |     |
|              |                                       |    Approve      |     |
|              |                                       +--------+--------+     |
|              |                                                |              |
|              |<-----------------------------------------------+              |
|              |  5. Approval received                                         |
|              |                                                               |
|              |  6. Session established (RECORDED)                            |
|              v                                                               |
|     +------------------+                                                     |
|     |  Engineering     |                                                     |
|     |  Workstation     |                                                     |
|     |                  |                                                     |
|     |  [RSLogix 5000]  |                                                     |
|     |  [TIA Portal]    |                                                     |
|     |  [etc.]          |                                                     |
|     +--------+---------+                                                     |
|              |                                                               |
|              | 7. PLC programming session                                    |
|              |    (through workstation)                                      |
|              v                                                               |
|     +------------------+                                                     |
|     |       PLC        |                                                     |
|     |                  |                                                     |
|     |  Changes made    |                                                     |
|     |  and recorded    |                                                     |
|     +------------------+                                                     |
|                                                                               |
|                                                                               |
|  8. POST-SESSION:                                                             |
|     * Recording archived                                                     |
|     * MOC (Management of Change) record created                              |
|     * Optional: Password rotation on engineering account                     |
|                                                                               |
+===============================================================================+
```

### PLC Authorization Configuration

```json
{
    "authorization_name": "plc-programming-critical",
    "description": "PLC programming access - requires approval",

    "user_group": "Control-Engineers",
    "target_group": "Engineering-Workstations",

    "active": true,
    "is_recorded": true,
    "is_critical": true,
    "approval_required": true,
    "has_comment": true,

    "approval_workflow": {
        "name": "dual-approval-engineering",
        "approvers": ["Operations-Supervisors", "Engineering-Managers"],
        "min_approvals": 1,
        "timeout_hours": 4,
        "notification": {
            "email": true,
            "sms": true
        }
    },

    "time_frames": ["business-hours"],

    "session_settings": {
        "max_duration_hours": 4,
        "inactivity_timeout_minutes": 30,
        "post_session_password_rotation": true
    },

    "subprotocols": ["RDP"]
}
```

---

## DCS Access Management

### DCS Architecture

```
+===============================================================================+
|                    DCS ACCESS MANAGEMENT                                      |
+===============================================================================+
|                                                                               |
|  DCS CHARACTERISTICS                                                          |
|  ===================                                                          |
|                                                                               |
|  * Integrated system (vendor-specific)                                       |
|  * Honeywell, Emerson, ABB, Yokogawa, Siemens                               |
|  * Tight coupling between components                                         |
|  * Proprietary protocols and tools                                           |
|  * Often runs 24/7 for years without restart                                 |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  TYPICAL DCS NETWORK                                                          |
|  ===================                                                          |
|                                                                               |
|                                                                               |
|         +---------------------------------------------------------+          |
|         |                    CONTROL NETWORK                      |          |
|         |                                                         |          |
|         |  +--------------+  +--------------+                    |          |
|         |  | DCS Server 1 |  | DCS Server 2 |                    |          |
|         |  | (Primary)    |  | (Redundant)  |                    |          |
|         |  +--------------+  +--------------+                    |          |
|         |                                                         |          |
|         |  +--------------+  +--------------+  +--------------+ |          |
|         |  | Operator     |  | Operator     |  | Engineering  | |          |
|         |  | Station 1    |  | Station 2    |  | Station      | |          |
|         |  +--------------+  +--------------+  +--------------+ |          |
|         |                                                         |          |
|         |  +--------------+  +--------------+                    |          |
|         |  | Historian    |  | Batch Server |                    |          |
|         |  |              |  |              |                    |          |
|         |  +--------------+  +--------------+                    |          |
|         |                                                         |          |
|         +-------------------------+-------------------------------+          |
|                                   |                                          |
|                          Control Network                                     |
|                                   |                                          |
|         +-------------------------+-------------------------------+          |
|         |                         |        I/O NETWORK            |          |
|         |                         |                               |          |
|         |  +-----------+  +-----------+  +-----------+          |          |
|         |  |Controller |  |Controller |  |Controller |          |          |
|         |  |    1      |  |    2      |  |    3      |          |          |
|         |  +-----------+  +-----------+  +-----------+          |          |
|         |                                                         |          |
|         +---------------------------------------------------------+          |
|                                                                               |
|                                                                               |
|  WALLIX ACCESS POINTS                                                         |
|  ====================                                                         |
|                                                                               |
|  +-----------------------------------------------------------------------+ |
|  | Target System        | Access Method  | Use Case                        | |
|  +----------------------+----------------+---------------------------------+ |
|  | DCS Server           | RDP            | System administration           | |
|  | Operator Station     | RDP            | Operations, monitoring          | |
|  | Engineering Station  | RDP            | Configuration changes           | |
|  | Historian            | RDP/SSH        | Data access, reporting          | |
|  | Controller (direct)  | Via Eng Station| Emergency only, approved        | |
|  +----------------------+----------------+---------------------------------+ |
|                                                                               |
+===============================================================================+
```

---

## Safety System Access

### Safety Instrumented System (SIS)

```
+===============================================================================+
|                    SAFETY SYSTEM ACCESS                                       |
+===============================================================================+
|                                                                               |
|  WARNING: HIGHEST CRITICALITY - SAFETY SYSTEMS                               |
|  =============================================                               |
|                                                                               |
|  Safety systems protect against:                                              |
|  * Loss of life                                                              |
|  * Environmental damage                                                      |
|  * Equipment destruction                                                     |
|                                                                               |
|  Standards: IEC 61508, IEC 61511 (process), IEC 62061 (machinery)            |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  SAFETY SYSTEM ISOLATION                                                      |
|  =======================                                                      |
|                                                                               |
|                                                                               |
|         +---------------------------------------------------------+          |
|         |                    BPCS (Control)                       |          |
|         |                                                         |          |
|         |  +--------------+  +--------------+                    |          |
|         |  | DCS/SCADA    |  | Engineering  |                    |          |
|         |  | Server       |  | Workstation  |                    |          |
|         |  +--------------+  +--------------+                    |          |
|         |                                                         |          |
|         +---------------------------------------------------------+          |
|                                   |                                          |
|                          LIMITED CONNECTION                                  |
|                          (Read-only data)                                    |
|                                   |                                          |
|         +=========================================================+            |
|         |              SAFETY SYSTEM NETWORK                     |            |
|         |              (Physically Separate)                     |            |
|         |                                                        |            |
|         |  +--------------+  +--------------+                   |            |
|         |  | SIS Logic    |  | SIS          |                   |            |
|         |  | Solver       |  | Engineering  |                   |            |
|         |  | (Safety PLC) |  | Station      |                   |            |
|         |  +--------------+  +--------------+                   |            |
|         |                                                        |            |
|         |  Access: EXTREMELY RESTRICTED                         |            |
|         |                                                        |            |
|         +========================================================+            |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  WALLIX SAFETY SYSTEM ACCESS CONTROLS                                         |
|  ====================================                                         |
|                                                                               |
|  1. SEPARATE AUTHORIZATION                                                    |
|     * Dedicated authorization for SIS access                                 |
|     * Different from normal engineering access                               |
|                                                                               |
|  2. DUAL APPROVAL                                                             |
|     * Requires TWO approvers (4-eyes principle)                              |
|     * One from Operations, one from Safety/Engineering                       |
|                                                                               |
|  3. TIME-LIMITED ACCESS                                                       |
|     * Maximum 2-hour sessions                                                |
|     * Auto-terminate after maintenance window                                |
|                                                                               |
|  4. ENHANCED RECORDING                                                        |
|     * Full video recording with OCR                                          |
|     * Command logging                                                        |
|     * Automatic backup of session                                            |
|                                                                               |
|  5. POST-SESSION REQUIREMENTS                                                 |
|     * Mandatory verification checklist                                       |
|     * Sign-off from multiple parties                                         |
|     * MOC (Management of Change) documentation                               |
|                                                                               |
+===============================================================================+
```

---

## Vendor Remote Access

### Vendor Access Architecture

```
+===============================================================================+
|                    VENDOR REMOTE ACCESS                                       |
+===============================================================================+
|                                                                               |
|  VENDOR ACCESS CHALLENGES                                                     |
|  ========================                                                     |
|                                                                               |
|  * Multiple vendors (PLC, SCADA, HMI, drives, etc.)                         |
|  * Different support personnel each time                                     |
|  * 24/7 access requirements for emergencies                                  |
|  * No visibility into vendor activities                                      |
|  * Compliance requirements for third-party access                            |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  WALLIX VENDOR ACCESS SOLUTION                                                |
|  =============================                                                |
|                                                                               |
|                                                                               |
|       INTERNET                                                                |
|           |                                                                   |
|           |                                                                   |
|   +-------+-------+  +---------------+  +---------------+                   |
|   |   Siemens     |  |  Rockwell     |  |   ABB         |                   |
|   |   Support     |  |  Support      |  |   Support     |                   |
|   +-------+-------+  +-------+-------+  +-------+-------+                   |
|           |                  |                  |                            |
|           |    HTTPS (443)   |                  |                            |
|           |                  |                  |                            |
|           +------------------+------------------+                            |
|                              |                                               |
|                              v                                               |
|         +========================================================+          |
|         |              WALLIX ACCESS MANAGER                     |          |
|         |              (DMZ - Internet Facing)                   |          |
|         |                                                         |          |
|         |  1. Vendor logs in with individual credentials         |          |
|         |  2. MFA required (TOTP, SMS, etc.)                     |          |
|         |  3. Sees only authorized targets                       |          |
|         |  4. Requests access (generates ticket)                 |          |
|         |                                                         |          |
|         +=========================+==============================+          |
|                                 |                                            |
|                                 v                                            |
|         +========================================================+          |
|         |              WALLIX BASTION                            |          |
|         |              (Internal - OT DMZ)                       |          |
|         |                                                         |          |
|         |  5. Approval workflow (if required)                    |          |
|         |  6. Session established (RECORDED)                     |          |
|         |  7. Credential injection                               |          |
|         |  8. Real-time monitoring available                     |          |
|         |                                                         |          |
|         +=========================+==============================+          |
|                                 |                                            |
|              +------------------+------------------+                        |
|              |                  |                  |                        |
|              v                  v                  v                        |
|     +-----------------+ +-----------------+ +-----------------+            |
|     | Siemens PLCs    | | Rockwell PLCs   | | ABB Systems     |            |
|     | (via TIA Portal)| | (via Eng WS)    | | (via Eng WS)    |            |
|     +-----------------+ +-----------------+ +-----------------+            |
|                                                                               |
|                                                                               |
|  VENDOR ACCOUNT MANAGEMENT                                                    |
|  =========================                                                    |
|                                                                               |
|  Option 1: Individual vendor accounts                                        |
|  * Create account per vendor technician                                      |
|  * Best accountability                                                       |
|  * More management overhead                                                  |
|                                                                               |
|  Option 2: Vendor company accounts                                           |
|  * One account per vendor company                                            |
|  * Vendor tracks who uses it                                                 |
|  * Less overhead, less accountability                                        |
|                                                                               |
|  RECOMMENDATION: Individual accounts with time-limited access                |
|                                                                               |
+===============================================================================+
```

### Vendor Authorization Example

```json
{
    "authorization_name": "siemens-vendor-access",
    "description": "Siemens support access to Siemens equipment",

    "user_group": "Siemens-Support-Vendor",
    "target_group": "Siemens-Engineering-Stations",

    "active": true,
    "is_recorded": true,
    "is_critical": true,
    "approval_required": true,
    "has_comment": true,

    "approval_workflow": {
        "name": "vendor-access-approval",
        "approvers": ["OT-Security-Team", "Plant-Operations"],
        "timeout_hours": 2,
        "validity_hours": 4
    },

    "time_frames": ["business-hours-extended"],

    "session_settings": {
        "max_duration_hours": 4,
        "idle_timeout_minutes": 15,
        "allow_session_extension": true,
        "extension_requires_approval": true
    },

    "subprotocols": ["RDP"]
}
```

---

## Access Workflow Examples

### Emergency Access Workflow

```
+===============================================================================+
|                    EMERGENCY ACCESS WORKFLOW                                  |
+===============================================================================+
|                                                                               |
|  SCENARIO: Production down, immediate access needed                           |
|  =================================================                           |
|                                                                               |
|                                                                               |
|  +-----------------+                                                         |
|  | INCIDENT        |   T+0 minutes                                           |
|  | Production line |                                                         |
|  | down            |                                                         |
|  +--------+--------+                                                         |
|           |                                                                   |
|           v                                                                   |
|  +-----------------+                                                         |
|  | Engineer        |   T+2 minutes                                           |
|  | requests        |                                                         |
|  | emergency       |                                                         |
|  | access          |                                                         |
|  +--------+--------+                                                         |
|           |                                                                   |
|           | Emergency authorization                                          |
|           | (pre-approved for incidents)                                     |
|           v                                                                   |
|  +=================+                                                         |
|  | WALLIX          |   T+3 minutes                                           |
|  |                 |                                                         |
|  | * Auth check    |                                                         |
|  | * Emergency     |                                                         |
|  |   flag detected |                                                         |
|  | * Fast-track    |-----------------------------------+                    |
|  |   approval      |                                   |                    |
|  +========+========+                                   |                    |
|           |                                             |                    |
|           |                                             v                    |
|           |                              +-------------------------+         |
|           |                              | On-call supervisor      |         |
|           |                              | receives SMS/call       |         |
|           |                              |                         |         |
|           |                              | One-click approve       |         |
|           |                              | from mobile             |         |
|           |                              +------------+------------+         |
|           |                                           |                      |
|           |<------------------------------------------+                      |
|           |  T+5 minutes (approval received)                                 |
|           |                                                                   |
|           v                                                                   |
|  +-----------------+                                                         |
|  | SESSION         |   T+6 minutes                                           |
|  | ESTABLISHED     |                                                         |
|  |                 |                                                         |
|  | Full recording  |                                                         |
|  | active          |                                                         |
|  +--------+--------+                                                         |
|           |                                                                   |
|           | Engineer troubleshoots                                           |
|           |                                                                   |
|           v                                                                   |
|  +-----------------+                                                         |
|  | PROBLEM         |   T+45 minutes                                          |
|  | RESOLVED        |                                                         |
|  |                 |                                                         |
|  | Session ends    |                                                         |
|  | Recording saved |                                                         |
|  +-----------------+                                                         |
|                                                                               |
|                                                                               |
|  TOTAL TIME TO ACCESS: ~6 minutes (vs hours without PAM)                     |
|                                                                               |
+===============================================================================+
```

---

## Next Steps

Continue to [19 - Air-Gapped Environments](../19-airgapped-environments/README.md) for isolated network deployments.
