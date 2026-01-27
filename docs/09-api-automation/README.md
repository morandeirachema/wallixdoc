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
+==============================================================================+
|                         WALLIX REST API                                       |
+==============================================================================+
|                                                                               |
|  BASE URL: https://bastion.company.com/api/                                   |
|                                                                               |
|  +---------------------------------------------------------------------+ |
|  |                           API STRUCTURE                                  | |
|  |                                                                          | |
|  |  /api/                                                                   | |
|  |  |                                                                       | |
|  |  +-- /auth                    # Authentication                          | |
|  |  |   +-- POST /login          # Get session token                       | |
|  |  |   +-- POST /logout         # Invalidate token                        | |
|  |  |                                                                       | |
|  |  +-- /users                   # User management                         | |
|  |  +-- /usergroups              # User group management                   | |
|  |  |                                                                       | |
|  |  +-- /domains                 # Domain management                       | |
|  |  +-- /devices                 # Device management                       | |
|  |  +-- /services                # Service configuration                   | |
|  |  +-- /accounts                # Account management                      | |
|  |  |                                                                       | |
|  |  +-- /targetgroups            # Target group management                 | |
|  |  +-- /authorizations          # Authorization policies                  | |
|  |  |                                                                       | |
|  |  +-- /sessions                # Session data                            | |
|  |  |   +-- /current             # Active sessions                         | |
|  |  |   +-- /history             # Historical sessions                     | |
|  |  |                                                                       | |
|  |  +-- /recordings              # Recording management                    | |
|  |  |                                                                       | |
|  |  +-- /passwords               # Password operations                     | |
|  |      +-- /checkout            # Credential checkout                     | |
|  |      +-- /change              # Password rotation                       | |
|  |                                                                          | |
|  +---------------------------------------------------------------------+ |
|                                                                               |
|  HTTP METHODS                                                                 |
|  ============                                                                 |
|                                                                               |
|  GET     - Retrieve resources                                                |
|  POST    - Create new resources                                              |
|  PUT     - Update existing resources (full replacement)                      |
|  PATCH   - Partial update of resources                                       |
|  DELETE  - Remove resources                                                  |
|                                                                               |
+==============================================================================+
```

### API Versioning

| Version | Status | Notes |
|---------|--------|-------|
| v3.0 | Current | Latest stable API |
| v2.0 | Supported | Legacy support |
| v1.0 | Deprecated | Migration recommended |

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
+==============================================================================+
|                      API AUTHENTICATION                                       |
+==============================================================================+
|                                                                               |
|  METHOD 1: Session Token (Cookie-based)                                       |
|  ======================================                                       |
|                                                                               |
|  # Login to get session cookie                                               |
|  curl -X POST https://bastion.company.com/api/auth/login \                   |
|       -H "Content-Type: application/json" \                                  |
|       -d '{"username": "admin", "password": "secret"}' \                     |
|       -c cookies.txt                                                          |
|                                                                               |
|  # Use cookie for subsequent requests                                        |
|  curl -X GET https://bastion.company.com/api/devices \                       |
|       -b cookies.txt                                                          |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  METHOD 2: API Key (Header-based)                                             |
|  ================================                                             |
|                                                                               |
|  # Use API key in header                                                     |
|  curl -X GET https://bastion.company.com/api/devices \                       |
|       -H "X-Auth-Token: your-api-key-here"                                   |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  METHOD 3: OAuth 2.0 (Bearer Token)                                           |
|  ==================================                                           |
|                                                                               |
|  # Get OAuth token                                                           |
|  curl -X POST https://bastion.company.com/oauth/token \                      |
|       -d "grant_type=client_credentials" \                                   |
|       -d "client_id=your-client-id" \                                        |
|       -d "client_secret=your-client-secret"                                  |
|                                                                               |
|  # Use bearer token                                                          |
|  curl -X GET https://bastion.company.com/api/devices \                       |
|       -H "Authorization: Bearer eyJhbGc..."                                  |
|                                                                               |
+==============================================================================+
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
+==============================================================================+
|                      DEVICE API ENDPOINTS                                     |
+==============================================================================+
|                                                                               |
|  LIST DEVICES                                                                 |
|  ============                                                                 |
|                                                                               |
|  GET /api/devices                                                             |
|                                                                               |
|  Query Parameters:                                                            |
|  * q          - Search query                                                 |
|  * domain     - Filter by domain                                             |
|  * limit      - Results per page (default: 50)                               |
|  * offset     - Pagination offset                                            |
|                                                                               |
|  Example:                                                                     |
|  GET /api/devices?domain=Production&limit=100                                |
|                                                                               |
|  Response:                                                                    |
|  {                                                                            |
|      "total": 156,                                                            |
|      "devices": [                                                             |
|          {                                                                    |
|              "device_name": "srv-prod-01",                                   |
|              "host": "192.168.1.100",                                        |
|              "domain": "Production",                                          |
|              "description": "Production web server"                          |
|          }                                                                    |
|      ]                                                                        |
|  }                                                                            |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  GET DEVICE                                                                   |
|  ==========                                                                   |
|                                                                               |
|  GET /api/devices/{device_name}                                               |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  CREATE DEVICE                                                                |
|  =============                                                                |
|                                                                               |
|  POST /api/devices                                                            |
|                                                                               |
|  Body:                                                                        |
|  {                                                                            |
|      "device_name": "srv-prod-02",                                           |
|      "host": "192.168.1.101",                                                |
|      "domain": "Production",                                                  |
|      "description": "Production app server"                                  |
|  }                                                                            |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  UPDATE DEVICE                                                                |
|  =============                                                                |
|                                                                               |
|  PUT /api/devices/{device_name}                                               |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  DELETE DEVICE                                                                |
|  =============                                                                |
|                                                                               |
|  DELETE /api/devices/{device_name}                                            |
|                                                                               |
+==============================================================================+
```

