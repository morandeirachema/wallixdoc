# Industrial Protocol Security Validation

## Testing and Validating PAM4OT Industrial Protocol Security Controls

This guide provides procedures for validating PAM4OT security controls on industrial protocols.

---

## Validation Overview

```
+===============================================================================+
|                   INDUSTRIAL PROTOCOL VALIDATION SCOPE                        |
+===============================================================================+

  Protocols Covered                   Validation Types
  =================                   ================

  ┌─────────────────┐                ┌─────────────────┐
  │  Modbus TCP     │                │  Authentication │
  │  Port 502       │                │  Validation     │
  └─────────────────┘                └─────────────────┘

  ┌─────────────────┐                ┌─────────────────┐
  │  DNP3           │                │  Authorization  │
  │  Port 20000     │                │  Testing        │
  └─────────────────┘                └─────────────────┘

  ┌─────────────────┐                ┌─────────────────┐
  │  OPC UA         │                │  Session        │
  │  Port 4840      │                │  Recording      │
  └─────────────────┘                └─────────────────┘

  ┌─────────────────┐                ┌─────────────────┐
  │  EtherNet/IP    │                │  Audit Trail    │
  │  Port 44818     │                │  Verification   │
  └─────────────────┘                └─────────────────┘

  ┌─────────────────┐                ┌─────────────────┐
  │  S7comm         │                │  Command        │
  │  Port 102       │                │  Filtering      │
  └─────────────────┘                └─────────────────┘

+===============================================================================+
```

---

## Pre-Validation Checklist

```
PRE-VALIDATION CHECKLIST
========================

Environment:
[ ] PAM4OT configured for industrial protocols
[ ] Test PLC/RTU/simulator available
[ ] Engineering workstation ready
[ ] Protocol analyzer installed (Wireshark)
[ ] Test user accounts configured
[ ] Approval for testing obtained

Safety:
[ ] Test targets are non-production
[ ] Rollback procedures documented
[ ] Emergency stop procedures known
[ ] Communication with OT team established
```

---

## Section 1: Modbus TCP Validation

### Test Setup

```bash
# Configure Modbus tunnel in PAM4OT
# Target: PLC at 10.10.3.50:502
# PAM4OT proxy: pam4ot.company.com:10502

# Test tools needed:
# - modpoll (Modbus client)
# - pymodbus (Python library)
# - Wireshark with Modbus dissector
```

### Test 1.1: Authentication Enforcement

```bash
# Test: Unauthorized access should be blocked

# 1. Attempt connection without PAM authentication
modpoll -m tcp -a 1 -r 1 -c 10 10.10.3.50

# Expected: Connection refused or no response

# 2. Connect through PAM4OT with valid credentials
modpoll -m tcp -a 1 -r 1 -c 10 pam4ot.company.com:10502

# Expected: Should prompt for PAM4OT authentication first

# 3. Verify in PAM4OT audit log
wabadmin audit search --protocol modbus --last 1h
```

### Test 1.2: Session Recording

```bash
# Test: All Modbus commands should be recorded

# 1. Establish authenticated session through PAM4OT

# 2. Execute various Modbus commands
# Read holding registers
modpoll -m tcp -a 1 -r 1 -c 10 -p 10502 pam4ot.company.com

# Write single register
modpoll -m tcp -a 1 -r 100 -p 10502 pam4ot.company.com 1234

# Read coils
modpoll -m tcp -a 1 -r 1 -c 8 -t 0 -p 10502 pam4ot.company.com

# 3. End session

# 4. Verify recording contains all commands
wabadmin recording show --session-id [session-id]

# Expected: All Modbus function codes visible in recording
```

### Test 1.3: Command Filtering (if configured)

```bash
# Test: Dangerous commands should be blocked

# Configure PAM4OT to block write operations
# (function codes 5, 6, 15, 16)

# 1. Attempt write command
modpoll -m tcp -a 1 -r 100 -p 10502 pam4ot.company.com 9999

# Expected: Command blocked, logged in audit

# 2. Verify read still works
modpoll -m tcp -a 1 -r 1 -c 10 -p 10502 pam4ot.company.com

# Expected: Read succeeds

# 3. Check audit for blocked command
wabadmin audit search --type blocked --protocol modbus
```

