# 03 - WALLIX Architecture

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Proxy-Based vs Agent-Based Architecture](#proxy-based-vs-agent-based-architecture)
3. [Component Architecture](#component-architecture)
4. [Deployment Models](#deployment-models)
5. [Network Architecture](#network-architecture)
6. [Data Flow](#data-flow)
7. [Storage Architecture](#storage-architecture)
8. [Integration Architecture](#integration-architecture)

---

## Architecture Overview

### High-Level Architecture

```
                            +-------------------------------------+
                            |           USERS                     |
                            |  (Administrators, Operators, Apps)  |
                            +--------------+----------------------+
                                           |
                    +----------------------+----------------------+
                    |                      |                      |
                    v                      v                      v
           +---------------+    +---------------+    +---------------+
           |  Native       |    |   Access      |    |   API         |
           |  Clients      |    |   Manager     |    |   Clients     |
           |  (SSH/RDP)    |    |   (HTML5)     |    |   (REST)      |
           +-------+-------+    +-------+-------+    +-------+-------+
                   |                    |                    |
                   +--------------------+--------------------+
                                        |
                                        v
+===========================================================================+
|                           WALLIX BASTION                                  |
|                                                                           |
|  +--------------------------------------------------------------------+   |
|  |                        PROXY LAYER                                 |   |
|  |   +----------+ +----------+ +----------+ +----------+ +---------+  |   |
|  |   |   SSH    | |   RDP    | |  HTTPS   | |   VNC    | | Telnet  |  |   |
|  |   |  Proxy   | |  Proxy   | |  Proxy   | |  Proxy   | | Proxy   |  |   |
|  |   +----------+ +----------+ +----------+ +----------+ +---------+  |   |
|  +--------------------------------------------------------------------+   |
|                                                                           |
|  +---------------------+  +---------------------+  +------------------+   |
|  |   SESSION MANAGER   |  |   PASSWORD MANAGER  |  |   AUDIT ENGINE   |   |
|  |                     |  |                     |  |                  |   |
|  |  * Authentication   |  |  * Credential Vault |  |  * Logging       |   |
|  |  * Authorization    |  |  * Rotation Engine  |  |  * Recording     |   |
|  |  * Session Broker   |  |  * Checkout/Checkin |  |  * Reporting     |   |
|  |  * Monitoring       |  |  * Injection        |  |  * Alerting      |   |
|  +---------------------+  +---------------------+  +------------------+   |
|                                                                           |
|  +--------------------------------------------------------------------+   |
|  |                        DATA LAYER                                  |   |
|  |   +--------------+  +--------------+  +-----------------------+    |   |
|  |   |   MariaDB    |  |  File System |  |  Configuration Store  |    |   |
|  |   |  (Metadata)  |  |  (Recordings)|  |  (Settings)           |    |   |
|  |   +--------------+  +--------------+  +-----------------------+    |   |
|  +--------------------------------------------------------------------+   |
|                                                                           |
+===========================================================================+
                                        |
                                        v
                            +-----------------------+
                            |    TARGET SYSTEMS     |
                            |                       |
                            |  * Servers            |
                            |  * Network Devices    |
                            |  * Databases          |
                            |  * Applications       |
                            |  * Cloud Resources    |
                            +-----------------------+
```

---

## Proxy-Based vs Agent-Based Architecture

### Understanding the Fundamental Difference

This is the **most significant architectural difference** between WALLIX and CyberArk.

#### CyberArk: Agent-Based (PSM)

```
+----------+         +------------------+         +----------+
|   User   |-------->|   PSM Server     |-------->|  Target  |
|          |   RDP   |                  |   RDP   |  Server  |
|          |         |  * Runs session  |         |          |
|          |         |  * Heavy compute |         |          |
|          |         |  * Windows-based |         |          |
+----------+         +------------------+         +----------+
                              |
                     User session runs
                     ON the PSM server
```

**CyberArk PSM Characteristics:**
- Session executes on PSM server
- Requires Windows Server infrastructure
- High resource consumption per session
- Connection components installed on PSM
- Scaling requires more PSM servers

#### WALLIX: Proxy-Based

```
+----------+         +------------------+         +----------+
|   User   |-------->|  WALLIX Bastion  |-------->|  Target  |
|          |   SSH   |                  |   SSH   |  Server  |
|          |         |  * Proxies data  |         |          |
|          |         |  * Low overhead  |         |          |
|          |         |  * Linux-based   |         |          |
+----------+         +------------------+         +----------+
                              |
                     Data streams THROUGH
                     the Bastion (not executed)
```

**WALLIX Bastion Characteristics:**
- Session data proxied through appliance
- Linux-based appliance
- Lower resource consumption
- No agents on target systems
- Better horizontal scaling

### Comparison Matrix

| Aspect | CyberArk (Agent-Based) | WALLIX (Proxy-Based) |
|--------|------------------------|----------------------|
| **Resource Usage** | High (runs sessions) | Low (proxies data) |
| **Scalability** | Vertical (bigger PSM servers) | Horizontal (more proxies) |
| **OS Requirement** | Windows Server | Linux Appliance |
| **Target Agents** | Optional connectors | None required |
| **Protocol Support** | Via connection components | Native protocol parsing |
| **Deployment Complexity** | Higher | Lower |
| **Session Isolation** | Process isolation on PSM | Network isolation |
| **Latency** | Higher (rendering) | Lower (passthrough) |

### When Proxy-Based Excels

- High-volume session environments
- Linux-centric infrastructure
- Network device management
- OT/ICS environments (minimal footprint)
- Virtualized and bare metal deployments

### When Agent-Based May Be Preferred

- Complex application sessions requiring local rendering
- Specific compliance requiring session isolation
- Environments heavily invested in Windows infrastructure

---

## Component Architecture

### Core Components Deep Dive

#### 1. Session Manager

```
+=================================================================+
|                      SESSION MANAGER                            |
+=================================================================+
|                                                                 |
|  +-----------------+     +-----------------+                    |
|  |  AUTHENTICATION |     |  AUTHORIZATION  |                    |
|  |                 |     |                 |                    |
|  |  * Local        |     |  * Policy       |                    |
|  |  * LDAP/AD      |     |    evaluation   |                    |
|  |  * RADIUS       |     |  * Time-based   |                    |
|  |  * SAML         |     |  * Approval     |                    |
|  |  * Kerberos     |     |    workflow     |                    |
|  |  * X.509        |     |                 |                    |
|  +-----------------+     +-----------------+                    |
|                                                                 |
|  +-----------------+     +-----------------+                    |
|  |  PROXY ENGINE   |     |  SESSION        |                    |
|  |                 |     |  MONITORING     |                    |
|  |  * Protocol     |     |                 |                    |
|  |    handlers     |     |  * Real-time    |                    |
|  |  * Data         |     |    view         |                    |
|  |    inspection   |     |  * 4-eyes       |                    |
|  |  * Recording    |     |  * Kill session |                    |
|  |    hooks        |     |  * Alerting     |                    |
|  +-----------------+     +-----------------+                    |
|                                                                 |
+=================================================================+
```

**Responsibilities:**
- User authentication and session authorization
- Protocol-level session proxying
- Real-time session monitoring
- Session recording coordination
- Connection brokering to targets

#### 2. Password Manager

```
+=================================================================+
|                      PASSWORD MANAGER                           |
+=================================================================+
|                                                                 |
|  +---------------------------------------------------------+    |
|  |                  CREDENTIAL VAULT                       |    |
|  |                                                         |    |
|  |    +----------+  +----------+  +----------+             |    |
|  |    | Accounts |  |   Keys   |  |  Secrets |             |    |
|  |    |          |  |          |  |          |             |    |
|  |    | user/pass|  | SSH Keys |  | API Keys |             |    |
|  |    |          |  | Certs    |  | Tokens   |             |    |
|  |    +----------+  +----------+  +----------+             |    |
|  |                                                         |    |
|  |    Encryption: AES-256 | Key Management: HSM optional   |    |
|  +---------------------------------------------------------+    |
|                                                                 |
|  +-----------------+     +-----------------+                    |
|  |  ROTATION       |     |  CHECKOUT       |                    |
|  |  ENGINE         |     |  WORKFLOW       |                    |
|  |                 |     |                 |                    |
|  |  * Scheduled    |     |  * Request      |                    |
|  |  * On-demand    |     |  * Approval     |                    |
|  |  * Post-session |     |  * Time-limited |                    |
|  |  * Verification |     |  * Audit trail  |                    |
|  +-----------------+     +-----------------+                    |
|                                                                 |
|  +---------------------------------------------------------+    |
|  |                  INJECTION ENGINE                       |    |
|  |                                                         |    |
|  |  * Transparent credential injection into sessions       |    |
|  |  * User never sees actual password                      |    |
|  |  * Protocol-aware injection                             |    |
|  +---------------------------------------------------------+    |
|                                                                 |
+=================================================================+
```

**Responsibilities:**
- Secure credential storage (AES-256 encryption)
- Automatic password rotation
- Credential injection into sessions
- Checkout/checkin workflows
- SSH key management

#### 3. Access Manager

```
+=================================================================+
|                      ACCESS MANAGER                             |
+=================================================================+
|                                                                 |
|  +---------------------------------------------------------+    |
|  |                    WEB PORTAL                           |    |
|  |                                                         |    |
|  |    +----------------------------------------------+     |    |
|  |    |            HTML5 Session Client              |     |    |
|  |    |                                              |     |    |
|  |    |   * RDP via Guacamole/HTML5                  |     |    |
|  |    |   * SSH via WebSocket terminal               |     |    |
|  |    |   * VNC via HTML5 canvas                     |     |    |
|  |    |   * File transfer via web                    |     |    |
|  |    +----------------------------------------------+     |    |
|  |                                                         |    |
|  |    +----------------------------------------------+     |    |
|  |    |            Target Browser                    |     |    |
|  |    |                                              |     |    |
|  |    |   * Search and filter targets                |     |    |
|  |    |   * Favorites and recent                     |     |    |
|  |    |   * Quick connect                            |     |    |
|  |    +----------------------------------------------+     |    |
|  +---------------------------------------------------------+    |
|                                                                 |
|  Features: SSO | MFA | Responsive | Mobile-Ready                |
|                                                                 |
+=================================================================+
```

**Responsibilities:**
- Browser-based session access (no client software)
- User-friendly target browsing
- SSO integration
- Mobile device support

---

## Deployment Models

> **This deployment** is an on-premises, 5-site multi-datacenter installation
> on bare metal hardware appliances and VMs. No cloud, container, or SaaS
> deployment is used. All components are physically located in datacenter
> buildings connected by a private MPLS backbone.

### Production Deployment: 5-Site Multi-Datacenter

This is the reference architecture for this deployment.

```
+===============================================================================+
|  5-SITE WALLIX BASTION DEPLOYMENT — PRODUCTION REFERENCE ARCHITECTURE        |
+===============================================================================+
|                                                                               |
|  ACCESS MANAGERS (HA Active-Passive — CLIENT-MANAGED)                         |
|  +-----------------------------+   +-----------------------------+            |
|  |  Access Manager 1 (DC-A)   |   |  Access Manager 2 (DC-B)   |            |
|  |  SSO / MFA / Session Broker|<->|  SSO / MFA / Session Broker|            |
|  |  CLIENT TEAM MANAGES       |   |  CLIENT TEAM MANAGES       |            |
|  +-------------+--------------+   +--------------+--------------+            |
|                |                                 |                           |
|                +----------------+----------------+                           |
|                           MPLS Network                                       |
|          +----------+----------+----------+----------+                       |
|          |          |          |          |          |                       |
|       Site 1     Site 2     Site 3     Site 4     Site 5                    |
|                                                                               |
|  PER-SITE LAYOUT (identical for all 5 sites):                                 |
|                                                                               |
|  +----------------------------------+  +----------------------------+         |
|  |          DMZ VLAN                |  |       Cyber VLAN           |         |
|  |                                  |  |                            |         |
|  |  +------------+  +------------+  |  |  +--------------------+   |         |
|  |  | HAProxy 1  |  | HAProxy 2  |  |  |  | FortiAuthenticator |   |         |
|  |  | (Active)   |  | (Standby)  |  |  |  | Primary (6.4+)     |   |         |
|  |  +-----+------+  +-----+------+  |  |  +--------------------+   |         |
|  |        |               |         |  |  | FortiAuthenticator |   |         |
|  |        +-------+-------+         |  |  | Secondary (6.4+)   |   |         |
|  |                |                 |  |  +--------------------+   |         |
|  |         +------+------+          |  |                            |         |
|  |         |             |          |  |  +--------------------+   |         |
|  |  +------+---+  +------+---+      |  |  |  AD Domain         |   |         |
|  |  | Bastion  |  | Bastion  |      |  |  |  Controller        |   |         |
|  |  | Node 1   |  | Node 2   |      |  |  |  (per site)        |   |         |
|  |  | (HA)     |  | (HA)     |      |  |  +--------------------+   |         |
|  |  +----------+  +----------+      |  |                            |         |
|  |                                  |  |                            |         |
|  |  +----------------------------+  |  |                            |         |
|  |  |  WALLIX RDS (Jump Host)    |  |  |                            |         |
|  |  |  OT RemoteApp access       |  |  |                            |         |
|  |  +----------------------------+  |  |                            |         |
|  +----------------------------------+  +----------------------------+         |
|                    |                             |                            |
|                    +-------- Fortigate ----------+                            |
|                              (inter-VLAN routing + firewall)                  |
|                                                                               |
+===============================================================================+
```

**Key architecture facts:**

| Aspect | Value |
|--------|-------|
| Sites | 5 (all datacenter buildings, MPLS-connected) |
| HAProxy per site | 2 (Active-Passive with Keepalived VRRP) |
| WALLIX Bastion per site | 2 (HA — Active-Active or Active-Passive) |
| RDS per site | 1 (standalone, OT RemoteApp jump host) |
| FortiAuthenticator per site | 2 (HA pair in Cyber VLAN — NOT shared) |
| AD DC per site | 1 (Cyber VLAN — NOT centralized) |
| Access Manager total | 2 (HA Active-Passive, CLIENT-MANAGED) |
| Inter-site Bastion comms | None — all inter-site routing via Access Manager |

**VLAN separation per site:**

| VLAN | Hosts | Purpose |
|------|-------|---------|
| DMZ VLAN | 2x HAProxy, 2x WALLIX Bastion, 1x RDS | User-facing services and PAM proxying |
| Cyber VLAN | 2x FortiAuthenticator, 1x AD DC | Identity and authentication backend |

**FortiAuthenticator placement — critical note:**
FortiAuthenticator is deployed as a **per-site HA pair** in the Cyber VLAN.
It is NOT a shared central service. Each site has its own independent pair.
RADIUS requests travel from Bastion nodes (DMZ VLAN) to FortiAuthenticator
(Cyber VLAN) via Fortigate inter-VLAN routing.

**Access Manager — scope note:**
Access Manager is **client-managed**. The client's AM team installs, configures,
and operates both AM nodes. Our scope is limited to Bastion-side registration:
providing the API endpoint, SAML metadata, and health check URL to the client
AM team. See [46 - Access Manager](../46-access-manager/README.md) and
[48 - AM Bastion Connectivity](../48-access-manager-bastion-connectivity/README.md).

---

### Model 1: Standalone (Single Appliance)

```
+-----------------------------------------+
|           WALLIX Bastion                |
|         (All-in-One Appliance)          |
|                                         |
|  * Session Manager                      |
|  * Password Manager                     |
|  * Access Manager                       |
|  * Database                             |
|  * Recording Storage                    |
+-----------------------------------------+
```

**Use Cases:**
- Small to medium deployments
- Proof of Concept
- Branch offices
- Up to ~500 concurrent sessions

---

### Model 2: Distributed (Separate Components)

```
+-----------------+     +-----------------+     +-----------------+
|  Access Manager |     |  Bastion Core   |     |  External DB    |
|  (Web Portal)   |---->|  (Session +     |---->|  (MariaDB)      |
|                 |     |   Password Mgr) |     |                 |
+-----------------+     +-----------------+     +-----------------+
                                |
                                v
                        +-----------------+
                        |  NAS/SAN        |
                        |  (Recordings)   |
                        +-----------------+
```

**Use Cases:**
- Large enterprises
- High-security requirements
- Compliance requirements for data separation
- 500+ concurrent sessions

---

### Model 3: High Availability Cluster

```
                    +-----------------+
                    |  Load Balancer  |
                    |  (HAProxy)      |
                    +--------+--------+
                             |
              +--------------+--------------+
              |                             |
              v                             v
     +-----------------+           +-----------------+
     |  Bastion Node 1 |           |  Bastion Node 2 |
     |    (Active)     |<--------->|    (Active)     |
     |                 |  Cluster  |                 |
     +--------+--------+   Sync    +--------+--------+
              |                             |
              +--------------+--------------+
                             |
                             v
              +-----------------------------+
              |    Shared Storage           |
              |  * MariaDB (HA)             |
              |  * Recording Storage (NAS)  |
              +-----------------------------+
```

**Use Cases:**
- Enterprise production environments
- Zero-downtime requirements
- Geographic redundancy
- Disaster recovery

---

## Network Architecture

### Network Zones and Traffic Flow

```
+=========================================================================+
|                           NETWORK ARCHITECTURE                          |
+=========================================================================+
|                                                                         |
|   USER ZONE                        DMZ                    SECURE ZONE   |
|   ----------                    ---------                 ------------  |
|                                                                         |
|   +----------+                 +----------+              +----------+   |
|   |   User   |---HTTPS:443---->|  Access  |              |  Target  |   |
|   | Browser  |                 |  Manager |              |  Servers |   |
|   +----------+                 +----+-----+              +----^-----+   |
|                                     |                         |         |
|   +----------+                      |                         |         |
|   |  Native  |                      v                         |         |
|   |  Client  |               +-------------+                  |         |
|   |  (SSH/   |--SSH:22------>|   WALLIX    |--SSH/RDP/etc-----+         |
|   |   RDP)   |--RDP:3389---->|   Bastion   |                            |
|   +----------+               +------+------+                            |
|                                     |                                   |
|   +----------+                      |              +--------------+     |
|   |   API    |---HTTPS:443----------+              |  Directory   |     |
|   |  Client  |                                     |  (LDAP/AD)   |     |
|   +----------+                                     +--------------+     |
|                                                                         |
+=========================================================================+
```

### Required Ports

#### Inbound to WALLIX Bastion

| Port | Protocol | Source | Purpose |
|------|----------|--------|---------|
| 443 | HTTPS | Users, Access Manager | Web UI, API |
| 22 | SSH | Users | SSH proxy |
| 3389 | RDP | Users | RDP proxy |
| 5900 | VNC | Users | VNC proxy |
| 23 | Telnet | Users | Telnet proxy (if needed) |

#### Outbound from WALLIX Bastion

| Port | Protocol | Destination | Purpose |
|------|----------|-------------|---------|
| 22 | SSH | Targets | SSH to targets |
| 3389 | RDP | Targets | RDP to targets |
| 389/636 | LDAP/LDAPS | Directory | Authentication |
| 88/464 | Kerberos | KDC | Kerberos auth |
| 1812/1813 | RADIUS | RADIUS server | MFA |
| 514/6514 | Syslog | SIEM | Log forwarding |
| Various | Target protocols | Targets | Database, app connections |

### Firewall Rule Summary

```
+==================================================================+
|                    FIREWALL RULES SUMMARY                        |
+==================================================================+
|                                                                  |
|  RULE 1: Users -> Bastion (Session Protocols)                    |
|  ---------------------------------------------                   |
|  Allow: TCP 22, 3389, 5900, 443                                  |
|                                                                  |
|  RULE 2: Bastion -> Targets (Session Protocols)                  |
|  -------------------------------------------------               |
|  Allow: TCP 22, 3389, 5900, 23, 1521, 3306, etc.                 |
|                                                                  |
|  RULE 3: Bastion -> Directory Services                           |
|  -----------------------------------------                       |
|  Allow: TCP 389, 636, 88, 464                                    |
|                                                                  |
|  RULE 4: Bastion -> SIEM/Syslog                                  |
|  --------------------------------                                |
|  Allow: TCP/UDP 514, TCP 6514                                    |
|                                                                  |
|  RULE 5: Cluster Communication                                   |
|  --------------------------------                                |
|  Allow: TCP 3306/3307 (DB), TCP cluster ports between nodes      |
|                                                                  |
|  DENY: All other traffic                                         |
|                                                                  |
+==================================================================+
```

---

## Data Flow

### Session Data Flow (Detailed)

```
+-----+                +-------------------------------------------------+                +--------+
|User |                |                WALLIX BASTION                   |                | Target |
+--+--+                +--------------------+----------------------------+                +---+----+
   |                                        |                                                 |
   |  1. Connection Request (SSH/RDP)       |                                                 |
   |--------------------------------------->|                                                 |
   |                                        |                                                 |
   |                          +-------------+-------------+                                   |
   |                          | 2. Authentication         |                                   |
   |                          |    - Validate credentials |                                   |
   |                          |    - Check MFA            |                                   |
   |                          |    - Query LDAP/Local     |                                   |
   |                          +-------------+-------------+                                   |
   |                                        |                                                 |
   |  3. Auth Challenge/Success             |                                                 |
   |<---------------------------------------|                                                 |
   |                                        |                                                 |
   |  4. Target Selection                   |                                                 |
   |--------------------------------------->|                                                 |
   |                                        |                                                 |
   |                          +-------------+--------------+                                  |
   |                          | 5. Authorization           |                                  |
   |                          |    - Check policies        |                                  |
   |                          |    - Validate time window  |                                  |
   |                          |    - Check approval status |                                  |
   |                          +-------------+--------------+                                  |
   |                                        |                                                 |
   |                          +-------------+--------------+                                  |
   |                          | 6. Credential Retrieval    |                                  |
   |                          |    - Fetch from vault      |                                  |
   |                          |    - Decrypt               |                                  |
   |                          +-------------+--------------+                                  |
   |                                        |                                                 |
   |                                        |  7. Connect to Target                           |
   |                                        |------------------------------------------------>
   |                                        |                                                 |
   |                                        |  8. Authenticate with Target Credentials        |
   |                                        |<------------------------------------------------|
   |                                        |                                                 |
   |  9. Session Established                |                                                 |
   |<---------------------------------------|                                                 |
   |                                        |                                                 |
   |  ======================================|==============================================   |
   |            PROXIED SESSION             |                  RECORDED                       |
   |  ======================================|==============================================   |
   |                                        |                                                 |
   |  10. Session Data (bidirectional)      |  11. Session Data (bidirectional)               |
   |<-------------------------------------->|<----------------------------------------------  |
   |                                        |                                                 |
   |                          +-------------+-------------+                                   |
   |                          | 12. Recording & Audit      |                                  |
   |                          |     - Write to storage     |                                  |
   |                          |     - Extract metadata     |                                  |
   |                          |     - OCR (RDP)            |                                  |
   |                          +---------------------------+                                   |
   |                                        |                                                 |
```

---

## Storage Architecture

### Data Storage Components

```
+=========================================================================+
|                        STORAGE ARCHITECTURE                             |
+=========================================================================+
|                                                                         |
|  +----------------------------------------------------------------+     |
|  |                      MariaDB Database                          |     |
|  |                                                                |     |
|  |   * Configuration data                                         |     |
|  |   * User and group definitions                                 |     |
|  |   * Device, account, authorization metadata                    |     |
|  |   * Encrypted credentials (AES-256)                            |     |
|  |   * Audit logs                                                 |     |
|  |   * Session metadata                                           |     |
|  |                                                                |     |
|  |   Location: /var/lib/mysql/                                    |     |
|  |   Encryption: At-rest encryption supported                     |     |
|  +----------------------------------------------------------------+     |
|                                                                         |
|  +----------------------------------------------------------------+     |
|  |                    Session Recordings                          |     |
|  |                                                                |     |
|  |   * Video recordings (proprietary format)                      |     |
|  |   * Session metadata files                                     |     |
|  |   * OCR index data (searchable text)                           |     |
|  |   * Keystroke logs                                             |     |
|  |                                                                |     |
|  |   Location: /var/wab/recorded/                                 |     |
|  |   External: NAS/SAN mount supported                            |     |
|  |   Retention: Policy-based                                      |     |
|  +----------------------------------------------------------------+     |
|                                                                         |
|  +----------------------------------------------------------------+     |
|  |                    Configuration Files                         |     |
|  |                                                                |     |
|  |   * /etc/opt/wab/                    System configuration      |     |
|  |   * /etc/opt/wab/wabengine/          Engine settings           |     |
|  |   * /var/opt/wab/                    Variable data             |     |
|  |                                                                |     |
|  +----------------------------------------------------------------+     |
|                                                                         |
+=========================================================================+
```

### Storage Sizing Guidelines

| Component | Sizing Factor | Estimate |
|-----------|---------------|----------|
| **Database** | Users + Targets + History | 10-50 GB typical |
| **Recordings (RDP)** | ~50-200 MB/hour per session | Variable |
| **Recordings (SSH)** | ~1-5 MB/hour per session | Variable |
| **Audit Logs** | ~100 KB/session | Depends on retention |

> **Tip**: Plan for external NAS/SAN storage for recordings in enterprise deployments. Local storage fills quickly with RDP sessions.

---

## Integration Architecture

### Integration Points

```
+=========================================================================+
|                      INTEGRATION ARCHITECTURE                           |
+=========================================================================+
|                                                                         |
|                          WALLIX BASTION                                 |
|                               |                                         |
|      +------------------------+------------------------+                |
|      |                        |                        |                |
|      v                        v                        v                |
|  +--------+            +------------+           +------------+          |
|  |IDENTITY|            |   ITSM     |           |    SIEM    |          |
|  |        |            |            |           |            |          |
|  |* LDAP  |            |* ServiceNow|           |* Splunk    |          |
|  |* AD    |            |* Jira      |           |* QRadar    |          |
|  |* SAML  |            |* BMC       |           |* ArcSight  |          |
|  |* RADIUS|            |* Custom    |           |* ELK       |          |
|  +--------+            +------------+           +------------+          |
|      |                        |                        |                |
|      |  LDAP/RADIUS           |  REST API/Webhooks     |  Syslog/CEF    |
|      |                        |                        |                |
|      |                        |                        |                |
|      v                        v                        v                |
|  +-------------+        +------------+           +------------+         |
|  |  CMDB       |        | AUTOMATION |           |  SECRETS   |         |
|  |             |        |            |           |            |         |
|  |* ServiceNow |        |* Ansible   |           |* HashiCorp |         |
|  |* i-doit     |        |* Terraform |           |* External  |         |
|  |* Custom     |        |* Jenkins   |           |  vaults    |         |
|  +-------------+        +------------+           +------------+         |
|                                                                         |
+=========================================================================+
```

### API Integration

```
REST API Architecture
---------------------

Base URL: https://bastion.company.com/api/

Authentication:
  * API Key (X-Auth-Token header)
  * OAuth 2.0 (Bearer token)
  * Session cookie (web UI)

Endpoints:
  /api/users          - User management
  /api/usergroups     - Group management
  /api/devices        - Target devices
  /api/accounts       - Privileged accounts
  /api/authorizations - Access policies
  /api/sessions       - Session data
  /api/recordings     - Recording access

Rate Limiting: Configurable
Format: JSON
```

---

## See Also

**Related Sections:**
- [04 - Core Components](../04-core-components/README.md) - Detailed component architecture
- [11 - High Availability](../11-high-availability/README.md) - HA clustering and failover
- [16 - Cloud Deployment](../16-cloud-deployment/README.md) - Deployment patterns and models

**Related Documentation:**
- [Install Guide](/install/HOWTO.md) - Multi-site deployment architecture
- [Install: Architecture Diagrams](/install/11-architecture-diagrams.md) - Network diagrams and ports

**Official Resources:**
- [WALLIX Documentation](https://pam.wallix.one/documentation)

---

## Next Steps

Continue to [03 - Core Components](../04-core-components/README.md) for detailed exploration of Session Manager, Password Manager, and Access Manager.
