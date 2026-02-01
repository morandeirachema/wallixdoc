# OT vs IT Security

The fundamental mindset shift for IT professionals entering OT security.

## The Core Difference

This single concept underlies everything in OT security:

```
┌─────────────────────────────────────────────────────────────────────┐
│                    The Fundamental Difference                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   IT Security protects DATA                                          │
│   OT Security protects PHYSICAL PROCESSES                            │
│                                                                      │
│   ─────────────────────────────────────────────────────────────────  │
│                                                                      │
│   IT Breach Consequence:                                             │
│   • Data stolen, reputation damaged, financial loss                  │
│   • Recovery: Restore from backup, notify affected parties           │
│                                                                      │
│   OT Breach Consequence:                                             │
│   • Equipment destroyed, environment damaged, people harmed          │
│   • Recovery: May not be possible, investigation required            │
│                                                                      │
│   ─────────────────────────────────────────────────────────────────  │
│                                                                      │
│   "In IT, we protect information.                                    │
│    In OT, we protect people and the physical world."                 │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## The CIA Triad Reversal

IT security prioritizes Confidentiality, Integrity, Availability (CIA).
OT security reverses this to AIC:

```
┌─────────────────────────────────────────────────────────────────────┐
│                    CIA vs AIC Priority                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   IT Security (CIA)              OT Security (AIC)                   │
│   ─────────────────              ─────────────────                   │
│                                                                      │
│   1. CONFIDENTIALITY             1. AVAILABILITY                     │
│      Keep data secret               Keep process running             │
│      "Protect customer data"        "Don't stop production"          │
│                                                                      │
│   2. INTEGRITY                   2. INTEGRITY                        │
│      Prevent modification           Ensure correct operation         │
│      "Data must be accurate"        "Commands must be trusted"       │
│                                                                      │
│   3. AVAILABILITY                3. CONFIDENTIALITY                  │
│      System accessible              Protect process data             │
│      "5 nines uptime"               "Often less critical"            │
│                                                                      │
│   ─────────────────────────────────────────────────────────────────  │
│                                                                      │
│   IT: "We can tolerate downtime to patch a vulnerability"            │
│   OT: "We cannot stop production for your security update"           │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Why Availability First?

In OT, downtime has immediate physical consequences:

| Sector | Downtime Impact |
|--------|-----------------|
| **Power Grid** | Blackouts, cascading failures, loss of critical services |
| **Water Treatment** | No drinking water, sewage backup, public health crisis |
| **Oil Refinery** | Equipment damage, fire/explosion risk, environmental release |
| **Manufacturing** | Scrapped product, supply chain disruption, contract penalties |
| **Hospital** | Patient safety systems offline, life support at risk |

## Operational Constraints

These real-world constraints shape OT security decisions:

### Change Windows

