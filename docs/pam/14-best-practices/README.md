# 13 - Best Practices

## Table of Contents

1. [Design Best Practices](#design-best-practices)
2. [Security Hardening](#security-hardening)
3. [Operational Excellence](#operational-excellence)
4. [Performance Optimization](#performance-optimization)
5. [Compliance & Audit](#compliance--audit)
6. [Change Management](#change-management)
7. [High Availability Monitoring Best Practices](#high-availability-monitoring-best-practices)

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
|  [x] Deploy in DMZ or dedicated management network                            |
|  [x] Use redundant architecture for production                                |
|  [x] Separate Access Manager from Bastion core (large deployments)            |
|  [x] Use dedicated storage for recordings                                     |
|  [x] Plan for growth (sessions, storage, targets)                             |
|  [x] Document network flows and firewall rules                                |
|                                                                               |
|  DON'T:                                                                       |
|  ======                                                                       |
|                                                                               |
|  [ ] Deploy single node in production without DR plan                         |
|  [ ] Store recordings on local disk only                                      |
|  [ ] Use same network segment as general user traffic                         |
|  [ ] Undersize the system (CPU, memory, storage)                              |
|  [ ] Skip network segmentation between Bastion and targets                    |
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
|  +-- Production/                                                              |
|  |   +-- PROD-Linux-Servers                                                   |
|  |   +-- PROD-Windows-Servers                                                 |
|  |   +-- PROD-Databases                                                       |
|  |   +-- PROD-Network                                                         |
|  |                                                                            |
|  +-- Non-Production/                                                          |
|  |   +-- DEV-Servers                                                          |
|  |   +-- STG-Servers                                                          |
|  |   +-- TEST-Servers                                                         |
|  |                                                                            |
|  +-- Infrastructure/                                                          |
|      +-- MGMT-Hypervisors                                                     |
|      +-- MGMT-Network-Core                                                    |
|      +-- MGMT-Security-Appliances                                             |
|                                                                               |
|  NAMING CONVENTIONS                                                           |
|  ==================                                                           |
|                                                                               |
|  * Use consistent prefixes (PROD-, DEV-, STG-)                                |
|  * Include function in name (Servers, Databases, Network)                     |
|  * Avoid spaces (use hyphens or underscores)                                  |
|  * Keep names meaningful but concise                                          |
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
|  1. Start restrictive, add permissions as needed                              |
|  2. Use specific target groups, not domain-wide                               |
|  3. Limit subprotocols to required functionality                              |
|  4. Apply time restrictions where appropriate                                 |
|                                                                               |
|  EXAMPLE - Good Authorization Design:                                         |
|                                                                               |
|  +-------------------------------------------------------------------------+  |
|  |                                                                         |  |
|  |  Authorization: "web-admins-prod-ssh"                                   |  |
|  |                                                                         |  |
|  |  User Group:    Web-Administrators                                      |  |
|  |  Target Group:  PROD-Web-Servers-Root                                   |  |
|  |  Subprotocols:  SHELL only (no SCP, SFTP)                               |  |
|  |  Recording:     Required                                                |  |
|  |  Time Frame:    Business hours only                                     |  |
|  |  Approval:      Not required                                            |  |
|  |                                                                         |  |
|  +--------------------------------------------------------------------------+ |
|                                                                               |
|  EXAMPLE - Avoid This:                                                        |
|                                                                               |
|  +--------------------------------------------------------------------------+ |
|  |                                                                          | |
|  |  Authorization: "all-access"                                             | |
|  |                                                                          | |
|  |  User Group:    All-Users                                                | |
|  |  Target Group:  All-Targets                                              | |
|  |  Subprotocols:  All                                                      | |
|  |  Recording:     Optional                                                 | |
|  |  Time Frame:    Always                                                   | |
|  |                                                                          | |
|  |  [ ] Too broad, violates least privilege                                 | |
|  |                                                                          | |
|  +--------------------------------------------------------------------------+ |
|                                                                               |
+===============================================================================+
```

---

## Zero Trust Architecture

### Zero Trust Principles for PAM

```
+===============================================================================+
|                   ZERO TRUST ARCHITECTURE WITH WALLIX                         |
+===============================================================================+

  CORE PRINCIPLES
  ===============

  1. NEVER TRUST, ALWAYS VERIFY
     +---------------------------------------------------------------------+
     | Traditional Model         | Zero Trust Model                        |
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
  |   | 2. MFA Required    | TOTP, FortiToken Push                        |
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
  |   | Time-Limited Grant | Access valid for specific duration            |
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
  |   | Session Recording  | All privileged sessions recorded              |
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
|                   ZERO TRUST ACCESS FLOW                                      |
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
  |               | Deny   |    | Deny   |    | Deny   |    | Terminate    |
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
|                   ZERO TRUST IMPLEMENTATION CHECKLIST                         |
+===============================================================================+

  PHASE 1: IDENTITY
  =================

  [ ] Integrate with central identity provider (AD, LDAP, SAML, OIDC)
  [ ] Enable MFA for ALL users (no exceptions)
  [ ] Implement strong password policies
  [ ] Configure account lockout policies
  [ ] Enable adaptive authentication (risk-based)

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
|  [ ] Deploy in isolated management network                                    |
|  [ ] Restrict source IPs for admin access                                     |
|  [ ] Use TLS 1.2+ for all connections                                         |
|  [ ] Disable unnecessary network services                                     |
|  [ ] Implement firewall rules (deny by default)                               |
|  [ ] Enable intrusion detection/prevention                                    |
|                                                                               |
|  AUTHENTICATION SECURITY                                                      |
|  =======================                                                      |
|                                                                               |
|  [ ] Require MFA for all administrative access                                |
|  [ ] Require MFA for critical target access                                   |
|  [ ] Use strong password policies                                             |
|  [ ] Implement account lockout                                                |
|  [ ] Review authentication logs regularly                                     |
|  [ ] Disable default/unused accounts                                          |
|                                                                               |
|  ENCRYPTION                                                                   |
|  ==========                                                                   |
|                                                                               |
|  [ ] Use AES-256 for credential encryption                                    |
|  [ ] Protect master encryption key (consider HSM)                             |
|  [ ] Enable TLS for database connections                                      |
|  [ ] Encrypt recording storage (at rest)                                      |
|  [ ] Use LDAPS (not LDAP) for directory                                       |
|                                                                               |
|  ACCESS CONTROL                                                               |
|  ==============                                                               |
|                                                                               |
|  [ ] Implement role-based access control                                      |
|  [ ] Separate admin and user roles                                            |
|  [ ] Require approval for critical access                                     |
|  [ ] Review authorizations quarterly                                          |
|  [ ] Remove access promptly on termination                                    |
|                                                                               |
|  AUDIT & MONITORING                                                           |
|  ==================                                                           |
|                                                                               |
|  [ ] Enable comprehensive audit logging                                       |
|  [ ] Forward logs to SIEM                                                     |
|  [ ] Configure alerting for security events                                   |
|  [ ] Protect audit logs from tampering                                        |
|  [ ] Retain logs per compliance requirements                                  |
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
|  * Length: 16+ characters (20+ for critical)                                  |
|  * Complexity: Upper, lower, digits, special                                  |
|  * History: Remember 24 passwords                                             |
|  * Rotation: 30 days (critical), 90 days (standard)                           |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  ROTATION BEST PRACTICES                                                      |
|  =======================                                                      |
|                                                                               |
|  [x] Enable automatic rotation for all managed accounts                       |
|  [x] Verify password after rotation                                           |
|  [x] Configure reconciliation accounts                                        |
|  [x] Alert on rotation failures                                               |
|  [x] Test rotation in non-production first                                    |
|  [x] Document accounts with special rotation requirements                     |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  ACCESS TO CREDENTIALS                                                        |
|  =====================                                                        |
|                                                                               |
|  [x] Prefer credential injection (user never sees password)                   |
|  [x] If checkout needed, use time-limited checkout                            |
|  [x] Rotate after checkout/checkin                                            |
|  [x] Log all credential access                                                |
|  [x] Require justification for credential view                                |
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
|  [ ] Review system health dashboard                                           |
|  [ ] Check service status                                                     |
|  [ ] Review password rotation status                                          |
|  [ ] Monitor active sessions                                                  |
|  [ ] Check disk space (recordings)                                            |
|  [ ] Review security alerts                                                   |
|                                                                               |
|  WEEKLY CHECKS                                                                |
|  =============                                                                |
|                                                                               |
|  [ ] Review audit logs for anomalies                                          |
|  [ ] Verify backup completion                                                 |
|  [ ] Check replication status (HA)                                            |
|  [ ] Review failed authentication attempts                                    |
|  [ ] Check certificate expiration                                             |
|  [ ] Review rotation failures                                                 |
|                                                                               |
|  MONTHLY CHECKS                                                               |
|  ==============                                                               |
|                                                                               |
|  [ ] Review user access (attestation)                                         |
|  [ ] Review authorization policies                                            |
|  [ ] Test DR failover                                                         |
|  [ ] Review capacity utilization                                              |
|  [ ] Update documentation                                                     |
|  [ ] Plan capacity expansion if needed                                        |
|                                                                               |
|  QUARTERLY CHECKS                                                             |
|  ================                                                             |
|                                                                               |
|  [ ] Formal access review/certification                                       |
|  [ ] Penetration testing                                                      |
|  [ ] Full DR test                                                             |
|  [ ] Review and update policies                                               |
|  [ ] Training refresher for admins                                            |
|  [ ] Vendor security patches review                                           |
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
|  * Service down                                                               |
|  * Database unreachable                                                       |
|  * Cluster node failure                                                       |
|  * Authentication service failure                                             |
|  * Multiple failed admin logins                                               |
|  * Critical session policy violations                                         |
|                                                                               |
|  HIGH ALERTS (Response within 1 hour)                                         |
|  =====================================                                        |
|                                                                               |
|  * Disk space > 80%                                                           |
|  * Multiple password rotation failures                                        |
|  * Replication lag > 5 minutes                                                |
|  * Certificate expiring < 30 days                                             |
|  * Unusual session volume                                                     |
|                                                                               |
|  MEDIUM ALERTS (Response within 24 hours)                                     |
|  =========================================                                    |
|                                                                               |
|  * Disk space > 70%                                                           |
|  * Single rotation failure                                                    |
|  * User login from new location                                               |
|  * Long-running sessions                                                      |
|                                                                               |
|  LOW ALERTS (Review weekly)                                                   |
|  =============================                                                |
|                                                                               |
|  * Configuration changes                                                      |
|  * New user/group created                                                     |
|  * Authorization changes                                                      |
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
|  | Concurrent Sessions | CPU    | RAM    | Storage| Notes                  |  |
|  +---------------------+--------+--------+--------+------------------------+  |
|  | Up to 50            | 4 cores| 8 GB   | 500 GB | Small deployment       |  |
|  | 50-200              | 8 cores| 16 GB  | 1 TB   | Medium deployment      |  |
|  | 200-500             | 16 core| 32 GB  | 2 TB   | Large deployment       |  |
|  | 500+                | Multi-node cluster + external storage             |  |
|  +---------------------+--------+--------+--------+------------------------+  |
|                                                                               |
|  STORAGE OPTIMIZATION                                                         |
|  ====================                                                         |
|                                                                               |
|  * Use SSD/NVMe for database                                                  |
|  * Use high-throughput storage for recordings                                 |
|  * Implement recording archival policy                                        |
|  * Compress archived recordings                                               |
|  * Use external NAS/SAN for large deployments                                 |
|                                                                               |
|  DATABASE OPTIMIZATION                                                        |
|  =====================                                                        |
|                                                                               |
|  * Regular VACUUM and ANALYZE                                                 |
|  * Monitor connection pool usage                                              |
|  * Archive old session metadata                                               |
|  * Review slow query logs                                                     |
|                                                                               |
|  NETWORK OPTIMIZATION                                                         |
|  ====================                                                         |
|                                                                               |
|  * Minimize latency to targets                                                |
|  * Use dedicated management network                                           |
|  * Optimize MTU settings                                                      |
|  * Use local DNS caching                                                      |
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
|  [x] Log ALL privileged access                                                |
|  [x] Record ALL sessions to critical systems                                  |
|  [x] Capture WHO, WHAT, WHEN, WHERE, HOW                                      |
|  [x] Protect logs from tampering                                              |
|  [x] Retain logs per policy (typically 1-7 years)                             |
|  [x] Enable log forwarding to SIEM                                            |
|                                                                               |
|  RECORDING REQUIREMENTS                                                       |
|  ======================                                                       |
|                                                                               |
|  [x] Record all sessions to production systems                                |
|  [x] Record all sessions to systems with sensitive data                       |
|  [x] Enable keystroke logging                                                 |
|  [x] Enable OCR for RDP sessions                                              |
|  [x] Retain recordings per compliance requirements                            |
|  [x] Implement recording integrity verification                               |
|                                                                               |
|  ACCESS REVIEW REQUIREMENTS                                                   |
|  ==========================                                                   |
|                                                                               |
|  [x] Quarterly access certification                                           |
|  [x] Document access review process                                           |
|  [x] Maintain evidence of reviews                                             |
|  [x] Promptly remove access when no longer needed                             |
|  [x] Document exceptions and approvals                                        |
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
|  * Add new device/account                                                     |
|  * Add user to existing group                                                 |
|  * Update device description                                                  |
|  * Trigger manual password rotation                                           |
|                                                                               |
|  NORMAL (Requires approval)                                                   |
|  * Create new authorization                                                   |
|  * Modify existing authorization                                              |
|  * Create new user group                                                      |
|  * Modify password policy                                                     |
|  * Add new domain                                                             |
|                                                                               |
|  CRITICAL (CAB approval required)                                             |
|  * System upgrade                                                             |
|  * Configuration changes affecting all users                                  |
|  * Changes to authentication settings                                         |
|  * HA/DR configuration changes                                                |
|  * Integration changes                                                        |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  CHANGE PROCESS                                                               |
|  ==============                                                               |
|                                                                               |
|  1. Request         - Document change request                                 |
|  2. Review          - Technical and security review                           |
|  3. Approve         - Appropriate approval level                              |
|  4. Test            - Test in non-production                                  |
|  5. Implement       - Apply change with rollback plan                         |
|  6. Verify          - Confirm change successful                               |
|  7. Document        - Update documentation                                    |
|                                                                               |
+===============================================================================+
```

---

## High Availability Monitoring Best Practices

### Overview

Effective HA monitoring is critical for maintaining cluster health, detecting issues before they cause service disruption, and ensuring seamless failover capabilities. This section provides comprehensive monitoring strategies, scripts, and alerting configurations.

### Key Metrics to Monitor

```
+===============================================================================+
|                    HA CLUSTER METRICS MONITORING                              |
+===============================================================================+
```

| Metric Name | Threshold Values | Check Frequency | Criticality | Alert Action |
|-------------|------------------|-----------------|-------------|--------------|
| **MariaDB Replication Lag** | Warning: >5s, Critical: >30s | Every 60s | Critical | Page on-call, investigate replication |
| **Corosync Ring Status** | Any ring faulty | Every 30s | Critical | Page on-call, check network |
| **Pacemaker Resource Status** | Any resource failed/stopped | Every 30s | Critical | Page on-call, attempt recovery |
| **VIP Failover Time** | Warning: >5s, Critical: >10s | On failover event | High | Alert ops team, review logs |
| **Session Sync Status** | Any sync failure | Every 60s | High | Alert ops team, check connectivity |
| **Cluster Quorum** | Lost quorum | Every 30s | Critical | Page on-call immediately |
| **Database Connection Pool** | Warning: >80%, Critical: >95% | Every 60s | High | Alert ops team, scale if needed |
| **Disk Space (Recordings)** | Warning: >75%, Critical: >90% | Every 300s | High | Alert ops team, archive/cleanup |
| **Node CPU Usage** | Warning: >80%, Critical: >95% | Every 60s | Medium | Alert ops team, investigate |
| **Node Memory Usage** | Warning: >85%, Critical: >95% | Every 60s | High | Alert ops team, investigate |
| **Split-Brain Detection** | Any split-brain detected | Every 30s | Critical | Page on-call immediately, manual intervention |
| **Certificate Expiration** | Warning: <30d, Critical: <7d | Every 86400s | High | Alert ops team, renew certificates |
| **Backup Status** | Last backup >24h ago | Every 3600s | Medium | Alert ops team, verify backup system |
| **WAL Archive Status** | Archive lag >10 WAL files | Every 300s | Medium | Alert ops team, check archiving |
| **Network Latency (Nodes)** | Warning: >10ms, Critical: >50ms | Every 60s | High | Alert network team, investigate |

### Automated Monitoring Script

Complete monitoring script for HA clusters that checks all critical metrics and sends alerts:

```bash
#!/bin/bash
#
# wallix-ha-monitor.sh
# Comprehensive HA cluster health monitoring script
#
# Usage: Run via cron every 1-5 minutes
# Example crontab: */5 * * * * /usr/local/bin/wallix-ha-monitor.sh
#
# Dependencies:
#   - crm (pacemaker)
#   - mysql client
#   - mailx or sendmail (for email alerts)
#   - curl (for webhook alerts)
#

set -euo pipefail

#------------------------------------------------------------------------------
# CONFIGURATION
#------------------------------------------------------------------------------

SCRIPT_NAME="wallix-ha-monitor"
LOG_FILE="/var/log/wallix/${SCRIPT_NAME}.log"
STATE_FILE="/var/lib/wallix/${SCRIPT_NAME}.state"
ALERT_WEBHOOK_URL="${ALERT_WEBHOOK_URL:-}"  # Slack/Teams/etc webhook
ALERT_EMAIL="${ALERT_EMAIL:-ops@example.com}"

# Thresholds
REPLICATION_LAG_WARN=5      # seconds
REPLICATION_LAG_CRIT=30     # seconds
DISK_SPACE_WARN=75          # percent
DISK_SPACE_CRIT=90          # percent
CPU_WARN=80                 # percent
CPU_CRIT=95                 # percent
MEM_WARN=85                 # percent
MEM_CRIT=95                 # percent
NETWORK_LATENCY_WARN=10     # milliseconds
NETWORK_LATENCY_CRIT=50     # milliseconds

# MariaDB credentials (read from environment or config file)
DB_USER="${DB_USER:-wallixmon}"
DB_PASS="${DB_PASS:-}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-3306}"

#------------------------------------------------------------------------------
# UTILITY FUNCTIONS
#------------------------------------------------------------------------------

log() {
    local level=$1
    shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*" | tee -a "$LOG_FILE"
}

alert() {
    local severity=$1
    local message=$2

    log "ALERT" "[$severity] $message"

    # Send email alert
    if command -v mailx >/dev/null 2>&1; then
        echo "$message" | mailx -s "[WALLIX HA $severity] $(hostname)" "$ALERT_EMAIL"
    fi

    # Send webhook alert (Slack, Teams, etc.)
    if [[ -n "$ALERT_WEBHOOK_URL" ]]; then
        curl -X POST -H 'Content-Type: application/json' \
            -d "{\"text\":\"[WALLIX HA $severity] $(hostname): $message\"}" \
            "$ALERT_WEBHOOK_URL" 2>/dev/null || true
    fi
}

check_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        log "ERROR" "Required command not found: $1"
        return 1
    fi
}

#------------------------------------------------------------------------------
# HEALTH CHECK FUNCTIONS
#------------------------------------------------------------------------------

check_mariadb_replication() {
    log "INFO" "Checking MariaDB replication status..."

    if ! check_command mysql; then
        alert "CRITICAL" "MySQL client not available"
        return 1
    fi

    local repl_status
    repl_status=$(mysql -u"$DB_USER" -p"$DB_PASS" -h"$DB_HOST" -P"$DB_PORT" \
        -e "SHOW SLAVE STATUS\G" 2>/dev/null || echo "")

    if [[ -z "$repl_status" ]]; then
        log "WARN" "No replication configured or connection failed"
        return 0
    fi

    # Check Slave_IO_Running
    local io_running
    io_running=$(echo "$repl_status" | grep "Slave_IO_Running:" | awk '{print $2}')
    if [[ "$io_running" != "Yes" ]]; then
        alert "CRITICAL" "MariaDB replication IO thread not running"
        return 1
    fi

    # Check Slave_SQL_Running
    local sql_running
    sql_running=$(echo "$repl_status" | grep "Slave_SQL_Running:" | awk '{print $2}')
    if [[ "$sql_running" != "Yes" ]]; then
        alert "CRITICAL" "MariaDB replication SQL thread not running"
        return 1
    fi

    # Check replication lag
    local seconds_behind
    seconds_behind=$(echo "$repl_status" | grep "Seconds_Behind_Master:" | awk '{print $2}')

    if [[ "$seconds_behind" == "NULL" ]]; then
        alert "CRITICAL" "MariaDB replication lag is NULL (broken replication)"
        return 1
    fi

    if (( seconds_behind > REPLICATION_LAG_CRIT )); then
        alert "CRITICAL" "MariaDB replication lag is ${seconds_behind}s (threshold: ${REPLICATION_LAG_CRIT}s)"
        return 1
    elif (( seconds_behind > REPLICATION_LAG_WARN )); then
        alert "WARNING" "MariaDB replication lag is ${seconds_behind}s (threshold: ${REPLICATION_LAG_WARN}s)"
    else
        log "INFO" "MariaDB replication healthy (lag: ${seconds_behind}s)"
    fi

    return 0
}

check_corosync_cluster() {
    log "INFO" "Checking Corosync cluster status..."

    if ! check_command corosync-quorumtool; then
        alert "CRITICAL" "Corosync tools not available"
        return 1
    fi

    # Check quorum
    local quorum_status
    quorum_status=$(corosync-quorumtool -s 2>/dev/null || echo "")

    if echo "$quorum_status" | grep -q "Quorate: Yes"; then
        log "INFO" "Cluster has quorum"
    else
        alert "CRITICAL" "Cluster has LOST QUORUM - immediate attention required"
        return 1
    fi

    # Check ring status
    local ring_status
    ring_status=$(corosync-cfgtool -s 2>/dev/null || echo "")

    if echo "$ring_status" | grep -qi "faulty"; then
        alert "CRITICAL" "Corosync ring is FAULTY"
        return 1
    fi

    log "INFO" "Corosync cluster healthy"
    return 0
}

check_pacemaker_resources() {
    log "INFO" "Checking Pacemaker resource status..."

    if ! check_command crm; then
        alert "CRITICAL" "Pacemaker CRM tools not available"
        return 1
    fi

    # Get resource status
    local resource_status
    resource_status=$(crm_mon -1 -r 2>/dev/null || echo "")

    # Check for failed resources
    if echo "$resource_status" | grep -qi "FAILED"; then
        local failed_resources
        failed_resources=$(echo "$resource_status" | grep -i "FAILED" || echo "")
        alert "CRITICAL" "Pacemaker resources FAILED: $failed_resources"
        return 1
    fi

    # Check for stopped resources
    if echo "$resource_status" | grep -qi "Stopped"; then
        local stopped_resources
        stopped_resources=$(echo "$resource_status" | grep -i "Stopped" || echo "")
        alert "WARNING" "Pacemaker resources STOPPED: $stopped_resources"
    fi

    log "INFO" "Pacemaker resources healthy"
    return 0
}

check_vip_status() {
    log "INFO" "Checking VIP status..."

    # Get configured VIPs from Pacemaker
    local vip_resources
    vip_resources=$(crm configure show 2>/dev/null | grep "primitive.*IPaddr2" | awk '{print $2}' || echo "")

    if [[ -z "$vip_resources" ]]; then
        log "WARN" "No VIP resources configured"
        return 0
    fi

    for vip in $vip_resources; do
        local vip_status
        vip_status=$(crm resource status "$vip" 2>/dev/null || echo "")

        if echo "$vip_status" | grep -qi "running"; then
            local vip_node
            vip_node=$(echo "$vip_status" | grep -i "running" | awk '{print $NF}')
            log "INFO" "VIP $vip is running on $vip_node"
        else
            alert "CRITICAL" "VIP $vip is NOT running"
            return 1
        fi
    done

    return 0
}

check_wallix_service() {
    log "INFO" "Checking WALLIX Bastion service..."

    if systemctl is-active --quiet wallix-bastion; then
        log "INFO" "WALLIX Bastion service is active"
    else
        alert "CRITICAL" "WALLIX Bastion service is NOT active"
        return 1
    fi

    # Check service status via wabadmin
    if check_command wabadmin; then
        local wab_status
        wab_status=$(wabadmin status 2>/dev/null || echo "")

        if echo "$wab_status" | grep -qi "running"; then
            log "INFO" "WALLIX Bastion application is running"
        else
            alert "CRITICAL" "WALLIX Bastion application is NOT running properly"
            return 1
        fi
    fi

    return 0
}

check_disk_space() {
    log "INFO" "Checking disk space..."

    # Check recording storage
    local recording_path="/var/wab/recorded"
    if [[ -d "$recording_path" ]]; then
        local disk_usage
        disk_usage=$(df "$recording_path" | tail -1 | awk '{print $5}' | sed 's/%//')

        if (( disk_usage >= DISK_SPACE_CRIT )); then
            alert "CRITICAL" "Disk space critical: ${disk_usage}% used on $recording_path"
            return 1
        elif (( disk_usage >= DISK_SPACE_WARN )); then
            alert "WARNING" "Disk space warning: ${disk_usage}% used on $recording_path"
        else
            log "INFO" "Disk space healthy: ${disk_usage}% used on $recording_path"
        fi
    fi

    # Check root filesystem
    local root_usage
    root_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')

    if (( root_usage >= DISK_SPACE_CRIT )); then
        alert "CRITICAL" "Root disk space critical: ${root_usage}% used"
        return 1
    elif (( root_usage >= DISK_SPACE_WARN )); then
        alert "WARNING" "Root disk space warning: ${root_usage}% used"
    fi

    return 0
}

check_system_resources() {
    log "INFO" "Checking system resources..."

    # Check CPU usage
    local cpu_usage
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//' || echo "0")
    cpu_usage=${cpu_usage%.*}  # Remove decimal

    if (( cpu_usage >= CPU_CRIT )); then
        alert "CRITICAL" "CPU usage critical: ${cpu_usage}%"
    elif (( cpu_usage >= CPU_WARN )); then
        alert "WARNING" "CPU usage high: ${cpu_usage}%"
    else
        log "INFO" "CPU usage: ${cpu_usage}%"
    fi

    # Check memory usage
    local mem_usage
    mem_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100}')

    if (( mem_usage >= MEM_CRIT )); then
        alert "CRITICAL" "Memory usage critical: ${mem_usage}%"
    elif (( mem_usage >= MEM_WARN )); then
        alert "WARNING" "Memory usage high: ${mem_usage}%"
    else
        log "INFO" "Memory usage: ${mem_usage}%"
    fi

    return 0
}

check_split_brain() {
    log "INFO" "Checking for split-brain condition..."

    # Check if multiple nodes think they are master
    local cluster_status
    cluster_status=$(crm_mon -1 2>/dev/null || echo "")

    # This is a simplified check - production should use more sophisticated detection
    if echo "$cluster_status" | grep -c "Online:" | grep -q "^1$"; then
        log "INFO" "Single cluster partition detected (normal)"
    else
        # Multiple partitions might exist
        alert "WARNING" "Possible cluster partition detected - verify manually"
    fi

    return 0
}

check_network_latency() {
    log "INFO" "Checking inter-node network latency..."

    # Get peer node IPs from Corosync
    local peer_nodes
    peer_nodes=$(corosync-cmapctl 2>/dev/null | grep "members.*ip" | awk '{print $3}' | tr -d '(' | tr -d ')' || echo "")

    local this_node_ip
    this_node_ip=$(hostname -I | awk '{print $1}')

    for node_ip in $peer_nodes; do
        if [[ "$node_ip" == "$this_node_ip" ]]; then
            continue
        fi

        # Ping peer node
        if command -v ping >/dev/null 2>&1; then
            local latency
            latency=$(ping -c 3 -W 2 "$node_ip" 2>/dev/null | tail -1 | awk -F'/' '{print $5}' | cut -d'.' -f1 || echo "999")

            if (( latency >= NETWORK_LATENCY_CRIT )); then
                alert "CRITICAL" "Network latency to $node_ip is ${latency}ms (critical threshold: ${NETWORK_LATENCY_CRIT}ms)"
            elif (( latency >= NETWORK_LATENCY_WARN )); then
                alert "WARNING" "Network latency to $node_ip is ${latency}ms (warning threshold: ${NETWORK_LATENCY_WARN}ms)"
            else
                log "INFO" "Network latency to $node_ip: ${latency}ms"
            fi
        fi
    done

    return 0
}

#------------------------------------------------------------------------------
# MAIN EXECUTION
#------------------------------------------------------------------------------

main() {
    log "INFO" "Starting HA cluster health check..."

    # Create log and state directories
    mkdir -p "$(dirname "$LOG_FILE")" "$(dirname "$STATE_FILE")"

    local overall_status=0

    # Run all health checks
    check_wallix_service || overall_status=1
    check_mariadb_replication || overall_status=1
    check_corosync_cluster || overall_status=1
    check_pacemaker_resources || overall_status=1
    check_vip_status || overall_status=1
    check_disk_space || overall_status=1
    check_system_resources || overall_status=1
    check_split_brain || overall_status=1
    check_network_latency || overall_status=1

    # Save status to state file
    echo "timestamp=$(date +%s)" > "$STATE_FILE"
    echo "status=$overall_status" >> "$STATE_FILE"

    if (( overall_status == 0 )); then
        log "INFO" "HA cluster health check completed - ALL CHECKS PASSED"
    else
        log "ERROR" "HA cluster health check completed - SOME CHECKS FAILED"
    fi

    return $overall_status
}

# Execute main function
main "$@"
```

**Installation:**

```bash
# Install script
sudo mkdir -p /usr/local/bin
sudo cp wallix-ha-monitor.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/wallix-ha-monitor.sh

# Create log directory
sudo mkdir -p /var/log/wallix /var/lib/wallix
sudo chown wallix:wallix /var/log/wallix /var/lib/wallix

# Create monitoring database user
mysql -e "CREATE USER 'wallixmon'@'localhost' IDENTIFIED BY 'SecurePassword123!';"
mysql -e "GRANT REPLICATION CLIENT ON *.* TO 'wallixmon'@'localhost';"

# Configure environment
cat > /etc/default/wallix-ha-monitor <<'EOF'
DB_USER=wallixmon
DB_PASS=SecurePassword123!
DB_HOST=localhost
DB_PORT=3306
ALERT_EMAIL=ops@example.com
ALERT_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
EOF

# Add to crontab (run every 5 minutes)
echo "*/5 * * * * source /etc/default/wallix-ha-monitor && /usr/local/bin/wallix-ha-monitor.sh" | sudo crontab -u wallix -
```

### Prometheus Exporter Metrics

If using Prometheus for monitoring, expose these key metrics:

**Core HA Metrics:**

```yaml
# wallix_cluster_status
# Values: 0 = offline, 1 = online, 2 = degraded, 3 = maintenance
wallix_cluster_status{node="bastion01"} 1

# wallix_replication_lag_seconds
# MariaDB replication lag in seconds
wallix_replication_lag_seconds{node="bastion01",master="bastion02"} 2.5

# wallix_node_role
# Values: 0 = standby, 1 = master
wallix_node_role{node="bastion01"} 1

# wallix_vip_status
# Values: 0 = not running, 1 = running on this node
wallix_vip_status{node="bastion01",vip="192.168.1.100"} 1

# wallix_cluster_quorum
# Values: 0 = no quorum, 1 = has quorum
wallix_cluster_quorum{cluster="wallix-ha"} 1

# wallix_pacemaker_resource_status
# Values: 0 = stopped, 1 = started, 2 = failed
wallix_pacemaker_resource_status{resource="wallix-bastion"} 1

# wallix_corosync_ring_status
# Values: 0 = faulty, 1 = healthy
wallix_corosync_ring_status{ring="0"} 1

# wallix_session_sync_lag_seconds
# Session synchronization lag between nodes
wallix_session_sync_lag_seconds{node="bastion01",peer="bastion02"} 0.3

# wallix_active_sessions
# Number of active sessions
wallix_active_sessions{node="bastion01"} 42

# wallix_failover_duration_seconds
# Time taken for last VIP failover
wallix_failover_duration_seconds{vip="192.168.1.100"} 3.2
```

**Example Prometheus Queries:**

```promql
# Check if any node has lost quorum
wallix_cluster_quorum == 0

# Check replication lag across all nodes
wallix_replication_lag_seconds > 5

# Check for failed Pacemaker resources
wallix_pacemaker_resource_status == 2

# Check for nodes in degraded state
wallix_cluster_status == 2

# Calculate average failover time over last 24h
avg_over_time(wallix_failover_duration_seconds[24h])

# Alert on high replication lag
rate(wallix_replication_lag_seconds[5m]) > 10

# Check VIP distribution across nodes
sum by (node) (wallix_vip_status)
```

**Sample Prometheus Scrape Configuration:**

```yaml
scrape_configs:
  - job_name: 'wallix-ha-cluster'
    scrape_interval: 30s
    scrape_timeout: 10s
    static_configs:
      - targets:
          - 'bastion01.example.com:9100'
          - 'bastion02.example.com:9100'
    relabel_configs:
      - source_labels: [__address__]
        target_label: instance
      - source_labels: [__address__]
        regex: '([^:]+):.*'
        target_label: node
        replacement: '$1'
```

### Alertmanager Rules

Complete Prometheus alert rules for HA monitoring:

```yaml
groups:
  - name: wallix_ha_cluster
    interval: 30s
    rules:
      # CRITICAL ALERTS

      - alert: WallixClusterQuorumLost
        expr: wallix_cluster_quorum == 0
        for: 1m
        labels:
          severity: critical
          component: cluster
        annotations:
          summary: "WALLIX cluster has lost quorum"
          description: "Cluster {{ $labels.cluster }} has lost quorum. Immediate intervention required."
          runbook: "https://docs.example.com/runbooks/wallix-quorum-loss"

      - alert: WallixNodeOffline
        expr: wallix_cluster_status == 0
        for: 2m
        labels:
          severity: critical
          component: node
        annotations:
          summary: "WALLIX node {{ $labels.node }} is offline"
          description: "Node {{ $labels.node }} has been offline for 2 minutes."
          runbook: "https://docs.example.com/runbooks/wallix-node-offline"

      - alert: WallixReplicationBroken
        expr: wallix_replication_lag_seconds == -1
        for: 1m
        labels:
          severity: critical
          component: replication
        annotations:
          summary: "MariaDB replication is broken on {{ $labels.node }}"
          description: "Replication from {{ $labels.master }} to {{ $labels.node }} is broken."
          runbook: "https://docs.example.com/runbooks/wallix-replication-broken"

      - alert: WallixPacemakerResourceFailed
        expr: wallix_pacemaker_resource_status == 2
        for: 1m
        labels:
          severity: critical
          component: pacemaker
        annotations:
          summary: "Pacemaker resource {{ $labels.resource }} has failed"
          description: "Resource {{ $labels.resource }} on node {{ $labels.node }} is in failed state."
          runbook: "https://docs.example.com/runbooks/wallix-pacemaker-failure"

      - alert: WallixVIPNotRunning
        expr: sum by (vip) (wallix_vip_status) == 0
        for: 1m
        labels:
          severity: critical
          component: vip
        annotations:
          summary: "VIP {{ $labels.vip }} is not running on any node"
          description: "Virtual IP {{ $labels.vip }} is not active. Service may be unavailable."
          runbook: "https://docs.example.com/runbooks/wallix-vip-down"

      - alert: WallixCorosyncRingFaulty
        expr: wallix_corosync_ring_status == 0
        for: 1m
        labels:
          severity: critical
          component: corosync
        annotations:
          summary: "Corosync ring {{ $labels.ring }} is faulty"
          description: "Corosync communication ring {{ $labels.ring }} is in faulty state."
          runbook: "https://docs.example.com/runbooks/wallix-corosync-ring"

      # HIGH SEVERITY ALERTS

      - alert: WallixReplicationLagHigh
        expr: wallix_replication_lag_seconds > 30
        for: 5m
        labels:
          severity: high
          component: replication
        annotations:
          summary: "High replication lag on {{ $labels.node }}"
          description: "Replication lag is {{ $value }}s on {{ $labels.node }} (threshold: 30s)."
          runbook: "https://docs.example.com/runbooks/wallix-replication-lag"

      - alert: WallixClusterDegraded
        expr: wallix_cluster_status == 2
        for: 5m
        labels:
          severity: high
          component: cluster
        annotations:
          summary: "WALLIX cluster is in degraded state"
          description: "Node {{ $labels.node }} is reporting degraded cluster status."
          runbook: "https://docs.example.com/runbooks/wallix-cluster-degraded"

      - alert: WallixFailoverSlow
        expr: wallix_failover_duration_seconds > 10
        for: 1m
        labels:
          severity: high
          component: failover
        annotations:
          summary: "Slow VIP failover detected"
          description: "VIP {{ $labels.vip }} took {{ $value }}s to failover (threshold: 10s)."
          runbook: "https://docs.example.com/runbooks/wallix-slow-failover"

      - alert: WallixSessionSyncLagHigh
        expr: wallix_session_sync_lag_seconds > 5
        for: 3m
        labels:
          severity: high
          component: session-sync
        annotations:
          summary: "High session sync lag between nodes"
          description: "Session sync lag is {{ $value }}s between {{ $labels.node }} and {{ $labels.peer }}."
          runbook: "https://docs.example.com/runbooks/wallix-session-sync"

      # MEDIUM SEVERITY ALERTS

      - alert: WallixReplicationLagWarning
        expr: wallix_replication_lag_seconds > 5 and wallix_replication_lag_seconds <= 30
        for: 10m
        labels:
          severity: medium
          component: replication
        annotations:
          summary: "Replication lag warning on {{ $labels.node }}"
          description: "Replication lag is {{ $value }}s on {{ $labels.node }} (warning threshold: 5s)."
          runbook: "https://docs.example.com/runbooks/wallix-replication-lag"

      - alert: WallixHighSessionCount
        expr: wallix_active_sessions > 450
        for: 15m
        labels:
          severity: medium
          component: capacity
        annotations:
          summary: "High session count on {{ $labels.node }}"
          description: "Node {{ $labels.node }} has {{ $value }} active sessions (capacity: 500)."
          runbook: "https://docs.example.com/runbooks/wallix-capacity-planning"

      # INFORMATIONAL ALERTS

      - alert: WallixVIPMigrated
        expr: changes(wallix_vip_status[5m]) > 0
        for: 1m
        labels:
          severity: info
          component: vip
        annotations:
          summary: "VIP {{ $labels.vip }} has migrated"
          description: "VIP {{ $labels.vip }} has moved to a different node."
          runbook: "https://docs.example.com/runbooks/wallix-vip-migration"

  - name: wallix_ha_cluster_multi_alert
    interval: 60s
    rules:
      - alert: WallixSplitBrainDetected
        expr: count(wallix_node_role == 1) > 1
        for: 1m
        labels:
          severity: critical
          component: cluster
        annotations:
          summary: "POSSIBLE SPLIT-BRAIN: Multiple nodes report as master"
          description: "{{ $value }} nodes are reporting master role. Manual intervention required immediately."
          runbook: "https://docs.example.com/runbooks/wallix-split-brain"

      - alert: WallixNoMasterNode
        expr: count(wallix_node_role == 1) == 0
        for: 2m
        labels:
          severity: critical
          component: cluster
        annotations:
          summary: "No master node in cluster"
          description: "No node is currently in master role. Service may be unavailable."
          runbook: "https://docs.example.com/runbooks/wallix-no-master"
```

**Alertmanager Configuration Example:**

```yaml
route:
  receiver: 'wallix-ops-team'
  group_by: ['alertname', 'cluster', 'node']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 12h
  routes:
    - match:
        severity: critical
      receiver: 'wallix-pagerduty'
      continue: true

    - match:
        severity: high
      receiver: 'wallix-ops-team'
      continue: true

    - match:
        severity: medium
      receiver: 'wallix-ops-email'

receivers:
  - name: 'wallix-pagerduty'
    pagerduty_configs:
      - service_key: 'YOUR_PAGERDUTY_KEY'
        description: '{{ .GroupLabels.alertname }}: {{ .Annotations.summary }}'

  - name: 'wallix-ops-team'
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/YOUR/WEBHOOK/URL'
        channel: '#wallix-alerts'
        title: '{{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'
    email_configs:
      - to: 'ops@example.com'
        from: 'alerts@example.com'
        smarthost: 'smtp.example.com:587'

  - name: 'wallix-ops-email'
    email_configs:
      - to: 'ops@example.com'
        from: 'alerts@example.com'
        smarthost: 'smtp.example.com:587'

inhibit_rules:
  # Don't alert on replication lag if node is offline
  - source_match:
      severity: 'critical'
      alertname: 'WallixNodeOffline'
    target_match:
      severity: 'high'
      alertname: 'WallixReplicationLagHigh'
    equal: ['node']

  # Don't alert on resource failures if quorum is lost
  - source_match:
      severity: 'critical'
      alertname: 'WallixClusterQuorumLost'
    target_match:
      severity: 'critical'
      alertname: 'WallixPacemakerResourceFailed'
    equal: ['cluster']
```

### Monitoring Dashboard Example

**Key Metrics to Display:**

1. **Cluster Health Overview:**
   - Cluster status (online/degraded/offline)
   - Quorum status
   - Number of healthy nodes
   - Master node identification

2. **Replication Status:**
   - Replication lag (graph over time)
   - Replication IO/SQL thread status
   - Last replication error (if any)

3. **Pacemaker Resources:**
   - Resource status table
   - Resource migration history
   - Failover count per day

4. **VIP Status:**
   - Current VIP location
   - Failover history
   - Failover duration trend

5. **Performance Metrics:**
   - Active sessions per node
   - CPU/Memory usage
   - Disk space utilization
   - Network latency between nodes

### Best Practices Summary

```
+===============================================================================+
|                    HA MONITORING BEST PRACTICES SUMMARY                       |
+===============================================================================+

  DO:
  ===

  [x] Monitor ALL critical HA metrics continuously
  [x] Set up automated alerting with appropriate thresholds
  [x] Use multi-channel alerting (email, Slack, PagerDuty)
  [x] Implement alert inhibition rules to prevent alert storms
  [x] Run monitoring checks every 30-60 seconds for critical metrics
  [x] Log all health check results for historical analysis
  [x] Test alerting paths regularly (at least monthly)
  [x] Document runbooks for each alert type
  [x] Monitor inter-node network latency
  [x] Set up dashboard for real-time visibility
  [x] Include split-brain detection mechanisms
  [x] Monitor database connection pool usage
  [x] Track VIP failover times and trends
  [x] Alert on certificate expiration (30 days warning)
  [x] Monitor backup job completion status

  DON'T:
  ======

  [ ] Rely on manual health checks only
  [ ] Set alert thresholds too aggressively (alert fatigue)
  [ ] Ignore medium/low severity alerts completely
  [ ] Run health checks too frequently (< 30s for most metrics)
  [ ] Alert to a single channel only
  [ ] Skip testing failover scenarios
  [ ] Monitor only master node (monitor all nodes)
  [ ] Forget to monitor monitoring (meta-monitoring)
  [ ] Use default thresholds without tuning for your environment
  [ ] Skip documentation of alert response procedures

+===============================================================================+
```

---

## See Also

**Related Sections:**
- [11 - High Availability](../11-high-availability/README.md) - HA architecture and clustering
- [12 - Monitoring & Observability](../12-monitoring-observability/README.md) - Prometheus and Grafana setup
- [13 - Troubleshooting](../13-troubleshooting/README.md) - Diagnostics and log analysis
- [19 - System Requirements](../19-system-requirements/README.md) - Hardware and sizing guidance
- [21 - Operational Runbooks](../21-operational-runbooks/README.md) - Daily operations procedures
- [28 - Certificate Management](../28-certificate-management/README.md) - TLS/SSL best practices
- [29 - Disaster Recovery](../29-disaster-recovery/README.md) - DR runbooks and procedures
- [30 - Backup & Restore](../30-backup-restore/README.md) - Backup strategies

**Related Documentation:**
- [Install Guide: HA Active-Active Setup](/install/02-site-a-primary.md) - HA cluster deployment
- [Install Guide: Multi-Site Sync](/install/05-multi-site-sync.md) - Cross-site replication
- [Install Guide: MariaDB Replication](/install/10-mariadb-replication.md) - Database HA
- [Install Guide: Security Hardening](/install/07-security-hardening.md) - Security configuration
- [Pre-Production: HA Testing](/pre/08-ha-active-active.md) - HA cluster validation
- [Pre-Production: Battery Tests](/pre/14-battery-tests.md) - Comprehensive testing

**Official Resources:**
- [WALLIX Documentation](https://pam.wallix.one/documentation)
- [WALLIX Admin Guide](https://pam.wallix.one/documentation/admin-doc/bastion_en_administration_guide.pdf)

---

## Next Steps

Continue to [14 - Appendix](../15-appendix/README.md) for quick reference and cheat sheets.
