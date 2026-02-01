# Vendor Risk Management for OT

Managing third-party and supply chain risks in industrial environments.

## Why Vendor Risk Matters in OT

```
┌─────────────────────────────────────────────────────────────────────┐
│                    OT Vendor Risk Landscape                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   OT environments are highly vendor-dependent:                       │
│                                                                      │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │                                                             │   │
│   │   Control System Vendor                                     │   │
│   │   • Provides DCS/PLC/SCADA                                  │   │
│   │   • Has remote access for support                           │   │
│   │   • Supplies software updates                               │   │
│   │   • May have admin credentials                              │   │
│   │                          │                                  │   │
│   │   Integrator             │                                  │   │
│   │   • Installs systems     │         Maintenance              │   │
│   │   • Configures networks  │         Contractor               │   │
│   │   • Programs PLCs        │         • Regular site access    │   │
│   │   • May retain access    │         • Equipment knowledge    │   │
│   │                          │         • OT credentials         │   │
│   │                          │                                  │   │
│   │              ────────────┼────────────                      │   │
│   │                          │                                  │   │
│   │                     YOUR OT                                 │   │
│   │                    ENVIRONMENT                              │   │
│   │                          │                                  │   │
│   │              ────────────┼────────────                      │   │
│   │                          │                                  │   │
│   │   Specialty              │          Software/Firmware       │   │
│   │   Equipment              │          Suppliers               │   │
│   │   • Analyzers            │          • Embedded code         │   │
│   │   • Drives               │          • Libraries             │   │
│   │   • Safety systems       │          • Components            │   │
│   │                          │                                  │   │
│   │                    Cloud Services                           │   │
│   │                    • Remote monitoring                      │   │
│   │                    • Predictive maintenance                 │   │
│   │                    • Data analytics                         │   │
│   │                                                             │   │
│   └─────────────────────────────────────────────────────────────┘   │
│                                                                      │
│   Each connection is a potential attack vector                       │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Supply Chain Attacks

### Notable Supply Chain Incidents

| Incident | Year | Impact | OT Relevance |
|----------|------|--------|--------------|
| **SolarWinds** | 2020 | 18,000 orgs compromised | IT/OT boundary breach |
| **Codecov** | 2021 | Build pipeline compromise | Software supply chain |
| **Kaseya** | 2021 | 1,500 businesses ransomware | MSP compromise |
| **Log4j** | 2021 | Widespread vulnerability | Embedded in OT products |
| **Stuxnet** | 2010 | Iran nuclear program | OT supply chain target |

### Supply Chain Attack Vectors

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Supply Chain Attack Vectors                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   1. SOFTWARE SUPPLY CHAIN                                           │
│      ─────────────────────────                                       │
│      • Compromised software updates                                  │
│      • Malicious libraries/dependencies                              │
│      • Backdoored source code                                        │
│      • Infected development environments                             │
│                                                                      │
│   2. HARDWARE SUPPLY CHAIN                                           │
│      ─────────────────────────                                       │
│      • Counterfeit components                                        │
│      • Hardware implants                                             │
│      • Malicious firmware                                            │
│      • Tampered equipment                                            │
│                                                                      │
│   3. SERVICE PROVIDER COMPROMISE                                     │
│      ─────────────────────────────                                   │
│      • Compromised integrator                                        │
│      • Infected contractor laptop                                    │
│      • Stolen vendor credentials                                     │
│      • Insider threat at vendor                                      │
│                                                                      │
│   4. VENDOR ACCESS ABUSE                                             │
│      ────────────────────────                                        │
│      • Excessive privileges                                          │
│      • Persistent access after project                               │
│      • Shared credentials                                            │
│      • Unmonitored sessions                                          │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Vendor Assessment Framework

### Pre-Engagement Assessment

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Vendor Security Questionnaire                     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   COMPANY SECURITY POSTURE                                           │
│   ────────────────────────                                           │
│   [ ] Do you have a formal security program?                         │
│   [ ] Do you have ISO 27001 or SOC 2 certification?                  │
│   [ ] Do you have cyber insurance?                                   │
│   [ ] When was your last security assessment/penetration test?       │
│   [ ] Have you experienced a security breach in past 3 years?        │
│                                                                      │
│   PRODUCT SECURITY (For Software/Hardware Vendors)                   │
│   ─────────────────────────────────────────────────                  │
│   [ ] Is the product IEC 62443-4-2 certified?                        │
│   [ ] Do you follow secure development lifecycle (SDL)?              │
│   [ ] How do you manage vulnerabilities in your products?            │
│   [ ] What is your patch release process and timeline?               │
│   [ ] Do you provide software bill of materials (SBOM)?              │
│                                                                      │
│   ACCESS AND CONNECTIVITY                                            │
│   ─────────────────────────                                          │
│   [ ] What access do you require to our systems?                     │
│   [ ] Will you need remote access?                                   │
│   [ ] What credentials do you require?                               │
│   [ ] How will your personnel connect?                               │
│   [ ] Can you operate through our PAM solution?                      │
│                                                                      │
│   DATA HANDLING                                                      │
│   ────────────                                                       │
│   [ ] What data will you access/collect?                             │
│   [ ] Where will our data be stored/processed?                       │
│   [ ] How is our data protected?                                     │
│   [ ] What is your data retention policy?                            │
│   [ ] How is data disposed of after engagement?                      │
│                                                                      │
│   INCIDENT RESPONSE                                                  │
│   ─────────────────                                                  │
│   [ ] What is your incident notification process?                    │
│   [ ] What is your notification timeline?                            │
│   [ ] How do you support customer incident response?                 │
│                                                                      │
│   SUBCONTRACTORS                                                     │
│   ──────────────                                                     │
│   [ ] Do you use subcontractors?                                     │
│   [ ] How do you vet subcontractor security?                         │
│   [ ] Will subcontractors access our systems/data?                   │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Vendor Risk Scoring

| Factor | Weight | Low Risk (1) | Medium Risk (3) | High Risk (5) |
|--------|--------|--------------|-----------------|---------------|
| **Access Level** | 25% | Read-only | Limited write | Admin/root |
| **Connectivity** | 20% | On-site only | VPN | Always-on |
| **Data Sensitivity** | 20% | Non-sensitive | Operational | Safety/recipes |
| **System Criticality** | 20% | Support systems | Production | Safety systems |
| **Vendor Maturity** | 15% | Certified, large | Established | Small, new |

## Contractual Requirements

### Security Clauses for OT Contracts

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Essential Contract Provisions                     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   ACCESS CONTROLS                                                    │
│   ───────────────                                                    │
│   "Vendor shall access Customer systems only through Customer-       │
│   provided Privileged Access Management (PAM) solution. All          │
│   sessions shall be recorded and subject to Customer review."        │
│                                                                      │
│   SECURITY REQUIREMENTS                                              │
│   ─────────────────────                                              │
│   "Vendor shall maintain security controls consistent with IEC       │
│   62443-2-4 for service providers. Vendor shall provide evidence     │
│   of compliance upon Customer request."                              │
│                                                                      │
│   INCIDENT NOTIFICATION                                              │
│   ─────────────────────                                              │
│   "Vendor shall notify Customer within 24 hours of discovery         │
│   of any security incident that may affect Customer systems or       │
│   data. Vendor shall cooperate fully with incident investigation."   │
│                                                                      │
│   VULNERABILITY DISCLOSURE                                           │
│   ─────────────────────────                                          │
│   "Vendor shall notify Customer of any vulnerabilities in            │
│   products/services within 48 hours of discovery. Vendor shall       │
│   provide remediation plan and timeline."                            │
│                                                                      │
│   RIGHT TO AUDIT                                                     │
│   ──────────────                                                     │
│   "Customer reserves the right to audit Vendor security controls     │
│   annually or following any security incident."                      │
│                                                                      │
│   DATA PROTECTION                                                    │
│   ───────────────                                                    │
│   "All Customer data accessed by Vendor shall be encrypted in        │
│   transit and at rest. Vendor shall not retain Customer data         │
│   beyond the engagement period without written authorization."       │
│                                                                      │
│   TERMINATION                                                        │
│   ───────────                                                        │
│   "Upon termination, Vendor shall return or securely destroy         │
│   all Customer data and credentials within 30 days."                 │
│                                                                      │
│   LIABILITY                                                          │
│   ─────────                                                          │
│   "Vendor shall be liable for security incidents caused by           │
│   Vendor negligence, including costs of remediation, business        │
│   interruption, and regulatory penalties."                           │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Secure Remote Access for Vendors

### Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Secure Vendor Remote Access                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Vendor                                                             │
│   ┌──────────────┐                                                  │
│   │   Engineer   │                                                  │
│   │   Laptop     │                                                  │
│   └──────┬───────┘                                                  │
│          │                                                          │
│          │ HTTPS (443)                                              │
│          ▼                                                          │
│   ┌──────────────────────────────────────────────────────────────┐  │
│   │   Corporate Perimeter                                        │  │
│   │   ┌────────────────────────────────────────────────────┐     │  │
│   │   │         Vendor VPN Gateway                         │     │  │
│   │   │   • Certificate-based auth                         │     │  │
│   │   │   • MFA required                                   │     │  │
│   │   │   • Vendor-specific VPN profile                    │     │  │
│   │   └───────────────────────┬────────────────────────────┘     │  │
│   └───────────────────────────┼──────────────────────────────────┘  │
│                               │                                      │
│                               ▼                                      │
│   ┌──────────────────────────────────────────────────────────────┐  │
│   │   OT DMZ                                                     │  │
│   │   ┌────────────────────────────────────────────────────┐     │  │
│   │   │   Privileged Access Management (PAM)               │     │  │
│   │   │                                                    │     │  │
│   │   │   ┌──────────────────────────────────────────────┐ │     │  │
│   │   │   │ 1. Vendor authenticates (MFA)                │ │     │  │
│   │   │   │ 2. Session approval workflow                 │ │     │  │
│   │   │   │ 3. Credential injection (no password shared) │ │     │  │
│   │   │   │ 4. Session recording (video + keystrokes)    │ │     │  │
│   │   │   │ 5. Command filtering (block dangerous cmds)  │ │     │  │
│   │   │   │ 6. Time-limited access (auto-disconnect)     │ │     │  │
│   │   │   └──────────────────────────────────────────────┘ │     │  │
│   │   └───────────────────────┬────────────────────────────┘     │  │
│   └───────────────────────────┼──────────────────────────────────┘  │
│                               │                                      │
│                               │ Proxied connection                   │
│                               ▼                                      │
│   ┌──────────────────────────────────────────────────────────────┐  │
│   │   OT Network                                                 │  │
│   │   ┌────────────┐    ┌────────────┐    ┌────────────┐        │  │
│   │   │   Target   │    │   Target   │    │   Target   │        │  │
│   │   │   PLC      │    │   HMI      │    │   DCS      │        │  │
│   │   └────────────┘    └────────────┘    └────────────┘        │  │
│   └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
│   Vendor never sees actual credentials                               │
│   All activity logged and recorded                                   │
│   Access can be terminated instantly                                 │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Vendor Access Controls

| Control | Implementation |
|---------|----------------|
| **Identity Verification** | Verify vendor identity before granting access |
| **MFA** | Require multi-factor for all vendor sessions |
| **Just-in-Time Access** | Grant access only when needed, revoke after |
| **Approval Workflow** | Require internal approval for vendor sessions |
| **Session Recording** | Record all vendor activity |
| **Credential Injection** | Never share actual credentials with vendors |
| **Command Filtering** | Block dangerous commands |
| **Time Limits** | Auto-terminate sessions after defined period |

## Software Bill of Materials (SBOM)

### Why SBOM Matters

```
┌─────────────────────────────────────────────────────────────────────┐
│                    SBOM for OT Products                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Problem: You don't know what's inside your OT software             │
│                                                                      │
│   Your PLC might include:                                            │
│   • Linux kernel (CVE exposure)                                      │
│   • OpenSSL library (Heartbleed, etc.)                               │
│   • Third-party web server                                           │
│   • Open source components                                           │
│   • Vendor's own code                                                │
│                                                                      │
│   Without SBOM, you can't:                                           │
│   • Know if you're affected by a new CVE                             │
│   • Assess supply chain risks                                        │
│   • Plan for end-of-life components                                  │
│   • Verify software integrity                                        │
│                                                                      │
│   SBOM Contents:                                                     │
│   ───────────────                                                    │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │  Component         │ Version │ License │ Supplier          │   │
│   ├─────────────────────────────────────────────────────────────┤   │
│   │  Linux Kernel      │ 4.19.2  │ GPL     │ kernel.org        │   │
│   │  OpenSSL           │ 1.1.1k  │ Apache  │ openssl.org       │   │
│   │  BusyBox           │ 1.31.0  │ GPL     │ busybox.net       │   │
│   │  Vendor App        │ 3.2.1   │ Propri. │ Vendor Inc        │   │
│   │  Custom Library    │ 1.0.0   │ Propri. │ Vendor Inc        │   │
│   └─────────────────────────────────────────────────────────────┘   │
│                                                                      │
│   Request SBOM from all OT product vendors                           │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Patch and Update Verification

