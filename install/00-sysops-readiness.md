# Sysops Readiness Checklist

## Pre-Deployment Verification for WALLIX PAM4OT

Complete this checklist BEFORE starting WALLIX installation. Each item prevents common deployment failures.

---

## 1. Network Infrastructure (30 minutes)

### DNS Verification

```bash
# Verify forward DNS resolution
nslookup wallix.company.com
# Expected: Returns IP address of WALLIX server

# Verify reverse DNS resolution
nslookup <wallix-ip>
# Expected: Returns wallix.company.com

# Test from client machine
nslookup wallix.company.com
# Expected: Same result as above

# Verify DNS for all target servers
for target in srv1 srv2 plc1 hmi1; do
  echo "Testing $target:"
  nslookup $target.company.com
done
```

**Why it matters**: DNS failures cause authentication issues, certificate problems, and session establishment failures.

### Network Connectivity

```bash
# Test connectivity to target servers
for port in 22 3389 5900; do
  echo "Testing port $port..."
  nc -zv target-server $port
done

# Test from WALLIX server to targets
ping -c 3 target-server
traceroute target-server

# Verify no packet loss under load
ping -c 100 -i 0.1 target-server | tail -3

# Check MTU (important for RDP)
ping -M do -s 1472 target-server
# If fails, MTU issues exist - reduce by 28 until it works
```

### Firewall Rules Verification

```
+===============================================================================+
|                   REQUIRED FIREWALL RULES                                    |
+===============================================================================+

  INBOUND TO WALLIX
  =================

  +------------------------------------------------------------------------+
  | Source          | Port       | Protocol | Purpose                       |
  +-----------------+------------+----------+-------------------------------+
  | Users           | 443        | TCP      | Web UI, API                   |
  | Users           | 22         | TCP      | SSH proxy                     |
  | Users           | 3389       | TCP      | RDP proxy                     |
  | Users           | 5900       | TCP      | VNC proxy                     |
  | Admin hosts     | 22         | TCP      | SSH admin access              |
  | Cluster peer    | 3306       | TCP      | MariaDB replication        |
  | Cluster peer    | 5404-5406  | UDP      | Corosync cluster sync         |
  +-----------------+------------+----------+-------------------------------+

  OUTBOUND FROM WALLIX
  ====================

  +------------------------------------------------------------------------+
  | Destination     | Port       | Protocol | Purpose                       |
  +-----------------+------------+----------+-------------------------------+
  | Target servers  | 22         | TCP      | SSH to targets                |
  | Target servers  | 3389       | TCP      | RDP to targets                |
  | Target servers  | 5900       | TCP      | VNC to targets                |
  | Target servers  | 23         | TCP      | Telnet to targets             |
  | Target servers  | 502        | TCP      | Modbus TCP (OT)               |
  | Target servers  | 4840       | TCP      | OPC UA (OT)                   |
  | LDAP servers    | 389/636    | TCP      | LDAP/LDAPS authentication     |
  | RADIUS servers  | 1812       | UDP      | RADIUS MFA                    |
  | NTP servers     | 123        | UDP      | Time synchronization          |
  | DNS servers     | 53         | TCP/UDP  | Name resolution               |
  | SIEM            | 514/6514   | TCP/UDP  | Syslog forwarding             |
  +-----------------+------------+----------+-------------------------------+

+===============================================================================+
```

**Verification commands:**
```bash
# Test outbound connectivity
nc -zv ldap-server 636
nc -zv target-server 22
nc -zv target-server 3389
```

---

## 2. Time Synchronization (10 minutes)

### NTP Configuration

```bash
# Check current time sync status
timedatectl status

# Expected output should show:
#   NTP synchronized: yes
#   System clock synchronized: yes

# Check NTP servers
chronyc sources -v
# or
ntpq -p

# Verify time offset is < 1 second
chronyc tracking | grep "System time"
# Should show offset in milliseconds, not seconds

# Force NTP sync (if needed)
chronyc makestep
```

**Why it matters**:
- TOTP MFA fails if clock skew > 30 seconds
- Kerberos authentication fails if skew > 5 minutes
- Session timestamps become unreliable for audit

### Time Zone Configuration

```bash
# Set correct timezone
timedatectl set-timezone America/New_York

# Verify
date
timedatectl
```

---