### Modbus Validation Results

```
MODBUS TCP VALIDATION RESULTS
=============================

Date: ____________________
Tester: ____________________
PAM4OT Version: ____________________
Test Target: ____________________

Authentication:
[ ] PASS  [ ] FAIL  Direct connection blocked
[ ] PASS  [ ] FAIL  PAM authentication required
[ ] PASS  [ ] FAIL  Failed auth logged

Session Management:
[ ] PASS  [ ] FAIL  Session created correctly
[ ] PASS  [ ] FAIL  Session timeout enforced
[ ] PASS  [ ] FAIL  Session recorded

Audit Trail:
[ ] PASS  [ ] FAIL  All commands logged
[ ] PASS  [ ] FAIL  User identity captured
[ ] PASS  [ ] FAIL  Timestamp accurate

Command Filtering (if applicable):
[ ] PASS  [ ] FAIL  Write commands blocked
[ ] PASS  [ ] FAIL  Read commands allowed
[ ] PASS  [ ] FAIL  Block events logged

Notes:
______________________________________
______________________________________
```

---

## Section 2: DNP3 Validation

### Test Setup

```bash
# Configure DNP3 tunnel in PAM4OT
# Target: RTU at 10.10.3.60:20000
# PAM4OT proxy: pam4ot.company.com:20000

# Test tools:
# - OpenDNP3 simulator/client
# - dnp3-master (testing tool)
# - Wireshark with DNP3 dissector
```

### Test 2.1: DNP3 Authentication

```bash
# Test: DNP3 Secure Authentication enforcement

# 1. Test connection without PAM credentials
# Expected: Connection blocked

# 2. Authenticate through PAM4OT portal
# Expected: Session established

# 3. Verify session in PAM4OT
wabadmin session list --protocol dnp3 --status active
```

### Test 2.2: DNP3 Command Recording

```bash
# Test: DNP3 commands recorded with function codes

# Commands to test:
# - Read class data (polls)
# - Direct operate (CROB)
# - Analog output
# - Time synchronization

# After testing, verify recording:
wabadmin recording show --session-id [session-id] --format detail

# Expected: Each DNP3 function visible with parameters
```

### Test 2.3: DNP3 Control Operation Logging

```bash
# Test: Control operations specifically logged

# 1. Execute control operation (Direct Operate)

# 2. Check audit for control commands
wabadmin audit search --protocol dnp3 --type control-operation

# Expected:
# - Control point address logged
# - Operation type logged
# - User identity recorded
# - Timestamp recorded
```

---

## Section 3: OPC UA Validation

### Test Setup

```bash
# Configure OPC UA endpoint in PAM4OT
# Target: OPC UA Server at opc.tcp://10.10.3.70:4840
# PAM4OT proxy: opc.tcp://pam4ot.company.com:14840

# Test tools:
# - UaExpert (OPC UA client)
# - Python opcua library
# - Wireshark with OPC UA dissector
```

### Test 3.1: OPC UA Authentication

```bash
# Test: OPC UA connection requires PAM authentication

# 1. Test direct connection (should fail)
# Using UaExpert, connect to: opc.tcp://10.10.3.70:4840
# Expected: Network-level block or connection refused

# 2. Connect through PAM4OT
# URL: opc.tcp://pam4ot.company.com:14840
# Should require PAM4OT authentication first

# 3. Verify user mapping
# OPC UA session should show PAM4OT user identity
```

### Test 3.2: OPC UA Node Access Control

```bash
# Test: PAM4OT enforces OPC UA node access policies

# 1. Connect as user with read-only access

# 2. Attempt to write to a node
# Expected: Write rejected, logged

# 3. Attempt to call method
# Expected: Depends on policy

# 4. Verify audit trail
wabadmin audit search --protocol opcua --type authorization
```

### Test 3.3: OPC UA Subscription Recording

