# Kerberos Configuration Guide

## Configuring Kerberos Authentication for PAM4OT

This guide covers integrating PAM4OT with Active Directory using Kerberos for seamless single sign-on.

---

## Kerberos Authentication Flow

```
+===============================================================================+
|                      KERBEROS AUTHENTICATION FLOW                             |
+===============================================================================+

  User Workstation            PAM4OT                     AD Domain Controller
  ================            ======                     ====================

       1. User opens browser
          │
          ▼
       2. Request https://pam4ot.company.com/
          │
          ├──────────────────────────────────────────────────────────────────>
          │                    3. 401 Negotiate                               │
          │<──────────────────────────────────────────────────────────────────┤
          │
          │                    4. TGT Request (AS-REQ)
          ├───────────────────────────────────────────────────────────────────>
          │                                                      KDC (port 88)
          │                    5. TGT (AS-REP)
          │<───────────────────────────────────────────────────────────────────
          │
          │                    6. Service Ticket Request (TGS-REQ)
          │                       for HTTP/pam4ot.company.com
          ├───────────────────────────────────────────────────────────────────>
          │
          │                    7. Service Ticket (TGS-REP)
          │<───────────────────────────────────────────────────────────────────
          │
          │     8. Request with Service Ticket (Authorization: Negotiate)
          ├──────────────────────────────────────────────────────────────────>
          │                                           PAM4OT validates ticket
          │                    9. Access granted
          │<──────────────────────────────────────────────────────────────────

+===============================================================================+
```

---

## Prerequisites

### Network Requirements

| Source | Destination | Port | Protocol | Purpose |
|--------|-------------|------|----------|---------|
| PAM4OT | AD DC | 88 | TCP/UDP | Kerberos KDC |
| PAM4OT | AD DC | 464 | TCP/UDP | Kerberos password change |
| PAM4OT | AD DC | 389 | TCP | LDAP |
| PAM4OT | AD DC | 636 | TCP | LDAPS |
| Clients | PAM4OT | 443 | TCP | HTTPS |

### DNS Requirements

```bash
# Forward lookup - PAM4OT hostname must resolve
nslookup pam4ot.company.com
# Must return: 10.10.1.100 (VIP)

# Reverse lookup - recommended
nslookup 10.10.1.100
# Should return: pam4ot.company.com

# SRV records for Kerberos
nslookup -type=SRV _kerberos._tcp.company.com
nslookup -type=SRV _ldap._tcp.company.com
```

### Time Synchronization

```bash
# Kerberos requires time sync within 5 minutes

# Check NTP status
timedatectl status

# Configure NTP to AD DC (recommended)
cat > /etc/systemd/timesyncd.conf << EOF
[Time]
NTP=dc-lab.company.com
FallbackNTP=pool.ntp.org
EOF

systemctl restart systemd-timesyncd
timedatectl set-ntp true

# Verify time sync
timedatectl timesync-status
```

---

## Section 1: Active Directory Configuration

### Create Service Account

```powershell
# PowerShell on Domain Controller

# Create service account
New-ADUser -Name "svc-pam4ot" `
    -SamAccountName "svc-pam4ot" `
    -UserPrincipalName "svc-pam4ot@COMPANY.COM" `
    -Description "PAM4OT Service Account" `
    -PasswordNeverExpires $true `
    -CannotChangePassword $true `
    -Enabled $true `
    -AccountPassword (ConvertTo-SecureString "SecurePassword123!" -AsPlainText -Force)

# Set account options
Set-ADUser "svc-pam4ot" -KerberosEncryptionType AES128,AES256
```

### Create SPN (Service Principal Name)

```powershell
# Register SPNs for PAM4OT
# Format: HTTP/hostname@REALM

setspn -S HTTP/pam4ot.company.com svc-pam4ot
setspn -S HTTP/pam4ot svc-pam4ot

# If using VIP with different name:
setspn -S HTTP/pam4ot-node1.company.com svc-pam4ot
setspn -S HTTP/pam4ot-node2.company.com svc-pam4ot

