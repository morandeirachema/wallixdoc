# 01 - Discovery & Assessment

## Client Environment Questionnaire

Use this questionnaire during the first meeting (kickoff or pre-sales) to understand the client's current state and design the right AD + MFA integration. Fill it in with the client, not in isolation -- gaps here become problems in production.

---

## 1. Organization Profile

```
Company Name:           ____________________________
Industry:               ____________________________
Number of employees:    ____________________________
Number of PAM users:    ____________________________ (who will access WALLIX)
Geographic sites:       ____________________________ (count + locations)
Compliance frameworks:  [ ] ISO 27001  [ ] SOC 2  [ ] PCI-DSS  [ ] NIS2
                        [ ] GDPR  [ ] NIST 800-53  [ ] HIPAA  [ ] Other: ____
```

---

## 2. Active Directory Environment

### 2.1 Domain Structure

```
+==============================================================================+
|  ACTIVE DIRECTORY -- CURRENT STATE                                           |
+==============================================================================+
|                                                                              |
|  Domain architecture:                                                        |
|  [ ] Single domain, single forest                                            |
|  [ ] Multiple domains, single forest                                         |
|  [ ] Multiple forests with trusts                                            |
|  [ ] Azure AD / Entra ID hybrid                                              |
|  [ ] Pure cloud (no on-prem AD)                                              |
|                                                                              |
|  Domain FQDN(s):                                                             |
|    1. ____________________________                                           |
|    2. ____________________________                                           |
|    3. ____________________________                                           |
|                                                                              |
|  Forest functional level:  ____________________________                      |
|  Domain functional level:  ____________________________                      |
|                                                                              |
|  Domain Controllers:                                                         |
|    DC count per site:      ____________________________                      |
|    OS version:             ____________________________                      |
|    Virtualized?            [ ] Yes  [ ] No  [ ] Mixed                        |
|                                                                              |
+==============================================================================+
```

### 2.2 Critical Questions to Ask

| # | Question | Why It Matters | Red Flag Answers |
|---|----------|----------------|------------------|
| 1 | Is LDAPS (port 636) enabled on all DCs? | WALLIX and FortiAuth need encrypted LDAP. Without it, credentials travel in cleartext | "We only use LDAP on 389" -- must deploy AD CS first |
| 2 | Do you have an internal Certificate Authority (AD CS)? | Required for LDAPS certificates on DCs | "No CA" -- adds 1-2 days to project for AD CS deployment |
| 3 | How many OUs hold users that need PAM access? | Determines Base DN and filter complexity | "Users are everywhere" -- needs careful filter design |
| 4 | Do you use nested groups? | Affects WALLIX sync performance and group mapping | Deep nesting (5+ levels) requires LDAP_MATCHING_RULE_IN_CHAIN |
| 5 | What is your password policy? | Impacts service account lifecycle | Short expiry (30-60 days) on all accounts -- service accounts need exemption |
| 6 | Who manages AD? Same team as PAM? | Determines coordination effort | Different teams in different countries -- plan extra lead time |
| 7 | Do you have existing service accounts for integrations? | May reuse or need new ones | "We use Domain Admin for everything" -- security risk, must create dedicated accounts |
| 8 | Is AD replicated across all sites? | Affects LDAP failover and latency | "Only one DC" -- single point of failure, recommend adding DC |

### 2.3 AD Readiness Scoring

Score each item 0 (not ready) to 2 (ready). Total < 10 = significant prep needed.

| Item | 0 (Not Ready) | 1 (Partial) | 2 (Ready) | Score |
|------|---------------|-------------|-----------|-------|
| LDAPS | Not enabled | Enabled on some DCs | Enabled on all DCs | __ |
| AD CS / PKI | No CA deployed | Self-signed only | Enterprise CA with auto-enrollment | __ |
| Service accounts | Using shared/admin accounts | Dedicated but overprivileged | Dedicated, least-privilege, no-expire | __ |
| OU structure | Flat / disorganized | Some structure | Clean OU hierarchy with PAM-specific OUs | __ |
| Group strategy | No security groups for PAM | Some groups exist | Role-based groups ready (Admin/Operator/Auditor) | __ |
| DNS | Inconsistent / manual entries | Partial DNS records | Full forward+reverse DNS for all components | __ |
| NTP | Not configured / unknown | Configured but not verified | All components synced, drift < 5s verified | __ |
| DC redundancy | Single DC | 2 DCs same site | 2+ DCs across sites | __ |
| **TOTAL** | | | | **__/16** |