### Account Management

```
+==============================================================================+
|                      ACCOUNT API ENDPOINTS                                    |
+==============================================================================+
|                                                                               |
|  LIST ACCOUNTS                                                                |
|  =============                                                                |
|                                                                               |
|  GET /api/accounts                                                            |
|  GET /api/devices/{device_name}/accounts                                      |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  CREATE ACCOUNT                                                               |
|  ==============                                                               |
|                                                                               |
|  POST /api/accounts                                                           |
|                                                                               |
|  Body:                                                                        |
|  {                                                                            |
|      "account_name": "root@srv-prod-01",                                     |
|      "login": "root",                                                         |
|      "device": "srv-prod-01",                                                |
|      "credentials": {                                                         |
|          "type": "password",                                                  |
|          "password": "SecureP@ssw0rd!"                                       |
|      },                                                                       |
|      "auto_change_password": true,                                           |
|      "change_password_interval_days": 30                                     |
|  }                                                                            |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  GET ACCOUNT PASSWORD                                                         |
|  ====================                                                         |
|                                                                               |
|  GET /api/accounts/{account_name}/password                                    |
|                                                                               |
|  Response:                                                                    |
|  {                                                                            |
|      "password": "CurrentP@ssw0rd!",                                         |
|      "last_changed": "2024-01-15T10:30:00Z"                                  |
|  }                                                                            |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  ROTATE PASSWORD                                                              |
|  ===============                                                              |
|                                                                               |
|  POST /api/accounts/{account_name}/password/change                            |
|                                                                               |
|  Body (optional - for manual password set):                                  |
|  {                                                                            |
|      "new_password": "NewP@ssw0rd!"                                          |
|  }                                                                            |
|                                                                               |
+==============================================================================+
```

### Session Management

