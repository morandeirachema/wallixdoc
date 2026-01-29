# Learning Paths

## Role-Based Learning for WALLIX PAM4OT

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
  | [_] Read: 00-quick-start/README.md                                     |
  | [_] Read: 01-introduction/README.md (Overview section only)            |
  | [_] Practice: Login to WALLIX web portal                               |
  | [_] Practice: Navigate admin interface                                 |
  +------------------------------------------------------------------------+

  Module 2: Session Operations (1.5 hours)
  +------------------------------------------------------------------------+
  | [_] Read: 08-session-management/README.md                              |
  | [_] Practice: Launch an SSH session to a test target                   |
  | [_] Practice: Launch an RDP session to a test target                   |
  | [_] Practice: View your own session recording                          |
  | [_] Practice: Search for a specific session in audit                   |
  +------------------------------------------------------------------------+

  Module 3: User Support (1 hour)
  +------------------------------------------------------------------------+
  | [_] Read: 31-faq-known-issues/README.md                                |
  | [_] Read: 12-troubleshooting/README.md (Connection issues section)     |
  | [_] Practice: Help a test user reset their MFA                         |
  | [_] Practice: Verify why a user can't see a target                     |
  +------------------------------------------------------------------------+

  Module 4: Daily Monitoring (1 hour)
  +------------------------------------------------------------------------+
  | [_] Read: 30-operational-runbooks/README.md (Daily checks section)     |
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
  | [_] Read: 00-quick-start/README.md                                     |
  | [_] Read: 01-introduction/README.md (Complete)                         |
  | [_] Read: 02-architecture/README.md                                    |
  | [_] Read: 03-core-components/README.md                                 |
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
  | [_] Read: 04-configuration/README.md                                   |
  | [_] Read: 05-authentication/README.md                                  |
  | [_] Read: 06-authorization/README.md                                   |
  | [_] Practice: Create domain, devices, accounts                         |
  | [_] Practice: Configure LDAP authentication                            |
  | [_] Practice: Set up MFA (TOTP)                                        |
  | [_] Practice: Create user groups and target groups                     |
  | [_] Practice: Create authorizations with policies                      |
  +------------------------------------------------------------------------+

  Module 4: Password Management (2 hours)
  +------------------------------------------------------------------------+
  | [_] Read: 07-password-management/README.md                             |
  | [_] Practice: Configure password rotation policy                       |
  | [_] Practice: Trigger manual rotation                                  |
  | [_] Practice: Troubleshoot a rotation failure                          |
  | [_] Practice: Set up reconciliation account                            |
  +------------------------------------------------------------------------+

  Module 5: High Availability (2 hours)
  +------------------------------------------------------------------------+
  | [_] Read: 10-high-availability/README.md                               |
  | [_] Read: install/10-postgresql-streaming-replication.md               |
  | [_] Practice: Understand cluster status commands                       |
  | [_] Practice: Simulate failover in test environment                    |
  +------------------------------------------------------------------------+

  Module 6: Troubleshooting & Operations (2 hours)
  +------------------------------------------------------------------------+
  | [_] Read: 12-troubleshooting/README.md                                 |
  | [_] Read: 27-error-reference/README.md                                 |
  | [_] Read: 30-operational-runbooks/README.md                            |
  | [_] Practice: Diagnose connection failure                              |
  | [_] Practice: Analyze performance issue                                |
  | [_] Practice: Perform backup and test restore                          |
  +------------------------------------------------------------------------+

  Module 7: API & Automation (2 hours)
  +------------------------------------------------------------------------+
  | [_] Read: 09-api-automation/README.md                                  |
  | [_] Read: 26-api-reference/README.md                                   |
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
  | [_] Read: 00-quick-start/README.md                                     |
  | [_] Read: 01-introduction/README.md                                    |
  | [_] Read: 13-best-practices/README.md (Security sections)              |
  +------------------------------------------------------------------------+

  Module 2: Session Analysis (2 hours)
  +------------------------------------------------------------------------+
  | [_] Read: 08-session-management/README.md                              |
  | [_] Practice: Search sessions by user, date, target                    |
  | [_] Practice: Replay recorded session                                  |
  | [_] Practice: Search within session (OCR, command search)              |
  | [_] Practice: Export session for evidence                              |
  +------------------------------------------------------------------------+

  Module 3: Audit & Compliance (2 hours)
  +------------------------------------------------------------------------+
  | [_] Read: 33-compliance-audit/README.md                                |
  | [_] Read: 20-iec62443-compliance/README.md (if OT relevant)            |
  | [_] Practice: Generate compliance report                               |
  | [_] Practice: Export audit logs for SIEM                               |
  | [_] Practice: Review access certification report                       |
  +------------------------------------------------------------------------+

  Module 4: Incident Investigation (2 hours)
  +------------------------------------------------------------------------+
  | [_] Read: 32-incident-response/README.md                               |
  | [_] Practice: Investigate suspicious login                             |
  | [_] Practice: Trace user activity across sessions                      |
  | [_] Practice: Correlate WALLIX logs with SIEM alerts                   |
  | [_] Practice: Terminate session during incident                        |
  +------------------------------------------------------------------------+

  Module 5: SIEM Integration (1.5 hours)
  +------------------------------------------------------------------------+
  | [_] Read: 22-ot-integration/README.md (SIEM sections)                  |
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

