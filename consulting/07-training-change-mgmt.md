# Training & Change Management

## Operator Onboarding, Administrator Certification, and Adoption Planning

PAM deployments fail not because the technology stops working but because
people stop using it. Session recording is bypassed, break-glass accounts
become the default, and vendors get direct VPN access again "just this once."

This guide addresses the human side of the engagement. Read it alongside
`03-engagement-playbook.md`. The technical configuration is worthless
if adoption does not follow.

---

## Table of Contents

1. [Why Change Management Fails in PAM Projects](#1-why-change-management-fails-in-pam-projects)
2. [Stakeholder Map and RACI](#2-stakeholder-map-and-raci)
3. [Communication Plan](#3-communication-plan)
4. [Resistance Handling](#4-resistance-handling)
5. [Administrator Training Programme](#5-administrator-training-programme)
6. [Operator Training Programme](#6-operator-training-programme)
7. [Vendor and Third-Party Onboarding](#7-vendor-and-third-party-onboarding)
8. [Go-Live Readiness Checklist](#8-go-live-readiness-checklist)
9. [Hypercare Period](#9-hypercare-period)
10. [Adoption Metrics](#10-adoption-metrics)
11. [Training Materials Reference](#11-training-materials-reference)

---

## 1. Why Change Management Fails in PAM Projects

PAM introduces friction to workflows that previously had none. An engineer
who previously typed `ssh root@server` now types their credentials into a
portal, approves an MFA push, and connects through a proxy. The additional
steps are small. The perceived disruption is large.

Resistance follows a predictable pattern:

```
+===============================================================================+
|  ADOPTION CURVE IN PAM DEPLOYMENTS                                           |
+===============================================================================+
|                                                                               |
|  Pre-launch:   Awareness campaign begins. Early adopters engaged.            |
|  Go-live:      Compliance-driven users adopt. Resistors push back.           |
|  Week 2–4:     "It's broken" tickets peak. Most are user error.              |
|  Month 2:      Adoption stabilises. Workarounds emerge if not addressed.     |
|  Month 3+:     PAM is normal. Adoption is self-sustaining or permanently     |
|                damaged if early resistance was not managed.                  |
|                                                                               |
|  Intervention window: go-live through Week 4. This is where the             |
|  engagement team must be most visible and responsive.                        |
|                                                                               |
+===============================================================================+
```

The three most common failure modes in PAM adoption:

| Failure Mode | Symptom | Root Cause |
|-------------|---------|-----------|
| Bypass culture | Users share break-glass credentials for routine access | Go-live happened before training was complete |
| Passive resistance | Managers raise a stream of "blocking issues" | CISO sponsorship was not secured before launch |
| Token abandonment | Users claim tokens are broken; IT disables MFA | Token distribution and training were rushed |

---

## 2. Stakeholder Map and RACI

### 2.1 Stakeholder Map

Identify these roles at every client and assign a named individual to each.
A gap in any role creates a risk that must be mitigated.

| Role | Influence | Interest | Strategy |
|------|----------|---------|---------|
| CISO / Security Director | High | High | Sponsor and champion — keep informed, involve in decisions |
| IT Manager | High | Medium | Key enabler — must be convinced early; leads the admin team |
| Operations Manager | High | Low | Must be converted — owns operator workflow change |
| AD Administrator | Medium | High | Hands-on partner — critical for Phase 2 |
| Network / Firewall Admin | Medium | Low | Must-have for firewall rules — brief, give clear specs |
| Privileged users (IT admins) | Low | High | End-adopters — train well, provide quick reference |
| Control room operators (OT) | Low | Low | Most resistant group — need the simplest experience possible |
| Vendors / contractors | Low | Medium | External — JIT portal training sufficient |
| Compliance / audit team | Low | High | Stakeholders in the compliance evidence — brief monthly |

### 2.2 RACI Matrix

| Activity | CISO | IT Manager | AD Admin | Operations Mgr | Consultant |
|----------|------|-----------|---------|----------------|-----------|
| Project sponsorship and escalation | **A** | R | — | I | — |
| AD integration and user group config | I | A | **R** | — | C |
| Firewall rule approval | A | R | — | I | C |
| FortiToken procurement | I | **A** | — | I | C |
| Token distribution to operators | I | A | — | **R** | C |
| Operator training delivery | I | A | — | **R** | **R** |
| Admin training delivery | I | **A** | R | — | **R** |
| Go-live approval | **A** | R | — | R | C |
| Escalation of adoption issues | I | A | — | R | **R** |
| Hypercare support | I | **A** | — | — | **R** |

*R = Responsible, A = Accountable, C = Consulted, I = Informed*

---

## 3. Communication Plan

### 3.1 Message Architecture

Different audiences need different messages. Craft communications per
audience. Do not send the same email to operators and executives.

| Audience | Key Message | Tone | Channel |
|---------|------------|------|---------|
| Executives / CISO | Risk reduction achieved, compliance obligations met | Strategic, brief | Executive summary email / slide |
| IT managers | System is reliable, team is trained, support process is clear | Practical, confident | Email + briefing call |
| Privileged users | One extra step, clear instructions, support available | Supportive, simple | Email + training session |
| Control room operators | Minimal change, hardware token, no smartphone required | Reassuring, specific | In-person briefing |
| Vendors / contractors | How to request access, how to use the portal | Instructional | Email + written guide |

### 3.2 Communication Timeline

| Timeline | Event | Audience | Channel |
|---------|-------|---------|---------|
| 6 weeks before go-live | Project announcement | All staff in scope | Email from CISO |
| 4 weeks before go-live | "What is changing and why" briefing | IT managers, operations managers | Meeting |
| 3 weeks before go-live | Admin training sessions | AD admins, IT admins | Workshop |
| 2 weeks before go-live | Operator training sessions | All privileged users | Workshop per team |
| 1 week before go-live | "Go-live next week" reminder | All in scope | Email |
| 1 week before go-live | Token distribution complete | Operators only | In-person |
| Go-live day | "PAM is live" confirmation + support contact | All in scope | Email from IT Manager |
| Week 1 post-go-live | Daily check-in with IT Manager | IT Manager | Standup call (15 min) |
| Week 2 post-go-live | Adoption status report | CISO, IT Manager | Email summary |
| Month 1 post-go-live | First-month review meeting | CISO, IT Manager, Operations | Meeting |

### 3.3 Email Templates

**Announcement email (6 weeks before go-live):**

```
Subject: Privileged Access Management — Project Launch

Team,

As part of our ongoing commitment to securing our infrastructure, we are
deploying a Privileged Access Management (PAM) system across [SCOPE].

Starting on [DATE], access to [TARGET SYSTEMS] will be managed through
WALLIX Bastion. This means:

- Your existing Active Directory password continues to work.
- A second authentication step (a code from your hardware token or phone app)
  will be required.
- All sessions are recorded to meet our compliance obligations.

Training sessions will be scheduled for your team in the coming weeks.
The change is minimal. The security improvement is significant.

Questions? Contact [IT CONTACT NAME] at [EMAIL].

[CISO NAME]
```

**Go-live day email:**

```
Subject: PAM is live today — what you need to do

Team,

Starting today, access to [TARGET SYSTEMS] is managed through WALLIX Bastion.

How to connect:
  1. Open your browser and go to: https://[BASTION URL]
  2. Enter your Active Directory username and password.
  3. Enter the 6-digit code from your [FortiToken / FortiToken Mobile app].
  4. Select the system you need and click Connect.

If you have any issues:
  - First check: https://[INTERNAL WIKI / QUICK GUIDE URL]
  - Support contact: [NAME] — [EMAIL / PHONE]
  - During business hours, response within [N] hours.

[IT MANAGER NAME]
```

---

## 4. Resistance Handling

### 4.1 Types of Resistance

Resistance in PAM projects is almost always one of three types:

| Type | How It Presents | Underlying Cause | Response |
|------|----------------|-----------------|---------|
| Workflow disruption | "This adds time to everything I do." | Legitimate friction, under-trained | Acknowledge, reduce friction where possible, demonstrate value |
| Authority challenge | "I shouldn't need approval to access my own servers." | Loss of autonomy | Involve them in RBAC design; make the scope of control visible |
| Technology distrust | "This proxy will fail and I'll be locked out." | Past experience with unreliable tooling | Demonstrate HA, show break-glass procedure, offer a supervised pilot |

### 4.2 Escalation Path for Persistent Resistance

If an individual or team continues to bypass controls after training and
communication, escalation follows this path:

1. Consultant discusses the pattern with the IT Manager
2. IT Manager has a direct conversation with the resisting individual / team lead
3. If unresolved, CISO is informed — this is a compliance risk, not a preference
4. CISO or HR involvement if the bypass is deliberate and repeated

**Important:** Never let persistent resistance sit unaddressed past Week 2.
Workarounds become habits. Habits become policy.

### 4.3 Common Objections and Responses

| Objection | Response |
|-----------|----------|
| "The token is too slow / annoying." | "The extra step takes under 10 seconds. If you would like hardware token alternatives tested, we can run that comparison in pre-production." |
| "I need emergency access and PAM is in the way." | "That is exactly what the break-glass procedure covers. Let me walk you through it — it takes less than 2 minutes and you will have it memorised after one test run." |
| "My team will never accept this." | "Can we run a 30-minute session with your team to walk through the change before go-live? Resistance is almost always highest before training and drops significantly after a single demo." |
| "What if Bastion goes down?" | "Bastion is deployed in HA — two nodes with automatic failover. We test that failover before go-live, with you watching. Additionally, the break-glass procedure gives you direct access if both nodes fail simultaneously." |
| "This is for IT security, not for us." | "Session recording protects you. If anything goes wrong on a system you accessed, the recording proves exactly what you did — or did not — do. It is as much your protection as it is ours." |
| "We have been doing this for years without PAM." | "The threat landscape has changed significantly. The Colonial Pipeline attack in 2021 began with exactly the type of unmanaged privileged access your environment currently has. The question is not whether the risk is real — it is whether to address it now or after an incident." |

---

## 5. Administrator Training Programme

### 5.1 Training Audience

Administrator training targets the staff who will operate and maintain the
Bastion environment after the engagement ends. These are typically:

- IT administrators (WALLIX Bastion platform administration)
- AD / IAM team (user account lifecycle and group management)
- Security operations (alert management, session review, incident response)

### 5.2 Administrator Training Curriculum

| Module | Duration | Audience | Format |
|--------|----------|---------|--------|
| 1. Platform overview and architecture | 1h | All admins | Presentation + demo |
| 2. User and device management | 2h | IT admins | Hands-on workshop |
| 3. RBAC and authorisation policy | 1.5h | IT admins | Hands-on workshop |
| 4. Credential vault and rotation management | 1.5h | IT admins | Hands-on workshop |
| 5. Session recording review and search | 1h | IT admins, SecOps | Demo + exercise |
| 6. MFA and FortiAuthenticator management | 1h | IT admins, IAM | Demo + exercise |
| 7. JIT access and approval workflows | 1h | IT admins, operations | Demo + exercise |
| 8. Monitoring, alerting, and SIEM integration | 1h | SecOps | Demo |
| 9. HA management and failover procedures | 1h | IT admins | Demo + exercise |
| 10. Break-glass and emergency procedures | 0.5h | All admins | Hands-on exercise |
| 11. Backup and recovery procedures | 0.5h | IT admins | Demo |
| **Total** | **12h** | | **2 days** |

### 5.3 Module Detail

**Module 2 — User and Device Management (hands-on)**

Participants will be able to:
- Add, modify, and delete user accounts
- Import users from AD/LDAP groups
- Add and configure a new target device
- Onboard a new protocol connection (SSH, RDP, Telnet)
- Assign accounts to target devices
- Review the device connection log

Lab exercise: Add 3 new users from AD. Create a new device. Assign an account.
Connect to the device. Review the session log.

**Module 4 — Credential Vault and Rotation (hands-on)**

Participants will be able to:
- Add a managed credential to the vault
- Configure a rotation policy (schedule, plugin, validation)
- Manually trigger a rotation
- Review rotation history and failure logs
- Configure a break-glass account with manual escrow

Lab exercise: Configure rotation on a test Linux account. Trigger rotation.
Verify the new credential works. Simulate a rotation failure and read the log.

**Module 10 — Break-Glass Procedure (hands-on)**

Participants will be able to:
- Locate the break-glass account credentials (sealed envelope / safe)
- Connect to a target system directly (bypassing Bastion)
- Document the break-glass use in the incident log
- Re-seal the break-glass credentials after use

Lab exercise: Simulate a Bastion outage. Follow the break-glass procedure.
Access the target directly. Document the access. Re-seal the envelope.

### 5.4 Administrator Certification Checklist

Before signing off administrator training, verify each administrator can
complete the following without assistance:

```
Administrator Certification Checklist
--------------------------------------
Name: ____________________________    Date: ____________________________

[ ]  Add a new user from Active Directory and assign to a role
[ ]  Add a new target device and configure an SSH connection
[ ]  Connect to a target via the Bastion console and end the session
[ ]  Search and replay a session recording
[ ]  Assign a FortiToken to a user account in FortiAuthenticator
[ ]  Issue a temporary MFA bypass for a locked-out user
[ ]  Configure a credential rotation policy on a managed account
[ ]  Trigger a manual credential rotation and verify success
[ ]  Initiate a JIT access request as a non-admin user (test account)
[ ]  Approve a JIT request and verify session opens correctly
[ ]  Test HA failover: stop the active node, verify failover completes
[ ]  Execute the break-glass procedure end-to-end

Certified by: ____________________________    Date: ____________________________
```

---

## 6. Operator Training Programme

### 6.1 Training Audience

Operator training targets privileged users who will access target systems
through the Bastion. These users need to complete their work efficiently.
They do not need to understand how Bastion works internally.

Training must be:
- Short (30–60 minutes maximum for any one session)
- Hands-on (no slides-only sessions)
- Role-specific (an operator in a control room has a different workflow
  than a Windows sysadmin)

### 6.2 Operator Training Workflow

The training session follows the user's actual workflow:

```
Step 1: Open the Bastion web portal
        URL: https://[BASTION URL]

Step 2: Log in with Active Directory credentials
        Username: [AD username format — e.g., jsmith or DOMAIN\jsmith]
        Password: [AD password]

Step 3: Authenticate with MFA
        [FortiToken 200]: Enter the 6-digit code displayed on the token
        [FortiToken Mobile]: Enter the 6-digit code from the app

Step 4: Select the target system from the approved device list

Step 5: Click Connect
        For SSH: terminal opens in browser or launches PuTTY/terminal
        For RDP: RDP session opens in browser or launches mstsc
        For VNC: VNC viewer opens in browser

Step 6: Work normally — no other change to workflow

Step 7: Close the session when done (do not leave sessions open)
```

### 6.3 Operator Quick Reference Card

Produce this card for each site. Print and laminate. Post in the control
room and IT operations area.

```
+===============================================================================+
|  WALLIX BASTION — QUICK REFERENCE CARD                                       |
+===============================================================================+
|                                                                               |
|  CONNECTING                                                                  |
|  1. Go to: https://[BASTION URL]                                             |
|  2. Username: your AD username                                               |
|  3. Password: your AD password                                               |
|  4. Token code: 6-digit code from your FortiToken                           |
|  5. Select your system and click Connect                                     |
|                                                                               |
|  IF YOU CANNOT CONNECT                                                       |
|  - Token code wrong? Wait 30 seconds for the next code.                     |
|  - Account locked? Call: [SUPPORT NUMBER]                                   |
|  - Bastion unreachable? Contact: [IT CONTACT]                               |
|                                                                               |
|  LOST OR BROKEN TOKEN?                                                       |
|  Call [SUPPORT NUMBER] — temporary access can be issued in < 5 minutes.    |
|                                                                               |
|  EMERGENCY ACCESS                                                            |
|  Break-glass procedure: [LOCATION OF SEALED ENVELOPE / SAFE]               |
|  Only use in a declared emergency. Document use immediately.                |
|                                                                               |
|  SUPPORT CONTACT                                                             |
|  Name: [NAME]     Email: [EMAIL]     Phone: [PHONE]                         |
|  Hours: [BUSINESS HOURS / 24x7]                                             |
|                                                                               |
+===============================================================================+
```

### 6.4 OT Operator Specific Considerations

For operators in control rooms and OT environments, additional guidance
is required. Refer to `04-pam-ot-guide.md` Section 6 for full detail.

Key points to cover in OT operator training:
- Hardware token mechanics (time-based, 30-second window, no battery indicator)
- What to do when a token expires mid-connection attempt
- Session latency expectations (set realistic expectations; do not oversell)
- Which systems are behind the Bastion vs. which are still direct access
- Emergency access during process emergencies (who to call, where the
  break-glass credentials are physically located)

---

## 7. Vendor and Third-Party Onboarding

### 7.1 Vendor Onboarding Process

Vendors do not receive the same training as internal staff. They need:
- A WALLIX Access Manager account
- A FortiToken Mobile app installed on their device
- Instructions for requesting and using JIT access

Produce this one-page guide for each vendor organisation. Send it when
the vendor account is created.

```
+===============================================================================+
|  VENDOR ACCESS GUIDE                                                         |
+===============================================================================+
|                                                                               |
|  Your organisation has been granted access to [CLIENT NAME]'s                |
|  infrastructure via the WALLIX Access Manager portal.                        |
|                                                                               |
|  ACCESS PORTAL                                                               |
|  URL: https://[ACCESS MANAGER URL]                                           |
|  Your username: [VENDOR EMAIL / USERNAME]                                   |
|  First login: you will be prompted to set your password.                    |
|                                                                               |
|  MFA SETUP                                                                   |
|  1. Install FortiToken Mobile on your iOS or Android device.                |
|     iOS: https://apps.apple.com/app/fortitoken-mobile/id500007723           |
|     Android: https://play.google.com/store/apps/details?id=com.fortinet.    |
|              fortitoken                                                       |
|  2. At first login, scan the QR code to register your token.               |
|                                                                               |
|  REQUESTING ACCESS                                                           |
|  1. Log in to the portal.                                                   |
|  2. Click "Request Access".                                                 |
|  3. Select the system(s) you need to reach.                                 |
|  4. Enter a reason and estimated duration.                                  |
|  5. Submit — the client team will approve or reject within [N] hours.      |
|                                                                               |
|  APPROVED ACCESS                                                             |
|  When approved, you will receive an email confirmation.                     |
|  Log in to the portal during the approved window to connect.                |
|  The session will close automatically at the end of the window.             |
|                                                                               |
|  SUPPORT                                                                     |
|  Contact: [CLIENT CONTACT NAME]  Email: [EMAIL]  Phone: [PHONE]            |
|                                                                               |
+===============================================================================+
```

### 7.2 Vendor Account Lifecycle

| Event | Action | Owner |
|-------|--------|-------|
| New vendor engagement starts | Create vendor account, assign to vendor group, issue onboarding guide | IT admin |
| Vendor access no longer needed | Disable vendor account within 24h of contract end | IT admin |
| Vendor employee leaves vendor company | Vendor POC notifies client; account disabled immediately | Vendor POC + IT admin |
| Vendor requests access extension | Standard JIT request via portal; operations manager approves | Vendor + operations manager |
| Vendor account unused for 30 days | Automatic suspension (configure in Bastion) | Automatic |

---

## 8. Go-Live Readiness Checklist

Complete this checklist with the client's technical lead before go-live.
Do not proceed with go-live if any item is marked as not ready.

### 8.1 Technical Readiness

```
Technical Readiness Checklist
-------------------------------
Date: ____________________________    Site: ____________________________

INFRASTRUCTURE
[ ]  All Bastion nodes operational and network-reachable
[ ]  HA failover tested and documented (failover completes in < 30s)
[ ]  HAProxy active-passive tested (VIP migrates correctly)
[ ]  All target devices onboarded and connection-tested
[ ]  Session recording verified for each protocol type (SSH / RDP / VNC)
[ ]  TLS certificates valid (expiry > 90 days from go-live date)
[ ]  NTP synchronised on all components (< 2s drift)

AUTHENTICATION
[ ]  AD/LDAP integration tested for all in-scope user groups
[ ]  FortiAuthenticator RADIUS integration tested (auth + reject cases)
[ ]  All in-scope users have tested MFA login at least once
[ ]  All hardware tokens distributed and activated
[ ]  Temporary bypass procedure tested and documented

CREDENTIAL MANAGEMENT
[ ]  All managed accounts added to the vault
[ ]  Rotation tested on at least one account per target type
[ ]  Break-glass account configured and credential stored in sealed envelope
[ ]  Break-glass procedure rehearsed with at least one admin

ACCESS CONTROL
[ ]  All RBAC roles reviewed and approved by client security owner
[ ]  JIT workflow tested end-to-end (request → approval → session → audit)
[ ]  Vendor portal tested with at least one test vendor account

MONITORING
[ ]  SIEM integration tested (log events appearing in SIEM)
[ ]  Session recording retention policy configured (__ days)
[ ]  Alert rules configured and tested (if applicable)

FIREWALL
[ ]  All required rules implemented and tested
[ ]  No direct access routes from IT to OT targets exist (if OT in scope)
[ ]  Rules are documented and approved by network team
```

### 8.2 Organisational Readiness

```
Organisational Readiness Checklist
------------------------------------
TRAINING
[ ]  Administrator training completed (see certification checklist, Section 5.4)
[ ]  Operator training completed for all shifts (____  sessions delivered)
[ ]  Vendor onboarding guide distributed to all active vendors
[ ]  Quick reference cards printed and posted at each site

DOCUMENTATION
[ ]  Operations runbook reviewed by client admin team
[ ]  Break-glass procedure understood by all admins and operations managers
[ ]  Support contact list current and distributed

COMMUNICATION
[ ]  Go-live announcement email drafted and approved
[ ]  Support process communicated (who to call, hours, escalation path)
[ ]  Management briefing completed (CISO / IT Manager / Operations Manager)

APPROVAL
[ ]  Client technical lead: go-live approved  [ ] YES  [ ] NO
[ ]  Client operations manager: go-live approved  [ ] YES  [ ] NO
[ ]  Client CISO (or delegate): go-live approved  [ ] YES  [ ] NO

Signed: ____________________________    Date: ____________________________
        (Client technical lead)
```

---

## 9. Hypercare Period

### 9.1 Hypercare Definition

Hypercare is the period immediately after go-live when the consulting team
provides elevated support. Standard engagement hypercare is two weeks.
Complex or large deployments may warrant four weeks.

During hypercare:
- Consulting team is available for same-day response (not 24/7, but within
  business hours with a defined response time)
- Daily 15-minute check-in call with IT Manager
- Any adoption blockers are escalated and resolved within 24 hours
- No new configuration changes are made unless they fix a production issue

### 9.2 Hypercare Support Model

| Issue Type | Response Time | Resolution Target | Who Responds |
|-----------|--------------|------------------|-------------|
| Bastion unreachable / HA failure | 1 hour | 4 hours | Senior consultant |
| Authentication failure (all users) | 1 hour | 4 hours | Senior consultant |
| Individual user login issue | 4 hours | Next business day | Consultant |
| Session recording not working | 4 hours | Next business day | Consultant |
| Rotation failure | Next business day | 2 business days | Consultant |
| General configuration question | Next business day | As agreed | Consultant |

### 9.3 Hypercare Handover

At the end of hypercare, a formal handover meeting closes the active
engagement phase:

Agenda (60 minutes):
1. Adoption metrics review (Section 10)
2. Open issues log — status and owner for each remaining item
3. Known limitations and documented exceptions
4. Support model post-hypercare (vendor support, internal runbook)
5. Roadmap discussion — what comes next (rotation, JIT expansion, OT scope)
6. Sign-off on project closure

---

## 10. Adoption Metrics

Track these metrics during hypercare and present them at the one-month
review. Declining metrics are early warning of a failing deployment.

| Metric | How to Measure | Target | Warning Threshold |
|--------|---------------|--------|------------------|
| % of in-scope users logging in via Bastion | Bastion session log | 100% | < 90% by Week 2 |
| % of target connections through Bastion | Network traffic / Bastion logs | 100% | < 95% by Week 2 |
| MFA success rate (first attempt) | FortiAuthenticator logs | > 95% | < 90% |
| Break-glass account uses | Bastion break-glass log | < 2/month | > 5/month |
| Support tickets related to Bastion | IT service desk | < 5/week by Week 2 | > 15/week persisting |
| Session recording coverage | Bastion recording log | 100% of proxied sessions | Any gap |
| Credential rotation success rate | Bastion rotation log | > 98% | < 95% |

### 10.1 Adoption Dashboard (Bastion + SIEM)

The following queries / reports should be configured and bookmarked for
the client admin team by the end of Phase 4:

- Daily active users in Bastion (past 7 days)
- Sessions by target device (top 10 most accessed)
- Failed MFA attempts by user (past 7 days)
- Break-glass account login events (all time)
- Sessions with no recording (should be zero)
- Rotation failures (past 7 days)
- Vendor sessions opened and closed (past 30 days)

---

## 11. Training Materials Reference

Produce these materials during Phase 4 and hand them over to the client.
They remain with the client and should be updated by the admin team as the
configuration evolves.

| Document | Audience | Format | Owner Post-Handover |
|----------|---------|--------|---------------------|
| Administrator Operations Runbook | IT admins | Markdown / PDF | IT Manager |
| Quick Reference Card | All operators | Laminated print | IT Manager |
| Vendor Onboarding Guide | External vendors | PDF | IT Manager |
| Break-Glass Procedure | All admins, operations managers | Printed, signed, in safe | CISO / IT Manager |
| Token Distribution Log | IT admin | Spreadsheet | IT Manager |
| RACI Matrix (live) | All stakeholders | Spreadsheet | IT Manager |
| Training Completion Log | Managers | Spreadsheet | IT Manager |

### 11.1 Internal Wiki Template Structure

Recommend the client create a PAM section in their internal knowledge base
(Confluence, SharePoint, etc.) with this structure:

```
PAM / WALLIX Bastion
├── Overview and architecture
├── User guides
│   ├── How to connect via Bastion (all users)
│   ├── How to set up FortiToken Mobile
│   ├── How to use the JIT access portal
│   └── How to request access as a vendor
├── Admin guides
│   ├── Adding a new user
│   ├── Adding a new target device
│   ├── Credential rotation management
│   ├── Session recording search and playback
│   └── FortiToken and MFA management
├── Operations
│   ├── Break-glass procedure
│   ├── HA failover procedure
│   ├── Backup and recovery
│   └── Monthly health check checklist
└── Compliance
    ├── Compliance evidence package (current)
    ├── Session recording retention policy
    └── Access review process
```

---

*Related documents in this toolkit:*
- *[Discovery & Assessment](01-discovery-assessment.md) — identify training needs in Phase 1*
- *[Engagement Playbook](03-engagement-playbook.md) — training slots in the project timeline*
- *[Scope & Proposal Template](06-scope-proposal-template.md) — Phase 4 effort estimation*
- *[PAM in OT Guide](04-pam-ot-guide.md) — OT operator-specific training considerations*
