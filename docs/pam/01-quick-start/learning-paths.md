# Learning Paths

## Role-Based Learning for WALLIX Bastion

Choose your role to get a customized learning path. Each path includes estimated time and competency checkpoints.

---

## Path 1: Operator (4-6 hours)

**Goal**: Launch sessions, basic troubleshooting, daily monitoring

```
+===============================================================================+
|                   OPERATOR LEARNING PATH                                      |
+===============================================================================+

  WHO IS THIS FOR?
  ================
  - Help desk staff handling user requests
  - Operators who need to launch sessions for monitoring
  - First-line support for access issues

  --------------------------------------------------------------------------

  LEARNING MODULES
  ================

  Module 1: Fundamentals (1 hour)
  +------------------------------------------------------------------------+
  | [_] Read: 01-quick-start/README.md                                     |
  | [_] Read: 02-introduction/README.md (Overview section only)            |
  | [_] Practice: Login to WALLIX web portal                               |
  | [_] Practice: Navigate admin interface                                 |
  +------------------------------------------------------------------------+

  Module 2: Session Operations (1.5 hours)
  +------------------------------------------------------------------------+
  | [_] Read: 09-session-management/README.md                              |
  | [_] Practice: Launch an SSH session to a test target                   |
  | [_] Practice: Launch an RDP session to a test target                   |
  | [_] Practice: View your own session recording                          |
  | [_] Practice: Search for a specific session in audit                   |
  +------------------------------------------------------------------------+

  Module 3: User Support (1 hour)
  +------------------------------------------------------------------------+
  | [_] Read: 22-faq-known-issues/README.md                                |
  | [_] Read: 13-troubleshooting/README.md (Connection issues section)     |
  | [_] Practice: Help a test user reset their MFA                         |
  | [_] Practice: Verify why a user can't see a target                     |
  +------------------------------------------------------------------------+

  Module 4: Daily Monitoring (1 hour)
  +------------------------------------------------------------------------+
  | [_] Read: 21-operational-runbooks/README.md (Daily checks section)     |
  | [_] Practice: Run daily health check commands                          |
  | [_] Practice: Generate session report for today                        |
  | [_] Practice: Check for any failed password rotations                  |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  COMPETENCY CHECKPOINT
  =====================

  Can you:
  [_] Launch SSH and RDP sessions through WALLIX?
  [_] Find and replay a recorded session?
  [_] Explain why a user might not see their target?
  [_] Run basic health check commands?
  [_] Generate a session report for a specific date?

+===============================================================================+
```

---

## Path 2: System Engineer (12-16 hours)

**Goal**: Deploy, configure, troubleshoot, and maintain WALLIX

