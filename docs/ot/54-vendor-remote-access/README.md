# 54 - Secure Vendor Remote Access for OT Environments

## Table of Contents

1. [Vendor Access Overview](#vendor-access-overview)
2. [Vendor Access Architecture](#vendor-access-architecture)
3. [Vendor Onboarding Process](#vendor-onboarding-process)
4. [Access Control Patterns](#access-control-patterns)
5. [OT Vendor Scenarios](#ot-vendor-scenarios)
6. [Session Controls for Vendors](#session-controls-for-vendors)
7. [Credential Management for Vendors](#credential-management-for-vendors)
8. [Multi-Site Vendor Access](#multi-site-vendor-access)
9. [IEC 62443 Compliance for Vendors](#iec-62443-compliance-for-vendors)
10. [Vendor Access Audit](#vendor-access-audit)
11. [Vendor Access Revocation](#vendor-access-revocation)
12. [Best Practices](#best-practices)

---

## Vendor Access Overview

### The Vendor Access Challenge in OT

Third-party vendor access represents one of the most significant security challenges in OT environments. Vendors require access to maintain, troubleshoot, and update critical industrial systems, yet their access introduces substantial risk to operational continuity and safety.

For official WALLIX documentation, see: https://pam.wallix.one/documentation

```
+==============================================================================+
|                     VENDOR ACCESS CHALLENGES IN OT                           |
+==============================================================================+
|                                                                               |
|  OPERATIONAL CHALLENGES                                                       |
|  ======================                                                       |
|                                                                               |
|  +------------------------------------------------------------------------+  |
|  | Challenge                  | Impact                                    |  |
|  +----------------------------+-------------------------------------------+  |
|  | Multiple vendor companies  | Siemens, ABB, Rockwell, Schneider, etc.  |  |
|  | Different support staff    | New technician each service call          |  |
|  | 24/7 emergency support     | After-hours access requirements           |  |
|  | Legacy system maintenance  | Older systems with weak security          |  |
|  | Firmware/software updates  | Critical patching windows                 |  |
|  | Warranty obligations       | Vendor-only maintenance requirements      |  |
|  +----------------------------+-------------------------------------------+  |
|                                                                               |
|  SECURITY RISKS                                                               |
|  ==============                                                               |
|                                                                               |
|  +------------------------------------------------------------------------+  |
|  | Risk                       | Potential Consequence                     |  |
|  +----------------------------+-------------------------------------------+  |
|  | Credential sharing         | No individual accountability              |  |
|  | Unmonitored sessions       | Unauthorized configuration changes        |  |
|  | Persistent VPN access      | Always-on attack vector                   |  |
|  | Direct OT network access   | Lateral movement opportunity              |  |
|  | No session recording       | No forensic evidence                      |  |
|  | Unrestricted privileges    | Full system control                       |  |
|  +----------------------------+-------------------------------------------+  |
|                                                                               |
|  COMPLIANCE REQUIREMENTS                                                      |
|  ======================                                                       |
|                                                                               |
|  * IEC 62443-2-4: Security requirements for IACS service providers           |
|  * NIST 800-82: Guide to Industrial Control Systems Security                 |
|  * NIS2 Directive: Supply chain security requirements                        |
|  * NERC CIP: Third-party access controls for utilities                       |
|  * FDA 21 CFR Part 11: Vendor access in pharmaceutical/medical               |
|                                                                               |
+==============================================================================+
```

### WALLIX Vendor Access Solution

WALLIX Bastion provides a comprehensive solution for securing vendor access to OT environments while maintaining operational efficiency.

```
+==============================================================================+
|                    WALLIX VENDOR ACCESS CAPABILITIES                         |
+==============================================================================+
|                                                                               |
|  CORE CAPABILITIES                                                            |
|  =================                                                            |
|                                                                               |
|  +------------------------------------------------------------------------+  |
|  | Capability               | Benefit                                     |  |
|  +--------------------------+---------------------------------------------+  |
|  | Individual vendor        | Unique accountability per technician        |  |
|  | accounts                 |                                             |  |
|  +--------------------------+---------------------------------------------+  |
|  | Just-in-time access      | No standing privileges for vendors          |  |
|  +--------------------------+---------------------------------------------+  |
|  | Mandatory approval       | Plant personnel control vendor access       |  |
|  | workflows                |                                             |  |
|  +--------------------------+---------------------------------------------+  |
|  | Session recording        | Complete audit trail of vendor activities   |  |
|  +--------------------------+---------------------------------------------+  |
|  | Credential injection     | Vendors never see OT system passwords       |  |
|  +--------------------------+---------------------------------------------+  |
|  | Time-limited access      | Automatic expiration after maintenance      |  |
|  +--------------------------+---------------------------------------------+  |
|  | Real-time monitoring     | Live oversight of vendor sessions           |  |
|  +--------------------------+---------------------------------------------+  |
|  | Command filtering        | Restrict vendor to authorized actions       |  |
|  +--------------------------+---------------------------------------------+  |
|  | Multi-site control       | Centralized vendor management               |  |
|  +--------------------------+---------------------------------------------+  |
|                                                                               |
+==============================================================================+
```

### Risk Comparison

| Access Method | Accountability | Audit Trail | Credential Security | Access Control |
|---------------|----------------|-------------|---------------------|----------------|
| Direct VPN | None | Limited | Exposed | Weak |
| Shared jump server | Partial | Limited | Shared | Moderate |
| TeamViewer/AnyDesk | Limited | Basic | N/A | Weak |
| **WALLIX Bastion** | **Full** | **Complete** | **Protected** | **Comprehensive** |

---

## Vendor Access Architecture

### Secure Vendor Access Path

```
+==============================================================================+
|                    VENDOR ACCESS ARCHITECTURE                                 |
+==============================================================================+
|                                                                               |
|                           INTERNET                                            |
|                              |                                                |
|     +------------------------+------------------------+                       |
|     |                        |                        |                       |
|     v                        v                        v                       |
| +----------+           +----------+           +----------+                    |
| | Siemens  |           | Rockwell |           |   ABB    |                    |
| | Vendor   |           | Vendor   |           | Vendor   |                    |
| | Support  |           | Support  |           | Support  |                    |
| +----+-----+           +----+-----+           +----+-----+                    |
|      |                      |                      |                          |
|      |     HTTPS (443)      |                      |                          |
|      +----------------------+----------------------+                          |
|                             |                                                 |
|                             v                                                 |
| +===================================================================+        |
| |                      CORPORATE DMZ                                  |        |
| |                                                                     |        |
| |  +-------------------------------------------------------------+   |        |
| |  |                 WALLIX ACCESS MANAGER                        |   |        |
| |  |                                                              |   |        |
| |  |   1. Vendor authenticates (individual account + MFA)        |   |        |
| |  |   2. Vendor sees only authorized targets                    |   |        |
| |  |   3. Vendor requests access (with ticket/justification)     |   |        |
| |  |                                                              |   |        |
| |  +------------------------------+-------------------------------+   |        |
| |                                 |                                   |        |
| +===================================================================+        |
|                                   |                                           |
|                                   v                                           |
| +===================================================================+        |
| |                        OT DMZ                                       |        |
| |                                                                     |        |
| |  +-------------------------------------------------------------+   |        |
| |  |                  WALLIX BASTION                              |   |        |
| |  |                                                              |   |        |
| |  |   4. Approval workflow triggered                            |   |        |
| |  |   5. Plant operations approves/denies                       |   |        |
| |  |   6. Time-limited session established                       |   |        |
| |  |   7. Full session recording active                          |   |        |
| |  |   8. Credentials injected (vendor never sees)               |   |        |
| |  |   9. Real-time monitoring available                         |   |        |
| |  |                                                              |   |        |
| |  +------------------------------+-------------------------------+   |        |
| |                                 |                                   |        |
| +===================================================================+        |
|                                   |                                           |
|              +--------------------+--------------------+                      |
|              |                    |                    |                      |
|              v                    v                    v                      |
| +=================================================================+          |
| |                        OT NETWORK (Level 3)                      |          |
| |                                                                  |          |
| | +----------------+  +----------------+  +----------------+       |          |
| | | Siemens TIA    |  | Rockwell       |  | ABB AC 800M   |       |          |
| | | Portal Station |  | FactoryTalk    |  | Engineering   |       |          |
| | +----------------+  +----------------+  +----------------+       |          |
| |                                                                  |          |
| +=================================================================+          |
|                                   |                                           |
|              +--------------------+--------------------+                      |
|              |                    |                    |                      |
|              v                    v                    v                      |
| +=================================================================+          |
| |                    OT CONTROL NETWORK (Level 1-2)                |          |
| |                                                                  |          |
| | +----------------+  +----------------+  +----------------+       |          |
| | | Siemens S7     |  | Allen-Bradley  |  | ABB AC 800M   |       |          |
| | | PLCs           |  | ControlLogix   |  | Controllers   |       |          |
| | +----------------+  +----------------+  +----------------+       |          |
| |                                                                  |          |
| +=================================================================+          |
|                                                                               |
+==============================================================================+
```

### Network Security Zones

```
+==============================================================================+
|                    VENDOR ACCESS SECURITY ZONES                               |
+==============================================================================+
|                                                                               |
|  ZONE ARCHITECTURE (IEC 62443)                                                |
|  =============================                                                |
|                                                                               |
|  +------------------------------------------------------------------------+  |
|  |                                                                         |  |
|  |  ZONE 5: EXTERNAL (Internet)                                            |  |
|  |  +-----------------------------------------------------------------+   |  |
|  |  |  Vendor workstations (untrusted)                                 |   |  |
|  |  |  Security Level: SL 0                                            |   |  |
|  |  +-----------------------------------------------------------------+   |  |
|  |                                 |                                       |  |
|  |                          [CONDUIT: TLS 1.3, MFA]                       |  |
|  |                                 |                                       |  |
|  |  ZONE 4: CORPORATE DMZ                                                  |  |
|  |  +-----------------------------------------------------------------+   |  |
|  |  |  WALLIX Access Manager                                           |   |  |
|  |  |  Security Level: SL 3                                            |   |  |
|  |  |  * Public-facing portal                                          |   |  |
|  |  |  * MFA enforcement                                               |   |  |
|  |  |  * Initial authentication                                        |   |  |
|  |  +-----------------------------------------------------------------+   |  |
|  |                                 |                                       |  |
|  |                          [CONDUIT: Internal encrypted]                 |  |
|  |                                 |                                       |  |
|  |  ZONE 3.5: OT DMZ                                                       |  |
|  |  +-----------------------------------------------------------------+   |  |
|  |  |  WALLIX Bastion                                                  |   |  |
|  |  |  Security Level: SL 3-4                                          |   |  |
|  |  |  * Session proxy                                                 |   |  |
|  |  |  * Approval workflow                                             |   |  |
|  |  |  * Recording & monitoring                                        |   |  |
|  |  +-----------------------------------------------------------------+   |  |
|  |                                 |                                       |  |
|  |                          [CONDUIT: Vendor-specific protocols]          |  |
|  |                                 |                                       |  |
|  |  ZONE 3: SITE OPERATIONS                                                |  |
|  |  +-----------------------------------------------------------------+   |  |
|  |  |  Engineering workstations, SCADA servers, Historians             |   |  |
|  |  |  Security Level: SL 2-3                                          |   |  |
|  |  +-----------------------------------------------------------------+   |  |
|  |                                 |                                       |  |
|  |  ZONE 1-2: CONTROL NETWORK                                              |  |
|  |  +-----------------------------------------------------------------+   |  |
|  |  |  PLCs, RTUs, HMIs, DCS controllers                               |   |  |
|  |  |  Security Level: SL 2-4 (depending on criticality)              |   |  |
|  |  |  * Access via engineering workstations only                      |   |  |
|  |  +-----------------------------------------------------------------+   |  |
|  |                                                                         |  |
|  +------------------------------------------------------------------------+  |
|                                                                               |
+==============================================================================+
```

---

## Vendor Onboarding Process

### Vendor Registration Workflow

```
+==============================================================================+
|                    VENDOR REGISTRATION WORKFLOW                               |
+==============================================================================+
|                                                                               |
|  PHASE 1: VENDOR COMPANY REGISTRATION                                         |
|  ====================================                                         |
|                                                                               |
|  +---------+       +------------+       +-----------+       +------------+   |
|  | Vendor  |       | Procurement|       | OT        |       | Security   |   |
|  | Request |------>| Review     |------>| Manager   |------>| Team       |   |
|  |         |       |            |       | Approval  |       | Validation |   |
|  +---------+       +------------+       +-----------+       +------------+   |
|       |                                                            |          |
|       |                                                            v          |
|       |                                                    +-------------+    |
|       |                                                    | Vendor      |    |
|       |                                                    | Company     |    |
|       |                                                    | Created     |    |
|       |                                                    +-------------+    |
|       |                                                                       |
|  REQUIREMENTS GATHERED:                                                       |
|  * Vendor company details (legal name, address, contacts)                     |
|  * Contract/NDA reference numbers                                             |
|  * Systems requiring vendor access                                            |
|  * Expected access patterns (scheduled maintenance, emergency)                |
|  * Authorized sites for access                                                |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  PHASE 2: INDIVIDUAL TECHNICIAN REGISTRATION                                  |
|  ==========================================                                   |
|                                                                               |
|  +---------+       +------------+       +-----------+       +------------+   |
|  | Vendor  |       | Vendor     |       | Customer  |       | Account    |   |
|  | Company |------>| Nominates  |------>| Security  |------>| Created    |   |
|  | Admin   |       | Technician |       | Approves  |       | in WALLIX  |   |
|  +---------+       +------------+       +-----------+       +------------+   |
|                                                                    |          |
|                                                                    v          |
|                                                           +---------------+   |
|                                                           | Welcome Email |   |
|                                                           | + MFA Setup   |   |
|                                                           +---------------+   |
|                                                                               |
+==============================================================================+
```

### NDA and Security Requirements

```
+==============================================================================+
|                    VENDOR SECURITY REQUIREMENTS                               |
+==============================================================================+
|                                                                               |
|  CONTRACTUAL REQUIREMENTS                                                     |
|  ========================                                                     |
|                                                                               |
|  +------------------------------------------------------------------------+  |
|  | Requirement                        | Documentation                      |  |
|  +------------------------------------+------------------------------------+  |
|  | Non-Disclosure Agreement (NDA)     | Signed NDA covering OT systems     |  |
|  | Master Service Agreement (MSA)     | Defines scope and liability        |  |
|  | Security Addendum                  | Specific OT security obligations   |  |
|  | Background Check Confirmation      | Verified for critical access       |  |
|  | Insurance Certificate              | Cyber liability coverage           |  |
|  +------------------------------------+------------------------------------+  |
|                                                                               |
|  TECHNICAL SECURITY REQUIREMENTS                                              |
|  ===============================                                              |
|                                                                               |
|  +------------------------------------------------------------------------+  |
|  | Requirement                        | Validation Method                  |  |
|  +------------------------------------+------------------------------------+  |
|  | Unique individual account          | Email verification                 |  |
|  | Multi-factor authentication        | TOTP/Hardware token enrollment     |  |
|  | Secure workstation                 | Self-attestation or EDR check      |  |
|  | VPN client (if required)           | Client certificate provisioning    |  |
|  | Security awareness training        | Vendor-specific OT training        |  |
|  +------------------------------------+------------------------------------+  |
|                                                                               |
|  COMPLIANCE ACKNOWLEDGMENTS                                                   |
|  =========================                                                    |
|                                                                               |
|  Vendors must acknowledge:                                                    |
|  * All sessions will be recorded                                              |
|  * Access is time-limited and logged                                          |
|  * Commands may be filtered/restricted                                        |
|  * Sessions may be monitored in real-time                                     |
|  * Access may be terminated without notice                                    |
|  * Evidence may be shared with authorities if required                        |
|                                                                               |
+==============================================================================+
```

### Account Provisioning Configuration

```json
{
    "vendor_company": {
        "company_name": "Siemens Industrial Services",
        "contract_reference": "MSA-2025-00123",
        "nda_reference": "NDA-2025-00456",
        "expiry_date": "2026-12-31",
        "authorized_sites": ["Site-A-HQ", "Site-B-Plant"],
        "emergency_contact": "+49-xxx-xxx-xxxx",
        "primary_contact": {
            "name": "Hans Mueller",
            "email": "hans.mueller@siemens.com",
            "phone": "+49-xxx-xxx-xxxx"
        }
    },
    "vendor_user_template": {
        "user_group": "Siemens-Vendor-Support",
        "profile": "vendor-ot-restricted",
        "mfa_required": true,
        "mfa_type": "totp",
        "password_policy": "vendor-strong",
        "session_timeout_minutes": 60,
        "max_concurrent_sessions": 1,
        "default_authorization": "vendor-jit-approval-required"
    }
}
```

### Vendor User Creation via API

```bash
# Create vendor user via REST API
curl -X POST "https://bastion.company.com/api/users" \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "user_name": "siemens-tech-mueller",
    "display_name": "Hans Mueller (Siemens)",
    "email": "hans.mueller@siemens.com",
    "user_groups": ["Siemens-Vendor-Support"],
    "profile": "vendor-ot-restricted",
    "force_change_password": true,
    "authentication": {
        "local_password": true,
        "mfa_required": true,
        "mfa_type": "totp"
    },
    "expiration_date": "2026-12-31",
    "metadata": {
        "vendor_company": "Siemens Industrial Services",
        "contract_ref": "MSA-2025-00123",
        "authorized_by": "john.smith@company.com",
        "authorization_date": "2025-01-15"
    }
}'
```

---

## Access Control Patterns

### Just-In-Time Vendor Access

```
+==============================================================================+
|                    JIT VENDOR ACCESS WORKFLOW                                 |
+==============================================================================+
|                                                                               |
|  +-----------+                                                                |
|  |  Vendor   |   T+0 min                                                      |
|  |  Requests |                                                                |
|  |  Access   |                                                                |
|  +-----+-----+                                                                |
|        |                                                                      |
|        | 1. Login with MFA                                                    |
|        | 2. Select target system                                              |
|        | 3. Provide justification/ticket#                                     |
|        | 4. Specify requested duration                                        |
|        v                                                                      |
|  +===================+                                                        |
|  | WALLIX BASTION    |   T+1 min                                              |
|  |                   |                                                        |
|  | * Validate vendor |                                                        |
|  | * Check contract  |                                                        |
|  | * Verify target   |                                                        |
|  | * Queue approval  |----------------------------------+                     |
|  +===================+                                  |                     |
|                                                         v                     |
|                                              +---------------------+          |
|                                              | APPROVAL QUEUE      |          |
|                                              |                     |          |
|                                              | * OT Operations     |          |
|                                              | * Plant Manager     |          |
|                                              | * Security Team     |          |
|                                              +----------+----------+          |
|                                                         |                     |
|                                                         v                     |
|                                              +---------------------+          |
|                                              |  APPROVER           |  T+5 min |
|                                              |                     |          |
|                                              | Reviews:            |          |
|                                              | * Vendor identity   |          |
|                                              | * Target system     |          |
|                                              | * Justification     |          |
|                                              | * Requested time    |          |
|                                              |                     |          |
|                                              | Decision:           |          |
|                                              | [ ] Approve         |          |
|                                              | [ ] Deny            |          |
|                                              | [ ] Modify duration |          |
|                                              +----------+----------+          |
|                                                         |                     |
|        +------------------------------------------------+                     |
|        |                                                                      |
|        v                                                                      |
|  +===================+                                                        |
|  | ACCESS GRANTED    |   T+6 min                                              |
|  |                   |                                                        |
|  | * Time window     |                                                        |
|  |   opens           |                                                        |
|  | * Recording       |                                                        |
|  |   starts          |                                                        |
|  | * Credentials     |                                                        |
|  |   injected        |                                                        |
|  +===================+                                                        |
|        |                                                                      |
|        v                                                                      |
|  +-----------+                                                                |
|  |  SESSION  |   T+6 min to T+4 hours (as approved)                           |
|  |  ACTIVE   |                                                                |
|  |           |                                                                |
|  | * Vendor works on system                                                   |
|  | * All activity recorded                                                    |
|  | * Real-time monitoring available                                           |
|  +-----------+                                                                |
|        |                                                                      |
|        v                                                                      |
|  +===================+                                                        |
|  | ACCESS EXPIRES    |   T+4 hours (or session end)                           |
|  |                   |                                                        |
|  | * Session         |                                                        |
|  |   terminated      |                                                        |
|  | * Credentials     |                                                        |
|  |   rotated         |                                                        |
|  | * Recording       |                                                        |
|  |   archived        |                                                        |
|  +===================+                                                        |
|                                                                               |
+==============================================================================+
```

### Vendor Approval Workflow Configuration

```json
{
    "authorization": {
        "name": "vendor-siemens-plc-access",
        "description": "Siemens vendor access to Siemens PLCs via engineering workstation",
        "user_group": "Siemens-Vendor-Support",
        "target_group": "Siemens-Engineering-Stations",
        "active": true,
        "is_recorded": true,
        "is_critical": true,
        "approval_required": true,
        "has_comment": true,
        "subprotocols": ["RDP"]
    },
    "approval_workflow": {
        "name": "vendor-access-dual-approval",
        "type": "any-of",
        "approvers": [
            {"group": "OT-Operations-Supervisors"},
            {"group": "Plant-Control-Engineers"},
            {"group": "OT-Security-Team"}
        ],
        "min_approvals": 1,
        "timeout_hours": 2,
        "timeout_action": "deny",
        "notification": {
            "email": true,
            "sms": true,
            "portal": true
        }
    },
    "access_window": {
        "default_duration_hours": 4,
        "max_duration_hours": 8,
        "extension_allowed": true,
        "extension_requires_approval": true,
        "max_extensions": 1
    },
    "session_policy": {
        "max_idle_minutes": 15,
        "max_duration_hours": 4,
        "recording": "mandatory",
        "real_time_monitoring": true,
        "command_filtering": "vendor-restricted"
    }
}
```

### Scheduled Maintenance Windows

```json
{
    "maintenance_window": {
        "name": "quarterly-plc-maintenance",
        "vendor_company": "Siemens Industrial Services",
        "schedule": {
            "frequency": "quarterly",
            "day_of_week": "saturday",
            "start_time": "22:00",
            "end_time": "06:00",
            "timezone": "Europe/Berlin"
        },
        "pre_approved_access": {
            "enabled": true,
            "targets": ["Siemens-Engineering-Stations"],
            "max_concurrent_vendors": 2,
            "require_ticket": true
        },
        "notification": {
            "notify_before_hours": 48,
            "notify_list": [
                "ot-operations@company.com",
                "plant-manager@company.com"
            ]
        },
        "post_maintenance": {
            "password_rotation": true,
            "session_review_required": true,
            "report_generation": true
        }
    }
}
```

### Emergency Vendor Access

```
+==============================================================================+
|                    EMERGENCY VENDOR ACCESS WORKFLOW                           |
+==============================================================================+
|                                                                               |
|  SCENARIO: Critical production system failure requiring immediate vendor     |
|            support outside normal business hours                              |
|                                                                               |
|  +---------------+                                                            |
|  | INCIDENT      |   T+0 min                                                  |
|  | Production    |                                                            |
|  | system down   |                                                            |
|  +-------+-------+                                                            |
|          |                                                                    |
|          v                                                                    |
|  +---------------+                                                            |
|  | OT Operator   |   T+2 min                                                  |
|  | calls vendor  |                                                            |
|  | support       |                                                            |
|  +-------+-------+                                                            |
|          |                                                                    |
|          v                                                                    |
|  +---------------+                                                            |
|  | Vendor tech   |   T+5 min                                                  |
|  | requests      |                                                            |
|  | EMERGENCY     |                                                            |
|  | access        |                                                            |
|  +-------+-------+                                                            |
|          |                                                                    |
|          | Emergency flag triggers expedited workflow                         |
|          v                                                                    |
|  +===================+                                                        |
|  | WALLIX BASTION    |                                                        |
|  |                   |                                                        |
|  | Emergency         |-----------------+                                      |
|  | workflow          |                 |                                      |
|  | triggered         |                 v                                      |
|  +===================+      +---------------------+                           |
|                             | ON-CALL APPROVER    |  T+7 min                  |
|                             |                     |                           |
|                             | * Push notification |                           |
|                             | * Phone call        |                           |
|                             | * SMS alert         |                           |
|                             |                     |                           |
|                             | Quick approve via   |                           |
|                             | mobile app          |                           |
|                             +----------+----------+                           |
|                                        |                                      |
|          +-----------------------------+                                      |
|          |                                                                    |
|          v                                                                    |
|  +===================+                                                        |
|  | EMERGENCY         |   T+8 min                                              |
|  | SESSION           |                                                        |
|  |                   |                                                        |
|  | * 2-hour initial  |                                                        |
|  |   window          |                                                        |
|  | * Mandatory       |                                                        |
|  |   real-time       |                                                        |
|  |   monitoring      |                                                        |
|  | * Supervisor      |                                                        |
|  |   auto-notified   |                                                        |
|  +===================+                                                        |
|          |                                                                    |
|          v                                                                    |
|  +---------------+                                                            |
|  | POST-INCIDENT |   After resolution                                         |
|  | REVIEW        |                                                            |
|  |               |                                                            |
|  | * Session     |                                                            |
|  |   review      |                                                            |
|  | * Incident    |                                                            |
|  |   report      |                                                            |
|  | * Management  |                                                            |
|  |   signoff     |                                                            |
|  +---------------+                                                            |
|                                                                               |
|  TOTAL TIME TO ACCESS: ~8 minutes (vs hours without PAM)                      |
|                                                                               |
+==============================================================================+
```

---

## OT Vendor Scenarios

### PLC Vendor Maintenance (Siemens, ABB, Rockwell)

```
+==============================================================================+
|                    PLC VENDOR MAINTENANCE SCENARIO                            |
+==============================================================================+
|                                                                               |
|  SIEMENS PLC MAINTENANCE                                                      |
|  =======================                                                      |
|                                                                               |
|  Access Path:                                                                 |
|  Vendor --> WALLIX --> TIA Portal Workstation --> S7 PLC                     |
|                                                                               |
|  +------------------------------------------------------------------------+  |
|  | Component                    | WALLIX Configuration                     |  |
|  +------------------------------+------------------------------------------+  |
|  | Target Device                | TIA-Engineering-WS-01                    |  |
|  | Protocol                     | RDP                                      |  |
|  | Account                      | siemens-maintenance@TIA-WS-01            |  |
|  | Credential Type              | Password (auto-rotate after session)     |  |
|  | Recording                    | Full video + keystroke                   |  |
|  | Approval                     | OT Operations + Control Engineer         |  |
|  | Max Duration                 | 4 hours                                  |  |
|  +------------------------------+------------------------------------------+  |
|                                                                               |
|  WALLIX Configuration:                                                        |
|                                                                               |
|  {                                                                            |
|      "device": {                                                              |
|          "name": "TIA-Engineering-WS-01",                                     |
|          "host": "10.100.3.50",                                               |
|          "domain": "Siemens-Equipment",                                       |
|          "description": "TIA Portal V18 Engineering Workstation"              |
|      },                                                                       |
|      "service": {                                                             |
|          "protocol": "RDP",                                                   |
|          "port": 3389,                                                        |
|          "subprotocols": {                                                    |
|              "clipboard": false,                                              |
|              "drive_redirection": false,                                      |
|              "usb_redirection": false                                         |
|          }                                                                    |
|      },                                                                       |
|      "account": {                                                             |
|          "login": "siemens-maintenance",                                      |
|          "auto_change_password": true,                                        |
|          "change_after_session": true,                                        |
|          "checkout_policy": "exclusive"                                       |
|      }                                                                        |
|  }                                                                            |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  ALLEN-BRADLEY/ROCKWELL MAINTENANCE                                           |
|  ==================================                                           |
|                                                                               |
|  Access Path:                                                                 |
|  Vendor --> WALLIX --> Studio 5000 Workstation --> ControlLogix PLC          |
|                                                                               |
|  +------------------------------------------------------------------------+  |
|  | Component                    | WALLIX Configuration                     |  |
|  +------------------------------+------------------------------------------+  |
|  | Target Device                | Rockwell-Eng-WS-01                       |  |
|  | Protocol                     | RDP                                      |  |
|  | Account                      | rockwell-support@Rockwell-WS             |  |
|  | Credential Type              | Domain account (managed)                 |  |
|  | Recording                    | Full video + keystroke                   |  |
|  | Approval                     | Dual approval required                   |  |
|  | Max Duration                 | 4 hours                                  |  |
|  +------------------------------+------------------------------------------+  |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  ABB DCS MAINTENANCE                                                          |
|  ===================                                                          |
|                                                                               |
|  Access Path:                                                                 |
|  Vendor --> WALLIX --> ABB Engineering Station --> AC 800M Controller        |
|                                                                               |
|  +------------------------------------------------------------------------+  |
|  | Component                    | WALLIX Configuration                     |  |
|  +------------------------------+------------------------------------------+  |
|  | Target Device                | ABB-800xA-Engineering-01                 |  |
|  | Protocol                     | RDP                                      |  |
|  | Account                      | abb-support@ABB-Eng                      |  |
|  | Credential Type              | Password (auto-rotate)                   |  |
|  | Recording                    | Full video + keystroke + OCR             |  |
|  | Approval                     | DCS supervisor required                  |  |
|  | Max Duration                 | 6 hours                                  |  |
|  +------------------------------+------------------------------------------+  |
|                                                                               |
+==============================================================================+
```

### SCADA Vendor Support

```json
{
    "vendor_access_profile": {
        "name": "scada-vendor-wonderware",
        "description": "Wonderware/AVEVA vendor support access",
        "targets": [
            {
                "device": "SCADA-Server-01",
                "services": ["RDP"],
                "account": "wonderware-support"
            },
            {
                "device": "SCADA-Server-02",
                "services": ["RDP"],
                "account": "wonderware-support"
            }
        ],
        "session_policy": {
            "recording": "mandatory",
            "real_time_monitoring": true,
            "max_duration_hours": 4,
            "idle_timeout_minutes": 15
        },
        "restrictions": {
            "clipboard": "disabled",
            "file_transfer": "disabled",
            "time_frames": ["business-hours-extended"]
        }
    }
}
```

### HMI Vendor Access

```
+==============================================================================+
|                    HMI VENDOR ACCESS CONFIGURATION                            |
+==============================================================================+
|                                                                               |
|  TYPICAL HMI VENDOR TASKS                                                     |
|  ========================                                                     |
|                                                                               |
|  * Screen layout modifications                                                |
|  * Alarm configuration updates                                                |
|  * Trend display adjustments                                                  |
|  * Software updates/patches                                                   |
|  * License renewals                                                           |
|                                                                               |
|  ACCESS CONFIGURATION                                                         |
|  ====================                                                         |
|                                                                               |
|  {                                                                            |
|      "authorization": {                                                       |
|          "name": "hmi-vendor-access",                                         |
|          "user_group": "HMI-Vendor-Support",                                  |
|          "target_group": "HMI-Engineering-Stations",                          |
|          "approval_required": true,                                           |
|          "is_recorded": true                                                  |
|      },                                                                       |
|      "target_group": {                                                        |
|          "name": "HMI-Engineering-Stations",                                  |
|          "devices": [                                                         |
|              "HMI-Dev-Station-01",                                            |
|              "HMI-Dev-Station-02"                                             |
|          ]                                                                    |
|      },                                                                       |
|      "restrictions": {                                                        |
|          "note": "HMI vendors should NOT have direct access to production",   |
|          "note2": "HMI systems - only development/test stations",             |
|          "production_access": "prohibited",                                   |
|          "deployment_process": "customer-performed"                           |
|      }                                                                        |
|  }                                                                            |
|                                                                               |
+==============================================================================+
```

### Historian Vendor Access

```json
{
    "historian_vendor_access": {
        "name": "historian-vendor-osisoft",
        "description": "OSIsoft/AVEVA PI vendor support access",
        "targets": [
            {
                "device": "PI-Server-Primary",
                "services": ["RDP", "SSH"],
                "accounts": {
                    "admin": "pi-admin-support",
                    "read_only": "pi-readonly-support"
                }
            },
            {
                "device": "PI-Archive-Server",
                "services": ["RDP"],
                "accounts": {
                    "admin": "pi-archive-support"
                }
            }
        ],
        "data_protection": {
            "note": "Historian contains sensitive production data",
            "data_export": "prohibited",
            "query_logging": "enabled",
            "bulk_data_access": "requires_additional_approval"
        },
        "session_controls": {
            "recording": "mandatory",
            "ocr_indexing": true,
            "clipboard": "disabled",
            "file_transfer": "disabled",
            "max_duration_hours": 4
        }
    }
}
```

---

## Session Controls for Vendors

### Mandatory Session Recording

```
+==============================================================================+
|                    VENDOR SESSION RECORDING REQUIREMENTS                      |
+==============================================================================+
|                                                                               |
|  RECORDING CONFIGURATION                                                      |
|  =======================                                                      |
|                                                                               |
|  {                                                                            |
|      "session_recording_policy": {                                            |
|          "name": "vendor-mandatory-recording",                                |
|          "applies_to": ["all-vendor-groups"],                                 |
|          "recording": {                                                       |
|              "enabled": true,                                                 |
|              "mandatory": true,                                               |
|              "cannot_be_disabled": true                                       |
|          },                                                                   |
|          "ssh_recording": {                                                   |
|              "input": true,                                                   |
|              "output": true,                                                  |
|              "metadata": true                                                 |
|          },                                                                   |
|          "rdp_recording": {                                                   |
|              "video": true,                                                   |
|              "ocr_indexing": true,                                            |
|              "keystroke_logging": true,                                       |
|              "clipboard_capture": true,                                       |
|              "file_transfer_logging": true                                    |
|          },                                                                   |
|          "storage": {                                                         |
|              "retention_days": 365,                                           |
|              "encryption": "AES-256",                                         |
|              "immutable": true                                                |
|          }                                                                    |
|      }                                                                        |
|  }                                                                            |
|                                                                               |
|  RECORDING DATA CAPTURED                                                      |
|  =======================                                                      |
|                                                                               |
|  +------------------------------------------------------------------------+  |
|  | Data Type                  | Purpose                                    |  |
|  +----------------------------+--------------------------------------------+  |
|  | Full video recording       | Visual record of all activities            |  |
|  | Keystroke logging          | Commands and input capture                 |  |
|  | OCR indexing               | Searchable text from RDP sessions          |  |
|  | Clipboard data             | Data transferred via clipboard             |  |
|  | File transfer logs         | Files uploaded/downloaded                  |  |
|  | Session metadata           | Duration, target, user, timestamps         |  |
|  | Authentication events      | Login/logout, MFA usage                    |  |
|  +----------------------------+--------------------------------------------+  |
|                                                                               |
+==============================================================================+
```

### Command Filtering for Vendors

```json
{
    "command_filter": {
        "name": "vendor-restricted-commands",
        "description": "Command restrictions for vendor sessions",
        "filter_type": "blacklist",
        "rules": [
            {
                "pattern": "^(shutdown|reboot|poweroff|halt|init\\s+[06])\\b",
                "pattern_type": "regex",
                "action": "deny",
                "alert": true,
                "description": "Prevent system shutdown/reboot"
            },
            {
                "pattern": "rm -rf /",
                "pattern_type": "contains",
                "action": "deny",
                "alert": true,
                "description": "Prevent filesystem wipe"
            },
            {
                "pattern": "^(useradd|userdel|usermod|passwd)\\b",
                "pattern_type": "regex",
                "action": "deny",
                "alert": true,
                "description": "Prevent user account modifications"
            },
            {
                "pattern": "^(iptables|firewall-cmd|ufw)\\b",
                "pattern_type": "regex",
                "action": "deny",
                "alert": true,
                "description": "Prevent firewall modifications"
            },
            {
                "pattern": "^(systemctl\\s+(stop|disable|mask))\\b",
                "pattern_type": "regex",
                "action": "deny",
                "alert": true,
                "description": "Prevent service disruption"
            }
        ],
        "audit_rules": [
            {
                "pattern": "sudo",
                "pattern_type": "contains",
                "action": "log_alert",
                "description": "Log all sudo usage"
            },
            {
                "pattern": "\\.(conf|cfg|ini)$",
                "pattern_type": "regex",
                "action": "log_alert",
                "description": "Log configuration file access"
            }
        ]
    }
}
```

### Real-Time Monitoring Requirements

```
+==============================================================================+
|                    VENDOR SESSION MONITORING                                  |
+==============================================================================+
|                                                                               |
|  MONITORING CONFIGURATION                                                     |
|  ========================                                                     |
|                                                                               |
|  {                                                                            |
|      "monitoring_policy": {                                                   |
|          "name": "vendor-realtime-monitoring",                                |
|          "applies_to": ["all-vendor-sessions"],                               |
|          "live_view": {                                                       |
|              "enabled": true,                                                 |
|              "auto_notify_supervisor": true,                                  |
|              "viewer_groups": ["OT-Operations", "OT-Security"]                |
|          },                                                                   |
|          "alerts": {                                                          |
|              "session_start": true,                                           |
|              "session_end": true,                                             |
|              "blocked_command": true,                                         |
|              "idle_timeout_warning": true,                                    |
|              "duration_threshold_minutes": 120                                |
|          },                                                                   |
|          "intervention": {                                                    |
|              "session_pause": true,                                           |
|              "session_terminate": true,                                       |
|              "send_message": true,                                            |
|              "authorized_groups": ["OT-Security", "OT-Supervisors"]           |
|          }                                                                    |
|      }                                                                        |
|  }                                                                            |
|                                                                               |
|  MONITORING DASHBOARD                                                         |
|  ====================                                                         |
|                                                                               |
|  +------------------------------------------------------------------------+  |
|  |  ACTIVE VENDOR SESSIONS                                    [Refresh]   |  |
|  +------------------------------------------------------------------------+  |
|  |                                                                         |  |
|  |  +-------------------------------------------------------------------+ |  |
|  |  | Vendor         | Target           | Duration | Status   | Actions | |  |
|  |  +----------------+------------------+----------+----------+---------+ |  |
|  |  | H.Mueller      | TIA-Eng-WS-01    | 01:23:45 | Active   | [View]  | |  |
|  |  | (Siemens)      |                  |          |          | [Term]  | |  |
|  |  +----------------+------------------+----------+----------+---------+ |  |
|  |  | J.Smith        | Rockwell-Eng-01  | 00:45:12 | Active   | [View]  | |  |
|  |  | (Rockwell)     |                  |          |          | [Term]  | |  |
|  |  +----------------+------------------+----------+----------+---------+ |  |
|  |                                                                         |  |
|  +------------------------------------------------------------------------+  |
|                                                                               |
+==============================================================================+
```

### Session Duration Limits

```json
{
    "session_duration_policy": {
        "name": "vendor-session-limits",
        "default_max_duration_hours": 4,
        "absolute_max_duration_hours": 8,
        "idle_timeout_minutes": 15,
        "warning_before_expiry_minutes": 15,
        "extension_policy": {
            "allowed": true,
            "requires_approval": true,
            "max_extension_hours": 2,
            "max_extensions": 1
        },
        "auto_terminate": {
            "on_duration_exceeded": true,
            "on_idle_timeout": true,
            "grace_period_minutes": 5
        }
    }
}
```

---

## Credential Management for Vendors

### Session Injection (No Credential Exposure)

```
+==============================================================================+
|                    CREDENTIAL INJECTION FOR VENDORS                           |
+==============================================================================+
|                                                                               |
|  PRINCIPLE: VENDORS NEVER SEE OT SYSTEM CREDENTIALS                          |
|  ===================================================                          |
|                                                                               |
|                                                                               |
|  +---------------+                                                            |
|  |    VENDOR     |                                                            |
|  |               |                                                            |
|  | Logs in with  |                                                            |
|  | own vendor    |                                                            |
|  | credentials   |                                                            |
|  +-------+-------+                                                            |
|          |                                                                    |
|          | Vendor's own username/password + MFA                               |
|          v                                                                    |
|  +===============================+                                            |
|  |       WALLIX BASTION          |                                            |
|  |                               |                                            |
|  |  1. Authenticate vendor       |                                            |
|  |  2. Check authorization       |                                            |
|  |  3. Retrieve target creds     |                                            |
|  |     from vault                |                                            |
|  |  4. Establish session to      |                                            |
|  |     target                    |                                            |
|  |  5. INJECT CREDENTIALS        |<---- Credentials never shown to vendor    |
|  |  6. Connect vendor to         |                                            |
|  |     established session       |                                            |
|  |                               |                                            |
|  +===============+===============+                                            |
|                  |                                                            |
|                  | Session with injected credentials                         |
|                  v                                                            |
|  +-------------------------------+                                            |
|  |        TARGET SYSTEM          |                                            |
|  |                               |                                            |
|  |  Vendor is logged in as       |                                            |
|  |  service account but never    |                                            |
|  |  sees the password            |                                            |
|  |                               |                                            |
|  +-------------------------------+                                            |
|                                                                               |
|                                                                               |
|  BENEFITS:                                                                    |
|  =========                                                                    |
|                                                                               |
|  * Vendors cannot record or share OT system passwords                         |
|  * Passwords can be complex (machine-generated)                               |
|  * Passwords can be rotated after each session                                |
|  * Credential theft from vendor workstation is ineffective                    |
|  * Vendor accounts can be disabled without changing OT passwords              |
|                                                                               |
+==============================================================================+
```

### Vendor-Specific Service Accounts

```json
{
    "service_accounts": {
        "siemens_vendor": {
            "account_name": "siemens-maint",
            "target": "TIA-Engineering-WS-01",
            "credential_type": "password",
            "password_policy": {
                "length": 32,
                "complexity": "maximum",
                "auto_generated": true
            },
            "usage_policy": {
                "vendor_groups": ["Siemens-Vendor-Support"],
                "checkout_exclusive": true,
                "show_password": false
            }
        },
        "rockwell_vendor": {
            "account_name": "rockwell-support",
            "target": "Rockwell-Engineering-WS",
            "credential_type": "password",
            "password_policy": {
                "length": 32,
                "complexity": "maximum",
                "auto_generated": true
            },
            "usage_policy": {
                "vendor_groups": ["Rockwell-Vendor-Support"],
                "checkout_exclusive": true,
                "show_password": false
            }
        }
    }
}
```

### Credential Rotation After Vendor Access

```json
{
    "post_session_rotation": {
        "policy_name": "vendor-session-rotation",
        "trigger": "session_end",
        "applies_to": ["all-vendor-sessions"],
        "rotation_settings": {
            "rotate_immediately": true,
            "new_password_length": 32,
            "verification_required": true,
            "retry_on_failure": 3
        },
        "notification": {
            "on_success": false,
            "on_failure": true,
            "alert_groups": ["OT-Security"]
        },
        "audit": {
            "log_rotation_event": true,
            "include_session_reference": true
        }
    }
}
```

---

## Multi-Site Vendor Access

### Centralized Vendor Management

```
+==============================================================================+
|                    MULTI-SITE VENDOR ACCESS ARCHITECTURE                      |
+==============================================================================+
|                                                                               |
|                         CENTRAL MANAGEMENT                                    |
|                               |                                               |
|           +-------------------+-------------------+                           |
|           |                                       |                           |
|           v                                       v                           |
|  +==================+                    +==================+                 |
|  | CORPORATE HQ     |                    | VENDOR PORTAL    |                 |
|  | WALLIX Bastion   |                    | (Access Manager) |                 |
|  |                  |                    |                  |                 |
|  | * Vendor DB      |<------------------>| * Vendor login   |                 |
|  | * Policy mgmt    |                    | * MFA            |                 |
|  | * Central audit  |                    | * Request portal |                 |
|  +========+=========+                    +==================+                 |
|           |                                                                   |
|           | Synchronized vendor policies                                      |
|           |                                                                   |
|  +--------+--------+--------+--------+                                        |
|  |                 |                 |                                        |
|  v                 v                 v                                        |
| +============+  +============+  +============+                                |
| | SITE A     |  | SITE B     |  | SITE C     |                                |
| | (Primary)  |  | (Secondary)|  | (Remote)   |                                |
| |            |  |            |  |            |                                |
| | Local      |  | Local      |  | Local      |                                |
| | Bastion    |  | Bastion    |  | Bastion    |                                |
| |            |  |            |  |            |                                |
| | * Siemens  |  | * Rockwell |  | * ABB      |                                |
| | * Wonderware| | * OSIsoft  |  | * Schneider|                                |
| +============+  +============+  +============+                                |
|                                                                               |
|  VENDOR SEES: Single portal, authorized sites only                            |
|  CUSTOMER GETS: Centralized control, local session handling                   |
|                                                                               |
+==============================================================================+
```

### Site-Specific Vendor Restrictions

```json
{
    "multi_site_vendor_policy": {
        "vendor_company": "Siemens Industrial Services",
        "site_authorizations": {
            "Site-A-HQ": {
                "authorized": true,
                "targets": ["Siemens-Equipment-SiteA"],
                "approvers": ["SiteA-OT-Operations"],
                "time_frames": ["business-hours-siteA"]
            },
            "Site-B-Plant": {
                "authorized": true,
                "targets": ["Siemens-Equipment-SiteB"],
                "approvers": ["SiteB-Plant-Operations"],
                "time_frames": ["24x7-with-approval"]
            },
            "Site-C-Remote": {
                "authorized": false,
                "reason": "No Siemens equipment at this site"
            }
        },
        "cross_site_restrictions": {
            "max_concurrent_sites": 1,
            "site_switch_cooldown_minutes": 30,
            "require_separate_sessions": true
        }
    }
}
```

---

## IEC 62443 Compliance for Vendors

### Security Level Requirements

```
+==============================================================================+
|                    IEC 62443 VENDOR ACCESS REQUIREMENTS                       |
+==============================================================================+
|                                                                               |
|  IEC 62443-2-4: SECURITY REQUIREMENTS FOR IACS SERVICE PROVIDERS             |
|  ===============================================================             |
|                                                                               |
|  +------------------------------------------------------------------------+  |
|  | Requirement                      | WALLIX Implementation               |  |
|  +----------------------------------+-------------------------------------+  |
|  | SP.01.01: Personnel security     | Individual vendor accounts          |  |
|  |                                  | Background check tracking           |  |
|  +----------------------------------+-------------------------------------+  |
|  | SP.02.01: Access control         | JIT access with approval            |  |
|  |                                  | Time-limited sessions               |  |
|  +----------------------------------+-------------------------------------+  |
|  | SP.02.02: Authentication         | MFA required for all vendors        |  |
|  |                                  | Certificate-based option            |  |
|  +----------------------------------+-------------------------------------+  |
|  | SP.03.01: Session management     | Session recording                   |  |
|  |                                  | Real-time monitoring                |  |
|  +----------------------------------+-------------------------------------+  |
|  | SP.03.02: Audit logging          | Complete audit trail                |  |
|  |                                  | Tamper-evident logs                 |  |
|  +----------------------------------+-------------------------------------+  |
|  | SP.04.01: Remote access          | Secure conduit via WALLIX           |  |
|  |                                  | No direct OT access                 |  |
|  +----------------------------------+-------------------------------------+  |
|                                                                               |
|  SECURITY LEVEL MAPPING                                                       |
|  ======================                                                       |
|                                                                               |
|  +--------+------------------------------------------------------------+     |
|  | SL     | Vendor Access Requirements (via WALLIX)                    |     |
|  +--------+------------------------------------------------------------+     |
|  |        |                                                            |     |
|  | SL 2   | * Individual vendor accounts                               |     |
|  |        | * Password + optional MFA                                  |     |
|  |        | * Session logging                                          |     |
|  |        | * Approval workflow (optional)                             |     |
|  |        |                                                            |     |
|  +--------+------------------------------------------------------------+     |
|  |        |                                                            |     |
|  | SL 3   | * All SL 2 requirements plus:                              |     |
|  |        | * Mandatory MFA                                            |     |
|  |        | * Mandatory approval workflow                              |     |
|  |        | * Full session recording                                   |     |
|  |        | * Real-time monitoring available                           |     |
|  |        | * Command filtering                                        |     |
|  |        | * Post-session credential rotation                         |     |
|  |        |                                                            |     |
|  +--------+------------------------------------------------------------+     |
|  |        |                                                            |     |
|  | SL 4   | * All SL 3 requirements plus:                              |     |
|  |        | * Dual approval (4-eyes)                                   |     |
|  |        | * Mandatory real-time monitoring                           |     |
|  |        | * Supervisor presence required                             |     |
|  |        | * Hardware token MFA                                       |     |
|  |        | * Immediate credential rotation                            |     |
|  |        |                                                            |     |
|  +--------+------------------------------------------------------------+     |
|                                                                               |
+==============================================================================+
```

### Audit Evidence for Vendor Sessions

```
+==============================================================================+
|                    VENDOR SESSION AUDIT EVIDENCE                              |
+==============================================================================+
|                                                                               |
|  EVIDENCE TYPES FOR COMPLIANCE AUDITS                                         |
|  ====================================                                         |
|                                                                               |
|  +------------------------------------------------------------------------+  |
|  | Evidence Type             | Content                                     |  |
|  +---------------------------+---------------------------------------------+  |
|  | Vendor Registration       | * Company details and contracts             |  |
|  | Records                   | * NDA documentation                         |  |
|  |                           | * Individual technician records             |  |
|  +---------------------------+---------------------------------------------+  |
|  | Access Request Logs       | * Request timestamp                         |  |
|  |                           | * Requested target and duration             |  |
|  |                           | * Business justification                    |  |
|  |                           | * Ticket/work order reference               |  |
|  +---------------------------+---------------------------------------------+  |
|  | Approval Records          | * Approver identity                         |  |
|  |                           | * Approval/denial timestamp                 |  |
|  |                           | * Approver comments                         |  |
|  |                           | * Approval chain (if multi-level)          |  |
|  +---------------------------+---------------------------------------------+  |
|  | Session Recordings        | * Full video recording (RDP)                |  |
|  |                           | * Command logs (SSH)                        |  |
|  |                           | * Keystroke logs                            |  |
|  |                           | * OCR-indexed content                       |  |
|  +---------------------------+---------------------------------------------+  |
|  | Session Metadata          | * Start/end timestamps                      |  |
|  |                           | * Session duration                          |  |
|  |                           | * Target system accessed                    |  |
|  |                           | * Source IP address                         |  |
|  +---------------------------+---------------------------------------------+  |
|  | Credential Management     | * Credential checkout logs                  |  |
|  |                           | * Password rotation records                 |  |
|  |                           | * Injection events                          |  |
|  +---------------------------+---------------------------------------------+  |
|                                                                               |
+==============================================================================+
```

---

## Vendor Access Audit

### Reporting on Vendor Activity

```bash
# Generate vendor access report via CLI
wabadmin report generate \
    --type vendor-access \
    --start-date "2025-01-01" \
    --end-date "2025-01-31" \
    --vendor-company "Siemens" \
    --format pdf \
    --output /reports/siemens-access-jan2025.pdf

# List all vendor sessions
wabadmin sessions list \
    --user-group "Siemens-Vendor-Support" \
    --start-date "2025-01-01" \
    --format csv > vendor-sessions.csv

# Export approval history
wabadmin approvals export \
    --authorization "vendor-*" \
    --start-date "2025-01-01" \
    --format json > approval-history.json
```

### Vendor Activity Report Template

```
+==============================================================================+
|                    VENDOR ACCESS AUDIT REPORT                                 |
|                    Period: January 2025                                       |
+==============================================================================+
|                                                                               |
|  EXECUTIVE SUMMARY                                                            |
|  =================                                                            |
|                                                                               |
|  Total vendor sessions: 47                                                    |
|  Unique vendors: 12                                                           |
|  Vendor companies: 5                                                          |
|  Average session duration: 2.3 hours                                          |
|  Sessions requiring approval: 47 (100%)                                       |
|  Sessions denied: 3 (6.4%)                                                    |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  VENDOR COMPANY BREAKDOWN                                                     |
|  ========================                                                     |
|                                                                               |
|  +-------------------+----------+----------+-------------+-----------------+ |
|  | Vendor Company    | Sessions | Duration | Approvals   | Recording Hours | |
|  +-------------------+----------+----------+-------------+-----------------+ |
|  | Siemens           | 18       | 41.5 hrs | 18 approved | 41.5            | |
|  | Rockwell          | 12       | 28.0 hrs | 11 approved | 28.0            | |
|  | ABB               | 8        | 19.2 hrs | 8 approved  | 19.2            | |
|  | Wonderware/AVEVA  | 6        | 14.4 hrs | 6 approved  | 14.4            | |
|  | OSIsoft           | 3        | 7.2 hrs  | 3 approved  | 7.2             | |
|  +-------------------+----------+----------+-------------+-----------------+ |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  SECURITY EVENTS                                                              |
|  ===============                                                              |
|                                                                               |
|  +-------------------+-------+----------------------------------------------+ |
|  | Event Type        | Count | Details                                      | |
|  +-------------------+-------+----------------------------------------------+ |
|  | Blocked commands  | 2     | rm -rf attempts blocked, investigated        | |
|  | Failed logins     | 5     | MFA failures, password issues                | |
|  | Session terminated| 1     | Terminated by supervisor (policy violation)  | |
|  | Access denied     | 3     | Requests denied by approvers                 | |
|  +-------------------+-------+----------------------------------------------+ |
|                                                                               |
+==============================================================================+
```

### Compliance Evidence Collection

```json
{
    "compliance_report": {
        "name": "vendor-access-iec62443-evidence",
        "period": {
            "start": "2025-01-01",
            "end": "2025-03-31"
        },
        "evidence_collection": {
            "vendor_accounts": {
                "export_all_vendors": true,
                "include_expiry_dates": true,
                "include_authorization_mappings": true
            },
            "access_requests": {
                "export_all_requests": true,
                "include_justifications": true,
                "include_approver_comments": true
            },
            "sessions": {
                "export_session_metadata": true,
                "include_recording_references": true,
                "sample_recordings_count": 10
            },
            "security_events": {
                "blocked_commands": true,
                "failed_authentications": true,
                "terminated_sessions": true
            }
        },
        "output_format": "pdf",
        "output_path": "/compliance/iec62443-vendor-q1-2025.pdf"
    }
}
```

### Anomaly Detection for Vendor Behavior

```json
{
    "vendor_anomaly_detection": {
        "name": "vendor-behavior-monitoring",
        "enabled": true,
        "baseline_period_days": 90,
        "detection_rules": [
            {
                "name": "unusual-access-hours",
                "description": "Vendor accessing outside normal patterns",
                "condition": "access_time NOT IN baseline_hours",
                "severity": "medium",
                "action": "alert"
            },
            {
                "name": "excessive-session-duration",
                "description": "Session significantly longer than average",
                "condition": "duration > (baseline_avg * 2)",
                "severity": "medium",
                "action": "alert"
            },
            {
                "name": "new-target-access",
                "description": "Vendor accessing previously unaccessed target",
                "condition": "target NOT IN vendor_baseline_targets",
                "severity": "high",
                "action": "alert_and_notify_supervisor"
            },
            {
                "name": "rapid-reconnection",
                "description": "Multiple sessions in short period",
                "condition": "sessions_count > 3 IN 1 hour",
                "severity": "medium",
                "action": "alert"
            },
            {
                "name": "command-pattern-deviation",
                "description": "Unusual command patterns detected",
                "condition": "commands NOT IN baseline_command_patterns",
                "severity": "high",
                "action": "alert_and_review"
            }
        ],
        "notification": {
            "channels": ["email", "siem", "portal"],
            "recipients": ["ot-security@company.com"]
        }
    }
}
```

---

## Vendor Access Revocation

### Immediate Access Termination

```bash
# Terminate active vendor session immediately
wabadmin session terminate \
    --session-id "ses-20250115-123456" \
    --reason "Security policy violation" \
    --notify-vendor \
    --notify-approvers

# Disable vendor user account
wabadmin user disable \
    --username "siemens-tech-mueller" \
    --reason "Contract terminated" \
    --effective-immediately

# Revoke all active vendor approvals
wabadmin approvals revoke \
    --user "siemens-tech-mueller" \
    --reason "Account disabled"
```

### Scheduled Access Expiration

```json
{
    "access_expiration_policy": {
        "vendor_user_expiration": {
            "auto_expire_enabled": true,
            "default_validity_days": 365,
            "warning_before_expiry_days": 30,
            "notification_recipients": [
                "vendor_contact",
                "customer_admin"
            ],
            "on_expiry": {
                "disable_account": true,
                "revoke_authorizations": true,
                "retain_audit_data": true
            }
        },
        "approval_expiration": {
            "default_validity_hours": 8,
            "max_validity_hours": 24,
            "auto_expire": true
        }
    }
}
```

### Emergency Lockout Procedures

```
+==============================================================================+
|                    EMERGENCY VENDOR LOCKOUT PROCEDURE                         |
+==============================================================================+
|                                                                               |
|  TRIGGER CONDITIONS                                                           |
|  ==================                                                           |
|                                                                               |
|  * Security incident detected                                                 |
|  * Contract termination                                                       |
|  * Vendor breach reported                                                     |
|  * Suspicious activity identified                                             |
|  * Regulatory requirement                                                     |
|                                                                               |
|  LOCKOUT PROCEDURE                                                            |
|  =================                                                            |
|                                                                               |
|  1. IMMEDIATE ACTIONS (within 5 minutes)                                      |
|     +------------------------------------------------------------------+     |
|     | Action                              | Command                     |     |
|     +-------------------------------------+-----------------------------+     |
|     | Terminate all active sessions       | wabadmin session terminate  |     |
|     |                                     |   --vendor "company-name"   |     |
|     +-------------------------------------+-----------------------------+     |
|     | Disable all vendor accounts         | wabadmin user disable       |     |
|     |                                     |   --group "vendor-group"    |     |
|     +-------------------------------------+-----------------------------+     |
|     | Revoke pending approvals            | wabadmin approvals revoke   |     |
|     |                                     |   --vendor "company-name"   |     |
|     +-------------------------------------+-----------------------------+     |
|                                                                               |
|  2. CREDENTIAL ROTATION (within 30 minutes)                                   |
|     +------------------------------------------------------------------+     |
|     | Rotate all vendor-accessed accounts                               |     |
|     | wabadmin credentials rotate --used-by-vendor "company-name"       |     |
|     +------------------------------------------------------------------+     |
|                                                                               |
|  3. INVESTIGATION (within 24 hours)                                           |
|     +------------------------------------------------------------------+     |
|     | Review all vendor session recordings                              |     |
|     | Export audit logs for analysis                                    |     |
|     | Document incident timeline                                        |     |
|     | Notify legal/compliance if required                               |     |
|     +------------------------------------------------------------------+     |
|                                                                               |
|  4. POST-INCIDENT (within 72 hours)                                           |
|     +------------------------------------------------------------------+     |
|     | Complete incident report                                          |     |
|     | Update vendor access policies if needed                           |     |
|     | Notify relevant stakeholders                                      |     |
|     | Archive all evidence                                              |     |
|     +------------------------------------------------------------------+     |
|                                                                               |
+==============================================================================+
```

---

## Best Practices

### Vendor Management Policies

```
+==============================================================================+
|                    VENDOR ACCESS POLICY GUIDELINES                            |
+==============================================================================+
|                                                                               |
|  ACCOUNT MANAGEMENT                                                           |
|  ==================                                                           |
|                                                                               |
|  DO:                                                                          |
|  * Create individual accounts for each vendor technician                      |
|  * Set account expiration dates aligned with contracts                        |
|  * Require MFA for all vendor accounts                                        |
|  * Regularly review and audit vendor accounts                                 |
|  * Remove accounts promptly when vendors leave                                |
|                                                                               |
|  DON'T:                                                                       |
|  * Create shared vendor accounts                                              |
|  * Allow indefinite account validity                                          |
|  * Skip MFA requirements for "convenience"                                    |
|  * Share vendor credentials between technicians                               |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  ACCESS CONTROLS                                                              |
|  ===============                                                              |
|                                                                               |
|  DO:                                                                          |
|  * Implement JIT access for all vendor connections                            |
|  * Require approval for all vendor sessions                                   |
|  * Limit access to specific systems per vendor                                |
|  * Use time-bounded access windows                                            |
|  * Enable session recording for all vendor access                             |
|                                                                               |
|  DON'T:                                                                       |
|  * Grant standing privileges to vendors                                       |
|  * Allow vendor access without approval                                       |
|  * Give vendors broader access than needed                                    |
|  * Disable session recording for any vendor session                           |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  SESSION MANAGEMENT                                                           |
|  ==================                                                           |
|                                                                               |
|  DO:                                                                          |
|  * Set reasonable session duration limits                                     |
|  * Configure idle timeouts                                                    |
|  * Enable real-time monitoring capability                                     |
|  * Rotate credentials after vendor sessions                                   |
|  * Review recordings of critical vendor work                                  |
|                                                                               |
|  DON'T:                                                                       |
|  * Allow unlimited session durations                                          |
|  * Skip credential rotation after access                                      |
|  * Ignore session recording storage                                           |
|                                                                               |
+==============================================================================+
```

### Training Requirements

| Training Type | Audience | Frequency | Content |
|---------------|----------|-----------|---------|
| Vendor Onboarding | New vendors | Once | Portal access, request process, policies |
| OT Security Awareness | All vendors | Annual | OT-specific security requirements |
| Approver Training | Plant operations | Initial + refresh | Approval process, red flags, escalation |
| Monitoring Training | OT security | Initial + refresh | Session monitoring, intervention |
| Incident Response | Security team | Annual | Vendor-related incident procedures |

### Incident Response for Vendor Issues

```
+==============================================================================+
|                    VENDOR INCIDENT RESPONSE PLAYBOOK                          |
+==============================================================================+
|                                                                               |
|  INCIDENT CLASSIFICATION                                                      |
|  =======================                                                      |
|                                                                               |
|  +------------------------------------------------------------------------+  |
|  | Severity | Description                      | Response Time            |  |
|  +----------+----------------------------------+--------------------------+  |
|  | Critical | Active compromise via vendor     | Immediate (minutes)      |  |
|  |          | session                          |                          |  |
|  +----------+----------------------------------+--------------------------+  |
|  | High     | Suspicious vendor activity       | Within 1 hour            |  |
|  |          | detected                         |                          |  |
|  +----------+----------------------------------+--------------------------+  |
|  | Medium   | Policy violation by vendor       | Within 4 hours           |  |
|  +----------+----------------------------------+--------------------------+  |
|  | Low      | Minor compliance deviation       | Within 24 hours          |  |
|  +----------+----------------------------------+--------------------------+  |
|                                                                               |
|  RESPONSE PROCEDURES                                                          |
|  ===================                                                          |
|                                                                               |
|  CRITICAL INCIDENT:                                                           |
|  1. Terminate all vendor sessions immediately                                 |
|  2. Disable vendor accounts                                                   |
|  3. Notify incident response team                                             |
|  4. Preserve all evidence (recordings, logs)                                  |
|  5. Isolate affected systems if needed                                        |
|  6. Engage forensics if required                                              |
|  7. Notify legal/compliance                                                   |
|  8. Contact vendor company management                                         |
|                                                                               |
|  HIGH SEVERITY:                                                               |
|  1. Review active vendor sessions                                             |
|  2. Terminate suspicious sessions                                             |
|  3. Investigate activity in recordings                                        |
|  4. Determine scope of potential impact                                       |
|  5. Escalate if necessary                                                     |
|                                                                               |
|  MEDIUM SEVERITY:                                                             |
|  1. Document policy violation                                                 |
|  2. Review session recording                                                  |
|  3. Notify vendor company contact                                             |
|  4. Implement corrective actions                                              |
|  5. Update policies if needed                                                 |
|                                                                               |
|  COMMUNICATION TEMPLATE                                                       |
|  ======================                                                       |
|                                                                               |
|  To: vendor-contact@vendor.com                                                |
|  Subject: Security Incident - Vendor Access Review Required                   |
|                                                                               |
|  We have identified [describe issue] during vendor access to our OT           |
|  systems on [date/time]. As per our security policies and contract            |
|  terms, we require:                                                           |
|                                                                               |
|  1. Immediate acknowledgment of this notification                             |
|  2. Investigation by your security team                                       |
|  3. Root cause analysis within [timeframe]                                    |
|  4. Corrective action plan                                                    |
|                                                                               |
|  Vendor access has been [suspended/restricted] pending resolution.            |
|                                                                               |
+==============================================================================+
```

---

## References

### WALLIX Documentation
- WALLIX Bastion Administration Guide: https://pam.wallix.one/documentation/admin-doc/bastion_en_administration_guide.pdf
- WALLIX REST API Reference: https://github.com/wallix/wbrest_samples
- WALLIX Terraform Provider: https://registry.terraform.io/providers/wallix/wallix-bastion

### Compliance Standards
- IEC 62443-2-4: Security requirements for IACS service providers
- NIST 800-82: Guide to Industrial Control Systems Security
- NIS2 Directive: Network and Information Security requirements
- NERC CIP-005: Electronic Security Perimeter

---

## Next Steps

Continue to [55 - Session Audit and Forensics](../55-session-audit-forensics/README.md) for detailed session investigation procedures.
