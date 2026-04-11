# Discovery & Assessment

## Client Environment Questionnaire

This questionnaire is completed jointly with the client during the kickoff or
pre-sales meeting. Its purpose is to understand the current state of the
environment and design an AD and MFA integration that is accurate, complete,
and fit for production from day one.

---

## 1. Organization Profile

```
Company Name:           ____________________________
Industry:               ____________________________
Number of employees:    ____________________________
Number of PAM users:    ____________________________ (users who will access WALLIX)
Geographic sites:       ____________________________ (count and locations)
Compliance frameworks:  [ ] ISO 27001  [ ] SOC 2  [ ] PCI-DSS  [ ] NIS2
                        [ ] GDPR  [ ] NIST 800-53  [ ] HIPAA  [ ] Other: ____
```

---

## 2. Active Directory Environment

### 2.1 Domain Structure

```
+===============================================================================+
|  ACTIVE DIRECTORY -- CURRENT STATE                                            |
+===============================================================================+
|                                                                               |
|  Domain architecture:                                                         |
|  [ ] Single domain, single forest                                             |
|  [ ] Multiple domains, single forest                                          |
|  [ ] Multiple forests with trusts                                             |
|  [ ] Azure AD / Entra ID hybrid                                               |
|  [ ] Pure cloud (no on-prem AD)                                               |
|                                                                               |
|  Domain FQDN(s):                                                              |
|    1. ____________________________                                            |
|    2. ____________________________                                            |
|    3. ____________________________                                            |
|                                                                               |
|  Forest functional level:  ____________________________                       |
|  Domain functional level:  ____________________________                       |
|                                                                               |
|  Domain Controllers:                                                          |
|    DC count per site:      ____________________________                       |
|    OS version:             ____________________________                       |
|    Virtualized?            [ ] Yes  [ ] No  [ ] Mixed                         |
|                                                                               |
+===============================================================================+
```

### 2.2 Technical Readiness Questions

| # | Question | Why It Matters | Risk Indicator |
|---|----------|----------------|----------------|
| 1 | Is LDAPS (port 636) enabled on all DCs? | WALLIX and FortiAuth require encrypted LDAP. Without it, credentials are transmitted in cleartext. | Answer: "We only use port 389" — requires AD CS deployment before integration. |
| 2 | Do you have an internal Certificate Authority (AD CS)? | Required to issue LDAPS certificates on Domain Controllers. | No CA in place adds 1–2 days for AD CS deployment. |
| 3 | How many OUs contain users who need PAM access? | Determines Base DN scope and LDAP filter complexity. | "Users are spread across many OUs" — requires careful filter design. |
| 4 | Do you use nested security groups? | Affects WALLIX sync performance and group mapping accuracy. | Nesting deeper than 5 levels requires `LDAP_MATCHING_RULE_IN_CHAIN`. |
| 5 | What is your password policy for service accounts? | Determines service account lifecycle requirements. | Short expiry (30–60 days) on all accounts — PAM service accounts require a dedicated policy. |
| 6 | Which team manages Active Directory? Is it the same team as PAM? | Determines coordination effort and lead times. | Different teams in different locations — plan additional lead time. |
| 7 | Do existing service accounts handle third-party integrations? | May allow reuse; otherwise new accounts must be created. | "We use Domain Admin for integrations" — must create dedicated, least-privilege accounts. |
| 8 | Is AD replicated across all sites? | Affects LDAP failover resilience and authentication latency. | Single DC — single point of failure. Recommend adding a secondary DC. |
| 9 | Does each site have at least one local Domain Controller? | The WALLIX HA pair at each site authenticates against local DCs (Phase 1 has no WAN dependency). Without a local DC, password validation traverses the WAN and becomes a single point of failure. | "All DCs are in the central datacenter" — remote site authentication breaks on WAN failure. |

### 2.3 AD Readiness Scoring

Score each item 0 (not ready) to 2 (ready). A total below 10 indicates
significant preparatory work is required before integration can begin.