```
+===============================================================================+
|                   SYSTEM ENGINEER LEARNING PATH                               |
+===============================================================================+

  WHO IS THIS FOR?
  ================
  - Sysadmins responsible for WALLIX deployment
  - Engineers maintaining PAM infrastructure
  - Technical leads designing access architecture

  --------------------------------------------------------------------------

  LEARNING MODULES
  ================

  Module 1: Foundations (2 hours)
  +------------------------------------------------------------------------+
  | [_] Read: 01-quick-start/README.md                                     |
  | [_] Read: 02-introduction/README.md (Complete)                         |
  | [_] Read: 03-architecture/README.md                                    |
  | [_] Read: 04-core-components/README.md                                 |
  +------------------------------------------------------------------------+

  Module 2: Installation & Deployment (3 hours)
  +------------------------------------------------------------------------+
  | [_] Read: install/README.md                                            |
  | [_] Read: install/01-prerequisites.md                                  |
  | [_] Read: install/appliance-setup-guide.md                             |
  | [_] Practice: Deploy WALLIX in test environment                        |
  | [_] Practice: Complete post-installation validation                    |
  +------------------------------------------------------------------------+

  Module 3: Configuration Deep Dive (3 hours)
  +------------------------------------------------------------------------+
  | [_] Read: 05-configuration/README.md                                   |
  | [_] Read: 06-authentication/README.md                                  |
  | [_] Read: 07-authorization/README.md                                   |
  | [_] Practice: Create domain, devices, accounts                         |
  | [_] Practice: Configure LDAP authentication                            |
  | [_] Practice: Set up MFA (FortiToken)                                  |
  | [_] Practice: Create user groups and target groups                     |
  | [_] Practice: Create authorizations with policies                      |
  +------------------------------------------------------------------------+

  Module 4: Password Management (2 hours)
  +------------------------------------------------------------------------+
  | [_] Read: 08-password-management/README.md                             |
  | [_] Practice: Configure password rotation policy                       |
  | [_] Practice: Trigger manual rotation                                  |
  | [_] Practice: Troubleshoot a rotation failure                          |
  | [_] Practice: Set up reconciliation account                            |
  +------------------------------------------------------------------------+

  Module 5: High Availability (2 hours)
  +------------------------------------------------------------------------+
  | [_] Read: 11-high-availability/README.md                               |
  | [_] Read: install/10-mariadb-replication.md                            |
  | [_] Practice: Understand cluster status commands                       |
  | [_] Practice: Simulate failover in test environment                    |
  +------------------------------------------------------------------------+

  Module 6: Troubleshooting & Operations (2 hours)
  +------------------------------------------------------------------------+
  | [_] Read: 13-troubleshooting/README.md                                 |
  | [_] Read: 18-error-reference/README.md                                 |
  | [_] Read: 21-operational-runbooks/README.md                            |
  | [_] Practice: Diagnose connection failure                              |
  | [_] Practice: Analyze performance issue                                |
  | [_] Practice: Perform backup and test restore                          |
  +------------------------------------------------------------------------+

  Module 7: API & Automation (2 hours)
  +------------------------------------------------------------------------+
  | [_] Read: 10-api-automation/README.md                                  |
  | [_] Read: 17-api-reference/README.md                                   |
  | [_] Practice: Create device via API                                    |
  | [_] Practice: Query sessions via API                                   |
  | [_] Practice: Write script for bulk device import                      |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  COMPETENCY CHECKPOINT
  =====================

  Can you:
  [_] Deploy WALLIX from scratch?
  [_] Configure LDAP + MFA authentication?
  [_] Create complete authorization chain (user->target)?
  [_] Set up and troubleshoot password rotation?
  [_] Diagnose and resolve connection failures?
  [_] Perform backup and disaster recovery?
  [_] Automate tasks via API?

+===============================================================================+
```

---

## Path 3: Security Analyst (8-10 hours)

**Goal**: Audit, investigate, compliance reporting

