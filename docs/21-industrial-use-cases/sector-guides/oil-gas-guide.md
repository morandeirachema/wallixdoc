# Oil & Gas Sector Deployment Guide

## WALLIX PAM4OT for Upstream, Midstream, and Downstream Operations

---

## Executive Overview

```
+===============================================================================+
|                   OIL & GAS PAM DEPLOYMENT                                   |
+===============================================================================+

  INDUSTRY CHALLENGES
  ===================

  - Remote/offshore facilities with limited connectivity
  - Mix of modern and legacy control systems (20+ year old RTUs)
  - Third-party vendor access for maintenance
  - Regulatory requirements (API 1164, TSA Pipeline Security)
  - High-consequence environments (safety-critical systems)
  - 24/7 operations with shift-based access

  WALLIX VALUE PROPOSITION
  ========================

  [✓] Centralized access control across all facilities
  [✓] Session recording for compliance and incident investigation
  [✓] Secure vendor remote access without VPN complexity
  [✓] Credential management for thousands of devices
  [✓] Offline operation capability for air-gapped sites
  [✓] IEC 62443 compliance support

+===============================================================================+
```

---

## Reference Architecture

### Typical Oil & Gas Network

```
+===============================================================================+
|                   OIL & GAS NETWORK ARCHITECTURE                             |
+===============================================================================+

                         CORPORATE NETWORK
                    +----------------------+
                    |   Business Systems   |
                    |   Email, ERP, HR     |
                    +----------+-----------+
                               |
                    +----------v-----------+
                    |     CORPORATE DMZ    |
                    |  +----------------+  |
                    |  | WALLIX Primary |  |
                    |  | (HQ Cluster)   |  |
                    |  +----------------+  |
                    +----------+-----------+
                               |
            +------------------+------------------+
            |                  |                  |
    +-------v-------+  +-------v-------+  +-------v-------+
    |  UPSTREAM     |  |  MIDSTREAM    |  |  DOWNSTREAM   |
    |  (Production) |  |  (Pipeline)   |  |  (Refinery)   |
    +---------------+  +---------------+  +---------------+
            |                  |                  |
    +-------v-------+  +-------v-------+  +-------v-------+
    | Field Site    |  | Compressor   |  | Process       |
    | WALLIX Edge   |  | Station      |  | Control       |
    +---------------+  | WALLIX Node  |  | WALLIX Node   |
            |          +---------------+  +---------------+
    +-------v-------+          |                  |
    | Wellhead RTUs |  +-------v-------+  +-------v-------+
    | Flow Computers|  | SCADA RTUs   |  | DCS           |
    | Safety PLCs   |  | Metering     |  | SIS           |
    +---------------+  +---------------+  +---------------+

+===============================================================================+
```

### WALLIX Deployment Architecture

```
+===============================================================================+
|                   WALLIX DEPLOYMENT FOR OIL & GAS                            |
+===============================================================================+

  TIER 1: CORPORATE (HQ)
  ======================

  +------------------------------------------------------------------------+
  | WALLIX Primary Cluster (Active-Active)                                 |
  | - 2 nodes, high availability                                           |
  | - PostgreSQL streaming replication                                     |
  | - Shared VIP for load balancing                                        |
  | - Central policy management                                            |
  | - Integration with corporate LDAP/AD                                   |
  | - SIEM integration                                                     |
  +------------------------------------------------------------------------+

  TIER 2: REGIONAL OPERATIONS CENTERS
  ====================================

  +------------------------------------------------------------------------+
  | WALLIX Secondary Nodes (per region)                                    |
  | - 1-2 nodes per operations center                                      |
  | - Replicated from HQ                                                   |
  | - Local session termination                                            |
  | - Fail-safe if HQ connectivity lost                                    |
  +------------------------------------------------------------------------+

  TIER 3: FIELD SITES
  ===================

  +------------------------------------------------------------------------+
  | WALLIX Edge Nodes (per major site)                                     |
  | - Standalone or minimal HA                                             |
  | - Offline credential cache                                             |
  | - Local recording storage                                              |
  | - Sync when connectivity available                                     |
  | - Can operate fully disconnected                                       |
  +------------------------------------------------------------------------+

+===============================================================================+
```

---

## Device Categories

### Upstream (Production)

| Device Type | Protocol | Access Pattern | Recording |
|-------------|----------|----------------|-----------|
| Wellhead RTU | Modbus TCP, DNP3 | Maintenance only | Required |
| Flow Computer | Serial/Modbus | Calibration, config | Required |
| Safety PLC | Proprietary | Vendor maintenance | Required + 4-eyes |
| SCADA HMI | RDP | 24/7 operations | Required |
| Historian | SSH, HTTPS | Data retrieval | Optional |

