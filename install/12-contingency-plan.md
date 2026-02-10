# Contingency Plan - Disaster Recovery and Business Continuity

> Recovery procedures for planned and unplanned failure scenarios across the 5-site WALLIX PAM infrastructure

---

## Document Information

| Property | Value |
|----------|-------|
| **Purpose** | Disaster recovery and business continuity procedures for multi-site PAM deployment |
| **Scope** | All 5 Bastion sites, 2 Access Managers, HAProxy, WALLIX RDS, FortiAuthenticator |
| **Classification** | Confidential - Operations Team Only |
| **Review Frequency** | Quarterly, or after any major incident |
| **Version** | 1.0 |
| **Last Updated** | February 2026 |

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
|  Access Manager Layer:                                                        |
|  +-------------------+          +-------------------+                         |
|  | AM-1 (DC-A)       |   HA    | AM-2 (DC-B)       |                         |
|  | 10.100.1.10       |<------->| 10.100.2.10       |                         |
|  +-------------------+          +-------------------+                         |
|                                                                               |
|  Site Layer (x5):                                                             |
|  +---------------------------------------------------------------+            |
|  |  HAProxy Pair    Bastion Cluster    WALLIX RDS                |            |
|  |  (Active-Passive) (Active-Active     (Single Instance)        |            |
|  |                   or Active-Passive)                          |            |
|  +---------------------------------------------------------------+            |
|                                                                               |
|  Shared Infrastructure:                                                       |
|  +-------------------------------+  +-------------------------------+         |
|  | FortiAuthenticator (Primary)  |  | FortiAuthenticator (Secondary)|         |
|  | 10.20.0.60                    |  | 10.20.0.61                    |         |
|  +-------------------------------+  +-------------------------------+         |
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
| **Access Manager (single)** | 0 s (HA failover) | 0 (replicated) | None - partner takes over |
| **Access Manager (both)** | 4 h | 1 h | SSO/MFA/brokering unavailable |
| **FortiAuthenticator** | 15 min (failover to secondary) | N/A | MFA unavailable |
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
# Follow 05-haproxy-setup.md

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
- Cluster partner detects peer failure (Pacemaker/Corosync or HA heartbeat)
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

### Access Manager Failures

#### Scenario 6: Single Access Manager Failure

**Detection**:
- HA partner detects failure and takes over
- Health check alerts: AM node unreachable
- No user impact if HA failover is successful

**Impact**: None — HA partner handles all requests.

**Recovery** (restore HA redundancy):

```bash
# 1. Diagnose the failed AM node
# Check via IPMI/iLO or console access

# 2. If service issue, restart Access Manager services
# (Handled by Access Manager team)

# 3. Verify HA failover occurred
# Check from surviving AM node
# Verify all Bastion sites can reach the surviving AM

# 4. Once failed node is restored, verify HA resync
# Confirm configuration replication is current
# Confirm license pool data is synchronized

# 5. Test failback (optional, coordinate with AM team)
```

**Validation Checklist**:
- [ ] Surviving AM node handles all SSO/MFA requests
- [ ] All 5 Bastion sites can authenticate
- [ ] Session brokering continues without interruption
- [ ] Failed AM node restored and HA resynchronized

---

#### Scenario 7: Both Access Managers Down

**Detection**:
- SSO authentication fails for all users
- Session brokering API unreachable
- All Bastion sites report AM connectivity failure

**Impact**: SSO, MFA enforcement, and centralized session brokering unavailable. Users cannot authenticate via normal channels.

**Immediate Workaround**: Invoke break glass procedures. See [13-break-glass-procedures.md](13-break-glass-procedures.md).

```bash
# 1. Enable local authentication on each Bastion
wabadmin auth configure --method local --fallback enable

# 2. Users authenticate directly to Bastion with local credentials
# (Break glass accounts must be pre-created)

# 3. Notify all site administrators
```

**Recovery**:

```bash
# 1. Restore at least one Access Manager (coordinate with AM team)
# 2. Verify SSO metadata is valid
# 3. Test authentication from each Bastion site
wabadmin sso status
wabadmin auth test --user test@company.com

# 4. Disable local authentication fallback
wabadmin auth configure --method local --fallback disable

# 5. Restore second AM node for HA
# 6. Verify license pool synchronization
```

