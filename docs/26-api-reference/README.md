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

---

## API Overview

### Base URL and Versioning

```
+==============================================================================+
|                   WALLIX API OVERVIEW                                        |
+==============================================================================+

  BASE URL
  ========

  https://<wallix-host>/api/

  Version-specific endpoints:
  https://<wallix-host>/api/v1/        # API v1 (legacy)
  https://<wallix-host>/api/v2/        # API v2 (current)

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

+==============================================================================+
```

---

## Authentication

### API Authentication Methods

```
+==============================================================================+
|                   API AUTHENTICATION                                         |
+==============================================================================+

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

+==============================================================================+
```

---

## Users & Groups

### User Endpoints

```
+==============================================================================+
|                   USER API ENDPOINTS                                         |
+==============================================================================+

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

+==============================================================================+
```

### Group Endpoints

```
+==============================================================================+
|                   GROUP API ENDPOINTS                                        |
+==============================================================================+

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

+==============================================================================+
```

---

## Devices & Accounts

### Device Endpoints

```
+==============================================================================+
|                   DEVICE API ENDPOINTS                                       |
+==============================================================================+

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

+==============================================================================+
```

### Account Endpoints

```
+==============================================================================+
|                   ACCOUNT API ENDPOINTS                                      |
+==============================================================================+

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

+==============================================================================+
```

---

## Authorizations

### Authorization Endpoints

```
+==============================================================================+
|                   AUTHORIZATION API ENDPOINTS                                |
+==============================================================================+

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

+==============================================================================+
```

### Approval Endpoints

```
+==============================================================================+
|                   APPROVAL API ENDPOINTS                                     |
+==============================================================================+

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

+==============================================================================+
```

---

## Sessions

### Session Endpoints

```
+==============================================================================+
|                   SESSION API ENDPOINTS                                      |
+==============================================================================+

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

+==============================================================================+
```

---

## Password Management

### Credential Endpoints

```
+==============================================================================+
|                   PASSWORD MANAGEMENT API                                    |
+==============================================================================+

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

+==============================================================================+
```

---

## System Administration

### System Endpoints

```
+==============================================================================+
|                   SYSTEM ADMINISTRATION API                                  |
+==============================================================================+

  SYSTEM STATUS
  =============

  GET /api/v2/system/status

  Response:
  {
    "status": "success",
    "data": {
      "version": "10.0.1",
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

+==============================================================================+
```

---

## Next Steps

Continue to [27 - Error Reference](../27-error-reference/README.md) for error codes and troubleshooting.
