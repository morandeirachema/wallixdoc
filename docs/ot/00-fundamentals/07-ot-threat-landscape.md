# OT Threat Landscape

Understanding the adversaries, attacks, and malware targeting industrial systems.

## Threat Actor Categories

### Who Targets OT?

```
┌─────────────────────────────────────────────────────────────────────┐
│                    OT Threat Actor Spectrum                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Sophistication                                                     │
│        ▲                                                             │
│        │   ┌─────────────────────────────────────────────────────┐  │
│   HIGH │   │           NATION-STATE ACTORS                       │  │
│        │   │   • Stuxnet (US/Israel vs Iran)                     │  │
│        │   │   • Industroyer/CrashOverride (Russia vs Ukraine)   │  │
│        │   │   • Triton/Trisis (Unknown vs Saudi Arabia)         │  │
│        │   │   Goals: Sabotage, intelligence, war preparation    │  │
│        │   └─────────────────────────────────────────────────────┘  │
│        │   ┌─────────────────────────────────────────────────────┐  │
│   MED  │   │           CYBERCRIME / RANSOMWARE                   │  │
│        │   │   • Colonial Pipeline (DarkSide)                    │  │
│        │   │   • JBS Foods (REvil)                               │  │
│        │   │   • Norsk Hydro (LockerGoga)                        │  │
│        │   │   Goals: Financial extortion                        │  │
│        │   └─────────────────────────────────────────────────────┘  │
│        │   ┌─────────────────────────────────────────────────────┐  │
│   LOW  │   │           HACKTIVISTS / SCRIPT KIDDIES              │  │
│        │   │   • Website defacement, DDoS                        │  │
│        │   │   • Shodan-based opportunistic attacks              │  │
│        │   │   Goals: Notoriety, political statement             │  │
│        │   └─────────────────────────────────────────────────────┘  │
│        │   ┌─────────────────────────────────────────────────────┐  │
│        │   │           INSIDERS                                  │  │
│        │   │   • Disgruntled employees                           │  │
│        │   │   • Contractors with access                         │  │
│        │   │   • Unintentional mistakes                          │  │
│        │   │   Goals: Revenge, financial, accidental             │  │
│        │   └─────────────────────────────────────────────────────┘  │
│        └─────────────────────────────────────────────────────────►  │
│                                                                      │
│                          Impact Potential                            │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Nation-State Groups Targeting OT

| Group | Attribution | Targets | Known Campaigns |
|-------|-------------|---------|-----------------|
| **SANDWORM** | Russia (GRU) | Ukraine, US, Europe | Industroyer, NotPetya |
| **XENOTIME** | Unknown (possibly Russia) | Oil & Gas, Safety Systems | Triton/Trisis |
| **MAGNALLIUM** | Iran | Oil & Gas, Aerospace | Multiple campaigns |
| **COVELLITE** | North Korea | Energy, Crypto | Various |
| **Equation Group** | US (NSA) | Various | Stuxnet collaboration |

## Historical OT Attacks

### Timeline of Major Incidents

```
┌─────────────────────────────────────────────────────────────────────┐
│                    OT Attack Timeline                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   2010 ─── STUXNET                                                   │
│            First known cyber weapon targeting OT                     │
│            Destroyed Iranian centrifuges                             │
│            Used 4 zero-days, Siemens S7-300 targeting               │
│                                                                      │
│   2014 ─── German Steel Mill                                         │
│            Attackers caused physical damage to blast furnace         │
│            Spear-phishing led to plant network access               │
│                                                                      │
│   2015 ─── Ukraine Power Grid (December 23)                          │
│            BlackEnergy malware + manual SCADA takeover               │
│            225,000 customers without power                           │
│            First confirmed cyberattack causing power outage          │
│                                                                      │
│   2016 ─── Ukraine Power Grid (December 17)                          │
│            Industroyer/CrashOverride malware                         │
│            Automated attack against substation                       │
│            IEC 61850/104 protocol exploitation                       │
│                                                                      │
│   2017 ─── TRITON/TRISIS                                             │
│            Safety Instrumented System (Triconex) targeted            │
│            Intent: Disable safety and cause physical damage          │
│            Discovered before causing harm                            │
│                                                                      │
│   2017 ─── NotPetya                                                  │
│            Maersk: $300M loss, Merck: $870M loss                     │
│            Spread via Ukrainian tax software                         │
│            Destroyed OT systems collaterally                         │
│                                                                      │
│   2019 ─── Norsk Hydro (LockerGoga)                                  │
│            Aluminum production halted globally                       │
│            $70M+ in damages                                          │
│            40,000 employees affected                                 │
│                                                                      │
│   2021 ─── Colonial Pipeline                                         │
│            Largest US fuel pipeline shut down 6 days                 │
│            Ransomware on IT side → OT shutdown as precaution        │
│            $4.4M ransom paid                                         │
│                                                                      │
│   2021 ─── JBS Foods                                                 │
│            World's largest meat processor                            │
│            Plants shut down globally                                 │
│            $11M ransom paid                                          │
│                                                                      │
│   2021 ─── Oldsmar Water Treatment                                   │
│            Attacker increased sodium hydroxide (lye) 100x            │
│            Operator noticed and reverted                             │
│            TeamViewer remote access exploited                        │
│                                                                      │
│   2022 ─── Industroyer2 (Ukraine)                                    │
│            Updated Industroyer targeting Ukrainian grid              │
│            Disrupted during Russian invasion                         │
│            Detected and mitigated before major impact                │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## ICS-Specific Malware

