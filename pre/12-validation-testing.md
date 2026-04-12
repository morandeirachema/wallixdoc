# 12 - Validation Testing

## Comprehensive Test Suite for Pre-Production Lab

This guide covers all validation tests to verify the WALLIX Bastion lab environment is working correctly.

> **Lab scope**: Single Bastion node (no HA cluster tests). HAProxy VIP failover IS tested (2-node HAProxy). FortiAuth is TOTP only (no Push tests). AD is in Cyber VLAN (10.10.1.60) — inter-VLAN connectivity from DMZ to Cyber via Fortigate must be validated.

---

## Test Categories Overview

```
+===============================================================================+
|                        VALIDATION TEST CATEGORIES                             |
+===============================================================================+

  1. INFRASTRUCTURE TESTS            2. WALLIX Bastion FUNCTIONAL TESTS
  =======================            ==========================
  - VM connectivity                  - Authentication (local/LDAP)
  - DNS resolution                   - Session management
  - Network segmentation             - Password checkout
  - Storage verification             - Recording playback

  3. HAPROXY VIP TESTS               4. INTEGRATION TESTS
  ====================               ====================
  - HAProxy VIP failover             - AD group mapping
  - Keepalived VRRP                  - SIEM log forwarding
  - Backend health check             - Metrics collection
  - Cyber VLAN connectivity          - Alert triggering

  5. SECURITY TESTS                  6. PERFORMANCE TESTS
  =================                  ====================
  - Certificate validation           - Concurrent sessions
  - TLS configuration                - Authentication throughput
  - Access controls                  - API response times
  - Audit logging                    - Database performance

+===============================================================================+
```

---

## Test 1: Infrastructure Validation

### 1.1 VM Connectivity

```bash
#!/bin/bash
# Run from any management workstation

echo "=== Infrastructure Connectivity Tests ==="

# Define hosts (all 12 lab VMs)
declare -A HOSTS=(
    # Management VLAN 100
    ["siem-lab.lab.local"]="10.10.0.10"
    ["monitor-lab.lab.local"]="10.10.0.20"
    # DMZ VLAN 110
    ["haproxy-1.lab.local"]="10.10.1.5"
    ["haproxy-2.lab.local"]="10.10.1.6"
    ["wallix-bastion.lab.local"]="10.10.1.11"
    ["wallix-rds.lab.local"]="10.10.1.30"
    # Cyber VLAN 120
    ["fortiauth.lab.local"]="10.10.1.50"
    ["dc-lab.lab.local"]="10.10.1.60"
    # Targets VLAN 130
    ["win-srv-01.lab.local"]="10.10.2.10"
    ["win-srv-02.lab.local"]="10.10.2.11"
    ["rhel10-srv.lab.local"]="10.10.2.20"
    ["rhel9-srv.lab.local"]="10.10.2.21"
)

for host in "${!HOSTS[@]}"; do
    ip="${HOSTS[$host]}"
    if ping -c 1 -W 2 "$ip" &>/dev/null; then
        echo "[PASS] $host ($ip) - Reachable"
    else
        echo "[FAIL] $host ($ip) - Unreachable"
    fi
done
```

### 1.2 DNS Resolution

```bash
echo "=== DNS Resolution Tests ==="

for host in siem-lab monitor-lab haproxy-1 haproxy-2 wallix-bastion wallix-rds fortiauth dc-lab; do
    result=$(nslookup "${host}.lab.local" 2>/dev/null | grep "Address" | tail -1)
    if [ -n "$result" ]; then
        echo "[PASS] ${host}.lab.local resolves"
    else
        echo "[FAIL] ${host}.lab.local does not resolve"
    fi
done
```

### 1.3 Port Connectivity

