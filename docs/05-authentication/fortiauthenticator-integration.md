# FortiAuthenticator MFA Integration

## Configuring FortiAuthenticator as MFA Provider for WALLIX PAM4OT

This guide covers complete integration of FortiAuthenticator with PAM4OT for multi-factor authentication.

---

## Integration Architecture

```
+===============================================================================+
|                    FORTIAUTHENTICATOR INTEGRATION                             |
+===============================================================================+

  User Login                 PAM4OT                    FortiAuthenticator
  ==========                 ======                    ==================

  1. User enters         2. PAM4OT sends         3. FortiAuth validates
     username/password      RADIUS request           and sends push/OTP

  +------------+         +----------------+         +------------------+
  |   User     |  --->   |    PAM4OT      |  --->   | FortiAuthenticator|
  | username   |         |                |         |                  |
  | password   |         | RADIUS Client  |         | RADIUS Server    |
  +------------+         +----------------+         | Push/SMS/Token   |
       |                        |                   +------------------+
       |                        |                          |
       |    4. MFA Challenge    |                          |
       |<-----------------------|                          |
       |                        |                          |
       |    5. User responds    |    6. Verify response    |
       |----------------------->|------------------------->|
       |                        |                          |
       |                        |    7. Access granted     |
       |                        |<-------------------------|
       |    8. Session starts   |                          |
       |<-----------------------|                          |

  MFA METHODS SUPPORTED:
  - FortiToken Mobile (Push notification)
  - FortiToken Hardware (OTP)
  - SMS OTP
  - Email OTP
  - TOTP (Google Authenticator compatible)

+===============================================================================+
```

---

## Prerequisites

### FortiAuthenticator Requirements

| Item | Requirement |
|------|-------------|
| FortiAuthenticator Version | 6.4+ recommended |
| License | Base + FortiToken licenses for users |
| Network Access | PAM4OT nodes must reach FortiAuth on RADIUS port |
| Users | Synced from AD or local |

### Network Requirements

| Source | Destination | Port | Protocol | Description |
|--------|-------------|------|----------|-------------|
| pam4ot-node1 | FortiAuthenticator | 1812 | UDP | RADIUS Auth |
| pam4ot-node2 | FortiAuthenticator | 1812 | UDP | RADIUS Auth |
| pam4ot-node1 | FortiAuthenticator | 1813 | UDP | RADIUS Accounting |
| pam4ot-node2 | FortiAuthenticator | 1813 | UDP | RADIUS Accounting |
| FortiAuthenticator | AD DC | 636 | TCP | LDAPS (user sync) |

---

## Step 1: Configure FortiAuthenticator

### 1.1 Create RADIUS Client for PAM4OT

**Via FortiAuthenticator Web UI:**

```
1. Login to FortiAuthenticator
   URL: https://fortiauth.company.com

2. Navigate to: Authentication > RADIUS Service > Clients

3. Click "Create New"

4. Configure RADIUS Client:
   Name:           PAM4OT-Cluster
   Client IP/Name: 10.10.1.11
   Secret:         [Strong shared secret - save this!]
   Description:    WALLIX PAM4OT Primary Node

   Authentication:
   [x] Enable
   [ ] Authorize only (no auth)

   Profile:        Default

5. Click OK

6. Repeat for second node:
   Name:           PAM4OT-Node2
   Client IP/Name: 10.10.1.12
   Secret:         [Same shared secret]
```

### 1.2 Configure Authentication Policy

```
1. Navigate to: Authentication > RADIUS Service > Policies

2. Create new policy:
   Name:           PAM4OT-MFA-Policy

   Matching Rules:
   - RADIUS Client: PAM4OT-Cluster, PAM4OT-Node2

   Authentication:
   - First Factor:  LDAP (or Local)
   - Second Factor: FortiToken

   Options:
   [x] Allow Push Notification
   [x] Allow OTP
   [ ] Allow SMS (optional)

   Timeout: 60 seconds

3. Click OK
```

