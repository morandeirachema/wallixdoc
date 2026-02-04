# 60 - Privileged Task Automation

## Table of Contents

1. [Task Automation Overview](#task-automation-overview)
2. [Architecture](#architecture)
3. [Task Types](#task-types)
4. [Task Definition](#task-definition)
5. [Scheduling](#scheduling)
6. [Credential Handling](#credential-handling)
7. [Task Execution](#task-execution)
8. [Common Use Cases](#common-use-cases)
9. [Security Controls](#security-controls)
10. [Monitoring and Alerting](#monitoring-and-alerting)
11. [API Integration](#api-integration)
12. [Troubleshooting](#troubleshooting)

---

## Task Automation Overview

### What is Privileged Task Automation?

Privileged Task Automation (PTA) enables organizations to execute administrative scripts and commands on target systems using managed credentials, without exposing those credentials to operators or scripts. WALLIX Bastion orchestrates the entire task lifecycle from credential retrieval to execution and audit logging.

```
+===============================================================================+
|                    PRIVILEGED TASK AUTOMATION OVERVIEW                        |
+===============================================================================+
|                                                                               |
|  TRADITIONAL APPROACH                 WALLIX PTA APPROACH                     |
|  ====================                 ===================                     |
|                                                                               |
|  +---------------+                    +---------------+                       |
|  |   Operator    |                    |   Operator    |                       |
|  +-------+-------+                    +-------+-------+                       |
|          |                                    |                               |
|          | Has credentials                    | Requests task                 |
|          v                                    v                               |
|  +---------------+                    +---------------+                       |
|  |   Script      |                    |    WALLIX     |                       |
|  | (credentials  |                    |   Task Engine |                       |
|  |  embedded)    |                    +-------+-------+                       |
|  +-------+-------+                            |                               |
|          |                                    | Injects credentials           |
|          v                                    v                               |
|  +---------------+                    +---------------+                       |
|  |    Target     |                    |    Target     |                       |
|  +---------------+                    +---------------+                       |
|                                                                               |
|  RISKS:                               BENEFITS:                               |
|  - Credential exposure                - Zero credential exposure              |
|  - No audit trail                     - Complete audit trail                  |
|  - Manual execution                   - Automated execution                   |
|  - Human error                        - Consistent results                    |
|                                                                               |
+===============================================================================+
```

### Key Benefits

| Benefit | Description |
|---------|-------------|
| **Zero Credential Exposure** | Credentials never visible in scripts, logs, or to operators |
| **Complete Audit Trail** | Every task execution logged with user, target, time, and outcome |
| **Consistent Execution** | Tasks run the same way every time, reducing human error |
| **Centralized Management** | All automated tasks managed from a single platform |
| **Approval Workflows** | Sensitive tasks require authorization before execution |
| **Compliance Ready** | Built-in reporting for regulatory requirements |

---

## Architecture

### Task Execution Flow

```
+===============================================================================+
|                       TASK EXECUTION ARCHITECTURE                             |
+===============================================================================+
|                                                                               |
|   +----------+                                                                |
|   | Operator |  1. Submit task request                                        |
|   +----+-----+                                                                |
|        |                                                                      |
|        v                                                                      |
|   +------------------------------------------------------------------+        |
|   |                    WALLIX BASTION                                |        |
|   |                                                                  |        |
|   |  +----------------+     +----------------+     +--------------+  |        |
|   |  |  Task Manager  |     |   Scheduler    |     |   Approval   |  |        |
|   |  | * Validate     |     | * Cron jobs    |     |   Workflow   |  |        |
|   |  | * Queue        |     | * Maintenance  |     | * Pending    |  |        |
|   |  | * Orchestrate  |     |   windows      |     | * Approved   |  |        |
|   |  +-------+--------+     +-------+--------+     +------+-------+  |        |
|   |          |                      |                     |          |        |
|   |          +----------------------+---------------------+          |        |
|   |                                 |                                |        |
|   |                                 v                                |        |
|   |                    +------------------------+                    |        |
|   |                    |    Execution Engine    |                    |        |
|   |                    | * Pre-flight checks    |                    |        |
|   |                    | * Credential injection |                    |        |
|   |                    | * Command execution    |                    |        |
|   |                    | * Output capture       |                    |        |
|   |                    +----------+-------------+                    |        |
|   |                               |                                  |        |
|   |  +----------------+           |           +----------------+     |        |
|   |  | Credential     |<----------+---------->|   Audit Log    |     |        |
|   |  | Vault (JIT)    |                       | * Task events  |     |        |
|   |  +----------------+                       +----------------+     |        |
|   +------------------------------------------------------------------+        |
|                                 |                                             |
|                                 | 2. Execute with credentials                 |
|                                 v                                             |
|   +------------------------------------------------------------------+        |
|   |  +-----------+  +-----------+  +-----------+  +-----------+      |        |
|   |  | Linux     |  | Windows   |  | Network   |  | Database  |      |        |
|   |  +-----------+  +-----------+  +-----------+  +-----------+      |        |
|   +------------------------------------------------------------------+        |
|                                                                               |
+===============================================================================+
```

### Component Responsibilities

| Component | Responsibility |
|-----------|---------------|
| **Task Manager** | Task validation, queuing, lifecycle management |
| **Scheduler** | Time-based task triggering, maintenance windows |
| **Approval Workflow** | Multi-level approval for sensitive tasks |
| **Execution Engine** | Secure task execution with credential injection |
| **Credential Vault** | Just-in-time credential provisioning |
| **Audit Log** | Complete task execution audit trail |

---

## Task Types

### Scheduled Tasks

Execute automatically based on defined schedules, similar to cron jobs but with PAM controls.

```json
{
    "task_name": "daily-config-backup",
    "type": "scheduled",
    "schedule": {
        "type": "cron",
        "expression": "0 2 * * *",
        "timezone": "UTC"
    },
    "targets": ["network-devices"],
    "script": "config-backup.sh"
}
```

### Event-Triggered Tasks

Execute in response to specific events within WALLIX Bastion.

| Event Category | Trigger Events |
|----------------|----------------|
| Session | session.start, session.end, session.terminated |
| Password | password.rotated, password.checkout |
| Authentication | auth.failure.threshold, auth.lockout |
| System | device.added, device.modified |

```json
{
    "task_name": "post-session-verify",
    "type": "event-triggered",
    "trigger": {
        "event": "session.end",
        "conditions": {
            "target_group": "high-security-servers"
        }
    },
    "script": "verify-password.sh"
}
```

### On-Demand Tasks

Executed manually by authorized users through UI or API.

```json
{
    "task_name": "restart-service",
    "type": "on-demand",
    "parameters": [
        {
            "name": "service_name",
            "type": "string",
            "required": true,
            "validation": "^[a-z][a-z0-9_-]*$"
        }
    ],
    "authorization": {
        "user_groups": ["linux-admins"],
        "approval_required": true
    }
}
```

### Approval-Gated Tasks

Tasks requiring explicit approval before execution.

```json
{
    "task_name": "emergency-patch",
    "approval": {
        "required": true,
        "approvers": {
            "groups": ["security-team", "change-management"],
            "minimum_approvals": 2
        },
        "timeout_hours": 4,
        "auto_deny_on_timeout": true
    }
}
```

---

## Task Definition

### Script Types

| Type | Description | Target Platforms |
|------|-------------|------------------|
| Shell (bash) | Linux/Unix shell scripts | Linux, Unix, MacOS |
| PowerShell | Windows automation | Windows Server |
| Python | Cross-platform scripts | All platforms |
| Expect | Interactive automation | Network devices |
| SQL | Database commands | Oracle, SQL, MySQL |

### Example: Linux Configuration Backup

```bash
#!/bin/bash
# Task: config-backup.sh
set -euo pipefail

# WALLIX injects these at runtime - NEVER hardcode credentials
# ${WALLIX_TARGET_HOST}, ${WALLIX_TARGET_USER}, ${WALLIX_TARGET_PASSWORD}

BACKUP_PATH="${1:-/var/backup/configs}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
HOSTNAME=$(hostname)

mkdir -p "${BACKUP_PATH}/${HOSTNAME}"

tar -czf "${BACKUP_PATH}/${HOSTNAME}/etc-${TIMESTAMP}.tar.gz" \
    /etc/passwd /etc/group /etc/sudoers /etc/ssh/sshd_config 2>/dev/null || true

echo "Backup completed: ${BACKUP_PATH}/${HOSTNAME}"
exit 0
```

### Parameter Handling

```json
{
    "task_name": "disk-cleanup",
    "parameters": [
        {
            "name": "path",
            "type": "string",
            "required": true,
            "default": "/tmp",
            "allowed_values": ["/tmp", "/var/log", "/var/cache"]
        },
        {
            "name": "days_old",
            "type": "integer",
            "default": 30,
            "min": 1,
            "max": 365
        },
        {
            "name": "dry_run",
            "type": "boolean",
            "default": true
        }
    ]
}
```

**Parameter Injection Methods:**
- Environment variables: `WALLIX_PARAM_<NAME>`
- Command-line arguments: in defined order
- JSON input file: `/tmp/wallix_task_params.json`

### Output Capture

```json
{
    "output": {
        "capture_stdout": true,
        "capture_stderr": true,
        "max_output_size_kb": 1024,
        "store_output": true,
        "retention_days": 90,
        "sanitize_patterns": ["password=.*", "secret=.*"]
    }
}
```

---

## Scheduling

### Schedule Configuration

| Expression | Description |
|------------|-------------|
| `0 2 * * *` | Daily at 2:00 AM |
| `0 */4 * * *` | Every 4 hours |
| `0 0 * * 0` | Weekly on Sunday at midnight |
| `0 3 1 * *` | Monthly on 1st at 3:00 AM |
| `0 2 * * 1-5` | Weekdays at 2:00 AM |

### Maintenance Windows

```json
{
    "maintenance_window": {
        "name": "weekly-sunday",
        "schedule": {
            "day_of_week": "sunday",
            "start_time": "02:00",
            "end_time": "06:00",
            "timezone": "America/New_York"
        },
        "restrictions": {
            "max_concurrent_tasks": 5,
            "allowed_task_types": ["maintenance", "backup"]
        }
    }
}
```

### Blackout Periods

Prevent task execution during critical business times:

```json
{
    "blackout_periods": [
        {
            "name": "month-end-close",
            "type": "recurring",
            "schedule": {
                "day_of_month": [-3, -2, -1, 1, 2],
                "all_day": true
            },
            "applies_to": {
                "target_groups": ["finance-servers"],
                "task_types": ["maintenance"]
            }
        },
        {
            "name": "holiday-freeze-2026",
            "type": "one-time",
            "schedule": {
                "start": "2026-12-20T00:00:00",
                "end": "2027-01-03T00:00:00"
            }
        }
    ]
}
```

### Timezone Handling

| Option | Description |
|--------|-------------|
| `use_target_timezone` | Execute based on target system's timezone |
| `dst_handling` | skip_invalid, run_twice, adjust |
| `display_timezone` | UTC, local, target |

---

## Credential Handling

### Just-in-Time Credential Injection

```
+===============================================================================+
|                  JUST-IN-TIME CREDENTIAL INJECTION                            |
+===============================================================================+
|                                                                               |
|  +----------+     +----------------+     +----------------+     +----------+  |
|  |  Task    |---->| Task Engine    |---->| Credential     |---->| Target   |  |
|  | Request  |     | (validates)    |     | Vault (JIT)    |     | System   |  |
|  +----------+     +----------------+     +-------+--------+     +----------+  |
|                                                  |                            |
|                                                  v                            |
|                                          +----------------+                   |
|                                          | Credential     |                   |
|                                          | Injected into  |                   |
|                                          | task runtime   |                   |
|                                          | (never logged) |                   |
|                                          +----------------+                   |
|                                                                               |
|  JIT WORKFLOW:                                                                |
|  1. Task execution initiated                                                  |
|  2. Engine validates task and authorization                                   |
|  3. Engine requests credential from vault (JIT checkout)                      |
|  4. Credential injected into secure runtime environment                       |
|  5. Task executes with credential available                                   |
|  6. Upon completion, credential automatically checked in                      |
|  7. Credential rotated if configured (post-task rotation)                     |
|                                                                               |
+===============================================================================+
```

### Credential Configuration

```json
{
    "task_name": "server-health-check",
    "credentials": {
        "type": "managed_account",
        "account": "svc-monitor@linux-servers",
        "checkout_mode": "automatic",
        "post_task_action": "checkin"
    }
}
```

| Option | Values |
|--------|--------|
| type | managed_account, ssh_key, certificate |
| checkout_mode | automatic, on_demand |
| post_task_action | checkin, rotate, keep_checked_out |

### Credential Protection

**Security Measures:**
- Scripts run in isolated process space
- Environment variables cleared after execution
- Credentials never written to logs
- Output sanitized for credential patterns
- Memory zeroed after use

**Anti-Patterns to Avoid:**
- NEVER embed credentials in scripts
- NEVER log credential values
- NEVER pass credentials as command-line arguments
- NEVER store credentials in task output

### Post-Task Rotation

```json
{
    "credentials": {
        "account": "admin@critical-server",
        "rotation": {
            "rotate_after_task": true,
            "rotation_delay_seconds": 60,
            "verify_rotation": true
        }
    }
}
```

---

## Task Execution

### Execution Environment

| Variable | Description |
|----------|-------------|
| `WALLIX_TASK_ID` | Unique task execution ID |
| `WALLIX_TASK_NAME` | Task definition name |
| `WALLIX_TARGET_HOST` | Target hostname or IP |
| `WALLIX_TARGET_USER` | Target account username |
| `WALLIX_TARGET_PORT` | Target connection port |
| `WALLIX_PARAM_<NAME>` | Task parameters (uppercase) |
| `WALLIX_OUTPUT_DIR` | Directory for task output files |

### Timeout Handling

```json
{
    "timeout": {
        "execution_timeout_seconds": 3600,
        "connection_timeout_seconds": 30,
        "idle_timeout_seconds": 300,
        "warning_threshold_percent": 80,
        "on_timeout": "terminate"
    }
}
```

| Action | Description |
|--------|-------------|
| terminate | Kill task immediately (SIGTERM then SIGKILL) |
| graceful | Send SIGTERM, wait grace period, then SIGKILL |
| notify_only | Alert but allow task to continue |
| extend | Automatically extend timeout (with limit) |

### Error Handling

```json
{
    "error_handling": {
        "on_script_error": {
            "action": "retry",
            "max_retries": 3,
            "retry_delay_seconds": 60,
            "escalate_after_retries": true
        },
        "exit_code_handling": {
            "0": "success",
            "1": "warning",
            "2-10": "error",
            "default": "failure"
        }
    }
}
```

### Retry Logic

| Strategy | Description | Best For |
|----------|-------------|----------|
| Fixed delay | Same delay between retries | Known recovery |
| Exponential | Doubling delay each retry | Transient errors |
| Linear backoff | Increasing delay linearly | Load issues |
| Random jitter | Random delay within range | Thundering herd |

---

## Common Use Cases

### Automated Password Verification

```json
{
    "task_name": "password-verification",
    "type": "scheduled",
    "schedule": {"type": "cron", "expression": "0 3 * * *"},
    "targets": {"type": "all_managed_accounts"},
    "script": "verify-password.sh",
    "on_failure": {
        "flag_account": true,
        "notify": ["pam-admin@company.com"],
        "trigger_reconciliation": true
    }
}
```

### Configuration Backup

```json
{
    "task_name": "network-config-backup",
    "type": "scheduled",
    "schedule": {"type": "cron", "expression": "0 1 * * *"},
    "targets": {"target_group": "network-devices"},
    "script": "backup-network-config.exp",
    "output": {
        "capture_stdout": true,
        "backup_storage": "/backup/network-configs"
    }
}
```

### Compliance Scanning

```json
{
    "task_name": "cis-benchmark-scan",
    "type": "scheduled",
    "schedule": {"type": "weekly", "day": "sunday", "time": "04:00"},
    "targets": {"target_group": "linux-servers"},
    "reporting": {
        "generate_report": true,
        "report_format": "pdf",
        "email_report": ["compliance@company.com"]
    }
}
```

### Patch Status Checking

```json
{
    "task_name": "patch-status-check",
    "type": "scheduled",
    "schedule": {"type": "daily", "time": "06:00"},
    "targets": {"target_groups": ["linux-servers", "windows-servers"]},
    "thresholds": {
        "critical_patches_max_age_days": 7,
        "security_patches_max_age_days": 30
    },
    "alerts": {
        "on_critical_missing": ["security@company.com"]
    }
}
```

### Log Collection

```json
{
    "task_name": "collect-security-logs",
    "type": "scheduled",
    "schedule": {"type": "cron", "expression": "0 */4 * * *"},
    "parameters": [
        {"name": "log_types", "default": "auth,secure,audit"},
        {"name": "since_hours", "default": 4}
    ],
    "output": {"destination": "siem", "format": "syslog"}
}
```

---

## Security Controls

### Task Approval Workflows

| Level | Approvers | Use Case |
|-------|-----------|----------|
| None | Auto-approved | Low-risk operational tasks |
| Single | One approver | Standard maintenance |
| Dual | Two approvers | Security-sensitive tasks |
| Manager | Direct manager | Change management |
| Multi | Multiple groups | High-impact operations |

```json
{
    "approval_workflow": {
        "required": true,
        "type": "multi-level",
        "levels": [
            {
                "level": 1,
                "name": "Technical Approval",
                "approvers": {"groups": ["operations-lead"], "min_approvals": 1},
                "timeout_hours": 2
            },
            {
                "level": 2,
                "name": "Change Approval",
                "approvers": {"groups": ["change-management"], "min_approvals": 1},
                "timeout_hours": 4
            }
        ]
    }
}
```

### Audit Trail

| Event | Data Captured |
|-------|---------------|
| task.created | Task definition, creator, timestamp |
| task.execution.started | Task ID, target, user, parameters |
| task.execution.ended | Duration, exit code, output hash |
| task.approval.requested | Requestor, target, justification |
| task.credential.used | Account, checkout time, checkin time |

### Output Sanitization

```json
{
    "output_sanitization": {
        "enabled": true,
        "patterns": [
            {"name": "passwords", "regex": "(?i)(password|pwd)\\s*[=:]\\s*[^\\s]+", "replacement": "$1=***REDACTED***"},
            {"name": "api_keys", "regex": "(?i)(api[_-]?key)\\s*[=:]\\s*[^\\s]+", "replacement": "$1=***REDACTED***"}
        ]
    }
}
```

### Command Restrictions

```json
{
    "command_restrictions": {
        "mode": "whitelist",
        "whitelist": ["ls", "cat", "grep", "df", "systemctl status *"],
        "blacklist": ["rm -rf /", "shutdown", "reboot", "passwd"],
        "alert_on_blocked": true
    }
}
```

---

## Monitoring and Alerting

### Task Execution Status

```
+-----------------------------------------------------------------------+
|                    TASK AUTOMATION DASHBOARD                          |
+-----------------------------------------------------------------------+
|  Today's Summary                                                      |
|  +---------------+  +---------------+  +---------------+              |
|  | Executed: 47  |  | Success: 45   |  | Failed: 2     |              |
|  +---------------+  +---------------+  +---------------+              |
|                                                                       |
|  Scheduled Tasks (Next 24h)                                           |
|  +----------------------------------------------------------------+  |
|  | Task Name              | Next Run     | Target Count | Status  |  |
|  +------------------------+--------------+--------------+---------+  |
|  | daily-config-backup    | 02:00        | 45           | Ready   |  |
|  | password-verification  | 03:00        | 120          | Ready   |  |
|  +----------------------------------------------------------------+  |
+-----------------------------------------------------------------------+
```

### Failure Notifications

```json
{
    "notifications": {
        "channels": {
            "email": {"enabled": true, "from": "wallix-tasks@company.com"},
            "slack": {"enabled": true, "webhook_url": "https://hooks.slack.com/..."},
            "pagerduty": {"enabled": true, "routing_key": "R01234567890"}
        },
        "rules": [
            {
                "condition": "task.status == 'failed'",
                "severity": "high",
                "channels": ["email", "slack"]
            },
            {
                "condition": "task.failures_consecutive >= 3",
                "severity": "critical",
                "channels": ["email", "slack", "pagerduty"]
            }
        ]
    }
}
```

### SLA Monitoring

```json
{
    "sla_monitoring": {
        "slas": [
            {
                "name": "backup-completion",
                "metric": "task_completion_time",
                "task_group": "backup-tasks",
                "threshold": "06:00",
                "measurement_period": "daily"
            },
            {
                "name": "task-success-rate",
                "metric": "success_rate_percent",
                "threshold": 99,
                "measurement_period": "weekly"
            }
        ]
    }
}
```

---

## API Integration

### Triggering Tasks via API

**Execute Task:**
```bash
POST /api/v2/tasks/{task_name}/execute

{
    "targets": ["srv-prod-01", "srv-prod-02"],
    "parameters": {"path": "/var/log", "days_old": 30},
    "justification": "Monthly log cleanup per CHG-12345"
}
```

**Response:**
```json
{
    "execution_id": "exec_20260201_001234",
    "status": "queued",
    "targets_count": 2,
    "status_url": "/api/v2/tasks/executions/exec_20260201_001234"
}
```

### Python Example

```python
import requests

def execute_task(task_name, targets, parameters=None, justification=None):
    headers = {"Authorization": f"Bearer {API_KEY}", "Content-Type": "application/json"}
    payload = {
        "targets": targets,
        "parameters": parameters or {},
        "justification": justification
    }
    response = requests.post(
        f"{WALLIX_URL}/api/v2/tasks/{task_name}/execute",
        headers=headers, json=payload
    )
    return response.json()
```

### Task Status Queries

```bash
# Get execution status
GET /api/v2/tasks/executions/{execution_id}

# List running executions
GET /api/v2/tasks/executions?status=running&limit=20

# Get execution output
GET /api/v2/tasks/executions/{execution_id}/output
```

### API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v2/tasks` | GET | List all tasks |
| `/api/v2/tasks` | POST | Create new task |
| `/api/v2/tasks/{name}` | GET | Get task details |
| `/api/v2/tasks/{name}/execute` | POST | Execute task |
| `/api/v2/tasks/executions` | GET | List executions |
| `/api/v2/tasks/executions/{id}` | GET | Get execution status |
| `/api/v2/tasks/executions/{id}/output` | GET | Get execution output |
| `/api/v2/tasks/executions/{id}/cancel` | POST | Cancel execution |

---

## Troubleshooting

### Common Failure Types

| Error Code | Description | Resolution |
|------------|-------------|------------|
| TASK_NOT_FOUND | Task definition missing | Verify task exists |
| AUTH_DENIED | Not authorized for task | Check permissions |
| TARGET_UNREACHABLE | Cannot connect to target | Check network/firewall |
| CRED_CHECKOUT_FAIL | Cannot get credentials | Check account status |
| SCRIPT_ERROR | Script returned non-zero | Review script output |
| TIMEOUT | Execution timed out | Increase timeout |
| APPROVAL_DENIED | Approval was rejected | Review request |

### Diagnostic Commands

```bash
# View task execution details
wabadmin task execution show <execution_id> --verbose

# View task execution log
wabadmin task execution log <execution_id>

# Test task without executing
wabadmin task test <task_name> --target srv-prod-01 --dry-run

# Verify script syntax
wabadmin task script verify /path/to/script.sh

# Check target connectivity
wabadmin connectivity-test --target srv-prod-01
```

### Timeout Troubleshooting

| Issue | Check | Resolution |
|-------|-------|------------|
| Connection Timeout | Network connectivity, firewall rules | Verify target responding |
| Execution Timeout | Task duration, target load | Increase timeout or optimize script |
| Idle Timeout | Script waiting for input | Ensure script is non-interactive |

### Permission Troubleshooting

```bash
# Verify user has task authorization
wabadmin authorization check --user jsmith --task config-backup

# Verify credential access
wabadmin authorization check --user jsmith --account svc-backup@srv-prod-01

# Check user group membership
wabadmin user show jsmith --groups
```

### Debug Mode

```bash
# Enable debug mode for task engine
wabadmin config set task.debug_mode true

# Run task with verbose output
wabadmin task execute <task_name> --target srv-prod-01 --verbose --debug

# View debug logs
tail -f /var/log/wallix/task-engine.debug.log

# IMPORTANT: Disable after troubleshooting
wabadmin config set task.debug_mode false
```

---

## Quick Reference

### CLI Commands

```bash
# Task Management
wabadmin task list                           # List all tasks
wabadmin task show <task_name>               # Show task details
wabadmin task create --file task.json        # Create task from file
wabadmin task delete <task_name>             # Delete task

# Execution
wabadmin task execute <task_name> --target <target>
wabadmin task schedule <task_name> --cron "0 2 * * *"

# Monitoring
wabadmin task executions --status running
wabadmin task execution show <id>
wabadmin task execution cancel <id>

# Approvals
wabadmin approval list --pending
wabadmin approval approve <id>
wabadmin approval deny <id> --reason "..."
```

---

## Related Documentation

| Document | Description |
|----------|-------------|
| [09 - API & Automation](../10-api-automation/README.md) | REST API integration details |
| [07 - Password Management](../08-password-management/README.md) | Credential vault and rotation |
| [30 - Operational Runbooks](../21-operational-runbooks/README.md) | Operational procedures |
| [06 - Authorization](../07-authorization/README.md) | Access control and approvals |

---

## External References

| Resource | URL |
|----------|-----|
| WALLIX Documentation | https://pam.wallix.one/documentation |
| REST API Samples | https://github.com/wallix/wbrest_samples |
| Terraform Provider | https://registry.terraform.io/providers/wallix/wallix-bastion |
| Support Portal | https://support.wallix.com |

---

## See Also

**Related Sections:**
- [42 - Service Account Lifecycle](../42-service-account-lifecycle/README.md) - Service account governance
- [10 - API & Automation](../10-api-automation/README.md) - REST API integration

**Related Documentation:**
- [Examples: Ansible](/examples/ansible/README.md) - Ansible automation examples

**Official Resources:**
- [WALLIX Documentation](https://pam.wallix.one/documentation)
- [WALLIX REST API Samples](https://github.com/wallix/wbrest_samples)

---

*Document Version: 1.0*
*Last Updated: February 2026*
*Applies to: WALLIX Bastion 12.1.x*
