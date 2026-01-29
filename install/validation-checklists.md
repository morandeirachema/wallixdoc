# Validation Checklists

## Pre-Deployment, Post-Deployment, and Go-Live Verification

Use these checklists to ensure successful WALLIX deployment at each phase.

---

## Phase 1: Pre-Deployment Validation

Complete before any installation begins.

### 1.1 Infrastructure Readiness

| # | Check | How to Verify | Status |
|---|-------|---------------|--------|
| 1 | Server provisioned | `hostname && uname -a` | [ ] |
| 2 | Correct OS version | `cat /etc/os-release` (Debian 12) | [ ] |
| 3 | Sufficient CPU | `nproc` (minimum 4 cores) | [ ] |
| 4 | Sufficient RAM | `free -h` (minimum 8 GB) | [ ] |
| 5 | Sufficient disk | `df -h` (minimum 100 GB /var) | [ ] |
| 6 | FQDN configured | `hostname -f` returns full name | [ ] |
| 7 | Forward DNS works | `nslookup $(hostname -f)` | [ ] |
| 8 | Reverse DNS works | `nslookup $(hostname -I)` | [ ] |
| 9 | NTP synchronized | `timedatectl status` shows synchronized | [ ] |
| 10 | Correct timezone | `timedatectl` shows expected zone | [ ] |

### 1.2 Network Connectivity

| # | Check | How to Verify | Status |
|---|-------|---------------|--------|
| 1 | LDAP/AD reachable | `nc -zv ldap-server 636` | [ ] |
| 2 | Target servers reachable | `ping target-server` | [ ] |
| 3 | SSH ports open | `nc -zv target 22` | [ ] |
| 4 | RDP ports open | `nc -zv target 3389` | [ ] |
| 5 | SIEM reachable | `nc -zv siem 514` | [ ] |
| 6 | NTP server reachable | `nc -zv ntp-server 123` | [ ] |
| 7 | No firewall blocking | Test from WALLIX IP to targets | [ ] |
| 8 | Cluster peer reachable | `ping cluster-peer` (if HA) | [ ] |

### 1.3 Authentication Prerequisites

| # | Check | How to Verify | Status |
|---|-------|---------------|--------|
| 1 | LDAP service account created | Test with ldapsearch | [ ] |
| 2 | LDAP account has read access | Can query user objects | [ ] |
| 3 | LDAP password documented | Stored securely | [ ] |
| 4 | RADIUS shared secret | If MFA, test with radtest | [ ] |
| 5 | Admin users identified | List of initial admins | [ ] |

### 1.4 Certificates

| # | Check | How to Verify | Status |
|---|-------|---------------|--------|
| 1 | Certificate obtained | File exists | [ ] |
| 2 | Key obtained | File exists | [ ] |
| 3 | Certificate matches key | MD5 hashes match | [ ] |
| 4 | Certificate not expired | `openssl x509 -noout -dates` | [ ] |
| 5 | SANs include all names | Check certificate details | [ ] |
| 6 | Chain complete | Intermediate certs available | [ ] |
| 7 | CA trusted by clients | Test import on client | [ ] |

```bash
# Certificate verification commands
openssl x509 -noout -modulus -in server.crt | openssl md5
openssl rsa -noout -modulus -in server.key | openssl md5
# Both should match

openssl x509 -in server.crt -noout -text | grep -A1 "Subject Alternative Name"
openssl verify -CAfile ca-chain.crt server.crt
```

### 1.5 Documentation

| # | Check | Status |
|---|-------|--------|
| 1 | Network diagram documented | [ ] |
| 2 | IP addresses assigned | [ ] |
| 3 | Firewall rules documented | [ ] |
| 4 | Emergency access procedure written | [ ] |
| 5 | Escalation contacts listed | [ ] |
| 6 | Change ticket approved | [ ] |

---

## Phase 2: Post-Installation Validation

Complete after WALLIX software installation.

### 2.1 Service Health