**Validation Checklist**:
- [ ] At least one AM node operational
- [ ] SSO authentication working from all 5 sites
- [ ] MFA enforcement re-enabled
- [ ] Session brokering functional
- [ ] License pool data intact
- [ ] Local auth fallback disabled
- [ ] HA restored between both AM nodes

---

### FortiAuthenticator Failure

#### Scenario 8: FortiAuthenticator Failure (MFA Unavailable)

**Detection**:
- RADIUS authentication timeouts
- Users cannot complete MFA challenge
- Bastion logs show RADIUS connection refused or timeout

**Impact**: MFA unavailable. Users can authenticate with username/password only (reduced security).

**Recovery**:

```bash
# 1. Test primary FortiAuthenticator
nc -zvu 10.20.0.60 1812
wabadmin auth test-radius --user test@company.com --debug

# 2. If primary is down, verify failover to secondary
nc -zvu 10.20.0.61 1812

# 3. If both are down, invoke break glass for MFA bypass
# See 13-break-glass-procedures.md, Scenario: FortiAuthenticator Down

# 4. Coordinate with Security team to restore FortiAuthenticator

# 5. Once restored, verify MFA from each Bastion site
for site in 1 2 3 4 5; do
  echo "Testing Site ${site}..."
  ssh bastion1-site${site}.company.com "wabadmin auth test-radius --user test@company.com --token 000000"
done
```

**Validation Checklist**:
- [ ] RADIUS connectivity restored (primary and secondary)
- [ ] MFA challenge works for test user
- [ ] FortiToken push notifications received
- [ ] All 5 Bastion sites can reach FortiAuthenticator
- [ ] MFA bypass (if temporarily enabled) is revoked

---

### Network Failures

#### Scenario 9: MPLS Network Failure (Single Site Isolated)

**Detection**:
- Access Manager cannot reach the site Bastions
- Site health check fails in AM dashboard
- Users at the site cannot authenticate via SSO

**Impact**: Isolated site cannot communicate with Access Managers. Local sessions in progress continue, but new SSO/brokered sessions fail.

**Immediate Workaround**:

```bash
# 1. Enable local authentication on isolated site
wabadmin auth configure --method local --fallback enable

# 2. Users can authenticate with local/break glass accounts
# Direct access: https://10.10.X.11 (bypass HAProxy VIP if also affected)

# 3. Existing sessions continue until timeout
```

**Recovery**:

```bash
# 1. Coordinate with MPLS carrier for circuit restoration
# 2. Verify MPLS connectivity restored
ping 10.100.1.10  # AM-1
ping 10.100.2.10  # AM-2

# 3. Verify Access Manager health check passes
curl -X GET https://am.company.com/api/v1/bastions/bastion-siteX/health \
  -H "Authorization: Bearer AM_API_KEY"

# 4. Disable local authentication fallback
wabadmin auth configure --method local --fallback disable

# 5. Test SSO and session brokering
```

**Validation Checklist**:
- [ ] MPLS connectivity restored (verified by ping/traceroute)
- [ ] Access Manager shows site as healthy
- [ ] SSO authentication working
- [ ] Session brokering functional
- [ ] Local auth fallback disabled

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
# See 13-break-glass-procedures.md

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
# 1. Identify license consumption per site
wabadmin license status
curl -X GET https://am.company.com/api/v1/licenses/pool/bastion-pool-450 \
  -H "Authorization: Bearer AM_API_KEY"

# 2. Terminate idle sessions to free licenses
for site in 1 2 3 4 5; do
  echo "Cleaning idle sessions on Site ${site}..."
  ssh bastion1-site${site}.company.com \
    "wabadmin session cleanup --idle-timeout 1800"
done

# 3. If genuine capacity issue, request emergency license increase
# Contact WALLIX licensing: support@wallix.com
# Reference: License Pool bastion-pool-450

