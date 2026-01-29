# OT Protocol Troubleshooting

## Diagnosing Industrial Protocol Issues Through WALLIX

This guide covers troubleshooting for common OT protocols when accessing industrial systems through WALLIX PAM4OT.

---

## Quick Diagnostic Flow

```
+==============================================================================+
|                   OT TROUBLESHOOTING DECISION TREE                            |
+==============================================================================+

  START: OT Connection Problem
            |
            v
  +-------------------+
  | Can you reach     |----NO---> Check network/firewall
  | WALLIX web UI?    |           (Section 1)
  +-------------------+
            | YES
            v
  +-------------------+
  | Can you see       |----NO---> Check authorization
  | target in portal? |           (Section 2)
  +-------------------+
            | YES
            v
  +-------------------+
  | Does session      |----NO---> Check tunnel config
  | establish?        |           (Section 3)
  +-------------------+
            | YES
            v
  +-------------------+
  | Can engineering   |----NO---> Check protocol-specific
  | software connect? |           (Section 4-7)
  +-------------------+
            | YES
            v
  +-------------------+
  | Is performance    |----NO---> Check latency/bandwidth
  | acceptable?       |           (Section 8)
  +-------------------+
            | YES
            v
        RESOLVED

+==============================================================================+
```

---

## Section 1: Network and Firewall Issues

### Symptoms
- Cannot reach WALLIX at all
- Timeout when accessing portal
- "Connection refused" errors

### Diagnostic Steps

```bash
# From engineer workstation:

# 1. Can you ping WALLIX?
ping bastion.company.com

# 2. Can you reach WALLIX web port?
nc -zv bastion.company.com 443

# 3. Can you reach WALLIX SSH proxy?
nc -zv bastion.company.com 22

# 4. Trace the route
traceroute bastion.company.com
```

### Common Issues

| Issue | Cause | Fix |
|-------|-------|-----|
| Ping works, port 443 fails | Firewall blocking HTTPS | Open port 443 from workstation to WALLIX |
| Works from IT, not from OT | OT network segmentation | Add firewall rule for OT network to WALLIX |
| Intermittent connectivity | MTU issues | Reduce MTU: `ping -M do -s 1400 bastion` |

---

## Section 2: Authorization Issues

### Symptoms
- "Access Denied" when trying to connect
- Target not visible in portal
- "No authorizations found"

### Diagnostic Steps

```
In WALLIX Admin UI:

1. Verify user exists:
   Configuration > Users > Search for username

2. Verify user group membership:
   Configuration > Users > [user] > Groups

3. Verify target group:
   Configuration > Target Groups > Check device/account is member

4. Verify authorization exists:
   Configuration > Authorizations > Search
   - User group matches user's group?
   - Target group contains the target?
   - Authorization is active?

5. Check time restrictions:
   Authorization > Time Restrictions
   - Is current time within allowed window?
```

### Common Issues

| Issue | Cause | Fix |
|-------|-------|-----|
| User not in correct group | LDAP group mapping | Fix LDAP group mapping or manually add to group |
| Target not in target group | Missing account | Add account to target group |
| Works during day, not at night | Time restriction | Modify time restrictions or request exception |

---

## Section 3: Tunnel Configuration Issues

### Symptoms
- WALLIX session starts but tunnel doesn't work
- Engineering software can't connect through tunnel
- "Connection refused" on local port

### Diagnostic Steps

```bash
# On WALLIX server (via SSH admin access):

# 1. Check tunnel is established
ss -tuln | grep LISTEN

# 2. Look for tunnel process
ps aux | grep ssh | grep tunnel

# 3. Check tunnel logs
tail -f /var/log/wabsessions/sessions.log | grep tunnel

# 4. Test tunnel connectivity
nc -zv localhost [local-port]
```

### Common Issues

| Issue | Cause | Fix |
|-------|-------|-----|
| Local port not listening | Tunnel not configured | Add tunnel in service configuration |
| Port already in use | Another process using port | Change local port or stop conflicting process |
| Remote port unreachable | Firewall between WALLIX and target | Open port from WALLIX to target |

### Tunnel Configuration Verification

```
Check in WALLIX Admin UI:

Configuration > Devices > [device] > Services > [service]

Tunnel Settings:
- Tunneling Enabled: [x]
- Local Port: 102 (for S7comm)
- Remote Host: [PLC IP or hostname]
- Remote Port: 102
```

---

## Section 4: Modbus TCP Troubleshooting

### Symptoms
- Modbus client can't connect
- "Device not responding"
- Timeout errors in Modbus software

### Diagnostic Steps

```bash
# 1. Verify Modbus port in tunnel config
# Default: 502

# 2. Test raw Modbus connectivity (from WALLIX server)
nc -zv [plc-ip] 502

# 3. Use modbus tool to test
# Install: apt install mbpoll (if available)
mbpoll -a 1 -r 1 -c 10 [plc-ip]

# 4. Check for Modbus response
tcpdump -i any port 502 -A
```

### Common Modbus Issues