### 1.3 Sync Users from Active Directory

```
1. Navigate to: Authentication > User Management > Remote Users

2. Configure LDAP Remote User Sync:
   Name:           AD-PAM4OT-Users
   Server:         dc-lab.company.com
   Port:           636 (LDAPS)
   Base DN:        OU=Users,OU=PAM4OT,DC=company,DC=com
   Bind DN:        CN=fortiauth-svc,OU=Service Accounts,DC=company,DC=com
   Bind Password:  [Service account password]

   User Filter:    (objectClass=user)
   Group Filter:   (objectClass=group)

   Sync Schedule:  Every 15 minutes

3. Click "Test" to verify connectivity

4. Click "Sync Now" for initial sync
```

### 1.4 Assign FortiTokens to Users

**For FortiToken Mobile:**

```
1. Navigate to: Authentication > User Management > Local Users
   (or Remote Users if synced from AD)

2. Select user (e.g., jadmin)

3. Click "Edit"

4. Token Assignment:
   Token Type:     FortiToken Mobile
   Delivery:       Email activation code

5. Click "Provision Token"

6. User receives email with activation instructions
```

**For Hardware Tokens:**

```
1. Navigate to: Authentication > FortiToken > Hardware Tokens

2. Import tokens (from CSV or manually)

3. Assign to user:
   - Select token serial number
   - Click "Assign"
   - Select user
```

---

## Step 2: Configure PAM4OT

### 2.1 Configure RADIUS Authentication

**Via PAM4OT Web UI:**

```
1. Login to PAM4OT Admin
   URL: https://pam4ot.company.com/admin

2. Navigate to: Configuration > Authentication > External Auth

3. Click "Add RADIUS Server"

4. Configure Primary RADIUS Server:
   Name:               FortiAuth-Primary
   Server Address:     fortiauth.company.com
   Authentication Port: 1812
   Accounting Port:    1813
   Shared Secret:      [Same secret from FortiAuth]
   Timeout:            30 seconds
   Retries:            3

5. Click "Test Connection" - should return "Success"

6. Click "Save"
```

**Via CLI:**

```bash
# Add FortiAuthenticator as RADIUS server
wabadmin auth radius add \
    --name "FortiAuth-Primary" \
    --server "fortiauth.company.com" \
    --port 1812 \
    --secret "[shared-secret]" \
    --timeout 30 \
    --retries 3

# Test connection
wabadmin auth radius test "FortiAuth-Primary"
```

### 2.2 Configure MFA Policy

**Via Web UI:**

```
1. Navigate to: Configuration > Authentication > MFA Policy

2. Configure MFA Settings:

   MFA Provider:       RADIUS (FortiAuth-Primary)

   MFA Required For:
   [x] All users
   [ ] Admin users only
   [ ] Specific groups

   Enforcement:
   [x] Web UI login
   [x] SSH proxy login
   [x] RDP proxy login
   [x] API authentication

   Bypass Options:
   [ ] Allow bypass for internal IPs
   [ ] Allow bypass for specific users

   Timeout:           60 seconds (match FortiAuth policy)

3. Click "Save"
```

**Via CLI:**

```bash
# Enable MFA for all users
wabadmin auth mfa enable \
    --provider radius \
    --server "FortiAuth-Primary" \
    --scope all \
    --enforce web,ssh,rdp,api

# Verify configuration
wabadmin auth mfa status
```

### 2.3 Configure Failover (Optional)

```bash
# Add secondary FortiAuthenticator for HA
wabadmin auth radius add \
    --name "FortiAuth-Secondary" \
    --server "fortiauth-dr.company.com" \
    --port 1812 \
    --secret "[shared-secret]" \
    --priority 2

# Configure failover
wabadmin auth radius failover \
    --primary "FortiAuth-Primary" \
    --secondary "FortiAuth-Secondary" \
    --failover-timeout 5
```