| Item | 0 — Not Ready | 1 — Partial | 2 — Ready | Score |
|------|---------------|-------------|-----------|-------|
| LDAPS | Not enabled | Enabled on some DCs | Enabled on all DCs | __ |
| AD CS / PKI | No CA deployed | Self-signed only | Enterprise CA with auto-enrollment | __ |
| Service accounts | Shared or admin accounts | Dedicated but over-privileged | Dedicated, least-privilege, non-expiring | __ |
| OU structure | Flat or disorganized | Some structure | Clean OU hierarchy with PAM-specific OUs | __ |
| Group strategy | No security groups for PAM | Some groups exist | Role-based groups ready (Admin/Operator/Auditor) | __ |
| DNS | Inconsistent or manual | Partial DNS records | Full forward and reverse DNS for all components | __ |
| NTP | Not configured | Configured but unverified | All components synchronized, drift verified < 5 s | __ |
| DC redundancy | Single DC | Two DCs, same site | Two or more DCs across sites | __ |
| Local DC per site | DCs only at central site | Some sites have local DCs | Every site has at least one local DC | __ |
| **TOTAL** | | | | **__ / 18** |

**Interpretation:**

| Score | Assessment |
|-------|------------|
| 16–18 | Ready to proceed. Phase 1 can begin immediately. |
| 11–15 | Minor gaps. Integration can start with parallel remediation. |
| 7–10 | Significant preparation required. Allow 1–2 weeks for AD readiness. |
| 0–6 | Major infrastructure gaps. AD environment must be stabilized first. |

---

## 3. Current Authentication State

### 3.1 How Do Privileged Users Access Systems Today?

```
+===============================================================================+
|  CURRENT AUTHENTICATION -- AS-IS                                              |
+===============================================================================+
|                                                                               |
|  Access method:                                                               |
|  [ ] Direct SSH/RDP with personal accounts                                    |
|  [ ] Direct SSH/RDP with shared accounts (root, Administrator)                |
|  [ ] VPN and direct access                                                    |
|  [ ] Jump server / non-WALLIX bastion                                         |
|  [ ] WALLIX Bastion already deployed (upgrade or MFA addition)                |
|  [ ] Other: ____________________________                                      |
|                                                                               |
|  Current MFA status:                                                          |
|  [ ] No MFA in use                                                            |
|  [ ] MFA on VPN only                                                          |
|  [ ] MFA on selected systems (describe): ____________________________         |
|  [ ] MFA on WALLIX with a different provider                                  |
|  [ ] FortiToken already deployed (FortiGate VPN, etc.)                        |
|                                                                               |
|  Existing MFA provider (if any):                                              |
|  [ ] None                                                                     |
|  [ ] Microsoft Authenticator / Azure MFA                                      |
|  [ ] Duo Security                                                             |
|  [ ] RSA SecurID                                                              |
|  [ ] FortiToken (already in use)                                              |
|  [ ] YubiKey / FIDO2                                                          |
|  [ ] Other: ____________________________                                      |
|                                                                               |
+===============================================================================+
```

**Note:** If the client already uses FortiToken for VPN (FortiGate), the same
FortiAuthenticator appliance and tokens can serve WALLIX Bastion. This means
no new application for users, no new licenses for existing tokens, and a
significantly shorter deployment timeline.

### 3.2 Project Driver Questions

Understanding the motivation behind the engagement shapes priorities,
timelines, and the level of urgency to bring to each conversation.

| Question | What It Reveals |
|----------|----------------|
| "What triggered this project — an audit finding, a security incident, or a strategic initiative?" | Urgency and budget. Audit = hard deadline. Incident = executive attention. Initiative = flexible timeline. |
| "Has the organization experienced a security incident related to privileged access?" | Sets the tone. A prior incident means reassurance and evidence of control are paramount. |
| "What is your primary concern about the current access model?" | Identifies real priorities, which may differ from the written requirements. |
| "Which teams are most likely to have concerns about this change?" | Identifies where change management effort is most needed. |
| "What does success look like six months after go-live?" | Aligns expectations before any technical work begins. |

---

## 4. Network and Infrastructure

### 4.1 Network Topology

