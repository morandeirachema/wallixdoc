# Certificate Management and Troubleshooting

## SSL/TLS Certificate Operations for PAM4OT

This guide covers certificate management, renewal procedures, and troubleshooting certificate issues.

---

## Certificate Overview

```
+===============================================================================+
|                      PAM4OT CERTIFICATE ARCHITECTURE                          |
+===============================================================================+

  Certificate Authority                 PAM4OT                    Clients
  =====================                 ======                    =======

  ┌─────────────────┐              ┌─────────────────┐
  │  Enterprise CA  │              │  Web Server     │
  │  (Internal PKI) │ ── Issues ─> │  Certificate    │ <── HTTPS ── Browsers
  └─────────────────┘              └─────────────────┘

  ┌─────────────────┐              ┌─────────────────┐
  │  Let's Encrypt  │              │  SSH Host       │
  │  (Public CA)    │ ── Issues ─> │  Certificate    │ <── SSH ─── SSH Clients
  └─────────────────┘              └─────────────────┘

                                   ┌─────────────────┐
                                   │  LDAPS Client   │
                                   │  Certificate    │ ── LDAPS ── AD DC
                                   └─────────────────┘

+===============================================================================+
```

---

## Section 1: Certificate Inventory

### Standard PAM4OT Certificates

| Certificate | Purpose | Location | Validity |
|-------------|---------|----------|----------|
| Web Server | HTTPS UI/API | /etc/ssl/wab/server.crt | 1-2 years |
| SSH Host | SSH Proxy | /etc/ssh/ssh_host_*_key | Permanent |
| LDAPS Client | AD Communication | /etc/ssl/wab/ldap-client.crt | 1-2 years |
| PostgreSQL | DB Encryption | /etc/postgresql/15/main/server.crt | 1-2 years |
| Cluster TLS | Node Communication | /etc/corosync/authkey | Generated |
| SIEM Client | Log Encryption | /etc/ssl/wab/syslog-client.crt | 1-2 years |

### Check All Certificates

```bash
#!/bin/bash
# check-certificates.sh - Check expiration of all PAM4OT certificates

echo "=== PAM4OT Certificate Status ==="
echo ""

# Web server certificate
echo "Web Server Certificate:"
if [ -f /etc/ssl/wab/server.crt ]; then
    openssl x509 -in /etc/ssl/wab/server.crt -noout -subject -dates -issuer
    EXPIRY=$(openssl x509 -in /etc/ssl/wab/server.crt -noout -enddate | cut -d= -f2)
    EXPIRY_EPOCH=$(date -d "${EXPIRY}" +%s)
    NOW_EPOCH=$(date +%s)
    DAYS_LEFT=$(( (EXPIRY_EPOCH - NOW_EPOCH) / 86400 ))
    echo "Days until expiry: ${DAYS_LEFT}"
    if [ ${DAYS_LEFT} -lt 30 ]; then
        echo "WARNING: Certificate expires in less than 30 days!"
    fi
else
    echo "NOT FOUND"
fi
echo ""

# PostgreSQL certificate
echo "PostgreSQL Certificate:"
if [ -f /etc/postgresql/15/main/server.crt ]; then
    openssl x509 -in /etc/postgresql/15/main/server.crt -noout -subject -dates
else
    echo "NOT FOUND"
fi
echo ""

# LDAP client certificate
echo "LDAP Client Certificate:"
if [ -f /etc/ssl/wab/ldap-client.crt ]; then
    openssl x509 -in /etc/ssl/wab/ldap-client.crt -noout -subject -dates
else
    echo "NOT FOUND (may be using system CA)"
fi
```

---

## Section 2: Certificate Generation

### Generate Self-Signed Certificate (Testing Only)

