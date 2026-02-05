# 26 - API Reference

## Table of Contents

1. [API Overview](#api-overview)
2. [Authentication](#authentication)
3. [Users & Groups](#users--groups)
4. [Devices & Accounts](#devices--accounts)
5. [Authorizations](#authorizations)
6. [Sessions](#sessions)
7. [Password Management](#password-management)
8. [System Administration](#system-administration)
9. [Complete Workflow Examples](#complete-workflow-examples)
   - [Workflow 1: Automated Credential Checkout](#workflow-1-automated-credential-checkout)
   - [Workflow 2: Session Monitoring and Alerts](#workflow-2-session-monitoring-and-alerts)
   - [Workflow 3: Bulk User Provisioning](#workflow-3-bulk-user-provisioning)
10. [SCIM API](#scim-api)

---

## API Overview

### Base URL and Versioning

```
+===============================================================================+
|                   WALLIX API OVERVIEW                                        |
+===============================================================================+

  BASE URL
  ========

  https://<wallix-host>/api/

  Version-specific endpoints:
  https://<wallix-host>/api/v2/        # Endpoint URL (current - use this)
  https://<wallix-host>/api/v1/        # REMOVED in 12.x - do not use

  --------------------------------------------------------------------------

  API VERSIONING CLARIFICATION
  =============================

  API Spec Version:  v3.12 (current features in WALLIX 12.x)
  Endpoint URLs:     /api/v2/  (for backward compatibility)

  Example: Current API is v3.12, but you still use https://bastion/api/v2/

  Terraform Provider 0.14.0 supports API v3.12

  --------------------------------------------------------------------------

  COMMON HEADERS
  ==============

  +------------------------------------------------------------------------+
  | Header              | Value                    | Required              |
  +---------------------+--------------------------+-----------------------+
  | Authorization       | Bearer <token>           | Yes                   |
  | Content-Type        | application/json         | Yes (POST/PUT/PATCH)  |
  | Accept              | application/json         | Recommended           |
  | X-Request-ID        | <uuid>                   | Optional (tracing)    |
  +---------------------+--------------------------+-----------------------+

  --------------------------------------------------------------------------

  RESPONSE FORMAT
  ===============

  Success Response:
  {
    "status": "success",
    "data": { ... },
    "meta": {
      "total": 100,
      "page": 1,
      "per_page": 25
    }
  }

  Error Response:
  {
    "status": "error",
    "error": {
      "code": "ERR_NOT_FOUND",
      "message": "Resource not found",
      "details": { ... }
    }
  }

  --------------------------------------------------------------------------

  HTTP STATUS CODES
  =================

  +--------+----------------------------+----------------------------------+
  | Code   | Meaning                    | When Used                        |
  +--------+----------------------------+----------------------------------+
  | 200    | OK                         | Successful GET/PUT/PATCH         |
  | 201    | Created                    | Successful POST                  |
  | 204    | No Content                 | Successful DELETE                |
  | 400    | Bad Request                | Invalid parameters               |
  | 401    | Unauthorized               | Missing/invalid token            |
  | 403    | Forbidden                  | Insufficient permissions         |
  | 404    | Not Found                  | Resource doesn't exist           |
  | 409    | Conflict                   | Duplicate resource               |
  | 422    | Unprocessable Entity       | Validation error                 |
  | 429    | Too Many Requests          | Rate limit exceeded              |
  | 500    | Internal Server Error      | Server error                     |
  +--------+----------------------------+----------------------------------+

  --------------------------------------------------------------------------

  PAGINATION
  ==========

  Query Parameters:
  +------------------------------------------------------------------------+
  | Parameter   | Type    | Default | Description                         |
  +-------------+---------+---------+-------------------------------------+
  | page        | integer | 1       | Page number                         |
  | per_page    | integer | 25      | Items per page (max 100)            |
  | sort        | string  | id      | Sort field                          |
  | order       | string  | asc     | Sort order (asc/desc)               |
  +-------------+---------+---------+-------------------------------------+

  Example:
  GET /api/v2/users?page=2&per_page=50&sort=name&order=asc

+===============================================================================+
```

---

## Authentication

### API Authentication Methods

```
+===============================================================================+
|                   API AUTHENTICATION                                         |
+===============================================================================+

  METHOD 1: API TOKEN (Recommended)
  =================================

  Generate API token via UI:
  Admin > System > API Keys > Generate New Key

  Usage:
  +------------------------------------------------------------------------+
  | curl -X GET "https://wallix.company.com/api/v2/users" \                |
  |   -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIs..."                   |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  METHOD 2: BASIC AUTHENTICATION (Legacy)
  =======================================

  Usage:
  +------------------------------------------------------------------------+
  | curl -X GET "https://wallix.company.com/api/v2/users" \                |
  |   -u "admin:password"                                                  |
  +------------------------------------------------------------------------+

  Or with encoded credentials:
  +------------------------------------------------------------------------+
  | curl -X GET "https://wallix.company.com/api/v2/users" \                |
  |   -H "Authorization: Basic YWRtaW46cGFzc3dvcmQ="                       |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  METHOD 3: SESSION AUTHENTICATION
  ================================

  Step 1: Login
  +------------------------------------------------------------------------+
  | POST /api/v2/auth/login                                                |
  |                                                                        |
  | Request:                                                               |
  | {                                                                      |
  |   "username": "admin",                                                 |
  |   "password": "password"                                               |
  | }                                                                      |
  |                                                                        |
  | Response:                                                              |
  | {                                                                      |
  |   "status": "success",                                                 |
  |   "data": {                                                            |
  |     "session_token": "abc123...",                                      |
  |     "expires_at": "2024-01-27T12:00:00Z"                               |
  |   }                                                                    |
  | }                                                                      |
  +------------------------------------------------------------------------+

  Step 2: Use session token
  +------------------------------------------------------------------------+
  | curl -X GET "https://wallix.company.com/api/v2/users" \                |
  |   -H "X-Session-Token: abc123..."                                      |
  +------------------------------------------------------------------------+

  Step 3: Logout
  +------------------------------------------------------------------------+
  | POST /api/v2/auth/logout                                               |
  | X-Session-Token: abc123...                                             |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  API TOKEN MANAGEMENT ENDPOINTS
  ==============================

  List API tokens:
  GET /api/v2/apikeys

  Create API token:
  POST /api/v2/apikeys
  {
    "name": "automation-key",
    "description": "Key for Ansible automation",
    "expires_at": "2025-12-31T23:59:59Z"
  }

  Revoke API token:
  DELETE /api/v2/apikeys/{key_id}

+===============================================================================+
```

---

## Users & Groups

### User Endpoints

```
+===============================================================================+
|                   USER API ENDPOINTS                                         |
+===============================================================================+

  LIST USERS
  ==========

  GET /api/v2/users

  Query Parameters:
  +------------------------------------------------------------------------+
  | Parameter   | Type    | Description                                    |
  +-------------+---------+------------------------------------------------+
  | search      | string  | Search by name, username, email                |
  | group       | string  | Filter by group name                           |
  | status      | string  | active, inactive, locked                       |
  | auth_type   | string  | local, ldap, radius                            |
  +-------------+---------+------------------------------------------------+

  Response:
  {
    "status": "success",
    "data": [
      {
        "id": "usr_12345",
        "username": "jsmith",
        "display_name": "John Smith",
        "email": "jsmith@company.com",
        "status": "active",
        "auth_type": "ldap",
        "groups": ["ot_engineers", "admin"],
        "mfa_enabled": true,
        "last_login": "2024-01-26T10:30:00Z",
        "created_at": "2023-06-15T08:00:00Z"
      }
    ],
    "meta": {
      "total": 150,
      "page": 1,
      "per_page": 25
    }
  }

  --------------------------------------------------------------------------

  GET USER
  ========

  GET /api/v2/users/{user_id}

  Response:
  {
    "status": "success",
    "data": {
      "id": "usr_12345",
      "username": "jsmith",
      "display_name": "John Smith",
      "email": "jsmith@company.com",
      "status": "active",
      "auth_type": "ldap",
      "groups": ["ot_engineers", "admin"],
      "mfa_enabled": true,
      "mfa_type": "totp",
      "language": "en",
      "timezone": "America/New_York",
      "last_login": "2024-01-26T10:30:00Z",
      "password_expires_at": "2024-04-26T10:30:00Z",
      "created_at": "2023-06-15T08:00:00Z",
      "updated_at": "2024-01-20T14:00:00Z"
    }
  }

  --------------------------------------------------------------------------

  CREATE USER
  ===========

  POST /api/v2/users

  Request:
  {
    "username": "mwilson",
    "display_name": "Mary Wilson",
    "email": "mwilson@company.com",
    "password": "<PASSWORD>",  // SECURITY: Use secure credential injection
    "groups": ["ot_operators"],
    "auth_type": "local",
    "mfa_enabled": true,
    "mfa_type": "totp",
    "language": "en",
    "timezone": "UTC",
    "password_change_required": true
  }

  Response (201 Created):
  {
    "status": "success",
    "data": {
      "id": "usr_67890",
      "username": "mwilson",
      ...
    }
  }

  --------------------------------------------------------------------------

  UPDATE USER
  ===========

  PATCH /api/v2/users/{user_id}

  Request:
  {
    "display_name": "Mary J. Wilson",
    "groups": ["ot_operators", "ot_engineers"],
    "mfa_enabled": true
  }

  Response (200 OK):
  {
    "status": "success",
    "data": { ... }
  }

  --------------------------------------------------------------------------

  DELETE USER
  ===========

  DELETE /api/v2/users/{user_id}

  Response (204 No Content)

  --------------------------------------------------------------------------

  USER ACTIONS
  ============

  Lock user:
  POST /api/v2/users/{user_id}/lock

  Unlock user:
  POST /api/v2/users/{user_id}/unlock

  Reset password:
  POST /api/v2/users/{user_id}/reset-password
  {
    "new_password": "NewSecurePassword!",
    "force_change": true
  }

  Reset MFA:
  POST /api/v2/users/{user_id}/reset-mfa

+===============================================================================+
```

### Group Endpoints

```
+===============================================================================+
|                   GROUP API ENDPOINTS                                        |
+===============================================================================+

  LIST GROUPS
  ===========

  GET /api/v2/groups

  Response:
  {
    "status": "success",
    "data": [
      {
        "id": "grp_001",
        "name": "ot_engineers",
        "description": "OT Engineering Team",
        "member_count": 15,
        "created_at": "2023-01-10T08:00:00Z"
      }
    ]
  }

  --------------------------------------------------------------------------

  GET GROUP
  =========

  GET /api/v2/groups/{group_id}

  Response:
  {
    "status": "success",
    "data": {
      "id": "grp_001",
      "name": "ot_engineers",
      "description": "OT Engineering Team",
      "members": [
        {"id": "usr_12345", "username": "jsmith"},
        {"id": "usr_67890", "username": "mwilson"}
      ],
      "authorizations": [
        {"id": "auth_001", "name": "engineers_to_plcs"}
      ],
      "created_at": "2023-01-10T08:00:00Z"
    }
  }

  --------------------------------------------------------------------------

  CREATE GROUP
  ============

  POST /api/v2/groups

  Request:
  {
    "name": "ot_vendors",
    "description": "External vendor accounts",
    "members": ["usr_12345", "usr_67890"]
  }

  --------------------------------------------------------------------------

  UPDATE GROUP
  ============

  PATCH /api/v2/groups/{group_id}

  Request:
  {
    "description": "Updated description",
    "members": ["usr_12345", "usr_67890", "usr_11111"]
  }

  --------------------------------------------------------------------------

  DELETE GROUP
  ============

  DELETE /api/v2/groups/{group_id}

  --------------------------------------------------------------------------

  GROUP MEMBERSHIP
  ================

  Add member:
  POST /api/v2/groups/{group_id}/members
  {
    "user_id": "usr_12345"
  }

  Remove member:
  DELETE /api/v2/groups/{group_id}/members/{user_id}

+===============================================================================+
```

---

## Devices & Accounts

### Device Endpoints

```
+===============================================================================+
|                   DEVICE API ENDPOINTS                                       |
+===============================================================================+

  LIST DEVICES
  ============

  GET /api/v2/devices

  Query Parameters:
  +------------------------------------------------------------------------+
  | Parameter   | Type    | Description                                    |
  +-------------+---------+------------------------------------------------+
  | search      | string  | Search by name, host, alias                    |
  | domain      | string  | Filter by domain                               |
  | type        | string  | server, network, database, industrial          |
  | protocol    | string  | ssh, rdp, telnet, vnc                          |
  +-------------+---------+------------------------------------------------+

  Response:
  {
    "status": "success",
    "data": [
      {
        "id": "dev_001",
        "name": "plc-line1",
        "host": "10.10.1.10",
        "alias": "PLC-LINE-1",
        "description": "Production Line 1 PLC",
        "domain": "ot_devices",
        "type": "industrial",
        "services": [
          {
            "id": "svc_001",
            "protocol": "ssh",
            "port": 22,
            "subprotocols": ["SSH_SHELL_SESSION"]
          }
        ],
        "status": "online",
        "last_connection": "2024-01-26T15:30:00Z",
        "created_at": "2023-03-20T10:00:00Z"
      }
    ]
  }

  --------------------------------------------------------------------------

  GET DEVICE
  ==========

  GET /api/v2/devices/{device_id}

  Response includes full device details with all services and accounts.

  --------------------------------------------------------------------------

  CREATE DEVICE
  =============

  POST /api/v2/devices

  Request:
  {
    "name": "scada-server-01",
    "host": "10.10.10.50",
    "alias": "SCADA-PRIMARY",
    "description": "Primary SCADA Server",
    "domain": "ot_scada",
    "type": "server",
    "services": [
      {
        "protocol": "rdp",
        "port": 3389,
        "subprotocols": ["RDP_CLIPBOARD", "RDP_PRINTER"]
      },
      {
        "protocol": "ssh",
        "port": 22,
        "subprotocols": ["SSH_SHELL_SESSION", "SSH_SCP"]
      }
    ]
  }

  --------------------------------------------------------------------------

  UPDATE DEVICE
  =============

  PATCH /api/v2/devices/{device_id}

  Request:
  {
    "description": "Primary SCADA Server - Updated",
    "services": [
      {
        "id": "svc_001",
        "port": 3390
      }
    ]
  }

  --------------------------------------------------------------------------

  DELETE DEVICE
  =============

  DELETE /api/v2/devices/{device_id}

  --------------------------------------------------------------------------

  DEVICE ACTIONS
  ==============

  Test connectivity:
  POST /api/v2/devices/{device_id}/test

  Response:
  {
    "status": "success",
    "data": {
      "reachable": true,
      "latency_ms": 5,
      "services": {
        "ssh": {"status": "ok", "port": 22},
        "rdp": {"status": "ok", "port": 3389}
      }
    }
  }

+===============================================================================+
```

### Account Endpoints

```
+===============================================================================+
|                   ACCOUNT API ENDPOINTS                                      |
+===============================================================================+

  LIST ACCOUNTS
  =============

  GET /api/v2/accounts

  Query Parameters:
  +------------------------------------------------------------------------+
  | Parameter   | Type    | Description                                    |
  +-------------+---------+------------------------------------------------+
  | device_id   | string  | Filter by device                               |
  | domain      | string  | Filter by domain                               |
  | type        | string  | local, domain, service                         |
  +-------------+---------+------------------------------------------------+

  Response:
  {
    "status": "success",
    "data": [
      {
        "id": "acc_001",
        "name": "root",
        "device": {
          "id": "dev_001",
          "name": "plc-line1"
        },
        "domain": "ot_devices",
        "type": "local",
        "credential_type": "password",
        "auto_rotate": true,
        "rotation_period_days": 90,
        "last_rotation": "2024-01-15T00:00:00Z",
        "next_rotation": "2024-04-15T00:00:00Z",
        "checkout_policy": "exclusive",
        "created_at": "2023-03-20T10:00:00Z"
      }
    ]
  }

  --------------------------------------------------------------------------

  GET ACCOUNT
  ===========

  GET /api/v2/accounts/{account_id}

  --------------------------------------------------------------------------

  CREATE ACCOUNT
  ==============

  POST /api/v2/accounts

  Request (Password):
  {
    "name": "admin",
    "device_id": "dev_001",
    "domain": "ot_devices",
    "type": "local",
    "credential_type": "password",
    "credentials": {
      "password": "SecurePassword123!"
    },
    "auto_rotate": true,
    "rotation_period_days": 90,
    "checkout_policy": "exclusive"
  }

  Request (SSH Key):
  {
    "name": "automation",
    "device_id": "dev_002",
    "type": "service",
    "credential_type": "ssh_key",
    "credentials": {
      "private_key": "<PRIVATE_KEY>",  // SECURITY: Never store keys in code
      "passphrase": "<PASSPHRASE>"     // SECURITY: Use secure credential injection
    }
  }

  --------------------------------------------------------------------------

  UPDATE ACCOUNT
  ==============

  PATCH /api/v2/accounts/{account_id}

  Request:
  {
    "auto_rotate": true,
    "rotation_period_days": 60
  }

  --------------------------------------------------------------------------

  DELETE ACCOUNT
  ==============

  DELETE /api/v2/accounts/{account_id}

  --------------------------------------------------------------------------

  ACCOUNT ACTIONS
  ===============

  Rotate password:
  POST /api/v2/accounts/{account_id}/rotate

  Response:
  {
    "status": "success",
    "data": {
      "rotated_at": "2024-01-27T10:00:00Z",
      "next_rotation": "2024-04-27T10:00:00Z"
    }
  }

  Checkout credential:
  POST /api/v2/accounts/{account_id}/checkout
  {
    "reason": "Maintenance task #12345",
    "duration_minutes": 60
  }

  Response:
  {
    "status": "success",
    "data": {
      "checkout_id": "chk_001",
      "credential": "<CREDENTIAL>",  // SECURITY: Credentials returned via secure channel
      "expires_at": "2024-01-27T11:00:00Z"
    }
  }

  Checkin credential:
  POST /api/v2/accounts/{account_id}/checkin
  {
    "checkout_id": "chk_001"
  }

+===============================================================================+
```

---

## Authorizations

### Authorization Endpoints

```
+===============================================================================+
|                   AUTHORIZATION API ENDPOINTS                                |
+===============================================================================+

  LIST AUTHORIZATIONS
  ===================

  GET /api/v2/authorizations

  Response:
  {
    "status": "success",
    "data": [
      {
        "id": "auth_001",
        "name": "engineers_to_plcs",
        "description": "OT Engineers access to PLCs",
        "user_group": {
          "id": "grp_001",
          "name": "ot_engineers"
        },
        "target_group": {
          "id": "tgt_001",
          "name": "plc_devices"
        },
        "accounts": ["root", "admin"],
        "is_recorded": true,
        "is_critical": false,
        "approval_required": true,
        "approvers": ["grp_002"],
        "time_restrictions": {
          "enabled": true,
          "schedule": "weekdays_business_hours"
        },
        "subprotocols": [
          "SSH_SHELL_SESSION",
          "SSH_SCP"
        ],
        "created_at": "2023-05-10T08:00:00Z"
      }
    ]
  }

  --------------------------------------------------------------------------

  GET AUTHORIZATION
  =================

  GET /api/v2/authorizations/{auth_id}

  --------------------------------------------------------------------------

  CREATE AUTHORIZATION
  ====================

  POST /api/v2/authorizations

  Request:
  {
    "name": "vendors_to_robots",
    "description": "Vendor access to robot controllers",
    "user_group_id": "grp_003",
    "target_group_id": "tgt_002",
    "accounts": ["vendor_svc"],
    "is_recorded": true,
    "is_critical": true,
    "approval_required": true,
    "approval_timeout_minutes": 30,
    "approvers": ["grp_001", "grp_002"],
    "time_restrictions": {
      "enabled": true,
      "allowed_days": ["monday", "tuesday", "wednesday", "thursday", "friday"],
      "allowed_hours": {
        "start": "08:00",
        "end": "18:00"
      },
      "timezone": "America/New_York"
    },
    "subprotocols": ["RDP_CLIPBOARD", "RDP_PRINTER"],
    "max_session_duration_minutes": 240
  }

  --------------------------------------------------------------------------

  UPDATE AUTHORIZATION
  ====================

  PATCH /api/v2/authorizations/{auth_id}

  Request:
  {
    "approval_required": true,
    "time_restrictions": {
      "enabled": true,
      "allowed_days": ["monday", "wednesday", "friday"]
    }
  }

  --------------------------------------------------------------------------

  DELETE AUTHORIZATION
  ====================

  DELETE /api/v2/authorizations/{auth_id}

+===============================================================================+
```

### Approval Endpoints

```
+===============================================================================+
|                   APPROVAL API ENDPOINTS                                     |
+===============================================================================+

  LIST PENDING APPROVALS
  ======================

  GET /api/v2/approvals?status=pending

  Response:
  {
    "status": "success",
    "data": [
      {
        "id": "apr_001",
        "type": "session_access",
        "status": "pending",
        "requestor": {
          "id": "usr_001",
          "username": "vendor1"
        },
        "target": {
          "device": "robot-controller-1",
          "account": "admin"
        },
        "authorization": {
          "id": "auth_001",
          "name": "vendors_to_robots"
        },
        "reason": "Scheduled maintenance",
        "requested_at": "2024-01-27T09:00:00Z",
        "expires_at": "2024-01-27T09:30:00Z"
      }
    ]
  }

  --------------------------------------------------------------------------

  APPROVE REQUEST
  ===============

  POST /api/v2/approvals/{approval_id}/approve

  Request:
  {
    "comment": "Approved for scheduled maintenance window"
  }

  --------------------------------------------------------------------------

  DENY REQUEST
  ============

  POST /api/v2/approvals/{approval_id}/deny

  Request:
  {
    "comment": "Not authorized - contact supervisor"
  }

+===============================================================================+
```

---

## Sessions

### Session Endpoints

```
+===============================================================================+
|                   SESSION API ENDPOINTS                                      |
+===============================================================================+

  LIST SESSIONS
  =============

  GET /api/v2/sessions

  Query Parameters:
  +------------------------------------------------------------------------+
  | Parameter   | Type     | Description                                   |
  +-------------+----------+-----------------------------------------------+
  | status      | string   | active, closed, terminated                    |
  | user_id     | string   | Filter by user                                |
  | device_id   | string   | Filter by device                              |
  | start_date  | datetime | Sessions after this date                      |
  | end_date    | datetime | Sessions before this date                     |
  | protocol    | string   | ssh, rdp, vnc                                 |
  +-------------+----------+-----------------------------------------------+

  Response:
  {
    "status": "success",
    "data": [
      {
        "id": "ses_001",
        "status": "active",
        "user": {
          "id": "usr_001",
          "username": "jsmith"
        },
        "device": {
          "id": "dev_001",
          "name": "plc-line1",
          "host": "10.10.1.10"
        },
        "account": "root",
        "protocol": "ssh",
        "client_ip": "192.168.1.100",
        "started_at": "2024-01-27T10:00:00Z",
        "duration_seconds": 1800,
        "is_recorded": true,
        "recording_id": "rec_001"
      }
    ]
  }

  --------------------------------------------------------------------------

  GET SESSION
  ===========

  GET /api/v2/sessions/{session_id}

  Response includes full session details, metadata, and recording info.

  --------------------------------------------------------------------------

  GET ACTIVE SESSIONS
  ===================

  GET /api/v2/sessions/active

  Shortcut for status=active filter.

  --------------------------------------------------------------------------

  TERMINATE SESSION
  =================

  POST /api/v2/sessions/{session_id}/terminate

  Request:
  {
    "reason": "Security incident - immediate termination required"
  }

  Response:
  {
    "status": "success",
    "data": {
      "terminated_at": "2024-01-27T10:30:00Z",
      "terminated_by": "admin"
    }
  }

  --------------------------------------------------------------------------

  GET SESSION RECORDING
  =====================

  GET /api/v2/sessions/{session_id}/recording

  Response:
  {
    "status": "success",
    "data": {
      "recording_id": "rec_001",
      "format": "wallix",
      "size_bytes": 15728640,
      "duration_seconds": 1800,
      "download_url": "/api/v2/recordings/rec_001/download",
      "expires_at": "2024-01-27T11:00:00Z"
    }
  }

  Download recording:
  GET /api/v2/recordings/{recording_id}/download

  Returns binary file (video or session data).

  --------------------------------------------------------------------------

  SEARCH SESSION CONTENT
  ======================

  POST /api/v2/sessions/search

  Request:
  {
    "query": "rm -rf",
    "start_date": "2024-01-01",
    "end_date": "2024-01-31",
    "user_id": null,
    "device_id": null,
    "search_type": "command"
  }

  Response:
  {
    "status": "success",
    "data": [
      {
        "session_id": "ses_001",
        "timestamp": "2024-01-15T14:30:00Z",
        "match": "rm -rf /tmp/cache",
        "context": {
          "before": "cd /tmp",
          "after": "ls -la"
        }
      }
    ]
  }

+===============================================================================+
```

---

## Password Management

### Credential Endpoints

```
+===============================================================================+
|                   PASSWORD MANAGEMENT API                                    |
+===============================================================================+

  TRIGGER PASSWORD ROTATION
  =========================

  POST /api/v2/passwords/rotate

  Request (single account):
  {
    "account_id": "acc_001"
  }

  Request (bulk rotation):
  {
    "account_ids": ["acc_001", "acc_002", "acc_003"]
  }

  Request (by criteria):
  {
    "domain": "ot_devices",
    "last_rotation_before": "2024-01-01"
  }

  Response:
  {
    "status": "success",
    "data": {
      "rotation_job_id": "job_001",
      "accounts_queued": 3,
      "status": "in_progress"
    }
  }

  --------------------------------------------------------------------------

  GET ROTATION STATUS
  ===================

  GET /api/v2/passwords/rotation-jobs/{job_id}

  Response:
  {
    "status": "success",
    "data": {
      "job_id": "job_001",
      "status": "completed",
      "started_at": "2024-01-27T10:00:00Z",
      "completed_at": "2024-01-27T10:05:00Z",
      "results": [
        {"account_id": "acc_001", "status": "success"},
        {"account_id": "acc_002", "status": "success"},
        {"account_id": "acc_003", "status": "failed", "error": "Connection timeout"}
      ]
    }
  }

  --------------------------------------------------------------------------

  GET ROTATION HISTORY
  ====================

  GET /api/v2/accounts/{account_id}/rotation-history

  Response:
  {
    "status": "success",
    "data": [
      {
        "rotated_at": "2024-01-15T00:00:00Z",
        "rotated_by": "system",
        "status": "success"
      },
      {
        "rotated_at": "2023-10-15T00:00:00Z",
        "rotated_by": "admin",
        "status": "success"
      }
    ]
  }

  --------------------------------------------------------------------------

  CREDENTIAL CHECKOUT HISTORY
  ===========================

  GET /api/v2/accounts/{account_id}/checkout-history

  Response:
  {
    "status": "success",
    "data": [
      {
        "checkout_id": "chk_001",
        "user": {
          "id": "usr_001",
          "username": "jsmith"
        },
        "checked_out_at": "2024-01-26T10:00:00Z",
        "checked_in_at": "2024-01-26T11:30:00Z",
        "reason": "Maintenance task"
      }
    ]
  }

+===============================================================================+
```

---

## System Administration

### System Endpoints

```
+===============================================================================+
|                   SYSTEM ADMINISTRATION API                                  |
+===============================================================================+

  SYSTEM STATUS
  =============

  GET /api/v2/system/status

  Response:
  {
    "status": "success",
    "data": {
      "version": "12.1.1",
      "uptime_seconds": 864000,
      "status": "healthy",
      "components": {
        "session_manager": "running",
        "password_manager": "running",
        "database": "connected",
        "recording_storage": "available"
      },
      "license": {
        "type": "enterprise",
        "valid_until": "2025-12-31",
        "sessions_limit": 1000,
        "sessions_used": 45
      },
      "cluster": {
        "mode": "active-standby",
        "node_role": "primary",
        "peer_status": "connected"
      }
    }
  }

  --------------------------------------------------------------------------

  SYSTEM HEALTH
  =============

  GET /api/v2/system/health

  Response:
  {
    "status": "success",
    "data": {
      "overall": "healthy",
      "checks": {
        "database": {"status": "ok", "latency_ms": 5},
        "storage": {"status": "ok", "free_space_gb": 450},
        "memory": {"status": "ok", "used_percent": 65},
        "cpu": {"status": "ok", "load_average": 1.2}
      }
    }
  }

  --------------------------------------------------------------------------

  AUDIT LOGS
  ==========

  GET /api/v2/audit/logs

  Query Parameters:
  +------------------------------------------------------------------------+
  | Parameter   | Type     | Description                                   |
  +-------------+----------+-----------------------------------------------+
  | start_date  | datetime | Logs after this date                          |
  | end_date    | datetime | Logs before this date                         |
  | event_type  | string   | login, session, config, admin                 |
  | user_id     | string   | Filter by user                                |
  | severity    | string   | info, warning, error, critical                |
  +-------------+----------+-----------------------------------------------+

  Response:
  {
    "status": "success",
    "data": [
      {
        "id": "log_001",
        "timestamp": "2024-01-27T10:00:00Z",
        "event_type": "session.start",
        "severity": "info",
        "user": {
          "id": "usr_001",
          "username": "jsmith"
        },
        "details": {
          "device": "plc-line1",
          "protocol": "ssh",
          "client_ip": "192.168.1.100"
        }
      }
    ]
  }

  --------------------------------------------------------------------------

  CONFIGURATION EXPORT
  ====================

  GET /api/v2/system/config/export

  Response: Binary file (configuration backup)

  --------------------------------------------------------------------------

  CONFIGURATION IMPORT
  ====================

  POST /api/v2/system/config/import

  Request: multipart/form-data with config file

  --------------------------------------------------------------------------

  LICENSE MANAGEMENT
  ==================

  GET /api/v2/system/license

  Response:
  {
    "status": "success",
    "data": {
      "type": "enterprise",
      "customer": "ACME Corporation",
      "valid_from": "2024-01-01",
      "valid_until": "2025-12-31",
      "features": ["session_recording", "password_rotation", "ha_cluster"],
      "limits": {
        "max_sessions": 1000,
        "max_users": 500,
        "max_devices": 2000
      },
      "usage": {
        "current_sessions": 45,
        "total_users": 150,
        "total_devices": 500
      }
    }
  }

  Upload new license:
  POST /api/v2/system/license
  {
    "license_key": "XXXX-XXXX-XXXX-XXXX"
  }

+===============================================================================+
```

---

## Complete Workflow Examples

### Overview

This section provides production-ready Python implementations for common WALLIX Bastion API workflows. Each example includes error handling, logging, retry logic, and best practices for enterprise deployments.

### Workflow 1: Automated Credential Checkout

This workflow implements a context manager for secure credential checkout with automatic check-in, retry logic, and comprehensive error handling.

```python
#!/usr/bin/env python3
"""
WALLIX Bastion Credential Checkout Automation
Secure credential checkout with automatic check-in using context manager
"""

import requests
import logging
import time
from typing import Optional, Dict, Any
from contextlib import contextmanager
from datetime import datetime, timedelta

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class WallixAPIError(Exception):
    """Base exception for WALLIX API errors"""
    pass


class CheckoutError(WallixAPIError):
    """Credential checkout failed"""
    pass


class CheckinError(WallixAPIError):
    """Credential check-in failed"""
    pass


class WallixCredentialManager:
    """
    Manages credential checkout and check-in operations with the WALLIX Bastion API.

    Features:
    - Automatic retry with exponential backoff
    - Context manager support for automatic check-in
    - Comprehensive error handling and logging
    - Token refresh handling
    """

    def __init__(self, base_url: str, api_token: str,
                 max_retries: int = 3, timeout: int = 30):
        """
        Initialize the credential manager.

        Args:
            base_url: WALLIX Bastion base URL (e.g., https://bastion.company.com)
            api_token: API authentication token
            max_retries: Maximum number of retry attempts for failed requests
            timeout: Request timeout in seconds
        """
        self.base_url = base_url.rstrip('/')
        self.api_token = api_token
        self.max_retries = max_retries
        self.timeout = timeout
        self.session = requests.Session()
        self.session.headers.update({
            'Authorization': f'Bearer {api_token}',
            'Content-Type': 'application/json',
            'Accept': 'application/json'
        })

        logger.info(f"Initialized WallixCredentialManager for {base_url}")

    def _make_request(self, method: str, endpoint: str,
                      data: Optional[Dict] = None) -> Dict[str, Any]:
        """
        Make HTTP request with retry logic and error handling.

        Args:
            method: HTTP method (GET, POST, etc.)
            endpoint: API endpoint path
            data: Request payload (for POST/PUT/PATCH)

        Returns:
            Response JSON data

        Raises:
            WallixAPIError: On API error after all retries exhausted
        """
        url = f"{self.base_url}{endpoint}"

        for attempt in range(1, self.max_retries + 1):
            try:
                logger.debug(f"Request attempt {attempt}/{self.max_retries}: {method} {url}")

                response = self.session.request(
                    method=method,
                    url=url,
                    json=data,
                    timeout=self.timeout,
                    verify=True  # Always verify SSL in production
                )

                # Handle rate limiting
                if response.status_code == 429:
                    retry_after = int(response.headers.get('Retry-After', 60))
                    logger.warning(f"Rate limited. Waiting {retry_after}s before retry")
                    time.sleep(retry_after)
                    continue

                # Raise for 4xx/5xx errors
                response.raise_for_status()

                return response.json()

            except requests.exceptions.Timeout:
                logger.warning(f"Request timeout (attempt {attempt}/{self.max_retries})")
                if attempt == self.max_retries:
                    raise WallixAPIError(f"Request timed out after {self.max_retries} attempts")
                time.sleep(2 ** attempt)  # Exponential backoff

            except requests.exceptions.HTTPError as e:
                logger.error(f"HTTP error: {e.response.status_code} - {e.response.text}")
                if attempt == self.max_retries:
                    raise WallixAPIError(f"HTTP error: {e.response.status_code}")
                time.sleep(2 ** attempt)

            except requests.exceptions.RequestException as e:
                logger.error(f"Request error: {str(e)}")
                if attempt == self.max_retries:
                    raise WallixAPIError(f"Request failed: {str(e)}")
                time.sleep(2 ** attempt)

        raise WallixAPIError("Max retries exceeded")

    def checkout_credential(self, account_id: str, reason: str,
                           duration_minutes: int = 60) -> Dict[str, Any]:
        """
        Check out a credential from the WALLIX vault.

        Args:
            account_id: Account ID to checkout
            reason: Justification for credential access (audit trail)
            duration_minutes: Checkout duration in minutes (default: 60)

        Returns:
            Dictionary containing checkout_id, credential, and expires_at

        Raises:
            CheckoutError: If checkout fails
        """
        logger.info(f"Checking out credential for account {account_id}")

        try:
            response = self._make_request(
                method='POST',
                endpoint=f'/api/v2/accounts/{account_id}/checkout',
                data={
                    'reason': reason,
                    'duration_minutes': duration_minutes
                }
            )

            checkout_data = response.get('data', {})
            checkout_id = checkout_data.get('checkout_id')
            expires_at = checkout_data.get('expires_at')

            logger.info(f"Credential checked out successfully: {checkout_id}")
            logger.info(f"Checkout expires at: {expires_at}")

            return checkout_data

        except WallixAPIError as e:
            logger.error(f"Checkout failed: {str(e)}")
            raise CheckoutError(f"Failed to checkout credential: {str(e)}")

    def checkin_credential(self, account_id: str, checkout_id: str) -> None:
        """
        Check in (return) a credential to the WALLIX vault.

        Args:
            account_id: Account ID
            checkout_id: Checkout ID from the checkout operation

        Raises:
            CheckinError: If check-in fails
        """
        logger.info(f"Checking in credential {checkout_id} for account {account_id}")

        try:
            self._make_request(
                method='POST',
                endpoint=f'/api/v2/accounts/{account_id}/checkin',
                data={'checkout_id': checkout_id}
            )

            logger.info(f"Credential checked in successfully: {checkout_id}")

        except WallixAPIError as e:
            logger.error(f"Check-in failed: {str(e)}")
            raise CheckinError(f"Failed to check-in credential: {str(e)}")

    @contextmanager
    def credential_checkout(self, account_id: str, reason: str,
                           duration_minutes: int = 60):
        """
        Context manager for automatic credential checkout and check-in.

        Usage:
            with manager.credential_checkout('acc_001', 'Deploy app') as cred:
                password = cred['credential']
                # Use credential...
            # Credential automatically checked in when context exits

        Args:
            account_id: Account ID to checkout
            reason: Justification for access
            duration_minutes: Checkout duration

        Yields:
            Checkout data dictionary with credential
        """
        checkout_data = None
        checkout_id = None

        try:
            # Checkout credential
            checkout_data = self.checkout_credential(account_id, reason, duration_minutes)
            checkout_id = checkout_data.get('checkout_id')

            # Yield credential to caller
            yield checkout_data

        except Exception as e:
            logger.error(f"Error during credential usage: {str(e)}")
            raise

        finally:
            # Always attempt check-in, even if error occurred
            if checkout_id:
                try:
                    self.checkin_credential(account_id, checkout_id)
                except CheckinError as e:
                    # Log but don't raise - credential will auto-expire
                    logger.error(f"Failed to check-in credential: {str(e)}")
                    logger.warning(f"Credential will auto-expire at {checkout_data.get('expires_at')}")


# Usage Examples
def example_basic_checkout():
    """Example: Basic credential checkout with context manager"""

    manager = WallixCredentialManager(
        base_url='https://bastion.company.com',
        api_token='your-api-token-here'
    )

    # Automatic check-in with context manager
    with manager.credential_checkout(
        account_id='acc_001',
        reason='Deploy application v2.1',
        duration_minutes=30
    ) as checkout:

        credential = checkout['credential']
        checkout_id = checkout['checkout_id']
        expires_at = checkout['expires_at']

        logger.info(f"Using credential (expires: {expires_at})")

        # Use credential for operations
        # Example: Connect to remote system, deploy code, etc.
        # credential is automatically checked in when context exits


def example_error_handling():
    """Example: Error handling for failed checkout"""

    manager = WallixCredentialManager(
        base_url='https://bastion.company.com',
        api_token='your-api-token-here'
    )

    try:
        with manager.credential_checkout(
            account_id='acc_invalid',
            reason='Test operation',
            duration_minutes=15
        ) as checkout:
            # This won't execute if checkout fails
            credential = checkout['credential']

    except CheckoutError as e:
        logger.error(f"Checkout failed: {e}")
        # Handle error (send alert, retry later, etc.)

    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        # Handle unexpected errors


def example_batch_operations():
    """Example: Checkout multiple credentials for batch operations"""

    manager = WallixCredentialManager(
        base_url='https://bastion.company.com',
        api_token='your-api-token-here'
    )

    accounts = [
        {'id': 'acc_001', 'name': 'db-prod-admin'},
        {'id': 'acc_002', 'name': 'app-prod-deploy'},
        {'id': 'acc_003', 'name': 'backup-service'}
    ]

    for account in accounts:
        try:
            with manager.credential_checkout(
                account_id=account['id'],
                reason=f"Batch maintenance - {account['name']}",
                duration_minutes=45
            ) as checkout:

                logger.info(f"Processing account: {account['name']}")
                credential = checkout['credential']

                # Perform operations with credential
                # Each credential is automatically checked in

        except CheckoutError as e:
            logger.error(f"Failed to process {account['name']}: {e}")
            continue  # Continue with next account


if __name__ == '__main__':
    # Run example
    example_basic_checkout()
```

---

### Workflow 2: Session Monitoring and Alerts

This workflow monitors active sessions for suspicious activity and sends alerts via email or Slack webhooks.

```python
#!/usr/bin/env python3
"""
WALLIX Bastion Session Monitoring with Alerting
Monitors active sessions and alerts on suspicious activity
"""

import requests
import logging
import time
import json
from typing import List, Dict, Any, Optional
from dataclasses import dataclass, asdict
from datetime import datetime, timedelta
from enum import Enum

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class AlertSeverity(Enum):
    """Alert severity levels"""
    INFO = "info"
    WARNING = "warning"
    CRITICAL = "critical"


@dataclass
class SessionAlert:
    """Session alert data structure"""
    severity: AlertSeverity
    session_id: str
    user: str
    device: str
    alert_type: str
    message: str
    timestamp: str
    details: Dict[str, Any]

    def to_dict(self) -> Dict[str, Any]:
        """Convert alert to dictionary"""
        data = asdict(self)
        data['severity'] = self.severity.value
        return data


class WallixSessionMonitor:
    """
    Monitors WALLIX Bastion sessions for suspicious activity.

    Features:
    - Failed login detection
    - Long-running session alerts
    - Concurrent session monitoring
    - Unusual access pattern detection
    - Multi-channel alerting (email, Slack, webhooks)
    """

    def __init__(self, base_url: str, api_token: str, config: Optional[Dict] = None):
        """
        Initialize session monitor.

        Args:
            base_url: WALLIX Bastion base URL
            api_token: API authentication token
            config: Configuration dictionary with alert thresholds
        """
        self.base_url = base_url.rstrip('/')
        self.api_token = api_token
        self.session = requests.Session()
        self.session.headers.update({
            'Authorization': f'Bearer {api_token}',
            'Content-Type': 'application/json'
        })

        # Default configuration
        self.config = {
            'failed_login_threshold': 3,
            'long_session_hours': 8,
            'concurrent_session_threshold': 5,
            'check_interval_seconds': 60,
            'alert_channels': {
                'slack_webhook': None,
                'email_api': None
            }
        }

        if config:
            self.config.update(config)

        logger.info("Session monitor initialized")

    def _make_request(self, endpoint: str, params: Optional[Dict] = None) -> Dict:
        """Make API request with error handling"""
        try:
            url = f"{self.base_url}{endpoint}"
            response = self.session.get(url, params=params, timeout=30)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            logger.error(f"API request failed: {e}")
            return {}

    def get_active_sessions(self) -> List[Dict[str, Any]]:
        """
        Get all currently active sessions.

        Returns:
            List of active session dictionaries
        """
        logger.debug("Fetching active sessions")

        response = self._make_request('/api/v2/sessions/active')
        sessions = response.get('data', [])

        logger.info(f"Found {len(sessions)} active sessions")
        return sessions

    def get_failed_logins(self, minutes: int = 15) -> List[Dict[str, Any]]:
        """
        Get failed login attempts in the last N minutes.

        Args:
            minutes: Time window for failed login search

        Returns:
            List of failed login audit entries
        """
        start_date = (datetime.utcnow() - timedelta(minutes=minutes)).isoformat() + 'Z'

        params = {
            'event_type': 'auth',
            'outcome': 'failure',
            'start_date': start_date
        }

        response = self._make_request('/api/v2/audit/logs', params=params)
        return response.get('data', [])

    def check_failed_logins(self) -> List[SessionAlert]:
        """
        Check for excessive failed login attempts.

        Returns:
            List of alerts for users with excessive failed logins
        """
        alerts = []
        failed_logins = self.get_failed_logins(minutes=15)

        # Group by user
        user_failures = {}
        for login in failed_logins:
            user = login.get('user', {}).get('username', 'unknown')
            if user not in user_failures:
                user_failures[user] = []
            user_failures[user].append(login)

        # Check threshold
        threshold = self.config['failed_login_threshold']
        for user, failures in user_failures.items():
            if len(failures) >= threshold:
                alert = SessionAlert(
                    severity=AlertSeverity.WARNING,
                    session_id='N/A',
                    user=user,
                    device='N/A',
                    alert_type='excessive_failed_logins',
                    message=f"User {user} has {len(failures)} failed login attempts in 15 minutes",
                    timestamp=datetime.utcnow().isoformat() + 'Z',
                    details={
                        'failure_count': len(failures),
                        'threshold': threshold,
                        'client_ips': list(set(f.get('user', {}).get('ip') for f in failures))
                    }
                )
                alerts.append(alert)
                logger.warning(f"Alert: {alert.message}")

        return alerts

    def check_long_sessions(self, sessions: List[Dict]) -> List[SessionAlert]:
        """
        Check for sessions exceeding maximum duration.

        Args:
            sessions: List of active sessions

        Returns:
            List of alerts for long-running sessions
        """
        alerts = []
        max_hours = self.config['long_session_hours']
        max_seconds = max_hours * 3600

        for session in sessions:
            duration = session.get('duration_seconds', 0)
            if duration > max_seconds:
                hours = duration / 3600
                alert = SessionAlert(
                    severity=AlertSeverity.WARNING,
                    session_id=session.get('id'),
                    user=session.get('user', {}).get('username', 'unknown'),
                    device=session.get('device', {}).get('name', 'unknown'),
                    alert_type='long_running_session',
                    message=f"Session has been active for {hours:.1f} hours (max: {max_hours})",
                    timestamp=datetime.utcnow().isoformat() + 'Z',
                    details={
                        'duration_hours': round(hours, 2),
                        'started_at': session.get('started_at'),
                        'protocol': session.get('protocol'),
                        'client_ip': session.get('client_ip')
                    }
                )
                alerts.append(alert)
                logger.warning(f"Alert: {alert.message}")

        return alerts

    def check_concurrent_sessions(self, sessions: List[Dict]) -> List[SessionAlert]:
        """
        Check for users with excessive concurrent sessions.

        Args:
            sessions: List of active sessions

        Returns:
            List of alerts for users with too many concurrent sessions
        """
        alerts = []
        threshold = self.config['concurrent_session_threshold']

        # Group by user
        user_sessions = {}
        for session in sessions:
            user = session.get('user', {}).get('username', 'unknown')
            if user not in user_sessions:
                user_sessions[user] = []
            user_sessions[user].append(session)

        # Check threshold
        for user, user_sess in user_sessions.items():
            if len(user_sess) >= threshold:
                alert = SessionAlert(
                    severity=AlertSeverity.WARNING,
                    session_id='multiple',
                    user=user,
                    device='multiple',
                    alert_type='excessive_concurrent_sessions',
                    message=f"User {user} has {len(user_sess)} concurrent sessions (max: {threshold})",
                    timestamp=datetime.utcnow().isoformat() + 'Z',
                    details={
                        'session_count': len(user_sess),
                        'threshold': threshold,
                        'devices': [s.get('device', {}).get('name') for s in user_sess],
                        'session_ids': [s.get('id') for s in user_sess]
                    }
                )
                alerts.append(alert)
                logger.warning(f"Alert: {alert.message}")

        return alerts

    def send_slack_alert(self, alert: SessionAlert) -> bool:
        """
        Send alert to Slack webhook.

        Args:
            alert: Alert to send

        Returns:
            True if sent successfully
        """
        webhook_url = self.config['alert_channels'].get('slack_webhook')
        if not webhook_url:
            logger.debug("Slack webhook not configured")
            return False

        # Color code by severity
        color_map = {
            AlertSeverity.INFO: '#36a64f',
            AlertSeverity.WARNING: '#ff9900',
            AlertSeverity.CRITICAL: '#ff0000'
        }

        payload = {
            'attachments': [{
                'color': color_map.get(alert.severity, '#808080'),
                'title': f"WALLIX Security Alert: {alert.alert_type}",
                'text': alert.message,
                'fields': [
                    {'title': 'Severity', 'value': alert.severity.value.upper(), 'short': True},
                    {'title': 'User', 'value': alert.user, 'short': True},
                    {'title': 'Device', 'value': alert.device, 'short': True},
                    {'title': 'Session ID', 'value': alert.session_id, 'short': True},
                    {'title': 'Timestamp', 'value': alert.timestamp, 'short': False}
                ],
                'footer': 'WALLIX Bastion Monitor',
                'ts': int(datetime.utcnow().timestamp())
            }]
        }

        try:
            response = requests.post(webhook_url, json=payload, timeout=10)
            response.raise_for_status()
            logger.info(f"Slack alert sent: {alert.alert_type}")
            return True
        except requests.exceptions.RequestException as e:
            logger.error(f"Failed to send Slack alert: {e}")
            return False

    def send_email_alert(self, alert: SessionAlert) -> bool:
        """
        Send alert via email API.

        Args:
            alert: Alert to send

        Returns:
            True if sent successfully
        """
        email_api = self.config['alert_channels'].get('email_api')
        if not email_api:
            logger.debug("Email API not configured")
            return False

        # Construct email body
        body = f"""
WALLIX Bastion Security Alert

Alert Type: {alert.alert_type}
Severity: {alert.severity.value.upper()}
Timestamp: {alert.timestamp}

User: {alert.user}
Device: {alert.device}
Session ID: {alert.session_id}

Message:
{alert.message}

Details:
{json.dumps(alert.details, indent=2)}

This is an automated alert from WALLIX Bastion Session Monitor.
"""

        payload = {
            'to': email_api.get('recipients', []),
            'subject': f"[WALLIX] Security Alert - {alert.alert_type}",
            'body': body
        }

        try:
            response = requests.post(
                email_api.get('endpoint'),
                json=payload,
                headers={'Authorization': f"Bearer {email_api.get('token')}"},
                timeout=10
            )
            response.raise_for_status()
            logger.info(f"Email alert sent: {alert.alert_type}")
            return True
        except requests.exceptions.RequestException as e:
            logger.error(f"Failed to send email alert: {e}")
            return False

    def send_alert(self, alert: SessionAlert):
        """
        Send alert to all configured channels.

        Args:
            alert: Alert to send
        """
        self.send_slack_alert(alert)
        self.send_email_alert(alert)

    def monitor_sessions(self):
        """
        Main monitoring loop - check sessions and send alerts.
        """
        logger.info("Starting session monitoring")

        # Get active sessions
        sessions = self.get_active_sessions()

        # Run all checks
        alerts = []
        alerts.extend(self.check_failed_logins())
        alerts.extend(self.check_long_sessions(sessions))
        alerts.extend(self.check_concurrent_sessions(sessions))

        # Send alerts
        for alert in alerts:
            self.send_alert(alert)

        logger.info(f"Monitoring cycle complete: {len(alerts)} alerts generated")

    def run_continuous(self):
        """
        Run monitoring continuously with configured interval.
        """
        interval = self.config['check_interval_seconds']
        logger.info(f"Starting continuous monitoring (interval: {interval}s)")

        while True:
            try:
                self.monitor_sessions()
                time.sleep(interval)
            except KeyboardInterrupt:
                logger.info("Monitoring stopped by user")
                break
            except Exception as e:
                logger.error(f"Monitoring error: {e}")
                time.sleep(interval)


# Usage Examples
def example_basic_monitoring():
    """Example: Basic session monitoring"""

    config = {
        'failed_login_threshold': 3,
        'long_session_hours': 8,
        'concurrent_session_threshold': 5,
        'check_interval_seconds': 300,  # 5 minutes
        'alert_channels': {
            'slack_webhook': 'https://hooks.slack.com/services/YOUR/WEBHOOK/URL'
        }
    }

    monitor = WallixSessionMonitor(
        base_url='https://bastion.company.com',
        api_token='your-api-token-here',
        config=config
    )

    # Run single monitoring cycle
    monitor.monitor_sessions()


def example_continuous_monitoring():
    """Example: Continuous monitoring"""

    config = {
        'failed_login_threshold': 5,
        'long_session_hours': 12,
        'concurrent_session_threshold': 10,
        'check_interval_seconds': 60,
        'alert_channels': {
            'slack_webhook': 'https://hooks.slack.com/services/YOUR/WEBHOOK/URL',
            'email_api': {
                'endpoint': 'https://api.emailprovider.com/send',
                'token': 'your-email-api-token',
                'recipients': ['security@company.com', 'ops@company.com']
            }
        }
    }

    monitor = WallixSessionMonitor(
        base_url='https://bastion.company.com',
        api_token='your-api-token-here',
        config=config
    )

    # Run continuously (press Ctrl+C to stop)
    monitor.run_continuous()


if __name__ == '__main__':
    # Run example
    example_basic_monitoring()
```

---

### Workflow 3: Bulk User Provisioning

This workflow implements end-to-end user provisioning from CSV with group assignment, authorization setup, and rollback capabilities.

```python
#!/usr/bin/env python3
"""
WALLIX Bastion Bulk User Provisioning
Provision users from CSV with group assignment and authorization setup
"""

import requests
import logging
import csv
import json
from typing import List, Dict, Any, Optional
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


@dataclass
class UserProvisionResult:
    """Result of user provisioning operation"""
    username: str
    status: str  # success, failed, skipped
    user_id: Optional[str] = None
    error: Optional[str] = None
    groups_assigned: List[str] = field(default_factory=list)
    authorizations_created: List[str] = field(default_factory=list)

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary"""
        return {
            'username': self.username,
            'status': self.status,
            'user_id': self.user_id,
            'error': self.error,
            'groups_assigned': self.groups_assigned,
            'authorizations_created': self.authorizations_created
        }


class WallixUserProvisioner:
    """
    Bulk user provisioning for WALLIX Bastion.

    Features:
    - CSV import with validation
    - User creation with configurable defaults
    - Automatic group assignment
    - Authorization creation
    - Transaction-like rollback on errors
    - Detailed result reporting
    """

    def __init__(self, base_url: str, api_token: str, dry_run: bool = False):
        """
        Initialize provisioner.

        Args:
            base_url: WALLIX Bastion base URL
            api_token: API authentication token
            dry_run: If True, validate only without making changes
        """
        self.base_url = base_url.rstrip('/')
        self.api_token = api_token
        self.dry_run = dry_run
        self.session = requests.Session()
        self.session.headers.update({
            'Authorization': f'Bearer {api_token}',
            'Content-Type': 'application/json'
        })

        # Track created resources for rollback
        self.created_users = []
        self.created_groups = []
        self.created_authorizations = []

        mode = "DRY RUN" if dry_run else "LIVE"
        logger.info(f"User provisioner initialized ({mode})")

    def _make_request(self, method: str, endpoint: str,
                      data: Optional[Dict] = None) -> Dict:
        """Make API request"""
        if self.dry_run and method in ['POST', 'PUT', 'PATCH', 'DELETE']:
            logger.info(f"[DRY RUN] Would {method} {endpoint}")
            return {'status': 'success', 'data': {'id': 'dry_run_id'}}

        try:
            url = f"{self.base_url}{endpoint}"
            response = self.session.request(method, url, json=data, timeout=30)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            logger.error(f"Request failed: {e}")
            raise

    def load_users_from_csv(self, csv_path: str) -> List[Dict[str, str]]:
        """
        Load user data from CSV file.

        CSV Format:
        username,display_name,email,groups,mfa_enabled,auth_type
        jsmith,John Smith,jsmith@company.com,engineers|operators,true,ldap

        Args:
            csv_path: Path to CSV file

        Returns:
            List of user dictionaries
        """
        users = []

        with open(csv_path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                # Parse groups (pipe-separated)
                groups = [g.strip() for g in row.get('groups', '').split('|') if g.strip()]

                # Parse MFA enabled
                mfa_enabled = row.get('mfa_enabled', 'false').lower() == 'true'

                user = {
                    'username': row['username'].strip(),
                    'display_name': row['display_name'].strip(),
                    'email': row['email'].strip(),
                    'groups': groups,
                    'mfa_enabled': mfa_enabled,
                    'auth_type': row.get('auth_type', 'local').strip()
                }

                users.append(user)

        logger.info(f"Loaded {len(users)} users from {csv_path}")
        return users

    def validate_user_data(self, user: Dict[str, str]) -> Optional[str]:
        """
        Validate user data.

        Args:
            user: User dictionary

        Returns:
            Error message if validation fails, None if valid
        """
        # Required fields
        if not user.get('username'):
            return "Missing username"
        if not user.get('email'):
            return "Missing email"
        if not user.get('display_name'):
            return "Missing display_name"

        # Email format validation (basic)
        if '@' not in user['email']:
            return "Invalid email format"

        # Username format (alphanumeric, underscore, hyphen)
        username = user['username']
        if not username.replace('_', '').replace('-', '').isalnum():
            return "Invalid username format"

        return None

    def user_exists(self, username: str) -> bool:
        """Check if user already exists"""
        try:
            response = self._make_request(
                'GET',
                f'/api/v2/users',
                data={'search': username}
            )
            users = response.get('data', [])
            return any(u['username'] == username for u in users)
        except:
            return False

    def create_user(self, user_data: Dict[str, str]) -> Dict[str, Any]:
        """
        Create a single user.

        Args:
            user_data: User information

        Returns:
            Created user data from API
        """
        payload = {
            'username': user_data['username'],
            'display_name': user_data['display_name'],
            'email': user_data['email'],
            'auth_type': user_data.get('auth_type', 'local'),
            'mfa_enabled': user_data.get('mfa_enabled', True),
            'mfa_type': 'totp',
            'language': 'en',
            'timezone': 'UTC',
            'password_change_required': True
        }

        logger.info(f"Creating user: {user_data['username']}")
        response = self._make_request('POST', '/api/v2/users', data=payload)

        user_info = response.get('data', {})
        if not self.dry_run:
            self.created_users.append(user_info.get('id'))

        return user_info

    def ensure_group_exists(self, group_name: str) -> str:
        """
        Ensure group exists, create if necessary.

        Args:
            group_name: Group name

        Returns:
            Group ID
        """
        # Check if group exists
        response = self._make_request('GET', '/api/v2/groups')
        groups = response.get('data', [])

        for group in groups:
            if group.get('name') == group_name:
                logger.debug(f"Group exists: {group_name}")
                return group.get('id')

        # Create group
        logger.info(f"Creating group: {group_name}")
        response = self._make_request(
            'POST',
            '/api/v2/groups',
            data={
                'name': group_name,
                'description': f'Auto-created group: {group_name}'
            }
        )

        group_id = response.get('data', {}).get('id')
        if not self.dry_run:
            self.created_groups.append(group_id)

        return group_id

    def assign_user_to_groups(self, user_id: str, group_names: List[str]) -> List[str]:
        """
        Assign user to groups.

        Args:
            user_id: User ID
            group_names: List of group names

        Returns:
            List of assigned group IDs
        """
        assigned_groups = []

        for group_name in group_names:
            try:
                group_id = self.ensure_group_exists(group_name)

                logger.info(f"Adding user to group: {group_name}")
                self._make_request(
                    'POST',
                    f'/api/v2/groups/{group_id}/members',
                    data={'user_id': user_id}
                )

                assigned_groups.append(group_name)

            except Exception as e:
                logger.error(f"Failed to assign group {group_name}: {e}")

        return assigned_groups

    def create_default_authorization(self, user_id: str, group_id: str) -> Optional[str]:
        """
        Create default authorization for user/group.

        Args:
            user_id: User ID
            group_id: Group ID

        Returns:
            Authorization ID if created
        """
        try:
            # This is a placeholder - customize based on your authorization model
            logger.info(f"Creating default authorization for user {user_id}")

            # Example: Create basic authorization
            # Adjust based on your target groups and accounts
            response = self._make_request(
                'POST',
                '/api/v2/authorizations',
                data={
                    'name': f'auto_auth_{user_id}',
                    'description': 'Auto-created authorization',
                    'user_group_id': group_id,
                    'target_group_id': 'default_targets',  # Configure this
                    'is_recorded': True,
                    'approval_required': False
                }
            )

            auth_id = response.get('data', {}).get('id')
            if not self.dry_run and auth_id:
                self.created_authorizations.append(auth_id)

            return auth_id

        except Exception as e:
            logger.error(f"Failed to create authorization: {e}")
            return None

    def provision_user(self, user_data: Dict[str, str]) -> UserProvisionResult:
        """
        Provision a single user with full workflow.

        Args:
            user_data: User information

        Returns:
            Provisioning result
        """
        username = user_data['username']

        # Validate
        error = self.validate_user_data(user_data)
        if error:
            logger.error(f"Validation failed for {username}: {error}")
            return UserProvisionResult(username=username, status='failed', error=error)

        # Check if exists
        if self.user_exists(username):
            logger.warning(f"User already exists: {username}")
            return UserProvisionResult(username=username, status='skipped', error='User exists')

        try:
            # Create user
            user_info = self.create_user(user_data)
            user_id = user_info.get('id')

            # Assign groups
            groups = user_data.get('groups', [])
            assigned_groups = self.assign_user_to_groups(user_id, groups)

            # Create authorizations (optional)
            auth_ids = []
            # Uncomment to enable default authorization creation
            # for group_name in groups:
            #     group_id = self.ensure_group_exists(group_name)
            #     auth_id = self.create_default_authorization(user_id, group_id)
            #     if auth_id:
            #         auth_ids.append(auth_id)

            logger.info(f"Successfully provisioned user: {username}")
            return UserProvisionResult(
                username=username,
                status='success',
                user_id=user_id,
                groups_assigned=assigned_groups,
                authorizations_created=auth_ids
            )

        except Exception as e:
            logger.error(f"Failed to provision {username}: {e}")
            return UserProvisionResult(
                username=username,
                status='failed',
                error=str(e)
            )

    def provision_users_bulk(self, users: List[Dict[str, str]]) -> List[UserProvisionResult]:
        """
        Provision multiple users.

        Args:
            users: List of user data dictionaries

        Returns:
            List of provisioning results
        """
        results = []

        logger.info(f"Starting bulk provisioning for {len(users)} users")

        for i, user_data in enumerate(users, 1):
            logger.info(f"Processing user {i}/{len(users)}: {user_data['username']}")
            result = self.provision_user(user_data)
            results.append(result)

        # Summary
        success_count = sum(1 for r in results if r.status == 'success')
        failed_count = sum(1 for r in results if r.status == 'failed')
        skipped_count = sum(1 for r in results if r.status == 'skipped')

        logger.info(f"Provisioning complete: {success_count} success, {failed_count} failed, {skipped_count} skipped")

        return results

    def rollback(self):
        """
        Rollback created resources (best effort).
        Use with caution - only in case of critical errors.
        """
        if self.dry_run:
            logger.info("[DRY RUN] Would rollback changes")
            return

        logger.warning("Starting rollback of provisioned resources")

        # Delete authorizations
        for auth_id in self.created_authorizations:
            try:
                self._make_request('DELETE', f'/api/v2/authorizations/{auth_id}')
                logger.info(f"Deleted authorization: {auth_id}")
            except Exception as e:
                logger.error(f"Failed to delete authorization {auth_id}: {e}")

        # Delete users
        for user_id in self.created_users:
            try:
                self._make_request('DELETE', f'/api/v2/users/{user_id}')
                logger.info(f"Deleted user: {user_id}")
            except Exception as e:
                logger.error(f"Failed to delete user {user_id}: {e}")

        # Delete groups (optional - may contain existing users)
        # Uncomment if you want to delete auto-created groups
        # for group_id in self.created_groups:
        #     try:
        #         self._make_request('DELETE', f'/api/v2/groups/{group_id}')
        #         logger.info(f"Deleted group: {group_id}")
        #     except Exception as e:
        #         logger.error(f"Failed to delete group {group_id}: {e}")

        logger.warning("Rollback complete")

    def export_results(self, results: List[UserProvisionResult], output_path: str):
        """
        Export provisioning results to JSON file.

        Args:
            results: Provisioning results
            output_path: Output file path
        """
        output_data = {
            'timestamp': datetime.utcnow().isoformat() + 'Z',
            'dry_run': self.dry_run,
            'summary': {
                'total': len(results),
                'success': sum(1 for r in results if r.status == 'success'),
                'failed': sum(1 for r in results if r.status == 'failed'),
                'skipped': sum(1 for r in results if r.status == 'skipped')
            },
            'results': [r.to_dict() for r in results]
        }

        with open(output_path, 'w') as f:
            json.dump(output_data, f, indent=2)

        logger.info(f"Results exported to {output_path}")


# Usage Examples
def example_provision_from_csv():
    """Example: Provision users from CSV file"""

    provisioner = WallixUserProvisioner(
        base_url='https://bastion.company.com',
        api_token='your-api-token-here',
        dry_run=False  # Set to True for validation only
    )

    # Load users from CSV
    users = provisioner.load_users_from_csv('users.csv')

    # Provision users
    results = provisioner.provision_users_bulk(users)

    # Export results
    provisioner.export_results(results, 'provisioning_results.json')

    # Check for failures
    failed = [r for r in results if r.status == 'failed']
    if failed:
        logger.error(f"{len(failed)} users failed to provision")
        for result in failed:
            logger.error(f"  {result.username}: {result.error}")


def example_dry_run_validation():
    """Example: Validate CSV without making changes"""

    provisioner = WallixUserProvisioner(
        base_url='https://bastion.company.com',
        api_token='your-api-token-here',
        dry_run=True  # Validation mode
    )

    users = provisioner.load_users_from_csv('users.csv')

    # Validate all users
    validation_errors = []
    for user in users:
        error = provisioner.validate_user_data(user)
        if error:
            validation_errors.append((user['username'], error))

    if validation_errors:
        logger.error(f"Validation failed for {len(validation_errors)} users:")
        for username, error in validation_errors:
            logger.error(f"  {username}: {error}")
    else:
        logger.info("All users validated successfully")


def example_rollback_on_error():
    """Example: Rollback provisioned users on critical error"""

    provisioner = WallixUserProvisioner(
        base_url='https://bastion.company.com',
        api_token='your-api-token-here',
        dry_run=False
    )

    users = provisioner.load_users_from_csv('users.csv')

    try:
        results = provisioner.provision_users_bulk(users)

        # Check failure rate
        failed_count = sum(1 for r in results if r.status == 'failed')
        failure_rate = failed_count / len(results)

        # Rollback if more than 20% failed
        if failure_rate > 0.2:
            logger.error(f"High failure rate ({failure_rate:.1%}), rolling back")
            provisioner.rollback()
        else:
            logger.info("Provisioning successful")
            provisioner.export_results(results, 'results.json')

    except Exception as e:
        logger.error(f"Critical error: {e}")
        provisioner.rollback()


if __name__ == '__main__':
    # Run example
    example_provision_from_csv()
```

---

## See Also

**Related API Sections:**
- [Authentication](#authentication) - API authentication methods
- [Users & Groups](#users--groups) - User and group management endpoints
- [Password Management](#password-management) - Credential checkout and rotation
- [Sessions](#sessions) - Session monitoring and control
- [Audit API](#audit-api) - Audit log queries for compliance

**Related Documentation:**
- [10 - API & Automation](../10-api-automation/README.md) - API integration patterns
- [31 - wabadmin Reference](../31-wabadmin-reference/README.md) - CLI automation
- [14 - Best Practices](../14-best-practices/README.md) - Security best practices

**Official Resources:**
- [WALLIX REST API Samples](https://github.com/wallix/wbrest_samples)
- [WALLIX Documentation](https://pam.wallix.one/documentation)

---

## SCIM API

### SCIM 2.0 Overview

```
+===============================================================================+
|                   SCIM 2.0 API                                               |
+===============================================================================+

  OVERVIEW
  ========

  SCIM (System for Cross-domain Identity Management) 2.0 provides standardized
  user provisioning and deprovisioning from identity providers (IdP).

  BASE URL
  ========

  https://<wallix-host>/scim/v2/

  --------------------------------------------------------------------------

  SUPPORTED RESOURCES
  ===================

  +------------------------------------------------------------------------+
  | Resource      | Endpoint            | Description                      |
  +---------------+---------------------+----------------------------------+
  | Users         | /scim/v2/Users      | User provisioning                |
  | Groups        | /scim/v2/Groups     | Group provisioning               |
  | Schemas       | /scim/v2/Schemas    | Schema discovery                 |
  | ResourceTypes | /scim/v2/ResourceTypes | Supported resource types      |
  | ServiceProvider | /scim/v2/ServiceProviderConfig | SCIM capabilities   |
  +---------------+---------------------+----------------------------------+

  --------------------------------------------------------------------------

  AUTHENTICATION
  ==============

  SCIM API uses Bearer token authentication:

  +------------------------------------------------------------------------+
  | curl -X GET "https://wallix.company.com/scim/v2/Users" \               |
  |   -H "Authorization: Bearer <scim-api-token>" \                        |
  |   -H "Content-Type: application/scim+json"                             |
  +------------------------------------------------------------------------+

  Generate SCIM token via:
  Admin > System > SCIM Configuration > Generate Token

+===============================================================================+
```

### User Provisioning

```
+===============================================================================+
|                   SCIM USER OPERATIONS                                       |
+===============================================================================+

  LIST USERS
  ==========

  GET /scim/v2/Users

  Query Parameters:
  +------------------------------------------------------------------------+
  | Parameter    | Type    | Description                                   |
  +--------------+---------+-----------------------------------------------+
  | filter       | string  | SCIM filter expression                        |
  | startIndex   | integer | 1-based index for pagination                  |
  | count        | integer | Number of results per page                    |
  | sortBy       | string  | Attribute to sort by                          |
  | sortOrder    | string  | ascending or descending                       |
  +--------------+---------+-----------------------------------------------+

  Example Request:
  GET /scim/v2/Users?filter=userName eq "jsmith"&count=10

  Response:
  {
    "schemas": ["urn:ietf:params:scim:api:messages:2.0:ListResponse"],
    "totalResults": 1,
    "startIndex": 1,
    "itemsPerPage": 10,
    "Resources": [
      {
        "schemas": ["urn:ietf:params:scim:schemas:core:2.0:User"],
        "id": "usr_12345",
        "userName": "jsmith",
        "name": {
          "formatted": "John Smith",
          "familyName": "Smith",
          "givenName": "John"
        },
        "displayName": "John Smith",
        "emails": [
          {
            "value": "jsmith@company.com",
            "type": "work",
            "primary": true
          }
        ],
        "active": true,
        "groups": [
          {
            "value": "grp_001",
            "display": "ot_engineers",
            "$ref": "https://wallix.company.com/scim/v2/Groups/grp_001"
          }
        ],
        "meta": {
          "resourceType": "User",
          "created": "2024-01-15T10:00:00Z",
          "lastModified": "2024-01-20T14:30:00Z",
          "location": "https://wallix.company.com/scim/v2/Users/usr_12345"
        }
      }
    ]
  }

  --------------------------------------------------------------------------

  GET USER
  ========

  GET /scim/v2/Users/{id}

  Response:
  {
    "schemas": ["urn:ietf:params:scim:schemas:core:2.0:User"],
    "id": "usr_12345",
    "userName": "jsmith",
    "name": {
      "formatted": "John Smith",
      "familyName": "Smith",
      "givenName": "John"
    },
    "displayName": "John Smith",
    "emails": [
      {
        "value": "jsmith@company.com",
        "type": "work",
        "primary": true
      }
    ],
    "phoneNumbers": [
      {
        "value": "+1-555-1234",
        "type": "work"
      }
    ],
    "active": true,
    "groups": [
      {
        "value": "grp_001",
        "display": "ot_engineers"
      }
    ],
    "urn:wallix:scim:schemas:1.0:User": {
      "mfaEnabled": true,
      "mfaType": "totp",
      "language": "en",
      "timezone": "America/New_York"
    },
    "meta": {
      "resourceType": "User",
      "created": "2024-01-15T10:00:00Z",
      "lastModified": "2024-01-20T14:30:00Z"
    }
  }

  --------------------------------------------------------------------------

  CREATE USER
  ===========

  POST /scim/v2/Users

  Request:
  {
    "schemas": ["urn:ietf:params:scim:schemas:core:2.0:User"],
    "userName": "mwilson",
    "name": {
      "familyName": "Wilson",
      "givenName": "Mary"
    },
    "displayName": "Mary Wilson",
    "emails": [
      {
        "value": "mwilson@company.com",
        "type": "work",
        "primary": true
      }
    ],
    "active": true,
    "urn:wallix:scim:schemas:1.0:User": {
      "mfaEnabled": true,
      "mfaType": "totp"
    }
  }

  Response (201 Created):
  {
    "schemas": ["urn:ietf:params:scim:schemas:core:2.0:User"],
    "id": "usr_67890",
    "userName": "mwilson",
    ...
    "meta": {
      "resourceType": "User",
      "created": "2024-01-27T10:00:00Z",
      "location": "https://wallix.company.com/scim/v2/Users/usr_67890"
    }
  }

  --------------------------------------------------------------------------

  UPDATE USER (PUT - Full Replace)
  ================================

  PUT /scim/v2/Users/{id}

  Request: Full user object (replaces existing)

  --------------------------------------------------------------------------

  UPDATE USER (PATCH - Partial Update)
  ====================================

  PATCH /scim/v2/Users/{id}

  Request:
  {
    "schemas": ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
    "Operations": [
      {
        "op": "replace",
        "path": "displayName",
        "value": "Mary J. Wilson"
      },
      {
        "op": "add",
        "path": "phoneNumbers",
        "value": [
          {
            "value": "+1-555-5678",
            "type": "mobile"
          }
        ]
      },
      {
        "op": "replace",
        "path": "active",
        "value": false
      }
    ]
  }

  --------------------------------------------------------------------------

  DELETE USER
  ===========

  DELETE /scim/v2/Users/{id}

  Response: 204 No Content

+===============================================================================+
```

### Group Provisioning

```
+===============================================================================+
|                   SCIM GROUP OPERATIONS                                      |
+===============================================================================+

  LIST GROUPS
  ===========

  GET /scim/v2/Groups

  Response:
  {
    "schemas": ["urn:ietf:params:scim:api:messages:2.0:ListResponse"],
    "totalResults": 5,
    "Resources": [
      {
        "schemas": ["urn:ietf:params:scim:schemas:core:2.0:Group"],
        "id": "grp_001",
        "displayName": "ot_engineers",
        "members": [
          {
            "value": "usr_12345",
            "display": "jsmith",
            "$ref": "https://wallix.company.com/scim/v2/Users/usr_12345"
          }
        ],
        "meta": {
          "resourceType": "Group",
          "created": "2024-01-10T08:00:00Z",
          "lastModified": "2024-01-25T16:00:00Z"
        }
      }
    ]
  }

  --------------------------------------------------------------------------

  CREATE GROUP
  ============

  POST /scim/v2/Groups

  Request:
  {
    "schemas": ["urn:ietf:params:scim:schemas:core:2.0:Group"],
    "displayName": "ot_vendors",
    "members": [
      {
        "value": "usr_12345"
      },
      {
        "value": "usr_67890"
      }
    ]
  }

  --------------------------------------------------------------------------

  UPDATE GROUP MEMBERSHIP
  =======================

  PATCH /scim/v2/Groups/{id}

  Add members:
  {
    "schemas": ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
    "Operations": [
      {
        "op": "add",
        "path": "members",
        "value": [
          {"value": "usr_11111"}
        ]
      }
    ]
  }

  Remove members:
  {
    "schemas": ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
    "Operations": [
      {
        "op": "remove",
        "path": "members[value eq \"usr_12345\"]"
      }
    ]
  }

+===============================================================================+
```

### SCIM Filter Expressions

```
+===============================================================================+
|                   SCIM FILTER SYNTAX                                         |
+===============================================================================+

  SUPPORTED OPERATORS
  ===================

  +------------------------------------------------------------------------+
  | Operator | Description              | Example                          |
  +----------+--------------------------+----------------------------------+
  | eq       | Equal                    | userName eq "jsmith"             |
  | ne       | Not equal                | active ne false                  |
  | co       | Contains                 | displayName co "Smith"           |
  | sw       | Starts with              | userName sw "vendor_"            |
  | ew       | Ends with                | email ew "@company.com"          |
  | gt       | Greater than             | meta.created gt "2024-01-01"     |
  | ge       | Greater or equal         | meta.lastModified ge "2024-01-01"|
  | lt       | Less than                | meta.created lt "2024-12-31"     |
  | le       | Less or equal            | meta.lastModified le "2024-12-31"|
  | pr       | Present (has value)      | phoneNumbers pr                  |
  | and      | Logical AND              | active eq true and userName sw "a"|
  | or       | Logical OR               | userName eq "a" or userName eq "b"|
  | not      | Logical NOT              | not(active eq false)             |
  +----------+--------------------------+----------------------------------+

  --------------------------------------------------------------------------

  FILTER EXAMPLES
  ===============

  Find active users:
  GET /scim/v2/Users?filter=active eq true

  Find users by email domain:
  GET /scim/v2/Users?filter=emails.value ew "@company.com"

  Find users in specific group:
  GET /scim/v2/Users?filter=groups.display eq "ot_engineers"

  Find users created after date:
  GET /scim/v2/Users?filter=meta.created gt "2024-01-01T00:00:00Z"

  Complex filter:
  GET /scim/v2/Users?filter=active eq true and (userName sw "vendor_" or
    groups.display eq "ot_vendors")

+===============================================================================+
```

### IdP Integration Examples

```
+===============================================================================+
|                   IDP SCIM INTEGRATION                                       |
+===============================================================================+

  AZURE AD / ENTRA ID
  ===================

  Configuration in Azure Portal:
  +------------------------------------------------------------------------+
  | 1. Enterprise Applications > New Application > WALLIX Bastion          |
  | 2. Provisioning > Automatic                                            |
  |                                                                        |
  | Tenant URL: https://wallix.company.com/scim/v2                         |
  | Secret Token: <SCIM API Token from WALLIX>                             |
  |                                                                        |
  | Mappings:                                                              |
  | +-------------------------------+----------------------------------+   |
  | | Azure AD Attribute            | WALLIX SCIM Attribute            |   |
  | +-------------------------------+----------------------------------+   |
  | | userPrincipalName             | userName                         |   |
  | | displayName                   | displayName                      |   |
  | | givenName                     | name.givenName                   |   |
  | | surname                       | name.familyName                  |   |
  | | mail                          | emails[type eq "work"].value     |   |
  | | Switch([IsSoftDeleted],...)   | active                           |   |
  | +-------------------------------+----------------------------------+   |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  OKTA
  ====

  Configuration in Okta Admin:
  +------------------------------------------------------------------------+
  | 1. Applications > Add Application > SCIM 2.0 Test App                  |
  | 2. Provisioning > Configure API Integration                            |
  |                                                                        |
  | SCIM connector base URL: https://wallix.company.com/scim/v2            |
  | Unique identifier field: userName                                      |
  | Authentication Mode: HTTP Header                                       |
  | Authorization: Bearer <token>                                          |
  |                                                                        |
  | Supported provisioning actions:                                        |
  | [x] Create Users                                                       |
  | [x] Update User Attributes                                             |
  | [x] Deactivate Users                                                   |
  | [x] Push Groups                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  PING IDENTITY
  =============

  Configuration:
  +------------------------------------------------------------------------+
  | Outbound Provisioning > SCIM                                           |
  |                                                                        |
  | Base URL: https://wallix.company.com/scim/v2                           |
  | Authentication: Bearer Token                                           |
  | Token: <SCIM API Token>                                                |
  |                                                                        |
  | Attribute Mapping:                                                     |
  | - Map PingOne user attributes to SCIM User schema                      |
  | - Configure group push for WALLIX group membership                     |
  +------------------------------------------------------------------------+

+===============================================================================+
```

---

## Bulk Operations

### Bulk API Endpoints

```
+===============================================================================+
|                   BULK OPERATIONS API                                        |
+===============================================================================+

  BULK REQUEST
  ============

  POST /api/v2/bulk

  Perform multiple operations in a single request.

  Request:
  {
    "operations": [
      {
        "method": "POST",
        "path": "/devices",
        "body": {
          "name": "plc-line1",
          "host": "10.10.1.10",
          "domain": "ot_devices"
        }
      },
      {
        "method": "POST",
        "path": "/devices",
        "body": {
          "name": "plc-line2",
          "host": "10.10.1.11",
          "domain": "ot_devices"
        }
      },
      {
        "method": "POST",
        "path": "/accounts",
        "body": {
          "name": "admin",
          "device_id": "$response[0].data.id",
          "credential_type": "password",
          "credentials": {"password": "secure123"}
        }
      }
    ],
    "fail_on_error": false
  }

  Response:
  {
    "status": "success",
    "data": {
      "total": 3,
      "successful": 3,
      "failed": 0,
      "results": [
        {
          "index": 0,
          "status": 201,
          "data": {"id": "dev_001", "name": "plc-line1"}
        },
        {
          "index": 1,
          "status": 201,
          "data": {"id": "dev_002", "name": "plc-line2"}
        },
        {
          "index": 2,
          "status": 201,
          "data": {"id": "acc_001", "name": "admin"}
        }
      ]
    }
  }

  --------------------------------------------------------------------------

  BULK DELETE
  ===========

  DELETE /api/v2/bulk

  Request:
  {
    "resource_type": "devices",
    "ids": ["dev_001", "dev_002", "dev_003"],
    "cascade": true
  }

  Response:
  {
    "status": "success",
    "data": {
      "deleted": 3,
      "cascaded": {
        "accounts": 5,
        "authorizations": 2
      }
    }
  }

  --------------------------------------------------------------------------

  BULK EXPORT
  ===========

  GET /api/v2/export

  Query Parameters:
  +------------------------------------------------------------------------+
  | Parameter     | Type   | Description                                   |
  +---------------+--------+-----------------------------------------------+
  | resource_type | string | devices, accounts, users, groups, all         |
  | format        | string | json, csv                                     |
  | domain        | string | Filter by domain                              |
  +---------------+--------+-----------------------------------------------+

  Example:
  GET /api/v2/export?resource_type=devices&format=csv&domain=ot_devices

  --------------------------------------------------------------------------

  BULK IMPORT
  ===========

  POST /api/v2/import

  Request (multipart/form-data):
  - file: CSV or JSON file
  - resource_type: devices, accounts, users
  - mode: create, update, upsert
  - dry_run: true/false

  Response:
  {
    "status": "success",
    "data": {
      "mode": "upsert",
      "dry_run": false,
      "processed": 100,
      "created": 75,
      "updated": 25,
      "errors": []
    }
  }

+===============================================================================+
```

---

## Audit API

### Audit Query Endpoints

```
+===============================================================================+
|                   AUDIT API ENDPOINTS                                        |
+===============================================================================+

  QUERY AUDIT LOGS
  ================

  GET /api/v2/audit/logs

  Query Parameters:
  +------------------------------------------------------------------------+
  | Parameter   | Type     | Description                                   |
  +-------------+----------+-----------------------------------------------+
  | start_date  | datetime | Start of time range (ISO 8601)                |
  | end_date    | datetime | End of time range (ISO 8601)                  |
  | event_type  | string   | auth, session, config, approval, password     |
  | user_id     | string   | Filter by user ID                             |
  | target_id   | string   | Filter by target device/account               |
  | severity    | string   | info, warning, error, critical                |
  | outcome     | string   | success, failure                              |
  | page        | integer  | Page number                                   |
  | per_page    | integer  | Results per page (max 1000)                   |
  +-------------+----------+-----------------------------------------------+

  Example:
  GET /api/v2/audit/logs?event_type=session&start_date=2024-01-01&outcome=success

  Response:
  {
    "status": "success",
    "data": [
      {
        "id": "aud_001",
        "timestamp": "2024-01-27T10:30:00Z",
        "event_type": "session.start",
        "severity": "info",
        "outcome": "success",
        "user": {
          "id": "usr_001",
          "username": "jsmith",
          "ip": "192.168.1.100"
        },
        "target": {
          "device": "plc-line1",
          "account": "root",
          "protocol": "ssh"
        },
        "details": {
          "session_id": "ses_001",
          "authorization": "engineers_to_plcs"
        }
      }
    ],
    "meta": {
      "total": 5000,
      "page": 1,
      "per_page": 100
    }
  }

  --------------------------------------------------------------------------

  AUDIT STATISTICS
  ================

  GET /api/v2/audit/stats

  Query Parameters:
  +------------------------------------------------------------------------+
  | Parameter   | Type     | Description                                   |
  +-------------+----------+-----------------------------------------------+
  | start_date  | datetime | Start of time range                           |
  | end_date    | datetime | End of time range                             |
  | group_by    | string   | user, device, event_type, hour, day, month    |
  +-------------+----------+-----------------------------------------------+

  Example:
  GET /api/v2/audit/stats?start_date=2024-01-01&end_date=2024-01-31&group_by=user

  Response:
  {
    "status": "success",
    "data": {
      "period": {
        "start": "2024-01-01T00:00:00Z",
        "end": "2024-01-31T23:59:59Z"
      },
      "totals": {
        "sessions": 15000,
        "unique_users": 50,
        "unique_devices": 200,
        "failed_logins": 25
      },
      "by_user": [
        {
          "user": "jsmith",
          "sessions": 500,
          "devices_accessed": 45,
          "total_duration_hours": 120
        }
      ]
    }
  }

  --------------------------------------------------------------------------

  COMPLIANCE REPORTS
  ==================

  GET /api/v2/audit/reports/{report_type}

  Available Reports:
  +------------------------------------------------------------------------+
  | Report Type         | Description                                      |
  +---------------------+--------------------------------------------------+
  | access_review       | User access certification report                 |
  | privileged_activity | High-privilege actions summary                   |
  | password_compliance | Password rotation compliance                     |
  | session_summary     | Session statistics and trends                    |
  | failed_access       | Failed authentication attempts                   |
  +---------------------+--------------------------------------------------+

  Example:
  GET /api/v2/audit/reports/password_compliance?start_date=2024-01-01

  Response:
  {
    "status": "success",
    "data": {
      "report_type": "password_compliance",
      "generated_at": "2024-01-27T10:00:00Z",
      "summary": {
        "total_accounts": 500,
        "compliant": 475,
        "non_compliant": 25,
        "compliance_rate": 95.0
      },
      "non_compliant_accounts": [
        {
          "account": "legacy_service@server1",
          "last_rotation": "2023-06-15T00:00:00Z",
          "days_overdue": 195,
          "reason": "Rotation failed - connection timeout"
        }
      ]
    }
  }

+===============================================================================+
```

---

## SCIM 2.0 API for User Provisioning

### SCIM API Overview

WALLIX Bastion supports the SCIM 2.0 (System for Cross-domain Identity Management) protocol for automated user and group provisioning from identity providers.

```
+===============================================================================+
|                        SCIM 2.0 API OVERVIEW                                  |
+===============================================================================+
|                                                                               |
|  BASE URL: https://<wallix-host>/scim/v2/                                     |
|                                                                               |
|  Supported Resources:                                                         |
|  - Users       /scim/v2/Users                                                 |
|  - Groups      /scim/v2/Groups                                                |
|                                                                               |
|  Authentication:                                                              |
|  - Bearer Token (OAuth 2.0)                                                   |
|  - API Key                                                                    |
|                                                                               |
|  Official Documentation:                                                      |
|  https://scim.wallix.com/scim/doc/Usage.html                                  |
|                                                                               |
+===============================================================================+
```

### SCIM Endpoints

```
+===============================================================================+
|                           SCIM 2.0 ENDPOINTS                                  |
+===============================================================================+

  USERS
  =====

  List Users
  ----------
  GET /scim/v2/Users

  Query Parameters:
  - filter:      SCIM filter expression
  - startIndex:  Pagination start (1-based)
  - count:       Results per page (default: 100)

  Example:
  GET /scim/v2/Users?filter=userName eq "jsmith"&startIndex=1&count=10

  Response:
  {
    "schemas": ["urn:ietf:params:scim:api:messages:2.0:ListResponse"],
    "totalResults": 1,
    "startIndex": 1,
    "itemsPerPage": 10,
    "Resources": [
      {
        "id": "usr_12345",
        "userName": "jsmith",
        "name": {
          "givenName": "John",
          "familyName": "Smith"
        },
        "emails": [
          {
            "value": "john.smith@company.com",
            "primary": true
          }
        ],
        "active": true,
        "groups": []
      }
    ]
  }

  --------------------------------------------------------------------------

  Get User by ID
  --------------
  GET /scim/v2/Users/{id}

  Example:
  GET /scim/v2/Users/usr_12345

  Response:
  {
    "schemas": ["urn:ietf:params:scim:schemas:core:2.0:User"],
    "id": "usr_12345",
    "userName": "jsmith",
    "name": {
      "givenName": "John",
      "familyName": "Smith"
    },
    "emails": [
      {
        "value": "john.smith@company.com",
        "primary": true
      }
    ],
    "active": true
  }

  --------------------------------------------------------------------------

  Create User
  -----------
  POST /scim/v2/Users

  Request Body:
  {
    "schemas": ["urn:ietf:params:scim:schemas:core:2.0:User"],
    "userName": "bjones",
    "name": {
      "givenName": "Bob",
      "familyName": "Jones"
    },
    "emails": [
      {
        "value": "bob.jones@company.com",
        "primary": true
      }
    ],
    "active": true
  }

  Response: 201 Created
  {
    "schemas": ["urn:ietf:params:scim:schemas:core:2.0:User"],
    "id": "usr_67890",
    "userName": "bjones",
    ...
  }

  --------------------------------------------------------------------------

  Update User (PUT)
  -----------------
  PUT /scim/v2/Users/{id}

  Request Body:
  {
    "schemas": ["urn:ietf:params:scim:schemas:core:2.0:User"],
    "id": "usr_12345",
    "userName": "jsmith",
    "name": {
      "givenName": "John",
      "familyName": "Smith-Updated"
    },
    "active": true
  }

  Response: 200 OK

  --------------------------------------------------------------------------

  Update User (PATCH)
  -------------------
  PATCH /scim/v2/Users/{id}

  Request Body:
  {
    "schemas": ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
    "Operations": [
      {
        "op": "replace",
        "path": "active",
        "value": false
      }
    ]
  }

  Response: 200 OK

  --------------------------------------------------------------------------

  Delete User
  -----------
  DELETE /scim/v2/Users/{id}

  Response: 204 No Content

  --------------------------------------------------------------------------

  GROUPS
  ======

  List Groups
  -----------
  GET /scim/v2/Groups

  Response:
  {
    "schemas": ["urn:ietf:params:scim:api:messages:2.0:ListResponse"],
    "totalResults": 3,
    "Resources": [
      {
        "id": "grp_001",
        "displayName": "IT Administrators",
        "members": [
          {
            "value": "usr_12345",
            "display": "jsmith"
          }
        ]
      }
    ]
  }

  --------------------------------------------------------------------------

  Create Group
  ------------
  POST /scim/v2/Groups

  Request Body:
  {
    "schemas": ["urn:ietf:params:scim:schemas:core:2.0:Group"],
    "displayName": "Database Admins",
    "members": [
      {
        "value": "usr_12345",
        "display": "jsmith"
      }
    ]
  }

  Response: 201 Created

  --------------------------------------------------------------------------

  Add User to Group (PATCH)
  --------------------------
  PATCH /scim/v2/Groups/{id}

  Request Body:
  {
    "schemas": ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
    "Operations": [
      {
        "op": "add",
        "path": "members",
        "value": [
          {
            "value": "usr_67890",
            "display": "bjones"
          }
        ]
      }
    ]
  }

+===============================================================================+
```

### SCIM Filter Examples

```python
# Filter by username
GET /scim/v2/Users?filter=userName eq "jsmith"

# Filter by email
GET /scim/v2/Users?filter=emails.value eq "john@company.com"

# Filter active users
GET /scim/v2/Users?filter=active eq true

# Complex filter (AND)
GET /scim/v2/Users?filter=active eq true and userName sw "admin"

# Complex filter (OR)
GET /scim/v2/Users?filter=userName eq "jsmith" or userName eq "bjones"

# Filter groups
GET /scim/v2/Groups?filter=displayName co "Admin"
```

### SCIM Integration Examples

#### Python SCIM Client

```python
import requests
from requests.auth import HTTPBasicAuth

class WallixSCIMClient:
    def __init__(self, base_url, api_key):
        self.base_url = base_url.rstrip('/')
        self.api_key = api_key
        self.headers = {
            'Authorization': f'Bearer {api_key}',
            'Content-Type': 'application/scim+json',
            'Accept': 'application/scim+json'
        }

    def create_user(self, username, given_name, family_name, email):
        """Create a new user via SCIM"""
        url = f'{self.base_url}/scim/v2/Users'
        payload = {
            "schemas": ["urn:ietf:params:scim:schemas:core:2.0:User"],
            "userName": username,
            "name": {
                "givenName": given_name,
                "familyName": family_name
            },
            "emails": [
                {
                    "value": email,
                    "primary": True
                }
            ],
            "active": True
        }

        response = requests.post(url, json=payload, headers=self.headers)
        response.raise_for_status()
        return response.json()

    def get_user_by_username(self, username):
        """Get user by username using SCIM filter"""
        url = f'{self.base_url}/scim/v2/Users'
        params = {'filter': f'userName eq "{username}"'}

        response = requests.get(url, params=params, headers=self.headers)
        response.raise_for_status()

        data = response.json()
        if data.get('totalResults', 0) > 0:
            return data['Resources'][0]
        return None

    def update_user_status(self, user_id, active):
        """Enable or disable user via SCIM PATCH"""
        url = f'{self.base_url}/scim/v2/Users/{user_id}'
        payload = {
            "schemas": ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
            "Operations": [
                {
                    "op": "replace",
                    "path": "active",
                    "value": active
                }
            ]
        }

        response = requests.patch(url, json=payload, headers=self.headers)
        response.raise_for_status()
        return response.json()

    def delete_user(self, user_id):
        """Delete user via SCIM"""
        url = f'{self.base_url}/scim/v2/Users/{user_id}'
        response = requests.delete(url, headers=self.headers)
        response.raise_for_status()

# Usage Example
client = WallixSCIMClient('https://bastion.company.com', 'your-api-key')

# Create user
new_user = client.create_user('bjones', 'Bob', 'Jones', 'bob@company.com')
print(f"Created user: {new_user['id']}")

# Get user
user = client.get_user_by_username('bjones')
print(f"Found user: {user['id']}")

# Disable user
client.update_user_status(user['id'], False)
print("User disabled")

# Delete user
client.delete_user(user['id'])
print("User deleted")
```

### SCIM Common Use Cases

| Use Case | Description | SCIM Operation |
|----------|-------------|----------------|
| **Identity Provider Sync** | Sync users from Azure AD, Okta, OneLogin | Automated CREATE/UPDATE/DELETE |
| **Automated Onboarding** | Provision users when hired | POST /scim/v2/Users |
| **Automated Offboarding** | Deprovision users when terminated | DELETE /scim/v2/Users/{id} or PATCH active=false |
| **Group Membership Sync** | Sync AD groups to WALLIX profiles | POST/PATCH /scim/v2/Groups |
| **Attribute Updates** | Update email, name, department | PATCH /scim/v2/Users/{id} |

### SCIM Error Responses

```json
// 400 Bad Request - Invalid filter syntax
{
  "schemas": ["urn:ietf:params:scim:api:messages:2.0:Error"],
  "status": "400",
  "detail": "Invalid filter syntax: userName equ 'test'"
}

// 404 Not Found - User doesn't exist
{
  "schemas": ["urn:ietf:params:scim:api:messages:2.0:Error"],
  "status": "404",
  "detail": "User not found: usr_99999"
}

// 409 Conflict - Duplicate username
{
  "schemas": ["urn:ietf:params:scim:api:messages:2.0:Error"],
  "status": "409",
  "detail": "Username 'jsmith' already exists"
}
```

### SCIM Resources

| Resource | URL |
|----------|-----|
| **Official SCIM API Documentation** | https://scim.wallix.com/scim/doc/Usage.html |
| **SCIM 2.0 RFC** | https://datatracker.ietf.org/doc/html/rfc7644 |
| **SCIM Schema** | https://datatracker.ietf.org/doc/html/rfc7643 |

---

## See Also

**Related Sections:**
- [31 - wabadmin Reference](../31-wabadmin-reference/README.md) - CLI command reference for automation
- [10 - API & Automation](../10-api-automation/README.md) - API overview and integration patterns
- [18 - Error Reference](../18-error-reference/README.md) - API error codes and troubleshooting
- [08 - Password Management](../08-password-management/README.md) - Credential vault API endpoints
- [09 - Session Management](../09-session-management/README.md) - Session control API endpoints

**Related Documentation:**
- [Install Guide](/install/HOWTO.md) - API configuration during deployment

**Official Resources:**
- [WALLIX REST API Samples](https://github.com/wallix/wbrest_samples)
- [SCIM API Documentation](https://scim.wallix.com/scim/doc/Usage.html)
- [WALLIX Documentation](https://pam.wallix.one/documentation)

---

## Next Steps

Continue to [27 - Error Reference](../18-error-reference/README.md) for error codes and troubleshooting.
