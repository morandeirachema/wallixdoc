# 07 - Password Management

## Table of Contents

1. [Password Management Overview](#password-management-overview)
2. [Credential Vault](#credential-vault)
3. [Password Policies](#password-policies)
4. [Automatic Rotation](#automatic-rotation)
5. [Target Connectors](#target-connectors)
6. [Checkout Workflows](#checkout-workflows)
7. [SSH Key Management](#ssh-key-management)
8. [Troubleshooting Rotation](#troubleshooting-rotation)

---

## Password Management Overview

### Architecture

```
+===============================================================================+
|                   PASSWORD MANAGEMENT ARCHITECTURE                            |
+===============================================================================+
|                                                                               |
|                        +-----------------------------+                        |
|                        |      CREDENTIAL VAULT       |                        |
|                        |                             |                        |
|                        |  +---------------------+    |                        |
|                        |  |   Encrypted Store   |    |                        |
|                        |  |   (AES-256-GCM)     |    |                        |
|                        |  +---------------------+    |                        |
|                        |                             |                        |
|                        |  +---------------------+    |                        |
|                        |  |   Master Key        |    |                        |
|                        |  |   (HSM optional)    |    |                        |
|                        |  +---------------------+    |                        |
|                        |                             |                        |
|                        +--------------+--------------+                        |
|                                       |                                       |
|           +---------------------------+---------------------------+           |
|           |                           |                           |           |
|           v                           v                           v           |
|  +-----------------+       +-----------------+       +-----------------+      |
|  |    ROTATION     |       |    INJECTION    |       |    CHECKOUT     |      |
|  |    ENGINE       |       |    ENGINE       |       |    WORKFLOW     |      |
|  |                 |       |                 |       |                 |      |
|  | * Scheduled     |       | * Transparent   |       | * Request       |      |
|  | * On-demand     |       | * Just-in-time  |       | * Approval      |      |
|  | * Post-session  |       | * Protocol-aware|       | * Time-limited  |      |
|  | * Verification  |       |                 |       | * Audit trail   |      |
|  +--------+--------+       +-----------------+       +-----------------+      |
|           |                                                                   |
|           v                                                                   |
|  +-----------------------------------------------------------------------+    |
|  |                      TARGET CONNECTORS                                |    |
|  |                                                                       |    |
|  |  +----------+ +----------+ +----------+ +----------+ +----------+     |    |
|  |  | Windows  | |  Linux   | | Network  | | Database | |  Custom  |     |    |
|  |  |          | |  Unix    | | Devices  | |          | |  Scripts |     |    |
|  |  +----------+ +----------+ +----------+ +----------+ +----------+     |    |
|  |                                                                       |    |
|  +-----------------------------------------------------------------------+    |
|                                                                               |
+===============================================================================+
```

### CyberArk Comparison

| CyberArk | WALLIX | Notes |
|----------|--------|-------|
| Digital Vault | Credential Vault | Encrypted storage |
| CPM | Password Manager | Rotation engine |
| Platform | Target Connector | Target type definition |
| CPM Plugin | Change Plugin | Custom rotation logic |
| Reconciliation | Reconciliation | Recovery mechanism |

---

## Credential Vault

### Storage Security

```
+===============================================================================+
|                        CREDENTIAL STORAGE SECURITY                            |
+===============================================================================+
|                                                                               |
|  ENCRYPTION LAYERS                                                            |
|  =================                                                            |
|                                                                               |
|  +-----------------------------------------------------------------------+    |
|  |  Layer 1: Database Encryption                                         |    |
|  |  -----------------------------                                        |    |
|  |  * MariaDB with encryption at rest                                    |    |
|  |  * Encrypted tablespaces                                              |    |
|  +-----------------------------------------------------------------------+    |
|                                       |                                       |
|                                       v                                       |
|  +-----------------------------------------------------------------------+    |
|  |  Layer 2: Credential Encryption                                       |    |
|  |  ------------------------------                                       |    |
|  |  * AES-256-GCM per credential                                         |    |
|  |  * Unique IV per encryption                                           |    |
|  +-----------------------------------------------------------------------+    |
|                                       |                                       |
|                                       v                                       |
|  +-----------------------------------------------------------------------+    |
|  |  Layer 3: Master Key Protection                                       |    |
|  |  ------------------------------                                       |    |
|  |  * Software protection (default)                                      |    |
|  |  * HSM integration (optional)                                         |    |
|  |  * Key ceremony for initial setup                                     |    |
|  +-----------------------------------------------------------------------+    |
|                                                                               |
+===============================================================================+
```

### Credential Types

| Type | Storage | Rotation Support | Use Case |
|------|---------|------------------|----------|
| Password | Encrypted string | Yes | Standard accounts |
| SSH Key | Encrypted key pair | Yes | Linux/Unix/Network |
| Certificate | X.509 + private key | Limited | PKI authentication |
| API Key | Encrypted token | Manual | Service integration |

---

## Password Policies

### Policy Configuration

```
+===============================================================================+
|                       PASSWORD POLICY CONFIGURATION                           |
+===============================================================================+
|                                                                               |
|  COMPLEXITY REQUIREMENTS                                                      |
|  =======================                                                      |
|                                                                               |
|  {                                                                            |
|      "policy_name": "high-security",                                          |
|      "description": "Policy for privileged accounts",                         |
|                                                                               |
|      "length": {                                                              |
|          "minimum": 20,                                                       |
|          "maximum": 64                                                        |
|      },                                                                       |
|                                                                               |
|      "complexity": {                                                          |
|          "uppercase_minimum": 2,                                              |
|          "lowercase_minimum": 2,                                              |
|          "digit_minimum": 2,                                                  |
|          "special_minimum": 2,                                                |
|          "special_characters": "!@#$%^&*()_+-=[]{}|;:,.<>?"                   |
|      },                                                                       |
|                                                                               |
|      "restrictions": {                                                        |
|          "no_username": true,                                                 |
|          "no_dictionary_words": true,                                         |
|          "no_sequential": true,                                               |
|          "no_repeated_chars": 3                                               |
|      },                                                                       |
|                                                                               |
|      "history": {                                                             |
|          "remember_count": 24                                                 |
|      }                                                                        |
|  }                                                                            |
|                                                                               |
+===============================================================================+
```

### Policy Templates

```
+===============================================================================+
|                        POLICY TEMPLATES BY USE CASE                           |
+===============================================================================+
|                                                                               |
|  +-----------------+------------+------------+------------+------------+      |
|  | Setting         | Standard   | High       | Network    | Service    |      |
|  |                 |            | Security   | Device     | Account    |      |
|  +-----------------+------------+------------+------------+------------+      |
|  | Min Length      | 14         | 20         | 16         | 24         |      |
|  | Max Length      | 32         | 64         | 32         | 64         |      |
|  | Uppercase       | 1          | 2          | 1          | 2          |      |
|  | Lowercase       | 1          | 2          | 1          | 2          |      |
|  | Digits          | 1          | 2          | 1          | 2          |      |
|  | Special         | 1          | 2          | 0*         | 2          |      |
|  | History         | 12         | 24         | 12         | 24         |      |
|  | Rotation Days   | 90         | 30         | 90         | 365        |      |
|  +-----------------+------------+------------+------------+------------+      |
|                                                                               |
|  * Some network devices don't support special characters                      |
|                                                                               |
+===============================================================================+
```

---

## Automatic Rotation

### Rotation Workflow

```
+===============================================================================+
|                      AUTOMATIC ROTATION WORKFLOW                              |
+===============================================================================+
|                                                                               |
|  1. TRIGGER                                                                   |
|  ==========                                                                   |
|                                                                               |
|  +-----------------+  +-----------------+  +-----------------+                |
|  |   SCHEDULED     |  |   ON-DEMAND     |  |  POST-SESSION   |                |
|  |                 |  |                 |  |                 |                |
|  |  Cron-based     |  |  Manual trigger |  |  After session  |                |
|  |  (daily/weekly) |  |  via UI or API  |  |  completion     |                |
|  +--------+--------+  +--------+--------+  +--------+--------+                |
|           |                    |                    |                         |
|           +--------------------+--------------------+                         |
|                                |                                              |
|                                v                                              |
|                                                                               |
|  2. PRE-CHANGE VALIDATION                                                     |
|  ========================                                                     |
|                                                                               |
|  +-----------------------------------------------------------------------+    |
|  |  * Verify target connectivity                                         |    |
|  |  * Check current credential validity                                  |    |
|  |  * Ensure no active sessions (optional)                               |    |
|  |  * Validate rotation account permissions                              |    |
|  +-----------------------------------------------------------------------+    |  
|                                |                                              | 
|                                v                                              |
|                                                                               |
|  3. GENERATE NEW PASSWORD                                                     |
|  ========================                                                     |
|                                                                               |
|  +-----------------------------------------------------------------------+    |
|  |  * Apply password policy rules                                        |    |
|  |  * Check against password history                                     |    |
|  |  * Generate cryptographically secure password                         |    |
|  +-----------------------------------------------------------------------+    |
|                                |                                              |
|                                v                                              |
|                                                                               |
|  4. CHANGE ON TARGET                                                          |
|  ===================                                                          |
|                                                                               |
|  +-----------------------------------------------------------------------+    |
|  |  * Connect to target system                                           |    |
|  |  * Execute platform-specific change command                           |    |
|  |  * Handle any prompts or confirmations                                |    |
|  +-----------------------------------------------------------------------+    |
|                                |                                              |
|                                v                                              |
|                                                                               |
|  5. VERIFY NEW PASSWORD                                                       |
|  ======================                                                       |
|                                                                               |
|  +-----------------------------------------------------------------------+    |
|  |  * Attempt authentication with new password                           |    |
|  |  * Confirm successful login                                           |    |
|  |  * Verify expected permissions/access                                 |    |
|  +-----------------------------------------------------------------------+    |
|                                |                                              |
|                    +-----------+-----------+                                  |
|                    |                       |                                  |
|                    v                       v                                  |
|                                                                               |
|           +----------------+      +----------------+                          |
|           |    SUCCESS     |      |    FAILURE     |                          |
|           |                |      |                |                          |
|           | * Update vault |      | * Keep old pwd |                          |
|           | * Log success  |      | * Alert admin  |                          |
|           | * Update audit |      | * Try reconcile|                          |
|           +----------------+      +----------------+                          |
|                                                                               |
+===============================================================================+
```

### Rotation Schedules

```json
{
    "rotation_schedule": {
        "name": "monthly-rotation",

        "frequency": {
            "type": "interval",
            "days": 30
        },

        "window": {
            "start_time": "02:00",
            "end_time": "06:00",
            "timezone": "UTC"
        },

        "options": {
            "skip_if_active_session": true,
            "retry_on_failure": true,
            "retry_count": 3,
            "retry_interval_minutes": 30
        }
    }
}
```

### Rotation Triggers

| Trigger | Description | Configuration |
|---------|-------------|---------------|
| Scheduled | Time-based rotation | Cron schedule |
| On-demand | Manual trigger | UI/API action |
| Post-session | After session ends | Authorization setting |
| On-checkout | Before credential use | Checkout policy |
| Event-based | After security event | Integration trigger |

---

## Target Connectors

### Windows Systems

```
+===============================================================================+
|                      WINDOWS PASSWORD CHANGE                                  |
+===============================================================================+
|                                                                               |
|  LOCAL ACCOUNTS                                                               |
|  ==============                                                               |
|                                                                               |
|  Method: WinRM + PowerShell                                                   |
|                                                                               |
|  +-----------------------------------------------------------------------+    |
|  |  # Change local user password (modern PowerShell)                     |    |
|  |  $SecurePass = ConvertTo-SecureString "NewPassword123!" -AsPlain -Foce|    |
|  |  Set-LocalUser -Name "Administrator" -Password $SecurePass            |    |
|  +-----------------------------------------------------------------------+    |
|                                                                               |
|  Requirements:                                                                |
|  * WinRM enabled on target                                                    |
|  * Admin credentials for rotation                                             |
|  * Port 5985/5986 accessible                                                  |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  DOMAIN ACCOUNTS                                                              |
|  ===============                                                              |
|                                                                               |
|  Method: LDAP/Kerberos                                                        |
|                                                                               |
|  +-----------------------------------------------------------------------+    |
|  |  # Change domain user password via LDAP                               |    |
|  |  Set-ADAccountPassword -Identity "svc_account" \                      |    |
|  |      -NewPassword (ConvertTo-SecureString "NewPwd!" -AsPlainText)     |    |
|  +-----------------------------------------------------------------------+    |
|                                                                               |
|  Requirements:                                                                |
|  * Domain admin or delegated permissions                                      |
|  * LDAPS (port 636) recommended                                               |
|  * Service account for rotation                                               |
|                                                                               |
+===============================================================================+
```

### Linux/Unix Systems

```
+===============================================================================+
|                      LINUX PASSWORD CHANGE                                    |
+===============================================================================+
|                                                                               |
|  Method: SSH + passwd/chpasswd                                                |
|                                                                               |
|  OPTION 1: Using passwd (interactive)                                         |
|  -------------------------------------                                        |
|                                                                               |
|  +-----------------------------------------------------------------------+    |
|  |  # Expect script or SSH interaction                                   |    |
|  |  passwd username                                                      |    |
|  |  > Enter new password: [new_password]                                 |    |
|  |  > Retype new password: [new_password]                                |    |
|  +-----------------------------------------------------------------------+    |
|                                                                               |
|  OPTION 2: Using chpasswd (non-interactive)                                   |
|  ------------------------------------------                                   |
|                                                                               |
|  +-----------------------------------------------------------------------+    |
|  |  echo "username:newpassword" | chpasswd                               |    |
|  +-----------------------------------------------------------------------+    |
|                                                                               |
|  OPTION 3: Using usermod                                                      |
|  -----------------------                                                      |
|                                                                               |
|  +-----------------------------------------------------------------------+    |
|  |  usermod --password $(openssl passwd -6 'newpassword') username       |    |
|  +-----------------------------------------------------------------------+    |
|                                                                               |
|  Requirements:                                                                |
|  * SSH access (port 22)                                                       |
|  * Root or sudo privileges                                                    |
|  * Target user exists                                                         |
|                                                                               |
+===============================================================================+
```

### Network Devices

```
+===============================================================================+
|                    NETWORK DEVICE PASSWORD CHANGE                             |
+===============================================================================+
|                                                                               |
|  CISCO IOS                                                                    |
|  =========                                                                    |
|                                                                               |
|  +-----------------------------------------------------------------------+    |
|  |  enable                                                               |    |
|  |  configure terminal                                                   |    |
|  |  username admin privilege 15 secret NewPassword123!                   |    |
|  |  end                                                                  |    |
|  |  write memory                                                         |    |
|  +-----------------------------------------------------------------------+    |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  JUNIPER JUNOS                                                                |
|  =============                                                                |
|                                                                               |
|  +-----------------------------------------------------------------------+    |
|  |  configure                                                            |    |
|  |  set system login user admin authentication plain-text-password       |    |
|  |  > New password: [new_password]                                       |    |
|  |  commit                                                               |    |
|  +-----------------------------------------------------------------------+    |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  PALO ALTO PAN-OS                                                             |
|  ================                                                             |
|                                                                               |
|  +-----------------------------------------------------------------------+    |
|  |  configure                                                            |    |
|  |  set mgt-config users admin password                                  |    |
|  |  > Enter password: [new_password]                                     |    |
|  |  commit                                                               |    |
|  +-----------------------------------------------------------------------+    |
|                                                                               |
+===============================================================================+
```

### Database Systems

```
+===============================================================================+
|                     DATABASE PASSWORD CHANGE                                  |
+===============================================================================+
|                                                                               |
|  ORACLE                                                                       |
|  ======                                                                       |
|                                                                               |
|  +-----------------------------------------------------------------------+    |
|  |  ALTER USER dbuser IDENTIFIED BY "NewPassword123!";                   |    |
|  +-----------------------------------------------------------------------+    |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  MICROSOFT SQL SERVER                                                         |
|  ====================                                                         |
|                                                                               |
|  +-----------------------------------------------------------------------+    |
|  |  ALTER LOGIN [sa] WITH PASSWORD = 'NewPassword123!';                  |    |
|  +-----------------------------------------------------------------------+    |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  MYSQL / MARIADB                                                              |
|  ===============                                                              |
|                                                                               |
|  +-----------------------------------------------------------------------+    |
|  |  ALTER USER 'dbuser'@'%' IDENTIFIED BY 'NewPassword123!';             |    |
|  |  FLUSH PRIVILEGES;                                                    |    |
|  +-----------------------------------------------------------------------+    |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  MARIADB                                                                      |
|  =======                                                                      |
|                                                                               |
|  +-----------------------------------------------------------------------+    |
|  |  ALTER USER 'dbuser'@'%' IDENTIFIED BY 'NewPassword123!';             |    |
|  |  FLUSH PRIVILEGES;                                                    |    |
|  +-----------------------------------------------------------------------+    |
|                                                                               |
+===============================================================================+
```

---

## Checkout Workflows

### Checkout Process

```
+===============================================================================+
|                        CHECKOUT WORKFLOW                                      |
+===============================================================================+
|                                                                               |
|  +----------+                                                                 |
|  |   User   |                                                                 |
|  +----+-----+                                                                 |
|       |                                                                       |
|       |  1. Request credential checkout                                       |
|       v                                                                       |
|  +---------------------------------------------------------------------+      |
|  |                    CHECKOUT REQUEST                                 |      |
|  |                                                                     |      |
|  |   Account: root@srv-prod-01                                         |      |
|  |   Reason: [Ticket number or justification]                          |      |
|  |   Duration: 4 hours                                                 |      |
|  |                                                                     |      |
|  +---------------------------------------------------------------------+      |
|       |                                                                       |
|       v                                                                       |
|  +-----------------------------------------+                                  |
|  |  2. Policy Check                        |                                  |
|  |                                         |                                  |
|  |  * Exclusive checkout in use?           |--- YES --> WAIT or DENY          |
|  |  * User authorized?                     |                                  |
|  |  * Approval required?                   |--- YES --> APPROVAL FLOW         |
|  +-----------------+-----------------------+                                  |
|                    | APPROVED                                                 |
|                    v                                                          |
|  +-----------------------------------------+                                  |
|  |  3. Credential Retrieved                |                                  |
|  |                                         |                                  |
|  |  * Decrypt from vault                   |                                  |
|  |  * Mark as checked out                  |                                  |
|  |  * Start timer                          |                                  |
|  |  * Log checkout event                   |                                  |
|  +-----------------+-----------------------+                                  |
|                    |                                                          |
|                    v                                                          |
|  +---------------------------------------------------------------------+      |
|  |                     CHECKOUT ACTIVE                                 |      |
|  |                                                                     |      |
|  |   Status: Checked out to jsmith                                     |      |
|  |   Time remaining: 3:45:00                                           |      |
|  |   Password: ******** [Show] [Copy]                                  |      |
|  |                                                                     |      |
|  |   [Extend] [Check In]                                               |      |
|  |                                                                     |      |
|  +---------------------------------------------------------------------+      |
|       |                                                                       |
|       |  4. User checks in or timeout                                         |
|       v                                                                       |
|  +-----------------------------------------+                                  |
|  |  5. Check-In                            |                                  |
|  |                                         |                                  |
|  |  * Mark as available                    |                                  |
|  |  * Rotate password (if configured)      |                                  |
|  |  * Log check-in event                   |                                  |
|  +-----------------------------------------+                                  |
|                                                                               |
+===============================================================================+
```

### Checkout Modes

| Mode | Description | Use Case |
|------|-------------|----------|
| **Exclusive** | One user at a time | High-security accounts |
| **Shared** | Multiple concurrent | Service accounts |
| **Time-limited** | Auto-checkin after duration | Standard access |

---

## SSH Key Management

### Key Lifecycle

```
+===============================================================================+
|                        SSH KEY LIFECYCLE                                      |
+===============================================================================+
|                                                                               |
|  1. KEY GENERATION                                                            |
|  =================                                                            |
|                                                                               |
|  +-----------------------------------------------------------------------+    |
|  |  Key Types Supported:                                                 |    |
|  |  * RSA (2048, 4096 bits)                                              |    |
|  |  * ECDSA (256, 384, 521 bits)                                         |    |
|  |  * Ed25519 (recommended)                                              |    |
|  +-----------------------------------------------------------------------+    |
|                                |                                              |
|                                v                                              |
|  2. KEY STORAGE                                                               |
|  ==============                                                               |
|                                                                               |
|  +-----------------------------------------------------------------------+    |
|  |  Private Key: Encrypted in vault (AES-256)                            |    |
|  |  Public Key: Stored for deployment                                    |    |
|  |  Passphrase: Optional, encrypted if used                              |    |
|  +-----------------------------------------------------------------------+    |
|                                |                                              |
|                                v                                              |
|  3. KEY DEPLOYMENT                                                            |
|  =================                                                            |
|                                                                               |
|  +-----------------------------------------------------------------------+    |
|  |  # Deploy public key to target                                        |    |
|  |  ~/.ssh/authorized_keys                                               |    |
|  |                                                                       |    |
|  |  Methods:                                                             |    |
|  |  * SSH + cat (manual)                                                 |    |
|  |  * Ansible/Puppet (automated)                                         |    |
|  |  * WALLIX deployment (built-in)                                       |    |
|  +-----------------------------------------------------------------------+    |
|                                |                                              |
|                                v                                              |
|  4. KEY ROTATION                                                              |
|  ===============                                                              |
|                                                                               |
|  +-----------------------------------------------------------------------+    |
|  |  * Generate new key pair                                              |    |
|  |  * Deploy new public key to target                                    |    |
|  |  * Verify new key works                                               |    |
|  |  * Remove old public key                                              |    |
|  |  * Update vault with new private key                                  |    |
|  +-----------------------------------------------------------------------+    | 
|                                                                               |
+===============================================================================+
```

---

## Troubleshooting Rotation

### Common Issues

```
+===============================================================================+
|                    ROTATION TROUBLESHOOTING GUIDE                             |
+===============================================================================+
|                                                                               |
|  ISSUE: Rotation Fails - Connection Error                                     |
|  ========================================                                     |
|                                                                               |
|  Symptoms:                                                                    |
|  * "Connection refused" or "Connection timeout"                               |
|                                                                               |
|  Checks:                                                                      |
|  [ ] Target reachable from Bastion? (ping, telnet)                            |
|  [ ] Required ports open? (22, 5985, etc.)                                    |
|  [ ] Firewall rules allow Bastion?                                            |
|  [ ] Target service running? (sshd, WinRM)                                    |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  ISSUE: Rotation Fails - Authentication Error                                 |
|  =============================================                                |
|                                                                               |
|  Symptoms:                                                                    |
|  * "Authentication failed" or "Access denied"                                 |
|                                                                               |
|  Checks:                                                                      |
|  [ ] Rotation account credentials correct?                                    |
|  [ ] Rotation account has permissions to change?                              |
|  [ ] Account not locked on target?                                            |
|  [ ] Password policy on target allows new password?                           |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  ISSUE: Rotation Fails - Verification Error                                   |
|  ===========================================                                  |
|                                                                               |
|  Symptoms:                                                                    |
|  * "Verification failed" - password changed but can't verify                  |
|                                                                               |
|  Checks:                                                                      |
|  [ ] Target requires password change delay?                                   |
|  [ ] Account restrictions prevent immediate login?                            |
|  [ ] Network issues during verification?                                      |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  ISSUE: Vault Out of Sync                                                     |
|  ========================                                                     |
|                                                                               |
|  Symptoms:                                                                    |
|  * Password in vault doesn't match target                                     |
|                                                                               |
|  Resolution:                                                                  |
|  1. Use reconciliation account to reset                                       |
|  2. Manually update vault with known password                                 |
|  3. Trigger reconciliation process                                            |
|                                                                               |
+===============================================================================+
```

### Reconciliation

```
+===============================================================================+
|                       RECONCILIATION PROCESS                                  |
+===============================================================================+
|                                                                               |
|  Purpose: Recover when vault password is out of sync with target              |
|                                                                               |
|  +---------------------------------------------------------------------+      |
|  |                                                                     |      |
|  |  1. Reconciliation account connects to target                       |      |
|  |     (separate privileged account)                                   |      |
|  |                           |                                         |      |
|  |                           v                                         |      |
|  |  2. Reset managed account password                                  |      |
|  |                           |                                         |      |
|  |                           v                                         |      |
|  |  3. Verify new password works                                       |      |
|  |                           |                                         |      |
|  |                           v                                         |      |
|  |  4. Update vault with new password                                  |      |
|  |                                                                     |      |
|  +---------------------------------------------------------------------+      |
|                                                                               |
|  Configuration:                                                               |
|                                                                               |
|  {                                                                            |
|      "reconciliation": {                                                      |
|          "enabled": true,                                                     |
|          "account": "reconcile@srv-prod-01",                                  |
|          "auto_reconcile_on_failure": true                                    |
|      }                                                                        |
|  }                                                                            |
|                                                                               |
+===============================================================================+
```

---

## Next Steps

Continue to [08 - Session Management](../08-session-management/README.md) for session recording and monitoring.