```
+===============================================================================+
|                   SECURITY ANALYST LEARNING PATH                              |
+===============================================================================+

  WHO IS THIS FOR?
  ================
  - Security operations center (SOC) analysts
  - Compliance officers
  - Incident responders
  - Auditors

  --------------------------------------------------------------------------

  LEARNING MODULES
  ================

  Module 1: PAM Security Foundations (1.5 hours)
  +------------------------------------------------------------------------+
  | [_] Read: 01-quick-start/README.md                                     |
  | [_] Read: 02-introduction/README.md                                    |
  | [_] Read: 14-best-practices/README.md (Security sections)              |
  +------------------------------------------------------------------------+

  Module 2: Session Analysis (2 hours)
  +------------------------------------------------------------------------+
  | [_] Read: 09-session-management/README.md                              |
  | [_] Practice: Search sessions by user, date, target                    |
  | [_] Practice: Replay recorded session                                  |
  | [_] Practice: Search within session (OCR, command search)              |
  | [_] Practice: Export session for evidence                              |
  +------------------------------------------------------------------------+

  Module 3: Audit & Compliance (2 hours)
  +------------------------------------------------------------------------+
  | [_] Read: 24-compliance-audit/README.md                                |
  | [_] Read: 37-compliance-evidence/README.md                             |
  | [_] Practice: Generate compliance report                               |
  | [_] Practice: Export audit logs for SIEM                               |
  | [_] Practice: Review access certification report                       |
  +------------------------------------------------------------------------+

  Module 4: Incident Investigation (2 hours)
  +------------------------------------------------------------------------+
  | [_] Read: 23-incident-response/README.md                               |
  | [_] Practice: Investigate suspicious login                             |
  | [_] Practice: Trace user activity across sessions                      |
  | [_] Practice: Correlate WALLIX logs with SIEM alerts                   |
  | [_] Practice: Terminate session during incident                        |
  +------------------------------------------------------------------------+

  Module 5: SIEM Integration (1.5 hours)
  +------------------------------------------------------------------------+
  | [_] Read: 12-monitoring-observability/README.md (SIEM sections)        |
  | [_] Practice: Configure syslog forwarding                              |
  | [_] Practice: Create SIEM dashboard for WALLIX                         |
  | [_] Practice: Set up alerting rules                                    |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  COMPETENCY CHECKPOINT
  =====================

  Can you:
  [_] Find all sessions for a specific user in a date range?
  [_] Search session recordings for specific commands?
  [_] Generate compliance report for auditors?
  [_] Investigate a suspected unauthorized access?
  [_] Export evidence for incident response?
  [_] Configure SIEM integration and alerts?

+===============================================================================+
```

---

## Path 4: Fortigate MFA Specialist (6-8 hours)

**Goal**: Configure and manage Fortigate MFA integration

```
+===============================================================================+
|                   FORTIGATE MFA SPECIALIST LEARNING PATH                      |
+===============================================================================+

  WHO IS THIS FOR?
  ================
  - Network security engineers
  - MFA administrators
  - Fortinet specialists
  - Identity and access management (IAM) professionals

  --------------------------------------------------------------------------

  LEARNING MODULES
  ================

  Module 1: WALLIX Fundamentals (2 hours)
  +------------------------------------------------------------------------+
  | [_] Read: 01-quick-start/README.md                                     |
  | [_] Read: 03-architecture/README.md                                    |
  | [_] Read: 06-authentication/README.md                                  |
  +------------------------------------------------------------------------+

  Module 2: FortiAuthenticator Configuration (2 hours)
  +------------------------------------------------------------------------+
  | [_] Read: 06-authentication/fortiauthenticator-integration.md          |
  | [_] Read: 46-fortigate-integration/README.md                           |
  | [_] Practice: Configure RADIUS client on FortiAuthenticator            |
  | [_] Practice: Sync users from Active Directory                         |
  | [_] Practice: Provision FortiToken Mobile to users                     |
  +------------------------------------------------------------------------+

  Module 3: WALLIX MFA Integration (2 hours)
  +------------------------------------------------------------------------+
  | [_] Read: pre/04-fortiauthenticator-setup.md                           |
  | [_] Practice: Configure RADIUS server in WALLIX                        |
  | [_] Practice: Enable MFA policy for all users                          |
  | [_] Practice: Test MFA authentication                                  |
  | [_] Practice: Configure MFA bypass procedures                          |
  +------------------------------------------------------------------------+

  Module 4: Fortigate Firewall Integration (2 hours)
  +------------------------------------------------------------------------+
  | [_] Read: 46-fortigate-integration/README.md                           |
  | [_] Practice: Configure SSL VPN with FortiAuth                         |
  | [_] Practice: Set up firewall policies for WALLIX                      |
  | [_] Practice: Configure VIP for WALLIX access                          |
  | [_] Practice: Test end-to-end VPN + MFA + WALLIX flow                  |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  COMPETENCY CHECKPOINT
  =====================

  Can you:
  [_] Configure FortiAuthenticator as RADIUS server?
  [_] Provision FortiToken Mobile to users?
  [_] Integrate WALLIX with FortiAuthenticator MFA?
  [_] Configure Fortigate firewall policies for WALLIX?
  [_] Troubleshoot MFA authentication failures?
  [_] Set up emergency MFA bypass procedures?

+===============================================================================+
```

