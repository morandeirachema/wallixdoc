# 03 - Core Components Deep Dive

## Table of Contents

1. [Session Manager](#session-manager)
2. [Password Manager](#password-manager)
3. [Access Manager](#access-manager)
4. [Component Interaction](#component-interaction)

---

## Session Manager

### Overview

The **Session Manager** is the heart of WALLIX Bastion, responsible for all privileged session brokering, monitoring, and recording.

**CyberArk Equivalent**: PSM (Privileged Session Manager) + PVWA session components

### Architecture

```
+===============================================================================+
|                            SESSION MANAGER                                    |
+===============================================================================+
|                                                                               |
|  +-------------------------------------------------------------------------+  |
|  |                       PROTOCOL HANDLERS                                 |  |
|  |                                                                         |  |
|  |  +----------+ +----------+ +----------+ +----------+ +----------+       |  |
|  |  |   SSH    | |   RDP    | |  HTTPS   | |   VNC    | |  TELNET  |       |  |
|  |  |  Handler | |  Handler | |  Handler | |  Handler | |  Handler |       |  |
|  |  |          | |          | |          | |          | |          |       |  |
|  |  | * SCP    | | * NLA    | | * Web    | | * Auth   | | * Plain  |       |  |
|  |  | * SFTP   | | * TLS    | |   Apps   | | * VNC    | | * SSL    |       |  |
|  |  | * X11    | | * RD GW  | | * REST   | |   Auth   | |          |       |  |
|  |  +----------+ +----------+ +----------+ +----------+ +----------+       |  |
|  |                                                                         |  |
|  |  +----------+ +----------+ +----------+                                 |  |
|  |  |  RLOGIN  | |  CUSTOM  | | RAW TCP  |                                 |  |
|  |  |  Handler | |  Plugins | |  Tunnel  |                                 |  |
|  |  +----------+ +----------+ +----------+                                 |  |
|  +-------------------------------------------------------------------------+  |
|                                                                               |
|  +---------------------------+     +---------------------------+              |
|  |   SESSION BROKER          |     |   RECORDING ENGINE        |              |
|  |                           |     |                           |              |
|  | * Connection routing      |     | * Video capture           |              |
|  | * Load balancing          |     | * Keystroke logging       |              |
|  | * Session tracking        |     | * OCR processing          |              |
|  | * Failover handling       |     | * Metadata extraction     |              |
|  +---------------------------+     +---------------------------+              |
|                                                                               |
|  +---------------------------+     +---------------------------+              |
|  |   MONITORING ENGINE       |     |   AUDIT LOGGER            |              |
|  |                           |     |                           |              |
|  | * Real-time view          |     | * Action logging          |              |
|  | * Session sharing         |     | * Compliance reports      |              |
|  | * Kill capability         |     | * Alert generation        |              |
|  | * Alert triggers          |     | * SIEM integration        |              |
|  +---------------------------+     +---------------------------+              |
|                                                                               |
+===============================================================================+
```

### Supported Protocols

#### SSH Protocol Handler

```
+===============================================================================+
|                            SSH HANDLER                                        |
+===============================================================================+
|                                                                               |
|  Main Protocols:                                                              |
|  +-- SSH (Interactive shell)                                                  |
|  +-- SCP (Secure copy)                                                        |
|  +-- SFTP (File transfer)                                                     |
|  +-- SSH Tunneling (Port forwarding)                                          |
|                                                                               |
|  Authentication Methods:                                                      |
|  +-- Password                                                                 |
|  +-- SSH Key (RSA, ECDSA, Ed25519)                                            |
|  +-- Keyboard-Interactive                                                     |
|  +-- Certificate-based                                                        |
|                                                                               |
|  Subprotocol Control:                                                         |
|  +-- Allow/deny shell access                                                  |
|  +-- Allow/deny SCP                                                           |
|  +-- Allow/deny SFTP                                                          |
|  +-- Allow/deny X11 forwarding                                                |
|  +-- Allow/deny port forwarding                                               |
|                                                                               |
|  Recording:                                                                   |
|  +-- Full session recording                                                   |
|  +-- Command logging                                                          |
|  +-- File transfer logging                                                    |
|                                                                               |
+===============================================================================+
```

**SSH Configuration Options:**

| Option | Description | Default |
|--------|-------------|---------|
| `shell_enabled` | Allow interactive shell | Yes |
| `scp_enabled` | Allow SCP file transfer | Yes |
| `sftp_enabled` | Allow SFTP file transfer | Yes |
| `x11_enabled` | Allow X11 forwarding | No |
| `tunnel_enabled` | Allow port forwarding | No |
| `agent_forwarding` | Allow SSH agent forwarding | No |

---

#### RDP Protocol Handler

```
+===============================================================================+
|                            RDP HANDLER                                        |
+===============================================================================+
|                                                                               |
|  Connection Methods:                                                          |
|  +-- Standard RDP                                                             |
|  +-- RDP over TLS (recommended)                                               |
|  +-- Network Level Authentication (NLA)                                       |
|  +-- RD Gateway integration                                                   |
|                                                                               |
|  Security Modes:                                                              |
|  +-- RDP Security Layer                                                       |
|  +-- TLS Security Layer                                                       |
|  +-- CredSSP (NLA)                                                            |
|  +-- Hybrid mode                                                              |
|                                                                               |
|  Subprotocol Control:                                                         |
|  +-- Clipboard redirection (allow/deny)                                       |
|  +-- Drive redirection (allow/deny)                                           |
|  +-- Printer redirection (allow/deny)                                         |
|  +-- Smart card redirection (allow/deny)                                      |
|  +-- Audio redirection (allow/deny)                                           |
|                                                                               |
|  Recording Features:                                                          |
|  +-- Video recording (screen capture)                                         |
|  +-- OCR processing (searchable content)                                      |
|  +-- Keystroke logging                                                        |
|  +-- Clipboard content logging                                                |
|  +-- File transfer logging                                                    |
|                                                                               |
|  Performance Options:                                                         |
|  +-- Color depth control                                                      |
|  +-- Compression settings                                                     |
|  +-- Bandwidth optimization                                                   |
|                                                                               |
+===============================================================================+
```

**RDP Security Levels:**

| Level | Description | Use Case |
|-------|-------------|----------|
| **Any** | Accept any security level | Legacy compatibility |
| **RDP** | RDP native security | Not recommended |
| **TLS** | TLS encryption | Standard deployments |
| **NLA** | Network Level Auth | Highest security |

---

#### VNC Protocol Handler

```
+===============================================================================+
|                            VNC HANDLER                                        |
+===============================================================================+
|                                                                               |
|  Supported Versions:                                                          |
|  +-- RFB Protocol 3.3, 3.7, 3.8                                               |
|  +-- TightVNC extensions                                                      |
|  +-- UltraVNC extensions                                                      |
|                                                                               |
|  Authentication:                                                              |
|  +-- VNC Password                                                             |
|  +-- No authentication (if target allows)                                     |
|  +-- Certificate-based (UltraVNC)                                             |
|                                                                               |
|  Recording:                                                                   |
|  +-- Video recording                                                          |
|  +-- Input event logging                                                      |
|                                                                               |
+===============================================================================+
```

---

#### HTTP/HTTPS Protocol Handler

```
+===============================================================================+
|                         HTTP/HTTPS HANDLER                                    |
+===============================================================================+
|                                                                               |
|  Use Cases:                                                                   |
|  +-- Web application access                                                   |
|  +-- REST API management interfaces                                           |
|  +-- Network device web consoles                                              |
|  +-- Cloud management consoles                                                |
|                                                                               |
|  Features:                                                                    |
|  +-- URL filtering                                                            |
|  +-- Request/response logging                                                 |
|  +-- Credential injection (form-based)                                        |
|  +-- Session recording (screenshots)                                          |
|                                                                               |
|  Authentication:                                                              |
|  +-- Basic authentication                                                     |
|  +-- Form-based authentication                                                |
|  +-- Certificate-based authentication                                         |
|                                                                               |
+===============================================================================+
```

---

### Session Recording

#### Recording Architecture

```
+===============================================================================+
|                       SESSION RECORDING FLOW                                  |
+===============================================================================+
|                                                                               |
|  User Session                                                                 |
|      |                                                                        |
|      v                                                                        |
|  +-----------------------------------------------------------------------+    |
|  |                      RECORDING ENGINE                                 |    |
|  |                                                                       |    |
|  |  +-----------------+  +-----------------+  +-----------------+        |    |
|  |  |  Screen Capture |  | Keystroke Logger|  | Metadata Extract|        |    |
|  |  |                 |  |                 |  |                 |        |    |
|  |  | * Video frames  |  | * Commands      |  | * User info     |        |    |
|  |  | * Delta encoding|  | * Inputs        |  | * Target info   |        |    |
|  |  |                 |  | * Clipboard     |  | * Timestamps    |        |    |
|  |  +--------+--------+  +--------+--------+  +--------+--------+        |    |
|  |           |                    |                    |                 |    |
|  |           +--------------------+--------------------+                 |    |
|  |                                |                                      |    |
|  |                                v                                      |    |
|  |                   +------------------------+                          |    |
|  |                   |    Recording File      |                          |    |
|  |                   |    (.wab format)       |                          |    |
|  |                   +-----------+------------+                          |    |
|  +-----------------------------|-----------------------------------------+    |
|                                |                                              |
|                                v                                              |
|  +-----------------------------------------------------------------------+    |
|  |                      POST-PROCESSING                                  |    |
|  |                                                                       |    |
|  |  +-----------------+  +-----------------+  +-----------------+        |    |
|  |  | OCR Processing  |  | Index Creation  |  | Archive Storage |        |    |
|  |  |   (RDP only)    |  |                 |  |                 |        |    |
|  |  +-----------------+  +-----------------+  +-----------------+        |    |
|  +-----------------------------------------------------------------------+    |
|                                                                               |
+===============================================================================+
```

#### Recording Types by Protocol

| Protocol | Recording Type | Searchable | File Size |
|----------|---------------|------------|-----------|
| **RDP** | Video + keystrokes + OCR | Yes (OCR) | Large (50-200 MB/hr) |
| **SSH** | Text + commands | Yes (native) | Small (1-5 MB/hr) |
| **VNC** | Video + input | Limited | Medium (20-100 MB/hr) |
| **HTTP** | Screenshots + requests | Yes (logs) | Variable |
| **Telnet** | Text | Yes (native) | Small |

#### Recording Storage

```
Recording File Structure
========================

/var/wab/recorded/
+-- YYYY/
|   +-- MM/
|       +-- DD/
|           +-- session_id_1.wab          # Recording file
|           +-- session_id_1.wab.meta     # Metadata
|           +-- session_id_1.wab.idx      # Search index
|           +-- session_id_1.wab.ocr      # OCR data (RDP)
```

#### Recording Retention Policies

| Policy Type | Configuration | Example |
|-------------|--------------|---------|
| **Time-based** | Delete after X days | 90 days retention |
| **Size-based** | Delete when storage exceeds X | 500 GB limit |
| **Quota-based** | Per-domain limits | 100 GB per domain |
| **Archive** | Move to cold storage | After 30 days |

---

### Real-Time Session Monitoring

#### Monitoring Capabilities

```
+===============================================================================+
|                          REAL-TIME MONITORING                                 |
+===============================================================================+
|                                                                               |
|  +------------------------------------------------------------------------+   |
|  |                      ACTIVE SESSIONS VIEW                              |   |
|  |                                                                        |   |
|  |  Session ID    User        Target           Protocol  Duration        |   |
|  |  ----------    ----        ------           --------  --------        |   |
|  |  SES-001       jsmith      srv-prod-01      SSH       00:45:12        |   |
|  |  SES-002       admin       dc01.corp        RDP       01:23:45        |   |
|  |  SES-003       dbadmin     oracle-prd       SQL*Plus  00:12:30        |   |
|  |                                                                        |   |
|  |  [View] [Share] [Message] [Kill]                                      |   |
|  +------------------------------------------------------------------------+   |
|                                                                               |
|  Monitoring Actions:                                                          |
|  -------------------                                                          |
|  VIEW      Watch session in real-time (shadow mode)                           |
|  SHARE     Join session (4-eyes / dual control)                               |
|  MESSAGE   Send message to session user                                       |
|  KILL      Terminate session immediately                                      |
|                                                                               |
|  Alerting:                                                                    |
|  ---------                                                                    |
|  * Command-based alerts (detect "rm -rf", "drop table", etc.)                 |
|  * Keyword detection in sessions                                              |
|  * Unusual activity patterns                                                  |
|  * Session duration alerts                                                    |
|                                                                               |
+===============================================================================+
```

#### 4-Eyes Principle (Session Sharing)

```
4-EYES SESSION WORKFLOW
=======================

+----------+                           +----------+
| Operator |                           | Approver |
+----+-----+                           +----+-----+
     |                                      |
     |  1. Request critical session         |
     |------------------------------------->|
     |                                      |
     |  2. Approver joins session           |
     |<-------------------------------------|
     |                                      |
     |  ================================   |
     |         SHARED SESSION               |
     |  ================================   |
     |                                      |
     |  * Both users see same screen        |
     |  * Both can interact (if allowed)    |
     |  * Approver can terminate anytime    |
     |                                      |
     |  3. Session ends                     |
     |<------------------------------------>|
     |                                      |
```

---

## Password Manager

### Overview

The **Password Manager** provides secure credential storage, automatic rotation, and transparent credential injection.

**CyberArk Equivalent**: Digital Vault + CPM (Central Policy Manager)

### Architecture

```
+===============================================================================+
|                           PASSWORD MANAGER                                    |
+===============================================================================+
|                                                                               |
|  +-----------------------------------------------------------------------+    |
|  |                      CREDENTIAL VAULT                                 |    |
|  |                                                                       |    |
|  |  +---------------+  +---------------+  +---------------+              |    |
|  |  |  Passwords    |  |  SSH Keys     |  | Certificates  |              |    |
|  |  |               |  |               |  |               |              |    |
|  |  | * Local       |  | * Private keys|  | * X.509       |              |    |
|  |  | * Domain      |  | * Key pairs   |  | * Client certs|              |    |
|  |  | * Service     |  | * Passphrases |  | * CA certs    |              |    |
|  |  | * Database    |  |               |  |               |              |    |
|  |  +---------------+  +---------------+  +---------------+              |    |
|  |                                                                       |    |
|  |  Encryption: AES-256-GCM    Key Management: Master key + optional HSM |    |
|  +-----------------------------------------------------------------------+    |
|                                                                               |
|  +-------------------------------+  +-------------------------------+         |
|  |   ROTATION ENGINE             |  |   INJECTION ENGINE            |         |
|  |                               |  |                               |         |
|  | * Scheduled rotation          |  | * Protocol-aware              |         |
|  | * On-demand rotation          |  | * Transparent to user         |         |
|  | * Post-session rotation       |  | * Just-in-time delivery       |         |
|  | * Verification                |  |                               |         |
|  | * Reconciliation              |  |                               |         |
|  +-------------------------------+  +-------------------------------+         |
|                                                                               |
|  +-----------------------------------------------------------------------+    |
|  |                      TARGET CONNECTORS                                |    |
|  |                                                                       |    |
|  |  +-----------+ +-----------+ +-----------+ +-----------+ +----------+ |    |
|  |  |  Windows  | |   Linux   | |  Network  | | Database  | |   LDAP   | |    |
|  |  |           | |   Unix    | |  Devices  | |           | |          | |    |
|  |  | * Local   | | * Local   | | * Cisco   | | * Oracle  | | * AD     | |    |
|  |  | * Domain  | | * sudo    | | * Juniper | | * MSSQL   | | * OpenLDAP |    |
|  |  +-----------+ +-----------+ +-----------+ +-----------+ +----------+ |    |
|  +-----------------------------------------------------------------------+    |
|                                                                               |
+===============================================================================+
```

### Credential Types

| Type | Description | Use Cases |
|------|-------------|-----------|
| **Password** | Username/password combination | Standard authentication |
| **SSH Key** | RSA/ECDSA/Ed25519 key pairs | Linux/Unix, network devices |
| **Certificate** | X.509 certificates | Smart card, mutual TLS |
| **API Key** | Static tokens | Service accounts, APIs |
| **Connection String** | Full connection strings | Database applications |

### Password Rotation

#### Rotation Workflow

```
+===============================================================================+
|                      PASSWORD ROTATION WORKFLOW                               |
+===============================================================================+
|                                                                               |
|  1. TRIGGER                                                                   |
|  ----------                                                                   |
|  +----------------+   +----------------+   +----------------+                 |
|  |   Scheduled    |   |   On-Demand    |   |  Post-Session  |                 |
|  |    (cron)      |   |   (manual)     |   |  (automatic)   |                 |
|  +-------+--------+   +-------+--------+   +-------+--------+                 |
|          |                    |                    |                          |
|          +--------------------+--------------------+                          |
|                               |                                               |
|                               v                                               |
|  2. CONNECT TO TARGET                                                         |
|  --------------------                                                         |
|  * Use current credentials or reconciliation account                          |
|  * SSH/WinRM/API connection                                                   |
|                               |                                               |
|                               v                                               |
|  3. GENERATE NEW PASSWORD                                                     |
|  ------------------------                                                     |
|  * Apply password policy     * Character requirements                         |
|  * Length requirements       * Exclusion list                                 |
|                               |                                               |
|                               v                                               |
|  4. CHANGE PASSWORD ON TARGET                                                 |
|  ----------------------------                                                 |
|  * Execute change command/API   * Platform-specific method                    |
|                               |                                               |
|                               v                                               |
|  5. VERIFY NEW PASSWORD                                                       |
|  ----------------------                                                       |
|  * Attempt login with new credentials                                         |
|  * Confirm successful authentication                                          |
|                               |                                               |
|          +--------------------+--------------------+                          |
|          v                    v                    v                          |
|  +----------------+   +----------------+   +----------------+                 |
|  |    SUCCESS     |   |    FAILURE     |   |     RETRY      |                 |
|  |                |   |                |   |                |                 |
|  | Update vault   |   | Keep old pass  |   | Reconcile      |                 |
|  | Log success    |   | Alert admin    |   | Try again      |                 |
|  +----------------+   +----------------+   +----------------+                 |
|                                                                               |
+===============================================================================+
```

#### Rotation Policies

| Policy | Description | Example |
|--------|-------------|---------|
| **Scheduled** | Regular interval rotation | Every 30 days |
| **On-demand** | Manual trigger | Administrator request |
| **Post-session** | After each session | High-security accounts |
| **On-checkout** | Before credential use | Ephemeral access |
| **Event-based** | Triggered by events | After incident |

#### Password Policy Configuration

```yaml
# Example Password Policy Configuration
password_policy:
  name: "High Security Policy"

  length:
    minimum: 16
    maximum: 64

  character_requirements:
    uppercase: 2          # Minimum uppercase letters
    lowercase: 2          # Minimum lowercase letters
    numbers: 2            # Minimum digits
    special: 2            # Minimum special characters

  special_characters: "!@#$%^&*()_+-=[]{}|;:,.<>?"

  exclusions:
    - "password"
    - "admin"
    - "123456"
    - "${username}"       # Exclude username in password

  history:
    count: 12             # Cannot reuse last 12 passwords

  expiration:
    days: 30
    warning_days: 7
```

### Supported Target Systems

#### Windows Systems

| Target Type | Change Method | Requirements |
|-------------|---------------|--------------|
| Local accounts | WinRM/PowerShell | WinRM enabled |
| Domain accounts | LDAP/Kerberos | Domain connectivity |
| Service accounts | WMI/PowerShell | Admin privileges |
| Scheduled tasks | PowerShell | Admin privileges |

#### Linux/Unix Systems

| Target Type | Change Method | Requirements |
|-------------|---------------|--------------|
| Local accounts | SSH + passwd/chpasswd | Root or sudo |
| sudo configuration | SSH + visudo | Root access |
| Application accounts | Custom scripts | Varies |

#### Network Devices

| Vendor | Protocol | Notes |
|--------|----------|-------|
| Cisco IOS | SSH | enable + configure terminal |
| Cisco NX-OS | SSH | Similar to IOS |
| Juniper | SSH | Junos CLI |
| Palo Alto | SSH/API | PAN-OS |
| F5 BIG-IP | SSH/API | tmsh commands |

#### Databases

| Database | Method | Account Types |
|----------|--------|---------------|
| Oracle | SQL*Plus | Database users |
| MS SQL | T-SQL | SQL logins |
| MySQL/MariaDB | MySQL client | MySQL users |
| MariaDB | mysql | MariaDB users |

---

## Access Manager

### Overview

**Access Manager** provides the web-based portal for user access to privileged sessions.

**CyberArk Equivalent**: PVWA (Password Vault Web Access) + PSM for Web

### Architecture

```
+===============================================================================+
|                            ACCESS MANAGER                                     |
+===============================================================================+
|                                                                               |
|  +------------------------------------------------------------------------+   |
|  |                        WEB INTERFACE                                   |   |
|  |                                                                        |   |
|  |  +------------------------------------------------------------------+  |   |
|  |  |                      USER PORTAL                                 |  |   |
|  |  |                                                                  |  |   |
|  |  |  +-------------+   +-------------+   +-------------+             |  |   |
|  |  |  |   Target    |   |   Session   |   |    Self-    |             |  |   |
|  |  |  |   Browser   |   |   Launcher  |   |   Service   |             |  |   |
|  |  |  |             |   |             |   |             |             |  |   |
|  |  |  | * Search    |   | * HTML5     |   | * Password  |             |  |   |
|  |  |  | * Filter    |   | * RDP       |   |   change    |             |  |   |
|  |  |  | * Favorites |   | * SSH       |   | * Profile   |             |  |   |
|  |  |  | * Recent    |   | * VNC       |   | * Prefs     |             |  |   |
|  |  |  +-------------+   +-------------+   +-------------+             |  |   |
|  |  +------------------------------------------------------------------+  |   |
|  |                                                                        |   |
|  |  +------------------------------------------------------------------+  |   |
|  |  |                     ADMIN INTERFACE                              |  |   |
|  |  |                                                                  |  |   |
|  |  |  * Configuration management    * User/group administration      |  |   |
|  |  |  * Target management           * Policy configuration           |  |   |
|  |  |  * Reporting and audit                                          |  |   |
|  |  +------------------------------------------------------------------+  |   |
|  +------------------------------------------------------------------------+   |
|                                                                               |
|  +------------------------------------------------------------------------+   |
|  |                     HTML5 SESSION CLIENT                               |   |
|  |                                                                        |   |
|  |  Technology: Apache Guacamole-based                                    |   |
|  |                                                                        |   |
|  |  Supported Protocols:                      Features:                   |   |
|  |  +-- RDP (full Windows desktop)            +-- Clipboard support       |   |
|  |  +-- SSH (terminal emulator)               +-- File transfer           |   |
|  |  +-- VNC (remote desktop)                  +-- Audio redirection       |   |
|  |  +-- Telnet (terminal)                     +-- Multi-monitor support   |   |
|  +------------------------------------------------------------------------+   |
|                                                                               |
+===============================================================================+
```

### User Interface Components

#### Target Browser

```
+===============================================================================+
|                        TARGET BROWSER INTERFACE                               |
+===============================================================================+
|  [Search: ____________]  [Filter v]  [View: Grid | List]                      |
+===============================================================================+
|                                                                               |
|  FAVORITES                                                                    |
|  ---------                                                                    |
|  +---------------+   +---------------+   +---------------+                    |
|  | srv-prod      |   | db-oracle     |   | fw-main       |                    |
|  |   SSH         |   |   SQL*Plus    |   |   SSH         |                    |
|  |   [Connect]   |   |   [Connect]   |   |   [Connect]   |                    |
|  +---------------+   +---------------+   +---------------+                    |
|                                                                               |
|  RECENT                                                                       |
|  ------                                                                       |
|  * srv-web-01 / root (SSH) - 2 hours ago                                      |
|  * dc01.corp / Administrator (RDP) - 5 hours ago                              |
|  * switch-core / admin (SSH) - Yesterday                                      |
|                                                                               |
|  ALL TARGETS                                                                  |
|  -----------                                                                  |
|  Production Servers                                                           |
|     +-- srv-prod-01 (SSH, RDP)                                                |
|     +-- srv-prod-02 (SSH, RDP)                                                |
|     +-- srv-prod-03 (SSH)                                                     |
|  Network Devices                                                              |
|     +-- fw-main (SSH)                                                         |
|     +-- switch-core (SSH)                                                     |
|  Databases                                                                    |
|     +-- db-oracle (SQL*Plus)                                                  |
|     +-- db-mysql (MySQL)                                                      |
|                                                                               |
+===============================================================================+
```

#### HTML5 Session Features

| Feature | RDP | SSH | VNC |
|---------|-----|-----|-----|
| Full screen | Yes | Yes | Yes |
| Clipboard | Yes | Yes | Yes |
| File transfer | Yes | Yes (SFTP) | No |
| Audio | Yes | No | No |
| Multi-monitor | Yes | No | No |
| Printing | Yes | No | No |
| Keyboard shortcuts | Yes | Yes | Yes |

### Mobile Access

Access Manager provides responsive design for mobile devices:

- iOS Safari support
- Android Chrome support
- Touch-optimized interface
- Reduced feature set for mobile

---

## Component Interaction

### Internal Communication

```
+===============================================================================+
|                         COMPONENT INTERACTION                                 |
+===============================================================================+
|                                                                               |
|                          +-------------------+                                |
|                          |   Access Manager  |                                |
|                          |     (Web UI)      |                                |
|                          +---------+---------+                                |
|                                    |                                          |
|                                    | REST API (HTTPS)                         |
|                                    v                                          |
|  +------------------------------------------------------------------------+   |
|  |                        WALLIX BASTION CORE                             |   |
|  |                                                                        |   |
|  |  +------------------------+       +------------------------+           |   |
|  |  |    Session Manager     |<----->|   Password Manager     |           |   |
|  |  |                        | Cred  |                        |           |   |
|  |  |  * Auth requests       | Fetch |  * Credential retrieval|           |   |
|  |  |  * Session broker      |       |  * Injection           |           |   |
|  |  |  * Monitoring          |       |                        |           |   |
|  |  +-----------+------------+       +-----------+------------+           |   |
|  |              |                                |                        |   |
|  |              +----------------+---------------+                        |   |
|  |                               |                                        |   |
|  |                               v                                        |   |
|  |  +--------------------------------------------------------------------+|   |
|  |  |                      MariaDB Database                              ||   |
|  |  |                                                                    ||   |
|  |  |  * Configuration data      * Session metadata                      ||   |
|  |  |  * User/group definitions  * Audit logs                            ||   |
|  |  |  * Encrypted credentials   * Authorization policies                ||   |
|  |  +--------------------------------------------------------------------+|   |
|  +------------------------------------------------------------------------+   |
|                                                                               |
+===============================================================================+
```

### Session Establishment Flow

```
COMPLETE SESSION FLOW
=====================

User                Access Manager         Session Manager        Password Manager       Target
 |                        |                      |                       |                 |
 |  1. Login              |                      |                       |                 |
 |----------------------->|                      |                       |                 |
 |                        |  2. Authenticate     |                       |                 |
 |                        |--------------------->|                       |                 |
 |                        |  3. Auth OK          |                       |                 |
 |                        |<---------------------|                       |                 |
 |  4. Show targets       |                      |                       |                 |
 |<-----------------------|                      |                       |                 |
 |                        |                      |                       |                 |
 |  5. Select target      |                      |                       |                 |
 |----------------------->|                      |                       |                 |
 |                        |  6. Request session  |                       |                 |
 |                        |--------------------->|                       |                 |
 |                        |                      |  7. Get credentials   |                 |
 |                        |                      |---------------------->|                 |
 |                        |                      |  8. Encrypted creds   |                 |
 |                        |                      |<----------------------|                 |
 |                        |                      |                       |                 |
 |                        |                      |  9. Connect           |                 |
 |                        |                      |--------------------------------------->|
 |                        |                      |  10. Session ready    |                 |
 |                        |                      |<---------------------------------------|
 |                        |  11. Session URL     |                       |                 |
 |                        |<---------------------|                       |                 |
 |  12. Session stream    |                      |                       |                 |
 |<-----------------------|<=====================|=======================================|
 |                        |     (WebSocket)      |      (Proxied)        |                 |
 |                        |                      |                       |                 |
```

---

## Next Steps

Continue to [04 - Configuration](../04-configuration/README.md) to learn about the WALLIX object model and configuration.
