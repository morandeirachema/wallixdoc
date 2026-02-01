# Network Segmentation Validation

## Validating PAM4OT Network Zones and Traffic Flows

This guide provides procedures for validating network segmentation around PAM4OT deployment.

---

## Network Architecture Overview

```
+===============================================================================+
|                    PAM4OT NETWORK SEGMENTATION MODEL                          |
+===============================================================================+

                            INTERNET
                                │
                      ┌─────────┴─────────┐
                      │   Firewall/DMZ    │
                      └─────────┬─────────┘
                                │
  ┌─────────────────────────────┼─────────────────────────────────┐
  │                     CORPORATE ZONE (Zone 4)                   │
  │  ┌───────────────┐    ┌───────────────┐    ┌───────────────┐  │
  │  │ User Stations │    │   AD / LDAP   │    │     SIEM      │  │
  │  │  10.1.0.0/24  │    │  10.1.1.0/24  │    │  10.1.2.0/24  │  │
  │  └───────────────┘    └───────────────┘    └───────────────┘  │
  └─────────────────────────────┼─────────────────────────────────┘
                                │
                      ┌─────────┴─────────┐
                      │   Core Firewall   │
                      └─────────┬─────────┘
                                │
  ┌─────────────────────────────┼─────────────────────────────────┐
  │                   PAM MANAGEMENT ZONE (Zone 3.5)              │
  │  ┌───────────────┐    ┌───────────────┐    ┌───────────────┐  │
  │  │  PAM4OT VIP   │    │  PAM4OT Node1 │    │  PAM4OT Node2 │  │
  │  │  10.10.1.100  │    │  10.10.1.101  │    │  10.10.1.102  │  │
  │  └───────────────┘    └───────────────┘    └───────────────┘  │
  └─────────────────────────────┼─────────────────────────────────┘
                                │
                      ┌─────────┴─────────┐
                      │  Industrial DMZ   │
                      └─────────┬─────────┘
                                │
  ┌─────────────────────────────┼─────────────────────────────────┐
  │                    OT ZONE (Zone 2)                           │
  │  ┌───────────────┐    ┌───────────────┐    ┌───────────────┐  │
  │  │      HMI      │    │    SCADA      │    │   Historian   │  │
  │  │  10.20.1.0/24 │    │  10.20.2.0/24 │    │  10.20.3.0/24 │  │
  │  └───────────────┘    └───────────────┘    └───────────────┘  │
  └─────────────────────────────┼─────────────────────────────────┘
                                │
  ┌─────────────────────────────┼─────────────────────────────────┐
  │                    PROCESS ZONE (Zone 1)                      │
  │  ┌───────────────┐    ┌───────────────┐    ┌───────────────┐  │
  │  │      PLC      │    │      RTU      │    │      DCS      │  │
  │  │  10.30.1.0/24 │    │  10.30.2.0/24 │    │  10.30.3.0/24 │  │
  │  └───────────────┘    └───────────────┘    └───────────────┘  │
  └───────────────────────────────────────────────────────────────┘

+===============================================================================+
```

---

## Section 1: Traffic Flow Matrix

### Allowed Traffic Flows

| Source Zone | Destination Zone | Service | Port | Direction |
|-------------|------------------|---------|------|-----------|
| Corporate | PAM Zone | HTTPS | 443 | Inbound |
| Corporate | PAM Zone | SSH | 22 | Inbound |
| PAM Zone | Corporate | LDAPS | 636 | Outbound |
| PAM Zone | Corporate | Kerberos | 88 | Outbound |
| PAM Zone | Corporate | Syslog | 514/6514 | Outbound |
| PAM Zone | OT Zone | SSH | 22 | Outbound |
| PAM Zone | OT Zone | RDP | 3389 | Outbound |
| PAM Zone | OT Zone | VNC | 5900 | Outbound |
| PAM Zone | Process Zone | Modbus | 502 | Outbound |
| PAM Zone | Process Zone | DNP3 | 20000 | Outbound |
| PAM Zone | Process Zone | OPC UA | 4840 | Outbound |

