# OT Incident Response

Responding to security incidents in industrial environments where safety comes first.

## OT IR is Different

```
┌─────────────────────────────────────────────────────────────────────┐
│                    IT vs OT Incident Response                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   IT Incident Response:                                              │
│   ─────────────────────                                              │
│   • Isolate affected systems immediately                             │
│   • Preserve evidence                                                │
│   • Investigate thoroughly                                           │
│   • Remediate and recover                                            │
│   • Downtime is acceptable for security                              │
│                                                                      │
│   OT Incident Response Must Consider:                                │
│   ────────────────────────────────────                               │
│   • Can we isolate without causing safety issues?                    │
│   • Will investigation affect production?                            │
│   • Are manual operations possible?                                  │
│   • What are regulatory notification requirements?                   │
│   • How do we maintain evidence while keeping production?            │
│                                                                      │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │                                                             │   │
│   │   RULE #1: SAFETY ALWAYS COMES FIRST                        │   │
│   │                                                             │   │
│   │   If there is ANY risk to human safety:                     │   │
│   │   • Shut down safely                                        │   │
│   │   • Evacuate if necessary                                   │   │
│   │   • Then worry about the cyber incident                     │   │
│   │                                                             │   │
│   └─────────────────────────────────────────────────────────────┘   │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## OT Incident Response Framework

### Phase Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                    OT IR Phases                                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   ┌──────────────────────────────────────────────────────────────┐  │
│   │ 1. PREPARATION                                               │  │
│   │    • Plans, procedures, training                             │  │
│   │    • Tools and capabilities                                  │  │
│   │    • Relationships with operations                           │  │
│   └──────────────────────────────────────────────────────────────┘  │
│                         │                                            │
│                         ▼                                            │
│   ┌──────────────────────────────────────────────────────────────┐  │
│   │ 2. DETECTION & ANALYSIS                                      │  │
│   │    • Identify incident                                       │  │
│   │    • Assess safety implications                              │  │
│   │    • Determine scope and severity                            │  │
│   └──────────────────────────────────────────────────────────────┘  │
│                         │                                            │
│                         ▼                                            │
│   ┌──────────────────────────────────────────────────────────────┐  │
│   │ 3. CONTAINMENT                                               │  │
│   │    • Short-term: Stop spread while maintaining safety        │  │
│   │    • Long-term: Sustainable containment during investigation │  │
│   └──────────────────────────────────────────────────────────────┘  │
│                         │                                            │
│                         ▼                                            │
│   ┌──────────────────────────────────────────────────────────────┐  │
│   │ 4. ERADICATION & RECOVERY                                    │  │
│   │    • Remove threat                                           │  │
│   │    • Restore systems                                         │  │
│   │    • Validate integrity                                      │  │
│   └──────────────────────────────────────────────────────────────┘  │
│                         │                                            │
│                         ▼                                            │
│   ┌──────────────────────────────────────────────────────────────┐  │
│   │ 5. POST-INCIDENT                                             │  │
│   │    • Lessons learned                                         │  │
│   │    • Improvements                                            │  │
│   │    • Documentation                                           │  │
│   └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Phase 1: Preparation

### OT-Specific IR Preparation

```
┌─────────────────────────────────────────────────────────────────────┐
│                    OT IR Preparation Checklist                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Documentation:                                                     │
│   ─────────────                                                      │
│   [ ] Network diagrams (IT and OT)                                   │
│   [ ] Asset inventory with criticality ratings                       │
│   [ ] PLC/DCS program backups                                        │
│   [ ] Baseline configurations                                        │
│   [ ] Normal traffic patterns                                        │
│   [ ] Vendor contact information                                     │
│   [ ] Manual operation procedures                                    │
│                                                                      │
│   Tools and Capabilities:                                            │
│   ───────────────────────                                            │
│   [ ] Network packet capture capability                              │
│   [ ] Forensic workstation (isolated)                                │
│   [ ] OT-safe forensic tools                                         │
│   [ ] Spare equipment for swap-out                                   │
│   [ ] Write blockers for disk imaging                                │
│   [ ] Industrial protocol analyzers                                  │
│                                                                      │
│   Relationships:                                                     │
│   ──────────────                                                     │
│   [ ] OT operations team contacts                                    │
│   [ ] Plant safety personnel contacts                                │
│   [ ] Vendor support contacts                                        │
│   [ ] Law enforcement contacts                                       │
│   [ ] ISAC membership                                                │
│   [ ] External IR support contracts                                  │
│                                                                      │
│   Training:                                                          │
│   ─────────                                                          │
│   [ ] Tabletop exercises (at least annual)                           │
│   [ ] Joint IT/OT exercises                                          │
│   [ ] Operations team awareness                                      │
│   [ ] IR team OT familiarization                                     │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### IR Team Structure