```bash
echo "=== Service Port Tests ==="

# WALLIX Bastion services
nc -zv wallix.lab.local 443 2>&1 | grep -q "succeeded" && echo "[PASS] WALLIX Bastion HTTPS" || echo "[FAIL] WALLIX Bastion HTTPS"
nc -zv wallix.lab.local 22 2>&1 | grep -q "succeeded" && echo "[PASS] WALLIX Bastion SSH" || echo "[FAIL] WALLIX Bastion SSH"

# AD services (Cyber VLAN 120 — inter-VLAN from DMZ via Fortigate)
nc -zv 10.10.1.60 636 2>&1 | grep -q "succeeded" && echo "[PASS] LDAPS (dc-lab)" || echo "[FAIL] LDAPS (dc-lab)"
nc -zv 10.10.1.60 389 2>&1 | grep -q "succeeded" && echo "[PASS] LDAP (dc-lab)" || echo "[FAIL] LDAP (dc-lab)"
nc -zv 10.10.1.60 88  2>&1 | grep -q "succeeded" && echo "[PASS] Kerberos (dc-lab)" || echo "[FAIL] Kerberos (dc-lab)"

# FortiAuth RADIUS (Cyber VLAN 120 — inter-VLAN from DMZ via Fortigate)
nc -zu 10.10.1.50 1812 2>&1 | grep -q "succeeded" && echo "[PASS] RADIUS (fortiauth)" || echo "[FAIL] RADIUS (fortiauth)"

# SIEM (Management VLAN 100)
nc -zv 10.10.0.10 514 2>&1 | grep -q "succeeded" && echo "[PASS] Syslog (siem-lab)" || echo "[FAIL] Syslog (siem-lab)"

# Monitoring (Management VLAN 100)
nc -zv 10.10.0.20 9090 2>&1 | grep -q "succeeded" && echo "[PASS] Prometheus (monitor-lab)" || echo "[FAIL] Prometheus (monitor-lab)"
nc -zv 10.10.0.20 3000 2>&1 | grep -q "succeeded" && echo "[PASS] Grafana (monitor-lab)" || echo "[FAIL] Grafana (monitor-lab)"
```

---

## Test 2: WALLIX Bastion Functional Tests

### 2.1 Local Admin Authentication

```bash
echo "=== Local Admin Authentication Test ==="

# Test via API
response=$(curl -sk -X POST "https://wallix.lab.local/api/auth" \
    -H "Content-Type: application/json" \
    -d '{"user": "admin", "password": "Pam4otAdmin123!"}')

if echo "$response" | grep -q "token"; then
    echo "[PASS] Local admin authentication successful"
    TOKEN=$(echo "$response" | jq -r '.token')
    export API_TOKEN="$TOKEN"
else
    echo "[FAIL] Local admin authentication failed"
    echo "Response: $response"
fi
```

### 2.2 LDAP Authentication

```bash
echo "=== LDAP Authentication Test ==="

# Test AD user via API
response=$(curl -sk -X POST "https://wallix.lab.local/api/auth" \
    -H "Content-Type: application/json" \
    -d '{"user": "jadmin@lab.local", "password": "JohnAdmin123!"}')

if echo "$response" | grep -q "token"; then
    echo "[PASS] LDAP authentication successful for jadmin"
else
    echo "[FAIL] LDAP authentication failed for jadmin"
    echo "Response: $response"
fi
```

### 2.3 SSH Session Test

```bash
echo "=== SSH Session Test ==="

# Test SSH proxy connection
# Note: This requires sshpass for automation
apt install -y sshpass 2>/dev/null

# Connect as jadmin to linux-test via WALLIX Bastion
sshpass -p 'JohnAdmin123!' ssh -o StrictHostKeyChecking=no jadmin@wallix.lab.local << 'EOF'
# Select target: linux-test / root
whoami
hostname
exit
EOF

if [ $? -eq 0 ]; then
    echo "[PASS] SSH session through WALLIX Bastion successful"
else
    echo "[FAIL] SSH session through WALLIX Bastion failed"
fi
```

### 2.4 Web UI Access Test

```bash
echo "=== Web UI Access Test ==="

# Test HTTPS access
http_code=$(curl -sk -o /dev/null -w "%{http_code}" "https://wallix.lab.local/")

if [ "$http_code" == "200" ] || [ "$http_code" == "302" ]; then
    echo "[PASS] Web UI accessible (HTTP $http_code)"
else
    echo "[FAIL] Web UI not accessible (HTTP $http_code)"
fi
```

### 2.5 Password Checkout Test

```bash
echo "=== Password Checkout Test ==="

# Checkout password via API
response=$(curl -sk -X POST "https://wallix.lab.local/api/passwords/checkout" \
    -H "X-Auth-Token: $API_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"device": "linux-test", "account": "root"}')

if echo "$response" | grep -q "password"; then
    echo "[PASS] Password checkout successful"
    # Immediately check in
    curl -sk -X POST "https://wallix.lab.local/api/passwords/checkin" \
        -H "X-Auth-Token: $API_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"device": "linux-test", "account": "root"}'
else
    echo "[FAIL] Password checkout failed"
    echo "Response: $response"
fi
```

