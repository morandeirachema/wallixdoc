# 23 - Industrial Security Best Practices

## Table of Contents

1. [Design Principles](#design-principles)
2. [Deployment Checklist](#deployment-checklist)
3. [Operational Security](#operational-security)
4. [Incident Response](#incident-response)
5. [Maintenance Procedures](#maintenance-procedures)
6. [Common Mistakes to Avoid](#common-mistakes-to-avoid)
7. [Quick Reference Guide](#quick-reference-guide)

---

## Design Principles

### OT-First Design Philosophy

```
+===============================================================================+
|                   OT SECURITY DESIGN PRINCIPLES                              |
+===============================================================================+

  PRINCIPLE 1: AVAILABILITY OVER CONFIDENTIALITY
  ===============================================

  In OT environments, the CIA triad priority is reversed:

  +------------------------------------------------------------------------+
  |                                                                        |
  |   IT Priority:              OT Priority:                               |
  |   ============              ============                               |
  |                                                                        |
  |   1. Confidentiality        1. Availability (Safety)                   |
  |   2. Integrity              2. Integrity                               |
  |   3. Availability           3. Confidentiality                         |
  |                                                                        |
  |   WALLIX IMPLICATION:                                                  |
  |   - PAM must NEVER prevent emergency access                            |
  |   - Bypass procedures must be documented and tested                    |
  |   - HA/failover is critical, not optional                              |
  |   - Session recording can be disabled in emergencies                   |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  PRINCIPLE 2: DEFENSE IN DEPTH
  =============================

  PAM is ONE layer of defense, not the only one:

  +------------------------------------------------------------------------+
  |                                                                        |
  |   +---------------------------------------------------------------+   |
  |   |  Layer 1: Physical Security (fences, locks, badges)           |   |
  |   |  +--------------------------------------------------------+   |   |
  |   |  |  Layer 2: Network Segmentation (firewalls, VLANs)      |   |   |
  |   |  |  +--------------------------------------------------+  |   |   |
  |   |  |  |  Layer 3: PAM (WALLIX - access control, audit)   |  |   |   |
  |   |  |  |  +--------------------------------------------+  |  |   |   |
  |   |  |  |  |  Layer 4: Endpoint Protection (AV, EDR)    |  |  |   |   |
  |   |  |  |  |  +--------------------------------------+  |  |  |   |   |
  |   |  |  |  |  |  Layer 5: Application Whitelisting   |  |  |  |   |   |
  |   |  |  |  |  |  +--------------------------------+  |  |  |  |   |   |
  |   |  |  |  |  |  |       OT ASSETS                |  |  |  |  |   |   |
  |   |  |  |  |  |  +--------------------------------+  |  |  |  |   |   |
  |   |  |  |  |  +--------------------------------------+  |  |  |   |   |
  |   |  |  |  +--------------------------------------------+  |  |   |   |
  |   |  |  +--------------------------------------------------+  |   |   |
  |   |  +--------------------------------------------------------+   |   |
  |   +---------------------------------------------------------------+   |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  PRINCIPLE 3: LEAST PRIVILEGE
  ============================

  +------------------------------------------------------------------------+
  |                                                                        |
  | MINIMUM NECESSARY ACCESS                                               |
  |                                                                        |
  | User                What they need              What to grant          |
  | ----                --------------              -------------          |
  | Operator            Monitor process             View-only to HMI       |
  | Technician          Adjust setpoints            Limited write access   |
  | Engineer            Programming, config         Full access, approval  |
  | Vendor              Their equipment only        Specific targets only  |
  |                                                                        |
  | ANTI-PATTERNS TO AVOID:                                                |
  | X "Everyone gets admin access - it's easier"                           |
  | X "Vendors can access everything - they might need it"                 |
  | X "We'll figure out permissions later"                                 |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  PRINCIPLE 4: ASSUME BREACH
  ==========================

  +------------------------------------------------------------------------+
  |                                                                        |
  | Design with the assumption that attackers WILL get in:                 |
  |                                                                        |
  | 1. LIMIT BLAST RADIUS                                                  |
  |    - Each authorization grants minimum access                          |
  |    - Segment OT assets into zones                                      |
  |    - No single account accesses everything                             |
  |                                                                        |
  | 2. DETECT QUICKLY                                                      |
  |    - Real-time session monitoring                                      |
  |    - SIEM integration with alerting                                    |
  |    - Anomaly detection (unusual hours, targets)                        |
  |                                                                        |
  | 3. RESPOND RAPIDLY                                                     |
  |    - Instant session termination capability                            |
  |    - Credential rotation on demand                                     |
  |    - Documented incident response procedures                           |
  |                                                                        |
  | 4. RECOVER SECURELY                                                    |
  |    - Session recordings for forensics                                  |
  |    - Audit trail for investigation                                     |
  |    - Credential rotation after incident                                |
  |                                                                        |
  +------------------------------------------------------------------------+

+===============================================================================+
```

---

## Deployment Checklist

### Pre-Deployment Planning

```
+===============================================================================+
|                   PRE-DEPLOYMENT CHECKLIST                                   |
+===============================================================================+

  PHASE 1: REQUIREMENTS GATHERING
  ===============================

  [ ] 1. ASSET INVENTORY
      - List all OT assets to be managed
      - Document IP addresses, protocols, ports
      - Identify asset criticality (SIL level if applicable)
      - Map existing access methods

  [ ] 2. USER IDENTIFICATION
      - Identify all user groups requiring OT access
      - Document current authentication methods
      - List vendor/contractor access requirements
      - Define role-based access needs

  [ ] 3. NETWORK ARCHITECTURE REVIEW
      - Document current network segmentation
      - Identify WALLIX placement options (DMZ)
      - Plan firewall rule changes
      - Assess bandwidth requirements

  [ ] 4. COMPLIANCE REQUIREMENTS
      - Identify applicable regulations (IEC 62443, NERC CIP, etc.)
      - Document required security controls
      - Plan for audit evidence generation
      - Define retention requirements

  --------------------------------------------------------------------------

  PHASE 2: ARCHITECTURE DESIGN
  ============================

  [ ] 5. HIGH AVAILABILITY DESIGN
      - Determine HA requirements (active/standby, active/active)
      - Plan shared storage for recordings
      - Design failover procedures
      - Document emergency bypass procedures

  [ ] 6. INTEGRATION PLANNING
      - Plan directory service integration (LDAP/AD)
      - Design SIEM integration
      - Plan ITSM workflow integration
      - Document API automation needs

  [ ] 7. ZONE MAPPING
      - Map WALLIX authorizations to IEC 62443 zones
      - Define conduit policies
      - Document cross-zone access requirements
      - Plan for security level enforcement

  --------------------------------------------------------------------------

  PHASE 3: DEPLOYMENT PREPARATION
  ===============================

  [ ] 8. INFRASTRUCTURE PREPARATION
      - Provision WALLIX servers/VMs
      - Configure networking (IPs, DNS, NTP)
      - Install SSL certificates
      - Configure backup storage

  [ ] 9. SECURITY BASELINE
      - Harden WALLIX appliance (disable unused services)
      - Configure logging and audit settings
      - Set password policies
      - Enable MFA

  [ ] 10. DOCUMENTATION
      - Create operational procedures
      - Document bypass/break-glass procedures
      - Prepare user training materials
      - Create troubleshooting guides

+===============================================================================+
```

### Deployment Steps

```
+===============================================================================+
|                   DEPLOYMENT CHECKLIST                                       |
+===============================================================================+

  PHASE 4: INITIAL DEPLOYMENT
  ===========================

  [ ] 11. BASE INSTALLATION
      - Install WALLIX Bastion
      - Configure basic settings (hostname, network)
      - Verify system health
      - Apply latest patches

  [ ] 12. AUTHENTICATION SETUP
      - Configure local admin accounts
      - Integrate with directory services
      - Configure MFA
      - Test authentication flow

  [ ] 13. DEVICE ONBOARDING (PILOT)
      - Start with non-critical devices
      - Create device definitions
      - Configure service accounts
      - Test connectivity

  [ ] 14. AUTHORIZATION POLICIES (PILOT)
      - Create initial user groups
      - Define pilot authorizations
      - Configure approval workflows
      - Test access flows

  --------------------------------------------------------------------------

  PHASE 5: PILOT TESTING
  ======================

  [ ] 15. FUNCTIONAL TESTING
      - Test session establishment (all protocols)
      - Verify session recording
      - Test credential injection
      - Verify approval workflows

  [ ] 16. INTEGRATION TESTING
      - Test SIEM log forwarding
      - Verify MFA flow
      - Test ITSM ticket creation
      - Verify API functionality

  [ ] 17. FAILOVER TESTING
      - Test HA failover
      - Verify session persistence
      - Test backup/restore
      - Validate bypass procedures

  [ ] 18. USER ACCEPTANCE
      - Conduct pilot with real users
      - Gather feedback
      - Address usability issues
      - Refine procedures

  --------------------------------------------------------------------------

  PHASE 6: PRODUCTION ROLLOUT
  ===========================

  [ ] 19. FULL DEVICE ONBOARDING
      - Onboard all OT assets systematically
      - Verify each device connectivity
      - Configure all service accounts
      - Update vault credentials

  [ ] 20. FULL AUTHORIZATION DEPLOYMENT
      - Deploy all authorization policies
      - Enable approval workflows
      - Configure time restrictions
      - Activate alerting rules

  [ ] 21. USER MIGRATION
      - Train all user groups
      - Migrate users in phases
      - Monitor for issues
      - Support transition period

  [ ] 22. LEGACY ACCESS RETIREMENT
      - Disable direct access paths
      - Update firewall rules
      - Remove legacy credentials
      - Document exceptions

+===============================================================================+
```

---

## Operational Security

### Daily Operations

```
+===============================================================================+
|                   OPERATIONAL SECURITY PRACTICES                             |
+===============================================================================+

  DAILY TASKS
  ===========

  +------------------------------------------------------------------------+
  |                                                                        |
  | MORNING CHECKLIST                                                      |
  |                                                                        |
  | [ ] Review overnight alerts from SIEM                                  |
  | [ ] Check WALLIX system health (dashboard)                             |
  | [ ] Review active sessions (any unexpected?)                           |
  | [ ] Check pending approval requests                                    |
  | [ ] Verify backup completion                                           |
  |                                                                        |
  | TIME: 15-30 minutes                                                    |
  |                                                                        |
  +------------------------------------------------------------------------+

  +------------------------------------------------------------------------+
  |                                                                        |
  | SHIFT HANDOVER                                                         |
  |                                                                        |
  | [ ] Report any security incidents                                      |
  | [ ] Note any unusual access patterns                                   |
  | [ ] Document pending vendor access requests                            |
  | [ ] Update shared incident log                                         |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  WEEKLY TASKS
  ============

  +------------------------------------------------------------------------+
  |                                                                        |
  | WEEKLY REVIEW                                                          |
  |                                                                        |
  | [ ] Review all vendor access sessions                                  |
  | [ ] Check for unused accounts (disable after 30 days)                  |
  | [ ] Review failed authentication trends                                |
  | [ ] Verify password rotations completed                                |
  | [ ] Check storage utilization (recordings)                             |
  | [ ] Review and clear expired access requests                           |
  |                                                                        |
  | TIME: 1-2 hours                                                        |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  MONTHLY TASKS
  =============

  +------------------------------------------------------------------------+
  |                                                                        |
  | MONTHLY AUDIT                                                          |
  |                                                                        |
  | [ ] User access review (verify all access is still needed)             |
  | [ ] Authorization policy review (any changes needed?)                  |
  | [ ] Review high-privilege account usage                                |
  | [ ] Test emergency bypass procedures                                   |
  | [ ] Review and archive old recordings                                  |
  | [ ] Generate compliance reports                                        |
  | [ ] Update asset inventory if needed                                   |
  |                                                                        |
  | TIME: 4-8 hours                                                        |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  QUARTERLY TASKS
  ===============

  +------------------------------------------------------------------------+
  |                                                                        |
  | QUARTERLY SECURITY REVIEW                                              |
  |                                                                        |
  | [ ] Full user access certification                                     |
  | [ ] Penetration test / vulnerability assessment                        |
  | [ ] Disaster recovery test                                             |
  | [ ] Review and update security policies                                |
  | [ ] Vendor access audit                                                |
  | [ ] Training refresh for operators                                     |
  | [ ] Review WALLIX patches and updates                                  |
  |                                                                        |
  | TIME: 1-2 days                                                         |
  |                                                                        |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### Monitoring & Alerting

```
+===============================================================================+
|                   MONITORING & ALERTING CONFIGURATION                        |
+===============================================================================+

  CRITICAL ALERTS (IMMEDIATE RESPONSE)
  ====================================

  +------------------------------------------------------------------------+
  | Alert                              | Threshold         | Response      |
  +------------------------------------+-------------------+---------------+
  | Failed logins (same user)          | > 5 in 5 min      | Investigate   |
  | Failed logins (same source IP)     | > 10 in 5 min     | Block IP      |
  | Access to SIS/Safety systems       | Any access        | Verify auth   |
  | After-hours critical system access | Any outside hours | Verify auth   |
  | Session terminated by admin        | Any               | Document      |
  | WALLIX service failure             | Any               | Restore ASAP  |
  | Break-glass account usage          | Any               | Full review   |
  +------------------------------------+-------------------+---------------+

  --------------------------------------------------------------------------

  HIGH PRIORITY ALERTS (RESPONSE < 1 HOUR)
  ========================================

  +------------------------------------------------------------------------+
  | Alert                              | Threshold         | Response      |
  +------------------------------------+-------------------+---------------+
  | Vendor access to critical system   | Any               | Monitor live  |
  | Password checkout (sensitive acct) | Any               | Log & track   |
  | Approval request timeout           | > 30 min pending  | Escalate      |
  | Session duration exceeded          | > 8 hours         | Review need   |
  | Multiple concurrent sessions       | > 3 per user      | Investigate   |
  | Configuration change               | Any admin change  | Verify auth   |
  +------------------------------------+-------------------+---------------+

  --------------------------------------------------------------------------

  MEDIUM PRIORITY (REVIEW WITHIN 24 HOURS)
  ========================================

  +------------------------------------------------------------------------+
  | Alert                              | Threshold         | Response      |
  +------------------------------------+-------------------+---------------+
  | New user account created           | Any               | Verify auth   |
  | New device added                   | Any               | Verify auth   |
  | Authorization modified             | Any               | Review change |
  | Password rotation failed           | Any               | Fix manually  |
  | Storage utilization                | > 80%             | Plan cleanup  |
  | Certificate expiration             | < 30 days         | Renew         |
  +------------------------------------+-------------------+---------------+

  --------------------------------------------------------------------------

  SIEM CORRELATION RULES
  ======================

  +------------------------------------------------------------------------+
  |                                                                        |
  | RULE 1: CREDENTIAL COMPROMISE DETECTION                                |
  | =======================================                                |
  |                                                                        |
  | Trigger: Same user authenticated from multiple locations               |
  |          within 15 minutes (impossible travel)                         |
  | Severity: Critical                                                     |
  | Response: Disable account, investigate                                 |
  |                                                                        |
  | RULE 2: LATERAL MOVEMENT DETECTION                                     |
  | ==================================                                     |
  |                                                                        |
  | Trigger: Single user accessing > 5 different OT systems                |
  |          within 1 hour (unusual pattern)                               |
  | Severity: High                                                         |
  | Response: Monitor session, investigate                                 |
  |                                                                        |
  | RULE 3: PRIVILEGE ESCALATION                                           |
  | ============================                                           |
  |                                                                        |
  | Trigger: User accesses system not in their normal pattern              |
  |          (baseline established over 30 days)                           |
  | Severity: Medium                                                       |
  | Response: Review authorization                                         |
  |                                                                        |
  +------------------------------------------------------------------------+

+===============================================================================+
```

---

## Incident Response

### PAM-Specific Incident Response

```
+===============================================================================+
|                   INCIDENT RESPONSE PROCEDURES                               |
+===============================================================================+

  INCIDENT TYPE 1: UNAUTHORIZED ACCESS DETECTED
  =============================================

  +------------------------------------------------------------------------+
  |                                                                        |
  | IMMEDIATE ACTIONS (0-15 minutes)                                       |
  |                                                                        |
  | 1. TERMINATE SESSION                                                   |
  |    - WALLIX Admin GUI > Sessions > Select > Kill Session               |
  |    - Or: wab-admin kill-session --id <session_id>                      |
  |                                                                        |
  | 2. DISABLE ACCOUNT                                                     |
  |    - WALLIX Admin GUI > Users > Select > Disable                       |
  |    - If LDAP: Disable in AD as well                                    |
  |                                                                        |
  | 3. PRESERVE EVIDENCE                                                   |
  |    - Do NOT delete or modify session recording                         |
  |    - Export audit logs immediately                                     |
  |    - Screenshot current state                                          |
  |                                                                        |
  | 4. NOTIFY                                                              |
  |    - Security team                                                     |
  |    - OT operations (for impact assessment)                             |
  |    - Management (if critical system)                                   |
  |                                                                        |
  +------------------------------------------------------------------------+

  +------------------------------------------------------------------------+
  |                                                                        |
  | INVESTIGATION (15 min - 2 hours)                                       |
  |                                                                        |
  | 1. REVIEW SESSION RECORDING                                            |
  |    - What actions were taken?                                          |
  |    - What data was accessed?                                           |
  |    - Was any configuration changed?                                    |
  |                                                                        |
  | 2. ANALYZE AUDIT LOGS                                                  |
  |    - How did user authenticate?                                        |
  |    - What was authorization path?                                      |
  |    - Any approval workflow bypassed?                                   |
  |                                                                        |
  | 3. CHECK RELATED SYSTEMS                                               |
  |    - OT monitoring alerts (Claroty, Nozomi)                            |
  |    - Firewall logs                                                     |
  |    - Target system logs                                                |
  |                                                                        |
  | 4. DETERMINE SCOPE                                                     |
  |    - Which systems were accessed?                                      |
  |    - What credentials were exposed?                                    |
  |    - Is attacker still active elsewhere?                               |
  |                                                                        |
  +------------------------------------------------------------------------+

  +------------------------------------------------------------------------+
  |                                                                        |
  | CONTAINMENT (2-24 hours)                                               |
  |                                                                        |
  | 1. ROTATE AFFECTED CREDENTIALS                                         |
  |    - All passwords accessed during incident                            |
  |    - Any shared credentials on accessed systems                        |
  |    - API tokens/keys if exposed                                        |
  |                                                                        |
  | 2. REVIEW ACCESS POLICIES                                              |
  |    - Tighten authorization if too permissive                           |
  |    - Add approval requirements if needed                               |
  |    - Implement additional MFA                                          |
  |                                                                        |
  | 3. SYSTEM VERIFICATION                                                 |
  |    - Verify OT system integrity                                        |
  |    - Check for unauthorized changes                                    |
  |    - Restore from backup if needed                                     |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  INCIDENT TYPE 2: WALLIX SYSTEM FAILURE
  ======================================

  +------------------------------------------------------------------------+
  |                                                                        |
  | AUTOMATIC FAILOVER (if HA configured)                                  |
  |                                                                        |
  | 1. HA cluster should automatically failover                            |
  | 2. Verify standby node is now active                                   |
  | 3. Active sessions should persist (session persistence enabled)        |
  | 4. Monitor for any dropped sessions                                    |
  |                                                                        |
  | NO FAILOVER ACTIONS:                                                   |
  | - Troubleshoot failed node                                             |
  | - Do NOT restore until root cause identified                           |
  | - Plan maintenance window for repair                                   |
  |                                                                        |
  +------------------------------------------------------------------------+

  +------------------------------------------------------------------------+
  |                                                                        |
  | MANUAL BYPASS (if total PAM failure)                                   |
  |                                                                        |
  | ONLY if PAM completely unavailable AND production requires access:     |
  |                                                                        |
  | 1. DOCUMENT INCIDENT START TIME                                        |
  |    - Log: Date, time, reason for bypass                                |
  |                                                                        |
  | 2. ACTIVATE EMERGENCY FIREWALL RULES                                   |
  |    - Pre-configured rules that allow direct access                     |
  |    - Should be disabled by default                                     |
  |                                                                        |
  | 3. USE BREAK-GLASS CREDENTIALS                                         |
  |    - Retrieve from secure storage (safe, HSM)                          |
  |    - Document all credential usage                                     |
  |                                                                        |
  | 4. MANUAL ACCESS LOGGING                                               |
  |    - Log all access: who, what, when, why                              |
  |    - Handwritten if necessary                                          |
  |                                                                        |
  | 5. RESTORE PAM ASAP                                                    |
  |    - Priority 1 incident                                               |
  |    - All hands on deck                                                 |
  |                                                                        |
  | 6. POST-BYPASS ACTIONS                                                 |
  |    - Rotate ALL credentials used during bypass                         |
  |    - Disable emergency firewall rules                                  |
  |    - Audit manual logs                                                 |
  |    - Full incident review                                              |
  |                                                                        |
  +------------------------------------------------------------------------+

+===============================================================================+
```

---

## Maintenance Procedures

### Scheduled Maintenance

```
+===============================================================================+
|                   MAINTENANCE PROCEDURES                                     |
+===============================================================================+

  WALLIX UPGRADE PROCEDURE
  ========================

  +------------------------------------------------------------------------+
  |                                                                        |
  | PRE-UPGRADE (1 week before)                                            |
  | ===========================                                            |
  |                                                                        |
  | [ ] Review release notes for breaking changes                          |
  | [ ] Verify current backup is valid (test restore)                      |
  | [ ] Check compatibility with current integrations                      |
  | [ ] Schedule maintenance window (low-activity period)                  |
  | [ ] Notify users of planned downtime                                   |
  | [ ] Prepare rollback procedure                                         |
  |                                                                        |
  | UPGRADE DAY                                                            |
  | ===========                                                            |
  |                                                                        |
  | [ ] Take full backup (configuration + database)                        |
  | [ ] Export current configuration                                       |
  | [ ] Notify users upgrade is starting                                   |
  | [ ] For HA: Upgrade standby first, failover, upgrade primary           |
  | [ ] Apply upgrade package                                              |
  | [ ] Verify service startup                                             |
  | [ ] Test critical functions:                                           |
  |     [ ] User authentication (local, LDAP, MFA)                         |
  |     [ ] Session establishment (SSH, RDP)                               |
  |     [ ] Session recording                                              |
  |     [ ] Approval workflow                                              |
  |     [ ] SIEM integration                                               |
  | [ ] Monitor for errors (1 hour)                                        |
  | [ ] Notify users upgrade complete                                      |
  |                                                                        |
  | POST-UPGRADE                                                           |
  | ============                                                           |
  |                                                                        |
  | [ ] Monitor system for 24-48 hours                                     |
  | [ ] Verify all scheduled tasks running                                 |
  | [ ] Check integration functionality                                    |
  | [ ] Update documentation                                               |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  CERTIFICATE RENEWAL
  ===================

  +------------------------------------------------------------------------+
  |                                                                        |
  | SSL certificates should be renewed BEFORE expiration (30+ days)        |
  |                                                                        |
  | PROCEDURE:                                                             |
  |                                                                        |
  | 1. Generate new CSR or certificate                                     |
  |    $ wab-admin generate-csr --common-name wallix.company.com           |
  |                                                                        |
  | 2. Submit to CA and obtain signed certificate                          |
  |                                                                        |
  | 3. Install new certificate                                             |
  |    $ wab-admin install-cert --cert /path/to/cert.pem                   |
  |                              --key /path/to/key.pem                    |
  |                              --chain /path/to/chain.pem                |
  |                                                                        |
  | 4. Restart services                                                    |
  |    $ wab-admin restart                                                 |
  |                                                                        |
  | 5. Verify certificate                                                  |
  |    $ openssl s_client -connect wallix.company.com:443                  |
  |                                                                        |
  | CERTIFICATES TO TRACK:                                                 |
  | - WALLIX web interface (HTTPS)                                         |
  | - Syslog TLS certificate                                               |
  | - LDAP client certificate (if used)                                    |
  | - API certificate                                                      |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  BACKUP & RESTORE
  ================

  +------------------------------------------------------------------------+
  |                                                                        |
  | BACKUP SCHEDULE                                                        |
  |                                                                        |
  | Daily:   Configuration backup (automated)                              |
  | Weekly:  Full system backup (config + database)                        |
  | Monthly: Offsite backup copy                                           |
  |                                                                        |
  | BACKUP COMMAND:                                                        |
  | $ wab-admin backup --full --output /backup/wallix-$(date +%F).tar.gz   |
  |                                                                        |
  | BACKUP CONTENTS:                                                       |
  | - MariaDB database dump                                                |
  | - Configuration files                                                  |
  | - SSL certificates                                                     |
  | - Custom scripts/plugins                                               |
  |                                                                        |
  | RESTORE PROCEDURE:                                                     |
  | $ wab-admin restore --file /backup/wallix-2024-01-15.tar.gz            |
  | $ wab-admin restart                                                    |
  |                                                                        |
  | QUARTERLY: Test restore to verify backups are valid                    |
  |                                                                        |
  +------------------------------------------------------------------------+

+===============================================================================+
```

---

## Common Mistakes to Avoid

### Implementation Anti-Patterns

```
+===============================================================================+
|                   COMMON MISTAKES & HOW TO AVOID THEM                        |
+===============================================================================+

  MISTAKE 1: OVERLY PERMISSIVE ACCESS
  ===================================

  +------------------------------------------------------------------------+
  |                                                                        |
  | WRONG:                                                                 |
  | "Everyone gets access to everything - we'll restrict later"            |
  |                                                                        |
  | IMPACT:                                                                |
  | - Security incidents affect entire OT environment                      |
  | - No audit trail of who accessed what                                  |
  | - Compliance failures                                                  |
  |                                                                        |
  | CORRECT:                                                               |
  | Start with minimal access, add permissions as needed                   |
  | Document business justification for each authorization                 |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  MISTAKE 2: SHARED ACCOUNTS
  ==========================

  +------------------------------------------------------------------------+
  |                                                                        |
  | WRONG:                                                                 |
  | "We use one 'operator' account for everyone - easier to manage"        |
  |                                                                        |
  | IMPACT:                                                                |
  | - No individual accountability                                         |
  | - Cannot determine who performed an action                             |
  | - Password exposed to many people                                      |
  | - Compliance violation                                                 |
  |                                                                        |
  | CORRECT:                                                               |
  | Individual accounts for every user                                     |
  | Shared service accounts only in WALLIX vault (never known to users)    |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  MISTAKE 3: SKIPPING MFA FOR "CONVENIENCE"
  =========================================

  +------------------------------------------------------------------------+
  |                                                                        |
  | WRONG:                                                                 |
  | "MFA is too slow for operators - we disabled it for OT users"          |
  |                                                                        |
  | IMPACT:                                                                |
  | - Credential theft leads directly to system access                     |
  | - Phishing attacks succeed                                             |
  | - Regulatory non-compliance                                            |
  |                                                                        |
  | CORRECT:                                                               |
  | Use efficient MFA (hardware tokens, push notifications)                |
  | Accept slight inconvenience for significant security improvement       |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  MISTAKE 4: NO BYPASS PROCEDURE
  ==============================

  +------------------------------------------------------------------------+
  |                                                                        |
  | WRONG:                                                                 |
  | "PAM is our only access path - if it fails, we'll figure it out"       |
  |                                                                        |
  | IMPACT:                                                                |
  | - Production down during PAM outage                                    |
  | - Panic decisions lead to permanent security holes                     |
  | - No documented recovery path                                          |
  |                                                                        |
  | CORRECT:                                                               |
  | Documented, tested emergency bypass procedure                          |
  | Break-glass credentials securely stored                                |
  | Regular bypass drills                                                  |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  MISTAKE 5: IGNORING RECORDINGS
  ==============================

  +------------------------------------------------------------------------+
  |                                                                        |
  | WRONG:                                                                 |
  | "We record sessions but never review them"                             |
  |                                                                        |
  | IMPACT:                                                                |
  | - Malicious actions undetected                                         |
  | - Storage fills up with unused data                                    |
  | - Compliance theater (checking box without benefit)                    |
  |                                                                        |
  | CORRECT:                                                               |
  | Regular review of high-risk sessions                                   |
  | Automated analysis with OCR/command matching                           |
  | Alert on suspicious patterns                                           |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  MISTAKE 6: VENDOR TRUST
  =======================

  +------------------------------------------------------------------------+
  |                                                                        |
  | WRONG:                                                                 |
  | "Vendor X is trusted - give them full access to maintain equipment"    |
  |                                                                        |
  | IMPACT:                                                                |
  | - Vendor credentials compromised = full OT access                      |
  | - No visibility into vendor actions                                    |
  | - Supply chain attack vector                                           |
  |                                                                        |
  | CORRECT:                                                               |
  | Vendors get ONLY access to their specific equipment                    |
  | All vendor sessions monitored and recorded                             |
  | Time-limited access with approval                                      |
  |                                                                        |
  +------------------------------------------------------------------------+

+===============================================================================+
```

---

## Quick Reference Guide

### OT PAM Cheat Sheet

```
+===============================================================================+
|                   WALLIX OT QUICK REFERENCE                                  |
+===============================================================================+

  COMMON COMMANDS
  ===============

  +------------------------------------------------------------------------+
  | Task                         | Command                                 |
  +------------------------------+-----------------------------------------+
  | Check system status          | wab-admin status                        |
  | Kill active session          | wab-admin kill-session --id <id>        |
  | Force password rotation      | wab-admin rotate-password --account <a> |
  | Export audit logs            | wab-admin export-logs --start <date>    |
  | Generate compliance report   | wab-admin compliance-report             |
  | Restart services             | wab-admin restart                       |
  | Backup system                | wab-admin backup --full                 |
  | Check HA status              | wab-admin cluster-status                |
  +------------------------------+-----------------------------------------+

  --------------------------------------------------------------------------

  CRITICAL PATHS
  ==============

  +------------------------------------------------------------------------+
  | File/Location                          | Purpose                       |
  +----------------------------------------+-------------------------------+
  | /etc/opt/wab/wabengine/wabengine.conf  | Main configuration            |
  | /var/wab/recorded/                     | Session recordings            |
  | /var/log/wab/                          | Application logs              |
  | /etc/opt/wab/certs/                    | SSL certificates              |
  | /var/lib/mysql/                        | Database files                |
  +----------------------------------------+-------------------------------+

  --------------------------------------------------------------------------

  EMERGENCY CONTACTS
  ==================

  +------------------------------------------------------------------------+
  | Role                    | Contact                                      |
  +-------------------------+----------------------------------------------+
  | WALLIX Support          | support@wallix.com / +33 1 XX XX XX XX       |
  | OT Security Team        | [Your contact info]                          |
  | Plant Manager (bypass)  | [Your contact info]                          |
  | IT Security (escalation)| [Your contact info]                          |
  +-------------------------+----------------------------------------------+

  --------------------------------------------------------------------------

  REGULATORY QUICK REFERENCE
  ==========================

  +------------------------------------------------------------------------+
  | Standard        | Key PAM Requirements                                 |
  +-----------------+------------------------------------------------------+
  | IEC 62443       | MFA (SL3+), session recording, audit logs            |
  | NERC CIP        | Intermediate system, access control, monitoring      |
  | NIS2            | Incident reporting, supply chain security            |
  | 21 CFR Part 11  | Electronic signatures, audit trail, user IDs         |
  | NIST CSF        | Identify, Protect, Detect, Respond, Recover          |
  +-----------------+------------------------------------------------------+

  --------------------------------------------------------------------------

  TROUBLESHOOTING QUICK CHECKS
  ============================

  +------------------------------------------------------------------------+
  |                                                                        |
  | CANNOT CONNECT TO TARGET                                               |
  | [ ] Check WALLIX -> target firewall rules                              |
  | [ ] Verify target is reachable: ping from WALLIX                       |
  | [ ] Check authorization exists for user/target                         |
  | [ ] Verify time restrictions allow current access                      |
  | [ ] Check if approval is pending                                       |
  |                                                                        |
  | AUTHENTICATION FAILING                                                 |
  | [ ] Verify LDAP/AD connectivity                                        |
  | [ ] Check user account status (not locked/disabled)                    |
  | [ ] Verify MFA token is synchronized                                   |
  | [ ] Check password expiration                                          |
  |                                                                        |
  | SESSION RECORDING NOT WORKING                                          |
  | [ ] Check storage space (/var/wab/recorded)                            |
  | [ ] Verify recording is enabled for authorization                      |
  | [ ] Check file system permissions                                      |
  | [ ] Review wabengine logs for errors                                   |
  |                                                                        |
  | HA FAILOVER NOT WORKING                                                |
  | [ ] Check cluster status: wab-admin cluster-status                     |
  | [ ] Verify network between nodes                                       |
  | [ ] Check shared storage connectivity                                  |
  | [ ] Review cluster logs                                                |
  |                                                                        |
  +------------------------------------------------------------------------+

+===============================================================================+

  End of WALLIX Industrial Security Documentation
  ===============================================

  For additional support:
  - WALLIX Documentation: https://docs.wallix.com
  - WALLIX Support Portal: https://support.wallix.com
  - Community Forums: https://community.wallix.com

+===============================================================================+
```

---

## Summary

This industrial security best practices guide covers:

1. **Design Principles**: OT-first thinking, defense in depth, least privilege
2. **Deployment**: Comprehensive checklists for planning and implementation
3. **Operations**: Daily, weekly, monthly, and quarterly security tasks
4. **Incident Response**: Specific procedures for PAM-related incidents
5. **Maintenance**: Upgrade, certificate, and backup procedures
6. **Common Mistakes**: Anti-patterns to avoid and correct approaches
7. **Quick Reference**: Commands, paths, contacts, and troubleshooting

---

**Congratulations!** You have completed the WALLIX Industrial PAM documentation series.

## Next Steps

Continue to [16 - Cloud Deployment](../pam/16-cloud-deployment/README.md) for cloud deployment patterns and Terraform examples.
