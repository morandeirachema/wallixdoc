# 09 - API & Automation

## Table of Contents

1. [API Overview](#api-overview)
2. [Authentication](#authentication)
3. [Core Endpoints](#core-endpoints)
4. [Common Operations](#common-operations)
5. [Automation Examples](#automation-examples)
6. [Integration Patterns](#integration-patterns)
7. [Best Practices](#best-practices)

---

## API Overview

### REST API Architecture

```
+===============================================================================+
|                         WALLIX REST API                                       |
+===============================================================================+
|                                                                               |
|  BASE URL: https://bastion.company.com/api/                                   |
|                                                                               |
|  +---------------------------------------------------------------------+      |
|  |                           API STRUCTURE                             |      |
|  |                                                                     |      |
|  |  /api/                                                              |      |
|  |  |                                                                  |      |
|  |  +-- /auth                    # Authentication                      |      |
|  |  |   +-- POST /login          # Get session token                   |      |
|  |  |   +-- POST /logout         # Invalidate token                    |      |
|  |  |                                                                  |      |
|  |  +-- /users                   # User management                     |      |
|  |  +-- /usergroups              # User group management               |      |
|  |  |                                                                  |      |
|  |  +-- /domains                 # Domain management                   |      |
|  |  +-- /devices                 # Device management                   |      |
|  |  +-- /services                # Service configuration               |      |
|  |  +-- /accounts                # Account management                  |      |
|  |  |                                                                  |      |
|  |  +-- /targetgroups            # Target group management             |      |
|  |  +-- /authorizations          # Authorization policies              |      |
|  |  |                                                                  |      |
|  |  +-- /sessions                # Session data                        |      |
|  |  |   +-- /current             # Active sessions                     |      |
|  |  |   +-- /history             # Historical sessions                 |      | 
|  |  |                                                                  |      |
|  |  +-- /recordings              # Recording management                |      |
|  |  |                                                                  |      |
|  |  +-- /passwords               # Password operations                 |      |
|  |      +-- /checkout            # Credential checkout                 |      |
|  |      +-- /change              # Password rotation                   |      |
|  |                                                                     |      |
|  +---------------------------------------------------------------------+      |
|                                                                               |
|  HTTP METHODS                                                                 |
|  ============                                                                 |
|                                                                               |
|  GET     - Retrieve resources                                                 |
|  POST    - Create new resources                                               |
|  PUT     - Update existing resources (full replacement)                       |
|  PATCH   - Partial update of resources                                        |
|  DELETE  - Remove resources                                                   |
|                                                                               |
+===============================================================================+
```

### API Versioning

| Version | Status | Notes |
|---------|--------|-------|
| v2.0 | Current | Stable API for 12.x |
| v1.0 | Removed | NOT supported in 12.x |
| v3.x | Removed | NOT supported in 12.x |

### CyberArk Comparison

> **CyberArk Equivalent: CyberArk REST API (PVWA) + Central Policy Manager API**

| Capability | CyberArk | WALLIX |
|------------|----------|--------|
| API Base | `/PasswordVault/API/` | `/api/` |
| Authentication | CyberArk Auth, LDAP, RADIUS | API Key, Basic Auth, LDAP |
| Token Type | Session token | Bearer token |
| API Style | REST | REST |
| SDK Availability | Python, PowerShell | Python, custom integrations |
| Webhook Support | Limited | Native webhooks |

**Key Differences:**
- WALLIX API is simpler with fewer nested endpoints
- CyberArk API requires Safe-level permissions; WALLIX uses Domain-level
- WALLIX supports direct password checkout via API without Safe access
- Terraform provider available for both (community and official)

---

## Authentication

### Authentication Methods

```
+===============================================================================+
|                      API AUTHENTICATION                                       |
+===============================================================================+
|                                                                               |
|  METHOD 1: Session Token (Cookie-based)                                       |
|  ======================================                                       |
|                                                                               |
|  # Login to get session cookie                                                |
|  curl -X POST https://bastion.company.com/api/auth/login \                    |
|       -H "Content-Type: application/json" \                                   |
|       -d '{"username": "admin", "password": "secret"}' \                      |
|       -c cookies.txt                                                          |
|                                                                               |
|  # Use cookie for subsequent requests                                         |
|  curl -X GET https://bastion.company.com/api/devices \                        |
|       -b cookies.txt                                                          |
|                                                                               |
|  -------------------------------------------------------------------------- - |
|                                                                               |
|  METHOD 2: API Key (Header-based)                                             |
|  ================================                                             |
|                                                                               |
|  # Use API key in header                                                      |
|  curl -X GET https://bastion.company.com/api/devices \                        |
|       -H "X-Auth-Token: your-api-key-here"                                    |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  METHOD 3: OAuth 2.0 (Bearer Token)                                           |
|  ==================================                                           |
|                                                                               |
|  # Get OAuth token                                                            |
|  curl -X POST https://bastion.company.com/oauth/token \                       |
|       -d "grant_type=client_credentials" \                                    |
|       -d "client_id=your-client-id" \                                         |
|       -d "client_secret=your-client-secret"                                   |
|                                                                               |
|  # Use bearer token                                                           |
|  curl -X GET https://bastion.company.com/api/devices \                        |
|       -H "Authorization: Bearer eyJhbGc..."                                   |
|                                                                               |
+===============================================================================+
```

### API Key Management

```json
{
    "api_key": {
        "name": "automation-service",
        "description": "Key for CI/CD automation",
        "permissions": [
            "devices:read",
            "devices:write",
            "accounts:read",
            "sessions:read"
        ],
        "ip_restrictions": ["10.0.0.0/8"],
        "expires": "2025-12-31T23:59:59Z"
    }
}
```

---

## Core Endpoints

### Device Management

```
+===============================================================================+
|                      DEVICE API ENDPOINTS                                     |
+===============================================================================+
|                                                                               |
|  LIST DEVICES                                                                 |
|  ============                                                                 |
|                                                                               |
|  GET /api/devices                                                             |
|                                                                               |
|  Query Parameters:                                                            |
|  * q          - Search query                                                  |
|  * domain     - Filter by domain                                              |
|  * limit      - Results per page (default: 50)                                |
|  * offset     - Pagination offset                                             |
|                                                                               |
|  Example:                                                                     |
|  GET /api/devices?domain=Production&limit=100                                 |
|                                                                               |
|  Response:                                                                    |
|  {                                                                            |
|      "total": 156,                                                            |
|      "devices": [                                                             |
|          {                                                                    |
|              "device_name": "srv-prod-01",                                    |
|              "host": "192.168.1.100",                                         |
|              "domain": "Production",                                          |
|              "description": "Production web server"                           |
|          }                                                                    |
|      ]                                                                        |
|  }                                                                            |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  GET DEVICE                                                                   |
|  ==========                                                                   |
|                                                                               |
|  GET /api/devices/{device_name}                                               |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  CREATE DEVICE                                                                |
|  =============                                                                |
|                                                                               |
|  POST /api/devices                                                            |
|                                                                               |
|  Body:                                                                        |
|  {                                                                            |
|      "device_name": "srv-prod-02",                                            |
|      "host": "192.168.1.101",                                                 |
|      "domain": "Production",                                                  |
|      "description": "Production app server"                                   |
|  }                                                                            |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  UPDATE DEVICE                                                                |
|  =============                                                                |
|                                                                               |
|  PUT /api/devices/{device_name}                                               |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  DELETE DEVICE                                                                |
|  =============                                                                |
|                                                                               |
|  DELETE /api/devices/{device_name}                                            |
|                                                                               |
+===============================================================================+
```

### Account Management

```
+===============================================================================+
|                      ACCOUNT API ENDPOINTS                                    |
+===============================================================================+
|                                                                               |
|  LIST ACCOUNTS                                                                |
|  =============                                                                |
|                                                                               |
|  GET /api/accounts                                                            |
|  GET /api/devices/{device_name}/accounts                                      |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  CREATE ACCOUNT                                                               |
|  ==============                                                               |
|                                                                               |
|  POST /api/accounts                                                           |
|                                                                               |
|  Body:                                                                        |
|  {                                                                            |
|      "account_name": "root@srv-prod-01",                                      |
|      "login": "root",                                                         |
|      "device": "srv-prod-01",                                                 |
|      "credentials": {                                                         |
|          "type": "password",                                                  |
|          "password": "SecureP@ssw0rd!"                                        |
|      },                                                                       |
|      "auto_change_password": true,                                            |
|      "change_password_interval_days": 30                                      |
|  }                                                                            |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  GET ACCOUNT PASSWORD                                                         |
|  ====================                                                         |
|                                                                               |
|  GET /api/accounts/{account_name}/password                                    |
|                                                                               |
|  Response:                                                                    |
|  {                                                                            |
|      "password": "CurrentP@ssw0rd!",                                          |
|      "last_changed": "2024-01-15T10:30:00Z"                                   |
|  }                                                                            |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  ROTATE PASSWORD                                                              |
|  ===============                                                              |
|                                                                               |
|  POST /api/accounts/{account_name}/password/change                            |
|                                                                               |
|  Body (optional - for manual password set):                                   |
|  {                                                                            |
|      "new_password": "NewP@ssw0rd!"                                           |
|  }                                                                            |
|                                                                               |
+===============================================================================+
```

### Session Management

```
+===============================================================================+
|                      SESSION API ENDPOINTS                                    |
+===============================================================================+
|                                                                               |
|  LIST ACTIVE SESSIONS                                                         |
|  ====================                                                         |
|                                                                               |
|  GET /api/sessions/current                                                    |
|                                                                               |
|  Response:                                                                    |
|  {                                                                            |
|      "sessions": [                                                            |
|          {                                                                    |
|              "session_id": "SES-001",                                         |
|              "user": "jsmith",                                                |
|              "target": "root@srv-prod-01",                                    |
|              "protocol": "SSH",                                               |
|              "start_time": "2024-01-15T09:30:00Z",                            |
|              "duration_seconds": 3600,                                        |
|              "is_recorded": true                                              |
|          }                                                                    |
|      ]                                                                        |
|  }                                                                            |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  TERMINATE SESSION                                                            |
|  =================                                                            |
|                                                                               |
|  DELETE /api/sessions/current/{session_id}                                    |
|                                                                               |
|  Body:                                                                        |
|  {                                                                            |
|      "reason": "Security incident response"                                   |
|  }                                                                            |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  SESSION HISTORY                                                              |
|  ===============                                                              |
|                                                                               |
|  GET /api/sessions/history                                                    |
|                                                                               |
|  Query Parameters:                                                            |
|  * from_date  - Start date (ISO 8601)                                         |
|  * to_date    - End date (ISO 8601)                                           |
|  * user       - Filter by user                                                |
|  * target     - Filter by target                                              |
|  * protocol   - Filter by protocol                                            |
|                                                                               |
|  Example:                                                                     |
|  GET /api/sessions/history?from_date=2024-01-01&user=jsmith                   |
|                                                                               |
+===============================================================================+
```

---

## Common Operations

### Bulk Import Example

```python
#!/usr/bin/env python3
"""
WALLIX Bastion - Bulk Device Import
"""

import requests
import csv

BASTION_URL = "https://bastion.company.com"
API_KEY = "your-api-key"

headers = {
    "X-Auth-Token": API_KEY,
    "Content-Type": "application/json"
}

def create_device(device_data):
    """Create a single device"""
    response = requests.post(
        f"{BASTION_URL}/api/devices",
        headers=headers,
        json=device_data
    )
    return response.status_code == 201

def create_account(account_data):
    """Create a single account"""
    response = requests.post(
        f"{BASTION_URL}/api/accounts",
        headers=headers,
        json=account_data
    )
    return response.status_code == 201

def import_from_csv(csv_file):
    """Import devices and accounts from CSV"""
    with open(csv_file, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            # Create device
            device = {
                "device_name": row['hostname'],
                "host": row['ip_address'],
                "domain": row['domain'],
                "description": row['description']
            }

            if create_device(device):
                print(f"Created device: {row['hostname']}")

                # Create account
                account = {
                    "account_name": f"{row['username']}@{row['hostname']}",
                    "login": row['username'],
                    "device": row['hostname'],
                    "credentials": {
                        "type": "password",
                        "password": row['password']
                    }
                }

                if create_account(account):
                    print(f"  Created account: {row['username']}")

if __name__ == "__main__":
    import_from_csv("servers.csv")
```

### Ansible Integration

```yaml
# ansible/wallix_device.yml
---
- name: Manage WALLIX Bastion Devices
  hosts: localhost
  vars:
    wallix_url: "https://bastion.company.com"
    wallix_api_key: "{{ lookup('env', 'WALLIX_API_KEY') }}"

  tasks:
    - name: Create device in WALLIX
      uri:
        url: "{{ wallix_url }}/api/devices"
        method: POST
        headers:
          X-Auth-Token: "{{ wallix_api_key }}"
          Content-Type: "application/json"
        body_format: json
        body:
          device_name: "{{ item.name }}"
          host: "{{ item.ip }}"
          domain: "{{ item.domain }}"
          description: "{{ item.description }}"
        status_code: [200, 201]
      loop:
        - name: srv-web-01
          ip: 192.168.1.10
          domain: Production
          description: Web Server 1
        - name: srv-web-02
          ip: 192.168.1.11
          domain: Production
          description: Web Server 2
```

### Terraform Provider

```hcl
# terraform/wallix.tf

terraform {
  required_providers {
    wallix = {
      source  = "wallix/wallix"
      version = "~> 1.0"
    }
  }
}

provider "wallix" {
  url     = "https://bastion.company.com"
  api_key = var.wallix_api_key
}

# Create Domain
resource "wallix_domain" "production" {
  domain_name = "Production"
  description = "Production environment"
}

# Create Device
resource "wallix_device" "web_server" {
  device_name = "srv-prod-web-01"
  host        = "192.168.1.100"
  domain      = wallix_domain.production.domain_name
  description = "Production web server"
}

# Create Account
resource "wallix_account" "root" {
  account_name = "root@srv-prod-web-01"
  login        = "root"
  device       = wallix_device.web_server.device_name

  credentials {
    type     = "password"
    password = var.root_password
  }

  auto_change_password        = true
  change_password_interval    = 30
}

# Create User Group
resource "wallix_usergroup" "linux_admins" {
  group_name  = "Linux-Admins"
  description = "Linux administrators"
}

# Create Target Group
resource "wallix_targetgroup" "prod_linux" {
  target_group_name = "Production-Linux"
  description       = "Production Linux servers"

  accounts = [
    wallix_account.root.account_name
  ]
}

# Create Authorization
resource "wallix_authorization" "linux_admin_access" {
  authorization_name = "linux-admins-prod"
  user_group         = wallix_usergroup.linux_admins.group_name
  target_group       = wallix_targetgroup.prod_linux.target_group_name

  is_recorded       = true
  is_critical       = false
  approval_required = false

  subprotocols = ["SHELL", "SCP", "SFTP"]
}
```

---

## Integration Patterns

### CMDB Integration

```
+===============================================================================+
|                        CMDB INTEGRATION PATTERN                               |
+===============================================================================+
|                                                                               |
|                        +-----------------+                                    |
|                        |      CMDB       |                                    |
|                        |   (ServiceNow)  |                                    |
|                        +--------+--------+                                    |
|                                 |                                             |
|                                 | Webhook/API                                 |
|                                 v                                             |
|                        +-----------------+                                    |
|                        |   Integration   |                                    |
|                        |     Service     |                                    |
|                        +--------+--------+                                    |
|                                 |                                             |
|           +---------------------+---------------------+                       |
|           |                     |                     |                       |
|           v                     v                     v                       |
|  +-----------------+  +-----------------+  +-----------------+                |
|  |  New Server     |  | Server Updated  |  | Server Retired  |                |
|  |                 |  |                 |  |                 |                |
|  | * Create Device |  | * Update Device |  | * Delete Device |                |
|  | * Create Accts  |  | * Update Accts  |  | * Delete Accts  |                |
|  | * Add to Groups |  |                 |  | * Remove Auth   |                |
|  +-----------------+  +-----------------+  +-----------------+                |
|                                                                               |
|  SYNC WORKFLOW                                                                |
|  =============                                                                |
|                                                                               |
|  1. CMDB change detected (new server provisioned)                             |
|  2. Webhook triggers integration service                                      |
|  3. Integration service:                                                      |
|     a. Validates server data                                                  |
|     b. Creates device in WALLIX                                               |
|     c. Creates default accounts (root, admin)                                 |
|     d. Adds to appropriate target groups                                      |
|  4. Confirmation logged back to CMDB                                          |
|                                                                               |
+===============================================================================+
```

### ITSM Ticketing Integration

```
+===============================================================================+
|                      ITSM TICKETING INTEGRATION                               |
+===============================================================================+
|                                                                               |
|  APPROVAL WORKFLOW                                                            |
|  =================                                                            |
|                                                                               |
|  +----------+                                                                 |
|  |   User   |                                                                 |
|  +----+-----+                                                                 |
|       |                                                                       |
|       | 1. Request access (with ticket number)                                |
|       v                                                                       |
|  +-----------------+                                                          |
|  |  WALLIX Bastion |                                                          |
|  +--------+--------+                                                          |
|           |                                                                   |
|           | 2. Validate ticket via API                                        |
|           v                                                                   |
|  +-----------------+                                                          |
|  |  ITSM System    |                                                          |
|  |  (ServiceNow)   |                                                          |
|  +--------+--------+                                                          |
|           |                                                                   |
|           | 3. Return ticket status                                           |
|           |    - Valid/Invalid                                                |
|           |    - Approved/Pending                                             |
|           |    - Authorized systems                                           |
|           v                                                                   |
|  +-----------------+                                                          |
|  |  WALLIX Bastion |                                                          |
|  +--------+--------+                                                          |
|           |                                                                   |
|           | 4. Grant/Deny access based on ticket                              |
|           v                                                                   |
|  +----------------------------------------------------------------------+     |
|  |  Session established (or denied)                                     |     |
|  |  Session ID linked to ticket number in audit                         |     |
|  +----------------------------------------------------------------------+     |
|                                                                               |
+===============================================================================+
```

---

## Webhooks

### Webhook Overview

```
+===============================================================================+
|                   WEBHOOK INTEGRATION                                         |
+===============================================================================+

  OVERVIEW
  ========

  WALLIX Bastion can send HTTP callbacks (webhooks) to external systems
  when specific events occur. This enables real-time integration with
  SIEM, ITSM, alerting, and automation platforms.

  ARCHITECTURE
  ============

  +------------------------------------------------------------------------+
  |                                                                        |
  |   WALLIX Bastion                          External Systems             |
  |   +------------------+                    +------------------+         |
  |   |                  |   HTTPS POST       |                  |         |
  |   | Event Generator  +-------------------->  Webhook         |         |
  |   | (Auth, Session,  |   (JSON Payload)   |  Endpoint        |         |
  |   |  Password, etc.) |                    |  (SIEM, ITSM,    |         |
  |   +------------------+                    |   Slack, etc.)   |         |
  |                                           +------------------+         |
  |                                                                        |
  |   Features:                                                            |
  |   - TLS encryption (required)                                          |
  |   - HMAC signature verification                                        |
  |   - Retry with exponential backoff                                     |
  |   - Event filtering by type and severity                               |
  |   - Custom headers and authentication                                  |
  |                                                                        |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### Webhook Configuration

```
+===============================================================================+
|                   WEBHOOK CONFIGURATION                                       |
+===============================================================================+

  API ENDPOINT: POST /api/v2/webhooks

  CREATE WEBHOOK
  ==============

  Request:
  {
    "name": "siem-integration",
    "description": "Send security events to Splunk HEC",
    "url": "https://splunk-hec.company.com:8088/services/collector",
    "enabled": true,
    "secret": "webhook-signing-secret-12345",
    "headers": {
      "Authorization": "Splunk <HEC-TOKEN>",
      "Content-Type": "application/json"
    },
    "events": [
      "auth.login.success",
      "auth.login.failure",
      "auth.mfa.failure",
      "session.start",
      "session.end",
      "session.terminated",
      "approval.requested",
      "approval.granted",
      "approval.denied",
      "password.checkout",
      "password.rotated",
      "config.changed"
    ],
    "filters": {
      "severity": ["warning", "error", "critical"],
      "user_groups": ["ot_vendors", "ot_admins"]
    },
    "retry": {
      "enabled": true,
      "max_attempts": 5,
      "backoff_seconds": [5, 15, 60, 300, 900]
    },
    "timeout_seconds": 30
  }

  Response (201 Created):
  {
    "status": "success",
    "data": {
      "id": "wh_001",
      "name": "siem-integration",
      "url": "https://splunk-hec.company.com:8088/services/collector",
      "enabled": true,
      "created_at": "2024-01-27T10:00:00Z"
    }
  }

  --------------------------------------------------------------------------

  CONFIGURATION FILE (Alternative)
  ================================

  /etc/opt/wab/wabengine/webhooks.conf:
  +------------------------------------------------------------------------+
  | [webhook.siem]                                                         |
  | enabled = true                                                         |
  | url = https://splunk-hec.company.com:8088/services/collector           |
  | secret = ${WEBHOOK_SECRET}                                             |
  | timeout = 30                                                           |
  |                                                                        |
  | # Authentication header                                                |
  | header.Authorization = Splunk ${SPLUNK_HEC_TOKEN}                      |
  | header.Content-Type = application/json                                 |
  |                                                                        |
  | # Event filtering                                                      |
  | events = auth.*, session.*, password.*, approval.*                     |
  | severity = warning, error, critical                                    |
  |                                                                        |
  | # Retry configuration                                                  |
  | retry.enabled = true                                                   |
  | retry.max_attempts = 5                                                 |
  | retry.backoff = 5, 15, 60, 300, 900                                    |
  |                                                                        |
  | [webhook.slack]                                                        |
  | enabled = true                                                         |
  | url = https://hooks.slack.com/services/T00/B00/xxxxx                   |
  | events = session.terminated, approval.denied, auth.mfa.failure         |
  | severity = error, critical                                             |
  | template = slack                                                       |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### Webhook Event Types

```
+===============================================================================+
|                   WEBHOOK EVENT TYPES                                         |
+===============================================================================+

  AUTHENTICATION EVENTS
  =====================

  +------------------------------------------------------------------------+
  | Event Type            | Triggered When                                 |
  +-----------------------+------------------------------------------------+
  | auth.login.success    | User successfully logs in                      |
  | auth.login.failure    | Login attempt fails                            |
  | auth.logout           | User logs out                                  |
  | auth.mfa.success      | MFA challenge passed                           |
  | auth.mfa.failure      | MFA challenge failed                           |
  | auth.lockout          | Account locked due to failed attempts          |
  | auth.unlock           | Account unlocked                               |
  | auth.password.expired | User password has expired                      |
  +-----------------------+------------------------------------------------+

  SESSION EVENTS
  ==============

  +------------------------------------------------------------------------+
  | Event Type            | Triggered When                                 |
  +-----------------------+------------------------------------------------+
  | session.start         | User starts a session to target                |
  | session.end           | Session ends normally                          |
  | session.terminated    | Admin terminates session                       |
  | session.idle_timeout  | Session closed due to inactivity               |
  | session.recording.start | Session recording begins                     |
  | session.recording.stop  | Session recording ends                       |
  | session.command.blocked | Blocked command detected                     |
  +-----------------------+------------------------------------------------+

  APPROVAL EVENTS
  ===============

  +------------------------------------------------------------------------+
  | Event Type            | Triggered When                                 |
  +-----------------------+------------------------------------------------+
  | approval.requested    | User requests access requiring approval        |
  | approval.granted      | Approver grants access                         |
  | approval.denied       | Approver denies access                         |
  | approval.expired      | Request expires without decision               |
  | approval.cancelled    | User cancels request                           |
  +-----------------------+------------------------------------------------+

  PASSWORD EVENTS
  ===============

  +------------------------------------------------------------------------+
  | Event Type            | Triggered When                                 |
  +-----------------------+------------------------------------------------+
  | password.checkout     | Credential checked out                         |
  | password.checkin      | Credential checked in                          |
  | password.rotated      | Password successfully rotated                  |
  | password.rotation.failed | Password rotation failed                    |
  | password.expiring     | Password approaching expiration                |
  +-----------------------+------------------------------------------------+

  CONFIGURATION EVENTS
  ====================

  +------------------------------------------------------------------------+
  | Event Type            | Triggered When                                 |
  +-----------------------+------------------------------------------------+
  | config.user.created   | New user created                               |
  | config.user.modified  | User modified                                  |
  | config.user.deleted   | User deleted                                   |
  | config.device.created | New device added                               |
  | config.device.modified| Device configuration changed                   |
  | config.device.deleted | Device removed                                 |
  | config.auth.created   | Authorization created                          |
  | config.auth.modified  | Authorization modified                         |
  | config.auth.deleted   | Authorization deleted                          |
  | config.system.changed | System configuration changed                   |
  +-----------------------+------------------------------------------------+

+===============================================================================+
```

### Webhook Payload Format

```
+===============================================================================+
|                   WEBHOOK PAYLOAD FORMAT                                      |
+===============================================================================+

  STANDARD PAYLOAD STRUCTURE
  ==========================

  {
    "id": "evt_abc123def456",
    "timestamp": "2024-01-27T10:30:00.000Z",
    "event_type": "session.start",
    "severity": "info",
    "source": {
      "host": "wallix.company.com",
      "version": "12.1.1",
      "cluster_node": "primary"
    },
    "actor": {
      "user_id": "usr_001",
      "username": "jsmith",
      "display_name": "John Smith",
      "groups": ["ot_engineers"],
      "ip_address": "192.168.1.100",
      "user_agent": "Mozilla/5.0..."
    },
    "target": {
      "device_id": "dev_001",
      "device_name": "plc-line1",
      "host": "10.10.1.10",
      "account": "root",
      "protocol": "ssh"
    },
    "data": {
      "session_id": "ses_001",
      "authorization": "engineers_to_plcs",
      "is_recorded": true,
      "approval_id": null
    },
    "metadata": {
      "request_id": "req_xyz789",
      "correlation_id": "corr_123"
    }
  }

  --------------------------------------------------------------------------

  EVENT-SPECIFIC PAYLOADS
  =======================

  Authentication Failure:
  +------------------------------------------------------------------------+
  | {                                                                      |
  |   "event_type": "auth.login.failure",                                  |
  |   "severity": "warning",                                               |
  |   "actor": {                                                           |
  |     "username": "unknown_user",                                        |
  |     "ip_address": "203.0.113.50"                                       |
  |   },                                                                   |
  |   "data": {                                                            |
  |     "reason": "invalid_credentials",                                   |
  |     "attempt_count": 3,                                                |
  |     "lockout_triggered": false                                         |
  |   }                                                                    |
  | }                                                                      |
  +------------------------------------------------------------------------+

  Session Terminated:
  +------------------------------------------------------------------------+
  | {                                                                      |
  |   "event_type": "session.terminated",                                  |
  |   "severity": "warning",                                               |
  |   "actor": {                                                           |
  |     "username": "jsmith",                                              |
  |     "ip_address": "192.168.1.100"                                      |
  |   },                                                                   |
  |   "target": {                                                          |
  |     "device_name": "scada-server",                                     |
  |     "account": "admin"                                                 |
  |   },                                                                   |
  |   "data": {                                                            |
  |     "session_id": "ses_001",                                           |
  |     "terminated_by": "admin_user",                                     |
  |     "reason": "Security incident response",                            |
  |     "duration_seconds": 1800                                           |
  |   }                                                                    |
  | }                                                                      |
  +------------------------------------------------------------------------+

  Password Rotation Failed:
  +------------------------------------------------------------------------+
  | {                                                                      |
  |   "event_type": "password.rotation.failed",                            |
  |   "severity": "error",                                                 |
  |   "target": {                                                          |
  |     "device_name": "plc-line1",                                        |
  |     "account": "admin"                                                 |
  |   },                                                                   |
  |   "data": {                                                            |
  |     "error_code": "CONNECTION_TIMEOUT",                                |
  |     "error_message": "Failed to connect to target",                    |
  |     "retry_count": 3,                                                  |
  |     "next_retry": "2024-01-27T11:00:00Z"                               |
  |   }                                                                    |
  | }                                                                      |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### Webhook Signature Verification

```
+===============================================================================+
|                   WEBHOOK SIGNATURE VERIFICATION                              |
+===============================================================================+

  SIGNATURE HEADER
  ================

  WALLIX signs all webhook payloads using HMAC-SHA256.

  Headers sent with each webhook:
  +------------------------------------------------------------------------+
  | X-Wallix-Signature: sha256=<HMAC-SHA256-hex>                           |
  | X-Wallix-Timestamp: 1706353800                                         |
  | X-Wallix-Event: session.start                                          |
  | X-Wallix-Delivery-ID: evt_abc123def456                                 |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  VERIFICATION PROCESS
  ====================

  1. Extract timestamp from X-Wallix-Timestamp header
  2. Verify timestamp is within acceptable window (5 minutes)
  3. Construct signature base string: timestamp + "." + raw_body
  4. Compute HMAC-SHA256 with webhook secret
  5. Compare with X-Wallix-Signature header value

  --------------------------------------------------------------------------

  PYTHON VERIFICATION EXAMPLE
  ===========================

  +------------------------------------------------------------------------+
  | import hmac                                                            |
  | import hashlib                                                         |
  | import time                                                            |
  |                                                                        |
  | def verify_webhook(request, secret):                                   |
  |     """Verify WALLIX webhook signature"""                              |
  |                                                                        |
  |     signature = request.headers.get('X-Wallix-Signature', '')          |
  |     timestamp = request.headers.get('X-Wallix-Timestamp', '')          |
  |     body = request.get_data(as_text=True)                              |
  |                                                                        |
  |     # Check timestamp freshness (5 minute window)                      |
  |     current_time = int(time.time())                                    |
  |     if abs(current_time - int(timestamp)) > 300:                       |
  |         return False, "Timestamp too old"                              |
  |                                                                        |
  |     # Compute expected signature                                       |
  |     sig_base = f"{timestamp}.{body}"                                   |
  |     expected = hmac.new(                                               |
  |         secret.encode(),                                               |
  |         sig_base.encode(),                                             |
  |         hashlib.sha256                                                 |
  |     ).hexdigest()                                                      |
  |                                                                        |
  |     # Compare signatures                                               |
  |     provided = signature.replace('sha256=', '')                        |
  |     if not hmac.compare_digest(expected, provided):                    |
  |         return False, "Invalid signature"                              |
  |                                                                        |
  |     return True, "Valid"                                               |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  NODE.JS VERIFICATION EXAMPLE
  ============================

  +------------------------------------------------------------------------+
  | const crypto = require('crypto');                                      |
  |                                                                        |
  | function verifyWebhook(req, secret) {                                  |
  |   const signature = req.headers['x-wallix-signature'] || '';           |
  |   const timestamp = req.headers['x-wallix-timestamp'] || '';           |
  |   const body = JSON.stringify(req.body);                               |
  |                                                                        |
  |   // Check timestamp freshness                                         |
  |   const currentTime = Math.floor(Date.now() / 1000);                   |
  |   if (Math.abs(currentTime - parseInt(timestamp)) > 300) {             |
  |     return { valid: false, error: 'Timestamp too old' };               |
  |   }                                                                    |
  |                                                                        |
  |   // Compute expected signature                                        |
  |   const sigBase = `${timestamp}.${body}`;                              |
  |   const expected = crypto                                              |
  |     .createHmac('sha256', secret)                                      |
  |     .update(sigBase)                                                   |
  |     .digest('hex');                                                    |
  |                                                                        |
  |   // Compare signatures                                                |
  |   const provided = signature.replace('sha256=', '');                   |
  |   if (!crypto.timingSafeEqual(                                         |
  |       Buffer.from(expected), Buffer.from(provided))) {                 |
  |     return { valid: false, error: 'Invalid signature' };               |
  |   }                                                                    |
  |                                                                        |
  |   return { valid: true };                                              |
  | }                                                                      |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### Webhook Integration Examples

```
+===============================================================================+
|                   WEBHOOK INTEGRATION EXAMPLES                                |
+===============================================================================+

  SLACK INTEGRATION
  =================

  +------------------------------------------------------------------------+
  | Webhook Configuration:                                                 |
  | {                                                                      |
  |   "name": "slack-alerts",                                              |
  |   "url": "https://hooks.slack.com/services/T00/B00/xxxxx",             |
  |   "events": ["session.terminated", "auth.lockout", "approval.denied"], |
  |   "template": "slack"                                                  |
  | }                                                                      |
  |                                                                        |
  | Slack-formatted payload:                                               |
  | {                                                                      |
  |   "blocks": [                                                          |
  |     {                                                                  |
  |       "type": "header",                                                |
  |       "text": {                                                        |
  |         "type": "plain_text",                                          |
  |         "text": ":warning: Session Terminated"                         |
  |       }                                                                |
  |     },                                                                 |
  |     {                                                                  |
  |       "type": "section",                                               |
  |       "fields": [                                                      |
  |         {"type": "mrkdwn", "text": "*User:*\njsmith"},                 |
  |         {"type": "mrkdwn", "text": "*Target:*\nplc-line1"},            |
  |         {"type": "mrkdwn", "text": "*Terminated By:*\nadmin"},         |
  |         {"type": "mrkdwn", "text": "*Reason:*\nSecurity incident"}     |
  |       ]                                                                |
  |     }                                                                  |
  |   ]                                                                    |
  | }                                                                      |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  MICROSOFT TEAMS INTEGRATION
  ===========================

  +------------------------------------------------------------------------+
  | Webhook Configuration:                                                 |
  | {                                                                      |
  |   "name": "teams-security",                                            |
  |   "url": "https://outlook.office.com/webhook/xxx/IncomingWebhook/yyy", |
  |   "events": ["auth.login.failure", "session.terminated"],              |
  |   "template": "teams"                                                  |
  | }                                                                      |
  |                                                                        |
  | Teams Adaptive Card payload:                                           |
  | {                                                                      |
  |   "@type": "MessageCard",                                              |
  |   "@context": "http://schema.org/extensions",                          |
  |   "themeColor": "FF0000",                                              |
  |   "summary": "WALLIX Security Alert",                                  |
  |   "sections": [{                                                       |
  |     "activityTitle": "Session Terminated",                             |
  |     "facts": [                                                         |
  |       {"name": "User", "value": "jsmith"},                             |
  |       {"name": "Target", "value": "plc-line1"},                        |
  |       {"name": "Time", "value": "2024-01-27 10:30:00"}                 |
  |     ]                                                                  |
  |   }]                                                                   |
  | }                                                                      |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  PAGERDUTY INTEGRATION
  =====================

  +------------------------------------------------------------------------+
  | Webhook Configuration:                                                 |
  | {                                                                      |
  |   "name": "pagerduty-critical",                                        |
  |   "url": "https://events.pagerduty.com/v2/enqueue",                    |
  |   "headers": {                                                         |
  |     "Content-Type": "application/json"                                 |
  |   },                                                                   |
  |   "events": ["auth.lockout", "password.rotation.failed"],              |
  |   "severity": ["error", "critical"],                                   |
  |   "template": "pagerduty"                                              |
  | }                                                                      |
  |                                                                        |
  | PagerDuty payload:                                                     |
  | {                                                                      |
  |   "routing_key": "<INTEGRATION-KEY>",                                  |
  |   "event_action": "trigger",                                           |
  |   "dedup_key": "wallix-evt_abc123",                                    |
  |   "payload": {                                                         |
  |     "summary": "WALLIX: Account lockout - jsmith",                     |
  |     "source": "wallix.company.com",                                    |
  |     "severity": "error",                                               |
  |     "custom_details": {                                                |
  |       "user": "jsmith",                                                |
  |       "ip": "203.0.113.50",                                            |
  |       "attempts": 5                                                    |
  |     }                                                                  |
  |   }                                                                    |
  | }                                                                      |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  CUSTOM AUTOMATION (AWS LAMBDA)
  ==============================

  +------------------------------------------------------------------------+
  | Webhook Configuration:                                                 |
  | {                                                                      |
  |   "name": "aws-automation",                                            |
  |   "url": "https://xyz.execute-api.region.amazonaws.com/prod/webhook",  |
  |   "headers": {                                                         |
  |     "x-api-key": "<API-GATEWAY-KEY>"                                   |
  |   },                                                                   |
  |   "events": ["session.start", "password.checkout"]                     |
  | }                                                                      |
  |                                                                        |
  | Lambda handler:                                                        |
  | +------------------------------------------------------------------+   |
  | | import json                                                      |   |
  | | import boto3                                                     |   |
  | |                                                                  |   |
  | | def handler(event, context):                                     |   |
  | |     body = json.loads(event['body'])                             |   |
  | |                                                                  |   |
  | |     if body['event_type'] == 'session.start':                    |   |
  | |         # Log to CloudWatch Logs Insights                        |   |
  | |         print(json.dumps({                                       |   |
  | |             'event': 'pam_session',                              |   |
  | |             'user': body['actor']['username'],                   |   |
  | |             'target': body['target']['device_name'],             |   |
  | |             'timestamp': body['timestamp']                       |   |
  | |         }))                                                      |   |
  | |                                                                  |   |
  | |         # Optionally update DynamoDB, send SNS, etc.             |   |
  | |                                                                  |   |
  | |     return {'statusCode': 200, 'body': 'OK'}                     |   |
  | +------------------------------------------------------------------+   |
  +------------------------------------------------------------------------+

+===============================================================================+
```

---

## Code Examples Library

### Python SDK Examples

```python
# wallix_client.py - Reusable WALLIX API client

import requests
from typing import Optional, Dict, List, Any
from dataclasses import dataclass

@dataclass
class WallixConfig:
    host: str
    api_key: str
    verify_ssl: bool = True
    timeout: int = 30

class WallixClient:
    """WALLIX Bastion API Client"""

    def __init__(self, config: WallixConfig):
        self.config = config
        self.base_url = f"https://{config.host}/api/v2"
        self.session = requests.Session()
        self.session.headers.update({
            "Authorization": f"Bearer {config.api_key}",
            "Content-Type": "application/json"
        })
        self.session.verify = config.verify_ssl

    def _request(self, method: str, endpoint: str, **kwargs) -> Dict[str, Any]:
        url = f"{self.base_url}{endpoint}"
        response = self.session.request(
            method, url, timeout=self.config.timeout, **kwargs
        )
        response.raise_for_status()
        return response.json() if response.text else {}

    # User Management
    def list_users(self, limit: int = 100) -> List[Dict]:
        return self._request("GET", f"/users?limit={limit}")["data"]

    def get_user(self, user_id: str) -> Dict:
        return self._request("GET", f"/users/{user_id}")["data"]

    def create_user(self, username: str, email: str,
                    groups: List[str] = None) -> Dict:
        payload = {"username": username, "email": email, "groups": groups or []}
        return self._request("POST", "/users", json=payload)["data"]

    def disable_user(self, user_id: str) -> None:
        self._request("PUT", f"/users/{user_id}", json={"enabled": False})

    # Device Management
    def list_devices(self, domain: str = None) -> List[Dict]:
        params = f"?domain={domain}" if domain else ""
        return self._request("GET", f"/devices{params}")["data"]

    def create_device(self, name: str, host: str, domain: str) -> Dict:
        payload = {"name": name, "host": host, "domain": domain}
        return self._request("POST", "/devices", json=payload)["data"]

    # Session Management
    def list_active_sessions(self) -> List[Dict]:
        return self._request("GET", "/sessions?status=active")["data"]

    def terminate_session(self, session_id: str) -> None:
        self._request("DELETE", f"/sessions/{session_id}")

    # Password Management
    def checkout_password(self, account_id: str, reason: str) -> Dict:
        payload = {"reason": reason}
        return self._request("POST",
            f"/accounts/{account_id}/checkout", json=payload)["data"]

    def rotate_password(self, account_id: str) -> Dict:
        return self._request("POST", f"/accounts/{account_id}/rotate")["data"]
```

### Automated User Provisioning

```python
# provision_users.py - Provision users from HR system

from wallix_client import WallixClient, WallixConfig
import csv
import logging
import os

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def provision_users_from_csv(client: WallixClient, csv_file: str) -> dict:
    """Provision users from CSV file"""
    results = {"created": 0, "updated": 0, "errors": []}

    # Get existing users
    existing_users = {u["username"]: u for u in client.list_users(limit=10000)}

    with open(csv_file, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            try:
                username = row["username"]
                if username in existing_users:
                    logger.info(f"Updating user: {username}")
                    results["updated"] += 1
                else:
                    logger.info(f"Creating user: {username}")
                    groups = row.get("groups", "").split(",")
                    client.create_user(
                        username=username,
                        email=row["email"],
                        groups=[g.strip() for g in groups if g]
                    )
                    results["created"] += 1
            except Exception as e:
                logger.error(f"Error processing {row}: {e}")
                results["errors"].append({"user": row, "error": str(e)})

    return results

if __name__ == "__main__":
    config = WallixConfig(
        host="wallix.company.com",
        api_key=os.environ["WALLIX_API_KEY"]
    )
    client = WallixClient(config)
    results = provision_users_from_csv(client, "users.csv")
    print(f"Created: {results['created']}, Updated: {results['updated']}")
```

### Password Rotation Monitor

```python
# rotation_monitor.py - Monitor and alert on rotation failures

from wallix_client import WallixClient, WallixConfig
from datetime import datetime, timedelta
import smtplib
from email.mime.text import MIMEText

def check_rotation_status(client: WallixClient) -> dict:
    """Check for failed rotations and expiring passwords"""
    issues = {"failed": [], "expiring": []}

    accounts = client._request("GET", "/accounts?auto_rotation=true")["data"]

    for account in accounts:
        if account.get("rotation_status") == "failed":
            issues["failed"].append({
                "account": account["name"],
                "device": account["device_name"],
                "last_attempt": account.get("last_rotation_attempt"),
                "error": account.get("rotation_error")
            })

        last_rotation = account.get("last_rotation_date")
        if last_rotation:
            last_date = datetime.fromisoformat(last_rotation.replace('Z', '+00:00'))
            days_old = (datetime.now(last_date.tzinfo) - last_date).days
            max_age = account.get("rotation_period_days", 30)
            if days_old > max_age * 0.8:
                issues["expiring"].append({
                    "account": account["name"],
                    "device": account["device_name"],
                    "days_old": days_old,
                    "max_age": max_age
                })

    return issues

def send_alert(issues: dict, recipients: list) -> None:
    """Send email alert for rotation issues"""
    if not issues["failed"] and not issues["expiring"]:
        return

    body = "WALLIX Password Rotation Alert\n\n"
    if issues["failed"]:
        body += f"FAILED ROTATIONS ({len(issues['failed'])}):\n"
        for i in issues["failed"]:
            body += f"  - {i['account']}@{i['device']}: {i['error']}\n"

    if issues["expiring"]:
        body += f"\nEXPIRING PASSWORDS ({len(issues['expiring'])}):\n"
        for i in issues["expiring"]:
            body += f"  - {i['account']}@{i['device']}: {i['days_old']}/{i['max_age']} days\n"

    msg = MIMEText(body)
    msg["Subject"] = "WALLIX Password Rotation Alert"
    msg["From"] = "wallix-alerts@company.com"
    msg["To"] = ", ".join(recipients)

    with smtplib.SMTP("smtp.company.com") as server:
        server.send_message(msg)
```

### Shell Script Examples

```bash
#!/bin/bash
# wallix-health-check.sh - Daily health monitoring

set -euo pipefail

LOG_FILE="/var/log/wallix/health-check.log"
ALERT_EMAIL="pam-admins@company.com"
HOSTNAME=$(hostname)

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

alert() {
    local subject="WALLIX Alert: $1"
    local body="$2"
    echo "$body" | mail -s "$subject" "$ALERT_EMAIL"
    log "ALERT: $subject"
}

check_service() {
    if ! systemctl is-active --quiet wallix-bastion; then
        alert "Service Down on $HOSTNAME" "WALLIX Bastion service is not running!"
        return 1
    fi
    log "Service: OK"
}

check_disk() {
    local usage=$(df /var/lib/wallix --output=pcent | tail -1 | tr -d ' %')
    if [ "$usage" -gt 85 ]; then
        alert "High Disk Usage on $HOSTNAME" "Disk usage is ${usage}%"
    elif [ "$usage" -gt 70 ]; then
        log "Disk: WARNING - ${usage}%"
    else
        log "Disk: OK - ${usage}%"
    fi
}

check_database() {
    if ! sudo mysql -e "SELECT 1;" > /dev/null 2>&1; then
        alert "Database Error on $HOSTNAME" "Cannot connect to MariaDB!"
        return 1
    fi
    log "Database: OK"
}

check_sessions() {
    local count=$(wabadmin sessions --status active 2>/dev/null | wc -l || echo 0)
    log "Active Sessions: $count"
}

main() {
    log "=== Starting Health Check ==="
    check_service
    check_disk
    check_database
    check_sessions
    log "=== Health Check Complete ==="
}

main "$@"
```

### PowerShell Examples

```powershell
# Wallix.psm1 - PowerShell module for WALLIX API

function New-WallixSession {
    param(
        [Parameter(Mandatory)][string]$Host,
        [Parameter(Mandatory)][string]$ApiKey,
        [switch]$SkipCertificateCheck
    )

    $script:WallixConfig = @{
        BaseUrl = "https://$Host/api/v2"
        Headers = @{
            "Authorization" = "Bearer $ApiKey"
            "Content-Type" = "application/json"
        }
        SkipCert = $SkipCertificateCheck
    }
    Write-Host "Connected to WALLIX at $Host"
}

function Invoke-WallixApi {
    param(
        [string]$Method = "GET",
        [Parameter(Mandatory)][string]$Endpoint,
        [object]$Body
    )

    $params = @{
        Uri = "$($script:WallixConfig.BaseUrl)$Endpoint"
        Method = $Method
        Headers = $script:WallixConfig.Headers
    }

    if ($Body) { $params.Body = $Body | ConvertTo-Json -Depth 10 }
    if ($script:WallixConfig.SkipCert) { $params.SkipCertificateCheck = $true }

    $response = Invoke-RestMethod @params
    return $response.data
}

function Get-WallixUser {
    param([string]$Username)
    if ($Username) {
        return Invoke-WallixApi -Endpoint "/users?filter=username eq '$Username'"
    }
    return Invoke-WallixApi -Endpoint "/users"
}

function Get-WallixSession {
    param([switch]$Active)
    $endpoint = "/sessions"
    if ($Active) { $endpoint += "?status=active" }
    return Invoke-WallixApi -Endpoint $endpoint
}

function Stop-WallixSession {
    param([Parameter(Mandatory)][string]$SessionId)
    return Invoke-WallixApi -Method DELETE -Endpoint "/sessions/$SessionId"
}

Export-ModuleMember -Function *-Wallix*
```

### PowerShell Usage Example

```powershell
# Example usage of Wallix.psm1

Import-Module ./Wallix.psm1

# Connect to WALLIX
New-WallixSession -Host "wallix.company.com" -ApiKey $env:WALLIX_KEY

# List active sessions
$sessions = Get-WallixSession -Active
$sessions | Format-Table User, Device, StartTime

# Find specific user
$user = Get-WallixUser -Username "jsmith"
Write-Host "User $($user.username) last login: $($user.last_login)"

# Terminate idle sessions (more than 4 hours)
$idleThreshold = (Get-Date).AddHours(-4)
$sessions | Where-Object {
    [datetime]$_.last_activity -lt $idleThreshold
} | ForEach-Object {
    Write-Host "Terminating idle session: $($_.id)"
    Stop-WallixSession -SessionId $_.id
}
```

---

## Best Practices

### API Security

```
+===============================================================================+
|                       API SECURITY BEST PRACTICES                             |
+===============================================================================+
|                                                                               |
|  1. AUTHENTICATION                                                            |
|  =================                                                            |
|  [ ] Use API keys for service-to-service communication                        |
|  [ ] Rotate API keys regularly (at least annually)                            |
|  [ ] Use short-lived tokens for user-facing applications                      |
|  [ ] Store credentials securely (vault, secrets manager)                      |
|                                                                               |
|  2. AUTHORIZATION                                                             |
|  ================                                                             |
|  [ ] Apply least privilege to API keys                                        |
|  [ ] Scope permissions to specific operations                                 |
|  [ ] Use separate keys for different applications                             |
|  [ ] Audit API key usage regularly                                            |
|                                                                               |
|  3. NETWORK SECURITY                                                          |
|  ===================                                                          |
|  [ ] Always use HTTPS (TLS 1.2+)                                              |
|  [ ] Restrict API access by source IP                                         |
|  [ ] Use dedicated API endpoints (separate from user UI)                      |
|  [ ] Implement rate limiting                                                  |
|                                                                               |
|  4. ERROR HANDLING                                                            |
|  =================                                                            |
|  [ ] Don't expose sensitive info in error messages                            |
|  [ ] Log all API calls for audit                                              |
|  [ ] Implement proper error codes                                             |
|  [ ] Handle failures gracefully                                               |
|                                                                               |
+===============================================================================+
```

### Error Handling

```python
# Proper error handling example

import requests
from requests.exceptions import RequestException

def api_call_with_retry(url, method, data=None, max_retries=3):
    """API call with proper error handling and retry logic"""

    for attempt in range(max_retries):
        try:
            response = requests.request(
                method=method,
                url=url,
                headers=headers,
                json=data,
                timeout=30
            )

            # Handle specific HTTP status codes
            if response.status_code == 200:
                return {"success": True, "data": response.json()}

            elif response.status_code == 201:
                return {"success": True, "data": response.json(), "created": True}

            elif response.status_code == 400:
                return {"success": False, "error": "Bad request",
                        "details": response.json()}

            elif response.status_code == 401:
                return {"success": False, "error": "Authentication failed"}

            elif response.status_code == 403:
                return {"success": False, "error": "Permission denied"}

            elif response.status_code == 404:
                return {"success": False, "error": "Resource not found"}

            elif response.status_code == 409:
                return {"success": False, "error": "Conflict - resource exists"}

            elif response.status_code == 429:
                # Rate limited - wait and retry
                wait_time = int(response.headers.get('Retry-After', 60))
                time.sleep(wait_time)
                continue

            elif response.status_code >= 500:
                # Server error - retry
                if attempt < max_retries - 1:
                    time.sleep(2 ** attempt)  # Exponential backoff
                    continue
                return {"success": False, "error": "Server error"}

        except RequestException as e:
            if attempt < max_retries - 1:
                time.sleep(2 ** attempt)
                continue
            return {"success": False, "error": f"Request failed: {str(e)}"}

    return {"success": False, "error": "Max retries exceeded"}
```

---

## Next Steps

Continue to [10 - High Availability](../10-high-availability/README.md) for clustering and disaster recovery.
