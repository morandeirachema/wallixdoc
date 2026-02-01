# OT Security Resources

Comprehensive collection of learning materials, tools, and community resources.

## Essential Reading

### Books

| Title | Author | Focus | Level |
|-------|--------|-------|-------|
| **Industrial Network Security** | Eric D. Knapp, Joel Thomas Langill | Comprehensive | Beginner-Intermediate |
| **Hacking Exposed Industrial Control Systems** | Clint Bodungen et al. | Offensive security | Intermediate |
| **Countdown to Zero Day** | Kim Zetter | Stuxnet story | All levels |
| **Sandworm** | Andy Greenberg | Russian cyber warfare | All levels |
| **Applied Cyber Security for Smart Grid** | Wei Wang et al. | Power grid focus | Advanced |
| **Practical Industrial Cybersecurity** | Charles J. Brooks et al. | Hands-on | Intermediate |

### Standards and Guidelines

| Document | Source | Focus |
|----------|--------|-------|
| **NIST SP 800-82 Rev 2** | NIST | ICS security guide |
| **IEC 62443 Series** | IEC/ISA | Industrial security standard |
| **NERC CIP Standards** | NERC | Electric utility requirements |
| **CISA ICS Advisories** | CISA | Vulnerability alerts |

### Free Publications

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Free Essential Documents                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   NIST:                                                              │
│   • SP 800-82 Rev 2: Guide to ICS Security                           │
│     https://csrc.nist.gov/publications/detail/sp/800-82/rev-2/final  │
│   • Cybersecurity Framework                                          │
│     https://www.nist.gov/cyberframework                              │
│                                                                      │
│   CISA:                                                              │
│   • ICS-CERT Recommended Practices                                   │
│     https://www.cisa.gov/ics-recommended-practices                   │
│   • Assessments and Technical Assistance                             │
│     https://www.cisa.gov/resources-tools/services/                   │
│                                                                      │
│   SANS:                                                              │
│   • ICS Reading Room Papers                                          │
│     https://www.sans.org/white-papers/                               │
│   • ICS Poster Series                                                │
│     https://www.sans.org/security-resources/posters/                 │
│                                                                      │
│   Vendor Resources:                                                  │
│   • Dragos Year in Review (annual)                                   │
│     https://www.dragos.com/year-in-review/                           │
│   • Claroty State of ICS Security                                    │
│     https://claroty.com/resources/                                   │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Online Training

### Paid Training

| Provider | Course | Cost | Notes |
|----------|--------|------|-------|
| **SANS** | ICS410: ICS Security Essentials | ~$8,500 | Industry standard |
| **SANS** | ICS515: ICS Active Defense | ~$8,500 | Advanced |
| **SANS** | ICS456: Essentials for NERC CIP | ~$8,500 | Compliance focus |
| **ISA** | IC32-34, IC37: IEC 62443 | ~$2,000 | Standards focus |
| **Dragos** | ICS Fundamentals | Varies | Practitioner focus |

### Free Training

| Provider | Content | URL |
|----------|---------|-----|
| **CISA** | ICS Training | https://www.cisa.gov/ics-training |
| **Cybrary** | ICS Security | https://www.cybrary.it/ |
| **EdX** | Industrial Cybersecurity | https://www.edx.org/ |
| **YouTube** | SANS ICS Summit recordings | Search "SANS ICS Summit" |

## Tools

### Network Analysis

```
┌─────────────────────────────────────────────────────────────────────┐
│                    OT Network Analysis Tools                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Packet Capture/Analysis:                                           │
│   ─────────────────────────                                          │
│   • Wireshark - Protocol analyzer with OT dissectors                 │
│     https://www.wireshark.org/                                       │
│   • Zeek (Bro) - Network monitoring framework                        │
│     https://zeek.org/                                                │
│   • tcpdump - Command line capture                                   │
│                                                                      │
│   OT-Specific:                                                       │
│   ────────────                                                       │
│   • Redpoint (Nmap scripts for ICS)                                  │
│     https://github.com/digitalbond/Redpoint                          │
│   • Grassmarlin - Passive OT mapper                                  │
│     https://github.com/nsacyber/GRASSMARLIN                          │
│   • ICSSPLOIT - ICS exploitation framework                           │
│     https://github.com/dark-lbp/isf                                  │
│                                                                      │
│   Network Mapping:                                                   │
│   ────────────────                                                   │
│   • Nmap with ICS scripts                                            │
│   • MASSCAN - Fast port scanner                                      │
│   • Shodan CLI - Internet-exposed ICS                                │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Protocol Tools

| Protocol | Tools |
|----------|-------|
| **Modbus** | ModbusPal, QModMaster, pymodbus |
| **DNP3** | OpenDNP3, Triangle MicroWorks |
| **OPC UA** | Prosys OPC UA Client, UaExpert |
| **EtherNet/IP** | pycomm3, EDS files |
| **S7comm** | Snap7, python-snap7 |
| **BACnet** | YABE, BACnet4j |

### Simulators and Emulators

```
┌─────────────────────────────────────────────────────────────────────┐
│                    ICS Simulators                                    │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   PLC/Controller:                                                    │
│   ───────────────                                                    │
│   • OpenPLC - Open source PLC runtime                                │
│     https://www.openplcproject.com/                                  │
│   • Codesys Development System - PLC IDE with simulator              │
│     https://www.codesys.com/                                         │
│   • Click PLC Simulator - Automation Direct                          │
│     https://www.automationdirect.com/                                │
│                                                                      │
│   SCADA/HMI:                                                         │
│   ──────────                                                         │
│   • ScadaBR - Open source SCADA                                      │
│     https://www.scadabr.com.br/                                      │
│   • Ignition Trial - 2-hour reset                                    │
│     https://inductiveautomation.com/                                 │
│   • Rapid SCADA - Open source                                        │
│     https://rapidscada.org/                                          │
│                                                                      │
│   Complete Environments:                                             │
│   ───────────────────────                                            │
│   • GRFICSv2 - Virtual ICS environment                               │
│     https://github.com/Fortiphyd/GRFICSv2                            │
│   • SWaT/WADI Datasets - Research datasets                           │
│     https://itrust.sutd.edu.sg/                                      │
│   • DVCP - Damn Vulnerable Chemical Process                          │
│     https://github.com/satejnik/DVCP                                 │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Security Tools

