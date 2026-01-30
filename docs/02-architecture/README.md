# 02 - WALLIX Architecture

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
                            |           USERS                      |
                            |  (Administrators, Operators, Apps)   |
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
|                           WALLIX BASTION                                   |
|                                                                            |
|  +--------------------------------------------------------------------+  |
|  |                        PROXY LAYER                                  |   |
|  |   +----------+ +----------+ +----------+ +----------+ +---------+ |  |
|  |   |   SSH    | |   RDP    | |  HTTPS   | |   VNC    | | Telnet  | |  |
|  |   |  Proxy   | |  Proxy   | |  Proxy   | |  Proxy   | | Proxy   | |  |
|  |   +----------+ +----------+ +----------+ +----------+ +---------+ |  |
|  +--------------------------------------------------------------------+  |
|                                                                            |
|  +---------------------+  +---------------------+  +------------------+  |
|  |   SESSION MANAGER   |  |   PASSWORD MANAGER  |  |   AUDIT ENGINE   |  |
|  |                     |  |                     |  |                  |  |
|  |  * Authentication   |  |  * Credential Vault |  |  * Logging       |  |
|  |  * Authorization    |  |  * Rotation Engine  |  |  * Recording     |  |
|  |  * Session Broker   |  |  * Checkout/Checkin |  |  * Reporting     |  |
|  |  * Monitoring       |  |  * Injection        |  |  * Alerting      |  |
|  +---------------------+  +---------------------+  +------------------+  |
|                                                                            |
|  +--------------------------------------------------------------------+  |
|  |                        DATA LAYER                                   |   |
|  |   +--------------+  +--------------+  +-----------------------+   |  |
|  |   |   MariaDB    |  |  File System |  |  Configuration Store  |   |  |
|  |   |  (Metadata)  |  |  (Recordings)|  |  (Settings)           |   |  |
|  |   +--------------+  +--------------+  +-----------------------+   |  |
|  +--------------------------------------------------------------------+  |
|                                                                            |
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
- Cloud and containerized deployments

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
|                      SESSION MANAGER                             |
+=================================================================+
|                                                                  |
|  +-----------------+     +-----------------+                   |
|  |  AUTHENTICATION |     |  AUTHORIZATION  |                   |
|  |                 |     |                 |                   |
|  |  * Local        |     |  * Policy       |                   |
|  |  * LDAP/AD      |     |    evaluation   |                   |
|  |  * RADIUS       |     |  * Time-based   |                   |
|  |  * SAML         |     |  * Approval     |                   |
|  |  * Kerberos     |     |    workflow     |                   |
|  |  * X.509        |     |                 |                   |
|  +-----------------+     +-----------------+                   |
|                                                                  |
|  +-----------------+     +-----------------+                   |
|  |  PROXY ENGINE   |     |  SESSION        |                   |
|  |                 |     |  MONITORING     |                   |
|  |  * Protocol     |     |                 |                   |
|  |    handlers     |     |  * Real-time    |                   |
|  |  * Data         |     |    view         |                   |
|  |    inspection   |     |  * 4-eyes       |                   |
|  |  * Recording    |     |  * Kill session |                   |
|  |    hooks        |     |  * Alerting     |                   |
|  +-----------------+     +-----------------+                   |
|                                                                  |
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
|                      PASSWORD MANAGER                            |
+=================================================================+
|                                                                  |
|  +---------------------------------------------------------+   |
|  |                  CREDENTIAL VAULT                        |   |
|  |                                                          |   |
|  |    +----------+  +----------+  +----------+            |   |
|  |    | Accounts |  |   Keys   |  |  Secrets |            |   |
|  |    |          |  |          |  |          |            |   |
|  |    | user/pass|  | SSH Keys |  | API Keys |            |   |
|  |    |          |  | Certs    |  | Tokens   |            |   |
|  |    +----------+  +----------+  +----------+            |   |
|  |                                                          |   |
|  |    Encryption: AES-256 | Key Management: HSM optional   |   |
|  +---------------------------------------------------------+   |
|                                                                  |
|  +-----------------+     +-----------------+                   |
|  |  ROTATION       |     |  CHECKOUT       |                   |
|  |  ENGINE         |     |  WORKFLOW       |                   |
|  |                 |     |                 |                   |
|  |  * Scheduled    |     |  * Request      |                   |
|  |  * On-demand    |     |  * Approval     |                   |
|  |  * Post-session |     |  * Time-limited |                   |
|  |  * Verification |     |  * Audit trail  |                   |
|  +-----------------+     +-----------------+                   |
|                                                                  |
|  +---------------------------------------------------------+   |
|  |                  INJECTION ENGINE                        |   |
|  |                                                          |   |
|  |  * Transparent credential injection into sessions       |   |
|  |  * User never sees actual password                      |   |
|  |  * Protocol-aware injection                             |   |
|  +---------------------------------------------------------+   |
|                                                                  |
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
|                      ACCESS MANAGER                              |
+=================================================================+
|                                                                  |
|  +---------------------------------------------------------+   |
|  |                    WEB PORTAL                            |   |
|  |                                                          |   |
|  |    +----------------------------------------------+     |   |
|  |    |            HTML5 Session Client              |     |   |
|  |    |                                              |     |   |
|  |    |   * RDP via Guacamole/HTML5                 |     |   |
|  |    |   * SSH via WebSocket terminal              |     |   |
|  |    |   * VNC via HTML5 canvas                    |     |   |
|  |    |   * File transfer via web                   |     |   |
|  |    +----------------------------------------------+     |   |
|  |                                                          |   |
|  |    +----------------------------------------------+     |   |
|  |    |            Target Browser                    |     |   |
|  |    |                                              |     |   |
|  |    |   * Search and filter targets               |     |   |
|  |    |   * Favorites and recent                    |     |   |
|  |    |   * Quick connect                           |     |   |
|  |    +----------------------------------------------+     |   |
|  +---------------------------------------------------------+   |
|                                                                  |
|  Features: SSO | MFA | Responsive | Mobile-Ready               |
|                                                                  |
+=================================================================+
```

**Responsibilities:**
- Browser-based session access (no client software)
- User-friendly target browsing
- SSO integration
- Mobile device support

---

## Deployment Models

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
|  Access Manager |     |  Bastion Core   |     |  External DB     |
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
                    |  (F5/HAProxy)   |
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

### Model 4: Multi-Site / Distributed

```
        SITE A (Primary)                    SITE B (DR/Secondary)
