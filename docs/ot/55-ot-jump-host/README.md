# 55 - OT Jump Host & Protocol Gateway

## Table of Contents

1. [Jump Host Overview](#jump-host-overview)
2. [Jump Host Architecture](#jump-host-architecture)
3. [Jump Host Deployment Models](#jump-host-deployment-models)
4. [Protocol Gateway Patterns](#protocol-gateway-patterns)
5. [Accessing PLCs via Jump Host](#accessing-plcs-via-jump-host)
6. [Accessing HMI/SCADA Systems](#accessing-hmiscada-systems)
7. [OPC UA Gateway](#opc-ua-gateway)
8. [Zone-Based Access](#zone-based-access)
9. [Jump Host Hardening](#jump-host-hardening)
10. [Session Recording Through Jump Host](#session-recording-through-jump-host)
11. [Network Configuration](#network-configuration)
12. [Troubleshooting](#troubleshooting)

---

## Jump Host Overview

### Why Jump Hosts Are Essential for OT

```
+==============================================================================+
|                    OT JUMP HOST FUNDAMENTALS                                  |
+==============================================================================+

  THE CHALLENGE
  =============

  Industrial protocols (Modbus, S7comm, EtherNet/IP) were designed for:
  * Reliability over security
  * Local network communication
  * No authentication or encryption
  * Direct device-to-device communication

  Modern security requirements demand:
  * Individual accountability
  * Session recording
  * Access control
  * Audit trails

  +------------------------------------------------------------------------+
  |                                                                        |
  |   PROBLEM: Direct Access to Industrial Devices                        |
  |   =============================================                        |
  |                                                                        |
  |       [Engineer]                                                       |
  |           |                                                            |
  |           |  Modbus TCP (Port 502)                                     |
  |           |  NO authentication                                         |
  |           |  NO encryption                                             |
  |           |  NO recording                                              |
  |           v                                                            |
  |       [PLC/RTU]                                                        |
  |                                                                        |
  |   Issues:                                                              |
  |   * Who connected? Unknown                                             |
  |   * What changed? Unknown                                              |
  |   * When? Maybe logged if PLC supports it                              |
  |   * Compliance? Failed                                                 |
  |                                                                        |
  +------------------------------------------------------------------------+

  +------------------------------------------------------------------------+
  |                                                                        |
  |   SOLUTION: Jump Host with PAM                                         |
  |   =============================                                        |
  |                                                                        |
  |       [Engineer]                                                       |
  |           |                                                            |
  |           |  RDP/SSH (Authenticated, Recorded)                         |
  |           v                                                            |
  |   +===============+                                                    |
  |   |    WALLIX     |  <-- Authentication, Authorization, Recording      |
  |   |    BASTION    |                                                    |
  |   +===============+                                                    |
  |           |                                                            |
  |           |  RDP (Credential injection)                                |
  |           v                                                            |
  |   +---------------+                                                    |
  |   |   Jump Host   |  <-- Engineering software installed                |
  |   | (Eng Station) |                                                    |
  |   +---------------+                                                    |
  |           |                                                            |
  |           |  Modbus TCP (Port 502)                                     |
  |           v                                                            |
  |       [PLC/RTU]                                                        |
  |                                                                        |
  |   Benefits:                                                            |
  |   * Individual accountability via WALLIX                               |
  |   * Full session recording of engineering activities                   |
  |   * Approval workflows for critical changes                            |
  |   * Centralized audit trail                                            |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  JUMP HOST FUNCTIONS
  ===================

  +-------------------------+------------------------------------------------+
  | Function                | Description                                    |
  +-------------------------+------------------------------------------------+
  | Protocol Translation    | Convert secure protocols (SSH/RDP) to          |
  |                         | industrial protocols (Modbus, S7comm)          |
  +-------------------------+------------------------------------------------+
  | Software Host           | Run vendor-specific engineering software       |
  |                         | (TIA Portal, RSLogix, FactoryTalk)             |
  +-------------------------+------------------------------------------------+
  | Network Segmentation    | Bridge between IT/OT zones with control        |
  +-------------------------+------------------------------------------------+
  | Recording Point         | All actions visible in session recording       |
  +-------------------------+------------------------------------------------+
  | Credential Isolation    | OT device credentials never leave the zone     |
  +-------------------------+------------------------------------------------+

+==============================================================================+
```

### Jump Host Types

```
+==============================================================================+
|                    JUMP HOST TYPES FOR OT                                    |
+==============================================================================+

  TYPE 1: ENGINEERING WORKSTATION
  ================================

  Purpose: PLC/DCS programming and configuration
  Software: TIA Portal, RSLogix 5000, DeltaV, Unity Pro
  Access: RDP from WALLIX

  +------------------------------------------------------------------------+
  |   +-----------------------------------------------------------+        |
  |   |               ENGINEERING WORKSTATION                      |        |
  |   |                                                            |        |
  |   |   +------------------+    +------------------+            |        |
  |   |   | Siemens TIA      |    | Rockwell Studio  |            |        |
  |   |   | Portal           |    | 5000             |            |        |
  |   |   +------------------+    +------------------+            |        |
  |   |                                                            |        |
  |   |   +------------------+    +------------------+            |        |
  |   |   | Schneider Unity  |    | Emerson DeltaV   |            |        |
  |   |   | Pro              |    | Workstation      |            |        |
  |   |   +------------------+    +------------------+            |        |
  |   |                                                            |        |
  |   +-----------------------------------------------------------+        |
  +------------------------------------------------------------------------+

  TYPE 2: SCADA OPERATOR STATION
  ===============================

  Purpose: SCADA/HMI access for operations
  Software: WinCC, FactoryTalk View, Ignition
  Access: RDP from WALLIX

  +------------------------------------------------------------------------+
  |   +-----------------------------------------------------------+        |
  |   |               SCADA OPERATOR STATION                       |        |
  |   |                                                            |        |
  |   |   +--------------------------------------------------+    |        |
  |   |   |           SCADA/HMI Application                   |    |        |
  |   |   |                                                   |    |        |
  |   |   |   [Process Graphics]  [Alarms]  [Trends]          |    |        |
  |   |   |                                                   |    |        |
  |   |   +--------------------------------------------------+    |        |
  |   |                                                            |        |
  |   +-----------------------------------------------------------+        |
  +------------------------------------------------------------------------+

  TYPE 3: PROTOCOL GATEWAY
  ========================

  Purpose: Tunnel industrial protocols through secure channel
  Software: SSH server, port forwarding tools
  Access: SSH from WALLIX with tunneling

  +------------------------------------------------------------------------+
  |   +-----------------------------------------------------------+        |
  |   |               PROTOCOL GATEWAY                             |        |
  |   |                                                            |        |
  |   |   +------------------+    +------------------+            |        |
  |   |   | SSH Server       |    | Port Forwarding  |            |        |
  |   |   | (OpenSSH)        |    | Rules            |            |        |
  |   |   +------------------+    +------------------+            |        |
  |   |                                                            |        |
  |   |   Tunneled Protocols:                                     |        |
  |   |   * Modbus TCP (502)                                      |        |
  |   |   * S7comm (102)                                          |        |
  |   |   * EtherNet/IP (44818)                                   |        |
  |   |   * OPC UA (4840)                                         |        |
  |   |                                                            |        |
  |   +-----------------------------------------------------------+        |
  +------------------------------------------------------------------------+

  TYPE 4: WEB GATEWAY
  ===================

  Purpose: Access web-based HMI and OPC UA interfaces
  Software: Reverse proxy (nginx, HAProxy)
  Access: HTTPS from WALLIX

  +------------------------------------------------------------------------+
  |   +-----------------------------------------------------------+        |
  |   |               WEB GATEWAY                                  |        |
  |   |                                                            |        |
  |   |   +--------------------------------------------------+    |        |
  |   |   |           Reverse Proxy (nginx)                   |    |        |
  |   |   |                                                   |    |        |
  |   |   |   /hmi1  --> 192.168.10.20:80 (HMI Panel 1)       |    |        |
  |   |   |   /hmi2  --> 192.168.10.21:80 (HMI Panel 2)       |    |        |
  |   |   |   /opcua --> 192.168.10.30:4840 (OPC UA Server)   |    |        |
  |   |   |                                                   |    |        |
  |   |   +--------------------------------------------------+    |        |
  |   |                                                            |        |
  |   +-----------------------------------------------------------+        |
  +------------------------------------------------------------------------+

+==============================================================================+
```

---

## Jump Host Architecture

### OT Access Flow Diagram

```
+==============================================================================+
|                    OT JUMP HOST ARCHITECTURE                                  |
+==============================================================================+


                        ENTERPRISE ZONE (Level 5)
    +=======================================================================+
    |                                                                        |
    |     [IT Administrator]    [Control Engineer]    [Vendor Support]       |
    |            |                     |                     |               |
    |            +---------------------+---------------------+               |
    |                                  |                                     |
    +=======================================================================+
                                       |
                                       | HTTPS (443)
                                       v
    +=======================================================================+
    |                        ENTERPRISE DMZ (Level 4)                        |
    |                                                                        |
    |    +===========================================================+      |
    |    |                  WALLIX ACCESS MANAGER                     |      |
    |    |                                                            |      |
    |    |   * Web portal for session initiation                     |      |
    |    |   * MFA authentication                                    |      |
    |    |   * Target selection                                      |      |
    |    |                                                            |      |
    |    +===========================================================+      |
    |                                  |                                     |
    +=======================================================================+
                                       |
                              Firewall (IT/OT Boundary)
                                       |
    +=======================================================================+
    |                         OT DMZ (Level 3.5)                             |
    |                                                                        |
    |    +===========================================================+      |
    |    |                  WALLIX BASTION CORE                       |      |
    |    |                                                            |      |
    |    |   * Session proxy (SSH, RDP, VNC, HTTPS)                  |      |
    |    |   * Credential vault                                      |      |
    |    |   * Session recording                                     |      |
    |    |   * Authorization enforcement                             |      |
    |    |                                                            |      |
    |    +=======================+===============================+===+      |
    |                            |                               |          |
    |                            | RDP/SSH                       | HTTPS    |
    |                            v                               v          |
    |    +------------------------+          +------------------------+     |
    |    |   JUMP HOST TYPE 1     |          |   JUMP HOST TYPE 2     |     |
    |    |   Engineering Station  |          |   Web Gateway          |     |
    |    |                        |          |                        |     |
    |    |   [TIA Portal]         |          |   [nginx Proxy]        |     |
    |    |   [RSLogix 5000]       |          |   [OPC UA Proxy]       |     |
    |    |   [Unity Pro]          |          |                        |     |
    |    +------------------------+          +------------------------+     |
    |             |                                    |                    |
    +=======================================================================+
                  |                                    |
         Firewall (OT Internal)               Firewall (OT Internal)
                  |                                    |
    +=======================================================================+
    |                     CONTROL ZONE (Level 2-3)                           |
    |                                                                        |
    |    +-------------+    +-------------+    +-------------+              |
    |    | SCADA       |    | HMI         |    | Historian   |              |
    |    | Server      |    | Stations    |    | Server      |              |
    |    +------+------+    +------+------+    +-------------+              |
    |           |                  |                                        |
    +=======================================================================+
                |                  |
         Industrial Protocols (Modbus, S7comm, EtherNet/IP)
                |                  |
    +=======================================================================+
    |                      FIELD ZONE (Level 0-1)                            |
    |                                                                        |
    |    +-------+    +-------+    +-------+    +-------+    +-------+      |
    |    | PLC-1 |    | PLC-2 |    | RTU-1 |    | VFD-1 |    |  SIS  |      |
    |    +-------+    +-------+    +-------+    +-------+    +-------+      |
    |                                                                        |
    +=======================================================================+


+==============================================================================+
```

### Detailed Connection Flow

```
+==============================================================================+
|                    CONNECTION FLOW DETAIL                                    |
+==============================================================================+

  STEP-BY-STEP ACCESS TO PLC VIA JUMP HOST
  =========================================


  1. USER INITIATES SESSION
  -------------------------

     [Control Engineer]
            |
            | HTTPS to Access Manager Portal
            v
     +==================+
     | WALLIX Access Mgr|
     |                  |
     | Enter: username  |
     | Enter: password  |
     | Enter: MFA token |
     +==================+

  --------------------------------------------------------------------------

  2. TARGET SELECTION
  -------------------

     +==================+
     | WALLIX Access Mgr|
     |                  |
     | Available Targets:|
     | [x] ENG-WS-01    |  Engineering Workstation
     | [ ] ENG-WS-02    |  Engineering Workstation
     | [ ] SCADA-01     |  SCADA Server
     +==================+
            |
            | User selects ENG-WS-01
            v

  --------------------------------------------------------------------------

  3. AUTHORIZATION CHECK
  ----------------------

     +==================+
     | WALLIX BASTION   |
     |                  |
     | Checking:        |
     | * User group     |  Control-Engineers
     | * Target group   |  Engineering-Stations
     | * Time frame     |  Business hours
     | * Approval       |  Required for PLC access
     +==================+
            |
            | If approval required, notification sent
            v

  --------------------------------------------------------------------------

  4. APPROVAL WORKFLOW (IF REQUIRED)
  ----------------------------------

     +==================+
     | APPROVAL REQUEST |
     |                  |
     | To: OT Manager   |
     | From: J.Smith    |
     | Target: ENG-WS-01|
     | Purpose: PLC     |
     |   maintenance    |
     | Duration: 2 hrs  |
     +==================+
            |
            | OT Manager approves (mobile/email)
            v

  --------------------------------------------------------------------------

  5. SESSION ESTABLISHED
  ----------------------

     +==================+      +==================+
     | WALLIX BASTION   |      |   ENG-WS-01      |
     |                  |      |   (Jump Host)    |
     | * Inject creds   +----->+                  |
     | * Start recording|      | * RDP session    |
     | * Log session    |      |   established    |
     +==================+      +==================+
                                       |
                                       | Engineer uses TIA Portal
                                       v

  --------------------------------------------------------------------------

  6. PLC ACCESS VIA JUMP HOST
  ---------------------------

     +==================+      +==================+
     |   ENG-WS-01      |      |      PLC         |
     |   (Jump Host)    |      |                  |
     |                  |      |                  |
     | [TIA Portal]     +----->+ S7comm (102)     |
     |                  |      |                  |
     | All actions      |      | Program download |
     | visible in RDP   |      | Online changes   |
     | recording        |      |                  |
     +==================+      +==================+

  --------------------------------------------------------------------------

  7. SESSION TERMINATION
  ----------------------

     * User disconnects or timeout
     * Recording saved and indexed
     * Session metadata logged
     * Optional: Post-session credential rotation

+==============================================================================+
```

---

## Jump Host Deployment Models

### Model 1: WALLIX as Direct Jump Host

```
+==============================================================================+
|                    MODEL 1: WALLIX AS JUMP HOST                              |
+==============================================================================+

  Use when WALLIX natively supports the required protocol.

  SUPPORTED PROTOCOLS:
  * SSH (direct to Linux devices)
  * RDP (direct to Windows HMI/SCADA)
  * VNC (direct to HMI panels)
  * HTTPS (direct to web-based interfaces)
  * Telnet (legacy devices)

  --------------------------------------------------------------------------

  ARCHITECTURE
  ============


       [Engineer]
            |
            | SSH/RDP/VNC
            v
     +==================+
     | WALLIX BASTION   |
     |                  |
     | Native Protocol  |
     | Proxy            |
     +==================+
            |
            | SSH/RDP/VNC (proxied)
            v
     +------------------+
     | Target Device    |
     | (HMI, SCADA, etc)|
     +------------------+


  --------------------------------------------------------------------------

  CONFIGURATION EXAMPLE: DIRECT RDP TO HMI
  =========================================

  Device Configuration:

  +------------------------------------------------------------------------+
  | wabadmin device create HMI-PANEL-01                                    |
  |   --domain OT-Control-Zone                                             |
  |   --host 192.168.10.20                                                 |
  |   --description "HMI Panel for Pump Station 1"                         |
  +------------------------------------------------------------------------+

  Service Configuration:

  +------------------------------------------------------------------------+
  | wabadmin service create HMI-PANEL-01/RDP                               |
  |   --protocol rdp                                                       |
  |   --port 3389                                                          |
  +------------------------------------------------------------------------+

  Account Configuration:

  +------------------------------------------------------------------------+
  | wabadmin account create HMI-PANEL-01/operator                          |
  |   --service RDP                                                        |
  |   --login "Operator"                                                   |
  |   --credentials-type password                                          |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  ADVANTAGES                           LIMITATIONS
  ==========                           ===========

  * Simplest architecture              * Only for supported protocols
  * Direct session recording           * No industrial protocol support
  * Native WALLIX features             * Requires direct network access
  * Lower latency                      * May expose Bastion to OT network

+==============================================================================+
```

### Model 2: Dedicated Jump Host Behind WALLIX

```
+==============================================================================+
|                    MODEL 2: DEDICATED JUMP HOST                              |
+==============================================================================+

  Use when vendor software or industrial protocols are required.

  ARCHITECTURE
  ============


       [Engineer]
            |
            | HTTPS (Web Portal)
            v
     +==================+
     | WALLIX Access Mgr|
     +==================+
            |
            | Session request
            v
     +==================+
     | WALLIX BASTION   |
     |                  |
     | RDP/SSH Proxy    |
     | + Recording      |
     +==================+
            |
            | RDP (credential injection)
            v
     +------------------+
     |   JUMP HOST      |
     |                  |
     | +-------------+  |
     | | Engineering |  |
     | | Software    |  |
     | +------+------+  |
     +--------|--------+
              |
              | Industrial Protocol
              | (Modbus, S7comm, etc.)
              v
     +------------------+
     |   PLC / RTU      |
     +------------------+


  --------------------------------------------------------------------------

  JUMP HOST REQUIREMENTS
  ======================

  +-------------------------+------------------------------------------------+
  | Component               | Specification                                  |
  +-------------------------+------------------------------------------------+
  | Operating System        | Windows 10/11 LTSC or Windows Server 2022      |
  +-------------------------+------------------------------------------------+
  | CPU                     | 4+ cores (for engineering software)            |
  +-------------------------+------------------------------------------------+
  | RAM                     | 16+ GB (TIA Portal, RSLogix require RAM)       |
  +-------------------------+------------------------------------------------+
  | Storage                 | 256+ GB SSD (software installation)            |
  +-------------------------+------------------------------------------------+
  | Network                 | Multiple NICs (management + OT network)        |
  +-------------------------+------------------------------------------------+
  | Software                | Vendor engineering tools licensed              |
  +-------------------------+------------------------------------------------+

  --------------------------------------------------------------------------

  CONFIGURATION EXAMPLE
  =====================

  Device (Jump Host):

  +------------------------------------------------------------------------+
  | wabadmin device create ENG-JUMPHOST-01                                 |
  |   --domain OT-DMZ                                                      |
  |   --host 172.16.10.50                                                  |
  |   --description "Engineering Jump Host - Siemens/Rockwell"             |
  +------------------------------------------------------------------------+

  Service:

  +------------------------------------------------------------------------+
  | wabadmin service create ENG-JUMPHOST-01/RDP                            |
  |   --protocol rdp                                                       |
  |   --port 3389                                                          |
  |   --subprotocols "clipboard:false,drive:false"                         |
  +------------------------------------------------------------------------+

  Account:

  +------------------------------------------------------------------------+
  | wabadmin account create ENG-JUMPHOST-01/plc-engineer                   |
  |   --service RDP                                                        |
  |   --login "PLC_Engineer"                                               |
  |   --domain "OT-DOMAIN"                                                 |
  |   --credentials-type password                                          |
  |   --auto-change-password true                                          |
  +------------------------------------------------------------------------+

  Authorization:

  +------------------------------------------------------------------------+
  | wabadmin authorization create control-engineers-jumphost               |
  |   --user-group Control-Engineers                                       |
  |   --target ENG-JUMPHOST-01/RDP/plc-engineer                            |
  |   --is-recorded true                                                   |
  |   --is-critical true                                                   |
  |   --approval-required true                                             |
  |   --approval-group OT-Managers                                         |
  +------------------------------------------------------------------------+

+==============================================================================+
```

### Model 3: Segmented Zone Jump Hosts

```
+==============================================================================+
|                    MODEL 3: ZONE-SEGMENTED JUMP HOSTS                        |
+==============================================================================+

  Use for large OT environments with multiple security zones.

  ARCHITECTURE
  ============


       [Engineer]
            |
            v
     +==================+
     | WALLIX BASTION   |
     | (OT DMZ)         |
     +==================+
            |
      +-----+-----+-----+-----+
      |           |           |
      v           v           v
  +--------+  +--------+  +--------+
  | JUMP   |  | JUMP   |  | JUMP   |
  | HOST   |  | HOST   |  | HOST   |
  | Zone 3 |  | Zone 2 |  | Zone 1 |
  +--------+  +--------+  +--------+
      |           |           |
      v           v           v
  +--------+  +--------+  +--------+
  | SCADA  |  |  HMI   |  |  PLC   |
  | Server |  | Panels |  |  RTU   |
  +--------+  +--------+  +--------+


  --------------------------------------------------------------------------

  ZONE-SPECIFIC JUMP HOSTS
  =========================

  +------------------+-------------------+-----------------------------------+
  | Zone             | Jump Host         | Purpose                           |
  +------------------+-------------------+-----------------------------------+
  | Zone 3           | JUMP-ZONE3-01     | SCADA server administration       |
  | (Site Operations)|                   | Historian access                  |
  |                  |                   | Network management                |
  +------------------+-------------------+-----------------------------------+
  | Zone 2           | JUMP-ZONE2-01     | HMI configuration                 |
  | (Area Control)   |                   | Operator console access           |
  |                  |                   | OPC UA client                     |
  +------------------+-------------------+-----------------------------------+
  | Zone 1           | JUMP-ZONE1-01     | PLC programming                   |
  | (Basic Control)  |                   | RTU configuration                 |
  |                  |                   | Safety system access              |
  +------------------+-------------------+-----------------------------------+

  --------------------------------------------------------------------------

  SECURITY LEVELS BY ZONE
  =======================

  +------------------+-------------------+-----------------------------------+
  | Zone             | Security Level    | Access Requirements               |
  +------------------+-------------------+-----------------------------------+
  | Zone 3           | SL-2              | * MFA required                    |
  |                  |                   | * Session recording               |
  |                  |                   | * Business hours                  |
  +------------------+-------------------+-----------------------------------+
  | Zone 2           | SL-3              | * MFA required                    |
  |                  |                   | * Session recording               |
  |                  |                   | * Single approval                 |
  |                  |                   | * Shift hours only                |
  +------------------+-------------------+-----------------------------------+
  | Zone 1           | SL-4              | * MFA required                    |
  |                  |                   | * Session recording               |
  |                  |                   | * Dual approval (4-eyes)          |
  |                  |                   | * Maintenance window only         |
  |                  |                   | * Real-time monitoring            |
  +------------------+-------------------+-----------------------------------+

+==============================================================================+
```

---

## Protocol Gateway Patterns

### SSH Tunnel for Industrial Protocols

```
+==============================================================================+
|                    SSH TUNNEL FOR INDUSTRIAL PROTOCOLS                       |
+==============================================================================+

  SSH tunneling allows secure transport of industrial protocols through
  WALLIX Bastion while maintaining session recording.

  --------------------------------------------------------------------------

  TUNNEL ARCHITECTURE
  ===================


       [Engineer Workstation]
              |
              | 1. SSH with port forwarding
              v
     +==================+
     | WALLIX BASTION   |
     |                  |
     | SSH Proxy with   |
     | tunnel support   |
     +==================+
              |
              | 2. SSH tunnel to jump host
              v
     +------------------+
     |   JUMP HOST      |
     |  (Protocol GW)   |
     |                  |
     | localhost:502    |
     | forwarded to     |
     | PLC:502          |
     +------------------+
              |
              | 3. Industrial protocol (Modbus)
              v
     +------------------+
     |      PLC         |
     |   192.168.1.10   |
     |      :502        |
     +------------------+


  --------------------------------------------------------------------------

  SSH TUNNEL CONFIGURATION
  ========================

  On Engineer Workstation (after WALLIX authentication):

  +------------------------------------------------------------------------+
  | # Connect via WALLIX with local port forwarding                        |
  | ssh -L 5502:192.168.1.10:502 engineer@wallix-bastion                   |
  |                                                                        |
  | # -L 5502:192.168.1.10:502 means:                                      |
  | #   Local port 5502 forwards to PLC (192.168.1.10) port 502            |
  +------------------------------------------------------------------------+

  Engineer's Modbus client connects to localhost:5502 instead of PLC directly.

  --------------------------------------------------------------------------

  WALLIX AUTHORIZATION FOR TUNNELING
  ===================================

  {
      "authorization_name": "plc-modbus-tunnel",
      "user_group": "Control-Engineers",
      "target_group": "Protocol-Gateways",

      "subprotocols": {
          "SSH_SHELL_SESSION": true,
          "SSH_REMOTE_COMMAND": false,
          "SSH_SCP_UP": false,
          "SSH_SCP_DOWN": false,
          "SSH_X11": false,
          "SSH_FORWARD_CONNECTION": true
      },

      "tunneling_policy": {
          "allowed_destinations": [
              "192.168.1.0/24:502",
              "192.168.1.0/24:102",
              "192.168.1.0/24:44818"
          ],
          "max_tunnels": 3
      },

      "is_recorded": true,
      "is_critical": true,
      "approval_required": true
  }

  --------------------------------------------------------------------------

  COMMON INDUSTRIAL PROTOCOL TUNNELS
  ===================================

  +------------------+--------+-------------------------------------------------+
  | Protocol         | Port   | SSH Tunnel Command                              |
  +------------------+--------+-------------------------------------------------+
  | Modbus TCP       | 502    | ssh -L 5502:plc-ip:502 user@wallix              |
  +------------------+--------+-------------------------------------------------+
  | S7comm (Siemens) | 102    | ssh -L 5102:plc-ip:102 user@wallix              |
  +------------------+--------+-------------------------------------------------+
  | EtherNet/IP      | 44818  | ssh -L 44818:plc-ip:44818 user@wallix           |
  +------------------+--------+-------------------------------------------------+
  | OPC UA           | 4840   | ssh -L 4840:opcserver:4840 user@wallix          |
  +------------------+--------+-------------------------------------------------+
  | DNP3             | 20000  | ssh -L 20000:rtu-ip:20000 user@wallix           |
  +------------------+--------+-------------------------------------------------+

+==============================================================================+
```

### RDP Gateway for HMI Access

```
+==============================================================================+
|                    RDP GATEWAY FOR HMI ACCESS                                |
+==============================================================================+

  WALLIX Bastion acts as RDP gateway for accessing HMI panels and SCADA
  workstations with full session recording.

  --------------------------------------------------------------------------

  RDP GATEWAY ARCHITECTURE
  ========================


       [Operator / Engineer]
              |
              | 1. HTTPS to Access Manager
              v
     +==================+
     | WALLIX Access Mgr|
     |                  |
     | Select target:   |
     | - HMI-Panel-01   |
     | - SCADA-WS-01    |
     +==================+
              |
              | 2. RDP via Bastion
              v
     +==================+
     | WALLIX BASTION   |
     |                  |
     | RDP Proxy        |
     | + Recording      |
     | + Credential     |
     |   injection      |
     +==================+
              |
              | 3. RDP to target
              v
     +------------------+
     |   HMI Panel      |
     |                  |
     | - WinCC          |
     | - FactoryTalk    |
     | - Ignition       |
     +------------------+


  --------------------------------------------------------------------------

  RDP CONFIGURATION FOR HMI
  =========================

  Service Configuration (disable dangerous features):

  +------------------------------------------------------------------------+
  | wabadmin service create HMI-PANEL-01/RDP                               |
  |   --protocol rdp                                                       |
  |   --port 3389                                                          |
  |   --rdp-clipboard disabled                                             |
  |   --rdp-drive-mapping disabled                                         |
  |   --rdp-printer-mapping disabled                                       |
  |   --rdp-smartcard disabled                                             |
  |   --rdp-audio disabled                                                 |
  +------------------------------------------------------------------------+

  Security Rationale:

  +------------------+---------------------------------------------------+
  | Feature          | Why Disabled                                      |
  +------------------+---------------------------------------------------+
  | Clipboard        | Prevents data exfiltration, malware transfer      |
  +------------------+---------------------------------------------------+
  | Drive mapping    | Blocks USB/file transfer to/from OT systems       |
  +------------------+---------------------------------------------------+
  | Printer          | Not needed for HMI operations                     |
  +------------------+---------------------------------------------------+
  | Smart card       | Use WALLIX MFA instead                            |
  +------------------+---------------------------------------------------+
  | Audio            | Not needed, reduces bandwidth                     |
  +------------------+---------------------------------------------------+

  --------------------------------------------------------------------------

  RDP RECORDING QUALITY SETTINGS
  ==============================

  For HMI/SCADA sessions where visual detail is critical:

  +------------------------------------------------------------------------+
  | # wabengine.conf                                                       |
  |                                                                        |
  | [rdp_recording]                                                        |
  | video_quality = high                                                   |
  | video_codec = h264                                                     |
  | frame_rate = 10                                                        |
  | key_frame_interval = 5                                                 |
  |                                                                        |
  | # OCR for text extraction from recordings                              |
  | ocr_enabled = true                                                     |
  | ocr_language = en                                                      |
  +------------------------------------------------------------------------+

+==============================================================================+
```

### VNC for Legacy HMI Systems

```
+==============================================================================+
|                    VNC FOR LEGACY HMI SYSTEMS                                |
+==============================================================================+

  Many legacy HMI panels only support VNC for remote access. WALLIX Bastion
  provides VNC proxying with session recording.

  --------------------------------------------------------------------------

  VNC GATEWAY ARCHITECTURE
  ========================


       [Operator]
            |
            | 1. HTTPS to Access Manager
            v
     +==================+
     | WALLIX Access Mgr|
     +==================+
            |
            | 2. VNC via Bastion
            v
     +==================+
     | WALLIX BASTION   |
     |                  |
     | VNC Proxy        |
     | (RFB Protocol)   |
     +==================+
            |
            | 3. VNC to legacy HMI
            v
     +------------------+
     |   Legacy HMI     |
     |                  |
     | - Embedded Linux |
     | - Windows CE     |
     | - Proprietary OS |
     +------------------+


  --------------------------------------------------------------------------

  VNC CONFIGURATION
  =================

  Device:

  +------------------------------------------------------------------------+
  | wabadmin device create LEGACY-HMI-01                                   |
  |   --domain OT-Legacy-Zone                                              |
  |   --host 192.168.50.10                                                 |
  |   --description "Legacy HMI Panel - Pump Station 5"                    |
  +------------------------------------------------------------------------+

  Service:

  +------------------------------------------------------------------------+
  | wabadmin service create LEGACY-HMI-01/VNC                              |
  |   --protocol vnc                                                       |
  |   --port 5900                                                          |
  +------------------------------------------------------------------------+

  Account:

  +------------------------------------------------------------------------+
  | wabadmin account create LEGACY-HMI-01/operator                         |
  |   --service VNC                                                        |
  |   --credentials-type password                                          |
  |   --password "********"                                                |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  VNC SECURITY CONSIDERATIONS
  ===========================

  +-------------------------+------------------------------------------------+
  | Issue                   | Mitigation                                     |
  +-------------------------+------------------------------------------------+
  | VNC is unencrypted      | Traffic encrypted within WALLIX tunnel         |
  +-------------------------+------------------------------------------------+
  | Weak VNC passwords      | Passwords managed in WALLIX vault              |
  +-------------------------+------------------------------------------------+
  | No user authentication  | Individual accountability via WALLIX           |
  +-------------------------+------------------------------------------------+
  | No session logging      | Full recording via WALLIX                      |
  +-------------------------+------------------------------------------------+

+==============================================================================+
```

### Web Proxy for OPC UA Interfaces

```
+==============================================================================+
|                    WEB PROXY FOR OPC UA INTERFACES                           |
+==============================================================================+

  OPC UA over HTTPS can be proxied through WALLIX for web-based access to
  industrial data and configuration.

  --------------------------------------------------------------------------

  OPC UA HTTPS PROXY ARCHITECTURE
  ================================


       [OPC UA Client]
            |
            | 1. HTTPS (443)
            v
     +==================+
     | WALLIX BASTION   |
     |                  |
     | HTTPS Proxy      |
     | + Recording      |
     +==================+
            |
            | 2. HTTPS to OPC UA Server
            v
     +------------------+
     |  OPC UA Server   |
     |                  |
     | opc.tcp or HTTPS |
     | endpoint         |
     +------------------+
            |
            | 3. OPC UA data access
            v
     +------------------+
     |   PLC / SCADA    |
     +------------------+


  --------------------------------------------------------------------------

  OPC UA WEB GATEWAY CONFIGURATION
  =================================

  For OPC UA servers with HTTPS endpoints:

  +------------------------------------------------------------------------+
  | wabadmin device create OPCUA-SERVER-01                                 |
  |   --domain OT-Control-Zone                                             |
  |   --host 192.168.10.100                                                |
  |   --description "OPC UA Server - Plant Control System"                 |
  +------------------------------------------------------------------------+

  +------------------------------------------------------------------------+
  | wabadmin service create OPCUA-SERVER-01/HTTPS                          |
  |   --protocol https                                                     |
  |   --port 443                                                           |
  |   --url-path "/opcua"                                                  |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  NGINX REVERSE PROXY FOR OPC UA
  ==============================

  When OPC UA uses binary protocol (4840), deploy nginx as web gateway:

  +------------------------------------------------------------------------+
  | # /etc/nginx/conf.d/opcua-gateway.conf                                 |
  |                                                                        |
  | upstream opcua_backend {                                               |
  |     server 192.168.10.100:4840;                                        |
  | }                                                                      |
  |                                                                        |
  | server {                                                               |
  |     listen 443 ssl;                                                    |
  |     server_name opcua-gateway.ot.local;                                |
  |                                                                        |
  |     ssl_certificate /etc/nginx/ssl/opcua-gw.crt;                       |
  |     ssl_certificate_key /etc/nginx/ssl/opcua-gw.key;                   |
  |                                                                        |
  |     location /opcua {                                                  |
  |         proxy_pass http://opcua_backend;                               |
  |         proxy_http_version 1.1;                                        |
  |         proxy_set_header Upgrade $http_upgrade;                        |
  |         proxy_set_header Connection "upgrade";                         |
  |     }                                                                  |
  | }                                                                      |
  +------------------------------------------------------------------------+

+==============================================================================+
```

---

## Accessing PLCs via Jump Host

### SSH Tunnel for Modbus TCP

```
+==============================================================================+
|                    SSH TUNNEL FOR MODBUS TCP                                 |
+==============================================================================+

  SCENARIO
  ========

  Engineer needs to use Modbus client software to read/write PLC registers
  through secure, recorded access.

  --------------------------------------------------------------------------

  ARCHITECTURE
  ============


       [Engineer Workstation]
              |
       +------+------+
       | Modbus Poll |
       | or similar  |
       | client      |
       +------+------+
              |
              | Connects to localhost:5502
              v
       +------+------+
       |   SSH       |
       |   Client    |
       |   (local    |
       |    tunnel)  |
       +------+------+
              |
              | SSH tunnel via WALLIX
              v
     +==================+
     | WALLIX BASTION   |
     |                  |
     | SSH Proxy        |
     | Recording active |
     +==================+
              |
              | SSH to jump host with forwarding
              v
     +------------------+
     |   JUMP HOST      |
     |                  |
     | Port forward:    |
     | 502 --> PLC:502  |
     +------------------+
              |
              | Modbus TCP (502)
              v
     +------------------+
     |      PLC         |
     |  192.168.1.50    |
     +------------------+


  --------------------------------------------------------------------------

  STEP-BY-STEP CONFIGURATION
  ===========================

  1. Configure jump host service in WALLIX:

  +------------------------------------------------------------------------+
  | wabadmin service create PROTOCOL-GW-01/SSH                             |
  |   --protocol ssh                                                       |
  |   --port 22                                                            |
  |   --ssh-shell true                                                     |
  |   --ssh-tunneling true                                                 |
  +------------------------------------------------------------------------+

  2. Configure authorization with tunnel permissions:

  +------------------------------------------------------------------------+
  | wabadmin authorization create modbus-tunnel-access                     |
  |   --user-group Control-Engineers                                       |
  |   --target PROTOCOL-GW-01/SSH/tunnel-account                           |
  |   --subprotocols "SSH_SHELL_SESSION,SSH_FORWARD_CONNECTION"            |
  |   --allowed-tunnel-destinations "192.168.1.0/24:502"                   |
  |   --is-recorded true                                                   |
  |   --is-critical true                                                   |
  |   --approval-required true                                             |
  +------------------------------------------------------------------------+

  3. Engineer connects via SSH with port forwarding:

  +------------------------------------------------------------------------+
  | # On engineer's workstation                                            |
  | ssh -L 5502:192.168.1.50:502 tunnel-account@wallix.company.com         |
  |                                                                        |
  | # WALLIX prompts for:                                                  |
  | # - Primary authentication                                             |
  | # - MFA token                                                          |
  | # - Approval (if not pre-approved)                                     |
  +------------------------------------------------------------------------+

  4. Use Modbus client:

  +------------------------------------------------------------------------+
  | # Point Modbus client to localhost:5502                                |
  | modpoll -m tcp -a 1 -r 1 -c 10 127.0.0.1:5502                          |
  |                                                                        |
  | # Traffic flows:                                                       |
  | # localhost:5502 --> SSH tunnel --> Jump Host --> PLC:502              |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  RECORDING CONTENT
  =================

  SSH tunnel sessions capture:

  +-------------------------+------------------------------------------------+
  | Captured                | Details                                        |
  +-------------------------+------------------------------------------------+
  | Connection metadata     | Source IP, timestamp, duration                 |
  +-------------------------+------------------------------------------------+
  | Tunnel setup            | Destination IP and port                        |
  +-------------------------+------------------------------------------------+
  | SSH shell (if used)     | All commands typed in shell                    |
  +-------------------------+------------------------------------------------+
  | Tunnel traffic          | Logged (not decrypted)                         |
  +-------------------------+------------------------------------------------+

  NOTE: The actual Modbus protocol content is not inspected, but the RDP
  session to the engineering workstation (if used) captures all visible
  activity in the Modbus client software.

+==============================================================================+
```

### Port Forwarding for S7comm (Siemens)

```
+==============================================================================+
|                    PORT FORWARDING FOR S7COMM                                |
+==============================================================================+

  S7comm (Siemens S7 protocol) uses TCP port 102 for PLC communication.

  --------------------------------------------------------------------------

  S7COMM TUNNEL SETUP
  ===================


       [TIA Portal]
            |
            | Connects to localhost:102
            v
       [SSH Tunnel]
            |
            | Via WALLIX to Jump Host
            v
     +==================+
     | WALLIX BASTION   |
     +==================+
            |
            | SSH to Protocol Gateway
            v
     +------------------+
     |  PROTOCOL-GW     |
     +------------------+
            |
            | S7comm (102)
            v
     +------------------+
     |  Siemens S7-1500 |
     |  192.168.1.100   |
     +------------------+


  --------------------------------------------------------------------------

  TUNNEL COMMAND
  ==============

  +------------------------------------------------------------------------+
  | # Create SSH tunnel for S7comm                                         |
  | ssh -L 102:192.168.1.100:102 s7-tunnel@wallix.company.com              |
  |                                                                        |
  | # Then configure TIA Portal to connect to:                             |
  | # Interface: TCP/IP                                                    |
  | # IP Address: 127.0.0.1                                                |
  | # Rack: 0                                                              |
  | # Slot: 1                                                              |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  ALTERNATIVE: RDP TO ENGINEERING STATION
  ========================================

  For better recording (visible TIA Portal screens):

  +------------------------------------------------------------------------+
  |                                                                        |
  |   [Engineer]                                                           |
  |       |                                                                |
  |       | RDP via WALLIX                                                 |
  |       v                                                                |
  |   +==================+                                                 |
  |   | WALLIX BASTION   |                                                 |
  |   +==================+                                                 |
  |       |                                                                |
  |       | RDP (recorded)                                                 |
  |       v                                                                |
  |   +------------------+                                                 |
  |   | Engineering WS   |                                                 |
  |   |                  |                                                 |
  |   | [TIA Portal]     |  <-- All actions visible in recording          |
  |   |                  |                                                 |
  |   +------------------+                                                 |
  |       |                                                                |
  |       | S7comm (local network)                                         |
  |       v                                                                |
  |   +------------------+                                                 |
  |   |  Siemens PLC     |                                                 |
  |   +------------------+                                                 |
  |                                                                        |
  +------------------------------------------------------------------------+

  RECOMMENDATION: Use RDP to engineering workstation for PLC programming
  to capture all visual activity in session recording.

+==============================================================================+
```

### Engineering Workstation Access

```
+==============================================================================+
|                    ENGINEERING WORKSTATION ACCESS                            |
+==============================================================================+

  RECOMMENDED PATTERN FOR PLC PROGRAMMING
  ========================================

  For comprehensive audit and safety, access PLCs through a dedicated
  engineering workstation with vendor software.

  --------------------------------------------------------------------------

  WORKSTATION CONFIGURATION
  =========================

  +------------------+---------------------------------------------------+
  | Component        | Configuration                                     |
  +------------------+---------------------------------------------------+
  | OS               | Windows 10/11 LTSC (minimal, hardened)            |
  +------------------+---------------------------------------------------+
  | Domain           | Joined to OT domain (separate from corporate)     |
  +------------------+---------------------------------------------------+
  | Software         | Vendor tools only:                                |
  |                  | - Siemens TIA Portal                              |
  |                  | - Rockwell Studio 5000                            |
  |                  | - Schneider Unity Pro                             |
  |                  | - ABB Automation Builder                          |
  +------------------+---------------------------------------------------+
  | Network          | Two NICs:                                         |
  |                  | - Management (connected to WALLIX)                |
  |                  | - OT (connected to PLC network)                   |
  +------------------+---------------------------------------------------+
  | USB              | Disabled or strictly controlled                   |
  +------------------+---------------------------------------------------+
  | Internet         | No internet access                                |
  +------------------+---------------------------------------------------+

  --------------------------------------------------------------------------

  WALLIX CONFIGURATION FOR ENGINEERING ACCESS
  ============================================

  Device:

  +------------------------------------------------------------------------+
  | wabadmin device create ENG-WS-SIEMENS-01                               |
  |   --domain OT-Engineering-Zone                                         |
  |   --host 172.16.20.50                                                  |
  |   --description "Siemens TIA Portal Engineering Station"               |
  +------------------------------------------------------------------------+

  Service with restricted RDP:

  +------------------------------------------------------------------------+
  | wabadmin service create ENG-WS-SIEMENS-01/RDP                          |
  |   --protocol rdp                                                       |
  |   --port 3389                                                          |
  |   --rdp-clipboard disabled                                             |
  |   --rdp-drive-mapping disabled                                         |
  |   --rdp-smartcard disabled                                             |
  +------------------------------------------------------------------------+

  Account:

  +------------------------------------------------------------------------+
  | wabadmin account create ENG-WS-SIEMENS-01/siemens-engineer             |
  |   --service RDP                                                        |
  |   --login "SiemensEngineer"                                            |
  |   --domain "OT"                                                        |
  |   --credentials-type password                                          |
  |   --auto-change-password true                                          |
  |   --change-interval-days 90                                            |
  +------------------------------------------------------------------------+

  Authorization with approval:

  +------------------------------------------------------------------------+
  | wabadmin authorization create siemens-plc-engineering                  |
  |   --user-group Control-Engineers                                       |
  |   --target ENG-WS-SIEMENS-01/RDP/siemens-engineer                      |
  |   --is-recorded true                                                   |
  |   --is-critical true                                                   |
  |   --approval-required true                                             |
  |   --approval-group OT-Managers                                         |
  |   --time-restriction "MON-FRI 06:00-22:00"                             |
  |   --max-duration 4h                                                    |
  +------------------------------------------------------------------------+

+==============================================================================+
```

---

## Accessing HMI/SCADA Systems

### RDP to SCADA Workstations

```
+==============================================================================+
|                    RDP TO SCADA WORKSTATIONS                                 |
+==============================================================================+

  SCADA workstations require RDP access for operators and administrators.

  --------------------------------------------------------------------------

  ARCHITECTURE
  ============


       [Operator]              [Administrator]
            |                        |
            | RDP                    | RDP
            v                        v
     +==========================================+
     |            WALLIX BASTION                 |
     |                                           |
     |  User: Operator1    User: Admin1         |
     |  Role: Operator     Role: Administrator   |
     |  Target: SCADA-WS   Target: SCADA-Server  |
     +==========================================+
            |                        |
            | RDP (operator)         | RDP (admin)
            v                        v
     +------------------+    +------------------+
     | SCADA Operator   |    | SCADA Server     |
     | Workstation      |    |                  |
     |                  |    | * Configuration  |
     | * Monitoring     |    | * User mgmt      |
     | * Alarming       |    | * System admin   |
     | * Trending       |    |                  |
     +------------------+    +------------------+


  --------------------------------------------------------------------------

  OPERATOR VS ADMINISTRATOR ACCESS
  =================================

  +------------------+--------------------+------------------------------------+
  | Role             | Target             | Permissions                        |
  +------------------+--------------------+------------------------------------+
  | Operator         | Operator WS        | * View process                     |
  |                  |                    | * Acknowledge alarms               |
  |                  |                    | * Basic setpoint changes           |
  |                  |                    | * Recording: Always                |
  |                  |                    | * Approval: No                     |
  +------------------+--------------------+------------------------------------+
  | Supervisor       | Operator WS        | * All operator functions           |
  |                  | + Historian        | * Recipe changes                   |
  |                  |                    | * Report generation                |
  |                  |                    | * Recording: Always                |
  |                  |                    | * Approval: No                     |
  +------------------+--------------------+------------------------------------+
  | Administrator    | SCADA Server       | * System configuration             |
  |                  |                    | * User management                  |
  |                  |                    | * Project changes                  |
  |                  |                    | * Recording: Always                |
  |                  |                    | * Approval: Required               |
  +------------------+--------------------+------------------------------------+

  --------------------------------------------------------------------------

  SCADA SERVER CONFIGURATION
  ==========================

  +------------------------------------------------------------------------+
  | wabadmin device create SCADA-SERVER-01                                 |
  |   --domain OT-Control-Zone                                             |
  |   --host 192.168.10.10                                                 |
  |   --description "Primary SCADA Server - WinCC"                         |
  +------------------------------------------------------------------------+

  +------------------------------------------------------------------------+
  | wabadmin service create SCADA-SERVER-01/RDP                            |
  |   --protocol rdp                                                       |
  |   --port 3389                                                          |
  |   --rdp-clipboard disabled                                             |
  |   --rdp-drive-mapping disabled                                         |
  +------------------------------------------------------------------------+

  +------------------------------------------------------------------------+
  | wabadmin account create SCADA-SERVER-01/scada-admin                    |
  |   --service RDP                                                        |
  |   --login "SCADAAdmin"                                                 |
  |   --domain "OT"                                                        |
  |   --credentials-type password                                          |
  +------------------------------------------------------------------------+

  +------------------------------------------------------------------------+
  | wabadmin authorization create scada-admin-access                       |
  |   --user-group SCADA-Administrators                                    |
  |   --target SCADA-SERVER-01/RDP/scada-admin                             |
  |   --is-recorded true                                                   |
  |   --is-critical true                                                   |
  |   --approval-required true                                             |
  |   --approval-group OT-Managers                                         |
  +------------------------------------------------------------------------+

+==============================================================================+
```

### VNC to HMI Panels

```
+==============================================================================+
|                    VNC TO HMI PANELS                                         |
+==============================================================================+

  HMI panels often run embedded operating systems with VNC as the only
  remote access method.

  --------------------------------------------------------------------------

  COMMON HMI PANEL TYPES
  ======================

  +------------------+-------------------+-----------------------------------+
  | Vendor           | Panel Type        | Remote Access                     |
  +------------------+-------------------+-----------------------------------+
  | Siemens          | TP/KTP Series     | VNC, Web                          |
  | Siemens          | Comfort Panel     | VNC, Web                          |
  | Rockwell         | PanelView Plus    | VNC, Web                          |
  | Schneider        | Magelis           | VNC                               |
  | B&R              | Power Panel       | VNC                               |
  | Beckhoff         | CP Series         | VNC, Web                          |
  +------------------+-------------------+-----------------------------------+

  --------------------------------------------------------------------------

  VNC PANEL CONFIGURATION
  =======================

  Device:

  +------------------------------------------------------------------------+
  | wabadmin device create HMI-PANEL-PUMP-01                               |
  |   --domain OT-Field-Zone                                               |
  |   --host 192.168.100.20                                                |
  |   --description "Siemens Comfort Panel - Pump Station 1"               |
  +------------------------------------------------------------------------+

  Service:

  +------------------------------------------------------------------------+
  | wabadmin service create HMI-PANEL-PUMP-01/VNC                          |
  |   --protocol vnc                                                       |
  |   --port 5900                                                          |
  +------------------------------------------------------------------------+

  Account:

  +------------------------------------------------------------------------+
  | wabadmin account create HMI-PANEL-PUMP-01/operator                     |
  |   --service VNC                                                        |
  |   --credentials-type password                                          |
  |   --password "********"                                                |
  +------------------------------------------------------------------------+

  Authorization:

  +------------------------------------------------------------------------+
  | wabadmin authorization create hmi-panel-operators                      |
  |   --user-group Field-Operators                                         |
  |   --target-group HMI-Panels                                            |
  |   --is-recorded true                                                   |
  |   --is-critical false                                                  |
  |   --time-restriction "24x7"                                            |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  VNC SECURITY NOTES
  ==================

  +-------------------------+------------------------------------------------+
  | Risk                    | Mitigation                                     |
  +-------------------------+------------------------------------------------+
  | VNC password exposed    | Password stored in WALLIX vault, auto-injected |
  +-------------------------+------------------------------------------------+
  | Unencrypted traffic     | All traffic tunneled through WALLIX            |
  +-------------------------+------------------------------------------------+
  | Multiple connections    | WALLIX enforces single session per user        |
  +-------------------------+------------------------------------------------+
  | No logging              | Full session recording in WALLIX               |
  +-------------------------+------------------------------------------------+

+==============================================================================+
```

### Web-Based HMI Access

```
+==============================================================================+
|                    WEB-BASED HMI ACCESS                                      |
+==============================================================================+

  Modern HMIs offer web-based interfaces accessible via HTTPS proxy.

  --------------------------------------------------------------------------

  WEB HMI ARCHITECTURE
  ====================


       [Operator]
            |
            | HTTPS
            v
     +==================+
     | WALLIX BASTION   |
     |                  |
     | HTTPS Proxy      |
     | + Recording      |
     +==================+
            |
            | HTTPS to HMI
            v
     +------------------+
     | Web-based HMI    |
     |                  |
     | - Ignition       |
     | - Inductive      |
     | - GE Cimplicity  |
     | - Schneider Web  |
     +------------------+


  --------------------------------------------------------------------------

  WEB HMI CONFIGURATION
  =====================

  Device:

  +------------------------------------------------------------------------+
  | wabadmin device create WEB-HMI-01                                      |
  |   --domain OT-Control-Zone                                             |
  |   --host 192.168.10.30                                                 |
  |   --description "Ignition Web HMI"                                     |
  +------------------------------------------------------------------------+

  Service:

  +------------------------------------------------------------------------+
  | wabadmin service create WEB-HMI-01/HTTPS                               |
  |   --protocol https                                                     |
  |   --port 443                                                           |
  |   --url-path "/"                                                       |
  +------------------------------------------------------------------------+

  Account:

  +------------------------------------------------------------------------+
  | wabadmin account create WEB-HMI-01/operator                            |
  |   --service HTTPS                                                      |
  |   --login "operator"                                                   |
  |   --credentials-type password                                          |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  RECORDING WEB SESSIONS
  ======================

  Web HMI sessions capture:

  +-------------------------+------------------------------------------------+
  | Content                 | Details                                        |
  +-------------------------+------------------------------------------------+
  | Screenshots             | Periodic screen captures                       |
  +-------------------------+------------------------------------------------+
  | URLs accessed           | Full URL path logging                          |
  +-------------------------+------------------------------------------------+
  | Form submissions        | POST data (if configured)                      |
  +-------------------------+------------------------------------------------+
  | Session duration        | Start/end timestamps                           |
  +-------------------------+------------------------------------------------+

+==============================================================================+
```

---

## OPC UA Gateway

### HTTPS Proxy for OPC UA

```
+==============================================================================+
|                    OPC UA GATEWAY CONFIGURATION                              |
+==============================================================================+

  OPC UA is the modern industrial protocol with built-in security.
  WALLIX can proxy OPC UA over HTTPS for centralized access control.

  --------------------------------------------------------------------------

  OPC UA SECURITY MODES
  =====================

  +------------------+---------------------------------------------------+
  | Mode             | Description                                       |
  +------------------+---------------------------------------------------+
  | None             | No security (testing only)                        |
  +------------------+---------------------------------------------------+
  | Sign             | Message signing for integrity                     |
  +------------------+---------------------------------------------------+
  | SignAndEncrypt   | Signing + encryption (RECOMMENDED)                |
  +------------------+---------------------------------------------------+

  --------------------------------------------------------------------------

  OPC UA VIA HTTPS PROXY
  ======================


       [OPC UA Client]
            |
            | HTTPS (proxied by WALLIX)
            v
     +==================+
     | WALLIX BASTION   |
     |                  |
     | HTTPS Proxy      |
     | + Recording      |
     +==================+
            |
            | HTTPS to OPC UA Web Interface
            v
     +------------------+
     | OPC UA Server    |
     | (HTTPS endpoint) |
     |                  |
     | - KepServerEX    |
     | - Prosys         |
     | - Unified Auto   |
     +------------------+


  --------------------------------------------------------------------------

  OPC UA CONFIGURATION
  ====================

  Device:

  +------------------------------------------------------------------------+
  | wabadmin device create OPCUA-SERVER-01                                 |
  |   --domain OT-Control-Zone                                             |
  |   --host 192.168.10.100                                                |
  |   --description "KepServerEX OPC UA Server"                            |
  +------------------------------------------------------------------------+

  Service (HTTPS endpoint):

  +------------------------------------------------------------------------+
  | wabadmin service create OPCUA-SERVER-01/HTTPS                          |
  |   --protocol https                                                     |
  |   --port 443                                                           |
  |   --url-path "/opcua"                                                  |
  +------------------------------------------------------------------------+

  Account:

  +------------------------------------------------------------------------+
  | wabadmin account create OPCUA-SERVER-01/opcua-client                   |
  |   --service HTTPS                                                      |
  |   --login "opcua-reader"                                               |
  |   --credentials-type password                                          |
  +------------------------------------------------------------------------+

+==============================================================================+
```

### Certificate Management for OPC UA

```
+==============================================================================+
|                    OPC UA CERTIFICATE MANAGEMENT                             |
+==============================================================================+

  OPC UA uses X.509 certificates for secure communication. Proper
  certificate management is essential.

  --------------------------------------------------------------------------

  CERTIFICATE HIERARCHY
  =====================

  +------------------------------------------------------------------------+
  |                                                                        |
  |                    +---------------------+                             |
  |                    |    OT Root CA       |                             |
  |                    | (Air-gapped, HSM)   |                             |
  |                    +----------+----------+                             |
  |                               |                                        |
  |               +---------------+---------------+                        |
  |               |                               |                        |
  |     +---------+----------+         +----------+---------+              |
  |     | OPC UA Issuing CA  |         | Device Issuing CA  |              |
  |     +--------------------+         +--------------------+              |
  |               |                               |                        |
  |       +-------+-------+               +-------+-------+                |
  |       |               |               |               |                |
  |   +---+---+       +---+---+       +---+---+       +---+---+            |
  |   | OPC   |       | OPC   |       | PLC   |       | HMI   |            |
  |   | Server|       | Client|       | Cert  |       | Cert  |            |
  |   +-------+       +-------+       +-------+       +-------+            |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  CERTIFICATE CONFIGURATION
  =========================

  1. Generate OPC UA server certificate:

  +------------------------------------------------------------------------+
  | # Generate key pair                                                    |
  | openssl genrsa -out opcua-server.key 2048                              |
  |                                                                        |
  | # Generate CSR                                                         |
  | openssl req -new -key opcua-server.key -out opcua-server.csr           |
  |   -subj "/CN=opcua-server.ot.local/O=OT Security"                      |
  |                                                                        |
  | # Sign with OPC UA Issuing CA                                          |
  | openssl x509 -req -in opcua-server.csr                                 |
  |   -CA opcua-ca.crt -CAkey opcua-ca.key                                 |
  |   -CAcreateserial -out opcua-server.crt -days 365                      |
  +------------------------------------------------------------------------+

  2. Configure trusted certificates in OPC UA server:

  +------------------------------------------------------------------------+
  | OPC UA Server Trust List:                                              |
  |                                                                        |
  | /opt/opcua/pki/trusted/certs/                                          |
  |   opcua-ca.crt          # Issuing CA                                   |
  |   wallix-client.crt     # WALLIX as client                             |
  |                                                                        |
  | /opt/opcua/pki/rejected/certs/                                         |
  |   (auto-populated with unknown certificates)                           |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  WALLIX OPC UA CLIENT CERTIFICATE
  =================================

  Configure WALLIX with client certificate for OPC UA:

  +------------------------------------------------------------------------+
  | wabadmin certificate import wallix-opcua-client                        |
  |   --cert-file /path/to/wallix-client.crt                               |
  |   --key-file /path/to/wallix-client.key                                |
  |   --purpose opcua-client                                               |
  +------------------------------------------------------------------------+

+==============================================================================+
```

### Session Recording Considerations for OPC UA

```
+==============================================================================+
|                    OPC UA SESSION RECORDING                                  |
+==============================================================================+

  OPC UA sessions require special consideration for recording due to
  the binary protocol nature.

  --------------------------------------------------------------------------

  RECORDING OPTIONS
  =================

  +------------------+---------------------------------------------------+
  | Method           | Recording Capability                              |
  +------------------+---------------------------------------------------+
  | HTTPS Proxy      | * URL logging                                     |
  |                  | * Screenshot capture                              |
  |                  | * Request/response metadata                       |
  +------------------+---------------------------------------------------+
  | RDP to Client    | * Full visual recording                           |
  |                  | * All OPC UA client interactions                  |
  |                  | * Configuration changes visible                   |
  +------------------+---------------------------------------------------+
  | SSH Tunnel       | * Connection metadata                             |
  |                  | * Tunnel endpoints logged                         |
  |                  | * Protocol content not visible                    |
  +------------------+---------------------------------------------------+

  --------------------------------------------------------------------------

  RECOMMENDED: RDP TO OPC UA CLIENT WORKSTATION
  =============================================

  For comprehensive audit, access OPC UA through a workstation:

  +------------------------------------------------------------------------+
  |                                                                        |
  |   [Engineer]                                                           |
  |       |                                                                |
  |       | RDP via WALLIX (recorded)                                      |
  |       v                                                                |
  |   +------------------+                                                 |
  |   | OPC UA Client WS |                                                 |
  |   |                  |                                                 |
  |   | [UaExpert]       |  <-- All tag browsing visible                   |
  |   | [Prosys Client]  |  <-- All value changes visible                  |
  |   |                  |                                                 |
  |   +------------------+                                                 |
  |       |                                                                |
  |       | OPC UA (opc.tcp:// or HTTPS)                                   |
  |       v                                                                |
  |   +------------------+                                                 |
  |   | OPC UA Server    |                                                 |
  |   +------------------+                                                 |
  |                                                                        |
  +------------------------------------------------------------------------+

  This provides visual recording of all OPC UA client activities.

+==============================================================================+
```

---

## Zone-Based Access

### Zone 3 to Zone 2 Access

```
+==============================================================================+
|                    ZONE 3 TO ZONE 2 ACCESS                                   |
+==============================================================================+

  Access from Site Operations (Zone 3) to Area Control (Zone 2).

  --------------------------------------------------------------------------

  ARCHITECTURE
  ============


       ZONE 3 (Site Operations)
       ========================

       [SCADA Admin]    [Historian User]
            |                  |
            +--------+---------+
                     |
                     v
            +==================+
            | WALLIX BASTION   |
            | (Zone 3 DMZ)     |
            +==================+
                     |
            =========|=========  ZONE BOUNDARY (Firewall)
                     |
                     v
       ZONE 2 (Area Control)
       =====================

            +------------------+
            | JUMP HOST Z2     |
            | (Area Control)   |
            +------------------+
                     |
         +-----------+-----------+
         |           |           |
         v           v           v
     [HMI-1]     [HMI-2]     [HMI-3]


  --------------------------------------------------------------------------

  FIREWALL RULES (ZONE 3 TO ZONE 2)
  ==================================

  +------------------------------------------------------------------------+
  | Rule | Source          | Dest         | Port    | Protocol | Action   |
  +------+-----------------+--------------+---------+----------+----------+
  | 1    | WALLIX Bastion  | Jump Host Z2 | 3389    | RDP      | ALLOW    |
  | 2    | WALLIX Bastion  | Jump Host Z2 | 22      | SSH      | ALLOW    |
  | 3    | Jump Host Z2    | HMI Stations | 3389    | RDP      | ALLOW    |
  | 4    | Jump Host Z2    | HMI Stations | 5900    | VNC      | ALLOW    |
  | 99   | ANY             | ANY          | ANY     | ANY      | DENY+LOG |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  AUTHORIZATION CONFIGURATION
  ===========================

  +------------------------------------------------------------------------+
  | wabadmin authorization create zone3-to-zone2-access                    |
  |   --user-group Zone3-Users                                             |
  |   --target-group Zone2-Systems                                         |
  |   --is-recorded true                                                   |
  |   --is-critical false                                                  |
  |   --approval-required false                                            |
  |   --time-restriction "SHIFT-HOURS"                                     |
  +------------------------------------------------------------------------+

+==============================================================================+
```

### Zone 4 to Zone 3 Access

```
+==============================================================================+
|                    ZONE 4 TO ZONE 3 ACCESS                                   |
+==============================================================================+

  Access from Enterprise DMZ (Zone 4) to Site Operations (Zone 3).

  --------------------------------------------------------------------------

  ARCHITECTURE
  ============


       ZONE 4 (Enterprise DMZ)
       =======================

       [IT Admin]    [Vendor Support]
            |                |
            +-------+--------+
                    |
                    v
            +==================+
            | WALLIX Access Mgr|
            | (Internet-facing)|
            +==================+
                    |
            ========|========  IT/OT BOUNDARY (Firewall)
                    |
                    v
       ZONE 3.5 (OT DMZ)
       =================

            +==================+
            | WALLIX BASTION   |
            | (OT Core)        |
            +==================+
                    |
            ========|========  ZONE BOUNDARY (Firewall)
                    |
                    v
       ZONE 3 (Site Operations)
       ========================

            +------------------+
            | SCADA Server     |
            | Historian        |
            | Engineering WS   |
            +------------------+


  --------------------------------------------------------------------------

  CONDUIT CONFIGURATION
  =====================

  Access from Zone 4 to Zone 3 must traverse:
  1. Enterprise firewall (to OT DMZ)
  2. OT internal firewall (to Zone 3)

  Conduit Rules:

  +------------------------------------------------------------------------+
  | # IT/OT Boundary Firewall                                              |
  +------------------------------------------------------------------------+
  | Rule | Source          | Dest            | Port | Protocol | Action   |
  +------+-----------------+-----------------+------+----------+----------+
  | 1    | IT Users        | WALLIX AM       | 443  | HTTPS    | ALLOW    |
  | 2    | WALLIX AM       | WALLIX Bastion  | 443  | HTTPS    | ALLOW    |
  | 3    | WALLIX Bastion  | Zone 3 Systems  | 3389 | RDP      | ALLOW    |
  | 4    | WALLIX Bastion  | Zone 3 Systems  | 22   | SSH      | ALLOW    |
  +------------------------------------------------------------------------+

  +------------------------------------------------------------------------+
  | # OT Internal Firewall                                                 |
  +------------------------------------------------------------------------+
  | Rule | Source          | Dest            | Port | Protocol | Action   |
  +------+-----------------+-----------------+------+----------+----------+
  | 1    | WALLIX Bastion  | SCADA Server    | 3389 | RDP      | ALLOW    |
  | 2    | WALLIX Bastion  | Historian       | 3389 | RDP      | ALLOW    |
  | 3    | WALLIX Bastion  | Engineering WS  | 3389 | RDP      | ALLOW    |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  VENDOR ACCESS AUTHORIZATION
  ===========================

  Vendors require approval and time-limited access:

  +------------------------------------------------------------------------+
  | wabadmin authorization create vendor-zone3-access                      |
  |   --user-group External-Vendors                                        |
  |   --target-group Zone3-Systems                                         |
  |   --is-recorded true                                                   |
  |   --is-critical true                                                   |
  |   --approval-required true                                             |
  |   --approval-group OT-Security-Team                                    |
  |   --approval-timeout 2h                                                |
  |   --session-max-duration 4h                                            |
  |   --valid-for 7d                                                       |
  +------------------------------------------------------------------------+

+==============================================================================+
```

### Conduit Configuration

```
+==============================================================================+
|                    IEC 62443 CONDUIT CONFIGURATION                           |
+==============================================================================+

  Conduits are the secure communication paths between zones as defined
  in IEC 62443.

  --------------------------------------------------------------------------

  CONDUIT DIAGRAM
  ===============


     +------------------------------------------------------------------+
     |                                                                  |
     |   ZONE A                    CONDUIT                    ZONE B    |
     |   (Source)                                             (Dest)    |
     |                                                                  |
     |   +--------+          +------------------+          +--------+   |
     |   |        |          |                  |          |        |   |
     |   | Assets +--------->+ WALLIX BASTION   +--------->+ Assets |   |
     |   |        |   (1)    | + Firewall       |   (2)    |        |   |
     |   +--------+          +------------------+          +--------+   |
     |                                                                  |
     |   (1) Authenticated, authorized, recorded                       |
     |   (2) Only allowed protocols, logged                            |
     |                                                                  |
     +------------------------------------------------------------------+


  --------------------------------------------------------------------------

  CONDUIT SECURITY REQUIREMENTS
  =============================

  +------------------+---------------------------------------------------+
  | IEC 62443 SR     | WALLIX Implementation                             |
  +------------------+---------------------------------------------------+
  | SR 5.1           | Network segmentation via WALLIX as choke point    |
  | (Network Segment)|                                                   |
  +------------------+---------------------------------------------------+
  | SR 5.2           | Firewall rules allowing only WALLIX traffic       |
  | (Zone Boundary)  |                                                   |
  +------------------+---------------------------------------------------+
  | SR 5.3           | All connections through WALLIX proxy              |
  | (Access Control) |                                                   |
  +------------------+---------------------------------------------------+

  --------------------------------------------------------------------------

  WALLIX AS CONDUIT GATEWAY
  =========================

  Configure WALLIX as the only path between zones:

  +------------------------------------------------------------------------+
  | Network Configuration:                                                 |
  |                                                                        |
  | WALLIX Bastion Interfaces:                                             |
  | - eth0: 172.16.0.10 (Management / Zone 3.5 DMZ)                        |
  | - eth1: 192.168.10.1 (Zone 3 - Control Network)                        |
  | - eth2: 192.168.100.1 (Zone 2 - Field Network)                         |
  |                                                                        |
  | Routing:                                                               |
  | - Zone 3 (192.168.10.0/24) via eth1                                    |
  | - Zone 2 (192.168.100.0/24) via eth2                                   |
  |                                                                        |
  | Firewall blocks:                                                       |
  | - Direct Zone 3 to Zone 2 traffic DENIED                               |
  | - All traffic must pass through WALLIX                                 |
  +------------------------------------------------------------------------+

+==============================================================================+
```

---

## Jump Host Hardening

### Minimal OS Installation

```
+==============================================================================+
|                    JUMP HOST HARDENING                                       |
+==============================================================================+

  MINIMAL OS INSTALLATION
  =======================

  +------------------------------------------------------------------------+
  | WINDOWS JUMP HOST HARDENING                                            |
  +------------------------------------------------------------------------+
  |                                                                        |
  | Base Installation:                                                     |
  | * Windows Server 2022 or Windows 10/11 LTSC                            |
  | * Core installation (no desktop experience) if possible                |
  | * Minimal features installed                                           |
  |                                                                        |
  | Remove/Disable:                                                        |
  | * Internet Explorer/Edge                                               |
  | * Windows Media Player                                                 |
  | * PowerShell v2 (keep v5+)                                             |
  | * SMBv1                                                                |
  | * Unused network protocols                                             |
  | * Print spooler service                                                |
  | * Remote registry service                                              |
  |                                                                        |
  +------------------------------------------------------------------------+

  +------------------------------------------------------------------------+
  | # PowerShell commands for Windows hardening                            |
  |                                                                        |
  | # Disable SMBv1                                                        |
  | Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol       |
  |                                                                        |
  | # Disable PowerShell v2                                                |
  | Disable-WindowsOptionalFeature -Online `                               |
  |   -FeatureName MicrosoftWindowsPowerShellV2Root                        |
  |                                                                        |
  | # Disable print spooler                                                |
  | Stop-Service -Name Spooler                                             |
  | Set-Service -Name Spooler -StartupType Disabled                        |
  |                                                                        |
  | # Disable remote registry                                              |
  | Stop-Service -Name RemoteRegistry                                      |
  | Set-Service -Name RemoteRegistry -StartupType Disabled                 |
  +------------------------------------------------------------------------+

  +------------------------------------------------------------------------+
  | LINUX JUMP HOST HARDENING                                              |
  +------------------------------------------------------------------------+
  |                                                                        |
  | Base Installation:                                                     |
  | * Debian 12 or RHEL 9 minimal                                          |
  | * No GUI                                                               |
  | * SSH server only                                                      |
  |                                                                        |
  | Remove/Disable:                                                        |
  | * X11 forwarding                                                       |
  | * Avahi/mDNS                                                           |
  | * CUPS                                                                 |
  | * Bluetooth                                                            |
  | * Unused network services                                              |
  |                                                                        |
  +------------------------------------------------------------------------+

  +------------------------------------------------------------------------+
  | # Debian/Ubuntu hardening commands                                     |
  |                                                                        |
  | # Remove unnecessary packages                                          |
  | apt purge avahi-daemon cups bluetooth                                  |
  |                                                                        |
  | # Disable X11 forwarding in SSH                                        |
  | sed -i 's/X11Forwarding yes/X11Forwarding no/' /etc/ssh/sshd_config    |
  |                                                                        |
  | # Disable IPv6 if not needed                                           |
  | echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf          |
  | sysctl -p                                                              |
  +------------------------------------------------------------------------+

+==============================================================================+
```

### No Internet Access Configuration

```
+==============================================================================+
|                    NO INTERNET ACCESS                                        |
+==============================================================================+

  Jump hosts in OT environments must not have internet access.

  --------------------------------------------------------------------------

  NETWORK ISOLATION
  =================

  +------------------------------------------------------------------------+
  |                                                                        |
  |   JUMP HOST NETWORK CONFIGURATION                                      |
  |                                                                        |
  |   +-----------------------------------------------------------+        |
  |   |               JUMP HOST                                    |        |
  |   |                                                            |        |
  |   |   NIC 1: Management (WALLIX access)                       |        |
  |   |   - IP: 172.16.10.50/24                                   |        |
  |   |   - Gateway: 172.16.10.1 (to WALLIX only)                 |        |
  |   |   - DNS: None or local only                               |        |
  |   |                                                            |        |
  |   |   NIC 2: OT Network (PLC/HMI access)                      |        |
  |   |   - IP: 192.168.1.50/24                                   |        |
  |   |   - Gateway: None                                         |        |
  |   |   - DNS: None                                             |        |
  |   |                                                            |        |
  |   +-----------------------------------------------------------+        |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  FIREWALL RULES ON JUMP HOST
  ============================

  Windows Firewall:

  +------------------------------------------------------------------------+
  | # Block all outbound except WALLIX and OT devices                      |
  |                                                                        |
  | netsh advfirewall set allprofiles firewallpolicy blockinbound,         |
  |   blockoutbound                                                        |
  |                                                                        |
  | # Allow RDP from WALLIX                                                |
  | netsh advfirewall firewall add rule name="Allow WALLIX RDP"            |
  |   dir=in action=allow protocol=tcp localport=3389                      |
  |   remoteip=172.16.10.10                                                |
  |                                                                        |
  | # Allow outbound to OT network only                                    |
  | netsh advfirewall firewall add rule name="Allow OT Modbus"             |
  |   dir=out action=allow protocol=tcp remoteport=502                     |
  |   remoteip=192.168.1.0/24                                              |
  |                                                                        |
  | netsh advfirewall firewall add rule name="Allow OT S7comm"             |
  |   dir=out action=allow protocol=tcp remoteport=102                     |
  |   remoteip=192.168.1.0/24                                              |
  +------------------------------------------------------------------------+

  Linux iptables:

  +------------------------------------------------------------------------+
  | # Default deny                                                         |
  | iptables -P INPUT DROP                                                 |
  | iptables -P OUTPUT DROP                                                |
  | iptables -P FORWARD DROP                                               |
  |                                                                        |
  | # Allow SSH from WALLIX                                                |
  | iptables -A INPUT -s 172.16.10.10 -p tcp --dport 22 -j ACCEPT          |
  | iptables -A OUTPUT -d 172.16.10.10 -p tcp --sport 22 -j ACCEPT         |
  |                                                                        |
  | # Allow Modbus to OT network                                           |
  | iptables -A OUTPUT -d 192.168.1.0/24 -p tcp --dport 502 -j ACCEPT      |
  | iptables -A INPUT -s 192.168.1.0/24 -p tcp --sport 502 -j ACCEPT       |
  |                                                                        |
  | # Save rules                                                           |
  | iptables-save > /etc/iptables/rules.v4                                 |
  +------------------------------------------------------------------------+

+==============================================================================+
```

### File Transfer Restrictions

```
+==============================================================================+
|                    FILE TRANSFER RESTRICTIONS                                |
+==============================================================================+

  Prevent unauthorized data movement through jump hosts.

  --------------------------------------------------------------------------

  RDP FILE TRANSFER RESTRICTIONS
  ==============================

  Configure WALLIX to disable RDP file transfer features:

  +------------------------------------------------------------------------+
  | wabadmin service update JUMP-HOST-01/RDP                               |
  |   --rdp-drive-mapping disabled                                         |
  |   --rdp-clipboard disabled                                             |
  |   --rdp-printer-mapping disabled                                       |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  SSH FILE TRANSFER RESTRICTIONS
  ==============================

  Configure WALLIX to block SCP/SFTP:

  +------------------------------------------------------------------------+
  | wabadmin authorization update eng-access                               |
  |   --subprotocols "SSH_SHELL_SESSION"                                   |
  |   --deny-subprotocols "SSH_SCP_UP,SSH_SCP_DOWN,SSH_SFTP_SESSION"       |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  USB RESTRICTIONS ON JUMP HOST
  =============================

  Windows:

  +------------------------------------------------------------------------+
  | # Group Policy: Disable USB storage                                    |
  | # Computer Configuration > Administrative Templates > System >         |
  | # Removable Storage Access                                             |
  | # Set "All Removable Storage classes: Deny all access" = Enabled       |
  |                                                                        |
  | # Registry (alternative):                                              |
  | reg add "HKLM\SYSTEM\CurrentControlSet\Services\USBSTOR"               |
  |   /v Start /t REG_DWORD /d 4 /f                                        |
  +------------------------------------------------------------------------+

  Linux:

  +------------------------------------------------------------------------+
  | # Blacklist USB storage module                                         |
  | echo "blacklist usb-storage" >> /etc/modprobe.d/blacklist.conf         |
  |                                                                        |
  | # Or use udev rules to disable                                         |
  | echo 'ACTION=="add", SUBSYSTEMS=="usb", DRIVERS=="usb-storage",        |
  |   ATTR{authorized}="0"' >> /etc/udev/rules.d/99-no-usb-storage.rules   |
  +------------------------------------------------------------------------+

+==============================================================================+
```

---

## Session Recording Through Jump Host

### Recording SSH Tunnels

```
+==============================================================================+
|                    RECORDING SSH TUNNELS                                     |
+==============================================================================+

  SSH tunnel recording captures connection metadata but not tunneled content.

  --------------------------------------------------------------------------

  WHAT IS RECORDED
  ================

  +------------------+---------------------------------------------------+
  | Component        | Captured                                          |
  +------------------+---------------------------------------------------+
  | Authentication   | User, time, source IP, MFA status                 |
  +------------------+---------------------------------------------------+
  | Shell session    | All commands typed, output displayed              |
  +------------------+---------------------------------------------------+
  | Tunnel setup     | Local/remote port, destination IP                 |
  +------------------+---------------------------------------------------+
  | Connection time  | Tunnel duration, bytes transferred                |
  +------------------+---------------------------------------------------+
  | Tunnel content   | NOT captured (encrypted)                          |
  +------------------+---------------------------------------------------+

  --------------------------------------------------------------------------

  ENHANCED RECORDING WITH RDP
  ===========================

  For full visibility of tunneled protocol usage, use RDP to a workstation:

  +------------------------------------------------------------------------+
  |                                                                        |
  |   OPTION 1: SSH Tunnel (Limited Recording)                             |
  |   =========================================                            |
  |                                                                        |
  |   [Engineer] --> [SSH Tunnel] --> [Modbus Client] --> [PLC]            |
  |                       |                                                |
  |                   Recorded: Tunnel metadata only                       |
  |                   NOT Recorded: Modbus register reads/writes           |
  |                                                                        |
  +------------------------------------------------------------------------+

  +------------------------------------------------------------------------+
  |                                                                        |
  |   OPTION 2: RDP to Workstation (Full Recording)                        |
  |   =============================================                        |
  |                                                                        |
  |   [Engineer] --> [RDP Session] --> [Workstation] --> [PLC]             |
  |                       |                   |                            |
  |                   Recorded:               |                            |
  |                   * All screen activity   |                            |
  |                   * Modbus client visible |                            |
  |                   * Register values shown |                            |
  |                   * Changes visible       |                            |
  |                                                                        |
  +------------------------------------------------------------------------+

  RECOMMENDATION: Use RDP to engineering workstation for PLC access
  to capture full visual recording of all actions.

+==============================================================================+
```

### RDP Recording Quality

```
+==============================================================================+
|                    RDP RECORDING QUALITY                                     |
+==============================================================================+

  Configure RDP recording for optimal OT session capture.

  --------------------------------------------------------------------------

  RECORDING CONFIGURATION
  =======================

  +------------------------------------------------------------------------+
  | # /etc/opt/wab/wabengine/wabengine.conf                                |
  |                                                                        |
  | [rdp]                                                                  |
  | recording_enabled = true                                               |
  |                                                                        |
  | # Video settings                                                       |
  | video_codec = h264                                                     |
  | video_quality = high                 # low, medium, high               |
  | video_frame_rate = 10                # frames per second               |
  | video_keyframe_interval = 5          # keyframes for seeking           |
  |                                                                        |
  | # OCR settings (for text extraction)                                   |
  | ocr_enabled = true                                                     |
  | ocr_language = en                                                      |
  | ocr_interval = 5                     # seconds between OCR             |
  |                                                                        |
  | # Storage                                                              |
  | recording_path = /var/wab/recordings                                   |
  | recording_retention_days = 365                                         |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  QUALITY SETTINGS FOR OT
  =======================

  +------------------+----------------------+---------------------------------+
  | Setting          | OT Recommendation    | Rationale                       |
  +------------------+----------------------+---------------------------------+
  | video_quality    | high                 | Capture HMI detail              |
  +------------------+----------------------+---------------------------------+
  | frame_rate       | 10                   | Balance quality/storage         |
  +------------------+----------------------+---------------------------------+
  | OCR              | enabled              | Search recordings by text       |
  +------------------+----------------------+---------------------------------+
  | retention        | 365+ days            | Regulatory compliance           |
  +------------------+----------------------+---------------------------------+

  --------------------------------------------------------------------------

  STORAGE ESTIMATION
  ==================

  +------------------------------------------------------------------------+
  | Session Duration | Quality | Approx Size | Notes                       |
  +------------------+---------+-------------+-----------------------------+
  | 1 hour           | Low     | 50-100 MB   | Limited detail              |
  | 1 hour           | Medium  | 100-200 MB  | Standard operations         |
  | 1 hour           | High    | 200-500 MB  | Engineering/HMI work        |
  +------------------+---------+-------------+-----------------------------+

  Annual storage for active OT environment:
  * 10 concurrent sessions
  * 8 hours/day
  * 250 workdays
  * High quality

  Estimate: 10 x 8 x 250 x 350MB = ~7 TB/year

+==============================================================================+
```

### Metadata Capture

```
+==============================================================================+
|                    SESSION METADATA CAPTURE                                  |
+==============================================================================+

  Metadata enriches session recordings for audit and search.

  --------------------------------------------------------------------------

  CAPTURED METADATA
  =================

  +------------------+---------------------------------------------------+
  | Category         | Data Points                                       |
  +------------------+---------------------------------------------------+
  | User             | * Username                                        |
  |                  | * User groups                                     |
  |                  | * Source IP address                               |
  |                  | * MFA method used                                 |
  +------------------+---------------------------------------------------+
  | Target           | * Device name                                     |
  |                  | * Device IP                                       |
  |                  | * Service/protocol                                |
  |                  | * Account used                                    |
  +------------------+---------------------------------------------------+
  | Session          | * Start time (UTC)                                |
  |                  | * End time (UTC)                                  |
  |                  | * Duration                                        |
  |                  | * Termination reason                              |
  +------------------+---------------------------------------------------+
  | Authorization    | * Authorization name                              |
  |                  | * Approval status                                 |
  |                  | * Approver (if approved)                          |
  |                  | * Ticket/comment                                  |
  +------------------+---------------------------------------------------+
  | Content          | * OCR text (if enabled)                           |
  |                  | * Typed commands (SSH)                            |
  |                  | * Clipboard content (if allowed)                  |
  +------------------+---------------------------------------------------+

  --------------------------------------------------------------------------

  SEARCHING RECORDINGS
  ====================

  +------------------------------------------------------------------------+
  | # Search by user                                                       |
  | wabadmin recordings search --user jsmith                               |
  |                                                                        |
  | # Search by target                                                     |
  | wabadmin recordings search --device "PLC-*"                            |
  |                                                                        |
  | # Search by date range                                                 |
  | wabadmin recordings search --from "2024-01-01" --to "2024-01-31"       |
  |                                                                        |
  | # Search by OCR text (find sessions with specific register)            |
  | wabadmin recordings search --text "MW100"                              |
  |                                                                        |
  | # Search by typed command                                              |
  | wabadmin recordings search --command "modbus write"                    |
  +------------------------------------------------------------------------+

+==============================================================================+
```

---

## Network Configuration

### Multiple NICs for Zone Separation

```
+==============================================================================+
|                    MULTI-NIC JUMP HOST CONFIGURATION                         |
+==============================================================================+

  Jump hosts often require multiple network interfaces for zone separation.

  --------------------------------------------------------------------------

  ARCHITECTURE
  ============


       +------------------------------------------------------------------+
       |                       JUMP HOST                                  |
       |                                                                  |
       |   +------------+     +------------+     +------------+          |
       |   |   NIC 1    |     |   NIC 2    |     |   NIC 3    |          |
       |   | Management |     | Control Net|     | Field Net  |          |
       |   +------+-----+     +------+-----+     +------+-----+          |
       |          |                  |                  |                |
       +----------|------------------|------------------|----------------+
                  |                  |                  |
                  v                  v                  v
       +----------+---+    +---------+----+    +-------+------+
       |              |    |              |    |              |
       | OT DMZ       |    | Control Zone |    | Field Zone   |
       | 172.16.0.0/24|    |192.168.10.0/24   |192.168.100.0/24
       |              |    |              |    |              |
       | WALLIX       |    | SCADA        |    | PLCs         |
       | Bastion      |    | HMI          |    | RTUs         |
       +--------------+    +--------------+    +--------------+


  --------------------------------------------------------------------------

  WINDOWS NETWORK CONFIGURATION
  =============================

  +------------------------------------------------------------------------+
  | # Configure NICs via PowerShell                                        |
  |                                                                        |
  | # NIC 1: Management (to WALLIX)                                        |
  | New-NetIPAddress -InterfaceAlias "Management"                          |
  |   -IPAddress 172.16.10.50 -PrefixLength 24 -DefaultGateway 172.16.10.1 |
  |                                                                        |
  | # NIC 2: Control Network (no gateway - local only)                     |
  | New-NetIPAddress -InterfaceAlias "Control"                             |
  |   -IPAddress 192.168.10.50 -PrefixLength 24                            |
  |                                                                        |
  | # NIC 3: Field Network (no gateway - local only)                       |
  | New-NetIPAddress -InterfaceAlias "Field"                               |
  |   -IPAddress 192.168.100.50 -PrefixLength 24                           |
  |                                                                        |
  | # Disable DNS registration for OT interfaces                           |
  | Set-DnsClient -InterfaceAlias "Control" -RegisterThisConnectionsAddress $false
  | Set-DnsClient -InterfaceAlias "Field" -RegisterThisConnectionsAddress $false
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  LINUX NETWORK CONFIGURATION
  ===========================

  +------------------------------------------------------------------------+
  | # /etc/network/interfaces (Debian)                                     |
  |                                                                        |
  | # Management interface                                                 |
  | auto eth0                                                              |
  | iface eth0 inet static                                                 |
  |     address 172.16.10.50                                               |
  |     netmask 255.255.255.0                                              |
  |     gateway 172.16.10.1                                                |
  |                                                                        |
  | # Control network (no gateway)                                         |
  | auto eth1                                                              |
  | iface eth1 inet static                                                 |
  |     address 192.168.10.50                                              |
  |     netmask 255.255.255.0                                              |
  |                                                                        |
  | # Field network (no gateway)                                           |
  | auto eth2                                                              |
  | iface eth2 inet static                                                 |
  |     address 192.168.100.50                                             |
  |     netmask 255.255.255.0                                              |
  +------------------------------------------------------------------------+

+==============================================================================+
```

### Routing for Industrial Networks

```
+==============================================================================+
|                    ROUTING CONFIGURATION                                     |
+==============================================================================+

  Proper routing ensures traffic flows through correct interfaces.

  --------------------------------------------------------------------------

  ROUTING TABLE DESIGN
  ====================

  +------------------------------------------------------------------------+
  | Destination          | Gateway       | Interface   | Purpose           |
  +----------------------+---------------+-------------+-------------------+
  | 0.0.0.0/0            | 172.16.10.1   | eth0        | Default (WALLIX)  |
  | 192.168.10.0/24      | direct        | eth1        | Control zone      |
  | 192.168.100.0/24     | direct        | eth2        | Field zone        |
  | 172.16.10.0/24       | direct        | eth0        | Management        |
  +----------------------+---------------+-------------+-------------------+

  --------------------------------------------------------------------------

  WINDOWS ROUTING
  ===============

  +------------------------------------------------------------------------+
  | # View routing table                                                   |
  | route print                                                            |
  |                                                                        |
  | # Add persistent route to remote OT subnet                             |
  | route -p add 192.168.200.0 mask 255.255.255.0 192.168.100.1            |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  LINUX ROUTING
  =============

  +------------------------------------------------------------------------+
  | # View routing table                                                   |
  | ip route show                                                          |
  |                                                                        |
  | # Add route to remote OT subnet                                        |
  | ip route add 192.168.200.0/24 via 192.168.100.1 dev eth2               |
  |                                                                        |
  | # Make persistent (Debian)                                             |
  | echo "up ip route add 192.168.200.0/24 via 192.168.100.1"              |
  |   >> /etc/network/interfaces                                           |
  +------------------------------------------------------------------------+

+==============================================================================+
```

### DNS for Industrial Devices

```
+==============================================================================+
|                    DNS FOR INDUSTRIAL DEVICES                                |
+==============================================================================+

  OT environments often use static IPs, but DNS can simplify management.

  --------------------------------------------------------------------------

  OT DNS DESIGN
  =============

  +------------------------------------------------------------------------+
  |                                                                        |
  |   OT DNS Architecture                                                  |
  |   ===================                                                  |
  |                                                                        |
  |   +------------------+                                                 |
  |   |   OT DNS Server  |                                                 |
  |   |   (Local only)   |                                                 |
  |   |                  |                                                 |
  |   |   Zone: ot.local |                                                 |
  |   +------------------+                                                 |
  |            |                                                           |
  |            | Queries                                                   |
  |            v                                                           |
  |   +------------------+                                                 |
  |   |   WALLIX         |                                                 |
  |   |   Jump Hosts     |                                                 |
  |   |   OT Devices     |                                                 |
  |   +------------------+                                                 |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  DNS RECORDS FOR OT
  ==================

  +------------------------------------------------------------------------+
  | # Example OT DNS zone file                                             |
  |                                                                        |
  | $ORIGIN ot.local.                                                      |
  | $TTL 3600                                                              |
  |                                                                        |
  | ; PAM Infrastructure                                                   |
  | wallix-bastion      IN A    172.16.10.10                               |
  | jump-host-eng       IN A    172.16.10.50                               |
  |                                                                        |
  | ; SCADA Systems                                                        |
  | scada-server-01     IN A    192.168.10.10                              |
  | scada-server-02     IN A    192.168.10.11                              |
  | historian-01        IN A    192.168.10.20                              |
  |                                                                        |
  | ; HMI Stations                                                         |
  | hmi-control-room-01 IN A    192.168.10.30                              |
  | hmi-control-room-02 IN A    192.168.10.31                              |
  |                                                                        |
  | ; PLCs                                                                 |
  | plc-pump-station-01 IN A    192.168.100.10                             |
  | plc-pump-station-02 IN A    192.168.100.11                             |
  | plc-compressor-01   IN A    192.168.100.20                             |
  |                                                                        |
  | ; RTUs                                                                 |
  | rtu-substation-a    IN A    192.168.100.50                             |
  | rtu-substation-b    IN A    192.168.100.51                             |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  JUMP HOST DNS CONFIGURATION
  ===========================

  +------------------------------------------------------------------------+
  | # Windows: Configure DNS for OT interface only                         |
  | Set-DnsClientServerAddress -InterfaceAlias "Control"                   |
  |   -ServerAddresses "192.168.10.5"                                      |
  |                                                                        |
  | # Linux: /etc/resolv.conf                                              |
  | search ot.local                                                        |
  | nameserver 192.168.10.5                                                |
  +------------------------------------------------------------------------+

+==============================================================================+
```

---

## Troubleshooting

### Tunnel Connectivity Issues

```
+==============================================================================+
|                    TUNNEL TROUBLESHOOTING                                    |
+==============================================================================+

  COMMON SSH TUNNEL ISSUES
  ========================

  +------------------+---------------------------------------------------+
  | Symptom          | Cause / Solution                                  |
  +------------------+---------------------------------------------------+
  | "Connection      | 1. Firewall blocking port                         |
  | refused" on      | 2. Target service not running                     |
  | tunnel port      | 3. Wrong destination IP/port                      |
  |                  |                                                   |
  |                  | Debug:                                            |
  |                  | ssh -v -L 5502:192.168.1.50:502 user@wallix       |
  +------------------+---------------------------------------------------+
  | Tunnel connects  | 1. Tunnel endpoint firewall                       |
  | but no data      | 2. Protocol mismatch                              |
  |                  | 3. Application-level issue                        |
  |                  |                                                   |
  |                  | Debug: Test with netcat                           |
  |                  | nc -zv localhost 5502                             |
  +------------------+---------------------------------------------------+
  | "Permission      | 1. Port < 1024 requires root                      |
  | denied" binding  | 2. Port already in use                            |
  | local port       |                                                   |
  |                  | Solution: Use port > 1024                         |
  |                  | ssh -L 5502:... instead of -L 502:...             |
  +------------------+---------------------------------------------------+
  | Tunnel drops     | 1. SSH timeout                                    |
  | after idle       | 2. Firewall idle timeout                          |
  |                  |                                                   |
  |                  | Solution: Add SSH keepalive                       |
  |                  | ssh -o ServerAliveInterval=60 ...                 |
  +------------------+---------------------------------------------------+

  --------------------------------------------------------------------------

  DIAGNOSTIC COMMANDS
  ===================

  +------------------------------------------------------------------------+
  | # Test SSH connectivity to WALLIX                                      |
  | ssh -v user@wallix.company.com                                         |
  |                                                                        |
  | # Test if tunnel port is listening                                     |
  | netstat -an | grep 5502                                                |
  | ss -tlnp | grep 5502                                                   |
  |                                                                        |
  | # Test connectivity through tunnel                                     |
  | nc -zv localhost 5502                                                  |
  |                                                                        |
  | # Test Modbus through tunnel                                           |
  | modpoll -m tcp -a 1 -r 1 -c 1 127.0.0.1:5502                           |
  +------------------------------------------------------------------------+

+==============================================================================+
```

### Protocol-Specific Problems

```
+==============================================================================+
|                    PROTOCOL-SPECIFIC TROUBLESHOOTING                         |
+==============================================================================+

  MODBUS TCP ISSUES
  =================

  +------------------+---------------------------------------------------+
  | Error            | Cause / Solution                                  |
  +------------------+---------------------------------------------------+
  | Exception 01     | Illegal function - PLC doesn't support command    |
  | (Illegal Func)   | Check PLC Modbus configuration                    |
  +------------------+---------------------------------------------------+
  | Exception 02     | Illegal data address - register doesn't exist     |
  | (Illegal Addr)   | Verify register mapping                           |
  +------------------+---------------------------------------------------+
  | Exception 03     | Illegal data value - value out of range           |
  | (Illegal Value)  | Check data type and limits                        |
  +------------------+---------------------------------------------------+
  | Timeout          | 1. Wrong IP/port                                  |
  |                  | 2. Firewall blocking                              |
  |                  | 3. PLC not responding                             |
  +------------------+---------------------------------------------------+

  --------------------------------------------------------------------------

  S7COMM (SIEMENS) ISSUES
  =======================

  +------------------+---------------------------------------------------+
  | Error            | Cause / Solution                                  |
  +------------------+---------------------------------------------------+
  | Connection       | 1. Wrong rack/slot configuration                  |
  | refused          | 2. PLC in STOP mode                               |
  |                  | 3. Firewall blocking port 102                     |
  +------------------+---------------------------------------------------+
  | Access denied    | 1. Protection level too high                      |
  |                  | 2. Password required                              |
  |                  | Check TIA Portal project settings                 |
  +------------------+---------------------------------------------------+
  | Inconsistent     | 1. Project/PLC mismatch                           |
  | program          | 2. Online changes not synchronized                |
  +------------------+---------------------------------------------------+

  --------------------------------------------------------------------------

  RDP ISSUES
  ==========

  +------------------+---------------------------------------------------+
  | Error            | Cause / Solution                                  |
  +------------------+---------------------------------------------------+
  | "CredSSP"        | 1. NLA mismatch                                   |
  | error            | 2. Certificate issue                              |
  |                  | Check WALLIX RDP service settings                 |
  +------------------+---------------------------------------------------+
  | Black screen     | 1. GPU/display driver issue                       |
  |                  | 2. RemoteFX incompatibility                       |
  |                  | Disable hardware graphics in RDP                  |
  +------------------+---------------------------------------------------+
  | Slow             | 1. Network bandwidth                              |
  | performance      | 2. Too many visual effects                        |
  |                  | Reduce color depth, disable animations            |
  +------------------+---------------------------------------------------+

+==============================================================================+
```

### Recording Gaps

```
+==============================================================================+
|                    RECORDING TROUBLESHOOTING                                 |
+==============================================================================+

  COMMON RECORDING ISSUES
  =======================

  +------------------+---------------------------------------------------+
  | Issue            | Cause / Solution                                  |
  +------------------+---------------------------------------------------+
  | Recording        | 1. Check authorization is_recorded setting        |
  | not starting     | 2. Verify disk space on recording storage         |
  |                  | 3. Check wabengine service status                 |
  |                  |                                                   |
  |                  | wabadmin recording-status                         |
  +------------------+---------------------------------------------------+
  | Recording        | 1. Network interruption                           |
  | gaps/drops       | 2. High load on Bastion                           |
  |                  | 3. Storage performance issues                     |
  |                  |                                                   |
  |                  | Check: /var/log/wab/wabengine.log                 |
  +------------------+---------------------------------------------------+
  | Poor video       | 1. Codec settings                                 |
  | quality          | 2. Frame rate too low                             |
  |                  | 3. Network bandwidth                              |
  |                  |                                                   |
  |                  | Adjust: wabengine.conf [rdp_recording]            |
  +------------------+---------------------------------------------------+
  | OCR not          | 1. OCR not enabled                                |
  | working          | 2. Language pack missing                          |
  |                  | 3. Text not clear in recording                    |
  +------------------+---------------------------------------------------+

  --------------------------------------------------------------------------

  DIAGNOSTIC COMMANDS
  ===================

  +------------------------------------------------------------------------+
  | # Check recording service status                                       |
  | systemctl status wab-recording                                         |
  |                                                                        |
  | # Check recording storage                                              |
  | df -h /var/wab/recordings                                              |
  |                                                                        |
  | # List recent recordings                                               |
  | wabadmin recordings list --last 10                                     |
  |                                                                        |
  | # Verify recording integrity                                           |
  | wabadmin recordings verify --id <recording-id>                         |
  |                                                                        |
  | # Check recording logs                                                 |
  | tail -f /var/log/wab/recording.log                                     |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  STORAGE MANAGEMENT
  ==================

  +------------------------------------------------------------------------+
  | # Check recording retention policy                                     |
  | wabadmin config get recording.retention_days                           |
  |                                                                        |
  | # Manually archive old recordings                                      |
  | wabadmin recordings archive --before "2023-01-01"                      |
  |                                                                        |
  | # Export recording for analysis                                        |
  | wabadmin recordings export --id <id> --format mp4 --output /tmp/       |
  +------------------------------------------------------------------------+

+==============================================================================+
```

---

## References

### Official WALLIX Documentation

- WALLIX Bastion Administration Guide: https://pam.wallix.one/documentation/admin-doc/bastion_en_administration_guide.pdf
- WALLIX Bastion User Guide: https://pam.wallix.one/documentation/user-doc/bastion_en_user_guide.pdf
- WALLIX REST API Samples: https://github.com/wallix/wbrest_samples

### Industrial Security Standards

- IEC 62443: Industrial Automation and Control Systems Security
- NIST SP 800-82: Guide to Industrial Control Systems Security
- ISA/IEC 62443-3-3: Security for Industrial Automation and Control Systems

### Related Documentation

- [16 - OT Architecture & Deployment](../16-ot-architecture/README.md)
- [17 - Industrial Protocols](../17-industrial-protocols/README.md)
- [18 - SCADA/ICS Access Management](../18-scada-ics-access/README.md)
- [19 - Air-Gapped Environments](../19-airgapped-environments/README.md)
- [20 - IEC 62443 Compliance](../20-iec62443-compliance/README.md)

---

## Next Steps

Continue to [20 - IEC 62443 Compliance](../20-iec62443-compliance/README.md) for detailed compliance mapping with industrial security standards.
