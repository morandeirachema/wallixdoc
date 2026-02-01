# Certificate Management

This section provides comprehensive guidance for managing certificates in WALLIX Bastion deployments, covering TLS, SSH, and client certificates.

---

## Table of Contents

1. [Certificate Overview](#certificate-overview)
2. [Certificate Architecture](#certificate-architecture)
3. [CSR Generation](#csr-generation)
4. [CA-Signed Certificate Installation](#ca-signed-certificate-installation)
5. [Self-Signed Certificate Creation](#self-signed-certificate-creation)
6. [Certificate Chain Configuration](#certificate-chain-configuration)
7. [Certificate Renewal Procedures](#certificate-renewal-procedures)
8. [Let's Encrypt/ACME Integration](#lets-encryptacme-integration)
9. [Client Certificate Authentication](#client-certificate-authentication)
10. [SSH Host Key Management](#ssh-host-key-management)
11. [Certificate Monitoring and Alerting](#certificate-monitoring-and-alerting)
12. [Troubleshooting](#troubleshooting)
13. [Certificate Storage Security](#certificate-storage-security)

---

## Certificate Overview

### Certificate Types in WALLIX Bastion

WALLIX Bastion uses multiple certificate types for secure communications:

```
+==============================================================================+
|                    CERTIFICATE TYPES OVERVIEW                                 |
+==============================================================================+

  TLS/SSL CERTIFICATES
  ====================

  +------------------------------------------------------------------------+
  | Certificate        | Purpose                    | Location              |
  +--------------------+----------------------------+-----------------------+
  | Web SSL            | HTTPS web interface        | /etc/wallix/ssl/      |
  | API TLS            | REST API encryption        | /etc/wallix/ssl/      |
  | LDAPS Client       | Secure LDAP connections    | /etc/wallix/ssl/      |
  | Syslog TLS         | Encrypted log forwarding   | /etc/wallix/ssl/      |
  | PostgreSQL         | Database encryption        | /var/lib/postgresql/  |
  | Inter-node TLS     | Cluster communication      | /etc/wallix/ssl/      |
  +--------------------+----------------------------+-----------------------+

  --------------------------------------------------------------------------

  SSH CERTIFICATES
  ================

  +------------------------------------------------------------------------+
  | Certificate        | Purpose                    | Location              |
  +--------------------+----------------------------+-----------------------+
  | SSH Host Keys      | Server identity            | /etc/ssh/             |
  | SSH Proxy Keys     | Session proxy identity     | /etc/wallix/ssh/      |
  | Target Auth Keys   | Automated authentication   | Stored in vault       |
  | User Auth Keys     | User SSH authentication    | User configuration    |
  +--------------------+----------------------------+-----------------------+

  --------------------------------------------------------------------------

  CLIENT CERTIFICATES
  ===================

  +------------------------------------------------------------------------+
  | Certificate        | Purpose                    | Location              |
  +--------------------+----------------------------+-----------------------+
  | User X.509         | Client authentication      | /etc/wallix/ssl/ca/   |
  | Smart Card/PIV     | Hardware token auth        | External device       |
  | API Client         | Service authentication     | /etc/wallix/ssl/      |
  +--------------------+----------------------------+-----------------------+

+==============================================================================+
```

### Certificate File Formats

| Format | Extension | Description | Use Case |
|--------|-----------|-------------|----------|
| PEM | .pem, .crt | Base64 encoded, text format | Most common, web servers |
| DER | .der, .cer | Binary format | Windows, Java applications |
| PKCS#12 | .p12, .pfx | Contains cert + private key | Import/export bundles |
| PKCS#7 | .p7b, .p7c | Certificate chain, no key | Chain distribution |

### Certificate Locations

```
+==============================================================================+
|                    CERTIFICATE FILE LOCATIONS                                 |
+==============================================================================+

  WALLIX BASTION CERTIFICATES
  ===========================

  /etc/wallix/ssl/
  +-- server.crt            # Primary web SSL certificate
  +-- server.key            # Private key (chmod 600)
  +-- ca-chain.crt          # Certificate authority chain
  +-- ldap-client.crt       # LDAP/AD client certificate
  +-- ldap-client.key       # LDAP client private key
  +-- syslog.crt            # Syslog TLS certificate
  +-- syslog.key            # Syslog TLS private key
  +-- api-client.crt        # API client certificate
  +-- api-client.key        # API client private key

  /etc/wallix/ssl/ca/
  +-- trusted-ca.crt        # Trusted CA certificates
  +-- client-auth-ca.crt    # CA for client authentication
  +-- crl/                  # Certificate revocation lists

  SSH KEYS
  ========

  /etc/ssh/
  +-- ssh_host_rsa_key      # RSA host key (4096-bit recommended)
  +-- ssh_host_rsa_key.pub  # RSA public key
  +-- ssh_host_ed25519_key  # Ed25519 host key
  +-- ssh_host_ed25519_key.pub

  /etc/wallix/ssh/
  +-- proxy_rsa_key         # SSH proxy RSA key
  +-- proxy_ed25519_key     # SSH proxy Ed25519 key

  POSTGRESQL SSL
  ==============

  /var/lib/postgresql/15/main/
  +-- server.crt            # PostgreSQL server certificate
  +-- server.key            # PostgreSQL server key
  +-- root.crt              # CA certificate for client verification

+==============================================================================+
```

---

## Certificate Architecture

### Certificate Trust Flow

```
+==============================================================================+
|                    CERTIFICATE TRUST ARCHITECTURE                             |
+==============================================================================+

                           +-------------------+
                           |   ROOT CA         |
                           |   (Offline)       |
                           +--------+----------+
                                    |
                    +---------------+---------------+
                    |                               |
           +--------+--------+             +--------+--------+
           | INTERMEDIATE CA |             | INTERMEDIATE CA |
           |   (Online)      |             |   (Issuing)     |
           +--------+--------+             +--------+--------+
                    |                               |
        +-----------+-----------+                   |
        |           |           |                   |
   +----+----+ +----+----+ +----+----+        +----+----+
   | WALLIX  | | WALLIX  | | WALLIX  |        | Client  |
   | Web SSL | | API TLS | | Syslog  |        | Certs   |
   +---------+ +---------+ +---------+        +---------+

  --------------------------------------------------------------------------

  TRUST VERIFICATION PROCESS
  ==========================

  +------------------------------------------------------------------------+
  |                                                                         |
  |   Client                WALLIX Bastion              Target Server      |
  |     |                        |                           |             |
  |     | 1. Connect (HTTPS)     |                           |             |
  |     |----------------------->|                           |             |
  |     |                        |                           |             |
  |     | 2. Server Certificate  |                           |             |
  |     |<-----------------------|                           |             |
  |     |                        |                           |             |
  |     | 3. Verify Chain:       |                           |             |
  |     |    - Server cert       |                           |             |
  |     |    - Intermediate CA   |                           |             |
  |     |    - Root CA           |                           |             |
  |     |                        |                           |             |
  |     | 4. Validated Session   |                           |             |
  |     |<======================>|                           |             |
  |     |                        |                           |             |
  |     |                        | 5. Connect to Target      |             |
  |     |                        |-------------------------->|             |
  |     |                        |                           |             |
  |     |                        | 6. Verify Target Cert     |             |
  |     |                        |<--------------------------|             |
  |     |                        |                           |             |
  |                                                                         |
  +------------------------------------------------------------------------+

+==============================================================================+
```

### Multi-Site Certificate Architecture

```
+==============================================================================+
|                    MULTI-SITE CERTIFICATE DEPLOYMENT                          |
+==============================================================================+

  +------------------------------------------------------------------------+
  |                         ENTERPRISE PKI                                  |
  |                                                                         |
  |                    +-------------------+                                |
  |                    |   ENTERPRISE      |                                |
  |                    |   ROOT CA         |                                |
  |                    +--------+----------+                                |
  |                             |                                           |
  |          +------------------+------------------+                        |
  |          |                                     |                        |
  |  +-------+-------+                    +--------+--------+               |
  |  | ISSUING CA    |                    | ISSUING CA      |               |
  |  | (Site A)      |                    | (Site B)        |               |
  |  +-------+-------+                    +--------+--------+               |
  |          |                                     |                        |
  +------------------------------------------------------------------------+
             |                                     |
  +----------+-----------+              +----------+-----------+
  |      SITE A          |              |      SITE B          |
  |  (Primary HQ)        |              |  (Secondary Plant)   |
  |                      |              |                      |
  | +------------------+ |              | +------------------+ |
  | | WALLIX Primary   | |              | | WALLIX Secondary | |
  | |                  | |              | |                  | |
  | | - server.crt     | |              | | - server.crt     | |
  | | - ca-chain.crt   | |              | | - ca-chain.crt   | |
  | | - cluster.crt    | |              | | - cluster.crt    | |
  | +------------------+ |              | +------------------+ |
  |                      |              |                      |
  +----------------------+              +----------------------+

  CERTIFICATE REQUIREMENTS PER SITE
  =================================

  +------------------------------------------------------------------------+
  | Site     | Certificates Required                                       |
  +----------+-------------------------------------------------------------+
  | Primary  | Web SSL, API TLS, LDAPS, Syslog TLS, PostgreSQL, Cluster   |
  | Second.  | Web SSL, API TLS, LDAPS, Syslog TLS, PostgreSQL, Cluster   |
  | Remote   | Web SSL, API TLS (optional offline CA for air-gapped)      |
  +----------+-------------------------------------------------------------+

+==============================================================================+
```

---

## CSR Generation

### Generate Certificate Signing Request

**Step 1: Create Private Key**

```bash
# Generate RSA 4096-bit private key
openssl genrsa -out /etc/wallix/ssl/server.key 4096

# Set secure permissions
chmod 600 /etc/wallix/ssl/server.key
chown wallix:wallix /etc/wallix/ssl/server.key

# Verify key
openssl rsa -in /etc/wallix/ssl/server.key -check -noout

# Expected output:
# RSA key ok
```

**Step 2: Create CSR Configuration File**

```bash
# Create CSR configuration
cat > /tmp/csr.conf << 'EOF'
[req]
default_bits = 4096
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn

[dn]
C = US
ST = California
L = San Francisco
O = Company Name
OU = IT Security
CN = bastion.company.com

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = bastion.company.com
DNS.2 = wallix.company.com
DNS.3 = pam.company.com
IP.1 = 10.100.1.10
IP.2 = 10.100.1.11
EOF
```

**Step 3: Generate CSR**

```bash
# Generate CSR using configuration
openssl req -new \
    -key /etc/wallix/ssl/server.key \
    -out /tmp/server.csr \
    -config /tmp/csr.conf

# Verify CSR
openssl req -in /tmp/server.csr -text -noout

# Expected output:
# Certificate Request:
#     Data:
#         Version: 1 (0x0)
#         Subject: C = US, ST = California, L = San Francisco, O = Company Name, OU = IT Security, CN = bastion.company.com
#         Subject Public Key Info:
#             Public Key Algorithm: rsaEncryption
#                 RSA Public-Key: (4096 bit)
#         Attributes:
#         Requested Extensions:
#             X509v3 Subject Alternative Name:
#                 DNS:bastion.company.com, DNS:wallix.company.com, DNS:pam.company.com, IP Address:10.100.1.10, IP Address:10.100.1.11
```

**Step 4: Submit CSR to Certificate Authority**

```bash
# Display CSR for submission
cat /tmp/server.csr

# The CSR should look like:
# -----BEGIN CERTIFICATE REQUEST-----
# MIIEwDCCAqgCAQAwgZoxCzAJBgNVBAYTAlVTMRMwEQYDVQQIDApDYWxpZm9ybmlh
# ... (base64 encoded content)
# -----END CERTIFICATE REQUEST-----

# Copy this content and submit to your CA
# - Internal CA: Submit via CA web portal
# - External CA: Submit via vendor portal (DigiCert, GlobalSign, etc.)
```

### CSR for Different Certificate Types

**LDAPS Client Certificate CSR**

```bash
# Generate key
openssl genrsa -out /etc/wallix/ssl/ldap-client.key 4096
chmod 600 /etc/wallix/ssl/ldap-client.key

# Generate CSR
openssl req -new \
    -key /etc/wallix/ssl/ldap-client.key \
    -out /tmp/ldap-client.csr \
    -subj "/C=US/ST=California/O=Company/CN=wallix-ldap-client"
```

**Syslog TLS Certificate CSR**

```bash
# Generate key
openssl genrsa -out /etc/wallix/ssl/syslog.key 4096
chmod 600 /etc/wallix/ssl/syslog.key

# Generate CSR with client auth extension
cat > /tmp/syslog-csr.conf << 'EOF'
[req]
default_bits = 4096
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn

[dn]
C = US
ST = California
O = Company Name
CN = wallix-syslog

[req_ext]
extendedKeyUsage = clientAuth, serverAuth
EOF

openssl req -new \
    -key /etc/wallix/ssl/syslog.key \
    -out /tmp/syslog.csr \
    -config /tmp/syslog-csr.conf
```

---

## CA-Signed Certificate Installation

### Pre-Installation Checklist

```
+==============================================================================+
|                    CERTIFICATE INSTALLATION CHECKLIST                         |
+==============================================================================+

  BEFORE INSTALLATION
  ===================

  [ ] Received signed certificate from CA
  [ ] Received intermediate CA certificate(s)
  [ ] Verified certificate matches CSR
  [ ] Scheduled maintenance window
  [ ] Notified users of potential brief outage
  [ ] Backed up current certificates
  [ ] Tested certificate chain validity

+==============================================================================+
```

### Step-by-Step Installation

**Step 1: Receive and Verify Certificate**

```bash
# Save received certificate
cat > /tmp/new-server.crt << 'EOF'
-----BEGIN CERTIFICATE-----
MIIFjTCCA3WgAwIBAgIQDHmpRLCMEbGO7c8xbNpKJDANBgkqhkiG9w0BAQsFADBe
... (certificate content from CA)
-----END CERTIFICATE-----
EOF

# Verify certificate details
openssl x509 -in /tmp/new-server.crt -text -noout | head -30

# Expected output:
# Certificate:
#     Data:
#         Version: 3 (0x2)
#         Serial Number: 0c:79:a9:44:b0:8c:11:b1:8e:ed:cf:31:6c:da:4a:24
#     Signature Algorithm: sha256WithRSAEncryption
#         Issuer: C = US, O = DigiCert Inc, CN = DigiCert TLS RSA SHA256 2020 CA1
#         Validity
#             Not Before: Jan 15 00:00:00 2026 GMT
#             Not After : Jan 15 23:59:59 2027 GMT
#         Subject: C = US, ST = California, L = San Francisco, O = Company Name, CN = bastion.company.com

# Verify certificate matches private key
openssl x509 -noout -modulus -in /tmp/new-server.crt | openssl md5
openssl rsa -noout -modulus -in /etc/wallix/ssl/server.key | openssl md5

# Both outputs should match:
# (stdin)= d41d8cd98f00b204e9800998ecf8427e
```

**Step 2: Prepare Certificate Chain**

```bash
# Save intermediate CA certificate
cat > /tmp/intermediate-ca.crt << 'EOF'
-----BEGIN CERTIFICATE-----
MIIEtjCCA56gAwIBAgIQDHmpRLCMEbGO7c8xbNpKJDANBgkqhkiG9w0BAQsFADBs
... (intermediate CA certificate)
-----END CERTIFICATE-----
EOF

# Create certificate chain (server cert + intermediate CA)
cat /tmp/new-server.crt /tmp/intermediate-ca.crt > /tmp/server-chain.crt

# Verify chain
openssl verify -CAfile /tmp/root-ca.crt /tmp/server-chain.crt

# Expected output:
# /tmp/server-chain.crt: OK
```

**Step 3: Backup Current Certificates**

```bash
# Create backup directory
BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p /etc/wallix/ssl/backup/${BACKUP_DATE}

# Backup current certificates
cp /etc/wallix/ssl/server.crt /etc/wallix/ssl/backup/${BACKUP_DATE}/
cp /etc/wallix/ssl/server.key /etc/wallix/ssl/backup/${BACKUP_DATE}/
cp /etc/wallix/ssl/ca-chain.crt /etc/wallix/ssl/backup/${BACKUP_DATE}/ 2>/dev/null || true

# Verify backup
ls -la /etc/wallix/ssl/backup/${BACKUP_DATE}/

# Expected output:
# -rw-r--r-- 1 root root 2048 Jan 15 10:30 server.crt
# -rw------- 1 root root 3272 Jan 15 10:30 server.key
# -rw-r--r-- 1 root root 4096 Jan 15 10:30 ca-chain.crt
```

**Step 4: Install New Certificate**

```bash
# Copy new certificate
cp /tmp/new-server.crt /etc/wallix/ssl/server.crt

# Copy CA chain
cp /tmp/intermediate-ca.crt /etc/wallix/ssl/ca-chain.crt

# Set permissions
chmod 644 /etc/wallix/ssl/server.crt
chmod 644 /etc/wallix/ssl/ca-chain.crt
chown wallix:wallix /etc/wallix/ssl/server.crt
chown wallix:wallix /etc/wallix/ssl/ca-chain.crt

# Verify file permissions
ls -la /etc/wallix/ssl/

# Expected output:
# -rw-r--r-- 1 wallix wallix 2048 Jan 15 10:35 server.crt
# -rw------- 1 wallix wallix 3272 Jan 15 10:30 server.key
# -rw-r--r-- 1 wallix wallix 4096 Jan 15 10:35 ca-chain.crt
```

**Step 5: Reload Services**

```bash
# Reload WALLIX Bastion
systemctl reload wallix-bastion

# If reload fails, restart service
systemctl restart wallix-bastion

# Verify service status
systemctl status wallix-bastion

# Expected output:
# wallix-bastion.service - WALLIX Bastion Service
#      Loaded: loaded (/etc/systemd/system/wallix-bastion.service; enabled)
#      Active: active (running) since Mon 2026-01-15 10:40:00 UTC
```

**Step 6: Verify Installation**

```bash
# Test HTTPS connection
curl -v https://localhost 2>&1 | grep -E "(subject|issuer|expire)"

# Expected output:
# *  subject: C=US; ST=California; L=San Francisco; O=Company Name; CN=bastion.company.com
# *  issuer: C=US; O=DigiCert Inc; CN=DigiCert TLS RSA SHA256 2020 CA1
# *  expire date: Jan 15 23:59:59 2027 GMT

# Check certificate from external client
echo | openssl s_client -connect bastion.company.com:443 2>/dev/null | \
    openssl x509 -noout -subject -dates

# Expected output:
# subject=C = US, ST = California, L = San Francisco, O = Company Name, CN = bastion.company.com
# notBefore=Jan 15 00:00:00 2026 GMT
# notAfter=Jan 15 23:59:59 2027 GMT

# Verify using wabadmin
wabadmin ssl-verify

# Expected output:
# Certificate: bastion.company.com
# Issuer: DigiCert TLS RSA SHA256 2020 CA1
# Valid From: 2026-01-15
# Valid To: 2027-01-15
# Key Size: 4096 bits
# Signature: SHA256withRSA
# Chain: Valid
# Status: OK
```

---

## Self-Signed Certificate Creation

### When to Use Self-Signed Certificates

| Scenario | Recommendation |
|----------|----------------|
| Development/Testing | Acceptable |
| Emergency (CA unavailable) | Temporary only |
| Air-gapped environments | Consider internal CA |
| Production | NOT recommended |

### Create Self-Signed Certificate

**Quick Self-Signed Certificate**

```bash
# Generate key and self-signed certificate in one command
openssl req -x509 -nodes -days 365 -newkey rsa:4096 \
    -keyout /etc/wallix/ssl/server.key \
    -out /etc/wallix/ssl/server.crt \
    -subj "/C=US/ST=California/O=Company/CN=bastion.company.com"

# Set permissions
chmod 600 /etc/wallix/ssl/server.key
chmod 644 /etc/wallix/ssl/server.crt
chown wallix:wallix /etc/wallix/ssl/server.*

# Verify certificate
openssl x509 -in /etc/wallix/ssl/server.crt -text -noout | head -20

# Expected output:
# Certificate:
#     Data:
#         Version: 3 (0x2)
#         Serial Number: ... (random)
#     Signature Algorithm: sha256WithRSAEncryption
#         Issuer: C = US, ST = California, O = Company, CN = bastion.company.com
#         Validity
#             Not Before: Jan 15 10:00:00 2026 GMT
#             Not After : Jan 15 10:00:00 2027 GMT
#         Subject: C = US, ST = California, O = Company, CN = bastion.company.com
```

**Self-Signed Certificate with SANs**

```bash
# Create configuration with SANs
cat > /tmp/self-signed.conf << 'EOF'
[req]
default_bits = 4096
prompt = no
default_md = sha256
x509_extensions = v3_req
distinguished_name = dn

[dn]
C = US
ST = California
L = San Francisco
O = Company Name
CN = bastion.company.com

[v3_req]
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names
basicConstraints = critical, CA:FALSE

[alt_names]
DNS.1 = bastion.company.com
DNS.2 = wallix.company.com
DNS.3 = localhost
IP.1 = 10.100.1.10
IP.2 = 127.0.0.1
EOF

# Generate certificate
openssl req -x509 -nodes -days 365 -newkey rsa:4096 \
    -keyout /etc/wallix/ssl/server.key \
    -out /etc/wallix/ssl/server.crt \
    -config /tmp/self-signed.conf

# Verify SANs
openssl x509 -in /etc/wallix/ssl/server.crt -text -noout | grep -A1 "Subject Alternative Name"

# Expected output:
# X509v3 Subject Alternative Name:
#     DNS:bastion.company.com, DNS:wallix.company.com, DNS:localhost, IP Address:10.100.1.10, IP Address:127.0.0.1
```

### Create Internal Certificate Authority

For air-gapped or isolated environments, create an internal CA:

```bash
# Create CA directory structure
mkdir -p /etc/wallix/ca/{certs,crl,newcerts,private}
chmod 700 /etc/wallix/ca/private
touch /etc/wallix/ca/index.txt
echo 1000 > /etc/wallix/ca/serial

# Create CA configuration
cat > /etc/wallix/ca/openssl.cnf << 'EOF'
[ca]
default_ca = CA_default

[CA_default]
dir               = /etc/wallix/ca
certs             = $dir/certs
crl_dir           = $dir/crl
new_certs_dir     = $dir/newcerts
database          = $dir/index.txt
serial            = $dir/serial
private_key       = $dir/private/ca.key
certificate       = $dir/certs/ca.crt
default_md        = sha256
default_days      = 365
policy            = policy_strict

[policy_strict]
countryName             = match
stateOrProvinceName     = match
organizationName        = match
commonName              = supplied

[req]
default_bits        = 4096
distinguished_name  = req_distinguished_name
string_mask         = utf8only
default_md          = sha256
x509_extensions     = v3_ca

[req_distinguished_name]
countryName                     = Country Name
stateOrProvinceName             = State
organizationName                = Organization
commonName                      = Common Name

[v3_ca]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[v3_intermediate_ca]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true, pathlen:0
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[server_cert]
basicConstraints = CA:FALSE
nsCertType = server
nsComment = "WALLIX Internal CA Generated Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer:always
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
EOF

# Generate CA private key
openssl genrsa -aes256 -out /etc/wallix/ca/private/ca.key 4096
chmod 400 /etc/wallix/ca/private/ca.key

# Generate CA certificate
openssl req -config /etc/wallix/ca/openssl.cnf \
    -key /etc/wallix/ca/private/ca.key \
    -new -x509 -days 3650 -sha256 -extensions v3_ca \
    -out /etc/wallix/ca/certs/ca.crt \
    -subj "/C=US/ST=California/O=Company/CN=WALLIX Internal CA"

# Verify CA certificate
openssl x509 -in /etc/wallix/ca/certs/ca.crt -text -noout | head -25
```

---

## Certificate Chain Configuration

### Understanding Certificate Chains

```
+==============================================================================+
|                    CERTIFICATE CHAIN STRUCTURE                                |
+==============================================================================+

  CHAIN HIERARCHY
  ===============

  +------------------------------------------------------------------------+
  |                                                                         |
  |   +-------------------+                                                |
  |   |    ROOT CA        |  <-- Trusted by browsers/OS                    |
  |   | (Self-signed)     |                                                |
  |   +--------+----------+                                                |
  |            |                                                           |
  |            | Signs                                                     |
  |            v                                                           |
  |   +-------------------+                                                |
  |   | INTERMEDIATE CA   |  <-- Included in chain file                    |
  |   | (Issuing CA)      |                                                |
  |   +--------+----------+                                                |
  |            |                                                           |
  |            | Signs                                                     |
  |            v                                                           |
  |   +-------------------+                                                |
  |   | SERVER CERT       |  <-- Your WALLIX certificate                   |
  |   | (End-entity)      |                                                |
  |   +-------------------+                                                |
  |                                                                         |
  +------------------------------------------------------------------------+

  CHAIN FILE ORDER
  ================

  server-chain.crt contains (in order):
  1. Server certificate (your cert)
  2. Intermediate CA certificate(s)
  3. Root CA (optional, usually in trust store)

+==============================================================================+
```

### Configure Certificate Chain

**Step 1: Obtain All Chain Certificates**

```bash
# Download intermediate CA certificate from CA
# Example for DigiCert:
wget -O /tmp/intermediate.crt \
    https://cacerts.digicert.com/DigiCertTLSRSASHA2562020CA1-1.crt.pem

# Convert DER to PEM if needed
openssl x509 -inform DER -in /tmp/intermediate.der -out /tmp/intermediate.pem
```

**Step 2: Build Chain File**

```bash
# Concatenate certificates in correct order
cat /etc/wallix/ssl/server.crt > /etc/wallix/ssl/fullchain.crt
cat /tmp/intermediate.crt >> /etc/wallix/ssl/fullchain.crt

# For multiple intermediates (in order from server to root)
# cat server.crt intermediate1.crt intermediate2.crt > fullchain.crt

# Verify chain
openssl verify -CAfile /etc/ssl/certs/ca-certificates.crt \
    /etc/wallix/ssl/fullchain.crt

# Expected output:
# /etc/wallix/ssl/fullchain.crt: OK
```

**Step 3: Create CA Bundle**

```bash
# Create CA chain file (intermediates only, no server cert)
cat /tmp/intermediate.crt > /etc/wallix/ssl/ca-chain.crt

# If multiple intermediates
# cat intermediate1.crt intermediate2.crt > ca-chain.crt

# Verify chain is complete
openssl verify -CAfile /etc/wallix/ssl/ca-chain.crt \
    -untrusted /etc/wallix/ssl/ca-chain.crt \
    /etc/wallix/ssl/server.crt
```

**Step 4: Configure WALLIX to Use Chain**

```bash
# Update WALLIX configuration via CLI
wabadmin config-set ssl.certificate /etc/wallix/ssl/server.crt
wabadmin config-set ssl.certificate_key /etc/wallix/ssl/server.key
wabadmin config-set ssl.certificate_chain /etc/wallix/ssl/ca-chain.crt

# Restart services
systemctl restart wallix-bastion

# Verify chain is served correctly
echo | openssl s_client -connect localhost:443 -showcerts 2>/dev/null | \
    grep -E "^(s:|i:)"

# Expected output:
# s:C = US, ST = California, O = Company, CN = bastion.company.com
# i:C = US, O = DigiCert Inc, CN = DigiCert TLS RSA SHA256 2020 CA1
# s:C = US, O = DigiCert Inc, CN = DigiCert TLS RSA SHA256 2020 CA1
# i:C = US, O = DigiCert Inc, OU = www.digicert.com, CN = DigiCert Global Root CA
```

---

## Certificate Renewal Procedures

### Manual Certificate Renewal

**Renewal Timeline**

```
+==============================================================================+
|                    CERTIFICATE RENEWAL TIMELINE                               |
+==============================================================================+

  Days Before Expiry    Action Required
  -------------------   ------------------------------------------------
  60 days               Generate new CSR, submit to CA
  45 days               Receive new certificate, test in staging
  30 days               Schedule production installation
  14 days               Install new certificate
  7 days                CRITICAL - must be renewed
  0 days                Certificate expired - service disruption

+==============================================================================+
```

**Step 1: Generate Renewal CSR**

```bash
# Use existing private key for renewal
openssl req -new \
    -key /etc/wallix/ssl/server.key \
    -out /tmp/renewal.csr \
    -config /tmp/csr.conf

# Or generate new key (recommended for long-term security)
openssl genrsa -out /tmp/new-server.key 4096
openssl req -new \
    -key /tmp/new-server.key \
    -out /tmp/renewal.csr \
    -config /tmp/csr.conf
```

**Step 2: Submit and Install**

```bash
# Follow CA-signed certificate installation procedure
# After receiving renewed certificate:

# Backup and install
BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p /etc/wallix/ssl/backup/${BACKUP_DATE}
cp /etc/wallix/ssl/server.* /etc/wallix/ssl/backup/${BACKUP_DATE}/

# If using new key
cp /tmp/new-server.key /etc/wallix/ssl/server.key
chmod 600 /etc/wallix/ssl/server.key

# Install renewed certificate
cp /tmp/renewed-server.crt /etc/wallix/ssl/server.crt

# Reload services
systemctl reload wallix-bastion
```

### Automated Certificate Renewal Script

```bash
#!/bin/bash
# /opt/scripts/cert-renewal-check.sh
# Run via cron: 0 8 * * * /opt/scripts/cert-renewal-check.sh

CERT_FILE="/etc/wallix/ssl/server.crt"
DAYS_WARN=60
DAYS_CRITICAL=30
EMAIL="security@company.com"

# Get expiry date
EXPIRY=$(openssl x509 -enddate -noout -in ${CERT_FILE} | cut -d= -f2)
EXPIRY_EPOCH=$(date -d "${EXPIRY}" +%s)
NOW_EPOCH=$(date +%s)
DAYS_LEFT=$(( (EXPIRY_EPOCH - NOW_EPOCH) / 86400 ))

# Log status
logger -t cert-check "Certificate expires in ${DAYS_LEFT} days (${EXPIRY})"

# Send alerts
if [ ${DAYS_LEFT} -lt ${DAYS_CRITICAL} ]; then
    echo "CRITICAL: WALLIX SSL certificate expires in ${DAYS_LEFT} days!" | \
        mail -s "[CRITICAL] Certificate Expiring" ${EMAIL}
    logger -t cert-check "CRITICAL: Certificate expires in ${DAYS_LEFT} days"
elif [ ${DAYS_LEFT} -lt ${DAYS_WARN} ]; then
    echo "WARNING: WALLIX SSL certificate expires in ${DAYS_LEFT} days." | \
        mail -s "[WARNING] Certificate Expiring Soon" ${EMAIL}
    logger -t cert-check "WARNING: Certificate expires in ${DAYS_LEFT} days"
fi

# Output for monitoring
echo "CERT_DAYS_LEFT=${DAYS_LEFT}"
exit 0
```

---

## Let's Encrypt/ACME Integration

### Prerequisites

- Domain must be publicly resolvable
- Port 80 or 443 accessible from internet (for HTTP/TLS challenges)
- Not suitable for air-gapped environments

### Install Certbot

```bash
# Install certbot
apt update
apt install -y certbot

# Verify installation
certbot --version

# Expected output:
# certbot 2.x.x
```

### Obtain Certificate

**HTTP Challenge Method**

```bash
# Stop WALLIX temporarily (frees port 80)
systemctl stop wallix-bastion

# Obtain certificate
certbot certonly --standalone \
    -d bastion.company.com \
    -d wallix.company.com \
    --email admin@company.com \
    --agree-tos \
    --non-interactive

# Expected output:
# Saving debug log to /var/log/letsencrypt/letsencrypt.log
# Requesting a certificate for bastion.company.com and wallix.company.com
# Successfully received certificate.
# Certificate is saved at: /etc/letsencrypt/live/bastion.company.com/fullchain.pem
# Key is saved at: /etc/letsencrypt/live/bastion.company.com/privkey.pem

# Link certificates to WALLIX directory
ln -sf /etc/letsencrypt/live/bastion.company.com/fullchain.pem /etc/wallix/ssl/server.crt
ln -sf /etc/letsencrypt/live/bastion.company.com/privkey.pem /etc/wallix/ssl/server.key

# Start WALLIX
systemctl start wallix-bastion
```

**DNS Challenge Method (Recommended)**

```bash
# For DNS challenge (doesn't require stopping services)
certbot certonly --manual \
    --preferred-challenges dns \
    -d bastion.company.com \
    --email admin@company.com \
    --agree-tos

# Follow prompts to create DNS TXT record
# Example:
# Please deploy a DNS TXT record under the name:
# _acme-challenge.bastion.company.com
# with the following value:
# gfj9Xq...Rg5Y

# Verify DNS record is propagated
dig -t TXT _acme-challenge.bastion.company.com

# Press Enter to continue after DNS propagation
```

### Configure Automatic Renewal

```bash
# Create renewal hook script
cat > /etc/letsencrypt/renewal-hooks/deploy/wallix-reload.sh << 'EOF'
#!/bin/bash
# Reload WALLIX after certificate renewal
systemctl reload wallix-bastion
logger -t certbot "WALLIX Bastion reloaded after certificate renewal"
EOF

chmod +x /etc/letsencrypt/renewal-hooks/deploy/wallix-reload.sh

# Test renewal process
certbot renew --dry-run

# Expected output:
# Processing /etc/letsencrypt/renewal/bastion.company.com.conf
# Account registered.
# Simulating renewal of an existing certificate for bastion.company.com
# Congratulations, all simulated renewals succeeded

# Cron job is automatically created at:
# /etc/cron.d/certbot
```

### WALLIX ACME Integration

```bash
# Use built-in WALLIX Let's Encrypt support
wabadmin ssl-letsencrypt \
    --domain bastion.company.com \
    --email admin@company.com \
    --auto-renew

# Verify configuration
wabadmin ssl-verify

# Check renewal schedule
wabadmin ssl-letsencrypt --status

# Expected output:
# Let's Encrypt Status:
# Domain: bastion.company.com
# Valid Until: 2026-04-15
# Auto-Renew: Enabled
# Last Renewal: 2026-01-15
# Next Renewal: 2026-03-15 (30 days before expiry)
```

---

## Client Certificate Authentication

### Configure Client Certificate Authentication

**Step 1: Create Client CA**

```bash
# Generate CA for client authentication
openssl genrsa -out /etc/wallix/ssl/ca/client-ca.key 4096
chmod 600 /etc/wallix/ssl/ca/client-ca.key

openssl req -x509 -new -nodes \
    -key /etc/wallix/ssl/ca/client-ca.key \
    -sha256 -days 3650 \
    -out /etc/wallix/ssl/ca/client-ca.crt \
    -subj "/C=US/ST=California/O=Company/CN=WALLIX Client Auth CA"

# Copy to trusted CA directory
cp /etc/wallix/ssl/ca/client-ca.crt /etc/wallix/ssl/ca/trusted-ca.crt
```

**Step 2: Enable Client Certificate Authentication**

```bash
# Configure WALLIX for client certificate auth
wabadmin config-set auth.client_cert.enabled true
wabadmin config-set auth.client_cert.ca_file /etc/wallix/ssl/ca/client-ca.crt
wabadmin config-set auth.client_cert.verify_depth 2
wabadmin config-set auth.client_cert.crl_check false
wabadmin config-set auth.client_cert.username_field "CN"

# Restart services
systemctl restart wallix-bastion
```

**Step 3: Issue Client Certificate**

```bash
# Generate client key
openssl genrsa -out /tmp/client-jsmith.key 4096

# Generate client CSR
openssl req -new \
    -key /tmp/client-jsmith.key \
    -out /tmp/client-jsmith.csr \
    -subj "/C=US/ST=California/O=Company/CN=jsmith/emailAddress=jsmith@company.com"

# Sign with client CA
openssl x509 -req \
    -in /tmp/client-jsmith.csr \
    -CA /etc/wallix/ssl/ca/client-ca.crt \
    -CAkey /etc/wallix/ssl/ca/client-ca.key \
    -CAcreateserial \
    -out /tmp/client-jsmith.crt \
    -days 365 \
    -sha256

# Create PKCS#12 bundle for user
openssl pkcs12 -export \
    -out /tmp/client-jsmith.p12 \
    -inkey /tmp/client-jsmith.key \
    -in /tmp/client-jsmith.crt \
    -certfile /etc/wallix/ssl/ca/client-ca.crt \
    -name "jsmith WALLIX Client Certificate"

# Provide .p12 file to user for browser import
```

**Step 4: Test Client Authentication**

```bash
# Test with curl
curl -v --cert /tmp/client-jsmith.crt --key /tmp/client-jsmith.key \
    https://bastion.company.com/api/v2/health

# Expected output:
# * SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384
# * Server certificate: bastion.company.com
# * TLSv1.3 (IN), TLS handshake, Certificate request (13):
# * Client certificate: jsmith
# {"status": "healthy", "authenticated_user": "jsmith"}
```

### Troubleshooting Client Certificates

```
+==============================================================================+
|                    CLIENT CERTIFICATE TROUBLESHOOTING                         |
+==============================================================================+

  COMMON ISSUES
  =============

  +------------------------------------------------------------------------+
  | Issue                  | Cause                   | Solution             |
  +------------------------+-------------------------+----------------------+
  | "Certificate unknown"  | CA not trusted          | Add CA to trusted    |
  | "Certificate expired"  | Cert validity passed    | Issue new cert       |
  | "Certificate revoked"  | Cert on CRL             | Issue new cert       |
  | "Username not found"   | CN doesn't match user   | Check username_field |
  | "Handshake failure"    | Client cert required    | Install client cert  |
  +------------------------+-------------------------+----------------------+

  DIAGNOSTIC COMMANDS
  ===================

  # Test SSL connection with client cert
  openssl s_client -connect bastion:443 \
      -cert client.crt -key client.key -CAfile ca.crt

  # Check certificate details
  openssl x509 -in client.crt -text -noout

  # Verify certificate chain
  openssl verify -CAfile client-ca.crt client.crt

  # Check CRL (if enabled)
  openssl crl -in crl.pem -text -noout

+==============================================================================+
```

---

## SSH Host Key Management

### SSH Host Key Overview

```
+==============================================================================+
|                    SSH HOST KEY MANAGEMENT                                    |
+==============================================================================+

  KEY TYPES AND RECOMMENDATIONS
  =============================

  +------------------------------------------------------------------------+
  | Key Type    | Size        | Security | Recommendation                   |
  +-------------+-------------+----------+----------------------------------+
  | RSA         | 4096 bits   | High     | Required for legacy clients      |
  | Ed25519     | 256 bits    | Very High| Preferred for modern clients     |
  | ECDSA       | 384 bits    | High     | Alternative to RSA               |
  | DSA         | 1024 bits   | Low      | DO NOT USE - deprecated          |
  +-------------+-------------+----------+----------------------------------+

+==============================================================================+
```

### Generate New Host Keys

```bash
# Backup existing keys
mkdir -p /etc/ssh/backup/$(date +%Y%m%d)
cp /etc/ssh/ssh_host_* /etc/ssh/backup/$(date +%Y%m%d)/

# Generate new RSA key (4096 bits)
ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -N ""

# Generate new Ed25519 key
ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ""

# Generate new ECDSA key
ssh-keygen -t ecdsa -b 384 -f /etc/ssh/ssh_host_ecdsa_key -N ""

# Set correct permissions
chmod 600 /etc/ssh/ssh_host_*_key
chmod 644 /etc/ssh/ssh_host_*_key.pub

# Verify keys
for key in /etc/ssh/ssh_host_*_key.pub; do
    ssh-keygen -lf $key
done

# Expected output:
# 4096 SHA256:xxxx...xxxx /etc/ssh/ssh_host_rsa_key.pub (RSA)
# 256 SHA256:xxxx...xxxx /etc/ssh/ssh_host_ed25519_key.pub (ED25519)
# 384 SHA256:xxxx...xxxx /etc/ssh/ssh_host_ecdsa_key.pub (ECDSA)

# Restart SSH daemon
systemctl restart sshd
```

### WALLIX SSH Proxy Key Management

```bash
# Generate WALLIX SSH proxy keys
wabadmin ssh-keygen --type rsa --bits 4096
wabadmin ssh-keygen --type ed25519

# List current keys
wabadmin ssh-keys --list

# Expected output:
# SSH Proxy Keys:
# +-------------+-----------+------------------------------------------+
# | Type        | Bits      | Fingerprint                              |
# +-------------+-----------+------------------------------------------+
# | RSA         | 4096      | SHA256:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    |
# | Ed25519     | 256       | SHA256:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    |
# +-------------+-----------+------------------------------------------+

# Export public key for distribution
wabadmin ssh-keys --export --type ed25519 > /tmp/wallix-proxy.pub
```

### Host Key Distribution

```bash
# Get host key fingerprints for user verification
ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub

# Create known_hosts entry for users
echo "bastion.company.com $(cat /etc/ssh/ssh_host_ed25519_key.pub)" > /tmp/known_hosts_entry

# Distribute via DNS (SSHFP records)
ssh-keygen -r bastion.company.com -f /etc/ssh/ssh_host_ed25519_key.pub

# Expected output (add to DNS):
# bastion.company.com IN SSHFP 4 1 xxxx...xxxx
# bastion.company.com IN SSHFP 4 2 xxxx...xxxx
```

### Host Key Rotation Procedure

```bash
# Schedule during maintenance window

# 1. Generate new keys (keep old ones temporarily)
ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key_new -N ""

# 2. Add new key to SSH config
echo "HostKey /etc/ssh/ssh_host_ed25519_key_new" >> /etc/ssh/sshd_config

# 3. Reload SSH to serve both keys
systemctl reload sshd

# 4. Notify users to update known_hosts
# 5. After transition period, remove old key

# 6. Rename new key to standard name
mv /etc/ssh/ssh_host_ed25519_key_new /etc/ssh/ssh_host_ed25519_key
mv /etc/ssh/ssh_host_ed25519_key_new.pub /etc/ssh/ssh_host_ed25519_key.pub

# 7. Update sshd_config to use standard path
# 8. Reload SSH
systemctl reload sshd
```

---

## Certificate Monitoring and Alerting

### Certificate Expiry Monitoring Script

```bash
#!/bin/bash
# /opt/scripts/cert-monitor.sh
# Comprehensive certificate monitoring

CERTS=(
    "/etc/wallix/ssl/server.crt:WALLIX Web SSL"
    "/etc/wallix/ssl/ldap-client.crt:LDAP Client"
    "/etc/wallix/ssl/syslog.crt:Syslog TLS"
    "/var/lib/postgresql/15/main/server.crt:PostgreSQL"
)

WARN_DAYS=60
CRITICAL_DAYS=30
OUTPUT_FILE="/var/log/wallix/cert-status.log"
ALERT_EMAIL="security@company.com"

echo "Certificate Status Report - $(date)" > ${OUTPUT_FILE}
echo "==========================================" >> ${OUTPUT_FILE}

EXIT_CODE=0

for CERT_ENTRY in "${CERTS[@]}"; do
    CERT_PATH="${CERT_ENTRY%%:*}"
    CERT_NAME="${CERT_ENTRY##*:}"

    if [ ! -f "${CERT_PATH}" ]; then
        echo "[MISSING] ${CERT_NAME}: File not found" >> ${OUTPUT_FILE}
        EXIT_CODE=2
        continue
    fi

    EXPIRY=$(openssl x509 -enddate -noout -in ${CERT_PATH} 2>/dev/null | cut -d= -f2)
    if [ -z "${EXPIRY}" ]; then
        echo "[ERROR] ${CERT_NAME}: Cannot read certificate" >> ${OUTPUT_FILE}
        EXIT_CODE=2
        continue
    fi

    EXPIRY_EPOCH=$(date -d "${EXPIRY}" +%s)
    NOW_EPOCH=$(date +%s)
    DAYS_LEFT=$(( (EXPIRY_EPOCH - NOW_EPOCH) / 86400 ))

    if [ ${DAYS_LEFT} -lt 0 ]; then
        echo "[EXPIRED] ${CERT_NAME}: Expired ${DAYS_LEFT#-} days ago" >> ${OUTPUT_FILE}
        EXIT_CODE=2
    elif [ ${DAYS_LEFT} -lt ${CRITICAL_DAYS} ]; then
        echo "[CRITICAL] ${CERT_NAME}: Expires in ${DAYS_LEFT} days (${EXPIRY})" >> ${OUTPUT_FILE}
        EXIT_CODE=2
    elif [ ${DAYS_LEFT} -lt ${WARN_DAYS} ]; then
        echo "[WARNING] ${CERT_NAME}: Expires in ${DAYS_LEFT} days (${EXPIRY})" >> ${OUTPUT_FILE}
        [ ${EXIT_CODE} -lt 1 ] && EXIT_CODE=1
    else
        echo "[OK] ${CERT_NAME}: Expires in ${DAYS_LEFT} days (${EXPIRY})" >> ${OUTPUT_FILE}
    fi
done

# Send alert if issues found
if [ ${EXIT_CODE} -gt 0 ]; then
    cat ${OUTPUT_FILE} | mail -s "[WALLIX] Certificate Alert" ${ALERT_EMAIL}
fi

# Output for monitoring system
cat ${OUTPUT_FILE}
exit ${EXIT_CODE}
```

### Configure Monitoring Integration

**Prometheus Metrics Export**

```bash
# Create certificate metrics script
cat > /opt/scripts/cert-metrics.sh << 'EOF'
#!/bin/bash
# Export certificate metrics for Prometheus

CERTS=(
    "/etc/wallix/ssl/server.crt:wallix_web"
    "/etc/wallix/ssl/ldap-client.crt:ldap_client"
    "/var/lib/postgresql/15/main/server.crt:postgresql"
)

echo "# HELP cert_expiry_days Days until certificate expiry"
echo "# TYPE cert_expiry_days gauge"

for CERT_ENTRY in "${CERTS[@]}"; do
    CERT_PATH="${CERT_ENTRY%%:*}"
    CERT_NAME="${CERT_ENTRY##*:}"

    if [ -f "${CERT_PATH}" ]; then
        EXPIRY=$(openssl x509 -enddate -noout -in ${CERT_PATH} 2>/dev/null | cut -d= -f2)
        EXPIRY_EPOCH=$(date -d "${EXPIRY}" +%s)
        NOW_EPOCH=$(date +%s)
        DAYS_LEFT=$(( (EXPIRY_EPOCH - NOW_EPOCH) / 86400 ))

        echo "cert_expiry_days{cert=\"${CERT_NAME}\"} ${DAYS_LEFT}"
    fi
done
EOF

chmod +x /opt/scripts/cert-metrics.sh
```

**WALLIX Built-in Monitoring**

```bash
# Configure certificate alerts via WALLIX
wabadmin alert-create \
    --name "cert-expiry-warning" \
    --type certificate \
    --threshold 60 \
    --action "email:security@company.com" \
    --severity warning

wabadmin alert-create \
    --name "cert-expiry-critical" \
    --type certificate \
    --threshold 30 \
    --action "email:security@company.com,sms:+1234567890" \
    --severity critical

# View certificate status
wabadmin certificates --list --expiry

# Expected output:
# Certificate Status:
# +----------------------+------------------+-------------+--------+
# | Name                 | Expires          | Days Left   | Status |
# +----------------------+------------------+-------------+--------+
# | Web SSL              | 2027-01-15       | 365         | OK     |
# | LDAP Client          | 2026-06-15       | 150         | OK     |
# | Syslog TLS           | 2026-03-15       | 58          | WARN   |
# | PostgreSQL           | 2027-01-15       | 365         | OK     |
# +----------------------+------------------+-------------+--------+
```

### Automated Alert Configuration

```bash
# Add to crontab
crontab -e

# Add these entries:
# Daily certificate check at 8am
0 8 * * * /opt/scripts/cert-monitor.sh

# Hourly metrics export for Prometheus
0 * * * * /opt/scripts/cert-metrics.sh > /var/lib/node_exporter/cert_metrics.prom
```

---

## Troubleshooting

### Common Certificate Errors

```
+==============================================================================+
|                    CERTIFICATE TROUBLESHOOTING GUIDE                          |
+==============================================================================+

  ERROR: CERTIFICATE HAS EXPIRED
  ==============================

  Symptoms:
  - Browser shows "Your connection is not private"
  - API calls fail with SSL error
  - Services fail to start

  Diagnosis:
  +------------------------------------------------------------------------+
  | # Check certificate expiry                                              |
  | openssl x509 -in /etc/wallix/ssl/server.crt -noout -dates              |
  |                                                                         |
  | # Expected output showing past date:                                    |
  | notBefore=Jan 15 00:00:00 2025 GMT                                     |
  | notAfter=Jan 15 23:59:59 2026 GMT  <-- EXPIRED                         |
  +------------------------------------------------------------------------+

  Resolution:
  - Install new certificate (follow CA-signed or self-signed procedure)
  - For emergency: create self-signed certificate temporarily

  --------------------------------------------------------------------------

  ERROR: CERTIFICATE CHAIN IS INCOMPLETE
  ======================================

  Symptoms:
  - Browser shows "Unable to verify certificate"
  - curl fails with "unable to get local issuer certificate"
  - Some clients work, others don't

  Diagnosis:
  +------------------------------------------------------------------------+
  | # Test SSL connection and show chain                                    |
  | openssl s_client -connect localhost:443 -showcerts                     |
  |                                                                         |
  | # Verify chain                                                          |
  | openssl verify -CAfile /etc/ssl/certs/ca-certificates.crt \            |
  |     /etc/wallix/ssl/server.crt                                         |
  |                                                                         |
  | # Error output:                                                         |
  | error 20 at 0 depth lookup: unable to get local issuer certificate     |
  +------------------------------------------------------------------------+

  Resolution:
  - Download intermediate CA certificate from CA
  - Append to ca-chain.crt
  - Reload services

  --------------------------------------------------------------------------

  ERROR: CERTIFICATE/KEY MISMATCH
  ===============================

  Symptoms:
  - Service fails to start
  - Error: "key values mismatch"
  - SSL handshake failures

  Diagnosis:
  +------------------------------------------------------------------------+
  | # Compare certificate and key modulus                                   |
  | openssl x509 -noout -modulus -in /etc/wallix/ssl/server.crt | md5sum  |
  | openssl rsa -noout -modulus -in /etc/wallix/ssl/server.key | md5sum   |
  |                                                                         |
  | # If outputs differ, key doesn't match certificate                      |
  +------------------------------------------------------------------------+

  Resolution:
  - Locate correct private key that matches certificate
  - Or generate new CSR with current key and request new certificate

  --------------------------------------------------------------------------

  ERROR: WRONG HOSTNAME
  =====================

  Symptoms:
  - Browser shows "Certificate name mismatch"
  - curl: "SSL: certificate subject name does not match target host name"

  Diagnosis:
  +------------------------------------------------------------------------+
  | # Check certificate CN and SANs                                         |
  | openssl x509 -in /etc/wallix/ssl/server.crt -noout -text | \           |
  |     grep -A1 "Subject Alternative Name"                                |
  |                                                                         |
  | # Check CN                                                              |
  | openssl x509 -in /etc/wallix/ssl/server.crt -noout -subject            |
  +------------------------------------------------------------------------+

  Resolution:
  - Request new certificate with correct hostnames in SAN
  - Update DNS to match certificate names
  - Add missing SANs to certificate

  --------------------------------------------------------------------------

  ERROR: PERMISSION DENIED
  ========================

  Symptoms:
  - Service fails to start
  - Error: "cannot read certificate" or "permission denied"
  - Key file access errors

  Diagnosis:
  +------------------------------------------------------------------------+
  | # Check file permissions                                                |
  | ls -la /etc/wallix/ssl/                                                |
  |                                                                         |
  | # Expected permissions:                                                 |
  | -rw-r--r-- wallix wallix server.crt                                    |
  | -rw------- wallix wallix server.key                                    |
  +------------------------------------------------------------------------+

  Resolution:
  - Fix permissions:
    chmod 644 /etc/wallix/ssl/server.crt
    chmod 600 /etc/wallix/ssl/server.key
    chown wallix:wallix /etc/wallix/ssl/server.*

+==============================================================================+
```

### Diagnostic Commands Reference

```bash
# View certificate details
openssl x509 -in cert.crt -text -noout

# Check certificate expiry
openssl x509 -in cert.crt -noout -dates

# Verify certificate chain
openssl verify -CAfile ca-chain.crt server.crt

# Test SSL connection
openssl s_client -connect hostname:443 -showcerts

# Check certificate/key match
openssl x509 -noout -modulus -in cert.crt | openssl md5
openssl rsa -noout -modulus -in key.key | openssl md5

# View certificate fingerprint
openssl x509 -in cert.crt -noout -fingerprint -sha256

# Check CSR contents
openssl req -in request.csr -text -noout

# Convert PEM to DER
openssl x509 -in cert.pem -outform DER -out cert.der

# Convert DER to PEM
openssl x509 -inform DER -in cert.der -out cert.pem

# Extract certificate from PKCS#12
openssl pkcs12 -in bundle.p12 -clcerts -nokeys -out cert.pem

# Extract key from PKCS#12
openssl pkcs12 -in bundle.p12 -nocerts -nodes -out key.pem
```

---

## Certificate Storage Security

### HSM Considerations

```
+==============================================================================+
|                    HARDWARE SECURITY MODULE (HSM) INTEGRATION                 |
+==============================================================================+

  HSM USE CASES
  =============

  +------------------------------------------------------------------------+
  | Requirement              | HSM Recommended | Notes                      |
  +--------------------------+-----------------+----------------------------+
  | Root CA private key      | Yes             | Never extract from HSM     |
  | Issuing CA key           | Yes             | High-value signing key     |
  | WALLIX master key        | Consider        | Protects credential vault  |
  | TLS server keys          | Optional        | Performance impact         |
  | User authentication keys | Optional        | Smart card integration     |
  +--------------------------+-----------------+----------------------------+

  --------------------------------------------------------------------------

  HSM INTEGRATION OPTIONS
  =======================

  +------------------------------------------------------------------------+
  |                                                                         |
  | Option 1: Network HSM (Recommended for HA)                             |
  |                                                                         |
  |   +-------------+          +-------------+                              |
  |   |   WALLIX    |--------->|  Network    |                              |
  |   |   Bastion   |  PKCS#11 |    HSM      |                              |
  |   +-------------+          +-------------+                              |
  |                                                                         |
  | Vendors: Thales Luna, nCipher, AWS CloudHSM                            |
  |                                                                         |
  +------------------------------------------------------------------------+
  |                                                                         |
  | Option 2: USB HSM (Single Node)                                        |
  |                                                                         |
  |   +-------------+                                                       |
  |   |   WALLIX    |---[USB]---[YubiHSM/Nitrokey HSM]                     |
  |   |   Bastion   |                                                       |
  |   +-------------+                                                       |
  |                                                                         |
  | Suitable for: Smaller deployments, air-gapped environments             |
  |                                                                         |
  +------------------------------------------------------------------------+

+==============================================================================+
```

### Secure Key Storage Best Practices

```bash
# Private key protection checklist
# ================================

# 1. Restrict file permissions
chmod 600 /etc/wallix/ssl/server.key
chown wallix:wallix /etc/wallix/ssl/server.key

# 2. Disable key file backup in version control
echo "*.key" >> /etc/wallix/.gitignore

# 3. Use encrypted filesystem (already enabled with LUKS)
lsblk -f | grep -i luks

# 4. Configure AppArmor/SELinux restrictions
# (WALLIX includes predefined profiles)

# 5. Audit key file access
auditctl -w /etc/wallix/ssl/server.key -p rwa -k private_key_access

# 6. Never store keys in:
#    - Version control systems
#    - Configuration management databases
#    - Backup systems without encryption
#    - Email or messaging systems
```

### Key Backup Procedures

```bash
#!/bin/bash
# /opt/scripts/key-backup.sh
# Secure backup of private keys

BACKUP_DIR="/var/backup/wallix/keys"
DATE=$(date +%Y%m%d)
GPG_RECIPIENT="security@company.com"

# Create encrypted backup
mkdir -p ${BACKUP_DIR}

# Backup and encrypt private key
gpg --encrypt --recipient ${GPG_RECIPIENT} \
    --output ${BACKUP_DIR}/server.key.${DATE}.gpg \
    /etc/wallix/ssl/server.key

# Verify backup
gpg --list-packets ${BACKUP_DIR}/server.key.${DATE}.gpg

# Set restrictive permissions
chmod 600 ${BACKUP_DIR}/*.gpg

# Transfer to secure offline storage
# (Manual step - should be air-gapped)

# Log backup
logger -t key-backup "Private key backup created: server.key.${DATE}.gpg"

# Cleanup old backups (keep last 3)
ls -t ${BACKUP_DIR}/server.key.*.gpg | tail -n +4 | xargs -r rm -f
```

### Certificate Revocation

```bash
# Generate Certificate Revocation List (CRL)

# 1. Add certificate to CRL
openssl ca -config /etc/wallix/ca/openssl.cnf \
    -revoke /path/to/compromised.crt \
    -crl_reason keyCompromise

# 2. Generate updated CRL
openssl ca -config /etc/wallix/ca/openssl.cnf \
    -gencrl \
    -out /etc/wallix/ssl/ca/crl/current.crl

# 3. Distribute CRL
cp /etc/wallix/ssl/ca/crl/current.crl /var/www/pki/crl/

# 4. Configure WALLIX to check CRL
wabadmin config-set ssl.crl_check true
wabadmin config-set ssl.crl_file /etc/wallix/ssl/ca/crl/current.crl

# 5. Restart services
systemctl restart wallix-bastion
```

---

## Quick Reference

### Certificate Commands Cheat Sheet

| Task | Command |
|------|---------|
| View certificate | `openssl x509 -in cert.crt -text -noout` |
| Check expiry | `openssl x509 -in cert.crt -noout -enddate` |
| Generate CSR | `openssl req -new -key key.pem -out csr.pem` |
| Self-signed cert | `openssl req -x509 -nodes -days 365 -newkey rsa:4096 -keyout key.pem -out cert.pem` |
| Verify chain | `openssl verify -CAfile ca.crt cert.crt` |
| Test connection | `openssl s_client -connect host:443` |
| Key/cert match | Compare: `openssl x509 -modulus` vs `openssl rsa -modulus` |
| Convert PEM to PKCS12 | `openssl pkcs12 -export -in cert.pem -inkey key.pem -out bundle.p12` |

### Certificate Locations Summary

| Certificate | Path |
|-------------|------|
| Web SSL | `/etc/wallix/ssl/server.crt` |
| Web SSL Key | `/etc/wallix/ssl/server.key` |
| CA Chain | `/etc/wallix/ssl/ca-chain.crt` |
| Client Auth CA | `/etc/wallix/ssl/ca/client-ca.crt` |
| SSH Host Keys | `/etc/ssh/ssh_host_*` |
| PostgreSQL SSL | `/var/lib/postgresql/15/main/server.crt` |

---

## External References

- [WALLIX Documentation Portal](https://pam.wallix.one/documentation)
- [WALLIX Administration Guide - SSL Configuration](https://pam.wallix.one/documentation/admin-doc/bastion_en_administration_guide.pdf)
- [OpenSSL Documentation](https://www.openssl.org/docs/)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)
- [NIST Guidelines for TLS](https://csrc.nist.gov/publications/detail/sp/800-52/rev-2/final)

---

*Document Version: 1.0*
*Last Updated: January 2026*
