# 07 - Security Hardening

## Table of Contents

1. [WALLIX 12.x Security Defaults](#wallix-12x-security-defaults)
2. [SSL/TLS Configuration](#ssltls-configuration)
3. [SSH Hardening](#ssh-hardening)
4. [Authentication Hardening](#authentication-hardening)
5. [Network Security](#network-security)
6. [IEC 62443 Compliance](#iec-62443-compliance)
7. [Audit and Monitoring](#audit-and-monitoring)

---

## WALLIX 12.x Security Defaults

WALLIX Bastion 12.x defaults to **HIGH** security level with enhanced cryptographic settings.

```
+==============================================================================+
|                   WALLIX 12.x SECURITY DEFAULTS                              |
+==============================================================================+

  SECURITY LEVEL: HIGH (default)
  ==============================

  +------------------------------------------------------------------------+
  | Setting                    | Default Value                             |
  +----------------------------+-------------------------------------------+
  | Key Derivation Function    | Argon2ID                                  |
  | Password Minimum Length    | 16 characters                             |
  | Password Complexity        | Upper, lower, digit, special required     |
  | Session Timeout            | 30 minutes                                |
  | Failed Login Lockout       | 5 attempts, 30 minute lockout            |
  | MFA Requirement            | Required for administrators               |
  | Disk Encryption            | LUKS (automatic on new installs)         |
  | Certificate Validation     | Strict (SMTP, LDAPS, etc.)                |
  +----------------------------+-------------------------------------------+

  --------------------------------------------------------------------------

  SSH CIPHER SUITE (12.x restricted)
  ==================================

  Allowed Ciphers:
  - aes256-gcm@openssh.com
  - aes128-gcm@openssh.com
  - aes256-ctr
  - aes192-ctr
  - aes128-ctr

  Allowed Key Exchange:
  - curve25519-sha256
  - curve25519-sha256@libssh.org
  - ecdh-sha2-nistp256
  - ecdh-sha2-nistp384
  - ecdh-sha2-nistp521
  - diffie-hellman-group16-sha512
  - diffie-hellman-group18-sha512

  Allowed MACs:
  - hmac-sha2-256-etm@openssh.com
  - hmac-sha2-512-etm@openssh.com
  - hmac-sha2-256
  - hmac-sha2-512

+==============================================================================+
```

### Verify Security Level

```bash
# Check current security level
wab-admin config-get security.level

# View all security settings
wab-admin security-audit

# Expected output:
# Security Level: HIGH
#
# [PASS] Password policy meets requirements
# [PASS] SSH ciphers restricted to approved set
# [PASS] TLS 1.2+ enforced
# [PASS] Disk encryption enabled
# [PASS] Argon2ID key derivation active
# [PASS] Certificate validation enabled
```

---

## SSL/TLS Configuration

### Certificate Installation

```bash
# Install production SSL certificate
wab-admin ssl-install \
    --cert /path/to/certificate.pem \
    --key /path/to/private.key \
    --chain /path/to/ca-chain.pem

# Or generate Let's Encrypt certificate
wab-admin ssl-letsencrypt \
    --domain wallix.site-a.company.com \
    --email admin@company.com \
    --auto-renew

# Verify certificate
wab-admin ssl-verify

# Expected output:
# Certificate: wallix.site-a.company.com
# Issuer: DigiCert Global CA G2
# Valid From: 2026-01-01
# Valid To: 2027-01-01
# Key Size: 4096 bits
# Signature: SHA256withRSA
# Status: Valid
```

### TLS Hardening

```bash
# Configure TLS settings
wab-admin config-set tls.min_version TLSv1.2
wab-admin config-set tls.prefer_server_ciphers true

# Set cipher suite (TLS 1.2)
wab-admin config-set tls.ciphers "ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256"

# Enable HSTS
wab-admin config-set web.hsts.enabled true
wab-admin config-set web.hsts.max_age 31536000
wab-admin config-set web.hsts.include_subdomains true

# Disable weak protocols
wab-admin config-set tls.sslv2 false
wab-admin config-set tls.sslv3 false
wab-admin config-set tls.tlsv1 false
wab-admin config-set tls.tlsv11 false
```

---

## SSH Hardening

### SSH Proxy Configuration

```bash
# Configure SSH proxy hardening
wab-admin config-set ssh.password_auth true
wab-admin config-set ssh.pubkey_auth true
wab-admin config-set ssh.keyboard_interactive true
wab-admin config-set ssh.gssapi_auth false        # Disable unless needed

# Set connection limits
wab-admin config-set ssh.max_sessions 100
wab-admin config-set ssh.login_grace_time 60
wab-admin config-set ssh.max_auth_tries 3

# Configure idle timeout
wab-admin config-set ssh.client_alive_interval 300
wab-admin config-set ssh.client_alive_count_max 3

# Disable weak algorithms
wab-admin config-set ssh.host_key_algorithms "ssh-ed25519,rsa-sha2-512,rsa-sha2-256,ecdsa-sha2-nistp256"
```

### SSH Key Management

```bash
# Generate new host keys (RSA 4096 + Ed25519)
wab-admin ssh-keygen --type rsa --bits 4096
wab-admin ssh-keygen --type ed25519

# Configure key-based authentication for target access
wab-admin config-set ssh.use_agent true
wab-admin config-set ssh.agent_forwarding false    # Disable for security

# Import SSH keys for target devices
wab-admin ssh-key-import \
    --name "scada-root-key" \
    --file /path/to/scada-root.pem \
    --passphrase-prompt \
    --devices "SCADA-Primary"
```

---

## Authentication Hardening

### Password Policy

```bash
# Configure strict password policy
wab-admin config-set auth.password.min_length 16
wab-admin config-set auth.password.require_uppercase true
wab-admin config-set auth.password.require_lowercase true
wab-admin config-set auth.password.require_digit true
wab-admin config-set auth.password.require_special true
wab-admin config-set auth.password.min_special 2
wab-admin config-set auth.password.history 12
wab-admin config-set auth.password.max_age_days 90
wab-admin config-set auth.password.min_age_days 1
```

### MFA Enforcement

```bash
# Enforce MFA for all administrators
wab-admin config-set auth.mfa.required_for_admins true
wab-admin config-set auth.mfa.required_for_ot true

# Configure TOTP settings
wab-admin config-set auth.mfa.totp.enabled true
wab-admin config-set auth.mfa.totp.issuer "WALLIX-OT"
wab-admin config-set auth.mfa.totp.digits 6
wab-admin config-set auth.mfa.totp.period 30
wab-admin config-set auth.mfa.totp.algorithm "SHA256"

# Configure recovery codes
wab-admin config-set auth.mfa.recovery.enabled true
wab-admin config-set auth.mfa.recovery.count 10
wab-admin config-set auth.mfa.recovery.length 16
```

### Account Lockout

```bash
# Configure account lockout
wab-admin config-set auth.lockout.enabled true
wab-admin config-set auth.lockout.threshold 5
wab-admin config-set auth.lockout.duration 1800      # 30 minutes
wab-admin config-set auth.lockout.reset_after 900   # 15 minutes
wab-admin config-set auth.lockout.notify_admin true
```

---

## Network Security

### IP Whitelisting

```bash
# Configure IP restrictions for admin access
wab-admin config-set access.admin.ip_whitelist "10.100.1.0/24,10.200.1.0/24"

# Configure IP restrictions for user access
wab-admin config-set access.user.ip_whitelist "10.0.0.0/8,172.16.0.0/12"

# Block known malicious ranges (example)
wab-admin config-set access.ip_blacklist "0.0.0.0/8,224.0.0.0/4"
```

### Rate Limiting

```bash
# Configure rate limiting
wab-admin config-set ratelimit.enabled true
wab-admin config-set ratelimit.login.max_attempts 10
wab-admin config-set ratelimit.login.window 60        # per minute
wab-admin config-set ratelimit.api.max_requests 100
wab-admin config-set ratelimit.api.window 60
```

### Session Security

```bash
# Configure session security
wab-admin config-set session.timeout 1800            # 30 minutes
wab-admin config-set session.absolute_timeout 28800  # 8 hours max
wab-admin config-set session.concurrent_limit 3      # Max 3 sessions per user
wab-admin config-set session.bind_ip true            # Bind session to IP
wab-admin config-set session.secure_cookie true
wab-admin config-set session.httponly_cookie true
wab-admin config-set session.samesite_cookie "Strict"
```

---

## IEC 62443 Compliance

### Security Level Configuration

```
+==============================================================================+
|                   IEC 62443 SECURITY LEVELS                                  |
+==============================================================================+

  MAP WALLIX SECURITY TO IEC 62443 ZONES
  ======================================

  +------------------------------------------------------------------------+
  | Zone              | IEC 62443 SL | WALLIX Configuration                |
  +-------------------+--------------+-------------------------------------+
  | Enterprise (L4-5) | SL 2         | Standard security                   |
  | OT DMZ (L3.5)     | SL 3         | High security + MFA                 |
  | Operations (L3)   | SL 3         | High security + session recording   |
  | Control (L2)      | SL 2         | Session recording + approval        |
  | Field (L0-1)      | SL 1         | Read-only access, full logging      |
  +-------------------+--------------+-------------------------------------+

  --------------------------------------------------------------------------

  CONFIGURE ZONE-BASED POLICIES
  =============================

  # Create zone definitions
  wab-admin zone-create --name "enterprise" --security-level 2
  wab-admin zone-create --name "ot-dmz" --security-level 3
  wab-admin zone-create --name "operations" --security-level 3
  wab-admin zone-create --name "control" --security-level 2
  wab-admin zone-create --name "field" --security-level 1

  # Apply zone policies
  wab-admin zone-policy --zone "field" --require-approval true
  wab-admin zone-policy --zone "field" --require-mfa true
  wab-admin zone-policy --zone "field" --max-session-time 3600
  wab-admin zone-policy --zone "field" --allow-write false

+==============================================================================+
```

### Compliance Reporting

```bash
# Generate IEC 62443 compliance report
wab-admin compliance-report --standard iec62443 --output /tmp/iec62443-report.pdf

# Generate NIS2 compliance report
wab-admin compliance-report --standard nis2 --output /tmp/nis2-report.pdf

# Check compliance status
wab-admin compliance-check --standard iec62443

# Expected output:
# IEC 62443 Compliance Check
# ==========================
#
# FR 1 - Identification and Authentication Control
#   [PASS] IAC-1: Human user identification
#   [PASS] IAC-2: Software process identification
#   [PASS] IAC-3: Account management
#   [PASS] IAC-4: Identifier management
#
# FR 2 - Use Control
#   [PASS] UC-1: Authorization enforcement
#   [PASS] UC-2: Wireless use control
#   [PASS] UC-3: Use control for portable devices
#
# FR 3 - System Integrity
#   [PASS] SI-1: Communication integrity
#   [PASS] SI-2: Malicious code protection
#
# FR 4 - Data Confidentiality
#   [PASS] DC-1: Information confidentiality
#   [PASS] DC-2: Use of cryptography
#
# Overall Status: COMPLIANT
```

---

## Audit and Monitoring

### Enable Comprehensive Logging

```bash
# Configure audit logging
wab-admin config-set audit.enabled true
wab-admin config-set audit.log_level info
wab-admin config-set audit.log_auth true
wab-admin config-set audit.log_sessions true
wab-admin config-set audit.log_admin_actions true
wab-admin config-set audit.log_config_changes true
wab-admin config-set audit.log_api_calls true

# Configure session recording
wab-admin config-set recording.enabled true
wab-admin config-set recording.ssh true
wab-admin config-set recording.rdp true
wab-admin config-set recording.vnc true
wab-admin config-set recording.format "native"
wab-admin config-set recording.compression true

# Configure log retention
wab-admin config-set audit.retention_days 365
wab-admin config-set recording.retention_days 180
```

### SIEM Integration

```bash
# Configure syslog forwarding
wab-admin config-set syslog.enabled true
wab-admin config-set syslog.server "10.100.1.5"
wab-admin config-set syslog.port 514
wab-admin config-set syslog.protocol "tcp"
wab-admin config-set syslog.format "cef"    # CEF format for SIEM
wab-admin config-set syslog.facility "local0"
wab-admin config-set syslog.tls true

# Test syslog connection
wab-admin syslog-test

# Configure additional SIEM (if needed)
wab-admin syslog-add \
    --name "backup-siem" \
    --server "10.200.1.5" \
    --port 514 \
    --protocol "tcp"
```

### Real-Time Alerting

```bash
# Configure security alerts
wab-admin alert-create \
    --name "failed-login-threshold" \
    --condition "failed_logins > 10" \
    --window "5m" \
    --action "email:security@company.com,syslog"
    --severity "high"

wab-admin alert-create \
    --name "admin-login-outside-hours" \
    --condition "admin_login AND (hour < 6 OR hour > 22)" \
    --action "email:security@company.com,sms:+1234567890" \
    --severity "critical"

wab-admin alert-create \
    --name "ot-zone-access" \
    --condition "zone == 'field' AND access_granted" \
    --action "syslog,webhook:https://soc.company.com/alerts" \
    --severity "info"

wab-admin alert-create \
    --name "plc-write-operation" \
    --condition "protocol == 'modbus' AND operation == 'write'" \
    --action "email:ot-security@company.com,syslog" \
    --severity "medium"
```

---

**Next Step**: [08-validation-testing.md](./08-validation-testing.md) - Validation and Testing