```
+===============================================================================+
|  NETWORK TOPOLOGY -- CONNECTIVITY MAP                                         |
+===============================================================================+
|                                                                               |
|  Site connectivity:                                                           |
|  [ ] Single site (all components co-located)                                  |
|  [x] Multiple sites via MPLS / private WAN  <-- confirmed: 5 sites on MPLS   |
|  [ ] Multiple sites via site-to-site VPN                                      |
|  [ ] Multiple sites via SD-WAN                                                |
|  [ ] Hybrid (cloud + on-premises)                                             |
|                                                                               |
|  Network segmentation:                                                        |
|  [ ] Flat network (no VLANs)                                                  |
|  [ ] Basic VLANs (servers / users / management)                               |
|  [x] Full segmentation  <-- confirmed: DMZ VLAN + Cyber VLAN per site         |
|  [ ] Microsegmentation / zero trust                                           |
|                                                                               |
|  VLAN assignment (confirmed):                                                 |
|  DMZ VLAN   -- WALLIX Bastion HA pairs (2 nodes per site)                     |
|  Cyber VLAN -- AD Domain Controllers (local HA pair per site)                 |
|  Cyber VLAN -- FortiAuthenticator HA pairs (2 nodes per site, local)          |
|                                                                               |
|  Firewall vendor:     ____________________________                            |
|  Change process:      [ ] Self-managed  [ ] Managed service  [ ] Committee    |
|  Change lead time:    ____________________________  (days / weeks per rule)   |
|                                                                               |
|  Note: Firewall change lead time is the single most common source of          |
|  project delays. This must be established and planned for in week 1.          |
|                                                                               |
+===============================================================================+
```

### 4.2 Firewall Change Lead Time

| Client Response | Project Impact | Required Action |
|----------------|----------------|-----------------|
| "I can apply rules immediately" | None | Standard timeline |
| "We submit a ticket, 1–3 days" | Minor | Submit rules in Phase 0, before any configuration work |
| "We have a weekly CAB meeting" | Moderate | Submit rules at least 2 weeks before planned integration |
| "Our firewall is managed by an outsourced SOC" | Significant | Initiate firewall requests in the very first week |
| "We require a formal change request with risk assessment" | Critical | Treat firewall rules as a dedicated workstream from day 1 |

### 4.3 Required Inter-VLAN Firewall Rules

Submit this complete list to the network team on Day 1 of the engagement.
All rules are required before any integration testing can begin.

```
+===============================================================================+
|  INTER-VLAN FIREWALL RULES -- FULL REQUIREMENT LIST                           |
+===============================================================================+
|                                                                               |
|  DMZ VLAN (Bastions) --> Cyber VLAN (local AD DCs)                            |
|  TCP 636   LDAPS   WALLIX password validation against local DCs (Phase 1)     |
|                                                                               |
|  DMZ VLAN (Bastions) --> Cyber VLAN (local FortiAuth)                         |
|  UDP 1812  RADIUS  WALLIX TOTP validation against local FortiAuth (Phase 2)  |
|                             Intra-site only — no WAN dependency               |
|                                                                               |
|  Cyber VLAN (FortiAuth) --> Cyber VLAN (local AD DCs)                         |
|  TCP 636   LDAPS   FortiAuth user and group sync from local site DCs          |
|                                                                               |
|  Users VLAN --> DMZ VLAN (Bastions)                                           |
|  TCP 443   HTTPS   WALLIX Web UI                                              |
|  TCP 22    SSH     WALLIX SSH proxy                                           |
|  TCP 3389  RDP     WALLIX RDP proxy                                           |
|                                                                               |
|  DMZ VLAN (Bastions) --> Server / Target VLANs                                |
|  TCP 22    SSH     Bastion to Linux targets                                   |
|  TCP 3389  RDP     Bastion to Windows targets                                 |
|  (add further rules per target VLAN as targets are onboarded)                 |
|                                                                               |
|  AM VLAN (external team) --> DMZ VLAN (Bastions)                              |
|  TCP 443   HTTPS   Access Manager to Bastion connectivity                     |
|  Note: the AM team submits their own firewall change requests                 |
|                                                                               |
+===============================================================================+
```

Verify each rule is in place from the correct source host before proceeding
to integration configuration. A missing rule produces either a timeout or
a silent failure — both are hard to diagnose without this checklist.

---

