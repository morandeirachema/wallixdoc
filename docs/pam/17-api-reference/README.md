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
+===============================================================================+
|                   WALLIX API OVERVIEW                                        |
+===============================================================================+

  BASE URL
  ========

  https://<wallix-host>/api/

  Version-specific endpoints:
  https://<wallix-host>/api/v2/        # API v2 (current - use this)
  https://<wallix-host>/api/v1/        # API v1 (REMOVED in 12.x - do not use)

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

## Next Steps

Continue to [27 - Error Reference](../18-error-reference/README.md) for error codes and troubleshooting.