### Malware Families

| Malware | Year | Target | Capability |
|---------|------|--------|------------|
| **Stuxnet** | 2010 | Siemens S7-300 | PLC logic modification |
| **Havex** | 2014 | OPC servers | Reconnaissance |
| **BlackEnergy** | 2015 | HMI/SCADA | Backdoor, KillDisk |
| **Industroyer** | 2016 | Power grid | Protocol exploitation |
| **Triton/Trisis** | 2017 | Triconex SIS | Safety system attack |
| **VPNFilter** | 2018 | Network devices | Persistence, Modbus sniffing |
| **Industroyer2** | 2022 | Power grid | Updated grid attack |
| **Pipedream/Incontroller** | 2022 | Various PLCs | Modular ICS toolkit |

### Stuxnet Deep Dive

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Stuxnet Architecture                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Infection Chain:                                                   │
│   ─────────────────                                                  │
│   USB ──► Windows (4 zero-days) ──► STEP 7 Project ──► S7-300 PLC   │
│                                                                      │
│   Target Identification:                                             │
│   ──────────────────────                                             │
│   • Checked for specific Siemens software                            │
│   • Looked for specific PLC configuration                            │
│   • Identified VFD models (Vacon, Fararo Paya)                       │
│   • Verified centrifuge cascade configuration                        │
│                                                                      │
│   Attack Payload:                                                    │
│   ───────────────                                                    │
│   1. Record normal frequency values                                  │
│   2. Replay "normal" to monitoring                                   │
│   3. Modify VFD frequency commands                                   │
│   4. Cause centrifuge damage through overspeed/underspeed            │
│                                                                      │
│   Key Innovations:                                                   │
│   ────────────────                                                   │
│   • First known PLC rootkit                                          │
│   • Replay attack to hide malicious activity                         │
│   • Air-gap crossing via USB                                         │
│   • Highly targeted (only specific configuration)                    │
│                                                                      │
│   Lessons:                                                           │
│   ────────                                                           │
│   • Air-gap is not absolute security                                 │
│   • USB is a major attack vector                                     │
│   • Supply chain attacks are viable                                  │
│   • Nation-states invest heavily in OT capabilities                  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Triton/Trisis Deep Dive

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Triton Attack Architecture                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   TRITON targeted Safety Instrumented Systems (SIS)                  │
│                                                                      │
│   Attack Chain:                                                      │
│   ─────────────                                                      │
│   1. Initial compromise of corporate network                         │
│   2. Lateral movement to OT network                                  │
│   3. Access to engineering workstation                               │
│   4. Reverse engineering of Triconex SIS protocol                    │
│   5. Malicious code uploaded to safety controllers                   │
│                                                                      │
│   Intent:                                                            │
│   ───────                                                            │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │  Disable Safety System                                      │   │
│   │         ▼                                                   │   │
│   │  Cause Dangerous Condition (via separate attack)            │   │
│   │         ▼                                                   │   │
│   │  Safety System Fails to Respond                             │   │
│   │         ▼                                                   │   │
│   │  Physical Destruction / Casualties                          │   │
│   └─────────────────────────────────────────────────────────────┘   │
│                                                                      │
│   Why This Matters:                                                  │
│   ─────────────────                                                  │
│   • First malware specifically targeting safety systems              │
│   • Demonstrates intent to cause physical harm                       │
│   • Shows sophisticated understanding of process safety              │
│   • Safety systems previously considered untouchable                 │
│                                                                      │
│   Detection:                                                         │
│   ──────────                                                         │
│   • Discovered because malware crashed the safety system             │
│   • Caused plant trip (safety shutdown)                              │
│   • Investigation revealed the malware                               │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Attack Techniques

