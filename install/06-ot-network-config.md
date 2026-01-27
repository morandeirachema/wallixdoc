# 06 - OT Network Configuration

## Table of Contents

1. [Network Segmentation](#network-segmentation)
2. [Industrial Protocol Support](#industrial-protocol-support)
3. [Universal Tunneling](#universal-tunneling)
4. [Device Integration](#device-integration)
5. [Protocol-Specific Configuration](#protocol-specific-configuration)

---

## Network Segmentation

### IEC 62443 Zone Architecture

```
+==============================================================================+
|                   OT NETWORK SEGMENTATION (IEC 62443)                        |
+==============================================================================+

  LEVEL 4-5: ENTERPRISE ZONE
  +------------------------------------------------------------------------+
  |  Corporate Network                                                      |
  |  [ERP] [Email] [File Servers] [Corporate Users]                        |
  +-------------------------------------+----------------------------------+
                                        |
  =====================================DMZ=====================================
                                        |
  LEVEL 3.5: OT DMZ                     |
  +-------------------------------------+----------------------------------+
  |  +----------------+    +------------------+    +------------------+    |
  |  | WALLIX BASTION |    | Historian Mirror |    | Patch Server     |    |
  |  | (Jump Server)  |    | (Read-Only)      |    | (Staging)        |    |
  |  | 10.x.10.5      |    | 10.x.10.10       |    | 10.x.10.15       |    |
  |  +-------+--------+    +------------------+    +------------------+    |
  +----------|-------------------------------------------------------------+
             |
  ==========|=================INDUSTRIAL FIREWALL=============================
             |
  LEVEL 3: OPERATIONS ZONE (Security Level 3)
  +----------|-------------------------------------------------------------+
  |          v                                                              |
  |  +----------------+    +------------------+    +------------------+    |
  |  | SCADA Server   |    | Historian        |    | Engineering WS   |    |
  |  | 10.x.20.10     |    | 10.x.20.20       |    | 10.x.20.30       |    |
  |  +-------+--------+    +------------------+    +------------------+    |
  +----------|-------------------------------------------------------------+
             |
  ==========|=================CONTROL FIREWALL================================
             |
  LEVEL 2: CONTROL ZONE (Security Level 2)
  +----------|-------------------------------------------------------------+
  |          v                                                              |
  |  +----------------+    +------------------+    +------------------+    |
  |  | HMI Stations   |    | Control Server   |    | Operator WS      |    |
  |  | 10.x.30.10-50  |    | 10.x.30.100      |    | 10.x.30.200      |    |
  |  +-------+--------+    +------------------+    +------------------+    |
  +----------|-------------------------------------------------------------+
             |
  ==========|=================FIELD FIREWALL==================================
             |
  LEVEL 0-1: FIELD ZONE (Security Level 1)
  +----------|-------------------------------------------------------------+
  |          v                                                              |
  |  +--------+-------+    +------------------+    +------------------+    |
  |  | PLCs           |    | RTUs             |    | Safety Systems   |    |
  |  | 10.x.40.10-100 |    | 10.x.40.110-150  |    | 10.x.40.200-250  |    |
  |  +----------------+    +------------------+    +------------------+    |
  +------------------------------------------------------------------------+

+==============================================================================+
```

### Firewall Rules for WALLIX

```bash
# OT DMZ Firewall Rules (between Enterprise and OT DMZ)

# Allow WALLIX management access from IT admins
iptables -A FORWARD -s 10.0.1.0/24 -d 10.100.10.5 -p tcp --dport 443 -j ACCEPT

# Allow user access to WALLIX for session proxying
iptables -A FORWARD -s 10.0.0.0/8 -d 10.100.10.5 -p tcp --dport 22 -j ACCEPT
iptables -A FORWARD -s 10.0.0.0/8 -d 10.100.10.5 -p tcp --dport 3389 -j ACCEPT
iptables -A FORWARD -s 10.0.0.0/8 -d 10.100.10.5 -p tcp --dport 5900 -j ACCEPT

# Block direct access to OT zones (must go through WALLIX)
iptables -A FORWARD -s 10.0.0.0/8 -d 10.100.20.0/24 -j DROP
iptables -A FORWARD -s 10.0.0.0/8 -d 10.100.30.0/24 -j DROP
iptables -A FORWARD -s 10.0.0.0/8 -d 10.100.40.0/24 -j DROP

# Allow WALLIX to access OT zones
iptables -A FORWARD -s 10.100.10.5 -d 10.100.20.0/24 -j ACCEPT
iptables -A FORWARD -s 10.100.10.5 -d 10.100.30.0/24 -j ACCEPT
iptables -A FORWARD -s 10.100.10.5 -d 10.100.40.0/24 -j ACCEPT
```

---

## Industrial Protocol Support

### Supported Protocols

```
+==============================================================================+
|                   INDUSTRIAL PROTOCOL SUPPORT                                |
+==============================================================================+

  NATIVE PROXY SUPPORT (Full Session Recording)
  =============================================

  +------------------------------------------------------------------------+
  | Protocol        | Port  | Recording | Credential Injection | Notes     |
  +-----------------+-------+-----------+----------------------+-----------+
  | SSH             | 22    | Full      | Yes                  | Native    |
  | RDP             | 3389  | Full      | Yes                  | Native    |
  | VNC             | 5900  | Full      | Yes                  | Native    |
  | Telnet          | 23    | Full      | Yes                  | Native    |
  | HTTP/HTTPS      | 80/443| Full      | Yes                  | 12.x new  |
  +-----------------+-------+-----------+----------------------+-----------+

  --------------------------------------------------------------------------

  UNIVERSAL TUNNELING (Encapsulated Protocols)
  ============================================

  +------------------------------------------------------------------------+
  | Protocol        | Port  | Tunnel Type | Use Case                       |
  +-----------------+-------+-------------+--------------------------------+
  | Modbus TCP      | 502   | SSH Tunnel  | PLC programming                |
  | EtherNet/IP     | 44818 | SSH Tunnel  | Allen-Bradley devices          |
  | S7comm          | 102   | SSH Tunnel  | Siemens PLCs                   |
  | PROFINET        | 34964 | SSH Tunnel  | Siemens/industrial Ethernet    |
  | OPC UA          | 4840  | SSH Tunnel  | Industrial data exchange       |
  | BACnet/IP       | 47808 | SSH Tunnel  | Building automation            |
  | DNP3            | 20000 | SSH Tunnel  | SCADA (TCP only)               |
  | IEC 61850 MMS   | 102   | SSH Tunnel  | Substation automation          |
  +-----------------+-------+-------------+--------------------------------+

+==============================================================================+
```

---

## Universal Tunneling

### Configuration

```bash
# Enable Universal Tunneling
wab-admin config-set tunneling.enabled true
wab-admin config-set tunneling.protocols "modbus,s7comm,ethernetip,opcua,bacnet,dnp3"

# Configure tunnel settings
wab-admin config-set tunneling.timeout 3600          # 1 hour max session
wab-admin config-set tunneling.keepalive 60          # Keepalive interval
wab-admin config-set tunneling.max_tunnels 100       # Max concurrent tunnels
```

### Create Tunnel Definitions

```json
// /etc/opt/wab/tunnels.json
{
  "tunnels": [
    {
      "name": "modbus-plc-line1",
      "description": "Modbus access to Line 1 PLCs",
      "protocol": "modbus",
      "local_port": 10502,
      "remote_host": "10.100.40.10",
      "remote_port": 502,
      "authorization_required": true,
      "recording": true,
      "allowed_groups": ["ot-engineers", "plc-programmers"]
    },
    {
      "name": "s7-siemens-plc1",
      "description": "S7comm access to Siemens S7-1500",
      "protocol": "s7comm",
      "local_port": 10102,
      "remote_host": "10.100.40.20",
      "remote_port": 102,
      "authorization_required": true,
      "recording": true,
      "allowed_groups": ["siemens-engineers"]
    },
    {
      "name": "opcua-historian",
      "description": "OPC UA access to Historian",
      "protocol": "opcua",
      "local_port": 14840,
      "remote_host": "10.100.20.20",
      "remote_port": 4840,
      "authorization_required": true,
      "recording": true,
      "tls_enabled": true,
      "allowed_groups": ["data-engineers"]
    }
  ]
}
```

### User Connection via Tunnel

```bash
# User establishes SSH tunnel through WALLIX
ssh -L 10502:localhost:10502 user@wallix.site-a.company.com

# Then connects their Modbus client to localhost:10502
# WALLIX proxies the connection to the actual PLC

# Or use WALLIX client application
wallix-connect --tunnel modbus-plc-line1 --user operator1
```

---

## Device Integration

### Add OT Devices

```bash
# Add PLCs
wab-admin device-create \
    --name "PLC-Line1-Main" \
    --host "10.100.40.10" \
    --description "Main PLC for Production Line 1" \
    --protocols "modbus:502,s7comm:102" \
    --zone "field-zone" \
    --tags "plc,production,line1"

wab-admin device-create \
    --name "PLC-Line2-Main" \
    --host "10.100.40.11" \
    --description "Main PLC for Production Line 2" \
    --protocols "modbus:502" \
    --zone "field-zone" \
    --tags "plc,production,line2"

# Add SCADA server
wab-admin device-create \
    --name "SCADA-Primary" \
    --host "10.100.20.10" \
    --description "Primary SCADA Server" \
    --protocols "rdp:3389,ssh:22" \
    --zone "operations-zone" \
    --tags "scada,critical"

# Add HMI stations
wab-admin device-create \
    --name "HMI-Station-01" \
    --host "10.100.30.10" \
    --description "Operator HMI Station 1" \
    --protocols "vnc:5900" \
    --zone "control-zone" \
    --tags "hmi,operator"

# Add Engineering Workstation
wab-admin device-create \
    --name "ENG-WS-01" \
    --host "10.100.20.30" \
    --description "Engineering Workstation with TIA Portal" \
    --protocols "rdp:3389" \
    --zone "operations-zone" \
    --tags "engineering,siemens"
```

### Configure Device Accounts

```bash
# Configure service accounts for devices
wab-admin account-create \
    --name "plc-admin" \
    --device "PLC-Line1-Main" \
    --protocol "modbus" \
    --description "PLC Admin Account" \
    --auto-rotate false \
    --checkout-required true

wab-admin account-create \
    --name "Administrator" \
    --device "SCADA-Primary" \
    --protocol "rdp" \
    --description "SCADA Windows Admin" \
    --domain "OT-DOMAIN" \
    --auto-rotate true \
    --rotation-days 90

wab-admin account-create \
    --name "root" \
    --device "SCADA-Primary" \
    --protocol "ssh" \
    --description "SCADA Linux Root" \
    --ssh-key "/var/wab/keys/scada-root.pem" \
    --auto-rotate true \
    --rotation-days 30
```

---

## Protocol-Specific Configuration

### Modbus Configuration

```json
// /etc/opt/wab/protocols/modbus.json
{
  "modbus": {
    "enabled": true,
    "default_port": 502,
    "timeout_seconds": 30,
    "max_connections": 50,

    "security": {
      "require_authorization": true,
      "log_all_transactions": true,
      "block_write_registers": false,
      "allowed_function_codes": [1, 2, 3, 4, 5, 6, 15, 16],
      "blocked_function_codes": [8, 17]
    },

    "recording": {
      "enabled": true,
      "log_read_operations": true,
      "log_write_operations": true,
      "alert_on_write": true
    }
  }
}
```

### S7comm Configuration (Siemens)

```json
// /etc/opt/wab/protocols/s7comm.json
{
  "s7comm": {
    "enabled": true,
    "default_port": 102,
    "timeout_seconds": 60,

    "security": {
      "require_authorization": true,
      "log_all_transactions": true,
      "block_cpu_stop": true,
      "block_plc_program_download": false,
      "block_memory_write": false
    },

    "allowed_operations": [
      "read_db",
      "read_inputs",
      "read_outputs",
      "read_markers",
      "write_db",
      "write_outputs"
    ],

    "blocked_operations": [
      "cpu_stop",
      "cpu_cold_restart",
      "delete_block"
    ],

    "recording": {
      "enabled": true,
      "log_read_operations": true,
      "log_write_operations": true,
      "alert_on_program_change": true,
      "alert_on_cpu_command": true
    }
  }
}
```

### OPC UA Configuration

```json
// /etc/opt/wab/protocols/opcua.json
{
  "opcua": {
    "enabled": true,
    "default_port": 4840,
    "security_mode": "SignAndEncrypt",
    "security_policy": "Basic256Sha256",

    "authentication": {
      "type": "username_password",
      "credential_injection": true
    },

    "certificate": {
      "enabled": true,
      "cert_path": "/etc/opt/wab/certs/opcua-client.pem",
      "key_path": "/etc/opt/wab/certs/opcua-client.key",
      "trust_path": "/etc/opt/wab/certs/opcua-trusted/"
    },

    "security": {
      "require_authorization": true,
      "log_all_transactions": true,
      "allowed_namespaces": ["*"],
      "blocked_methods": []
    },

    "recording": {
      "enabled": true,
      "log_browse": true,
      "log_read": true,
      "log_write": true,
      "log_subscribe": true
    }
  }
}
```

### Apply Protocol Configurations

```bash
# Reload protocol configurations
wab-admin protocol-reload

# Verify protocol status
wab-admin protocol-status

# Expected output:
# Protocol     | Status  | Connections | Config File
# -------------+---------+-------------+---------------------------
# modbus       | Active  | 5           | /etc/opt/wab/protocols/modbus.json
# s7comm       | Active  | 3           | /etc/opt/wab/protocols/s7comm.json
# opcua        | Active  | 2           | /etc/opt/wab/protocols/opcua.json
# ethernetip   | Active  | 1           | /etc/opt/wab/protocols/ethernetip.json
```

---

**Next Step**: [07-security-hardening.md](./07-security-hardening.md) - Security Hardening