```bash
# Test: OPC UA subscriptions are recorded

# 1. Create subscription to nodes
# 2. Receive data changes
# 3. End session

# 4. Verify recording
wabadmin recording show --session-id [session-id]

# Expected: Subscription data visible in recording
```

---

## Section 4: EtherNet/IP Validation

### Test Setup

```bash
# Configure EtherNet/IP tunnel in PAM4OT
# Target: PLC at 10.10.3.80:44818
# PAM4OT proxy: pam4ot.company.com:44818

# Test tools:
# - RSLinx/Studio 5000 (if Allen-Bradley)
# - pycomm3 (Python library)
# - Wireshark with CIP/EtherNet/IP dissector
```

### Test 4.1: CIP Connection Validation

```bash
# Python test script using pycomm3

from pycomm3 import LogixDriver

# Test through PAM4OT proxy
with LogixDriver('pam4ot.company.com/10.10.3.80') as plc:
    # Read tag
    result = plc.read('MyTag')
    print(f"Value: {result.value}")

# Expected: Requires PAM4OT authentication session first
```

### Test 4.2: Tag Read/Write Recording

```bash
# Test: All tag operations recorded

# 1. Perform various operations:
# - Read single tag
# - Read multiple tags
# - Write tag
# - Get controller info

# 2. Verify recording
wabadmin recording show --session-id [session-id]

# Expected: Tag names, values, and operations visible
```

---

## Section 5: S7comm Validation

### Test Setup

```bash
# Configure S7 tunnel in PAM4OT
# Target: Siemens PLC at 10.10.3.90:102
# PAM4OT proxy: pam4ot.company.com:10102

# Test tools:
# - Snap7 client
# - TIA Portal (if available)
# - Wireshark with S7comm dissector
```

### Test 5.1: S7 Authentication

```bash
# Python test using snap7

import snap7

# Connect through PAM4OT proxy
client = snap7.client.Client()
client.connect('pam4ot.company.com', 0, 1, 10102)

# Read data block
data = client.db_read(1, 0, 10)
print(f"Data: {data}")

client.disconnect()
```

### Test 5.2: S7 Operation Recording

```bash
# Test operations to record:
# - DB read
# - DB write
# - Get PLC status
# - Read SZL (System Status List)

# Verify all operations in recording
wabadmin recording show --session-id [session-id]
```

---

## Section 6: Cross-Protocol Validation

### Network Isolation Test

```bash
# Test: Industrial protocols cannot bypass PAM4OT

# 1. From engineering workstation, attempt direct connections:

nc -zv 10.10.3.50 502    # Modbus (should fail)
nc -zv 10.10.3.60 20000  # DNP3 (should fail)
nc -zv 10.10.3.70 4840   # OPC UA (should fail)

# 2. Connections through PAM4OT should work (after auth):
nc -zv pam4ot.company.com 10502  # Modbus via PAM
```

### Session Timeout Test

```bash
# Test: Sessions timeout correctly

# 1. Establish session to industrial target
# 2. Leave session idle
# 3. Verify session terminates after timeout
# 4. Check audit for timeout event

wabadmin audit search --type session-timeout --protocol modbus
```

### Concurrent Session Test

```bash
# Test: Concurrent session limits enforced

# 1. Configure max concurrent sessions (e.g., 2)
# 2. Attempt to establish 3 sessions to same target
# 3. Verify 3rd session blocked or queued
# 4. Check audit

wabadmin audit search --type session-limit
```

---

## Section 7: Audit Trail Validation

### Audit Completeness Check