---

## Test 3: HAProxy VIP Failover and Cyber VLAN Connectivity

### 3.1 HAProxy VIP Status

```bash
echo "=== HAProxy VIP Status Test ==="

# Check which HAProxy node holds the VIP
echo "Checking VIP on haproxy-1 (10.10.1.5):"
ssh root@haproxy-1.lab.local "ip addr show | grep 10.10.1.100 && echo '[PASS] haproxy-1 holds VIP' || echo '[INFO] haproxy-1 does not hold VIP'"

echo "Checking VIP on haproxy-2 (10.10.1.6):"
ssh root@haproxy-2.lab.local "ip addr show | grep 10.10.1.100 && echo '[PASS] haproxy-2 holds VIP' || echo '[INFO] haproxy-2 does not hold VIP'"

# Check HAProxy stats
curl -s http://10.10.1.5:8404/stats | grep -q "wallix-bastion" && echo "[PASS] HAProxy stats page accessible" || echo "[FAIL] HAProxy stats not accessible"
```

### 3.2 HAProxy VIP Failover Test

```bash
echo "=== HAProxy VIP Failover Test (haproxy-1 -> haproxy-2) ==="

# Baseline: confirm VIP is on haproxy-1
ssh root@haproxy-1.lab.local "ip addr show | grep -q '10.10.1.100'" && echo "VIP on haproxy-1 (MASTER)" || echo "VIP not on haproxy-1"

# Start continuous connectivity test in background
ping -c 30 10.10.1.100 > /tmp/failover_ping.log 2>&1 &
PING_PID=$!

# Stop HAProxy on haproxy-1 to trigger failover
echo "Stopping HAProxy on haproxy-1 to trigger VIP failover..."
ssh root@haproxy-1.lab.local "systemctl stop haproxy"
sleep 8

# Check VIP moved to haproxy-2
new_vip=$(ssh root@haproxy-2.lab.local "ip addr show | grep -q '10.10.1.100' && echo 'moved' || echo 'not_moved'")

# Restore haproxy-1
ssh root@haproxy-1.lab.local "systemctl start haproxy"

# Wait for ping to complete
wait $PING_PID
lost=$(grep -c "unreachable\|timeout" /tmp/failover_ping.log 2>/dev/null || echo "0")

if [ "$new_vip" == "moved" ] && [ "$lost" -lt 5 ]; then
    echo "[PASS] HAProxy VIP failover successful (packet loss: $lost)"
else
    echo "[FAIL] HAProxy VIP failover issue (VIP status: $new_vip, packet loss: $lost)"
fi
```

### 3.3 Cyber VLAN Connectivity Test (from Bastion DMZ)

```bash
echo "=== Cyber VLAN Connectivity Test (from wallix-bastion) ==="
# These tests verify Fortigate inter-VLAN routing: DMZ (VLAN 110) -> Cyber (VLAN 120)

ssh root@wallix-bastion.lab.local << 'BASTION_EOF'
echo "--- LDAPS to dc-lab (10.10.1.60:636) ---"
nc -zv 10.10.1.60 636 2>&1 | grep -q "succeeded" && echo "[PASS] LDAPS reachable" || echo "[FAIL] LDAPS not reachable"

echo "--- LDAP to dc-lab (10.10.1.60:389) ---"
nc -zv 10.10.1.60 389 2>&1 | grep -q "succeeded" && echo "[PASS] LDAP reachable" || echo "[FAIL] LDAP not reachable"

echo "--- Kerberos to dc-lab (10.10.1.60:88) ---"
nc -zv 10.10.1.60 88 2>&1 | grep -q "succeeded" && echo "[PASS] Kerberos reachable" || echo "[FAIL] Kerberos not reachable"

echo "--- RADIUS to fortiauth (10.10.1.50:1812 UDP) ---"
# UDP test using radtest (freeradius-utils)
if command -v radtest &>/dev/null; then
    radtest test test 10.10.1.50 0 WallixRadius2026! 2>&1 | grep -q "Access-" && echo "[PASS] RADIUS reachable" || echo "[FAIL] RADIUS not reachable"
else
    nc -zu 10.10.1.50 1812 && echo "[INFO] UDP 1812 open (install freeradius-utils for full test)" || echo "[FAIL] UDP 1812 closed"
fi
BASTION_EOF
```

