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
|  * 80% of breaches involve compromised credentials (Verizon DBIR 2024)       |
|  * Privileged accounts are the primary target in all major attack classes     |
|  * MFA blocks over 99% of automated credential-based attacks                 |
|  * Session recording provides forensic evidence when incidents occur          |
|                                                                               |
|  COMPLIANCE                                                                   |
|  * ISO 27001 A.8.5 — secure authentication for privileged access             |
|  * SOC 2 CC6.1 — MFA as a required logical access control                    |
|  * PCI-DSS 8.4.2 — MFA mandatory for all non-console admin access            |
|  * NIS2 Article 21 — MFA required for critical infrastructure access         |
|  * NIST 800-53 IA-2 — MFA for privileged and non-privileged accounts         |
|                                                                               |
|  OPERATIONAL BENEFIT                                                          |
|  * Centralized access gateway — one place to manage who accesses what        |
|  * Full session recording — complete audit trail for every privileged action  |
|  * Automated credential rotation — no shared passwords for target systems     |
|  * Single offboarding action — disable in AD, access removed everywhere      |
|                                                                               |
+===============================================================================+
```

### 2.2 Why FortiAuthenticator and WALLIX Bastion

The combination of WALLIX Bastion and FortiAuthenticator creates a layered
architecture where each component has a single, well-defined responsibility.

| Component | Responsibility | Protocol | VLAN | Placement |
|-----------|---------------|----------|------|-----------|
| **Active Directory** | Identity and password validation | LDAPS (636) | Cyber | Local to each site — each Bastion HA pair authenticates against the local site DCs |
| **FortiAuthenticator** | Second factor validation (token) | RADIUS (1812) | Cyber | Centralized HA across two datacenters, reachable over MPLS |
| **WALLIX Bastion** | Authorization, access control, session recording | SSH, RDP, HTTPS | DMZ | Local HA pair per site (2 nodes per site) |

**Key architectural point:** Phase 1 (password) is always resolved locally — WALLIX at each
site binds to the local Domain Controllers via LDAPS. This means AD authentication is
resilient to WAN failures. Phase 2 (token) travels to the central FortiAuthenticator over
the WAN. If the WAN is unavailable, only the break-glass account can authenticate.

### 2.3 Per-Site VLAN Architecture

```
+===============================================================================+
|  PER-SITE VLAN DESIGN (replicated across all 5 sites)                        |
+===============================================================================+
|                                                                               |
|  CYBER VLAN                                                                   |
|  +----------------------------------+                                         |
|  |  AD Domain Controllers (local)  |  <-- LDAPS 636 from DMZ Bastions        |
|  +----------------------------------+                                         |
|  |  FortiAuthenticator (central,   |  <-- RADIUS 1812 from DMZ Bastions      |
|  |  reached via MPLS)              |      LDAPS 636 to local AD DCs          |
|  +----------------------------------+                                         |
|                                                                               |
|           ^                ^                                                  |
|           | LDAPS 636      | RADIUS 1812 (via MPLS)                          |
|           |                |                                                  |
|  DMZ VLAN                                                                     |
|  +----------------------------------+                                         |
|  |  WALLIX Bastion node 1  (HA)    |                                         |
|  |  WALLIX Bastion node 2  (HA)    |                                         |
|  +----------------------------------+                                         |
|           |                                                                   |
|           | SSH 22 / RDP 3389 / HTTPS 443 (to targets)                       |
|           v                                                                   |
|  SERVER / TARGET VLANs                                                        |
|                                                                               |
|  Users connect to Bastions (DMZ) via SSH 22, RDP 3389, HTTPS 443             |
|  Access Managers (external team) connect to Bastions from their VLAN         |
|                                                                               |
+===============================================================================+
```

### 2.4 Required Inter-VLAN Firewall Rules

These rules must be in place before any integration testing can begin.
Submit the full list to the network team on Day 1.

| Source VLAN | Destination VLAN | Protocol | Port | Purpose |
|-------------|-----------------|----------|------|---------|
| DMZ (Bastion) | Cyber (local AD) | TCP | 636 | WALLIX LDAPS bind — password validation (Phase 1) |
| DMZ (Bastion) | Cyber (FortiAuth, via MPLS) | UDP | 1812 | WALLIX RADIUS — token validation (Phase 2) |
| Cyber (FortiAuth) | Cyber (local AD, all sites) | TCP | 636 | FortiAuth LDAP sync — user and group import |
| Users VLAN | DMZ (Bastion) | TCP | 443 | WALLIX Web UI access |
| Users VLAN | DMZ (Bastion) | TCP | 22 | WALLIX SSH proxy access |
| Users VLAN | DMZ (Bastion) | TCP | 3389 | WALLIX RDP proxy access |
| DMZ (Bastion) | Server VLANs | TCP | 22 | Bastion SSH to Linux targets |
| DMZ (Bastion) | Server VLANs | TCP | 3389 | Bastion RDP to Windows targets |
| AM VLAN (external) | DMZ (Bastion) | TCP | 443 | Access Manager to Bastion connectivity |

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
(knowledge) validated directly by WALLIX, and the FortiToken OTP or push
approval (possession) validated by FortiAuthenticator via RADIUS.

### 3.2 FortiToken Mobile

FortiToken Mobile is a time-based OTP (TOTP) application for iOS and Android.
It supports two authentication modes:

| Mode | How It Works | Internet Required | Best For |
|------|-------------|-------------------|----------|
| **Push notification** | User receives a notification and taps Approve | Yes (phone must have internet) | Daily use — fastest experience |
| **OTP (manual)** | User reads a 6-digit code that changes every 60 s | No — works fully offline | Backup mode, air-gapped environments |

### 3.3 FortiToken Hardware (200 / 300)

A physical device that generates a 6-digit OTP every 60 seconds. No
smartphone required. Appropriate for:

- OT and plant floor environments where smartphones are not permitted
- Users in security-sensitive areas who may not carry personal devices
- Environments where BYOD is not acceptable

| Criterion | FortiToken Mobile | FortiToken Hardware |
|-----------|-------------------|---------------------|
| Cost per user | Lower (software license) | Higher (physical device) |
| User experience | Push — tap to approve | Manual 6-digit entry |
| Deployment speed | Fast — email activation link | Slower — physical distribution |
| Lost / stolen recovery | Revoke and re-provision in minutes | Requires physical replacement |
| Battery | N/A | ~5 years, then device replacement |
| Offline use | OTP works offline; push requires internet | Always offline capable |

### 3.4 How RADIUS Integrates with WALLIX

RADIUS (Remote Authentication Dial-In User Service) is the industry-standard
protocol for forwarding authentication requests to a centralized server.

In plain terms:

> "When a user enters their OTP or approves a push on their phone, WALLIX
> sends a message to FortiAuthenticator that says: 'This user presented
> this code — is it valid?' FortiAuthenticator verifies the token and
> replies with Accept or Reject. WALLIX grants or denies access based on
> that reply. The two systems communicate over an encrypted channel using
> a shared secret that is unique to this integration."

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
|  PHASE 1 — LOCAL                                                              |
|  WALLIX (Site N) binds to LOCAL site AD Domain Controllers via LDAPS          |
|  Active Directory validates: username + password                              |
|  No WAN dependency — AD DCs are local to each site                           |
|                 |                                                             |
|        [password OK?]                                                         |
|                 |                                                             |
|                 v                                                             |
|  PHASE 2 — CENTRALIZED                                                        |
|  WALLIX (Site N) sends RADIUS Access-Request to FortiAuthenticator            |
|  FortiAuthenticator (central HA) sends push to user's FortiToken app          |
|  WAN must be available for this step                                          |
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

Every WALLIX Bastion node and WALLIX Access Manager that will send RADIUS
requests must be registered as a RADIUS client on FortiAuthenticator.
A missing client entry results in silent MFA failure for that node.

| Component | Count | Managed By | Coordination Required |
|-----------|-------|------------|----------------------|
| WALLIX Bastion nodes | 10 (2 per site) | In scope | None |
| WALLIX Access Managers | 2 | External team — not in scope | AM team must provide node IPs; registration on FortiAuth is in scope |
| **Total RADIUS client entries** | **12** | | |

**Important:** The Access Managers are managed by a separate team and are
not in scope for this engagement. However, because each AM connects to
every site's Bastion HA pair and initiates RADIUS authentication requests
to FortiAuthenticator, both AM nodes must be registered as RADIUS clients.

Action required from the AM team:
- Provide the IP addresses of both AM nodes before FortiAuth configuration
- Confirm when the AM-to-Bastion connectivity is established per site
- Any changes to AM node IPs must be communicated — a missing or stale
  RADIUS client entry will silently break MFA for AM-brokered sessions

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
|  Second Factor:    FortiToken (push + OTP)                                    |
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

FortiAuthenticator synchronizes users from Active Directory via LDAPS.
This enables FortiAuth to know which users are enrolled for MFA and to
automatically assign tokens when users are added to the PAM-MFA-Users group.

| Configuration Item | Value |
|-------------------|-------|
| LDAP server | DC FQDN (not IP — allows DC failover) |
| Port | 636 (LDAPS) |
| Bind account | svc-fortiauth (read-only, in PAM OU) |
| Sync group | PAM-MFA-Users |
| Sync interval | 30 minutes (or on-demand trigger) |
| User attribute for token assignment | sAMAccountName |

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
|     Every login: approve push notification or enter 6-digit OTP               |
|     OTP changes every 60 seconds (TOTP — RFC 6238)                            |
|     Push requires internet on the user's phone; OTP does not                  |
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

FortiAuthenticator HA operates in Active-Passive mode. The primary node
handles all RADIUS requests. The secondary node maintains a synchronized
copy of all configuration, users, and tokens.

| HA Parameter | Recommended Value |
|-------------|-------------------|
| HA mode | Active-Passive |
| Sync protocol | Proprietary (TCP port 8009) |
| Sync interval | 60 seconds |
| WALLIX configuration | Primary as priority 1, secondary as priority 2 |
| Failover detection | WALLIX timeout + retry triggers automatic failover |

When the primary FortiAuth becomes unreachable, WALLIX automatically retries
against the secondary. The failover is transparent to the user — the push
notification or OTP entry proceeds normally.

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
|    Phase 1: WALLIX -> LOCAL AD (LDAPS) — password, no WAN dependency         |
|    Phase 2: WALLIX -> FortiAuth (RADIUS, over WAN) — OTP only                 |
|    Benefits:                                                                  |
|    * Each system does exactly one thing                                       |
|    * AD lockout policies work correctly (WALLIX binds directly)               |
|    * Phase 1 resilient to WAN and FortiAuth failures                          |
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

**Note on AD placement:** Active Directory Domain Controllers are always local
to each site. The WALLIX HA pair at each site binds to its local DCs for
password validation — this is fixed regardless of which FortiAuth placement
option is chosen. The decision below applies only to FortiAuthenticator
(Phase 2 — token validation).

**Network:** All five sites are interconnected via a private MPLS network.
FortiAuthenticator centralized placement (Option A) is the recommended
approach given the reliable, low-latency MPLS backbone.

```
+===============================================================================+
|  PLACEMENT OPTION A — CENTRALIZED (RECOMMENDED FOR MPLS CLIENTS)             |
+===============================================================================+
|                                                                               |
|  FortiAuth deployed in the shared infrastructure VLAN alongside AD DCs.       |
|  All WALLIX nodes at all sites reach it via MPLS / private WAN.               |
|                                                                               |
|  Advantages: single management point, simple HA, centralized token pool       |
|  Limitation: depends on WAN availability for remote site authentication       |
|  Mitigation: break-glass accounts at each site; HA at primary DC              |
|                                                                               |
|  Best fit: reliable MPLS, centralized IT, < 5 sites                           |
|                                                                               |
+===============================================================================+

