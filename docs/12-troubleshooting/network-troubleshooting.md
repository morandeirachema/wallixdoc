# Network Troubleshooting Guide

## Diagnosing Connectivity and Network Issues

This guide covers troubleshooting network-related problems with PAM4OT.

---

## Quick Diagnosis Flowchart

```
+===============================================================================+
|                    NETWORK TROUBLESHOOTING FLOWCHART                          |
+===============================================================================+

  Users cannot reach PAM4OT?
            |
            v
  +-------------------+
  | Is VIP responding |     NO
  | to ping?          |-----------> Check VIP/Load Balancer
  +-------------------+
            | YES
            v
  +-------------------+
  | Is HTTPS (443)    |     NO
  | responding?       |-----------> Check PAM4OT service/firewall
  +-------------------+
            | YES
            v
  +-------------------+
  | Can PAM4OT reach  |     NO
  | target systems?   |-----------> Check routing/target firewall
  +-------------------+
            | YES
            v
  Check application layer (auth, sessions)

+===============================================================================+
```

---

## Section 1: VIP/Load Balancer Issues

### VIP Not Responding

```bash
# Step 1: Check if VIP is assigned
ip addr show | grep 10.10.1.100

# Step 2: If not assigned, check Pacemaker
pcs status

# Step 3: Check which node should have VIP
pcs resource show vip-pam4ot

# Step 4: If VIP stuck, force move
pcs resource move vip-pam4ot [node-name]
pcs resource clear vip-pam4ot  # Remove constraint after move
```

### Load Balancer Health Check Failing

```bash
# Check what health check the LB uses
# Common: GET / or GET /health

# Test health endpoint
curl -sk https://pam4ot-node1.company.com/
curl -sk https://pam4ot-node1.company.com/health

# If returns error, check PAM4OT service
systemctl status wallix-bastion

# Check LB can reach backend
# On LB:
nc -zv pam4ot-node1.company.com 443
nc -zv pam4ot-node2.company.com 443
```

---

## Section 2: Firewall Issues

### Verify Firewall Rules

```bash
# On PAM4OT nodes, check iptables
iptables -L -n --line-numbers

# Check if traffic is being dropped
iptables -L -n -v | grep DROP

# Check specific port is allowed
iptables -L -n | grep 443
iptables -L -n | grep 22
```

### Required Ports Checklist

| Source | Destination | Port | Protocol | Test Command |
|--------|-------------|------|----------|--------------|
| Users | PAM4OT VIP | 443 | TCP | `curl -sk https://10.10.1.100/` |
| Users | PAM4OT VIP | 22 | TCP | `nc -zv 10.10.1.100 22` |
| PAM4OT | AD DC | 636 | TCP | `nc -zv dc-lab 636` |
| PAM4OT | AD DC | 88 | TCP/UDP | `nc -zv dc-lab 88` |
| PAM4OT | FortiAuth | 1812 | UDP | `nc -zuv fortiauth 1812` |
| PAM4OT | SIEM | 514 | TCP | `nc -zv siem-lab 514` |
| PAM4OT | Targets | 22 | TCP | `nc -zv linux-test 22` |
| PAM4OT | Targets | 3389 | TCP | `nc -zv windows-test 3389` |
| Node1 | Node2 | 5432 | TCP | `nc -zv node2 5432` |
| Node1 | Node2 | 5405 | UDP | `nc -zuv node2 5405` |

### Test All Ports Script