**Interpretation:**
- **14-16:** Ready to proceed. Start Phase 1 immediately.
- **10-13:** Minor gaps. Can start while remediating in parallel.
- **6-9:** Significant prep needed. Dedicate 1-2 weeks for AD readiness before integration.
- **0-5:** Major infrastructure gaps. AD environment needs stabilization first.

---

## 3. Current Authentication State

### 3.1 How Do Users Access Systems Today?

```
+==============================================================================+
|  CURRENT AUTHENTICATION -- AS-IS                                             |
+==============================================================================+
|                                                                              |
|  How do privileged users access servers today?                               |
|  [ ] Direct SSH/RDP with personal accounts                                   |
|  [ ] Direct SSH/RDP with shared accounts (root, Administrator)               |
|  [ ] VPN + direct access                                                     |
|  [ ] Jump server / bastion (non-WALLIX)                                      |
|  [ ] WALLIX Bastion already deployed (upgrading/adding MFA)                  |
|  [ ] Other: ____________________________                                     |
|                                                                              |
|  Current MFA status:                                                         |
|  [ ] No MFA anywhere                                                         |
|  [ ] MFA on VPN only                                                         |
|  [ ] MFA on some systems (describe): ____________________________            |
|  [ ] MFA on WALLIX but different provider                                    |
|  [ ] FortiToken already in use (for FortiGate VPN, etc.)                     |
|                                                                              |
|  Existing MFA provider (if any):                                             |
|  [ ] None                                                                    |
|  [ ] Microsoft Authenticator / Azure MFA                                     |
|  [ ] Duo Security                                                            |
|  [ ] RSA SecurID                                                             |
|  [ ] FortiToken (already!)                                                   |
|  [ ] YubiKey / FIDO2                                                         |
|  [ ] Other: ____________________________                                     |
|                                                                              |
+==============================================================================+
```

> **Tip:** If the client already uses FortiToken for VPN (FortiGate), the same FortiAuthenticator appliance and tokens can serve WALLIX. This is a major selling point -- no new app for users, no new licenses for existing tokens.

### 3.2 Pain Points (Ask These Directly)

Use these questions to understand motivation and urgency:

| Question | What You Learn |
|----------|---------------|
| "What triggered this project -- audit finding, incident, or initiative?" | Urgency and budget. Audit = hard deadline. Incident = executive attention. Initiative = flexible timeline. |
| "Have you had a security incident related to privileged access?" | If yes, sets the tone for the entire engagement. They want reassurance. |
| "What keeps you up at night about your current setup?" | Their real priorities (may differ from the RFP). |
| "Who will resist this change the most?" | Identifies where to invest change management effort. |
| "What would success look like 6 months after go-live?" | Aligns expectations early. |

---

## 4. Network and Infrastructure

### 4.1 Network Assessment

```
+==============================================================================+
|  NETWORK TOPOLOGY -- CONNECTIVITY MAP                                        |
+==============================================================================+
|                                                                              |
|  How are sites connected?                                                    |
|  [ ] Single site (all components co-located)                                 |
|  [ ] Multiple sites with MPLS / private WAN                                  |
|  [ ] Multiple sites with site-to-site VPN                                    |
|  [ ] Multiple sites with SD-WAN                                              |
|  [ ] Hybrid (cloud + on-prem)                                                |
|                                                                              |
|  Network segmentation:                                                       |
|  [ ] Flat network (no VLANs)                                                 |
|  [ ] Basic VLANs (servers / users / management)                              |
|  [ ] Full segmentation (DMZ, management, server, user zones)                 |
|  [ ] Microsegmentation / zero trust network                                  |
|                                                                              |
|  Firewall vendor:     ____________________________                           |
|  Change process:      [ ] Self-managed  [ ] Managed service  [ ] Committee   |
|  Change lead time:    ____________________________  (days/weeks for rules)   |
|                                                                              |
|  IMPORTANT: Firewall change lead time is the #1 source of project delays.    |
|  If the client needs 2 weeks for a firewall change request, plan accordingly.|
|                                                                              |
+==============================================================================+
```