### Secure Update Process

```
┌─────────────────────────────────────────────────────────────────────┐
│                    OT Software Update Verification                   │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   BEFORE INSTALLING ANY VENDOR UPDATE:                               │
│                                                                      │
│   1. Verify Authenticity                                             │
│      ────────────────────                                            │
│      [ ] Download from official vendor source only                   │
│      [ ] Verify digital signature                                    │
│      [ ] Check hash against vendor-published value                   │
│      [ ] Verify signing certificate validity                         │
│                                                                      │
│   2. Review Release Notes                                            │
│      ──────────────────────                                          │
│      [ ] Understand what changes are included                        │
│      [ ] Review security fixes addressed                             │
│      [ ] Check compatibility with your configuration                 │
│      [ ] Identify any new features or changes                        │
│                                                                      │
│   3. Test Before Production                                          │
│      ────────────────────────                                        │
│      [ ] Test in isolated environment                                │
│      [ ] Verify functionality                                        │
│      [ ] Test rollback procedure                                     │
│      [ ] Document test results                                       │
│                                                                      │
│   4. Plan Deployment                                                 │
│      ─────────────────                                               │
│      [ ] Schedule during maintenance window                          │
│      [ ] Have rollback plan ready                                    │
│      [ ] Notify operations                                           │
│      [ ] Prepare for extended testing post-install                   │
│                                                                      │
│   5. Post-Installation                                               │
│      ─────────────────                                               │
│      [ ] Verify successful installation                              │
│      [ ] Test critical functions                                     │
│      [ ] Monitor for anomalies                                       │
│      [ ] Document completion                                         │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Ongoing Vendor Management

### Continuous Monitoring

| Activity | Frequency | Purpose |
|----------|-----------|---------|
| **Access Review** | Monthly | Verify only authorized vendors have access |
| **Credential Rotation** | Per session | Minimize credential exposure |
| **Session Audit** | Weekly | Review vendor activity |
| **Contract Review** | Annually | Update security requirements |
| **Security Assessment** | Annually | Verify vendor security posture |
| **SBOM Review** | Per release | Track component changes |

### Vendor Incident Response

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Vendor-Related Incident Procedure                 │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   If Vendor Compromise is Suspected:                                 │
│   ────────────────────────────────                                   │
│                                                                      │
│   IMMEDIATE (< 1 hour):                                              │
│   • Revoke all vendor access immediately                             │
│   • Disable vendor VPN accounts                                      │
│   • Block vendor IP ranges at firewall                               │
│   • Notify vendor security contact                                   │
│                                                                      │
│   SHORT-TERM (< 24 hours):                                           │
│   • Review all recent vendor sessions                                │
│   • Check for unauthorized changes                                   │
│   • Verify system integrity (compare to baseline)                    │
│   • Assess scope of potential exposure                               │
│                                                                      │
│   INVESTIGATION:                                                     │
│   • Request vendor incident report                                   │
│   • Coordinate forensic investigation                                │
│   • Document timeline and impact                                     │
│   • Report to regulators if required                                 │
│                                                                      │
│   RECOVERY:                                                          │
│   • Require security improvements before re-enabling                 │
│   • Implement additional monitoring                                  │
│   • Update contracts if needed                                       │
│   • Consider alternative vendors                                     │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Key Takeaways

1. **Vendors are attack vectors** - treat them as potential threats
2. **Assess before engaging** - vet vendor security upfront
3. **Contract security** - include security requirements contractually
4. **Control access** - PAM for all vendor connections
5. **Monitor activity** - log and review vendor sessions
6. **Verify updates** - authenticate all software before installing
7. **Plan for incidents** - have vendor-specific response procedures

## Study Questions

1. Why is vendor remote access a higher risk in OT than IT?

2. What security controls would you require before allowing a vendor to remotely access a safety system?

3. How does SBOM help with vulnerability management?

4. What should be included in a vendor security assessment?

5. How would you respond if a critical vendor was compromised?

## Practical Exercise

A DCS vendor needs remote access to troubleshoot a critical system:
1. What questions would you ask before granting access?
2. Design the access architecture
3. Define the approval workflow
4. Specify monitoring requirements
5. Create vendor access policy

## Next Steps

Continue to [13-ot-security-career.md](13-ot-security-career.md) to learn about building your OT security career.

## References

- NERC CIP-013: Supply Chain Risk Management
- NIST SP 800-161: Supply Chain Risk Management
- IEC 62443-2-4: Security for Service Providers
- CISA: Supply Chain Best Practices
- NTIA SBOM Resources: https://www.ntia.gov/sbom
