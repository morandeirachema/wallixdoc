# 51 - Offline and Sneakernet Operations

## Table of Contents

1. [Offline Operations Overview](#offline-operations-overview)
2. [Air-Gapped Architecture](#air-gapped-architecture)
3. [Offline Credential Cache](#offline-credential-cache)
4. [Sneakernet Credential Updates](#sneakernet-credential-updates)
5. [Offline User Management](#offline-user-management)
6. [Offline License Management](#offline-license-management)
7. [Patch and Update Procedures](#patch-and-update-procedures)
8. [Offline Audit Log Export](#offline-audit-log-export)
9. [Emergency Access Procedures](#emergency-access-procedures)
10. [Data Diode Integration](#data-diode-integration)
11. [Time Synchronization](#time-synchronization)

---

## Offline Operations Overview

### When and Why Offline Operations Are Needed

```
+==============================================================================+
|                   OFFLINE OPERATIONS OVERVIEW                                 |
+==============================================================================+

  WHY AIR-GAPPED PAM?
  ===================

  Air-gapped WALLIX Bastion deployments are required when:

  +------------------------------------------------------------------------+
  | Scenario                        | Driver                                |
  +---------------------------------+---------------------------------------+
  | Nuclear power facilities        | NRC 10 CFR 73.54, safety isolation    |
  | Defense/classified networks     | DoD STIGs, air-gap mandates           |
  | Critical infrastructure (grid)  | NERC CIP-005, network segmentation    |
  | Oil & gas remote sites          | Physical isolation, satellite-only    |
  | Pharmaceutical manufacturing    | GxP requirements, validated systems   |
  | Financial trading systems       | Market manipulation prevention        |
  | Research laboratories           | IP protection, experiment integrity   |
  +---------------------------------+---------------------------------------+

  --------------------------------------------------------------------------

  CHALLENGES IN OFFLINE ENVIRONMENTS
  ===================================

  +------------------------------------------------------------------------+
  |                                                                        |
  |   CONNECTIVITY CHALLENGES             OPERATIONAL CHALLENGES           |
  |   ======================             =======================           |
  |                                                                        |
  |   * No LDAP/AD synchronization       * Manual user provisioning        |
  |   * No cloud MFA providers           * Delayed credential updates      |
  |   * No SIEM real-time streaming      * Batch audit log export          |
  |   * No automatic updates             * Manual patch management         |
  |   * No OCSP/CRL validation           * Local CA required               |
  |   * No NTP over internet             * GPS/atomic clock needed         |
  |   * No vendor remote support         * On-site expertise required      |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  OFFLINE OPERATION MODES
  =======================

  +------------------------------------------------------------------------+
  |                                                                        |
  |   MODE 1: FULLY AIR-GAPPED                                             |
  |   =========================                                            |
  |                                                                        |
  |   * No network connection whatsoever                                   |
  |   * All updates via physical media                                     |
  |   * Audit logs exported via sneakernet                                 |
  |   * Credentials managed locally                                        |
  |                                                                        |
  |   MODE 2: DATA DIODE (ONE-WAY)                                         |
  |   ============================                                         |
  |                                                                        |
  |   * Outbound-only data flow                                            |
  |   * Real-time audit streaming                                          |
  |   * Inbound updates via physical media                                 |
  |   * Unidirectional log export                                          |
  |                                                                        |
  |   MODE 3: INTERMITTENT CONNECTIVITY                                    |
  |   =================================                                    |
  |                                                                        |
  |   * Scheduled connection windows                                       |
  |   * Batch synchronization during windows                               |
  |   * Offline caching between connections                                |
  |   * Common in remote OT sites                                          |
  |                                                                        |
  +------------------------------------------------------------------------+

+==============================================================================+
```

### Regulatory Context

| Standard | Requirement | Offline Relevance |
|----------|-------------|-------------------|
| IEC 62443-3-3 | SR 5.1 - Network segmentation | Zone isolation |
| NERC CIP-005 | Electronic Security Perimeter | Air-gap boundary |
| NRC 10 CFR 73.54 | Cyber security for nuclear | Complete isolation |
| NIST 800-82 | ICS security zones | DMZ requirements |
| NIS2 Directive | Critical infrastructure | Network separation |

---

## Air-Gapped Architecture

### Complete Air-Gap Topology

```
+==============================================================================+
|                   AIR-GAPPED WALLIX DEPLOYMENT                                |
+==============================================================================+


                    +---------------------------------------------------+
                    |              CORPORATE NETWORK (IT)               |
                    |                                                   |
                    |  +-------------+  +-------------+  +------------+ |
                    |  | Corp LDAP/AD|  | Corp SIEM   |  | Patch Mgmt | |
                    |  +-------------+  +-------------+  +------------+ |
                    |                                                   |
                    +---------------------------------------------------+
                                            |
                                            X  AIR GAP
                                            X  (No Connection)
                                            |
  +=========================================================================+
  |                        SECURE TRANSFER ZONE                              |
  |                                                                          |
  |  +---------------------+                    +---------------------+      |
  |  |    DATA EXPORT      |                    |    DATA IMPORT      |      |
  |  |    STATION          |  ===== USB =====>  |    STATION          |      |
  |  | (Corporate side)    |  Physical Media    | (OT side)           |      |
  |  +---------------------+                    +---------------------+      |
  |                                                                          |
  |  * Malware scanning      <-- PROCEDURES -->  * Checksum verify          |
  |  * Encryption            <-- PROCEDURES -->  * Signature verify         |
  |  * Chain of custody      <-- PROCEDURES -->  * Integrity check          |
  |                                                                          |
  +=========================================================================+
                                            |
                                            v
  +=========================================================================+
  |                         AIR-GAPPED OT ZONE                               |
  |                                                                          |
  |   +---------------------------------------------------------------+     |
  |   |                     OT DMZ (Level 3.5)                        |     |
  |   |                                                               |     |
  |   |   +-------------------------------------------------------+   |     |
  |   |   |              WALLIX BASTION (HA Cluster)              |   |     |
  |   |   |                                                       |   |     |
  |   |   |  +------------------+    +------------------+         |   |     |
  |   |   |  |    Node 1        |    |    Node 2        |         |   |     |
  |   |   |  |  (Active)        |<-->|  (Passive)       |         |   |     |
  |   |   |  +------------------+    +------------------+         |   |     |
  |   |   |                    [VIP]                              |   |     |
  |   |   +-------------------------------------------------------+   |     |
  |   |                                                               |     |
  |   |   +--------------+  +--------------+  +--------------+        |     |
  |   |   |   Local NTP  |  |  Local LDAP  |  | Local Syslog |        |     |
  |   |   |  (GPS Sync)  |  |  (Optional)  |  |   Server     |        |     |
  |   |   +--------------+  +--------------+  +--------------+        |     |
  |   |                                                               |     |
  |   +---------------------------------------------------------------+     |
  |                                    |                                     |
  |                           +--------+--------+                            |
  |                           |    FIREWALL     |                            |
  |                           |  (Layer 3/4)    |                            |
  |                           +-----------------+                            |
  |                                    |                                     |
  |   +---------------------------------------------------------------+     |
  |   |                  OT CONTROL NETWORK (Level 2)                 |     |
  |   |                                                               |     |
  |   |   [SCADA]    [HMI]    [Historian]    [Engineering WS]         |     |
  |   |                                                               |     |
  |   +---------------------------------------------------------------+     |
  |                                    |                                     |
  |   +---------------------------------------------------------------+     |
  |   |                    FIELD NETWORK (Level 1)                    |     |
  |   |                                                               |     |
  |   |   [PLC]    [RTU]    [DCS Controller]    [Safety PLC]          |     |
  |   |                                                               |     |
  |   +---------------------------------------------------------------+     |
  |                                                                          |
  +=========================================================================+

+==============================================================================+
```

### Local Infrastructure Requirements

```
+==============================================================================+
|                   LOCAL SERVICES FOR AIR-GAPPED PAM                          |
+==============================================================================+

  REQUIRED LOCAL SERVICES
  =======================

  +------------------------------------------------------------------------+
  | Service          | Purpose                   | Air-Gapped Solution     |
  +------------------+---------------------------+-------------------------+
  | Time Sync        | Audit accuracy, MFA       | GPS NTP or atomic clock |
  | User Directory   | Authentication            | Local PostgreSQL + CSV  |
  | MFA/2FA          | Strong authentication     | Hardware TOTP tokens    |
  | Certificate Auth | PKI validation            | Local CA, manual CRL    |
  | Log Collection   | Audit trail               | Local syslog server     |
  | Backup Storage   | Data protection           | Local NAS within zone   |
  +------------------+---------------------------+-------------------------+

  --------------------------------------------------------------------------

  INFRASTRUCTURE LAYOUT
  =====================

  +------------------------------------------------------------------------+
  |                                                                        |
  |   AIR-GAPPED INFRASTRUCTURE                                            |
  |   ==========================                                           |
  |                                                                        |
  |   +------------+   +------------+   +------------+   +------------+   |
  |   |  GPS NTP   |   |   RADIUS   |   |  Syslog    |   |  Local CA  |   |
  |   |  Server    |   |   Server   |   |  Collector |   |  (PKI)     |   |
  |   | 10.50.1.10 |   | 10.50.1.11 |   | 10.50.1.12 |   | 10.50.1.13 |   |
  |   +-----+------+   +-----+------+   +-----+------+   +-----+------+   |
  |         |               |               |               |             |
  |         +---------------+-------+-------+---------------+             |
  |                                 |                                     |
  |                         +-------+-------+                             |
  |                         |    SWITCH     |                             |
  |                         +-------+-------+                             |
  |                                 |                                     |
  |                 +---------------+---------------+                     |
  |                 |                               |                     |
  |          +------+------+                 +------+------+              |
  |          |   WALLIX    |                 |   WALLIX    |              |
  |          |   Node 1    |<-- Heartbeat -->|   Node 2    |              |
  |          | 10.50.1.20  |                 | 10.50.1.21  |              |
  |          +------+------+                 +------+------+              |
  |                 |                               |                     |
  |                 +---------------+---------------+                     |
  |                                 |                                     |
  |                         +-------+-------+                             |
  |                         |  Virtual IP   |                             |
  |                         |  10.50.1.100  |                             |
  |                         +---------------+                             |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  NETWORK ADDRESSING (EXAMPLE)
  ============================

  +------------------------------------------------------------------------+
  | Network          | CIDR           | Purpose                            |
  +------------------+----------------+------------------------------------+
  | OT DMZ           | 10.50.1.0/24   | WALLIX, local services             |
  | Control Network  | 10.50.2.0/24   | SCADA, HMI, Historians             |
  | Field Network    | 10.50.3.0/24   | PLCs, RTUs, Safety systems         |
  | Management       | 10.50.0.0/24   | Out-of-band management             |
  +------------------+----------------+------------------------------------+

+==============================================================================+
```

---

## Offline Credential Cache

### How Credentials Are Cached Locally

```
+==============================================================================+
|                   OFFLINE CREDENTIAL CACHE                                    |
+==============================================================================+

  CACHE ARCHITECTURE
  ==================

  +------------------------------------------------------------------------+
  |                                                                        |
  |   WALLIX BASTION                                                       |
  |   ==============                                                       |
  |                                                                        |
  |   +----------------------------------------------------------------+  |
  |   |                    CREDENTIAL VAULT                            |  |
  |   |                                                                |  |
  |   |   +------------------------+  +------------------------+       |  |
  |   |   |     PRIMARY STORE      |  |     CACHE STORE        |       |  |
  |   |   |                        |  |                        |       |  |
  |   |   |  * Master credentials  |  |  * Cached passwords    |       |  |
  |   |   |  * Full history        |  |  * Last known good     |       |  |
  |   |   |  * All metadata        |  |  * TTL-based expiry    |       |  |
  |   |   |                        |  |  * Offline access      |       |  |
  |   |   +------------------------+  +------------------------+       |  |
  |   |                                                                |  |
  |   |   +--------------------------------------------------------+   |  |
  |   |   |                 ENCRYPTION LAYER                       |   |  |
  |   |   |                                                        |   |  |
  |   |   |   * AES-256-GCM encryption                             |   |  |
  |   |   |   * Key derivation: Argon2ID                           |   |  |
  |   |   |   * Hardware Security Module (optional)                |   |  |
  |   |   |   * Local master key protected                         |   |  |
  |   |   +--------------------------------------------------------+   |  |
  |   |                                                                |  |
  |   +----------------------------------------------------------------+  |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  CACHE CONFIGURATION
  ===================

  Configuration file: /etc/opt/wab/wabengine/offline_cache.conf

  +------------------------------------------------------------------------+
  | # Offline credential cache settings                                    |
  | [offline_cache]                                                        |
  | enabled = true                                                         |
  | cache_duration_days = 90                                               |
  | max_cached_accounts = 1000                                             |
  | cache_refresh_interval = 3600                                          |
  | encrypt_cache = true                                                   |
  |                                                                        |
  | # Cache location (encrypted)                                           |
  | cache_path = /var/lib/wallix/cache/credentials.db                      |
  |                                                                        |
  | # Automatic cache population                                           |
  | auto_populate = true                                                   |
  | populate_on_checkout = true                                            |
  | populate_on_rotation = true                                            |
  |                                                                        |
  | # Offline access settings                                              |
  | allow_offline_checkout = true                                          |
  | offline_checkout_duration = 86400                                      |
  | require_local_mfa = true                                               |
  +------------------------------------------------------------------------+

+==============================================================================+
```

### Cache Duration and Refresh

```
+==============================================================================+
|                   CACHE LIFECYCLE MANAGEMENT                                  |
+==============================================================================+

  CACHE REFRESH WORKFLOW
  ======================

  +------------------------------------------------------------------------+
  |                                                                        |
  |   CREDENTIAL UPDATE                                                    |
  |         |                                                              |
  |         v                                                              |
  |   +-------------------+                                                |
  |   | Rotation Occurs   |  (Local rotation or sneakernet import)         |
  |   +--------+----------+                                                |
  |            |                                                           |
  |            v                                                           |
  |   +-------------------+                                                |
  |   | Update Primary    |                                                |
  |   | Vault Store       |                                                |
  |   +--------+----------+                                                |
  |            |                                                           |
  |            v                                                           |
  |   +-------------------+                                                |
  |   | Propagate to      |                                                |
  |   | Cache Store       |                                                |
  |   +--------+----------+                                                |
  |            |                                                           |
  |            v                                                           |
  |   +-------------------+                                                |
  |   | Update TTL and    |                                                |
  |   | Metadata          |                                                |
  |   +-------------------+                                                |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  CACHE POLICIES BY ACCOUNT TYPE
  ==============================

  +------------------------------------------------------------------------+
  | Account Type         | Cache Duration | Refresh Trigger | Priority     |
  +----------------------+----------------+-----------------+--------------+
  | Emergency/Break-glass| 365 days       | Annual review   | Critical     |
  | SCADA Admin          | 90 days        | Post-rotation   | High         |
  | Service Accounts     | 180 days       | Quarterly       | Medium       |
  | Vendor Temporary     | 7 days         | Per-engagement  | Low          |
  | Operator Accounts    | 90 days        | Post-rotation   | High         |
  +----------------------+----------------+-----------------+--------------+

  --------------------------------------------------------------------------

  CACHE STATUS COMMANDS
  =====================

  +------------------------------------------------------------------------+
  | # View cache status                                                    |
  | wabadmin cache status                                                  |
  |                                                                        |
  | # Example output:                                                      |
  | # Cache Status: ACTIVE                                                 |
  | # Total Cached Credentials: 847                                        |
  | # Cache Size: 12.4 MB                                                  |
  | # Last Refresh: 2026-01-31 02:00:00 UTC                                |
  | # Next Scheduled Refresh: 2026-02-01 02:00:00 UTC                      |
  | # Expiring Soon (7 days): 23 credentials                               |
  |                                                                        |
  | # View specific credential cache status                                |
  | wabadmin cache show --account "root@scada-server"                      |
  |                                                                        |
  | # Example output:                                                      |
  | # Account: root@scada-server                                           |
  | # Cache Status: VALID                                                  |
  | # Cached Since: 2025-12-15 14:30:00 UTC                                |
  | # Expires: 2026-03-15 14:30:00 UTC                                     |
  | # Last Used: 2026-01-28 09:15:00 UTC                                   |
  | # Rotation Count Since Cache: 1                                        |
  +------------------------------------------------------------------------+

+==============================================================================+
```

### Offline vs Connected Capabilities

```
+==============================================================================+
|                   OFFLINE CAPABILITY MATRIX                                   |
+==============================================================================+

  WHAT WORKS OFFLINE
  ==================

  +------------------------------------------------------------------------+
  | Feature                          | Offline | Notes                      |
  +----------------------------------+---------+----------------------------+
  | Session establishment (cached)   | YES     | Cached credentials only    |
  | Session recording                | YES     | Local storage              |
  | Local user authentication        | YES     | Local DB + hardware MFA    |
  | Credential checkout (cached)     | YES     | Time-limited               |
  | Audit logging                    | YES     | Local syslog               |
  | Local password rotation          | YES     | To cached targets          |
  | Break-glass access               | YES     | Emergency procedures       |
  | Session monitoring               | YES     | Live view within network   |
  +----------------------------------+---------+----------------------------+

  --------------------------------------------------------------------------

  WHAT REQUIRES CONNECTIVITY (OR SNEAKERNET)
  ==========================================

  +------------------------------------------------------------------------+
  | Feature                          | Workaround                          |
  +----------------------------------+-------------------------------------+
  | LDAP/AD user sync                | CSV import via sneakernet           |
  | External MFA validation          | Use hardware TOTP tokens locally    |
  | License activation               | Offline activation procedure        |
  | Software updates                 | Media-based update procedure        |
  | SIEM streaming                   | Data diode or batch export          |
  | External CA validation           | Local CA with manual CRL            |
  | Credential sync from master      | Sneakernet credential import        |
  | Remote vendor access             | Escort with local authentication    |
  +----------------------------------+-------------------------------------+

  --------------------------------------------------------------------------

  GRACEFUL DEGRADATION
  ====================

  +------------------------------------------------------------------------+
  |                                                                        |
  |   When connectivity is lost unexpectedly:                              |
  |                                                                        |
  |   1. WALLIX continues with cached credentials                          |
  |   2. Local authentication remains functional                           |
  |   3. Session recording continues to local storage                      |
  |   4. Audit events queue locally for later export                       |
  |   5. Password rotation continues for reachable targets                 |
  |                                                                        |
  |   Alert triggers:                                                      |
  |   * Cache credentials expiring within 14 days                          |
  |   * Audit log local storage > 80% full                                 |
  |   * License approaching expiration                                     |
  |                                                                        |
  +------------------------------------------------------------------------+

+==============================================================================+
```

---

## Sneakernet Credential Updates

### Export Credentials from Connected Site

```
+==============================================================================+
|                   CREDENTIAL EXPORT PROCEDURE                                 |
+==============================================================================+

  EXPORT WORKFLOW
  ===============

  +------------------------------------------------------------------------+
  |                                                                        |
  |   CONNECTED SITE (Source)                                              |
  |   =======================                                              |
  |                                                                        |
  |   +------------------+                                                 |
  |   |  WALLIX Bastion  |                                                 |
  |   |  (Primary)       |                                                 |
  |   +--------+---------+                                                 |
  |            |                                                           |
  |            | 1. Export command                                         |
  |            v                                                           |
  |   +------------------+                                                 |
  |   | Credential       |                                                 |
  |   | Export Package   |                                                 |
  |   | (Encrypted)      |                                                 |
  |   +--------+---------+                                                 |
  |            |                                                           |
  |            | 2. Sign package                                           |
  |            v                                                           |
  |   +------------------+                                                 |
  |   | Signed + Encrypt |                                                 |
  |   | .wabcred file    |                                                 |
  |   +--------+---------+                                                 |
  |            |                                                           |
  |            | 3. Write to secure media                                  |
  |            v                                                           |
  |   +------------------+                                                 |
  |   | Encrypted USB    |  <=== Physical transfer to air-gapped site     |
  |   | (Write-protect)  |                                                 |
  |   +------------------+                                                 |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  EXPORT COMMANDS
  ===============

  Step 1: Generate credential export package

  +------------------------------------------------------------------------+
  | # Export credentials for specific target group                         |
  | wabadmin credentials export \                                          |
  |   --target-group "air-gapped-site-c" \                                 |
  |   --output /secure-export/credentials-$(date +%Y%m%d).wabcred \        |
  |   --encrypt \                                                          |
  |   --passphrase-file /etc/wallix/export-key.txt \                       |
  |   --include-history 3                                                  |
  |                                                                        |
  | # Example output:                                                      |
  | # Exporting credentials...                                             |
  | # Target group: air-gapped-site-c                                      |
  | # Accounts selected: 47                                                |
  | # Including password history: 3 versions                               |
  | # Encrypting with AES-256-GCM...                                       |
  | # Export complete: credentials-20260131.wabcred                        |
  | # SHA256: 8f4a2b...c9d1e0                                              |
  +------------------------------------------------------------------------+

  Step 2: Sign the export package

  +------------------------------------------------------------------------+
  | # Sign export with WALLIX signing key                                  |
  | wabadmin credentials sign \                                            |
  |   --input /secure-export/credentials-20260131.wabcred \                |
  |   --key /etc/wallix/signing-key.pem \                                  |
  |   --output /secure-export/credentials-20260131.wabcred.sig             |
  |                                                                        |
  | # Generate checksum manifest                                           |
  | sha256sum /secure-export/credentials-20260131.wabcred \                |
  |   > /secure-export/credentials-20260131.sha256                         |
  +------------------------------------------------------------------------+

  Step 3: Create transfer package

  +------------------------------------------------------------------------+
  | # Create complete transfer package                                     |
  | mkdir /secure-export/transfer-$(date +%Y%m%d)                          |
  |                                                                        |
  | cp /secure-export/credentials-20260131.wabcred \                       |
  |    /secure-export/credentials-20260131.wabcred.sig \                   |
  |    /secure-export/credentials-20260131.sha256 \                        |
  |    /secure-export/transfer-20260131/                                   |
  |                                                                        |
  | # Include verification public key                                      |
  | cp /etc/wallix/signing-key-public.pem \                                |
  |    /secure-export/transfer-20260131/                                   |
  |                                                                        |
  | # Create manifest                                                      |
  | cat > /secure-export/transfer-20260131/MANIFEST.txt << 'EOF'           |
  | Transfer Package: Credential Update                                    |
  | Date: 2026-01-31                                                       |
  | Source: wallix-primary.corp.example.com                                |
  | Target: air-gapped-site-c                                              |
  | Accounts: 47                                                           |
  | Authorized by: John Smith (Security Admin)                             |
  | Ticket: CHG-2026-0131-001                                              |
  | EOF                                                                    |
  +------------------------------------------------------------------------+

+==============================================================================+
```

### Secure Transfer Procedures

```
+==============================================================================+
|                   SECURE MEDIA TRANSFER                                       |
+==============================================================================+

  APPROVED TRANSFER MEDIA
  =======================

  +------------------------------------------------------------------------+
  | Media Type                | Security Level | Use Case                  |
  +---------------------------+----------------+---------------------------+
  | Hardware-encrypted USB    | High           | Standard transfers        |
  | (IronKey, Apricorn)       |                |                           |
  +---------------------------+----------------+---------------------------+
  | Write-once optical        | Very High      | High-security facilities  |
  | (DVD-R, BD-R)             |                | Tamper-evident            |
  +---------------------------+----------------+---------------------------+
  | Data diode transfer       | Highest        | Real-time approved        |
  | (Waterfall, Owl)          |                | One-way only              |
  +---------------------------+----------------+---------------------------+

  --------------------------------------------------------------------------

  TRANSFER CHAIN OF CUSTODY
  =========================

  +------------------------------------------------------------------------+
  |                                                                        |
  |   CHAIN OF CUSTODY LOG                                                 |
  |   ====================                                                 |
  |                                                                        |
  |   Transfer ID: TRF-2026-0131-001                                       |
  |   Package: credentials-20260131.wabcred                                |
  |   Classification: CONFIDENTIAL                                         |
  |                                                                        |
  |   +------+----------+------------------+-------------+---------------+ |
  |   | Step | DateTime | Person           | Action      | Signature     | |
  |   +------+----------+------------------+-------------+---------------+ |
  |   | 1    | 09:00    | J. Smith (Admin) | Created     | [signature]   | |
  |   | 2    | 09:15    | J. Smith         | Encrypted   | [signature]   | |
  |   | 3    | 09:30    | M. Jones (Sec)   | Verified    | [signature]   | |
  |   | 4    | 10:00    | M. Jones         | Sealed USB  | [signature]   | |
  |   | 5    | 10:15    | Courier (ID: 42) | In Transit  | [signature]   | |
  |   | 6    | 14:00    | A. Wilson (OT)   | Received    | [signature]   | |
  |   | 7    | 14:15    | A. Wilson        | Verified    | [signature]   | |
  |   | 8    | 14:30    | A. Wilson        | Imported    | [signature]   | |
  |   | 9    | 15:00    | A. Wilson        | Media Destr.| [signature]   | |
  |   +------+----------+------------------+-------------+---------------+ |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  MEDIA PREPARATION SCRIPT
  ========================

  +------------------------------------------------------------------------+
  | #!/bin/bash                                                            |
  | # prepare-transfer-media.sh                                            |
  | # Prepare secure USB for credential transfer                           |
  |                                                                        |
  | set -euo pipefail                                                      |
  |                                                                        |
  | USB_DEVICE="${1:-/dev/sdb}"                                            |
  | MOUNT_POINT="/mnt/secure-transfer"                                     |
  | TRANSFER_DIR="${2:-/secure-export/transfer-$(date +%Y%m%d)}"           |
  |                                                                        |
  | # Verify device is removable                                           |
  | if [ "$(cat /sys/block/$(basename $USB_DEVICE)/removable)" != "1" ]; then
  |     echo "ERROR: $USB_DEVICE is not a removable device"                |
  |     exit 1                                                             |
  | fi                                                                     |
  |                                                                        |
  | # Format with encryption                                               |
  | echo "Formatting $USB_DEVICE with LUKS encryption..."                  |
  | cryptsetup luksFormat --type luks2 $USB_DEVICE                         |
  | cryptsetup luksOpen $USB_DEVICE secure-transfer                        |
  | mkfs.ext4 /dev/mapper/secure-transfer                                  |
  |                                                                        |
  | # Mount and copy                                                       |
  | mkdir -p $MOUNT_POINT                                                  |
  | mount /dev/mapper/secure-transfer $MOUNT_POINT                         |
  | cp -r $TRANSFER_DIR/* $MOUNT_POINT/                                    |
  |                                                                        |
  | # Generate on-media checksum                                           |
  | cd $MOUNT_POINT                                                        |
  | sha256sum * > SHA256SUMS                                               |
  |                                                                        |
  | # Sync and unmount                                                     |
  | sync                                                                   |
  | umount $MOUNT_POINT                                                    |
  | cryptsetup luksClose secure-transfer                                   |
  |                                                                        |
  | echo "Transfer media prepared successfully"                            |
  | echo "LUKS passphrase must be communicated separately"                 |
  +------------------------------------------------------------------------+

+==============================================================================+
```

### Import Credentials to Air-Gapped Site

```
+==============================================================================+
|                   CREDENTIAL IMPORT PROCEDURE                                 |
+==============================================================================+

  IMPORT WORKFLOW
  ===============

  +------------------------------------------------------------------------+
  |                                                                        |
  |   AIR-GAPPED SITE (Destination)                                        |
  |   =============================                                        |
  |                                                                        |
  |   +------------------+                                                 |
  |   | Encrypted USB    |  <== Physical media received                    |
  |   | from transfer    |                                                 |
  |   +--------+---------+                                                 |
  |            |                                                           |
  |            | 1. Mount on isolated verification station                 |
  |            v                                                           |
  |   +------------------+                                                 |
  |   | Verify checksums |                                                 |
  |   | and signature    |                                                 |
  |   +--------+---------+                                                 |
  |            |                                                           |
  |            | 2. Malware scan (isolated scanner)                        |
  |            v                                                           |
  |   +------------------+                                                 |
  |   | Transfer to      |                                                 |
  |   | import station   |                                                 |
  |   +--------+---------+                                                 |
  |            |                                                           |
  |            | 3. Import to WALLIX                                       |
  |            v                                                           |
  |   +------------------+                                                 |
  |   | WALLIX Bastion   |                                                 |
  |   | (Air-gapped)     |                                                 |
  |   +------------------+                                                 |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  VERIFICATION COMMANDS
  =====================

  Step 1: Mount and verify package

  +------------------------------------------------------------------------+
  | # Mount encrypted USB                                                  |
  | cryptsetup luksOpen /dev/sdb secure-transfer                           |
  | mount /dev/mapper/secure-transfer /mnt/import                          |
  |                                                                        |
  | # Verify checksums                                                     |
  | cd /mnt/import                                                         |
  | sha256sum -c SHA256SUMS                                                |
  |                                                                        |
  | # Expected output:                                                     |
  | # credentials-20260131.wabcred: OK                                     |
  | # credentials-20260131.wabcred.sig: OK                                 |
  | # signing-key-public.pem: OK                                           |
  | # MANIFEST.txt: OK                                                     |
  +------------------------------------------------------------------------+

  Step 2: Verify digital signature

  +------------------------------------------------------------------------+
  | # Verify signature using provided public key                           |
  | wabadmin credentials verify-signature \                                |
  |   --input /mnt/import/credentials-20260131.wabcred \                   |
  |   --signature /mnt/import/credentials-20260131.wabcred.sig \           |
  |   --public-key /mnt/import/signing-key-public.pem                      |
  |                                                                        |
  | # Expected output:                                                     |
  | # Signature verification: VALID                                        |
  | # Signed by: wallix-primary.corp.example.com                           |
  | # Sign date: 2026-01-31T09:30:00Z                                      |
  | # Package integrity: VERIFIED                                          |
  +------------------------------------------------------------------------+

  Step 3: Import credentials

  +------------------------------------------------------------------------+
  | # Dry run first                                                        |
  | wabadmin credentials import \                                          |
  |   --input /mnt/import/credentials-20260131.wabcred \                   |
  |   --passphrase-file /etc/wallix/import-key.txt \                       |
  |   --dry-run                                                            |
  |                                                                        |
  | # Expected output:                                                     |
  | # Dry run mode - no changes will be made                               |
  | # Accounts to import: 47                                               |
  | # New accounts: 3                                                      |
  | # Updates: 44                                                          |
  | # Conflicts: 0                                                         |
  |                                                                        |
  | # Actual import                                                        |
  | wabadmin credentials import \                                          |
  |   --input /mnt/import/credentials-20260131.wabcred \                   |
  |   --passphrase-file /etc/wallix/import-key.txt \                       |
  |   --log /var/log/wallix/imports/import-20260131.log                    |
  |                                                                        |
  | # Expected output:                                                     |
  | # Importing credentials...                                             |
  | # Processing 47 accounts...                                            |
  | # Created: 3                                                           |
  | # Updated: 44                                                          |
  | # Skipped: 0                                                           |
  | # Errors: 0                                                            |
  | # Import completed successfully                                        |
  +------------------------------------------------------------------------+

  Step 4: Verify import and cleanup

  +------------------------------------------------------------------------+
  | # Verify imported credentials                                          |
  | wabadmin credentials list --imported-since "1 hour ago"                |
  |                                                                        |
  | # Test credential access                                               |
  | wabadmin account test root@scada-server-01                             |
  |                                                                        |
  | # Unmount and secure media                                             |
  | umount /mnt/import                                                     |
  | cryptsetup luksClose secure-transfer                                   |
  |                                                                        |
  | # IMPORTANT: Destroy transfer media after successful import            |
  | # Physical destruction or secure wipe                                  |
  | shred -vfz -n 3 /dev/sdb                                               |
  +------------------------------------------------------------------------+

+==============================================================================+
```

### Verification Procedures

```
+==============================================================================+
|                   IMPORT VERIFICATION CHECKLIST                               |
+==============================================================================+

  PRE-IMPORT VERIFICATION
  =======================

  +------------------------------------------------------------------------+
  | [ ] 1. Verify chain of custody documentation is complete               |
  | [ ] 2. Verify media seal is intact (tamper-evident)                    |
  | [ ] 3. Verify transfer ticket/authorization exists                     |
  | [ ] 4. Two-person verification of manifest contents                    |
  | [ ] 5. SHA256 checksums match on all files                             |
  | [ ] 6. Digital signature is valid                                      |
  | [ ] 7. Public key matches expected source                              |
  | [ ] 8. Malware scan completed (isolated scanner)                       |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  POST-IMPORT VERIFICATION
  ========================

  +------------------------------------------------------------------------+
  | [ ] 1. Import log shows no errors                                      |
  | [ ] 2. All expected accounts present in vault                          |
  | [ ] 3. Sample credential tests succeed                                 |
  | [ ] 4. Audit log entries created for import                            |
  | [ ] 5. Cache refresh completed                                         |
  | [ ] 6. Transfer media securely destroyed                               |
  | [ ] 7. Chain of custody log updated with import confirmation           |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  VERIFICATION SCRIPT
  ===================

  +------------------------------------------------------------------------+
  | #!/bin/bash                                                            |
  | # verify-credential-import.sh                                          |
  | # Post-import verification script                                      |
  |                                                                        |
  | set -euo pipefail                                                      |
  |                                                                        |
  | IMPORT_LOG="${1:-/var/log/wallix/imports/latest-import.log}"           |
  | REPORT_FILE="/var/log/wallix/imports/verification-$(date +%Y%m%d).txt" |
  |                                                                        |
  | echo "=== Credential Import Verification ===" > $REPORT_FILE           |
  | echo "Date: $(date)" >> $REPORT_FILE                                   |
  | echo "" >> $REPORT_FILE                                                |
  |                                                                        |
  | # Check import log for errors                                          |
  | echo "1. Import Log Analysis" >> $REPORT_FILE                          |
  | if grep -q "ERROR" $IMPORT_LOG; then                                   |
  |     echo "   STATUS: FAILED - Errors found in import log" >> $REPORT_FILE
  |     grep "ERROR" $IMPORT_LOG >> $REPORT_FILE                           |
  |     ERRORS=1                                                           |
  | else                                                                   |
  |     echo "   STATUS: PASSED - No errors in import log" >> $REPORT_FILE |
  |     ERRORS=0                                                           |
  | fi                                                                     |
  |                                                                        |
  | # Sample credential tests                                              |
  | echo "" >> $REPORT_FILE                                                |
  | echo "2. Credential Access Tests" >> $REPORT_FILE                      |
  | SAMPLE_ACCOUNTS=$(wabadmin credentials list --imported-since "1 hour ago" \
  |   --format json | jq -r '.[0:5] | .[].account_name')                   |
  |                                                                        |
  | for account in $SAMPLE_ACCOUNTS; do                                    |
  |     if wabadmin account test "$account" > /dev/null 2>&1; then         |
  |         echo "   $account: PASSED" >> $REPORT_FILE                     |
  |     else                                                               |
  |         echo "   $account: FAILED" >> $REPORT_FILE                     |
  |         ERRORS=$((ERRORS + 1))                                         |
  |     fi                                                                 |
  | done                                                                   |
  |                                                                        |
  | # Cache status                                                         |
  | echo "" >> $REPORT_FILE                                                |
  | echo "3. Cache Refresh Status" >> $REPORT_FILE                         |
  | wabadmin cache status >> $REPORT_FILE                                  |
  |                                                                        |
  | # Summary                                                              |
  | echo "" >> $REPORT_FILE                                                |
  | echo "=== VERIFICATION SUMMARY ===" >> $REPORT_FILE                    |
  | if [ $ERRORS -eq 0 ]; then                                             |
  |     echo "RESULT: ALL CHECKS PASSED" >> $REPORT_FILE                   |
  | else                                                                   |
  |     echo "RESULT: $ERRORS CHECK(S) FAILED" >> $REPORT_FILE             |
  | fi                                                                     |
  |                                                                        |
  | cat $REPORT_FILE                                                       |
  +------------------------------------------------------------------------+

+==============================================================================+
```

---

## Offline User Management

### Local User Creation

```
+==============================================================================+
|                   OFFLINE USER MANAGEMENT                                     |
+==============================================================================+

  LOCAL USER PROVISIONING
  =======================

  In air-gapped environments, users are managed locally:

  +------------------------------------------------------------------------+
  |                                                                        |
  |   USER MANAGEMENT OPTIONS                                              |
  |   =======================                                              |
  |                                                                        |
  |   1. MANUAL CREATION (Web UI or CLI)                                   |
  |      * Create individual users as needed                               |
  |      * Assign to local groups                                          |
  |      * Configure MFA (hardware tokens)                                 |
  |                                                                        |
  |   2. CSV BULK IMPORT                                                   |
  |      * Prepare user list on connected system                           |
  |      * Transfer via sneakernet                                         |
  |      * Import to air-gapped WALLIX                                     |
  |                                                                        |
  |   3. LOCAL LDAP (Optional)                                             |
  |      * Deploy OpenLDAP within air-gap zone                             |
  |      * WALLIX syncs with local LDAP                                    |
  |      * Separate from corporate AD                                      |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  MANUAL USER CREATION
  ====================

  +------------------------------------------------------------------------+
  | # Create local user via CLI                                            |
  | wabadmin user create \                                                 |
  |   --username "jsmith" \                                                |
  |   --email "jsmith@local.domain" \                                      |
  |   --full-name "John Smith" \                                           |
  |   --groups "ot-operators" \                                            |
  |   --authentication "local" \                                           |
  |   --mfa-type "totp" \                                                  |
  |   --temporary-password                                                 |
  |                                                                        |
  | # Output:                                                              |
  | # User created: jsmith                                                 |
  | # Temporary password: Kj8#mN2$pL9xQw1!                                 |
  | # MFA secret: JBSWY3DPEHPK3PXP                                         |
  | # User must change password on first login                             |
  |                                                                        |
  | # Configure hardware token                                             |
  | wabadmin user set-totp-seed \                                          |
  |   --username "jsmith" \                                                |
  |   --seed-from-token "RSA-TOKEN-SERIAL-12345"                           |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  CSV IMPORT FORMAT
  =================

  +------------------------------------------------------------------------+
  | # users-import.csv format                                              |
  | # Header row:                                                          |
  | username,full_name,email,groups,auth_type,valid_until,department       |
  |                                                                        |
  | # Data rows:                                                           |
  | jsmith,John Smith,jsmith@local,ot-operators,local,2026-12-31,Operations|
  | mwilson,Mary Wilson,mwilson@local,ot-engineers,local,2026-12-31,Eng    |
  | vendor1,Vendor Account,vendor@ext,vendors,local,2026-02-15,External    |
  | tjones,Tom Jones,tjones@local,ot-operators;ot-viewers,local,,Ops       |
  +------------------------------------------------------------------------+

  Import command:

  +------------------------------------------------------------------------+
  | # Dry run first                                                        |
  | wabadmin users import \                                                |
  |   --file /import/users-import.csv \                                    |
  |   --dry-run                                                            |
  |                                                                        |
  | # Actual import                                                        |
  | wabadmin users import \                                                |
  |   --file /import/users-import.csv \                                    |
  |   --generate-passwords \                                               |
  |   --password-output /secure/new-passwords.txt \                        |
  |   --log /var/log/wallix/user-import-$(date +%Y%m%d).log                |
  +------------------------------------------------------------------------+

+==============================================================================+
```

### Syncing User Changes via Sneakernet

```
+==============================================================================+
|                   USER SYNC VIA SNEAKERNET                                    |
+==============================================================================+

  USER EXPORT FROM CORPORATE AD
  =============================

  On connected corporate network:

  +------------------------------------------------------------------------+
  | # Export users from corporate AD for air-gapped site                   |
  | # PowerShell script on Domain Controller                               |
  |                                                                        |
  | $OT_Groups = @("OT-Operators", "OT-Engineers", "OT-Admins")            |
  |                                                                        |
  | $Users = foreach ($Group in $OT_Groups) {                              |
  |     Get-ADGroupMember -Identity $Group | Get-ADUser -Properties * |    |
  |     Select-Object SamAccountName, DisplayName, EmailAddress,           |
  |                   @{N='Groups';E={$Group}},                            |
  |                   @{N='AccountExpires';E={                             |
  |                       if ($_.AccountExpirationDate) {                  |
  |                           $_.AccountExpirationDate.ToString("yyyy-MM-dd")
  |                       }                                                |
  |                   }}                                                   |
  | }                                                                      |
  |                                                                        |
  | $Users | Export-Csv -Path "C:\Export\ot-users-$(Get-Date -Format 'yyyyMMdd').csv" -NoTypeInformation
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  USER CHANGE EXPORT
  ==================

  +------------------------------------------------------------------------+
  | # Export only changed users (since last export)                        |
  | wabadmin users export \                                                |
  |   --modified-since "2026-01-15" \                                      |
  |   --format csv \                                                       |
  |   --output /export/user-changes-$(date +%Y%m%d).csv \                  |
  |   --include-disabled \                                                 |
  |   --include-deleted                                                    |
  |                                                                        |
  | # Package for transfer                                                 |
  | tar -czvf /export/user-sync-$(date +%Y%m%d).tar.gz \                   |
  |   /export/user-changes-$(date +%Y%m%d).csv                             |
  |                                                                        |
  | # Sign and encrypt                                                     |
  | gpg --encrypt --sign \                                                 |
  |   --recipient air-gapped-site@example.com \                            |
  |   /export/user-sync-$(date +%Y%m%d).tar.gz                             |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  USER IMPORT ON AIR-GAPPED SITE
  ==============================

  +------------------------------------------------------------------------+
  | # Verify and decrypt package                                           |
  | gpg --decrypt /import/user-sync-20260131.tar.gz.gpg \                  |
  |   > /import/user-sync-20260131.tar.gz                                  |
  |                                                                        |
  | tar -xzvf /import/user-sync-20260131.tar.gz -C /import/                |
  |                                                                        |
  | # Import user changes                                                  |
  | wabadmin users import \                                                |
  |   --file /import/user-changes-20260131.csv \                           |
  |   --mode merge \                                                       |
  |   --handle-deletes disable \                                           |
  |   --log /var/log/wallix/user-sync-$(date +%Y%m%d).log                  |
  |                                                                        |
  | # Verify import                                                        |
  | wabadmin users list --modified-since "1 hour ago"                      |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  SYNC PROCEDURE CHECKLIST
  ========================

  +------------------------------------------------------------------------+
  | [ ] 1. Export user changes from corporate AD/LDAP                      |
  | [ ] 2. Review export for accuracy                                      |
  | [ ] 3. Package and encrypt for transfer                                |
  | [ ] 4. Transfer via approved media                                     |
  | [ ] 5. Verify package integrity on air-gapped side                     |
  | [ ] 6. Perform dry-run import                                          |
  | [ ] 7. Review dry-run results                                          |
  | [ ] 8. Execute import                                                  |
  | [ ] 9. Verify user accounts                                            |
  | [ ] 10. Notify affected users (if needed)                              |
  | [ ] 11. Update sync log with date and counts                           |
  | [ ] 12. Destroy transfer media                                         |
  +------------------------------------------------------------------------+

+==============================================================================+
```

---

## Offline License Management

### Offline License Activation

```
+==============================================================================+
|                   OFFLINE LICENSE ACTIVATION                                  |
+==============================================================================+

  OFFLINE ACTIVATION WORKFLOW
  ===========================

  +------------------------------------------------------------------------+
  |                                                                        |
  |   AIR-GAPPED SITE                    WALLIX SUPPORT                    |
  |   ===============                    ==============                    |
  |                                                                        |
  |   1. Generate License Request                                          |
  |   +------------------+                                                 |
  |   | wabadmin license |                                                 |
  |   | request-generate |                                                 |
  |   +--------+---------+                                                 |
  |            |                                                           |
  |            | 2. Transfer request file                                  |
  |            |    (via sneakernet to connected system)                   |
  |            v                                                           |
  |   +------------------+         +------------------+                    |
  |   | license-request  | ======> | Email/Portal     |                    |
  |   | .wablicense      |         | Submit request   |                    |
  |   +------------------+         +--------+---------+                    |
  |                                         |                              |
  |                                         | 3. WALLIX processes request  |
  |                                         v                              |
  |                                +------------------+                    |
  |                                | License file     |                    |
  |                                | .wablicense      |                    |
  |                                +--------+---------+                    |
  |                                         |                              |
  |            +----------------------------+                              |
  |            | 4. Transfer license file                                  |
  |            |    (via sneakernet to air-gapped site)                    |
  |            v                                                           |
  |   +------------------+                                                 |
  |   | wabadmin license |                                                 |
  |   | activate-offline |                                                 |
  |   +------------------+                                                 |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  STEP 1: GENERATE LICENSE REQUEST
  ================================

  +------------------------------------------------------------------------+
  | # Generate offline license request                                     |
  | wabadmin license request-generate \                                    |
  |   --output /export/license-request-$(hostname)-$(date +%Y%m%d).req     |
  |                                                                        |
  | # Output:                                                              |
  | # License Request Generated                                            |
  | # =========================                                            |
  | # Request ID: REQ-2026-0131-ABCD1234                                   |
  | # Hardware ID: HW-XYZ789-DEF456                                        |
  | # Current License: TRIAL (expires 2026-02-15)                          |
  | # Requested Features: All                                              |
  | #                                                                      |
  | # Request file: license-request-wallix-ot-01-20260131.req              |
  | #                                                                      |
  | # Submit this file to: licensing@wallix.com                            |
  | # Or via support portal: https://support.wallix.com                    |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  STEP 2: SUBMIT REQUEST (via connected system)
  =============================================

  +------------------------------------------------------------------------+
  | # On connected system, submit via portal or email                      |
  | # Using curl to WALLIX API (example)                                   |
  |                                                                        |
  | curl -X POST "https://licensing.wallix.com/api/v1/offline-activation" \|
  |   -H "Authorization: Bearer $WALLIX_SUPPORT_TOKEN" \                   |
  |   -H "Content-Type: application/octet-stream" \                        |
  |   --data-binary @license-request-wallix-ot-01-20260131.req \           |
  |   -o wallix-ot-01-license-20260131.lic                                 |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  STEP 3: ACTIVATE LICENSE OFFLINE
  ================================

  +------------------------------------------------------------------------+
  | # Transfer license file to air-gapped site                             |
  | # Then activate:                                                       |
  |                                                                        |
  | wabadmin license activate-offline \                                    |
  |   --license-file /import/wallix-ot-01-license-20260131.lic             |
  |                                                                        |
  | # Output:                                                              |
  | # License Activated Successfully                                       |
  | # =============================                                        |
  | # License Type: Enterprise                                             |
  | # Licensed To: Example Corp - OT Site C                                |
  | # Valid From: 2026-01-31                                               |
  | # Valid Until: 2027-01-31                                              |
  | # Licensed Users: 100                                                  |
  | # Licensed Devices: 500                                                |
  | # Features: Full PAM, Session Recording, Password Management           |
  |                                                                        |
  | # Verify license                                                       |
  | wabadmin license-info                                                  |
  +------------------------------------------------------------------------+

+==============================================================================+
```

### License Renewal Without Network

```
+==============================================================================+
|                   OFFLINE LICENSE RENEWAL                                     |
+==============================================================================+

  RENEWAL TIMELINE
  ================

  +------------------------------------------------------------------------+
  |                                                                        |
  |   Days Before    Action Required                                       |
  |   Expiry                                                               |
  |   ============   ===============                                       |
  |                                                                        |
  |   90 days        * Begin renewal process                               |
  |                  * Contact WALLIX sales                                |
  |                  * Generate renewal request                            |
  |                                                                        |
  |   60 days        * Submit renewal request                              |
  |                  * Ensure PO processing                                |
  |                                                                        |
  |   30 days        * Receive renewal license                             |
  |                  * Schedule activation maintenance window              |
  |                                                                        |
  |   14 days        * ALERT: License expiring soon                        |
  |                  * Activate renewal if not done                        |
  |                                                                        |
  |   7 days         * CRITICAL: Activate immediately                      |
  |                  * Plan for degraded mode if fails                     |
  |                                                                        |
  |   0 days         * License expired                                     |
  |                  * Degraded mode active                                |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  RENEWAL COMMANDS
  ================

  +------------------------------------------------------------------------+
  | # Check license status                                                 |
  | wabadmin license-info                                                  |
  |                                                                        |
  | # Example output when expiring:                                        |
  | # License Status                                                       |
  | # ==============                                                       |
  | # Status: ACTIVE (EXPIRING SOON)                                       |
  | # Days Remaining: 28                                                   |
  | # Expires: 2026-02-28                                                  |
  | # WARNING: License expires in less than 30 days                        |
  |                                                                        |
  | # Generate renewal request                                             |
  | wabadmin license renewal-request \                                     |
  |   --output /export/renewal-request-$(hostname)-$(date +%Y%m%d).req     |
  |                                                                        |
  | # Apply renewal license (same as activation)                           |
  | wabadmin license activate-offline \                                    |
  |   --license-file /import/wallix-ot-01-renewal-20260201.lic             |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  GRACE PERIOD AND DEGRADED MODE
  ==============================

  +------------------------------------------------------------------------+
  |                                                                        |
  |   If license expires before renewal:                                   |
  |                                                                        |
  |   GRACE PERIOD (7 days after expiry)                                   |
  |   ==================================                                   |
  |   * Full functionality maintained                                      |
  |   * Warning banners displayed                                          |
  |   * Daily admin notifications                                          |
  |                                                                        |
  |   DEGRADED MODE (after grace period)                                   |
  |   ==================================                                   |
  |   * Existing sessions continue                                         |
  |   * New sessions blocked                                               |
  |   * Admin access maintained for renewal                                |
  |   * Audit logging continues                                            |
  |                                                                        |
  |   RECOVERY                                                             |
  |   ========                                                             |
  |   * Apply valid license                                                |
  |   * Full functionality restored immediately                            |
  |   * No data loss occurs                                                |
  |                                                                        |
  +------------------------------------------------------------------------+

+==============================================================================+
```

---

## Patch and Update Procedures

### Downloading Updates on Connected System

```
+==============================================================================+
|                   OFFLINE UPDATE PROCEDURE                                    |
+==============================================================================+

  UPDATE DOWNLOAD WORKFLOW
  ========================

  +------------------------------------------------------------------------+
  |                                                                        |
  |   CONNECTED NETWORK                                                    |
  |   =================                                                    |
  |                                                                        |
  |   +------------------+                                                 |
  |   | WALLIX Support   |                                                 |
  |   | Portal           |                                                 |
  |   +--------+---------+                                                 |
  |            |                                                           |
  |            | 1. Download update package                                |
  |            v                                                           |
  |   +------------------+                                                 |
  |   | Staging Server   |                                                 |
  |   | (IT Network)     |                                                 |
  |   +--------+---------+                                                 |
  |            |                                                           |
  |            | 2. Verify signature and checksum                          |
  |            v                                                           |
  |   +------------------+                                                 |
  |   | AV Scanning      |                                                 |
  |   | Station          |                                                 |
  |   +--------+---------+                                                 |
  |            |                                                           |
  |            | 3. Test in staging environment (if available)             |
  |            v                                                           |
  |   +------------------+                                                 |
  |   | WALLIX Staging   |                                                 |
  |   | (IT environment) |                                                 |
  |   +--------+---------+                                                 |
  |            |                                                           |
  |            | 4. Prepare transfer package                               |
  |            v                                                           |
  |   +------------------+                                                 |
  |   | Encrypted USB    |  ====> Physical transfer                        |
  |   +------------------+                                                 |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  DOWNLOAD AND VERIFICATION
  =========================

  +------------------------------------------------------------------------+
  | # On connected staging server                                          |
  |                                                                        |
  | # 1. Download from WALLIX support portal                               |
  | wget -O wallix-bastion-12.1.5.wab \                                    |
  |   "https://support.wallix.com/downloads/bastion/12.1.5/wallix-bastion-12.1.5.wab"
  |                                                                        |
  | # 2. Download checksum and signature                                   |
  | wget -O wallix-bastion-12.1.5.sha256 \                                 |
  |   "https://support.wallix.com/downloads/bastion/12.1.5/wallix-bastion-12.1.5.sha256"
  | wget -O wallix-bastion-12.1.5.sig \                                    |
  |   "https://support.wallix.com/downloads/bastion/12.1.5/wallix-bastion-12.1.5.sig"
  |                                                                        |
  | # 3. Import WALLIX GPG key (if not already imported)                   |
  | gpg --keyserver keys.openpgp.org --recv-keys WALLIX_GPG_KEY_ID         |
  |                                                                        |
  | # 4. Verify GPG signature                                              |
  | gpg --verify wallix-bastion-12.1.5.sig wallix-bastion-12.1.5.wab       |
  | # Expected: Good signature from "WALLIX Release Team"                  |
  |                                                                        |
  | # 5. Verify SHA256 checksum                                            |
  | sha256sum -c wallix-bastion-12.1.5.sha256                              |
  | # Expected: wallix-bastion-12.1.5.wab: OK                              |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  MALWARE SCANNING
  ================

  +------------------------------------------------------------------------+
  | # Run multiple AV scans on isolated scanning station                   |
  |                                                                        |
  | # ClamAV scan                                                          |
  | clamscan --verbose wallix-bastion-12.1.5.wab                           |
  |                                                                        |
  | # If available, scan with commercial AV                                |
  | # Document scan results for chain of custody                           |
  |                                                                        |
  | # Create scan report                                                   |
  | cat > scan-report-$(date +%Y%m%d).txt << 'EOF'                         |
  | Update Package Scan Report                                             |
  | ==========================                                             |
  | File: wallix-bastion-12.1.5.wab                                        |
  | Date: 2026-01-31                                                       |
  | Scanned by: Security Team                                              |
  |                                                                        |
  | ClamAV 1.2.0:        CLEAN                                             |
  | Windows Defender:    CLEAN (via sandbox)                               |
  | Malwarebytes:        CLEAN                                             |
  |                                                                        |
  | Verified by: [Signature]                                               |
  | EOF                                                                    |
  +------------------------------------------------------------------------+

+==============================================================================+
```

### Verification and Applying Updates Offline

```
+==============================================================================+
|                   OFFLINE UPDATE APPLICATION                                  |
+==============================================================================+

  PRE-UPDATE CHECKLIST
  ====================

  +------------------------------------------------------------------------+
  | [ ] 1. Verify update package integrity (checksum)                      |
  | [ ] 2. Verify GPG signature                                            |
  | [ ] 3. Review release notes for breaking changes                       |
  | [ ] 4. Create full backup of current installation                      |
  | [ ] 5. Schedule maintenance window                                     |
  | [ ] 6. Notify users of planned downtime                                |
  | [ ] 7. Verify rollback procedure is documented                         |
  | [ ] 8. Verify backup restore has been tested                           |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  UPDATE APPLICATION PROCEDURE
  ============================

  Step 1: Pre-update backup

  +------------------------------------------------------------------------+
  | # Create timestamped backup                                            |
  | BACKUP_DATE=$(date +%Y%m%d_%H%M%S)                                     |
  | wabadmin backup --full \                                               |
  |   --output /backup/pre-update-${BACKUP_DATE}.tar.gz                    |
  |                                                                        |
  | # Verify backup                                                        |
  | wabadmin backup --verify /backup/pre-update-${BACKUP_DATE}.tar.gz      |
  |                                                                        |
  | # Export current version                                               |
  | wabadmin version > /backup/version-before-${BACKUP_DATE}.txt           |
  +------------------------------------------------------------------------+

  Step 2: Verify update package on air-gapped system

  +------------------------------------------------------------------------+
  | # Mount transfer media                                                 |
  | cryptsetup luksOpen /dev/sdb secure-update                             |
  | mount /dev/mapper/secure-update /mnt/update                            |
  |                                                                        |
  | # Verify checksums                                                     |
  | cd /mnt/update                                                         |
  | sha256sum -c wallix-bastion-12.1.5.sha256                              |
  |                                                                        |
  | # Verify signature (WALLIX public key must be pre-imported)            |
  | gpg --verify wallix-bastion-12.1.5.sig wallix-bastion-12.1.5.wab       |
  |                                                                        |
  | # Copy to local storage                                                |
  | cp wallix-bastion-12.1.5.wab /var/cache/wallix/updates/                |
  +------------------------------------------------------------------------+

  Step 3: Apply update

  +------------------------------------------------------------------------+
  | # Enable maintenance mode                                              |
  | wabadmin maintenance-mode --enable                                     |
  |                                                                        |
  | # Wait for active sessions to complete (or terminate)                  |
  | wabadmin sessions --active                                             |
  |                                                                        |
  | # Stop services                                                        |
  | systemctl stop wallix-bastion                                          |
  |                                                                        |
  | # Apply update                                                         |
  | wabadmin upgrade --package /var/cache/wallix/updates/wallix-bastion-12.1.5.wab
  |                                                                        |
  | # Run database migrations if needed                                    |
  | wabadmin db-migrate --status                                           |
  | wabadmin db-migrate                                                    |
  |                                                                        |
  | # Start services                                                       |
  | systemctl start wallix-bastion                                         |
  |                                                                        |
  | # Disable maintenance mode                                             |
  | wabadmin maintenance-mode --disable                                    |
  +------------------------------------------------------------------------+

  Step 4: Post-update verification

  +------------------------------------------------------------------------+
  | # Verify new version                                                   |
  | wabadmin version                                                       |
  |                                                                        |
  | # Health check                                                         |
  | wabadmin health-check                                                  |
  |                                                                        |
  | # Test critical functionality                                          |
  | wabadmin connectivity-test --sample 5                                  |
  |                                                                        |
  | # Verify session establishment                                         |
  | # (Manual test by operator)                                            |
  |                                                                        |
  | # Document update                                                      |
  | wabadmin version > /backup/version-after-$(date +%Y%m%d).txt           |
  +------------------------------------------------------------------------+

+==============================================================================+
```

### Rollback Procedures

```
+==============================================================================+
|                   UPDATE ROLLBACK PROCEDURE                                   |
+==============================================================================+

  ROLLBACK DECISION CRITERIA
  ==========================

  +------------------------------------------------------------------------+
  | Trigger rollback if:                                                   |
  |                                                                        |
  | CRITICAL (Immediate rollback):                                         |
  | * Services fail to start after update                                  |
  | * Database corruption detected                                         |
  | * Authentication completely broken                                     |
  |                                                                        |
  | HIGH (Consider rollback):                                              |
  | * More than 50% of sessions failing                                    |
  | * Major feature broken with no workaround                              |
  |                                                                        |
  | MEDIUM (Monitor, may rollback):                                        |
  | * Performance degraded significantly                                   |
  | * Minor features broken                                                |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  ROLLBACK PROCEDURE
  ==================

  +------------------------------------------------------------------------+
  | # 1. Stop services                                                     |
  | systemctl stop wallix-bastion                                          |
  |                                                                        |
  | # 2. Document the issue                                                |
  | cat > /var/log/wallix/rollback-$(date +%Y%m%d).log << 'EOF'            |
  | Rollback initiated                                                     |
  | Date: $(date)                                                          |
  | Reason: [Document specific issues]                                     |
  | Approved by: [Name]                                                    |
  | EOF                                                                    |
  |                                                                        |
  | # 3. Restore from pre-update backup                                    |
  | wabadmin restore --full \                                              |
  |   --input /backup/pre-update-20260131_100000.tar.gz                    |
  |                                                                        |
  | # 4. Start services                                                    |
  | systemctl start wallix-bastion                                         |
  |                                                                        |
  | # 5. Verify rollback                                                   |
  | wabadmin version                                                       |
  | wabadmin health-check                                                  |
  |                                                                        |
  | # 6. Test functionality                                                |
  | wabadmin connectivity-test --sample 5                                  |
  |                                                                        |
  | # 7. Document rollback completion                                      |
  | echo "Rollback completed: $(date)" >> \                                |
  |   /var/log/wallix/rollback-$(date +%Y%m%d).log                         |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  HA CLUSTER ROLLBACK
  ===================

  +------------------------------------------------------------------------+
  | # For HA clusters, rollback both nodes                                 |
  |                                                                        |
  | # 1. On primary node - stop cluster                                    |
  | crm cluster stop                                                       |
  |                                                                        |
  | # 2. On each node - restore from backup                                |
  | # Node 1:                                                              |
  | wabadmin restore --full --input /backup/pre-update-node1.tar.gz        |
  |                                                                        |
  | # Node 2:                                                              |
  | wabadmin restore --full --input /backup/pre-update-node2.tar.gz        |
  |                                                                        |
  | # 3. Start cluster                                                     |
  | crm cluster start                                                      |
  |                                                                        |
  | # 4. Verify cluster health                                             |
  | crm status                                                             |
  | wabadmin health-check                                                  |
  +------------------------------------------------------------------------+

+==============================================================================+
```

---

## Offline Audit Log Export

### Exporting Logs for External Analysis

```
+==============================================================================+
|                   OFFLINE AUDIT LOG EXPORT                                    |
+==============================================================================+

  LOG EXPORT WORKFLOW
  ===================

  +------------------------------------------------------------------------+
  |                                                                        |
  |   AIR-GAPPED WALLIX                     CORPORATE SOC                  |
  |   =================                     =============                  |
  |                                                                        |
  |   +------------------+                                                 |
  |   | Audit Logs       |                                                 |
  |   | Session Logs     |                                                 |
  |   | System Logs      |                                                 |
  |   +--------+---------+                                                 |
  |            |                                                           |
  |            | 1. Export and encrypt                                     |
  |            v                                                           |
  |   +------------------+                                                 |
  |   | Encrypted        |                                                 |
  |   | Log Package      |                                                 |
  |   +--------+---------+                                                 |
  |            |                                                           |
  |            | 2. Sign with integrity hash                               |
  |            v                                                           |
  |   +------------------+                                                 |
  |   | Signed Package   |                                                 |
  |   | + Manifest       |                                                 |
  |   +--------+---------+                                                 |
  |            |                                                           |
  |            | 3. Transfer via data diode or USB                         |
  |            v                                                           |
  |                      +------------------+                              |
  |                      |   Corporate      |                              |
  |                      |   SIEM/SOC       |                              |
  |                      +------------------+                              |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  LOG EXPORT COMMANDS
  ===================

  +------------------------------------------------------------------------+
  | # Export audit logs for date range                                     |
  | wabadmin audit export \                                                |
  |   --start-date "2026-01-01" \                                          |
  |   --end-date "2026-01-31" \                                            |
  |   --format syslog \                                                    |
  |   --output /export/audit-logs-202601.syslog                            |
  |                                                                        |
  | # Export in JSON format for SIEM                                       |
  | wabadmin audit export \                                                |
  |   --start-date "2026-01-01" \                                          |
  |   --end-date "2026-01-31" \                                            |
  |   --format json \                                                      |
  |   --output /export/audit-logs-202601.json                              |
  |                                                                        |
  | # Export session metadata                                              |
  | wabadmin sessions export \                                             |
  |   --start-date "2026-01-01" \                                          |
  |   --end-date "2026-01-31" \                                            |
  |   --format csv \                                                       |
  |   --output /export/sessions-202601.csv                                 |
  |                                                                        |
  | # Export session recordings (optional, large files)                    |
  | wabadmin recordings export \                                           |
  |   --start-date "2026-01-01" \                                          |
  |   --end-date "2026-01-31" \                                            |
  |   --output-dir /export/recordings-202601/                              |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  AUTOMATED EXPORT SCRIPT
  =======================

  +------------------------------------------------------------------------+
  | #!/bin/bash                                                            |
  | # export-audit-logs.sh                                                 |
  | # Automated weekly audit log export                                    |
  |                                                                        |
  | set -euo pipefail                                                      |
  |                                                                        |
  | EXPORT_DIR="/export/audit"                                             |
  | ENCRYPT_KEY="/etc/wallix/soc-public-key.pem"                           |
  | DATE_SUFFIX=$(date +%Y%m%d)                                            |
  | WEEK_AGO=$(date -d "7 days ago" +%Y-%m-%d)                             |
  | TODAY=$(date +%Y-%m-%d)                                                |
  |                                                                        |
  | mkdir -p $EXPORT_DIR                                                   |
  |                                                                        |
  | # Export audit logs                                                    |
  | echo "Exporting audit logs..."                                         |
  | wabadmin audit export \                                                |
  |   --start-date "$WEEK_AGO" \                                           |
  |   --end-date "$TODAY" \                                                |
  |   --format json \                                                      |
  |   --output $EXPORT_DIR/audit-$DATE_SUFFIX.json                         |
  |                                                                        |
  | # Export session metadata                                              |
  | echo "Exporting session metadata..."                                   |
  | wabadmin sessions export \                                             |
  |   --start-date "$WEEK_AGO" \                                           |
  |   --end-date "$TODAY" \                                                |
  |   --format csv \                                                       |
  |   --output $EXPORT_DIR/sessions-$DATE_SUFFIX.csv                       |
  |                                                                        |
  | # Create archive                                                       |
  | echo "Creating archive..."                                             |
  | tar -czvf $EXPORT_DIR/logs-$DATE_SUFFIX.tar.gz \                       |
  |   -C $EXPORT_DIR audit-$DATE_SUFFIX.json sessions-$DATE_SUFFIX.csv     |
  |                                                                        |
  | # Encrypt for SOC                                                      |
  | echo "Encrypting archive..."                                           |
  | openssl smime -encrypt -aes256 \                                       |
  |   -in $EXPORT_DIR/logs-$DATE_SUFFIX.tar.gz \                           |
  |   -out $EXPORT_DIR/logs-$DATE_SUFFIX.tar.gz.enc \                      |
  |   -outform DER $ENCRYPT_KEY                                            |
  |                                                                        |
  | # Generate checksum                                                    |
  | sha256sum $EXPORT_DIR/logs-$DATE_SUFFIX.tar.gz.enc \                   |
  |   > $EXPORT_DIR/logs-$DATE_SUFFIX.sha256                               |
  |                                                                        |
  | # Cleanup unencrypted files                                            |
  | rm -f $EXPORT_DIR/audit-$DATE_SUFFIX.json                              |
  | rm -f $EXPORT_DIR/sessions-$DATE_SUFFIX.csv                            |
  | rm -f $EXPORT_DIR/logs-$DATE_SUFFIX.tar.gz                             |
  |                                                                        |
  | echo "Export complete: logs-$DATE_SUFFIX.tar.gz.enc"                   |
  | logger -t wallix-export "Weekly audit export completed: $DATE_SUFFIX"  |
  +------------------------------------------------------------------------+

+==============================================================================+
```

### Secure Transfer to SOC

```
+==============================================================================+
|                   SOC LOG TRANSFER PROCEDURES                                 |
+==============================================================================+

  TRANSFER METHODS
  ================

  +------------------------------------------------------------------------+
  | Method              | Frequency     | Latency      | Use Case          |
  +---------------------+---------------+--------------+-------------------+
  | Data Diode          | Real-time     | Seconds      | Continuous monitor|
  | Encrypted USB       | Weekly        | Days         | Standard export   |
  | Write-once media    | Monthly       | Weeks        | Archive/compliance|
  +---------------------+---------------+--------------+-------------------+

  --------------------------------------------------------------------------

  USB TRANSFER PROCEDURE
  ======================

  +------------------------------------------------------------------------+
  | EXPORT SIDE (Air-gapped)                                               |
  | ========================                                               |
  |                                                                        |
  | # 1. Prepare export package                                            |
  | /opt/scripts/export-audit-logs.sh                                      |
  |                                                                        |
  | # 2. Write to encrypted USB                                            |
  | cryptsetup luksFormat /dev/sdb                                         |
  | cryptsetup luksOpen /dev/sdb secure-export                             |
  | mkfs.ext4 /dev/mapper/secure-export                                    |
  | mount /dev/mapper/secure-export /mnt/export                            |
  |                                                                        |
  | cp /export/audit/logs-*.tar.gz.enc /mnt/export/                        |
  | cp /export/audit/logs-*.sha256 /mnt/export/                            |
  |                                                                        |
  | # Generate transfer manifest                                           |
  | cat > /mnt/export/MANIFEST.txt << 'EOF'                                |
  | Log Export Transfer                                                    |
  | ===================                                                    |
  | Source: wallix-ot-site-c                                               |
  | Date Range: 2026-01-24 to 2026-01-31                                   |
  | Export Date: 2026-01-31                                                |
  | Prepared by: A. Wilson                                                 |
  | Files:                                                                 |
  |   - logs-20260131.tar.gz.enc (audit logs, sessions)                    |
  |   - logs-20260131.sha256 (checksum)                                    |
  | EOF                                                                    |
  |                                                                        |
  | umount /mnt/export                                                     |
  | cryptsetup luksClose secure-export                                     |
  |                                                                        |
  | # PHYSICAL TRANSFER TO CORPORATE SOC                                   |
  +------------------------------------------------------------------------+

  +------------------------------------------------------------------------+
  | IMPORT SIDE (Corporate SOC)                                            |
  | ===========================                                            |
  |                                                                        |
  | # 1. Mount and verify                                                  |
  | cryptsetup luksOpen /dev/sdb secure-import                             |
  | mount /dev/mapper/secure-import /mnt/import                            |
  |                                                                        |
  | cd /mnt/import                                                         |
  | sha256sum -c logs-20260131.sha256                                      |
  |                                                                        |
  | # 2. Decrypt logs                                                      |
  | openssl smime -decrypt \                                               |
  |   -in logs-20260131.tar.gz.enc \                                       |
  |   -inform DER \                                                        |
  |   -out logs-20260131.tar.gz \                                          |
  |   -inkey /etc/soc/private-key.pem                                      |
  |                                                                        |
  | # 3. Extract and import to SIEM                                        |
  | tar -xzvf logs-20260131.tar.gz                                         |
  |                                                                        |
  | # 4. Import to Splunk/QRadar/etc                                       |
  | /opt/splunk/bin/splunk add oneshot audit-20260131.json \               |
  |   -sourcetype wallix:audit -index ot_pam                               |
  |                                                                        |
  | # 5. Cleanup and destroy media                                         |
  | umount /mnt/import                                                     |
  | cryptsetup luksClose secure-import                                     |
  | # Secure wipe or physical destruction                                  |
  +------------------------------------------------------------------------+

+==============================================================================+
```

---

## Emergency Access Procedures

### Break-Glass Access When Isolated

```
+==============================================================================+
|                   EMERGENCY BREAK-GLASS PROCEDURES                            |
+==============================================================================+

  BREAK-GLASS OVERVIEW
  ====================

  +------------------------------------------------------------------------+
  |                                                                        |
  |   Break-glass access provides emergency access when:                   |
  |                                                                        |
  |   * WALLIX Bastion is unavailable                                      |
  |   * Network connectivity to WALLIX is lost                             |
  |   * Critical incident requires immediate access                        |
  |   * Authentication systems are compromised                             |
  |                                                                        |
  |   IMPORTANT: Break-glass access bypasses PAM controls and must be:     |
  |   * Documented immediately                                             |
  |   * Used only for genuine emergencies                                  |
  |   * Followed by credential rotation                                    |
  |   * Reviewed in post-incident analysis                                 |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  BREAK-GLASS CREDENTIAL STORAGE
  ==============================

  +------------------------------------------------------------------------+
  |                                                                        |
  |   PHYSICAL SAFE STORAGE                                                |
  |   =====================                                                |
  |                                                                        |
  |   +----------------------------------------------+                     |
  |   |              FIREPROOF SAFE                  |                     |
  |   |  Location: Control Room, Secured Cabinet    |                     |
  |   |  Access: Dual Control (2 keyholders)        |                     |
  |   |                                              |                     |
  |   |  +----------------------------------------+  |                     |
  |   |  |  ENVELOPE: SCADA-ADMIN                 |  |                     |
  |   |  |  Seal #: 2026-001                      |  |                     |
  |   |  |  Date Sealed: 2026-01-15               |  |                     |
  |   |  |  Contents: admin@scada-server          |  |                     |
  |   |  +----------------------------------------+  |                     |
  |   |                                              |                     |
  |   |  +----------------------------------------+  |                     |
  |   |  |  ENVELOPE: PLC-ENGINEERING             |  |                     |
  |   |  |  Seal #: 2026-002                      |  |                     |
  |   |  |  Date Sealed: 2026-01-15               |  |                     |
  |   |  |  Contents: engineer@plc-program-ws     |  |                     |
  |   |  +----------------------------------------+  |                     |
  |   |                                              |                     |
  |   |  +----------------------------------------+  |                     |
  |   |  |  ENVELOPE: WALLIX-RECOVERY             |  |                     |
  |   |  |  Seal #: 2026-003                      |  |                     |
  |   |  |  Date Sealed: 2026-01-15               |  |                     |
  |   |  |  Contents: recovery@wallix-bastion     |  |                     |
  |   |  +----------------------------------------+  |                     |
  |   |                                              |                     |
  |   +----------------------------------------------+                     |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  BREAK-GLASS PROCEDURE
  =====================

  +------------------------------------------------------------------------+
  | STEP 1: AUTHORIZATION (Dual Control)                                   |
  | ====================================                                   |
  |                                                                        |
  | Required personnel:                                                    |
  | * Operations Manager or Shift Supervisor                               |
  | * Security Officer or OT Administrator                                 |
  |                                                                        |
  | Both must:                                                             |
  | 1. Agree emergency access is necessary                                 |
  | 2. Sign Break-Glass Authorization Form                                 |
  | 3. Document incident ticket number                                     |
  +------------------------------------------------------------------------+

  +------------------------------------------------------------------------+
  | STEP 2: RETRIEVE CREDENTIALS                                           |
  | =============================                                          |
  |                                                                        |
  | 1. Both authorized personnel go to safe location                       |
  | 2. Unlock safe with dual keys/combinations                             |
  | 3. Select appropriate sealed envelope                                  |
  | 4. Verify seal is intact and matches log                               |
  | 5. Document seal number being broken                                   |
  | 6. Open envelope and retrieve credentials                              |
  +------------------------------------------------------------------------+

  +------------------------------------------------------------------------+
  | STEP 3: ACCESS SYSTEM                                                  |
  | =====================                                                  |
  |                                                                        |
  | 1. Access target system directly (not via WALLIX)                      |
  | 2. Perform ONLY necessary emergency actions                            |
  | 3. Document all commands executed                                      |
  | 4. Have witness observe all actions                                    |
  | 5. Screenshot or record session if possible                            |
  +------------------------------------------------------------------------+

  +------------------------------------------------------------------------+
  | STEP 4: POST-EMERGENCY ACTIONS                                         |
  | ==============================                                         |
  |                                                                        |
  | IMMEDIATELY after emergency resolved:                                  |
  |                                                                        |
  | # 1. Rotate all used break-glass credentials                           |
  | wabadmin account rotate scada-admin --force                            |
  | wabadmin account rotate plc-engineering --force                        |
  |                                                                        |
  | # 2. Update break-glass envelopes with new passwords                   |
  | wabadmin account show scada-admin --show-password                      |
  | # Print and seal in new tamper-evident envelope                        |
  |                                                                        |
  | # 3. Log break-glass event in WALLIX                                   |
  | wabadmin audit log \                                                   |
  |   --event-type "break-glass" \                                         |
  |   --user "authorized_personnel" \                                      |
  |   --target "scada-server" \                                            |
  |   --details "Emergency access - Ticket INC-2026-0131-001"              |
  |                                                                        |
  | # 4. File incident report                                              |
  | # 5. Schedule post-incident review                                     |
  +------------------------------------------------------------------------+

+==============================================================================+
```

### Local Admin Override

```
+==============================================================================+
|                   LOCAL ADMIN OVERRIDE                                        |
+==============================================================================+

  WALLIX LOCAL RECOVERY ACCESS
  ============================

  +------------------------------------------------------------------------+
  |                                                                        |
  |   When WALLIX web interface is inaccessible:                           |
  |                                                                        |
  |   CONSOLE ACCESS                                                       |
  |   ==============                                                       |
  |   1. Access physical console (IPMI/iLO/iDRAC)                          |
  |   2. Login with local OS account                                       |
  |   3. Use wabadmin CLI for emergency operations                         |
  |                                                                        |
  +------------------------------------------------------------------------+

  +------------------------------------------------------------------------+
  | # Local recovery account access                                        |
  | # (credentials in break-glass safe)                                    |
  |                                                                        |
  | ssh recovery@wallix-bastion-console                                    |
  | # Or via IPMI/iLO console                                              |
  |                                                                        |
  | # Check service status                                                 |
  | sudo systemctl status wallix-bastion                                   |
  |                                                                        |
  | # View recent errors                                                   |
  | sudo journalctl -u wallix-bastion --since "1 hour ago"                 |
  |                                                                        |
  | # Emergency service restart                                            |
  | sudo systemctl restart wallix-bastion                                  |
  |                                                                        |
  | # If database issue, check PostgreSQL                                  |
  | sudo systemctl status postgresql                                       |
  | sudo -u postgres psql -c "SELECT 1;"                                   |
  |                                                                        |
  | # Emergency credential checkout (bypasses normal workflow)             |
  | sudo wabadmin emergency-checkout \                                     |
  |   --account root@critical-server \                                     |
  |   --reason "INC-2026-0131-001" \                                       |
  |   --authorized-by "J.Smith"                                            |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  EMERGENCY BYPASS MODES
  ======================

  +------------------------------------------------------------------------+
  | Mode                  | Access Level        | Use Case                 |
  +-----------------------+---------------------+--------------------------+
  | Maintenance Mode      | Admin only          | Scheduled maintenance    |
  | Emergency Checkout    | Specific credential | Urgent access needed     |
  | Bypass Mode           | All sessions direct | WALLIX completely down   |
  | Recovery Mode         | Console only        | System recovery          |
  +-----------------------+---------------------+--------------------------+

  WARNING: Bypass modes disable session recording and audit.               |
  Use only when absolutely necessary.                                      |

  +------------------------------------------------------------------------+
  | # Enable emergency bypass (WALLIX completely unavailable)              |
  | # This allows direct target access without WALLIX proxy                |
  |                                                                        |
  | # On network firewall/switch:                                          |
  | # 1. Enable emergency ACL that permits direct OT access                |
  | # 2. Document all access during bypass period                          |
  | # 3. Disable bypass ACL immediately after resolution                   |
  |                                                                        |
  | # Example Cisco IOS emergency ACL:                                     |
  | # (pre-configured but normally disabled)                               |
  | interface Vlan100                                                      |
  |   ip access-group EMERGENCY-BYPASS in                                  |
  |                                                                        |
  | # To enable:                                                           |
  | no ip access-group NORMAL-PAM in                                       |
  | ip access-group EMERGENCY-BYPASS in                                    |
  |                                                                        |
  | # To disable (restore normal):                                         |
  | no ip access-group EMERGENCY-BYPASS in                                 |
  | ip access-group NORMAL-PAM in                                          |
  +------------------------------------------------------------------------+

+==============================================================================+
```

---

## Data Diode Integration

### One-Way Data Transfer

```
+==============================================================================+
|                   DATA DIODE ARCHITECTURE                                     |
+==============================================================================+

  DATA DIODE OVERVIEW
  ===================

  +------------------------------------------------------------------------+
  |                                                                        |
  |   A data diode provides hardware-enforced one-way data flow.           |
  |   Data can only flow OUT of the air-gapped network.                    |
  |                                                                        |
  |   +--------------------+                    +--------------------+     |
  |   |   AIR-GAPPED       |                    |   CORPORATE        |     |
  |   |   OT NETWORK       |                    |   NETWORK          |     |
  |   |                    |                    |                    |     |
  |   |  +-------------+   |    DATA DIODE      |   +-------------+  |     |
  |   |  |   WALLIX    |   |                    |   |    SIEM     |  |     |
  |   |  |   Bastion   +---+--->  [=====>]  --->+-->+   Splunk    |  |     |
  |   |  +-------------+   |    (One-way)       |   |   QRadar    |  |     |
  |   |                    |                    |   +-------------+  |     |
  |   |  +-------------+   |                    |                    |     |
  |   |  |   Syslog    +---+--->  [=====>]  --->+--> Log Archive  |  |     |
  |   |  |   Server    |   |    (One-way)       |                    |     |
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

  SUPPORTED DATA DIODE VENDORS
  ============================

  +------------------------------------------------------------------------+
  | Vendor          | Product              | Protocol Support              |
  +-----------------+----------------------+-------------------------------+
  | Waterfall       | Unidirectional       | Syslog, File, OPC, Modbus     |
  |                 | Security Gateway     |                               |
  +-----------------+----------------------+-------------------------------+
  | Owl Cyber      | Dual Diode           | Syslog, SFTP, Database        |
  | Defense        | Transfer             |                               |
  +-----------------+----------------------+-------------------------------+
  | Fox-IT         | DataDiode            | Syslog, HTTP, Custom          |
  +-----------------+----------------------+-------------------------------+
  | Advenica       | SecuriCDS            | Multiple protocols            |
  +-----------------+----------------------+-------------------------------+

+==============================================================================+
```

### Syslog Export Through Data Diode

```
+==============================================================================+
|                   SYSLOG VIA DATA DIODE                                       |
+==============================================================================+

  CONFIGURATION
  =============

  +------------------------------------------------------------------------+
  | # WALLIX syslog configuration for data diode                           |
  | # /etc/opt/wab/wabengine/wabengine.conf                                |
  |                                                                        |
  | [syslog]                                                               |
  | enabled = true                                                         |
  | server = 10.50.1.50          # Data diode input interface              |
  | port = 514                                                             |
  | protocol = udp               # UDP for one-way (no ACK needed)         |
  | format = cef                 # CEF format for SIEM                     |
  | facility = local0                                                      |
  | include_session_events = true                                          |
  | include_auth_events = true                                             |
  | include_admin_events = true                                            |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  CEF LOG FORMAT
  ==============

  +------------------------------------------------------------------------+
  | # Example CEF syslog message from WALLIX                               |
  |                                                                        |
  | CEF:0|WALLIX|Bastion|12.1.5|auth:success|User Authentication|3|        |
  |   src=10.50.2.100 suser=jsmith duser=root@scada-server                 |
  |   act=session_start cs1Label=Target cs1=scada-server.ot.local          |
  |   cs2Label=Protocol cs2=SSH rt=1706720400000                           |
  |                                                                        |
  | CEF:0|WALLIX|Bastion|12.1.5|session:command|Command Executed|2|        |
  |   src=10.50.2.100 suser=jsmith duser=root@scada-server                 |
  |   act=command cs1Label=Command cs1="systemctl status scada-app"        |
  |   rt=1706720450000                                                     |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  LOCAL SYSLOG RELAY (for data diode)
  ====================================

  +------------------------------------------------------------------------+
  | # /etc/rsyslog.d/50-wallix-diode.conf                                  |
  | # Relay WALLIX logs to data diode                                      |
  |                                                                        |
  | # Receive from WALLIX                                                  |
  | $ModLoad imudp                                                         |
  | $UDPServerRun 514                                                      |
  |                                                                        |
  | # Queue for reliability                                                |
  | $ActionQueueType LinkedList                                            |
  | $ActionQueueFileName wallix_diode                                      |
  | $ActionQueueMaxDiskSpace 1g                                            |
  | $ActionQueueSaveOnShutdown on                                          |
  | $ActionResumeRetryCount -1                                             |
  |                                                                        |
  | # Forward to data diode input                                          |
  | *.* @10.50.1.50:514                                                    |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  VERIFICATION
  ============

  +------------------------------------------------------------------------+
  | # Verify syslog is flowing to diode                                    |
  |                                                                        |
  | # Check local queue                                                    |
  | ls -la /var/spool/rsyslog/                                             |
  |                                                                        |
  | # Test syslog generation                                               |
  | logger -p local0.info -t WALLIX "Test message for diode verification"  |
  |                                                                        |
  | # Check WALLIX is sending                                              |
  | tcpdump -i eth0 udp port 514 -c 10                                     |
  |                                                                        |
  | # On corporate side, verify reception                                  |
  | # (via SIEM dashboard or log collector)                                |
  +------------------------------------------------------------------------+

+==============================================================================+
```

### File Transfer Through Data Diode

```
+==============================================================================+
|                   FILE TRANSFER VIA DATA DIODE                                |
+==============================================================================+

  FILE-BASED EXPORT CONFIGURATION
  ===============================

  +------------------------------------------------------------------------+
  | # Configure WALLIX for file-based export to diode share                |
  | # /etc/opt/wab/wabengine/export.conf                                   |
  |                                                                        |
  | [file_export]                                                          |
  | enabled = true                                                         |
  | export_path = /var/export/diode                                        |
  | format = json                                                          |
  | compress = true                                                        |
  | encrypt = true                                                         |
  | encrypt_key = /etc/wallix/diode-export-key.pem                         |
  | schedule = "0 */6 * * *"       # Every 6 hours                         |
  | retention_hours = 168          # Keep 7 days locally                   |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  EXPORT DIRECTORY STRUCTURE
  ==========================

  +------------------------------------------------------------------------+
  |                                                                        |
  |   /var/export/diode/                                                   |
  |   |                                                                    |
  |   +-- audit/                                                           |
  |   |   +-- audit-20260131-0600.json.gz.enc                              |
  |   |   +-- audit-20260131-1200.json.gz.enc                              |
  |   |   +-- audit-20260131-1800.json.gz.enc                              |
  |   |                                                                    |
  |   +-- sessions/                                                        |
  |   |   +-- sessions-20260131-0600.json.gz.enc                           |
  |   |   +-- sessions-20260131-1200.json.gz.enc                           |
  |   |                                                                    |
  |   +-- recordings/                                                      |
  |   |   +-- rec-2026013112345.webm.enc                                   |
  |   |   +-- rec-2026013112346.webm.enc                                   |
  |   |                                                                    |
  |   +-- manifest/                                                        |
  |       +-- manifest-20260131-1800.txt                                   |
  |       +-- checksums-20260131-1800.sha256                               |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  DIODE FILE TRANSFER SCRIPT
  ==========================

  +------------------------------------------------------------------------+
  | #!/bin/bash                                                            |
  | # transfer-to-diode.sh                                                 |
  | # Copy export files to data diode input share                          |
  |                                                                        |
  | set -euo pipefail                                                      |
  |                                                                        |
  | EXPORT_DIR="/var/export/diode"                                         |
  | DIODE_SHARE="/mnt/diode-input"                                         |
  | PROCESSED_DIR="/var/export/processed"                                  |
  |                                                                        |
  | # Ensure diode share is mounted                                        |
  | if ! mountpoint -q $DIODE_SHARE; then                                  |
  |     echo "ERROR: Diode share not mounted"                              |
  |     exit 1                                                             |
  | fi                                                                     |
  |                                                                        |
  | # Copy new files to diode                                              |
  | find $EXPORT_DIR -name "*.enc" -newer $PROCESSED_DIR/.last_transfer \  |
  |   -exec cp {} $DIODE_SHARE/ \;                                         |
  |                                                                        |
  | # Copy manifests and checksums                                         |
  | find $EXPORT_DIR/manifest -newer $PROCESSED_DIR/.last_transfer \       |
  |   -exec cp {} $DIODE_SHARE/ \;                                         |
  |                                                                        |
  | # Update transfer marker                                               |
  | touch $PROCESSED_DIR/.last_transfer                                    |
  |                                                                        |
  | # Archive processed files locally                                      |
  | find $EXPORT_DIR -name "*.enc" -mtime +7 \                             |
  |   -exec mv {} $PROCESSED_DIR/ \;                                       |
  |                                                                        |
  | logger -t wallix-diode "File transfer to diode completed"              |
  +------------------------------------------------------------------------+

+==============================================================================+
```

---

## Time Synchronization

### GPS-Based NTP for Isolated Networks

```
+==============================================================================+
|                   AIR-GAPPED TIME SYNCHRONIZATION                             |
+==============================================================================+

  WHY ACCURATE TIME IS CRITICAL
  =============================

  +------------------------------------------------------------------------+
  |                                                                        |
  |   Accurate time synchronization is essential for:                      |
  |                                                                        |
  |   * TOTP/MFA validation (30-60 second tolerance)                       |
  |   * Audit log accuracy and legal admissibility                         |
  |   * Session timing and correlation                                     |
  |   * Certificate validity checking                                      |
  |   * Event correlation across systems                                   |
  |   * Regulatory compliance (IEC 62443, NERC CIP)                        |
  |                                                                        |
  |   TIME DRIFT IMPACT                                                    |
  |   =================                                                    |
  |                                                                        |
  |   +---------------------+----------------------------------------+     |
  |   | Drift               | Impact                                 |     |
  |   +---------------------+----------------------------------------+     |
  |   | > 30 seconds        | TOTP authentication may fail           |     |
  |   | > 5 minutes         | Audit log accuracy compromised         |     |
  |   | > 1 hour            | Certificate validation issues          |     |
  |   | > 24 hours          | Compliance violations                  |     |
  |   +---------------------+----------------------------------------+     |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  GPS NTP SERVER ARCHITECTURE
  ===========================

  +------------------------------------------------------------------------+
  |                                                                        |
  |   GPS ANTENNA (Roof-mounted)                                           |
  |         |                                                              |
  |         | Coax cable                                                   |
  |         v                                                              |
  |   +------------------+                                                 |
  |   |  GPS Receiver    |  (Garmin, Trimble, or similar)                  |
  |   |  with PPS output |                                                 |
  |   +--------+---------+                                                 |
  |            |                                                           |
  |            | Serial/USB + PPS                                          |
  |            v                                                           |
  |   +------------------+                                                 |
  |   |  NTP Server      |  (Dedicated appliance or Linux server)          |
  |   |  10.50.1.10      |                                                 |
  |   +--------+---------+                                                 |
  |            |                                                           |
  |            | NTP (UDP 123)                                             |
  |            v                                                           |
  |   +------------------------------------------+                         |
  |   |              OT NETWORK                  |                         |
  |   |                                          |                         |
  |   |  [WALLIX]  [SCADA]  [HMI]  [Historian]   |                         |
  |   |                                          |                         |
  |   +------------------------------------------+                         |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  NTP SERVER CONFIGURATION (Linux with GPS)
  =========================================

  +------------------------------------------------------------------------+
  | # /etc/chrony/chrony.conf                                              |
  | # GPS-synchronized NTP server for air-gapped OT network                |
  |                                                                        |
  | # GPS reference clock via gpsd                                         |
  | refclock SHM 0 refid GPS precision 1e-1 offset 0.9999                  |
  | refclock SHM 1 refid PPS precision 1e-9                                |
  |                                                                        |
  | # Backup: Local hardware clock                                         |
  | refclock PHC /dev/ptp0 poll 3 dpoll -2 offset 0                        |
  |                                                                        |
  | # Allow NTP clients from OT network                                    |
  | allow 10.50.0.0/16                                                     |
  |                                                                        |
  | # Stratum if GPS fails                                                 |
  | local stratum 3 orphan                                                 |
  |                                                                        |
  | # Logging                                                              |
  | log tracking measurements statistics                                   |
  | logdir /var/log/chrony                                                 |
  |                                                                        |
  | # Leap second handling                                                 |
  | leapsectz right/UTC                                                    |
  +------------------------------------------------------------------------+

+==============================================================================+
```

### Manual Time Synchronization Procedures

```
+==============================================================================+
|                   MANUAL TIME SYNC PROCEDURES                                 |
+==============================================================================+

  WHEN MANUAL SYNC IS NEEDED
  ==========================

  +------------------------------------------------------------------------+
  |                                                                        |
  |   Manual time synchronization required when:                           |
  |                                                                        |
  |   * GPS receiver fails                                                 |
  |   * NTP server unavailable                                             |
  |   * Initial deployment without GPS                                     |
  |   * Time drift detected > 1 minute                                     |
  |   * Daylight saving time issues                                        |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  MANUAL SYNC PROCEDURE
  =====================

  Step 1: Obtain accurate time reference

  +------------------------------------------------------------------------+
  | # Use a verified time source:                                          |
  | # - WWV/WWVH radio time signal                                         |
  | # - Calibrated atomic clock                                            |
  | # - GPS receiver on mobile device (temporary)                          |
  | # - Telephone time service (NIST: 303-499-7111)                        |
  +------------------------------------------------------------------------+

  Step 2: Stop time-sensitive services

  +------------------------------------------------------------------------+
  | # On WALLIX Bastion                                                    |
  | sudo systemctl stop wallix-bastion                                     |
  |                                                                        |
  | # Notify users of brief outage                                         |
  +------------------------------------------------------------------------+

  Step 3: Set system time

  +------------------------------------------------------------------------+
  | # Set date and time manually                                           |
  | sudo timedatectl set-time "2026-01-31 14:30:00"                        |
  |                                                                        |
  | # Verify time                                                          |
  | timedatectl                                                            |
  |                                                                        |
  | # Sync hardware clock                                                  |
  | sudo hwclock --systohc                                                 |
  +------------------------------------------------------------------------+

  Step 4: Restart services and verify

  +------------------------------------------------------------------------+
  | # Start services                                                       |
  | sudo systemctl start wallix-bastion                                    |
  |                                                                        |
  | # Verify TOTP is working                                               |
  | # (Test login with hardware token)                                     |
  |                                                                        |
  | # Document time sync                                                   |
  | logger -t time-sync "Manual time sync performed: $(date)"              |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  TIME SYNC VERIFICATION SCRIPT
  =============================

  +------------------------------------------------------------------------+
  | #!/bin/bash                                                            |
  | # verify-time-sync.sh                                                  |
  | # Verify time synchronization across OT systems                        |
  |                                                                        |
  | NTP_SERVER="10.50.1.10"                                                |
  | MAX_DRIFT_SECONDS=2                                                    |
  | SYSTEMS="wallix-node1 wallix-node2 scada-server hmi-01"                |
  |                                                                        |
  | echo "Time Synchronization Verification"                               |
  | echo "================================="                               |
  | echo "Reference: $NTP_SERVER (GPS-synced NTP)"                         |
  | echo ""                                                                |
  |                                                                        |
  | REF_TIME=$(ssh $NTP_SERVER "date +%s")                                 |
  |                                                                        |
  | for system in $SYSTEMS; do                                             |
  |     SYS_TIME=$(ssh $system "date +%s" 2>/dev/null)                     |
  |     if [ $? -eq 0 ]; then                                              |
  |         DRIFT=$((SYS_TIME - REF_TIME))                                 |
  |         ABS_DRIFT=${DRIFT#-}                                           |
  |         if [ $ABS_DRIFT -le $MAX_DRIFT_SECONDS ]; then                 |
  |             echo "$system: OK (drift: ${DRIFT}s)"                      |
  |         else                                                           |
  |             echo "$system: WARNING - Drift ${DRIFT}s exceeds threshold"|
  |         fi                                                             |
  |     else                                                               |
  |         echo "$system: ERROR - Cannot connect"                         |
  |     fi                                                                 |
  | done                                                                   |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  WALLIX TIME VERIFICATION
  ========================

  +------------------------------------------------------------------------+
  | # Check WALLIX time status                                             |
  | wabadmin time-status                                                   |
  |                                                                        |
  | # Expected output:                                                     |
  | # Time Synchronization Status                                          |
  | # ===========================                                          |
  | # System Time: 2026-01-31 14:32:45 UTC                                 |
  | # NTP Server: 10.50.1.10                                               |
  | # NTP Status: Synchronized                                             |
  | # Stratum: 1 (GPS reference)                                           |
  | # Offset: +0.003 seconds                                               |
  | # TOTP Window: Valid                                                   |
  |                                                                        |
  | # Force NTP sync                                                       |
  | wabadmin time-sync --force                                             |
  +------------------------------------------------------------------------+

+==============================================================================+
```

---

## Summary

This guide covers comprehensive procedures for operating WALLIX Bastion in air-gapped and offline OT environments:

| Topic | Key Points |
|-------|------------|
| **Offline Operations** | Understanding when and why air-gapped deployments are required |
| **Architecture** | Complete topology for air-gapped WALLIX with local services |
| **Credential Cache** | Local caching for offline access with TTL management |
| **Sneakernet Updates** | Secure export, transfer, and import of credentials |
| **User Management** | Local user provisioning and sync via secure media |
| **License Management** | Offline activation and renewal procedures |
| **Patch Management** | Secure update download, verification, and application |
| **Audit Export** | Log export procedures for SOC integration |
| **Emergency Access** | Break-glass procedures and local admin override |
| **Data Diode** | One-way data transfer for continuous monitoring |
| **Time Sync** | GPS-based NTP and manual sync procedures |

---

## Related Documentation

- [19 - Air-Gapped & Isolated Environments](../19-airgapped-environments/README.md)
- [20 - IEC 62443 Compliance](../20-iec62443-compliance/README.md)
- [29 - Upgrade Guide](../29-upgrade-guide/README.md)
- [30 - Operational Runbooks](../30-operational-runbooks/README.md)
- [40 - Backup and Restore](../40-backup-restore/README.md)

## External References

- WALLIX Documentation: https://pam.wallix.one/documentation
- NIST 800-82 Guide to ICS Security: https://csrc.nist.gov/publications/detail/sp/800-82/rev-3/final
- IEC 62443 Standards: https://www.isa.org/intech-home/2018/september-october/departments/new-satisfying-iec-62443-for-iacs-component-suppli

---

*Document Version: 1.0*
*Last Updated: February 2026*