## 5. FortiAuthenticator Assessment

### 5.0 Access Manager Coordination

The WALLIX Access Managers are not in scope for this engagement — they are
managed by a separate team. However, both AM nodes connect to every site's
Bastion HA pair and will send RADIUS authentication requests to
FortiAuthenticator. Their IPs must be registered as RADIUS clients.

```
Access Manager dependency checklist:

[ ] Obtain IP addresses of both AM nodes from the AM team
[ ] Confirm per-site AM-to-Bastion connectivity timeline
[ ] Register both AM IPs as RADIUS clients on FortiAuth
[ ] Validate MFA for an AM-brokered session before go-live
[ ] Document the AM team contact for any future IP changes
```

### 5.1 Existing Fortinet Infrastructure

```
+===============================================================================+
|  FORTINET ECOSYSTEM -- CURRENT STATE                                          |
+===============================================================================+
|                                                                               |
|  Deployed Fortinet products:                                                  |
|  [ ] FortiGate (firewall)                                                     |
|  [ ] FortiAuthenticator (already deployed)                                    |
|  [ ] FortiToken Mobile (already in use)                                       |
|  [ ] FortiToken Hardware                                                      |
|  [ ] FortiAnalyzer                                                            |
|  [ ] FortiManager                                                             |
|  [ ] FortiSIEM                                                                |
|  [ ] None — Fortinet is new to this environment                               |
|                                                                               |
|  If FortiAuthenticator is already deployed:                                   |
|  Model:               ____________________________                            |
|  Firmware version:    ____________________________                            |
|  Current purpose:     ____________________________                            |
|  Token licenses:      ____ / ____ (used / total)                              |
|  HA configured?       [ ] Yes  [ ] No                                         |
|  Available capacity?  [ ] Yes  [ ] No — additional licenses required          |
|                                                                               |
+===============================================================================+
```

When the client already has FortiAuthenticator deployed for VPN MFA, the scope
and timeline reduce significantly:

- The same FortiToken Mobile app is used for both VPN and WALLIX
- Existing tokens require no re-enrollment
- WALLIX Bastion nodes are added as new RADIUS clients on the existing appliance
- A dedicated RADIUS policy is created with First Factor set to None
- **Typical result: 2–3 days of integration work instead of 2–3 weeks**

### 5.2 FortiAuthenticator Sizing Reference

| User Count | Recommended Model | Token Licenses | HA Recommended? |
|------------|-------------------|----------------|-----------------|
| 1–100 | FAC-VM or 200F | 1 × 100-pack | Optional |
| 100–500 | FAC-300F | Multiple 100-packs | Yes |
| 500–2,000 | FAC-400F | 1,000-pack | Yes |
| 2,000+ | FAC-3000F or VM cluster | Bulk packs | Mandatory |

### 5.3 Token Licensing Summary for Client Conversations

```
FORTITOKEN LICENSING -- KEY POINTS
====================================

1. FortiToken Mobile licenses are PERPETUAL
   - One-time purchase; no annual renewal per token
   - Users retain the same token until deprovisioned

2. FortiCare support is annual
   - Required for firmware updates
   - TOTP continues to function without FortiCare (no cloud dependency)

3. License planning
   - License against active users, not total AD accounts
   - Revoked tokens return to the pool and are reusable
   - Plan a 10–15% buffer for growth

4. Cost positioning
   - Lower per-user cost than RSA SecurID, Duo, or Azure MFA P2
   - No per-authentication charges (unlike cloud MFA services)
   - Hardware tokens carry a higher unit cost and require
     battery replacement every 5 years
```

---

## 6. User Impact Assessment

### 6.1 User Population

| User Category | Count | MFA Impact | Training Requirement |
|---------------|-------|------------|----------------------|
| IT Administrators | __ | High — daily use, multiple concurrent sessions | Low — technically proficient |
| Operators / Engineers | __ | High — frequent access to target systems | Medium |
| Auditors / Compliance | __ | Medium — periodic access for reviews | Medium |
| External contractors | __ | High — often remote, variable devices | High — may not have a company device |
| Service accounts | __ | None — exempt from MFA | None |
| Break-glass accounts | __ | Exempt — emergency use only | Must be formally documented |

