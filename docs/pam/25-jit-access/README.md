# 34 - Just-In-Time (JIT) Access

## Table of Contents

1. [JIT Access Overview](#jit-access-overview)
2. [JIT Architecture](#jit-architecture)
3. [Configuration](#configuration)
4. [Approval Workflows](#approval-workflows)
5. [Time-Based Access](#time-based-access)
6. [Ticketing System Integration](#ticketing-system-integration)
7. [API Reference](#api-reference)
8. [Use Cases](#use-cases)
9. [Compliance Mapping](#compliance-mapping)
10. [Best Practices](#best-practices)
11. [Troubleshooting](#troubleshooting)

---

## JIT Access Overview

### What is Just-In-Time Access?

Just-In-Time (JIT) access is a security paradigm that provides privileged access only when needed, for the minimum time required, and with appropriate approval. Instead of granting standing (permanent) privileges, access is provisioned dynamically and revoked automatically after use.

```
+==============================================================================+
|                       JIT ACCESS PARADIGM                                     |
+==============================================================================+
|                                                                               |
|  TRADITIONAL PAM (Standing Privileges)                                        |
|  =====================================                                        |
|                                                                               |
|  User Account ────────────────────────────────────────────> Always Has Access |
|      │                                                                        |
|      │   [Permanent Group Membership]                                         |
|      │   [Always Available Credentials]                                       |
|      └──> Risk: Compromised accounts = immediate breach                       |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  JIT ACCESS (Zero Standing Privileges)                                        |
|  =====================================                                        |
|                                                                               |
|  User Account ──┬──> Request ──> Approval ──> Time-Limited Access ──> Revoke |
|                 │                    │                                        |
|                 │    [On-Demand]     │    [Automatic Expiration]              |
|                 │                    │                                        |
|                 └──> Risk: Reduced attack surface, audit trail                |
|                                                                               |
+==============================================================================+
```

### Why JIT Access Matters for PAM

| Challenge | How JIT Addresses It |
|-----------|---------------------|
| **Credential Exposure** | Credentials only accessible during approved window |
| **Lateral Movement** | No standing privileges to exploit |
| **Insider Threats** | All access requires justification and approval |
| **Compliance Requirements** | Full audit trail with approval chain |
| **Vendor/Contractor Access** | Time-bounded, supervised access |
| **Blast Radius** | Compromised account has no persistent access |

### CyberArk Comparison

```
+==============================================================================+
|                    CYBERARK VS WALLIX JIT COMPARISON                          |
+==============================================================================+
|                                                                               |
|  +--------------------+---------------------------+-------------------------+ |
|  | Feature            | CyberArk                  | WALLIX Bastion          | |
|  +--------------------+---------------------------+-------------------------+ |
|  | JIT Concept        | Privileged Session Mgr    | Authorization Workflows | |
|  |                    | + CyberArk Cloud JIT      | + Approval Policies     | |
|  +--------------------+---------------------------+-------------------------+ |
|  | Approval Workflow  | Dual Control + REST API   | Built-in Approvals      | |
|  |                    | Ticketing Integration     | API + ITSM Integration  | |
|  +--------------------+---------------------------+-------------------------+ |
|  | Time-Based Access  | Timed Access + OPM        | Time Frames + Duration  | |
|  |                    |                           | Policies                | |
|  +--------------------+---------------------------+-------------------------+ |
|  | Break-Glass        | Break-glass accounts      | Emergency Authorization | |
|  |                    | Master Policy exception   | with post-approval      | |
|  +--------------------+---------------------------+-------------------------+ |
|  | Credential Release | Exclusive/Non-exclusive   | Checkout + Session      | |
|  |                    | check-out                 | Injection               | |
|  +--------------------+---------------------------+-------------------------+ |
|  | Automation         | CPM + REST API            | REST API + Webhooks     | |
|  +--------------------+---------------------------+-------------------------+ |
|                                                                               |
+==============================================================================+
```

### Key Benefits

- **Zero Standing Privileges**: No permanent access rights to privileged accounts
- **Reduced Attack Surface**: Credentials only active during approved sessions
- **Complete Audit Trail**: Every access request, approval, and session recorded
- **Automatic Revocation**: Access expires automatically, no manual cleanup
- **Compliance Ready**: Built-in evidence for auditors (SOC2, PCI-DSS, IEC 62443)

---

## JIT Architecture

### JIT Access Workflow

```
+==============================================================================+
|                         JIT ACCESS WORKFLOW                                   |
+==============================================================================+
|                                                                               |
|  +----------+         +------------+         +------------+                   |
|  |   User   |         |   WALLIX   |         |  Approver  |                   |
|  +----+-----+         +-----+------+         +-----+------+                   |
|       |                     |                      |                          |
|       |  1. Request Access  |                      |                          |
|       |  (target, reason,   |                      |                          |
|       |   duration)         |                      |                          |
|       |-------------------->|                      |                          |
|       |                     |                      |                          |
|       |                     |  2. Notification     |                          |
|       |                     |  (email, portal,     |                          |
|       |                     |   ticketing)         |                          |
|       |                     |--------------------->|                          |
|       |                     |                      |                          |
|       |                     |                      |  3. Review Request       |
|       |                     |                      |  - User identity         |
|       |                     |                      |  - Target details        |
|       |                     |                      |  - Business reason       |
|       |                     |                      |  - Risk assessment       |
|       |                     |                      |                          |
|       |                     |  4. Approve/Deny     |                          |
|       |                     |<---------------------|                          |
|       |                     |  (with comment)      |                          |
|       |                     |                      |                          |
|       |  5. Notification    |                      |                          |
|       |  (approved/denied)  |                      |                          |
|       |<--------------------|                      |                          |
|       |                     |                      |                          |
|       |  6. Access Window   |                      |                          |
|       |  Opens              |                      |                          |
|       |<====================|                      |                          |
|       |                     |                      |                          |
|       |  7. Session         |                      |                          |
|       |  (recorded)         |                      |                          |
|       |-------------------->|                      |                          |
|       |                     |                      |                          |
|       |  8. Access Window   |                      |                          |
|       |  Expires            |                      |                          |
|       |<====================|                      |                          |
|       |                     |                      |                          |
|       |  9. Access Revoked  |                      |                          |
|       |  (automatic)        |                      |                          |
|       |                     |                      |                          |
|                                                                               |
+==============================================================================+
```

### Component Architecture

```
+==============================================================================+
|                     JIT ACCESS ARCHITECTURE                                   |
+==============================================================================+
|                                                                               |
|                          +----------------------+                             |
|                          |     USERS            |                             |
|                          |  (Requestors)        |                             |
|                          +----------+-----------+                             |
|                                     |                                         |
|                                     v                                         |
|  +------------------------------------------------------------------+        |
|  |                     WALLIX BASTION                                |        |
|  |                                                                   |        |
|  |   +-------------------+      +----------------------+             |        |
|  |   | Access Manager    |      | Approval Engine      |             |        |
|  |   |                   |      |                      |             |        |
|  |   | - Request Portal  |<---->| - Workflow Manager   |             |        |
|  |   | - Self-Service    |      | - Quorum Logic       |             |        |
|  |   | - API Endpoint    |      | - Timeout Handler    |             |        |
|  |   +-------------------+      | - Notification Svc   |             |        |
|  |                              +----------+-----------+             |        |
|  |                                         |                         |        |
|  |                                         v                         |        |
|  |   +-------------------+      +----------------------+             |        |
|  |   | Time Frame Mgr    |      | Authorization Engine |             |        |
|  |   |                   |      |                      |             |        |
|  |   | - Schedule Eval   |<---->| - Access Grants      |             |        |
|  |   | - Duration Track  |      | - Permission Check   |             |        |
|  |   | - Auto-Revocation |      | - Session Policy     |             |        |
|  |   +-------------------+      +----------------------+             |        |
|  |                                         |                         |        |
|  |                                         v                         |        |
|  |   +-------------------+      +----------------------+             |        |
|  |   | Audit Engine      |      | Session Manager      |             |        |
|  |   |                   |      |                      |             |        |
|  |   | - Request Logs    |<---->| - Session Recording  |             |        |
|  |   | - Approval Logs   |      | - Real-time Monitor  |             |        |
|  |   | - Session Logs    |      | - Session Termination|             |        |
|  |   +-------------------+      +----------------------+             |        |
|  |                                                                   |        |
|  +------------------------------------------------------------------+        |
|                                     |                                         |
|                                     v                                         |
|  +------------------------------------------------------------------+        |
|  |  INTEGRATIONS                                                     |        |
|  |                                                                   |        |
|  |  +------------+  +------------+  +------------+  +-------------+ |        |
|  |  | ServiceNow |  |    Jira    |  |    SIEM    |  |   Webhook   | |        |
|  |  | Connector  |  |  Connector |  |  Forward   |  |   Notify    | |        |
|  |  +------------+  +------------+  +------------+  +-------------+ |        |
|  |                                                                   |        |
|  +------------------------------------------------------------------+        |
|                                                                               |
+==============================================================================+
```

### Data Flow

```
+==============================================================================+
|                        JIT ACCESS DATA FLOW                                   |
+==============================================================================+
|                                                                               |
|                   REQUEST                  GRANT                              |
|                      |                       |                                |
|  +----------+        v          +----------+ v         +-----------+          |
|  |          |   +---------+     |          |     +---------+       |          |
|  |  User    |-->| Request |---->| Approval |---->| Access  |------>| Target   |
|  | (Portal) |   |  Queue  |     |  Engine  |     | Window  |       | System   |
|  |          |   +---------+     |          |     +---------+       |          |
|  +----------+        |          +----+-----+           |           +-----------+
|                      |               |                 |                      |
|                      v               v                 v                      |
|                 +---------+     +---------+      +---------+                  |
|                 |  Audit  |     | Notifi- |      | Session |                  |
|                 |   Log   |     | cation  |      |Recording|                  |
|                 +---------+     +---------+      +---------+                  |
|                                                                               |
|  EVENTS LOGGED:                                                               |
|  - jit.request.created                                                        |
|  - jit.request.approved / jit.request.denied                                  |
|  - jit.access.granted / jit.access.expired                                    |
|  - jit.session.started / jit.session.ended                                    |
|                                                                               |
+==============================================================================+
```

---

## Configuration

### Enabling JIT Access

JIT access is implemented through authorization configurations with approval requirements and time constraints.

#### Step 1: Create Approval-Required Authorization

```json
{
    "authorization_name": "jit-production-database",
    "description": "JIT access to production databases - requires approval",
    "user_group": "DBA-Team",
    "target_group": "Production-Databases",
    "active": true,
    "is_recorded": true,
    "is_critical": true,
    "approval_required": true,
    "has_comment": true,
    "subprotocols": ["SHELL"]
}
```

#### Step 2: Configure Approval Policy

```json
{
    "approval_policy": {
        "name": "jit-production-approval",
        "description": "JIT approval for production access",

        "approvers": {
            "user_groups": ["Security-Team", "DBA-Managers"],
            "specific_users": ["security-admin@company.com"]
        },

        "quorum": {
            "enabled": false,
            "minimum_approvers": 1
        },

        "timeout": {
            "hours": 4,
            "action": "deny",
            "notify_before_minutes": 30
        },

        "access_validity": {
            "default_hours": 4,
            "maximum_hours": 8,
            "single_use": false,
            "extend_allowed": true,
            "max_extensions": 2
        },

        "notification": {
            "channels": ["email", "portal"],
            "on_request": true,
            "on_approval": true,
            "on_denial": true,
            "on_expiration": true
        }
    }
}
```

#### Step 3: Define Time Frames

```json
{
    "time_frame": {
        "name": "jit-emergency-window",
        "description": "Emergency JIT access - 24/7 with mandatory approval",
        "periods": [
            {
                "days": ["monday", "tuesday", "wednesday",
                         "thursday", "friday", "saturday", "sunday"],
                "start_time": "00:00",
                "end_time": "23:59"
            }
        ],
        "timezone": "UTC"
    }
}
```

### Authorization Settings Matrix

```
+==============================================================================+
|                    JIT AUTHORIZATION CONFIGURATION                            |
+==============================================================================+
|                                                                               |
|  +-------------------------------------------------------------------------+ |
|  | Setting              | Standard PAM | JIT Access    | JIT + Break-Glass| |
|  +----------------------+-------------+---------------+-------------------+ |
|  | approval_required    | false       | true          | true              | |
|  | has_comment          | optional    | true          | true              | |
|  | is_recorded          | true        | true          | true              | |
|  | is_critical          | optional    | true          | true              | |
|  | time_frames          | optional    | configured    | "always"          | |
|  | max_duration_hours   | unlimited   | 4-8 hours     | 2-4 hours         | |
|  | auto_revoke          | false       | true          | true              | |
|  | single_use           | false       | optional      | true              | |
|  | post_session_rotate  | optional    | optional      | true              | |
|  +----------------------+-------------+---------------+-------------------+ |
|                                                                               |
+==============================================================================+
```

### CLI Configuration

```bash
# Create JIT authorization
wabadmin authorization create \
    --name "jit-prod-servers" \
    --user-group "Operations-Team" \
    --target-group "Production-Servers" \
    --approval-required \
    --comment-required \
    --recorded \
    --critical \
    --max-duration 4h \
    --auto-revoke

# Configure approval policy
wabadmin approval-policy create \
    --name "jit-prod-approval" \
    --approvers "Security-Team,Operations-Managers" \
    --timeout 4h \
    --timeout-action deny \
    --validity 4h \
    --notify-email \
    --notify-portal

# Link approval policy to authorization
wabadmin authorization update "jit-prod-servers" \
    --approval-policy "jit-prod-approval"
```

---

## Approval Workflows

### Workflow Types

```
+==============================================================================+
|                       APPROVAL WORKFLOW TYPES                                 |
+==============================================================================+
|                                                                               |
|  TYPE 1: SIMPLE APPROVAL (Single Approver)                                    |
|  =========================================                                    |
|                                                                               |
|  User ────> Request ────> Approver ────> Access Granted                      |
|                              │                                                |
|                              └── First available approver                     |
|                                  from approver group                          |
|                                                                               |
|  Use Case: Low-risk production access, standard operations                    |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  TYPE 2: QUORUM APPROVAL (N of M)                                             |
|  ================================                                             |
|                                                                               |
|  User ────> Request ────> Approver 1 ─┐                                       |
|                     ├───> Approver 2 ─┼──> Access Granted                    |
|                     └───> Approver 3 ─┘   (when 2 of 3 approve)              |
|                                                                               |
|  Use Case: High-security access, critical infrastructure                      |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  TYPE 3: SEQUENTIAL APPROVAL (Multi-Level)                                    |
|  =========================================                                    |
|                                                                               |
|  User ────> Request ────> Level 1 ────> Level 2 ────> Access Granted         |
|                           (Manager)     (Security)                            |
|                                                                               |
|  Use Case: Sensitive data access, regulatory requirements                     |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  TYPE 4: PARALLEL + QUORUM                                                    |
|  =========================                                                    |
|                                                                               |
|  User ────> Request ───┬──> Security Team ──┐                                |
|                        │                    ├──> (1 from each) ──> Access    |
|                        └──> Business Team ──┘                                |
|                                                                               |
|  Use Case: Cross-functional approval, vendor access                           |
|                                                                               |
+==============================================================================+
```

### Quorum Configuration

```json
{
    "approval_workflow": {
        "name": "critical-system-quorum",
        "type": "quorum",

        "quorum_settings": {
            "minimum_approvers": 2,
            "approver_groups": [
                {
                    "group": "Security-Team",
                    "required": true,
                    "minimum": 1
                },
                {
                    "group": "System-Owners",
                    "required": true,
                    "minimum": 1
                }
            ]
        },

        "timeout": {
            "hours": 2,
            "action": "escalate",
            "escalate_to": "CISO"
        }
    }
}
```

### Approval Request Flow

```
+==============================================================================+
|                      APPROVAL REQUEST PROCESS                                 |
+==============================================================================+
|                                                                               |
|  REQUEST CREATION                                                             |
|  ================                                                             |
|                                                                               |
|  +------------------------------------------------------------------------+  |
|  |  JIT ACCESS REQUEST                                                    |  |
|  +------------------------------------------------------------------------+  |
|  |                                                                        |  |
|  |  Requestor:     jsmith@company.com                                     |  |
|  |  Target:        root@prod-db-01.company.com                            |  |
|  |  Protocol:      SSH                                                    |  |
|  |  Requested:     2026-01-31 10:00:00 UTC                                |  |
|  |                                                                        |  |
|  |  Duration:      [ 4 hours         v ]                                  |  |
|  |                                                                        |  |
|  |  Reason:        +---------------------------------------------------+  |  |
|  |                 | Database maintenance for performance tuning.      |  |  |
|  |                 | Ticket: CHG-2026-0131                              |  |  |
|  |                 +---------------------------------------------------+  |  |
|  |                                                                        |  |
|  |  [ ] I acknowledge this session will be recorded                       |  |
|  |  [ ] I have read the acceptable use policy                             |  |
|  |                                                                        |  |
|  |                              [ Cancel ]  [ Submit Request ]            |  |
|  |                                                                        |  |
|  +------------------------------------------------------------------------+  |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  APPROVER VIEW                                                                |
|  =============                                                                |
|                                                                               |
|  +------------------------------------------------------------------------+  |
|  |  PENDING APPROVAL                                            [ Urgent ]|  |
|  +------------------------------------------------------------------------+  |
|  |                                                                        |  |
|  |  Request ID:    REQ-2026-0131-0042                                     |  |
|  |  Status:        Pending (expires in 3h 45m)                            |  |
|  |                                                                        |  |
|  |  REQUESTOR INFORMATION                                                 |  |
|  |  +------------------------------------------------------------------+  |  |
|  |  | User:        John Smith (jsmith)                                 |  |  |
|  |  | Department:  Database Administration                            |  |  |
|  |  | Manager:     mary.wilson@company.com                             |  |  |
|  |  | Recent Accesses: 3 in last 30 days (all approved)               |  |  |
|  |  +------------------------------------------------------------------+  |  |
|  |                                                                        |  |
|  |  TARGET INFORMATION                                                    |  |
|  |  +------------------------------------------------------------------+  |  |
|  |  | Device:      prod-db-01.company.com (10.10.10.50)                |  |  |
|  |  | Account:     root                                                |  |  |
|  |  | Protocol:    SSH                                                 |  |  |
|  |  | Risk Level:  HIGH (production database)                          |  |  |
|  |  +------------------------------------------------------------------+  |  |
|  |                                                                        |  |
|  |  JUSTIFICATION                                                         |  |
|  |  +------------------------------------------------------------------+  |  |
|  |  | Database maintenance for performance tuning.                     |  |  |
|  |  | Ticket: CHG-2026-0131                                            |  |  |
|  |  +------------------------------------------------------------------+  |  |
|  |                                                                        |  |
|  |  Approver Comment:                                                     |  |
|  |  +------------------------------------------------------------------+  |  |
|  |  |                                                                  |  |  |
|  |  +------------------------------------------------------------------+  |  |
|  |                                                                        |  |
|  |                    [ Deny ]  [ Approve for 2h ]  [ Approve ]           |  |
|  |                                                                        |  |
|  +------------------------------------------------------------------------+  |
|                                                                               |
+==============================================================================+
```

### Timeout Handling

```
+==============================================================================+
|                      TIMEOUT BEHAVIOR OPTIONS                                 |
+==============================================================================+
|                                                                               |
|  +-------------------+-------------------------------------------------------+|
|  | Timeout Action    | Behavior                                              ||
|  +-------------------+-------------------------------------------------------+|
|  | deny              | Request automatically denied, user notified           ||
|  | approve           | Request automatically approved (use with caution)     ||
|  | escalate          | Request escalated to higher authority                 ||
|  | extend            | Timeout extended, additional reminder sent            ||
|  | notify_only       | Approvers notified, request remains pending           ||
|  +-------------------+-------------------------------------------------------+|
|                                                                               |
|  TIMEOUT NOTIFICATION TIMELINE                                                |
|  =============================                                                |
|                                                                               |
|  Request ──> T=0         T=75%        T=100%                                 |
|  Created     │            │             │                                    |
|              │            │             │                                    |
|              │  Reminder  │  Final      │  Action                            |
|              │  Sent      │  Warning    │  Executed                          |
|              │            │             │                                    |
|              ▼            ▼             ▼                                    |
|  ──────────[●]─────────[●]────────────[●]───────────>                        |
|              0h          3h           4h (timeout)                           |
|                                                                               |
+==============================================================================+
```

---

## Time-Based Access

### Access Duration Management

```
+==============================================================================+
|                    TIME-BASED ACCESS CONTROL                                  |
+==============================================================================+
|                                                                               |
|  ACCESS LIFECYCLE                                                             |
|  ================                                                             |
|                                                                               |
|  Request ──> Approval ──> Access Window ──> Expiration ──> Revocation        |
|     │           │              │                │              │              |
|     ▼           ▼              ▼                ▼              ▼              |
|  T-request   T-approve    T-start          T-expire      T-cleanup           |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  ACCESS WINDOW VISUALIZATION                                                  |
|  ===========================                                                  |
|                                                                               |
|        Request     Approval    Access       Session      Expiration          |
|        Created     Granted     Starts       Active       (4 hours)           |
|           │           │           │           │              │                |
|           ▼           ▼           ▼           ▼              ▼                |
|  ─────────[●]────────[●]─────────[████████████████]─────────[●]────>         |
|         09:00       09:15       09:15                      13:15             |
|                                                                               |
|                                   └────── Access Window ──────┘               |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  AUTOMATIC ACTIONS                                                            |
|  =================                                                            |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  | Event               | Action                                          |   |
|  +---------------------+------------------------------------------------+   |
|  | 30 min before expiry| Warning notification to user                   |   |
|  | 5 min before expiry | Final warning, offer extension if allowed      |   |
|  | At expiration       | Active sessions terminated gracefully          |   |
|  | After expiration    | Credentials rotated (if configured)            |   |
|  +---------------------+------------------------------------------------+   |
|                                                                               |
+==============================================================================+
```

### Scheduling Windows

```json
{
    "time_frame_configurations": [
        {
            "name": "business-hours-jit",
            "description": "JIT access during business hours",
            "periods": [
                {
                    "days": ["monday", "tuesday", "wednesday",
                             "thursday", "friday"],
                    "start_time": "08:00",
                    "end_time": "18:00"
                }
            ],
            "max_session_duration_hours": 8,
            "auto_extend": false
        },
        {
            "name": "maintenance-window-jit",
            "description": "JIT access for maintenance windows",
            "periods": [
                {
                    "days": ["saturday"],
                    "start_time": "22:00",
                    "end_time": "23:59"
                },
                {
                    "days": ["sunday"],
                    "start_time": "00:00",
                    "end_time": "06:00"
                }
            ],
            "max_session_duration_hours": 8,
            "require_change_ticket": true
        },
        {
            "name": "emergency-24x7",
            "description": "Emergency JIT - always available with approval",
            "periods": [
                {
                    "days": ["monday", "tuesday", "wednesday",
                             "thursday", "friday", "saturday", "sunday"],
                    "start_time": "00:00",
                    "end_time": "23:59"
                }
            ],
            "max_session_duration_hours": 4,
            "require_quorum_approval": true,
            "post_access_review": true
        }
    ]
}
```

### Session Extension

```
+==============================================================================+
|                      SESSION EXTENSION WORKFLOW                               |
+==============================================================================+
|                                                                               |
|  EXTENSION REQUEST                                                            |
|  =================                                                            |
|                                                                               |
|  +------------------------------------------------------------------------+  |
|  |  SESSION EXTENSION REQUEST                                             |  |
|  +------------------------------------------------------------------------+  |
|  |                                                                        |  |
|  |  Current Session:    root@prod-db-01 (SSH)                             |  |
|  |  Started:            09:15:00 UTC                                      |  |
|  |  Expires:            13:15:00 UTC (25 minutes remaining)               |  |
|  |                                                                        |  |
|  |  Extension Requested: [ 2 hours  v ]                                   |  |
|  |                                                                        |  |
|  |  Reason for Extension:                                                 |  |
|  |  +------------------------------------------------------------------+  |  |
|  |  | Query optimization taking longer than expected.                  |  |  |
|  |  | Need additional time to complete testing.                        |  |  |
|  |  +------------------------------------------------------------------+  |  |
|  |                                                                        |  |
|  |                              [ Cancel ]  [ Request Extension ]         |  |
|  |                                                                        |  |
|  +------------------------------------------------------------------------+  |
|                                                                               |
|  EXTENSION POLICY                                                             |
|  ================                                                             |
|                                                                               |
|  +---------------------------------------------------------------------+     |
|  | Policy                     | Setting                                |     |
|  +----------------------------+----------------------------------------+     |
|  | Extensions allowed         | Yes                                    |     |
|  | Maximum extensions         | 2                                      |     |
|  | Maximum extension duration | 2 hours                                |     |
|  | Re-approval required       | Yes (for >1 hour)                      |     |
|  | Total max session time     | 12 hours                               |     |
|  +----------------------------+----------------------------------------+     |
|                                                                               |
+==============================================================================+
```

---

## Ticketing System Integration

### ServiceNow Integration

```
+==============================================================================+
|                    SERVICENOW INTEGRATION ARCHITECTURE                        |
+==============================================================================+
|                                                                               |
|  +------------------+                        +------------------+             |
|  |     User         |                        |    ServiceNow    |             |
|  |                  |                        |                  |             |
|  |  Creates         |                        |  Change Request  |             |
|  |  Change Ticket   |----------------------->|  CHG0012345      |             |
|  |                  |                        |                  |             |
|  +------------------+                        +--------+---------+             |
|                                                       |                       |
|                                                       | Webhook              |
|                                                       | Notification         |
|                                                       |                       |
|                                                       v                       |
|  +------------------+                        +------------------+             |
|  |  WALLIX Bastion  |                        |  Integration     |             |
|  |                  |                        |  Engine          |             |
|  |  JIT Request     |<-----------------------|                  |             |
|  |  Portal          |                        |  Validates:      |             |
|  |                  |                        |  - Ticket exists |             |
|  +--------+---------+                        |  - Status = Open |             |
|           |                                  |  - User matches  |             |
|           |                                  +------------------+             |
|           |                                                                   |
|           v                                                                   |
|  +------------------+      +------------------+                               |
|  |  Approval        |      |   ServiceNow     |                               |
|  |  Decision        |----->|   Update         |                               |
|  |                  |      |                  |                               |
|  |  - Approved      |      |  - Add work note |                               |
|  |  - Denied        |      |  - Update status |                               |
|  +------------------+      +------------------+                               |
|                                                                               |
+==============================================================================+
```

#### ServiceNow Configuration

```json
{
    "servicenow_integration": {
        "enabled": true,
        "instance_url": "https://company.service-now.com",
        "api_user": "wallix_integration",
        "api_credentials": "<encrypted>",

        "ticket_validation": {
            "enabled": true,
            "required_for_approval": true,
            "table": "change_request",
            "valid_states": ["implement", "scheduled"],
            "match_user": true
        },

        "auto_update": {
            "on_request": {
                "action": "add_work_note",
                "note_template": "JIT access requested via WALLIX Bastion.\nRequest ID: {{request_id}}\nTarget: {{target}}\nRequestor: {{user}}"
            },
            "on_approval": {
                "action": "add_work_note",
                "note_template": "JIT access APPROVED.\nApprover: {{approver}}\nDuration: {{duration}}"
            },
            "on_session_end": {
                "action": "add_work_note",
                "note_template": "JIT session completed.\nDuration: {{session_duration}}\nRecording: {{recording_link}}"
            }
        },

        "webhook": {
            "url": "https://bastion.company.com/api/v2/webhooks/servicenow",
            "secret": "<encrypted>",
            "events": ["change.approved", "change.implemented"]
        }
    }
}
```

### Jira Integration

```json
{
    "jira_integration": {
        "enabled": true,
        "base_url": "https://company.atlassian.net",
        "api_token": "<encrypted>",

        "ticket_validation": {
            "enabled": true,
            "project_keys": ["OPS", "SEC", "CHG"],
            "valid_statuses": ["In Progress", "Approved"],
            "issue_types": ["Change", "Incident", "Task"]
        },

        "auto_update": {
            "on_request": {
                "action": "add_comment",
                "comment_template": "JIT access requested via WALLIX Bastion.\n* Request ID: {{request_id}}\n* Target: {{target}}\n* Requestor: {{user}}"
            },
            "on_session_end": {
                "action": "add_comment",
                "transition": "Complete",
                "comment_template": "JIT session completed.\n* Duration: {{session_duration}}\n* [Recording Link|{{recording_link}}]"
            }
        }
    }
}
```

### Generic Webhook Integration

```json
{
    "webhook_integration": {
        "name": "custom-itsm",
        "enabled": true,

        "outbound_webhooks": [
            {
                "event": "jit.request.created",
                "url": "https://itsm.company.com/api/wallix/request",
                "method": "POST",
                "headers": {
                    "Authorization": "Bearer {{api_token}}",
                    "Content-Type": "application/json"
                },
                "body_template": {
                    "event_type": "jit_request",
                    "request_id": "{{request_id}}",
                    "user": "{{user_email}}",
                    "target": "{{target_device}}:{{target_account}}",
                    "reason": "{{justification}}",
                    "requested_duration": "{{duration_hours}}h"
                }
            },
            {
                "event": "jit.request.approved",
                "url": "https://itsm.company.com/api/wallix/approved",
                "method": "POST",
                "body_template": {
                    "event_type": "jit_approved",
                    "request_id": "{{request_id}}",
                    "approver": "{{approver_email}}",
                    "access_expires": "{{expiration_time}}"
                }
            }
        ],

        "inbound_webhook": {
            "path": "/api/v2/webhooks/itsm",
            "authentication": "hmac_sha256",
            "secret": "<encrypted>",
            "actions": {
                "ticket_approved": "auto_approve_request",
                "ticket_cancelled": "deny_request"
            }
        }
    }
}
```

---

## API Reference

### JIT Request Endpoints

```
+==============================================================================+
|                        JIT API ENDPOINTS (v3.12)                              |
+==============================================================================+

  CREATE JIT REQUEST
  ==================

  POST /api/v2/jit/requests

  Request:
  {
    "target_device": "prod-db-01",
    "target_account": "root",
    "protocol": "SSH",
    "requested_duration_hours": 4,
    "justification": "Database maintenance for CHG-2026-0131",
    "ticket_reference": "CHG-2026-0131",
    "scheduled_start": "2026-01-31T10:00:00Z"
  }

  Response (201 Created):
  {
    "status": "success",
    "data": {
      "request_id": "jit_req_abc123",
      "status": "pending_approval",
      "requestor": {
        "id": "usr_001",
        "username": "jsmith",
        "email": "jsmith@company.com"
      },
      "target": {
        "device": "prod-db-01",
        "account": "root",
        "protocol": "SSH"
      },
      "requested_duration_hours": 4,
      "justification": "Database maintenance for CHG-2026-0131",
      "ticket_reference": "CHG-2026-0131",
      "created_at": "2026-01-31T09:30:00Z",
      "expires_at": "2026-01-31T13:30:00Z",
      "approval_deadline": "2026-01-31T13:30:00Z"
    }
  }

  --------------------------------------------------------------------------

  LIST JIT REQUESTS
  =================

  GET /api/v2/jit/requests

  Query Parameters:
  +------------------------------------------------------------------------+
  | Parameter      | Type    | Description                                 |
  +----------------+---------+---------------------------------------------+
  | status         | string  | pending, approved, denied, expired, active  |
  | requestor_id   | string  | Filter by requestor                         |
  | target_device  | string  | Filter by target device                     |
  | start_date     | datetime| Requests created after                      |
  | end_date       | datetime| Requests created before                     |
  +----------------+---------+---------------------------------------------+

  Response:
  {
    "status": "success",
    "data": [
      {
        "request_id": "jit_req_abc123",
        "status": "pending_approval",
        "requestor": "jsmith",
        "target": "root@prod-db-01",
        "created_at": "2026-01-31T09:30:00Z"
      }
    ],
    "meta": {
      "total": 15,
      "page": 1,
      "per_page": 25
    }
  }

  --------------------------------------------------------------------------

  GET JIT REQUEST
  ===============

  GET /api/v2/jit/requests/{request_id}

  Response:
  {
    "status": "success",
    "data": {
      "request_id": "jit_req_abc123",
      "status": "approved",
      "requestor": {
        "id": "usr_001",
        "username": "jsmith"
      },
      "target": {
        "device": "prod-db-01",
        "account": "root",
        "protocol": "SSH"
      },
      "requested_duration_hours": 4,
      "justification": "Database maintenance",
      "approval": {
        "approved_by": "security-admin",
        "approved_at": "2026-01-31T09:45:00Z",
        "comment": "Verified change ticket CHG-2026-0131"
      },
      "access_window": {
        "starts_at": "2026-01-31T10:00:00Z",
        "expires_at": "2026-01-31T14:00:00Z"
      },
      "sessions": [
        {
          "session_id": "ses_xyz789",
          "started_at": "2026-01-31T10:05:00Z",
          "status": "active"
        }
      ]
    }
  }

  --------------------------------------------------------------------------

  CANCEL JIT REQUEST
  ==================

  DELETE /api/v2/jit/requests/{request_id}

  Response (204 No Content)

+==============================================================================+
```

### Approval Endpoints

```
+==============================================================================+
|                     APPROVAL API ENDPOINTS                                    |
+==============================================================================+

  LIST PENDING APPROVALS
  ======================

  GET /api/v2/jit/approvals?status=pending

  Response:
  {
    "status": "success",
    "data": [
      {
        "approval_id": "apr_001",
        "request_id": "jit_req_abc123",
        "requestor": "jsmith",
        "target": "root@prod-db-01",
        "justification": "Database maintenance",
        "requested_at": "2026-01-31T09:30:00Z",
        "deadline": "2026-01-31T13:30:00Z",
        "time_remaining_minutes": 180
      }
    ]
  }

  --------------------------------------------------------------------------

  APPROVE REQUEST
  ===============

  POST /api/v2/jit/approvals/{request_id}/approve

  Request:
  {
    "comment": "Approved - verified change ticket CHG-2026-0131",
    "modified_duration_hours": 4,
    "conditions": {
      "session_recording": true,
      "command_restrictions": ["rm -rf", "shutdown"]
    }
  }

  Response (200 OK):
  {
    "status": "success",
    "data": {
      "request_id": "jit_req_abc123",
      "status": "approved",
      "approved_by": "security-admin",
      "approved_at": "2026-01-31T09:45:00Z",
      "access_window": {
        "starts_at": "2026-01-31T10:00:00Z",
        "expires_at": "2026-01-31T14:00:00Z"
      }
    }
  }

  --------------------------------------------------------------------------

  DENY REQUEST
  ============

  POST /api/v2/jit/approvals/{request_id}/deny

  Request:
  {
    "comment": "Denied - no valid change ticket found",
    "suggest_alternative": "Please submit a change request first"
  }

  Response (200 OK):
  {
    "status": "success",
    "data": {
      "request_id": "jit_req_abc123",
      "status": "denied",
      "denied_by": "security-admin",
      "denied_at": "2026-01-31T09:45:00Z",
      "reason": "Denied - no valid change ticket found"
    }
  }

  --------------------------------------------------------------------------

  EXTEND ACCESS
  =============

  POST /api/v2/jit/requests/{request_id}/extend

  Request:
  {
    "extension_hours": 2,
    "justification": "Additional time needed for testing"
  }

  Response (200 OK):
  {
    "status": "success",
    "data": {
      "request_id": "jit_req_abc123",
      "new_expiration": "2026-01-31T16:00:00Z",
      "extension_number": 1,
      "extensions_remaining": 1
    }
  }

  --------------------------------------------------------------------------

  REVOKE ACCESS
  =============

  POST /api/v2/jit/requests/{request_id}/revoke

  Request:
  {
    "reason": "Emergency revocation - security incident",
    "terminate_active_sessions": true,
    "rotate_credential": true
  }

  Response (200 OK):
  {
    "status": "success",
    "data": {
      "request_id": "jit_req_abc123",
      "revoked_at": "2026-01-31T11:30:00Z",
      "sessions_terminated": 1,
      "credential_rotated": true
    }
  }

+==============================================================================+
```

### Python SDK Examples

```python
#!/usr/bin/env python3
"""
WALLIX Bastion JIT Access API Examples
"""

import requests
from datetime import datetime, timedelta

WALLIX_URL = "https://bastion.company.com"
API_TOKEN = "your-api-token"

headers = {
    "Authorization": f"Bearer {API_TOKEN}",
    "Content-Type": "application/json"
}


def create_jit_request(target_device, target_account, duration_hours,
                       justification, ticket_ref=None):
    """Create a JIT access request"""

    payload = {
        "target_device": target_device,
        "target_account": target_account,
        "protocol": "SSH",
        "requested_duration_hours": duration_hours,
        "justification": justification
    }

    if ticket_ref:
        payload["ticket_reference"] = ticket_ref

    response = requests.post(
        f"{WALLIX_URL}/api/v2/jit/requests",
        headers=headers,
        json=payload
    )

    return response.json()


def approve_jit_request(request_id, comment, modified_duration=None):
    """Approve a JIT access request"""

    payload = {
        "comment": comment
    }

    if modified_duration:
        payload["modified_duration_hours"] = modified_duration

    response = requests.post(
        f"{WALLIX_URL}/api/v2/jit/approvals/{request_id}/approve",
        headers=headers,
        json=payload
    )

    return response.json()


def deny_jit_request(request_id, reason):
    """Deny a JIT access request"""

    payload = {
        "comment": reason
    }

    response = requests.post(
        f"{WALLIX_URL}/api/v2/jit/approvals/{request_id}/deny",
        headers=headers,
        json=payload
    )

    return response.json()


def list_pending_approvals():
    """List all pending JIT approval requests"""

    response = requests.get(
        f"{WALLIX_URL}/api/v2/jit/approvals?status=pending",
        headers=headers
    )

    return response.json()


def revoke_jit_access(request_id, reason, terminate_sessions=True,
                      rotate_credential=True):
    """Revoke JIT access immediately"""

    payload = {
        "reason": reason,
        "terminate_active_sessions": terminate_sessions,
        "rotate_credential": rotate_credential
    }

    response = requests.post(
        f"{WALLIX_URL}/api/v2/jit/requests/{request_id}/revoke",
        headers=headers,
        json=payload
    )

    return response.json()


# Example usage
if __name__ == "__main__":
    # Create a JIT request
    result = create_jit_request(
        target_device="prod-db-01",
        target_account="root",
        duration_hours=4,
        justification="Database maintenance",
        ticket_ref="CHG-2026-0131"
    )
    print(f"Created request: {result['data']['request_id']}")

    # List pending approvals (as approver)
    pending = list_pending_approvals()
    for req in pending['data']:
        print(f"Pending: {req['request_id']} from {req['requestor']}")
```

### cURL Examples

```bash
# Create JIT Request
curl -X POST "https://bastion.company.com/api/v2/jit/requests" \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "target_device": "prod-db-01",
    "target_account": "root",
    "protocol": "SSH",
    "requested_duration_hours": 4,
    "justification": "Database maintenance for CHG-2026-0131",
    "ticket_reference": "CHG-2026-0131"
  }'

# Approve JIT Request
curl -X POST "https://bastion.company.com/api/v2/jit/approvals/jit_req_abc123/approve" \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "comment": "Approved - verified change ticket"
  }'

# Deny JIT Request
curl -X POST "https://bastion.company.com/api/v2/jit/approvals/jit_req_abc123/deny" \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "comment": "Denied - insufficient justification"
  }'

# Revoke JIT Access
curl -X POST "https://bastion.company.com/api/v2/jit/requests/jit_req_abc123/revoke" \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "reason": "Emergency revocation",
    "terminate_active_sessions": true,
    "rotate_credential": true
  }'
```

---

## Use Cases

### Use Case 1: Emergency Break-Glass Access

```
+==============================================================================+
|                     BREAK-GLASS SCENARIO                                      |
+==============================================================================+
|                                                                               |
|  SCENARIO: Production database is down, DBA needs immediate root access       |
|                                                                               |
|  WORKFLOW:                                                                    |
|  =========                                                                    |
|                                                                               |
|  1. DBA triggers break-glass request                                          |
|     - Selects "Emergency Access"                                              |
|     - Provides incident ticket number                                         |
|     - Justification: "Production DB down - INC0012345"                        |
|                                                                               |
|  2. Dual approval required (quorum: 2 of 3)                                   |
|     - Security Team member                                                    |
|     - On-call manager                                                         |
|     - NOC supervisor                                                          |
|                                                                               |
|  3. Access granted for 2 hours                                                |
|     - Session fully recorded                                                  |
|     - Real-time monitoring enabled                                            |
|     - Command blocking for destructive commands                               |
|                                                                               |
|  4. Post-access actions                                                       |
|     - Session review within 24 hours                                          |
|     - Credential automatically rotated                                        |
|     - Incident report generated                                               |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  CONFIGURATION:                                                               |
|                                                                               |
|  {                                                                            |
|    "authorization_name": "break-glass-database",                              |
|    "user_group": "Emergency-Access-Team",                                     |
|    "target_group": "Critical-Infrastructure",                                 |
|    "approval_required": true,                                                 |
|    "approval_workflow": {                                                     |
|      "type": "quorum",                                                        |
|      "minimum_approvers": 2,                                                  |
|      "timeout_minutes": 15                                                    |
|    },                                                                         |
|    "access_settings": {                                                       |
|      "max_duration_hours": 2,                                                 |
|      "single_use": true,                                                      |
|      "post_access_credential_rotation": true,                                 |
|      "mandatory_review": true                                                 |
|    },                                                                         |
|    "is_recorded": true,                                                       |
|    "is_critical": true,                                                       |
|    "real_time_monitoring": true                                               |
|  }                                                                            |
|                                                                               |
+==============================================================================+
```

### Use Case 2: Vendor Maintenance Access

```
+==============================================================================+
|                     VENDOR ACCESS SCENARIO                                    |
+==============================================================================+
|                                                                               |
|  SCENARIO: External vendor needs access for scheduled SCADA maintenance       |
|                                                                               |
|  WORKFLOW:                                                                    |
|  =========                                                                    |
|                                                                               |
|  1. Pre-access preparation                                                    |
|     - Vendor account created with expiration date                             |
|     - Background check verified                                               |
|     - NDA on file                                                             |
|     - Change ticket approved                                                  |
|                                                                               |
|  2. Access request                                                            |
|     - Vendor logs in with MFA                                                 |
|     - Requests access to specific SCADA server                                |
|     - Provides change ticket reference                                        |
|     - Specifies maintenance window                                            |
|                                                                               |
|  3. Approval chain                                                            |
|     - OT Manager approval (Level 1)                                           |
|     - Security Team approval (Level 2)                                        |
|     - Automatic ticket validation                                             |
|                                                                               |
|  4. Supervised session                                                        |
|     - Internal engineer shadows session                                       |
|     - All actions recorded                                                    |
|     - Clipboard disabled                                                      |
|     - File transfer restricted                                                |
|                                                                               |
|  5. Post-session                                                              |
|     - Credential rotated                                                      |
|     - Session reviewed                                                        |
|     - Work notes added to ticket                                              |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  CONFIGURATION:                                                               |
|                                                                               |
|  {                                                                            |
|    "authorization_name": "vendor-scada-access",                               |
|    "user_group": "External-Vendors",                                          |
|    "target_group": "SCADA-Systems",                                           |
|    "approval_required": true,                                                 |
|    "approval_workflow": {                                                     |
|      "type": "sequential",                                                    |
|      "levels": [                                                              |
|        {"group": "OT-Managers", "required": true},                            |
|        {"group": "Security-Team", "required": true}                           |
|      ]                                                                        |
|    },                                                                         |
|    "time_frames": ["maintenance-window"],                                     |
|    "subprotocols_denied": ["SCP", "SFTP", "TUNNEL"],                          |
|    "session_settings": {                                                      |
|      "shadow_required": true,                                                 |
|      "clipboard_disabled": true                                               |
|    },                                                                         |
|    "ticket_integration": {                                                    |
|      "required": true,                                                        |
|      "valid_types": ["CHG"]                                                   |
|    }                                                                          |
|  }                                                                            |
|                                                                               |
+==============================================================================+
```

### Use Case 3: Database Administrator Access

```
+==============================================================================+
|                     DBA PRODUCTION ACCESS                                     |
+==============================================================================+
|                                                                               |
|  SCENARIO: DBA needs access to production database for monthly maintenance    |
|                                                                               |
|  WORKFLOW:                                                                    |
|  =========                                                                    |
|                                                                               |
|  1. Scheduled request                                                         |
|     - DBA requests access 24 hours in advance                                 |
|     - Specifies maintenance window (Saturday 22:00-06:00)                     |
|     - Change ticket automatically created                                     |
|                                                                               |
|  2. Pre-approval check                                                        |
|     - Manager approval                                                        |
|     - Change Advisory Board (CAB) sign-off                                    |
|     - Automated backup verification                                           |
|                                                                               |
|  3. Access window                                                             |
|     - Access auto-activates at scheduled time                                 |
|     - Duration: 8 hours maximum                                               |
|     - Session recording enabled                                               |
|                                                                               |
|  4. Access controls                                                           |
|     - Specific account only (db_admin)                                        |
|     - Certain commands blocked (DROP DATABASE)                                |
|     - Keystroke logging enabled                                               |
|                                                                               |
|  CONFIGURATION:                                                               |
|                                                                               |
|  {                                                                            |
|    "authorization_name": "dba-production-maintenance",                        |
|    "user_group": "DBA-Team",                                                  |
|    "target_group": "Production-Databases",                                    |
|    "approval_required": true,                                                 |
|    "scheduled_access": {                                                      |
|      "advance_request_hours": 24,                                             |
|      "auto_activate": true                                                    |
|    },                                                                         |
|    "time_frames": ["maintenance-window"],                                     |
|    "access_settings": {                                                       |
|      "max_duration_hours": 8                                                  |
|    },                                                                         |
|    "command_restrictions": {                                                  |
|      "blocked_patterns": [                                                    |
|        "DROP DATABASE",                                                       |
|        "TRUNCATE TABLE",                                                      |
|        "DELETE FROM .* WHERE 1=1"                                             |
|      ]                                                                        |
|    }                                                                          |
|  }                                                                            |
|                                                                               |
+==============================================================================+
```

### Use Case 4: Cloud Infrastructure Access

```
+==============================================================================+
|                     CLOUD INFRASTRUCTURE JIT                                  |
+==============================================================================+
|                                                                               |
|  SCENARIO: DevOps engineer needs temporary access to AWS production           |
|                                                                               |
|  WORKFLOW:                                                                    |
|  =========                                                                    |
|                                                                               |
|  1. Request via API (CI/CD pipeline)                                          |
|     - Automated request from deployment pipeline                              |
|     - Short duration (15-30 minutes)                                          |
|     - Specific EC2 instance only                                              |
|                                                                               |
|  2. Auto-approval for known patterns                                          |
|     - Deployment pipelines pre-approved                                       |
|     - Within defined maintenance windows                                      |
|     - From known CI/CD systems                                                |
|                                                                               |
|  3. Credential injection                                                      |
|     - SSH key injected for session                                            |
|     - Temporary key generated                                                 |
|     - Key destroyed after session                                             |
|                                                                               |
|  4. Audit integration                                                         |
|     - CloudTrail correlation                                                  |
|     - Session recording to S3                                                 |
|     - Deployment artifact linking                                             |
|                                                                               |
|  API REQUEST EXAMPLE:                                                         |
|                                                                               |
|  curl -X POST "https://bastion.company.com/api/v2/jit/requests" \             |
|    -H "Authorization: Bearer $DEPLOY_TOKEN" \                                 |
|    -d '{                                                                      |
|      "target_device": "i-0abc123def456",                                      |
|      "target_account": "ec2-user",                                            |
|      "requested_duration_hours": 0.5,                                         |
|      "justification": "Deployment: deploy-prod-v2.5.1",                       |
|      "ticket_reference": "DEPLOY-2026-0131-001",                              |
|      "auto_approve_context": {                                                |
|        "pipeline": "prod-deploy",                                             |
|        "commit": "abc123"                                                     |
|      }                                                                        |
|    }'                                                                         |
|                                                                               |
+==============================================================================+
```

---

## Compliance Mapping

### IEC 62443 Compliance

```
+==============================================================================+
|                    JIT ACCESS - IEC 62443 MAPPING                             |
+==============================================================================+
|                                                                               |
|  FR1 - Identification and Authentication Control (IAC)                        |
|  +---------------------------------------------------------------------+     |
|  | Control | Requirement              | JIT Implementation              |     |
|  +---------+--------------------------+---------------------------------+     |
|  | IAC-1   | Human user identification| JIT requestor identification    |     |
|  | IAC-4   | Human user authentication| MFA required for JIT requests   |     |
|  | IAC-11  | Unsuccessful login       | Failed JIT attempts logged      |     |
|  | IAC-14  | Auth strength by zone    | Stronger approval for OT zones  |     |
|  +---------+--------------------------+---------------------------------+     |
|                                                                               |
|  FR2 - Use Control (UC)                                                       |
|  +---------------------------------------------------------------------+     |
|  | Control | Requirement              | JIT Implementation              |     |
|  +---------+--------------------------+---------------------------------+     |
|  | UC-1    | Authorization enforcement| JIT approval workflow           |     |
|  | UC-5    | Session lock             | JIT session timeout             |     |
|  | UC-6    | Session termination      | Auto-revocation at expiry       |     |
|  | UC-8    | Auditable events         | JIT request/approval audit      |     |
|  | UC-12   | Non-repudiation          | Approval chain logged           |     |
|  +---------+--------------------------+---------------------------------+     |
|                                                                               |
|  FR6 - Timely Response to Events (TRE)                                        |
|  +---------------------------------------------------------------------+     |
|  | Control | Requirement              | JIT Implementation              |     |
|  +---------+--------------------------+---------------------------------+     |
|  | TRE-1   | Audit log accessibility  | JIT logs centralized            |     |
|  | TRE-2   | Continuous monitoring    | Real-time JIT session monitor   |     |
|  | TRE-3   | Response mechanisms      | Immediate access revocation     |     |
|  +---------+--------------------------+---------------------------------+     |
|                                                                               |
|  SECURITY LEVEL REQUIREMENTS                                                  |
|  ===========================                                                  |
|                                                                               |
|  +---------------------------------------------------------------------+     |
|  | SL   | JIT Requirements                                             |     |
|  +------+--------------------------------------------------------------+     |
|  | SL 1 | Basic JIT with single approval                               |     |
|  | SL 2 | JIT with MFA + manager approval                              |     |
|  | SL 3 | JIT with quorum approval + time restrictions                 |     |
|  | SL 4 | JIT with biometric + multi-level approval + real-time monitor|     |
|  +------+--------------------------------------------------------------+     |
|                                                                               |
+==============================================================================+
```

### SOC 2 Compliance

| Trust Criteria | Control | JIT Contribution |
|----------------|---------|------------------|
| CC6.1 | Logical access security | JIT enforces approval before access |
| CC6.2 | User authorization | Approval workflow with documented justification |
| CC6.3 | Access removal | Automatic access revocation at expiry |
| CC6.6 | Access restrictions | Time-bounded access with session limits |
| CC7.1 | Vulnerability detection | Reduces standing privilege exposure |
| CC7.2 | System monitoring | Real-time JIT session monitoring |
| CC7.4 | Incident response | Immediate revocation capability |

### PCI-DSS Compliance

| Requirement | Description | JIT Control |
|-------------|-------------|-------------|
| 7.1 | Limit access to system components | JIT eliminates standing privileges |
| 7.1.2 | Restrict privileged user access | Approval workflow for privileged access |
| 7.2.1 | Cover all system components | All privileged access through JIT |
| 8.1.5 | Manage third-party access | Vendor JIT with time limits |
| 10.2.2 | Root/admin actions | JIT session recording |
| 12.3.8 | Auto session disconnect | JIT automatic expiration |

### Evidence Collection for JIT Compliance

```bash
#!/bin/bash
# /opt/scripts/collect-jit-compliance-evidence.sh

EVIDENCE_DIR="/evidence/jit/$(date +%Y-%m)"
PERIOD="$(date -d '3 months ago' +%Y-%m-%d),$(date +%Y-%m-%d)"

mkdir -p "${EVIDENCE_DIR}"

echo "Collecting JIT compliance evidence..."

# JIT request history
wabadmin jit-requests --period "${PERIOD}" \
    --export > "${EVIDENCE_DIR}/jit-requests.csv"

# Approval audit trail
wabadmin jit-approvals --period "${PERIOD}" \
    --export > "${EVIDENCE_DIR}/jit-approvals.csv"

# Access duration analysis
wabadmin jit-analytics --period "${PERIOD}" \
    --metric duration \
    --export > "${EVIDENCE_DIR}/jit-duration-analysis.csv"

# Denied requests
wabadmin jit-requests --period "${PERIOD}" \
    --status denied \
    --export > "${EVIDENCE_DIR}/jit-denied.csv"

# Revoked access
wabadmin jit-requests --period "${PERIOD}" \
    --status revoked \
    --export > "${EVIDENCE_DIR}/jit-revoked.csv"

# Session recordings index
wabadmin sessions --period "${PERIOD}" \
    --filter "jit_access=true" \
    --export > "${EVIDENCE_DIR}/jit-sessions.csv"

echo "Evidence collection complete: ${EVIDENCE_DIR}"
```

---

## Best Practices

### Implementation Guidelines

```
+==============================================================================+
|                    JIT ACCESS BEST PRACTICES                                  |
+==============================================================================+
|                                                                               |
|  1. START WITH HIGH-RISK TARGETS                                              |
|  =================================                                            |
|                                                                               |
|  Phase 1: Critical production systems, databases, domain controllers          |
|  Phase 2: All production servers                                              |
|  Phase 3: Network devices, cloud infrastructure                               |
|  Phase 4: Development/staging (optional)                                      |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  2. DESIGN APPROPRIATE APPROVAL WORKFLOWS                                     |
|  =========================================                                    |
|                                                                               |
|  +---------------------------------------------------------------------+     |
|  | Access Type          | Recommended Workflow                         |     |
|  +----------------------+----------------------------------------------+     |
|  | Standard maintenance | Single approver, 4-hour timeout              |     |
|  | Production critical  | Quorum (2 of 3), 2-hour timeout              |     |
|  | Emergency/break-glass| Dual approval, 15-min timeout, post-review   |     |
|  | Vendor access        | Sequential (manager + security)              |     |
|  | Audit/compliance     | Auto-approve with logging                    |     |
|  +----------------------+----------------------------------------------+     |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  3. SET REASONABLE TIME LIMITS                                                |
|  ==============================                                               |
|                                                                               |
|  +---------------------------------------------------------------------+     |
|  | Access Type          | Recommended Duration                         |     |
|  +----------------------+----------------------------------------------+     |
|  | Investigation/debug  | 1-2 hours                                    |     |
|  | Standard maintenance | 4 hours                                      |     |
|  | Major maintenance    | 8 hours (with extension option)              |     |
|  | Emergency access     | 2 hours (single-use)                         |     |
|  | Vendor access        | Task-specific, 2-4 hours typical             |     |
|  +----------------------+----------------------------------------------+     |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  4. INTEGRATE WITH ITSM                                                       |
|  ======================                                                       |
|                                                                               |
|  - Require ticket reference for production access                             |
|  - Validate ticket status automatically                                       |
|  - Update tickets with session information                                    |
|  - Link session recordings to tickets                                         |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  5. MONITOR AND REVIEW                                                        |
|  =====================                                                        |
|                                                                               |
|  Daily:                                                                       |
|  - Review denied requests for patterns                                        |
|  - Check for expired requests (user education needed?)                        |
|                                                                               |
|  Weekly:                                                                       |
|  - Analyze JIT usage patterns                                                 |
|  - Review break-glass usage                                                   |
|  - Verify approval response times                                             |
|                                                                               |
|  Monthly:                                                                      |
|  - Audit JIT policies                                                         |
|  - Review approver coverage                                                   |
|  - Optimize time limits based on actual usage                                 |
|                                                                               |
+==============================================================================+
```

### Security Considerations

```
+==============================================================================+
|                    SECURITY CONSIDERATIONS                                    |
+==============================================================================+
|                                                                               |
|  PROTECT THE APPROVAL CHAIN                                                   |
|  ===========================                                                  |
|                                                                               |
|  - Approvers must use MFA                                                     |
|  - Approvers cannot approve their own requests                                |
|  - Maintain adequate approver coverage (vacation, turnover)                   |
|  - Monitor for approval fatigue (rubber-stamping)                             |
|                                                                               |
|  CREDENTIAL MANAGEMENT                                                        |
|  =====================                                                        |
|                                                                               |
|  - Rotate credentials after break-glass usage                                 |
|  - Consider single-use credentials for sensitive targets                      |
|  - Cache credentials appropriately for offline sites                          |
|                                                                               |
|  SESSION SECURITY                                                             |
|  ================                                                             |
|                                                                               |
|  - Record all JIT sessions                                                    |
|  - Enable real-time monitoring for critical access                            |
|  - Implement command blocking for destructive operations                      |
|  - Disable file transfer for vendor sessions                                  |
|                                                                               |
|  PREVENT ABUSE                                                                |
|  =============                                                                |
|                                                                               |
|  - Rate-limit JIT requests per user                                           |
|  - Flag excessive extension requests                                          |
|  - Alert on out-of-pattern access requests                                    |
|  - Review denied requests for social engineering attempts                     |
|                                                                               |
|  AUDIT TRAIL INTEGRITY                                                        |
|  =====================                                                        |
|                                                                               |
|  - JIT logs should be tamper-evident                                          |
|  - Forward logs to SIEM in real-time                                          |
|  - Retain logs per compliance requirements                                    |
|  - Link JIT events to session recordings                                      |
|                                                                               |
+==============================================================================+
```

---

## Troubleshooting

### Common Issues

```
+==============================================================================+
|                    JIT ACCESS TROUBLESHOOTING                                 |
+==============================================================================+

  ISSUE 1: JIT Request Not Appearing to Approvers
  ================================================

  Symptoms:
  - User creates request but approvers don't see it
  - No email notifications received

  Diagnosis:
  +------------------------------------------------------------------------+
  | # Check request was created                                            |
  | wabadmin jit-requests --user <username> --last 1h                      |
  |                                                                        |
  | # Verify approval policy configuration                                 |
  | wabadmin approval-policy show <policy-name>                            |
  |                                                                        |
  | # Check notification settings                                          |
  | wabadmin notifications --test <approver-email>                         |
  |                                                                        |
  | # Review logs                                                          |
  | journalctl -u wallix-bastion | grep -i "approval"                      |
  +------------------------------------------------------------------------+

  Solutions:
  - Verify approver group membership
  - Check email/notification service configuration
  - Confirm authorization links to correct approval policy

  --------------------------------------------------------------------------

  ISSUE 2: Approved Request But Cannot Connect
  =============================================

  Symptoms:
  - Request shows "approved" status
  - Session connection fails
  - "Access denied" error

  Diagnosis:
  +------------------------------------------------------------------------+
  | # Check access window                                                  |
  | wabadmin jit-request show <request-id>                                 |
  |                                                                        |
  | # Verify time window is active                                         |
  | date -u  # Compare to access window times                              |
  |                                                                        |
  | # Check authorization status                                           |
  | wabadmin authorizations --user <username> --target <target>            |
  +------------------------------------------------------------------------+

  Solutions:
  - Ensure current time is within access window
  - Check time zone configuration
  - Verify authorization is still active (not disabled)

  --------------------------------------------------------------------------

  ISSUE 3: Approval Timeout Before Response
  ==========================================

  Symptoms:
  - Requests auto-denied due to timeout
  - Approvers didn't respond in time

  Diagnosis:
  +------------------------------------------------------------------------+
  | # Check approval timeout settings                                      |
  | wabadmin approval-policy show <policy-name> | grep timeout             |
  |                                                                        |
  | # Review approver activity                                             |
  | wabadmin audit --filter "event_type=approval" --last 24h               |
  +------------------------------------------------------------------------+

  Solutions:
  - Increase timeout duration
  - Add more approvers for coverage
  - Enable escalation for approaching timeouts
  - Configure SMS notifications for urgent requests

  --------------------------------------------------------------------------

  ISSUE 4: Session Terminated Unexpectedly
  =========================================

  Symptoms:
  - Active session disconnected
  - "Session expired" message

  Diagnosis:
  +------------------------------------------------------------------------+
  | # Check session history                                                |
  | wabadmin sessions --user <username> --last 4h                          |
  |                                                                        |
  | # Check JIT request status                                             |
  | wabadmin jit-request show <request-id>                                 |
  |                                                                        |
  | # Review audit logs                                                    |
  | wabadmin audit --session <session-id>                                  |
  +------------------------------------------------------------------------+

  Solutions:
  - JIT access window expired - request extension before expiry
  - Access revoked by admin - check with security team
  - Idle timeout - configure appropriate idle settings

  --------------------------------------------------------------------------

  ISSUE 5: Ticket Validation Failing
  ===================================

  Symptoms:
  - "Invalid ticket reference" error
  - Ticket integration not working

  Diagnosis:
  +------------------------------------------------------------------------+
  | # Test ticket integration                                              |
  | wabadmin integration test servicenow                                   |
  |                                                                        |
  | # Check ticket validation settings                                     |
  | wabadmin integration show servicenow                                   |
  |                                                                        |
  | # Manual ticket lookup                                                 |
  | curl -X GET "https://instance.service-now.com/api/now/table/           |
  |   change_request?sysparm_query=number=CHG0012345"                      |
  +------------------------------------------------------------------------+

  Solutions:
  - Verify ticket exists and is in valid state
  - Check integration credentials
  - Confirm user email matches ticket assignee

+==============================================================================+
```

### Diagnostic Commands

```bash
# JIT System Health Check
wabadmin jit-status

# List pending approvals across all approvers
wabadmin jit-approvals --status pending --all

# JIT request statistics
wabadmin jit-analytics --period "last 30 days"

# Test notification delivery
wabadmin notifications --test --type jit_request

# Verify approval policy
wabadmin approval-policy validate <policy-name>

# Check integration connectivity
wabadmin integration test --all

# Review JIT-related errors
wabadmin logs --filter "component=jit" --level error --last 24h
```

### Log Locations

| Log Type | Location | Contents |
|----------|----------|----------|
| JIT Requests | `/var/log/wallix/jit-requests.log` | Request creation, status changes |
| Approvals | `/var/log/wallix/approvals.log` | Approval/denial actions |
| Notifications | `/var/log/wallix/notifications.log` | Email/webhook delivery |
| Integration | `/var/log/wallix/integration.log` | ITSM integration events |
| Sessions | `/var/log/wallix/sessions.log` | JIT session events |

---

## External References

- [WALLIX Documentation Portal](https://pam.wallix.one/documentation)
- [WALLIX REST API Reference](https://github.com/wallix/wbrest_samples)
- [NIST SP 800-53 Access Control](https://csrc.nist.gov/publications/detail/sp/800-53/rev-5/final)
- [CIS Controls v8 - Access Control](https://www.cisecurity.org/controls/v8)
- [IEC 62443 Standards](https://www.isa.org/standards-and-publications/isa-standards/isa-iec-62443-series-of-standards)

---

## See Also

**Related Sections:**
- [07 - Authorization](../07-authorization/README.md) - RBAC and approval workflows
- [44 - User Self-Service](../44-user-self-service/README.md) - Self-service portal configuration

**Related Documentation:**
- [Pre-Production Lab](/pre/README.md) - JIT access testing

**Official Resources:**
- [WALLIX Documentation](https://pam.wallix.one/documentation)

---

## Next Steps

Continue to [06 - Authorization](../07-authorization/README.md) for detailed authorization configuration, or see [33 - Compliance & Audit](../24-compliance-audit/README.md) for compliance reporting.

---

*Document Version: 1.0*
*Last Updated: January 2026*