## Path 4: OT Security Specialist (20-30 hours)

**Goal**: Secure industrial environments with PAM

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
  | [_] Read: 00-quick-start/README.md                                     |
  | [_] Read: 01-introduction/README.md                                    |
  | [_] Read: 02-architecture/README.md                                    |
  | [_] Read: 03-core-components/README.md                                 |
  +------------------------------------------------------------------------+

  Module 2: OT Security Fundamentals (6 hours)
  +------------------------------------------------------------------------+
  | [_] Read: ot/01-ot-fundamentals.md                                     |
  | [_] Read: ot/02-control-systems-101.md                                 |
  | [_] Read: ot/03-ot-vs-it-security.md                                   |
  | [_] Read: ot/04-industrial-protocols.md                                |
  | [_] Read: ot/05-ot-network-architecture.md                             |
  | [_] Read: ot/06-legacy-systems.md                                      |
  +------------------------------------------------------------------------+

  Module 3: OT Threat Landscape (4 hours)
  +------------------------------------------------------------------------+
  | [_] Read: ot/07-ot-threat-landscape.md                                 |
  | [_] Read: ot/08-ot-threat-modeling.md                                  |
  | [_] Read: ot/09-ot-incident-response.md                                |
  | [_] Read: 15-industrial-overview/README.md                             |
  +------------------------------------------------------------------------+

  Module 4: WALLIX for OT (4 hours)
  +------------------------------------------------------------------------+
  | [_] Read: 16-ot-architecture/README.md                                 |
  | [_] Read: 17-industrial-protocols/README.md                            |
  | [_] Read: 18-scada-ics-access/README.md                                |
  | [_] Read: 19-airgapped-environments/README.md                          |
  | [_] Practice: Design WALLIX deployment for IEC 62443 zones             |
  +------------------------------------------------------------------------+

  Module 5: Compliance & Standards (4 hours)
  +------------------------------------------------------------------------+
  | [_] Read: ot/10-iec62443-deep-dive.md                                  |
  | [_] Read: ot/11-regulatory-landscape.md                                |
  | [_] Read: 20-iec62443-compliance/README.md                             |
  | [_] Read: 33-compliance-audit/README.md (IEC 62443 sections)           |
  | [_] Practice: Map WALLIX controls to IEC 62443 requirements            |
  +------------------------------------------------------------------------+

  Module 6: OT Deployment & Operations (4 hours)
  +------------------------------------------------------------------------+
  | [_] Read: install/06-ot-network-config.md                              |
  | [_] Read: install/appliance-setup-guide.md (OT sections)               |
  | [_] Read: 21-industrial-use-cases/README.md                            |
  | [_] Read: 22-ot-integration/README.md                                  |
  | [_] Read: 23-industrial-best-practices/README.md                       |
  | [_] Practice: Configure Universal Tunneling for OT protocol            |
  +------------------------------------------------------------------------+

  Module 7: Vendor & Risk Management (3 hours)
  +------------------------------------------------------------------------+
  | [_] Read: ot/12-vendor-risk-management.md                              |
  | [_] Read: 30-operational-runbooks/README.md (Vendor sections)          |
  | [_] Practice: Set up time-limited vendor access                        |
  | [_] Practice: Monitor vendor session in real-time                      |
  +------------------------------------------------------------------------+

  Module 8: Hands-On Labs (4 hours)
  +------------------------------------------------------------------------+
  | [_] Read: ot/14-hands-on-labs.md                                       |
  | [_] Practice: Set up home lab with OT simulation                       |
  | [_] Practice: Configure Modbus access through WALLIX                   |
  | [_] Practice: Incident response drill with OT target                   |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  COMPETENCY CHECKPOINT
  =====================

  Can you:
  [_] Explain OT vs IT security differences?
  [_] Design WALLIX architecture for IEC 62443 zones?
  [_] Configure access to industrial protocols (Modbus, OPC UA)?
  [_] Set up secure vendor remote access?
  [_] Map WALLIX capabilities to compliance requirements?
  [_] Respond to OT-specific security incidents?
  [_] Deploy WALLIX in air-gapped environment?