### 6.2 User Device Readiness

```
+===============================================================================+
|  USER DEVICE READINESS                                                        |
+===============================================================================+
|                                                                               |
|  FortiToken Mobile requires a smartphone (iOS or Android).                    |
|                                                                               |
|  Do all PAM users have access to a smartphone?                                |
|  [ ] Yes — all users have company-managed phones                              |
|  [ ] Mostly — some users use personal devices (BYOD)                          |
|  [ ] Mixed — a portion of users have no smartphone                            |
|  [ ] No — most users do not have smartphones                                  |
|                                                                               |
|  For users without a smartphone:                                              |
|  * Hardware tokens (FortiToken 200) are the recommended alternative           |
|  * Email OTP is available but not recommended for privileged access           |
|  * Desktop TOTP applications (FortiToken for Windows) as a last resort        |
|                                                                               |
|  MDM (Mobile Device Management) in use?                                       |
|  [ ] Yes: ____________________________                                        |
|  [ ] No                                                                       |
|                                                                               |
|  With MDM: FortiToken Mobile can be silently deployed via App Config.         |
|                                                                               |
+===============================================================================+
```

### 6.3 Change Management Readiness

| Question | Client Response | Risk Level |
|----------|----------------|------------|
| Have users previously used MFA? | Yes / No | Low if yes, medium if no |
| Is there executive sponsorship for this project? | Yes / No | High risk if no |
| Is a communication and training team available? | Yes / No | Medium risk if no |
| What is the works council or union situation? | N/A / Approval required | High risk if approval is needed before rollout |
| Is there a service desk team to handle MFA support calls? | Yes / No | High risk if no |

---

## 7. Compliance and Audit Drivers

### 7.1 Applicable Compliance Frameworks

| Framework | MFA Requirement | Applicable? | Design Impact |
|-----------|----------------|-------------|---------------|
| ISO 27001 A.8.5 | Secure authentication mechanisms | [ ] Yes [ ] No | MFA satisfies this control |
| SOC 2 CC6.1 | Logical access with MFA | [ ] Yes [ ] No | Audit evidence of MFA enforcement required |
| PCI-DSS 8.4.2 | MFA for all non-console admin access | [ ] Yes [ ] No | All admin access must transit WALLIX + MFA |
| NIS2 Art. 21 | MFA for critical infrastructure systems | [ ] Yes [ ] No | MFA mandatory on all privileged access paths |
| NIST 800-53 IA-2 | MFA for privileged accounts | [ ] Yes [ ] No | Separate factors: knowledge and possession |
| Internal policy | Organization-specific requirements | [ ] Yes [ ] No | Document specific obligations |

### 7.2 Audit Evidence Requirements

Clients subject to formal audits will be asked to demonstrate the following.
Ensure evidence collection is tested and documented before go-live.

```
AUDIT EVIDENCE -- WHAT AUDITORS REQUIRE AND WHERE TO FIND IT
==============================================================

Q: "How is MFA enforced for privileged access?"
A: WALLIX Bastion MFA policy — enforced on Web UI, SSH proxy, RDP proxy,
   and API. No access path exists that bypasses MFA.
   Evidence: wabadmin auth mfa status

Q: "Can a user bypass MFA?"
A: Only the designated break-glass account, which is monitored and
   generates an immediate alert to the security team on every use.
   Evidence: wabadmin audit search --type mfa-bypass

Q: "What happens if the MFA provider is unavailable?"
A: FortiAuthenticator is deployed in Active-Passive HA. If both nodes
   fail, access is limited to the break-glass account only.
   Evidence: FortiAuth HA configuration, failover test documentation

Q: "How quickly is access revoked when an employee leaves?"
A: Disabling the account in Active Directory immediately blocks
   authentication. The FortiToken is revoked in FortiAuthenticator.
   Evidence: Offboarding procedure documentation, audit log for
   departed users

Q: "What are the two authentication factors?"
A: Knowledge (AD password validated via LDAPS) and Possession
   (FortiToken on the user's phone — separate system, separate event).
   Evidence: WALLIX authentication flow documentation

Q: "Is there evidence of MFA enforcement over the audit period?"
A: RADIUS accounting logs combined with WALLIX session audit logs.
   Evidence: wabadmin report generate --type mfa-audit --last 90d
```