| Category | Tools |
|----------|-------|
| **IDS/IPS** | Snort, Suricata (with ET ICS rules) |
| **Asset Discovery** | Nmap, Grassmarlin, Tenable.ot |
| **Vulnerability** | CSET, Nessus (careful in OT!) |
| **SIEM** | Splunk, Elastic, QRadar |
| **OT-Specific** | Dragos, Claroty, Nozomi Networks |

## Communities

### Online Communities

```
┌─────────────────────────────────────────────────────────────────────┐
│                    OT Security Communities                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Slack:                                                             │
│   ──────                                                             │
│   • ICS-Security Slack                                               │
│     Join request: ics-security.slack.com                             │
│                                                                      │
│   Reddit:                                                            │
│   ───────                                                            │
│   • r/ICS - Industrial Control Systems                               │
│   • r/netsec - General security                                      │
│   • r/cybersecurity - Broad community                                │
│                                                                      │
│   Twitter/X:                                                         │
│   ──────────                                                         │
│   Key accounts to follow:                                            │
│   • @RobertMLee - Dragos CEO                                         │
│   • @ICS_Village - DEF CON ICS Village                               │
│   • @SCADAhacker - Research community                                │
│   • @DragosInc - Threat intelligence                                 │
│   • @Claraboratory - Claroty research                                │
│   • @ICS_CERT - CISA ICS-CERT                                        │
│                                                                      │
│   LinkedIn:                                                          │
│   ─────────                                                          │
│   Groups:                                                            │
│   • Industrial Control System (ICS) Cyber Security                   │
│   • SCADA/ICS Security Professionals                                 │
│   • OT Cybersecurity Professionals                                   │
│                                                                      │
│   Discord:                                                           │
│   ────────                                                           │
│   • Various security servers with ICS channels                       │
│   • Search for "ICS security" or "OT security"                       │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Conferences

| Conference | Location | Focus | Website |
|------------|----------|-------|---------|
| **S4 Conference** | Miami, US | ICS security innovation | https://s4xevents.com/ |
| **SANS ICS Summit** | Various | Training + networking | https://www.sans.org/ics/ |
| **SecurityWeek ICS** | Atlanta, US | Industry focus | https://www.securityweek.com/ |
| **DEF CON ICS Village** | Las Vegas, US | Hands-on, CTF | https://www.icsvillage.com/ |
| **44CON** | London, UK | European community | https://44con.com/ |
| **Hack The Capitol** | DC, US | Policy focus | https://hackthecapitol.org/ |

### ISACs (Information Sharing and Analysis Centers)

| ISAC | Sector | URL |
|------|--------|-----|
| **E-ISAC** | Electricity | https://www.eisac.com/ |
| **WaterISAC** | Water/Wastewater | https://www.waterisac.org/ |
| **ONG-ISAC** | Oil & Gas | https://www.ongisac.org/ |
| **MFG-ISAC** | Manufacturing | https://mfgisac.org/ |
| **MS-ISAC** | State/Local Gov | https://www.cisecurity.org/ms-isac |

## Threat Intelligence

### Sources

```
┌─────────────────────────────────────────────────────────────────────┐
│                    OT Threat Intelligence Sources                    │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Government:                                                        │
│   ───────────                                                        │
│   • CISA ICS-CERT Advisories                                         │
│     https://www.cisa.gov/ics                                         │
│   • CISA KEV (Known Exploited Vulnerabilities)                       │
│     https://www.cisa.gov/known-exploited-vulnerabilities-catalog     │
│                                                                      │
│   Vendors:                                                           │
│   ────────                                                           │
│   • Dragos Threat Intelligence                                       │
│     https://www.dragos.com/threat/                                   │
│   • Claroty Team82 Research                                          │
│     https://claroty.com/team82/                                      │
│   • Nozomi Networks Labs                                             │
│     https://www.nozominetworks.com/labs/                             │
│   • Mandiant Threat Research                                         │
│     https://www.mandiant.com/resources                               │
│                                                                      │
│   Open Source:                                                       │
│   ────────────                                                       │
│   • MITRE ATT&CK for ICS                                             │
│     https://attack.mitre.org/techniques/ics/                         │
│   • CVE Details (filter ICS vendors)                                 │
│     https://www.cvedetails.com/                                      │
│   • Exploit Database                                                 │
│     https://www.exploit-db.com/                                      │
│                                                                      │
│   Mailing Lists:                                                     │
│   ──────────────                                                     │
│   • SCADA Hacker (free newsletter)                                   │
│   • Dale Peterson's Unfetter (S4 news)                               │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Vendor Documentation

