# Compliance & Audit Guide

This section provides guidance for achieving and maintaining compliance with major regulatory frameworks using WALLIX Bastion.

---

## Table of Contents

1. [Compliance Overview](#compliance-overview)
2. [SOC 2 Type II](#soc-2-type-ii)
3. [ISO 27001](#iso-27001)
4. [PCI-DSS](#pci-dss)
5. [HIPAA/HITECH](#hipaahitech)
6. [GDPR](#gdpr)
7. [NIS2 Directive](#nis2-directive)
8. [NIST Cybersecurity Framework](#nist-cybersecurity-framework)
9. [Evidence Collection Procedures](#evidence-collection-procedures)
10. [Audit Preparation Checklist](#audit-preparation-checklist)

---

## Compliance Overview

### WALLIX Bastion Compliance Capabilities

| Capability | Compliance Benefit |
|------------|-------------------|
| **Session Recording** | Audit trail, forensics, accountability |
| **Credential Vault** | Secure storage, access control |
| **Password Rotation** | Credential hygiene, risk reduction |
| **Access Control** | Least privilege, segregation of duties |
| **Approval Workflows** | Change control, authorization |
| **Audit Logging** | Accountability, non-repudiation |
| **MFA Support** | Strong authentication |
| **Encryption** | Data protection |

### Framework Coverage Summary

| Framework | Coverage Level | Primary Controls |
|-----------|----------------|------------------|
| IEC 62443 | Full | Access control, audit, monitoring |
| NIST 800-82 | Full | ICS security, privileged access |
| NIS2 | Full | Essential services protection |
| SOC 2 | High | Security, availability, confidentiality |
| ISO 27001 | High | Access control, cryptography, operations |
| PCI-DSS | High | Access control, logging, monitoring |
| HIPAA | Medium | Access control, audit, integrity |
| GDPR | Medium | Access control, data protection |

---

## SOC 2 Type II

### Overview

SOC 2 (Service Organization Control 2) evaluates controls relevant to security, availability, processing integrity, confidentiality, and privacy.

### Trust Service Criteria Mapping

#### Security (Common Criteria)

| Criteria | Description | WALLIX Control |
|----------|-------------|----------------|
| CC6.1 | Logical access security | User authentication, RBAC, MFA |
| CC6.2 | User registration/authorization | User provisioning, authorization workflows |
| CC6.3 | User access removal | Account deprovisioning, access revocation |
| CC6.6 | Logical access restrictions | Session policies, target access controls |
| CC6.7 | System boundary protection | Jump host architecture, network segmentation |
| CC6.8 | Malicious software prevention | Session isolation, controlled access |
| CC7.1 | Vulnerability detection | Security monitoring, audit logging |
| CC7.2 | System monitoring | Real-time session monitoring, alerts |
| CC7.3 | Anomaly evaluation | Session analytics, behavior monitoring |
| CC7.4 | Incident response | Audit trails, session recordings |

#### Availability

| Criteria | Description | WALLIX Control |
|----------|-------------|----------------|
| A1.1 | Capacity management | Scalable architecture, performance monitoring |
| A1.2 | Backup and recovery | Configuration backup, disaster recovery |
| A1.3 | Recovery testing | Backup verification procedures |

#### Confidentiality

| Criteria | Description | WALLIX Control |
|----------|-------------|----------------|
| C1.1 | Confidential data identification | Credential classification, target grouping |
| C1.2 | Confidential data destruction | Secure credential rotation, session purging |

### Evidence Collection for SOC 2

```bash
# User access list and permissions
wabadmin users --export --format csv > soc2/cc6.1-user-list.csv
wabadmin authorizations --export > soc2/cc6.1-authorizations.csv

# User provisioning/deprovisioning log
wabadmin audit --filter "event_type IN (user_create,user_delete,user_disable)" \
  --period "audit-period" --export > soc2/cc6.2-user-lifecycle.csv

# Access control policy documentation
wabadmin policies --export > soc2/cc6.6-access-policies.csv

# Session monitoring evidence
wabadmin sessions --period "audit-period" --export > soc2/cc7.2-sessions.csv

# Security incident log
wabadmin audit --filter "severity=high" --period "audit-period" \
  --export > soc2/cc7.3-security-events.csv

# Backup verification records
wabadmin backup --list > soc2/a1.2-backup-list.csv
```

---

## ISO 27001

### Overview

ISO 27001 is an international standard for information security management systems (ISMS).

### Annex A Control Mapping

#### A.9 Access Control

| Control | Description | WALLIX Implementation |
|---------|-------------|----------------------|
| A.9.1.1 | Access control policy | Documented authorization policies |
| A.9.1.2 | Network access control | Jump host architecture, VIP access |
| A.9.2.1 | User registration | Automated provisioning from AD/LDAP |
| A.9.2.2 | Access provisioning | Authorization workflow, approval process |
| A.9.2.3 | Privileged access management | Core WALLIX functionality |
| A.9.2.4 | Secret authentication | Password vault, credential injection |
| A.9.2.5 | Access rights review | Audit reports, access review tools |
| A.9.2.6 | Access removal/adjustment | Deprovisioning, authorization modification |
| A.9.4.1 | Information access restriction | Target-based access control |
| A.9.4.2 | Secure logon procedures | MFA, session policies |
| A.9.4.3 | Password management | Vault, rotation, complexity enforcement |
| A.9.4.4 | Use of privileged utilities | Controlled through session policies |

#### A.10 Cryptography

| Control | Description | WALLIX Implementation |
|---------|-------------|----------------------|
| A.10.1.1 | Policy on cryptography | TLS 1.3, AES-256-GCM, Argon2ID |
| A.10.1.2 | Key management | Certificate management, key rotation |

#### A.12 Operations Security

| Control | Description | WALLIX Implementation |
|---------|-------------|----------------------|
| A.12.4.1 | Event logging | Comprehensive audit logging |
| A.12.4.2 | Log protection | Tamper-evident logs, secure storage |
| A.12.4.3 | Admin/operator logs | Session recording, keystroke logging |
| A.12.4.4 | Clock synchronization | NTP integration |

### Evidence Collection for ISO 27001

```bash
# A.9.2.3 - Privileged access inventory
wabadmin accounts --privileged --export > iso27001/a923-privileged-accounts.csv

# A.9.2.5 - Access review report
wabadmin report --type access-review --period quarterly \
  --export > iso27001/a925-access-review.csv

# A.12.4.1 - Audit log sample
wabadmin audit --period "audit-period" --sample 1000 \
  --export > iso27001/a1241-audit-sample.csv

# A.12.4.3 - Administrative action log
wabadmin audit --filter "event_type=admin_action" --period "audit-period" \
  --export > iso27001/a1243-admin-actions.csv
```

---

## PCI-DSS

### Overview

Payment Card Industry Data Security Standard (PCI-DSS) applies to organizations handling cardholder data.

### Requirement Mapping

#### Requirement 7: Restrict Access to Cardholder Data

| Requirement | Description | WALLIX Control |
|-------------|-------------|----------------|
| 7.1 | Limit access to system components | Target group restrictions, authorizations |
| 7.1.1 | Define access needs | Authorization policies, least privilege |
| 7.1.2 | Privileged user access restriction | Role-based access, approval workflows |
| 7.1.3 | Default deny access | Authorization required for all access |
| 7.2 | Access control systems | WALLIX Bastion core functionality |
| 7.2.1 | Coverage of all system components | All access through Bastion |
| 7.2.2 | Assignment based on job classification | Group-based authorizations |
| 7.2.3 | Default "deny-all" setting | No implicit access rights |

#### Requirement 8: Identify Users and Authenticate Access

| Requirement | Description | WALLIX Control |
|-------------|-------------|----------------|
| 8.1 | Unique user identification | Individual user accounts |
| 8.1.5 | Manage third-party access | Vendor accounts, time-limited access |
| 8.2 | Strong authentication | MFA support, password policies |
| 8.2.3 | Password complexity | Vault password policies |
| 8.2.4 | Password changes | Automatic rotation |
| 8.5 | Shared account prohibition | Individual accounts, credential injection |
| 8.6 | Authentication mechanisms | SSH keys, certificates, tokens |

#### Requirement 10: Track and Monitor Access

| Requirement | Description | WALLIX Control |
|-------------|-------------|----------------|
| 10.1 | Audit trails for access | Session logging, audit trail |
| 10.2 | Automated audit trails | Automatic logging of all sessions |
| 10.2.1 | Individual access to CHD | Session recordings per user |
| 10.2.2 | Root/admin actions | Privileged session recording |
| 10.2.4 | Invalid access attempts | Failed authentication logging |
| 10.2.5 | Changes to authentication | Credential change logging |
| 10.3 | Audit log elements | Complete audit data capture |
| 10.5 | Secure audit trails | Tamper-evident logging |
| 10.7 | Log retention | Configurable retention (1+ year) |

### Evidence Collection for PCI-DSS

```bash
# Requirement 7 - Access control evidence
wabadmin authorizations --export > pci/req7-authorizations.csv
wabadmin users --with-authorizations --export > pci/req7-user-access.csv

# Requirement 8 - Authentication evidence
wabadmin audit --filter "event_type=authentication" \
  --period "audit-period" --export > pci/req8-authentications.csv
wabadmin mfa-status --export > pci/req8-mfa-status.csv

# Requirement 10 - Audit log evidence
wabadmin audit --period "audit-period" --export > pci/req10-audit-log.csv
wabadmin sessions --period "audit-period" --export > pci/req10-sessions.csv

# Generate compliance report
wabadmin report --type pci-dss --period quarterly \
  --output pci/pci-dss-report.pdf
```

---

## HIPAA/HITECH

### Overview

Health Insurance Portability and Accountability Act (HIPAA) and HITECH apply to protected health information (PHI).

### Security Rule Mapping

#### Administrative Safeguards (§164.308)

| Standard | Description | WALLIX Control |
|----------|-------------|----------------|
| (a)(3) | Workforce security | User management, access control |
| (a)(4) | Access management | Authorization, least privilege |
| (a)(5) | Security awareness | Audit trails, monitoring |
| (a)(6) | Security incidents | Incident logging, session recording |

#### Technical Safeguards (§164.312)

| Standard | Description | WALLIX Control |
|----------|-------------|----------------|
| (a)(1) | Access control | Role-based access, authorizations |
| (a)(2)(i) | Unique user ID | Individual accounts |
| (a)(2)(ii) | Emergency access | Break-glass procedures |
| (a)(2)(iii) | Automatic logoff | Session timeout policies |
| (a)(2)(iv) | Encryption | TLS, AES-256 encryption |
| (b) | Audit controls | Comprehensive audit logging |
| (c)(1) | Integrity controls | Tamper-evident logs, checksums |
| (d) | Person authentication | MFA, strong authentication |
| (e)(1) | Transmission security | TLS 1.3, encrypted sessions |

### Evidence Collection for HIPAA

```bash
# §164.312(a) - Access control evidence
wabadmin authorizations --filter "target_group=phi-systems" \
  --export > hipaa/312a-access-controls.csv

# §164.312(b) - Audit controls
wabadmin audit --filter "target_group=phi-systems" --period "audit-period" \
  --export > hipaa/312b-audit-log.csv

# §164.312(d) - Authentication
wabadmin audit --filter "event_type=authentication,target_group=phi-systems" \
  --period "audit-period" --export > hipaa/312d-authentication.csv

# Access review for PHI systems
wabadmin report --type access-review --filter "target_group=phi-systems" \
  --output hipaa/access-review.pdf
```

---

## GDPR

### Overview

General Data Protection Regulation (GDPR) governs personal data protection in the EU.

### Article Mapping

#### Article 25: Data Protection by Design

| Requirement | Description | WALLIX Control |
|-------------|-------------|----------------|
| Pseudonymization | Data protection technique | Credential injection (no password exposure) |
| Data minimization | Limit data collection | Access logging only necessary data |
| Access controls | Restrict data access | Authorization-based access |

#### Article 32: Security of Processing

| Requirement | Description | WALLIX Control |
|-------------|-------------|----------------|
| (a) | Pseudonymization and encryption | Credential vault, TLS encryption |
| (b) | Confidentiality, integrity | Access control, audit trails |
| (c) | Availability, resilience | HA clustering, disaster recovery |
| (d) | Regular testing | Backup verification, DR tests |

#### Article 33: Breach Notification

| Requirement | Description | WALLIX Control |
|-------------|-------------|----------------|
| Detection | Identify breaches | Audit logging, session monitoring |
| Investigation | Determine scope | Session recordings, audit export |
| Timeline | 72-hour notification | Alert integration, reporting |

### Right to Be Forgotten (Article 17)

```bash
# Identify all data for a user
wabadmin audit --filter "user=<username>" --all --export > gdpr/user-data.csv
wabadmin sessions --filter "user=<username>" --all --list

# Delete user data (after retention period)
wabadmin user delete <username> --purge-data

# Verify deletion
wabadmin audit --filter "user=<username>" --verify-deleted
```

### Data Subject Access Request (Article 15)

```bash
# Export all user activity data
wabadmin report --type user-activity --user <username> \
  --all --output dsar/user-activity-report.pdf

# Include session metadata (not recordings - may contain third-party data)
wabadmin sessions --filter "user=<username>" --metadata-only \
  --export > dsar/session-metadata.csv
```

---

## NIS2 Directive

### Overview

Network and Information Security Directive 2 (NIS2) is an EU directive for essential and important entities.

### Article 21 Mapping

| Measure | Description | WALLIX Control |
|---------|-------------|----------------|
| (a) | Risk analysis policies | Documented access policies |
| (b) | Incident handling | Audit logs, session recordings |
| (c) | Business continuity | HA, backup, disaster recovery |
| (d) | Supply chain security | Vendor access control |
| (e) | Security in procurement | Controlled deployment |
| (f) | Vulnerability management | Security monitoring |
| (g) | Security effectiveness | Compliance reporting |
| (h) | Cryptography | TLS 1.3, AES-256 encryption |
| (i) | Human resources security | Access control, offboarding |
| (j) | Access control | Core PAM functionality |

### Evidence for NIS2 Compliance

```bash
# Article 21(b) - Incident handling
wabadmin audit --filter "severity IN (high,critical)" \
  --period "audit-period" --export > nis2/incident-log.csv

# Article 21(c) - Business continuity
wabadmin backup --list --verify > nis2/backup-status.csv
crm status > nis2/cluster-status.txt

# Article 21(j) - Access control
wabadmin authorizations --export > nis2/access-controls.csv
wabadmin users --with-roles --export > nis2/user-roles.csv
```

---

## NIST Cybersecurity Framework

### Framework Mapping

#### Identify (ID)

| Subcategory | Description | WALLIX Control |
|-------------|-------------|----------------|
| ID.AM-1 | Physical devices inventory | Device management |
| ID.AM-2 | Software inventory | Account management |
| ID.AM-5 | Resource prioritization | Target group classification |
| ID.AM-6 | Cybersecurity roles | Role-based access control |

#### Protect (PR)

| Subcategory | Description | WALLIX Control |
|-------------|-------------|----------------|
| PR.AC-1 | Identity management | User provisioning, authentication |
| PR.AC-3 | Remote access management | Core PAM functionality |
| PR.AC-4 | Access permissions | Authorizations, least privilege |
| PR.AC-6 | Identity proofing | MFA, strong authentication |
| PR.AC-7 | Authentication | Multi-factor authentication |
| PR.DS-1 | Data-at-rest protection | Credential vault encryption |
| PR.DS-2 | Data-in-transit protection | TLS 1.3 encryption |
| PR.DS-5 | Data leak protection | Session controls, clipboard policies |
| PR.PT-1 | Audit log protection | Tamper-evident logging |
| PR.PT-3 | Least functionality | Controlled access paths |

#### Detect (DE)

| Subcategory | Description | WALLIX Control |
|-------------|-------------|----------------|
| DE.AE-1 | Network baseline | Session monitoring |
| DE.AE-3 | Event data aggregation | Centralized logging, SIEM integration |
| DE.CM-1 | Network monitoring | Session monitoring |
| DE.CM-3 | Personnel activity monitoring | Session recording |
| DE.CM-7 | Unauthorized activity detection | Authorization enforcement, alerts |
| DE.DP-4 | Event detection communication | Alert notifications |

#### Respond (RS)

| Subcategory | Description | WALLIX Control |
|-------------|-------------|----------------|
| RS.AN-1 | Notifications investigated | Audit log analysis |
| RS.AN-3 | Forensics performed | Session recordings |
| RS.MI-1 | Incident containment | Session termination, access revocation |

#### Recover (RC)

| Subcategory | Description | WALLIX Control |
|-------------|-------------|----------------|
| RC.RP-1 | Recovery plan execution | Backup restoration |

---

## IEC 62443 Compliance

### IEC 62443 Control Mapping

```
+===============================================================================+
|                   IEC 62443 CONTROL MAPPING                                  |
+===============================================================================+

  FOUNDATIONAL REQUIREMENTS (FR)
  ==============================

  FR1 - Identification and Authentication Control (IAC)
  +------------------------------------------------------------------------+
  | Control ID | Requirement                    | WALLIX Implementation     |
  +------------+--------------------------------+---------------------------+
  | IAC-1      | Human user identification      | User accounts, AD/LDAP    |
  | IAC-2      | Software process identification| Service accounts          |
  | IAC-3      | Hardware device identification | Device management         |
  | IAC-4      | Human user authentication      | MFA, strong passwords     |
  | IAC-5      | Software process authentication| API keys, certificates    |
  | IAC-6      | Hardware device authentication | Certificate auth          |
  | IAC-7      | Password-based authentication  | Vault, rotation           |
  | IAC-8      | Public key-based authentication| SSH keys, certificates    |
  | IAC-9      | Authenticator management       | Credential lifecycle      |
  | IAC-10     | Authenticator feedback         | Secure credential display |
  | IAC-11     | Unsuccessful login attempts    | Account lockout           |
  | IAC-12     | System use notification        | Login banners             |
  | IAC-13     | Access via untrusted networks  | Proxy through DMZ         |
  | IAC-14     | Strength of authentication     | MFA enforcement           |
  +------------+--------------------------------+---------------------------+

  FR2 - Use Control (UC)
  +------------------------------------------------------------------------+
  | Control ID | Requirement                    | WALLIX Implementation     |
  +------------+--------------------------------+---------------------------+
  | UC-1       | Authorization enforcement      | RBAC, authorizations      |
  | UC-2       | Wireless use control           | Network segmentation      |
  | UC-3       | Use control for portable media | Session restrictions      |
  | UC-4       | Use control for mobile code    | Protocol restrictions     |
  | UC-5       | Session lock                   | Idle timeout              |
  | UC-6       | Session termination            | Auto-termination          |
  | UC-7       | Concurrent session control     | Session limits            |
  | UC-8       | Auditable events               | Session recording         |
  | UC-9       | Audit storage capacity         | Recording storage         |
  | UC-10      | Response to audit failures     | Alerting                  |
  | UC-11      | Time stamps                    | NTP synchronization       |
  | UC-12      | Non-repudiation                | Audit logs, recordings    |
  +------------+--------------------------------+---------------------------+

  FR3 - System Integrity (SI)
  +------------------------------------------------------------------------+
  | Control ID | Requirement                    | WALLIX Implementation     |
  +------------+--------------------------------+---------------------------+
  | SI-1       | Communication integrity        | TLS 1.3 encryption        |
  | SI-2       | Malicious code protection      | Session isolation         |
  | SI-3       | Security functionality verify  | Health checks             |
  | SI-4       | Software and info integrity    | Checksums, signing        |
  | SI-5       | Input validation               | Protocol validation       |
  | SI-6       | Deterministic output           | Consistent responses      |
  | SI-7       | Error handling                 | Secure error handling     |
  +------------+--------------------------------+---------------------------+

  FR4 - Data Confidentiality (DC)
  +------------------------------------------------------------------------+
  | Control ID | Requirement                    | WALLIX Implementation     |
  +------------+--------------------------------+---------------------------+
  | DC-1       | Information confidentiality    | Credential vault, AES-256 |
  | DC-2       | Access control                 | Authorization policies    |
  | DC-3       | Use of cryptography            | TLS, AES, Argon2ID        |
  | DC-4       | Public key infrastructure      | Certificate management    |
  +------------+--------------------------------+---------------------------+

  FR5 - Restricted Data Flow (RDF)
  +------------------------------------------------------------------------+
  | Control ID | Requirement                    | WALLIX Implementation     |
  +------------+--------------------------------+---------------------------+
  | RDF-1      | Network segmentation           | Zone-based deployment     |
  | RDF-2      | Zone boundary protection       | Proxy architecture        |
  | RDF-3      | General-purpose person-person  | Session monitoring        |
  | RDF-4      | Application partitioning       | Isolated sessions         |
  | RDF-5      | Session authenticity           | Session authentication    |
  +------------+--------------------------------+---------------------------+

  FR6 - Timely Response to Events (TRE)
  +------------------------------------------------------------------------+
  | Control ID | Requirement                    | WALLIX Implementation     |
  +------------+--------------------------------+---------------------------+
  | TRE-1      | Audit log accessibility        | Centralized logging       |
  | TRE-2      | Continuous monitoring          | Real-time session monitor |
  | TRE-3      | Response mechanisms            | Session termination       |
  +------------+--------------------------------+---------------------------+

  FR7 - Resource Availability (RA)
  +------------------------------------------------------------------------+
  | Control ID | Requirement                    | WALLIX Implementation     |
  +------------+--------------------------------+---------------------------+
  | RA-1       | Denial-of-service protection   | Rate limiting             |
  | RA-2       | Resource management            | Capacity planning         |
  | RA-3       | Control system backup          | Configuration backup      |
  | RA-4       | Control system recovery        | DR procedures             |
  | RA-5       | Emergency power                | UPS integration           |
  | RA-6       | Network and security config    | HA clustering             |
  | RA-7       | Least functionality            | Minimal services          |
  +------------+--------------------------------+---------------------------+

+===============================================================================+
```

### Security Level (SL) Requirements

```
+===============================================================================+
|                   IEC 62443 SECURITY LEVELS                                  |
+===============================================================================+

  SECURITY LEVEL DEFINITIONS
  ==========================

  +------------------------------------------------------------------------+
  | SL   | Description                   | Threat Profile                  |
  +------+-------------------------------+---------------------------------+
  | SL 1 | Protection against casual     | Low capability, motivation      |
  |      | or coincidental violation     | Insider threats                 |
  +------+-------------------------------+---------------------------------+
  | SL 2 | Protection against            | Moderate capability             |
  |      | intentional violation         | Generic attack tools            |
  +------+-------------------------------+---------------------------------+
  | SL 3 | Protection against            | High capability, sophistication |
  |      | sophisticated means           | Targeted attacks                |
  +------+-------------------------------+---------------------------------+
  | SL 4 | Protection against            | Nation-state level              |
  |      | state-sponsored attacks       | Custom exploits, 0-days         |
  +------+-------------------------------+---------------------------------+

  --------------------------------------------------------------------------

  WALLIX CONFIGURATION BY SECURITY LEVEL
  ======================================

  SL 1 - Basic Protection:
  +------------------------------------------------------------------------+
  | [ ] User authentication (username/password)                            |
  | [ ] Basic role-based access control                                    |
  | [ ] Session logging enabled                                            |
  | [ ] Password rotation (90-day)                                         |
  | [ ] TLS 1.2+ for web interface                                         |
  +------------------------------------------------------------------------+

  SL 2 - Moderate Protection:
  +------------------------------------------------------------------------+
  | [ ] All SL 1 requirements PLUS:                                        |
  | [ ] MFA required for all users                                         |
  | [ ] Session recording enabled                                          |
  | [ ] Approval workflows for sensitive access                            |
  | [ ] Password rotation (30-day)                                         |
  | [ ] SIEM integration                                                   |
  | [ ] TLS 1.3 enforcement                                                |
  +------------------------------------------------------------------------+

  SL 3 - High Protection:
  +------------------------------------------------------------------------+
  | [ ] All SL 2 requirements PLUS:                                        |
  | [ ] Hardware MFA (FortiToken)                                     |
  | [ ] HA cluster deployment                                              |
  | [ ] Session recording with OCR/keystroke logging                       |
  | [ ] Time-based access restrictions                                     |
  | [ ] Command restrictions/blocking                                      |
  | [ ] Real-time session monitoring                                       |
  | [ ] Encrypted storage (at-rest)                                        |
  | [ ] Network segmentation (OT zones)                                    |
  +------------------------------------------------------------------------+

  SL 4 - Maximum Protection:
  +------------------------------------------------------------------------+
  | [ ] All SL 3 requirements PLUS:                                        |
  | [ ] Multi-factor with biometrics                                       |
  | [ ] Four-eyes approval requirement                                     |
  | [ ] HSM for key management                                             |
  | [ ] Air-gapped backup systems                                          |
  | [ ] Continuous security monitoring                                     |
  | [ ] Penetration testing (quarterly)                                    |
  | [ ] Zero-trust network architecture                                    |
  | [ ] Physical security integration                                      |
  +------------------------------------------------------------------------+

+===============================================================================+
```

---

## CIS Controls Mapping

### CIS Controls v8 Mapping

```
+===============================================================================+
|                   CIS CONTROLS V8 MAPPING                                    |
+===============================================================================+

  IMPLEMENTATION GROUP 1 (IG1) - Essential
  =========================================

  +------------------------------------------------------------------------+
  | Control | Description                    | WALLIX Implementation        |
  +---------+--------------------------------+------------------------------+
  | 5.1     | Establish account management   | User provisioning, lifecycle |
  | 5.2     | Use unique passwords           | Vault, password policies     |
  | 5.3     | Disable dormant accounts       | Access review, auto-disable  |
  | 5.4     | Restrict admin privileges      | Least privilege, RBAC        |
  | 6.1     | Establish access granting proc | Authorization workflows      |
  | 6.2     | Establish access revoking proc | Deprovisioning procedures    |
  | 6.3     | Require MFA for ext access     | MFA for all external users   |
  | 6.4     | Require MFA for admin access   | MFA for administrators       |
  | 6.5     | Require MFA for remote access  | MFA for all remote access    |
  | 8.1     | Establish audit log management | Centralized logging          |
  | 8.2     | Collect audit logs             | Session logs, audit trail    |
  | 8.3     | Ensure adequate log storage    | Recording storage            |
  +---------+--------------------------------+------------------------------+

  IMPLEMENTATION GROUP 2 (IG2) - Foundational
  ===========================================

  +------------------------------------------------------------------------+
  | Control | Description                    | WALLIX Implementation        |
  +---------+--------------------------------+------------------------------+
  | 5.5     | Establish/maintain inventory   | Device/account inventory     |
  | 5.6     | Centralize account management  | AD/LDAP integration          |
  | 6.6     | Establish/maintain access ACL  | Authorization policies       |
  | 6.7     | Centralize access control      | Single PAM solution          |
  | 6.8     | Define/maintain RBAC           | User groups, target groups   |
  | 8.4     | Standardize time sync          | NTP configuration            |
  | 8.5     | Collect detailed audit logs    | Keystroke, command logging   |
  | 8.6     | Collect DNS query audit logs   | Protocol logging             |
  | 8.7     | Collect URL request audit logs | HTTP session logging         |
  | 8.9     | Centralize audit logs          | SIEM integration             |
  | 8.10    | Retain audit logs              | Configurable retention       |
  | 8.11    | Conduct audit log reviews      | Reporting, dashboards        |
  +---------+--------------------------------+------------------------------+

  IMPLEMENTATION GROUP 3 (IG3) - Organizational
  =============================================

  +------------------------------------------------------------------------+
  | Control | Description                    | WALLIX Implementation        |
  +---------+--------------------------------+------------------------------+
  | 8.12    | Collect admin service logs     | Admin session recording      |
  | 12.1    | Maintain network infra mgmt    | Network device PAM           |
  | 12.7    | Maintain portable endpoints    | Jump host architecture       |
  | 13.6    | Deploy DLP                     | Session controls, blocking   |
  | 16.8    | Separate prod/non-prod         | Domain separation            |
  | 16.12   | Implement app logging          | API audit logging            |
  +---------+--------------------------------+------------------------------+

+===============================================================================+
```

---

## Evidence Collection Procedures

### Automated Evidence Collection Script

```bash
#!/bin/bash
# /opt/scripts/collect-compliance-evidence.sh

EVIDENCE_DIR="/evidence/$(date +%Y-%m)"
PERIOD="$(date -d '3 months ago' +%Y-%m-%d),$(date +%Y-%m-%d)"

mkdir -p "${EVIDENCE_DIR}"

echo "Collecting compliance evidence for period: ${PERIOD}"

# User and access control evidence
echo "Collecting user and access data..."
wabadmin users --export > "${EVIDENCE_DIR}/users.csv"
wabadmin authorizations --export > "${EVIDENCE_DIR}/authorizations.csv"
wabadmin groups --export > "${EVIDENCE_DIR}/groups.csv"

# Session evidence
echo "Collecting session data..."
wabadmin sessions --period "${PERIOD}" --export > "${EVIDENCE_DIR}/sessions.csv"
wabadmin sessions --period "${PERIOD}" --summary > "${EVIDENCE_DIR}/session-summary.csv"

# Audit log evidence
echo "Collecting audit logs..."
wabadmin audit --period "${PERIOD}" --export > "${EVIDENCE_DIR}/audit-log.csv"
wabadmin audit --period "${PERIOD}" --filter "event_type=authentication" \
  --export > "${EVIDENCE_DIR}/authentications.csv"
wabadmin audit --period "${PERIOD}" --filter "event_type=admin_action" \
  --export > "${EVIDENCE_DIR}/admin-actions.csv"

# Password management evidence
echo "Collecting password management data..."
wabadmin accounts --export > "${EVIDENCE_DIR}/accounts.csv"
wabadmin rotation --history --period "${PERIOD}" \
  --export > "${EVIDENCE_DIR}/password-rotations.csv"

# Configuration evidence
echo "Collecting configuration..."
wabadmin policies --export > "${EVIDENCE_DIR}/policies.csv"
wabadmin config --export > "${EVIDENCE_DIR}/configuration.json"

# System status
echo "Collecting system status..."
wabadmin status --full > "${EVIDENCE_DIR}/system-status.txt"
wabadmin license-info > "${EVIDENCE_DIR}/license-info.txt"

# Generate checksums
echo "Generating checksums..."
find "${EVIDENCE_DIR}" -type f -exec sha256sum {} \; \
  > "${EVIDENCE_DIR}/checksums.sha256"

echo "Evidence collection complete: ${EVIDENCE_DIR}"
```

### Evidence Retention Requirements

| Framework | Retention Period | Notes |
|-----------|------------------|-------|
| SOC 2 | 1 year minimum | Match audit period |
| ISO 27001 | 3 years | Per ISMS requirements |
| PCI-DSS | 1 year | Online, 1 year archive |
| HIPAA | 6 years | From creation or last effective date |
| GDPR | As needed | Per data retention policy |
| NIS2 | As required | Per national implementation |

---

## Audit Preparation Checklist

### Pre-Audit Preparation (30 days before)

```
□ Confirm audit scope and timeline
□ Identify key contacts and schedule availability
□ Review previous audit findings and remediation
□ Collect evidence for audit period
□ Verify documentation is current
□ Test backup and recovery procedures
□ Review access control policies
□ Conduct internal pre-audit review
```

### Documentation Checklist

```
□ Access control policies
□ Password management policies
□ Session recording policies
□ Incident response procedures
□ Backup and recovery procedures
□ Change management procedures
□ User provisioning/deprovisioning procedures
□ Access review procedures
□ System architecture diagrams
□ Network diagrams
□ Data flow diagrams
```

### Technical Evidence Checklist

```
□ User list with roles and permissions
□ Authorization matrix
□ Audit logs for audit period
□ Session logs for audit period
□ Password rotation records
□ Backup logs and verification records
□ System configuration export
□ Security patch status
□ Vulnerability scan results
□ Penetration test results (if applicable)
```

### Interview Preparation

| Topic | Key Points to Cover |
|-------|---------------------|
| Access Control | How users are provisioned, authorized, deprovisioned |
| Authentication | MFA implementation, password policies |
| Session Management | Recording, monitoring, termination |
| Credential Management | Vault security, rotation, checkout |
| Monitoring | Real-time alerts, log analysis |
| Incident Response | Detection, response, recovery |
| Change Management | How changes are approved and implemented |
| Backup/Recovery | Procedures, testing, verification |

### Common Auditor Questions

1. **How do you ensure only authorized users can access privileged accounts?**
   - Explain: Authorization model, approval workflows, RBAC

2. **How are privileged sessions monitored?**
   - Explain: Session recording, real-time monitoring, audit logging

3. **What happens when an employee leaves?**
   - Explain: Deprovisioning, access revocation, credential rotation

4. **How are credentials protected?**
   - Explain: Vault encryption, access controls, rotation

5. **How would you detect unauthorized access?**
   - Explain: Audit logging, alerts, session analysis

6. **How do you handle security incidents?**
   - Explain: Detection, response procedures, session recordings

---

## See Also

**Related Sections:**
- [37 - Compliance Evidence](../37-compliance-evidence/README.md) - Evidence collection and attestation
- [09 - Session Management](../09-session-management/README.md) - Audit trail and session recording
- [08 - Password Management](../08-password-management/README.md) - Credential governance

**Related Documentation:**
- [Install Guide: Security Hardening](/install/07-security-hardening.md) - Security configuration

**Official Resources:**
- [WALLIX Documentation](https://pam.wallix.one/documentation)

---

## Next Steps

You have completed the documentation series. Additional resources:

- [Installation Guide](../../install/README.md) - Multi-site deployment procedures
- [Pre-Production Lab](../../pre/README.md) - Test environment setup
- [Examples](../../examples/README.md) - Terraform, API, and automation examples
- [Main Documentation Index](../README.md) - Return to documentation home

---

*Document Version: 1.0*
*Last Updated: January 2026*