### Midstream (Pipeline)

| Device Type | Protocol | Access Pattern | Recording |
|-------------|----------|----------------|-----------|
| Pipeline RTU | DNP3, Modbus | Remote monitoring | Required |
| Compressor PLC | EtherNet/IP | Maintenance | Required |
| Metering Skid | Modbus, OPC | Calibration | Required |
| Leak Detection | Proprietary | Vendor access | Required |
| SCADA Master | RDP, SSH | Operations | Required |

### Downstream (Refinery)

| Device Type | Protocol | Access Pattern | Recording |
|-------------|----------|----------------|-----------|
| DCS Controller | Proprietary | Process changes | Required + approval |
| SIS (Safety) | Proprietary | Safety modifications | Required + 4-eyes |
| Analyzer | Modbus, HART | Calibration | Required |
| Tank Gauging | Modbus | Inventory | Optional |
| Blending System | OPC UA | Recipe changes | Required |

---

## Implementation Roadmap

### Phase 1: Foundation (Months 1-2)

```
+===============================================================================+
|                   PHASE 1: FOUNDATION                                        |
+===============================================================================+

  WEEK 1-2: PLANNING
  ==================
  [ ] Inventory all control system assets
  [ ] Map network architecture (Purdue Model zones)
  [ ] Identify regulatory requirements (API 1164, TSA)
  [ ] Define user roles and access patterns
  [ ] Select pilot site(s)

  WEEK 3-4: HQ DEPLOYMENT
  =======================
  [ ] Deploy WALLIX primary cluster at HQ
  [ ] Configure HA and database replication
  [ ] Integrate with corporate AD/LDAP
  [ ] Configure MFA (TOTP or hardware token)
  [ ] Set up SIEM integration
  [ ] Define base policies and password rules

  WEEK 5-6: PILOT SITE
  ====================
  [ ] Deploy WALLIX node at pilot site
  [ ] Onboard 20-50 critical devices
  [ ] Configure vendor access for pilot
  [ ] Train pilot site operators
  [ ] Validate recording and audit

  WEEK 7-8: PILOT VALIDATION
  ==========================
  [ ] Monitor pilot for 2 weeks
  [ ] Gather user feedback
  [ ] Tune performance and policies
  [ ] Document lessons learned
  [ ] Prepare for broader rollout

+===============================================================================+
```

### Phase 2: Expansion (Months 3-6)

```
+===============================================================================+
|                   PHASE 2: EXPANSION                                         |
+===============================================================================+

  REGIONAL OPERATIONS CENTERS
  ===========================
  [ ] Deploy WALLIX at each regional ops center
  [ ] Configure multi-site replication
  [ ] Onboard regional devices
  [ ] Establish regional admin teams

  FIELD SITE ROLLOUT
  ==================
  [ ] Prioritize sites by risk/criticality
  [ ] Deploy edge nodes to major sites
  [ ] Configure offline credential cache
  [ ] Test disconnected operation
  [ ] Train field personnel

  VENDOR ACCESS PROGRAM
  =====================
  [ ] Define vendor access policies
  [ ] Create vendor user groups
  [ ] Configure time-limited authorizations
  [ ] Set up approval workflows
  [ ] Test vendor access procedures

+===============================================================================+
```

### Phase 3: Optimization (Months 7-12)

```
+===============================================================================+
|                   PHASE 3: OPTIMIZATION                                      |
+===============================================================================+

  AUTOMATION
  ==========
  [ ] API integration with asset management
  [ ] Automated device onboarding
  [ ] CMDB synchronization
  [ ] Automated compliance reporting

  ADVANCED FEATURES
  =================
  [ ] Session analytics and anomaly detection
  [ ] Command filtering for critical systems
  [ ] Just-in-time access for maintenance
  [ ] Emergency access procedures

  CONTINUOUS IMPROVEMENT
  ======================
  [ ] Quarterly access reviews
  [ ] Annual penetration testing
  [ ] DR testing (twice yearly)
  [ ] Policy optimization based on usage

+===============================================================================+
```

---

## Configuration Examples

### Domain Structure

```
Domains/
├── Corporate/
│   ├── CORP-IT-Servers
│   └── CORP-Network
│
├── Upstream/
│   ├── UP-Field-Site-Alpha
│   ├── UP-Field-Site-Bravo
│   └── UP-Offshore-Platform
│
├── Midstream/
│   ├── MID-Pipeline-Segment-1
│   ├── MID-Compressor-Stations
│   └── MID-Metering
│
└── Downstream/
    ├── DOWN-Refinery-ProcessControl
    ├── DOWN-Refinery-Safety
    └── DOWN-Blending
```

### User Groups

