# 04 - Configuration & Object Model

## Table of Contents

1. [Object Model Overview](#object-model-overview)
2. [Domains](#domains)
3. [Devices](#devices)
4. [Services](#services)
5. [Accounts](#accounts)
6. [Users and User Groups](#users-and-user-groups)
7. [Target Groups](#target-groups)
8. [Configuration Workflow](#configuration-workflow)

---

## Object Model Overview

### Hierarchical Structure

WALLIX Bastion uses a hierarchical object model to organize resources:

```
+-----------------------------------------------------------------------------+
|                         WALLIX OBJECT MODEL                                  |
+-----------------------------------------------------------------------------+
|                                                                              |
|   +---------------------------------------------------------------------+  |
|   |                          DOMAIN                                      |  |
|   |   (Organizational container - similar to CyberArk Safe)             |  |
|   |                                                                      |  |
|   |   +-----------------------------------------------------------------+  |  |
|   |   |                       DEVICE                                 |  |  |
|   |   |   (Target system: server, appliance, database)              |  |   |
|   |   |                                                              |  |  |
|   |   |   +---------------------+  +---------------------+         |  |  |
|   |   |   |      SERVICE        |  |      SERVICE        |         |  |  |
|   |   |   |   (Connection type) |  |   (Connection type) |         |  |  |
|   |   |   |                     |  |                     |         |  |  |
|   |   |   |   * Protocol        |  |   * Protocol        |         |  |  |
|   |   |   |   * Port            |  |   * Port            |         |  |  |
|   |   |   |   * Options         |  |   * Options         |         |  |  |
|   |   |   +---------------------+  +---------------------+         |  |  |
|   |   |                                                              |  |  |
|   |   |   +---------------------+  +---------------------+         |  |  |
|   |   |   |      ACCOUNT        |  |      ACCOUNT        |         |  |  |
|   |   |   |   (Credentials)     |  |   (Credentials)     |         |  |  |
|   |   |   |                     |  |                     |         |  |  |
|   |   |   |   * Username        |  |   * Username        |         |  |  |
|   |   |   |   * Password/Key    |  |   * Password/Key    |         |  |  |
|   |   |   |   * Permissions     |  |   * Permissions     |         |  |  |
|   |   |   +---------------------+  +---------------------+         |  |  |
|   |   |                                                              |  |  |
|   |   +-----------------------------------------------------------------+  |  |
|   |                                                                      |  |
|   +---------------------------------------------------------------------+  |
|                                                                              |
|   ACCESS CONTROL                                                            |
|   --------------                                                            |
|   +-------------+      +---------------+      +-----------------+          |
|   | USER GROUP  |----->| AUTHORIZATION |<-----+  TARGET GROUP   |          |
|   |             |      |               |      |                 |          |
|   | (Who)       |      | (Policy)      |      | (What)          |          |
|   +-------------+      +---------------+      +-----------------+          |
|                                                                              |
+-----------------------------------------------------------------------------+
```

### Object Relationships

```
                    +--------------+
                    |    DOMAIN    |
                    |              |
                    | "Production" |
                    +------+-------+
                           | contains
            +--------------+--------------+
            |              |              |
            v              v              v
     +----------+   +----------+   +----------+
     |  DEVICE  |   |  DEVICE  |   |  DEVICE  |
     |          |   |          |   |          |
     | srv-web  |   | srv-app  |   | srv-db   |
     +----+-----+   +----+-----+   +----+-----+
          |              |              |
    +-----+-----+  +-----+-----+  +-----+-----+
    |           |  |           |  |           |
    v           v  v           v  v           v
+-------+ +-------+ +-------+ +-------+ +-------+ +-------+
|SERVICE| |SERVICE| |SERVICE| |SERVICE| |SERVICE| |SERVICE|
|  SSH  | |  RDP  | |  SSH  | |  RDP  | |  SSH  | | MySQL |
+---+---+ +---+---+ +---+---+ +---+---+ +---+---+ +---+---+
    |         |         |         |         |         |
    v         v         v         v         v         v
+-------+ +-------+ +-------+ +-------+ +-------+ +-------+
|ACCOUNT| |ACCOUNT| |ACCOUNT| |ACCOUNT| |ACCOUNT| |ACCOUNT|
| root  | | admin | | root  | | admin | | root  | | dbadm |
+-------+ +-------+ +-------+ +-------+ +-------+ +-------+
```

### CyberArk Mapping

| WALLIX Object | CyberArk Equivalent | Description |
|---------------|---------------------|-------------|
| Domain | Safe | Logical container for grouping |
| Device | Platform + Account (partial) | Target system definition |
| Service | Connection Component | Protocol/connection method |
| Account | Account | Privileged credential |
| User Group | Safe Members (partial) | Group of users |
| Target Group | Safe (accounts grouping) | Group of targets |
| Authorization | Safe Membership + Permissions | Access policy |

---

## Domains

### Concept

**Domains** are the top-level organizational containers in WALLIX, similar to CyberArk Safes but more flexible.

### Domain Properties

| Property | Description | Required |
|----------|-------------|----------|
| `domain_name` | Unique identifier | Yes |
| `description` | Human-readable description | No |
| `admin_account` | Default admin account for devices | No |
| `enable_password` | Enable/unlock password (network devices) | No |

### Domain Design Patterns

#### Pattern 1: Environment-Based

```
Domains:
+-- Production
|   +-- prod-web-servers
|   +-- prod-app-servers
|   +-- prod-databases
+-- Staging
|   +-- stg-web-servers
|   +-- stg-databases
+-- Development
    +-- dev-servers
```

#### Pattern 2: Function-Based

```
Domains:
+-- Web-Servers
+-- Application-Servers
+-- Database-Servers
+-- Network-Devices
+-- Security-Appliances
```

#### Pattern 3: Business Unit-Based

```
Domains:
+-- Finance-Systems
+-- HR-Systems
+-- IT-Infrastructure
+-- Customer-Facing
+-- Internal-Apps
```

#### Pattern 4: Compliance-Based

```
Domains:
+-- PCI-Scope
+-- HIPAA-Systems
+-- SOX-Critical
+-- General-IT
```

### Domain Configuration Example

```json
{
  "domain_name": "Production-Servers",
  "description": "Production environment servers - critical systems",
  "admin_account": "svc_wallix_admin",
  "enable_password": null
}
```

### Best Practices

> **Domain Design Tips**:
> - Keep domain names consistent and meaningful
> - Plan domain structure before deployment
> - Consider access patterns when grouping
> - Align with existing organizational structure
> - Don't create too many or too few domains

---

## Devices

### Concept

**Devices** represent target systems that users connect to through WALLIX Bastion.

**CyberArk Comparison**: A Device is similar to defining a Platform assignment for accounts, but the device itself is an explicit object.

### Device Properties

| Property | Description | Required |
|----------|-------------|----------|
| `device_name` | Unique identifier | Yes |
| `host` | Hostname, FQDN, or IP address | Yes |
| `alias` | Friendly display name | No |
| `description` | Detailed description | No |
| `domain` | Parent domain | Yes |
| `device_type` | Type (server, network, etc.) | No |

### Device Types

| Type | Description | Examples |
|------|-------------|----------|
| `server` | Standard servers | Windows, Linux, Unix |
| `network` | Network devices | Routers, switches, firewalls |
| `database` | Database servers | Oracle, SQL Server, MySQL |
| `appliance` | Security/management appliances | Load balancers, proxies |
| `cloud` | Cloud resources | AWS EC2, Azure VMs |
| `application` | Application interfaces | Web apps, APIs |

### Device Configuration Examples

#### Linux Server

```json
{
  "device_name": "srv-prod-web-01",
  "host": "192.168.1.100",
  "alias": "Production Web Server 1",
  "description": "Primary web server for customer portal",
  "domain": "Production-Servers"
}
```

#### Windows Server

```json
{
  "device_name": "srv-prod-dc-01",
  "host": "dc01.corp.company.com",
  "alias": "Primary Domain Controller",
  "description": "Main AD domain controller",
  "domain": "Production-Servers"
}
```

#### Network Device

```json
{
  "device_name": "fw-perimeter-01",
  "host": "10.0.0.1",
  "alias": "Perimeter Firewall",
  "description": "Main perimeter firewall - Palo Alto PA-5250",
  "domain": "Network-Devices"
}
```

### Device Addressing

| Method | Example | Use Case |
|--------|---------|----------|
| IP Address | `192.168.1.100` | Stable, non-DNS environments |
| FQDN | `srv01.corp.com` | DNS-managed environments |
| Short hostname | `srv01` | Internal DNS resolution |

> **Warning**: Using IP addresses means manual updates if IPs change. FQDN is recommended for production.

---

## Services

### Concept

**Services** define how users connect to a device - the protocol, port, and connection settings.

**CyberArk Comparison**: Similar to Connection Components in PSM, but configured per-device.

### Service Properties

| Property | Description | Required |
|----------|-------------|----------|
| `service_name` | Identifier (often protocol name) | Yes |
| `protocol` | Connection protocol | Yes |
| `port` | Network port | Yes (usually default) |
| `subprotocols` | Allowed sub-features | No |
| `connection_policy` | Connection behavior | No |

### Supported Protocols

| Protocol | Default Port | Subprotocols |
|----------|-------------|--------------|
| `SSH` | 22 | SHELL, SCP, SFTP, X11, TUNNEL |
| `RDP` | 3389 | - |
| `VNC` | 5900 | - |
| `TELNET` | 23 | - |
| `RLOGIN` | 513 | - |
| `HTTPS` | 443 | - |
| `HTTP` | 80 | - |

### SSH Service Configuration

```json
{
  "service_name": "SSH",
  "protocol": "SSH",
  "port": 22,
  "subprotocols": ["SHELL", "SCP", "SFTP"],
  "connection_policy": {
    "authentication_methods": ["password", "publickey"],
    "host_key_verification": true
  }
}
```

#### SSH Subprotocol Control

| Subprotocol | Description | Security Consideration |
|-------------|-------------|------------------------|
| `SHELL` | Interactive shell | Standard access |
| `SCP` | Secure copy | File exfiltration risk |
| `SFTP` | Secure FTP | File exfiltration risk |
| `X11` | X Window forwarding | Rarely needed |
| `TUNNEL` | Port forwarding | Can bypass controls |

### RDP Service Configuration

```json
{
  "service_name": "RDP",
  "protocol": "RDP",
  "port": 3389,
  "connection_policy": {
    "security_level": "NLA",
    "enable_clipboard": false,
    "enable_drive_redirection": false,
    "enable_printer": false
  }
}
```

#### RDP Security Levels

| Level | Description | Recommendation |
|-------|-------------|----------------|
| `ANY` | Accept any level | Not recommended |
| `RDP` | Basic RDP security | Legacy only |
| `TLS` | TLS encryption | Minimum standard |
| `NLA` | Network Level Auth | Recommended |

### Multiple Services per Device

A device can have multiple services:

```
Device: srv-prod-01
+-- Service: SSH (port 22)
|   +-- Subprotocols: SHELL, SCP, SFTP
+-- Service: RDP (port 3389)
|   +-- Security: NLA
+-- Service: HTTPS (port 443)
    +-- Web management interface
```

---

## Accounts

### Concept

**Accounts** are the privileged credentials stored in WALLIX for accessing target systems.

**CyberArk Comparison**: Directly equivalent to Accounts in CyberArk.

### Account Properties

| Property | Description | Required |
|----------|-------------|----------|
| `account_name` | Account identifier | Yes |
| `login` | Username on target | Yes |
| `device` | Parent device | Yes |
| `credentials` | Password, key, or certificate | Yes |
| `description` | Account description | No |
| `auto_change_password` | Enable rotation | No |
| `checkout_policy` | Checkout rules | No |

### Credential Types

#### Password-Based Account

```json
{
  "account_name": "root@srv-prod-01",
  "login": "root",
  "device": "srv-prod-01",
  "credentials": {
    "type": "password",
    "password": "********"
  },
  "auto_change_password": true,
  "auto_change_password_policy": "30days"
}
```

#### SSH Key-Based Account

```json
{
  "account_name": "admin@srv-prod-01",
  "login": "admin",
  "device": "srv-prod-01",
  "credentials": {
    "type": "ssh_key",
    "private_key": "-----BEGIN RSA PRIVATE KEY-----...",
    "passphrase": "********"
  }
}
```

#### Domain Account

```json
{
  "account_name": "CORP\\svc_backup",
  "login": "CORP\\svc_backup",
  "device": "srv-prod-dc-01",
  "credentials": {
    "type": "password",
    "password": "********"
  },
  "domain_account": true
}
```

### Account Naming Conventions

| Convention | Example | Use Case |
|------------|---------|----------|
| `user@device` | `root@srv-prod-01` | Clear association |
| `device_user` | `srv-prod-01_root` | Alternative format |
| `domain\user` | `CORP\Administrator` | Windows domain |
| `user_function` | `oracle_dba` | Function-based |

### Account-Service Association

Accounts can be associated with specific services:

```
Device: srv-prod-01
+-- Service: SSH
|   +-- Accounts:
|       +-- root (password)
|       +-- admin (SSH key)
+-- Service: RDP
    +-- Accounts:
        +-- Administrator (password)
```

### Checkout Policies

| Policy | Description | Use Case |
|--------|-------------|----------|
| `exclusive` | One user at a time | High-security accounts |
| `shared` | Multiple concurrent users | Service accounts |
| `checkout_required` | Must checkout before use | Audit trail |
| `automatic` | System manages checkout | Standard access |

---

## Users and User Groups

### Users

**Users** represent individuals or service accounts that access WALLIX Bastion.

#### User Types

| Type | Description | Authentication |
|------|-------------|----------------|
| **Local** | Stored in WALLIX | Local password + MFA |
| **LDAP/AD** | From directory | Directory auth + MFA |
| **RADIUS** | RADIUS backend | RADIUS + MFA |

#### User Properties

| Property | Description | Required |
|----------|-------------|----------|
| `user_name` | Unique identifier | Yes |
| `real_name` | Display name | No |
| `email` | Email address | No |
| `profile` | Permission profile | Yes |
| `groups` | Group memberships | No |
| `authentication` | Auth method | Yes |
| `ip_restriction` | Allowed source IPs | No |

#### User Profiles

| Profile | Description | Permissions |
|---------|-------------|-------------|
| `user` | Standard user | Connect to authorized targets |
| `auditor` | Read-only auditor | View sessions, logs, reports |
| `operator` | Operations staff | Monitor sessions, basic admin |
| `administrator` | Full admin | Complete configuration access |
| `superadmin` | Super administrator | System-level access |

#### User Configuration Example

```json
{
  "user_name": "jsmith",
  "real_name": "John Smith",
  "email": "jsmith@company.com",
  "profile": "user",
  "groups": ["Linux-Admins", "DBA-Team"],
  "authentication": {
    "type": "ldap",
    "ldap_domain": "corp.company.com"
  },
  "ip_restriction": ["10.0.0.0/8", "192.168.1.0/24"],
  "mfa_required": true
}
```

### User Groups

**User Groups** organize users for authorization management.

**CyberArk Comparison**: Similar to defining Safe members, but groups are managed separately.

#### Group Properties

| Property | Description | Required |
|----------|-------------|----------|
| `group_name` | Unique identifier | Yes |
| `description` | Group description | No |
| `profile` | Default profile for members | No |
| `time_frames` | Allowed access times | No |

#### Group Design Patterns

```
User Groups (Role-Based):
+-- Linux-Admins
|   +-- jsmith
|   +-- bjones
+-- Windows-Admins
|   +-- mwilson
|   +-- rjohnson
+-- DBA-Team
|   +-- jsmith
|   +-- dlee
+-- Network-Admins
|   +-- kbrown
+-- Security-Team
    +-- auditor1
    +-- auditor2
```

#### LDAP Group Mapping

```json
{
  "ldap_mapping": {
    "ldap_group": "CN=Linux-Admins,OU=Groups,DC=corp,DC=company,DC=com",
    "wallix_group": "Linux-Admins",
    "sync_interval": "3600"
  }
}
```

---

## Target Groups

### Concept

**Target Groups** are collections of accounts, devices, or domains used for authorization.

**CyberArk Comparison**: Similar to grouping accounts in a Safe, but more flexible with device and account grouping.

### Target Group Types

| Type | Contains | Use Case |
|------|----------|----------|
| Account group | Specific accounts | Fine-grained access |
| Device group | All accounts on devices | Device-level access |
| Domain group | All accounts in domain | Broad access |
| Mixed group | Combination | Complex scenarios |

### Target Group Configuration

#### Account-Based Group

```json
{
  "target_group_name": "Production-Root-Accounts",
  "description": "Root accounts on all production servers",
  "accounts": [
    "root@srv-prod-01",
    "root@srv-prod-02",
    "root@srv-prod-03"
  ]
}
```

#### Device-Based Group

```json
{
  "target_group_name": "All-Production-Servers",
  "description": "All accounts on production servers",
  "devices": [
    "srv-prod-01",
    "srv-prod-02",
    "srv-prod-03"
  ]
}
```

#### Domain-Based Group

```json
{
  "target_group_name": "Production-Domain",
  "description": "All accounts in Production domain",
  "domains": [
    "Production-Servers"
  ]
}
```

### Target Group Design

```
Target Groups:
+-- Linux-Root-All
|   +-- Accounts: All root accounts
+-- Windows-Admin-All
|   +-- Accounts: All Administrator accounts
+-- Oracle-DBA-Prod
|   +-- Accounts: Oracle DBA accounts (prod)
+-- Network-Enable-Access
|   +-- Accounts: Network device enable accounts
+-- Emergency-All-Access
    +-- Domains: All domains (break-glass)
```

---

## Configuration Workflow

### Recommended Setup Order

```
CONFIGURATION WORKFLOW
======================

Step 1: Plan Structure
-------------------------
* Define domain structure
* Identify target systems
* Map user groups to access needs

        |
        v

Step 2: Create Domains
-------------------------
* Create organizational containers
* Set domain-level defaults

        |
        v

Step 3: Add Devices
-------------------------
* Define target systems
* Configure hostnames/IPs

        |
        v

Step 4: Configure Services
-------------------------
* Define protocols per device
* Set security options
* Configure subprotocols

        |
        v

Step 5: Add Accounts
-------------------------
* Create privileged accounts
* Store credentials
* Configure rotation policies

        |
        v

Step 6: Create User Groups
-------------------------
* Define role-based groups
* Map to LDAP groups (if applicable)

        |
        v

Step 7: Create Target Groups
-------------------------
* Group accounts logically
* Prepare for authorizations

        |
        v

Step 8: Configure Authorizations
-------------------------
* Link user groups to target groups
* Set policies and restrictions
* (Covered in next chapter)
```

### Example Complete Configuration

```
Domain: Production-Servers
|
+-- Device: srv-prod-web-01
|   +-- Service: SSH (22)
|   |   +-- Subprotocols: SHELL, SCP
|   |   +-- Accounts:
|   |       +-- root (password, 30-day rotation)
|   |       +-- webadmin (password, 30-day rotation)
|   +-- Service: HTTPS (443)
|       +-- Accounts:
|           +-- admin (password)
|
+-- Device: srv-prod-app-01
|   +-- Service: SSH (22)
|   |   +-- Accounts:
|   |       +-- root (password)
|   |       +-- appadmin (SSH key)
|   +-- Service: RDP (3389)
|       +-- Accounts:
|           +-- Administrator (password)
|
+-- Device: srv-prod-db-01
    +-- Service: SSH (22)
        +-- Accounts:
            +-- root (password)
            +-- oracle (password)

Target Groups:
+-- Prod-Web-Root -> root@srv-prod-web-01
+-- Prod-App-Root -> root@srv-prod-app-01
+-- Prod-DB-Root -> root@srv-prod-db-01
+-- All-Prod-Root -> All root accounts
+-- All-Prod-Web-Admin -> webadmin accounts

User Groups:
+-- Web-Admins -> Access to web servers
+-- App-Admins -> Access to app servers
+-- DBA-Team -> Access to database servers
+-- Senior-Admins -> Access to all
```

---

## Next Steps

Continue to [05 - Authentication](../05-authentication/README.md) to learn about authentication methods and MFA configuration.
