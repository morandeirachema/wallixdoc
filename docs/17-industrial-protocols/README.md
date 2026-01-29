# 17 - Industrial Protocols

## Table of Contents

1. [Industrial Protocol Overview](#industrial-protocol-overview)
2. [Modbus Protocol](#modbus-protocol)
3. [DNP3 Protocol](#dnp3-protocol)
4. [OPC UA/DA](#opc-uada)
5. [Ethernet/IP & CIP](#ethernetip--cip)
6. [IEC 61850](#iec-61850)
7. [BACnet](#bacnet)
8. [Proprietary Protocols](#proprietary-protocols)
9. [Protocol Security Considerations](#protocol-security-considerations)

---

## Industrial Protocol Overview

### Protocol Landscape

```
+===============================================================================+
|                    INDUSTRIAL PROTOCOL LANDSCAPE                              |
+===============================================================================+
|                                                                               |
|  PROTOCOL CATEGORIES                                                          |
|  ===================                                                          |
|                                                                               |
|  +-----------------------------------------------------------------------+ |
|  | FIELDBUS PROTOCOLS (Level 0-1)                                           | |
|  | ---------------------------------                                        | |
|  | * Modbus RTU/ASCII (Serial)                                              | |
|  | * PROFIBUS                                                               | |
|  | * DeviceNet                                                              | |
|  | * HART                                                                   | |
|  | * Foundation Fieldbus                                                    | |
|  +-----------------------------------------------------------------------+ |
|                                                                               |
|  +-----------------------------------------------------------------------+ |
|  | INDUSTRIAL ETHERNET (Level 1-3)                                          | |
|  | --------------------------------                                         | |
|  | * Modbus TCP                                                             | |
|  | * EtherNet/IP (CIP)                                                      | |
|  | * PROFINET                                                               | |
|  | * OPC UA / OPC DA                                                        | |
|  | * DNP3 (TCP only - UDP not supported)                                    | |
|  | * IEC 61850 (MMS, GOOSE)                                                | |
|  | * BACnet/IP                                                              | |
|  | * EtherCAT                                                               | |
|  +-----------------------------------------------------------------------+ |
|                                                                               |
|  +-----------------------------------------------------------------------+ |
|  | APPLICATION PROTOCOLS (Level 2-4)                                        | |
|  | ---------------------------------                                        | |
|  | * OPC UA (unified architecture)                                          | |
|  | * MQTT (IIoT)                                                           | |
|  | * AMQP                                                                   | |
|  | * REST/HTTP APIs                                                         | |
|  +-----------------------------------------------------------------------+ |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  WALLIX PROTOCOL SUPPORT MATRIX                                               |
|  ==============================                                               |
|                                                                               |
|  +------------------+-------------+----------------+------------------------+|
|  | Protocol         | Session     | Recording      | Notes                  ||
|  |                  | Proxy       | Support        |                        ||
|  +------------------+-------------+----------------+------------------------+|
|  | SSH              | [x] Native    | [x] Full         | Primary admin protocol ||
|  | RDP              | [x] Native    | [x] Full + OCR   | HMI/SCADA access       ||
|  | VNC              | [x] Native    | [x] Full         | Older HMI systems      ||
|  | Telnet           | [x] Native    | [x] Full         | Legacy devices         ||
|  | HTTP/HTTPS       | [x] Native    | [x] Screenshots  | Web HMI, OPC UA        ||
|  | Modbus TCP       | [x] Via SSH   | [x] Via session  | Through jump host      ||
|  | EtherNet/IP      | [x] Via SSH   | [x] Via session  | Through jump host      ||
|  | OPC UA           | [x] HTTPS     | [x] Via session  | Modern interface       ||
|  | Custom TCP       | [x] Tunnel    | [x] Basic        | Port forwarding        ||
|  +------------------+-------------+----------------+------------------------+|
|                                                                               |
+===============================================================================+
```

### Protocol Stack in OT

```
+===============================================================================+
|                    OT PROTOCOL STACK                                          |
+===============================================================================+
|                                                                               |
|  OSI LAYER MAPPING                                                            |
|  =================                                                            |
|                                                                               |
|  +-----------------------------------------------------------------------+ |
|  | Layer 7    | OPC UA | Modbus App | DNP3 App | CIP    | BACnet | MMS    | |
|  | Application|        |            |          |        |        |        | |
|  +------------+--------+------------+----------+--------+--------+--------+ |
|  | Layer 6    |                                                            | |
|  | Presentation                      (often combined)                      | |
|  +------------+------------------------------------------------------------+ |
|  | Layer 5    |                                                            | |
|  | Session    |                      (often combined)                      | |
|  +------------+------------------------------------------------------------+ |
|  | Layer 4    | TCP                  | UDP                                 | |
|  | Transport  | (Modbus TCP, OPC UA) | (DNP3 UDP, BACnet)                  | |
|  +------------+----------------------+-------------------------------------+ |
|  | Layer 3    | IP (IPv4 typically, IPv6 emerging)                         | |
|  | Network    |                                                            | |
|  +------------+------------------------------------------------------------+ |
|  | Layer 2    | Ethernet | Serial (RS-232/485) | Industrial Ethernet      | |
|  | Data Link  |          |                     | (EtherNet/IP, PROFINET)  | |
|  +------------+----------+---------------------+---------------------------+ |
|  | Layer 1    | Copper | Fiber | Wireless | Serial                        | |
|  | Physical   |                                                            | |
|  +------------+------------------------------------------------------------+ |
|                                                                               |
|                                                                               |
|  WHERE WALLIX OPERATES                                                        |
|  =====================                                                        |
|                                                                               |
|                           +-------------------------+                        |
|                           |   WALLIX BASTION        |                        |
|                           |                         |                        |
|                           |   Operates at Layer 7   |                        |
|                           |   (Application Layer)   |                        |
|                           |                         |                        |
|                           |   * Protocol-aware      |                        |
|                           |     proxying            |                        |
|                           |   * Session inspection  |                        |
|                           |   * Credential injection|                        |
|                           |   * Command logging     |                        |
|                           +-------------------------+                        |
|                                                                               |
+===============================================================================+
```

---

## Modbus Protocol

### Modbus Overview

```
+===============================================================================+
|                    MODBUS PROTOCOL                                            |
+===============================================================================+
|                                                                               |
|  MODBUS VARIANTS                                                              |
|  ===============                                                              |
|                                                                               |
|  +-----------------+-----------------------------------------------------+   |
|  | Variant         | Description                                         |   |
|  +-----------------+-----------------------------------------------------+   |
|  | Modbus RTU      | Serial (RS-232/485), binary, CRC checksum          |   |
|  | Modbus ASCII    | Serial, ASCII encoding, LRC checksum               |   |
|  | Modbus TCP      | TCP/IP encapsulation, port 502                     |   |
|  | Modbus TCP/TLS  | Encrypted Modbus TCP (emerging)                    |   |
|  +-----------------+-----------------------------------------------------+   |
|                                                                               |
|  MODBUS TCP FRAME                                                             |
|  ===============                                                              |
|                                                                               |
|  +------------------------------------------------------------------------+  |
|  |                                                                         |  |
|  |  +----------+----------+----------+----------+----------+----------+  |  |
|  |  |Transaction| Protocol |  Length  |  Unit    | Function |   Data   |  |  |
|  |  |    ID    |    ID    |          |    ID    |   Code   |          |  |  |
|  |  |  2 bytes |  2 bytes |  2 bytes |  1 byte  |  1 byte  | N bytes  |  |  |
|  |  +----------+----------+----------+----------+----------+----------+  |  |
|  |                                                                         |  |
|  |  <-------------- MBAP Header --------------><---- PDU --------------> |  |
|  |                                                                         |  |
|  +------------------------------------------------------------------------+  |
|                                                                               |
|  COMMON FUNCTION CODES                                                        |
|  =====================                                                        |
|                                                                               |
|  +----------+------------------------------+-------------------------------+ |
|  | Code     | Function                     | Risk Level                    | |
|  +----------+------------------------------+-------------------------------+ |
|  | 0x01     | Read Coils                   | Low (read-only)               | |
|  | 0x02     | Read Discrete Inputs         | Low (read-only)               | |
|  | 0x03     | Read Holding Registers       | Low (read-only)               | |
|  | 0x04     | Read Input Registers         | Low (read-only)               | |
|  | 0x05     | Write Single Coil            | HIGH (control)                | |
|  | 0x06     | Write Single Register        | HIGH (control)                | |
|  | 0x0F     | Write Multiple Coils         | CRITICAL (bulk control)       | |
|  | 0x10     | Write Multiple Registers     | CRITICAL (bulk control)       | |
|  | 0x2B     | Read Device Identification   | Medium (reconnaissance)       | |
|  +----------+------------------------------+-------------------------------+ |
|                                                                               |
|  SECURITY CONCERNS                                                            |
|  =================                                                            |
|                                                                               |
|  WARNING: NO AUTHENTICATION - Anyone on network can issue commands            |
|  WARNING: NO ENCRYPTION - All traffic in clear text                           |
|  WARNING: NO INTEGRITY - Commands can be modified in transit                  |
|  WARNING: REPLAY ATTACKS - Valid commands can be captured and replayed        |
|                                                                               |
+===============================================================================+
```

### WALLIX with Modbus

```
+===============================================================================+
|                    WALLIX MODBUS ACCESS                                       |
+===============================================================================+
|                                                                               |
|  ARCHITECTURE                                                                 |
|  ============                                                                 |
|                                                                               |
|                                                                               |
|         +--------------+                                                     |
|         |  Engineer    |                                                     |
|         |  Workstation |                                                     |
|         +------+-------+                                                     |
|                |                                                              |
|                | SSH/RDP                                                      |
|                v                                                              |
|     +------------------------+                                               |
|     |    WALLIX BASTION      |                                               |
|     |                        |                                               |
|     |  * Authenticates user  |                                               |
|     |  * Authorizes access   |                                               |
|     |  * Records session     |                                               |
|     +-----------+------------+                                               |
|                 |                                                             |
|                 | SSH/RDP                                                     |
|                 v                                                             |
|     +------------------------+                                               |
|     |  Engineering Station   |                                               |
|     |  (Jump Host)           |                                               |
|     |                        |                                               |
|     |  +------------------+ |                                               |
|     |  | Modbus Client    | |                                               |
|     |  | (Programming SW) | |                                               |
|     |  +--------+---------+ |                                               |
|     +-----------+------------+                                               |
|                 |                                                             |
|                 | Modbus TCP (Port 502)                                       |
|                 v                                                             |
|     +------------------------+                                               |
|     |         PLC            |                                               |
|     |    (Modbus Server)     |                                               |
|     +------------------------+                                               |
|                                                                               |
|                                                                               |
|  SESSION RECORDING CAPTURES:                                                  |
|  ============================                                                 |
|                                                                               |
|  * User authentication to WALLIX                                             |
|  * Full session to Engineering Station                                       |
|  * Screen recording of Modbus client software                                |
|  * Commands entered in programming software                                  |
|  * All changes made visible in recording                                     |
|                                                                               |
+===============================================================================+
```

### Modbus WALLIX Configuration

```
+===============================================================================+
|                    WALLIX MODBUS DEVICE CONFIGURATION                        |
+===============================================================================+

  STEP 1: CREATE DOMAIN FOR OT DEVICES
  =====================================

  Domain Name: OT-Manufacturing
  Description: OT manufacturing floor PLCs and HMIs

  +------------------------------------------------------------------------+
  | wabadmin domain create OT-Manufacturing                                |
  |   --description "Manufacturing floor OT devices"                       |
  |   --admin-group "OT-Engineers"                                         |
  +------------------------------------------------------------------------+

  STEP 2: CREATE ENGINEERING STATION (JUMP HOST)
  ===============================================

  This is the Engineering Workstation with Modbus client software.

  +------------------------------------------------------------------------+
  | wabadmin device create ENG-STATION-01                                  |
  |   --domain OT-Manufacturing                                            |
  |   --host 10.100.10.50                                                  |
  |   --description "Engineering Station with Modbus/PLC Software"         |
  +------------------------------------------------------------------------+

  STEP 3: CREATE SERVICES FOR THE ENGINEERING STATION
  ====================================================

  +------------------------------------------------------------------------+
  | # RDP access for graphical PLC programming                             |
  | wabadmin service create ENG-STATION-01/RDP                             |
  |   --protocol rdp                                                       |
  |   --port 3389                                                          |
  |                                                                        |
  | # SSH access for command-line tools                                    |
  | wabadmin service create ENG-STATION-01/SSH                             |
  |   --protocol ssh                                                       |
  |   --port 22                                                            |
  +------------------------------------------------------------------------+

  STEP 4: CREATE ACCOUNT FOR ENGINEERING ACCESS
  ==============================================

  +------------------------------------------------------------------------+
  | wabadmin account create ENG-STATION-01/plc_engineer                    |
  |   --service RDP                                                        |
  |   --credentials auto-managed                                           |
  |   --description "PLC Engineer access to programming software"          |
  +------------------------------------------------------------------------+

  STEP 5: CREATE AUTHORIZATION FOR OT ENGINEERS
  ==============================================

  +------------------------------------------------------------------------+
  | wabadmin authorization create OT-Engineers-ModbusAccess                |
  |   --user-group OT-Engineers                                            |
  |   --target ENG-STATION-01/RDP/plc_engineer                             |
  |   --approval-required true                                             |
  |   --approval-group OT-Supervisors                                      |
  |   --time-restriction "MON-FRI 06:00-22:00"                             |
  |   --session-recording true                                             |
  |   --max-session-duration 4h                                            |
  +------------------------------------------------------------------------+

  STEP 6: NETWORK FIREWALL RULES
  ==============================

  Ensure firewall allows only WALLIX to reach Engineering Station:

  +------------------------------------------------------------------------+
  | # Block direct access to Engineering Station                           |
  | iptables -A INPUT -p tcp --dport 3389 -s ! <WALLIX-IP> -j DROP         |
  |                                                                        |
  | # Block direct Modbus from IT network                                  |
  | iptables -A FORWARD -p tcp --dport 502 -s 10.0.0.0/8 -j DROP           |
  |                                                                        |
  | # Allow Engineering Station to Modbus devices                          |
  | iptables -A FORWARD -p tcp --dport 502 -s 10.100.10.50 -j ACCEPT       |
  +------------------------------------------------------------------------+

+===============================================================================+

  VERIFICATION AND TROUBLESHOOTING
  =================================

  +------------------------------------------------------------------------+
  | # Test Modbus connectivity from Engineering Station                    |
  | modpoll -m tcp -a 1 -r 1 -c 5 <PLC-IP>                                 |
  |                                                                        |
  | # Common Modbus errors:                                                |
  | # - Connection refused: PLC not listening or wrong IP                  |
  | # - Timeout: Firewall blocking port 502                                |
  | # - Illegal function: PLC doesn't support function code                |
  | # - Illegal address: Register address doesn't exist                    |
  +------------------------------------------------------------------------+

+===============================================================================+
```

---

## DNP3 Protocol

### DNP3 Overview

```
+===============================================================================+
|                    DNP3 PROTOCOL                                              |
+===============================================================================+
|                                                                               |
|  DISTRIBUTED NETWORK PROTOCOL 3                                               |
|  ==============================                                               |
|                                                                               |
|  Primary use: SCADA communications (utilities, water, oil & gas)              |
|  Standard: IEEE 1815                                                          |
|  Transport: TCP (port 20000) or Serial                                       |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  DNP3 ARCHITECTURE                                                            |
|  =================                                                            |
|                                                                               |
|        +-------------------------------------------------------------+       |
|        |                    MASTER STATION                           |       |
|        |                    (SCADA Server)                           |       |
|        +----------------------------+--------------------------------+       |
|                                     |                                        |
|                                     | DNP3                                   |
|                                     |                                        |
|             +-----------------------+-----------------------+                |
|             |                       |                       |                |
|             v                       v                       v                |
|      +-------------+         +-------------+         +-------------+        |
|      |  OUTSTATION |         |  OUTSTATION |         |  OUTSTATION |        |
|      |   (RTU 1)   |         |   (RTU 2)   |         |   (RTU 3)   |        |
|      |             |         |             |         |             |        |
|      | Address: 1  |         | Address: 2  |         | Address: 3  |        |
|      +-------------+         +-------------+         +-------------+        |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  DNP3 DATA TYPES                                                              |
|  ===============                                                              |
|                                                                               |
|  +--------------------+-----------------------------------------------------+    |
|  | Data Type          | Description                                     |    |
|  +--------------------+-----------------------------------------------------+    |
|  | Binary Inputs      | On/off status (breaker, switch)                |    |
|  | Binary Outputs     | Control outputs (open/close commands)          |    |
|  | Analog Inputs      | Measured values (voltage, current, flow)       |    |
|  | Analog Outputs     | Setpoints (control values)                     |    |
|  | Counters           | Accumulated values (energy, events)            |    |
|  | Time Objects       | Time synchronization                           |    |
|  +--------------------+-----------------------------------------------------+    |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  DNP3 SECURE AUTHENTICATION                                                   |
|  ==========================                                                   |
|                                                                               |
|  DNP3-SA (Secure Authentication) v5 adds:                                    |
|  * Challenge-response authentication                                         |
|  * Message integrity (HMAC)                                                  |
|  * Anti-replay protection                                                    |
|  * Key management                                                            |
|                                                                               |
|  WARNING: Many legacy systems do NOT support SA                              |
|                                                                               |
+===============================================================================+
```

### WALLIX for DNP3 Environments

```
+===============================================================================+
|                    WALLIX DNP3 ACCESS CONTROL                                 |
+===============================================================================+
|                                                                               |
|  RECOMMENDED ARCHITECTURE                                                     |
|  ========================                                                     |
|                                                                               |
|                                                                               |
|         +-----------------+                                                  |
|         |  Control Center |                                                  |
|         |     Users       |                                                  |
|         +--------+--------+                                                  |
|                  |                                                            |
|         +--------+--------+                                                  |
|         | WALLIX BASTION  |                                                  |
|         |                 |                                                  |
|         | * RDP/SSH to    |                                                  |
|         |   SCADA Server  |                                                  |
|         | * Session       |                                                  |
|         |   recording     |                                                  |
|         +--------+--------+                                                  |
|                  |                                                            |
|         +--------+--------+                                                  |
|         |  SCADA Server   |                                                  |
|         |  (DNP3 Master)  |                                                  |
|         |                 |                                                  |
|         |  All DNP3       |                                                  |
|         |  commands from  |                                                  |
|         |  here           |                                                  |
|         +--------+--------+                                                  |
|                  |                                                            |
|                  | DNP3 (Port 20000)                                         |
|                  |                                                            |
|      +-----------+-----------+-------------------+                           |
|      |           |           |                   |                           |
|      v           v           v                   v                           |
|   [RTU 1]     [RTU 2]     [RTU 3]    ...     [RTU N]                        |
|                                                                               |
|                                                                               |
|  ACCESS CONTROL STRATEGY                                                      |
|  =======================                                                      |
|                                                                               |
|  1. All operator access to SCADA server through WALLIX                       |
|  2. DNP3 traffic only from SCADA server to RTUs                              |
|  3. No direct user access to RTUs                                            |
|  4. Firewall blocks DNP3 from anywhere except SCADA                          |
|  5. Session recording captures all operator actions                          |
|                                                                               |
|  AUTHORIZATION CONFIGURATION                                                  |
|  ===========================                                                  |
|                                                                               |
|  {                                                                            |
|      "authorization": "scada-operators",                                      |
|      "user_group": "Control-Room-Operators",                                 |
|      "target_group": "SCADA-Servers",                                        |
|      "subprotocols": ["RDP"],                                                |
|      "is_recorded": true,                                                     |
|      "is_critical": true,                                                     |
|      "time_frames": ["shift-hours"],                                         |
|      "requires_approval": false                                              |
|  }                                                                            |
|                                                                               |
+===============================================================================+
```

---

## OPC UA/DA

### OPC Overview

```
+===============================================================================+
|                    OPC PROTOCOLS                                              |
+===============================================================================+
|                                                                               |
|  OPC EVOLUTION                                                                |
|  =============                                                                |
|                                                                               |
|  +-----------------------------------------------------------------------+ |
|  |                                                                          | |
|  |  OPC DA (Data Access) - Classic                                         | |
|  |  ----------------------------------                                     | |
|  |  * Windows-only (COM/DCOM)                                              | |
|  |  * Real-time data access                                                | |
|  |  * Ports: Dynamic RPC (135 + high ports)                                | |
|  |  * Security: Windows authentication                                     | |
|  |  * Still widely used in legacy systems                                  | |
|  |                                                                          | |
|  |                         v Evolution                                     | |
|  |                                                                          | |
|  |  OPC UA (Unified Architecture) - Modern                                 | |
|  |  ------------------------------------------                                 | |
|  |  * Platform independent                                                 | |
|  |  * Binary (TCP 4840) or HTTPS (443)                                     | |
|  |  * Built-in security (X.509, encryption)                                | |
|  |  * Information modeling                                                 | |
|  |  * IIoT ready                                                           | |
|  |                                                                          | |
|  +-----------------------------------------------------------------------+ |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  OPC UA SECURITY MODES                                                        |
|  =====================                                                        |
|                                                                               |
|  +------------------+-----------------------------------------------------+  |
|  | Mode             | Description                                         |  |
|  +------------------+-----------------------------------------------------+  |
|  | None             | No security (testing only!)                         |  |
|  | Sign             | Message signing (integrity)                         |  |
|  | SignAndEncrypt   | Signing + encryption (RECOMMENDED)                  |  |
|  +------------------+-----------------------------------------------------+  |
|                                                                               |
|  OPC UA AUTHENTICATION                                                        |
|  =====================                                                        |
|                                                                               |
|  * Anonymous (not recommended)                                               |
|  * Username/Password                                                         |
|  * X.509 Certificate                                                         |
|  * Kerberos (in some implementations)                                        |
|                                                                               |
+===============================================================================+
```

### WALLIX with OPC

```
+===============================================================================+
|                    WALLIX OPC ACCESS                                          |
+===============================================================================+
|                                                                               |
|  OPC DA (Classic) ACCESS                                                      |
|  =======================                                                      |
|                                                                               |
|                                                                               |
|       +---------------+                                                      |
|       |  OPC Client   |                                                      |
|       |  (Engineer)   |                                                      |
|       +-------+-------+                                                      |
|               | RDP                                                           |
|               v                                                               |
|       +---------------+                                                      |
|       |    WALLIX     |                                                      |
|       |   BASTION     |                                                      |
|       +-------+-------+                                                      |
|               | RDP (Recorded)                                                |
|               v                                                               |
|       +---------------+                                                      |
|       |  OPC Server   |                                                      |
|       |  Workstation  |                                                      |
|       |               |                                                      |
|       |  [OPC DA      |                                                      |
|       |   Client SW]  |                                                      |
|       +-------+-------+                                                      |
|               | DCOM (135+)                                                   |
|               v                                                               |
|       +---------------+                                                      |
|       |  OPC DA       |                                                      |
|       |  Server       |                                                      |
|       |  (on SCADA)   |                                                      |
|       +---------------+                                                      |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  OPC UA (Modern) ACCESS                                                       |
|  ======================                                                       |
|                                                                               |
|       +---------------+                                                      |
|       |  OPC UA       |                                                      |
|       |  Client       |                                                      |
|       +-------+-------+                                                      |
|               | HTTPS (443)                                                   |
|               v                                                               |
|       +---------------+                                                      |
|       |    WALLIX     |                                                      |
|       |   BASTION     |                                                      |
|       |               |                                                      |
|       |  HTTPS Proxy  |    <--- Can proxy OPC UA over HTTPS                 |
|       |  + Recording  |                                                      |
|       +-------+-------+                                                      |
|               | HTTPS (Recorded)                                              |
|               v                                                               |
|       +---------------+                                                      |
|       |  OPC UA       |                                                      |
|       |  Server       |                                                      |
|       +---------------+                                                      |
|                                                                               |
|  OPC UA BENEFITS WITH WALLIX:                                                 |
|  * HTTPS-based = native WALLIX protocol support                              |
|  * Certificate-based auth can integrate with WALLIX                          |
|  * Session recording of all OPC UA interactions                              |
|  * Centralized access control                                                |
|                                                                               |
+===============================================================================+
```

---

## Ethernet/IP & CIP

### EtherNet/IP Overview

```
+===============================================================================+
|                    ETHERNET/IP & CIP                                          |
+===============================================================================+
|                                                                               |
|  COMMON INDUSTRIAL PROTOCOL (CIP)                                             |
|  ================================                                             |
|                                                                               |
|  CIP is the application layer protocol used by:                               |
|  * EtherNet/IP (Ethernet)                                                    |
|  * DeviceNet (CAN bus)                                                       |
|  * ControlNet (proprietary)                                                  |
|                                                                               |
|  Primary vendors: Rockwell Automation (Allen-Bradley), ODVA members          |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  ETHERNET/IP PORTS                                                            |
|  =================                                                            |
|                                                                               |
|  +-----------------+----------------------------------------------------+|
|  | Port            | Purpose                                                ||
|  +-----------------+----------------------------------------------------+|
|  | TCP 44818       | Explicit messaging (configuration, programming)       ||
|  | UDP 2222        | Implicit messaging (real-time I/O)                    ||
|  | UDP 44818       | Encapsulation discovery                               ||
|  +-----------------+----------------------------------------------------+|
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  SECURITY CONCERNS                                                            |
|  =================                                                            |
|                                                                               |
|  Traditional EtherNet/IP:                                                     |
|  WARNING: No authentication                                                   |
|  WARNING: No encryption                                                       |
|  WARNING: Device discovery exposes network                                    |
|                                                                               |
|  CIP Security (newer):                                                        |
|  [x] TLS encryption                                                           |
|  [x] Certificate authentication                                               |
|  [x] Device authorization                                                     |
|  WARNING: Not universally supported                                           |
|                                                                               |
+===============================================================================+
```

### WALLIX for EtherNet/IP

```
+===============================================================================+
|                    WALLIX ETHERNET/IP ACCESS                                  |
+===============================================================================+
|                                                                               |
|  ROCKWELL/ALLEN-BRADLEY ENVIRONMENT                                           |
|  ==================================                                           |
|                                                                               |
|                                                                               |
|       +-----------------------+                                              |
|       |      Engineer         |                                              |
|       |                       |                                              |
|       |  RSLogix / Studio 5000|                                              |
|       +-----------+-----------+                                              |
|                   |                                                           |
|                   | RDP                                                       |
|                   v                                                           |
|       +=======================+                                              |
|       |    WALLIX BASTION     |                                              |
|       |                       |                                              |
|       |  * User authentication|                                              |
|       |  * Session approval   |                                              |
|       |  * Full recording     |                                              |
|       +===========+===========+                                              |
|                   |                                                           |
|                   | RDP                                                       |
|                   v                                                           |
|       +-----------------------+                                              |
|       |  Engineering Station  |                                              |
|       |                       |                                              |
|       |  RSLogix 5000 /       |                                              |
|       |  Studio 5000          |                                              |
|       |  FactoryTalk          |                                              |
|       +-----------+-----------+                                              |
|                   |                                                           |
|                   | EtherNet/IP (44818)                                       |
|                   v                                                           |
|       +-----------------------+                                              |
|       |    ControlLogix       |                                              |
|       |    CompactLogix       |                                              |
|       |        PLCs           |                                              |
|       +-----------------------+                                              |
|                                                                               |
|                                                                               |
|  RECORDING CAPTURES:                                                          |
|  ===================                                                          |
|                                                                               |
|  +-----------------------------------------------------------------------+ |
|  | [x] Program downloads/uploads                                             | |
|  | [x] Online edits                                                          | |
|  | [x] Controller mode changes                                               | |
|  | [x] I/O forcing                                                           | |
|  | [x] Tag value modifications                                               | |
|  | [x] All screens visible in video recording                                | |
|  +-----------------------------------------------------------------------+ |
|                                                                               |
+===============================================================================+
```

---

## IEC 61850

### IEC 61850 Overview

```
+===============================================================================+
|                    IEC 61850 PROTOCOL                                         |
+===============================================================================+
|                                                                               |
|  POWER SYSTEM AUTOMATION STANDARD                                             |
|  ================================                                             |
|                                                                               |
|  Primary use: Electrical substations, power generation                        |
|  Vendors: ABB, Siemens, GE, Schneider, SEL                                   |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  IEC 61850 PROTOCOLS                                                          |
|  ===================                                                          |
|                                                                               |
|  +-----------------+----------------------------------------------------+|
|  | Protocol        | Purpose                                                ||
|  +-----------------+----------------------------------------------------+|
|  | MMS             | Manufacturing Message Specification                    ||
|  | (TCP 102)       | Client-server communication, reporting                 ||
|  +-----------------+----------------------------------------------------+|
|  | GOOSE           | Generic Object Oriented Substation Event              ||
|  | (Multicast)     | Fast peer-to-peer, protection signaling               ||
|  +-----------------+----------------------------------------------------+|
|  | SV              | Sampled Values                                        ||
|  | (Multicast)     | Real-time measurement data                            ||
|  +-----------------+----------------------------------------------------+|
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  SUBSTATION ARCHITECTURE                                                      |
|  =======================                                                      |
|                                                                               |
|            +---------------------------------------------+                   |
|            |            STATION LEVEL                    |                   |
|            |                                             |                   |
|            |  +-------------+    +-------------+        |                   |
|            |  |   Gateway   |    |  Historian  |        |                   |
|            |  +------+------+    +-------------+        |                   |
|            |         |                                   |                   |
|            +---------+-----------------------------------+                   |
|                      | MMS (TCP 102)                                         |
|            +---------+-----------------------------------+                   |
|            |         |     BAY LEVEL                     |                   |
|            |         |                                   |                   |
|            |  +------+------+    +-------------+        |                   |
|            |  |    IED      |    |    IED      |        |                   |
|            |  | (Protection)|<---|  (Control)  |        |                   |
|            |  +------+------+    +------+------+        |                   |
|            |         | GOOSE            |               |                   |
|            +---------+------------------+----------------+                   |
|                      |                  |                                    |
|            +---------+------------------+----------------+                   |
|            |         |  PROCESS LEVEL   |                |                   |
|            |         v                  v                |                   |
|            |     [CT/VT]           [Breaker]             |                   |
|            |                                             |                   |
|            +---------------------------------------------+                   |
|                                                                               |
+===============================================================================+
```

---

## BACnet

### BACnet Overview

```
+===============================================================================+
|                    BACNET PROTOCOL                                            |
+===============================================================================+
|                                                                               |
|  BUILDING AUTOMATION AND CONTROL NETWORK                                      |
|  =======================================                                      |
|                                                                               |
|  Primary use: Building Management Systems (BMS), HVAC, lighting              |
|  Standard: ASHRAE 135, ISO 16484-5                                           |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  BACNET DATA LINK OPTIONS                                                     |
|  ========================                                                     |
|                                                                               |
|  +-----------------+----------------------------------------------------+|
|  | Type            | Details                                                ||
|  +-----------------+----------------------------------------------------+|
|  | BACnet/IP       | UDP port 47808, most common                           ||
|  | BACnet/Ethernet | Direct Ethernet encapsulation                         ||
|  | BACnet MS/TP    | RS-485 serial, for field devices                      ||
|  | BACnet SC       | Secure Connect (TLS), newer standard                  ||
|  +-----------------+----------------------------------------------------+|
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  BMS ACCESS THROUGH WALLIX                                                    |
|  =========================                                                    |
|                                                                               |
|       +-------------------+                                                  |
|       |  Building         |                                                  |
|       |  Engineer         |                                                  |
|       +---------+---------+                                                  |
|                 | HTTPS/RDP                                                   |
|                 v                                                             |
|       +=====================+                                                |
|       |   WALLIX BASTION    |                                                |
|       +=========+===========+                                                |
|                 |                                                             |
|                 | RDP/HTTPS                                                   |
|                 v                                                             |
|       +-------------------+                                                  |
|       |  BMS Workstation  |                                                  |
|       |                   |                                                  |
|       |  [BMS Software]   |                                                  |
|       |  [Graphics]       |                                                  |
|       +---------+---------+                                                  |
|                 | BACnet/IP (47808)                                           |
|                 v                                                             |
|       +-------------------+                                                  |
|       |  BACnet Devices   |                                                  |
|       |  (Controllers)    |                                                  |
|       +-------------------+                                                  |
|                                                                               |
+===============================================================================+
```

---

## Protocol Security Considerations

### Security Summary

```
+===============================================================================+
|                    PROTOCOL SECURITY SUMMARY                                  |
+===============================================================================+
|                                                                               |
|  PROTOCOL SECURITY COMPARISON                                                 |
|  ============================                                                 |
|                                                                               |
|  +--------------+-------+-------+-------+-------+-------------------------+ |
|  | Protocol     | Auth  | Encr  | Integ | Replay| Secure Variant         | |
|  +--------------+-------+-------+-------+-------+-------------------------+ |
|  | Modbus TCP   |   x   |   x   |   x   |   x   | Modbus/TCP Security    | |
|  | DNP3         |   ~   |   x   |   ~   |   ~   | DNP3-SA v5             | |
|  | OPC DA       |   ~   |   x   |   x   |   x   | Use OPC UA instead     | |
|  | OPC UA       |   Y   |   Y   |   Y   |   Y   | Native security        | |
|  | EtherNet/IP  |   x   |   x   |   x   |   x   | CIP Security           | |
|  | IEC 61850    |   ~   |   ~   |   ~   |   ~   | IEC 62351              | |
|  | BACnet/IP    |   x   |   x   |   x   |   x   | BACnet SC              | |
|  | PROFINET     |   ~   |   ~   |   ~   |   ~   | PROFINET Security      | |
|  +--------------+-------+-------+-------+-------+-------------------------+ |
|                                                                               |
|  Legend: Y Native  ~ Optional/Limited  x Not supported                       |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  PAM MITIGATION STRATEGY                                                      |
|  =======================                                                      |
|                                                                               |
|  Since most OT protocols lack security:                                       |
|                                                                               |
|  1. CONTROL ACCESS AT HIGHER LAYER                                           |
|     +-----------------------------------------------------------------------+ |
|     | Use WALLIX to control access to systems that USE these protocols   | |
|     | (SCADA servers, engineering workstations, HMIs)                     | |
|     +-----------------------------------------------------------------------+ |
|                                                                               |
|  2. NETWORK SEGMENTATION                                                      |
|     +-----------------------------------------------------------------------+ |
|     | Firewall OT protocols to authorized sources only                   | |
|     | (e.g., only SCADA server can send Modbus to PLCs)                  | |
|     +-----------------------------------------------------------------------+ |
|                                                                               |
|  3. MONITORING & RECORDING                                                    |
|     +-----------------------------------------------------------------------+ |
|     | Record all sessions to OT systems                                  | |
|     | Enable forensic investigation of any changes                       | |
|     +-----------------------------------------------------------------------+ |
|                                                                               |
|  4. COMPENSATING CONTROLS                                                     |
|     +-----------------------------------------------------------------------+ |
|     | * IDS/IPS for OT protocols                                         | |
|     | * Application whitelisting                                         | |
|     | * Change detection                                                 | |
|     | * Physical security                                                | |
|     +-----------------------------------------------------------------------+ |
|                                                                               |
+===============================================================================+
```

---

## Next Steps

Continue to [18 - SCADA/ICS Access](../18-scada-ics-access/README.md) for specific SCADA access configurations.