+===============================================================================+
|  PLACEMENT OPTION B — PRIMARY + DR SITE                                       |
+===============================================================================+
|                                                                               |
|  Primary FortiAuth at main datacenter. Secondary FortiAuth at DR site.        |
|  HA sync operates over the WAN link (port 8009 must be permitted).            |
|                                                                               |
|  Advantages: lowest latency for primary site; HA across datacenters           |
|  Limitation: remote sites still depend on WAN for RADIUS                      |
|  Mitigation: break-glass accounts per site                                    |
|                                                                               |
|  Best fit: hub-and-spoke topology, datacenter-centric organizations           |
|                                                                               |
+===============================================================================+

+===============================================================================+
|  PLACEMENT OPTION C — DISTRIBUTED (ONE PER REGION)                            |
+===============================================================================+
|                                                                               |
|  FortiAuth appliances deployed at each major region.                          |
|  All sync from Active Directory; each handles local RADIUS.                   |
|                                                                               |
|  Advantages: survives WAN outages; lowest latency at every site               |
|  Limitation: more appliances, more licensing, complex sync design             |
|  Mitigation: detailed HA planning per region                                  |
|                                                                               |
|  Best fit: unreliable WAN, strict availability SLAs, geographically           |
|  distributed organizations                                                    |
|                                                                               |
+===============================================================================+
```

### 9.3 Decision Flowchart

```
Is WAN reliable (< 50 ms latency, >= 99.9% uptime)?
|
+-- YES --> How many sites?
|           |
|           +-- 1-5 sites  --> OPTION A: Centralized FortiAuth
|           |                  ** This deployment: 5 sites on MPLS
|           |                     --> OPTION A confirmed **
|           +-- 5+ sites   --> OPTION B: Primary + DR site FortiAuth
|
+-- NO  --> Are sites grouped by region?
            |
            +-- YES --> OPTION C: One FortiAuth per region
            |
            +-- NO  --> OPTION A + aggressive break-glass planning
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

