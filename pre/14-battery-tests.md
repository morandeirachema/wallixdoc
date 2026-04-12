# 14 - Battery Tests for Client Demonstrations

## WALLIX Bastion Comprehensive Test Suite

This document provides a complete battery of tests to demonstrate WALLIX Bastion capabilities to clients. Each test includes expected results, success criteria, and talking points for client presentations.

---

## Test Categories

> **Lab configuration**: Single WALLIX Bastion node (10.10.1.11, DMZ VLAN 110). HAProxy 2-node Active-Passive (VIP 10.10.1.100). FortiAuthenticator TOTP only (10.10.1.50, Cyber VLAN). AD DC (10.10.1.60, Cyber VLAN). Targets: win-srv-01/02 (10.10.2.x), rhel10-srv/rhel9-srv (10.10.2.x).

| Category | Tests | Duration | Purpose |
|----------|-------|----------|---------|
| [Authentication Tests](#1-authentication-tests) | 8 | 30 min | TOTP MFA, LDAP, Kerberos |
| [Session Management Tests](#2-session-management-tests) | 10 | 45 min | Recording, monitoring |
| [Password Management Tests](#3-password-management-tests) | 6 | 20 min | Vault, rotation |
| [HAProxy VIP Tests](#4-haproxy-vip-tests) | 5 | 25 min | VIP failover, Cyber VLAN connectivity |
| [Performance Tests](#5-performance-tests) | 5 | 30 min | Load, stress |
| [Security Tests](#6-security-tests) | 6 | 25 min | Hardening, audit |
| [Integration Tests](#7-integration-tests) | 5 | 20 min | SIEM, monitoring, AD |

**Total Duration**: ~3 hours

---

## Pre-Test Checklist

```
+===============================================================================+
|  PRE-TEST VERIFICATION                                                        |
+===============================================================================+

Before starting battery tests, verify:

[ ] WALLIX Bastion is healthy (single node)
    Command: wabadmin status
    Expected: All services running

[ ] HAProxy VIP is active
    Command: ip addr show on haproxy-1 (check for 10.10.1.100)
    Expected: VIP held by haproxy-1 (MASTER)

[ ] AD/LDAP integration is working
    Command: Test LDAP bind in Web UI (System > Authentication)
    Expected: Connection to dc-lab (10.10.1.60) successful

[ ] FortiAuthenticator RADIUS reachable
    Command: radtest testuser testpass 10.10.1.50 1812 sharedsecret
    Expected: Access-Challenge or Access-Accept

[ ] Test targets are reachable
    Command: ping 10.10.2.10 && ping 10.10.2.20
    Expected: win-srv-01 and rhel10-srv respond

[ ] Monitoring stack is operational
    Command: curl http://10.10.0.20:9090/-/healthy
    Expected: Prometheus is Healthy

[ ] SIEM receiving logs
    Command: Check siem-lab (10.10.0.10) for recent wallix events
    Expected: Events present from last 10 minutes

+===============================================================================+
```

---

## 1. Authentication Tests

### Test 1.1: Local Admin Login

```
+===============================================================================+
|  TEST 1.1: LOCAL ADMIN LOGIN                                                  |
+===============================================================================+

OBJECTIVE: Verify local admin authentication works

STEPS:
1. Open browser to https://wallix.lab.local
2. Enter credentials: admin / Pam4otAdmin123!
3. Click "Sign In"

EXPECTED RESULT:
- Dashboard loads successfully
- User shown as "admin" in top-right
- No error messages

SUCCESS CRITERIA:
[ ] Login completes in < 3 seconds
[ ] Dashboard displays correctly
[ ] Session appears in audit log

CLIENT TALKING POINT:
"Local admin accounts are available for emergency access when directory
services are unavailable. These accounts have full audit logging."

+===============================================================================+
```

### Test 1.2: LDAP Authentication

```
+===============================================================================+
|  TEST 1.2: LDAP AUTHENTICATION                                                |
+===============================================================================+

OBJECTIVE: Verify AD/LDAP user authentication

STEPS:
1. Open browser to https://wallix.lab.local
2. Enter credentials: lab\pam-user / UserPass123!
3. Click "Sign In"

EXPECTED RESULT:
- User authenticates against AD
- Dashboard loads with appropriate permissions
- Group memberships are synchronized

SUCCESS CRITERIA:
[ ] LDAP authentication completes in < 5 seconds
[ ] User groups correctly mapped to PAM roles
[ ] Login appears in AD security log

CLIENT TALKING POINT:
"Users authenticate with their existing corporate credentials - no separate
passwords to manage. Group-based access control maps directly to AD groups."

+===============================================================================+
```

### Test 1.3: Kerberos SSO

```
+===============================================================================+
|  TEST 1.3: KERBEROS SINGLE SIGN-ON                                            |
+===============================================================================+

OBJECTIVE: Verify seamless SSO for domain-joined workstations

STEPS:
1. From a domain-joined Windows workstation
2. Open browser to https://wallix.lab.local
3. Observe automatic authentication

EXPECTED RESULT:
- No password prompt displayed
- User automatically logged in
- Kerberos ticket used for auth

SUCCESS CRITERIA:
[ ] SSO completes without user interaction
[ ] User identity correctly identified
[ ] Kerberos ticket visible in session

CLIENT TALKING POINT:
"Users on domain workstations get seamless single sign-on - they're
automatically authenticated without entering any credentials."

+===============================================================================+
```

### Test 1.4: MFA Challenge

```
+===============================================================================+
|  TEST 1.4: MULTI-FACTOR AUTHENTICATION                                        |
+===============================================================================+

OBJECTIVE: Verify TOTP MFA enforcement via FortiAuthenticator

STEPS:
1. Login as user with MFA requirement
2. Enter username/password
3. When prompted, enter 6-digit TOTP code from FortiToken Mobile app
4. Complete login

EXPECTED RESULT:
- MFA TOTP challenge displayed after password
- TOTP code validated against FortiAuthenticator (10.10.1.50)
- Session established with MFA flag in audit log

SUCCESS CRITERIA:
[ ] MFA prompt appears after password
[ ] Invalid TOTP codes are rejected
[ ] Valid TOTP codes grant access
[ ] Audit log shows MFA was used
[ ] FortiAuthenticator logs show RADIUS Accept

LAB NOTE:
FortiToken Push is NOT configured in this lab. TOTP only.

CLIENT TALKING POINT:
"For high-security access, we enforce multi-factor authentication
via FortiAuthenticator. TOTP tokens generate a new code every 30
seconds — even offline, with no network dependency."

+===============================================================================+
```

### Test 1.5: Failed Login Lockout

```
+===============================================================================+
|  TEST 1.5: FAILED LOGIN LOCKOUT                                               |
+===============================================================================+

OBJECTIVE: Verify account lockout after failed attempts

STEPS:
1. Attempt login with wrong password 5 times
2. Observe lockout message
3. Wait for lockout period or admin unlock

EXPECTED RESULT:
- After 5 failures, account is locked
- Lockout message displayed
- Alert generated in SIEM

SUCCESS CRITERIA:
[ ] Lockout occurs after configured attempts
[ ] User cannot login during lockout
[ ] Security alert is generated

CLIENT TALKING POINT:
"Brute-force attacks are automatically blocked. After configurable
failed attempts, accounts are locked and security is alerted."

+===============================================================================+
```

### Test 1.6: Session Timeout

```
+===============================================================================+
|  TEST 1.6: SESSION TIMEOUT                                                    |
+===============================================================================+

OBJECTIVE: Verify idle session termination

STEPS:
1. Login to WALLIX Bastion
2. Leave session idle for configured timeout (e.g., 15 minutes)
3. Attempt to perform an action

EXPECTED RESULT:
- Session is terminated after timeout
- User is redirected to login page
- Timeout logged in audit

SUCCESS CRITERIA:
[ ] Session terminates at configured time
[ ] Graceful redirect to login
[ ] Audit log records timeout

+===============================================================================+
```

### Test 1.7: Certificate Authentication

```
+===============================================================================+
|  TEST 1.7: X.509 CERTIFICATE AUTHENTICATION                                   |
+===============================================================================+

OBJECTIVE: Verify client certificate authentication

STEPS:
1. Install user certificate in browser
2. Navigate to WALLIX Bastion with certificate auth enabled
3. Select certificate when prompted

EXPECTED RESULT:
- Certificate is validated
- User is authenticated based on certificate CN
- No password required

SUCCESS CRITERIA:
[ ] Certificate prompt appears
[ ] Valid certificates grant access
[ ] Expired/revoked certificates are rejected

CLIENT TALKING POINT:
"For high-security environments, we support certificate-based
authentication - no passwords at all, just smart cards or certificates."

+===============================================================================+
```

### Test 1.8: Approval Workflow Login

```
+===============================================================================+
|  TEST 1.8: APPROVAL WORKFLOW                                                  |
+===============================================================================+

OBJECTIVE: Verify access requires manager approval

STEPS:
1. Login as user requiring approval
2. Request access to protected target
3. As approver, approve the request
4. Verify access is granted

EXPECTED RESULT:
- Access request is submitted
- Approver receives notification
- After approval, access is granted

SUCCESS CRITERIA:
[ ] Request appears in approval queue
[ ] Approver can approve/deny
[ ] Approved access works immediately

CLIENT TALKING POINT:
"For sensitive systems, access can require manager approval.
This provides a dual-control mechanism for privileged access."

+===============================================================================+
```

---

## 2. Session Management Tests

### Test 2.1: SSH Session Recording

```
+===============================================================================+
|  TEST 2.1: SSH SESSION RECORDING                                              |
+===============================================================================+

OBJECTIVE: Demonstrate SSH session recording and playback

STEPS:
1. Login to WALLIX Bastion Web UI
2. Select SSH target (linux-test)
3. Connect to session
4. Execute commands:
   - whoami
   - ls -la
   - cat /etc/hostname
5. Disconnect session
6. View recording in audit

EXPECTED RESULT:
- Session is recorded in real-time
- Recording is available immediately after disconnect
- Full video playback available

SUCCESS CRITERIA:
[ ] Session connects successfully
[ ] Commands execute properly
[ ] Recording is complete
[ ] Playback shows all activity

CLIENT TALKING POINT:
"Every SSH session is recorded as video. Auditors can replay exactly
what happened, see every command typed, and every response received."

DEMO COMMANDS TO SHOW:
  whoami
  pwd
  ls -la /etc
  cat /etc/passwd | head -5
  uptime

+===============================================================================+
```

### Test 2.2: RDP Session Recording

```
+===============================================================================+
|  TEST 2.2: RDP SESSION RECORDING                                              |
+===============================================================================+

OBJECTIVE: Demonstrate RDP session recording

STEPS:
1. Login to WALLIX Bastion Web UI
2. Select RDP target (windows-test)
3. Connect via HTML5 or native RDP
4. Perform actions:
   - Open File Explorer
   - Open Notepad, type text
   - Open PowerShell, run Get-Process
5. Disconnect and view recording

EXPECTED RESULT:
- Full graphical session is recorded
- All mouse/keyboard activity captured
- OCR metadata extracted

SUCCESS CRITERIA:
[ ] RDP session connects
[ ] GUI actions recorded
[ ] Playback shows full desktop activity
[ ] OCR can search for typed text

CLIENT TALKING POINT:
"RDP sessions are fully recorded as video. Our OCR technology extracts
text from the screen, making sessions searchable by content."

+===============================================================================+
```

### Test 2.3: Real-Time Session Monitoring

```
+===============================================================================+
|  TEST 2.3: REAL-TIME SESSION MONITORING                                       |
+===============================================================================+

OBJECTIVE: Show live session monitoring (shadow session)

STEPS:
1. User A: Start SSH session to linux-test
2. Admin: Go to "Active Sessions" in Web UI
3. Admin: Click "Monitor" on User A's session
4. User A: Execute commands
5. Observe Admin sees activity in real-time

EXPECTED RESULT:
- Admin sees live session activity
- No impact on user session
- Admin can terminate if needed

SUCCESS CRITERIA:
[ ] Live monitoring works in real-time
[ ] < 1 second latency
[ ] Admin can terminate session

CLIENT TALKING POINT:
"Security admins can monitor any active session in real-time.
If suspicious activity is detected, they can instantly terminate it."

+===============================================================================+
```

### Test 2.4: Session Termination

```
+===============================================================================+
|  TEST 2.4: ADMINISTRATIVE SESSION TERMINATION                                 |
+===============================================================================+

OBJECTIVE: Demonstrate admin can kill active sessions

STEPS:
1. User: Connect to SSH session
2. Admin: View active sessions
3. Admin: Click "Terminate" on user's session
4. Observe session is immediately closed

EXPECTED RESULT:
- Session is terminated instantly
- User is disconnected
- Termination is logged

SUCCESS CRITERIA:
[ ] Termination is immediate
[ ] User sees disconnect
[ ] Audit log shows admin action

CLIENT TALKING POINT:
"If an incident occurs, security can immediately terminate any session
across the entire environment from a single console."

+===============================================================================+
```

### Test 2.5: Keystroke Logging

```
+===============================================================================+
|  TEST 2.5: KEYSTROKE LOGGING                                                  |
+===============================================================================+

OBJECTIVE: Show detailed keystroke capture

STEPS:
1. Connect SSH session
2. Type commands including special characters:
   - echo "Test message with special chars: @#$%"
   - cat /etc/passwd | grep root
3. Disconnect and view keystroke log

EXPECTED RESULT:
- Every keystroke is logged
- Special characters captured correctly
- Searchable in audit

SUCCESS CRITERIA:
[ ] All keystrokes captured
[ ] Timing preserved
[ ] Searchable by command

CLIENT TALKING POINT:
"Beyond video, we capture every keystroke with timestamps.
This makes it easy to search for specific commands or patterns
across thousands of sessions."

+===============================================================================+
```

### Test 2.6: Session Sharing

```
+===============================================================================+
|  TEST 2.6: SESSION SHARING                                                    |
+===============================================================================+

OBJECTIVE: Demonstrate collaborative session capability

STEPS:
1. User A: Start SSH session
2. User A: Share session with User B (via UI)
3. User B: Join shared session
4. Both users can see same session
5. Optionally, both can interact

EXPECTED RESULT:
- Session is shared successfully
- Both users see same output
- Collaboration is logged

SUCCESS CRITERIA:
[ ] Sharing invitation works
[ ] Both see real-time output
[ ] All participants logged

CLIENT TALKING POINT:
"For training or support scenarios, sessions can be shared.
A senior admin can watch and assist a junior admin in real-time."

+===============================================================================+
```

### Test 2.7: Session Time Limits

```
+===============================================================================+
|  TEST 2.7: SESSION TIME LIMITS                                                |
+===============================================================================+

OBJECTIVE: Verify session duration enforcement

STEPS:
1. Configure 5-minute session limit for test user
2. Connect to target
3. Wait for time limit
4. Observe forced disconnect

EXPECTED RESULT:
- Warning before disconnect (optional)
- Session is terminated at limit
- User cannot reconnect without new auth

SUCCESS CRITERIA:
[ ] Session terminates at limit
[ ] User is notified
[ ] New session requires re-auth

+===============================================================================+
```

### Test 2.8: Session Audit Search

```
+===============================================================================+
|  TEST 2.8: SESSION AUDIT SEARCH                                               |
+===============================================================================+

OBJECTIVE: Demonstrate audit search capabilities

STEPS:
1. Go to Audit section in Web UI
2. Search by:
   - User name
   - Target device
   - Date range
   - Command executed (e.g., "sudo")
3. View matching sessions

EXPECTED RESULT:
- Search returns relevant results
- Filters work correctly
- Can navigate to specific session

SUCCESS CRITERIA:
[ ] Search is fast (< 5 seconds)
[ ] Filters are accurate
[ ] Can playback from search

CLIENT TALKING POINT:
"Auditors can search across millions of sessions by any criteria -
who connected, where, when, or what commands were executed."

+===============================================================================+
```

### Test 2.9: Session Export

```
+===============================================================================+
|  TEST 2.9: SESSION EXPORT                                                     |
+===============================================================================+

OBJECTIVE: Show session recording export

STEPS:
1. Select completed session in audit
2. Export as video file (MP4)
3. Export keystroke log as text
4. Verify exports are complete

EXPECTED RESULT:
- Video exports successfully
- Keystroke log is readable
- Files can be archived

SUCCESS CRITERIA:
[ ] Export completes
[ ] Video plays in standard player
[ ] Logs are complete

+===============================================================================+
```

### Test 2.10: Protocol Translation

```
+===============================================================================+
|  TEST 2.10: PROTOCOL TRANSLATION                                              |
+===============================================================================+

OBJECTIVE: Show accessing SSH target via web browser

STEPS:
1. Login to Web UI
2. Connect to SSH target via HTML5
3. Execute commands without native SSH client

EXPECTED RESULT:
- SSH access works in browser
- No client software needed
- Session is recorded

SUCCESS CRITERIA:
[ ] Browser-based SSH works
[ ] Responsive terminal
[ ] Recording is complete

CLIENT TALKING POINT:
"Users can access any target through just a web browser -
no need to install SSH clients, RDP clients, or VPN software."

+===============================================================================+
```

---

## 3. Password Management Tests

### Test 3.1: Password Checkout

```
+===============================================================================+
|  TEST 3.1: PASSWORD CHECKOUT                                                  |
+===============================================================================+

OBJECTIVE: Demonstrate secure password checkout

STEPS:
1. Navigate to Password Vault
2. Select credential (e.g., linux-test / root)
3. Request checkout with reason
4. View password (or copy to clipboard)
5. Check in password after use

EXPECTED RESULT:
- Password is revealed/copied
- Checkout is logged with reason
- Check-in resets access

SUCCESS CRITERIA:
[ ] Checkout requires reason
[ ] Password is displayed/copied
[ ] Audit trail complete

CLIENT TALKING POINT:
"Privileged passwords are never shared or written down. Users check them
out when needed, and every access is fully audited with business reason."

+===============================================================================+
```

### Test 3.2: Automatic Password Rotation

```
+===============================================================================+
|  TEST 3.2: AUTOMATIC PASSWORD ROTATION                                        |
+===============================================================================+

OBJECTIVE: Show automatic credential rotation

STEPS:
1. View current password for test account
2. Trigger manual rotation (or wait for scheduled)
3. Verify new password is different
4. Verify new password works on target

EXPECTED RESULT:
- Password is changed automatically
- New password stored in vault
- Target account works with new password

SUCCESS CRITERIA:
[ ] Rotation completes successfully
[ ] New password is random/complex
[ ] Target authentication works

CLIENT TALKING POINT:
"Passwords are rotated automatically on a schedule you define -
daily, weekly, or after each use. This eliminates password staleness."

+===============================================================================+
```

### Test 3.3: SSH Key Management

```
+===============================================================================+
|  TEST 3.3: SSH KEY MANAGEMENT                                                 |
+===============================================================================+

OBJECTIVE: Demonstrate SSH key rotation

STEPS:
1. View SSH key for target account
2. Trigger key rotation
3. Verify new key is deployed to target
4. Connect using new key

EXPECTED RESULT:
- New key pair is generated
- Public key deployed to target
- Connection works with new key

SUCCESS CRITERIA:
[ ] Key rotation completes
[ ] Target authorized_keys updated
[ ] SSH connection works

+===============================================================================+
```

### Test 3.4: Password Policy Enforcement

```
+===============================================================================+
|  TEST 3.4: PASSWORD POLICY ENFORCEMENT                                        |
+===============================================================================+

OBJECTIVE: Show password policy compliance

STEPS:
1. View password policy settings
2. Generate new password
3. Verify it meets complexity requirements:
   - Length
   - Character types
   - No dictionary words

EXPECTED RESULT:
- Generated passwords meet policy
- Policy is configurable

SUCCESS CRITERIA:
[ ] Passwords meet length requirement
[ ] Include upper/lower/number/special
[ ] Policy is enforced

+===============================================================================+
```

### Test 3.5: Emergency Break-Glass Access

```
+===============================================================================+
|  TEST 3.5: EMERGENCY BREAK-GLASS ACCESS                                       |
+===============================================================================+

OBJECTIVE: Demonstrate emergency credential access

STEPS:
1. Simulate emergency (all admins unavailable)
2. Use break-glass procedure
3. Access emergency credentials
4. Verify enhanced audit logging

EXPECTED RESULT:
- Emergency access is possible
- Multiple approvals logged
- High-priority alerts generated

SUCCESS CRITERIA:
[ ] Emergency access works
[ ] Additional logging triggered
[ ] Alerts sent to security

CLIENT TALKING POINT:
"For true emergencies, break-glass procedures provide access even
when approvers are unavailable - but with extra scrutiny and alerts."

+===============================================================================+
```

### Test 3.6: Password Exposure Detection

```
+===============================================================================+
|  TEST 3.6: PASSWORD EXPOSURE DETECTION                                        |
+===============================================================================+

OBJECTIVE: Show detection of password misuse

STEPS:
1. Configure alert for credential access
2. Access credential
3. Verify alert is generated
4. Check SIEM for correlation

EXPECTED RESULT:
- Access generates alert
- SIEM receives notification
- Security can investigate

SUCCESS CRITERIA:
[ ] Alert generated on access
[ ] Alert includes context
[ ] SIEM correlation works

+===============================================================================+
```

---

## 4. HAProxy VIP Tests

> **Lab scope**: WALLIX Bastion is a single node — no Bastion cluster, no bastion-replication, no MariaDB HA. HAProxy Active-Passive (haproxy-1 / haproxy-2) with Keepalived VRRP provides VIP failover. These tests validate the HAProxy layer and Cyber VLAN connectivity.

### Test 4.1: HAProxy VIP Status

```
+===============================================================================+
|  TEST 4.1: HAPROXY VIP STATUS VERIFICATION                                    |
+===============================================================================+

OBJECTIVE: Verify HAProxy Active-Passive VIP is active

COMMANDS:
# On haproxy-1 (expected MASTER):
ip addr show | grep 10.10.1.100
systemctl status keepalived
systemctl status haproxy

# On haproxy-2 (expected BACKUP):
ip addr show | grep 10.10.1.100   # should show nothing

# Check HAProxy stats:
curl http://10.10.1.5:8404/stats   # haproxy-1
curl http://10.10.1.6:8404/stats   # haproxy-2

EXPECTED RESULT:
- VIP 10.10.1.100 active on haproxy-1
- haproxy-2 in BACKUP state
- Backend wallix-bastion (10.10.1.11) shows UP

SUCCESS CRITERIA:
[ ] VIP present on haproxy-1
[ ] HAProxy backend shows wallix-bastion UP
[ ] Keepalived state is MASTER on haproxy-1

+===============================================================================+
```

### Test 4.2: VIP Failover (Planned)

```
+===============================================================================+
|  TEST 4.2: PLANNED VIP FAILOVER                                               |
+===============================================================================+

OBJECTIVE: Demonstrate VIP migration when haproxy-1 goes down

STEPS:
1. Confirm VIP on haproxy-1: ip addr show | grep 10.10.1.100
2. Connect a session through VIP: https://wallix.lab.local
3. Stop keepalived on haproxy-1:
   systemctl stop keepalived
4. Observe VIP migrates to haproxy-2:
   ip addr show on haproxy-2 | grep 10.10.1.100
5. Verify wallix.lab.local still reachable via haproxy-2
6. Restore: systemctl start keepalived on haproxy-1

EXPECTED RESULT:
- VIP migrates to haproxy-2 within 5 seconds
- WALLIX Bastion web UI still accessible
- Sessions through VIP continue

SUCCESS CRITERIA:
[ ] VIP failover in < 5 seconds
[ ] WALLIX Bastion accessible after failover
[ ] VRRP logs show state transition

CLIENT TALKING POINT:
"HAProxy Active-Passive ensures the load balancer is never a single
point of failure. VIP migration is automatic and sub-5-second."

+===============================================================================+
```

### Test 4.3: VIP Failover (Unplanned — Power Off)

```
+===============================================================================+
|  TEST 4.3: UNPLANNED VIP FAILOVER - VM POWER OFF                             |
+===============================================================================+

OBJECTIVE: Simulate haproxy-1 hard failure

STEPS:
1. Power off haproxy-1 VM in vSphere
2. Watch haproxy-2 for VIP acquisition
3. Test WALLIX Bastion is accessible: https://wallix.lab.local
4. Power on haproxy-1 — confirm it returns as BACKUP (not MASTER)

EXPECTED RESULT:
- haproxy-2 acquires VIP automatically
- Access continues without manual intervention
- haproxy-1 comes back as BACKUP

SUCCESS CRITERIA:
[ ] VIP acquired by haproxy-2 < 10 seconds
[ ] No manual intervention required
[ ] haproxy-1 returns as BACKUP on restart

+===============================================================================+
```

### Test 4.4: Cyber VLAN Connectivity (LDAP/Kerberos)

```
+===============================================================================+
|  TEST 4.4: CYBER VLAN CONNECTIVITY — AD (dc-lab 10.10.1.60)                  |
+===============================================================================+

OBJECTIVE: Verify wallix-bastion can reach dc-lab across inter-VLAN (Fortigate)

COMMANDS (from wallix-bastion):
# LDAPS (port 636):
openssl s_client -connect 10.10.1.60:636 -showcerts

# LDAP (port 389):
ldapsearch -H ldap://10.10.1.60 -b "DC=lab,DC=local" \
  -D "wallix-svc@lab.local" -w "ServicePass123!" \
  "(objectClass=user)" cn | head -20

# Kerberos (port 88):
kinit pam-user@LAB.LOCAL
klist

EXPECTED RESULT:
- LDAPS connection established with valid certificate
- LDAP search returns user list from AD
- Kerberos ticket obtained successfully

SUCCESS CRITERIA:
[ ] LDAPS connection to 10.10.1.60:636 succeeds
[ ] LDAP user query returns results
[ ] Kerberos TGT obtained for lab user
[ ] WALLIX Bastion LDAP test (Web UI) shows Connected

+===============================================================================+
```

### Test 4.5: Cyber VLAN Connectivity (FortiAuthenticator RADIUS)

```
+===============================================================================+
|  TEST 4.5: CYBER VLAN CONNECTIVITY — FORTIAUTH (10.10.1.50)                  |
+===============================================================================+

OBJECTIVE: Verify wallix-bastion can reach fortiauth RADIUS across inter-VLAN

COMMANDS (from wallix-bastion):
# Test RADIUS reachability (NAS-IP = wallix-bastion):
radtest pam-user "password+TOTP" 10.10.1.50 1812 <shared_secret>

# From siem-lab, verify FortiAuth syslog arrives:
tail -f /var/log/wazuh/alerts/alerts.log | grep fortiauth

EXPECTED RESULT:
- RADIUS challenge received (Access-Challenge for TOTP)
- After valid TOTP code: Access-Accept
- FortiAuth logs show authentication attempt

SUCCESS CRITERIA:
[ ] RADIUS port 1812 reachable from wallix-bastion
[ ] Access-Challenge returned (TOTP prompt)
[ ] Valid TOTP code yields Access-Accept
[ ] FortiAuth syslog appears in SIEM

CLIENT TALKING POINT:
"TOTP-based MFA via FortiAuthenticator requires no network push —
codes are generated offline on the user's device and validated over
RADIUS. Inter-VLAN security boundaries are respected."

+===============================================================================+
```

---

## 5. Performance Tests

### Test 5.1: Concurrent Session Load

```
+===============================================================================+
|  TEST 5.1: CONCURRENT SESSION LOAD                                            |
+===============================================================================+

OBJECTIVE: Verify system handles multiple concurrent sessions

STEPS:
1. Start 10+ concurrent SSH sessions
2. Start 5+ concurrent RDP sessions
3. Monitor system resources
4. Verify all sessions work properly

EXPECTED RESULT:
- All sessions connect successfully
- No performance degradation
- Recordings work for all

SUCCESS CRITERIA:
[ ] 15+ concurrent sessions
[ ] < 5 second connection time
[ ] CPU/RAM within limits

COMMANDS:
# Monitor during test
top
wabadmin status
curl http://10.10.0.20:9090/api/v1/query?query=up

CLIENT TALKING POINT:
"The system is designed for enterprise scale - hundreds of concurrent
sessions with full recording and no performance impact."

+===============================================================================+
```

### Test 5.2: Authentication Throughput

```
+===============================================================================+
|  TEST 5.2: AUTHENTICATION THROUGHPUT                                          |
+===============================================================================+

OBJECTIVE: Measure login performance under load

STEPS:
1. Script 50 rapid login attempts
2. Measure average login time
3. Monitor system during load
4. Verify no failed authentications

EXPECTED RESULT:
- Average login < 3 seconds
- No authentication failures
- System remains stable

SUCCESS CRITERIA:
[ ] < 3 second average login
[ ] 0 failures
[ ] System stable

+===============================================================================+
```

### Test 5.3: Recording Storage Performance

```
+===============================================================================+
|  TEST 5.3: RECORDING STORAGE PERFORMANCE                                      |
+===============================================================================+

OBJECTIVE: Verify recording performance at scale

STEPS:
1. Run 10 concurrent active sessions
2. Monitor storage write speed
3. Check recording quality
4. Verify no gaps in recordings

EXPECTED RESULT:
- All recordings complete
- No quality degradation
- Storage keeps up

SUCCESS CRITERIA:
[ ] All recordings valid
[ ] < 10% storage overhead
[ ] No dropped frames

+===============================================================================+
```

### Test 5.4: API Response Time

```
+===============================================================================+
|  TEST 5.4: API RESPONSE TIME                                                  |
+===============================================================================+

OBJECTIVE: Measure REST API performance

STEPS:
1. Run API benchmark:
   - GET /devices (list)
   - GET /users (list)
   - POST /sessions (create)
2. Measure response times
3. Test under load

EXPECTED RESULT:
- Average response < 500ms
- No timeouts
- Consistent performance

COMMANDS:
# Example benchmark
curl -w "%{time_total}\n" -o /dev/null -s \
  "https://wallix.lab.local/api/devices"

SUCCESS CRITERIA:
[ ] < 500ms average response
[ ] < 2 second max response
[ ] No errors under load

+===============================================================================+
```

### Test 5.5: Database Query Performance

```
+===============================================================================+
|  TEST 5.5: DATABASE QUERY PERFORMANCE                                         |
+===============================================================================+

OBJECTIVE: Verify database performance under load

STEPS:
1. Run audit queries during active sessions
2. Search large audit datasets
3. Monitor query times
4. Verify no impact on sessions

EXPECTED RESULT:
- Queries complete quickly
- No session impact
- Indexing works properly

SUCCESS CRITERIA:
[ ] Audit queries < 5 seconds
[ ] No session degradation
[ ] No database locks

+===============================================================================+
```

---

## 6. Security Tests

### Test 6.1: TLS Configuration

```
+===============================================================================+
|  TEST 6.1: TLS CONFIGURATION                                                  |
+===============================================================================+

OBJECTIVE: Verify strong TLS configuration

COMMANDS:
# Test TLS version and ciphers
nmap --script ssl-enum-ciphers -p 443 wallix.lab.local

# Or use testssl.sh
./testssl.sh https://wallix.lab.local

EXPECTED RESULT:
- TLS 1.2/1.3 only
- No weak ciphers
- Valid certificate

SUCCESS CRITERIA:
[ ] No TLS 1.0/1.1
[ ] No weak ciphers (RC4, DES, etc.)
[ ] Certificate is valid

CLIENT TALKING POINT:
"All communications use TLS 1.3 with strong ciphers.
Weak protocols and ciphers are completely disabled."

+===============================================================================+
```

### Test 6.2: Audit Log Integrity

```
+===============================================================================+
|  TEST 6.2: AUDIT LOG INTEGRITY                                                |
+===============================================================================+

OBJECTIVE: Verify audit logs cannot be tampered

STEPS:
1. View current audit logs
2. Attempt to modify audit file directly
3. Verify integrity checks fail
4. Verify logs are signed

EXPECTED RESULT:
- Audit logs are protected
- Modifications are detected
- Chain of custody maintained

SUCCESS CRITERIA:
[ ] Logs are read-only to users
[ ] Integrity checks work
[ ] SIEM has copy of logs

+===============================================================================+
```

### Test 6.3: Privilege Escalation Prevention

```
+===============================================================================+
|  TEST 6.3: PRIVILEGE ESCALATION PREVENTION                                    |
+===============================================================================+

OBJECTIVE: Verify users cannot escalate privileges

STEPS:
1. Login as regular user
2. Attempt to access admin functions
3. Attempt to view other users' sessions
4. Attempt to access unauthorized targets

EXPECTED RESULT:
- All attempts are blocked
- Access denied messages
- Attempts are logged

SUCCESS CRITERIA:
[ ] No unauthorized access
[ ] Proper error messages
[ ] Attempts logged

CLIENT TALKING POINT:
"Role-based access control is enforced at every level.
Users can only access what they're explicitly authorized to access."

+===============================================================================+
```

### Test 6.4: Injection Attack Prevention

```
+===============================================================================+
|  TEST 6.4: INJECTION ATTACK PREVENTION                                        |
+===============================================================================+

OBJECTIVE: Verify input validation prevents attacks

STEPS:
1. Attempt SQL injection in search fields
2. Attempt XSS in input fields
3. Attempt command injection
4. Verify all are blocked

EXPECTED RESULT:
- All injection attempts fail
- Input is sanitized
- No error disclosure

SUCCESS CRITERIA:
[ ] SQL injection blocked
[ ] XSS blocked
[ ] Command injection blocked

+===============================================================================+
```

### Test 6.5: SIEM Alert Integration

```
+===============================================================================+
|  TEST 6.5: SIEM ALERT INTEGRATION                                             |
+===============================================================================+

OBJECTIVE: Verify security events reach SIEM

STEPS:
1. Trigger security events:
   - Failed logins
   - Unauthorized access attempts
   - Admin actions
2. Verify events appear in SIEM
3. Check correlation rules fire

EXPECTED RESULT:
- All events forwarded
- SIEM receives in real-time
- Alerts trigger correctly

SUCCESS CRITERIA:
[ ] Events reach SIEM in < 30 seconds
[ ] Event format is correct
[ ] Alerts fire as expected

CLIENT TALKING POINT:
"All security events are forwarded to your SIEM in real-time.
Pre-built correlation rules detect suspicious patterns automatically."

+===============================================================================+
```

### Test 6.6: Compliance Report Generation

```
+===============================================================================+
|  TEST 6.6: COMPLIANCE REPORT GENERATION                                       |
+===============================================================================+

OBJECTIVE: Demonstrate compliance reporting

STEPS:
1. Generate access report for date range
2. Generate privileged user report
3. Export reports in multiple formats
4. Verify report accuracy

EXPECTED RESULT:
- Reports generate successfully
- Data is accurate
- Multiple export formats available

SUCCESS CRITERIA:
[ ] Reports generate in < 1 minute
[ ] Data matches audit logs
[ ] PDF/CSV/Excel exports work

CLIENT TALKING POINT:
"For compliance audits, generate reports showing who accessed what,
when, and why. Reports can be scheduled and sent automatically."

+===============================================================================+
```

---

## 7. Integration Tests

### Test 7.1: SIEM Log Forwarding

```
+===============================================================================+
|  TEST 7.1: SIEM LOG FORWARDING VERIFICATION                                   |
+===============================================================================+

OBJECTIVE: Verify WALLIX Bastion events reach siem-lab (10.10.0.10)

STEPS:
1. Generate authentication events (login success and failure)
2. Start and end an SSH session
3. On siem-lab, verify events arrived in Wazuh:
   tail -f /var/log/wazuh/alerts/alerts.log | grep wallix
4. Search for CEF events in Wazuh dashboard

EXPECTED RESULT:
- Auth events arrive within 30 seconds
- Session events (start/end) arrive
- CEF format parsed correctly

SUCCESS CRITERIA:
[ ] Auth success events visible in SIEM
[ ] Auth failure events visible in SIEM
[ ] Session start/end events visible
[ ] Wazuh alert triggered for failed logins

CLIENT TALKING POINT:
"All security events are forwarded to the SIEM in real-time using
CEF format. Pre-built parsers make events immediately searchable."

+===============================================================================+
```

### Test 7.2: Prometheus Metrics Scraping

```
+===============================================================================+
|  TEST 7.2: PROMETHEUS METRICS SCRAPING (monitor-lab 10.10.0.20)              |
+===============================================================================+

OBJECTIVE: Verify monitor-lab scrapes wallix-bastion metrics

STEPS:
1. On monitor-lab, check Prometheus targets:
   curl http://10.10.0.20:9090/api/v1/targets | python3 -m json.tool
2. Verify wallix-bastion (10.10.1.11) shows state: up
3. Open Grafana (http://10.10.0.20:3000) and check dashboards
4. Verify node_exporter metrics present for wallix-bastion

EXPECTED RESULT:
- wallix-bastion target is UP
- CPU, memory, disk metrics present
- Grafana dashboard shows current data

SUCCESS CRITERIA:
[ ] Prometheus target wallix-bastion shows UP
[ ] node_exporter metrics visible
[ ] mysqld_exporter metrics visible
[ ] Grafana WALLIX Bastion Overview dashboard populates

+===============================================================================+
```

### Test 7.3: AD/LDAP Group Sync

```
+===============================================================================+
|  TEST 7.3: AD GROUP SYNC AND RBAC                                             |
+===============================================================================+

OBJECTIVE: Verify AD group membership maps to WALLIX Bastion permissions

STEPS:
1. Add test user to "Linux-Admins" AD group on dc-lab
2. Login to WALLIX Bastion as that user
3. Verify user can see Linux targets (rhel10-srv, rhel9-srv)
4. Verify user cannot see Windows targets (win-srv-01, win-srv-02)
5. Remove from group, re-test — access should be revoked

EXPECTED RESULT:
- Group membership grants correct access
- Non-member groups produce access denied
- Revocation works on next login

SUCCESS CRITERIA:
[ ] Linux-Admins can access rhel10-srv and rhel9-srv
[ ] Windows-Admins cannot access Linux targets
[ ] Revocation denies access after re-login

+===============================================================================+
```

### Test 7.4: FortiAuthenticator TOTP End-to-End

```
+===============================================================================+
|  TEST 7.4: FORTIAUTH TOTP END-TO-END FLOW                                    |
+===============================================================================+

OBJECTIVE: Verify complete TOTP MFA flow: User -> Bastion -> FortiAuth -> AD

STEPS:
1. Open https://wallix.lab.local (via HAProxy VIP)
2. Enter AD credentials (lab\pam-user / UserPass123!)
3. Receive TOTP challenge (FortiAuthenticator via RADIUS)
4. Enter 6-digit TOTP code from FortiToken Mobile
5. Verify login success
6. Check FortiAuth logs: Admin > Logs > Authentication
7. Check WALLIX Bastion audit log for MFA event

EXPECTED RESULT:
- Password phase: RADIUS Access-Challenge
- TOTP phase: RADIUS Access-Accept
- WALLIX Bastion session created with MFA=true flag

SUCCESS CRITERIA:
[ ] AD password validated
[ ] TOTP challenge presented
[ ] Valid TOTP code accepted
[ ] Audit log shows auth_method=RADIUS+TOTP

LAB NOTE: Push notifications are NOT configured. TOTP only.

+===============================================================================+
```

### Test 7.5: Target Connectivity (All 4 Targets)

```
+===============================================================================+
|  TEST 7.5: TARGET CONNECTIVITY — VLAN 130 (10.10.2.0/24)                     |
+===============================================================================+

OBJECTIVE: Verify wallix-bastion can reach all 4 target VMs in Targets VLAN

STEPS:
1. From WALLIX Bastion web UI, connect to each target:
   - win-srv-01 (10.10.2.10) — RDP as Administrator
   - win-srv-02 (10.10.2.11) — RDP as Administrator
   - rhel10-srv (10.10.2.20) — SSH as root
   - rhel9-srv  (10.10.2.21) — SSH as root
2. Verify session starts and recording begins
3. Execute simple command/action in each session
4. Disconnect and verify recording is available

EXPECTED RESULT:
- All 4 targets connect successfully
- Session recording starts immediately
- Recordings playable after disconnect

SUCCESS CRITERIA:
[ ] win-srv-01 RDP session connects and records
[ ] win-srv-02 RDP session connects and records
[ ] rhel10-srv SSH session connects and records
[ ] rhel9-srv SSH session connects and records

CLIENT TALKING POINT:
"WALLIX Bastion proxies all protocols - RDP, SSH - to target systems
in isolated network segments. No direct user access to targets."

+===============================================================================+
```

---

## Test Results Summary Template

```
+===============================================================================+
|  BATTERY TEST RESULTS SUMMARY                                                 |
+===============================================================================+

  Date:           _______________
  Tester:         _______________
  WALLIX Bastion Version: _______________
  Client:         _______________

  CATEGORY                          PASSED    FAILED    SKIPPED
  ----------------------------------------------------------------
  Authentication Tests              ___/8     ___/8     ___/8
  Session Management Tests          ___/10    ___/10    ___/10
  Password Management Tests         ___/6     ___/6     ___/6
  HAProxy VIP Tests                 ___/5     ___/5     ___/5
  Performance Tests                 ___/5     ___/5     ___/5
  Security Tests                    ___/6     ___/6     ___/6
  Integration Tests                 ___/5     ___/5     ___/5
  ----------------------------------------------------------------
  TOTAL                             ___/45    ___/45    ___/45

  OVERALL STATUS:   [ ] PASS    [ ] CONDITIONAL PASS    [ ] FAIL

  NOTES:
  _______________________________________________________________
  _______________________________________________________________
  _______________________________________________________________

  SIGN-OFF:
  Tester: _________________________ Date: _____________
  Client: _________________________ Date: _____________

+===============================================================================+
```

---

## Quick Demo Script (30 Minutes)

For time-limited client demos, use this abbreviated sequence:

| Time | Test | Key Demonstration |
|------|------|-------------------|
| 0-5 min | [1.4](#test-14-multi-factor-authentication) | TOTP MFA via FortiAuthenticator |
| 5-10 min | [2.1](#test-21-ssh-session-recording) | SSH session shows recording |
| 10-15 min | [2.3](#test-23-real-time-session-monitoring) | Live monitoring impresses |
| 15-20 min | [3.1](#test-31-password-checkout) | Vault shows credential management |
| 20-25 min | [4.2](#test-42-planned-vip-failover) | HAProxy VIP failover demonstrates resilience |
| 25-30 min | [7.1](#test-71-siem-log-forwarding-verification) | SIEM shows security event flow |

---

*Last updated: April 2026 | WALLIX Bastion 12.1.x | Lab: single node (10.10.1.11) | FortiAuthenticator 6.4+ TOTP only | HAProxy Active-Passive (VIP 10.10.1.100)*

---

<p align="center">
  <a href="./13-team-handoffs.md">← Back to Team Handoffs</a> •
  <a href="./README.md">Back to Pre-Production Index</a>
</p>