```
┌─────────────────────────────────────────────────────────────────────┐
│                    OT Incident Response Team                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│                    ┌─────────────────────┐                           │
│                    │   Incident          │                           │
│                    │   Commander         │                           │
│                    │   (Executive)       │                           │
│                    └──────────┬──────────┘                           │
│                               │                                      │
│           ┌───────────────────┼───────────────────┐                  │
│           │                   │                   │                  │
│           ▼                   ▼                   ▼                  │
│   ┌───────────────┐  ┌───────────────┐  ┌───────────────┐           │
│   │ Safety Lead   │  │  Technical    │  │ Communications│           │
│   │               │  │  Lead         │  │ Lead          │           │
│   │ - Process     │  │               │  │               │           │
│   │   safety      │  │ - IT security │  │ - Internal    │           │
│   │ - HSE         │  │ - OT engineer │  │ - External    │           │
│   │ - Operations  │  │ - Forensics   │  │ - Regulatory  │           │
│   └───────────────┘  └───────────────┘  └───────────────┘           │
│                                                                      │
│   Key Roles:                                                         │
│   ──────────                                                         │
│   • Safety Lead: Can override any decision on safety grounds         │
│   • OT Engineer: Understands process, can advise on impacts          │
│   • Operations Rep: Current production status, manual procedures     │
│   • IT Security: Investigation, forensics, containment               │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Phase 2: Detection and Analysis

### Initial Assessment Questions

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Initial Assessment Checklist                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   SAFETY ASSESSMENT (First Priority):                                │
│   ───────────────────────────────────                                │
│   [ ] Is there any immediate safety risk?                            │
│   [ ] Are safety systems functioning normally?                       │
│   [ ] Is the process within safe operating limits?                   │
│   [ ] Do we need to initiate emergency shutdown?                     │
│   [ ] Are operators aware and monitoring?                            │
│                                                                      │
│   SCOPE ASSESSMENT:                                                  │
│   ─────────────────                                                  │
│   [ ] What systems are affected? (IT/OT/both)                        │
│   [ ] What is the extent of compromise?                              │
│   [ ] Is the attack ongoing or contained?                            │
│   [ ] What data or access might attacker have?                       │
│   [ ] Are other sites/plants at risk?                                │
│                                                                      │
│   OPERATIONAL ASSESSMENT:                                            │
│   ───────────────────────                                            │
│   [ ] What is current production status?                             │
│   [ ] Can we continue operations safely?                             │
│   [ ] What manual fallback options exist?                            │
│   [ ] What are the business impacts of shutdown?                     │
│   [ ] What planned maintenance windows are available?                │
│                                                                      │
│   TECHNICAL ASSESSMENT:                                              │
│   ─────────────────────                                              │
│   [ ] What indicators of compromise exist?                           │
│   [ ] What logs and evidence are available?                          │
│   [ ] What is the likely attack vector?                              │
│   [ ] What tools/malware are involved?                               │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Severity Classification

| Level | Description | OT Impact | Response Time |
|-------|-------------|-----------|---------------|
| **Critical** | Active threat to safety | Safety system compromised | Immediate |
| **High** | Active attack on OT | Production control affected | < 1 hour |
| **Medium** | OT network compromised | No direct process impact yet | < 4 hours |
| **Low** | IT compromise, OT unaffected | Monitoring for spread | < 24 hours |

## Phase 3: Containment

### Containment Decision Matrix

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Containment Options                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Situation                         Recommended Action               │
│   ─────────────────────────────────────────────────────────────────  │
│                                                                      │
│   Safety system compromised    →    Emergency shutdown               │
│                                     (safety first, always)           │
│                                                                      │
│   Active attack on DCS/PLC    →    Isolate from network              │
│                                     (can process run standalone?)    │
│                                                                      │
│   IT/OT boundary breached     →    Disconnect IT/OT link             │
│                                     (monitor OT closely)             │
│                                                                      │
│   Ransomware spreading        →    Segment network                   │
│                                     (contain blast radius)           │
│                                                                      │
│   Unknown scope               →    Monitor, don't alert attacker     │
│                                     (gather intelligence)            │
│                                                                      │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │                                                             │   │
│   │   Key Principle:                                            │   │
│   │   Containment should not make things worse                  │   │
│   │                                                             │   │
│   │   Before disconnecting any OT system:                       │   │
│   │   • What process does it control?                           │   │
│   │   • What happens if communication lost?                     │   │
│   │   • Can operators maintain safe operation?                  │   │
│   │                                                             │   │
│   └─────────────────────────────────────────────────────────────┘   │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Short-Term Containment

Actions to stop immediate spread:

| Action | OT Consideration |
|--------|------------------|
| Block malicious IP | Verify not blocking OT traffic |
| Disable user account | Check for OT service dependencies |
| Isolate workstation | Is it an HMI or engineering WS? |
| Disconnect network segment | What processes lose connectivity? |
| Shut down server | What OT systems depend on it? |

### Long-Term Containment

Sustainable containment during investigation:

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Long-Term Containment Strategy                    │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   1. Network Level:                                                  │
│      • Block lateral movement paths                                  │
│      • Implement stricter firewall rules                             │
│      • Enable enhanced logging                                       │
│      • Deploy additional monitoring                                  │
│                                                                      │
│   2. Host Level:                                                     │
│      • Isolate known-compromised systems                             │
│      • Enable application whitelisting                               │
│      • Disable unnecessary services                                  │
│      • Deploy endpoint detection (where safe)                        │
│                                                                      │
│   3. Credential Level:                                               │
│      • Reset compromised credentials                                 │
│      • Implement additional authentication                           │
│      • Revoke VPN/remote access                                      │
│                                                                      │
│   4. Operations Level:                                               │
│      • Increase manual monitoring                                    │
│      • Verify safety system integrity                                │
│      • Implement additional operator checks                          │
│                                                                      │
│   Duration: Until investigation complete and systems verified        │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Phase 4: Eradication and Recovery

### OT System Verification

Before returning systems to production:

```
┌─────────────────────────────────────────────────────────────────────┐
│                    System Integrity Verification                     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   PLC/Controller Verification:                                       │
│   ────────────────────────────                                       │
│   [ ] Compare program to known-good backup                           │
│   [ ] Verify firmware version                                        │
│   [ ] Check all configuration parameters                             │
│   [ ] Validate I/O configuration                                     │
│   [ ] Test safety functions                                          │
│   [ ] Verify communication settings                                  │
│                                                                      │
│   HMI/SCADA Verification:                                            │
│   ─────────────────────────                                          │
│   [ ] Reinstall from known-good media                                │
│   [ ] Verify application configuration                               │
│   [ ] Check alarm settings                                           │
│   [ ] Validate user accounts                                         │
│   [ ] Test all critical functions                                    │
│                                                                      │
│   Network Verification:                                              │
│   ─────────────────────                                              │
│   [ ] Verify firewall rules                                          │
│   [ ] Check switch configurations                                    │
│   [ ] Validate routing                                               │
│   [ ] Test connectivity                                              │
│   [ ] Enable monitoring                                              │
│                                                                      │
│   Process Verification:                                              │
│   ─────────────────────                                              │
│   [ ] Test interlocks                                                │
│   [ ] Verify setpoints                                               │
│   [ ] Check trip points                                              │
│   [ ] Run startup procedures                                         │
│   [ ] Monitor closely during initial operation                       │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Recovery Prioritization