| # | Check | How to Verify | Status |
|---|-------|---------------|--------|
| 1 | All services running | `waservices status` all green | [ ] |
| 2 | Web UI accessible | `curl -k https://localhost:443` | [ ] |
| 3 | SSH proxy listening | `ss -tuln \| grep :22` | [ ] |
| 4 | RDP proxy listening | `ss -tuln \| grep :3389` | [ ] |
| 5 | Database running | `systemctl status postgresql` | [ ] |
| 6 | No errors in logs | `tail /var/log/wabengine/*.log` | [ ] |

### 2.2 Web Interface

| # | Check | How to Verify | Status |
|---|-------|---------------|--------|
| 1 | Admin login works | Login as admin | [ ] |
| 2 | Dashboard loads | No errors displayed | [ ] |
| 3 | Certificate valid | Browser shows secure | [ ] |
| 4 | All menus accessible | Click through sections | [ ] |

### 2.3 License Validation

| # | Check | How to Verify | Status |
|---|-------|---------------|--------|
| 1 | License installed | System > License shows valid | [ ] |
| 2 | Correct user count | Matches purchased license | [ ] |
| 3 | Correct features | OT, HA enabled if purchased | [ ] |
| 4 | Expiry date acceptable | Not expiring soon | [ ] |

### 2.4 Authentication Configuration

| # | Check | How to Verify | Status |
|---|-------|---------------|--------|
| 1 | LDAP connected | Configuration > Auth > Test | [ ] |
| 2 | User lookup works | Search for test user | [ ] |
| 3 | Group mapping works | User gets correct groups | [ ] |
| 4 | MFA configured | If applicable | [ ] |
| 5 | Local admin backup | Can login without LDAP | [ ] |

### 2.5 Basic Functionality Test

| # | Check | How to Verify | Status |
|---|-------|---------------|--------|
| 1 | Can create domain | Configuration > Domains > Add | [ ] |
| 2 | Can create device | Configuration > Devices > Add | [ ] |
| 3 | Can create user group | Configuration > User Groups | [ ] |
| 4 | Can create authorization | Configuration > Authorizations | [ ] |

---

## Phase 3: Integration Validation

Complete after connecting to target systems and authentication.

### 3.1 Target Connectivity

| # | Target Type | Check | Status |
|---|-------------|-------|--------|
| 1 | Linux SSH | Session connects and authenticates | [ ] |
| 2 | Linux SSH | Commands execute | [ ] |
| 3 | Linux SSH | Session recorded | [ ] |
| 4 | Windows RDP | Session connects | [ ] |
| 5 | Windows RDP | Credential injection works | [ ] |
| 6 | Windows RDP | Session recorded | [ ] |
| 7 | OT/PLC | Tunnel established | [ ] |
| 8 | OT/PLC | Engineering software connects | [ ] |

### 3.2 Password Management

| # | Check | How to Verify | Status |
|---|-------|---------------|--------|
| 1 | Initial password set | Account shows password stored | [ ] |
| 2 | Manual rotation works | Rotate Now succeeds | [ ] |
| 3 | Target accepts new password | Session after rotation works | [ ] |
| 4 | Rotation scheduled | Next rotation date shown | [ ] |
| 5 | Checkout works (if enabled) | Can retrieve password | [ ] |
| 6 | Checkout logged | Audit shows checkout event | [ ] |

### 3.3 Recording and Audit

| # | Check | How to Verify | Status |
|---|-------|---------------|--------|
| 1 | SSH session recorded | Replay shows commands | [ ] |
| 2 | RDP session recorded | Replay shows video | [ ] |
| 3 | Keystroke logging | Search finds typed text | [ ] |
| 4 | OCR indexing (RDP) | Can search RDP content | [ ] |
| 5 | Audit log entries | All actions logged | [ ] |
| 6 | Syslog forwarding | SIEM receives events | [ ] |

### 3.4 Authorization Testing

