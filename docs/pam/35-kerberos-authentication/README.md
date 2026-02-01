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

## References

- [MIT Kerberos Documentation](https://web.mit.edu/kerberos/krb5-latest/doc/)
- [Microsoft Kerberos Protocol Documentation](https://docs.microsoft.com/en-us/windows/win32/secauthn/microsoft-kerberos)
- [RFC 4120 - The Kerberos Network Authentication Service (V5)](https://datatracker.ietf.org/doc/html/rfc4120)
- [RFC 4559 - SPNEGO-based Kerberos and NTLM HTTP Authentication](https://datatracker.ietf.org/doc/html/rfc4559)
- [WALLIX Documentation Portal](https://pam.wallix.one/documentation)
- [WALLIX Administration Guide](https://pam.wallix.one/documentation/admin-doc/bastion_en_administration_guide.pdf)

---

## Next Steps

Continue to [05 - Authentication](../06-authentication/README.md) for an overview of all authentication methods, or see [34 - JIT Access](../25-jit-access/README.md) for just-in-time access workflows that can integrate with Kerberos SSO.
