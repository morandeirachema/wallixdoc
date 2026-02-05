# 46 - Kerberos and SPNEGO Authentication

## Table of Contents

1. [Kerberos Overview](#kerberos-overview)
2. [Authentication Flow](#authentication-flow)
3. [Prerequisites](#prerequisites)
4. [Active Directory Integration](#active-directory-integration)
5. [MIT Kerberos Integration](#mit-kerberos-integration)
6. [WALLIX Kerberos Configuration](#wallix-kerberos-configuration)
7. [SPNEGO/Negotiate Setup](#spnegonegotiate-setup)
8. [Cross-Realm Trust](#cross-realm-trust)
9. [Constrained Delegation](#constrained-delegation)
10. [Troubleshooting](#troubleshooting)
11. [Diagnostic Commands](#diagnostic-commands)

---

## Kerberos Overview

### What is Kerberos?

Kerberos is a network authentication protocol that uses secret-key cryptography to provide strong authentication for client-server applications. Named after the three-headed guard dog of Hades in Greek mythology, Kerberos involves three parties: the client, the server, and a trusted Key Distribution Center (KDC).

### Key Concepts

| Concept | Description |
|---------|-------------|
| **Principal** | A unique identity (user, service, or host) in the Kerberos realm |
| **Realm** | A Kerberos administrative domain (e.g., `CORP.COMPANY.COM`) |
| **KDC** | Key Distribution Center - the trusted authority that issues tickets |
| **TGT** | Ticket Granting Ticket - initial ticket obtained after authentication |
| **Service Ticket** | Ticket used to access a specific service |
| **Keytab** | File containing encrypted keys for service principals |
| **SPN** | Service Principal Name - unique identifier for a service instance |

### Kerberos Components

```
+-----------------------------------------------------------------------------+
|                         KERBEROS ARCHITECTURE                                |
+-----------------------------------------------------------------------------+
|                                                                              |
|                     +------------------------------------------+             |
|                     |       KEY DISTRIBUTION CENTER (KDC)      |             |
|                     |                                          |             |
|                     |  +----------------+  +----------------+  |             |
|                     |  | Authentication |  |  Ticket        |  |             |
|                     |  |   Service (AS) |  |  Granting      |  |             |
|                     |  |                |  |  Service (TGS) |  |             |
|                     |  | Issues TGT     |  |  Issues        |  |             |
|                     |  | after password |  |  service       |  |             |
|                     |  | verification   |  |  tickets       |  |             |
|                     |  +----------------+  +----------------+  |             |
|                     |                                          |             |
|                     |  +------------------------------------+  |             |
|                     |  |        KERBEROS DATABASE           |  |             |
|                     |  |  (Principals, Keys, Policies)      |  |             |
|                     |  +------------------------------------+  |             |
|                     +------------------------------------------+             |
|                                      |                                       |
|          +---------------------------+---------------------------+           |
|          |                           |                           |           |
|          v                           v                           v           |
|   +-------------+            +-------------+            +-------------+      |
|   |   CLIENT    |            |   WALLIX    |            |   TARGET    |      |
|   |  Workstation|            |   Bastion   |            |   Server    |      |
|   |             |            |             |            |             |      |
|   | User: jsmith|            | Service:    |            | Service:    |      |
|   | @CORP.COM   |            | HTTP/       |            | HOST/       |      |
|   |             |            | bastion     |            | server01    |      |
|   +-------------+            +-------------+            +-------------+      |
|                                                                              |
+-----------------------------------------------------------------------------+
```

### Ticket Types

| Ticket Type | Purpose | Lifetime | Storage |
|-------------|---------|----------|---------|
| **TGT** | Authenticate to TGS for service tickets | 8-10 hours (default) | Credential cache |
| **Service Ticket** | Access specific service | 8-10 hours (default) | Credential cache |
| **Renewable Ticket** | Extended session without re-auth | Up to 7 days | Credential cache |

### Security Benefits

- **No Password Transmission**: Passwords never sent over the network after initial auth
- **Mutual Authentication**: Both client and server verify each other's identity
- **Single Sign-On**: One authentication grants access to multiple services
- **Ticket Expiration**: Time-limited access reduces exposure window
- **Replay Protection**: Authenticators prevent ticket reuse

---

## Authentication Flow

### Complete Kerberos Authentication Sequence

```
+-----------------------------------------------------------------------------+
|                    KERBEROS AUTHENTICATION FLOW                              |
+-----------------------------------------------------------------------------+
|                                                                              |
|   CLIENT                  KDC                    WALLIX                      |
|   WORKSTATION          (AD Domain               BASTION                      |
|                        Controller)                                           |
|      |                     |                       |                         |
|      |  1. AS-REQ          |                       |                         |
|      |  (username, realm)  |                       |                         |
|      |-------------------->|                       |                         |
|      |                     |                       |                         |
|      |  2. AS-REP          |                       |                         |
|      |  (TGT encrypted     |                       |                         |
|      |   with user key)    |                       |                         |
|      |<--------------------|                       |                         |
|      |                     |                       |                         |
|      |     [User decrypts TGT with password]       |                         |
|      |                     |                       |                         |
|      |  3. TGS-REQ         |                       |                         |
|      |  (TGT + request for |                       |                         |
|      |   HTTP/bastion.     |                       |                         |
|      |   corp.company.com) |                       |                         |
|      |-------------------->|                       |                         |
|      |                     |                       |                         |
|      |  4. TGS-REP         |                       |                         |
|      |  (Service ticket    |                       |                         |
|      |   for WALLIX)       |                       |                         |
|      |<--------------------|                       |                         |
|      |                     |                       |                         |
|      |  5. AP-REQ (SPNEGO)                         |                         |
|      |  (Service ticket + authenticator)           |                         |
|      |-------------------------------------------->|                         |
|      |                     |                       |                         |
|      |                     |  6. Ticket validation |                         |
|      |                     |  (Decrypt with keytab)|                         |
|      |                     |                       |                         |
|      |  7. AP-REP (optional)                       |                         |
|      |  (Mutual authentication confirmation)       |                         |
|      |<--------------------------------------------|                         |
|      |                     |                       |                         |
|      |  8. Session established (SSO complete)      |                         |
|      |<--------------------------------------------|                         |
|      |                     |                       |                         |
+-----------------------------------------------------------------------------+
```

### Message Types Explained

| Message | Direction | Content | Purpose |
|---------|-----------|---------|---------|
| **AS-REQ** | Client -> KDC | Username, realm, timestamp | Request TGT |
| **AS-REP** | KDC -> Client | TGT (encrypted), session key | Provide TGT |
| **TGS-REQ** | Client -> KDC | TGT, target service SPN | Request service ticket |
| **TGS-REP** | KDC -> Client | Service ticket, session key | Provide service ticket |
| **AP-REQ** | Client -> Service | Service ticket, authenticator | Access service |
| **AP-REP** | Service -> Client | Encrypted timestamp | Mutual authentication |

### SPNEGO Negotiation Flow

```
+-----------------------------------------------------------------------------+
|                      SPNEGO/HTTP NEGOTIATE FLOW                              |
+-----------------------------------------------------------------------------+
|                                                                              |
|   BROWSER                                      WALLIX BASTION                |
|      |                                              |                        |
|      |  1. GET /login                               |                        |
|      |--------------------------------------------->|                        |
|      |                                              |                        |
|      |  2. HTTP 401 Unauthorized                    |                        |
|      |     WWW-Authenticate: Negotiate              |                        |
|      |<---------------------------------------------|                        |
|      |                                              |                        |
|      |  [Browser obtains Kerberos service ticket]   |                        |
|      |                                              |                        |
|      |  3. GET /login                               |                        |
|      |     Authorization: Negotiate <SPNEGO token>  |                        |
|      |--------------------------------------------->|                        |
|      |                                              |                        |
|      |  [WALLIX validates ticket using keytab]      |                        |
|      |                                              |                        |
|      |  4. HTTP 200 OK                              |                        |
|      |     WWW-Authenticate: Negotiate <response>   |                        |
|      |     Set-Cookie: session=...                  |                        |
|      |<---------------------------------------------|                        |
|      |                                              |                        |
|      |  5. User logged in via SSO                   |                        |
|      |                                              |                        |
+-----------------------------------------------------------------------------+
```

---

## Prerequisites

### Time Synchronization (Critical)

Kerberos authentication is extremely sensitive to time differences. The default maximum clock skew is 5 minutes.

#### NTP Configuration on WALLIX Bastion

```bash
# Install chrony (preferred) or ntpd
apt-get install chrony

# Configure /etc/chrony/chrony.conf
server dc01.corp.company.com iburst prefer
server dc02.corp.company.com iburst
server time.windows.com iburst

# Time synchronization settings
makestep 1.0 3
rtcsync
driftfile /var/lib/chrony/drift

# Start and enable chrony
systemctl enable chrony
systemctl start chrony

# Verify synchronization
chronyc sources -v
```

**Expected Output:**
```
  .-- Source mode  '^' = server, '=' = peer, '#' = local clock.
 / .- Source state '*' = current best, '+' = combined, '-' = not combined,
| /             'x' = may be in error, '~' = too variable, '?' = unusable.
||                                                 .- xxxx [ yyyy ] +/- zzzz
||      Reachability register (octal) -.           |  xxxx = adjusted offset,
||      Log2(Polling interval) --.      |          |  yyyy = measured offset,
||                                \     |          |  zzzz = estimated error.
||                                 |    |           \
MS Name/IP address         Stratum Poll Reach LastRx Last sample
===============================================================================
^* dc01.corp.company.com         2   6   377    34   +125us[ +187us] +/-  12ms
^+ dc02.corp.company.com         2   6   377    35   +892us[ +954us] +/-  15ms
^- time.windows.com              2   8   377   201   -2.5ms[-2.4ms] +/-  45ms
```

#### Verify Time Synchronization

```bash
# Check time offset
chronyc tracking

# Output showing offset
Reference ID    : C0A80101 (dc01.corp.company.com)
Stratum         : 3
Ref time (UTC)  : Fri Jan 31 10:23:45 2026
System time     : 0.000125342 seconds fast of NTP time
Last offset     : +0.000187234 seconds
RMS offset      : 0.000234567 seconds
Frequency       : 12.345 ppm slow
Residual freq   : +0.001 ppm
Skew            : 0.234 ppm
Root delay      : 0.002345678 seconds
Root dispersion : 0.001234567 seconds
Update interval : 64.2 seconds
Leap status     : Normal

# Compare with domain controller
date && ssh dc01.corp.company.com date
```

### DNS Configuration Requirements

Proper DNS resolution is essential for Kerberos to function correctly.

#### Required DNS Records

| Record Type | Name | Value | Purpose |
|-------------|------|-------|---------|
| **A** | bastion.corp.company.com | 192.168.1.50 | WALLIX Bastion IP |
| **PTR** | 50.1.168.192.in-addr.arpa | bastion.corp.company.com | Reverse lookup |
| **A** | dc01.corp.company.com | 192.168.1.10 | Domain Controller |
| **SRV** | _kerberos._tcp.corp.company.com | dc01.corp.company.com | KDC location |
| **SRV** | _kerberos._udp.corp.company.com | dc01.corp.company.com | KDC location |

#### Configure DNS Resolution

```bash
# /etc/resolv.conf
search corp.company.com company.com
nameserver 192.168.1.10  # Primary DC
nameserver 192.168.1.11  # Secondary DC
options timeout:2 attempts:3

# Verify forward and reverse DNS
nslookup bastion.corp.company.com
nslookup 192.168.1.50

# Expected output for forward lookup
Server:         192.168.1.10
Address:        192.168.1.10#53

Name:   bastion.corp.company.com
Address: 192.168.1.50

# Expected output for reverse lookup
Server:         192.168.1.10
Address:        192.168.1.10#53

50.1.168.192.in-addr.arpa       name = bastion.corp.company.com
```

#### Verify SRV Records

```bash
# Query Kerberos SRV records
nslookup -type=SRV _kerberos._tcp.corp.company.com

# Expected output
_kerberos._tcp.corp.company.com   SRV record:
        Priority = 0
        Weight = 100
        Port = 88
        Target = dc01.corp.company.com
_kerberos._tcp.corp.company.com   SRV record:
        Priority = 10
        Weight = 100
        Port = 88
        Target = dc02.corp.company.com
```

### Network Requirements

| Port | Protocol | Direction | Purpose |
|------|----------|-----------|---------|
| **88** | TCP/UDP | WALLIX -> KDC | Kerberos authentication |
| **464** | TCP/UDP | WALLIX -> KDC | Kerberos password change |
| **389** | TCP | WALLIX -> DC | LDAP (for user info) |
| **636** | TCP | WALLIX -> DC | LDAPS (secure LDAP) |
| **53** | TCP/UDP | WALLIX -> DNS | DNS resolution |
| **123** | UDP | WALLIX -> NTP | Time synchronization |

#### Firewall Verification

```bash
# Test Kerberos port connectivity
nc -zv dc01.corp.company.com 88
nc -zv dc01.corp.company.com 464
nc -zv dc01.corp.company.com 636

# Expected output
Connection to dc01.corp.company.com 88 port [tcp/kerberos] succeeded!
Connection to dc01.corp.company.com 464 port [tcp/kpasswd] succeeded!
Connection to dc01.corp.company.com 636 port [tcp/ldaps] succeeded!
```

---

## Active Directory Integration

### Service Account Creation

Create a dedicated service account in Active Directory for WALLIX Bastion Kerberos authentication.

#### PowerShell Commands (Run on Domain Controller)

```powershell
# Create service account
New-ADUser -Name "svc_wallix_krb" `
    -SamAccountName "svc_wallix_krb" `
    -UserPrincipalName "svc_wallix_krb@corp.company.com" `
    -Path "OU=Service Accounts,OU=IT,DC=corp,DC=company,DC=com" `
    -AccountPassword (ConvertTo-SecureString "P@ssw0rd!Complex123" -AsPlainText -Force) `
    -PasswordNeverExpires $true `
    -CannotChangePassword $true `
    -Enabled $true `
    -Description "WALLIX Bastion Kerberos Service Account"

# Verify account creation
Get-ADUser svc_wallix_krb -Properties *

# Set account options for Kerberos
Set-ADUser svc_wallix_krb -KerberosEncryptionType AES128,AES256
```

### SPN (Service Principal Name) Registration

The SPN uniquely identifies the WALLIX Bastion service in Active Directory.

#### Register SPNs

```powershell
# Register HTTP SPN for web interface
setspn -S HTTP/bastion.corp.company.com svc_wallix_krb

# Register HTTPS SPN (alias)
setspn -S HTTP/bastion svc_wallix_krb

# Verify SPN registration
setspn -L svc_wallix_krb
```

**Expected Output:**
```
Registered ServicePrincipalNames for CN=svc_wallix_krb,OU=Service Accounts,OU=IT,DC=corp,DC=company,DC=com:
        HTTP/bastion.corp.company.com
        HTTP/bastion
```

#### Check for Duplicate SPNs

```powershell
# Search for duplicate SPNs (critical check)
setspn -Q HTTP/bastion.corp.company.com

# If no duplicates, output should be:
Checking domain DC=corp,DC=company,DC=com
HTTP/bastion.corp.company.com
        svc_wallix_krb

Existing SPN found!
```

> **Warning**: Duplicate SPNs will cause Kerberos authentication failures. If duplicates exist, remove them before proceeding.

### Keytab Generation on Windows

The keytab file contains the service account's encrypted credentials for ticket validation.

#### Generate Keytab Using ktpass

```cmd
REM Run on Domain Controller as Administrator
ktpass -out C:\Temp\wallix.keytab ^
       -princ HTTP/bastion.corp.company.com@CORP.COMPANY.COM ^
       -mapuser CORP\svc_wallix_krb ^
       -pass "P@ssw0rd!Complex123" ^
       -ptype KRB5_NT_PRINCIPAL ^
       -crypto AES256-SHA1 ^
       +DumpSalt
```

**Expected Output:**
```
Targeting domain controller: dc01.corp.company.com
Using legacy password setting method
Successfully mapped HTTP/bastion.corp.company.com to svc_wallix_krb.
Building salt with principalname HTTP/bastion.corp.company.com...
Hashing password with salt "CORP.COMPANY.COMHTTPbastion.corp.company.com".
Key created.
Output keytab to C:\Temp\wallix.keytab:
Keytab version: 0x502
keysize 91 HTTP/bastion.corp.company.com@CORP.COMPANY.COM ptype 1 (KRB5_NT_PRINCIPAL)
vno 3 etype 0x12 (AES256-CTS-HMAC-SHA1-96) keylength 32 (0x...)
Account svc_wallix_krb has been set for AES-256-CTS-HMAC-SHA1-96 encryption.
```

#### Generate Keytab with Multiple Encryption Types

For broader compatibility, include multiple encryption types:

```cmd
REM Generate keytab with AES256 (recommended)
ktpass -out C:\Temp\wallix_aes256.keytab ^
       -princ HTTP/bastion.corp.company.com@CORP.COMPANY.COM ^
       -mapuser CORP\svc_wallix_krb ^
       -pass "P@ssw0rd!Complex123" ^
       -ptype KRB5_NT_PRINCIPAL ^
       -crypto AES256-SHA1

REM Merge with AES128 for compatibility
ktpass -out C:\Temp\wallix_aes128.keytab ^
       -princ HTTP/bastion.corp.company.com@CORP.COMPANY.COM ^
       -mapuser CORP\svc_wallix_krb ^
       -pass "P@ssw0rd!Complex123" ^
       -ptype KRB5_NT_PRINCIPAL ^
       -crypto AES128-SHA1 ^
       -in C:\Temp\wallix_aes256.keytab
```

#### Transfer Keytab Securely

```bash
# On WALLIX Bastion, retrieve keytab securely
scp administrator@dc01.corp.company.com:C:/Temp/wallix.keytab /tmp/

# Verify keytab integrity
klist -kte /tmp/wallix.keytab

# Set proper permissions
sudo mv /tmp/wallix.keytab /etc/krb5.keytab
sudo chown root:root /etc/krb5.keytab
sudo chmod 600 /etc/krb5.keytab
```

---

## MIT Kerberos Integration

### krb5.conf Configuration

The `/etc/krb5.conf` file configures Kerberos client behavior on WALLIX Bastion.

#### Complete krb5.conf Example

```ini
# /etc/krb5.conf - Kerberos configuration for WALLIX Bastion

[libdefaults]
    # Default realm (must be UPPERCASE)
    default_realm = CORP.COMPANY.COM

    # DNS-based realm and KDC discovery
    dns_lookup_realm = true
    dns_lookup_kdc = true

    # Ticket lifetime settings
    ticket_lifetime = 10h
    renew_lifetime = 7d

    # Encryption types (strongest first)
    default_tgs_enctypes = aes256-cts-hmac-sha1-96 aes128-cts-hmac-sha1-96
    default_tkt_enctypes = aes256-cts-hmac-sha1-96 aes128-cts-hmac-sha1-96
    permitted_enctypes = aes256-cts-hmac-sha1-96 aes128-cts-hmac-sha1-96

    # Disable weak encryption (RC4, DES)
    allow_weak_crypto = false

    # Clock skew tolerance (default 300 seconds)
    clockskew = 300

    # Forward credentials for delegation
    forwardable = true
    proxiable = true

    # Credential cache location
    default_ccache_name = FILE:/tmp/krb5cc_%{uid}

[realms]
    CORP.COMPANY.COM = {
        # Primary and secondary KDCs
        kdc = dc01.corp.company.com:88
        kdc = dc02.corp.company.com:88

        # Admin server for password changes
        admin_server = dc01.corp.company.com:749

        # Password change server
        kpasswd_server = dc01.corp.company.com:464

        # Default domain for realm
        default_domain = corp.company.com
    }

    # Secondary realm (if applicable)
    DMZ.COMPANY.COM = {
        kdc = dmzdc01.dmz.company.com:88
        admin_server = dmzdc01.dmz.company.com:749
        default_domain = dmz.company.com
    }

[domain_realm]
    # Map DNS domains to Kerberos realms
    .corp.company.com = CORP.COMPANY.COM
    corp.company.com = CORP.COMPANY.COM
    .dmz.company.com = DMZ.COMPANY.COM
    dmz.company.com = DMZ.COMPANY.COM

    # Explicit host mappings (if needed)
    bastion.corp.company.com = CORP.COMPANY.COM

[appdefaults]
    # GSSAPI settings
    pam = {
        debug = false
        ticket_lifetime = 36000
        renew_lifetime = 36000
        forwardable = true
        krb4_convert = false
    }

[logging]
    # Log locations
    default = FILE:/var/log/krb5/krb5libs.log
    kdc = FILE:/var/log/krb5/krb5kdc.log
    admin_server = FILE:/var/log/krb5/kadmind.log
```

### Install Kerberos Packages

```bash
# Install MIT Kerberos client packages
apt-get update
apt-get install -y krb5-user krb5-config libpam-krb5 libkrb5-dev

# During installation, provide:
# - Default realm: CORP.COMPANY.COM
# - KDC: dc01.corp.company.com
# - Admin server: dc01.corp.company.com
```

### Keytab Generation (MIT Kerberos)

If generating a keytab on a Linux system with MIT Kerberos tools:

```bash
# Create keytab using ktutil
ktutil

# Inside ktutil interactive shell
ktutil: addent -password -p HTTP/bastion.corp.company.com@CORP.COMPANY.COM -k 1 -e aes256-cts-hmac-sha1-96
# Enter password when prompted

ktutil: addent -password -p HTTP/bastion.corp.company.com@CORP.COMPANY.COM -k 1 -e aes128-cts-hmac-sha1-96
# Enter password when prompted

ktutil: wkt /etc/krb5.keytab
ktutil: quit

# Verify keytab
klist -kte /etc/krb5.keytab
```

**Expected Output:**
```
Keytab name: FILE:/etc/krb5.keytab
KVNO Timestamp           Principal
---- ------------------- ------------------------------------------------------
   1 01/31/2026 10:30:00 HTTP/bastion.corp.company.com@CORP.COMPANY.COM (aes256-cts-hmac-sha1-96)
   1 01/31/2026 10:30:00 HTTP/bastion.corp.company.com@CORP.COMPANY.COM (aes128-cts-hmac-sha1-96)
```

### Test Kerberos Authentication

```bash
# Obtain TGT using kinit
kinit jsmith@CORP.COMPANY.COM

# Enter password when prompted
Password for jsmith@CORP.COMPANY.COM:

# Verify ticket
klist

# Expected output
Ticket cache: FILE:/tmp/krb5cc_1000
Default principal: jsmith@CORP.COMPANY.COM

Valid starting       Expires              Service principal
01/31/2026 10:35:00  01/31/2026 20:35:00  krbtgt/CORP.COMPANY.COM@CORP.COMPANY.COM
        renew until 02/07/2026 10:35:00

# Test keytab authentication
kinit -kt /etc/krb5.keytab HTTP/bastion.corp.company.com@CORP.COMPANY.COM
klist
```

---

## WALLIX Kerberos Configuration

### Enabling Kerberos Authentication

Configure Kerberos authentication in WALLIX Bastion through the web interface or API.

#### Web Interface Configuration

Navigate to: **Configuration** -> **Authentication** -> **Kerberos**

#### Configuration Parameters

```json
{
  "kerberos_configuration": {
    "enabled": true,
    "realm": "CORP.COMPANY.COM",
    "kdc_servers": [
      "dc01.corp.company.com",
      "dc02.corp.company.com"
    ],
    "service_principal": "HTTP/bastion.corp.company.com@CORP.COMPANY.COM",
    "keytab_file": "/etc/krb5.keytab",

    "authentication_settings": {
      "allow_negotiate": true,
      "require_mutual_auth": true,
      "allow_delegation": false
    },

    "user_mapping": {
      "strip_realm": true,
      "username_attribute": "sAMAccountName",
      "auto_create_users": false,
      "default_profile": "user",
      "default_groups": ["domain-users"]
    },

    "session_settings": {
      "ticket_lifetime_hours": 10,
      "session_timeout_minutes": 480
    }
  }
}
```

### Keytab Installation

```bash
# Copy keytab to WALLIX configuration directory
sudo cp /tmp/wallix.keytab /var/lib/wallix/bastion/etc/krb5.keytab

# Set ownership and permissions
sudo chown wabuser:wabgroup /var/lib/wallix/bastion/etc/krb5.keytab
sudo chmod 600 /var/lib/wallix/bastion/etc/krb5.keytab

# Create symbolic link if needed
sudo ln -sf /var/lib/wallix/bastion/etc/krb5.keytab /etc/krb5.keytab

# Verify WALLIX can read the keytab
sudo -u wabuser klist -kte /var/lib/wallix/bastion/etc/krb5.keytab
```

### Keytab Validation Script

```bash
#!/bin/bash
# /usr/local/bin/verify-keytab.sh

KEYTAB="/var/lib/wallix/bastion/etc/krb5.keytab"
PRINCIPAL="HTTP/bastion.corp.company.com@CORP.COMPANY.COM"

echo "=== Keytab Verification ==="

# Check file exists
if [[ ! -f "$KEYTAB" ]]; then
    echo "ERROR: Keytab file not found: $KEYTAB"
    exit 1
fi

# Check permissions
PERMS=$(stat -c %a "$KEYTAB")
if [[ "$PERMS" != "600" ]]; then
    echo "WARNING: Keytab permissions should be 600, currently: $PERMS"
fi

# List keytab entries
echo -e "\nKeytab entries:"
klist -kte "$KEYTAB"

# Test authentication
echo -e "\nTesting authentication with keytab..."
kdestroy -A 2>/dev/null
if kinit -kt "$KEYTAB" "$PRINCIPAL" 2>/dev/null; then
    echo "SUCCESS: Keytab authentication successful"
    klist
    kdestroy -A
else
    echo "ERROR: Keytab authentication failed"
    exit 1
fi

# Verify KVNO matches AD
echo -e "\nVerifying KVNO with KDC..."
kvno "$PRINCIPAL"

echo -e "\n=== Verification Complete ==="
```

### Configuration File Locations

| File | Location | Purpose |
|------|----------|---------|
| **krb5.conf** | `/etc/krb5.conf` | Kerberos client configuration |
| **keytab** | `/var/lib/wallix/bastion/etc/krb5.keytab` | Service credentials |
| **WALLIX config** | `/var/lib/wallix/bastion/etc/wabengine.conf` | Bastion engine config |
| **Apache config** | `/etc/apache2/sites-enabled/wallix.conf` | Web server SPNEGO |

### Apache mod_auth_gssapi Configuration

```apache
# /etc/apache2/sites-enabled/wallix-kerberos.conf

<Location "/api">
    AuthType GSSAPI
    AuthName "WALLIX Bastion Kerberos"

    # Keytab location
    GssapiCredStore keytab:/var/lib/wallix/bastion/etc/krb5.keytab

    # Enable SPNEGO/Negotiate
    GssapiAllowedMech krb5
    GssapiNegotiateOnce On

    # Session handling
    GssapiUseSessions On
    Session On
    SessionCookieName wallix_gssapi_session path=/;httponly;secure;

    # User mapping
    GssapiLocalName On
    GssapiConnectionBound Off

    # Delegation (optional)
    GssapiDelegCcacheDir /run/httpd/krbcache
    GssapiDelegCcacheUnique On

    # Require valid user
    Require valid-user
</Location>
```

---

## SPNEGO/Negotiate Setup

### Browser Configuration

#### Google Chrome

Chrome uses the system's Kerberos configuration. Additional settings can be configured via policies.

**Windows Group Policy:**

```
Computer Configuration -> Administrative Templates -> Google Chrome
-> Kerberos authentication settings

AuthServerAllowlist: *.corp.company.com, bastion.corp.company.com
AuthNegotiateDelegateAllowlist: bastion.corp.company.com
```

**Linux Chrome:**

```bash
# Create Chrome policy directory
sudo mkdir -p /etc/opt/chrome/policies/managed

# Create policy file
cat << 'EOF' | sudo tee /etc/opt/chrome/policies/managed/kerberos.json
{
  "AuthServerAllowlist": "*.corp.company.com,bastion.corp.company.com",
  "AuthNegotiateDelegateAllowlist": "bastion.corp.company.com",
  "DisableAuthNegotiateCnameLookup": false,
  "EnableAuthNegotiatePort": false
}
EOF
```

**macOS Chrome:**

```bash
# Configure via defaults command
defaults write com.google.Chrome AuthServerAllowlist "*.corp.company.com,bastion.corp.company.com"
defaults write com.google.Chrome AuthNegotiateDelegateAllowlist "bastion.corp.company.com"
```

#### Mozilla Firefox

**about:config Settings:**

| Setting | Value | Description |
|---------|-------|-------------|
| `network.negotiate-auth.trusted-uris` | `.corp.company.com,bastion.corp.company.com` | Allowed SSO domains |
| `network.negotiate-auth.delegation-uris` | `bastion.corp.company.com` | Delegation allowed |
| `network.negotiate-auth.allow-non-fqdn` | `false` | Require FQDN |
| `network.negotiate-auth.allow-proxies` | `true` | Allow through proxy |
| `network.negotiate-auth.gsslib` | (blank for system default) | GSSAPI library |

**Firefox Policy (Linux):**

```bash
# Create Firefox policy directory
sudo mkdir -p /etc/firefox/policies

# Create policies.json
cat << 'EOF' | sudo tee /etc/firefox/policies/policies.json
{
  "policies": {
    "Authentication": {
      "SPNEGO": ["https://bastion.corp.company.com", "https://*.corp.company.com"],
      "Delegated": ["https://bastion.corp.company.com"],
      "AllowNonFQDN": {
        "SPNEGO": false
      }
    }
  }
}
EOF
```

#### Microsoft Edge

Edge follows the same configuration as Internet Explorer via Group Policy or registry.

**Group Policy Settings:**

```
Computer Configuration -> Administrative Templates -> Microsoft Edge
-> HTTP authentication

AuthServerAllowlist: *.corp.company.com
AuthNegotiateDelegateAllowlist: bastion.corp.company.com
```

**Registry Settings:**

```powershell
# PowerShell commands to configure Edge
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" `
    -Name "AuthServerAllowlist" `
    -Value "*.corp.company.com" `
    -PropertyType String -Force

New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" `
    -Name "AuthNegotiateDelegateAllowlist" `
    -Value "bastion.corp.company.com" `
    -PropertyType String -Force
```

### Web SSO Configuration

#### WALLIX Web Interface SSO Settings

```json
{
  "sso_settings": {
    "enabled": true,
    "method": "spnego",

    "spnego_config": {
      "primary_authentication": true,
      "fallback_to_form": true,
      "realm_stripping": true
    },

    "session_config": {
      "idle_timeout_minutes": 30,
      "max_session_hours": 8,
      "single_session": false
    },

    "logout_config": {
      "clear_kerberos_cache": false,
      "redirect_url": "/login"
    }
  }
}
```

### Fallback Authentication

When Kerberos/SPNEGO fails, provide fallback options:

```
+-----------------------------------------------------------------------------+
|                      AUTHENTICATION FALLBACK FLOW                            |
+-----------------------------------------------------------------------------+
|                                                                              |
|   USER                                                                       |
|     |                                                                        |
|     |  Step 1: Try SPNEGO/Kerberos                                          |
|     v                                                                        |
|   +---------------------------------------------+                           |
|   |  SPNEGO Authentication                      |                           |
|   |  - Browser sends Negotiate header           |                           |
|   |  - WALLIX validates ticket                  |                           |
|   +---------------------+-----------------------+                           |
|                         |                                                    |
|         Success?        |                                                    |
|           |             |                                                    |
|      +----+----+        |                                                    |
|      |         |        |                                                    |
|     YES       NO        |                                                    |
|      |         |        |                                                    |
|      v         v        |                                                    |
|   [SSO]     Step 2: Fallback                                                |
|   [Done]      |                                                              |
|               v                                                              |
|   +---------------------------------------------+                           |
|   |  Form-Based Login                           |                           |
|   |  - Username/password prompt                 |                           |
|   |  - Can use LDAP, Local, RADIUS              |                           |
|   +---------------------+-----------------------+                           |
|                         |                                                    |
|                         v                                                    |
|   [Session Established]                                                     |
|                                                                              |
+-----------------------------------------------------------------------------+
```

#### Fallback Configuration

```json
{
  "authentication_policy": {
    "name": "kerberos-with-fallback",
    "methods": [
      {
        "order": 1,
        "type": "kerberos",
        "required": false,
        "config": {
          "realm": "CORP.COMPANY.COM"
        }
      },
      {
        "order": 2,
        "type": "ldap",
        "required": false,
        "config": {
          "server": "dc01.corp.company.com",
          "fallback_reason": ["kerberos_failed", "no_negotiate_header"]
        }
      },
      {
        "order": 3,
        "type": "local",
        "required": false,
        "config": {
          "fallback_reason": ["ldap_unavailable"]
        }
      }
    ],
    "policy": "first_success"
  }
}
```

---

## Cross-Realm Trust

### Multi-Domain Setup

For organizations with multiple Active Directory domains or forests, configure cross-realm trust.

```
+-----------------------------------------------------------------------------+
|                       CROSS-REALM TRUST ARCHITECTURE                         |
+-----------------------------------------------------------------------------+
|                                                                              |
|   +-----------------------------------+   +-----------------------------------+
|   |         CORP.COMPANY.COM          |   |         DMZ.COMPANY.COM           |
|   |         (Internal Domain)         |   |         (DMZ Domain)              |
|   |                                   |   |                                   |
|   |  +---------------------------+    |   |    +---------------------------+  |
|   |  |    dc01.corp.company.com  |    |   |    |   dmzdc01.dmz.company.com |  |
|   |  |         KDC               |<========>   |         KDC               |  |
|   |  +---------------------------+    |   |    +---------------------------+  |
|   |              |                    |   |                |                  |
|   |              |                    |   |                |                  |
|   |  +-----------+-----------+        |   |    +-----------+-----------+      |
|   |  |                       |        |   |    |                       |      |
|   |  v                       v        |   |    v                       v      |
|   | Users                  Services   |   |  Users                  Services  |
|   | jsmith@CORP...         bastion    |   |  vendor@DMZ...          webapps   |
|   |                                   |   |                                   |
|   +-----------------------------------+   +-----------------------------------+
|                     |                               |                         |
|                     +---------------+---------------+                         |
|                                     |                                         |
|                              +------+------+                                  |
|                              |   WALLIX    |                                  |
|                              |   Bastion   |                                  |
|                              |             |                                  |
|                              | Accepts     |                                  |
|                              | tickets from|                                  |
|                              | both realms |                                  |
|                              +-------------+                                  |
|                                                                              |
+-----------------------------------------------------------------------------+
```

### krb5.conf for Cross-Realm

```ini
# /etc/krb5.conf - Cross-realm configuration

[libdefaults]
    default_realm = CORP.COMPANY.COM
    dns_lookup_realm = true
    dns_lookup_kdc = true

[realms]
    CORP.COMPANY.COM = {
        kdc = dc01.corp.company.com:88
        kdc = dc02.corp.company.com:88
        admin_server = dc01.corp.company.com:749
        default_domain = corp.company.com
    }

    DMZ.COMPANY.COM = {
        kdc = dmzdc01.dmz.company.com:88
        admin_server = dmzdc01.dmz.company.com:749
        default_domain = dmz.company.com
    }

[domain_realm]
    .corp.company.com = CORP.COMPANY.COM
    corp.company.com = CORP.COMPANY.COM
    .dmz.company.com = DMZ.COMPANY.COM
    dmz.company.com = DMZ.COMPANY.COM

[capaths]
    # Trust paths between realms
    CORP.COMPANY.COM = {
        DMZ.COMPANY.COM = .
    }
    DMZ.COMPANY.COM = {
        CORP.COMPANY.COM = .
    }
```

### Trust Relationship Configuration

#### Active Directory Forest Trust (Windows)

```powershell
# On CORP.COMPANY.COM domain controller
# Create outgoing forest trust to DMZ.COMPANY.COM

New-ADForestTrust -Name "DMZ.COMPANY.COM" `
    -Direction Bidirectional `
    -ForestType ExternalForest `
    -TrustPassword (ConvertTo-SecureString "TrustP@ssw0rd!" -AsPlainText -Force) `
    -Authentication SelectiveAuthentication

# Verify trust
Get-ADTrust -Filter * | Select-Object Name, Direction, ForestTransitive
```

#### MIT Kerberos Cross-Realm Trust

For MIT Kerberos environments, create trust principals:

```bash
# On CORP.COMPANY.COM KDC
kadmin.local
addprinc -pw "TrustP@ssw0rd!" krbtgt/DMZ.COMPANY.COM@CORP.COMPANY.COM
addprinc -pw "TrustP@ssw0rd!" krbtgt/CORP.COMPANY.COM@DMZ.COMPANY.COM
quit

# On DMZ.COMPANY.COM KDC
kadmin.local
addprinc -pw "TrustP@ssw0rd!" krbtgt/CORP.COMPANY.COM@DMZ.COMPANY.COM
addprinc -pw "TrustP@ssw0rd!" krbtgt/DMZ.COMPANY.COM@CORP.COMPANY.COM
quit
```

### WALLIX Cross-Realm Configuration

```json
{
  "kerberos_multi_realm": {
    "primary_realm": "CORP.COMPANY.COM",
    "trusted_realms": [
      {
        "realm": "DMZ.COMPANY.COM",
        "trust_type": "bidirectional",
        "user_mapping": {
          "domain_prefix": "DMZ",
          "auto_create": false
        }
      }
    ],
    "realm_routing": {
      "@corp.company.com": "CORP.COMPANY.COM",
      "@dmz.company.com": "DMZ.COMPANY.COM"
    }
  }
}
```

---

## Multi-Realm Kerberos and Cross-Forest Trust

### Overview

In enterprise environments with complex organizational structures, mergers, acquisitions, or multi-national operations, multiple Kerberos realms (Active Directory forests/domains) are common. WALLIX Bastion can authenticate users and access resources across these multiple realms using cross-realm trust relationships.

**Key Use Cases:**

| Scenario | Description | Configuration |
|----------|-------------|---------------|
| **Merged Organizations** | Two companies merge, each with its own AD forest | Cross-forest trust |
| **Subsidiary Access** | Parent company needs to manage subsidiary infrastructure | One-way trust |
| **Multi-National Deployment** | Regional offices with separate AD domains | Transitive trust chain |
| **Partner Integration** | External partners need limited access to resources | Selective authentication |
| **DMZ Segregation** | Separate realm for DMZ resources with restricted trust | One-way forest trust |

### Cross-Realm Architecture

```
+===============================================================================+
|                   MULTI-REALM KERBEROS ARCHITECTURE                           |
+===============================================================================+
|                                                                               |
|  +------------------------+      +------------------------+                   |
|  |   COMPANY.COM (Root)   |      |   SUBSIDIARY.COM       |                   |
|  |   Primary Forest       |      |   Secondary Forest     |                   |
|  |                        |      |                        |                   |
|  |  +------------------+  |      |  +------------------+  |                   |
|  |  |  dc01.company    |  |      |  |  dc01.subsidiary |  |                   |
|  |  |  .com            |  |      |  |  .com            |  |                   |
|  |  |  (KDC/AD DC)     |  |      |  |  (KDC/AD DC)     |  |                   |
|  |  +------------------+  |      |  +------------------+  |                   |
|  |          |             |      |          |             |                   |
|  +----------|-------------+      +----------|-------------+                   |
|             |                               |                                 |
|             |    Two-Way Forest Trust       |                                 |
|             |<==============================>|                                 |
|             |                               |                                 |
|             +---------------+---------------+                                 |
|                             |                                                 |
|                             v                                                 |
|                  +---------------------+                                      |
|                  |  WALLIX Bastion     |                                      |
|                  |  (PAM Platform)     |                                      |
|                  |                     |                                      |
|                  |  - Multi-realm auth |                                      |
|                  |  - Cross-forest SSO |                                      |
|                  |  - Transitive trust |                                      |
|                  +----------+----------+                                      |
|                             |                                                 |
|              +--------------+---------------+                                 |
|              |                              |                                 |
|              v                              v                                 |
|  +---------------------+        +---------------------+                       |
|  |  Target Systems     |        |  Target Systems     |                       |
|  |  COMPANY.COM        |        |  SUBSIDIARY.COM     |                       |
|  |                     |        |                     |                       |
|  |  - Windows Servers  |        |  - Windows Servers  |                       |
|  |  - Linux Servers    |        |  - Linux Servers    |                       |
|  |  - Databases        |        |  - Databases        |                       |
|  +---------------------+        +---------------------+                       |
|                                                                               |
+===============================================================================+
```

### krb5.conf Configuration for Multiple Realms

Complete configuration supporting multiple realms with cross-realm trust:

```ini
# /etc/krb5.conf - Multi-realm Kerberos configuration for WALLIX Bastion

[libdefaults]
    # Default realm for unqualified principals
    default_realm = COMPANY.COM

    # DNS-based discovery (recommended for multi-realm)
    dns_lookup_realm = true
    dns_lookup_kdc = true
    dns_canonicalize_hostname = true

    # Ticket lifetime settings
    ticket_lifetime = 10h
    renew_lifetime = 7d

    # Encryption types (strongest first, AES-256/128 only)
    default_tgs_enctypes = aes256-cts-hmac-sha1-96 aes128-cts-hmac-sha1-96
    default_tkt_enctypes = aes256-cts-hmac-sha1-96 aes128-cts-hmac-sha1-96
    permitted_enctypes = aes256-cts-hmac-sha1-96 aes128-cts-hmac-sha1-96

    # Security settings
    allow_weak_crypto = false
    clockskew = 300

    # Delegation and forwarding
    forwardable = true
    proxiable = true

    # Credential cache
    default_ccache_name = FILE:/tmp/krb5cc_%{uid}

    # RDNS (reverse DNS) - important for cross-realm
    rdns = true
    ignore_acceptor_hostname = false

[realms]
    # Primary realm - COMPANY.COM
    COMPANY.COM = {
        # Multiple KDCs for high availability
        kdc = dc01.company.com:88
        kdc = dc02.company.com:88
        kdc = dc03.company.com:88

        # Admin and password change servers
        admin_server = dc01.company.com:749
        kpasswd_server = dc01.company.com:464

        # Default domain mapping
        default_domain = company.com

        # Master KDC for propagation
        master_kdc = dc01.company.com

        # Authentication paths
        auth_to_local = RULE:[1:$1@$0](^.*@COMPANY\.COM$)s/@COMPANY\.COM$//
        auth_to_local = DEFAULT
    }

    # Secondary realm - SUBSIDIARY.COM
    SUBSIDIARY.COM = {
        kdc = dc01.subsidiary.com:88
        kdc = dc02.subsidiary.com:88
        admin_server = dc01.subsidiary.com:749
        kpasswd_server = dc01.subsidiary.com:464
        default_domain = subsidiary.com
        master_kdc = dc01.subsidiary.com

        # Username mapping for subsidiary users
        auth_to_local = RULE:[1:$1@$0](^.*@SUBSIDIARY\.COM$)s/@SUBSIDIARY\.COM$/\@SUBSIDIARY/
        auth_to_local = DEFAULT
    }

    # Regional realm - APAC.COMPANY.COM (Asia-Pacific)
    APAC.COMPANY.COM = {
        kdc = dc01.apac.company.com:88
        kdc = dc02.apac.company.com:88
        admin_server = dc01.apac.company.com:749
        default_domain = apac.company.com
    }

    # Regional realm - EMEA.COMPANY.COM (Europe, Middle East, Africa)
    EMEA.COMPANY.COM = {
        kdc = dc01.emea.company.com:88
        kdc = dc02.emea.company.com:88
        admin_server = dc01.emea.company.com:749
        default_domain = emea.company.com
    }

    # Partner realm (one-way trust)
    PARTNER.COM = {
        kdc = dc01.partner.com:88
        admin_server = dc01.partner.com:749
        default_domain = partner.com
    }

[domain_realm]
    # Map DNS domains to Kerberos realms
    # Primary domain
    .company.com = COMPANY.COM
    company.com = COMPANY.COM

    # Subsidiary domain
    .subsidiary.com = SUBSIDIARY.COM
    subsidiary.com = SUBSIDIARY.COM

    # Regional domains
    .apac.company.com = APAC.COMPANY.COM
    apac.company.com = APAC.COMPANY.COM
    .emea.company.com = EMEA.COMPANY.COM
    emea.company.com = EMEA.COMPANY.COM

    # Partner domain
    .partner.com = PARTNER.COM
    partner.com = PARTNER.COM

    # Explicit host mappings (if needed for exceptions)
    bastion.company.com = COMPANY.COM
    bastion-apac.apac.company.com = APAC.COMPANY.COM
    bastion-emea.emea.company.com = EMEA.COMPANY.COM

[capaths]
    # Cross-realm trust paths (authentication paths between realms)
    # Direct trust between COMPANY.COM and SUBSIDIARY.COM
    COMPANY.COM = {
        SUBSIDIARY.COM = .
        APAC.COMPANY.COM = .
        EMEA.COMPANY.COM = .
        PARTNER.COM = .
    }

    SUBSIDIARY.COM = {
        COMPANY.COM = .
        # Transitive trust through COMPANY.COM to regional realms
        APAC.COMPANY.COM = COMPANY.COM
        EMEA.COMPANY.COM = COMPANY.COM
    }

    # Regional realms trust parent
    APAC.COMPANY.COM = {
        COMPANY.COM = .
        SUBSIDIARY.COM = COMPANY.COM
        EMEA.COMPANY.COM = COMPANY.COM
    }

    EMEA.COMPANY.COM = {
        COMPANY.COM = .
        SUBSIDIARY.COM = COMPANY.COM
        APAC.COMPANY.COM = COMPANY.COM
    }

    # Partner realm (one-way: COMPANY -> PARTNER)
    PARTNER.COM = {
        COMPANY.COM = .
    }

[logging]
    # Detailed logging for troubleshooting
    default = FILE:/var/log/krb5/krb5libs.log
    kdc = FILE:/var/log/krb5/krb5kdc.log
    admin_server = FILE:/var/log/krb5/kadmind.log

[appdefaults]
    # PAM settings
    pam = {
        debug = false
        ticket_lifetime = 36000
        renew_lifetime = 604800
        forwardable = true
        krb4_convert = false
        validate = true
    }

    # Settings for specific realms
    COMPANY.COM = {
        pam = {
            minimum_uid = 1000
        }
    }

    SUBSIDIARY.COM = {
        pam = {
            minimum_uid = 5000
        }
    }
```

### Capaths Configuration Explained

The `[capaths]` section defines intermediate realm paths for transitive trusts. This is critical when realms don't have direct trust relationships.

#### Direct Trust Path

```ini
[capaths]
    REALM_A = {
        REALM_B = .
    }
```

The dot (`.`) indicates a **direct trust** between REALM_A and REALM_B.

#### Transitive Trust Path

```ini
[capaths]
    REALM_A = {
        REALM_C = REALM_B
    }
```

This means: To reach REALM_C from REALM_A, go through REALM_B (intermediate realm).

#### Complex Multi-Hop Trust

```ini
[capaths]
    COMPANY.COM = {
        EXTERNAL.ORG = SUBSIDIARY.COM
    }
    SUBSIDIARY.COM = {
        EXTERNAL.ORG = PARTNER.COM
    }
```

This creates a trust chain: COMPANY.COM → SUBSIDIARY.COM → PARTNER.COM → EXTERNAL.ORG

**Trust Path Visualization:**

```
+===============================================================================+
|                        TRANSITIVE TRUST PATH EXAMPLE                          |
+===============================================================================+
|                                                                               |
|  User in COMPANY.COM wants to access resource in EXTERNAL.ORG                |
|                                                                               |
|  +---------------+                +---------------+                           |
|  | COMPANY.COM   |                | SUBSIDIARY.COM|                           |
|  | (User's realm)|                | (Intermediate)|                           |
|  |               |                |               |                           |
|  |  User:        |   Trust 1      |               |   Trust 2                |
|  |  jsmith@      |===============>|               |===============>           |
|  |  COMPANY.COM  |                |               |                           |
|  +---------------+                +---------------+                           |
|                                                                               |
|  +---------------+                +---------------+                           |
|  | PARTNER.COM   |                | EXTERNAL.ORG  |                           |
|  | (Intermediate)|                | (Target realm)|                           |
|  |               |   Trust 3      |               |                           |
|  |               |===============>| Service:      |                           |
|  |               |                | resource@     |                           |
|  |               |                | EXTERNAL.ORG  |                           |
|  +---------------+                +---------------+                           |
|                                                                               |
|  Authentication flow:                                                         |
|  1. User gets TGT from COMPANY.COM KDC                                        |
|  2. User requests cross-realm TGT for SUBSIDIARY.COM                          |
|  3. User requests cross-realm TGT for PARTNER.COM                             |
|  4. User requests cross-realm TGT for EXTERNAL.ORG                            |
|  5. User gets service ticket for resource@EXTERNAL.ORG                        |
|  6. User presents service ticket to access resource                           |
|                                                                               |
+===============================================================================+
```

### Trust Setup Examples

#### One-Way Trust Setup

Used when COMPANY.COM users need access to PARTNER.COM resources, but not vice versa.

**On COMPANY.COM Domain Controller (Trusting Domain):**

```powershell
# Create outgoing one-way trust
netdom trust PARTNER.COM /domain:COMPANY.COM /add /UserD:administrator /PasswordD:* /UserO:administrator /PasswordO:*

# Or using PowerShell cmdlet
New-ADTrust -Name "PARTNER.COM" `
    -Direction Outbound `
    -Type Forest `
    -TrustPassword (ConvertTo-SecureString "ComplexTrustP@ssw0rd123!" -AsPlainText -Force) `
    -TrustingDomainName COMPANY.COM `
    -SourceName COMPANY.COM

# Verify trust
Get-ADTrust -Filter {Name -eq "PARTNER.COM"} | Format-List Name, Direction, TrustType
```

**On PARTNER.COM Domain Controller (Trusted Domain):**

```powershell
# Create incoming one-way trust
netdom trust COMPANY.COM /domain:PARTNER.COM /add /UserD:administrator /PasswordD:* /UserO:administrator /PasswordO:*

# Or using PowerShell cmdlet
New-ADTrust -Name "COMPANY.COM" `
    -Direction Inbound `
    -Type Forest `
    -TrustPassword (ConvertTo-SecureString "ComplexTrustP@ssw0rd123!" -AsPlainText -Force) `
    -SourceName PARTNER.COM

# Verify trust
Get-ADTrust -Filter {Name -eq "COMPANY.COM"} | Format-List Name, Direction, TrustType
```

**Expected Output:**

```
Name         : PARTNER.COM
Direction    : Outbound
TrustType    : Forest
```

**krb5.conf for One-Way Trust:**

```ini
[capaths]
    COMPANY.COM = {
        PARTNER.COM = .
    }
    # Note: No reciprocal entry for PARTNER.COM -> COMPANY.COM
```

#### Two-Way Trust Setup

Both domains trust each other, allowing bidirectional authentication.

**On COMPANY.COM Domain Controller:**

```powershell
# Create two-way forest trust
New-ADTrust -Name "SUBSIDIARY.COM" `
    -Direction Bidirectional `
    -Type Forest `
    -TrustPassword (ConvertTo-SecureString "BidirectionalTrust!2026" -AsPlainText -Force) `
    -RemoteDCName "dc01.subsidiary.com" `
    -SourceName COMPANY.COM

# Enable SID filtering (security boundary)
netdom trust SUBSIDIARY.COM /domain:COMPANY.COM /EnableSIDHistory:No /Quarantine:Yes

# Verify trust and test connectivity
Test-ADTrust -Identity SUBSIDIARY.COM -Verbose
```

**On SUBSIDIARY.COM Domain Controller:**

```powershell
# Accept two-way forest trust
New-ADTrust -Name "COMPANY.COM" `
    -Direction Bidirectional `
    -Type Forest `
    -TrustPassword (ConvertTo-SecureString "BidirectionalTrust!2026" -AsPlainText -Force) `
    -RemoteDCName "dc01.company.com" `
    -SourceName SUBSIDIARY.COM

# Test trust from both directions
Test-ADTrust -Identity COMPANY.COM -Verbose
```

**Verification Commands:**

```powershell
# On COMPANY.COM
Get-ADTrust -Filter * | Select-Object Name, Direction, TrustType, SelectiveAuthentication

# Test trust authentication
nltest /domain:COMPANY.COM /sc_verify:SUBSIDIARY.COM

# Query cross-realm resources
Get-ADUser -Filter * -Server SUBSIDIARY.COM -SearchBase "DC=subsidiary,DC=com"
```

**Expected Output:**

```
Name                     : SUBSIDIARY.COM
Direction                : Bidirectional
TrustType                : Forest
SelectiveAuthentication  : False

Flags: 0
Connection Status = 0 0x0 NERR_Success
The command completed successfully
```

**krb5.conf for Two-Way Trust:**

```ini
[capaths]
    COMPANY.COM = {
        SUBSIDIARY.COM = .
    }
    SUBSIDIARY.COM = {
        COMPANY.COM = .
    }
```

#### Forest Trust Setup (Complete Example)

Forest trust is the strongest trust relationship in Active Directory, allowing full authentication and authorization across forests.

**Pre-requisites Validation:**

```powershell
# 1. Verify DNS resolution between forests
nslookup dc01.subsidiary.com
nslookup dc01.company.com

# 2. Verify network connectivity
Test-NetConnection dc01.subsidiary.com -Port 88
Test-NetConnection dc01.subsidiary.com -Port 389
Test-NetConnection dc01.subsidiary.com -Port 53

# 3. Verify forest functional level (minimum Windows Server 2003)
Get-ADForest | Select-Object Name, ForestMode
```

**Create Forest Trust:**

```powershell
# On COMPANY.COM forest root domain controller
# Step 1: Create conditional forwarder for DNS
Add-DnsServerConditionalForwarderZone -Name "subsidiary.com" `
    -MasterServers 192.168.10.10,192.168.10.11 `
    -ReplicationScope Forest

# Step 2: Create forest trust with selective authentication
$TrustPassword = ConvertTo-SecureString "ForestTrust2026!SecurePassword" -AsPlainText -Force

New-ADTrust -Name "subsidiary.com" `
    -Type Forest `
    -Direction Bidirectional `
    -TrustPassword $TrustPassword `
    -RemoteDCName "dc01.subsidiary.com" `
    -SelectiveAuthentication $true `
    -Confirm:$false

# Step 3: Enable name suffix routing
Get-ADTrust -Identity "subsidiary.com" | Set-ADTrust -AllowedToDelegateTo @("*.subsidiary.com")

# Step 4: Verify trust
Test-ADTrust -Identity "subsidiary.com" -Verbose
```

**On SUBSIDIARY.COM forest root domain controller:**

```powershell
# Step 1: Create conditional forwarder
Add-DnsServerConditionalForwarderZone -Name "company.com" `
    -MasterServers 192.168.1.10,192.168.1.11 `
    -ReplicationScope Forest

# Step 2: Accept forest trust
$TrustPassword = ConvertTo-SecureString "ForestTrust2026!SecurePassword" -AsPlainText -Force

New-ADTrust -Name "company.com" `
    -Type Forest `
    -Direction Bidirectional `
    -TrustPassword $TrustPassword `
    -RemoteDCName "dc01.company.com" `
    -SelectiveAuthentication $true `
    -Confirm:$false

# Step 3: Verify trust
Test-ADTrust -Identity "company.com" -Verbose

# Step 4: Enable selective authentication for specific resources
# Grant "Allowed to Authenticate" permission to COMPANY.COM users
$CompanyGroup = Get-ADGroup "Domain Users" -Server company.com
$TargetOU = "OU=SharedResources,DC=subsidiary,DC=com"
Set-ADObject $TargetOU -Add @{"msDS-AllowedToActOnBehalfOfOtherIdentity"=$CompanyGroup}
```

**Trust Verification Script:**

```powershell
# /opt/scripts/verify-forest-trust.ps1

function Test-ForestTrust {
    param(
        [string]$TrustedForest
    )

    Write-Host "=== Forest Trust Verification ===" -ForegroundColor Cyan
    Write-Host "Trusted Forest: $TrustedForest`n"

    # Test 1: Trust existence
    Write-Host "[1] Checking trust existence..." -ForegroundColor Yellow
    $Trust = Get-ADTrust -Filter {Name -eq $TrustedForest}
    if ($Trust) {
        Write-Host "    PASS: Trust exists" -ForegroundColor Green
        Write-Host "    Direction: $($Trust.Direction)"
        Write-Host "    TrustType: $($Trust.TrustType)"
        Write-Host "    SelectiveAuth: $($Trust.SelectiveAuthentication)"
    } else {
        Write-Host "    FAIL: Trust not found" -ForegroundColor Red
        return
    }

    # Test 2: Trust validation
    Write-Host "`n[2] Testing trust authentication..." -ForegroundColor Yellow
    try {
        Test-ADTrust -Identity $TrustedForest -ErrorAction Stop
        Write-Host "    PASS: Trust authentication successful" -ForegroundColor Green
    } catch {
        Write-Host "    FAIL: $($_.Exception.Message)" -ForegroundColor Red
    }

    # Test 3: DNS resolution
    Write-Host "`n[3] Testing DNS resolution..." -ForegroundColor Yellow
    $DnsTest = Resolve-DnsName -Name $TrustedForest -Type A -ErrorAction SilentlyContinue
    if ($DnsTest) {
        Write-Host "    PASS: DNS resolution successful" -ForegroundColor Green
    } else {
        Write-Host "    FAIL: DNS resolution failed" -ForegroundColor Red
    }

    # Test 4: KDC connectivity
    Write-Host "`n[4] Testing KDC connectivity..." -ForegroundColor Yellow
    $KDCTest = Test-NetConnection -ComputerName $TrustedForest -Port 88 -WarningAction SilentlyContinue
    if ($KDCTest.TcpTestSucceeded) {
        Write-Host "    PASS: KDC port 88 reachable" -ForegroundColor Green
    } else {
        Write-Host "    FAIL: Cannot reach KDC port 88" -ForegroundColor Red
    }

    # Test 5: Cross-forest user lookup
    Write-Host "`n[5] Testing cross-forest user enumeration..." -ForegroundColor Yellow
    try {
        $Users = Get-ADUser -Filter * -Server $TrustedForest -ResultSetSize 5 -ErrorAction Stop
        Write-Host "    PASS: Retrieved $($Users.Count) users from $TrustedForest" -ForegroundColor Green
    } catch {
        Write-Host "    FAIL: $($_.Exception.Message)" -ForegroundColor Red
    }

    Write-Host "`n=== Verification Complete ===" -ForegroundColor Cyan
}

# Run verification
Test-ForestTrust -TrustedForest "subsidiary.com"
```

### Cross-Realm Authentication Flow

Detailed flow showing how tickets are obtained across realm boundaries.

```
+===============================================================================+
|              CROSS-REALM AUTHENTICATION FLOW (DETAILED)                       |
+===============================================================================+
|                                                                               |
|  USER                KDC                   KDC                   TARGET       |
|  WORKSTATION       (COMPANY.COM)        (SUBSIDIARY.COM)        SERVER        |
|  (COMPANY.COM)                                                 (SUBSIDIARY)   |
|      |                 |                     |                     |         |
|      |                 |                     |                     |         |
|  Step 1: Initial Authentication (Home Realm)                                 |
|      |                 |                     |                     |         |
|      | AS-REQ          |                     |                     |         |
|      | User: jsmith@   |                     |                     |         |
|      | COMPANY.COM     |                     |                     |         |
|      |---------------->|                     |                     |         |
|      |                 |                     |                     |         |
|      | AS-REP          |                     |                     |         |
|      | TGT for         |                     |                     |         |
|      | COMPANY.COM     |                     |                     |         |
|      |<----------------|                     |                     |         |
|      |                 |                     |                     |         |
|  Step 2: Request Cross-Realm TGT                                             |
|      |                 |                     |                     |         |
|      | TGS-REQ         |                     |                     |         |
|      | TGT: COMPANY.COM|                     |                     |         |
|      | Request: krbtgt/|                     |                     |         |
|      | SUBSIDIARY.COM@ |                     |                     |         |
|      | COMPANY.COM     |                     |                     |         |
|      |---------------->|                     |                     |         |
|      |                 |                     |                     |         |
|      |                 | [KDC verifies       |                     |         |
|      |                 |  trust relationship]|                     |         |
|      |                 |                     |                     |         |
|      | TGS-REP         |                     |                     |         |
|      | Cross-realm TGT |                     |                     |         |
|      | for SUBSIDIARY  |                     |                     |         |
|      |<----------------|                     |                     |         |
|      |                 |                     |                     |         |
|  Step 3: Request Service Ticket from Foreign Realm                           |
|      |                 |                     |                     |         |
|      | TGS-REQ                               |                     |         |
|      | Cross-realm TGT                       |                     |         |
|      | Request: cifs/fileserver.subsidiary   |                     |         |
|      | .com@SUBSIDIARY.COM                   |                     |         |
|      |-------------------------------------->|                     |         |
|      |                 |                     |                     |         |
|      |                 |                     | [KDC validates      |         |
|      |                 |                     |  cross-realm TGT]   |         |
|      |                 |                     | [Checks trust]      |         |
|      |                 |                     |                     |         |
|      | TGS-REP                               |                     |         |
|      | Service ticket for                    |                     |         |
|      | fileserver@SUBSIDIARY.COM             |                     |         |
|      |<--------------------------------------|                     |         |
|      |                 |                     |                     |         |
|  Step 4: Access Service with Cross-Realm Ticket                              |
|      |                 |                     |                     |         |
|      | AP-REQ (GSSAPI)                       |                     |         |
|      | Service ticket                                              |         |
|      | Authenticator                                               |         |
|      |------------------------------------------------------------>|         |
|      |                 |                     |                     |         |
|      |                 |                     |       [Server validates       |
|      |                 |                     |        cross-realm ticket]    |
|      |                 |                     |       [Checks PAC]            |
|      |                 |                     |                     |         |
|      | AP-REP (optional)                                           |         |
|      | Mutual authentication                                       |         |
|      |<------------------------------------------------------------|         |
|      |                 |                     |                     |         |
|      | Authorized access to resource                               |         |
|      |<============================================================>|         |
|      |                 |                     |                     |         |
|                                                                               |
|  Ticket Contents:                                                             |
|  - Home TGT: Encrypted with user's key, contains PAC with SIDs                |
|  - Cross-realm TGT: Encrypted with inter-realm trust key (krbtgt/FOREIGN@HOME)|
|  - Service ticket: Encrypted with service key, includes cross-realm PAC       |
|                                                                               |
+===============================================================================+
```

### Testing Cross-Realm Authentication

#### Test 1: Obtain Initial TGT in Home Realm

```bash
# Authenticate as user in COMPANY.COM realm
kinit jsmith@COMPANY.COM

# Verify TGT
klist

# Expected output:
Ticket cache: FILE:/tmp/krb5cc_1000
Default principal: jsmith@COMPANY.COM

Valid starting       Expires              Service principal
02/04/2026 09:00:00  02/04/2026 19:00:00  krbtgt/COMPANY.COM@COMPANY.COM
        renew until 02/11/2026 09:00:00
```

#### Test 2: Request Cross-Realm TGT

```bash
# Request service ticket for foreign realm service
# This automatically obtains cross-realm TGT
kvno cifs/fileserver.subsidiary.com@SUBSIDIARY.COM

# Verify both TGTs now exist
klist

# Expected output:
Ticket cache: FILE:/tmp/krb5cc_1000
Default principal: jsmith@COMPANY.COM

Valid starting       Expires              Service principal
02/04/2026 09:00:00  02/04/2026 19:00:00  krbtgt/COMPANY.COM@COMPANY.COM
        renew until 02/11/2026 09:00:00
02/04/2026 09:05:00  02/04/2026 19:00:00  krbtgt/SUBSIDIARY.COM@COMPANY.COM
        renew until 02/11/2026 09:00:00
02/04/2026 09:05:00  02/04/2026 19:00:00  cifs/fileserver.subsidiary.com@SUBSIDIARY.COM
        renew until 02/11/2026 09:00:00
```

#### Test 3: Verify Encryption Types

```bash
# Display encryption types for all tickets
klist -e

# Expected output with encryption details:
Ticket cache: FILE:/tmp/krb5cc_1000
Default principal: jsmith@COMPANY.COM

Valid starting       Expires              Service principal
02/04/2026 09:00:00  02/04/2026 19:00:00  krbtgt/COMPANY.COM@COMPANY.COM
        renew until 02/11/2026 09:00:00
        Etype (skey, tkt): aes256-cts-hmac-sha1-96, aes256-cts-hmac-sha1-96
02/04/2026 09:05:00  02/04/2026 19:00:00  krbtgt/SUBSIDIARY.COM@COMPANY.COM
        renew until 02/11/2026 09:00:00
        Etype (skey, tkt): aes256-cts-hmac-sha1-96, aes256-cts-hmac-sha1-96
02/04/2026 09:05:00  02/04/2026 19:00:00  cifs/fileserver.subsidiary.com@SUBSIDIARY.COM
        renew until 02/11/2026 09:00:00
        Etype (skey, tkt): aes256-cts-hmac-sha1-96, aes256-cts-hmac-sha1-96
```

#### Test 4: Test Cross-Realm Service Access

```bash
# Test SMB/CIFS access to foreign realm server
smbclient -k //fileserver.subsidiary.com/share -c "ls"

# Expected: File listing (authenticated via Kerberos cross-realm)
  .                                   D        0  Tue Feb  4 09:00:00 2026
  ..                                  D        0  Tue Feb  4 09:00:00 2026
  documents                           D        0  Mon Feb  3 14:30:00 2026

                50331648 blocks of size 1024. 25165824 blocks available
```

#### Test 5: Trace Cross-Realm Authentication

```bash
# Enable Kerberos debug tracing
export KRB5_TRACE=/dev/stdout

# Request cross-realm service ticket with full trace
kvno cifs/fileserver.subsidiary.com@SUBSIDIARY.COM

# Expected trace output (abbreviated):
[1000] 1738662000.123456: Getting credentials jsmith@COMPANY.COM -> cifs/fileserver.subsidiary.com@SUBSIDIARY.COM
[1000] 1738662000.123457: Starting with TGT for client realm: krbtgt/COMPANY.COM@COMPANY.COM
[1000] 1738662000.123458: Trying to find service cifs/fileserver.subsidiary.com@SUBSIDIARY.COM in realm COMPANY.COM
[1000] 1738662000.123459: Sending request to COMPANY.COM KDC: dc01.company.com
[1000] 1738662000.123460: Response from KDC: referral to realm SUBSIDIARY.COM
[1000] 1738662000.123461: Received cross-realm TGT: krbtgt/SUBSIDIARY.COM@COMPANY.COM
[1000] 1738662000.123462: Following referral to realm SUBSIDIARY.COM
[1000] 1738662000.123463: Sending TGS-REQ to SUBSIDIARY.COM KDC: dc01.subsidiary.com
[1000] 1738662000.123464: Received service ticket: cifs/fileserver.subsidiary.com@SUBSIDIARY.COM
[1000] 1738662000.123465: Storing cifs/fileserver.subsidiary.com@SUBSIDIARY.COM in cache
```

#### Test 6: Automated Cross-Realm Test Script

```bash
#!/bin/bash
# /usr/local/bin/test-cross-realm.sh
# Automated cross-realm Kerberos authentication test

set -euo pipefail

# Configuration
HOME_REALM="COMPANY.COM"
FOREIGN_REALM="SUBSIDIARY.COM"
TEST_USER="jsmith@${HOME_REALM}"
TEST_SERVICE="cifs/fileserver.subsidiary.com@${FOREIGN_REALM}"
TEST_PASSWORD=""  # Will prompt

echo "=========================================="
echo "Cross-Realm Kerberos Authentication Test"
echo "=========================================="
echo "Home Realm:    $HOME_REALM"
echo "Foreign Realm: $FOREIGN_REALM"
echo "Test User:     $TEST_USER"
echo "Test Service:  $TEST_SERVICE"
echo

# Clean credential cache
echo "[1/7] Cleaning credential cache..."
kdestroy -A 2>/dev/null || true
echo "      Done"

# Obtain initial TGT
echo "[2/7] Obtaining TGT in home realm..."
if [ -z "$TEST_PASSWORD" ]; then
    kinit "$TEST_USER"
else
    echo "$TEST_PASSWORD" | kinit "$TEST_USER"
fi
echo "      Done"

# Verify home realm TGT
echo "[3/7] Verifying home realm TGT..."
if klist | grep -q "krbtgt/${HOME_REALM}@${HOME_REALM}"; then
    echo "      PASS: Home realm TGT obtained"
else
    echo "      FAIL: No home realm TGT found"
    exit 1
fi

# Request cross-realm service ticket
echo "[4/7] Requesting cross-realm service ticket..."
if kvno "$TEST_SERVICE" >/dev/null 2>&1; then
    echo "      PASS: Service ticket obtained"
else
    echo "      FAIL: Could not obtain service ticket"
    exit 1
fi

# Verify cross-realm TGT exists
echo "[5/7] Verifying cross-realm TGT..."
if klist | grep -q "krbtgt/${FOREIGN_REALM}@${HOME_REALM}"; then
    echo "      PASS: Cross-realm TGT obtained"
else
    echo "      FAIL: No cross-realm TGT found"
    exit 1
fi

# Verify service ticket exists
echo "[6/7] Verifying service ticket..."
if klist | grep -q "$TEST_SERVICE"; then
    echo "      PASS: Service ticket exists"
else
    echo "      FAIL: Service ticket not found"
    exit 1
fi

# Display ticket details
echo "[7/7] Ticket cache contents:"
klist -e

echo
echo "=========================================="
echo "Cross-realm authentication test: SUCCESS"
echo "=========================================="
```

### Troubleshooting Cross-Realm Issues

#### Common Cross-Realm Errors

| Error | Cause | Resolution |
|-------|-------|------------|
| `Client not found in Kerberos database` | User doesn't exist in home realm | Verify user principal name |
| `Server not found in Kerberos database` | Service doesn't exist in target realm | Check SPN registration in target realm |
| `Cross-realm policy rejects requested ticket` | Trust not established or capaths misconfigured | Verify trust and capaths configuration |
| `Cannot find key of appropriate type` | Encryption type mismatch between realms | Align encryption types in both realms |
| `KDC has no support for encryption type` | Weak encryption types not allowed | Use AES-256/128 only |
| `Ticket not yet valid` | Clock skew between realms | Synchronize time via NTP |

#### Debugging Cross-Realm with Wireshark

```bash
# Capture cross-realm Kerberos traffic
tcpdump -i any -w cross-realm.pcap \
    '(host dc01.company.com or host dc01.subsidiary.com) and port 88'

# Analyze with tshark
tshark -r cross-realm.pcap -Y 'kerberos' -T fields \
    -e frame.number \
    -e ip.src \
    -e ip.dst \
    -e kerberos.msg_type \
    -e kerberos.realm \
    -e kerberos.sname_string

# Look for cross-realm TGS-REQ/REP messages
# msg_type 12 = TGS-REQ (request for service ticket)
# msg_type 13 = TGS-REP (service ticket response)
# Check realm field shows both HOME and FOREIGN realms
```

#### Verify Trust Relationship

```bash
# From Linux/WALLIX Bastion
# Query trust information from Active Directory
ldapsearch -x -H ldap://dc01.company.com \
    -D "CN=Administrator,CN=Users,DC=company,DC=com" \
    -W -b "CN=System,DC=company,DC=com" \
    '(objectClass=trustedDomain)' \
    trustPartner flatName trustDirection trustType

# Expected output shows trust to SUBSIDIARY.COM:
# dn: CN=SUBSIDIARY.COM,CN=System,DC=company,DC=com
# trustPartner: subsidiary.com
# flatName: SUBSIDIARY
# trustDirection: 3 (bidirectional)
# trustType: 2 (forest trust)
```

```powershell
# From Windows/Domain Controller
# Detailed trust information
Get-ADTrust -Filter * | Format-List *

# Test trust connectivity
Test-ADTrust -Identity SUBSIDIARY.COM

# Check trust authentication
nltest /sc_verify:SUBSIDIARY.COM
```

### WALLIX Multi-Realm Configuration

Configure WALLIX Bastion to support multiple Kerberos realms:

```json
{
  "kerberos_multi_realm_configuration": {
    "enabled": true,
    "primary_realm": "COMPANY.COM",

    "realms": [
      {
        "name": "COMPANY.COM",
        "type": "primary",
        "kdc_servers": [
          "dc01.company.com:88",
          "dc02.company.com:88"
        ],
        "service_principal": "HTTP/bastion.company.com@COMPANY.COM",
        "keytab_file": "/var/lib/wallix/bastion/etc/krb5-company.keytab",
        "user_mapping": {
          "strip_realm": true,
          "username_attribute": "sAMAccountName",
          "domain_prefix": ""
        }
      },
      {
        "name": "SUBSIDIARY.COM",
        "type": "trusted",
        "kdc_servers": [
          "dc01.subsidiary.com:88",
          "dc02.subsidiary.com:88"
        ],
        "trust_type": "bidirectional_forest",
        "user_mapping": {
          "strip_realm": false,
          "username_attribute": "userPrincipalName",
          "domain_prefix": "SUB"
        },
        "authorization": {
          "auto_create_users": false,
          "default_profile": "readonly",
          "group_mapping": {
            "Domain Admins@SUBSIDIARY.COM": "wallix-admins",
            "PAM Users@SUBSIDIARY.COM": "wallix-users"
          }
        }
      },
      {
        "name": "PARTNER.COM",
        "type": "trusted",
        "kdc_servers": [
          "dc01.partner.com:88"
        ],
        "trust_type": "oneway_outbound",
        "user_mapping": {
          "strip_realm": false,
          "username_attribute": "userPrincipalName",
          "domain_prefix": "PARTNER"
        },
        "authorization": {
          "auto_create_users": false,
          "require_explicit_authorization": true,
          "allowed_groups": [
            "ExternalContractors@PARTNER.COM"
          ]
        },
        "session_restrictions": {
          "max_session_duration": 4,
          "recording_mandatory": true,
          "approval_required": true
        }
      }
    ],

    "cross_realm_settings": {
      "enable_transitive_trust": true,
      "validate_trust_chain": true,
      "cache_cross_realm_tgts": true,
      "cross_realm_tgt_lifetime": 3600
    },

    "security_settings": {
      "require_pac_validation": true,
      "enforce_selective_auth": true,
      "log_cross_realm_access": true,
      "alert_on_trust_failures": true
    }
  }
}
```

Apply configuration via WALLIX API:

```bash
# Update WALLIX Kerberos multi-realm configuration
curl -X PUT "https://bastion.company.com/api/v3.12/kerberos/multirealm" \
  -H "Content-Type: application/json" \
  -H "X-Auth-User: admin" \
  -H "X-Auth-Key: ${WALLIX_API_KEY}" \
  -d @multi-realm-config.json

# Verify configuration
curl -X GET "https://bastion.company.com/api/v3.12/kerberos/multirealm" \
  -H "X-Auth-User: admin" \
  -H "X-Auth-Key: ${WALLIX_API_KEY}" | jq .
```

---

## Constrained Delegation

### Overview

Constrained delegation allows WALLIX Bastion to impersonate users when connecting to target servers, enabling true SSO without credential forwarding.

### S4U2Self and S4U2Proxy

```
+-----------------------------------------------------------------------------+
|                    CONSTRAINED DELEGATION FLOW                               |
+-----------------------------------------------------------------------------+
|                                                                              |
|   USER                WALLIX              KDC                 TARGET         |
|   WORKSTATION         BASTION                                 SERVER         |
|      |                   |                  |                    |           |
|      |  1. Authenticate  |                  |                    |           |
|      |    (any method)   |                  |                    |           |
|      |------------------>|                  |                    |           |
|      |                   |                  |                    |           |
|      |                   |  2. S4U2Self     |                    |           |
|      |                   |  (Get ticket     |                    |           |
|      |                   |   for user)      |                    |           |
|      |                   |----------------->|                    |           |
|      |                   |                  |                    |           |
|      |                   |  3. Self-ticket  |                    |           |
|      |                   |<-----------------|                    |           |
|      |                   |                  |                    |           |
|      |                   |  4. S4U2Proxy    |                    |           |
|      |                   |  (Get ticket for |                    |           |
|      |                   |   target service)|                    |           |
|      |                   |----------------->|                    |           |
|      |                   |                  |                    |           |
|      |                   |  5. Service      |                    |           |
|      |                   |     ticket       |                    |           |
|      |                   |<-----------------|                    |           |
|      |                   |                  |                    |           |
|      |                   |  6. Connect with impersonated        |           |
|      |                   |     ticket                            |           |
|      |                   |-------------------------------------->|           |
|      |                   |                  |                    |           |
|      |  7. Session to target server         |                    |           |
|      |<----------------------------------------------------->   |           |
|      |                   |                  |                    |           |
+-----------------------------------------------------------------------------+
```

### Configure Constrained Delegation in AD

#### Enable Delegation for Service Account

```powershell
# Configure service account for constrained delegation
Set-ADUser svc_wallix_krb -TrustedForDelegation $false
Set-ADUser svc_wallix_krb -TrustedToAuthForDelegation $true

# Add allowed delegation targets
Set-ADUser svc_wallix_krb -Add @{
    'msDS-AllowedToDelegateTo' = @(
        'HOST/server01.corp.company.com',
        'HOST/server02.corp.company.com',
        'MSSQLSvc/sqlserver.corp.company.com:1433',
        'HTTP/webapp.corp.company.com'
    )
}

# Verify delegation configuration
Get-ADUser svc_wallix_krb -Properties msDS-AllowedToDelegateTo, TrustedToAuthForDelegation |
    Select-Object Name, TrustedToAuthForDelegation, @{N='AllowedServices';E={$_.'msDS-AllowedToDelegateTo'}}
```

**Expected Output:**
```
Name            TrustedToAuthForDelegation AllowedServices
----            -------------------------- ---------------
svc_wallix_krb  True                       {HOST/server01.corp.company.com,
                                            HOST/server02.corp.company.com,
                                            MSSQLSvc/sqlserver.corp.company.com:1433,
                                            HTTP/webapp.corp.company.com}
```

### Protocol Transition

Protocol transition (S4U2Self) allows WALLIX to obtain a Kerberos ticket for a user who authenticated via a non-Kerberos method (e.g., RADIUS MFA, SAML).

#### Enable Protocol Transition

```powershell
# Enable "Use any authentication protocol" for the service account
# This is required for S4U2Self to work

$ServiceAccount = Get-ADUser svc_wallix_krb
$ServiceAccount | Set-ADAccountControl -TrustedToAuthForDelegation $true

# Or via ADSI Edit:
# Navigate to: CN=svc_wallix_krb,OU=Service Accounts,...
# Modify: userAccountControl
# Add flag: TRUSTED_TO_AUTH_FOR_DELEGATION (0x1000000)
```

### WALLIX Delegation Configuration

```json
{
  "delegation_settings": {
    "enabled": true,
    "type": "constrained",

    "s4u_config": {
      "protocol_transition": true,
      "use_any_auth": true
    },

    "target_services": [
      {
        "pattern": "HOST/*.corp.company.com",
        "allow_delegation": true
      },
      {
        "pattern": "MSSQLSvc/*.corp.company.com:*",
        "allow_delegation": true
      }
    ],

    "security_settings": {
      "validate_pac": true,
      "require_forwardable": false,
      "log_delegation": true
    }
  }
}
```

---

## Troubleshooting

### Clock Skew Errors

**Symptom:** Authentication fails with "Clock skew too great"

```
kinit: Clock skew too great while getting initial credentials
```

**Diagnosis:**

```bash
# Check time difference with KDC
date && ssh dc01.corp.company.com date

# Example showing problematic skew
Local:   Fri Jan 31 10:45:23 UTC 2026
Remote:  Fri Jan 31 10:52:18 UTC 2026
# Difference: ~7 minutes (exceeds 5-minute default)
```

**Resolution:**

```bash
# Force immediate time sync
systemctl stop chrony
chronyd -q 'server dc01.corp.company.com iburst'
systemctl start chrony

# Verify sync
chronyc tracking | grep "System time"
```

### SPN Issues

**Symptom:** "Server not found in Kerberos database"

```
kinit: Server not found in Kerberos database while getting credentials for HTTP/bastion.corp.company.com@CORP.COMPANY.COM
```

**Diagnosis:**

```powershell
# Check SPN registration (on AD)
setspn -Q HTTP/bastion.corp.company.com

# Check for duplicate SPNs
setspn -X -F

# Verify service account
Get-ADUser svc_wallix_krb -Properties servicePrincipalName |
    Select-Object -ExpandProperty servicePrincipalName
```

**Resolution:**

```powershell
# Re-register SPN
setspn -D HTTP/bastion.corp.company.com svc_wallix_krb  # Remove if exists
setspn -S HTTP/bastion.corp.company.com svc_wallix_krb  # Add fresh
```

### Keytab Problems

**Symptom:** "Cannot find key of appropriate type"

```
gss_acquire_cred() failed: No key table entry found for HTTP/bastion.corp.company.com@CORP.COMPANY.COM
```

**Diagnosis:**

```bash
# List keytab entries
klist -kte /etc/krb5.keytab

# Check kvno (key version number)
kvno HTTP/bastion.corp.company.com@CORP.COMPANY.COM

# Compare with AD
kinit administrator@CORP.COMPANY.COM
kvno HTTP/bastion.corp.company.com
```

**Common Issues:**

| Issue | Cause | Resolution |
|-------|-------|------------|
| KVNO mismatch | Password changed after keytab created | Regenerate keytab |
| Wrong encryption | Keytab/AD encryption mismatch | Generate with correct -crypto |
| Principal mismatch | SPN differs from keytab entry | Verify SPN matches exactly |
| Permission denied | Keytab not readable by service | Fix permissions (chmod 600) |

**Resolution:**

```bash
# Regenerate keytab with correct KVNO
# First, check current KVNO in AD
kvno HTTP/bastion.corp.company.com@CORP.COMPANY.COM

# Output shows: HTTP/bastion.corp.company.com@CORP.COMPANY.COM: kvno = 3

# Regenerate keytab on AD with matching KVNO
ktpass -out wallix.keytab ^
       -princ HTTP/bastion.corp.company.com@CORP.COMPANY.COM ^
       -mapuser CORP\svc_wallix_krb ^
       -pass "P@ssw0rd!Complex123" ^
       -kvno 3 ^
       -ptype KRB5_NT_PRINCIPAL ^
       -crypto AES256-SHA1
```

### Ticket Cache Issues

**Symptom:** "Credentials cache file not found"

```
klist: No credentials cache found
```

**Diagnosis:**

```bash
# Check cache location
echo $KRB5CCNAME

# List all credential caches
ls -la /tmp/krb5cc_*

# Check default cache name in krb5.conf
grep default_ccache_name /etc/krb5.conf
```

**Resolution:**

```bash
# Set cache environment variable
export KRB5CCNAME=FILE:/tmp/krb5cc_$(id -u)

# Or use specific cache
export KRB5CCNAME=FILE:/tmp/krb5cc_wallix

# Initialize new cache
kinit -c $KRB5CCNAME jsmith@CORP.COMPANY.COM
```

### Browser SSO Failures

**Symptom:** Browser prompts for credentials instead of SSO

**Diagnosis Checklist:**

| Check | Command/Action | Expected Result |
|-------|----------------|-----------------|
| User has TGT | `klist` | Valid krbtgt ticket |
| Service ticket available | `klist` after accessing site | Service ticket for HTTP/bastion... |
| Browser trusted sites | Check browser config | bastion.corp.company.com listed |
| DNS resolution | `nslookup bastion.corp.company.com` | Correct IP |
| HTTP response | Developer tools -> Network | 401 with Negotiate header |

**Browser-Specific Debugging:**

```bash
# Chrome - enable debug logging
google-chrome --enable-logging --v=1 --auth-server-whitelist="*.corp.company.com"

# Firefox - check about:config
# network.negotiate-auth.trusted-uris should include the site

# Edge - check policy
Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name AuthServerAllowlist
```

**Resolution:**

```bash
# Test service ticket acquisition manually
kvno HTTP/bastion.corp.company.com@CORP.COMPANY.COM

# Should show:
HTTP/bastion.corp.company.com@CORP.COMPANY.COM: kvno = 3

# If fails, check:
# 1. SPN registration
# 2. DNS resolution
# 3. Network connectivity to KDC
```

---

## Diagnostic Commands

### klist - List Credentials

```bash
# List all tickets
klist

# Example output
Ticket cache: FILE:/tmp/krb5cc_1000
Default principal: jsmith@CORP.COMPANY.COM

Valid starting       Expires              Service principal
01/31/2026 10:00:00  01/31/2026 20:00:00  krbtgt/CORP.COMPANY.COM@CORP.COMPANY.COM
        renew until 02/07/2026 10:00:00
01/31/2026 10:05:00  01/31/2026 20:00:00  HTTP/bastion.corp.company.com@CORP.COMPANY.COM
        renew until 02/07/2026 10:00:00

# List with encryption types
klist -e

# List keytab entries
klist -kte /etc/krb5.keytab

# Example keytab output
Keytab name: FILE:/etc/krb5.keytab
KVNO Timestamp           Principal
---- ------------------- ------------------------------------------------------
   3 01/31/2026 09:00:00 HTTP/bastion.corp.company.com@CORP.COMPANY.COM (aes256-cts-hmac-sha1-96)
   3 01/31/2026 09:00:00 HTTP/bastion.corp.company.com@CORP.COMPANY.COM (aes128-cts-hmac-sha1-96)
```

### kinit - Obtain Tickets

```bash
# Basic kinit
kinit jsmith@CORP.COMPANY.COM

# With keytab
kinit -kt /etc/krb5.keytab HTTP/bastion.corp.company.com@CORP.COMPANY.COM

# Verbose mode (debug)
KRB5_TRACE=/dev/stdout kinit jsmith@CORP.COMPANY.COM

# Example trace output
[12345] 1706698800.000000: Getting initial credentials for jsmith@CORP.COMPANY.COM
[12345] 1706698800.000001: Sending unauthenticated request
[12345] 1706698800.000002: Sending request (200 bytes) to CORP.COMPANY.COM
[12345] 1706698800.000003: Initiating TCP connection to 192.168.1.10:88
[12345] 1706698800.000004: Received answer (1234 bytes) from 192.168.1.10:88
[12345] 1706698800.000005: Response was from primary KDC
[12345] 1706698800.000006: Received error from KDC: PREAUTH_REQUIRED
[12345] 1706698800.000007: Processing preauth types: PA-ETYPE-INFO2 (19), PA-ENC-TIMESTAMP (2)
[12345] 1706698800.000008: Selected etype info: etype aes256-cts-hmac-sha1-96
[12345] 1706698800.000009: AS key determined by preauth: aes256-cts-hmac-sha1-96
[12345] 1706698800.000010: Decrypted AS reply; session key is: aes256-cts-hmac-sha1-96
[12345] 1706698800.000011: FAST negotiation: unavailable
[12345] 1706698800.000012: Storing jsmith@CORP.COMPANY.COM -> krbtgt/CORP.COMPANY.COM@CORP.COMPANY.COM

# Renewable ticket
kinit -r 7d jsmith@CORP.COMPANY.COM

# Forwardable ticket
kinit -f jsmith@CORP.COMPANY.COM
```

### kvno - Get Key Version Number

```bash
# Get KVNO for service principal
kvno HTTP/bastion.corp.company.com@CORP.COMPANY.COM

# Output
HTTP/bastion.corp.company.com@CORP.COMPANY.COM: kvno = 3

# Multiple services
kvno HTTP/bastion.corp.company.com HOST/server01.corp.company.com

# This also acquires service tickets (check with klist)
```

### kdestroy - Clear Credentials

```bash
# Destroy default credential cache
kdestroy

# Destroy all credential caches for current user
kdestroy -A

# Destroy specific cache
kdestroy -c FILE:/tmp/krb5cc_wallix
```

### Wireshark Kerberos Analysis

Capture and analyze Kerberos traffic for debugging:

```bash
# Capture Kerberos traffic
tcpdump -i eth0 -w /tmp/kerberos.pcap 'port 88'

# Or with tshark
tshark -i eth0 -f 'port 88' -w /tmp/kerberos.pcap

# Analyze with tshark
tshark -r /tmp/kerberos.pcap -Y 'kerberos' -T fields \
    -e frame.time \
    -e ip.src \
    -e ip.dst \
    -e kerberos.msg_type \
    -e kerberos.cname_string \
    -e kerberos.sname_string
```

**Kerberos Message Types in Wireshark:**

| msg_type | Name | Description |
|----------|------|-------------|
| 10 | AS-REQ | Authentication Service Request |
| 11 | AS-REP | Authentication Service Reply |
| 12 | TGS-REQ | Ticket Granting Service Request |
| 13 | TGS-REP | Ticket Granting Service Reply |
| 14 | AP-REQ | Application Request |
| 15 | AP-REP | Application Reply |
| 30 | KRB-ERROR | Error Message |

**Wireshark Display Filter Examples:**

```
# All Kerberos traffic
kerberos

# Only errors
kerberos.error_code

# Specific principal
kerberos.cname_string contains "jsmith"

# AS-REQ/REP only
kerberos.msg_type == 10 or kerberos.msg_type == 11

# TGS requests
kerberos.msg_type == 12

# SPNEGO/GSS-API
gss-api or spnego
```

### Debug Logging

#### Enable Kerberos Debug Logging

```bash
# Set debug environment variable
export KRB5_TRACE=/var/log/krb5_trace.log

# Run application with tracing
KRB5_TRACE=/dev/stdout kinit jsmith@CORP.COMPANY.COM

# For Apache/WALLIX
echo "export KRB5_TRACE=/var/log/wallix_krb5_trace.log" >> /etc/apache2/envvars
systemctl restart apache2
```

#### GSSAPI Debug Logging

```bash
# Enable GSSAPI debugging
export GSSAPI_MECH_CONF=/etc/gss/mech.d/
export GSS_USE_PROXY=1

# Apache mod_auth_gssapi debug
# In Apache config:
LogLevel auth_gssapi:trace8
```

#### WALLIX Kerberos Logs

```bash
# Check WALLIX authentication logs
tail -f /var/log/wallix/bastion/auth.log | grep -i kerberos

# Example log entries
2026-01-31 10:30:00 INFO  kerberos: Received SPNEGO token from 192.168.1.100
2026-01-31 10:30:00 DEBUG kerberos: Principal: jsmith@CORP.COMPANY.COM
2026-01-31 10:30:00 INFO  kerberos: Authentication successful for jsmith
2026-01-31 10:30:00 DEBUG kerberos: Session ticket lifetime: 36000 seconds

# Check for errors
grep -i "kerberos.*error\|krb5" /var/log/wallix/bastion/auth.log
```

### Complete Diagnostic Script

```bash
#!/bin/bash
# /usr/local/bin/kerberos-diag.sh
# Comprehensive Kerberos diagnostics for WALLIX Bastion

echo "========================================"
echo "WALLIX Bastion Kerberos Diagnostics"
echo "Date: $(date)"
echo "========================================"

# 1. Time synchronization
echo -e "\n[1] Time Synchronization"
echo "------------------------"
chronyc tracking | grep -E "Reference ID|System time|Last offset"

# 2. DNS resolution
echo -e "\n[2] DNS Resolution"
echo "------------------"
BASTION_FQDN="bastion.corp.company.com"
echo "Forward lookup: $BASTION_FQDN"
nslookup $BASTION_FQDN | grep -A1 "Name:"

BASTION_IP=$(hostname -I | awk '{print $1}')
echo "Reverse lookup: $BASTION_IP"
nslookup $BASTION_IP | grep "name ="

# 3. KDC connectivity
echo -e "\n[3] KDC Connectivity"
echo "--------------------"
for KDC in dc01.corp.company.com dc02.corp.company.com; do
    echo -n "$KDC:88 - "
    nc -zv -w2 $KDC 88 2>&1 | grep -o "succeeded\|failed"
done

# 4. Kerberos configuration
echo -e "\n[4] Kerberos Configuration"
echo "--------------------------"
echo "Default realm: $(grep default_realm /etc/krb5.conf | awk '{print $3}')"
echo "KDC servers:"
grep -A5 "^\[realms\]" /etc/krb5.conf | grep "kdc ="

# 5. Keytab verification
echo -e "\n[5] Keytab Verification"
echo "-----------------------"
KEYTAB="/var/lib/wallix/bastion/etc/krb5.keytab"
if [[ -f "$KEYTAB" ]]; then
    echo "Keytab exists: $KEYTAB"
    echo "Permissions: $(stat -c '%a %U:%G' $KEYTAB)"
    echo "Entries:"
    klist -kte $KEYTAB 2>/dev/null | tail -5
else
    echo "ERROR: Keytab not found: $KEYTAB"
fi

# 6. Current tickets
echo -e "\n[6] Current Tickets"
echo "-------------------"
klist 2>/dev/null || echo "No credential cache found"

# 7. Service connectivity test
echo -e "\n[7] Service Ticket Test"
echo "-----------------------"
SPN="HTTP/bastion.corp.company.com@CORP.COMPANY.COM"
echo "Testing: $SPN"
if kvno $SPN 2>/dev/null; then
    echo "SUCCESS: Service ticket obtained"
else
    echo "FAILED: Could not obtain service ticket"
fi

# 8. Recent authentication logs
echo -e "\n[8] Recent Kerberos Logs"
echo "------------------------"
if [[ -f /var/log/wallix/bastion/auth.log ]]; then
    grep -i kerberos /var/log/wallix/bastion/auth.log | tail -10
else
    echo "No WALLIX auth logs found"
fi

echo -e "\n========================================"
echo "Diagnostics complete"
echo "========================================"
```

---

## Kerberos Troubleshooting Guide

This comprehensive troubleshooting guide covers the most common Kerberos authentication issues encountered in WALLIX Bastion deployments, with detailed diagnosis and resolution steps.

### Issue 1: Clock Skew Errors

#### Symptoms

Authentication fails with clock-related error messages:

```
kinit: Clock skew too great while getting initial credentials
```

```
KRB5KRB_AP_ERR_SKEW: Clock skew too great
```

```
gss_acquire_cred() failed: Ticket not yet valid
```

Users may report intermittent authentication failures, particularly after extended periods or system reboots.

#### Diagnosis

**Step 1: Check Time Difference Between Systems**

```bash
# Check local system time
date

# Check KDC time
ssh dc01.corp.company.com date

# Or compare directly
date && ssh dc01.corp.company.com date

# Example output showing problematic skew
Local:   Fri Jan 31 10:45:23 UTC 2026
Remote:  Fri Jan 31 10:52:18 UTC 2026
# Difference: ~7 minutes (exceeds default 5-minute tolerance)
```

**Step 2: Check NTP/Chrony Synchronization Status**

```bash
# For chrony (recommended)
chronyc tracking

# Look for "System time" line
# Good:   System time     : 0.000125342 seconds fast of NTP time
# Bad:    System time     : 360.234567 seconds fast of NTP time (6 minutes!)

# Check source status
chronyc sources -v

# Look for '*' (current best) or '+' (combined) status
# MS column shows reachability (377 = perfect)
```

**Step 3: Check Kerberos Clock Skew Setting**

```bash
# Check configured clock skew tolerance
grep clockskew /etc/krb5.conf

# Default is 300 seconds (5 minutes)
# Output: clockskew = 300
```

**Step 4: Verify Time Across All Systems**

```bash
# Create a time check script
#!/bin/bash
# check-time-skew.sh

SYSTEMS="bastion.corp.company.com dc01.corp.company.com dc02.corp.company.com server01.corp.company.com"
BASETIME=$(date +%s)

echo "=== Time Skew Check ==="
echo "Base time: $(date -d @$BASETIME)"
echo

for HOST in $SYSTEMS; do
    REMOTE_TIME=$(ssh -o ConnectTimeout=5 $HOST date +%s 2>/dev/null)
    if [[ $? -eq 0 ]]; then
        DIFF=$((REMOTE_TIME - BASETIME))
        if [[ ${DIFF#-} -gt 300 ]]; then
            STATUS="CRITICAL"
        elif [[ ${DIFF#-} -gt 60 ]]; then
            STATUS="WARNING"
        else
            STATUS="OK"
        fi
        echo "$HOST: ${DIFF}s offset [$STATUS]"
    else
        echo "$HOST: Connection failed"
    fi
done
```

#### Resolution

**Step 1: Force Immediate Time Synchronization**

```bash
# Stop chrony service
systemctl stop chrony

# Force sync with KDC
chronyd -q 'server dc01.corp.company.com iburst'

# Expected output
2026-01-31T10:45:23Z chronyd version 4.3 starting (+CMDMON +NTP +REFCLOCK +RTC +PRIVDROP +SCFILTER +SIGND +ASYNCDNS +NTS +SECHASH +IPV6 +DEBUG)
2026-01-31T10:45:23Z Frequency -12.345 +/- 0.234 ppm read from /var/lib/chrony/drift
2026-01-31T10:45:24Z System clock was stepped by 360.123 seconds
2026-01-31T10:45:24Z chronyd exiting

# Restart chrony
systemctl start chrony

# Verify synchronization
chronyc tracking
```

**Step 2: Configure Persistent Time Synchronization**

```bash
# Edit chrony configuration
cat > /etc/chrony/chrony.conf << 'EOF'
# Use domain controllers as primary time sources
server dc01.corp.company.com iburst prefer
server dc02.corp.company.com iburst

# Fallback to external time servers
server time.windows.com iburst
server 0.debian.pool.ntp.org iburst

# Allow large initial time step (once at startup)
makestep 1.0 3

# Sync hardware clock
rtcsync

# Log tracking to file
driftfile /var/lib/chrony/drift
logdir /var/log/chrony
log tracking measurements statistics

# Allow local clients (if acting as NTP server)
allow 192.168.1.0/24
EOF

# Restart chrony
systemctl restart chrony

# Enable on boot
systemctl enable chrony
```

**Step 3: Set Hardware Clock**

```bash
# Sync hardware clock to system clock
hwclock --systohc

# Verify hardware clock
hwclock --show
```

**Step 4: Increase Clock Skew Tolerance (Temporary Workaround)**

Only use this as a temporary measure while fixing the root cause:

```bash
# Edit /etc/krb5.conf
# In [libdefaults] section, increase tolerance to 10 minutes
cat >> /etc/krb5.conf << 'EOF'

[libdefaults]
    clockskew = 600
EOF

# Restart WALLIX services
systemctl restart wallix-bastion
```

> **Warning**: Increasing clock skew tolerance reduces security. Always fix the underlying time synchronization issue instead.

#### Verification Steps

```bash
# 1. Verify chrony is running and synced
systemctl status chrony
chronyc tracking | grep "System time"

# 2. Compare time with KDC
date && ssh dc01.corp.company.com date
# Difference should be < 1 second

# 3. Test Kerberos authentication
kdestroy -A
kinit jsmith@CORP.COMPANY.COM
# Should succeed without clock skew errors

# 4. Check WALLIX authentication logs
tail -f /var/log/wallix/bastion/auth.log | grep -i "clock\|skew"
```

---

### Issue 2: Keytab File Issues

#### Symptoms

Keytab-related authentication failures:

```
gss_acquire_cred() failed: No key table entry found for HTTP/bastion.corp.company.com@CORP.COMPANY.COM
```

```
kinit(v5): Key table entry not found while getting initial credentials
```

```
KRB5_KT_NOTFOUND: Key table entry not found
```

```
Key version number for principal in key table is incorrect
```

Service starts but Kerberos authentication fails. Browser prompts for credentials instead of SSO.

#### Diagnosis

**Step 1: Verify Keytab File Exists and is Readable**

```bash
# Check keytab file exists
ls -la /var/lib/wallix/bastion/etc/krb5.keytab

# Expected output
-rw------- 1 wabuser wabgroup 256 Jan 31 10:00 /var/lib/wallix/bastion/etc/krb5.keytab

# Check permissions (must be 600 or 400)
stat -c '%a %U:%G' /var/lib/wallix/bastion/etc/krb5.keytab

# Test readability by service account
sudo -u wabuser klist -kte /var/lib/wallix/bastion/etc/krb5.keytab
```

**Step 2: List Keytab Entries**

```bash
# List all keytab entries with encryption types
klist -kte /var/lib/wallix/bastion/etc/krb5.keytab

# Expected output
Keytab name: FILE:/var/lib/wallix/bastion/etc/krb5.keytab
KVNO Timestamp           Principal
---- ------------------- ------------------------------------------------------
   3 01/31/2026 10:00:00 HTTP/bastion.corp.company.com@CORP.COMPANY.COM (aes256-cts-hmac-sha1-96)
   3 01/31/2026 10:00:00 HTTP/bastion.corp.company.com@CORP.COMPANY.COM (aes128-cts-hmac-sha1-96)

# If output shows wrong principal, missing entries, or no output, keytab is invalid
```

**Step 3: Check Key Version Number (KVNO)**

```bash
# Initialize Kerberos credentials
kinit administrator@CORP.COMPANY.COM

# Check current KVNO in Active Directory
kvno HTTP/bastion.corp.company.com@CORP.COMPANY.COM

# Expected output
HTTP/bastion.corp.company.com@CORP.COMPANY.COM: kvno = 3

# Compare with keytab KVNO (from step 2)
# If KVNO in keytab (3) differs from AD (e.g., 4), keytab is out of sync
```

**Step 4: Check Encryption Types**

```bash
# Query supported encryption types in AD (PowerShell on DC)
Get-ADUser svc_wallix_krb -Properties msDS-SupportedEncryptionTypes |
    Select-Object Name, msDS-SupportedEncryptionTypes

# Expected output
Name           msDS-SupportedEncryptionTypes
----           -----------------------------
svc_wallix_krb 24  # 24 = AES128 + AES256 (0x08 + 0x10)

# Decode encryption types:
# 1 = DES-CBC-CRC
# 2 = DES-CBC-MD5
# 4 = RC4-HMAC
# 8 = AES128-CTS-HMAC-SHA1-96
# 16 = AES256-CTS-HMAC-SHA1-96
```

**Step 5: Test Keytab Authentication**

```bash
# Clear existing credentials
kdestroy -A

# Test keytab authentication
kinit -kt /var/lib/wallix/bastion/etc/krb5.keytab HTTP/bastion.corp.company.com@CORP.COMPANY.COM

# If successful, verify ticket
klist

# Expected output
Ticket cache: FILE:/tmp/krb5cc_1000
Default principal: HTTP/bastion.corp.company.com@CORP.COMPANY.COM

Valid starting       Expires              Service principal
01/31/2026 10:30:00  01/31/2026 20:30:00  krbtgt/CORP.COMPANY.COM@CORP.COMPANY.COM
        renew until 02/07/2026 10:30:00
```

#### Resolution

**Common Issue 1: KVNO Mismatch**

The password was changed or service account was recreated, invalidating the keytab.

```bash
# Solution: Regenerate keytab with current KVNO

# Step 1: Check current KVNO (as administrator)
kinit administrator@CORP.COMPANY.COM
kvno HTTP/bastion.corp.company.com@CORP.COMPANY.COM
# Output: HTTP/bastion.corp.company.com@CORP.COMPANY.COM: kvno = 4

# Step 2: Regenerate keytab on Domain Controller
# Run as Administrator on DC

# Remove old keytab (if doing fresh generation)
setspn -D HTTP/bastion.corp.company.com svc_wallix_krb
setspn -S HTTP/bastion.corp.company.com svc_wallix_krb

# Generate new keytab with correct KVNO
ktpass -out C:\Temp\wallix_new.keytab ^
       -princ HTTP/bastion.corp.company.com@CORP.COMPANY.COM ^
       -mapuser CORP\svc_wallix_krb ^
       -pass "CurrentP@ssw0rd!123" ^
       -kvno 4 ^
       -ptype KRB5_NT_PRINCIPAL ^
       -crypto AES256-SHA1

# Step 3: Transfer to WALLIX Bastion
scp C:\Temp\wallix_new.keytab wabuser@bastion:/tmp/

# Step 4: Install on WALLIX Bastion
sudo mv /var/lib/wallix/bastion/etc/krb5.keytab /var/lib/wallix/bastion/etc/krb5.keytab.old
sudo mv /tmp/wallix_new.keytab /var/lib/wallix/bastion/etc/krb5.keytab
sudo chown wabuser:wabgroup /var/lib/wallix/bastion/etc/krb5.keytab
sudo chmod 600 /var/lib/wallix/bastion/etc/krb5.keytab

# Step 5: Verify
klist -kte /var/lib/wallix/bastion/etc/krb5.keytab
kinit -kt /var/lib/wallix/bastion/etc/krb5.keytab HTTP/bastion.corp.company.com@CORP.COMPANY.COM
```

**Common Issue 2: Wrong Encryption Type**

Keytab uses RC4 but AD requires AES.

```bash
# Solution: Regenerate with correct encryption type

# On Domain Controller (PowerShell)
# Set allowed encryption types
Set-ADUser svc_wallix_krb -KerberosEncryptionType AES128,AES256

# Generate keytab with AES256
ktpass -out C:\Temp\wallix_aes.keytab ^
       -princ HTTP/bastion.corp.company.com@CORP.COMPANY.COM ^
       -mapuser CORP\svc_wallix_krb ^
       -pass "CurrentP@ssw0rd!123" ^
       -ptype KRB5_NT_PRINCIPAL ^
       -crypto AES256-SHA1

# For maximum compatibility, add AES128 as well
ktpass -out C:\Temp\wallix_aes.keytab ^
       -princ HTTP/bastion.corp.company.com@CORP.COMPANY.COM ^
       -mapuser CORP\svc_wallix_krb ^
       -pass "CurrentP@ssw0rd!123" ^
       -ptype KRB5_NT_PRINCIPAL ^
       -crypto AES128-SHA1 ^
       -in C:\Temp\wallix_aes.keytab

# Transfer and install (same as above)
```

**Common Issue 3: Wrong Principal Name**

SPN in keytab doesn't match registered SPN.

```bash
# Diagnosis
# Check registered SPN (PowerShell on DC)
setspn -L svc_wallix_krb

# Check keytab principal
klist -kte /var/lib/wallix/bastion/etc/krb5.keytab

# If mismatch (e.g., keytab has HTTP/bastion but should be HTTP/bastion.corp.company.com)

# Solution: Regenerate with correct principal
ktpass -out C:\Temp\wallix_correct.keytab ^
       -princ HTTP/bastion.corp.company.com@CORP.COMPANY.COM ^
       -mapuser CORP\svc_wallix_krb ^
       -pass "CurrentP@ssw0rd!123" ^
       -ptype KRB5_NT_PRINCIPAL ^
       -crypto AES256-SHA1
```

**Common Issue 4: Permission Problems**

Keytab exists but service cannot read it.

```bash
# Solution: Fix permissions and ownership

# Set correct ownership
sudo chown wabuser:wabgroup /var/lib/wallix/bastion/etc/krb5.keytab

# Set restrictive permissions (owner read-only)
sudo chmod 600 /var/lib/wallix/bastion/etc/krb5.keytab

# Verify service can read
sudo -u wabuser klist -kte /var/lib/wallix/bastion/etc/krb5.keytab

# Check SELinux context (if using SELinux)
ls -Z /var/lib/wallix/bastion/etc/krb5.keytab
# Should show: unconfined_u:object_r:krb5_keytab_t:s0

# If wrong context, fix it
sudo restorecon -v /var/lib/wallix/bastion/etc/krb5.keytab
```

#### Verification Steps

```bash
# 1. Verify keytab integrity
klist -kte /var/lib/wallix/bastion/etc/krb5.keytab

# 2. Test keytab authentication
kdestroy -A
kinit -kt /var/lib/wallix/bastion/etc/krb5.keytab HTTP/bastion.corp.company.com@CORP.COMPANY.COM
klist

# 3. Verify KVNO matches AD
kvno HTTP/bastion.corp.company.com@CORP.COMPANY.COM
# Compare with KVNO in keytab output

# 4. Restart WALLIX and test
systemctl restart wallix-bastion
curl -I --negotiate -u : https://bastion.corp.company.com/
# Should return 200 OK or 302 redirect (not 401 with WWW-Authenticate: Negotiate)

# 5. Check WALLIX logs
tail -f /var/log/wallix/bastion/auth.log | grep -i keytab
```

---

### Issue 3: SPNEGO Negotiation Failure

#### Symptoms

Browser shows basic authentication prompt instead of Kerberos SSO:
- HTTP 401 Unauthorized with username/password form
- Browser never sends "Authorization: Negotiate" header
- Users have valid TGT but cannot SSO to WALLIX web interface
- Works with explicit credentials but not with Kerberos

Browser developer tools show:
```
HTTP/1.1 401 Unauthorized
WWW-Authenticate: Negotiate
```

But no automatic negotiation occurs.

#### Diagnosis

**Step 1: Verify User Has Valid TGT**

```bash
# On user's workstation
klist

# Expected output (user must have TGT)
Ticket cache: FILE:/tmp/krb5cc_1000
Default principal: jsmith@CORP.COMPANY.COM

Valid starting       Expires              Service principal
01/31/2026 10:00:00  01/31/2026 20:00:00  krbtgt/CORP.COMPANY.COM@CORP.COMPANY.COM
        renew until 02/07/2026 10:00:00

# If no TGT, user must authenticate
kinit jsmith@CORP.COMPANY.COM
```

**Step 2: Check Browser Configuration**

```bash
# Chrome/Chromium (Linux) - Check policy
cat /etc/opt/chrome/policies/managed/kerberos.json

# Expected content
{
  "AuthServerAllowlist": "*.corp.company.com,bastion.corp.company.com",
  "AuthNegotiateDelegateAllowlist": "bastion.corp.company.com"
}

# Firefox - Check about:config settings
# Open Firefox, type: about:config
# Search for: network.negotiate-auth.trusted-uris
# Should contain: .corp.company.com,bastion.corp.company.com

# Windows Chrome - Check registry
reg query "HKLM\SOFTWARE\Policies\Google\Chrome" /v AuthServerAllowlist
# Should return: *.corp.company.com
```

**Step 3: Verify SPN Registration**

```powershell
# On Domain Controller
# Check SPN is registered correctly
setspn -Q HTTP/bastion.corp.company.com

# Expected output
Checking domain DC=corp,DC=company,DC=com
HTTP/bastion.corp.company.com
        CN=svc_wallix_krb,OU=Service Accounts,OU=IT,DC=corp,DC=company,DC=com

Existing SPN found!

# Check for duplicate SPNs (critical)
setspn -X -F

# Should show no duplicates for HTTP/bastion.corp.company.com
# If duplicates exist, authentication will fail
```

**Step 4: Test Service Ticket Acquisition**

```bash
# On user workstation with valid TGT
kvno HTTP/bastion.corp.company.com@CORP.COMPANY.COM

# Expected output
HTTP/bastion.corp.company.com@CORP.COMPANY.COM: kvno = 3

# If this fails with "Server not found", SPN is not registered or DNS is wrong
# If this succeeds, verify ticket was cached
klist | grep HTTP/bastion
```

**Step 5: Check DNS Resolution**

```bash
# Browser uses FQDN for Kerberos
# Verify DNS resolves correctly
nslookup bastion.corp.company.com

# Expected output
Server:         192.168.1.10
Address:        192.168.1.10#53

Name:   bastion.corp.company.com
Address: 192.168.1.50

# Reverse lookup must also work
nslookup 192.168.1.50

# Expected output
50.1.168.192.in-addr.arpa       name = bastion.corp.company.com.

# If reverse lookup fails or returns wrong name, browsers may reject Kerberos
```

**Step 6: Test with curl**

```bash
# Test Kerberos negotiation with curl
curl -I --negotiate -u : https://bastion.corp.company.com/

# Expected output
HTTP/1.1 200 OK
WWW-Authenticate: Negotiate YIIFtQYGKwYBBQUCoIIFqTCCBaWgMDAu...
Set-Cookie: wallix_session=...

# If returns 401, negotiation failed
# If returns 302 redirect to /login, negotiation succeeded
```

#### Resolution

**Issue 1: Browser Not Configured for Negotiate**

```bash
# Google Chrome (Linux)
sudo mkdir -p /etc/opt/chrome/policies/managed

cat > /etc/opt/chrome/policies/managed/kerberos.json << 'EOF'
{
  "AuthServerAllowlist": "*.corp.company.com,bastion.corp.company.com",
  "AuthNegotiateDelegateAllowlist": "bastion.corp.company.com",
  "DisableAuthNegotiateCnameLookup": false,
  "EnableAuthNegotiatePort": false
}
EOF

# Firefox
# Create policy file
sudo mkdir -p /etc/firefox/policies

cat > /etc/firefox/policies/policies.json << 'EOF'
{
  "policies": {
    "Authentication": {
      "SPNEGO": [
        "https://bastion.corp.company.com",
        "https://*.corp.company.com"
      ],
      "Delegated": ["https://bastion.corp.company.com"],
      "AllowNonFQDN": {
        "SPNEGO": false
      }
    }
  }
}
EOF

# Windows Chrome - Use Group Policy or registry
# Run as Administrator in PowerShell
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Google\Chrome" `
    -Name "AuthServerAllowlist" `
    -Value "*.corp.company.com" `
    -PropertyType String -Force

New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Google\Chrome" `
    -Name "AuthNegotiateDelegateAllowlist" `
    -Value "bastion.corp.company.com" `
    -PropertyType String -Force

# Restart browser after configuration
```

**Issue 2: SPN Not Registered or Duplicate SPN**

```powershell
# On Domain Controller

# Remove any duplicate SPNs first
setspn -D HTTP/bastion.corp.company.com old_account
setspn -D HTTP/bastion.corp.company.com computer_account

# Register SPN correctly
setspn -S HTTP/bastion.corp.company.com svc_wallix_krb

# Verify no duplicates
setspn -Q HTTP/bastion.corp.company.com

# Should show only one match (svc_wallix_krb)
```

**Issue 3: DNS Resolution Problem**

```bash
# Add entry to /etc/hosts as temporary workaround
echo "192.168.1.50  bastion.corp.company.com bastion" | sudo tee -a /etc/hosts

# Permanent fix: Add/fix DNS records in DNS server
# Add A record: bastion.corp.company.com -> 192.168.1.50
# Add PTR record: 192.168.1.50 -> bastion.corp.company.com

# On Windows DNS Server (PowerShell)
Add-DnsServerResourceRecordA -Name "bastion" -ZoneName "corp.company.com" -IPv4Address "192.168.1.50"
Add-DnsServerResourceRecordPtr -Name "50" -ZoneName "1.168.192.in-addr.arpa" -PtrDomainName "bastion.corp.company.com"
```

**Issue 4: Apache/Web Server Not Configured**

```bash
# Verify mod_auth_gssapi is loaded
apache2ctl -M | grep gssapi
# Expected output: auth_gssapi_module (shared)

# If not loaded, enable it
sudo a2enmod auth_gssapi
sudo systemctl restart apache2

# Check Apache configuration
cat /etc/apache2/sites-enabled/wallix-kerberos.conf

# Should contain:
<Location "/api">
    AuthType GSSAPI
    AuthName "WALLIX Bastion Kerberos"
    GssapiCredStore keytab:/var/lib/wallix/bastion/etc/krb5.keytab
    GssapiAllowedMech krb5
    GssapiNegotiateOnce On
    GssapiUseSessions On
    Require valid-user
</Location>

# If configuration missing or wrong, fix and restart
sudo systemctl restart apache2
```

**Issue 5: Service Ticket Cannot Be Obtained**

```bash
# Test service ticket acquisition
kinit jsmith@CORP.COMPANY.COM
kvno HTTP/bastion.corp.company.com@CORP.COMPANY.COM

# If fails with "Server not found", check:
# 1. SPN registration (setspn -L svc_wallix_krb)
# 2. Service account exists and is enabled
# 3. Keytab has correct principal

# Verify on DC
Get-ADUser svc_wallix_krb -Properties Enabled, servicePrincipalName |
    Select-Object Name, Enabled, servicePrincipalName
```

#### Verification Steps

```bash
# 1. Verify user has TGT
klist

# 2. Test service ticket acquisition
kvno HTTP/bastion.corp.company.com@CORP.COMPANY.COM

# 3. Check service ticket is cached
klist | grep "HTTP/bastion"

# 4. Test with curl
curl -I --negotiate -u : https://bastion.corp.company.com/
# Should return 200 or 302 (not 401)

# 5. Test in browser
# Open: https://bastion.corp.company.com/
# Should automatically log in without password prompt

# 6. Check browser developer tools (F12)
# Network tab -> Click on bastion.corp.company.com request
# Request Headers should show:
#   Authorization: Negotiate YIIFtQYGKwYBBQUC...
# Response Headers should show:
#   WWW-Authenticate: Negotiate YIIFqTCCBaWgMDAu...

# 7. Verify in WALLIX logs
tail -f /var/log/wallix/bastion/auth.log | grep -i spnego
# Should show successful SPNEGO authentication
```

---

### Issue 4: Cross-Realm Trust Failures

#### Symptoms

Users from trusted realm cannot authenticate:

```
kinit: Cannot find KDC for realm "DMZ.COMPANY.COM" while getting initial credentials
```

```
kinit: Realm not local to KDC while getting initial credentials
```

```
Server not found in Kerberos database
```

- Users from primary realm (CORP.COMPANY.COM) can authenticate
- Users from trusted realm (DMZ.COMPANY.COM) receive authentication errors
- Cross-realm TGT cannot be obtained

#### Diagnosis

**Step 1: Verify Trust Relationship Exists**

```powershell
# On Domain Controller (CORP.COMPANY.COM)
Get-ADTrust -Filter *

# Expected output
Direction               : Bidirectional
DisallowTransivity      : False
DistinguishedName       : CN=DMZ.COMPANY.COM,CN=System,DC=corp,DC=company,DC=com
ForestTransitive        : True
IntraForest             : False
IsTreeParent            : False
IsTreeRoot              : False
Name                    : DMZ.COMPANY.COM
ObjectClass             : trustedDomain
SelectiveAuthentication : False
SIDFilteringForestAware : False
Source                  : DC=corp,DC=company,DC=com
Target                  : DMZ.COMPANY.COM
TrustingPolicy         :

# Check trust status
Test-ADTrust -Identity "DMZ.COMPANY.COM"

# Expected output
True  # If trust is healthy
```

**Step 2: Check krb5.conf Configuration**

```bash
# Verify both realms are defined
grep -A10 "^\[realms\]" /etc/krb5.conf

# Expected output (both realms present)
[realms]
    CORP.COMPANY.COM = {
        kdc = dc01.corp.company.com:88
        kdc = dc02.corp.company.com:88
        admin_server = dc01.corp.company.com:749
    }

    DMZ.COMPANY.COM = {
        kdc = dmzdc01.dmz.company.com:88
        admin_server = dmzdc01.dmz.company.com:749
    }

# Check capaths section (trust paths)
grep -A10 "^\[capaths\]" /etc/krb5.conf

# Expected output
[capaths]
    CORP.COMPANY.COM = {
        DMZ.COMPANY.COM = .
    }
    DMZ.COMPANY.COM = {
        CORP.COMPANY.COM = .
    }
```

**Step 3: Test DNS Resolution for Trusted Realm**

```bash
# Resolve KDC for trusted realm
nslookup dmzdc01.dmz.company.com

# Expected output
Server:         192.168.1.10
Address:        192.168.1.10#53

Name:   dmzdc01.dmz.company.com
Address: 192.168.2.10

# Check SRV records for Kerberos
nslookup -type=SRV _kerberos._tcp.dmz.company.com

# Expected output
_kerberos._tcp.dmz.company.com   SRV record:
        Priority = 0
        Weight = 100
        Port = 88
        Target = dmzdc01.dmz.company.com
```

**Step 4: Test Connectivity to Trusted Realm KDC**

```bash
# Test TCP connectivity to trusted KDC
nc -zv dmzdc01.dmz.company.com 88

# Expected output
Connection to dmzdc01.dmz.company.com 88 port [tcp/kerberos] succeeded!

# Test UDP (Kerberos uses both)
nc -zuv dmzdc01.dmz.company.com 88

# Capture Kerberos traffic
tcpdump -i any -w /tmp/cross-realm.pcap 'port 88'
# Then attempt authentication from trusted realm user
```

**Step 5: Test Cross-Realm TGT Acquisition**

```bash
# Authenticate as user from trusted realm
kinit vendor@DMZ.COMPANY.COM

# Enter password
Password for vendor@DMZ.COMPANY.COM:

# Check tickets
klist

# Expected output (should show TGT for DMZ.COMPANY.COM)
Ticket cache: FILE:/tmp/krb5cc_1000
Default principal: vendor@DMZ.COMPANY.COM

Valid starting       Expires              Service principal
01/31/2026 10:00:00  01/31/2026 20:00:00  krbtgt/DMZ.COMPANY.COM@DMZ.COMPANY.COM

# Now try to get service ticket from CORP realm
kvno HTTP/bastion.corp.company.com@CORP.COMPANY.COM

# Expected output (cross-realm ticket should be obtained)
HTTP/bastion.corp.company.com@CORP.COMPANY.COM: kvno = 3

# Check for cross-realm TGT
klist | grep krbtgt

# Expected output (two krbtgt tickets)
krbtgt/DMZ.COMPANY.COM@DMZ.COMPANY.COM
krbtgt/CORP.COMPANY.COM@DMZ.COMPANY.COM    # Cross-realm TGT
```

#### Resolution

**Issue 1: Trust Not Configured or Broken**

```powershell
# On CORP.COMPANY.COM Domain Controller

# Verify trust exists
Get-ADTrust -Filter * | Where-Object {$_.Target -eq "DMZ.COMPANY.COM"}

# If trust doesn't exist, create it
New-ADTrust -Name "DMZ.COMPANY.COM" `
    -Direction Bidirectional `
    -TrustPassword (ConvertTo-SecureString "TrustP@ssw0rd!Complex" -AsPlainText -Force) `
    -TrustType External `
    -SourceName "CORP.COMPANY.COM" `
    -TargetName "DMZ.COMPANY.COM"

# If trust exists but is broken, repair it
Test-ADTrust -Identity "DMZ.COMPANY.COM"
# If returns False, reset trust

Reset-ADTrust -Identity "DMZ.COMPANY.COM" `
    -Password (ConvertTo-SecureString "TrustP@ssw0rd!Complex" -AsPlainText -Force)

# Verify trust is working
Test-ADTrust -Identity "DMZ.COMPANY.COM"
# Should return True
```

**Issue 2: Missing capaths Configuration**

```bash
# Add capaths section to /etc/krb5.conf
cat >> /etc/krb5.conf << 'EOF'

[capaths]
    CORP.COMPANY.COM = {
        DMZ.COMPANY.COM = .
    }
    DMZ.COMPANY.COM = {
        CORP.COMPANY.COM = .
    }
EOF

# For complex trust paths (multi-hop), specify intermediate realms
# Example: CORP -> INTERMEDIATE -> DMZ
[capaths]
    CORP.COMPANY.COM = {
        DMZ.COMPANY.COM = INTERMEDIATE.COMPANY.COM
        INTERMEDIATE.COMPANY.COM = .
    }
    DMZ.COMPANY.COM = {
        CORP.COMPANY.COM = INTERMEDIATE.COMPANY.COM
        INTERMEDIATE.COMPANY.COM = .
    }
```

**Issue 3: DNS Not Resolving Trusted Realm**

```bash
# Temporary fix: Add to /etc/hosts
cat >> /etc/hosts << 'EOF'
192.168.2.10    dmzdc01.dmz.company.com dmzdc01
192.168.2.11    dmzdc02.dmz.company.com dmzdc02
EOF

# Permanent fix: Add conditional forwarder in DNS
# On CORP DNS server (PowerShell)
Add-DnsServerConditionalForwarderZone -Name "dmz.company.com" `
    -MasterServers 192.168.2.10,192.168.2.11 `
    -ReplicationScope "Forest"

# Verify DNS forwarding works
nslookup dmzdc01.dmz.company.com

# On DMZ DNS server, add reverse forwarder for CORP
Add-DnsServerConditionalForwarderZone -Name "corp.company.com" `
    -MasterServers 192.168.1.10,192.168.1.11 `
    -ReplicationScope "Forest"
```

**Issue 4: Firewall Blocking Cross-Realm Traffic**

```bash
# Test connectivity from WALLIX to DMZ KDC
nc -zv dmzdc01.dmz.company.com 88
nc -zv dmzdc01.dmz.company.com 464

# If connection fails, firewall rules needed

# On WALLIX Bastion (if using iptables)
sudo iptables -A OUTPUT -p tcp -d 192.168.2.0/24 --dport 88 -j ACCEPT
sudo iptables -A OUTPUT -p udp -d 192.168.2.0/24 --dport 88 -j ACCEPT
sudo iptables -A OUTPUT -p tcp -d 192.168.2.0/24 --dport 464 -j ACCEPT

# On firewall between networks, allow:
# WALLIX (192.168.1.50) -> DMZ DCs (192.168.2.10,192.168.2.11)
# Ports: 88/tcp, 88/udp, 464/tcp, 389/tcp, 636/tcp
```

**Issue 5: WALLIX Not Configured for Multiple Realms**

```json
# Configure WALLIX to accept multiple realms
# /var/lib/wallix/bastion/etc/wabengine.conf (or via Web UI)

{
  "kerberos_multi_realm": {
    "primary_realm": "CORP.COMPANY.COM",
    "trusted_realms": [
      {
        "realm": "DMZ.COMPANY.COM",
        "trust_type": "bidirectional",
        "kdc_servers": ["dmzdc01.dmz.company.com", "dmzdc02.dmz.company.com"],
        "user_mapping": {
          "domain_prefix": "DMZ",
          "auto_create": false,
          "default_profile": "vendor-user"
        }
      }
    ],
    "realm_routing": {
      "@corp.company.com": "CORP.COMPANY.COM",
      "@dmz.company.com": "DMZ.COMPANY.COM"
    }
  }
}

# Restart WALLIX after configuration
systemctl restart wallix-bastion
```

#### Verification Steps

```bash
# 1. Test trust from both sides
# On CORP DC
Test-ADTrust -Identity "DMZ.COMPANY.COM"

# On DMZ DC
Test-ADTrust -Identity "CORP.COMPANY.COM"

# Both should return True

# 2. Test user authentication from trusted realm
kinit vendor@DMZ.COMPANY.COM
klist
# Should show TGT for DMZ.COMPANY.COM

# 3. Test cross-realm service ticket
kvno HTTP/bastion.corp.company.com@CORP.COMPANY.COM
klist | grep krbtgt
# Should show cross-realm TGT: krbtgt/CORP.COMPANY.COM@DMZ.COMPANY.COM

# 4. Test WALLIX web login
# Browse to: https://bastion.corp.company.com/
# As user: vendor@DMZ.COMPANY.COM
# Should successfully authenticate

# 5. Check WALLIX authentication logs
tail -f /var/log/wallix/bastion/auth.log | grep -i "DMZ\|vendor"

# 6. Verify user can access resources
# Try to initiate a session to a target server
# Should work with cross-realm Kerberos delegation
```

---

## References

- [MIT Kerberos Documentation](https://web.mit.edu/kerberos/krb5-latest/doc/)
- [Microsoft Kerberos Protocol Documentation](https://docs.microsoft.com/en-us/windows/win32/secauthn/microsoft-kerberos)
- [RFC 4120 - The Kerberos Network Authentication Service (V5)](https://datatracker.ietf.org/doc/html/rfc4120)
- [RFC 4559 - SPNEGO-based Kerberos and NTLM HTTP Authentication](https://datatracker.ietf.org/doc/html/rfc4559)
- [WALLIX Documentation Portal](https://pam.wallix.one/documentation)
- [WALLIX Administration Guide](https://pam.wallix.one/documentation/admin-doc/bastion_en_administration_guide.pdf)

---

## See Also

**Related Sections:**
- [06 - Authentication](../06-authentication/README.md) - Authentication methods overview
- [34 - LDAP/AD Integration](../34-ldap-ad-integration/README.md) - Active Directory setup

**Official Resources:**
- [WALLIX Documentation](https://pam.wallix.one/documentation)

---

## Next Steps

Continue to [05 - Authentication](../06-authentication/README.md) for an overview of all authentication methods, or see [34 - JIT Access](../25-jit-access/README.md) for just-in-time access workflows that can integrate with Kerberos SSO.