```bash
#!/bin/bash
# validate-audit.sh - Verify audit trail completeness

PROTOCOL=$1
START_TIME=$2
END_TIME=$3

echo "=== Audit Validation for ${PROTOCOL} ==="
echo "Period: ${START_TIME} to ${END_TIME}"

# Count session events
SESSIONS=$(wabadmin audit search --protocol ${PROTOCOL} \
    --type session --since "${START_TIME}" --until "${END_TIME}" | wc -l)
echo "Session events: ${SESSIONS}"

# Count authentication events
AUTH=$(wabadmin audit search --protocol ${PROTOCOL} \
    --type auth --since "${START_TIME}" --until "${END_TIME}" | wc -l)
echo "Auth events: ${AUTH}"

# Count command events
COMMANDS=$(wabadmin audit search --protocol ${PROTOCOL} \
    --type command --since "${START_TIME}" --until "${END_TIME}" | wc -l)
echo "Command events: ${COMMANDS}"

# Check for gaps
echo ""
echo "Checking for audit gaps..."
wabadmin audit check-gaps --since "${START_TIME}" --until "${END_TIME}"
```

### Syslog Forward Verification

```bash
# Verify industrial protocol events reach SIEM

# 1. Generate test event
modpoll -m tcp -a 1 -r 1 -c 1 -p 10502 pam4ot.company.com

# 2. Check local syslog
grep "modbus" /var/log/wab*/audit.log | tail -5

# 3. Verify received at SIEM
# (Check Splunk/ELK for CEF event with protocol=modbus)
```

---

## Section 8: Validation Report Template

```
INDUSTRIAL PROTOCOL SECURITY VALIDATION REPORT
==============================================

Report Date: ____________________
Validator: ____________________
PAM4OT Version: ____________________
Environment: [ ] Production  [ ] Test

EXECUTIVE SUMMARY
-----------------
Overall Result: [ ] PASS  [ ] CONDITIONAL PASS  [ ] FAIL

Protocols Tested:
[ ] Modbus TCP - Result: ________
[ ] DNP3 - Result: ________
[ ] OPC UA - Result: ________
[ ] EtherNet/IP - Result: ________
[ ] S7comm - Result: ________

DETAILED RESULTS BY PROTOCOL
----------------------------

MODBUS TCP:
- Authentication: [ ] PASS  [ ] FAIL
- Session Recording: [ ] PASS  [ ] FAIL
- Command Filtering: [ ] PASS  [ ] FAIL  [ ] N/A
- Audit Trail: [ ] PASS  [ ] FAIL

DNP3:
- Authentication: [ ] PASS  [ ] FAIL
- Session Recording: [ ] PASS  [ ] FAIL
- Control Logging: [ ] PASS  [ ] FAIL
- Audit Trail: [ ] PASS  [ ] FAIL

OPC UA:
- Authentication: [ ] PASS  [ ] FAIL
- Node Access Control: [ ] PASS  [ ] FAIL
- Subscription Recording: [ ] PASS  [ ] FAIL
- Audit Trail: [ ] PASS  [ ] FAIL

CROSS-PROTOCOL TESTS
--------------------
- Network Isolation: [ ] PASS  [ ] FAIL
- Session Timeout: [ ] PASS  [ ] FAIL
- Concurrent Limits: [ ] PASS  [ ] FAIL
- SIEM Integration: [ ] PASS  [ ] FAIL

ISSUES FOUND
------------
1. ________________________________________
2. ________________________________________
3. ________________________________________

RECOMMENDATIONS
---------------
1. ________________________________________
2. ________________________________________

SIGN-OFF
--------
OT Security Lead: ______________ Date: ______
IT Security Lead: ______________ Date: ______
```

---

## Appendix: Protocol Test Tools

| Protocol | Tool | Purpose | URL |
|----------|------|---------|-----|
| Modbus | modpoll | CLI polling | www.modbusdriver.com |
| Modbus | pymodbus | Python library | pypi.org/project/pymodbus |
| DNP3 | OpenDNP3 | Test framework | github.com/dnp3/opendnp3 |
| OPC UA | UaExpert | GUI client | unified-automation.com |
| OPC UA | python-opcua | Python library | pypi.org/project/opcua |
| EtherNet/IP | pycomm3 | Python library | pypi.org/project/pycomm3 |
| S7comm | snap7 | Library | snap7.sourceforge.net |
| All | Wireshark | Packet analysis | wireshark.org |

---

<p align="center">
  <a href="./README.md">← Back to Industrial Protocols</a>
</p>
