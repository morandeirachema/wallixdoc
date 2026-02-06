# 06 - Active Directory Integration with MFA

## Configuring LDAP/AD Authentication and Multi-Factor Authentication for WALLIX Bastion

This guide covers integrating WALLIX Bastion with Active Directory for user authentication and FortiAuthenticator for MFA.

---

## Integration Overview

```
+===============================================================================+
|                    AD + MFA AUTHENTICATION FLOW                               |
+===============================================================================+

  User Login          WALLIX Bastion           FortiAuth       Active Directory
  ==========          ======                   =========       ================

  1. User enters      2. WALLIX Bastion sends  3. FortiAuth    4. FortiAuth
     credentials        RADIUS req             validates        queries AD
                                               TOTP code

  +----------+       +-------------+      +----------+      +-------------+
  |  jadmin  |------>|WALLIXBastion|----->|FortiAuth |----->|   DC-LAB    |
  | password |HTTPS  |             |RADIUS|          | LDAP |             |
  | + TOTP   |       |10.10.1.11   |:1812 |10.10.1.50|:389  | 10.10.0.10  |
  +----------+       +-------------+      +----------+      +-------------+
                           |                  |                 |
                           |<-Access-Accept---|<--User Info-----|
                           |   + Attributes   |
                           |
                     5. Grant access based
                        on AD groups + MFA

+===============================================================================+
```

---

## Prerequisites

- [ ] AD DC running and accessible (dc-lab.lab.local)
- [ ] LDAPS enabled (port 636)
- [ ] Service account created (wallix-svc)
- [ ] AD CA certificate imported to WALLIX Bastion
- [ ] Test users created in AD
- [ ] FortiAuthenticator configured (see [04-fortiauthenticator-setup.md](./04-fortiauthenticator-setup.md))
- [ ] Users imported into FortiAuth with MFA tokens activated

### Verify Connectivity

```bash
# Test LDAPS from WALLIX Bastion node
openssl s_client -connect dc-lab.lab.local:636 -CApath /etc/ssl/certs/

# Test LDAP bind
ldapsearch -x -H ldaps://dc-lab.lab.local:636 \
    -D "CN=wallix-svc,OU=Service Accounts,OU=WALLIX Bastion,DC=lab,DC=local" \
    -W \
    -b "DC=lab,DC=local" \
    "(sAMAccountName=jadmin)"
```

---

## Step 1: Configure LDAP Authentication in WALLIX Bastion

### Via Web UI

1. Login to WALLIX Bastion Admin: `https://wallix.lab.local/admin`
2. Navigate to: **Configuration > Authentication > LDAP**
3. Click **Add LDAP Domain**

```
+===============================================================================+
|  LDAP DOMAIN CONFIGURATION                                                    |
+===============================================================================+
|                                                                               |
|  GENERAL                                                                      |
|  -------                                                                      |
|  Domain Name:           LAB.LOCAL                                             |
|  Description:           Lab Active Directory                                  |
|  Default Domain:        [x] Yes                                               |
|                                                                               |
|  CONNECTION                                                                   |
|  ----------                                                                   |
|  Server:                dc-lab.lab.local                                      |
|  Port:                  636                                                   |
|  Use SSL/TLS:           [x] LDAPS                                             |
|  Verify Certificate:    [x] Yes (uncheck if using self-signed)                |
|                                                                               |
|  BIND CREDENTIALS                                                             |
|  ----------------                                                             |
|  Bind DN:               CN=wallix-svc,OU=Service Accounts,OU=WALLIX Bastion,  |
|                         DC=lab,DC=local                                       |
|  Bind Password:         WallixSvc123!                                         |
|                                                                               |
|  SEARCH SETTINGS                                                              |
|  ---------------                                                              |
|  Base DN:               DC=lab,DC=local                                       |
|  User Search Filter:    (&(objectClass=user)(sAMAccountName=%s))              |
|  User Search Base:      OU=Users,OU=WALLIX Bastion,DC=lab,DC=local            |
|                                                                               |
|  ATTRIBUTE MAPPING                                                            |
|  -----------------                                                            |
|  Username Attribute:    sAMAccountName                                        |
|  Display Name:          displayName                                           |
|  Email:                 mail                                                  |
|  Groups:                memberOf                                              |
|                                                                               |
+===============================================================================+
```

### Via CLI/API

```bash
# Using wabadmin CLI
wabadmin ldap add \
    --name "LAB.LOCAL" \
    --server "dc-lab.lab.local" \
    --port 636 \
    --ssl \
    --bind-dn "CN=wallix-svc,OU=Service Accounts,OU=WALLIX Bastion,DC=lab,DC=local" \
    --bind-password "WallixSvc123!" \
    --base-dn "DC=lab,DC=local" \
    --user-filter "(&(objectClass=user)(sAMAccountName=%s))" \
    --default
```

