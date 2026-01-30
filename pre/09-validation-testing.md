# 09 - Validation Testing

## Comprehensive Test Suite for Pre-Production Lab

This guide covers all validation tests to verify the PAM4OT lab environment is working correctly.

---

## Test Categories Overview

```
+===============================================================================+
|                        VALIDATION TEST CATEGORIES                             |
+===============================================================================+

  1. INFRASTRUCTURE TESTS            2. PAM4OT FUNCTIONAL TESTS
  =======================            ==========================
  - VM connectivity                  - Authentication (local/LDAP)
  - DNS resolution                   - Session management
  - Network segmentation             - Password checkout
  - Storage verification             - Recording playback

  3. HA CLUSTER TESTS                4. INTEGRATION TESTS
  ===================                ====================
  - Failover scenarios               - AD group mapping
  - VIP movement                     - SIEM log forwarding
  - Replication health               - Metrics collection
  - Split-brain prevention           - Alert triggering

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

# Define hosts
declare -A HOSTS=(
    ["dc-lab.lab.local"]="10.10.1.10"
    ["pam4ot-node1.lab.local"]="10.10.1.11"
    ["pam4ot-node2.lab.local"]="10.10.1.12"
    ["siem-lab.lab.local"]="10.10.1.50"
    ["monitoring-lab.lab.local"]="10.10.1.60"
    ["linux-test.lab.local"]="10.10.2.10"
    ["windows-test.lab.local"]="10.10.2.20"
    ["network-test.lab.local"]="10.10.2.30"
    ["plc-sim.lab.local"]="10.10.3.10"
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

for host in dc-lab pam4ot-node1 pam4ot-node2 pam4ot siem-lab monitoring-lab; do
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

# PAM4OT services
nc -zv pam4ot.lab.local 443 2>&1 | grep -q "succeeded" && echo "[PASS] PAM4OT HTTPS" || echo "[FAIL] PAM4OT HTTPS"
nc -zv pam4ot.lab.local 22 2>&1 | grep -q "succeeded" && echo "[PASS] PAM4OT SSH" || echo "[FAIL] PAM4OT SSH"

# AD services
nc -zv dc-lab.lab.local 636 2>&1 | grep -q "succeeded" && echo "[PASS] LDAPS" || echo "[FAIL] LDAPS"
nc -zv dc-lab.lab.local 88 2>&1 | grep -q "succeeded" && echo "[PASS] Kerberos" || echo "[FAIL] Kerberos"

# SIEM
nc -zv siem-lab.lab.local 514 2>&1 | grep -q "succeeded" && echo "[PASS] Syslog" || echo "[FAIL] Syslog"

# Monitoring
nc -zv monitoring-lab.lab.local 9090 2>&1 | grep -q "succeeded" && echo "[PASS] Prometheus" || echo "[FAIL] Prometheus"
nc -zv monitoring-lab.lab.local 3000 2>&1 | grep -q "succeeded" && echo "[PASS] Grafana" || echo "[FAIL] Grafana"
```

---

## Test 2: PAM4OT Functional Tests

### 2.1 Local Admin Authentication

```bash
echo "=== Local Admin Authentication Test ==="

# Test via API
response=$(curl -sk -X POST "https://pam4ot.lab.local/api/auth" \
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
response=$(curl -sk -X POST "https://pam4ot.lab.local/api/auth" \
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

# Connect as jadmin to linux-test via PAM4OT
sshpass -p 'JohnAdmin123!' ssh -o StrictHostKeyChecking=no jadmin@pam4ot.lab.local << 'EOF'
# Select target: linux-test / root
whoami
hostname
exit
EOF

if [ $? -eq 0 ]; then
    echo "[PASS] SSH session through PAM4OT successful"
else
    echo "[FAIL] SSH session through PAM4OT failed"
fi
```

### 2.4 Web UI Access Test

```bash
echo "=== Web UI Access Test ==="

# Test HTTPS access
http_code=$(curl -sk -o /dev/null -w "%{http_code}" "https://pam4ot.lab.local/")

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
response=$(curl -sk -X POST "https://pam4ot.lab.local/api/passwords/checkout" \
    -H "X-Auth-Token: $API_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"device": "linux-test", "account": "root"}')

if echo "$response" | grep -q "password"; then
    echo "[PASS] Password checkout successful"
    # Immediately check in
    curl -sk -X POST "https://pam4ot.lab.local/api/passwords/checkin" \
        -H "X-Auth-Token: $API_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"device": "linux-test", "account": "root"}'
else
    echo "[FAIL] Password checkout failed"
    echo "Response: $response"
fi
```

---

## Test 3: HA Cluster Tests

### 3.1 Cluster Status