### Denied Traffic Flows

| Source Zone | Destination Zone | Reason |
|-------------|------------------|--------|
| Corporate | OT Zone | Must traverse PAM |
| Corporate | Process Zone | Must traverse PAM |
| OT Zone | Corporate | No direct return path |
| Process Zone | Corporate | Isolated network |
| Internet | PAM Zone | Only via VPN/jump host |

---

## Section 2: Validation Tests

### Test 1: Corporate to PAM Zone Access

```bash
# Test from corporate workstation

# Test 1.1: HTTPS access to PAM4OT (should succeed)
curl -v -k https://10.10.1.100/
# Expected: 200 OK

# Test 1.2: SSH access to PAM4OT (should succeed)
nc -zv 10.10.1.100 22
# Expected: Connection succeeded

# Test 1.3: Direct access to OT zone (should fail)
nc -zv 10.20.1.50 22
# Expected: Connection refused or timeout
```

### Test 2: PAM Zone to Corporate Services

```bash
# Test from PAM4OT node

# Test 2.1: LDAPS to AD (should succeed)
nc -zv dc-lab.company.com 636
# Expected: Connection succeeded

# Test 2.2: Kerberos to AD (should succeed)
nc -zv dc-lab.company.com 88
# Expected: Connection succeeded

# Test 2.3: Syslog to SIEM (should succeed)
nc -zv siem.company.com 514
# Expected: Connection succeeded

# Test 2.4: Internet access (should be blocked or restricted)
curl -v https://www.google.com
# Expected: Connection timeout or block
```

### Test 3: PAM Zone to OT Zone

```bash
# Test from PAM4OT node

# Test 3.1: SSH to HMI (should succeed)
nc -zv 10.20.1.50 22
# Expected: Connection succeeded

# Test 3.2: RDP to SCADA server (should succeed)
nc -zv 10.20.2.50 3389
# Expected: Connection succeeded

# Test 3.3: Modbus to PLC (should succeed)
nc -zv 10.30.1.10 502
# Expected: Connection succeeded
```

### Test 4: Direct OT Access (Bypass Test)

```bash
# Test from corporate workstation - these should ALL FAIL

# Test 4.1: Direct SSH to HMI
nc -zv 10.20.1.50 22
# Expected: Connection timeout

# Test 4.2: Direct RDP to SCADA
nc -zv 10.20.2.50 3389
# Expected: Connection timeout

# Test 4.3: Direct Modbus to PLC
nc -zv 10.30.1.10 502
# Expected: Connection timeout
```

---

## Section 3: Validation Scripts

### Full Network Validation Script

