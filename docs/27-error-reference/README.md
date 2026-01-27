# 27 - Error Code Reference

## Table of Contents

1. [Error Code Format](#error-code-format)
2. [Authentication Errors (1xxx)](#authentication-errors-1xxx)
3. [Authorization Errors (2xxx)](#authorization-errors-2xxx)
4. [Session Errors (3xxx)](#session-errors-3xxx)
5. [Password Management Errors (4xxx)](#password-management-errors-4xxx)
6. [System Errors (5xxx)](#system-errors-5xxx)
7. [Integration Errors (6xxx)](#integration-errors-6xxx)
8. [Troubleshooting Flowcharts](#troubleshooting-flowcharts)

---

## Error Code Format

### Understanding Error Codes

```
+==============================================================================+
|                   WALLIX ERROR CODE FORMAT                                   |
+==============================================================================+

  ERROR CODE STRUCTURE
  ====================

  +------------------------------------------------------------------------+
  |                                                                        |
  |   WAB-XYYY-ZZZ                                                         |
  |   |   |    |                                                           |
  |   |   |    +-- Specific error number                                   |
  |   |   +------- Category (1=Auth, 2=Authz, 3=Session, etc.)             |
  |   +----------- Product prefix (WAB = WALLIX Bastion)                   |
  |                                                                        |
  +------------------------------------------------------------------------+

  SEVERITY LEVELS
  ===============

  +------------------------------------------------------------------------+
  | Level    | Code Range | Description                                    |
  +----------+------------+------------------------------------------------+
  | INFO     | x000-x099  | Informational, no action required              |
  | WARNING  | x100-x199  | Warning, may require attention                 |
  | ERROR    | x200-x399  | Error, action required                         |
  | CRITICAL | x400-x499  | Critical, immediate action required            |
  +----------+------------+------------------------------------------------+

  LOG LOCATIONS
  =============

  +------------------------------------------------------------------------+
  | Log File                              | Content                        |
  +---------------------------------------+--------------------------------+
  | /var/log/wab/wabengine.log            | Main application logs          |
  | /var/log/wab/wabauth.log              | Authentication logs            |
  | /var/log/wab/wabsession.log           | Session proxy logs             |
  | /var/log/wab/wabpassword.log          | Password rotation logs         |
  | /var/log/wab/wabaudit.log             | Audit trail                    |
  | /var/log/postgresql/postgresql.log    | Database logs                  |
  +---------------------------------------+--------------------------------+

+==============================================================================+
```

---

## Authentication Errors (1xxx)

### Authentication Error Codes

```
+==============================================================================+
|                   AUTHENTICATION ERRORS                                      |
+==============================================================================+

  WAB-1001: INVALID_CREDENTIALS
  =============================

  Description: Username or password is incorrect
  Severity: ERROR

  Possible Causes:
  * Incorrect password entered
  * Username does not exist
  * Account not synchronized from LDAP

  Resolution:
  1. Verify username is correct
  2. Reset password if forgotten
  3. Check LDAP synchronization status
  4. Review wabauth.log for details

  Log Example:
  +------------------------------------------------------------------------+
  | 2024-01-27 10:00:00 ERROR [wabauth] WAB-1001: Authentication failed    |
  | for user 'jsmith' from 192.168.1.100 - Invalid credentials             |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  WAB-1002: ACCOUNT_LOCKED
  ========================

  Description: User account is locked due to failed login attempts
  Severity: ERROR

  Possible Causes:
  * Too many failed login attempts (default: 5)
  * Account manually locked by administrator
  * Account locked in LDAP/AD

  Resolution:
  1. Wait for automatic unlock (if configured)
  2. Admin unlock via: Admin > Users > [user] > Unlock
  3. CLI: wab-admin unlock-user --username <user>
  4. Check LDAP account status

  Log Example:
  +------------------------------------------------------------------------+
  | 2024-01-27 10:00:00 ERROR [wabauth] WAB-1002: Account 'jsmith' locked  |
  | - 5 failed attempts in 5 minutes                                       |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  WAB-1003: ACCOUNT_EXPIRED
  =========================

  Description: User account has expired
  Severity: ERROR

  Possible Causes:
  * Account expiration date passed
  * Temporary account not renewed
  * Vendor account validity period ended

  Resolution:
  1. Extend account validity: Admin > Users > [user] > Edit > Valid Until
  2. Contact administrator to renew account
  3. For vendors: Submit new access request

  --------------------------------------------------------------------------

  WAB-1004: ACCOUNT_DISABLED
  ==========================

  Description: User account is disabled
  Severity: ERROR

  Possible Causes:
  * Account manually disabled
  * Account disabled in LDAP/AD
  * Automatic disabling due to inactivity

  Resolution:
  1. Enable account: Admin > Users > [user] > Enable
  2. Check LDAP account status
  3. Review account disable policies

  --------------------------------------------------------------------------

  WAB-1005: MFA_REQUIRED
  ======================

  Description: Multi-factor authentication required but not provided
  Severity: ERROR

  Possible Causes:
  * User did not enter OTP/token
  * MFA device not registered
  * MFA policy requires stronger authentication

  Resolution:
  1. Enter valid OTP from authenticator app or hardware token
  2. Register MFA device if not done
  3. Contact admin to reset MFA if device lost

  --------------------------------------------------------------------------

  WAB-1006: MFA_INVALID
  =====================

  Description: MFA token/OTP is invalid or expired
  Severity: ERROR

  Possible Causes:
  * Incorrect OTP entered
  * OTP expired (typically 30-60 second window)
  * Time synchronization issue
  * Wrong MFA device/account used

  Resolution:
  1. Wait for next OTP and enter immediately
  2. Verify time on MFA device matches server time
  3. Ensure correct account in authenticator app
  4. Reset MFA if consistently failing

  --------------------------------------------------------------------------

  WAB-1010: LDAP_CONNECTION_FAILED
  ================================

  Description: Cannot connect to LDAP/AD server
  Severity: CRITICAL

  Possible Causes:
  * LDAP server down or unreachable
  * Network connectivity issue
  * Firewall blocking LDAP ports (389/636)
  * DNS resolution failure
  * SSL/TLS certificate issue

  Resolution:
  1. Verify LDAP server status
  2. Test connectivity: telnet <ldap-server> 636
  3. Check firewall rules
  4. Verify DNS resolution
  5. Check certificate validity

  Log Example:
  +------------------------------------------------------------------------+
  | 2024-01-27 10:00:00 CRITICAL [wabauth] WAB-1010: LDAP connection       |
  | failed to ldap.company.com:636 - Connection timed out                  |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  WAB-1011: LDAP_BIND_FAILED
  ==========================

  Description: LDAP bind (authentication) failed
  Severity: ERROR

  Possible Causes:
  * LDAP service account credentials incorrect
  * Service account locked or expired
  * Insufficient permissions for service account

  Resolution:
  1. Verify LDAP bind credentials in configuration
  2. Test bind with ldapsearch command
  3. Check service account in AD

  --------------------------------------------------------------------------

  WAB-1012: LDAP_USER_NOT_FOUND
  =============================

  Description: User exists in WALLIX but not found in LDAP
  Severity: ERROR

  Possible Causes:
  * User deleted from LDAP
  * Search base DN incorrect
  * LDAP filter too restrictive
  * User in different OU than configured

  Resolution:
  1. Verify user exists in LDAP: ldapsearch -b "dc=company,dc=com" "(sAMAccountName=jsmith)"
  2. Check LDAP search base DN configuration
  3. Review LDAP user filter

  --------------------------------------------------------------------------

  WAB-1020: RADIUS_CONNECTION_FAILED
  ==================================

  Description: Cannot connect to RADIUS server for MFA
  Severity: CRITICAL

  Possible Causes:
  * RADIUS server down
  * Network connectivity issue
  * Firewall blocking RADIUS ports (1812/1813)
  * Shared secret mismatch

  Resolution:
  1. Verify RADIUS server status
  2. Test connectivity to RADIUS port
  3. Verify shared secret configuration
  4. Check RADIUS server logs

  --------------------------------------------------------------------------

  WAB-1021: RADIUS_TIMEOUT
  ========================

  Description: RADIUS server did not respond in time
  Severity: ERROR

  Possible Causes:
  * RADIUS server overloaded
  * Network latency
  * MFA push notification not acknowledged

  Resolution:
  1. Increase RADIUS timeout in configuration
  2. Check RADIUS server load
  3. Verify user received push notification

+==============================================================================+
```

---

## Authorization Errors (2xxx)

### Authorization Error Codes

```
+==============================================================================+
|                   AUTHORIZATION ERRORS                                       |
+==============================================================================+

  WAB-2001: NO_AUTHORIZATION
  ==========================

  Description: User has no authorization to access the requested target
  Severity: ERROR

  Possible Causes:
  * No authorization policy exists for user/group to target
  * User not member of authorized group
  * Authorization has been deleted or disabled

  Resolution:
  1. Check user's group membership
  2. Verify authorization exists: Admin > Authorizations
  3. Create or modify authorization if needed

  Log Example:
  +------------------------------------------------------------------------+
  | 2024-01-27 10:00:00 ERROR [wabauth] WAB-2001: No authorization for     |
  | user 'jsmith' to device 'plc-line1' account 'root'                     |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  WAB-2002: TIME_RESTRICTION
  ==========================

  Description: Access denied due to time restriction
  Severity: ERROR

  Possible Causes:
  * Current time outside allowed window
  * Access attempted on restricted day
  * Timezone mismatch

  Resolution:
  1. Check authorization time restrictions
  2. Wait until allowed time window
  3. Request temporary exception if urgent
  4. Verify server and client timezone settings

  Log Example:
  +------------------------------------------------------------------------+
  | 2024-01-27 22:00:00 ERROR [wabauth] WAB-2002: Time restriction -       |
  | user 'jsmith' denied access outside business hours (08:00-18:00)       |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  WAB-2003: APPROVAL_REQUIRED
  ===========================

  Description: Access requires approval from authorized approver
  Severity: INFO

  Possible Causes:
  * Authorization configured with approval workflow
  * Critical system access policy

  Resolution:
  1. Submit approval request through WALLIX
  2. Wait for approver to approve
  3. Contact approver directly if urgent

  --------------------------------------------------------------------------

  WAB-2004: APPROVAL_DENIED
  =========================

  Description: Access request was denied by approver
  Severity: ERROR

  Possible Causes:
  * Approver rejected the request
  * Request did not meet approval criteria
  * Maintenance window not confirmed

  Resolution:
  1. Review denial reason in approval history
  2. Contact approver for clarification
  3. Submit new request with updated justification

  --------------------------------------------------------------------------

  WAB-2005: APPROVAL_EXPIRED
  ==========================

  Description: Approval request timed out without response
  Severity: ERROR

  Possible Causes:
  * Approver did not respond in time
  * Approver unavailable
  * Email notification not received

  Resolution:
  1. Submit new approval request
  2. Contact approver directly
  3. Request emergency access if critical

  --------------------------------------------------------------------------

  WAB-2010: ACCOUNT_NOT_AVAILABLE
  ===============================

  Description: Target account not available (checked out by another user)
  Severity: ERROR

  Possible Causes:
  * Exclusive checkout policy - account in use
  * Account locked for maintenance
  * Previous session not properly closed

  Resolution:
  1. Wait for current user to release account
  2. Contact current user to expedite
  3. Admin can force release if necessary

  --------------------------------------------------------------------------

  WAB-2011: CONCURRENT_SESSION_LIMIT
  ==================================

  Description: User has reached maximum concurrent sessions
  Severity: ERROR

  Possible Causes:
  * User already has active sessions at limit
  * Sessions not properly terminated
  * Policy restricts concurrent connections

  Resolution:
  1. Close existing sessions before starting new one
  2. Check for orphaned sessions
  3. Request limit increase if business need

+==============================================================================+
```

---

## Session Errors (3xxx)

### Session Error Codes

```
+==============================================================================+
|                   SESSION ERRORS                                             |
+==============================================================================+

  WAB-3001: TARGET_UNREACHABLE
  ============================

  Description: Cannot establish connection to target system
  Severity: ERROR

  Possible Causes:
  * Target system down or unreachable
  * Network connectivity issue
  * Firewall blocking connection
  * Target IP/hostname incorrect

  Resolution:
  1. Verify target system is running
  2. Test connectivity: ping <target>
  3. Check firewall rules from WALLIX to target
  4. Verify target IP/hostname in device configuration

  Log Example:
  +------------------------------------------------------------------------+
  | 2024-01-27 10:00:00 ERROR [wabsession] WAB-3001: Cannot connect to     |
  | 10.10.1.10:22 - Connection refused                                     |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  WAB-3002: TARGET_AUTH_FAILED
  ============================

  Description: Authentication to target system failed
  Severity: ERROR

  Possible Causes:
  * Stored credentials incorrect or expired
  * Password was changed outside WALLIX
  * SSH key rejected
  * Account locked on target

  Resolution:
  1. Verify credentials in WALLIX vault
  2. Update password if changed externally
  3. Check target system authentication logs
  4. Manually rotate password to sync

  --------------------------------------------------------------------------

  WAB-3003: PROTOCOL_ERROR
  ========================

  Description: Protocol-level error during session
  Severity: ERROR

  Possible Causes:
  * Protocol version mismatch
  * Unsupported cipher/algorithm
  * Target configuration incompatible
  * Network packet corruption

  Resolution:
  1. Check target system protocol configuration
  2. Verify cipher compatibility
  3. Review session logs for specific error
  4. Update target system if outdated

  --------------------------------------------------------------------------

  WAB-3004: SESSION_TIMEOUT
  =========================

  Description: Session timed out due to inactivity
  Severity: INFO

  Possible Causes:
  * User idle beyond configured timeout
  * Network connection dropped
  * Client application closed unexpectedly

  Resolution:
  1. Reconnect and start new session
  2. Increase timeout if business need
  3. Use session keepalive if available

  --------------------------------------------------------------------------

  WAB-3005: SESSION_TERMINATED
  ============================

  Description: Session was terminated by administrator
  Severity: WARNING

  Possible Causes:
  * Admin manually terminated session
  * Security incident response
  * Emergency maintenance

  Resolution:
  1. Contact administrator for reason
  2. Review if access still permitted
  3. Start new session if authorized

  --------------------------------------------------------------------------

  WAB-3010: RECORDING_FAILED
  ==========================

  Description: Session recording could not be started or saved
  Severity: ERROR

  Possible Causes:
  * Recording storage full
  * Storage unreachable (NFS/NAS issue)
  * Permissions issue on recording directory
  * Disk I/O error

  Resolution:
  1. Check storage space: df -h /var/wab/recorded
  2. Verify NFS mount is accessible
  3. Check directory permissions
  4. Review system I/O errors

  --------------------------------------------------------------------------

  WAB-3011: RECORDING_STORAGE_FULL
  ================================

  Description: Recording storage has reached capacity
  Severity: CRITICAL

  Possible Causes:
  * Too many recordings stored
  * Archival not running
  * Retention policy not enforced
  * Unexpected large recordings

  Resolution:
  1. Archive old recordings immediately
  2. Increase storage capacity
  3. Review and enforce retention policy
  4. Clean up unnecessary recordings

  --------------------------------------------------------------------------

  WAB-3020: SUBPROTOCOL_DENIED
  ============================

  Description: Requested subprotocol not allowed by authorization
  Severity: ERROR

  Possible Causes:
  * File transfer attempted but not authorized
  * Clipboard access denied by policy
  * Port forwarding blocked

  Resolution:
  1. Check authorization subprotocol settings
  2. Request subprotocol to be enabled
  3. Use alternative method if available

  Log Example:
  +------------------------------------------------------------------------+
  | 2024-01-27 10:00:00 ERROR [wabsession] WAB-3020: Subprotocol           |
  | 'SSH_SCP' denied for session - not in authorization policy             |
  +------------------------------------------------------------------------+

+==============================================================================+
```

---

## Password Management Errors (4xxx)

### Password Management Error Codes

```
+==============================================================================+
|                   PASSWORD MANAGEMENT ERRORS                                 |
+==============================================================================+

  WAB-4001: ROTATION_FAILED
  =========================

  Description: Password rotation failed on target system
  Severity: ERROR

  Possible Causes:
  * Target system unreachable
  * Current credentials invalid
  * Password policy violation on target
  * Rotation connector error

  Resolution:
  1. Verify target connectivity
  2. Check current credentials
  3. Review target password policy
  4. Check connector configuration

  Log Example:
  +------------------------------------------------------------------------+
  | 2024-01-27 02:00:00 ERROR [wabpassword] WAB-4001: Password rotation    |
  | failed for account 'root' on device 'server1' - New password does not  |
  | meet target password policy requirements                                |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  WAB-4002: ROTATION_VERIFICATION_FAILED
  ======================================

  Description: Password changed but verification failed
  Severity: CRITICAL

  Possible Causes:
  * Password changed but stored incorrectly
  * Target reverted password change
  * Race condition with another process

  Resolution:
  1. IMMEDIATE: Manually verify/reset password
  2. Attempt manual rotation
  3. Check for concurrent password changes
  4. Review target system logs

  IMPORTANT: This state may leave account inaccessible!

  EMERGENCY RECOVERY PROCEDURE:
  +------------------------------------------------------------------------+
  | Step 1: Check current password in WALLIX                               |
  |   wabadmin account show <device>/<account> --show-password             |
  |                                                                        |
  | Step 2: Test authentication manually                                   |
  |   ssh <account>@<device>    # For SSH targets                          |
  |   OR use target's admin console                                        |
  |                                                                        |
  | Step 3: If password is wrong - Force reconciliation                    |
  |   wabadmin password reconcile <device>/<account>                       |
  |   Enter current target password when prompted                          |
  |                                                                        |
  | Step 4: Verify account is accessible                                   |
  |   wabadmin password verify <device>/<account>                          |
  |                                                                        |
  | Step 5: If target locked out - Contact target system admin             |
  |   Use break-glass account or local admin to reset password             |
  |   Then reconcile in WALLIX                                             |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  WAB-4003: CONNECTOR_ERROR
  =========================

  Description: Password rotation connector encountered error
  Severity: ERROR

  Possible Causes:
  * Connector not configured properly
  * Connector for target type not available
  * Protocol not supported for rotation

  Resolution:
  1. Verify connector configuration
  2. Check connector compatibility with target
  3. Review connector logs

  --------------------------------------------------------------------------

  WAB-4010: CHECKOUT_CONFLICT
  ===========================

  Description: Credential already checked out by another user
  Severity: ERROR

  Possible Causes:
  * Exclusive checkout policy
  * Previous checkout not released
  * System error leaving orphaned checkout

  Resolution:
  1. Wait for checkout to be released
  2. Contact current checkout holder
  3. Admin can force release if necessary

  ADMIN COMMANDS FOR CHECKOUT MANAGEMENT:
  +------------------------------------------------------------------------+
  | View current checkouts:                                                |
  |   wabadmin checkout list                                               |
  |   wabadmin checkout list --account=<device>/<account>                  |
  |                                                                        |
  | View checkout details:                                                 |
  |   wabadmin checkout show <checkout-id>                                 |
  |                                                                        |
  | Force release checkout (requires admin privileges):                    |
  |   wabadmin checkout release <checkout-id> --force                      |
  |                                                                        |
  | Release all orphaned checkouts (cleanup):                              |
  |   wabadmin checkout cleanup --orphaned                                 |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  WAB-4011: CHECKOUT_EXPIRED
  ==========================

  Description: Credential checkout has expired
  Severity: WARNING

  Possible Causes:
  * Checkout duration exceeded
  * Session ended without explicit checkin

  Resolution:
  1. Request new checkout
  2. Extend checkout if needed
  3. Complete work within checkout window

  --------------------------------------------------------------------------

  WAB-4020: VAULT_UNAVAILABLE
  ===========================

  Description: Credential vault is unavailable
  Severity: CRITICAL

  Possible Causes:
  * Vault service not running
  * Database connection lost
  * Encryption key unavailable
  * HSM connection failed

  Resolution:
  1. Check vault service status
  2. Verify database connectivity
  3. Check HSM connection (if used)
  4. Restart vault service if needed

+==============================================================================+
```

---

## System Errors (5xxx)

### System Error Codes

```
+==============================================================================+
|                   SYSTEM ERRORS                                              |
+==============================================================================+

  WAB-5001: SERVICE_UNAVAILABLE
  =============================

  Description: Core WALLIX service is unavailable
  Severity: CRITICAL

  Possible Causes:
  * Service not started
  * Service crashed
  * Resource exhaustion (memory/CPU)
  * Configuration error

  Resolution:
  1. Check service status: systemctl status wabengine
  2. Review logs: journalctl -u wabengine
  3. Restart service: systemctl restart wabengine
  4. Check system resources

  --------------------------------------------------------------------------

  WAB-5002: DATABASE_ERROR
  ========================

  Description: Database connection or query error
  Severity: CRITICAL

  Possible Causes:
  * PostgreSQL service down
  * Connection pool exhausted
  * Database corruption
  * Disk full

  Resolution:
  1. Check PostgreSQL status: systemctl status postgresql
  2. Verify connectivity: psql -h localhost -U wallix
  3. Check disk space: df -h
  4. Review PostgreSQL logs

  --------------------------------------------------------------------------

  WAB-5003: CLUSTER_SYNC_ERROR
  ============================

  Description: HA cluster synchronization failed
  Severity: ERROR

  Possible Causes:
  * Network issue between cluster nodes
  * Primary node unreachable
  * Database replication lag
  * Configuration mismatch

  Resolution:
  1. Check cluster status: wab-admin cluster-status
  2. Verify network between nodes
  3. Check replication status
  4. Review cluster logs

  --------------------------------------------------------------------------

  WAB-5004: LICENSE_EXPIRED
  =========================

  Description: WALLIX license has expired
  Severity: CRITICAL

  Possible Causes:
  * License validity date passed
  * License not renewed

  Resolution:
  1. Contact WALLIX or reseller for license renewal
  2. Upload new license: Admin > System > License
  3. System may operate in limited mode until renewed

  --------------------------------------------------------------------------

  WAB-5005: LICENSE_LIMIT_EXCEEDED
  ================================

  Description: License usage limit exceeded
  Severity: WARNING

  Possible Causes:
  * Concurrent sessions exceed license
  * Too many users/devices configured
  * License tier insufficient

  Resolution:
  1. Close unnecessary sessions
  2. Review license usage: Admin > System > License
  3. Upgrade license tier if needed
  4. Remove unused users/devices

  --------------------------------------------------------------------------

  WAB-5010: DISK_SPACE_LOW
  ========================

  Description: System disk space critically low
  Severity: WARNING

  Possible Causes:
  * Recordings filling disk
  * Log files not rotated
  * Database growth
  * Backup files accumulated

  Resolution:
  1. Check disk usage: df -h
  2. Archive old recordings
  3. Clean up log files
  4. Review retention policies

  --------------------------------------------------------------------------

  WAB-5011: DISK_SPACE_CRITICAL
  =============================

  Description: System disk space critical - may cause service failure
  Severity: CRITICAL

  Possible Causes:
  * Same as WAB-5010 but more severe

  Resolution:
  1. IMMEDIATE: Free space urgently
  2. Move recordings to external storage
  3. Truncate old logs
  4. Expand disk if possible

  --------------------------------------------------------------------------

  WAB-5020: CERTIFICATE_EXPIRING
  ==============================

  Description: SSL certificate expiring soon
  Severity: WARNING

  Possible Causes:
  * Certificate not renewed
  * Auto-renewal failed

  Resolution:
  1. Renew certificate before expiration
  2. Upload new certificate: Admin > System > Certificates
  3. Restart services after renewal

  --------------------------------------------------------------------------

  WAB-5021: CERTIFICATE_EXPIRED
  =============================

  Description: SSL certificate has expired
  Severity: CRITICAL

  Possible Causes:
  * Certificate not renewed in time

  Resolution:
  1. IMMEDIATE: Renew and install new certificate
  2. Users may see security warnings
  3. Some integrations may fail

+==============================================================================+
```

---

## Integration Errors (6xxx)

### Integration Error Codes

```
+==============================================================================+
|                   INTEGRATION ERRORS                                         |
+==============================================================================+

  WAB-6001: SIEM_CONNECTION_FAILED
  ================================

  Description: Cannot send logs to SIEM server
  Severity: ERROR

  Possible Causes:
  * SIEM server unreachable
  * Firewall blocking syslog ports
  * TLS certificate issue
  * SIEM server rejecting logs

  Resolution:
  1. Verify SIEM server status
  2. Test connectivity: nc -zv <siem-server> 514
  3. Check TLS configuration
  4. Review SIEM server logs

  --------------------------------------------------------------------------

  WAB-6002: SIEM_CERTIFICATE_ERROR
  ================================

  Description: TLS certificate error when connecting to SIEM
  Severity: ERROR

  Possible Causes:
  * SIEM certificate expired
  * CA certificate not trusted
  * Certificate hostname mismatch

  Resolution:
  1. Update CA certificate in WALLIX
  2. Verify SIEM certificate validity
  3. Check hostname configuration

  --------------------------------------------------------------------------

  WAB-6010: ITSM_INTEGRATION_ERROR
  ================================

  Description: ITSM ticketing integration failed
  Severity: ERROR

  Possible Causes:
  * ITSM system unreachable
  * API credentials invalid
  * Webhook endpoint changed

  Resolution:
  1. Verify ITSM system availability
  2. Check API credentials
  3. Test webhook endpoint manually

  --------------------------------------------------------------------------

  WAB-6020: CMDB_SYNC_FAILED
  ==========================

  Description: CMDB synchronization failed
  Severity: WARNING

  Possible Causes:
  * CMDB API error
  * Data format mismatch
  * Network timeout

  Resolution:
  1. Check CMDB API status
  2. Review sync logs
  3. Verify data mapping configuration

+==============================================================================+
```

---

## Troubleshooting Flowcharts

### Common Issue Resolution

```
+==============================================================================+
|                   TROUBLESHOOTING FLOWCHARTS                                 |
+==============================================================================+

  USER CANNOT LOGIN
  =================

  Start
    |
    v
  [Check error code in log]
    |
    +-- WAB-1001 --> [Verify credentials] --> [Reset password if needed]
    |
    +-- WAB-1002 --> [Unlock account] --> [Review failed attempts]
    |
    +-- WAB-1010 --> [Check LDAP connectivity] --> [Verify LDAP config]
    |
    +-- WAB-1005/1006 --> [Verify MFA device] --> [Reset MFA if needed]
    |
    +-- Other --> [Review wabauth.log for details]

  --------------------------------------------------------------------------

  SESSION CANNOT START
  ====================

  Start
    |
    v
  [Check error code in log]
    |
    +-- WAB-2001 --> [Check authorizations] --> [Add authorization if needed]
    |
    +-- WAB-2002 --> [Check time restrictions] --> [Adjust or wait]
    |
    +-- WAB-2003 --> [Submit approval request] --> [Wait for approval]
    |
    +-- WAB-3001 --> [Check target connectivity] --> [Verify firewall]
    |
    +-- WAB-3002 --> [Check stored credentials] --> [Rotate password]
    |
    +-- Other --> [Review wabsession.log for details]

  --------------------------------------------------------------------------

  PASSWORD ROTATION FAILED
  ========================

  Start
    |
    v
  [Check error code in log]
    |
    +-- WAB-4001 --> [Check target connectivity]
    |                   |
    |                   +-- OK --> [Check current creds]
    |                   |              |
    |                   |              +-- Invalid --> [Manual reset]
    |                   |              |
    |                   |              +-- Valid --> [Check password policy]
    |                   |
    |                   +-- Fail --> [Fix network/firewall]
    |
    +-- WAB-4002 --> [CRITICAL: Manual intervention required]
    |                   |
    |                   +-- [Manually verify password on target]
    |                   +-- [Update WALLIX vault if needed]
    |
    +-- WAB-4003 --> [Check connector configuration]

  --------------------------------------------------------------------------

  SYSTEM PERFORMANCE ISSUES
  =========================

  Start
    |
    v
  [Check system resources]
    |
    +-- High CPU --> [Check active sessions] --> [Identify resource hogs]
    |
    +-- High Memory --> [Check for memory leaks] --> [Restart if needed]
    |
    +-- High Disk I/O --> [Check recording activity] --> [Move to faster storage]
    |
    +-- Low Disk Space --> [Clean up recordings] --> [Archive old data]
    |
    v
  [Still issues?]
    |
    +-- Yes --> [Review wabengine.log] --> [Contact support]
    |
    +-- No --> [Document resolution]

+==============================================================================+
```

---

## Next Steps

Continue to [28 - System Requirements](../28-system-requirements/README.md) for hardware and software specifications.