```
┌─────────────────────────────────────────────────────────────────────┐
│                    IT vs OT Change Windows                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   IT Environment:                                                    │
│   ─────────────────                                                  │
│   • Weekly/monthly maintenance windows                               │
│   • Rolling updates with load balancers                              │
│   • Blue-green deployments                                           │
│   • "Patch Tuesday" culture                                          │
│                                                                      │
│   OT Environment:                                                    │
│   ─────────────────                                                  │
│   • Annual or biannual turnarounds                                   │
│   • Multi-month planning cycles                                      │
│   • $1M+ per day downtime costs                                      │
│   • Some systems NEVER shut down                                     │
│                                                                      │
│   ─────────────────────────────────────────────────────────────────  │
│                                                                      │
│   Example: Refinery turnaround                                       │
│   • Planned 12-18 months in advance                                  │
│   • Lasts 4-6 weeks                                                  │
│   • Costs $50M+ in lost production                                   │
│   • Only window for major changes                                    │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Testing Limitations

| IT Testing | OT Testing |
|------------|------------|
| Dev/staging environments | Production is the only real test |
| Virtualization easy | Physical processes can't be virtualized |
| Rollback in minutes | Rollback may take days |
| Test in isolation | Interdependent systems |
| Fail fast, fix fast | Failure may cause physical damage |

### Vendor Dependencies

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Vendor Support Model                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   IT Model:                                                          │
│   • Multiple vendors, commodity hardware                             │
│   • Rapid innovation cycles                                          │
│   • Open standards (mostly)                                          │
│   • Replace vendor if support ends                                   │
│                                                                      │
│   OT Model:                                                          │
│   • Single vendor per system (lock-in)                               │
│   • 20+ year support requirements                                    │
│   • Proprietary protocols                                            │
│   • Vendor must approve any changes                                  │
│   • Warranty/support voided by modifications                         │
│                                                                      │
│   ─────────────────────────────────────────────────────────────────  │
│                                                                      │
│   "If you install unauthorized software on this DCS, your           │
│    $2M support contract is void and we won't help you recover."     │
│                                     - Every DCS vendor ever          │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Security Control Differences

### Patching

| Aspect | IT | OT |
|--------|----|----|
| **Frequency** | Monthly | Annually (if ever) |
| **Testing** | Weeks | Months |
| **Approval** | IT team | Vendor + Operations + Engineering |
| **Rollback** | Minutes | Hours to days |
| **Scope** | All systems | Case-by-case |

### Antivirus/EDR

| Aspect | IT | OT |
|--------|----|----|
| **Deployment** | Universal | Limited/none |
| **Updates** | Automatic | Manual, tested |
| **Scanning** | Real-time | Scheduled only |
| **Quarantine** | Automatic | Manual only |
| **Concern** | Malware | Process interruption |

### Network Security

| Aspect | IT | OT |
|--------|----|----|
| **Segmentation** | VLANs, microsegmentation | Physical separation |
| **Monitoring** | Full packet capture | Protocol-aware only |
| **Encryption** | Required everywhere | May break systems |
| **Authentication** | Required | Often absent |
| **Firewalls** | Stateful, app-aware | Basic, deterministic |

## Common IT Practices That Fail in OT

### Active Vulnerability Scanning

```
┌─────────────────────────────────────────────────────────────────────┐
│           Why Active Scanning Breaks OT Systems                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   IT Network:                                                        │
│   Scanner ──► Server                                                 │
│   "Server handles malformed packets gracefully"                      │
│                                                                      │
│   OT Network:                                                        │
│   Scanner ──► PLC ──► CRASH                                          │
│   "PLC was not designed for this traffic, reboots"                   │
│                                                                      │
│   ─────────────────────────────────────────────────────────────────  │
│                                                                      │
│   Real Examples:                                                     │
│   • Nessus scan crashes Siemens S7-300 (CVE-2014-2256)               │
│   • Port scan restarts Modicon Quantum PLC                           │
│   • Vulnerability scan causes GE Multilin relay failure              │
│   • Network discovery tool triggers DCS watchdog                     │
│                                                                      │
│   Rule: NEVER run active scans against OT systems without            │
│         explicit approval and out-of-band recovery plan              │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Password Rotation

```
┌─────────────────────────────────────────────────────────────────────┐
│           Why 90-Day Password Rotation Fails in OT                   │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   IT Policy: "Rotate all passwords every 90 days"                    │
│                                                                      │
│   OT Reality:                                                        │
│   • PLCs have hardcoded credentials in programs                      │
│   • HMI scripts store passwords for database access                  │
│   • Service accounts run 24/7/365 without interruption               │
│   • Some systems don't support password changes                      │
│   • Changing one password may require coordinated change             │
│     across dozens of systems                                         │
│                                                                      │
│   Better Approach:                                                   │
│   • Use PAM solutions for session-based access                       │
│   • Implement credential injection                                   │
│   • Rotate when operationally safe                                   │
│   • Document credentials, don't lose them                            │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Automatic Updates

```
┌─────────────────────────────────────────────────────────────────────┐
│           Why Automatic Updates Are Dangerous in OT                  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   IT: "Enable automatic updates for all systems"                     │
│                                                                      │
│   OT Scenario:                                                       │
│   • Windows Update runs at 2 AM on HMI                               │
│   • System reboots during batch process                              │
│   • Operator cannot see alarm                                        │
│   • Batch is ruined ($500K loss)                                     │
│                                                                      │
│   Worse Scenario:                                                    │
│   • Update changes driver behavior                                   │
│   • Communication to safety PLC affected                             │
│   • Emergency shutdown fails                                         │
│   • Physical damage, injuries possible                               │
│                                                                      │
│   Rule: ALL updates must be manually approved and tested             │
│         in OT environments                                           │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Encryption Everywhere