### MITRE ATT&CK for ICS

Key techniques specific to OT environments:

| Tactic | Techniques | OT Impact |
|--------|------------|-----------|
| **Initial Access** | Spear-phishing, Supply Chain, Remote Services | Entry to OT network |
| **Execution** | Scripting, Native API, Change Program State | Malicious code runs |
| **Persistence** | Modify Controller, Module Firmware | Survives reboot |
| **Evasion** | Masquerading, Rootkit, Spoof Reporting | Hides activity |
| **Discovery** | Network Sniffing, Remote System Discovery | Maps environment |
| **Lateral Movement** | Default Credentials, Exploitation | Spreads in network |
| **Collection** | Point & Tag Identification, Screen Capture | Gathers intelligence |
| **Command & Control** | Standard Protocol, Connection Proxy | Maintains access |
| **Inhibit Response** | Alarm Suppression, Device Restart | Prevents detection |
| **Impair Process** | Modify Parameter, Unauthorized Command | Physical impact |
| **Impact** | Damage to Property, Denial of Service, Loss of Safety | Physical harm |

### Common Attack Vectors

```
┌─────────────────────────────────────────────────────────────────────┐
│                    OT Attack Vectors                                 │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   1. IT Network Compromise → Lateral Movement                        │
│      ────────────────────────────────────────                        │
│      Corporate phishing → Domain compromise → OT DMZ → OT            │
│      Most common path for ransomware                                 │
│                                                                      │
│   2. Remote Access Exploitation                                      │
│      ─────────────────────────────                                   │
│      VPN vulnerabilities, exposed RDP, vendor backdoors              │
│      Example: Oldsmar water treatment (TeamViewer)                   │
│                                                                      │
│   3. Supply Chain                                                    │
│      ────────────                                                    │
│      Compromised vendor software, infected firmware                  │
│      Example: SolarWinds, Codecov                                    │
│                                                                      │
│   4. Removable Media                                                 │
│      ────────────────                                                │
│      USB drives carrying malware across air-gaps                     │
│      Example: Stuxnet                                                │
│                                                                      │
│   5. Direct Internet Exposure                                        │
│      ─────────────────────────                                       │
│      Misconfigured firewalls, cloud-connected OT                     │
│      Shodan reveals thousands of exposed PLCs                        │
│                                                                      │
│   6. Insider Threat                                                  │
│      ──────────────                                                  │
│      Disgruntled employees, compromised credentials                  │
│      Hardest to detect, most access                                  │
│                                                                      │
│   7. Wireless Networks                                               │
│      ─────────────────                                               │
│      Rogue access points, weak encryption, RF attacks                │
│      Plant WiFi often poorly segmented                               │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Ransomware in OT Environments

### Why Ransomware Hits OT

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Ransomware Impact on OT                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Attack Pattern:                                                    │
│   ───────────────                                                    │
│   1. Initial compromise (IT network)                                 │
│   2. Reconnaissance (identify high-value targets)                    │
│   3. Privilege escalation (domain admin)                             │
│   4. Lateral movement (including to OT if connected)                 │
│   5. Data exfiltration (double extortion)                            │
│   6. Encryption deployment                                           │
│                                                                      │
│   OT Impact Scenarios:                                               │
│   ────────────────────                                               │
│                                                                      │
│   Scenario A: Direct OT Encryption                                   │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │  Ransomware encrypts:                                       │   │
│   │  • HMI workstations                                         │   │
│   │  • SCADA servers                                            │   │
│   │  • Engineering workstations                                 │   │
│   │  • Historian databases                                      │   │
│   │                                                             │   │
│   │  Result: Operators cannot see or control process            │   │
│   │  Decision: Manual operation or shutdown                     │   │
│   └─────────────────────────────────────────────────────────────┘   │
│                                                                      │
│   Scenario B: IT Dependency                                          │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │  IT systems encrypted:                                      │   │
│   │  • ERP (no production orders)                               │   │
│   │  • Logistics (no shipping)                                  │   │
│   │  • Quality systems (no release)                             │   │
│   │                                                             │   │
│   │  Result: OT running but useless without IT                  │   │
│   │  Decision: Shut down OT to prevent waste                    │   │
│   └─────────────────────────────────────────────────────────────┘   │
│                                                                      │
│   Scenario C: Precautionary Shutdown (Colonial Pipeline)             │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │  IT compromised, OT integrity unknown                       │   │
│   │                                                             │   │
│   │  Decision: Shut down OT out of abundance of caution         │   │
│   │  Rationale: Cannot risk compromised billing/metering        │   │
│   │             Cannot verify OT wasn't touched                 │   │
│   └─────────────────────────────────────────────────────────────┘   │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Ransomware Groups Targeting Industrial

| Group | Notable OT Victims | Status |
|-------|-------------------|--------|
| **DarkSide** | Colonial Pipeline | Disbanded (2021) |
| **REvil/Sodinokibi** | JBS Foods | Disrupted (2022) |
| **LockerGoga** | Norsk Hydro, Altran | Active |
| **Ryuk/Conti** | Multiple hospitals, manufacturing | Rebranded |
| **ALPHV/BlackCat** | Various industrial | Active |
| **LockBit** | Multiple manufacturing | Active |

## Emerging Threats

### Threats to Watch

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Emerging OT Threat Trends                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   1. ICS-Specific Ransomware                                         │
│      ────────────────────────                                        │
│      Ransomware that directly targets industrial protocols           │
│      Example: EKANS/Snake ransomware kills ICS processes             │
│                                                                      │
│   2. Cloud-Connected OT Attacks                                      │
│      ───────────────────────────                                     │
│      As OT moves to cloud, new attack surface                        │
│      Cloud misconfigurations exposing OT                             │
│                                                                      │
│   3. AI-Enhanced Attacks                                             │
│      ───────────────────────                                         │
│      Automated vulnerability discovery                               │
│      Intelligent evasion of detection                                │
│                                                                      │
│   4. Living-off-the-Land in OT                                       │
│      ──────────────────────────                                      │
│      Using legitimate OT tools (PLC programming software)            │
│      Harder to detect than malware                                   │
│                                                                      │
│   5. Supply Chain Targeting                                          │
│      ─────────────────────────                                       │
│      Compromising vendors that supply many targets                   │
│      Engineering tool providers, firmware updates                    │
│                                                                      │
│   6. Hacktivist OT Attacks                                           │
│      ─────────────────────────                                       │
│      Politically motivated groups targeting infrastructure           │
│      Often less sophisticated but still disruptive                   │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Threat Intelligence Sources

### Where to Get OT Threat Intelligence

| Source | Type | Access |
|--------|------|--------|
| **CISA ICS-CERT** | Advisories, alerts | Free - https://www.cisa.gov/ics |
| **Dragos** | Reports, blog | Free/paid - https://www.dragos.com |
| **Claroty** | Research, blog | Free - https://claroty.com/team82 |
| **SANS ICS** | Summits, courses | Mixed - https://www.sans.org/ics |
| **Nozomi Networks** | Blog, reports | Free - https://www.nozominetworks.com |
| **Mandiant** | Threat reports | Free/paid - https://www.mandiant.com |
| **ISACs** | Sector-specific | Membership - Various |

### Information Sharing Organizations

| Organization | Sector | Focus |
|--------------|--------|-------|
| **E-ISAC** | Energy | Electric utilities |
| **WaterISAC** | Water | Water/wastewater |
| **ONG-ISAC** | Oil & Gas | Upstream, midstream, downstream |
| **MS-ISAC** | Public Sector | State/local government |
| **MFG-ISAC** | Manufacturing | Discrete and process |

## Key Takeaways

1. **Nation-states are active** - OT is a legitimate military target
2. **Ransomware is primary threat** - even without OT-specific targeting
3. **Safety systems are targets** - Triton proved this
4. **IT/OT convergence increases risk** - connectivity = exposure
5. **Legacy systems are vulnerable** - Stuxnet targeted 2003 PLCs
6. **Detection is critical** - many attacks are discovered late
7. **Threat intelligence matters** - stay informed about emerging threats

## Study Questions

1. Why did Stuxnet need to replay "normal" readings to monitoring systems?

2. What made Triton/Trisis unique among ICS malware?

3. How did Colonial Pipeline get infected, and why did they shut down OT even though it wasn't directly hit?

4. What is "living off the land" in an OT context?

5. Why are safety systems particularly attractive targets for nation-state actors?

## Practical Exercise

Research and present on one historical OT attack:
- Attack timeline
- Attack chain (initial access → impact)
- Technical details
- Lessons learned
- How it could be prevented today

## Next Steps

Continue to [08-ot-threat-modeling.md](08-ot-threat-modeling.md) to learn how to analyze threats specific to your OT environment.

## References

- MITRE ATT&CK for ICS: https://attack.mitre.org/techniques/ics/
- Dragos Year in Review Reports: https://www.dragos.com/year-in-review/
- CISA ICS-CERT Advisories: https://www.cisa.gov/ics
- Stuxnet: A Breakdown (Langner): https://www.langner.com/
- Triton Analysis (FireEye/Mandiant)
- SANS ICS Reports
