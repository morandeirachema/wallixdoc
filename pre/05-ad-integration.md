# 05 - Active Directory Integration

## Configuring LDAP/AD Authentication for PAM4OT

This guide covers integrating PAM4OT with Active Directory for user authentication.

---

## Integration Overview

```
+==============================================================================+
|                   AD AUTHENTICATION FLOW                                      |
+==============================================================================+

  User Login                PAM4OT                    Active Directory
  ==========                ======                    ================

  1. User enters       2. PAM4OT binds to AD    3. AD validates
     AD credentials        using service account     user credentials

  +--------+          +----------------+          +----------------+
  | jadmin |   --->   |   PAM4OT       |   --->   |  DC-LAB        |
  | ****   |          |                |          |                |
  +--------+          | LDAPS:636      |          | Validate user  |
                      | Bind: wallix-svc|          | Check groups   |
                      +----------------+          +----------------+
                             |                           |
                             |    4. Return user info    |
                             |    & group membership     |
                             |<--------------------------|
                             |
                      5. Map AD groups to
                         PAM4OT permissions

+==============================================================================+
```

---

## Prerequisites

- [ ] AD DC running and accessible (dc-lab.lab.local)
- [ ] LDAPS enabled (port 636)
- [ ] Service account created (wallix-svc)
- [ ] AD CA certificate imported to PAM4OT
- [ ] Test users created in AD

### Verify Connectivity

```bash
# Test LDAPS from PAM4OT node
openssl s_client -connect dc-lab.lab.local:636 -CApath /etc/ssl/certs/

# Test LDAP bind
ldapsearch -x -H ldaps://dc-lab.lab.local:636 \
    -D "CN=wallix-svc,OU=Service Accounts,OU=PAM4OT,DC=lab,DC=local" \
    -W \
    -b "DC=lab,DC=local" \
    "(sAMAccountName=jadmin)"
```

---

## Step 1: Configure LDAP Authentication in PAM4OT

### Via Web UI

1. Login to PAM4OT Admin: `https://pam4ot.lab.local/admin`
2. Navigate to: **Configuration > Authentication > LDAP**
3. Click **Add LDAP Domain**

```
+------------------------------------------------------------------------------+
|  LDAP DOMAIN CONFIGURATION                                                   |
+------------------------------------------------------------------------------+
|                                                                              |
|  GENERAL                                                                     |
|  -------                                                                     |
|  Domain Name:           LAB.LOCAL                                            |
|  Description:           Lab Active Directory                                 |
|  Default Domain:        [x] Yes                                              |
|                                                                              |
|  CONNECTION                                                                  |
|  ----------                                                                  |
|  Server:                dc-lab.lab.local                                     |
|  Port:                  636                                                  |
|  Use SSL/TLS:           [x] LDAPS                                            |
|  Verify Certificate:    [x] Yes (uncheck if using self-signed)              |
|                                                                              |
|  BIND CREDENTIALS                                                            |
|  ----------------                                                            |
|  Bind DN:               CN=wallix-svc,OU=Service Accounts,OU=PAM4OT,         |
|                         DC=lab,DC=local                                      |
|  Bind Password:         WallixSvc123!                                        |
|                                                                              |
|  SEARCH SETTINGS                                                             |
|  ---------------                                                             |
|  Base DN:               DC=lab,DC=local                                      |
|  User Search Filter:    (&(objectClass=user)(sAMAccountName=%s))            |
|  User Search Base:      OU=Users,OU=PAM4OT,DC=lab,DC=local                  |
|                                                                              |
|  ATTRIBUTE MAPPING                                                           |
|  -----------------                                                           |
|  Username Attribute:    sAMAccountName                                       |
|  Display Name:          displayName                                          |
|  Email:                 mail                                                 |
|  Groups:                memberOf                                             |
|                                                                              |
+------------------------------------------------------------------------------+
```

### Via CLI/API

```bash
# Using wabadmin CLI
wabadmin ldap add \
    --name "LAB.LOCAL" \
    --server "dc-lab.lab.local" \
    --port 636 \
    --ssl \
    --bind-dn "CN=wallix-svc,OU=Service Accounts,OU=PAM4OT,DC=lab,DC=local" \
    --bind-password "WallixSvc123!" \
    --base-dn "DC=lab,DC=local" \
    --user-filter "(&(objectClass=user)(sAMAccountName=%s))" \
    --default
```

### Via REST API

```bash
curl -k -X POST "https://pam4ot.lab.local/api/ldapdomains" \
    -H "X-Auth-Token: $API_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "ldapdomain_name": "LAB.LOCAL",
        "ldapdomain_description": "Lab Active Directory",
        "host": "dc-lab.lab.local",
        "port": 636,
        "use_ssl": true,
        "bind_dn": "CN=wallix-svc,OU=Service Accounts,OU=PAM4OT,DC=lab,DC=local",
        "bind_password": "WallixSvc123!",
        "base_dn": "DC=lab,DC=local",
        "user_filter": "(&(objectClass=user)(sAMAccountName=%s))",
        "is_default": true
    }'
```