### Via REST API

```bash
curl -k -X POST "https://wallix.lab.local/api/ldapdomains" \
    -H "X-Auth-Token: $API_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "ldapdomain_name": "LAB.LOCAL",
        "ldapdomain_description": "Lab Active Directory",
        "host": "dc-lab.lab.local",
        "port": 636,
        "use_ssl": true,
        "bind_dn": "CN=wallix-svc,OU=Service Accounts,OU=WALLIX Bastion,DC=lab,DC=local",
        "bind_password": "WallixSvc123!",
        "base_dn": "DC=lab,DC=local",
        "user_filter": "(&(objectClass=user)(sAMAccountName=%s))",
        "is_default": true
    }'
```

---

## Step 2: Test LDAP Connection

```
In WALLIX Bastion Web UI:

Configuration > Authentication > LDAP > LAB.LOCAL > Test Connection

Expected: "Connection successful"
```

```bash
# Via CLI
wabadmin ldap test LAB.LOCAL

# Test user lookup
wabadmin ldap search LAB.LOCAL "jadmin"
```

---

## Step 3: Configure Group Mapping

Map AD groups to WALLIX Bastion user groups for authorization.

### Create WALLIX Bastion User Groups

```
Configuration > User Groups > Add

1. Group: LDAP-Admins
   Description: Mapped from WALLIX Bastion-Admins AD group

2. Group: LDAP-Operators
   Description: Mapped from WALLIX Bastion-Operators AD group

3. Group: LDAP-Auditors
   Description: Mapped from WALLIX Bastion-Auditors AD group

4. Group: LDAP-Linux-Admins
   Description: Mapped from Linux-Admins AD group

5. Group: LDAP-OT-Engineers
   Description: Mapped from OT-Engineers AD group
```

### Configure Group Mapping

```
Configuration > Authentication > LDAP > LAB.LOCAL > Group Mapping

+======================================================================================+
| AD Group (DN)                                       | WALLIX Bastion Group           |
+======================================================================================+
| CN=WALLIX Bastion-Admins,OU=Groups,OU=WALLIX Bastion,DC=lab,DC=local| LDAP-Admins    |
| CN=WALLIX Bastion-Operators,OU=Groups,OU=WALLIX Bastion,DC=lab,...  | LDAP-Operators |
| CN=WALLIX Bastion-Auditors,OU=Groups,OU=WALLIX Bastion,DC=lab,...   | LDAP-Auditors  |
| CN=Linux-Admins,OU=Groups,OU=WALLIX Bastion,DC=lab,DC=local | LDAP-Linux-Admins      |
| CN=Windows-Admins,OU=Groups,OU=WALLIX Bastion,DC=lab,...    | LDAP-Windows-Admins    |
| CN=OT-Engineers,OU=Groups,OU=WALLIX Bastion,DC=lab,DC=local | LDAP-OT-Engineers      |
+======================================================================================+
```

### Via API

```bash
# Add group mapping
curl -k -X POST "https://wallix.lab.local/api/ldapdomains/LAB.LOCAL/groupmappings" \
    -H "X-Auth-Token: $API_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "ldap_group": "CN=WALLIX Bastion-Admins,OU=Groups,OU=WALLIX Bastion,DC=lab,DC=local",
        "usergroup": "LDAP-Admins"
    }'
```

---

## Step 4: Configure WALLIX Bastion Profiles for LDAP Groups

### Admin Profile

```
Configuration > Profiles > Add

Name: LDAP-Admin-Profile
User Group: LDAP-Admins

Permissions:
[x] Administration access
[x] Configuration access
[x] Audit access
[x] User management
[x] Device management
[x] Authorization management
```

### Operator Profile

```
Name: LDAP-Operator-Profile
User Group: LDAP-Operators

Permissions:
[ ] Administration access
[x] Configuration access (read-only)
[x] Audit access
[ ] User management
[ ] Device management
[ ] Authorization management
```

### Auditor Profile

```
Name: LDAP-Auditor-Profile
User Group: LDAP-Auditors

Permissions:
[ ] Administration access
[ ] Configuration access
[x] Audit access
[x] Session playback
[ ] User management
[ ] Device management
```

---

## Step 5: Test AD Authentication

### Test Login via Web UI

1. Logout from admin account
2. On login page, enter:
   - Username: `jadmin` (or `LAB\jadmin`)
   - Password: `JohnAdmin123!`
3. Verify login succeeds
4. Check user has correct permissions based on AD group membership

### Test Login via SSH Proxy

```bash
# SSH to WALLIX Bastion using AD credentials
ssh jadmin@wallix.lab.local

# When prompted:
# Password: JohnAdmin123!
# Then select target system
```