+-----------------------------+     +-----------------------------+
|                             |     |                             |
|  +---------------------+   |     |   +---------------------+   |
|  |  Bastion Cluster    |   |     |   |  Bastion Cluster    |   |
|  |  (Active)           |<--+-----+-->|  (Standby/Active)   |   |
|  +---------------------+   |     |   +---------------------+   |
|            |               |     |            |               |
|            v               |     |            v               |
|  +---------------------+   |     |   +---------------------+   |
|  |  Local Database     |---+-----+-->|  Replica Database   |   |
|  +---------------------+   |     |   +---------------------+   |
|                             |     |                             |
+-----------------------------+     +-----------------------------+
              |                                   |
              +---------------+-------------------+
                              |
                    Global Load Balancer
                      (GSLB / DNS-based)
```

---

## Network Architecture

### Network Zones and Traffic Flow

```
+=========================================================================+
|                           NETWORK ARCHITECTURE                           |
+=========================================================================+
|                                                                          |
|   USER ZONE                        DMZ                    SECURE ZONE   |
|   ----------                    ---------                 ------------  |
|                                                                          |
|   +----------+                 +----------+              +----------+  |
|   |   User   |---HTTPS:443---->|  Access  |              |  Target  |  |
|   | Browser  |                 |  Manager |              |  Servers |  |
|   +----------+                 +----+-----+              +----^-----+  |
|                                     |                         |        |
|   +----------+                      |                         |        |
|   |  Native  |                      v                         |        |
|   |  Client  |               +-------------+                  |        |
|   |  (SSH/   |--SSH:22------>|   WALLIX    |--SSH/RDP/etc-----+        |
|   |   RDP)   |--RDP:3389---->|   Bastion   |                          |
|   +----------+               +------+------+                          |
|                                     |                                  |
|   +----------+                      |              +--------------+   |
|   |   API    |---HTTPS:443----------+              |  Directory   |   |
|   |  Client  |                                     |  (LDAP/AD)   |   |
|   +----------+                                     +--------------+   |
|                                                                          |
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
|                                                                   |
|  RULE 1: Users -> Bastion (Session Protocols)                    |
|  ---------------------------------------------                  |
|  Allow: TCP 22, 3389, 5900, 443                                 |
|                                                                   |
|  RULE 2: Bastion -> Targets (Session Protocols)                  |
|  -------------------------------------------------              |
|  Allow: TCP 22, 3389, 5900, 23, 1521, 3306, etc.               |
|                                                                   |
|  RULE 3: Bastion -> Directory Services                           |
|  -----------------------------------------                      |
|  Allow: TCP 389, 636, 88, 464                                   |
|                                                                   |
|  RULE 4: Bastion -> SIEM/Syslog                                  |
|  --------------------------------                               |
|  Allow: TCP/UDP 514, TCP 6514                                   |
|                                                                   |
|  RULE 5: Cluster Communication                                   |
|  --------------------------------                               |
|  Allow: TCP 3306/3307 (DB), TCP cluster ports between nodes     |
|                                                                   |
|  DENY: All other traffic                                        |
|                                                                   |
+==================================================================+
```

---

## Data Flow

### Session Data Flow (Detailed)

```
+-----+                +---------------------------------------------+                +--------+
|User |                |                WALLIX BASTION                   |                | Target |
+--+--+                +--------------------+----------------------------+                +---+----+
   |                                        |                                                 |
   |  1. Connection Request (SSH/RDP)       |                                                 |
   |--------------------------------------->|                                                 |
   |                                        |                                                 |
   |                          +-------------+-------------+                                  |
   |                          | 2. Authentication          |                                  |
   |                          |    - Validate credentials  |                                  |
   |                          |    - Check MFA             |                                  |
   |                          |    - Query LDAP/Local      |                                  |
   |                          +-------------+-------------+                                  |
   |                                        |                                                 |
   |  3. Auth Challenge/Success             |                                                 |
   |<---------------------------------------|                                                 |
   |                                        |                                                 |
   |  4. Target Selection                   |                                                 |
   |--------------------------------------->|                                                 |
   |                                        |                                                 |
   |                          +-------------+-------------+                                  |
   |                          | 5. Authorization           |                                  |
   |                          |    - Check policies        |                                  |
   |                          |    - Validate time window  |                                  |
   |                          |    - Check approval status |                                  |
   |                          +-------------+-------------+                                  |
   |                                        |                                                 |
   |                          +-------------+-------------+                                  |
   |                          | 6. Credential Retrieval    |                                  |
   |                          |    - Fetch from vault      |                                  |
   |                          |    - Decrypt               |                                  |
   |                          +-------------+-------------+                                  |
   |                                        |                                                 |
   |                                        |  7. Connect to Target                          |
   |                                        |------------------------------------------------>
   |                                        |                                                 |
   |                                        |  8. Authenticate with Target Credentials       |
   |                                        |<------------------------------------------------|
   |                                        |                                                 |
   |  9. Session Established                |                                                 |
   |<---------------------------------------|                                                 |
   |                                        |                                                 |
   |  ======================================|============================================== |
   |            PROXIED SESSION             |                  RECORDED                      |
   |  ======================================|============================================== |
   |                                        |                                                 |
   |  10. Session Data (bidirectional)      |  11. Session Data (bidirectional)              |
   |<-------------------------------------->|<---------------------------------------------- |
   |                                        |                                                 |
   |                          +-------------+-------------+                                  |
   |                          | 12. Recording & Audit      |                                  |
   |                          |     - Write to storage     |                                  |
   |                          |     - Extract metadata     |                                  |
   |                          |     - OCR (RDP)            |                                  |
   |                          +---------------------------+                                  |
   |                                        |                                                 |
