# Post-Deployment Health Check

## PAM Maturity Assessment and Annual Review Guide

This guide is used for two scenarios:

1. **Annual health check** — a returning engagement with an existing WALLIX
   client to assess whether the deployment is performing well, coverage has
   kept pace with the environment, and the compliance posture is current.

2. **Inherited deployment assessment** — arriving at a client where WALLIX
   was deployed by another team or a previous consultant, and needing to
   understand the actual state before making recommendations.

Both scenarios require the same assessment approach. The difference is the
relationship: the annual review is collaborative; the inherited assessment
starts with no assumptions.

---

## Table of Contents

1. [When to Use This Guide](#1-when-to-use-this-guide)
2. [PAM Maturity Model](#2-pam-maturity-model)
3. [Health Check Methodology](#3-health-check-methodology)
4. [Coverage Assessment](#4-coverage-assessment)
5. [Authentication and MFA Health](#5-authentication-and-mfa-health)
6. [Credential Vault Health](#6-credential-vault-health)
7. [Session Recording Health](#7-session-recording-health)
8. [Access Control and RBAC Health](#8-access-control-and-rbac-health)
9. [Infrastructure and HA Health](#9-infrastructure-and-ha-health)
10. [Compliance Posture Review](#10-compliance-posture-review)
11. [Findings Report Structure](#11-findings-report-structure)
12. [Remediation Prioritisation](#12-remediation-prioritisation)
13. [Health Check Scorecard](#13-health-check-scorecard)

---

## 1. When to Use This Guide

### 1.1 Annual Health Check Triggers

Recommend an annual health check to every client at engagement closure.
Frame it as part of the engagement contract, not as an optional add-on.

A health check is particularly urgent when any of the following apply:

| Trigger | Reason |
|---------|--------|
| 12+ months since deployment or last review | Configuration drift accumulates silently |
| Staff turnover in the IT/security team | Institutional knowledge loss; undocumented changes |
| Significant infrastructure change (new site / cloud / M&A) | Coverage gaps introduced without PAM update |
| Compliance audit approaching | Evidence package needs to be current |
| Security incident (related or unrelated to PAM) | Validate controls held; identify lessons |
| WALLIX Bastion version more than 2 releases behind | Security patches and features not applied |
| Adoption complaints or bypass behaviour reported | Operational issues masking coverage gaps |

### 1.2 Inherited Deployment Assessment

When the client's Bastion was deployed by another party, begin with no
assumptions about the configuration quality. Treat the assessment as a
discovery phase. Common issues found in inherited deployments:

- Default credentials not changed on Bastion admin account
- Session recording disabled on selected targets "temporarily"
- Break-glass account password unknown (no documentation)
- Rotation configured but failing silently on multiple accounts
- Vendor accounts never cleaned up after contract end
- HA configured but failover never tested
- Compliance reporting configured but not reviewed by anyone

---

## 2. PAM Maturity Model

Use this model to position the client on the maturity spectrum and define a
target state for the next 12 months.

```
+===============================================================================+
|  PAM MATURITY MODEL                                                          |
+===============================================================================+
|                                                                               |
|  Level 1 — Initial                                                           |
|  Bastion deployed. Some targets onboarded. AD integration working.           |
|  No MFA, no rotation, no formal RBAC. Break-glass undocumented.             |
|                                                                               |
|  Level 2 — Managed                                                           |
|  MFA enforced for all users. Session recording on all proxied sessions.      |
|  Credential vault populated. Break-glass documented and tested.              |
|  RBAC defined but not reviewed. No rotation. No JIT.                        |
|                                                                               |
|  Level 3 — Defined                                                           |
|  Full coverage: all target systems onboarded. Rotation on all accounts.      |
|  JIT access for vendors. RBAC reviewed quarterly. SIEM integration live.    |
|  Compliance evidence package maintained. HA tested annually.                |
|                                                                               |
|  Level 4 — Quantified                                                        |
|  Adoption metrics tracked. Access reviews automated. Recording OCR and      |
|  alerting configured. Anomaly detection on session behaviour. Threat        |
|  hunting uses session recordings. Compliance evidence auto-generated.       |
|                                                                               |
|  Level 5 — Optimising                                                        |
|  JIT access is the default for all privileged access. Zero standing          |
|  access. Service accounts automated via API. PAM integrated into            |
|  ITSM change workflow. Continuous compliance monitoring.                    |
|                                                                               |
+===============================================================================+
```

Most clients after initial deployment are at Level 1–2. The health check
identifies what is needed to reach the client's target level (typically
Level 3 for NIS2 / IEC 62443 compliance).

---

## 3. Health Check Methodology

### 3.1 Preparation (Before On-Site)

Request these artefacts from the client before the assessment session:

| Artefact | Why Needed |
|---------|-----------|
| Bastion version number | Assess patch currency |
| Number of onboarded devices (current vs. original scope) | Coverage gap measurement |
| Number of active user accounts | Compare to user inventory |
| Last HA failover test date | HA health indicator |
| Last session recording reviewed by security team | Recording utility indicator |
| Last access review date | RBAC health indicator |
| Open service desk tickets related to Bastion | Operational issue indicator |
| Last rotation failure report (if rotation is configured) | Vault health indicator |

### 3.2 On-Site Assessment Sessions

Structure the health check as two half-day sessions:

**Session 1 — Technical assessment (3 hours)**
- Live review of Bastion configuration with IT admin
- Coverage audit: compare current device list to asset inventory
- Credential vault audit: rotation status, failure log
- Session recording spot-check: random sample of recent sessions
- HA configuration and last-tested date
- Bastion version and pending updates

**Session 2 — Compliance and access review (3 hours)**
- User account review: active users vs. current staff list
- Vendor account review: active vendor accounts vs. current contracts
- RBAC review: roles and permissions vs. current job functions
- Compliance evidence review: is the evidence package current?
- SIEM integration: are events flowing and being actioned?
- Break-glass procedure: is it documented, is it known, is it in the safe?

---

## 4. Coverage Assessment

### 4.1 Coverage Definition

Coverage is the percentage of in-scope privileged access paths that are
brokered through the Bastion. A deployment with 100 target systems where
only 60 are onboarded has 60% coverage — and 40% uncontrolled privileged
access.

Coverage gaps are the most common finding in health checks. They arise from:
- New servers provisioned without informing the PAM team
- Scope creep during deployment that was never completed
- Legacy systems excluded with intent to onboard "later"
- Vendors given direct VPN access because the JIT workflow was not set up

### 4.2 Coverage Audit Steps

1. Export the current device list from Bastion (Admin → Devices → Export)
2. Compare against the current asset inventory (`02-asset-inventory.csv`)
3. Identify devices in the asset inventory not in the Bastion device list
4. For each gap device, determine: why was it excluded, is it still in use,
   what is the privileged access path today?
5. Score: covered / not covered / excluded (with documented justification)

### 4.3 Coverage Health Thresholds

| Coverage % | Assessment | Recommended Action |
|-----------|-----------|-------------------|
| > 95% | Healthy | Maintain; review exclusions annually |
| 80–95% | Acceptable | Onboard gap devices in next quarter |
| 60–80% | Degraded | Treat as partial deployment; remediation plan required |
| < 60% | Critical | Significant uncontrolled privileged access; urgent remediation |

---

## 5. Authentication and MFA Health

### 5.1 MFA Coverage Check

MFA enforcement can degrade silently if accounts are added without the MFA
policy being applied. Check:

```bash
# On FortiAuthenticator: export user list and MFA enrollment status
# Cross-reference with Bastion user list

# Users in Bastion with MFA-type = NONE (should be zero after go-live)
# Check in Bastion Admin > Users > filter by MFA policy
```

| Finding | Severity | Action |
|---------|---------|--------|
| Users with MFA bypassed | Critical | Enforce MFA; document any justified exceptions |
| Users enrolled but token expired / lost and not replaced | High | Re-issue token within 5 business days |
| New users added without token enrollment | High | Enforce onboarding checklist |
| Hardware token battery warnings | Medium | Replace tokens before expiry |

### 5.2 AD Integration Health

Signs of AD integration drift:

- Disabled AD users still appearing as active in Bastion
- AD groups have changed but Bastion group mappings have not been updated
- Kerberos tickets generating errors in the Bastion log
- LDAP sync failures (check: Admin → Domains → Last sync status)

### 5.3 FortiAuthenticator Health

Check:
- FortiAuthenticator version (current supported release)
- HA sync status (if FA is deployed in HA)
- License utilisation (tokens used vs. licensed)
- Authentication failure rate in the FA log (high failure rate = user friction
  or token issue)

---

## 6. Credential Vault Health

### 6.1 Rotation Status Audit

Export the rotation status for all managed accounts and review:

| Status | Count | Target | Action if Below Target |
|--------|-------|--------|----------------------|
| Rotation enabled and last successful | — | 100% of managed accounts | Enable rotation on gaps |
| Rotation enabled, last attempt failed | — | 0 | Investigate and resolve failures |
| Rotation enabled, never run | — | 0 | Trigger manual rotation; investigate why auto-rotation did not run |
| Rotation disabled (with justification) | — | Documented | Verify justification is still valid |
| Rotation disabled (no justification) | — | 0 | Enable rotation or document exception |

Common rotation failure causes found in health checks:
- Target system firewall rule changed, blocking Bastion rotation plugin
- Account locked due to too many failed rotation attempts
- Rotation plugin version incompatible with target OS update
- Service account used by a process that was not updated after rotation

### 6.2 Vault Population Check

- Are all accounts in the asset inventory represented in the vault?
- Are any accounts in the vault for systems that no longer exist?
- Are vault accounts named consistently with the naming convention?
- Are orphaned vault accounts (no associated device) present?

### 6.3 Break-Glass Account Health

| Check | Expected State | Finding |
|-------|---------------|---------|
| Break-glass account exists in Bastion | Yes | |
| Break-glass credentials in sealed physical envelope | Yes | |
| Envelope location is known to > 1 named person | Yes | |
| Break-glass procedure document is current | Yes | |
| Break-glass has not been used since last review | Verify log | |
| If used: was the use documented and the password re-sealed? | Yes | |

---

## 7. Session Recording Health

### 7.1 Recording Coverage Check

Session recording should be enabled for 100% of onboarded target connections.
Silent recording gaps — where sessions open but are not recorded — are a
critical finding.

Check: Admin → Sessions → Filter by "Not recorded" → Should return zero results
for completed sessions.

Common reasons for recording gaps:
- Storage volume reached capacity (recordings stop silently)
- Recording engine service stopped and not restarted
- Specific target configured with recording disabled
- Protocol type not supported for recording (Modbus, DNP3, etc. — these are
  known and documented; the control is at the workstation level)

### 7.2 Storage Health Check

| Metric | Check | Warning Threshold |
|--------|-------|-----------------|
| Available recording storage | df -h on Bastion | < 20% free |
| Oldest recording date | Admin → Sessions → oldest entry | Gap from expected retention period |
| Recording retention policy | Admin → Configuration | Less than regulatory requirement |
| SIEM archival working | SIEM query for recent sessions | No sessions received in > 24h |

### 7.3 Recording Utility Check

Session recordings are only valuable if they are occasionally reviewed.
Confirm with the security team:

- Have any recordings been reviewed in the past 3 months?
- Has the OCR / keyword search feature been used?
- Have any alerts been triggered by session content?
- Has a recording ever been used as forensic evidence?

If the answer to all four is "no," the recording feature is shelfware. This
is a training and process gap, not a technical gap.

---

## 8. Access Control and RBAC Health

### 8.1 User Account Review

Perform a full user account review at every health check. This is a
compliance requirement under ISO 27001 A.8.2, NIS2 Article 21, and most
enterprise security policies.

Steps:
1. Export user list from Bastion (Admin → Users → Export)
2. Cross-reference with current HR active employee list
3. Cross-reference with current contractor / vendor list
4. Flag:
   - Accounts for departed employees (critical finding — disable immediately)
   - Accounts for contractors whose engagement has ended
   - Dormant accounts (no login in > 90 days)
   - Accounts with roles inconsistent with current job function

### 8.2 Vendor Account Review

Vendor accounts degrade fastest. Check:

| Check | Finding |
|-------|---------|
| Vendor accounts mapped to active contracts | |
| Vendor accounts for expired contracts (disable) | |
| Vendor accounts unused for > 30 days | |
| Vendor accounts with standing access (should be JIT only) | |
| Vendor accounts without MFA | |

### 8.3 RBAC Role Review

Review each WALLIX role (authorisation profile) against current job functions:

- Does the role grant access to systems that the role members no longer use?
- Are there users with multiple roles creating unintended cumulative permissions?
- Are any roles giving access to OT targets without JIT or dual-control?
- Are admin-level permissions granted to users who should have operator access only?

---

## 9. Infrastructure and HA Health

### 9.1 Version Currency

| Component | Current Deployed Version | Latest Available Version | Patch Gap | Action |
|-----------|------------------------|--------------------------|----------|--------|
| WALLIX Bastion | | | | |
| WALLIX Access Manager | | | | |
| FortiAuthenticator | | | | |
| HAProxy | | | | |
| Underlying OS (Debian) | | | | |
| MariaDB | | | | |

A Bastion version more than 2 minor releases behind current is a finding.
Check release notes for security advisories in skipped versions.

**Reference:** [WALLIX Release Notes](https://pam.wallix.one/documentation/release-notes)

### 9.2 HA Cluster Health

```bash
# Check Pacemaker/Corosync cluster status
crm status
crm_mon -1

# Expected output: 2 nodes online, all resources running on active node
# Failure indicators: node offline, resource failed, split-brain warning

# Check MariaDB replication lag
mysql -e "SHOW SLAVE STATUS\G" | grep -E "Seconds_Behind|Running|Error"

# Check HAProxy status
systemctl status haproxy
echo "show stat" | socat stdio /var/run/haproxy/admin.sock | cut -d',' -f1,2,18,19
```

### 9.3 Certificate Health

| Certificate | Expiry Date | Days Remaining | Action |
|------------|-------------|---------------|--------|
| Bastion web TLS certificate | | | Renew if < 60 days |
| FortiAuthenticator TLS certificate | | | Renew if < 60 days |
| Access Manager TLS certificate | | | Renew if < 60 days |
| Internal CA (if applicable) | | | Review if < 180 days |

Certificate expiry is the most common cause of sudden Bastion outages in
the second year of deployment. Add certificate renewal to the annual
operations calendar.

### 9.4 Backup Verification

| Check | Last Verified | Finding |
|-------|--------------|---------|
| Bastion configuration backup exists and is current | | |
| Backup restore was tested (not just backup creation) | | |
| MariaDB backup is current and tested | | |
| Session recording backup / archival is working | | |
| Backup storage is off-host (not on Bastion itself) | | |

---

## 10. Compliance Posture Review

### 10.1 Compliance Evidence Currency

Review the compliance evidence package from the original deployment (or last
health check) against the current configuration:

| Evidence Item | Original State | Current State | Gap |
|--------------|---------------|---------------|-----|
| MFA enforcement documentation | | | |
| Session recording retention confirmation | | | |
| User access review (last date) | | | |
| HA test results (last date) | | | |
| Rotation success report (last 90 days) | | | |
| Vendor access review (last date) | | | |
| Bastion version and patch status | | | |
| Firewall rule documentation | | | |

### 10.2 Regulatory Change Check

Compliance frameworks evolve. At each health check, verify:

- Has NIS2 national implementation in the client's country introduced new
  requirements since the last review?
- Has IEC 62443 or NERC CIP published new guidance relevant to the client?
- Has the client's cyber insurance renewal introduced new PAM-specific
  conditions?
- Has the client's internal security policy been updated?

If any of the above has changed, update the compliance gap analysis
(`05-compliance-gap.csv`) accordingly.

---

## 11. Findings Report Structure

Produce this report at the end of every health check. Deliver it within
5 business days of the assessment.

### 11.1 Report Sections

```
WALLIX BASTION HEALTH CHECK REPORT
Client: ____________________________
Assessment Date: ____________________
Consultant: ________________________
Report Version: 1.0

EXECUTIVE SUMMARY
  [3–5 bullet points: overall maturity level, critical findings count,
   recommendations summary, compliance posture]

1. DEPLOYMENT OVERVIEW
   Current maturity level: Level [N]
   Target maturity level:  Level [N]
   Coverage: [N]% of in-scope targets onboarded
   Active users: [N] / [N] provisioned
   MFA enforced: [N]% of users

2. FINDINGS SUMMARY

   Critical (must resolve within 30 days):
     F-001: [Finding title] — [One-line description]
     F-002: ...

   High (resolve within 90 days):
     F-003: ...

   Medium (address in next health check cycle):
     F-004: ...

   Low / Observations:
     F-005: ...

3. DETAILED FINDINGS
   [One section per finding with: description, evidence, risk, recommendation]

4. COMPLIANCE POSTURE
   [Table: framework / control / status / change since last review]

5. REMEDIATION ROADMAP
   [Table: finding / recommended action / owner / target date / effort estimate]

6. MATURITY ROADMAP
   [What changes would move the client from Level N to Level N+1]

APPENDICES
  A. Evidence screenshots
  B. Configuration export extracts
  C. Rotation status report
  D. User account review results
```

---

## 12. Remediation Prioritisation

Use this matrix to prioritise findings from the health check report.

| Finding Category | P1 (30 days) | P2 (90 days) | P3 (next cycle) |
|----------------|-------------|-------------|----------------|
| Departed employee accounts active | Always P1 | — | — |
| Session recording disabled on any target | Always P1 | — | — |
| Break-glass credentials unknown or undocumented | Always P1 | — | — |
| MFA bypassed for any in-scope user | Always P1 | — | — |
| HA never tested | — | Always P2 | — |
| Rotation failures > 5% of managed accounts | — | P2 | — |
| Coverage < 80% of in-scope targets | P1 if < 60% | P2 if 60–80% | — |
| Bastion version > 2 releases behind | — | P2 | — |
| Certificate expiry < 60 days | P1 | — | — |
| Vendor accounts without contracts | P1 | — | — |
| RBAC roles not reviewed in > 12 months | — | — | P3 |
| Recording storage < 20% free | P1 if < 10% | P2 if 10–20% | — |
| Compliance evidence package > 12 months old | — | P2 if audit < 90 days | P3 |

---

## 13. Health Check Scorecard

Score each section 0–100 using the weights below. Total score indicates
overall deployment health.

| Section | Weight | Score (0–100) | Weighted Score |
|---------|--------|--------------|---------------|
| Coverage (% of targets onboarded) | 20% | | |
| MFA enforcement (% of users with MFA) | 20% | | |
| Credential vault (rotation success rate) | 15% | | |
| Session recording coverage | 15% | | |
| Access control (user review current) | 10% | | |
| Infrastructure and HA health | 10% | | |
| Compliance posture | 10% | | |
| **Total weighted score** | **100%** | | |

**Score interpretation:**

| Score | Health Status | Recommended Action |
|-------|--------------|-------------------|
| 90–100 | Excellent | Annual review sufficient |
| 75–89 | Good | Address medium findings; semi-annual review |
| 60–74 | Acceptable | Remediation plan required; quarterly check-in |
| 40–59 | Degraded | Urgent remediation; return visit within 60 days |
| < 40 | Critical | Treat as a new deployment; full remediation engagement |

---

*Related documents in this toolkit:*
- *[Engagement Playbook](03-engagement-playbook.md) — include health check at handover*
- *[Training & Change Management](07-training-change-mgmt.md) — adoption metrics to track*
- *[Scope & Proposal Template](06-scope-proposal-template.md) — scope a health check engagement*
- *[Templates: Test Results](../templates/08-test-results.csv) — re-run key tests during health check*
