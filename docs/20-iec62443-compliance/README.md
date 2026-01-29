# 20 - IEC 62443 Compliance with WALLIX

## Table of Contents

1. [IEC 62443 Overview](#iec-62443-overview)
2. [Security Levels](#security-levels)
3. [Foundational Requirements](#foundational-requirements)
4. [System Requirements Mapping](#system-requirements-mapping)
5. [Compliance Implementation](#compliance-implementation)
6. [Audit Evidence](#audit-evidence)

---

## IEC 62443 Overview

### Understanding the Standard

```
+===============================================================================+
|                   IEC 62443 STANDARD STRUCTURE                               |
+===============================================================================+

  IEC 62443 is the international standard for Industrial Automation and
  Control Systems (IACS) security. It provides a framework for securing
  industrial environments.

  STANDARD STRUCTURE
  ==================

  +------------------------------------------------------------------------+
  |                                                                        |
  |   IEC 62443-1-x : General (Concepts, Models, Terminology)              |
  |   +-----------------------------------------------------------------+  |
  |   | 1-1: Terminology, concepts and models                           |  |
  |   | 1-2: Master glossary of terms                                   |  |
  |   | 1-3: System security conformance metrics                        |  |
  |   | 1-4: IACS security lifecycle and use-cases                      |  |
  |   +-----------------------------------------------------------------+  |
  |                                                                        |
  |   IEC 62443-2-x : Policies & Procedures                                |
  |   +-----------------------------------------------------------------+  |
  |   | 2-1: Security program requirements for IACS asset owners        |  |
  |   | 2-2: IACS Protection Level                                      |  |
  |   | 2-3: Patch management in the IACS environment                   |  |
  |   | 2-4: Security program requirements for IACS service providers   |  |
  |   +-----------------------------------------------------------------+  |
  |                                                                        |
  |   IEC 62443-3-x : System (Security Requirements)                       |
  |   +-----------------------------------------------------------------+  |
  |   | 3-1: Security technologies for IACS                             |  |
  |   | 3-2: Security risk assessment for system design                 |  |
  |   | 3-3: System security requirements and security levels           |  |
  |   +-----------------------------------------------------------------+  |
  |                                                                        |
  |   IEC 62443-4-x : Component (Product Development)                      |
  |   +-----------------------------------------------------------------+  |
  |   | 4-1: Secure product development lifecycle requirements          |  |
  |   | 4-2: Technical security requirements for IACS components        |  |
  |   +-----------------------------------------------------------------+  |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  KEY CONCEPTS
  ============

  ZONES: Groups of logical/physical assets sharing security requirements
  CONDUITS: Communication paths between zones with defined security
  SECURITY LEVELS: Target security capability (SL 1-4)
  FOUNDATIONAL REQUIREMENTS: Seven core security areas (FR 1-7)

  +------------------------------------------------------------------------+
  |                                                                        |
  |                     ZONE AND CONDUIT MODEL                             |
  |                                                                        |
  |   +-------------------+           +-------------------+                |
  |   |      ZONE A       |           |      ZONE B       |                |
  |   |    (SL Target: 2) | CONDUIT   |    (SL Target: 3) |                |
  |   |                   +===========+                   |                |
  |   |   [Asset 1]       |  (SL: 2)  |   [Asset 3]       |                |
  |   |   [Asset 2]       |           |   [Asset 4]       |                |
  |   |                   |           |                   |                |
  |   +-------------------+           +-------------------+                |
  |                                                                        |
  |   WALLIX Bastion typically sits in the CONDUIT, controlling            |
  |   access between zones.                                                |
  |                                                                        |
  +------------------------------------------------------------------------+

+===============================================================================+
```

---

## Security Levels

### Security Level Definitions

```
+===============================================================================+
|                   IEC 62443 SECURITY LEVELS                                  |
+===============================================================================+

  Security Levels (SL) define the degree of protection required against
  different threat actors.

  SECURITY LEVEL SCALE
  ====================

  +--------+------------------+--------------------------------------------+
  | Level  | Threat Actor     | Description                                |
  +--------+------------------+--------------------------------------------+
  |        |                  |                                            |
  | SL 0   | None             | No specific requirements or protection     |
  |        |                  |                                            |
  +--------+------------------+--------------------------------------------+
  |        |                  |                                            |
  | SL 1   | Casual /         | Protection against casual or coincidental  |
  |        | Coincidental     | violation                                  |
  |        |                  | - Unintentional errors                     |
  |        |                  | - Accidental misuse                        |
  |        |                  |                                            |
  +--------+------------------+--------------------------------------------+
  |        |                  |                                            |
  | SL 2   | Intentional /    | Protection against intentional violation   |
  |        | Simple means     | using simple means with low resources      |
  |        |                  | - Script kiddies                           |
  |        |                  | - Disgruntled employees                    |
  |        |                  | - Generic malware                          |
  |        |                  |                                            |
  +--------+------------------+--------------------------------------------+
  |        |                  |                                            |
  | SL 3   | Intentional /    | Protection against sophisticated attack    |
  |        | Sophisticated    | with moderate resources                    |
  |        |                  | - Organized crime                          |
  |        |                  | - Hacktivists                              |
  |        |                  | - Nation-state affiliated                  |
  |        |                  |                                            |
  +--------+------------------+--------------------------------------------+
  |        |                  |                                            |
  | SL 4   | Intentional /    | Protection against sophisticated attack    |
  |        | Extended /       | with extended resources                    |
  |        | State-sponsored  | - Nation-state actors                      |
  |        |                  | - APT groups                               |
  |        |                  | - Terrorist organizations                  |
  |        |                  |                                            |
  +--------+------------------+--------------------------------------------+

  --------------------------------------------------------------------------

  WALLIX SECURITY LEVEL CAPABILITY
  =================================

  WALLIX Bastion supports implementation up to SL 4 with proper
  configuration:

  +--------+--------------------------------------------------------------+
  | Level  | WALLIX Configuration Required                                |
  +--------+--------------------------------------------------------------+
  |        |                                                              |
  | SL 1   | - Basic authentication (username/password)                   |
  |        | - Default session logging enabled                            |
  |        | - Basic role separation (admin vs user)                      |
  |        |                                                              |
  +--------+--------------------------------------------------------------+
  |        |                                                              |
  | SL 2   | SL 1 requirements plus:                                      |
  |        | - Strong passwords (complexity, history)                     |
  |        | - Full session recording                                     |
  |        | - Role-based access control (RBAC)                           |
  |        | - Audit logging with retention                               |
  |        | - Account lockout policies                                   |
  |        |                                                              |
  +--------+--------------------------------------------------------------+
  |        |                                                              |
  | SL 3   | SL 2 requirements plus:                                      |
  |        | - Multi-factor authentication (MFA)                          |
  |        | - Encrypted storage (credential vault)                       |
  |        | - SIEM integration                                           |
  |        | - Approval workflows                                         |
  |        | - Real-time session monitoring                               |
  |        | - Automatic password rotation                                |
  |        | - Network encryption (TLS 1.2+)                              |
  |        |                                                              |
  +--------+--------------------------------------------------------------+
  |        |                                                              |
  | SL 4   | SL 3 requirements plus:                                      |
  |        | - HSM for key protection                                     |
  |        | - 4-eyes approval (dual control)                             |
  |        | - Continuous session monitoring                              |
  |        | - Behavioral anomaly detection                               |
  |        | - High availability (redundancy)                             |
  |        | - Geographic separation                                      |
  |        | - Advanced audit (tamper-proof logs)                         |
  |        |                                                              |
  +--------+--------------------------------------------------------------+

+===============================================================================+
```

---

## Foundational Requirements

### FR 1: Identification and Authentication Control (IAC)

```
+===============================================================================+
|                   FR 1: IDENTIFICATION & AUTHENTICATION                      |
+===============================================================================+

  Purpose: Identify and authenticate all users (humans, software, devices)
  before access to the IACS is authorized.

  WALLIX IMPLEMENTATION
  =====================

  +------------------------------------------------------------------------+
  | SR      | Requirement                    | WALLIX Implementation       |
  +---------+--------------------------------+-----------------------------+
  |         |                                |                             |
  | SR 1.1  | Human user identification      | Local user accounts         |
  |         | and authentication             | LDAP/AD integration         |
  |         |                                | RADIUS authentication       |
  |         |                                | SAML/OAuth for SSO          |
  |         |                                |                             |
  +---------+--------------------------------+-----------------------------+
  |         |                                |                             |
  | SR 1.2  | Software process and device    | Service accounts with       |
  |         | identification                 | API authentication          |
  |         |                                | Certificate-based auth      |
  |         |                                |                             |
  +---------+--------------------------------+-----------------------------+
  |         |                                |                             |
  | SR 1.3  | Account management             | User lifecycle management   |
  |         |                                | Group-based provisioning    |
  |         |                                | Automatic deprovisioning    |
  |         |                                |                             |
  +---------+--------------------------------+-----------------------------+
  |         |                                |                             |
  | SR 1.4  | Identifier management          | Unique user identifiers     |
  |         |                                | No shared accounts          |
  |         |                                | Account naming standards    |
  |         |                                |                             |
  +---------+--------------------------------+-----------------------------+
  |         |                                |                             |
  | SR 1.5  | Authenticator management       | Password policy enforcement |
  |         |                                | Token provisioning          |
  |         |                                | Certificate lifecycle       |
  |         |                                |                             |
  +---------+--------------------------------+-----------------------------+
  |         |                                |                             |
  | SR 1.6  | Wireless access management     | N/A (network layer)         |
  |         |                                |                             |
  +---------+--------------------------------+-----------------------------+
  |         |                                |                             |
  | SR 1.7  | Strength of password-based     | Configurable complexity:    |
  |         | authentication                 | - Minimum length (12+)      |
  |         |                                | - Character requirements    |
  |         |                                | - History (prevent reuse)   |
  |         |                                | - Expiration policies       |
  |         |                                |                             |
  +---------+--------------------------------+-----------------------------+
  |         |                                |                             |
  | SR 1.8  | Public key infrastructure      | Certificate authentication  |
  |         | certificates                   | Smart card support          |
  |         |                                | CA integration              |
  |         |                                |                             |
  +---------+--------------------------------+-----------------------------+
  |         |                                |                             |
  | SR 1.9  | Strength of public key         | Configurable key sizes      |
  |         | authentication                 | Algorithm selection         |
  |         |                                | RSA 2048+, ECDSA 256+       |
  |         |                                |                             |
  +---------+--------------------------------+-----------------------------+
  |         |                                |                             |
  | SR 1.10 | Authenticator feedback         | Obscured password entry     |
  |         |                                | Generic error messages      |
  |         |                                | No username enumeration     |
  |         |                                |                             |
  +---------+--------------------------------+-----------------------------+
  |         |                                |                             |
  | SR 1.11 | Unsuccessful login attempts    | Configurable lockout:       |
  |         |                                | - Attempt threshold         |
  |         |                                | - Lockout duration          |
  |         |                                | - Admin notification        |
  |         |                                |                             |
  +---------+--------------------------------+-----------------------------+
  |         |                                |                             |
  | SR 1.12 | System use notification        | Login banner                |
  |         |                                | Terms acceptance            |
  |         |                                |                             |
  +---------+--------------------------------+-----------------------------+
  |         |                                |                             |
  | SR 1.13 | Access via untrusted networks  | MFA enforcement             |
  |         |                                | VPN integration             |
  |         |                                | Session restrictions        |
  |         |                                |                             |
  +---------+--------------------------------+-----------------------------+

+===============================================================================+
```

### FR 2: Use Control (UC)

```
+===============================================================================+
|                   FR 2: USE CONTROL                                          |
+===============================================================================+

  Purpose: Ensure only authorized users have access to the system and its
  functions, enforcing least privilege.

  WALLIX IMPLEMENTATION
  =====================

  +------------------------------------------------------------------------+
  | SR      | Requirement                    | WALLIX Implementation       |
  +---------+--------------------------------+-----------------------------+
  |         |                                |                             |
  | SR 2.1  | Authorization enforcement      | Authorization policies      |
  |         |                                | User-Group-Device mapping   |
  |         |                                | Time-based restrictions     |
  |         |                                | Target account mapping      |
  |         |                                |                             |
  +---------+--------------------------------+-----------------------------+
  |         |                                |                             |
  | SR 2.2  | Wireless use control           | N/A (network layer)         |
  |         |                                |                             |
  +---------+--------------------------------+-----------------------------+
  |         |                                |                             |
  | SR 2.3  | Use control for portable       | Session restrictions        |
  |         | and mobile devices             | Device-based policies       |
  |         |                                | Access Manager controls     |
  |         |                                |                             |
  +---------+--------------------------------+-----------------------------+
  |         |                                |                             |
  | SR 2.4  | Mobile code                    | Command restrictions        |
  |         |                                | Blocked command lists       |
  |         |                                | Protocol inspection         |
  |         |                                |                             |
  +---------+--------------------------------+-----------------------------+
  |         |                                |                             |
  | SR 2.5  | Session lock                   | Session timeout             |
  |         |                                | Idle disconnect             |
  |         |                                | Manual session lock         |
  |         |                                |                             |
  +---------+--------------------------------+-----------------------------+
  |         |                                |                             |
  | SR 2.6  | Remote session termination     | Admin session kill          |
  |         |                                | Automatic termination       |
  |         |                                | Policy-based disconnect     |
  |         |                                |                             |
  +---------+--------------------------------+-----------------------------+
  |         |                                |                             |
  | SR 2.7  | Concurrent session control     | Session limits per user     |
  |         |                                | Concurrent session policies |
  |         |                                |                             |
  +---------+--------------------------------+-----------------------------+
  |         |                                |                             |
  | SR 2.8  | Auditable events               | Full session recording      |
  |         |                                | Keystroke logging           |
  |         |                                | Command capture             |
  |         |                                | Screen recording (RDP)      |
  |         |                                |                             |
  +---------+--------------------------------+-----------------------------+
  |         |                                |                             |
  | SR 2.9  | Audit storage capacity         | Configurable retention      |
  |         |                                | External storage support    |
  |         |                                | Automatic archival          |
  |         |                                |                             |
  +---------+--------------------------------+-----------------------------+
  |         |                                |                             |
  | SR 2.10 | Response to audit processing   | Storage alerts              |
  |         | failures                       | Failover logging            |
  |         |                                | Graceful degradation        |
  |         |                                |                             |
  +---------+--------------------------------+-----------------------------+
  |         |                                |                             |
  | SR 2.11 | Timestamps                     | NTP synchronization         |
  |         |                                | UTC logging                 |
  |         |                                | Timestamp in all events     |
  |         |                                |                             |
  +---------+--------------------------------+-----------------------------+
  |         |                                |                             |
  | SR 2.12 | Non-repudiation                | Digital signatures          |
  |         |                                | Session attestation         |
  |         |                                | Tamper-evident logs         |
  |         |                                |                             |
  +---------+--------------------------------+-----------------------------+

+===============================================================================+
```

### FR 3-7 Summary

```
+===============================================================================+
|                   FR 3-7: ADDITIONAL REQUIREMENTS                            |
+===============================================================================+

  FR 3: SYSTEM INTEGRITY (SI)
  ===========================

  +------------------------------------------------------------------------+
  | WALLIX Support:                                                        |
  | - Validates system integrity at boot                                   |
  | - Signed firmware updates                                              |
  | - Input validation for all user input                                  |
  | - Session data sanitization                                            |
  | - No code execution on behalf of users                                 |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  FR 4: DATA CONFIDENTIALITY (DC)
  ===============================

  +------------------------------------------------------------------------+
  | WALLIX Support:                                                        |
  | - AES-256 encryption for credential vault                              |
  | - TLS 1.2/1.3 for all communications                                   |
  | - Encrypted session recordings (optional)                              |
  | - HSM support for key protection                                       |
  | - No plaintext credential exposure                                     |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  FR 5: RESTRICTED DATA FLOW (RDF)
  ================================

  +------------------------------------------------------------------------+
  | WALLIX Support:                                                        |
  | - Network segmentation enforcement via proxy                           |
  | - Protocol-level traffic control                                       |
  | - Session-based data flow (no persistent tunnels)                      |
  | - Configurable allowed protocols per target                            |
  | - File transfer controls (if enabled)                                  |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  FR 6: TIMELY RESPONSE TO EVENTS (TRE)
  =====================================

  +------------------------------------------------------------------------+
  | WALLIX Support:                                                        |
  | - Real-time alerting via email/syslog/SNMP                             |
  | - SIEM integration (CEF, syslog)                                       |
  | - Configurable alert thresholds                                        |
  | - Session monitoring with instant kill                                 |
  | - Webhook notifications                                                |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  FR 7: RESOURCE AVAILABILITY (RA)
  ================================

  +------------------------------------------------------------------------+
  | WALLIX Support:                                                        |
  | - High availability clustering                                         |
  | - Automatic failover                                                   |
  | - Session persistence across failover                                  |
  | - Load balancing support                                               |
  | - Backup and restore procedures                                        |
  | - Denial of service protection (rate limiting)                         |
  +------------------------------------------------------------------------+

+===============================================================================+
```

---

## System Requirements Mapping

### Complete SR Mapping Table

```
+===============================================================================+
|                   WALLIX IEC 62443 COMPLIANCE MATRIX                         |
+===============================================================================+

  Legend:
  [F] = Fully Supported
  [P] = Partially Supported (may need additional configuration/integration)
  [N] = Not Applicable to PAM
  [-] = Not Supported

  +----------+-------------------------------------------+-------+-------+
  | SR       | Requirement                               | SL2   | SL3/4 |
  +----------+-------------------------------------------+-------+-------+
  |                                                                       |
  | FR 1: IDENTIFICATION AND AUTHENTICATION CONTROL (IAC)                 |
  |                                                                       |
  +----------+-------------------------------------------+-------+-------+
  | SR 1.1   | Human user identification and auth        | [F]   | [F]   |
  | SR 1.2   | Software process identification           | [F]   | [F]   |
  | SR 1.3   | Account management                        | [F]   | [F]   |
  | SR 1.4   | Identifier management                     | [F]   | [F]   |
  | SR 1.5   | Authenticator management                  | [F]   | [F]   |
  | SR 1.6   | Wireless access management                | [N]   | [N]   |
  | SR 1.7   | Strength of password-based auth           | [F]   | [F]   |
  | SR 1.8   | Public key infrastructure certificates    | [F]   | [F]   |
  | SR 1.9   | Strength of public key auth               | [F]   | [F]   |
  | SR 1.10  | Authenticator feedback                    | [F]   | [F]   |
  | SR 1.11  | Unsuccessful login attempts               | [F]   | [F]   |
  | SR 1.12  | System use notification                   | [F]   | [F]   |
  | SR 1.13  | Access via untrusted networks             | [F]   | [F]   |
  +----------+-------------------------------------------+-------+-------+
  |                                                                       |
  | FR 2: USE CONTROL (UC)                                                |
  |                                                                       |
  +----------+-------------------------------------------+-------+-------+
  | SR 2.1   | Authorization enforcement                 | [F]   | [F]   |
  | SR 2.2   | Wireless use control                      | [N]   | [N]   |
  | SR 2.3   | Use control for portable/mobile           | [P]   | [P]   |
  | SR 2.4   | Mobile code                               | [P]   | [P]   |
  | SR 2.5   | Session lock                              | [F]   | [F]   |
  | SR 2.6   | Remote session termination                | [F]   | [F]   |
  | SR 2.7   | Concurrent session control                | [F]   | [F]   |
  | SR 2.8   | Auditable events                          | [F]   | [F]   |
  | SR 2.9   | Audit storage capacity                    | [F]   | [F]   |
  | SR 2.10  | Response to audit processing failures     | [F]   | [F]   |
  | SR 2.11  | Timestamps                                | [F]   | [F]   |
  | SR 2.12  | Non-repudiation                           | [F]   | [F]   |
  +----------+-------------------------------------------+-------+-------+
  |                                                                       |
  | FR 3: SYSTEM INTEGRITY (SI)                                           |
  |                                                                       |
  +----------+-------------------------------------------+-------+-------+
  | SR 3.1   | Communication integrity                   | [F]   | [F]   |
  | SR 3.2   | Malicious code protection                 | [P]   | [P]   |
  | SR 3.3   | Security functionality verification      | [F]   | [F]   |
  | SR 3.4   | Software and information integrity        | [F]   | [F]   |
  | SR 3.5   | Input validation                          | [F]   | [F]   |
  | SR 3.6   | Deterministic output                      | [F]   | [F]   |
  | SR 3.7   | Error handling                            | [F]   | [F]   |
  | SR 3.8   | Session integrity                         | [F]   | [F]   |
  | SR 3.9   | Audit information protection              | [F]   | [F]   |
  +----------+-------------------------------------------+-------+-------+
  |                                                                       |
  | FR 4: DATA CONFIDENTIALITY (DC)                                       |
  |                                                                       |
  +----------+-------------------------------------------+-------+-------+
  | SR 4.1   | Information confidentiality               | [F]   | [F]   |
  | SR 4.2   | Information persistence                   | [F]   | [F]   |
  | SR 4.3   | Use of cryptography                       | [F]   | [F]   |
  +----------+-------------------------------------------+-------+-------+
  |                                                                       |
  | FR 5: RESTRICTED DATA FLOW (RDF)                                      |
  |                                                                       |
  +----------+-------------------------------------------+-------+-------+
  | SR 5.1   | Network segmentation                      | [F]   | [F]   |
  | SR 5.2   | Zone boundary protection                  | [F]   | [F]   |
  | SR 5.3   | General purpose person-to-person comm     | [N]   | [N]   |
  | SR 5.4   | Application partitioning                  | [P]   | [P]   |
  +----------+-------------------------------------------+-------+-------+
  |                                                                       |
  | FR 6: TIMELY RESPONSE TO EVENTS (TRE)                                 |
  |                                                                       |
  +----------+-------------------------------------------+-------+-------+
  | SR 6.1   | Audit log accessibility                   | [F]   | [F]   |
  | SR 6.2   | Continuous monitoring                     | [F]   | [F]   |
  +----------+-------------------------------------------+-------+-------+
  |                                                                       |
  | FR 7: RESOURCE AVAILABILITY (RA)                                      |
  |                                                                       |
  +----------+-------------------------------------------+-------+-------+
  | SR 7.1   | DoS protection                            | [F]   | [F]   |
  | SR 7.2   | Resource management                       | [F]   | [F]   |
  | SR 7.3   | Control system backup                     | [F]   | [F]   |
  | SR 7.4   | Control system recovery and reconstitution| [F]   | [F]   |
  | SR 7.5   | Emergency power                           | [N]   | [N]   |
  | SR 7.6   | Network and security config settings      | [F]   | [F]   |
  | SR 7.7   | Least functionality                       | [F]   | [F]   |
  | SR 7.8   | Control system component inventory        | [F]   | [F]   |
  +----------+-------------------------------------------+-------+-------+

+===============================================================================+
```

---

## Compliance Implementation

### Configuration Guide by Security Level

```
+===============================================================================+
|                   WALLIX CONFIGURATION FOR IEC 62443                         |
+===============================================================================+

  SECURITY LEVEL 2 CONFIGURATION
  ==============================

  Authentication Settings:
  +------------------------------------------------------------------------+
  | Parameter                    | Value                                   |
  +------------------------------+-----------------------------------------+
  | Password minimum length      | 8 characters                            |
  | Password complexity          | Upper + Lower + Number                  |
  | Password history             | 5 passwords                             |
  | Password expiration          | 90 days                                 |
  | Account lockout threshold    | 5 failed attempts                       |
  | Account lockout duration     | 30 minutes                              |
  | Session timeout              | 15 minutes idle                         |
  +------------------------------+-----------------------------------------+

  Authorization Settings:
  +------------------------------------------------------------------------+
  | Parameter                    | Value                                   |
  +------------------------------+-----------------------------------------+
  | Role-based access            | Enabled                                 |
  | Approval workflow            | Optional                                |
  | Time restrictions            | Recommended                             |
  | MFA                          | Not required (recommended)              |
  +------------------------------+-----------------------------------------+

  Audit Settings:
  +------------------------------------------------------------------------+
  | Parameter                    | Value                                   |
  +------------------------------+-----------------------------------------+
  | Session recording            | Enabled (all sessions)                  |
  | Keystroke logging            | Enabled                                 |
  | Syslog forwarding            | Enabled                                 |
  | Log retention                | 1 year minimum                          |
  +------------------------------+-----------------------------------------+

  --------------------------------------------------------------------------

  SECURITY LEVEL 3 CONFIGURATION
  ==============================

  Authentication Settings:
  +------------------------------------------------------------------------+
  | Parameter                    | Value                                   |
  +------------------------------+-----------------------------------------+
  | Password minimum length      | 12 characters                           |
  | Password complexity          | Upper + Lower + Number + Special        |
  | Password history             | 12 passwords                            |
  | Password expiration          | 60 days                                 |
  | Account lockout threshold    | 3 failed attempts                       |
  | Account lockout duration     | 60 minutes (admin unlock)               |
  | Session timeout              | 10 minutes idle                         |
  | MFA                          | REQUIRED for all users                  |
  | MFA type                     | TOTP/Hardware token/Smart card          |
  +------------------------------+-----------------------------------------+

  Authorization Settings:
  +------------------------------------------------------------------------+
  | Parameter                    | Value                                   |
  +------------------------------+-----------------------------------------+
  | Role-based access            | Enabled (strict)                        |
  | Approval workflow            | Required for sensitive targets          |
  | Time restrictions            | Required                                |
  | Concurrent sessions          | Limited (1-2 per user)                  |
  | Just-in-time access          | Enabled                                 |
  +------------------------------+-----------------------------------------+

  Audit Settings:
  +------------------------------------------------------------------------+
  | Parameter                    | Value                                   |
  +------------------------------+-----------------------------------------+
  | Session recording            | Enabled (all sessions)                  |
  | Keystroke logging            | Enabled                                 |
  | OCR indexing (RDP)           | Enabled                                 |
  | Syslog forwarding            | Enabled (encrypted TLS)                 |
  | SIEM integration             | Required                                |
  | Real-time monitoring         | Enabled                                 |
  | Log retention                | 3 years minimum                         |
  | Log signing                  | Enabled                                 |
  +------------------------------+-----------------------------------------+

  Encryption Settings:
  +------------------------------------------------------------------------+
  | Parameter                    | Value                                   |
  +------------------------------+-----------------------------------------+
  | TLS version                  | 1.2 minimum (1.3 preferred)             |
  | Cipher suites                | Strong only (no RC4, 3DES)              |
  | Certificate key size         | RSA 2048+ / ECDSA 256+                  |
  | Vault encryption             | AES-256                                 |
  +------------------------------+-----------------------------------------+

  --------------------------------------------------------------------------

  SECURITY LEVEL 4 CONFIGURATION
  ==============================

  All SL3 requirements plus:

  +------------------------------------------------------------------------+
  | Parameter                    | Value                                   |
  +------------------------------+-----------------------------------------+
  | HSM integration              | Required for key storage                |
  | 4-eyes approval              | Required for all access                 |
  | Continuous monitoring        | Required (SOC integration)              |
  | Behavioral analytics         | Enabled                                 |
  | Geo-redundancy               | Required                                |
  | Session recording encryption | Required                                |
  | Tamper-evident logging       | Required (hash chain)                   |
  | Break-glass procedures       | Documented and tested                   |
  +------------------------------+-----------------------------------------+

+===============================================================================+
```

---

## Audit Evidence

### Documentation for Compliance Audits

```
+===============================================================================+
|                   IEC 62443 AUDIT EVIDENCE                                   |
+===============================================================================+

  Evidence required for IEC 62443 compliance audits:

  DOCUMENTATION ARTIFACTS
  =======================

  +------------------------------------------------------------------------+
  | Category              | Evidence                                       |
  +-----------------------+------------------------------------------------+
  |                       |                                                |
  | System Architecture   | - Network diagrams showing WALLIX placement    |
  |                       | - Zone and conduit definitions                 |
  |                       | - Data flow diagrams                           |
  |                       |                                                |
  +-----------------------+------------------------------------------------+
  |                       |                                                |
  | Policies & Procedures | - Access control policy document               |
  |                       | - Password policy document                     |
  |                       | - Incident response procedures                 |
  |                       | - Change management procedures                 |
  |                       |                                                |
  +-----------------------+------------------------------------------------+
  |                       |                                                |
  | Configuration         | - WALLIX configuration export                  |
  |                       | - Authorization policy export                  |
  |                       | - User and group definitions                   |
  |                       | - Device/account inventory                     |
  |                       |                                                |
  +-----------------------+------------------------------------------------+
  |                       |                                                |
  | Operational Records   | - Session audit logs (sample)                  |
  |                       | - Password rotation logs                       |
  |                       | - Access approval records                      |
  |                       | - Incident records                             |
  |                       |                                                |
  +-----------------------+------------------------------------------------+
  |                       |                                                |
  | Testing Evidence      | - Penetration test reports                     |
  |                       | - Vulnerability scan results                   |
  |                       | - Failover test results                        |
  |                       | - Backup/restore test results                  |
  |                       |                                                |
  +-----------------------+------------------------------------------------+

  --------------------------------------------------------------------------

  GENERATING EVIDENCE FROM WALLIX
  ===============================

  Configuration Export:
  +------------------------------------------------------------------------+
  | # Export full configuration                                            |
  | wab-admin export-config --output /backup/wallix-config-$(date +%F).xml |
  |                                                                        |
  | # Export authorization policies                                        |
  | wab-admin export-authorizations --format json > authorizations.json    |
  |                                                                        |
  | # Export user/group inventory                                          |
  | wab-admin export-users --format csv > users.csv                        |
  | wab-admin export-groups --format csv > groups.csv                      |
  |                                                                        |
  | # Export device inventory                                              |
  | wab-admin export-devices --format csv > devices.csv                    |
  +------------------------------------------------------------------------+

  Audit Log Export:
  +------------------------------------------------------------------------+
  | # Export session logs for date range                                   |
  | wab-admin export-sessions --start 2024-01-01 --end 2024-01-31 \        |
  |   --format csv > sessions-jan2024.csv                                  |
  |                                                                        |
  | # Export authentication logs                                           |
  | wab-admin export-auth-logs --start 2024-01-01 --end 2024-01-31 \       |
  |   --format csv > auth-logs-jan2024.csv                                 |
  |                                                                        |
  | # Generate compliance report                                           |
  | wab-admin compliance-report --standard iec62443 --level 3 \            |
  |   --output iec62443-report.pdf                                         |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  AUDIT CHECKLIST
  ===============

  Pre-Audit Preparation:

  [ ] 1. Verify all configuration documentation is current
  [ ] 2. Export configuration and policy files
  [ ] 3. Generate session log samples for audit period
  [ ] 4. Prepare network diagrams with WALLIX placement
  [ ] 5. Document zone definitions and security levels
  [ ] 6. Compile incident response procedure evidence
  [ ] 7. Gather penetration test / vulnerability scan reports
  [ ] 8. Document change management records for WALLIX
  [ ] 9. Prepare failover and backup test results
  [ ] 10. Review and update access control policy documents

+===============================================================================+
```

---

## Next Steps

Continue to [21 - Industrial Use Cases](../21-industrial-use-cases/README.md) for industry-specific implementation scenarios.
