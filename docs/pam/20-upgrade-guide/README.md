# 29 - Upgrade Guide

## Table of Contents

1. [Upgrade Overview](#upgrade-overview)
2. [Pre-Upgrade Checklist](#pre-upgrade-checklist)
3. [Version-Specific Upgrades](#version-specific-upgrades)
4. [Standard Upgrade Procedure](#standard-upgrade-procedure)
5. [HA Cluster Upgrade](#ha-cluster-upgrade)
6. [Post-Upgrade Verification](#post-upgrade-verification)
7. [Rollback Procedures](#rollback-procedures)

---

## Upgrade Overview

### Upgrade Path Matrix

```
+===============================================================================+
|                   WALLIX UPGRADE OVERVIEW                                    |
+===============================================================================+

  SUPPORTED UPGRADE PATHS
  =======================

  +------------------------------------------------------------------------+
  | From Version    | To Version      | Direct Upgrade | Notes             |
  +-----------------+-----------------+----------------+-------------------+
  | 10.0.x          | 10.1.x          | Yes            | Minor upgrade     |
  | 10.1.x          | 12.0.x          | Yes            | Major upgrade     |
  | 12.0.x          | 12.1.x          | Yes            | Minor upgrade     |
  | 9.x             | 12.x            | No             | Upgrade to 10.x   |
  |                 |                 |                | first             |
  +-----------------+-----------------+----------------+-------------------+

  UPGRADE PATH DIAGRAM
  ====================

  +------------------------------------------------------------------------+
  |                                                                        |
  |   9.x --> 10.0 --> 10.1 --> 12.0 --> 12.1                             |
  |                    |                |                                  |
  |                    +- MAJOR UPGRADE-+                                  |
  |                                                                        |
  |   * Minor upgrades (x.Y): Generally safe, minimal changes              |
  |   * Major upgrades (X.0): Review release notes carefully               |
  |   * NOTE: Version 11.x was skipped (10.x -> 12.x)                      |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  UPGRADE TYPES
  =============

  +------------------------------------------------------------------------+
  | Type            | Risk    | Downtime | When to Use                     |
  +-----------------+---------+----------+---------------------------------+
  | Patch Update    | Low     | Minutes  | Security fixes, bug fixes       |
  | (12.0.1->12.0.2)|         |          | within same minor version       |
  +-----------------+---------+----------+---------------------------------+
  | Minor Upgrade   | Medium  | 15-30min | New features, improvements      |
  | (12.0->12.1)    |         |          | within same major version       |
  +-----------------+---------+----------+---------------------------------+
  | Major Upgrade   | Higher  | 30-60min | Significant changes, new        |
  | (10.x->12.x)    |         |          | architecture, breaking changes  |
  +-----------------+---------+----------+---------------------------------+

  --------------------------------------------------------------------------

  UPGRADE PLANNING TIMELINE
  =========================

  +------------------------------------------------------------------------+
  |                                                                        |
  | Week -4: Review release notes, identify breaking changes               |
  |          |                                                             |
  | Week -3: Test upgrade in non-production environment                    |
  |          |                                                             |
  | Week -2: Verify test results, document any issues                      |
  |          |                                                             |
  | Week -1: Schedule maintenance window, notify users                     |
  |          Create full backup, verify backup integrity                   |
  |          |                                                             |
  | Day 0:   Execute upgrade during maintenance window                     |
  |          |                                                             |
  | Week +1: Monitor for issues, validate all functionality                |
  |                                                                        |
  +------------------------------------------------------------------------+

+===============================================================================+
```

---

## Pre-Upgrade Checklist

### Complete Checklist

```
+===============================================================================+
|                   PRE-UPGRADE CHECKLIST                                      |
+===============================================================================+

  PLANNING & PREPARATION
  ======================

  [ ] 1. REVIEW RELEASE NOTES
      - Read full release notes for target version
      - Identify breaking changes
      - Note deprecated features
      - Check known issues
      - Review upgrade requirements

  [ ] 2. CHECK SYSTEM REQUIREMENTS
      - Verify hardware meets new version requirements
      - Check disk space (need 2x current for safety)
      - Verify MariaDB version compatibility
      - Check browser compatibility for new UI features

  [ ] 3. VERIFY LICENSE
      - Confirm license valid for new version
      - Contact WALLIX if license update needed
      - Check license expiration date

  [ ] 4. PLAN MAINTENANCE WINDOW
      - Schedule during low-usage period
      - Allow 2x estimated time for safety
      - Notify all users in advance
      - Coordinate with change management

  --------------------------------------------------------------------------

  BACKUP & RECOVERY PREPARATION
  =============================

  [ ] 5. CREATE FULL BACKUP
      wab-admin backup --full --output /backup/pre-upgrade-$(date +%F).tar.gz

  [ ] 6. VERIFY BACKUP
      - Test backup file integrity
      - Verify backup can be listed/extracted
      - Document backup location

  [ ] 7. BACKUP DATABASE SEPARATELY
      mysqldump -u wallix -p wallix > /backup/wallix-db-$(date +%F).sql

  [ ] 8. EXPORT CONFIGURATION
      wab-admin export-config --output /backup/config-$(date +%F).xml

  [ ] 9. DOCUMENT CURRENT STATE
      - Record current version: wab-admin version
      - List active sessions
      - Document custom configurations
      - Screenshot key settings

  [ ] 10. PREPARE ROLLBACK PLAN
      - Document rollback steps
      - Verify backup restore procedure
      - Identify rollback decision criteria

  --------------------------------------------------------------------------

  SYSTEM CHECKS
  =============

  [ ] 11. CHECK SYSTEM HEALTH
      wab-admin status
      wab-admin health-check

  [ ] 12. VERIFY DISK SPACE
      df -h /
      df -h /var/wab
      # Need at least 10 GB free, preferably 20+ GB

  [ ] 13. CHECK CLUSTER STATUS (if HA)
      wab-admin cluster-status

  [ ] 14. VERIFY DATABASE
      wab-admin db-check
      # Check for corruption or pending migrations

  [ ] 15. REVIEW ACTIVE SESSIONS
      wab-admin session-list --active
      # Plan to terminate or wait for completion

  --------------------------------------------------------------------------

  INTEGRATION VERIFICATION
  ========================

  [ ] 16. TEST LDAP CONNECTIVITY
      wab-admin test-ldap

  [ ] 17. TEST SIEM CONNECTIVITY
      wab-admin test-syslog

  [ ] 18. VERIFY CERTIFICATE EXPIRY
      wab-admin cert-check
      # Renew if expiring within 30 days

  --------------------------------------------------------------------------

  FINAL PREPARATION
  =================

  [ ] 19. DOWNLOAD UPGRADE PACKAGE
      - Download from WALLIX support portal
      - Verify checksum/signature
      - Transfer to WALLIX server

  [ ] 20. NOTIFY STAKEHOLDERS
      - Send maintenance notification
      - Confirm on-call support availability
      - Document emergency contacts

  [ ] 21. PREPARE TEST PLAN
      - List critical functions to test post-upgrade
      - Identify test users/sessions
      - Prepare test credentials

+===============================================================================+
```

---

## Version-Specific Upgrades

### Version 10.x to 12.x Upgrade

```
+===============================================================================+
|                   VERSION 10.x TO 12.x UPGRADE                               |
+===============================================================================+

  BREAKING CHANGES IN 12.x
  ========================

  +------------------------------------------------------------------------+
  | Change                        | Impact                    | Action     |
  +-------------------------------+---------------------------+------------+
  | Debian 12 base OS             | OS upgrade required       | Plan full  |
  |                               |                           | reinstall  |
  +-------------------------------+---------------------------+------------+
  | API v3.11 removed             | Old integrations fail     | Update to  |
  |                               |                           | latest API |
  +-------------------------------+---------------------------+------------+
  | /api/apikeys deprecated       | API key management change | Use        |
  |                               |                           | /apikeys-v2|
  +-------------------------------+---------------------------+------------+
  | Legacy license keys removed   | Old licenses invalid      | Get new    |
  |                               |                           | license    |
  +-------------------------------+---------------------------+------------+
  | HA DRBD scripts removed       | Manual HA config needed   | Review HA  |
  |                               |                           | setup      |
  +-------------------------------+---------------------------+------------+
  | Security level "high" default | Stricter crypto settings  | Review SSH |
  |                               |                           | ciphers    |
  +-------------------------------+---------------------------+------------+
  | RDP-JUMPHOST policy removed   | Jumphost config changes   | Update RDP |
  |                               |                           | policies   |
  +-------------------------------+---------------------------+------------+
  | Legacy UI pages removed       | User Groups, API Keys,    | Use new UI |
  |                               | My Authorizations pages   |            |
  +-------------------------------+---------------------------+------------+

  --------------------------------------------------------------------------

  NEW FEATURES IN 12.x
  ====================

  * OpenID Connect (OIDC) authentication support
  * Single Sign-On (SSO) integration
  * RDP session resolution enforcement
  * Whole disk encryption (LUKS) - auto-configured on install
  * Kerberos password reconciliation for Windows plugins
  * Network discovery with latency measurement
  * Enhanced HA database replication synchronization
  * Argon2ID as default key derivation function
  * 4GB quota on /home partition by default

  --------------------------------------------------------------------------

  SPECIFIC STEPS FOR 10.x to 12.x
  ===============================

  PRE-UPGRADE:

  1. Verify MariaDB version is 10.6+
     mysql --version
     # If < 10.6, upgrade MariaDB first

  2. Check for deprecated features in use
     wab-admin deprecation-check

  3. Export API integrations configuration
     # Review all scripts using deprecated API endpoints

  4. Backup custom scripts/plugins
     cp -r /etc/opt/wab/scripts /backup/

  5. Verify SMTP server has valid certificate
     # SMTP certificate validation is now mandatory

  UPGRADE EXECUTION:

  1. Stop all services
     systemctl stop wabengine

  2. Run database pre-migration check
     wab-admin db-premigrate --version 12.0

  3. Apply upgrade package
     wab-admin upgrade --package wallix-12.0.0.wab

  4. Run database migration
     wab-admin db-migrate
     # This may take 15-30 minutes for large databases

  5. Start services
     systemctl start wabengine

  POST-UPGRADE:

  1. Verify new features enabled
     wab-admin feature-check

  2. Test API integrations
     curl -X GET "https://wallix/api/v2/status" -H "Authorization: Bearer ..."

  3. Review SSH cipher configuration (now defaults to high security)
     # Allowed ciphers: aes256-gcm@openssh.com, aes128-gcm@openssh.com,
     # aes256-ctr, aes192-ctr, aes128-ctr

  3. Verify recording playback with new player

+===============================================================================+
```

### Minor Version Upgrades

```
+===============================================================================+
|                   MINOR VERSION UPGRADES                                     |
+===============================================================================+

  MINOR UPGRADE PROCEDURE (e.g., 12.0 to 12.1)
  ============================================

  Minor upgrades are generally straightforward with minimal breaking changes.

  QUICK UPGRADE STEPS:

  1. Create backup
     wab-admin backup --full --output /backup/pre-12.1-upgrade.tar.gz

  2. Download and verify package
     sha256sum wallix-12.1.0.wab
     # Compare with published checksum

  3. Apply upgrade
     wab-admin upgrade --package wallix-12.1.0.wab

  4. Restart services (automatic in most cases)
     systemctl restart wabengine

  5. Verify version
     wab-admin version

  6. Run health check
     wab-admin health-check

  --------------------------------------------------------------------------

  PATCH UPDATES (e.g., 12.0.1 to 12.0.2)
  ======================================

  Patch updates contain bug fixes and security updates.

  QUICK PATCH STEPS:

  1. Backup configuration (full backup optional)
     wab-admin export-config --output /backup/config-pre-patch.xml

  2. Apply patch
     wab-admin patch --package wallix-12.0.2-patch.wab

  3. Verify
     wab-admin version
     wab-admin health-check

  Note: Patches typically do not require full service restart.

+===============================================================================+
```

---

## Standard Upgrade Procedure

### Step-by-Step Upgrade

```
+===============================================================================+
|                   STANDARD UPGRADE PROCEDURE                                 |
+===============================================================================+

  PHASE 1: PREPARATION (30 minutes before maintenance)
  ====================================================

  1. Final backup
     +--------------------------------------------------------------------+
     | # Create timestamped backup                                        |
     | BACKUP_DATE=$(date +%Y%m%d_%H%M%S)                                  |
     | wab-admin backup --full --output /backup/upgrade-${BACKUP_DATE}.tar.gz
     |                                                                    |
     | # Verify backup                                                    |
     | ls -la /backup/upgrade-${BACKUP_DATE}.tar.gz                       |
     +--------------------------------------------------------------------+

  2. Document current state
     +--------------------------------------------------------------------+
     | # Record version                                                   |
     | wab-admin version > /backup/version-before.txt                     |
     |                                                                    |
     | # Record active sessions                                           |
     | wab-admin session-list --active > /backup/sessions-before.txt      |
     |                                                                    |
     | # Record system status                                             |
     | wab-admin status > /backup/status-before.txt                       |
     +--------------------------------------------------------------------+

  3. Transfer upgrade package
     +--------------------------------------------------------------------+
     | # Verify package on server                                         |
     | ls -la /tmp/wallix-12.0.0.wab                                      |
     |                                                                    |
     | # Verify checksum                                                  |
     | sha256sum /tmp/wallix-12.0.0.wab                                   |
     | # Compare with official checksum from WALLIX                       |
     +--------------------------------------------------------------------+

  --------------------------------------------------------------------------

  PHASE 2: MAINTENANCE WINDOW START
  =================================

  4. Notify users and disable new sessions
     +--------------------------------------------------------------------+
     | # Enable maintenance mode (blocks new sessions)                    |
     | wab-admin maintenance-mode --enable                                |
     |                                                                    |
     | # Wait for active sessions to complete (or terminate)              |
     | wab-admin session-list --active                                    |
     |                                                                    |
     | # If urgent, terminate sessions gracefully                         |
     | wab-admin session-terminate-all --grace-period 300                 |
     +--------------------------------------------------------------------+

  5. Stop services
     +--------------------------------------------------------------------+
     | # Stop WALLIX services                                             |
     | systemctl stop wabengine                                           |
     | systemctl stop wab-webui                                           |
     |                                                                    |
     | # Verify services stopped                                          |
     | systemctl status wabengine                                         |
     +--------------------------------------------------------------------+

  --------------------------------------------------------------------------

  PHASE 3: UPGRADE EXECUTION
  ==========================

  6. Apply upgrade package
     +--------------------------------------------------------------------+
     | # Run upgrade                                                      |
     | wab-admin upgrade --package /tmp/wallix-12.0.0.wab                  |
     |                                                                    |
     | # Monitor output for errors                                        |
     | # Typical output:                                                  |
     | # [INFO] Extracting upgrade package...                             |
     | # [INFO] Checking prerequisites...                                 |
     | # [INFO] Backing up current installation...                        |
     | # [INFO] Applying upgrade...                                       |
     | # [INFO] Running database migrations...                            |
     | # [INFO] Upgrade complete.                                         |
     +--------------------------------------------------------------------+

  7. Run database migrations (if not automatic)
     +--------------------------------------------------------------------+
     | # Check migration status                                           |
     | wab-admin db-migrate --status                                      |
     |                                                                    |
     | # Run pending migrations                                           |
     | wab-admin db-migrate                                               |
     +--------------------------------------------------------------------+

  8. Start services
     +--------------------------------------------------------------------+
     | # Start WALLIX services                                            |
     | systemctl start wabengine                                          |
     | systemctl start wab-webui                                          |
     |                                                                    |
     | # Verify services running                                          |
     | systemctl status wabengine                                         |
     +--------------------------------------------------------------------+

  --------------------------------------------------------------------------

  PHASE 4: VERIFICATION
  =====================

  9. Verify upgrade success
     +--------------------------------------------------------------------+
     | # Check new version                                                |
     | wab-admin version                                                  |
     |                                                                    |
     | # Run health check                                                 |
     | wab-admin health-check                                             |
     |                                                                    |
     | # Check status                                                     |
     | wab-admin status                                                   |
     +--------------------------------------------------------------------+

  10. Disable maintenance mode
     +--------------------------------------------------------------------+
     | wab-admin maintenance-mode --disable                               |
     +--------------------------------------------------------------------+

  11. Test critical functionality
     +--------------------------------------------------------------------+
     | # Test login via web UI                                            |
     | # Test SSH session                                                 |
     | # Test RDP session                                                 |
     | # Test API access                                                  |
     | # Verify recording playback                                        |
     +--------------------------------------------------------------------+

  --------------------------------------------------------------------------

  PHASE 5: POST-UPGRADE
  =====================

  12. Notify users of completion
     +--------------------------------------------------------------------+
     | # Send notification that maintenance is complete                   |
     | # Document any known issues or changes                             |
     +--------------------------------------------------------------------+

  13. Monitor for issues
     +--------------------------------------------------------------------+
     | # Watch logs for errors                                            |
     | tail -f /var/log/wab/wabengine.log                                 |
     |                                                                    |
     | # Monitor for 1-2 hours post-upgrade                               |
     +--------------------------------------------------------------------+

  14. Document upgrade
     +--------------------------------------------------------------------+
     | # Record new version                                               |
     | wab-admin version > /backup/version-after.txt                      |
     |                                                                    |
     | # Update change management records                                 |
     | # Archive upgrade logs                                             |
     +--------------------------------------------------------------------+

+===============================================================================+
```

---

## HA Cluster Upgrade

### High Availability Upgrade Procedure

```
+===============================================================================+
|                   HA CLUSTER UPGRADE                                         |
+===============================================================================+

  HA UPGRADE STRATEGY
  ===================

  +------------------------------------------------------------------------+
  |                                                                        |
  |   ROLLING UPGRADE (Recommended)                                        |
  |   ============================                                         |
  |                                                                        |
  |   1. Upgrade standby node first                                        |
  |   2. Failover to upgraded standby                                      |
  |   3. Upgrade original primary                                          |
  |   4. Re-establish cluster                                              |
  |                                                                        |
  |   Benefits:                                                            |
  |   - Minimal downtime (brief failover)                                  |
  |   - Easy rollback if issues                                            |
  |   - Production remains available                                       |
  |                                                                        |
  |   Timeline:                                                            |
  |                                                                        |
  |   +-------+     +-------+     +-------+     +-------+                  |
  |   | Start |     | Step 1|     | Step 2|     | Step 3|                  |
  |   +---+---+     +---+---+     +---+---+     +---+---+                  |
  |       |             |             |             |                       |
  |       v             v             v             v                       |
  |   Primary    Upgrade     Failover     Upgrade                          |
  |   Active     Standby    (30 sec)     Original                          |
  |   Standby                             Primary                           |
  |   Standby    Standby     Primary     Standby                           |
  |              (v10)       (v10)       (v10)                             |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  ROLLING UPGRADE PROCEDURE
  =========================

  PRE-UPGRADE:

  1. Verify cluster health
     +--------------------------------------------------------------------+
     | # On primary node                                                  |
     | wab-admin cluster-status                                           |
     |                                                                    |
     | # Expected output:                                                 |
     | # Cluster Status: HEALTHY                                          |
     | # Primary: node1.wallix.local (ACTIVE)                             |
     | # Standby: node2.wallix.local (STANDBY, SYNC)                      |
     +--------------------------------------------------------------------+

  2. Create backup on primary
     +--------------------------------------------------------------------+
     | wab-admin backup --full --output /backup/cluster-upgrade.tar.gz    |
     | # Copy to both nodes and external location                         |
     +--------------------------------------------------------------------+

  --------------------------------------------------------------------------

  PHASE 1: UPGRADE STANDBY NODE
  =============================

  3. On STANDBY node - Stop services
     +--------------------------------------------------------------------+
     | # On standby node                                                  |
     | systemctl stop wabengine                                           |
     |                                                                    |
     | # Verify primary still active                                      |
     | # On primary:                                                      |
     | wab-admin cluster-status                                           |
     | # Standby should show DISCONNECTED                                 |
     +--------------------------------------------------------------------+

  4. On STANDBY node - Apply upgrade
     +--------------------------------------------------------------------+
     | wab-admin upgrade --package /tmp/wallix-12.0.0.wab                  |
     +--------------------------------------------------------------------+

  5. On STANDBY node - Start services
     +--------------------------------------------------------------------+
     | systemctl start wabengine                                          |
     |                                                                    |
     | # Verify standby is running new version                            |
     | wab-admin version                                                  |
     +--------------------------------------------------------------------+

  6. Verify standby rejoins cluster
     +--------------------------------------------------------------------+
     | # On primary                                                       |
     | wab-admin cluster-status                                           |
     |                                                                    |
     | # Wait for replication to catch up                                 |
     | # Standby should show SYNC status                                  |
     +--------------------------------------------------------------------+

  --------------------------------------------------------------------------

  PHASE 2: FAILOVER
  =================

  7. Initiate planned failover
     +--------------------------------------------------------------------+
     | # On primary (old version)                                         |
     | wab-admin cluster-failover --planned                               |
     |                                                                    |
     | # This will:                                                       |
     | # - Stop accepting new sessions                                    |
     | # - Wait for replication sync                                      |
     | # - Promote standby to primary                                     |
     | # - Demote current primary to standby                              |
     |                                                                    |
     | # Downtime: ~30 seconds                                            |
     +--------------------------------------------------------------------+

  8. Verify failover complete
     +--------------------------------------------------------------------+
     | # On new primary (was standby, now v10)                            |
     | wab-admin cluster-status                                           |
     | wab-admin version                                                  |
     |                                                                    |
     | # Test session connectivity                                        |
     +--------------------------------------------------------------------+

  --------------------------------------------------------------------------

  PHASE 3: UPGRADE ORIGINAL PRIMARY
  =================================

  9. On ORIGINAL PRIMARY (now standby) - Apply upgrade
     +--------------------------------------------------------------------+
     | # Stop services                                                    |
     | systemctl stop wabengine                                           |
     |                                                                    |
     | # Apply upgrade                                                    |
     | wab-admin upgrade --package /tmp/wallix-12.0.0.wab                  |
     |                                                                    |
     | # Start services                                                   |
     | systemctl start wabengine                                          |
     +--------------------------------------------------------------------+

  10. Verify cluster fully upgraded
     +--------------------------------------------------------------------+
     | # On current primary                                               |
     | wab-admin cluster-status                                           |
     |                                                                    |
     | # Both nodes should show same version                              |
     | # Replication should be SYNC                                       |
     +--------------------------------------------------------------------+

  --------------------------------------------------------------------------

  PHASE 4: OPTIONAL - RESTORE ORIGINAL ROLES
  ==========================================

  11. (Optional) Failback to original primary
     +--------------------------------------------------------------------+
     | # Only if you prefer original node as primary                      |
     | wab-admin cluster-failover --planned                               |
     +--------------------------------------------------------------------+

+===============================================================================+
```

---

## Post-Upgrade Verification

### Verification Checklist

```
+===============================================================================+
|                   POST-UPGRADE VERIFICATION                                  |
+===============================================================================+

  IMMEDIATE VERIFICATION (First 15 minutes)
  =========================================

  [ ] 1. VERSION CHECK
      wab-admin version
      # Verify correct version installed

  [ ] 2. SERVICE STATUS
      wab-admin status
      systemctl status wabengine
      # All services should be running

  [ ] 3. HEALTH CHECK
      wab-admin health-check
      # No errors or warnings

  [ ] 4. DATABASE CONNECTIVITY
      wab-admin db-check
      # Database accessible and healthy

  [ ] 5. WEB UI ACCESS
      # Access https://wallix-server/
      # Login as admin
      # Verify dashboard loads

  --------------------------------------------------------------------------

  FUNCTIONAL VERIFICATION (First hour)
  ====================================

  [ ] 6. AUTHENTICATION TEST
      - Test local user login
      - Test LDAP user login
      - Test MFA authentication
      - Verify failed login handling

  [ ] 7. SESSION TEST - SSH
      - Establish SSH session through WALLIX
      - Verify session recording starts
      - Test command execution
      - Verify session terminates cleanly

  [ ] 8. SESSION TEST - RDP
      - Establish RDP session through WALLIX
      - Verify video recording
      - Test clipboard (if enabled)
      - Verify session terminates cleanly

  [ ] 9. AUTHORIZATION TEST
      - Verify user can access authorized targets
      - Verify user cannot access unauthorized targets
      - Test approval workflow (if used)
      - Verify time restrictions work

  [ ] 10. RECORDING VERIFICATION
      - View recent session recording
      - Verify recording playback works
      - Test session search
      - Verify OCR/text search (RDP)

  --------------------------------------------------------------------------

  INTEGRATION VERIFICATION (First 24 hours)
  =========================================

  [ ] 11. SIEM INTEGRATION
      - Verify logs flowing to SIEM
      - Check log format correct
      - Test alert generation

  [ ] 12. LDAP SYNCHRONIZATION
      - Verify user sync working
      - Check group membership updates
      - Test user authentication

  [ ] 13. API FUNCTIONALITY
      - Test API authentication
      - Verify key endpoints working
      - Test automation scripts

  [ ] 14. BACKUP VERIFICATION
      - Run post-upgrade backup
      - Verify backup completes successfully

  [ ] 15. PASSWORD ROTATION
      - Verify scheduled rotations run
      - Test manual rotation
      - Check rotation logs

  --------------------------------------------------------------------------

  MONITORING (First week)
  =======================

  [ ] 16. PERFORMANCE MONITORING
      - Monitor CPU/memory usage
      - Check session response times
      - Review database performance

  [ ] 17. ERROR MONITORING
      - Review application logs daily
      - Check for recurring errors
      - Monitor failed sessions

  [ ] 18. USER FEEDBACK
      - Collect feedback from users
      - Document any issues reported
      - Address concerns promptly

+===============================================================================+
```

---

## Rollback Procedures

### Rollback Decision and Execution

```
+===============================================================================+
|                   ROLLBACK PROCEDURES                                        |
+===============================================================================+

  ROLLBACK DECISION CRITERIA
  ==========================

  Consider rollback if ANY of the following occur:

  +------------------------------------------------------------------------+
  | Criteria                           | Severity  | Action               |
  +------------------------------------+-----------+----------------------+
  | Services won't start               | CRITICAL  | Immediate rollback   |
  | Database corruption detected       | CRITICAL  | Immediate rollback   |
  | Authentication completely broken   | CRITICAL  | Immediate rollback   |
  | > 50% of sessions failing          | HIGH      | Consider rollback    |
  | Major feature broken               | HIGH      | Evaluate workaround  |
  | Performance > 50% degraded         | MEDIUM    | Monitor, may rollback|
  | Minor issues, workarounds exist    | LOW       | Do not rollback      |
  +------------------------------------+-----------+----------------------+

  --------------------------------------------------------------------------

  ROLLBACK PROCEDURE
  ==================

  STEP 1: DECISION
  +------------------------------------------------------------------------+
  | # Document the decision                                                |
  | - Record issue(s) triggering rollback                                  |
  | - Get approval if required by change management                        |
  | - Notify stakeholders                                                  |
  +------------------------------------------------------------------------+

  STEP 2: STOP SERVICES
  +------------------------------------------------------------------------+
  | systemctl stop wabengine                                               |
  | systemctl stop wab-webui                                               |
  +------------------------------------------------------------------------+

  STEP 3: RESTORE FROM BACKUP
  +------------------------------------------------------------------------+
  | # Locate pre-upgrade backup                                            |
  | ls -la /backup/upgrade-*.tar.gz                                        |
  |                                                                        |
  | # Restore full backup                                                  |
  | wab-admin restore --file /backup/upgrade-20240127_100000.tar.gz        |
  |                                                                        |
  | # Or restore database only                                             |
  | sudo mysql wallix < /backup/wallix-db-20240127.sql                     |
  +------------------------------------------------------------------------+

  STEP 4: RESTORE PREVIOUS VERSION
  +------------------------------------------------------------------------+
  | # If backup includes application                                       |
  | wab-admin restore --full --file /backup/upgrade-20240127.tar.gz        |
  |                                                                        |
  | # Or reinstall previous version package                                |
  | wab-admin upgrade --package /backup/wallix-10.1.0.wab --force          |
  +------------------------------------------------------------------------+

  STEP 5: START SERVICES
  +------------------------------------------------------------------------+
  | systemctl start wabengine                                              |
  | systemctl start wab-webui                                              |
  +------------------------------------------------------------------------+

  STEP 6: VERIFY ROLLBACK
  +------------------------------------------------------------------------+
  | # Check version                                                        |
  | wab-admin version                                                      |
  | # Should show previous version                                         |
  |                                                                        |
  | # Health check                                                         |
  | wab-admin health-check                                                 |
  |                                                                        |
  | # Test functionality                                                   |
  | # - Login                                                              |
  | # - Start session                                                      |
  | # - Verify recordings                                                  |
  +------------------------------------------------------------------------+

  STEP 7: POST-ROLLBACK
  +------------------------------------------------------------------------+
  | # Document rollback                                                    |
  | - Record what failed                                                   |
  | - Collect logs for analysis                                            |
  | - Open support case with WALLIX                                        |
  |                                                                        |
  | # Notify stakeholders                                                  |
  | - Inform users system restored to previous version                     |
  | - Schedule follow-up for reattempt                                     |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  HA CLUSTER ROLLBACK
  ===================

  If rolling upgrade fails, rollback depends on phase:

  FAILED DURING STANDBY UPGRADE:
  +------------------------------------------------------------------------+
  | # Simply restore standby from backup                                   |
  | # Primary still running, no production impact                          |
  |                                                                        |
  | # On standby:                                                          |
  | wab-admin restore --file /backup/cluster-upgrade.tar.gz                |
  | systemctl start wabengine                                              |
  +------------------------------------------------------------------------+

  FAILED AFTER FAILOVER:
  +------------------------------------------------------------------------+
  | # Failback to original primary (still on old version)                  |
  | # On new primary (upgraded, having issues):                            |
  | wab-admin cluster-failover --emergency --to-node node1                 |
  |                                                                        |
  | # Then restore failed node from backup                                 |
  +------------------------------------------------------------------------+

  BOTH NODES UPGRADED, ISSUES DETECTED:
  +------------------------------------------------------------------------+
  | # Must restore both nodes from backup                                  |
  | # 1. Stop cluster                                                      |
  | # 2. Restore primary from backup                                       |
  | # 3. Restore standby from backup                                       |
  | # 4. Restart cluster                                                   |
  |                                                                        |
  | # This is why pre-upgrade backup is critical!                          |
  +------------------------------------------------------------------------+

+===============================================================================+
```

---

## Summary

This upgrade guide covers:

1. **Upgrade Planning**: Understanding upgrade paths and planning timeline
2. **Pre-Upgrade Checklist**: Complete preparation checklist
3. **Version-Specific Notes**: Breaking changes for major upgrades
4. **Standard Procedure**: Step-by-step upgrade process
5. **HA Cluster Upgrade**: Rolling upgrade for high availability
6. **Verification**: Post-upgrade testing checklist
7. **Rollback**: Decision criteria and procedures

---

## See Also

**Related Sections:**
- [30 - Backup & Restore](../30-backup-restore/README.md) - Backup strategies before upgrades
- [11 - High Availability](../11-high-availability/README.md) - HA cluster upgrade procedures

**Official Resources:**
- [WALLIX Documentation](https://pam.wallix.one/documentation)
- [WALLIX Release Notes](https://pam.wallix.one/documentation/release-notes)

---

## Next Steps

Continue to [30 - Operational Runbooks](../21-operational-runbooks/README.md) for day-to-day operational procedures.
