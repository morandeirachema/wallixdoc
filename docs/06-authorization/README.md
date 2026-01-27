# 06 - Authorization & Access Control

## Table of Contents

1. [Authorization Model Overview](#authorization-model-overview)
2. [Authorization Components](#authorization-components)
3. [Creating Authorizations](#creating-authorizations)
4. [Time-Based Restrictions](#time-based-restrictions)
5. [Approval Workflows](#approval-workflows)
6. [Session Policies](#session-policies)
7. [Critical Sessions](#critical-sessions)
8. [Authorization Examples](#authorization-examples)

---

## Authorization Model Overview

### Core Concept

WALLIX Authorization answers: **WHO** can access **WHAT**, **WHEN**, and **HOW**.

```
+==============================================================================+
|                        AUTHORIZATION MODEL                                    |
+==============================================================================+
|                                                                               |
|    +-----------------+                           +-----------------+         |
|    |   USER GROUP    |                           |  TARGET GROUP   |         |
|    |                 |                           |                 |         |
|    |  "Linux-Admins" |                           | "Prod-Servers"  |         |
|    |                 |                           |                 |         |
|    |  * jsmith       |                           | * root@srv-01   |         |
|    |  * bjones       |                           | * root@srv-02   |         |
|    |  * mwilson      |                           | * admin@srv-03  |         |
|    +--------+--------+                           +--------+--------+         |
|             |                                             |                  |
|             |              WHO + WHAT                     |                  |
|             +------------------+---------------------------+                  |
|                                |                                             |
|                                v                                             |
|             +--------------------------------------+                         |
|             |          AUTHORIZATION               |                         |
|             |                                      |                         |
|             |  +--------------------------------+  |                         |
|             |  | WHEN: Time Restrictions        |  |                         |
|             |  |  * Mon-Fri 08:00-18:00        |  |                         |
|             |  +--------------------------------+  |                         |
|             |                                      |                         |
|             |  +--------------------------------+  |                         |
|             |  | HOW: Policies                  |  |                         |
|             |  |  * Recording: Required         |  |                         |
|             |  |  * Approval: Optional          |  |                         |
|             |  |  * Subprotocols: SHELL, SFTP   |  |                         |
|             |  +--------------------------------+  |                         |
|             |                                      |                         |
|             +--------------------------------------+                         |
|                                                                               |
+==============================================================================+
```

### CyberArk Comparison

| CyberArk | WALLIX | Notes |
|----------|--------|-------|
| Safe Member | Authorization | Access grant |
| Safe Permissions | Authorization Settings | What actions allowed |
| Dual Control | Approval Workflow | 4-eyes principle |
| PSM Recording | Session Recording | Same concept |
| Master Policy | Global Settings | Default behaviors |

---

## Authorization Components

### Authorization Properties

```
+==============================================================================+
|                     AUTHORIZATION PROPERTIES                                  |
+==============================================================================+
|                                                                               |
|  REQUIRED PROPERTIES                                                          |
|  ===================                                                          |
|                                                                               |
|  +-------------------+-----------------------------------------------------+ |
|  | user_group        | Which users get access                              | |
|  +-------------------+-----------------------------------------------------+ |
|  | target_group      | Which targets they can access                       | |
|  +-------------------+-----------------------------------------------------+ |
|  | authorization_name| Unique identifier                                   | |
|  +-------------------+-----------------------------------------------------+ |
|                                                                               |
|  OPTIONAL PROPERTIES                                                          |
|  ===================                                                          |
|                                                                               |
|  +-------------------+-----------------------------------------------------+ |
|  | description       | Human-readable description                          | |
|  +-------------------+-----------------------------------------------------+ |
|  | active            | Enable/disable authorization                        | |
|  +-------------------+-----------------------------------------------------+ |
|  | is_recorded       | Record sessions (true/false)                        | |
|  +-------------------+-----------------------------------------------------+ |
|  | is_critical       | Mark as critical (extra confirmation)               | |
|  +-------------------+-----------------------------------------------------+ |
|  | approval_required | Require approval before access                      | |
|  +-------------------+-----------------------------------------------------+ |
|  | has_comment       | Require comment/ticket for session                  | |
|  +-------------------+-----------------------------------------------------+ |
|  | time_frames       | When access is allowed                              | |
|  +-------------------+-----------------------------------------------------+ |
|  | subprotocols      | Which connection features allowed                   | |
|  +-------------------+-----------------------------------------------------+ |
|                                                                               |
+==============================================================================+
```

### Subprotocol Restrictions

```
+==============================================================================+
|                       SUBPROTOCOL CONTROL                                     |
+==============================================================================+
|                                                                               |
|  SSH SUBPROTOCOLS                                                             |
|  ----------------                                                             |
|                                                                               |
|  +--------------+-----------------------------+----------------------------+ |
|  | Subprotocol  | Description                 | Security Consideration     | |
|  +--------------+-----------------------------+----------------------------+ |
|  | SHELL        | Interactive shell access    | Standard, usually allow    | |
|  | SCP          | Secure copy (file transfer) | Data exfiltration risk     | |
|  | SFTP         | Secure FTP                  | Data exfiltration risk     | |
|  | X11          | X Window forwarding         | Rarely needed, deny        | |
|  | TUNNEL       | SSH port forwarding         | Can bypass security        | |
|  +--------------+-----------------------------+----------------------------+ |
|                                                                               |
|  RDP SUBPROTOCOLS                                                             |
|  ----------------                                                             |
|                                                                               |
|  +--------------+-----------------------------+----------------------------+ |
|  | Feature      | Description                 | Security Consideration     | |
|  +--------------+-----------------------------+----------------------------+ |
|  | Clipboard    | Copy/paste                  | Data leakage risk          | |
|  | Drive        | Local drive mapping         | File transfer risk         | |
|  | Printer      | Printer redirection         | Usually safe               | |
|  | Smart Card   | Smart card passthrough      | Usually safe               | |
|  | Audio        | Sound redirection           | Usually safe               | |
|  +--------------+-----------------------------+----------------------------+ |
|                                                                               |
+==============================================================================+
```

---

## Creating Authorizations

### Basic Authorization

```json
{
    "authorization_name": "linux-admins-to-prod",
    "description": "Linux administrators access to production servers",
    "user_group": "Linux-Admins",
    "target_group": "Production-Linux-Servers",
    "active": true,
    "is_recorded": true,
    "is_critical": false,
    "approval_required": false,
    "subprotocols": ["SHELL", "SCP", "SFTP"]
}
```

### Authorization with Restrictions

```json
{
    "authorization_name": "dba-to-prod-db",
    "description": "DBA team access to production databases",
    "user_group": "DBA-Team",
    "target_group": "Production-Databases",
    "active": true,
    "is_recorded": true,
    "is_critical": true,
    "approval_required": true,
    "has_comment": true,
    "time_frames": ["business-hours"],
    "subprotocols": ["SHELL"]
}
```

### Authorization Decision Flow

```
+==============================================================================+
|                    AUTHORIZATION DECISION FLOW                                |
+==============================================================================+
|                                                                               |
|  User requests access to target                                               |
|                    |                                                          |
|                    v                                                          |
|  +-----------------------------------------+                                 |
|  |  1. Find matching authorization          |                                 |
|  |     User in User Group?                  |----- NO ------> ACCESS DENIED  |
|  |     Target in Target Group?              |                                 |
|  +-----------------+-----------------------+                                 |
|                    | YES                                                      |
|                    v                                                          |
|  +-----------------------------------------+                                 |
|  |  2. Authorization active?                |----- NO ------> ACCESS DENIED  |
|  +-----------------+-----------------------+                                 |
|                    | YES                                                      |
|                    v                                                          |
|  +-----------------------------------------+                                 |
|  |  3. Within allowed time frame?           |----- NO ------> ACCESS DENIED  |
|  +-----------------+-----------------------+                                 |
|                    | YES                                                      |
|                    v                                                          |
|  +-----------------------------------------+                                 |
|  |  4. Approval required?                   |----- YES -----> WAIT APPROVAL  |
|  +-----------------+-----------------------+                                 |
|                    | NO                                                       |
|                    v                                                          |
|  +-----------------------------------------+                                 |
|  |  5. Critical session confirmation?       |                                 |
|  +-----------------+-----------------------+                                 |
|                    |                                                          |
|                    v                                                          |
|              ACCESS GRANTED                                                   |
|                                                                               |
+==============================================================================+
```

---

## Time-Based Restrictions

### Time Frame Configuration

```
+==============================================================================+
|                        TIME FRAME EXAMPLES                                    |
+==============================================================================+
|                                                                               |
|  BUSINESS HOURS                                                               |
|  --------------                                                               |
|                                                                               |
|  {                                                                            |
|      "time_frame_name": "business-hours",                                     |
|      "description": "Standard business hours",                                |
|      "periods": [                                                             |
|          {                                                                    |
|              "days": ["monday", "tuesday", "wednesday",                       |
|                       "thursday", "friday"],                                  |
|              "start_time": "08:00",                                           |
|              "end_time": "18:00"                                              |
|          }                                                                    |
|      ]                                                                        |
|  }                                                                            |
|                                                                               |
|  MAINTENANCE WINDOW                                                           |
|  ------------------                                                           |
|                                                                               |
|  {                                                                            |
|      "time_frame_name": "maintenance-window",                                 |
|      "description": "Weekend maintenance window",                             |
|      "periods": [                                                             |
|          {                                                                    |
|              "days": ["saturday"],                                            |
|              "start_time": "22:00",                                           |
|              "end_time": "06:00"                                              |
|          },                                                                   |
|          {                                                                    |
|              "days": ["sunday"],                                              |
|              "start_time": "00:00",                                           |
|              "end_time": "06:00"                                              |
|          }                                                                    |
|      ]                                                                        |
|  }                                                                            |
|                                                                               |
|  24x7 ACCESS (EMERGENCY)                                                      |
|  -----------------------                                                      |
|                                                                               |
|  {                                                                            |
|      "time_frame_name": "always",                                             |
|      "description": "24x7 emergency access",                                  |
|      "periods": [                                                             |
|          {                                                                    |
|              "days": ["monday", "tuesday", "wednesday",                       |
|                       "thursday", "friday", "saturday", "sunday"],            |
|              "start_time": "00:00",                                           |
|              "end_time": "23:59"                                              |
|          }                                                                    |
|      ]                                                                        |
|  }                                                                            |
|                                                                               |
+==============================================================================+
```

### Time Zone Handling

| Setting | Description |
|---------|-------------|
| UTC | Times stored in UTC |
| Local | Converted to Bastion timezone |
| User | Based on user's configured timezone |

---

## Approval Workflows

### Workflow Types

```
+==============================================================================+
|                       APPROVAL WORKFLOW TYPES                                 |
+==============================================================================+
|                                                                               |
|  TYPE 1: SIMPLE APPROVAL                                                      |
|  =======================                                                      |
|                                                                               |
|  User ------> Request ------> Approver ------> Access                        |
|                                                                               |
|  * Single approver required                                                   |
|  * First-come approval                                                        |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  TYPE 2: MULTI-APPROVER                                                       |
|  ======================                                                       |
|                                                                               |
|  User ------> Request ------> Approver 1 --+--> Access                       |
|                         +--> Approver 2 --+                                 |
|                                                                               |
|  * Multiple approvers can approve                                             |
|  * Any one approval sufficient                                                |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  TYPE 3: QUORUM                                                               |
|  =============                                                                |
|                                                                               |
|  User ------> Request ------> Approver 1 --+                                 |
|                         +--> Approver 2 --+--> Access (2 of 3 required)     |
|                         +--> Approver 3 --+                                 |
|                                                                               |
|  * Minimum number of approvals required                                       |
|  * Configurable quorum                                                        |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  TYPE 4: SEQUENTIAL                                                           |
|  ==================                                                           |
|                                                                               |
|  User ------> Request ------> Approver 1 ------> Approver 2 ------> Access   |
|                                                                               |
|  * Approvers in sequence                                                      |
|  * Each must approve before next                                              |
|                                                                               |
+==============================================================================+
```

### Approval Configuration

```json
{
    "approval_workflow": {
        "name": "production-access-approval",
        "type": "simple",

        "approvers": {
            "user_groups": ["Security-Team", "Operations-Managers"]
        },

        "timeout": {
            "hours": 4,
            "action": "deny"
        },

        "notification": {
            "email": true,
            "sms": false
        },

        "validity": {
            "hours": 8,
            "single_use": false
        }
    }
}
```

### Approval Request Flow

```
+==============================================================================+
|                      APPROVAL REQUEST FLOW                                    |
+==============================================================================+
|                                                                               |
|  +---------+                    +-------------+                              |
|  |  User   |                    |  Approver   |                              |
|  +----+----+                    +------+------+                              |
|       |                                |                                      |
|       |  1. Request access             |                                      |
|       |  (with justification)          |                                      |
|       |--------------------------------|                                      |
|       |                                |                                      |
|       |                                |  2. Notification                     |
|       |                                |<-----------------                    |
|       |                                |  (email/portal)                      |
|       |                                |                                      |
|       |                                |  3. Review request                   |
|       |                                |  - User details                      |
|       |                                |  - Target details                    |
|       |                                |  - Justification                     |
|       |                                |                                      |
|       |                                |  4. Approve/Deny                     |
|       |                                |--------------------                  |
|       |                                |                                      |
|       |  5. Notification               |                                      |
|       |<-------------------------------|                                      |
|       |  (approved/denied)             |                                      |
|       |                                |                                      |
|       |  6. Access granted             |                                      |
|       |  (if approved)                 |                                      |
|       |                                |                                      |
|                                                                               |
+==============================================================================+
```

---

## Session Policies

### Recording Policies

```
+==============================================================================+
|                       RECORDING POLICY OPTIONS                                |
+==============================================================================+
|                                                                               |
|  +--------------------+----------------------------------------------+  |
|  | Policy Setting     | Description                                      |  |
|  +--------------------+----------------------------------------------+  |
|  | is_recorded: true  | All sessions are recorded                        |  |
|  +--------------------+----------------------------------------------+  |
|  | is_recorded: false | No recording (use sparingly)                     |  |
|  +--------------------+----------------------------------------------+  |
|  | record_input: true | Record keystrokes/input                          |  |
|  +--------------------+----------------------------------------------+  |
|  | record_output: true| Record screen/output                             |  |
|  +--------------------+----------------------------------------------+  |
|                                                                               |
|  RECOMMENDED SETTINGS BY USE CASE                                             |
|  --------------------------------                                             |
|                                                                               |
|  +----------------------+------------+------------+--------------------+    |
|  | Use Case             | Recording  | Input      | Output             |    |
|  +----------------------+------------+------------+--------------------+    |
|  | Production Access    | Required   | Yes        | Yes                |    |
|  | Development          | Optional   | Yes        | Yes                |    |
|  | Break-glass          | Required   | Yes        | Yes                |    |
|  | Service Account      | Required   | Yes        | Yes                |    |
|  | Network Devices      | Required   | Yes        | Yes                |    |
|  +----------------------+------------+------------+--------------------+    |
|                                                                               |
+==============================================================================+
```

### Connection Policies

```json
{
    "connection_policy": {
        "name": "secure-ssh-policy",

        "ssh_settings": {
            "authentication_methods": ["publickey", "password"],
            "subprotocols_allowed": ["SHELL", "SCP"],
            "subprotocols_denied": ["TUNNEL", "X11"],
            "max_session_duration_hours": 8
        },

        "credential_access": {
            "show_password": false,
            "checkout_required": true
        }
    }
}
```

---

## Critical Sessions

### Overview

Critical sessions require additional confirmation before access.

### Configuration

```
+==============================================================================+
|                      CRITICAL SESSION WORKFLOW                                |
+==============================================================================+
|                                                                               |
|  +---------+                                                                 |
|  |  User   |                                                                 |
|  +----+----+                                                                 |
|       |                                                                       |
|       |  1. Request critical target                                          |
|       v                                                                       |
|  +------------------------------------------------------------+         |
|  |                                                                 |         |
|  |   +=========================================================+    |         |
|  |   |          CRITICAL SESSION WARNING                      |    |         |
|  |   +=========================================================+    |         |
|  |   |                                                        |    |         |
|  |   |  You are about to access a CRITICAL system.           |    |         |
|  |   |                                                        |    |         |
|  |   |  Target: root@prod-database-01                        |    |         |
|  |   |  Domain: Production-Critical                          |    |         |
|  |   |                                                        |    |         |
|  |   |  This session will be:                                |    |         |
|  |   |  * Fully recorded                                     |    |         |
|  |   |  * Subject to audit review                            |    |         |
|  |   |  * Time-limited (4 hours max)                         |    |         |
|  |   |                                                        |    |         |
|  |   |  Please provide justification:                        |    |         |
|  |   |  +------------------------------------------------+   |    |         |
|  |   |  | INC-12345: Emergency database maintenance      |   |    |         |
|  |   |  +------------------------------------------------+   |    |         |
|  |   |                                                        |    |         |
|  |   |  [ ] I understand and accept                          |    |         |
|  |   |                                                        |    |         |
|  |   |         [Cancel]  [Confirm & Connect]                 |    |         |
|  |   +=========================================================+    |         |
|  |                                                                 |         |
|  +-------------------------------------------------------------+         |
|                                                                               |
+==============================================================================+
```

---

## Authorization Examples

### Example 1: Standard Operations Team

```json
{
    "authorization_name": "ops-team-standard-access",
    "description": "Operations team standard server access",

    "user_group": "Operations-Team",
    "target_group": "Non-Production-Servers",

    "active": true,
    "is_recorded": true,
    "is_critical": false,
    "approval_required": false,
    "has_comment": false,

    "time_frames": ["always"],
    "subprotocols": ["SHELL", "SCP", "SFTP"]
}
```

### Example 2: DBA Production Access

```json
{
    "authorization_name": "dba-production-database",
    "description": "DBA team production database access - requires approval",

    "user_group": "DBA-Team",
    "target_group": "Production-Databases",

    "active": true,
    "is_recorded": true,
    "is_critical": true,
    "approval_required": true,
    "has_comment": true,

    "time_frames": ["business-hours"],
    "approval_workflow": "manager-approval",
    "subprotocols": ["SHELL"]
}
```

### Example 3: Emergency Break-Glass

```json
{
    "authorization_name": "emergency-break-glass",
    "description": "Emergency access to all systems - heavily audited",

    "user_group": "Emergency-Access-Team",
    "target_group": "All-Systems",

    "active": true,
    "is_recorded": true,
    "is_critical": true,
    "approval_required": true,
    "has_comment": true,

    "time_frames": ["always"],
    "approval_workflow": "emergency-dual-approval",
    "subprotocols": ["SHELL", "SCP", "SFTP"]
}
```

### Example 4: Read-Only Auditor Access

```json
{
    "authorization_name": "auditor-readonly",
    "description": "Auditor read-only access for compliance review",

    "user_group": "Auditors",
    "target_group": "All-Servers-ReadOnly",

    "active": true,
    "is_recorded": true,
    "is_critical": false,
    "approval_required": false,

    "time_frames": ["business-hours"],
    "subprotocols": ["SHELL"]
}
```

---

## Next Steps

Continue to [07 - Password Management](../07-password-management/README.md) for detailed credential management and rotation.
