# 65 - RTU and Field Device Access

## Table of Contents

1. [RTU/Field Device Overview](#rtufield-device-overview)
2. [Field Access Architecture](#field-access-architecture)
3. [RTU Types and Access Methods](#rtu-types-and-access-methods)
4. [Remote Access Patterns](#remote-access-patterns)
5. [Connection Management](#connection-management)
6. [Jump Host Placement](#jump-host-placement)
7. [Session Recording](#session-recording)
8. [Emergency Access](#emergency-access)
9. [Vendor/Contractor Access](#vendorcontractor-access)
10. [Security Considerations](#security-considerations)
11. [Compliance](#compliance)
12. [Troubleshooting](#troubleshooting)

---

## RTU/Field Device Overview

Remote Terminal Units (RTUs) and field devices are the distributed intelligence of industrial control systems, operating at geographically dispersed locations with limited connectivity.

For official WALLIX documentation, see: https://pam.wallix.one/documentation

```
+==============================================================================+
|                    RTU AND FIELD DEVICE FUNDAMENTALS                          |
+==============================================================================+

  RTU (Remote Terminal Unit):
  - Microprocessor-based device monitoring/controlling field equipment
  - Communicates with central SCADA systems
  - Operates autonomously when communication is lost
  - Located at substations, pump stations, well pads

  Field Devices: IEDs, flow computers, well controllers, remote PLCs

  +------------------------------------------------------------------------+
  |   GEOGRAPHIC DISTRIBUTION EXAMPLE (Pipeline)                           |
  |                                                                        |
  |   [Central Control]                                                    |
  |         +-------- 50 km --------+-------- 80 km --------+              |
  |         |                       |                       |              |
  |    [Pump Stn 1]           [Pump Stn 2]           [Pump Stn 3]          |
  |      RTU-001                RTU-002                RTU-003             |
  |   Fiber/Microwave         Cellular 4G            Satellite             |
  |   15 ms / 10 Mbps         80 ms / 5 Mbps         600+ ms / 512 Kbps   |
  +------------------------------------------------------------------------+

  ACCESS CHALLENGES
  =================
  +-------------------------+------------------------------------------------+
  | Challenge               | Impact on PAM                                  |
  +-------------------------+------------------------------------------------+
  | Geographic isolation    | Cannot always deploy local infrastructure      |
  | Limited bandwidth       | Session recording must be optimized            |
  | Intermittent connectivity| Must handle disconnections gracefully         |
  | Legacy protocols        | Serial, Modbus RTU, proprietary                |
  | Safety-critical systems | Access must never disrupt operations           |
  +-------------------------+------------------------------------------------+

+==============================================================================+
```

---

## Field Access Architecture

```
+==============================================================================+
|                    FIELD ACCESS ARCHITECTURE                                  |
+==============================================================================+

                         ENTERPRISE ZONE
  +========================================================================+
  |   [Control Room     [Field           [Vendor           [Emergency      |
  |    Operators]        Engineers]       Support]          Response]      |
  +========================================================================+
                                   | HTTPS (443)
  +========================================================================+
  |                         CORPORATE DMZ                                   |
  |   +================================================================+   |
  |   |                  WALLIX ACCESS MANAGER                          |   |
  |   |   * Web portal, MFA, target selection, approval workflows      |   |
  |   +================================================================+   |
  +========================================================================+
                          IT/OT Boundary Firewall
  +========================================================================+
  |                           OT DMZ                                        |
  |   +================================================================+   |
  |   |                  WALLIX BASTION (Central)                       |   |
  |   |   * Session proxy, credential injection, recording, auth       |   |
  |   +===================+================+================+===========+   |
  +========================================================================+
              |                |                |
  +===================+ +===================+ +===================+
  |   REGION NORTH    | |   REGION SOUTH    | |   REGION WEST     |
  | +---------------+ | | +---------------+ | | +---------------+ |
  | | Regional Jump | | | | Regional Jump | | | | Regional Jump | |
  | | Host          | | | | Host          | | | | Host          | |
  | +-------+-------+ | | +-------+-------+ | | +-------+-------+ |
  |    +----+----+    | |    +----+----+    | |    +----+----+    |
  | [RTU-N01] [RTU-N02] | [RTU-S01] [RTU-S02] | [RTU-W01] [RTU-W02] |
  | Fiber/Microwave   | | Cellular 4G/LTE   | | Satellite VSAT    |
  +===================+ +===================+ +===================+

  MULTI-TIER ACCESS MODEL
  =======================
  TIER 1: Central Access - Full recording at central, requires stable WAN
  TIER 2: Regional Access - Recording at regional jump host, synced later
  TIER 3: Local Access (Emergency) - Break-glass credentials, manual logging

+==============================================================================+
```

---

## RTU Types and Access Methods

### DNP3 RTUs

```
+==============================================================================+
|                    DNP3 RTU ACCESS                                            |
+==============================================================================+

  Protocol: IEEE 1815, TCP port 20000 or Serial
  Used by: Electric utilities, water/wastewater, oil & gas pipelines
  Vendors: SEL, ABB, GE, Schneider, Honeywell

  ACCESS ARCHITECTURE
  ===================
  [Engineer] --> [WALLIX] --> [Eng Workstation] --> [DNP3 RTU]
                              (SEL AcSELerator,     (Serial/TCP)
                               ABB MicroSCADA)

  CONFIGURATION
  =============
  wabadmin domain create DNP3-Field-Devices \
    --description "DNP3 RTUs and outstations"

  wabadmin device create DNP3-ENG-WS-01 \
    --domain DNP3-Field-Devices \
    --host 10.100.50.10 \
    --description "DNP3 Engineering Workstation"

  wabadmin authorization create DNP3-Engineers-Access \
    --user-group SCADA-Engineers \
    --target DNP3-ENG-WS-01/RDP/dnp3_engineer \
    --approval-required true \
    --session-recording true \
    --max-session-duration 4h

+==============================================================================+
```

### Modbus RTUs and Serial-over-IP

```
+==============================================================================+
|                    MODBUS RTU ACCESS                                          |
+==============================================================================+

  Variants: Modbus RTU (Serial), Modbus TCP (port 502)
  Used by: Manufacturing, building automation, remote stations, solar/wind

  SERIAL-OVER-IP ARCHITECTURE
  ============================
  [Engineer] --> [WALLIX] --> [Protocol Gateway] --> [Serial Server] --> [RTU]
                              (Linux: socat,         (Moxa, Digi,      (RS-485)
                               ser2net, mbpoll)       Lantronix)

  CONFIGURATION
  =============
  wabadmin device create MODBUS-GATEWAY-01 \
    --domain OT-Field-Devices \
    --host 10.100.60.20 \
    --description "Modbus protocol gateway for serial devices"

  wabadmin authorization create Modbus-Field-Access \
    --user-group Field-Technicians \
    --target MODBUS-GATEWAY-01/SSH/modbus_admin \
    --session-recording true \
    --command-logging true

+==============================================================================+
```

### IEC 61850 IEDs and Flow Computers

```
+==============================================================================+
|                    IEC 61850 IED AND FLOW COMPUTER ACCESS                     |
+==============================================================================+

  IEC 61850 (Substation Automation)
  =================================
  Protocols: MMS (TCP 102), GOOSE (multicast), Sampled Values
  Vendors: ABB, Siemens, GE, Schneider, SEL
  Standard Reference: https://webstore.iec.ch/publication/6028

  IED ACCESS ARCHITECTURE
  =======================

                    UTILITY CONTROL CENTER
       +================================================+
       |   [Protection     [SCADA        [Engineering   |
       |    Engineer]       Operator]     Specialist]   |
       |        +--------------+--------------+         |
       |              +========+========+               |
       |              | WALLIX BASTION  |               |
       |              +=================+               |
       +================================================+
                               |
                          WAN / MPLS
                               |
       +================================================+
       |                  SUBSTATION                     |
       |   +------------------------------------------+ |
       |   |           Station Computer               | |
       |   |  [SEL AcSELerator]  [ABB PCM600]        | |
       |   |  [GE EnerVista]     [Siemens DIGSI]     | |
       |   +--------------------+---------------------+ |
       |           +------------+------------+          |
       |           v            v            v          |
       |   +----------+  +----------+  +----------+    |
       |   | IED      |  | IED      |  | IED      |    |
       |   | (SEL-451)|  | (ABB-670)|  | (GE-D60) |    |
       |   +----------+  +----------+  +----------+    |
       +================================================+

  IED CONFIGURATION
  =================
  wabadmin domain create Substations \
    --description "Electric utility substations"

  wabadmin device create SUB-NORTH-STATION-PC \
    --domain Substations \
    --host 10.200.10.5 \
    --description "Substation North station computer"

  wabadmin authorization create Protection-Engineers-IED-Access \
    --user-group Protection-Engineers \
    --target-group Substation-Computers \
    --approval-required true \
    --session-recording true \
    --time-restriction "MON-FRI 06:00-18:00"

  ---------------------------------------------------------------------------

  FLOW COMPUTERS (Oil & Gas)
  ==========================
  Purpose: Custody transfer calculations, BTU, regulatory reporting
  Vendors: ABB, Emerson, Honeywell, OMNI

  +------------------------------------------------------------------------+
  |   FLOW COMPUTER ACCESS ARCHITECTURE                                    |
  |                                                                        |
  |   [Measurement     --> [WALLIX] --> [Measurement  --> [Flow           |
  |    Technician]                       Workstation]      Computer]       |
  |                                                                        |
  |   Software Required:                                                   |
  |   * ABB TotalFlow                                                      |
  |   * Emerson ROC800 Configuration                                       |
  |   * Honeywell Enraf Configuration                                      |
  +------------------------------------------------------------------------+

  WELL CONTROLLERS
  =================
  Purpose: Artificial lift control, production optimization, safety shutdown
  Vendors: Weatherford, Lufkin, ABB, Schneider
  Connectivity: Often cellular or satellite

  +------------------------------------------------------------------------+
  |   WELL SITE ACCESS ARCHITECTURE                                        |
  |                                                                        |
  |                     [Field Office]                                     |
  |                    +======+======+                                     |
  |                    |   WALLIX    |                                     |
  |                    +=============+                                     |
  |                           |                                            |
  |                      Cellular/Satellite                                |
  |         +-----------------+-----------------+                          |
  |         v                 v                 v                          |
  |   +-----------+     +-----------+     +-----------+                    |
  |   | Well Pad 1|     | Well Pad 2|     | Well Pad 3|                    |
  |   | [Well Ctrl]     | [Well Ctrl]     | [Well Ctrl]                    |
  |   | [RTU]     |     | [RTU]     |     | [RTU]     |                    |
  |   +-----------+     +-----------+     +-----------+                    |
  +------------------------------------------------------------------------+

  wabadmin authorization create Measurement-Tech-Access \
    --user-group Measurement-Technicians \
    --target MEAS-WS-EAST/RDP/measurement_tech \
    --session-recording true \
    --time-restriction "MON-SUN 06:00-22:00"

+==============================================================================+
```

---

## Remote Access Patterns

### VPN/Tunnel Access

```
+==============================================================================+
|                    VPN AND TUNNEL ACCESS                                      |
+==============================================================================+

  SITE-TO-SITE VPN
  =================
  [Corporate Firewall] <===IPsec===> [Field Site Firewall]
         |                                    |
  [WALLIX Bastion]                    [Field RTU]

  WALLIX WITH VPN CONCENTRATOR
  =============================
  [Vendor] --> [SSL VPN] --> [DMZ] --> [WALLIX] --> [Field Devices]
                                          ^
                             ALL sessions must go through WALLIX

  FIREWALL RULES
  ==============
  permit tcp VPN-POOL -> WALLIX-IP:443,22,3389
  deny ip VPN-POOL -> OT-NETWORKS           # Block direct VPN to OT
  permit ip WALLIX-IP -> OT-NETWORKS        # Allow WALLIX to OT

+==============================================================================+
```

### Cellular, Satellite, and Radio Access

```
+==============================================================================+
|                    CELLULAR, SATELLITE, AND RADIO ACCESS                      |
+==============================================================================+

  CELLULAR (4G/LTE/5G)
  ====================
  Latency: 50-150 ms, Bandwidth: 1-50 Mbps
  Considerations: Private APN, static IP or dynamic DNS, failover to satellite

  SATELLITE (VSAT/LEO)
  ====================
  Geostationary: 500-700 ms latency, 128 Kbps-10 Mbps
  LEO (Starlink): 20-40 ms latency

  PRIVATE RADIO
  ==============
  Licensed VHF/UHF: 1200-9600 bps, very reliable
  900 MHz Spread: 115 Kbps-1 Mbps
  5.8 GHz P2P: 10-100+ Mbps, line-of-sight

  HIGH LATENCY CONFIGURATION
  ==========================
  [session]
  ssh_keepalive_interval = 60
  ssh_keepalive_count_max = 10
  rdp_timeout = 300
  session_idle_timeout = 1800

  [proxy]
  enable_compression = true
  tcp_keepalive = true

+==============================================================================+
```

---

## Connection Management

### Low-Bandwidth and Intermittent Connectivity

```
+==============================================================================+
|                    CONNECTION MANAGEMENT                                      |
+==============================================================================+

  BANDWIDTH REQUIREMENTS
  =======================
  +-------------------------+------------------+------------------------------+
  | Access Type             | Min Bandwidth    | Recommended                  |
  +-------------------------+------------------+------------------------------+
  | SSH (with compression)  | 4.8 Kbps         | 19.2 Kbps                    |
  | RDP (low quality)       | 56 Kbps          | 256 Kbps                     |
  | Session recording sync  | Background       | 512 Kbps burst               |
  +-------------------------+------------------+------------------------------+

  BANDWIDTH OPTIMIZATION
  =======================
  wabadmin session-policy create low-bandwidth-rdp \
    --protocol rdp \
    --color-depth 16 \
    --disable-wallpaper true \
    --enable-compression true

  RECONNECTION CONFIGURATION
  ===========================
  [session]
  reconnection_enabled = true
  reconnection_timeout = 300    # 5 minutes to reconnect

  [satellite_mode]
  enabled = true
  reconnection_timeout = 600    # 10 minutes for satellite

  OFFLINE CREDENTIAL CACHING
  ===========================
  Regional jump hosts can cache credentials for disconnected operations:
  - Encrypted with HSM
  - Time-limited validity (24-72 hours)
  - Auto-sync when connected
  - Local audit logging

  wabadmin sync configure \
    --central-server central-wallix.company.com \
    --offline-mode-enabled true \
    --offline-credential-validity 72h

+==============================================================================+
```

---

## Jump Host Placement

```
+==============================================================================+
|                    JUMP HOST PLACEMENT                                        |
+==============================================================================+

  REGIONAL JUMP HOST BENEFITS
  ============================
  +-------------------------+------------------------------------------------+
  | Benefit                 | Description                                    |
  +-------------------------+------------------------------------------------+
  | Reduced latency         | Jump host closer to field devices              |
  | Bandwidth efficiency    | Only auth traffic crosses WAN                  |
  | Resilience              | Local access if WAN fails                      |
  | Recording optimization  | Local recording, background sync               |
  +-------------------------+------------------------------------------------+

  CONFIGURATION
  =============
  wabadmin device create REGION-A-JUMPHOST \
    --domain OT-Regional-Infrastructure \
    --host 10.50.10.5 \
    --description "Regional jump host for Region A"

  wabadmin device configure REGION-A-JUMPHOST \
    --session-relay true \
    --local-recording true \
    --recording-sync-schedule "0 */4 * * *"

  SUBSTATION ACCESS MODEL
  =======================
  [Control Center] --> [WALLIX Central] --> [WAN] --> [Station Computer]
                                                            |
                                            +---------------+---------------+
                                            |               |               |
                                      [Protection     [Control       [Metering
                                       IEDs]           IEDs]          IEDs]

+==============================================================================+
```

---

## Session Recording

```
+==============================================================================+
|                    SESSION RECORDING FOR FIELD ACCESS                         |
+==============================================================================+

  RECORDING STRATEGIES BY BANDWIDTH
  ==================================
  +-------------------------+------------------+------------------------------+
  | Strategy                | Bandwidth Impact | Use Case                     |
  +-------------------------+------------------+------------------------------+
  | Full video recording    | High (100+ Kbps) | High-bandwidth sites         |
  | Reduced frame rate      | Medium (50 Kbps) | Moderate bandwidth           |
  | Keystroke only (SSH)    | Very low (1 Kbps)| Satellite/radio sites        |
  | Metadata only           | Minimal          | Extremely constrained        |
  +-------------------------+------------------+------------------------------+

  RECORDING POLICY CONFIGURATION
  ===============================
  # Standard (high bandwidth)
  wabadmin recording-policy create standard-recording \
    --video-enabled true --video-quality high --frame-rate 15

  # Low bandwidth
  wabadmin recording-policy create low-bandwidth-recording \
    --video-enabled true --video-quality low --frame-rate 2

  # Satellite (keystroke only)
  wabadmin recording-policy create satellite-recording \
    --video-enabled false --keystroke-logging true

  LOCAL RECORDING WITH SYNC
  ==========================
  /etc/opt/wab/regional/recording-sync.conf:
  [sync]
  central_server = central-wallix.company.com
  sync_schedule = "0 2 * * *"  # Daily at 2 AM
  compression = true

  # Check sync status
  wabadmin recording-sync status

+==============================================================================+
```

---

## Emergency Access

```
+==============================================================================+
|                    EMERGENCY ACCESS                                           |
+==============================================================================+

  EMERGENCY SCENARIOS
  ====================
  Pipeline: Leak, compressor failure, pressure exceedance
  Substation: Protection trip, equipment failure, cyber incident

  EMERGENCY ACCESS WORKFLOW
  ==========================
  1. Alert received (SCADA alarm, field report)
  2. Emergency declared by supervisor
  3. Emergency code entered in WALLIX (approval bypassed)
  4. Immediate access with maximum recording
  5. Post-emergency review and credential rotation

  CONFIGURATION
  =============
  wabadmin authorization create Pipeline-Emergency-Access \
    --user-group Pipeline-Emergency-Response \
    --target-group All-Pipeline-RTUs \
    --approval-required false \
    --requires-emergency-code true \
    --session-recording true \
    --real-time-monitoring enabled \
    --time-limit 4h \
    --notification-group "Supervisors,Security-Team"

  BREAK-GLASS PROCEDURE (WALLIX Unavailable)
  ===========================================
  * Sealed envelopes in control room safe (dual-control)
  * Contents: device ID, username, password, valid-until date
  * Procedure: Two personnel retrieve, log seal number, use credential
  * Post-use: Rotate credential, prepare new envelope, file report

  NERC CIP EMERGENCY ACCESS
  ==========================
  CIP-004-6 R6 allows emergency access with:
  * Documented procedure
  * All access logged
  * Review/authorize within 24-72 hours
  * Credential rotation after use

+==============================================================================+
```

---

## Vendor/Contractor Access

```
+==============================================================================+
|                    VENDOR/CONTRACTOR ACCESS                                   |
+==============================================================================+

  FIELD SERVICE SCENARIOS
  ========================
  +-------------------------+------------------------------------------------+
  | Scenario                | Access Requirements                            |
  +-------------------------+------------------------------------------------+
  | Scheduled maintenance   | Pre-approved time window, specific devices     |
  | Break/fix repair        | Urgent access to failed device                 |
  | Firmware update         | Approved change window, full recording         |
  | Commissioning           | Extended access during installation            |
  +-------------------------+------------------------------------------------+

  VENDOR ACCESS WORKFLOW
  =======================
  1. Vendor registration (company approved, individual accounts, NDA)
  2. Access request (login, select target, provide work order)
  3. Approval (plant operations verifies, approves/denies)
  4. Access granted (time-limited, recorded, credentials injected)
  5. Post-access (recording archived, work order closed, credentials rotated)

  CONFIGURATION
  =============
  wabadmin group create RTU-Vendor-Technicians \
    --description "Field service technicians for RTU maintenance" \
    --external true

  wabadmin user create vendor-honeywell-jdoe \
    --group RTU-Vendor-Technicians \
    --email jdoe@honeywell.com \
    --expiry-date 2026-12-31 \
    --require-mfa true

  wabadmin authorization create Vendor-RTU-Access \
    --user-group RTU-Vendor-Technicians \
    --target-group Honeywell-RTUs \
    --approval-required true \
    --ticket-required true \
    --session-recording true \
    --max-session-duration 8h

  COMMISSIONING ACCESS
  ====================
  wabadmin authorization create Project-RTU-Commissioning \
    --user-group Commissioning-Vendor-Team \
    --target-group New-RTU-Installation \
    --valid-from 2026-03-01 \
    --valid-until 2026-04-30 \
    --max-session-duration 12h

+==============================================================================+
```

---

## Security Considerations

```
+==============================================================================+
|                    SECURITY CONSIDERATIONS                                    |
+==============================================================================+

  DEFENSE IN DEPTH
  =================
  Layer 1: Network - Firewall, WALLIX as only path, VPN encryption
  Layer 2: Authentication - MFA, individual accounts, certificates
  Layer 3: Authorization - Least privilege, time-based, approval workflows
  Layer 4: Monitoring - Session recording, real-time alerting, SIEM

  FIREWALL RULES
  ===============
  access-list OT-FIELD deny ip any OT-FIELD-NETWORKS
  access-list OT-FIELD permit ip WALLIX-IP OT-FIELD-NETWORKS
  access-list REGION-A permit ip REGION-A-JUMP REGION-A-FIELD-NET

  ENCRYPTION MATRIX
  ==================
  +-------------------------+----------------------+---------------------------+
  | Connection              | Encryption           | Implementation            |
  +-------------------------+----------------------+---------------------------+
  | User to WALLIX          | TLS 1.3              | HTTPS/SSH                 |
  | WALLIX to Jump Host     | TLS 1.3 / SSH        | Internal network          |
  | WAN connections         | IPsec / TLS          | VPN tunnel                |
  | Credential storage      | AES-256-GCM          | WALLIX vault              |
  +-------------------------+----------------------+---------------------------+

  TLS CONFIGURATION
  =================
  [ssl]
  min_version = TLSv1.3
  ciphersuites = TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256
  hsts_enabled = true

  LEGACY DEVICE COMPENSATING CONTROLS
  =====================================
  * Network isolation (legacy devices in isolated VLAN)
  * VPN tunnel wrapping unencrypted traffic
  * Physical security of network paths
  * Protocol-specific security (DNP3-SA, Modbus/TCP Security)

+==============================================================================+
```

---

## Compliance

```
+==============================================================================+
|                    COMPLIANCE                                                 |
+==============================================================================+

  NERC CIP FOR UTILITIES
  =======================
  Reference: https://www.nerc.com/pa/Stand/Pages/ReliabilityStandards.aspx

  +-------------------------+------------------------------------------------+
  | Requirement             | WALLIX Implementation                          |
  +-------------------------+------------------------------------------------+
  | CIP-005-6 R1            | WALLIX as Electronic Access Point (EAP)        |
  |                         | All interactive remote access through Bastion  |
  +-------------------------+------------------------------------------------+
  | CIP-005-6 R2            | Intermediate system between external network   |
  |                         | and BES Cyber Assets, session monitoring       |
  +-------------------------+------------------------------------------------+
  | CIP-007-6 R5            | Unique user identification, authentication     |
  |                         | enforcement, failed login alerting             |
  +-------------------------+------------------------------------------------+
  | CIP-007-6 R5.6          | Full session logging, minimum 90-day retention |
  |                         | SIEM integration for alerting                  |
  +-------------------------+------------------------------------------------+
  | CIP-004-6 R4            | Revoke access within 24 hours of termination   |
  |                         | Immediate revocation capability                |
  +-------------------------+------------------------------------------------+
  | CIP-004-6 R6            | Emergency access procedures documented         |
  |                         | All emergency access logged and reviewed       |
  +-------------------------+------------------------------------------------+
  | CIP-011-2               | Session recording for BES Cyber Information    |
  |                         | Credential vault protects sensitive data       |
  +-------------------------+------------------------------------------------+

  # Generate CIP compliance reports
  wabadmin compliance-report generate \
    --standard NERC-CIP \
    --period 2026-Q1 \
    --output /reports/nerc-cip-q1-2026.pdf

  # Specific CIP-007-6 R5 evidence
  wabadmin audit-report access-control \
    --start-date 2026-01-01 \
    --end-date 2026-03-31 \
    --include failed-logins \
    --include access-granted \
    --include access-revoked

  ---------------------------------------------------------------------------

  TSA PIPELINE SECURITY
  ======================
  TSA Security Directive Pipeline-2021-02 (and updates) requirements
  Reference: https://www.tsa.gov/sd-and-ea

  +-------------------------+------------------------------------------------+
  | Requirement             | WALLIX Implementation                          |
  +-------------------------+------------------------------------------------+
  | Password/MFA policy     | Enforce MFA for all remote access              |
  |                         | Password complexity and rotation               |
  +-------------------------+------------------------------------------------+
  | Access control          | Role-based access control                      |
  |                         | Least privilege enforcement                    |
  +-------------------------+------------------------------------------------+
  | Continuous monitoring   | Session recording, real-time alerting          |
  |                         | SIEM integration for correlation               |
  +-------------------------+------------------------------------------------+
  | Network segmentation    | IT/OT boundary enforcement                     |
  |                         | WALLIX as choke point                          |
  +-------------------------+------------------------------------------------+
  | Incident response       | Immediate session termination capability       |
  |                         | Audit trail for investigations                 |
  +-------------------------+------------------------------------------------+

  wabadmin policy create tsa-pipeline-policy \
    --mfa-required true \
    --mfa-type hardware-token \
    --password-min-length 16 \
    --password-rotation-days 90 \
    --session-recording mandatory \
    --session-timeout-minutes 30 \
    --failed-login-lockout 3

  # Apply to all pipeline assets
  wabadmin authorization configure-all \
    --target-group Pipeline-OT-Assets \
    --policy tsa-pipeline-policy

  ---------------------------------------------------------------------------

  OIL & GAS REGULATIONS
  ======================
  * API 1164: Pipeline SCADA Security (https://www.api.org)
  * DOT PHMSA: Pipeline safety regulations
  * State regulations: Varies by jurisdiction

  AWIA FOR WATER UTILITIES
  =========================
  America's Water Infrastructure Act (AWIA) Section 2013
  * Risk assessment documentation
  * Monitoring of SCADA systems (session recording)
  * Chemical handling system access controls
  * Detection of intrusions (SIEM integration)

+==============================================================================+
```

---

## Troubleshooting

```
+==============================================================================+
|                    TROUBLESHOOTING                                            |
+==============================================================================+

  CONNECTIVITY ISSUES
  ====================
  +-------------------------+------------------------------------------------+
  | Symptom                 | Possible Causes                                |
  +-------------------------+------------------------------------------------+
  | Connection timeout      | WAN link down, firewall blocking, device off   |
  | Slow response           | High latency, bandwidth saturation             |
  | Intermittent drops      | Cellular handoff, radio interference           |
  | Authentication failure  | Credential expired, MFA timeout                |
  | Session freeze          | Device overload, network congestion            |
  +-------------------------+------------------------------------------------+

  DIAGNOSTIC COMMANDS
  ====================
  # Check WALLIX connectivity to target
  wabadmin connectivity-test --target RTU-001

  Output:
  Target: RTU-001 (10.200.50.10)
  ================================
  Network reachability: OK (ping 145ms)
  TCP port 22: OK
  TCP port 502: OK
  Last successful session: 2026-02-01 08:45:12

  # Check session status
  wabadmin session-status --active

  Session    | User    | Target  | Status    | Duration
  ---------- | ------- | ------- | --------- | --------
  sess-0145  | jsmith  | RTU-001 | Connected | 00:23:45
  sess-0146  | mwilson | RTU-003 | Reconnect | 00:45:12

  # Network path diagnostics (from WALLIX server)
  ping -c 5 <device-ip>
  nc -zv <device-ip> 22
  nc -zv <device-ip> 502
  traceroute <device-ip>
  mtr -r -c 100 <device-ip>

  ---------------------------------------------------------------------------

  LATENCY TROUBLESHOOTING
  ========================
  +-------------------------+------------------+------------------------------+
  | Latency Range           | Classification   | Expected Experience          |
  +-------------------------+------------------+------------------------------+
  | < 50 ms                 | Excellent        | Real-time interaction        |
  | 50-150 ms               | Good             | Slight delay, usable         |
  | 150-300 ms              | Acceptable       | Noticeable delay             |
  | 300-600 ms              | Poor             | Significant delay            |
  | > 600 ms                | Satellite        | Requires patience            |
  +-------------------------+------------------+------------------------------+

  # Measure latency to target device
  wabadmin latency-test --target RTU-001 --count 10

  Results for RTU-001 (10.200.50.10):
  ===================================
  Min latency:  125 ms
  Max latency:  312 ms
  Avg latency:  178 ms
  Jitter:       45 ms
  Packet loss:  0%

  Recommendation: Use high-latency session profile

  ---------------------------------------------------------------------------

  PROTOCOL-SPECIFIC TROUBLESHOOTING
  ==================================

  DNP3 ISSUES
  -----------
  +-------------------------+------------------------------------------------+
  | Issue                   | Resolution                                     |
  +-------------------------+------------------------------------------------+
  | Connection refused      | Check DNP3 port (20000), verify device online  |
  | Authentication failure  | DNP3-SA key mismatch, re-sync keys             |
  | Timeout on commands     | Increase timeout, check device load            |
  | Data quality issues     | Check device time sync, verify point config    |
  +-------------------------+------------------------------------------------+

  # DNP3 connectivity test from jump host
  dnp3-test -h <device-ip> -p 20000 -m 1 -o 1

  MODBUS ISSUES
  -------------
  +-------------------------+------------------------------------------------+
  | Issue                   | Resolution                                     |
  +-------------------------+------------------------------------------------+
  | No response             | Check port 502, verify device address          |
  | Illegal function        | Device doesn't support function code           |
  | Illegal address         | Register address doesn't exist                 |
  | Gateway timeout         | Serial device not responding to gateway        |
  +-------------------------+------------------------------------------------+

  # Modbus connectivity test
  modpoll -m tcp -a 1 -r 1 -c 5 <device-ip>

  # Expected output:
  # modpoll 3.10 - FieldTalk(tm) Modbus(R) Master Simulator
  # Protocol: Modbus/TCP
  # Destination: 10.200.50.10:502
  # [1]: 1234
  # [2]: 5678

  IEC 61850 ISSUES
  ----------------
  +-------------------------+------------------------------------------------+
  | Issue                   | Resolution                                     |
  +-------------------------+------------------------------------------------+
  | MMS connection failed   | Check port 102, verify IED configuration       |
  | GOOSE not received      | Check multicast, verify VLAN config            |
  | Model mismatch          | Re-import SCL file, verify IED firmware        |
  +-------------------------+------------------------------------------------+

  # Test MMS connectivity
  nc -zv <ied-ip> 102

  SERIAL-OVER-IP ISSUES
  ---------------------
  +-------------------------+------------------------------------------------+
  | Issue                   | Resolution                                     |
  +-------------------------+------------------------------------------------+
  | No serial response      | Check baud rate, parity, stop bits             |
  | Garbled data            | Baud rate mismatch                             |
  | Timeout                 | Increase serial timeout, check cable           |
  | Port in use             | Another session holding port                   |
  +-------------------------+------------------------------------------------+

  # Check serial server connectivity
  telnet <serial-server-ip> <port>

  # Verify serial settings match device
  # Common settings: 9600,8,N,1 or 19200,8,N,1

  ---------------------------------------------------------------------------

  FIREWALL VERIFICATION
  ======================
  # On WALLIX server, check outbound
  iptables -L OUTPUT -v -n | grep <device-ip>

  # On intermediate firewall, verify rules
  show access-list | include <WALLIX-IP>
  show access-list | include <device-ip>

  BANDWIDTH MONITORING
  ====================
  # Monitor session bandwidth usage
  wabadmin session-stats --active --show-bandwidth

  Session ID    | User      | Target    | Bandwidth | Duration
  ------------- | --------- | --------- | --------- | --------
  sess-0012     | jsmith    | RTU-N01   | 12 Kbps   | 00:45:22
  sess-0013     | mwilson   | RTU-S03   | 156 Kbps  | 00:12:10

+==============================================================================+
```

---

## References

- WALLIX Documentation: https://pam.wallix.one/documentation
- NERC CIP Standards: https://www.nerc.com/pa/Stand/Pages/ReliabilityStandards.aspx
- TSA Pipeline Security: https://www.tsa.gov/sd-and-ea
- IEC 62443: https://www.iec.ch/cyber-security
- DNP3 (IEEE 1815): https://standards.ieee.org/standard/1815-2012.html
- Modbus: https://modbus.org/specs.php

---

## Related Documentation

- [54 - Secure Vendor Remote Access](../54-vendor-remote-access/README.md)
- [55 - OT Jump Host & Protocol Gateway](../55-ot-jump-host/README.md)
- [19 - Air-Gapped & Isolated Environments](../19-airgapped-environments/README.md)
- [17 - Industrial Protocols](../17-industrial-protocols/README.md)