### 4.2 Firewall Change Lead Time Matrix

| Client Answer | Impact | Action |
|---------------|--------|--------|
| "I can do it myself in 5 minutes" | None | Standard timeline |
| "We submit a ticket, takes 1-3 days" | Minor | Submit rules in Phase 0, before any config work |
| "We have a weekly CAB meeting" | Moderate | Submit rules 2 weeks before planned integration |
| "Our firewall is managed by an outsourced SOC" | Major | Start firewall requests in the very first week |
| "We need a formal change request with risk assessment" | Critical | Treat firewall rules as a separate work stream |

---

## 5. FortiAuthenticator Assessment

### 5.1 Existing Fortinet Infrastructure

```
+==============================================================================+
|  FORTINET ECOSYSTEM -- CURRENT STATE                                         |
+==============================================================================+
|                                                                              |
|  Existing Fortinet products:                                                 |
|  [ ] FortiGate (firewall)                                                    |
|  [ ] FortiAuthenticator (already deployed!)                                  |
|  [ ] FortiToken Mobile (already in use!)                                     |
|  [ ] FortiToken Hardware                                                     |
|  [ ] FortiAnalyzer                                                           |
|  [ ] FortiManager                                                            |
|  [ ] FortiSIEM                                                               |
|  [ ] None -- Fortinet is new                                                 |
|                                                                              |
|  If FortiAuthenticator exists:                                               |
|  Model:               ____________________________                           |
|  Firmware version:     ____________________________                          |
|  Current purpose:      ____________________________                          |
|  Token licenses used:  ____ / ____ (used/total)                              |
|  HA configured?        [ ] Yes  [ ] No                                       |
|  Available capacity?   [ ] Yes  [ ] Need more licenses                       |
|                                                                              |
+==============================================================================+
```

> **Key insight:** If the client already has FortiAuthenticator for VPN MFA, you can reuse it for WALLIX. This means:
> - Same FortiToken app on user phones (no new app to install)
> - Same tokens (no re-enrollment)
> - Just add WALLIX Bastion nodes as new RADIUS clients
> - Create a separate RADIUS policy with First Factor = None
> - **Saves weeks of deployment time and user training**

### 5.2 FortiAuthenticator Sizing

| User Count | Recommended Model | Token Licenses | HA Recommended? |
|------------|-------------------|----------------|-----------------|
| 1-100 | FortiAuthenticator VM or 200F | 1x 100-pack | Optional |
| 100-500 | FortiAuthenticator 300F | Multiple 100-packs | Yes |
| 500-2000 | FortiAuthenticator 400F | 1000-pack(s) | Yes |
| 2000+ | FortiAuthenticator 3000F or VM cluster | Bulk | Mandatory |

### 5.3 Licensing Conversation

Key points for the client:

```
FORTITOKEN LICENSING -- WHAT TO TELL THE CLIENT
================================================

1. FortiToken Mobile licenses are PERPETUAL (one-time cost)
   - No annual renewal for the tokens themselves
   - Users keep the same token forever (until deprovisioned)

2. FortiCare support IS annual
   - Required for firmware updates
   - Required for FortiGuard push notification service
   - Without FortiCare, push stops working -- OTP still works

3. License math:
   - Buy tokens for active users only, not all AD accounts
   - Revoked tokens return to the pool (reusable)
   - Plan 10-15% buffer for growth

4. Cost comparison (use in proposals):
   - FortiToken Mobile: lower cost per user than RSA, Duo, or Azure MFA
   - No per-authentication charges (unlike some cloud MFA)
   - Hardware tokens: higher unit cost + battery replacement every 5 years
```

---

## 6. User Impact Assessment

### 6.1 User Population Analysis

