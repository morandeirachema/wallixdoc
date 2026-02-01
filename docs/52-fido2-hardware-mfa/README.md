# 52 - FIDO2, WebAuthn, and Hardware Token MFA

## Table of Contents

1. [Hardware MFA Overview](#hardware-mfa-overview)
2. [FIDO2/WebAuthn Architecture](#fido2webauthn-architecture)
3. [Supported Hardware Tokens](#supported-hardware-tokens)
4. [FIDO2 Configuration](#fido2-configuration)
5. [User Enrollment](#user-enrollment)
6. [Smart Card Authentication](#smart-card-authentication)
7. [YubiKey Specific Setup](#yubikey-specific-setup)
8. [Passwordless Authentication](#passwordless-authentication)
9. [Fallback Mechanisms](#fallback-mechanisms)
10. [Offline Hardware MFA](#offline-hardware-mfa)
11. [Browser Compatibility](#browser-compatibility)
12. [Troubleshooting](#troubleshooting)

---

## Hardware MFA Overview

### Why Hardware Tokens?

Hardware tokens provide the strongest form of multi-factor authentication by offering physical proof of possession that cannot be phished, cloned, or intercepted through software attacks.

```
+==============================================================================+
|                    HARDWARE MFA VS SOFTWARE MFA COMPARISON                    |
+==============================================================================+

  AUTHENTICATION FACTORS
  ======================

  +-------------------------+------------------------------------------------+
  | Factor                  | Description                                    |
  +-------------------------+------------------------------------------------+
  | Something You Know      | Password, PIN                                  |
  | Something You Have      | Hardware token, smart card, phone              |
  | Something You Are       | Biometrics (fingerprint, face)                 |
  +-------------------------+------------------------------------------------+

  ----------------------------------------------------------------------------

  HARDWARE TOKEN ADVANTAGES
  =========================

  +-------------------------+------------------------------------------------+
  | Advantage               | Description                                    |
  +-------------------------+------------------------------------------------+
  | Phishing Resistant      | FIDO2 cryptographically binds to origin        |
  |                         | Attacker cannot replay credentials             |
  +-------------------------+------------------------------------------------+
  | No Shared Secrets       | Private keys never leave the device            |
  |                         | Server stores only public key                  |
  +-------------------------+------------------------------------------------+
  | No Network Required     | Works offline (HOTP/HMAC modes)                |
  |                         | No dependency on SMS/push services             |
  +-------------------------+------------------------------------------------+
  | Tamper Resistant        | Hardware security modules protect keys         |
  |                         | Physical attack detection                      |
  +-------------------------+------------------------------------------------+
  | No Battery Issues       | USB-powered or passive NFC                     |
  |                         | No mobile device battery dependency            |
  +-------------------------+------------------------------------------------+
  | Compliance Ready        | Meets NIST AAL3, PCI-DSS, HIPAA                |
  |                         | Required for IEC 62443 SL3+                    |
  +-------------------------+------------------------------------------------+

  ----------------------------------------------------------------------------

  COMPARISON: SOFTWARE TOTP VS HARDWARE FIDO2
  ===========================================

  +---------------------------+-------------------+---------------------------+
  | Feature                   | Software TOTP     | Hardware FIDO2            |
  +---------------------------+-------------------+---------------------------+
  | Phishing Protection       | None              | Full (origin binding)     |
  | Key Storage               | App/phone         | Secure element            |
  | Shared Secret Risk        | Yes (seed synced) | No (asymmetric)           |
  | User Experience           | Type 6 digits     | Touch/tap                 |
  | Offline Capability        | Yes               | Yes (with PIN)            |
  | Recovery Complexity       | Backup codes      | Backup tokens             |
  | Cost                      | Free              | $20-$70 per token         |
  | Compliance Level          | AAL2              | AAL3                      |
  | Attack Surface            | Phone compromise  | Physical theft only       |
  +---------------------------+-------------------+---------------------------+

+==============================================================================+
```

### Security Benefits for PAM

```
+==============================================================================+
|                   HARDWARE MFA IN PRIVILEGED ACCESS MANAGEMENT                |
+==============================================================================+

  WHY HARDWARE MFA FOR PAM?
  =========================

  Privileged accounts require the highest level of authentication assurance:

  1. CRITICAL ASSET PROTECTION
     - Admin credentials control entire infrastructure
     - Single compromised password = full breach
     - Hardware MFA adds physical barrier

  2. REGULATORY REQUIREMENTS
     - PCI-DSS: MFA required for all admin access
     - HIPAA: Strong authentication for PHI systems
     - IEC 62443: SL3+ requires hardware-based auth
     - NIS2: Critical infrastructure MFA mandates

  3. ATTACK MITIGATION
     - Credential stuffing: blocked (no reusable passwords)
     - Phishing: blocked (origin-bound authentication)
     - Man-in-the-middle: blocked (challenge-response)
     - Keyloggers: blocked (no typing required)

  ----------------------------------------------------------------------------

  WALLIX BASTION MFA ARCHITECTURE
  ================================

  +------------------------------------------------------------------------+
  |                                                                        |
  |   +------------+     +------------------+     +------------------+     |
  |   |   User     |     |   WALLIX         |     |   Target         |     |
  |   |   with     |---->|   Bastion        |---->|   Systems        |     |
  |   |   Hardware |     |                  |     |                  |     |
  |   |   Token    |     |   MFA Required:  |     |   - Servers      |     |
  |   +------------+     |   - Web UI       |     |   - Databases    |     |
  |        |             |   - SSH Proxy    |     |   - Network      |     |
  |        |             |   - RDP Proxy    |     |   - Cloud        |     |
  |        v             |   - API Access   |     |                  |     |
  |   +------------+     +------------------+     +------------------+     |
  |   | FIDO2      |              |                                        |
  |   | YubiKey    |              v                                        |
  |   | Smart Card |     +------------------+                              |
  |   +------------+     |   MFA Methods    |                              |
  |                      |   Supported:     |                              |
  |                      |                  |                              |
  |                      |   - FIDO2/       |                              |
  |                      |     WebAuthn     |                              |
  |                      |   - TOTP         |                              |
  |                      |   - RADIUS       |                              |
  |                      |   - Smart Card   |                              |
  |                      |   - PIV/CAC      |                              |
  |                      +------------------+                              |
  |                                                                        |
  +------------------------------------------------------------------------+

+==============================================================================+
```

---

## FIDO2/WebAuthn Architecture

### Protocol Overview

FIDO2 consists of two specifications:
- **WebAuthn**: W3C standard for web authentication
- **CTAP2**: Client to Authenticator Protocol for hardware tokens

```
+==============================================================================+
|                      FIDO2/WEBAUTHN ARCHITECTURE                              |
+==============================================================================+

  PROTOCOL STACK
  ==============

  +------------------------------------------------------------------------+
  |                                                                        |
  |   +------------------------+                                           |
  |   |       Application      |  WALLIX Bastion Web UI                    |
  |   +------------------------+                                           |
  |              |                                                          |
  |              v                                                          |
  |   +------------------------+                                           |
  |   |  WebAuthn JavaScript   |  navigator.credentials.create()           |
  |   |        API             |  navigator.credentials.get()              |
  |   +------------------------+                                           |
  |              |                                                          |
  |              v                                                          |
  |   +------------------------+                                           |
  |   |       Browser          |  Chrome, Firefox, Edge, Safari            |
  |   +------------------------+                                           |
  |              |                                                          |
  |              v                                                          |
  |   +------------------------+                                           |
  |   |  CTAP2 (USB/NFC/BLE)   |  Client to Authenticator Protocol         |
  |   +------------------------+                                           |
  |              |                                                          |
  |              v                                                          |
  |   +------------------------+                                           |
  |   |  Hardware Authenticator|  YubiKey, Feitian, SoloKeys               |
  |   +------------------------+                                           |
  |                                                                        |
  +------------------------------------------------------------------------+

  ----------------------------------------------------------------------------

  WEBAUTHN AUTHENTICATION FLOW
  ============================

  +------------------------------------------------------------------------+
  |                                                                        |
  |   USER         BROWSER         WALLIX           AUTHENTICATOR          |
  |     |              |           BASTION               |                 |
  |     |              |              |                  |                 |
  |     | 1. Login     |              |                  |                 |
  |     |------------->|              |                  |                 |
  |     |              |              |                  |                 |
  |     |              | 2. Request   |                  |                 |
  |     |              |    challenge |                  |                 |
  |     |              |------------->|                  |                 |
  |     |              |              |                  |                 |
  |     |              | 3. Challenge |                  |                 |
  |     |              |    + options |                  |                 |
  |     |              |<-------------|                  |                 |
  |     |              |              |                  |                 |
  |     |              | 4. navigator.credentials.get() |                 |
  |     |              |-------------------------------->|                 |
  |     |              |              |                  |                 |
  |     | 5. Touch     |              |                  |                 |
  |     |    prompt    |              |      6. Sign     |                 |
  |     |<-------------|              |         challenge|                 |
  |     |              |              |                  |                 |
  |     | 7. Touch     |              |                  |                 |
  |     |    token     |              |                  |                 |
  |     |---------------------------------------->      |                 |
  |     |              |              |                  |                 |
  |     |              | 8. Signed    |                  |                 |
  |     |              |    assertion |                  |                 |
  |     |              |<--------------------------------|                 |
  |     |              |              |                  |                 |
  |     |              | 9. Verify    |                  |                 |
  |     |              |    signature |                  |                 |
  |     |              |------------->|                  |                 |
  |     |              |              |                  |                 |
  |     |              | 10. Session  |                  |                 |
  |     |              |     granted  |                  |                 |
  |     |              |<-------------|                  |                 |
  |     |              |              |                  |                 |
  |     | 11. Access   |              |                  |                 |
  |     |     granted  |              |                  |                 |
  |     |<-------------|              |                  |                 |
  |     |              |              |                  |                 |
  +------------------------------------------------------------------------+

  ----------------------------------------------------------------------------

  CRYPTOGRAPHIC OPERATIONS
  ========================

  Registration (Credential Creation):
  -----------------------------------

  1. Server generates random challenge
  2. Browser sends challenge to authenticator
  3. Authenticator generates new key pair:
     - Private key: stored securely in hardware
     - Public key: returned to server
  4. Authenticator signs response with attestation key
  5. Server stores public key + credential ID

  Authentication:
  ---------------

  1. Server generates random challenge
  2. Browser sends challenge to authenticator with credential ID
  3. Authenticator signs challenge with private key
  4. Server verifies signature with stored public key

  +------------------------------------------------------------------------+
  |                                                                        |
  |   REGISTRATION                          AUTHENTICATION                 |
  |   ============                          ==============                 |
  |                                                                        |
  |   Server           Authenticator        Server           Authenticator |
  |      |                  |                  |                  |        |
  |      | Challenge        |                  | Challenge        |        |
  |      |----------------->|                  |----------------->|        |
  |      |                  |                  |                  |        |
  |      |    Generate      |                  |   Sign with      |        |
  |      |    key pair      |                  |   private key    |        |
  |      |                  |                  |                  |        |
  |      |<-----------------|                  |<-----------------|        |
  |      |   Public key     |                  |   Signature      |        |
  |      |   Attestation    |                  |   Auth data      |        |
  |      |                  |                  |                  |        |
  |      |   Store          |                  |   Verify with    |        |
  |      |   public key     |                  |   stored public  |        |
  |      |                  |                  |   key            |        |
  |      |                  |                  |                  |        |
  +------------------------------------------------------------------------+

+==============================================================================+
```

### Relying Party Concepts

| Term | Description |
|------|-------------|
| **Relying Party (RP)** | The server requesting authentication (WALLIX Bastion) |
| **RP ID** | Domain identifier (e.g., `bastion.company.com`) |
| **Origin** | Full URL origin bound to credential |
| **Attestation** | Proof that credential was created by genuine hardware |
| **Assertion** | Signed proof of authentication |

---

## Supported Hardware Tokens

### Compatibility Matrix

```
+==============================================================================+
|                      SUPPORTED HARDWARE TOKENS                                |
+==============================================================================+

  FIDO2/WEBAUTHN TOKENS
  =====================

  +-------------------------+----------------+--------+--------+---------------+
  | Token                   | FIDO2/WebAuthn | TOTP   | PIV    | Price (USD)   |
  +-------------------------+----------------+--------+--------+---------------+
  | YubiKey 5 NFC           | Yes            | Yes    | Yes    | $50           |
  | YubiKey 5C NFC          | Yes            | Yes    | Yes    | $55           |
  | YubiKey 5Ci             | Yes            | Yes    | Yes    | $75           |
  | YubiKey 5 Nano          | Yes            | Yes    | Yes    | $50           |
  | YubiKey Security Key    | Yes            | No     | No     | $25           |
  | Feitian ePass FIDO2     | Yes            | No     | No     | $25           |
  | Feitian BioPass FIDO2   | Yes (bio)      | No     | No     | $60           |
  | SoloKeys Solo 2         | Yes            | No     | No     | $35           |
  | Google Titan Key        | Yes            | No     | No     | $30           |
  | Thetis FIDO2            | Yes            | No     | No     | $25           |
  | Windows Hello           | Yes (platform) | No     | No     | Built-in      |
  | macOS Touch ID          | Yes (platform) | No     | No     | Built-in      |
  +-------------------------+----------------+--------+--------+---------------+

  ----------------------------------------------------------------------------

  YUBIKEY 5 SERIES (RECOMMENDED)
  ==============================

  Full-featured tokens supporting all WALLIX authentication methods:

  +------------------------------------------------------------------------+
  |                                                                        |
  |   YubiKey 5 NFC                YubiKey 5C NFC            YubiKey 5Ci   |
  |   ============                 ==============            ============  |
  |                                                                        |
  |   +----------+                 +----------+              +----------+  |
  |   |   USB-A  |                 |   USB-C  |              |  USB-C + |  |
  |   |   + NFC  |                 |   + NFC  |              | Lightning|  |
  |   +----------+                 +----------+              +----------+  |
  |                                                                        |
  |   Protocols Supported:                                                 |
  |   - FIDO2/WebAuthn (passwordless, MFA)                                 |
  |   - FIDO U2F (legacy second factor)                                    |
  |   - PIV (Smart Card / X.509)                                           |
  |   - OpenPGP (signing, encryption)                                      |
  |   - OATH-TOTP (software authenticator codes)                           |
  |   - OATH-HOTP (event-based codes)                                      |
  |   - Yubico OTP (offline validation)                                    |
  |   - Static Password (legacy systems)                                   |
  |                                                                        |
  +------------------------------------------------------------------------+

  ----------------------------------------------------------------------------

  FEITIAN EPASS SERIES
  ====================

  Cost-effective FIDO2 tokens for enterprise deployment:

  +-------------------------+------------------------------------------------+
  | Model                   | Features                                       |
  +-------------------------+------------------------------------------------+
  | ePass FIDO2-NFC         | USB-A + NFC, FIDO2 only                        |
  | ePass FIDO2-K9          | USB-A, compact form factor                     |
  | BioPass FIDO2           | USB-A + fingerprint, biometric unlock          |
  | iePass FIDO             | Lightning + USB-C, iOS compatible              |
  +-------------------------+------------------------------------------------+

  Best for: Budget-conscious deployments, large user populations

  ----------------------------------------------------------------------------

  SOLOKEYS (OPEN SOURCE)
  ======================

  Open-source hardware for transparency and auditability:

  +-------------------------+------------------------------------------------+
  | Model                   | Features                                       |
  +-------------------------+------------------------------------------------+
  | Solo 2                  | USB-A or USB-C, FIDO2, open firmware           |
  | Solo 2 NFC              | USB-A + NFC, FIDO2                             |
  +-------------------------+------------------------------------------------+

  Best for: Security-conscious organizations, firmware auditing requirements

  ----------------------------------------------------------------------------

  GOOGLE TITAN KEYS
  =================

  Google's FIDO2 security keys:

  +-------------------------+------------------------------------------------+
  | Model                   | Features                                       |
  +-------------------------+------------------------------------------------+
  | Titan Security Key      | USB-A/C + NFC, FIDO2                           |
  +-------------------------+------------------------------------------------+

  Best for: Google Workspace environments, general FIDO2 use

  ----------------------------------------------------------------------------

  PLATFORM AUTHENTICATORS
  =======================

  Built-in authenticators on devices:

  +-------------------------+------------------------------------------------+
  | Platform                | Features                                       |
  +-------------------------+------------------------------------------------+
  | Windows Hello           | PIN + biometric, TPM-backed, FIDO2             |
  | macOS Touch ID          | Fingerprint, Secure Enclave, FIDO2             |
  | Android Fingerprint     | Biometric + PIN, FIDO2                         |
  | iOS Face ID/Touch ID    | Biometric, Secure Enclave, FIDO2               |
  +-------------------------+------------------------------------------------+

  Best for: Workstation login, mobile access, user convenience

+==============================================================================+
```

### Token Selection Guide

| Use Case | Recommended Token | Reason |
|----------|-------------------|--------|
| Standard enterprise MFA | YubiKey 5 NFC | Full protocol support, durability |
| Budget deployment | Feitian ePass FIDO2 | Low cost, FIDO2 compliant |
| High-security / air-gapped | YubiKey 5 with TOTP | Offline OTP capability |
| Mobile workforce | YubiKey 5Ci or 5C NFC | Lightning/USB-C + NFC |
| Government / PIV required | YubiKey 5 with PIV | FIPS 140-2 certified models |
| Open-source requirement | SoloKeys Solo 2 | Auditable firmware |

---

## FIDO2 Configuration

### Enabling WebAuthn in WALLIX

```
+==============================================================================+
|                      FIDO2/WEBAUTHN CONFIGURATION                             |
+==============================================================================+

  STEP 1: ENABLE WEBAUTHN AUTHENTICATION
  ======================================

  Navigate to: Configuration -> Authentication -> FIDO2/WebAuthn

  Web Interface Settings:
  -----------------------

  +------------------------------------------------------------------------+
  |  FIDO2/WebAuthn Configuration                                          |
  +------------------------------------------------------------------------+
  |                                                                        |
  |  General Settings                                                      |
  |  ================                                                      |
  |                                                                        |
  |  [ ] Enable FIDO2/WebAuthn authentication                              |
  |                                                                        |
  |  Relying Party ID:     [bastion.company.com        ]                   |
  |  Relying Party Name:   [WALLIX Bastion             ]                   |
  |                                                                        |
  |  Authentication Mode:                                                  |
  |  ( ) Second factor only (requires password first)                      |
  |  ( ) Passwordless (FIDO2 resident credentials)                         |
  |  ( ) Either (user choice during enrollment)                            |
  |                                                                        |
  +------------------------------------------------------------------------+

+==============================================================================+
```

### Configuration via API

```json
{
  "webauthn_configuration": {
    "enabled": true,

    "relying_party": {
      "id": "bastion.company.com",
      "name": "WALLIX Bastion",
      "icon": "https://bastion.company.com/favicon.ico"
    },

    "authentication_settings": {
      "user_verification": "preferred",
      "resident_key": "preferred",
      "authenticator_attachment": "cross-platform",
      "timeout_ms": 60000
    },

    "attestation_settings": {
      "conveyance": "direct",
      "trusted_attestation_roots": [
        "/etc/wallix/fido2/yubico-root-ca.pem",
        "/etc/wallix/fido2/feitian-root-ca.pem"
      ],
      "allow_untrusted": false
    },

    "credential_settings": {
      "algorithms": [-7, -257],
      "max_credentials_per_user": 5,
      "credential_lifetime_days": 365
    },

    "policy": {
      "require_for_admins": true,
      "require_for_all_users": false,
      "allow_self_enrollment": true,
      "require_backup_method": true
    }
  }
}
```

### Relying Party Configuration

The Relying Party (RP) ID must match your WALLIX Bastion domain:

| Setting | Example | Notes |
|---------|---------|-------|
| **RP ID** | `bastion.company.com` | Must be a valid domain suffix |
| **RP Name** | `WALLIX Bastion PAM` | Displayed during enrollment |
| **Origin** | `https://bastion.company.com` | Must use HTTPS |

```bash
# Verify RP ID configuration
wabadmin config get webauthn.relying_party_id
# Expected: bastion.company.com

# Set RP ID
wabadmin config set webauthn.relying_party_id "bastion.company.com"

# Restart services
systemctl restart wallix-bastion
```

### Attestation Settings

Attestation verifies that credentials were created by genuine hardware tokens.

```
+==============================================================================+
|                      ATTESTATION CONFIGURATION                                |
+==============================================================================+

  ATTESTATION CONVEYANCE OPTIONS
  ==============================

  +-------------------------+------------------------------------------------+
  | Option                  | Description                                    |
  +-------------------------+------------------------------------------------+
  | none                    | No attestation requested                       |
  |                         | Lowest security, maximum compatibility         |
  +-------------------------+------------------------------------------------+
  | indirect                | Attestation may be anonymized by browser       |
  |                         | Good balance of privacy and security           |
  +-------------------------+------------------------------------------------+
  | direct                  | Full attestation chain returned                |
  |                         | Highest security, verify token authenticity    |
  +-------------------------+------------------------------------------------+
  | enterprise              | Enterprise attestation with device ID          |
  |                         | For managed device environments                |
  +-------------------------+------------------------------------------------+

  Recommendation: Use "direct" for PAM systems to verify authentic tokens

  ----------------------------------------------------------------------------

  TRUSTED ATTESTATION ROOTS
  =========================

  Download and install vendor root CA certificates:

  # YubiKey attestation root
  wget -O /etc/wallix/fido2/yubico-root-ca.pem \
    https://developers.yubico.com/U2F/yubico-u2f-ca-certs.txt

  # Feitian attestation root
  wget -O /etc/wallix/fido2/feitian-root-ca.pem \
    https://www.ftsafe.com/onlinehelp/FIDO/attestation_ca.pem

  # Verify certificate
  openssl x509 -in /etc/wallix/fido2/yubico-root-ca.pem -text -noout

  ----------------------------------------------------------------------------

  SUPPORTED ALGORITHMS
  ====================

  +--------+---------------------------+---------------------------------------+
  | COSE   | Algorithm                 | Notes                                 |
  +--------+---------------------------+---------------------------------------+
  | -7     | ES256 (ECDSA P-256)       | Recommended, widely supported         |
  | -257   | RS256 (RSA PKCS#1)        | Compatibility with older tokens       |
  | -8     | EdDSA (Ed25519)           | Modern, efficient (limited support)   |
  | -35    | ES384 (ECDSA P-384)       | Higher security (limited support)     |
  | -36    | ES512 (ECDSA P-521)       | Highest security (limited support)    |
  +--------+---------------------------+---------------------------------------+

  Configuration:

  {
    "credential_settings": {
      "algorithms": [-7, -257],
      "comment": "ES256 preferred, RS256 fallback"
    }
  }

+==============================================================================+
```

---

## User Enrollment

### Self-Service Enrollment

```
+==============================================================================+
|                      FIDO2 USER ENROLLMENT FLOW                               |
+==============================================================================+

  SELF-SERVICE ENROLLMENT STEPS
  =============================

  Step 1: User navigates to Security Settings
  -------------------------------------------

  +------------------------------------------------------------------------+
  |  My Account -> Security -> Authentication Methods                      |
  +------------------------------------------------------------------------+
  |                                                                        |
  |  Current Authentication Methods                                        |
  |  ==============================                                        |
  |                                                                        |
  |  [x] Password                         Enrolled                         |
  |  [ ] TOTP Authenticator               Not enrolled                     |
  |  [ ] Security Key (FIDO2)             Not enrolled                     |
  |  [ ] Smart Card (PIV)                 Not enrolled                     |
  |                                                                        |
  |  [+ Add Security Key]                                                  |
  |                                                                        |
  +------------------------------------------------------------------------+

  Step 2: Insert and register security key
  ----------------------------------------

  +------------------------------------------------------------------------+
  |  Register Security Key                                                 |
  +------------------------------------------------------------------------+
  |                                                                        |
  |  1. Insert your security key into a USB port                           |
  |     or place it near the NFC reader                                    |
  |                                                                        |
  |  2. Give your key a name for identification:                           |
  |     [YubiKey 5 - Primary                    ]                          |
  |                                                                        |
  |  3. Choose credential type:                                            |
  |     ( ) Second factor (requires password)                              |
  |     ( ) Passwordless (FIDO2 resident key)                              |
  |                                                                        |
  |  [Cancel]                              [Register Key]                  |
  |                                                                        |
  +------------------------------------------------------------------------+

  Step 3: Browser prompts for user verification
  ---------------------------------------------

  +------------------------------------------------------------------------+
  |                                                                        |
  |   +--------------------------------------------------+                 |
  |   |  Verify your identity                            |                 |
  |   |                                                  |                 |
  |   |  Touch your security key                         |                 |
  |   |                                                  |                 |
  |   |        +----------------+                        |                 |
  |   |        |                |                        |                 |
  |   |        |    [Touch]     |                        |                 |
  |   |        |                |                        |                 |
  |   |        +----------------+                        |                 |
  |   |                                                  |                 |
  |   |  Or enter your PIN:                              |                 |
  |   |  [********]                                      |                 |
  |   |                                                  |                 |
  |   +--------------------------------------------------+                 |
  |                                                                        |
  +------------------------------------------------------------------------+

  Step 4: Enrollment confirmation
  -------------------------------

  +------------------------------------------------------------------------+
  |  Security Key Registered Successfully                                  |
  +------------------------------------------------------------------------+
  |                                                                        |
  |  Your security key "YubiKey 5 - Primary" has been registered.          |
  |                                                                        |
  |  Key Details:                                                          |
  |  - Name: YubiKey 5 - Primary                                           |
  |  - Type: FIDO2/WebAuthn                                                |
  |  - Registered: 2026-01-31 10:45:23 UTC                                 |
  |  - Authenticator: YubiKey 5 Series                                     |
  |                                                                        |
  |  IMPORTANT: Register a backup key to avoid lockout.                    |
  |                                                                        |
  |  [Register Backup Key]        [Done]                                   |
  |                                                                        |
  +------------------------------------------------------------------------+

+==============================================================================+
```

### Admin-Assisted Enrollment

For users who cannot self-enroll or for pre-provisioning:

```bash
# Admin enrolls FIDO2 credential for user via CLI
wabadmin user fido2-enroll --username jsmith --name "YubiKey Primary"

# Output:
# Waiting for security key...
# Insert the security key and touch it when prompted.
#
# [Touch security key now]
#
# Successfully enrolled FIDO2 credential:
#   User: jsmith
#   Credential Name: YubiKey Primary
#   Credential ID: abc123...
#   Created: 2026-01-31T10:45:23Z

# List user's FIDO2 credentials
wabadmin user fido2-list --username jsmith

# Output:
# FIDO2 Credentials for jsmith:
# ID                   Name              Created              Last Used
# abc123def456...      YubiKey Primary   2026-01-31 10:45    2026-01-31 14:30
# fed987cba654...      Backup Key        2026-01-31 10:50    Never

# Revoke a FIDO2 credential
wabadmin user fido2-revoke --username jsmith --credential-id abc123def456
```

### Backup Token Registration

**Best Practice**: Always register at least two security keys per user.

```
+==============================================================================+
|                      BACKUP TOKEN STRATEGY                                    |
+==============================================================================+

  RECOMMENDED BACKUP APPROACH
  ===========================

  +------------------------------------------------------------------------+
  |                                                                        |
  |   PRIMARY KEY                              BACKUP KEY                  |
  |   ===========                              ==========                  |
  |                                                                        |
  |   +------------------+                     +------------------+        |
  |   |   YubiKey 5      |                     |   YubiKey 5      |        |
  |   |   (On keychain)  |                     |   (In safe)      |        |
  |   +------------------+                     +------------------+        |
  |          |                                        |                    |
  |          v                                        v                    |
  |   Daily use                                Emergency recovery          |
  |   - Always carried                         - Secure storage            |
  |   - First choice                           - Tested quarterly          |
  |                                                                        |
  +------------------------------------------------------------------------+

  BACKUP REGISTRATION PROCESS
  ===========================

  1. User registers primary key
  2. System prompts for backup registration
  3. User registers second key
  4. Backup key stored securely (safe, lockbox)
  5. Quarterly verification of backup key functionality

  ADMIN ENFORCEMENT
  =================

  {
    "enrollment_policy": {
      "require_backup_key": true,
      "min_credentials": 2,
      "grace_period_days": 7,
      "notify_missing_backup": true
    }
  }

+==============================================================================+
```

### Enrollment via API

```python
#!/usr/bin/env python3
"""
FIDO2 Enrollment API Example
"""

import requests
import json

BASTION_URL = "https://bastion.company.com"
API_KEY = "your-api-key"

def initiate_fido2_enrollment(username: str, credential_name: str):
    """
    Initiate FIDO2 credential enrollment for a user.
    Returns challenge for WebAuthn registration.
    """
    response = requests.post(
        f"{BASTION_URL}/api/v3/users/{username}/fido2/register/begin",
        headers={
            "Authorization": f"Bearer {API_KEY}",
            "Content-Type": "application/json"
        },
        json={
            "credential_name": credential_name,
            "authenticator_selection": {
                "authenticator_attachment": "cross-platform",
                "resident_key": "preferred",
                "user_verification": "preferred"
            },
            "attestation": "direct"
        }
    )

    return response.json()

def complete_fido2_enrollment(username: str, attestation_response: dict):
    """
    Complete FIDO2 enrollment with attestation response from authenticator.
    """
    response = requests.post(
        f"{BASTION_URL}/api/v3/users/{username}/fido2/register/complete",
        headers={
            "Authorization": f"Bearer {API_KEY}",
            "Content-Type": "application/json"
        },
        json=attestation_response
    )

    return response.json()

def list_fido2_credentials(username: str):
    """
    List all FIDO2 credentials for a user.
    """
    response = requests.get(
        f"{BASTION_URL}/api/v3/users/{username}/fido2/credentials",
        headers={
            "Authorization": f"Bearer {API_KEY}"
        }
    )

    return response.json()

def revoke_fido2_credential(username: str, credential_id: str):
    """
    Revoke a FIDO2 credential.
    """
    response = requests.delete(
        f"{BASTION_URL}/api/v3/users/{username}/fido2/credentials/{credential_id}",
        headers={
            "Authorization": f"Bearer {API_KEY}"
        }
    )

    return response.status_code == 204

# Example usage
if __name__ == "__main__":
    # List existing credentials
    creds = list_fido2_credentials("jsmith")
    print(f"Current credentials: {json.dumps(creds, indent=2)}")
```

---

## Smart Card Authentication

### PIV/CAC Card Support

```
+==============================================================================+
|                      SMART CARD / PIV AUTHENTICATION                          |
+==============================================================================+

  OVERVIEW
  ========

  PIV (Personal Identity Verification) and CAC (Common Access Card) use
  X.509 certificates stored on smart cards for authentication.

  +------------------------------------------------------------------------+
  |                                                                        |
  |   SMART CARD AUTHENTICATION FLOW                                       |
  |   ===============================                                      |
  |                                                                        |
  |   +------------+     +------------+     +------------------+           |
  |   |   User     |     |   Card     |     |   WALLIX         |           |
  |   |   Smart    |---->|   Reader   |---->|   Bastion        |           |
  |   |   Card     |     |            |     |                  |           |
  |   +------------+     +------------+     +------------------+           |
  |        |                                       |                       |
  |        |                                       v                       |
  |        |                                +------------------+           |
  |        |                                |   Certificate    |           |
  |        |                                |   Validation     |           |
  |        |                                +------------------+           |
  |        |                                       |                       |
  |        |                              +--------+--------+              |
  |        |                              |                 |              |
  |        |                              v                 v              |
  |        v                        +----------+      +----------+         |
  |   +-----------+                 |   Local  |      |   OCSP/  |         |
  |   |   Enter   |                 |   CA     |      |   CRL    |         |
  |   |   PIN     |                 |   Trust  |      |   Check  |         |
  |   +-----------+                 +----------+      +----------+         |
  |                                                                        |
  +------------------------------------------------------------------------+

  ----------------------------------------------------------------------------

  PIV CERTIFICATE SLOTS
  =====================

  +--------+---------------------------+---------------------------------------+
  | Slot   | Certificate Type          | Purpose                               |
  +--------+---------------------------+---------------------------------------+
  | 9a     | PIV Authentication        | Login, authentication                 |
  | 9c     | Digital Signature         | Document signing                      |
  | 9d     | Key Management            | Encryption/decryption                 |
  | 9e     | Card Authentication       | Physical access, door locks           |
  +--------+---------------------------+---------------------------------------+

  WALLIX uses slot 9a (PIV Authentication) by default.

  ----------------------------------------------------------------------------

  SUPPORTED SMART CARDS
  =====================

  +-------------------------+------------------------------------------------+
  | Card Type               | Notes                                          |
  +-------------------------+------------------------------------------------+
  | YubiKey 5 (PIV)         | FIPS 140-2 certified models available          |
  | US Federal PIV          | Government-issued PIV cards                    |
  | DoD CAC                  | Common Access Card for military               |
  | Gemalto IDPrime         | Enterprise smart cards                         |
  | Thales SafeNet          | Enterprise smart cards                         |
  | OpenSC compatible       | Various open-standard cards                    |
  +-------------------------+------------------------------------------------+

+==============================================================================+
```

### Certificate Mapping

Configure how smart card certificates map to WALLIX users:

```json
{
  "smart_card_configuration": {
    "enabled": true,

    "certificate_settings": {
      "slot": "9a",
      "pin_required": true,
      "pin_policy": "once_per_session"
    },

    "trust_settings": {
      "trusted_ca_certificates": [
        "/etc/wallix/pki/enterprise-root-ca.pem",
        "/etc/wallix/pki/enterprise-issuing-ca.pem"
      ],
      "crl_check": true,
      "crl_distribution_points": true,
      "ocsp_check": true,
      "ocsp_responder": "http://ocsp.company.com"
    },

    "user_mapping": {
      "method": "subject_dn",
      "subject_dn_attribute": "CN",
      "alternative_mapping": "upn",
      "upn_domain_filter": "@company.com"
    },

    "fallback": {
      "allow_password_fallback": true,
      "fallback_reason_codes": ["PIN_LOCKED", "CARD_NOT_PRESENT"]
    }
  }
}
```

### User Mapping Options

| Mapping Method | Certificate Field | Example Value | WALLIX Username |
|----------------|-------------------|---------------|-----------------|
| **CN (Common Name)** | Subject CN | John Smith | jsmith |
| **UPN (User Principal Name)** | SAN:UPN | jsmith@company.com | jsmith |
| **Email** | SAN:Email | john.smith@company.com | john.smith |
| **Serial Number** | Subject SerialNumber | 12345 | 12345 |

### Reader Configuration

```bash
# Install PC/SC daemon and tools
apt-get install -y pcscd pcsc-tools opensc

# Start and enable PC/SC daemon
systemctl enable pcscd
systemctl start pcscd

# Test card reader detection
pcsc_scan

# Expected output:
# Reader 0: Yubico YubiKey OTP+FIDO+CCID 00 00
# Card state: Card inserted
# ATR: 3B F8 13 00 00 81 31 FE 15 ...

# List certificates on smart card
pkcs15-tool --list-certificates

# Test certificate authentication
pkcs11-tool --module /usr/lib/opensc-pkcs11.so --login --test

# Configure WALLIX to use PC/SC
wabadmin config set smartcard.pcsc_library "/usr/lib/x86_64-linux-gnu/libpcsclite.so.1"
wabadmin config set smartcard.enabled true
```

---

## YubiKey Specific Setup

### FIDO2 Mode Configuration

```
+==============================================================================+
|                      YUBIKEY FIDO2 CONFIGURATION                              |
+==============================================================================+

  YUBIKEY MANAGER SETUP
  =====================

  Install YubiKey Manager:
  ------------------------

  # Debian/Ubuntu
  apt-get install -y yubikey-manager

  # Or download from Yubico
  # https://www.yubico.com/support/download/yubikey-manager/

  ----------------------------------------------------------------------------

  CONFIGURE FIDO2 PIN
  ===================

  A FIDO2 PIN is required for user verification:

  # Check current FIDO2 status
  ykman fido info

  # Output:
  # FIDO2 supported: true
  # PIN configured: false
  # Minimum PIN length: 4
  # Credential count: 0

  # Set FIDO2 PIN
  ykman fido access change-pin

  # Enter new PIN (6+ characters recommended)
  # Enter new PIN: ********
  # Confirm PIN: ********
  # PIN set successfully.

  ----------------------------------------------------------------------------

  MANAGE FIDO2 CREDENTIALS
  ========================

  # List FIDO2 credentials (requires PIN)
  ykman fido credentials list

  # Output:
  # Relying Party         Username      Credential ID
  # bastion.company.com   jsmith        abc123...
  # bastion.company.com   jsmith        def456... (backup)

  # Delete a credential
  ykman fido credentials delete abc123...

  # Reset FIDO2 application (WARNING: deletes all credentials)
  ykman fido reset

  ----------------------------------------------------------------------------

  YUBIKEY APPLICATION CONFIGURATION
  =================================

  Configure which YubiKey applications are enabled:

  # List current configuration
  ykman config usb

  # Output:
  # USB Interface configuration:
  #   OTP: enabled
  #   FIDO U2F: enabled
  #   FIDO2: enabled
  #   OATH: enabled
  #   PIV: enabled
  #   OpenPGP: enabled

  # For FIDO2-only deployment (disable unused features)
  ykman config usb --disable OTP --disable OATH --disable OpenPGP

  # For full-featured deployment (all enabled)
  ykman config usb --enable-all

+==============================================================================+
```

### OTP Slot Configuration for Offline Use

```
+==============================================================================+
|                      YUBIKEY OTP FOR AIR-GAPPED ENVIRONMENTS                  |
+==============================================================================+

  YUBICO OTP OVERVIEW
  ===================

  Yubico OTP works offline without internet connectivity:

  - 44-character one-time password
  - AES-128 encrypted
  - Counter-based (no time synchronization needed)
  - Validated against local database or YubiCloud

  +------------------------------------------------------------------------+
  |                                                                        |
  |   OFFLINE OTP FLOW                                                     |
  |   ================                                                     |
  |                                                                        |
  |   +------------+     +------------------+     +------------------+     |
  |   |   User     |     |   WALLIX         |     |   Local OTP      |     |
  |   |   touches  |---->|   Bastion        |---->|   Validation     |     |
  |   |   YubiKey  |     |                  |     |   Server         |     |
  |   +------------+     +------------------+     +------------------+     |
  |        |                                             |                 |
  |        v                                             v                 |
  |   OTP Generated:                              Validate against         |
  |   ccccccbchvrb...                             stored AES key           |
  |   (44 chars)                                  and counter              |
  |                                                                        |
  +------------------------------------------------------------------------+

  ----------------------------------------------------------------------------

  CONFIGURE YUBIKEY OTP SLOT
  ==========================

  YubiKeys have two slots for OTP configuration:

  +--------+------------------+-----------------------------------------------+
  | Slot   | Activation       | Typical Use                                   |
  +--------+------------------+-----------------------------------------------+
  | Slot 1 | Short touch      | Primary OTP (Yubico OTP or custom)            |
  | Slot 2 | Long touch (2s)  | Secondary OTP or static password              |
  +--------+------------------+-----------------------------------------------+

  Program Yubico OTP:
  -------------------

  # Generate new Yubico OTP credential
  ykman otp yubiotp 1 --generate-key --generate-private-id

  # Output includes:
  # Serial: 12345678
  # Public ID: ccccccbchvrb
  # Private ID: a1b2c3d4e5f6
  # AES Key: 0123456789abcdef0123456789abcdef

  # IMPORTANT: Save these values for local validation server!

  Program Challenge-Response (HMAC-SHA1):
  ---------------------------------------

  # Configure slot 2 for HMAC-SHA1 challenge-response
  ykman otp chalresp 2 --generate

  # Output:
  # Using slot 2.
  # Generated key: 0123456789abcdef0123456789abcdef01234567

  ----------------------------------------------------------------------------

  LOCAL OTP VALIDATION SERVER
  ===========================

  For air-gapped environments, deploy a local YubiKey validation server:

  1. Install YubiKey Validation Server (ykval)

  # Clone and install
  git clone https://github.com/Yubico/yubikey-val.git
  cd yubikey-val
  # Follow installation instructions

  2. Import YubiKey credentials

  {
    "yubikeys": [
      {
        "serial": "12345678",
        "public_id": "ccccccbchvrb",
        "private_id": "a1b2c3d4e5f6",
        "aes_key": "0123456789abcdef0123456789abcdef",
        "user": "jsmith"
      }
    ]
  }

  3. Configure WALLIX to use local validation

  {
    "yubikey_otp": {
      "enabled": true,
      "validation_mode": "local",
      "validation_servers": [
        "http://localhost:8080/wsapi/2.0/verify"
      ],
      "client_id": 1,
      "api_key": "local-api-key"
    }
  }

+==============================================================================+
```

### PIV Certificate Loading

```bash
#!/bin/bash
# Load PIV certificate onto YubiKey for smart card authentication

# Generate key pair on YubiKey (slot 9a - PIV Authentication)
ykman piv keys generate --algorithm RSA2048 9a public.pem

# Create Certificate Signing Request
ykman piv certificates request 9a public.pem csr.pem \
    --subject "CN=John Smith,O=Company Inc,C=US"

# Submit CSR to your CA and receive signed certificate
# (This step depends on your PKI infrastructure)

# Import signed certificate
ykman piv certificates import 9a signed-cert.pem

# Verify certificate
ykman piv info

# Expected output:
# PIV version: 5.4.3
# PIN tries remaining: 3
# Slot 9a (PIV Authentication):
#   Algorithm: RSA2048
#   Subject: CN=John Smith,O=Company Inc,C=US
#   Issuer: CN=Company Issuing CA,O=Company Inc,C=US
#   Serial: 12345678
#   Not before: 2026-01-01
#   Not after: 2027-01-01

# Set PIV PIN (different from FIDO2 PIN)
ykman piv access change-pin

# Set PUK (PIN Unlock Key) for recovery
ykman piv access change-puk

# Set management key for admin operations
ykman piv access change-management-key --generate --protect
```

---

## Passwordless Authentication

### Enabling Passwordless with FIDO2

```
+==============================================================================+
|                      PASSWORDLESS AUTHENTICATION                              |
+==============================================================================+

  OVERVIEW
  ========

  Passwordless authentication eliminates passwords entirely, using FIDO2
  resident credentials (discoverable credentials) stored on the security key.

  +------------------------------------------------------------------------+
  |                                                                        |
  |   TRADITIONAL MFA               PASSWORDLESS                           |
  |   ===============               ============                           |
  |                                                                        |
  |   1. Enter username             1. Insert security key                 |
  |   2. Enter password             2. Enter PIN (or biometric)            |
  |   3. Touch security key         3. Touch security key                  |
  |                                                                        |
  |   3 steps                       2 steps                                |
  |   Password vulnerable           No password to phish                   |
  |                                                                        |
  +------------------------------------------------------------------------+

  ----------------------------------------------------------------------------

  RESIDENT CREDENTIALS
  ====================

  Resident (discoverable) credentials store the username on the security key:

  +------------------------------------------------------------------------+
  |                                                                        |
  |   SECURITY KEY STORAGE                                                 |
  |   ====================                                                 |
  |                                                                        |
  |   +----------------------------------------------------------+        |
  |   |  YubiKey 5 Series                                        |        |
  |   |                                                          |        |
  |   |  Credential 1:                                           |        |
  |   |    RP: bastion.company.com                               |        |
  |   |    User: jsmith                                          |        |
  |   |    Private Key: [stored securely]                        |        |
  |   |                                                          |        |
  |   |  Credential 2:                                           |        |
  |   |    RP: bastion.company.com                               |        |
  |   |    User: admin                                           |        |
  |   |    Private Key: [stored securely]                        |        |
  |   |                                                          |        |
  |   |  (Up to 25 resident credentials on YubiKey 5)            |        |
  |   +----------------------------------------------------------+        |
  |                                                                        |
  +------------------------------------------------------------------------+

  ----------------------------------------------------------------------------

  CONFIGURATION
  =============

  Enable passwordless in WALLIX:

  {
    "passwordless_configuration": {
      "enabled": true,

      "credential_requirements": {
        "resident_key": "required",
        "user_verification": "required",
        "authenticator_attachment": "cross-platform"
      },

      "enrollment": {
        "require_password_first": true,
        "verify_identity_method": "existing_mfa"
      },

      "session_policy": {
        "session_lifetime_hours": 8,
        "require_reverification_minutes": 30,
        "sensitive_action_reverification": true
      },

      "fallback": {
        "allow_password_fallback": false,
        "emergency_access_procedure": "helpdesk_approval"
      }
    }
  }

+==============================================================================+
```

### Resident Credentials Setup

```bash
# Check YubiKey resident credential capacity
ykman fido info

# Output:
# FIDO2 supported: true
# PIN configured: true
# Resident credentials: 3/25

# List resident credentials
ykman fido credentials list

# Output:
# Relying Party         Username      Credential ID
# bastion.company.com   jsmith        abc123def456...
# bastion.company.com   admin         fed987cba654...

# Delete specific credential
ykman fido credentials delete --credential-id abc123def456

# Note: YubiKey 5 series supports up to 25 resident credentials
# YubiKey 5 FIPS supports up to 25 resident credentials
# Older YubiKey 4 does not support resident credentials
```

### Passwordless Login Flow

```
+==============================================================================+
|                      PASSWORDLESS LOGIN FLOW                                  |
+==============================================================================+

  USER EXPERIENCE
  ===============

  +------------------------------------------------------------------------+
  |                                                                        |
  |   WALLIX Bastion Login                                                 |
  |   ====================                                                 |
  |                                                                        |
  |   +--------------------------------------------------+                 |
  |   |                                                  |                 |
  |   |  Welcome to WALLIX Bastion                       |                 |
  |   |                                                  |                 |
  |   |  Sign in with:                                   |                 |
  |   |                                                  |                 |
  |   |  [   Sign in with Security Key   ]               |                 |
  |   |                                                  |                 |
  |   |  --------- or ---------                          |                 |
  |   |                                                  |                 |
  |   |  Username: [                    ]                |                 |
  |   |  Password: [                    ]                |                 |
  |   |                                                  |                 |
  |   |  [         Sign In              ]                |                 |
  |   |                                                  |                 |
  |   +--------------------------------------------------+                 |
  |                                                                        |
  +------------------------------------------------------------------------+

  After clicking "Sign in with Security Key":
  -------------------------------------------

  +------------------------------------------------------------------------+
  |                                                                        |
  |   +--------------------------------------------------+                 |
  |   |  Use your security key                           |                 |
  |   |                                                  |                 |
  |   |  Insert your security key and enter your PIN     |                 |
  |   |                                                  |                 |
  |   |  PIN: [********]                                 |                 |
  |   |                                                  |                 |
  |   |  Then touch the security key                     |                 |
  |   |                                                  |                 |
  |   |        +----------------+                        |                 |
  |   |        |    [Touch]     |                        |                 |
  |   |        +----------------+                        |                 |
  |   |                                                  |                 |
  |   +--------------------------------------------------+                 |
  |                                                                        |
  +------------------------------------------------------------------------+

  Multiple Accounts Selection:
  ----------------------------

  If multiple resident credentials exist for the same RP:

  +------------------------------------------------------------------------+
  |                                                                        |
  |   +--------------------------------------------------+                 |
  |   |  Choose an account                               |                 |
  |   |                                                  |                 |
  |   |  [x] jsmith (John Smith)                         |                 |
  |   |  [ ] admin (Administrator)                       |                 |
  |   |                                                  |                 |
  |   |  [Continue]                                      |                 |
  |   |                                                  |                 |
  |   +--------------------------------------------------+                 |
  |                                                                        |
  +------------------------------------------------------------------------+

+==============================================================================+
```

---

## Fallback Mechanisms

### Lost Token Procedures

```
+==============================================================================+
|                      LOST TOKEN RECOVERY PROCEDURES                           |
+==============================================================================+

  SCENARIO 1: USER HAS BACKUP TOKEN
  =================================

  Recommended approach - use registered backup token:

  1. User logs in with backup security key
  2. User navigates to Security Settings
  3. User revokes lost primary key
  4. User registers new primary key
  5. Backup key remains active

  ----------------------------------------------------------------------------

  SCENARIO 2: NO BACKUP TOKEN AVAILABLE
  =====================================

  Emergency recovery procedure:

  +------------------------------------------------------------------------+
  |                                                                        |
  |   STEP 1: USER CONTACTS HELPDESK                                       |
  |   ================================                                     |
  |                                                                        |
  |   - User calls helpdesk                                                |
  |   - Identity verified via:                                             |
  |     - Security questions                                               |
  |     - Manager approval                                                 |
  |     - HR verification                                                  |
  |     - Video call verification                                          |
  |                                                                        |
  +------------------------------------------------------------------------+
  |                                                                        |
  |   STEP 2: ADMIN GENERATES BYPASS CODE                                  |
  |   ====================================                                 |
  |                                                                        |
  |   # Generate one-time bypass code                                      |
  |   wabadmin user mfa-bypass --username jsmith --reason "Lost token"     |
  |                                                                        |
  |   Output:                                                              |
  |   Bypass code: ABC123-DEF456-GHI789                                    |
  |   Valid for: 15 minutes                                                |
  |   Single use: Yes                                                      |
  |                                                                        |
  +------------------------------------------------------------------------+
  |                                                                        |
  |   STEP 3: USER LOGS IN WITH BYPASS CODE                                |
  |   =====================================                                |
  |                                                                        |
  |   - User enters username/password                                      |
  |   - At MFA prompt, selects "Use bypass code"                           |
  |   - User enters bypass code                                            |
  |   - User gains temporary access                                        |
  |                                                                        |
  +------------------------------------------------------------------------+
  |                                                                        |
  |   STEP 4: USER ENROLLS NEW TOKEN                                       |
  |   ================================                                     |
  |                                                                        |
  |   - User immediately registers new security key                        |
  |   - User registers backup key                                          |
  |   - Old credentials automatically revoked                              |
  |                                                                        |
  +------------------------------------------------------------------------+

  ----------------------------------------------------------------------------

  ADMIN COMMANDS FOR RECOVERY
  ===========================

  # Generate MFA bypass code
  wabadmin user mfa-bypass --username jsmith \
    --reason "Lost token - ticket #12345" \
    --validity-minutes 15

  # Temporarily disable MFA (emergency only)
  wabadmin user mfa-disable --username jsmith \
    --reason "Emergency recovery - ticket #12345" \
    --duration-hours 1

  # Revoke all FIDO2 credentials
  wabadmin user fido2-revoke-all --username jsmith \
    --reason "Token compromise - ticket #12345"

  # Force re-enrollment
  wabadmin user fido2-require-enrollment --username jsmith

  # View MFA audit log
  wabadmin audit mfa --username jsmith --last-days 30

+==============================================================================+
```

### Backup Codes Configuration

```json
{
  "backup_codes_configuration": {
    "enabled": true,

    "code_settings": {
      "count": 10,
      "length": 8,
      "format": "XXXX-XXXX",
      "single_use": true
    },

    "generation_policy": {
      "generate_on_enrollment": true,
      "regenerate_when_low": 3,
      "require_secure_display": true
    },

    "usage_policy": {
      "notify_admin_on_use": true,
      "require_new_mfa_after_use": true,
      "max_uses_before_lockout": 3
    }
  }
}
```

### Recovery Workflow

```
+==============================================================================+
|                      COMPLETE RECOVERY WORKFLOW                               |
+==============================================================================+

  RECOVERY DECISION TREE
  ======================

  +------------------------------------------------------------------------+
  |                                                                        |
  |                     Token Lost/Stolen?                                 |
  |                           |                                            |
  |              +------------+------------+                               |
  |              |                         |                               |
  |              v                         v                               |
  |         Lost only                 Stolen/Compromised                   |
  |              |                         |                               |
  |              |                         v                               |
  |              |                  IMMEDIATE:                             |
  |              |                  - Revoke all credentials               |
  |              |                  - Alert security team                  |
  |              |                  - Review access logs                   |
  |              |                         |                               |
  |              v                         v                               |
  |         Has Backup?               Investigation                        |
  |              |                         |                               |
  |         +----+----+                    |                               |
  |         |         |                    |                               |
  |        YES       NO                    |                               |
  |         |         |                    |                               |
  |         v         v                    v                               |
  |   Use backup   Identity         Clear all sessions                     |
  |   token        verification     Force password reset                   |
  |         |         |                    |                               |
  |         v         v                    v                               |
  |   Revoke lost  Bypass code      Supervised re-enrollment               |
  |   credential       |                                                   |
  |         |         |                                                    |
  |         v         v                                                    |
  |   Register    Register                                                 |
  |   new token   new token                                                |
  |         |         |                                                    |
  |         +----+----+                                                    |
  |              |                                                         |
  |              v                                                         |
  |   Register backup token                                                |
  |   Update emergency contacts                                            |
  |                                                                        |
  +------------------------------------------------------------------------+

+==============================================================================+
```

---

## Offline Hardware MFA

### YubiKey OTP for Air-Gapped Environments

```
+==============================================================================+
|                      OFFLINE MFA FOR AIR-GAPPED SYSTEMS                       |
+==============================================================================+

  SUPPORTED OFFLINE METHODS
  =========================

  +-------------------------+------------------------------------------------+
  | Method                  | Air-Gap Compatibility                          |
  +-------------------------+------------------------------------------------+
  | YubiKey OTP             | FULLY COMPATIBLE                               |
  |                         | - Local validation server                      |
  |                         | - No internet required                         |
  |                         | - Counter-based (no NTP needed)                |
  +-------------------------+------------------------------------------------+
  | HMAC-SHA1 Challenge-    | FULLY COMPATIBLE                               |
  | Response                | - Direct challenge-response                    |
  |                         | - No server needed                             |
  |                         | - Requires PAM integration                     |
  +-------------------------+------------------------------------------------+
  | FIDO2 (PIN only)        | PARTIALLY COMPATIBLE                           |
  |                         | - Works for local auth                         |
  |                         | - No attestation verification                  |
  +-------------------------+------------------------------------------------+
  | TOTP (local)            | COMPATIBLE                                     |
  |                         | - Requires accurate NTP                        |
  |                         | - Local RADIUS validation                      |
  +-------------------------+------------------------------------------------+

  ----------------------------------------------------------------------------

  YUBIKEY OTP LOCAL VALIDATION
  ============================

  Architecture for air-gapped YubiKey OTP:

  +------------------------------------------------------------------------+
  |                                                                        |
  |   AIR-GAPPED NETWORK                                                   |
  |   ==================                                                   |
  |                                                                        |
  |   +------------+     +------------------+     +------------------+     |
  |   |   User     |     |   WALLIX         |     |   Local OTP      |     |
  |   |   with     |---->|   Bastion        |---->|   Validation     |     |
  |   |   YubiKey  |     |                  |     |   Server         |     |
  |   +------------+     +------------------+     +------------------+     |
  |        |                                             |                 |
  |        v                                             v                 |
  |   Touch YubiKey                               +------------------+     |
  |   generates OTP:                              |   YubiKey        |     |
  |   ccccccbchvrbhe...                           |   Database       |     |
  |                                               |   - Serial       |     |
  |                                               |   - Public ID    |     |
  |                                               |   - Private ID   |     |
  |                                               |   - AES Key      |     |
  |                                               |   - Counter      |     |
  |                                               +------------------+     |
  |                                                                        |
  +------------------------------------------------------------------------+

  ----------------------------------------------------------------------------

  SETUP LOCAL VALIDATION SERVER
  =============================

  1. Export YubiKey credentials during programming:

  ykman otp yubiotp 1 --generate-key --generate-private-id

  # Save output:
  # Serial: 12345678
  # Public ID: ccccccbchvrb
  # Private ID: a1b2c3d4e5f6
  # AES Key: 0123456789abcdef0123456789abcdef

  2. Import into local validation server database:

  -- SQL schema for YubiKey validation
  CREATE TABLE yubikeys (
      id SERIAL PRIMARY KEY,
      serial_number VARCHAR(20) NOT NULL,
      public_id VARCHAR(32) NOT NULL UNIQUE,
      private_id VARCHAR(12) NOT NULL,
      aes_key VARCHAR(32) NOT NULL,
      counter INTEGER DEFAULT 0,
      session_counter INTEGER DEFAULT 0,
      username VARCHAR(100) NOT NULL,
      active BOOLEAN DEFAULT TRUE,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );

  INSERT INTO yubikeys (serial_number, public_id, private_id, aes_key, username)
  VALUES ('12345678', 'ccccccbchvrb', 'a1b2c3d4e5f6',
          '0123456789abcdef0123456789abcdef', 'jsmith');

  3. Configure WALLIX to use local validation:

  {
    "yubikey_otp": {
      "enabled": true,
      "mode": "local",
      "local_validation": {
        "database": "postgresql://localhost/yubikey_val",
        "connection_pool_size": 5
      }
    }
  }

+==============================================================================+
```

### HMAC-SHA1 Challenge-Response

```
+==============================================================================+
|                      HMAC-SHA1 CHALLENGE-RESPONSE                             |
+==============================================================================+

  OVERVIEW
  ========

  HMAC-SHA1 challenge-response provides offline MFA without any server:

  +------------------------------------------------------------------------+
  |                                                                        |
  |   CHALLENGE-RESPONSE FLOW                                              |
  |   ========================                                             |
  |                                                                        |
  |   +------------+     +------------------+     +------------------+     |
  |   |   WALLIX   |     |   User           |     |   YubiKey        |     |
  |   |   Bastion  |     |   Workstation    |     |   (Slot 2)       |     |
  |   +------+-----+     +--------+---------+     +--------+---------+     |
  |          |                    |                        |               |
  |          | 1. Generate        |                        |               |
  |          |    challenge       |                        |               |
  |          |------------------->|                        |               |
  |          |                    |                        |               |
  |          |                    | 2. Send challenge      |               |
  |          |                    |    to YubiKey          |               |
  |          |                    |----------------------->|               |
  |          |                    |                        |               |
  |          |                    |                        | 3. HMAC-SHA1  |
  |          |                    |                        |    with stored|
  |          |                    |                        |    secret     |
  |          |                    |                        |               |
  |          |                    | 4. Response            |               |
  |          |                    |<-----------------------|               |
  |          |                    |                        |               |
  |          | 5. Verify response |                        |               |
  |          |<-------------------|                        |               |
  |          |                    |                        |               |
  |          | 6. Access granted  |                        |               |
  |          |------------------->|                        |               |
  |          |                    |                        |               |
  +------------------------------------------------------------------------+

  ----------------------------------------------------------------------------

  CONFIGURATION
  =============

  1. Program YubiKey slot 2 for challenge-response:

  # Generate and program secret
  ykman otp chalresp 2 --generate --require-touch

  # Output:
  # Using slot 2.
  # Generated key: 0123456789abcdef0123456789abcdef01234567
  # Touch required: true

  # SAVE THIS KEY for WALLIX configuration!

  2. Test challenge-response manually:

  # Send challenge to YubiKey
  ykchalresp -2 "test challenge"

  # Touch YubiKey when LED blinks
  # Output: 64-character hex response

  3. Configure WALLIX for challenge-response:

  {
    "challenge_response_mfa": {
      "enabled": true,
      "slot": 2,
      "require_touch": true,
      "challenge_length": 32,
      "response_timeout_seconds": 30
    }
  }

  4. Store user's HMAC secret in WALLIX:

  wabadmin user chalresp-enroll --username jsmith \
    --secret 0123456789abcdef0123456789abcdef01234567

  ----------------------------------------------------------------------------

  PAM INTEGRATION
  ===============

  For SSH/console authentication via challenge-response:

  # /etc/pam.d/wallix-auth
  auth required pam_yubico.so mode=challenge-response chalresp_path=/var/yubico

  # Create challenge-response mapping
  mkdir -p /var/yubico
  ykpamcfg -2 -v

  # This creates /var/yubico/jsmith-12345678

+==============================================================================+
```

---

## Browser Compatibility

### Supported Browsers and Versions

```
+==============================================================================+
|                      BROWSER COMPATIBILITY MATRIX                             |
+==============================================================================+

  WEBAUTHN/FIDO2 BROWSER SUPPORT
  ==============================

  +-------------------------+----------+----------+-----+---------------------+
  | Browser                 | Windows  | macOS    |Linux| Mobile              |
  +-------------------------+----------+----------+-----+---------------------+
  | Google Chrome 67+       | Full     | Full     | Full| Android 7+, iOS 14+ |
  | Mozilla Firefox 60+     | Full     | Full     | Full| Android, iOS 14+    |
  | Microsoft Edge 79+      | Full     | Full     | Full| Android             |
  | Safari 14+              | Full     | Full     | N/A | iOS 14+             |
  | Opera 54+               | Full     | Full     | Full| Android             |
  | Brave 1.0+              | Full     | Full     | Full| Android             |
  +-------------------------+----------+----------+-----+---------------------+

  Minimum recommended versions for full FIDO2 support:
  - Chrome 89+ (resident credentials)
  - Firefox 85+ (resident credentials)
  - Edge 89+ (resident credentials)
  - Safari 14+ (Touch ID/Face ID)

  ----------------------------------------------------------------------------

  PLATFORM AUTHENTICATOR SUPPORT
  ==============================

  +-------------------------+------------------------------------------------+
  | Platform                | Built-in Authenticator                         |
  +-------------------------+------------------------------------------------+
  | Windows 10/11           | Windows Hello (PIN, fingerprint, face)         |
  |                         | TPM 2.0 required for full support              |
  +-------------------------+------------------------------------------------+
  | macOS 11+               | Touch ID (fingerprint)                         |
  |                         | Secure Enclave backed                          |
  +-------------------------+------------------------------------------------+
  | iOS 14+                 | Face ID, Touch ID                              |
  |                         | Safari and apps via ASWebAuthenticationSession |
  +-------------------------+------------------------------------------------+
  | Android 7+              | Fingerprint, PIN, face unlock                  |
  |                         | Chrome and apps                                |
  +-------------------------+------------------------------------------------+
  | ChromeOS                | Built-in fingerprint sensor (if available)     |
  +-------------------------+------------------------------------------------+
  | Linux                   | No platform authenticator                      |
  |                         | Requires external USB/NFC token                |
  +-------------------------+------------------------------------------------+

  ----------------------------------------------------------------------------

  TRANSPORT SUPPORT
  =================

  +-------------------------+----------+----------+----------+-----------------+
  | Transport               | Chrome   | Firefox  | Safari   | Edge            |
  +-------------------------+----------+----------+----------+-----------------+
  | USB                     | Yes      | Yes      | Yes      | Yes             |
  | NFC                     | Android  | Android  | No       | Android         |
  | Bluetooth (BLE)         | Limited  | No       | No       | Limited         |
  | Internal (platform)     | Yes      | Yes      | Yes      | Yes             |
  +-------------------------+----------+----------+----------+-----------------+

  Note: BLE support is deprecated in favor of NFC and USB

  ----------------------------------------------------------------------------

  CORPORATE BROWSER CONFIGURATION
  ===============================

  Ensure WebAuthn APIs are enabled in managed browsers:

  Chrome Enterprise Policy:
  ------------------------
  {
    "WebAuthnEnabled": true,
    "WebAuthnSecurityKeyAllowed": true,
    "WebAuthnPlatformAllowed": true
  }

  Firefox Enterprise Policy:
  --------------------------
  {
    "policies": {
      "SecurityDevices": {
        "Add": {
          "PKCS11Module": "/usr/lib/libykcs11.so"
        }
      }
    }
  }

+==============================================================================+
```

### Known Browser Issues

| Browser | Issue | Workaround |
|---------|-------|------------|
| Chrome on Linux | USB permission denied | Add udev rules for FIDO devices |
| Firefox on macOS | Touch ID not working | Use external authenticator |
| Safari | NFC not supported | Use USB or Touch ID |
| Edge Legacy | WebAuthn not supported | Upgrade to Edge Chromium |

### Linux udev Rules for USB Tokens

```bash
# /etc/udev/rules.d/70-fido.rules
# FIDO/U2F USB device rules

# YubiKey
KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1050", MODE="0660", GROUP="plugdev"

# Feitian
KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="096e", MODE="0660", GROUP="plugdev"

# SoloKeys
KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="0483", MODE="0660", GROUP="plugdev"

# Google Titan
KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="18d1", MODE="0660", GROUP="plugdev"

# Generic FIDO2
KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1050", ATTRS{idProduct}=="0402", MODE="0660", GROUP="plugdev"

# Reload rules
# udevadm control --reload-rules && udevadm trigger

# Add user to plugdev group
# usermod -aG plugdev $USER
```

---

## Troubleshooting

### Token Not Recognized

```
+==============================================================================+
|                      TROUBLESHOOTING: TOKEN NOT RECOGNIZED                    |
+==============================================================================+

  SYMPTOM: Security key not detected by browser or system

  DIAGNOSTIC STEPS
  ================

  1. Check physical connection:
     - USB fully inserted
     - Try different USB port
     - Try USB 2.0 port if USB 3.0 fails
     - Check for debris in connector

  2. Verify device detection (Linux):

     # Check USB device
     lsusb | grep -i yubico

     # Expected output:
     # Bus 001 Device 005: ID 1050:0407 Yubico.com Yubikey 4/5 OTP+U2F+CCID

     # Check HID device
     ls -la /dev/hidraw*

     # Check permissions
     cat /sys/bus/usb/devices/*/product | grep -i yubi

  3. Check browser console for errors:
     - Open Developer Tools (F12)
     - Check Console tab for WebAuthn errors
     - Look for "NotAllowedError" or "SecurityError"

  4. Verify FIDO2 functionality:

     # Install ykman
     apt-get install -y yubikey-manager

     # Check YubiKey status
     ykman info

     # Check FIDO2 status
     ykman fido info

  ----------------------------------------------------------------------------

  COMMON CAUSES AND SOLUTIONS
  ===========================

  +-------------------------+------------------------------------------------+
  | Cause                   | Solution                                       |
  +-------------------------+------------------------------------------------+
  | USB permissions         | Add udev rules, add user to plugdev group      |
  | Browser popup blocked   | Allow popups for WALLIX site                   |
  | HTTPS required          | Ensure using https:// URL                      |
  | Old browser             | Update to latest browser version               |
  | FIDO2 disabled          | Enable FIDO2 on YubiKey: ykman config usb      |
  | Wrong USB mode          | YubiKey in CCID-only mode: reconfigure         |
  +-------------------------+------------------------------------------------+

  ----------------------------------------------------------------------------

  LINUX-SPECIFIC FIXES
  ====================

  # Install required packages
  apt-get install -y libu2f-udev pcscd pcsc-tools

  # Create udev rules
  cat > /etc/udev/rules.d/70-u2f.rules << 'EOF'
  KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1050", MODE="0660", GROUP="plugdev"
  EOF

  # Reload udev
  udevadm control --reload-rules
  udevadm trigger

  # Add user to group
  usermod -aG plugdev $USER

  # Re-login or reboot

+==============================================================================+
```

### Attestation Failures

```
+==============================================================================+
|                      TROUBLESHOOTING: ATTESTATION FAILURES                    |
+==============================================================================+

  SYMPTOM: Registration fails with attestation verification error

  DIAGNOSTIC STEPS
  ================

  1. Check attestation configuration:

     wabadmin config get webauthn.attestation_conveyance
     # Should return: direct, indirect, or none

  2. Verify trusted attestation roots:

     wabadmin config get webauthn.trusted_attestation_roots
     # Should list CA certificate paths

  3. Check certificate validity:

     openssl x509 -in /etc/wallix/fido2/yubico-root-ca.pem -text -noout
     # Verify not expired

  4. Test with attestation disabled:

     # Temporarily set attestation to "none"
     wabadmin config set webauthn.attestation_conveyance "none"
     systemctl restart wallix-bastion

     # If enrollment succeeds, issue is with attestation verification

  ----------------------------------------------------------------------------

  COMMON CAUSES AND SOLUTIONS
  ===========================

  +-------------------------+------------------------------------------------+
  | Error                   | Solution                                       |
  +-------------------------+------------------------------------------------+
  | Unknown attestation CA  | Add vendor root CA to trusted roots            |
  | Attestation expired     | Update attestation CA certificates             |
  | Self-attestation        | Set allow_self_attestation: true               |
  | Anonymous attestation   | Use indirect or none conveyance                |
  +-------------------------+------------------------------------------------+

  ----------------------------------------------------------------------------

  DOWNLOAD ATTESTATION ROOTS
  ==========================

  # YubiKey attestation
  curl -o /etc/wallix/fido2/yubico-root-ca.pem \
    https://developers.yubico.com/U2F/yubico-u2f-ca-certs.txt

  # FIDO Alliance Metadata Service
  curl -o /etc/wallix/fido2/fido-mds.jwt \
    https://mds.fidoalliance.org/

  # Verify downloaded certificates
  openssl x509 -in /etc/wallix/fido2/yubico-root-ca.pem -text -noout | head -20

  # Restart WALLIX
  systemctl restart wallix-bastion

+==============================================================================+
```

### Browser Issues

```
+==============================================================================+
|                      TROUBLESHOOTING: BROWSER ISSUES                          |
+==============================================================================+

  COMMON BROWSER ERRORS
  =====================

  +------------------------------------------------------------------------+
  |  Error: NotAllowedError: The operation either timed out or was         |
  |         not allowed.                                                   |
  +------------------------------------------------------------------------+

  Causes:
  - User didn't touch the security key in time
  - Operation was cancelled
  - Page not served over HTTPS
  - Popup was blocked

  Solutions:
  - Increase timeout: "timeout_ms": 120000
  - Ensure HTTPS is used
  - Allow popups for the site
  - Check user touched key when prompted

  +------------------------------------------------------------------------+
  |  Error: SecurityError: The operation is insecure.                      |
  +------------------------------------------------------------------------+

  Causes:
  - HTTP instead of HTTPS
  - Invalid SSL certificate
  - Mixed content

  Solutions:
  - Always use HTTPS
  - Install valid SSL certificate
  - Fix mixed content warnings

  +------------------------------------------------------------------------+
  |  Error: InvalidStateError: The user attempted to register an           |
  |         authenticator that contains one of the credentials already     |
  |         registered.                                                    |
  +------------------------------------------------------------------------+

  Causes:
  - Key already registered for this user
  - Duplicate credential ID

  Solutions:
  - Delete existing credential first
  - Use different key for backup
  - Check for existing registrations: ykman fido credentials list

  +------------------------------------------------------------------------+
  |  Error: ConstraintError: The relying party ID is not a registrable     |
  |         domain suffix of, nor equal to, the current origin.            |
  +------------------------------------------------------------------------+

  Causes:
  - RP ID doesn't match domain
  - Wrong origin configuration

  Solutions:
  - Set RP ID to match domain: bastion.company.com
  - Ensure origin matches: https://bastion.company.com

  ----------------------------------------------------------------------------

  BROWSER DEBUG LOGGING
  =====================

  Chrome:
  -------
  # Enable WebAuthn logging
  chrome://flags/#enable-web-authentication-caBLE-logging

  # View console logs
  Developer Tools (F12) -> Console
  # Filter: webauthn

  Firefox:
  --------
  # Enable security device logging
  about:config
  security.webauthn.log_level = "debug"

  # View logs
  about:debugging -> This Firefox -> Web Console

  Edge:
  -----
  # Similar to Chrome
  edge://flags/#enable-web-authentication-caBLE-logging

  ----------------------------------------------------------------------------

  BROWSER POLICY ISSUES
  =====================

  Enterprise browsers may have WebAuthn disabled by policy.

  Check Chrome policies:
  chrome://policy/

  Look for:
  - WebAuthnEnabled: should be "true"
  - SecurityKeyPermitAttestation: should include your domain

  Check Firefox policies:
  about:policies

  Check Edge policies:
  edge://policy/

+==============================================================================+
```

### Diagnostic Script

```bash
#!/bin/bash
# /usr/local/bin/fido2-diagnostics.sh
# FIDO2/WebAuthn diagnostic script for WALLIX Bastion

echo "========================================"
echo "WALLIX Bastion FIDO2/WebAuthn Diagnostics"
echo "Date: $(date)"
echo "========================================"

# 1. Check WALLIX WebAuthn configuration
echo -e "\n[1] WebAuthn Configuration"
echo "------------------------"
wabadmin config get webauthn.enabled 2>/dev/null || echo "Command not available"
wabadmin config get webauthn.relying_party_id 2>/dev/null || echo "N/A"

# 2. Check USB devices
echo -e "\n[2] USB Security Keys Detected"
echo "-----------------------------"
lsusb | grep -iE "yubico|feitian|fido|solo" || echo "No FIDO devices found via lsusb"

# 3. Check HID devices
echo -e "\n[3] HID Device Permissions"
echo "-------------------------"
if ls /dev/hidraw* 2>/dev/null; then
    ls -la /dev/hidraw*
else
    echo "No hidraw devices found"
fi

# 4. Check YubiKey Manager
echo -e "\n[4] YubiKey Status"
echo "------------------"
if command -v ykman &> /dev/null; then
    ykman list 2>/dev/null || echo "No YubiKey detected"
    if ykman list 2>/dev/null | grep -q "YubiKey"; then
        echo -e "\nFIDO2 Info:"
        ykman fido info 2>/dev/null || echo "FIDO2 info not available"
    fi
else
    echo "ykman not installed"
fi

# 5. Check PCSC daemon
echo -e "\n[5] PC/SC Daemon Status"
echo "----------------------"
systemctl is-active pcscd 2>/dev/null || echo "pcscd status unknown"

# 6. Check udev rules
echo -e "\n[6] FIDO udev Rules"
echo "-------------------"
if [ -f /etc/udev/rules.d/70-u2f.rules ] || [ -f /etc/udev/rules.d/70-fido.rules ]; then
    ls -la /etc/udev/rules.d/*fido* /etc/udev/rules.d/*u2f* 2>/dev/null
    echo "Rules exist"
else
    echo "WARNING: No FIDO udev rules found"
fi

# 7. Check attestation certificates
echo -e "\n[7] Attestation Certificates"
echo "---------------------------"
CERT_DIR="/etc/wallix/fido2"
if [ -d "$CERT_DIR" ]; then
    for cert in "$CERT_DIR"/*.pem; do
        if [ -f "$cert" ]; then
            echo "Certificate: $cert"
            openssl x509 -in "$cert" -noout -subject -enddate 2>/dev/null
        fi
    done
else
    echo "Certificate directory not found: $CERT_DIR"
fi

# 8. Check SSL configuration
echo -e "\n[8] SSL Configuration"
echo "--------------------"
if command -v openssl &> /dev/null; then
    HOSTNAME=$(hostname -f)
    echo | openssl s_client -connect localhost:443 2>/dev/null | openssl x509 -noout -subject -issuer 2>/dev/null || echo "SSL check failed"
fi

# 9. Recent FIDO2 log entries
echo -e "\n[9] Recent FIDO2 Logs"
echo "--------------------"
if [ -f /var/log/wallix/bastion/auth.log ]; then
    grep -i "fido\|webauthn\|credential" /var/log/wallix/bastion/auth.log 2>/dev/null | tail -10 || echo "No FIDO2 entries found"
else
    echo "Auth log not found"
fi

echo -e "\n========================================"
echo "Diagnostics complete"
echo "========================================"
```

---

## References

- [WebAuthn Specification (W3C)](https://www.w3.org/TR/webauthn-2/)
- [FIDO2 Specifications (FIDO Alliance)](https://fidoalliance.org/fido2/)
- [CTAP2 Protocol](https://fidoalliance.org/specs/fido-v2.1-ps-20210615/fido-client-to-authenticator-protocol-v2.1-ps-20210615.html)
- [YubiKey Technical Documentation](https://developers.yubico.com/)
- [WebAuthn.io (Testing Tool)](https://webauthn.io/)
- [WALLIX Documentation Portal](https://pam.wallix.one/documentation)
- [WALLIX Administration Guide](https://pam.wallix.one/documentation/admin-doc/bastion_en_administration_guide.pdf)
- [NIST SP 800-63B Digital Identity Guidelines](https://pages.nist.gov/800-63-3/sp800-63b.html)

---

## Next Steps

Continue to [05 - Authentication](../05-authentication/README.md) for an overview of all authentication methods, or see [19 - Air-Gapped Environments](../19-airgapped-environments/README.md) for offline MFA strategies in isolated networks.