---

## Step 2: Test LDAP Connection

```
In PAM4OT Web UI:

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

Map AD groups to PAM4OT user groups for authorization.

### Create PAM4OT User Groups

```
Configuration > User Groups > Add

1. Group: LDAP-Admins
   Description: Mapped from PAM4OT-Admins AD group

2. Group: LDAP-Operators
   Description: Mapped from PAM4OT-Operators AD group

3. Group: LDAP-Auditors
   Description: Mapped from PAM4OT-Auditors AD group

4. Group: LDAP-Linux-Admins
   Description: Mapped from Linux-Admins AD group

5. Group: LDAP-OT-Engineers
   Description: Mapped from OT-Engineers AD group
```

### Configure Group Mapping

```
Configuration > Authentication > LDAP > LAB.LOCAL > Group Mapping

+------------------------------------------------------------------------------+
|  AD Group (DN)                                      | PAM4OT Group           |
+-----------------------------------------------------+------------------------+
| CN=PAM4OT-Admins,OU=Groups,OU=PAM4OT,DC=lab,DC=local| LDAP-Admins           |
| CN=PAM4OT-Operators,OU=Groups,OU=PAM4OT,DC=lab,...  | LDAP-Operators        |
| CN=PAM4OT-Auditors,OU=Groups,OU=PAM4OT,DC=lab,...   | LDAP-Auditors         |
| CN=Linux-Admins,OU=Groups,OU=PAM4OT,DC=lab,DC=local | LDAP-Linux-Admins     |
| CN=Windows-Admins,OU=Groups,OU=PAM4OT,DC=lab,...    | LDAP-Windows-Admins   |
| CN=OT-Engineers,OU=Groups,OU=PAM4OT,DC=lab,DC=local | LDAP-OT-Engineers     |
+------------------------------------------------------------------------------+
```

### Via API

```bash
# Add group mapping
curl -k -X POST "https://pam4ot.lab.local/api/ldapdomains/LAB.LOCAL/groupmappings" \
    -H "X-Auth-Token: $API_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "ldap_group": "CN=PAM4OT-Admins,OU=Groups,OU=PAM4OT,DC=lab,DC=local",
        "usergroup": "LDAP-Admins"
    }'
```

---

## Step 4: Configure PAM4OT Profiles for LDAP Groups

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
# SSH to PAM4OT using AD credentials
ssh jadmin@pam4ot.lab.local

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

## Step 6: Configure Kerberos (Optional)

For single sign-on with Kerberos:

### On PAM4OT Node

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

### Configure PAM4OT for Kerberos

```
Configuration > Authentication > Kerberos

Realm: LAB.LOCAL
KDC: dc-lab.lab.local
Admin Server: dc-lab.lab.local

Keytab: (upload keytab file from AD)
```

---

## User Authentication Matrix

| User | AD Groups | PAM4OT Groups | Access Level |
|------|-----------|---------------|--------------|
| jadmin | PAM4OT-Admins, Linux-Admins, Windows-Admins | LDAP-Admins, LDAP-Linux-Admins | Full Admin |
| soperator | PAM4OT-Operators, Linux-Admins | LDAP-Operators, LDAP-Linux-Admins | Operator |
| mauditor | PAM4OT-Auditors | LDAP-Auditors | Audit Only |
| lnetwork | Network-Admins | LDAP-Network-Admins | Network Access |
| totengineer | OT-Engineers | LDAP-OT-Engineers | OT Access |

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
    -D "CN=wallix-svc,OU=Service Accounts,OU=PAM4OT,DC=lab,DC=local" \
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
    -D "CN=wallix-svc,OU=Service Accounts,OU=PAM4OT,DC=lab,DC=local" \
    -W \
    -b "DC=lab,DC=local" \
    "(sAMAccountName=jadmin)" memberOf

# Verify group DN matches exactly in PAM4OT mapping
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

## AD Integration Checklist

| Check | Status |
|-------|--------|
| LDAPS connection works | [ ] |
| Service account can bind | [ ] |
| User search returns results | [ ] |
| Group mapping configured | [ ] |
| Test user can login via web | [ ] |
| Test user can login via SSH | [ ] |
| Groups mapped correctly | [ ] |
| Permissions applied correctly | [ ] |

---

<p align="center">
  <a href="./04-ha-active-active.md">← Previous</a> •
  <a href="./06-test-targets.md">Next: Test Targets Setup →</a>
</p>