| User Type | Count | MFA Impact | Training Need |
|-----------|-------|------------|---------------|
| IT Administrators | __ | High -- daily use, multiple sessions | Low -- tech savvy |
| Operators / Engineers | __ | High -- frequent access to targets | Medium |
| Auditors / Compliance | __ | Medium -- periodic access for reviews | Medium |
| External contractors | __ | High -- often remote, variable devices | High -- may not have company phone |
| Service accounts | __ | None -- exempt from MFA | None |
| Break-glass accounts | __ | Exempt | Must be documented |

### 6.2 User Device Readiness

```
+==============================================================================+
|  USER DEVICE READINESS                                                       |
+==============================================================================+
|                                                                              |
|  FortiToken Mobile requires a smartphone (iOS or Android).                   |
|                                                                              |
|  Ask the client:                                                             |
|                                                                              |
|  Do all PAM users have company smartphones?                                  |
|  [ ] Yes -- all users have company-managed phones                            |
|  [ ] Mostly -- some use personal phones (BYOD)                               |
|  [ ] Mixed -- some users have no smartphone                                  |
|  [ ] No -- most users don't have smartphones                                 |
|                                                                              |
|  If users lack smartphones:                                                  |
|  * Hardware tokens (FortiToken 200) as alternative                           |
|  * Email OTP (less secure, not recommended for privileged access)            |
|  * Consider: should the company provide phones for PAM users?                |
|  * Desktop TOTP apps (FortiToken for Windows) as last resort                 |
|                                                                              |
|  MDM (Mobile Device Management) in use?                                      |
|  [ ] Yes: ____________________________                                       |
|  [ ] No                                                                      |
|                                                                              |
|  If MDM: FortiToken Mobile can be pushed via MDM silently.                   |
|  App Config keys available for managed deployment.                           |
|                                                                              |
+==============================================================================+
```

### 6.3 Change Management Readiness

| Question | Client Answer | Risk Level |
|----------|---------------|------------|
| Have users experienced MFA before? | Yes / No | Low if yes, medium if no |
| Is there executive sponsorship for this project? | Yes / No | High risk if no |
| Is there a communication/training team available? | Yes / No | Medium risk if no |
| What is the union/works council situation? | N/A / Need approval | High risk if approval needed |
| Is there a service desk to handle MFA support calls? | Yes / No | High risk if no -- who answers "my token doesn't work"? |

---

## 7. Compliance and Audit Drivers

### 7.1 Compliance Requirements Matrix

| Framework | MFA Requirement | Client Applicable? | Impact on Design |
|-----------|----------------|-------------------|------------------|
| ISO 27001 A.8.5 | Secure authentication mechanisms | [ ] Yes [ ] No | MFA satisfies this control |
| SOC 2 CC6.1 | Logical access with MFA | [ ] Yes [ ] No | Need audit evidence of MFA enforcement |
| PCI-DSS 8.4.2 | MFA for non-console admin access | [ ] Yes [ ] No | All admin access must go through WALLIX+MFA |
| NIS2 Art.21 | Multi-factor for critical systems | [ ] Yes [ ] No | MFA on all privileged access |
| NIST 800-53 IA-2 | MFA for privileged accounts | [ ] Yes [ ] No | Separate factors: knowledge + possession |
| Internal policy | Company-specific | [ ] Yes [ ] No | Document specific requirements |

### 7.2 Audit Questions to Anticipate

The auditor will ask these. Prepare the client:

```
WHAT AUDITORS WILL ASK (AND WHERE TO FIND THE ANSWERS)
======================================================

Q: "How do you enforce MFA for privileged access?"
A: WALLIX Bastion MFA policy -- enforced on Web UI, SSH, RDP, API.
   Evidence: wabadmin auth mfa status

Q: "Can a user bypass MFA?"
A: Only the break-glass account (documented, alerted, logged).
   All bypasses trigger email to security team.
   Evidence: wabadmin audit search --type mfa-bypass

Q: "What happens when the MFA provider goes down?"
A: FortiAuth HA (active-passive). If both fail, break-glass only.
   Evidence: FortiAuth HA status, failover test documentation

Q: "How quickly is access revoked when someone leaves?"
A: Disable in AD = instant LDAP auth block. Revoke token in FortiAuth.
   Evidence: offboarding procedure + last audit log for departed users

Q: "What are the two factors?"
A: Knowledge (AD password via LDAPS) + Possession (FortiToken on phone).
   Two separate systems, two separate authentication events.
   Evidence: WALLIX auth flow documentation

Q: "Do you have evidence of MFA enforcement over the audit period?"
A: RADIUS accounting logs + WALLIX session audit logs.
   Evidence: wabadmin report generate --type mfa-audit --last 90d
```