## 3. Storage Verification (15 minutes)

### Disk Space Requirements

```
+===============================================================================+
|                   MINIMUM STORAGE REQUIREMENTS                               |
+===============================================================================+

  +------------------------------------------------------------------------+
  | Mount Point         | Minimum  | Recommended | Purpose                  |
  +---------------------+----------+-------------+--------------------------+
  | / (root)            | 20 GB    | 50 GB       | OS and applications      |
  | /var/lib/wallix     | 100 GB   | 500 GB      | Database, recordings     |
  | /var/log            | 20 GB    | 50 GB       | Log files                |
  | /var/backup         | 100 GB   | 200 GB      | Backups                  |
  +---------------------+----------+-------------+--------------------------+

  RECORDING STORAGE ESTIMATION
  ============================

  Per concurrent session:
  - SSH (text): ~5-20 MB/hour
  - SSH (full): ~20-80 MB/hour
  - RDP (standard): ~100-200 MB/hour
  - RDP (HD video): ~200-500 MB/hour

  Example: 50 concurrent RDP sessions, 8 hours/day, 30-day retention
  = 50 x 200 MB x 8 x 30 = 2.4 TB

+===============================================================================+
```

### Verification Commands

```bash
# Check current disk space
df -h

# Check for separate mount points
mount | grep -E "(wallix|backup|log)"

# Verify disk performance (important for recordings)
dd if=/dev/zero of=/var/lib/wallix/test.file bs=1G count=1 oflag=direct
# Should complete in < 10 seconds for SSD

# Clean up test file
rm /var/lib/wallix/test.file

# Check inode availability
df -i
```

---

## 4. System Resources (10 minutes)

### CPU and Memory

```bash
# Check CPU
lscpu | grep -E "(^CPU\(s\)|Thread|Core|Model name)"
# Minimum: 4 cores, Recommended: 8+ cores

# Check memory
free -h
# Minimum: 8 GB, Recommended: 16+ GB

# Check for memory pressure
cat /proc/meminfo | grep -E "(MemTotal|MemAvailable|SwapTotal)"

# Verify no swap usage (swap = performance problems)
swapon --show
# Ideally empty or swap usage < 1%
```

### System Limits

```bash
# Check file descriptor limits
ulimit -n
# Should be at least 65536

# If too low, edit /etc/security/limits.conf:
# wallix soft nofile 65536
# wallix hard nofile 65536

# Check max processes
ulimit -u
# Should be at least 4096
```

---

## 5. Authentication Infrastructure (20 minutes)

### LDAP/AD Connectivity Test

```bash
# Test LDAP connectivity
ldapsearch -x -H ldap://dc.company.com:389 \
  -D "CN=wallix-svc,OU=Service,DC=company,DC=com" \
  -W -b "DC=company,DC=com" \
  "(sAMAccountName=testuser)"

# Test LDAPS (secure)
ldapsearch -x -H ldaps://dc.company.com:636 \
  -D "CN=wallix-svc,OU=Service,DC=company,DC=com" \
  -W -b "DC=company,DC=com" \
  "(sAMAccountName=testuser)"

# If LDAPS fails, check certificate
echo | openssl s_client -connect dc.company.com:636 2>/dev/null | \
  openssl x509 -noout -subject -dates
```

**Checklist:**
- [ ] LDAP service account created
- [ ] Service account has read access to user objects
- [ ] Service account password documented securely
- [ ] LDAPS certificate trusted (or added to trust store)

### RADIUS/MFA Test (if applicable)

```bash
# Test RADIUS connectivity
radtest testuser testpassword radius-server 1812 shared-secret

# Expected: Access-Accept or Access-Challenge (for MFA)
```

---

## 6. Target Server Preparation (20 minutes)

### SSH Targets

```bash
# Test SSH connectivity from WALLIX server
ssh -o BatchMode=yes -o ConnectTimeout=5 root@target-server echo "OK"

# Verify SSH version (should be SSHv2)
ssh -v root@target-server 2>&1 | grep "Remote protocol version"

# Check SSH key authentication (if using)
ssh -i /path/to/key -o BatchMode=yes root@target-server echo "OK"
```

### RDP Targets

```bash
# Test RDP port connectivity
nc -zv windows-server 3389

# Verify NLA settings (Network Level Authentication)
# NLA must be enabled for secure RDP proxying
```