| # | Check | How to Verify | Status |
|---|-------|---------------|--------|
| 1 | Authorized user can connect | Test with authorized user | [ ] |
| 2 | Unauthorized user blocked | Test with unauthorized user | [ ] |
| 3 | Time restrictions work | Test outside allowed time | [ ] |
| 4 | Approval workflow works | Request requires approval | [ ] |
| 5 | 4-eyes works | Second person can observe | [ ] |

---

## Phase 4: High Availability Validation

Complete if deploying HA cluster.

### 4.1 Cluster Formation

| # | Check | How to Verify | Status |
|---|-------|---------------|--------|
| 1 | Both nodes online | `crm status` shows 2 nodes | [ ] |
| 2 | Resources distributed | Resources on expected nodes | [ ] |
| 3 | VIP accessible | `ping virtual-ip` | [ ] |
| 4 | Database replication | `pg_stat_replication` shows streaming | [ ] |
| 5 | No errors in cluster logs | `journalctl -u corosync` | [ ] |

### 4.2 Failover Testing

| # | Check | How to Verify | Status |
|---|-------|---------------|--------|
| 1 | Primary to secondary failover | Stop primary, verify VIP moves | [ ] |
| 2 | Services restart on failover | Can login after failover | [ ] |
| 3 | Active sessions survive | Existing sessions continue | [ ] |
| 4 | Database consistent | Data intact after failover | [ ] |
| 5 | Failback works | Restart primary, verify recovery | [ ] |

```bash
# Failover test procedure
# ON PRIMARY:
systemctl stop pacemaker

# VERIFY:
# - VIP should move to secondary
# - Web UI accessible on VIP
# - Can launch new sessions
# - Existing sessions continue

# FAILBACK:
systemctl start pacemaker
# Verify cluster reforms
```

---

## Phase 5: Go-Live Checklist

Complete before production use.

### 5.1 Security Hardening

| # | Check | How to Verify | Status |
|---|-------|---------------|--------|
| 1 | Default passwords changed | Admin, DB passwords | [ ] |
| 2 | SSH root login disabled | sshd_config: PermitRootLogin no | [ ] |
| 3 | Unnecessary ports closed | `ss -tuln` only needed ports | [ ] |
| 4 | TLS 1.2+ only | Older protocols disabled | [ ] |
| 5 | Audit logging enabled | All actions logged | [ ] |
| 6 | Backup configured | Automated backup running | [ ] |
| 7 | SIEM integration working | Logs flowing to SIEM | [ ] |

### 5.2 Operational Readiness

| # | Check | Status |
|---|-------|--------|
| 1 | Admin team trained | [ ] |
| 2 | User documentation available | [ ] |
| 3 | Support contact established | [ ] |
| 4 | Monitoring configured | [ ] |
| 5 | Alerting configured | [ ] |
| 6 | Backup tested (restore verified) | [ ] |
| 7 | DR plan documented | [ ] |

### 5.3 User Acceptance

| # | Check | Status |
|---|-------|--------|
| 1 | Pilot users tested access | [ ] |
| 2 | Pilot users can complete workflows | [ ] |
| 3 | No blocking issues reported | [ ] |
| 4 | Performance acceptable | [ ] |
| 5 | User feedback addressed | [ ] |

### 5.4 Compliance Verification

| # | Check | Status |
|---|-------|--------|
| 1 | Recording policy documented | [ ] |
| 2 | Retention period configured | [ ] |
| 3 | Access review process defined | [ ] |
| 4 | Audit report capability verified | [ ] |
| 5 | Compliance requirements mapped | [ ] |

---

## Go-Live Sign-Off

