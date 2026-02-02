# 11 - Battery Tests for Client Demonstrations

## WALLIX Bastion Comprehensive Test Suite

This document provides a complete battery of tests to demonstrate WALLIX WALLIX Bastion capabilities to clients. Each test includes expected results, success criteria, and talking points for client presentations.

---

## Test Categories

| Category | Tests | Duration | Purpose |
|----------|-------|----------|---------|
| [Authentication Tests](#1-authentication-tests) | 8 | 30 min | MFA, LDAP, Kerberos |
| [Session Management Tests](#2-session-management-tests) | 10 | 45 min | Recording, monitoring |
| [Password Management Tests](#3-password-management-tests) | 6 | 20 min | Vault, rotation |
| [High Availability Tests](#4-high-availability-tests) | 8 | 40 min | Failover, replication |
| [Performance Tests](#5-performance-tests) | 5 | 30 min | Load, stress |
| [Security Tests](#6-security-tests) | 6 | 25 min | Hardening, audit |
| [OT/Industrial Tests](#7-otindustrial-tests) | 5 | 20 min | Protocols, PLCs |

**Total Duration**: ~3.5 hours

---

## Pre-Test Checklist

```
+===============================================================================+
|  PRE-TEST VERIFICATION                                                        |
+===============================================================================+

Before starting battery tests, verify:

[ ] WALLIX Bastion cluster is healthy
    Command: wabadmin status
    Expected: All services running

[ ] HA replication is active
    Command: bastion-replication status
    Expected: Sync Status: OK

[ ] AD integration is working
    Command: Test LDAP bind in Web UI
    Expected: Connection successful

[ ] Test targets are reachable
    Command: ping linux-test && ping windows-test
    Expected: All respond

[ ] Monitoring stack is operational
    Command: curl http://monitor-lab:9090/-/healthy
    Expected: Prometheus is Healthy

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

OBJECTIVE: Verify MFA enforcement for privileged access

STEPS:
1. Login as user with MFA requirement
2. Enter username/password
3. When prompted, enter TOTP code from authenticator app
4. Complete login

EXPECTED RESULT:
- MFA challenge displayed after password
- TOTP code validated
- Session established with MFA flag

SUCCESS CRITERIA:
[ ] MFA prompt appears after password
[ ] Invalid codes are rejected
[ ] Valid codes grant access
[ ] Audit log shows MFA was used

CLIENT TALKING POINT:
"For high-security access, we enforce multi-factor authentication.
This can be TOTP apps, hardware tokens, or integrated with your
existing MFA solution like FortiAuthenticator."

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

## 4. High Availability Tests

### Test 4.1: Cluster Status Verification

```
+===============================================================================+
|  TEST 4.1: CLUSTER STATUS VERIFICATION                                        |
+===============================================================================+

OBJECTIVE: Verify HA cluster is healthy

COMMANDS:
# On any node:
wabadmin status
crm status
bastion-replication status

EXPECTED RESULT:
- All services running on both nodes
- VIP active on one node
- Replication synchronized

SUCCESS CRITERIA:
[ ] wabadmin shows all services running
[ ] crm shows 2 nodes online
[ ] Replication shows 0 seconds lag

CLIENT TALKING POINT:
"The HA cluster is continuously monitored. Both nodes are active,
with real-time database replication ensuring no data loss."

+===============================================================================+
```

### Test 4.2: Active-Active Load Distribution

```
+===============================================================================+
|  TEST 4.2: ACTIVE-ACTIVE LOAD DISTRIBUTION                                    |
+===============================================================================+

OBJECTIVE: Show both nodes handle requests

STEPS:
1. Check which node holds VIP
2. Connect to VIP, verify which node responds
3. Start sessions on both nodes
4. View session distribution

EXPECTED RESULT:
- Sessions can run on either node
- Load is distributed
- Failover is seamless

SUCCESS CRITERIA:
[ ] Sessions work through VIP
[ ] Both nodes handle connections
[ ] No single point of failure

+===============================================================================+
```

### Test 4.3: Planned Failover

```
+===============================================================================+
|  TEST 4.3: PLANNED FAILOVER                                                   |
+===============================================================================+

OBJECTIVE: Demonstrate planned maintenance failover

STEPS:
1. Note which node has VIP (e.g., node1)
2. Start active session through VIP
3. Initiate failover: pcs resource move wallix-vip wallix-node2
4. Observe VIP migration
5. Verify session continues

EXPECTED RESULT:
- VIP moves to node2
- Active sessions continue
- No user disconnection

SUCCESS CRITERIA:
[ ] Failover completes in < 30 seconds
[ ] Sessions remain active
[ ] No data loss

CLIENT TALKING POINT:
"For planned maintenance, we can fail over without any user impact.
Sessions continue uninterrupted while we update or reboot servers."

+===============================================================================+
```

### Test 4.4: Unplanned Failover (Node Failure)

```
+===============================================================================+
|  TEST 4.4: UNPLANNED FAILOVER - NODE FAILURE                                  |
+===============================================================================+

OBJECTIVE: Simulate node crash and verify automatic recovery

STEPS:
1. Note active node with VIP
2. Start active session through VIP
3. SIMULATE FAILURE: systemctl stop pacemaker (on active node)
   Or: Power off active node VM
4. Observe automatic failover
5. Verify session reconnects

EXPECTED RESULT:
- Cluster detects failure
- VIP moves automatically
- Services resume on surviving node

SUCCESS CRITERIA:
[ ] Failover completes in < 60 seconds
[ ] Automatic without intervention
[ ] Alert generated

CLIENT TALKING POINT:
"If a node fails unexpectedly, the cluster automatically fails over.
Users may see a brief disconnect but can immediately reconnect."

+===============================================================================+
```

### Test 4.5: Database Replication Test

```
+===============================================================================+
|  TEST 4.5: DATABASE REPLICATION TEST                                          |
+===============================================================================+

OBJECTIVE: Verify database changes replicate

STEPS:
1. On node1: Create a test authorization
2. On node2: Verify authorization exists
3. Check replication lag

EXPECTED RESULT:
- Change replicates in < 1 second
- Both nodes have identical data
- No replication errors

SUCCESS CRITERIA:
[ ] Replication lag < 1 second
[ ] Data consistent on both nodes
[ ] No replication errors

COMMANDS:
# Check replication status
bastion-replication status

# Create test on node1, verify on node2
wabadmin authorization list

CLIENT TALKING POINT:
"Database replication is synchronous - changes are visible on both
nodes within milliseconds, ensuring no data is ever lost."

+===============================================================================+
```

### Test 4.6: Split-Brain Prevention

```
+===============================================================================+
|  TEST 4.6: SPLIT-BRAIN PREVENTION                                             |
+===============================================================================+

OBJECTIVE: Verify cluster prevents split-brain

STEPS:
1. Block network between nodes (simulate partition)
2. Observe fencing/STONITH activation
3. Verify only one node remains active
4. Restore network, observe recovery

EXPECTED RESULT:
- Fencing isolates one node
- Only one node has VIP
- Services remain consistent

SUCCESS CRITERIA:
[ ] Split-brain prevented
[ ] Fencing works correctly
[ ] Recovery is automatic

CLIENT TALKING POINT:
"Split-brain scenarios are automatically prevented. The cluster uses
fencing to ensure only one node is ever active, preventing data corruption."

+===============================================================================+
```

### Test 4.7: Session Persistence After Failover

```
+===============================================================================+
|  TEST 4.7: SESSION PERSISTENCE AFTER FAILOVER                                 |
+===============================================================================+

OBJECTIVE: Verify session data survives failover

STEPS:
1. Connect session, execute commands
2. Trigger failover
3. Reconnect and verify session recording complete
4. Check audit log shows complete activity

EXPECTED RESULT:
- Session recording is complete
- No gap in audit data
- All commands logged

SUCCESS CRITERIA:
[ ] Recording includes all activity
[ ] No data loss
[ ] Audit trail complete

+===============================================================================+
```

### Test 4.8: Recovery and Rejoin

```
+===============================================================================+
|  TEST 4.8: RECOVERY AND REJOIN                                                |
+===============================================================================+

OBJECTIVE: Verify failed node can rejoin cluster

STEPS:
1. After failover test, start failed node
2. Verify it rejoins cluster
3. Check replication synchronizes
4. Verify both nodes operational

EXPECTED RESULT:
- Node rejoins automatically
- Replication catches up
- Cluster returns to normal

SUCCESS CRITERIA:
[ ] Automatic rejoin
[ ] Full resync completes
[ ] Cluster healthy again

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
crm_mon -1

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

## 7. OT/Industrial Tests

### Test 7.1: Modbus Protocol Proxying

```
+===============================================================================+
|  TEST 7.1: MODBUS PROTOCOL PROXYING                                           |
+===============================================================================+

OBJECTIVE: Demonstrate Modbus session through WALLIX Bastion

STEPS:
1. Configure Modbus target (plc-sim)
2. Connect through WALLIX Bastion
3. Read holding registers
4. Write coil values
5. Verify session recorded

EXPECTED RESULT:
- Modbus connection works
- Read/write operations succeed
- Session is fully audited

SUCCESS CRITERIA:
[ ] Modbus connection establishes
[ ] Register read/write works
[ ] Session recording shows operations

CLIENT TALKING POINT:
"Industrial protocols like Modbus are natively proxied and recorded.
Every PLC access is fully audited, meeting IEC 62443 requirements."

+===============================================================================+
```

### Test 7.2: OPC UA Connection

```
+===============================================================================+
|  TEST 7.2: OPC UA CONNECTION                                                  |
+===============================================================================+

OBJECTIVE: Demonstrate OPC UA session through WALLIX Bastion

STEPS:
1. Configure OPC UA endpoint
2. Connect through WALLIX Bastion
3. Browse address space
4. Read node values
5. Verify recording

EXPECTED RESULT:
- OPC UA session works
- Address space browsable
- All operations logged

SUCCESS CRITERIA:
[ ] OPC UA connection works
[ ] Node values readable
[ ] Session recorded

+===============================================================================+
```

### Test 7.3: Serial/Console Access

```
+===============================================================================+
|  TEST 7.3: SERIAL/CONSOLE ACCESS                                              |
+===============================================================================+

OBJECTIVE: Demonstrate serial console recording

STEPS:
1. Configure serial console target
2. Connect through WALLIX Bastion
3. Execute commands on serial device
4. Verify recording

EXPECTED RESULT:
- Serial access works
- Commands execute
- Session recorded

SUCCESS CRITERIA:
[ ] Serial connection works
[ ] All I/O captured
[ ] Recording complete

CLIENT TALKING POINT:
"Even legacy serial connections to PLCs and RTUs can be recorded.
No protocol is too old or specialized to audit."

+===============================================================================+
```

### Test 7.4: Emergency Access Mode

```
+===============================================================================+
|  TEST 7.4: EMERGENCY ACCESS MODE                                              |
+===============================================================================+

OBJECTIVE: Demonstrate offline credential cache for OT

STEPS:
1. Simulate network isolation from WALLIX Bastion
2. Access cached credentials on local agent
3. Connect to target using cached creds
4. Verify audit sync when reconnected

EXPECTED RESULT:
- Offline access works
- Credentials available from cache
- Audit syncs when online

SUCCESS CRITERIA:
[ ] Cache works offline
[ ] Credentials accessible
[ ] Audit eventually consistent

CLIENT TALKING POINT:
"For air-gapped or intermittently connected OT sites, cached credentials
ensure operations continue even when network is unavailable."

+===============================================================================+
```

### Test 7.5: Vendor Maintenance Access

```
+===============================================================================+
|  TEST 7.5: VENDOR MAINTENANCE ACCESS                                          |
+===============================================================================+

OBJECTIVE: Demonstrate third-party vendor access workflow

STEPS:
1. Create time-limited vendor account
2. Configure access to specific PLC
3. Vendor connects through web portal
4. Vendor performs maintenance
5. Session is recorded
6. Account expires automatically

EXPECTED RESULT:
- Vendor access is time-limited
- Only specified targets accessible
- Full session recording
- Automatic expiration

SUCCESS CRITERIA:
[ ] Time-limited access works
[ ] Scope is restricted
[ ] Recording complete
[ ] Auto-expiration works

CLIENT TALKING POINT:
"Vendor access is controlled with surgical precision - specific targets,
specific timeframes, full recording, and automatic expiration."

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
  High Availability Tests           ___/8     ___/8     ___/8
  Performance Tests                 ___/5     ___/5     ___/5
  Security Tests                    ___/6     ___/6     ___/6
  OT/Industrial Tests               ___/5     ___/5     ___/5
  ----------------------------------------------------------------
  TOTAL                             ___/48    ___/48    ___/48

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
| 0-5 min | [1.2](#test-12-ldap-authentication) | LDAP login shows AD integration |
| 5-10 min | [2.1](#test-21-ssh-session-recording) | SSH session shows recording |
| 10-15 min | [2.3](#test-23-real-time-session-monitoring) | Live monitoring impresses |
| 15-20 min | [3.1](#test-31-password-checkout) | Vault shows credential management |
| 20-25 min | [4.4](#test-44-unplanned-failover-node-failure) | Failover shows HA |
| 25-30 min | [6.5](#test-65-siem-alert-integration) | SIEM shows security integration |

---

<p align="center">
  <a href="./10-team-handoffs.md">← Back to Team Handoffs</a> •
  <a href="./README.md">Back to Pre-Production Index</a>
</p>