```bash
# Generate private key
openssl genrsa -out /etc/ssl/wab/server.key 4096

# Generate self-signed certificate
openssl req -new -x509 \
    -key /etc/ssl/wab/server.key \
    -out /etc/ssl/wab/server.crt \
    -days 365 \
    -subj "/C=US/ST=State/L=City/O=Company/CN=pam4ot.company.com" \
    -addext "subjectAltName=DNS:pam4ot.company.com,DNS:pam4ot-node1.company.com,DNS:pam4ot-node2.company.com,IP:10.10.1.100"

# Set permissions
chmod 600 /etc/ssl/wab/server.key
chmod 644 /etc/ssl/wab/server.crt
chown wabuser:wabgroup /etc/ssl/wab/server.*
```

### Generate CSR for Enterprise CA

```bash
# Generate private key
openssl genrsa -out /etc/ssl/wab/server.key 4096

# Create CSR configuration
cat > /tmp/csr.conf << EOF
[req]
default_bits = 4096
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = req_ext

[dn]
C = US
ST = State
L = City
O = Company Name
OU = IT Security
CN = pam4ot.company.com

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = pam4ot.company.com
DNS.2 = pam4ot-node1.company.com
DNS.3 = pam4ot-node2.company.com
IP.1 = 10.10.1.100
IP.2 = 10.10.1.101
IP.3 = 10.10.1.102
EOF

# Generate CSR
openssl req -new \
    -key /etc/ssl/wab/server.key \
    -out /etc/ssl/wab/server.csr \
    -config /tmp/csr.conf

# Verify CSR
openssl req -in /etc/ssl/wab/server.csr -noout -text

# Submit to CA and receive server.crt
```

### Generate Certificate with Let's Encrypt

```bash
# Install certbot
apt install certbot

# Generate certificate (standalone mode)
certbot certonly --standalone \
    -d pam4ot.company.com \
    --agree-tos \
    --email admin@company.com

# Certificates will be in:
# /etc/letsencrypt/live/pam4ot.company.com/fullchain.pem
# /etc/letsencrypt/live/pam4ot.company.com/privkey.pem

# Link to PAM4OT location
ln -sf /etc/letsencrypt/live/pam4ot.company.com/fullchain.pem /etc/ssl/wab/server.crt
ln -sf /etc/letsencrypt/live/pam4ot.company.com/privkey.pem /etc/ssl/wab/server.key

# Setup auto-renewal
systemctl enable certbot.timer
```

---

## Section 3: Certificate Installation

### Install Web Server Certificate

```bash
# Stop PAM4OT service
systemctl stop wallix-bastion

# Backup existing certificates
cp /etc/ssl/wab/server.crt /etc/ssl/wab/server.crt.backup
cp /etc/ssl/wab/server.key /etc/ssl/wab/server.key.backup

# Install new certificate
cp new-server.crt /etc/ssl/wab/server.crt
cp new-server.key /etc/ssl/wab/server.key

# Install CA chain (if applicable)
cp ca-chain.crt /etc/ssl/wab/ca-chain.crt

# Set permissions
chmod 600 /etc/ssl/wab/server.key
chmod 644 /etc/ssl/wab/server.crt
chown wabuser:wabgroup /etc/ssl/wab/server.*

# Verify certificate
openssl verify -CAfile /etc/ssl/wab/ca-chain.crt /etc/ssl/wab/server.crt

# Start PAM4OT service
systemctl start wallix-bastion

# Verify HTTPS
curl -v https://pam4ot.company.com/ 2>&1 | grep "SSL certificate"
```

### Install PostgreSQL Certificate

```bash
# Stop PostgreSQL
systemctl stop postgresql

# Install certificates
cp server.crt /etc/postgresql/15/main/server.crt
cp server.key /etc/postgresql/15/main/server.key
cp ca.crt /etc/postgresql/15/main/root.crt

# Set permissions
chmod 600 /etc/postgresql/15/main/server.key
chown postgres:postgres /etc/postgresql/15/main/server.*
chown postgres:postgres /etc/postgresql/15/main/root.crt

# Configure PostgreSQL
# In postgresql.conf:
# ssl = on
# ssl_cert_file = '/etc/postgresql/15/main/server.crt'
# ssl_key_file = '/etc/postgresql/15/main/server.key'
# ssl_ca_file = '/etc/postgresql/15/main/root.crt'

# Start PostgreSQL
systemctl start postgresql

# Verify SSL
sudo -u postgres psql -c "SHOW ssl;"
```