| Group | Description | MFA | Approval Required |
|-------|-------------|-----|-------------------|
| OT-Operators | 24/7 control room operators | Yes | No |
| OT-Engineers | Process/control engineers | Yes | For safety systems |
| OT-Maintenance | Field maintenance techs | Yes | No |
| IT-Admins | IT infrastructure support | Yes | For OT systems |
| Vendors-DCS | DCS vendor technicians | Yes | Always |
| Vendors-Safety | SIS vendor technicians | Yes | Always + 4-eyes |
| Emergency | Break-glass access | Yes | Post-incident review |

### Authorization Examples

**Operators - 24/7 HMI Access:**
```
Authorization: operators-hmi-access
- User Group: OT-Operators
- Target Group: All-HMI-Stations
- Protocols: RDP
- Recording: Required
- Approval: Not required
- Time Restriction: None (24/7)
```

**Engineers - Process Control:**
```
Authorization: engineers-dcs-access
- User Group: OT-Engineers
- Target Group: DCS-Engineering-Stations
- Protocols: RDP, SSH
- Recording: Required
- Approval: Not required for viewing, required for changes
- Time Restriction: Business hours preferred
```

**Vendors - Safety System:**
```
Authorization: vendor-sis-maintenance
- User Group: Vendors-Safety
- Target Group: SIS-Controllers
- Protocols: Proprietary tunnel
- Recording: Required
- Approval: Always required
- 4-Eyes: Required (OT engineer must observe)
- Time Restriction: Scheduled maintenance windows only
- Max Duration: 4 hours
```

---

## Compliance Mapping

### API 1164 (Pipeline SCADA Security)

| API 1164 Requirement | WALLIX Capability |
|---------------------|-------------------|
| 4.1 Access Control | User authentication, RBAC authorizations |
| 4.2 Authentication | MFA, LDAP/AD integration |
| 4.3 Accountability | Session recording, audit logs |
| 4.4 Configuration Management | Change tracking, approval workflows |
| 4.5 Intrusion Detection | Session monitoring, command filtering |
| 4.6 Security Assessment | Access reviews, compliance reports |

### TSA Pipeline Security Directive

| TSA Requirement | WALLIX Implementation |
|-----------------|----------------------|
| Credential management | Password Manager, rotation |
| MFA for remote access | TOTP, FIDO2, RADIUS |
| Network segmentation | Zone-based access control |
| Access logging | Comprehensive audit trail |
| Incident response | Session termination, forensics |

---

## Vendor Access Procedures

### Standard Vendor Maintenance

```
+===============================================================================+
|                   VENDOR ACCESS WORKFLOW                                     |
+===============================================================================+

  1. SCHEDULING (1 week before)
     +------------------------------------------------------------------+
     | Vendor submits: Work order, scope, required systems, duration    |
     | Internal review: OT manager approves scope                       |
     | WALLIX: Create time-limited authorization                        |
     +------------------------------------------------------------------+

  2. PRE-MAINTENANCE (1 day before)
     +------------------------------------------------------------------+
     | WALLIX: Enable vendor authorization                              |
     | Notify: Operations center aware of maintenance                   |
     | Prepare: Backup critical configurations                          |
     +------------------------------------------------------------------+

  3. DURING MAINTENANCE
     +------------------------------------------------------------------+
     | Vendor logs into WALLIX portal                                   |
     | Vendor selects authorized target                                 |
     | Session automatically recorded                                   |
     | Internal engineer can observe in real-time                       |
     +------------------------------------------------------------------+

  4. POST-MAINTENANCE
     +------------------------------------------------------------------+
     | Vendor session ends (logout or timeout)                          |
     | WALLIX: Disable vendor authorization                             |
     | WALLIX: Rotate accessed credentials                              |
     | Review: Session recording archived                               |
     | Report: Generate maintenance activity report                     |
     +------------------------------------------------------------------+

+===============================================================================+
```

### Emergency Vendor Access

```
+===============================================================================+
|                   EMERGENCY VENDOR ACCESS                                    |
+===============================================================================+

  WHEN TO USE
  ===========
  - Production down, vendor expertise required
  - Safety system fault, vendor support needed
  - No time for standard approval process

  PROCEDURE
  =========

  1. AUTHORIZATION
     - Call OT Manager or designated backup
     - Document: Ticket#, Approver, Time, Reason
     - If unreachable, Security Manager can authorize

  2. ENABLE ACCESS
     - OT Admin creates temporary authorization
     - Duration: Maximum 4 hours
     - Approval: Marked as "Emergency"

  3. DURING ACCESS
     - Session recorded
     - Internal observer if possible
     - Frequent check-ins with vendor

  4. POST-INCIDENT
     - Review session recording
     - Rotate all accessed credentials
     - Complete incident report
     - Review emergency access policy

+===============================================================================+
```