| Priority | Systems | Rationale |
|----------|---------|-----------|
| 1 | Safety systems | Must verify before any operations |
| 2 | Core process control | Required for safe operation |
| 3 | Monitoring/historian | Needed for visibility |
| 4 | Engineering systems | Required for recovery |
| 5 | Business integration | Can operate without |

### Staged Recovery

```
┌─────────────────────────────────────────────────────────────────────┐
│                    OT Recovery Sequence                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Stage 1: Verify Safety (Before anything else)                      │
│   ─────────────────────────────────────────────                      │
│   • Verify safety system integrity                                   │
│   • Test emergency stops                                             │
│   • Confirm alarm systems work                                       │
│   • Get safety sign-off                                              │
│                                                                      │
│   Stage 2: Core Control                                              │
│   ─────────────────────                                              │
│   • Bring up primary controllers                                     │
│   • Verify basic control loops                                       │
│   • Test operator interfaces                                         │
│   • Start with minimal production                                    │
│                                                                      │
│   Stage 3: Extended Operations                                       │
│   ────────────────────────────                                       │
│   • Restore full monitoring                                          │
│   • Re-enable historian                                              │
│   • Connect engineering workstations                                 │
│   • Increase production gradually                                    │
│                                                                      │
│   Stage 4: Full Operations                                           │
│   ─────────────────────────                                          │
│   • Reconnect IT/OT integration (carefully)                          │
│   • Resume remote access (with enhanced controls)                    │
│   • Return to normal operations                                      │
│   • Maintain enhanced monitoring                                     │
│                                                                      │
│   Each stage requires sign-off from:                                 │
│   • Safety representative                                            │
│   • Operations representative                                        │
│   • Security representative                                          │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Forensics in OT

### Safe Evidence Collection

```
┌─────────────────────────────────────────────────────────────────────┐
│                    OT Forensics Considerations                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   SAFE TO COLLECT (usually):                                         │
│   ──────────────────────────                                         │
│   • Network traffic captures (passive)                               │
│   • Log files from SIEM/historian                                    │
│   • Disk images of offline systems                                   │
│   • Memory dumps of offline systems                                  │
│   • Configuration backups                                            │
│   • Photos/screenshots                                               │
│                                                                      │
│   CAUTION REQUIRED:                                                  │
│   ─────────────────                                                  │
│   • Live memory acquisition (may crash system)                       │
│   • Disk imaging of active HMI (prefer shutdown first)               │
│   • Querying running PLCs (use passive methods)                      │
│   • Any action that generates network traffic                        │
│                                                                      │
│   AVOID:                                                             │
│   ──────                                                             │
│   • Scanning production networks                                     │
│   • Installing agents on production systems                          │
│   • Running unknown tools on OT systems                              │
│   • Anything that could affect process                               │
│                                                                      │
│   PLC Forensics:                                                     │
│   ─────────────                                                      │
│   • Download program without stopping (if supported)                 │
│   • Compare to baseline offline                                      │
│   • Document all findings                                            │
│   • Use vendor tools when possible                                   │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Evidence Preservation