### Verify Group Membership

```
As admin, check:
Configuration > Users > jadmin (LDAP)

Should show:
- Source: LDAP (LAB.LOCAL)
- Groups: LDAP-Admins, LDAP-Linux-Admins, LDAP-Windows-Admins
```

---

## Step 6: Configure RADIUS for MFA

### Enable RADIUS Authentication in WALLIX Bastion

**Navigate to: Configuration > Authentication > RADIUS**

Click **Add RADIUS Server**:

```
+===============================================================================+
|  RADIUS SERVER CONFIGURATION                                                  |
+===============================================================================+
|                                                                               |
|  GENERAL                                                                      |
|  -------                                                                      |
|  Name:                  FortiAuth-MFA                                         |
|  Description:           FortiAuthenticator for MFA                            |
|                                                                               |
|  CONNECTION                                                                   |
|  ----------                                                                   |
|  Primary Server:        10.10.1.50                                            |
|  Port:                  1812                                                  |
|  Secret:                WallixRadius2026!                                     |
|  Timeout:               30 seconds                                            |
|  Retries:               3                                                     |
|                                                                               |
|  AUTHENTICATION                                                               |
|  --------------                                                               |
|  [x] Enable RADIUS authentication                                             |
|  [x] Use for two-factor authentication                                        |
|  Password Format:       password+token (concatenated)                         |
|                                                                               |
|  FALLBACK                                                                     |
|  --------                                                                     |
|  Fallback to LDAP:      No (MFA required)                                     |
|                                                                               |
+===============================================================================+
```

### Test RADIUS Connection

```bash
# From WALLIX Bastion node
apt install -y freeradius-utils

# Test RADIUS authentication with MFA
# Password format: AD_Password + TOTP_Code
radtest jadmin "JohnAdmin123!123456" 10.10.1.50 0 WallixRadius2026!

# Expected: Access-Accept
```

---

## Step 7: Configure Authentication Chain

### Enable MFA for User Groups

**Navigate to: Configuration > User Groups**

For each user group, configure MFA:

```
+===============================================================================+
|  USER GROUP - LDAP-Admins (MFA CONFIGURATION)                                 |
+===============================================================================+
|                                                                               |
|  AUTHENTICATION                                                               |
|  --------------                                                               |
|  Primary Auth:          LDAP (LAB.LOCAL)                                      |
|  [x] Require two-factor authentication                                        |
|  2FA Method:            RADIUS                                                |
|  RADIUS Server:         FortiAuth-MFA                                         |
|                                                                               |
|  PASSWORD FORMAT                                                              |
|  ---------------                                                              |
|  Format:                password+token                                        |
|  Description:           User enters AD password followed immediately by       |
|                         6-digit TOTP code from FortiToken Mobile              |
|  Example:               MyPassword123!456789                                  |
|                                                                               |
+===============================================================================+
```

### Alternative: Separate Prompt for MFA

If you want users to enter password and OTP separately:

```
Configuration > Authentication > Settings

[x] Use separate MFA prompt
    User will enter password first, then be prompted for OTP code
```

---

## Step 8: Configure Authentication Chain (LDAP + RADIUS)

**Navigate to: Configuration > Authentication > Authentication Chain**

```
+===============================================================================+
|  AUTHENTICATION CHAIN CONFIGURATION                                           |
+===============================================================================+
|                                                                               |
|  Chain Name:            AD-MFA-Chain                                          |
|  Description:           Active Directory with FortiAuthenticator MFA          |
|                                                                               |
|  AUTHENTICATION METHODS (in order)                                            |
|  ----------------------------------                                           |
|  1. LDAP Domain:        LAB.LOCAL                                             |
|     Purpose:            Validate AD credentials and retrieve group membership |
|                                                                               |
|  2. RADIUS Server:      FortiAuth-MFA                                         |
|     Purpose:            Validate TOTP/MFA token                               |
|     Required:           Yes (authentication fails if RADIUS fails)            |
|                                                                               |
|  BEHAVIOR                                                                     |
|  --------                                                                     |
|  [x] Require all methods to succeed                                           |
|  [x] Stop on first failure                                                    |
|  [ ] Allow fallback to local authentication                                   |
|                                                                               |
+===============================================================================+
```

---

## Step 9: Test MFA Authentication

### Web UI Login Test

1. Navigate to: `https://10.10.1.100`
2. Enter credentials:
   ```
   Username: jadmin
   Password: JohnAdmin123!456789
            └─ AD Password ─┘└─ TOTP ─┘
   ```
3. Click **Login**
4. Verify successful authentication

**Expected behavior:**
- WALLIX Bastion validates AD password via LDAP
- WALLIX Bastion sends full credential to FortiAuth via RADIUS
- FortiAuth validates TOTP code
- User logged in with correct AD group permissions

