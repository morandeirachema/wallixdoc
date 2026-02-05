# Licensing - License Pools and Integration

> Comprehensive guide for WALLIX Bastion and Access Manager license management across 5 sites

---

## Table of Contents

1. [Licensing Overview](#licensing-overview)
2. [License Pool Architecture](#license-pool-architecture)
3. [License Calculation](#license-calculation)
4. [License Activation Methods](#license-activation-methods)
5. [Access Manager Integration](#access-manager-integration)
6. [Session Quota Management](#session-quota-management)
7. [Monitoring and Alerting](#monitoring-and-alerting)
8. [License Renewal Procedures](#license-renewal-procedures)
9. [Troubleshooting](#troubleshooting)

---

## Licensing Overview

### WALLIX Licensing Model

WALLIX Bastion uses a **concurrent session-based** licensing model:

| Metric | Description |
|--------|-------------|
| **License Unit** | 1 concurrent user session |
| **Scope** | Active sessions (SSH, RDP, VNC, HTTP, etc.) |
| **Sharing** | License pool shared across HA cluster (not per appliance) |
| **Grace Period** | 30 days after license expiration (with warnings) |
| **Enforcement** | New sessions blocked when pool exhausted |

### Deployment Licensing Summary

```
+===============================================================================+
|  LICENSING BREAKDOWN - 5 SITES + ACCESS MANAGER                               |
+===============================================================================+
|                                                                               |
|  LICENSE POOL A: Access Manager                                               |
|  +---------------------------------------+                                    |
|  | Component: 2x Access Manager (HA)     |                                    |
|  | Sessions: 500 concurrent              |                                    |
|  | Managed By: Separate team             |                                    |
|  | Integration: Optional unified pool    |                                    |
|  +---------------------------------------+                                    |
|                                                                               |
|  LICENSE POOL B: WALLIX Bastion (Your Deployment)                            |
|  +---------------------------------------+                                    |
|  | Sites: 5 (Paris DC-P1 to DC-P5)       |                                    |
|  | Appliances: 10 (2 per site in HA)     |                                    |
|  | Licensed Units: 5 HA clusters         |                                    |
|  | Sessions: 450 concurrent              |                                    |
|  | Sharing: Pool shared across 5 sites   |                                    |
|  +---------------------------------------+                                    |
|                                                                               |
|  TOTAL CAPACITY: 950 concurrent sessions (AM 500 + Bastion 450)              |
|                                                                               |
|  KEY PRINCIPLE: HA cluster = 1 license (NOT 2)                               |
|                 10 appliances = 5 HA pairs = 5 licenses needed               |
|                                                                               |
+===============================================================================+
```

### Why Split Pools?

| Pool | Purpose | Managed By |
|------|---------|------------|
| **Access Manager** | SSO, MFA, session brokering to Bastions | Separate team |
| **Bastion** | PAM enforcement, credential vault, session recording | Your team |

**Optional**: Pools can be integrated for unified management (covered in [Access Manager Integration](#access-manager-integration)).

---

## License Pool Architecture

### Architecture Option 1: Split Pools (Default)

```
+===============================================================================+
|  SPLIT LICENSE POOLS - INDEPENDENT MANAGEMENT                                 |
+===============================================================================+
|                                                                               |
|  +---------------------------------+     +---------------------------------+  |
|  |  ACCESS MANAGER LICENSE POOL    |     |  BASTION LICENSE POOL           |  |
|  |                                 |     |                                 |  |
|  |  Total: 500 sessions            |     |  Total: 450 sessions            |  |
|  |  Managed: Separately            |     |  Managed: By your team          |  |
|  |                                 |     |                                 |  |
|  |  +---------------------------+  |     |  +---------------------------+  |  |
|  |  | AM-1 (DC-A)               |  |     |  | Site 1: 90 sessions       |  |  |
|  |  | AM-2 (DC-B)               |  |     |  | Site 2: 90 sessions       |  |  |
|  |  | (HA pair shares pool)     |  |     |  | Site 3: 90 sessions       |  |  |
|  |  +---------------------------+  |     |  | Site 4: 90 sessions       |  |  |
|  |                                 |     |  | Site 5: 90 sessions       |  |  |
|  |  Enforces: AM session limits    |     |  +---------------------------+  |  |
|  |  Does NOT affect Bastion pool   |     |  Shared dynamically across sites |  |
|  +---------------------------------+     +---------------------------------+  |
|                                                                               |
|  Use Case:                                                                    |
|  - Separate operational control                                              |
|  - Independent billing/accounting                                            |
|  - Bastion team manages own capacity                                         |
|                                                                               |
+===============================================================================+
```

### Architecture Option 2: Unified Pool (Optional)

```
+===============================================================================+
|  UNIFIED LICENSE POOL - CENTRALIZED MANAGEMENT VIA ACCESS MANAGER             |
+===============================================================================+
|                                                                               |
|  +---------------------------------------------------------------------+      |
|  |               CENTRALIZED LICENSE SERVER (ACCESS MANAGER)           |      |
|  |                                                                     |      |
|  |  Total Pool: 950 sessions (AM 500 + Bastion 450)                   |      |
|  |  Dynamic Allocation: Sessions allocated on-demand                   |      |
|  |                                                                     |      |
|  |  +------------------------------------------------------------+     |      |
|  |  | Current Allocation:                                        |     |      |
|  |  |   Access Manager: 200/500 (40%)                            |     |      |
|  |  |   Bastion Site 1: 85/450 (19%)                             |     |      |
|  |  |   Bastion Site 2: 120/450 (27%)                            |     |      |
|  |  |   Bastion Site 3: 50/450 (11%)                             |     |      |
|  |  |   Bastion Site 4: 90/450 (20%)                             |     |      |
|  |  |   Bastion Site 5: 105/450 (23%)                            |     |      |
|  |  +------------------------------------------------------------+     |      |
|  +---------------------------------------------------------------------+      |
|                             |                                                |
|              +--------------+---------------+                                |
|              |              |               |                                |
|   +----------v---+   +------v------+   +---v----------+                      |
|   | AM-1 (DC-A)  |   | Site 1-3    |   | Site 4-5     |                      |
|   | AM-2 (DC-B)  |   | Paris       |   | Paris        |                      |
|   +--------------+   +-------------+   +--------------+                      |
|                                                                               |
|  Advantages:                                                                  |
|  - Centralized visibility and control                                        |
|  - Dynamic session reallocation                                              |
|  - Single renewal process                                                    |
|                                                                               |
|  Requirements:                                                                |
|  - Network connectivity: Bastion -> Access Manager (443/tcp)                 |
|  - Access Manager license server API access                                  |
|  - Coordination with Access Manager team                                     |
|                                                                               |
+===============================================================================+
```

---

## License Calculation

### Per-Site Calculation

| Site | Appliances | HA Configuration | License Units Required |
|------|------------|------------------|------------------------|
| **Site 1** | 2 (Bastion-1, Bastion-2) | Active-Active HA | 1 HA cluster = **1 license** |
| **Site 2** | 2 (Bastion-1, Bastion-2) | Active-Active HA | 1 HA cluster = **1 license** |
| **Site 3** | 2 (Bastion-1, Bastion-2) | Active-Active HA | 1 HA cluster = **1 license** |
| **Site 4** | 2 (Bastion-1, Bastion-2) | Active-Active HA | 1 HA cluster = **1 license** |
| **Site 5** | 2 (Bastion-1, Bastion-2) | Active-Active HA | 1 HA cluster = **1 license** |

**Total Bastion Licenses Required**: **5 licenses** (NOT 10)

### Session Capacity Planning

#### Current Deployment

| Metric | Value |
|--------|-------|
| **Total Bastion Sessions** | 450 concurrent |
| **Sites** | 5 |
| **Average per Site** | 90 concurrent sessions |
| **Peak Capacity per Site** | Up to 450 (entire pool if needed) |

#### Recommended Allocation Strategy

**Option A: Equal Distribution (Simple)**

```
Site 1: 90 sessions
Site 2: 90 sessions
Site 3: 90 sessions
Site 4: 90 sessions
Site 5: 90 sessions
```

**Option B: Weighted by Load (Optimized)**

```
Site 1 (High Load):   120 sessions
Site 2 (Medium Load): 100 sessions
Site 3 (Medium Load): 100 sessions
Site 4 (Low Load):     70 sessions
Site 5 (Low Load):     60 sessions
```

**Key**: Pool is **shared dynamically**, so these are targets, not hard limits.

#### Capacity Sizing

```bash
# Formula: Required concurrent sessions = Peak users × Concurrency factor

# Example calculation:
Total PAM Users: 500
Peak Active Users: 60% = 300 users
Average Sessions per User: 1.5 (e.g., 1 SSH + 1 RDP)
Concurrency Factor: 0.8 (not all peak users online simultaneously)

Required Sessions = 300 × 1.5 × 0.8 = 360 sessions

# Add 20% overhead for bursts
Recommended License Pool = 360 × 1.2 = 432 sessions

# Round up: 450 sessions ✓
```

### HA Licensing Rules

| Configuration | Appliances | License Units | Reasoning |
|---------------|------------|---------------|-----------|
| **Active-Active** | 2 | 1 | Cluster shares session pool |
| **Active-Passive** | 2 | 1 | Passive node does NOT consume license |
| **Standalone** | 1 | 1 | Single appliance, no HA |

**Important**: WALLIX licenses the **cluster**, not individual appliances. An HA pair (Active-Active or Active-Passive) counts as **1 license unit**.

---

## License Activation Methods

### Method 1: Online Activation (Recommended)

For Bastion appliances with internet connectivity:

```bash
# SSH to primary Bastion appliance
ssh admin@10.10.1.11

# Activate license online
wabadmin license activate --key "XXXX-XXXX-XXXX-XXXX" --method online

# Verify activation
wabadmin license-info

# Expected output:
# License Status: Active
# Type: Commercial
# Sessions: 90 (allocated to this cluster)
# Expiration: 2027-02-05
# License Server: bastion-license.wallix.com
```

### Method 2: Offline Activation (Air-Gapped Environments)

For Bastion appliances without internet access:

#### Step 1: Generate Activation Request

```bash
# On Bastion appliance
wabadmin license generate-request --output /tmp/license-request.xml

# Copy file to workstation with internet access
scp admin@10.10.1.11:/tmp/license-request.xml ./
```

#### Step 2: Submit to WALLIX Portal

```bash
# From workstation with internet access:
# 1. Navigate to: https://support.wallix.com/license
# 2. Login with WALLIX customer credentials
# 3. Upload license-request.xml
# 4. Download license-response.xml
```

#### Step 3: Apply License File

```bash
# Copy license file to Bastion
scp license-response.xml admin@10.10.1.11:/tmp/

# Apply license
wabadmin license activate --file /tmp/license-response.xml

# Verify
wabadmin license-info
```

### Method 3: License Server (Shared Pool)

For dynamic session allocation across sites:

```bash
# Configure Bastion to use central license server
wabadmin license server-config \
  --url "https://license-server.corp.local:8443/api" \
  --auth-token "<API_TOKEN>" \
  --pool-name "Bastion-Production" \
  --check-interval 300  # Check every 5 minutes

# Test connectivity
wabadmin license server-test

# Apply configuration
wabadmin license server-enable

# Verify license retrieval
wabadmin license-info

# Expected:
# License Status: Active
# Source: License Server (license-server.corp.local)
# Sessions: 450 (pool shared across 5 sites)
# Current Usage: 127/450 (28%)
```

### License Activation Per Site

| Site | Appliance | License Key | Activation Method | Sessions Allocated |
|------|-----------|-------------|-------------------|-------------------|
| **Site 1** | 10.10.1.11 (primary) | SITE1-XXXX-XXXX | Online / License Server | 90 (or dynamic) |
| **Site 2** | 10.10.2.11 (primary) | SITE2-XXXX-XXXX | Online / License Server | 90 (or dynamic) |
| **Site 3** | 10.10.3.11 (primary) | SITE3-XXXX-XXXX | Online / License Server | 90 (or dynamic) |
| **Site 4** | 10.10.4.11 (primary) | SITE4-XXXX-XXXX | Online / License Server | 90 (or dynamic) |
| **Site 5** | 10.10.5.11 (primary) | SITE5-XXXX-XXXX | Online / License Server | 90 (or dynamic) |

**Note**: Only **primary appliance** in HA cluster needs license activation. Secondary inherits via cluster sync.

---

## Access Manager Integration

### Integration Architecture

```
+===============================================================================+
|  ACCESS MANAGER LICENSE INTEGRATION                                           |
+===============================================================================+
|                                                                               |
|  +-------------------------------------+                                      |
|  |  ACCESS MANAGER LICENSE SERVER      |  Centralized License Pool            |
|  |  (AM-1: DC-A, AM-2: DC-B in HA)     |  - 500 AM sessions                   |
|  |                                     |  - 450 Bastion sessions              |
|  |  API Endpoint:                      |  - Dynamic allocation                |
|  |  https://am.corp.local/api/license  |  - Real-time monitoring              |
|  +-----------------+-------------------+                                      |
|                    |                                                          |
|                    | HTTPS (443/tcp)                                        |
|                    | License API Calls                                       |
|                    |                                                          |
|       +------------+------------+------------+------------+                   |
|       |            |            |            |            |                   |
|  +----v----+  +----v----+  +----v----+  +----v----+  +----v----+            |
|  | Site 1  |  | Site 2  |  | Site 3  |  | Site 4  |  | Site 5  |            |
|  | Bastion |  | Bastion |  | Bastion |  | Bastion |  | Bastion |            |
|  | Cluster |  | Cluster |  | Cluster |  | Cluster |  | Cluster |            |
|  +---------+  +---------+  +---------+  +---------+  +---------+            |
|                                                                               |
|  Integration Benefits:                                                        |
|  - Centralized license visibility across AM + Bastion                        |
|  - Single renewal process (no per-site activation)                           |
|  - Dynamic session reallocation (e.g., move sessions from Site 1 to Site 4)  |
|  - Unified compliance reporting                                              |
|                                                                               |
+===============================================================================+
```

### Configuration Steps

#### On Access Manager (Performed by AM Team)

```bash
# SSH to Access Manager
ssh admin@am1.corp.local

# Create license pool for Bastions
am-admin license pool create \
  --name "Bastion-Production" \
  --total-sessions 450 \
  --allow-overdraft false \
  --alert-threshold 90

# Generate API token for Bastion access
am-admin api token create \
  --name "Bastion-License-API" \
  --permissions "license:read,license:checkout" \
  --expiration "2027-12-31"

# Output: API_TOKEN=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Share API token securely with Bastion team
```

#### On WALLIX Bastion (Your Configuration)

```bash
# Configure on primary Bastion appliance per site
# Example: Site 1
ssh admin@10.10.1.11

# Configure license server integration
wabadmin license server-config \
  --url "https://am.corp.local/api/license" \
  --auth-token "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  --pool-name "Bastion-Production" \
  --site-id "site1" \
  --check-interval 300 \
  --failover-mode "local-cache"  # Use cached license if server unreachable

# Enable license server mode
wabadmin license server-enable

# Test connectivity and license retrieval
wabadmin license server-test

# Expected:
# Connection: OK
# Pool: Bastion-Production
# Available Sessions: 450
# Allocated to Site 1: 90
# License Valid Until: 2027-02-05
```

#### Replicate Across Sites

```bash
# Repeat for each site, changing site-id
# Site 2:
ssh admin@10.10.2.11
wabadmin license server-config --url "https://am.corp.local/api/license" \
  --auth-token "<TOKEN>" --pool-name "Bastion-Production" --site-id "site2"
wabadmin license server-enable

# Site 3-5: Same process with site-id "site3", "site4", "site5"
```

### License Server Failover

```bash
# Configure fallback to local license file if AM unreachable
wabadmin license failover-config \
  --mode "local-cache" \
  --cache-ttl 86400 \
  --offline-grace-period 7  # 7 days

# Prepare emergency local license
wabadmin license cache-export --output /root/emergency-license.xml

# If AM becomes unreachable:
wabadmin license activate --file /root/emergency-license.xml
```

---

## Session Quota Management

### Setting Per-Site Quotas

```bash
# On primary Bastion appliance
wabadmin quota set \
  --site "site1" \
  --max-sessions 90 \
  --warning-threshold 80 \
  --action-on-exceed "block"  # Options: block, warn, queue

# Verify quota
wabadmin quota show --site "site1"

# Expected:
# Site: Site 1 (Paris DC-P1)
# Max Sessions: 90
# Current Usage: 42/90 (47%)
# Status: OK
```

### Dynamic Quota Adjustment

```bash
# Increase Site 1 quota (e.g., during peak usage)
wabadmin quota modify --site "site1" --max-sessions 120

# Decrease Site 4 quota (redistribute to Site 1)
wabadmin quota modify --site "site4" --max-sessions 60

# Verify total still within pool limit
wabadmin quota summary

# Expected:
# Pool Total: 450 sessions
# Allocated:
#   Site 1: 120
#   Site 2: 90
#   Site 3: 90
#   Site 4: 60
#   Site 5: 90
# Unallocated: 0 (450 allocated)
```

### Queue Management (Session Overflow)

```bash
# Enable session queueing instead of hard blocking
wabadmin queue config \
  --enabled true \
  --max-queue-size 20 \
  --max-wait-time 300  # 5 minutes

# Users exceeding quota are queued
# When a session ends, next user in queue is admitted

# Monitor queue status
wabadmin queue status

# Expected:
# Queue Size: 3
# Longest Wait: 42 seconds
# Queued Users:
#   - jdoe (waiting 42s)
#   - asmith (waiting 18s)
#   - bjohnson (waiting 5s)
```

### User-Based Session Limits

```bash
# Limit concurrent sessions per user (prevent session hoarding)
wabadmin user-policy set \
  --user-group "Standard-Users" \
  --max-concurrent-sessions 2

wabadmin user-policy set \
  --user-group "Admin-Users" \
  --max-concurrent-sessions 5

# Verify
wabadmin user-policy list
```

---

## Monitoring and Alerting

### Real-Time License Monitoring

#### Dashboard View (Web UI)

Navigate to: **Administration → Licensing → Session Usage**

| Metric | Current | Threshold | Status |
|--------|---------|-----------|--------|
| **Total Pool** | 450 | N/A | Active |
| **Used Sessions** | 287 | 405 (90%) | OK |
| **Available Sessions** | 163 | N/A | OK |
| **Peak Today** | 398 | N/A | 88% |
| **License Expiration** | 2027-02-05 | 30 days warning | 365 days |

#### CLI Monitoring

```bash
# Check license status
wabadmin license-info

# Expected:
# License Type: Commercial
# Sessions Licensed: 450
# Sessions Active: 287
# Sessions Available: 163
# Utilization: 63.8%
# Expiration: 2027-02-05 (365 days remaining)
# Status: OK

# Get per-site breakdown
wabadmin license-info --breakdown

# Expected:
# Site 1: 85/90 (94%) - WARNING: High utilization
# Site 2: 67/90 (74%)
# Site 3: 45/90 (50%)
# Site 4: 52/90 (58%)
# Site 5: 38/90 (42%)
# Total: 287/450 (63.8%)
```

### Prometheus Metrics Export

```bash
# Enable Prometheus exporter for license metrics
wabadmin monitoring prometheus-config \
  --enabled true \
  --port 9100 \
  --metrics "license,sessions,users"

# Verify metrics endpoint
curl http://10.10.1.11:9100/metrics | grep wallix_license

# Example metrics:
# wallix_license_total{pool="Bastion-Production"} 450
# wallix_license_used{site="site1"} 85
# wallix_license_used{site="site2"} 67
# wallix_license_available 163
# wallix_license_utilization_percent 63.8
# wallix_license_expiry_days 365
```

### Grafana Dashboard

```bash
# Import WALLIX Bastion dashboard template
# Dashboard ID: wallix-bastion-license-overview

# Key panels:
# - Session usage gauge (0-450)
# - Per-site session breakdown (stacked bar chart)
# - Session trend (last 7 days)
# - License expiration countdown
# - Queue size (if enabled)
```

### Alerting Rules

#### Alert 1: High License Utilization

```bash
# Configure alert at 90% utilization
wabadmin alert create \
  --name "License Utilization High" \
  --condition "license_used >= license_total * 0.9" \
  --severity "warning" \
  --notification "email,syslog,snmp" \
  --recipients "pam-admins@corp.local"

# Test alert
wabadmin alert test --name "License Utilization High"
```

#### Alert 2: License Expiration Warning

```bash
# Alert 60 days before expiration
wabadmin alert create \
  --name "License Expiring Soon" \
  --condition "license_expiry_days <= 60" \
  --severity "warning" \
  --notification "email" \
  --recipients "pam-admins@corp.local,procurement@corp.local"

# Alert 30 days before expiration (critical)
wabadmin alert create \
  --name "License Expiration Critical" \
  --condition "license_expiry_days <= 30" \
  --severity "critical" \
  --notification "email,sms" \
  --recipients "pam-admins@corp.local,management@corp.local"
```

#### Alert 3: License Server Unreachable

```bash
# Alert if license server (Access Manager) is down
wabadmin alert create \
  --name "License Server Unreachable" \
  --condition "license_server_status != 'ok'" \
  --severity "critical" \
  --notification "email,pagerduty" \
  --recipients "pam-admins@corp.local"
```

### SIEM Integration

```bash
# Send license events to SIEM (Splunk, QRadar, etc.)
wabadmin syslog config \
  --enabled true \
  --server "siem.corp.local" \
  --port 514 \
  --protocol "tcp" \
  --format "rfc5424" \
  --facility "local7"

# Configure which events to send
wabadmin syslog filter \
  --include "license_checkout,license_release,license_denied,license_expiry"

# Example syslog message:
# <189>1 2026-02-05T14:23:45.123Z bastion1 wabadmin - - [license event="checkout" user="jdoe" sessions_used=288 sessions_total=450]
```

---

## License Renewal Procedures

### Pre-Renewal Checklist

| Task | Deadline | Owner | Status |
|------|----------|-------|--------|
| **Forecast session needs** | 90 days before expiration | PAM Admin | [ ] |
| **Request quote from WALLIX** | 60 days before expiration | Procurement | [ ] |
| **Approve PO** | 45 days before expiration | Management | [ ] |
| **Receive license keys** | 30 days before expiration | Procurement | [ ] |
| **Test license activation** | 14 days before expiration | PAM Admin | [ ] |
| **Production renewal** | 7 days before expiration | PAM Admin | [ ] |

### Renewal Process

#### Step 1: Generate Renewal Request

```bash
# 60 days before expiration, generate renewal request
wabadmin license renewal-request \
  --current-sessions 450 \
  --requested-sessions 500 \
  --justification "20% user growth projected" \
  --output /tmp/license-renewal-request.pdf

# Send to WALLIX sales representative
```

#### Step 2: Receive Renewal License Keys

WALLIX provides:
- New license keys (5 keys for 5 sites OR 1 unified pool key)
- Activation instructions
- Expiration date (typically +1 year)

#### Step 3: Test License Activation (Non-Production)

```bash
# Activate new license on test/pre-prod environment first
# See: /pre/README.md for lab environment

ssh admin@bastion-lab.corp.local
wabadmin license activate --key "RENEWAL-XXXX-XXXX-XXXX"
wabadmin license-info

# Expected:
# Sessions: 500 (increased from 450)
# Expiration: 2028-02-05 (1 year extension)
# Status: Active
```

#### Step 4: Production License Renewal

```bash
# Perform during maintenance window (renewals are non-disruptive)

# Site 1:
ssh admin@10.10.1.11
wabadmin license activate --key "SITE1-RENEWAL-XXXX-XXXX"

# Verify no session disruption
wabadmin session list --active
# Expected: All active sessions continue (no disconnections)

# Repeat for Sites 2-5
```

#### Step 5: Verify Renewal Across Sites

```bash
# Check all sites have updated licenses
for site in 1 2 3 4 5; do
  echo "=== Site $site ==="
  ssh admin@10.10.${site}.11 "wabadmin license-info | grep -E 'Sessions|Expiration|Status'"
done

# Expected output:
# === Site 1 ===
# Sessions Licensed: 500
# Expiration: 2028-02-05
# Status: Active
# [... same for Sites 2-5]
```

### Grace Period Behavior

If license expires **without renewal**:

| Days After Expiration | Behavior |
|-----------------------|----------|
| **0-7 days** | Warning banner, full functionality |
| **8-14 days** | Warning banner, daily email alerts |
| **15-21 days** | Warning banner, new sessions limited to 50% capacity |
| **22-28 days** | Warning banner, new sessions limited to 25% capacity |
| **29-30 days** | Warning banner, new sessions limited to 10% capacity |
| **31+ days** | **New sessions BLOCKED**, existing sessions continue until logout |

```bash
# Check grace period status
wabadmin license-info --grace

# Expected (during grace period):
# License Status: EXPIRED (Grace Period)
# Days Expired: 12
# Grace Period Remaining: 18 days
# Session Capacity: 225/450 (50% restriction active)
# Action Required: Renew license immediately
```

---

## Troubleshooting

### Issue 1: License Activation Fails

**Symptoms**: `wabadmin license activate` returns error

**Diagnosis**:

```bash
# Check license key format
wabadmin license validate-key --key "XXXX-XXXX-XXXX-XXXX"

# Check network connectivity (online activation)
curl -I https://bastion-license.wallix.com

# Check system date/time (incorrect time causes activation failures)
date
timedatectl status
```

**Resolution**:

```bash
# Fix system time if incorrect
timedatectl set-ntp true
systemctl restart chronyd

# Retry activation
wabadmin license activate --key "XXXX-XXXX-XXXX-XXXX" --method online

# If online fails, use offline method
wabadmin license generate-request --output /tmp/request.xml
# Submit to WALLIX support portal
```

### Issue 2: Session Denied - License Pool Exhausted

**Symptoms**: User receives "License quota exceeded" error

**Diagnosis**:

```bash
# Check current session usage
wabadmin license-info

# Expected:
# Sessions Active: 450/450 (100%)

# Identify top session consumers
wabadmin session list --active --sort-by user

# Expected:
# jdoe: 12 sessions
# asmith: 8 sessions
# ... (identify users hogging sessions)
```

**Resolution**:

```bash
# Option 1: Terminate idle sessions
wabadmin session list --active --idle-time ">30m"
wabadmin session terminate --idle-time ">30m" --force

# Option 2: Increase license pool (temporary - request renewal)
# Contact WALLIX for temporary license increase

# Option 3: Enable session queueing
wabadmin queue config --enabled true --max-wait-time 600
```

### Issue 3: License Server Integration Fails

**Symptoms**: Bastion cannot retrieve license from Access Manager

**Diagnosis**:

```bash
# Test connectivity to Access Manager
curl -k https://am.corp.local/api/license/health

# Expected: HTTP 200 OK

# Check API token validity
wabadmin license server-test --verbose

# Expected error:
# Error: 401 Unauthorized (API token expired or invalid)
```

**Resolution**:

```bash
# Contact Access Manager team for new API token

# Update Bastion configuration
wabadmin license server-config \
  --auth-token "NEW_TOKEN_HERE" \
  --url "https://am.corp.local/api/license"

# Restart license service
wabadmin license server-restart

# Verify
wabadmin license server-test
# Expected: Connection OK, license retrieved
```

### Issue 4: HA Cluster License Mismatch

**Symptoms**: Secondary Bastion node shows different license info than primary

**Diagnosis**:

```bash
# On primary node
ssh admin@10.10.1.11
wabadmin license-info

# On secondary node
ssh admin@10.10.1.12
wabadmin license-info

# Compare outputs - should be identical in HA cluster
```

**Resolution**:

```bash
# Re-sync cluster configuration
ssh admin@10.10.1.11
wabadmin cluster sync --force --target 10.10.1.12

# Verify license sync
ssh admin@10.10.1.12
wabadmin license-info

# Should now match primary node
```

### Issue 5: License Expiration Not Alerting

**Symptoms**: License expired but no alerts received

**Diagnosis**:

```bash
# Check alert configuration
wabadmin alert list --filter "license"

# Check alert delivery
wabadmin alert test --name "License Expiration Critical"

# Check email configuration
wabadmin smtp status
```

**Resolution**:

```bash
# Verify SMTP settings
wabadmin smtp config \
  --server "smtp.corp.local" \
  --port 587 \
  --from "wallix-alerts@corp.local" \
  --auth-user "smtp_user" \
  --auth-pass "smtp_password"

# Recreate alert
wabadmin alert delete --name "License Expiration Critical"
wabadmin alert create \
  --name "License Expiration Critical" \
  --condition "license_expiry_days <= 30" \
  --severity "critical" \
  --notification "email" \
  --recipients "pam-admins@corp.local"

# Test alert delivery
wabadmin alert test --name "License Expiration Critical"
```

---

## Best Practices

### License Management

1. **Monitor utilization trends** - Forecast 6 months ahead based on growth
2. **Set alerts at 80% capacity** - Proactive capacity planning
3. **Renew 60 days early** - Avoid grace period activation
4. **Document license allocation** - Maintain site-to-session mapping
5. **Audit session usage monthly** - Identify and reclaim orphaned sessions

### Session Optimization

```bash
# Terminate zombie sessions (users left without logout)
wabadmin session cleanup --idle-time ">4h" --force

# Enforce session timeout policies
wabadmin session-policy set \
  --max-idle-time 60 \
  --max-session-time 480 \
  --disconnect-on-idle true

# Review high session consumers quarterly
wabadmin reporting session-usage --period "last-90-days" --group-by user
```

### License Pool Strategies

**For 5-Site Deployment**:

| Strategy | When to Use |
|----------|-------------|
| **Equal Distribution (90/site)** | Similar load across all sites |
| **Weighted by Site (80-120)** | Some sites have higher demand |
| **Dynamic Pool (no limits)** | High variability, centralized license server |

**Recommended for Most Deployments**: **Dynamic Pool with 80% soft limit per site**

```bash
wabadmin quota set --site "site1" --soft-limit 80 --hard-limit 120
# Soft limit = warning, hard limit = block
```

---

## Next Steps

After completing license configuration:

1. **End-to-End Testing**: [10-testing-validation.md](10-testing-validation.md) - Validate licensing and session management
2. **Monitoring Setup**: [/docs/pam/12-monitoring-observability/](../docs/pam/12-monitoring-observability/) - Grafana dashboards for license metrics
3. **Operational Runbooks**: [/docs/pam/21-operational-runbooks/](../docs/pam/21-operational-runbooks/) - License renewal procedures

---

## References

### WALLIX Documentation
- Licensing Guide: https://pam.wallix.one/documentation/admin-doc/licensing
- License Activation: https://pam.wallix.one/documentation/admin-doc/license-activation
- License Server API: https://pam.wallix.one/documentation/api/license

### Internal Documentation
- Access Manager Integration: [03-access-manager-integration.md](03-access-manager-integration.md)
- HA Architecture: [02-ha-architecture.md](02-ha-architecture.md)
- Prerequisites: [00-prerequisites.md](00-prerequisites.md)

### Support
- WALLIX Support Portal: https://support.wallix.com
- License Renewal Request: https://support.wallix.com/license-renewal
- Emergency License Assistance: support@wallix.com (24/7)

---

*Proper license management ensures uninterrupted PAM service delivery and compliance with WALLIX commercial terms.*
