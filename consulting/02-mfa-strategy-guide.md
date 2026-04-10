# 02 - MFA Strategy Guide

## Concepts, Decision Matrices, and Architecture Patterns

Use this guide during client conversations to explain MFA concepts clearly, help them make informed decisions, and design the right architecture for their environment.

---

## Table of Contents

1. [Explaining MFA to the Client](#1-explaining-mfa-to-the-client)
2. [Why FortiAuthenticator + WALLIX](#2-why-fortiauthenticator--wallix)
3. [Architecture Decision Matrix](#3-architecture-decision-matrix)
4. [The Two-Phase Authentication Model](#4-the-two-phase-authentication-model)
5. [Token Strategy](#5-token-strategy)
6. [Group and Profile Strategy](#6-group-and-profile-strategy)
7. [High Availability Patterns](#7-high-availability-patterns)
8. [Common Client Scenarios](#8-common-client-scenarios)
9. [Anti-Patterns to Avoid](#9-anti-patterns-to-avoid)
10. [Competitive Positioning](#10-competitive-positioning)

---

## 1. Explaining MFA to the Client

### 1.1 The Three Factors (Client-Friendly Language)

Use this table when explaining MFA to non-technical stakeholders:

| Factor | Plain Language | Example | Analogy |
|--------|---------------|---------|---------|
| **Knowledge** | Something you know | Password, PIN | The combination to a safe |
| **Possession** | Something you have | Phone with FortiToken, hardware token | The physical key to a door |
| **Inherence** | Something you are | Fingerprint, face recognition | Your signature |

**The elevator pitch:**

> "Right now, if someone steals a password, they're in. With MFA, stealing the password is not enough -- they also need the user's phone. Two separate things, from two separate systems. That's what makes it effective."

### 1.2 Why Passwords Alone Fail

Use these data points in presentations:

```
WHY PASSWORDS ARE NOT ENOUGH
=============================

- 80% of breaches involve compromised credentials (Verizon DBIR 2024)
- Average cost of a breach: $4.88M (IBM Cost of a Data Breach 2024)
- Privileged accounts are the #1 target in attacks
- Password reuse across personal and corporate accounts is endemic
- Phishing attacks bypass password complexity requirements entirely
- MFA blocks 99.9% of automated credential attacks (Microsoft data)
```

### 1.3 What MFA Does NOT Solve

Be honest with the client. MFA is not a silver bullet:

| MFA Protects Against | MFA Does NOT Protect Against |
|---------------------|----------------------------|
| Stolen passwords | Insider threats (authorized user acting maliciously) |
| Credential stuffing | Session hijacking (after MFA is completed) |
| Brute force attacks | Malware on the endpoint |
| Phishing (partially) | Social engineering targeting MFA itself (MFA fatigue) |
| Keyloggers (password alone is useless) | Physical access to unlocked sessions |

> **Consultant tip:** Never oversell. If you promise MFA solves everything, you lose credibility. Position it as "one critical layer in a defense-in-depth strategy."

---

## 2. Why FortiAuthenticator + WALLIX

### 2.1 The Integration Advantage

```
+==============================================================================+
|  WHY THIS COMBINATION WORKS                                                  |
+==============================================================================+
|                                                                              |
|  1. CLEAN SEPARATION OF CONCERNS                                             |
|     Active Directory: "Who are you?" (identity + password)                   |
|     FortiAuthenticator: "Prove you have your phone" (2nd factor)             |
|     WALLIX Bastion: "What can you access?" (authorization + session)         |
|                                                                              |
|  2. NO VENDOR LOCK-IN ON THE MFA LAYER                                       |
|     WALLIX speaks standard RADIUS -- FortiAuth today, Duo tomorrow           |
|     FortiAuth speaks standard LDAPS -- works with any PAM solution           |
|     AD is the single source of truth for identity (stays unchanged)          |
|                                                                              |
|  3. OPERATIONAL SIMPLICITY                                                   |
|     User changes password in AD -- nothing else to update                    |
|     User leaves -- disable in AD, revoke token, done                         |
|     New user -- add to AD group, token auto-assigned                         |
|                                                                              |
|  4. WORKS WITH EXISTING FORTINET INFRASTRUCTURE                              |
|     Same FortiToken app used for VPN and PAM                                 |
|     Same FortiAuth appliance -- just add WALLIX as RADIUS client             |
|     No new software for users if already using FortiToken                    |
|                                                                              |
+==============================================================================+
```

### 2.2 Client Talking Points

| Client Question | Your Answer |
|----------------|-------------|
| "Why not just use Azure MFA?" | "Azure MFA works great for cloud apps. For on-prem PAM with SSH/RDP proxy, RADIUS is more reliable and has lower latency. FortiAuth gives you on-prem MFA that works even if your internet goes down." |
| "Why not Duo?" | "Duo is excellent but cloud-dependent. FortiAuth is on-prem, no per-auth cloud charges, and if you already have FortiGate, the same tokens and appliance work for both VPN and PAM." |
| "Can't WALLIX do MFA by itself?" | "WALLIX supports MFA natively for some methods, but FortiAuthenticator adds the token lifecycle management, push notifications, and hardware token support that enterprise deployments need." |
| "Why RADIUS and not SAML?" | "WALLIX uses RADIUS for the second factor because it works across all access methods: Web UI, SSH proxy, and RDP proxy. SAML only works for web-based access." |
| "What if FortiAuth goes down?" | "We deploy HA (active-passive). If both fail, a break-glass local account with no MFA provides emergency access, heavily monitored and alerted." |

---

## 3. Architecture Decision Matrix

### 3.1 Which Architecture Fits?

| Client Profile | Architecture | FortiAuth Model | HA? | Notes |
|---------------|-------------|-----------------|-----|-------|
| Small (1-50 users, 1 site) | Single FortiAuth VM | VM or 200F | No | Simplest. Backup strategy critical. |
| Medium (50-200 users, 1-3 sites) | FortiAuth 300F with HA | 300F | Yes | Standard enterprise deployment. |
| Large (200-1000 users, 3-10 sites) | FortiAuth 400F with HA | 400F | Yes | Consider load and sync performance. |
| Enterprise (1000+ users, 10+ sites) | FortiAuth cluster or 3000F | 3000F | Yes | Dedicated planning for token enrollment at scale. |
| Hybrid (cloud + on-prem) | FortiAuth on-prem + cloud connector | Varies | Yes | May need FortiAuth Cloud for cloud workloads. |

### 3.2 Where to Place FortiAuthenticator

```
+==============================================================================+
|  FORTIAUTHENTICATOR PLACEMENT -- DECISION GUIDE                              |
+==============================================================================+
|                                                                              |
|  OPTION A: SHARED INFRASTRUCTURE VLAN (RECOMMENDED)                          |
|  ==================================================                          |
|                                                                              |
|  Place FortiAuth in the same subnet as AD DCs and shared services.           |
|  All sites reach it via MPLS/WAN.                                            |
|                                                                              |
|  Pros: single management point, simple HA, centralized tokens                |
|  Cons: depends on WAN; if WAN fails, remote sites lose MFA                   |
|  Mitigation: break-glass accounts at each site                               |
|                                                                              |
|  Best for: clients with reliable MPLS, centralized IT                        |
|                                                                              |
|  -----------------------------------------------------------------------     |
|                                                                              |
|  OPTION B: CO-LOCATED WITH PRIMARY BASTION SITE                              |
|  ===============================================                             |
|                                                                              |
|  Place FortiAuth at the main datacenter alongside the primary Bastion.       |
|  Secondary FortiAuth at DR site.                                             |
|                                                                              |
|  Pros: lowest latency for primary site, HA across datacenters                |
|  Cons: remote sites still depend on WAN for RADIUS                           |
|  Mitigation: same as Option A                                                |
|                                                                              |
|  Best for: hub-and-spoke networks, datacenter-centric orgs                   |
|                                                                              |
|  -----------------------------------------------------------------------     |
|                                                                              |
|  OPTION C: DISTRIBUTED (one FortiAuth per region)                            |
|  ================================================                            |
|                                                                              |
|  Deploy FortiAuth appliances at each major region.                           |
|  All sync from same AD, each handles local RADIUS.                           |
|                                                                              |
|  Pros: survives WAN outages, lowest latency everywhere                       |
|  Cons: more appliances, more licensing, complex sync                         |
|  Mitigation: careful HA planning per region                                  |
|                                                                              |
|  Best for: clients with poor WAN, strict uptime SLAs, geo-distributed        |
|                                                                              |
+==============================================================================+
```

### 3.3 Decision Flowchart

```
Is WAN reliable (< 50ms latency, 99.9% uptime)?
|
+-- YES --> How many sites?
|           |
|           +-- 1-5 sites --> OPTION A: Centralized FortiAuth
|           |
|           +-- 5+ sites --> OPTION B: Primary + DR site FortiAuth
|
+-- NO  --> Are there regional clusters of sites?
            |
            +-- YES --> OPTION C: One FortiAuth per region
            |
            +-- NO  --> OPTION A + aggressive break-glass planning
```

---

## 4. The Two-Phase Authentication Model

### 4.1 Why Two Phases?

This is the most important concept to communicate to the client's technical team:

```
+==============================================================================+
|  THE TWO-PHASE MODEL -- WHY IT MATTERS                                       |
+==============================================================================+
|                                                                              |
|  PHASE 1: WALLIX validates password directly against Active Directory (LDAP) |
|  PHASE 2: WALLIX asks FortiAuth to validate the second factor (RADIUS)       |
|                                                                              |
|  WHY NOT SEND EVERYTHING TO FORTIAUTH?                                       |
|  =====================================                                       |
|                                                                              |
|  Bad approach (single-phase):                                                |
|  User -> WALLIX -> FortiAuth (password + OTP together)                       |
|  Problems:                                                                   |
|  * FortiAuth would need to validate the password against AD                  |
|  * Adds latency (FortiAuth -> AD -> FortiAuth -> WALLIX)                     |
|  * FortiAuth becomes a bottleneck for ALL authentication                     |
|  * If FortiAuth is down, no one can log in at all                            |
|  * Password lockout policies in AD may be triggered by FortiAuth retries     |
|                                                                              |
|  Good approach (two-phase):                                                  |
|  User -> WALLIX -> AD (password only)     DIRECT, FAST                       |
|  User -> WALLIX -> FortiAuth (OTP only)   SEPARATE, FOCUSED                  |
|  Benefits:                                                                   |
|  * Each system does ONE thing well                                           |
|  * If FortiAuth is down, break-glass still works (local auth)                |
|  * AD lockout policies work correctly (WALLIX binds directly)                |
|  * FortiAuth is lighter (only validates OTP, not passwords)                  |
|  * Easier to troubleshoot (Phase 1 issue vs Phase 2 issue)                   |
|                                                                              |
+==============================================================================+
```

### 4.2 The Critical FortiAuth Setting

This is the single most common misconfiguration. Emphasize it in every engagement:

```
+==============================================================================+
|                                                                              |
|  FORTIAUTHENTICATOR RADIUS POLICY                                            |
|                                                                              |
|  First Factor:   N O N E                                                     |
|                  =======                                                     |
|                                                                              |
|  NOT LDAP. NOT Local. NOT anything.                                          |
|                                                                              |
|  NONE.                                                                       |
|                                                                              |
|  WALLIX already validated the password. FortiAuth only checks the token.     |
|  Setting First Factor to LDAP causes:                                        |
|                                                                              |
|  * Double password prompt (user confusion)                                   |
|  * Double password validation (unnecessary AD load)                          |
|  * Broken auth if password format doesn't match RADIUS expectation           |
|  * Doubled account lockout risk (two LDAP bind attempts per login)           |
|                                                                              |
|  If you remember ONE thing from this guide, remember this.                   |
|                                                                              |
+==============================================================================+
```

---

## 5. Token Strategy

### 5.1 FortiToken Mobile vs Hardware Tokens

| Criterion | FortiToken Mobile | FortiToken Hardware (200/300) |
|-----------|-------------------|-------------------------------|
| **Cost per user** | Lower (software) | Higher (physical device) |
| **User experience** | Push notification (tap to approve) | Manual 6-digit entry |
| **Deployment speed** | Fast (email activation) | Slow (physical distribution) |
| **Lost/stolen recovery** | Revoke + re-provision (minutes) | Ship new token (days) |
| **Battery life** | N/A (phone battery) | ~5 years (then replace all) |
| **No-smartphone users** | Not possible | Works for everyone |
| **Offline environments** | OTP works offline, push needs internet | Always works offline |
| **Security level** | High (phone + PIN/biometric) | High (dedicated device) |

### 5.2 Recommendation by User Type

| User Type | Recommended Token | Rationale |
|-----------|-------------------|-----------|
| IT Administrators | FortiToken Mobile + push | Fastest login, most sessions per day |
| Operators | FortiToken Mobile + push | Balance of speed and security |
| Auditors | FortiToken Mobile (OTP or push) | Less frequent access |
| External contractors | FortiToken Mobile | Easy to provision and revoke remotely |
| OT/plant floor users | Hardware token | May not carry smartphones in industrial areas |
| Executive assistants | FortiToken Mobile + push | Minimal friction for occasional access |
| Break-glass accounts | None (exempt) | Must work when MFA infrastructure is down |

### 5.3 Token Lifecycle

```
+==============================================================================+
|  TOKEN LIFECYCLE -- EXPLAIN TO CLIENT                                        |
+==============================================================================+
|                                                                              |
|  1. PROVISION                                                                |
|     Admin assigns token to user in FortiAuth                                 |
|     User receives activation email with QR code                              |
|     License consumed (1 token = 1 license slot)                              |
|                                                                              |
|  2. ACTIVATE                                                                 |
|     User scans QR code with FortiToken Mobile app                            |
|     Token registers with FortiAuth (cryptographic seed shared)               |
|     Token is now generating valid OTP codes                                  |
|                                                                              |
|  3. USE                                                                      |
|     Every login: approve push or enter 6-digit OTP                           |
|     OTP changes every 60 seconds (TOTP algorithm)                            |
|     No internet needed for OTP -- push needs internet                        |
|                                                                              |
|  4. RESYNC (if needed)                                                       |
|     If OTP stops working (phone clock drift)                                 |
|     Admin enters two consecutive OTP codes from user                         |
|     FortiAuth recalculates time offset                                       |
|                                                                              |
|  5. REVOKE (offboarding)                                                     |
|     Admin revokes token in FortiAuth                                         |
|     License returns to pool (reusable for next user)                         |
|     Token on phone becomes invalid                                           |
|                                                                              |
|  KEY POINTS FOR THE CLIENT:                                                  |
|  * Licenses are not "burned" -- revoked tokens free the license              |
|  * No annual per-token cost -- one-time purchase                             |
|  * Lost phone? Revoke old token, provision new one. 5 minutes.               |
|  * User changes phone? Same process -- revoke, re-provision.                 |
|                                                                              |
+==============================================================================+
```

---

## 6. Group and Profile Strategy

### 6.1 Designing the AD Group Structure

Help the client design their group structure. The goal: AD groups are the single source of truth for both authorization (what you can access) and MFA enrollment (whether you need a token).

```
+==============================================================================+
|  RECOMMENDED AD GROUP DESIGN                                                 |
+==============================================================================+
|                                                                              |
|  OU=PAM,DC=company,DC=com                                                    |
|    |                                                                         |
|    +-- OU=Groups                                                             |
|    |     |                                                                   |
|    |     +-- PAM-MFA-Users       (all users who need MFA)                    |
|    |     +-- PAM-MFA-Exempt      (break-glass, service accounts)             |
|    |     |                                                                   |
|    |     +-- PAM-Admins          (WALLIX administrator profile)              |
|    |     +-- PAM-Operators       (WALLIX operator profile)                   |
|    |     +-- PAM-Auditors        (WALLIX auditor profile)                    |
|    |     |                                                                   |
|    |     +-- PAM-Linux-Servers   (access to Linux targets)                   |
|    |     +-- PAM-Windows-Servers (access to Windows targets)                 |
|    |     +-- PAM-Network-Devices (access to network equipment)               |
|    |     +-- PAM-Databases       (access to database servers)                |
|    |                                                                         |
|    +-- OU=Service Accounts                                                   |
|          |                                                                   |
|          +-- svc_wallix          (WALLIX LDAP bind)                          |
|          +-- svc-fortiauth       (FortiAuth LDAP sync)                       |
|                                                                              |
|  DESIGN PRINCIPLES:                                                          |
|  * Role groups (Admin/Operator/Auditor) control the WALLIX profile           |
|  * Target groups (Linux/Windows/Network/DB) control what they can access     |
|  * MFA group controls token enrollment scope                                 |
|  * Users belong to 1 role group + 1 or more target groups + MFA group        |
|  * Separation of duties: Auditors cannot be Admins                           |
|                                                                              |
+==============================================================================+
```

### 6.2 Group-to-Profile Mapping Conversation

Walk the client through this table and get sign-off:

| AD Group | WALLIX Profile | Can Do | Cannot Do |
|----------|---------------|--------|-----------|
| PAM-Admins | administrator | Full WALLIX admin, manage users, change config | N/A -- full access |
| PAM-Operators | operator | Connect to targets, manage target credentials | Change WALLIX config, manage users |
| PAM-Auditors | auditor | View sessions, generate reports, read-only access | Connect to targets, change anything |
| _(no group match)_ | _(denied)_ | Nothing -- login rejected | Everything |

> **Tip:** Always set the default (no matching group) to DENY. If a user authenticates via AD+MFA but has no WALLIX profile mapping, they should get rejected, not granted a default profile. This prevents privilege escalation if someone is added to PAM-MFA-Users but not to a role group.

---

## 7. High Availability Patterns

### 7.1 HA Decision Guide

| Question | Yes | No |
|----------|-----|-----|
| Is this a production environment? | HA recommended | HA optional |
| Are there compliance requirements for availability? | HA mandatory | HA recommended |
| Is there a DR site? | HA across sites | HA within single site |
| Budget allows for 2x FortiAuth? | Deploy HA | Single + strong backup strategy |
| Client has > 100 users? | HA strongly recommended | HA optional |

### 7.2 HA Patterns

```
+==============================================================================+
|  PATTERN 1: SINGLE SITE HA (most common)                                     |
+==============================================================================+
|                                                                              |
|  FortiAuth Primary (10.20.0.60) --- HA Sync --- FortiAuth Secondary (10.20.0.6
|                                                                              |
|  Both in same VLAN, same datacenter.                                         |
|  Active-Passive: primary handles all requests, secondary is standby.         |
|  WALLIX configured with both as RADIUS servers (primary = priority 1).       |
|                                                                              |
|  RTO: < 30 seconds (WALLIX auto-fails over to secondary)                     |
|  RPO: near-zero (HA sync interval: 60 seconds)                               |
+==============================================================================+

+==============================================================================+
|  PATTERN 2: CROSS-SITE HA (for DR)                                           |
+==============================================================================+
|                                                                              |
|  DC-A: FortiAuth Primary (10.20.0.60) --- WAN --- DC-B: FortiAuth (10.20.0.61)
|                                                                              |
|  Primary at main datacenter, secondary at DR site.                           |
|  HA sync over WAN (must allow port 8009 between sites).                      |
|  Higher RPO due to WAN latency (sync may lag 1-5 minutes).                   |
|                                                                              |
|  RTO: < 30 seconds (same as Pattern 1)                                       |
|  RPO: 1-5 minutes (WAN-dependent sync lag)                                   |
+==============================================================================+

+==============================================================================+
|  PATTERN 3: NO HA (budget constraint)                                        |
+==============================================================================+
|                                                                              |
|  FortiAuth Primary (10.20.0.60) only.                                        |
|  No secondary appliance.                                                     |
|                                                                              |
|  MANDATORY compensating controls:                                            |
|  * Daily backup to SFTP server (automated)                                   |
|  * Break-glass account tested quarterly                                      |
|  * Documented restore procedure (< 1 hour RTO target)                        |
|  * Client accepts risk of MFA unavailability during outage                   |
|                                                                              |
|  RTO: 30-60 minutes (restore from backup)                                    |
|  RPO: up to 24 hours (daily backup)                                          |
+==============================================================================+
```

---

## 8. Common Client Scenarios

### 8.1 Scenario Matrix

| Scenario | Complexity | Key Challenge | Approach |
|----------|-----------|---------------|----------|
| **Greenfield** -- no WALLIX, no MFA | Medium | Everything is new -- more work but no legacy constraints | Standard phased deployment |
| **Add MFA to existing WALLIX** | Low | WALLIX already has AD integration -- just add RADIUS | Start at Phase 2 (FortiAuth config) |
| **Replace existing MFA provider** | Medium | User re-enrollment, parallel running period | Run old and new MFA in parallel, migrate in batches |
| **Existing FortiToken for VPN** | Low | FortiAuth already deployed with tokens | Just add WALLIX as RADIUS client + new policy |
| **Multi-domain AD** | High | Multiple LDAP domains, user disambiguation | Use Global Catalog or separate LDAP domain per forest |
| **Azure AD hybrid** | High | Cloud vs on-prem identity, sync timing | Ensure on-prem AD is authoritative for PAM users |
| **OT/air-gapped sites** | High | No internet for push, limited WAN | Hardware tokens, local FortiAuth per site, aggressive break-glass |

### 8.2 The "Already Have FortiToken" Shortcut

This is a common and favorable scenario. When the client already uses FortiToken for VPN:

```
WHAT CHANGES (ALMOST NOTHING FOR USERS)
========================================

Step 1: Add WALLIX Bastion nodes as RADIUS clients on existing FortiAuth
        (12 entries, 10 minutes of work)

Step 2: Create a NEW RADIUS policy "WALLIX-MFA-Policy"
        First Factor: None (critical!)
        Second Factor: FortiToken
        Clients: WALLIX-* entries only
        (Keep the existing VPN policy unchanged)

Step 3: Configure WALLIX to use existing FortiAuth as RADIUS server

Step 4: Test -- users use the SAME FortiToken app, SAME token
        They just approve one more push (for WALLIX, in addition to VPN)

WHAT DOES NOT CHANGE:
- No new app to install
- No new token to activate
- No re-enrollment
- No new hardware

PROJECT TIMELINE: 2-3 days instead of 2-3 weeks
```

---

## 9. Anti-Patterns to Avoid

### 9.1 Technical Anti-Patterns

| Anti-Pattern | Why It's Bad | What to Do Instead |
|-------------|-------------|-------------------|
| Setting FortiAuth First Factor to LDAP | Double password validation, breaks auth flow | Set First Factor to **None** |
| Using Domain Admin for LDAP bind | Massively overprivileged, security risk | Create dedicated read-only service accounts |
| Skipping NTP configuration | All OTP codes rejected (time-based) | Configure and verify NTP on every component before anything else |
| Using LDAP (389) instead of LDAPS (636) | Passwords transmitted in cleartext | Always use LDAPS; deploy AD CS if needed |
| Single RADIUS shared secret across different systems | VPN and PAM share the same secret -- compromise one, compromise both | Different shared secrets for VPN vs PAM RADIUS policies |
| Hardcoding IPs instead of FQDNs | DC replacement requires config changes everywhere | Use FQDNs for LDAP; use IPs only for RADIUS failover targets |
| Not registering ALL Bastion nodes as RADIUS clients | MFA silently fails on unregistered nodes | Count nodes, count RADIUS clients -- numbers must match |

### 9.2 Process Anti-Patterns

| Anti-Pattern | Why It's Bad | What to Do Instead |
|-------------|-------------|-------------------|
| Big-bang MFA enforcement | Users locked out, support overwhelmed, executive backlash | Phased rollout: pilot -> early adopters -> general -> enforce |
| No break-glass account | If FortiAuth is down, nobody can manage WALLIX | Create local break-glass account with alerting before enabling MFA |
| Skipping token activation tracking | Enforcement day arrives, 30% of users haven't activated | Track activation %, follow up with stragglers weekly |
| No executive communication | Users surprised by MFA, perceive it as IT imposing burden | Executive email explaining WHY, framing it as protection |
| Testing only from one site | Works at HQ, fails at remote site due to firewall rule gap | Test from every Bastion node before declaring success |
| No runbook for token issues | Every "my token doesn't work" call becomes a 30-minute troubleshooting session | Create a simple flowchart for L1 support |

---

## 10. Competitive Positioning

### 10.1 FortiAuth vs Alternatives

Use this **only when the client asks** or is comparing options. Never badmouth competitors -- focus on advantages.

| Feature | FortiAuthenticator | Duo | Azure MFA | RSA SecurID |
|---------|-------------------|-----|-----------|-------------|
| Deployment | On-prem appliance | Cloud | Cloud | On-prem or cloud |
| Push notification | Yes | Yes | Yes | Yes |
| TOTP (offline) | Yes | Yes | Limited | Yes |
| Hardware tokens | Yes (FortiToken) | Yes (limited) | FIDO2 keys | Yes (RSA tokens) |
| RADIUS support | Native | Yes | NPS extension | Native |
| Per-auth cost | None (appliance + token license) | Per user/month | Per user/month or P2 license | Per user/year |
| WAN/internet dependency | None (on-prem) | Yes (cloud) | Yes (cloud) | Depends on deployment |
| Works if internet is down | Yes | No | No | Depends |
| Fortinet ecosystem synergy | Full (FortiGate, FortiManager) | None | Azure ecosystem | None |

### 10.2 When to Recommend FortiAuth

**Strong fit:**
- Client already has Fortinet infrastructure (FortiGate, FortiManager)
- Client needs on-prem MFA (air-gapped, OT, compliance)
- Client wants no per-authentication cloud charges
- Client has unreliable or restricted internet at remote sites

**Consider alternatives if:**
- Client is fully cloud-native (Azure MFA may be simpler)
- Client has < 10 users and no Fortinet products (Duo may be faster to deploy)
- Client requires FIDO2/passwordless as primary method (Azure/Duo stronger here today)

---

## Quick Concepts Reference Card

Print this and keep it in your notebook during client meetings:

```
+==============================================================================+
|  QUICK REFERENCE -- KEY CONCEPTS                                             |
+==============================================================================+
|                                                                              |
|  TWO PHASES:                                                                 |
|    Phase 1: WALLIX -> AD (LDAPS 636) = password validation                   |
|    Phase 2: WALLIX -> FortiAuth (RADIUS 1812) = OTP/push validation          |
|                                                                              |
|  FORTIAUTH FIRST FACTOR = NONE  (always, never LDAP)                         |
|                                                                              |
|  THREE SERVICE ACCOUNTS:                                                     |
|    svc_wallix       -- WALLIX LDAP bind to AD (read-only)                    |
|    svc-fortiauth    -- FortiAuth LDAP sync from AD (read-only)               |
|    breakglass-admin -- Local WALLIX account, no MFA, alerted                 |
|                                                                              |
|  NTP BEFORE EVERYTHING:                                                      |
|    > 30 seconds drift = 100% OTP failure rate                                |
|                                                                              |
|  TOKEN LICENSES ARE PERPETUAL:                                               |
|    Buy once, revoked tokens return to pool, no annual per-token cost         |
|                                                                              |
|  COUNT YOUR RADIUS CLIENTS:                                                  |
|    Bastion nodes + Access Managers = total RADIUS client entries             |
|    Missing one = MFA fails silently on that node                             |
|                                                                              |
|  DEFAULT PROFILE = DENY:                                                     |
|    If no AD group matches, user should be rejected, not granted access       |
|                                                                              |
+==============================================================================+
```

---

*Version 1.0 -- 2026-04-10*