### SSH Login Test

```bash
# SSH to WALLIX Bastion
ssh jadmin@10.10.1.100

# Enter password when prompted:
Password: JohnAdmin123!456789

# Should display target menu
```

### RDP Login Test

```bash
# From Windows client, open mstsc.exe
# Computer: 10.10.1.100
# Username: jadmin@windows-server01
# Password: JohnAdmin123!456789

# Should connect through WALLIX Bastion with MFA
```

---

## Step 10: Configure Kerberos (Optional)

For single sign-on with Kerberos:

### On WALLIX Bastion Node

```bash
# Install Kerberos client
apt install -y krb5-user

# Configure /etc/krb5.conf
cat > /etc/krb5.conf << 'EOF'
[libdefaults]
    default_realm = LAB.LOCAL
    dns_lookup_realm = false
    dns_lookup_kdc = true

[realms]
    LAB.LOCAL = {
        kdc = dc-lab.lab.local
        admin_server = dc-lab.lab.local
    }

[domain_realm]
    .lab.local = LAB.LOCAL
    lab.local = LAB.LOCAL
EOF

# Test Kerberos
kinit jadmin@LAB.LOCAL
# Enter password: JohnAdmin123!

klist
# Should show valid ticket
```

### Configure WALLIX Bastion for Kerberos

```
Configuration > Authentication > Kerberos

Realm: LAB.LOCAL
KDC: dc-lab.lab.local
Admin Server: dc-lab.lab.local

Keytab: (upload keytab file from AD)
```

---

## User Authentication Matrix

| User | AD Groups | WALLIX Bastion Groups | MFA | Access Level |
|------|-----------|---------------|-----|--------------|
| jadmin | WALLIX Bastion-Admins, Linux-Admins, Windows-Admins | LDAP-Admins, LDAP-Linux-Admins | Required | Full Admin |
| soperator | WALLIX Bastion-Operators, Linux-Admins | LDAP-Operators, LDAP-Linux-Admins | Required | Operator |
| mauditor | WALLIX Bastion-Auditors | LDAP-Auditors | Required | Audit Only |
| lnetwork | Network-Admins | LDAP-Network-Admins | Required | Network Access |
| totengineer | OT-Engineers | LDAP-OT-Engineers | Required | OT Access |

---

## Troubleshooting

### Login Fails: "Invalid credentials"

```bash
# Test LDAP bind directly
ldapsearch -x -H ldaps://dc-lab.lab.local:636 \
    -D "jadmin@lab.local" \
    -W \
    -b "DC=lab,DC=local" \
    "(sAMAccountName=jadmin)"

# Check user exists and is enabled in AD
# Check password is correct
# Check account is not locked
```

### Login Fails: "User not found"

```bash
# Check search filter and base DN
ldapsearch -x -H ldaps://dc-lab.lab.local:636 \
    -D "CN=wallix-svc,OU=Service Accounts,OU=WALLIX Bastion,DC=lab,DC=local" \
    -W \
    -b "DC=lab,DC=local" \
    "(&(objectClass=user)(sAMAccountName=jadmin))"

# Verify user is in correct OU
# Check search base DN includes user's OU
```

### Groups Not Mapped

```bash
# Check user's group membership in AD
ldapsearch -x -H ldaps://dc-lab.lab.local:636 \
    -D "CN=wallix-svc,OU=Service Accounts,OU=WALLIX Bastion,DC=lab,DC=local" \
    -W \
    -b "DC=lab,DC=local" \
    "(sAMAccountName=jadmin)" memberOf

# Verify group DN matches exactly in WALLIX Bastion mapping
```

### Certificate Error

```bash
# Check certificate chain
openssl s_client -connect dc-lab.lab.local:636 -showcerts

# Verify CA cert imported
ls -la /usr/local/share/ca-certificates/

# Re-import if needed
update-ca-certificates
```

---

## AD Integration with MFA Checklist

| Check | Status |
|-------|--------|
| LDAPS connection works | [ ] |
| Service account can bind | [ ] |
| User search returns results | [ ] |
| Group mapping configured | [ ] |
| FortiAuth RADIUS configured | [ ] |
| RADIUS connection test successful | [ ] |
| MFA enabled for user groups | [ ] |
| Test user can login via web with MFA | [ ] |
| Test user can login via SSH with MFA | [ ] |
| Test user can login via RDP with MFA | [ ] |
| Groups mapped correctly | [ ] |
| Permissions applied correctly | [ ] |
| Authentication logs visible in FortiAuth | [ ] |

---

<p align="center">
  <a href="./05-wallix-rds-setup.md">← Previous: WALLIX RDS Setup</a> •
  <a href="./07-wallix-installation.md">Next: WALLIX Bastion Installation →</a>
</p>