```bash
#!/bin/bash
# test-ports.sh - Test all required PAM4OT ports

echo "=== Testing PAM4OT Network Connectivity ==="

# VIP
echo -n "VIP HTTPS (443): "
nc -zv -w2 10.10.1.100 443 2>&1 | grep -q succeeded && echo "OK" || echo "FAILED"

echo -n "VIP SSH (22): "
nc -zv -w2 10.10.1.100 22 2>&1 | grep -q succeeded && echo "OK" || echo "FAILED"

# AD
echo -n "AD LDAPS (636): "
nc -zv -w2 dc-lab.company.com 636 2>&1 | grep -q succeeded && echo "OK" || echo "FAILED"

echo -n "AD Kerberos (88): "
nc -zv -w2 dc-lab.company.com 88 2>&1 | grep -q succeeded && echo "OK" || echo "FAILED"

# FortiAuth
echo -n "FortiAuth RADIUS (1812): "
nc -zuv -w2 fortiauth.company.com 1812 2>&1 | grep -q succeeded && echo "OK" || echo "FAILED"

# SIEM
echo -n "SIEM Syslog (514): "
nc -zv -w2 siem.company.com 514 2>&1 | grep -q succeeded && echo "OK" || echo "FAILED"

# Cluster
echo -n "PostgreSQL Replication: "
nc -zv -w2 pam4ot-node2.company.com 5432 2>&1 | grep -q succeeded && echo "OK" || echo "FAILED"

# Targets
echo -n "Linux Target (22): "
nc -zv -w2 linux-test.company.com 22 2>&1 | grep -q succeeded && echo "OK" || echo "FAILED"

echo -n "Windows Target (3389): "
nc -zv -w2 windows-test.company.com 3389 2>&1 | grep -q succeeded && echo "OK" || echo "FAILED"
```

---

## Section 3: DNS Issues

### DNS Resolution Failing

```bash
# Test DNS resolution
nslookup pam4ot.company.com
dig pam4ot.company.com

# Test from PAM4OT node
nslookup dc-lab.company.com
nslookup fortiauth.company.com

# Check DNS servers configured
cat /etc/resolv.conf

# Test specific DNS server
nslookup pam4ot.company.com 10.10.1.10
```

### Common DNS Problems

| Symptom | Cause | Solution |
|---------|-------|----------|
| "server can't find" | Record doesn't exist | Add DNS record |
| "connection timed out" | DNS server unreachable | Check DNS server |
| Wrong IP returned | Stale DNS cache | Flush cache |
| Intermittent resolution | Multiple DNS servers inconsistent | Sync DNS servers |

### Fix DNS Issues

```bash
# Flush local DNS cache
systemd-resolve --flush-caches

# Test reverse DNS
nslookup 10.10.1.100
dig -x 10.10.1.100

# If DNS unreliable, add to /etc/hosts temporarily
echo "10.10.1.100 pam4ot.company.com pam4ot" >> /etc/hosts
```

---

## Section 4: Session Connectivity Issues

### SSH Sessions Failing

```bash
# Test SSH proxy
ssh -v jadmin@pam4ot.company.com

# If connection refused, check:
# 1. SSH service running
systemctl status wallix-bastion | grep ssh

# 2. SSH port open
ss -tlnp | grep :22

# 3. Test from PAM4OT to target
# (On PAM4OT node)
ssh -v root@linux-test.company.com
```

### RDP Sessions Failing

```bash
# Test RDP port on PAM4OT
nc -zv pam4ot.company.com 3389

# Test from PAM4OT to target
nc -zv windows-test.company.com 3389

# Check RDP service on target
# (On Windows target)
netstat -an | findstr 3389
```

### Session Disconnections

```bash
# Check for network instability
ping -c 100 pam4ot.company.com | grep -E "loss|time"

# Check MTU issues
ping -M do -s 1472 pam4ot.company.com

# If MTU issue (packet too large)
# Reduce MTU on PAM4OT interface
ip link set dev ens192 mtu 1400
```

---

## Section 5: SSL/TLS Issues

### Certificate Errors

```bash
# Check certificate
echo | openssl s_client -connect pam4ot.company.com:443 2>/dev/null | \
  openssl x509 -noout -subject -dates -issuer

# Check certificate chain
echo | openssl s_client -connect pam4ot.company.com:443 -showcerts 2>/dev/null

# Check specific errors
echo | openssl s_client -connect pam4ot.company.com:443 2>&1 | grep -i error
```

### Common Certificate Issues

| Error | Cause | Solution |
|-------|-------|----------|
| "certificate has expired" | Cert expired | Renew certificate |
| "unable to get local issuer" | CA not trusted | Import CA cert |
| "hostname mismatch" | Wrong CN/SAN | Update certificate |
| "self-signed certificate" | Self-signed | Import to trust store |