```
+==============================================================================+
|                   GO-LIVE AUTHORIZATION                                       |
+==============================================================================+

  Pre-Deployment Validation:     [ ] Complete     Date: ___________
  Post-Installation Validation:  [ ] Complete     Date: ___________
  Integration Validation:        [ ] Complete     Date: ___________
  HA Validation (if applicable): [ ] Complete     Date: ___________
  Security Hardening:            [ ] Complete     Date: ___________
  User Acceptance:               [ ] Complete     Date: ___________

  -------------------------------------------------------------------------

  Outstanding Issues:
  __________________________________________________________________
  __________________________________________________________________

  Mitigation Plan:
  __________________________________________________________________
  __________________________________________________________________

  -------------------------------------------------------------------------

  APPROVALS

  Technical Lead:     ________________________    Date: ___________

  Security Team:      ________________________    Date: ___________

  Operations Lead:    ________________________    Date: ___________

  Project Manager:    ________________________    Date: ___________

  -------------------------------------------------------------------------

  Go-Live Date/Time: ________________________

  Rollback Plan Location: ________________________

+==============================================================================+
```

---

## Quick Validation Script

Save as `validate-wallix.sh`:

```bash
#!/bin/bash
# WALLIX Deployment Validation Script

echo "=========================================="
echo "WALLIX Deployment Validation"
echo "=========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() { echo -e "${GREEN}[PASS]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

echo "--- Service Checks ---"

# Check services
if systemctl is-active --quiet wabengine; then
    pass "WAB Engine running"
else
    fail "WAB Engine not running"
fi

if systemctl is-active --quiet postgresql; then
    pass "PostgreSQL running"
else
    fail "PostgreSQL not running"
fi

# Check ports
echo ""
echo "--- Port Checks ---"

for port in 443 22 3389; do
    if ss -tuln | grep -q ":$port "; then
        pass "Port $port listening"
    else
        fail "Port $port not listening"
    fi
done

# Check disk space
echo ""
echo "--- Disk Space ---"

var_usage=$(df /var --output=pcent | tail -1 | tr -d ' %')
if [ "$var_usage" -lt 80 ]; then
    pass "/var usage: ${var_usage}%"
else
    warn "/var usage: ${var_usage}% (high)"
fi

# Check memory
echo ""
echo "--- Memory ---"

mem_avail=$(free -m | awk '/^Mem:/{print $7}')
if [ "$mem_avail" -gt 2000 ]; then
    pass "Available memory: ${mem_avail}MB"
else
    warn "Available memory: ${mem_avail}MB (low)"
fi

# Check time sync
echo ""
echo "--- Time Sync ---"

if timedatectl status | grep -q "synchronized: yes"; then
    pass "NTP synchronized"
else
    fail "NTP not synchronized"
fi

# Check logs for errors
echo ""
echo "--- Recent Errors ---"

error_count=$(grep -c "ERROR" /var/log/wabengine/*.log 2>/dev/null || echo 0)
if [ "$error_count" -eq 0 ]; then
    pass "No errors in logs"
else
    warn "$error_count errors in logs (review manually)"
fi

# Check web UI
echo ""
echo "--- Web UI ---"

if curl -sk https://localhost/admin | grep -q "WALLIX"; then
    pass "Web UI accessible"
else
    fail "Web UI not accessible"
fi

echo ""
echo "=========================================="
echo "Validation Complete"
echo "=========================================="
```

---

## Post-Go-Live Monitoring

### First 24 Hours

| Time | Check | Action if Issue |
|------|-------|-----------------|
| +1 hour | All services running | Restart failed services |
| +1 hour | Sessions connecting | Check firewall, credentials |
| +4 hours | No error spikes | Review logs |
| +8 hours | Disk space stable | Check recording storage |
| +24 hours | Full day of sessions | Review audit logs |

### First Week

| Day | Check |
|-----|-------|
| Day 2 | Password rotations succeeding |
| Day 3 | Backup completed successfully |
| Day 4 | No user access complaints |
| Day 5 | SIEM receiving all events |
| Day 7 | Weekly report generated |

---

<p align="center">
  <a href="./00-sysops-readiness.md">Sysops Readiness</a> •
  <a href="./HOWTO.md">Installation Guide</a> •
  <a href="../docs/12-troubleshooting/README.md">Troubleshooting</a>
</p>
