# LDAP/AD Troubleshooting Guide

## Diagnosing and Resolving Active Directory Integration Issues

This guide covers troubleshooting LDAP/AD authentication and sync problems with WALLIX Bastion.

---

## Quick Diagnosis Flowchart

```
+===============================================================================+
|                    LDAP/AD TROUBLESHOOTING FLOWCHART                          |
+===============================================================================+

  User can't login with AD credentials?
            |
            v
  +-------------------+
  | Can WALLIX Bastion reach  |     NO
  | AD on port 636?   |-----------> Check network/firewall
  +-------------------+
            | YES
            v
  +-------------------+
  | Does service      |     NO
  | account bind work?|-----------> Check service account creds
  +-------------------+
            | YES
            v
  +-------------------+
  | Is user found     |     NO
  | in LDAP search?   |-----------> Check search base/filter
  +-------------------+
            | YES
            v
  +-------------------+
  | Are user's groups |     NO
  | being mapped?     |-----------> Check group mapping config
  +-------------------+
            | YES
            v
  Check user password / account status in AD

+===============================================================================+
```

---

## Step 1: Verify Network Connectivity

### Test LDAPS Connection

```bash
# Test LDAPS port (636)
nc -zv dc-lab.company.com 636

# Test with OpenSSL
openssl s_client -connect dc-lab.company.com:636 -showcerts

# Test LDAP port (389) - if not using TLS
nc -zv dc-lab.company.com 389
```

### Verify DNS Resolution

```bash
# Resolve AD DC
nslookup dc-lab.company.com
dig dc-lab.company.com

# Resolve domain
nslookup _ldap._tcp.company.com
dig _ldap._tcp.company.com SRV
```

### Check Certificate Trust

```bash
# View AD certificate
echo | openssl s_client -connect dc-lab.company.com:636 2>/dev/null | \
  openssl x509 -noout -subject -issuer -dates

# Check if CA is trusted
openssl s_client -connect dc-lab.company.com:636 -CApath /etc/ssl/certs/ </dev/null

# If "Verify return code: 0 (ok)" = trusted
# If "Verify return code: 18/19/20" = certificate issue
```

---

## Step 2: Verify Service Account

### Test Service Account Bind

```bash
# Test LDAP bind with service account
ldapsearch -x -H ldaps://dc-lab.company.com:636 \
    -D "CN=wallix-svc,OU=Service Accounts,OU=WALLIX Bastion,DC=company,DC=com" \
    -W \
    -b "DC=company,DC=com" \
    "(sAMAccountName=wallix-svc)"

# Enter password when prompted
# Should return the service account's attributes
```

### Common Bind Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `ldap_bind: Invalid credentials (49)` | Wrong password | Reset service account password |
| `ldap_bind: Invalid DN syntax (34)` | Malformed DN | Fix DN format |
| `ldap_bind: Can't contact LDAP server (-1)` | Network/TLS issue | Check connectivity/cert |
| `ldap_bind: Strong(er) authentication required (8)` | LDAPS required | Use port 636 with TLS |

### Verify in WALLIX Bastion

```bash
# Check LDAP configuration
wabadmin ldap show

# Test LDAP connection
wabadmin ldap test "LAB.LOCAL"

# Expected: "Connection successful"
```

---

## Step 3: Verify User Search

### Test User Search Directly

```bash
# Search for specific user
ldapsearch -x -H ldaps://dc-lab.company.com:636 \
    -D "CN=wallix-svc,OU=Service Accounts,OU=WALLIX Bastion,DC=company,DC=com" \
    -W \
    -b "OU=Users,OU=WALLIX Bastion,DC=company,DC=com" \
    "(sAMAccountName=jadmin)"

# Should return user's DN and attributes
```

### Common Search Issues

#### "User not found"

**Diagnosis:**
```bash
# Check if user is in correct OU
ldapsearch -x -H ldaps://dc-lab.company.com:636 \
    -D "CN=wallix-svc,OU=Service Accounts,OU=WALLIX Bastion,DC=company,DC=com" \
    -W \
    -b "DC=company,DC=com" \
    "(sAMAccountName=jadmin)" dn

# Note the DN returned - is it in the search base?
```

**Solution:**
```bash
# Option 1: Expand search base in WALLIX Bastion
wabadmin ldap modify "LAB.LOCAL" \
    --base-dn "DC=company,DC=com"

# Option 2: Move user to correct OU in AD
# (Use AD Users and Computers)
```

#### "Multiple users found"

```bash
# Check for duplicate usernames
ldapsearch -x -H ldaps://dc-lab.company.com:636 \
    -D "CN=wallix-svc,OU=Service Accounts,OU=WALLIX Bastion,DC=company,DC=com" \
    -W \
    -b "DC=company,DC=com" \
    "(sAMAccountName=jadmin)" dn | grep "dn:"
```