+===============================================================================+
```

---

## Path 5: DevOps Engineer (6-8 hours)

**Goal**: Automate WALLIX deployment and management

```
+===============================================================================+
|                   DEVOPS ENGINEER LEARNING PATH                               |
+===============================================================================+

  WHO IS THIS FOR?
  ================
  - Infrastructure automation engineers
  - CI/CD pipeline developers
  - Cloud infrastructure teams
  - Site reliability engineers (SRE)

  --------------------------------------------------------------------------

  LEARNING MODULES
  ================

  Module 1: WALLIX Fundamentals (2 hours)
  +------------------------------------------------------------------------+
  | [_] Read: 00-quick-start/README.md                                     |
  | [_] Read: 02-architecture/README.md                                    |
  | [_] Read: 03-core-components/README.md                                 |
  +------------------------------------------------------------------------+

  Module 2: API & Automation (2.5 hours)
  +------------------------------------------------------------------------+
  | [_] Read: 09-api-automation/README.md (Complete)                       |
  | [_] Read: 26-api-reference/README.md                                   |
  | [_] Practice: Authenticate to API                                      |
  | [_] Practice: CRUD operations on devices                               |
  | [_] Practice: Bulk operations via API                                  |
  +------------------------------------------------------------------------+

  Module 3: Infrastructure as Code (2 hours)
  +------------------------------------------------------------------------+
  | [_] Read: 24-cloud-deployment/README.md                                |
  | [_] Read: 25-container-deployment/README.md                            |
  | [_] Review: Terraform provider documentation                           |
  | [_] Practice: Deploy WALLIX resources with Terraform                   |
  | [_] Practice: Create Ansible playbook for configuration                |
  +------------------------------------------------------------------------+

  Module 4: CI/CD Integration (1.5 hours)
  +------------------------------------------------------------------------+
  | [_] Review: examples/devops/ (when created)                            |
  | [_] Practice: Auto-onboard servers from cloud provider                 |
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

### Level 4: OT PAM Specialist
- Complete OT Security Specialist Path
- Deploy WALLIX in OT environment
- Achieve IEC 62443 compliance mapping
- Conduct vendor access security review

---

## Recommended Reading Order for Everyone

If you only have 2 hours, read these in order:

1. **00-quick-start/README.md** (15 min) - Basic concepts
2. **03-core-components/README.md** (20 min) - What each part does
3. **04-configuration/README.md** (30 min) - How to configure
4. **12-troubleshooting/README.md** (30 min) - Common problems
5. **30-operational-runbooks/README.md** (25 min) - Daily operations

---

## Resources for Continued Learning

| Resource | URL |
|----------|-----|
| WALLIX Documentation | https://pam.wallix.one/documentation |
| WALLIX Support | https://support.wallix.com |
| OT Security Training | /ot/15-resources.md |
| API Samples | https://github.com/wallix/wbrest_samples |
| Terraform Provider | https://registry.terraform.io/providers/wallix/wallix-bastion |

---

<p align="center">
  <a href="./README.md">Quick Start</a> •
  <a href="../01-introduction/README.md">Introduction</a> •
  <a href="../../install/README.md">Installation</a>
</p>