---

## Offline Operation (Field Sites)

### Credential Caching

```
+===============================================================================+
|                   OFFLINE CREDENTIAL CACHE                                   |
+===============================================================================+

  CONFIGURATION
  =============

  # On edge WALLIX node
  wabadmin cache configure \
    --cache-size 500 \
    --cache-duration 7d \
    --priority-accounts "safety-*,emergency-*"

  HOW IT WORKS
  ============

  1. Normal operation: Credentials retrieved from central vault
  2. Connection lost: Edge node uses cached credentials
  3. Reconnection: Cache refreshed, sessions synced

  CACHED ITEMS
  ============

  [✓] Account credentials (encrypted)
  [✓] User authentication tokens
  [✓] Authorization policies
  [✓] Session recordings (queued for sync)

  NOT CACHED
  ==========

  [X] MFA secrets (users must have offline MFA)
  [X] Real-time approval workflows
  [X] Live session monitoring from HQ

  SECURITY CONSIDERATIONS
  =======================

  - Cache is encrypted with local key
  - Key protected by HSM or TPM
  - Cache auto-expires if not refreshed
  - Cached passwords rotate on reconnection

+===============================================================================+
```

---

## Monitoring and Alerting

### Critical Alerts

| Alert | Threshold | Response |
|-------|-----------|----------|
| Failed vendor login | 3 attempts | Block, notify security |
| Safety system access | Any | Notify OT manager |
| After-hours access | Outside window | Verify authorization |
| Session > 8 hours | Duration exceeded | Check on user |
| Credential checkout | Any | Log for review |
| Rotation failure | 3 attempts | Investigate immediately |

### Dashboard Metrics

```
OIL & GAS WALLIX DASHBOARD
==========================

Active Sessions:
  Operators: 12
  Engineers: 5
  Vendors: 2
  Total: 19

Sessions by Site:
  HQ: 8
  Platform Alpha: 4
  Refinery: 7

Today's Activity:
  Logins: 45
  Sessions: 89
  Recordings: 89 (100%)

Compliance:
  Rotation Success: 98.5%
  MFA Enabled: 100%
  Recording Coverage: 100%
```

---

## Incident Response

### Unauthorized Access Detected

```bash
# 1. Terminate suspicious session
wabadmin session kill <session-id> --reason "Security incident"

# 2. Disable account
wabadmin user disable <username>

# 3. Export evidence
wabadmin recordings --session <session-id> --export /forensics/
wabadmin audit --session <session-id> --export /forensics/

# 4. Rotate affected credentials
wabadmin rotation --target-group affected-systems --execute

# 5. Notify
# - OT Manager
# - Security Team
# - If safety-related: Plant Manager
```

### Credential Compromise

```bash
# 1. Identify affected accounts
wabadmin accounts --last-accessed-by <compromised-user>

# 2. Rotate ALL potentially affected
wabadmin rotation --domain affected-domain --force --execute

# 3. Review session recordings
wabadmin recordings --user <compromised-user> --since "7 days ago"

# 4. Check for policy changes
wabadmin audit --type config --since "7 days ago"
```

---

## Best Practices Summary

```
+===============================================================================+
|                   OIL & GAS BEST PRACTICES                                   |
+===============================================================================+

  DO:
  ===
  [✓] Deploy WALLIX in each network zone (defense in depth)
  [✓] Require recording for ALL access to process control
  [✓] Use 4-eyes for safety-critical system changes
  [✓] Rotate credentials after every vendor session
  [✓] Test offline operation quarterly
  [✓] Integrate with existing SIEM and historian
  [✓] Train operators on recognizing suspicious activity
  [✓] Maintain emergency access procedures
  [✓] Review access quarterly (regulatory requirement)

  DON'T:
  ======
  [X] Allow direct access to control systems (bypass WALLIX)
  [X] Share vendor accounts between companies
  [X] Disable recording for "trusted" users
  [X] Skip MFA for "convenience"
  [X] Allow indefinite vendor access
  [X] Ignore rotation failures
  [X] Store credentials outside WALLIX

+===============================================================================+
```

---

## Resources

| Resource | Description |
|----------|-------------|
| API 1164 | Pipeline SCADA Security Guidelines |
| TSA Directives | Pipeline Security Requirements |
| IEC 62443 | Industrial Automation Security |
| NIST 800-82 | Guide to ICS Security |
| ISA/IEC 62443 | Industrial Cybersecurity Standard |

---

<p align="center">
  <a href="../README.md">Use Cases Overview</a> •
  <a href="../../16-ot-architecture/README.md">OT Architecture</a> •
  <a href="../../20-iec62443-compliance/README.md">IEC 62443</a>
</p>
