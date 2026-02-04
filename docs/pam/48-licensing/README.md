# 48 - WALLIX Licensing Guide

## Table of Contents

1. [Licensing Overview](#licensing-overview)
2. [License Types](#license-types)
3. [HA Deployment Licensing](#ha-deployment-licensing)
4. [Multi-Site Licensing Scenario](#multi-site-licensing-scenario)
5. [License Calculation](#license-calculation)
6. [License Activation](#license-activation)
7. [License Management](#license-management)
8. [License Monitoring](#license-monitoring)
9. [Troubleshooting](#troubleshooting)
10. [Renewals and Upgrades](#renewals-and-upgrades)

---

## Licensing Overview

### WALLIX Licensing Model

WALLIX products use a **concurrent session-based** licensing model with perpetual or subscription options.

```
+===============================================================================+
|                        WALLIX LICENSING MODEL                                 |
+===============================================================================+
|                                                                               |
|  License Metrics:                                                             |
|  ================                                                             |
|                                                                               |
|  +-------------------------+    +-------------------------+                   |
|  |  Concurrent Sessions    |    |  Named Users (Optional) |                   |
|  +-------------------------+    +-------------------------+                   |
|  | Max simultaneous        |    | Maximum user accounts   |                   |
|  | connections to targets  |    | in the system           |                   |
|  | Example: 100 sessions   |    | Example: 500 users      |                   |
|  +-------------------------+    +-------------------------+                   |
|                                                                               |
|  License Types:                                                               |
|  ==============                                                               |
|                                                                               |
|  Perpetual License                    Subscription License                    |
|  ------------------                   ---------------------                   |
|  • One-time purchase                  • Annual/multi-year                     |
|  • Lifetime usage rights              • Lower upfront cost                    |
|  • Annual support/maintenance         • Includes support                      |
|  • Can upgrade sessions               • Flexible scaling                      |
|                                                                               |
|  Components Licensed:                                                         |
|  ====================                                                         |
|                                                                               |
|  ✓ WALLIX Bastion (sessions)                                                  |
|  ✓ WALLIX Access Manager (sessions)                                           |
|  ✓ Support & Maintenance                                                      |
|  ✓ Software updates                                                           |
|                                                                               |
+===============================================================================+
```

### Key Licensing Principles

1. **Session-Based Counting**
   - License counts **concurrent active sessions**
   - Not based on number of servers/nodes
   - HA nodes share the same license pool

2. **Cluster Licensing**
   - HA cluster = **ONE license** for all nodes
   - Active-Active cluster shares session count
   - Failover does not require additional licenses

3. **Multi-Site Licensing**
   - Each site can have separate license
   - OR single enterprise license for all sites
   - Centralized license management available

---

## License Types

### WALLIX Bastion Licenses

| License Type | Description | Session Count | Best For |
|--------------|-------------|---------------|----------|
| **Small** | Entry-level deployment | 10-50 sessions | Small teams, pilot projects |
| **Medium** | Standard deployment | 100-250 sessions | Medium organizations |
| **Large** | Enterprise deployment | 500-1000 sessions | Large enterprises |
| **Enterprise** | Unlimited sessions | 1000+ sessions | Global deployments |
| **Custom** | Tailored to needs | Custom count | Specific requirements |

### WALLIX Access Manager Licenses

| License Type | Description | Session Count | Best For |
|--------------|-------------|---------------|----------|
| **Starter** | Small deployment | 25-100 sessions | Department access |
| **Professional** | Standard deployment | 250-500 sessions | Company-wide access |
| **Enterprise** | Large deployment | 1000+ sessions | Global access |

### Support and Maintenance

| Tier | Description | Response Time | Included |
|------|-------------|---------------|----------|
| **Standard** | Business hours support | 8 hours | Software updates, patches |
| **Premium** | 24/7 support | 4 hours | Standard + priority support |
| **Enterprise** | Dedicated support | 1 hour | Premium + TAM, custom SLA |

---

## HA Deployment Licensing

### How HA Licensing Works

```
+===============================================================================+
|                    HA CLUSTER LICENSING MODEL                                 |
+===============================================================================+
|                                                                               |
|  Single Site HA Cluster (Active-Active):                                     |
|                                                                               |
|  +------------------+         +------------------+                            |
|  | Bastion Node 1   |         | Bastion Node 2   |                            |
|  | (Active)         |<------->| (Active)         |                            |
|  +------------------+         +------------------+                            |
|           |                            |                                      |
|           +------------+---------------+                                      |
|                        |                                                      |
|                        v                                                      |
|              +-------------------+                                            |
|              | SHARED LICENSE    |                                            |
|              | 500 Sessions      |                                            |
|              +-------------------+                                            |
|                                                                               |
|  Key Points:                                                                  |
|  -----------                                                                  |
|  • Both nodes share the same 500-session license                              |
|  • Session count is cluster-wide, not per-node                                |
|  • If Node 1 has 200 active sessions, Node 2 can use 300                      |
|  • Total cluster capacity: 500 concurrent sessions                            |
|  • License applied once (not duplicated for HA)                               |
|                                                                               |
+===============================================================================+
```

### HA Licensing Rules

1. **Cluster = One License**
   - Apply license to **primary node only**
   - Secondary nodes inherit license automatically
   - No additional cost for HA redundancy

2. **Session Pooling**
   - All nodes in cluster share session pool
   - Sessions distributed across active nodes
   - Total cannot exceed license limit

3. **Failover Behavior**
   - License remains valid during failover
   - No interruption to licensed sessions
   - Automatic license synchronization

---

## Multi-Site Licensing Scenario

### Your Deployment: 4 Sites with HA

**Architecture:**
- **4 Sites** (Site A, Site B, Site C, Site D)
- **8 WALLIX Bastion nodes** (2 per site in HA)
- **2 WALLIX Access Manager instances**

```
+===============================================================================+
|           4-SITE HA DEPLOYMENT LICENSING ARCHITECTURE                         |
+===============================================================================+
|                                                                               |
|  Site A (Primary)          Site B (Secondary)                                 |
|  +-----------------+       +-----------------+                                |
|  | Bastion 1 + 2   |       | Bastion 3 + 4   |                                |
|  | (HA Pair)       |       | (HA Pair)       |                                |
|  | License: 500    |       | License: 500    |                                |
|  +-----------------+       +-----------------+                                |
|                                                                               |
|  Site C (Tertiary)         Site D (Quaternary)                                |
|  +-----------------+       +-----------------+                                |
|  | Bastion 5 + 6   |       | Bastion 7 + 8   |                                |
|  | (HA Pair)       |       | (HA Pair)       |                                |
|  | License: 500    |       | License: 500    |                                |
|  +-----------------+       +-----------------+                                |
|                                                                               |
|  Access Manager Layer:                                                        |
|  +-----------------------------------+-----------------------------------+     |
|  | Access Manager 1 (Active)         | Access Manager 2 (Standby)        |     |
|  | License: 250 sessions             | Shares AM1 License                |     |
|  +-----------------------------------+-----------------------------------+     |
|                                                                               |
+===============================================================================+
```

### Licensing Options for This Deployment

#### Option 1: Individual Site Licenses (Isolated)

```
Component                        | Quantity | Sessions Each | Total Sessions
---------------------------------|----------|---------------|---------------
WALLIX Bastion - Site A (HA)     | 1 license| 500          | 500
WALLIX Bastion - Site B (HA)     | 1 license| 500          | 500
WALLIX Bastion - Site C (HA)     | 1 license| 500          | 500
WALLIX Bastion - Site D (HA)     | 1 license| 500          | 500
WALLIX Access Manager (HA)       | 1 license| 250          | 250
---------------------------------|----------|---------------|---------------
TOTAL LICENSES                   | 5        |              | 2,250 sessions
```

**Characteristics:**
- Each site operates independently
- License failure at one site doesn't affect others
- Cannot share session capacity between sites
- Best for: Isolated regional deployments

**Pricing Estimate:**
- Bastion: 4 × 500-session licenses
- Access Manager: 1 × 250-session license
- Support: Per license tier selected

#### Option 2: Enterprise License (Shared Pool)

```
Component                        | Quantity | Sessions     | Notes
---------------------------------|----------|--------------|------------------
WALLIX Bastion Enterprise        | 1 license| 2000 sessions| Shared across all 4 sites
WALLIX Access Manager Enterprise | 1 license| 250 sessions | Shared across AM instances
---------------------------------|----------|--------------|------------------
TOTAL LICENSES                   | 2        | 2,250 total  | Centralized management
```

**Characteristics:**
- Single enterprise license pool
- Sessions shared dynamically across all sites
- Centralized license management
- Lower total cost
- Best for: Synchronized multi-site deployment

**Pricing Estimate:**
- Bastion: 1 × 2000-session enterprise license
- Access Manager: 1 × 250-session license
- Support: Enterprise tier (24/7, TAM)

#### Option 3: Hybrid Licensing (Recommended)

```
Component                        | Quantity | Sessions Each | Total Sessions
---------------------------------|----------|---------------|---------------
Primary Sites (A+B) - Enterprise | 1 license| 1200         | 1200 (shared)
DR Sites (C+D) - Standard        | 2 licenses| 400 each    | 800
WALLIX Access Manager            | 1 license| 250          | 250
---------------------------------|----------|---------------|---------------
TOTAL LICENSES                   | 4        |              | 2,250 sessions
```

**Characteristics:**
- Production sites share enterprise license
- DR sites have separate smaller licenses
- Cost-effective for DR scenarios
- Best for: Primary + DR deployment model

---

## License Calculation

### Determining Required Session Count

#### Step 1: Calculate Peak Concurrent Sessions

```bash
# Formula:
Required_Sessions = (Total_Admins × Concurrency_Rate × Peak_Factor) + Safety_Margin

# Example Calculation:
Total_Admins = 200 (system administrators)
Concurrency_Rate = 0.20 (20% working simultaneously)
Peak_Factor = 1.5 (50% increase during incidents)
Safety_Margin = 1.2 (20% buffer)

Required_Sessions = (200 × 0.20 × 1.5) × 1.2
Required_Sessions = 60 × 1.2
Required_Sessions = 72 sessions

# Recommended License: 100-session tier
```

#### Step 2: Session Estimation by Team

| Team | Users | Avg Concurrent % | Sessions Needed |
|------|-------|------------------|-----------------|
| **Linux Admins** | 50 | 25% | 13 |
| **Windows Admins** | 40 | 30% | 12 |
| **Database Admins** | 30 | 20% | 6 |
| **Network Admins** | 20 | 15% | 3 |
| **Security Team** | 15 | 40% | 6 |
| **DevOps Team** | 45 | 35% | 16 |
| **Contractors** | 25 | 10% | 3 |
| **Total** | **225** | - | **59** |
| **With 30% buffer** | - | - | **77** |
| **Recommended License** | - | - | **100 sessions** |

#### Step 3: Multi-Site Session Distribution

For 4-site deployment with 2000 total sessions:

| Site | Purpose | Allocated Sessions | % of Total |
|------|---------|-------------------|------------|
| **Site A** | Primary production | 800 | 40% |
| **Site B** | Secondary production | 600 | 30% |
| **Site C** | DR / Dev-Test | 400 | 20% |
| **Site D** | DR / Staging | 200 | 10% |
| **Total** | - | **2000** | **100%** |

### Access Manager Session Calculation

```bash
# Access Manager sessions = Web application users

Total_App_Users = 500
Concurrent_Rate = 0.15 (15% accessing apps simultaneously)
Peak_Factor = 1.3 (30% increase during business hours)

Required_AM_Sessions = (500 × 0.15) × 1.3
Required_AM_Sessions = 75 × 1.3
Required_AM_Sessions = 98 sessions

# Recommended License: 100-session tier
```

---

## License Activation

### Pre-Activation Checklist

- [ ] Purchase Order (PO) completed
- [ ] License keys received from WALLIX
- [ ] System IDs collected from all nodes
- [ ] Network connectivity verified (for online activation)
- [ ] Backup of existing configuration
- [ ] Maintenance window scheduled

### Method 1: Online Activation (Recommended)

#### For WALLIX Bastion

```bash
# On primary node of each HA cluster
ssh admin@bastion-site-a-node1.company.com

# Step 1: Check current license status
wabadmin license-info

# Expected output (before activation):
# License Status: Not Licensed
# Trial Days Remaining: 30
# Sessions Allowed: 10 (trial)

# Step 2: Activate license (online)
wabadmin license-activate \
  --key XXXX-XXXX-XXXX-XXXX-XXXX \
  --email admin@company.com

# Step 3: Verify activation
wabadmin license-info

# Expected output (after activation):
# License Status: Active
# License Type: Enterprise
# Sessions Licensed: 500
# Expiration Date: 2027-12-31
# Support Level: Premium
# Licensed To: Company Name
```

#### For WALLIX Access Manager

```bash
# On Access Manager primary instance
ssh admin@access-manager-1.company.com

# Activate license
sudo wallix-am license activate \
  --key YYYY-YYYY-YYYY-YYYY-YYYY \
  --email admin@company.com

# Verify
sudo wallix-am license show
```

### Method 2: Offline Activation

#### Step 1: Generate Activation Request

```bash
# On WALLIX Bastion (offline environment)
wabadmin license-request-offline \
  --output /tmp/license-request.xml

# Copy request file to machine with internet access
scp /tmp/license-request.xml user@jump-host:/tmp/
```

#### Step 2: Submit to WALLIX Licensing Portal

1. Navigate to: https://licensing.wallix.com
2. Login with WALLIX account credentials
3. Navigate to: **Licenses** → **Activate Offline**
4. Upload `license-request.xml`
5. Download `license-response.xml`

#### Step 3: Apply License Response

```bash
# Copy response back to Bastion
scp user@jump-host:/tmp/license-response.xml /tmp/

# Apply license
wabadmin license-activate-offline \
  --input /tmp/license-response.xml

# Verify
wabadmin license-info
```

### Method 3: HA Cluster License Synchronization

```bash
# License only needs to be activated on PRIMARY node
# Secondary nodes will sync automatically

# On Primary Node:
wabadmin license-activate --key XXXX-XXXX-XXXX-XXXX-XXXX

# Verify sync on Secondary Node:
ssh admin@bastion-site-a-node2.company.com
wabadmin license-info

# Expected: Same license info as primary
```

---

## License Management

### Managing Multi-Site Licenses

#### Centralized License Dashboard

Web UI: `https://bastion-site-a.company.com/admin/licensing`

```
+===============================================================================+
|                  MULTI-SITE LICENSE DASHBOARD                                 |
+===============================================================================+

License Overview:
┌─────────────────────────────────────────────────────────────────────────────┐
│ Component          │ License Type │ Sessions │ Used │ Available │ Expires   │
├────────────────────┼──────────────┼──────────┼──────┼───────────┼───────────┤
│ Bastion - Site A   │ Enterprise   │ 500      │ 234  │ 266       │ 2027-12-31│
│ Bastion - Site B   │ Enterprise   │ 500      │ 187  │ 313       │ 2027-12-31│
│ Bastion - Site C   │ Standard     │ 400      │ 56   │ 344       │ 2027-12-31│
│ Bastion - Site D   │ Standard     │ 400      │ 23   │ 377       │ 2027-12-31│
│ Access Manager     │ Professional │ 250      │ 89   │ 161       │ 2027-12-31│
├────────────────────┼──────────────┼──────────┼──────┼───────────┼───────────┤
│ TOTAL              │ -            │ 2050     │ 589  │ 1461      │ -         │
└─────────────────────────────────────────────────────────────────────────────┘

Alerts:
  ⚠ Site A approaching 50% capacity (234/500 sessions)
  ✓ All licenses valid until 2027-12-31
  ✓ Support active - Premium tier
```

#### License Management Commands

```bash
# View all licenses across cluster
wabadmin license-info --all-nodes

# Export license information
wabadmin license-export --format json > /tmp/licenses.json

# Check license compliance
wabadmin license-check --verbose

# Update license (upgrade sessions)
wabadmin license-update --key NEW-LICENSE-KEY

# Deactivate license (before hardware change)
wabadmin license-deactivate --reason "Hardware upgrade"
```

### License Transfer Between Nodes

```bash
# Scenario: Replacing hardware for Site A Node 1

# Step 1: Deactivate on old node
ssh admin@bastion-site-a-node1-old.company.com
wabadmin license-deactivate --export /tmp/license-transfer.xml

# Step 2: Activate on new node
ssh admin@bastion-site-a-node1-new.company.com
wabadmin license-activate-transfer --input /tmp/license-transfer.xml

# Step 3: Verify
wabadmin license-info
```

---

## License Monitoring

### Automated License Monitoring Script

```bash
#!/bin/bash
# /opt/scripts/monitor-wallix-licenses.sh
# Monitor WALLIX licenses and send alerts

ALERT_EMAIL="licensing@company.com"
WARNING_THRESHOLD=80  # Alert at 80% usage
CRITICAL_THRESHOLD=95 # Critical at 95% usage

# Sites to monitor
SITES=(
    "bastion-site-a.company.com"
    "bastion-site-b.company.com"
    "bastion-site-c.company.com"
    "bastion-site-d.company.com"
)

echo "=== WALLIX License Monitoring ===" | tee -a /var/log/license-monitor.log
echo "Date: $(date)" | tee -a /var/log/license-monitor.log
echo "" | tee -a /var/log/license-monitor.log

for site in "${SITES[@]}"; do
    echo "Checking: $site" | tee -a /var/log/license-monitor.log

    # Get license info via SSH
    LICENSE_INFO=$(ssh admin@$site "wabadmin license-info --format json")

    LICENSED=$(echo "$LICENSE_INFO" | jq -r '.sessions_licensed')
    USED=$(echo "$LICENSE_INFO" | jq -r '.sessions_used')
    EXPIRY=$(echo "$LICENSE_INFO" | jq -r '.expiration_date')

    # Calculate usage percentage
    USAGE_PCT=$((USED * 100 / LICENSED))

    echo "  Licensed: $LICENSED | Used: $USED | Usage: ${USAGE_PCT}%" | tee -a /var/log/license-monitor.log

    # Check thresholds
    if [ $USAGE_PCT -ge $CRITICAL_THRESHOLD ]; then
        echo "  🔴 CRITICAL: License usage above ${CRITICAL_THRESHOLD}%" | tee -a /var/log/license-monitor.log
        mail -s "CRITICAL: WALLIX License Usage - $site" $ALERT_EMAIL <<EOF
CRITICAL LICENSE ALERT

Site: $site
Licensed Sessions: $LICENSED
Used Sessions: $USED
Usage: ${USAGE_PCT}%

Action Required: Immediate license upgrade or session management needed.

EOF
    elif [ $USAGE_PCT -ge $WARNING_THRESHOLD ]; then
        echo "  ⚠️  WARNING: License usage above ${WARNING_THRESHOLD}%" | tee -a /var/log/license-monitor.log
        mail -s "WARNING: WALLIX License Usage - $site" $ALERT_EMAIL <<EOF
LICENSE WARNING

Site: $site
Licensed Sessions: $LICENSED
Used Sessions: $USED
Usage: ${USAGE_PCT}%

Action Recommended: Review license capacity planning.

EOF
    fi

    # Check expiration (warn if < 90 days)
    DAYS_TO_EXPIRY=$(( ($(date -d "$EXPIRY" +%s) - $(date +%s)) / 86400 ))

    if [ $DAYS_TO_EXPIRY -lt 90 ] && [ $DAYS_TO_EXPIRY -gt 0 ]; then
        echo "  ⚠️  License expires in $DAYS_TO_EXPIRY days" | tee -a /var/log/license-monitor.log
        mail -s "WALLIX License Expiring Soon - $site" $ALERT_EMAIL <<EOF
LICENSE EXPIRATION WARNING

Site: $site
Expiration Date: $EXPIRY
Days Remaining: $DAYS_TO_EXPIRY

Action Required: Renew license before expiration.

EOF
    fi

    echo "" | tee -a /var/log/license-monitor.log
done

echo "=== Monitoring Complete ===" | tee -a /var/log/license-monitor.log
```

**Cron Configuration:**

```bash
# Run license monitoring every 6 hours
0 */6 * * * /opt/scripts/monitor-wallix-licenses.sh
```

### Prometheus Metrics for Licensing

```yaml
# prometheus.yml - WALLIX license metrics

scrape_configs:
  - job_name: 'wallix-licenses'
    static_configs:
      - targets:
          - 'bastion-site-a.company.com:9100'
          - 'bastion-site-b.company.com:9100'
          - 'bastion-site-c.company.com:9100'
          - 'bastion-site-d.company.com:9100'
    metrics_path: '/metrics'

# Key metrics:
# - wallix_license_sessions_total
# - wallix_license_sessions_used
# - wallix_license_sessions_available
# - wallix_license_days_to_expiry
# - wallix_license_status (0=invalid, 1=valid, 2=trial)
```

---

## Troubleshooting

### Common Licensing Issues

#### Issue 1: License Activation Fails

**Symptoms:**
- Activation command returns error
- License status shows "Invalid"

**Diagnosis:**
```bash
# Check license key format
wabadmin license-validate --key XXXX-XXXX-XXXX-XXXX-XXXX

# Check internet connectivity (for online activation)
ping licensing.wallix.com

# Check system time (must be accurate)
date
timedatectl status

# View detailed error logs
journalctl -u wallix-bastion -n 100 | grep -i license
```

**Resolution:**
```bash
# Ensure correct license key (no typos)
# Verify system time is synchronized
sudo timedatectl set-ntp true

# Try offline activation if online fails
wabadmin license-request-offline --output /tmp/request.xml
```

#### Issue 2: Session Limit Exceeded

**Symptoms:**
- Users cannot connect
- Error: "License session limit reached"

**Diagnosis:**
```bash
# Check current session usage
wabadmin sessions --active --count

# View sessions by user
wabadmin sessions --active --group-by user

# Check license capacity
wabadmin license-info
```

**Resolution:**
```bash
# Option 1: Terminate idle sessions
wabadmin session kill --idle-minutes 60

# Option 2: Upgrade license
wabadmin license-update --key UPGRADED-LICENSE-KEY

# Option 3: Implement session limits per user
wabadmin user update --max-sessions 3
```

#### Issue 3: License Not Syncing in HA Cluster

**Symptoms:**
- Primary node shows license active
- Secondary node shows no license

**Diagnosis:**
```bash
# Check cluster replication
wabadmin ha-status

# Check database replication
wabadmin db-replication-status

# Verify license on both nodes
# Primary:
ssh admin@bastion-node1 "wabadmin license-info"
# Secondary:
ssh admin@bastion-node2 "wabadmin license-info"
```

**Resolution:**
```bash
# Force license sync
wabadmin ha-sync --component license --force

# If sync fails, reactivate on primary
wabadmin license-activate --key XXXX-XXXX-XXXX-XXXX-XXXX --force

# Restart secondary node
ssh admin@bastion-node2 "sudo systemctl restart wallix-bastion"
```

#### Issue 4: License Expired

**Symptoms:**
- All connections blocked
- Error: "License has expired"

**Diagnosis:**
```bash
wabadmin license-info

# Output shows:
# License Status: Expired
# Expiration Date: 2026-01-15 (past date)
```

**Resolution:**
```bash
# Contact WALLIX for renewal
# Apply renewed license immediately
wabadmin license-activate --key RENEWED-LICENSE-KEY

# Verify
wabadmin license-info

# Restart services if needed
sudo systemctl restart wallix-bastion
```

---

## Renewals and Upgrades

### License Renewal Process

#### 90 Days Before Expiration

1. **Review Current Usage**
   ```bash
   # Generate usage report
   wabadmin license-usage-report \
     --period 365d \
     --format pdf \
     --output /tmp/license-usage-2026.pdf
   ```

2. **Contact WALLIX Sales**
   - Email: sales@wallix.com
   - Provide: Current license key, usage statistics
   - Request: Renewal quote

3. **Plan for Growth**
   - Analyze peak session usage
   - Account for business growth
   - Consider session upgrades

#### 30 Days Before Expiration

4. **Receive Renewal Quote**
   - Review pricing
   - Approve purchase order
   - Coordinate with procurement

5. **Schedule Renewal**
   - Plan maintenance window (if needed)
   - Notify users of potential brief interruption
   - Prepare rollback plan

#### Renewal Day

6. **Apply Renewed License**
   ```bash
   # Backup current configuration
   wabadmin backup create --include-license

   # Activate renewed license
   wabadmin license-activate --key RENEWED-LICENSE-KEY

   # Verify new expiration date
   wabadmin license-info
   ```

### License Upgrade Process

**Scenario: Upgrading from 500 to 1000 sessions**

```bash
# Step 1: Request upgrade from WALLIX
# Receive upgraded license key

# Step 2: Apply upgrade (no downtime required)
wabadmin license-update --key UPGRADED-LICENSE-KEY

# Step 3: Verify increased capacity
wabadmin license-info

# Expected Output:
# Sessions Licensed: 1000 (was 500)
# Sessions Used: 234
# Sessions Available: 766

# Step 4: Update monitoring thresholds
# Edit monitoring script to reflect new capacity
```

### Best Practices for License Management

1. **Monitor Proactively**
   - Set up automated monitoring
   - Alert at 80% capacity
   - Review usage monthly

2. **Plan for Growth**
   - Track usage trends
   - Plan upgrades before hitting limits
   - Build 20-30% buffer capacity

3. **Document Everything**
   - Keep license keys secure (password manager)
   - Document activation dates
   - Track renewal dates in calendar

4. **Test Renewals**
   - Test renewal process in dev environment
   - Verify HA sync after renewal
   - Have rollback plan ready

5. **Centralize Management**
   - Use enterprise license for multi-site
   - Implement license tracking dashboard
   - Automate compliance reporting

---

## See Also

**Related Sections:**
- [00 - Official Resources](../00-official-resources/README.md) - WALLIX support and licensing contacts
- [11 - High Availability](../11-high-availability/README.md) - HA cluster licensing implications
- [19 - System Requirements](../19-system-requirements/README.md) - Capacity planning for licensing
- [47 - Access Manager](../47-access-manager/README.md) - Access Manager licensing

**Related Documentation:**
- [Install Guide](/install/README.md) - Initial license activation during installation

**Official Resources:**
- [WALLIX Licensing Portal](https://licensing.wallix.com)
- [WALLIX Support Portal](https://support.wallix.com)
- [WALLIX Sales](mailto:sales@wallix.com)

---

## Quick Reference

### License Activation Commands

```bash
# Check license status
wabadmin license-info

# Activate license (online)
wabadmin license-activate --key XXXX-XXXX-XXXX-XXXX-XXXX

# Offline activation request
wabadmin license-request-offline --output request.xml

# Apply offline response
wabadmin license-activate-offline --input response.xml

# Update/upgrade license
wabadmin license-update --key NEW-KEY

# Export license info
wabadmin license-export --format json

# Deactivate (for transfer)
wabadmin license-deactivate --export transfer.xml
```

### License Monitoring Commands

```bash
# View current session usage
wabadmin sessions --active --count

# Check usage by user
wabadmin sessions --active --group-by user

# Generate usage report
wabadmin license-usage-report --period 30d

# Check license compliance
wabadmin license-check
```

### Emergency Contacts

| Issue | Contact | Response Time |
|-------|---------|---------------|
| **License Expired** | support@wallix.com | 1 hour (Enterprise) |
| **Cannot Activate** | support@wallix.com | 4 hours (Premium) |
| **Renewal Questions** | sales@wallix.com | 1 business day |
| **Billing Issues** | billing@wallix.com | 2 business days |

---

*Document Version: 1.0*
*Last Updated: February 2026*
*Applies to: WALLIX Bastion 12.x, Access Manager 5.x*