```
┌─────────────────────────────────────────────────────────────────────┐
│           Why "Encrypt Everything" Fails in OT                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   IT: "All traffic must be encrypted"                                │
│                                                                      │
│   OT Challenges:                                                     │
│   • Many protocols don't support encryption (Modbus, DNP3)           │
│   • Encryption adds latency (breaks real-time requirements)          │
│   • Certificate management on embedded devices                       │
│   • Crypto processing on constrained hardware                        │
│   • Visibility: Can't inspect encrypted traffic for threats          │
│                                                                      │
│   Better Approach:                                                   │
│   • Network segmentation as primary protection                       │
│   • Encrypt at boundaries (VPN between zones)                        │
│   • Use protocol-specific security where available (OPC UA)          │
│   • Physical security for local networks                             │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Zero Trust

```
┌─────────────────────────────────────────────────────────────────────┐
│           Zero Trust Challenges in OT                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   IT Zero Trust Principles:                                          │
│   • Never trust, always verify                                       │
│   • Microsegmentation                                                │
│   • Continuous authentication                                        │
│   • Least privilege access                                           │
│                                                                      │
│   OT Implementation Challenges:                                      │
│   • Legacy devices cannot authenticate                               │
│   • Microsegmentation breaks multicast (PROFINET, OPC UA)            │
│   • Continuous auth adds latency                                     │
│   • Service accounts need persistent access                          │
│   • Safety systems must work even if auth fails                      │
│                                                                      │
│   Practical OT Zero Trust:                                           │
│   • Zone-based architecture (macro-segmentation)                     │
│   • Strong authentication at zone boundaries                         │
│   • PAM for privileged access                                        │
│   • Accept some trust within zones                                   │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## The Safety Dimension

### Safety vs Security

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Safety vs Security                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Safety:                                                            │
│   • Protecting people and equipment from the PROCESS                 │
│   • Preventing accidents, fires, explosions                          │
│   • Engineering discipline, well-understood                          │
│   • Regulatory requirements (OSHA, EPA)                              │
│                                                                      │
│   Security:                                                          │
│   • Protecting the process from ATTACKERS                            │
│   • Preventing unauthorized access/modification                      │
│   • Evolving threat landscape                                        │
│   • Regulatory requirements emerging (NERC CIP, TSA)                 │
│                                                                      │
│   ─────────────────────────────────────────────────────────────────  │
│                                                                      │
│   Critical Principle:                                                │
│   SAFETY ALWAYS WINS OVER SECURITY                                   │
│                                                                      │
│   If a security control could prevent a safety system from           │
│   operating, the security control must be removed or redesigned.     │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### When Safety and Security Conflict

| Scenario | Safety Requirement | Security Requirement | Resolution |
|----------|-------------------|---------------------|------------|
| Emergency shutdown | Always accessible | No unauthorized access | Physical bypass for safety |
| Fire panel | No authentication | Authenticated access | Physical security + logging |
| Safety PLC | No network security overhead | Network protection | Air-gap safety network |
| Panic button | Immediate response | Verify identity | Safety wins - immediate response |

## Building the Right Mindset

### Questions to Ask Before Any Change

1. **What physical process does this system control?**
2. **What happens if this system stops working?**
3. **What happens if this system gives wrong data?**
4. **Who needs to approve this change?**
5. **How do we test this without affecting production?**
6. **How do we roll back if something goes wrong?**
7. **Are there safety implications?**

### The OT Security Professional's Oath