### 3.4 Service Continuity Through VIP

```bash
echo "=== Service Continuity Test ==="

# Test HAProxy VIP is routing to the single Bastion node
for i in {1..5}; do
    http_code=$(curl -sk -o /dev/null -w "%{http_code}" --max-time 3 "https://10.10.1.100/")
    echo "Attempt $i: HTTP $http_code"
    sleep 1
done
```

---

## Test 4: Integration Tests

### 4.1 AD Group Mapping Test

```bash
echo "=== AD Group Mapping Test ==="

# Login as jadmin and verify groups
response=$(curl -sk -X POST "https://wallix.lab.local/api/auth" \
    -H "Content-Type: application/json" \
    -d '{"user": "jadmin@lab.local", "password": "JohnAdmin123!"}')

token=$(echo "$response" | jq -r '.token')

# Get user details
user_info=$(curl -sk "https://wallix.lab.local/api/users/jadmin" \
    -H "X-Auth-Token: $token")

echo "User info:"
echo "$user_info" | jq '.groups'

if echo "$user_info" | grep -q "LDAP-Admins"; then
    echo "[PASS] AD group mapping working"
else
    echo "[FAIL] AD group mapping not working"
fi
```

### 4.2 SIEM Log Forwarding Test

```bash
echo "=== SIEM Log Forwarding Test ==="

# Generate authentication event
curl -sk -X POST "https://wallix.lab.local/api/auth" \
    -H "Content-Type: application/json" \
    -d '{"user": "testuser", "password": "wrongpassword"}' &>/dev/null

# Wait for log to be forwarded
sleep 5

# Check SIEM for event (Splunk example)
# Note: Adjust query based on your SIEM
ssh root@10.10.0.10 << 'EOF'
# For Wazuh
grep -i "wallix\|authentication" /var/ossec/logs/alerts/alerts.log 2>/dev/null | tail -5 || echo "[INFO] Check Wazuh dashboard at http://10.10.0.10:443"

# For Splunk (if used instead)
/opt/splunk/bin/splunk search 'index=wallix "authentication" earliest=-5m' -auth admin:SplunkAdmin123! 2>/dev/null | head -5

# For ELK (if used instead)
curl -s "http://localhost:9200/wallix-*/_search?q=authentication&size=5" | jq '.hits.hits[]._source.message' 2>/dev/null | head -5
EOF

echo "[INFO] Check SIEM manually for authentication event"
```

### 4.3 Prometheus Metrics Test

```bash
echo "=== Prometheus Metrics Test ==="

# Check targets
targets=$(curl -s "http://monitoring-lab.lab.local:9090/api/v1/targets" | jq -r '.data.activeTargets[] | select(.labels.job=="wallix") | "\(.labels.instance): \(.health)"')

echo "WALLIX Bastion targets:"
echo "$targets"

if echo "$targets" | grep -q "up"; then
    echo "[PASS] Prometheus collecting WALLIX Bastion metrics"
else
    echo "[FAIL] Prometheus not collecting WALLIX Bastion metrics"
fi
```

### 4.4 Alert Test

```bash
echo "=== Alert Trigger Test ==="

# Temporarily stop node_exporter to trigger alert
ssh root@wallix-node1.lab.local "systemctl stop node_exporter"

echo "Waiting 2 minutes for alert to fire..."
sleep 120

# Check for alert
alerts=$(curl -s "http://monitoring-lab.lab.local:9090/api/v1/alerts" | jq '.data.alerts[] | select(.labels.alertname=="WALLIX BastionNodeDown")')

if [ -n "$alerts" ]; then
    echo "[PASS] Alert triggered successfully"
    echo "$alerts" | jq '.labels'
else
    echo "[FAIL] Alert did not trigger"
fi

# Restore
ssh root@wallix-node1.lab.local "systemctl start node_exporter"
```

---

## Test 5: Security Tests

### 5.1 Certificate Validation

```bash
echo "=== Certificate Validation Test ==="

# Check certificate
cert_info=$(echo | openssl s_client -connect wallix.lab.local:443 2>/dev/null | openssl x509 -noout -dates -subject 2>/dev/null)

echo "Certificate Info:"
echo "$cert_info"

# Check expiry
expiry=$(echo | openssl s_client -connect wallix.lab.local:443 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
expiry_epoch=$(date -d "$expiry" +%s)
now_epoch=$(date +%s)
days_left=$(( (expiry_epoch - now_epoch) / 86400 ))

if [ $days_left -gt 30 ]; then
    echo "[PASS] Certificate valid for $days_left days"
else
    echo "[WARN] Certificate expires in $days_left days"
fi
```

