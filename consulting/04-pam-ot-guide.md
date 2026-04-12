# PAM in Operational Technology Environments

## Privileged Access Management for OT, ICS, and SCADA Infrastructure

This guide supports client-facing engagements where the target environment
includes Operational Technology (OT), Industrial Control Systems (ICS), or
SCADA infrastructure. OT engagements have fundamentally different constraints
than IT deployments: the risk calculus is inverted, the protocols are older,
the availability requirements are extreme, and the stakeholders are engineers —
not IT administrators.

Read this guide before the first client meeting and use it throughout the
engagement lifecycle.

---

## Table of Contents

1. [Why OT Is Different from IT](#1-why-ot-is-different-from-it)
2. [OT Threat Landscape](#2-ot-threat-landscape)
3. [The Purdue Model and Zone Architecture](#3-the-purdue-model-and-zone-architecture)
4. [PAM Deployment Patterns in OT](#4-pam-deployment-patterns-in-ot)
5. [Protocol Coverage in OT](#5-protocol-coverage-in-ot)
6. [MFA in OT Environments](#6-mfa-in-ot-environments)
7. [Session Recording in OT](#7-session-recording-in-ot)
8. [Third-Party and Vendor Access](#8-third-party-and-vendor-access)
9. [Credential Management in OT](#9-credential-management-in-ot)
10. [Compliance Frameworks for OT](#10-compliance-frameworks-for-ot)
11. [Common OT Client Scenarios](#11-common-ot-client-scenarios)
12. [Stakeholder Conversations](#12-stakeholder-conversations)
13. [Pitfalls and Anti-Patterns](#13-pitfalls-and-anti-patterns)
14. [OT Readiness Assessment](#14-ot-readiness-assessment)
15. [Architecture Reference](#15-architecture-reference)
16. [Quick Reference: OT Tips](#16-quick-reference-ot-tips)

---

## 1. Why OT Is Different from IT

### 1.1 The Fundamental Inversion

In IT, the priority order is: **Confidentiality → Integrity → Availability**.
A database breach is bad. Downtime is expensive but recoverable.

In OT, the order is reversed: **Availability → Integrity → Confidentiality**.
Downtime in a power substation, water treatment plant, or manufacturing line
has physical consequences. People can be injured. Infrastructure can be
permanently damaged. This inversion shapes every decision in an OT engagement.

| Property | IT Posture | OT Posture |
|----------|-----------|-----------|
| **Availability** | High — hours of acceptable downtime | Extreme — zero tolerance in many cases |
| **Integrity** | High — data accuracy is critical | Highest — wrong commands cause physical damage |
| **Confidentiality** | Highest — data leakage is primary risk | Secondary — process data is less sensitive |
| **Patch cycles** | Weekly to monthly | Years — often never |
| **Testing before change** | Standard practice | Mandatory, often with physical simulation |
| **Authentication disruption** | Recoverable | May halt production |

### 1.2 Equipment Longevity

OT assets routinely operate for 15–30 years. A PLC installed in 2005 was
designed for a different threat landscape and was never intended to be touched
by a modern PAM solution. The consultant must assess, not assume.

Typical OT asset age distribution in a mid-size industrial client:

| Asset Age | Typical Proportion | PAM Integration Risk |
|-----------|-------------------|----------------------|
| < 5 years | 10–20% | Low |
| 5–15 years | 30–40% | Medium |
| 15–25 years | 25–35% | High |
| > 25 years | 10–20% | Very high — evaluate jump-host model |

### 1.3 Operational Constraints

- **Maintenance windows are rare.** A refinery may have one planned shutdown
  per year. Bastion deployment cannot require the target to go offline.
- **Physical access is controlled.** Many OT environments have no Internet
  access. Tokens and activation codes cannot be e-mailed to operators.
- **Legacy credentials are shared.** Generic accounts (`admin`, `operator`,
  `plc-config`) are the norm, not the exception. Individual accountability
  begins with PAM.
- **Latency is critical.** An HMI session with 200ms of additional proxy
  latency will be rejected by operators and operations managers alike. Test
  early.

---

## 2. OT Threat Landscape

### 2.1 Why OT Is a High-Value Target

OT environments were historically air-gapped, making them low-priority targets.
That isolation is gone. IT/OT convergence, remote maintenance contracts, and
vendor VPN tunnels have created attack paths that did not exist a decade ago.

Key incidents to reference in client conversations:

| Incident | Year | Vector | Impact |
|----------|------|--------|--------|
| Stuxnet | 2010 | USB / Windows zero-day | Centrifuge destruction |
| Ukraine Power Grid | 2015 | Spear-phishing → ICS | 230,000 customers without power |
| TRITON / TRISIS | 2017 | Engineering workstation | Safety system manipulation |
| Colonial Pipeline | 2021 | Legacy VPN credential | Fuel supply disruption, $4.4M ransom |
| Oldsmar Water Plant | 2021 | Remote access software | HMI manipulation (NaOH levels) |
| Industroyer2 | 2022 | APT lateral movement | Ukrainian power grid attack |

**References:**
- [ICS-CERT Advisories](https://www.cisa.gov/ics-cert-advisories)
- [ENISA Threat Landscape for OT/ICS (2023)](https://www.enisa.europa.eu/publications/enisa-threat-landscape-for-ot-and-ics-sectors)
- [DRAGOS Year in Review Report](https://www.dragos.com/resources/reports/)

The common denominator across most incidents: **privileged remote access
without adequate controls**. This is exactly what PAM addresses.

### 2.2 OT-Specific Attack Vectors

```
+===============================================================================+
|  OT ATTACK SURFACE: PRIVILEGED ACCESS PATHS                                  |
+===============================================================================+
|                                                                               |
|  EXTERNAL                                                                     |
|  --------                                                                     |
|  Vendor VPN  ------>  Engineering Workstation  ------>  PLC / RTU            |
|  Remote Desk ------>  Historian Server          ------>  DCS Controller       |
|  IT Network  ------>  SCADA HMI                 ------>  Safety System        |
|                                                                               |
|  INTERNAL                                                                     |
|  --------                                                                     |
|  IT Operator ------>  Jump Host (if any)        ------>  OT Asset             |
|  Contractor  ------>  Direct access (no jump)   ------>  OT Asset  [HIGH RISK]|
|  Shared acct ------>  No audit trail            ------>  OT Asset  [HIGH RISK]|
|                                                                               |
|  PAM CONTROL POINT                                                            |
|  -----------------                                                            |
|  All paths  ------>  WALLIX Bastion  ---------->  OT Asset  [RECOMMENDED]    |
|                                                                               |
+===============================================================================+
```

---

## 3. The Purdue Model and Zone Architecture

### 3.1 Purdue Reference Model (ISA-99 / IEC 62443)

The Purdue Model defines the logical segmentation of OT/IT environments into
numbered levels. PAM's insertion point depends on where the client currently
enforces zone boundaries.

```
+===============================================================================+
|  PURDUE MODEL — PAM INSERTION POINTS                                         |
+===============================================================================+
|                                                                               |
|  Level 5: Enterprise Network (IT)                                            |
|  +-----------------------------------------------------------------+         |
|  |  ERP, CRM, email, corporate Active Directory                    |         |
|  +-----------------------------------------------------------------+         |
|           |                                                                   |
|           | Firewall / DMZ boundary  <-- WALLIX Bastion lives here           |
|           v                                                                   |
|  Level 4: Site Business / Historian                                          |
|  +-----------------------------------------------------------------+         |
|  |  OSIsoft PI, Historian servers, site-level SCADA servers        |         |
|  +-----------------------------------------------------------------+         |
|           |                                                                   |
|           | ICS Firewall (Purdue L3/L4 boundary)                             |
|           v                                                                   |
|  Level 3: Operations / SCADA                                                 |
|  +-----------------------------------------------------------------+         |
|  |  SCADA servers, HMI, batch management, DCS console              |         |
|  +-----------------------------------------------------------------+         |
|           |                                                                   |
|  Level 2: Control Systems                                                    |
|  +-----------------------------------------------------------------+         |
|  |  DCS controllers, SCADA supervisory, HMI workstations           |         |
|  +-----------------------------------------------------------------+         |
|           |                                                                   |
|  Level 1: Field Devices / PLCs                                               |
|  +-----------------------------------------------------------------+         |
|  |  PLCs, RTUs, drives, sensors, actuators                         |         |
|  +-----------------------------------------------------------------+         |
|           |                                                                   |
|  Level 0: Physical Process                                                   |
|  +-----------------------------------------------------------------+         |
|  |  Valves, motors, pumps, physical equipment                      |         |
|  +-----------------------------------------------------------------+         |
|                                                                               |
+===============================================================================+
```

### 3.2 Where to Place the Bastion

The optimal placement depends on the client's current network segmentation:

| Client State | Recommended Placement | Notes |
|-------------|----------------------|-------|
| IT/OT fully converged (no firewall) | DMZ between IT and OT | Justify network segmentation first |
| Firewall at L3/L4 boundary | Bastion in DMZ at that boundary | Standard deployment |
| Firewall plus OT-internal jump host | Bastion replaces or wraps jump host | Verify protocol support |
| Fully air-gapped OT | Bastion deployed inside OT network | No external auth dependency |
| Multiple plant sites | Bastion per site + Access Manager | Use WALLIX multi-site model |

### 3.3 The DMZ Strategy

For most OT clients, the target architecture is a dedicated OT-DMZ where
the Bastion acts as the sole ingress point for privileged sessions.

```
+===============================================================================+
|  OT DMZ ARCHITECTURE                                                         |
+===============================================================================+
|                                                                               |
|  IT NETWORK (Level 4-5)                                                      |
|  +---------------------------+                                                |
|  |  Corporate users          |                                                |
|  |  Vendor jump-ins          |                                                |
|  +---------------------------+                                                |
|           |                                                                   |
|           v                                                                   |
|  OT DMZ (Firewall-enforced)                                                  |
|  +---------------------------+     +----------------------------+             |
|  |  WALLIX Bastion (HA)      |     |  FortiAuthenticator        |             |
|  |  - Session proxy          |     |  - TOTP / Push MFA         |             |
|  |  - Credential vault       |     |  - RADIUS endpoint         |             |
|  |  - Session recording      |     |  - FortiToken hardware     |             |
|  +---------------------------+     +----------------------------+             |
|           |                                                                   |
|           v (Only approved protocols pass)                                    |
|  OT NETWORK (Level 2-3)                                                      |
|  +---------------------------+                                                |
|  |  SCADA servers            |                                                |
|  |  HMI workstations         |                                                |
|  |  PLCs (via jump host)     |                                                |
|  |  Engineering workstations |                                                |
|  +---------------------------+                                                |
|                                                                               |
+===============================================================================+
```

**Tip:** Enforce firewall rules so that no IT workstation can reach OT Level 2–3
directly. All traffic must pass through the Bastion. This is the single most
impactful network control you can help the client implement.

---

## 4. PAM Deployment Patterns in OT

### 4.1 Pattern A: Bastion as the Single OT Entry Point

All access to OT assets flows through WALLIX Bastion. No direct connections
are permitted from the IT network. This is the target state for most clients.

**Advantages:**
- Full session recording for all privileged access
- Single credential vault for all OT accounts
- Audit trail covers every connection, regardless of source

**Challenges:**
- Requires firewall rule changes that OT teams may resist
- Must not introduce latency that breaks real-time HMI sessions
- Requires operator training and change management

### 4.2 Pattern B: Bastion Over an Existing Jump Host

Some OT environments already have a Windows jump server. WALLIX Bastion is
deployed in front of the jump server, adding authentication, recording, and
credential injection without replacing the existing infrastructure.

```
+===============================================================================+
|  PATTERN B: BASTION + EXISTING JUMP HOST                                     |
+===============================================================================+
|                                                                               |
|  User  -->  WALLIX Bastion (auth + record)  -->  Windows Jump Host           |
|                                             -->  (RDP RemoteApp or desktop)  |
|                                             -->  then: PLC / SCADA / HMI     |
|                                                                               |
|  WALLIX records: user identity, time, session duration                        |
|  Jump host provides: OT-specific application access                          |
|                                                                               |
+===============================================================================+
```

**When to use:**
- Client cannot change OT firewall rules in the short term
- OT team has strong attachment to the existing jump server tooling
- Some OT assets require local software installed on the jump host

**Note:** WALLIX RDS (RemoteApp) is the recommended component for this pattern.
See `install/08-rds-jump-host.md`.

### 4.3 Pattern C: Isolated Bastion Per Zone

In environments with strict segmentation between production zones (e.g.,
separate network segments per manufacturing cell or per utility area), a
dedicated Bastion instance may be required per zone.

**When to use:**
- IEC 62443 compliance requires zone-level isolation
- Different security zones have different authentication policies
- Air-gap requirements prevent a shared Bastion from reaching all zones

**Considerations:**
- Increases license count and operational overhead
- WALLIX Access Manager can aggregate all Bastion instances under a single
  entry point — evaluate this option before recommending per-zone Bastions

### 4.4 Pattern D: Offline / Air-Gapped Deployment

In nuclear, defense, or critical infrastructure environments with true air gaps,
the Bastion operates without any connection to external authentication
infrastructure. All authentication is local or relies on hardware tokens.

**Constraints:**
- No RADIUS/LDAP to external AD (or AD must exist inside the air gap)
- FortiAuthenticator must be deployed inside the air gap
- TOTP via hardware token (FortiToken 200) is the recommended MFA
- Software updates and license renewals require a secure offline procedure

---

## 5. Protocol Coverage in OT

### 5.1 Supported Protocols

WALLIX Bastion natively proxies the following protocols, which are relevant
in OT environments:

| Protocol | OT Use Case | Bastion Support | Notes |
|----------|------------|----------------|-------|
| **SSH** | Linux HMI, historian, engineering workstations | Native | Full recording, command filtering |
| **RDP** | Windows SCADA, HMI, jump hosts | Native | Full recording, keystroke + video |
| **VNC** | HMI consoles, UNIX workstations | Native | Video recording |
| **Telnet** | Legacy PLCs, switches, RTUs | Native | Full recording; migrate away when possible |
| **HTTP/HTTPS** | Web-based HMI, device management UIs | Native (Web Tunnel) | With WALLIX Web Access Manager |
| **WinRM** | Windows automation on SCADA servers | Native | PowerShell remoting |
| **X11** | Legacy UNIX engineering workstations | Via SSH X11 forwarding | Evaluate case by case |

### 5.2 Protocols Not Natively Proxied

Some OT-specific protocols cannot be proxied by WALLIX Bastion directly.
These require an alternative approach:

| Protocol | OT Use Case | Approach |
|----------|------------|---------|
| **Modbus TCP** | PLC communication | Not proxied — access the engineering workstation via Bastion (RDP/SSH), then use engineering software locally |
| **DNP3** | SCADA/RTU communication | Same as above — proxy the workstation, not the protocol |
| **IEC 61850 MMS** | Substation automation | Access via engineering workstation proxied through Bastion |
| **OPC DA / UA** | Process data exchange | OPC server accessed via Bastion; client application on proxied workstation |
| **Serial / RS-232** | Legacy PLCs and RTUs | Serial-to-IP converter (e.g., Digi, Moxa) + Telnet proxy through Bastion |
| **PROFINET / EtherNet/IP** | PLC fieldbus | No PAM proxy — control at network layer; protect the engineering workstation |

**Key principle:** For protocols Bastion cannot proxy, the control point is
the **engineering workstation or SCADA server** that speaks that protocol.
Bastion brokers access to the workstation; what the operator does inside
the workstation session is recorded via screen recording.

### 5.3 Serial-to-IP Bridging

For clients with legacy serial-connected PLCs that must be reachable through
Bastion, document the serial-to-IP architecture:

```
+===============================================================================+
|  SERIAL PLC ACCESS VIA BASTION (TELNET PROXY)                                |
+===============================================================================+
|                                                                               |
|  Operator  -->  WALLIX Bastion (Telnet proxy)  -->  Serial-to-IP Converter   |
|                 - Auth + recording                   (Digi PortServer,        |
|                                                       Moxa NPort, etc.)       |
|                                                   -->  RS-232 / RS-485        |
|                                                   -->  PLC / RTU / Drive      |
|                                                                               |
|  Result: full character-level recording of the serial CLI session            |
|                                                                               |
+===============================================================================+
```

---

## 6. MFA in OT Environments

### 6.1 OT-Specific MFA Challenges

Standard push notification MFA (FortiToken Mobile) works well in IT. OT
introduces constraints that change the recommendation:

| Challenge | Impact | Mitigation |
|-----------|--------|-----------|
| No smartphones in control rooms | Push MFA unusable | Hardware token (FortiToken 200) |
| Shared operator accounts | MFA per-account defeats auditing | Move to individual accounts first |
| Emergency access under stress | Complex MFA causes operator error | Bypass codes, hardware fallback |
| Air-gapped networks | FortiAuthenticator cannot reach cloud | On-prem FortiAuthenticator only |
| 24/7 shift operations | Token replacement needs out-of-hours procedure | Spare tokens, documented bypass |
| Legacy HMI software | May not support modern auth libraries | Credential injection; no UI-layer MFA |

### 6.2 Recommended MFA Model for OT

```
+===============================================================================+
|  OT MFA DECISION MATRIX                                                      |
+===============================================================================+
|                                                                               |
|  User type             | Recommended MFA        | Fallback                   |
|  ----------------------|------------------------|--------------------------- |
|  Control room operator | FortiToken 200 (HW)    | Bypass code (time-limited) |
|  Remote engineer       | FortiToken Mobile (SW) | FortiToken 200             |
|  External vendor       | FortiToken Mobile (SW) | Supervised access only     |
|  SCADA admin           | FortiToken 200 (HW)    | Break-glass account        |
|  Automated process     | No MFA (service acct)  | Dedicated vault account    |
|                                                                               |
+===============================================================================+
```

### 6.3 Hardware Token Logistics

FortiToken 200 is a hardware TOTP token. It requires no network connectivity
and no smartphone. For OT environments, it is the default recommendation.

**Provisioning steps to document with the client:**

1. FortiAuthenticator admin imports token seeds (CSV or XML from Fortinet)
2. Tokens are assigned to user accounts in FortiAuthenticator
3. Physical tokens are distributed to operators with a PIN activation procedure
4. Operators register their token at first login (initial TOTP sync)
5. Token replacement procedure is documented in the operations runbook

**Token lifecycle considerations:**
- FortiToken 200 battery life: approximately 3–5 years
- Token replacement requires FortiAuthenticator re-provisioning
- Store spare tokens in a secured safe with documented chain of custody
- Replace tokens in batches during scheduled maintenance windows

**Reference:** [FortiToken 200 Data Sheet](https://www.fortinet.com/content/dam/fortinet/assets/data-sheets/FortiToken_200.pdf)

### 6.4 When MFA Cannot Be Applied to a Target

Some OT assets cannot tolerate an additional authentication step because:
- The HMI software has a hardcoded authentication bypass
- The session must be initiated within a sub-second window (process interlocks)
- The account is shared across automation scripts and human operators

In these cases, apply MFA at the **Bastion level** (user authenticates to
Bastion with MFA), and use **credential injection** so the target never
requires MFA. The session is still fully recorded and attributed to a named
user.

```
[Operator] --MFA--> [WALLIX Bastion] --injected credential--> [PLC HMI]
     ^                     ^
     |                     |
  FortiToken TOTP    Session recorded,
                     user identity known
```

---

## 7. Session Recording in OT

### 7.1 Why Recording Matters More in OT

In OT, a recorded session is not just an audit artifact — it is forensic
evidence of what commands were sent to a physical process. A recording that
shows `valve_close(V-201)` executed at 02:14:37 is the difference between
proving an authorized maintenance action and proving sabotage.

Frame this to the client: session recording in OT is the equivalent of the
black box recorder in aviation.

### 7.2 Recording Capabilities by Protocol

| Protocol | What Is Recorded | Searchable? | Exportable? |
|----------|-----------------|-------------|-------------|
| SSH | Full character stream, timing | Yes (OCR + text) | Yes |
| RDP | Video + keystroke log | Yes (OCR) | Yes (video) |
| VNC | Video | Yes (OCR) | Yes (video) |
| Telnet | Full character stream | Yes | Yes |
| HTTP/HTTPS | Page navigation, form fields | Partial | Yes |

### 7.3 OCR and Command Detection

WALLIX Bastion can apply OCR to recorded screen sessions. This allows:
- Keyword alerts on sensitive OT commands (e.g., `EMERGENCY_STOP`, `FORCE_ON`)
- Post-incident search across recorded sessions
- Compliance reporting on who accessed which system

**Tip for OT clients:** Define a list of high-risk commands and configure
Bastion alerts for any session containing those strings. Integrate with SIEM
(Splunk, QRadar) for real-time alerting.

### 7.4 Storage Sizing for OT Sessions

OT sessions are often long-running (shift-length HMI sessions). Account for
storage accordingly.

Approximate recording sizes:

| Session Type | Duration | Approximate Size |
|-------------|----------|-----------------|
| SSH text session | 1 hour | 1–5 MB |
| RDP standard | 1 hour | 200–800 MB |
| RDP with video compression | 1 hour | 50–200 MB |
| VNC | 1 hour | 100–400 MB |
| Telnet | 1 hour | < 1 MB |

For a site with 20 concurrent operators running 8-hour RDP shifts, 5 days per
week, plan for approximately 1–5 TB of recording storage per year per site.
Confirm retention policy with the client (regulatory minimum is often 1–3 years
for OT compliance frameworks).

---

## 8. Third-Party and Vendor Access

### 8.1 The Vendor Access Problem

Third-party vendor access is the single highest-risk privileged access pattern
in OT. Most major OT security incidents involved:
- A vendor VPN account with persistent, always-on access
- No session recording
- Shared credentials known to multiple vendor employees
- No expiration on the access grant

WALLIX Bastion addresses all of these. This is one of the highest-value
propositions in an OT engagement.

### 8.2 Recommended Vendor Access Architecture

```
+===============================================================================+
|  VENDOR ACCESS MODEL WITH WALLIX BASTION                                     |
+===============================================================================+
|                                                                               |
|  Vendor  -->  WALLIX Access Manager  -->  JIT Approval  -->  WALLIX Bastion  |
|               (portal, no VPN)            (operations mgr       |            |
|                                            approves access)      v            |
|                                                             OT Target         |
|                                                             (time-limited     |
|                                                              session)         |
|  Controls enforced:                                                           |
|  - Individual vendor identity (no shared accounts)                           |
|  - MFA required (FortiToken Mobile for vendors)                              |
|  - Session recording: full video + keystroke                                 |
|  - Time-boxed access: auto-disconnect after defined window                   |
|  - Dual-control option: operator shadow and approve in real time             |
|  - No persistent VPN required: browser-based session via Access Manager      |
|                                                                               |
+===============================================================================+
```

### 8.3 JIT Access for Vendors

Just-In-Time access is the recommended model for all vendor sessions:

1. Vendor submits access request via WALLIX Access Manager portal
2. Operations manager (or on-call engineer) receives approval notification
3. Approval grants access to specific target(s) for a defined window (e.g., 4h)
4. Bastion opens session; full recording begins automatically
5. Session terminates at end of window or on manual revocation
6. Audit report is available immediately after session ends

**Reference:** `docs/pam/25-jit-access/` for full JIT configuration detail.

### 8.4 Session Shadowing and Dual Control

For high-risk vendor operations (firmware upgrades, safety system changes),
configure dual-control: a second authorized operator must be present in the
session before any commands can be issued.

This maps directly to IEC 62443 requirements for change management in OT.

---

## 9. Credential Management in OT

### 9.1 Shared Account Problem

OT environments almost universally rely on shared generic accounts. Common
examples encountered in the field:

- `administrator` / `admin` on Windows HMI workstations
- `root` on Linux SCADA servers
- `plcadmin` on PLC programming interfaces
- Single shared password known to all shift engineers

This provides zero individual accountability. When an incident occurs, it
is impossible to determine who executed a given command.

### 9.2 Migration Strategy

Do not attempt to eliminate shared accounts in Phase 1. The sequence is:

```
Phase 1: Brokerability
  All access via Bastion. Shared accounts still exist but are
  credential-injected. Individual identity is captured at Bastion level.
  No change to target systems required.

Phase 2: Individual Accounts
  Where supported, create individual accounts on target OT systems.
  Bastion maps user identity to individual accounts.
  Shared accounts retained only for legacy systems that cannot be changed.

Phase 3: Account Rotation
  Bastion rotates passwords on all managed accounts automatically.
  Shared account passwords are unknown to users — only Bastion holds them.
  Emergency break-glass procedure provides offline access if Bastion fails.
```

### 9.3 Password Rotation in OT

Automatic password rotation in OT requires caution:

| Risk | Mitigation |
|------|-----------|
| Rotation breaks a running automation script | Inventory all automated processes before enabling rotation |
| Rotation during a critical operation | Schedule rotation windows during known-quiet periods |
| Rotation fails on legacy system | Test rotation plugin on each target type in pre-production first |
| Break-glass password becomes unknown | Ensure break-glass accounts are excluded from rotation OR securely escrowed |

**Tip:** Enable rotation on a per-device basis, starting with test systems.
Do not enable bulk rotation across all OT targets simultaneously.

### 9.4 Service Account Governance

Automated OT processes (e.g., historian data collection, SCADA polling agents)
use service accounts. These must be:

- Catalogued in the Bastion credential vault
- Excluded from automatic rotation until the calling application is updated
- Monitored for anomalous interactive login (a service account doing RDP is a
  strong indicator of compromise)

**Reference:** `docs/pam/42-service-account-lifecycle/` for governance detail.

---

## 10. Compliance Frameworks for OT

### 10.1 IEC 62443

The primary international standard for OT/ICS security. Most industrial
clients in Europe and the Middle East reference this framework.

| IEC 62443 Requirement | WALLIX Control |
|----------------------|---------------|
| SR 1.1 — Human user identification and authentication | Individual user accounts, LDAP/AD integration |
| SR 1.2 — Software process and device identification | Service account management, device accounts |
| SR 1.3 — Account management | Centralized account lifecycle in Bastion |
| SR 1.5 — Authenticator management | FortiAuthenticator MFA, hardware tokens |
| SR 1.8 — PKI certificates | Certificate-based authentication for sessions |
| SR 1.9 — Strength of public key authentication | SSH key management, CA signing |
| SR 2.8 — Auditable events | Full session recording, structured audit log |
| SR 2.9 — Audit storage capacity | Configurable retention, SIEM integration |
| SR 2.12 — Non-repudiation | Session recordings with user identity binding |
| SR 3.3 — Security functionality verification | Pre-production lab validation procedures |
| SR 3.8 — Session integrity | Encrypted session channels (TLS 1.3, SSH) |
| SR 5.2 — Zone boundary protection | Bastion as sole ingress point |
| SR 6.2 — Continuous monitoring | Prometheus / Grafana + SIEM integration |

**Reference:** [IEC 62443 Standard Overview (ISA)](https://www.isa.org/standards-and-publications/isa-standards/isa-iec-62443-series-of-standards)

### 10.2 NERC CIP

Applicable to North American electric utilities. Relevant requirements:

| NERC CIP Standard | Requirement | WALLIX Control |
|------------------|-------------|---------------|
| CIP-004 | Personnel training and access management | Role-based access, JIT approval workflow |
| CIP-005 | Electronic security perimeter | Bastion as Electronic Access Point (EAP) |
| CIP-006 | Physical security of BES cyber systems | Out of scope for PAM |
| CIP-007 | Systems security management | Port/service management via Bastion firewall rules |
| CIP-010 | Configuration change management | Session recording of all change activity |
| CIP-011 | Information protection | Credential vault with encryption at rest |

**Reference:** [NERC CIP Standards](https://www.nerc.com/pa/Stand/Pages/CIPStandards.aspx)

### 10.3 NIS2 Directive (EU)

NIS2 applies to operators of essential services including energy, water,
transport, and digital infrastructure. Key PAM-relevant articles:

| NIS2 Article | Requirement | WALLIX Control |
|-------------|-------------|---------------|
| Art. 21(2)(a) | Risk analysis and information system security policies | PAM as privileged access risk control |
| Art. 21(2)(b) | Incident handling | Session recordings support forensics |
| Art. 21(2)(i) | Multi-factor authentication | FortiAuthenticator MFA at Bastion |
| Art. 21(2)(j) | Secure communications | TLS 1.3 for all Bastion sessions |

**Reference:** [NIS2 Directive Text](https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX%3A32022L2555)

### 10.4 ISA/IEC 62443 Security Level Mapping

The standard defines four Security Levels (SL). Map the client's target SL
to the appropriate Bastion configuration:

| Security Level | Definition | Bastion Configuration |
|---------------|-----------|----------------------|
| SL 1 | Protection against casual or unintentional violation | Basic auth, session recording |
| SL 2 | Protection against intentional violation using simple means | MFA, RBAC, full recording |
| SL 3 | Protection against sophisticated attack | MFA + JIT + dual control + SIEM |
| SL 4 | Protection against state-sponsored attack | SL 3 + air gap + hardware tokens + HSM |

Most industrial clients target SL 2 for operational systems and SL 3 for
safety systems.

---

## 11. Common OT Client Scenarios

### Scenario A: Energy / Utilities

**Profile:** Power generation or distribution company. Mix of Windows SCADA,
Linux historian, and legacy serial-connected IEDs. NERC CIP or NIS2 compliance
driver.

**Key concerns:**
- Strict change management — every command to a substation must be logged
- Vendor access for IED maintenance is high risk and poorly controlled today
- Operators resist any change to their workstation workflow

**Recommended approach:**
1. Start with vendor access control — highest risk, lowest operator friction
2. Deploy Bastion in front of Windows SCADA servers (RDP sessions)
3. Add FortiToken 200 hardware tokens for control room operators
4. Integrate session recordings with existing SIEM (Splunk, QRadar, or IBM)
5. Present NERC CIP or NIS2 compliance report as deliverable

### Scenario B: Manufacturing / Industry 4.0

**Profile:** Automotive, food & beverage, or pharma manufacturer. OT/IT
convergence initiative underway. Mix of Siemens S7 PLCs, Wonderware HMIs,
and Windows-based MES.

**Key concerns:**
- Production availability is paramount — no tolerance for downtime
- IT/OT convergence means OT is now reachable from corporate network
- GMP (Good Manufacturing Practice) compliance requires operator traceability

**Recommended approach:**
1. Deploy Bastion in OT DMZ without disrupting existing production network
2. Use Pattern B (Bastion over existing jump host) for initial rollout
3. Implement individual operator accounts on Windows HMIs (Phase 2)
4. Configure command filtering on SSH sessions to Linux-based SCADA
5. Produce per-operator activity reports for GMP audit trail

### Scenario C: Water / Wastewater

**Profile:** Municipal water utility. Small IT team, legacy SCADA, some
remote pump stations accessible via cellular modems.

**Key concerns:**
- Oldsmar-style attack risk: unauthenticated remote access is common
- Very limited IT budget and personnel
- Remote sites may only be reachable via 4G/LTE modem

**Recommended approach:**
1. Eliminate direct VNC/RDP access from the Internet immediately
2. Route all remote access through Bastion with MFA
3. FortiToken Mobile for the small team of engineers (easy deployment)
4. Prioritize session recording for any access to chemical dosing systems
5. Define break-glass procedure for emergency access at remote sites

### Scenario D: Oil & Gas

**Profile:** Upstream or midstream operator. Mix of DCS (Emerson DeltaV,
Honeywell Experion), pipeline SCADA, and safety instrumented systems (SIS).

**Key concerns:**
- SIS (Safety Instrumented Systems) must never be accessible except during
  declared maintenance windows
- Contractor workforce is large and transient
- Multi-site operation with dedicated OT networks per asset

**Recommended approach:**
1. Deploy per-site Bastion instances with WALLIX Access Manager aggregation
2. Implement strict JIT access with dual-control approval for SIS
3. Contractor access via Access Manager portal — no persistent VPN
4. Session recording retention: 3 years minimum (typical regulatory requirement)
5. SIEM integration for real-time alerts on SIS access attempts

---

## 12. Stakeholder Conversations

### 12.1 Speaking to the OT/SCADA Engineer

The OT engineer's primary concern is availability. They have likely seen PAM
projects fail because the proxy introduced latency or broke a protocol.
Establish credibility by addressing this first.

> "I understand your concern about adding a proxy in front of your SCADA
> systems. WALLIX Bastion operates as a transparent proxy — for SSH and Telnet,
> it adds sub-millisecond overhead. For RDP, the session travels directly
> between your client and the server; the Bastion sits on the session metadata,
> not the pixel stream. We will measure latency in your pre-production lab
> before touching production. If we cannot meet your latency requirements for
> any target, we will not proxy it and will document the exception."

### 12.2 Speaking to the CISO or Security Director

The CISO needs risk reduction evidence and compliance coverage. Lead with
incidents and regulation.

> "The three attack patterns we see most often in OT are: vendor VPN
> credentials left active after a contract ends; shared 'admin' accounts
> with no per-user audit trail; and direct remote access to HMIs with no
> monitoring. All three are addressed by this deployment. The session
> recording library also gives you evidence of what was done during any
> maintenance window — which is the first thing regulators and insurers ask
> for after an incident."

### 12.3 Speaking to the Plant / Operations Manager

The operations manager owns production continuity. Frame PAM as a tool
that protects their operation, not a security control imposed on them.

> "Right now, if something goes wrong after a maintenance window, there is
> no way to know exactly what was changed. With session recording, you have
> a complete video record of every action taken in every privileged session.
> If a vendor changes a setpoint and you need to know what it was before,
> you play back the recording. This is as much an operational tool as it is
> a security tool."

### 12.4 Speaking to the Legal / Compliance Team

Compliance teams need mapping to specific framework controls. Provide
written output.

> "We will produce a compliance mapping document at the end of the engagement
> that shows which IEC 62443 Security Requirements are addressed by the
> deployed controls. For NIS2 Article 21, we will show evidence of MFA
> deployment, audit logging, and session recording. This documentation is
> formatted to support both internal audit and external regulatory review."

---

## 13. Pitfalls and Anti-Patterns

### 13.1 Starting with Rotation Before Audit

**Anti-pattern:** Enabling automatic password rotation as the first PAM control.

**Problem:** If rotation breaks an automated process or a device loses
connectivity, you will have created an outage before establishing trust.

**Correct sequence:** Audit → Vault → Proxy → Rotate. Earn trust before
you touch credentials.

### 13.2 Applying IT Change Management to OT

**Anti-pattern:** Scheduling Bastion maintenance windows without consulting
the OT schedule.

**Problem:** OT has its own maintenance windows, often aligned with production
shifts or planned shutdowns. An unexpected restart of the Bastion at 03:00 may
coincide with a critical batch process.

**Correct approach:** All Bastion changes must be co-ordinated with the OT
operations team. Add an OT operations representative to the change advisory
board for this project.

### 13.3 Proxying Safety Systems Without Isolation

**Anti-pattern:** Adding SIS (Safety Instrumented System) devices to the Bastion
target list along with regular OT targets.

**Problem:** A Bastion misconfiguration could grant unauthorized access to
safety systems. SIS devices require an additional approval layer and should
be access-controlled separately.

**Correct approach:** SIS targets are configured with mandatory dual-control
approval and time-limited JIT access only. They are never available for
self-service access. Consider a dedicated Bastion instance for SIS.

### 13.4 Underestimating Token Distribution

**Anti-pattern:** Ordering hardware tokens 2 weeks before go-live for 200
control room operators across 5 sites.

**Problem:** Token distribution, activation, and user training for a large
shift workforce takes weeks. Tokens must be physically distributed, activated,
and tested per user. Operators who cannot authenticate on Day 1 cannot do
their jobs.

**Correct approach:** Plan token distribution as a project workstream with
dedicated effort. Allow 4–6 weeks for a large site. Consider a phased rollout
by shift team.

### 13.5 No Break-Glass Procedure for OT

**Anti-pattern:** Deploying Bastion without a tested emergency access procedure.

**Problem:** If Bastion fails during a process emergency, operators need
immediate access to OT assets. Without a documented and tested break-glass
procedure, they will bypass security controls permanently ("we can't rely on
this system").

**Correct approach:** Before go-live, define, document, and test the break-glass
procedure. The break-glass account credentials must be physically secured
(sealed envelope in a safe). The procedure must be rehearsed with the OT team.

**Reference:** `install/13-break-glass-procedures.md`

### 13.6 Ignoring Latency Testing

**Anti-pattern:** Deploying Bastion in production without measuring latency
for each target type.

**Problem:** Some HMI applications are latency-sensitive. An added 50ms
round-trip may cause timeouts or visual artifacts that operators will not
tolerate. This will result in pressure to remove the Bastion.

**Correct approach:** Measure baseline latency for each target type in
pre-production. Test with the actual HMI application. Document that tested
overhead is within acceptable bounds before requesting production change approval.

---

## 14. OT Readiness Assessment

Use this section as a supplement to `01-discovery-assessment.md` for OT-specific
discovery.

### 14.1 OT Asset Inventory Questions

```
OT Asset Inventory
------------------
Total OT devices in scope:          ____
  - PLCs:                           ____
  - HMI workstations:               ____
  - SCADA servers:                  ____
  - Engineering workstations:       ____
  - Historian servers:              ____
  - Network devices (OT switches):  ____
  - RTUs / field devices:           ____
  - Safety systems (SIS):           ____

Protocols in use:
  [ ] SSH        [ ] RDP        [ ] VNC       [ ] Telnet
  [ ] Modbus TCP [ ] DNP3       [ ] IEC 61850 [ ] OPC DA/UA
  [ ] PROFINET   [ ] EtherNet/IP              [ ] Other: ____

Asset age profile:
  < 5 years:    ____    5-15 years: ____
  15-25 years:  ____    > 25 years: ____

Existing jump hosts:
  [ ] Yes — count: ____    OS: ____
  [ ] No
```

### 14.2 OT Network Architecture Questions

```
OT Network Segmentation
-----------------------
Does an IT/OT firewall exist?        [ ] Yes  [ ] No  [ ] Partial
Is there a documented OT DMZ?        [ ] Yes  [ ] No
Are OT VLANs separate from IT?       [ ] Yes  [ ] No  [ ] Mixed
Do vendor VPNs terminate in OT?      [ ] Yes  [ ] No
  If yes, how many active VPN accounts?  ____
Are there any direct Internet paths to OT? [ ] Yes  [ ] No

Network zones present:
  [ ] Separate zone per manufacturing cell
  [ ] Separate zone per safety system
  [ ] Single flat OT network
  [ ] Other: ____
```

### 14.3 OT Authentication State

```
OT Authentication Current State
--------------------------------
Are shared accounts used on OT systems?     [ ] Yes  [ ] No
  If yes, estimated % of targets:           ____
Are any OT accounts in Active Directory?    [ ] Yes  [ ] No
Is MFA used anywhere in OT today?           [ ] Yes  [ ] No
  If yes, what technology:                  ____
Are any OT system passwords known to change? [ ] Yes  [ ] No  [ ] Unknown
  Last known rotation:                      ____
Are service accounts documented?            [ ] Yes  [ ] No  [ ] Partial
```

### 14.4 OT Operational Constraints

```
OT Operational Constraints
--------------------------
Planned shutdown windows:           ____  per year
  Next scheduled shutdown:          ____
Acceptable latency increase:        ____  ms (per OT team)
Shift patterns:                     ____  (e.g., 3x8h, 2x12h)
On-call team for PAM support:       [ ] Yes  [ ] No
SIEM / SOC in scope?                [ ] Yes  [ ] No
  If yes, platform:                 ____
Existing change management process? [ ] Yes  [ ] No
  CAB includes OT rep?              [ ] Yes  [ ] No
```

### 14.5 OT Compliance Drivers

```
OT Compliance Framework
------------------------
Primary framework:
  [ ] IEC 62443         [ ] NERC CIP      [ ] NIS2
  [ ] ISO 27001         [ ] NIST SP 800-82 [ ] Other: ____

Target Security Level (IEC 62443):
  [ ] SL 1  [ ] SL 2  [ ] SL 3  [ ] SL 4  [ ] Not assessed

Regulatory body:
  ____________________________

Next audit date:
  ____________________________

Audit evidence required:
  [ ] Session logs       [ ] Access reports     [ ] Incident records
  [ ] Change records     [ ] User access review  [ ] Other: ____
```

---

## 15. Architecture Reference

### 15.1 Multi-Site OT Deployment with Access Manager

```
+===============================================================================+
|  OT PAM MULTI-SITE ARCHITECTURE                                              |
+===============================================================================+
|                                                                               |
|  CORPORATE NETWORK (IT)                                                      |
|  +------------------------------------------------------------------+        |
|  |  WALLIX Access Manager (HA)                                      |        |
|  |  - Single portal for all OT sites                                |        |
|  |  - JIT approval workflow                                         |        |
|  |  - Vendor access management                                      |        |
|  +------------------------------------------------------------------+        |
|           |  MPLS / WAN                                                       |
|    +-------+-------+-------+-------+                                         |
|    v       v       v       v       v                                         |
|  Site 1  Site 2  Site 3  Site 4  Site 5                                      |
|                                                                               |
|  Per-Site OT DMZ:                                                            |
|  +---------------------------+     +---------------------------+              |
|  |  WALLIX Bastion (HA)      |     |  FortiAuthenticator       |              |
|  |  - Protocol proxy         |     |  - RADIUS server          |              |
|  |  - Credential vault       |     |  - FortiToken 200 support |              |
|  |  - Session recording      |     |  - Local admin portal     |              |
|  +---------------------------+     +---------------------------+              |
|           |                                                                   |
|    OT Production Network:                                                    |
|  +------------------------------------------------------------------+        |
|  |  SCADA  |  HMI  |  Historian  |  EWS  |  PLCs (via jump host)  |        |
|  +------------------------------------------------------------------+        |
|                                                                               |
+===============================================================================+
```

### 15.2 Vendor Access Flow

```
+===============================================================================+
|  VENDOR SESSION LIFECYCLE                                                    |
+===============================================================================+
|                                                                               |
|  1. REQUEST                                                                  |
|     Vendor submits request via Access Manager portal                         |
|     - Target system, purpose, estimated duration                             |
|                                                                               |
|  2. APPROVAL                                                                 |
|     Operations manager receives notification                                 |
|     - Approves or rejects with reason                                        |
|     - Sets time window (e.g., 09:00-13:00 on 2026-04-14)                    |
|                                                                               |
|  3. SESSION                                                                  |
|     Vendor authenticates to Bastion:                                         |
|     - LDAP credential (vendor AD account or local account)                  |
|     - FortiToken Mobile TOTP                                                 |
|     Session opens to approved target only, within approved window            |
|                                                                               |
|  4. MONITORING                                                               |
|     Operations manager can shadow session live                               |
|     Alert fired if session exceeds approved window                           |
|     Auto-disconnect at window end                                            |
|                                                                               |
|  5. AUDIT                                                                    |
|     Full session recording available immediately after disconnect            |
|     Structured log event sent to SIEM                                        |
|     PDF access report generated for compliance file                          |
|                                                                               |
+===============================================================================+
```

---

## 16. Quick Reference: OT Tips

Key principles to apply throughout every OT engagement:

| # | Tip | Why |
|---|-----|-----|
| 1 | Start with vendor access, not operator access | Highest risk, lowest operator friction |
| 2 | Proxy first, rotate later | Build trust before touching credentials |
| 3 | Test latency in pre-production for every target type | Latency complaints kill PAM rollouts in OT |
| 4 | Use FortiToken 200 hardware tokens for control rooms | Smartphones not permitted in most OT sites |
| 5 | Never enable bulk rotation without service account inventory | One broken automation = one production incident |
| 6 | Define and rehearse break-glass before go-live | OT engineers will bypass security if they feel unsafe |
| 7 | Get OT engineer sign-off on change windows | OT schedules are not IT schedules |
| 8 | Record every session — even short ones | Forensic value is highest when you least expect it |
| 9 | Treat SIS as a separate scope with extra controls | Safety system access requires additional approval layer |
| 10 | Map all controls to IEC 62443 or NERC CIP from day one | Compliance evidence is easier to build than retrofit |
| 11 | Include OT rep in change advisory board | Prevents production conflicts caused by IT-only planning |
| 12 | Size recording storage for shift-length RDP sessions | Standard IT sizing assumptions are wrong for OT |
| 13 | Certify that each protocol proxy adds < required latency | Documented evidence for OT team acceptance |
| 14 | Document all serial-to-IP bridges in scope | Serial devices are invisible to IT-side asset scans |
| 15 | Always align with the Purdue model in architecture discussions | Common language across OT, IT, and compliance teams |

---

## External References

| Resource | URL |
|----------|-----|
| IEC 62443 Standard (ISA overview) | https://www.isa.org/standards-and-publications/isa-standards/isa-iec-62443-series-of-standards |
| NERC CIP Standards | https://www.nerc.com/pa/Stand/Pages/CIPStandards.aspx |
| NIS2 Directive (EU) | https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX%3A32022L2555 |
| NIST SP 800-82 Rev 3 (OT Security) | https://csrc.nist.gov/publications/detail/sp/800-82/rev-3/final |
| CISA ICS-CERT Advisories | https://www.cisa.gov/ics-cert-advisories |
| ENISA OT/ICS Threat Landscape | https://www.enisa.europa.eu/publications/enisa-threat-landscape-for-ot-and-ics-sectors |
| DRAGOS Year in Review | https://www.dragos.com/resources/reports/ |
| FortiToken 200 Data Sheet | https://www.fortinet.com/content/dam/fortinet/assets/data-sheets/FortiToken_200.pdf |
| WALLIX Bastion Admin Guide | https://pam.wallix.one/documentation/admin-doc/bastion_en_administration_guide.pdf |
| ISA Global Cybersecurity Alliance | https://isagca.org |

---

*Related documents in this toolkit:*
- *[Discovery & Assessment](01-discovery-assessment.md) — OT sections supplement the general questionnaire*
- *[MFA Strategy Guide](02-mfa-strategy-guide.md) — FortiAuthenticator and FortiToken architecture*
- *[Engagement Playbook](03-engagement-playbook.md) — OT engagement sequencing and milestones*