```bash
#!/bin/bash
# network-validation.sh - PAM4OT network segmentation test

LOG_FILE="/tmp/network-validation-$(date +%Y%m%d_%H%M%S).log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test function
test_connection() {
    local SOURCE=$1
    local DEST_IP=$2
    local DEST_PORT=$3
    local EXPECTED=$4
    local DESC=$5

    echo -n "Testing: ${DESC}... " | tee -a ${LOG_FILE}

    timeout 5 nc -zv ${DEST_IP} ${DEST_PORT} 2>/dev/null
    RESULT=$?

    if [ "${EXPECTED}" == "allow" ]; then
        if [ $RESULT -eq 0 ]; then
            echo -e "${GREEN}PASS (Connected)${NC}" | tee -a ${LOG_FILE}
            return 0
        else
            echo -e "${RED}FAIL (Expected connection)${NC}" | tee -a ${LOG_FILE}
            return 1
        fi
    else
        if [ $RESULT -ne 0 ]; then
            echo -e "${GREEN}PASS (Blocked)${NC}" | tee -a ${LOG_FILE}
            return 0
        else
            echo -e "${RED}FAIL (Expected block)${NC}" | tee -a ${LOG_FILE}
            return 1
        fi
    fi
}

echo "=============================================" | tee ${LOG_FILE}
echo "PAM4OT Network Segmentation Validation" | tee -a ${LOG_FILE}
echo "Date: $(date)" | tee -a ${LOG_FILE}
echo "=============================================" | tee -a ${LOG_FILE}

TOTAL=0
PASSED=0
FAILED=0

# Define tests based on running location
if hostname | grep -q "pam4ot"; then
    echo "Running from PAM4OT node" | tee -a ${LOG_FILE}

    # PAM -> Corporate tests
    echo -e "\n--- PAM Zone to Corporate Zone ---" | tee -a ${LOG_FILE}
    test_connection "PAM" "dc-lab.company.com" "636" "allow" "LDAPS to AD" && ((PASSED++)) || ((FAILED++)); ((TOTAL++))
    test_connection "PAM" "dc-lab.company.com" "88" "allow" "Kerberos to AD" && ((PASSED++)) || ((FAILED++)); ((TOTAL++))
    test_connection "PAM" "siem.company.com" "514" "allow" "Syslog to SIEM" && ((PASSED++)) || ((FAILED++)); ((TOTAL++))

    # PAM -> OT Zone tests
    echo -e "\n--- PAM Zone to OT Zone ---" | tee -a ${LOG_FILE}
    test_connection "PAM" "10.20.1.50" "22" "allow" "SSH to HMI" && ((PASSED++)) || ((FAILED++)); ((TOTAL++))
    test_connection "PAM" "10.20.2.50" "3389" "allow" "RDP to SCADA" && ((PASSED++)) || ((FAILED++)); ((TOTAL++))

    # PAM -> Process Zone tests
    echo -e "\n--- PAM Zone to Process Zone ---" | tee -a ${LOG_FILE}
    test_connection "PAM" "10.30.1.10" "502" "allow" "Modbus to PLC" && ((PASSED++)) || ((FAILED++)); ((TOTAL++))
    test_connection "PAM" "10.30.2.10" "20000" "allow" "DNP3 to RTU" && ((PASSED++)) || ((FAILED++)); ((TOTAL++))

else
    echo "Running from Corporate workstation" | tee -a ${LOG_FILE}

    # Corporate -> PAM tests
    echo -e "\n--- Corporate Zone to PAM Zone ---" | tee -a ${LOG_FILE}
    test_connection "Corporate" "10.10.1.100" "443" "allow" "HTTPS to PAM VIP" && ((PASSED++)) || ((FAILED++)); ((TOTAL++))
    test_connection "Corporate" "10.10.1.100" "22" "allow" "SSH to PAM VIP" && ((PASSED++)) || ((FAILED++)); ((TOTAL++))

    # Bypass tests (should all fail)
    echo -e "\n--- Bypass Tests (All should FAIL) ---" | tee -a ${LOG_FILE}
    test_connection "Corporate" "10.20.1.50" "22" "deny" "Direct SSH to HMI" && ((PASSED++)) || ((FAILED++)); ((TOTAL++))
    test_connection "Corporate" "10.20.2.50" "3389" "deny" "Direct RDP to SCADA" && ((PASSED++)) || ((FAILED++)); ((TOTAL++))
    test_connection "Corporate" "10.30.1.10" "502" "deny" "Direct Modbus to PLC" && ((PASSED++)) || ((FAILED++)); ((TOTAL++))
fi

# Summary
echo -e "\n=============================================" | tee -a ${LOG_FILE}
echo "RESULTS SUMMARY" | tee -a ${LOG_FILE}
echo "=============================================" | tee -a ${LOG_FILE}
echo "Total Tests: ${TOTAL}" | tee -a ${LOG_FILE}
echo -e "Passed: ${GREEN}${PASSED}${NC}" | tee -a ${LOG_FILE}
echo -e "Failed: ${RED}${FAILED}${NC}" | tee -a ${LOG_FILE}

if [ ${FAILED} -eq 0 ]; then
    echo -e "\n${GREEN}ALL TESTS PASSED${NC}" | tee -a ${LOG_FILE}
    exit 0
else
    echo -e "\n${RED}SOME TESTS FAILED - REVIEW REQUIRED${NC}" | tee -a ${LOG_FILE}
    exit 1
fi
```

