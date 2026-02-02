# 59 - User Self-Service Portal

## Table of Contents

1. [Self-Service Overview](#self-service-overview)
2. [Portal Architecture](#portal-architecture)
3. [Password Management](#password-management)
4. [MFA Self-Enrollment](#mfa-self-enrollment)
5. [Access Request Workflow](#access-request-workflow)
6. [Profile Management](#profile-management)
7. [Session History](#session-history)
8. [Credential Checkout](#credential-checkout)
9. [Emergency Access Request](#emergency-access-request)
10. [Mobile Access](#mobile-access)
11. [Configuration](#configuration)
12. [Troubleshooting](#troubleshooting)

---

## Self-Service Overview

### What is the Self-Service Portal?

The WALLIX Bastion Self-Service Portal empowers end users to manage their own accounts, security settings, and access requests without requiring administrator intervention. This reduces IT helpdesk burden while maintaining security controls and audit trails.

```
+===============================================================================+
|                    USER SELF-SERVICE CAPABILITIES                             |
+===============================================================================+
|                                                                               |
|  IDENTITY & SECURITY                                                          |
|  ===================                                                          |
|                                                                               |
|  +-------------------+   +-------------------+   +-------------------+        |
|  |   PASSWORD        |   |   MFA             |   |   PROFILE         |        |
|  |   MANAGEMENT      |   |   ENROLLMENT      |   |   SETTINGS        |        |
|  |                   |   |                   |   |                   |        |
|  |   * Reset         |   |   * FortiToken setup    |   |   * Contact info  |        |
|  |   * Change        |   |   * FortiToken keys    |   |   * Preferences   |        |
|  |   * History       |   |   * Backup codes  |   |   * Timezone      |        |
|  +-------------------+   +-------------------+   +-------------------+        |
|                                                                               |
|  ACCESS & SESSIONS                                                            |
|  =================                                                            |
|                                                                               |
|  +-------------------+   +-------------------+   +-------------------+        |
|  |   ACCESS          |   |   SESSION         |   |   CREDENTIAL      |        |
|  |   REQUESTS        |   |   HISTORY         |   |   CHECKOUT        |        |
|  |                   |   |                   |   |                   |        |
|  |   * New access    |   |   * View logs     |   |   * Self-service  |        |
|  |   * Track status  |   |   * Playback      |   |   * Time-limited  |        |
|  |   * Emergency     |   |   * Reports       |   |   * Check-in      |        |
|  +-------------------+   +-------------------+   +-------------------+        |
|                                                                               |
+===============================================================================+
```

### Key Benefits

| Benefit | Description |
|---------|-------------|
| **Reduced IT Burden** | Users handle routine tasks independently |
| **Faster Resolution** | No waiting for helpdesk tickets |
| **Enhanced Security** | Users own their MFA enrollment |
| **Compliance** | Full audit trail of self-service actions |
| **User Empowerment** | Transparency into own access and history |

### Security Considerations

```
+===============================================================================+
|                    SELF-SERVICE SECURITY CONTROLS                             |
+===============================================================================+
|                                                                               |
|  AUTHENTICATION REQUIREMENTS                                                  |
|  ===========================                                                  |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |  Action                          | Authentication Required            |   |
|  +----------------------------------+------------------------------------+   |
|  |  View profile                    | Standard login                     |   |
|  |  Change password                 | Current password + MFA             |   |
|  |  Reset password                  | Email/SMS verification             |   |
|  |  Enroll MFA                      | Current password + existing MFA    |   |
|  |  Request access                  | Standard login + MFA               |   |
|  |  Emergency access                | MFA + manager approval             |   |
|  |  View session history            | Standard login                     |   |
|  |  Download recordings             | MFA + explicit permission          |   |
|  +----------------------------------+------------------------------------+   |
|                                                                               |
|  RATE LIMITING                                                                |
|  =============                                                                |
|                                                                               |
|  * Password reset: 3 attempts per hour                                        |
|  * MFA enrollment: 5 enrollments per day                                      |
|  * Access requests: 10 pending requests maximum                               |
|  * Session exports: 5 downloads per day                                       |
|                                                                               |
+===============================================================================+
```

---

## Portal Architecture

### Component Overview

```
+===============================================================================+
|                    SELF-SERVICE PORTAL ARCHITECTURE                           |
+===============================================================================+
|                                                                               |
|                              +---------------------+                          |
|                              |     WEB BROWSER     |                          |
|                              |   (User Device)     |                          |
|                              +----------+----------+                          |
|                                         |                                     |
|                                         | HTTPS/443                           |
|                                         v                                     |
|  +-----------------------------------------------------------------------+   |
|  |                        WALLIX ACCESS MANAGER                          |   |
|  |                                                                       |   |
|  |  +-------------------+  +-------------------+  +-------------------+  |   |
|  |  |   Self-Service    |  |   Authentication  |  |   Authorization   |  |   |
|  |  |   Web UI          |  |   Gateway         |  |   Engine          |  |   |
|  |  +-------------------+  +-------------------+  +-------------------+  |   |
|  |                                                                       |   |
|  +--------------------------------+--------------------------------------+   |
|                                   |                                          |
|                                   | Internal API                             |
|                                   v                                          |
|  +-----------------------------------------------------------------------+   |
|  |                        WALLIX BASTION CORE                            |   |
|  |                                                                       |   |
|  |  +---------------+  +---------------+  +---------------+              |   |
|  |  |   User        |  |   Password    |  |   Session     |              |   |
|  |  |   Management  |  |   Manager     |  |   Manager     |              |   |
|  |  +---------------+  +---------------+  +---------------+              |   |
|  |                                                                       |   |
|  |  +---------------+  +---------------+  +---------------+              |   |
|  |  |   MFA         |  |   Approval    |  |   Audit       |              |   |
|  |  |   Service     |  |   Engine      |  |   Service     |              |   |
|  |  +---------------+  +---------------+  +---------------+              |   |
|  |                                                                       |   |
|  +--------------------------------+--------------------------------------+   |
|                                   |                                          |
|                                   v                                          |
|  +-----------------------------------------------------------------------+   |
|  |                        DATA STORES                                    |   |
|  |                                                                       |   |
|  |  +------------------+  +------------------+  +------------------+     |   |
|  |  |   PostgreSQL     |  |   Credential     |  |   Session        |     |   |
|  |  |   Database       |  |   Vault          |  |   Recordings     |     |   |
|  |  +------------------+  +------------------+  +------------------+     |   |
|  |                                                                       |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
+===============================================================================+
```

### Portal Access Methods

| Method | URL Pattern | Use Case |
|--------|-------------|----------|
| **Standard Portal** | `https://bastion.company.com/selfservice` | Primary access |
| **Direct Login** | `https://bastion.company.com/selfservice/login` | Bookmark-friendly |
| **Password Reset** | `https://bastion.company.com/selfservice/reset` | Forgot password flow |
| **Mobile Web** | `https://bastion.company.com/m/` | Mobile-optimized |

### Integration Points

```
+===============================================================================+
|                    EXTERNAL INTEGRATIONS                                      |
+===============================================================================+
|                                                                               |
|  +---------------------------+                                                |
|  |    SELF-SERVICE PORTAL    |                                                |
|  +--------------+------------+                                                |
|                 |                                                             |
|       +---------+---------+---------+---------+                               |
|       |         |         |         |         |                               |
|       v         v         v         v         v                               |
|  +--------+ +--------+ +--------+ +--------+ +--------+                       |
|  |  LDAP/ | |  SMTP  | |  SMS   | |Ticketing| | SIEM  |                       |
|  |   AD   | | Server | |Gateway | | System | |        |                       |
|  +--------+ +--------+ +--------+ +--------+ +--------+                       |
|  |Identity| |Password| | MFA    | |Service | |Audit   |                       |
|  |sync,   | |reset   | |delivery| |Now,    | |logging |                       |
|  |auth    | |emails  | |        | |Jira    | |        |                       |
|  +--------+ +--------+ +--------+ +--------+ +--------+                       |
|                                                                               |
+===============================================================================+
```

---

## Password Management

### Self-Service Password Reset

The password reset flow allows users to recover access without administrator assistance while maintaining security through identity verification.

```
+===============================================================================+
|                    PASSWORD RESET WORKFLOW                                    |
+===============================================================================+
|                                                                               |
|  +----------+                                                                 |
|  |   User   |  "I forgot my password"                                         |
|  +----+-----+                                                                 |
|       |                                                                       |
|       |  1. Click "Forgot Password" on login page                             |
|       v                                                                       |
|  +-----------------------------------------------------------------------+   |
|  |                    IDENTITY VERIFICATION                              |   |
|  |                                                                       |   |
|  |   Enter your username or email address:                               |   |
|  |   +-------------------------------------------------------+           |   |
|  |   | jsmith@company.com                                    |           |   |
|  |   +-------------------------------------------------------+           |   |
|  |                                                                       |   |
|  |   [Continue]                                                          |   |
|  |                                                                       |   |
|  +-----------------------------------------------------------------------+   |
|       |                                                                       |
|       |  2. System sends verification code                                    |
|       v                                                                       |
|  +-----------------------------------------------------------------------+   |
|  |                    VERIFICATION METHOD                                |   |
|  |                                                                       |   |
|  |   A verification code has been sent to:                               |   |
|  |                                                                       |   |
|  |   ( ) Email: j****h@company.com                                       |   |
|  |   ( ) SMS: +1 ***-***-4567                                            |   |
|  |   ( ) Authenticator app (if enrolled)                                 |   |
|  |                                                                       |   |
|  |   Enter 6-digit code:                                                 |   |
|  |   +------------------+                                                |   |
|  |   |                  |                                                |   |
|  |   +------------------+                                                |   |
|  |                                                                       |   |
|  |   [Verify]  [Resend Code]                                             |   |
|  |                                                                       |   |
|  +-----------------------------------------------------------------------+   |
|       |                                                                       |
|       |  3. Code verified, user sets new password                             |
|       v                                                                       |
|  +-----------------------------------------------------------------------+   |
|  |                    SET NEW PASSWORD                                   |   |
|  |                                                                       |   |
|  |   New Password:                                                       |   |
|  |   +-------------------------------------------------------+           |   |
|  |   | **********************                                |           |   |
|  |   +-------------------------------------------------------+           |   |
|  |                                                                       |   |
|  |   Confirm Password:                                                   |   |
|  |   +-------------------------------------------------------+           |   |
|  |   | **********************                                |           |   |
|  |   +-------------------------------------------------------+           |   |
|  |                                                                       |   |
|  |   Password Requirements:                                              |   |
|  |   [x] At least 14 characters                                          |   |
|  |   [x] Uppercase letter                                                |   |
|  |   [x] Lowercase letter                                                |   |
|  |   [x] Number                                                          |   |
|  |   [x] Special character                                               |   |
|  |   [x] Not in password history                                         |   |
|  |                                                                       |   |
|  |   [Reset Password]                                                    |   |
|  |                                                                       |   |
|  +-----------------------------------------------------------------------+   |
|       |                                                                       |
|       |  4. Password updated, audit logged                                    |
|       v                                                                       |
|  +-----------------------------------------------------------------------+   |
|  |   Password successfully reset. You can now log in.                    |   |
|  |                                                                       |   |
|  |   [Go to Login]                                                       |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
+===============================================================================+
```

### Password Change Workflow

Authenticated users can proactively change their password.

```
+===============================================================================+
|                    PASSWORD CHANGE WORKFLOW                                   |
+===============================================================================+
|                                                                               |
|  SELF-SERVICE PORTAL > SECURITY > CHANGE PASSWORD                            |
|  ================================================                            |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |                    CHANGE PASSWORD                                    |   |
|  |                                                                       |   |
|  |   Current Password:                                                   |   |
|  |   +-------------------------------------------------------+           |   |
|  |   | **********************                                |           |   |
|  |   +-------------------------------------------------------+           |   |
|  |                                                                       |   |
|  |   New Password:                                                       |   |
|  |   +-------------------------------------------------------+           |   |
|  |   |                                                       |           |   |
|  |   +-------------------------------------------------------+           |   |
|  |   Strength: [======----] Moderate                                     |   |
|  |                                                                       |   |
|  |   Confirm New Password:                                               |   |
|  |   +-------------------------------------------------------+           |   |
|  |   |                                                       |           |   |
|  |   +-------------------------------------------------------+           |   |
|  |                                                                       |   |
|  |   +-----------------------------------------------------------+       |   |
|  |   |  Password Policy: Corporate Standard                      |       |   |
|  |   |                                                           |       |   |
|  |   |  [x] Minimum 14 characters (you have: 16)                 |       |   |
|  |   |  [x] At least 1 uppercase letter                          |       |   |
|  |   |  [x] At least 1 lowercase letter                          |       |   |
|  |   |  [x] At least 1 number                                    |       |   |
|  |   |  [ ] At least 1 special character (!@#$%^&*)              |       |   |
|  |   |  [x] Cannot reuse last 12 passwords                       |       |   |
|  |   +-----------------------------------------------------------+       |   |
|  |                                                                       |   |
|  |   [ ] Log out all other sessions after password change                |   |
|  |                                                                       |   |
|  |   [Change Password]  [Cancel]                                         |   |
|  |                                                                       |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
+===============================================================================+
```

### Password Policy Enforcement

```json
{
    "password_policy": {
        "name": "self-service-policy",
        "description": "Policy for user self-service password changes",

        "length": {
            "minimum": 14,
            "maximum": 128
        },

        "complexity": {
            "uppercase_required": true,
            "lowercase_required": true,
            "digit_required": true,
            "special_required": true,
            "special_characters": "!@#$%^&*()_+-=[]{}|;:,.<>?"
        },

        "restrictions": {
            "no_username_in_password": true,
            "no_email_in_password": true,
            "no_common_patterns": true,
            "no_keyboard_sequences": true,
            "max_repeated_chars": 3
        },

        "history": {
            "remember_count": 12,
            "min_age_hours": 24
        },

        "expiration": {
            "max_age_days": 90,
            "warn_days_before": 14,
            "grace_logins": 3
        }
    }
}
```

### Password History and Audit

```
+===============================================================================+
|                    PASSWORD HISTORY                                           |
+===============================================================================+
|                                                                               |
|  SELF-SERVICE PORTAL > SECURITY > PASSWORD HISTORY                           |
|  =================================================                           |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |  Date/Time              | Action          | Method       | IP Address |   |
|  +-------------------------+-----------------+--------------+------------+   |
|  |  2026-01-28 14:32:15   | Changed         | Self-service | 10.1.5.42  |   |
|  |  2025-10-15 09:18:44   | Changed         | Self-service | 10.1.5.42  |   |
|  |  2025-07-22 11:45:33   | Reset           | Email verify | 192.168.1.1|   |
|  |  2025-04-10 16:22:18   | Changed         | Self-service | 10.1.5.42  |   |
|  |  2025-01-05 08:55:02   | Admin reset     | Admin portal | 10.1.1.10  |   |
|  +-------------------------+-----------------+--------------+------------+   |
|                                                                               |
|  Password expires: 2026-04-28 (90 days)                                       |
|  Last change: 29 days ago                                                     |
|                                                                               |
+===============================================================================+
```

---

## MFA Self-Enrollment

### FortiToken Enrollment

Users can self-enroll FortiToken apps (Google Authenticator, Microsoft Authenticator, Authy, etc.).

```
+===============================================================================+
|                    FORTITOKEN ENROLLMENT WORKFLOW                                   |
+===============================================================================+
|                                                                               |
|  SELF-SERVICE PORTAL > SECURITY > MFA > ENROLL AUTHENTICATOR                 |
|  ===========================================================                 |
|                                                                               |
|  Step 1: Scan QR Code                                                         |
|  =====================                                                        |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |                                                                       |   |
|  |   Scan this QR code with your authenticator app:                      |   |
|  |                                                                       |   |
|  |              +----------------------------+                           |   |
|  |              |   [QR CODE IMAGE]          |                           |   |
|  |              |                            |                           |   |
|  |              |   [====================]   |                           |   |
|  |              |   [====================]   |                           |   |
|  |              |   [====================]   |                           |   |
|  |              |   [====================]   |                           |   |
|  |              +----------------------------+                           |   |
|  |                                                                       |   |
|  |   Or enter this code manually:                                        |   |
|  |   JBSW Y3DP EHPK 3PXP 4XZA 2MZX                                       |   |
|  |                                                                       |   |
|  |   Account: jsmith@wallix-bastion                                      |   |
|  |   Issuer: WALLIX Bastion                                              |   |
|  |                                                                       |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
|  Step 2: Verify Setup                                                         |
|  ====================                                                         |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |                                                                       |   |
|  |   Enter the 6-digit code from your authenticator app:                 |   |
|  |                                                                       |   |
|  |   +----+ +----+ +----+ +----+ +----+ +----+                           |   |
|  |   |  4 | |  7 | |  2 | |  9 | |  0 | |  1 |                           |   |
|  |   +----+ +----+ +----+ +----+ +----+ +----+                           |   |
|  |                                                                       |   |
|  |   [Verify and Enable]                                                 |   |
|  |                                                                       |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
|  Step 3: Confirmation                                                         |
|  ====================                                                         |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |                                                                       |   |
|  |   FortiToken successfully enrolled!                           |   |
|  |                                                                       |   |
|  |   Device Name: My Authenticator                                       |   |
|  |   Enrolled: 2026-01-28 14:32:15                                       |   |
|  |                                                                       |   |
|  |   IMPORTANT: Generate backup codes now in case you lose access        |   |
|  |   to your authenticator app.                                          |   |
|  |                                                                       |   |
|  |   [Generate Backup Codes]  [Done]                                     |   |
|  |                                                                       |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
+===============================================================================+
```

### FortiToken Enrollment

Hardware FortiTokens provide phishing-resistant authentication.

```
+===============================================================================+
|                    FORTITOKEN ENROLLMENT                                  |
+===============================================================================+
|                                                                               |
|  SELF-SERVICE PORTAL > SECURITY > MFA > ENROLL SECURITY KEY                  |
|  ==========================================================                  |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |                                                                       |   |
|  |   REGISTER SECURITY KEY                                               |   |
|  |   =====================                                               |   |
|  |                                                                       |   |
|  |   Supported devices:                                                  |   |
|  |   * FortiToken Mobile App                                                  |   |
|  |   * FortiToken Hardware                                              |   |
|  |   * FortiToken 200                                                  |   |
|  |   * FortiToken 300                                                     |   |
|  |   * Windows Hello (biometric)                                         |   |
|  |   * macOS Touch ID                                                    |   |
|  |                                                                       |   |
|  |   Device Name:                                                        |   |
|  |   +-------------------------------------------------------+           |   |
|  |   | FortiToken - Primary                                  |           |   |
|  |   +-------------------------------------------------------+           |   |
|  |                                                                       |   |
|  |   [Begin Registration]                                                |   |
|  |                                                                       |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
|  Browser Prompt:                                                              |
|  ===============                                                              |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |                                                                       |   |
|  |   wallix-bastion.company.com wants to register a FortiToken         |   |
|  |                                                                       |   |
|  |   Insert your FortiToken and touch it, or use Windows Hello         |   |
|  |                                                                       |   |
|  |   +-------------------------------------------+                       |   |
|  |   |                                           |                       |   |
|  |   |      [FortiToken Icon]                  |                       |   |
|  |   |                                           |                       |   |
|  |   |      Touch your FortiToken              |                       |   |
|  |   |                                           |                       |   |
|  |   +-------------------------------------------+                       |   |
|  |                                                                       |   |
|  |   [Cancel]                                                            |   |
|  |                                                                       |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
|  Success:                                                                     |
|  ========                                                                     |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |                                                                       |   |
|  |   Security key registered successfully!                               |   |
|  |                                                                       |   |
|  |   Name: FortiToken - Primary                                          |   |
|  |   Type: USB FortiToken (FortiToken)                                      |   |
|  |   Registered: 2026-01-28 14:45:22                                     |   |
|  |   Credential ID: 8f4a2b...                                            |   |
|  |                                                                       |   |
|  |   [Register Another Key]  [Done]                                      |   |
|  |                                                                       |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
+===============================================================================+
```

### Backup Codes Generation

```
+===============================================================================+
|                    BACKUP CODES MANAGEMENT                                    |
+===============================================================================+
|                                                                               |
|  SELF-SERVICE PORTAL > SECURITY > MFA > BACKUP CODES                         |
|  ===================================================                         |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |                                                                       |   |
|  |   BACKUP CODES                                                        |   |
|  |   ============                                                        |   |
|  |                                                                       |   |
|  |   Use these codes if you lose access to your authenticator app        |   |
|  |   or FortiToken. Each code can only be used once.                   |   |
|  |                                                                       |   |
|  |   +-----------------------------------------------------------+       |   |
|  |   |                                                           |       |   |
|  |   |   1.  ABCD-1234-EFGH     [ ] Used                         |       |   |
|  |   |   2.  IJKL-5678-MNOP     [ ] Used                         |       |   |
|  |   |   3.  QRST-9012-UVWX     [x] Used (2026-01-15)            |       |   |
|  |   |   4.  YZAB-3456-CDEF     [ ] Used                         |       |   |
|  |   |   5.  GHIJ-7890-KLMN     [ ] Used                         |       |   |
|  |   |   6.  OPQR-1234-STUV     [ ] Used                         |       |   |
|  |   |   7.  WXYZ-5678-ABCD     [ ] Used                         |       |   |
|  |   |   8.  EFGH-9012-IJKL     [ ] Used                         |       |   |
|  |   |   9.  MNOP-3456-QRST     [ ] Used                         |       |   |
|  |   |  10.  UVWX-7890-YZAB     [ ] Used                         |       |   |
|  |   |                                                           |       |   |
|  |   +-----------------------------------------------------------+       |   |
|  |                                                                       |   |
|  |   Remaining codes: 9 of 10                                            |   |
|  |   Generated: 2026-01-10                                               |   |
|  |                                                                       |   |
|  |   [Download as PDF]  [Print Codes]  [Regenerate All]                  |   |
|  |                                                                       |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
|  WARNING: Regenerating codes will invalidate all existing codes.             |
|  Store these codes in a secure location separate from your device.           |
|                                                                               |
+===============================================================================+
```

### Recovery Options

```
+===============================================================================+
|                    MFA RECOVERY OPTIONS                                       |
+===============================================================================+
|                                                                               |
|  SELF-SERVICE PORTAL > SECURITY > MFA > RECOVERY                             |
|  ===============================================                             |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |                                                                       |   |
|  |   RECOVERY METHODS                                                    |   |
|  |   ================                                                    |   |
|  |                                                                       |   |
|  |   +-----------------------------------------------------------+       |   |
|  |   |  [ ] Email Recovery                                       |       |   |
|  |   |      Send recovery link to: j****h@company.com            |       |   |
|  |   +-----------------------------------------------------------+       |   |
|  |                                                                       |   |
|  |   +-----------------------------------------------------------+       |   |
|  |   |  [x] SMS Recovery                                         |       |   |
|  |   |      Send code to: +1 ***-***-4567                        |       |   |
|  |   +-----------------------------------------------------------+       |   |
|  |                                                                       |   |
|  |   +-----------------------------------------------------------+       |   |
|  |   |  [x] Manager Approval                                     |       |   |
|  |   |      Manager: Mary Johnson (mjohnson@company.com)         |       |   |
|  |   +-----------------------------------------------------------+       |   |
|  |                                                                       |   |
|  |   +-----------------------------------------------------------+       |   |
|  |   |  [x] Helpdesk Verification                                |       |   |
|  |   |      Answer security questions with IT support            |       |   |
|  |   +-----------------------------------------------------------+       |   |
|  |                                                                       |   |
|  |   [Save Recovery Options]                                             |   |
|  |                                                                       |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
+===============================================================================+
```

### Enrolled MFA Devices Overview

```
+===============================================================================+
|                    MY MFA DEVICES                                             |
+===============================================================================+
|                                                                               |
|  SELF-SERVICE PORTAL > SECURITY > MFA > MY DEVICES                           |
|  =================================================                           |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |  Device Name          | Type      | Status   | Last Used  | Actions   |   |
|  +-----------------------+-----------+----------+------------+-----------+   |
|  |  Google Authenticator | TOTP      | Active   | Today      | [Remove]  |   |
|  |  FortiToken Primary   | FortiToken     | Active   | Yesterday  | [Remove]  |   |
|  |  FortiToken Backup     | FortiToken     | Active   | 2025-12-01 | [Remove]  |   |
|  |  Work Phone           | Push      | Active   | Today      | [Remove]  |   |
|  |  Backup Codes (9/10)  | Recovery  | Active   | 2026-01-15 | [Manage]  |   |
|  +-----------------------+-----------+----------+------------+-----------+   |
|                                                                               |
|  [+ Enroll New Device]                                                        |
|                                                                               |
|  Default MFA Method: Google Authenticator                                     |
|  [Change Default]                                                             |
|                                                                               |
+===============================================================================+
```

---

## Access Request Workflow

### Requesting New Access

```
+===============================================================================+
|                    ACCESS REQUEST WORKFLOW                                    |
+===============================================================================+
|                                                                               |
|  SELF-SERVICE PORTAL > ACCESS > REQUEST NEW ACCESS                           |
|  =================================================                           |
|                                                                               |
|  Step 1: Select Resource Type                                                 |
|  ============================                                                 |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |                                                                       |   |
|  |   What type of access do you need?                                    |   |
|  |                                                                       |   |
|  |   +------------------+  +------------------+  +------------------+    |   |
|  |   |   SERVER         |  |   DATABASE       |  |   NETWORK        |    |   |
|  |   |   ACCESS         |  |   ACCESS         |  |   DEVICE         |    |   |
|  |   |                  |  |                  |  |                  |    |   |
|  |   |   Linux, Windows |  |   Oracle, SQL    |  |   Cisco, Juniper |    |   |
|  |   |   Unix servers   |  |   MySQL, Postgres|  |   Palo Alto      |    |   |
|  |   +------------------+  +------------------+  +------------------+    |   |
|  |                                                                       |   |
|  |   +------------------+  +------------------+  +------------------+    |   |
|  |   |   APPLICATION    |  |   CLOUD          |  |   OT/SCADA       |    |   |
|  |   |   ACCESS         |  |   CONSOLE        |  |   SYSTEM         |    |   |
|  |   |                  |  |                  |  |                  |    |   |
|  |   |   Web apps, RDP  |  |   AWS, Azure     |  |   PLCs, HMIs     |    |   |
|  |   |                  |  |   GCP consoles   |  |   SCADA systems  |    |   |
|  |   +------------------+  +------------------+  +------------------+    |   |
|  |                                                                       |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
|  Step 2: Select Specific Resource                                             |
|  ================================                                             |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |                                                                       |   |
|  |   Search for resource:                                                |   |
|  |   +-------------------------------------------------------+           |   |
|  |   | prod-web                                              |           |   |
|  |   +-------------------------------------------------------+           |   |
|  |                                                                       |   |
|  |   Available Resources:                                                |   |
|  |   +-----------------------------------------------------------+       |   |
|  |   | [ ] prod-web-01.company.com     | Linux   | Production    |       |   |
|  |   | [x] prod-web-02.company.com     | Linux   | Production    |       |   |
|  |   | [ ] prod-web-03.company.com     | Linux   | Production    |       |   |
|  |   | [ ] dev-web-01.company.com      | Linux   | Development   |       |   |
|  |   +-----------------------------------------------------------+       |   |
|  |                                                                       |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
|  Step 3: Request Details                                                      |
|  =======================                                                      |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |                                                                       |   |
|  |   Account Type:                                                       |   |
|  |   ( ) Read-only (monitoring, logs)                                    |   |
|  |   (x) Standard user (application management)                          |   |
|  |   ( ) Administrator (full control)                                    |   |
|  |   ( ) Root/Domain Admin (emergency only)                              |   |
|  |                                                                       |   |
|  |   Access Duration:                                                    |   |
|  |   +---------------------------+                                       |   |
|  |   | 4 hours                 v |                                       |   |
|  |   +---------------------------+                                       |   |
|  |   Options: 1h, 4h, 8h, 1 day, 1 week, 30 days, permanent              |   |
|  |                                                                       |   |
|  |   Start Time:                                                         |   |
|  |   (x) Immediately upon approval                                       |   |
|  |   ( ) Schedule: [Date Picker] [Time Picker]                           |   |
|  |                                                                       |   |
|  |   Business Justification: *                                           |   |
|  |   +-------------------------------------------------------+           |   |
|  |   | Need to deploy hotfix for JIRA-4521 security patch.   |           |   |
|  |   | Expected deployment window: 2 hours.                  |           |   |
|  |   +-------------------------------------------------------+           |   |
|  |                                                                       |   |
|  |   Related Ticket (optional):                                          |   |
|  |   +-------------------------------------------------------+           |   |
|  |   | JIRA-4521                                             |           |   |
|  |   +-------------------------------------------------------+           |   |
|  |                                                                       |   |
|  |   [Submit Request]                                                    |   |
|  |                                                                       |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
+===============================================================================+
```

### Request Approval Tracking

```
+===============================================================================+
|                    MY ACCESS REQUESTS                                         |
+===============================================================================+
|                                                                               |
|  SELF-SERVICE PORTAL > ACCESS > MY REQUESTS                                  |
|  ==========================================                                  |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |  Request ID  | Resource           | Status    | Submitted    | Expires|   |
|  +-------------+--------------------+-----------+--------------+---------+   |
|  |  REQ-2847   | prod-web-02        | APPROVED  | Today 14:32  | 18:32  |   |
|  |  REQ-2845   | prod-db-01         | PENDING   | Today 10:15  | -      |   |
|  |  REQ-2841   | dev-app-01         | APPROVED  | Yesterday    | Active |   |
|  |  REQ-2838   | prod-web-01        | DENIED    | 2 days ago   | -      |   |
|  |  REQ-2825   | staging-db         | EXPIRED   | 5 days ago   | Ended  |   |
|  +-------------+--------------------+-----------+--------------+---------+   |
|                                                                               |
|  [+ New Request]  [Filter by Status v]                                        |
|                                                                               |
+===============================================================================+

Request Detail View (REQ-2845):
==============================

+-----------------------------------------------------------------------+
|                                                                       |
|  REQUEST: REQ-2845                                                    |
|  Status: PENDING APPROVAL                                             |
|                                                                       |
|  +-----------------------------------------------------------+       |
|  |  Resource:        prod-db-01.company.com                  |       |
|  |  Account Type:    Database Administrator                  |       |
|  |  Duration:        4 hours                                 |       |
|  |  Requested:       2026-01-28 10:15:22                     |       |
|  |  Justification:   Database maintenance for JIRA-4520      |       |
|  +-----------------------------------------------------------+       |
|                                                                       |
|  APPROVAL CHAIN:                                                      |
|  ===============                                                      |
|                                                                       |
|  +-----------------------------------------------------------+       |
|  |  Step 1: Direct Manager                                   |       |
|  |  Approver: Mary Johnson                                   |       |
|  |  Status: APPROVED (2026-01-28 11:02:15)                   |       |
|  |  Comment: "Approved for maintenance window"               |       |
|  +-----------------------------------------------------------+       |
|                                                                       |
|  +-----------------------------------------------------------+       |
|  |  Step 2: Database Team Lead                               |       |
|  |  Approver: Bob Williams                                   |       |
|  |  Status: PENDING                                          |       |
|  |  Reminder sent: 2026-01-28 12:15:00                       |       |
|  +-----------------------------------------------------------+       |
|                                                                       |
|  [Cancel Request]  [Send Reminder]                                    |
|                                                                       |
+-----------------------------------------------------------------------+
```

### Access Expiration Handling

```
+===============================================================================+
|                    ACCESS EXPIRATION NOTIFICATIONS                            |
+===============================================================================+
|                                                                               |
|  EXPIRING SOON:                                                               |
|  ==============                                                               |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |                                                                       |   |
|  |   ACCESS EXPIRING IN 30 MINUTES                                       |   |
|  |                                                                       |   |
|  |   Resource: prod-web-02.company.com                                   |   |
|  |   Current session will end at: 18:32                                  |   |
|  |                                                                       |   |
|  |   [Request Extension]  [Dismiss]                                      |   |
|  |                                                                       |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
|  EXTENSION REQUEST:                                                           |
|  ==================                                                           |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |                                                                       |   |
|  |   Extend Access: prod-web-02.company.com                              |   |
|  |                                                                       |   |
|  |   Current expiration: 2026-01-28 18:32                                |   |
|  |                                                                       |   |
|  |   Extend by:                                                          |   |
|  |   ( ) 1 hour                                                          |   |
|  |   (x) 2 hours                                                         |   |
|  |   ( ) 4 hours                                                         |   |
|  |   ( ) Until end of day (23:59)                                        |   |
|  |                                                                       |   |
|  |   Reason for extension:                                               |   |
|  |   +-------------------------------------------------------+           |   |
|  |   | Deployment taking longer than expected. Need 2 more   |           |   |
|  |   | hours to complete testing.                            |           |   |
|  |   +-------------------------------------------------------+           |   |
|  |                                                                       |   |
|  |   [Submit Extension Request]                                          |   |
|  |                                                                       |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
+===============================================================================+
```

---

## Profile Management

### Updating Contact Information

```
+===============================================================================+
|                    PROFILE MANAGEMENT                                         |
+===============================================================================+
|                                                                               |
|  SELF-SERVICE PORTAL > PROFILE > PERSONAL INFORMATION                        |
|  ====================================================                        |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |                                                                       |   |
|  |   PERSONAL INFORMATION                                                |   |
|  |   ====================                                                |   |
|  |                                                                       |   |
|  |   +-------------------------------------------+                       |   |
|  |   |         [User Avatar]                     |                       |   |
|  |   |           J. Smith                        |                       |   |
|  |   |                                           |                       |   |
|  |   |   [Change Photo]                          |                       |   |
|  |   +-------------------------------------------+                       |   |
|  |                                                                       |   |
|  |   Username:        jsmith (read-only)                                 |   |
|  |   Employee ID:     EMP-12345 (read-only)                              |   |
|  |   Department:      Engineering (read-only)                            |   |
|  |                                                                       |   |
|  |   Display Name:                                                       |   |
|  |   +-------------------------------------------------------+           |   |
|  |   | John Smith                                            |           |   |
|  |   +-------------------------------------------------------+           |   |
|  |                                                                       |   |
|  |   Primary Email:                                                      |   |
|  |   +-------------------------------------------------------+           |   |
|  |   | jsmith@company.com                                    |           |   |
|  |   +-------------------------------------------------------+           |   |
|  |   (Changes require verification)                                      |   |
|  |                                                                       |   |
|  |   Secondary Email:                                                    |   |
|  |   +-------------------------------------------------------+           |   |
|  |   | john.smith@personal.com                               |           |   |
|  |   +-------------------------------------------------------+           |   |
|  |   (Used for recovery only)                                            |   |
|  |                                                                       |   |
|  |   Phone Number:                                                       |   |
|  |   +-------------------------------------------------------+           |   |
|  |   | +1 555-123-4567                                       |           |   |
|  |   +-------------------------------------------------------+           |   |
|  |   (Changes require SMS verification)                                  |   |
|  |                                                                       |   |
|  |   [Save Changes]                                                      |   |
|  |                                                                       |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
+===============================================================================+
```

### Language and Timezone Preferences

```
+===============================================================================+
|                    PREFERENCES                                                |
+===============================================================================+
|                                                                               |
|  SELF-SERVICE PORTAL > PROFILE > PREFERENCES                                 |
|  ===========================================                                 |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |                                                                       |   |
|  |   DISPLAY PREFERENCES                                                 |   |
|  |   ===================                                                 |   |
|  |                                                                       |   |
|  |   Language:                                                           |   |
|  |   +---------------------------+                                       |   |
|  |   | English (US)           v |                                       |   |
|  |   +---------------------------+                                       |   |
|  |   Available: English (US), English (UK), Francais, Deutsch,           |   |
|  |              Espanol, Italiano, Portugues, Japanese, Chinese          |   |
|  |                                                                       |   |
|  |   Timezone:                                                           |   |
|  |   +---------------------------+                                       |   |
|  |   | America/New_York       v |                                       |   |
|  |   +---------------------------+                                       |   |
|  |   Current time: 2026-01-28 14:35:22 EST                               |   |
|  |                                                                       |   |
|  |   Date Format:                                                        |   |
|  |   ( ) MM/DD/YYYY (01/28/2026)                                         |   |
|  |   (x) DD/MM/YYYY (28/01/2026)                                         |   |
|  |   ( ) YYYY-MM-DD (2026-01-28)                                         |   |
|  |                                                                       |   |
|  |   Time Format:                                                        |   |
|  |   ( ) 12-hour (2:35 PM)                                               |   |
|  |   (x) 24-hour (14:35)                                                 |   |
|  |                                                                       |   |
|  |   Theme:                                                              |   |
|  |   (x) Light                                                           |   |
|  |   ( ) Dark                                                            |   |
|  |   ( ) System default                                                  |   |
|  |                                                                       |   |
|  |   [Save Preferences]                                                  |   |
|  |                                                                       |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
+===============================================================================+
```

### Notification Settings

```
+===============================================================================+
|                    NOTIFICATION SETTINGS                                      |
+===============================================================================+
|                                                                               |
|  SELF-SERVICE PORTAL > PROFILE > NOTIFICATIONS                               |
|  =============================================                               |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |                                                                       |   |
|  |   NOTIFICATION CHANNELS                                               |   |
|  |   =====================                                               |   |
|  |                                                                       |   |
|  |   +-----------------------------------------------------------+       |   |
|  |   |  Event Type               | Email | SMS  | Push | Portal |       |   |
|  |   +---------------------------+-------+------+------+--------+       |   |
|  |   |  Access request approved  |  [x]  | [ ]  | [x]  |  [x]   |       |   |
|  |   |  Access request denied    |  [x]  | [x]  | [x]  |  [x]   |       |   |
|  |   |  Access expiring (30 min) |  [ ]  | [ ]  | [x]  |  [x]   |       |   |
|  |   |  Access expired           |  [x]  | [ ]  | [ ]  |  [x]   |       |   |
|  |   |  Password expiring        |  [x]  | [ ]  | [x]  |  [x]   |       |   |
|  |   |  Password changed         |  [x]  | [x]  | [x]  |  [x]   |       |   |
|  |   |  New login detected       |  [x]  | [x]  | [x]  |  [x]   |       |   |
|  |   |  MFA device added         |  [x]  | [x]  | [x]  |  [x]   |       |   |
|  |   |  Session terminated       |  [ ]  | [ ]  | [x]  |  [x]   |       |   |
|  |   |  Approval needed (approver)|  [x]  | [x]  | [x]  |  [x]   |       |   |
|  |   +---------------------------+-------+------+------+--------+       |   |
|  |                                                                       |   |
|  |   QUIET HOURS                                                         |   |
|  |   ===========                                                         |   |
|  |                                                                       |   |
|  |   [x] Enable quiet hours (no SMS/Push during these times)             |   |
|  |                                                                       |   |
|  |   Start: [22:00]  End: [07:00]                                        |   |
|  |                                                                       |   |
|  |   [ ] Except for security alerts (new login, password change)         |   |
|  |                                                                       |   |
|  |   [Save Notification Settings]                                        |   |
|  |                                                                       |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
+===============================================================================+
```

---

## Session History

### Viewing Own Session History

```
+===============================================================================+
|                    MY SESSION HISTORY                                         |
+===============================================================================+
|                                                                               |
|  SELF-SERVICE PORTAL > SESSIONS > HISTORY                                    |
|  ========================================                                    |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |  Date/Time           | Target              | Protocol | Duration | Status|  |
|  +---------------------+---------------------+----------+----------+-------+  |
|  |  2026-01-28 13:15   | prod-web-02         | SSH      | 45m 22s  | Ended |  |
|  |  2026-01-28 10:32   | prod-db-01          | RDP      | 2h 15m   | Active|  |
|  |  2026-01-27 16:45   | dev-app-01          | SSH      | 1h 05m   | Ended |  |
|  |  2026-01-27 09:18   | prod-web-01         | SSH      | 32m      | Ended |  |
|  |  2026-01-26 14:22   | staging-db          | RDP      | 3h 45m   | Ended |  |
|  +---------------------+---------------------+----------+----------+-------+  |
|                                                                               |
|  Filter:                                                                      |
|  +---------------+  +---------------+  +-------------------+                  |
|  | Last 7 days v |  | All targets v |  | All protocols  v |                  |
|  +---------------+  +---------------+  +-------------------+                  |
|                                                                               |
|  [Export to CSV]                                                              |
|                                                                               |
+===============================================================================+

Session Detail View:
===================

+-----------------------------------------------------------------------+
|                                                                       |
|  SESSION DETAILS                                                      |
|  ===============                                                      |
|                                                                       |
|  Session ID:     SES-2026012813150042                                 |
|  Target:         prod-web-02.company.com                              |
|  Protocol:       SSH                                                  |
|  Account:        appuser                                              |
|                                                                       |
|  Started:        2026-01-28 13:15:42                                  |
|  Ended:          2026-01-28 14:01:04                                  |
|  Duration:       45 minutes 22 seconds                                |
|                                                                       |
|  Source IP:      10.1.5.42                                            |
|  Client:         OpenSSH_8.9                                          |
|                                                                       |
|  Authorization:  REQ-2847 (4-hour access)                             |
|  Approval:       Auto-approved (pre-authorized)                       |
|                                                                       |
|  Recording:      Available                                            |
|  [View Recording]  [Download Recording]                               |
|                                                                       |
+-----------------------------------------------------------------------+
```

### Downloading Session Recordings

```
+===============================================================================+
|                    SESSION RECORDING ACCESS                                   |
+===============================================================================+
|                                                                               |
|  SELF-SERVICE PORTAL > SESSIONS > RECORDINGS                                 |
|  ===========================================                                 |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |                                                                       |   |
|  |   SESSION RECORDING                                                   |   |
|  |   =================                                                   |   |
|  |                                                                       |   |
|  |   Session: SES-2026012813150042                                       |   |
|  |   Target: prod-web-02.company.com                                     |   |
|  |   Date: 2026-01-28 13:15-14:01                                        |   |
|  |                                                                       |   |
|  |   +-----------------------------------------------------------+       |   |
|  |   |                                                           |       |   |
|  |   |   [Session Playback Window]                               |       |   |
|  |   |                                                           |       |   |
|  |   |   > Terminal output showing commands                      |       |   |
|  |   |   $ cd /var/www/html                                      |       |   |
|  |   |   $ ls -la                                                |       |   |
|  |   |   $ vim config.php                                        |       |   |
|  |   |                                                           |       |   |
|  |   |   [|<] [<] [||] [>] [>|]     00:15:32 / 00:45:22          |       |   |
|  |   |                                                           |       |   |
|  |   +-----------------------------------------------------------+       |   |
|  |                                                                       |   |
|  |   Playback Speed: [1x v]                                              |   |
|  |                                                                       |   |
|  |   Search Commands:                                                    |   |
|  |   +-------------------------------------------------------+           |   |
|  |   | vim                                                   |           |   |
|  |   +-------------------------------------------------------+           |   |
|  |   Found: 3 matches  [< Prev] [Next >]                                 |   |
|  |                                                                       |   |
|  |   DOWNLOAD OPTIONS (requires MFA verification):                       |   |
|  |   [ ] Video format (.mp4)                                             |   |
|  |   [x] Audit log only (.txt)                                           |   |
|  |   [ ] Full session archive (.wab)                                     |   |
|  |                                                                       |   |
|  |   [Download Selected]                                                 |   |
|  |                                                                       |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
|  NOTE: Recording downloads are logged and may require manager approval       |
|  based on organizational policy.                                             |
|                                                                               |
+===============================================================================+
```

### Activity Reports

```
+===============================================================================+
|                    MY ACTIVITY REPORT                                         |
+===============================================================================+
|                                                                               |
|  SELF-SERVICE PORTAL > SESSIONS > ACTIVITY REPORT                            |
|  ================================================                            |
|                                                                               |
|  Report Period: [2026-01-01] to [2026-01-28]  [Generate]                      |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |                                                                       |   |
|  |   SUMMARY                                                             |   |
|  |   =======                                                             |   |
|  |                                                                       |   |
|  |   Total Sessions:          47                                         |   |
|  |   Total Duration:          62 hours 35 minutes                        |   |
|  |   Unique Targets:          12                                         |   |
|  |   Access Requests:         8                                          |   |
|  |   Emergency Requests:      1                                          |   |
|  |                                                                       |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |   TOP ACCESSED TARGETS                                                |   |
|  |   ====================                                                |   |
|  |                                                                       |   |
|  |   prod-web-02.company.com      18 sessions    24h 15m                 |   |
|  |   prod-db-01.company.com       12 sessions    18h 42m                 |   |
|  |   dev-app-01.company.com        8 sessions     8h 22m                 |   |
|  |   staging-db.company.com        5 sessions     6h 10m                 |   |
|  |   prod-web-01.company.com       4 sessions     5h 06m                 |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |   ACCESS PATTERN                                                      |   |
|  |   ==============                                                      |   |
|  |                                                                       |   |
|  |   Peak hours: 09:00-11:00, 14:00-16:00                                |   |
|  |   Most active day: Wednesday                                          |   |
|  |   Average session: 1h 20m                                             |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
|  [Export Report as PDF]  [Export as CSV]                                      |
|                                                                               |
+===============================================================================+
```

---

## Credential Checkout

### Self-Service Credential Checkout

```
+===============================================================================+
|                    CREDENTIAL CHECKOUT                                        |
+===============================================================================+
|                                                                               |
|  SELF-SERVICE PORTAL > CREDENTIALS > CHECKOUT                                |
|  ============================================                                |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |                                                                       |   |
|  |   AVAILABLE CREDENTIALS                                               |   |
|  |   =====================                                               |   |
|  |                                                                       |   |
|  |   Search:                                                             |   |
|  |   +-------------------------------------------------------+           |   |
|  |   | prod                                                  |           |   |
|  |   +-------------------------------------------------------+           |   |
|  |                                                                       |   |
|  |   +-----------------------------------------------------------+       |   |
|  |   |  Account              | Target          | Status    | Action|     |   |
|  |   +-----------------------+-----------------+-----------+-------+     |   |
|  |   |  appuser              | prod-web-02     | Available | [Checkout]  |   |
|  |   |  dbadmin              | prod-db-01      | Checked Out (you)| [View]|  |
|  |   |  root                 | prod-web-01     | Locked    | -      |     |   |
|  |   |  appuser              | prod-web-03     | Available | [Checkout]  |   |
|  |   |  svc_backup           | prod-backup     | Approval  | [Request]   |   |
|  |   +-----------------------------------------------------------+       |   |
|  |                                                                       |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
|  CHECKOUT REQUEST:                                                            |
|  =================                                                            |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |                                                                       |   |
|  |   Checkout: appuser @ prod-web-02                                     |   |
|  |                                                                       |   |
|  |   Checkout Duration:                                                  |   |
|  |   +---------------------------+                                       |   |
|  |   | 4 hours                 v |                                       |   |
|  |   +---------------------------+                                       |   |
|  |   Maximum allowed: 8 hours                                            |   |
|  |                                                                       |   |
|  |   Purpose:                                                            |   |
|  |   +-------------------------------------------------------+           |   |
|  |   | Application deployment for JIRA-4521                  |           |   |
|  |   +-------------------------------------------------------+           |   |
|  |                                                                       |   |
|  |   [ ] Show password (reveal after checkout)                           |   |
|  |   [x] Copy to clipboard after checkout                                |   |
|  |                                                                       |   |
|  |   [Checkout Credential]                                               |   |
|  |                                                                       |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
+===============================================================================+
```

### Checkout Duration Management

```
+===============================================================================+
|                    ACTIVE CHECKOUTS                                           |
+===============================================================================+
|                                                                               |
|  SELF-SERVICE PORTAL > CREDENTIALS > MY CHECKOUTS                            |
|  ================================================                            |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |                                                                       |   |
|  |   CREDENTIAL CHECKED OUT                                              |   |
|  |   ======================                                              |   |
|  |                                                                       |   |
|  |   Account: dbadmin                                                    |   |
|  |   Target: prod-db-01.company.com                                      |   |
|  |   Checkout Time: 2026-01-28 10:32:15                                  |   |
|  |   Expires: 2026-01-28 14:32:15                                        |   |
|  |                                                                       |   |
|  |   Time Remaining:                                                     |   |
|  |   +-----------------------------------------------------------+       |   |
|  |   |  [===================--------]  2h 15m remaining          |       |   |
|  |   +-----------------------------------------------------------+       |   |
|  |                                                                       |   |
|  |   Password: ************************  [Show] [Copy]                   |   |
|  |                                                                       |   |
|  |   [Extend Checkout]  [Check In Now]                                   |   |
|  |                                                                       |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
|  EXTEND CHECKOUT:                                                             |
|  ================                                                             |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |                                                                       |   |
|  |   Current expiration: 2026-01-28 14:32:15 (2h 15m remaining)          |   |
|  |                                                                       |   |
|  |   Extend by:                                                          |   |
|  |   ( ) 1 hour  (until 15:32)                                           |   |
|  |   (x) 2 hours (until 16:32)                                           |   |
|  |   ( ) 4 hours (until 18:32) - requires approval                       |   |
|  |                                                                       |   |
|  |   Reason for extension:                                               |   |
|  |   +-------------------------------------------------------+           |   |
|  |   | Database migration taking longer than expected        |           |   |
|  |   +-------------------------------------------------------+           |   |
|  |                                                                       |   |
|  |   [Request Extension]                                                 |   |
|  |                                                                       |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
+===============================================================================+
```

### Check-In Procedures

```
+===============================================================================+
|                    CREDENTIAL CHECK-IN                                        |
+===============================================================================+
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |                                                                       |   |
|  |   CHECK-IN CREDENTIAL                                                 |   |
|  |   ==================                                                  |   |
|  |                                                                       |   |
|  |   Account: dbadmin @ prod-db-01                                       |   |
|  |   Checked out: 2026-01-28 10:32 (4 hours ago)                         |   |
|  |                                                                       |   |
|  |   Check-in Options:                                                   |   |
|  |   +-----------------------------------------------------------+       |   |
|  |   |                                                           |       |   |
|  |   |  [x] Rotate password after check-in                       |       |   |
|  |   |      (Recommended - ensures one-time use)                 |       |   |
|  |   |                                                           |       |   |
|  |   |  [ ] Keep current password                                |       |   |
|  |   |      (Password remains valid until next rotation)         |       |   |
|  |   |                                                           |       |   |
|  |   +-----------------------------------------------------------+       |   |
|  |                                                                       |   |
|  |   Confirm check-in notes (optional):                                  |   |
|  |   +-------------------------------------------------------+           |   |
|  |   | Migration completed successfully                      |           |   |
|  |   +-------------------------------------------------------+           |   |
|  |                                                                       |   |
|  |   [Check In]  [Cancel]                                                |   |
|  |                                                                       |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
|  CHECK-IN CONFIRMATION:                                                       |
|  ======================                                                       |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |                                                                       |   |
|  |   Credential successfully checked in.                                 |   |
|  |                                                                       |   |
|  |   Account: dbadmin @ prod-db-01                                       |   |
|  |   Duration: 4 hours 12 minutes                                        |   |
|  |   Password: Rotated successfully                                      |   |
|  |                                                                       |   |
|  |   [Done]                                                              |   |
|  |                                                                       |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
+===============================================================================+
```

---

## Emergency Access Request

### Break-Glass Request Workflow

```
+===============================================================================+
|                    EMERGENCY ACCESS REQUEST                                   |
+===============================================================================+
|                                                                               |
|  SELF-SERVICE PORTAL > ACCESS > EMERGENCY REQUEST                            |
|  ================================================                            |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |                                                                       |   |
|  |   EMERGENCY / BREAK-GLASS ACCESS                                      |   |
|  |   ==============================                                      |   |
|  |                                                                       |   |
|  |   WARNING: Emergency access requests are for critical situations      |   |
|  |   only. All emergency access is:                                      |   |
|  |                                                                       |   |
|  |   * Logged with enhanced audit detail                                 |   |
|  |   * Subject to post-access review                                     |   |
|  |   * Reported to security team automatically                           |   |
|  |   * Time-limited (maximum 4 hours)                                    |   |
|  |                                                                       |   |
|  |   +-----------------------+                                           |   |
|  |   |  [!] I understand and |                                           |   |
|  |   |  need to proceed      |                                           |   |
|  |   +-----------------------+                                           |   |
|  |                                                                       |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
|  EMERGENCY REQUEST FORM:                                                      |
|  =======================                                                      |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |                                                                       |   |
|  |   Emergency Type: *                                                   |   |
|  |   +---------------------------+                                       |   |
|  |   | Production Outage       v |                                       |   |
|  |   +---------------------------+                                       |   |
|  |   Options: Production Outage, Security Incident, Customer Impact,     |   |
|  |            Data Recovery, Compliance Audit, Other Critical            |   |
|  |                                                                       |   |
|  |   Target System: *                                                    |   |
|  |   +-------------------------------------------------------+           |   |
|  |   | prod-db-master.company.com                            |           |   |
|  |   +-------------------------------------------------------+           |   |
|  |                                                                       |   |
|  |   Account Level: *                                                    |   |
|  |   ( ) Application (standard privileges)                               |   |
|  |   (x) Administrator (elevated privileges)                             |   |
|  |   ( ) Root/System (highest privileges)                                |   |
|  |                                                                       |   |
|  |   Incident/Ticket Number: *                                           |   |
|  |   +-------------------------------------------------------+           |   |
|  |   | INC-2026-0128-001                                     |           |   |
|  |   +-------------------------------------------------------+           |   |
|  |                                                                       |   |
|  |   Detailed Justification: * (minimum 50 characters)                   |   |
|  |   +-------------------------------------------------------+           |   |
|  |   | Production database master is unresponsive. Customer  |           |   |
|  |   | transactions are failing. Need immediate access to    |           |   |
|  |   | diagnose and restore service. Estimated impact: 500   |           |   |
|  |   | users affected. On-call DBA unavailable.              |           |   |
|  |   +-------------------------------------------------------+           |   |
|  |                                                                       |   |
|  |   Duration Requested:                                                 |   |
|  |   +---------------------------+                                       |   |
|  |   | 2 hours                 v |                                       |   |
|  |   +---------------------------+                                       |   |
|  |   Options: 1h, 2h, 4h (maximum)                                       |   |
|  |                                                                       |   |
|  |   Contact Phone (for callback verification):                          |   |
|  |   +-------------------------------------------------------+           |   |
|  |   | +1 555-123-4567                                       |           |   |
|  |   +-------------------------------------------------------+           |   |
|  |                                                                       |   |
|  |   [Submit Emergency Request]                                          |   |
|  |                                                                       |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
+===============================================================================+
```

### Justification Requirements

```
+===============================================================================+
|                    EMERGENCY ACCESS JUSTIFICATION                             |
+===============================================================================+
|                                                                               |
|  REQUIRED INFORMATION:                                                        |
|  =====================                                                        |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |                                                                       |   |
|  |  1. INCIDENT IDENTIFICATION                                           |   |
|  |     * Valid incident/ticket number from ITSM system                   |   |
|  |     * Cross-referenced automatically with ServiceNow/Jira             |   |
|  |                                                                       |   |
|  |  2. BUSINESS IMPACT                                                   |   |
|  |     * Affected users/customers count                                  |   |
|  |     * Revenue/operational impact                                      |   |
|  |     * Compliance implications                                         |   |
|  |                                                                       |   |
|  |  3. WHY STANDARD ACCESS IS INSUFFICIENT                               |   |
|  |     * Normal approval chain unavailable                               |   |
|  |     * Time-critical nature of issue                                   |   |
|  |     * Escalation attempts made                                        |   |
|  |                                                                       |   |
|  |  4. PLANNED ACTIONS                                                   |   |
|  |     * Specific tasks to be performed                                  |   |
|  |     * Expected resolution steps                                       |   |
|  |                                                                       |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
|  VALIDATION RULES:                                                            |
|  =================                                                            |
|                                                                               |
|  * Minimum 50 characters in justification                                     |
|  * Incident number must match pattern (INC-YYYY-MMDD-NNN)                     |
|  * Phone number must be verifiable contact                                    |
|  * User must have at least one previous standard access to system type        |
|                                                                               |
+===============================================================================+
```

### Expedited Approval

```
+===============================================================================+
|                    EMERGENCY APPROVAL WORKFLOW                                |
+===============================================================================+
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |                                                                       |   |
|  |  EMERGENCY REQUEST: EMR-2026-0128-001                                 |   |
|  |  Status: AWAITING APPROVAL                                            |   |
|  |                                                                       |   |
|  |  +-----------------------------------------------------------+       |   |
|  |  |  EXPEDITED APPROVAL CHAIN                                 |       |   |
|  |  +-----------------------------------------------------------+       |   |
|  |  |                                                           |       |   |
|  |  |  Step 1: Security On-Call (REQUIRED)                      |       |   |
|  |  |  ================================                         |       |   |
|  |  |  Approver: Security Team On-Call                          |       |   |
|  |  |  Status: APPROVED (auto - policy match)                   |       |   |
|  |  |  Time: 2026-01-28 15:02:15 (2 seconds)                    |       |   |
|  |  |                                                           |       |   |
|  |  |  Step 2: Manager Notification (PARALLEL)                  |       |   |
|  |  |  =======================================                  |       |   |
|  |  |  Notified: Mary Johnson (manager)                         |       |   |
|  |  |  Status: Acknowledged via SMS                             |       |   |
|  |  |  Time: 2026-01-28 15:02:45                                |       |   |
|  |  |                                                           |       |   |
|  |  +-----------------------------------------------------------+       |   |
|  |                                                                       |   |
|  |  ACCESS GRANTED                                                       |   |
|  |  ==============                                                       |   |
|  |                                                                       |   |
|  |  Target: prod-db-master.company.com                                   |   |
|  |  Account: dbadmin (Administrator)                                     |   |
|  |  Valid Until: 2026-01-28 17:02:15 (2 hours)                           |   |
|  |                                                                       |   |
|  |  [Launch Session]  [View Credentials]                                 |   |
|  |                                                                       |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
|  POST-ACCESS REQUIREMENTS:                                                    |
|  =========================                                                    |
|                                                                               |
|  * Incident report required within 24 hours                                   |
|  * Session recording review by security team                                  |
|  * Manager sign-off on actions taken                                          |
|                                                                               |
+===============================================================================+
```

---

## Mobile Access

### Mobile App Enrollment

```
+===============================================================================+
|                    MOBILE APP ENROLLMENT                                      |
+===============================================================================+
|                                                                               |
|  SELF-SERVICE PORTAL > MOBILE > ENROLL DEVICE                                |
|  ============================================                                |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |                                                                       |   |
|  |   WALLIX AUTHENTICATOR APP                                            |   |
|  |   ========================                                            |   |
|  |                                                                       |   |
|  |   Step 1: Download the App                                            |   |
|  |   ========================                                            |   |
|  |                                                                       |   |
|  |   +------------------+    +------------------+                        |   |
|  |   | [App Store]      |    | [Google Play]    |                        |   |
|  |   | Download for iOS |    | Download for     |                        |   |
|  |   |                  |    | Android          |                        |   |
|  |   +------------------+    +------------------+                        |   |
|  |                                                                       |   |
|  |   Step 2: Scan Enrollment QR Code                                     |   |
|  |   ================================                                    |   |
|  |                                                                       |   |
|  |              +----------------------------+                           |   |
|  |              |   [QR CODE IMAGE]          |                           |   |
|  |              |                            |                           |   |
|  |              |   Valid for: 10 minutes    |                           |   |
|  |              |                            |                           |   |
|  |              +----------------------------+                           |   |
|  |                                                                       |   |
|  |   Or enter manually:                                                  |   |
|  |   Server: bastion.company.com                                         |   |
|  |   Code: WXYZ-1234-ABCD-5678                                           |   |
|  |                                                                       |   |
|  |   Step 3: Verify Enrollment                                           |   |
|  |   =========================                                           |   |
|  |                                                                       |   |
|  |   Enter the code shown in the app:                                    |   |
|  |   +----+ +----+ +----+ +----+ +----+ +----+                           |   |
|  |   |    | |    | |    | |    | |    | |    |                           |   |
|  |   +----+ +----+ +----+ +----+ +----+ +----+                           |   |
|  |                                                                       |   |
|  |   [Verify]                                                            |   |
|  |                                                                       |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
+===============================================================================+
```

### Push Notification Setup

```
+===============================================================================+
|                    PUSH NOTIFICATION CONFIGURATION                            |
+===============================================================================+
|                                                                               |
|  SELF-SERVICE PORTAL > MOBILE > NOTIFICATIONS                                |
|  ============================================                                |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |                                                                       |   |
|  |   ENROLLED DEVICES                                                    |   |
|  |   ================                                                    |   |
|  |                                                                       |   |
|  |   +-----------------------------------------------------------+       |   |
|  |   |  Device           | OS       | Enrolled    | Push  | Action|      |   |
|  |   +-------------------+----------+-------------+-------+-------+      |   |
|  |   |  iPhone 14 Pro    | iOS 17.2 | 2026-01-15 | Active| [Remove]     |   |
|  |   |  Samsung Galaxy   | And 14   | 2025-12-01 | Active| [Remove]     |   |
|  |   +-----------------------------------------------------------+       |   |
|  |                                                                       |   |
|  |   PUSH AUTHENTICATION SETTINGS                                        |   |
|  |   ============================                                        |   |
|  |                                                                       |   |
|  |   [x] Enable push authentication                                      |   |
|  |       Receive push notifications for login approval                   |   |
|  |                                                                       |   |
|  |   [x] Require biometric to approve                                    |   |
|  |       Face ID / Touch ID / Fingerprint required                       |   |
|  |                                                                       |   |
|  |   [ ] Allow offline approval (with cached credentials)                |   |
|  |       Approve requests even without internet                          |   |
|  |                                                                       |   |
|  |   Notification timeout:                                               |   |
|  |   +---------------------------+                                       |   |
|  |   | 60 seconds             v |                                       |   |
|  |   +---------------------------+                                       |   |
|  |                                                                       |   |
|  |   [Save Push Settings]                                                |   |
|  |                                                                       |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
|  TEST PUSH NOTIFICATION:                                                      |
|  =======================                                                      |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |                                                                       |   |
|  |   Send a test push notification to verify setup:                      |   |
|  |                                                                       |   |
|  |   Device: [iPhone 14 Pro     v]                                       |   |
|  |                                                                       |   |
|  |   [Send Test Notification]                                            |   |
|  |                                                                       |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
+===============================================================================+
```

### Offline Access Configuration

```
+===============================================================================+
|                    OFFLINE ACCESS SETTINGS                                    |
+===============================================================================+
|                                                                               |
|  SELF-SERVICE PORTAL > MOBILE > OFFLINE ACCESS                               |
|  =============================================                               |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |                                                                       |   |
|  |   OFFLINE CREDENTIAL CACHE                                            |   |
|  |   ========================                                            |   |
|  |                                                                       |   |
|  |   Enable offline access for situations without network connectivity.  |   |
|  |   Credentials are encrypted and stored securely on device.            |   |
|  |                                                                       |   |
|  |   [x] Enable offline credential cache                                 |   |
|  |                                                                       |   |
|  |   Maximum offline duration:                                           |   |
|  |   +---------------------------+                                       |   |
|  |   | 24 hours               v |                                       |   |
|  |   +---------------------------+                                       |   |
|  |   Options: 4h, 8h, 24h, 72h (requires approval)                       |   |
|  |                                                                       |   |
|  |   CACHED CREDENTIALS:                                                 |   |
|  |   ===================                                                 |   |
|  |                                                                       |   |
|  |   +-----------------------------------------------------------+       |   |
|  |   |  Account           | Target          | Cached Until  |     |       |   |
|  |   +--------------------+-----------------+---------------+     |       |   |
|  |   |  appuser           | prod-web-02     | 2026-01-29 14:00   |       |   |
|  |   |  operator          | plc-zone3-01    | 2026-01-29 14:00   |       |   |
|  |   +-----------------------------------------------------------+       |   |
|  |                                                                       |   |
|  |   [Refresh Cache Now]  [Clear Cache]                                  |   |
|  |                                                                       |   |
|  |   Last sync: 2026-01-28 14:00:00                                      |   |
|  |   Next auto-sync: 2026-01-28 18:00:00                                 |   |
|  |                                                                       |   |
|  |   SECURITY REQUIREMENTS FOR OFFLINE ACCESS:                           |   |
|  |   ========================================                            |   |
|  |                                                                       |   |
|  |   [x] Device must have screen lock enabled                            |   |
|  |   [x] Device must have disk encryption                                |   |
|  |   [x] Biometric required to access cached credentials                 |   |
|  |   [x] Credentials purged on device wipe detection                     |   |
|  |                                                                       |   |
|  |   [Save Offline Settings]                                             |   |
|  |                                                                       |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
+===============================================================================+
```

---

## Configuration

### Enabling Self-Service Features

```
+===============================================================================+
|                    SELF-SERVICE CONFIGURATION                                 |
+===============================================================================+
|                                                                               |
|  ADMIN CONSOLE > CONFIGURATION > SELF-SERVICE                                |
|  ============================================                                |
|                                                                               |
|  Feature Toggles:                                                             |
|  ================                                                             |

{
    "self_service": {
        "enabled": true,
        "portal_url": "/selfservice",

        "features": {
            "password_reset": {
                "enabled": true,
                "require_email_verification": true,
                "require_sms_verification": false,
                "allow_security_questions": false,
                "max_attempts_per_hour": 3,
                "lockout_duration_minutes": 30
            },

            "password_change": {
                "enabled": true,
                "require_current_password": true,
                "require_mfa": true,
                "enforce_policy": true,
                "logout_other_sessions": true
            },

            "mfa_enrollment": {
                "enabled": true,
                "allowed_types": ["totp", "fido2", "push"],
                "require_mfa_to_enroll": true,
                "max_devices_per_type": 3,
                "require_backup_codes": true
            },

            "access_requests": {
                "enabled": true,
                "require_justification": true,
                "min_justification_length": 20,
                "max_pending_requests": 10,
                "allow_emergency_requests": true,
                "emergency_max_duration_hours": 4
            },

            "session_history": {
                "enabled": true,
                "allow_recording_playback": true,
                "allow_recording_download": false,
                "require_mfa_for_download": true,
                "history_retention_days": 90
            },

            "credential_checkout": {
                "enabled": true,
                "allow_self_checkout": true,
                "max_checkout_hours": 8,
                "rotate_on_checkin": true
            },

            "profile_management": {
                "enabled": true,
                "allow_email_change": true,
                "require_email_verification": true,
                "allow_phone_change": true,
                "require_phone_verification": true
            },

            "mobile_access": {
                "enabled": true,
                "allow_push_auth": true,
                "allow_offline_cache": true,
                "max_offline_hours": 24
            }
        }
    }
}
```

### Customizing Portal Appearance

```
+===============================================================================+
|                    PORTAL CUSTOMIZATION                                       |
+===============================================================================+
|                                                                               |
|  ADMIN CONSOLE > CONFIGURATION > PORTAL BRANDING                             |
|  ===============================================                             |

{
    "branding": {
        "organization_name": "ACME Corporation",
        "portal_title": "ACME Privileged Access Portal",

        "logo": {
            "main_logo": "/custom/logo-main.png",
            "favicon": "/custom/favicon.ico",
            "login_logo": "/custom/logo-login.png"
        },

        "colors": {
            "primary": "#1a5276",
            "secondary": "#2e86c1",
            "accent": "#28b463",
            "danger": "#e74c3c",
            "background": "#f8f9fa",
            "text": "#2c3e50"
        },

        "login_page": {
            "background_image": "/custom/login-bg.jpg",
            "welcome_message": "Welcome to ACME Privileged Access Portal",
            "help_text": "Contact IT Helpdesk at x4357 for assistance",
            "show_forgot_password": true,
            "show_self_register": false
        },

        "portal_page": {
            "show_quick_actions": true,
            "show_recent_sessions": true,
            "show_pending_requests": true,
            "custom_footer": "ACME Corporation - IT Security",
            "privacy_policy_url": "https://acme.com/privacy",
            "terms_url": "https://acme.com/terms"
        },

        "notifications": {
            "email_from": "pam@acme.com",
            "email_from_name": "ACME PAM System",
            "email_template": "/custom/email-template.html"
        }
    }
}
```

### Feature Toggles by User Group

```
+===============================================================================+
|                    GROUP-BASED FEATURE ACCESS                                 |
+===============================================================================+

{
    "self_service_policies": [
        {
            "name": "standard-users",
            "groups": ["Domain Users"],
            "features": {
                "password_reset": true,
                "password_change": true,
                "mfa_enrollment": true,
                "access_requests": true,
                "emergency_requests": false,
                "session_history": true,
                "recording_playback": false,
                "credential_checkout": false,
                "mobile_access": true,
                "offline_cache": false
            }
        },
        {
            "name": "privileged-users",
            "groups": ["IT-Admins", "Database-Admins"],
            "features": {
                "password_reset": true,
                "password_change": true,
                "mfa_enrollment": true,
                "access_requests": true,
                "emergency_requests": true,
                "session_history": true,
                "recording_playback": true,
                "credential_checkout": true,
                "mobile_access": true,
                "offline_cache": true
            }
        },
        {
            "name": "contractors",
            "groups": ["External-Vendors"],
            "features": {
                "password_reset": false,
                "password_change": true,
                "mfa_enrollment": true,
                "access_requests": true,
                "emergency_requests": false,
                "session_history": true,
                "recording_playback": false,
                "credential_checkout": false,
                "mobile_access": false,
                "offline_cache": false
            }
        }
    ]
}
```

---

## Troubleshooting

### Login Issues

```
+===============================================================================+
|                    LOGIN TROUBLESHOOTING                                      |
+===============================================================================+
|                                                                               |
|  ISSUE: Cannot Access Self-Service Portal                                     |
|  ========================================                                     |
|                                                                               |
|  Symptoms:                                                                    |
|  * "Access Denied" message on portal URL                                      |
|  * Redirect to corporate login but portal not loading                         |
|                                                                               |
|  Checks:                                                                      |
|  [ ] Verify self-service is enabled in admin console                          |
|  [ ] Check user is member of allowed groups                                   |
|  [ ] Verify portal URL is correct (/selfservice)                              |
|  [ ] Check browser cache/cookies - try incognito mode                         |
|  [ ] Verify SSL certificate is valid and trusted                              |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  ISSUE: Password Reset Link Not Received                                      |
|  =======================================                                      |
|                                                                               |
|  Symptoms:                                                                    |
|  * No email received after requesting password reset                          |
|  * No SMS received for verification code                                      |
|                                                                               |
|  Checks:                                                                      |
|  [ ] Verify email address is correct in user profile                          |
|  [ ] Check spam/junk folder                                                   |
|  [ ] Verify SMTP server configuration in admin console                        |
|  [ ] Check rate limiting (max 3 attempts per hour)                            |
|  [ ] Verify SMS gateway configuration if using SMS                            |
|                                                                               |
|  Admin Commands:                                                              |

# Check SMTP configuration
wabadmin config smtp --test

# View password reset attempts
wabadmin audit --filter "password_reset" --user jsmith --last 10

# Check email delivery queue
wabadmin email-queue --status

|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  ISSUE: Account Locked After Failed Attempts                                  |
|  ===========================================                                  |
|                                                                               |
|  Symptoms:                                                                    |
|  * "Account temporarily locked" message                                       |
|  * Cannot attempt password reset                                              |
|                                                                               |
|  Resolution:                                                                  |
|  [ ] Wait for lockout period (default 30 minutes)                             |
|  [ ] Contact helpdesk for manual unlock                                       |
|  [ ] Admin can unlock via: wabadmin user unlock --username jsmith             |
|                                                                               |
+===============================================================================+
```

### MFA Problems

```
+===============================================================================+
|                    MFA TROUBLESHOOTING                                        |
+===============================================================================+
|                                                                               |
|  ISSUE: TOTP Codes Not Working                                                |
|  =============================                                                |
|                                                                               |
|  Symptoms:                                                                    |
|  * "Invalid code" message when entering TOTP                                  |
|  * Code accepted but then fails                                               |
|                                                                               |
|  Checks:                                                                      |
|  [ ] Verify device time is synchronized (NTP)                                 |
|  [ ] Check time zone settings on device                                       |
|  [ ] Try next code (codes change every 30 seconds)                            |
|  [ ] Re-enroll TOTP if persistent issue                                       |
|                                                                               |
|  Time Sync Commands:                                                          |

# Check server time
date
timedatectl status

# Force NTP sync
timedatectl set-ntp true

|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  ISSUE: FortiToken FortiToken Not Recognized                                     |
|  ========================================                                     |
|                                                                               |
|  Symptoms:                                                                    |
|  * Browser not detecting FortiToken                                         |
|  * "No FortiToken found" error                                              |
|  * Key blinks but authentication fails                                        |
|                                                                               |
|  Checks:                                                                      |
|  [ ] Verify browser supports FortiToken (Chrome 67+, Firefox 60+, Edge 79+)     |
|  [ ] Try different USB port                                                   |
|  [ ] Check if key requires PIN setup first                                    |
|  [ ] Verify key is registered for this account                                |
|  [ ] Try NFC if key supports it (hold to phone)                               |
|                                                                               |
|  Browser Console Check:                                                       |

# Open browser developer console (F12) and run:
navigator.credentials.get({publicKey: {challenge: new Uint8Array(32)}})
# Should prompt for FortiToken if FortiToken is working

|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  ISSUE: Lost All MFA Devices                                                  |
|  ===========================                                                  |
|                                                                               |
|  Recovery Options (in order of preference):                                   |
|                                                                               |
|  1. Use backup codes (if previously generated)                                |
|  2. Manager-assisted recovery (manager approves reset)                        |
|  3. Helpdesk verification (answer security questions in person/video)         |
|  4. Admin manual MFA reset (last resort)                                      |
|                                                                               |
|  Admin MFA Reset:                                                             |

# List user's MFA devices
wabadmin user mfa --list --username jsmith

# Remove specific MFA device
wabadmin user mfa --remove --username jsmith --device-id <device_id>

# Reset all MFA (requires re-enrollment)
wabadmin user mfa --reset --username jsmith --force

|                                                                               |
+===============================================================================+
```

### Access Request Failures

```
+===============================================================================+
|                    ACCESS REQUEST TROUBLESHOOTING                             |
+===============================================================================+
|                                                                               |
|  ISSUE: Request Stuck in Pending Status                                       |
|  ======================================                                       |
|                                                                               |
|  Symptoms:                                                                    |
|  * Request shows "Pending" for extended time                                  |
|  * No notification to approvers                                               |
|                                                                               |
|  Checks:                                                                      |
|  [ ] Verify approvers are configured for the resource                         |
|  [ ] Check approver availability (vacation, disabled account)                 |
|  [ ] Verify email notifications are being sent                                |
|  [ ] Check approval workflow configuration                                    |
|                                                                               |
|  Admin Commands:                                                              |

# View pending requests
wabadmin approval --list --status pending

# Check approval chain for resource
wabadmin authorization --resource "prod-web-02" --show-approvers

# Manually process stuck request
wabadmin approval --request REQ-2845 --expedite

|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  ISSUE: Request Denied Without Clear Reason                                   |
|  ==========================================                                   |
|                                                                               |
|  Checks:                                                                      |
|  [ ] Review denial reason in request details                                  |
|  [ ] Check if user has required group memberships                             |
|  [ ] Verify resource is available (not disabled/maintenance)                  |
|  [ ] Check time-based access windows                                          |
|                                                                               |
|  Common Denial Reasons:                                                       |
|  * User not in authorized group for resource                                  |
|  * Request outside allowed time window                                        |
|  * Maximum concurrent users exceeded                                          |
|  * Account already checked out exclusively                                    |
|  * Insufficient justification provided                                        |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  ISSUE: Emergency Request Not Expedited                                       |
|  ======================================                                       |
|                                                                               |
|  Symptoms:                                                                    |
|  * Emergency request following normal approval chain                          |
|  * No expedited processing despite urgency                                    |
|                                                                               |
|  Checks:                                                                      |
|  [ ] Verify emergency requests are enabled for user's group                   |
|  [ ] Check emergency type selection is valid                                  |
|  [ ] Verify incident ticket number format is correct                          |
|  [ ] Ensure security on-call escalation is configured                         |
|                                                                               |
|  Emergency Request Requirements:                                              |
|  * Valid incident ticket number (auto-validated against ITSM)                 |
|  * Minimum justification length (50+ characters)                              |
|  * User has previous access to similar resource type                          |
|  * Emergency feature enabled for user's group                                 |
|                                                                               |
+===============================================================================+
```

### Common Error Messages

```
+===============================================================================+
|                    ERROR MESSAGE REFERENCE                                    |
+===============================================================================+
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |  Error Message               | Cause           | Resolution           |   |
|  +------------------------------+-----------------+----------------------+   |
|  |  "Session expired"           | Idle timeout    | Re-authenticate      |   |
|  |  "Invalid verification code" | Wrong/expired   | Request new code     |   |
|  |  "Account locked"            | Too many fails  | Wait or contact help |   |
|  |  "Password policy violation" | Doesn't meet    | Review requirements  |   |
|  |  "MFA required"              | No MFA enrolled | Enroll MFA device    |   |
|  |  "Access denied"             | No permission   | Request access       |   |
|  |  "Resource unavailable"      | Maintenance     | Try later            |   |
|  |  "Checkout limit reached"    | Max checkouts   | Check in existing    |   |
|  |  "Approval required"         | Needs approval  | Wait for approval    |   |
|  |  "Rate limit exceeded"       | Too many reqs   | Wait and retry       |   |
|  +------------------------------+-----------------+----------------------+   |
|                                                                               |
+===============================================================================+
```

---

## API Reference

### Self-Service API Endpoints

```
+===============================================================================+
|                    SELF-SERVICE API                                           |
+===============================================================================+

# Password Management
POST /api/v1/selfservice/password/change
POST /api/v1/selfservice/password/reset/request
POST /api/v1/selfservice/password/reset/verify
POST /api/v1/selfservice/password/reset/complete

# MFA Management
GET  /api/v1/selfservice/mfa/devices
POST /api/v1/selfservice/mfa/totp/enroll
POST /api/v1/selfservice/mfa/totp/verify
POST /api/v1/selfservice/mfa/fido2/enroll
POST /api/v1/selfservice/mfa/fido2/verify
DELETE /api/v1/selfservice/mfa/devices/{device_id}
POST /api/v1/selfservice/mfa/backup-codes/generate
GET  /api/v1/selfservice/mfa/backup-codes

# Access Requests
GET  /api/v1/selfservice/access/requests
POST /api/v1/selfservice/access/requests
GET  /api/v1/selfservice/access/requests/{request_id}
DELETE /api/v1/selfservice/access/requests/{request_id}
POST /api/v1/selfservice/access/emergency

# Profile Management
GET  /api/v1/selfservice/profile
PATCH /api/v1/selfservice/profile
GET  /api/v1/selfservice/preferences
PATCH /api/v1/selfservice/preferences
GET  /api/v1/selfservice/notifications
PATCH /api/v1/selfservice/notifications

# Session History
GET  /api/v1/selfservice/sessions
GET  /api/v1/selfservice/sessions/{session_id}
GET  /api/v1/selfservice/sessions/{session_id}/recording
GET  /api/v1/selfservice/activity-report

# Credential Checkout
GET  /api/v1/selfservice/credentials/available
POST /api/v1/selfservice/credentials/checkout
POST /api/v1/selfservice/credentials/checkin
POST /api/v1/selfservice/credentials/extend
```

### Example API Calls

```bash
# Request access to a resource
curl -X POST "https://bastion.company.com/api/v1/selfservice/access/requests" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "resource": "prod-web-02.company.com",
    "account_type": "standard",
    "duration_hours": 4,
    "justification": "Deploy hotfix for JIRA-4521",
    "ticket": "JIRA-4521"
  }'

# Checkout credential
curl -X POST "https://bastion.company.com/api/v1/selfservice/credentials/checkout" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "account": "appuser",
    "target": "prod-web-02",
    "duration_hours": 4,
    "purpose": "Application deployment"
  }'

# Get session history
curl -X GET "https://bastion.company.com/api/v1/selfservice/sessions?days=7" \
  -H "Authorization: Bearer $TOKEN"
```

---

## Related Documentation

| Document | Description |
|----------|-------------|
| [Authentication](../06-authentication/README.md) | Authentication methods and MFA configuration |
| [Authorization](../07-authorization/README.md) | RBAC and approval workflows |
| [Password Management](../08-password-management/README.md) | Credential vault and rotation |
| [Session Management](../09-session-management/README.md) | Session recording and monitoring |
| [FortiToken Hardware MFA](../40-fido2-hardware-mfa/README.md) | Hardware token configuration |
| [JIT Access](../25-jit-access/README.md) | Just-in-time access workflows |

---

## External References

| Resource | URL |
|----------|-----|
| WALLIX Documentation Portal | https://pam.wallix.one/documentation |
| WALLIX User Guide | https://pam.wallix.one/documentation/user-doc/bastion_en_user_guide.pdf |
| WALLIX Admin Guide | https://pam.wallix.one/documentation/admin-doc/bastion_en_administration_guide.pdf |
| FortiToken Specification | https://www.w3.org/TR/webauthn-2/ |
| FIDO Alliance | https://fidoalliance.org/ |

---

## Next Steps

Continue to [Authorization](../07-authorization/README.md) for detailed RBAC configuration and approval workflow setup.