---

## Path 5: OT Security Specialist (20-30 hours)

**Goal**: Secure industrial environments with PAM

> **Note**: This learning path references OT/Industrial content. Contact WALLIX professional services for OT-specific deployment guidance.

```
+===============================================================================+
|                   OT SECURITY SPECIALIST LEARNING PATH                        |
+===============================================================================+

  WHO IS THIS FOR?
  ================
  - OT/ICS security engineers
  - Industrial control system administrators
  - Plant IT/OT convergence specialists
  - Critical infrastructure security professionals

  --------------------------------------------------------------------------

  LEARNING MODULES
  ================

  Module 1: PAM Foundations (3 hours)
  +------------------------------------------------------------------------+
  | [_] Read: 01-quick-start/README.md                                     |
  | [_] Read: 02-introduction/README.md                                    |
  | [_] Read: 03-architecture/README.md                                    |
  | [_] Read: 04-core-components/README.md                                 |
  +------------------------------------------------------------------------+

  Module 2: OT Security Fundamentals (6 hours)
  +------------------------------------------------------------------------+
  | [_] External: IEC 62443 standards documentation                        |
  | [_] External: NIST 800-82 Guide to ICS Security                        |
  | [_] External: SANS ICS security resources                              |
  | [_] Read: 14-best-practices/README.md (Security hardening)             |
  +------------------------------------------------------------------------+

  Module 3: OT Network Architecture (4 hours)
  +------------------------------------------------------------------------+
  | [_] External: Purdue Model / IEC 62443 zone architecture               |
  | [_] Read: 03-architecture/README.md (Zone deployment)                  |
  | [_] Practice: Design WALLIX deployment for industrial zones            |
  +------------------------------------------------------------------------+

  Module 4: Industrial Protocol Access (4 hours)
  +------------------------------------------------------------------------+
  | [_] Read: 09-session-management/README.md                              |
  | [_] Read: 27-vendor-integration/README.md                              |
  | [_] Practice: Configure Universal Tunneling for industrial protocols   |
  | [_] Practice: Set up secure vendor remote access                       |
  +------------------------------------------------------------------------+

  Module 5: Compliance & Standards (4 hours)
  +------------------------------------------------------------------------+
  | [_] Read: 24-compliance-audit/README.md                                |
  | [_] Read: 37-compliance-evidence/README.md                             |
  | [_] External: IEC 62443-3-3 security requirements                      |
  | [_] Practice: Map WALLIX controls to IEC 62443 requirements            |
  +------------------------------------------------------------------------+

  Module 6: OT Deployment & Operations (4 hours)
  +------------------------------------------------------------------------+
  | [_] Read: install/README.md                                            |
  | [_] Read: install/appliance-setup-guide.md                             |
  | [_] Read: 21-operational-runbooks/README.md                            |
  | [_] Practice: Deploy WALLIX in air-gapped test environment             |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  COMPETENCY CHECKPOINT
  =====================

  Can you:
  [_] Explain OT vs IT security differences?
  [_] Design WALLIX architecture for IEC 62443 zones?
  [_] Configure access to industrial protocols?
  [_] Set up secure vendor remote access?
  [_] Map WALLIX capabilities to compliance requirements?
  [_] Deploy WALLIX in isolated/air-gapped environment?

+===============================================================================+
```

---

## Path 6: DevOps Engineer (6-8 hours)

**Goal**: Automate WALLIX deployment and management

