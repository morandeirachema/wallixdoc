# 05 - Multi-Site Synchronization

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Primary Site Configuration](#primary-site-configuration)
3. [Secondary Sites Configuration](#secondary-sites-configuration)
4. [Sync Policies](#sync-policies)
5. [Conflict Resolution](#conflict-resolution)
6. [Monitoring and Troubleshooting](#monitoring-and-troubleshooting)

---

## Architecture Overview

```
+==============================================================================+
|                   MULTI-SITE SYNCHRONIZATION ARCHITECTURE                    |
+==============================================================================+

                    +-------------------+
                    |     SITE A        |
                    |    (PRIMARY)      |
                    |                   |
                    | - Master Config   |
                    | - User Directory  |
                    | - Global Policies |
                    | - Audit Logs      |
                    +--------+----------+
                             |
              +--------------+--------------+
              |              |              |
              v              v              v
     +--------+------+ +-----+-------+ +----+--------+
     |    SITE B     | |   SITE C    | |  SITE N...  |
     |  (SECONDARY)  | |  (REMOTE)   | | (SECONDARY) |
     |               | |             | |             |
     | - Sync Users  | | - Sync Users| | - Sync Users|
     | - Sync Devices| | - Cached    | | - Sync All  |
     | - Local OT    | | - Offline   | | - Full HA   |
     +---------------+ +-------------+ +-------------+

  SYNC DIRECTION
  ==============

  +------------------------------------------------------------------------+
  | Data Type          | Direction      | Notes                            |
  +--------------------+----------------+----------------------------------+
  | Users              | Primary -> All | Read-only at secondary sites     |
  | Groups             | Primary -> All | Read-only at secondary sites     |
  | Global Policies    | Primary -> All | Can have local overrides         |
  | Devices (Global)   | Primary -> All | Shared infrastructure            |
  | Devices (Local)    | Local only     | Site-specific OT devices         |
  | Session Recordings | Local -> Prim  | Replicated for central audit     |
  | Audit Logs         | Local -> Prim  | Aggregated at primary            |
  +--------------------+----------------+----------------------------------+

+==============================================================================+
```

---

## Primary Site Configuration

### Enable Multi-Site on Site A

```bash
# On Site A primary node
ssh admin@wallix.site-a.company.com

# Enable multi-site primary role
wab-admin config-set multisite.enabled true
wab-admin config-set multisite.role primary
wab-admin config-set multisite.instance_id site-a

# Generate API keys for secondary sites
wab-admin multisite-generate-key --site site-b --name "Site B Secondary"
# Output: API Key: sk_live_site-b_xxxxxxxxxxxxxxxxxxxx

wab-admin multisite-generate-key --site site-c --name "Site C Remote"
# Output: API Key: sk_live_site-c_xxxxxxxxxxxxxxxxxxxx

# Configure allowed secondary sites
wab-admin multisite-add-secondary \
    --site-id site-b \
    --name "Site B - Secondary Plant" \
    --url https://wallix.site-b.company.com \
    --sync-mode full

wab-admin multisite-add-secondary \
    --site-id site-c \
    --name "Site C - Remote Site" \
    --url https://wallix.site-c.company.com \
    --sync-mode cached    # Optimized for low bandwidth
```

### Configure Sync Objects

```json
// /etc/opt/wab/multisite.json
{
  "multisite": {
    "enabled": true,
    "role": "primary",
    "instance_id": "site-a",

    "sync_objects": {
      "users": {
        "enabled": true,
        "filter": "all",
        "include_passwords": false,
        "include_mfa_seeds": true
      },
      "groups": {
        "enabled": true,
        "filter": "all"
      },
      "devices": {
        "enabled": true,
        "filter": "global_only",
        "exclude_local": true
      },
      "authorizations": {
        "enabled": true,
        "filter": "all"
      },
      "policies": {
        "enabled": true,
        "allow_local_override": true
      },
      "credentials": {
        "enabled": true,
        "encrypted": true,
        "vault_sync": true
      }
    },

    "secondary_sites": [
      {
        "id": "site-b",
        "name": "Site B - Secondary Plant",
        "url": "https://wallix.site-b.company.com",
        "api_key_hash": "<hashed_key>",
        "sync_mode": "full",
        "sync_interval": 300,
        "enabled": true
      },
      {
        "id": "site-c",
        "name": "Site C - Remote Site",
        "url": "https://wallix.site-c.company.com",
        "api_key_hash": "<hashed_key>",
        "sync_mode": "cached",
        "sync_interval": 3600,
        "offline_capable": true,
        "enabled": true
      }
    ]
  }
}
```

### Configure Audit Log Aggregation

```bash
# Enable audit log collection from secondary sites
wab-admin config-set audit.aggregation.enabled true
wab-admin config-set audit.aggregation.sources "site-b,site-c"
wab-admin config-set audit.aggregation.retention_days 365
wab-admin config-set audit.aggregation.compression true

# Configure session recording aggregation
wab-admin config-set recordings.aggregation.enabled true
wab-admin config-set recordings.aggregation.storage_path /var/wab/recorded/aggregated
wab-admin config-set recordings.aggregation.schedule "0 3 * * *"  # 3 AM daily
```

---

## Secondary Sites Configuration

### Site B Configuration

```bash
# On Site B primary node
ssh admin@wallix.site-b.company.com

# Configure as secondary
wab-admin config-set multisite.enabled true
wab-admin config-set multisite.role secondary
wab-admin config-set multisite.instance_id site-b
wab-admin config-set multisite.primary_url https://wallix.site-a.company.com
wab-admin config-set multisite.api_key 'sk_live_site-b_xxxxxxxxxxxxxxxxxxxx'

# Configure sync behavior
wab-admin config-set multisite.sync_interval 300           # 5 minutes
wab-admin config-set multisite.sync_on_startup true
wab-admin config-set multisite.sync_timeout 120            # 2 minutes

# Configure what to sync
wab-admin config-set multisite.sync.users true
wab-admin config-set multisite.sync.groups true
wab-admin config-set multisite.sync.devices_global true
wab-admin config-set multisite.sync.devices_local false    # Keep local OT devices
wab-admin config-set multisite.sync.authorizations true
wab-admin config-set multisite.sync.policies true

# Configure audit log forwarding
wab-admin config-set audit.forward.enabled true
wab-admin config-set audit.forward.destination https://wallix.site-a.company.com/api/audit
wab-admin config-set audit.forward.batch_size 100
wab-admin config-set audit.forward.interval 60

# Initial sync
wab-admin multisite-sync --full
```

### Site C Configuration (Offline-Capable)

```bash
# On Site C
ssh admin@wallix.site-c.company.com

# Configure as secondary with offline capability
wab-admin config-set multisite.enabled true
wab-admin config-set multisite.role secondary
wab-admin config-set multisite.instance_id site-c
wab-admin config-set multisite.primary_url https://wallix.site-a.company.com
wab-admin config-set multisite.api_key 'sk_live_site-c_xxxxxxxxxxxxxxxxxxxx'

# Configure for limited bandwidth / offline operation
wab-admin config-set multisite.sync_interval 3600          # 1 hour
wab-admin config-set multisite.offline_mode true
wab-admin config-set multisite.cache_enabled true
wab-admin config-set multisite.cache_ttl 86400             # 24 hours
wab-admin config-set multisite.bandwidth_limit 1024        # 1 Mbps
wab-admin config-set multisite.compression true
wab-admin config-set multisite.delta_sync true             # Only sync changes

# Configure scheduled sync (off-peak)
wab-admin config-set multisite.sync_schedule "0 2 * * *"   # 2 AM daily

# Configure local fallback
wab-admin config-set multisite.fallback.enabled true
wab-admin config-set multisite.fallback.cache_auth true
wab-admin config-set multisite.fallback.local_admins true

# Initial sync (when online)
wab-admin multisite-sync --full
```

---

## Sync Policies

### Object Sync Matrix

```
+==============================================================================+
|                   SYNC POLICY MATRIX                                         |
+==============================================================================+

  +------------------------------------------------------------------------+
  | Object Type      | Site A    | Site B    | Site C    | Conflict Rule  |
  +------------------+-----------+-----------+-----------+----------------+
  | Users            | Read/Write| Read-Only | Cached    | Primary wins   |
  | Groups           | Read/Write| Read-Only | Cached    | Primary wins   |
  | Global Devices   | Read/Write| Read-Only | Read-Only | Primary wins   |
  | Local Devices    | N/A       | Read/Write| Read/Write| Local only     |
  | Authorizations   | Read/Write| Read-Only | Cached    | Primary wins   |
  | Policies (Global)| Read/Write| Read-Only | Read-Only | Primary wins   |
  | Policies (Local) | N/A       | Read/Write| Read/Write| Local only     |
  | Credentials      | Read/Write| Read-Only | Cached    | Primary wins   |
  | Audit Logs       | Aggregate | Forward   | Forward   | Merge all      |
  | Recordings       | Aggregate | Forward   | Forward   | Merge all      |
  +------------------+-----------+-----------+-----------+----------------+

  --------------------------------------------------------------------------

  SYNC MODES
  ==========

  FULL SYNC (Site B):
  - All objects synchronized in real-time
  - Changes propagated within sync_interval
  - Requires stable network connection
  - Best for: Well-connected secondary sites

  CACHED SYNC (Site C):
  - Objects cached locally with TTL
  - Changes synced on schedule
  - Operates offline with cached data
  - Best for: Remote sites with limited connectivity

  DELTA SYNC:
  - Only changed objects transferred
  - Reduces bandwidth usage
  - Uses timestamps and hashes
  - Enabled by: multisite.delta_sync = true

+==============================================================================+
```

### Local Override Configuration

```bash
# Configure local policy overrides (Site B example)

# Allow local session recording policy
wab-admin policy-override create \
    --name "site-b-recording-policy" \
    --type session_recording \
    --scope local \
    --settings '{
        "record_keystrokes": true,
        "record_video": true,
        "retention_days": 180
    }'

# Allow local time restrictions
wab-admin policy-override create \
    --name "site-b-time-policy" \
    --type time_restriction \
    --scope local \
    --settings '{
        "allowed_hours": "06:00-22:00",
        "timezone": "Europe/Berlin",
        "allowed_days": ["Mon","Tue","Wed","Thu","Fri"]
    }'
```

---

## Conflict Resolution

### Conflict Scenarios

```
+==============================================================================+
|                   CONFLICT RESOLUTION                                        |
+==============================================================================+

  SCENARIO 1: User Modified at Both Sites
  =======================================

  Condition: User updated at primary while secondary was offline

  Resolution:
  1. Primary version always wins for synced objects
  2. Secondary receives updated version on next sync
  3. Local changes at secondary are discarded
  4. Audit log records conflict and resolution

  Example:
  +------------------------------------------------------------------------+
  | Time     | Site A Action      | Site B Action      | Result           |
  +----------+--------------------+--------------------+------------------+
  | 10:00    | User "john" group  | (Offline)          |                  |
  |          | changed to "admin" |                    |                  |
  | 10:30    | (No change)        | Comes online       | Sync triggered   |
  | 10:31    | (No change)        | Receives update    | "john" -> admin  |
  +----------+--------------------+--------------------+------------------+

  --------------------------------------------------------------------------

  SCENARIO 2: Local vs Global Device Conflict
  ==========================================

  Condition: Device with same name exists locally and globally

  Resolution:
  1. Global devices have namespace prefix: "global/"
  2. Local devices have namespace prefix: "local/"
  3. Both can coexist without conflict
  4. Authorizations reference namespaced names

  Example:
  - global/web-server-01 (from Site A)
  - local/plc-line-01 (Site B local OT device)

  --------------------------------------------------------------------------

  SCENARIO 3: Credential Vault Conflict
  =====================================

  Condition: Password rotated at primary, cached version at secondary

  Resolution:
  1. Primary vault is authoritative
  2. Secondary receives new credentials on sync
  3. Cached credentials updated
  4. Sessions using old credentials may fail (re-auth required)

  Configuration:
  wab-admin config-set vault.sync_priority primary
  wab-admin config-set vault.cache_invalidation immediate

+==============================================================================+
```

### Conflict Logging

```bash
# View sync conflicts
wab-admin multisite-conflicts --last 100

# Example output:
# Timestamp           | Object Type | Object ID    | Conflict Type  | Resolution
# 2026-01-27 10:31:00 | user        | john.smith   | version_mismatch | primary_wins
# 2026-01-27 09:15:00 | credential  | admin@plc-01 | cache_expired  | refreshed
# 2026-01-26 14:00:00 | policy      | time-restrict| local_override | merged

# Export conflict report
wab-admin multisite-conflicts --export /tmp/conflicts.csv --from 2026-01-01
```

---

## Monitoring and Troubleshooting

### Sync Status Monitoring

```bash
# Check overall sync status
wab-admin multisite-status

# Example output:
# ============================================================
# Multi-Site Synchronization Status
# ============================================================
# Role: Primary
# Instance ID: site-a
#
# Secondary Sites:
# +-----------+---------------------------+--------+------------------+
# | Site ID   | URL                       | Status | Last Sync        |
# +-----------+---------------------------+--------+------------------+
# | site-b    | wallix.site-b.company.com | ONLINE | 2026-01-27 14:30 |
# | site-c    | wallix.site-c.company.com | ONLINE | 2026-01-27 02:00 |
# +-----------+---------------------------+--------+------------------+
#
# Sync Statistics (last 24 hours):
# - Total syncs: 288
# - Successful: 286
# - Failed: 2
# - Objects synced: 15,432
# - Conflicts resolved: 3

# Check specific site
wab-admin multisite-status --site site-b --detailed
```

### Troubleshooting Commands

```bash
# Test connectivity to secondary
wab-admin multisite-test --site site-b

# Force sync to specific site
wab-admin multisite-sync --site site-b --force

# Reset sync state (re-sync all objects)
wab-admin multisite-sync --site site-c --full --reset

# Check sync queue
wab-admin multisite-queue

# View sync errors
wab-admin multisite-errors --last 50

# Check replication lag
wab-admin multisite-lag
```

### Common Issues

```
+==============================================================================+
|                   TROUBLESHOOTING GUIDE                                      |
+==============================================================================+

  ISSUE: Sync failing with "Connection refused"
  =============================================

  Cause: Firewall blocking port 443 between sites

  Solution:
  1. Verify firewall rules allow HTTPS between sites
  2. Test: curl -k https://wallix.site-a.company.com/api/status
  3. Check VPN/MPLS tunnel status

  --------------------------------------------------------------------------

  ISSUE: "API key invalid" error
  ==============================

  Cause: API key mismatch or expired

  Solution:
  1. Regenerate API key on primary: wab-admin multisite-generate-key --site site-b
  2. Update key on secondary: wab-admin config-set multisite.api_key '<new_key>'
  3. Test: wab-admin multisite-test

  --------------------------------------------------------------------------

  ISSUE: Objects not syncing
  ==========================

  Cause: Sync filter excluding objects

  Solution:
  1. Check sync configuration: wab-admin config-get multisite.sync
  2. Verify object not marked as local-only
  3. Check sync logs: wab-admin multisite-logs --last 100

  --------------------------------------------------------------------------

  ISSUE: High sync latency
  ========================

  Cause: Large number of objects or slow network

  Solution:
  1. Enable delta sync: wab-admin config-set multisite.delta_sync true
  2. Enable compression: wab-admin config-set multisite.compression true
  3. Increase sync interval for remote sites
  4. Schedule full syncs during off-peak hours

+==============================================================================+
```

---

**Next Step**: [06-ot-network-config.md](./06-ot-network-config.md) - OT Network Configuration
