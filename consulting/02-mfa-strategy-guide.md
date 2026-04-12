# MFA Strategy Guide

## Privileged Access Management with Multi-Factor Authentication

This guide supports client-facing conversations throughout the engagement:
from initial introduction of MFA concepts to architecture decisions, target
scope, role design, and FortiAuthenticator configuration.

---

## Table of Contents

1. [Introducing MFA to the Client](#1-introducing-mfa-to-the-client)
2. [Why This Solution, Why Now](#2-why-this-solution-why-now)
3. [MFA Technology Overview](#3-mfa-technology-overview)
4. [Engagement Objectives](#4-engagement-objectives)
5. [Target Systems and Protected Connections](#5-target-systems-and-protected-connections)
6. [Roles and Access Control](#6-roles-and-access-control)
7. [FortiAuthenticator: Securing Every Connection](#7-fortiauthenticator-securing-every-connection)
8. [The Two-Phase Authentication Model](#8-the-two-phase-authentication-model)
9. [Architecture Decision Guide](#9-architecture-decision-guide)
10. [High Availability Patterns](#10-high-availability-patterns)
11. [Common Client Scenarios](#11-common-client-scenarios)
12. [Compliance and Audit Readiness](#12-compliance-and-audit-readiness)
13. [Quick Reference Card](#13-quick-reference-card)

---

## 1. Introducing MFA to the Client

### 1.1 The Opening Message

When presenting MFA to stakeholders for the first time, lead with the
business problem, not the technology. The goal is alignment, not a
product demonstration.

**For executive stakeholders (CISO, CIO, board):**

> "Privileged accounts — the ones that can access your servers, your
> backups, your network equipment — are the primary target in almost every
> major breach. A stolen password is sufficient to gain that access today.
> Multi-factor authentication changes the equation: even if a password is
> compromised, access requires a second proof of identity that only the
> legitimate user holds. This engagement implements that control across
> your entire privileged access infrastructure."

**For IT managers and team leads:**

> "We are adding a second authentication step to WALLIX Bastion. Users
> will enter their Active Directory password as usual, then approve a
> notification on their phone. The change is minimal for users. The
> security benefit is substantial: stolen credentials alone cannot grant
> access to any system behind the bastion."

**For end users:**

> "Starting on [DATE], logging into the privileged access system will
> require one extra step: after entering your password, you will tap
> Approve on your phone. That is the entire change. It takes two to three
> seconds and protects both your accounts and the systems you manage."

### 1.2 Addressing Concerns Before They Are Raised

| Concern | Response |
|---------|----------|
| "This will slow us down." | "The approval tap takes 2–3 seconds. The operational impact is negligible compared to the risk exposure it eliminates." |
| "What if I lose my phone?" | "An administrator can issue a temporary bypass in under two minutes. No user is permanently locked out. We also maintain a break-glass account for genuine emergencies." |
| "I don't want a work app on my personal phone." | "FortiToken Mobile is a standalone authentication app. It cannot access, read, or transmit any data from your device. A hardware token is available as an alternative." |
| "We have never had a breach." | "MFA is preventive, not reactive. By the time a breach is confirmed, the cost is already significant. The value of MFA is precisely that it acts before an incident occurs." |
| "It is too expensive." | "FortiToken licenses are a one-time purchase. There are no per-authentication charges. The average cost of a breach involving compromised credentials exceeds $4.8M — the token investment is a fraction of that exposure." |

### 1.3 What MFA Does — and Does Not — Address

Position MFA accurately. Overstating its scope damages credibility.

| MFA Addresses | MFA Does Not Address |
|---------------|----------------------|
| Stolen or phished passwords | Insider threats from authorized users |
| Credential stuffing attacks | Session hijacking after authentication |
| Brute force attacks | Malware on the endpoint |
| Most automated credential attacks | Social engineering targeting MFA itself |
| Keylogger exposure (password alone is useless) | Physical access to an unlocked session |

> "MFA is a critical control, not a complete security program. It
> eliminates the risk of compromised credentials, which is the leading
> cause of breaches. It complements session recording, access controls,
> and monitoring — it does not replace them."

---

## 2. Why This Solution, Why Now

### 2.1 The Business Case

```
+===============================================================================+
|  WHY PRIVILEGED ACCESS MANAGEMENT WITH MFA                                    |
+===============================================================================+
|                                                                               |
|  RISK REDUCTION                                                               |
|  * 80% of breaches involve compromised credentials (Verizon DBIR 2024)        |
|  * Privileged accounts are the primary target in all major attack classes     |
|  * MFA blocks over 99% of automated credential-based attacks                  |
|  * Session recording provides forensic evidence when incidents occur          |
|                                                                               |
|  COMPLIANCE                                                                   |
|  * ISO 27001 A.8.5 — secure authentication for privileged access              |
|  * SOC 2 CC6.1 — MFA as a required logical access control                     |
|  * PCI-DSS 8.4.2 — MFA mandatory for all non-console admin access             |
|  * NIS2 Article 21 — MFA required for critical infrastructure access          |
|  * NIST 800-53 IA-2 — MFA for privileged and non-privileged accounts          |
|                                                                               |
|  OPERATIONAL BENEFIT                                                          |
|  * Centralized access gateway — one place to manage who accesses what         |
|  * Full session recording — complete audit trail for every privileged action  |
|  * Automated credential rotation — no shared passwords for target systems     |
|  * Single offboarding action — disable in AD, access removed everywhere       |
|                                                                               |
+===============================================================================+
```

### 2.2 Why FortiAuthenticator and WALLIX Bastion

The combination of WALLIX Bastion and FortiAuthenticator creates a layered
architecture where each component has a single, well-defined responsibility.

| Component | Responsibility | Protocol | VLAN | Placement |
|-----------|---------------|----------|------|-----------|
| **Active Directory** | Identity and password validation | LDAPS (636) | Cyber | Local HA pair of DCs per site |
| **FortiAuthenticator** | Second factor validation (token) | RADIUS (1812) | Cyber | Local HA pair per site (2 nodes × 5 sites = 10 total) |
| **WALLIX Bastion** | Authorization, access control, session recording | SSH, RDP, HTTPS | DMZ | Local HA pair per site (2 nodes × 5 sites = 10 total) |

**Key architectural point:** Both authentication phases are fully local to each site.
Phase 1 (password) — WALLIX binds to the local Cyber VLAN AD DCs via LDAPS.
Phase 2 (token) — WALLIX sends RADIUS to the local Cyber VLAN FortiAuthenticator.
Neither phase crosses the MPLS WAN. A WAN outage does not affect authentication
at any site.

### 2.3 Per-Site VLAN Architecture

```
+===============================================================================+
|  PER-SITE VLAN DESIGN (identical at all 5 sites)                              |
+===============================================================================+
|                                                                               |
|  CYBER VLAN                                                                   |
|  +----------------------------------+                                         |
|  |  AD Domain Controller 1  (HA)   |  <-- LDAPS 636 from DMZ Bastions         |
|  |  AD Domain Controller 2  (HA)   |      (Phase 1 — local, no WAN)           |
|  +----------------------------------+                                         |
|  |  FortiAuthenticator node 1 (HA) |  <-- RADIUS 1812 from DMZ Bastions       |
|  |  FortiAuthenticator node 2 (HA) |      (Phase 2 — local, no WAN)           |
|  |                                 |  --> LDAPS 636 to local AD DCs (sync)    |
|  +----------------------------------+                                         |
|                                                                               |
|      ^  LDAPS 636 (Phase 1)    ^  RADIUS 1812 (Phase 2)                       |
|      |  local, intra-VLAN      |  local, intra-VLAN                           |
|                                                                               |
|  DMZ VLAN                                                                     |
|  +----------------------------------+                                         |
|  |  WALLIX Bastion node 1  (HA)    |                                          |
|  |  WALLIX Bastion node 2  (HA)    |                                          |
|  +----------------------------------+                                         |
|           |                                                                   |
|           | SSH 22 / RDP 3389 / HTTPS 443 (to targets)                        |
|           v                                                                   |
|  SERVER / TARGET VLANs                                                        |
|                                                                               |
|  Users connect to Bastions (DMZ) via SSH 22, RDP 3389, HTTPS 443              |
|  Access Managers (external team) connect to Bastions from their VLAN          |
|                                                                               |
|  WAN (MPLS) carries only: AM connections, inter-site management               |
|  Authentication traffic (LDAPS + RADIUS) never leaves the local site          |
|                                                                               |
+===============================================================================+
```

### 2.4 Required Inter-VLAN Firewall Rules

These rules must be in place before any integration testing can begin.
Submit the full list to the network team on Day 1.

| Source VLAN | Destination VLAN | Protocol | Port | Purpose | Scope |
|-------------|-----------------|----------|------|---------|-------|
| DMZ (Bastion) | Cyber (local AD) | TCP | 636 | WALLIX LDAPS bind — password validation (Phase 1) | Intra-site |
| DMZ (Bastion) | Cyber (local FortiAuth) | UDP | 1812 | WALLIX RADIUS — token validation (Phase 2) | Intra-site |
| Cyber (FortiAuth) | Cyber (local AD) | TCP | 636 | FortiAuth LDAP sync — user and group import | Intra-site |
| Users VLAN | DMZ (Bastion) | TCP | 443 | WALLIX Web UI access | Intra-site |
| Users VLAN | DMZ (Bastion) | TCP | 22 | WALLIX SSH proxy access | Intra-site |
| Users VLAN | DMZ (Bastion) | TCP | 3389 | WALLIX RDP proxy access | Intra-site |
| DMZ (Bastion) | Server VLANs | TCP | 22 | Bastion SSH to Linux targets | Intra-site |
| DMZ (Bastion) | Server VLANs | TCP | 3389 | Bastion RDP to Windows targets | Intra-site |
| AM VLAN (external) | DMZ (Bastion) | TCP | 443 | Access Manager to Bastion connectivity | Cross-site (MPLS) |

**Note:** The Access Manager team is responsible for the firewall rules on
their side (AM VLAN → DMZ). Confirm with them which rules they require and
who submits their change requests.

**Client talking points:**

| Question | Response |
|----------|----------|
| "Why not Azure MFA?" | "Azure MFA is well-suited to cloud applications. For on-premises PAM across SSH and RDP proxies, RADIUS provides lower latency and functions without internet connectivity. FortiAuth delivers on-premises MFA that operates independently of your internet link." |
| "Why not Duo?" | "Duo is a strong product but it is cloud-dependent. FortiAuth is on-premises with no per-authentication cloud charges. For clients already using FortiGate, the same tokens and appliance serve both VPN and PAM." |
| "Why RADIUS and not SAML?" | "WALLIX uses RADIUS for the second factor because RADIUS works across all access methods: web interface, SSH proxy, and RDP proxy. SAML is limited to browser-based authentication only." |
| "What if FortiAuth goes down?" | "FortiAuthenticator is deployed in Active-Passive HA. If both nodes fail simultaneously, the designated break-glass account provides emergency access. That account is monitored, alerted on every use, and its password is stored in a sealed envelope." |

---

## 3. MFA Technology Overview

### 3.1 Authentication Factors

| Factor | Description | Example | Client Analogy |
|--------|-------------|---------|----------------|
| **Knowledge** | Something the user knows | Password, PIN | The combination to a safe |
| **Possession** | Something the user physically holds | Phone with FortiToken, hardware token | A physical key |
| **Inherence** | A biological characteristic | Fingerprint, facial recognition | A handwritten signature |

This engagement implements **Knowledge + Possession**: the AD password
(knowledge) validated directly by WALLIX, and the FortiToken TOTP code
(possession) validated by FortiAuthenticator via RADIUS.

### 3.2 FortiToken Mobile

FortiToken Mobile is a time-based OTP (TOTP) application for iOS and Android.
It supports two authentication modes:

| Mode | How It Works | Internet Required | Status in This Deployment |
|------|-------------|-------------------|--------------------------|
| **TOTP (manual OTP)** | User reads a 6-digit code that changes every 60 s | No — works fully offline | **Active — used in this deployment** |
| **Push notification** | User receives a notification and taps Approve | Yes (phone must have internet) | Not used — TOTP only |

### 3.3 FortiToken Hardware (200 / 300)

A physical device that generates a 6-digit OTP every 60 seconds. No
smartphone required. Appropriate for:

- OT and plant floor environments where smartphones are not permitted
- Users in security-sensitive areas who may not carry personal devices
- Environments where BYOD is not acceptable

| Criterion | FortiToken Mobile | FortiToken Hardware |
|-----------|-------------------|---------------------|
| Cost per user | Lower (software license) | Higher (physical device) |
| User experience | TOTP — 6-digit code from app (push not used) | TOTP — 6-digit code from device |
| Deployment speed | Fast — email activation link | Slower — physical distribution |
| Lost / stolen recovery | Revoke and re-provision in minutes | Requires physical replacement |
| Battery | N/A | ~5 years, then device replacement |
| Offline use | TOTP always works offline (push not configured) | Always offline capable |

### 3.4 How RADIUS Integrates with WALLIX

RADIUS (Remote Authentication Dial-In User Service) is the industry-standard
protocol for forwarding authentication requests to a centralized server.

In plain terms:

> "When a user enters their 6-digit TOTP code, WALLIX sends a message to
> FortiAuthenticator: 'This user presented this code — is it valid?'
> FortiAuthenticator verifies the token and replies with Accept or Reject.
> WALLIX grants or denies access based on that reply. The two systems
> communicate over an encrypted channel using a shared secret that is
> unique to this integration. No internet connection is required — the
> TOTP code is generated locally on the user's device."

Key configuration parameters:

| Parameter | Value | Purpose |
|-----------|-------|---------|
| RADIUS server IP | FortiAuth IP (primary + secondary) | Where WALLIX sends MFA requests |
| Shared secret | Unique per integration | Authenticates the RADIUS conversation |
| Port | UDP 1812 | Standard RADIUS authentication port |
| Timeout | 30 s | How long WALLIX waits for a response |
| Retry | 2 | Number of retries before failover to secondary |

---

## 4. Engagement Objectives

### 4.1 End-to-End Objectives

A successful engagement delivers the following outcomes. Present these as
the agreed definition of done at the kickoff meeting.

```
+===============================================================================+
|  ENGAGEMENT OBJECTIVES                                                        |
+===============================================================================+
|                                                                               |
|  SECURITY OBJECTIVES                                                          |
|  [ ] All privileged access to target systems requires two factors             |
|  [ ] No access path exists that bypasses WALLIX Bastion and MFA               |
|  [ ] All sessions are recorded with full audit trail                          |
|  [ ] Credentials to target systems are managed by WALLIX (no shared root)    |
|  [ ] Break-glass access is documented, tested, and alerted on use             |
|                                                                               |
|  OPERATIONAL OBJECTIVES                                                       |
|  [ ] Active Directory is the single source of truth for user identity         |
|  [ ] User onboarding and offboarding are driven entirely by AD group changes  |
|  [ ] FortiAuthenticator HA is configured and failover is tested               |
|  [ ] All target systems are reachable from all WALLIX nodes                   |
|  [ ] Token activation rate > 95% before MFA enforcement                      |
|                                                                               |
|  COMPLIANCE OBJECTIVES                                                        |
|  [ ] Audit evidence collection is documented and tested                       |
|  [ ] MFA enforcement satisfies applicable compliance frameworks               |
|  [ ] A compliance mapping document is delivered and signed off                |
|  [ ] Runbooks for auditor requests are in place                               |
|                                                                               |
|  KNOWLEDGE TRANSFER OBJECTIVES                                                |
|  [ ] Internal team can onboard and offboard users independently               |
|  [ ] Service desk has a troubleshooting guide and can handle L1 calls         |
|  [ ] Operations runbook covers all routine and emergency procedures           |
|  [ ] At least one internal owner per system (AD, FortiAuth, WALLIX)           |
|                                                                               |
+===============================================================================+
```

### 4.2 Success Criteria by Phase

| Phase | Success Criteria |
|-------|-----------------|
| Discovery | Readiness score completed, all gaps identified, architecture agreed |
| Build | All components configured, HA verified, connectivity confirmed from all sites |
| Test | All test cases passed; failure scenarios exercised; break-glass tested |
| Rollout | Token activation > 95%; MFA enforced; no critical support incidents |
| Handover | Internal team operates independently; all documentation delivered |

---

## 5. Target Systems and Protected Connections

### 5.1 What WALLIX Bastion Protects

WALLIX Bastion acts as a mandatory gateway between users and target systems.
No direct connection to a target is permitted once the bastion is in place.
Every connection is authenticated, authorized, and recorded.

```
+===============================================================================+
|  PROTECTED ACCESS MODEL                                                       |
+===============================================================================+
|                                                                               |
|  WITHOUT WALLIX (current state):                                              |
|                                                                               |
|  User --> [direct SSH / RDP] --> Target System                                |
|           No recording. No MFA. No centralized control.                       |
|                                                                               |
|  WITH WALLIX + MFA (target state):                                            |
|                                                                               |
|  User --> WALLIX --> [AD password check] + [FortiAuth MFA check]              |
|           WALLIX --> [authorized?] --> [session recorded]                     |
|           WALLIX --> Target System (using WALLIX-managed credentials)         |
|                                                                               |
|  Every access event: authenticated, authorized, recorded, auditable.          |
|                                                                               |
+===============================================================================+
```

### 5.2 Supported Connection Protocols

| Protocol | Port | Target Type | Use Case |
|----------|------|-------------|----------|
| SSH | 22 | Linux / Unix servers, network equipment | Command-line administration |
| RDP | 3389 | Windows Server | Graphical remote desktop |
| HTTPS | 443 | Web applications, management consoles | Browser-based admin interfaces |
| WinRM | 5985 / 5986 | Windows Server | PowerShell remoting, automation |
| VNC | 5900 | Linux desktop, legacy systems | Graphical access to non-RDP systems |
| Telnet | 23 | Legacy network equipment | Only where SSH is not available |
| Database | Varies | Oracle, MSSQL, MySQL, PostgreSQL | Direct database administration |

### 5.3 Target System Categories

Define the target scope with the client during the design review. Each
category may warrant different connection profiles and authorization rules.

| Category | Examples | Typical Protocol | Authorization Level |
|----------|----------|-----------------|---------------------|
| Production servers | Windows Server 2022, RHEL 9 / 10 | SSH, RDP | Restricted — operators only, no admin by default |
| Database servers | Oracle DB, MSSQL, PostgreSQL | SSH + DB client | Highly restricted — DBA team only |
| Network equipment | Fortigate, switches, routers | SSH, HTTPS | Network team only |
| Domain Controllers | Windows Server (AD) | RDP, WinRM | AD admin team only — highest sensitivity |
| Management platforms | VMware vCenter, IPMI, iDRAC | HTTPS | Infrastructure team only |
| Development / staging | Linux, Windows VMs | SSH, RDP | Wider scope — operators and developers |
| OT / industrial systems | PLCs, SCADA, HMI | VNC, RDP, SSH | OT-specific team; hardware tokens preferred |

### 5.4 Connection Profile Design

Each target or group of targets is assigned a **connection policy** in WALLIX
that controls:

- Which accounts are used to connect (WALLIX-managed credentials)
- Whether session recording is active (always recommended)
- Whether command filtering is applied (for SSH)
- Whether clipboard and file transfer are permitted
- Time-of-day restrictions (optional)
- Approval requirements (optional — just-in-time access)

---

## 6. Roles and Access Control

### 6.1 The WALLIX Authorization Model

Authentication (who you are) and authorization (what you can do) are
handled independently. A user who successfully authenticates via AD and MFA
is still subject to the authorization policy defined in WALLIX.

```
+===============================================================================+
|  AUTHORIZATION LAYERS                                                         |
+===============================================================================+
|                                                                               |
|  LAYER 1 — Authentication (Who are you?)                                      |
|    AD validates the password via LDAPS                                        |
|    FortiAuth validates the token via RADIUS                                   |
|    Both must succeed for the session to proceed                               |
|                                                                               |
|  LAYER 2 — Profile (What role do you have in WALLIX?)                         |
|    AD group membership maps to a WALLIX profile (Admin / Operator / Auditor)  |
|    Profile controls: what the user can see and configure in WALLIX itself     |
|                                                                               |
|  LAYER 3 — Authorization (Which targets can you reach?)                       |
|    Target groups control which systems the user can connect to                |
|    Connection policies control how (recorded, filtered, time-restricted)      |
|                                                                               |
|  DEFAULT RULE: If no group match exists, access is DENIED.                    |
|  A user who authenticates successfully but has no profile mapping is          |
|  rejected. Authentication success does not imply access.                      |
|                                                                               |
+===============================================================================+
```

### 6.2 Role Definitions

| WALLIX Role | Access Level | Typical User | What They Can Do |
|-------------|-------------|--------------|-----------------|
| **Administrator** | Full WALLIX access | PAM admin, security team | Manage users, policies, targets, credentials, configuration |
| **Operator** | Connect to authorized targets | IT engineers, sysadmins | Connect to assigned targets, view own sessions |
| **Auditor** | Read-only, reporting | Compliance team, CISO | View all sessions, generate reports, no system changes |
| **Approver** | Approve JIT access requests | Managers, security leads | Grant or deny time-limited access requests |
| _(no match)_ | **Denied** | Any unenrolled user | No access — login rejected |

### 6.3 Recommended AD Group Structure

```
+===============================================================================+
|  RECOMMENDED AD GROUP DESIGN                                                  |
+===============================================================================+
|                                                                               |
|  OU=PAM,DC=company,DC=com                                                     |
|    |                                                                          |
|    +-- OU=Groups                                                              |
|    |     |                                                                    |
|    |     +-- PAM-MFA-Users         all users enrolled for MFA                |
|    |     +-- PAM-MFA-Exempt        break-glass and service accounts           |
|    |     |                                                                    |
|    |     +-- PAM-Admins            WALLIX Administrator profile               |
|    |     +-- PAM-Operators         WALLIX Operator profile                    |
|    |     +-- PAM-Auditors          WALLIX Auditor profile                     |
|    |     +-- PAM-Approvers         JIT access approval rights                 |
|    |     |                                                                    |
|    |     +-- PAM-Linux-Servers     access to Linux target group               |
|    |     +-- PAM-Windows-Servers   access to Windows target group             |
|    |     +-- PAM-Network-Devices   access to network equipment group          |
|    |     +-- PAM-Databases         access to database server group            |
|    |     +-- PAM-DomainControllers access to DC group (restricted)            |
|    |                                                                          |
|    +-- OU=Service Accounts                                                    |
|          |                                                                    |
|          +-- svc_wallix            WALLIX LDAP bind account (read-only)       |
|          +-- svc-fortiauth         FortiAuth LDAP sync account (read-only)    |
|                                                                               |
|  DESIGN PRINCIPLES:                                                           |
|  * Role groups (Admin / Operator / Auditor) define the WALLIX profile         |
|  * Target groups define which systems a user can reach                        |
|  * A user belongs to one role group + one or more target groups               |
|  * Separation of duties: Auditors must not also be Admins                     |
|  * Default is deny: no group match = no access                                |
|                                                                               |
+===============================================================================+
```

### 6.4 Group-to-Profile Mapping

Present this table to the client during the design review and obtain
formal sign-off. It defines the complete authorization model.

| AD Group | WALLIX Profile | Permitted Actions | Restricted Actions |
|----------|---------------|-------------------|--------------------|
| PAM-Admins | Administrator | Full WALLIX administration, user management, configuration | None |
| PAM-Operators | Operator | Connect to authorized targets, manage target credentials | Change WALLIX configuration, manage users |
| PAM-Auditors | Auditor | View all sessions, generate reports, read-only access | Connect to targets, modify any configuration |
| PAM-Approvers | (custom) | Approve or deny JIT access requests | Connect to targets directly |
| _(no group)_ | _(none)_ | Login rejected | Everything |

### 6.5 Segregation of Duties

Ensure the following controls are explicitly configured and documented:

- An **Auditor** cannot be an **Operator** or **Administrator**
- The user who requests JIT access cannot also be the Approver
- The PAM Administrator account should not be used for day-to-day
  administrative tasks (create separate operator accounts for routine work)
- The break-glass account must have no AD group membership — it is a
  local WALLIX account only

---

## 7. FortiAuthenticator: Securing Every Connection

### 7.1 Role in the Architecture

FortiAuthenticator is the MFA enforcement point in this architecture. Every
privileged connection to WALLIX Bastion triggers a RADIUS authentication
request to FortiAuthenticator. No token approval means no session.

```
+===============================================================================+
|  FORTIAUTHENTICATOR IN THE AUTHENTICATION CHAIN                               |
+===============================================================================+
|                                                                               |
|  User enters credentials on WALLIX login page (Site N)                        |
|                 |                                                             |
|                 v                                                             |
|  PHASE 1 — LOCAL (intra-site, Cyber VLAN)                                     |
|  WALLIX (Site N, DMZ) binds to local AD DCs (Site N, Cyber) via LDAPS         |
|  Active Directory validates: username + password                              |
|  No WAN dependency — AD DCs are in the local Cyber VLAN                      |
|                 |                                                             |
|        [password OK?]                                                         |
|                 |                                                             |
|                 v                                                             |
|  PHASE 2 — LOCAL (intra-site, Cyber VLAN)                                     |
|  WALLIX (Site N, DMZ) sends RADIUS to FortiAuth (Site N, Cyber)               |
|  User enters 6-digit TOTP code from FortiToken Mobile app                     |
|  FortiAuth validates the TOTP code (time-based, no internet required)         |
|  No WAN dependency — FortiAuth HA pair is in the local Cyber VLAN             |
|                 |                                                             |
|        [token approved?]                                                      |
|                 |                                                             |
|                 v                                                             |
|  WALLIX receives RADIUS Access-Accept                                         |
|  Authorization evaluated against local AD group membership                    |
|  Session opened to authorized target — recording begins                       |
|                                                                               |
+===============================================================================+
```

### 7.2 RADIUS Policy Design

The RADIUS policy on FortiAuthenticator defines the rules for WALLIX
authentication requests. Three elements require precise configuration:

**RADIUS Clients**

Every node that sends RADIUS requests to a site's FortiAuthenticator must
be registered as a RADIUS client on that site's FortiAuth pair. A missing
entry results in silent MFA failure for sessions routed through that node.

Each site's FortiAuth pair has the following RADIUS clients:

| Component | Count per site | Managed By | Note |
|-----------|---------------|------------|------|
| WALLIX Bastion nodes | 2 (local HA pair) | In scope | Register on the local site FortiAuth |
| WALLIX Access Managers | 2 (connect to all sites) | External team | AM team must provide IPs; register on every site's FortiAuth |
| **Total RADIUS clients per site** | **4** | | |
| **Total across 5 sites** | **20** | | 10 Bastion + 10 AM entries |

**Important:** The Access Managers connect to Bastions at every site. When
an AM brokers a session through Bastion at Site N, that Bastion sends the
RADIUS request to Site N's local FortiAuth. Both AM nodes must therefore
be registered on every site's FortiAuth pair — not just one site.

Action required from the AM team before FortiAuth configuration begins:
- Provide the IP addresses of both AM nodes
- Confirm per-site AM-to-Bastion connectivity schedule
- Any future AM IP changes must be communicated — a stale entry will
  silently break MFA for all AM-brokered sessions at that site

**RADIUS Policy — Critical Setting**

```
+===============================================================================+
|  FORTIAUTH RADIUS POLICY                                                      |
|                                                                               |
|  Policy Name:      WALLIX-MFA-Policy                                          |
|  RADIUS Clients:   WALLIX-* entries only                                      |
|                                                                               |
|  First Factor:     NONE                                                       |
|                    ====                                                       |
|                                                                               |
|  WALLIX has already validated the password against Active Directory.          |
|  FortiAuthenticator is responsible for the second factor only.                |
|                                                                               |
|  Setting First Factor to LDAP causes:                                         |
|  * A second password prompt (user confusion and failed logins)                |
|  * Double Active Directory bind (unnecessary load and lockout risk)           |
|  * Authentication failures when the password format does not match            |
|    RADIUS expectations                                                        |
|                                                                               |
|  Second Factor:    FortiToken TOTP (6-digit code, no push)                    |
|                                                                               |
+===============================================================================+
```

**Shared Secret**

The RADIUS shared secret must be:
- Unique to the WALLIX integration (not shared with VPN or other policies)
- At least 32 characters, randomly generated
- Stored securely (password manager, not in a text file)
- Documented in the handover configuration reference (value redacted)

### 7.3 LDAP Synchronization

Each site's FortiAuthenticator pair synchronizes users from the local site
Active Directory Domain Controllers via LDAPS. Since AD is replicated across
all sites, the local DCs are always authoritative for the full user directory.

| Configuration Item | Value |
|-------------------|-------|
| LDAP server | Local site DC FQDN (not IP — allows DC failover within site) |
| Port | 636 (LDAPS) |
| Bind account | svc-fortiauth (read-only, in PAM OU) |
| Sync group | PAM-MFA-Users |
| Sync interval | 30 minutes (or on-demand trigger) |
| User attribute for token assignment | sAMAccountName |

**Note:** Because each site manages its own FortiAuth pair independently,
token provisioning and user sync are administered per site. Coordinate a
consistent configuration across all 5 sites to avoid divergence.

### 7.4 Token Lifecycle

```
+===============================================================================+
|  TOKEN LIFECYCLE                                                               |
+===============================================================================+
|                                                                               |
|  1. PROVISION                                                                 |
|     Administrator assigns a token to the user in FortiAuthenticator           |
|     User receives an activation email containing a QR code                    |
|     One license slot is consumed                                              |
|                                                                               |
|  2. ACTIVATE                                                                  |
|     User installs FortiToken Mobile and scans the QR code                     |
|     The token registers with FortiAuthenticator                               |
|     The token is now generating valid TOTP codes                              |
|                                                                               |
|  3. USE                                                                       |
|     Every login: open FortiToken Mobile and enter the 6-digit TOTP code       |
|     Code changes every 60 seconds (TOTP — RFC 6238)                           |
|     No internet required — code is generated locally on the device            |
|                                                                               |
|  4. RESYNC (when required)                                                    |
|     If the OTP is consistently rejected, the phone clock may have drifted     |
|     Administrator enters two consecutive OTP codes from the user              |
|     FortiAuthenticator recalculates the time offset                           |
|                                                                               |
|  5. REVOKE (offboarding or lost device)                                       |
|     Administrator revokes the token in FortiAuthenticator                     |
|     The license slot returns to the pool and is immediately reusable          |
|     The token on the device becomes invalid                                   |
|                                                                               |
|  IMPORTANT FOR THE CLIENT:                                                    |
|  * Licenses are not consumed permanently — revoking a token frees it          |
|  * There is no annual cost per token — one-time purchase                      |
|  * Lost phone: revoke old token, provision new one — under 5 minutes          |
|                                                                               |
+===============================================================================+
```

### 7.5 FortiAuthenticator HA Configuration

Each site has its own FortiAuthenticator Active-Passive HA pair, both nodes
in the local Cyber VLAN. The primary node handles all RADIUS requests. The
secondary maintains a synchronized copy of all configuration, users, and tokens.
HA sync stays entirely within the local Cyber VLAN — no WAN traffic involved.

| HA Parameter | Value |
|-------------|-------|
| HA mode | Active-Passive |
| Sync protocol | Proprietary (TCP port 8009) |
| Sync scope | Intra-site only — within the local Cyber VLAN |
| Sync interval | 60 seconds |
| WALLIX configuration | Site primary as priority 1, site secondary as priority 2 |
| Failover detection | WALLIX timeout + retry triggers automatic failover |
| Deployment count | 2 nodes × 5 sites = 10 FortiAuthenticator nodes total |

When the primary FortiAuth at a site becomes unreachable, WALLIX automatically
retries against the secondary at the same site. Failover is transparent to the
user. A failure of both nodes at a site affects only that site — other sites
continue to function independently with their own local FortiAuth pair.

---

## 8. The Two-Phase Authentication Model

### 8.1 Why Two Separate Phases

This is the most architecturally important concept to communicate clearly
to the client's technical team.

```
+===============================================================================+
|  TWO-PHASE AUTHENTICATION -- DESIGN RATIONALE                                 |
+===============================================================================+
|                                                                               |
|  PHASE 1 — LOCAL:  WALLIX binds directly to the local site AD via LDAPS      |
|  PHASE 2 — CENTRAL: WALLIX asks FortiAuthenticator for token validation       |
|                                                                               |
|  LOCAL AD BINDING IS INTENTIONAL                                              |
|  Each site has its own Domain Controllers. The WALLIX HA pair at each         |
|  site authenticates against those local DCs — not a remote or central DC.    |
|  This ensures:                                                                |
|  * Password validation survives a WAN outage (Phase 1 is always local)       |
|  * No inter-site latency for password checks                                  |
|  * AD replication keeps all DCs in sync — any local DC is authoritative      |
|                                                                               |
|  WHY NOT SEND EVERYTHING TO FORTIAUTHENTICATOR?                               |
|                                                                               |
|  Single-phase (incorrect) approach:                                           |
|    User enters password + OTP -> WALLIX -> FortiAuth -> AD -> FortiAuth       |
|    Problems:                                                                  |
|    * FortiAuth becomes a bottleneck — now in the critical path for Phase 1    |
|    * If FortiAuth or the WAN is down, no one can log in at all                |
|    * AD lockout policies may be triggered by FortiAuth bind retries           |
|    * Password crosses the WAN unnecessarily                                   |
|                                                                               |
|  Two-phase (correct) approach:                                                |
|    Phase 1: WALLIX (DMZ) -> LOCAL AD (Cyber, same site, LDAPS) — password    |
|    Phase 2: WALLIX (DMZ) -> LOCAL FortiAuth (Cyber, same site, RADIUS) — OTP |
|    Benefits:                                                                  |
|    * Each system does exactly one thing                                       |
|    * Both phases are intra-site — no WAN dependency for authentication        |
|    * AD lockout policies work correctly (WALLIX binds directly)               |
|    * A WAN outage does not affect authentication at any site                  |
|    * Failure isolation: Phase 1 and Phase 2 issues are independent            |
|    * Break-glass (local WALLIX account) bypasses Phase 2 entirely             |
|                                                                               |
+===============================================================================+
```

---

## 9. Architecture Decision Guide

### 9.1 Sizing by Client Profile

| Client Profile | Architecture | FortiAuth Model | HA |
|---------------|-------------|-----------------|-----|
| Small (1–50 users, 1 site) | Single FortiAuth VM | FAC-VM or 200F | Optional |
| Medium (50–200 users, 1–3 sites) | Single FortiAuth 300F with HA | 300F | Recommended |
| Large (200–1,000 users, 3–10 sites) | FortiAuth 400F with HA | 400F | Required |
| Enterprise (1,000+ users, 10+ sites) | FortiAuth 3000F or VM cluster | 3000F | Mandatory |

### 9.2 FortiAuthenticator Placement Options

**Confirmed deployment:** FortiAuthenticator HA pair (Active-Passive) at every
site, in the local Cyber VLAN alongside the AD Domain Controllers. RADIUS
traffic never crosses the MPLS WAN — it stays intra-site between DMZ and
Cyber VLANs. All 5 sites are identical in layout.

```
+===============================================================================+
|  CONFIRMED PLACEMENT — LOCAL HA PAIR PER SITE                                 |
+===============================================================================+
|                                                                               |
|  FortiAuth node 1 (primary)  --- HA Sync (TCP 8009) ---  FortiAuth node 2    |
|  Cyber VLAN, Site N                                       Cyber VLAN, Site N  |
|                                                                               |
|  Both nodes in the same Cyber VLAN at the same site.                          |
|  Active-Passive: primary handles all RADIUS; secondary is standby.            |
|  WALLIX Bastions (DMZ) configured with site primary as priority 1.            |
|                                                                               |
|  Deployed at: Site 1, Site 2, Site 3, Site 4, Site 5                          |
|  Total FortiAuth nodes: 10 (2 per site)                                       |
|                                                                               |
|  Advantages:                                                                  |
|  * No WAN dependency for Phase 2 — fully intra-site                           |
|  * A WAN outage does not affect authentication at any site                    |
|  * Site-level blast radius — a failure affects one site only                  |
|  * HA sync stays within the local Cyber VLAN (no inter-site sync traffic)     |
|                                                                               |
|  Management consideration:                                                    |
|  * Configuration must be applied consistently across all 5 site pairs         |
|  * Token pool is per-site — a user's token is enrolled on their home-site     |
|    FortiAuth; cross-site access requires the token to be recognized           |
|    by the FortiAuth at the site being accessed                                |
|  * Recommended: use AD group-driven auto-enrolment so tokens are              |
|    provisioned on every site's FortiAuth for roaming users                    |
|                                                                               |
+===============================================================================+
```

---

## 10. High Availability Patterns

### 10.1 HA Recommendation Criteria

| Question | Yes | No |
|----------|-----|----|
| Is this a production environment? | HA required | HA optional |
| Are there compliance uptime requirements? | HA mandatory | HA strongly recommended |
| Is there a DR site? | HA across sites | HA within single site |
| Does the client have > 100 PAM users? | HA strongly recommended | HA optional |

### 10.2 HA Architecture

```
+===============================================================================+
|  CONFIRMED PATTERN — LOCAL ACTIVE-PASSIVE HA AT EVERY SITE                   |
+===============================================================================+
|                                                                               |
|  FortiAuth Primary (Site N)   HA Sync TCP 8009   FortiAuth Secondary (Site N) |
|  Cyber VLAN            <---------------------------->  Cyber VLAN            |
|                                                                               |
|  Both nodes in the local Cyber VLAN. HA sync is intra-site only.              |
|  Active-Passive: primary handles all requests; secondary is hot standby.      |
|  WALLIX DMZ Bastions configured: site primary priority 1, secondary priority 2|
|                                                                               |
|  RTO: < 30 seconds (WALLIX failover on timeout)                               |
|  RPO: near-zero (HA sync every 60 seconds, intra-VLAN)                        |
|                                                                               |
|  Failure blast radius: one site only                                          |
|  Other sites continue authenticating via their own independent HA pair        |
|                                                                               |
+===============================================================================+
```

---

## 11. Common Client Scenarios

| Scenario | Complexity | Key Consideration | Approach |
|----------|-----------|-------------------|----------|
| Greenfield — no WALLIX, no MFA | Medium | Full deployment; no legacy constraints | Standard phased deployment |
| Add MFA to existing WALLIX | Low | WALLIX AD integration exists — add RADIUS only | Begin at FortiAuth configuration |
| Replace existing MFA provider | Medium | User re-enrollment; parallel operation period | Run old and new MFA in parallel; migrate in batches |
| Client already has FortiToken for VPN | Low | FortiAuth and tokens exist — add WALLIX as RADIUS client | 2–3 days of integration work |
| Multi-domain Active Directory | High | Multiple LDAP domains; user disambiguation required | Use Global Catalog or separate LDAP per forest |
| Azure AD hybrid | High | Cloud vs on-premises identity; sync timing | On-premises AD must be authoritative for PAM users |
| OT / air-gapped sites | High | No internet for push; limited WAN | TOTP already works offline; hardware tokens if no smartphone |

### 11.1 The Existing FortiToken Scenario

When the client already uses FortiToken for FortiGate VPN, the integration
scope reduces to the following four steps:

```
EXISTING FORTITOKEN DEPLOYMENT -- INTEGRATION STEPS
=====================================================

Step 1: Register WALLIX Bastion nodes as new RADIUS clients on
        the existing FortiAuthenticator
        (10 Bastion nodes + 2 Access Managers = 12 entries)

Step 2: Create a new RADIUS policy: "WALLIX-MFA-Policy"
        First Factor: None
        Second Factor: FortiToken
        Client scope: WALLIX-* entries only
        The existing VPN policy is untouched.

Step 3: Configure WALLIX to use the existing FortiAuth as RADIUS server

Step 4: Test — users use the same FortiToken app and same token
        They enter a TOTP code for WALLIX, the same app they use for VPN

WHAT DOES NOT CHANGE FOR USERS:
* No new application to install
* No new token to activate
* No re-enrollment process
* No new hardware

ESTIMATED TIMELINE: 2–3 days instead of 2–3 weeks
```

---

## 12. Compliance and Audit Readiness

### 12.1 Framework Mapping

| Framework | Relevant Control | Satisfied By |
|-----------|----------------|--------------|
| ISO 27001 A.8.5 | Secure authentication | MFA on all privileged access via WALLIX |
| SOC 2 CC6.1 | Logical access controls with MFA | WALLIX + FortiAuth + session recording |
| PCI-DSS 8.4.2 | MFA for non-console admin access | WALLIX as mandatory gateway + MFA |
| NIS2 Art. 21 | MFA for critical infrastructure | FortiAuth MFA on all WALLIX sessions |
| NIST 800-53 IA-2 | MFA for privileged accounts | Knowledge (AD) + Possession (FortiToken) |

### 12.2 Anti-Patterns to Avoid

| Anti-Pattern | Risk | Correct Approach |
|-------------|------|-----------------|
| FortiAuth First Factor set to LDAP | Double password prompt; authentication failures | First Factor must be **None** |
| Domain Admin account used for LDAP bind | Massively over-privileged service account | Dedicated read-only service accounts |
| LDAP (port 389) instead of LDAPS (port 636) | Credentials transmitted in cleartext | Always use LDAPS; deploy AD CS if required |
| Identical RADIUS shared secrets for VPN and PAM | Compromise of one policy compromises both | Separate shared secrets per RADIUS policy |
| FQDNs replaced by hardcoded IPs | Configuration breaks on DC replacement | Use FQDNs for LDAP; IPs only for RADIUS failover |
| RADIUS client entries incomplete | MFA fails silently on unregistered nodes | Count Bastion nodes + Access Managers; register all |
| NTP not verified before enabling MFA | 100% OTP failure rate | Verify NTP on all components before any MFA config |
| Big-bang MFA enforcement without pilot | Users locked out; executive escalation | Always pilot with a small group first |

---

## 13. Quick Reference Card

```
+===============================================================================+
|  QUICK REFERENCE                                                               |
+===============================================================================+
|                                                                               |
|  AUTHENTICATION FLOW                                                          |
|    Phase 1: WALLIX (DMZ) --> LOCAL AD DCs (Cyber, LDAPS 636)  password       |
|             Intra-site — no WAN dependency                                   |
|    Phase 2: WALLIX (DMZ) --> LOCAL FortiAuth (Cyber, RADIUS 1812)  TOTP      |
|             Intra-site — no WAN dependency                                   |
|                                                                               |
|  CRITICAL SETTING                                                             |
|    FortiAuth RADIUS Policy: First Factor = NONE                               |
|    WALLIX validates the password. FortiAuth validates the token only.         |
|                                                                               |
|  SERVICE ACCOUNTS                                                             |
|    svc_wallix        WALLIX LDAP bind to AD (read-only)                       |
|    svc-fortiauth     FortiAuth LDAP sync from AD (read-only)                  |
|    breakglass-admin  Local WALLIX account, no MFA, alerted on every use       |
|                                                                               |
|  NTP IS NOT OPTIONAL                                                          |
|    Clock drift > 30 seconds = 100% OTP failure rate                           |
|    Verify NTP before any MFA configuration                                    |
|                                                                               |
|  TOKEN LICENSES                                                               |
|    Perpetual — one-time purchase                                              |
|    Revoked tokens return to the pool and are reusable                         |
|    No annual per-token cost                                                   |
|                                                                               |
|  RADIUS CLIENTS (per site FortiAuth pair)                                     |
|    2 local Bastion nodes + 2 AM nodes = 4 entries per site                   |
|    5 sites = 20 total RADIUS client entries across the deployment             |
|    One missing entry = silent MFA failure on that node                        |
|                                                                               |
|  DEFAULT AUTHORIZATION                                                        |
|    No AD group match = access denied                                          |
|    Authentication success does not imply authorization                        |
|                                                                               |
+===============================================================================+
```

---

*Version 2.0 — 2026-04-11*