### 10.2 HA Architecture Diagrams

```
+===============================================================================+
|  PATTERN 1 — SINGLE SITE HA (most common deployment)                         |
+===============================================================================+
|                                                                               |
|  FortiAuth Primary          HA Sync (TCP 8009)        FortiAuth Secondary     |
|  10.20.0.60        <---------------------------->     10.20.0.61             |
|                                                                               |
|  Both in the same VLAN and datacenter.                                        |
|  Active-Passive: primary handles all requests; secondary is standby.          |
|  WALLIX configured with primary as priority 1, secondary as priority 2.       |
|                                                                               |
|  RTO: < 30 seconds (WALLIX failover on timeout)                               |
|  RPO: near-zero (HA sync interval: 60 seconds)                                |
|                                                                               |
+===============================================================================+

+===============================================================================+
|  PATTERN 2 — CROSS-SITE HA (for DR)                                           |
+===============================================================================+
|                                                                               |
|  DC-A: FortiAuth Primary           WAN            DC-B: FortiAuth Secondary   |
|  10.20.0.60           <-------------------------> 10.20.0.61                 |
|                                                                               |
|  Primary at main datacenter; secondary at DR site.                            |
|  HA sync over WAN — port 8009 must be permitted between sites.                |
|                                                                               |
|  RTO: < 30 seconds                                                            |
|  RPO: 1–5 minutes (WAN-dependent sync lag)                                    |
|                                                                               |
+===============================================================================+

+===============================================================================+
|  PATTERN 3 — NO HA (budget constraint)                                        |
+===============================================================================+
|                                                                               |
|  Single FortiAuth only. No secondary appliance.                               |
|                                                                               |
|  Required compensating controls:                                              |
|  * Automated daily backup to SFTP                                             |
|  * Break-glass account tested quarterly                                       |
|  * Documented restore procedure targeting < 1 hour RTO                        |
|  * Formal client acceptance of MFA unavailability during outage               |
|                                                                               |
|  RTO: 30–60 minutes (restore from backup)                                     |
|  RPO: up to 24 hours (daily backup)                                           |
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
| OT / air-gapped sites | High | No internet for push; limited WAN | Hardware tokens; local FortiAuth per site |

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
        They approve one push for WALLIX, the same way they do for VPN

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
|    Phase 1: WALLIX (site N) --> LOCAL AD DCs (LDAPS 636)  password           |
|             No WAN dependency — AD is local to every site                    |
|    Phase 2: WALLIX (site N) --> Central FortiAuth (RADIUS 1812)  token       |
|             Requires WAN connectivity to central FortiAuth                   |
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
|  RADIUS CLIENTS                                                               |
|    Bastion nodes + Access Managers = total client entries required            |
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