### Import CA Certificate

```bash
# Copy CA cert to trust store
cp company-ca.crt /usr/local/share/ca-certificates/
update-ca-certificates

# Verify
openssl verify -CApath /etc/ssl/certs/ /path/to/server.crt
```

---

## Section 6: Performance Issues

### High Latency

```bash
# Test network latency
ping -c 20 pam4ot.company.com
mtr pam4ot.company.com

# Test application response time
curl -sk -o /dev/null -w "Connect: %{time_connect}s, TTFB: %{time_starttransfer}s, Total: %{time_total}s\n" https://pam4ot.company.com/

# Compare node performance
for node in pam4ot-node1 pam4ot-node2; do
  echo -n "$node: "
  curl -sk -o /dev/null -w "%{time_total}s\n" https://$node.company.com/
done
```

### Bandwidth Issues

```bash
# Test bandwidth to PAM4OT
iperf3 -c pam4ot-node1.company.com -p 5201

# Check network interface stats
ip -s link show ens192

# Check for errors/drops
netstat -i
cat /proc/net/dev
```

### TCP Connection Issues

```bash
# Check TCP connections
ss -s
ss -tn | wc -l

# Check for connection states
ss -tn state time-wait | wc -l
ss -tn state established | wc -l

# If too many TIME_WAIT connections
cat /proc/sys/net/ipv4/tcp_fin_timeout
# Consider reducing if very high
```

---

## Section 7: Packet Capture

### Capture Traffic for Analysis

```bash
# Capture all traffic on interface
tcpdump -i ens192 -w /tmp/capture.pcap

# Capture specific port
tcpdump -i ens192 port 443 -w /tmp/https.pcap

# Capture specific host
tcpdump -i ens192 host 10.10.1.50 -w /tmp/siem.pcap

# Capture with content
tcpdump -i ens192 port 514 -A

# Stop after N packets
tcpdump -i ens192 -c 100 -w /tmp/sample.pcap
```

### Analyze with tshark

```bash
# Summary of capture
tshark -r /tmp/capture.pcap -q -z io,stat,1

# Filter specific traffic
tshark -r /tmp/capture.pcap -Y "tcp.port == 443"

# Show conversation statistics
tshark -r /tmp/capture.pcap -q -z conv,tcp
```

---

## Section 8: Network Troubleshooting Checklist

```
NETWORK TROUBLESHOOTING CHECKLIST
=================================

LAYER 1 - PHYSICAL
[ ] Network cable connected
[ ] Link lights active
[ ] Switch port enabled
[ ] No speed/duplex mismatch

LAYER 2 - DATA LINK
[ ] VLAN correctly assigned
[ ] MAC address learned by switch
[ ] No spanning tree issues
[ ] ARP resolving correctly

LAYER 3 - NETWORK
[ ] IP address configured correctly
[ ] Subnet mask correct
[ ] Default gateway reachable
[ ] Routing table correct
[ ] No IP conflicts

LAYER 4 - TRANSPORT
[ ] Required ports open
[ ] Firewall rules correct
[ ] No connection limits hit
[ ] TCP connections establishing

LAYER 7 - APPLICATION
[ ] PAM4OT service running
[ ] HTTPS responding
[ ] Authentication working
[ ] Sessions establishing
```

---

## Appendix: Useful Commands

```bash
# Network configuration
ip addr show
ip route show
cat /etc/resolv.conf

# Connection testing
ping [host]
traceroute [host]
mtr [host]
nc -zv [host] [port]

# Port checking
ss -tlnp  # TCP listening
ss -ulnp  # UDP listening
ss -tn    # TCP connections

# Firewall
iptables -L -n
iptables -L -n -v

# DNS
nslookup [host]
dig [host]
host [host]

# SSL/TLS
openssl s_client -connect [host]:443
curl -vk https://[host]/

# Packet capture
tcpdump -i [interface]
tshark -i [interface]

# Performance
iperf3 -c [host]
ping -f [host]  # Flood ping (careful!)
```

---

<p align="center">
  <a href="./README.md">← Back to Troubleshooting</a>
</p>
