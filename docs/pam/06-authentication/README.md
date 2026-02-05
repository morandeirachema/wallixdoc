# 05 - Authentication & Identity

## Table of Contents

1. [Authentication Overview](#authentication-overview)
2. [Local Authentication](#local-authentication)
3. [LDAP/Active Directory Integration](#ldapactive-directory-integration)
4. [RADIUS Authentication](#radius-authentication)
5. [Multi-Factor Authentication (MFA)](#multi-factor-authentication-mfa)
6. [Kerberos & SSO](#kerberos--sso)
7. [SAML Federation](#saml-federation)
8. [OpenID Connect (OIDC)](#openid-connect-oidc) *(New in 12.x)*
9. [Certificate-Based Authentication](#certificate-based-authentication)
10. [Authentication Chaining](#authentication-chaining)

---

## Authentication Overview

### Authentication Layers

WALLIX Bastion supports multiple authentication layers:

```
+=============================================================================+
|                      AUTHENTICATION ARCHITECTURE                            |
+=============================================================================+
|                                                                             |
|   USER                                                                      |
|     |                                                                       |
|     |  Step 1: Primary Authentication                                       |
|     |  -----------------------------------                                  |
|     v                                                                       |
|   +---------------------------------------------------------------------+   |
|   |                    PRIMARY AUTHENTICATION                           |   |
|   |                                                                     |   |
|   |  +-------+ +-------+ +-------+ +-------+ +-------+ +-------+        |   |
|   |  | Local | | LDAP/ | |RADIUS | |Kerber.| | SAML  | | OIDC  |        |   |
|   |  |       | |  AD   | |       | |       | |       | | (12.x)|        |   |
|   |  +-------+ +-------+ +-------+ +-------+ +-------+ +-------+        |   |
|   |                                                                     |   |
|   +---------------------------------------------------------------------+   |
|     |                                                                       |
|     |  Step 2: Multi-Factor Authentication (Optional but Recommended)       |
|     |  -------------------------------------------------------------        |
|     v                                                                       |
|   +---------------------------------------------------------------------+   |
|   |                    SECOND FACTOR                                    |   |
|   |                                                                     |   |
|   |  +---------+  +---------+  +---------+  +---------+  +---------+    |   |
|   |  |FortiToken|  |  RADIUS |  |   SMS   |  |  Push   |  |  X.509  |    |   |
|   |  |         |  |  (OTP)  |  |         |  |         |  |  Cert   |    |   |
|   |  +---------+  +---------+  +---------+  +---------+  +---------+    |   |
|   |                                                                     |   |
|   +---------------------------------------------------------------------+   |
|     |                                                                       |
|     |  Step 3: Authorization Check                                          |
|     |  ---------------------------                                          |
|     v                                                                       |
|   +---------------------------------------------------------------------+   |
|   |                    SESSION ESTABLISHED                              |   |
|   +---------------------------------------------------------------------+   |
|                                                                             |
+=============================================================================+
```

### Authentication Methods Summary

| Method | Primary Auth | MFA Capable | SSO | Use Case |
|--------|-------------|-------------|-----|----------|
| **Local** | Yes | Via FortiToken | No | Small deployments |
| **LDAP/AD** | Yes | Via external | No | Enterprise standard |
| **RADIUS** | Yes | Native | No | MFA integration |
| **Kerberos** | Yes | Via external | Yes | Windows SSO |
| **SAML** | Yes | Via IdP | Yes | Federation/cloud |
| **X.509** | Yes | Inherent | Yes | High security |

---

## Local Authentication

### Overview

Local authentication stores user credentials directly in WALLIX Bastion's database.

### Configuration

```
Local User Configuration
========================

User Settings:
+-- Username: jsmith
+-- Password: [Encrypted in database]
+-- Password Policy: Strong (12+ chars, complexity)
+-- Password Expiry: 90 days
+-- Account Lockout: 5 failed attempts
+-- MFA: FortiToken enabled
```

### Password Policy Configuration

```json
{
  "password_policy": {
    "name": "default",
    "min_length": 12,
    "require_uppercase": true,
    "require_lowercase": true,
    "require_digits": true,
    "require_special": true,
    "max_age_days": 90,
    "history_count": 12,
    "lockout_threshold": 5,
    "lockout_duration_minutes": 30
  }
}
```

### Use Cases

| Scenario | Recommendation |
|----------|----------------|
| Small organizations (<50 users) | Acceptable |
| Emergency/break-glass accounts | Recommended |
| Service accounts | Acceptable |
| Enterprise deployments | Use LDAP/AD instead |

> **Best Practice**: Even with LDAP/AD, maintain a few local admin accounts for emergency access when directory services are unavailable.

---

## LDAP/Active Directory Integration

### Overview

LDAP/AD integration allows WALLIX to authenticate users against existing directory services.

**CyberArk Comparison**: Similar to LDAP integration in CyberArk, with vault/directory sync.

### Architecture

```
+=============================================================================+
|                      LDAP/AD INTEGRATION                                    |
+=============================================================================+
|                                                                             |
|   +----------+          +-------------+          +------------------+       |
|   |   User   |----------|   WALLIX    |----------|   Active         |       |
|   |          |  Login   |   Bastion   |  LDAP    |   Directory      |       |
|   +----------+          +------+------+  Bind    +------------------+       |
|                                |                                            |
|                                |                                            |
|                         +------+------+                                     |
|                         |             |                                     |
|                         v             v                                     |
|                  +-------------+ +-------------+                            |
|                  | User Auth   | | Group Sync  |                            |
|                  |             | |             |                            |
|                  | * Validate  | | * Fetch     |                            |
|                  |   password  | |   groups    |                            |
|                  | * Get user  | | * Map to    |                            |
|                  |   attributes| |   WALLIX    |                            |
|                  |             | |   groups    |                            |
|                  +-------------+ +-------------+                            |
|                                                                             |
+=============================================================================+
```

### LDAP Configuration

#### Basic LDAP Settings

```json
{
  "ldap_configuration": {
    "name": "Corporate-AD",
    "enabled": true,

    "connection": {
      "host": "dc01.corp.company.com",
      "port": 636,
      "use_ssl": true,
      "ssl_verify": true,
      "timeout_seconds": 30
    },

    "bind_credentials": {
      "bind_dn": "CN=svc_wallix,OU=Service Accounts,DC=corp,DC=company,DC=com",
      "bind_password": "********"
    },

    "search_settings": {
      "base_dn": "DC=corp,DC=company,DC=com",
      "user_filter": "(&(objectClass=user)(sAMAccountName={login}))",
      "user_scope": "subtree"
    },

    "attribute_mapping": {
      "login": "sAMAccountName",
      "display_name": "displayName",
      "email": "mail",
      "groups": "memberOf"
    }
  }
}
```

#### LDAPS (Secure LDAP)

| Setting | Value | Notes |
|---------|-------|-------|
| Port | 636 | Standard LDAPS |
| SSL | Required | Always use encryption |
| Certificate | Trusted CA | Validate server cert |

> **Security**: Never use plain LDAP (port 389) in production. Always use LDAPS (port 636).

### Active Directory Specifics

#### AD User Filter Examples

| Filter | Description |
|--------|-------------|
| `(&(objectClass=user)(sAMAccountName={login}))` | Standard user lookup |
| `(&(objectClass=user)(userPrincipalName={login}))` | UPN-based lookup |
| `(&(objectClass=user)(sAMAccountName={login})(!(userAccountControl:1.2.840.113556.1.4.803:=2)))` | Exclude disabled |

#### AD Group Mapping

```json
{
  "group_mappings": [
    {
      "ldap_group": "CN=PAM-Linux-Admins,OU=PAM,OU=Groups,DC=corp,DC=company,DC=com",
      "wallix_group": "Linux-Admins",
      "sync_mode": "automatic"
    },
    {
      "ldap_group": "CN=PAM-DBA-Team,OU=PAM,OU=Groups,DC=corp,DC=company,DC=com",
      "wallix_group": "DBA-Team",
      "sync_mode": "automatic"
    }
  ]
}
```

### Multiple Domain Support

```
Multi-Domain Configuration
==========================

+------------------+     +------------------+
|   corp.company   |     |  dmz.company     |
|      .com        |     |     .com         |
+--------+---------+     +--------+---------+
         |                        |
         +-----------+------------+
                     |
              +------+------+
              |   WALLIX    |
              |   Bastion   |
              +-------------+

Configuration:
+-- LDAP Source 1: corp.company.com
|   +-- User format: CORP\username
+-- LDAP Source 2: dmz.company.com
    +-- User format: DMZ\username
```

---

## RADIUS Authentication

### Overview

RADIUS provides flexible authentication, often used for MFA integration with various vendors.

### Configuration

```json
{
  "radius_configuration": {
    "name": "MFA-RADIUS",
    "enabled": true,

    "servers": [
      {
        "host": "radius1.company.com",
        "port": 1812,
        "secret": "********",
        "timeout_seconds": 10,
        "retries": 3
      },
      {
        "host": "radius2.company.com",
        "port": 1812,
        "secret": "********",
        "timeout_seconds": 10,
        "retries": 3
      }
    ],

    "authentication": {
      "protocol": "PAP",
      "nas_identifier": "WALLIX-Bastion"
    }
  }
}
```

### RADIUS Protocol Options

| Protocol | Description | Security |
|----------|-------------|----------|
| **PAP** | Password Auth Protocol | Password sent encrypted with shared secret |
| **CHAP** | Challenge-Handshake | More secure, may not work with all MFA |
| **MS-CHAPv2** | Microsoft CHAP | Windows integration |

### MFA Vendors via RADIUS

| Vendor | Integration Method | Notes |
|--------|-------------------|-------|
| RSA SecurID | RADIUS | Native support |
| Duo Security | RADIUS | Duo Auth Proxy |
| Microsoft Azure MFA | RADIUS/NPS | NPS extension |
| Okta | RADIUS | Okta RADIUS Agent |
| CyberArk Identity | RADIUS | Cloud connector |

---

## Multi-Factor Authentication (MFA)

### Overview

WALLIX supports multiple MFA methods for enhanced security.

### MFA Methods

```
+=============================================================================+
|                          MFA METHODS                                        |
+=============================================================================+
|                                                                             |
|   +-----------------+  +-----------------+  +-----------------+             |
|   |      FortiToken       |  |     RADIUS      |  |   PUSH/SMS      |             |
|   |                 |  |     (OTP)       |  |                 |             |
|   |  * Google Auth  |  |  * RSA SecurID  |  |  * Trustelem    |             |
|   |  * Microsoft    |  |  * Duo          |  |  * External     |             |
|   |    Authenticator|  |  * Azure MFA    |  |    gateway      |             |
|   |  * Authy        |  |  * Okta         |  |                 |             |
|   |                 |  |                 |  |                 |             |
|   +-----------------+  +-----------------+  +-----------------+             |
|                                                                             |
|   +-----------------+  +-----------------+                                  |
|   |   CERTIFICATE   |  |    WEBAUTHN     |                                  |
|   |                 |  |    FortiToken      |                                  |
|   |  * FortiToken  |  |  * FortiToken      |                                  |
|   |  * PKI certs    |  |  * Windows      |                                  |
|   |                 |  |    Hello        |                                  |
|   +-----------------+  +-----------------+                                  |
|                                                                             |
+=============================================================================+
```

### FortiToken Configuration

#### Enable FortiToken for User

```json
{
  "user": "jsmith",
  "mfa_settings": {
    "enabled": true,
    "method": "totp",
    "totp_settings": {
      "algorithm": "SHA1",
      "digits": 6,
      "period": 30
    }
  }
}
```

#### FortiToken Enrollment Flow

```
FortiToken Enrollment
===============

1. Admin enables FortiToken for user
           |
           v
2. User logs in (redirected to enrollment)
           |
           v
3. WALLIX generates secret key
           |
           v
4. User scans QR code with authenticator app
           |
           v
5. User enters verification code
           |
           v
6. FortiToken enrolled successfully
```

### MFA Policy Configuration

```json
{
  "mfa_policy": {
    "name": "standard-mfa",

    "requirements": {
      "all_users": false,
      "admin_users": true,
      "sensitive_targets": true
    },

    "methods_allowed": ["totp", "radius"],

    "bypass_conditions": {
      "trusted_networks": ["10.0.0.0/8"],
      "service_accounts": true
    },

    "session_settings": {
      "remember_device_hours": 8,
      "require_per_session": false
    }
  }
}
```

### MFA Bypass (Use Carefully)

| Scenario | Configuration | Risk |
|----------|---------------|------|
| Trusted networks | IP whitelist | Medium - network compromise |
| Service accounts | Account flag | Low if properly secured |
| Emergency access | Break-glass | Acceptable with auditing |

> **Warning**: MFA bypass should be used sparingly and with compensating controls (logging, alerting, review).

---

## Kerberos & SSO

### Overview

Kerberos enables Single Sign-On (SSO) for Windows environments.

**CyberArk Comparison**: Similar to Windows authentication in PVWA.

### Architecture

```
+=============================================================================+
|                      KERBEROS SSO FLOW                                      |
+=============================================================================+
|                                                                             |
|   +----------+     +----------+     +----------+     +--------------+       |
|   |   User   |     |   KDC    |     |  WALLIX  |     |    Target    |       |
|   |  (Domain |     |  (AD DC) |     | Bastion  |     |    Server    |       |
|   |  Joined) |     |          |     |          |     |              |       |
|   +----+-----+     +----+-----+     +----+-----+     +------+-------+       |
|        |                |                |                  |               |
|        | 1. Login       |                |                  |               |
|        |--------------->|                |                  |               |
|        |                |                |                  |               |
|        | 2. TGT         |                |                  |               |
|        |<---------------|                |                  |               |
|        |                |                |                  |               |
|        | 3. Access WALLIX (with TGT)     |                  |               |
|        |-------------------------------->|                  |               |
|        |                |                |                  |               |
|        |                | 4. Validate    |                  |               |
|        |                |    ticket      |                  |               |
|        |                |<---------------|                  |               |
|        |                |--------------->|                  |               |
|        |                |                |                  |               |
|        | 5. SSO - No password prompt     |                  |               |
|        |<--------------------------------|                  |               |
|        |                |                |                  |               |
|        | 6. Session established          |                  |               |
|        |-------------------------------->|----------------->|               |
|        |                |                |                  |               |
|                                                                             |
+=============================================================================+
```

### Kerberos Configuration

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
    "keytab_file": "/etc/krb5.keytab"
  }
}
```

### Service Principal Setup

```bash
# On Active Directory (create service account)
# Create account: svc_wallix_krb

# Set SPN
setspn -A HTTP/bastion.corp.company.com svc_wallix_krb

# Generate keytab
ktpass -out wallix.keytab \
       -princ HTTP/bastion.corp.company.com@CORP.COMPANY.COM \
       -mapuser svc_wallix_krb \
       -pass <password> \
       -ptype KRB5_NT_PRINCIPAL \
       -crypto AES256-CTS-HMAC-SHA1-96
```

---

## SAML Federation

### Overview

SAML 2.0 enables federation with identity providers (IdP) for SSO.

### SAML Flow

```
+=============================================================================+
|                          SAML SSO FLOW                                      |
+=============================================================================+
|                                                                             |
|   +----------+           +----------+           +------------------+        |
|   |   User   |           |  WALLIX  |           |   Identity       |        |
|   | Browser  |           | Bastion  |           |   Provider       |        |
|   |          |           |   (SP)   |           |   (IdP)          |        |
|   +----+-----+           +----+-----+           +--------+---------+        |
|        |                      |                          |                  |
|        | 1. Access WALLIX     |                          |                  |
|        |--------------------->|                          |                  |
|        |                      |                          |                  |
|        | 2. Redirect to IdP (SAML AuthnRequest)          |                  |
|        |<---------------------|                          |                  |
|        |-------------------------------------------------------->           |
|        |                      |                          |                  |
|        | 3. Authenticate at IdP                          |                  |
|        |<--------------------------------------------------------|          |
|        |                      |                          |                  |
|        | 4. SAML Response (Assertion)                    |                  |
|        |<--------------------------------------------------------|          |
|        |--------------------->|                          |                  |
|        |                      |                          |                  |
|        |                      | 5. Validate assertion    |                  |
|        |                      |    Extract attributes    |                  |
|        |                      |                          |                  |
|        | 6. Session created   |                          |                  |
|        |<---------------------|                          |                  |
|        |                      |                          |                  |
|                                                                             |
+=============================================================================+
```

### SAML Configuration

```json
{
  "saml_configuration": {
    "enabled": true,
    "entity_id": "https://bastion.company.com/saml/metadata",

    "identity_provider": {
      "name": "Corporate-IdP",
      "metadata_url": "https://idp.company.com/saml/metadata",
      "sso_url": "https://idp.company.com/saml/sso",
      "certificate": "-----BEGIN CERTIFICATE-----..."
    },

    "service_provider": {
      "acs_url": "https://bastion.company.com/saml/acs",
      "slo_url": "https://bastion.company.com/saml/slo",
      "certificate": "-----BEGIN CERTIFICATE-----...",
      "private_key": "-----BEGIN PRIVATE KEY-----..."
    },

    "attribute_mapping": {
      "username": "urn:oid:0.9.2342.19200300.100.1.1",
      "email": "urn:oid:0.9.2342.19200300.100.1.3",
      "display_name": "urn:oid:2.5.4.3",
      "groups": "urn:oid:1.3.6.1.4.1.5923.1.5.1.1"
    }
  }
}
```

### Supported Identity Providers

| IdP | Notes |
|-----|-------|
| Azure AD | Full support |
| Okta | Full support |
| Ping Identity | Full support |
| ADFS | Full support |
| Google Workspace | Full support |
| WALLIX Trustelem | Native integration |

---

## OpenID Connect (OIDC)

*New in WALLIX Bastion 12.x*

### Overview

OpenID Connect (OIDC) provides seamless authentication with identity providers supporting the standard. This integration enhances security and simplifies user access management through Single Sign-On (SSO).

### Key Features

- **Single Sign-On (SSO)**: Users can access Bastion without repeatedly entering credentials
- **Standard Compliance**: Full OpenID Connect 1.0 specification support
- **Multiple IdP Support**: Azure AD, Okta, Google, Keycloak, and others
- **Token-Based**: Secure JWT token authentication

### Configuration

```json
{
  "oidc": {
    "enabled": true,
    "provider_url": "https://login.microsoftonline.com/{tenant-id}/v2.0",
    "client_id": "your-client-id",
    "client_secret": "<CLIENT_SECRET>",
    "scopes": ["openid", "profile", "email"],
    "redirect_uri": "https://bastion.company.com/auth/oidc/callback",
    "claims_mapping": {
      "username": "preferred_username",
      "email": "email",
      "groups": "groups"
    },
    "auto_create_users": false,
    "default_profile": "user"
  }
}
```

### Provider Examples

**Azure AD Configuration:**
```json
{
  "oidc": {
    "enabled": true,
    "provider_url": "https://login.microsoftonline.com/{tenant-id}/v2.0",
    "client_id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "client_secret": "<CLIENT_SECRET>",
    "scopes": ["openid", "profile", "email", "User.Read"]
  }
}
```

**Okta Configuration:**
```json
{
  "oidc": {
    "enabled": true,
    "provider_url": "https://your-domain.okta.com",
    "client_id": "your-okta-client-id",
    "client_secret": "<CLIENT_SECRET>",
    "scopes": ["openid", "profile", "email", "groups"]
  }
}
```

**Keycloak Configuration:**
```json
{
  "oidc": {
    "enabled": true,
    "provider_url": "https://keycloak.company.com/realms/your-realm",
    "client_id": "wallix-bastion",
    "client_secret": "<CLIENT_SECRET>",
    "scopes": ["openid", "profile", "email"]
  }
}
```

### Troubleshooting OIDC

| Issue | Solution |
|-------|----------|
| Token validation fails | Verify provider_url matches IdP configuration |
| User not found | Enable auto_create_users or pre-create users |
| Groups not mapped | Check claims_mapping configuration |
| Redirect fails | Verify redirect_uri matches IdP allowed callbacks |

---

## Certificate-Based Authentication

### Overview

X.509 certificate authentication provides strong authentication using PKI.

### Configuration

```json
{
  "certificate_authentication": {
    "enabled": true,

    "trust_settings": {
      "trusted_ca_certificates": [
        "/etc/ssl/certs/company-ca.pem"
      ],
      "crl_check": true,
      "ocsp_check": true
    },

    "user_mapping": {
      "username_field": "CN",
      "alternative_field": "email"
    },

    "smart_card_settings": {
      "enabled": true,
      "pin_required": true
    }
  }
}
```

### Use Cases

| Scenario | Configuration |
|----------|---------------|
| FortiToken | Certificate + PIN |
| Mutual TLS | Client certificate |
| PIV/CAC | Government PKI |

---

## Authentication Chaining

### Overview

Multiple authentication methods can be chained for defense in depth.

### Chain Configuration

```
Authentication Chain Example
============================

+=================================================================+
|                                                                 |
|   Step 1: Primary Authentication                                |
|   ---------------------------------------                       |
|   Method: LDAP/AD                                               |
|   Result: User identity verified                                |
|                    |                                            |
|                    v                                            |
|   Step 2: Second Factor                                         |
|   ------------------------                                      |
|   Method: RADIUS (Duo)                                          |
|   Result: Possession verified                                   |
|                    |                                            |
|                    v                                            |
|   Step 3: Context Validation                                    |
|   ------------------------------                                |
|   Checks: Source IP, Time, Device                               |
|   Result: Risk assessment passed                                |
|                    |                                            |
|                    v                                            |
|   AUTHENTICATION COMPLETE                                       |
|                                                                 |
+=================================================================+
```

### Chain Policy

```json
{
  "authentication_chain": {
    "name": "high-security",
    "steps": [
      {
        "order": 1,
        "method": "ldap",
        "required": true
      },
      {
        "order": 2,
        "method": "radius",
        "required": true,
        "conditions": {
          "apply_to_profiles": ["administrator", "superadmin"]
        }
      }
    ],
    "fallback": "deny"
  }
}
```

---

## Related Guides

For specific authentication scenarios, see these detailed guides:

| Guide | Description |
|-------|-------------|
| [FortiAuthenticator Integration](./fortiauthenticator-integration.md) | MFA integration with FortiAuthenticator |
| [Kerberos Configuration](./kerberos-configuration.md) | AD Kerberos SSO setup and troubleshooting |

---

## See Also

**Related Sections:**
- [46 - Fortigate Integration](../46-fortigate-integration/README.md) - FortiAuthenticator MFA and RADIUS configuration
- [34 - LDAP/AD Integration](../34-ldap-ad-integration/README.md) - Active Directory authentication and group sync
- [35 - Kerberos Authentication](../35-kerberos-authentication/README.md) - Kerberos SSO and SPNEGO configuration
- [07 - Authorization](../07-authorization/README.md) - Access control policies and RBAC
- [05 - Configuration](../05-configuration/README.md) - Authentication domain configuration

**Related Documentation:**
- [Install Guide](/install/HOWTO.md) - Multi-site deployment with authentication setup
- [Pre-Production Lab](/pre/README.md) - AD and FortiAuthenticator lab setup

**Official Resources:**
- [WALLIX Authentication Guide](https://pam.wallix.one/documentation/admin-doc/bastion_en_administration_guide.pdf)

---

## Next Steps

Continue to [06 - Authorization](../07-authorization/README.md) to learn about access control and authorization policies.
