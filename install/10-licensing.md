# Licensing - WALLIX Bastion License Management

> License sizing, activation, and management for 5-site WALLIX Bastion deployment

---

## Document Information

| Property | Value |
|----------|-------|
| **Purpose** | License sizing and activation for our Bastion deployment (5 sites) |
| **Scope** | WALLIX Bastion licensing only — Access Manager licensing is client-managed |
| **Prerequisites** | [05-site-deployment.md](05-site-deployment.md) |
| **Version** | WALLIX Bastion 12.1.x |
| **Last Updated** | April 2026 |

---

> **IMPORTANT**: The WALLIX Access Manager (client-managed) has its own separate license.
> The AM license is the **client's responsibility** — we do not purchase, activate, or manage it.
> This document covers only the **WALLIX Bastion** license for our 5-site deployment.

---

## Table of Contents

1. [Licensing Overview](#licensing-overview)
2. [License Calculation](#license-calculation)
3. [FortiAuthenticator and FortiToken Licensing](#fortiauthenticator-and-fortitoken-licensing)
4. [License Activation Methods](#license-activation-methods)
5. [Session Quota Management](#session-quota-management)
6. [Monitoring and Alerting](#monitoring-and-alerting)
7. [License Renewal Procedures](#license-renewal-procedures)
8. [Troubleshooting](#troubleshooting)

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

### Licensing Scope Summary

```
+===============================================================================+
|  LICENSING SCOPE - WHO MANAGES WHAT                                           |
+===============================================================================+
|                                                                               |
|  CLIENT-MANAGED (not our scope):                                              |
|  +--------------------------------------------------+                        |
|  |  Access Manager License                          |                        |
|  |  - Purchased and managed by client team          |                        |
|  |  - Applied to client's AM HA pair (2 nodes)      |                        |
|  |  - Session count: determined by client           |                        |
|  |  - Renewal: client's procurement process         |                        |
|  +--------------------------------------------------+                        |
|                                                                               |
|  OUR SCOPE:                                                                   |
|  +--------------------------------------------------+                        |
|  |  WALLIX Bastion License                          |                        |
|  |  - 5 sites, 10 appliances, 5 HA pairs            |                        |
|  |  - Recommended: 150 concurrent sessions           |                        |
|  |  - 5 license units (1 per HA cluster)            |                        |
|  +--------------------------------------------------+                        |
|  +--------------------------------------------------+                        |
|  |  FortiAuthenticator License                      |                        |
|  |  - 5 HA pairs (Primary + Secondary per site)     |                        |
|  |  - FortiToken Mobile licenses (1 per user)       |                        |
|  |  - ~25 users per site = ~125 FortiToken licenses  |                        |
|  +--------------------------------------------------+                        |
|                                                                               |
|  KEY PRINCIPLE: HA cluster = 1 license (NOT 2)                                |
|                 10 appliances = 5 HA pairs = 5 licenses needed                |
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

#### Deployment Scale

| Metric | Value |
|--------|-------|
| **Privileged users per site** | ~25 |
| **Total privileged users** | ~125 (25 × 5 sites) |
| **Average sessions per user** | ~1 (most users run 1 session at a time) |
| **Worst-case simultaneous sessions** | ~125 (all users at all sites active at once) |
| **Recommended license pool** | **150 concurrent sessions** (20% headroom) |

#### Capacity Sizing Rationale

```
Users per site:          25
Sites:                    5
Max simultaneous:       125  (25 users × 5 sites, all active at once)
20% overhead buffer:    +25
Recommended pool:       150 concurrent sessions
```

This is a conservative estimate for privileged access management.
In practice, not all 125 users will have active sessions simultaneously.
A 150-session pool provides comfortable headroom for burst activity.

#### HA Licensing Rules

| Configuration | Appliances | License Units | Reasoning |
|---------------|------------|---------------|-----------|
| **Active-Active** | 2 | 1 | Cluster shares session pool |
| **Active-Passive** | 2 | 1 | Passive node does NOT consume license |
| **Standalone** | 1 | 1 | Single appliance, no HA |

**Important**: WALLIX licenses the **cluster**, not individual appliances. An HA pair (Active-Active or Active-Passive) counts as **1 license unit**.

---

## FortiAuthenticator and FortiToken Licensing

### FortiAuthenticator Licensing

Each site has an independent FortiAuthenticator HA pair (Primary + Secondary) in the Cyber VLAN. Licensing applies to each FortiAuthenticator node independently.

| Item | Quantity | Notes |
|------|----------|-------|
| **FortiAuthenticator nodes** | 10 (2 per site) | Each node requires a license |
| **License type** | FortiAuthenticator hardware/VM license | Per-node, based on max users |
| **User scale** | ~25 users per site | Small-tier license sufficient |
| **Managed by** | Our team | We purchase and activate |

FortiAuthenticator sizing recommendation for ~25 users per site: the base FortiAuthenticator license supports up to 100 local users on hardware appliances. Confirm actual SKU with Fortinet sales based on appliance model.

### FortiToken Mobile Licensing

FortiToken Mobile (TOTP soft token) requires one license per enrolled user.

| Item | Quantity | Notes |
|------|----------|-------|
| **Users per site** | ~25 | Each user gets 1 FortiToken Mobile |
| **Total users** | ~125 | Across all 5 sites |
| **Recommended purchase** | **150 FortiToken Mobile licenses** | Headroom for onboarding |
| **License type** | FortiToken Mobile (FTM-ELIC) | Perpetual or subscription |
| **Pooling** | Per-site FortiAuth manages local tokens | No central pool |

FortiToken Mobile licenses are activated on the per-site FortiAuthenticator. Each site's FortiAuth manages its own token pool.

```bash
# Verify FortiToken license count on FortiAuthenticator
# FortiAuthenticator CLI:
get license fortitoken

# Expected output:
# FortiToken Mobile Licenses: 30 (used: 22, available: 8)
```

### Access Manager Licensing (Client-Managed)

The client team is responsible for:
- Purchasing AM licenses from WALLIX
- Activating licenses on their AM HA pair
- Sizing the AM license pool for their user base
- Renewing AM licenses

We do not have access to the AM administration interface. If the client reports AM license issues (e.g., "session brokering not working"), direct them to WALLIX support.

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

| Site | Appliance | License Key | Activation Method | Sessions |
|------|-----------|-------------|-------------------|----------|
| **Site 1** | 10.10.1.11 (primary) | SITE1-XXXX-XXXX | Online / Offline | 30 (or dynamic pool) |
| **Site 2** | 10.10.2.11 (primary) | SITE2-XXXX-XXXX | Online / Offline | 30 (or dynamic pool) |
| **Site 3** | 10.10.3.11 (primary) | SITE3-XXXX-XXXX | Online / Offline | 30 (or dynamic pool) |
| **Site 4** | 10.10.4.11 (primary) | SITE4-XXXX-XXXX | Online / Offline | 30 (or dynamic pool) |
| **Site 5** | 10.10.5.11 (primary) | SITE5-XXXX-XXXX | Online / Offline | 30 (or dynamic pool) |

**Total licensed sessions: 150** (30 per site × 5 sites, or one unified pool of 150)

**Note**: Only the **primary appliance** in each HA cluster needs license activation. The secondary node inherits the license via cluster sync.

---

## Session Quota Management

### Setting Per-Site Quotas

```bash
# On primary Bastion appliance
wabadmin quota set \
  --site "site1" \
  --max-sessions 30 \
  --warning-threshold 80 \
  --action-on-exceed "block"  # Options: block, warn, queue

# Verify quota
wabadmin quota show --site "site1"

# Expected:
# Site: Site 1 (DC-1)
# Max Sessions: 30
# Current Usage: 18/30 (60%)
# Status: OK
```

### Dynamic Quota Adjustment

```bash
# Increase Site 1 quota (e.g., during peak usage)
wabadmin quota modify --site "site1" --max-sessions 40

# Decrease Site 4 quota (redistribute to Site 1)
wabadmin quota modify --site "site4" --max-sessions 20

# Verify total still within pool limit
wabadmin quota summary

# Expected:
# Pool Total: 150 sessions
# Allocated:
#   Site 1: 40
#   Site 2: 30
#   Site 3: 30
#   Site 4: 20
#   Site 5: 30
# Unallocated: 0 (150 allocated)
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
| **Total Pool** | 150 | N/A | Active |
| **Used Sessions** | 87 | 135 (90%) | OK |
| **Available Sessions** | 63 | N/A | OK |
| **Peak Today** | 112 | N/A | 75% |
| **License Expiration** | 2027-02-05 | 30 days warning | 365 days |

#### CLI Monitoring

```bash
# Check license status
wabadmin license-info

# Expected:
# License Type: Commercial
# Sessions Licensed: 150
# Sessions Active: 87
# Sessions Available: 63
# Utilization: 58%
# Expiration: 2027-02-05 (365 days remaining)
# Status: OK

# Get per-site breakdown
wabadmin license-info --breakdown

# Expected:
# Site 1: 22/30 (73%)
# Site 2: 18/30 (60%)
# Site 3: 15/30 (50%)
# Site 4: 17/30 (57%)
# Site 5: 15/30 (50%)
# Total: 87/150 (58%)
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
# wallix_license_total{pool="Bastion-Production"} 150
# wallix_license_used{site="site1"} 22
# wallix_license_used{site="site2"} 18
# wallix_license_available 63
# wallix_license_utilization_percent 58
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
  --current-sessions 150 \
  --requested-sessions 175 \
  --justification "Planned user growth in 2027" \
  --output /tmp/license-renewal-request.pdf

# Send to WALLIX sales representative
```

#### Step 2: Receive Renewal License Keys

WALLIX provides:
- New license keys (5 keys for 5 HA clusters OR 1 unified pool key)
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
# Sessions: 175 (increased from 150)
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
# Sessions Licensed: 30
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
# Session Capacity: 75/150 (50% restriction active)
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
# Sessions Active: 150/150 (100%)

# Identify top session consumers
wabadmin session list --active --sort-by user

# Expected:
# jdoe: 5 sessions
# asmith: 4 sessions
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

### Issue 3: HA Cluster License Mismatch

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

### Issue 4: License Expiration Not Alerting

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

**For 5-Site Deployment (~25 users per site)**:

| Strategy | When to Use |
|----------|-------------|
| **Equal Distribution (30/site)** | Similar load across all sites (default) |
| **Weighted by Site (20-40)** | Some sites have higher privileged access demand |
| **Dynamic Pool (no per-site limits)** | High variability, centralized management |

**Recommended for Most Deployments**: **Equal distribution with 80% soft limit per site**

```bash
wabadmin quota set --site "site1" --soft-limit 24 --hard-limit 30
# Soft limit = warning at 80% (24/30), hard limit = block at 100%
```

---

## Next Steps

After completing license configuration:

1. **End-to-End Testing**: [11-testing-validation.md](11-testing-validation.md) - Validate licensing and session management
2. **Monitoring Setup**: [/docs/pam/12-monitoring-observability/](../docs/pam/12-monitoring-observability/) - Grafana dashboards for license metrics
3. **Operational Runbooks**: [/docs/pam/21-operational-runbooks/](../docs/pam/21-operational-runbooks/) - License renewal procedures

---

## References

### WALLIX Documentation
- Licensing Guide: https://pam.wallix.one/documentation/admin-doc/licensing
- License Activation: https://pam.wallix.one/documentation/admin-doc/license-activation
- License Server API: https://pam.wallix.one/documentation/api/license

### Internal Documentation
- Bastion-side AM Integration: [15-access-manager-integration.md](15-access-manager-integration.md)
- FortiAuthenticator HA: [03-fortiauthenticator-ha.md](03-fortiauthenticator-ha.md)
- HA Architecture: [02-ha-architecture.md](02-ha-architecture.md)
- Prerequisites: [00-prerequisites.md](00-prerequisites.md)

### Support
- WALLIX Support Portal: https://support.wallix.com
- License Renewal Request: https://support.wallix.com/license-renewal
- Emergency License Assistance: support@wallix.com (24/7)

---

*Proper license management ensures uninterrupted PAM service delivery and compliance with WALLIX commercial terms.*