### Verify Search Filter

```bash
# Check WALLIX Bastion search filter
wabadmin ldap show "LAB.LOCAL" | grep filter

# Default filter: (&(objectClass=user)(sAMAccountName=%s))

# Test filter manually
ldapsearch -x -H ldaps://dc-lab.company.com:636 \
    -D "CN=wallix-svc,OU=Service Accounts,OU=WALLIX Bastion,DC=company,DC=com" \
    -W \
    -b "OU=Users,OU=WALLIX Bastion,DC=company,DC=com" \
    "(&(objectClass=user)(sAMAccountName=jadmin))"
```

---

## Step 4: Verify Group Membership

### Check User's Groups in AD

```bash
# Get user's group membership
ldapsearch -x -H ldaps://dc-lab.company.com:636 \
    -D "CN=wallix-svc,OU=Service Accounts,OU=WALLIX Bastion,DC=company,DC=com" \
    -W \
    -b "DC=company,DC=com" \
    "(sAMAccountName=jadmin)" memberOf

# Returns:
# memberOf: CN=WALLIX Bastion-Admins,OU=Groups,OU=WALLIX Bastion,DC=company,DC=com
# memberOf: CN=Linux-Admins,OU=Groups,OU=WALLIX Bastion,DC=company,DC=com
```

### Check Group Mapping in WALLIX Bastion

```bash
# List group mappings
wabadmin ldap groups "LAB.LOCAL"

# Add missing mapping
wabadmin ldap group-map "LAB.LOCAL" \
    --ad-group "CN=WALLIX Bastion-Admins,OU=Groups,OU=WALLIX Bastion,DC=company,DC=com" \
    --wallix-group "LDAP-Admins"
```

### Nested Group Issues

```bash
# AD nested groups may not resolve automatically
# Check if user is in nested group:

# Get all groups (including nested)
ldapsearch -x -H ldaps://dc-lab.company.com:636 \
    -D "CN=wallix-svc,OU=Service Accounts,OU=WALLIX Bastion,DC=company,DC=com" \
    -W \
    -b "DC=company,DC=com" \
    "(&(objectClass=group)(member:1.2.840.113556.1.4.1941:=CN=jadmin,OU=Users,OU=WALLIX Bastion,DC=company,DC=com))"

# If nested groups not resolving in WALLIX Bastion:
wabadmin ldap modify "LAB.LOCAL" --nested-groups true
```

---

## Step 5: Verify User Authentication

### Test User Authentication

```bash
# Test user credentials via LDAP bind
ldapsearch -x -H ldaps://dc-lab.company.com:636 \
    -D "jadmin@company.com" \
    -W \
    -b "DC=company,DC=com" \
    "(sAMAccountName=jadmin)"

# Enter user's password
# If bind succeeds, credentials are correct
```

### Check Account Status in AD

```bash
# Check if account is enabled/locked
ldapsearch -x -H ldaps://dc-lab.company.com:636 \
    -D "CN=wallix-svc,OU=Service Accounts,OU=WALLIX Bastion,DC=company,DC=com" \
    -W \
    -b "DC=company,DC=com" \
    "(sAMAccountName=jadmin)" userAccountControl lockoutTime

# userAccountControl: 512 = Normal account
# userAccountControl: 514 = Disabled
# userAccountControl: 66048 = Password never expires
# lockoutTime: (non-zero) = Account locked
```

### Account Status Decoder

| userAccountControl | Meaning |
|-------------------|---------|
| 512 | Normal account |
| 514 | Disabled |
| 544 | Enabled, password not required |
| 66048 | Normal + password never expires |
| 66050 | Disabled + password never expires |
| 262656 | Smart card required |

---

## Step 6: Common Error Messages

### "Invalid credentials"

**Causes:**
- Wrong password
- Account disabled
- Account locked
- Password expired

**Diagnosis:**
```bash
# Check account in AD
Get-ADUser jadmin -Properties Enabled,LockedOut,PasswordExpired,PasswordLastSet

# Or via ldapsearch
ldapsearch -x -H ldaps://dc-lab.company.com:636 \
    -D "CN=wallix-svc,OU=Service Accounts,OU=WALLIX Bastion,DC=company,DC=com" \
    -W \
    -b "DC=company,DC=com" \
    "(sAMAccountName=jadmin)" \
    userAccountControl pwdLastSet lockoutTime
```

### "User not found in directory"

**Causes:**
- User not in search base DN
- Search filter doesn't match user
- Service account can't see user (permissions)

**Diagnosis:**
```bash
# Search entire directory
ldapsearch -x -H ldaps://dc-lab.company.com:636 \
    -D "CN=wallix-svc,OU=Service Accounts,OU=WALLIX Bastion,DC=company,DC=com" \
    -W \
    -b "DC=company,DC=com" \
    "(sAMAccountName=jadmin)" dn

# If found, update WALLIX Bastion search base
wabadmin ldap modify "LAB.LOCAL" \
    --search-base "DC=company,DC=com"
```

