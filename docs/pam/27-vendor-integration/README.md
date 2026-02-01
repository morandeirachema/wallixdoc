# 36 - Vendor-Specific Integration Guides

## Table of Contents

1. [Overview](#overview)
2. [Network Devices](#network-devices)
   - [Cisco IOS/IOS-XE](#cisco-iosios-xe)
   - [Cisco NX-OS](#cisco-nx-os)
   - [Juniper Junos](#juniper-junos)
   - [Palo Alto Networks](#palo-alto-networks)
   - [Fortinet FortiGate](#fortinet-fortigate)
   - [F5 BIG-IP](#f5-big-ip)
3. [Industrial/OT Vendors](#industrialot-vendors)
   - [Siemens](#siemens)
   - [ABB](#abb)
   - [Rockwell Automation](#rockwell-automation)
   - [Schneider Electric](#schneider-electric)
4. [Integration Best Practices](#integration-best-practices)

---

## Overview

### Purpose

This guide provides vendor-specific configuration instructions for integrating WALLIX Bastion with common network equipment and industrial control systems.

```
+==============================================================================+
|                    VENDOR INTEGRATION ARCHITECTURE                            |
+==============================================================================+
|                                                                               |
|                          +-------------------+                                |
|                          |      USERS        |                                |
|                          |  Network/OT Eng.  |                                |
|                          +---------+---------+                                |
|                                    |                                          |
|                                    | SSH/HTTPS                                |
|                                    v                                          |
|                    +-------------------------------+                          |
|                    |       WALLIX BASTION          |                          |
|                    |                               |                          |
|                    |  +-------------------------+  |                          |
|                    |  |  Session Manager        |  |                          |
|                    |  |  Password Manager       |  |                          |
|                    |  |  Recording Engine       |  |                          |
|                    |  +-------------------------+  |                          |
|                    +---------------+---------------+                          |
|                                    |                                          |
|          +-------------------------+-------------------------+                |
|          |              |                |                    |               |
|          v              v                v                    v               |
|   +------------+  +------------+  +-------------+  +----------------+        |
|   | NETWORK    |  | FIREWALL   |  | INDUSTRIAL  |  | ENGINEERING    |        |
|   | DEVICES    |  | SYSTEMS    |  | CONTROLLERS |  | STATIONS       |        |
|   |            |  |            |  |             |  |                |        |
|   | Cisco      |  | Palo Alto  |  | Siemens PLC |  | TIA Portal     |        |
|   | Juniper    |  | FortiGate  |  | ABB 800xA   |  | FactoryTalk    |        |
|   | F5 BIG-IP  |  |            |  | Rockwell    |  | EcoStruxure    |        |
|   +------------+  +------------+  +-------------+  +----------------+        |
|                                                                               |
+==============================================================================+
```

### Supported Protocols by Vendor Category

| Category | Vendors | Primary Protocols | WALLIX Access Method |
|----------|---------|-------------------|---------------------|
| Network Routers/Switches | Cisco, Juniper | SSH, NETCONF | Direct SSH proxy |
| Firewalls | Palo Alto, FortiGate | SSH, HTTPS API | SSH proxy, HTTPS proxy |
| Load Balancers | F5 BIG-IP | SSH (TMSH), iControl REST | SSH proxy, HTTPS proxy |
| Industrial PLCs | Siemens, Rockwell, Schneider | Proprietary | RDP to engineering station |
| DCS Systems | ABB, Honeywell | Proprietary | RDP to workstation |

---

## Network Devices

### Cisco IOS/IOS-XE

#### Overview

Cisco IOS and IOS-XE are the most common network operating systems for enterprise routers and switches.

```
+==============================================================================+
|                    CISCO IOS/IOS-XE INTEGRATION                               |
+==============================================================================+
|                                                                               |
|  CONNECTION ARCHITECTURE                                                      |
|  =======================                                                      |
|                                                                               |
|       +----------------+                                                      |
|       |   Engineer     |                                                      |
|       +-------+--------+                                                      |
|               |                                                               |
|               | SSH (Port 22)                                                 |
|               v                                                               |
|       +================+                                                      |
|       | WALLIX BASTION |                                                      |
|       |                |                                                      |
|       | * Authenticate |                                                      |
|       | * Authorize    |                                                      |
|       | * Record       |                                                      |
|       +-------+========+                                                      |
|               |                                                               |
|               | SSH (Port 22)                                                 |
|               v                                                               |
|       +----------------+                                                      |
|       |   CISCO IOS    |                                                      |
|       |   Router/SW    |                                                      |
|       |                |                                                      |
|       | * User EXEC    |                                                      |
|       | * Priv EXEC    |                                                      |
|       | * Config Mode  |                                                      |
|       +----------------+                                                      |
|                                                                               |
+==============================================================================+
```

#### Connection Setup

| Parameter | Value | Notes |
|-----------|-------|-------|
| Protocol | SSH | SSHv2 required for security |
| Default Port | 22 | Configurable on device |
| Authentication | Password or SSH Key | Local or TACACS+/RADIUS |
| Enable Mode | Secondary password | Required for configuration |

#### Device Configuration in WALLIX

```
+------------------------------------------------------------------------------+
|                    CISCO IOS DEVICE CONFIGURATION                             |
+------------------------------------------------------------------------------+

  STEP 1: CREATE DOMAIN FOR NETWORK DEVICES
  ==========================================

  Domain Name: Network-Infrastructure
  Description: Core network devices - routers, switches, firewalls

  wabadmin domain create Network-Infrastructure \
    --description "Core network infrastructure devices"

  ---------------------------------------------------------------------------

  STEP 2: CREATE DEVICE ENTRY
  ===========================

  wabadmin device create CORE-RTR-01 \
    --domain Network-Infrastructure \
    --host 10.1.1.1 \
    --alias "Core Router - Site A" \
    --description "Cisco ISR 4451 - Primary WAN router"

  ---------------------------------------------------------------------------

  STEP 3: CREATE SSH SERVICE
  ==========================

  wabadmin service create CORE-RTR-01/SSH \
    --protocol ssh \
    --port 22 \
    --subprotocols "SSH_SHELL_SESSION"

  ---------------------------------------------------------------------------

  STEP 4: CREATE ACCOUNTS
  =======================

  # Standard admin account
  wabadmin account create CORE-RTR-01/netadmin \
    --service SSH \
    --credentials-type password \
    --description "Network admin account - privilege 15"

  # Enable password (secondary credential)
  wabadmin account create CORE-RTR-01/enable \
    --service SSH \
    --credentials-type password \
    --description "Enable mode password"
    --is-secondary true

+------------------------------------------------------------------------------+
```

#### Password Rotation Configuration

```
+==============================================================================+
|                    CISCO IOS PASSWORD ROTATION                                |
+==============================================================================+
|                                                                               |
|  ROTATION SCRIPT LOGIC                                                        |
|  =====================                                                        |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |  # Connect and enter privileged mode                                   |   |
|  |  enable                                                                |   |
|  |  [enable_password]                                                     |   |
|  |                                                                        |   |
|  |  # Enter configuration mode                                            |   |
|  |  configure terminal                                                    |   |
|  |                                                                        |   |
|  |  # Change user password                                                |   |
|  |  username netadmin privilege 15 secret 0 [NEW_PASSWORD]                |   |
|  |                                                                        |   |
|  |  # Save configuration                                                  |   |
|  |  end                                                                   |   |
|  |  write memory                                                          |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
|  IMPORTANT CONSIDERATIONS                                                     |
|  ========================                                                     |
|                                                                               |
|  * Use 'secret' instead of 'password' for Type 9 hashing                     |
|  * Cisco devices may have password complexity requirements                    |
|  * Some older IOS versions limit password length to 25 characters            |
|  * Always save configuration after password change                           |
|                                                                               |
|  PASSWORD POLICY RECOMMENDATIONS                                              |
|  ================================                                             |
|                                                                               |
|  +-------------------------+-----------------------+                          |
|  | Setting                 | Recommended Value     |                          |
|  +-------------------------+-----------------------+                          |
|  | Minimum Length          | 16 characters         |                          |
|  | Special Characters      | Limited set*          |                          |
|  | Rotation Period         | 90 days               |                          |
|  +-------------------------+-----------------------+                          |
|                                                                               |
|  * Avoid: " ' ` | < > & ; these may cause parsing issues                     |
|                                                                               |
+==============================================================================+
```

#### Session Recording Specifics

| Feature | Support | Notes |
|---------|---------|-------|
| Command logging | Full | All CLI commands captured |
| Enable mode tracking | Yes | Recorded when entering enable |
| Config mode tracking | Yes | Configuration changes logged |
| Show command output | Yes | Outputs captured in recording |

#### Common Issues and Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| Connection timeout | SSH not enabled | `ip ssh version 2` on device |
| Authentication failed | Wrong credentials | Verify username/password in WALLIX |
| Enable mode fails | Wrong enable password | Configure enable credential in WALLIX |
| Password rotation fails | Complexity mismatch | Adjust WALLIX password policy |
| Session disconnect | VTY timeout | Increase `exec-timeout` on device |

#### Cisco IOS Configuration Backup

```
+------------------------------------------------------------------------------+
|                    CONFIGURATION BACKUP VIA WALLIX                            |
+------------------------------------------------------------------------------+

  AUTOMATED BACKUP SCRIPT
  =======================

  #!/bin/bash
  # Backup Cisco config through WALLIX

  DEVICE="CORE-RTR-01"
  BACKUP_DIR="/var/backups/network"
  DATE=$(date +%Y%m%d)

  # Connect via WALLIX and capture config
  ssh wallix-bastion -l "netadmin@${DEVICE}" << 'EOF'
    terminal length 0
    show running-config
    exit
  EOF > "${BACKUP_DIR}/${DEVICE}_${DATE}.cfg"

  ---------------------------------------------------------------------------

  WALLIX AUTHORIZATION FOR BACKUP
  ===============================

  {
    "authorization": "network-backup-automation",
    "user_group": "Automation-Service-Accounts",
    "target_group": "Network-Devices-All",
    "subprotocols": ["SSH_SHELL_SESSION"],
    "is_recorded": true,
    "approval_required": false,
    "description": "Automated configuration backup"
  }

+------------------------------------------------------------------------------+
```

---

### Cisco NX-OS

#### Overview

Cisco NX-OS runs on Nexus data center switches with specific differences from IOS.

```
+==============================================================================+
|                    CISCO NX-OS SPECIFICS                                      |
+==============================================================================+
|                                                                               |
|  KEY DIFFERENCES FROM IOS                                                     |
|  ========================                                                     |
|                                                                               |
|  +-------------------------+----------------------+------------------------+  |
|  | Feature                 | IOS                  | NX-OS                  |  |
|  +-------------------------+----------------------+------------------------+  |
|  | User database           | Local/TACACS+        | Local/TACACS+/LDAP     |  |
|  | Config save             | write memory         | copy run start         |  |
|  | Role-based access       | Privilege levels     | RBAC roles             |  |
|  | API access              | Limited              | NX-API (REST/JSON-RPC) |  |
|  | Feature licensing       | Basic                | Per-feature            |  |
|  +-------------------------+----------------------+------------------------+  |
|                                                                               |
+==============================================================================+
```

#### Device Configuration

```
+------------------------------------------------------------------------------+
|                    NX-OS DEVICE CONFIGURATION                                 |
+------------------------------------------------------------------------------+

  DEVICE ENTRY
  ============

  wabadmin device create NEXUS-CORE-01 \
    --domain Network-Infrastructure \
    --host 10.1.1.10 \
    --alias "Nexus 9500 - Core Spine" \
    --description "Cisco Nexus 9508 - Data Center Core"

  ---------------------------------------------------------------------------

  SSH SERVICE
  ===========

  wabadmin service create NEXUS-CORE-01/SSH \
    --protocol ssh \
    --port 22 \
    --subprotocols "SSH_SHELL_SESSION"

  ---------------------------------------------------------------------------

  NX-API SERVICE (Optional - for API access)
  ==========================================

  wabadmin service create NEXUS-CORE-01/HTTPS \
    --protocol https \
    --port 443 \
    --description "NX-API REST interface"

  ---------------------------------------------------------------------------

  ACCOUNT CONFIGURATION
  =====================

  # Admin account with network-admin role
  wabadmin account create NEXUS-CORE-01/nxadmin \
    --service SSH \
    --credentials-type password \
    --description "Network admin - network-admin role"

+------------------------------------------------------------------------------+
```

#### Password Rotation for NX-OS

```
+------------------------------------------------------------------------------+
|                    NX-OS PASSWORD CHANGE COMMANDS                             |
+------------------------------------------------------------------------------+

  SSH METHOD
  ==========

  +-----------------------------------------------------------------------+
  |  configure terminal                                                    |
  |  username nxadmin password 0 [NEW_PASSWORD] role network-admin        |
  |  copy running-config startup-config                                    |
  +-----------------------------------------------------------------------+

  ---------------------------------------------------------------------------

  NX-API METHOD (REST)
  ====================

  POST https://nexus-device/ins

  Headers:
    Content-Type: application/json
    Authorization: Basic [base64-encoded-credentials]

  Body:
  {
    "ins_api": {
      "version": "1.0",
      "type": "cli_conf",
      "chunk": "0",
      "sid": "1",
      "input": "username nxadmin password [NEW_PASSWORD] role network-admin",
      "output_format": "json"
    }
  }

+------------------------------------------------------------------------------+
```

---

### Juniper Junos

#### Overview

Juniper Junos OS provides both CLI and NETCONF access for configuration management.

```
+==============================================================================+
|                    JUNIPER JUNOS INTEGRATION                                  |
+==============================================================================+
|                                                                               |
|  ACCESS METHODS                                                               |
|  ==============                                                               |
|                                                                               |
|       +--------------------+                                                  |
|       |    WALLIX BASTION  |                                                  |
|       +----+----------+----+                                                  |
|            |          |                                                       |
|    +-------+          +-------+                                               |
|    |                          |                                               |
|    v                          v                                               |
|  +-------------+        +-------------+                                       |
|  |    SSH      |        |   NETCONF   |                                       |
|  |  Port 22    |        |  Port 830   |                                       |
|  |             |        |             |                                       |
|  | CLI Access  |        | XML/RPC     |                                       |
|  | Operational |        | Automation  |                                       |
|  | Config Mode |        | Junos PyEZ  |                                       |
|  +-------------+        +-------------+                                       |
|                                                                               |
|  WALLIX SUPPORT                                                               |
|  ==============                                                               |
|                                                                               |
|  +----------------+------------------+------------------------------+         |
|  | Protocol       | WALLIX Support   | Notes                        |         |
|  +----------------+------------------+------------------------------+         |
|  | SSH            | Full             | Direct proxy, full recording |         |
|  | NETCONF        | Via SSH tunnel   | Encapsulated in SSH          |         |
|  +----------------+------------------+------------------------------+         |
|                                                                               |
+==============================================================================+
```

#### Device Configuration

```
+------------------------------------------------------------------------------+
|                    JUNOS DEVICE CONFIGURATION                                 |
+------------------------------------------------------------------------------+

  DEVICE ENTRY
  ============

  wabadmin device create JUNOS-MX-01 \
    --domain Network-Infrastructure \
    --host 10.1.1.20 \
    --alias "MX480 - WAN Edge" \
    --description "Juniper MX480 - Primary WAN Router"

  ---------------------------------------------------------------------------

  SSH SERVICE
  ===========

  wabadmin service create JUNOS-MX-01/SSH \
    --protocol ssh \
    --port 22 \
    --subprotocols "SSH_SHELL_SESSION"

  ---------------------------------------------------------------------------

  NETCONF SERVICE (Port 830)
  ==========================

  wabadmin service create JUNOS-MX-01/NETCONF \
    --protocol ssh \
    --port 830 \
    --description "NETCONF over SSH"

  ---------------------------------------------------------------------------

  ACCOUNT CONFIGURATION
  =====================

  wabadmin account create JUNOS-MX-01/netops \
    --service SSH \
    --credentials-type password \
    --description "Network operations - super-user class"

+------------------------------------------------------------------------------+
```

#### Password Rotation

```
+==============================================================================+
|                    JUNOS PASSWORD ROTATION                                    |
+==============================================================================+
|                                                                               |
|  CLI METHOD                                                                   |
|  ==========                                                                   |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |  # Enter configuration mode                                            |   |
|  |  configure                                                             |   |
|  |                                                                        |   |
|  |  # Change password (prompts for new password)                          |   |
|  |  set system login user netops authentication plain-text-password       |   |
|  |  New password: [NEW_PASSWORD]                                          |   |
|  |  Retype new password: [NEW_PASSWORD]                                   |   |
|  |                                                                        |   |
|  |  # Commit changes                                                      |   |
|  |  commit and-quit                                                       |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
|  ALTERNATIVE: ENCRYPTED PASSWORD                                              |
|  ================================                                             |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |  # Pre-encrypt password and set directly                               |   |
|  |  configure                                                             |   |
|  |  set system login user netops authentication encrypted-password \      |   |
|  |      "$6$hash..."                                                      |   |
|  |  commit and-quit                                                       |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
|  NETCONF METHOD (XML-RPC)                                                     |
|  ========================                                                     |
|                                                                               |
|  <rpc>                                                                        |
|    <load-configuration>                                                       |
|      <configuration>                                                          |
|        <system>                                                               |
|          <login>                                                              |
|            <user>                                                             |
|              <name>netops</name>                                              |
|              <authentication>                                                 |
|                <encrypted-password>$6$hash...</encrypted-password>            |
|              </authentication>                                                |
|            </user>                                                            |
|          </login>                                                             |
|        </system>                                                              |
|      </configuration>                                                         |
|    </load-configuration>                                                      |
|  </rpc>                                                                       |
|  <rpc><commit/></rpc>                                                         |
|                                                                               |
+==============================================================================+
```

#### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Commit fails | Configuration conflict | Use `commit check` before commit |
| Password rejected | Complexity requirements | Check `set system login password` settings |
| Session timeout | Idle timeout | Adjust `set system login idle-timeout` |
| NETCONF connection fails | Service disabled | Enable with `set system services netconf ssh` |

---

### Palo Alto Networks

#### Overview

Palo Alto firewalls support SSH CLI and XML/REST API access.

```
+==============================================================================+
|                    PALO ALTO NETWORKS INTEGRATION                             |
+==============================================================================+
|                                                                               |
|  ACCESS ARCHITECTURE                                                          |
|  ===================                                                          |
|                                                                               |
|       +--------------------+                                                  |
|       |    WALLIX BASTION  |                                                  |
|       +----+----------+----+                                                  |
|            |          |                                                       |
|    +-------+          +-------+                                               |
|    |                          |                                               |
|    v                          v                                               |
|  +-------------+        +-------------+                                       |
|  |    SSH      |        |   HTTPS     |                                       |
|  |  Port 22    |        |  Port 443   |                                       |
|  |             |        |             |                                       |
|  | CLI Access  |        | XML API     |                                       |
|  | Operational |        | REST API    |                                       |
|  | Configure   |        | Automation  |                                       |
|  +-------------+        +-------------+                                       |
|                                                                               |
|  PAN-OS ACCESS LEVELS                                                         |
|  ====================                                                         |
|                                                                               |
|  +------------------+---------------------------------------+                 |
|  | Role             | Permissions                           |                 |
|  +------------------+---------------------------------------+                 |
|  | superuser        | Full administrative access            |                 |
|  | superreader      | Read-only access to all               |                 |
|  | deviceadmin      | Device configuration, no policies     |                 |
|  | devicereader     | Device read-only                      |                 |
|  | vsysadmin        | Virtual system administration         |                 |
|  | vsysreader       | Virtual system read-only              |                 |
|  +------------------+---------------------------------------+                 |
|                                                                               |
+==============================================================================+
```

#### Device Configuration

```
+------------------------------------------------------------------------------+
|                    PALO ALTO DEVICE CONFIGURATION                             |
+------------------------------------------------------------------------------+

  DEVICE ENTRY
  ============

  wabadmin device create PA-FW-01 \
    --domain Network-Infrastructure \
    --host 10.1.1.30 \
    --alias "Palo Alto PA-5260" \
    --description "Perimeter Firewall - Data Center"

  ---------------------------------------------------------------------------

  SSH SERVICE
  ===========

  wabadmin service create PA-FW-01/SSH \
    --protocol ssh \
    --port 22 \
    --subprotocols "SSH_SHELL_SESSION"

  ---------------------------------------------------------------------------

  HTTPS SERVICE (API Access)
  ==========================

  wabadmin service create PA-FW-01/HTTPS \
    --protocol https \
    --port 443 \
    --description "PAN-OS API access"

  ---------------------------------------------------------------------------

  ACCOUNT CONFIGURATION
  =====================

  # CLI admin account
  wabadmin account create PA-FW-01/fwadmin \
    --service SSH \
    --credentials-type password \
    --description "Firewall admin - superuser role"

  # API key (stored as password)
  wabadmin account create PA-FW-01/api-key \
    --service HTTPS \
    --credentials-type password \
    --description "API key for automation"

+------------------------------------------------------------------------------+
```

#### Password Rotation

```
+==============================================================================+
|                    PALO ALTO PASSWORD ROTATION                                |
+==============================================================================+
|                                                                               |
|  CLI METHOD                                                                   |
|  ==========                                                                   |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |  # Enter configuration mode                                            |   |
|  |  configure                                                             |   |
|  |                                                                        |   |
|  |  # Change admin password                                               |   |
|  |  set mgt-config users fwadmin password                                 |   |
|  |  Enter password: [NEW_PASSWORD]                                        |   |
|  |  Confirm password: [NEW_PASSWORD]                                      |   |
|  |                                                                        |   |
|  |  # Commit changes                                                      |   |
|  |  commit                                                                |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  XML API METHOD                                                               |
|  ==============                                                               |
|                                                                               |
|  # Generate API key first                                                     |
|  GET https://firewall/api/?type=keygen&user=admin&password=oldpass           |
|                                                                               |
|  # Change password via API                                                    |
|  POST https://firewall/api/                                                   |
|  ?type=config                                                                 |
|  &action=set                                                                  |
|  &xpath=/config/mgt-config/users/entry[@name='fwadmin']                      |
|  &element=<phash>[PASSWORD_HASH]</phash>                                     |
|  &key=[API_KEY]                                                              |
|                                                                               |
|  # Commit                                                                     |
|  POST https://firewall/api/?type=commit&cmd=<commit></commit>&key=[API_KEY]  |
|                                                                               |
+==============================================================================+
```

#### API Key Management

| Consideration | Details |
|---------------|---------|
| Key Generation | Generated per-user, contains role permissions |
| Key Storage | Store in WALLIX vault as password credential |
| Key Rotation | Regenerate periodically, update in WALLIX |
| Key Revocation | Delete user or regenerate key to revoke |

#### Session Recording

| Feature | Support | Notes |
|---------|---------|-------|
| CLI Commands | Full | All commands recorded |
| Configuration mode | Yes | Config changes tracked |
| Show commands | Yes | Output captured |
| Commit operations | Yes | Commit logs captured |

---

### Fortinet FortiGate

#### Overview

FortiGate firewalls provide SSH CLI and REST API access.

```
+==============================================================================+
|                    FORTINET FORTIGATE INTEGRATION                             |
+==============================================================================+
|                                                                               |
|  ACCESS METHODS                                                               |
|  ==============                                                               |
|                                                                               |
|  +------------------+------------+--------------------------------+           |
|  | Method           | Port       | Use Case                       |           |
|  +------------------+------------+--------------------------------+           |
|  | SSH              | 22         | CLI administration             |           |
|  | HTTPS (GUI)      | 443        | Web-based management           |           |
|  | REST API         | 443        | Automation, integration        |           |
|  +------------------+------------+--------------------------------+           |
|                                                                               |
|  FORTIGATE ADMIN PROFILES                                                     |
|  ========================                                                     |
|                                                                               |
|  +------------------+---------------------------------------+                 |
|  | Profile          | Access Level                          |                 |
|  +------------------+---------------------------------------+                 |
|  | super_admin      | Full read-write access                |                 |
|  | prof_admin       | Custom profile permissions            |                 |
|  | read_only        | View configuration only               |                 |
|  +------------------+---------------------------------------+                 |
|                                                                               |
+==============================================================================+
```

#### Device Configuration

```
+------------------------------------------------------------------------------+
|                    FORTIGATE DEVICE CONFIGURATION                             |
+------------------------------------------------------------------------------+

  DEVICE ENTRY
  ============

  wabadmin device create FGT-FW-01 \
    --domain Network-Infrastructure \
    --host 10.1.1.40 \
    --alias "FortiGate 600E" \
    --description "Branch Office Firewall"

  ---------------------------------------------------------------------------

  SSH SERVICE
  ===========

  wabadmin service create FGT-FW-01/SSH \
    --protocol ssh \
    --port 22 \
    --subprotocols "SSH_SHELL_SESSION"

  ---------------------------------------------------------------------------

  HTTPS SERVICE
  =============

  wabadmin service create FGT-FW-01/HTTPS \
    --protocol https \
    --port 443 \
    --description "FortiGate REST API"

  ---------------------------------------------------------------------------

  ACCOUNT CONFIGURATION
  =====================

  wabadmin account create FGT-FW-01/fgtadmin \
    --service SSH \
    --credentials-type password \
    --description "FortiGate admin - super_admin profile"

+------------------------------------------------------------------------------+
```

#### Password Rotation

```
+==============================================================================+
|                    FORTIGATE PASSWORD ROTATION                                |
+==============================================================================+
|                                                                               |
|  CLI METHOD                                                                   |
|  ==========                                                                   |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |  config system admin                                                   |   |
|  |      edit fgtadmin                                                     |   |
|  |          set password [NEW_PASSWORD]                                   |   |
|  |      next                                                              |   |
|  |  end                                                                   |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  REST API METHOD                                                              |
|  ===============                                                              |
|                                                                               |
|  # Authenticate and get session token                                         |
|  POST https://fortigate/logincheck                                            |
|  Content-Type: application/x-www-form-urlencoded                              |
|  username=admin&secretkey=password                                            |
|                                                                               |
|  # Update admin password                                                      |
|  PUT https://fortigate/api/v2/cmdb/system/admin/fgtadmin                      |
|  Content-Type: application/json                                               |
|  {                                                                            |
|    "password": "[NEW_PASSWORD]"                                               |
|  }                                                                            |
|                                                                               |
|  # Logout                                                                     |
|  POST https://fortigate/logout                                                |
|                                                                               |
|  PASSWORD POLICY                                                              |
|  ===============                                                              |
|                                                                               |
|  FortiOS password requirements (configurable):                                |
|  * Minimum 8 characters (default)                                             |
|  * Can enforce complexity via admin password policy                           |
|  * Some special characters may need escaping in CLI                           |
|                                                                               |
+==============================================================================+
```

---

### F5 BIG-IP

#### Overview

F5 BIG-IP load balancers use TMSH (Traffic Management Shell) and iControl REST API.

```
+==============================================================================+
|                    F5 BIG-IP INTEGRATION                                      |
+==============================================================================+
|                                                                               |
|  ACCESS METHODS                                                               |
|  ==============                                                               |
|                                                                               |
|  +------------------+------------+--------------------------------+           |
|  | Method           | Port       | Use Case                       |           |
|  +------------------+------------+--------------------------------+           |
|  | SSH (TMSH)       | 22         | CLI administration             |           |
|  | SSH (bash)       | 22         | Advanced shell access          |           |
|  | HTTPS (GUI)      | 443        | Web-based management           |           |
|  | iControl REST    | 443        | REST API automation            |           |
|  +------------------+------------+--------------------------------+           |
|                                                                               |
|  BIG-IP USER ROLES                                                            |
|  =================                                                            |
|                                                                               |
|  +---------------------+--------------------------------------+               |
|  | Role                | Description                          |               |
|  +---------------------+--------------------------------------+               |
|  | Administrator       | Full access to all partitions        |               |
|  | Resource Admin      | Create/modify resources              |               |
|  | Operator            | Enable/disable resources             |               |
|  | Guest               | Read-only access                      |               |
|  | Application Editor  | Modify AS3 applications              |               |
|  +---------------------+--------------------------------------+               |
|                                                                               |
+==============================================================================+
```

#### Device Configuration

```
+------------------------------------------------------------------------------+
|                    F5 BIG-IP DEVICE CONFIGURATION                             |
+------------------------------------------------------------------------------+

  DEVICE ENTRY
  ============

  wabadmin device create F5-LTM-01 \
    --domain Network-Infrastructure \
    --host 10.1.1.50 \
    --alias "F5 BIG-IP LTM" \
    --description "Load Balancer - Production Applications"

  ---------------------------------------------------------------------------

  SSH SERVICE (TMSH)
  ==================

  wabadmin service create F5-LTM-01/SSH \
    --protocol ssh \
    --port 22 \
    --subprotocols "SSH_SHELL_SESSION"

  ---------------------------------------------------------------------------

  HTTPS SERVICE (iControl REST)
  =============================

  wabadmin service create F5-LTM-01/HTTPS \
    --protocol https \
    --port 443 \
    --description "iControl REST API"

  ---------------------------------------------------------------------------

  ACCOUNTS
  ========

  # TMSH admin account
  wabadmin account create F5-LTM-01/f5admin \
    --service SSH \
    --credentials-type password \
    --description "BIG-IP admin - Administrator role"

  # Root account (for advanced bash access)
  wabadmin account create F5-LTM-01/root \
    --service SSH \
    --credentials-type password \
    --description "Root shell access"

+------------------------------------------------------------------------------+
```

#### Password Rotation

```
+==============================================================================+
|                    F5 BIG-IP PASSWORD ROTATION                                |
+==============================================================================+
|                                                                               |
|  TMSH METHOD                                                                  |
|  ===========                                                                  |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |  # Login to TMSH                                                       |   |
|  |  tmsh                                                                  |   |
|  |                                                                        |   |
|  |  # Modify user password                                                |   |
|  |  modify auth user f5admin password [NEW_PASSWORD]                      |   |
|  |                                                                        |   |
|  |  # Save configuration                                                  |   |
|  |  save sys config                                                       |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  iCONTROL REST API METHOD                                                     |
|  ========================                                                     |
|                                                                               |
|  # Authenticate                                                               |
|  POST https://bigip/mgmt/shared/authn/login                                   |
|  {                                                                            |
|    "username": "admin",                                                       |
|    "password": "oldpassword",                                                 |
|    "loginProviderName": "tmos"                                                |
|  }                                                                            |
|                                                                               |
|  # Change password                                                            |
|  PATCH https://bigip/mgmt/tm/auth/user/f5admin                                |
|  {                                                                            |
|    "password": "[NEW_PASSWORD]"                                               |
|  }                                                                            |
|                                                                               |
|  ROOT PASSWORD CHANGE                                                         |
|  ====================                                                         |
|                                                                               |
|  +-----------------------------------------------------------------------+   |
|  |  # Via bash (SSH as root)                                              |   |
|  |  passwd                                                                |   |
|  |  # Or                                                                  |   |
|  |  tmsh modify auth password root                                        |   |
|  +-----------------------------------------------------------------------+   |
|                                                                               |
+==============================================================================+
```

#### Session Recording

| Feature | Support | Notes |
|---------|---------|-------|
| TMSH commands | Full | All TMSH commands recorded |
| Bash shell | Full | Full bash session recorded |
| iRule edits | Yes | Visible in session recording |
| Config sync | Yes | Sync operations logged |

---

## Industrial/OT Vendors

### Siemens

#### Overview

Siemens industrial systems use proprietary protocols accessed through engineering software.

```
+==============================================================================+
|                    SIEMENS INTEGRATION ARCHITECTURE                           |
+==============================================================================+
|                                                                               |
|  ACCESS PATTERN                                                               |
|  ==============                                                               |
|                                                                               |
|       +----------------+                                                      |
|       |   OT Engineer  |                                                      |
|       +-------+--------+                                                      |
|               |                                                               |
|               | RDP (Port 3389)                                               |
|               v                                                               |
|       +================+                                                      |
|       | WALLIX BASTION |                                                      |
|       |                |                                                      |
|       | * Authenticate |                                                      |
|       | * Record RDP   |                                                      |
|       | * Audit trail  |                                                      |
|       +-------+========+                                                      |
|               |                                                               |
|               | RDP                                                           |
|               v                                                               |
|       +-------------------+                                                   |
|       |  ENGINEERING      |                                                   |
|       |  WORKSTATION      |                                                   |
|       |                   |                                                   |
|       | +---------------+ |                                                   |
|       | | TIA Portal    | |                                                   |
|       | | STEP 7        | |                                                   |
|       | | WinCC         | |                                                   |
|       | +-------+-------+ |                                                   |
|       +---------+---------+                                                   |
|                 |                                                             |
|                 | S7comm (Port 102)                                           |
|                 | PROFINET                                                    |
|                 v                                                             |
|       +-------------------+                                                   |
|       |   SIEMENS PLC     |                                                   |
|       |   S7-1500/1200    |                                                   |
|       +-------------------+                                                   |
|                                                                               |
|  SIEMENS PROTOCOLS                                                            |
|  =================                                                            |
|                                                                               |
|  +------------------+------------+-----------------------------------+        |
|  | Protocol         | Port       | Description                       |        |
|  +------------------+------------+-----------------------------------+        |
|  | S7comm           | 102        | PLC programming/communication     |        |
|  | S7comm-Plus      | 102        | Secure variant (TLS)              |        |
|  | PROFINET         | UDP 34964  | Real-time I/O                     |        |
|  | OPC UA           | 4840       | Modern data access                |        |
|  +------------------+------------+-----------------------------------+        |
|                                                                               |
+==============================================================================+
```

#### Device Configuration

```
+------------------------------------------------------------------------------+
|                    SIEMENS ENVIRONMENT CONFIGURATION                          |
+------------------------------------------------------------------------------+

  ENGINEERING WORKSTATION (Jump Host)
  ====================================

  wabadmin device create SIEMENS-ENG-01 \
    --domain OT-Engineering \
    --host 10.100.10.20 \
    --alias "Siemens Engineering Station" \
    --description "TIA Portal V17 - PLC Programming"

  ---------------------------------------------------------------------------

  RDP SERVICE
  ===========

  wabadmin service create SIEMENS-ENG-01/RDP \
    --protocol rdp \
    --port 3389 \
    --subprotocols "RDP_DRIVE,RDP_PRINTER"

  NOTE: Enable drive mapping carefully for project file transfer

  ---------------------------------------------------------------------------

  ACCOUNTS
  ========

  # Local engineering account
  wabadmin account create SIEMENS-ENG-01/plc_engineer \
    --service RDP \
    --credentials-type password \
    --description "TIA Portal engineering access"

  # Domain account for integrated environments
  wabadmin account create SIEMENS-ENG-01/DOMAIN\\plc_engineer \
    --service RDP \
    --credentials-type password \
    --description "Domain engineering access"

  ---------------------------------------------------------------------------

  AUTHORIZATION
  =============

  wabadmin authorization create OT-Engineers-Siemens \
    --user-group OT-Engineers \
    --target SIEMENS-ENG-01/RDP/plc_engineer \
    --approval-required true \
    --approval-group OT-Supervisors \
    --session-recording true \
    --max-session-duration 8h

+------------------------------------------------------------------------------+
```

#### Password Rotation Considerations

```
+==============================================================================+
|                    SIEMENS PASSWORD MANAGEMENT                                |
+==============================================================================+
|                                                                               |
|  WALLIX MANAGED COMPONENTS                                                    |
|  =========================                                                    |
|                                                                               |
|  +------------------------+------------------+----------------------------+   |
|  | Component              | Rotation Support | Method                     |   |
|  +------------------------+------------------+----------------------------+   |
|  | Engineering WS (Win)   | Yes              | WinRM/RDP                  |   |
|  | TIA Portal Users       | Manual           | Via TIA Portal             |   |
|  | PLC CPU Password       | Manual           | Via TIA Portal project     |   |
|  | HMI Passwords          | Manual           | Via WinCC configuration    |   |
|  +------------------------+------------------+----------------------------+   |
|                                                                               |
|  IMPORTANT: PLC passwords are part of the project file.                       |
|  Changing requires project download to PLC.                                   |
|                                                                               |
|  WINDOWS WORKSTATION ROTATION                                                 |
|  ============================                                                 |
|                                                                               |
|  Standard Windows password rotation applies to engineering workstation:       |
|                                                                               |
|  1. WALLIX connects via WinRM                                                 |
|  2. Executes password change command                                          |
|  3. Verifies new password works                                               |
|                                                                               |
|  TIA PORTAL PROJECT SECURITY                                                  |
|  ===========================                                                  |
|                                                                               |
|  TIA Portal projects can have their own protection:                           |
|  * Project password (for opening project)                                     |
|  * Know-how protection (for function blocks)                                  |
|  * CPU access protection levels                                               |
|                                                                               |
|  These are NOT managed by WALLIX but visible in session recordings.           |
|                                                                               |
+==============================================================================+
```

#### Session Recording Specifics

| Recorded Element | Details |
|------------------|---------|
| TIA Portal operations | Full screen recording |
| PLC online connections | Connection visible in recording |
| Program downloads | Download operations captured |
| Diagnostic views | All diagnostic data visible |
| Project modifications | All project changes recorded |

#### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| RDP session slow | Large project files | Use RemoteFX if available |
| Project transfer fails | Drive mapping disabled | Enable RDP_DRIVE subprotocol |
| S7 connection fails | Network segmentation | Verify OT network access |
| License not found | License on different server | Configure TIA license server |

---

### ABB

#### Overview

ABB control systems, particularly System 800xA, require specialized access patterns.

```
+==============================================================================+
|                    ABB SYSTEM 800xA INTEGRATION                               |
+==============================================================================+
|                                                                               |
|  SYSTEM ARCHITECTURE                                                          |
|  ===================                                                          |
|                                                                               |
|                    +---------------------------+                              |
|                    |      WALLIX BASTION       |                              |
|                    +-------------+-------------+                              |
|                                  |                                            |
|                                  | RDP                                         |
|                                  v                                            |
|       +----------------------------------------------------------+           |
|       |                    ABB 800xA SYSTEM                       |           |
|       |                                                           |           |
|       |  +-------------+  +-------------+  +-------------+       |           |
|       |  | Engineering |  |  Operator   |  |   Aspect    |       |           |
|       |  |  Workplace  |  | Workplace   |  |   Server    |       |           |
|       |  +------+------+  +------+------+  +------+------+       |           |
|       |         |                |                |               |           |
|       |         +----------------+----------------+               |           |
|       |                          |                                |           |
|       |                          v                                |           |
|       |             +---------------------------+                 |           |
|       |             |    Connectivity Server    |                 |           |
|       |             +-------------+-------------+                 |           |
|       |                           |                               |           |
|       +----------------------------------------------------------+           |
|                                   |                                           |
|                                   v                                           |
|                        +-------------------+                                  |
|                        |   AC 800M / PM   |                                  |
|                        |   Controllers    |                                  |
|                        +-------------------+                                  |
|                                                                               |
+==============================================================================+
```

#### Device Configuration

```
+------------------------------------------------------------------------------+
|                    ABB 800xA CONFIGURATION                                    |
+------------------------------------------------------------------------------+

  ENGINEERING WORKPLACE
  =====================

  wabadmin device create ABB-ENG-WP-01 \
    --domain OT-Engineering \
    --host 10.100.20.10 \
    --alias "ABB Engineering Workplace" \
    --description "System 800xA Engineering Station"

  wabadmin service create ABB-ENG-WP-01/RDP \
    --protocol rdp \
    --port 3389

  wabadmin account create ABB-ENG-WP-01/abb_engineer \
    --service RDP \
    --credentials-type password \
    --description "800xA Engineering Access"

  ---------------------------------------------------------------------------

  OPERATOR WORKPLACE
  ==================

  wabadmin device create ABB-OP-WP-01 \
    --domain OT-Operations \
    --host 10.100.20.20 \
    --alias "ABB Operator Workplace" \
    --description "System 800xA Operator Station"

  wabadmin service create ABB-OP-WP-01/RDP \
    --protocol rdp \
    --port 3389

  wabadmin account create ABB-OP-WP-01/operator \
    --service RDP \
    --credentials-type password \
    --description "800xA Operator Access"

  ---------------------------------------------------------------------------

  AUTHORIZATION WITH APPROVAL
  ===========================

  wabadmin authorization create ABB-Engineering-Access \
    --user-group OT-Engineers \
    --target ABB-ENG-WP-01/RDP/abb_engineer \
    --approval-required true \
    --approval-group OT-Supervisors \
    --time-restriction "MON-FRI 06:00-22:00" \
    --session-recording true

+------------------------------------------------------------------------------+
```

#### Password Rotation

```
+==============================================================================+
|                    ABB 800xA PASSWORD MANAGEMENT                              |
+==============================================================================+
|                                                                               |
|  WALLIX MANAGED                                                               |
|  ==============                                                               |
|                                                                               |
|  +------------------------+------------------+----------------------------+   |
|  | Component              | Rotation Support | Notes                      |   |
|  +------------------------+------------------+----------------------------+   |
|  | Windows Workstations   | Yes              | Standard Windows rotation  |   |
|  | Domain Accounts        | Yes              | Via AD integration         |   |
|  +------------------------+------------------+----------------------------+   |
|                                                                               |
|  NOT MANAGED BY WALLIX (Internal to 800xA)                                    |
|  =========================================                                    |
|                                                                               |
|  * 800xA Application Users (managed in Administration Console)               |
|  * Controller passwords (configured during commissioning)                     |
|  * OPC server credentials                                                     |
|                                                                               |
|  INTEGRATION NOTES                                                            |
|  =================                                                            |
|                                                                               |
|  800xA typically uses Windows domain authentication.                          |
|  WALLIX can manage the domain accounts used to access workplaces.             |
|                                                                               |
+==============================================================================+
```

---

### Rockwell Automation

#### Overview

Rockwell Automation ControlLogix/CompactLogix systems use EtherNet/IP and RSLogix/Studio 5000.

```
+==============================================================================+
|                    ROCKWELL AUTOMATION INTEGRATION                            |
+==============================================================================+
|                                                                               |
|  ACCESS ARCHITECTURE                                                          |
|  ===================                                                          |
|                                                                               |
|       +----------------+                                                      |
|       |   OT Engineer  |                                                      |
|       +-------+--------+                                                      |
|               |                                                               |
|               | RDP                                                           |
|               v                                                               |
|       +================+                                                      |
|       | WALLIX BASTION |                                                      |
|       +-------+========+                                                      |
|               |                                                               |
|               | RDP                                                           |
|               v                                                               |
|       +-------------------+                                                   |
|       |  ENGINEERING      |                                                   |
|       |  WORKSTATION      |                                                   |
|       |                   |                                                   |
|       | +---------------+ |                                                   |
|       | | Studio 5000   | |                                                   |
|       | | FactoryTalk   | |                                                   |
|       | | RSLinx        | |                                                   |
|       | +-------+-------+ |                                                   |
|       +---------+---------+                                                   |
|                 |                                                             |
|                 | EtherNet/IP (Port 44818)                                    |
|                 v                                                             |
|       +-------------------+                                                   |
|       |  ControlLogix     |                                                   |
|       |  CompactLogix     |                                                   |
|       +-------------------+                                                   |
|                                                                               |
|  ROCKWELL PROTOCOLS                                                           |
|  ==================                                                           |
|                                                                               |
|  +------------------+--------------+---------------------------------+        |
|  | Protocol         | Port         | Description                     |        |
|  +------------------+--------------+---------------------------------+        |
|  | EtherNet/IP      | TCP 44818    | Explicit messaging              |        |
|  | EtherNet/IP      | UDP 2222     | Implicit I/O                    |        |
|  | CIP              | Encapsulated | Common Industrial Protocol      |        |
|  +------------------+--------------+---------------------------------+        |
|                                                                               |
+==============================================================================+
```

#### Device Configuration

```
+------------------------------------------------------------------------------+
|                    ROCKWELL ENVIRONMENT CONFIGURATION                         |
+------------------------------------------------------------------------------+

  ENGINEERING WORKSTATION
  =======================

  wabadmin device create ROCKWELL-ENG-01 \
    --domain OT-Engineering \
    --host 10.100.30.10 \
    --alias "Rockwell Engineering Station" \
    --description "Studio 5000 V32 - ControlLogix Programming"

  wabadmin service create ROCKWELL-ENG-01/RDP \
    --protocol rdp \
    --port 3389

  wabadmin account create ROCKWELL-ENG-01/plc_engineer \
    --service RDP \
    --credentials-type password \
    --description "Studio 5000 engineering access"

  ---------------------------------------------------------------------------

  FACTORYTALK VIEW SE SERVER
  ==========================

  wabadmin device create FTV-SE-01 \
    --domain OT-Operations \
    --host 10.100.30.20 \
    --alias "FactoryTalk View SE Server" \
    --description "HMI Server - Production Area 1"

  wabadmin service create FTV-SE-01/RDP \
    --protocol rdp \
    --port 3389

  wabadmin account create FTV-SE-01/ftv_admin \
    --service RDP \
    --credentials-type password \
    --description "FactoryTalk View administration"

  ---------------------------------------------------------------------------

  AUTHORIZATION
  =============

  # Engineering access with approval
  wabadmin authorization create Rockwell-Engineering \
    --user-group OT-Engineers \
    --target ROCKWELL-ENG-01/RDP/plc_engineer \
    --approval-required true \
    --approval-group OT-Supervisors \
    --session-recording true \
    --max-session-duration 8h

  # Operations access without approval (during shifts)
  wabadmin authorization create Rockwell-Operations \
    --user-group OT-Operators \
    --target FTV-SE-01/RDP/operator \
    --approval-required false \
    --time-restriction "24x7" \
    --session-recording true

+------------------------------------------------------------------------------+
```

#### Password Rotation

```
+==============================================================================+
|                    ROCKWELL PASSWORD MANAGEMENT                               |
+==============================================================================+
|                                                                               |
|  MANAGED BY WALLIX                                                            |
|  =================                                                            |
|                                                                               |
|  +------------------------+------------------+----------------------------+   |
|  | Component              | Support          | Method                     |   |
|  +------------------------+------------------+----------------------------+   |
|  | Windows Workstations   | Yes              | WinRM rotation             |   |
|  | FactoryTalk Services   | Manual           | Service account rotation   |   |
|  +------------------------+------------------+----------------------------+   |
|                                                                               |
|  CONTROLLOGIX CONTROLLER SECURITY                                             |
|  ================================                                             |
|                                                                               |
|  ControlLogix supports CIP Security with:                                     |
|  * Controller mode keys                                                       |
|  * Source key protection                                                      |
|  * Certificate-based authentication                                           |
|                                                                               |
|  These are configured via Studio 5000 and recorded in WALLIX sessions.        |
|                                                                               |
|  FACTORYTALK DIRECTORY                                                        |
|  =====================                                                        |
|                                                                               |
|  FactoryTalk uses its own user database or integrates with Windows AD.        |
|  For AD-integrated deployments, WALLIX manages the AD accounts.               |
|                                                                               |
+==============================================================================+
```

#### Session Recording

| Recorded Element | Details |
|------------------|---------|
| Studio 5000 operations | Full graphical recording |
| Online program edits | All ladder logic changes |
| Controller downloads | Download operations visible |
| Tag value forcing | I/O forcing captured |
| RSLinx configuration | Driver setup recorded |

---

### Schneider Electric

#### Overview

Schneider Electric systems use Unity Pro, EcoStruxure, and Modbus protocols.

```
+==============================================================================+
|                    SCHNEIDER ELECTRIC INTEGRATION                             |
+==============================================================================+
|                                                                               |
|  PRODUCT PORTFOLIO                                                            |
|  =================                                                            |
|                                                                               |
|  +-------------------+------------------------------------+                   |
|  | Product           | Description                        |                   |
|  +-------------------+------------------------------------+                   |
|  | Modicon M340/M580 | Process automation PLCs            |                   |
|  | Unity Pro/XL      | PLC programming environment        |                   |
|  | EcoStruxure       | Integrated automation platform     |                   |
|  | Vijeo Designer    | HMI development                    |                   |
|  | Citect SCADA      | SCADA system                       |                   |
|  +-------------------+------------------------------------+                   |
|                                                                               |
|  ACCESS ARCHITECTURE                                                          |
|  ===================                                                          |
|                                                                               |
|       +----------------+                                                      |
|       |   OT Engineer  |                                                      |
|       +-------+--------+                                                      |
|               |                                                               |
|               | RDP                                                           |
|               v                                                               |
|       +================+                                                      |
|       | WALLIX BASTION |                                                      |
|       +-------+========+                                                      |
|               |                                                               |
|               | RDP                                                           |
|               v                                                               |
|       +-------------------+                                                   |
|       |  ENGINEERING      |                                                   |
|       |  WORKSTATION      |                                                   |
|       |                   |                                                   |
|       | +---------------+ |                                                   |
|       | | Unity Pro XL  | |                                                   |
|       | | EcoStruxure   | |                                                   |
|       | +-------+-------+ |                                                   |
|       +---------+---------+                                                   |
|                 |                                                             |
|                 | Modbus TCP (Port 502)                                       |
|                 | EtherNet/IP                                                 |
|                 v                                                             |
|       +-------------------+                                                   |
|       |  Modicon M580     |                                                   |
|       |  Modicon M340     |                                                   |
|       +-------------------+                                                   |
|                                                                               |
+==============================================================================+
```

#### Device Configuration

```
+------------------------------------------------------------------------------+
|                    SCHNEIDER ENVIRONMENT CONFIGURATION                        |
+------------------------------------------------------------------------------+

  ENGINEERING WORKSTATION
  =======================

  wabadmin device create SCHNEIDER-ENG-01 \
    --domain OT-Engineering \
    --host 10.100.40.10 \
    --alias "Schneider Engineering Station" \
    --description "Unity Pro XL 14.0 - Modicon Programming"

  wabadmin service create SCHNEIDER-ENG-01/RDP \
    --protocol rdp \
    --port 3389

  wabadmin account create SCHNEIDER-ENG-01/plc_engineer \
    --service RDP \
    --credentials-type password \
    --description "Unity Pro engineering access"

  ---------------------------------------------------------------------------

  ECOSTRUXURE CONTROL SERVER
  ==========================

  wabadmin device create ECO-CTRL-01 \
    --domain OT-Operations \
    --host 10.100.40.20 \
    --alias "EcoStruxure Control Expert" \
    --description "Integrated automation server"

  wabadmin service create ECO-CTRL-01/RDP \
    --protocol rdp \
    --port 3389

  wabadmin service create ECO-CTRL-01/HTTPS \
    --protocol https \
    --port 443 \
    --description "EcoStruxure web interface"

  wabadmin account create ECO-CTRL-01/eco_admin \
    --service RDP \
    --credentials-type password \
    --description "EcoStruxure administration"

  ---------------------------------------------------------------------------

  CITECT SCADA SERVER
  ===================

  wabadmin device create CITECT-01 \
    --domain OT-Operations \
    --host 10.100.40.30 \
    --alias "Citect SCADA Server" \
    --description "Production SCADA Server"

  wabadmin service create CITECT-01/RDP \
    --protocol rdp \
    --port 3389

  wabadmin account create CITECT-01/scada_admin \
    --service RDP \
    --credentials-type password \
    --description "Citect SCADA administration"

+------------------------------------------------------------------------------+
```

#### Password Rotation

```
+==============================================================================+
|                    SCHNEIDER PASSWORD MANAGEMENT                              |
+==============================================================================+
|                                                                               |
|  MANAGED BY WALLIX                                                            |
|  =================                                                            |
|                                                                               |
|  +------------------------+------------------+----------------------------+   |
|  | Component              | Support          | Method                     |   |
|  +------------------------+------------------+----------------------------+   |
|  | Windows Workstations   | Yes              | WinRM rotation             |   |
|  | EcoStruxure Users      | Via Windows      | AD integration             |   |
|  | Citect SCADA Users     | Manual           | Citect user management     |   |
|  +------------------------+------------------+----------------------------+   |
|                                                                               |
|  MODICON PLC SECURITY                                                         |
|  ====================                                                         |
|                                                                               |
|  Modicon M580/M340 controllers support:                                       |
|  * CPU protection levels (None, Read, Read/Write)                             |
|  * Application password                                                       |
|  * Secure Boot (M580 only)                                                    |
|                                                                               |
|  These settings are configured in Unity Pro projects.                         |
|  All changes are visible in WALLIX session recordings.                        |
|                                                                               |
|  MODBUS SECURITY CONSIDERATIONS                                               |
|  ==============================                                               |
|                                                                               |
|  Standard Modbus TCP has NO authentication.                                   |
|  WALLIX provides access control at the workstation level:                     |
|                                                                               |
|  1. User authenticates to WALLIX                                              |
|  2. WALLIX authorizes access to engineering workstation                       |
|  3. Modbus traffic originates from approved workstation                       |
|  4. Session is fully recorded                                                 |
|                                                                               |
+==============================================================================+
```

#### Session Recording

| Recorded Element | Details |
|------------------|---------|
| Unity Pro operations | Full screen recording |
| PLC program changes | All ladder/FBD edits visible |
| Online modifications | Online changes captured |
| Project transfers | Upload/download visible |
| Citect SCADA config | All configuration changes |

---

## Integration Best Practices

### Network Device Best Practices

```
+==============================================================================+
|                    NETWORK DEVICE BEST PRACTICES                              |
+==============================================================================+
|                                                                               |
|  ACCOUNT MANAGEMENT                                                           |
|  ==================                                                           |
|                                                                               |
|  1. CREATE DEDICATED WALLIX ACCOUNTS                                          |
|     +-------------------------------------------------------------------+    |
|     | Do NOT use shared admin accounts.                                  |    |
|     | Create individual accounts for WALLIX management:                  |    |
|     |                                                                    |    |
|     | - wallix_admin (for password rotation)                             |    |
|     | - wallix_backup (for configuration backup)                         |    |
|     | - Individual user accounts (for session access)                    |    |
|     +-------------------------------------------------------------------+    |
|                                                                               |
|  2. USE TACACS+/RADIUS INTEGRATION                                            |
|     +-------------------------------------------------------------------+    |
|     | Integrate network devices with TACACS+/RADIUS for:                 |    |
|     |                                                                    |    |
|     | - Centralized authentication                                       |    |
|     | - Command authorization                                            |    |
|     | - Accounting/logging                                               |    |
|     |                                                                    |    |
|     | WALLIX can manage TACACS+/RADIUS passwords.                        |    |
|     +-------------------------------------------------------------------+    |
|                                                                               |
|  3. SEPARATE ENABLE PASSWORDS                                                 |
|     +-------------------------------------------------------------------+    |
|     | Configure enable passwords as secondary credentials in WALLIX.     |    |
|     | Rotate enable passwords separately from user passwords.            |    |
|     +-------------------------------------------------------------------+    |
|                                                                               |
|  PASSWORD POLICY RECOMMENDATIONS                                              |
|  ================================                                             |
|                                                                               |
|  +--------------------+-----------------------+--------------------------+    |
|  | Device Type        | Rotation Frequency    | Special Characters       |    |
|  +--------------------+-----------------------+--------------------------+    |
|  | Core Routers       | 90 days               | Avoid | ; < > in CLI     |    |
|  | Access Switches    | 90 days               | Limited set recommended  |    |
|  | Firewalls          | 60 days               | Full complexity allowed  |    |
|  | Load Balancers     | 90 days               | Full complexity allowed  |    |
|  +--------------------+-----------------------+--------------------------+    |
|                                                                               |
+==============================================================================+
```

### Industrial/OT Best Practices

```
+==============================================================================+
|                    OT INTEGRATION BEST PRACTICES                              |
+==============================================================================+
|                                                                               |
|  1. ENGINEERING WORKSTATION STRATEGY                                          |
|  ===================================                                          |
|                                                                               |
|     +-------------------------------------------------------------------+    |
|     | Use dedicated engineering workstations as jump hosts.              |    |
|     | All access to OT devices flows through WALLIX to workstation.      |    |
|     |                                                                    |    |
|     |       User --> WALLIX --> Eng. Workstation --> PLC/DCS            |    |
|     |                                                                    |    |
|     | Benefits:                                                          |    |
|     | - Full session recording of engineering activities                 |    |
|     | - Software licensing contained on workstation                      |    |
|     | - Network segmentation maintained                                  |    |
|     +-------------------------------------------------------------------+    |
|                                                                               |
|  2. MAINTENANCE WINDOW SCHEDULING                                             |
|  ================================                                             |
|                                                                               |
|     +-------------------------------------------------------------------+    |
|     | Configure time restrictions for OT access:                         |    |
|     |                                                                    |    |
|     | - Routine access: Business hours only                              |    |
|     | - Emergency access: 24/7 with approval                             |    |
|     | - Vendor access: Scheduled maintenance windows                     |    |
|     |                                                                    |    |
|     | Example authorization:                                             |    |
|     | --time-restriction "MON-FRI 06:00-18:00"                           |    |
|     +-------------------------------------------------------------------+    |
|                                                                               |
|  3. APPROVAL WORKFLOWS                                                        |
|  =====================                                                        |
|                                                                               |
|     +-------------------------------------------------------------------+    |
|     | Always require approval for:                                       |    |
|     |                                                                    |    |
|     | - PLC programming access                                           |    |
|     | - Safety system access                                             |    |
|     | - Production-critical system changes                               |    |
|     | - Vendor/contractor access                                         |    |
|     |                                                                    |    |
|     | Configure dual approval for highly critical systems.               |    |
|     +-------------------------------------------------------------------+    |
|                                                                               |
|  4. SESSION RECORDING RETENTION                                               |
|  ==============================                                               |
|                                                                               |
|     +-------------------------------------------------------------------+    |
|     | OT session recordings should be retained longer:                   |    |
|     |                                                                    |    |
|     | - Minimum: 1 year                                                  |    |
|     | - Recommended: 3-5 years                                           |    |
|     | - Critical systems: 7+ years                                       |    |
|     |                                                                    |    |
|     | Recordings are valuable for:                                       |    |
|     | - Incident investigation                                           |    |
|     | - Regulatory compliance                                            |    |
|     | - Knowledge transfer                                               |    |
|     +-------------------------------------------------------------------+    |
|                                                                               |
|  5. NETWORK SEGMENTATION                                                      |
|  =======================                                                      |
|                                                                               |
|     +-------------------------------------------------------------------+    |
|     | Deploy WALLIX at the boundary between IT and OT networks:          |    |
|     |                                                                    |    |
|     |    IT Network          DMZ              OT Network                |    |
|     |   +----------+   +------------+   +------------------+            |    |
|     |   | Users    |-->| WALLIX     |-->| Engineering WS   |            |    |
|     |   +----------+   | Bastion    |   | PLCs, DCS        |            |    |
|     |                  +------------+   +------------------+            |    |
|     |                                                                    |    |
|     | Firewall rules should only allow WALLIX to access OT systems.     |    |
|     +-------------------------------------------------------------------+    |
|                                                                               |
+==============================================================================+
```

### Troubleshooting Guide

```
+==============================================================================+
|                    COMMON INTEGRATION ISSUES                                  |
+==============================================================================+
|                                                                               |
|  NETWORK DEVICE ISSUES                                                        |
|  =====================                                                        |
|                                                                               |
|  +---------------------+---------------------------+-----------------------+  |
|  | Issue               | Possible Cause            | Resolution            |  |
|  +---------------------+---------------------------+-----------------------+  |
|  | SSH connection      | SSHv1 only on device      | Upgrade device IOS    |  |
|  | refused             |                           | or enable SSHv2       |  |
|  +---------------------+---------------------------+-----------------------+  |
|  | Authentication      | TACACS+ server issue      | Check TACACS+ server  |  |
|  | timeout             |                           | or fall back to local |  |
|  +---------------------+---------------------------+-----------------------+  |
|  | Password rotation   | Complexity mismatch       | Adjust WALLIX policy  |  |
|  | fails               |                           | to match device       |  |
|  +---------------------+---------------------------+-----------------------+  |
|  | Config not saved    | Write memory failed       | Check flash space     |  |
|  | after rotation      |                           |                       |  |
|  +---------------------+---------------------------+-----------------------+  |
|                                                                               |
|  OT/INDUSTRIAL ISSUES                                                         |
|  ====================                                                         |
|                                                                               |
|  +---------------------+---------------------------+-----------------------+  |
|  | Issue               | Possible Cause            | Resolution            |  |
|  +---------------------+---------------------------+-----------------------+  |
|  | RDP session slow    | Large project files       | Optimize RDP settings |  |
|  |                     | or poor network           | or use RemoteFX       |  |
|  +---------------------+---------------------------+-----------------------+  |
|  | Engineering SW      | License server            | Configure license     |  |
|  | won't start         | unreachable               | server access         |  |
|  +---------------------+---------------------------+-----------------------+  |
|  | PLC connection      | OT network firewall       | Verify firewall rules |  |
|  | fails from WS       | blocking protocol         | allow protocol ports  |  |
|  +---------------------+---------------------------+-----------------------+  |
|  | Session recording   | Screen resolution         | Set fixed resolution  |  |
|  | quality poor        | too high                  | in RDP settings       |  |
|  +---------------------+---------------------------+-----------------------+  |
|                                                                               |
+==============================================================================+
```

---

## External Resources

| Vendor | Documentation URL |
|--------|-------------------|
| Cisco | https://www.cisco.com/c/en/us/support/index.html |
| Juniper | https://www.juniper.net/documentation/ |
| Palo Alto | https://docs.paloaltonetworks.com/ |
| Fortinet | https://docs.fortinet.com/ |
| F5 | https://techdocs.f5.com/ |
| Siemens | https://support.industry.siemens.com/ |
| ABB | https://new.abb.com/control-systems/service/800xa-support |
| Rockwell | https://rockwellautomation.custhelp.com/ |
| Schneider | https://www.se.com/ww/en/work/support/ |
| WALLIX | https://pam.wallix.one/documentation |

---

## Next Steps

- Continue to [37 - Cloud Vendor Integration](../37-cloud-vendor-integration/README.md) for AWS, Azure, GCP specific guides
- See [17 - Industrial Protocols](../17-industrial-protocols/README.md) for protocol details
- See [07 - Password Management](../08-password-management/README.md) for rotation configuration details