| Issue | Cause | Fix |
|-------|-------|-----|
| Connection timeout | Wrong IP or port | Verify PLC IP and port 502 |
| "Illegal function" error | PLC doesn't support function | Check PLC documentation for supported functions |
| Intermittent failures | Network congestion | Check OT network quality |
| Multiple units fail | Broadcast storm | Check for network loops |

### Modbus Tunnel Configuration

```
WALLIX Tunnel Settings for Modbus:

Service: SSH Tunnel
Local Port: 502
Remote Host: 192.168.50.10 (PLC IP)
Remote Port: 502

Engineering Software Configuration:
- Connect to: localhost:502
- Unit ID: [as per PLC config, usually 1]
```

---

## Section 5: OPC UA Troubleshooting

### Symptoms
- OPC UA client shows "BadSecurityChecksFailed"
- "BadConnectionClosed" immediately after connect
- Certificate errors

### Diagnostic Steps

```bash
# 1. Verify OPC UA port (default 4840)
nc -zv [server-ip] 4840

# 2. Check OPC UA server endpoints
# Using opcua-commander (if available)
opcua-commander -e opc.tcp://[server-ip]:4840

# 3. Check certificate issues
openssl s_client -connect [server-ip]:4840

# 4. Test with UaExpert (free OPC UA client)
# Connect through tunnel: opc.tcp://localhost:4840
```

### Common OPC UA Issues

| Issue | Cause | Fix |
|-------|-------|-----|
| BadSecurityChecksFailed | Certificate not trusted | Import client cert to server trust store |
| BadIdentityTokenRejected | Wrong credentials | Verify username/password |
| BadTcpEndpointUrlInvalid | Wrong endpoint URL | Check server configuration for correct endpoint |
| Connection closes immediately | Security policy mismatch | Match security policy (None, Sign, SignAndEncrypt) |

### OPC UA Tunnel Configuration

```
WALLIX Tunnel Settings for OPC UA:

Service: SSH Tunnel
Local Port: 4840
Remote Host: 192.168.60.10 (OPC UA Server)
Remote Port: 4840

Client Configuration:
- Endpoint: opc.tcp://localhost:4840
- Security Policy: [Match server]
- User Authentication: [As configured]
```

### OPC UA Security Modes

```
+==============================================================================+
|                   OPC UA SECURITY MODES                                       |
+==============================================================================+

  Mode: None (insecure)
  - Use for: Testing only
  - WALLIX handles: Transport security

  Mode: Sign
  - Use for: Authentication without encryption
  - Certificates: Required on both sides

  Mode: SignAndEncrypt
  - Use for: Production OT environments
  - Certificates: Required
  - Note: May conflict with WALLIX recording

  Recommendation for WALLIX:
  - Use SignAndEncrypt between WALLIX and OPC UA server
  - WALLIX proxies the TLS connection
  - Recording captures the session data

+==============================================================================+
```

---

## Section 6: Siemens S7comm Troubleshooting

### Symptoms
- TIA Portal can't connect to PLC
- "Connection to device failed"
- Offline mode only

### Diagnostic Steps

```bash
# 1. Verify S7comm port (default 102)
nc -zv [plc-ip] 102

# 2. Check PLC is responding on S7
# S7 uses ISO-on-TCP (RFC1006)
# Simple test: look for connection acceptance
timeout 5 bash -c 'echo -ne "\x03\x00\x00\x16\x11\xe0\x00\x00\x00\x01\x00\xc0\x01\x0a\xc1\x02\x01\x00\xc2\x02\x01\x02" | nc [plc-ip] 102'

# 3. Verify tunnel is working
ss -tuln | grep 102
```

### Common S7comm Issues

| Issue | Cause | Fix |
|-------|-------|-----|
| "No route to station" | Wrong rack/slot | Check PLC settings (usually rack 0, slot 1) |
| Connection refused | CPU in STOP | Check PLC mode |
| Timeout | Firewall | Open port 102 |
| "Insufficient rights" | PLC access protection | Check PLC security settings |

### TIA Portal Configuration Through WALLIX

```
1. Configure WALLIX Tunnel:
   - Local Port: 102
   - Remote: PLC IP:102

2. In TIA Portal:
   - Device > Properties > General > PROFINET interface
   - IP Address: 127.0.0.1 (localhost)

   Or use PG/PC interface:
   - Options > Settings > PG/PC Interface
   - Interface: TCP/IP
   - Address: 127.0.0.1

3. Common TIA Portal errors through tunnel:
   - "No connection": Check tunnel is established
   - "Wrong type": Ensure correct PLC type selected
```

### S7comm Protocol Details

```
+==============================================================================+
|                   S7COMM PROTOCOL REFERENCE                                   |
+==============================================================================+

  Port: 102 (ISO-TSAP)

  Communication types:
  - PG Communication (programming)
  - OP Communication (HMI)
  - S7 Basic Communication

  Common subfunction codes:
  0x04 = Read variable
  0x05 = Write variable
  0x00 = CPU services
  0x29 = Block transfer

  For S7-1500 (S7comm+):
  - Uses TLS by default
  - May require certificate import

+==============================================================================+
```

---

## Section 7: EtherNet/IP (Rockwell) Troubleshooting