```
┌─────────────────────────────────────────────────────────────────────┐
│                    OT Security Principles                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   1. I will understand the process before I secure it                │
│                                                                      │
│   2. I will not implement security that endangers safety             │
│                                                                      │
│   3. I will coordinate with operations before making changes         │
│                                                                      │
│   4. I will have rollback plans for every change                     │
│                                                                      │
│   5. I will never scan production systems without approval           │
│                                                                      │
│   6. I will respect that availability is paramount                   │
│                                                                      │
│   7. I will learn from operations and engineering, not dictate       │
│                                                                      │
│   8. I will design controls that fail safely                         │
│                                                                      │
│   9. I will accept that "good enough" security may be necessary      │
│                                                                      │
│  10. I will remember that behind every system are people             │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Comparison Table Summary

| Aspect | IT | OT |
|--------|----|----|
| **Priority** | CIA (Confidentiality first) | AIC (Availability first) |
| **Downtime tolerance** | Hours acceptable | Seconds critical |
| **Patching cycle** | Weekly/monthly | Annual/never |
| **System lifespan** | 3-5 years | 15-30 years |
| **Testing** | Staging environment | Production only |
| **Vendor control** | Multi-vendor | Single vendor lock-in |
| **Change process** | ITIL, quick | MOC, months of planning |
| **Scanning** | Routine | Only with approval |
| **Updates** | Automatic | Manual, tested |
| **Encryption** | Everywhere | At boundaries only |
| **Authentication** | Multi-factor everywhere | Often absent |
| **Incident response** | Isolate, investigate | Keep running safely |
| **Staff** | IT-focused | Engineering + IT hybrid |
| **Failure mode** | Service outage | Physical damage |

## Cultural Differences

### IT Culture

- Move fast, break things (then fix them)
- Innovation rewarded
- Agile methodology
- Cloud-first mentality
- Strong vendor ecosystem

### OT Culture

- Move carefully, break nothing
- Reliability rewarded
- Waterfall methodology
- On-premise forever
- Single vendor relationships

### Bridging the Gap

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Building IT/OT Collaboration                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   IT Professionals Should:                                           │
│   • Learn the physical process                                       │
│   • Respect operational constraints                                  │
│   • Partner with, not dictate to, OT                                 │
│   • Accept different risk tolerances                                 │
│   • Understand safety implications                                   │
│                                                                      │
│   OT Professionals Should:                                           │
│   • Accept that cyber threats are real                               │
│   • Learn basic security concepts                                    │
│   • Share process knowledge                                          │
│   • Participate in security planning                                 │
│   • Report anomalies to IT security                                  │
│                                                                      │
│   Together:                                                          │
│   • Joint tabletop exercises                                         │
│   • Shared risk assessments                                          │
│   • Cross-training programs                                          │
│   • Integrated monitoring                                            │
│   • Unified incident response                                        │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Key Takeaways

1. **Availability first** - production cannot stop for your security
2. **Safety trumps security** - never compromise safety systems
3. **Respect the process** - understand what you're protecting
4. **Change is hard** - plan months ahead, test thoroughly
5. **Vendor dependency** - you need their approval
6. **Legacy is reality** - 20-year-old systems are normal
7. **Different culture** - partner with OT, don't dictate
8. **Physical consequences** - your decisions affect the real world

## Study Questions

1. Why is availability prioritized over confidentiality in OT environments?

2. A patch is available for a critical vulnerability in a SCADA server. What steps should be taken before applying it?

3. Why might adding encryption to an OT network cause more problems than it solves?

4. An IT auditor recommends disabling USB ports on all HMI workstations. What factors should be considered?

5. How would you explain to an IT security manager why 90-day password rotation doesn't work for PLCs?

## Practical Exercise

**Scenario**: You're an IT security professional assigned to improve OT security at a water treatment plant.

1. Who do you need to meet with before making any recommendations?
2. What questions do you need to ask to understand the environment?
3. What IT security practices might be harmful if applied directly?
4. What would be a reasonable first security improvement to propose?
5. How would you measure success?

## Next Steps

Continue to [04-industrial-protocols.md](04-industrial-protocols.md) to learn about the specific communication protocols used in OT environments.

## References

- NIST SP 800-82 Rev. 2 Guide to Industrial Control Systems Security
- IEC 62443 Series: Industrial Automation and Control Systems Security
- SANS ICS Security Resources: https://www.sans.org/cyber-security-courses/ics-scada-cyber-security-essentials/
- CISA ICS-CERT: https://www.cisa.gov/ics