```
+==============================================================================+
|                      SESSION API ENDPOINTS                                    |
+==============================================================================+
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
|              "session_id": "SES-001",                                        |
|              "user": "jsmith",                                                |
|              "target": "root@srv-prod-01",                                   |
|              "protocol": "SSH",                                               |
|              "start_time": "2024-01-15T09:30:00Z",                           |
|              "duration_seconds": 3600,                                        |
|              "is_recorded": true                                             |
|          }                                                                    |
|      ]                                                                        |
|  }                                                                            |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  TERMINATE SESSION                                                            |
|  =================                                                            |
|                                                                               |
|  DELETE /api/sessions/current/{session_id}                                    |
|                                                                               |
|  Body:                                                                        |
|  {                                                                            |
|      "reason": "Security incident response"                                  |
|  }                                                                            |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  SESSION HISTORY                                                              |
|  ===============                                                              |
|                                                                               |
|  GET /api/sessions/history                                                    |
|                                                                               |
|  Query Parameters:                                                            |
|  * from_date  - Start date (ISO 8601)                                        |
|  * to_date    - End date (ISO 8601)                                          |
|  * user       - Filter by user                                               |
|  * target     - Filter by target                                             |
|  * protocol   - Filter by protocol                                           |
|                                                                               |
|  Example:                                                                     |
|  GET /api/sessions/history?from_date=2024-01-01&user=jsmith                  |
|                                                                               |
+==============================================================================+
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
+==============================================================================+
|                        CMDB INTEGRATION PATTERN                               |
+==============================================================================+
|                                                                               |
|                        +-----------------+                                   |
|                        |      CMDB       |                                   |
|                        |   (ServiceNow)  |                                   |
|                        +--------+--------+                                   |
|                                 |                                            |
|                                 | Webhook/API                                |
|                                 v                                            |
|                        +-----------------+                                   |
|                        |   Integration   |                                   |
|                        |     Service     |                                   |
|                        +--------+--------+                                   |
|                                 |                                            |
|           +---------------------+---------------------+                     |
|           |                     |                     |                     |
|           v                     v                     v                     |
|  +-----------------+  +-----------------+  +-----------------+             |
|  |  New Server     |  | Server Updated  |  | Server Retired  |             |
|  |                 |  |                 |  |                 |             |
|  | * Create Device |  | * Update Device |  | * Delete Device |             |
|  | * Create Accts  |  | * Update Accts  |  | * Delete Accts  |             |
|  | * Add to Groups |  |                 |  | * Remove Auth   |             |
|  +-----------------+  +-----------------+  +-----------------+             |
|                                                                               |
|  SYNC WORKFLOW                                                                |
|  =============                                                                |
|                                                                               |
|  1. CMDB change detected (new server provisioned)                            |
|  2. Webhook triggers integration service                                     |
|  3. Integration service:                                                     |
|     a. Validates server data                                                 |
|     b. Creates device in WALLIX                                              |
|     c. Creates default accounts (root, admin)                                |
|     d. Adds to appropriate target groups                                     |
|  4. Confirmation logged back to CMDB                                         |
|                                                                               |
+==============================================================================+
```

### ITSM Ticketing Integration

```
+==============================================================================+
|                      ITSM TICKETING INTEGRATION                               |
+==============================================================================+
|                                                                               |
|  APPROVAL WORKFLOW                                                            |
|  =================                                                            |
|                                                                               |
|  +----------+                                                                |
|  |   User   |                                                                |
|  +----+-----+                                                                |
|       |                                                                       |
|       | 1. Request access (with ticket number)                               |
|       v                                                                       |
|  +-----------------+                                                         |
|  |  WALLIX Bastion |                                                         |
|  +--------+--------+                                                         |
|           |                                                                   |
|           | 2. Validate ticket via API                                       |
|           v                                                                   |
|  +-----------------+                                                         |
|  |  ITSM System    |                                                         |
|  |  (ServiceNow)   |                                                         |
|  +--------+--------+                                                         |
|           |                                                                   |
|           | 3. Return ticket status                                          |
|           |    - Valid/Invalid                                               |
|           |    - Approved/Pending                                            |
|           |    - Authorized systems                                          |
|           v                                                                   |
|  +-----------------+                                                         |
|  |  WALLIX Bastion |                                                         |
|  +--------+--------+                                                         |
|           |                                                                   |
|           | 4. Grant/Deny access based on ticket                             |
|           v                                                                   |
|  +----------------------------------------------------------------------+   |
|  |  Session established (or denied)                                      |   |
|  |  Session ID linked to ticket number in audit                          |   |
|  +----------------------------------------------------------------------+   |
|                                                                               |
+==============================================================================+
```

---

## Best Practices

### API Security

```
+==============================================================================+
|                       API SECURITY BEST PRACTICES                             |
+==============================================================================+
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
+==============================================================================+
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