### 5.2 TLS Configuration

```bash
echo "=== TLS Configuration Test ==="

# Test TLS versions
for version in tls1 tls1_1 tls1_2 tls1_3; do
    result=$(echo | openssl s_client -connect wallix.lab.local:443 -$version 2>&1)
    if echo "$result" | grep -q "Cipher is"; then
        cipher=$(echo "$result" | grep "Cipher is" | head -1)
        echo "[INFO] $version: $cipher"
    else
        echo "[INFO] $version: Not supported"
    fi
done
```

### 5.3 Failed Login Lockout Test

```bash
echo "=== Account Lockout Test ==="

# Attempt multiple failed logins
for i in {1..6}; do
    response=$(curl -sk -X POST "https://wallix.lab.local/api/auth" \
        -H "Content-Type: application/json" \
        -d '{"user": "jadmin@lab.local", "password": "wrongpassword"}')
    echo "Attempt $i: $(echo $response | jq -r '.error // "No error"')"
done

# Try valid login - should be locked
response=$(curl -sk -X POST "https://wallix.lab.local/api/auth" \
    -H "Content-Type: application/json" \
    -d '{"user": "jadmin@lab.local", "password": "JohnAdmin123!"}')

if echo "$response" | grep -qi "locked\|blocked"; then
    echo "[PASS] Account lockout working"
else
    echo "[WARN] Account lockout may not be configured"
fi
```

### 5.4 Audit Log Test

```bash
echo "=== Audit Log Test ==="

# Check audit logs exist
ssh root@wallix-node1.lab.local << 'EOF'
echo "Recent audit entries:"
wabadmin audit --last 10

echo ""
echo "Audit log size:"
ls -lh /var/log/wabaudit/audit.log
EOF
```

---

## Test 6: Performance Tests

### 6.1 Concurrent Authentication Test

```bash
echo "=== Concurrent Authentication Test ==="

# Run 10 concurrent authentications
for i in {1..10}; do
    curl -sk -X POST "https://wallix.lab.local/api/auth" \
        -H "Content-Type: application/json" \
        -d '{"user": "admin", "password": "Pam4otAdmin123!"}' &
done

wait
echo "[INFO] 10 concurrent authentications completed"
```

### 6.2 API Response Time Test

```bash
echo "=== API Response Time Test ==="

# Measure response times
for endpoint in "/" "/api/status" "/api/version"; do
    time=$(curl -sk -o /dev/null -w "%{time_total}" "https://wallix.lab.local${endpoint}")
    echo "GET $endpoint: ${time}s"
done
```

### 6.3 Database Performance Test

```bash
echo "=== Database Performance Test ==="

ssh root@wallix-node1.lab.local << 'EOF'
# Simple query timing
echo "Query performance:"
sudo mysql wabdb -c "EXPLAIN ANALYZE SELECT count(*) FROM sessions WHERE created > NOW() - interval '1 day';"
EOF
```

---

## Test Results Summary Template