# Verify SPNs
setspn -L svc-pam4ot
```

### Generate Keytab

```powershell
# Generate keytab file on DC
ktpass -princ HTTP/pam4ot.company.com@COMPANY.COM `
    -mapuser COMPANY\svc-pam4ot `
    -pass "SecurePassword123!" `
    -crypto AES256-SHA1 `
    -ptype KRB5_NT_PRINCIPAL `
    -out C:\keytabs\pam4ot.keytab

# Copy keytab to PAM4OT server securely
# (Use SCP or secure file transfer)
```

---

## Section 2: PAM4OT Configuration

### Install Kerberos Packages

```bash
apt update
apt install krb5-user libpam-krb5 libsasl2-modules-gssapi-mit
```

### Configure Kerberos Client

```bash
# /etc/krb5.conf
cat > /etc/krb5.conf << 'EOF'
[libdefaults]
    default_realm = COMPANY.COM
    dns_lookup_realm = false
    dns_lookup_kdc = true
    ticket_lifetime = 24h
    renew_lifetime = 7d
    forwardable = true
    rdns = false
    default_ccache_name = FILE:/tmp/krb5cc_%{uid}
    default_tgs_enctypes = aes256-cts-hmac-sha1-96 aes128-cts-hmac-sha1-96
    default_tkt_enctypes = aes256-cts-hmac-sha1-96 aes128-cts-hmac-sha1-96
    permitted_enctypes = aes256-cts-hmac-sha1-96 aes128-cts-hmac-sha1-96

[realms]
    COMPANY.COM = {
        kdc = dc-lab.company.com
        admin_server = dc-lab.company.com
        default_domain = company.com
    }

[domain_realm]
    .company.com = COMPANY.COM
    company.com = COMPANY.COM
EOF
```

### Install Keytab

```bash
# Copy keytab to PAM4OT
scp user@dc-lab:/path/to/pam4ot.keytab /etc/wab/krb5.keytab

# Set permissions
chmod 600 /etc/wab/krb5.keytab
chown wabuser:wabgroup /etc/wab/krb5.keytab

# Verify keytab
klist -kt /etc/wab/krb5.keytab

# Test authentication with keytab
kinit -kt /etc/wab/krb5.keytab HTTP/pam4ot.company.com@COMPANY.COM
klist
```

### Configure PAM4OT for Kerberos

```bash
# Enable Kerberos SSO in PAM4OT
wabadmin config set auth.kerberos.enabled true
wabadmin config set auth.kerberos.realm "COMPANY.COM"
wabadmin config set auth.kerberos.keytab "/etc/wab/krb5.keytab"
wabadmin config set auth.kerberos.service_principal "HTTP/pam4ot.company.com@COMPANY.COM"

# Configure LDAP for group mapping
wabadmin config set auth.ldap.enabled true
wabadmin config set auth.ldap.server "ldaps://dc-lab.company.com:636"
wabadmin config set auth.ldap.base_dn "DC=company,DC=com"
wabadmin config set auth.ldap.bind_dn "CN=svc-pam4ot,OU=Service Accounts,DC=company,DC=com"
wabadmin config set auth.ldap.bind_password "[password]"

# Restart PAM4OT
systemctl restart wallix-bastion
```

---

## Section 3: Web Browser Configuration

### Internet Explorer / Edge

```
Group Policy settings for Kerberos SSO:

1. Computer Configuration > Administrative Templates > Windows Components
   > Internet Explorer > Internet Control Panel > Security Page

2. Site to Zone Assignment List:
   - https://pam4ot.company.com = 1 (Intranet)

3. User Configuration > Administrative Templates > Windows Components
   > Internet Explorer > Internet Control Panel > Security Page
   > Intranet Zone

4. Enable: "Automatic logon only in Intranet zone"
```

### Chrome