### Windows Target Checklist

- [ ] RDP enabled
- [ ] NLA (Network Level Authentication) enabled
- [ ] Firewall allows RDP from WALLIX IP
- [ ] Service account created for password rotation
- [ ] Service account has local admin rights (for rotation)

### Linux Target Checklist

- [ ] SSH enabled and running
- [ ] Root login permitted (or sudo account available)
- [ ] Firewall allows SSH from WALLIX IP
- [ ] Service account created for password rotation
- [ ] Service account has sudo NOPASSWD for passwd command

---

## 7. Certificate Preparation (15 minutes)

### SSL Certificate Requirements

```
+===============================================================================+
|                   CERTIFICATE REQUIREMENTS                                   |
+===============================================================================+

  WEB INTERFACE CERTIFICATE
  =========================

  - Subject/CN: wallix.company.com (or *.company.com)
  - SANs: Include all DNS names users will use
  - Key Size: 2048-bit RSA minimum, 4096-bit recommended
  - Validity: 1-2 years recommended
  - Format: PEM (certificate + private key)

  CERTIFICATE CHAIN
  =================

  Ensure you have:
  1. Server certificate (wallix.company.com.crt)
  2. Intermediate CA certificate(s)
  3. Private key (wallix.company.com.key)

  If using internal CA, ensure CA is trusted on all client machines.

+===============================================================================+
```

### Certificate Verification

```bash
# Verify certificate and key match
openssl x509 -noout -modulus -in server.crt | openssl md5
openssl rsa -noout -modulus -in server.key | openssl md5
# Both MD5 hashes must match

# Check certificate details
openssl x509 -in server.crt -noout -text | grep -A1 "Subject:"
openssl x509 -in server.crt -noout -dates

# Verify certificate chain
openssl verify -CAfile ca-chain.crt server.crt
```

---

## 8. Backup Infrastructure (10 minutes)

### Backup Storage

```bash
# Verify backup destination is accessible
ls -la /var/backup/wallix/

# Or if using NFS
mount | grep backup
df -h /mnt/backup

# Test write access
touch /var/backup/wallix/test.txt && rm /var/backup/wallix/test.txt
```

### Backup Schedule Planning

| Backup Type | Frequency | Retention | Storage Needed |
|-------------|-----------|-----------|----------------|
| Database | Daily | 30 days | ~50 GB |
| Configuration | Daily | 30 days | ~1 GB |
| Recordings | Weekly archive | 1 year | Varies |
| Full system | Weekly | 4 weeks | ~200 GB |

---

## 9. Monitoring Infrastructure (10 minutes)

### Syslog Destination

```bash
# Test syslog connectivity
logger -n siem-server -P 514 "WALLIX test message"

# Verify message received on SIEM
# (Check SIEM interface)

# For TLS syslog
openssl s_client -connect siem-server:6514
```

### SNMP (if applicable)

```bash
# Test SNMP connectivity
snmpwalk -v2c -c public monitoring-server 1.3.6.1.2.1.1.1
```

---

## 10. Emergency Access Planning (15 minutes)

### Break-Glass Procedure

```
+===============================================================================+
|                   EMERGENCY ACCESS PROCEDURE                                 |
+===============================================================================+

  DOCUMENT BEFORE DEPLOYMENT
  ==========================

  If WALLIX is completely unavailable:

  1. AUTHORIZATION
     - Who can authorize emergency access?
     - Phone numbers for emergency authorization

  2. CREDENTIALS
     - Where are emergency credentials stored?
     - Physical safe? Password manager? Sealed envelope?

  3. ACCESS METHOD
     - Direct SSH/RDP to targets (bypassing WALLIX)
     - Console access for critical systems

  4. DOCUMENTATION
     - How to document emergency access used
     - Who to notify after emergency access

  5. POST-INCIDENT
     - Password rotation after emergency access
     - Incident report requirements

+===============================================================================+
```

### Emergency Contact List

| Role | Name | Phone | Email |
|------|------|-------|-------|
| WALLIX Primary Admin | | | |
| WALLIX Backup Admin | | | |
| Security Team | | | |
| Network Team | | | |
| Management Escalation | | | |

---

## Pre-Installation Sign-Off

### Checklist Summary

