# 57 - Service Account Lifecycle Management

## Table of Contents

1. [Service Account Overview](#service-account-overview)
2. [Lifecycle Architecture](#lifecycle-architecture)
3. [Account Creation](#account-creation)
4. [Account Onboarding to PAM](#account-onboarding-to-pam)
5. [Ongoing Management](#ongoing-management)
6. [Password and Key Rotation](#password-and-key-rotation)
7. [Access Reviews](#access-reviews)
8. [Account Modification](#account-modification)
9. [Account Decommissioning](#account-decommissioning)
10. [Compliance and Reporting](#compliance-and-reporting)
11. [Automation](#automation)

---

## Service Account Overview

### What Are Service Accounts?

Service accounts are non-human identities used by applications, services, automated processes, and system components to authenticate and access resources. Unlike human user accounts, service accounts operate programmatically without interactive logon.

```
+===============================================================================+
|                    SERVICE ACCOUNT TAXONOMY                                    |
+===============================================================================+
|                                                                               |
|  SERVICE ACCOUNT TYPES                                                        |
|  =====================                                                        |
|                                                                               |
|  +-------------------------------------------------------------------------+ |
|  | Type                 | Purpose                    | Risk Level          | |
|  +----------------------+----------------------------+---------------------+ |
|  | Application Service  | Web apps, middleware       | High                | |
|  | Database Service     | DB connections, backups    | Critical            | |
|  | Scheduled Tasks      | Batch jobs, automation     | Medium-High         | |
|  | Integration Service  | API connectors, ETL        | High                | |
|  | Infrastructure       | Monitoring, management     | High                | |
|  | Vendor/Third-party   | External integrations      | Critical            | |
|  | Legacy Systems       | Older applications         | Critical            | |
|  +----------------------+----------------------------+---------------------+ |
|                                                                               |
|  KEY CHARACTERISTICS                                                          |
|  ===================                                                          |
|                                                                               |
|  * Non-interactive authentication                                             |
|  * Often highly privileged                                                    |
|  * Long-lived credentials (historically)                                      |
|  * Multiple system dependencies                                               |
|  * Ownership often unclear after initial creation                             |
|  * Password changes can cause service outages                                 |
|                                                                               |
+===============================================================================+
```

### Service Account Risks

| Risk Category | Description | Business Impact |
|---------------|-------------|-----------------|
| **Credential Exposure** | Static passwords in scripts, config files | Data breach, unauthorized access |
| **Privilege Creep** | Excessive permissions accumulated over time | Lateral movement, blast radius |
| **Orphaned Accounts** | No owner after staff turnover | Uncontrolled access, compliance gaps |
| **No Rotation** | Same password for years | Extended compromise window |
| **Shared Credentials** | Multiple services using same account | No accountability, audit failures |
| **No Audit Trail** | Activities not linked to individuals | Compliance violations, forensics gaps |

### Governance Requirements

```
+===============================================================================+
|                    SERVICE ACCOUNT GOVERNANCE MODEL                            |
+===============================================================================+
|                                                                               |
|  GOVERNANCE PILLARS                                                           |
|  ==================                                                           |
|                                                                               |
|     ACCOUNTABILITY          VISIBILITY           CONTROL           COMPLIANCE |
|     ==============          ==========           =======           ========== |
|                                                                               |
|  +---------------+     +---------------+     +---------------+     +---------+|
|  | * Defined     |     | * Complete    |     | * Credential  |     | * Audit ||
|  |   owners      |     |   inventory   |     |   vaulting    |     |   ready ||
|  | * Approval    |     | * Usage       |     | * Access      |     | * Policy||
|  |   workflows   |     |   monitoring  |     |   controls    |     |   align ||
|  | * Business    |     | * Dependency  |     | * Rotation    |     | * Report||
|  |   justification     |   mapping     |     |   automation  |     |   able  ||
|  +---------------+     +---------------+     +---------------+     +---------+|
|                                                                               |
|  REGULATORY DRIVERS                                                           |
|  ==================                                                           |
|                                                                               |
|  +-------------------------------------------------------------------------+ |
|  | Framework    | Service Account Requirements                              | |
|  +--------------+-----------------------------------------------------------+ |
|  | SOC 2        | CC6.1-CC6.3: Access control, provisioning, removal        | |
|  | ISO 27001    | A.9.2.3: Privileged access management                     | |
|  | PCI-DSS      | 8.1.5, 8.6: Unique IDs, authentication mechanisms         | |
|  | IEC 62443    | IAC-2, IAC-9: Process identification, authenticator mgmt  | |
|  | NIST 800-53  | AC-2, IA-4: Account management, identifier management     | |
|  | NIS2         | Article 21(j): Access control policies                    | |
|  +--------------+-----------------------------------------------------------+ |
|                                                                               |
+===============================================================================+
```

---

## Lifecycle Architecture

### Full Lifecycle Diagram

```
+===============================================================================+
|                    SERVICE ACCOUNT LIFECYCLE                                   |
+===============================================================================+
|                                                                               |
|    REQUEST       CREATE        ONBOARD       OPERATE       MODIFY      DECOM  |
|    =======       ======        =======       =======       ======      =====  |
|                                                                               |
|    +------+     +------+      +------+      +------+      +------+    +------+|
|    |      |     |      |      |      |      |      |      |      |    |      ||
|    | REQ  |---->|CREATE|----->|VAULT |----->|ROTATE|----->|UPDATE|    |RETIRE||
|    |      |     |      |      |      |      |      |      |      |    |      ||
|    +------+     +------+      +------+      +------+      +------+    +------+|
|        |            |             |             |             |           ^   |
|        v            v             v             v             v           |   |
|    +------+     +------+      +------+      +------+      +------+    +------+|
|    |Justify|    |Name  |      |Import|      |Monitor|     |Owner |    |Revoke||
|    |Owner  |    |Doc   |      |Policy|      |Attest |     |Perms |    |Archive|
|    |Approve|    |Creds |      |Assign|      |Review |     |Regen |    |Audit ||
|    +------+     +------+      +------+      +------+      +------+    +------+|
|                                                                               |
|                                                                               |
|    LIFECYCLE PHASES IN DETAIL                                                 |
|    ==========================                                                 |
|                                                                               |
|    Phase 1: REQUEST (Days 1-3)                                                |
|    ---------------------------                                                |
|    * Business justification submitted                                         |
|    * Owner and approver assigned                                              |
|    * Security review completed                                                |
|    * ITSM ticket created                                                      |
|                                                                               |
|    Phase 2: CREATE (Days 4-7)                                                 |
|    --------------------------                                                 |
|    * Account created per naming convention                                    |
|    * Initial credentials generated securely                                   |
|    * Documentation completed                                                  |
|    * Minimum required permissions assigned                                    |
|                                                                               |
|    Phase 3: ONBOARD TO PAM (Days 8-10)                                        |
|    -----------------------------------                                        |
|    * Account imported to WALLIX Bastion                                       |
|    * Credentials vaulted (AES-256 encrypted)                                  |
|    * Rotation policy assigned                                                 |
|    * Authorizations configured                                                |
|                                                                               |
|    Phase 4: OPERATE (Ongoing)                                                 |
|    --------------------------                                                 |
|    * Automatic password rotation                                              |
|    * Usage monitoring and alerting                                            |
|    * Periodic attestation (quarterly)                                         |
|    * Access reviews (annual)                                                  |
|                                                                               |
|    Phase 5: MODIFY (As needed)                                                |
|    ---------------------------                                                |
|    * Ownership transfers                                                      |
|    * Permission changes                                                       |
|    * Credential regeneration                                                  |
|    * Dependency updates                                                       |
|                                                                               |
|    Phase 6: DECOMMISSION (End of life)                                        |
|    -----------------------------------                                        |
|    * Disable account access                                                   |
|    * Revoke credentials                                                       |
|    * Archive audit trails                                                     |
|    * Document decommission                                                    |
|                                                                               |
+===============================================================================+
```

### State Transition Diagram

```
+===============================================================================+
|                    ACCOUNT STATE TRANSITIONS                                   |
+===============================================================================+
|                                                                               |
|                            +-------------+                                    |
|                            |  REQUESTED  |                                    |
|                            +------+------+                                    |
|                                   |                                           |
|                              Approved                                         |
|                                   |                                           |
|                                   v                                           |
|                            +-------------+                                    |
|                            |   CREATED   |                                    |
|                            +------+------+                                    |
|                                   |                                           |
|                              Onboarded                                        |
|                                   |                                           |
|                                   v                                           |
|    +-------------+         +-------------+         +-------------+            |
|    |   LOCKED    |<--------|   ACTIVE    |-------->|  SUSPENDED  |            |
|    +------+------+   Lock  +------+------+  Suspend+------+------+            |
|           |                      |                        |                   |
|           |                      |                        |                   |
|       Unlock                 Decommission              Reactivate             |
|           |                      |                        |                   |
|           |                      v                        |                   |
|           |                +-------------+                |                   |
|           +--------------->|  DISABLED   |<---------------+                   |
|                            +------+------+                                    |
|                                   |                                           |
|                               Archive                                         |
|                                   |                                           |
|                                   v                                           |
|                            +-------------+                                    |
|                            |  ARCHIVED   |                                    |
|                            +-------------+                                    |
|                                                                               |
|  STATE DEFINITIONS                                                            |
|  =================                                                            |
|                                                                               |
|  +-------------+-------------------------------------------------------+     |
|  | State       | Description                                           |     |
|  +-------------+-------------------------------------------------------+     |
|  | REQUESTED   | Approval pending, no account exists                   |     |
|  | CREATED     | Account exists but not yet in PAM                     |     |
|  | ACTIVE      | Fully operational, credentials managed by PAM         |     |
|  | SUSPENDED   | Temporarily disabled, awaiting review                 |     |
|  | LOCKED      | Security hold, requires investigation                 |     |
|  | DISABLED    | Permanently deactivated, pending archive              |     |
|  | ARCHIVED    | Historical record only, all access removed            |     |
|  +-------------+-------------------------------------------------------+     |
|                                                                               |
+===============================================================================+
```

---

## Account Creation

### Naming Conventions

Consistent naming enables automated discovery, reporting, and lifecycle management.

```
+===============================================================================+
|                    SERVICE ACCOUNT NAMING STANDARD                             |
+===============================================================================+
|                                                                               |
|  NAMING PATTERN                                                               |
|  ==============                                                               |
|                                                                               |
|  Format: svc_<app>_<function>_<environment>                                   |
|                                                                               |
|  Components:                                                                  |
|  +-------------------------------------------------------------------------+ |
|  | Component   | Description              | Examples                       | |
|  +-------------+--------------------------+--------------------------------+ |
|  | Prefix      | Account type identifier  | svc_ (service)                 | |
|  |             |                          | app_ (application)             | |
|  |             |                          | int_ (integration)             | |
|  |             |                          | sch_ (scheduled task)          | |
|  +-------------+--------------------------+--------------------------------+ |
|  | Application | Application/system name  | erp, crm, scada, mes           | |
|  +-------------+--------------------------+--------------------------------+ |
|  | Function    | Purpose/role             | db, api, backup, monitor       | |
|  +-------------+--------------------------+--------------------------------+ |
|  | Environment | Deployment environment   | prod, uat, dev, dr             | |
|  +-------------+--------------------------+--------------------------------+ |
|                                                                               |
|  EXAMPLES                                                                     |
|  ========                                                                     |
|                                                                               |
|  svc_erp_db_prod        - ERP database service account (production)          |
|  svc_crm_api_uat        - CRM API integration (UAT)                          |
|  svc_scada_backup_prod  - SCADA backup service (production)                  |
|  int_sap_monitor_prod   - SAP monitoring integration (production)            |
|  sch_reports_batch_prod - Scheduled reporting batch job (production)         |
|                                                                               |
|  NAMING ANTI-PATTERNS (AVOID)                                                 |
|  ============================                                                 |
|                                                                               |
|  * admin, admin1, administrator    - Generic, non-descriptive                |
|  * john_service                    - Personal names                          |
|  * test_account                    - Unclear purpose                         |
|  * backup                          - Missing context                         |
|  * temp_svc_2024                   - Temporary accounts that persist         |
|                                                                               |
+===============================================================================+
```

### Ownership Assignment

Every service account must have clearly defined ownership and accountability.

```
+===============================================================================+
|                    OWNERSHIP MODEL                                             |
+===============================================================================+
|                                                                               |
|  ROLE DEFINITIONS                                                             |
|  ================                                                             |
|                                                                               |
|  +-------------------------------------------------------------------------+ |
|  | Role              | Responsibilities                                    | |
|  +-------------------+-----------------------------------------------------+ |
|  | Business Owner    | * Business justification                            | |
|  |                   | * Budget authorization                              | |
|  |                   | * Annual attestation                                | |
|  |                   | * Decommission approval                             | |
|  +-------------------+-----------------------------------------------------+ |
|  | Technical Owner   | * Day-to-day management                             | |
|  |                   | * Permission configuration                          | |
|  |                   | * Dependency documentation                          | |
|  |                   | * Rotation coordination                             | |
|  +-------------------+-----------------------------------------------------+ |
|  | Security Owner    | * Risk assessment                                   | |
|  |                   | * Policy compliance                                 | |
|  |                   | * Access review approval                            | |
|  |                   | * Incident response                                 | |
|  +-------------------+-----------------------------------------------------+ |
|  | Backup Owner      | * Coverage during absences                          | |
|  |                   | * Emergency response                                | |
|  |                   | * Knowledge continuity                              | |
|  +-------------------+-----------------------------------------------------+ |
|                                                                               |
|  OWNERSHIP DOCUMENTATION                                                      |
|  =======================                                                      |
|                                                                               |
|  {                                                                            |
|    "account_name": "svc_erp_db_prod",                                         |
|    "ownership": {                                                             |
|      "business_owner": {                                                      |
|        "name": "Jane Smith",                                                  |
|        "email": "jane.smith@company.com",                                     |
|        "department": "Finance",                                               |
|        "cost_center": "FIN-001"                                               |
|      },                                                                       |
|      "technical_owner": {                                                     |
|        "name": "John Doe",                                                    |
|        "email": "john.doe@company.com",                                       |
|        "team": "Database Administration"                                      |
|      },                                                                       |
|      "security_owner": {                                                      |
|        "name": "Security Team",                                               |
|        "email": "security@company.com"                                        |
|      },                                                                       |
|      "backup_owner": {                                                        |
|        "name": "Bob Wilson",                                                  |
|        "email": "bob.wilson@company.com"                                      |
|      }                                                                        |
|    },                                                                         |
|    "created_date": "2024-01-15",                                              |
|    "last_review": "2024-10-15",                                               |
|    "next_review": "2025-01-15"                                                |
|  }                                                                            |
|                                                                               |
+===============================================================================+
```

### Initial Credential Setup

```
+===============================================================================+
|                    SECURE CREDENTIAL GENERATION                                |
+===============================================================================+
|                                                                               |
|  CREDENTIAL REQUIREMENTS BY TYPE                                              |
|  ===============================                                              |
|                                                                               |
|  +-------------------------------------------------------------------------+ |
|  | Credential Type | Min Length | Complexity          | Rotation           | |
|  +-----------------+------------+---------------------+--------------------+ |
|  | Password        | 24 chars   | Upper, lower, num,  | Per risk level     | |
|  |                 |            | special (2 each)    |                    | |
|  +-----------------+------------+---------------------+--------------------+ |
|  | SSH Key         | 4096-bit   | RSA or Ed25519      | Annual minimum     | |
|  |                 |            | (Ed25519 preferred) |                    | |
|  +-----------------+------------+---------------------+--------------------+ |
|  | API Key         | 64 chars   | Cryptographic random| Per policy         | |
|  +-----------------+------------+---------------------+--------------------+ |
|  | Certificate     | 2048-bit   | SHA-256 or better   | Before expiry      | |
|  |                 | minimum    |                     |                    | |
|  +-----------------+------------+---------------------+--------------------+ |
|                                                                               |
|  GENERATION METHODS                                                           |
|  ==================                                                           |
|                                                                               |
|  # Generate secure password via WALLIX API                                    |
|  curl -X POST "https://wallix.company.com/api/v2/passwords/generate" \        |
|    -H "Authorization: Bearer $TOKEN" \                                        |
|    -H "Content-Type: application/json" \                                      |
|    -d '{                                                                      |
|      "length": 24,                                                            |
|      "uppercase": 2,                                                          |
|      "lowercase": 2,                                                          |
|      "digits": 2,                                                             |
|      "special": 2,                                                            |
|      "exclude_ambiguous": true                                                |
|    }'                                                                         |
|                                                                               |
|  # Generate SSH key pair                                                      |
|  ssh-keygen -t ed25519 -C "svc_erp_db_prod@company.com" -f svc_key            |
|                                                                               |
|  SECURE HANDOFF                                                               |
|  ==============                                                               |
|                                                                               |
|  Initial credentials should NEVER be:                                         |
|  * Sent via email in plain text                                               |
|  * Stored in tickets or documentation                                         |
|  * Shared verbally or via messaging                                           |
|                                                                               |
|  Approved handoff methods:                                                    |
|  * Direct vault-to-vault transfer                                             |
|  * One-time secret sharing tools                                              |
|  * Credential injection (preferred)                                           |
|                                                                               |
+===============================================================================+
```

### Documentation Requirements

| Document | Purpose | Owner | Review Frequency |
|----------|---------|-------|------------------|
| **Account Request Form** | Business justification, approvals | Business Owner | At creation |
| **Technical Specification** | Purpose, dependencies, permissions | Technical Owner | Annual |
| **Risk Assessment** | Risk classification, mitigations | Security Owner | Annual |
| **Runbook** | Operational procedures, rotation steps | Technical Owner | As needed |
| **Dependency Map** | Systems, applications affected | Technical Owner | Quarterly |

---

## Account Onboarding to PAM

### Import Procedures

```
+===============================================================================+
|                    PAM ONBOARDING WORKFLOW                                     |
+===============================================================================+
|                                                                               |
|  STEP 1: PRE-ONBOARDING CHECKLIST                                             |
|  ================================                                             |
|                                                                               |
|  [ ] Account exists in target system                                          |
|  [ ] Current credentials known or resettable                                  |
|  [ ] Ownership documented                                                     |
|  [ ] Risk classification assigned                                             |
|  [ ] Target system reachable from Bastion                                     |
|  [ ] Rotation method validated                                                |
|  [ ] Dependencies documented                                                  |
|                                                                               |
|  STEP 2: CREATE DEVICE (if not exists)                                        |
|  =====================================                                        |
|                                                                               |
|  POST /api/v2/devices                                                         |
|  {                                                                            |
|    "name": "erp-db-prod",                                                     |
|    "host": "10.10.10.50",                                                     |
|    "alias": "ERP-DATABASE-PROD",                                              |
|    "description": "ERP Production Database Server",                           |
|    "domain": "service_accounts",                                              |
|    "type": "database",                                                        |
|    "services": [                                                              |
|      {                                                                        |
|        "protocol": "ssh",                                                     |
|        "port": 22                                                             |
|      }                                                                        |
|    ]                                                                          |
|  }                                                                            |
|                                                                               |
|  STEP 3: CREATE ACCOUNT IN WALLIX                                             |
|  ================================                                             |
|                                                                               |
|  POST /api/v2/accounts                                                        |
|  {                                                                            |
|    "name": "svc_erp_db_prod",                                                 |
|    "device_id": "dev_001",                                                    |
|    "domain": "service_accounts",                                              |
|    "type": "service",                                                         |
|    "description": "ERP database service account",                             |
|    "credential_type": "password",                                             |
|    "credentials": {                                                           |
|      "password": "<INITIAL_PASSWORD>"                                         |
|    },                                                                         |
|    "metadata": {                                                              |
|      "business_owner": "jane.smith@company.com",                              |
|      "technical_owner": "john.doe@company.com",                               |
|      "risk_level": "high",                                                    |
|      "created_date": "2024-01-15",                                            |
|      "itsm_ticket": "CHG0012345"                                              |
|    }                                                                          |
|  }                                                                            |
|                                                                               |
+===============================================================================+
```

### Credential Vaulting

```
+===============================================================================+
|                    CREDENTIAL VAULT CONFIGURATION                              |
+===============================================================================+
|                                                                               |
|  VAULT SECURITY                                                               |
|  ==============                                                               |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |  WALLIX CREDENTIAL VAULT                                              |   |
|  |                                                                       |   |
|  |  +-----------------------+    +-------------------------+             |   |
|  |  |    ENCRYPTION LAYER   |    |    ACCESS CONTROL      |             |   |
|  |  |                       |    |                         |             |   |
|  |  |  * AES-256-GCM        |    |  * Role-based access    |             |   |
|  |  |  * Unique IV per cred |    |  * Authorization req'd  |             |   |
|  |  |  * Master key (HSM)   |    |  * Audit logging        |             |   |
|  |  +-----------------------+    +-------------------------+             |   |
|  |                                                                       |   |
|  |  +-----------------------+    +-------------------------+             |   |
|  |  |    CREDENTIAL TYPES   |    |    CHECKOUT POLICIES    |             |   |
|  |  |                       |    |                         |             |   |
|  |  |  * Passwords          |    |  * Exclusive mode       |             |   |
|  |  |  * SSH keys           |    |  * Time-limited         |             |   |
|  |  |  * Certificates       |    |  * Approval required    |             |   |
|  |  |  * API tokens         |    |  * Rotate on checkin    |             |   |
|  |  +-----------------------+    +-------------------------+             |   |
|  |                                                                       |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
|  VAULTING API EXAMPLE                                                         |
|  ====================                                                         |
|                                                                               |
|  # Update account with vaulted credentials                                    |
|  PATCH /api/v2/accounts/{account_id}                                          |
|  {                                                                            |
|    "checkout_policy": "exclusive",                                            |
|    "auto_rotate": true,                                                       |
|    "rotation_period_days": 30,                                                |
|    "require_approval": false,                                                 |
|    "notify_on_checkout": true,                                                |
|    "notify_email": "john.doe@company.com"                                     |
|  }                                                                            |
|                                                                               |
+===============================================================================+
```

### Rotation Policy Assignment

```
+===============================================================================+
|                    ROTATION POLICY TEMPLATES                                   |
+===============================================================================+
|                                                                               |
|  POLICY BY RISK LEVEL                                                         |
|  ====================                                                         |
|                                                                               |
|  +-----------+------------------+----------------+------------------+         |
|  | Risk      | Rotation         | Verification   | Failure Action   |         |
|  | Level     | Frequency        | Required       |                  |         |
|  +-----------+------------------+----------------+------------------+         |
|  | Critical  | 7 days           | Yes            | Alert + retry    |         |
|  | High      | 30 days          | Yes            | Alert + retry    |         |
|  | Medium    | 90 days          | Yes            | Alert            |         |
|  | Low       | 180 days         | Optional       | Log              |         |
|  +-----------+------------------+----------------+------------------+         |
|                                                                               |
|  ROTATION SCHEDULE CONFIGURATION                                              |
|  ===============================                                              |
|                                                                               |
|  {                                                                            |
|    "policy_name": "high_risk_service_account",                                |
|    "rotation": {                                                              |
|      "frequency_days": 30,                                                    |
|      "window": {                                                              |
|        "start_time": "02:00",                                                 |
|        "end_time": "04:00",                                                   |
|        "timezone": "UTC",                                                     |
|        "days": ["saturday", "sunday"]                                         |
|      },                                                                       |
|      "options": {                                                             |
|        "verify_after_change": true,                                           |
|        "retry_on_failure": true,                                              |
|        "retry_count": 3,                                                      |
|        "retry_interval_minutes": 15,                                          |
|        "skip_if_service_active": true                                         |
|      }                                                                        |
|    },                                                                         |
|    "password_policy": {                                                       |
|      "length": 24,                                                            |
|      "uppercase_minimum": 2,                                                  |
|      "lowercase_minimum": 2,                                                  |
|      "digit_minimum": 2,                                                      |
|      "special_minimum": 2,                                                    |
|      "history_count": 24                                                      |
|    },                                                                         |
|    "notifications": {                                                         |
|      "on_success": false,                                                     |
|      "on_failure": true,                                                      |
|      "notify_owner": true,                                                    |
|      "notify_security": true                                                  |
|    }                                                                          |
|  }                                                                            |
|                                                                               |
+===============================================================================+
```

---

## Ongoing Management

### Regular Attestation/Recertification

```
+===============================================================================+
|                    ATTESTATION WORKFLOW                                        |
+===============================================================================+
|                                                                               |
|  QUARTERLY ATTESTATION PROCESS                                                |
|  =============================                                                |
|                                                                               |
|    [Start Attestation Campaign]                                               |
|              |                                                                |
|              v                                                                |
|    +-------------------+                                                      |
|    | Generate Account  |                                                      |
|    | Review List       |                                                      |
|    +--------+----------+                                                      |
|             |                                                                 |
|             v                                                                 |
|    +-------------------+                                                      |
|    | Send to Owners    |     Owner receives:                                  |
|    | for Review        |---->* Account list                                   |
|    +--------+----------+     * Current permissions                            |
|             |                * Last activity date                             |
|             |                * Justification prompt                           |
|             v                                                                 |
|    +-------------------+                                                      |
|    | Owner Response    |                                                      |
|    +--------+----------+                                                      |
|             |                                                                 |
|     +-------+-------+                                                         |
|     |               |                                                         |
|     v               v                                                         |
|  [CERTIFY]      [FLAG FOR REVIEW]                                             |
|     |               |                                                         |
|     v               v                                                         |
|  Continue      +-------------------+                                          |
|  Operations    | Security Review   |                                          |
|                +--------+----------+                                          |
|                         |                                                     |
|                 +-------+-------+                                             |
|                 |               |                                             |
|                 v               v                                             |
|             [APPROVE]      [DISABLE]                                          |
|                                                                               |
|  ATTESTATION QUESTIONS                                                        |
|  =====================                                                        |
|                                                                               |
|  1. Is this service account still required? [Yes/No]                          |
|  2. Is the current permission level appropriate? [Yes/No/Reduce]              |
|  3. Has the business purpose changed? [Yes/No]                                |
|  4. Is the technical owner still accurate? [Yes/No]                           |
|  5. Are there any security concerns? [Yes/No]                                 |
|                                                                               |
+===============================================================================+
```

### Owner Verification

| Check | Frequency | Action on Failure |
|-------|-----------|-------------------|
| Owner still employed | Monthly | Transfer ownership |
| Owner still in role | Quarterly | Review assignment |
| Owner responded to attestation | Quarterly | Escalate to manager |
| Owner acknowledged incidents | Per incident | Escalate to security |

### Usage Monitoring

```
+===============================================================================+
|                    USAGE MONITORING DASHBOARD                                  |
+===============================================================================+
|                                                                               |
|  KEY METRICS TO TRACK                                                         |
|  ====================                                                         |
|                                                                               |
|  +-------------------------------------------------------------------------+ |
|  | Metric                      | Alert Threshold       | Action            | |
|  +-----------------------------+-----------------------+-------------------+ |
|  | Last authentication         | > 90 days             | Review for decom  | |
|  | Authentication failures     | > 5 in 24h            | Investigate       | |
|  | Unusual login times         | Outside business hours| Verify legitimate | |
|  | Source IP changes           | New IP detected       | Verify legitimate | |
|  | Permission escalation       | Any elevation         | Security review   | |
|  | Credential checkout         | Any checkout          | Verify authorized | |
|  +-----------------------------+-----------------------+-------------------+ |
|                                                                               |
|  MONITORING API QUERIES                                                       |
|  ======================                                                       |
|                                                                               |
|  # Get accounts with no activity in 90 days                                   |
|  GET /api/v2/accounts?last_activity_before=90d&type=service                   |
|                                                                               |
|  # Get failed authentication attempts for service accounts                    |
|  GET /api/v2/audit/logs?event_type=auth_failure&account_type=service          |
|    &start_date=2024-01-01                                                     |
|                                                                               |
|  # Get checkout history for high-risk accounts                                |
|  GET /api/v2/accounts?risk_level=high&type=service                            |
|    &include=checkout_history                                                  |
|                                                                               |
|  ALERT CONFIGURATION                                                          |
|  ===================                                                          |
|                                                                               |
|  {                                                                            |
|    "alert_name": "service_account_anomaly",                                   |
|    "conditions": [                                                            |
|      {                                                                        |
|        "metric": "failed_auth_count",                                         |
|        "operator": "gt",                                                      |
|        "value": 5,                                                            |
|        "window": "24h"                                                        |
|      },                                                                       |
|      {                                                                        |
|        "metric": "source_ip",                                                 |
|        "operator": "changed",                                                 |
|        "baseline": "last_30d"                                                 |
|      }                                                                        |
|    ],                                                                         |
|    "actions": [                                                               |
|      {                                                                        |
|        "type": "email",                                                       |
|        "recipients": ["security@company.com", "${owner_email}"]               |
|      },                                                                       |
|      {                                                                        |
|        "type": "siem_alert",                                                  |
|        "severity": "high"                                                     |
|      }                                                                        |
|    ]                                                                          |
|  }                                                                            |
|                                                                               |
+===============================================================================+
```

---

## Password and Key Rotation

### Rotation Schedules by Risk Level

```
+===============================================================================+
|                    ROTATION SCHEDULE MATRIX                                    |
+===============================================================================+
|                                                                               |
|  RISK-BASED ROTATION REQUIREMENTS                                             |
|  ================================                                             |
|                                                                               |
|  +-------------------------------------------------------------------------+ |
|  | Risk    | Password  | SSH Key   | Certificate | API Token  | Justification|
|  | Level   | Rotation  | Rotation  | Renewal     | Rotation   |              |
|  +---------+-----------+-----------+-------------+------------+--------------+|
|  | Critical| 7 days    | 30 days   | 90 days     | 7 days     | Highest      |
|  |         |           |           |             |            | exposure     |
|  +---------+-----------+-----------+-------------+------------+--------------+|
|  | High    | 30 days   | 90 days   | 180 days    | 30 days    | Production   |
|  |         |           |           |             |            | systems      |
|  +---------+-----------+-----------+-------------+------------+--------------+|
|  | Medium  | 90 days   | 180 days  | 365 days    | 90 days    | Non-critical |
|  |         |           |           |             |            | systems      |
|  +---------+-----------+-----------+-------------+------------+--------------+|
|  | Low     | 180 days  | 365 days  | 365 days    | 180 days   | Isolated     |
|  |         |           |           |             |            | systems      |
|  +---------+-----------+-----------+-------------+------------+--------------+|
|                                                                               |
|  CRITICAL SYSTEMS EXAMPLES                                                    |
|  =========================                                                    |
|                                                                               |
|  * Domain admin service accounts                                              |
|  * Database admin accounts (production)                                       |
|  * Financial system integrations                                              |
|  * SCADA/ICS management accounts                                              |
|  * Backup system accounts                                                     |
|  * Certificate authority accounts                                             |
|                                                                               |
+===============================================================================+
```

### Rotation Verification

```
+===============================================================================+
|                    ROTATION VERIFICATION PROCESS                               |
+===============================================================================+
|                                                                               |
|  VERIFICATION WORKFLOW                                                        |
|  ====================                                                         |
|                                                                               |
|    [Generate New Credential]                                                  |
|              |                                                                |
|              v                                                                |
|    [Change on Target System]                                                  |
|              |                                                                |
|              v                                                                |
|    +-------------------+                                                      |
|    | VERIFY NEW        |                                                      |
|    | CREDENTIAL WORKS  |                                                      |
|    +--------+----------+                                                      |
|             |                                                                 |
|     +-------+-------+                                                         |
|     |               |                                                         |
|     v               v                                                         |
|  [SUCCESS]      [FAILURE]                                                     |
|     |               |                                                         |
|     v               v                                                         |
|  Update Vault   +-------------------+                                         |
|  Log Success    | Rollback to Old   |                                         |
|  Notify (opt)   | Credential        |                                         |
|                 +--------+----------+                                         |
|                          |                                                    |
|                          v                                                    |
|                 +-------------------+                                         |
|                 | Alert Owner &     |                                         |
|                 | Security Team     |                                         |
|                 +--------+----------+                                         |
|                          |                                                    |
|                          v                                                    |
|                 +-------------------+                                         |
|                 | Schedule Retry    |                                         |
|                 | or Manual Fix     |                                         |
|                 +-------------------+                                         |
|                                                                               |
|  VERIFICATION METHODS BY SYSTEM TYPE                                          |
|  ===================================                                          |
|                                                                               |
|  +-------------------------------------------------------------------------+ |
|  | System Type      | Verification Method                                  | |
|  +------------------+------------------------------------------------------+ |
|  | Linux/Unix       | SSH login test with new password/key                 | |
|  | Windows          | WinRM authentication test                            | |
|  | Database         | Connection test with new credentials                 | |
|  | Network device   | SSH/Telnet login verification                        | |
|  | Application      | API authentication endpoint test                     | |
|  | LDAP/AD          | LDAP bind test with new password                     | |
|  +------------------+------------------------------------------------------+ |
|                                                                               |
+===============================================================================+
```

### Failed Rotation Handling

```
+===============================================================================+
|                    ROTATION FAILURE PROCEDURES                                 |
+===============================================================================+
|                                                                               |
|  FAILURE RESPONSE WORKFLOW                                                    |
|  =========================                                                    |
|                                                                               |
|  +-------------------------------------------------------------------------+ |
|  | Priority | Condition                    | Response Time | Escalation    | |
|  +----------+------------------------------+---------------+---------------+ |
|  | P1       | Critical account, production | 15 minutes    | Immediate     | |
|  | P2       | High-risk account            | 1 hour        | Within 4h     | |
|  | P3       | Medium-risk account          | 4 hours       | Next bus day  | |
|  | P4       | Low-risk account             | 24 hours      | Weekly review | |
|  +----------+------------------------------+---------------+---------------+ |
|                                                                               |
|  COMMON FAILURE REASONS                                                       |
|  ======================                                                       |
|                                                                               |
|  +-------------------------------------------------------------------------+ |
|  | Failure Type           | Cause                      | Resolution        | |
|  +------------------------+----------------------------+-------------------+ |
|  | Connection timeout     | Network issue, firewall    | Check connectivity| |
|  | Authentication failed  | Old credential invalid     | Use reconciliation| |
|  | Permission denied      | Rotation account perms     | Fix permissions   | |
|  | Password policy reject | Complexity not met         | Adjust policy     | |
|  | Account locked         | Too many failures          | Unlock account    | |
|  | Service unavailable    | Target system down         | Wait/retry        | |
|  +------------------------+----------------------------+-------------------+ |
|                                                                               |
|  RECONCILIATION PROCEDURE                                                     |
|  ========================                                                     |
|                                                                               |
|  When vault credential is out of sync with target:                            |
|                                                                               |
|  1. Use reconciliation account to connect                                     |
|  2. Reset managed account password                                            |
|  3. Verify new credential works                                               |
|  4. Update vault with new credential                                          |
|  5. Log reconciliation event                                                  |
|  6. Investigate root cause                                                    |
|                                                                               |
|  # API: Trigger reconciliation                                                |
|  POST /api/v2/accounts/{account_id}/reconcile                                 |
|  {                                                                            |
|    "reason": "Rotation failure - credential out of sync",                     |
|    "ticket": "INC0012345"                                                     |
|  }                                                                            |
|                                                                               |
+===============================================================================+
```

---

## Access Reviews

### Periodic Access Reviews

```
+===============================================================================+
|                    ACCESS REVIEW FRAMEWORK                                     |
+===============================================================================+
|                                                                               |
|  REVIEW SCHEDULE                                                              |
|  ===============                                                              |
|                                                                               |
|  +-------------------------------------------------------------------------+ |
|  | Review Type           | Frequency    | Scope                            | |
|  +-----------------------+--------------+----------------------------------+ |
|  | Owner Attestation     | Quarterly    | All service accounts             | |
|  | Permission Review     | Semi-annual  | High/Critical accounts           | |
|  | Comprehensive Audit   | Annual       | All accounts + dependencies      | |
|  | Triggered Review      | As needed    | After incidents, org changes     | |
|  +-----------------------+--------------+----------------------------------+ |
|                                                                               |
|  ACCESS REVIEW CHECKLIST                                                      |
|  =======================                                                      |
|                                                                               |
|  [ ] Account still required for business function                             |
|  [ ] Permissions follow least privilege principle                             |
|  [ ] Owner information is current                                             |
|  [ ] Dependencies are documented                                              |
|  [ ] Rotation is occurring as scheduled                                       |
|  [ ] No security incidents associated                                         |
|  [ ] Compliant with current policies                                          |
|                                                                               |
|  REVIEW API ENDPOINTS                                                         |
|  ====================                                                         |
|                                                                               |
|  # Generate access review report                                              |
|  GET /api/v2/reports/access-review?account_type=service&period=quarterly      |
|                                                                               |
|  # Get accounts pending review                                                |
|  GET /api/v2/accounts?type=service&review_status=pending                      |
|                                                                               |
|  # Submit review decision                                                     |
|  POST /api/v2/accounts/{account_id}/review                                    |
|  {                                                                            |
|    "decision": "certify",                                                     |
|    "reviewer": "jane.smith@company.com",                                      |
|    "justification": "Required for ERP integration",                           |
|    "next_review_date": "2025-04-15"                                           |
|  }                                                                            |
|                                                                               |
+===============================================================================+
```

### Orphaned Account Detection

```
+===============================================================================+
|                    ORPHANED ACCOUNT IDENTIFICATION                             |
+===============================================================================+
|                                                                               |
|  DETECTION CRITERIA                                                           |
|  ==================                                                           |
|                                                                               |
|  An account is considered "orphaned" if:                                      |
|                                                                               |
|  +-------------------------------------------------------------------------+ |
|  | Criterion                              | Detection Method               | |
|  +----------------------------------------+--------------------------------+ |
|  | Owner no longer employed               | HR system integration          | |
|  | Owner transferred to different role    | HR system integration          | |
|  | Owner unresponsive to attestation      | 2+ missed attestation cycles   | |
|  | No activity for extended period        | > 180 days no authentication   | |
|  | Application decommissioned             | CMDB integration               | |
|  | No documented business purpose         | Missing justification          | |
|  +----------------------------------------+--------------------------------+ |
|                                                                               |
|  AUTOMATED DETECTION QUERY                                                    |
|  =========================                                                    |
|                                                                               |
|  # Find orphaned accounts                                                     |
|  GET /api/v2/accounts?type=service&orphan_indicators=true                     |
|                                                                               |
|  Response:                                                                    |
|  {                                                                            |
|    "status": "success",                                                       |
|    "data": [                                                                  |
|      {                                                                        |
|        "account_id": "acc_001",                                               |
|        "name": "svc_legacy_backup",                                           |
|        "orphan_indicators": [                                                 |
|          {"type": "owner_departed", "date": "2024-06-15"},                    |
|          {"type": "no_activity", "days": 245}                                 |
|        ],                                                                     |
|        "risk_score": 85,                                                      |
|        "recommendation": "investigate_for_decommission"                       |
|      }                                                                        |
|    ]                                                                          |
|  }                                                                            |
|                                                                               |
|  ORPHAN RESOLUTION WORKFLOW                                                   |
|  ==========================                                                   |
|                                                                               |
|    [Orphaned Account Detected]                                                |
|              |                                                                |
|              v                                                                |
|    [Attempt to identify new owner]                                            |
|              |                                                                |
|      +-------+-------+                                                        |
|      |               |                                                        |
|      v               v                                                        |
|  [Owner Found]  [No Owner Found]                                              |
|      |               |                                                        |
|      v               v                                                        |
|  Transfer       [Suspend Account]                                             |
|  Ownership            |                                                       |
|                       v                                                       |
|                 [30-day grace period]                                         |
|                       |                                                       |
|               +-------+-------+                                               |
|               |               |                                               |
|               v               v                                               |
|          [Claimed]      [Unclaimed]                                           |
|               |               |                                               |
|               v               v                                               |
|          Reactivate     Decommission                                          |
|                                                                               |
+===============================================================================+
```

### Unused Account Identification

```
+===============================================================================+
|                    UNUSED ACCOUNT DETECTION                                    |
+===============================================================================+
|                                                                               |
|  ACTIVITY THRESHOLDS                                                          |
|  ===================                                                          |
|                                                                               |
|  +-------------------------------------------------------------------------+ |
|  | Account Type           | Unused Threshold | Action                      | |
|  +------------------------+------------------+-----------------------------+ |
|  | Critical service       | 7 days           | Investigate immediately     | |
|  | Production service     | 30 days          | Contact owner               | |
|  | Non-production service | 90 days          | Flag for review             | |
|  | Legacy/migration       | 30 days          | Prioritize decommission     | |
|  +------------------------+------------------+-----------------------------+ |
|                                                                               |
|  DETECTION QUERY                                                              |
|  ===============                                                              |
|                                                                               |
|  # Find unused service accounts                                               |
|  GET /api/v2/accounts?type=service&last_activity_before=90d                   |
|                                                                               |
|  # Find accounts never used after onboarding                                  |
|  GET /api/v2/accounts?type=service&activity_count=0&created_before=30d        |
|                                                                               |
|  EXCEPTION HANDLING                                                           |
|  ==================                                                           |
|                                                                               |
|  Some accounts may appear unused but are legitimately inactive:               |
|                                                                               |
|  * Disaster recovery accounts (used only during DR)                           |
|  * Seasonal processing (quarterly, annual jobs)                               |
|  * Break-glass emergency accounts                                             |
|                                                                               |
|  These should be tagged with:                                                 |
|  {                                                                            |
|    "usage_pattern": "periodic",                                               |
|    "expected_frequency": "quarterly",                                         |
|    "last_expected_use": "2024-12-31",                                         |
|    "justification": "Year-end financial processing"                           |
|  }                                                                            |
|                                                                               |
+===============================================================================+
```

---

## Account Modification

### Changing Ownership

```
+===============================================================================+
|                    OWNERSHIP TRANSFER PROCEDURE                                |
+===============================================================================+
|                                                                               |
|  TRANSFER WORKFLOW                                                            |
|  =================                                                            |
|                                                                               |
|    [Ownership Transfer Request]                                               |
|              |                                                                |
|              v                                                                |
|    [Verify new owner authorization]                                           |
|              |                                                                |
|              v                                                                |
|    [Current owner acknowledgment]                                             |
|              |                                                                |
|              v                                                                |
|    [Update account metadata]                                                  |
|              |                                                                |
|              v                                                                |
|    [Notify all stakeholders]                                                  |
|              |                                                                |
|              v                                                                |
|    [Update documentation]                                                     |
|              |                                                                |
|              v                                                                |
|    [Log transfer in audit trail]                                              |
|                                                                               |
|  API: OWNERSHIP TRANSFER                                                      |
|  =======================                                                      |
|                                                                               |
|  PATCH /api/v2/accounts/{account_id}                                          |
|  {                                                                            |
|    "metadata": {                                                              |
|      "business_owner": "new.owner@company.com",                               |
|      "technical_owner": "new.tech@company.com",                               |
|      "ownership_transfer_date": "2024-01-15",                                 |
|      "previous_owner": "old.owner@company.com",                               |
|      "transfer_reason": "Employee departure",                                 |
|      "transfer_ticket": "CHG0023456"                                          |
|    }                                                                          |
|  }                                                                            |
|                                                                               |
|  MANDATORY TRANSFER TRIGGERS                                                  |
|  ==========================                                                   |
|                                                                               |
|  * Owner termination                                                          |
|  * Owner department transfer                                                  |
|  * Application ownership change                                               |
|  * Organizational restructuring                                               |
|  * Security incident response                                                 |
|                                                                               |
+===============================================================================+
```

### Updating Permissions

```
+===============================================================================+
|                    PERMISSION MODIFICATION PROCESS                             |
+===============================================================================+
|                                                                               |
|  CHANGE WORKFLOW                                                              |
|  ===============                                                              |
|                                                                               |
|    [Permission Change Request]                                                |
|              |                                                                |
|              v                                                                |
|    +-------------------+                                                      |
|    | Document current  |                                                      |
|    | permissions       |                                                      |
|    +--------+----------+                                                      |
|             |                                                                 |
|             v                                                                 |
|    +-------------------+                                                      |
|    | Impact assessment |   * What systems affected?                           |
|    | and risk review   |   * What is the blast radius?                        |
|    +--------+----------+   * Is this least privilege?                         |
|             |                                                                 |
|             v                                                                 |
|    +-------------------+                                                      |
|    | Approval workflow |   * Owner approval                                   |
|    +--------+----------+   * Security approval (if elevated)                  |
|             |                                                                 |
|             v                                                                 |
|    +-------------------+                                                      |
|    | Implement change  |                                                      |
|    +--------+----------+                                                      |
|             |                                                                 |
|             v                                                                 |
|    +-------------------+                                                      |
|    | Verify and test   |                                                      |
|    +--------+----------+                                                      |
|             |                                                                 |
|             v                                                                 |
|    +-------------------+                                                      |
|    | Update audit log  |                                                      |
|    | and documentation |                                                      |
|    +-------------------+                                                      |
|                                                                               |
|  PERMISSION CHANGE CATEGORIES                                                 |
|  ============================                                                 |
|                                                                               |
|  +-------------------------------------------------------------------------+ |
|  | Change Type           | Approval Required      | Review Period          | |
|  +-----------------------+------------------------+------------------------+ |
|  | Permission elevation  | Security + Owner       | Immediate              | |
|  | Permission reduction  | Owner                  | 24 hours               | |
|  | New system access     | Owner + System Owner   | Per system SLA         | |
|  | Access removal        | Owner                  | Immediate (verify)     | |
|  | Temporary elevation   | Security + Owner       | Time-limited           | |
|  +-----------------------+------------------------+------------------------+ |
|                                                                               |
+===============================================================================+
```

### Credential Regeneration

```
+===============================================================================+
|                    CREDENTIAL REGENERATION PROCEDURES                          |
+===============================================================================+
|                                                                               |
|  REGENERATION TRIGGERS                                                        |
|  =====================                                                        |
|                                                                               |
|  +-------------------------------------------------------------------------+ |
|  | Trigger                        | Priority | Procedure                    | |
|  +--------------------------------+----------+------------------------------+ |
|  | Suspected compromise           | P1       | Emergency rotation           | |
|  | Credential exposure detected   | P1       | Immediate regeneration       | |
|  | Security audit finding         | P2       | Scheduled regeneration       | |
|  | Compliance requirement         | P3       | Planned maintenance window   | |
|  | Technology upgrade             | P3       | Change window                | |
|  | Regular rotation               | P4       | Automated per policy         | |
|  +--------------------------------+----------+------------------------------+ |
|                                                                               |
|  EMERGENCY REGENERATION WORKFLOW                                              |
|  ===============================                                              |
|                                                                               |
|    [Compromise Detected]                                                      |
|              |                                                                |
|              v                                                                |
|    [Suspend account immediately]                                              |
|              |                                                                |
|              v                                                                |
|    [Generate new credentials]                                                 |
|              |                                                                |
|              v                                                                |
|    [Update all dependent systems]                                             |
|              |                                                                |
|              v                                                                |
|    [Verify all integrations]                                                  |
|              |                                                                |
|              v                                                                |
|    [Reactivate account]                                                       |
|              |                                                                |
|              v                                                                |
|    [Document incident]                                                        |
|                                                                               |
|  API: FORCE CREDENTIAL REGENERATION                                           |
|  ==================================                                           |
|                                                                               |
|  POST /api/v2/accounts/{account_id}/regenerate                                |
|  {                                                                            |
|    "reason": "security_incident",                                             |
|    "incident_ticket": "SEC0001234",                                           |
|    "force": true,                                                             |
|    "notify_owners": true,                                                     |
|    "suspend_until_updated": true                                              |
|  }                                                                            |
|                                                                               |
+===============================================================================+
```

---

## Account Decommissioning

### Decommission Workflow

```
+===============================================================================+
|                    DECOMMISSION WORKFLOW                                       |
+===============================================================================+
|                                                                               |
|  DECOMMISSION PROCESS                                                         |
|  ====================                                                         |
|                                                                               |
|    [Decommission Request]                                                     |
|              |                                                                |
|              v                                                                |
|    +-------------------+                                                      |
|    | Validate request  |   * Authorized requestor                             |
|    | and approvals     |   * Business owner approval                          |
|    +--------+----------+   * Security sign-off                                |
|             |                                                                 |
|             v                                                                 |
|    +-------------------+                                                      |
|    | Dependency check  |   * What systems use this account?                   |
|    +--------+----------+   * What will break if disabled?                     |
|             |                                                                 |
|     +-------+-------+                                                         |
|     |               |                                                         |
|     v               v                                                         |
| [No deps]    [Has dependencies]                                               |
|     |               |                                                         |
|     |               v                                                         |
|     |        [Migrate dependencies]                                           |
|     |               |                                                         |
|     +-------+-------+                                                         |
|             |                                                                 |
|             v                                                                 |
|    +-------------------+                                                      |
|    | Disable account   |   * Suspend in PAM                                   |
|    | (soft delete)     |   * Disable on target system                         |
|    +--------+----------+   * Log disable event                                |
|             |                                                                 |
|             v                                                                 |
|    +-------------------+                                                      |
|    | Grace period      |   * 30 days for production                           |
|    | (monitoring)      |   * 7 days for non-production                        |
|    +--------+----------+   * Monitor for access attempts                      |
|             |                                                                 |
|     +-------+-------+                                                         |
|     |               |                                                         |
|     v               v                                                         |
| [No issues]   [Issues detected]                                               |
|     |               |                                                         |
|     |               v                                                         |
|     |        [Rollback/investigate]                                           |
|     |                                                                         |
|     v                                                                         |
|    +-------------------+                                                      |
|    | Permanent delete  |   * Remove from PAM                                  |
|    +--------+----------+   * Delete from target (optional)                    |
|             |                                                                 |
|             v                                                                 |
|    +-------------------+                                                      |
|    | Archive records   |   * Preserve audit trails                            |
|    +-------------------+   * Store for compliance period                      |
|                                                                               |
+===============================================================================+
```

### Credential Revocation

```
+===============================================================================+
|                    CREDENTIAL REVOCATION PROCEDURE                             |
+===============================================================================+
|                                                                               |
|  REVOCATION CHECKLIST                                                         |
|  ====================                                                         |
|                                                                               |
|  [ ] Change/invalidate password on target system                              |
|  [ ] Remove SSH public keys from authorized_keys                              |
|  [ ] Revoke certificates (add to CRL or OCSP)                                 |
|  [ ] Invalidate API tokens                                                    |
|  [ ] Remove from all groups and roles                                         |
|  [ ] Disable account on target system                                         |
|  [ ] Remove from PAM vault                                                    |
|  [ ] Revoke any active sessions                                               |
|  [ ] Clear cached credentials                                                 |
|                                                                               |
|  API: REVOKE CREDENTIALS                                                      |
|  =======================                                                      |
|                                                                               |
|  # Revoke all credentials for account                                         |
|  POST /api/v2/accounts/{account_id}/revoke                                    |
|  {                                                                            |
|    "revoke_password": true,                                                   |
|    "revoke_ssh_keys": true,                                                   |
|    "revoke_certificates": true,                                               |
|    "revoke_api_tokens": true,                                                 |
|    "terminate_active_sessions": true,                                         |
|    "reason": "Account decommissioning",                                       |
|    "ticket": "CHG0034567"                                                     |
|  }                                                                            |
|                                                                               |
|  VERIFICATION                                                                 |
|  ============                                                                 |
|                                                                               |
|  After revocation, verify:                                                    |
|  * Authentication attempts fail                                               |
|  * No active sessions exist                                                   |
|  * Vault entry removed or marked deleted                                      |
|  * Target system shows account disabled                                       |
|                                                                               |
+===============================================================================+
```

### Audit Trail Preservation

```
+===============================================================================+
|                    AUDIT TRAIL RETENTION                                       |
+===============================================================================+
|                                                                               |
|  RETENTION REQUIREMENTS                                                       |
|  =====================                                                        |
|                                                                               |
|  +-------------------------------------------------------------------------+ |
|  | Framework    | Minimum Retention | Recommended      | Notes              | |
|  +--------------+-------------------+------------------+--------------------+ |
|  | SOC 2        | 1 year            | 3 years          | Audit period       | |
|  | PCI-DSS      | 1 year            | 3 years          | Req 10.7           | |
|  | HIPAA        | 6 years           | 7 years          | Administrative     | |
|  | ISO 27001    | 3 years           | 5 years          | Best practice      | |
|  | IEC 62443    | Per contract      | 5 years          | OT systems         | |
|  | GDPR         | Minimum necessary | Documented policy| Data minimization  | |
|  +--------------+-------------------+------------------+--------------------+ |
|                                                                               |
|  PRESERVED DATA                                                               |
|  ==============                                                               |
|                                                                               |
|  +-------------------------------------------------------------------------+ |
|  | Data Type                | Retention Period | Storage Location          | |
|  +--------------------------+------------------+---------------------------+ |
|  | Account creation record  | 7 years          | Compliance archive        | |
|  | Ownership history        | 7 years          | Compliance archive        | |
|  | Permission changes       | 7 years          | Audit database            | |
|  | Rotation history         | 3 years          | PAM database              | |
|  | Checkout/checkin logs    | 3 years          | PAM database              | |
|  | Access attempt logs      | 3 years          | SIEM                      | |
|  | Decommission record      | 7 years          | Compliance archive        | |
|  +--------------------------+------------------+---------------------------+ |
|                                                                               |
|  ARCHIVE PROCEDURE                                                            |
|  =================                                                            |
|                                                                               |
|  # Export account history before deletion                                     |
|  GET /api/v2/accounts/{account_id}/history?include=all                        |
|                                                                               |
|  # Archive to compliance storage                                              |
|  POST /api/v2/archive/accounts                                                |
|  {                                                                            |
|    "account_id": "acc_001",                                                   |
|    "archive_reason": "decommission",                                          |
|    "retention_years": 7,                                                      |
|    "include": [                                                               |
|      "creation_record",                                                       |
|      "ownership_history",                                                     |
|      "permission_history",                                                    |
|      "rotation_history",                                                      |
|      "checkout_history",                                                      |
|      "access_logs",                                                           |
|      "decommission_record"                                                    |
|    ]                                                                          |
|  }                                                                            |
|                                                                               |
+===============================================================================+
```

---

## Compliance and Reporting

### Account Inventory Reports

```
+===============================================================================+
|                    INVENTORY REPORTING                                         |
+===============================================================================+
|                                                                               |
|  STANDARD REPORTS                                                             |
|  ================                                                             |
|                                                                               |
|  1. SERVICE ACCOUNT INVENTORY                                                 |
|  ----------------------------                                                 |
|                                                                               |
|  # Generate complete inventory                                                |
|  GET /api/v2/reports/service-accounts?format=csv                              |
|                                                                               |
|  Report fields:                                                               |
|  * Account name                                                               |
|  * Target system                                                              |
|  * Account type                                                               |
|  * Risk classification                                                        |
|  * Business owner                                                             |
|  * Technical owner                                                            |
|  * Created date                                                               |
|  * Last rotation                                                              |
|  * Last activity                                                              |
|  * Status                                                                     |
|                                                                               |
|  2. ROTATION COMPLIANCE REPORT                                                |
|  -----------------------------                                                |
|                                                                               |
|  GET /api/v2/reports/rotation-compliance?period=monthly                       |
|                                                                               |
|  Report fields:                                                               |
|  * Total accounts                                                             |
|  * Accounts rotated on schedule                                               |
|  * Accounts with failed rotation                                              |
|  * Accounts overdue for rotation                                              |
|  * Compliance percentage                                                      |
|                                                                               |
|  3. ORPHANED ACCOUNTS REPORT                                                  |
|  ---------------------------                                                  |
|                                                                               |
|  GET /api/v2/reports/orphaned-accounts                                        |
|                                                                               |
|  4. ACCESS REVIEW STATUS                                                      |
|  -----------------------                                                      |
|                                                                               |
|  GET /api/v2/reports/access-review-status?period=quarterly                    |
|                                                                               |
+===============================================================================+
```

### Lifecycle Audit Trails

```
+===============================================================================+
|                    LIFECYCLE AUDIT EVENTS                                      |
+===============================================================================+
|                                                                               |
|  EVENT CATEGORIES                                                             |
|  ================                                                             |
|                                                                               |
|  +-------------------------------------------------------------------------+ |
|  | Event Type              | Severity | Retention | SIEM Forward           | |
|  +-------------------------+----------+-----------+------------------------+ |
|  | account.created         | Info     | 7 years   | Yes                    | |
|  | account.onboarded       | Info     | 7 years   | Yes                    | |
|  | account.modified        | Info     | 3 years   | Yes                    | |
|  | account.owner_changed   | Warning  | 7 years   | Yes                    | |
|  | account.permission_changed | Warning | 3 years | Yes                    | |
|  | account.suspended       | Warning  | 3 years   | Yes                    | |
|  | account.disabled        | Info     | 7 years   | Yes                    | |
|  | account.reactivated     | Warning  | 3 years   | Yes                    | |
|  | account.decommissioned  | Info     | 7 years   | Yes                    | |
|  | credential.rotated      | Info     | 3 years   | No                     | |
|  | credential.rotation_failed | Error | 3 years   | Yes                    | |
|  | credential.checkout     | Info     | 3 years   | Yes                    | |
|  | credential.checkin      | Info     | 3 years   | No                     | |
|  | credential.compromised  | Critical | 7 years   | Yes                    | |
|  | attestation.completed   | Info     | 3 years   | No                     | |
|  | attestation.failed      | Warning  | 3 years   | Yes                    | |
|  +-------------------------+----------+-----------+------------------------+ |
|                                                                               |
|  AUDIT LOG QUERY                                                              |
|  ===============                                                              |
|                                                                               |
|  # Get lifecycle events for specific account                                  |
|  GET /api/v2/audit/logs?account_id={id}&event_type=lifecycle                  |
|                                                                               |
|  # Get all high-severity events for service accounts                          |
|  GET /api/v2/audit/logs?account_type=service&severity=high,critical           |
|    &start_date=2024-01-01                                                     |
|                                                                               |
+===============================================================================+
```

### Compliance Evidence

```
+===============================================================================+
|                    COMPLIANCE EVIDENCE GENERATION                              |
+===============================================================================+
|                                                                               |
|  SOC 2 EVIDENCE                                                               |
|  ==============                                                               |
|                                                                               |
|  # CC6.1 - Access control evidence                                            |
|  wabadmin report --type service-account-inventory \                           |
|    --format csv > evidence/soc2/cc6.1-service-accounts.csv                    |
|                                                                               |
|  # CC6.2 - Provisioning evidence                                              |
|  wabadmin audit --filter "event_type=account.created" \                       |
|    --period "audit-period" > evidence/soc2/cc6.2-provisioning.csv             |
|                                                                               |
|  # CC6.3 - Deprovisioning evidence                                            |
|  wabadmin audit --filter "event_type=account.decommissioned" \                |
|    --period "audit-period" > evidence/soc2/cc6.3-deprovisioning.csv           |
|                                                                               |
|  PCI-DSS EVIDENCE                                                             |
|  ================                                                             |
|                                                                               |
|  # Req 8.1.5 - Service account inventory                                      |
|  wabadmin report --type service-accounts --include ownership \                |
|    > evidence/pci/8.1.5-service-accounts.csv                                  |
|                                                                               |
|  # Req 8.2.4 - Password change evidence                                       |
|  wabadmin report --type rotation-history --account-type service \             |
|    --period "audit-period" > evidence/pci/8.2.4-rotation.csv                  |
|                                                                               |
|  ISO 27001 EVIDENCE                                                           |
|  ==================                                                           |
|                                                                               |
|  # A.9.2.3 - Privileged access management                                     |
|  wabadmin report --type privileged-accounts --include permissions \           |
|    > evidence/iso27001/a923-privileged-accounts.csv                           |
|                                                                               |
|  # A.9.2.5 - Access rights review                                             |
|  wabadmin report --type access-review --period quarterly \                    |
|    > evidence/iso27001/a925-access-review.csv                                 |
|                                                                               |
+===============================================================================+
```

---

## Automation

### API-Driven Lifecycle Management

```
+===============================================================================+
|                    LIFECYCLE AUTOMATION API                                    |
+===============================================================================+
|                                                                               |
|  COMPLETE LIFECYCLE AUTOMATION FLOW                                           |
|  ==================================                                           |
|                                                                               |
|  # 1. CREATE SERVICE ACCOUNT                                                  |
|  # --------------------------                                                 |
|  curl -X POST "https://wallix.company.com/api/v2/accounts" \                  |
|    -H "Authorization: Bearer $TOKEN" \                                        |
|    -H "Content-Type: application/json" \                                      |
|    -d '{                                                                      |
|      "name": "svc_app_db_prod",                                               |
|      "device_id": "dev_001",                                                  |
|      "type": "service",                                                       |
|      "credential_type": "password",                                           |
|      "auto_rotate": true,                                                     |
|      "rotation_period_days": 30,                                              |
|      "metadata": {                                                            |
|        "business_owner": "owner@company.com",                                 |
|        "technical_owner": "tech@company.com",                                 |
|        "risk_level": "high",                                                  |
|        "itsm_ticket": "CHG0012345"                                            |
|      }                                                                        |
|    }'                                                                         |
|                                                                               |
|  # 2. CONFIGURE ROTATION POLICY                                               |
|  # -----------------------------                                              |
|  curl -X PATCH "https://wallix.company.com/api/v2/accounts/{id}" \            |
|    -H "Authorization: Bearer $TOKEN" \                                        |
|    -d '{                                                                      |
|      "rotation_policy": {                                                     |
|        "frequency_days": 30,                                                  |
|        "verification_required": true,                                         |
|        "retry_on_failure": true                                               |
|      }                                                                        |
|    }'                                                                         |
|                                                                               |
|  # 3. TRIGGER MANUAL ROTATION                                                 |
|  # --------------------------                                                 |
|  curl -X POST "https://wallix.company.com/api/v2/accounts/{id}/rotate" \      |
|    -H "Authorization: Bearer $TOKEN" \                                        |
|    -d '{"reason": "Security policy requirement"}'                             |
|                                                                               |
|  # 4. CHECK ROTATION STATUS                                                   |
|  # ------------------------                                                   |
|  curl -X GET "https://wallix.company.com/api/v2/accounts/{id}/rotation-status"|
|    -H "Authorization: Bearer $TOKEN"                                          |
|                                                                               |
|  # 5. UPDATE OWNERSHIP                                                        |
|  # -------------------                                                        |
|  curl -X PATCH "https://wallix.company.com/api/v2/accounts/{id}" \            |
|    -H "Authorization: Bearer $TOKEN" \                                        |
|    -d '{                                                                      |
|      "metadata": {                                                            |
|        "business_owner": "new.owner@company.com",                             |
|        "ownership_transfer_date": "2024-01-15"                                |
|      }                                                                        |
|    }'                                                                         |
|                                                                               |
|  # 6. DISABLE ACCOUNT                                                         |
|  # ------------------                                                         |
|  curl -X POST "https://wallix.company.com/api/v2/accounts/{id}/disable" \     |
|    -H "Authorization: Bearer $TOKEN" \                                        |
|    -d '{"reason": "Decommission request", "ticket": "CHG0023456"}'            |
|                                                                               |
|  # 7. DECOMMISSION ACCOUNT                                                    |
|  # -----------------------                                                    |
|  curl -X DELETE "https://wallix.company.com/api/v2/accounts/{id}" \           |
|    -H "Authorization: Bearer $TOKEN" \                                        |
|    -H "X-Archive: true"                                                       |
|                                                                               |
+===============================================================================+
```

### Integration with ITSM

```
+===============================================================================+
|                    ITSM INTEGRATION                                            |
+===============================================================================+
|                                                                               |
|  SERVICENOW INTEGRATION                                                       |
|  ======================                                                       |
|                                                                               |
|  Bi-directional integration with ServiceNow CMDB and Change Management.       |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |  ServiceNow                         WALLIX Bastion                    |   |
|  |  ===========                        ==============                    |   |
|  |                                                                       |   |
|  |  [Change Request]  ----------------> [Create Account]                 |   |
|  |                                              |                        |   |
|  |  [CMDB Update]    <------------------ [Account Created]               |   |
|  |                                              |                        |   |
|  |  [Incident]       <------------------ [Rotation Failed]               |   |
|  |                                              |                        |   |
|  |  [Decom Request]  ----------------> [Disable Account]                 |   |
|  |                                              |                        |   |
|  |  [CMDB Update]    <------------------ [Account Archived]              |   |
|  |                                                                       |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
|  WEBHOOK CONFIGURATION                                                        |
|  =====================                                                        |
|                                                                               |
|  # Configure webhook for lifecycle events                                     |
|  POST /api/v2/webhooks                                                        |
|  {                                                                            |
|    "name": "servicenow_integration",                                          |
|    "url": "https://company.service-now.com/api/now/import/service_account",   |
|    "events": [                                                                |
|      "account.created",                                                       |
|      "account.modified",                                                      |
|      "account.disabled",                                                      |
|      "account.decommissioned",                                                |
|      "credential.rotation_failed"                                             |
|    ],                                                                         |
|    "authentication": {                                                        |
|      "type": "oauth2",                                                        |
|      "client_id": "wallix_integration",                                       |
|      "client_secret_vault_path": "integrations/servicenow"                    |
|    },                                                                         |
|    "payload_format": "servicenow",                                            |
|    "retry_policy": {                                                          |
|      "max_retries": 3,                                                        |
|      "retry_interval_seconds": 60                                             |
|    }                                                                          |
|  }                                                                            |
|                                                                               |
+===============================================================================+
```

### Automated Workflows

```
+===============================================================================+
|                    AUTOMATED WORKFLOW EXAMPLES                                 |
+===============================================================================+
|                                                                               |
|  PYTHON: AUTOMATED ONBOARDING                                                 |
|  ============================                                                 |
|                                                                               |
|  #!/usr/bin/env python3                                                       |
|  """                                                                          |
|  Service Account Lifecycle Automation                                         |
|  Integrates with WALLIX Bastion API for automated management                  |
|  """                                                                          |
|                                                                               |
|  import requests                                                              |
|  import json                                                                  |
|  from datetime import datetime, timedelta                                     |
|                                                                               |
|  class ServiceAccountManager:                                                 |
|      def __init__(self, base_url, api_token):                                 |
|          self.base_url = base_url                                             |
|          self.headers = {                                                     |
|              "Authorization": f"Bearer {api_token}",                          |
|              "Content-Type": "application/json"                               |
|          }                                                                    |
|                                                                               |
|      def create_service_account(self, account_data):                          |
|          """Create and onboard a new service account"""                       |
|          # Create account                                                     |
|          response = requests.post(                                            |
|              f"{self.base_url}/api/v2/accounts",                              |
|              headers=self.headers,                                            |
|              json=account_data                                                |
|          )                                                                    |
|          response.raise_for_status()                                          |
|          account = response.json()["data"]                                    |
|                                                                               |
|          # Configure rotation policy                                          |
|          self.configure_rotation(account["id"], account_data.get("risk_level"))|
|                                                                               |
|          return account                                                       |
|                                                                               |
|      def configure_rotation(self, account_id, risk_level):                    |
|          """Configure rotation based on risk level"""                         |
|          rotation_days = {                                                    |
|              "critical": 7,                                                   |
|              "high": 30,                                                      |
|              "medium": 90,                                                    |
|              "low": 180                                                       |
|          }                                                                    |
|                                                                               |
|          requests.patch(                                                      |
|              f"{self.base_url}/api/v2/accounts/{account_id}",                 |
|              headers=self.headers,                                            |
|              json={                                                           |
|                  "auto_rotate": True,                                         |
|                  "rotation_period_days": rotation_days.get(risk_level, 90)    |
|              }                                                                |
|          )                                                                    |
|                                                                               |
|      def find_orphaned_accounts(self):                                        |
|          """Find accounts with no valid owner"""                              |
|          response = requests.get(                                             |
|              f"{self.base_url}/api/v2/accounts",                              |
|              headers=self.headers,                                            |
|              params={"type": "service", "orphan_indicators": "true"}          |
|          )                                                                    |
|          return response.json()["data"]                                       |
|                                                                               |
|      def find_unused_accounts(self, days=90):                                 |
|          """Find accounts with no activity"""                                 |
|          response = requests.get(                                             |
|              f"{self.base_url}/api/v2/accounts",                              |
|              headers=self.headers,                                            |
|              params={                                                         |
|                  "type": "service",                                           |
|                  "last_activity_before": f"{days}d"                           |
|              }                                                                |
|          )                                                                    |
|          return response.json()["data"]                                       |
|                                                                               |
|      def decommission_account(self, account_id, ticket, reason):              |
|          """Decommission a service account"""                                 |
|          # Disable first                                                      |
|          requests.post(                                                       |
|              f"{self.base_url}/api/v2/accounts/{account_id}/disable",         |
|              headers=self.headers,                                            |
|              json={"reason": reason, "ticket": ticket}                        |
|          )                                                                    |
|                                                                               |
|          # Archive after grace period (would be scheduled)                    |
|          # requests.delete(...)                                               |
|                                                                               |
|      def generate_attestation_report(self):                                   |
|          """Generate quarterly attestation report"""                          |
|          response = requests.get(                                             |
|              f"{self.base_url}/api/v2/reports/access-review",                 |
|              headers=self.headers,                                            |
|              params={"account_type": "service", "period": "quarterly"}        |
|          )                                                                    |
|          return response.json()["data"]                                       |
|                                                                               |
|  # Usage example                                                              |
|  if __name__ == "__main__":                                                   |
|      manager = ServiceAccountManager(                                         |
|          base_url="https://wallix.company.com",                               |
|          api_token="your-api-token"                                           |
|      )                                                                        |
|                                                                               |
|      # Create new service account                                             |
|      new_account = manager.create_service_account({                           |
|          "name": "svc_new_app_prod",                                          |
|          "device_id": "dev_001",                                              |
|          "type": "service",                                                   |
|          "credential_type": "password",                                       |
|          "risk_level": "high",                                                |
|          "metadata": {                                                        |
|              "business_owner": "owner@company.com",                           |
|              "technical_owner": "tech@company.com",                           |
|              "itsm_ticket": "CHG0012345"                                      |
|          }                                                                    |
|      })                                                                       |
|                                                                               |
|      # Find accounts needing attention                                        |
|      orphaned = manager.find_orphaned_accounts()                              |
|      unused = manager.find_unused_accounts(days=90)                           |
|                                                                               |
|      print(f"Orphaned accounts: {len(orphaned)}")                             |
|      print(f"Unused accounts (90+ days): {len(unused)}")                      |
|                                                                               |
+===============================================================================+
```

### Scheduled Automation Tasks

| Task | Schedule | Description |
|------|----------|-------------|
| **Orphan Detection** | Daily | Identify accounts with invalid owners |
| **Unused Detection** | Weekly | Flag accounts with no recent activity |
| **Rotation Compliance** | Daily | Check for overdue rotations |
| **Attestation Reminders** | Weekly | Send pending attestation notifications |
| **Compliance Reports** | Monthly | Generate inventory and compliance reports |
| **Archive Cleanup** | Quarterly | Remove accounts past grace period |

---

## Quick Reference

### Lifecycle Checklist

```
+===============================================================================+
|                    SERVICE ACCOUNT LIFECYCLE CHECKLIST                         |
+===============================================================================+
|                                                                               |
|  CREATION                                                                     |
|  --------                                                                     |
|  [ ] Business justification documented                                        |
|  [ ] Owner assigned (business and technical)                                  |
|  [ ] Risk level classified                                                    |
|  [ ] Naming convention followed                                               |
|  [ ] Minimum permissions defined                                              |
|  [ ] ITSM ticket created                                                      |
|                                                                               |
|  ONBOARDING                                                                   |
|  ----------                                                                   |
|  [ ] Account created in target system                                         |
|  [ ] Credentials securely generated                                           |
|  [ ] Account imported to WALLIX Bastion                                       |
|  [ ] Rotation policy assigned                                                 |
|  [ ] Authorizations configured                                                |
|  [ ] Initial rotation successful                                              |
|                                                                               |
|  OPERATIONS                                                                   |
|  ----------                                                                   |
|  [ ] Rotation occurring on schedule                                           |
|  [ ] Usage being monitored                                                    |
|  [ ] Quarterly attestation completed                                          |
|  [ ] Annual access review completed                                           |
|  [ ] Documentation current                                                    |
|                                                                               |
|  MODIFICATION                                                                 |
|  ------------                                                                 |
|  [ ] Change request submitted                                                 |
|  [ ] Appropriate approvals obtained                                           |
|  [ ] Changes implemented                                                      |
|  [ ] Documentation updated                                                    |
|  [ ] Audit trail preserved                                                    |
|                                                                               |
|  DECOMMISSION                                                                 |
|  ------------                                                                 |
|  [ ] Decommission request approved                                            |
|  [ ] Dependencies migrated                                                    |
|  [ ] Account disabled                                                         |
|  [ ] Grace period observed                                                    |
|  [ ] Credentials revoked                                                      |
|  [ ] Audit trails archived                                                    |
|  [ ] Account removed from PAM                                                 |
|                                                                               |
+===============================================================================+
```

### Key API Endpoints

| Operation | Method | Endpoint |
|-----------|--------|----------|
| Create account | POST | `/api/v2/accounts` |
| Get account | GET | `/api/v2/accounts/{id}` |
| Update account | PATCH | `/api/v2/accounts/{id}` |
| Delete account | DELETE | `/api/v2/accounts/{id}` |
| Rotate credential | POST | `/api/v2/accounts/{id}/rotate` |
| Disable account | POST | `/api/v2/accounts/{id}/disable` |
| Get rotation history | GET | `/api/v2/accounts/{id}/rotation-history` |
| Get checkout history | GET | `/api/v2/accounts/{id}/checkout-history` |
| Generate report | GET | `/api/v2/reports/{report_type}` |
| Query audit logs | GET | `/api/v2/audit/logs` |

---

## Related Documentation

- [07 - Password Management](../07-password-management/README.md) - Credential vault and rotation
- [26 - API Reference](../26-api-reference/README.md) - Complete API documentation
- [33 - Compliance & Audit](../33-compliance-audit/README.md) - Compliance framework mappings
- [53 - Account Discovery](../53-account-discovery/README.md) - Discovering unmanaged accounts

---

## External References

- [WALLIX Documentation Portal](https://pam.wallix.one/documentation)
- [WALLIX REST API Samples](https://github.com/wallix/wbrest_samples)
- [NIST SP 800-53 AC-2: Account Management](https://csrc.nist.gov/publications/detail/sp/800-53/rev-5/final)
- [CIS Controls: Account Management](https://www.cisecurity.org/controls)