---

## Step 3: Test MFA Integration

### 3.1 Test from PAM4OT

```bash
# Test RADIUS authentication
wabadmin auth test \
    --provider radius \
    --user "jadmin" \
    --password "[password]"

# Expected flow:
# 1. Password validated
# 2. FortiToken push sent to user's phone
# 3. User approves push
# 4. "Authentication successful" message
```

### 3.2 Test User Login

```
1. Open browser to https://pam4ot.company.com

2. Enter credentials:
   Username: jadmin
   Password: [AD password]

3. Click "Login"

4. MFA Challenge appears:
   "Waiting for FortiToken authentication..."

5. On FortiToken Mobile app:
   - Push notification received
   - Review login details
   - Tap "Approve"

6. Login completes, dashboard appears
```

### 3.3 Test SSH Proxy Login

```bash
# Connect via SSH
ssh jadmin@pam4ot.company.com

# Enter password when prompted
Password: [AD password]

# MFA prompt appears:
# "FortiToken verification required. Check your mobile app or enter OTP:"

# Either:
# - Approve push notification on phone, OR
# - Enter 6-digit OTP from FortiToken

# After MFA, target selection appears
```

---

## Step 4: User Enrollment

### 4.1 Self-Service Enrollment

Configure FortiAuthenticator for self-service:

```
1. FortiAuth > Authentication > Self-Service Portal

2. Enable Self-Service:
   [x] Enable self-service portal
   URL: https://fortiauth.company.com/self-service

3. Allowed Actions:
   [x] FortiToken Mobile enrollment
   [x] Password change
   [ ] Account recovery

4. Email user instructions:
```

**User Enrollment Email Template:**

```
Subject: Enable Multi-Factor Authentication for PAM4OT

Dear [User],

Multi-factor authentication (MFA) is now required for PAM4OT access.

ENROLLMENT STEPS:

1. Install FortiToken Mobile app:
   - iOS: App Store > Search "FortiToken Mobile"
   - Android: Play Store > Search "FortiToken Mobile"

2. Activate your token:
   - Open email on your mobile device
   - Click activation link (or scan QR code)
   - FortiToken app opens and registers automatically

3. Test your login:
   - Go to https://pam4ot.company.com
   - Enter username and password
   - Approve push notification on phone

NEED HELP?
Contact IT Support: support@company.com or ext. 1234

Thank you,
IT Security Team
```

### 4.2 Admin-Assisted Enrollment

```bash
# Generate enrollment token for user
# On FortiAuthenticator:
1. User Management > Users > [select user]
2. Token > Provision FortiToken Mobile
3. Send activation email

# On PAM4OT, verify user can authenticate:
wabadmin auth test --user "[username]" --provider radius
```

---

## Troubleshooting

### Common Issues

#### "RADIUS server not responding"

```bash
# Check network connectivity
nc -zvu fortiauth.company.com 1812

# Check firewall rules
iptables -L -n | grep 1812

# Verify shared secret matches
# On PAM4OT:
wabadmin auth radius show "FortiAuth-Primary"

# On FortiAuthenticator:
# Authentication > RADIUS Service > Clients > PAM4OT-Cluster
```

#### "MFA timeout - no response"

```bash
# Check FortiAuthenticator logs
# FortiAuth > Monitor > Logs > Authentication

# Common causes:
# - User didn't receive push (check FortiToken app)
# - User's token not properly activated
# - Network latency (increase timeout)

# Increase timeout:
wabadmin auth mfa set-timeout 90
```

#### "Invalid OTP"

```bash
# Check time synchronization
# FortiAuthenticator and PAM4OT must have synchronized time

# On PAM4OT:
chronyc tracking

# On FortiAuthenticator:
# System > Administration > Time

# If tokens are out of sync:
# FortiAuth > Authentication > FortiToken > [token] > Resync
```

#### "User not found in RADIUS"