```

---

## Storage Architecture

### Data Storage Components

```
+=========================================================================+
|                        STORAGE ARCHITECTURE                              |
+=========================================================================+
|                                                                          |
|  +----------------------------------------------------------------+    |
|  |                      MariaDB Database                          |    |
|  |                                                                 |    |
|  |   * Configuration data                                         |    |
|  |   * User and group definitions                                 |    |
|  |   * Device, account, authorization metadata                    |    |
|  |   * Encrypted credentials (AES-256)                           |    |
|  |   * Audit logs                                                 |    |
|  |   * Session metadata                                           |    |
|  |                                                                 |    |
|  |   Location: /var/lib/mysql/                                   |    |
|  |   Encryption: At-rest encryption supported                     |    |
|  +----------------------------------------------------------------+    |
|                                                                          |
|  +----------------------------------------------------------------+    |
|  |                    Session Recordings                          |    |
|  |                                                                 |    |
|  |   * Video recordings (proprietary format)                      |    |
|  |   * Session metadata files                                     |    |
|  |   * OCR index data (searchable text)                          |    |
|  |   * Keystroke logs                                             |    |
|  |                                                                 |    |
|  |   Location: /var/wab/recorded/                                |    |
|  |   External: NAS/SAN mount supported                           |    |
|  |   Retention: Policy-based                                      |    |
|  +----------------------------------------------------------------+    |
|                                                                          |
|  +----------------------------------------------------------------+    |
|  |                    Configuration Files                         |    |
|  |                                                                 |    |
|  |   * /etc/opt/wab/                    System configuration     |    |
|  |   * /etc/opt/wab/wabengine/          Engine settings          |    |
|  |   * /var/opt/wab/                    Variable data            |    |
|  |                                                                 |    |
|  +----------------------------------------------------------------+    |
|                                                                          |
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
|                      INTEGRATION ARCHITECTURE                            |
+=========================================================================+
|                                                                          |
|                          WALLIX BASTION                                  |
|                               |                                          |
|      +------------------------+------------------------+                |
|      |                        |                        |                |
|      v                        v                        v                |
|  +--------+            +------------+           +------------+         |
|  |IDENTITY|            |   ITSM     |           |    SIEM    |         |
|  |        |            |            |           |            |         |
|  |* LDAP  |            |* ServiceNow|           |* Splunk    |         |
|  |* AD    |            |* Jira      |           |* QRadar    |         |
|  |* SAML  |            |* BMC       |           |* ArcSight  |         |
|  |* RADIUS|            |* Custom    |           |* ELK       |         |
|  +--------+            +------------+           +------------+         |
|      |                        |                        |                |
|      |  LDAP/RADIUS          |  REST API/Webhooks     |  Syslog/CEF   |
|      |                        |                        |                |
|      |                        |                        |                |
|      v                        v                        v                |
|  +--------+            +------------+           +------------+         |
|  |  CMDB  |            | AUTOMATION |           |  SECRETS   |         |
|  |        |            |            |           |            |         |
|  |* ServiceNow|        |* Ansible   |           |* HashiCorp |         |
|  |* i-doit |           |* Terraform |           |* External  |         |
|  |* Custom |           |* Jenkins   |           |  vaults    |         |
|  +--------+            +------------+           +------------+         |
|                                                                          |
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

## Next Steps

Continue to [03 - Core Components](../03-core-components/README.md) for detailed exploration of Session Manager, Password Manager, and Access Manager.