---

## Section 4: Firewall Rule Verification

### Expected Firewall Rules

```bash
# Corporate Firewall (between Corporate and PAM Zone)

# Allow corporate to PAM4OT
iptables -A FORWARD -s 10.1.0.0/24 -d 10.10.1.0/24 -p tcp --dport 443 -j ACCEPT
iptables -A FORWARD -s 10.1.0.0/24 -d 10.10.1.0/24 -p tcp --dport 22 -j ACCEPT

# Allow PAM to AD/LDAP
iptables -A FORWARD -s 10.10.1.0/24 -d 10.1.1.0/24 -p tcp --dport 636 -j ACCEPT
iptables -A FORWARD -s 10.10.1.0/24 -d 10.1.1.0/24 -p tcp --dport 88 -j ACCEPT
iptables -A FORWARD -s 10.10.1.0/24 -d 10.1.1.0/24 -p udp --dport 88 -j ACCEPT

# Allow PAM to SIEM
iptables -A FORWARD -s 10.10.1.0/24 -d 10.1.2.0/24 -p tcp --dport 514 -j ACCEPT
iptables -A FORWARD -s 10.10.1.0/24 -d 10.1.2.0/24 -p tcp --dport 6514 -j ACCEPT

# DENY direct corporate to OT
iptables -A FORWARD -s 10.1.0.0/24 -d 10.20.0.0/16 -j DROP
iptables -A FORWARD -s 10.1.0.0/24 -d 10.30.0.0/16 -j DROP
```

### Industrial DMZ Firewall Rules

```bash
# Allow PAM to OT Zone
iptables -A FORWARD -s 10.10.1.0/24 -d 10.20.0.0/16 -p tcp --dport 22 -j ACCEPT
iptables -A FORWARD -s 10.10.1.0/24 -d 10.20.0.0/16 -p tcp --dport 3389 -j ACCEPT
iptables -A FORWARD -s 10.10.1.0/24 -d 10.20.0.0/16 -p tcp --dport 5900 -j ACCEPT

# Allow PAM to Process Zone (specific protocols only)
iptables -A FORWARD -s 10.10.1.0/24 -d 10.30.0.0/16 -p tcp --dport 502 -j ACCEPT
iptables -A FORWARD -s 10.10.1.0/24 -d 10.30.0.0/16 -p tcp --dport 20000 -j ACCEPT
iptables -A FORWARD -s 10.10.1.0/24 -d 10.30.0.0/16 -p tcp --dport 4840 -j ACCEPT
iptables -A FORWARD -s 10.10.1.0/24 -d 10.30.0.0/16 -p tcp --dport 102 -j ACCEPT

# DENY all other traffic
iptables -A FORWARD -j DROP
```

---

## Section 5: Traffic Flow Validation

### Capture and Analyze Traffic

```bash
# On PAM4OT node, capture traffic to verify flows

# Capture corporate to PAM traffic
tcpdump -i ens192 src net 10.1.0.0/24 -w /tmp/corp-to-pam.pcap

# Capture PAM to OT traffic
tcpdump -i ens224 dst net 10.20.0.0/16 or dst net 10.30.0.0/16 -w /tmp/pam-to-ot.pcap

# Capture unexpected traffic
tcpdump -i any 'src net 10.1.0.0/24 and dst net 10.20.0.0/16' -w /tmp/bypass-attempt.pcap
```

### Analyze with tshark

