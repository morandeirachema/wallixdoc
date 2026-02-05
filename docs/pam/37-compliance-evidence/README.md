# 48 - Compliance Evidence Collection and Automation

This section provides comprehensive guidance for collecting, automating, and presenting compliance evidence using WALLIX Bastion across major regulatory frameworks.

---

## Table of Contents

1. [Compliance Overview](#compliance-overview)
2. [Evidence Architecture](#evidence-architecture)
3. [SOC 2 Type II Evidence](#soc-2-type-ii-evidence)
4. [ISO 27001 Evidence](#iso-27001-evidence)
5. [PCI-DSS Evidence](#pci-dss-evidence)
6. [HIPAA Evidence](#hipaa-evidence)
7. [GDPR Evidence](#gdpr-evidence)
8. [IEC 62443 Evidence](#iec-62443-evidence)
9. [Automated Evidence Collection](#automated-evidence-collection)
10. [API-Based Evidence Extraction](#api-based-evidence-extraction)
11. [Audit Preparation](#audit-preparation)
12. [Continuous Compliance Monitoring](#continuous-compliance-monitoring)

---

## Compliance Overview

### Supported Compliance Frameworks

WALLIX Bastion provides evidence for the following regulatory frameworks:

| Framework | Coverage | Primary Evidence Types |
|-----------|----------|------------------------|
| SOC 2 Type II | High | Access logs, session recordings, policy configurations |
| ISO 27001 | High | Access control, cryptography, operations security |
| PCI-DSS | High | Cardholder data access, authentication, audit logs |
| HIPAA | Medium | PHI access, audit controls, authentication |
| GDPR | Medium | Data access logging, consent, retention |
| IEC 62443 | Full | OT access, security levels, zone documentation |
| NIST 800-82 | Full | ICS security controls, privileged access |
| NIS2 | Full | Essential services protection, incident handling |

### Evidence Types and Sources

```
+==============================================================================+
|                   EVIDENCE TYPE MATRIX                                       |
+==============================================================================+

  CONFIGURATION EVIDENCE
  ======================
  Source: WALLIX Configuration Export
  +------------------------------------------------------------------------+
  | Evidence Type                    | API Endpoint / Command              |
  +----------------------------------+-------------------------------------+
  | User accounts and roles          | GET /api/v2/users                   |
  | Group memberships                | GET /api/v2/groups                  |
  | Authorization policies           | GET /api/v2/authorizations          |
  | Password policies                | GET /api/v2/policies/password       |
  | Session policies                 | GET /api/v2/policies/session        |
  | MFA configuration                | GET /api/v2/config/mfa              |
  | Encryption settings              | wabadmin config --export            |
  +----------------------------------+-------------------------------------+

  OPERATIONAL EVIDENCE
  ====================
  Source: WALLIX Audit Logs and Sessions
  +------------------------------------------------------------------------+
  | Evidence Type                    | API Endpoint / Command              |
  +----------------------------------+-------------------------------------+
  | Session recordings               | GET /api/v2/sessions                |
  | Authentication logs              | GET /api/v2/audit/logs?type=auth    |
  | Administrative actions           | GET /api/v2/audit/logs?type=admin   |
  | Password rotations               | GET /api/v2/passwords/rotation-jobs |
  | Approval workflows               | GET /api/v2/approvals               |
  | Access requests                  | GET /api/v2/access-requests         |
  +----------------------------------+-------------------------------------+

  COMPLIANCE REPORTS
  ==================
  Source: WALLIX Reporting Engine
  +------------------------------------------------------------------------+
  | Report Type                      | Generation Method                   |
  +----------------------------------+-------------------------------------+
  | Access review                    | wabadmin report --type access-review|
  | Privileged activity              | wabadmin report --type priv-activity|
  | Password compliance              | wabadmin report --type pwd-comply   |
  | Session summary                  | wabadmin report --type session-sum  |
  | Failed access attempts           | wabadmin report --type failed-access|
  +----------------------------------+-------------------------------------+

+==============================================================================+
```

---

## Evidence Architecture

### Evidence Collection Flow

```
+==============================================================================+
|                   EVIDENCE COLLECTION ARCHITECTURE                           |
+==============================================================================+

                              WALLIX BASTION
  +------------------------------------------------------------------------+
  |                                                                        |
  |  +------------------+  +------------------+  +------------------+       |
  |  |  Session Manager |  | Password Manager |  |  Access Manager  |       |
  |  +--------+---------+  +--------+---------+  +--------+---------+       |
  |           |                     |                     |                |
  |           +----------+----------+----------+----------+                |
  |                      |                     |                           |
  |              +-------v-------+     +-------v-------+                   |
  |              | Audit Engine  |     |  Config DB    |                   |
  |              +-------+-------+     +-------+-------+                   |
  |                      |                     |                           |
  +----------------------|---------------------|---------------------------+
                         |                     |
         +---------------+---------------------+---------------+
         |                                                     |
         v                                                     v
  +------+------+                                       +------+------+
  | Audit Logs  |                                       |  Policies   |
  | - Sessions  |                                       | - Configs   |
  | - Auth logs |                                       | - Users     |
  | - Admin ops |                                       | - Authz     |
  +------+------+                                       +------+------+
         |                                                     |
         +------------------------+----------------------------+
                                  |
                                  v
                    +-------------+-------------+
                    |   Evidence Collector      |
                    |   (Scheduled/On-Demand)   |
                    +-------------+-------------+
                                  |
         +------------------------+------------------------+
         |                        |                        |
         v                        v                        v
  +------+------+          +------+------+          +------+------+
  |   SOC 2     |          |  ISO 27001  |          |   PCI-DSS   |
  |  Evidence   |          |  Evidence   |          |  Evidence   |
  +-------------+          +-------------+          +-------------+
         |                        |                        |
         v                        v                        v
  +------+------+          +------+------+          +------+------+
  |   HIPAA     |          |    GDPR     |          | IEC 62443   |
  |  Evidence   |          |  Evidence   |          |  Evidence   |
  +-------------+          +-------------+          +-------------+
                                  |
                                  v
                    +-------------+-------------+
                    |   Evidence Repository     |
                    |   /evidence/<framework>/  |
                    |   /evidence/<date>/       |
                    +-------------+-------------+
                                  |
         +------------------------+------------------------+
         |                        |                        |
         v                        v                        v
  +------+------+          +------+------+          +------+------+
  |  Long-term  |          | SIEM Export |          |   Auditor   |
  |   Archive   |          | (Splunk/ELK)|          |   Portal    |
  +-------------+          +-------------+          +-------------+

+==============================================================================+
```

### Evidence Storage Structure

```bash
/evidence/
├── soc2/
│   ├── 2026-Q1/
│   │   ├── cc6.1-access-controls/
│   │   ├── cc6.2-user-lifecycle/
│   │   ├── cc7.2-monitoring/
│   │   └── checksums.sha256
│   └── 2026-Q2/
├── iso27001/
│   ├── 2026-Q1/
│   │   ├── a9-access-control/
│   │   ├── a10-cryptography/
│   │   ├── a12-operations/
│   │   └── checksums.sha256
│   └── 2026-Q2/
├── pci-dss/
│   ├── 2026-Q1/
│   │   ├── req7-access-control/
│   │   ├── req8-authentication/
│   │   ├── req10-audit-logs/
│   │   └── checksums.sha256
│   └── 2026-Q2/
├── hipaa/
├── gdpr/
├── iec62443/
└── master/
    ├── configs/
    ├── audit-logs/
    └── reports/
```

---

## SOC 2 Type II Evidence

### Control Mapping Table

```
+==============================================================================+
|                   SOC 2 TYPE II CONTROL MAPPING                              |
+==============================================================================+

  COMMON CRITERIA (CC) - SECURITY
  ================================

  +--------+--------------------------------+-------------------------------+
  | Control| Description                    | WALLIX Evidence               |
  +--------+--------------------------------+-------------------------------+
  |        |                                |                               |
  | CC6.1  | Logical and physical access    | - User list with roles        |
  |        | security software,             | - MFA configuration           |
  |        | infrastructure, and            | - Authentication policy       |
  |        | architectures                  | - Session policy export       |
  |        |                                |                               |
  +--------+--------------------------------+-------------------------------+
  |        |                                |                               |
  | CC6.2  | Prior to issuing system        | - User provisioning logs      |
  |        | credentials and granting       | - Approval workflow records   |
  |        | system access, the entity      | - Authorization assignments   |
  |        | registers and authorizes       | - Group membership history    |
  |        | new internal and external      |                               |
  |        | users                          |                               |
  |        |                                |                               |
  +--------+--------------------------------+-------------------------------+
  |        |                                |                               |
  | CC6.3  | The entity authorizes,         | - Deprovisioning logs         |
  |        | modifies, or removes           | - Access revocation records   |
  |        | access to data, software,      | - Credential rotation after   |
  |        | functions, and other           |   termination                 |
  |        | protected information          |                               |
  |        | assets                         |                               |
  |        |                                |                               |
  +--------+--------------------------------+-------------------------------+
  |        |                                |                               |
  | CC6.6  | The entity implements          | - Session policy configs      |
  |        | logical access security        | - Command restrictions        |
  |        | measures to protect against    | - Protocol restrictions       |
  |        | threats from sources           | - Time-based access rules     |
  |        | outside its system boundaries  |                               |
  |        |                                |                               |
  +--------+--------------------------------+-------------------------------+
  |        |                                |                               |
  | CC6.7  | The entity restricts the       | - Network architecture docs   |
  |        | transmission, movement,        | - Jump host configuration     |
  |        | and removal of information     | - Session proxy settings      |
  |        | to authorized internal and     | - File transfer policies      |
  |        | external users and processes   |                               |
  |        |                                |                               |
  +--------+--------------------------------+-------------------------------+
  |        |                                |                               |
  | CC7.1  | To meet its objectives, the    | - Vulnerability scan results  |
  |        | entity uses detection and      | - Security monitoring config  |
  |        | monitoring procedures          | - Alert rule configurations   |
  |        |                                |                               |
  +--------+--------------------------------+-------------------------------+
  |        |                                |                               |
  | CC7.2  | The entity monitors system     | - Real-time monitoring logs   |
  |        | components and the operation   | - Session monitoring records  |
  |        | of those components for        | - System health checks        |
  |        | anomalies                      | - Alert notifications         |
  |        |                                |                               |
  +--------+--------------------------------+-------------------------------+
  |        |                                |                               |
  | CC7.3  | The entity evaluates           | - Security event analysis     |
  |        | security events to determine   | - Incident investigation logs |
  |        | whether they could or have     | - Session recording reviews   |
  |        | resulted in a failure          |                               |
  |        |                                |                               |
  +--------+--------------------------------+-------------------------------+
  |        |                                |                               |
  | CC7.4  | The entity responds to         | - Incident response records   |
  |        | identified security            | - Session termination logs    |
  |        | incidents                      | - Emergency access revocation |
  |        |                                |                               |
  +--------+--------------------------------+-------------------------------+

+==============================================================================+
```

### SOC 2 Evidence Collection Script

```bash
#!/bin/bash
# /opt/wallix/scripts/collect-soc2-evidence.sh
# SOC 2 Type II Evidence Collection Script

set -euo pipefail

# Configuration
WALLIX_HOST="${WALLIX_HOST:-localhost}"
API_TOKEN="${WALLIX_API_TOKEN}"
EVIDENCE_BASE="/evidence/soc2"
QUARTER=$(date +%Y-Q$(( ($(date +%-m) - 1) / 3 + 1 )))
PERIOD_START=$(date -d "3 months ago" +%Y-%m-%d)
PERIOD_END=$(date +%Y-%m-%d)

# Create evidence directory structure
EVIDENCE_DIR="${EVIDENCE_BASE}/${QUARTER}"
mkdir -p "${EVIDENCE_DIR}"/{cc6.1-access-controls,cc6.2-user-lifecycle,cc6.3-access-removal}
mkdir -p "${EVIDENCE_DIR}"/{cc6.6-access-restrictions,cc6.7-system-boundaries}
mkdir -p "${EVIDENCE_DIR}"/{cc7.1-vulnerability,cc7.2-monitoring,cc7.3-anomalies,cc7.4-incidents}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

api_call() {
    local endpoint="$1"
    local output="$2"
    curl -s -H "Authorization: Bearer ${API_TOKEN}" \
         -H "Accept: application/json" \
         "https://${WALLIX_HOST}/api/v2${endpoint}" > "${output}"
}

log "Starting SOC 2 evidence collection for ${QUARTER}"
log "Period: ${PERIOD_START} to ${PERIOD_END}"

# CC6.1 - Logical Access Security
log "Collecting CC6.1 - Access Controls..."
api_call "/users" "${EVIDENCE_DIR}/cc6.1-access-controls/users.json"
api_call "/groups" "${EVIDENCE_DIR}/cc6.1-access-controls/groups.json"
api_call "/authorizations" "${EVIDENCE_DIR}/cc6.1-access-controls/authorizations.json"
api_call "/config/mfa" "${EVIDENCE_DIR}/cc6.1-access-controls/mfa-config.json"
api_call "/policies/authentication" "${EVIDENCE_DIR}/cc6.1-access-controls/auth-policies.json"

# CC6.2 - User Registration and Authorization
log "Collecting CC6.2 - User Lifecycle..."
api_call "/audit/logs?event_type=user.create&start_date=${PERIOD_START}&end_date=${PERIOD_END}" \
    "${EVIDENCE_DIR}/cc6.2-user-lifecycle/user-creations.json"
api_call "/audit/logs?event_type=authorization.grant&start_date=${PERIOD_START}&end_date=${PERIOD_END}" \
    "${EVIDENCE_DIR}/cc6.2-user-lifecycle/authorization-grants.json"
api_call "/approvals?status=approved&start_date=${PERIOD_START}&end_date=${PERIOD_END}" \
    "${EVIDENCE_DIR}/cc6.2-user-lifecycle/approval-records.json"

# CC6.3 - Access Removal
log "Collecting CC6.3 - Access Removal..."
api_call "/audit/logs?event_type=user.delete&start_date=${PERIOD_START}&end_date=${PERIOD_END}" \
    "${EVIDENCE_DIR}/cc6.3-access-removal/user-deletions.json"
api_call "/audit/logs?event_type=user.disable&start_date=${PERIOD_START}&end_date=${PERIOD_END}" \
    "${EVIDENCE_DIR}/cc6.3-access-removal/user-disables.json"
api_call "/audit/logs?event_type=authorization.revoke&start_date=${PERIOD_START}&end_date=${PERIOD_END}" \
    "${EVIDENCE_DIR}/cc6.3-access-removal/authorization-revocations.json"

# CC6.6 - Access Restrictions
log "Collecting CC6.6 - Access Restrictions..."
api_call "/policies/session" "${EVIDENCE_DIR}/cc6.6-access-restrictions/session-policies.json"
api_call "/policies/command" "${EVIDENCE_DIR}/cc6.6-access-restrictions/command-policies.json"
api_call "/authorizations?with_restrictions=true" \
    "${EVIDENCE_DIR}/cc6.6-access-restrictions/time-restrictions.json"

# CC6.7 - System Boundaries
log "Collecting CC6.7 - System Boundaries..."
api_call "/devices" "${EVIDENCE_DIR}/cc6.7-system-boundaries/devices.json"
api_call "/domains" "${EVIDENCE_DIR}/cc6.7-system-boundaries/domains.json"
wabadmin config --section network --export > \
    "${EVIDENCE_DIR}/cc6.7-system-boundaries/network-config.json" 2>/dev/null || true

# CC7.1 - Vulnerability Detection
log "Collecting CC7.1 - Vulnerability Detection..."
api_call "/system/health" "${EVIDENCE_DIR}/cc7.1-vulnerability/system-health.json"
api_call "/audit/logs?severity=warning,error,critical&start_date=${PERIOD_START}&end_date=${PERIOD_END}" \
    "${EVIDENCE_DIR}/cc7.1-vulnerability/security-events.json"

# CC7.2 - System Monitoring
log "Collecting CC7.2 - Monitoring..."
api_call "/sessions?start_date=${PERIOD_START}&end_date=${PERIOD_END}&per_page=1000" \
    "${EVIDENCE_DIR}/cc7.2-monitoring/session-log.json"
api_call "/audit/stats?start_date=${PERIOD_START}&end_date=${PERIOD_END}&group_by=day" \
    "${EVIDENCE_DIR}/cc7.2-monitoring/daily-stats.json"

# CC7.3 - Anomaly Evaluation
log "Collecting CC7.3 - Anomalies..."
api_call "/audit/logs?event_type=auth.failure&start_date=${PERIOD_START}&end_date=${PERIOD_END}" \
    "${EVIDENCE_DIR}/cc7.3-anomalies/auth-failures.json"
api_call "/audit/logs?event_type=session.terminate&start_date=${PERIOD_START}&end_date=${PERIOD_END}" \
    "${EVIDENCE_DIR}/cc7.3-anomalies/session-terminations.json"

# CC7.4 - Incident Response
log "Collecting CC7.4 - Incidents..."
api_call "/audit/logs?severity=critical&start_date=${PERIOD_START}&end_date=${PERIOD_END}" \
    "${EVIDENCE_DIR}/cc7.4-incidents/critical-events.json"
api_call "/audit/logs?event_type=security.incident&start_date=${PERIOD_START}&end_date=${PERIOD_END}" \
    "${EVIDENCE_DIR}/cc7.4-incidents/security-incidents.json"

# Generate checksums
log "Generating checksums..."
find "${EVIDENCE_DIR}" -type f -name "*.json" -exec sha256sum {} \; > \
    "${EVIDENCE_DIR}/checksums.sha256"

# Generate summary report
log "Generating summary report..."
cat > "${EVIDENCE_DIR}/collection-summary.txt" << EOF
SOC 2 Type II Evidence Collection Summary
==========================================
Collection Date: $(date '+%Y-%m-%d %H:%M:%S')
Audit Period: ${PERIOD_START} to ${PERIOD_END}
Quarter: ${QUARTER}

Evidence Categories Collected:
- CC6.1: Access Controls
- CC6.2: User Lifecycle
- CC6.3: Access Removal
- CC6.6: Access Restrictions
- CC6.7: System Boundaries
- CC7.1: Vulnerability Detection
- CC7.2: System Monitoring
- CC7.3: Anomaly Evaluation
- CC7.4: Incident Response

File Count: $(find "${EVIDENCE_DIR}" -type f -name "*.json" | wc -l)
Total Size: $(du -sh "${EVIDENCE_DIR}" | cut -f1)

Checksum File: checksums.sha256
EOF

log "SOC 2 evidence collection complete: ${EVIDENCE_DIR}"
```

### SOC 2 Report Template

```markdown
# SOC 2 Type II Compliance Evidence Report

## Report Information
- **Organization**: [Organization Name]
- **Audit Period**: [Start Date] to [End Date]
- **Report Generated**: [Generation Date]
- **WALLIX Bastion Version**: 12.1.x

---

## CC6.1 - Logical Access Security

### Evidence Summary
| Metric | Count |
|--------|-------|
| Total Users | [X] |
| Active Users | [X] |
| MFA-Enabled Users | [X] |
| Authorization Policies | [X] |

### Key Controls
- Multi-factor authentication enforced for all administrative access
- Role-based access control implemented via user groups
- Session policies enforce timeout and recording

### Supporting Documents
- `cc6.1-access-controls/users.json`
- `cc6.1-access-controls/mfa-config.json`
- `cc6.1-access-controls/auth-policies.json`

---

## CC6.2 - User Registration and Authorization

### Evidence Summary
| Activity | Count |
|----------|-------|
| New Users Created | [X] |
| Authorizations Granted | [X] |
| Approvals Processed | [X] |

### Key Controls
- All access requires approval workflow
- User creation logged with timestamp and approver
- Authorization grants tracked in audit log

### Supporting Documents
- `cc6.2-user-lifecycle/user-creations.json`
- `cc6.2-user-lifecycle/approval-records.json`

---

[Continue for each control category...]
```

---

## ISO 27001 Evidence

### Annex A Control Mapping

```
+==============================================================================+
|                   ISO 27001 ANNEX A CONTROL MAPPING                          |
+==============================================================================+

  A.9 ACCESS CONTROL
  ==================

  +----------+---------------------------+----------------------------------+
  | Control  | Requirement               | Evidence Collection              |
  +----------+---------------------------+----------------------------------+
  |          |                           |                                  |
  | A.9.1.1  | Access control policy     | - Policy document export         |
  |          |                           | - Authorization configuration    |
  |          |                           | - Approval workflow settings     |
  |          |                           |                                  |
  +----------+---------------------------+----------------------------------+
  |          |                           |                                  |
  | A.9.1.2  | Access to networks and    | - Network segmentation config    |
  |          | network services          | - Jump host configuration        |
  |          |                           | - VIP access settings            |
  |          |                           |                                  |
  +----------+---------------------------+----------------------------------+
  |          |                           |                                  |
  | A.9.2.1  | User registration and     | - User creation audit logs       |
  |          | de-registration           | - AD/LDAP sync configuration     |
  |          |                           | - SCIM provisioning logs         |
  |          |                           |                                  |
  +----------+---------------------------+----------------------------------+
  |          |                           |                                  |
  | A.9.2.2  | User access provisioning  | - Authorization grant logs       |
  |          |                           | - Approval workflow records      |
  |          |                           | - Role assignment history        |
  |          |                           |                                  |
  +----------+---------------------------+----------------------------------+
  |          |                           |                                  |
  | A.9.2.3  | Management of privileged  | - Privileged account inventory   |
  |          | access rights             | - Session recordings             |
  |          |                           | - Password checkout logs         |
  |          |                           |                                  |
  +----------+---------------------------+----------------------------------+
  |          |                           |                                  |
  | A.9.2.4  | Management of secret      | - Credential vault configuration |
  |          | authentication info       | - Password rotation history      |
  |          |                           | - Credential checkout records    |
  |          |                           |                                  |
  +----------+---------------------------+----------------------------------+
  |          |                           |                                  |
  | A.9.2.5  | Review of user access     | - Access review reports          |
  |          | rights                    | - Quarterly certification logs   |
  |          |                           | - Unused account reports         |
  |          |                           |                                  |
  +----------+---------------------------+----------------------------------+
  |          |                           |                                  |
  | A.9.2.6  | Removal or adjustment of  | - User deletion audit logs       |
  |          | access rights             | - Authorization revocation logs  |
  |          |                           | - Offboarding procedures         |
  |          |                           |                                  |
  +----------+---------------------------+----------------------------------+
  |          |                           |                                  |
  | A.9.4.1  | Information access        | - Target group configuration     |
  |          | restriction               | - Authorization policies         |
  |          |                           | - Session protocol restrictions  |
  |          |                           |                                  |
  +----------+---------------------------+----------------------------------+
  |          |                           |                                  |
  | A.9.4.2  | Secure log-on procedures  | - MFA configuration              |
  |          |                           | - Login banner settings          |
  |          |                           | - Account lockout policy         |
  |          |                           |                                  |
  +----------+---------------------------+----------------------------------+
  |          |                           |                                  |
  | A.9.4.3  | Password management       | - Password policy configuration  |
  |          | system                    | - Rotation schedule settings     |
  |          |                           | - Complexity requirements        |
  |          |                           |                                  |
  +----------+---------------------------+----------------------------------+

  A.10 CRYPTOGRAPHY
  =================

  +----------+---------------------------+----------------------------------+
  | Control  | Requirement               | Evidence Collection              |
  +----------+---------------------------+----------------------------------+
  |          |                           |                                  |
  | A.10.1.1 | Policy on the use of      | - TLS configuration              |
  |          | cryptographic controls    | - Encryption algorithm settings  |
  |          |                           | - Certificate inventory          |
  |          |                           |                                  |
  +----------+---------------------------+----------------------------------+
  |          |                           |                                  |
  | A.10.1.2 | Key management            | - Certificate rotation records   |
  |          |                           | - Key generation logs            |
  |          |                           | - HSM configuration (if used)    |
  |          |                           |                                  |
  +----------+---------------------------+----------------------------------+

  A.12 OPERATIONS SECURITY
  ========================

  +----------+---------------------------+----------------------------------+
  | Control  | Requirement               | Evidence Collection              |
  +----------+---------------------------+----------------------------------+
  |          |                           |                                  |
  | A.12.4.1 | Event logging             | - Audit log configuration        |
  |          |                           | - Log retention settings         |
  |          |                           | - SIEM integration status        |
  |          |                           |                                  |
  +----------+---------------------------+----------------------------------+
  |          |                           |                                  |
  | A.12.4.2 | Protection of log         | - Log encryption settings        |
  |          | information               | - Access control on logs         |
  |          |                           | - Tamper-evident configuration   |
  |          |                           |                                  |
  +----------+---------------------------+----------------------------------+
  |          |                           |                                  |
  | A.12.4.3 | Administrator and         | - Session recordings (sample)    |
  |          | operator logs             | - Administrative action logs     |
  |          |                           | - Command execution logs         |
  |          |                           |                                  |
  +----------+---------------------------+----------------------------------+
  |          |                           |                                  |
  | A.12.4.4 | Clock synchronisation     | - NTP configuration              |
  |          |                           | - Time sync status               |
  |          |                           |                                  |
  +----------+---------------------------+----------------------------------+

+==============================================================================+
```

### ISO 27001 Evidence Collection Script

```bash
#!/bin/bash
# /opt/wallix/scripts/collect-iso27001-evidence.sh
# ISO 27001 Evidence Collection Script

set -euo pipefail

WALLIX_HOST="${WALLIX_HOST:-localhost}"
API_TOKEN="${WALLIX_API_TOKEN}"
EVIDENCE_BASE="/evidence/iso27001"
QUARTER=$(date +%Y-Q$(( ($(date +%-m) - 1) / 3 + 1 )))
PERIOD_START=$(date -d "3 months ago" +%Y-%m-%d)
PERIOD_END=$(date +%Y-%m-%d)

EVIDENCE_DIR="${EVIDENCE_BASE}/${QUARTER}"
mkdir -p "${EVIDENCE_DIR}"/{a9-access-control,a10-cryptography,a12-operations}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

api_call() {
    local endpoint="$1"
    local output="$2"
    curl -s -H "Authorization: Bearer ${API_TOKEN}" \
         -H "Accept: application/json" \
         "https://${WALLIX_HOST}/api/v2${endpoint}" > "${output}"
}

log "Starting ISO 27001 evidence collection for ${QUARTER}"

# A.9 Access Control
log "Collecting A.9 - Access Control evidence..."

# A.9.1.1 - Access control policy
api_call "/policies" "${EVIDENCE_DIR}/a9-access-control/a9.1.1-policies.json"

# A.9.2.1 - User registration
api_call "/users" "${EVIDENCE_DIR}/a9-access-control/a9.2.1-user-inventory.json"
api_call "/audit/logs?event_type=user.create,user.delete&start_date=${PERIOD_START}&end_date=${PERIOD_END}" \
    "${EVIDENCE_DIR}/a9-access-control/a9.2.1-user-lifecycle.json"

# A.9.2.3 - Privileged access management
api_call "/accounts?type=privileged" "${EVIDENCE_DIR}/a9-access-control/a9.2.3-privileged-accounts.json"
api_call "/sessions?account_type=privileged&start_date=${PERIOD_START}&end_date=${PERIOD_END}" \
    "${EVIDENCE_DIR}/a9-access-control/a9.2.3-privileged-sessions.json"

# A.9.2.4 - Secret authentication management
api_call "/passwords/rotation-jobs?start_date=${PERIOD_START}&end_date=${PERIOD_END}" \
    "${EVIDENCE_DIR}/a9-access-control/a9.2.4-password-rotations.json"

# A.9.2.5 - Access review
api_call "/audit/reports/access_review?start_date=${PERIOD_START}&end_date=${PERIOD_END}" \
    "${EVIDENCE_DIR}/a9-access-control/a9.2.5-access-review.json"

# A.9.4.2 - Secure logon
api_call "/config/mfa" "${EVIDENCE_DIR}/a9-access-control/a9.4.2-mfa-config.json"
api_call "/policies/lockout" "${EVIDENCE_DIR}/a9-access-control/a9.4.2-lockout-policy.json"

# A.9.4.3 - Password management
api_call "/policies/password" "${EVIDENCE_DIR}/a9-access-control/a9.4.3-password-policy.json"

# A.10 Cryptography
log "Collecting A.10 - Cryptography evidence..."

# A.10.1.1 - Cryptographic controls
api_call "/system/config/tls" "${EVIDENCE_DIR}/a10-cryptography/a10.1.1-tls-config.json"
api_call "/certificates" "${EVIDENCE_DIR}/a10-cryptography/a10.1.2-certificates.json"

# A.12 Operations Security
log "Collecting A.12 - Operations Security evidence..."

# A.12.4.1 - Event logging
api_call "/audit/logs?start_date=${PERIOD_START}&end_date=${PERIOD_END}&per_page=100" \
    "${EVIDENCE_DIR}/a12-operations/a12.4.1-audit-log-sample.json"
api_call "/config/logging" "${EVIDENCE_DIR}/a12-operations/a12.4.1-logging-config.json"

# A.12.4.3 - Administrator logs
api_call "/audit/logs?event_type=admin&start_date=${PERIOD_START}&end_date=${PERIOD_END}" \
    "${EVIDENCE_DIR}/a12-operations/a12.4.3-admin-actions.json"

# A.12.4.4 - Clock sync
api_call "/system/ntp" "${EVIDENCE_DIR}/a12-operations/a12.4.4-ntp-config.json"

# Generate checksums
find "${EVIDENCE_DIR}" -type f -name "*.json" -exec sha256sum {} \; > \
    "${EVIDENCE_DIR}/checksums.sha256"

log "ISO 27001 evidence collection complete: ${EVIDENCE_DIR}"
```

---

## PCI-DSS Evidence

### Requirement Mapping

```
+==============================================================================+
|                   PCI-DSS REQUIREMENT MAPPING                                |
+==============================================================================+

  REQUIREMENT 7: RESTRICT ACCESS TO CARDHOLDER DATA
  =================================================

  +----------+----------------------------------+-----------------------------+
  | Req      | Requirement                      | WALLIX Evidence             |
  +----------+----------------------------------+-----------------------------+
  |          |                                  |                             |
  | 7.1      | Limit access to system           | - Target group configs      |
  |          | components and cardholder        | - Authorization policies    |
  |          | data to only those whose         | - CDE device inventory      |
  |          | job requires such access         |                             |
  |          |                                  |                             |
  +----------+----------------------------------+-----------------------------+
  |          |                                  |                             |
  | 7.1.1    | Define access needs for each     | - Role definitions          |
  |          | role                             | - Group-to-target mappings  |
  |          |                                  | - Least privilege analysis  |
  |          |                                  |                             |
  +----------+----------------------------------+-----------------------------+
  |          |                                  |                             |
  | 7.1.2    | Restrict access to privileged    | - Privileged user list      |
  |          | user IDs to least privileges     | - Approval workflow records |
  |          | necessary                        | - JIT access configuration  |
  |          |                                  |                             |
  +----------+----------------------------------+-----------------------------+
  |          |                                  |                             |
  | 7.2      | Establish an access control      | - WALLIX PAM deployment     |
  |          | system(s) for systems            | - Centralized access logs   |
  |          | components                       | - Policy enforcement        |
  |          |                                  |                             |
  +----------+----------------------------------+-----------------------------+

  REQUIREMENT 8: IDENTIFY USERS AND AUTHENTICATE ACCESS
  =====================================================

  +----------+----------------------------------+-----------------------------+
  | Req      | Requirement                      | WALLIX Evidence             |
  +----------+----------------------------------+-----------------------------+
  |          |                                  |                             |
  | 8.1      | Define and implement policies    | - User account inventory    |
  |          | to ensure proper user            | - Unique ID enforcement     |
  |          | identification management        | - Account naming policy     |
  |          |                                  |                             |
  +----------+----------------------------------+-----------------------------+
  |          |                                  |                             |
  | 8.1.5    | Manage IDs used by third         | - Vendor account list       |
  |          | parties                          | - Time-limited access logs  |
  |          |                                  | - Vendor session recordings |
  |          |                                  |                             |
  +----------+----------------------------------+-----------------------------+
  |          |                                  |                             |
  | 8.2      | Ensure proper user               | - MFA configuration         |
  |          | authentication management        | - Password policy settings  |
  |          |                                  | - Authentication logs       |
  |          |                                  |                             |
  +----------+----------------------------------+-----------------------------+
  |          |                                  |                             |
  | 8.2.3    | Passwords/passphrases must       | - Password complexity rules |
  |          | meet minimum complexity          | - Policy configuration      |
  |          |                                  |                             |
  +----------+----------------------------------+-----------------------------+
  |          |                                  |                             |
  | 8.2.4    | Change user passwords at         | - Rotation schedule config  |
  |          | least once every 90 days         | - Rotation history logs     |
  |          |                                  |                             |
  +----------+----------------------------------+-----------------------------+
  |          |                                  |                             |
  | 8.5      | Do not use group, shared,        | - Individual account policy |
  |          | or generic IDs                   | - Credential injection      |
  |          |                                  | - No shared account access  |
  |          |                                  |                             |
  +----------+----------------------------------+-----------------------------+

  REQUIREMENT 10: TRACK AND MONITOR ALL ACCESS
  ============================================

  +----------+----------------------------------+-----------------------------+
  | Req      | Requirement                      | WALLIX Evidence             |
  +----------+----------------------------------+-----------------------------+
  |          |                                  |                             |
  | 10.1     | Implement audit trails to        | - Session recording config  |
  |          | link all access to system        | - Audit log configuration   |
  |          | components to each               | - User attribution logs     |
  |          | individual user                  |                             |
  |          |                                  |                             |
  +----------+----------------------------------+-----------------------------+
  |          |                                  |                             |
  | 10.2     | Implement automated audit        | - Automatic session logging |
  |          | trails                           | - Real-time audit capture   |
  |          |                                  | - Event correlation         |
  |          |                                  |                             |
  +----------+----------------------------------+-----------------------------+
  |          |                                  |                             |
  | 10.2.1   | All individual user accesses     | - Session logs per user     |
  |          | to cardholder data               | - CDE access reports        |
  |          |                                  | - Data access attribution   |
  |          |                                  |                             |
  +----------+----------------------------------+-----------------------------+
  |          |                                  |                             |
  | 10.2.2   | All actions taken by any         | - Admin session recordings  |
  |          | individual with root or          | - Privileged command logs   |
  |          | administrative privileges        | - Keystroke capture         |
  |          |                                  |                             |
  +----------+----------------------------------+-----------------------------+
  |          |                                  |                             |
  | 10.2.4   | Invalid logical access           | - Failed auth logs          |
  |          | attempts                         | - Account lockout events    |
  |          |                                  | - Brute force detection     |
  |          |                                  |                             |
  +----------+----------------------------------+-----------------------------+
  |          |                                  |                             |
  | 10.3     | Record audit trail entries       | - Timestamp, user, action   |
  |          | for all system components        | - Source IP, target system  |
  |          |                                  | - Success/failure status    |
  |          |                                  |                             |
  +----------+----------------------------------+-----------------------------+
  |          |                                  |                             |
  | 10.5     | Secure audit trails so they      | - Tamper-evident logging    |
  |          | cannot be altered                | - Log integrity verification|
  |          |                                  | - Access control on logs    |
  |          |                                  |                             |
  +----------+----------------------------------+-----------------------------+
  |          |                                  |                             |
  | 10.7     | Retain audit trail history       | - 1 year online retention   |
  |          | for at least one year            | - Archive configuration     |
  |          |                                  | - Backup verification       |
  |          |                                  |                             |
  +----------+----------------------------------+-----------------------------+

+==============================================================================+
```

### PCI-DSS Evidence Collection

```bash
#!/bin/bash
# /opt/wallix/scripts/collect-pci-evidence.sh
# PCI-DSS Evidence Collection Script

set -euo pipefail

WALLIX_HOST="${WALLIX_HOST:-localhost}"
API_TOKEN="${WALLIX_API_TOKEN}"
EVIDENCE_BASE="/evidence/pci-dss"
QUARTER=$(date +%Y-Q$(( ($(date +%-m) - 1) / 3 + 1 )))
PERIOD_START=$(date -d "3 months ago" +%Y-%m-%d)
PERIOD_END=$(date +%Y-%m-%d)

EVIDENCE_DIR="${EVIDENCE_BASE}/${QUARTER}"
mkdir -p "${EVIDENCE_DIR}"/{req7-access-control,req8-authentication,req10-audit}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

api_call() {
    local endpoint="$1"
    local output="$2"
    curl -s -H "Authorization: Bearer ${API_TOKEN}" \
         -H "Accept: application/json" \
         "https://${WALLIX_HOST}/api/v2${endpoint}" > "${output}"
}

log "Starting PCI-DSS evidence collection for ${QUARTER}"

# Requirement 7 - Access Control
log "Collecting Requirement 7 - Access Control..."

# 7.1 - CDE access restrictions
api_call "/authorizations?target_group=cde_systems" \
    "${EVIDENCE_DIR}/req7-access-control/7.1-cde-authorizations.json"
api_call "/devices?domain=cde" \
    "${EVIDENCE_DIR}/req7-access-control/7.1-cde-devices.json"

# 7.1.1 - Role definitions
api_call "/groups" "${EVIDENCE_DIR}/req7-access-control/7.1.1-role-definitions.json"
api_call "/authorizations" "${EVIDENCE_DIR}/req7-access-control/7.1.1-access-mappings.json"

# 7.1.2 - Privileged access
api_call "/users?role=admin" "${EVIDENCE_DIR}/req7-access-control/7.1.2-privileged-users.json"
api_call "/approvals?start_date=${PERIOD_START}&end_date=${PERIOD_END}" \
    "${EVIDENCE_DIR}/req7-access-control/7.1.2-approval-records.json"

# Requirement 8 - Authentication
log "Collecting Requirement 8 - Authentication..."

# 8.1 - User identification
api_call "/users" "${EVIDENCE_DIR}/req8-authentication/8.1-user-inventory.json"

# 8.1.5 - Third-party access
api_call "/users?type=vendor" "${EVIDENCE_DIR}/req8-authentication/8.1.5-vendor-accounts.json"
api_call "/sessions?user_type=vendor&start_date=${PERIOD_START}&end_date=${PERIOD_END}" \
    "${EVIDENCE_DIR}/req8-authentication/8.1.5-vendor-sessions.json"

# 8.2 - Authentication
api_call "/config/mfa" "${EVIDENCE_DIR}/req8-authentication/8.2-mfa-config.json"
api_call "/audit/logs?event_type=auth&start_date=${PERIOD_START}&end_date=${PERIOD_END}&per_page=1000" \
    "${EVIDENCE_DIR}/req8-authentication/8.2-auth-logs.json"

# 8.2.3 - Password complexity
api_call "/policies/password" "${EVIDENCE_DIR}/req8-authentication/8.2.3-password-policy.json"

# 8.2.4 - Password rotation
api_call "/passwords/rotation-jobs?start_date=${PERIOD_START}&end_date=${PERIOD_END}" \
    "${EVIDENCE_DIR}/req8-authentication/8.2.4-rotation-history.json"

# Requirement 10 - Audit
log "Collecting Requirement 10 - Audit..."

# 10.1 - Audit trails
api_call "/sessions?start_date=${PERIOD_START}&end_date=${PERIOD_END}&per_page=1000" \
    "${EVIDENCE_DIR}/req10-audit/10.1-session-audit.json"

# 10.2.1 - CHD access
api_call "/sessions?target_group=cde_systems&start_date=${PERIOD_START}&end_date=${PERIOD_END}" \
    "${EVIDENCE_DIR}/req10-audit/10.2.1-cde-access.json"

# 10.2.2 - Admin actions
api_call "/audit/logs?event_type=admin&start_date=${PERIOD_START}&end_date=${PERIOD_END}" \
    "${EVIDENCE_DIR}/req10-audit/10.2.2-admin-actions.json"

# 10.2.4 - Failed access
api_call "/audit/logs?event_type=auth.failure&start_date=${PERIOD_START}&end_date=${PERIOD_END}" \
    "${EVIDENCE_DIR}/req10-audit/10.2.4-failed-access.json"

# 10.5 - Log integrity
api_call "/config/logging" "${EVIDENCE_DIR}/req10-audit/10.5-log-config.json"

# Generate checksums
find "${EVIDENCE_DIR}" -type f -name "*.json" -exec sha256sum {} \; > \
    "${EVIDENCE_DIR}/checksums.sha256"

log "PCI-DSS evidence collection complete: ${EVIDENCE_DIR}"
```

---

## HIPAA Evidence

### Technical Safeguard Mapping

```
+==============================================================================+
|                   HIPAA TECHNICAL SAFEGUARDS MAPPING                         |
+==============================================================================+

  164.312 - TECHNICAL SAFEGUARDS
  ==============================

  +----------------+-----------------------------+-----------------------------+
  | Standard       | Implementation Spec         | WALLIX Evidence             |
  +----------------+-----------------------------+-----------------------------+
  |                |                             |                             |
  | (a)(1)         | Access Control              | - Authorization policies    |
  |                | Implement technical         | - PHI system access rules   |
  |                | policies for electronic     | - Role-based configurations |
  |                | information systems         |                             |
  |                |                             |                             |
  +----------------+-----------------------------+-----------------------------+
  |                |                             |                             |
  | (a)(2)(i)      | Unique User Identification  | - Individual user accounts  |
  |                | Assign unique name/number   | - No shared credentials     |
  |                | for tracking user identity  | - User attribution logs     |
  |                |                             |                             |
  +----------------+-----------------------------+-----------------------------+
  |                |                             |                             |
  | (a)(2)(ii)     | Emergency Access Procedure  | - Break-glass configuration |
  |                | Establish procedures for    | - Emergency access logs     |
  |                | obtaining ePHI during       | - Post-access review        |
  |                | emergency                   |                             |
  |                |                             |                             |
  +----------------+-----------------------------+-----------------------------+
  |                |                             |                             |
  | (a)(2)(iii)    | Automatic Logoff            | - Session timeout settings  |
  |                | Implement procedures that   | - Idle disconnect config    |
  |                | terminate session after     | - Timeout enforcement logs  |
  |                | inactivity                  |                             |
  |                |                             |                             |
  +----------------+-----------------------------+-----------------------------+
  |                |                             |                             |
  | (a)(2)(iv)     | Encryption and Decryption   | - TLS configuration         |
  |                | Implement mechanism to      | - Vault encryption settings |
  |                | encrypt and decrypt ePHI    | - At-rest encryption        |
  |                |                             |                             |
  +----------------+-----------------------------+-----------------------------+
  |                |                             |                             |
  | (b)            | Audit Controls              | - Session recording config  |
  |                | Implement hardware,         | - Audit log settings        |
  |                | software, and/or procedures | - SIEM integration          |
  |                | to record and examine       | - Log retention policy      |
  |                | activity                    |                             |
  |                |                             |                             |
  +----------------+-----------------------------+-----------------------------+
  |                |                             |                             |
  | (c)(1)         | Mechanism to Authenticate   | - Hash verification         |
  |                | ePHI                        | - Integrity checksums       |
  |                | Implement mechanisms to     | - Tamper-evident logs       |
  |                | corroborate ePHI has not    |                             |
  |                | been altered or destroyed   |                             |
  |                |                             |                             |
  +----------------+-----------------------------+-----------------------------+
  |                |                             |                             |
  | (d)            | Person or Entity            | - MFA configuration         |
  |                | Authentication              | - Authentication methods    |
  |                | Implement procedures to     | - Identity verification     |
  |                | verify identity of person   |                             |
  |                | or entity seeking access    |                             |
  |                |                             |                             |
  +----------------+-----------------------------+-----------------------------+
  |                |                             |                             |
  | (e)(1)         | Transmission Security       | - TLS 1.2/1.3 enforcement   |
  |                | Implement security measures | - Cipher suite config       |
  |                | to guard against            | - Certificate management    |
  |                | unauthorized access during  |                             |
  |                | transmission                |                             |
  |                |                             |                             |
  +----------------+-----------------------------+-----------------------------+

+==============================================================================+
```

### HIPAA Evidence Collection

```bash
#!/bin/bash
# /opt/wallix/scripts/collect-hipaa-evidence.sh
# HIPAA Evidence Collection Script

set -euo pipefail

WALLIX_HOST="${WALLIX_HOST:-localhost}"
API_TOKEN="${WALLIX_API_TOKEN}"
EVIDENCE_BASE="/evidence/hipaa"
QUARTER=$(date +%Y-Q$(( ($(date +%-m) - 1) / 3 + 1 )))
PERIOD_START=$(date -d "3 months ago" +%Y-%m-%d)
PERIOD_END=$(date +%Y-%m-%d)

EVIDENCE_DIR="${EVIDENCE_BASE}/${QUARTER}"
mkdir -p "${EVIDENCE_DIR}"/{access-control,audit-controls,integrity,authentication,transmission}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

api_call() {
    local endpoint="$1"
    local output="$2"
    curl -s -H "Authorization: Bearer ${API_TOKEN}" \
         -H "Accept: application/json" \
         "https://${WALLIX_HOST}/api/v2${endpoint}" > "${output}"
}

log "Starting HIPAA evidence collection for ${QUARTER}"

# 164.312(a) - Access Control
log "Collecting Access Control evidence..."

# PHI system authorizations
api_call "/authorizations?target_group=phi_systems" \
    "${EVIDENCE_DIR}/access-control/312a-phi-authorizations.json"
api_call "/devices?domain=phi" \
    "${EVIDENCE_DIR}/access-control/312a-phi-devices.json"

# Unique user identification
api_call "/users" "${EVIDENCE_DIR}/access-control/312a2i-user-inventory.json"

# Emergency access
api_call "/audit/logs?event_type=emergency_access&start_date=${PERIOD_START}&end_date=${PERIOD_END}" \
    "${EVIDENCE_DIR}/access-control/312a2ii-emergency-access.json"

# Automatic logoff
api_call "/policies/session" "${EVIDENCE_DIR}/access-control/312a2iii-session-timeout.json"

# Encryption
api_call "/system/config/encryption" "${EVIDENCE_DIR}/access-control/312a2iv-encryption.json"

# 164.312(b) - Audit Controls
log "Collecting Audit Controls evidence..."

api_call "/sessions?target_group=phi_systems&start_date=${PERIOD_START}&end_date=${PERIOD_END}" \
    "${EVIDENCE_DIR}/audit-controls/312b-phi-sessions.json"
api_call "/config/logging" "${EVIDENCE_DIR}/audit-controls/312b-logging-config.json"
api_call "/config/retention" "${EVIDENCE_DIR}/audit-controls/312b-retention-policy.json"

# 164.312(c) - Integrity
log "Collecting Integrity evidence..."

api_call "/config/integrity" "${EVIDENCE_DIR}/integrity/312c-integrity-config.json"

# 164.312(d) - Authentication
log "Collecting Authentication evidence..."

api_call "/config/mfa" "${EVIDENCE_DIR}/authentication/312d-mfa-config.json"
api_call "/audit/logs?event_type=auth&target_group=phi_systems&start_date=${PERIOD_START}&end_date=${PERIOD_END}" \
    "${EVIDENCE_DIR}/authentication/312d-auth-logs.json"

# 164.312(e) - Transmission Security
log "Collecting Transmission Security evidence..."

api_call "/system/config/tls" "${EVIDENCE_DIR}/transmission/312e-tls-config.json"
api_call "/certificates" "${EVIDENCE_DIR}/transmission/312e-certificates.json"

# Generate checksums
find "${EVIDENCE_DIR}" -type f -name "*.json" -exec sha256sum {} \; > \
    "${EVIDENCE_DIR}/checksums.sha256"

log "HIPAA evidence collection complete: ${EVIDENCE_DIR}"
```

---

## GDPR Evidence

### Data Access and Rights Mapping

```
+==============================================================================+
|                   GDPR ARTICLE MAPPING                                       |
+==============================================================================+

  ARTICLE 25 - DATA PROTECTION BY DESIGN
  =======================================

  +----------+--------------------------------+------------------------------+
  | Clause   | Requirement                    | WALLIX Evidence              |
  +----------+--------------------------------+------------------------------+
  |          |                                |                              |
  | 25(1)    | Implement appropriate          | - Access control policies    |
  |          | technical and organizational   | - Data minimization config   |
  |          | measures                       | - Privacy-by-design features |
  |          |                                |                              |
  +----------+--------------------------------+------------------------------+
  |          |                                |                              |
  | 25(2)    | Implement measures to ensure   | - Default deny settings      |
  |          | only necessary personal data   | - Explicit authorization     |
  |          | is processed                   | - Minimal data exposure      |
  |          |                                |                              |
  +----------+--------------------------------+------------------------------+

  ARTICLE 30 - RECORDS OF PROCESSING
  ===================================

  +----------+--------------------------------+------------------------------+
  | Clause   | Requirement                    | WALLIX Evidence              |
  +----------+--------------------------------+------------------------------+
  |          |                                |                              |
  | 30(1)    | Maintain record of processing  | - Access log exports         |
  |          | activities                     | - Session metadata           |
  |          |                                | - Data access reports        |
  |          |                                |                              |
  +----------+--------------------------------+------------------------------+

  ARTICLE 32 - SECURITY OF PROCESSING
  ====================================

  +----------+--------------------------------+------------------------------+
  | Clause   | Requirement                    | WALLIX Evidence              |
  +----------+--------------------------------+------------------------------+
  |          |                                |                              |
  | 32(1)(a) | Pseudonymisation and           | - Credential injection       |
  |          | encryption of personal data    | - Vault encryption config    |
  |          |                                | - TLS configuration          |
  |          |                                |                              |
  +----------+--------------------------------+------------------------------+
  |          |                                |                              |
  | 32(1)(b) | Ensure confidentiality,        | - Access control policies    |
  |          | integrity, availability        | - HA configuration           |
  |          | of systems                     | - Backup procedures          |
  |          |                                |                              |
  +----------+--------------------------------+------------------------------+
  |          |                                |                              |
  | 32(1)(c) | Restore availability and       | - DR procedures              |
  |          | access to personal data        | - Backup restore tests       |
  |          | in timely manner               | - RTO/RPO documentation      |
  |          |                                |                              |
  +----------+--------------------------------+------------------------------+
  |          |                                |                              |
  | 32(1)(d) | Regular testing and            | - Backup verification logs   |
  |          | evaluation of security         | - DR test results            |
  |          | measures                       | - Security assessments       |
  |          |                                |                              |
  +----------+--------------------------------+------------------------------+

  ARTICLE 15 - RIGHT OF ACCESS
  ============================

  +----------+--------------------------------+------------------------------+
  | Clause   | Requirement                    | WALLIX Evidence              |
  +----------+--------------------------------+------------------------------+
  |          |                                |                              |
  | 15(1)    | Data subject right to obtain   | - User activity export       |
  |          | confirmation and access to     | - Session metadata export    |
  |          | personal data                  | - DSAR fulfillment process   |
  |          |                                |                              |
  +----------+--------------------------------+------------------------------+

  ARTICLE 17 - RIGHT TO ERASURE
  =============================

  +----------+--------------------------------+------------------------------+
  | Clause   | Requirement                    | WALLIX Evidence              |
  +----------+--------------------------------+------------------------------+
  |          |                                |                              |
  | 17(1)    | Data subject right to          | - Data deletion procedures   |
  |          | erasure ("right to be          | - Retention policy config    |
  |          | forgotten")                    | - Deletion confirmation logs |
  |          |                                |                              |
  +----------+--------------------------------+------------------------------+

+==============================================================================+
```

### GDPR Evidence Collection and DSAR Support

```bash
#!/bin/bash
# /opt/wallix/scripts/collect-gdpr-evidence.sh
# GDPR Evidence Collection Script

set -euo pipefail

WALLIX_HOST="${WALLIX_HOST:-localhost}"
API_TOKEN="${WALLIX_API_TOKEN}"
EVIDENCE_BASE="/evidence/gdpr"
QUARTER=$(date +%Y-Q$(( ($(date +%-m) - 1) / 3 + 1 )))
PERIOD_START=$(date -d "3 months ago" +%Y-%m-%d)
PERIOD_END=$(date +%Y-%m-%d)

EVIDENCE_DIR="${EVIDENCE_BASE}/${QUARTER}"
mkdir -p "${EVIDENCE_DIR}"/{art25-design,art30-records,art32-security,art15-access,art17-erasure}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

api_call() {
    local endpoint="$1"
    local output="$2"
    curl -s -H "Authorization: Bearer ${API_TOKEN}" \
         -H "Accept: application/json" \
         "https://${WALLIX_HOST}/api/v2${endpoint}" > "${output}"
}

log "Starting GDPR evidence collection for ${QUARTER}"

# Article 25 - Data Protection by Design
log "Collecting Article 25 evidence..."
api_call "/authorizations" "${EVIDENCE_DIR}/art25-design/access-policies.json"
api_call "/policies" "${EVIDENCE_DIR}/art25-design/security-policies.json"

# Article 30 - Records of Processing
log "Collecting Article 30 evidence..."
api_call "/audit/logs?start_date=${PERIOD_START}&end_date=${PERIOD_END}&per_page=1000" \
    "${EVIDENCE_DIR}/art30-records/processing-records.json"
api_call "/sessions?start_date=${PERIOD_START}&end_date=${PERIOD_END}" \
    "${EVIDENCE_DIR}/art30-records/session-metadata.json"

# Article 32 - Security of Processing
log "Collecting Article 32 evidence..."
api_call "/system/config/encryption" "${EVIDENCE_DIR}/art32-security/encryption-config.json"
api_call "/system/config/tls" "${EVIDENCE_DIR}/art32-security/tls-config.json"
api_call "/system/health" "${EVIDENCE_DIR}/art32-security/availability-status.json"

# Article 15/17 - Data Subject Rights (documentation)
log "Documenting Article 15/17 procedures..."
cat > "${EVIDENCE_DIR}/art15-access/dsar-procedure.md" << 'EOF'
# Data Subject Access Request (DSAR) Procedure

## Process for Fulfilling Article 15 Requests

1. Receive DSAR request
2. Verify data subject identity
3. Export user activity data:
   ```bash
   # Export all activity for specific user
   curl -X GET "https://wallix/api/v2/audit/logs?user=<username>&start_date=<start>&end_date=<end>" \
     -H "Authorization: Bearer $TOKEN" > user-activity.json

   # Export session metadata (excluding recordings with third-party data)
   curl -X GET "https://wallix/api/v2/sessions?user=<username>&metadata_only=true" \
     -H "Authorization: Bearer $TOKEN" > session-metadata.json
   ```
4. Review and redact third-party data
5. Provide response within 30 days

## Supported Data Exports
- Authentication events
- Session metadata (not recordings)
- Authorization assignments
- Account activity logs
EOF

# Generate checksums
find "${EVIDENCE_DIR}" -type f \( -name "*.json" -o -name "*.md" \) -exec sha256sum {} \; > \
    "${EVIDENCE_DIR}/checksums.sha256"

log "GDPR evidence collection complete: ${EVIDENCE_DIR}"
```

### DSAR Fulfillment Script

```python
#!/usr/bin/env python3
"""
GDPR Data Subject Access Request (DSAR) Fulfillment Script
Exports all user data for GDPR Article 15 compliance
"""

import requests
import json
import csv
from datetime import datetime, timedelta
import argparse
import os

class DSARExporter:
    def __init__(self, host: str, token: str):
        self.base_url = f"https://{host}/api/v2"
        self.headers = {
            "Authorization": f"Bearer {token}",
            "Accept": "application/json"
        }

    def export_user_data(self, username: str, output_dir: str) -> dict:
        """Export all data for a specific user"""
        os.makedirs(output_dir, exist_ok=True)

        report = {
            "generated_at": datetime.now().isoformat(),
            "data_subject": username,
            "data_categories": []
        }

        # Export user profile
        user_data = self._get(f"/users?username={username}")
        if user_data.get("data"):
            self._save_json(f"{output_dir}/user-profile.json", user_data["data"][0])
            report["data_categories"].append("User Profile")

        # Export authentication history
        auth_logs = self._get(f"/audit/logs?user={username}&event_type=auth&per_page=10000")
        self._save_json(f"{output_dir}/authentication-history.json", auth_logs.get("data", []))
        report["data_categories"].append("Authentication History")

        # Export session metadata (not recordings - may contain third-party data)
        sessions = self._get(f"/sessions?user={username}&metadata_only=true&per_page=10000")
        self._save_json(f"{output_dir}/session-metadata.json", sessions.get("data", []))
        report["data_categories"].append("Session Metadata")

        # Export authorization assignments
        authorizations = self._get(f"/authorizations?user={username}")
        self._save_json(f"{output_dir}/access-rights.json", authorizations.get("data", []))
        report["data_categories"].append("Access Rights")

        # Export approval requests
        approvals = self._get(f"/approvals?requestor={username}&per_page=10000")
        self._save_json(f"{output_dir}/approval-requests.json", approvals.get("data", []))
        report["data_categories"].append("Approval Requests")

        # Generate summary report
        self._save_json(f"{output_dir}/dsar-report.json", report)

        return report

    def _get(self, endpoint: str) -> dict:
        response = requests.get(f"{self.base_url}{endpoint}", headers=self.headers, verify=True)
        response.raise_for_status()
        return response.json()

    def _save_json(self, path: str, data):
        with open(path, "w") as f:
            json.dump(data, f, indent=2, default=str)

def main():
    parser = argparse.ArgumentParser(description="GDPR DSAR Fulfillment")
    parser.add_argument("--host", required=True, help="WALLIX host")
    parser.add_argument("--token", required=True, help="API token")
    parser.add_argument("--username", required=True, help="Data subject username")
    parser.add_argument("--output", default="./dsar-export", help="Output directory")

    args = parser.parse_args()

    exporter = DSARExporter(args.host, args.token)
    report = exporter.export_user_data(args.username, args.output)

    print(f"DSAR export complete: {args.output}")
    print(f"Data categories exported: {', '.join(report['data_categories'])}")

if __name__ == "__main__":
    main()
```

---

## IEC 62443 Evidence

### Security Level Evidence Requirements

```
+==============================================================================+
|                   IEC 62443 SECURITY LEVEL EVIDENCE                          |
+==============================================================================+

  SECURITY LEVEL 1 (SL1) - BASIC PROTECTION
  =========================================

  +------------------------------------------------------------------------+
  | Requirement                    | Evidence Required                      |
  +--------------------------------+----------------------------------------+
  | User authentication            | - User account configuration           |
  | (username/password)            | - Authentication policy                |
  |                                |                                        |
  | Basic access control           | - Authorization policies               |
  |                                | - Target-to-user mappings              |
  |                                |                                        |
  | Session logging                | - Logging configuration                |
  |                                | - Sample audit logs                    |
  |                                |                                        |
  | Password requirements          | - Password policy settings             |
  |                                | - Complexity requirements              |
  +--------------------------------+----------------------------------------+

  SECURITY LEVEL 2 (SL2) - MODERATE PROTECTION
  ============================================

  +------------------------------------------------------------------------+
  | Requirement                    | Evidence Required                      |
  +--------------------------------+----------------------------------------+
  | All SL1 requirements           | - SL1 evidence package                 |
  |                                |                                        |
  | Session recording              | - Recording configuration              |
  |                                | - Sample recordings (metadata)         |
  |                                |                                        |
  | Role-based access control      | - RBAC configuration                   |
  |                                | - Group/role definitions               |
  |                                |                                        |
  | Account lockout                | - Lockout policy configuration         |
  |                                | - Lockout event logs                   |
  |                                |                                        |
  | Audit retention                | - Retention policy settings            |
  |                                | - Archive verification                 |
  +--------------------------------+----------------------------------------+

  SECURITY LEVEL 3 (SL3) - HIGH PROTECTION
  ========================================

  +------------------------------------------------------------------------+
  | Requirement                    | Evidence Required                      |
  +--------------------------------+----------------------------------------+
  | All SL2 requirements           | - SL2 evidence package                 |
  |                                |                                        |
  | Multi-factor authentication    | - MFA configuration                    |
  |                                | - MFA enrollment status                |
  |                                |                                        |
  | Approval workflows             | - Workflow configuration               |
  |                                | - Approval records                     |
  |                                |                                        |
  | Real-time monitoring           | - Monitoring configuration             |
  |                                | - Alert rules                          |
  |                                |                                        |
  | SIEM integration               | - SIEM configuration                   |
  |                                | - Log forwarding status                |
  |                                |                                        |
  | Encrypted storage              | - Encryption configuration             |
  |                                | - Key management policy                |
  |                                |                                        |
  | Automatic password rotation    | - Rotation schedule                    |
  |                                | - Rotation history                     |
  |                                |                                        |
  | TLS 1.2+ enforcement           | - TLS configuration                    |
  |                                | - Cipher suite settings                |
  +--------------------------------+----------------------------------------+

  SECURITY LEVEL 4 (SL4) - MAXIMUM PROTECTION
  ===========================================

  +------------------------------------------------------------------------+
  | Requirement                    | Evidence Required                      |
  +--------------------------------+----------------------------------------+
  | All SL3 requirements           | - SL3 evidence package                 |
  |                                |                                        |
  | HSM key protection             | - HSM configuration                    |
  |                                | - Key storage verification             |
  |                                |                                        |
  | 4-eyes approval                | - Dual approval configuration          |
  |                                | - Multi-approver records               |
  |                                |                                        |
  | Continuous monitoring          | - SOC integration status               |
  |                                | - Monitoring coverage                  |
  |                                |                                        |
  | Behavioral analytics           | - Analytics configuration              |
  |                                | - Anomaly detection rules              |
  |                                |                                        |
  | Geographic separation          | - HA cluster configuration             |
  |                                | - Site documentation                   |
  |                                |                                        |
  | Tamper-evident logging         | - Log integrity configuration          |
  |                                | - Hash chain verification              |
  +--------------------------------+----------------------------------------+

+==============================================================================+
```

### Zone and Conduit Documentation

```bash
#!/bin/bash
# /opt/wallix/scripts/collect-iec62443-evidence.sh
# IEC 62443 Evidence Collection Script

set -euo pipefail

WALLIX_HOST="${WALLIX_HOST:-localhost}"
API_TOKEN="${WALLIX_API_TOKEN}"
EVIDENCE_BASE="/evidence/iec62443"
QUARTER=$(date +%Y-Q$(( ($(date +%-m) - 1) / 3 + 1 )))
PERIOD_START=$(date -d "3 months ago" +%Y-%m-%d)
PERIOD_END=$(date +%Y-%m-%d)

EVIDENCE_DIR="${EVIDENCE_BASE}/${QUARTER}"
mkdir -p "${EVIDENCE_DIR}"/{sl1-basic,sl2-moderate,sl3-high,sl4-maximum,zones-conduits}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

api_call() {
    local endpoint="$1"
    local output="$2"
    curl -s -H "Authorization: Bearer ${API_TOKEN}" \
         -H "Accept: application/json" \
         "https://${WALLIX_HOST}/api/v2${endpoint}" > "${output}"
}

log "Starting IEC 62443 evidence collection for ${QUARTER}"

# SL1 - Basic Protection
log "Collecting SL1 evidence..."
api_call "/users" "${EVIDENCE_DIR}/sl1-basic/user-accounts.json"
api_call "/policies/authentication" "${EVIDENCE_DIR}/sl1-basic/auth-policy.json"
api_call "/authorizations" "${EVIDENCE_DIR}/sl1-basic/authorizations.json"
api_call "/policies/password" "${EVIDENCE_DIR}/sl1-basic/password-policy.json"
api_call "/config/logging" "${EVIDENCE_DIR}/sl1-basic/logging-config.json"

# SL2 - Moderate Protection
log "Collecting SL2 evidence..."
api_call "/config/recording" "${EVIDENCE_DIR}/sl2-moderate/recording-config.json"
api_call "/groups" "${EVIDENCE_DIR}/sl2-moderate/rbac-groups.json"
api_call "/policies/lockout" "${EVIDENCE_DIR}/sl2-moderate/lockout-policy.json"
api_call "/config/retention" "${EVIDENCE_DIR}/sl2-moderate/retention-policy.json"

# SL3 - High Protection
log "Collecting SL3 evidence..."
api_call "/config/mfa" "${EVIDENCE_DIR}/sl3-high/mfa-config.json"
api_call "/users?mfa_enabled=true" "${EVIDENCE_DIR}/sl3-high/mfa-enrollment.json"
api_call "/config/approval" "${EVIDENCE_DIR}/sl3-high/approval-workflow.json"
api_call "/approvals?start_date=${PERIOD_START}&end_date=${PERIOD_END}" \
    "${EVIDENCE_DIR}/sl3-high/approval-records.json"
api_call "/config/monitoring" "${EVIDENCE_DIR}/sl3-high/monitoring-config.json"
api_call "/config/siem" "${EVIDENCE_DIR}/sl3-high/siem-integration.json"
api_call "/system/config/encryption" "${EVIDENCE_DIR}/sl3-high/encryption-config.json"
api_call "/system/config/tls" "${EVIDENCE_DIR}/sl3-high/tls-config.json"
api_call "/passwords/rotation-jobs?start_date=${PERIOD_START}&end_date=${PERIOD_END}" \
    "${EVIDENCE_DIR}/sl3-high/rotation-history.json"

# SL4 - Maximum Protection
log "Collecting SL4 evidence..."
api_call "/config/hsm" "${EVIDENCE_DIR}/sl4-maximum/hsm-config.json" 2>/dev/null || echo '{"status": "not_configured"}' > "${EVIDENCE_DIR}/sl4-maximum/hsm-config.json"
api_call "/config/dual-approval" "${EVIDENCE_DIR}/sl4-maximum/dual-approval.json" 2>/dev/null || echo '{"status": "not_configured"}' > "${EVIDENCE_DIR}/sl4-maximum/dual-approval.json"
api_call "/system/cluster" "${EVIDENCE_DIR}/sl4-maximum/cluster-config.json"
api_call "/config/log-integrity" "${EVIDENCE_DIR}/sl4-maximum/log-integrity.json"

# Zone and Conduit Documentation
log "Collecting zone/conduit documentation..."
api_call "/domains" "${EVIDENCE_DIR}/zones-conduits/domains.json"
api_call "/devices?with_zones=true" "${EVIDENCE_DIR}/zones-conduits/device-zones.json"

# Generate zone documentation
cat > "${EVIDENCE_DIR}/zones-conduits/zone-mapping.md" << 'EOF'
# IEC 62443 Zone and Conduit Mapping

## Zone Definitions

| Zone ID | Zone Name | Security Level | Description |
|---------|-----------|----------------|-------------|
| Zone 0  | Safety    | SL 4           | Safety instrumented systems |
| Zone 1  | Control   | SL 3           | PLCs, RTUs, DCS controllers |
| Zone 2  | Process   | SL 3           | HMIs, SCADA servers |
| Zone 3  | Operations| SL 2           | Historian, MES |
| Zone 4  | Enterprise| SL 2           | Business systems, IT |
| Zone 5  | External  | SL 1           | DMZ, remote access |

## Conduit Mapping

| Conduit | From Zone | To Zone | WALLIX Role | Security Level |
|---------|-----------|---------|-------------|----------------|
| C1      | Zone 5    | Zone 4  | External access proxy | SL 2 |
| C2      | Zone 4    | Zone 3  | IT-OT gateway | SL 2 |
| C3      | Zone 3    | Zone 2  | Operations access | SL 3 |
| C4      | Zone 2    | Zone 1  | Engineering access | SL 3 |
| C5      | Zone 1    | Zone 0  | Safety system access | SL 4 |

## WALLIX Deployment

WALLIX Bastion is deployed as the conduit security control between zones,
enforcing access policies, session recording, and credential management.
EOF

# Generate checksums
find "${EVIDENCE_DIR}" -type f \( -name "*.json" -o -name "*.md" \) -exec sha256sum {} \; > \
    "${EVIDENCE_DIR}/checksums.sha256"

log "IEC 62443 evidence collection complete: ${EVIDENCE_DIR}"
```

---

## Automated Evidence Collection

### Master Collection Script

```bash
#!/bin/bash
# /opt/wallix/scripts/collect-all-evidence.sh
# Master Evidence Collection Script - All Frameworks

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WALLIX_HOST="${WALLIX_HOST:-localhost}"
API_TOKEN="${WALLIX_API_TOKEN:-}"
EVIDENCE_BASE="${EVIDENCE_BASE:-/evidence}"
LOG_FILE="/var/log/wallix/evidence-collection.log"

# Ensure token is set
if [[ -z "${API_TOKEN}" ]]; then
    echo "ERROR: WALLIX_API_TOKEN environment variable not set"
    exit 1
fi

log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$msg"
    echo "$msg" >> "${LOG_FILE}"
}

run_collection() {
    local script="$1"
    local framework="$2"

    log "Starting ${framework} evidence collection..."

    if [[ -x "${SCRIPT_DIR}/${script}" ]]; then
        if "${SCRIPT_DIR}/${script}" >> "${LOG_FILE}" 2>&1; then
            log "${framework} evidence collection completed successfully"
            return 0
        else
            log "ERROR: ${framework} evidence collection failed"
            return 1
        fi
    else
        log "WARNING: ${script} not found or not executable"
        return 1
    fi
}

# Create log directory
mkdir -p "$(dirname "${LOG_FILE}")"

log "=========================================="
log "Starting Master Evidence Collection"
log "Host: ${WALLIX_HOST}"
log "Evidence Base: ${EVIDENCE_BASE}"
log "=========================================="

# Track results
declare -A RESULTS

# Run all framework collections
run_collection "collect-soc2-evidence.sh" "SOC 2" && RESULTS["SOC2"]="SUCCESS" || RESULTS["SOC2"]="FAILED"
run_collection "collect-iso27001-evidence.sh" "ISO 27001" && RESULTS["ISO27001"]="SUCCESS" || RESULTS["ISO27001"]="FAILED"
run_collection "collect-pci-evidence.sh" "PCI-DSS" && RESULTS["PCI-DSS"]="SUCCESS" || RESULTS["PCI-DSS"]="FAILED"
run_collection "collect-hipaa-evidence.sh" "HIPAA" && RESULTS["HIPAA"]="SUCCESS" || RESULTS["HIPAA"]="FAILED"
run_collection "collect-gdpr-evidence.sh" "GDPR" && RESULTS["GDPR"]="SUCCESS" || RESULTS["GDPR"]="FAILED"
run_collection "collect-iec62443-evidence.sh" "IEC 62443" && RESULTS["IEC62443"]="SUCCESS" || RESULTS["IEC62443"]="FAILED"

# Generate master summary
SUMMARY_DIR="${EVIDENCE_BASE}/master/$(date +%Y-%m)"
mkdir -p "${SUMMARY_DIR}"

cat > "${SUMMARY_DIR}/collection-summary.json" << EOF
{
  "collection_date": "$(date -Iseconds)",
  "host": "${WALLIX_HOST}",
  "frameworks": {
    "soc2": "${RESULTS["SOC2"]:-SKIPPED}",
    "iso27001": "${RESULTS["ISO27001"]:-SKIPPED}",
    "pci_dss": "${RESULTS["PCI-DSS"]:-SKIPPED}",
    "hipaa": "${RESULTS["HIPAA"]:-SKIPPED}",
    "gdpr": "${RESULTS["GDPR"]:-SKIPPED}",
    "iec62443": "${RESULTS["IEC62443"]:-SKIPPED}"
  }
}
EOF

log "=========================================="
log "Evidence Collection Complete"
log "Summary: ${SUMMARY_DIR}/collection-summary.json"
log "=========================================="

# Print results
for framework in "${!RESULTS[@]}"; do
    log "${framework}: ${RESULTS[$framework]}"
done
```

### Scheduled Collection (systemd)

```ini
# /etc/systemd/system/wallix-evidence-collection.service
[Unit]
Description=WALLIX Compliance Evidence Collection
After=network.target wallix-bastion.service

[Service]
Type=oneshot
User=wallix
Group=wallix
Environment=WALLIX_HOST=localhost
EnvironmentFile=/etc/wallix/evidence-collection.env
ExecStart=/opt/wallix/scripts/collect-all-evidence.sh
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

```ini
# /etc/systemd/system/wallix-evidence-collection.timer
[Unit]
Description=Weekly WALLIX Evidence Collection

[Timer]
OnCalendar=Sun 02:00:00
Persistent=true
RandomizedDelaySec=1800

[Install]
WantedBy=timers.target
```

```bash
# /etc/wallix/evidence-collection.env
WALLIX_API_TOKEN=your-api-token-here
EVIDENCE_BASE=/evidence
```

### Cron Alternative

```bash
# /etc/cron.d/wallix-evidence-collection
# Weekly evidence collection - Sunday at 2:00 AM
0 2 * * 0 wallix WALLIX_HOST=localhost WALLIX_API_TOKEN=your-token /opt/wallix/scripts/collect-all-evidence.sh >> /var/log/wallix/evidence-cron.log 2>&1

# Monthly archive - 1st of month at 3:00 AM
0 3 1 * * wallix /opt/wallix/scripts/archive-evidence.sh >> /var/log/wallix/evidence-archive.log 2>&1
```

### Evidence Retention and Archival

```bash
#!/bin/bash
# /opt/wallix/scripts/archive-evidence.sh
# Evidence Archival Script

set -euo pipefail

EVIDENCE_BASE="${EVIDENCE_BASE:-/evidence}"
ARCHIVE_DIR="${ARCHIVE_DIR:-/archive/compliance}"
RETENTION_MONTHS="${RETENTION_MONTHS:-36}"  # 3 years default

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Create archive directory
mkdir -p "${ARCHIVE_DIR}"

# Archive old evidence
log "Archiving evidence older than ${RETENTION_MONTHS} months..."

find "${EVIDENCE_BASE}" -maxdepth 2 -type d -name "20*-Q*" -mtime +$((RETENTION_MONTHS * 30)) | while read -r dir; do
    archive_name="$(basename "$(dirname "$dir")")-$(basename "$dir").tar.gz"
    log "Archiving: ${dir} -> ${ARCHIVE_DIR}/${archive_name}"

    # Create compressed archive
    tar -czf "${ARCHIVE_DIR}/${archive_name}" -C "$(dirname "$dir")" "$(basename "$dir")"

    # Verify archive
    if tar -tzf "${ARCHIVE_DIR}/${archive_name}" > /dev/null 2>&1; then
        log "Archive verified, removing original: ${dir}"
        rm -rf "$dir"
    else
        log "ERROR: Archive verification failed for ${archive_name}"
    fi
done

# Generate archive inventory
log "Generating archive inventory..."
find "${ARCHIVE_DIR}" -name "*.tar.gz" -exec ls -lh {} \; > "${ARCHIVE_DIR}/inventory.txt"

log "Archival complete"
```

---

## API-Based Evidence Extraction

### Python Evidence Collection Library

```python
#!/usr/bin/env python3
"""
WALLIX Compliance Evidence Collection Library
Provides programmatic access to evidence collection for all frameworks
"""

import requests
import json
import os
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any
from dataclasses import dataclass
from enum import Enum
import hashlib

class Framework(Enum):
    SOC2 = "soc2"
    ISO27001 = "iso27001"
    PCI_DSS = "pci-dss"
    HIPAA = "hipaa"
    GDPR = "gdpr"
    IEC62443 = "iec62443"

@dataclass
class EvidenceConfig:
    host: str
    token: str
    base_dir: str = "/evidence"
    verify_ssl: bool = True

class WALLIXEvidenceCollector:
    """Comprehensive evidence collection for compliance frameworks"""

    def __init__(self, config: EvidenceConfig):
        self.config = config
        self.base_url = f"https://{config.host}/api/v2"
        self.headers = {
            "Authorization": f"Bearer {config.token}",
            "Accept": "application/json"
        }
        self.session = requests.Session()
        self.session.headers.update(self.headers)
        self.session.verify = config.verify_ssl

    def collect_framework(self,
                          framework: Framework,
                          start_date: datetime,
                          end_date: datetime) -> Dict[str, Any]:
        """Collect evidence for a specific framework"""

        collectors = {
            Framework.SOC2: self._collect_soc2,
            Framework.ISO27001: self._collect_iso27001,
            Framework.PCI_DSS: self._collect_pci_dss,
            Framework.HIPAA: self._collect_hipaa,
            Framework.GDPR: self._collect_gdpr,
            Framework.IEC62443: self._collect_iec62443,
        }

        collector = collectors.get(framework)
        if not collector:
            raise ValueError(f"Unknown framework: {framework}")

        return collector(start_date, end_date)

    def _get(self, endpoint: str, params: Optional[Dict] = None) -> Dict:
        """Make API GET request"""
        response = self.session.get(f"{self.base_url}{endpoint}", params=params)
        response.raise_for_status()
        return response.json()

    def _save_evidence(self, framework: str, category: str,
                       filename: str, data: Any) -> str:
        """Save evidence to file with checksum"""
        quarter = self._get_quarter()
        dir_path = os.path.join(self.config.base_dir, framework, quarter, category)
        os.makedirs(dir_path, exist_ok=True)

        file_path = os.path.join(dir_path, filename)
        with open(file_path, "w") as f:
            json.dump(data, f, indent=2, default=str)

        # Generate checksum
        with open(file_path, "rb") as f:
            checksum = hashlib.sha256(f.read()).hexdigest()

        return file_path

    def _get_quarter(self) -> str:
        """Get current quarter string"""
        now = datetime.now()
        quarter = (now.month - 1) // 3 + 1
        return f"{now.year}-Q{quarter}"

    def _collect_soc2(self, start_date: datetime, end_date: datetime) -> Dict:
        """Collect SOC 2 Type II evidence"""
        evidence = {"framework": "SOC2", "collected_at": datetime.now().isoformat()}
        params = {"start_date": start_date.isoformat(), "end_date": end_date.isoformat()}

        # CC6.1 - Access Controls
        evidence["cc6.1"] = {
            "users": self._get("/users"),
            "groups": self._get("/groups"),
            "authorizations": self._get("/authorizations"),
            "mfa_config": self._get("/config/mfa"),
        }
        self._save_evidence("soc2", "cc6.1-access-controls", "evidence.json", evidence["cc6.1"])

        # CC6.2 - User Lifecycle
        evidence["cc6.2"] = {
            "user_creations": self._get("/audit/logs", {**params, "event_type": "user.create"}),
            "approvals": self._get("/approvals", params),
        }
        self._save_evidence("soc2", "cc6.2-user-lifecycle", "evidence.json", evidence["cc6.2"])

        # CC6.3 - Access Removal
        evidence["cc6.3"] = {
            "user_deletions": self._get("/audit/logs", {**params, "event_type": "user.delete"}),
            "revocations": self._get("/audit/logs", {**params, "event_type": "authorization.revoke"}),
        }
        self._save_evidence("soc2", "cc6.3-access-removal", "evidence.json", evidence["cc6.3"])

        # CC7.2 - Monitoring
        evidence["cc7.2"] = {
            "sessions": self._get("/sessions", {**params, "per_page": 1000}),
            "stats": self._get("/audit/stats", {**params, "group_by": "day"}),
        }
        self._save_evidence("soc2", "cc7.2-monitoring", "evidence.json", evidence["cc7.2"])

        return evidence

    def _collect_iso27001(self, start_date: datetime, end_date: datetime) -> Dict:
        """Collect ISO 27001 evidence"""
        evidence = {"framework": "ISO27001", "collected_at": datetime.now().isoformat()}
        params = {"start_date": start_date.isoformat(), "end_date": end_date.isoformat()}

        # A.9 - Access Control
        evidence["a9"] = {
            "policies": self._get("/policies"),
            "users": self._get("/users"),
            "privileged_accounts": self._get("/accounts", {"type": "privileged"}),
            "mfa_config": self._get("/config/mfa"),
            "password_policy": self._get("/policies/password"),
        }
        self._save_evidence("iso27001", "a9-access-control", "evidence.json", evidence["a9"])

        # A.10 - Cryptography
        evidence["a10"] = {
            "tls_config": self._get("/system/config/tls"),
            "certificates": self._get("/certificates"),
        }
        self._save_evidence("iso27001", "a10-cryptography", "evidence.json", evidence["a10"])

        # A.12 - Operations
        evidence["a12"] = {
            "audit_logs": self._get("/audit/logs", {**params, "per_page": 100}),
            "admin_actions": self._get("/audit/logs", {**params, "event_type": "admin"}),
        }
        self._save_evidence("iso27001", "a12-operations", "evidence.json", evidence["a12"])

        return evidence

    def _collect_pci_dss(self, start_date: datetime, end_date: datetime) -> Dict:
        """Collect PCI-DSS evidence"""
        evidence = {"framework": "PCI-DSS", "collected_at": datetime.now().isoformat()}
        params = {"start_date": start_date.isoformat(), "end_date": end_date.isoformat()}

        # Requirement 7 - Access Control
        evidence["req7"] = {
            "authorizations": self._get("/authorizations"),
            "groups": self._get("/groups"),
            "approvals": self._get("/approvals", params),
        }
        self._save_evidence("pci-dss", "req7-access-control", "evidence.json", evidence["req7"])

        # Requirement 8 - Authentication
        evidence["req8"] = {
            "users": self._get("/users"),
            "mfa_config": self._get("/config/mfa"),
            "password_policy": self._get("/policies/password"),
            "auth_logs": self._get("/audit/logs", {**params, "event_type": "auth", "per_page": 1000}),
        }
        self._save_evidence("pci-dss", "req8-authentication", "evidence.json", evidence["req8"])

        # Requirement 10 - Audit
        evidence["req10"] = {
            "sessions": self._get("/sessions", {**params, "per_page": 1000}),
            "failed_access": self._get("/audit/logs", {**params, "event_type": "auth.failure"}),
        }
        self._save_evidence("pci-dss", "req10-audit", "evidence.json", evidence["req10"])

        return evidence

    def _collect_hipaa(self, start_date: datetime, end_date: datetime) -> Dict:
        """Collect HIPAA evidence"""
        evidence = {"framework": "HIPAA", "collected_at": datetime.now().isoformat()}
        params = {"start_date": start_date.isoformat(), "end_date": end_date.isoformat()}

        # 164.312(a) - Access Control
        evidence["312a"] = {
            "authorizations": self._get("/authorizations"),
            "users": self._get("/users"),
            "session_policy": self._get("/policies/session"),
            "encryption": self._get("/system/config/encryption"),
        }
        self._save_evidence("hipaa", "access-control", "evidence.json", evidence["312a"])

        # 164.312(b) - Audit Controls
        evidence["312b"] = {
            "logging_config": self._get("/config/logging"),
            "sessions": self._get("/sessions", {**params, "per_page": 1000}),
        }
        self._save_evidence("hipaa", "audit-controls", "evidence.json", evidence["312b"])

        # 164.312(d) - Authentication
        evidence["312d"] = {
            "mfa_config": self._get("/config/mfa"),
            "auth_logs": self._get("/audit/logs", {**params, "event_type": "auth"}),
        }
        self._save_evidence("hipaa", "authentication", "evidence.json", evidence["312d"])

        return evidence

    def _collect_gdpr(self, start_date: datetime, end_date: datetime) -> Dict:
        """Collect GDPR evidence"""
        evidence = {"framework": "GDPR", "collected_at": datetime.now().isoformat()}
        params = {"start_date": start_date.isoformat(), "end_date": end_date.isoformat()}

        # Article 25 - Data Protection by Design
        evidence["art25"] = {
            "authorizations": self._get("/authorizations"),
            "policies": self._get("/policies"),
        }
        self._save_evidence("gdpr", "art25-design", "evidence.json", evidence["art25"])

        # Article 30 - Records of Processing
        evidence["art30"] = {
            "audit_logs": self._get("/audit/logs", {**params, "per_page": 1000}),
            "sessions": self._get("/sessions", {**params, "per_page": 1000}),
        }
        self._save_evidence("gdpr", "art30-records", "evidence.json", evidence["art30"])

        # Article 32 - Security of Processing
        evidence["art32"] = {
            "encryption": self._get("/system/config/encryption"),
            "tls": self._get("/system/config/tls"),
            "health": self._get("/system/health"),
        }
        self._save_evidence("gdpr", "art32-security", "evidence.json", evidence["art32"])

        return evidence

    def _collect_iec62443(self, start_date: datetime, end_date: datetime) -> Dict:
        """Collect IEC 62443 evidence"""
        evidence = {"framework": "IEC62443", "collected_at": datetime.now().isoformat()}
        params = {"start_date": start_date.isoformat(), "end_date": end_date.isoformat()}

        # SL1-4 Evidence
        evidence["security_levels"] = {
            "users": self._get("/users"),
            "auth_policy": self._get("/policies/authentication"),
            "password_policy": self._get("/policies/password"),
            "recording_config": self._get("/config/recording"),
            "mfa_config": self._get("/config/mfa"),
            "encryption": self._get("/system/config/encryption"),
            "tls": self._get("/system/config/tls"),
        }
        self._save_evidence("iec62443", "security-levels", "evidence.json", evidence["security_levels"])

        # Zone and Conduit
        evidence["zones"] = {
            "domains": self._get("/domains"),
            "devices": self._get("/devices"),
        }
        self._save_evidence("iec62443", "zones-conduits", "evidence.json", evidence["zones"])

        return evidence

    def generate_report(self, framework: Framework, evidence: Dict) -> str:
        """Generate compliance report from evidence"""
        report_path = os.path.join(
            self.config.base_dir,
            framework.value,
            self._get_quarter(),
            "compliance-report.md"
        )

        # Generate markdown report
        report = f"""# {framework.value.upper()} Compliance Evidence Report

## Report Information
- **Generated**: {datetime.now().isoformat()}
- **Framework**: {framework.value}
- **Period**: {evidence.get('period', 'N/A')}

## Evidence Summary

"""
        for category, data in evidence.items():
            if isinstance(data, dict):
                report += f"### {category}\n"
                for key, value in data.items():
                    if isinstance(value, dict) and "data" in value:
                        count = len(value["data"]) if isinstance(value["data"], list) else 1
                        report += f"- **{key}**: {count} records\n"
                report += "\n"

        os.makedirs(os.path.dirname(report_path), exist_ok=True)
        with open(report_path, "w") as f:
            f.write(report)

        return report_path

# Example usage
def main():
    config = EvidenceConfig(
        host="wallix.company.com",
        token=os.environ.get("WALLIX_API_TOKEN"),
        base_dir="/evidence"
    )

    collector = WALLIXEvidenceCollector(config)

    # Collect evidence for last quarter
    end_date = datetime.now()
    start_date = end_date - timedelta(days=90)

    for framework in Framework:
        print(f"Collecting {framework.value} evidence...")
        evidence = collector.collect_framework(framework, start_date, end_date)
        report = collector.generate_report(framework, evidence)
        print(f"Report generated: {report}")

if __name__ == "__main__":
    main()
```

---

## Audit Preparation

### Pre-Audit Checklist

```
+==============================================================================+
|                   PRE-AUDIT PREPARATION CHECKLIST                            |
+==============================================================================+

  30 DAYS BEFORE AUDIT
  ====================

  Documentation Review:
  [ ] Verify all policy documents are current and approved
  [ ] Update network diagrams to reflect current architecture
  [ ] Review and update access control policy documentation
  [ ] Ensure incident response procedures are documented
  [ ] Verify backup and recovery procedures are documented

  Evidence Collection:
  [ ] Run automated evidence collection scripts
  [ ] Verify evidence files are complete and valid
  [ ] Generate checksums for all evidence files
  [ ] Review sample session recordings for quality
  [ ] Export audit logs for full audit period

  System Verification:
  [ ] Verify WALLIX Bastion is running latest stable version
  [ ] Check all security patches are applied
  [ ] Verify HA cluster is functioning properly
  [ ] Test backup and restore procedures
  [ ] Verify SIEM integration is active

  --------------------------------------------------------------------------

  14 DAYS BEFORE AUDIT
  ====================

  Internal Review:
  [ ] Conduct internal pre-audit assessment
  [ ] Review previous audit findings and remediation
  [ ] Identify any gaps in evidence or documentation
  [ ] Prepare responses to common auditor questions
  [ ] Brief key personnel on audit process

  Access Preparation:
  [ ] Create auditor user accounts (read-only)
  [ ] Configure auditor access to evidence repository
  [ ] Set up secure file sharing for document exchange
  [ ] Prepare demo environment if needed

  --------------------------------------------------------------------------

  7 DAYS BEFORE AUDIT
  ===================

  Final Verification:
  [ ] Run final evidence collection
  [ ] Verify all evidence files are accessible
  [ ] Test auditor account access
  [ ] Prepare audit room/virtual meeting space
  [ ] Distribute audit schedule to key personnel

  Documentation Package:
  [ ] Compile evidence index with file locations
  [ ] Prepare executive summary of controls
  [ ] Create quick reference guide for auditors
  [ ] Package all documentation for delivery

  --------------------------------------------------------------------------

  DAY OF AUDIT
  ============

  [ ] Verify WALLIX systems are operational
  [ ] Confirm auditor access is working
  [ ] Have key personnel available for interviews
  [ ] Prepare demonstration of key controls
  [ ] Have backup contacts identified

+==============================================================================+
```

### Evidence Packaging Script

```bash
#!/bin/bash
# /opt/wallix/scripts/package-audit-evidence.sh
# Package evidence for auditor delivery

set -euo pipefail

EVIDENCE_BASE="${EVIDENCE_BASE:-/evidence}"
OUTPUT_DIR="${OUTPUT_DIR:-/tmp/audit-package}"
FRAMEWORK="${1:-all}"
QUARTER="${2:-$(date +%Y-Q$(( ($(date +%-m) - 1) / 3 + 1 )))}"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Packaging audit evidence for ${FRAMEWORK} - ${QUARTER}"

# Create output directory
mkdir -p "${OUTPUT_DIR}"

# Package evidence
if [[ "${FRAMEWORK}" == "all" ]]; then
    frameworks=("soc2" "iso27001" "pci-dss" "hipaa" "gdpr" "iec62443")
else
    frameworks=("${FRAMEWORK}")
fi

for fw in "${frameworks[@]}"; do
    evidence_dir="${EVIDENCE_BASE}/${fw}/${QUARTER}"

    if [[ -d "${evidence_dir}" ]]; then
        log "Packaging ${fw} evidence..."

        # Create archive
        tar -czf "${OUTPUT_DIR}/${fw}-${QUARTER}-evidence.tar.gz" \
            -C "${EVIDENCE_BASE}/${fw}" "${QUARTER}"

        # Generate manifest
        find "${evidence_dir}" -type f | while read -r file; do
            echo "$(sha256sum "$file" | cut -d' ' -f1)  ${file#${evidence_dir}/}"
        done > "${OUTPUT_DIR}/${fw}-${QUARTER}-manifest.txt"

        log "${fw} evidence packaged successfully"
    else
        log "WARNING: No evidence found for ${fw} in ${QUARTER}"
    fi
done

# Generate index
cat > "${OUTPUT_DIR}/README.txt" << EOF
WALLIX Bastion Compliance Evidence Package
===========================================

Generated: $(date '+%Y-%m-%d %H:%M:%S')
Period: ${QUARTER}
Frameworks: ${frameworks[*]}

Package Contents:
EOF

for archive in "${OUTPUT_DIR}"/*.tar.gz; do
    if [[ -f "$archive" ]]; then
        echo "- $(basename "$archive")" >> "${OUTPUT_DIR}/README.txt"
    fi
done

cat >> "${OUTPUT_DIR}/README.txt" << EOF

Verification:
Each framework package includes a manifest file with SHA-256 checksums
for all evidence files. To verify:

  tar -tzf <archive>.tar.gz
  sha256sum -c <framework>-<quarter>-manifest.txt

Contact:
For questions about this evidence package, contact your WALLIX administrator.
EOF

log "Evidence package complete: ${OUTPUT_DIR}"
log "Contents:"
ls -la "${OUTPUT_DIR}"
```

### Auditor Access Setup

```bash
#!/bin/bash
# /opt/wallix/scripts/setup-auditor-access.sh
# Create limited auditor access for compliance review

set -euo pipefail

WALLIX_HOST="${WALLIX_HOST:-localhost}"
API_TOKEN="${WALLIX_API_TOKEN}"
AUDITOR_NAME="${1:-external_auditor}"
AUDIT_END_DATE="${2:-$(date -d '+30 days' +%Y-%m-%d)}"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

api_call() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [[ -n "$data" ]]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer ${API_TOKEN}" \
            -H "Content-Type: application/json" \
            -d "$data" \
            "https://${WALLIX_HOST}/api/v2${endpoint}"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer ${API_TOKEN}" \
            "https://${WALLIX_HOST}/api/v2${endpoint}"
    fi
}

log "Creating auditor access for: ${AUDITOR_NAME}"
log "Access expires: ${AUDIT_END_DATE}"

# Create auditor group with read-only permissions
log "Creating auditor group..."
GROUP_DATA=$(cat << EOF
{
    "name": "auditors",
    "description": "External auditor read-only access",
    "permissions": ["view_users", "view_groups", "view_authorizations",
                    "view_sessions", "view_audit_logs", "view_reports"]
}
EOF
)

api_call POST "/groups" "$GROUP_DATA"

# Create auditor user
log "Creating auditor user..."
TEMP_PASSWORD=$(openssl rand -base64 16)

USER_DATA=$(cat << EOF
{
    "username": "${AUDITOR_NAME}",
    "display_name": "External Auditor",
    "email": "auditor@example.com",
    "password": "${TEMP_PASSWORD}",
    "groups": ["auditors"],
    "auth_type": "local",
    "mfa_enabled": true,
    "password_change_required": true,
    "expires_at": "${AUDIT_END_DATE}T23:59:59Z"
}
EOF
)

api_call POST "/users" "$USER_DATA"

# Generate API key for automated access
log "Generating auditor API key..."
API_KEY_DATA=$(cat << EOF
{
    "name": "${AUDITOR_NAME}-api-key",
    "description": "Read-only API key for audit",
    "permissions": ["read"],
    "expires_at": "${AUDIT_END_DATE}T23:59:59Z"
}
EOF
)

api_call POST "/apikeys" "$API_KEY_DATA"

log "Auditor access created successfully"
log "Username: ${AUDITOR_NAME}"
log "Temporary Password: ${TEMP_PASSWORD}"
log "Expires: ${AUDIT_END_DATE}"
log ""
log "IMPORTANT: Provide credentials securely to auditor"
log "IMPORTANT: Auditor must change password on first login"
log "IMPORTANT: MFA enrollment required"
```

---

## Continuous Compliance Monitoring

### Compliance Dashboard Metrics

```python
#!/usr/bin/env python3
"""
WALLIX Compliance Dashboard Metrics
Generates real-time compliance status metrics
"""

import requests
from datetime import datetime, timedelta
from typing import Dict, Any
from dataclasses import dataclass

@dataclass
class ComplianceMetrics:
    """Compliance metrics for monitoring"""
    framework: str
    status: str  # compliant, warning, non-compliant
    score: float  # 0-100
    controls_total: int
    controls_compliant: int
    controls_warning: int
    controls_failed: int
    last_check: datetime
    issues: list

class ComplianceMonitor:
    """Continuous compliance monitoring"""

    def __init__(self, host: str, token: str):
        self.base_url = f"https://{host}/api/v2"
        self.headers = {"Authorization": f"Bearer {token}"}

    def check_soc2_compliance(self) -> ComplianceMetrics:
        """Check SOC 2 compliance status"""
        issues = []
        controls = {"total": 0, "compliant": 0, "warning": 0, "failed": 0}

        # CC6.1 - Check MFA enforcement
        controls["total"] += 1
        mfa = self._get("/config/mfa")
        if mfa.get("data", {}).get("enforced", False):
            controls["compliant"] += 1
        else:
            controls["failed"] += 1
            issues.append("CC6.1: MFA not enforced for all users")

        # CC6.2 - Check approval workflows
        controls["total"] += 1
        approvals = self._get("/config/approval")
        if approvals.get("data", {}).get("enabled", False):
            controls["compliant"] += 1
        else:
            controls["warning"] += 1
            issues.append("CC6.2: Approval workflows not fully enabled")

        # CC7.2 - Check session recording
        controls["total"] += 1
        recording = self._get("/config/recording")
        if recording.get("data", {}).get("enabled", False):
            controls["compliant"] += 1
        else:
            controls["failed"] += 1
            issues.append("CC7.2: Session recording not enabled")

        # Calculate score
        score = (controls["compliant"] / controls["total"]) * 100 if controls["total"] > 0 else 0

        # Determine status
        if controls["failed"] > 0:
            status = "non-compliant"
        elif controls["warning"] > 0:
            status = "warning"
        else:
            status = "compliant"

        return ComplianceMetrics(
            framework="SOC2",
            status=status,
            score=score,
            controls_total=controls["total"],
            controls_compliant=controls["compliant"],
            controls_warning=controls["warning"],
            controls_failed=controls["failed"],
            last_check=datetime.now(),
            issues=issues
        )

    def check_password_compliance(self) -> Dict[str, Any]:
        """Check password rotation compliance"""
        accounts = self._get("/accounts")

        total = 0
        compliant = 0
        overdue = []

        for account in accounts.get("data", []):
            if account.get("auto_rotate", False):
                total += 1
                next_rotation = account.get("next_rotation")
                if next_rotation:
                    if datetime.fromisoformat(next_rotation.replace("Z", "+00:00")) > datetime.now():
                        compliant += 1
                    else:
                        overdue.append({
                            "account": account.get("name"),
                            "device": account.get("device", {}).get("name"),
                            "days_overdue": (datetime.now() - datetime.fromisoformat(
                                next_rotation.replace("Z", "+00:00")
                            )).days
                        })

        return {
            "total_accounts": total,
            "compliant": compliant,
            "overdue": len(overdue),
            "compliance_rate": (compliant / total * 100) if total > 0 else 100,
            "overdue_accounts": overdue
        }

    def check_access_review_status(self) -> Dict[str, Any]:
        """Check access review compliance"""
        users = self._get("/users")

        review_required = 0
        reviewed = 0

        for user in users.get("data", []):
            if user.get("status") == "active":
                review_required += 1
                last_review = user.get("last_access_review")
                if last_review:
                    review_date = datetime.fromisoformat(last_review.replace("Z", "+00:00"))
                    if review_date > datetime.now() - timedelta(days=90):
                        reviewed += 1

        return {
            "users_requiring_review": review_required,
            "users_reviewed": reviewed,
            "review_rate": (reviewed / review_required * 100) if review_required > 0 else 100,
            "overdue_reviews": review_required - reviewed
        }

    def _get(self, endpoint: str) -> Dict:
        """Make API request"""
        response = requests.get(f"{self.base_url}{endpoint}", headers=self.headers)
        response.raise_for_status()
        return response.json()

    def export_prometheus_metrics(self) -> str:
        """Export metrics in Prometheus format"""
        soc2 = self.check_soc2_compliance()
        passwords = self.check_password_compliance()
        access = self.check_access_review_status()

        metrics = f"""# HELP wallix_compliance_score Compliance score by framework (0-100)
# TYPE wallix_compliance_score gauge
wallix_compliance_score{{framework="soc2"}} {soc2.score}

# HELP wallix_compliance_controls_total Total number of controls
# TYPE wallix_compliance_controls_total gauge
wallix_compliance_controls_total{{framework="soc2"}} {soc2.controls_total}

# HELP wallix_compliance_controls_compliant Number of compliant controls
# TYPE wallix_compliance_controls_compliant gauge
wallix_compliance_controls_compliant{{framework="soc2"}} {soc2.controls_compliant}

# HELP wallix_password_compliance_rate Password rotation compliance rate
# TYPE wallix_password_compliance_rate gauge
wallix_password_compliance_rate {passwords['compliance_rate']}

# HELP wallix_passwords_overdue Number of overdue password rotations
# TYPE wallix_passwords_overdue gauge
wallix_passwords_overdue {passwords['overdue']}

# HELP wallix_access_review_rate Access review completion rate
# TYPE wallix_access_review_rate gauge
wallix_access_review_rate {access['review_rate']}

# HELP wallix_access_reviews_overdue Number of overdue access reviews
# TYPE wallix_access_reviews_overdue gauge
wallix_access_reviews_overdue {access['overdue_reviews']}
"""
        return metrics
```

### Drift Detection and Remediation

```bash
#!/bin/bash
# /opt/wallix/scripts/compliance-drift-check.sh
# Detect compliance drift and alert

set -euo pipefail

WALLIX_HOST="${WALLIX_HOST:-localhost}"
API_TOKEN="${WALLIX_API_TOKEN}"
ALERT_EMAIL="${ALERT_EMAIL:-security@company.com}"
BASELINE_DIR="/etc/wallix/compliance-baseline"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

api_call() {
    curl -s -H "Authorization: Bearer ${API_TOKEN}" \
         "https://${WALLIX_HOST}/api/v2$1"
}

check_drift() {
    local category="$1"
    local endpoint="$2"
    local baseline_file="${BASELINE_DIR}/${category}.json"

    # Get current state
    current=$(api_call "$endpoint" | jq -S '.')

    if [[ -f "$baseline_file" ]]; then
        baseline=$(cat "$baseline_file" | jq -S '.')

        # Compare (simple diff)
        if ! diff -q <(echo "$baseline") <(echo "$current") > /dev/null 2>&1; then
            log "DRIFT DETECTED: ${category}"
            return 1
        fi
    else
        log "Creating baseline: ${category}"
        echo "$current" > "$baseline_file"
    fi

    return 0
}

mkdir -p "${BASELINE_DIR}"

DRIFT_DETECTED=false
DRIFT_REPORT=""

# Check critical compliance controls
log "Checking compliance drift..."

if ! check_drift "mfa-config" "/config/mfa"; then
    DRIFT_DETECTED=true
    DRIFT_REPORT+="- MFA configuration changed\n"
fi

if ! check_drift "password-policy" "/policies/password"; then
    DRIFT_DETECTED=true
    DRIFT_REPORT+="- Password policy changed\n"
fi

if ! check_drift "session-policy" "/policies/session"; then
    DRIFT_DETECTED=true
    DRIFT_REPORT+="- Session policy changed\n"
fi

if ! check_drift "logging-config" "/config/logging"; then
    DRIFT_DETECTED=true
    DRIFT_REPORT+="- Logging configuration changed\n"
fi

if [[ "$DRIFT_DETECTED" == "true" ]]; then
    log "Compliance drift detected!"

    # Send alert
    if command -v mail &> /dev/null; then
        echo -e "Compliance configuration drift detected:\n\n${DRIFT_REPORT}\n\nPlease review and remediate." | \
            mail -s "[ALERT] WALLIX Compliance Drift Detected" "${ALERT_EMAIL}"
    fi

    # Write to syslog
    logger -t wallix-compliance "DRIFT DETECTED: ${DRIFT_REPORT}"

    exit 1
else
    log "No compliance drift detected"
    exit 0
fi
```

---

## Related Documentation

- [33 - Compliance & Audit](../24-compliance-audit/README.md) - Framework overview and audit preparation
- [20 - IEC 62443 Compliance](../20-iec62443-compliance/README.md) - Industrial security compliance
- [26 - API Reference](../17-api-reference/README.md) - Complete API documentation
- [37 - SIEM Integration](../37-siem-integration/README.md) - Log forwarding and alerting
- [43 - Monitoring and Alerting](../43-monitoring-alerting/README.md) - Operational monitoring

---

## External References

- [AICPA SOC 2 Framework](https://www.aicpa.org/interestareas/frc/assuranceadvisoryservices/aaborandatasheets.html)
- [ISO 27001:2022 Standard](https://www.iso.org/standard/27001)
- [PCI DSS v4.0](https://www.pcisecuritystandards.org/)
- [HIPAA Security Rule](https://www.hhs.gov/hipaa/for-professionals/security/index.html)
- [GDPR Official Text](https://gdpr.eu/)
- [IEC 62443 Series](https://www.iec.ch/industrial-cybersecurity)

---

## See Also

**Related Sections:**
- [24 - Compliance & Audit](../24-compliance-audit/README.md) - Compliance frameworks and audit prep
- [23 - Incident Response](../23-incident-response/README.md) - Security incident procedures

**Official Resources:**
- [WALLIX Documentation](https://pam.wallix.one/documentation)

---

*Document Version: 1.0*
*Last Updated: January 2026*