---

## 8. Risk Assessment

### 8.1 Integration Risk Register

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| LDAPS not enabled on DCs | Medium | High -- blocks entire integration | Assess in discovery; deploy AD CS early |
| Firewall changes delayed | High | High -- no RADIUS/LDAPS connectivity | Submit firewall requests week 1 |
| Users resist MFA | Medium | Medium -- support overload, complaints | Executive comms, phased rollout, training |
| NTP not synchronized | Medium | High -- all OTP codes rejected | Verify NTP before any MFA config |
| FortiAuth undersized | Low | Medium -- performance under load | Size properly; load test before go-live |
| Service account password expires | Medium | High -- LDAP auth breaks silently | Set to never-expire; monitor; rotate manually |
| Single DC / single FortiAuth | Varies | High -- SPOF for auth | Recommend HA; size break-glass procedure |
| Token enrollment incomplete | High | Medium -- users locked out on enforcement day | Track activation %; follow up before deadline |
| Wrong RADIUS First Factor | Medium | Critical -- breaks all auth | Verify: First Factor = None (WALLIX validates password) |

### 8.2 Showstopper Checklist

If any of these are true, **stop and resolve before proceeding**:

```
+==============================================================================+
|  SHOWSTOPPERS -- MUST RESOLVE BEFORE INTEGRATION                             |
+==============================================================================+
|                                                                              |
|  [ ] No LDAPS on ANY Domain Controller                                       |
|      --> Deploy AD CS and configure DC certificates first                    |
|                                                                              |
|  [ ] No DNS resolution between components                                    |
|      --> DNS must work before anything else                                  |
|                                                                              |
|  [ ] NTP not configured / clocks off by > 30 seconds                         |
|      --> OTP will fail 100% of the time. Fix NTP first.                      |
|                                                                              |
|  [ ] No firewall change process and rules not in place                       |
|      --> Cannot test anything without network connectivity                   |
|                                                                              |
|  [ ] Client has no smartphones AND refuses hardware tokens                   |
|      --> No MFA factor available. Redesign required.                         |
|                                                                              |
|  [ ] No executive sponsor and strong user resistance expected                |
|      --> Project will stall at enforcement phase. Get sponsorship first.     |
|                                                                              |
+==============================================================================+
```

---

## 9. Assessment Deliverable Template

After the discovery session, deliver this summary to the client:

```
ENVIRONMENT ASSESSMENT SUMMARY
==============================

Client:          [Company Name]
Date:            [Date]
Assessor:        [Your Name]
Version:         1.0

CURRENT STATE
-------------
AD Architecture:     [Single domain / Multi-domain / Hybrid]
LDAPS Status:        [Enabled / Not enabled / Partial]
Existing MFA:        [None / FortiToken already / Other provider]
FortiAuthenticator:  [Already deployed / New purchase needed]
User Count (PAM):    [Number]
Sites:               [Number]
Compliance Drivers:  [ISO 27001, SOC 2, NIS2, etc.]

READINESS SCORE:     [__/16]  (from Section 2.3)

IDENTIFIED GAPS
---------------
1. [Gap description] -- [Estimated effort to resolve]
2. [Gap description] -- [Estimated effort to resolve]
3. [Gap description] -- [Estimated effort to resolve]

RECOMMENDED APPROACH
--------------------
[ ] Standard deployment (environment ready, < 2 weeks)
[ ] Guided deployment (minor gaps, 2-4 weeks)
[ ] Extended engagement (significant prep needed, 4-8 weeks)

NEXT STEPS
----------
1. [Action] -- Owner: [Name] -- By: [Date]
2. [Action] -- Owner: [Name] -- By: [Date]
3. [Action] -- Owner: [Name] -- By: [Date]
```

---

*Version 1.0 -- 2026-04-10*
