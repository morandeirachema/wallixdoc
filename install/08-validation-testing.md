# 08 - Validation and Testing

## Table of Contents

1. [Pre-Flight Checklist](#pre-flight-checklist)
2. [Functional Testing](#functional-testing)
3. [HA Failover Testing](#ha-failover-testing)
4. [Multi-Site Sync Testing](#multi-site-sync-testing)
5. [OT Protocol Testing](#ot-protocol-testing)
6. [Security Validation](#security-validation)
7. [Performance Testing](#performance-testing)
8. [Go-Live Checklist](#go-live-checklist)

---

## Pre-Flight Checklist

### System Health Verification

```bash
# Run comprehensive health check on all sites
# Site A
ssh admin@wallix.site-a.company.com "wab-admin health-check --verbose"

# Site B
ssh admin@wallix.site-b.company.com "wab-admin health-check --verbose"

# Site C
ssh admin@wallix.site-c.company.com "wab-admin health-check --verbose"
```

### Expected Health Check Output

```
+===============================================================================+
|                   SYSTEM HEALTH CHECK                                        |
+===============================================================================+

  CORE SERVICES
  =============
  [OK] wabengine                    running (pid 1234, uptime 5d 3h)
  [OK] wab-webui                    running (pid 1235, uptime 5d 3h)
  [OK] mariadb                   running (pid 1236, uptime 5d 3h)
  [OK] nginx                        running (pid 1237, uptime 5d 3h)

  DATABASE
  ========
  [OK] Connection                   established
  [OK] Replication                  streaming (lag: 0 bytes)
  [OK] Disk Space                   45% used (500GB free)

  LICENSING
  =========
  [OK] License Status               valid
  [OK] License Expiry               2027-01-15 (353 days remaining)
  [OK] Concurrent Users             45/100 (55 available)

  NETWORK
  =======
  [OK] HTTPS (443)                  listening
  [OK] SSH Proxy (22)               listening
  [OK] RDP Proxy (3389)             listening
  [OK] VNC Proxy (5900)             listening

  CERTIFICATES
  ============
  [OK] SSL Certificate              valid (expires 2027-01-01)
  [OK] CA Chain                     complete

  HIGH AVAILABILITY
  =================
  [OK] Cluster Status               active
  [OK] Node: wallix-a1-hb           online (primary)
  [OK] Node: wallix-a2-hb           online (standby)
  [OK] Virtual IP                   10.100.1.100 (active on wallix-a1-hb)

  MULTI-SITE
  ==========
  [OK] Role                         primary
  [OK] Site B Connection            online (last sync: 2 min ago)
  [OK] Site C Connection            online (last sync: 1 hour ago)

  STORAGE
  =======
  [OK] Recording Storage            mounted (/var/wab/recorded)
  [OK] Recording Space              35% used (6.5TB free)

  Overall Status: HEALTHY

+===============================================================================+
```

---

## Functional Testing

### Authentication Tests

```bash
# Test 1: Local authentication
echo "Test 1: Local Authentication"
wab-admin auth-test --user admin --method local
# Expected: Authentication successful

# Test 2: LDAP authentication
echo "Test 2: LDAP Authentication"
wab-admin auth-test --user jsmith --method ldap
# Expected: Authentication successful

# Test 3: OIDC authentication (12.x)
echo "Test 3: OIDC Authentication"
wab-admin auth-test --user oidc-user --method oidc
# Expected: Authentication successful (redirect flow)

# Test 4: MFA authentication
echo "Test 4: MFA Authentication"
wab-admin auth-test --user admin --method local --mfa-code 123456
# Expected: MFA validated

# Test 5: Failed authentication (lockout)
echo "Test 5: Lockout Test"
for i in {1..6}; do
    wab-admin auth-test --user testuser --password wrongpassword 2>/dev/null
done
wab-admin user-status testuser
# Expected: Account locked after 5 attempts
```

### Session Proxy Tests

```bash
# Test SSH Proxy
echo "Test: SSH Proxy"
ssh -o ProxyCommand="ssh -W %h:%p admin@wallix.site-a.company.com" \
    -o StrictHostKeyChecking=no \
    root@scada-server -c "hostname && date"
# Expected: Connection successful, hostname and date displayed

# Test RDP Proxy (using xfreerdp on Linux)
echo "Test: RDP Proxy"
xfreerdp /v:wallix.site-a.company.com /u:admin@hmi-station-01 /p:password /cert:ignore
# Expected: RDP session established

# Test VNC Proxy
echo "Test: VNC Proxy"
vncviewer wallix.site-a.company.com::5900
# Authenticate and connect to target VNC
# Expected: VNC session displayed
```

### Session Recording Verification

```bash
# Verify session was recorded
wab-admin session-list --last 5

# Expected output:
# Session ID          | User      | Target          | Protocol | Start Time          | Duration
# SES-2026-001-ABC123 | jsmith    | scada-server    | SSH      | 2026-01-27 10:00:00 | 00:15:30
# SES-2026-001-ABC124 | admin     | hmi-station-01  | RDP      | 2026-01-27 10:05:00 | 00:10:15

# Playback recording
wab-admin session-playback SES-2026-001-ABC123 --output /tmp/session-playback.mp4
# Expected: Video file created successfully
```

---

## HA Failover Testing

### Planned Failover Test

```bash
# Step 1: Document current state
pcs status
# Note which node is primary

# Step 2: Initiate planned failover
pcs node standby wallix-a1-hb

# Step 3: Verify failover completed
sleep 30
pcs status
# Expected: wallix-a2-hb is now primary, VIP moved

# Step 4: Test services on new primary
curl -k https://10.100.1.100/api/status
ssh admin@10.100.1.100 "wab-admin health-check"
# Expected: All services responding

# Step 5: Restore original node
pcs node unstandby wallix-a1-hb
sleep 30
pcs status
# Expected: Both nodes online

# Step 6: Verify no session interruption
wab-admin session-list --active
# Expected: Active sessions continued without interruption
```

### Unplanned Failover Test

```bash
# WARNING: This test will abruptly stop the primary node
# Only perform during maintenance window

# Step 1: Start a test session (from another terminal)
ssh -o ProxyCommand="ssh -W %h:%p admin@wallix.site-a.company.com" testuser@target

# Step 2: Simulate node failure (on primary node)
echo b > /proc/sysrq-trigger  # Force reboot

# Step 3: Monitor failover (from management workstation)
watch -n 1 "ping -c 1 10.100.1.100 && echo 'VIP UP' || echo 'VIP DOWN'"
# Expected: Brief outage (< 30 seconds), then VIP responds

# Step 4: Verify test session recovered
# Session should have terminated but new sessions possible

# Step 5: Verify data integrity
wab-admin health-check
wab-admin session-list --last 5
```

---

## Multi-Site Sync Testing

### Sync Verification

```bash
# Step 1: Create test user on Site A
wab-admin user-create \
    --username "sync-test-user" \
    --display-name "Sync Test User" \
    --email "synctest@company.com" \
    --groups "test-group"

# Step 2: Wait for sync to Site B (5 minutes)
sleep 300

# Step 3: Verify user exists on Site B
ssh admin@wallix.site-b.company.com "wab-admin user-show sync-test-user"
# Expected: User details displayed

# Step 4: Wait for sync to Site C (1 hour or force sync)
ssh admin@wallix.site-c.company.com "wab-admin multisite-sync --force"

# Step 5: Verify user exists on Site C
ssh admin@wallix.site-c.company.com "wab-admin user-show sync-test-user"
# Expected: User details displayed

# Step 6: Clean up
wab-admin user-delete sync-test-user
```

### Offline Operation Test (Site C)

```bash
# Step 1: Cache credentials on Site C
ssh admin@wallix.site-c.company.com "wab-admin auth-cache --user ot-operator1"

# Step 2: Simulate network disconnection (on Site C firewall)
# Block traffic to Site A
iptables -A OUTPUT -d 10.100.1.100 -j DROP

# Step 3: Verify offline authentication works
ssh admin@wallix.site-c.company.com "wab-admin auth-test --user ot-operator1 --cached"
# Expected: Authentication successful (from cache)

# Step 4: Verify session proxy works
ssh -o ProxyCommand="ssh -W %h:%p ot-operator1@wallix.site-c.company.com" operator@plc-c-line1
# Expected: Connection successful using cached credentials

# Step 5: Restore network
iptables -D OUTPUT -d 10.100.1.100 -j DROP

# Step 6: Verify sync resumes
sleep 60
ssh admin@wallix.site-c.company.com "wab-admin multisite-status"
# Expected: Connection restored, sync resumed
```

---

## OT Protocol Testing

### Modbus Testing

```bash
# Test Modbus tunnel
echo "Test: Modbus TCP Tunnel"

# Establish tunnel
ssh -L 10502:10.100.40.10:502 admin@wallix.site-a.company.com -N &
TUNNEL_PID=$!
sleep 2

# Test Modbus connection (using modbus-cli or similar)
modbus read --host localhost --port 10502 --address 0 --count 10
# Expected: Register values displayed

# Verify session recorded
kill $TUNNEL_PID
wab-admin session-list --last 1 --protocol modbus
# Expected: Modbus session logged

# Check audit log for Modbus operations
wab-admin audit-search --protocol modbus --last 1h
# Expected: Read operations logged
```

### OPC UA Testing

```bash
# Test OPC UA tunnel
echo "Test: OPC UA Tunnel"

# Establish tunnel
ssh -L 14840:10.100.20.20:4840 admin@wallix.site-a.company.com -N &
TUNNEL_PID=$!
sleep 2

# Test OPC UA connection (using opcua-client or UaExpert)
# Connect to opc.tcp://localhost:14840
# Browse nodes and read values

# Verify session recorded
kill $TUNNEL_PID
wab-admin session-list --last 1 --protocol opcua
# Expected: OPC UA session logged
```

### Protocol Security Tests

```bash
# Test blocked operations (Modbus write to restricted device)
wab-admin audit-search --protocol modbus --operation write --status blocked --last 24h
# Expected: Any blocked write attempts logged

# Test protocol-level access control
wab-admin authorization-check \
    --user operator \
    --device PLC-Line1-Main \
    --protocol modbus \
    --operation write
# Expected: Access denied (if operator is read-only)
```

---

## Security Validation

### Vulnerability Scan

```bash
# Run internal security scan
wab-admin security-scan --type full

# Expected output:
# Security Scan Results
# =====================
# [PASS] No default credentials detected
# [PASS] Strong password policy enforced
# [PASS] MFA enabled for administrators
# [PASS] SSH using approved ciphers only
# [PASS] TLS 1.2+ enforced
# [PASS] No known vulnerabilities in installed packages
# [PASS] Disk encryption enabled
# [PASS] Audit logging enabled
# [WARN] Consider enabling STONITH for HA cluster
#
# Overall: PASS (1 warning)
```

### Penetration Test Checklist

```
+===============================================================================+
|                   SECURITY VALIDATION CHECKLIST                              |
+===============================================================================+

  AUTHENTICATION SECURITY
  =======================
  [ ] Brute force protection working (lockout after 5 attempts)
  [ ] Password complexity enforced
  [ ] MFA cannot be bypassed
  [ ] Session timeout enforced
  [ ] Concurrent session limit enforced

  NETWORK SECURITY
  ================
  [ ] Only required ports open (22, 443, 3389, 5900)
  [ ] Direct OT access blocked (must go through WALLIX)
  [ ] IP whitelist enforced for admin access
  [ ] Rate limiting prevents DoS

  PROTOCOL SECURITY
  =================
  [ ] SSH using strong ciphers only
  [ ] TLS 1.2+ enforced (no SSLv3, TLS 1.0, 1.1)
  [ ] Certificate validation enabled
  [ ] Session recording cannot be disabled by users

  DATA PROTECTION
  ===============
  [ ] Disk encryption enabled (LUKS)
  [ ] Database encrypted at rest
  [ ] Credentials encrypted in vault
  [ ] Session recordings encrypted

  AUDIT & MONITORING
  ==================
  [ ] All actions logged
  [ ] Logs forwarded to SIEM
  [ ] Tamper-evident logs
  [ ] Real-time alerting configured

+===============================================================================+
```

---

## Performance Testing

### Load Testing

```bash
# Test concurrent SSH sessions
echo "Test: 50 concurrent SSH sessions"
for i in {1..50}; do
    ssh -o ProxyCommand="ssh -W %h:%p loadtest$i@wallix.site-a.company.com" \
        testuser@target-server -c "sleep 30" &
done
wait

# Verify performance
wab-admin performance-stats

# Expected:
# Active Sessions: 50
# CPU Usage: < 60%
# Memory Usage: < 70%
# Response Time: < 100ms
```

### Capacity Verification

```bash
# Check license capacity
wab-admin license-status

# Expected:
# License Type: Enterprise
# Max Concurrent Users: 100
# Current Usage: 50
# Max Targets: 1000
# Current Targets: 750
```

---

## Go-Live Checklist

```
+===============================================================================+
|                   GO-LIVE CHECKLIST                                          |
+===============================================================================+

  INFRASTRUCTURE
  ==============
  [ ] All sites installed and configured
  [ ] HA clusters operational (Site A, Site B)
  [ ] Multi-site sync verified
  [ ] Backup procedures tested
  [ ] Disaster recovery plan documented

  SECURITY
  ========
  [ ] Security hardening applied
  [ ] SSL certificates installed (production)
  [ ] MFA enabled for all administrators
  [ ] Security scan passed
  [ ] IEC 62443 compliance verified

  INTEGRATION
  ===========
  [ ] LDAP/AD integration tested
  [ ] OIDC integration tested (if applicable)
  [ ] SIEM integration verified
  [ ] Email alerts configured and tested
  [ ] All OT devices registered

  USERS & ACCESS
  ==============
  [ ] User groups configured
  [ ] Authorization policies defined
  [ ] Emergency access procedures documented
  [ ] User training completed

  DOCUMENTATION
  =============
  [ ] Runbook created
  [ ] Network diagrams updated
  [ ] Password vault populated
  [ ] Support contacts documented

  SIGN-OFF
  ========
  [ ] IT Security approval
  [ ] OT Manager approval
  [ ] Compliance Officer approval
  [ ] Change Management approval

+===============================================================================+

  FINAL VERIFICATION
  ==================

  Run final validation:
  $ wab-admin validate-all --verbose

  Expected output:
  ✓ System health verified
  ✓ Cluster status verified
  ✓ Multi-site sync verified
  ✓ Authentication verified
  ✓ Session proxy verified
  ✓ Recording verified
  ✓ Security policies verified
  ✓ Audit logging verified

  Status: READY FOR PRODUCTION

+===============================================================================+
```

---

## Post-Go-Live Monitoring

```bash
# Set up ongoing monitoring
wab-admin monitor-start

# Schedule daily health reports
wab-admin schedule-report \
    --type health \
    --frequency daily \
    --time "06:00" \
    --recipients "ot-team@company.com"

# Schedule weekly compliance reports
wab-admin schedule-report \
    --type compliance \
    --frequency weekly \
    --day Monday \
    --time "08:00" \
    --recipients "security@company.com,compliance@company.com"
```

---

**Installation Complete!**

For ongoing operations, refer to:
- [../docs/12-troubleshooting/README.md](../docs/12-troubleshooting/README.md) - Troubleshooting Guide
- [../docs/10-high-availability/README.md](../docs/10-high-availability/README.md) - HA Operations
- [../docs/29-upgrade-guide/README.md](../docs/29-upgrade-guide/README.md) - Upgrade Procedures
