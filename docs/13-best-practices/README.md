# 13 - Best Practices

## Table of Contents

1. [Design Best Practices](#design-best-practices)
2. [Security Hardening](#security-hardening)
3. [Operational Excellence](#operational-excellence)
4. [Performance Optimization](#performance-optimization)
5. [Compliance & Audit](#compliance--audit)
6. [Change Management](#change-management)

---

## Design Best Practices

### Architecture Design

```
+===============================================================================+
|                    ARCHITECTURE BEST PRACTICES                                |
+===============================================================================+
|                                                                               |
|  DO:                                                                          |
|  ===                                                                          |
|                                                                               |
|  [x] Deploy in DMZ or dedicated management network                           |
|  [x] Use redundant architecture for production                               |
|  [x] Separate Access Manager from Bastion core (large deployments)           |
|  [x] Use dedicated storage for recordings                                    |
|  [x] Plan for growth (sessions, storage, targets)                            |
|  [x] Document network flows and firewall rules                               |
|                                                                               |
|  DON'T:                                                                       |
|  ======                                                                       |
|                                                                               |
|  [ ] Deploy single node in production without DR plan                        |
|  [ ] Store recordings on local disk only                                     |
|  [ ] Use same network segment as general user traffic                        |
|  [ ] Undersize the system (CPU, memory, storage)                             |
|  [ ] Skip network segmentation between Bastion and targets                   |
|                                                                               |
+===============================================================================+
```

### Domain Structure

```
+===============================================================================+
|                    DOMAIN DESIGN BEST PRACTICES                               |
+===============================================================================+
|                                                                               |
|  RECOMMENDED STRUCTURE                                                        |
|  =====================                                                        |
|                                                                               |
|  Domains/                                                                     |
|  +-- Production/                                                             |
|  |   +-- PROD-Linux-Servers                                                  |
|  |   +-- PROD-Windows-Servers                                                |
|  |   +-- PROD-Databases                                                      |
|  |   +-- PROD-Network                                                        |
|  |                                                                            |
|  +-- Non-Production/                                                         |
|  |   +-- DEV-Servers                                                         |
|  |   +-- STG-Servers                                                         |
|  |   +-- TEST-Servers                                                        |
|  |                                                                            |
|  +-- Infrastructure/                                                         |
|      +-- MGMT-Hypervisors                                                    |
|      +-- MGMT-Network-Core                                                   |
|      +-- MGMT-Security-Appliances                                            |
|                                                                               |
|  NAMING CONVENTIONS                                                           |
|  ==================                                                           |
|                                                                               |
|  * Use consistent prefixes (PROD-, DEV-, STG-)                               |
|  * Include function in name (Servers, Databases, Network)                    |
|  * Avoid spaces (use hyphens or underscores)                                 |
|  * Keep names meaningful but concise                                         |
|                                                                               |
+===============================================================================+
```

### Authorization Design

```
+===============================================================================+
|                    AUTHORIZATION BEST PRACTICES                               |
+===============================================================================+
|                                                                               |
|  PRINCIPLE OF LEAST PRIVILEGE                                                 |
|  ============================                                                 |
|                                                                               |
|  1. Start restrictive, add permissions as needed                             |
|  2. Use specific target groups, not domain-wide                              |
|  3. Limit subprotocols to required functionality                             |
|  4. Apply time restrictions where appropriate                                |
|                                                                               |
|  EXAMPLE - Good Authorization Design:                                         |
|                                                                               |
|  +---------------------------------------------------------------------------+|
|  |                                                                          | |
|  |  Authorization: "web-admins-prod-ssh"                                   | |
|  |                                                                          | |
|  |  User Group:    Web-Administrators                                      | |
|  |  Target Group:  PROD-Web-Servers-Root                                   | |
|  |  Subprotocols:  SHELL only (no SCP, SFTP)                               | |
|  |  Recording:     Required                                                 | |
|  |  Time Frame:    Business hours only                                     | |
|  |  Approval:      Not required                                            | |
|  |                                                                          | |
|  +---------------------------------------------------------------------------+|
|                                                                               |
|  EXAMPLE - Avoid This:                                                        |
|                                                                               |
|  +---------------------------------------------------------------------------+|
|  |                                                                          | |
|  |  Authorization: "all-access"                                            | |
|  |                                                                          | |
|  |  User Group:    All-Users                                               | |
|  |  Target Group:  All-Targets                                             | |
|  |  Subprotocols:  All                                                     | |
|  |  Recording:     Optional                                                 | |
|  |  Time Frame:    Always                                                  | |
|  |                                                                          | |
|  |  [ ] Too broad, violates least privilege                                | |
|  |                                                                          | |
|  +---------------------------------------------------------------------------+|
|                                                                               |
+===============================================================================+
```

---

## Zero Trust Architecture

### Zero Trust Principles for PAM

```
+===============================================================================+
|                   ZERO TRUST ARCHITECTURE WITH WALLIX                        |
+===============================================================================+

  CORE PRINCIPLES
  ===============

  1. NEVER TRUST, ALWAYS VERIFY
     +----------------------------------------------------------------------+
     | Traditional Model         | Zero Trust Model                         |
     +--------------------------+------------------------------------------+
     | Trust internal network   | Verify every connection                  |
     | Trust VPN users          | Authenticate at every access             |
     | Trust known devices      | Validate device posture continuously     |
     | Implicit trust           | Explicit verification                    |
     +--------------------------+------------------------------------------+

  2. ASSUME BREACH
     * Design systems expecting attackers are already inside
     * Limit lateral movement through micro-segmentation
     * Monitor all privileged access

  3. LEAST PRIVILEGE ACCESS
     * Grant minimum necessary permissions
     * Time-bound access (JIT)
     * Continuous authorization

  --------------------------------------------------------------------------

  ZERO TRUST IMPLEMENTATION WITH WALLIX
  =====================================

  +------------------------------------------------------------------------+
  |                                                                        |
  |   IDENTITY VERIFICATION LAYER                                          |
  |   ===========================                                          |
  |                                                                        |
  |   User Identity                                                        |
  |   +--------------------+                                               |
  |   | 1. Primary Auth    | AD/LDAP, Local, SAML, OIDC                    |
  |   | 2. MFA Required    | TOTP, FIDO2, Push, SMS                        |
  |   | 3. Device Trust    | Certificate, compliance check                 |
  |   | 4. Context Check   | Location, time, behavior                      |
  |   +--------------------+                                               |
  |                                                                        |
  |   WALLIX Configuration:                                                |
  |   - Enable MFA for ALL users (no exceptions)                           |
  |   - Integrate with identity provider (SAML/OIDC)                       |
  |   - Configure conditional access policies                              |
  |   - Enable session risk scoring                                        |
  |                                                                        |
  +------------------------------------------------------------------------+
  |                                                                        |
  |   MICRO-SEGMENTATION LAYER                                             |
  |   =========================                                            |
  |                                                                        |
  |   Network Segmentation                                                 |
  |   +--------------------+                                               |
  |   | Zone 1: Users      | Corporate network                             |
  |   | Zone 2: WALLIX     | DMZ / Management zone                         |
  |   | Zone 3: Targets    | Server / OT networks                          |
  |   +--------------------+                                               |
  |                                                                        |
  |   Access Flow:                                                         |
  |   Users --[HTTPS]--> WALLIX --[Protocol]--> Targets                    |
  |                                                                        |
  |   * NO direct user-to-target access                                    |
  |   * ALL access through WALLIX proxy                                    |
  |   * Firewall rules enforce segmentation                                |
  |                                                                        |
  +------------------------------------------------------------------------+
  |                                                                        |
  |   CONTINUOUS AUTHORIZATION LAYER                                       |
  |   ===============================                                      |
  |                                                                        |
  |   Just-In-Time Access                                                  |
  |   +--------------------+                                               |
  |   | Request Access     | User submits access request                   |
  |   | Approval Workflow  | Manager/security approval                     |
  |   | Time-Limited Grant | Access valid for specific duration           |
  |   | Auto-Revocation    | Access automatically expires                  |
  |   +--------------------+                                               |
  |                                                                        |
  |   WALLIX Configuration:                                                |
  |   - Enable approval workflows for sensitive access                     |
  |   - Set maximum session durations                                      |
  |   - Configure automatic timeout policies                               |
  |   - Enable session monitoring and termination                          |
  |                                                                        |
  +------------------------------------------------------------------------+
  |                                                                        |
  |   CONTINUOUS MONITORING LAYER                                          |
  |   ============================                                         |
  |                                                                        |
  |   Real-Time Monitoring                                                 |
  |   +--------------------+                                               |
  |   | Session Recording  | All privileged sessions recorded             |
  |   | Command Logging    | All commands captured                         |
  |   | Behavior Analysis  | Anomaly detection                             |
  |   | Policy Enforcement | Blocked commands/actions                      |
  |   +--------------------+                                               |
  |                                                                        |
  |   WALLIX Configuration:                                                |
  |   - Enable recording for all authorizations                            |
  |   - Configure command restrictions                                     |
  |   - Set up SIEM integration for correlation                            |
  |   - Enable real-time alerting                                          |
  |                                                                        |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### Zero Trust Access Model

```
+===============================================================================+
|                   ZERO TRUST ACCESS FLOW                                     |
+===============================================================================+

  ACCESS REQUEST LIFECYCLE
  ========================

  +------------------------------------------------------------------------+
  |                                                                        |
  |   +------+    +--------+    +--------+    +--------+    +--------+     |
  |   | User +--->+ Verify +--->+ Check  +--->+ Grant  +--->+ Monitor|     |
  |   +------+    | Identity   | Context |    | Access |    | Session|     |
  |               +--------+    +--------+    +--------+    +--------+     |
  |                   |             |             |             |          |
  |                   v             v             v             v          |
  |               +--------+    +--------+    +--------+    +--------+     |
  |               | Deny   |    | Deny   |    | Deny   |    | Terminate   |
  |               | Access |    | Access |    | Access |    | Session|     |
  |               +--------+    +--------+    +--------+    +--------+     |
  |                                                                        |
  +------------------------------------------------------------------------+

  VERIFICATION CHECKPOINTS
  ========================

  1. IDENTITY VERIFICATION
     +------------------------------------------------------------------+
     | Check                      | Action on Failure                   |
     +----------------------------+-------------------------------------+
     | Valid credentials          | Block access, log attempt           |
     | MFA challenge passed       | Block access, alert security        |
     | Account not locked/expired | Block access, notify admin          |
     | User in valid group        | Block access, log violation         |
     +----------------------------+-------------------------------------+

  2. CONTEXT VERIFICATION
     +------------------------------------------------------------------+
     | Check                      | Action on Failure                   |
     +----------------------------+-------------------------------------+
     | Source IP allowed          | Block access, alert security        |
     | Time within permitted hours| Request approval or block           |
     | Device posture compliant   | Block access, remediation prompt    |
     | Geographic location valid  | Block access, investigate           |
     +----------------------------+-------------------------------------+

  3. AUTHORIZATION VERIFICATION
     +------------------------------------------------------------------+
     | Check                      | Action on Failure                   |
     +----------------------------+-------------------------------------+
     | Valid authorization exists | Block access, log attempt           |
     | Approval obtained (if req) | Hold pending approval               |
     | Target available           | Retry or block                      |
     | Session limit not exceeded | Queue or block                      |
     +----------------------------+-------------------------------------+

  4. CONTINUOUS VERIFICATION
     +------------------------------------------------------------------+
     | Check                      | Action on Violation                 |
     +----------------------------+-------------------------------------+
     | Session within time limit  | Warn user, then terminate           |
     | No blocked commands        | Block command, alert, optional term |
     | Behavior within normal     | Alert security, optional terminate  |
     | User still authorized      | Terminate session immediately       |
     +----------------------------+-------------------------------------+

+===============================================================================+
```

### Zero Trust Implementation Checklist

```
+===============================================================================+
|                   ZERO TRUST IMPLEMENTATION CHECKLIST                        |
+===============================================================================+

  PHASE 1: IDENTITY
  =================

  [ ] Integrate with central identity provider (AD, LDAP, SAML, OIDC)
  [ ] Enable MFA for ALL users (no exceptions)
  [ ] Implement strong password policies
  [ ] Configure account lockout policies
  [ ] Enable adaptive authentication (risk-based)
  [ ] Deploy FIDO2/WebAuthn for high-security users

  PHASE 2: NETWORK
  ================

  [ ] Deploy WALLIX in DMZ/management zone
  [ ] Block direct user-to-target access
  [ ] Enforce all access through WALLIX proxy
  [ ] Implement firewall rules (deny by default)
  [ ] Enable TLS 1.3 for all connections
  [ ] Segment networks by security level

  PHASE 3: ACCESS CONTROL
  =======================

  [ ] Define granular target groups
  [ ] Implement least privilege authorizations
  [ ] Enable just-in-time access for sensitive systems
  [ ] Configure approval workflows
  [ ] Set maximum session durations
  [ ] Implement time-based access restrictions

  PHASE 4: MONITORING
  ===================

  [ ] Enable session recording for all access
  [ ] Configure command restrictions/alerting
  [ ] Integrate with SIEM for correlation
  [ ] Enable real-time session monitoring
  [ ] Configure anomaly detection alerts
  [ ] Implement session termination capabilities

  PHASE 5: CREDENTIAL SECURITY
  ============================

  [ ] Store all credentials in vault (never on endpoints)
  [ ] Enable credential injection (users never see passwords)
  [ ] Implement automatic password rotation
  [ ] Configure credential checkout with time limits
  [ ] Rotate credentials after each checkout
  [ ] Monitor and alert on credential access

+===============================================================================+
```

---

## Security Hardening

### System Hardening

```
+===============================================================================+
|                    SECURITY HARDENING CHECKLIST                               |
+===============================================================================+
|                                                                               |
|  NETWORK SECURITY                                                             |
|  ================                                                             |
|                                                                               |
|  [ ] Deploy in isolated management network                                   |
|  [ ] Restrict source IPs for admin access                                    |
|  [ ] Use TLS 1.2+ for all connections                                        |
|  [ ] Disable unnecessary network services                                    |
|  [ ] Implement firewall rules (deny by default)                              |
|  [ ] Enable intrusion detection/prevention                                   |
|                                                                               |
|  AUTHENTICATION SECURITY                                                      |
|  =======================                                                      |
|                                                                               |
|  [ ] Require MFA for all administrative access                               |
|  [ ] Require MFA for critical target access                                  |
|  [ ] Use strong password policies                                            |
|  [ ] Implement account lockout                                               |
|  [ ] Review authentication logs regularly                                    |
|  [ ] Disable default/unused accounts                                         |
|                                                                               |
|  ENCRYPTION                                                                   |
|  ==========                                                                   |
|                                                                               |
|  [ ] Use AES-256 for credential encryption                                   |
|  [ ] Protect master encryption key (consider HSM)                            |
|  [ ] Enable TLS for database connections                                     |
|  [ ] Encrypt recording storage (at rest)                                     |
|  [ ] Use LDAPS (not LDAP) for directory                                      |
|                                                                               |
|  ACCESS CONTROL                                                               |
|  ==============                                                               |
|                                                                               |
|  [ ] Implement role-based access control                                     |
|  [ ] Separate admin and user roles                                           |
|  [ ] Require approval for critical access                                    |
|  [ ] Review authorizations quarterly                                         |
|  [ ] Remove access promptly on termination                                   |
|                                                                               |
|  AUDIT & MONITORING                                                           |
|  ==================                                                           |
|                                                                               |
|  [ ] Enable comprehensive audit logging                                      |
|  [ ] Forward logs to SIEM                                                    |
|  [ ] Configure alerting for security events                                  |
|  [ ] Protect audit logs from tampering                                       |
|  [ ] Retain logs per compliance requirements                                 |
|                                                                               |
+===============================================================================+
```

### Credential Security

```
+===============================================================================+
|                    CREDENTIAL SECURITY                                        |
+===============================================================================+
|                                                                               |
|  PASSWORD POLICIES                                                            |
|  =================                                                            |
|                                                                               |
|  Minimum Requirements:                                                        |
|  * Length: 16+ characters (20+ for critical)                                 |
|  * Complexity: Upper, lower, digits, special                                 |
|  * History: Remember 24 passwords                                            |
|  * Rotation: 30 days (critical), 90 days (standard)                          |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  ROTATION BEST PRACTICES                                                      |
|  =======================                                                      |
|                                                                               |
|  [x] Enable automatic rotation for all managed accounts                      |
|  [x] Verify password after rotation                                          |
|  [x] Configure reconciliation accounts                                       |
|  [x] Alert on rotation failures                                              |
|  [x] Test rotation in non-production first                                   |
|  [x] Document accounts with special rotation requirements                    |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  ACCESS TO CREDENTIALS                                                        |
|  =====================                                                        |
|                                                                               |
|  [x] Prefer credential injection (user never sees password)                  |
|  [x] If checkout needed, use time-limited checkout                           |
|  [x] Rotate after checkout/checkin                                           |
|  [x] Log all credential access                                               |
|  [x] Require justification for credential view                               |
|                                                                               |
+===============================================================================+
```

---

## Operational Excellence

### Daily Operations

```
+===============================================================================+
|                    OPERATIONAL BEST PRACTICES                                 |
+===============================================================================+
|                                                                               |
|  DAILY CHECKS                                                                 |
|  ============                                                                 |
|                                                                               |
|  [ ] Review system health dashboard                                          |
|  [ ] Check service status                                                    |
|  [ ] Review password rotation status                                         |
|  [ ] Monitor active sessions                                                 |
|  [ ] Check disk space (recordings)                                           |
|  [ ] Review security alerts                                                  |
|                                                                               |
|  WEEKLY CHECKS                                                                |
|  =============                                                                |
|                                                                               |
|  [ ] Review audit logs for anomalies                                         |
|  [ ] Verify backup completion                                                |
|  [ ] Check replication status (HA)                                           |
|  [ ] Review failed authentication attempts                                   |
|  [ ] Check certificate expiration                                            |
|  [ ] Review rotation failures                                                |
|                                                                               |
|  MONTHLY CHECKS                                                               |
|  ==============                                                               |
|                                                                               |
|  [ ] Review user access (attestation)                                        |
|  [ ] Review authorization policies                                           |
|  [ ] Test DR failover                                                        |
|  [ ] Review capacity utilization                                             |
|  [ ] Update documentation                                                    |
|  [ ] Plan capacity expansion if needed                                       |
|                                                                               |
|  QUARTERLY CHECKS                                                             |
|  ================                                                             |
|                                                                               |
|  [ ] Formal access review/certification                                      |
|  [ ] Penetration testing                                                     |
|  [ ] Full DR test                                                            |
|  [ ] Review and update policies                                              |
|  [ ] Training refresher for admins                                           |
|  [ ] Vendor security patches review                                          |
|                                                                               |
+===============================================================================+
```

### Monitoring & Alerting

```
+===============================================================================+
|                    MONITORING BEST PRACTICES                                  |
+===============================================================================+
|                                                                               |
|  CRITICAL ALERTS (Immediate Response)                                         |
|  ====================================                                         |
|                                                                               |
|  * Service down                                                              |
|  * Database unreachable                                                      |
|  * Cluster node failure                                                      |
|  * Authentication service failure                                            |
|  * Multiple failed admin logins                                              |
|  * Critical session policy violations                                        |
|                                                                               |
|  HIGH ALERTS (Response within 1 hour)                                         |
|  =====================================                                        |
|                                                                               |
|  * Disk space > 80%                                                          |
|  * Multiple password rotation failures                                       |
|  * Replication lag > 5 minutes                                               |
|  * Certificate expiring < 30 days                                            |
|  * Unusual session volume                                                    |
|                                                                               |
|  MEDIUM ALERTS (Response within 24 hours)                                     |
|  =========================================                                    |
|                                                                               |
|  * Disk space > 70%                                                          |
|  * Single rotation failure                                                   |
|  * User login from new location                                              |
|  * Long-running sessions                                                     |
|                                                                               |
|  LOW ALERTS (Review weekly)                                                   |
|  =============================                                                |
|                                                                               |
|  * Configuration changes                                                     |
|  * New user/group created                                                    |
|  * Authorization changes                                                     |
|                                                                               |
+===============================================================================+
```

---

## Performance Optimization

### Optimization Guidelines

```
+===============================================================================+
|                    PERFORMANCE OPTIMIZATION                                   |
+===============================================================================+
|                                                                               |
|  SIZING GUIDELINES                                                            |
|  =================                                                            |
|                                                                               |
|  +---------------------+--------+--------+--------+------------------------+  |
|  | Concurrent Sessions | CPU    | RAM    | Storage| Notes                  | |
|  +---------------------+--------+--------+--------+------------------------+  |
|  | Up to 50            | 4 cores| 8 GB   | 500 GB | Small deployment       | |
|  | 50-200              | 8 cores| 16 GB  | 1 TB   | Medium deployment      | |
|  | 200-500             | 16 core| 32 GB  | 2 TB   | Large deployment       | |
|  | 500+                | Multi-node cluster + external storage            | |
|  +---------------------+--------+--------+--------+------------------------+  |
|                                                                               |
|  STORAGE OPTIMIZATION                                                         |
|  ====================                                                         |
|                                                                               |
|  * Use SSD/NVMe for database                                                 |
|  * Use high-throughput storage for recordings                                |
|  * Implement recording archival policy                                       |
|  * Compress archived recordings                                              |
|  * Use external NAS/SAN for large deployments                                |
|                                                                               |
|  DATABASE OPTIMIZATION                                                        |
|  =====================                                                        |
|                                                                               |
|  * Regular VACUUM and ANALYZE                                                |
|  * Monitor connection pool usage                                             |
|  * Archive old session metadata                                              |
|  * Review slow query logs                                                    |
|                                                                               |
|  NETWORK OPTIMIZATION                                                         |
|  ====================                                                         |
|                                                                               |
|  * Minimize latency to targets                                               |
|  * Use dedicated management network                                          |
|  * Optimize MTU settings                                                     |
|  * Use local DNS caching                                                     |
|                                                                               |
+===============================================================================+
```

---

## Compliance & Audit

### Compliance Requirements

```
+===============================================================================+
|                    COMPLIANCE BEST PRACTICES                                  |
+===============================================================================+
|                                                                               |
|  AUDIT TRAIL REQUIREMENTS                                                     |
|  ========================                                                     |
|                                                                               |
|  [x] Log ALL privileged access                                               |
|  [x] Record ALL sessions to critical systems                                 |
|  [x] Capture WHO, WHAT, WHEN, WHERE, HOW                                     |
|  [x] Protect logs from tampering                                             |
|  [x] Retain logs per policy (typically 1-7 years)                            |
|  [x] Enable log forwarding to SIEM                                           |
|                                                                               |
|  RECORDING REQUIREMENTS                                                       |
|  ======================                                                       |
|                                                                               |
|  [x] Record all sessions to production systems                               |
|  [x] Record all sessions to systems with sensitive data                      |
|  [x] Enable keystroke logging                                                |
|  [x] Enable OCR for RDP sessions                                             |
|  [x] Retain recordings per compliance requirements                           |
|  [x] Implement recording integrity verification                              |
|                                                                               |
|  ACCESS REVIEW REQUIREMENTS                                                   |
|  ==========================                                                   |
|                                                                               |
|  [x] Quarterly access certification                                          |
|  [x] Document access review process                                          |
|  [x] Maintain evidence of reviews                                            |
|  [x] Promptly remove access when no longer needed                            |
|  [x] Document exceptions and approvals                                       |
|                                                                               |
+===============================================================================+
```

---

## Change Management

### Change Control

```
+===============================================================================+
|                    CHANGE MANAGEMENT                                          |
+===============================================================================+
|                                                                               |
|  CHANGE CATEGORIES                                                            |
|  =================                                                            |
|                                                                               |
|  STANDARD (Pre-approved)                                                      |
|  * Add new device/account                                                    |
|  * Add user to existing group                                                |
|  * Update device description                                                 |
|  * Trigger manual password rotation                                          |
|                                                                               |
|  NORMAL (Requires approval)                                                   |
|  * Create new authorization                                                  |
|  * Modify existing authorization                                             |
|  * Create new user group                                                     |
|  * Modify password policy                                                    |
|  * Add new domain                                                            |
|                                                                               |
|  CRITICAL (CAB approval required)                                             |
|  * System upgrade                                                            |
|  * Configuration changes affecting all users                                 |
|  * Changes to authentication settings                                        |
|  * HA/DR configuration changes                                               |
|  * Integration changes                                                       |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  CHANGE PROCESS                                                               |
|  ==============                                                               |
|                                                                               |
|  1. Request         - Document change request                                |
|  2. Review          - Technical and security review                          |
|  3. Approve         - Appropriate approval level                             |
|  4. Test            - Test in non-production                                 |
|  5. Implement       - Apply change with rollback plan                        |
|  6. Verify          - Confirm change successful                              |
|  7. Document        - Update documentation                                   |
|                                                                               |
+===============================================================================+
```

---

## Next Steps

Continue to [14 - Appendix](../14-appendix/README.md) for quick reference and cheat sheets.