---

## Section 4: Certificate Renewal

### Renewal Procedure

```bash
# 1. Generate new CSR (if required by CA)
openssl req -new \
    -key /etc/ssl/wab/server.key \
    -out /etc/ssl/wab/server-renewal.csr \
    -config /tmp/csr.conf

# 2. Submit to CA for renewal

# 3. Receive new certificate

# 4. Verify new certificate
openssl x509 -in new-server.crt -noout -text
openssl verify -CAfile ca-chain.crt new-server.crt

# 5. Plan maintenance window

# 6. During maintenance:
systemctl stop wallix-bastion
cp new-server.crt /etc/ssl/wab/server.crt
systemctl start wallix-bastion

# 7. Verify
curl -sk https://pam4ot.company.com/ -o /dev/null -w "%{http_code}\n"
```

### Automated Renewal Monitoring

```bash
#!/bin/bash
# /opt/wab/scripts/check-cert-expiry.sh
# Run daily via cron

CERT_FILE="/etc/ssl/wab/server.crt"
WARN_DAYS=30
CRIT_DAYS=7
EMAIL="ops@company.com"

EXPIRY=$(openssl x509 -in ${CERT_FILE} -noout -enddate | cut -d= -f2)
EXPIRY_EPOCH=$(date -d "${EXPIRY}" +%s)
NOW_EPOCH=$(date +%s)
DAYS_LEFT=$(( (EXPIRY_EPOCH - NOW_EPOCH) / 86400 ))

if [ ${DAYS_LEFT} -lt ${CRIT_DAYS} ]; then
    echo "CRITICAL: PAM4OT certificate expires in ${DAYS_LEFT} days!" | \
        mail -s "[CRITICAL] PAM4OT Certificate Expiring" ${EMAIL}
elif [ ${DAYS_LEFT} -lt ${WARN_DAYS} ]; then
    echo "WARNING: PAM4OT certificate expires in ${DAYS_LEFT} days." | \
        mail -s "[WARNING] PAM4OT Certificate Expiring" ${EMAIL}
fi
```

### Prometheus Alert for Certificate Expiry

```yaml
groups:
  - name: certificate_alerts
    rules:
      - alert: PAM4OTCertExpiring
        expr: (probe_ssl_earliest_cert_expiry - time()) / 86400 < 30
        for: 1h
        labels:
          severity: warning
        annotations:
          description: "PAM4OT certificate expires in {{ $value | humanizeDuration }}"

      - alert: PAM4OTCertCritical
        expr: (probe_ssl_earliest_cert_expiry - time()) / 86400 < 7
        for: 1h
        labels:
          severity: critical
        annotations:
          description: "PAM4OT certificate expires in {{ $value | humanizeDuration }}"
```

---

## Section 5: Troubleshooting

### Common Certificate Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `certificate has expired` | Cert past end date | Renew certificate |
| `unable to get local issuer certificate` | CA not trusted | Import CA certificate |
| `certificate verify failed` | Chain incomplete | Install intermediate certs |
| `hostname mismatch` | Wrong CN/SAN | Generate cert with correct names |
| `self-signed certificate` | Not from trusted CA | Use enterprise CA |
| `certificate not yet valid` | System clock wrong | Fix system time (NTP) |

### Debug Certificate Chain

