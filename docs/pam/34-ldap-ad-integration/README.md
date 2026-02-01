# 45 - LDAP/Active Directory Integration and Troubleshooting

## Table of Contents

1. [LDAP/AD Overview](#ldapad-overview)
2. [Architecture](#architecture)
3. [LDAP Configuration](#ldap-configuration)
4. [Active Directory Specific Setup](#active-directory-specific-setup)
5. [LDAPS/StartTLS Configuration](#ldapsstarttls-configuration)
6. [User Synchronization](#user-synchronization)
7. [Group Synchronization](#group-synchronization)
8. [Authentication Flow](#authentication-flow)
9. [Troubleshooting Common Issues](#troubleshooting-common-issues)
10. [Diagnostic Tools and Commands](#diagnostic-tools-and-commands)
11. [Performance Tuning](#performance-tuning)

---

## LDAP/AD Overview

### Authentication vs Synchronization

WALLIX Bastion integrates with LDAP/Active Directory through two distinct mechanisms:

| Integration Mode | Description | Use Case |
|------------------|-------------|----------|
| **Authentication** | Pass-through validation of user credentials against directory | Real-time login verification |
| **Synchronization** | Import/update users and groups from directory to WALLIX | Pre-provisioning users, group-based access |

```
+==============================================================================+
|                    LDAP/AD INTEGRATION MODES                                  |
+==============================================================================+
|                                                                               |
|  AUTHENTICATION MODE (Pass-through)                                           |
|  ==================================                                           |
|                                                                               |
|  +--------+     +----------+     +----------+     +-------------+            |
|  |  User  |---->|  WALLIX  |---->|   LDAP   |---->| Credential  |            |
|  | Login  |     | Bastion  |     |  Server  |     | Validation  |            |
|  +--------+     +----------+     +----------+     +-------------+            |
|                      |                                  |                     |
|                      |<---------------------------------+                     |
|                      |      Success/Failure Response                         |
|                                                                               |
|  Benefits:                                                                    |
|  * Single source of truth for passwords                                      |
|  * No password synchronization needed                                        |
|  * Real-time password policy enforcement                                     |
|  * Immediate effect of password changes                                      |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  SYNCHRONIZATION MODE (Import/Update)                                         |
|  =====================================                                        |
|                                                                               |
|  +----------+     +----------+     +-------------+                           |
|  |   LDAP   |---->|  WALLIX  |---->|   Local     |                           |
|  |  Server  |     |   Sync   |     |  Database   |                           |
|  +----------+     +----------+     +-------------+                           |
|                        |                                                      |
|                        |  Scheduled or manual sync                           |
|                        |  - User attributes                                   |
|                        |  - Group membership                                  |
|                        |  - Profile assignment                               |
|                                                                               |
|  Benefits:                                                                    |
|  * Reduced LDAP dependency during sessions                                   |
|  * Group-to-profile automatic mapping                                        |
|  * Offline availability of user data                                         |
|  * Performance optimization for large directories                            |
|                                                                               |
+==============================================================================+
```

### When to Use Each Mode

| Scenario | Recommended Mode | Rationale |
|----------|------------------|-----------|
| Enterprise with centralized AD | Both | Authentication for credentials, sync for provisioning |
| Strict password policies | Authentication | Passwords validated in real-time against AD |
| OT/air-gapped environments | Sync with local fallback | Directory may be unreachable |
| Temporary/contractor access | Authentication only | No need to maintain local copies |
| Complex group hierarchies | Sync | Pre-compute nested group memberships |

---

## Architecture

### WALLIX to LDAP/AD Communication

```
+==============================================================================+
|                    LDAP/AD INTEGRATION ARCHITECTURE                           |
+==============================================================================+
|                                                                               |
|                        ENTERPRISE NETWORK                                     |
|                                                                               |
|   +------------------+          +------------------+                         |
|   |     Domain       |          |     Domain       |                         |
|   |   Controller 1   |          |   Controller 2   |                         |
|   |   (Primary)      |          |   (Secondary)    |                         |
|   |                  |          |                  |                         |
|   | LDAPS: 636      |          | LDAPS: 636      |                         |
|   | GC: 3269        |          | GC: 3269        |                         |
|   +--------+---------+          +--------+---------+                         |
|            |                             |                                    |
|            |     TLS 1.2/1.3            |                                    |
|            |     Encrypted              |                                    |
|            +-------------+---------------+                                    |
|                          |                                                    |
|                          v                                                    |
|   +-----------------------------------------------------------------+        |
|   |                    WALLIX BASTION                                |        |
|   |                                                                  |        |
|   |  +-------------------+   +-------------------+                   |        |
|   |  |  LDAP Connector   |   |  Auth Module      |                   |        |
|   |  |                   |   |                   |                   |        |
|   |  | * Connection pool |   | * Bind validation |                   |        |
|   |  | * Failover logic  |   | * Attribute query |                   |        |
|   |  | * TLS handling    |   | * Group lookup    |                   |        |
|   |  +--------+----------+   +--------+----------+                   |        |
|   |           |                       |                              |        |
|   |           v                       v                              |        |
|   |  +-------------------+   +-------------------+                   |        |
|   |  |  Sync Engine      |   |  Session Manager  |                   |        |
|   |  |                   |   |                   |                   |        |
|   |  | * Scheduled jobs  |   | * User sessions   |                   |        |
|   |  | * Delta updates   |   | * Audit logging   |                   |        |
|   |  | * Conflict res.   |   | * Access control  |                   |        |
|   |  +-------------------+   +-------------------+                   |        |
|   |                                                                  |        |
|   +-----------------------------------------------------------------+        |
|                                                                               |
|   NETWORK REQUIREMENTS                                                        |
|   ====================                                                        |
|                                                                               |
|   +-------------------------------------------------------------------+      |
|   | Protocol  | Port  | Direction          | Description              |      |
|   +-----------+-------+--------------------+--------------------------+      |
|   | LDAPS     | 636   | WALLIX -> DC       | Secure LDAP queries      |      |
|   | LDAP+TLS  | 389   | WALLIX -> DC       | StartTLS LDAP (alt.)     |      |
|   | Global Cat| 3269  | WALLIX -> DC       | Multi-domain queries     |      |
|   | Kerberos  | 88    | WALLIX -> DC       | Optional SSO             |      |
|   | DNS       | 53    | WALLIX -> DNS      | SRV record lookup        |      |
|   +-----------+-------+--------------------+--------------------------+      |
|                                                                               |
+==============================================================================+
```

### High Availability Configuration

```
+==============================================================================+
|                    LDAP HIGH AVAILABILITY                                     |
+==============================================================================+
|                                                                               |
|   PRIMARY SITE                              SECONDARY SITE                    |
|   ============                              ==============                    |
|                                                                               |
|   +----------------+                        +----------------+                |
|   |     DC-01      |<--- AD Replication --->|     DC-03      |                |
|   | ldaps://dc01   |                        | ldaps://dc03   |                |
|   +----------------+                        +----------------+                |
|          |                                          |                         |
|          |                                          |                         |
|   +----------------+                        +----------------+                |
|   |     DC-02      |<--- AD Replication --->|     DC-04      |                |
|   | ldaps://dc02   |                        | ldaps://dc04   |                |
|   +----------------+                        +----------------+                |
|          |                                          |                         |
|          +------------------+-------------------+---+                         |
|                             |                                                 |
|                             v                                                 |
|   +-------------------------------------------------------------+            |
|   |                    WALLIX BASTION                            |            |
|   |                                                              |            |
|   |  LDAP Server Configuration:                                  |            |
|   |  +----------------------------------------------------------+|            |
|   |  | Server 1 (Primary):   ldaps://dc01.corp.company.com:636  ||            |
|   |  | Server 2 (Failover):  ldaps://dc02.corp.company.com:636  ||            |
|   |  | Server 3 (DR Site):   ldaps://dc03.corp.company.com:636  ||            |
|   |  | Server 4 (DR Site):   ldaps://dc04.corp.company.com:636  ||            |
|   |  +----------------------------------------------------------+|            |
|   |                                                              |            |
|   |  Failover Behavior:                                          |            |
|   |  * Try servers in order until successful connection          |            |
|   |  * Connection timeout: 10 seconds per server                 |            |
|   |  * Failed server retry interval: 60 seconds                  |            |
|   |  * Health check interval: 30 seconds                         |            |
|   |                                                              |            |
|   +-------------------------------------------------------------+            |
|                                                                               |
+==============================================================================+
```

---

## LDAP Configuration

### Connection Settings

#### Basic LDAP Configuration

```json
{
  "ldap_domain": {
    "name": "Corporate-AD",
    "description": "Primary Active Directory domain",
    "enabled": true,

    "connection": {
      "servers": [
        {
          "host": "dc01.corp.company.com",
          "port": 636,
          "priority": 1
        },
        {
          "host": "dc02.corp.company.com",
          "port": 636,
          "priority": 2
        }
      ],
      "protocol": "ldaps",
      "timeout_seconds": 30,
      "network_timeout_seconds": 10
    },

    "bind_credentials": {
      "bind_dn": "CN=svc_wallix,OU=Service Accounts,DC=corp,DC=company,DC=com",
      "bind_password": "********"
    },

    "search_settings": {
      "base_dn": "DC=corp,DC=company,DC=com",
      "user_base_dn": "OU=Users,DC=corp,DC=company,DC=com",
      "group_base_dn": "OU=Groups,DC=corp,DC=company,DC=com",
      "scope": "subtree"
    }
  }
}
```

### Bind DN and Credentials

#### Service Account Requirements

| Requirement | Description |
|-------------|-------------|
| **Account Type** | Domain user (not computer account) |
| **Password Policy** | Set to never expire or managed rotation |
| **Permissions** | Read access to user/group objects |
| **OU Membership** | Place in protected service accounts OU |
| **Delegation** | No special delegation required for read-only |

#### Bind DN Formats

```
+==============================================================================+
|                    BIND DN FORMAT EXAMPLES                                    |
+==============================================================================+
|                                                                               |
|  ACTIVE DIRECTORY                                                             |
|  ================                                                             |
|                                                                               |
|  Distinguished Name (preferred):                                              |
|  CN=svc_wallix,OU=Service Accounts,DC=corp,DC=company,DC=com                 |
|                                                                               |
|  User Principal Name (UPN):                                                   |
|  svc_wallix@corp.company.com                                                  |
|                                                                               |
|  Down-level logon name (NTLM style):                                          |
|  CORP\svc_wallix                                                              |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  OPENLDAP                                                                     |
|  ========                                                                     |
|                                                                               |
|  Distinguished Name:                                                          |
|  cn=admin,dc=company,dc=com                                                   |
|                                                                               |
|  uid-based:                                                                   |
|  uid=wallix-bind,ou=services,dc=company,dc=com                               |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  389 DIRECTORY SERVER / RED HAT DIRECTORY                                     |
|  ========================================                                     |
|                                                                               |
|  Distinguished Name:                                                          |
|  uid=wallix-bind,ou=People,dc=company,dc=com                                 |
|                                                                               |
|  Directory Manager (for testing only):                                        |
|  cn=Directory Manager                                                         |
|                                                                               |
+==============================================================================+
```

### Base DN and Search Scope

```json
{
  "search_settings": {
    "base_dn": "DC=corp,DC=company,DC=com",
    "scope": "subtree",

    "ou_restrictions": [
      "OU=Employees,DC=corp,DC=company,DC=com",
      "OU=Contractors,DC=corp,DC=company,DC=com",
      "OU=Admins,DC=corp,DC=company,DC=com"
    ],

    "excluded_ous": [
      "OU=Disabled,DC=corp,DC=company,DC=com",
      "OU=Terminated,DC=corp,DC=company,DC=com"
    ]
  }
}
```

#### Search Scope Options

| Scope | Description | Use Case |
|-------|-------------|----------|
| **base** | Only the base DN object | Lookup specific known DN |
| **onelevel** | Direct children of base DN | Flat OU structure |
| **subtree** | Base DN and all descendants | Most common, full tree search |

### User and Group Filters

#### User Filter Examples

```
+==============================================================================+
|                    LDAP USER FILTER EXAMPLES                                  |
+==============================================================================+
|                                                                               |
|  ACTIVE DIRECTORY                                                             |
|  ================                                                             |
|                                                                               |
|  Basic user lookup by sAMAccountName:                                         |
|  (&(objectClass=user)(sAMAccountName={login}))                               |
|                                                                               |
|  User lookup by UPN:                                                          |
|  (&(objectClass=user)(userPrincipalName={login}))                            |
|                                                                               |
|  Exclude disabled accounts:                                                   |
|  (&(objectClass=user)(sAMAccountName={login})                                |
|    (!(userAccountControl:1.2.840.113556.1.4.803:=2)))                        |
|                                                                               |
|  Exclude disabled and locked accounts:                                        |
|  (&(objectClass=user)(sAMAccountName={login})                                |
|    (!(userAccountControl:1.2.840.113556.1.4.803:=2))                         |
|    (!(lockoutTime>=1)))                                                       |
|                                                                               |
|  Only users in specific group:                                                |
|  (&(objectClass=user)(sAMAccountName={login})                                |
|    (memberOf=CN=PAM-Users,OU=Groups,DC=corp,DC=company,DC=com))              |
|                                                                               |
|  Support both sAMAccountName and UPN:                                         |
|  (&(objectClass=user)(|(sAMAccountName={login})(userPrincipalName={login}))) |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  OPENLDAP                                                                     |
|  ========                                                                     |
|                                                                               |
|  Basic user lookup:                                                           |
|  (&(objectClass=inetOrgPerson)(uid={login}))                                 |
|                                                                               |
|  With posixAccount:                                                           |
|  (&(objectClass=posixAccount)(uid={login}))                                  |
|                                                                               |
|  By email:                                                                    |
|  (&(objectClass=inetOrgPerson)(mail={login}))                                |
|                                                                               |
+==============================================================================+
```

#### Group Filter Examples

```
+==============================================================================+
|                    LDAP GROUP FILTER EXAMPLES                                 |
+==============================================================================+
|                                                                               |
|  ACTIVE DIRECTORY                                                             |
|  ================                                                             |
|                                                                               |
|  All security groups:                                                         |
|  (&(objectClass=group)(groupType:1.2.840.113556.1.4.803:=-2147483646))       |
|                                                                               |
|  Groups with specific prefix:                                                 |
|  (&(objectClass=group)(cn=PAM-*))                                            |
|                                                                               |
|  Groups in specific OU:                                                       |
|  (objectClass=group)                                                          |
|  Base DN: OU=PAM-Groups,DC=corp,DC=company,DC=com                            |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  OPENLDAP                                                                     |
|  ========                                                                     |
|                                                                               |
|  POSIX groups:                                                                |
|  (objectClass=posixGroup)                                                     |
|                                                                               |
|  groupOfNames:                                                                |
|  (objectClass=groupOfNames)                                                   |
|                                                                               |
|  groupOfUniqueNames:                                                          |
|  (objectClass=groupOfUniqueNames)                                             |
|                                                                               |
+==============================================================================+
```

### Attribute Mapping

```json
{
  "attribute_mapping": {
    "user_attributes": {
      "login": "sAMAccountName",
      "display_name": "displayName",
      "email": "mail",
      "first_name": "givenName",
      "last_name": "sn",
      "phone": "telephoneNumber",
      "department": "department",
      "title": "title",
      "manager": "manager",
      "employee_id": "employeeID",
      "groups": "memberOf"
    },

    "group_attributes": {
      "name": "cn",
      "description": "description",
      "members": "member",
      "dn": "distinguishedName"
    }
  }
}
```

#### Common Attribute Mapping Table

| WALLIX Field | Active Directory | OpenLDAP | Description |
|--------------|------------------|----------|-------------|
| login | sAMAccountName | uid | Primary login identifier |
| display_name | displayName | cn | Full display name |
| email | mail | mail | Email address |
| first_name | givenName | givenName | First/given name |
| last_name | sn | sn | Surname/last name |
| groups | memberOf | memberOf | Group memberships |
| phone | telephoneNumber | telephoneNumber | Contact phone |
| department | department | ou | Organizational unit |

---

## Active Directory Specific Setup

### Service Account Requirements

```
+==============================================================================+
|                    AD SERVICE ACCOUNT SETUP                                   |
+==============================================================================+
|                                                                               |
|  STEP 1: Create Service Account                                               |
|  ==============================                                               |
|                                                                               |
|  PowerShell:                                                                  |
|  +------------------------------------------------------------------------+  |
|  | # Create service account                                                |  |
|  | New-ADUser -Name "svc_wallix" `                                         |  |
|  |   -SamAccountName "svc_wallix" `                                        |  |
|  |   -UserPrincipalName "svc_wallix@corp.company.com" `                    |  |
|  |   -Path "OU=Service Accounts,DC=corp,DC=company,DC=com" `               |  |
|  |   -Description "WALLIX Bastion LDAP Bind Account" `                     |  |
|  |   -AccountPassword (ConvertTo-SecureString "P@ssw0rd!" -AsPlain -Force) |  |
|  |   -Enabled $true `                                                      |  |
|  |   -PasswordNeverExpires $true `                                         |  |
|  |   -CannotChangePassword $true                                           |  |
|  +------------------------------------------------------------------------+  |
|                                                                               |
|  STEP 2: Assign Read Permissions                                              |
|  ================================                                             |
|                                                                               |
|  Minimum permissions required:                                                |
|  * Read all user properties                                                  |
|  * Read group membership                                                     |
|  * List contents of OUs                                                      |
|                                                                               |
|  These are granted by default to "Authenticated Users"                       |
|  No additional delegation typically needed for read-only access              |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  STEP 3: Security Recommendations                                             |
|  ==================================                                           |
|                                                                               |
|  +------------------------------------------------------------------------+  |
|  | # Add to Protected Users group (prevents credential caching)            |  |
|  | Add-ADGroupMember -Identity "Protected Users" -Members "svc_wallix"     |  |
|  |                                                                          |  |
|  | # Deny interactive logon (service account protection)                   |  |
|  | # Configure via GPO: "Deny log on locally" and "Deny log on through     |  |
|  | # Remote Desktop Services"                                              |  |
|  |                                                                          |  |
|  | # Set delegation restrictions                                           |  |
|  | Set-ADUser -Identity "svc_wallix" `                                      |  |
|  |   -AccountNotDelegated $true                                            |  |
|  +------------------------------------------------------------------------+  |
|                                                                               |
+==============================================================================+
```

### Group Membership Queries

```
+==============================================================================+
|                    GROUP MEMBERSHIP QUERY STRATEGIES                          |
+==============================================================================+
|                                                                               |
|  DIRECT MEMBERSHIP (Simple)                                                   |
|  ==========================                                                   |
|                                                                               |
|  Query: User's memberOf attribute                                             |
|  Returns: Direct group memberships only                                       |
|                                                                               |
|  LDAP Filter:                                                                 |
|  (&(objectClass=user)(sAMAccountName=jsmith))                                |
|  Attributes: memberOf                                                         |
|                                                                               |
|  Result:                                                                      |
|  memberOf: CN=PAM-Linux-Admins,OU=Groups,DC=corp,DC=company,DC=com           |
|  memberOf: CN=IT-Staff,OU=Groups,DC=corp,DC=company,DC=com                   |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  NESTED MEMBERSHIP (Recursive)                                                |
|  =============================                                                |
|                                                                               |
|  AD supports LDAP_MATCHING_RULE_IN_CHAIN (1.2.840.113556.1.4.1941)           |
|                                                                               |
|  Query all groups (including nested):                                         |
|  (&(objectClass=group)                                                        |
|    (member:1.2.840.113556.1.4.1941:=CN=jsmith,OU=Users,DC=corp,DC=company,DC=com))
|                                                                               |
|  This returns:                                                                |
|  * Direct group memberships                                                  |
|  * Parent groups of those groups                                             |
|  * All ancestor groups in the hierarchy                                      |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  PRIMARY GROUP (Special handling)                                             |
|  ================================                                             |
|                                                                               |
|  The primary group (typically "Domain Users") is NOT in memberOf             |
|  Must be queried separately using primaryGroupID                             |
|                                                                               |
|  User attribute: primaryGroupID = 513 (Domain Users RID)                     |
|                                                                               |
|  To resolve:                                                                  |
|  1. Get user's objectSid                                                     |
|  2. Get user's primaryGroupID                                                |
|  3. Replace last component of objectSid with primaryGroupID                  |
|  4. Search for group with that objectSid                                     |
|                                                                               |
+==============================================================================+
```

### Nested Group Handling

```json
{
  "nested_groups": {
    "enabled": true,
    "method": "ldap_matching_rule",
    "max_depth": 10,
    "cache_ttl_seconds": 300,

    "example_hierarchy": {
      "PAM-All-Admins": {
        "members": ["PAM-Linux-Admins", "PAM-Windows-Admins", "PAM-DB-Admins"]
      },
      "PAM-Linux-Admins": {
        "members": ["jsmith", "alee", "bwilson"]
      }
    },

    "notes": [
      "User jsmith is member of PAM-Linux-Admins (direct)",
      "User jsmith is also member of PAM-All-Admins (nested)",
      "WALLIX can resolve both memberships for authorization"
    ]
  }
}
```

### Multiple Domain/Forest Setup

```
+==============================================================================+
|                    MULTI-DOMAIN CONFIGURATION                                 |
+==============================================================================+
|                                                                               |
|  SINGLE FOREST, MULTIPLE DOMAINS                                              |
|  ================================                                             |
|                                                                               |
|               company.com (Forest Root)                                       |
|                     |                                                         |
|          +----------+----------+                                              |
|          |                     |                                              |
|     corp.company.com      dmz.company.com                                     |
|      (Internal)            (Perimeter)                                        |
|                                                                               |
|  Configuration approach:                                                      |
|  * Use Global Catalog (port 3269) for cross-domain queries                   |
|  * Configure one LDAP domain pointing to GC                                   |
|  * All domains searchable through single connection                          |
|                                                                               |
|  +------------------------------------------------------------------------+  |
|  | Global Catalog Configuration:                                           |  |
|  |                                                                         |  |
|  | Server: gc.company.com:3269 (or any DC with GC role)                    |  |
|  | Base DN: DC=company,DC=com (forest root)                                |  |
|  | Scope: subtree                                                          |  |
|  |                                                                         |  |
|  | User filter (supports both domains):                                    |  |
|  | (&(objectClass=user)                                                    |  |
|  |   (|(sAMAccountName={login})                                            |  |
|  |     (userPrincipalName={login})))                                       |  |
|  +------------------------------------------------------------------------+  |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  MULTIPLE FORESTS (Trust relationship)                                        |
|  =====================================                                        |
|                                                                               |
|     company.com                           partner.com                         |
|     (Primary)                             (Trusted)                           |
|         |                                      |                              |
|         |<-------- Forest Trust -------------->|                              |
|         |                                      |                              |
|                                                                               |
|  Configuration approach:                                                      |
|  * Configure separate LDAP domain for each forest                            |
|  * Users authenticate against their home forest                              |
|  * Use domain prefix for login (e.g., PARTNER\username)                      |
|                                                                               |
|  +------------------------------------------------------------------------+  |
|  | Multiple Domain Configuration:                                          |  |
|  |                                                                         |  |
|  | Domain 1:                                                               |  |
|  |   Name: Company-AD                                                      |  |
|  |   Server: ldaps://dc01.company.com:636                                  |  |
|  |   Base DN: DC=company,DC=com                                            |  |
|  |   User format: COMPANY\{login} or {login}@company.com                   |  |
|  |                                                                         |  |
|  | Domain 2:                                                               |  |
|  |   Name: Partner-AD                                                      |  |
|  |   Server: ldaps://dc01.partner.com:636                                  |  |
|  |   Base DN: DC=partner,DC=com                                            |  |
|  |   User format: PARTNER\{login} or {login}@partner.com                   |  |
|  +------------------------------------------------------------------------+  |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  LOGIN RESOLUTION ORDER                                                       |
|  ======================                                                       |
|                                                                               |
|  When user enters login without domain:                                       |
|  1. Try primary domain (Company-AD) first                                    |
|  2. If not found, try secondary domains in priority order                    |
|  3. Return "user not found" if no match in any domain                        |
|                                                                               |
|  When user enters login with domain:                                          |
|  COMPANY\jsmith -> Query Company-AD only                                      |
|  jsmith@partner.com -> Query Partner-AD only                                  |
|                                                                               |
+==============================================================================+
```

---

## LDAPS/StartTLS Configuration

### Certificate Requirements

```
+==============================================================================+
|                    LDAPS CERTIFICATE REQUIREMENTS                             |
+==============================================================================+
|                                                                               |
|  SERVER CERTIFICATE REQUIREMENTS                                              |
|  ================================                                             |
|                                                                               |
|  The LDAP server (Domain Controller) must have:                              |
|                                                                               |
|  +------------------------------------------------------------------------+  |
|  | Field                | Requirement                                     |  |
|  +----------------------+-----------------------------------------------+  |
|  | Subject/CN           | Server FQDN (dc01.corp.company.com)            |  |
|  | Subject Alt Name     | DNS: dc01.corp.company.com                     |  |
|  |                      | DNS: corp.company.com (optional, for LB)       |  |
|  | Key Usage            | Digital Signature, Key Encipherment            |  |
|  | Extended Key Usage   | Server Authentication (1.3.6.1.5.5.7.3.1)      |  |
|  | Validity             | Check expiration date                           |  |
|  | Chain                | Must chain to trusted CA                        |  |
|  +----------------------+-----------------------------------------------+  |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  ACTIVE DIRECTORY CERTIFICATE SERVICES                                        |
|  =====================================                                        |
|                                                                               |
|  AD CS automatically issues LDAPS certificates to Domain Controllers          |
|  Template: "Domain Controller" or "Domain Controller Authentication"         |
|                                                                               |
|  Verify certificate on DC:                                                    |
|  +------------------------------------------------------------------------+  |
|  | # PowerShell - Check DC certificate                                     |  |
|  | Get-ChildItem Cert:\LocalMachine\My | Where-Object {                    |  |
|  |   $_.EnhancedKeyUsageList -match "Server Authentication"                |  |
|  | } | Format-List Subject, NotAfter, Thumbprint                           |  |
|  +------------------------------------------------------------------------+  |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  COMMON CERTIFICATE ISSUES                                                    |
|  =========================                                                    |
|                                                                               |
|  | Issue                    | Symptom                | Solution             |
|  +--------------------------+------------------------+----------------------+
|  | Certificate expired      | TLS handshake fails   | Renew DC certificate |
|  | Wrong CN/SAN            | Hostname mismatch      | Reissue with correct |
|  |                         | error                  | names                |
|  | Self-signed cert        | Trust validation fails| Add to trust store   |
|  | Missing CA in chain     | Chain verification    | Export full chain    |
|  |                         | fails                  |                      |
|  | Weak signature (SHA1)   | May be rejected       | Reissue with SHA256  |
|  +--------------------------+------------------------+----------------------+
|                                                                               |
+==============================================================================+
```

### Trust Store Configuration

```bash
# Export CA certificate from Domain Controller
# On Windows DC:
# certutil -ca.cert ca_cert.cer
# Or export from AD CS web interface

# Copy to WALLIX Bastion
scp ca_cert.cer admin@bastion:/tmp/

# Convert to PEM format if needed
openssl x509 -inform DER -in /tmp/ca_cert.cer -out /tmp/company-ca.pem

# Add to system trust store (Debian)
sudo cp /tmp/company-ca.pem /usr/local/share/ca-certificates/company-ca.crt
sudo update-ca-certificates

# Verify certificate was added
ls -la /etc/ssl/certs/ | grep company

# Test LDAPS connection with new certificate
openssl s_client -connect dc01.corp.company.com:636 -CApath /etc/ssl/certs/
```

#### WALLIX Trust Store Configuration

```json
{
  "tls_configuration": {
    "ca_certificates": [
      "/etc/ssl/certs/company-ca.pem",
      "/etc/ssl/certs/partner-ca.pem"
    ],

    "certificate_verification": {
      "enabled": true,
      "verify_hostname": true,
      "check_crl": false,
      "check_ocsp": false
    },

    "tls_versions": {
      "min_version": "TLSv1.2",
      "max_version": "TLSv1.3"
    },

    "cipher_suites": [
      "TLS_AES_256_GCM_SHA384",
      "TLS_CHACHA20_POLY1305_SHA256",
      "TLS_AES_128_GCM_SHA256"
    ]
  }
}
```

### Certificate Verification

```bash
# Test LDAPS certificate and chain
echo | openssl s_client -connect dc01.corp.company.com:636 2>/dev/null | \
  openssl x509 -noout -subject -issuer -dates -fingerprint

# Expected output:
# subject=CN = dc01.corp.company.com
# issuer=CN = Company-Root-CA, DC = corp, DC = company, DC = com
# notBefore=Jan  1 00:00:00 2024 GMT
# notAfter=Jan  1 00:00:00 2026 GMT
# SHA256 Fingerprint=AB:CD:EF:12:34...

# Verify full certificate chain
echo | openssl s_client -connect dc01.corp.company.com:636 -showcerts 2>/dev/null | \
  openssl x509 -noout -text | head -30

# Test with specific CA bundle
openssl s_client -connect dc01.corp.company.com:636 \
  -CAfile /etc/ssl/certs/company-ca.pem \
  -verify 5 \
  -verify_return_error

# Check certificate expiration for all DCs
for dc in dc01 dc02 dc03; do
  echo "=== $dc.corp.company.com ==="
  echo | openssl s_client -connect $dc.corp.company.com:636 2>/dev/null | \
    openssl x509 -noout -dates
done
```

### StartTLS Configuration

```json
{
  "ldap_starttls": {
    "connection": {
      "host": "dc01.corp.company.com",
      "port": 389,
      "use_starttls": true,
      "starttls_required": true
    },

    "notes": [
      "StartTLS uses standard LDAP port 389",
      "Connection starts unencrypted, upgrades to TLS",
      "Useful when LDAPS (636) is blocked",
      "Same certificate requirements as LDAPS"
    ]
  }
}
```

---

## User Synchronization

### Import Procedures

```
+==============================================================================+
|                    USER SYNCHRONIZATION PROCESS                               |
+==============================================================================+
|                                                                               |
|  MANUAL IMPORT                                                                |
|  =============                                                                |
|                                                                               |
|  Via Web UI:                                                                  |
|  1. Navigate to Configuration > LDAP Domains                                 |
|  2. Select domain > Actions > Import Users                                   |
|  3. Set import filter (optional)                                             |
|  4. Preview users to be imported                                             |
|  5. Select users and confirm import                                          |
|                                                                               |
|  Via API:                                                                     |
|  +------------------------------------------------------------------------+  |
|  | POST /api/ldapdomains/{domain_id}/import                                |  |
|  |                                                                         |  |
|  | Request:                                                                |  |
|  | {                                                                       |  |
|  |   "filter": "(memberOf=CN=PAM-Users,OU=Groups,DC=corp,DC=company,DC=com)",
|  |   "import_mode": "preview"                                              |  |
|  | }                                                                       |  |
|  |                                                                         |  |
|  | Response:                                                               |  |
|  | {                                                                       |  |
|  |   "users_found": 150,                                                   |  |
|  |   "users_new": 45,                                                      |  |
|  |   "users_existing": 105,                                                |  |
|  |   "preview": [                                                          |  |
|  |     {"login": "jsmith", "display_name": "John Smith", "action": "create"},
|  |     {"login": "alee", "display_name": "Alice Lee", "action": "update"} |  |
|  |   ]                                                                     |  |
|  | }                                                                       |  |
|  +------------------------------------------------------------------------+  |
|                                                                               |
|  Via CLI:                                                                     |
|  +------------------------------------------------------------------------+  |
|  | # Preview import                                                        |  |
|  | wabadmin ldap import --domain Corporate-AD --preview                    |  |
|  |                                                                         |  |
|  | # Import all users from specific group                                  |  |
|  | wabadmin ldap import --domain Corporate-AD \                            |  |
|  |   --filter "(memberOf=CN=PAM-Users,OU=Groups,DC=corp,DC=company,DC=com)"|  |
|  |                                                                         |  |
|  | # Import with automatic profile assignment                              |  |
|  | wabadmin ldap import --domain Corporate-AD \                            |  |
|  |   --default-profile "user" \                                            |  |
|  |   --group-mapping-file /etc/wallix/ldap-group-mapping.json              |  |
|  +------------------------------------------------------------------------+  |
|                                                                               |
+==============================================================================+
```

### Scheduled Sync Setup

```json
{
  "synchronization_schedule": {
    "enabled": true,
    "schedule": {
      "type": "cron",
      "expression": "0 */4 * * *",
      "description": "Every 4 hours"
    },

    "sync_options": {
      "sync_users": true,
      "sync_groups": true,
      "delete_removed_users": false,
      "disable_removed_users": true,
      "update_existing_users": true
    },

    "notifications": {
      "on_completion": true,
      "on_error": true,
      "recipients": ["admin@company.com"]
    }
  }
}
```

### Attribute Mapping Table

| LDAP Attribute | WALLIX Field | Type | Notes |
|----------------|--------------|------|-------|
| sAMAccountName | login | Required | Primary identifier |
| displayName | display_name | Optional | Shown in UI |
| mail | email | Optional | Notifications |
| givenName | first_name | Optional | Profile info |
| sn | last_name | Optional | Profile info |
| telephoneNumber | phone | Optional | Contact |
| department | department | Optional | Organizational |
| title | job_title | Optional | Role info |
| manager | manager_dn | Optional | Hierarchy |
| memberOf | groups | Computed | Group memberships |
| userAccountControl | account_status | Computed | Active/disabled |
| pwdLastSet | password_age | Computed | Password info |

### Conflict Resolution

```
+==============================================================================+
|                    SYNC CONFLICT RESOLUTION                                   |
+==============================================================================+
|                                                                               |
|  CONFLICT TYPES AND RESOLUTION                                                |
|  =============================                                                |
|                                                                               |
|  +------------------------------------------------------------------------+  |
|  | Conflict Type         | Default Action    | Configurable Options       |  |
|  +-----------------------+-------------------+----------------------------+  |
|  | User exists locally   | Skip              | Skip, Update, Merge        |  |
|  | User deleted in LDAP  | Keep local        | Keep, Disable, Delete      |  |
|  | Login conflict        | Keep existing     | Keep existing, Suffix new  |  |
|  | Email conflict        | Skip email        | Skip, Overwrite, Suffix    |  |
|  | Group name conflict   | Rename new        | Rename, Merge, Skip        |  |
|  +-----------------------+-------------------+----------------------------+  |
|                                                                               |
|  Configuration:                                                               |
|  +------------------------------------------------------------------------+  |
|  | {                                                                       |  |
|  |   "conflict_resolution": {                                              |  |
|  |     "user_exists": "update",                                            |  |
|  |     "user_deleted_in_ldap": "disable",                                  |  |
|  |     "login_conflict": "keep_existing",                                  |  |
|  |     "preserve_local_changes": true,                                     |  |
|  |     "protected_attributes": ["profile", "groups"]                       |  |
|  |   }                                                                     |  |
|  | }                                                                       |  |
|  +------------------------------------------------------------------------+  |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  EXAMPLE SCENARIO                                                             |
|  ================                                                             |
|                                                                               |
|  User "jsmith" in LDAP:                                                       |
|    displayName: John Smith                                                    |
|    department: Engineering                                                    |
|                                                                               |
|  User "jsmith" in WALLIX (modified locally):                                  |
|    display_name: John A. Smith                                                |
|    department: IT                                                             |
|    profile: linux-admin (locally assigned)                                    |
|                                                                               |
|  With "update" + "preserve_local_changes":                                    |
|    Result: display_name updated to "John Smith"                              |
|            department updated to "Engineering"                                |
|            profile preserved as "linux-admin"                                 |
|                                                                               |
+==============================================================================+
```

---

## Group Synchronization

### Group to WALLIX Profile Mapping

```json
{
  "group_profile_mapping": [
    {
      "ldap_group_dn": "CN=PAM-SuperAdmins,OU=PAM,OU=Groups,DC=corp,DC=company,DC=com",
      "wallix_profile": "superadmin",
      "priority": 1
    },
    {
      "ldap_group_dn": "CN=PAM-Admins,OU=PAM,OU=Groups,DC=corp,DC=company,DC=com",
      "wallix_profile": "administrator",
      "priority": 2
    },
    {
      "ldap_group_dn": "CN=PAM-Auditors,OU=PAM,OU=Groups,DC=corp,DC=company,DC=com",
      "wallix_profile": "auditor",
      "priority": 3
    },
    {
      "ldap_group_dn": "CN=PAM-Users,OU=PAM,OU=Groups,DC=corp,DC=company,DC=com",
      "wallix_profile": "user",
      "priority": 10
    }
  ],

  "mapping_rules": {
    "multiple_group_behavior": "highest_priority",
    "no_matching_group": "deny_access",
    "default_profile": null
  }
}
```

### Dynamic Group Membership

```
+==============================================================================+
|                    DYNAMIC GROUP MEMBERSHIP                                   |
+==============================================================================+
|                                                                               |
|  WALLIX USER GROUP ASSIGNMENT                                                 |
|  ============================                                                 |
|                                                                               |
|  Option 1: LDAP Group to WALLIX Group Mapping                                |
|                                                                               |
|  +------------------------------------------------------------------------+  |
|  | {                                                                       |  |
|  |   "group_mappings": [                                                   |  |
|  |     {                                                                   |  |
|  |       "ldap_group": "CN=Linux-Admins,OU=Groups,DC=corp,DC=company,DC=com",
|  |       "wallix_group": "linux-servers-access",                           |  |
|  |       "auto_membership": true                                           |  |
|  |     },                                                                  |  |
|  |     {                                                                   |  |
|  |       "ldap_group": "CN=DBA-Team,OU=Groups,DC=corp,DC=company,DC=com",  |  |
|  |       "wallix_group": "database-access",                                |  |
|  |       "auto_membership": true                                           |  |
|  |     }                                                                   |  |
|  |   ]                                                                     |  |
|  | }                                                                       |  |
|  +------------------------------------------------------------------------+  |
|                                                                               |
|  Option 2: Pattern-Based Mapping                                              |
|                                                                               |
|  +------------------------------------------------------------------------+  |
|  | {                                                                       |  |
|  |   "pattern_mappings": [                                                 |  |
|  |     {                                                                   |  |
|  |       "ldap_group_pattern": "CN=PAM-([^,]+),.*",                        |  |
|  |       "wallix_group_template": "pam-$1",                                |  |
|  |       "auto_create_groups": true                                        |  |
|  |     }                                                                   |  |
|  |   ]                                                                     |  |
|  | }                                                                       |  |
|  |                                                                         |  |
|  | Example:                                                                |  |
|  | LDAP: CN=PAM-Linux-Servers,OU=Groups,...                               |  |
|  | WALLIX: pam-Linux-Servers (auto-created)                               |  |
|  +------------------------------------------------------------------------+  |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  REAL-TIME VS SCHEDULED                                                       |
|  ======================                                                       |
|                                                                               |
|  | Mode        | Group membership updated...                              |
|  +-------------+------------------------------------------------------------+
|  | Real-time   | At each user login (query LDAP memberOf)                  |
|  | Scheduled   | During sync jobs only                                     |
|  | Hybrid      | Scheduled sync + real-time verification at login          |
|  +-------------+------------------------------------------------------------+
|                                                                               |
+==============================================================================+
```

---

## Authentication Flow

### Pass-through Authentication

```
+==============================================================================+
|                    LDAP AUTHENTICATION FLOW                                   |
+==============================================================================+
|                                                                               |
|   +--------+     +----------+     +--------+     +-----------+               |
|   |  User  |     |  WALLIX  |     |  LDAP  |     |  Target   |               |
|   |        |     | Bastion  |     | Server |     |  System   |               |
|   +---+----+     +----+-----+     +---+----+     +-----+-----+               |
|       |               |              |                 |                      |
|       | 1. Login      |              |                 |                      |
|       |  (user/pass)  |              |                 |                      |
|       |-------------->|              |                 |                      |
|       |               |              |                 |                      |
|       |               | 2. Search    |                 |                      |
|       |               |    user DN   |                 |                      |
|       |               |------------->|                 |                      |
|       |               |              |                 |                      |
|       |               | 3. User DN   |                 |                      |
|       |               |<-------------|                 |                      |
|       |               |              |                 |                      |
|       |               | 4. Bind      |                 |                      |
|       |               |    (user DN, |                 |                      |
|       |               |     password)|                 |                      |
|       |               |------------->|                 |                      |
|       |               |              |                 |                      |
|       |               | 5. Bind      |                 |                      |
|       |               |    success   |                 |                      |
|       |               |<-------------|                 |                      |
|       |               |              |                 |                      |
|       |               | 6. Fetch     |                 |                      |
|       |               |    groups    |                 |                      |
|       |               |------------->|                 |                      |
|       |               |              |                 |                      |
|       |               | 7. Groups    |                 |                      |
|       |               |<-------------|                 |                      |
|       |               |              |                 |                      |
|       | 8. Auth OK    |              |                 |                      |
|       |<--------------|              |                 |                      |
|       |               |              |                 |                      |
|       | 9. Select     |              |                 |                      |
|       |    target     |              |                 |                      |
|       |-------------->|              |                 |                      |
|       |               |              |                 |                      |
|       |               | 10. Get credentials from vault |                      |
|       |               |-------------------------------->                      |
|       |               |                                                       |
|       |               | 11. Connect  |                 |                      |
|       |               |-------------------------------->|                      |
|       |               |              |                 |                      |
|       | 12. Session   |              |                 |                      |
|       |     started   |              |                 |                      |
|       |<--------------|              |                 |                      |
|                                                                               |
+==============================================================================+
```

### Local Fallback Configuration

```json
{
  "authentication_fallback": {
    "enabled": true,
    "fallback_order": ["ldap", "local"],

    "ldap_failure_conditions": [
      "connection_timeout",
      "server_unavailable",
      "bind_failure"
    ],

    "local_fallback_users": [
      "admin",
      "emergency",
      "breakglass"
    ],

    "fallback_logging": {
      "log_fallback_events": true,
      "alert_on_fallback": true
    },

    "notes": [
      "Local fallback activates only when LDAP is unreachable",
      "Invalid LDAP credentials do NOT trigger fallback",
      "Emergency accounts should have strong MFA"
    ]
  }
}
```

---

## Troubleshooting Common Issues

### Connection Refused/Timeout

```
+==============================================================================+
|                    CONNECTION REFUSED / TIMEOUT                               |
+==============================================================================+
|                                                                               |
|  SYMPTOMS                                                                     |
|  ========                                                                     |
|  * "Connection refused" error in logs                                        |
|  * "Connection timed out" after 30 seconds                                   |
|  * LDAP authentication fails for all users                                   |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  DIAGNOSTIC STEPS                                                             |
|  ================                                                             |
|                                                                               |
|  Step 1: Test basic connectivity                                              |
|  +------------------------------------------------------------------------+  |
|  | # Test TCP connectivity to LDAPS port                                   |  |
|  | nc -zv dc01.corp.company.com 636                                        |  |
|  |                                                                         |  |
|  | # Expected output:                                                      |  |
|  | Connection to dc01.corp.company.com 636 port [tcp/ldaps] succeeded!     |  |
|  |                                                                         |  |
|  | # If failed, check:                                                     |  |
|  | # 1. DNS resolution                                                     |  |
|  | nslookup dc01.corp.company.com                                          |  |
|  |                                                                         |  |
|  | # 2. Network routing                                                    |  |
|  | traceroute dc01.corp.company.com                                        |  |
|  |                                                                         |  |
|  | # 3. Firewall rules                                                     |  |
|  | # Check local firewall                                                  |  |
|  | iptables -L -n | grep 636                                               |  |
|  +------------------------------------------------------------------------+  |
|                                                                               |
|  Step 2: Test LDAPS connection with OpenSSL                                   |
|  +------------------------------------------------------------------------+  |
|  | openssl s_client -connect dc01.corp.company.com:636                     |  |
|  |                                                                         |  |
|  | # Should show certificate chain and "Verify return code: 0 (ok)"        |  |
|  +------------------------------------------------------------------------+  |
|                                                                               |
|  Step 3: Check WALLIX logs                                                    |
|  +------------------------------------------------------------------------+  |
|  | grep -i "ldap" /var/log/wabengine/wabengine.log | tail -50              |  |
|  |                                                                         |  |
|  | # Look for:                                                             |  |
|  | # - "Connection refused"                                                |  |
|  | # - "Connection timed out"                                              |  |
|  | # - "No route to host"                                                  |  |
|  +------------------------------------------------------------------------+  |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  COMMON CAUSES AND SOLUTIONS                                                  |
|  ===========================                                                  |
|                                                                               |
|  | Cause                        | Solution                                 |
|  +------------------------------+------------------------------------------+
|  | Firewall blocking port 636   | Open port in network/host firewall      |
|  | DNS resolution failure       | Add DNS entry or use IP address         |
|  | Wrong port configured        | Verify LDAPS=636, LDAP+StartTLS=389     |
|  | LDAPS not enabled on DC      | Enable LDAPS on Domain Controller       |
|  | Network routing issue        | Check routing tables and VPN            |
|  | Server overloaded            | Use multiple servers, load balance      |
|  +------------------------------+------------------------------------------+
|                                                                               |
+==============================================================================+
```

### Invalid Credentials

```
+==============================================================================+
|                    INVALID CREDENTIALS                                        |
+==============================================================================+
|                                                                               |
|  SYMPTOMS                                                                     |
|  ========                                                                     |
|  * "Invalid credentials" error on login                                      |
|  * "Bind failed" in WALLIX logs                                              |
|  * Works for some users, not others                                          |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  DIAGNOSTIC STEPS                                                             |
|  ================                                                             |
|                                                                               |
|  Step 1: Test bind credentials                                                |
|  +------------------------------------------------------------------------+  |
|  | # Test WALLIX service account bind                                      |  |
|  | ldapsearch -x -H ldaps://dc01.corp.company.com:636 \                    |  |
|  |   -D "CN=svc_wallix,OU=Service Accounts,DC=corp,DC=company,DC=com" \    |  |
|  |   -W \                                                                  |  |
|  |   -b "DC=corp,DC=company,DC=com" \                                      |  |
|  |   "(objectClass=user)" \                                                |  |
|  |   sAMAccountName -s base                                                |  |
|  |                                                                         |  |
|  | # Enter password when prompted                                          |  |
|  | # If fails: service account password incorrect or expired               |  |
|  +------------------------------------------------------------------------+  |
|                                                                               |
|  Step 2: Test user bind (simulates user authentication)                       |
|  +------------------------------------------------------------------------+  |
|  | # Find user's DN first                                                  |  |
|  | ldapsearch -x -H ldaps://dc01.corp.company.com:636 \                    |  |
|  |   -D "CN=svc_wallix,OU=Service Accounts,DC=corp,DC=company,DC=com" \    |  |
|  |   -W \                                                                  |  |
|  |   -b "DC=corp,DC=company,DC=com" \                                      |  |
|  |   "(sAMAccountName=jsmith)" \                                           |  |
|  |   dn                                                                    |  |
|  |                                                                         |  |
|  | # Output: dn: CN=John Smith,OU=Users,DC=corp,DC=company,DC=com          |  |
|  |                                                                         |  |
|  | # Now test bind with user's DN and password                             |  |
|  | ldapsearch -x -H ldaps://dc01.corp.company.com:636 \                    |  |
|  |   -D "CN=John Smith,OU=Users,DC=corp,DC=company,DC=com" \               |  |
|  |   -W \                                                                  |  |
|  |   -b "DC=corp,DC=company,DC=com" \                                      |  |
|  |   "(objectClass=*)" -s base                                             |  |
|  +------------------------------------------------------------------------+  |
|                                                                               |
|  Step 3: Check account status in AD                                           |
|  +------------------------------------------------------------------------+  |
|  | # PowerShell on DC                                                      |  |
|  | Get-ADUser -Identity jsmith -Properties * | Select-Object `             |  |
|  |   Enabled, LockedOut, PasswordExpired, PasswordLastSet,                 |  |
|  |   AccountExpirationDate, userAccountControl                             |  |
|  +------------------------------------------------------------------------+  |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  COMMON CAUSES AND SOLUTIONS                                                  |
|  ===========================                                                  |
|                                                                               |
|  | Cause                        | Solution                                 |
|  +------------------------------+------------------------------------------+
|  | Password expired             | User must reset password in AD          |
|  | Account locked               | Unlock in AD, check lockout policy      |
|  | Account disabled             | Enable account in AD                    |
|  | Service account pwd expired  | Update WALLIX LDAP config with new pwd  |
|  | Wrong Bind DN format         | Use full DN, not sAMAccountName         |
|  | Case sensitivity             | Check if LDAP is case-sensitive         |
|  +------------------------------+------------------------------------------+
|                                                                               |
+==============================================================================+
```

### User Not Found

```
+==============================================================================+
|                    USER NOT FOUND                                             |
+==============================================================================+
|                                                                               |
|  SYMPTOMS                                                                     |
|  ========                                                                     |
|  * "User not found in directory" error                                       |
|  * User exists in AD but cannot authenticate                                 |
|  * Some users work, others don't                                             |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  DIAGNOSTIC STEPS                                                             |
|  ================                                                             |
|                                                                               |
|  Step 1: Verify user exists in LDAP                                           |
|  +------------------------------------------------------------------------+  |
|  | ldapsearch -x -H ldaps://dc01.corp.company.com:636 \                    |  |
|  |   -D "CN=svc_wallix,OU=Service Accounts,DC=corp,DC=company,DC=com" \    |  |
|  |   -W \                                                                  |  |
|  |   -b "DC=corp,DC=company,DC=com" \                                      |  |
|  |   "(sAMAccountName=jsmith)"                                             |  |
|  |                                                                         |  |
|  | # If no results: user doesn't exist or is in different location         |  |
|  +------------------------------------------------------------------------+  |
|                                                                               |
|  Step 2: Check user's actual location                                         |
|  +------------------------------------------------------------------------+  |
|  | # Search entire directory for user                                      |  |
|  | ldapsearch -x -H ldaps://dc01.corp.company.com:636 \                    |  |
|  |   -D "CN=svc_wallix,OU=Service Accounts,DC=corp,DC=company,DC=com" \    |  |
|  |   -W \                                                                  |  |
|  |   -b "DC=corp,DC=company,DC=com" \                                      |  |
|  |   "(sAMAccountName=jsmith)" \                                           |  |
|  |   dn                                                                    |  |
|  |                                                                         |  |
|  | # Compare with configured Base DN in WALLIX                             |  |
|  +------------------------------------------------------------------------+  |
|                                                                               |
|  Step 3: Test with WALLIX user filter                                         |
|  +------------------------------------------------------------------------+  |
|  | # Get the exact filter from WALLIX configuration                        |  |
|  | # Example filter: (&(objectClass=user)(sAMAccountName={login}))         |  |
|  |                                                                         |  |
|  | ldapsearch -x -H ldaps://dc01.corp.company.com:636 \                    |  |
|  |   -D "CN=svc_wallix,OU=Service Accounts,DC=corp,DC=company,DC=com" \    |  |
|  |   -W \                                                                  |  |
|  |   -b "OU=Users,DC=corp,DC=company,DC=com" \                             |  |
|  |   "(&(objectClass=user)(sAMAccountName=jsmith))"                        |  |
|  +------------------------------------------------------------------------+  |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  COMMON CAUSES AND SOLUTIONS                                                  |
|  ===========================                                                  |
|                                                                               |
|  | Cause                        | Solution                                 |
|  +------------------------------+------------------------------------------+
|  | User in wrong OU             | Expand Base DN or add OU to search      |
|  | Base DN too restrictive      | Use broader Base DN (e.g., domain root) |
|  | Search scope is "onelevel"   | Change to "subtree" for nested OUs      |
|  | User filter excludes user    | Check filter logic (disabled check?)    |
|  | Wrong login attribute        | Verify sAMAccountName vs UPN vs uid     |
|  | Case mismatch                | Try exact case as in AD                 |
|  | Child domain user            | Use Global Catalog or add domain config |
|  +------------------------------+------------------------------------------+
|                                                                               |
+==============================================================================+
```

### Group Membership Not Updating

```
+==============================================================================+
|                    GROUP MEMBERSHIP NOT UPDATING                              |
+==============================================================================+
|                                                                               |
|  SYMPTOMS                                                                     |
|  ========                                                                     |
|  * User added to AD group but no access in WALLIX                           |
|  * User removed from AD group but still has access                           |
|  * Group mappings not applied to new group members                           |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  DIAGNOSTIC STEPS                                                             |
|  ================                                                             |
|                                                                               |
|  Step 1: Verify group membership in AD                                        |
|  +------------------------------------------------------------------------+  |
|  | ldapsearch -x -H ldaps://dc01.corp.company.com:636 \                    |  |
|  |   -D "CN=svc_wallix,OU=Service Accounts,DC=corp,DC=company,DC=com" \    |  |
|  |   -W \                                                                  |  |
|  |   -b "DC=corp,DC=company,DC=com" \                                      |  |
|  |   "(sAMAccountName=jsmith)" \                                           |  |
|  |   memberOf                                                              |  |
|  |                                                                         |  |
|  | # Output should list all direct group memberships                       |  |
|  +------------------------------------------------------------------------+  |
|                                                                               |
|  Step 2: Check for nested group membership                                    |
|  +------------------------------------------------------------------------+  |
|  | # Query with LDAP_MATCHING_RULE_IN_CHAIN for nested groups              |  |
|  | ldapsearch -x -H ldaps://dc01.corp.company.com:636 \                    |  |
|  |   -D "CN=svc_wallix,OU=Service Accounts,DC=corp,DC=company,DC=com" \    |  |
|  |   -W \                                                                  |  |
|  |   -b "DC=corp,DC=company,DC=com" \                                      |  |
|  |   "(&(objectClass=group)(member:1.2.840.113556.1.4.1941:=CN=John Smith,OU=Users,DC=corp,DC=company,DC=com))" \
|  |   cn                                                                    |  |
|  +------------------------------------------------------------------------+  |
|                                                                               |
|  Step 3: Force synchronization                                                |
|  +------------------------------------------------------------------------+  |
|  | # Via CLI                                                               |  |
|  | wabadmin ldap sync --domain Corporate-AD --user jsmith                  |  |
|  |                                                                         |  |
|  | # Via API                                                               |  |
|  | curl -X POST https://bastion/api/ldapdomains/Corporate-AD/sync \        |  |
|  |   -H "Authorization: Bearer $TOKEN" \                                   |  |
|  |   -H "Content-Type: application/json" \                                 |  |
|  |   -d '{"users": ["jsmith"]}'                                            |  |
|  +------------------------------------------------------------------------+  |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  COMMON CAUSES AND SOLUTIONS                                                  |
|  ===========================                                                  |
|                                                                               |
|  | Cause                        | Solution                                 |
|  +------------------------------+------------------------------------------+
|  | Sync not run yet             | Run manual sync or wait for scheduled   |
|  | Group mapping misconfigured  | Verify exact DN match in mapping        |
|  | Nested groups not enabled    | Enable nested group resolution          |
|  | Cache stale                  | Clear LDAP cache, re-sync user          |
|  | User needs re-login          | User logout/login for new groups        |
|  | AD replication delay         | Wait for AD replication (15-60 min)     |
|  +------------------------------+------------------------------------------+
|                                                                               |
+==============================================================================+
```

### Certificate Errors

```
+==============================================================================+
|                    CERTIFICATE ERRORS                                         |
+==============================================================================+
|                                                                               |
|  COMMON ERROR MESSAGES                                                        |
|  =====================                                                        |
|                                                                               |
|  * "certificate verify failed"                                               |
|  * "unable to get local issuer certificate"                                  |
|  * "certificate has expired"                                                 |
|  * "hostname mismatch"                                                       |
|  * "self signed certificate in certificate chain"                            |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  DIAGNOSTIC STEPS                                                             |
|  ================                                                             |
|                                                                               |
|  Step 1: Check certificate details                                            |
|  +------------------------------------------------------------------------+  |
|  | echo | openssl s_client -connect dc01.corp.company.com:636 2>/dev/null | \
|  |   openssl x509 -noout -subject -issuer -dates -checkend 86400           |  |
|  |                                                                         |  |
|  | # Output:                                                               |  |
|  | # subject=CN = dc01.corp.company.com                                    |  |
|  | # issuer=CN = Corp-Root-CA, DC = corp, DC = company, DC = com           |  |
|  | # notBefore=Jan  1 00:00:00 2024 GMT                                    |  |
|  | # notAfter=Dec 31 23:59:59 2025 GMT                                     |  |
|  | # Certificate will not expire (within 86400 seconds)                    |  |
|  +------------------------------------------------------------------------+  |
|                                                                               |
|  Step 2: Verify certificate chain                                             |
|  +------------------------------------------------------------------------+  |
|  | echo | openssl s_client -connect dc01.corp.company.com:636 \            |  |
|  |   -showcerts 2>/dev/null                                                |  |
|  |                                                                         |  |
|  | # Should show complete chain:                                           |  |
|  | # Certificate 0: Server cert (dc01.corp.company.com)                    |  |
|  | # Certificate 1: Intermediate CA (if any)                               |  |
|  | # Certificate 2: Root CA                                                |  |
|  +------------------------------------------------------------------------+  |
|                                                                               |
|  Step 3: Test with CA certificate                                             |
|  +------------------------------------------------------------------------+  |
|  | echo | openssl s_client -connect dc01.corp.company.com:636 \            |  |
|  |   -CAfile /etc/ssl/certs/company-ca.pem \                               |  |
|  |   -verify_return_error 2>&1 | grep -E "(Verify|error)"                  |  |
|  |                                                                         |  |
|  | # Should show: Verify return code: 0 (ok)                               |  |
|  +------------------------------------------------------------------------+  |
|                                                                               |
|  Step 4: Check hostname matching                                              |
|  +------------------------------------------------------------------------+  |
|  | echo | openssl s_client -connect dc01.corp.company.com:636 2>/dev/null | \
|  |   openssl x509 -noout -text | grep -A1 "Subject Alternative Name"       |  |
|  |                                                                         |  |
|  | # Should include the hostname you're connecting to                      |  |
|  +------------------------------------------------------------------------+  |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  SOLUTIONS BY ERROR TYPE                                                      |
|  ========================                                                     |
|                                                                               |
|  | Error                        | Solution                                 |
|  +------------------------------+------------------------------------------+
|  | "unable to get local issuer" | Add CA cert to /usr/local/share/        |
|  |                              | ca-certificates/ and run update-ca-certs|
|  | "certificate has expired"    | Renew certificate on Domain Controller  |
|  | "hostname mismatch"          | Use FQDN matching cert, or add SAN      |
|  | "self signed certificate"    | Add self-signed cert to trust store     |
|  | "certificate signature fail" | Check for TLS version mismatch          |
|  +------------------------------+------------------------------------------+
|                                                                               |
+==============================================================================+
```

### Special Characters in Usernames

```
+==============================================================================+
|                    SPECIAL CHARACTERS IN USERNAMES                            |
+==============================================================================+
|                                                                               |
|  PROBLEMATIC CHARACTERS                                                       |
|  ======================                                                       |
|                                                                               |
|  | Character | Issue                      | LDAP Escape Sequence           |
|  +-----------+----------------------------+--------------------------------+
|  | \         | Escape character           | \\                             |
|  | *         | Wildcard                   | \2a                            |
|  | (         | Filter syntax              | \28                            |
|  | )         | Filter syntax              | \29                            |
|  | NUL       | String terminator          | \00                            |
|  | /         | DN separator               | \2f                            |
|  | ,         | DN component separator     | \,                             |
|  | +         | Multi-valued RDN           | \+                             |
|  | "         | Quoted string              | \"                             |
|  | <         | Distinguished name         | \<                             |
|  | >         | Distinguished name         | \>                             |
|  | ;         | Attribute separator        | \;                             |
|  | #         | Start of comment           | \#                             |
|  +-----------+----------------------------+--------------------------------+
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  EXAMPLE: User with special characters                                        |
|                                                                               |
|  Username in AD: O'Connor, Mary (Dept)                                        |
|  sAMAccountName: moconnor                                                     |
|  DN: CN=O'Connor\, Mary (Dept),OU=Users,DC=corp,DC=company,DC=com            |
|                                                                               |
|  Filter for this user:                                                        |
|  (sAMAccountName=moconnor)  <- Use sAMAccountName, not CN                    |
|                                                                               |
|  If you must search by CN:                                                    |
|  (cn=O'Connor\2c Mary \28Dept\29)                                            |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  BEST PRACTICES                                                               |
|  ==============                                                               |
|                                                                               |
|  1. Use sAMAccountName for searches (alphanumeric, no spaces)                |
|  2. Let WALLIX handle escaping in user filters                               |
|  3. Avoid special characters in sAMAccountName when possible                 |
|  4. Test authentication with special character usernames after setup         |
|                                                                               |
+==============================================================================+
```

### Encoding Issues (UTF-8)

```
+==============================================================================+
|                    ENCODING ISSUES (UTF-8)                                    |
+==============================================================================+
|                                                                               |
|  SYMPTOMS                                                                     |
|  ========                                                                     |
|  * Non-ASCII characters display as garbage                                   |
|  * Users with accented names can't authenticate                              |
|  * Search returns no results for names with umlauts, accents, etc.          |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  COMMON SCENARIOS                                                             |
|  ================                                                             |
|                                                                               |
|  Affected names:                                                              |
|  * François, José, Müller, Björk, Søren                                       |
|  * Japanese: 田中, Chinese: 张伟, Korean: 김철수                               |
|  * Cyrillic: Иванов, Arabic: محمد                                            |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  DIAGNOSTIC STEPS                                                             |
|  ================                                                             |
|                                                                               |
|  Step 1: Verify LDAP returns UTF-8                                            |
|  +------------------------------------------------------------------------+  |
|  | # Search for user with non-ASCII name                                   |  |
|  | LANG=en_US.UTF-8 ldapsearch -x -H ldaps://dc01.corp.company.com:636 \   |  |
|  |   -D "CN=svc_wallix,OU=Service Accounts,DC=corp,DC=company,DC=com" \    |  |
|  |   -W \                                                                  |  |
|  |   -b "DC=corp,DC=company,DC=com" \                                      |  |
|  |   "(sAMAccountName=fmuller)" \                                          |  |
|  |   displayName cn                                                        |  |
|  |                                                                         |  |
|  | # Should show: displayName: François Müller                             |  |
|  +------------------------------------------------------------------------+  |
|                                                                               |
|  Step 2: Check terminal/shell encoding                                        |
|  +------------------------------------------------------------------------+  |
|  | # Verify locale settings                                                |  |
|  | locale                                                                  |  |
|  |                                                                         |  |
|  | # Should show UTF-8:                                                    |  |
|  | # LANG=en_US.UTF-8                                                      |  |
|  | # LC_ALL=en_US.UTF-8                                                    |  |
|  |                                                                         |  |
|  | # If not UTF-8, set it:                                                 |  |
|  | export LANG=en_US.UTF-8                                                 |  |
|  | export LC_ALL=en_US.UTF-8                                               |  |
|  +------------------------------------------------------------------------+  |
|                                                                               |
|  Step 3: Verify WALLIX encoding configuration                                 |
|  +------------------------------------------------------------------------+  |
|  | # Check LDAP domain configuration                                       |  |
|  | wabadmin ldap show Corporate-AD | grep -i encoding                      |  |
|  |                                                                         |  |
|  | # Should be UTF-8 (default)                                             |  |
|  +------------------------------------------------------------------------+  |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  SOLUTIONS                                                                    |
|  =========                                                                    |
|                                                                               |
|  | Issue                        | Solution                                 |
|  +------------------------------+------------------------------------------+
|  | Display garbled in UI        | Check browser encoding (UTF-8)          |
|  | Search fails for non-ASCII   | Ensure filter uses UTF-8 encoding       |
|  | Import truncates names       | Verify database supports UTF-8          |
|  | Logs show encoding errors    | Set LANG=en_US.UTF-8 in service config  |
|  +------------------------------+------------------------------------------+
|                                                                               |
+==============================================================================+
```

---

## Diagnostic Tools and Commands

### ldapsearch Examples

```bash
# Basic user search
ldapsearch -x -H ldaps://dc01.corp.company.com:636 \
  -D "CN=svc_wallix,OU=Service Accounts,DC=corp,DC=company,DC=com" \
  -W \
  -b "DC=corp,DC=company,DC=com" \
  "(sAMAccountName=jsmith)"

# Search with specific attributes
ldapsearch -x -H ldaps://dc01.corp.company.com:636 \
  -D "CN=svc_wallix,OU=Service Accounts,DC=corp,DC=company,DC=com" \
  -W \
  -b "DC=corp,DC=company,DC=com" \
  "(sAMAccountName=jsmith)" \
  sAMAccountName displayName mail memberOf userAccountControl

# Count all users
ldapsearch -x -H ldaps://dc01.corp.company.com:636 \
  -D "CN=svc_wallix,OU=Service Accounts,DC=corp,DC=company,DC=com" \
  -W \
  -b "DC=corp,DC=company,DC=com" \
  "(&(objectClass=user)(objectCategory=person))" \
  dn | grep -c "^dn:"

# Find all groups a user belongs to (including nested)
ldapsearch -x -H ldaps://dc01.corp.company.com:636 \
  -D "CN=svc_wallix,OU=Service Accounts,DC=corp,DC=company,DC=com" \
  -W \
  -b "DC=corp,DC=company,DC=com" \
  "(&(objectClass=group)(member:1.2.840.113556.1.4.1941:=CN=John Smith,OU=Users,DC=corp,DC=company,DC=com))" \
  cn

# Find disabled accounts
ldapsearch -x -H ldaps://dc01.corp.company.com:636 \
  -D "CN=svc_wallix,OU=Service Accounts,DC=corp,DC=company,DC=com" \
  -W \
  -b "DC=corp,DC=company,DC=com" \
  "(&(objectClass=user)(userAccountControl:1.2.840.113556.1.4.803:=2))" \
  sAMAccountName

# Find locked accounts
ldapsearch -x -H ldaps://dc01.corp.company.com:636 \
  -D "CN=svc_wallix,OU=Service Accounts,DC=corp,DC=company,DC=com" \
  -W \
  -b "DC=corp,DC=company,DC=com" \
  "(&(objectClass=user)(lockoutTime>=1))" \
  sAMAccountName lockoutTime

# Search with paging (for large directories)
ldapsearch -x -H ldaps://dc01.corp.company.com:636 \
  -D "CN=svc_wallix,OU=Service Accounts,DC=corp,DC=company,DC=com" \
  -W \
  -b "DC=corp,DC=company,DC=com" \
  -E pr=500/noprompt \
  "(objectClass=user)" \
  sAMAccountName

# Test StartTLS connection
ldapsearch -x -H ldap://dc01.corp.company.com:389 \
  -ZZ \
  -D "CN=svc_wallix,OU=Service Accounts,DC=corp,DC=company,DC=com" \
  -W \
  -b "DC=corp,DC=company,DC=com" \
  "(sAMAccountName=jsmith)"
```

### Connection Testing

```bash
# Test TCP connectivity
nc -zv dc01.corp.company.com 636

# Test with timeout
timeout 5 bash -c 'echo > /dev/tcp/dc01.corp.company.com/636' && echo "Connected" || echo "Failed"

# Test TLS handshake
echo | openssl s_client -connect dc01.corp.company.com:636 -brief

# Test with specific TLS version
echo | openssl s_client -connect dc01.corp.company.com:636 -tls1_2

# Test certificate chain
echo | openssl s_client -connect dc01.corp.company.com:636 \
  -CAfile /etc/ssl/certs/company-ca.pem \
  -verify_return_error

# Test all configured LDAP servers
for server in dc01 dc02 dc03; do
  echo "Testing $server.corp.company.com..."
  timeout 5 openssl s_client -connect $server.corp.company.com:636 \
    -brief 2>/dev/null && echo "OK" || echo "FAILED"
done
```

### Query Testing

```bash
# Measure query time
time ldapsearch -x -H ldaps://dc01.corp.company.com:636 \
  -D "CN=svc_wallix,OU=Service Accounts,DC=corp,DC=company,DC=com" \
  -W \
  -b "DC=corp,DC=company,DC=com" \
  "(objectClass=user)" \
  sAMAccountName > /dev/null

# Test filter syntax
ldapsearch -x -H ldaps://dc01.corp.company.com:636 \
  -D "CN=svc_wallix,OU=Service Accounts,DC=corp,DC=company,DC=com" \
  -W \
  -b "DC=corp,DC=company,DC=com" \
  "(&(objectClass=user)(sAMAccountName=jsmith)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))" \
  -LLL dn

# Verbose output for debugging
ldapsearch -x -H ldaps://dc01.corp.company.com:636 \
  -D "CN=svc_wallix,OU=Service Accounts,DC=corp,DC=company,DC=com" \
  -W \
  -b "DC=corp,DC=company,DC=com" \
  -d 1 \
  "(sAMAccountName=jsmith)" 2>&1 | head -100
```

### WALLIX Diagnostic Commands

```bash
# Test LDAP domain connectivity
wabadmin ldap test Corporate-AD

# Check LDAP domain configuration
wabadmin ldap show Corporate-AD

# List all configured LDAP domains
wabadmin ldap list

# Run LDAP sync with verbose output
wabadmin ldap sync --domain Corporate-AD --verbose

# Check sync status
wabadmin ldap sync-status Corporate-AD

# View LDAP-related logs
grep -i "ldap" /var/log/wabengine/wabengine.log | tail -100

# Check authentication failures
grep -i "authentication.*failed\|ldap.*error" /var/log/wabengine/wabengine.log | tail -50
```

---

## Performance Tuning

### Connection Pooling

```json
{
  "connection_pool": {
    "enabled": true,
    "min_connections": 5,
    "max_connections": 50,
    "connection_timeout_ms": 10000,
    "idle_timeout_seconds": 300,
    "max_wait_ms": 5000,

    "health_check": {
      "enabled": true,
      "interval_seconds": 30,
      "query": "(objectClass=*)",
      "base_dn": ""
    }
  }
}
```

### Query Optimization

```
+==============================================================================+
|                    LDAP QUERY OPTIMIZATION                                    |
+==============================================================================+
|                                                                               |
|  INDEXING RECOMMENDATIONS                                                     |
|  ========================                                                     |
|                                                                               |
|  Ensure these AD attributes are indexed for fast searches:                   |
|                                                                               |
|  | Attribute           | Index Type     | Used For                         |
|  +---------------------+----------------+----------------------------------+
|  | sAMAccountName      | Equality       | User lookup by login             |
|  | userPrincipalName   | Equality       | UPN-based authentication         |
|  | mail                | Equality       | Email-based search               |
|  | memberOf            | Equality       | Group membership queries         |
|  | member              | Equality       | Reverse group lookups            |
|  | objectClass         | Equality       | All queries                      |
|  | userAccountControl  | Bit            | Enabled/disabled filtering       |
|  +---------------------+----------------+----------------------------------+
|                                                                               |
|  Note: Active Directory indexes these by default                             |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  FILTER OPTIMIZATION                                                          |
|  ===================                                                          |
|                                                                               |
|  Bad (slow):                                                                  |
|  (displayName=*Smith*)                    # Leading wildcard, no index       |
|                                                                               |
|  Better:                                                                      |
|  (&(objectClass=user)(sn=Smith))          # Indexed attributes               |
|                                                                               |
|  Bad (returns too many results):                                              |
|  (objectClass=user)                       # Returns all users                |
|                                                                               |
|  Better:                                                                      |
|  (&(objectClass=user)(memberOf=CN=PAM-Users,...))  # Scoped by group        |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  SEARCH SCOPE OPTIMIZATION                                                    |
|  =========================                                                    |
|                                                                               |
|  | Scope     | Performance | Use When                                       |
|  +-----------+-------------+-----------------------------------------------+
|  | base      | Fastest     | You know the exact DN                         |
|  | onelevel  | Fast        | Objects are in single OU                      |
|  | subtree   | Slowest     | Objects spread across OU hierarchy            |
|  +-----------+-------------+-----------------------------------------------+
|                                                                               |
|  Optimization: Use multiple specific OUs instead of entire tree              |
|                                                                               |
+==============================================================================+
```

### Caching Settings

```json
{
  "ldap_cache": {
    "user_cache": {
      "enabled": true,
      "ttl_seconds": 300,
      "max_entries": 10000,
      "negative_ttl_seconds": 60
    },

    "group_cache": {
      "enabled": true,
      "ttl_seconds": 600,
      "max_entries": 5000
    },

    "search_cache": {
      "enabled": true,
      "ttl_seconds": 120,
      "max_entries": 1000
    },

    "invalidation": {
      "on_sync": true,
      "on_user_update": true,
      "manual_clear_endpoint": "/api/ldap/cache/clear"
    }
  }
}
```

### Performance Monitoring

```bash
# Monitor LDAP query times
grep "ldap.*query.*time" /var/log/wabengine/wabengine.log | \
  awk '{print $NF}' | sort -n | tail -20

# Check cache hit rate
wabadmin ldap cache-stats Corporate-AD

# Monitor connection pool status
wabadmin ldap pool-status Corporate-AD

# Expected output:
# Active connections: 12
# Idle connections: 38
# Waiting requests: 0
# Total connections: 50
# Connection errors (last hour): 0
```

---

## Quick Reference

### Essential ldapsearch Commands

```bash
# Test bind credentials
ldapsearch -x -H ldaps://dc01.corp.company.com:636 \
  -D "BIND_DN" -W -b "BASE_DN" "(objectClass=*)" -s base

# Find user
ldapsearch -x -H ldaps://dc01.corp.company.com:636 \
  -D "BIND_DN" -W -b "BASE_DN" "(sAMAccountName=USERNAME)"

# Get user's groups
ldapsearch -x -H ldaps://dc01.corp.company.com:636 \
  -D "BIND_DN" -W -b "BASE_DN" "(sAMAccountName=USERNAME)" memberOf

# Test certificate
echo | openssl s_client -connect dc01.corp.company.com:636 2>/dev/null | \
  openssl x509 -noout -dates
```

### Common Error Quick Fixes

| Error | Quick Fix |
|-------|-----------|
| Connection refused | Check firewall, verify port 636 open |
| Invalid credentials | Test bind with ldapsearch, verify password |
| User not found | Check Base DN, expand search scope |
| Certificate error | Add CA to trust store, update-ca-certificates |
| Timeout | Check network route, increase timeout |
| Groups not syncing | Force sync, verify group DN in mapping |

---

## Related Documentation

- [05 - Authentication & Identity](../06-authentication/README.md) - Authentication overview
- [06 - Authorization](../07-authorization/README.md) - RBAC and access control
- [12 - Troubleshooting](../13-troubleshooting/README.md) - General troubleshooting
- [38 - Certificate Management](../28-certificate-management/README.md) - TLS certificate setup

## External References

- [WALLIX Bastion Documentation Portal](https://pam.wallix.one/documentation)
- [WALLIX Admin Guide (PDF)](https://pam.wallix.one/documentation/admin-doc/bastion_en_administration_guide.pdf)
- [Microsoft Active Directory LDAP Reference](https://docs.microsoft.com/en-us/windows/win32/adsi/ldap-adsi-provider)
- [OpenLDAP Admin Guide](https://www.openldap.org/doc/admin26/)
- [RFC 4511 - LDAP Protocol](https://datatracker.ietf.org/doc/html/rfc4511)
- [RFC 4513 - LDAP Authentication Methods](https://datatracker.ietf.org/doc/html/rfc4513)
