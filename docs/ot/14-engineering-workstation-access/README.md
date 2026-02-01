# 62 - Engineering Workstation Access for OT Environments

## Table of Contents

1. [Engineering Access Overview](#engineering-access-overview)
2. [Architecture](#architecture)
3. [PLC Programming Access](#plc-programming-access)
4. [HMI Development Access](#hmi-development-access)
5. [Access Control Patterns](#access-control-patterns)
6. [Session Recording for Engineering](#session-recording-for-engineering)
7. [Credential Management](#credential-management)
8. [Change Control Integration](#change-control-integration)
9. [Vendor Engineer Access](#vendor-engineer-access)
10. [Backup and Recovery](#backup-and-recovery)
11. [Compliance](#compliance)
12. [Troubleshooting](#troubleshooting)

---

## Engineering Access Overview

### What Engineering Workstations Do

Engineering Workstations (EWS) are specialized computers used by control engineers to program, configure, and maintain PLCs, HMIs, DCS systems, and other OT assets.

For official WALLIX documentation: https://pam.wallix.one/documentation

```
+==============================================================================+
|                    ENGINEERING WORKSTATION FUNCTIONS                          |
+==============================================================================+
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |  PLC PROGRAMMING           |  HMI DEVELOPMENT                        |   |
|  |  * Ladder logic, FB, ST    |  * Operator interface screens           |   |
|  |  * Download/upload code    |  * Alarm configuration                  |   |
|  |  * Online debugging        |  * Tag databases                        |   |
|  |  * Force I/O points        |  * Runtime deployment                   |   |
|  +-----------------------------------------------------------------------+   |
|  |  SYSTEM CONFIGURATION      |  SAFETY SYSTEMS                         |   |
|  |  * Network devices         |  * SIS programming                      |   |
|  |  * Drive/motion setup      |  * Safety PLC logic                     |   |
|  |  * Historian config        |  * Validation testing                   |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
+==============================================================================+
```

### Security Risks

| Risk Category | Impact |
|---------------|--------|
| Malicious code injection | Process disruption, equipment damage, safety bypass |
| Accidental modification | Unintended behavior, production loss, quality issues |
| Shared accounts | No accountability, audit trail gaps |
| Data exfiltration | IP theft, configuration disclosure |
| Vendor access | Third-party risk, supply chain attacks |

```
+==============================================================================+
|                    ENGINEERING ACCESS RISK MATRIX                             |
+==============================================================================+
|                                                                               |
|  ATTACK VECTORS                                                               |
|  ==============                                                               |
|                                                                               |
|  1. INSIDER THREAT                                                            |
|     * Disgruntled employee modifies PLC logic                                |
|     * Contractor installs backdoor during maintenance                        |
|     * Engineer accidentally downloads untested code                          |
|                                                                               |
|  2. SUPPLY CHAIN ATTACK                                                       |
|     * Compromised vendor laptop connects to EWS                              |
|     * Malicious project file imported from external source                   |
|     * Infected firmware update deployed to controllers                       |
|                                                                               |
|  3. CREDENTIAL COMPROMISE                                                     |
|     * Shared engineering passwords exposed                                   |
|     * Phishing attack captures PLC access credentials                        |
|     * Hardcoded passwords in project files                                   |
|                                                                               |
|  WALLIX MITIGATION                                                            |
|  =================                                                            |
|                                                                               |
|  [x] Individual accountability - no shared accounts                           |
|  [x] Session recording - full audit trail of changes                          |
|  [x] Approval workflows - prevent unauthorized modifications                  |
|  [x] Credential vault - secure storage and rotation                           |
|  [x] Time-limited access - reduce exposure window                             |
|  [x] Network isolation - all access through WALLIX                            |
|                                                                               |
+==============================================================================+
```

---

## Architecture

### Engineering Workstation Placement and Access Paths

```
+==============================================================================+
|                    ENGINEERING WORKSTATION ARCHITECTURE                       |
+==============================================================================+
|                                                                               |
|  CORPORATE (Level 4-5)           OT DMZ (Level 3.5)                          |
|                                                                               |
|     +----------------+           +=======================+                   |
|     | Control Engr   |  HTTPS    |  WALLIX ACCESS MGR    |                   |
|     | (Office)       |---------->|  (DMZ / Web Portal)   |                   |
|     +----------------+           +===========+===========+                   |
|                                              |                                |
|     +----------------+           +===========v===========+                   |
|     | Vendor Engr    |  HTTPS    |  WALLIX BASTION       |                   |
|     | (Remote)       |---------->|  (OT Security Zone)   |                   |
|     +----------------+           |  * Authorization      |                   |
|                                  |  * Session Recording  |                   |
|                                  |  * Credential Inject  |                   |
|                                  +===========+===========+                   |
|                                              | RDP (3389)                     |
|  CONTROL NETWORK (Level 3)                   v                                |
|     +----------------+  +----------------+  +----------------+               |
|     | EWS-SIEMENS    |  | EWS-ROCKWELL   |  | EWS-GENERAL    |               |
|     | TIA Portal     |  | Studio 5000    |  | Multi-vendor   |               |
|     +-------+--------+  +-------+--------+  +-------+--------+               |
|             |                   |                   |                         |
|  CONTROL NETWORK (Level 1-2)    v                   v                         |
|     +--------+  +--------+  +--------+  +--------+                           |
|     | S7-1500|  | CLX    |  | HMIs   |  | Drives |                           |
|     +--------+  +--------+  +--------+  +--------+                           |
|                                                                               |
+==============================================================================+
```

### Firewall Rules

| Source | Destination | Port | Action |
|--------|-------------|------|--------|
| WALLIX Bastion | Engineering WS | 3389 | ALLOW |
| EWS-SIEMENS | Siemens PLCs | 102 | ALLOW |
| EWS-ROCKWELL | Rockwell PLCs | 44818 | ALLOW |
| Corporate Network | Engineering WS | ANY | DENY |

### Network Segmentation Strategy

```
+==============================================================================+
|                    NETWORK ZONES FOR ENGINEERING ACCESS                       |
+==============================================================================+
|                                                                               |
|  ZONE CONFIGURATION                                                           |
|  ==================                                                           |
|                                                                               |
|  +--------------------+--------------------------------------------------+   |
|  | Zone               | Purpose                   | Security Level       |   |
|  +--------------------+---------------------------+----------------------+   |
|  | Corporate (L4-5)   | Office networks           | Standard IT          |   |
|  | OT DMZ (L3.5)      | WALLIX, data exchange     | High (PAM enforced)  |   |
|  | Control (L3)       | Engineering workstations  | High (restricted)    |   |
|  | Process (L1-2)     | PLCs, HMIs, controllers   | Critical (isolated)  |   |
|  | Safety (L1)        | SIS, safety PLCs          | Critical+ (airgap)   |   |
|  +--------------------+---------------------------+----------------------+   |
|                                                                               |
|  KEY PRINCIPLES                                                               |
|  ==============                                                               |
|                                                                               |
|  1. No direct access from Corporate to Control/Process zones                 |
|  2. All engineering access transits through WALLIX in OT DMZ                 |
|  3. EWS can only reach specific PLCs on specific protocols                   |
|  4. No internet access from EWS or control networks                          |
|  5. Safety systems physically isolated or require additional controls        |
|                                                                               |
+==============================================================================+
```

---

## PLC Programming Access

### Siemens TIA Portal Access

```json
{
    "device": {
        "name": "EWS-SIEMENS-01",
        "host": "10.100.10.50",
        "domain": "OT-Engineering"
    },
    "service": {
        "name": "RDP-Engineering",
        "protocol": "RDP",
        "port": 3389,
        "subprotocols": {
            "clipboard": false,
            "drive_redirection": false
        }
    },
    "authorization": {
        "name": "siemens-plc-programming",
        "user_group": "Siemens-Control-Engineers",
        "is_recorded": true,
        "approval_required": true,
        "session_max_duration": "4h"
    }
}
```

### Rockwell Studio 5000 Access

```bash
# Device Configuration
wabadmin device create EWS-ROCKWELL-01 \
  --domain OT-Engineering \
  --host 10.100.10.51

# Service
wabadmin service create EWS-ROCKWELL-01/RDP \
  --protocol rdp --port 3389

# Account with rotation
wabadmin account create EWS-ROCKWELL-01/studio5000_engineer \
  --service RDP \
  --auto-change-password true \
  --change-interval 30
```

### ABB Automation Builder Access

```bash
wabadmin device create EWS-ABB-01 \
  --domain OT-Engineering \
  --host 10.100.10.52 \
  --description "ABB Automation Builder Workstation"

# ABB AC500 uses TCP 1201, 1202 - ensure EWS can reach PLCs
```

### Schneider Unity Pro / EcoStruxure Access

```bash
wabadmin device create EWS-SCHNEIDER-01 \
  --domain OT-Engineering \
  --host 10.100.10.53

wabadmin authorization create schneider-plc-programming \
  --user-group Schneider-Engineers \
  --target EWS-SCHNEIDER-01/RDP/schneider_engineer \
  --approval-required true \
  --session-recording true
```

### Vendor-Specific Protocol Considerations

```
+==============================================================================+
|                    PLC PROGRAMMING PROTOCOLS                                  |
+==============================================================================+
|                                                                               |
|  SIEMENS S7 COMMUNICATION                                                     |
|  ========================                                                     |
|                                                                               |
|  Protocol: S7comm / S7comm-plus                                              |
|  Port: TCP 102 (ISO-TSAP)                                                    |
|                                                                               |
|  Protection Levels:                                                          |
|  * Level 1: No protection (not recommended)                                  |
|  * Level 2: Write protection (password for changes)                          |
|  * Level 3: Read/Write protection (password for all access)                  |
|  * Level 4: Full protection (CPU key required)                               |
|                                                                               |
|  ROCKWELL CIP/ETHERNET/IP                                                     |
|  ========================                                                     |
|                                                                               |
|  Protocol: Common Industrial Protocol over EtherNet/IP                       |
|  Ports: TCP 44818 (explicit), UDP 2222 (implicit I/O)                        |
|                                                                               |
|  Security Options:                                                           |
|  * Controller slot passwords                                                 |
|  * FactoryTalk security integration                                          |
|  * CIP Security (certificate-based, newer systems)                           |
|                                                                               |
|  SCHNEIDER MODBUS/UNITELWAY                                                   |
|  ==========================                                                   |
|                                                                               |
|  Protocol: Modbus TCP, Unitelway (legacy)                                    |
|  Ports: TCP 502 (Modbus), TCP 3000 (Unitelway)                               |
|                                                                               |
|  Security Notes:                                                             |
|  * Modbus has no built-in authentication                                     |
|  * Rely on network segmentation and PAM                                      |
|  * M580 supports Modbus/TCP Security (TLS)                                   |
|                                                                               |
|  ABB AC500/SYMPHONY                                                           |
|  ==================                                                           |
|                                                                               |
|  Protocol: ABB proprietary                                                   |
|  Ports: TCP 1201, 1202                                                       |
|                                                                               |
|  Security: Password protection at CPU level                                  |
|                                                                               |
+==============================================================================+
```

---

## HMI Development Access

### Wonderware / AVEVA System Platform

```json
{
    "device": {
        "name": "EWS-AVEVA-01",
        "host": "10.100.10.60",
        "description": "AVEVA System Platform Development Node"
    },
    "access_levels": [
        {"name": "development", "capabilities": "Full ArchestrA IDE"},
        {"name": "runtime", "capabilities": "Limited modification", "approval": "required"},
        {"name": "readonly", "capabilities": "View only", "approval": "none"}
    ]
}
```

### Ignition Designer

```
+----------------------------------------------------------------------+
|  IGNITION ACCESS OPTIONS                                              |
+----------------------------------------------------------------------+
|                                                                        |
|  Option 1: HTTPS Proxy                  Option 2: RDP to EWS          |
|  * Device: IGNITION-GW-01               * Device: EWS-IGNITION-01     |
|  * Protocol: HTTPS (8043)               * Protocol: RDP (3389)        |
|  * Direct gateway access                * Designer pre-installed      |
|                                                                        |
|  Ignition supports IdP (SAML/OIDC) - integrate with WALLIX IdP       |
+----------------------------------------------------------------------+
```

### WinCC and FactoryTalk View

| Product | Access Method | Configuration |
|---------|---------------|---------------|
| WinCC Unified | HTTPS (443) | Web-based, proxy through WALLIX |
| WinCC Professional | RDP to EWS | Same as TIA Portal access |
| WinCC Classic | RDP (3389) | Dedicated SCADA workstation |
| FactoryTalk View SE | RDP to EWS | Uses FactoryTalk Directory |
| FactoryTalk View ME | RDP to EWS | Panel development station |

---

## Access Control Patterns

### Read-Only vs Read-Write Access

```
+==============================================================================+
|                    ACCESS LEVEL DEFINITIONS                                   |
+==============================================================================+
|  Level      | Capabilities                      | Approval Required          |
+-------------+-----------------------------------+----------------------------+
|  VIEW       | Monitor values, view configs      | No                         |
|  DIAGNOSE   | Upload programs, compare online   | Supervisor (1)             |
|  MODIFY     | Online edits, force I/O           | Supervisor (1)             |
|  PROGRAM    | Download, mode changes, firmware  | Engineering Lead + OT Sec  |
+==============================================================================+
```

### Implementation with Multiple Accounts

```bash
# View-only account
wabadmin account create EWS-SIEMENS-01/tia_viewer \
  --description "TIA Portal view-only access"

# Diagnostic account
wabadmin account create EWS-SIEMENS-01/tia_diagnostics \
  --description "TIA Portal diagnostic access"

# Full engineering account
wabadmin account create EWS-SIEMENS-01/tia_engineer \
  --description "TIA Portal full engineering access"

# Match authorization to access level
wabadmin authorization create siemens-view-only \
  --user-group Control-Operators \
  --target EWS-SIEMENS-01/RDP/tia_viewer \
  --approval-required false

wabadmin authorization create siemens-full-engineering \
  --user-group Senior-Control-Engineers \
  --target EWS-SIEMENS-01/RDP/tia_engineer \
  --approval-required true \
  --approval-group "Engineering-Managers,OT-Security"
```

### Time-Limited Engineering Windows

```bash
# Define time frames
wabadmin timeframe create engineering-hours \
  --schedule "MON-FRI 07:00-18:00"

wabadmin timeframe create maintenance-window \
  --schedule "SAT 06:00-14:00"

# Apply to authorization
wabadmin authorization create plc-engineering-standard \
  --user-group Control-Engineers \
  --target-group Engineering-Workstations \
  --time-frames engineering-hours \
  --approval-required true \
  --session-max-duration 4h
```

### Production vs Development Environments

| Attribute | Development | Production |
|-----------|-------------|------------|
| Approval required | No | Yes |
| Time restrictions | Business hours | Maintenance only |
| Session recording | Yes | Yes + OCR |
| Max session duration | 8 hours | 2 hours |
| Post-session review | Optional | Mandatory |

### Project-Based Access Control

```
+==============================================================================+
|                    PROJECT-BASED ACCESS PATTERNS                              |
+==============================================================================+
|                                                                               |
|  SCENARIO: Single EWS serves multiple production areas                        |
|  =====================================================                        |
|                                                                               |
|     EWS-SIEMENS-01                                                           |
|     +-----------------------------------------+                              |
|     |  Projects:                              |                              |
|     |  +-----------------------------------+  |                              |
|     |  | Line1_PLC  - Production Line 1   |  |                              |
|     |  | Line2_PLC  - Production Line 2   |  |                              |
|     |  | Utility_PLC - HVAC, Utilities    |  |                              |
|     |  | Safety_PLC  - Safety Systems     |  |                              |
|     |  +-----------------------------------+  |                              |
|     +-----------------------------------------+                              |
|                                                                               |
|  IMPLEMENTATION OPTIONS                                                       |
|  ======================                                                       |
|                                                                               |
|  Option 1: Separate EWS per production area (recommended for safety)        |
|  Option 2: Windows user profiles with file system permissions                |
|  Option 3: Authorization-based access to different accounts                  |
|                                                                               |
|  EXAMPLE CONFIGURATION                                                        |
|  ---------------------                                                        |
|                                                                               |
|  # Line 1 engineers get Line 1 account                                       |
|  wabadmin authorization create line1-engineering \                           |
|    --user-group Line1-Engineers \                                            |
|    --target EWS-SIEMENS-01/RDP/line1_engineer                                |
|                                                                               |
|  # Safety engineers get safety account with dual approval                    |
|  wabadmin authorization create safety-engineering \                          |
|    --user-group Safety-Engineers \                                           |
|    --target EWS-SIEMENS-01/RDP/safety_engineer \                             |
|    --approval-required true \                                                |
|    --approval-group "Safety-Manager,OT-Security"                             |
|                                                                               |
+==============================================================================+
```

---

## Session Recording for Engineering

### What Gets Recorded

| Content Type | Captured By |
|--------------|-------------|
| Screen activity | Full video (RDP) |
| Keystrokes | Input logging |
| Window titles | OCR extraction |
| Dialog boxes | OCR extraction |
| Code editors | OCR of visible code |
| Download confirmations | OCR extraction |

### Recording Configuration

```bash
wabadmin authorization update plc-engineering \
  --session-recording true \
  --recording-quality high \
  --ocr-enabled true \
  --keystroke-logging true
```

### Search and Audit

```bash
# Find download operations
wabadmin recording search \
  --query "Download" \
  --target-group Engineering-Workstations \
  --date-range "2026-01-01 to 2026-01-31"

# Find sessions accessing specific PLC
wabadmin recording search \
  --query "192.168.10.100" \
  --target-group Siemens-EWS

# Configure alerts for high-risk activities
wabadmin alert create plc-download-alert \
  --trigger-pattern "Download to PLC" \
  --target-group Production-Engineering-WS \
  --notification-email "ot-security@company.com" \
  --severity high
```

### Before/After Change Documentation

```
+==============================================================================+
|                    CHANGE DOCUMENTATION WORKFLOW                              |
+==============================================================================+
|                                                                               |
|  SESSION RECORDING PROVIDES CHANGE EVIDENCE                                   |
|  ==========================================                                   |
|                                                                               |
|     +-------------------+                                                    |
|     | 1. Session Start  |  Capture initial state                             |
|     +--------+----------+                                                    |
|              |                                                                |
|              v                                                                |
|     +-------------------+                                                    |
|     | 2. Upload Current |  Record program upload from PLC                    |
|     |    Program        |  (visible in session video)                        |
|     +--------+----------+                                                    |
|              |                                                                |
|              v                                                                |
|     +-------------------+                                                    |
|     | 3. Make Changes   |  Full video of modifications                       |
|     |    (Recorded)     |  OCR captures code changes                         |
|     +--------+----------+                                                    |
|              |                                                                |
|              v                                                                |
|     +-------------------+                                                    |
|     | 4. Download       |  Confirmation dialog captured                      |
|     |    Modified Code  |  OCR indexes download event                        |
|     +--------+----------+                                                    |
|              |                                                                |
|              v                                                                |
|     +-------------------+                                                    |
|     | 5. Verify         |  Post-change testing visible                       |
|     +-------------------+                                                    |
|                                                                               |
|  EXPORTING CHANGE EVIDENCE                                                    |
|  =========================                                                    |
|                                                                               |
|  # Export screenshots at key change moments                                  |
|  wabadmin recording screenshots --session SES-2026-001-ENG001 \              |
|    --timestamps "00:05:00,00:15:00,00:30:00" \                                |
|    --output /evidence/change-12345/                                          |
|                                                                               |
|  # Export full session for archival                                          |
|  wabadmin recording export --session SES-2026-001-ENG001 \                   |
|    --format mp4 --output /archive/changes/CHG-12345.mp4                      |
|                                                                               |
+==============================================================================+
```

---

## Credential Management

### Credential Types

| Credential Type | Management Approach |
|-----------------|---------------------|
| Windows login | WALLIX auto-managed, injected via RDP |
| PLC passwords | Stored in WALLIX vault, rotated periodically |
| Software licenses | Stored on EWS, not transferred |
| Project passwords | Application-specific, documented |

### Windows Credentials for EWS

```bash
wabadmin account create EWS-SIEMENS-01/tia_engineer \
  --service RDP \
  --login "DOMAIN\\tia_engineer" \
  --credentials auto-managed \
  --auto-change-password true \
  --change-interval-days 30
```

### PLC Access Passwords

```bash
# Store PLC password in vault
wabadmin credential store PLC-S7-1500-LINE1-WRITE \
  --type password \
  --description "Line 1 PLC write access" \
  --checkout-required true \
  --checkout-duration 4h
```

### Project File Access

Recommended configuration - disable file transfer to prevent data exfiltration:

```json
{
    "subprotocols": {
        "drive_redirection": false,
        "clipboard": false
    }
}
```

### Source Code Repository Access

```
+==============================================================================+
|                    VERSION CONTROL INTEGRATION                                |
+==============================================================================+
|                                                                               |
|  RECOMMENDED: Store PLC projects in version control                          |
|  ==================================================                          |
|                                                                               |
|  +------------------------+----------------------------------------------+   |
|  | VCS Option             | Integration Approach                         |   |
|  +------------------------+----------------------------------------------+   |
|  | Git (GitLab/GitHub)    | Access via HTTPS proxy or EWS network        |   |
|  | SVN (Subversion)       | Access via EWS network connection            |   |
|  | Rockwell AssetCentre   | Native ControlLogix versioning               |   |
|  | VersionDog             | Specialized PLC version control              |   |
|  +------------------------+----------------------------------------------+   |
|                                                                               |
|  ASSETCENTRE INTEGRATION                                                      |
|  =======================                                                      |
|                                                                               |
|  Rockwell AssetCentre provides:                                              |
|  * Automatic versioning of ControlLogix projects                             |
|  * Compare functionality between versions                                    |
|  * Built-in audit trail of changes                                           |
|                                                                               |
|  WALLIX complements AssetCentre:                                             |
|  * Controls WHO can access AssetCentre                                       |
|  * Records the check-in/check-out sessions                                   |
|  * Provides approval workflow before access                                  |
|  * Links session recordings to version history                               |
|                                                                               |
+==============================================================================+
```

---

## Change Control Integration

### Version Control Workflow

```
+----------------------------------------------------------------------+
|  CHANGE WORKFLOW                                                      |
+----------------------------------------------------------------------+
|  1. Change Request --> 2. Checkout Project --> 3. Request EWS Access |
|         |                     |                        |              |
|         v                     v                        v              |
|  4. Approval       --> 5. Make Changes  --> 6. Commit Changes        |
|         |                (Recorded)              |                    |
|         v                                        v                    |
|  7. Close Ticket   <-- Link session recording to change record       |
+----------------------------------------------------------------------+
```

### Ticket-Based Access Control

```json
{
    "authorization_name": "plc-engineering-with-ticket",
    "user_group": "Control-Engineers",
    "target_group": "Production-Engineering-WS",
    "has_comment": true,
    "comment_required": true,
    "comment_pattern": "^(CHG|INC|TASK)-[0-9]{6}$",
    "comment_validation": {
        "type": "external_api",
        "url": "https://itsm.company.com/api/validate",
        "required_status": ["Approved", "In Progress"]
    }
}
```

### Approval Workflows

```bash
# Standard (single approval)
wabadmin workflow create engineering-standard \
  --approvers "OT-Supervisors" \
  --min-approvals 1 \
  --timeout-hours 8

# Critical systems (dual approval)
wabadmin workflow create engineering-critical \
  --approvers "OT-Supervisors,Safety-Team,OT-Security" \
  --min-approvals 2 \
  --timeout-hours 4

# Emergency (fast-track)
wabadmin workflow create engineering-emergency \
  --approvers "On-Call-Supervisor" \
  --min-approvals 1 \
  --timeout-minutes 30 \
  --notification-sms true
```

---

## Vendor Engineer Access

### Temporary Vendor Access

```bash
# Create vendor user with expiration
wabadmin user create vendor-siemens-jdoe \
  --profile "Vendor-External" \
  --email "jdoe@siemens.com" \
  --expiration-date "2026-03-31" \
  --mfa-required true

# Time-limited authorization
wabadmin authorization create siemens-vendor-line1 \
  --user vendor-siemens-jdoe \
  --target EWS-SIEMENS-01/RDP/vendor_access \
  --valid-from "2026-01-15" \
  --valid-until "2026-03-31" \
  --approval-required true \
  --session-recording true
```

### Supervised Vendor Sessions

```json
{
    "authorization_name": "vendor-supervised-access",
    "user_group": "External-Vendors",
    "session_supervision": {
        "required": true,
        "supervisor_group": "OT-Supervisors",
        "supervisor_must_join": true,
        "session_blocked_until_join": true
    },
    "supervisor_controls": {
        "can_terminate": true,
        "can_take_control": true
    }
}
```

### Knowledge Transfer Sessions

```bash
# Multi-user training session
wabadmin authorization create vendor-training-session \
  --user vendor-siemens-jdoe \
  --target EWS-SIEMENS-01/RDP/trainer \
  --session-recording true \
  --allow-observers true \
  --observer-group Internal-Engineers \
  --max-duration 8h

# Export for training material
wabadmin recording export --session SES-2026-001-TRAIN01 \
  --format mp4 --output /training/siemens-configuration.mp4
```

### Vendor Access Lifecycle

```
+==============================================================================+
|                    VENDOR ACCESS LIFECYCLE                                    |
+==============================================================================+
|                                                                               |
|     +------------------+                                                     |
|     | 1. Contract /    |   Legal agreement, NDA, scope definition           |
|     |    PO Created    |                                                     |
|     +--------+---------+                                                     |
|              |                                                                |
|              v                                                                |
|     +------------------+                                                     |
|     | 2. Vendor        |   Vendor provides engineer details                  |
|     |    Onboarding    |   Background check if required                      |
|     +--------+---------+                                                     |
|              |                                                                |
|              v                                                                |
|     +------------------+                                                     |
|     | 3. WALLIX Account|   Time-limited account created                      |
|     |    Creation      |   Linked to contract end date                       |
|     +--------+---------+                                                     |
|              |                                                                |
|              v                                                                |
|     +------------------+                                                     |
|     | 4. Work Sessions |   All sessions recorded                             |
|     |    (Supervised)  |   Approval required each time                       |
|     +--------+---------+                                                     |
|              |                                                                |
|              v                                                                |
|     +------------------+                                                     |
|     | 5. Project       |   Access automatically disabled                     |
|     |    Completion    |   Account deactivated on expiry                     |
|     +--------+---------+                                                     |
|              |                                                                |
|              v                                                                |
|     +------------------+                                                     |
|     | 6. Audit /       |   Session recordings archived                       |
|     |    Archive       |   Knowledge transfer documented                     |
|     +------------------+                                                     |
|                                                                               |
+==============================================================================+
```

---

## Backup and Recovery

### Backup Strategy

| Backup Type | Frequency | Retention |
|-------------|-----------|-----------|
| PLC Program Upload | Before changes | Per change ticket |
| Project File Backup | Daily | 90 days |
| EWS System Image | Weekly | 4 versions |
| Configuration Export | After changes | Permanent |

### Emergency Restore Access

```bash
wabadmin authorization create emergency-restore-access \
  --user-group Emergency-Response-Team \
  --target-group All-Engineering-Workstations \
  --approval-workflow emergency-fast-track \
  --is-critical true \
  --session-recording true \
  --max-duration 8h

# Break-glass for critical emergencies
wabadmin authorization create break-glass-engineering \
  --user-group Break-Glass-Users \
  --target-group All-Engineering-Workstations \
  --approval-required false \
  --alert-on-use "security-soc@company.com" \
  --mfa-required true
```

### Configuration Backup Procedures

```
+==============================================================================+
|                    EWS CONFIGURATION BACKUP                                   |
+==============================================================================+
|                                                                               |
|  WHAT TO BACKUP ON ENGINEERING WORKSTATIONS                                   |
|  ==========================================                                   |
|                                                                               |
|  +------------------------------+----------------------------------------+   |
|  | Component                    | Location                               |   |
|  +------------------------------+----------------------------------------+   |
|  | Software licenses            | Vendor-specific license files          |   |
|  | Communication configurations | RSLinx drivers, TIA connections        |   |
|  | Project templates            | Application template folders           |   |
|  | Custom libraries             | User-defined function blocks           |   |
|  | User preferences             | Application settings                   |   |
|  | Network configurations       | IP settings, VLAN assignments          |   |
|  +------------------------------+----------------------------------------+   |
|                                                                               |
|  BACKUP AUTOMATION                                                            |
|  =================                                                            |
|                                                                               |
|  # Example scheduled backup script                                           |
|  BACKUP_DIR=\\fileserver\ews-backups\%COMPUTERNAME%                          |
|                                                                               |
|  # Backup TIA Portal settings                                                |
|  xcopy /E /Y "%APPDATA%\Siemens" "%BACKUP_DIR%\%DATE%\Siemens\"              |
|                                                                               |
|  # Backup project templates                                                  |
|  xcopy /E /Y "C:\TIA Projects\Templates" "%BACKUP_DIR%\%DATE%\Templates\"    |
|                                                                               |
+==============================================================================+
```

---

## Compliance

### IEC 62443 Requirements

| Requirement | WALLIX Implementation |
|-------------|----------------------|
| SR 1.1 Human User ID | Individual accounts for all engineers |
| SR 1.5 Authenticator Mgmt | MFA required, password rotation automated |
| SR 2.1 Authorization | Role-based access, approval workflows |
| SR 2.8 Auditable Events | Full session recording with OCR |
| SR 2.12 Non-Repudiation | Digital signatures on recordings |

### Security Level Mapping

| SL | Engineering Access Controls |
|----|----------------------------|
| SL 1 | Individual auth, basic recording |
| SL 2 | + MFA, approval for production, time restrictions |
| SL 3 | + Dual approval, real-time monitoring, supervision |
| SL 4 | + Hardware tokens, biometric MFA, continuous monitoring |

### Report Generation

```bash
# Engineering access report
wabadmin report generate engineering-access \
  --date-range "last 30 days" \
  --output /reports/engineering-access.pdf

# Vendor access report
wabadmin report vendor-access \
  --user-group External-Vendors \
  --output /reports/vendor-access.pdf

# Compliance summary
wabadmin report compliance-summary \
  --framework IEC62443 \
  --scope engineering-access
```

### Audit Trail Components

```
+==============================================================================+
|                    ENGINEERING AUDIT TRAIL                                    |
+==============================================================================+
|                                                                               |
|  AUDIT ELEMENT          | SOURCE                                             |
|  =======================+==================================================  |
|  Who                    | WALLIX user authentication                         |
|  What                   | Session recording (video + OCR)                    |
|  When                   | Session timestamps                                 |
|  Where                  | Target device and account                          |
|  Why                    | Approval comment, ticket reference                 |
|  Authorization          | WALLIX authorization used                          |
|  Approval               | Approver identity and timestamp                    |
|                                                                               |
|  AUDIT LOG SAMPLE                                                             |
|  ================                                                             |
|                                                                               |
|  {                                                                            |
|      "event_id": "AUD-2026-001-ENG-12345",                                   |
|      "timestamp": "2026-01-15T09:30:00Z",                                    |
|      "event_type": "session_start",                                          |
|      "user": {                                                                |
|          "name": "jsmith",                                                   |
|          "groups": ["Control-Engineers", "Line1-Team"]                       |
|      },                                                                       |
|      "target": {                                                              |
|          "device": "EWS-SIEMENS-01",                                         |
|          "account": "tia_engineer"                                           |
|      },                                                                       |
|      "authorization": "siemens-plc-programming",                             |
|      "approval": {                                                            |
|          "approver": "mwilson",                                              |
|          "comment": "CHG-123456 - Line 1 motor control update"               |
|      },                                                                       |
|      "session_id": "SES-2026-001-ENG-12345",                                 |
|      "mfa_method": "TOTP"                                                    |
|  }                                                                            |
|                                                                               |
+==============================================================================+
```

---

## Troubleshooting

### PLC Connection Issues

| Issue | Solution |
|-------|----------|
| Timeout connecting | Check firewall, verify network path |
| Access denied | Verify PLC password, check protection level |
| Wrong CPU type | Update project, download hardware config |
| Adapter not found | Install/configure RSLinx or TIA driver |

**Required Ports by Vendor:**

| Vendor | Ports |
|--------|-------|
| Siemens S7 | TCP 102 |
| Rockwell | TCP 44818, UDP 2222 |
| Schneider Modbus | TCP 502 |
| ABB AC500 | TCP 1201, 1202 |

### Software Licensing

| Vendor | License Type |
|--------|--------------|
| Siemens | Floating (Automation License Manager) |
| Rockwell | FactoryTalk Activation |
| AVEVA | FlexNet license server |
| Ignition | Gateway-based |

**Session timeout configuration for license release:**

```json
{
    "session_settings": {
        "on_disconnect": "logoff",
        "disconnect_timeout_seconds": 300,
        "idle_timeout_minutes": 30
    }
}
```

### Network Latency

| Activity | Max Acceptable Latency |
|----------|----------------------|
| RDP session (usable) | < 150ms |
| RDP session (optimal) | < 50ms |
| PLC online monitoring | < 500ms |
| PLC download | < 1000ms |

**Optimization options:**

```json
{
    "service_settings": {
        "rdp_compression": true,
        "rdp_color_depth": 16,
        "rdp_experience": "modem"
    }
}
```

### Common Issues and Solutions

```
+==============================================================================+
|                    TROUBLESHOOTING GUIDE                                      |
+==============================================================================+
|                                                                               |
|  SESSION ISSUES                                                               |
|  ==============                                                               |
|                                                                               |
|  +---------------------------+-------------------------------------------+   |
|  | Symptom                   | Solution                                  |   |
|  +---------------------------+-------------------------------------------+   |
|  | Session disconnects       | Check WALLIX timeout settings             |   |
|  | frequently                | Verify network stability                  |   |
|  |                           | Increase idle timeout                     |   |
|  +---------------------------+-------------------------------------------+   |
|  | Cannot see full screen    | Adjust RDP display settings               |   |
|  |                           | Check multi-monitor configuration         |   |
|  +---------------------------+-------------------------------------------+   |
|  | Slow response time        | Enable RDP compression                    |   |
|  |                           | Reduce color depth                        |   |
|  |                           | Check network bandwidth                   |   |
|  +---------------------------+-------------------------------------------+   |
|  | Cannot copy/paste         | Drive redirection disabled (security)     |   |
|  |                           | Clipboard disabled (by design)            |   |
|  +---------------------------+-------------------------------------------+   |
|                                                                               |
|  PLC CONNECTION DIAGNOSTICS                                                   |
|  ==========================                                                   |
|                                                                               |
|  From EWS (inside WALLIX session):                                           |
|                                                                               |
|  # Verify network connectivity                                               |
|  ping <PLC-IP>                                                               |
|  tracert <PLC-IP>                                                            |
|                                                                               |
|  # Check port availability                                                   |
|  Test-NetConnection -ComputerName <PLC-IP> -Port 102                         |
|  Test-NetConnection -ComputerName <PLC-IP> -Port 44818                       |
|                                                                               |
|  # Verify PLC communication driver                                           |
|  Check RSLinx status / TIA communication test                                |
|                                                                               |
+==============================================================================+
```

---

## Quick Reference

### CLI Commands

```bash
# Device management
wabadmin device create EWS-SIEMENS-01 --domain OT-Engineering --host 10.100.10.50
wabadmin service create EWS-SIEMENS-01/RDP --protocol rdp --port 3389

# Authorization
wabadmin authorization create plc-engineering --user-group Engineers --target-group EWS

# Recording search
wabadmin recording search --query "Download" --target-group Engineering-Workstations

# Reports
wabadmin report generate engineering-access --date-range "last 30 days"
```

### Port Reference

| Vendor/Protocol | Port |
|-----------------|------|
| RDP | TCP 3389 |
| Siemens S7 | TCP 102 |
| Rockwell EtherNet/IP | TCP 44818, UDP 2222 |
| Modbus TCP | TCP 502 |
| OPC UA | TCP 4840, TCP 443 (HTTPS) |
| ABB AC500 | TCP 1201-1202 |

---

## Related Documentation

- [17 - Industrial Protocols](../17-industrial-protocols/README.md)
- [18 - SCADA/ICS Access](../18-scada-ics-access/README.md)
- [50 - Session Recording Playback](../50-session-recording-playback/README.md)
- [54 - Vendor Remote Access](../54-vendor-remote-access/README.md)
- [63 - OT Change Management](../63-ot-change-management/README.md)

## External References

- [WALLIX Documentation Portal](https://pam.wallix.one/documentation)
- [WALLIX Admin Guide](https://pam.wallix.one/documentation/admin-doc/bastion_en_administration_guide.pdf)
- [IEC 62443 Standard](https://www.iec.ch/industrial-cybersecurity)
- [NIST SP 800-82](https://csrc.nist.gov/publications/detail/sp/800-82/rev-2/final)

---

*Document Version: 1.0 | Last Updated: February 2026 | WALLIX Bastion 12.x*
