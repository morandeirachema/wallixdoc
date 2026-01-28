# CyberArk vs WALLIX Bastion - Comparison Guide

> **Purpose**: This document helps users familiar with CyberArk understand WALLIX Bastion through direct comparison. If you know CyberArk, this guide will accelerate your understanding of how WALLIX works.

## Table of Contents

1. [Architecture Comparison](#architecture-comparison)
2. [Component Mapping](#component-mapping)
3. [Password Management: CPM vs Password Manager](#password-management-cpm-vs-password-manager)
4. [Session Management: PSM vs Session Manager](#session-management-psm-vs-session-manager)
5. [OT/Industrial Capabilities](#otindustrial-capabilities)
6. [Feature Matrix](#feature-matrix)
7. [Key Concepts Translation](#key-concepts-translation)

---

## Architecture Comparison

### CyberArk: Multi-Component Architecture

CyberArk uses a distributed architecture with multiple specialized servers:

```
+============================================================================+
|                         CYBERARK ARCHITECTURE                              |
+============================================================================+
|                                                                            |
|                          MANAGEMENT LAYER                                  |
|  +----------------------------------------------------------------------+  |
|  |                                                                      |  |
|  |  +-------------+    +-------------+    +-------------+              |  |
|  |  |    PVWA     |    |   Mobile    |    |  Reports    |              |  |
|  |  | Web Console |    |    App      |    |             |              |  |
|  |  +------+------+    +------+------+    +------+------+              |  |
|  |         |                 |                  |                       |  |
|  +---------|-----------------|------------------|------------------------+  |
|            |                 |                  |                           |
|            +-----------------+------------------+                           |
|                              |                                              |
|                          CORE LAYER                                        |
|  +----------------------------------------------------------------------+  |
|  |                              |                                       |  |
|  |  +========================================================+         |  |
|  |  |                    DIGITAL VAULT                       |         |  |
|  |  |                                                        |         |  |
|  |  |  * Proprietary encrypted filesystem                   |         |  |
|  |  |  * Hardened Windows Server                            |         |  |
|  |  |  * Master Policy (system defaults)                    |         |  |
|  |  |  * Safes (logical credential containers)              |         |  |
|  |  +========================================================+         |  |
|  |                              |                                       |  |
|  +------------------------------|---------------------------------------+  |
|                                 |                                          |
|                        OPERATIONAL LAYER                                   |
|  +----------------------------------------------------------------------+  |
|  |                              |                                       |  |
|  |  +-------------+    +-------------+    +-------------+              |  |
|  |  |     CPM     |    |     PSM     |    |     PTA     |              |  |
|  |  |             |    |             |    |             |              |  |
|  |  | Password    |    | Session     |    | Threat      |              |  |
|  |  | rotation    |    | recording   |    | analytics   |              |  |
|  |  | (Windows)   |    | (Windows)   |    | (ML/AI)     |              |  |
|  |  +-------------+    +-------------+    +-------------+              |  |
|  |                                                                      |  |
|  +----------------------------------------------------------------------+  |
|                                                                            |
|  Typical deployment: 5-10+ servers                                         |
|                                                                            |
+============================================================================+
```

### WALLIX: Unified Appliance Architecture

WALLIX consolidates all PAM functions into a single appliance:

```
+============================================================================+
|                          WALLIX ARCHITECTURE                               |
+============================================================================+
|                                                                            |
|  +----------------------------------------------------------------------+  |
|  |                                                                      |  |
|  |  +================================================================+  |  |
|  |  |                  WALLIX BASTION APPLIANCE                      |  |  |
|  |  |                                                                |  |  |
|  |  |  +----------------+  +----------------+  +----------------+   |  |  |
|  |  |  | Session        |  | Password       |  | Credential     |   |  |  |
|  |  |  | Manager        |  | Manager        |  | Vault          |   |  |  |
|  |  |  |                |  |                |  |                |   |  |  |
|  |  |  | * Protocol     |  | * Rotation     |  | * PostgreSQL   |   |  |  |
|  |  |  |   proxy        |  |   engine       |  | * AES-256-GCM  |   |  |  |
|  |  |  | * Recording    |  | * Connectors   |  | * Argon2ID     |   |  |  |
|  |  |  | * Monitoring   |  | * Verification |  | * HSM optional |   |  |  |
|  |  |  +----------------+  +----------------+  +----------------+   |  |  |
|  |  |                                                                |  |  |
|  |  |  +----------------------------------------------------------+  |  |  |
|  |  |  |                   Web Admin Console                      |  |  |  |
|  |  |  |  Configuration, monitoring, reporting, self-service      |  |  |  |
|  |  |  +----------------------------------------------------------+  |  |  |
|  |  |                                                                |  |  |
|  |  |  +----------------------------------------------------------+  |  |  |
|  |  |  |                   REST API + AAPM                        |  |  |  |
|  |  |  |  Automation, integration, app-to-app credentials         |  |  |  |
|  |  |  +----------------------------------------------------------+  |  |  |
|  |  |                                                                |  |  |
|  |  +================================================================+  |  |
|  |                                                                      |  |
|  +----------------------------------------------------------------------+  |
|                                                                            |
|  Optional: Access Manager (WAM) for external user portal                   |
|  Typical deployment: 1-2 appliances (HA pair)                              |
|                                                                            |
+============================================================================+
```

### Architecture Differences Summary

| Aspect | CyberArk | WALLIX |
|--------|----------|--------|
| **Deployment model** | Multiple specialized servers | Single unified appliance |
| **Typical server count** | 5-10+ servers | 1-2 appliances |
| **Operating system** | Windows Server required | Linux (Debian) based |
| **Vault technology** | Proprietary filesystem | PostgreSQL + AES-256-GCM |
| **Component communication** | Inter-server protocols | Internal (same appliance) |
| **Scaling approach** | Add more component servers | Cluster appliances |

---

## Component Mapping

### Direct Component Equivalents

```
+============================================================================+
|                          COMPONENT MAPPING                                 |
+============================================================================+
|                                                                            |
|  +------------------------+-----------------------+-----------------------+ |
|  | CyberArk               | WALLIX                | How It Works          | |
|  +------------------------+-----------------------+-----------------------+ |
|  |                        |                       |                       | |
|  | Digital Vault          | Credential Vault      | Stores encrypted      | |
|  |                        |                       | credentials           | |
|  | * Proprietary format   | * PostgreSQL backend  |                       | |
|  | * Hardened OS          | * AES-256-GCM encrypt |                       | |
|  | * Safes organize data  | * Domains organize    |                       | |
|  |                        |                       |                       | |
|  +------------------------+-----------------------+-----------------------+ |
|  |                        |                       |                       | |
|  | CPM                    | Password Manager      | Rotates passwords     | |
|  | (Central Policy Mgr)   | (Integrated)          | on target systems     | |
|  |                        |                       |                       | |
|  | * Separate Windows srv | * Built into appliance|                       | |
|  | * CPM Plugins          | * Target Connectors   |                       | |
|  | * Platform definitions | * Custom scripts      |                       | |
|  |                        |                       |                       | |
|  +------------------------+-----------------------+-----------------------+ |
|  |                        |                       |                       | |
|  | PSM                    | Session Manager       | Records and controls  | |
|  | (Privileged Session)   | (Proxy-based)         | privileged sessions   | |
|  |                        |                       |                       | |
|  | * Agent on jump server | * Protocol proxy      |                       | |
|  | * Windows RDP Gateway  | * No agent required   |                       | |
|  | * Proprietary recording| * Native protocol     |                       | |
|  |                        |                       |                       | |
|  +------------------------+-----------------------+-----------------------+ |
|  |                        |                       |                       | |
|  | PVWA                   | Web Admin Console     | Management interface  | |
|  | (Password Vault Web)   |                       |                       | |
|  |                        |                       |                       | |
|  | * Web management UI    | * Web management UI   |                       | |
|  | * User self-service    | * User self-service   |                       | |
|  | * Request workflows    | * Request workflows   |                       | |
|  |                        |                       |                       | |
|  +------------------------+-----------------------+-----------------------+ |
|  |                        |                       |                       | |
|  | CCP/AAM                | AAPM                  | Application           | |
|  | (App Access Manager)   | (App-to-App Password) | credentials           | |
|  |                        |                       |                       | |
|  | * Agent-based          | * REST API based      |                       | |
|  | * SDK available        | * No agent required   |                       | |
|  |                        |                       |                       | |
|  +------------------------+-----------------------+-----------------------+ |
|  |                        |                       |                       | |
|  | PTA                    | Session Analytics +   | Threat detection      | |
|  | (Privileged Threat     | SIEM Integration      |                       | |
|  | Analytics)             |                       |                       | |
|  |                        |                       |                       | |
|  | * Behavioral ML/AI     | * OCR on recordings   |                       | |
|  | * Dedicated server     | * Export to SIEM      |                       | |
|  |                        |                       |                       | |
|  +------------------------+-----------------------+-----------------------+ |
|                                                                            |
+============================================================================+
```

### Object Model Comparison

```
+============================================================================+
|                        OBJECT MODEL COMPARISON                             |
+============================================================================+
|                                                                            |
|  KEY DIFFERENCE: Account-centric vs Device-centric                         |
|                                                                            |
|  CYBERARK (Account-Centric)            WALLIX (Device-Centric)             |
|  ==========================            =======================             |
|                                                                            |
|  +---------------------+              +---------------------+              |
|  |       SAFE          |              |      DOMAIN         |              |
|  |  "Production-Unix"  |              | "Production-Unix"   |              |
|  +---------+-----------+              +---------+-----------+              |
|            |                                    |                          |
|            v                                    v                          |
|  +---------------------+              +---------------------+              |
|  |      ACCOUNT        |              |      DEVICE         |              |
|  | "root-srv-prod-01"  |              |  "srv-prod-01"      |              |
|  |                     |              |                     |              |
|  | Platform: Unix SSH  |              |  +---------------+  |              |
|  | Address: 10.0.1.5   |              |  |   SERVICE     |  |              |
|  | Username: root      |              |  |   SSH:22      |  |              |
|  | Password: ******    |              |  +-------+-------+  |              |
|  +---------------------+              |          |          |              |
|                                       |  +-------+-------+  |              |
|  CyberArk: Account is                 |  |   ACCOUNT     |  |              |
|  the primary object                   |  |   root        |  |              |
|  (contains address)                   |  |   ******      |  |              |
|                                       |  +---------------+  |              |
|                                       +---------------------+              |
|                                                                            |
|                                       WALLIX: Device is primary            |
|                                       object (contains services            |
|                                       and accounts)                        |
|                                                                            |
+============================================================================+
```

### Terminology Quick Reference

| CyberArk Term | WALLIX Term | Notes |
|---------------|-------------|-------|
| Safe | Domain | Logical container for organizing assets |
| Platform | Device Type + Service | Connection definition |
| Account | Account | Privileged credential |
| Safe Member | Authorization | Access permission |
| Dual Control | Approval Workflow | Requires approver |
| Exclusive Access | Exclusive Checkout | One user at a time |
| PSM Connection Component | Service (Protocol) | How to connect |
| CPM Plugin | Target Connector | Platform-specific rotation |
| Reconciliation Account | Reconciliation Account | Same concept |
| Master Policy | Global Settings | System defaults |

---

## Password Management: CPM vs Password Manager

### CyberArk CPM

```
+============================================================================+
|                            CYBERARK CPM                                    |
+============================================================================+
|                                                                            |
|  ARCHITECTURE                                                              |
|  ============                                                              |
|                                                                            |
|  +----------------------------------------------------------------------+  |
|  |                       CPM SERVER (Windows)                           |  |
|  |                                                                      |  |
|  |  +-----------------------+    +--------------------------+          |  |
|  |  |    CPM Service        |    |    Plugin Framework      |          |  |
|  |  |                       |    |                          |          |  |
|  |  | * Task scheduling     |    | +----------------------+ |          |  |
|  |  | * Queue management    |    | |  Windows Plugin      | |          |  |
|  |  | * Retry logic         |    | +----------------------+ |          |  |
|  |  +-----------------------+    | |  Unix/SSH Plugin     | |          |  |
|  |                               | +----------------------+ |          |  |
|  |  +-----------------------+    | |  Database Plugins    | |          |  |
|  |  |  Vault Connection     |    | +----------------------+ |          |  |
|  |  |                       |    | |  Network Plugins     | |          |  |
|  |  | * Get credentials     |    | +----------------------+ |          |  |
|  |  | * Update passwords    |    | |  Cloud Plugins       | |          |  |
|  |  +-----------------------+    | +----------------------+ |          |  |
|  |                               | |  Custom Plugins      | |          |  |
|  |                               | +----------------------+ |          |  |
|  |                               +--------------------------+          |  |
|  +----------------------------------------------------------------------+  |
|                                                                            |
|  CHARACTERISTICS                                                           |
|  ===============                                                           |
|                                                                            |
|  * Separate Windows Server installation                                    |
|  * Plugins written in C/C++ or .NET                                        |
|  * Wide platform coverage (many pre-built plugins)                         |
|  * Platform definitions control connection behavior                        |
|  * Can scale by adding more CPM servers                                    |
|                                                                            |
+============================================================================+
```

### WALLIX Password Manager

```
+============================================================================+
|                        WALLIX PASSWORD MANAGER                             |
+============================================================================+
|                                                                            |
|  ARCHITECTURE                                                              |
|  ============                                                              |
|                                                                            |
|  +----------------------------------------------------------------------+  |
|  |                   WALLIX BASTION (Integrated)                        |  |
|  |                                                                      |  |
|  |  +================================================================+  |  |
|  |  |                    PASSWORD MANAGER                            |  |  |
|  |  |                                                                |  |  |
|  |  |  +--------------------+    +--------------------------+       |  |  |
|  |  |  |  Rotation Engine   |    |   Target Connectors      |       |  |  |
|  |  |  |                    |    |                          |       |  |  |
|  |  |  | * Scheduled jobs   |    | +----------------------+ |       |  |  |
|  |  |  | * On-demand        |    | | SSH (Unix/Linux)     | |       |  |  |
|  |  |  | * Post-session     |    | +----------------------+ |       |  |  |
|  |  |  | * Event triggers   |    | | WinRM (Windows)      | |       |  |  |
|  |  |  +--------------------+    | +----------------------+ |       |  |  |
|  |  |                            | | LDAP (AD)            | |       |  |  |
|  |  |  +--------------------+    | +----------------------+ |       |  |  |
|  |  |  | Credential Vault   |    | | Database Connectors  | |       |  |  |
|  |  |  |                    |    | +----------------------+ |       |  |  |
|  |  |  | * PostgreSQL       |    | | Network Devices      | |       |  |  |
|  |  |  | * AES-256-GCM      |    | +----------------------+ |       |  |  |
|  |  |  | * Argon2ID KDF     |    | | Custom Scripts       | |       |  |  |
|  |  |  +--------------------+    | | (Bash, Python)       | |       |  |  |
|  |  |                            | +----------------------+ |       |  |  |
|  |  |                            +--------------------------+       |  |  |
|  |  +================================================================+  |  |
|  +----------------------------------------------------------------------+  |
|                                                                            |
|  CHARACTERISTICS                                                           |
|  ===============                                                           |
|                                                                            |
|  * Integrated in Bastion appliance (no separate server)                    |
|  * Target connectors for common platforms                                  |
|  * Custom scripts in Bash/Python for proprietary systems                   |
|  * Lighter footprint, simpler architecture                                 |
|  * Scales with appliance clustering                                        |
|                                                                            |
+============================================================================+
```

### Rotation Capabilities Comparison

| Capability | CyberArk CPM | WALLIX Password Manager |
|------------|--------------|-------------------------|
| **Scheduled rotation** | Native | Native |
| **On-demand rotation** | Native | Native |
| **Post-session rotation** | Native | Native |
| **Rotation triggers** | Time, event, use-count | Time, event, session-end |
| **Password verification** | Native | Native |
| **Reconciliation** | Native | Native |
| **SSH key rotation** | Native | Native |
| **Custom platforms** | C/.NET plugins | Bash/Python scripts |
| **Deployment** | Separate Windows server | Integrated in appliance |

### Target Connector Comparison

| Target System | CyberArk | WALLIX |
|---------------|----------|--------|
| Windows Local | Native plugin | WinRM connector |
| Windows Domain | Native plugin + LDAP | LDAP connector |
| Linux/Unix | Unix plugin (SSH) | SSH connector |
| Cisco/Network | Platform plugins | SSH/Telnet connectors |
| Oracle/SQL/MySQL | Database plugins | DB connectors |
| AWS/Azure/GCP | Cloud plugins | API connectors |
| HMI/SCADA | Custom plugin needed | Custom script |
| Proprietary | C/.NET plugin (complex) | Bash/Python script (simpler) |

---

## Session Management: PSM vs Session Manager

### CyberArk PSM Model

```
+============================================================================+
|                            CYBERARK PSM                                    |
+============================================================================+
|                                                                            |
|  CONNECTION FLOW                                                           |
|  ===============                                                           |
|                                                                            |
|       +------------+                                                       |
|       |    User    |                                                       |
|       +-----+------+                                                       |
|             |                                                              |
|             | 1. RDP to PSM server                                         |
|             v                                                              |
|       +------------+                                                       |
|       |   PVWA     |  2. Authenticate, select target                       |
|       +-----+------+                                                       |
|             |                                                              |
|             | 3. Session routed to PSM                                     |
|             v                                                              |
|       +============+                                                       |
|       |    PSM     |  4. PSM initiates connection to target                |
|       |   Server   |     (credentials injected)                            |
|       | (Windows)  |                                                       |
|       +-----+------+                                                       |
|             |                                                              |
|             | 5. RDP/SSH to target                                         |
|             v                                                              |
|       +------------+                                                       |
|       |   Target   |                                                       |
|       |   System   |                                                       |
|       +------------+                                                       |
|                                                                            |
|  CHARACTERISTICS                                                           |
|  ===============                                                           |
|                                                                            |
|  * Windows Server required for PSM                                         |
|  * Agent-based approach                                                    |
|  * RDP Gateway mode for RDP sessions                                       |
|  * Recording stored on PSM server                                          |
|  * Session isolation on PSM                                                |
|                                                                            |
+============================================================================+
```

### WALLIX Session Manager Model

```
+============================================================================+
|                        WALLIX SESSION MANAGER                              |
+============================================================================+
|                                                                            |
|  CONNECTION FLOW                                                           |
|  ===============                                                           |
|                                                                            |
|       +------------+                                                       |
|       |    User    |                                                       |
|       +-----+------+                                                       |
|             |                                                              |
|             | 1. SSH/RDP/VNC/HTTP directly to Bastion                      |
|             |    (native protocol)                                         |
|             v                                                              |
|       +============+                                                       |
|       |  WALLIX    |  2. Authenticate, authorize                           |
|       |  Bastion   |  3. Credentials injected (user never sees)            |
|       |  (Proxy)   |  4. Session recorded at protocol level                |
|       +-----+------+                                                       |
|             |                                                              |
|             | 5. Proxied connection to target                              |
|             v                                                              |
|       +------------+                                                       |
|       |   Target   |                                                       |
|       |   System   |                                                       |
|       +------------+                                                       |
|                                                                            |
|  CHARACTERISTICS                                                           |
|  ===============                                                           |
|                                                                            |
|  * No agent or jump server required                                        |
|  * Native protocol proxying (SSH, RDP, VNC, HTTP, Telnet)                  |
|  * User connects directly through Bastion                                  |
|  * Recording at protocol level                                             |
|  * Lighter infrastructure                                                  |
|                                                                            |
+============================================================================+
```

### Session Capabilities Comparison

| Capability | CyberArk PSM | WALLIX Session Manager |
|------------|--------------|------------------------|
| **SSH proxy** | Via PSM agent | Native protocol proxy |
| **RDP proxy** | RDP Gateway mode | Native protocol proxy |
| **VNC proxy** | Limited | Native protocol proxy |
| **HTTP/HTTPS** | Via PSM | Native protocol proxy |
| **Telnet** | Via PSM | Native protocol proxy |
| **Video recording** | Proprietary format | WAB format |
| **Keystroke logging** | Yes | Yes |
| **OCR on recordings** | Yes | Yes |
| **Live monitoring** | Yes | Yes |
| **Session termination** | Yes | Yes |
| **4-eyes (dual auth)** | Yes | Yes |
| **Server requirement** | Windows Server | Integrated (Linux) |

---

## OT/Industrial Capabilities

### Industrial Environment Comparison

```
+============================================================================+
|                       OT/INDUSTRIAL COMPARISON                             |
+============================================================================+
|                                                                            |
|  +---------------------------+----------------------+--------------------+ |
|  | Capability                | CyberArk             | WALLIX             | |
|  +---------------------------+----------------------+--------------------+ |
|  |                           |                      |                    | |
|  | ARCHITECTURE FOR OT       |                      |                    | |
|  | ~~~~~~~~~~~~~~~~~~~       |                      |                    | |
|  | Unified appliance         | Multi-component      | Single appliance   | |
|  | Air-gapped deployment     | Complex (Vault need) | Native support     | |
|  | Offline credential cache  | Not native           | Built-in           | |
|  | Windows-free OT zone      | Requires Windows     | Linux-based        | |
|  |                           |                      |                    | |
|  +---------------------------+----------------------+--------------------+ |
|  |                           |                      |                    | |
|  | PROTOCOL SUPPORT          |                      |                    | |
|  | ~~~~~~~~~~~~~~~~          |                      |                    | |
|  | SSH/RDP/VNC               | Via PSM              | Native proxy       | |
|  | HTTP/HTTPS                | Via PSM              | Native proxy       | |
|  | Telnet (legacy)           | Via PSM              | Native proxy       | |
|  | Universal tunneling       | PSM tunneling        | Native tunneling   | |
|  |                           |                      |                    | |
|  +---------------------------+----------------------+--------------------+ |
|  |                           |                      |                    | |
|  | INDUSTRIAL ACCESS         |                      |                    | |
|  | ~~~~~~~~~~~~~~~~~         |                      |                    | |
|  | HMI shared accounts       | Credential injection | Credential inject  | |
|  | Individual accountability | Via session record   | Via session record | |
|  | Engineering station       | RDP via PSM          | RDP via proxy      | |
|  | Modbus/OPC UA (via jump)  | Via PSM RDP          | Via session        | |
|  |                           |                      |                    | |
|  +---------------------------+----------------------+--------------------+ |
|  |                           |                      |                    | |
|  | COMPLIANCE                |                      |                    | |
|  | ~~~~~~~~~~                |                      |                    | |
|  | IEC 62443 focus           | General PAM          | Native OT focus    | |
|  | NERC CIP                  | Good support         | Good support       | |
|  | NIST 800-82               | Documented           | Documented         | |
|  |                           |                      |                    | |
|  +---------------------------+----------------------+--------------------+ |
|  |                           |                      |                    | |
|  | OT VENDOR ECOSYSTEM       |                      |                    | |
|  | ~~~~~~~~~~~~~~~~~~~       |                      |                    | |
|  | Schneider Electric i-PAM  | No partnership       | OEM partnership    | |
|  | Industrial integrations   | Generic              | Focused            | |
|  |                           |                      |                    | |
|  +---------------------------+----------------------+--------------------+ |
|                                                                            |
+============================================================================+
```

### OT Deployment Architecture

```
+============================================================================+
|                       OT DEPLOYMENT COMPARISON                             |
+============================================================================+
|                                                                            |
|      CYBERARK IN OT                         WALLIX IN OT                   |
|      ==============                         ============                   |
|                                                                            |
|   +--------------------+                +--------------------+             |
|   |    IT Network      |                |    IT Network      |             |
|   |                    |                |                    |             |
|   | +----------------+ |                | +----------------+ |             |
|   | | Vault + PVWA   | |                | | Bastion (HA)   | |             |
|   | | + PTA          | |                | | + Access Mgr   | |             |
|   | | (3+ servers)   | |                | | (1-2 servers)  | |             |
|   | +----------------+ |                | +----------------+ |             |
|   +--------+-----------+                +--------+-----------+             |
|            |                                     |                         |
|      [Firewall]                            [Firewall]                      |
|            |                                     |                         |
|   +--------+-----------+                +--------+-----------+             |
|   |    OT DMZ          |                |    OT DMZ          |             |
|   |                    |                |                    |             |
|   | +------+ +-------+ |                | +----------------+ |             |
|   | | CPM  | | PSM   | |                | |   Bastion      | |             |
|   | |(Win) | |(Win)  | |                | |   (unified)    | |             |
|   | +------+ +-------+ |                | +----------------+ |             |
|   | (2 Windows servers)|                | (1 Linux appl.)    |             |
|   +--------+-----------+                +--------+-----------+             |
|            |                                     |                         |
|      [Firewall]                            [Firewall]                      |
|            |                                     |                         |
|   +--------+-----------+                +--------+-----------+             |
|   |  Control Network   |                |  Control Network   |             |
|   |                    |                |                    |             |
|   | [SCADA] [HMI]      |                | [SCADA] [HMI]      |             |
|   | [Eng WS] [PLC]     |                | [Eng WS] [PLC]     |             |
|   +--------------------+                +--------------------+             |
|                                                                            |
|   Servers in OT: 5+                     Servers in OT: 2-3                 |
|   Windows in OT: Required               Windows in OT: Not required       |
|                                                                            |
+============================================================================+
```

---

## Feature Matrix

### Complete Feature Comparison

```
+============================================================================+
|                         FEATURE COMPARISON                                 |
+============================================================================+
|                                                                            |
|  AUTHENTICATION                                                            |
|  ==============                                                            |
|  +--------------------------------+------------------+------------------+  |
|  | Feature                        | CyberArk         | WALLIX           |  |
|  +--------------------------------+------------------+------------------+  |
|  | Local accounts                 | Yes              | Yes              |  |
|  | LDAP/Active Directory          | Yes              | Yes              |  |
|  | RADIUS                         | Yes              | Yes              |  |
|  | SAML 2.0                       | Yes              | Yes              |  |
|  | OpenID Connect (OIDC)          | Yes              | Yes              |  |
|  | Kerberos                       | Yes              | Yes              |  |
|  | Smart cards / X.509            | Yes              | Yes              |  |
|  | TOTP (Google Auth, etc.)       | Yes              | Yes              |  |
|  | FIDO2 / WebAuthn               | Yes              | Yes              |  |
|  +--------------------------------+------------------+------------------+  |
|                                                                            |
|  PASSWORD MANAGEMENT                                                       |
|  ===================                                                       |
|  +--------------------------------+------------------+------------------+  |
|  | Feature                        | CyberArk         | WALLIX           |  |
|  +--------------------------------+------------------+------------------+  |
|  | Encrypted vault                | Proprietary      | PostgreSQL+AES   |  |
|  | Automatic rotation             | Yes              | Yes              |  |
|  | Scheduled rotation             | Yes              | Yes              |  |
|  | Post-session rotation          | Yes              | Yes              |  |
|  | Password verification          | Yes              | Yes              |  |
|  | Reconciliation                 | Yes              | Yes              |  |
|  | SSH key management             | Yes              | Yes              |  |
|  | Checkout workflow              | Yes              | Yes              |  |
|  | Custom password policies       | Yes              | Yes              |  |
|  +--------------------------------+------------------+------------------+  |
|                                                                            |
|  SESSION MANAGEMENT                                                        |
|  ==================                                                        |
|  +--------------------------------+------------------+------------------+  |
|  | Feature                        | CyberArk         | WALLIX           |  |
|  +--------------------------------+------------------+------------------+  |
|  | SSH proxy                      | PSM agent        | Native proxy     |  |
|  | RDP proxy                      | PSM agent        | Native proxy     |  |
|  | VNC proxy                      | Limited          | Native proxy     |  |
|  | Video recording                | Yes              | Yes              |  |
|  | Keystroke logging              | Yes              | Yes              |  |
|  | OCR on recordings              | Yes              | Yes              |  |
|  | Live monitoring                | Yes              | Yes              |  |
|  | Session termination            | Yes              | Yes              |  |
|  | 4-eyes (dual authorization)    | Yes              | Yes              |  |
|  +--------------------------------+------------------+------------------+  |
|                                                                            |
|  AUTHORIZATION                                                             |
|  =============                                                             |
|  +--------------------------------+------------------+------------------+  |
|  | Feature                        | CyberArk         | WALLIX           |  |
|  +--------------------------------+------------------+------------------+  |
|  | Role-based access              | Yes              | Yes              |  |
|  | Approval workflows             | Yes              | Yes              |  |
|  | Multi-level approval           | Yes              | Yes              |  |
|  | Time-based access              | Yes              | Yes              |  |
|  | Just-in-time access            | Yes              | Yes              |  |
|  | Emergency/break-glass          | Yes              | Yes              |  |
|  +--------------------------------+------------------+------------------+  |
|                                                                            |
|  INTEGRATION                                                               |
|  ===========                                                               |
|  +--------------------------------+------------------+------------------+  |
|  | Feature                        | CyberArk         | WALLIX           |  |
|  +--------------------------------+------------------+------------------+  |
|  | REST API                       | Yes              | Yes              |  |
|  | SIEM integration               | Yes              | Yes              |  |
|  | Terraform provider             | Yes              | Yes              |  |
|  | ServiceNow integration         | Yes              | Yes              |  |
|  | Secrets management (DevOps)    | Conjur           | AAPM/API         |  |
|  +--------------------------------+------------------+------------------+  |
|                                                                            |
|  HIGH AVAILABILITY                                                         |
|  =================                                                         |
|  +--------------------------------+------------------+------------------+  |
|  | Feature                        | CyberArk         | WALLIX           |  |
|  +--------------------------------+------------------+------------------+  |
|  | Active-Active clustering       | PSM only         | Yes              |  |
|  | Active-Passive failover        | Yes              | Yes              |  |
|  | Geographic distribution        | Yes              | Yes              |  |
|  +--------------------------------+------------------+------------------+  |
|                                                                            |
+============================================================================+
```

---

## Key Concepts Translation

### Quick Reference for CyberArk Users

```
+============================================================================+
|                         THINKING IN WALLIX                                 |
+============================================================================+
|                                                                            |
|  IF YOU KNOW CYBERARK, HERE'S HOW WALLIX WORKS:                            |
|  ==============================================                            |
|                                                                            |
|  1. OBJECT MODEL                                                           |
|     ============                                                           |
|                                                                            |
|     CyberArk: Account-centric                                              |
|       "I have an account that connects to an address"                      |
|                                                                            |
|     WALLIX: Device-centric                                                 |
|       "I have a device with services and accounts on it"                   |
|                                                                            |
|  2. ARCHITECTURE                                                           |
|     ============                                                           |
|                                                                            |
|     CyberArk: Multiple specialized servers                                 |
|       Vault + CPM + PSM + PVWA + PTA = 5+ servers                          |
|                                                                            |
|     WALLIX: Single unified appliance                                       |
|       Everything in one box (or HA pair)                                   |
|                                                                            |
|  3. SESSION MANAGEMENT                                                     |
|     ==================                                                     |
|                                                                            |
|     CyberArk: User -> PSM Windows Server -> Target                         |
|       (Agent-based, jump server model)                                     |
|                                                                            |
|     WALLIX: User -> Bastion Proxy -> Target                                |
|       (Transparent proxy, no jump server)                                  |
|                                                                            |
|  4. PASSWORD ROTATION                                                      |
|     =================                                                      |
|                                                                            |
|     CyberArk: CPM Windows server with compiled plugins                     |
|                                                                            |
|     WALLIX: Integrated Password Manager with connectors/scripts            |
|                                                                            |
|  5. TERMINOLOGY                                                            |
|     ===========                                                            |
|                                                                            |
|     Safe              ==>    Domain                                        |
|     Platform          ==>    Device Type + Service                         |
|     PSM Component     ==>    Service                                       |
|     CPM Plugin        ==>    Target Connector / Script                     |
|     Safe Member       ==>    Authorization                                 |
|     Dual Control      ==>    Approval Workflow                             |
|                                                                            |
+============================================================================+
```

### Strengths Summary

| Use Case | Better Choice | Why |
|----------|---------------|-----|
| Large enterprise (50K+ accounts) | CyberArk | Horizontal scaling, mature ecosystem |
| OT/Industrial | WALLIX | Native OT focus, air-gapped support, IEC 62443 |
| Simple deployment | WALLIX | Single appliance, faster setup |
| Windows-free OT | WALLIX | Linux-based, no Windows needed |
| DevSecOps secrets | CyberArk | Conjur is mature |
| Behavioral analytics | CyberArk | PTA has ML/AI |
| European sovereignty | WALLIX | EU-based vendor |
| Mid-market | WALLIX | Lower TCO, simpler |

---

## Related Documentation

- [Password Management](../07-password-management/README.md) - WALLIX credential vault and rotation
- [Session Management](../08-session-management/README.md) - WALLIX session recording and monitoring
- [Configuration](../04-configuration/README.md) - WALLIX object model (devices, services, accounts)
- [Authorization](../06-authorization/README.md) - WALLIX RBAC and approval workflows
- [Industrial Protocols](../17-industrial-protocols/README.md) - OT protocol support
- [SCADA/ICS Access](../18-scada-ics-access/README.md) - Industrial access control
- [Air-Gapped Environments](../19-airgapped-environments/README.md) - Isolated deployments