```
+===============================================================================+
|                   DEVOPS ENGINEER LEARNING PATH                               |
+===============================================================================+

  WHO IS THIS FOR?
  ================
  - Infrastructure automation engineers
  - CI/CD pipeline developers
  - Infrastructure teams
  - Site reliability engineers (SRE)

  --------------------------------------------------------------------------

  LEARNING MODULES
  ================

  Module 1: WALLIX Fundamentals (2 hours)
  +------------------------------------------------------------------------+
  | [_] Read: 01-quick-start/README.md                                     |
  | [_] Read: 03-architecture/README.md                                    |
  | [_] Read: 04-core-components/README.md                                 |
  +------------------------------------------------------------------------+

  Module 2: API & Automation (2.5 hours)
  +------------------------------------------------------------------------+
  | [_] Read: 10-api-automation/README.md (Complete)                       |
  | [_] Read: 17-api-reference/README.md                                   |
  | [_] Practice: Authenticate to API                                      |
  | [_] Practice: CRUD operations on devices                               |
  | [_] Practice: Bulk operations via API                                  |
  +------------------------------------------------------------------------+

  Module 3: Infrastructure as Code (2 hours)
  +------------------------------------------------------------------------+
  | [_] Read: 16-cloud-deployment/README.md (On-premises deployment)       |
  | [_] Review: Terraform provider documentation                           |
  | [_] Practice: Deploy WALLIX resources with Terraform                   |
  | [_] Practice: Create Ansible playbook for configuration                |
  +------------------------------------------------------------------------+

  Module 4: CI/CD Integration (1.5 hours)
  +------------------------------------------------------------------------+
  | [_] Review: examples/ansible/ playbooks                                |
  | [_] Practice: Auto-onboard servers from inventory                      |
  | [_] Practice: Integrate WALLIX provisioning in deployment pipeline     |
  | [_] Practice: Set up GitOps workflow for WALLIX config                 |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  COMPETENCY CHECKPOINT
  =====================

  Can you:
  [_] Automate device/account creation via API?
  [_] Deploy WALLIX infrastructure with Terraform?
  [_] Create Ansible playbook for WALLIX configuration?
  [_] Integrate WALLIX with CI/CD pipeline?
  [_] Implement auto-discovery and onboarding?

+===============================================================================+
```

---

## Certification Milestones

### Level 1: WALLIX Operator
- Complete Operator Path
- Pass competency checkpoint
- Handle 10 real user support requests

### Level 2: WALLIX Administrator
- Complete System Engineer Path
- Pass competency checkpoint
- Deploy WALLIX in test environment
- Resolve 5 real troubleshooting incidents

### Level 3: WALLIX Architect
- Complete System Engineer + Security Analyst paths
- Design multi-site HA architecture
- Create automation for full deployment
- Lead DR test successfully

### Level 4: Fortigate MFA Expert
- Complete Fortigate MFA Specialist Path
- Deploy WALLIX with Fortigate integration
- Configure SSL VPN + MFA authentication
- Document MFA procedures and runbooks

### Level 5: OT PAM Specialist
- Complete OT Security Specialist Path
- Deploy WALLIX in OT/industrial environment
- Achieve IEC 62443 compliance mapping
- Conduct vendor access security review

---

## Recommended Reading Order for Everyone

If you only have 2 hours, read these in order:

1. **01-quick-start/README.md** (15 min) - Basic concepts
2. **04-core-components/README.md** (20 min) - What each part does
3. **05-configuration/README.md** (30 min) - How to configure
4. **13-troubleshooting/README.md** (30 min) - Common problems
5. **21-operational-runbooks/README.md** (25 min) - Daily operations

---

## Resources for Continued Learning

| Resource | URL |
|----------|-----|
| WALLIX Documentation | https://pam.wallix.one/documentation |
| WALLIX Support | https://support.wallix.com |
| Fortigate MFA Integration | 46-fortigate-integration/README.md |
| API Samples | https://github.com/wallix/wbrest_samples |
| Terraform Provider | https://registry.terraform.io/providers/wallix/wallix-bastion |

---

<p align="center">
  <a href="./README.md">Quick Start</a> •
  <a href="../02-introduction/README.md">Introduction</a> •
  <a href="../../install/README.md">Installation</a>
</p>