```bash
# Windows Registry for Chrome
reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v AuthServerWhitelist /t REG_SZ /d "*.company.com"
reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v AuthNegotiateDelegateWhitelist /t REG_SZ /d "*.company.com"

# Linux Chrome
cat > /etc/opt/chrome/policies/managed/kerberos.json << 'EOF'
{
  "AuthServerWhitelist": "*.company.com",
  "AuthNegotiateDelegateWhitelist": "*.company.com"
}
EOF
```

### Firefox

```bash
# Firefox about:config settings

# network.negotiate-auth.trusted-uris
# Value: https://pam4ot.company.com

# network.negotiate-auth.delegation-uris
# Value: https://pam4ot.company.com

# Or via enterprise policy:
cat > /usr/lib/firefox/distribution/policies.json << 'EOF'
{
  "policies": {
    "Authentication": {
      "SPNEGO": ["https://pam4ot.company.com"],
      "Delegated": ["https://pam4ot.company.com"]
    }
  }
}
EOF
```

---

## Section 4: Testing Kerberos

### Server-Side Tests

```bash
# Test 1: Verify keytab
klist -kt /etc/wab/krb5.keytab

# Expected output:
# Keytab name: FILE:/etc/wab/krb5.keytab
# KVNO Timestamp           Principal
# ---- ------------------- ----------------------------------------------
#    2 01/28/25 10:00:00   HTTP/pam4ot.company.com@COMPANY.COM

# Test 2: Authenticate with keytab
kinit -kt /etc/wab/krb5.keytab HTTP/pam4ot.company.com@COMPANY.COM
klist

# Test 3: Verify Kerberos connectivity to DC
kinit testuser@COMPANY.COM
# Enter password when prompted

# Test 4: Check PAM4OT Kerberos status
wabadmin auth kerberos status
```

### Client-Side Tests

```bash
# On Windows workstation

# Test 1: Verify TGT
klist

# Test 2: Request service ticket manually
klist get HTTP/pam4ot.company.com

# Test 3: Test with curl (from Linux with Kerberos)
kinit username@COMPANY.COM
curl -v --negotiate -u : https://pam4ot.company.com/

# Expected: 200 OK with user authenticated
```

### Packet Capture Analysis

```bash
# Capture Kerberos traffic
tcpdump -i any port 88 -w /tmp/kerberos.pcap

# Analyze with Wireshark
# Filter: kerberos
# Look for:
# - AS-REQ/AS-REP (initial TGT)
# - TGS-REQ/TGS-REP (service ticket)
# - AP-REQ/AP-REP (authentication)
```

---

## Section 5: Troubleshooting

### Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `KRB5KDC_ERR_S_PRINCIPAL_UNKNOWN` | SPN not registered | Register SPN with setspn |
| `KRB5KDC_ERR_PREAUTH_FAILED` | Wrong password | Verify keytab password |
| `KRB5_KT_NOTFOUND` | Keytab missing | Check keytab path/permissions |
| `Clock skew too great` | Time sync issue | Sync NTP with DC |
| `Server not found in Kerberos database` | DNS issue | Verify DNS resolution |
| `No credentials cache found` | No TGT | Run kinit |

### Debug Kerberos

```bash
# Enable Kerberos debugging
export KRB5_TRACE=/tmp/krb5_trace.log

# Run test
kinit -kt /etc/wab/krb5.keytab HTTP/pam4ot.company.com@COMPANY.COM

# Review trace
cat /tmp/krb5_trace.log

# Check system logs
journalctl -u wallix-bastion | grep -i kerb
```

### Verify SPN Configuration

```bash
# On DC, check for duplicate SPNs
setspn -X

# Check SPN is associated with correct account
setspn -Q HTTP/pam4ot.company.com

# If SPN on wrong account, remove and re-add
setspn -D HTTP/pam4ot.company.com wrong-account
setspn -S HTTP/pam4ot.company.com svc-pam4ot
```

### Keytab Issues