### Major Control System Vendors

| Vendor | Security Resources |
|--------|-------------------|
| **Siemens** | https://www.siemens.com/global/en/products/services/cert.html |
| **Rockwell** | https://www.rockwellautomation.com/en-us/company/about-us/security.html |
| **Schneider** | https://www.se.com/ww/en/work/support/cybersecurity/ |
| **ABB** | https://new.abb.com/about/technology/cyber-security |
| **Honeywell** | https://process.honeywell.com/us/en/services/cybersecurity |
| **GE** | https://www.ge.com/digital/applications/cybersecurity |

## Research and Academia

### Research Labs

| Lab | Institution | Focus |
|-----|-------------|-------|
| **INL** | Idaho National Lab | CCE, critical infrastructure |
| **PNNL** | Pacific Northwest NL | Grid security |
| **Sandia** | Sandia National Labs | Energy security |
| **SUTD iTrust** | Singapore | Testbed datasets |
| **CERT** | CMU | Vulnerability research |

### Academic Papers

Key conferences for ICS security research:
- ACSAC (Annual Computer Security Applications Conference)
- IEEE S&P (Security and Privacy)
- USENIX Security
- ACM CCS (Computer and Communications Security)

## Quick Reference Cards

### Protocol Ports

| Protocol | Port | Notes |
|----------|------|-------|
| Modbus TCP | 502 | Unencrypted |
| DNP3 | 20000 | SCADA |
| EtherNet/IP | 44818/2222 | TCP/UDP |
| OPC UA | 4840 | Secure by design |
| S7comm | 102 | Siemens |
| BACnet/IP | 47808 | Building automation |
| Niagara Fox | 1911 | Building automation |
| IEC 60870-5-104 | 2404 | Power SCADA |
| IEC 61850 MMS | 102 | Substation |

### Common Vulnerabilities

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Top OT Vulnerability Categories                   │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   1. Improper Input Validation                                       │
│      • Buffer overflows                                              │
│      • Command injection                                             │
│      • Path traversal                                                │
│                                                                      │
│   2. Improper Authentication                                         │
│      • Default credentials                                           │
│      • Hardcoded passwords                                           │
│      • Missing authentication                                        │
│                                                                      │
│   3. Improper Access Control                                         │
│      • Privilege escalation                                          │
│      • Insecure direct object reference                              │
│                                                                      │
│   4. Cryptographic Issues                                            │
│      • Cleartext transmission                                        │
│      • Weak algorithms                                               │
│      • Improper certificate validation                               │
│                                                                      │
│   5. Protocol Weaknesses                                             │
│      • No authentication (Modbus)                                    │
│      • Replay attacks                                                │
│      • Man-in-the-middle                                             │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Glossary

| Term | Definition |
|------|------------|
| **BES** | Bulk Electric System |
| **BPCS** | Basic Process Control System |
| **CIP** | Critical Infrastructure Protection (or Common Industrial Protocol) |
| **DCS** | Distributed Control System |
| **DMZ** | Demilitarized Zone |
| **ESD** | Emergency Shutdown |
| **HMI** | Human-Machine Interface |
| **IACS** | Industrial Automation and Control Systems |
| **ICS** | Industrial Control System |
| **IED** | Intelligent Electronic Device |
| **OPC** | Open Platform Communications |
| **OT** | Operational Technology |
| **PLC** | Programmable Logic Controller |
| **RTU** | Remote Terminal Unit |
| **SCADA** | Supervisory Control and Data Acquisition |
| **SIS** | Safety Instrumented System |
| **SL** | Security Level |

## Feedback and Updates

This guide is a living document. For updates, corrections, or contributions:

- Latest version in repository
- Community feedback welcome
- Annual review for currency

---

**Congratulations!**

You've completed the OT Security Fundamentals guide. You now have the foundational knowledge to:

- Understand OT environments and their unique challenges
- Identify and analyze threats to industrial systems
- Design and implement security controls
- Respond to incidents safely
- Continue your OT security career

**Next Steps:**
1. Build your home lab
2. Pursue GICSP certification
3. Join the OT security community
4. Apply knowledge in real environments

Good luck on your OT security journey!
