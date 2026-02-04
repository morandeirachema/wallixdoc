# Session Recording Playback and Search Guide

Comprehensive guide for accessing, searching, analyzing, and managing WALLIX Bastion session recordings for audit, forensics, and compliance purposes.

---

## Table of Contents

1. [Recording Overview](#recording-overview)
2. [Playback Architecture](#playback-architecture)
3. [Web Player Usage](#web-player-usage)
4. [OCR Search](#ocr-search)
5. [Text Search in SSH Sessions](#text-search-in-ssh-sessions)
6. [Metadata Search](#metadata-search)
7. [Recording Export](#recording-export)
8. [Forensic Analysis](#forensic-analysis)
9. [Recording Sharing](#recording-sharing)
10. [Bulk Export](#bulk-export)
11. [Recording Integrity](#recording-integrity)
12. [Storage Management](#storage-management)
13. [Troubleshooting](#troubleshooting)

---

## Recording Overview

### Recording Formats and Types

WALLIX Bastion captures privileged sessions in proprietary `.wab` format, optimized for security, compression, and searchability.

```
+==============================================================================+
|                        SESSION RECORDING COMPONENTS                           |
+==============================================================================+
|                                                                               |
|  RECORDING FILE STRUCTURE (.wab format)                                       |
|  ======================================                                       |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |                        RECORDING HEADER                               |   |
|  |-----------------------------------------------------------------------|   |
|  | Session ID     | SES-2026-001-A7B3C9D1                               |   |
|  | Start Time     | 2026-01-15T09:30:15Z                                |   |
|  | End Time       | 2026-01-15T10:45:22Z                                |   |
|  | Protocol       | SSH / RDP / VNC / HTTP / Telnet                     |   |
|  | User           | jsmith (John Smith)                                 |   |
|  | Target         | root@srv-prod-01 (192.168.1.100)                    |   |
|  | Authorization  | linux-admins-to-production                          |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |                        VIDEO/SCREEN DATA                              |   |
|  |-----------------------------------------------------------------------|   |
|  | Compression    | Delta-encoded frames (RDP/VNC)                      |   |
|  |                | Text stream (SSH/Telnet)                            |   |
|  | Resolution     | Native capture (RDP: up to 4K)                      |   |
|  | Frame Rate     | Adaptive (1-30 fps based on activity)               |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |                        INPUT DATA                                     |   |
|  |-----------------------------------------------------------------------|   |
|  | Keystrokes     | Full keyboard input with timestamps                 |   |
|  | Mouse Events   | Clicks, movements (RDP/VNC)                         |   |
|  | Clipboard      | Copy/paste operations (if enabled)                  |   |
|  | Commands       | Parsed command lines (SSH/Telnet)                   |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |                        METADATA/INDEX                                 |   |
|  |-----------------------------------------------------------------------|   |
|  | Event Timeline | Timestamped markers for navigation                  |   |
|  | OCR Index      | Searchable text from screen (RDP/VNC)               |   |
|  | Command Index  | Searchable commands (SSH/Telnet)                    |   |
|  | Hash/Signature | SHA-256 integrity verification                      |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
+==============================================================================+
```

### Recording Capabilities by Protocol

| Protocol | Screen Capture | Keystrokes | Commands | OCR Search | File Size/Hour |
|----------|----------------|------------|----------|------------|----------------|
| SSH | Text stream | Yes | Yes (parsed) | N/A | 1-5 MB |
| RDP | Full video | Yes | Via OCR | Yes | 50-200 MB |
| VNC | Full video | Yes | Via OCR | Yes | 20-100 MB |
| HTTP/S | Screenshots | Yes | N/A | Yes | 5-20 MB |
| Telnet | Text stream | Yes | Yes (parsed) | N/A | 1-3 MB |

### Storage Structure

```
/var/wab/recorded/
|
+-- 2026/
|   +-- 01/
|   |   +-- 15/
|   |   |   +-- SES-2026-001-A7B3C9D1.wab          # Recording file
|   |   |   +-- SES-2026-001-A7B3C9D1.wab.meta     # Metadata JSON
|   |   |   +-- SES-2026-001-A7B3C9D1.wab.idx      # Search index
|   |   |   +-- SES-2026-001-A7B3C9D1.wab.ocr      # OCR data (RDP/VNC)
|   |   |   +-- SES-2026-001-A7B3C9D1.wab.sig      # Digital signature
|   |   +-- 16/
|   |       +-- ...
|   +-- 02/
|       +-- ...
+-- archive/                                        # Compressed archives
|   +-- 2025-Q4.tar.gz
|   +-- 2025-Q3.tar.gz
+-- staging/                                        # Active recordings
    +-- SES-2026-001-CURRENT.wab.tmp
```

### Retention Policies

```json
{
    "retention_policy": {
        "name": "enterprise-standard",
        "description": "Standard retention for compliance",

        "online_storage": {
            "duration_days": 90,
            "max_size_tb": 2,
            "location": "/var/wab/recorded"
        },

        "archive_tier": {
            "enabled": true,
            "trigger_age_days": 30,
            "compression": "gzip",
            "destination": "/var/wab/recorded/archive"
        },

        "cold_storage": {
            "enabled": true,
            "trigger_age_days": 180,
            "destination": "s3://wallix-archive-bucket/recordings",
            "storage_class": "GLACIER"
        },

        "deletion": {
            "enabled": true,
            "after_days": 730,
            "require_approval": true,
            "legal_hold_exempt": true,
            "compliance_check": true
        },

        "exceptions": {
            "security_incidents": {
                "retention_days": 2555,
                "auto_archive": false
            },
            "compliance_hold": {
                "retention_days": -1,
                "deletion_blocked": true
            }
        }
    }
}
```

---

## Playback Architecture

### System Components

```
+==============================================================================+
|                       PLAYBACK ARCHITECTURE                                   |
+==============================================================================+
|                                                                               |
|  USER BROWSER                         WALLIX BASTION                          |
|  ============                         ==============                          |
|                                                                               |
|  +------------------+                 +----------------------------------+    |
|  |                  |    HTTPS/443    |                                  |    |
|  |  Web Player      |<--------------->|  Session Playback Service        |    |
|  |  (JavaScript)    |                 |  /api/sessions/{id}/playback     |    |
|  |                  |                 |                                  |    |
|  |  +------------+  |                 |  +----------------------------+  |    |
|  |  | Video      |  |                 |  | Recording Decoder          |  |    |
|  |  | Renderer   |  |                 |  | (.wab to streaming format) |  |    |
|  |  +------------+  |                 |  +----------------------------+  |    |
|  |                  |                 |               |                  |    |
|  |  +------------+  |                 |               v                  |    |
|  |  | Timeline   |  |                 |  +----------------------------+  |    |
|  |  | Controller |  |                 |  | Index Server               |  |    |
|  |  +------------+  |                 |  | (OCR, commands, events)    |  |    |
|  |                  |                 |  +----------------------------+  |    |
|  |  +------------+  |                 |               |                  |    |
|  |  | Search     |  |                 |               v                  |    |
|  |  | Interface  |  |                 |  +----------------------------+  |    |
|  |  +------------+  |                 |  | Storage Backend            |  |    |
|  |                  |                 |  | (Local/NAS/S3)             |  |    |
|  +------------------+                 |  +----------------------------+  |    |
|                                       |                                  |    |
|                                       +----------------------------------+    |
|                                                                               |
|  DATA FLOW                                                                    |
|  =========                                                                    |
|                                                                               |
|  1. User requests session playback via web UI                                 |
|  2. Playback service validates user permissions                               |
|  3. Recording file retrieved from storage                                     |
|  4. Decoder converts .wab to streaming format                                 |
|  5. Video/text streamed to browser player                                     |
|  6. Index data enables search and navigation                                  |
|  7. All playback actions logged to audit trail                                |
|                                                                               |
+==============================================================================+
```

### Playback Permissions Model

```
+==============================================================================+
|                     PLAYBACK PERMISSION HIERARCHY                             |
+==============================================================================+
|                                                                               |
|  ROLE-BASED ACCESS TO RECORDINGS                                              |
|  ================================                                             |
|                                                                               |
|  +-------------------------------------------------------------------+       |
|  |  AUDITOR Role                                                      |       |
|  |-------------------------------------------------------------------|       |
|  |  * View all session recordings                                     |       |
|  |  * Search across all sessions                                      |       |
|  |  * Export recordings (with approval)                               |       |
|  |  * Generate compliance reports                                     |       |
|  |  * View keystroke logs                                             |       |
|  |  * Access OCR search results                                       |       |
|  +-------------------------------------------------------------------+       |
|                                                                               |
|  +-------------------------------------------------------------------+       |
|  |  SECURITY_OFFICER Role                                             |       |
|  |-------------------------------------------------------------------|       |
|  |  * All Auditor permissions PLUS:                                   |       |
|  |  * Export without approval                                         |       |
|  |  * Place legal hold on recordings                                  |       |
|  |  * Access incident-tagged sessions                                 |       |
|  |  * Share recordings with external parties                          |       |
|  |  * Verify recording integrity                                      |       |
|  +-------------------------------------------------------------------+       |
|                                                                               |
|  +-------------------------------------------------------------------+       |
|  |  MANAGER Role (Limited)                                            |       |
|  |-------------------------------------------------------------------|       |
|  |  * View recordings for users in managed groups                     |       |
|  |  * View recordings for targets in managed domains                  |       |
|  |  * Cannot export or share                                          |       |
|  |  * Cannot view keystroke details                                   |       |
|  +-------------------------------------------------------------------+       |
|                                                                               |
|  +-------------------------------------------------------------------+       |
|  |  USER Role (Self-Service)                                          |       |
|  |-------------------------------------------------------------------|       |
|  |  * View own session recordings only                                |       |
|  |  * Limited to metadata view (no keystroke details)                 |       |
|  |  * Configurable per authorization policy                           |       |
|  +-------------------------------------------------------------------+       |
|                                                                               |
+==============================================================================+
```

---

## Web Player Usage

### Accessing Session Recordings

**Navigation Path:**
```
WALLIX Web UI > Audit > Sessions > [Select Session] > Play Recording
```

**Direct URL Format:**
```
https://bastion.example.com/wabam/recordings/play?session_id=SES-2026-001-A7B3C9D1
```

### Player Interface

```
+==============================================================================+
|                        SESSION PLAYBACK VIEWER                                |
+==============================================================================+
|                                                                               |
|  +------------------------------------------------------------------------+  |
|  | Session: SES-2026-001-A7B3C9D1                                         |  |
|  | User: jsmith -> root@srv-prod-01 (SSH) | 2026-01-15 09:30 - 10:45     |  |
|  +------------------------------------------------------------------------+  |
|                                                                               |
|  +------------------------------------------------------------------------+  |
|  |                                                                         |  |
|  |                                                                         |  |
|  |                                                                         |  |
|  |                     [SESSION VIDEO/TERMINAL DISPLAY]                    |  |
|  |                                                                         |  |
|  |  root@srv-prod-01:~# cd /var/log                                       |  |
|  |  root@srv-prod-01:/var/log# tail -f syslog                             |  |
|  |  Jan 15 09:35:22 srv-prod-01 systemd[1]: Started Session...            |  |
|  |                                                                         |  |
|  |                                                                         |  |
|  +------------------------------------------------------------------------+  |
|                                                                               |
|  PLAYBACK CONTROLS                                                           |
|  +------------------------------------------------------------------------+  |
|  |                                                                         |  |
|  |  [|<<] [<<] [<]  [>||]  [>] [>>] [>>|]     [M]  [|||]  [?]  [...]     |  |
|  |   |     |    |     |     |    |     |       |     |     |     |        |  |
|  |   |     |    |     |     |    |     |       |     |     |     +- Menu  |  |
|  |   |     |    |     |     |    |     |       |     |     +- Help        |  |
|  |   |     |    |     |     |    |     |       |     +- Fullscreen        |  |
|  |   |     |    |     |     |    |     |       +- Mute (RDP audio)        |  |
|  |   |     |    |     |     |    |     +- Jump to end                     |  |
|  |   |     |    |     |     |    +- Fast forward (2x, 4x, 8x)             |  |
|  |   |     |    |     |     +- Step forward (1 frame/command)             |  |
|  |   |     |    |     +- Play/Pause                                       |  |
|  |   |     |    +- Step backward (1 frame/command)                        |  |
|  |   |     +- Rewind (2x, 4x, 8x)                                         |  |
|  |   +- Jump to start                                                      |  |
|  |                                                                         |  |
|  +------------------------------------------------------------------------+  |
|                                                                               |
|  TIMELINE                                                                     |
|  +------------------------------------------------------------------------+  |
|  |                                                                         |  |
|  |  [====*================================---------------------------]    |  |
|  |  00:00                    00:45:12                           01:15:07 |  |
|  |       ^                       ^                                        |  |
|  |       |                       +-- Current position                     |  |
|  |       +-- Event markers (commands, alerts, screenshots)                |  |
|  |                                                                         |  |
|  +------------------------------------------------------------------------+  |
|                                                                               |
|  SPEED & NAVIGATION                                                          |
|  +------------------------------------------------------------------------+  |
|  |  Speed: [0.5x] [1x] [2x] [4x] [8x]                                     |  |
|  |                                                                         |  |
|  |  Jump to: [Event v] [00:00:00]  Search: [__________________] [Go]      |  |
|  +------------------------------------------------------------------------+  |
|                                                                               |
+==============================================================================+
```

### Playback Speed Options

| Speed | Use Case |
|-------|----------|
| 0.25x | Detailed forensic analysis, frame-by-frame review |
| 0.5x | Careful review of complex operations |
| 1x | Normal playback, standard review |
| 2x | Quick overview, familiar content |
| 4x | Scanning for specific events |
| 8x | Rapid navigation, high-level review |
| 16x | Skip to end, verify recording completeness |

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Space` | Play/Pause |
| `Left Arrow` | Step back 5 seconds |
| `Right Arrow` | Step forward 5 seconds |
| `Shift + Left` | Previous event marker |
| `Shift + Right` | Next event marker |
| `Home` | Jump to start |
| `End` | Jump to end |
| `+` / `-` | Increase/decrease speed |
| `F` | Toggle fullscreen |
| `M` | Toggle mute (RDP) |
| `S` | Take screenshot |
| `/` | Open search |
| `Esc` | Close dialogs/exit fullscreen |

---

## OCR Search

### How OCR Indexing Works

```
+==============================================================================+
|                         OCR PROCESSING PIPELINE                               |
+==============================================================================+
|                                                                               |
|  DURING SESSION (Real-time)                                                   |
|  ==========================                                                   |
|                                                                               |
|  +----------------+     +------------------+     +------------------+         |
|  | RDP/VNC        |     | Frame            |     | Temporary        |         |
|  | Video Stream   |---->| Buffer           |---->| Recording        |         |
|  | (Delta-encoded)|     | (Keyframes)      |     | (.wab.tmp)       |         |
|  +----------------+     +------------------+     +------------------+         |
|                                                                               |
|  POST-SESSION (Background processing)                                         |
|  ====================================                                         |
|                                                                               |
|  +----------------+     +------------------+     +------------------+         |
|  | Recording      |     | Keyframe         |     | OCR Engine       |         |
|  | Finalized      |---->| Extraction       |---->| (Tesseract)      |         |
|  | (.wab)         |     | (1 fps sample)   |     |                  |         |
|  +----------------+     +------------------+     +------------------+         |
|                                |                          |                   |
|                                v                          v                   |
|                         +------------------+     +------------------+         |
|                         | Frame with       |     | Extracted Text   |         |
|                         | Timestamp        |     | + Coordinates    |         |
|                         +------------------+     +------------------+         |
|                                                          |                   |
|                                                          v                   |
|                                                 +------------------+         |
|                                                 | Search Index     |         |
|                                                 | (.wab.ocr)       |         |
|                                                 |                  |         |
|                                                 | * Text content   |         |
|                                                 | * Timestamp      |         |
|                                                 | * Screen region  |         |
|                                                 | * Confidence     |         |
|                                                 +------------------+         |
|                                                                               |
|  OCR ACCURACY FACTORS                                                         |
|  ====================                                                         |
|                                                                               |
|  +---------------------------+----------------------------------------+      |
|  | Factor                    | Impact on Accuracy                     |      |
|  +---------------------------+----------------------------------------+      |
|  | Font type                 | Standard fonts: 95%+ accuracy          |      |
|  |                           | Custom/decorative: 70-85% accuracy     |      |
|  +---------------------------+----------------------------------------+      |
|  | Resolution                | 1080p+: Best results                   |      |
|  |                           | 720p: Good results                     |      |
|  |                           | Lower: Degraded accuracy               |      |
|  +---------------------------+----------------------------------------+      |
|  | Screen contrast           | High contrast: Best                    |      |
|  |                           | Low contrast: May miss text            |      |
|  +---------------------------+----------------------------------------+      |
|  | Text orientation          | Horizontal: Best                       |      |
|  |                           | Rotated/vertical: Lower accuracy       |      |
|  +---------------------------+----------------------------------------+      |
|  | Animation/scrolling       | Static: Best                           |      |
|  |                           | Moving text: May be missed             |      |
|  +---------------------------+----------------------------------------+      |
|                                                                               |
+==============================================================================+
```

### OCR Search Syntax

**Basic Search:**
```
password
credit card
administrator
SELECT * FROM
```

**Phrase Search (exact match):**
```
"credit card number"
"drop table"
"administrator password"
```

**Wildcard Search:**
```
admin*         # Matches: admin, administrator, administration
pass*word      # Matches: password, passw0rd, pass-word
*.xlsx         # Matches: data.xlsx, report.xlsx
```

**Boolean Operators:**
```
password AND admin           # Both terms present
credit OR debit              # Either term present
password NOT test            # Password without test
(admin OR root) AND password # Complex expressions
```

**Field-Specific Search:**
```
window_title:"Control Panel"    # Text in window title
dialog:"Save As"                # Text in dialog boxes
menu:"File > Export"            # Menu navigation
error:"Access Denied"           # Error messages
```

### OCR Search Examples

**Example 1: Find sensitive data access**
```bash
# Via Web UI: Audit > Sessions > Search
# Search query:
"credit card" OR "social security" OR "SSN"

# Via API:
curl -X POST "https://bastion.example.com/api/v3.12/sessions/search" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "search_type": "ocr",
    "query": "\"credit card\" OR \"social security\" OR SSN",
    "date_range": {
      "start": "2026-01-01T00:00:00Z",
      "end": "2026-01-31T23:59:59Z"
    },
    "protocol": ["RDP", "VNC"]
  }'
```

**Example 2: Find database operations**
```bash
# Search for SQL operations in graphical tools
"SELECT" AND "FROM" AND "WHERE"
"INSERT INTO"
"DELETE FROM"
"DROP TABLE"
```

**Example 3: Find file access**
```bash
# File explorer operations
window_title:"File Explorer" AND ".xlsx"
"Open" AND ("confidential" OR "secret" OR "private")
```

### OCR Search Results

```json
{
    "search_results": {
        "total_matches": 15,
        "sessions_matched": 3,
        "results": [
            {
                "session_id": "SES-2026-001-A7B3C9D1",
                "timestamp": "2026-01-15T09:42:33Z",
                "offset_seconds": 733,
                "matched_text": "Credit Card Processing Application",
                "context": "Window title in Excel spreadsheet",
                "screen_region": {
                    "x": 120,
                    "y": 15,
                    "width": 400,
                    "height": 25
                },
                "confidence": 0.97,
                "thumbnail_url": "/api/sessions/SES-2026-001-A7B3C9D1/thumbnail?offset=733"
            },
            {
                "session_id": "SES-2026-001-A7B3C9D1",
                "timestamp": "2026-01-15T09:45:12Z",
                "offset_seconds": 892,
                "matched_text": "credit card numbers.xlsx",
                "context": "File open dialog",
                "screen_region": {
                    "x": 200,
                    "y": 340,
                    "width": 180,
                    "height": 20
                },
                "confidence": 0.94
            }
        ]
    }
}
```

---

## Text Search in SSH Sessions

### Command and Output Search

SSH and Telnet sessions provide native text search without OCR processing.

```
+==============================================================================+
|                       SSH SESSION TEXT INDEXING                               |
+==============================================================================+
|                                                                               |
|  INDEXED CONTENT                                                              |
|  ===============                                                              |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |  INPUT STREAM (User keystrokes)                                       |   |
|  |-----------------------------------------------------------------------|   |
|  |  * Every character typed by user                                      |   |
|  |  * Parsed into complete commands                                      |   |
|  |  * Timestamps per keystroke and per command                           |   |
|  |  * Special keys recorded (Ctrl+C, Tab, arrows)                        |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |  OUTPUT STREAM (Server responses)                                     |   |
|  |-----------------------------------------------------------------------|   |
|  |  * All text output from server                                        |   |
|  |  * Command output, prompts, error messages                            |   |
|  |  * File contents displayed (cat, less, vi)                            |   |
|  |  * ANSI escape sequences stripped for search                          |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
|  INDEX STRUCTURE                                                              |
|  ===============                                                              |
|                                                                               |
|  {                                                                            |
|    "session_id": "SES-2026-001-A7B3C9D1",                                    |
|    "commands": [                                                              |
|      {                                                                        |
|        "index": 1,                                                            |
|        "timestamp": "2026-01-15T09:30:45Z",                                  |
|        "offset_seconds": 30,                                                  |
|        "command": "cd /var/log",                                             |
|        "exit_code": 0,                                                       |
|        "duration_ms": 45                                                     |
|      },                                                                       |
|      {                                                                        |
|        "index": 2,                                                            |
|        "timestamp": "2026-01-15T09:31:02Z",                                  |
|        "offset_seconds": 47,                                                  |
|        "command": "grep -i error syslog | tail -20",                         |
|        "exit_code": 0,                                                       |
|        "duration_ms": 1250                                                   |
|      }                                                                        |
|    ],                                                                         |
|    "full_text_index": "searchable text from input and output..."             |
|  }                                                                            |
|                                                                               |
+==============================================================================+
```

### SSH Search Syntax

**Command Search:**
```
command:rm              # Commands containing "rm"
command:"rm -rf"        # Exact command match
command:sudo*           # Commands starting with sudo
command:passwd          # Password change commands
```

**Output Search:**
```
output:error            # Error messages in output
output:"permission denied"  # Access denied messages
output:"connection refused" # Network errors
```

**Combined Search:**
```
command:mysql AND output:error    # MySQL commands that produced errors
command:sudo AND output:password  # Sudo with password prompts
command:cat AND output:password   # Viewing files containing passwords
```

**Pattern Search:**
```
# Find IP addresses in output
output:/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/

# Find email addresses
output:/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/

# Find credit card patterns
output:/\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}/
```

### SSH Search Examples

**Example 1: Find dangerous commands**
```bash
# Web UI or API search
command:"rm -rf" OR command:"dd if=" OR command:"mkfs" OR command:"> /dev/"

# API request
curl -X POST "https://bastion.example.com/api/v3.12/sessions/search" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "search_type": "command",
    "query": "rm -rf OR dd if= OR mkfs OR > /dev/",
    "date_range": {
      "start": "2026-01-01T00:00:00Z",
      "end": "2026-01-31T23:59:59Z"
    }
  }'
```

**Example 2: Find configuration changes**
```bash
command:vi AND ("/etc/" OR "/opt/" OR "config")
command:sed AND -i
command:echo AND ">>"
```

**Example 3: Find credential access**
```bash
output:password OR output:credential OR output:secret
command:cat AND (passwd OR shadow OR htpasswd)
```

### Command History Export

```bash
# Export all commands from a session
wabadmin recording commands --session SES-2026-001-A7B3C9D1 \
  --output /tmp/commands.txt

# Export with timestamps
wabadmin recording commands --session SES-2026-001-A7B3C9D1 \
  --format json --output /tmp/commands.json

# Sample output:
# [
#   {"timestamp": "2026-01-15T09:30:45Z", "command": "cd /var/log"},
#   {"timestamp": "2026-01-15T09:31:02Z", "command": "grep -i error syslog"},
#   ...
# ]
```

---

## Metadata Search

### Searchable Metadata Fields

| Field | Description | Example |
|-------|-------------|---------|
| `user` | Username who initiated session | `user:jsmith` |
| `user_group` | User's group membership | `user_group:admins` |
| `target` | Target device name | `target:srv-prod-01` |
| `target_account` | Account used on target | `target_account:root` |
| `target_group` | Target's group/domain | `target_group:production` |
| `protocol` | Session protocol | `protocol:SSH` |
| `date` | Session date | `date:2026-01-15` |
| `date_range` | Date range | `date:[2026-01-01 TO 2026-01-31]` |
| `duration` | Session length | `duration:>3600` (seconds) |
| `status` | Session status | `status:completed` |
| `ip` | Source IP address | `ip:10.0.1.*` |
| `authorization` | Authorization name | `authorization:linux-admin` |

### Metadata Search Examples

**Example 1: Find sessions by user and date**
```bash
# Web UI: Audit > Sessions > Advanced Search

# Search criteria:
user:jsmith AND date:[2026-01-01 TO 2026-01-15]
```

**Example 2: Find long sessions to critical systems**
```bash
target_group:production AND duration:>7200 AND protocol:RDP
```

**Example 3: Find after-hours access**
```bash
# Sessions outside business hours (requires time zone handling)
date:2026-01-* AND (time:[00:00 TO 06:00] OR time:[20:00 TO 23:59])
```

**Example 4: Find sessions by authorization**
```bash
authorization:"emergency-break-glass" AND date:[2026-01-01 TO 2026-01-31]
```

### Metadata Search via API

```bash
# Search sessions with multiple criteria
curl -X POST "https://bastion.example.com/api/v3.12/sessions/search" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "filters": {
      "user": ["jsmith", "bjones"],
      "target_group": "production",
      "protocol": ["SSH", "RDP"],
      "date_range": {
        "start": "2026-01-01T00:00:00Z",
        "end": "2026-01-31T23:59:59Z"
      },
      "duration_min_seconds": 300,
      "status": "completed"
    },
    "sort": {
      "field": "start_time",
      "order": "desc"
    },
    "limit": 100,
    "offset": 0
  }'
```

### Search Results Format

```json
{
    "total_count": 156,
    "returned_count": 100,
    "sessions": [
        {
            "session_id": "SES-2026-001-A7B3C9D1",
            "start_time": "2026-01-15T09:30:15Z",
            "end_time": "2026-01-15T10:45:22Z",
            "duration_seconds": 4507,
            "user": {
                "name": "jsmith",
                "display_name": "John Smith",
                "groups": ["admins", "linux-team"]
            },
            "target": {
                "name": "srv-prod-01",
                "address": "192.168.1.100",
                "account": "root",
                "group": "production"
            },
            "protocol": "SSH",
            "authorization": "linux-admins-to-production",
            "source_ip": "10.0.1.50",
            "status": "completed",
            "termination_reason": "user_disconnect",
            "recording": {
                "available": true,
                "size_bytes": 2450000,
                "indexed": true,
                "ocr_processed": false
            }
        }
    ]
}
```

---

## Recording Export

### Export Formats

| Format | Use Case | Content |
|--------|----------|---------|
| `.wab` | Native archive, legal evidence | Complete recording, all data |
| `.mp4` | Video playback, presentations | Video only, no search index |
| `.txt` | Text analysis, command review | Commands and output (SSH/Telnet) |
| `.json` | Programmatic analysis | Structured metadata and events |
| `.pdf` | Audit reports, documentation | Summary with screenshots |
| `.csv` | Spreadsheet analysis | Metadata and command list |

### Export via Web UI

**Navigation:**
```
Audit > Sessions > [Select Session] > Export > [Choose Format]
```

### Export via CLI

```bash
# Export single session as native .wab
wabadmin recording export --session SES-2026-001-A7B3C9D1 \
  --format wab \
  --output /export/SES-2026-001-A7B3C9D1.wab

# Export as MP4 video
wabadmin recording export --session SES-2026-001-A7B3C9D1 \
  --format mp4 \
  --quality high \
  --output /export/session-video.mp4

# Export SSH session as text transcript
wabadmin recording export --session SES-2026-001-A7B3C9D1 \
  --format txt \
  --include-timestamps \
  --output /export/session-transcript.txt

# Export metadata and events as JSON
wabadmin recording export --session SES-2026-001-A7B3C9D1 \
  --format json \
  --include-events \
  --include-commands \
  --output /export/session-data.json

# Export with time range (clip)
wabadmin recording export --session SES-2026-001-A7B3C9D1 \
  --format mp4 \
  --start-offset 300 \
  --end-offset 600 \
  --output /export/session-clip.mp4
```

### Export via API

```bash
# Request export
curl -X POST "https://bastion.example.com/api/v3.12/sessions/SES-2026-001-A7B3C9D1/export" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "format": "mp4",
    "options": {
      "quality": "high",
      "include_audio": true,
      "start_offset_seconds": 0,
      "end_offset_seconds": null
    }
  }'

# Response:
{
    "export_id": "EXP-2026-001-XYZ789",
    "status": "processing",
    "estimated_completion": "2026-01-15T12:30:00Z",
    "download_url": null
}

# Check export status
curl "https://bastion.example.com/api/v3.12/exports/EXP-2026-001-XYZ789" \
  -H "Authorization: Bearer $TOKEN"

# Response when complete:
{
    "export_id": "EXP-2026-001-XYZ789",
    "status": "completed",
    "download_url": "/api/v3.12/exports/EXP-2026-001-XYZ789/download",
    "size_bytes": 156000000,
    "expires": "2026-01-22T12:30:00Z"
}

# Download exported file
curl -O "https://bastion.example.com/api/v3.12/exports/EXP-2026-001-XYZ789/download" \
  -H "Authorization: Bearer $TOKEN"
```

### Export Text Transcript Example

```text
================================================================================
SESSION TRANSCRIPT
================================================================================

Session ID:     SES-2026-001-A7B3C9D1
User:           jsmith (John Smith)
Target:         root@srv-prod-01 (192.168.1.100)
Protocol:       SSH
Start Time:     2026-01-15 09:30:15 UTC
End Time:       2026-01-15 10:45:22 UTC
Duration:       01:15:07

================================================================================
COMMAND LOG
================================================================================

[09:30:45] root@srv-prod-01:~# cd /var/log
[09:31:02] root@srv-prod-01:/var/log# grep -i error syslog | tail -20
Jan 15 09:15:22 srv-prod-01 nginx[1234]: 2026/01/15 09:15:22 [error] ...
Jan 15 09:20:45 srv-prod-01 mysql[5678]: ERROR 1045 Access denied...
[09:32:15] root@srv-prod-01:/var/log# tail -f syslog
[09:45:30] ^C
[09:45:32] root@srv-prod-01:/var/log# systemctl status nginx
   nginx.service - A high performance web server
   Loaded: loaded (/lib/systemd/system/nginx.service; enabled)
   Active: active (running) since Mon 2026-01-15 00:00:01 UTC
[09:46:00] root@srv-prod-01:/var/log# exit
logout

================================================================================
END OF TRANSCRIPT
================================================================================
```

---

## Forensic Analysis

### Timeline Reconstruction

```
+==============================================================================+
|                      FORENSIC TIMELINE RECONSTRUCTION                         |
+==============================================================================+
|                                                                               |
|  SESSION: SES-2026-001-A7B3C9D1                                               |
|  ===================================                                          |
|                                                                               |
|  +------------------------------------------------------------------------+  |
|  | Time (UTC)      | Event Type    | Details                              |  |
|  +-----------------+---------------+--------------------------------------+  |
|  | 09:30:15.000    | SESSION_START | User jsmith authenticated            |  |
|  | 09:30:15.250    | AUTH_TARGET   | Connected to root@srv-prod-01        |  |
|  | 09:30:15.500    | RECORDING_ON  | Recording started                    |  |
|  | 09:30:45.123    | COMMAND       | cd /var/log                          |  |
|  | 09:31:02.456    | COMMAND       | grep -i error syslog | tail -20      |  |
|  | 09:32:15.789    | COMMAND       | tail -f syslog                       |  |
|  | 09:45:30.000    | KEYBOARD      | Ctrl+C (interrupt)                   |  |
|  | 09:45:32.111    | COMMAND       | systemctl status nginx               |  |
|  | 09:46:00.222    | COMMAND       | exit                                 |  |
|  | 09:46:00.500    | SESSION_END   | User disconnected                    |  |
|  | 09:46:00.750    | RECORDING_OFF | Recording finalized                  |  |
|  +-----------------+---------------+--------------------------------------+  |
|                                                                               |
|  EVIDENCE MARKERS                                                             |
|  ================                                                             |
|                                                                               |
|  [!] 09:31:02 - Viewed error logs (potential reconnaissance)                  |
|  [!] 09:32:15 - Real-time log monitoring (13 minutes duration)                |
|                                                                               |
+==============================================================================+
```

### Evidence Extraction Commands

```bash
# Extract complete timeline
wabadmin recording timeline --session SES-2026-001-A7B3C9D1 \
  --format json \
  --output /evidence/timeline.json

# Extract all keystrokes with timestamps
wabadmin recording keystrokes --session SES-2026-001-A7B3C9D1 \
  --include-special-keys \
  --output /evidence/keystrokes.json

# Extract screenshots at key moments
wabadmin recording screenshots --session SES-2026-001-A7B3C9D1 \
  --events "command,error,alert" \
  --output /evidence/screenshots/

# Extract screenshots at regular intervals
wabadmin recording screenshots --session SES-2026-001-A7B3C9D1 \
  --interval 60 \
  --output /evidence/interval-screenshots/

# Generate forensic report
wabadmin recording forensic-report --session SES-2026-001-A7B3C9D1 \
  --include-hashes \
  --include-timeline \
  --include-screenshots \
  --output /evidence/forensic-report.pdf
```

### Multi-Session Investigation

```bash
# Find all sessions by a suspect user in time range
wabadmin sessions search --user suspicious-user \
  --date-start 2026-01-01 --date-end 2026-01-31 \
  --output /investigation/sessions-list.json

# Correlate sessions across users accessing same target
wabadmin sessions correlate \
  --target srv-prod-01 \
  --date-start 2026-01-10 --date-end 2026-01-15 \
  --output /investigation/target-access-correlation.json

# Search for specific activity across all sessions
wabadmin recording search-all \
  --query "rm -rf" \
  --date-start 2026-01-01 --date-end 2026-01-31 \
  --output /investigation/dangerous-commands.json
```

### Forensic Report Template

```json
{
    "forensic_report": {
        "report_id": "FOR-2026-001-ABC",
        "generated": "2026-01-20T14:30:00Z",
        "generated_by": "security-officer",

        "session_summary": {
            "session_id": "SES-2026-001-A7B3C9D1",
            "user": "jsmith",
            "target": "root@srv-prod-01",
            "start_time": "2026-01-15T09:30:15Z",
            "end_time": "2026-01-15T10:45:22Z",
            "duration_seconds": 4507
        },

        "integrity_verification": {
            "recording_hash": "sha256:a1b2c3d4e5f6...",
            "metadata_hash": "sha256:f6e5d4c3b2a1...",
            "verification_status": "valid",
            "chain_of_custody": "maintained"
        },

        "timeline_events": [
            {
                "timestamp": "2026-01-15T09:30:15Z",
                "event_type": "SESSION_START",
                "details": "User authenticated successfully"
            }
        ],

        "key_findings": [
            {
                "finding_id": 1,
                "timestamp": "2026-01-15T09:35:00Z",
                "category": "suspicious_activity",
                "description": "User viewed system error logs",
                "evidence_reference": "screenshot_001.png"
            }
        ],

        "attachments": [
            "timeline.json",
            "keystrokes.json",
            "screenshots/",
            "recording.wab"
        ]
    }
}
```

---

## Recording Sharing

### Granting Auditor Access

```bash
# Grant temporary access to external auditor
wabadmin recording share --session SES-2026-001-A7B3C9D1 \
  --user external-auditor@company.com \
  --permission view \
  --expires 2026-02-15 \
  --require-mfa

# Grant access to multiple sessions
wabadmin recording share-bulk \
  --sessions-file /tmp/session-list.txt \
  --user auditor@external.com \
  --permission view \
  --expires 2026-02-15

# Create shareable link (time-limited)
wabadmin recording share-link --session SES-2026-001-A7B3C9D1 \
  --expires-hours 24 \
  --password-protected
```

### Sharing via API

```bash
# Create share for external party
curl -X POST "https://bastion.example.com/api/v3.12/recordings/share" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "session_ids": ["SES-2026-001-A7B3C9D1", "SES-2026-001-B8C4D0E2"],
    "recipient": {
      "email": "auditor@external.com",
      "name": "External Auditor"
    },
    "permissions": ["view", "export_text"],
    "restrictions": {
      "require_mfa": true,
      "ip_whitelist": ["203.0.113.0/24"],
      "expiration": "2026-02-15T00:00:00Z",
      "max_views": 10
    },
    "notification": {
      "send_email": true,
      "custom_message": "Access to requested session recordings for Q1 audit."
    }
  }'

# Response:
{
    "share_id": "SHR-2026-001-XYZ",
    "access_url": "https://bastion.example.com/shared/SHR-2026-001-XYZ",
    "access_code": "ABC123DEF",
    "expires": "2026-02-15T00:00:00Z",
    "sessions_shared": 2
}
```

### Access Logging

All shared recording access is logged:

```json
{
    "access_log": [
        {
            "timestamp": "2026-01-16T10:15:00Z",
            "share_id": "SHR-2026-001-XYZ",
            "session_accessed": "SES-2026-001-A7B3C9D1",
            "accessor_email": "auditor@external.com",
            "accessor_ip": "203.0.113.50",
            "action": "playback_start",
            "mfa_verified": true
        },
        {
            "timestamp": "2026-01-16T10:45:00Z",
            "share_id": "SHR-2026-001-XYZ",
            "session_accessed": "SES-2026-001-A7B3C9D1",
            "accessor_email": "auditor@external.com",
            "accessor_ip": "203.0.113.50",
            "action": "export_text",
            "mfa_verified": true
        }
    ]
}
```

---

## Bulk Export

### Export Multiple Sessions

```bash
# Export all sessions matching criteria
wabadmin recording bulk-export \
  --filter "user:jsmith AND date:[2026-01-01 TO 2026-01-31]" \
  --format wab \
  --output /export/january-sessions/ \
  --parallel 4

# Export for legal/compliance (with verification)
wabadmin recording bulk-export \
  --filter "target_group:production AND date:[2026-Q1]" \
  --format wab \
  --include-verification \
  --create-manifest \
  --output /export/q1-production-audit/

# Export as video for review
wabadmin recording bulk-export \
  --filter "protocol:RDP AND date:[2026-01-15]" \
  --format mp4 \
  --quality medium \
  --output /export/rdp-sessions/
```

### Bulk Export Script

```bash
#!/bin/bash
# /opt/scripts/compliance-export.sh
# Export session recordings for compliance audit

set -e

EXPORT_DIR="/export/compliance-$(date +%Y-%m)"
FILTER="date:[$(date -d '1 month ago' +%Y-%m-01) TO $(date -d '1 day ago' +%Y-%m-%d)]"
LOG_FILE="${EXPORT_DIR}/export.log"

mkdir -p "${EXPORT_DIR}"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${LOG_FILE}"
}

log "Starting compliance export"
log "Filter: ${FILTER}"

# Get session count
SESSION_COUNT=$(wabadmin sessions count --filter "${FILTER}")
log "Sessions to export: ${SESSION_COUNT}"

# Export recordings
log "Exporting recordings..."
wabadmin recording bulk-export \
  --filter "${FILTER}" \
  --format wab \
  --include-verification \
  --parallel 4 \
  --output "${EXPORT_DIR}/recordings/" \
  2>&1 | tee -a "${LOG_FILE}"

# Export metadata
log "Exporting metadata..."
wabadmin sessions export \
  --filter "${FILTER}" \
  --format json \
  --output "${EXPORT_DIR}/sessions-metadata.json"

# Generate manifest
log "Generating manifest..."
cat > "${EXPORT_DIR}/manifest.json" << EOF
{
    "export_date": "$(date -Iseconds)",
    "filter": "${FILTER}",
    "session_count": ${SESSION_COUNT},
    "exported_by": "$(whoami)",
    "bastion_version": "$(wabadmin version)"
}
EOF

# Generate checksums
log "Generating checksums..."
find "${EXPORT_DIR}" -type f ! -name "checksums.sha256" \
  -exec sha256sum {} \; > "${EXPORT_DIR}/checksums.sha256"

# Create archive
log "Creating archive..."
ARCHIVE_NAME="compliance-export-$(date +%Y%m%d).tar.gz"
tar -czf "${EXPORT_DIR}/../${ARCHIVE_NAME}" -C "${EXPORT_DIR}" .

ARCHIVE_SIZE=$(du -h "${EXPORT_DIR}/../${ARCHIVE_NAME}" | cut -f1)
log "Export complete: ${ARCHIVE_NAME} (${ARCHIVE_SIZE})"

# Optionally upload to secure storage
# aws s3 cp "${EXPORT_DIR}/../${ARCHIVE_NAME}" s3://compliance-archive/
```

### Export Manifest Format

```json
{
    "export_manifest": {
        "export_id": "EXP-BULK-2026-001",
        "created": "2026-02-01T00:00:00Z",
        "created_by": "compliance-officer",
        "purpose": "Q1 2026 Compliance Audit",

        "filters_applied": {
            "date_range": {
                "start": "2026-01-01T00:00:00Z",
                "end": "2026-01-31T23:59:59Z"
            },
            "target_group": "production"
        },

        "statistics": {
            "total_sessions": 1547,
            "total_size_bytes": 45000000000,
            "protocols": {
                "SSH": 892,
                "RDP": 543,
                "VNC": 87,
                "HTTP": 25
            }
        },

        "files": [
            {
                "filename": "SES-2026-001-A7B3C9D1.wab",
                "session_id": "SES-2026-001-A7B3C9D1",
                "size_bytes": 2450000,
                "sha256": "a1b2c3d4e5f6..."
            }
        ],

        "verification": {
            "all_recordings_verified": true,
            "signature_valid": true,
            "chain_of_custody_maintained": true
        }
    }
}
```

---

## Recording Integrity

### Verification Procedures

```
+==============================================================================+
|                    RECORDING INTEGRITY VERIFICATION                           |
+==============================================================================+
|                                                                               |
|  INTEGRITY COMPONENTS                                                         |
|  ====================                                                         |
|                                                                               |
|  1. FILE HASH (SHA-256)                                                       |
|     +-------------------------------------------------------------------+    |
|     | * Computed at recording finalization                               |    |
|     | * Stored in .wab.sig file                                          |    |
|     | * Verifies file has not been modified                              |    |
|     +-------------------------------------------------------------------+    |
|                                                                               |
|  2. DIGITAL SIGNATURE (Optional)                                              |
|     +-------------------------------------------------------------------+    |
|     | * Recording signed with Bastion private key                        |    |
|     | * Proves recording originated from authorized system               |    |
|     | * Timestamp from trusted time source                               |    |
|     +-------------------------------------------------------------------+    |
|                                                                               |
|  3. METADATA INTEGRITY                                                        |
|     +-------------------------------------------------------------------+    |
|     | * Session metadata hash                                            |    |
|     | * Cross-referenced with audit log entries                          |    |
|     | * Verifies session context                                         |    |
|     +-------------------------------------------------------------------+    |
|                                                                               |
|  4. CHAIN OF CUSTODY                                                          |
|     +-------------------------------------------------------------------+    |
|     | * Access log for all playback/export                               |    |
|     | * Immutable audit trail                                            |    |
|     | * Tracks all handling of recording                                 |    |
|     +-------------------------------------------------------------------+    |
|                                                                               |
+==============================================================================+
```

### Verification Commands

```bash
# Verify single recording integrity
wabadmin recording verify --session SES-2026-001-A7B3C9D1

# Output:
# Recording: SES-2026-001-A7B3C9D1
# File: /var/wab/recorded/2026/01/15/SES-2026-001-A7B3C9D1.wab
# Size: 2,450,000 bytes
#
# Verification Results:
#   File Hash:      VALID (sha256:a1b2c3d4...)
#   Signature:      VALID (signed 2026-01-15T10:45:23Z)
#   Metadata:       VALID (matches audit log)
#   Index:          VALID (OCR/commands verified)
#
# Overall Status: VERIFIED

# Verify with detailed output
wabadmin recording verify --session SES-2026-001-A7B3C9D1 --verbose

# Bulk verification
wabadmin recording verify-bulk \
  --filter "date:[2026-01-01 TO 2026-01-31]" \
  --output /reports/verification-report.json

# Verify exported recording (outside Bastion)
wabadmin recording verify-file \
  --file /export/SES-2026-001-A7B3C9D1.wab \
  --signature /export/SES-2026-001-A7B3C9D1.wab.sig
```

### Integrity Verification API

```bash
# Verify recording integrity via API
curl "https://bastion.example.com/api/v3.12/recordings/SES-2026-001-A7B3C9D1/verify" \
  -H "Authorization: Bearer $TOKEN"

# Response:
{
    "session_id": "SES-2026-001-A7B3C9D1",
    "verification_time": "2026-01-20T14:30:00Z",
    "results": {
        "file_integrity": {
            "status": "valid",
            "expected_hash": "sha256:a1b2c3d4e5f6...",
            "computed_hash": "sha256:a1b2c3d4e5f6...",
            "match": true
        },
        "digital_signature": {
            "status": "valid",
            "signer": "CN=bastion.example.com",
            "signed_at": "2026-01-15T10:45:23Z",
            "certificate_valid": true
        },
        "metadata_integrity": {
            "status": "valid",
            "audit_log_match": true,
            "session_data_consistent": true
        },
        "index_integrity": {
            "status": "valid",
            "command_index_valid": true,
            "ocr_index_valid": true
        }
    },
    "overall_status": "verified",
    "chain_of_custody": {
        "recording_created": "2026-01-15T10:45:22Z",
        "last_accessed": "2026-01-20T14:30:00Z",
        "access_count": 3,
        "export_count": 1
    }
}
```

### Chain of Custody Report

```bash
# Generate chain of custody report
wabadmin recording chain-of-custody --session SES-2026-001-A7B3C9D1 \
  --output /evidence/chain-of-custody.pdf

# Report includes:
# - Recording creation timestamp
# - All playback events with user/IP/time
# - All export events with user/IP/time/destination
# - All share events with recipient/expiration
# - All verification events
# - Cryptographic proof of each event
```

---

## Storage Management

### Storage Configuration

```bash
# Check current storage usage
wabadmin storage status

# Output:
# Recording Storage Status
# ========================
#
# Primary Storage: /var/wab/recorded
#   Total:      2.0 TB
#   Used:       1.2 TB (60%)
#   Available:  800 GB (40%)
#   Recordings: 45,678
#
# Archive Storage: /var/wab/recorded/archive
#   Total:      5.0 TB
#   Used:       3.8 TB (76%)
#   Available:  1.2 TB (24%)
#   Archives:   24
#
# Staging (Active): /var/wab/recorded/staging
#   Active Recordings: 12
#   Size: 450 MB

# Configure external storage
wabadmin storage configure \
  --type nfs \
  --server nas.example.com \
  --path /wallix/recordings \
  --mount-point /var/wab/recorded/external
```

### NAS/SAN Configuration

```
+==============================================================================+
|                        EXTERNAL STORAGE CONFIGURATION                         |
+==============================================================================+
|                                                                               |
|  NFS CONFIGURATION                                                            |
|  =================                                                            |
|                                                                               |
|  /etc/fstab entry:                                                            |
|  nas.example.com:/wallix/recordings  /var/wab/recorded/external  nfs4  \     |
|    rw,sync,hard,intr,rsize=1048576,wsize=1048576  0  0                       |
|                                                                               |
|  Mount options explained:                                                     |
|  * rw        - Read/write access                                             |
|  * sync      - Synchronous writes (data integrity)                           |
|  * hard      - Retry indefinitely on failure                                 |
|  * intr      - Allow interrupt of hung processes                             |
|  * rsize     - Read buffer size (1MB for performance)                        |
|  * wsize     - Write buffer size (1MB for performance)                       |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  iSCSI CONFIGURATION                                                          |
|  ===================                                                          |
|                                                                               |
|  # Discover targets                                                           |
|  iscsiadm -m discovery -t sendtargets -p san.example.com                     |
|                                                                               |
|  # Login to target                                                            |
|  iscsiadm -m node -T iqn.2026-01.com.example:wallix-recordings -l            |
|                                                                               |
|  # Format and mount                                                           |
|  mkfs.xfs /dev/sdb                                                            |
|  mount /dev/sdb /var/wab/recorded/san                                        |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  S3-COMPATIBLE STORAGE (for archival)                                         |
|  ====================================                                         |
|                                                                               |
|  wabadmin storage configure-s3 \                                              |
|    --bucket wallix-recordings-archive \                                       |
|    --region us-east-1 \                                                       |
|    --access-key AKIAIOSFODNN7EXAMPLE \                                       |
|    --secret-key wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY \                   |
|    --storage-class STANDARD_IA \                                              |
|    --encryption AES256                                                        |
|                                                                               |
+==============================================================================+
```

### Archival Procedures

```bash
# Manual archive of old recordings
wabadmin recording archive \
  --older-than 90 \
  --destination /var/wab/recorded/archive \
  --compress

# Archive to S3
wabadmin recording archive \
  --older-than 180 \
  --destination s3://wallix-archive/recordings \
  --storage-class GLACIER

# Schedule automatic archival (cron)
# /etc/cron.daily/wallix-archive
wabadmin recording archive --older-than 30 --destination /archive --compress
```

### Storage Cleanup

```bash
# Identify recordings eligible for deletion
wabadmin recording cleanup --dry-run \
  --older-than 730 \
  --exclude-legal-hold

# Execute cleanup with confirmation
wabadmin recording cleanup \
  --older-than 730 \
  --exclude-legal-hold \
  --confirm

# Generate cleanup report
wabadmin recording cleanup-report \
  --output /reports/cleanup-candidates.csv
```

### Storage Monitoring

```bash
# Enable storage alerts
wabadmin storage alerts configure \
  --warning-threshold 80 \
  --critical-threshold 95 \
  --notification-email storage-admin@example.com

# Check storage health
wabadmin storage health-check

# Output:
# Storage Health Check
# ====================
#
# Primary Storage (/var/wab/recorded):
#   Disk Health:     OK
#   I/O Performance: OK (Read: 450 MB/s, Write: 380 MB/s)
#   Space Status:    WARNING (60% used)
#   Permissions:     OK
#
# NFS Mount (/var/wab/recorded/external):
#   Connection:      OK
#   Latency:         OK (2.3ms)
#   Availability:    OK
```

---

## Troubleshooting

### Recording Not Playing

```
+==============================================================================+
|                    PLAYBACK TROUBLESHOOTING                                   |
+==============================================================================+
|                                                                               |
|  ISSUE: Recording fails to play / "Recording not found"                       |
|  ======================================================                       |
|                                                                               |
|  Diagnostic Steps:                                                            |
|                                                                               |
|  1. Verify recording exists:                                                  |
|     $ ls -la /var/wab/recorded/2026/01/15/SES-2026-001-*.wab                 |
|                                                                               |
|  2. Check file permissions:                                                   |
|     $ stat /var/wab/recorded/2026/01/15/SES-2026-001-A7B3C9D1.wab            |
|     Expected: -rw-r----- wab:wab                                             |
|                                                                               |
|  3. Verify recording in database:                                             |
|     $ wabadmin sessions show SES-2026-001-A7B3C9D1                           |
|                                                                               |
|  4. Check playback service logs:                                              |
|     $ journalctl -u wab-playback --since "10 minutes ago"                    |
|                                                                               |
|  Common Causes:                                                               |
|  * Recording file moved or deleted                                           |
|  * File permissions changed                                                  |
|  * Storage mount disconnected                                                |
|  * Recording still being processed (post-session)                            |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  ISSUE: Playback stutters or stops                                            |
|  ===================================                                          |
|                                                                               |
|  Diagnostic Steps:                                                            |
|                                                                               |
|  1. Check storage I/O:                                                        |
|     $ iostat -x 1 5                                                          |
|                                                                               |
|  2. Check network to storage:                                                 |
|     $ ping -c 10 nas.example.com                                             |
|                                                                               |
|  3. Check playback service resources:                                         |
|     $ top -p $(pgrep -f wab-playback)                                        |
|                                                                               |
|  4. Check browser console for errors                                          |
|                                                                               |
|  Solutions:                                                                   |
|  * Reduce playback quality settings                                          |
|  * Close other browser tabs                                                  |
|  * Use direct network path to storage                                        |
|  * Increase server resources                                                 |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  ISSUE: "Recording corrupted" error                                           |
|  ===================================                                          |
|                                                                               |
|  Diagnostic Steps:                                                            |
|                                                                               |
|  1. Verify file integrity:                                                    |
|     $ wabadmin recording verify --session SES-2026-001-A7B3C9D1              |
|                                                                               |
|  2. Check file structure:                                                     |
|     $ wabadmin recording diagnose --session SES-2026-001-A7B3C9D1            |
|                                                                               |
|  3. Attempt repair:                                                           |
|     $ wabadmin recording repair --session SES-2026-001-A7B3C9D1              |
|                                                                               |
|  If repair fails:                                                             |
|  * Check for backup copies                                                   |
|  * Contact WALLIX support with diagnostic output                             |
|  * Recording may be unrecoverable                                            |
|                                                                               |
+==============================================================================+
```

### Missing Recordings

```bash
# Find sessions without recordings
wabadmin sessions orphaned --list

# Check recording status
wabadmin recording status --session SES-2026-001-A7B3C9D1

# Common causes for missing recordings:
# 1. Authorization has is_recorded = false
# 2. Storage was full during session
# 3. Session ended abnormally
# 4. Recording archival/deletion

# Check authorization recording settings
wabadmin authorization show <auth_id> | grep is_recorded

# Check storage space during session time
wabadmin storage history --date 2026-01-15
```

### OCR Search Not Finding Results

```bash
# Check if OCR processing completed
wabadmin recording ocr-status --session SES-2026-001-A7B3C9D1

# Output:
# OCR Processing Status:
#   Protocol: RDP
#   Status: completed / in_progress / failed / not_applicable
#   Processed Frames: 4532
#   Indexed Words: 12456
#   Processing Time: 45 minutes

# Reprocess OCR if failed
wabadmin recording ocr-reprocess --session SES-2026-001-A7B3C9D1

# Check OCR queue status
wabadmin ocr-queue status

# View OCR processing logs
journalctl -u wab-ocr --since "1 hour ago" | grep SES-2026-001-A7B3C9D1
```

### Storage Issues

```bash
# Check disk space
df -h /var/wab/recorded

# Check inode usage
df -i /var/wab/recorded

# Check for large files
find /var/wab/recorded -size +1G -ls

# Check NFS mount status
mount | grep wab
showmount -e nas.example.com

# Remount NFS if disconnected
umount -f /var/wab/recorded/external
mount /var/wab/recorded/external

# Check for stale NFS handles
ls /var/wab/recorded/external 2>&1 | grep -i stale
```

### Performance Issues

```bash
# Check playback service performance
wabadmin playback-service status

# Check concurrent playback sessions
wabadmin playback-service connections

# Tune playback service (if needed)
wabadmin playback-service configure \
  --max-concurrent 20 \
  --buffer-size 32M \
  --cache-size 1G

# Check transcoding queue (for exports)
wabadmin export-queue status
```

### Diagnostic Commands Summary

| Issue | Diagnostic Command |
|-------|-------------------|
| Recording not found | `wabadmin recording diagnose --session <id>` |
| Playback fails | `journalctl -u wab-playback -f` |
| OCR not working | `wabadmin recording ocr-status --session <id>` |
| Storage issues | `wabadmin storage health-check` |
| Export fails | `wabadmin export-queue status` |
| Verification fails | `wabadmin recording verify --session <id> --verbose` |

---

## Quick Reference

### Common CLI Commands

```bash
# Session search
wabadmin sessions search --user jsmith --date-start 2026-01-01

# Playback (opens browser)
wabadmin recording play --session SES-2026-001-A7B3C9D1

# Export recording
wabadmin recording export --session SES-2026-001-A7B3C9D1 --format mp4

# Verify integrity
wabadmin recording verify --session SES-2026-001-A7B3C9D1

# Search commands in sessions
wabadmin recording search --query "rm -rf" --date-range "2026-01"

# Storage status
wabadmin storage status

# Archive old recordings
wabadmin recording archive --older-than 90 --destination /archive
```

### API Endpoints Reference

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v3.12/sessions` | GET | List sessions |
| `/api/v3.12/sessions/search` | POST | Search sessions |
| `/api/v3.12/sessions/{id}` | GET | Get session details |
| `/api/v3.12/sessions/{id}/playback` | GET | Stream playback |
| `/api/v3.12/sessions/{id}/export` | POST | Request export |
| `/api/v3.12/sessions/{id}/verify` | GET | Verify integrity |
| `/api/v3.12/sessions/{id}/timeline` | GET | Get event timeline |
| `/api/v3.12/recordings/share` | POST | Create share link |
| `/api/v3.12/exports/{id}` | GET | Check export status |
| `/api/v3.12/exports/{id}/download` | GET | Download export |

---

## Related Documentation

- [Session Management](../09-session-management/README.md) - Recording configuration and real-time monitoring
- [Compliance & Audit](../24-compliance-audit/README.md) - Using recordings for compliance evidence
- [Incident Response](../23-incident-response/README.md) - Forensic use of session recordings
- [Backup and Restore](../30-backup-restore/README.md) - Recording backup procedures
- [API Reference](../17-api-reference/README.md) - Complete API documentation

---

## External References

- [WALLIX Documentation Portal](https://pam.wallix.one/documentation)
- [WALLIX Admin Guide](https://pam.wallix.one/documentation/admin-doc/bastion_en_administration_guide.pdf)
- [WALLIX REST API Samples](https://github.com/wallix/wbrest_samples)

---

## See Also

**Related Sections:**
- [09 - Session Management](../09-session-management/README.md) - Session recording configuration
- [12 - Monitoring & Observability](../12-monitoring-observability/README.md) - Real-time monitoring

**Official Resources:**
- [WALLIX Documentation](https://pam.wallix.one/documentation)

---

*Document Version: 1.0*
*Last Updated: February 2026*
*Applies to: WALLIX Bastion 12.x*
