# Contingency Plan - Disaster Recovery and Business Continuity

> Recovery procedures for planned and unplanned failure scenarios across the 5-site WALLIX PAM infrastructure

---

## Document Information

| Property | Value |
|----------|-------|
| **Purpose** | Disaster recovery and business continuity procedures for multi-site PAM deployment |
| **Scope** | All 5 Bastion sites, per-site FortiAuth HA, per-site AD, HAProxy, WALLIX RDS |
| **AM Scope** | AM is client-managed — coordinate with client team for AM failures |
| **Classification** | Confidential - Operations Team Only |
| **Review Frequency** | Quarterly, or after any major incident |
| **Version** | 2.0 |
| **Last Updated** | April 2026 |

---

## Table of Contents

1. [Overview](#overview)
2. [Recovery Objectives](#recovery-objectives)
3. [Backup Strategy](#backup-strategy)
4. [Failure Scenarios and Recovery](#failure-scenarios-and-recovery)
   - [HAProxy Failures](#haproxy-failures)
   - [Bastion Failures](#bastion-failures)
   - [WALLIX RDS Failure](#wallix-rds-failure)
   - [Access Manager Failures](#access-manager-failures)
   - [FortiAuthenticator Failure](#fortiauthenticator-failure)
   - [Network Failures](#network-failures)
   - [Database Corruption](#database-corruption)
   - [Certificate Issues](#certificate-issues)
   - [License Pool Exhaustion](#license-pool-exhaustion)
   - [Full Site Loss](#full-site-loss)
   - [Multi-Site Loss](#multi-site-loss)
5. [Planned Maintenance Procedures](#planned-maintenance-procedures)
6. [Communication and Escalation Matrix](#communication-and-escalation-matrix)
7. [Post-Incident Review Template](#post-incident-review-template)

---

## Overview

This document defines recovery procedures for every component in the 5-site WALLIX PAM infrastructure. Each scenario includes detection criteria, impact assessment, step-by-step recovery, and validation procedures.

```
+===============================================================================+
|  CONTINGENCY PLAN COVERAGE                                                    |
+===============================================================================+
|                                                                               |
|  Client-Managed (Not Our DR Scope):                                           |
|  +-------------------+  HA  +-------------------+                             |
|  | AM-1 (client DC-A)|<---->| AM-2 (client DC-B)|  Coordinate with client     |
|  +-------------------+      +-------------------+  team for AM failures        |
|                                                                               |
|  Per-Site (x5) — Our Scope:                                                   |
|  +---------------------------------------------------------------+            |
|  |  DMZ VLAN (10.10.X.0/25):                                     |            |
|  |  HAProxy HA  | Bastion Cluster  | WALLIX RDS                  |            |
|  |  (Keepalived)| (Active-Active   | (Single Instance)           |            |
|  |              |  or Actv-Passive)|                             |            |
|  +---------------------------------------------------------------+            |
|  +---------------------------------------------------------------+            |
|  |  Cyber VLAN (10.10.X.128/25):                                 |            |
|  |  FortiAuth-1 (Primary) | FortiAuth-2 (Secondary) | AD DC      |            |
|  |  10.10.X.50            | 10.10.X.51             | 10.10.X.60  |            |
|  +---------------------------------------------------------------+            |
|                                                                               |
+===============================================================================+
```

---

## Recovery Objectives

### RTO/RPO by Component

| Component | RTO (Recovery Time) | RPO (Recovery Point) | Impact if Down |
|-----------|--------------------|-----------------------|----------------|
| **HAProxy (single node)** | 0 s (automatic failover) | N/A (stateless) | None - VIP moves to partner |
| **HAProxy (pair)** | 30 min | N/A (stateless) | Site PAM access via LB unavailable |
| **Bastion (single node)** | 0-60 s (automatic failover) | 0 (replicated) | None - partner takes over |
| **Bastion (cluster)** | 2 h | 1 h (last backup) | Site PAM access unavailable |
| **WALLIX RDS** | 1 h | 24 h (last backup) | OT RemoteApp access unavailable |
| **FortiAuth (single node, per site)** | 0 s (RADIUS failover) | N/A | None — Bastion uses secondary |
| **FortiAuth (both nodes, per site)** | 30 min | N/A | MFA unavailable for that site |
| **Active Directory (per site)** | 30 min (restore) | 1 h | AD auth unavailable for that site |
| **Access Manager (single, client)** | 0 s (AM HA failover) | 0 | None — client AM HA handles it |
| **Access Manager (both, client)** | Coordinate with client | N/A | SSO unavailable, RADIUS still works |
| **MPLS (single site)** | Carrier-dependent | N/A | Site isolated from AM |
| **MariaDB** | 1 h | 15 min (binlog) | Session data at risk |
| **Full site** | 4 h (redirect to other sites) | 1 h | Site capacity reduced |

### Availability Targets

| Scope | Target | Achieved By |
|-------|--------|-------------|
| Single site | 99.9% (8.7 h/year downtime) | HA clustering, HAProxy failover |
| Multi-site service | 99.99% (52 min/year downtime) | 5-site redundancy, AM HA |
| Access Manager | 99.95% (4.4 h/year downtime) | Active-Passive HA |

---

## Backup Strategy

### Backup Schedule

| Component | What | Frequency | Retention | Location |
|-----------|------|-----------|-----------|----------|
| **Bastion configuration** | `/var/wab/etc/`, policies, authorizations | Daily | 30 days | Offsite storage |
| **Bastion database** | MariaDB full dump | Daily | 30 days | Offsite storage |
| **Bastion database** | MariaDB binlog (incremental) | Continuous | 7 days | Local + offsite |
| **Session recordings** | `/var/wab/recordings/` | Daily sync | 365 days | Offsite storage |
| **HAProxy configuration** | `/etc/haproxy/`, `/etc/keepalived/` | After changes | 30 days | Git repository |
| **WALLIX RDS** | Full system backup (Windows) | Weekly | 30 days | Offsite storage |
| **SSL certificates** | Private keys, certificates | After renewal | Until expiry +90 days | Secure vault |
| **Access Manager config** | AM configuration export | Daily | 30 days | Offsite storage |

### Backup Procedures

```bash
# Bastion full backup (run on primary node)
wabadmin backup create \
  --output /backup/bastion-site1-$(date +%Y%m%d-%H%M).tar.gz \
  --include config,database,credentials

# Verify backup integrity
wabadmin backup verify \
  --input /backup/bastion-site1-20260210-0200.tar.gz

# Copy to offsite storage
rsync -avz /backup/ backup-server.company.com:/backups/bastion-site1/

# MariaDB incremental backup (binlog)
mysqlbinlog --read-from-remote-server \
  --host=10.10.1.11 --user=repl_user \
  --raw --stop-never \
  --result-file=/backup/binlog/ \
  mysql-bin.000001
```

### Backup Validation

```bash
# Monthly restore test (use pre-production environment)
- [ ] Restore Bastion configuration backup to test appliance
- [ ] Verify all policies and authorizations are intact
- [ ] Restore MariaDB from full dump + binlogs
- [ ] Verify session recording playback
- [ ] Document restore time and validate RTO targets
```

---

## Failure Scenarios and Recovery

### HAProxy Failures

#### Scenario 1: Single HAProxy Node Failure

**Detection**:
- Keepalived detects peer down (VRRP timeout, default 3 seconds)
- VIP automatically moves to surviving node
- Monitoring alert: HAProxy node unreachable

**Impact**: None — automatic failover via Keepalived VRRP.

**Recovery** (restore redundancy):

```bash
# 1. Diagnose the failed node
ssh haproxy1-site1.company.com   # or haproxy2-site1.company.com
systemctl status haproxy
systemctl status keepalived
journalctl -u haproxy --since "1 hour ago"

# 2. If hardware/OS issue, rebuild or repair the server
# 3. If service issue, restart
systemctl restart haproxy
systemctl restart keepalived

# 4. Verify the node has rejoined as BACKUP
ip addr show eth0  # Should NOT have VIP if partner is MASTER
journalctl -u keepalived -f  # Look for "Entering BACKUP STATE"

# 5. Test failover to confirm redundancy is restored
# On current MASTER node:
systemctl stop keepalived
# Verify VIP moves to recovered node
ping 10.10.X.100
# Restore original MASTER
systemctl start keepalived
```

**Validation Checklist**:
- [ ] Both HAProxy nodes are running
- [ ] Keepalived shows MASTER/BACKUP roles correctly
- [ ] VIP responds on both HTTP (443) and TCP (22, 3389)
- [ ] HAProxy backend health checks show both Bastions healthy

---

#### Scenario 2: HAProxy Pair Failure (Full Site Load Balancer Loss)

**Detection**:
- VIP (10.10.X.100) unreachable
- All user connections to the site fail
- Access Manager health check marks the site as unhealthy

**Impact**: Site PAM access via load balancer is unavailable. Direct Bastion access still possible.

**Immediate Workaround** (bypass load balancer):

```bash
# Users can connect directly to Bastion nodes:
# Bastion-1: 10.10.X.11
# Bastion-2: 10.10.X.12

# Update DNS as emergency measure (if DNS TTL allows)
# bastion-siteX.company.com → 10.10.X.11 (direct to Bastion-1)

# Or notify Access Manager to route to direct Bastion IP
curl -X PATCH https://am.company.com/api/v1/bastions/bastion-siteX \
  -H "Authorization: Bearer AM_API_KEY" \
  -d '{"url": "https://10.10.X.11"}'
```

**Recovery**:

```bash
# 1. Diagnose both HAProxy nodes
# Check hardware, network, OS, services

# 2. Rebuild HAProxy pair if necessary
# Follow 06-haproxy-setup.md

# 3. Restore configuration from backup (Git repository)
git clone git@config-server.company.com:haproxy/siteX.git
cp haproxy.cfg /etc/haproxy/haproxy.cfg
cp keepalived.conf /etc/keepalived/keepalived.conf

# 4. Start services
systemctl start haproxy keepalived

# 5. Revert DNS or Access Manager URL changes
curl -X PATCH https://am.company.com/api/v1/bastions/bastion-siteX \
  -H "Authorization: Bearer AM_API_KEY" \
  -d '{"url": "https://bastion-siteX.company.com"}'
```

**Validation Checklist**:
- [ ] VIP (10.10.X.100) responds
- [ ] HAProxy forwards traffic to both Bastion nodes
- [ ] Keepalived VRRP failover works between the pair
- [ ] Access Manager health check shows site as healthy

---

### Bastion Failures

#### Scenario 3: Single Bastion Node Failure

**Detection**:
- HAProxy health check marks the node as DOWN
- Cluster partner detects peer failure (`bastion-replication --monitoring`)
- Active sessions on the failed node are interrupted

**Impact**: Active sessions on the failed node are lost. New sessions routed to surviving node automatically.

**Recovery**:

```bash
# 1. Check cluster status from surviving node
wabadmin ha status

# 2. Diagnose the failed node
# Check IPMI/iLO for hardware errors
# Check OS via console if network is down
# Check Bastion services:
wabadmin status
systemctl status wabcore
journalctl -u wabcore --since "1 hour ago"

# 3. If service issue, restart
systemctl restart wabcore

# 4. If hardware issue, replace appliance and restore from backup
wabadmin restore --input /backup/bastion-siteX-latest.tar.gz

# 5. Rejoin the cluster
wabadmin ha rejoin --partner 10.10.X.11  # or .12

# 6. Verify cluster health
wabadmin ha status
# Expected: Both nodes visible, correct primary/secondary roles
```

**Validation Checklist**:
- [ ] Both Bastion nodes visible in cluster status
- [ ] HAProxy shows both backends as UP
- [ ] New sessions can be created on both nodes
- [ ] Database replication is synchronized

---

#### Scenario 4: Bastion Cluster Failure (Full Site PAM Loss)

**Detection**:
- Both Bastion nodes unreachable
- HAProxy shows all backends as DOWN
- Access Manager marks site as unhealthy

**Impact**: Site PAM access is completely unavailable. Users must be redirected to another site.

**Immediate Workaround** (redirect users):

```bash
# 1. Access Manager automatically routes sessions to other healthy sites
#    (if failover routing rules are configured)

# 2. If automatic failover is not configured, update routing manually
curl -X PATCH https://am.company.com/api/v1/bastions/bastion-siteX \
  -H "Authorization: Bearer AM_API_KEY" \
  -d '{"enabled": false}'

# 3. Notify users to connect via alternative site
# Users in Site 1 can use Site 2: bastion-site2.company.com
```

**Recovery**:

```bash
# 1. Diagnose root cause (power, network, hardware, software)
# 2. Restore at least one Bastion node
# 3. Restore from backup
wabadmin restore --input /backup/bastion-siteX-latest.tar.gz

# 4. Apply license
wabadmin license apply --key "LICENSE_KEY_SITEX"

# 5. Verify authentication integration
wabadmin sso status
wabadmin auth test-radius --user test@company.com --token 123456

# 6. Re-enable site in Access Manager
curl -X PATCH https://am.company.com/api/v1/bastions/bastion-siteX \
  -H "Authorization: Bearer AM_API_KEY" \
  -d '{"enabled": true}'

# 7. Restore second node and rejoin cluster
wabadmin ha rejoin --partner 10.10.X.11
```

**Validation Checklist**:
- [ ] At least one Bastion node operational
- [ ] HAProxy shows at least one backend as UP
- [ ] SSO and MFA authentication working
- [ ] Access Manager routes sessions to the restored site
- [ ] Session recording functional
- [ ] Second node restored and cluster healthy

---

### WALLIX RDS Failure

#### Scenario 5: WALLIX RDS Failure (OT Access Loss)

**Detection**:
- RemoteApp sessions fail to launch
- Bastion reports RDS target as unreachable
- Users cannot access OT systems

**Impact**: OT RemoteApp access unavailable for the affected site. Native SSH/RDP access to non-OT targets is unaffected.

**Recovery**:

```bash
# 1. Diagnose the RDS server (10.10.X.30)
# Check via RDP or console access
# Verify Windows Server services

# 2. Restart Remote Desktop Services
# (On the RDS server via PowerShell)
Restart-Service -Name TermService -Force
Restart-Service -Name SessionEnv -Force

# 3. If server is unrecoverable, rebuild from backup
# Restore Windows Server backup
# Reinstall RDS role:
Install-WindowsFeature -Name RDS-RD-Server -IncludeManagementTools

# 4. Re-register RDS as target in Bastion
wabadmin target create --name "rds-siteX" \
  --host "10.10.X.30" \
  --protocol rdp \
  --port 3389 \
  --domain "COMPANY"

# 5. Test OT RemoteApp access
wabadmin session test --target "rds-siteX" --account "ot-access"
```

**Validation Checklist**:
- [ ] RDS server accessible via RDP
- [ ] RemoteApp sessions launch successfully
- [ ] OT target systems reachable through RDS
- [ ] Session recording of RemoteApp sessions working

---

### Access Manager Failures (Client-Managed)

> The Access Manager is installed and operated by the client team. AM failures are handled
> by the client team. Our role is to:
> 1. Detect the impact on Bastion-side SSO integration
> 2. Fall back to RADIUS-based authentication (Bastion → FortiAuth)
> 3. Notify the client AM team

#### Scenario 6: Access Manager Unreachable

**Detection**:
- SSO authentication (SAML redirect) fails
- Bastion logs report "AM unreachable" or SAML assertion timeout
- Client AM team's own alerting triggers

**Impact**: SSO login unavailable. Direct RADIUS-based authentication (AD + FortiToken TOTP) via per-site FortiAuth still works.

**Immediate Workaround**:

```bash
# RADIUS authentication still works while AM is down
# Users can authenticate with AD credentials + FortiToken TOTP directly on Bastion
# (if Bastion is configured for direct RADIUS as fallback — verify with wabadmin auth show)

# Check Bastion auth configuration
wabadmin auth show
# Look for: RADIUS server configured AND SSO fallback behavior

# Verify RADIUS to per-site FortiAuth still works
wabadmin auth test-radius --user testuser@company.local --site site1

# 1. Notify client AM team of the outage
# 2. Communicate to users: use direct Bastion URL with AD+TOTP credentials
# 3. Monitor AM recovery via health endpoint:
curl -k https://am1.client.com/health
```

**Recovery**:

```bash
# Recovery is handled by client AM team
# Our actions:
# 1. Verify SSO works after AM restored
wabadmin sso status

# 2. Test SAML login from Bastion
wabadmin auth test-saml --provider ClientAccessManager --user testuser

# 3. Confirm users can log in via SSO again
```

**Validation Checklist**:
- [ ] RADIUS (FortiAuth) authentication unaffected during AM outage
- [ ] Client AM team notified and engaged
- [ ] SSO restored after AM recovery
- [ ] SAML assertion flow tested from all 5 sites

---

#### Scenario 7: Both Access Managers Down (Extended Outage)

**Detection**:
- SSO authentication fails from all 5 sites
- Client AM team reports extended outage

**Impact**: SSO login unavailable. RADIUS authentication via FortiAuth still works.

**Immediate Workaround**:

```bash
# 1. RADIUS authentication is the fallback (per-site FortiAuth, not AM)
# Users authenticate with: AD credentials + FortiToken TOTP

# 2. If break glass is needed (RADIUS also fails):
# See 14-break-glass-procedures.md

# 3. Notify operations team and all users of SSO outage

# 4. Escalate to client AM team
```

**Recovery** (client team restores AM):

```bash
# After client AM team confirms AM is restored:
# 1. Test Bastion → AM HTTPS connectivity
curl -k https://am1.client.com/health

# 2. Verify SAML metadata still valid
wabadmin auth saml-verify --provider ClientAccessManager

# 3. Test SSO login from each site
for site in 1 2 3 4 5; do
  echo "Testing SSO Site ${site}..."
  wabadmin auth test-saml --site site${site} --provider ClientAccessManager
done
```

**Validation Checklist**:
- [ ] RADIUS authentication continued working throughout AM outage
- [ ] Client AM team engaged and restored AM
- [ ] SSO (SAML) restored and tested from all 5 sites
- [ ] No user data loss during outage

---

### FortiAuthenticator Failure

#### Scenario 8: FortiAuthenticator Failure (MFA Unavailable)

**Detection**:
- RADIUS authentication timeouts
- Users cannot complete MFA challenge
- Bastion logs show RADIUS connection refused or timeout

**Impact**: MFA unavailable. Users can authenticate with username/password only (reduced security).

**Recovery**:

Each site has its own FortiAuthenticator HA pair (Primary at 10.10.X.50, Secondary at 10.10.X.51, VIP at 10.10.X.52) in the Cyber VLAN. A single-node failure causes automatic RADIUS failover within the site — no action required. The following applies when both nodes of a site's FortiAuth pair are down.

```bash
# Replace X with the affected site number (1-5)

# 1. Test whether the site FortiAuth VIP is responding
nc -zvu 10.10.X.52 1812
# If VIP is down, test individual nodes:
nc -zvu 10.10.X.50 1812   # Primary
nc -zvu 10.10.X.51 1812   # Secondary

# 2. Verify from Bastion (run on bastion1-siteX)
wabadmin auth test-radius --user testuser@company.local --debug

# 3. If both nodes are down, invoke break glass for MFA bypass
# See 14-break-glass-procedures.md, Scenario: FortiAuthenticator Down

# 4. Coordinate with Security team to restore FortiAuthenticator nodes
#    - Log in to FortiAuthenticator admin console via console/IPMI
#    - Check sync status between Primary and Secondary
#    - Restore from FortiAuthenticator configuration backup if needed

# 5. Once restored, verify TOTP authentication from the affected site's Bastion
wabadmin auth test-radius --user testuser@company.local --token 000000
# Note: --token is the 6-digit TOTP code from FortiToken Mobile

# 6. Verify HA pair is synchronized (on FortiAuthenticator admin console)
#    System > High Availability > Status — both nodes must show "In sync"
```

**Validation Checklist**:
- [ ] RADIUS VIP (10.10.X.52) responding on UDP 1812
- [ ] Both FortiAuth nodes (10.10.X.50, 10.10.X.51) reachable from Bastion
- [ ] TOTP authentication succeeds for test user
- [ ] FortiAuth HA pair shows "In sync" status
- [ ] MFA bypass (if temporarily enabled) is revoked

---

### Network Failures

#### Scenario 9: MPLS Network Failure (Single Site Isolated)

**Detection**:
- Access Manager cannot reach the site Bastions (client AM team reports)
- Users at the site cannot authenticate via SSO (SAML redirect fails)
- Bastion logs show SAML metadata fetch timeout

**Impact**: Isolated site cannot communicate with Access Managers or peer sites. SSO login fails, but per-site FortiAuth RADIUS authentication continues to work (FortiAuth is in the local Cyber VLAN, not MPLS-dependent).

**Immediate Workaround**:

```bash
# RADIUS via per-site FortiAuth still works — no inter-site path required
# Users can authenticate with AD credentials + FortiToken TOTP directly on Bastion

# 1. Enable local authentication fallback on isolated site (if RADIUS also fails)
wabadmin auth configure --method local --fallback enable

# 2. Users access the site Bastion directly if needed
# VIP: https://10.10.X.100
# Direct Bastion-1: https://10.10.X.11

# 3. Existing sessions continue until timeout
# 4. Notify client AM team of isolation (MPLS circuit failure)
```

**Recovery**:

```bash
# 1. Coordinate with MPLS carrier for circuit restoration
# 2. Verify MPLS connectivity restored
ping am1.client.com   # AM-1 (client provides IP/hostname)
ping am2.client.com   # AM-2 (client provides IP/hostname)

# 3. Verify Bastion SAML connectivity to AM
wabadmin sso status

# 4. Disable local authentication fallback (if it was enabled)
wabadmin auth configure --method local --fallback disable

# 5. Test SSO login from affected site
wabadmin auth test-saml --provider ClientAccessManager --user testuser
```

**Validation Checklist**:
- [ ] MPLS connectivity restored (verified by ping/traceroute)
- [ ] RADIUS (FortiAuth) authentication was unaffected during MPLS outage
- [ ] SAML SSO authentication working after recovery
- [ ] Local auth fallback disabled (if it was enabled)
- [ ] Client AM team confirms site is visible in AM dashboard

---

#### Scenario 10: MPLS Network Failure (Multi-Site)

**Detection**:
- Multiple sites unreachable from Access Managers
- Widespread SSO failures reported

**Impact**: Multiple sites isolated. Proportional loss of PAM capacity.

**Recovery**:

```bash
# 1. Identify affected sites
for site in 1 2 3 4 5; do
  echo "Site ${site}:"
  ping -c 3 -W 2 10.10.${site}.11 && echo "REACHABLE" || echo "UNREACHABLE"
done

# 2. Enable local auth on all affected sites (break glass)
# See 14-break-glass-procedures.md

# 3. Coordinate MPLS carrier restoration

# 4. As sites come back online, verify and disable local auth
# 5. Run full validation per site
```

---

### Database Corruption

#### Scenario 11: MariaDB Corruption

**Detection**:
- Bastion reports database errors in logs
- Session data missing or inconsistent
- Replication errors between cluster nodes

**Impact**: Session management, audit logs, and configuration may be affected.

**Recovery**:

```bash
# 1. Stop Bastion services to prevent further corruption
systemctl stop wabcore

# 2. Attempt MariaDB repair
mysqlcheck --all-databases --check --auto-repair \
  -u root -p

# 3. If repair fails, restore from backup
systemctl stop mariadb

# Restore full dump
mysql -u root -p < /backup/bastion-siteX-db-latest.sql

# Apply binlogs for point-in-time recovery
mysqlbinlog /backup/binlog/mysql-bin.000* | mysql -u root -p

# 4. Restart services
systemctl start mariadb
systemctl start wabcore

# 5. If this node is part of a cluster, resync replication
wabadmin ha resync --from-partner

# 6. Verify data integrity
wabadmin database verify
wabadmin session list --recent 10  # Verify recent sessions are visible
```

**Validation Checklist**:
- [ ] MariaDB running without errors
- [ ] Bastion services operational
- [ ] Session data intact (verify recent sessions)
- [ ] Replication synchronized between cluster nodes
- [ ] Audit log continuity verified

---

### Certificate Issues

#### Scenario 12: Certificate Expiry

**Detection**:
- Browser SSL warnings when accessing Bastion web UI
- HAProxy SSL handshake failures
- Monitoring alert: certificate expiring within 30 days

**Impact**: Users see certificate warnings; some clients may refuse to connect.

**Recovery**:

```bash
# 1. Check current certificate expiry
openssl x509 -in /etc/haproxy/certs/bastion-siteX.pem -noout -enddate
openssl s_client -connect bastion-siteX.company.com:443 -servername bastion-siteX.company.com \
  2>/dev/null | openssl x509 -noout -enddate

# 2. Obtain new certificate from CA
# (Follow your organization's certificate request process)

# 3. Deploy new certificate to HAProxy
cp new-cert.pem /etc/haproxy/certs/bastion-siteX.pem
systemctl reload haproxy

# 4. Deploy new certificate to Bastion
wabadmin certificate install --cert new-cert.pem --key new-key.pem

# 5. Update Access Manager with new certificate (if pinned)
# Coordinate with AM team
```

#### Scenario 13: Certificate Compromise (Private Key Leaked)

**Detection**:
- Security team reports key compromise
- Unexpected certificate usage detected

**Impact**: Man-in-the-middle attacks possible until certificate is revoked and replaced.

**Recovery**:

```bash
# 1. IMMEDIATE: Revoke compromised certificate with CA
# 2. Generate new private key and CSR
openssl req -new -newkey rsa:4096 -nodes \
  -keyout new-key.pem \
  -out new-csr.pem \
  -subj "/CN=bastion-siteX.company.com"

# 3. Submit CSR to CA and obtain new certificate
# 4. Deploy new certificate (same as expiry recovery above)
# 5. Verify CRL/OCSP shows old certificate as revoked
# 6. Audit logs for suspicious activity during compromise window
```

**Validation Checklist**:
- [ ] Old certificate revoked (verify via CRL/OCSP)
- [ ] New certificate deployed on HAProxy and Bastion
- [ ] SSL connections working without warnings
- [ ] Access Manager updated with new certificate
- [ ] Security audit of compromise window completed

---

### License Pool Exhaustion

#### Scenario 14: License Pool Exhaustion

**Detection**:
- New session requests rejected with "License limit reached"
- License pool at 100% utilization
- Monitoring alert at 90% threshold

**Impact**: No new PAM sessions can be created across any site.

**Recovery**:

```bash
# License sizing: 25 users x 5 sites = 125 max simultaneous sessions
# Recommended pool: 150 total (30 per site), alert threshold at 80% (24/site)

# 1. Identify license consumption per site
for site in 1 2 3 4 5; do
  echo "Site ${site} license usage:"
  ssh bastion1-site${site}.company.com "wabadmin license status" 2>/dev/null || echo "UNREACHABLE"
done

# 2. Terminate idle sessions to free licenses
for site in 1 2 3 4 5; do
  echo "Cleaning idle sessions on Site ${site}..."
  ssh bastion1-site${site}.company.com \
    "wabadmin session cleanup --idle-timeout 1800"
done

# 3. If genuine capacity issue, request emergency license increase
# Contact WALLIX licensing: support@wallix.com
# Reference: Current Bastion license pool (150 concurrent sessions total)

# 4. Long-term: review session policies
# - Reduce maximum session duration
# - Implement session idle timeout (30 minutes recommended)
# - Review authorization policies for over-provisioning
```

**Validation Checklist**:
- [ ] License consumption below 80% threshold per site (24 of 30)
- [ ] New sessions can be created successfully
- [ ] Idle session cleanup policy in place
- [ ] Capacity planning review scheduled

---

### Full Site Loss

#### Scenario 15: Full Site Loss (Datacenter Disaster)

**Detection**:
- All components at a site unreachable (HAProxy, Bastion, RDS)
- Physical infrastructure failure (power, cooling, fire, flood)

**Impact**: One site fully unavailable. 20% capacity reduction. Users redirected to other sites.

**Recovery**:

```bash
# 1. IMMEDIATE: Notify client AM team — site X is down
#    Client AM team will disable the site in AM and route sessions elsewhere
#    Our role: confirm Bastion unreachable, provide status updates

# 2. Verify remaining sites can handle additional load
#    (Total capacity: 150 sessions / 5 sites = 30/site; 4 remaining sites = 120 capacity)
for site in 1 2 3 4 5; do
  echo "Site ${site} license usage:"
  ssh bastion1-site${site}.company.com "wabadmin license status" 2>/dev/null || echo "UNREACHABLE"
done

# 3. Check if 4 remaining sites have capacity for redirected sessions
#    If > 120 active sessions expected, terminate non-critical sessions:
#    wabadmin session cleanup --priority low

# 4. Communicate to users: site X unavailable, use alternative sites

# 5. When datacenter is restored, rebuild in order:
#    a. Rebuild HAProxy pair — see 06-haproxy-setup.md
#    b. Restore Bastion from backup (or rebuild + restore config)
wabadmin restore --input /backup/bastion-siteX-latest.tar.gz
#    c. Rebuild WALLIX RDS — see 09-rds-jump-host.md
#    d. Verify per-site FortiAuth HA pair is operational
nc -zvu 10.10.X.52 1812   # FortiAuth VIP
#    e. Verify per-site AD DC is operational
ldapsearch -H ldap://10.10.X.60 -x -b "" -s base
#    f. Run full validation — see 11-testing-validation.md
#    g. Notify client AM team to re-enable site X in AM

# 6. Confirm with client AM team that site X is showing healthy in AM dashboard
```

**Validation Checklist**:
- [ ] Client AM team notified and site X removed from AM routing
- [ ] Remaining sites (4) handling redirected load within 120-session capacity
- [ ] Users notified of site unavailability
- [ ] Disaster recovery timeline communicated to stakeholders
- [ ] Full site rebuilt and validated before client AM team re-enables it
- [ ] Post-incident review scheduled

---

### Multi-Site Loss

#### Scenario 16: Multi-Site Loss

**Detection**:
- Two or more sites simultaneously unreachable
- Common cause suspected (MPLS provider failure, regional event)

**Impact**: Significant capacity reduction. Remaining sites may be overloaded.

**Recovery**:

```bash
# 1. Identify affected vs. healthy sites
for site in 1 2 3 4 5; do
  echo "Site ${site}:"
  ping -c 2 -W 2 10.10.${site}.100 && echo "HEALTHY" || echo "DOWN"
done

# 2. Notify client AM team — provide list of affected sites
#    Client AM team will disable affected sites in AM and reroute sessions

# 3. Assess capacity of remaining sites
#    Total pool: 150 sessions, 30/site
#    If 2 sites down: remaining 3 sites = 90 session capacity
#    If 3 sites down: remaining 2 sites = 60 session capacity

# 4. If capacity insufficient:
#    a. Terminate non-critical sessions to prioritize critical access
wabadmin session cleanup --priority low
#    b. Restrict access to essential personnel only
#    c. Request emergency license capacity from WALLIX: support@wallix.com

# 5. Activate break glass procedures if RADIUS (FortiAuth) is also affected
# See 14-break-glass-procedures.md

# 6. Restore sites in priority order (most critical business operations first)
```

---

## Planned Maintenance Procedures

### Standalone Bastion Upgrade (WALLIX Bastion 12.1.x)

```bash
# Official upgrade procedure using BastionSecureUpgrade

# 1. Pre-upgrade: Create backup via GUI
#    System > Backup/Restore > Create Backup
#    Use an encryption key between 16 and 128 characters
#    Store the backup and key securely offsite

# 2. Upload ISO to Bastion via SCP (port 2242, wabupgrade account)
scp -P 2242 <BASTION_ISO_NAME>.iso wabupgrade@<BASTION_IP>:/home/wabupgrade/
scp -P 2242 <BASTION_ISO_NAME>.iso.sha256sum.sig wabupgrade@<BASTION_IP>:/home/wabupgrade/
scp -P 2242 <BASTION_ISO_NAME>.iso.sha256sum wabupgrade@<BASTION_IP>:/home/wabupgrade/

# 3. Run upgrade (as wabupgrade user)
ssh -p 2242 wabupgrade@<BASTION_IP>
BastionSecureUpgrade -i /home/wabupgrade/<BASTION_ISO_NAME>.iso \
  -c /home/wabupgrade/<BASTION_ISO_NAME>.iso.sha256sum \
  -s /home/wabupgrade/<BASTION_ISO_NAME>.iso.sha256sum.sig

# 4. Reboot after successful upgrade (as wabadmin -> root)
reboot
```

### HA Cluster Bastion Upgrade (WALLIX Bastion 12.1.x)

```bash
# Official HA upgrade procedure — all nodes must be upgraded together

# 1. Pre-upgrade: Create backup on ALL nodes
#    On each node: System > Backup/Restore > Create Backup
#    Use an encryption key between 16 and 128 characters
#    Store all backups and keys securely offsite
- [ ] Backup created on primary Master node
- [ ] Backup created on secondary node(s)
- [ ] All backups stored offsite with encryption keys

# 2. Stop replication (from primary Master as root)
bastion-replication --stop

# 3. Upload ISO to ALL nodes via SCP (port 2242, wabupgrade account)
scp -P 2242 <BASTION_ISO_NAME>.iso wabupgrade@<NODE_IP>:/home/wabupgrade/
scp -P 2242 <BASTION_ISO_NAME>.iso.sha256sum.sig wabupgrade@<NODE_IP>:/home/wabupgrade/
scp -P 2242 <BASTION_ISO_NAME>.iso.sha256sum wabupgrade@<NODE_IP>:/home/wabupgrade/

# 4. Run BastionSecureUpgrade on ALL nodes (can be run in parallel)
ssh -p 2242 wabupgrade@<NODE_IP>
BastionSecureUpgrade -i /home/wabupgrade/<BASTION_ISO_NAME>.iso \
  -c /home/wabupgrade/<BASTION_ISO_NAME>.iso.sha256sum \
  -s /home/wabupgrade/<BASTION_ISO_NAME>.iso.sha256sum.sig

# 5. Reboot ALL nodes (as wabadmin -> root)
reboot

# 6. After reboot, resync data from primary Master (as root)
bastion-replication --dump-resync

# 7. Start replication (from primary Master as root)
bastion-replication --start

# 8. Verify replication status (from primary Master as root)
bastion-replication --monitoring
```

**HA Upgrade Checklist**:
- [ ] Backups created on all nodes with encryption keys stored securely
- [ ] Replication stopped on primary Master
- [ ] ISO uploaded to all nodes
- [ ] BastionSecureUpgrade completed successfully on all nodes
- [ ] All nodes rebooted
- [ ] Replication resynchronized via `--dump-resync`
- [ ] Replication restarted and verified via `--monitoring`

### Post-Upgrade Verification

```bash
# 1. Verify Bastion version
#    Access Bastion web UI and confirm version is 12.1.x

# 2. Check crypto algorithms and HTTP security level
WABSecurityLevel
# Default HTTP security level is "high", which enables:
#   ECDHE-ECDSA-AES256-GCM-SHA384
#   ECDHE-RSA-AES256-GCM-SHA384
#   ECDHE-ECDSA-AES128-GCM-SHA256
#   ECDHE-RSA-AES128-GCM-SHA256

# 3. Verify services are running
#    Check Bastion web UI is accessible
#    Test SSH and RDP proxy connectivity

# 4. Verify HA cluster health (if applicable)
bastion-replication --monitoring
```

**Post-Upgrade Validation Checklist**:
- [ ] Bastion version confirmed as 12.1.x
- [ ] Crypto algorithms verified with `WABSecurityLevel`
- [ ] Web UI accessible
- [ ] SSH proxy functional
- [ ] RDP proxy functional
- [ ] Session recording working
- [ ] HA replication healthy (if applicable)

### Upgrade Rollback Procedures

#### Virtual Appliances

```bash
# Rollback by restoring VM snapshot taken before upgrade
# 1. Power off the Bastion VM
# 2. Restore the VM snapshot taken before the upgrade
# 3. Power on the VM
# 4. Verify Bastion services are operational
# 5. If HA cluster: repeat on all nodes, then resync replication
bastion-replication --dump-resync
bastion-replication --start
bastion-replication --monitoring
```

#### Physical Appliances

```bash
# Rollback requires reinstall from ISO + restore backup

# 1. Create a bootable USB from the previous version ISO
# 2. Reinstall WALLIX Bastion from the USB

# 3. Restore configuration backup
wallix-config-restore.py

# 4. Import session recordings from backup
WABSessionLogImport

# 5. Verify Bastion services are operational

# 6. If HA cluster: repeat on all nodes, then resync replication
bastion-replication --dump-resync
bastion-replication --start
bastion-replication --monitoring
```

**Rollback Checklist**:
- [ ] Bastion restored to previous version
- [ ] Configuration restored (policies, authorizations, accounts)
- [ ] Session recordings imported
- [ ] Services operational and accessible
- [ ] HA replication healthy (if applicable)
- [ ] Access Manager connectivity verified

### HAProxy Patching

```bash
# Patch HAProxy nodes one at a time

# 1. On BACKUP node first:
apt-get update && apt-get upgrade -y haproxy
systemctl restart haproxy
# Verify: haproxy -vv

# 2. Failover VIP to patched BACKUP node
# On current MASTER:
systemctl stop keepalived
# Verify VIP moves to patched node

# 3. Patch the former MASTER node
apt-get update && apt-get upgrade -y haproxy
systemctl restart haproxy
systemctl start keepalived
# VIP returns to original MASTER (higher priority)
```

### Certificate Renewal

```bash
# Renew certificates before expiry (minimum 30 days ahead)

# 1. Check all certificate expiry dates
for site in 1 2 3 4 5; do
  echo "Site ${site}:"
  echo | openssl s_client -connect bastion-site${site}.company.com:443 \
    -servername bastion-site${site}.company.com 2>/dev/null | \
    openssl x509 -noout -dates
done

# 2. Request new certificates from CA
# 3. Deploy to HAProxy (reload, no restart needed)
cp new-cert.pem /etc/haproxy/certs/bastion-siteX.pem
systemctl reload haproxy

# 4. Deploy to Bastion
wabadmin certificate install --cert new-cert.pem --key new-key.pem

# 5. Verify no SSL warnings
curl -vI https://bastion-siteX.company.com 2>&1 | grep "expire date"
```

### Database Maintenance

```bash
# Monthly database optimization (schedule during maintenance window)

# 1. Optimize MariaDB tables
mysqlcheck --all-databases --optimize -u root -p

# 2. Purge old session recordings (per retention policy)
wabadmin recording cleanup --older-than 365

# 3. Purge old audit logs (per retention policy)
wabadmin log cleanup --older-than 365

# 4. Verify database size and disk usage
df -h /var/lib/mysql
mysql -e "SELECT table_schema, ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)' FROM information_schema.tables GROUP BY table_schema;"
```

---

## Communication and Escalation Matrix

### Escalation Levels

| Level | Team | Contact | Response Time | Scope |
|-------|------|---------|---------------|-------|
| **L1** | Operations | operations@company.com | 30 min (business), 2 h (after hours) | Service restarts, known issues, monitoring |
| **L2** | Infrastructure | infrastructure@company.com | 2 h | Network, hardware, clustering, failover |
| **L3** | Security | security@company.com | 1 h | Certificate issues, MFA, credential compromise |
| **L4** | WALLIX Support | support@wallix.com | Per SLA (1-8 h) | Product defects, complex recovery |
| **L5** | Management | pam-management@company.com | Immediate | Full site loss, multi-site outage, business impact |

### Communication Templates

**Incident Start**:
```
Subject: [INCIDENT] WALLIX PAM - [Component] - [Site] - [Severity]
Impact: [Description of user impact]
Status: Investigating / Mitigating / Resolved
ETA: [Estimated resolution time]
Workaround: [If available]
Next update: [Time of next status update]
```

**Incident Resolution**:
```
Subject: [RESOLVED] WALLIX PAM - [Component] - [Site]
Root Cause: [Brief description]
Resolution: [What was done to fix it]
Duration: [Start time - End time]
Impact: [Number of affected users/sessions]
Follow-up: Post-incident review scheduled for [date]
```

---

## Post-Incident Review Template

Conduct a post-incident review within 5 business days of any Severity 1 or Severity 2 incident.

### Review Document Structure

```markdown
# Post-Incident Review: [Incident Title]

## Incident Summary
- **Date/Time**: [Start] to [End]
- **Duration**: [Total duration]
- **Severity**: [1-4]
- **Affected Components**: [List]
- **Affected Sites**: [List]
- **User Impact**: [Number of users, description]

## Timeline
| Time | Event |
|------|-------|
| HH:MM | [Event description] |

## Root Cause
[Detailed root cause analysis]

## Resolution
[Steps taken to resolve the incident]

## What Went Well
- [Item]

## What Could Be Improved
- [Item]

## Action Items
| Action | Owner | Due Date | Status |
|--------|-------|----------|--------|
| [Action description] | [Name] | [Date] | Open |

## Lessons Learned
[Key takeaways for preventing similar incidents]
```

---

## Cross-References

| Document | Relevance |
|----------|-----------|
| [06-haproxy-setup.md](06-haproxy-setup.md) | HAProxy configuration and troubleshooting |
| [07-bastion-active-active.md](07-bastion-active-active.md) | Active-Active cluster recovery |
| [08-bastion-active-passive.md](08-bastion-active-passive.md) | Active-Passive cluster recovery |
| [09-rds-jump-host.md](09-rds-jump-host.md) | WALLIX RDS rebuild procedures |
| [10-licensing.md](10-licensing.md) | License pool management |
| [11-testing-validation.md](11-testing-validation.md) | Post-recovery validation procedures |
| [12-architecture-diagrams.md](12-architecture-diagrams.md) | Network topology reference |
| [14-break-glass-procedures.md](14-break-glass-procedures.md) | Emergency access when normal channels fail |
| [15-access-manager-integration.md](15-access-manager-integration.md) | Access Manager recovery |

---

**Document Version**: 2.0
**Last Updated**: April 2026
