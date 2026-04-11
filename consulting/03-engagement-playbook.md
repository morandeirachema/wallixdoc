# Engagement Playbook

## Delivery Methodology for PAM and MFA Integration Projects

This playbook guides the engagement from first contact through to knowledge
transfer and project closure. It provides meeting agendas, communication
frameworks, stakeholder guidance, scoping references, and post-go-live
procedures.

---

## Table of Contents

1. [Engagement Phases Overview](#1-engagement-phases-overview)
2. [Meeting Templates](#2-meeting-templates)
3. [Client Communication Framework](#3-client-communication-framework)
4. [Handling Objections](#4-handling-objections)
5. [Stakeholder Management](#5-stakeholder-management)
6. [Estimation and Scoping](#6-estimation-and-scoping)
7. [Delivery Milestones](#7-delivery-milestones)
8. [Handover and Knowledge Transfer](#8-handover-and-knowledge-transfer)
9. [Quality and Risk Controls](#9-quality-and-risk-controls)
10. [Post-Go-Live Support](#10-post-go-live-support)

---

## 1. Engagement Phases Overview

```
+===============================================================================+
|  ENGAGEMENT TIMELINE — TYPICAL MFA INTEGRATION PROJECT                        |
+===============================================================================+
|                                                                               |
|  WEEK 0         WEEK 1-2        WEEK 3-4        WEEK 5-6        WEEK 7+       |
|  ======         ========        ========        ========        ======        |
|                                                                               |
|  Discovery      Build           Test            Rollout         Operations    |
|  & Design       & Configure     & Validate      & Enforce       & Support     |
|                                                                               |
|  * Kickoff      * AD prep       * End-to-end    * Pilot group   * Health      |
|  * Assessment   * FortiAuth     * Failure        * General       * checks     |
|  * Architecture * WALLIX          scenarios       enrollment    * Monitoring  |
|  * Design       * HA setup      * Multi-site     * MFA          * KT          |
|    sign-off     * Firewall        validation      enforcement   * Handover    |
|                   rules          * Enrollment                                 |
|                                                                               |
|  DELIVERABLES:                                                                |
|  Assessment     Config          Test report     Go-live cert    Runbook       |
|  report         documentation   Remediation     User guide      Support guide |
|  Design doc     Firewall        list            Comms           Lessons       |
|                 rules                           plan            learned       |
|                                                                               |
+===============================================================================+
```

---

## 2. Meeting Templates

### 2.1 Kickoff Meeting

**Duration:** 90 minutes
**Required attendees:** Project sponsor, IT manager, AD administrator,
network administrator, security lead

```
AGENDA
======

1. Introductions and roles (10 min)
   - Confirm roles and responsibilities on both sides
   - Establish escalation paths
   - Agree on communication channels and cadence

2. Project goals and success criteria (15 min)
   - Review the driver: compliance deadline, incident, or initiative
   - Define what "done" looks like from the client's perspective
   - Surface any hard constraints (audit dates, freeze windows, etc.)

3. Discovery questionnaire walkthrough (30 min)
   - Complete 01-discovery-assessment.md together
   - Identify gaps and blockers in real time
   - Record answers — do not leave blanks to fill in later

4. Architecture overview presentation (15 min)
   - Introduce the two-phase model (use diagrams from 02-mfa-strategy-guide)
   - Clarify component roles: AD, FortiAuthenticator, WALLIX
   - Collect initial questions and concerns

5. Timeline and next steps (15 min)
   - Agree on milestone dates
   - Assign all action items with owners and due dates
   - Schedule the design review meeting

6. Questions (5 min)
```

**Action items to assign and confirm before leaving the kickoff:**

| Action | Owner | Due |
|--------|-------|-----|
| Submit firewall rule change requests (full port matrix) | Network administrator | Day 2 |
| Create AD service accounts (svc_wallix, svc-fortiauth) | AD administrator | Day 3 |
| Create AD security groups (PAM-Admins, PAM-Operators, etc.) | AD administrator | Day 3 |
| Verify LDAPS is enabled on all Domain Controllers | AD administrator | Day 3 |
| Export the Enterprise CA certificate | AD administrator | Day 3 |
| Confirm FortiAuthenticator is racked, powered, and IP-assigned | IT / Datacenter | Day 3 |
| Verify NTP is configured and synchronized on all components | IT administrator | Day 5 |
| Provide the list of users who require MFA enrollment | Project sponsor | Day 5 |
| Provide IP addresses of both Access Manager nodes | AM team | Day 3 |
| Confirm per-site AM-to-Bastion connectivity schedule | AM team | Week 1 |

### 2.2 Design Review Meeting

**Duration:** 60 minutes
**Attendees:** IT manager, AD administrator, security lead

```
AGENDA
======

1. Assessment findings (10 min)
   - Present the readiness score
   - Walk through identified gaps
   - Confirm whether any showstoppers remain open

2. Proposed architecture presentation (20 min)
   - Network diagram with IP addresses and ports
   - Group-to-profile mapping table
   - HA strategy and FortiAuth placement decision
   - Token strategy (FortiToken Mobile vs hardware)
   - Step-by-step authentication flow walkthrough

3. Design decisions for sign-off (20 min)
   - AD group names and structure
   - WALLIX profile assignments
   - MFA scope: who is enrolled, who is exempt
   - Rollout strategy: phased pilot or full enforcement
   - Break-glass policy and account ownership

4. Prerequisites status review (10 min)
   - Confirm status of each action item from kickoff
   - Identify any remaining blockers
   - Confirm start date for the build phase
```

### 2.3 Weekly Status Meeting

**Duration:** 30 minutes
**Attendees:** IT manager, plus any stakeholder needed to resolve blockers

```
AGENDA
======

1. Progress since last session (5 min)
   - Completed items
   - Milestone checkpoint status

2. Open blockers (10 min)
   - Firewall rules: submitted, approved, validated?
   - Service account issues?
   - Connectivity problems?

3. Plan for next week (5 min)
   - What will be delivered
   - What is required from the client team

4. Decisions needed (10 min)
   - Outstanding design decisions
   - Escalation items if any
```

### 2.4 Go-Live Decision Meeting

**Duration:** 60 minutes
**Attendees:** Project sponsor, IT manager, security lead, service desk lead

```
AGENDA
======

1. Test results summary (15 min)
   - All test scenarios: passed or open?
   - Multi-site validation results
   - Failure scenario and break-glass test results

2. Enrollment status (10 min)
   - Active users enrolled vs total required
   - Pending users: follow-up plan and owner
   - Any user groups requiring special handling

3. Go-live checklist review (15 min)
   - Walk through the full checklist item by item
   - Obtain sign-off from each responsible stakeholder

4. Rollback plan confirmation (10 min)
   - Procedure to disable MFA if a critical issue arises
   - Decision authority: who can authorize rollback
   - Maximum acceptable incident duration before rollback is triggered

5. Go / No-Go decision (10 min)
   - Formal decision recorded in meeting minutes
   - Confirm enforcement date and communication schedule
   - Confirm consultant availability for go-live day
```

---

## 3. Client Communication Framework

### 3.1 Language Guide

The language used in client conversations directly affects how the project
is perceived. The following substitutions improve clarity and professionalism.

| Avoid | Use Instead | Reason |
|-------|-------------|--------|
| "This is simple" | "This is a straightforward process — here is the plan" | Nothing feels simple to the client. Calling it simple dismisses their questions. |
| "You need to fix your AD" | "We will work together to prepare Active Directory for the integration" | Collaborative framing. The consultant is there to help, not to assign blame. |
| "RADIUS shared secret" | "The passphrase that WALLIX and FortiAuthenticator use to authenticate each other" | Translate protocol terminology into functional meaning. |
| "LDAP bind" | "How WALLIX authenticates to Active Directory in order to verify user credentials" | Protocols should be explained as actions. |
| "First Factor None" | "FortiAuthenticator is only responsible for validating the token. WALLIX handles the password separately." | Explain the logic, not just the setting name. |
| "SPOF" | "If this component fails, authentication will not function until it is restored" | Impact matters more than acronyms. |
| "Best practice" | "We configure it this way because [specific reason]" | "Best practice" communicates nothing. Always provide the reason. |

### 3.2 Explaining the Authentication Flow to Non-Technical Stakeholders

Use this simplified version for executive and business audiences:

```
HOW ACCESS WORKS AFTER MFA IS DEPLOYED
========================================

Before:
  Username + Password --> Access granted

After:
  Username + Password --> Correct? --> Tap Approve on phone --> Access granted

What changes for users:
  One additional tap per login. The rest of the workflow is unchanged.

What changes for the organization's security posture:
  A stolen or phished password no longer grants access.
  An attacker would also need physical possession of the user's phone.
  The second factor is independent of the first — two separate systems,
  two separate proofs of identity.
```

### 3.3 Email Templates

#### Pre-Project Communication to PAM Users

```
Subject: Security Enhancement: Multi-Factor Authentication for Privileged Access

Dear [Name / Team],

As part of our ongoing commitment to securing our infrastructure, we are
implementing multi-factor authentication (MFA) on our privileged access
management platform (WALLIX Bastion).

WHAT THIS MEANS FOR YOU

Starting on [DATE], logging into WALLIX will require a second step after
entering your password: approving a notification on your phone. This takes
two to three seconds and requires the FortiToken Mobile application.

We will send you personalized setup instructions before the launch date.
A brief optional training session will be available on [DATE].

WHY WE ARE DOING THIS

Passwords alone are no longer sufficient to protect access to critical
systems. Multi-factor authentication is required by [compliance framework /
company security policy] and is the most effective single control against
credential-based attacks.

TIMELINE

  [DATE]: Setup instructions sent to your email
  [DATE]: Optional training session (15 minutes)
  [DATE]: MFA goes live — the application must be activated by this date

SUPPORT

For questions or assistance, contact [support contact] or attend the
training session on [DATE].

[Executive Sponsor Name]
[Title]
```

#### Activation Reminder for Users Who Have Not Enrolled

```
Subject: Action Required — Activate Your FortiToken Before [DATE]

Dear [Name],

Our records indicate that your FortiToken Mobile activation is not yet
complete. MFA enforcement begins on [DATE]. After that date, access to
WALLIX will require the application to be active on your device.

Activation takes less than five minutes:

  1. Install "FortiToken Mobile" on your smartphone
     (Available on the App Store and Google Play)
  2. Open the activation email we sent on [DATE]
  3. Tap the activation link or scan the QR code

If you have questions or need assistance, please contact [support contact]
or visit [location / service desk] during [hours].

IT Security Team
```

---

## 4. Handling Objections

### 4.1 Objection Reference

| Objection | Raised By | Recommended Response |
|-----------|-----------|----------------------|
| "This will slow us down." | Operators, administrators | "Entering the 6-digit code takes under 10 seconds per login. The operational cost is negligible. The risk exposure it eliminates — a credential breach affecting every system the user can access — is not." |
| "What happens if I lose my phone?" | End users | "An administrator can issue a temporary bypass in under two minutes. No user is permanently locked out. A hardware token is available as a permanent alternative if preferred." |
| "We have never been breached." | Management | "80% of breaches involve compromised credentials. MFA is a preventive control. Its value is in the breaches that do not happen, not the ones that do." |
| "I don't want a work application on my personal phone." | BYOD users | "FortiToken Mobile cannot access, read, or transmit any data from your device. It is a standalone authentication app. A hardware token is available for anyone who prefers not to use their phone." |
| "Longer passwords should be sufficient." | IT staff | "Password complexity does not protect against phishing, keyloggers, or credential reuse across systems. MFA adds a fundamentally different category of defense that password policy cannot address." |
| "The cost is too high." | Finance, procurement | "FortiToken licenses are a one-time purchase with no per-authentication fees. The average confirmed breach costs $4.8M. The per-user cost of this deployment is a fraction of that." |
| "Our security team already monitors for suspicious logins." | Security team | "Detection and prevention serve different purposes. Monitoring detects an incident after credentials have been used. MFA prevents that use in the first place. Both controls are needed and they are complementary." |
| "We will do this next quarter." | Management | "If the compliance deadline is [DATE] or an audit is scheduled for [MONTH], the 2–4 week integration timeline means that starting now is the latest responsible option. Waiting past [DATE] creates a compliance gap." |

### 4.2 Addressing MFA Fatigue

MFA fatigue attacks (bombarding users with push notifications) are not
applicable to this deployment. Push notifications are not configured —
TOTP is the only second factor. An attacker with a stolen password cannot
log in without physically reading the 6-digit code from the user's device.

```
MFA SECURITY PROPERTIES IN THIS DEPLOYMENT
============================================

1. TOTP only — no push notifications
   No push bombing attack surface exists.
   The attacker must have physical access to the user's device
   to read the current 6-digit code.
   Codes expire every 60 seconds.

2. Session recording in WALLIX
   All privileged session activity is recorded regardless of how
   access was obtained. Forensic evidence is always available.

3. Alerting on repeated failures
   An alert fires on more than 5 MFA failures within 5 minutes
   for a single user. The security team investigates immediately.
```

---

## 5. Stakeholder Management

### 5.1 Stakeholder Map

| Stakeholder | Primary Interest | Engagement Approach | Consequence if Not Engaged |
|-------------|----------------|---------------------|---------------------------|
| **CISO / Security Lead** | Compliance, risk reduction, audit readiness | Present compliance mapping and audit evidence procedures | Project deprioritized |
| **IT Manager** | Timeline, resource allocation, operational complexity | Realistic milestones, clear per-person action items | Resources not allocated when needed |
| **AD Administrator** | Minimal AD changes; no disruption to existing services | Provide pre-written scripts; emphasize read-only service accounts | AD preparation delayed |
| **Network Administrator** | Complete firewall requirements; no service disruption | Deliver the full port matrix upfront with rule descriptions | Firewall changes delayed by weeks |
| **Access Manager Team** | AM-to-Bastion connectivity per site; their systems not in scope | Request AM node IPs early; align on per-site connectivity milestones; they must be consulted before FortiAuth RADIUS client registration | AM RADIUS clients missing — MFA breaks silently for AM-brokered sessions |
| **Service Desk Lead** | User support volume; first-call resolution capability | Provide L1 troubleshooting flowchart; set call volume expectations | Service desk overwhelmed at go-live |
| **End Users** | Minimal disruption; ease of use | Clear written instructions; training session; accessible support | Resistance and escalations to management |
| **Project Sponsor** | On-time delivery; budget control; visible progress | Weekly status updates; milestone confirmations; no surprises | Budget re-allocation or project cancellation |
| **External Auditor** | Evidence of enforced controls; policy documentation | Prepare compliance mapping; test evidence collection commands | Audit findings |

### 5.2 The First 48 Hours After Enforcement

The 48 hours following MFA enforcement determine how the project is
perceived by the organization. Manage this period proactively.

```
FIRST 48 HOURS — OPERATIONAL READINESS
========================================

BEFORE ENFORCEMENT:
  [ ] Service desk briefed with L1 troubleshooting guide
  [ ] Consultant available on-site or by phone throughout Day 1
  [ ] Break-glass account tested one final time within 24 hours
  [ ] Executive communication sent to all affected users
  [ ] Token activation rate confirmed > 95%

MORNING OF DAY 1:
  [ ] Available for direct user support (on-site if at all possible)
  [ ] Monitor MFA authentication failure rate
  [ ] Verify RADIUS connectivity from every site
  [ ] Handle first-wave user questions personally or via service desk
  [ ] Escalate any systemic issues immediately

END OF DAY 1:
  [ ] Status summary delivered to project sponsor
  [ ] MFA failure rate reported
  [ ] Root cause documented for each user who had an issue
  [ ] Any configuration adjustments identified and planned

DAY 2:
  [ ] Follow up on all Day 1 open issues
  [ ] Address any remaining unactivated users directly
  [ ] Begin transitioning support responsibility to the internal team

AFTER 48 HOURS:
  [ ] Formal status communication to sponsor: "MFA is live and stable"
  [ ] Transition to standard support model
  [ ] Schedule knowledge transfer session
```

---

## 6. Estimation and Scoping

### 6.1 Effort Reference Guide

| Task | Effort (days) | Key Dependencies | Responsible |
|------|--------------|-----------------|-------------|
| Discovery and assessment | 1–2 | Client availability | Consultant + client team |
| Architecture design and documentation | 1 | Assessment complete | Consultant |
| AD preparation (OUs, service accounts, groups) | 0.5–1 | AD administrator available | Client AD administrator |
| Firewall rule submission and validation | 0.5 + wait time | Network team lead time | Client network administrator |
| FortiAuthenticator initial setup | 0.5–1 | Appliance racked and IP assigned | Consultant |
| FortiAuthenticator LDAP and RADIUS configuration | 1 | AD preparation complete, LDAPS functional | Consultant |
| WALLIX LDAP domain configuration | 0.5 | CA certificate imported, LDAPS working | Consultant |
| WALLIX RADIUS and MFA policy configuration | 0.5 | FortiAuth configured | Consultant |
| HA configuration | 0.5–1 | Secondary appliance available | Consultant |
| End-to-end testing | 1–2 | All configuration complete | Consultant + client |
| Multi-site validation | 1 | Firewall rules confirmed on all sites | Consultant |
| Pilot group enrollment and support | 0.5 | Pilot users identified | Consultant + client |
| General enrollment support | 1–3 | Enrollment emails distributed | Client + consultant |
| User communication and training | 0.5–1 | Materials prepared | Client communications + consultant |
| Go-live support | 1–2 | Enforcement date confirmed | Consultant |
| Knowledge transfer and handover | 1 | Post-go-live stability achieved | Consultant |
| **Total** | **10–18 days** | | |

### 6.2 Scope Definition

Use this matrix to align on inclusions and exclusions at the start of the
engagement. Any item in "Not Included" requires a separate scope agreement.

```
+===============================================================================+
|  SCOPE DEFINITION                                                             |
+===============================================================================+
|                                                                               |
|  INCLUDED IN STANDARD ENGAGEMENT:                                             |
|  [ ] Active Directory preparation (service accounts, groups, LDAPS check)    |
|  [ ] FortiAuthenticator configuration (LDAP sync, RADIUS policy, tokens)     |
|  [ ] WALLIX Bastion MFA integration (LDAP domain, RADIUS, policy)            |
|  [ ] HA configuration (if secondary appliance is available)                  |
|  [ ] End-to-end testing from all sites                                       |
|  [ ] Pilot group enrollment and first-week support                           |
|  [ ] Go-live support (2 days)                                                |
|  [ ] Knowledge transfer session (1 session, up to 3 hours)                   |
|  [ ] Handover documentation (architecture, configuration, runbook)           |
|                                                                               |
|  NOT INCLUDED — DISCUSS IF REQUIRED:                                          |
|  [ ] AD CS / PKI deployment (if LDAPS is not currently available)            |
|  [ ] FortiAuthenticator appliance procurement and physical installation       |
|  [ ] Firewall rule implementation (client responsibility)                    |
|  [ ] WALLIX Access Manager configuration — managed by a separate team        |
|      The AM team is responsible for AM-to-Bastion connectivity per site.     |
|      This engagement registers the AM nodes as RADIUS clients on             |
|      FortiAuth and validates MFA for AM-brokered sessions, but does not      |
|      configure or administer the Access Managers themselves.                 |
|  [ ] User communication planning and execution (change management)           |
|  [ ] Full general enrollment (client-driven, consultant provides guidance)   |
|  [ ] Custom WALLIX authorization policies beyond standard role model          |
|  [ ] SIEM integration for MFA and session logs                               |
|  [ ] Ongoing support beyond the go-live period                               |
|                                                                               |
+===============================================================================+
```

---

## 7. Delivery Milestones

### 7.1 Milestone Tracker

Use this table in weekly status reports and sponsor updates.

| # | Milestone | Completion Criteria | Target Date | Status |
|---|-----------|---------------------|-------------|--------|
| M1 | Assessment Complete | Questionnaire completed, readiness scored, gaps documented | Week 0 | [ ] |
| M2 | Architecture Approved | Network diagram, group mapping, HA strategy signed off by client | Week 1 | [ ] |
| M3 | Prerequisites Verified | LDAPS, firewall rules, NTP, and service accounts confirmed | Week 1–2 | [ ] |
| M4 | FortiAuth Configured | RADIUS clients, policy, LDAP sync, tokens assigned to pilot users | Week 2–3 | [ ] |
| M5 | WALLIX Configured | LDAP domain, RADIUS server, MFA policy active on all nodes | Week 3 | [ ] |
| M6 | Testing Passed | All test cases passed from all sites; failure scenarios verified | Week 3–4 | [ ] |
| M7 | Pilot Complete | Pilot group using MFA successfully for a minimum of 3 days | Week 4–5 | [ ] |
| M8 | General Enrollment | Token activation rate > 95% of required users | Week 5–6 | [ ] |
| M9 | MFA Enforced | MFA mandatory for all users; break-glass account tested | Week 6–7 | [ ] |
| M10 | Handover Complete | KT session delivered; runbook accepted; internal ownership confirmed | Week 7+ | [ ] |

---

## 8. Handover and Knowledge Transfer

### 8.1 Knowledge Transfer Session

**Duration:** 2–3 hours
**Required attendees:** PAM administrator, AD administrator, security team
representative, service desk lead

```
KNOWLEDGE TRANSFER AGENDA
===========================

1. Architecture walkthrough (30 min)
   - Draw the authentication flow together on a whiteboard
   - Explain what each component does and why it is configured as it is
   - Reference the delivered documentation for each section

2. Day-to-day operations — live demonstrations (30 min)
   - Onboard a new user: AD group, token provisioning, activation email
   - Offboard a user: AD disable, token revoke
   - Check MFA status on a specific user
   - Run the daily health check procedure

3. Common issues and resolution (30 min)
   - "Token does not work": troubleshooting flow (L1 guide walkthrough)
   - "RADIUS not responding": connectivity checklist
   - Token resync procedure
   - Temporary MFA bypass issuance and revocation

4. Emergency procedures (20 min)
   - Break-glass account: location, who holds it, how to use it
   - FortiAuth failover: what triggers it, what to verify
   - Emergency MFA disable procedure (authorization process)

5. Monitoring and alerting (20 min)
   - Configured alert definitions and thresholds
   - How to check FortiAuth health status
   - How to check WALLIX MFA enforcement status
   - Where to find audit logs

6. Hands-on practice (20 min)
   - Internal team performs user onboarding on a test account
   - Internal team performs MFA bypass and revoke
   - Internal team runs the health check script
```

### 8.2 Handover Document Set

All documents are delivered digitally. No passwords or secrets are included
in any delivered document.

| Document | Contents | Primary Audience |
|----------|----------|-----------------|
| **Architecture Diagram** | Network diagram with IPs, ports, and component roles | IT manager, security team |
| **Configuration Reference** | All applied settings, sanitized (no credentials) | PAM administrator, AD administrator |
| **Operations Runbook** | Onboarding, offboarding, bypass, token resync, HA failover | PAM administrator |
| **L1 Support Guide** | "I cannot log in" troubleshooting flowchart | Service desk |
| **Monitoring Guide** | Alert definitions, health check script, metric thresholds | Operations team |
| **Compliance Evidence Guide** | How to generate audit reports; what auditors will ask | Security and compliance team |

### 8.3 L1 Support Troubleshooting Flowchart

Deliver this to the service desk before go-live.

```
+===============================================================================+
|  L1 SUPPORT — "I CANNOT LOG INTO WALLIX"                                      |
+===============================================================================+
|                                                                               |
|  1. "Are you entering the correct Active Directory password?"                 |
|     |                                                                         |
|     NO  --> Reset the password in Active Directory (standard process)         |
|     YES --> Continue                                                          |
|                                                                               |
|  2. "After your password, do you see an MFA prompt?"                          |
|     |                                                                         |
|     NO  --> Escalate to L2 (MFA may not be triggering correctly)              |
|     YES --> Continue                                                          |
|                                                                               |
|  3. "Open FortiToken Mobile on your phone. Enter the 6-digit code shown."     |
|     |                                                                         |
|     Works? --> Resolved                                                       |
|     Fails? --> Continue to step 4                                             |
|                                                                               |
|  4. "Open the FortiToken app. Is there a 6-digit code displayed?"             |
|     |                                                                         |
|     NO  --> Token is not activated. Send a new activation email.             |
|             FortiAuth > User Management > [user] > Provision Token            |
|     YES --> "Please read me the code"                                         |
|             Try it. If it fails --> Token may need resync. Escalate to L2.    |
|                                                                               |
|  5. STILL NOT RESOLVED?                                                       |
|     --> Escalate to L2 / PAM administrator                                    |
|     --> For time-sensitive access: PAM admin can issue a temporary bypass     |
|         wabadmin auth mfa bypass --user "[username]" --duration 1h            |
|                                                                               |
+===============================================================================+
```

---

## 9. Quality and Risk Controls

### 9.1 Technical Quality Checks

| Check | Risk if Skipped | Verification Method |
|-------|----------------|---------------------|
| Test MFA from every Bastion node, not only from HQ | MFA works at the primary site; fails silently at remote sites | Run end-to-end test login from each node |
| Register all Bastion nodes and Access Managers as RADIUS clients | Authentication fails for users who hit an unregistered node | Count: 10 Bastions + 2 AMs = 12 entries required. AM IPs must be obtained from the AM team — do not proceed without them |
| Verify FortiAuth RADIUS First Factor = None | Double password prompt; authentication broken | Review policy settings before first user test |
| Verify NTP synchronization before enabling MFA | All OTP codes rejected; users locked out | Check NTP status on AD, FortiAuth, and all WALLIX nodes |
| Create break-glass account before enabling MFA | If MFA breaks, there is no way to access WALLIX to fix it | Test break-glass login before enabling enforcement |
| Use unique RADIUS shared secrets per policy | VPN and PAM share a secret — one compromise affects both | Confirm different secrets for VPN RADIUS and PAM RADIUS policies |

### 9.2 Process Quality Checks

| Check | Risk if Skipped | Mitigation |
|-------|----------------|------------|
| Submit firewall requests on Day 1 | Cannot test connectivity; project stalls | Treat firewall requests as the Day 1 deliverable |
| Track token activation weekly | 30% of users are locked out on enforcement day | Produce a weekly activation report; follow up personally |
| Pilot before general enforcement | Support overwhelmed; executive escalation | Minimum 1 week pilot with a representative user group |
| Structured KT session with hands-on practice | Client calls the consultant for every issue for months | KT is not optional — it is a billable milestone |
| Document every design decision and obtain sign-off | "Who decided that?" disputes after go-live | Written design decisions, signed off in the design review meeting |
| Send user communications before go-live | Users are surprised, blame IT, escalate to management | Executive communication at least 2 weeks before enforcement |

---

## 10. Post-Go-Live Support

### 10.1 First 30 Days Monitoring Plan

| Week | Focus Area | Target Metric |
|------|-----------|---------------|
| Week 1 | Stability, user issues, edge cases | MFA failure rate < 5% |
| Week 2 | Stragglers, token resync cases | Token activation rate > 99% |
| Week 3 | Operational handover to internal team | Internal team resolving issues independently |
| Week 4 | Project closure | Formal sign-off; lessons learned documented |

### 10.2 Lessons Learned Template

Complete this within one week of project closure.

```
LESSONS LEARNED
================

Client:             ____________________________
Engagement dates:   ____________________________
Total days:         ____________________________

WHAT WENT WELL:
1. ____________________________
2. ____________________________
3. ____________________________

WHAT SHOULD BE IMPROVED:
1. ____________________________
2. ____________________________
3. ____________________________

UNEXPECTED ISSUES:
1. ____________________________
2. ____________________________

RECOMMENDATIONS FOR FUTURE ENGAGEMENTS:
1. ____________________________
2. ____________________________

EFFORT BY PHASE (actual vs estimated):
  Discovery:   ____ days  (estimated: ____)
  Build:       ____ days  (estimated: ____)
  Test:        ____ days  (estimated: ____)
  Rollout:     ____ days  (estimated: ____)
  Support:     ____ days  (estimated: ____)
  TOTAL:       ____ days  (estimated: ____)
```

### 10.3 Monthly Check-In (First Quarter After Go-Live)

A brief monthly check-in for the first three months after go-live maintains
quality and gives the client a structured opportunity to raise issues.

```
MONTHLY CHECK-IN AGENDA (15 minutes)
======================================

1. MFA operational status — any recurring user issues?
2. Token activation and enrollment: any outstanding gaps?
3. New user onboarding: is the process working as designed?
4. Departed users: tokens revoked, AD accounts disabled?
5. Monitoring and alerting: any alerts fired? Investigated?
6. Planned infrastructure changes that may affect the integration?
7. Questions from the internal team?
```

---

*Version 2.0 — 2026-04-11*
