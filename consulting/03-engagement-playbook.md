# 03 - Engagement Playbook

## Meeting Agendas, Client Tips, and Delivery Approach

This playbook guides the consultant through a complete AD + MFA integration engagement, from the first call to post-go-live support.

---

## Table of Contents

1. [Engagement Phases Overview](#1-engagement-phases-overview)
2. [Meeting Templates](#2-meeting-templates)
3. [Client Communication Tips](#3-client-communication-tips)
4. [Handling Objections](#4-handling-objections)
5. [Stakeholder Management](#5-stakeholder-management)
6. [Estimation and Scoping](#6-estimation-and-scoping)
7. [Delivery Milestones](#7-delivery-milestones)
8. [Handover and Knowledge Transfer](#8-handover-and-knowledge-transfer)
9. [Common Mistakes Consultants Make](#9-common-mistakes-consultants-make)
10. [Post-Go-Live Support](#10-post-go-live-support)

---

## 1. Engagement Phases Overview

```
+==============================================================================+
|  ENGAGEMENT TIMELINE -- TYPICAL MFA INTEGRATION PROJECT                      |
+==============================================================================+
|                                                                              |
|  WEEK 0        WEEK 1-2       WEEK 3-4       WEEK 5-6       WEEK 7+          |
|  ======        ========       ========       ========       ======           |
|                                                                              |
|  Discovery     Build          Test           Rollout        Operate          |
|  & Design      & Configure    & Validate     & Enforce      & Support        |
|                                                                              |
|  * Kickoff     * AD prep      * End-to-end   * Pilot group  * Health checks  |
|  * Assessment  * FortiAuth    * Failure       * General      * Monitoring    |
|  * Design      * WALLIX       * Multi-site    * Enforcement  * KT sessions   |
|  * Sign-off    * HA setup     * User enroll   * Comms        * Handover      |
|                                                                              |
|  DELIVERABLES:                                                               |
|  * Assessment  * Config docs  * Test report  * Go-live cert * Runbook        |
|    report      * Firewall     * Remediation  * User guide   * Support guide  |
|  * Design doc    rules          list                                         |
|                                                                              |
+==============================================================================+
```

---

## 2. Meeting Templates

### 2.1 Kickoff Meeting (Day 1)

**Duration:** 90 minutes
**Attendees:** Project sponsor, IT manager, AD admin, network admin, security lead

```
AGENDA
======

1. Introductions and roles (10 min)
   - Who does what on the client side
   - Your role as consultant
   - Escalation paths

2. Project goals and success criteria (15 min)
   - Why MFA? (compliance, incident, initiative?)
   - What does "done" look like?
   - Timeline constraints (audit deadlines, etc.)

3. Discovery questionnaire walkthrough (30 min)
   - Use 01-discovery-assessment.md
   - Fill in together, not in isolation
   - Identify gaps and blockers immediately

4. Architecture overview (15 min)
   - Explain the two-phase model (use diagrams from 02-mfa-strategy-guide)
   - Explain component roles (AD, FortiAuth, WALLIX)
   - Get initial reaction -- any concerns?

5. Timeline and next steps (15 min)
   - Agree on phase dates
   - Assign action items (firewall rules, service accounts, etc.)
   - Schedule next meeting

6. Q&A (5 min)
```

**Action items to leave with:**

| Action | Owner | Due |
|--------|-------|-----|
| Submit firewall rule requests (Port Matrix) | Network admin | Day 2 |
| Create AD service accounts | AD admin | Day 3 |
| Create AD security groups | AD admin | Day 3 |
| Verify LDAPS is enabled | AD admin | Day 3 |
| Export CA certificate | AD admin | Day 3 |
| Confirm FortiAuth appliance is racked and powered | IT / datacenter | Day 3 |
| Verify NTP is configured on all components | IT admin | Day 5 |
| Send user list (who needs MFA) | Project sponsor | Day 5 |

### 2.2 Design Review Meeting (Week 1)

**Duration:** 60 minutes
**Attendees:** IT manager, AD admin, security lead

```
AGENDA
======

1. Review assessment findings (10 min)
   - Readiness score
   - Gaps identified
   - Showstoppers (if any)

2. Present proposed architecture (20 min)
   - Network diagram with IPs
   - Group-to-profile mapping table
   - HA strategy
   - Token strategy (Mobile vs hardware)
   - Walk through authentication flow step by step

3. Review and agree on decisions (20 min)
   - Group names and structure
   - Profile assignments
   - MFA scope (who is enrolled, who is exempt)
   - Rollout strategy (phased or big-bang)
   - Break-glass policy

4. Confirm prerequisites status (10 min)
   - Check each item from prerequisites checklist
   - Identify remaining blockers
   - Agree on start date for build phase
```

### 2.3 Weekly Status Meeting (During Build)

**Duration:** 30 minutes
**Attendees:** IT manager, whoever is needed for blockers

```
AGENDA (keep it tight)
======================

1. Progress update (5 min)
   - What was completed this week
   - Phase checkpoint status

2. Blockers and issues (10 min)
   - Firewall rules pending?
   - Service account issues?
   - Connectivity problems?

3. Next week plan (5 min)
   - What will be done
   - What is needed from the client

4. Decisions needed (10 min)
   - Any outstanding decisions?
   - Escalation needed?
```

### 2.4 Go-Live Decision Meeting (Before Enforcement)

**Duration:** 60 minutes
**Attendees:** Project sponsor, IT manager, security lead, service desk lead

```
AGENDA
======

1. Test results review (15 min)
   - All test scenarios passed?
   - Multi-site validation results
   - Failure scenario results

2. Enrollment status (10 min)
   - How many users enrolled vs total?
   - Who hasn't activated? Follow-up plan?
   - Are there groups that need special attention?

3. Go-live checklist review (15 min)
   - Walk through full go-live checklist
   - Every item must be checked
   - Sign-off from each responsible person

4. Rollback plan (10 min)
   - What happens if MFA causes widespread issues?
   - How quickly can MFA be disabled?
   - Who has the authority to trigger rollback?

5. Go/No-Go decision (10 min)
   - Formal decision to proceed
   - Confirm enforcement date
   - Confirm communication plan
```

---

## 3. Client Communication Tips

### 3.1 Language Guide

| Instead of Saying | Say This | Why |
|-------------------|----------|-----|
| "This is simple" | "This is straightforward -- here's the plan" | Nothing feels simple to the client. Saying "simple" makes them feel dumb for asking questions. |
| "You need to fix your AD" | "We'll work together to prepare AD for the integration" | Collaborative, not accusatory. You're there to help. |
| "RADIUS shared secret" | "The password that WALLIX and FortiAuth use to trust each other" | Clients may not know RADIUS terminology. |
| "LDAP bind" | "How WALLIX logs into Active Directory to verify users" | Translate protocols into actions. |
| "First Factor None" | "FortiAuth only checks the token -- WALLIX handles the password separately" | Explain the logic, not just the setting name. |
| "SPOF" | "If this goes down, nobody can log in" | Impact > acronym. |
| "It's a best practice" | "We do this because [specific reason]" | "Best practice" means nothing. Give the reason. |

### 3.2 Explaining the Authentication Flow to Executives

Use this simplified version for C-level and non-technical stakeholders:

```
HOW LOGIN WORKS AFTER MFA IS ENABLED
=====================================

Today:
  Username + Password -> Logged in

After MFA:
  Username + Password -> Correct? -> Tap "Approve" on phone -> Logged in

What changes for users:
  One extra tap. That's it.

What changes for security:
  A stolen password alone can no longer grant access.
  The attacker would also need the user's phone.
```

### 3.3 Email Templates

#### Pre-Project Communication (Send to All PAM Users)

```
Subject: Upcoming security enhancement for privileged access

Dear colleagues,

As part of our ongoing security improvements, we are adding multi-factor
authentication (MFA) to our privileged access management system (WALLIX).

WHAT THIS MEANS FOR YOU:
- Starting [DATE], when you log into WALLIX, you'll enter your password
  as usual, then approve a notification on your phone
- You'll need to install a free app called "FortiToken Mobile"
- We'll send you setup instructions before the launch date

WHY WE'RE DOING THIS:
- Passwords alone are no longer sufficient to protect critical systems
- MFA is required by [compliance framework / company policy / board directive]
- This protects both the company and you personally

TIMELINE:
- [DATE]: Setup instructions sent to your email
- [DATE]: Training session (optional, 15 min)
- [DATE]: MFA goes live -- you'll need the app from this date

QUESTIONS?
Contact [support contact] or reply to this email.

Thank you for your cooperation,
[Executive Name]
[Title]
```

#### Post-Enrollment Reminder (Users Who Haven't Activated)

```
Subject: REMINDER -- Please activate your FortiToken before [DATE]

Hi [Name],

Our records show you haven't yet activated your FortiToken Mobile app.
MFA enforcement begins [DATE] -- after this date, you won't be able
to access WALLIX without the app.

It takes less than 5 minutes:

1. Install "FortiToken Mobile" on your phone (App Store / Play Store)
2. Open the activation email we sent on [DATE]
3. Tap the activation link or scan the QR code

Need help? Contact [support] or stop by [location] during [hours].

Thank you,
IT Security
```

---

## 4. Handling Objections

### 4.1 Common Objections and Responses

| Objection | Who Says It | Response |
|-----------|------------|----------|
| "This slows us down" | Operators, admins | "The push notification takes 2-3 seconds. Compared to the weeks of downtime from a breach, it's a small investment." |
| "What if I lose my phone?" | Users | "Your admin can issue a temporary bypass in 2 minutes. We'll also have a break-glass account for emergencies. No one gets locked out permanently." |
| "We've never been hacked" | Management | "80% of breaches involve stolen credentials. MFA is insurance -- you don't wait for the fire to buy the extinguisher." |
| "I don't want work apps on my personal phone" | Users (BYOD) | "FortiToken is a standalone app -- it can't read your data, track you, or access anything else on your phone. Alternatively, we can provide a hardware token." |
| "Can't we just use longer passwords?" | IT staff | "Password length doesn't protect against phishing, keyloggers, or credential reuse. MFA adds a different category of defense." |
| "It's too expensive" | Finance | "FortiToken licenses are one-time, not annual. No per-authentication fees. Compare: a single breach costs on average $4.88M. FortiToken for 100 users costs a fraction of that." |
| "Our SOC already monitors for suspicious logins" | Security team | "Detection is important, but prevention is better. MFA prevents the breach; monitoring detects it after the fact. Both are needed." |
| "We'll do it next quarter" | Management | "If there's an audit in [month] or compliance deadline on [date], waiting means a finding. The integration takes 2-4 weeks -- starting now means you're covered." |

### 4.2 The "MFA Fatigue" Concern

Some clients have heard about MFA fatigue attacks (bombarding users with push notifications):

```
HOW WE MITIGATE MFA FATIGUE IN THIS DEPLOYMENT
===============================================

1. Push notifications show SOURCE DETAILS
   - User sees: "Login to WALLIX Bastion from [IP]"
   - If they didn't initiate it, they deny

2. TIMEOUT protects against bombing
   - 60-second timeout per challenge
   - After timeout, attacker must retry -- creates audit trail

3. OTP alternative always available
   - If push feels suspicious, user can switch to manual OTP entry
   - OTP requires the attacker to see the user's phone screen

4. WALLIX Bastion has session logging
   - Even if MFA is bypassed, all session activity is recorded
   - Enables forensics and accountability

5. MONITORING and alerts
   - Alert on > 5 MFA failures in 5 minutes
   - Alert on any MFA bypass usage
   - Security team investigates immediately
```

---

## 5. Stakeholder Management

### 5.1 Stakeholder Map

| Stakeholder | Cares About | How to Engage | Risk if Ignored |
|-------------|-------------|---------------|-----------------|
| **CISO / Security Lead** | Compliance, risk reduction, audit readiness | Show compliance mapping table, audit evidence commands | Project gets deprioritized |
| **IT Manager** | Timeline, resource impact, operational complexity | Realistic timeline, clear action items per person | Resources not allocated |
| **AD Administrator** | Minimal changes to AD, no breaking existing services | Pre-written PowerShell scripts, read-only service accounts | AD changes delayed |
| **Network Administrator** | Firewall rules, port requirements, no disruption | Complete port matrix upfront, pre-written rule descriptions | Firewall rules take weeks |
| **Service Desk Lead** | User support volume, troubleshooting tools | Provide L1 troubleshooting guide, anticipate call volume | Support overwhelmed at go-live |
| **End Users** | Minimal disruption, easy to use | Clear instructions, training session, responsive support | Resistance, complaints to management |
| **Project Sponsor** | On-time, on-budget, visible progress | Weekly status, clear milestones, no surprises | Budget cut or project cancelled |
| **External Auditor** | Evidence of controls, policy documentation | Compliance mapping, evidence collection commands | Audit findings |

### 5.2 The Critical First 48 Hours

The first 48 hours after MFA enforcement determine project perception:

```
FIRST 48 HOURS PLAYBOOK
========================

BEFORE enforcement goes live:
  [ ] Service desk briefed with troubleshooting guide
  [ ] Consultant on standby (or reachable by phone)
  [ ] Break-glass account tested one final time
  [ ] Executive communication sent
  [ ] Activation rate verified > 95%

FIRST MORNING (Day 1):
  [ ] Be available for support calls (on-site if possible)
  [ ] Monitor MFA failure rate dashboard
  [ ] Check for RADIUS connectivity issues from all sites
  [ ] Handle first wave of "how does this work?" calls
  [ ] Escalate any systemic issues immediately

END OF DAY 1:
  [ ] Status update to project sponsor
  [ ] MFA failure rate report
  [ ] List of users who had issues (root cause each)
  [ ] Any adjustments needed?

DAY 2:
  [ ] Second day is usually quieter
  [ ] Follow up on Day 1 issues
  [ ] Address any remaining unactivated users
  [ ] Begin transitioning support to internal team

AFTER 48 HOURS:
  [ ] Formal status email to sponsor: "MFA is live and stable"
  [ ] Transition to BAU support model
  [ ] Schedule KT session for ongoing operations
```

---

## 6. Estimation and Scoping

### 6.1 Effort Estimation Guide

| Task | Effort (Days) | Dependencies | Who |
|------|--------------|--------------|-----|
| Discovery and assessment | 1-2 | Client availability | Consultant + client team |
| Architecture design | 1 | Assessment complete | Consultant |
| AD preparation (OU, accounts, groups) | 0.5-1 | AD admin available | Client AD admin |
| Firewall rule submission and validation | 0.5 + wait | Network team lead time | Client network admin |
| FortiAuth initial setup | 0.5-1 | Appliance racked, IP assigned | Consultant |
| FortiAuth LDAP + RADIUS config | 1 | AD prep complete, LDAPS working | Consultant |
| WALLIX LDAP domain config | 0.5 | CA cert imported, LDAPS working | Consultant |
| WALLIX RADIUS + MFA config | 0.5 | FortiAuth configured | Consultant |
| HA configuration | 0.5-1 | Second FortiAuth available | Consultant |
| End-to-end testing | 1-2 | All config complete | Consultant + client |
| Multi-site validation | 1 | Firewall rules confirmed | Consultant |
| Token enrollment (pilot) | 0.5 | Pilot users identified | Consultant + client |
| Token enrollment (general) | 1-3 | Enrollment emails sent | Client + consultant support |
| User training / communication | 0.5-1 | Materials prepared | Client comms + consultant |
| Go-live support | 1-2 | Enforcement date set | Consultant |
| Knowledge transfer + handover | 1 | Post go-live stability | Consultant |
| **TOTAL** | **10-18 days** | | |

### 6.2 Scoping Checklist

```
+==============================================================================+
|  SCOPE IN vs SCOPE OUT                                                       |
+==============================================================================+
|                                                                              |
|  INCLUDED (standard engagement):                                             |
|  [ ] AD preparation (service accounts, groups, LDAPS verification)           |
|  [ ] FortiAuthenticator 300F configuration                                   |
|  [ ] WALLIX Bastion MFA integration                                          |
|  [ ] HA configuration (if secondary appliance available)                     |
|  [ ] End-to-end testing from all sites                                       |
|  [ ] Pilot group enrollment + support                                        |
|  [ ] Go-live support (2 days)                                                |
|  [ ] Knowledge transfer (1 session)                                          |
|  [ ] Documentation (config, runbook)                                         |
|                                                                              |
|  NOT INCLUDED (discuss if needed):                                           |
|  [ ] AD CS / PKI deployment (if LDAPS not available)                         |
|  [ ] FortiAuth appliance procurement and rack mount                          |
|  [ ] Firewall rule implementation (client responsibility)                    |
|  [ ] User communication and change management                                |
|  [ ] Full user enrollment (client-driven with guidance)                      |
|  [ ] Custom WALLIX authorization policies                                    |
|  [ ] SIEM integration for MFA logs                                           |
|  [ ] Ongoing support beyond go-live                                          |
|                                                                              |
+==============================================================================+
```

---

## 7. Delivery Milestones

### 7.1 Milestone Tracker

| # | Milestone | Criteria | Target Date | Status |
|---|-----------|----------|-------------|--------|
| M1 | Assessment Complete | Questionnaire filled, readiness scored, gaps identified | Week 0 | [ ] |
| M2 | Design Approved | Architecture, group mapping, HA strategy signed off | Week 1 | [ ] |
| M3 | Prerequisites Met | LDAPS, firewall rules, NTP, service accounts verified | Week 1-2 | [ ] |
| M4 | FortiAuth Configured | RADIUS clients, policy, user sync, tokens assigned | Week 2-3 | [ ] |
| M5 | WALLIX Configured | LDAP domain, RADIUS server, MFA policy on all nodes | Week 3 | [ ] |
| M6 | Testing Passed | All test cases passed from all sites | Week 3-4 | [ ] |
| M7 | Pilot Complete | Pilot group using MFA successfully for 3+ days | Week 4-5 | [ ] |
| M8 | General Enrollment | > 95% of users have activated tokens | Week 5-6 | [ ] |
| M9 | MFA Enforced | MFA mandatory for all users, break-glass tested | Week 6-7 | [ ] |
| M10 | Handover Complete | KT done, runbook delivered, support transitioned | Week 7+ | [ ] |

---

## 8. Handover and Knowledge Transfer

### 8.1 KT Session Plan

**Duration:** 2-3 hours
**Attendees:** Client's PAM admin, AD admin, security team member, service desk lead

```
KNOWLEDGE TRANSFER AGENDA
==========================

1. Architecture walkthrough (30 min)
   - Draw the flow on whiteboard together
   - Explain: what each component does and why
   - Point to documentation for reference

2. Day-to-day operations (30 min)
   - Onboarding a new user (live demo)
   - Offboarding a user (live demo)
   - Checking MFA status (live demo)
   - Running the daily health check script

3. Common issues and fixes (30 min)
   - "Token doesn't work" troubleshooting flow
   - "RADIUS not responding" troubleshooting flow
   - Token resync procedure
   - MFA bypass procedure

4. Emergency procedures (20 min)
   - Break-glass account: where is the password, who can use it
   - FortiAuth failover: what happens, what to check
   - MFA disable procedure (emergency only, with approval)

5. Monitoring and alerting (20 min)
   - Walk through configured alerts
   - Show how to check FortiAuth health
   - Show how to check WALLIX MFA status

6. Q&A and practice (20 min)
   - Client performs onboarding of test user
   - Client performs MFA bypass + revoke
   - Client runs health check script
```

### 8.2 Handover Documents to Deliver

| Document | Contents | Audience |
|----------|----------|----------|
| **Architecture Diagram** | Network diagram with IPs, ports, component roles | IT manager, security team |
| **Configuration Reference** | All settings applied (sanitized, no passwords) | PAM admin, AD admin |
| **Operations Runbook** | Onboarding, offboarding, bypass, rotation procedures | PAM admin |
| **L1 Support Guide** | "My token doesn't work" troubleshooting flowchart | Service desk |
| **Monitoring Guide** | Alert definitions, health check script, metric thresholds | Operations team |
| **Compliance Evidence Guide** | How to generate audit reports, what auditors will ask | Security/compliance team |

### 8.3 L1 Support Troubleshooting Flowchart

Deliver this to the service desk team:

```
+==============================================================================+
|  L1 SUPPORT -- "I CAN'T LOG INTO WALLIX"                                     |
+==============================================================================+
|                                                                              |
|  1. "Are you entering the correct password?"                                 |
|     |                                                                        |
|     NO  -> Reset password in AD (standard process)                           |
|     YES -> Continue                                                          |
|                                                                              |
|  2. "Do you see an MFA prompt after the password?"                           |
|     |                                                                        |
|     NO  -> Escalate to L2 (MFA may not be triggering)                        |
|     YES -> Continue                                                          |
|                                                                              |
|  3. "Did you receive a push notification on your phone?"                     |
|     |                                                                        |
|     NO  -> "Try entering the 6-digit code from FortiToken app manually"      |
|            |                                                                 |
|            Works? -> Phone push issue (check internet on phone)              |
|            Fails? -> Continue to step 4                                      |
|     YES -> "Tap Approve on the notification"                                 |
|            |                                                                 |
|            Works? -> Done                                                    |
|            Fails? -> Continue to step 4                                      |
|                                                                              |
|  4. "Open FortiToken app. Is there a token with a 6-digit code?"             |
|     |                                                                        |
|     NO  -> Token not activated. Send new activation email.                   |
|            FortiAuth > User Management > [user] > Provision Token            |
|     YES -> "Read me the 6-digit code"                                        |
|            Try it. If it fails -> Token may need resync (L2)                 |
|                                                                              |
|  5. STILL NOT WORKING?                                                       |
|     -> Escalate to L2/PAM admin                                              |
|     -> If urgent: PAM admin can issue temporary MFA bypass                   |
|        wabadmin auth mfa bypass --user "[user]" --duration 1h                |
|                                                                              |
+==============================================================================+
```

---

## 9. Common Mistakes Consultants Make

### 9.1 Technical Mistakes

| Mistake | Consequence | Prevention |
|---------|------------|------------|
| Not testing from EVERY site | MFA works at HQ, fails at remote office | Test from each Bastion node before signing off |
| Forgetting to register Access Manager as RADIUS client | AM users can't use MFA | Count: 10 Bastions + 2 AMs = 12 RADIUS clients |
| Configuring FortiAuth First Factor as LDAP | Double password prompt, auth breaks | Verify: First Factor = **None** |
| Not verifying NTP before enabling MFA | All OTP codes fail, users locked out | Check NTP on day 1, before any MFA config |
| Using the same shared secret as the VPN RADIUS policy | Security risk -- compromise one, compromise both | Separate shared secrets for VPN and PAM |
| Not creating break-glass account BEFORE enabling MFA | If something breaks, no way in | Break-glass is step 1, not step last |

### 9.2 Process Mistakes

| Mistake | Consequence | Prevention |
|---------|------------|------------|
| Starting config before firewall rules are in place | Wasted time, can't test anything | Submit firewall request on day 1 |
| Not tracking token activation rate | 30% of users locked out on enforcement day | Weekly activation report, follow up stragglers |
| Big-bang enforcement without pilot | Support overwhelmed, executive backlash | Always pilot first (minimum 1 week) |
| Handover without KT session | Client calls you for every issue for months | Structured KT with hands-on practice |
| Not documenting decisions | "Who decided that?" arguments later | Write down every design decision and get sign-off |
| Underestimating user communication | Users surprised, angry, blame IT | Executive email + clear instructions before go-live |

---

## 10. Post-Go-Live Support

### 10.1 First 30 Days Monitoring

| Week | Focus | Key Metric |
|------|-------|------------|
| Week 1 | Stability, user issues | MFA failure rate (target: < 5%) |
| Week 2 | Stragglers, edge cases | Token activation rate (target: > 99%) |
| Week 3 | Operational handover | Internal team handling issues independently |
| Week 4 | Closure | Formal project sign-off, lessons learned |

### 10.2 Lessons Learned Template

After every engagement, fill this in:

```
LESSONS LEARNED
===============

Client:          ____________________________
Date:            ____________________________
Engagement days: ____________________________

WHAT WENT WELL:
1. ____________________________
2. ____________________________
3. ____________________________

WHAT COULD BE IMPROVED:
1. ____________________________
2. ____________________________
3. ____________________________

UNEXPECTED ISSUES ENCOUNTERED:
1. ____________________________
2. ____________________________

TIPS FOR NEXT ENGAGEMENT:
1. ____________________________
2. ____________________________

TIME SPENT BY PHASE:
  Discovery:     ____ days (estimated: ____)
  Build:         ____ days (estimated: ____)
  Test:          ____ days (estimated: ____)
  Rollout:       ____ days (estimated: ____)
  Support:       ____ days (estimated: ____)
  TOTAL:         ____ days (estimated: ____)
```

### 10.3 Recurring Client Check-In (Monthly, First Quarter)

Offer the client a brief monthly check-in for the first quarter after go-live:

```
MONTHLY CHECK-IN AGENDA (15 min)
=================================

1. How is MFA working? Any user complaints?
2. Token activation and enrollment status
3. Any new users onboarded? Process working?
4. Any offboarded users? Tokens revoked?
5. Health check results -- any alerts fired?
6. Upcoming changes (AD migration, new site, etc.)?
7. Questions from internal team?
```

---

*Version 1.0 -- 2026-04-10*