```bash
# Summarize traffic by conversation
tshark -r /tmp/pam-to-ot.pcap -q -z conv,tcp

# Identify protocols
tshark -r /tmp/pam-to-ot.pcap -q -z io,phs

# Check for blocked traffic
tshark -r /tmp/bypass-attempt.pcap -c 10
# Expected: No packets (or only rejected)
```

---

## Section 6: Validation Report Template

```
NETWORK SEGMENTATION VALIDATION REPORT
======================================

Report Date: ____________________
Validated By: ____________________
Environment: [ ] Production  [ ] Test

NETWORK ZONES TESTED
--------------------
[ ] Corporate Zone (10.1.0.0/24)
[ ] PAM Zone (10.10.1.0/24)
[ ] OT Zone (10.20.0.0/16)
[ ] Process Zone (10.30.0.0/16)

ALLOWED TRAFFIC VALIDATION
--------------------------
| Flow | Expected | Result |
|------|----------|--------|
| Corporate → PAM (443) | Allow | [ ] PASS [ ] FAIL |
| Corporate → PAM (22) | Allow | [ ] PASS [ ] FAIL |
| PAM → AD (636) | Allow | [ ] PASS [ ] FAIL |
| PAM → AD (88) | Allow | [ ] PASS [ ] FAIL |
| PAM → SIEM (514) | Allow | [ ] PASS [ ] FAIL |
| PAM → OT (22) | Allow | [ ] PASS [ ] FAIL |
| PAM → OT (3389) | Allow | [ ] PASS [ ] FAIL |
| PAM → Process (502) | Allow | [ ] PASS [ ] FAIL |

BLOCKED TRAFFIC VALIDATION (BYPASS TESTS)
-----------------------------------------
| Flow | Expected | Result |
|------|----------|--------|
| Corporate → OT Direct | Block | [ ] PASS [ ] FAIL |
| Corporate → Process Direct | Block | [ ] PASS [ ] FAIL |
| OT → Corporate | Block | [ ] PASS [ ] FAIL |
| Process → Corporate | Block | [ ] PASS [ ] FAIL |
| Internet → PAM | Block | [ ] PASS [ ] FAIL |

FIREWALL RULE VERIFICATION
--------------------------
[ ] Corporate firewall rules verified
[ ] Industrial DMZ rules verified
[ ] Host firewalls consistent

ISSUES IDENTIFIED
-----------------
1. ________________________________________
2. ________________________________________
3. ________________________________________

RECOMMENDATIONS
---------------
1. ________________________________________
2. ________________________________________

SIGN-OFF
--------
Network Team: ______________ Date: ______
Security Team: ______________ Date: ______
OT Team: ______________ Date: ______
```

---

## Section 7: Continuous Validation

### Prometheus Network Monitoring

```yaml
# Prometheus blackbox exporter config
modules:
  tcp_connect:
    prober: tcp
    timeout: 5s

# Prometheus job config
scrape_configs:
  - job_name: 'network_validation'
    metrics_path: /probe
    params:
      module: [tcp_connect]
    static_configs:
      - targets:
          # Allowed flows
          - 10.10.1.100:443  # PAM HTTPS
          - 10.10.1.100:22   # PAM SSH
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - target_label: __address__
        replacement: blackbox-exporter:9115
```

### Alert Rules

```yaml
groups:
  - name: network_segmentation
    rules:
      - alert: PAMUnreachable
        expr: probe_success{job="network_validation",instance=~"10.10.1.100.*"} == 0
        for: 2m
        labels:
          severity: critical
        annotations:
          description: "PAM4OT not reachable on {{ $labels.instance }}"

      - alert: UnexpectedTrafficFlow
        expr: increase(firewall_blocked_packets{src_zone="corporate",dst_zone="ot"}[5m]) > 0
        for: 1m
        labels:
          severity: high
          category: security
        annotations:
          description: "Blocked traffic detected from corporate to OT zone"
```

---

<p align="center">
  <a href="./README.md">← Back to OT Architecture</a>
</p>