---

## 8. Risk Register

### 8.1 Integration Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| LDAPS not enabled on Domain Controllers | Medium | High — blocks the entire integration | Assess during discovery; deploy AD CS early |
| Firewall change requests delayed | High | High — no RADIUS or LDAPS connectivity | Submit all firewall requests in week 1 |
| User resistance to MFA adoption | Medium | Medium — support overload, escalations | Executive sponsorship, phased rollout, pre-training |
| NTP not synchronized across components | Medium | High — all OTP codes rejected | Verify NTP before any MFA configuration |
| FortiAuthenticator undersized for load | Low | Medium — performance degradation under peak | Size correctly based on user count; load test before go-live |
| Service account password expiry | Medium | High — LDAP authentication breaks silently | Configure non-expiring policy; monitor proactively |
| Single DC or single FortiAuth (no HA) | Varies | High — single point of failure for auth | Recommend HA; document break-glass procedure |
| Token enrollment not completed before enforcement | High | Medium — users locked out on go-live day | Track activation rate weekly; follow up on stragglers |
| FortiAuth RADIUS First Factor misconfigured | Medium | Critical — all authentication fails | Verify First Factor = None before any user testing |

### 8.2 Mandatory Blockers

The following conditions must be resolved before integration work proceeds.

```
+===============================================================================+
|  BLOCKERS -- RESOLVE BEFORE PROCEEDING                                        |
+===============================================================================+
|                                                                               |
|  [ ] LDAPS is not enabled on any Domain Controller                            |
|      Resolution: Deploy AD CS and configure DC certificates                   |
|                                                                               |
|  [ ] DNS resolution is not functioning between components                     |
|      Resolution: DNS must be verified and working before all else             |
|                                                                               |
|  [ ] NTP is not configured or clock drift exceeds 30 seconds                  |
|      Resolution: OTP validation fails at 100%. Fix NTP before                 |
|      any MFA configuration begins.                                            |
|                                                                               |
|  [ ] Firewall rules are not in place and no change process exists             |
|      Resolution: No connectivity testing is possible without rules            |
|                                                                               |
|  [ ] Users have no smartphones and hardware tokens have been declined         |
|      Resolution: No second factor is available. Architecture must             |
|      be redesigned.                                                           |
|                                                                               |
|  [ ] No executive sponsor and significant user resistance is expected         |
|      Resolution: Project will stall at enforcement. Secure sponsorship        |
|      before proceeding.                                                       |
|                                                                               |
+===============================================================================+
```

---

## 9. Assessment Deliverable

Deliver this summary to the client following the discovery session.

```
ENVIRONMENT ASSESSMENT SUMMARY
================================

Client:          [Company Name]
Date:            [Date]
Consultant:      [Name]
Version:         1.0

CURRENT STATE
-------------
AD Architecture:     [Single domain / Multi-domain / Hybrid]
LDAPS Status:        [Enabled / Not enabled / Partial]
Existing MFA:        [None / FortiToken already deployed / Other provider]
FortiAuthenticator:  [Already deployed / New procurement required]
PAM User Count:      [Number]
Sites:               [Number]
Compliance Drivers:  [ISO 27001 / SOC 2 / NIS2 / etc.]

READINESS SCORE:     [__ / 16]

IDENTIFIED GAPS
---------------
1. [Description] — Estimated resolution effort: [effort]
2. [Description] — Estimated resolution effort: [effort]
3. [Description] — Estimated resolution effort: [effort]

RECOMMENDED ENGAGEMENT APPROACH
--------------------------------
[ ] Standard deployment  — environment ready, 1–2 weeks
[ ] Guided deployment    — minor gaps, 2–4 weeks
[ ] Extended engagement  — significant preparation required, 4–8 weeks

AGREED NEXT STEPS
-----------------
1. [Action] — Owner: [Name] — Due: [Date]
2. [Action] — Owner: [Name] — Due: [Date]
3. [Action] — Owner: [Name] — Due: [Date]
```

---

*Version 2.0 — 2026-04-11*