| Category | Status | Verified By | Date |
|----------|--------|-------------|------|
| Network/DNS | [ ] Pass | | |
| Firewall Rules | [ ] Pass | | |
| Time Sync (NTP) | [ ] Pass | | |
| Storage | [ ] Pass | | |
| System Resources | [ ] Pass | | |
| LDAP/AD | [ ] Pass | | |
| MFA/RADIUS | [ ] Pass / [ ] N/A | | |
| Target Servers | [ ] Pass | | |
| Certificates | [ ] Pass | | |
| Backup Storage | [ ] Pass | | |
| Monitoring | [ ] Pass | | |
| Emergency Procedures | [ ] Documented | | |

### Sign-Off

```
Prepared By: _______________________  Date: ___________

Reviewed By: _______________________  Date: ___________

Approved for Installation: __________  Date: ___________
```

---

## Quick Verification Script

Save this as `pre-flight-check.sh` and run before installation:

```bash
#!/bin/bash
# WALLIX Pre-Flight Check Script

echo "=== WALLIX Pre-Installation Verification ==="
echo ""

# Check DNS
echo "[1/10] DNS Resolution..."
if nslookup $(hostname -f) > /dev/null 2>&1; then
    echo "  [PASS] Forward DNS works"
else
    echo "  [FAIL] Forward DNS failed"
fi

# Check NTP
echo "[2/10] Time Synchronization..."
if timedatectl status | grep -q "synchronized: yes"; then
    echo "  [PASS] NTP synchronized"
else
    echo "  [WARN] NTP not synchronized"
fi

# Check disk space
echo "[3/10] Disk Space..."
root_free=$(df / --output=avail -BG | tail -1 | tr -d 'G ')
if [ "$root_free" -gt 20 ]; then
    echo "  [PASS] Root has ${root_free}GB free"
else
    echo "  [FAIL] Root has only ${root_free}GB free (need 20GB+)"
fi

# Check memory
echo "[4/10] Memory..."
mem_total=$(free -g | awk '/^Mem:/{print $2}')
if [ "$mem_total" -ge 8 ]; then
    echo "  [PASS] ${mem_total}GB RAM available"
else
    echo "  [FAIL] Only ${mem_total}GB RAM (need 8GB+)"
fi

# Check CPU
echo "[5/10] CPU..."
cpu_count=$(nproc)
if [ "$cpu_count" -ge 4 ]; then
    echo "  [PASS] ${cpu_count} CPU cores"
else
    echo "  [FAIL] Only ${cpu_count} CPU cores (need 4+)"
fi

# Check file descriptors
echo "[6/10] File Descriptors..."
fd_limit=$(ulimit -n)
if [ "$fd_limit" -ge 65536 ]; then
    echo "  [PASS] File descriptor limit: $fd_limit"
else
    echo "  [WARN] File descriptor limit: $fd_limit (recommend 65536)"
fi

# Check ports
echo "[7/10] Port Availability..."
for port in 443 22 3389 3306; do
    if ! ss -tuln | grep -q ":$port "; then
        echo "  [PASS] Port $port available"
    else
        echo "  [WARN] Port $port already in use"
    fi
done

# Check backup directory
echo "[8/10] Backup Directory..."
if [ -d "/var/backup" ] && [ -w "/var/backup" ]; then
    echo "  [PASS] /var/backup exists and writable"
else
    echo "  [WARN] /var/backup not ready"
fi

# Check internet (for updates)
echo "[9/10] Internet Connectivity..."
if ping -c 1 8.8.8.8 > /dev/null 2>&1; then
    echo "  [PASS] Internet reachable"
else
    echo "  [WARN] No internet (offline installation required)"
fi

# Summary
echo ""
echo "[10/10] Generating Summary..."
echo "=== Pre-Flight Check Complete ==="
```

---

## Next Steps

After completing this checklist:

1. **Proceed to Installation**: [01-prerequisites.md](./01-prerequisites.md)
2. **Review Architecture**: [09-architecture-diagrams.md](./09-architecture-diagrams.md)
3. **Full Installation Guide**: [HOWTO.md](./HOWTO.md)

---

<p align="center">
  <a href="./01-prerequisites.md">Prerequisites</a> •
  <a href="./HOWTO.md">Installation Guide</a> •
  <a href="./appliance-setup-guide.md">Appliance Setup</a>
</p>