# 4. Long-term: review session policies
# - Reduce maximum session duration
# - Implement session idle timeout
# - Review authorization policies for over-provisioning
```

**Validation Checklist**:
- [ ] License consumption below 90% threshold
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
# 1. IMMEDIATE: Disable site in Access Manager
curl -X PATCH https://am.company.com/api/v1/bastions/bastion-siteX \
  -H "Authorization: Bearer AM_API_KEY" \
  -d '{"enabled": false}'

# 2. Access Manager routes sessions to remaining 4 sites automatically

# 3. Verify remaining sites can handle additional load
for site in 1 2 3 4 5; do
  echo "Site ${site} license usage:"
  ssh bastion1-site${site}.company.com "wabadmin license status" 2>/dev/null || echo "UNREACHABLE"
done

# 4. Communicate to users: site X unavailable, use alternative sites

# 5. When datacenter is restored:
#    a. Rebuild HAProxy pair (05-haproxy-setup.md)
#    b. Restore Bastion from backup (or rebuild + restore config)
#    c. Rebuild WALLIX RDS (08-rds-jump-host.md)
#    d. Re-register with Access Manager
#    e. Run full validation (10-testing-validation.md)

# 6. Re-enable site
curl -X PATCH https://am.company.com/api/v1/bastions/bastion-siteX \
  -H "Authorization: Bearer AM_API_KEY" \
  -d '{"enabled": true}'
```

**Validation Checklist**:
- [ ] Remaining sites handling redirected load
- [ ] Users notified of site unavailability
- [ ] Disaster recovery timeline communicated to stakeholders
- [ ] Full site rebuilt and validated before re-enabling
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

# 2. Disable affected sites in Access Manager
# 3. Assess capacity of remaining sites
#    Total pool: 450 sessions
#    If 2 sites down: remaining 3 sites must handle all sessions

# 4. If capacity insufficient:
#    a. Terminate non-critical sessions to prioritize critical access
#    b. Restrict access to essential personnel only
#    c. Request emergency license capacity

# 5. Activate break glass procedures if Access Manager is also affected
# See 13-break-glass-procedures.md

# 6. Restore sites in priority order (highest capacity first)
```

---

## Planned Maintenance Procedures

### Rolling Bastion Upgrade

```bash
# Upgrade Bastion nodes one at a time to maintain availability

# 1. Pre-upgrade backup
wabadmin backup create --output /backup/pre-upgrade-$(date +%Y%m%d).tar.gz

# 2. Drain sessions from node to be upgraded
# On HAProxy, set node to maintenance mode:
echo "set server bastion-web-backend/bastion1 state maint" | \
  socat stdio /run/haproxy/admin.sock

# Wait for active sessions to complete (or set timeout)
wabadmin session list --active --node bastion1

# 3. Upgrade the drained node
wabadmin upgrade apply --version 12.1.x --accept-eula

# 4. Verify upgraded node
wabadmin status
wabadmin ha status

# 5. Re-enable node in HAProxy
echo "set server bastion-web-backend/bastion1 state ready" | \
  socat stdio /run/haproxy/admin.sock

# 6. Repeat for second node

# 7. Post-upgrade validation
wabadmin session test --target test-server --account test
```

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
| [05-haproxy-setup.md](05-haproxy-setup.md) | HAProxy configuration and troubleshooting |
| [06-bastion-active-active.md](06-bastion-active-active.md) | Active-Active cluster recovery |
| [07-bastion-active-passive.md](07-bastion-active-passive.md) | Active-Passive cluster recovery |
| [08-rds-jump-host.md](08-rds-jump-host.md) | WALLIX RDS rebuild procedures |
| [09-licensing.md](09-licensing.md) | License pool management |
| [10-testing-validation.md](10-testing-validation.md) | Post-recovery validation procedures |
| [11-architecture-diagrams.md](11-architecture-diagrams.md) | Network topology reference |
| [13-break-glass-procedures.md](13-break-glass-procedures.md) | Emergency access when normal channels fail |
| [03-access-manager-integration.md](03-access-manager-integration.md) | Access Manager recovery |

---

**Document Version**: 1.0
**Last Updated**: February 2026