```bash
echo "=== Cluster Status Test ==="

# On either PAM4OT node
ssh root@pam4ot-node1.lab.local << 'EOF'
echo "Pacemaker Status:"
pcs status | grep -E "(Online|Offline|vip-pam4ot)"

echo ""
echo "VIP Location:"
ip addr show | grep "10.10.1.100"
EOF
```

### 3.2 Database Replication Status

```bash
echo "=== Replication Status Test ==="

# On Node 1 (Primary)
ssh root@pam4ot-node1.lab.local << 'EOF'
echo "Replication Status (from primary):"
sudo mysql -c "SELECT client_addr, state, sent_lsn, write_lsn, replay_lsn FROM SHOW SLAVE STATUS;"

echo ""
echo "Replication Lag:"
sudo mysql -e "SHOW SLAVE STATUS\G" | grep Seconds_Behind_Master
EOF

# On Node 2 (Replica)
ssh root@pam4ot-node2.lab.local << 'EOF'
echo "Recovery Status (from replica):"
sudo mysql -e "SHOW SLAVE STATUS\G"
EOF
```

### 3.3 VIP Failover Test

```bash
echo "=== VIP Failover Test ==="

# Find which node has VIP
vip_node=$(ssh root@pam4ot-node1.lab.local "ip addr show | grep -q '10.10.1.100' && echo 'node1' || echo 'node2'")

echo "VIP currently on: $vip_node"

# Start continuous ping in background
ping -c 30 10.10.1.100 > /tmp/failover_ping.log 2>&1 &
PING_PID=$!

# Trigger failover
if [ "$vip_node" == "node1" ]; then
    echo "Putting node1 in standby..."
    ssh root@pam4ot-node1.lab.local "pcs node standby pam4ot-node1"
    sleep 10

    # Check VIP moved
    new_vip=$(ssh root@pam4ot-node2.lab.local "ip addr show | grep -q '10.10.1.100' && echo 'moved' || echo 'not_moved'")

    # Restore
    ssh root@pam4ot-node1.lab.local "pcs node unstandby pam4ot-node1"
else
    echo "Putting node2 in standby..."
    ssh root@pam4ot-node2.lab.local "pcs node standby pam4ot-node2"
    sleep 10

    new_vip=$(ssh root@pam4ot-node1.lab.local "ip addr show | grep -q '10.10.1.100' && echo 'moved' || echo 'not_moved'")

    ssh root@pam4ot-node2.lab.local "pcs node unstandby pam4ot-node2"
fi

# Wait for ping to complete
wait $PING_PID

# Analyze results
lost=$(grep -c "unreachable\|timeout" /tmp/failover_ping.log 2>/dev/null || echo "0")

if [ "$new_vip" == "moved" ] && [ "$lost" -lt 5 ]; then
    echo "[PASS] VIP failover successful with minimal packet loss ($lost packets)"
else
    echo "[FAIL] VIP failover issues (VIP: $new_vip, Lost packets: $lost)"
fi
```

### 3.4 Service Continuity Test

```bash
echo "=== Service Continuity Test ==="

# During failover, test web access
for i in {1..20}; do
    http_code=$(curl -sk -o /dev/null -w "%{http_code}" --max-time 2 "https://10.10.1.100/")
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
response=$(curl -sk -X POST "https://pam4ot.lab.local/api/auth" \
    -H "Content-Type: application/json" \
    -d '{"user": "jadmin@lab.local", "password": "JohnAdmin123!"}')

token=$(echo "$response" | jq -r '.token')

# Get user details
user_info=$(curl -sk "https://pam4ot.lab.local/api/users/jadmin" \
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
curl -sk -X POST "https://pam4ot.lab.local/api/auth" \
    -H "Content-Type: application/json" \
    -d '{"user": "testuser", "password": "wrongpassword"}' &>/dev/null

# Wait for log to be forwarded
sleep 5

# Check SIEM for event (Splunk example)
# Note: Adjust query based on your SIEM
ssh root@siem-lab.lab.local << 'EOF'
# For Splunk
/opt/splunk/bin/splunk search 'index=pam4ot "authentication" earliest=-5m' -auth admin:SplunkAdmin123! 2>/dev/null | head -5

# For ELK
curl -s "http://localhost:9200/pam4ot-*/_search?q=authentication&size=5" | jq '.hits.hits[]._source.message' 2>/dev/null | head -5
EOF

echo "[INFO] Check SIEM manually for authentication event"
```

### 4.3 Prometheus Metrics Test