### "Certificate verification failed"

**Causes:**
- Self-signed certificate not trusted
- CA certificate not imported
- Certificate hostname mismatch

**Diagnosis:**
```bash
# Check certificate details
echo | openssl s_client -connect dc-lab.company.com:636 2>/dev/null | \
  openssl x509 -noout -text | grep -E "Subject:|DNS:|Issuer:"
```

**Solution:**
```bash
# Import AD CA certificate
scp admin@dc-lab:/path/to/ca-cert.pem /tmp/ad-ca.pem

cp /tmp/ad-ca.pem /usr/local/share/ca-certificates/ad-ca.crt
update-ca-certificates

# Or disable verification (NOT recommended for production)
wabadmin ldap modify "LAB.LOCAL" --tls-verify false
```

### "Groups not mapped"

**Causes:**
- Group DN mismatch
- Case sensitivity
- Nested groups not enabled

**Diagnosis:**
```bash
# Get exact group DN from AD
ldapsearch -x -H ldaps://dc-lab.company.com:636 \
    -D "CN=wallix-svc,OU=Service Accounts,OU=WALLIX Bastion,DC=company,DC=com" \
    -W \
    -b "DC=company,DC=com" \
    "(sAMAccountName=WALLIX Bastion-Admins)" dn

# Verify mapping in WALLIX Bastion uses exact DN
wabadmin ldap groups "LAB.LOCAL"
```

---

## Step 7: Recovery Procedures

### LDAP Sync Failure Recovery

```bash
# Check sync status
wabadmin ldap sync-status "LAB.LOCAL"

# Force full resync
wabadmin ldap sync "LAB.LOCAL" --full

# If sync keeps failing, check:
# 1. Service account password hasn't changed
# 2. Network connectivity
# 3. AD DC is healthy

# View sync logs
tail -f /var/log/wabengine/ldap-sync.log
```

### Service Account Password Rotation

```bash
# When service account password changes in AD:

# 1. Update in WALLIX Bastion
wabadmin ldap modify "LAB.LOCAL" \
    --bind-password "NewPassword123!"

# 2. Test connection
wabadmin ldap test "LAB.LOCAL"

# 3. Force sync
wabadmin ldap sync "LAB.LOCAL"
```

### Emergency: All LDAP Users Locked Out

```bash
# Use local admin account to access WALLIX Bastion
# Login with: admin / [local password]

# Temporarily allow local auth fallback
wabadmin auth local enable

# Fix LDAP configuration
wabadmin ldap test "LAB.LOCAL"
wabadmin ldap modify "LAB.LOCAL" --[fix options]

# Once fixed, disable local fallback
wabadmin auth local disable
```

---

## Appendix: Useful LDAP Commands

### Search Examples

```bash
# Find all users in OU
ldapsearch -x -H ldaps://dc-lab.company.com:636 \
    -D "CN=wallix-svc,OU=Service Accounts,OU=WALLIX Bastion,DC=company,DC=com" \
    -W \
    -b "OU=Users,OU=WALLIX Bastion,DC=company,DC=com" \
    "(objectClass=user)" sAMAccountName

# Find all groups
ldapsearch -x -H ldaps://dc-lab.company.com:636 \
    -D "CN=wallix-svc,OU=Service Accounts,OU=WALLIX Bastion,DC=company,DC=com" \
    -W \
    -b "OU=Groups,OU=WALLIX Bastion,DC=company,DC=com" \
    "(objectClass=group)" sAMAccountName

# Find users in specific group
ldapsearch -x -H ldaps://dc-lab.company.com:636 \
    -D "CN=wallix-svc,OU=Service Accounts,OU=WALLIX Bastion,DC=company,DC=com" \
    -W \
    -b "DC=company,DC=com" \
    "(&(objectClass=user)(memberOf=CN=WALLIX Bastion-Admins,OU=Groups,OU=WALLIX Bastion,DC=company,DC=com))" \
    sAMAccountName
```

### WALLIX Bastion Commands

```bash
# List LDAP domains
wabadmin ldap list

# Show domain config
wabadmin ldap show "LAB.LOCAL"

# Test connection
wabadmin ldap test "LAB.LOCAL"

# Search user
wabadmin ldap search "LAB.LOCAL" "jadmin"

# Force sync
wabadmin ldap sync "LAB.LOCAL" --full

# View sync status
wabadmin ldap sync-status "LAB.LOCAL"

# List group mappings
wabadmin ldap groups "LAB.LOCAL"
```

---

<p align="center">
  <a href="./README.md">← Back to Troubleshooting</a>
</p>
