# 08 - Session Management

## Table of Contents

1. [Session Management Overview](#session-management-overview)
2. [Session Recording](#session-recording)
3. [Real-Time Monitoring](#real-time-monitoring)
4. [Session Audit](#session-audit)
5. [Recording Playback](#recording-playback)
6. [Session Analytics](#session-analytics)
7. [Compliance Reporting](#compliance-reporting)

---

## Session Management Overview

### Session Lifecycle

```
+===============================================================================+
|                         SESSION LIFECYCLE                                     |
+===============================================================================+
|                                                                               |
|  +---------------------------------------------------------------------+      |
|  | 1. INITIATION                                                       |      |
|  |    -----------                                                      |      |
|  |    * User requests connection                                       |      |
|  |    * Authentication validated                                       |      |
|  |    * Authorization checked                                          |      |
|  +---------------------------------------------------------------------+      | 
|                                    |                                          |
|                                    v                                          |
|  +---------------------------------------------------------------------+      |
|  | 2. ESTABLISHMENT                                                    |      |
|  |    --------------                                                   |      |
|  |    * Credential retrieved from vault                                |      |
|  |    * Connection to target established                               |      |
|  |    * Recording initialized                                          |      |
|  |    * Session ID assigned                                            |      |
|  +---------------------------------------------------------------------+      |
|                                    |                                          |
|                                    v                                          |
|  +---------------------------------------------------------------------+      |
|  | 3. ACTIVE SESSION                                                   |      |
|  |    --------------                                                   |      |
|  |    * Data proxied between user and target                           |      |
|  |    * Real-time recording                                            |      |
|  |    * Monitoring and alerting active                                 |      |
|  |    * Keystroke/command logging                                      |      |
|  +---------------------------------------------------------------------+      |
|                                    |                                          |
|                                    v                                          |
|  +---------------------------------------------------------------------+      |
|  | 4. TERMINATION                                                      |      |
|  |    -----------                                                      |      |
|  |    * User disconnects OR timeout OR admin kill                      |      |
|  |    * Recording finalized                                            |      |
|  |    * Session metadata saved                                         |      |
|  |    * Post-session actions (rotation if configured)                  |      |
|  +---------------------------------------------------------------------+      |
|                                    |                                          |
|                                    v                                          |
|  +---------------------------------------------------------------------+      |
|  | 5. POST-PROCESSING                                                  |      |
|  |    ---------------                                                  |      |
|  |    * OCR processing (RDP sessions)                                  |      |
|  |    * Index creation for search                                      |      |
|  |    * Archive management                                             |      |
|  +---------------------------------------------------------------------+      |
|                                                                               |
+===============================================================================+
```

### CyberArk Comparison

> **CyberArk Equivalent: PSM (Privileged Session Manager) + PTA (Privileged Threat Analytics)**

| Feature | CyberArk | WALLIX |
|---------|----------|--------|
| Session Recording | PSM recordings | Session Manager recordings |
| Real-time Monitoring | PSM for Windows/Web | Native in Session Manager |
| Session Analytics | PTA (separate product) | Built-in analytics |
| OCR Indexing | Available | Native OCR processing |
| Session Kill | PSM console | Real-time session control |
| Audit Trail | Integrated in Vault | Separate audit module |

**Key Differences:**
- WALLIX integrates session analytics natively, while CyberArk requires separate PTA license
- WALLIX provides unified session management across all protocols in single interface
- Recording storage in WALLIX is file-based (NAS/SAN), while CyberArk uses Vault storage

---

## Session Recording

### Recording Architecture

```
+===============================================================================+
|                       RECORDING ARCHITECTURE                                  |
+===============================================================================+
|                                                                               |
|                          +---------------------+                              |
|                          |    ACTIVE SESSION   |                              |
|                          |                     |                              |
|                          |  User <---> Target  |                              |
|                          +----------+----------+                              |
|                                     |                                         |
|                    +----------------+----------------+                        |
|                    |                |                |                        |
|                    v                v                v                        |
|           +--------------+ +--------------+ +--------------+                  |
|           |   SCREEN     | |  KEYSTROKE   | |  METADATA    |                  |
|           |   CAPTURE    | |   LOGGER     | |  COLLECTOR   |                  |
|           |              | |              | |              |                  |
|           | * Video      | | * Input      | | * Timestamps |                  |
|           | * Frames     | | * Commands   | | * Actions    |                  |
|           | * Delta enc  | | * Clipboard  | | * Events     |                  |
|           +------+-------+ +------+-------+ +------+-------+                  |
|                  |                |                |                          |
|                  +----------------+----------------+                          |
|                                   |                                           |
|                                   v                                           |
|                  +------------------------------------+                       |
|                  |        RECORDING FILE              |                       |
|                  |        (.wab format)               |                       |
|                  |                                    |                       |
|                  |  +------------------------------+  |                       |
|                  |  | Header: Session metadata     |  |                       |
|                  |  +------------------------------+  |                       |
|                  |  | Video: Compressed frames     |  |                       |
|                  |  +------------------------------+  |                       |
|                  |  | Input: Keystroke log         |  |                       |
|                  |  +------------------------------+  |                       |
|                  |  | Events: Timeline markers     |  |                       |
|                  |  +------------------------------+  |                       |
|                  +------------------------------------+                       |
|                                                                               |
+===============================================================================+
```

### Recording by Protocol

```
+===============================================================================+
|                    RECORDING CAPABILITIES BY PROTOCOL                         |
+===============================================================================+
|                                                                               |
|  +----------+----------+----------+----------+----------+------------------+  |
|  | Feature  |   SSH    |   RDP    |   VNC    |  HTTPS   |     TELNET       |  |
|  +----------+----------+----------+----------+----------+------------------+  |
|  | Video    |    -     |    Y     |    Y     | Snapshot |       -          |  |
|  | Screen   |   Text   |  Full    |  Full    |  Page    |      Text        |  |
|  | Keystroke|    Y     |    Y     |    Y     |    Y     |       Y          |  |
|  | Commands |    Y     |    -     |    -     |    -     |       Y          |  |
|  | OCR      |    -     |    Y     |    Y     |    -     |       -          |  |
|  | Searchabl|    Y     | via OCR  | via OCR  |    Y     |       Y          |  |
|  | File Size|  Small   |  Large   |  Medium  |  Small   |     Small        |  |
|  +----------+----------+----------+----------+----------+------------------+  |
|                                                                               |
|  TYPICAL FILE SIZES (per hour)                                                |
|  -----------------------------                                                |
|                                                                               |
|  SSH:     1-5 MB/hour     (text-based, highly compressible)                   |
|  RDP:     50-200 MB/hour  (video, depends on activity)                        |
|  VNC:     20-100 MB/hour  (video, depends on activity)                        |
|  HTTPS:   5-20 MB/hour    (screenshots + requests)                            |
|  Telnet:  1-3 MB/hour     (text-based)                                        |
|                                                                               |
+===============================================================================+
```

### Recording Storage

```
+===============================================================================+
|                        RECORDING STORAGE                                      |
+===============================================================================+
|                                                                               |
|  DEFAULT STORAGE STRUCTURE                                                    |
|  =========================                                                    |
|                                                                               |
|  /var/wab/recorded/                                                           |
|  |                                                                            |
|  +-- 2024/                                                                    |
|  |   +-- 01/                                                                  |
|  |   |   +-- 15/                                                              |
|  |   |   |   +-- session_abc123.wab           # Recording file                |
|  |   |   |   +-- session_abc123.wab.meta      # Metadata                      |
|  |   |   |   +-- session_abc123.wab.idx       # Search index                  |
|  |   |   |   +-- session_abc123.wab.ocr       # OCR data (RDP)                |
|  |   |   +-- 16/                                                              |
|  |   |       +-- ...                                                          |
|  |   +-- 02/                                                                  |
|  |       +-- ...                                                              |
|  +-- 2025/                                                                    |
|      +-- ...                                                                  |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  EXTERNAL STORAGE OPTIONS                                                     |
|  ========================                                                     |
|                                                                               |
|  +-----------------+---------------------------------------------------+      |
|  | Storage Type    | Configuration                                      |     |
|  +-----------------+---------------------------------------------------+      |
|  | NFS Mount       | Mount point: /var/wab/recorded                     |     |
|  |                 | NFS server: nas.company.com:/wallix/recordings     |     |
|  +-----------------+---------------------------------------------------+      |
|  | iSCSI           | Target: iqn.2024-01.com.company:wallix-recordings  |     |
|  |                 | LUN formatted with XFS/ext4                        |     |
|  +-----------------+---------------------------------------------------+      |
|  | S3/Object       | Bucket: wallix-recordings                          |     |
|  | (archival)      | Lifecycle: Move to Glacier after 90 days           |     |
|  +-----------------+---------------------------------------------------+      |
|                                                                               |
+===============================================================================+
```

### Retention Policies

```json
{
    "retention_policy": {
        "name": "standard-retention",

        "active_storage": {
            "max_age_days": 90,
            "max_size_gb": 500
        },

        "archive": {
            "enabled": true,
            "after_days": 30,
            "destination": "cold-storage",
            "compress": true
        },

        "deletion": {
            "after_days": 365,
            "require_approval": true,
            "exceptions": ["compliance-hold"]
        }
    }
}
```

---

## Real-Time Monitoring

### Monitoring Dashboard

```
+===============================================================================+
|                      ACTIVE SESSIONS DASHBOARD                                |
+===============================================================================+
|                                                                               |
|  ACTIVE SESSIONS: 12                      RECORDING: 12/12 (100%)             |
|                                                                               |
|  +------------------------------------------------------------------------+   |
|  | ID       | User     | Target           | Protocol | Duration | Status  |   |
|  +----------+----------+------------------+----------+----------+---------+   |
|  | SES-001  | jsmith   | root@srv-prod-01 | SSH      | 00:45:12 | * REC   |   |
|  | SES-002  | bjones   | Admin@dc01       | RDP      | 01:23:45 | * REC   |   |
|  | SES-003  | mwilson  | oracle@db-prod   | SSH      | 00:12:30 | * REC   |   |
|  | SES-004  | rjohnson | root@srv-web-01  | SSH      | 02:15:00 | ! CRIT  |   |
|  | SES-005  | klee     | admin@fw-main    | SSH      | 00:05:22 | * REC   |   |
|  +----------+----------+------------------+----------+----------+---------+   |
|                                                                               |
|  ACTIONS:  [View]  [Share]  [Message]  [Kill]  [Details]                      |
|                                                                               |
+===============================================================================+
```

### Monitoring Actions

```
+===============================================================================+
|                       MONITORING ACTIONS                                      |
+===============================================================================+
|                                                                               |
|  VIEW (Shadow Mode)                                                           |
|  ==================                                                           |
|                                                                               |
|  * Watch session in real-time                                                 |
|  * Read-only observation                                                      |
|  * User is NOT notified (configurable)                                        |
|  * Multiple viewers supported                                                 |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  SHARE (4-Eyes / Dual Control)                                                |
|  =============================                                                |
|                                                                               |
|  * Join session interactively                                                 |
|  * Both users see same screen                                                 |
|  * Both can interact (configurable)                                           |
|  * User IS notified of observer                                               |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  MESSAGE                                                                      |
|  =======                                                                      |
|                                                                               |
|  * Send text message to session user                                          |
|  * Displayed in session window                                                |
|  * Logged in session recording                                                |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  KILL                                                                         |
|  ====                                                                         |
|                                                                               |
|  * Immediately terminate session                                              |
|  * User disconnected from target                                              |
|  * Reason logged in audit                                                     |
|  * Requires confirmation                                                      |
|                                                                               |
+===============================================================================+
```

### Session Alerts

```
+===============================================================================+
|                        SESSION ALERTING                                       |
+===============================================================================+
|                                                                               |
|  ALERT TYPES                                                                  |
|  ===========                                                                  |
|                                                                               |
|  +--------------------+----------------------------------------------------+  |
|  | Alert Type         | Description                                        |  |
|  +--------------------+----------------------------------------------------+  |
|  | Command Pattern    | Detect specific commands (rm -rf, drop table)      |  |
|  | Keyword Detection  | Sensitive words in session                         |  |
|  | Duration Exceeded  | Session exceeds time limit                         |  |
|  | Unusual Activity   | Abnormal patterns detected                         |  |
|  | File Transfer      | Large file transfers                               |  |
|  | Critical Target    | Access to critical systems                         |  |
|  +--------------------+----------------------------------------------------+  | 
|                                                                               |
|  ALERT CONFIGURATION EXAMPLE                                                  |
|  ===========================                                                  |
|                                                                               |
|  {                                                                            |
|      "alert_name": "dangerous-commands",                                      |
|      "protocol": "SSH",                                                       |
|      "patterns": [                                                            |
|          "rm -rf /",                                                          |
|          "dd if=/dev/zero",                                                   |
|          "mkfs",                                                              |
|          "> /dev/sda"                                                         |
|      ],                                                                       |
|      "actions": [                                                             |
|          {"type": "email", "recipients": ["security@company.com"]},           |
|          {"type": "syslog", "severity": "critical"},                          |
|          {"type": "kill_session", "require_confirmation": true}               |
|      ]                                                                        |
|  }                                                                            |
|                                                                               |
+===============================================================================+
```

---

## Session Audit

### Audit Log Contents

```
+===============================================================================+
|                         SESSION AUDIT DATA                                    |
+===============================================================================+
|                                                                               |
|  SESSION METADATA                                                             |
|  ================                                                             |
|                                                                               |
|  +-----------------------------------------------------------------------+    |
|  | Session ID:        SES-2024-001-ABC123                                |    |
|  | Start Time:        2024-01-15 09:30:15 UTC                            |    |
|  | End Time:          2024-01-15 10:45:22 UTC                            |    |
|  | Duration:          01:15:07                                           |    |
|  |                                                                       |    |
|  | User:              jsmith                                             |    |
|  | User IP:           10.0.1.50                                          |    |
|  | User Agent:        PuTTY/0.78                                         |    |
|  |                                                                       |    |
|  | Target:            srv-prod-01                                        |    |
|  | Target Account:    root                                               |    |
|  | Protocol:          SSH                                                |    | 
|  | Target IP:         192.168.1.100                                      |    |
|  |                                                                       |    |
|  | Authorization:     linux-admins-to-prod                               |    |
|  | Recording File:    /var/wab/recorded/2024/01/15/SES-2024-001-ABC123   |    |
|  | Recording Size:    2.3 MB                                             |    |
|  |                                                                       |    |
|  | Termination:       User disconnect                                    |    |
|  +-----------------------------------------------------------------------+    | 
|                                                                               |
|  SESSION EVENTS                                                               |
|  ==============                                                               |
|                                                                               |
|  +-----------------------------------------------------------------------+    |
|  | Timestamp              | Event Type     | Details                     |    |
|  +------------------------+----------------+-----------------------------+    |
|  | 2024-01-15 09:30:15    | SESSION_START  | Connection initiated        |    |
|  | 2024-01-15 09:30:16    | AUTH_SUCCESS   | User authenticated          |    |
|  | 2024-01-15 09:30:17    | AUTH_TARGET    | Target auth successful      |    |
|  | 2024-01-15 09:30:18    | RECORDING_START| Recording initiated         |    |
|  | 2024-01-15 09:35:22    | COMMAND        | cd /var/log                 |    |
|  | 2024-01-15 09:35:45    | COMMAND        | tail -f syslog              |    |
|  | 2024-01-15 10:45:20    | COMMAND        | exit                        |    |
|  | 2024-01-15 10:45:22    | SESSION_END    | User disconnected           |    |
|  +-----------------------------------------------------------------------+    |
|                                                                               |
+===============================================================================+
```

### SIEM Integration

```
+===============================================================================+
|                         SIEM INTEGRATION                                      |
+===============================================================================+
|                                                                               |
|  SUPPORTED FORMATS                                                            |
|  =================                                                            |
|                                                                               |
|  +-----------------+---------------------------------------------------+      |
|  | Format          | Description                                        |     | 
|  +-----------------+---------------------------------------------------+      |
|  | Syslog (RFC5424)| Standard syslog format                             |     |
|  | CEF             | ArcSight Common Event Format                       |     |
|  | LEEF            | QRadar Log Event Extended Format                   |     |
|  | JSON            | Structured JSON for Splunk/ELK                     |     |
|  +-----------------+---------------------------------------------------+      |
|                                                                               |
|  SAMPLE CEF OUTPUT                                                            |
|  =================                                                            |
|                                                                               |
|  CEF:0|WALLIX|Bastion|12.1|100|Session Started|5|                             |
|  src=10.0.1.50 suser=jsmith dhost=srv-prod-01                                 |
|  duser=root proto=SSH sessionId=SES-2024-001-ABC123                           |
|  rt=Jan 15 2024 09:30:15                                                      |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  CONFIGURATION                                                                |
|  =============                                                                |
|                                                                               |
|  {                                                                            |
|      "siem_integration": {                                                    |
|          "enabled": true,                                                     |
|          "protocol": "syslog",                                                |
|          "format": "CEF",                                                     |
|          "servers": [                                                         |
|              {"host": "siem.company.com", "port": 514, "protocol": "udp"},    |
|              {"host": "siem-backup.company.com", "port": 6514, "protocol": "tls"}|
|          ],                                                                   |
|          "events": [                                                          |
|              "session_start", "session_end",                                  |
|              "auth_success", "auth_failure",                                  |
|              "command_critical", "policy_violation"                           |
|          ]                                                                    |
|      }                                                                        |
|  }                                                                            |
|                                                                               |
+===============================================================================+
```

---

## Recording Playback

### Playback Interface

```
+===============================================================================+
|                       RECORDING PLAYBACK                                      |
+===============================================================================+
|                                                                               |
|  +------------------------------------------------------------------------+   |
|  |                                                                        |   |
|  |                     SESSION PLAYBACK VIEWER                            |   |
|  |                                                                        |   |
|  |  +-------------------------------------------------------------------+ |   |
|  |  |                                                                   | |   |
|  |  |                                                                   | |   |
|  |  |                   [Session Video/Terminal]                        | |   |
|  |  |                                                                   | |   |
|  |  |                                                                   | |   |
|  |  |                                                                   | |   |
|  |  +-------------------------------------------------------------------+ |   |
|  |                                                                        |   |
|  |  <<  <  >  >>   |   ||    M   []   ?                                   |   |
|  |                                                                        |   |
|  |  --*--------------------------------------------------  00:45:12       |   |
|  |  00:00                                                       01:15:07  |   |
|  |                                                                        |   |
|  |  Speed: [1x v]    [Jump to event v]    [Search: ________]              |   |
|  |                                                                        |   |
|  +------------------------------------------------------------------------+   |
|                                                                               |
|  PLAYBACK FEATURES                                                            |
|  =================                                                            |
|                                                                               |
|  * Variable speed playback (0.5x to 8x)                                       |
|  * Jump to specific timestamp                                                 |
|  * Jump to events (commands, alerts)                                          |
|  * Full-text search (SSH) or OCR search (RDP)                                 |
|  * Export clips                                                               |
|  * Generate screenshots                                                       |
|                                                                               |
+===============================================================================+
```

### Search Capabilities

```
+===============================================================================+
|                      RECORDING SEARCH                                         |
+===============================================================================+
|                                                                               |
|  SSH SESSION SEARCH (Native Text)                                             |
|  =================================                                            |
|                                                                               |
|  Search: [password________]  [Search]                                         |
|                                                                               |
|  Results:                                                                     |
|  +------------------------------------------------------------------------+   |
|  | 00:15:22  | sudo passwd user1                                          |   |
|  | 00:23:45  | cat /etc/passwd                                            |   |
|  | 00:45:12  | grep password /var/log/auth.log                            |   |
|  +------------------------------------------------------------------------+   |
|                                                                               |
|  [Click timestamp to jump to location in recording]                           |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  RDP SESSION SEARCH (OCR)                                                     |
|  ========================                                                     |
|                                                                               |
|  Search: [credit card____]  [Search]                                          |
|                                                                               |
|  Results:                                                                     |
|  +------------------------------------------------------------------------+   |
|  | 00:12:33  | [Screenshot] "Credit Card Processing" window opened        |   |
|  | 00:14:22  | [Screenshot] Excel: "Credit Card Numbers.xlsx"             |   |
|  | 00:18:45  | [Screenshot] Notepad: Contains "credit card"               |   |
|  +------------------------------------------------------------------------+   |
|                                                                               |
|  OCR Accuracy: ~95% for standard fonts                                        |
|  Note: OCR processing happens post-session                                    |
|                                                                               |
+===============================================================================+
```

---

## Session Analytics

### Analytics Dashboard

```
+===============================================================================+
|                      SESSION ANALYTICS                                        |
+===============================================================================+
|                                                                               |
|  PERIOD: Last 30 Days                                                         |
|                                                                               |
|  +----------------------------------------------------------------------+     |
|  |  TOTAL SESSIONS          UNIQUE USERS         UNIQUE TARGETS         |     |
|  |                                                                      |     |
|  |      12,456                  234                  567                |     |
|  |      ^ 15%                  ^ 8%                 ^ 12%               |     |
|  +----------------------------------------------------------------------+     |
|                                                                               |
|  SESSIONS BY PROTOCOL                    SESSIONS BY TIME OF DAY              |
|  ====================                    ========================             |
|                                                                               |
|  +---------------------+                 +---------------------+              |
|  | SSH     ======== 65%|                 |       -------                      |
|  | RDP     ====    28% |                 |    ---========---                  |
|  | VNC     =        5% |                 |  --===============--               |
|  | Other   .        2% |                 | ======================             |
|  +---------------------+                 | 00  04  08  12  16  20  24         |
|                                          +---------------------+              |
|                                                                               |
|  TOP USERS (by session count)            TOP TARGETS (by session count)       |
|  ============================            ===============================      |
|                                                                               |
|  1. jsmith      - 1,234 sessions         1. srv-prod-01    - 890 sessions     |
|  2. bjones      - 1,122 sessions         2. db-oracle-prd  - 756 sessions     |
|  3. mwilson     -   987 sessions         3. dc01.corp      - 654 sessions     |
|  4. rjohnson    -   876 sessions         4. fw-perimeter   - 543 sessions     |
|  5. klee        -   765 sessions         5. srv-web-01     - 432 sessions     |
|                                                                               |
+===============================================================================+
```

---

## Compliance Reporting

### Standard Reports

```
+===============================================================================+
|                      COMPLIANCE REPORTS                                       |
+===============================================================================+
|                                                                               |
|  AVAILABLE REPORTS                                                            |
|  =================                                                            |
|                                                                               |
|  +----------------------------+--------------------------+-----------------+  |
|  | Report Name                | Description              | Frequency       |  |
|  +----------------------------+--------------------------+-----------------+  |
|  | Session Summary            | Overview of all sessions | Daily/Weekly    |  |
|  | User Activity              | Sessions per user        | Weekly/Monthly  |  |
|  | Target Access              | Access by target system  | Weekly/Monthly  |  |
|  | Failed Authentications     | Auth failures            | Daily           |  |
|  | Policy Violations          | Authorization denials    | Daily           |  |
|  | Critical Session Review    | Critical access audit    | Daily           |  | 
|  | Password Rotation Status   | Rotation success/failure | Weekly          |  | 
|  | Recording Integrity        | Recording verification   | Monthly         |  |
|  | Compliance Attestation     | Full audit report        | Quarterly       |  |
|  +----------------------------+--------------------------+-----------------+  |
|                                                                               |
|  REPORT FORMATS                                                               |
|  ==============                                                               |
|                                                                               |
|  * PDF   - Formatted for printing/archival                                    |
|  * CSV   - For data analysis/spreadsheets                                     |
|  * HTML  - Interactive web viewing                                            |
|  * JSON  - API/integration consumption                                        |
|                                                                               |
|  SCHEDULED DELIVERY                                                           |
|  ==================                                                           |
|                                                                               |
|  * Email to stakeholders                                                      |
|  * SFTP to secure location                                                    |
|  * API push to GRC platform                                                   |
|                                                                               |
+===============================================================================+
```

---

## Next Steps

Continue to [09 - API & Automation](../10-api-automation/README.md) for REST API and integration details.