| Evidence Type | Collection Method | Priority |
|---------------|-------------------|----------|
| Network captures | TAP or SPAN (passive) | High |
| Firewall logs | Copy from management console | High |
| PLC programs | Download via engineering SW | Critical |
| HMI disk | Image when safe to shut down | Medium |
| Event logs | Export or remote collection | High |
| Historian data | Database export | Medium |

## Communication During Incidents

### Internal Communication

```
┌─────────────────────────────────────────────────────────────────────┐
│                    OT Incident Communication Plan                    │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Notification Order:                                                │
│   ───────────────────                                                │
│   1. Operations/Control Room (if OT affected)                        │
│   2. Safety/HSE team                                                 │
│   3. Plant/Site management                                           │
│   4. IT Security leadership                                          │
│   5. Executive management                                            │
│   6. Legal/Communications                                            │
│                                                                      │
│   Status Update Frequency:                                           │
│   ─────────────────────────                                          │
│   Critical incident:  Every 30 minutes                               │
│   High incident:      Every 2 hours                                  │
│   Medium incident:    Every 4 hours                                  │
│   Low incident:       Daily                                          │
│                                                                      │
│   Communication Channels:                                            │
│   ───────────────────────                                            │
│   • Phone/radio for critical (OT may be down)                        │
│   • Out-of-band communication (cell phones)                          │
│   • Do NOT use potentially compromised systems                       │
│                                                                      │
│   What to Communicate:                                               │
│   ─────────────────────                                              │
│   • Current status                                                   │
│   • Safety implications                                              │
│   • Operational impacts                                              │
│   • Actions being taken                                              │
│   • What responders need                                             │
│   • Next update time                                                 │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### External Notification Requirements

| Stakeholder | When to Notify | Requirements |
|-------------|----------------|--------------|
| **CISA/ICS-CERT** | Critical infrastructure incidents | Voluntary but recommended |
| **Sector ISAC** | Share threat intelligence | Membership dependent |
| **Law Enforcement** | Criminal activity, ransom demands | Consult legal |
| **Regulators** | Per sector requirements | NERC CIP, TSA, etc. |
| **Customers** | If service affected | Contractual/legal |
| **Public** | If public safety affected | Coordinated messaging |

## Post-Incident Activities

### Lessons Learned

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Post-Incident Review                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Review Meeting Participants:                                       │
│   ────────────────────────────                                       │
│   • IR team members                                                  │
│   • Operations representatives                                       │
│   • Safety representatives                                           │
│   • Management (appropriate level)                                   │
│   • External responders (if used)                                    │
│                                                                      │
│   Discussion Topics:                                                 │
│   ──────────────────                                                 │
│   1. Timeline of events                                              │
│   2. What worked well                                                │
│   3. What could be improved                                          │
│   4. Root cause analysis                                             │
│   5. Gaps identified                                                 │
│   6. Recommendations                                                 │
│                                                                      │
│   Output Documents:                                                  │
│   ─────────────────                                                  │
│   • Incident report                                                  │
│   • Lessons learned                                                  │
│   • Action items with owners                                         │
│   • Updated procedures                                               │
│   • Training needs identified                                        │
│                                                                      │
│   Timing:                                                            │
│   ───────                                                            │
│   • Hot wash: Within 24-48 hours (immediate feedback)                │
│   • Formal review: Within 2 weeks                                    │
│   • Report completion: Within 30 days                                │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Key Takeaways

1. **Safety first, always** - never compromise safety for investigation
2. **Involve operations early** - they understand the process
3. **Containment carefully** - don't make things worse
4. **Verify before recovery** - ensure systems are clean
5. **Staged recovery** - safety systems first
6. **Forensics safely** - passive methods preferred
7. **Document everything** - for learning and legal purposes
8. **Communicate regularly** - keep stakeholders informed

## Study Questions

1. Why should the Safety Lead have override authority in an OT incident?

2. An attacker is actively in your SCADA system but hasn't affected the process yet. What are your containment options?

3. How do you verify PLC integrity without affecting production?

4. When would you choose to shut down production rather than continue during an incident?

5. What evidence can you safely collect from a running OT network?

## Tabletop Exercise

**Scenario**: Your manufacturing plant receives a ransom note. IT systems are encrypted. OT status unknown.

Walk through:
1. Initial assessment actions
2. Safety verification steps
3. Containment decisions
4. Communication plan
5. Recovery priorities

## Next Steps

Continue to [10-iec62443-deep-dive.md](10-iec62443-deep-dive.md) to understand the primary OT security standard.

## References

- NIST SP 800-82 Rev. 2 - Incident Response
- NIST SP 800-61 - Computer Security Incident Handling Guide
- CISA: ICS-CERT Incident Response Guide
- SANS: ICS Incident Response
- Dragos: OT Incident Response Best Practices
