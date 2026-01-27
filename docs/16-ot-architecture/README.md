# 16 - OT Architecture & Deployment

## Table of Contents

1. [Industrial Architecture Principles](#industrial-architecture-principles)
2. [Zone-Based Deployment](#zone-based-deployment)
3. [Network Segmentation](#network-segmentation)
4. [Deployment Topologies](#deployment-topologies)
5. [DMZ Architecture](#dmz-architecture)
6. [High Availability for OT](#high-availability-for-ot)
7. [Distributed Site Architecture](#distributed-site-architecture)

---

## Industrial Architecture Principles

### Core Design Principles

```
+==============================================================================+
|                       OT ARCHITECTURE PRINCIPLES                             |
+==============================================================================+

  PRINCIPLE 1: DEFENSE IN DEPTH
  =============================

  +------------------------------------------------------------------------+
  |                                                                        |
  |  +------------------------------------------------------------------+  |
  |  |  Layer 1: Network Segmentation                                   |  |
  |  |  +------------------------------------------------------------+  |  |
  |  |  |  Layer 2: Firewalls & Access Control                       |  |  |
  |  |  |  +------------------------------------------------------+  |  |  |
  |  |  |  |  Layer 3: PAM / WALLIX Bastion                       |  |  |  |
  |  |  |  |  +------------------------------------------------+  |  |  |  |
  |  |  |  |  |  Layer 4: Endpoint Protection                  |  |  |  |  |
  |  |  |  |  |  +------------------------------------------+  |  |  |  |  |
  |  |  |  |  |  |  Layer 5: Application Control            |  |  |  |  |  |
  |  |  |  |  |  |  +------------------------------------+  |  |  |  |  |  |
  |  |  |  |  |  |  |          OT ASSETS                 |  |  |  |  |  |  |
  |  |  |  |  |  |  +------------------------------------+  |  |  |  |  |  |
  |  |  |  |  |  +------------------------------------------+  |  |  |  |  |
  |  |  |  |  +------------------------------------------------+  |  |  |  |
  |  |  |  +------------------------------------------------------+  |  |  |
  |  |  +------------------------------------------------------------+  |  |
  |  +------------------------------------------------------------------+  |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  PRINCIPLE 2: MINIMAL FOOTPRINT
  ==============================

  * No agents on OT devices
  * Minimal network overhead
  * No active scanning of OT networks
  * Passive monitoring where possible
  * Lightweight proxy architecture

  --------------------------------------------------------------------------

  PRINCIPLE 3: FAIL-SAFE OPERATION
  ================================

  * PAM failure must not stop production
  * Emergency bypass procedures documented
  * Local operation capability if WAN fails
  * Graceful degradation modes
  * Production continuity over security perfection

  --------------------------------------------------------------------------

  PRINCIPLE 4: ZONE-BASED ACCESS
  ==============================

  * Access controlled at zone boundaries
  * No direct IT-to-OT access
  * All traffic through defined conduits
  * Least privilege per zone

+==============================================================================+
```

---

## Zone-Based Deployment

### IEC 62443 Zone Architecture

```
+==============================================================================+
|                       IEC 62443 ZONE DEPLOYMENT                              |
+==============================================================================+


                    +----------------------------------+
                    |        ENTERPRISE ZONE           |
                    |       (Security Level 1)         |
                    |                                  |
                    |   * Corporate IT                 |
                    |   * Business applications        |
                    |   * Internet access              |
                    +-----------------+----------------+
                                      |
                          +-----------+-----------+
                          |     ENTERPRISE DMZ    |
                          |       (Conduit)       |
                          |                       |
                          |  * WALLIX Access Mgr  |
                          |  * Historian replica  |
                          |  * Jump servers       |
                          +-----------+-----------+
                                      |
  +-----------------------------------+-----------------------------------+
  |                      MANUFACTURING ZONE                               |
  |                     (Security Level 2-3)                              |
  |                                                                       |
  |   +---------------------------------------------------------------+   |
  |   |                    SITE DMZ (Level 3.5)                       |   |
  |   |                                                               |   |
  |   |   +-------------------------------------------------------+   |   |
  |   |   |              WALLIX BASTION                           |   |   |
  |   |   |                                                       |   |   |
  |   |   |   * Secure access gateway                             |   |   |
  |   |   |   * Session recording                                 |   |   |
  |   |   |   * Protocol inspection                               |   |   |
  |   |   |   * Credential vault                                  |   |   |
  |   |   +-------------------------------------------------------+   |   |
  |   |                                                               |   |
  |   |   [Historian] [Patch Server] [AV Server]                      |   |
  |   |                                                               |   |
  |   +-----------------------------+---------------------------------+   |
  |                                 |                                     |
  |   +-----------------------------+-----------------------------+       |
  |   |                  CONTROL ZONE (Level 2-3)                 |       |
  |   |                   (Security Level 3)                      |       |
  |   |                                                           |       |
  |   |   [SCADA Server]  [HMI Stations]  [Engineering WS]        |       |
  |   |                                                           |       |
  |   +-----------------------------+-----------------------------+       |
  |                                 |                                     |
  |   +-----------------------------+-----------------------------+       |
  |   |                  FIELD ZONE (Level 0-1)                   |       |
  |   |                   (Security Level 1)                      |       |
  |   |                                                           |       |
  |   |   [PLC]  [RTU]  [DCS]  [Safety Systems]  [Sensors]        |       |
  |   |                                                           |       |
  |   +-----------------------------------------------------------+       |
  |                                                                       |
  +-----------------------------------------------------------------------+

+==============================================================================+
```

### Zone Security Levels

```
+==============================================================================+
|                    IEC 62443 SECURITY LEVELS                                  |
+==============================================================================+
|                                                                               |
|  SECURITY LEVEL DEFINITIONS                                                   |
|  ==========================                                                   |
|                                                                               |
|  +----------+-----------------------------------------------------------------+  |
|  | Level    | Description                                                 |  |
|  +----------+-----------------------------------------------------------------+  |
|  | SL 0     | No security requirements                                    |  |
|  +----------+-----------------------------------------------------------------+  |
|  | SL 1     | Protection against casual/coincidental attack               |  |
|  |          | * Basic password protection                                 |  |
|  |          | * No encryption required                                    |  |
|  +----------+-----------------------------------------------------------------+  |
|  | SL 2     | Protection against intentional attack with low resources    |  |
|  |          | * Role-based access control                                 |  |
|  |          | * Audit logging                                             |  |
|  |          | * Session management                                        |  |
|  +----------+-----------------------------------------------------------------+  |
|  | SL 3     | Protection against sophisticated attack with moderate       |  |
|  |          | resources (nation-state aligned)                            |  |
|  |          | * Strong authentication (MFA)                               |  |
|  |          | * Encrypted communications                                  |  |
|  |          | * Comprehensive monitoring                                  |  |
|  |          | * Incident response capability                              |  |
|  +----------+-----------------------------------------------------------------+  |
|  | SL 4     | Protection against state-sponsored attack with extensive    |  |
|  |          | resources                                                   |  |
|  |          | * Maximum security controls                                 |  |
|  |          | * Defense in depth                                          |  |
|  |          | * Continuous monitoring                                     |  |
|  |          | * Assumed breach mentality                                  |  |
|  +----------+-----------------------------------------------------------------+  |
|                                                                               |
|  WALLIX SECURITY LEVEL MAPPING                                                |
|  =============================                                                |
|                                                                               |
|  +----------+-----------------------------------------------------------------+  |
|  | SL       | WALLIX Features Required                                    |  |
|  +----------+-----------------------------------------------------------------+  |
|  | SL 2     | * Basic authentication                                      |  |
|  |          | * Session recording                                         |  |
|  |          | * Role-based authorization                                  |  |
|  +----------+-----------------------------------------------------------------+  |
|  | SL 3     | * MFA for all access                                        |  |
|  |          | * Full session recording with search                        |  |
|  |          | * Approval workflows                                        |  |
|  |          | * Real-time monitoring & alerting                           |  |
|  |          | * SIEM integration                                          |  |
|  |          | * Password rotation                                         |  |
|  +----------+-----------------------------------------------------------------+  |
|  | SL 4     | * All SL3 features plus:                                    |  |
|  |          | * 4-eyes approval                                           |  |
|  |          | * Continuous session monitoring                             |  |
|  |          | * Behavioral analytics                                      |  |
|  |          | * HSM for key protection                                    |  |
|  |          | * Geo-redundant architecture                                |  |
|  +----------+-----------------------------------------------------------------+  |
|                                                                               |
+==============================================================================+
```

---

## Network Segmentation

### OT Network Architecture

```
+==============================================================================+
|                    OT NETWORK SEGMENTATION                                    |
+==============================================================================+
|                                                                               |
|                                                                               |
|           CORPORATE NETWORK                                                   |
|           ================                                                    |
|                  |                                                            |
|                  | 10.0.0.0/8                                                |
|                  |                                                            |
|         +--------+--------+                                                  |
|         |    FIREWALL 1   |                                                  |
|         |   (IT/OT DMZ)   |                                                  |
|         +--------+--------+                                                  |
|                  |                                                            |
|  +---------------+-------------------------------------------+               |
|  |                    IT/OT DMZ                               |               |
|  |                    172.16.0.0/24                           |               |
|  |                                                            |               |
|  |    +=======================+    +---------------------+  |               |
|  |    |   WALLIX BASTION      |    |    Historian        |  |               |
|  |    |   172.16.0.10         |    |    172.16.0.20      |  |               |
|  |    |                       |    +---------------------+  |               |
|  |    |   Access Manager:     |                              |               |
|  |    |   172.16.0.11         |    +---------------------+  |               |
|  |    +=======================+    |    AV/Patch Server  |  |               |
|  |                                  |    172.16.0.30      |  |               |
|  |                                  +---------------------+  |               |
|  |                                                            |               |
|  +---------------+--------------------------------------------+               |
|                  |                                                            |
|         +--------+--------+                                                  |
|         |    FIREWALL 2   |                                                  |
|         |   (OT Internal) |                                                  |
|         +--------+--------+                                                  |
|                  |                                                            |
|  +---------------+-------------------------------------------+               |
|  |                 SCADA/CONTROL NETWORK                      |               |
|  |                 192.168.10.0/24                            |               |
|  |                                                            |               |
|  |  +-------------+  +-------------+  +-------------+       |               |
|  |  |   SCADA     |  |    HMI      |  | Engineering |       |               |
|  |  |   Server    |  |  Stations   |  | Workstation |       |               |
|  |  | .10         |  | .20-.25     |  | .30         |       |               |
|  |  +-------------+  +-------------+  +-------------+       |               |
|  |                                                            |               |
|  +---------------+--------------------------------------------+               |
|                  |                                                            |
|         +--------+--------+                                                  |
|         |    FIREWALL 3   |                                                  |
|         |   (Field Zone)  |                                                  |
|         +--------+--------+                                                  |
|                  |                                                            |
|  +---------------+-------------------------------------------+               |
|  |                    FIELD NETWORK                           |               |
|  |                    192.168.100.0/24                        |               |
|  |                                                            |               |
|  |  +-------+  +-------+  +-------+  +-------+  +-------+  |               |
|  |  | PLC-1 |  | PLC-2 |  | RTU-1 |  | RTU-2 |  |  SIS  |  |               |
|  |  | .10   |  | .11   |  | .20   |  | .21   |  | .100  |  |               |
|  |  +-------+  +-------+  +-------+  +-------+  +-------+  |               |
|  |                                                            |               |
|  +------------------------------------------------------------+               |
|                                                                               |
+==============================================================================+
```

### Firewall Rules for PAM

```
+==============================================================================+
|                    OT FIREWALL RULES                                          |
+==============================================================================+
|                                                                               |
|  FIREWALL 1: IT/OT DMZ BOUNDARY                                               |
|  ==============================                                               |
|                                                                               |
|  +----------------------------------------------------------------------------+|
|  | Rule | Source      | Dest         | Port     | Protocol | Action        ||
|  +------+-------------+--------------+----------+----------+---------------+|
|  | 1    | IT Users    | WALLIX AM    | 443      | HTTPS    | ALLOW         ||
|  | 2    | WALLIX      | Corp LDAP    | 636      | LDAPS    | ALLOW         ||
|  | 3    | WALLIX      | Corp RADIUS  | 1812     | RADIUS   | ALLOW         ||
|  | 4    | WALLIX      | Corp SIEM    | 6514     | Syslog   | ALLOW         ||
|  | 5    | Historian   | Corp MES     | 1433     | SQL      | ALLOW         ||
|  | 99   | ANY         | ANY          | ANY      | ANY      | DENY + LOG    ||
|  +------+-------------+--------------+----------+----------+---------------+|
|                                                                               |
|  FIREWALL 2: OT INTERNAL BOUNDARY                                             |
|  ================================                                             |
|                                                                               |
|  +----------------------------------------------------------------------------+|
|  | Rule | Source      | Dest         | Port     | Protocol | Action        ||
|  +------+-------------+--------------+----------+----------+---------------+|
|  | 1    | WALLIX      | SCADA Server | 22       | SSH      | ALLOW         ||
|  | 2    | WALLIX      | SCADA Server | 3389     | RDP      | ALLOW         ||
|  | 3    | WALLIX      | HMI Stations | 3389     | RDP      | ALLOW         ||
|  | 4    | WALLIX      | Eng WS       | 22,3389  | SSH/RDP  | ALLOW         ||
|  | 5    | SCADA       | Historian    | 1433     | SQL      | ALLOW         ||
|  | 6    | Patch Srv   | OT Systems   | 445      | SMB      | ALLOW (sched) ||
|  | 99   | ANY         | ANY          | ANY      | ANY      | DENY + LOG    ||
|  +------+-------------+--------------+----------+----------+---------------+|
|                                                                               |
|  FIREWALL 3: FIELD ZONE BOUNDARY                                              |
|  ===============================                                              |
|                                                                               |
|  +----------------------------------------------------------------------------+|
|  | Rule | Source      | Dest         | Port     | Protocol | Action        ||
|  +------+-------------+--------------+----------+----------+---------------+|
|  | 1    | SCADA       | PLCs         | 502      | Modbus   | ALLOW         ||
|  | 2    | SCADA       | RTUs         | 20000    | DNP3     | ALLOW         ||
|  | 3    | Eng WS      | PLCs         | 44818    | EtherNet/IP| ALLOW       ||
|  | 4    | WALLIX*     | PLCs         | 44818    | EtherNet/IP| ALLOW       ||
|  | 99   | ANY         | ANY          | ANY      | ANY      | DENY + LOG    ||
|  +------+-------------+--------------+----------+----------+---------------+|
|                                                                               |
|  * Only for engineering/programming sessions through PAM                     |
|                                                                               |
+==============================================================================+
```

---

## Deployment Topologies

### Topology 1: Centralized Deployment

```
+==============================================================================+
|                    CENTRALIZED DEPLOYMENT                                     |
+==============================================================================+
|                                                                               |
|  Best for: Single site, small-medium deployment                               |
|                                                                               |
|                     +-------------------------------------+                  |
|                     |           CORPORATE IT              |                  |
|                     |                                     |                  |
|                     |   [Users]  [Admin]  [Vendors]       |                  |
|                     +------------------+------------------+                  |
|                                        |                                     |
|                               +--------+--------+                            |
|                               |    FIREWALL     |                            |
|                               +--------+--------+                            |
|                                        |                                     |
|  +-------------------------------------+-------------------------------------+   |
|  |                           OT DMZ                                       |   |
|  |                                                                        |   |
|  |              +========================================+               |   |
|  |              |        WALLIX BASTION CLUSTER          |               |   |
|  |              |                                         |               |   |
|  |              |   +----------+      +----------+       |               |   |
|  |              |   |  Node 1  |<---->|  Node 2  |       |               |   |
|  |              |   | (Active) |      |(Standby) |       |               |   |
|  |              |   +----------+      +----------+       |               |   |
|  |              |                                         |               |   |
|  |              |   +----------------------------+       |               |   |
|  |              |   |    Shared Storage (NAS)    |       |               |   |
|  |              |   |    (Recordings, Config)    |       |               |   |
|  |              |   +----------------------------+       |               |   |
|  |              |                                         |               |   |
|  |              +========================================+               |   |
|  |                                                                        |   |
|  +-------------------------------------+-------------------------------------+   |
|                                        |                                     |
|          +-----------------------------+-----------------------------+       |
|          |                             |                             |       |
|          v                             v                             v       |
|  +---------------+           +---------------+           +---------------+   |
|  |  Process Area |           |  Process Area |           |  Process Area |   |
|  |       A       |           |       B       |           |       C       |   |
|  |               |           |               |           |               |   |
|  | [HMI][PLC]    |           | [HMI][PLC]    |           | [HMI][PLC]    |   |
|  +---------------+           +---------------+           +---------------+   |
|                                                                               |
|  ADVANTAGES:                                                                  |
|  * Simplified management                                                     |
|  * Centralized audit                                                        |
|  * Lower cost                                                               |
|                                                                               |
|  CONSIDERATIONS:                                                              |
|  * Single point of entry                                                    |
|  * Network dependency                                                       |
|                                                                               |
+==============================================================================+
```

### Topology 2: Distributed Deployment

```
+==============================================================================+
|                    DISTRIBUTED DEPLOYMENT                                     |
+==============================================================================+
|                                                                               |
|  Best for: Multi-site, large scale, geographic distribution                   |
|                                                                               |
|                     +-------------------------------------+                  |
|                     |         CENTRAL MANAGEMENT          |                  |
|                     |                                     |                  |
|                     |  +-----------------------------+   |                  |
|                     |  |   Central WALLIX Manager    |   |                  |
|                     |  |   (Policy, Reporting)       |   |                  |
|                     |  +-----------------------------+   |                  |
|                     |                                     |                  |
|                     |  +-----------------------------+   |                  |
|                     |  |   Central SIEM/SOC          |   |                  |
|                     |  +-----------------------------+   |                  |
|                     |                                     |                  |
|                     +------------------+------------------+                  |
|                                        |                                     |
|                                   WAN / MPLS                                 |
|                                        |                                     |
|         +------------------------------+------------------------------+      |
|         |                              |                              |      |
|         v                              v                              v      |
|  +------------------+        +------------------+        +------------------+|
|  |     SITE A       |        |     SITE B       |        |     SITE C       ||
|  |   (Plant 1)      |        |   (Plant 2)      |        |   (Remote)       ||
|  |                  |        |                  |        |                  ||
|  | +--------------+ |        | +--------------+ |        | +--------------+ ||
|  | |WALLIX Cluster| |        | |WALLIX Bastion| |        | |WALLIX Bastion| ||
|  | |  (HA pair)    | |        | |  (Single)     | |        | |  (Local)     | ||
|  | +------+-------+ |        | +------+-------+ |        | +------+-------+ ||
|  |        |         |        |        |         |        |        |         ||
|  | +------+-------+ |        | +------+-------+ |        | +------+-------+ ||
|  | |  OT Assets   | |        | |  OT Assets   | |        | |  OT Assets   | ||
|  | |  [SCADA]     | |        | |  [SCADA]     | |        | |  [RTU]       | ||
|  | |  [HMI]       | |        | |  [HMI]       | |        | |  [PLC]       | ||
|  | |  [PLC]       | |        | |  [PLC]       | |        | |              | ||
|  | +--------------+ |        | +--------------+ |        | +--------------+ ||
|  |                  |        |                  |        |                  ||
|  +------------------+        +------------------+        +------------------+|
|                                                                               |
|  ADVANTAGES:                                                                  |
|  * Local operation if WAN fails                                             |
|  * Reduced latency for sessions                                             |
|  * Scalable to many sites                                                   |
|  * Compliance with data locality                                            |
|                                                                               |
|  CONSIDERATIONS:                                                              |
|  * More complex management                                                  |
|  * Higher infrastructure cost                                               |
|  * Distributed policy management                                            |
|                                                                               |
+==============================================================================+
```

### Topology 3: Hub and Spoke

```
+==============================================================================+
|                    HUB AND SPOKE DEPLOYMENT                                   |
+==============================================================================+
|                                                                               |
|  Best for: Central control center with multiple remote facilities             |
|                                                                               |
|                                                                               |
|                     +====================================+                   |
|                     |       CENTRAL CONTROL CENTER       |                   |
|                     |                                    |                   |
|                     |   +----------------------------+  |                   |
|                     |   |   WALLIX Bastion (Primary) |  |                   |
|                     |   |   + Access Manager         |  |                   |
|                     |   |   + Full HA Cluster        |  |                   |
|                     |   +----------------------------+  |                   |
|                     |                                    |                   |
|                     |   +----------+  +----------+      |                   |
|                     |   | Master   |  |  SIEM    |      |                   |
|                     |   | SCADA    |  |  SOC     |      |                   |
|                     |   +----------+  +----------+      |                   |
|                     |                                    |                   |
|                     +==================+================+                   |
|                                         |                                    |
|              +--------------------------+----------------------------+        |
|              |                          |                          |        |
|              |         WAN / Satellite / Cellular                  |        |
|              |                          |                          |        |
|      +-------+-------+          +-------+-------+          +-------+-------+|
|      |               |          |               |          |               ||
|      v               v          v               v          v               v|
|  +---------+   +---------+  +---------+  +---------+  +---------+  +---------+|
|  |Substation|   |Substation|  |Pump Stn |  |Pump Stn |  |Well Site|  |Well Site||
|  |    A    |   |    B    |  |    1    |  |    2    |  |   101   |  |   102   ||
|  |         |   |         |  |         |  |         |  |         |  |         ||
|  | [RTU]   |   | [RTU]   |  | [PLC]   |  | [PLC]   |  | [RTU]   |  | [RTU]   ||
|  | [IED]   |   | [IED]   |  | [VFD]   |  | [VFD]   |  |         |  |         ||
|  +---------+   +---------+  +---------+  +---------+  +---------+  +---------+|
|                                                                               |
|  ACCESS FLOW:                                                                 |
|  -------------                                                                |
|                                                                               |
|  1. All access through central WALLIX                                        |
|  2. Sessions proxied to remote sites                                         |
|  3. Recordings stored centrally                                              |
|  4. Single point of control and audit                                        |
|                                                                               |
|  ADVANTAGES:                                                                  |
|  * Simplified remote site infrastructure                                    |
|  * Centralized security control                                             |
|  * Unified audit trail                                                      |
|  * Suitable for utility/pipeline operations                                 |
|                                                                               |
|  CONSIDERATIONS:                                                              |
|  * WAN dependency                                                           |
|  * Latency for interactive sessions                                         |
|  * Bandwidth for session traffic                                            |
|                                                                               |
+==============================================================================+
```

---

## DMZ Architecture

### Industrial DMZ Design

```
+==============================================================================+
|                    INDUSTRIAL DMZ ARCHITECTURE                                |
+==============================================================================+
|                                                                               |
|                                                                               |
|         ENTERPRISE NETWORK                                                    |
|         ==================                                                    |
|                |                                                              |
|                |                                                              |
|       +--------+--------+                                                    |
|       |   OUTER FW      |                                                    |
|       |   (Stateful)    |                                                    |
|       +--------+--------+                                                    |
|                |                                                              |
|  ==============+============================================================ |
|                |                    IT/OT DMZ                                 |
|  ==============+============================================================ |
|                |                                                              |
|       +--------+---------------------------------------------------------+   |
|       |                                                                   |   |
|       |  +---------------------------------------------------------------+ |   |
|       |  |              EXTERNAL-FACING SERVICES                        | |   |
|       |  |                                                              | |   |
|       |  |  +=======================================================+  | |   |
|       |  |  |          WALLIX ACCESS MANAGER                        |  | |   |
|       |  |  |          (Web Portal for Vendors/Remote Users)        |  | |   |
|       |  |  +=======================================================+  | |   |
|       |  |                                                              | |   |
|       |  |  +-------------------+  +-------------------+               | |   |
|       |  |  |  Reverse Proxy    |  |  MFA Server       |               | |   |
|       |  |  |  (if needed)      |  |  (if separate)    |               | |   |
|       |  |  +-------------------+  +-------------------+               | |   |
|       |  |                                                              | |   |
|       |  +--------------------------------------------------------------+ |   |
|       |                                                                   |   |
|       |  +---------------------------------------------------------------+ |   |
|       |  |              INTERNAL DMZ SERVICES                           | |   |
|       |  |                                                              | |   |
|       |  |  +=======================================================+  | |   |
|       |  |  |          WALLIX BASTION CORE                          |  | |   |
|       |  |  |          (Session Proxy, Vault, Recording)            |  | |   |
|       |  |  +=======================================================+  | |   |
|       |  |                                                              | |   |
|       |  |  +-------------------+  +-------------------+               | |   |
|       |  |  |  Historian        |  |  Patch/AV         |               | |   |
|       |  |  |  (DMZ Replica)    |  |  Repository       |               | |   |
|       |  |  +-------------------+  +-------------------+               | |   |
|       |  |                                                              | |   |
|       |  |  +-------------------+  +-------------------+               | |   |
|       |  |  |  Jump Server      |  |  File Transfer    |               | |   |
|       |  |  |  (if needed)      |  |  Server           |               | |   |
|       |  |  +-------------------+  +-------------------+               | |   |
|       |  |                                                              | |   |
|       |  +--------------------------------------------------------------+ |   |
|       |                                                                   |   |
|       +--------+---------------------------------------------------------+   |
|                |                                                              |
|  ==============+============================================================ |
|                |                                                              |
|       +--------+--------+                                                    |
|       |   INNER FW      |                                                    |
|       |  (App-aware)    |                                                    |
|       +--------+--------+                                                    |
|                |                                                              |
|         OT NETWORK                                                            |
|         ==========                                                            |
|                                                                               |
+==============================================================================+
```

---

## High Availability for OT

### OT-Specific HA Considerations

```
+==============================================================================+
|                    OT HIGH AVAILABILITY                                       |
+==============================================================================+
|                                                                               |
|  OT HA REQUIREMENTS                                                           |
|  ==================                                                           |
|                                                                               |
|  +-----------------------------------------------------------------------+ |
|  | Requirement          | IT Standard      | OT Requirement               | |
|  +----------------------+------------------+------------------------------+ |
|  | RTO (Recovery Time)  | Hours            | Minutes (or bypass)          | |
|  | RPO (Data Loss)      | Minutes-Hours    | Near-zero for safety         | |
|  | Failover Mode        | Automatic        | Automatic with manual option | |
|  | Bypass Capability    | Not usually      | REQUIRED for production      | |
|  | Split-brain handling | Standard         | Critical - must prevent      | |
|  +----------------------+------------------+------------------------------+ |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  RECOMMENDED OT HA ARCHITECTURE                                               |
|  ==============================                                               |
|                                                                               |
|                     +-------------------------------------+                  |
|                     |          LOAD BALANCER              |                  |
|                     |       (or Floating VIP)             |                  |
|                     +------------------+------------------+                  |
|                                        |                                     |
|              +-------------------------+-------------------------+           |
|              |                         |                         |           |
|              v                         |                         v           |
|     +-----------------+               |               +-----------------+   |
|     |  WALLIX Node 1  |               |               |  WALLIX Node 2  |   |
|     |    (Active)     |<--------------+-------------->|   (Standby)     |   |
|     |                 |           Sync                |                 |   |
|     |  * Session Mgr  |                               |  * Session Mgr  |   |
|     |  * Password Mgr |                               |  * Password Mgr |   |
|     |  * Recording    |                               |  * Recording    |   |
|     +--------+--------+                               +--------+--------+   |
|              |                                                  |           |
|              +---------------------+----------------------------+           |
|                                    |                                        |
|                          +---------+---------+                              |
|                          |   SHARED STORAGE  |                              |
|                          |   (HA NAS/SAN)    |                              |
|                          |                   |                              |
|                          |   * Recordings    |                              |
|                          |   * Database      |                              |
|                          |   * Config sync   |                              |
|                          +-------------------+                              |
|                                                                               |
|  BYPASS PROCEDURES (CRITICAL)                                                 |
|  ============================                                                 |
|                                                                               |
|  +-----------------------------------------------------------------------+ |
|  |                                                                          | |
|  |  If WALLIX completely fails:                                            | |
|  |                                                                          | |
|  |  1. Document incident start time                                        | |
|  |  2. Activate emergency bypass firewall rules                            | |
|  |  3. Use documented break-glass credentials                              | |
|  |  4. Log all access manually                                             | |
|  |  5. Restore WALLIX ASAP                                                 | |
|  |  6. Rotate all credentials used during bypass                           | |
|  |  7. Review manual logs                                                  | |
|  |                                                                          | |
|  |  WARNING: Bypass = production continues, security reduced               | |
|  |                                                                          | |
|  +-----------------------------------------------------------------------+ |
|                                                                               |
+==============================================================================+
```

---

## Distributed Site Architecture

### Multi-Site Industrial Deployment

```
+==============================================================================+
|                    DISTRIBUTED SITE ARCHITECTURE                              |
+==============================================================================+
|                                                                               |
|                                                                               |
|                        +------------------------+                            |
|                        |   CORPORATE / SOC      |                            |
|                        |                        |                            |
|                        |  +------------------+ |                            |
|                        |  | Central Manager  | |                            |
|                        |  | (Policy, Report) | |                            |
|                        |  +------------------+ |                            |
|                        |                        |                            |
|                        |  +------------------+ |                            |
|                        |  |   SIEM / SOC     | |                            |
|                        |  +------------------+ |                            |
|                        |                        |                            |
|                        +-----------+------------+                            |
|                                    |                                         |
|                           Corporate WAN / MPLS                               |
|                                    |                                         |
|     +------------------------------+------------------------------+         |
|     |                              |                              |         |
|     v                              v                              v         |
|                                                                               |
|  =========================================================================== |
|                                                                               |
|  LARGE PLANT (Staffed)        MEDIUM PLANT (Limited Staff)    REMOTE SITE    |
|  =====================        ============================    ============   |
|                                                                               |
|  +---------------------+     +---------------------+     +-----------------+|
|  |                     |     |                     |     |                 ||
|  |  +---------------+  |     |  +---------------+  |     |  Central Bastion||
|  |  | WALLIX Cluster|  |     |  |WALLIX Bastion |  |     |  handles access ||
|  |  |  (HA pair)    |  |     |  |  (Single)     |  |     |                 ||
|  |  +---------------+  |     |  +---------------+  |     |  [RTU] [PLC]    ||
|  |                     |     |                     |     |                 ||
|  |  Local admin team   |     |  Remote managed     |     |  No local PAM   ||
|  |  Full recording     |     |  Local + central    |     |  WAN dependent  ||
|  |  Local storage      |     |  recording          |     |                 ||
|  |                     |     |                     |     |                 ||
|  |  +-----+ +-----+   |     |  +-----+ +-----+   |     |                 ||
|  |  |SCADA| | HMI |   |     |  |SCADA| | HMI |   |     |                 ||
|  |  +-----+ +-----+   |     |  +-----+ +-----+   |     |                 ||
|  |                     |     |                     |     |                 ||
|  |  +-----+ +-----+   |     |  +-----+ +-----+   |     |                 ||
|  |  | PLC | | DCS |   |     |  | PLC | | VFD |   |     |                 ||
|  |  +-----+ +-----+   |     |  +-----+ +-----+   |     |                 ||
|  |                     |     |                     |     |                 ||
|  +---------------------+     +---------------------+     +-----------------+|
|                                                                               |
|  LOG/AUDIT FLOW                                                               |
|  ==============                                                               |
|                                                                               |
|  All sites ---> Central SIEM (real-time syslog)                              |
|  All sites ---> Central Manager (daily sync if WAN limited)                  |
|                                                                               |
|  POLICY MANAGEMENT                                                            |
|  =================                                                            |
|                                                                               |
|  Central Manager ---> Push policies to all sites                             |
|  Local Bastion ---> Enforce locally, report centrally                        |
|                                                                               |
+==============================================================================+
```

---

## Next Steps

Continue to [17 - Industrial Protocols](../17-industrial-protocols/README.md) for protocol-specific configurations.
