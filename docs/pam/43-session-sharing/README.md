# Session Sharing and Collaboration Guide

Comprehensive guide for real-time session sharing, multi-user collaboration, and joint access workflows in WALLIX Bastion 12.x for training, incident response, and dual-control scenarios.

---

## Table of Contents

1. [Session Sharing Overview](#session-sharing-overview)
2. [Sharing Architecture](#sharing-architecture)
3. [Sharing Modes](#sharing-modes)
4. [Initiating Session Sharing](#initiating-session-sharing)
5. [Permissions and Controls](#permissions-and-controls)
6. [Real-Time Collaboration](#real-time-collaboration)
7. [Training and Knowledge Transfer](#training-and-knowledge-transfer)
8. [Incident Response Use Cases](#incident-response-use-cases)
9. [Security Controls](#security-controls)
10. [Configuration](#configuration)
11. [Troubleshooting](#troubleshooting)

---

## Session Sharing Overview

### What is Session Sharing?

Session sharing enables multiple users to simultaneously access and interact with a single privileged session, providing real-time collaboration capabilities for training, auditing, incident response, and dual-control scenarios.

```
+==============================================================================+
|                        SESSION SHARING CONCEPT                                |
+==============================================================================+
|                                                                               |
|  TRADITIONAL SESSION                    SHARED SESSION                        |
|  ===================                    ==============                        |
|                                                                               |
|  +-------------+                        +-------------+                       |
|  |   User A    |                        |   User A    | (Presenter/Owner)     |
|  +------+------+                        +------+------+                       |
|         |                                      |                              |
|         v                                      v                              |
|  +-------------+                        +-------------+                       |
|  |   WALLIX    |                        |   WALLIX    |<----+----+----+       |
|  |   Bastion   |                        |   Bastion   |     |    |    |       |
|  +------+------+                        +------+------+     |    |    |       |
|         |                                      |            |    |    |       |
|         v                                      v            |    |    |       |
|  +-------------+                        +-------------+     |    |    |       |
|  |   Target    |                        |   Target    |     |    |    |       |
|  |   System    |                        |   System    |     |    |    |       |
|  +-------------+                        +-------------+     |    |    |       |
|                                                             |    |    |       |
|  * Single user                          +-------+ +-------+ +----+    |       |
|  * Private session                      |User B | |User C | |User D   |       |
|  * Standard recording                   |(View) | |(Share)| |(Audit)  |       |
|                                         +-------+ +-------+ +---------+       |
|                                                                               |
|                                         * Multiple participants               |
|                                         * Real-time collaboration             |
|                                         * Enhanced recording with all users   |
|                                                                               |
+==============================================================================+
```

### Use Cases

| Use Case | Description | Primary Benefit |
|----------|-------------|-----------------|
| **Training** | Senior admin teaches junior staff | Knowledge transfer |
| **Mentoring** | Expert guides new team member | Skill development |
| **Dual Control** | Two-person integrity for critical operations | Security compliance |
| **Incident Response** | Multiple experts collaborate on issue | Faster resolution |
| **Vendor Support** | External vendor assists with internal oversight | Controlled access |
| **Audit Observation** | Auditor observes privileged operations | Compliance evidence |
| **Help Desk** | IT support assists user remotely | User support |
| **Change Management** | Peer review of configuration changes | Quality assurance |

### Benefits of Session Sharing

```
+==============================================================================+
|                        SESSION SHARING BENEFITS                               |
+==============================================================================+
|                                                                               |
|  SECURITY BENEFITS                                                            |
|  =================                                                            |
|                                                                               |
|  * Dual-control enforcement for sensitive operations                          |
|  * Real-time oversight of third-party access                                  |
|  * Complete audit trail of all participants                                   |
|  * Immediate intervention capability                                          |
|  * Reduced risk of unauthorized actions                                       |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  OPERATIONAL BENEFITS                                                         |
|  ====================                                                         |
|                                                                               |
|  * Faster incident resolution with expert collaboration                       |
|  * Effective knowledge transfer without direct access                         |
|  * Reduced travel costs for remote training                                   |
|  * Immediate expert assistance for complex issues                             |
|  * Peer review of critical changes                                            |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  COMPLIANCE BENEFITS                                                          |
|  ===================                                                          |
|                                                                               |
|  * Meet four-eyes principle requirements                                      |
|  * Documented oversight for sensitive operations                              |
|  * Complete participant identification in recordings                          |
|  * Audit-ready evidence of collaborative access                               |
|  * SOX, PCI-DSS, IEC 62443 compliance support                                 |
|                                                                               |
+==============================================================================+
```

### Security Considerations

| Consideration | Mitigation |
|---------------|------------|
| Unauthorized viewing | Role-based sharing permissions |
| Session hijacking | Mutual authentication and encryption |
| Credential exposure | Shared users never see passwords |
| Audit integrity | All participants logged separately |
| Access creep | Time-limited sharing with auto-expiration |
| Privacy concerns | Configurable notifications to session owner |

---

## Sharing Architecture

### Multi-User Session Architecture

```
+==============================================================================+
|                     SESSION SHARING ARCHITECTURE                              |
+==============================================================================+
|                                                                               |
|  PARTICIPANTS                           WALLIX BASTION                        |
|  ============                           ==============                        |
|                                                                               |
|  +------------------+                   +----------------------------------+  |
|  | Session Owner    |                   |                                  |  |
|  | (Presenter)      |   WebSocket/TLS   |     Session Sharing Service      |  |
|  | jsmith           +------------------>|                                  |  |
|  +------------------+                   |  +----------------------------+  |  |
|                                         |  |    Session Multiplexer     |  |  |
|  +------------------+                   |  |                            |  |  |
|  | Viewer 1         |   WebSocket/TLS   |  |  * Input aggregation       |  |  |
|  | (Shadow Mode)    +------------------>|  |  * Output broadcast        |  |  |
|  | bjones           |                   |  |  * Control management      |  |  |
|  +------------------+                   |  |  * Event synchronization   |  |  |
|                                         |  +-------------+--------------+  |  |
|  +------------------+                   |                |                 |  |
|  | Viewer 2         |   WebSocket/TLS   |                v                 |  |
|  | (Interactive)    +------------------>|  +----------------------------+  |  |
|  | mwilson          |                   |  |   Session Manager Core     |  |  |
|  +------------------+                   |  +-------------+--------------+  |  |
|                                         |                |                 |  |
|  +------------------+                   |                v                 |  |
|  | Auditor          |   WebSocket/TLS   |  +----------------------------+  |  |
|  | (View-Only)      +------------------>|  |   Recording Engine         |  |  |
|  | auditor1         |                   |  |                            |  |  |
|  +------------------+                   |  |  * All participants        |  |  |
|                                         |  |  * All inputs/outputs      |  |  |
|                                         |  |  * Control transfers       |  |  |
|                                         |  |  * Chat messages           |  |  |
|                                         |  +----------------------------+  |  |
|                                         |                                  |  |
|                                         +----------------+-----------------+  |
|                                                          |                    |
|                                                          v                    |
|                                         +----------------------------------+  |
|                                         |         TARGET SYSTEM            |  |
|                                         |                                  |  |
|                                         |  Single authenticated session    |  |
|                                         |  All user actions multiplexed    |  |
|                                         +----------------------------------+  |
|                                                                               |
+==============================================================================+
```

### Network Communication Flow

```
+==============================================================================+
|                        NETWORK COMMUNICATION                                  |
+==============================================================================+
|                                                                               |
|  PROTOCOL STACK                                                               |
|  ==============                                                               |
|                                                                               |
|  +------------------------------------------------------------------------+  |
|  |                        APPLICATION LAYER                               |  |
|  |  +------------------+  +------------------+  +------------------+       |  |
|  |  | Session Data     |  | Control Messages |  | Chat/Annotation  |       |  |
|  |  | (Screen/Input)   |  | (Handoff/Perms)  |  | (Collaboration)  |       |  |
|  |  +------------------+  +------------------+  +------------------+       |  |
|  +------------------------------------------------------------------------+  |
|                                    |                                          |
|  +------------------------------------------------------------------------+  |
|  |                        PRESENTATION LAYER                              |  |
|  |  +------------------------------------------------------------------+  |  |
|  |  | JSON/Binary Encoding | Compression | Session Multiplexing        |  |  |
|  |  +------------------------------------------------------------------+  |  |
|  +------------------------------------------------------------------------+  |
|                                    |                                          |
|  +------------------------------------------------------------------------+  |
|  |                        TRANSPORT LAYER                                 |  |
|  |  +------------------------------------------------------------------+  |  |
|  |  | WebSocket (wss://) | TLS 1.3 | Port 443                          |  |  |
|  |  +------------------------------------------------------------------+  |  |
|  +------------------------------------------------------------------------+  |
|                                                                               |
|  PORT USAGE                                                                   |
|  ==========                                                                   |
|                                                                               |
|  +-------------------+-------------------+----------------------------------+ |
|  | Port              | Protocol          | Purpose                          | |
|  +-------------------+-------------------+----------------------------------+ |
|  | 443/TCP           | HTTPS/WebSocket   | Primary sharing connection       | |
|  | 443/TCP           | WSS               | Real-time session data           | |
|  | 8443/TCP          | HTTPS             | Management API (optional)        | |
|  +-------------------+-------------------+----------------------------------+ |
|                                                                               |
+==============================================================================+
```

### Component Interactions

```
+==============================================================================+
|                       COMPONENT INTERACTIONS                                  |
+==============================================================================+
|                                                                               |
|  1. SESSION INITIATION                                                        |
|     ==================                                                        |
|                                                                               |
|     Owner         Bastion            Target                                   |
|       |              |                  |                                     |
|       |-- Connect -->|                  |                                     |
|       |              |-- Authenticate ->|                                     |
|       |              |<- Session OK ----|                                     |
|       |<- Session ---|                  |                                     |
|       |   Started    |                  |                                     |
|                                                                               |
|  2. SHARING INVITATION                                                        |
|     ==================                                                        |
|                                                                               |
|     Owner         Bastion            Viewer                                   |
|       |              |                  |                                     |
|       |-- Invite --->|                  |                                     |
|       |   User B     |-- Notification ->|                                     |
|       |              |                  |                                     |
|       |              |<- Accept --------|                                     |
|       |              |-- Join Session ->|                                     |
|       |<- Viewer ----|                  |                                     |
|       |   Joined     |                  |                                     |
|                                                                               |
|  3. DATA FLOW (During Shared Session)                                         |
|     =================================                                         |
|                                                                               |
|     Owner         Bastion            Target         Viewers                   |
|       |              |                  |              |                      |
|       |-- Input ---->|-- Forward ----->|              |                      |
|       |              |<- Output -------|              |                      |
|       |<- Broadcast -|-----------------|------------->|                      |
|       |              |                  |              |                      |
|       |              |<- Input ---------|--------------|  (if interactive)   |
|       |              |-- Forward ----->|              |                      |
|                                                                               |
+==============================================================================+
```

---

## Sharing Modes

### Overview of Sharing Modes

WALLIX Bastion supports multiple session sharing modes to accommodate different collaboration scenarios.

```
+==============================================================================+
|                         SESSION SHARING MODES                                 |
+==============================================================================+
|                                                                               |
|  +------------------------------------------------------------------------+  |
|  |  MODE 1: VIEW-ONLY (SHADOW)                                            |  |
|  |  ==============================                                        |  |
|  |                                                                        |  |
|  |  * Observer can see session output only                                |  |
|  |  * No input capability                                                 |  |
|  |  * Session owner may or may not be notified (configurable)             |  |
|  |  * Used for: Auditing, monitoring, covert observation                  |  |
|  |                                                                        |  |
|  |     +--------+     +--------+                                          |  |
|  |     | Owner  |====>| Target |      Observer: View only                 |  |
|  |     +--------+     +--------+           |                              |  |
|  |         ^                               |                              |  |
|  |         |          +----------+         |                              |  |
|  |         +----------| Observer |<--------+                              |  |
|  |                    | (View)   |                                        |  |
|  |                    +----------+                                        |  |
|  +------------------------------------------------------------------------+  |
|                                                                               |
|  +------------------------------------------------------------------------+  |
|  |  MODE 2: INTERACTIVE (SHARED CONTROL)                                  |  |
|  |  ======================================                                |  |
|  |                                                                        |  |
|  |  * Multiple users can provide input simultaneously                     |  |
|  |  * All inputs merged to target                                         |  |
|  |  * Session owner always notified                                       |  |
|  |  * Used for: Collaborative troubleshooting, pair administration        |  |
|  |                                                                        |  |
|  |     +--------+     +--------+                                          |  |
|  |     | Owner  |====>|        |      Both can type/interact              |  |
|  |     +--------+     | Target |                                          |  |
|  |     +--------+     |        |                                          |  |
|  |     | User B |====>|        |                                          |  |
|  |     +--------+     +--------+                                          |  |
|  +------------------------------------------------------------------------+  |
|                                                                               |
|  +------------------------------------------------------------------------+  |
|  |  MODE 3: PRESENTER (ONE CONTROLS, OTHERS VIEW)                         |  |
|  |  ==============================================                        |  |
|  |                                                                        |  |
|  |  * One user has exclusive control at a time                            |  |
|  |  * Control can be transferred between users                            |  |
|  |  * All viewers see same output                                         |  |
|  |  * Used for: Training, demonstrations, controlled handoff              |  |
|  |                                                                        |  |
|  |     +------------+     +--------+                                      |  |
|  |     | Presenter  |====>| Target |      Only presenter can interact     |  |
|  |     | (Control)  |     +--------+                                      |  |
|  |     +------------+          |                                          |  |
|  |          |                  |                                          |  |
|  |          v                  v                                          |  |
|  |     +----------+  +----------+  +----------+                           |  |
|  |     | Viewer 1 |  | Viewer 2 |  | Viewer 3 |                           |  |
|  |     +----------+  +----------+  +----------+                           |  |
|  +------------------------------------------------------------------------+  |
|                                                                               |
+==============================================================================+
```

### View-Only (Shadow) Mode

**Purpose:** Observation without interaction

**Configuration:**
```json
{
    "sharing_mode": "view_only",
    "settings": {
        "notify_owner": false,
        "show_viewer_cursor": false,
        "allow_chat": true,
        "record_observer": true,
        "max_viewers": 10
    }
}
```

**Use Cases:**
- Security monitoring and oversight
- Compliance auditing
- Performance evaluation
- Covert investigation (with proper authorization)

**Capabilities:**

| Capability | Allowed |
|------------|---------|
| View screen output | Yes |
| Send keyboard input | No |
| Send mouse input | No |
| Use chat | Configurable |
| Add annotations | Configurable |
| Take screenshots | Configurable |

### Interactive (Shared Control) Mode

**Purpose:** Collaborative control of a session

**Configuration:**
```json
{
    "sharing_mode": "interactive",
    "settings": {
        "notify_owner": true,
        "input_merge_mode": "interleaved",
        "conflict_resolution": "last_wins",
        "activity_timeout_seconds": 300,
        "max_participants": 5,
        "require_approval": true
    }
}
```

**Input Handling:**
```
+==============================================================================+
|                    INTERACTIVE MODE INPUT HANDLING                            |
+==============================================================================+
|                                                                               |
|  INPUT MERGE STRATEGIES                                                       |
|  ======================                                                       |
|                                                                               |
|  INTERLEAVED (Default)                                                        |
|  ---------------------                                                        |
|  * Inputs processed in order received                                         |
|  * No blocking between users                                                  |
|  * May cause confusion with simultaneous typing                               |
|                                                                               |
|  User A: "ls -la"      --> Target receives: "lcsd -l/aetc"                   |
|  User B: "cd /etc"         (interleaved characters)                          |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  QUEUED                                                                       |
|  ------                                                                       |
|  * Commands queued and executed sequentially                                  |
|  * Each user waits for command completion                                     |
|  * Prevents interleaving confusion                                            |
|                                                                               |
|  User A: "ls -la"      --> Target receives: "ls -la" then "cd /etc"          |
|  User B: "cd /etc"                                                            |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  TOKEN-BASED                                                                  |
|  -----------                                                                  |
|  * Users must request input token                                             |
|  * Only token holder can send input                                           |
|  * Token auto-releases after timeout                                          |
|                                                                               |
|  User A: [Has Token] "ls -la"  --> Input accepted                            |
|  User B: [No Token]  "cd /etc" --> Input rejected (must request token)       |
|                                                                               |
+==============================================================================+
```

### Presenter Mode

**Purpose:** Controlled demonstrations with single active controller

**Configuration:**
```json
{
    "sharing_mode": "presenter",
    "settings": {
        "initial_presenter": "session_owner",
        "allow_control_transfer": true,
        "transfer_requires_approval": true,
        "presenter_indicator": true,
        "auto_return_to_owner_seconds": 300,
        "max_viewers": 50
    }
}
```

**Control Transfer Workflow:**
```
+==============================================================================+
|                    PRESENTER MODE CONTROL TRANSFER                            |
+==============================================================================+
|                                                                               |
|  CONTROL TRANSFER METHODS                                                     |
|  ========================                                                     |
|                                                                               |
|  1. OWNER-INITIATED TRANSFER                                                  |
|     -------------------------                                                 |
|     Owner clicks "Transfer Control" -> Selects recipient -> Confirmed         |
|                                                                               |
|  2. VIEWER-REQUESTED TRANSFER                                                 |
|     --------------------------                                                |
|     Viewer clicks "Request Control" -> Owner approves/denies -> Transfer      |
|                                                                               |
|  3. AUTOMATIC TRANSFER (Configurable)                                         |
|     ---------------------------------                                         |
|     Owner idle for X minutes -> Next in queue gets control                    |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  TRANSFER SEQUENCE                                                            |
|                                                                               |
|  Current         Bastion            Next                                      |
|  Presenter                          Presenter                                 |
|     |               |                  |                                      |
|     |-- Transfer -->|                  |                                      |
|     |   to User B   |                  |                                      |
|     |               |-- Offer -------->|                                      |
|     |               |   Control        |                                      |
|     |               |<- Accept --------|                                      |
|     |<- Control ----|                  |                                      |
|     |   Revoked     |-- Control ------>|                                      |
|     |               |   Granted        |                                      |
|     |               |                  |                                      |
|  [Now Viewer]       |           [Now Presenter]                               |
|                                                                               |
+==============================================================================+
```

### Mode Comparison

| Feature | View-Only | Interactive | Presenter |
|---------|-----------|-------------|-----------|
| Multiple viewers | Yes | Yes | Yes |
| Owner notification | Configurable | Always | Always |
| Viewer input | No | Yes | Presenter only |
| Control transfer | N/A | N/A | Yes |
| Best for | Auditing | Collaboration | Training |
| Max participants | 10+ | 5 | 50+ |
| Complexity | Low | Medium | Medium |

---

## Initiating Session Sharing

### Requesting to Join a Session

**Via Web UI:**
```
Navigation: Active Sessions > [Select Session] > Request to Join

+------------------------------------------------------------------------+
|                    REQUEST TO JOIN SESSION                              |
+------------------------------------------------------------------------+
|                                                                         |
|  Session: SES-2026-001-A7B3C9D1                                        |
|  Owner: jsmith (John Smith)                                            |
|  Target: root@srv-prod-01 (SSH)                                        |
|  Started: 2026-01-15 09:30:15                                          |
|                                                                         |
|  Requested Mode: [ View Only    v ]                                    |
|                                                                         |
|  Reason for Join Request:                                              |
|  +------------------------------------------------------------------+  |
|  | Need to observe troubleshooting for training purposes            |  |
|  +------------------------------------------------------------------+  |
|                                                                         |
|  [ ] Notify me when session ends                                       |
|  [ ] Request recording access after session                            |
|                                                                         |
|  [Cancel]                            [Submit Request]                   |
|                                                                         |
+------------------------------------------------------------------------+
```

**Via API:**
```bash
# Request to join an active session
curl -X POST "https://bastion.example.com/api/v3.12/sessions/SES-2026-001-A7B3C9D1/join-request" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "requested_mode": "view_only",
    "reason": "Need to observe troubleshooting for training purposes",
    "notify_on_end": true
  }'

# Response:
{
    "request_id": "REQ-2026-001-XYZ789",
    "status": "pending",
    "session_id": "SES-2026-001-A7B3C9D1",
    "owner": "jsmith",
    "requested_mode": "view_only",
    "submitted": "2026-01-15T09:45:00Z"
}
```

### Inviting Users to a Session

**Via Web UI (Session Owner):**
```
Navigation: [Active Session] > Share > Invite Users

+------------------------------------------------------------------------+
|                      INVITE TO SESSION                                  |
+------------------------------------------------------------------------+
|                                                                         |
|  Current Session: root@srv-prod-01 (SSH)                               |
|  Session ID: SES-2026-001-A7B3C9D1                                     |
|                                                                         |
|  Invite Users:                                                         |
|  +------------------------------------------------------------------+  |
|  | Search: [bjones________________] [Search]                        |  |
|  |                                                                  |  |
|  | Selected Users:                                                  |  |
|  |   [x] bjones (Bob Jones) - DBA Team                             |  |
|  |   [x] mwilson (Mary Wilson) - Security Team                     |  |
|  +------------------------------------------------------------------+  |
|                                                                         |
|  Sharing Mode: [ Presenter Mode  v ]                                   |
|                                                                         |
|  Permissions:                                                          |
|  [x] Allow control request                                             |
|  [x] Allow chat messaging                                              |
|  [ ] Allow annotations                                                 |
|  [ ] Allow screenshots                                                 |
|                                                                         |
|  Invitation Message:                                                   |
|  +------------------------------------------------------------------+  |
|  | Please join to help troubleshoot the database connectivity issue |  |
|  +------------------------------------------------------------------+  |
|                                                                         |
|  [Cancel]                            [Send Invitation]                  |
|                                                                         |
+------------------------------------------------------------------------+
```

**Via API:**
```bash
# Invite users to current session
curl -X POST "https://bastion.example.com/api/v3.12/sessions/SES-2026-001-A7B3C9D1/invite" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "invitees": ["bjones", "mwilson"],
    "mode": "presenter",
    "permissions": {
      "allow_control_request": true,
      "allow_chat": true,
      "allow_annotations": false,
      "allow_screenshots": false
    },
    "message": "Please join to help troubleshoot the database connectivity issue",
    "expiration_minutes": 60
  }'

# Response:
{
    "invitation_id": "INV-2026-001-ABC123",
    "session_id": "SES-2026-001-A7B3C9D1",
    "invitees": [
        {
            "username": "bjones",
            "status": "pending",
            "notification_sent": true
        },
        {
            "username": "mwilson",
            "status": "pending",
            "notification_sent": true
        }
    ],
    "expires": "2026-01-15T10:45:00Z"
}
```

### Ad-Hoc Sharing

**Quick Share Link:**
```bash
# Generate a time-limited share link
curl -X POST "https://bastion.example.com/api/v3.12/sessions/SES-2026-001-A7B3C9D1/share-link" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "mode": "view_only",
    "expires_minutes": 30,
    "max_uses": 3,
    "require_authentication": true
  }'

# Response:
{
    "share_url": "https://bastion.example.com/join/XYZ789ABC123",
    "expires": "2026-01-15T10:15:00Z",
    "max_uses": 3,
    "current_uses": 0
}
```

**Direct Join (for authorized users):**
```bash
# Join session directly (requires appropriate permissions)
curl -X POST "https://bastion.example.com/api/v3.12/sessions/SES-2026-001-A7B3C9D1/join" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "mode": "view_only"
  }'

# Response:
{
    "participant_id": "PART-2026-001-DEF456",
    "session_id": "SES-2026-001-A7B3C9D1",
    "mode": "view_only",
    "websocket_url": "wss://bastion.example.com/session/SES-2026-001-A7B3C9D1/stream?token=xyz",
    "joined_at": "2026-01-15T09:50:00Z"
}
```

---

## Permissions and Controls

### Who Can Share Sessions

```
+==============================================================================+
|                    SESSION SHARING PERMISSIONS                                |
+==============================================================================+
|                                                                               |
|  PERMISSION MATRIX                                                            |
|  =================                                                            |
|                                                                               |
|  +------------------------+--------+--------+--------+--------+--------+     |
|  | Action                 | Owner  | Admin  | Auditor| Manager| User   |     |
|  +------------------------+--------+--------+--------+--------+--------+     |
|  | Start shared session   |   Y    |   Y    |   -    |   -    |   -    |     |
|  | Invite users           |   Y    |   Y    |   -    |   -    |   -    |     |
|  | Accept invitation      |   Y    |   Y    |   Y    |   Y    |   Y*   |     |
|  | Request to join        |   -    |   Y    |   Y    |   Y    |   -*   |     |
|  | Join without approval  |   -    |   Y    |   Y*   |   -    |   -    |     |
|  | Transfer control       |   Y    |   Y    |   -    |   -    |   -    |     |
|  | Revoke participant     |   Y    |   Y    |   -    |   -    |   -    |     |
|  | Force-join any session |   -    |   Y    |   -    |   -    |   -    |     |
|  | View sharing settings  |   Y    |   Y    |   Y    |   Y    |   -    |     |
|  | Modify sharing policy  |   -    |   Y    |   -    |   -    |   -    |     |
|  +------------------------+--------+--------+--------+--------+--------+     |
|                                                                               |
|  Y = Yes, - = No, Y* = Conditional (depends on policy)                        |
|                                                                               |
+==============================================================================+
```

### Role-Based Sharing Policies

```json
{
    "sharing_policies": {
        "admin": {
            "can_share_sessions": true,
            "can_invite_any_user": true,
            "can_join_any_session": true,
            "can_force_join": true,
            "default_mode": "interactive",
            "require_owner_approval": false
        },
        "auditor": {
            "can_share_sessions": false,
            "can_invite_any_user": false,
            "can_join_any_session": true,
            "can_force_join": false,
            "default_mode": "view_only",
            "require_owner_approval": false,
            "notify_owner": false
        },
        "operator": {
            "can_share_sessions": true,
            "can_invite_any_user": false,
            "can_invite_same_group": true,
            "can_join_any_session": false,
            "default_mode": "presenter",
            "require_owner_approval": true
        },
        "user": {
            "can_share_sessions": false,
            "can_invite_any_user": false,
            "can_join_any_session": false,
            "can_accept_invitations": true,
            "default_mode": "view_only",
            "require_owner_approval": true
        }
    }
}
```

### Who Can Be Invited

**Invitation Eligibility Rules:**
```
+==============================================================================+
|                      INVITATION ELIGIBILITY                                   |
+==============================================================================+
|                                                                               |
|  ELIGIBLE TO BE INVITED:                                                      |
|  =======================                                                      |
|                                                                               |
|  * Users with active WALLIX Bastion accounts                                  |
|  * Users with "session_sharing_participant" permission                        |
|  * Users in same user group (if group-restricted sharing enabled)             |
|  * Users with authorization to the target (if target-based restriction)       |
|                                                                               |
|  NOT ELIGIBLE:                                                                |
|  =============                                                                |
|                                                                               |
|  * Disabled accounts                                                          |
|  * Locked accounts                                                            |
|  * Users without sharing permission                                           |
|  * External users (unless external sharing enabled)                           |
|  * Users on sharing blacklist                                                 |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  AUTHORIZATION-BASED RESTRICTIONS                                             |
|  ================================                                             |
|                                                                               |
|  +-------------------------------------------------------------------+       |
|  | Authorization Setting     | Who Can Be Invited                    |       |
|  +-------------------------------------------------------------------+       |
|  | sharing_restriction: none | Any eligible user                      |       |
|  | sharing_restriction: group| Same user group only                   |       |
|  | sharing_restriction: auth | Users with same authorization          |       |
|  | sharing_restriction: list | Only users on explicit allow list      |       |
|  +-------------------------------------------------------------------+       |
|                                                                               |
+==============================================================================+
```

### Control Handoff Procedures

**Presenter Mode Control Transfer:**

```bash
# Session owner transfers control to participant
curl -X POST "https://bastion.example.com/api/v3.12/sessions/SES-2026-001-A7B3C9D1/control/transfer" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "to_participant": "bjones",
    "reason": "Bob will demonstrate database query optimization",
    "duration_minutes": 15,
    "auto_return": true
  }'

# Participant requests control
curl -X POST "https://bastion.example.com/api/v3.12/sessions/SES-2026-001-A7B3C9D1/control/request" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "reason": "Need to run specific diagnostic commands",
    "requested_duration_minutes": 10
  }'

# Session owner approves control request
curl -X POST "https://bastion.example.com/api/v3.12/sessions/SES-2026-001-A7B3C9D1/control/approve" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "request_id": "CTRL-REQ-001",
    "approved_duration_minutes": 10
  }'
```

**Control Transfer Audit Log:**
```json
{
    "control_transfers": [
        {
            "timestamp": "2026-01-15T09:55:00Z",
            "from_user": "jsmith",
            "to_user": "bjones",
            "transfer_type": "owner_initiated",
            "reason": "Bob will demonstrate database query optimization",
            "duration_granted_minutes": 15
        },
        {
            "timestamp": "2026-01-15T10:10:00Z",
            "from_user": "bjones",
            "to_user": "jsmith",
            "transfer_type": "auto_return",
            "reason": "Duration expired"
        }
    ]
}
```

---

## Real-Time Collaboration

### Chat During Sessions

**In-Session Chat Interface:**
```
+------------------------------------------------------------------------+
|                       SESSION CHAT                                      |
+------------------------------------------------------------------------+
|                                                                         |
|  [09:45:12] jsmith: Starting the database restore procedure            |
|  [09:45:30] bjones: Make sure to check replication status first        |
|  [09:45:45] jsmith: Good point, running SHOW SLAVE STATUS now          |
|  [09:46:10] mwilson: I see the lag is 45 seconds, that's within limits |
|  [09:46:25] jsmith: Proceeding with restore                            |
|                                                                         |
+------------------------------------------------------------------------+
|  Type message: [________________________________] [Send]               |
+------------------------------------------------------------------------+
```

**Chat API:**
```bash
# Send chat message
curl -X POST "https://bastion.example.com/api/v3.12/sessions/SES-2026-001-A7B3C9D1/chat" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Check the error log at /var/log/mysql/error.log"
  }'

# Get chat history
curl "https://bastion.example.com/api/v3.12/sessions/SES-2026-001-A7B3C9D1/chat" \
  -H "Authorization: Bearer $TOKEN"
```

### Annotations and Markers

```
+==============================================================================+
|                      SESSION ANNOTATIONS                                      |
+==============================================================================+
|                                                                               |
|  ANNOTATION TYPES                                                             |
|  ================                                                             |
|                                                                               |
|  +-------------------------------------------------------------------+       |
|  | Type           | Description                      | Example        |       |
|  +-------------------------------------------------------------------+       |
|  | Highlight      | Draw attention to screen area    | Circle, box    |       |
|  | Arrow          | Point to specific element        | Pointer arrow  |       |
|  | Text Note      | Add explanatory text             | "Click here"   |       |
|  | Timestamp Mark | Mark important moment            | Bookmark       |       |
|  | Warning        | Flag potential issue             | Red indicator  |       |
|  +-------------------------------------------------------------------+       |
|                                                                               |
|  ANNOTATION VISIBILITY                                                        |
|  =====================                                                        |
|                                                                               |
|  * Annotations visible to all current participants                            |
|  * Annotations saved in recording for playback                                |
|  * Annotations attributed to creator                                          |
|  * Optional: Annotations can be hidden from target output                     |
|                                                                               |
+==============================================================================+
```

**Annotation API:**
```bash
# Add screen annotation
curl -X POST "https://bastion.example.com/api/v3.12/sessions/SES-2026-001-A7B3C9D1/annotations" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "highlight",
    "coordinates": {
      "x": 100,
      "y": 200,
      "width": 300,
      "height": 50
    },
    "color": "#FF0000",
    "label": "Important configuration setting",
    "duration_seconds": 30
  }'

# Add timestamp bookmark
curl -X POST "https://bastion.example.com/api/v3.12/sessions/SES-2026-001-A7B3C9D1/bookmarks" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "label": "Database restore started",
    "category": "milestone",
    "notes": "Restore from backup dated 2026-01-14"
  }'
```

### Session Bookmarks

```json
{
    "session_bookmarks": [
        {
            "id": "BM-001",
            "timestamp": "2026-01-15T09:45:00Z",
            "offset_seconds": 900,
            "created_by": "jsmith",
            "label": "Issue identified",
            "category": "problem",
            "notes": "Found misconfigured replication setting"
        },
        {
            "id": "BM-002",
            "timestamp": "2026-01-15T10:15:00Z",
            "offset_seconds": 2700,
            "created_by": "bjones",
            "label": "Fix applied",
            "category": "resolution",
            "notes": "Changed server_id parameter"
        },
        {
            "id": "BM-003",
            "timestamp": "2026-01-15T10:30:00Z",
            "offset_seconds": 3600,
            "created_by": "jsmith",
            "label": "Verification complete",
            "category": "milestone",
            "notes": "Replication working correctly"
        }
    ]
}
```

---

## Training and Knowledge Transfer

### Mentor/Trainee Sessions

**Training Session Setup:**
```
+==============================================================================+
|                    TRAINING SESSION CONFIGURATION                             |
+==============================================================================+
|                                                                               |
|  TRAINING MODE FEATURES                                                       |
|  =====================                                                        |
|                                                                               |
|  +-------------------------------------------------------------------+       |
|  |  Feature              |  Mentor (Presenter)  |  Trainee (Viewer)  |       |
|  +-------------------------------------------------------------------+       |
|  |  Session control      |  Full control        |  View only*        |       |
|  |  Chat messaging       |  Yes                 |  Yes               |       |
|  |  Annotations          |  Create & view       |  View only         |       |
|  |  Ask questions        |  Respond             |  Submit            |       |
|  |  Request control      |  Grant/deny          |  Request           |       |
|  |  Pause session        |  Yes                 |  No                |       |
|  |  End session          |  Yes                 |  No                |       |
|  +-------------------------------------------------------------------+       |
|                                                                               |
|  * Trainee may be granted temporary control for practice                      |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  PRACTICE MODE                                                                |
|  =============                                                                |
|                                                                               |
|  When mentor transfers control to trainee:                                    |
|                                                                               |
|  * Mentor continues observing                                                 |
|  * Mentor can provide real-time guidance via chat                             |
|  * Mentor can reclaim control at any time                                     |
|  * All trainee actions are recorded and attributed                            |
|  * Optional: Mentor can enable "undo" capability                              |
|                                                                               |
+==============================================================================+
```

**Training Session Workflow:**
```bash
# 1. Mentor initiates training session
curl -X POST "https://bastion.example.com/api/v3.12/sessions" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "target": "root@training-server-01",
    "protocol": "SSH",
    "session_type": "training",
    "sharing": {
      "mode": "presenter",
      "auto_record": true,
      "training_options": {
        "allow_practice_mode": true,
        "enable_annotations": true,
        "enable_bookmarks": true
      }
    }
  }'

# 2. Invite trainee
curl -X POST "https://bastion.example.com/api/v3.12/sessions/SES-2026-001-TRAIN/invite" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "invitees": ["trainee_user"],
    "role": "trainee",
    "message": "Join for Linux administration training session"
  }'

# 3. Grant practice time to trainee
curl -X POST "https://bastion.example.com/api/v3.12/sessions/SES-2026-001-TRAIN/control/transfer" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "to_participant": "trainee_user",
    "practice_mode": true,
    "duration_minutes": 10,
    "mentor_can_intervene": true
  }'
```

### Recording Shared Sessions

**Enhanced Recording for Training:**
```json
{
    "recording_config": {
        "session_type": "training",
        "participants_recorded": true,
        "record_options": {
            "video": true,
            "keystrokes": true,
            "chat": true,
            "annotations": true,
            "bookmarks": true,
            "control_transfers": true,
            "participant_actions": true
        },
        "metadata": {
            "training_topic": "Linux System Administration",
            "mentor": "jsmith",
            "trainees": ["trainee_user"],
            "skill_level": "beginner"
        }
    }
}
```

**Recording Includes:**
- All screen activity with participant attribution
- Chat messages with timestamps
- Annotations and their creators
- Control transfers and durations
- Bookmarks for key learning moments
- Trainee practice session segments

### Post-Session Review

```
+==============================================================================+
|                       POST-SESSION REVIEW                                     |
+==============================================================================+
|                                                                               |
|  TRAINING SESSION REVIEW INTERFACE                                            |
|  =================================                                            |
|                                                                               |
|  Session: Training - Linux Admin Basics                                       |
|  Date: 2026-01-15 | Duration: 01:30:00                                       |
|  Mentor: jsmith | Trainee: trainee_user                                      |
|                                                                               |
|  +-------------------------------------------------------------------+       |
|  |  Playback Controls                                                 |       |
|  |  [|<<] [<<] [<] [>||] [>] [>>] [>>|]                              |       |
|  |                                                                   |       |
|  |  Timeline: [====*====================================] 00:45:30   |       |
|  |            ^    ^         ^              ^                         |       |
|  |            |    |         |              +- Practice session       |       |
|  |            |    |         +- Control transfer                      |       |
|  |            |    +- Bookmark: "Important concept"                   |       |
|  |            +- Session start                                        |       |
|  +-------------------------------------------------------------------+       |
|                                                                               |
|  BOOKMARKS AND ANNOTATIONS                                                    |
|  =========================                                                    |
|                                                                               |
|  [00:10:15] [jsmith] Bookmark: Introduction to file permissions              |
|  [00:25:30] [jsmith] Annotation: chmod command syntax                        |
|  [00:35:00] [jsmith] Control transferred to trainee_user                     |
|  [00:45:00] [jsmith] Bookmark: Practice session - good progress              |
|  [01:00:00] [trainee_user] Question: What about setuid?                      |
|  [01:05:00] [jsmith] Annotation: setuid explanation                          |
|                                                                               |
|  TRAINEE ASSESSMENT                                                          |
|  ==================                                                           |
|                                                                               |
|  [ ] Understands file permissions basics                                     |
|  [ ] Can use chmod correctly                                                 |
|  [ ] Understands ownership concepts                                          |
|  [ ] Needs more practice with advanced permissions                           |
|                                                                               |
|  Notes: [_________________________________________________________]          |
|                                                                               |
|  [Export Recording] [Generate Training Report] [Schedule Follow-up]          |
|                                                                               |
+==============================================================================+
```

---

## Incident Response Use Cases

### Emergency Collaboration

**Scenario:** Critical production issue requiring multiple experts

```
+==============================================================================+
|                    INCIDENT RESPONSE SHARING                                  |
+==============================================================================+
|                                                                               |
|  INCIDENT: Database cluster failing over repeatedly                           |
|  SEVERITY: P1 - Critical                                                      |
|  TIME SENSITIVITY: Immediate                                                  |
|                                                                               |
|  SHARING CONFIGURATION FOR INCIDENT RESPONSE                                  |
|  ============================================                                  |
|                                                                               |
|  {                                                                            |
|    "session_type": "incident_response",                                       |
|    "incident_id": "INC-2026-001-CRITICAL",                                    |
|    "sharing": {                                                               |
|      "mode": "interactive",                                                   |
|      "auto_approve_authorized": true,                                         |
|      "allowed_roles": ["incident_responder", "dba", "sysadmin"],              |
|      "max_participants": 10,                                                  |
|      "notifications": {                                                       |
|        "slack_channel": "#incident-response",                                 |
|        "pagerduty": true                                                      |
|      }                                                                        |
|    },                                                                         |
|    "recording": {                                                             |
|      "enabled": true,                                                         |
|      "legal_hold": true,                                                      |
|      "classification": "incident_evidence"                                    |
|    }                                                                          |
|  }                                                                            |
|                                                                               |
+==============================================================================+
```

**Incident Response Workflow:**
```bash
# 1. Incident commander initiates emergency session
curl -X POST "https://bastion.example.com/api/v3.12/sessions" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "target": "root@db-primary-01",
    "protocol": "SSH",
    "session_type": "incident_response",
    "incident_id": "INC-2026-001-CRITICAL",
    "sharing": {
      "mode": "interactive",
      "auto_approve": ["incident_responder"]
    }
  }'

# 2. Broadcast invitation to response team
curl -X POST "https://bastion.example.com/api/v3.12/sessions/SES-2026-001-INC/broadcast-invite" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "groups": ["incident-response-team", "dba-oncall"],
    "message": "P1 INCIDENT: DB cluster failover issue - immediate assistance needed",
    "priority": "critical"
  }'

# 3. Responders join directly (pre-authorized)
curl -X POST "https://bastion.example.com/api/v3.12/sessions/SES-2026-001-INC/join" \
  -H "Authorization: Bearer $RESPONDER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "role": "incident_responder"
  }'
```

### Expert Assistance

**Remote Expert Consultation:**
```
+==============================================================================+
|                      EXPERT ASSISTANCE WORKFLOW                               |
+==============================================================================+
|                                                                               |
|  SCENARIO: On-site technician needs remote DBA expert help                    |
|                                                                               |
|  Step 1: Technician initiates session                                         |
|  ----------------------------------------                                     |
|  * Connects to target system                                                  |
|  * Encounters complex issue                                                   |
|  * Requests expert assistance                                                 |
|                                                                               |
|  Step 2: Expert joins session                                                 |
|  ----------------------------                                                 |
|  * Receives notification of assistance request                                |
|  * Joins in presenter mode (view + guide)                                     |
|  * Observes current state                                                     |
|                                                                               |
|  Step 3: Collaborative troubleshooting                                        |
|  ------------------------------------                                         |
|  * Expert guides via chat/annotations                                         |
|  * Expert may take control for complex operations                             |
|  * Technician learns from expert actions                                      |
|                                                                               |
|  Step 4: Resolution and handback                                              |
|  --------------------------------                                             |
|  * Expert returns control to technician                                       |
|  * Technician verifies resolution                                             |
|  * Expert disconnects                                                         |
|  * Session continues or ends                                                  |
|                                                                               |
+==============================================================================+
```

### Escalation Procedures

```json
{
    "escalation_sharing_policy": {
        "levels": [
            {
                "level": 1,
                "trigger": "user_request",
                "sharing_mode": "view_only",
                "auto_invite": ["team_lead"],
                "approval_required": true
            },
            {
                "level": 2,
                "trigger": "team_lead_escalation",
                "sharing_mode": "presenter",
                "auto_invite": ["senior_admin", "subject_matter_expert"],
                "approval_required": false
            },
            {
                "level": 3,
                "trigger": "critical_incident",
                "sharing_mode": "interactive",
                "auto_invite": ["incident_commander", "all_oncall"],
                "approval_required": false,
                "notifications": ["pagerduty", "slack", "email"]
            }
        ],
        "automatic_escalation": {
            "enabled": true,
            "time_threshold_minutes": 30,
            "escalate_on_no_progress": true
        }
    }
}
```

---

## Security Controls

### Audit Trail for All Participants

```
+==============================================================================+
|                    PARTICIPANT AUDIT LOGGING                                  |
+==============================================================================+
|                                                                               |
|  AUDIT EVENTS CAPTURED                                                        |
|  =====================                                                        |
|                                                                               |
|  +-------------------------------------------------------------------+       |
|  | Event Type              | Details Logged                          |       |
|  +-------------------------------------------------------------------+       |
|  | PARTICIPANT_JOIN        | User, IP, time, mode, approval method   |       |
|  | PARTICIPANT_LEAVE       | User, time, reason (disconnect/kicked)  |       |
|  | CONTROL_TRANSFER        | From, to, reason, duration              |       |
|  | CONTROL_REQUEST         | Requester, reason, approved/denied      |       |
|  | CHAT_MESSAGE            | Sender, message, timestamp              |       |
|  | ANNOTATION_CREATED      | Creator, type, content, coordinates     |       |
|  | BOOKMARK_CREATED        | Creator, label, timestamp               |       |
|  | INPUT_SUBMITTED         | User, input type, content (if logged)   |       |
|  | PERMISSION_CHANGED      | User, old perms, new perms              |       |
|  | SHARING_SETTINGS_CHANGED| Modifier, old settings, new settings    |       |
|  +-------------------------------------------------------------------+       |
|                                                                               |
+==============================================================================+
```

**Audit Log Example:**
```json
{
    "session_id": "SES-2026-001-A7B3C9D1",
    "sharing_audit": [
        {
            "timestamp": "2026-01-15T09:30:15Z",
            "event": "SESSION_STARTED",
            "user": "jsmith",
            "details": {
                "sharing_enabled": true,
                "initial_mode": "presenter"
            }
        },
        {
            "timestamp": "2026-01-15T09:35:00Z",
            "event": "PARTICIPANT_JOIN",
            "user": "bjones",
            "details": {
                "mode": "viewer",
                "source_ip": "10.0.1.50",
                "approval_method": "invitation",
                "invitation_id": "INV-001"
            }
        },
        {
            "timestamp": "2026-01-15T09:40:00Z",
            "event": "CONTROL_TRANSFER",
            "user": "jsmith",
            "details": {
                "transferred_to": "bjones",
                "reason": "Practice session",
                "duration_minutes": 10
            }
        },
        {
            "timestamp": "2026-01-15T09:42:30Z",
            "event": "INPUT_SUBMITTED",
            "user": "bjones",
            "details": {
                "input_type": "command",
                "content_hash": "sha256:abc123..."
            }
        }
    ]
}
```

### Session Recording with Participants

**Enhanced Recording Metadata:**
```json
{
    "recording_metadata": {
        "session_id": "SES-2026-001-A7B3C9D1",
        "recording_file": "/var/wab/recorded/2026/01/15/SES-2026-001-A7B3C9D1.wab",
        "owner": "jsmith",
        "participants": [
            {
                "username": "jsmith",
                "role": "owner",
                "joined": "2026-01-15T09:30:15Z",
                "left": "2026-01-15T11:00:00Z",
                "mode": "presenter",
                "control_time_seconds": 4800
            },
            {
                "username": "bjones",
                "role": "participant",
                "joined": "2026-01-15T09:35:00Z",
                "left": "2026-01-15T10:45:00Z",
                "mode": "interactive",
                "control_time_seconds": 600
            },
            {
                "username": "auditor1",
                "role": "observer",
                "joined": "2026-01-15T09:40:00Z",
                "left": "2026-01-15T11:00:00Z",
                "mode": "view_only",
                "control_time_seconds": 0
            }
        ],
        "chat_messages_count": 45,
        "annotations_count": 12,
        "bookmarks_count": 5,
        "control_transfers_count": 3
    }
}
```

### Access Revocation During Session

```bash
# Remove participant from active session
curl -X DELETE "https://bastion.example.com/api/v3.12/sessions/SES-2026-001-A7B3C9D1/participants/bjones" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "reason": "No longer needed for troubleshooting",
    "block_rejoin": false
  }'

# Block specific user from joining
curl -X POST "https://bastion.example.com/api/v3.12/sessions/SES-2026-001-A7B3C9D1/block" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "suspicious_user",
    "reason": "Unauthorized join attempt"
  }'

# Disable all sharing for session
curl -X PUT "https://bastion.example.com/api/v3.12/sessions/SES-2026-001-A7B3C9D1/sharing" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "enabled": false,
    "disconnect_all_participants": true,
    "reason": "Security concern - ending collaboration"
  }'
```

**Revocation Events:**
```json
{
    "revocation_log": [
        {
            "timestamp": "2026-01-15T10:30:00Z",
            "action": "participant_removed",
            "target_user": "bjones",
            "by_user": "jsmith",
            "reason": "Session task completed",
            "force_disconnect": true
        },
        {
            "timestamp": "2026-01-15T10:35:00Z",
            "action": "sharing_disabled",
            "by_user": "jsmith",
            "affected_participants": ["mwilson", "auditor1"],
            "reason": "Moving to sensitive operations"
        }
    ]
}
```

---

## Configuration

### Enabling Session Sharing

**Global Configuration:**
```bash
# Enable session sharing globally
wabadmin config set session_sharing.enabled true

# Configure default sharing mode
wabadmin config set session_sharing.default_mode presenter

# Set maximum participants
wabadmin config set session_sharing.max_participants 10

# Verify configuration
wabadmin config get session_sharing
```

**Configuration File (`/etc/wallix/session_sharing.conf`):**
```ini
[session_sharing]
enabled = true
default_mode = presenter
max_participants = 10
require_owner_approval = true
notify_owner_on_join = true
notify_owner_on_leave = true

[modes]
view_only_enabled = true
interactive_enabled = true
presenter_enabled = true

[security]
require_mfa_for_sharing = true
encrypt_sharing_channel = true
log_all_participant_actions = true
record_shared_sessions = true

[notifications]
email_enabled = true
slack_enabled = false
teams_enabled = false

[timeouts]
invitation_expiry_minutes = 60
idle_participant_timeout_minutes = 30
control_transfer_timeout_minutes = 15
```

### Policy Configuration

**Authorization-Level Sharing Policy:**
```json
{
    "authorization_id": "linux-admin-prod",
    "sharing_policy": {
        "sharing_allowed": true,
        "allowed_modes": ["view_only", "presenter"],
        "restricted_modes": ["interactive"],
        "max_participants": 5,
        "allowed_invitees": {
            "type": "group_restricted",
            "allowed_groups": ["linux-admins", "security-team"]
        },
        "require_approval": true,
        "approval_timeout_minutes": 5,
        "recording_required": true,
        "four_eyes_required": false
    }
}
```

**Apply Policy via CLI:**
```bash
# Create sharing policy
wabadmin sharing-policy create \
  --name "production-sharing" \
  --modes "view_only,presenter" \
  --max-participants 5 \
  --require-approval true \
  --allowed-groups "linux-admins,security-team"

# Apply to authorization
wabadmin authorization modify linux-admin-prod \
  --sharing-policy "production-sharing"

# Apply to all authorizations in a domain
wabadmin authorization bulk-modify \
  --filter "domain=production" \
  --sharing-policy "production-sharing"
```

### Notification Settings

```json
{
    "sharing_notifications": {
        "channels": {
            "email": {
                "enabled": true,
                "templates": {
                    "invitation": "session_share_invitation.html",
                    "join_request": "session_join_request.html",
                    "participant_joined": "participant_joined.html"
                }
            },
            "slack": {
                "enabled": true,
                "webhook_url": "https://hooks.slack.com/services/xxx/yyy/zzz",
                "channel": "#pam-notifications"
            },
            "teams": {
                "enabled": false,
                "webhook_url": null
            },
            "in_app": {
                "enabled": true,
                "show_popup": true,
                "play_sound": true
            }
        },
        "triggers": {
            "on_invitation_sent": ["email", "in_app"],
            "on_invitation_accepted": ["in_app"],
            "on_join_request": ["email", "in_app", "slack"],
            "on_participant_join": ["in_app"],
            "on_participant_leave": ["in_app"],
            "on_control_transfer": ["in_app"],
            "on_session_ended": ["email"]
        },
        "preferences": {
            "respect_user_preferences": true,
            "quiet_hours_enabled": false,
            "batch_notifications": false
        }
    }
}
```

---

## Troubleshooting

### Connection Issues

```
+==============================================================================+
|                    SHARING CONNECTION TROUBLESHOOTING                         |
+==============================================================================+
|                                                                               |
|  ISSUE: Participant cannot join shared session                                |
|  ==============================================                               |
|                                                                               |
|  Diagnostic Steps:                                                            |
|                                                                               |
|  1. Verify session is still active:                                           |
|     $ wabadmin session show SES-2026-001-A7B3C9D1                             |
|                                                                               |
|  2. Check if sharing is enabled for session:                                  |
|     $ wabadmin session show SES-2026-001-A7B3C9D1 --sharing-status            |
|                                                                               |
|  3. Verify user has permission to join:                                       |
|     $ wabadmin user permissions bjones --check session_sharing                |
|                                                                               |
|  4. Check WebSocket connectivity:                                             |
|     $ curl -I https://bastion.example.com/ws/health                          |
|                                                                               |
|  5. Check firewall rules (port 443 WebSocket):                                |
|     $ netstat -tlnp | grep 443                                               |
|                                                                               |
|  Common Causes:                                                               |
|  * Session owner disabled sharing                                             |
|  * User not in allowed group                                                  |
|  * Invitation expired                                                         |
|  * Network/firewall blocking WebSocket                                        |
|  * Browser WebSocket support issue                                            |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  ISSUE: Shared session disconnects frequently                                 |
|  =============================================                                |
|                                                                               |
|  Diagnostic Steps:                                                            |
|                                                                               |
|  1. Check network stability:                                                  |
|     $ ping -c 100 bastion.example.com                                        |
|                                                                               |
|  2. Check WebSocket service:                                                  |
|     $ systemctl status wab-websocket                                         |
|     $ journalctl -u wab-websocket --since "10 minutes ago"                   |
|                                                                               |
|  3. Check session service load:                                               |
|     $ wabadmin service status session-sharing                                |
|                                                                               |
|  4. Check for timeout settings:                                               |
|     $ wabadmin config get session_sharing.timeouts                           |
|                                                                               |
|  Solutions:                                                                   |
|  * Increase idle timeout                                                      |
|  * Check proxy/load balancer WebSocket support                                |
|  * Verify TLS configuration                                                   |
|                                                                               |
+==============================================================================+
```

### Lag/Latency Problems

```bash
# Check sharing service latency
wabadmin sharing diagnostics --session SES-2026-001-A7B3C9D1

# Output:
# Sharing Diagnostics for SES-2026-001-A7B3C9D1
# =============================================
#
# Owner Connection:
#   Latency: 15ms (Good)
#   Bandwidth: 45 Mbps
#   Packet Loss: 0%
#
# Participants:
#   bjones:
#     Latency: 85ms (Fair)
#     Bandwidth: 12 Mbps
#     Packet Loss: 0.1%
#
#   mwilson:
#     Latency: 250ms (Poor)
#     Bandwidth: 5 Mbps
#     Packet Loss: 1.2%
#     Recommendation: Enable adaptive quality

# Enable adaptive quality for poor connections
wabadmin sharing configure --session SES-2026-001-A7B3C9D1 \
  --adaptive-quality true \
  --target-fps 15 \
  --compression high
```

**Performance Optimization:**
```json
{
    "performance_settings": {
        "adaptive_quality": {
            "enabled": true,
            "min_fps": 5,
            "max_fps": 30,
            "latency_threshold_ms": 150
        },
        "bandwidth_management": {
            "max_bandwidth_kbps": 5000,
            "throttle_slow_participants": true,
            "prioritize_presenter": true
        },
        "compression": {
            "level": "auto",
            "algorithm": "zstd"
        }
    }
}
```

### Permission Errors

```
+==============================================================================+
|                    PERMISSION ERROR TROUBLESHOOTING                           |
+==============================================================================+
|                                                                               |
|  ERROR: "User not authorized to join session"                                 |
|  ============================================                                  |
|                                                                               |
|  Check:                                                                       |
|  $ wabadmin user show bjones --permissions | grep sharing                    |
|  $ wabadmin authorization show linux-admin-prod --sharing-policy             |
|  $ wabadmin sharing-policy show production-sharing                           |
|                                                                               |
|  Resolution:                                                                  |
|  * Add user to allowed group                                                  |
|  * Update authorization sharing policy                                        |
|  * Grant session_sharing_participant permission                               |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  ERROR: "Cannot transfer control - user not permitted"                        |
|  ====================================================                         |
|                                                                               |
|  Check:                                                                       |
|  $ wabadmin session show SES-XXX --participant bjones --permissions          |
|                                                                               |
|  Resolution:                                                                  |
|  * Sharing mode may be view_only (change to presenter or interactive)        |
|  * User needs allow_control_request permission                                |
|  * Authorization restricts interactive mode                                   |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  ERROR: "Maximum participants reached"                                        |
|  =====================================                                        |
|                                                                               |
|  Check:                                                                       |
|  $ wabadmin session show SES-XXX --participants                              |
|  $ wabadmin config get session_sharing.max_participants                      |
|                                                                               |
|  Resolution:                                                                  |
|  * Remove inactive participants                                               |
|  * Increase max_participants limit (if policy allows)                         |
|  * Use broadcast mode instead of individual participants                      |
|                                                                               |
+==============================================================================+
```

### Diagnostic Commands Summary

| Issue | Diagnostic Command |
|-------|-------------------|
| Session not shareable | `wabadmin session show <id> --sharing-status` |
| User cannot join | `wabadmin user permissions <user> --check session_sharing` |
| Connection issues | `wabadmin sharing diagnostics --session <id>` |
| Permission denied | `wabadmin authorization show <auth> --sharing-policy` |
| Performance problems | `wabadmin sharing metrics --session <id>` |
| WebSocket issues | `systemctl status wab-websocket && journalctl -u wab-websocket` |

---

## Quick Reference

### CLI Commands

```bash
# Enable sharing on active session
wabadmin session share <session_id> --mode presenter

# Invite user to session
wabadmin session invite <session_id> --user bjones --mode viewer

# List session participants
wabadmin session participants <session_id>

# Transfer control
wabadmin session transfer-control <session_id> --to bjones

# Remove participant
wabadmin session kick <session_id> --user bjones

# Disable sharing
wabadmin session share <session_id> --disable

# View sharing audit log
wabadmin audit --session <session_id> --type sharing
```

### API Endpoints Reference

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v3.12/sessions/{id}/share` | POST | Enable sharing |
| `/api/v3.12/sessions/{id}/invite` | POST | Invite users |
| `/api/v3.12/sessions/{id}/join` | POST | Join session |
| `/api/v3.12/sessions/{id}/join-request` | POST | Request to join |
| `/api/v3.12/sessions/{id}/participants` | GET | List participants |
| `/api/v3.12/sessions/{id}/participants/{user}` | DELETE | Remove participant |
| `/api/v3.12/sessions/{id}/control/transfer` | POST | Transfer control |
| `/api/v3.12/sessions/{id}/control/request` | POST | Request control |
| `/api/v3.12/sessions/{id}/chat` | POST/GET | Send/get chat |
| `/api/v3.12/sessions/{id}/annotations` | POST | Add annotation |
| `/api/v3.12/sessions/{id}/bookmarks` | POST | Add bookmark |

---

## Related Documentation

- [Session Management](../09-session-management/README.md) - Core session features and recording
- [Session Recording Playback](../39-session-recording-playback/README.md) - Playback and search
- [Authorization](../07-authorization/README.md) - Access control policies
- [Incident Response](../23-incident-response/README.md) - Emergency procedures
- [API Reference](../17-api-reference/README.md) - Complete API documentation

---

## External References

- [WALLIX Documentation Portal](https://pam.wallix.one/documentation)
- [WALLIX Admin Guide](https://pam.wallix.one/documentation/admin-doc/bastion_en_administration_guide.pdf)
- [WALLIX REST API Samples](https://github.com/wallix/wbrest_samples)

---

## See Also

**Related Sections:**
- [09 - Session Management](../09-session-management/README.md) - Session recording and monitoring
- [07 - Authorization](../07-authorization/README.md) - Access control and approvals

**Official Resources:**
- [WALLIX Documentation](https://pam.wallix.one/documentation)

---

*Document Version: 1.0*
*Last Updated: February 2026*
*Applies to: WALLIX Bastion 12.x*