```
+===============================================================================+
|                          TEST RESULTS SUMMARY                                 |
+===============================================================================+

  Test Date: ____________________
  Tester: ____________________
  Environment: Pre-Production Lab

  INFRASTRUCTURE TESTS
  --------------------
  [ ] VM Connectivity            [PASS/FAIL]
  [ ] DNS Resolution             [PASS/FAIL]
  [ ] Port Connectivity          [PASS/FAIL]

  WALLIX Bastion FUNCTIONAL TESTS
  -----------------------
  [ ] Local Authentication       [PASS/FAIL]
  [ ] LDAP Authentication        [PASS/FAIL]
  [ ] SSH Session                [PASS/FAIL]
  [ ] Web UI Access              [PASS/FAIL]
  [ ] Password Checkout          [PASS/FAIL]

  HAPROXY VIP + CYBER VLAN TESTS
  -------------------------------
  [ ] HAProxy VIP status         [PASS/FAIL]
  [ ] HAProxy VIP failover       [PASS/FAIL]
  [ ] Bastion -> AD LDAPS        [PASS/FAIL]
  [ ] Bastion -> FortiAuth RADIUS[PASS/FAIL]

  INTEGRATION TESTS
  -----------------
  [ ] AD Group Mapping           [PASS/FAIL]
  [ ] SIEM Log Forwarding        [PASS/FAIL]
  [ ] Prometheus Metrics         [PASS/FAIL]
  [ ] Alert Triggering           [PASS/FAIL]

  SECURITY TESTS
  --------------
  [ ] Certificate Valid          [PASS/FAIL]
  [ ] TLS Configuration          [PASS/FAIL]
  [ ] Account Lockout            [PASS/FAIL]
  [ ] Audit Logging              [PASS/FAIL]

  PERFORMANCE TESTS
  -----------------
  [ ] Concurrent Auth            [PASS/FAIL]
  [ ] API Response Time          [PASS/FAIL]  (Target: < 500ms)
  [ ] Database Performance       [PASS/FAIL]

  OVERALL STATUS: ____________

  NOTES:
  _______________________________________________________________________
  _______________________________________________________________________
  _______________________________________________________________________

+===============================================================================+
```

---

## Automated Test Script

Save as `/pre/scripts/run-all-tests.sh`:

```bash
#!/bin/bash
# WALLIX Bastion Pre-Production Lab - Full Test Suite

LOG_FILE="/tmp/wallix-test-$(date +%Y%m%d-%H%M%S).log"

echo "WALLIX Bastion Test Suite - $(date)" | tee "$LOG_FILE"
echo "================================" | tee -a "$LOG_FILE"

# Source test functions
# ... (include all tests above)

# Run all tests
echo "Running tests..." | tee -a "$LOG_FILE"

# Infrastructure
run_connectivity_tests 2>&1 | tee -a "$LOG_FILE"
run_dns_tests 2>&1 | tee -a "$LOG_FILE"
run_port_tests 2>&1 | tee -a "$LOG_FILE"

# Functional
run_auth_tests 2>&1 | tee -a "$LOG_FILE"
run_session_tests 2>&1 | tee -a "$LOG_FILE"

# HAProxy VIP and Cyber VLAN
run_haproxy_tests 2>&1 | tee -a "$LOG_FILE"
run_cyber_vlan_tests 2>&1 | tee -a "$LOG_FILE"

# Integration
run_integration_tests 2>&1 | tee -a "$LOG_FILE"

# Security
run_security_tests 2>&1 | tee -a "$LOG_FILE"

# Performance
run_performance_tests 2>&1 | tee -a "$LOG_FILE"

echo "" | tee -a "$LOG_FILE"
echo "Tests completed. Log saved to: $LOG_FILE" | tee -a "$LOG_FILE"
```

---

## Validation Checklist

| Category | Test | Status | Notes |
|----------|------|--------|-------|
| Infrastructure | All VMs reachable | [ ] | |
| Infrastructure | DNS resolving | [ ] | |
| Infrastructure | Required ports open | [ ] | |
| WALLIX Bastion | Local admin login | [ ] | |
| WALLIX Bastion | LDAP user login | [ ] | |
| WALLIX Bastion | SSH session works | [ ] | |
| WALLIX Bastion | RDP session works | [ ] | |
| WALLIX Bastion | Password checkout | [ ] | |
| HAProxy | VIP failover < 30s | [ ] | |
| HAProxy | Bastion backend healthy | [ ] | |
| Cyber VLAN | Bastion -> AD LDAPS | [ ] | inter-VLAN via Fortigate |
| Cyber VLAN | Bastion -> FortiAuth RADIUS | [ ] | inter-VLAN via Fortigate |
| Integration | AD groups mapped | [ ] | |
| Integration | Logs in SIEM | [ ] | |
| Integration | Metrics in Prometheus | [ ] | |
| Integration | Grafana dashboards | [ ] | |
| Security | Valid certificates | [ ] | |
| Security | TLS 1.2+ only | [ ] | |
| Security | Audit logs working | [ ] | |
| Performance | Auth < 500ms | [ ] | |

Last updated: April 2026 | WALLIX Bastion 12.1.x | Single Bastion node | HAProxy VIP tested | TOTP MFA only

---

<p align="center">
  <a href="./11-observability.md">← Previous: Observability Stack</a> •
  <a href="./13-team-handoffs.md">Next: Team Handoffs →</a>
</p>