```bash
echo "=== Prometheus Metrics Test ==="

# Check targets
targets=$(curl -s "http://monitoring-lab.lab.local:9090/api/v1/targets" | jq -r '.data.activeTargets[] | select(.labels.job=="pam4ot") | "\(.labels.instance): \(.health)"')

echo "PAM4OT targets:"
echo "$targets"

if echo "$targets" | grep -q "up"; then
    echo "[PASS] Prometheus collecting PAM4OT metrics"
else
    echo "[FAIL] Prometheus not collecting PAM4OT metrics"
fi
```

### 4.4 Alert Test

```bash
echo "=== Alert Trigger Test ==="

# Temporarily stop node_exporter to trigger alert
ssh root@pam4ot-node1.lab.local "systemctl stop node_exporter"

echo "Waiting 2 minutes for alert to fire..."
sleep 120

# Check for alert
alerts=$(curl -s "http://monitoring-lab.lab.local:9090/api/v1/alerts" | jq '.data.alerts[] | select(.labels.alertname=="PAM4OTNodeDown")')

if [ -n "$alerts" ]; then
    echo "[PASS] Alert triggered successfully"
    echo "$alerts" | jq '.labels'
else
    echo "[FAIL] Alert did not trigger"
fi

# Restore
ssh root@pam4ot-node1.lab.local "systemctl start node_exporter"
```

---

## Test 5: Security Tests

### 5.1 Certificate Validation

```bash
echo "=== Certificate Validation Test ==="

# Check certificate
cert_info=$(echo | openssl s_client -connect pam4ot.lab.local:443 2>/dev/null | openssl x509 -noout -dates -subject 2>/dev/null)

echo "Certificate Info:"
echo "$cert_info"

# Check expiry
expiry=$(echo | openssl s_client -connect pam4ot.lab.local:443 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
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
    result=$(echo | openssl s_client -connect pam4ot.lab.local:443 -$version 2>&1)
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
    response=$(curl -sk -X POST "https://pam4ot.lab.local/api/auth" \
        -H "Content-Type: application/json" \
        -d '{"user": "jadmin@lab.local", "password": "wrongpassword"}')
    echo "Attempt $i: $(echo $response | jq -r '.error // "No error"')"
done

# Try valid login - should be locked
response=$(curl -sk -X POST "https://pam4ot.lab.local/api/auth" \
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
ssh root@pam4ot-node1.lab.local << 'EOF'
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
    curl -sk -X POST "https://pam4ot.lab.local/api/auth" \
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
    time=$(curl -sk -o /dev/null -w "%{time_total}" "https://pam4ot.lab.local${endpoint}")
    echo "GET $endpoint: ${time}s"
done
```

### 6.3 Database Performance Test

```bash
echo "=== Database Performance Test ==="

ssh root@pam4ot-node1.lab.local << 'EOF'
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

  PAM4OT FUNCTIONAL TESTS
  -----------------------
  [ ] Local Authentication       [PASS/FAIL]
  [ ] LDAP Authentication        [PASS/FAIL]
  [ ] SSH Session                [PASS/FAIL]
  [ ] Web UI Access              [PASS/FAIL]
  [ ] Password Checkout          [PASS/FAIL]

  HA CLUSTER TESTS
  ----------------
  [ ] Cluster Status             [PASS/FAIL]
  [ ] Replication Health         [PASS/FAIL]
  [ ] VIP Failover               [PASS/FAIL]
  [ ] Service Continuity         [PASS/FAIL]

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
# PAM4OT Pre-Production Lab - Full Test Suite

LOG_FILE="/tmp/pam4ot-test-$(date +%Y%m%d-%H%M%S).log"

echo "PAM4OT Test Suite - $(date)" | tee "$LOG_FILE"
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

# HA
run_cluster_tests 2>&1 | tee -a "$LOG_FILE"
run_replication_tests 2>&1 | tee -a "$LOG_FILE"

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
| PAM4OT | Local admin login | [ ] | |
| PAM4OT | LDAP user login | [ ] | |
| PAM4OT | SSH session works | [ ] | |
| PAM4OT | RDP session works | [ ] | |
| PAM4OT | Password checkout | [ ] | |
| HA | Cluster healthy | [ ] | |
| HA | VIP failover < 30s | [ ] | |
| HA | Replication lag < 1MB | [ ] | |
| Integration | AD groups mapped | [ ] | |
| Integration | Logs in SIEM | [ ] | |
| Integration | Metrics in Prometheus | [ ] | |
| Integration | Grafana dashboards | [ ] | |
| Security | Valid certificates | [ ] | |
| Security | TLS 1.2+ only | [ ] | |
| Security | Audit logs working | [ ] | |
| Performance | Auth < 500ms | [ ] | |

---

<p align="center">
  <a href="./08-observability.md">← Previous</a> •
  <a href="./10-team-handoffs.md">Next: Team Handoffs →</a>
</p>