```bash
# View full certificate chain
openssl s_client -connect pam4ot.company.com:443 -showcerts

# Check certificate details
openssl x509 -in /etc/ssl/wab/server.crt -noout -text

# Verify certificate against CA
openssl verify -verbose -CAfile ca-chain.crt server.crt

# Test SSL/TLS connection
openssl s_client -connect pam4ot.company.com:443 \
    -CAfile /etc/ssl/certs/ca-certificates.crt

# Check supported TLS versions
nmap --script ssl-enum-ciphers -p 443 pam4ot.company.com
```

### Certificate Chain Issues

```bash
# Build complete certificate chain
# Order: Server Cert -> Intermediate(s) -> Root CA

# Create chain file
cat server.crt intermediate.crt > /etc/ssl/wab/server-chain.crt

# Or download missing intermediates
# Use https://whatsmychaincert.com/ to identify missing certs

# Install chain
cp server-chain.crt /etc/ssl/wab/server.crt

# Verify chain is complete
openssl verify -CAfile ca-root.crt -untrusted intermediate.crt server.crt
```

### Key Mismatch

```bash
# Check if certificate matches private key
CERT_MD5=$(openssl x509 -noout -modulus -in server.crt | openssl md5)
KEY_MD5=$(openssl rsa -noout -modulus -in server.key | openssl md5)

if [ "${CERT_MD5}" == "${KEY_MD5}" ]; then
    echo "Certificate and key MATCH"
else
    echo "ERROR: Certificate and key DO NOT MATCH"
fi
```

### Trust Store Issues

```bash
# Add CA to system trust store (Debian/Ubuntu)
cp company-ca.crt /usr/local/share/ca-certificates/
update-ca-certificates

# Verify CA is trusted
openssl verify -CApath /etc/ssl/certs/ /path/to/server.crt

# For specific applications, may need to specify CA path
curl --cacert /etc/ssl/certs/company-ca.crt https://pam4ot.company.com/
```

---

## Section 6: HA Cluster Certificates

### Cluster Certificate Synchronization

```bash
# Certificates must be identical on both nodes

# On primary node, after certificate update:
scp /etc/ssl/wab/server.crt root@pam4ot-node2:/etc/ssl/wab/
scp /etc/ssl/wab/server.key root@pam4ot-node2:/etc/ssl/wab/
scp /etc/ssl/wab/ca-chain.crt root@pam4ot-node2:/etc/ssl/wab/

# Restart services on secondary
ssh root@pam4ot-node2 "systemctl restart wallix-bastion"

# Verify both nodes
for node in pam4ot-node1 pam4ot-node2; do
    echo "=== ${node} ==="
    ssh root@${node} "openssl x509 -in /etc/ssl/wab/server.crt -noout -fingerprint"
done
```

---

## Section 7: Certificate Best Practices

### Security Requirements

| Requirement | Minimum | Recommended |
|-------------|---------|-------------|
| Key Size (RSA) | 2048 bits | 4096 bits |
| Key Size (ECC) | 256 bits | 384 bits |
| Hash Algorithm | SHA-256 | SHA-256 |
| Validity Period | ≤2 years | 1 year |
| TLS Version | TLS 1.2 | TLS 1.3 |

### Certificate Checklist

```
CERTIFICATE DEPLOYMENT CHECKLIST
================================

Before Deployment:
[ ] Certificate verified against CA chain
[ ] Key and certificate match
[ ] SANs include all required hostnames
[ ] Validity period acceptable
[ ] Key stored securely (600 permissions)
[ ] Backup of previous certificates

During Deployment:
[ ] Maintenance window scheduled
[ ] Users notified
[ ] Services stopped cleanly
[ ] Certificates installed with correct permissions
[ ] Services started successfully

After Deployment:
[ ] HTTPS responding correctly
[ ] No browser certificate warnings
[ ] API endpoints working
[ ] Session connectivity verified
[ ] Secondary node updated (HA)
[ ] Monitoring updated if needed
```

---

<p align="center">
  <a href="./README.md">← Back to Troubleshooting</a>
</p>