```bash
# Verify user exists in FortiAuthenticator
# FortiAuth > User Management > Remote Users > Search

# Force LDAP sync
# FortiAuth > Authentication > Remote User Sync > Sync Now

# Check LDAP filter in FortiAuth includes the user
```

### Debug Mode

```bash
# Enable RADIUS debug logging on PAM4OT
wabadmin log level radius debug

# View real-time logs
tail -f /var/log/wabengine/radius.log

# Test with debug output
wabadmin auth test \
    --user "jadmin" \
    --provider radius \
    --debug

# Disable debug when done
wabadmin log level radius info
```

---

## MFA Bypass Procedures

### Temporary Bypass (Emergency)

```bash
# For emergencies when FortiAuthenticator is unavailable

# Option 1: Bypass for specific user (time-limited)
wabadmin auth mfa bypass \
    --user "jadmin" \
    --duration 1h \
    --reason "FortiAuth maintenance"

# Option 2: Use breakglass account (pre-configured without MFA)
# Account: breakglass-admin
# This should be heavily monitored

# Log all bypass events
wabadmin audit search --type mfa-bypass --last 24h
```

### Disable MFA (Maintenance Window)

```bash
# Schedule maintenance window
# NEVER do this without approval

# Temporarily disable MFA
wabadmin auth mfa disable \
    --scheduled-start "2026-01-30T02:00:00Z" \
    --scheduled-end "2026-01-30T04:00:00Z" \
    --reason "FortiAuthenticator upgrade"

# Notifications sent automatically to security team
```

---

## High Availability Configuration

### FortiAuthenticator HA

```
FortiAuth Primary:    fortiauth.company.com     (10.10.1.70)
FortiAuth Secondary:  fortiauth-dr.company.com  (10.10.1.71)
```

### PAM4OT RADIUS Failover

```bash
# Configure both FortiAuth servers
wabadmin auth radius add \
    --name "FortiAuth-Primary" \
    --server "fortiauth.company.com" \
    --port 1812 \
    --secret "[secret]" \
    --priority 1

wabadmin auth radius add \
    --name "FortiAuth-Secondary" \
    --server "fortiauth-dr.company.com" \
    --port 1812 \
    --secret "[secret]" \
    --priority 2

# Enable automatic failover
wabadmin auth radius failover enable \
    --check-interval 30 \
    --failback-delay 300
```

---

## Security Best Practices

### Token Security

```
1. Require PIN on FortiToken Mobile app
2. Enable biometric unlock (fingerprint/face)
3. Disable token backup to cloud
4. Revoke tokens immediately when user leaves
5. Regular token inventory audits
```

### RADIUS Security

```
1. Use strong shared secrets (32+ characters)
2. Enable RADIUS accounting for audit trail
3. Limit RADIUS clients to PAM4OT IPs only
4. Use separate VLAN for RADIUS traffic
5. Monitor for RADIUS authentication failures
```

### Monitoring

```bash
# Alert on MFA failures
wabadmin alert create \
    --name "MFA-Failures" \
    --condition "mfa_failures > 5 in 5m" \
    --action email \
    --recipient security@company.com

# Daily MFA report
wabadmin report schedule \
    --type mfa-summary \
    --frequency daily \
    --recipient security@company.com
```

---

## Quick Reference

### FortiAuthenticator URLs

| Purpose | URL |
|---------|-----|
| Admin Console | https://fortiauth.company.com/admin |
| Self-Service Portal | https://fortiauth.company.com/self-service |
| RADIUS Port | 1812/UDP |

### PAM4OT MFA Commands

```bash
# Check MFA status
wabadmin auth mfa status

# Test MFA for user
wabadmin auth test --user USERNAME --provider radius

# Bypass MFA temporarily
wabadmin auth mfa bypass --user USERNAME --duration 1h

# View MFA audit logs
wabadmin audit search --type mfa --last 24h
```

---

<p align="center">
  <a href="./README.md">← Back to Authentication</a>
</p>