### Symptoms
- RSLinx can't find controller
- Studio 5000 can't go online
- "Path does not exist"

### Diagnostic Steps

```bash
# 1. Verify EtherNet/IP port (default 44818)
nc -zv [plc-ip] 44818

# 2. Also check secondary port
nc -zv [plc-ip] 2222

# 3. Test with simple CIP identity request
# (requires specialized tool)
```

### Common EtherNet/IP Issues

| Issue | Cause | Fix |
|-------|-------|-----|
| "No controller found" | Browse doesn't work through NAT | Use direct IP path |
| "Path does not exist" | Wrong IP or slot | Verify IP and chassis slot |
| Upload/download fails | Large packet dropped | Check MTU settings |
| Intermittent drops | Keepalive timeout | Increase connection timeout |

### RSLinx Configuration Through WALLIX

```
1. Configure WALLIX Tunnel:
   - Local Port: 44818
   - Remote: ControlLogix IP:44818

   Additional tunnel if needed:
   - Local Port: 2222
   - Remote: ControlLogix IP:2222

2. In RSLinx:
   - Configure Drivers > EtherNet/IP Driver > Add New
   - Driver Name: WALLIX_Tunnel
   - Browse Local Subnet: UNCHECK
   - Specify IP: 127.0.0.1 (localhost)

3. If browse required:
   - May need to tunnel broadcast
   - Or use direct path in Studio 5000

4. Studio 5000 direct path:
   - Controller Properties > Path
   - 127.0.0.1\Backplane\0 (adjust slot as needed)
```

---

## Section 8: Performance Issues

### Symptoms
- Slow response from PLC
- Engineering software lags
- Downloads timeout

### Diagnostic Steps

```bash
# 1. Check latency to WALLIX
ping -c 100 bastion.company.com | tail -5

# 2. Check latency from WALLIX to target
# (on WALLIX server)
ping -c 100 [plc-ip] | tail -5

# 3. Check for packet loss
mtr bastion.company.com -c 100

# 4. Check WALLIX server load
top -bn1 | head -5

# 5. Check tunnel throughput
# Start iperf server on target network
iperf3 -c [target-ip]
```

### Performance Benchmarks

```
+==============================================================================+
|                   EXPECTED LATENCY FOR OT PROTOCOLS                           |
+==============================================================================+

  Protocol        | Direct  | Through WALLIX | Acceptable
  ----------------|---------|----------------|------------
  Modbus TCP      | <10ms   | <50ms          | <100ms
  OPC UA          | <20ms   | <100ms         | <200ms
  S7comm          | <10ms   | <50ms          | <100ms
  EtherNet/IP     | <10ms   | <50ms          | <100ms

  If latency exceeds acceptable:
  1. Check WALLIX server resources
  2. Check network path quality
  3. Consider dedicated WALLIX for OT

+==============================================================================+
```

### Optimizing Tunnel Performance

```
1. Use dedicated tunnels per protocol
   - Don't mix Modbus and S7 on same tunnel

2. Check WALLIX server sizing
   - OT sessions need consistent latency
   - Don't overload with IT sessions

3. Network optimization
   - Place WALLIX close to OT network
   - Minimize hops between WALLIX and PLCs
   - Use dedicated VLAN for WALLIX-to-OT traffic

4. If using HA cluster
   - Ensure active node is closest to OT network
   - Configure affinity if possible
```

---

## Protocol-Specific Quick Reference

### Port Summary

| Protocol | Default Port | Description |
|----------|--------------|-------------|
| Modbus TCP | 502 | Modbus over TCP |
| OPC UA | 4840 | OPC Unified Architecture |
| S7comm | 102 | Siemens S7 (ISO-TSAP) |
| EtherNet/IP | 44818 | Rockwell/Allen-Bradley |
| DNP3 | 20000 | Distributed Network Protocol |
| IEC 61850 MMS | 102 | Substation communication |
| BACnet/IP | 47808 | Building automation |
| PROFINET | 34962-34964 | Siemens industrial Ethernet |

### Quick Test Commands

```bash
# Test any TCP port
nc -zv [ip] [port]

# Test with timeout
timeout 5 nc -zv [ip] [port]

# Continuous monitoring
watch -n 1 "nc -zv [ip] [port]"

# Capture traffic for analysis
tcpdump -i any port [port] -w capture.pcap

# View Modbus traffic
tcpdump -i any port 502 -A

# View S7 traffic
tcpdump -i any port 102 -X
```

---

## Escalation Checklist

When opening a support ticket, gather:

```
[ ] WALLIX version (System > About)
[ ] Target device type and firmware version
[ ] Engineering software name and version
[ ] Network diagram between workstation -> WALLIX -> target
[ ] Error message (exact text or screenshot)
[ ] Timestamp of failure
[ ] Steps to reproduce
[ ] Relevant logs from /var/log/wabsessions/
[ ] tcpdump capture if possible
```

---

<p align="center">
  <a href="./README.md">Troubleshooting Overview</a> •
  <a href="../17-industrial-protocols/README.md">Industrial Protocols</a> •
  <a href="../18-scada-ics-access/README.md">SCADA/ICS Access</a>
</p>