```bash
# Regenerate keytab if corrupted
# On DC:
ktpass -princ HTTP/pam4ot.company.com@COMPANY.COM `
    -mapuser COMPANY\svc-pam4ot `
    -pass "NewPassword!" `
    -crypto AES256-SHA1 `
    -ptype KRB5_NT_PRINCIPAL `
    -out pam4ot-new.keytab

# On PAM4OT:
# Update password for service account first, then:
cp pam4ot-new.keytab /etc/wab/krb5.keytab
chmod 600 /etc/wab/krb5.keytab
chown wabuser:wabgroup /etc/wab/krb5.keytab
systemctl restart wallix-bastion
```

---

## Section 6: High Availability Considerations

### Keytab Synchronization

```bash
# Both HA nodes must have identical keytab

# On primary node:
scp /etc/wab/krb5.keytab root@pam4ot-node2:/etc/wab/krb5.keytab

# On secondary node:
chmod 600 /etc/wab/krb5.keytab
chown wabuser:wabgroup /etc/wab/krb5.keytab
```

### SPN for VIP

```powershell
# Register SPN for VIP hostname
setspn -S HTTP/pam4ot.company.com svc-pam4ot

# Also register for individual nodes if needed
setspn -S HTTP/pam4ot-node1.company.com svc-pam4ot
setspn -S HTTP/pam4ot-node2.company.com svc-pam4ot
```

### DNS Round-Robin Considerations

```bash
# If using DNS round-robin:
# - Register SPN for the common DNS name
# - Ensure keytab works for all node names
# - Test failover scenarios
```

---

## Section 7: Security Hardening

### Encryption Types

```bash
# Use strong encryption only
# In krb5.conf:
default_tgs_enctypes = aes256-cts-hmac-sha1-96
default_tkt_enctypes = aes256-cts-hmac-sha1-96
permitted_enctypes = aes256-cts-hmac-sha1-96

# Disable weak encryption on DC (Group Policy):
# Computer Configuration > Policies > Windows Settings > Security Settings
# > Local Policies > Security Options
# > "Network security: Configure encryption types allowed for Kerberos"
# Enable: AES256_HMAC_SHA1
# Disable: DES_*, RC4_*
```

### Keytab Protection

```bash
# Restrict keytab permissions
chmod 600 /etc/wab/krb5.keytab
chown wabuser:wabgroup /etc/wab/krb5.keytab

# Monitor keytab access
auditctl -w /etc/wab/krb5.keytab -p rwa -k keytab_access
```

### Service Account Security

```powershell
# Protect service account
Set-ADUser svc-pam4ot -AccountNotDelegated $true
Add-ADGroupMember "Protected Users" svc-pam4ot
```

---

## Appendix: Quick Reference

### Essential Commands

```bash
# Kerberos ticket operations
kinit username@COMPANY.COM      # Get TGT
klist                           # List tickets
kdestroy                        # Destroy tickets

# Keytab operations
klist -kt /path/to/keytab       # List keytab entries
kinit -kt /path/to/keytab SPN   # Auth with keytab

# PAM4OT Kerberos
wabadmin auth kerberos status   # Check Kerberos status
wabadmin auth kerberos test     # Test Kerberos auth

# Debug
export KRB5_TRACE=/tmp/trace.log
```

### Checklist

```
KERBEROS CONFIGURATION CHECKLIST
================================

Active Directory:
[ ] Service account created
[ ] SPN registered
[ ] Keytab generated
[ ] Strong encryption enabled

PAM4OT:
[ ] Kerberos packages installed
[ ] /etc/krb5.conf configured
[ ] Keytab installed (600 permissions)
[ ] Time synchronized with DC
[ ] PAM4OT Kerberos enabled

Client:
[ ] Browser configured for SSO
[ ] Intranet zone configured
[ ] Delegation allowed

Testing:
[ ] klist shows valid TGT
[ ] Service ticket obtained
[ ] SSO login works
[ ] Failover tested (HA)
```

---

<p align="center">
  <a href="./README.md">← Back to Authentication</a>
</p>
