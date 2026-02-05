# Testing and Validation - 5-Site Multi-Datacenter Deployment

> Comprehensive testing procedures for validating WALLIX Bastion deployment across 5 sites with Access Manager integration

---

## Document Information

| Property | Value |
|----------|-------|
| **Purpose** | End-to-end testing and validation procedures |
| **Scope** | 5 Bastion sites + 2 Access Managers + FortiAuthenticator |
| **Timeline** | Phase 8-9 testing (Week 9 of deployment) |
| **Version** | WALLIX Bastion 12.1.x |
| **Last Updated** | February 2026 |

---

## Table of Contents

1. [Testing Overview](#testing-overview)
2. [Component Testing](#component-testing)
3. [Integration Testing](#integration-testing)
4. [End-to-End User Workflow Testing](#end-to-end-user-workflow-testing)
5. [Failover Testing](#failover-testing)
6. [Performance Testing](#performance-testing)
7. [Security Testing](#security-testing)
8. [Acceptance Criteria](#acceptance-criteria)
9. [Sign-Off Checklist](#sign-off-checklist)

---

## Testing Overview

### Testing Strategy

```
+===============================================================================+
|  TESTING PYRAMID - 5-SITE DEPLOYMENT                                          |
+===============================================================================+
|                                                                               |
|                         +---------------------+                               |
|                         |   E2E Testing       |                               |
|                         |   (5-10% of tests)  |                               |
|                         |   User Workflows    |                               |
|                         +---------------------+                               |
|                                                                               |
|                  +---------------------------+                                |
|                  |   Integration Testing     |                                |
|                  |   (20-30% of tests)       |                                |
|                  |   Component Interactions  |                                |
|                  +---------------------------+                                |
|                                                                               |
|         +----------------------------------------+                            |
|         |        Component Testing               |                            |
|         |        (60-70% of tests)               |                            |
|         |        Individual Components           |                            |
|         +----------------------------------------+                            |
|                                                                               |
+===============================================================================+
```

### Testing Phases

| Phase | Focus | Duration | Dependencies |
|-------|-------|----------|--------------|
| **Phase 1: Component Testing** | Individual component validation | 1-2 days | All components installed |
| **Phase 2: Integration Testing** | Component interactions | 2-3 days | Phase 1 complete |
| **Phase 3: E2E User Workflows** | Complete user journeys | 2-3 days | Phase 2 complete |
| **Phase 4: Failover Testing** | HA and DR scenarios | 1-2 days | Phase 3 complete |
| **Phase 5: Performance Testing** | Load and scalability | 2-3 days | Phase 4 complete |
| **Phase 6: Security Testing** | Penetration and compliance | 2-3 days | Phase 5 complete |

**Total Testing Timeline**: 10-16 days (2-3 weeks)

### Test Environment

```
Testing Scope:
==============

Sites:
- Site 1 (DC-1): 2x Bastion + 2x HAProxy + 1x RDS
- Site 2 (DC-2): 2x Bastion + 2x HAProxy + 1x RDS
- Site 3 (DC-3): 2x Bastion + 2x HAProxy + 1x RDS
- Site 4 (DC-4): 2x Bastion + 2x HAProxy + 1x RDS
- Site 5 (DC-5): 2x Bastion + 2x HAProxy + 1x RDS

Shared Infrastructure:
- 2x Access Manager (DC-A, DC-B) in HA
- 2x FortiAuthenticator (Primary, Secondary)
- Active Directory (2x domain controllers)
- MPLS network connectivity

Target Systems:
- 5x Windows Server 2022 (RDP targets)
- 5x RHEL 10 (SSH targets)
- 3x RHEL 9 (SSH legacy targets)
```

---

## Component Testing

### 1.1 HAProxy Testing (Per Site)

#### Test 1.1.1: HAProxy Service Health

```bash
# Test on each site (Site 1-5)
ssh admin@haproxy1-site1.company.com

# Check HAProxy service status
systemctl status haproxy
# Expected: active (running)

# Check HAProxy configuration syntax
haproxy -c -f /etc/haproxy/haproxy.cfg
# Expected: Configuration file is valid

# Check HAProxy statistics
echo "show stat" | socat stdio /var/lib/haproxy/stats
# Expected: Backend servers showing UP status

# Test HAProxy API
curl -u admin:password http://localhost:8404/stats
# Expected: HTTP 200, statistics page displayed
```

**Expected Results:**
- [ ] HAProxy service running on both nodes (primary and backup)
- [ ] Configuration valid with no syntax errors
- [ ] Statistics socket accessible
- [ ] Web stats interface accessible on port 8404

#### Test 1.1.2: HAProxy VRRP Failover

```bash
# Test VRRP virtual IP assignment
ip addr show | grep 10.10.1.100
# Expected: VIP present on primary node

# Check Keepalived status
systemctl status keepalived
# Expected: active (running)

# Test VRRP failover
# On primary node:
systemctl stop keepalived

# Verify VIP migration (< 3 seconds)
# On backup node:
ip addr show | grep 10.10.1.100
# Expected: VIP migrated to backup

# Test user connectivity during failover
while true; do curl -k https://10.10.1.100/health; sleep 1; done
# Expected: Brief interruption (< 3s), then successful responses

# Restart primary Keepalived
systemctl start keepalived
```

**Expected Results:**
- [ ] VIP assigned to primary under normal conditions
- [ ] VIP fails over to backup within 3 seconds
- [ ] User traffic automatically routed to backup
- [ ] Primary can reclaim VIP after restoration

#### Test 1.1.3: HAProxy Load Balancing

```bash
# Test load distribution to Bastion backends
for i in {1..100}; do
  curl -k https://10.10.1.100/health 2>&1 | grep -o "bastion[12]"
done | sort | uniq -c

# Expected: Approximately 50/50 distribution
#   50 bastion1
#   50 bastion2

# Test session persistence (cookie-based)
curl -k -c cookies.txt https://10.10.1.100/login
curl -k -b cookies.txt https://10.10.1.100/dashboard

# Expected: Both requests routed to same backend

# Check HAProxy backend health
echo "show servers state" | socat stdio /var/lib/haproxy/stats
# Expected: Both bastion1 and bastion2 status UP
```

**Expected Results:**
- [ ] Traffic distributed evenly across both Bastion nodes
- [ ] Session persistence maintained via cookies
- [ ] Health checks detecting backend status correctly
- [ ] Failed backends automatically removed from rotation

### 1.2 WALLIX Bastion Testing (Per Site)

#### Test 1.2.1: Bastion Service Health

```bash
# SSH to primary Bastion node
ssh admin@bastion1-site1.company.com

# Check WALLIX service status
systemctl status wallix-bastion
# Expected: active (running)

# Check Bastion internal health
wabadmin status
# Expected: All services running

# Check database connectivity
wabadmin db-status
# Expected: Database accessible, replication active

# Check license status
wabadmin license-info
# Expected: Valid license, sessions available
```

**Expected Results:**
- [ ] WALLIX Bastion service running on both nodes
- [ ] All internal services (web, SSH, RDP) active
- [ ] Database reachable and synchronized
- [ ] License valid with available session slots

#### Test 1.2.2: Bastion HA Cluster Status

```bash
# Check cluster status (Active-Active OR Active-Passive)

# For Active-Active:
wabadmin cluster-status
# Expected: Both nodes ACTIVE

crm status
# Expected: Online: [ bastion1-site1 bastion2-site1 ]

# Check MariaDB Galera cluster
mysql -e "SHOW STATUS LIKE 'wsrep_cluster_size';"
# Expected: wsrep_cluster_size = 2

# For Active-Passive:
wabadmin cluster-status
# Expected: Node1 PRIMARY, Node2 STANDBY

crm status
# Expected: Primary: bastion1-site1, Standby: bastion2-site1

# Check MariaDB replication
mysql -e "SHOW SLAVE STATUS\G"
# Expected: Slave_IO_Running: Yes, Slave_SQL_Running: Yes
```

**Expected Results:**
- [ ] Cluster recognized and operational
- [ ] Database replication working (Active-Active or Active-Passive)
- [ ] Pacemaker/Corosync cluster healthy
- [ ] No split-brain condition detected

#### Test 1.2.3: Bastion Credential Vault

```bash
# Test credential storage and retrieval
wabadmin credential add \
  --device "test-server-01" \
  --account "testuser" \
  --password "TestP@ssw0rd123" \
  --domain "company.com"

# Verify credential stored
wabadmin credential list | grep test-server-01
# Expected: Credential listed

# Test credential retrieval (encrypted)
wabadmin credential get --device "test-server-01" --account "testuser"
# Expected: Credential details returned (password masked)

# Test credential checkout (for session use)
wabadmin credential checkout --device "test-server-01" --account "testuser"
# Expected: Password decrypted and provided
```

**Expected Results:**
- [ ] Credentials stored encrypted in vault
- [ ] Credentials retrievable by authorized users only
- [ ] Credential checkout audited in logs
- [ ] Credential rotation policies enforced

### 1.3 WALLIX RDS Testing (Per Site)

#### Test 1.3.1: RDS Service Health

```bash
# RDP to WALLIX RDS server
mstsc /v:rds-site1.company.com

# Login with admin credentials

# Check RDS role installed
Get-WindowsFeature -Name RDS-RD-Server
# Expected: Installed

# Check RemoteApp configuration
Get-RDRemoteApp
# Expected: Published RemoteApps listed

# Check RDS licensing
Get-RDLicenseConfiguration
# Expected: License server configured, mode PerUser
```

**Expected Results:**
- [ ] RDS service running and accessible
- [ ] RemoteApps published for OT access
- [ ] RDS licensing configured correctly
- [ ] Session collection active

#### Test 1.3.2: RDS Connection via Bastion

```bash
# Test OT access via RDS jump host
# User connects to Bastion → Bastion routes to RDS → RDS connects to OT target

# Login to Bastion web UI
https://bastion-site1.company.com

# Select OT target (via RDS RemoteApp)
# Target: ot-workstation-01.company.com
# Protocol: RDP (RemoteApp)

# Expected: RemoteApp session launched
# User sees only the published application, not full desktop

# Verify session recording
wabadmin sessions --active | grep rds
# Expected: RDS session listed with recording active
```

**Expected Results:**
- [ ] RDS jump host accessible via Bastion
- [ ] RemoteApp sessions launch successfully
- [ ] OT targets reachable via RDS
- [ ] Sessions recorded and audited

### 1.4 Access Manager Testing

#### Test 1.4.1: Access Manager HA Status

```bash
# Check AM HA status (coordinated with AM team)
ssh admin@accessmanager-1.company.com

# Check Access Manager service
systemctl status wallix-access-manager
# Expected: active (running)

# Check HA replication status
wab-am ha-status
# Expected: Primary: AM1, Standby: AM2, Replication: Active

# Check database replication
mysql -e "SHOW SLAVE STATUS\G"
# Expected: Slave_IO_Running: Yes, Slave_SQL_Running: Yes
```

**Expected Results:**
- [ ] Access Manager service running on both nodes
- [ ] HA pair synchronized and healthy
- [ ] Database replication active
- [ ] Session broker active

#### Test 1.4.2: Access Manager Session Brokering

```bash
# Test session routing to Bastion sites
# From Access Manager admin console:

# Check Bastion site health
wab-am sites --status
# Expected:
# Site1: Healthy (15% load)
# Site2: Healthy (25% load)
# Site3: Healthy (30% load)
# Site4: Healthy (20% load)
# Site5: Healthy (10% load)

# Test routing decision
wab-am route-test --user "jsmith" --target "prod-db-01.company.com"
# Expected: Routes to optimal site (lowest load, healthy)
```

**Expected Results:**
- [ ] All Bastion sites registered with AM
- [ ] Health checks successful for all sites
- [ ] Routing policy working correctly
- [ ] Failover to alternate sites functional

### 1.5 FortiAuthenticator Testing

#### Test 1.5.1: FortiAuth RADIUS Service

```bash
# Test RADIUS authentication (coordinated with Security team)
ssh admin@fortiauth.company.com

# Check RADIUS service status
diagnose debug application radiusd -1
# Expected: RADIUS daemon running

# Test RADIUS authentication for test user
radtest testuser TestP@ss123 localhost 0 sharedsecret
# Expected: Access-Accept (or Access-Challenge for MFA)

# Check RADIUS accounting
tail -f /var/log/radius/radacct/accessmanager-1/detail
# Expected: Accounting records logged
```

**Expected Results:**
- [ ] RADIUS service running on primary and secondary
- [ ] RADIUS clients (Access Managers) configured
- [ ] Test authentication successful
- [ ] Accounting logs generated

#### Test 1.5.2: FortiToken MFA

```bash
# Test FortiToken push notification
# Login to FortiAuthenticator web UI
https://fortiauth.company.com

# Navigate to: Authentication > Test Authentication

# Test user:
Username: jsmith
Password: [User's AD password]

# Expected: Push notification sent to user's mobile device

# User approves on FortiToken Mobile app

# Expected: Authentication successful, Access-Accept returned
```

**Expected Results:**
- [ ] FortiToken push notifications delivered
- [ ] Users can approve/deny MFA challenges
- [ ] Timeout after 60 seconds if not approved
- [ ] Fallback to OTP code functional

---

## Integration Testing

### 2.1 SSO Integration Testing

#### Test 2.1.1: SAML Authentication Flow

```bash
# Test SAML SSO from user perspective

# 1. Access Bastion portal
curl -v https://bastion-site1.company.com/login
# Expected: HTTP 302 redirect to Access Manager

# 2. Follow redirect to Access Manager
# Expected: SAML authentication request received

# 3. Simulate user login
# Expected: Redirect to FortiAuthenticator for MFA

# 4. Complete MFA challenge
# Expected: SAML assertion issued by Access Manager

# 5. Redirect back to Bastion
# Expected: User authenticated, session created

# Verify SAML assertion
wabadmin audit --last 10 | grep -i saml
# Expected: SAML authentication logged
```

**Expected Results:**
- [ ] SAML redirect chain functions correctly
- [ ] User attributes mapped properly (email, groups, etc.)
- [ ] Session created after successful SAML authentication
- [ ] SSO session persists across Bastion sites

#### Test 2.1.2: OIDC Authentication Flow

```bash
# Test OIDC authentication (if configured)

# 1. Access Bastion portal
curl -v https://bastion-site1.company.com/login
# Expected: HTTP 302 redirect to OIDC authorize endpoint

# 2. Check OIDC discovery
curl https://accessmanager.company.com/.well-known/openid-configuration
# Expected: JSON with OIDC endpoints

# 3. Complete authentication flow
# Expected: Authorization code returned

# 4. Token exchange
# Expected: ID token and access token issued

# Verify token claims
wabadmin oidc-token decode --token [ID_TOKEN]
# Expected: User claims (sub, email, groups) present
```

**Expected Results:**
- [ ] OIDC discovery endpoint accessible
- [ ] Authorization code flow completes successfully
- [ ] Tokens issued with correct claims
- [ ] Refresh token functionality working

### 2.2 MFA Integration Testing

#### Test 2.2.1: FortiToken Push Notification

```bash
# End-to-end MFA test

# 1. User initiates login to Bastion (via Access Manager)
# 2. User enters AD credentials
# 3. Access Manager sends RADIUS request to FortiAuthenticator

# Monitor RADIUS traffic on FortiAuth
tcpdump -i any -n 'udp port 1812 or udp port 1813'
# Expected: RADIUS Access-Request from Access Manager

# 4. FortiAuth sends push notification to user's mobile

# 5. User approves on FortiToken Mobile app

# 6. FortiAuth sends RADIUS Access-Accept to Access Manager

# 7. Access Manager issues session token to Bastion

# Verify in Bastion logs
tail -f /var/log/wallix/auth.log | grep -i radius
# Expected: RADIUS authentication successful
```

**Expected Results:**
- [ ] RADIUS communication between AM and FortiAuth functional
- [ ] Push notifications delivered within 5 seconds
- [ ] User can approve/deny within 60-second timeout
- [ ] Failed MFA attempts logged and blocked

#### Test 2.2.2: MFA Failover

```bash
# Test FortiAuth failover scenario

# 1. Stop primary FortiAuthenticator
ssh admin@fortiauth.company.com
systemctl stop fortiauthd

# 2. Attempt user login
# Expected: Access Manager fails over to secondary FortiAuth

# 3. Monitor failover in AM logs
ssh admin@accessmanager-1.company.com
tail -f /var/log/wallix/radius.log
# Expected: "Primary RADIUS server timeout, trying secondary"

# 4. Complete login with secondary FortiAuth
# Expected: Authentication successful

# 5. Restore primary FortiAuth
systemctl start fortiauthd

# 6. New logins should prefer primary
```

**Expected Results:**
- [ ] Automatic failover to secondary FortiAuth
- [ ] Users unaware of failover (transparent)
- [ ] Failover time < 10 seconds
- [ ] Automatic failback to primary after restoration

### 2.3 Session Brokering Testing

#### Test 2.3.1: Site Selection Algorithm

```bash
# Test intelligent site selection

# Scenario 1: All sites healthy, low load
# Expected: Route to geographically closest site

# Scenario 2: Site 1 at 90% capacity
# Expected: Route to Site 2 (next available)

# Scenario 3: Site 5 down
# Expected: Route to alternate site, Site 5 excluded

# Test routing API
curl -H "Authorization: Bearer YOUR_API_KEY" \
  https://accessmanager.company.com/api/v1/route \
  -d '{"user": "jsmith", "target": "prod-db-01.company.com"}'

# Expected response:
{
  "selected_site": "site1",
  "reason": "lowest_load",
  "site_load": 15,
  "alternatives": ["site5", "site4"]
}
```

**Expected Results:**
- [ ] Routing algorithm considers load, health, and proximity
- [ ] Overloaded sites deprioritized
- [ ] Failed sites excluded from routing
- [ ] User affinity respected (same site for returning users)

#### Test 2.3.2: Session Callbacks

```bash
# Test session lifecycle callbacks

# 1. User logs in via Access Manager
# 2. AM brokers session to Site 1

# Monitor callbacks on Bastion
tail -f /var/log/wallix/session-broker.log
# Expected: "session.created" callback received from AM

# 3. User terminates session

# Expected: "session.terminated" callback received

# 4. User transferred to different site (manual failover)

# Expected: "session.transferred" callback received

# Verify callback integrity
wabadmin session-broker verify-callback --signature [CALLBACK_SIG]
# Expected: Signature valid
```

**Expected Results:**
- [ ] Session lifecycle events trigger callbacks
- [ ] Callbacks authenticated with HMAC signature
- [ ] Bastion updates session state based on callbacks
- [ ] Failed callbacks retried automatically

---

## End-to-End User Workflow Testing

### 3.1 Native Access Workflow (SSH)

#### Test 3.1.1: SSH Proxy Session

```bash
# Complete SSH workflow via Bastion

# User: jsmith
# Target: prod-rhel-01.company.com (SSH)

# Step 1: User initiates SSH connection
ssh jsmith@bastion-site1.company.com

# Expected: Redirect to Access Manager SSO login page

# Step 2: User enters credentials
Username: jsmith
Password: [AD password]

# Expected: FortiToken push notification sent

# Step 3: User approves MFA on mobile device
# Expected: Authentication successful, redirect to Bastion

# Step 4: Bastion presents target selection menu
Available targets:
  1. prod-rhel-01.company.com (SSH)
  2. prod-rhel-02.company.com (SSH)
  3. dev-rhel-03.company.com (SSH)

Select target: 1

# Expected: SSH session established to prod-rhel-01.company.com

# Step 5: User executes commands on target
whoami
# Expected: jsmith

# Step 6: Session recorded
wabadmin sessions --active | grep jsmith
# Expected: Active SSH session to prod-rhel-01 listed

# Step 7: User exits session
exit

# Verify session recording saved
wabadmin recordings --user jsmith --last 1
# Expected: SSH session recording available
```

**Expected Results:**
- [ ] User authenticated via SSO + MFA
- [ ] Target selection menu displayed
- [ ] SSH session proxied through Bastion
- [ ] Commands executed successfully on target
- [ ] Session recorded with keystroke logging
- [ ] Session audit log generated

### 3.2 Native Access Workflow (RDP)

#### Test 3.2.1: RDP Proxy Session

```bash
# Complete RDP workflow via Bastion

# User: jsmith
# Target: prod-win-01.company.com (RDP)

# Step 1: User opens RDP client
mstsc /v:bastion-site1.company.com:3389

# Expected: Bastion RDP gateway prompt

# Step 2: User enters credentials
Username: jsmith@company.com
Password: [Redirects to Access Manager SSO]

# Expected: Web-based SSO login in RDP client

# Step 3: User completes SSO + MFA
# Expected: Authenticated, target selection screen

# Step 4: User selects target
Target: prod-win-01.company.com
Protocol: RDP

# Expected: RDP session established, Windows desktop displayed

# Step 5: User works on Windows target
# (Opens applications, executes commands)

# Verify session recording active
wabadmin sessions --active --protocol rdp | grep jsmith
# Expected: Active RDP session listed

# Step 6: User closes RDP window
# Expected: Session terminated gracefully

# Verify recording
wabadmin recordings --user jsmith --protocol rdp --last 1
# Expected: RDP session video recording available
```

**Expected Results:**
- [ ] RDP gateway authentication via SSO
- [ ] Full Windows desktop accessible
- [ ] Mouse and keyboard input captured
- [ ] Screen recording saved as video
- [ ] Session metadata (apps opened, files accessed) logged
- [ ] Graceful session termination

### 3.3 OT Access Workflow (RemoteApp)

#### Test 3.3.1: OT RemoteApp Session

```bash
# OT access via WALLIX RDS jump host

# User: ot-engineer
# Target: ot-workstation-01.company.com (via RDS RemoteApp)

# Step 1: User logs into Bastion web UI
https://bastion-site1.company.com

# Expected: SSO redirect to Access Manager

# Step 2: Complete SSO + MFA
# Expected: Bastion dashboard displayed

# Step 3: User selects OT target
Navigation: Resources > OT Systems > ot-workstation-01.company.com
Protocol: RDP (RemoteApp)

# Expected: RemoteApp connection initiated via RDS jump host

# Step 4: RDS brokers connection to OT target
# Expected: Published RemoteApp window displayed (NOT full desktop)

# Step 5: User works within RemoteApp
# (Performs OT-specific tasks in isolated application)

# Verify two-hop session recording
# Bastion → RDS → OT Target

wabadmin sessions --active --via-rds | grep ot-engineer
# Expected: Two sessions listed (Bastion→RDS, RDS→OT)

# Step 6: User closes RemoteApp
# Expected: Both sessions terminated

# Verify recording includes both hops
wabadmin recordings --user ot-engineer --last 1 --detailed
# Expected: Recording shows full path (Bastion→RDS→OT)
```

**Expected Results:**
- [ ] OT access via RDS jump host functional
- [ ] RemoteApp isolation enforced (no full desktop)
- [ ] Two-hop session path recorded
- [ ] OT target accessible only via RDS
- [ ] Direct Bastion→OT access blocked (enforced)

---

## Failover Testing

### 4.1 HAProxy Failover

#### Test 4.1.1: HAProxy Node Failure

```bash
# Test HAProxy high availability

# Initial state: HAProxy-1 primary, HAProxy-2 standby

# Step 1: Verify VIP on primary
ssh admin@haproxy1-site1.company.com
ip addr show | grep 10.10.1.100
# Expected: VIP present on HAProxy-1

# Step 2: Initiate user sessions
# 5 concurrent users accessing Bastion via VIP

# Step 3: Simulate HAProxy-1 failure
systemctl stop haproxy keepalived

# Step 4: Monitor failover
# On HAProxy-2:
ip addr show | grep 10.10.1.100
# Expected: VIP migrated to HAProxy-2 within 3 seconds

# Step 5: Verify user sessions
# Expected: Existing sessions continue uninterrupted
# New sessions routed via HAProxy-2

# Step 6: Measure failover time
# Expected: < 3 seconds (VRRP timeout)

# Step 7: Restore HAProxy-1
systemctl start haproxy keepalived

# Expected: HAProxy-1 reclaims VIP (manual fallback or auto)
```

**Expected Results:**
- [ ] VRRP failover within 3 seconds
- [ ] Active sessions continue without interruption
- [ ] New connections automatically routed to backup
- [ ] Failback to primary after restoration
- [ ] No data loss during failover

### 4.2 Bastion HA Failover

#### Test 4.2.1: Bastion Node Failure (Active-Active)

```bash
# Test Active-Active cluster failover

# Initial state: Both Bastion nodes active, load balanced

# Step 1: Verify cluster status
wabadmin cluster-status
# Expected: Node1 ACTIVE (50% load), Node2 ACTIVE (50% load)

# Step 2: Initiate user sessions
# 10 users connected, distributed across both nodes

# Step 3: Simulate Bastion Node 1 failure
ssh admin@bastion1-site1.company.com
systemctl stop wallix-bastion

# Step 4: Monitor failover via HAProxy
# HAProxy health check detects Node 1 down
# All traffic redirected to Node 2

echo "show servers state" | socat stdio /var/lib/haproxy/stats
# Expected: bastion1 DOWN, bastion2 UP

# Step 5: Verify user sessions
# Expected: Users on Node 1 experience brief interruption (< 5s)
#           Users on Node 2 unaffected
#           New sessions all routed to Node 2

# Step 6: Check Node 2 load
wabadmin sessions --count
# Expected: All sessions on Node 2 (100% load)

# Step 7: Restore Node 1
systemctl start wallix-bastion

# Expected: HAProxy detects Node 1 UP, resumes load balancing
```

**Expected Results:**
- [ ] HAProxy health check detects failure within 5 seconds
- [ ] Failed node removed from rotation
- [ ] Surviving node handles 100% load
- [ ] Session interruption < 5 seconds for affected users
- [ ] Automatic rebalancing after restoration

#### Test 4.2.2: Bastion Node Failure (Active-Passive)

```bash
# Test Active-Passive cluster failover

# Initial state: Node 1 PRIMARY (active), Node 2 STANDBY (passive)

# Step 1: Verify cluster status
wabadmin cluster-status
# Expected: Node1 PRIMARY (100% load), Node2 STANDBY (0% load)

# Step 2: Initiate user sessions
# 10 users connected to Node 1 via VIP

# Step 3: Simulate Node 1 failure
ssh admin@bastion1-site1.company.com
systemctl stop wallix-bastion pacemaker corosync

# Step 4: Monitor failover (30-60 seconds)
# Pacemaker detects failure, promotes Node 2 to PRIMARY

ssh admin@bastion2-site1.company.com
wabadmin cluster-status
# Expected: Node2 now PRIMARY

# Step 5: Verify VIP migration
ip addr show | grep 10.10.1.10
# Expected: VIP migrated to Node 2

# Step 6: Verify user sessions
# Expected: All sessions disconnected (30-60s outage)
#           Users must reconnect to Node 2

# Step 7: Restore Node 1
systemctl start wallix-bastion pacemaker corosync

# Expected: Node 1 becomes STANDBY, Node 2 remains PRIMARY
```

**Expected Results:**
- [ ] Pacemaker detects failure within 6 seconds
- [ ] Node 2 promoted to PRIMARY within 30-60 seconds
- [ ] VIP migrated to new PRIMARY
- [ ] Users disconnected, must reconnect
- [ ] Node 1 rejoins as STANDBY after restoration

### 4.3 Access Manager Failover

#### Test 4.3.1: AM Primary Failure

```bash
# Test Access Manager HA failover (coordinated with AM team)

# Initial state: AM1 PRIMARY, AM2 STANDBY

# Step 1: Initiate user logins
# 5 users authenticating via AM1

# Step 2: Simulate AM1 failure
ssh admin@accessmanager-1.company.com
systemctl stop wallix-access-manager

# Step 3: Monitor failover
# Bastion detects AM1 unreachable, fails over to AM2

tail -f /var/log/wallix/auth.log | grep "Access Manager"
# Expected: "AM1 unreachable, trying AM2"

# Step 4: Verify authentication via AM2
# Users in login process redirected to AM2
# Expected: Authentication completes successfully

# Step 5: Measure failover time
# Expected: < 10 seconds (DNS/connection timeout)

# Step 6: Restore AM1
systemctl start wallix-access-manager

# Expected: AM1 becomes PRIMARY again (manual failback or auto)
```

**Expected Results:**
- [ ] Automatic failover to AM2 within 10 seconds
- [ ] Users in-progress authentication complete via AM2
- [ ] New authentication requests routed to AM2
- [ ] Existing sessions unaffected
- [ ] Failback to AM1 after restoration

### 4.4 FortiAuthenticator Failover

#### Test 4.4.1: FortiAuth Primary Failure

```bash
# Test FortiAuth RADIUS failover (coordinated with Security team)

# Initial state: FortiAuth Primary, FortiAuth Secondary

# Step 1: Initiate MFA challenges
# 5 users completing MFA via primary FortiAuth

# Step 2: Simulate primary FortiAuth failure
ssh admin@fortiauth.company.com
systemctl stop fortiauthd

# Step 3: Monitor failover
# Access Manager detects RADIUS timeout, tries secondary

ssh admin@accessmanager-1.company.com
tail -f /var/log/wallix/radius.log
# Expected: "RADIUS timeout on primary, trying secondary"

# Step 4: Verify MFA via secondary
# Expected: Push notifications sent via secondary FortiAuth
#           Users complete MFA successfully

# Step 5: Measure failover time
# Expected: < 5 seconds (RADIUS timeout is 5s)

# Step 6: Restore primary FortiAuth
systemctl start fortiauthd

# Expected: New MFA requests routed to primary
```

**Expected Results:**
- [ ] RADIUS failover to secondary within 5 seconds
- [ ] MFA challenges continue uninterrupted
- [ ] Users unaware of failover
- [ ] Automatic failback to primary after restoration

---

## Performance Testing

### 5.1 Concurrent Session Load Testing

#### Test 5.1.1: Load Test - 50 Concurrent Sessions (Per Site)

```bash
# Load test with 50 concurrent SSH sessions

# Use load testing tool (JMeter, Locust, or custom script)

# Test script: concurrent-ssh-load.sh
#!/bin/bash
for i in {1..50}; do
  ssh -o StrictHostKeyChecking=no \
      jsmith$i@bastion-site1.company.com \
      "hostname; sleep 300; exit" &
done
wait

# Monitor system resources during test
ssh admin@bastion1-site1.company.com
htop

# Expected:
# - CPU usage < 60%
# - Memory usage < 70%
# - Load average < 4.0

# Check session count
wabadmin sessions --count
# Expected: 50 active sessions

# Measure session establishment time
wabadmin sessions --active --show-latency
# Expected: Average session start time < 2 seconds
```

**Expected Results:**
- [ ] 50 concurrent sessions established successfully
- [ ] CPU usage < 60% (headroom for burst)
- [ ] Memory usage < 70%
- [ ] Disk I/O < 80% (recording overhead)
- [ ] Network bandwidth < 500 Mbps
- [ ] Session establishment time < 2 seconds per session

#### Test 5.1.2: Load Test - 100 Concurrent Sessions (Active-Active)

```bash
# Load test with 100 concurrent sessions (Active-Active only)

# Expected load distribution:
# - Node 1: 50 sessions
# - Node 2: 50 sessions

# Step 1: Initiate 100 concurrent SSH sessions
for i in {1..100}; do
  ssh jsmith$i@bastion-site1.company.com \
      "hostname; sleep 600; exit" &
done

# Step 2: Monitor load distribution via HAProxy
echo "show servers state" | socat stdio /var/lib/haproxy/stats
# Expected: Approximately 50 sessions per backend

# Step 3: Monitor system resources on both nodes
ssh admin@bastion1-site1.company.com "uptime; free -h"
ssh admin@bastion2-site1.company.com "uptime; free -h"

# Expected:
# - Load average < 6.0 on each node
# - Memory usage < 80% on each node

# Step 4: Measure session recording disk I/O
iostat -x 5 10
# Expected: Disk write throughput < 200 MB/s
```

**Expected Results:**
- [ ] 100 sessions distributed evenly (50/50)
- [ ] Both nodes handling load without degradation
- [ ] No session establishment failures
- [ ] Recording storage keeping up with write rate
- [ ] Network throughput < 1 Gbps

### 5.2 Bandwidth Testing

#### Test 5.2.1: High-Throughput File Transfer

```bash
# Test large file transfer via Bastion (SCP)

# User: jsmith
# Source: Local workstation
# Target: prod-rhel-01.company.com via Bastion

# Step 1: Transfer 1 GB file
time scp -o ProxyJump=bastion-site1.company.com \
  testfile-1gb.bin jsmith@prod-rhel-01.company.com:/tmp/

# Expected: Transfer completes without errors
# Transfer time: < 2 minutes (> 8 MB/s sustained)

# Step 2: Monitor network bandwidth on Bastion
ssh admin@bastion1-site1.company.com
iftop -i eth0

# Expected: Peak bandwidth < 1 Gbps (network limit)

# Step 3: Verify file integrity
ssh jsmith@prod-rhel-01.company.com "md5sum /tmp/testfile-1gb.bin"
# Expected: MD5 checksum matches source file
```

**Expected Results:**
- [ ] Large file transfers complete successfully
- [ ] Sustained throughput > 8 MB/s (64 Mbps)
- [ ] No packet loss during transfer
- [ ] File integrity preserved (checksums match)
- [ ] Session recording captures file transfer metadata

### 5.3 Session Recording Performance

#### Test 5.3.1: Recording Storage I/O

```bash
# Test session recording under load

# Step 1: Initiate 20 concurrent RDP sessions (video recording)
# RDP sessions generate more recording data than SSH

# Step 2: Monitor recording storage disk I/O
ssh admin@bastion1-site1.company.com
iostat -x 5 10

# Expected:
# - Disk write throughput < 200 MB/s
# - Disk utilization < 85%
# - Write latency < 20ms

# Step 3: Check recording queue depth
wabadmin recordings --queue-status
# Expected: Queue depth < 100 (backlog manageable)

# Step 4: Verify recording files written
ls -lh /var/wab/recorded/
# Expected: Recording files present, sizes growing
```

**Expected Results:**
- [ ] Recording storage handles write load
- [ ] No recording buffer overruns
- [ ] Recording files written without corruption
- [ ] Disk I/O does not impact session performance

---

## Security Testing

### 6.1 Firewall Rules Validation

#### Test 6.1.1: Allowed Traffic

```bash
# Verify firewall rules allow required traffic

# Test 1: User → HAProxy VIP (HTTPS 443)
curl -k https://bastion-site1.company.com
# Expected: HTTP 200 (login page)

# Test 2: User → HAProxy VIP (SSH 22)
nc -zv bastion-site1.company.com 22
# Expected: Connection succeeded

# Test 3: Bastion → Access Manager (HTTPS 443)
ssh admin@bastion1-site1.company.com
curl -k https://accessmanager.company.com/health
# Expected: HTTP 200

# Test 4: Bastion → FortiAuth (RADIUS 1812/1813)
nc -uzv fortiauth.company.com 1812
nc -uzv fortiauth.company.com 1813
# Expected: Connection succeeded

# Test 5: Bastion → Target (SSH 22, RDP 3389)
ssh admin@bastion1-site1.company.com
nc -zv prod-rhel-01.company.com 22
nc -zv prod-win-01.company.com 3389
# Expected: Both connections succeeded
```

**Expected Results:**
- [ ] All allowed traffic passes through firewall
- [ ] No connection timeouts for permitted flows
- [ ] Latency within acceptable range (< 50ms)

#### Test 6.1.2: Blocked Traffic

```bash
# Verify firewall rules block unauthorized traffic

# Test 1: Direct Bastion-to-Bastion (Site 1 → Site 2) should FAIL
ssh admin@bastion1-site1.company.com
ping -c 3 bastion1-site2.company.com
# Expected: Destination Host Unreachable (BLOCKED)

# Test 2: External access to Bastion HA cluster ports should FAIL
nc -zv bastion1-site1.company.com 3306
# Expected: Connection refused (MariaDB port blocked)

nc -zv bastion1-site1.company.com 2224
# Expected: Connection refused (Pacemaker PCSD blocked)

# Test 3: Bastion → Internet (unless explicit proxy) should FAIL
ssh admin@bastion1-site1.company.com
curl http://www.google.com
# Expected: Connection timeout (no internet access)

# Test 4: User → Bastion Node IP (not via HAProxy VIP) may be BLOCKED
curl -k https://10.10.1.11:443
# Expected: Connection timeout or refused (depending on policy)
```

**Expected Results:**
- [ ] Inter-site Bastion traffic blocked
- [ ] HA cluster ports not accessible externally
- [ ] Internet access blocked (unless approved)
- [ ] Direct node access restricted (VIP mandatory)

### 6.2 Authentication Security Testing

#### Test 6.2.1: Brute Force Protection

```bash
# Test account lockout after failed login attempts

# Step 1: Attempt 5 failed logins for user "jsmith"
for i in {1..5}; do
  curl -X POST https://bastion-site1.company.com/api/login \
    -d '{"username":"jsmith","password":"wrongpassword"}'
done

# Expected: After 5 attempts, account locked temporarily

# Step 2: Attempt valid login
curl -X POST https://bastion-site1.company.com/api/login \
  -d '{"username":"jsmith","password":"correctpassword"}'

# Expected: HTTP 403 Forbidden - Account locked

# Step 3: Verify lockout logged
wabadmin audit --event "account.locked" | grep jsmith
# Expected: Lockout event logged

# Step 4: Wait for lockout expiration (e.g., 15 minutes)
# OR manually unlock account:
wabadmin user unlock --username jsmith

# Step 5: Retry valid login
# Expected: HTTP 200 OK - Login successful
```

**Expected Results:**
- [ ] Account locked after 5 failed attempts
- [ ] Lockout duration configurable (default 15 minutes)
- [ ] Lockout events logged in audit trail
- [ ] Admin can manually unlock accounts

#### Test 6.2.2: Session Timeout

```bash
# Test session inactivity timeout

# Step 1: Login to Bastion web UI
# Step 2: Remain idle for configured timeout (e.g., 30 minutes)
# Step 3: Attempt action after timeout

# Expected: Session expired, redirect to login page

# Verify in logs
wabadmin audit --event "session.timeout" | tail -10
# Expected: Session timeout logged

# Test SSH session timeout
ssh jsmith@bastion-site1.company.com
# Remain idle for 30 minutes

# Expected: SSH session terminated with message:
# "Connection closed due to inactivity"
```

**Expected Results:**
- [ ] Web UI sessions timeout after inactivity
- [ ] SSH sessions timeout after inactivity
- [ ] RDP sessions timeout after inactivity
- [ ] Timeout configurable per protocol

### 6.3 Encryption Validation

#### Test 6.3.1: TLS/SSL Configuration

```bash
# Test TLS configuration on Bastion

# Step 1: Check TLS version support
nmap --script ssl-enum-ciphers -p 443 bastion-site1.company.com

# Expected:
# - TLS 1.2: Supported
# - TLS 1.3: Supported
# - TLS 1.0/1.1: NOT supported (deprecated)

# Step 2: Check cipher suites
openssl s_client -connect bastion-site1.company.com:443 -tls1_2
# Expected: Strong ciphers only (AES-GCM, ChaCha20)

# Step 3: Test for weak ciphers (should fail)
openssl s_client -connect bastion-site1.company.com:443 -cipher 'DES-CBC3-SHA'
# Expected: Connection refused (weak cipher not supported)

# Step 4: Check certificate configuration
echo | openssl s_client -connect bastion-site1.company.com:443 -showcerts
# Expected:
# - Certificate valid
# - Certificate chain complete
# - No expired certificates
# - Strong signature algorithm (SHA256 or higher)
```

**Expected Results:**
- [ ] TLS 1.2+ only (TLS 1.0/1.1 disabled)
- [ ] Strong cipher suites only
- [ ] Valid certificate with complete chain
- [ ] Perfect Forward Secrecy (PFS) enabled

#### Test 6.3.2: Database Encryption

```bash
# Test MariaDB replication encryption

# Step 1: Check MariaDB TLS configuration
ssh admin@bastion1-site1.company.com
mysql -e "SHOW VARIABLES LIKE 'have_ssl';"
# Expected: have_ssl = YES

# Step 2: Verify replication uses TLS
mysql -e "SHOW SLAVE STATUS\G" | grep Master_SSL
# Expected: Master_SSL_Allowed: Yes

# Step 3: Test database connection encryption
mysql --ssl-mode=REQUIRED -e "STATUS" | grep SSL
# Expected: SSL: Cipher in use is [strong cipher]

# Step 4: Check data-at-rest encryption (if configured)
mysql -e "SHOW VARIABLES LIKE 'innodb_encryption%';"
# Expected: innodb_encryption = ON (if implemented)
```

**Expected Results:**
- [ ] MariaDB replication encrypted (TLS)
- [ ] Database connections require TLS
- [ ] Strong cipher suites for database encryption
- [ ] Data-at-rest encryption enabled (optional)

---

## Acceptance Criteria

### 7.1 Functional Acceptance Criteria

| ID | Criteria | Status | Evidence |
|----|----------|--------|----------|
| **F-01** | All 5 Bastion sites accessible via HAProxy VIP | [ ] Pass | Health check results |
| **F-02** | SSO authentication functional via Access Manager | [ ] Pass | Test login logs |
| **F-03** | MFA challenges delivered via FortiAuthenticator | [ ] Pass | MFA test results |
| **F-04** | Session brokering routes users to optimal site | [ ] Pass | Routing decision logs |
| **F-05** | SSH proxy sessions established successfully | [ ] Pass | 10 test sessions |
| **F-06** | RDP proxy sessions established successfully | [ ] Pass | 10 test sessions |
| **F-07** | OT access via RDS RemoteApp functional | [ ] Pass | 5 test sessions |
| **F-08** | Credential vault stores and retrieves passwords | [ ] Pass | Credential tests |
| **F-09** | Session recording captures all session activity | [ ] Pass | Recording review |
| **F-10** | Audit logs generated for all user actions | [ ] Pass | Audit log export |

### 7.2 Performance Acceptance Criteria

| ID | Criteria | Target | Actual | Status |
|----|----------|--------|--------|--------|
| **P-01** | Session establishment time | < 2 seconds | _____ s | [ ] Pass |
| **P-02** | HAProxy failover time | < 3 seconds | _____ s | [ ] Pass |
| **P-03** | Bastion HA failover time (Active-Active) | < 5 seconds | _____ s | [ ] Pass |
| **P-04** | Bastion HA failover time (Active-Passive) | < 60 seconds | _____ s | [ ] Pass |
| **P-05** | Concurrent sessions per site | ≥ 100 | _____ | [ ] Pass |
| **P-06** | Session recording disk I/O | < 200 MB/s | _____ MB/s | [ ] Pass |
| **P-07** | CPU utilization (50 sessions) | < 60% | _____ % | [ ] Pass |
| **P-08** | Memory utilization (50 sessions) | < 70% | _____ % | [ ] Pass |
| **P-09** | Network throughput (file transfer) | > 8 MB/s | _____ MB/s | [ ] Pass |
| **P-10** | MPLS latency (Bastion ↔ AM) | < 50 ms | _____ ms | [ ] Pass |

### 7.3 Security Acceptance Criteria

| ID | Criteria | Status | Evidence |
|----|----------|--------|----------|
| **S-01** | TLS 1.2+ only (TLS 1.0/1.1 disabled) | [ ] Pass | nmap scan results |
| **S-02** | Strong cipher suites enforced | [ ] Pass | SSL Labs report |
| **S-03** | Account lockout after failed logins | [ ] Pass | Brute force test |
| **S-04** | Session timeout enforced | [ ] Pass | Inactivity test |
| **S-05** | Inter-site Bastion traffic blocked | [ ] Pass | Connectivity test |
| **S-06** | HA cluster ports not externally accessible | [ ] Pass | Port scan results |
| **S-07** | MariaDB replication encrypted | [ ] Pass | MySQL status check |
| **S-08** | All user actions audited | [ ] Pass | Audit log review |
| **S-09** | Session recordings encrypted at rest | [ ] Pass | Storage encryption check |
| **S-10** | MFA required for all user authentication | [ ] Pass | Authentication tests |

### 7.4 Availability Acceptance Criteria

| ID | Criteria | Target | Status |
|----|----------|--------|--------|
| **A-01** | HAProxy HA pair functional | 99.99% | [ ] Pass |
| **A-02** | Bastion HA cluster functional | 99.9%+ | [ ] Pass |
| **A-03** | Access Manager HA functional | 99.99% | [ ] Pass |
| **A-04** | FortiAuth failover functional | < 5s | [ ] Pass |
| **A-05** | Session data replicated across nodes | Real-time | [ ] Pass |
| **A-06** | Automatic failover tested | Working | [ ] Pass |
| **A-07** | Automatic failback tested (optional) | Working | [ ] Pass |

---

## Sign-Off Checklist

### 9.1 Pre-Production Sign-Off

#### Technical Sign-Off

| Area | Responsible | Status | Date | Signature |
|------|-------------|--------|------|-----------|
| **Component Testing** | Infrastructure Team | [ ] Complete | ______ | __________ |
| **Integration Testing** | Integration Team | [ ] Complete | ______ | __________ |
| **Performance Testing** | Performance Team | [ ] Complete | ______ | __________ |
| **Security Testing** | Security Team | [ ] Complete | ______ | __________ |
| **Failover Testing** | Operations Team | [ ] Complete | ______ | __________ |
| **Documentation Review** | Documentation Lead | [ ] Complete | ______ | __________ |

#### Stakeholder Sign-Off

| Stakeholder | Role | Status | Date | Signature |
|-------------|------|--------|------|-----------|
| **Project Manager** | Overall delivery | [ ] Approved | ______ | __________ |
| **Infrastructure Lead** | Infrastructure | [ ] Approved | ______ | __________ |
| **Security Lead** | Security compliance | [ ] Approved | ______ | __________ |
| **Operations Manager** | Operational readiness | [ ] Approved | ______ | __________ |
| **Business Owner** | Business acceptance | [ ] Approved | ______ | __________ |

### 9.2 Production Go-Live Checklist

#### Pre-Go-Live

- [ ] All testing phases completed successfully
- [ ] All acceptance criteria met
- [ ] Known issues documented and mitigated
- [ ] Operations team trained on new system
- [ ] Runbooks created and reviewed
- [ ] Monitoring dashboards configured
- [ ] Alerting rules configured and tested
- [ ] Backup and recovery tested
- [ ] Disaster recovery plan documented
- [ ] Communication plan for users created
- [ ] Rollback plan documented and tested
- [ ] Change management approval obtained

#### Go-Live Day

- [ ] Final configuration backup taken
- [ ] Maintenance window scheduled and communicated
- [ ] War room established with key personnel
- [ ] Production cutover performed
- [ ] Post-cutover smoke tests completed
- [ ] User acceptance testing (UAT) completed
- [ ] Performance monitoring active
- [ ] On-call team briefed and ready

#### Post-Go-Live (First 24 Hours)

- [ ] System health monitoring active
- [ ] User issues tracked and resolved
- [ ] Performance metrics within targets
- [ ] No critical issues reported
- [ ] Lessons learned documented

### 9.3 Conditional Acceptance

If testing reveals issues:

1. **Critical Issues** (must be resolved before go-live):
   - Authentication failures
   - Data loss scenarios
   - Security vulnerabilities
   - System instability

2. **Major Issues** (must have mitigation plan):
   - Performance degradation
   - Non-critical feature failures
   - Failover delays exceeding targets

3. **Minor Issues** (can be resolved post-go-live):
   - UI/UX improvements
   - Non-essential feature enhancements
   - Documentation updates

---

## Next Steps

After successful testing and validation:

1. **Production Cutover**: Proceed to [HOWTO.md](HOWTO.md) Phase 9 (Go-Live)
2. **Operations Handoff**: Transfer to operations team with runbooks
3. **Monitoring Setup**: Configure Prometheus, Grafana dashboards
4. **User Training**: Conduct end-user training sessions
5. **Post-Go-Live Support**: 24/7 support for first week

---

## Related Documentation

- [11 - Architecture Diagrams](11-architecture-diagrams.md) - Network topology and port reference
- [01 - Network Design](01-network-design.md) - MPLS connectivity and firewall rules
- [03 - Access Manager Integration](03-access-manager-integration.md) - SSO, MFA, session brokering
- [HOWTO.md](HOWTO.md) - Main installation guide

---

**Document Version**: 1.0
**Last Updated**: February 2026
**Validated By**: QA Team
**Approval Status**: Ready for Production Validation
