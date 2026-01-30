# 19 - Air-Gapped & Isolated Environments

## Table of Contents

1. [Understanding Air-Gapped Environments](#understanding-air-gapped-environments)
2. [Deployment Architecture](#deployment-architecture)
3. [Data Diode Integration](#data-diode-integration)
4. [Offline Operations](#offline-operations)
5. [Update & Patch Management](#update--patch-management)
6. [Credential Management](#credential-management)
7. [Audit & Compliance](#audit--compliance)

---

## Understanding Air-Gapped Environments

### Why Air-Gap?

```
+===============================================================================+
|                   AIR-GAPPED ENVIRONMENT OVERVIEW                            |
+===============================================================================+

  DEFINITION
  ==========

  An air-gapped network has NO physical or logical connection to external
  networks, including the internet and corporate IT networks.

  +------------------------------------------------------------------------+
  |                                                                        |
  |   CONNECTED ENVIRONMENT              AIR-GAPPED ENVIRONMENT            |
  |   (Standard Deployment)              (Isolated Deployment)             |
  |                                                                        |
  |   +------------------+               +------------------+              |
  |   |   Corporate IT   |               |   Corporate IT   |              |
  |   +--------+---------+               +------------------+              |
  |            |                                                           |
  |            | Network                        X  NO CONNECTION           |
  |            |                                                           |
  |   +--------+---------+               +------------------+              |
  |   |   WALLIX PAM     |               |   WALLIX PAM     |              |
  |   +--------+---------+               +--------+---------+              |
  |            |                                  |                        |
  |   +--------+---------+               +--------+---------+              |
  |   |   OT Network     |               |   OT Network     |              |
  |   +------------------+               +------------------+              |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  COMMON INDUSTRIES REQUIRING AIR-GAP
  ====================================

  +-------------------------+----------------------------------------------+
  | Industry                | Reason                                       |
  +-------------------------+----------------------------------------------+
  | Nuclear Power           | NRC regulations, safety-critical systems     |
  | Defense/Military        | Classified information protection            |
  | Critical Infrastructure | National security, grid stability            |
  | Pharmaceutical          | GxP compliance, IP protection                |
  | Financial Trading       | Market manipulation prevention               |
  | Research Labs           | IP protection, experiment integrity          |
  +-------------------------+----------------------------------------------+

  --------------------------------------------------------------------------

  CHALLENGES FOR PAM IN AIR-GAPPED ENVIRONMENTS
  ==============================================

  1. No LDAP/AD synchronization with corporate directory
  2. No external MFA services (cloud-based authenticators)
  3. No automatic updates or patches
  4. No SIEM/SOC integration (real-time)
  5. No vendor remote access
  6. Limited certificate validation (no OCSP/CRL)
  7. Time synchronization challenges

+===============================================================================+
```

---

## Deployment Architecture

### Standalone Air-Gapped Deployment

```
+===============================================================================+
|                   AIR-GAPPED WALLIX DEPLOYMENT                               |
+===============================================================================+


                     +-----------------------------------------------+
                     |              CORPORATE NETWORK                |
                     |                                               |
                     |   +---------------+    +------------------+   |
                     |   |  Corporate AD |    |  Corporate SIEM  |   |
                     |   +---------------+    +------------------+   |
                     |                                               |
                     +-----------------------------------------------+

                              |
                              |  AIR GAP (No Connection)
                              X
                              |
                              v

  +--------------------------------------------------------------------------+
  |                        AIR-GAPPED OT ZONE                                |
  |                                                                          |
  |   +------------------------------------------------------------------+   |
  |   |                      OT DMZ                                      |   |
  |   |                                                                  |   |
  |   |   +----------------------------------------------------------+   |   |
  |   |   |               WALLIX BASTION (Standalone)                |   |   |
  |   |   |                                                          |   |   |
  |   |   |   +------------------+    +------------------+           |   |   |
  |   |   |   | Local User DB    |    | Credential Vault |           |   |   |
  |   |   |   | (No LDAP sync)   |    | (Local Keys)     |           |   |   |
  |   |   |   +------------------+    +------------------+           |   |   |
  |   |   |                                                          |   |   |
  |   |   |   +------------------+    +------------------+           |   |   |
  |   |   |   | Local MFA        |    | Session Storage  |           |   |   |
  |   |   |   | (Hardware tokens)|    | (Local NAS)      |           |   |   |
  |   |   |   +------------------+    +------------------+           |   |   |
  |   |   |                                                          |   |   |
  |   |   +----------------------------------------------------------+   |   |
  |   |                                                                  |   |
  |   |   +------------------+    +------------------+                   |   |
  |   |   |  Local Syslog    |    |  NTP Server      |                   |   |
  |   |   |  (Air-gapped)    |    |  (GPS/Atomic)    |                   |   |
  |   |   +------------------+    +------------------+                   |   |
  |   |                                                                  |   |
  |   +------------------------------------------------------------------+   |
  |                                    |                                     |
  |                           +--------+--------+                            |
  |                           |    FIREWALL     |                            |
  |                           +-----------------+                            |
  |                                    |                                     |
  |   +----------------------------------------------------------------+     |
  |   |                      OT CONTROL NETWORK                        |     |
  |   |                                                                |     |
  |   |   [SCADA]    [HMI]    [Engineering WS]    [Historian]          |     |
  |   |                                                                |     |
  |   +----------------------------------------------------------------+     |
  |                                    |                                     |
  |   +----------------------------------------------------------------+     |
  |   |                      FIELD NETWORK                             |     |
  |   |                                                                |     |
  |   |   [PLC]    [RTU]    [DCS]    [Safety Systems]                  |     |
  |   |                                                                |     |
  |   +----------------------------------------------------------------+     |
  |                                                                          |
  +--------------------------------------------------------------------------+

+===============================================================================+
```

### Local Services Required

```
+===============================================================================+
|                   LOCAL SERVICES FOR AIR-GAPPED PAM                          |
+===============================================================================+

  WALLIX BASTION requires these services locally in air-gapped mode:

  +-------------------------+------------------------------------------------+
  | Service                 | Air-Gapped Solution                            |
  +-------------------------+------------------------------------------------+
  | User Directory          | Local MariaDB user database                    |
  |                         | Manual user provisioning                       |
  |                         | CSV import for bulk operations                 |
  +-------------------------+------------------------------------------------+
  | Time Synchronization    | Local NTP server with GPS receiver             |
  |                         | Or: Atomic clock reference                     |
  |                         | Critical for audit accuracy                    |
  +-------------------------+------------------------------------------------+
  | MFA / Authentication    | Hardware tokens (RSA, YubiKey TOTP)            |
  |                         | Smart cards with local validation              |
  |                         | RADIUS server in air-gapped zone               |
  +-------------------------+------------------------------------------------+
  | Certificate Authority   | Local CA for internal certificates             |
  |                         | Manual CRL distribution                        |
  |                         | No OCSP (offline validation)                   |
  +-------------------------+------------------------------------------------+
  | Log Collection          | Local syslog server (rsyslog, syslog-ng)       |
  |                         | Periodic export via secure media               |
  +-------------------------+------------------------------------------------+
  | Backup Storage          | Local NAS/SAN within air-gap                   |
  |                         | Offline backup rotation                        |
  +-------------------------+------------------------------------------------+

  --------------------------------------------------------------------------

  NETWORK ARCHITECTURE
  ====================

  +------------------------------------------------------------------------+
  |                                                                        |
  |   AIR-GAPPED ZONE                                                      |
  |   ================                                                     |
  |                                                                        |
  |   +------------+     +------------+     +------------+                 |
  |   |   NTP      |     |   RADIUS   |     |   Syslog   |                 |
  |   |   Server   |     |   Server   |     |   Server   |                 |
  |   | (GPS Sync) |     | (Local)    |     | (Local)    |                 |
  |   +-----+------+     +-----+------+     +-----+------+                 |
  |         |                  |                  |                        |
  |         +------------------+------------------+                        |
  |                            |                                           |
  |                    +-------+-------+                                   |
  |                    |    WALLIX     |                                   |
  |                    |    BASTION    |                                   |
  |                    +-------+-------+                                   |
  |                            |                                           |
  |         +------------------+------------------+                        |
  |         |                  |                  |                        |
  |   +-----+------+     +-----+------+     +-----+------+                 |
  |   |   Local    |     |   Backup   |     |   Local    |                 |
  |   |   CA       |     |   NAS      |     |   LDAP     |                 |
  |   +------------+     +------------+     | (optional) |                 |
  |                                         +------------+                 |
  |                                                                        |
  +------------------------------------------------------------------------+

+===============================================================================+
```

---

## Data Diode Integration

### One-Way Data Transfer

```
+===============================================================================+
|                   DATA DIODE ARCHITECTURE                                    |
+===============================================================================+

  A data diode allows ONE-WAY data transfer from the air-gapped network
  to external systems for audit/monitoring, while preventing any inbound
  data flow.

  +------------------------------------------------------------------------+
  |                                                                        |
  |                                                                        |
  |   +--------------------+                    +--------------------+     |
  |   |   AIR-GAPPED       |                    |   CORPORATE        |     |
  |   |   OT NETWORK       |                    |   NETWORK          |     |
  |   |                    |                    |                    |     |
  |   |  +-------------+   |    DATA DIODE      |   +-------------+  |     |
  |   |  |   WALLIX    |   |                    |   |    SIEM     |  |     |
  |   |  |   Bastion   +---+--->  [=====>]  >---+-->+   QRadar    |  |     |
  |   |  +-------------+   |    (One-way)       |   |   Splunk    |  |     |
  |   |                    |                    |   +-------------+  |     |
  |   |  +-------------+   |                    |                    |     |
  |   |  |   Syslog    +---+--->  [=====>]  >---+--> (Audit Store)|  |     |
  |   |  |   Server    |   |                    |                    |     |
  |   |  +-------------+   |                    |                    |     |
  |   |                    |                    |                    |     |
  |   +--------------------+                    +--------------------+     |
  |                                                                        |
  |        ^                                              |                |
  |        |                                              |                |
  |        +----------------  X  NO RETURN  --------------+                |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  DATA DIODE IMPLEMENTATION OPTIONS
  ==================================

  +-------------------------+------------------------------------------------+
  | Type                    | Description                                    |
  +-------------------------+------------------------------------------------+
  | Hardware Data Diode     | Physical device with optical isolation         |
  |                         | Vendors: Waterfall, Owl, Fox-IT                |
  |                         | Highest assurance level                        |
  +-------------------------+------------------------------------------------+
  | Software Data Diode     | Application-layer one-way proxy                |
  |                         | Less assurance than hardware                   |
  |                         | Lower cost option                              |
  +-------------------------+------------------------------------------------+
  | Unidirectional Gateway  | Protocol-aware one-way transfer                |
  |                         | Supports specific protocols (syslog, files)    |
  |                         | May include protocol break                     |
  +-------------------------+------------------------------------------------+

  --------------------------------------------------------------------------

  WALLIX DATA DIODE CONFIGURATION
  ================================

  WALLIX can export audit data through a data diode using:

  1. SYSLOG EXPORT (UDP)
     - Configure syslog to diode input interface
     - UDP is naturally one-way (no ACK required)
     - Format: CEF or standard syslog

  2. FILE-BASED EXPORT
     - Export recordings/logs to diode share
     - Scheduled batch transfer
     - Signed/encrypted archives

  3. DATABASE REPLICATION
     - One-way MariaDB replication
     - Read replica on external side
     - Requires diode protocol support

  Configuration Example (syslog):

  +------------------------------------------------------------------------+
  | /etc/opt/wab/wabengine/wabengine.conf                                  |
  +------------------------------------------------------------------------+
  |                                                                        |
  | [syslog]                                                               |
  | enabled = true                                                         |
  | server = 192.168.100.50    # Diode input interface                     |
  | port = 514                                                             |
  | protocol = udp             # UDP for one-way                           |
  | format = cef                                                           |
  |                                                                        |
  +------------------------------------------------------------------------+

+===============================================================================+
```

---

## Offline Operations

### User Management Without LDAP

```
+===============================================================================+
|                   OFFLINE USER MANAGEMENT                                    |
+===============================================================================+

  Without LDAP/AD synchronization, user management is performed locally:

  USER PROVISIONING OPTIONS
  =========================

  1. MANUAL CREATION
     - Create users via WALLIX Admin GUI
     - Assign to local groups
     - Set local password or certificate

  2. CSV IMPORT
     - Prepare user list in CSV format
     - Import via Admin GUI or API
     - Useful for initial deployment

  3. LOCAL LDAP
     - Deploy OpenLDAP within air-gap
     - WALLIX syncs with local LDAP
     - Separate from corporate AD

  --------------------------------------------------------------------------

  LOCAL USER DATABASE STRUCTURE
  ==============================

  +------------------------------------------------------------------------+
  |                                                                        |
  |   WALLIX Local User Hierarchy                                          |
  |   ============================                                         |
  |                                                                        |
  |   +------------------+                                                 |
  |   |  Local Admins    |  - Full WALLIX administration                   |
  |   +--------+---------+  - User/device management                       |
  |            |                                                           |
  |   +--------+---------+                                                 |
  |   |  OT Operators    |  - Session access to assigned targets           |
  |   |  (User Group)    |  - No admin rights                              |
  |   +--------+---------+                                                 |
  |            |                                                           |
  |   +--------+---------+                                                 |
  |   |  OT Engineers    |  - Engineering workstation access               |
  |   |  (User Group)    |  - PLC programming rights                       |
  |   +--------+---------+                                                 |
  |            |                                                           |
  |   +--------+---------+                                                 |
  |   |  Vendors         |  - Temporary access                             |
  |   |  (User Group)    |  - Time-limited accounts                        |
  |   +------------------+  - Require escort/approval                      |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  CSV IMPORT FORMAT
  =================

  Example CSV for user import:

  +------------------------------------------------------------------------+
  | username,full_name,email,group,password_hash,valid_until               |
  | jsmith,John Smith,jsmith@local,ot_operators,<hash>,2025-12-31          |
  | mwilson,Mary Wilson,mwilson@local,ot_engineers,<hash>,2025-12-31       |
  | vendor1,Vendor Account,vendor@ext,vendors,<hash>,2024-03-15            |
  +------------------------------------------------------------------------+

  Import via CLI:

  +------------------------------------------------------------------------+
  | # wab-admin import-users --file /path/to/users.csv --dry-run           |
  | # wab-admin import-users --file /path/to/users.csv                     |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### Hardware Token MFA

```
+===============================================================================+
|                   AIR-GAPPED MFA OPTIONS                                     |
+===============================================================================+

  Without cloud MFA services, use hardware-based authentication:

  +-------------------------+------------------------------------------------+
  | MFA Method              | Air-Gap Compatibility                          |
  +-------------------------+------------------------------------------------+
  | TOTP Hardware Token     | FULLY COMPATIBLE                               |
  | (RSA SecurID, YubiKey)  | - Local RADIUS server validates                |
  |                         | - Time-based, no network needed                |
  |                         | - Requires accurate NTP                        |
  +-------------------------+------------------------------------------------+
  | Smart Cards / PKI       | FULLY COMPATIBLE                               |
  |                         | - Local CA issues certificates                 |
  |                         | - Card reader at workstations                  |
  |                         | - No external validation needed                |
  +-------------------------+------------------------------------------------+
  | FIDO2 / WebAuthn        | PARTIALLY COMPATIBLE                           |
  |                         | - Works for local web authentication           |
  |                         | - No attestation verification                  |
  +-------------------------+------------------------------------------------+
  | SMS / Push              | NOT COMPATIBLE                                 |
  |                         | - Requires external network                    |
  |                         | - Cannot be used in air-gap                    |
  +-------------------------+------------------------------------------------+

  --------------------------------------------------------------------------

  RECOMMENDED: TOTP WITH LOCAL RADIUS
  =====================================

  Architecture:

  +------------------------------------------------------------------------+
  |                                                                        |
  |   +------------+         +------------+         +------------+         |
  |   |   User     |  1.     |   WALLIX   |  2.     |   RADIUS   |         |
  |   |   with     +-------->+   Bastion  +-------->+   Server   |         |
  |   |   Token    |  Login  |            |  Verify |   (Local)  |         |
  |   +------------+  +OTP   +-----+------+  OTP    +-----+------+         |
  |                               |                       |                |
  |                               | 3. Access             | Token DB       |
  |                               |    Granted            | (Encrypted)    |
  |                               v                       v                |
  |                         +------------+         +------------+          |
  |                         |   Target   |         |   Token    |          |
  |                         |   System   |         |   Seeds    |          |
  |                         +------------+         +------------+          |
  |                                                                        |
  +------------------------------------------------------------------------+

  Local RADIUS Servers:
  - FreeRADIUS (open source)
  - RSA Authentication Manager (commercial)
  - SafeNet Authentication Service (on-premise)

+===============================================================================+
```

---

## Update & Patch Management

### Secure Update Process

```
+===============================================================================+
|                   AIR-GAPPED UPDATE PROCEDURE                                |
+===============================================================================+

  Updates must be transferred via secure removable media with verification.

  WALLIX UPDATE WORKFLOW
  ======================

  +------------------------------------------------------------------------+
  |                                                                        |
  |   EXTERNAL NETWORK                       AIR-GAPPED NETWORK            |
  |                                                                        |
  |   1. Download                                                          |
  |   +------------------+                                                 |
  |   |  WALLIX Support  |                                                 |
  |   |  Portal          |                                                 |
  |   +--------+---------+                                                 |
  |            |                                                           |
  |            v                                                           |
  |   2. Verify Signature                                                  |
  |   +------------------+                                                 |
  |   |  Staging Server  |                                                 |
  |   |  (IT Network)    |                                                 |
  |   +--------+---------+                                                 |
  |            |                                                           |
  |            v                                                           |
  |   3. Malware Scan                                                      |
  |   +------------------+                                                 |
  |   |  AV Scanning     |                                                 |
  |   |  Station         |                                                 |
  |   +--------+---------+                                                 |
  |            |                                                           |
  |            v                                                           |
  |   4. Write to Media                                                    |
  |   +------------------+               +------------------+              |
  |   |  Secure USB      |  ==========  |  Air-Gap         |              |
  |   |  (Write-once)    | ============>|  Transfer        |              |
  |   +------------------+  Physical    |  Station         |              |
  |                         Transfer    +--------+---------+              |
  |                                              |                        |
  |                                              v                        |
  |                                     5. Verify Again                   |
  |                                     +------------------+              |
  |                                     |  Verification    |              |
  |                                     |  Station         |              |
  |                                     +--------+---------+              |
  |                                              |                        |
  |                                              v                        |
  |                                     6. Apply Update                   |
  |                                     +------------------+              |
  |                                     |  WALLIX Bastion  |              |
  |                                     +------------------+              |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  VERIFICATION CHECKLIST
  ======================

  Before applying any update in air-gapped environment:

  [ ] 1. Verify download from official WALLIX source
  [ ] 2. Check GPG signature of package
  [ ] 3. Verify SHA256 checksum matches published value
  [ ] 4. Scan with multiple AV engines
  [ ] 5. Test in non-production environment first (if available)
  [ ] 6. Review release notes for breaking changes
  [ ] 7. Backup current system before update
  [ ] 8. Document update in change management

  --------------------------------------------------------------------------

  SECURE MEDIA PROCEDURES
  =======================

  +-------------------------+------------------------------------------------+
  | Step                    | Procedure                                      |
  +-------------------------+------------------------------------------------+
  | Media Selection         | Use write-once media (DVD-R) or hardware-      |
  |                         | encrypted USB with write-protect               |
  +-------------------------+------------------------------------------------+
  | Media Preparation       | Format on clean, offline workstation           |
  |                         | Verify no autorun files                        |
  +-------------------------+------------------------------------------------+
  | Data Transfer           | Copy verified files only                       |
  |                         | Calculate checksum after write                 |
  +-------------------------+------------------------------------------------+
  | Air-Gap Crossing        | Physical hand-off with chain of custody        |
  |                         | Log media movement                             |
  +-------------------------+------------------------------------------------+
  | Media Disposal          | Physically destroy after single use            |
  |                         | No media re-use across air-gap                 |
  +-------------------------+------------------------------------------------+

+===============================================================================+
```

---

## Credential Management

### Offline Credential Rotation

```
+===============================================================================+
|                   AIR-GAPPED CREDENTIAL MANAGEMENT                           |
+===============================================================================+

  Credential rotation without external connectivity:

  AUTOMATIC ROTATION (LOCAL)
  ==========================

  WALLIX Password Manager can rotate credentials locally:

  +------------------------------------------------------------------------+
  |                                                                        |
  |   +------------------+         +------------------+                    |
  |   |  WALLIX Bastion  |         |  Target Device   |                    |
  |   |  Password Mgr    +-------->+  (PLC/HMI/SCADA) |                    |
  |   +--------+---------+         +------------------+                    |
  |            |                                                           |
  |            |  1. Generate new password                                 |
  |            |  2. Connect to target                                     |
  |            |  3. Change password on target                             |
  |            |  4. Verify new password works                             |
  |            |  5. Store new password in vault                           |
  |            |  6. Log rotation event                                    |
  |            v                                                           |
  |   +------------------+                                                 |
  |   |  Local Vault     |                                                 |
  |   |  (Encrypted)     |                                                 |
  |   +------------------+                                                 |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  ROTATION POLICIES FOR OT
  ========================

  +-------------------------+--------------------+---------------------------+
  | Account Type            | Rotation Frequency | Notes                     |
  +-------------------------+--------------------+---------------------------+
  | SCADA Admin             | 90 days            | Scheduled maintenance     |
  | HMI Operator            | 180 days           | Low risk, high impact     |
  | Engineering Account     | 90 days            | After each project        |
  | PLC/RTU Service         | Annual             | During planned outage     |
  | Vendor Temporary        | Per-access         | Rotate after each use     |
  | Break-glass Emergency   | After use          | Immediate rotation        |
  +-------------------------+--------------------+---------------------------+

  IMPORTANT: OT systems may have rotation constraints:
  - Some PLCs require restart after password change
  - Legacy systems may not support programmatic rotation
  - Coordinate with maintenance windows

  --------------------------------------------------------------------------

  BREAK-GLASS CREDENTIALS
  =======================

  Emergency access when WALLIX is unavailable:

  +------------------------------------------------------------------------+
  |                                                                        |
  |   BREAK-GLASS PROCEDURE                                                |
  |   =====================                                                |
  |                                                                        |
  |   1. STORAGE                                                           |
  |      - Credentials stored in sealed, tamper-evident envelopes          |
  |      - Locked in physical safe (dual-control if possible)              |
  |      - Separate safe from IT systems                                   |
  |                                                                        |
  |   2. ACCESS                                                            |
  |      - Two authorized personnel required                               |
  |      - Document reason, time, systems accessed                         |
  |      - Notify security team immediately                                |
  |                                                                        |
  |   3. POST-USE                                                          |
  |      - Rotate ALL used credentials immediately                         |
  |      - Prepare new sealed envelopes                                    |
  |      - Review access logs                                              |
  |      - Incident report required                                        |
  |                                                                        |
  |   Storage Example:                                                     |
  |   +--------------------+                                               |
  |   |  SAFE (Fireproof)  |                                               |
  |   |                    |                                               |
  |   |  [Envelope: SCADA] |  <- Tamper-evident seal with date             |
  |   |  [Envelope: PLC-1] |  <- Serial number logged                      |
  |   |  [Envelope: PLC-2] |  <- Dual signature required to open           |
  |   |  [Envelope: HMI]   |                                               |
  |   |                    |                                               |
  |   +--------------------+                                               |
  |                                                                        |
  +------------------------------------------------------------------------+

+===============================================================================+
```

---

## Audit & Compliance

### Audit Data Export

```
+===============================================================================+
|                   AIR-GAPPED AUDIT MANAGEMENT                                |
+===============================================================================+

  Maintaining compliance in air-gapped environments:

  AUDIT DATA FLOW
  ===============

  +------------------------------------------------------------------------+
  |                                                                        |
  |   AIR-GAPPED ZONE                                                      |
  |                                                                        |
  |   +------------------+                                                 |
  |   |  WALLIX Bastion  |                                                 |
  |   +--------+---------+                                                 |
  |            |                                                           |
  |            v                                                           |
  |   +------------------+         +------------------+                    |
  |   |  Session         |         |  Audit Logs      |                    |
  |   |  Recordings      |         |  (Syslog)        |                    |
  |   +--------+---------+         +--------+---------+                    |
  |            |                            |                              |
  |            v                            v                              |
  |   +------------------------------------------+                         |
  |   |           Local Archive Server           |                         |
  |   |  - Compressed recordings                 |                         |
  |   |  - Signed log files                      |                         |
  |   |  - Retention per policy                  |                         |
  |   +--------------------+---------------------+                         |
  |                        |                                               |
  |                        v                                               |
  |               EXPORT OPTIONS                                           |
  |               ==============                                           |
  |                        |                                               |
  |         +--------------+--------------+                                |
  |         |              |              |                                |
  |         v              v              v                                |
  |   +-----------+  +-----------+  +-----------+                          |
  |   | Data      |  | Secure    |  | Manual    |                          |
  |   | Diode     |  | Media     |  | Review    |                          |
  |   | (Real-    |  | Export    |  | Station   |                          |
  |   |  time)    |  | (Batch)   |  | (On-site) |                          |
  |   +-----------+  +-----------+  +-----------+                          |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  COMPLIANCE MAPPING
  ==================

  +-------------------------+------------------------------------------------+
  | Requirement             | Air-Gapped Implementation                      |
  +-------------------------+------------------------------------------------+
  | IEC 62443 SR 2.8        | Local audit logging with integrity             |
  | (Auditable Events)      | Tamper-evident log storage                     |
  +-------------------------+------------------------------------------------+
  | IEC 62443 SR 2.9        | Local time source (GPS/atomic)                 |
  | (Audit Storage)         | Encrypted archive with retention               |
  +-------------------------+------------------------------------------------+
  | NERC CIP-007-6 R5       | Local log review process                       |
  | (System Access Control) | Periodic export for analysis                   |
  +-------------------------+------------------------------------------------+
  | NIS2 Article 21         | Batch export via secure media                  |
  | (Incident Handling)     | Data diode for real-time (if approved)         |
  +-------------------------+------------------------------------------------+

  --------------------------------------------------------------------------

  LOG INTEGRITY VERIFICATION
  ==========================

  Ensure audit logs haven't been tampered:

  +------------------------------------------------------------------------+
  |                                                                        |
  |   1. HASH CHAIN                                                        |
  |      - Each log entry includes hash of previous entry                  |
  |      - Tampering breaks the chain                                      |
  |      - WALLIX supports this natively                                   |
  |                                                                        |
  |   2. DIGITAL SIGNATURES                                                |
  |      - Daily log files signed with WALLIX private key                  |
  |      - Verify signature before analysis                                |
  |      - Keep public key separately                                      |
  |                                                                        |
  |   3. WRITE-ONCE STORAGE                                                |
  |      - Archive to WORM (Write Once Read Many) media                    |
  |      - Or: Immutable storage (if available)                            |
  |                                                                        |
  |   Verification Command:                                                |
  |   $ wab-admin verify-logs --start 2024-01-01 --end 2024-01-31          |
  |                                                                        |
  +------------------------------------------------------------------------+

+===============================================================================+
```

---

## Next Steps

Continue to [20 - IEC 62443 Compliance](../20-iec62443-compliance/README.md) for detailed compliance mapping.
