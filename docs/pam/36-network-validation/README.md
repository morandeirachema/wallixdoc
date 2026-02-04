# 47 - Network Configuration and Validation

## Table of Contents

1. [Network Requirements Overview](#network-requirements-overview)
2. [Network Architecture](#network-architecture)
3. [Port Reference](#port-reference)
4. [Firewall Configuration](#firewall-configuration)
5. [DNS Configuration](#dns-configuration)
6. [NTP Configuration](#ntp-configuration)
7. [MTU Configuration](#mtu-configuration)
8. [Network Validation Procedures](#network-validation-procedures)
9. [HA Network Configuration](#ha-network-configuration)
10. [Multi-Site Network](#multi-site-network)
11. [Troubleshooting](#troubleshooting)
12. [Network Monitoring](#network-monitoring)

---

## Network Requirements Overview

### Bandwidth Requirements

```
+==============================================================================+
|                    BANDWIDTH REQUIREMENTS                                     |
+==============================================================================+

  SESSION BANDWIDTH BY PROTOCOL
  =============================

  +------------------------------------------------------------------------+
  | Protocol        | Minimum      | Recommended  | Heavy Use               |
  +-----------------+--------------+--------------+-------------------------+
  | SSH (text)      | 10 Kbps      | 50 Kbps      | 100 Kbps (file transfer)|
  | SSH (X11)       | 100 Kbps     | 500 Kbps     | 2 Mbps                  |
  | RDP (standard)  | 100 Kbps     | 500 Kbps     | 1 Mbps                  |
  | RDP (HD/Video)  | 1 Mbps       | 5 Mbps       | 10 Mbps                 |
  | VNC             | 100 Kbps     | 300 Kbps     | 1 Mbps                  |
  | Telnet          | 5 Kbps       | 20 Kbps      | 50 Kbps                 |
  +-----------------+--------------+--------------+-------------------------+

  --------------------------------------------------------------------------

  DEPLOYMENT BANDWIDTH CALCULATION
  ================================

  Formula:
  Total Bandwidth = (Sessions x Avg Bandwidth) x 1.3 (overhead)

  Example Calculations:
  +------------------------------------------------------------------------+
  | Deployment Size   | Sessions | Mix (SSH/RDP)  | Required Bandwidth      |
  +-------------------+----------+----------------+-------------------------+
  | Small             | 50       | 70/30          | 50 Mbps                 |
  | Medium            | 200      | 60/40          | 200 Mbps                |
  | Large             | 500      | 50/50          | 500 Mbps                |
  | Enterprise        | 1000+    | 50/50          | 1 Gbps+                 |
  +-------------------+----------+----------------+-------------------------+

  --------------------------------------------------------------------------

  LATENCY REQUIREMENTS
  ====================

  +------------------------------------------------------------------------+
  | Connection Type           | Maximum Latency  | Impact if Exceeded       |
  +---------------------------+------------------+--------------------------+
  | User to WALLIX            | 100 ms           | Noticeable UI lag        |
  | WALLIX to Target          | 50 ms            | Session quality impact   |
  | WALLIX to LDAP/AD         | 20 ms            | Authentication delays    |
  | WALLIX to Database        | 10 ms            | Overall performance      |
  | HA Cluster Nodes          | 5 ms             | Replication lag          |
  | Multi-Site Replication    | 100 ms           | Sync delays acceptable   |
  +---------------------------+------------------+--------------------------+

  Latency Thresholds:
  * < 20 ms:   Excellent (recommended for production)
  * 20-50 ms:  Good (acceptable for most deployments)
  * 50-100 ms: Acceptable (noticeable delays possible)
  * > 100 ms:  Poor (user experience degraded)

+==============================================================================+
```

### Protocol Requirements

```
+==============================================================================+
|                    PROTOCOL REQUIREMENTS                                      |
+==============================================================================+

  REQUIRED PROTOCOLS
  ==================

  +------------------------------------------------------------------------+
  | Protocol    | Version/Type      | Purpose                              |
  +-------------+-------------------+--------------------------------------+
  | TCP/IP      | IPv4 (IPv6 opt.)  | All communications                   |
  | TLS         | 1.2, 1.3          | Encrypted communications             |
  | DNS         | UDP/TCP 53        | Name resolution                      |
  | NTP         | UDP 123           | Time synchronization                 |
  | ICMP        | Echo Request/Reply| Health checks (optional)             |
  +-------------+-------------------+--------------------------------------+

  --------------------------------------------------------------------------

  SESSION PROTOCOLS
  =================

  +------------------------------------------------------------------------+
  | Protocol    | Default Port | Encryption                                |
  +-------------+--------------+-------------------------------------------+
  | SSH         | 22/tcp       | Native (SSH protocol)                     |
  | RDP         | 3389/tcp     | TLS/NLA                                   |
  | VNC         | 5900/tcp     | Optional TLS tunnel                       |
  | Telnet      | 23/tcp       | None (legacy, not recommended)            |
  | HTTPS       | 443/tcp      | TLS 1.2/1.3                               |
  +-------------+--------------+-------------------------------------------+

  --------------------------------------------------------------------------

  INDUSTRIAL PROTOCOLS (OT Environments)
  ======================================

  +------------------------------------------------------------------------+
  | Protocol      | Default Port | Notes                                   |
  +---------------+--------------+-----------------------------------------+
  | Modbus TCP    | 502/tcp      | Tunneled through WALLIX                 |
  | OPC UA        | 4840/tcp     | Secure channel supported                |
  | DNP3          | 20000/tcp    | SCADA protocol                          |
  | EtherNet/IP   | 44818/tcp    | Allen-Bradley/Rockwell                  |
  | S7comm        | 102/tcp      | Siemens S7 PLC                          |
  | IEC 61850 MMS | 102/tcp      | Power systems                           |
  | BACnet/IP     | 47808/udp    | Building automation                     |
  +---------------+--------------+-----------------------------------------+

+==============================================================================+
```

---

## Network Architecture

### Typical Deployment Topology

```
+==============================================================================+
|                    NETWORK TOPOLOGY - STANDARD DEPLOYMENT                    |
+==============================================================================+

                              INTERNET
                                  |
                                  |
                         +--------+--------+
                         |  EDGE FIREWALL  |
                         |   (Perimeter)   |
                         +--------+--------+
                                  |
                                  | DMZ ZONE
                                  |
        +-------------------------+-------------------------+
        |                         |                         |
        v                         v                         v
  +-----------+           +-----------+            +-----------+
  |  Web App  |           |  VPN GW   |            |  Mail GW  |
  |  Server   |           |           |            |           |
  +-----------+           +-----+-----+            +-----------+
                                |
                                |
                         +------+------+
                         | INTERNAL FW |
                         |  (IT/OT)    |
                         +------+------+
                                |
        +-----------------------+-----------------------+
        |                       |                       |
        v                       v                       v
  +===========+          +===========+           +===========+
  |  CORPORATE |         |  WALLIX   |          |    OT      |
  |  NETWORK   |         |  BASTION  |          |  NETWORK   |
  | (Users)    |         |  (PAM)    |          | (Devices)  |
  | 10.0.0.0/8 |         | 10.1.0.0/24|         | 10.10.0.0/16|
  +===========+          +===========+           +===========+
        |                      | |                      |
        |   +------------------+ +------------------+   |
        |   |                                       |   |
        |   v                                       v   |
        |  +---+                                 +---+  |
        +->|443|--- Web UI, API ---------------->|22 |  |
        |  +---+                                 +---+  |
        |   |                                       |   |
        |  +---+                                 +---+  |
        +->|22 |--- SSH Proxy ----------------->|3389|--+
           +---+                                 +---+
            |                                       |
           +---+                                 +---+
           |3389--- RDP Proxy ----------------->|502|
           +---+                                 +---+
                                                    |
                                                 +---+
                                                 |4840
                                                 +---+

  USER ACCESS FLOW:
  =================
  1. User connects to WALLIX from Corporate Network
  2. WALLIX authenticates user (LDAP/AD/MFA)
  3. WALLIX authorizes based on policies
  4. WALLIX proxies connection to target in OT Network
  5. Session is recorded and audited

+==============================================================================+
```

### HA Cluster Network Architecture

```
+==============================================================================+
|                    HA CLUSTER NETWORK ARCHITECTURE                           |
+==============================================================================+

                              USERS
                                |
                                v
                      +------------------+
                      |  LOAD BALANCER   |
                      |  VIP: 10.1.0.100 |
                      +--------+---------+
                               |
            +------------------+------------------+
            |                                     |
            v                                     v
  +--------------------+               +--------------------+
  |   WALLIX NODE 1    |               |   WALLIX NODE 2    |
  |                    |               |                    |
  | Management Network |               | Management Network |
  | eth0: 10.1.0.10    |               | eth0: 10.1.0.11    |
  |                    |               |                    |
  | Cluster Network    |<=============>| Cluster Network    |
  | eth1: 192.168.1.10 |   Heartbeat   | eth1: 192.168.1.11 |
  |                    |   + PG Sync   |                    |
  +--------------------+               +--------------------+
            |                                     |
            +------------------+------------------+
                               |
                      +--------+--------+
                      | SHARED STORAGE  |
                      | (NFS/iSCSI)     |
                      | Session Records |
                      +-----------------+

  NETWORK INTERFACES PER NODE
  ===========================

  +------------------------------------------------------------------------+
  | Interface | Network          | Purpose                                 |
  +-----------+------------------+-----------------------------------------+
  | eth0      | Management       | User access, API, Admin SSH             |
  | eth1      | Cluster          | Heartbeat, DB replication               |
  | eth2      | Storage (opt.)   | NFS/iSCSI for recordings                |
  | eth3      | Target (opt.)    | Dedicated to OT network access          |
  +-----------+------------------+-----------------------------------------+

  CLUSTER COMMUNICATION
  =====================

  Node 1 (192.168.1.10) <---> Node 2 (192.168.1.11)

  +------------------------------------------------------------------------+
  | Port       | Protocol | Direction   | Purpose                          |
  +------------+----------+-------------+----------------------------------+
  | 5404-5406  | UDP      | Bidirection | Corosync cluster communication   |
  | 5432       | TCP      | Bidirection | PostgreSQL streaming replication |
  | 2224       | TCP      | Bidirection | Pacemaker PCSD web/API           |
  | 3121       | TCP      | Bidirection | Pacemaker remote                 |
  +------------+----------+-------------+----------------------------------+

+==============================================================================+
```

---

## Port Reference

### Consolidated Port Matrix (Source → Destination)

```
+===============================================================================+
|                  COMPLETE PORT REFERENCE MATRIX                               |
+===============================================================================+
|                                                                               |
|  This matrix shows ALL required network flows for WALLIX Bastion deployment  |
|                                                                               |
+===============================================================================+

USER → WALLIX
=============

+-----------------------------------------------------------------------------+
| Source          | Destination    | Port/Proto   | Purpose        | Req/Opt |
+-----------------+----------------+--------------+----------------+---------+
| End Users       | WALLIX         | 443/TCP      | Web UI, API    | Req     |
| End Users       | WALLIX         | 22/TCP       | SSH Proxy      | Req     |
| End Users       | WALLIX         | 3389/TCP     | RDP Proxy      | Req     |
| End Users       | WALLIX         | 5900/TCP     | VNC Proxy      | Opt     |
| End Users       | WALLIX         | 80/TCP       | HTTP redirect  | Opt     |
| Administrators  | WALLIX         | 22/TCP       | OS Admin SSH   | Req     |
| Monitoring      | WALLIX         | 161/UDP      | SNMP polling   | Opt     |
+-----------------+----------------+--------------+----------------+---------+

WALLIX → ACTIVE DIRECTORY / LDAP
=================================

+-----------------------------------------------------------------------------+
| Source          | Destination    | Port/Proto   | Purpose        | Req/Opt |
+-----------------+----------------+--------------+----------------+---------+
| WALLIX          | AD/LDAP        | 389/TCP      | LDAP auth      | Req*    |
| WALLIX          | AD/LDAP        | 636/TCP      | LDAPS          | Req*    |
| WALLIX          | AD/LDAP        | 3268/TCP     | Global Catalog | Req*    |
| WALLIX          | AD/LDAP        | 3269/TCP     | GC over SSL    | Req*    |
| WALLIX          | AD/KDC         | 88/TCP+UDP   | Kerberos auth  | Opt     |
| WALLIX          | AD/KDC         | 464/TCP+UDP  | Kerberos pwd   | Opt     |
| WALLIX          | AD/KDC         | 749/TCP      | Kerberos admin | Opt     |
+-----------------+----------------+--------------+----------------+---------+
* LDAP (389) OR LDAPS (636) required. Global Catalog for multi-domain forests.

WALLIX → FORTIAUTHENTICATOR (RADIUS)
=====================================

+-----------------------------------------------------------------------------+
| Source          | Destination    | Port/Proto   | Purpose        | Req/Opt |
+-----------------+----------------+--------------+----------------+---------+
| WALLIX          | FortiAuth      | 1812/UDP     | RADIUS auth    | Req     |
| WALLIX          | FortiAuth      | 1813/UDP     | RADIUS acct    | Opt     |
+-----------------+----------------+--------------+----------------+---------+

WALLIX → TARGET SERVERS
========================

+-----------------------------------------------------------------------------+
| Source          | Destination    | Port/Proto   | Purpose        | Req/Opt |
+-----------------+----------------+--------------+----------------+---------+
| WALLIX          | Linux/Unix     | 22/TCP       | SSH sessions   | Req     |
| WALLIX          | Windows        | 3389/TCP     | RDP sessions   | Req     |
| WALLIX          | Windows        | 5985/TCP     | WinRM HTTP     | Opt     |
| WALLIX          | Windows        | 5986/TCP     | WinRM HTTPS    | Opt     |
| WALLIX          | Various        | 5900+/TCP    | VNC sessions   | Opt     |
| WALLIX          | Legacy         | 23/TCP       | Telnet         | Opt     |
| WALLIX          | PLCs/RTUs      | 502/TCP      | Modbus TCP     | Opt     |
| WALLIX          | OPC Servers    | 4840/TCP     | OPC UA         | Opt     |
| WALLIX          | SCADA/IEDs     | 20000/TCP    | DNP3           | Opt     |
| WALLIX          | PLCs           | 44818/TCP+UDP| EtherNet/IP    | Opt     |
| WALLIX          | PLCs/SCADA     | 102/TCP      | S7/IEC61850    | Opt     |
| WALLIX          | BMS            | 47808/UDP    | BACnet/IP      | Opt     |
+-----------------+----------------+--------------+----------------+---------+

WALLIX HA CLUSTER (Between Bastion Nodes)
==========================================

+-----------------------------------------------------------------------------+
| Source          | Destination    | Port/Proto   | Purpose        | Req/Opt |
+-----------------+----------------+--------------+----------------+---------+
| WALLIX Node 1   | WALLIX Node 2  | 3306/TCP     | MariaDB repl   | Req     |
| WALLIX Node 1   | WALLIX Node 2  | 5404/UDP     | Corosync mcast | Req*    |
| WALLIX Node 1   | WALLIX Node 2  | 5405/UDP     | Corosync ucast | Req*    |
| WALLIX Node 1   | WALLIX Node 2  | 5406/UDP     | Corosync comm  | Req     |
| WALLIX Node 1   | WALLIX Node 2  | 2224/TCP     | Pacemaker PCSD | Req     |
| WALLIX Node 1   | WALLIX Node 2  | 3121/TCP     | Pacemaker rem  | Opt     |
| WALLIX Nodes    | Quorum Device  | 5403/TCP     | Qdevice        | Opt     |
+-----------------+----------------+--------------+----------------+---------+
* Either multicast (5404) OR unicast (5405) required, not both.

INFRASTRUCTURE SERVICES
========================

+-----------------------------------------------------------------------------+
| Source          | Destination    | Port/Proto   | Purpose        | Req/Opt |
+-----------------+----------------+--------------+----------------+---------+
| WALLIX          | DNS Server     | 53/UDP+TCP   | Name resolution| Req     |
| WALLIX          | NTP Server     | 123/UDP      | Time sync      | Req     |
| WALLIX          | Syslog Server  | 514/UDP      | Syslog plain   | Opt     |
| WALLIX          | Syslog Server  | 6514/TCP     | Syslog TLS     | Opt     |
| WALLIX          | SMTP Server    | 25/TCP       | Email notif    | Opt     |
| WALLIX          | SMTP Server    | 587/TCP      | SMTP STARTTLS  | Opt     |
| WALLIX          | SMTP Server    | 465/TCP      | SMTPS          | Opt     |
| WALLIX          | SNMP Manager   | 162/UDP      | SNMP traps     | Opt     |
| WALLIX          | Prometheus     | 9100/TCP     | Node exporter  | Opt     |
| WALLIX          | IdP (OIDC/SAML)| 443/TCP      | SSO auth       | Opt     |
+-----------------+----------------+--------------+----------------+---------+

+===============================================================================+
|  LEGEND                                                                       |
|  Req = Required    Opt = Optional    * = See notes                            |
+===============================================================================+
```

### Complete Port Matrix

```
+==============================================================================+
|                    COMPLETE PORT REFERENCE                                    |
+==============================================================================+

  INBOUND PORTS (To WALLIX Bastion)
  =================================

  User Access Ports:
  +------------------------------------------------------------------------+
  | Port     | Protocol | Source          | Description                    |
  +----------+----------+-----------------+--------------------------------+
  | 443      | TCP      | Users/API       | HTTPS Web UI, REST API         |
  | 22       | TCP      | Users           | SSH Proxy (session access)     |
  | 3389     | TCP      | Users           | RDP Proxy (session access)     |
  | 5900     | TCP      | Users           | VNC Proxy (session access)     |
  | 23       | TCP      | Users           | Telnet Proxy (legacy)          |
  | 80       | TCP      | Users           | HTTP redirect to HTTPS         |
  +----------+----------+-----------------+--------------------------------+

  Administrative Ports:
  +------------------------------------------------------------------------+
  | Port     | Protocol | Source          | Description                    |
  +----------+----------+-----------------+--------------------------------+
  | 22       | TCP      | Admin Network   | SSH access to WALLIX OS        |
  | 161      | UDP      | Monitoring      | SNMP polling                   |
  +----------+----------+-----------------+--------------------------------+

  Cluster Ports (HA Only):
  +------------------------------------------------------------------------+
  | Port     | Protocol | Source          | Description                    |
  +----------+----------+-----------------+--------------------------------+
  | 5404     | UDP      | Cluster Peer    | Corosync multicast             |
  | 5405     | UDP      | Cluster Peer    | Corosync unicast               |
  | 5406     | UDP      | Cluster Peer    | Corosync communication         |
  | 5432     | TCP      | Cluster Peer    | PostgreSQL replication         |
  | 2224     | TCP      | Cluster Peer    | Pacemaker PCSD                 |
  | 3121     | TCP      | Cluster Peer    | Pacemaker remote               |
  | 5403     | TCP      | Quorum Device   | Corosync Qdevice               |
  +----------+----------+-----------------+--------------------------------+

  --------------------------------------------------------------------------

  OUTBOUND PORTS (From WALLIX Bastion)
  ====================================

  Target Access Ports:
  +------------------------------------------------------------------------+
  | Port     | Protocol | Destination     | Description                    |
  +----------+----------+-----------------+--------------------------------+
  | 22       | TCP      | Targets         | SSH to Linux/Unix/Network      |
  | 3389     | TCP      | Targets         | RDP to Windows                 |
  | 5900+    | TCP      | Targets         | VNC to various systems         |
  | 23       | TCP      | Targets         | Telnet (legacy devices)        |
  | 5985     | TCP      | Targets         | WinRM HTTP                     |
  | 5986     | TCP      | Targets         | WinRM HTTPS                    |
  +----------+----------+-----------------+--------------------------------+

  Industrial Protocol Ports:
  +------------------------------------------------------------------------+
  | Port     | Protocol | Destination     | Description                    |
  +----------+----------+-----------------+--------------------------------+
  | 502      | TCP      | PLCs/RTUs       | Modbus TCP                     |
  | 4840     | TCP      | OPC Servers     | OPC UA                         |
  | 20000    | TCP      | RTUs/IEDs       | DNP3                           |
  | 44818    | TCP/UDP  | PLCs            | EtherNet/IP                    |
  | 2222     | TCP      | PLCs            | EtherNet/IP explicit           |
  | 102      | TCP      | PLCs/IEDs       | S7comm, IEC 61850 MMS          |
  | 47808    | UDP      | Controllers     | BACnet/IP                      |
  +----------+----------+-----------------+--------------------------------+

  Authentication Ports:
  +------------------------------------------------------------------------+
  | Port     | Protocol | Destination     | Description                    |
  +----------+----------+-----------------+--------------------------------+
  | 389      | TCP      | LDAP Server     | LDAP authentication            |
  | 636      | TCP      | LDAP Server     | LDAPS (LDAP over TLS)          |
  | 3268     | TCP      | Global Catalog  | AD Global Catalog              |
  | 3269     | TCP      | Global Catalog  | AD Global Catalog (SSL)        |
  | 88       | TCP/UDP  | KDC             | Kerberos authentication        |
  | 464      | TCP/UDP  | KDC             | Kerberos password change       |
  | 749      | TCP      | KDC             | Kerberos administration        |
  | 1812     | UDP      | RADIUS Server   | RADIUS authentication          |
  | 1813     | UDP      | RADIUS Server   | RADIUS accounting              |
  | 443      | TCP      | IdP             | OIDC/SAML authentication       |
  +----------+----------+-----------------+--------------------------------+

  Infrastructure Ports:
  +------------------------------------------------------------------------+
  | Port     | Protocol | Destination     | Description                    |
  +----------+----------+-----------------+--------------------------------+
  | 53       | UDP/TCP  | DNS Server      | DNS resolution                 |
  | 123      | UDP      | NTP Server      | Time synchronization           |
  | 514      | UDP      | Syslog Server   | Syslog (unencrypted)           |
  | 6514     | TCP      | Syslog Server   | Syslog over TLS                |
  | 25       | TCP      | SMTP Server     | Email notifications            |
  | 587      | TCP      | SMTP Server     | Email (STARTTLS)               |
  | 465      | TCP      | SMTP Server     | Email (SMTPS)                  |
  | 162      | UDP      | NMS             | SNMP traps                     |
  +----------+----------+-----------------+--------------------------------+

+==============================================================================+
```

### Port Verification Script

```bash
#!/bin/bash
# /opt/scripts/verify-ports.sh
# Verify all required ports are accessible

WALLIX_IP="10.1.0.10"
TARGETS="10.10.0.0/24"

echo "=== WALLIX Network Port Verification ==="
echo "Date: $(date)"
echo ""

# Function to test TCP port
test_tcp_port() {
    local host=$1
    local port=$2
    local desc=$3

    if timeout 3 bash -c "cat < /dev/null > /dev/tcp/$host/$port" 2>/dev/null; then
        echo "[OK]   TCP $host:$port - $desc"
        return 0
    else
        echo "[FAIL] TCP $host:$port - $desc"
        return 1
    fi
}

# Function to test UDP port
test_udp_port() {
    local host=$1
    local port=$2
    local desc=$3

    if nc -u -z -w3 $host $port 2>/dev/null; then
        echo "[OK]   UDP $host:$port - $desc"
        return 0
    else
        echo "[WARN] UDP $host:$port - $desc (may be filtered)"
        return 1
    fi
}

echo "--- Inbound Ports (local listening) ---"
for port in 22 80 443 3389 5900; do
    if ss -tln | grep -q ":$port "; then
        echo "[OK]   Port $port is listening"
    else
        echo "[FAIL] Port $port is NOT listening"
    fi
done

echo ""
echo "--- Authentication Services ---"
test_tcp_port "dc.company.com" 636 "LDAPS"
test_tcp_port "dc.company.com" 389 "LDAP"
test_tcp_port "dc.company.com" 88 "Kerberos"
test_udp_port "radius.company.com" 1812 "RADIUS"

echo ""
echo "--- Infrastructure Services ---"
test_udp_port "ntp.company.com" 123 "NTP"
test_tcp_port "dns.company.com" 53 "DNS (TCP)"
test_udp_port "dns.company.com" 53 "DNS (UDP)"
test_tcp_port "syslog.company.com" 6514 "Syslog TLS"
test_tcp_port "smtp.company.com" 587 "SMTP"

echo ""
echo "--- Target Connectivity Sample ---"
test_tcp_port "10.10.0.50" 22 "Linux Server SSH"
test_tcp_port "10.10.0.100" 3389 "Windows Server RDP"
test_tcp_port "10.10.0.200" 502 "PLC Modbus"

echo ""
echo "=== Verification Complete ==="
```

---

## Firewall Configuration

### Inbound Rules

```
+==============================================================================+
|                    FIREWALL - INBOUND RULES                                  |
+==============================================================================+

  MANAGEMENT INTERFACE RULES
  ==========================

  Allow from Corporate Network:
  +------------------------------------------------------------------------+
  | Order | Source          | Dest Port | Protocol | Action | Description  |
  +-------+-----------------+-----------+----------+--------+--------------+
  | 1     | 10.0.0.0/8      | 443       | TCP      | ALLOW  | Web UI/API   |
  | 2     | 10.0.0.0/8      | 22        | TCP      | ALLOW  | SSH Proxy    |
  | 3     | 10.0.0.0/8      | 3389      | TCP      | ALLOW  | RDP Proxy    |
  | 4     | 10.0.0.0/8      | 5900      | TCP      | ALLOW  | VNC Proxy    |
  | 5     | 10.0.0.0/8      | 80        | TCP      | ALLOW  | HTTP Redir   |
  +-------+-----------------+-----------+----------+--------+--------------+

  Allow from Admin Network:
  +------------------------------------------------------------------------+
  | Order | Source          | Dest Port | Protocol | Action | Description  |
  +-------+-----------------+-----------+----------+--------+--------------+
  | 10    | 10.0.100.0/24   | 22        | TCP      | ALLOW  | Admin SSH    |
  | 11    | 10.0.100.0/24   | 443       | TCP      | ALLOW  | Admin Web    |
  +-------+-----------------+-----------+----------+--------+--------------+

  Allow from Monitoring:
  +------------------------------------------------------------------------+
  | Order | Source          | Dest Port | Protocol | Action | Description  |
  +-------+-----------------+-----------+----------+--------+--------------+
  | 20    | 10.0.50.0/24    | 161       | UDP      | ALLOW  | SNMP         |
  +-------+-----------------+-----------+----------+--------+--------------+

  Allow from HA Peer:
  +------------------------------------------------------------------------+
  | Order | Source          | Dest Port | Protocol | Action | Description  |
  +-------+-----------------+-----------+----------+--------+--------------+
  | 30    | 192.168.1.11    | 5404-5406 | UDP      | ALLOW  | Corosync     |
  | 31    | 192.168.1.11    | 5432      | TCP      | ALLOW  | PostgreSQL   |
  | 32    | 192.168.1.11    | 2224      | TCP      | ALLOW  | Pacemaker    |
  | 33    | 192.168.1.11    | 3121      | TCP      | ALLOW  | Pacemaker    |
  +-------+-----------------+-----------+----------+--------+--------------+

  Default Policy:
  +------------------------------------------------------------------------+
  | 999   | ANY             | ANY       | ANY      | DROP   | Default deny |
  +-------+-----------------+-----------+----------+--------+--------------+

+==============================================================================+
```

### Outbound Rules

```
+==============================================================================+
|                    FIREWALL - OUTBOUND RULES                                 |
+==============================================================================+

  TARGET ACCESS RULES
  ===================

  +------------------------------------------------------------------------+
  | Order | Destination     | Dest Port | Protocol | Action | Description  |
  +-------+-----------------+-----------+----------+--------+--------------+
  | 1     | 10.10.0.0/16    | 22        | TCP      | ALLOW  | SSH targets  |
  | 2     | 10.10.0.0/16    | 3389      | TCP      | ALLOW  | RDP targets  |
  | 3     | 10.10.0.0/16    | 5900-5999 | TCP      | ALLOW  | VNC targets  |
  | 4     | 10.10.0.0/16    | 23        | TCP      | ALLOW  | Telnet       |
  | 5     | 10.10.0.0/16    | 5985-5986 | TCP      | ALLOW  | WinRM        |
  +-------+-----------------+-----------+----------+--------+--------------+

  INDUSTRIAL PROTOCOL RULES
  =========================

  +------------------------------------------------------------------------+
  | Order | Destination     | Dest Port | Protocol | Action | Description  |
  +-------+-----------------+-----------+----------+--------+--------------+
  | 10    | 10.10.0.0/16    | 502       | TCP      | ALLOW  | Modbus TCP   |
  | 11    | 10.10.0.0/16    | 4840      | TCP      | ALLOW  | OPC UA       |
  | 12    | 10.10.0.0/16    | 20000     | TCP      | ALLOW  | DNP3         |
  | 13    | 10.10.0.0/16    | 44818     | TCP      | ALLOW  | EtherNet/IP  |
  | 14    | 10.10.0.0/16    | 102       | TCP      | ALLOW  | S7/MMS       |
  +-------+-----------------+-----------+----------+--------+--------------+

  AUTHENTICATION RULES
  ====================

  +------------------------------------------------------------------------+
  | Order | Destination     | Dest Port | Protocol | Action | Description  |
  +-------+-----------------+-----------+----------+--------+--------------+
  | 20    | 10.0.1.2        | 389       | TCP      | ALLOW  | LDAP         |
  | 21    | 10.0.1.2        | 636       | TCP      | ALLOW  | LDAPS        |
  | 22    | 10.0.1.2        | 88        | TCP/UDP  | ALLOW  | Kerberos     |
  | 23    | 10.0.1.2        | 464       | TCP/UDP  | ALLOW  | Kerberos pwd |
  | 24    | 10.0.1.3        | 1812      | UDP      | ALLOW  | RADIUS auth  |
  | 25    | 10.0.1.3        | 1813      | UDP      | ALLOW  | RADIUS acct  |
  +-------+-----------------+-----------+----------+--------+--------------+

  INFRASTRUCTURE RULES
  ====================

  +------------------------------------------------------------------------+
  | Order | Destination     | Dest Port | Protocol | Action | Description  |
  +-------+-----------------+-----------+----------+--------+--------------+
  | 30    | 10.0.1.1        | 53        | UDP/TCP  | ALLOW  | DNS          |
  | 31    | ANY             | 123       | UDP      | ALLOW  | NTP          |
  | 32    | 10.0.1.5        | 6514      | TCP      | ALLOW  | Syslog TLS   |
  | 33    | 10.0.1.6        | 587       | TCP      | ALLOW  | SMTP         |
  | 34    | 10.0.1.7        | 162       | UDP      | ALLOW  | SNMP traps   |
  +-------+-----------------+-----------+----------+--------+--------------+

  HA CLUSTER RULES
  ================

  +------------------------------------------------------------------------+
  | Order | Destination     | Dest Port | Protocol | Action | Description  |
  +-------+-----------------+-----------+----------+--------+--------------+
  | 40    | 192.168.1.11    | 5404-5406 | UDP      | ALLOW  | Corosync     |
  | 41    | 192.168.1.11    | 5432      | TCP      | ALLOW  | PostgreSQL   |
  | 42    | 192.168.1.11    | 2224      | TCP      | ALLOW  | Pacemaker    |
  +-------+-----------------+-----------+----------+--------+--------------+

+==============================================================================+
```

### iptables Configuration Example

```bash
#!/bin/bash
# /etc/wallix/firewall-rules.sh
# WALLIX Bastion iptables firewall rules

# Flush existing rules
iptables -F
iptables -X

# Set default policies
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

# Allow loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Allow established connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# ============== INBOUND RULES ==============

# User Access (from Corporate: 10.0.0.0/8)
iptables -A INPUT -s 10.0.0.0/8 -p tcp --dport 443 -j ACCEPT -m comment --comment "HTTPS Web UI/API"
iptables -A INPUT -s 10.0.0.0/8 -p tcp --dport 22 -j ACCEPT -m comment --comment "SSH Proxy"
iptables -A INPUT -s 10.0.0.0/8 -p tcp --dport 3389 -j ACCEPT -m comment --comment "RDP Proxy"
iptables -A INPUT -s 10.0.0.0/8 -p tcp --dport 5900 -j ACCEPT -m comment --comment "VNC Proxy"
iptables -A INPUT -s 10.0.0.0/8 -p tcp --dport 80 -j ACCEPT -m comment --comment "HTTP redirect"

# Admin SSH (from Admin Network: 10.0.100.0/24)
iptables -A INPUT -s 10.0.100.0/24 -p tcp --dport 22 -j ACCEPT -m comment --comment "Admin SSH"

# SNMP Monitoring
iptables -A INPUT -s 10.0.50.0/24 -p udp --dport 161 -j ACCEPT -m comment --comment "SNMP"

# HA Cluster (from peer node)
iptables -A INPUT -s 192.168.1.11 -p udp --dport 5404:5406 -j ACCEPT -m comment --comment "Corosync"
iptables -A INPUT -s 192.168.1.11 -p tcp --dport 5432 -j ACCEPT -m comment --comment "PostgreSQL replication"
iptables -A INPUT -s 192.168.1.11 -p tcp --dport 2224 -j ACCEPT -m comment --comment "Pacemaker PCSD"
iptables -A INPUT -s 192.168.1.11 -p tcp --dport 3121 -j ACCEPT -m comment --comment "Pacemaker remote"

# ============== OUTBOUND RULES ==============

# Target Access (to OT Network: 10.10.0.0/16)
iptables -A OUTPUT -d 10.10.0.0/16 -p tcp --dport 22 -j ACCEPT -m comment --comment "SSH to targets"
iptables -A OUTPUT -d 10.10.0.0/16 -p tcp --dport 3389 -j ACCEPT -m comment --comment "RDP to targets"
iptables -A OUTPUT -d 10.10.0.0/16 -p tcp --dport 5900:5999 -j ACCEPT -m comment --comment "VNC to targets"
iptables -A OUTPUT -d 10.10.0.0/16 -p tcp --dport 23 -j ACCEPT -m comment --comment "Telnet to targets"
iptables -A OUTPUT -d 10.10.0.0/16 -p tcp --dport 5985:5986 -j ACCEPT -m comment --comment "WinRM"

# Industrial Protocols
iptables -A OUTPUT -d 10.10.0.0/16 -p tcp --dport 502 -j ACCEPT -m comment --comment "Modbus TCP"
iptables -A OUTPUT -d 10.10.0.0/16 -p tcp --dport 4840 -j ACCEPT -m comment --comment "OPC UA"
iptables -A OUTPUT -d 10.10.0.0/16 -p tcp --dport 20000 -j ACCEPT -m comment --comment "DNP3"
iptables -A OUTPUT -d 10.10.0.0/16 -p tcp --dport 102 -j ACCEPT -m comment --comment "S7/MMS"

# Authentication (LDAP/AD)
iptables -A OUTPUT -d 10.0.1.2 -p tcp --dport 389 -j ACCEPT -m comment --comment "LDAP"
iptables -A OUTPUT -d 10.0.1.2 -p tcp --dport 636 -j ACCEPT -m comment --comment "LDAPS"
iptables -A OUTPUT -d 10.0.1.2 -p tcp --dport 88 -j ACCEPT -m comment --comment "Kerberos"
iptables -A OUTPUT -d 10.0.1.2 -p udp --dport 88 -j ACCEPT -m comment --comment "Kerberos UDP"

# Infrastructure
iptables -A OUTPUT -d 10.0.1.1 -p udp --dport 53 -j ACCEPT -m comment --comment "DNS"
iptables -A OUTPUT -d 10.0.1.1 -p tcp --dport 53 -j ACCEPT -m comment --comment "DNS TCP"
iptables -A OUTPUT -p udp --dport 123 -j ACCEPT -m comment --comment "NTP"
iptables -A OUTPUT -d 10.0.1.5 -p tcp --dport 6514 -j ACCEPT -m comment --comment "Syslog TLS"
iptables -A OUTPUT -d 10.0.1.6 -p tcp --dport 587 -j ACCEPT -m comment --comment "SMTP"

# HA Cluster
iptables -A OUTPUT -d 192.168.1.11 -p udp --dport 5404:5406 -j ACCEPT -m comment --comment "Corosync"
iptables -A OUTPUT -d 192.168.1.11 -p tcp --dport 5432 -j ACCEPT -m comment --comment "PostgreSQL"
iptables -A OUTPUT -d 192.168.1.11 -p tcp --dport 2224 -j ACCEPT -m comment --comment "Pacemaker"

# Log dropped packets (rate limited)
iptables -A INPUT -m limit --limit 5/min -j LOG --log-prefix "WALLIX-INPUT-DROP: " --log-level 4
iptables -A OUTPUT -m limit --limit 5/min -j LOG --log-prefix "WALLIX-OUTPUT-DROP: " --log-level 4

# Save rules
iptables-save > /etc/iptables/rules.v4

echo "Firewall rules applied successfully"
```

### nftables Configuration Example

```bash
#!/usr/sbin/nft -f
# /etc/nftables.conf
# WALLIX Bastion nftables firewall rules

flush ruleset

table inet filter {
    chain input {
        type filter hook input priority 0; policy drop;

        # Allow loopback
        iif "lo" accept

        # Allow established connections
        ct state established,related accept

        # User Access (from Corporate)
        ip saddr 10.0.0.0/8 tcp dport { 80, 443, 22, 3389, 5900 } accept comment "User access"

        # Admin SSH
        ip saddr 10.0.100.0/24 tcp dport 22 accept comment "Admin SSH"

        # SNMP
        ip saddr 10.0.50.0/24 udp dport 161 accept comment "SNMP monitoring"

        # HA Cluster
        ip saddr 192.168.1.11 udp dport 5404-5406 accept comment "Corosync"
        ip saddr 192.168.1.11 tcp dport { 5432, 2224, 3121 } accept comment "Cluster services"

        # Log and drop
        limit rate 5/minute log prefix "WALLIX-INPUT-DROP: " drop
    }

    chain output {
        type filter hook output priority 0; policy drop;

        # Allow loopback
        oif "lo" accept

        # Allow established
        ct state established,related accept

        # Target Access (to OT Network)
        ip daddr 10.10.0.0/16 tcp dport { 22, 23, 3389, 5900-5999, 5985, 5986 } accept comment "Target access"
        ip daddr 10.10.0.0/16 tcp dport { 502, 4840, 20000, 102, 44818 } accept comment "Industrial protocols"

        # Authentication
        ip daddr 10.0.1.2 tcp dport { 389, 636, 88, 464 } accept comment "LDAP/Kerberos"
        ip daddr 10.0.1.2 udp dport { 88, 464 } accept comment "Kerberos UDP"

        # Infrastructure
        ip daddr 10.0.1.1 udp dport 53 accept comment "DNS"
        ip daddr 10.0.1.1 tcp dport 53 accept comment "DNS TCP"
        udp dport 123 accept comment "NTP"
        ip daddr 10.0.1.5 tcp dport 6514 accept comment "Syslog TLS"
        ip daddr 10.0.1.6 tcp dport 587 accept comment "SMTP"

        # HA Cluster
        ip daddr 192.168.1.11 udp dport 5404-5406 accept comment "Corosync"
        ip daddr 192.168.1.11 tcp dport { 5432, 2224 } accept comment "Cluster"

        # Log and drop
        limit rate 5/minute log prefix "WALLIX-OUTPUT-DROP: " drop
    }

    chain forward {
        type filter hook forward priority 0; policy drop;
    }
}
```

### firewalld Configuration Example

```bash
#!/bin/bash
# /opt/scripts/configure-firewalld.sh
# WALLIX Bastion firewalld configuration

# Create WALLIX zone
firewall-cmd --permanent --new-zone=wallix-users 2>/dev/null || true
firewall-cmd --permanent --new-zone=wallix-admin 2>/dev/null || true
firewall-cmd --permanent --new-zone=wallix-cluster 2>/dev/null || true

# Configure wallix-users zone (corporate access)
firewall-cmd --permanent --zone=wallix-users --add-source=10.0.0.0/8
firewall-cmd --permanent --zone=wallix-users --add-port=443/tcp
firewall-cmd --permanent --zone=wallix-users --add-port=22/tcp
firewall-cmd --permanent --zone=wallix-users --add-port=3389/tcp
firewall-cmd --permanent --zone=wallix-users --add-port=5900/tcp
firewall-cmd --permanent --zone=wallix-users --add-port=80/tcp

# Configure wallix-admin zone
firewall-cmd --permanent --zone=wallix-admin --add-source=10.0.100.0/24
firewall-cmd --permanent --zone=wallix-admin --add-port=22/tcp
firewall-cmd --permanent --zone=wallix-admin --add-port=443/tcp

# Configure wallix-cluster zone
firewall-cmd --permanent --zone=wallix-cluster --add-source=192.168.1.11
firewall-cmd --permanent --zone=wallix-cluster --add-port=5404-5406/udp
firewall-cmd --permanent --zone=wallix-cluster --add-port=5432/tcp
firewall-cmd --permanent --zone=wallix-cluster --add-port=2224/tcp
firewall-cmd --permanent --zone=wallix-cluster --add-port=3121/tcp

# Create direct rules for outbound (firewalld is primarily inbound)
# Note: For outbound control, iptables/nftables direct rules recommended

# Reload
firewall-cmd --reload

# Verify
echo "=== Firewalld Configuration ==="
firewall-cmd --list-all-zones | grep -A 20 "wallix"
```

---

## DNS Configuration

### Forward DNS Requirements

```
+==============================================================================+
|                    DNS CONFIGURATION                                          |
+==============================================================================+

  FORWARD DNS RECORDS
  ===================

  Required A Records:
  +------------------------------------------------------------------------+
  | Hostname                    | IP Address    | Purpose                   |
  +-----------------------------+---------------+---------------------------+
  | bastion.company.com         | 10.1.0.100    | VIP (HA) or primary       |
  | bastion-node1.company.com   | 10.1.0.10     | Node 1 management         |
  | bastion-node2.company.com   | 10.1.0.11     | Node 2 management         |
  +-----------------------------+---------------+---------------------------+

  CNAME Records (optional):
  +------------------------------------------------------------------------+
  | Alias                       | Target                   | Purpose        |
  +-----------------------------+--------------------------+----------------+
  | pam.company.com             | bastion.company.com      | User-friendly  |
  | wallix.company.com          | bastion.company.com      | Alternative    |
  +-----------------------------+--------------------------+----------------+

  --------------------------------------------------------------------------

  REVERSE DNS (PTR) RECORDS
  =========================

  Required PTR Records:
  +------------------------------------------------------------------------+
  | IP Address    | PTR Record                          | Purpose           |
  +---------------+-------------------------------------+-------------------+
  | 10.1.0.100    | bastion.company.com                 | VIP reverse       |
  | 10.1.0.10     | bastion-node1.company.com           | Node 1 reverse    |
  | 10.1.0.11     | bastion-node2.company.com           | Node 2 reverse    |
  +---------------+-------------------------------------+-------------------+

  Why PTR records matter:
  * SSH host key verification
  * Kerberos authentication
  * Logging/audit trail accuracy
  * Email authentication (SPF/DKIM)

  --------------------------------------------------------------------------

  DNS FOR HA VIRTUAL IP
  =====================

  Option 1: Short TTL A Record
  +------------------------------------------------------------------------+
  | bastion.company.com.  60  IN  A  10.1.0.100                            |
  |                                                                        |
  | Pros: Simple                                                           |
  | Cons: Failover limited by TTL propagation                              |
  +------------------------------------------------------------------------+

  Option 2: Multiple A Records (Round-Robin)
  +------------------------------------------------------------------------+
  | bastion.company.com.  60  IN  A  10.1.0.10                             |
  | bastion.company.com.  60  IN  A  10.1.0.11                             |
  |                                                                        |
  | Pros: Automatic load distribution                                      |
  | Cons: No health checking, may route to failed node                     |
  +------------------------------------------------------------------------+

  Option 3: DNS Load Balancer (GSLB)
  +------------------------------------------------------------------------+
  | Use external GSLB service (F5 DNS, AWS Route53, etc.)                  |
  |                                                                        |
  | Pros: Health checking, geographic routing                              |
  | Cons: Additional infrastructure                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  SSHFP RECORDS (SSH Fingerprint)
  ===============================

  Generate SSHFP records for WALLIX Bastion:
  +------------------------------------------------------------------------+
  | # On WALLIX Bastion, generate SSHFP records:                           |
  | ssh-keygen -r bastion.company.com                                      |
  |                                                                        |
  | # Output example:                                                      |
  | bastion.company.com IN SSHFP 1 1 abc123...                             |
  | bastion.company.com IN SSHFP 1 2 def456...                             |
  | bastion.company.com IN SSHFP 4 1 ghi789...                             |
  | bastion.company.com IN SSHFP 4 2 jkl012...                             |
  |                                                                        |
  | # Add these to DNS zone                                                |
  +------------------------------------------------------------------------+

  Client SSH configuration to use SSHFP:
  +------------------------------------------------------------------------+
  | # ~/.ssh/config                                                        |
  | Host bastion.company.com                                               |
  |     VerifyHostKeyDNS yes                                               |
  +------------------------------------------------------------------------+

+==============================================================================+
```

### DNS Configuration Commands

```bash
# Verify forward DNS resolution
nslookup bastion.company.com
dig bastion.company.com +short

# Verify reverse DNS resolution
nslookup 10.1.0.100
dig -x 10.1.0.100 +short

# Verify all DNS servers respond consistently
for ns in ns1.company.com ns2.company.com; do
    echo "=== $ns ==="
    dig @$ns bastion.company.com +short
done

# Test DNS resolution time
dig bastion.company.com | grep "Query time"

# Verify SSHFP records
dig bastion.company.com SSHFP +short

# Check DNS TTL
dig bastion.company.com | grep -A1 "ANSWER SECTION"
```

---

## NTP Configuration

### Time Synchronization Requirements

```
+==============================================================================+
|                    NTP CONFIGURATION                                          |
+==============================================================================+

  WHY TIME SYNC IS CRITICAL
  =========================

  Impact of Time Drift:
  +------------------------------------------------------------------------+
  | Component           | Time Drift Impact                                |
  +---------------------+--------------------------------------------------+
  | Kerberos Auth       | > 5 min drift = authentication failures          |
  | Certificate Valid.  | Incorrect time = cert validation failures        |
  | Session Recording   | Timestamps inaccurate, compliance issues         |
  | Log Correlation     | Cannot correlate events across systems           |
  | HA Cluster          | Split-brain risk, quorum issues                  |
  | Audit Trail         | Legal/compliance requirements not met            |
  +---------------------+--------------------------------------------------+

  Maximum Acceptable Drift:
  +------------------------------------------------------------------------+
  | Use Case              | Maximum Drift    | Recommended                  |
  +-----------------------+------------------+------------------------------+
  | Kerberos              | 5 minutes        | < 1 minute                   |
  | TLS Certificates      | Minutes          | < 1 minute                   |
  | HA Cluster            | Seconds          | < 1 second                   |
  | Audit/Compliance      | Seconds          | < 1 second                   |
  +-----------------------+------------------+------------------------------+

+==============================================================================+
```

### chrony Configuration

```bash
# /etc/chrony/chrony.conf
# WALLIX Bastion chrony configuration

# Primary NTP servers (internal recommended)
server ntp1.company.com iburst prefer
server ntp2.company.com iburst

# Fallback to public NTP pools
pool 0.debian.pool.ntp.org iburst
pool 1.debian.pool.ntp.org iburst

# Record the rate at which the system clock gains/losses time
driftfile /var/lib/chrony/drift

# Allow the system clock to be stepped during first sync
makestep 1.0 3

# Enable kernel synchronization of RTC
rtcsync

# Specify directory for log files
logdir /var/log/chrony

# Log measurements and statistics
log measurements statistics tracking

# Allow NTP queries from cluster peer (if serving time)
# allow 192.168.1.0/24

# Specify file containing keys for NTP authentication
keyfile /etc/chrony/chrony.keys

# Hardware timestamping (if supported)
# hwtimestamp eth0
```

### ntpd Configuration (Alternative)

```bash
# /etc/ntp.conf
# WALLIX Bastion NTP configuration

# Primary servers
server ntp1.company.com iburst prefer
server ntp2.company.com iburst

# Fallback pools
pool 0.debian.pool.ntp.org iburst
pool 1.debian.pool.ntp.org iburst

# Drift file
driftfile /var/lib/ntp/drift

# Access control
restrict default kod nomodify notrap nopeer noquery limited
restrict 127.0.0.1
restrict ::1

# Allow queries from cluster network
restrict 192.168.1.0 mask 255.255.255.0 nomodify notrap

# Statistics
statsdir /var/log/ntp/
statistics loopstats peerstats clockstats
filegen loopstats file loopstats type day enable
filegen peerstats file peerstats type day enable
filegen clockstats file clockstats type day enable

# Leap seconds file
leapfile /usr/share/zoneinfo/leap-seconds.list
```

### NTP Verification Commands

```bash
#!/bin/bash
# /opt/scripts/verify-ntp.sh
# Verify NTP synchronization

echo "=== NTP Synchronization Status ==="
echo "Date: $(date)"
echo ""

# Check if chrony or ntpd is running
if systemctl is-active --quiet chronyd; then
    echo "Time service: chrony"
    echo ""

    # Show current sources
    echo "--- NTP Sources ---"
    chronyc sources -v
    echo ""

    # Show tracking info
    echo "--- Time Tracking ---"
    chronyc tracking
    echo ""

    # Check synchronization status
    if chronyc tracking | grep -q "Leap status.*Normal"; then
        echo "[OK] Time is synchronized"
    else
        echo "[WARN] Time may not be synchronized"
    fi

elif systemctl is-active --quiet ntpd; then
    echo "Time service: ntpd"
    echo ""

    # Show peers
    echo "--- NTP Peers ---"
    ntpq -p
    echo ""

    # Check sync status
    if ntpq -c rv | grep -q "sync_ntp"; then
        echo "[OK] Time is synchronized"
    else
        echo "[WARN] Time may not be synchronized"
    fi

else
    echo "[FAIL] No NTP service running!"
    exit 1
fi

# Show current time offset
echo ""
echo "--- Time Comparison ---"
echo "Local time:  $(date)"
echo "UTC time:    $(date -u)"

# Check time against external source
if command -v ntpdate &> /dev/null; then
    echo "Offset from pool.ntp.org:"
    ntpdate -q pool.ntp.org 2>&1 | tail -1
fi

# Check hardware clock
echo ""
echo "--- Hardware Clock ---"
hwclock --show

echo ""
echo "=== Verification Complete ==="
```

---

## MTU Configuration

### MTU Discovery and Configuration

```
+==============================================================================+
|                    MTU CONFIGURATION                                          |
+==============================================================================+

  DEFAULT MTU VALUES
  ==================

  +------------------------------------------------------------------------+
  | Network Type          | Standard MTU | Jumbo MTU   | Notes             |
  +-----------------------+--------------+-------------+-------------------+
  | Ethernet              | 1500         | 9000        | Most common       |
  | PPPoE                 | 1492         | N/A         | DSL connections   |
  | VPN (IPsec)           | 1400-1438    | N/A         | Varies by config  |
  | VPN (OpenVPN)         | 1400-1450    | N/A         | Varies by config  |
  | VXLAN                 | 1450         | 8950        | Overlay networks  |
  | GRE                   | 1476         | N/A         | Tunnel overhead   |
  +-----------------------+--------------+-------------+-------------------+

  --------------------------------------------------------------------------

  MTU ISSUES AND SYMPTOMS
  =======================

  Common symptoms of MTU problems:
  * SSH connections hang after authentication
  * RDP sessions freeze or disconnect randomly
  * Large file transfers fail while small ones work
  * Web UI loads partially or times out
  * Sessions work for a while then fail

  --------------------------------------------------------------------------

  JUMBO FRAMES CONSIDERATIONS
  ===========================

  When to use Jumbo Frames (MTU 9000):
  +------------------------------------------------------------------------+
  | Use Case                              | Recommendation                 |
  +---------------------------------------+--------------------------------+
  | High-bandwidth RDP sessions           | Consider jumbo frames          |
  | Session recording to NAS              | Beneficial for performance     |
  | HA cluster interconnect               | Recommended for replication    |
  | User access over WAN                  | NOT recommended (stick to 1500)|
  | Cloud/VPN connections                 | NOT recommended                |
  +---------------------------------------+--------------------------------+

  Requirements for Jumbo Frames:
  * All devices in path must support same MTU
  * Switches/routers configured for jumbo
  * NIC drivers support jumbo frames
  * No intermediate devices that fragment

+==============================================================================+
```

### MTU Discovery Commands

```bash
#!/bin/bash
# /opt/scripts/mtu-discovery.sh
# Discover optimal MTU to target

TARGET=${1:-"10.10.0.1"}
INTERFACE=${2:-"eth0"}

echo "=== MTU Path Discovery to $TARGET ==="
echo "Date: $(date)"
echo ""

# Get current MTU
CURRENT_MTU=$(ip link show $INTERFACE | grep -oP 'mtu \K\d+')
echo "Current interface MTU: $CURRENT_MTU"
echo ""

# Function to test MTU
test_mtu() {
    local mtu=$1
    local payload=$((mtu - 28))  # 20 IP + 8 ICMP header

    if ping -c 1 -M do -s $payload $TARGET &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Binary search for optimal MTU
echo "Testing MTU path to $TARGET..."
low=576
high=$CURRENT_MTU
optimal=$low

while [ $low -le $high ]; do
    mid=$(( (low + high) / 2 ))

    if test_mtu $mid; then
        optimal=$mid
        low=$((mid + 1))
    else
        high=$((mid - 1))
    fi
done

echo ""
echo "Optimal MTU: $optimal"
echo ""

# Test common MTU values
echo "--- Common MTU Values Test ---"
for mtu in 1500 1492 1450 1400 1380; do
    if test_mtu $mtu; then
        echo "[OK]   MTU $mtu works"
    else
        echo "[FAIL] MTU $mtu blocked"
    fi
done

echo ""

# Recommendations
if [ $optimal -lt 1400 ]; then
    echo "[WARN] Low MTU detected. Possible VPN/tunnel in path."
    echo "       Consider configuring TCP MSS clamping."
elif [ $optimal -ge 1500 ]; then
    echo "[OK] Standard MTU supported."
fi

echo ""
echo "=== Discovery Complete ==="
```

### MTU Configuration

```bash
# Temporary MTU change (lost on reboot)
ip link set eth0 mtu 1400

# Permanent MTU configuration (Debian/Ubuntu with netplan)
# /etc/netplan/01-netcfg.yaml
network:
  version: 2
  ethernets:
    eth0:
      mtu: 1400
      addresses:
        - 10.1.0.10/24
      gateway4: 10.1.0.1

# Permanent MTU configuration (Debian with interfaces)
# /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 10.1.0.10
    netmask 255.255.255.0
    gateway 10.1.0.1
    mtu 1400

# Permanent MTU configuration (RHEL/CentOS with nmcli)
nmcli connection modify eth0 802-3-ethernet.mtu 1400
nmcli connection up eth0

# TCP MSS clamping (for VPN/tunnel issues)
iptables -t mangle -A POSTROUTING -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
```

---

## Network Validation Procedures

### Pre-Installation Checklist

```
+==============================================================================+
|                    PRE-INSTALLATION NETWORK CHECKLIST                        |
+==============================================================================+

  NETWORK INFRASTRUCTURE
  ======================

  [ ] IP addresses allocated for WALLIX nodes
      - Node 1 Management IP: ________________
      - Node 2 Management IP: ________________
      - Virtual IP (VIP):     ________________
      - Cluster IPs:          ________________

  [ ] DNS records created and verified
      - Forward (A) records resolve correctly
      - Reverse (PTR) records resolve correctly
      - SSHFP records (optional)

  [ ] NTP servers accessible
      - Primary NTP: ________________
      - Secondary NTP: ________________

  --------------------------------------------------------------------------

  FIREWALL RULES
  ==============

  Inbound Rules:
  [ ] Port 443/TCP from user networks
  [ ] Port 22/TCP from user networks (SSH proxy)
  [ ] Port 3389/TCP from user networks (RDP proxy)
  [ ] Port 22/TCP from admin network (OS admin)

  Outbound Rules:
  [ ] Ports 22,3389,5900/TCP to target networks
  [ ] Ports 389,636/TCP to LDAP servers
  [ ] Port 88/TCP+UDP to Kerberos KDC
  [ ] Port 53/UDP+TCP to DNS servers
  [ ] Port 123/UDP to NTP servers

  --------------------------------------------------------------------------

  CONNECTIVITY TESTS
  ==================

  [ ] Ping to default gateway
  [ ] Ping to DNS servers
  [ ] Ping to NTP servers
  [ ] Ping to LDAP servers
  [ ] Ping to sample targets

  [ ] TCP connectivity to LDAP (389/636)
  [ ] TCP connectivity to targets (22/3389)
  [ ] DNS resolution working

  --------------------------------------------------------------------------

  LATENCY VERIFICATION
  ====================

  [ ] Latency to LDAP server < 20ms
  [ ] Latency to targets < 50ms
  [ ] Latency between HA nodes < 5ms (if HA)

  --------------------------------------------------------------------------

  BANDWIDTH VERIFICATION
  ======================

  [ ] Minimum 100 Mbps to user network
  [ ] Minimum 100 Mbps to target network
  [ ] Minimum 1 Gbps between HA nodes (if HA)

+==============================================================================+
```

### Connectivity Test Script

```bash
#!/bin/bash
# /opt/scripts/network-validation.sh
# Comprehensive network validation for WALLIX Bastion

# Configuration - adjust these values
LDAP_SERVER="dc.company.com"
NTP_SERVER="ntp.company.com"
DNS_SERVER="10.0.1.1"
SAMPLE_TARGETS="10.10.0.50 10.10.0.100 10.10.0.200"
HA_PEER="192.168.1.11"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=============================================="
echo "  WALLIX Bastion Network Validation"
echo "=============================================="
echo "Date: $(date)"
echo ""

ERRORS=0
WARNINGS=0

# Function to test TCP port
test_tcp() {
    local host=$1
    local port=$2
    local timeout=${3:-5}

    if timeout $timeout bash -c "cat < /dev/null > /dev/tcp/$host/$port" 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Function to check latency
check_latency() {
    local host=$1
    local threshold=$2

    local latency=$(ping -c 3 -W 2 $host 2>/dev/null | grep 'avg' | awk -F'/' '{print $5}')

    if [ -z "$latency" ]; then
        echo "N/A"
        return 1
    fi

    echo "$latency ms"

    if (( $(echo "$latency > $threshold" | bc -l) )); then
        return 1
    fi
    return 0
}

# ============== DNS Tests ==============
echo "--- DNS Resolution Tests ---"

# Test DNS server connectivity
echo -n "DNS server connectivity ($DNS_SERVER): "
if test_tcp $DNS_SERVER 53; then
    echo -e "${GREEN}[OK]${NC}"
else
    echo -e "${RED}[FAIL]${NC}"
    ((ERRORS++))
fi

# Test resolution
echo -n "Forward DNS resolution: "
if nslookup $LDAP_SERVER $DNS_SERVER &>/dev/null; then
    echo -e "${GREEN}[OK]${NC}"
else
    echo -e "${RED}[FAIL]${NC}"
    ((ERRORS++))
fi

# Test reverse DNS
echo -n "Reverse DNS resolution: "
if nslookup $(hostname -I | awk '{print $1}') $DNS_SERVER &>/dev/null; then
    echo -e "${GREEN}[OK]${NC}"
else
    echo -e "${YELLOW}[WARN]${NC} PTR record may be missing"
    ((WARNINGS++))
fi

echo ""

# ============== NTP Tests ==============
echo "--- NTP Synchronization Tests ---"

echo -n "NTP server connectivity ($NTP_SERVER): "
if nc -u -z -w3 $NTP_SERVER 123 2>/dev/null; then
    echo -e "${GREEN}[OK]${NC}"
else
    echo -e "${RED}[FAIL]${NC}"
    ((ERRORS++))
fi

echo -n "Time synchronization status: "
if chronyc tracking 2>/dev/null | grep -q "Leap status.*Normal"; then
    echo -e "${GREEN}[OK]${NC}"
elif ntpq -c rv 2>/dev/null | grep -q "sync_ntp"; then
    echo -e "${GREEN}[OK]${NC}"
else
    echo -e "${YELLOW}[WARN]${NC} Time may not be synchronized"
    ((WARNINGS++))
fi

echo ""

# ============== LDAP Tests ==============
echo "--- LDAP Connectivity Tests ---"

echo -n "LDAP port 389 ($LDAP_SERVER): "
if test_tcp $LDAP_SERVER 389; then
    echo -e "${GREEN}[OK]${NC}"
else
    echo -e "${YELLOW}[WARN]${NC} LDAP not accessible"
    ((WARNINGS++))
fi

echo -n "LDAPS port 636 ($LDAP_SERVER): "
if test_tcp $LDAP_SERVER 636; then
    echo -e "${GREEN}[OK]${NC}"
else
    echo -e "${YELLOW}[WARN]${NC} LDAPS not accessible"
    ((WARNINGS++))
fi

echo -n "Kerberos port 88 ($LDAP_SERVER): "
if test_tcp $LDAP_SERVER 88; then
    echo -e "${GREEN}[OK]${NC}"
else
    echo -e "${YELLOW}[WARN]${NC} Kerberos not accessible"
    ((WARNINGS++))
fi

echo -n "LDAP server latency: "
latency=$(check_latency $LDAP_SERVER 20)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}$latency${NC}"
else
    echo -e "${YELLOW}$latency${NC} (threshold: 20ms)"
    ((WARNINGS++))
fi

echo ""

# ============== Target Tests ==============
echo "--- Target Connectivity Tests ---"

for target in $SAMPLE_TARGETS; do
    echo "Target: $target"

    echo -n "  SSH (22): "
    if test_tcp $target 22 3; then
        echo -e "${GREEN}[OK]${NC}"
    else
        echo -e "${YELLOW}[N/A]${NC}"
    fi

    echo -n "  RDP (3389): "
    if test_tcp $target 3389 3; then
        echo -e "${GREEN}[OK]${NC}"
    else
        echo -e "${YELLOW}[N/A]${NC}"
    fi

    echo -n "  Modbus (502): "
    if test_tcp $target 502 3; then
        echo -e "${GREEN}[OK]${NC}"
    else
        echo -e "${YELLOW}[N/A]${NC}"
    fi

    echo -n "  Latency: "
    latency=$(check_latency $target 50)
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}$latency${NC}"
    else
        echo -e "${YELLOW}$latency${NC}"
    fi
done

echo ""

# ============== HA Cluster Tests (if applicable) ==============
if [ -n "$HA_PEER" ]; then
    echo "--- HA Cluster Tests ---"

    echo -n "Cluster peer connectivity: "
    if ping -c 1 -W 2 $HA_PEER &>/dev/null; then
        echo -e "${GREEN}[OK]${NC}"
    else
        echo -e "${RED}[FAIL]${NC}"
        ((ERRORS++))
    fi

    echo -n "Corosync port 5405: "
    if nc -u -z -w3 $HA_PEER 5405 2>/dev/null; then
        echo -e "${GREEN}[OK]${NC}"
    else
        echo -e "${YELLOW}[WARN]${NC}"
        ((WARNINGS++))
    fi

    echo -n "PostgreSQL port 5432: "
    if test_tcp $HA_PEER 5432 3; then
        echo -e "${GREEN}[OK]${NC}"
    else
        echo -e "${RED}[FAIL]${NC}"
        ((ERRORS++))
    fi

    echo -n "Cluster latency: "
    latency=$(check_latency $HA_PEER 5)
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}$latency${NC}"
    else
        echo -e "${YELLOW}$latency${NC} (threshold: 5ms)"
        ((WARNINGS++))
    fi
fi

echo ""

# ============== Summary ==============
echo "=============================================="
echo "  Validation Summary"
echo "=============================================="
echo -e "Errors:   ${RED}$ERRORS${NC}"
echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"
echo ""

if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}VALIDATION FAILED - Please resolve errors before proceeding${NC}"
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}VALIDATION PASSED WITH WARNINGS - Review warnings${NC}"
    exit 0
else
    echo -e "${GREEN}VALIDATION PASSED - Network ready for installation${NC}"
    exit 0
fi
```

### Latency Testing

```bash
#!/bin/bash
# /opt/scripts/latency-test.sh
# Detailed latency testing

TARGET=${1:-"10.10.0.1"}
COUNT=${2:-100}

echo "=== Latency Test to $TARGET ==="
echo "Sending $COUNT pings..."
echo ""

# Run ping test
ping -c $COUNT $TARGET | tee /tmp/ping_results.txt

# Extract statistics
echo ""
echo "--- Statistics ---"
tail -2 /tmp/ping_results.txt

# Calculate percentiles
echo ""
echo "--- Percentile Analysis ---"
grep "time=" /tmp/ping_results.txt | \
    sed 's/.*time=\([0-9.]*\).*/\1/' | \
    sort -n | \
    awk '
    {
        a[NR] = $1
        sum += $1
    }
    END {
        p50 = int(NR * 0.5)
        p90 = int(NR * 0.9)
        p95 = int(NR * 0.95)
        p99 = int(NR * 0.99)

        printf "Samples: %d\n", NR
        printf "Average: %.2f ms\n", sum/NR
        printf "P50:     %.2f ms\n", a[p50]
        printf "P90:     %.2f ms\n", a[p90]
        printf "P95:     %.2f ms\n", a[p95]
        printf "P99:     %.2f ms\n", a[p99]
        printf "Min:     %.2f ms\n", a[1]
        printf "Max:     %.2f ms\n", a[NR]
    }'

rm /tmp/ping_results.txt
```

### Bandwidth Testing

```bash
#!/bin/bash
# /opt/scripts/bandwidth-test.sh
# Bandwidth testing using iperf3

SERVER=${1:-"10.1.0.1"}
DURATION=${2:-30}

echo "=== Bandwidth Test to $SERVER ==="
echo "Duration: $DURATION seconds"
echo ""

# Check if iperf3 is installed
if ! command -v iperf3 &> /dev/null; then
    echo "iperf3 not installed. Installing..."
    apt-get update && apt-get install -y iperf3
fi

# TCP bandwidth test
echo "--- TCP Bandwidth Test ---"
iperf3 -c $SERVER -t $DURATION -P 4

echo ""

# UDP bandwidth test
echo "--- UDP Bandwidth Test (100 Mbps target) ---"
iperf3 -c $SERVER -t $DURATION -u -b 100M

echo ""
echo "=== Test Complete ==="
```

### Certificate Connectivity Testing

```bash
#!/bin/bash
# /opt/scripts/cert-test.sh
# Test TLS/SSL connectivity and certificates

HOST=${1:-"ldaps.company.com"}
PORT=${2:-636}

echo "=== Certificate Connectivity Test ==="
echo "Host: $HOST:$PORT"
echo "Date: $(date)"
echo ""

# Test TLS connection
echo "--- TLS Connection Test ---"
if timeout 5 bash -c "echo | openssl s_client -connect $HOST:$PORT 2>/dev/null | head -5"; then
    echo "[OK] TLS connection successful"
else
    echo "[FAIL] TLS connection failed"
    exit 1
fi

echo ""

# Get certificate details
echo "--- Certificate Details ---"
echo | openssl s_client -connect $HOST:$PORT 2>/dev/null | \
    openssl x509 -noout -subject -issuer -dates -fingerprint

echo ""

# Check certificate chain
echo "--- Certificate Chain ---"
echo | openssl s_client -connect $HOST:$PORT -showcerts 2>/dev/null | \
    grep -E "(^Certificate chain|s:|i:)"

echo ""

# Verify certificate
echo "--- Certificate Verification ---"
if echo | openssl s_client -connect $HOST:$PORT -verify_return_error 2>/dev/null | grep -q "Verify return code: 0"; then
    echo "[OK] Certificate verification passed"
else
    echo "[WARN] Certificate verification issues detected"
    echo | openssl s_client -connect $HOST:$PORT 2>&1 | grep "Verify return code"
fi

echo ""

# Check expiration
echo "--- Expiration Check ---"
expiry=$(echo | openssl s_client -connect $HOST:$PORT 2>/dev/null | \
    openssl x509 -noout -enddate | cut -d= -f2)
expiry_epoch=$(date -d "$expiry" +%s)
now_epoch=$(date +%s)
days_left=$(( (expiry_epoch - now_epoch) / 86400 ))

echo "Expires: $expiry"
echo "Days until expiration: $days_left"

if [ $days_left -lt 30 ]; then
    echo "[WARN] Certificate expires in less than 30 days!"
elif [ $days_left -lt 90 ]; then
    echo "[INFO] Certificate expires in less than 90 days"
else
    echo "[OK] Certificate valid for $days_left days"
fi

echo ""
echo "=== Test Complete ==="
```

---

## HA Network Configuration

### Virtual IP Setup

```
+==============================================================================+
|                    HA VIRTUAL IP CONFIGURATION                               |
+==============================================================================+

  VIP CONFIGURATION WITH PACEMAKER
  ================================

  Resource Definition:
  +------------------------------------------------------------------------+
  | # Create VIP resource                                                  |
  | pcs resource create wallix-vip IPaddr2 \                               |
  |     ip=10.1.0.100 \                                                    |
  |     cidr_netmask=24 \                                                  |
  |     nic=eth0 \                                                         |
  |     op monitor interval=10s \                                          |
  |     --group wallix-group                                               |
  |                                                                        |
  | # Verify                                                               |
  | pcs resource status                                                    |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  MULTICAST VS UNICAST FOR COROSYNC
  =================================

  Multicast Configuration (Default):
  +------------------------------------------------------------------------+
  | # /etc/corosync/corosync.conf                                          |
  |                                                                        |
  | totem {                                                                |
  |     version: 2                                                         |
  |     cluster_name: wallix-cluster                                       |
  |     transport: udp                                                     |
  |     interface {                                                        |
  |         ringnumber: 0                                                  |
  |         bindnetaddr: 192.168.1.0                                       |
  |         mcastaddr: 239.255.1.1                                         |
  |         mcastport: 5405                                                |
  |     }                                                                  |
  | }                                                                      |
  +------------------------------------------------------------------------+

  Unicast Configuration (When multicast not available):
  +------------------------------------------------------------------------+
  | # /etc/corosync/corosync.conf                                          |
  |                                                                        |
  | totem {                                                                |
  |     version: 2                                                         |
  |     cluster_name: wallix-cluster                                       |
  |     transport: udpu                                                    |
  | }                                                                      |
  |                                                                        |
  | nodelist {                                                             |
  |     node {                                                             |
  |         ring0_addr: 192.168.1.10                                       |
  |         nodeid: 1                                                      |
  |     }                                                                  |
  |     node {                                                             |
  |         ring0_addr: 192.168.1.11                                       |
  |         nodeid: 2                                                      |
  |     }                                                                  |
  | }                                                                      |
  +------------------------------------------------------------------------+

  When to use Unicast:
  * Cloud environments (AWS, Azure, GCP)
  * Networks that block multicast
  * VXLAN/overlay networks
  * Cross-subnet cluster nodes

  --------------------------------------------------------------------------

  NETWORK REDUNDANCY
  ==================

  Dual-Ring Configuration:
  +------------------------------------------------------------------------+
  | # /etc/corosync/corosync.conf (dual ring)                              |
  |                                                                        |
  | totem {                                                                |
  |     version: 2                                                         |
  |     rrp_mode: passive                                                  |
  |                                                                        |
  |     interface {                                                        |
  |         ringnumber: 0                                                  |
  |         bindnetaddr: 192.168.1.0                                       |
  |         mcastport: 5405                                                |
  |     }                                                                  |
  |     interface {                                                        |
  |         ringnumber: 1                                                  |
  |         bindnetaddr: 192.168.2.0                                       |
  |         mcastport: 5407                                                |
  |     }                                                                  |
  | }                                                                      |
  |                                                                        |
  | # rrp_mode options:                                                    |
  | # - passive: Uses ring 1 only when ring 0 fails                        |
  | # - active: Uses both rings simultaneously (load sharing)              |
  +------------------------------------------------------------------------+

+==============================================================================+
```

---

## Multi-Site Network

### Site-to-Site Connectivity

```
+==============================================================================+
|                    MULTI-SITE NETWORK CONFIGURATION                          |
+==============================================================================+

  SITE CONNECTIVITY TOPOLOGY
  ==========================

                    Site A (Primary)                Site B (Secondary)
                    ================                ==================

                    +-------------+                 +-------------+
                    | WALLIX HA   |                 | WALLIX HA   |
                    | Cluster     |<--------------->| Cluster     |
                    | 10.1.0.0/24 |    WAN Link     | 10.2.0.0/24 |
                    +------+------+                 +------+------+
                           |                               |
                           |                               |
                    +------+------+                 +------+------+
                    | OT Network  |                 | OT Network  |
                    | 10.10.0.0/16|                 | 10.20.0.0/16|
                    +-------------+                 +-------------+

  --------------------------------------------------------------------------

  REPLICATION BANDWIDTH REQUIREMENTS
  ==================================

  +------------------------------------------------------------------------+
  | Replication Type    | Bandwidth Minimum | Recommended | Notes          |
  +---------------------+-------------------+-------------+----------------+
  | Config sync         | 1 Mbps            | 10 Mbps     | Intermittent   |
  | Database replication| 10 Mbps           | 100 Mbps    | Continuous     |
  | Session recordings  | 10 Mbps           | 100 Mbps    | Batch transfer |
  | Audit log sync      | 1 Mbps            | 10 Mbps     | Near real-time |
  +---------------------+-------------------+-------------+----------------+

  Calculation:
  +------------------------------------------------------------------------+
  | Data Type           | Volume/Day   | Peak Rate  | Bandwidth Needed     |
  +---------------------+--------------+------------+----------------------+
  | Config changes      | 10 MB        | 1 KB/s     | 10 Kbps              |
  | DB transactions     | 1 GB         | 100 KB/s   | 1 Mbps               |
  | Session recordings  | 100 GB       | 10 MB/s    | 80 Mbps (sync)       |
  | Audit logs          | 500 MB       | 50 KB/s    | 500 Kbps             |
  +---------------------+--------------+------------+----------------------+
  | TOTAL (peak)        |              |            | ~100 Mbps            |
  +---------------------+--------------+------------+----------------------+

  --------------------------------------------------------------------------

  LATENCY TOLERANCE
  =================

  +------------------------------------------------------------------------+
  | Replication Type    | Max Latency  | Impact of Higher Latency          |
  +---------------------+--------------+-----------------------------------+
  | Config sync         | 500 ms       | Delayed policy propagation        |
  | DB replication      | 100 ms       | Replication lag, potential data   |
  |                     |              | loss on failover                  |
  | Session recordings  | 1000 ms      | Delayed availability at DR site   |
  | Audit log sync      | 500 ms       | Delayed audit visibility          |
  +---------------------+--------------+-----------------------------------+

  Recommendation:
  * Site-to-site latency < 100 ms for synchronous operations
  * Site-to-site latency < 500 ms for asynchronous operations

  --------------------------------------------------------------------------

  SITE-TO-SITE FIREWALL RULES
  ===========================

  From Site A to Site B:
  +------------------------------------------------------------------------+
  | Port     | Protocol | Purpose                                          |
  +----------+----------+--------------------------------------------------+
  | 443      | TCP      | API replication, config sync                     |
  | 5432     | TCP      | PostgreSQL replication (async)                   |
  | 22       | TCP      | SSH for rsync (recordings)                       |
  +----------+----------+--------------------------------------------------+

  From Site B to Site A:
  +------------------------------------------------------------------------+
  | Port     | Protocol | Purpose                                          |
  +----------+----------+--------------------------------------------------+
  | 443      | TCP      | API replication, audit upload                    |
  | 22       | TCP      | SSH for rsync (recordings)                       |
  +----------+----------+--------------------------------------------------+

+==============================================================================+
```

---

## Troubleshooting

### Connection Timeout Issues

```
+==============================================================================+
|                    CONNECTION TIMEOUT TROUBLESHOOTING                        |
+==============================================================================+

  SYMPTOM: Connection times out to target
  =======================================

  Diagnostic Steps:
  +------------------------------------------------------------------------+
  | 1. Test basic connectivity:                                            |
  |    $ ping target-ip                                                    |
  |    $ traceroute target-ip                                              |
  |                                                                        |
  | 2. Test port connectivity:                                             |
  |    $ nc -zv target-ip 22                                               |
  |    $ nc -zv target-ip 3389                                             |
  |                                                                        |
  | 3. Check for firewall blocking:                                        |
  |    $ tcpdump -i eth0 host target-ip                                    |
  |    Look for SYN packets without SYN-ACK responses                      |
  |                                                                        |
  | 4. Check WALLIX logs:                                                  |
  |    $ tail -f /var/log/wallix/session-proxy.log                         |
  |    Look for timeout or connection refused messages                     |
  +------------------------------------------------------------------------+

  Common Causes and Solutions:
  +------------------------------------------------------------------------+
  | Cause                       | Solution                                 |
  +-----------------------------+------------------------------------------+
  | Firewall blocking           | Add firewall rule for traffic            |
  | Service not listening       | Start service on target                  |
  | Routing issue               | Check routes on WALLIX and network       |
  | MTU mismatch                | Adjust MTU or enable PMTUD                |
  | Network congestion          | Check bandwidth, QoS                     |
  | Target overloaded           | Check target resources                   |
  +-----------------------------+------------------------------------------+

  --------------------------------------------------------------------------

  SYMPTOM: Intermittent timeouts
  ==============================

  Diagnostic Steps:
  +------------------------------------------------------------------------+
  | 1. Monitor connection quality over time:                               |
  |    $ mtr --report-cycles 100 target-ip                                 |
  |                                                                        |
  | 2. Check for packet loss:                                              |
  |    $ ping -c 1000 target-ip | grep -E "(loss|time)"                    |
  |                                                                        |
  | 3. Monitor network interface:                                          |
  |    $ watch -n 1 "ethtool -S eth0 | grep -i error"                      |
  |                                                                        |
  | 4. Check for link flapping:                                            |
  |    $ dmesg | grep -i "link"                                            |
  +------------------------------------------------------------------------+

  Common Causes:
  +------------------------------------------------------------------------+
  | * Network link quality issues (cable, switch port)                     |
  | * Duplex mismatch                                                      |
  | * Switch/router overload                                               |
  | * ISP/WAN issues for remote targets                                    |
  | * Virtual network issues (in cloud/VM environments)                    |
  +------------------------------------------------------------------------+

+==============================================================================+
```

### Packet Loss Diagnosis

```bash
#!/bin/bash
# /opt/scripts/packet-loss-diagnosis.sh
# Diagnose packet loss issues

TARGET=${1:-"10.10.0.1"}
DURATION=${2:-300}

echo "=== Packet Loss Diagnosis ==="
echo "Target: $TARGET"
echo "Duration: $DURATION seconds"
echo ""

# Start packet capture in background
echo "Starting packet capture..."
tcpdump -i any host $TARGET -w /tmp/capture.pcap &
TCPDUMP_PID=$!

# Run ping test
echo "Running ping test..."
ping -c $DURATION -i 1 $TARGET > /tmp/ping_test.txt 2>&1 &
PING_PID=$!

# Monitor in real-time
echo ""
echo "Monitoring (press Ctrl+C to stop early)..."
sleep $DURATION

# Stop background processes
kill $TCPDUMP_PID $PING_PID 2>/dev/null

# Analyze results
echo ""
echo "--- Ping Statistics ---"
tail -5 /tmp/ping_test.txt

# Extract packet loss percentage
LOSS=$(grep "packet loss" /tmp/ping_test.txt | awk -F',' '{print $3}' | awk '{print $1}')
echo ""
echo "Packet Loss: $LOSS"

# Analyze capture for issues
echo ""
echo "--- Capture Analysis ---"
echo "Total packets: $(tcpdump -r /tmp/capture.pcap 2>/dev/null | wc -l)"
echo "ICMP requests: $(tcpdump -r /tmp/capture.pcap icmp 2>/dev/null | grep "request" | wc -l)"
echo "ICMP replies: $(tcpdump -r /tmp/capture.pcap icmp 2>/dev/null | grep "reply" | wc -l)"
echo "TCP retransmits: $(tcpdump -r /tmp/capture.pcap 2>/dev/null | grep -c "retransmit")"
echo "TCP RST: $(tcpdump -r /tmp/capture.pcap 2>/dev/null | grep -c "Flags \[R")"

# Check interface errors
echo ""
echo "--- Interface Errors ---"
for iface in $(ip link show | grep "^[0-9]" | awk -F: '{print $2}' | tr -d ' '); do
    errors=$(cat /sys/class/net/$iface/statistics/rx_errors 2>/dev/null)
    dropped=$(cat /sys/class/net/$iface/statistics/rx_dropped 2>/dev/null)
    if [ "$errors" != "0" ] || [ "$dropped" != "0" ]; then
        echo "$iface: errors=$errors dropped=$dropped"
    fi
done

# Cleanup
rm -f /tmp/capture.pcap /tmp/ping_test.txt

echo ""
echo "=== Diagnosis Complete ==="
```

### NAT/PAT Issues

```
+==============================================================================+
|                    NAT/PAT TROUBLESHOOTING                                   |
+==============================================================================+

  COMMON NAT ISSUES
  =================

  Issue: Source NAT causing authentication failures
  +------------------------------------------------------------------------+
  | Symptom: Kerberos or NTLM authentication fails                         |
  |                                                                        |
  | Cause: Source IP is NATed, target sees wrong IP                        |
  |                                                                        |
  | Solution:                                                              |
  | * Configure NAT exemption for WALLIX traffic                           |
  | * Use dedicated source IP for authentication                           |
  | * Configure identity-based NAT                                         |
  +------------------------------------------------------------------------+

  Issue: Port exhaustion
  +------------------------------------------------------------------------+
  | Symptom: Intermittent connection failures                              |
  |          "Cannot assign requested address" errors                      |
  |                                                                        |
  | Cause: Too many NAT translations, running out of ports                 |
  |                                                                        |
  | Solution:                                                              |
  | * Increase NAT port pool                                               |
  | * Reduce connection timeout on firewall                                |
  | * Use multiple NAT IPs                                                 |
  | * Enable port reuse                                                    |
  +------------------------------------------------------------------------+

  Issue: Asymmetric routing with NAT
  +------------------------------------------------------------------------+
  | Symptom: Connections establish but no data flows                       |
  |          One-way communication only                                    |
  |                                                                        |
  | Cause: Return traffic takes different path, NAT state not found        |
  |                                                                        |
  | Solution:                                                              |
  | * Ensure symmetric routing                                             |
  | * Configure stateful NAT with session sync                             |
  | * Use source routing if necessary                                      |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  DIAGNOSTIC COMMANDS
  ===================

  Check NAT translations (on firewall):
  +------------------------------------------------------------------------+
  | # Cisco ASA                                                            |
  | show xlate local <wallix-ip>                                           |
  | show conn address <wallix-ip>                                          |
  |                                                                        |
  | # Linux iptables                                                       |
  | conntrack -L -s <wallix-ip>                                            |
  | cat /proc/net/nf_conntrack | grep <wallix-ip>                          |
  |                                                                        |
  | # Check port usage                                                     |
  | ss -tn | awk '{print $4}' | cut -d: -f2 | sort | uniq -c | sort -rn    |
  +------------------------------------------------------------------------+

  Verify traffic path:
  +------------------------------------------------------------------------+
  | # From WALLIX, check outbound source IP                                |
  | curl -s ifconfig.me                                                    |
  | curl -s https://api.ipify.org                                          |
  |                                                                        |
  | # Check routing                                                        |
  | ip route get <target-ip>                                               |
  +------------------------------------------------------------------------+

+==============================================================================+
```

---

## Network Monitoring

### Continuous Validation Script

```bash
#!/bin/bash
# /opt/scripts/network-monitor.sh
# Continuous network monitoring for WALLIX Bastion

CONFIG_FILE="/etc/wallix/network-monitor.conf"
LOG_FILE="/var/log/wallix/network-monitor.log"
ALERT_EMAIL="admin@company.com"

# Load configuration
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Default values
LDAP_SERVER=${LDAP_SERVER:-"dc.company.com"}
NTP_SERVER=${NTP_SERVER:-"ntp.company.com"}
DNS_SERVER=${DNS_SERVER:-"10.0.1.1"}
HA_PEER=${HA_PEER:-""}
TARGETS=${TARGETS:-"10.10.0.50 10.10.0.100"}
CHECK_INTERVAL=${CHECK_INTERVAL:-60}
LATENCY_THRESHOLD=${LATENCY_THRESHOLD:-50}
LOSS_THRESHOLD=${LOSS_THRESHOLD:-1}

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

# Alert function
send_alert() {
    local subject="$1"
    local message="$2"

    log "ALERT: $subject - $message"

    if [ -n "$ALERT_EMAIL" ]; then
        echo "$message" | mail -s "[WALLIX] $subject" $ALERT_EMAIL
    fi

    # Also log to syslog
    logger -t wallix-network -p local0.alert "$subject: $message"
}

# Test function
check_host() {
    local host=$1
    local port=$2
    local name=$3

    # Test connectivity
    if ! timeout 5 bash -c "cat < /dev/null > /dev/tcp/$host/$port" 2>/dev/null; then
        send_alert "Connectivity Failure" "$name ($host:$port) is unreachable"
        return 1
    fi

    # Test latency
    local latency=$(ping -c 3 -W 2 $host 2>/dev/null | grep 'avg' | awk -F'/' '{print $5}')
    if [ -n "$latency" ]; then
        if (( $(echo "$latency > $LATENCY_THRESHOLD" | bc -l) )); then
            send_alert "High Latency" "$name ($host) latency ${latency}ms exceeds threshold ${LATENCY_THRESHOLD}ms"
        fi
    fi

    return 0
}

# Check packet loss
check_packet_loss() {
    local host=$1
    local name=$2

    local loss=$(ping -c 10 -W 2 $host 2>/dev/null | grep "packet loss" | awk -F',' '{print $3}' | awk '{print $1}' | tr -d '%')

    if [ -n "$loss" ] && [ "$loss" != "0" ]; then
        if (( $(echo "$loss > $LOSS_THRESHOLD" | bc -l) )); then
            send_alert "Packet Loss" "$name ($host) packet loss ${loss}% exceeds threshold ${LOSS_THRESHOLD}%"
        fi
    fi
}

# Main monitoring loop
log "Network monitor started"

while true; do
    # Check DNS
    check_host $DNS_SERVER 53 "DNS Server"

    # Check NTP
    if ! nc -u -z -w3 $NTP_SERVER 123 2>/dev/null; then
        send_alert "NTP Failure" "NTP server ($NTP_SERVER) is unreachable"
    fi

    # Check LDAP
    check_host $LDAP_SERVER 636 "LDAP Server"

    # Check HA peer
    if [ -n "$HA_PEER" ]; then
        check_host $HA_PEER 5432 "HA Cluster Peer"
        check_packet_loss $HA_PEER "HA Cluster"
    fi

    # Check sample targets
    for target in $TARGETS; do
        check_host $target 22 "Target $target"
    done

    # Sleep until next check
    sleep $CHECK_INTERVAL
done
```

### Alert Thresholds Configuration

```bash
# /etc/wallix/network-monitor.conf
# Network monitoring configuration

# Infrastructure servers
LDAP_SERVER="dc.company.com"
NTP_SERVER="ntp.company.com"
DNS_SERVER="10.0.1.1"

# HA peer (empty if standalone)
HA_PEER="192.168.1.11"

# Sample targets to monitor
TARGETS="10.10.0.50 10.10.0.100 10.10.0.200"

# Check interval in seconds
CHECK_INTERVAL=60

# Alert thresholds
LATENCY_THRESHOLD=50      # ms
LOSS_THRESHOLD=1          # percent
JITTER_THRESHOLD=10       # ms

# Alerting
ALERT_EMAIL="pam-admin@company.com"
SYSLOG_FACILITY="local0"
SNMP_TRAP_HOST="nms.company.com"
```

### Prometheus Metrics Export

```bash
#!/bin/bash
# /opt/scripts/network-metrics-exporter.sh
# Export network metrics in Prometheus format

METRICS_FILE="/var/lib/prometheus/wallix-network.prom"
TARGETS="dc.company.com ntp.company.com 10.10.0.50 10.10.0.100"

# Create temporary file
TEMP_FILE=$(mktemp)

# Header
echo "# HELP wallix_network_latency_ms Network latency to target in milliseconds" >> $TEMP_FILE
echo "# TYPE wallix_network_latency_ms gauge" >> $TEMP_FILE

echo "# HELP wallix_network_reachable Target reachability (1=up, 0=down)" >> $TEMP_FILE
echo "# TYPE wallix_network_reachable gauge" >> $TEMP_FILE

echo "# HELP wallix_network_packet_loss_percent Packet loss percentage" >> $TEMP_FILE
echo "# TYPE wallix_network_packet_loss_percent gauge" >> $TEMP_FILE

# Collect metrics for each target
for target in $TARGETS; do
    # Test reachability
    if ping -c 1 -W 2 $target &>/dev/null; then
        reachable=1
    else
        reachable=0
    fi
    echo "wallix_network_reachable{target=\"$target\"} $reachable" >> $TEMP_FILE

    # Measure latency
    latency=$(ping -c 3 -W 2 $target 2>/dev/null | grep 'avg' | awk -F'/' '{print $5}')
    if [ -n "$latency" ]; then
        echo "wallix_network_latency_ms{target=\"$target\"} $latency" >> $TEMP_FILE
    fi

    # Measure packet loss
    loss=$(ping -c 10 -W 2 $target 2>/dev/null | grep "packet loss" | awk -F',' '{print $3}' | awk '{print $1}' | tr -d '%')
    if [ -n "$loss" ]; then
        echo "wallix_network_packet_loss_percent{target=\"$target\"} $loss" >> $TEMP_FILE
    fi
done

# Port check metrics
echo "# HELP wallix_port_open Port open status (1=open, 0=closed)" >> $TEMP_FILE
echo "# TYPE wallix_port_open gauge" >> $TEMP_FILE

# Check common ports
check_port() {
    local host=$1
    local port=$2
    local proto=${3:-tcp}

    if [ "$proto" = "tcp" ]; then
        if timeout 2 bash -c "cat < /dev/null > /dev/tcp/$host/$port" 2>/dev/null; then
            echo "wallix_port_open{host=\"$host\",port=\"$port\",protocol=\"$proto\"} 1" >> $TEMP_FILE
        else
            echo "wallix_port_open{host=\"$host\",port=\"$port\",protocol=\"$proto\"} 0" >> $TEMP_FILE
        fi
    fi
}

check_port "dc.company.com" 636 tcp
check_port "dc.company.com" 88 tcp
check_port "10.10.0.50" 22 tcp
check_port "10.10.0.100" 3389 tcp

# Move temp file to final location
mv $TEMP_FILE $METRICS_FILE
chmod 644 $METRICS_FILE
```

---

## Quick Reference

### Essential Commands

```bash
# Test TCP connectivity
nc -zv host port
timeout 5 bash -c "cat < /dev/null > /dev/tcp/host/port"

# Test UDP connectivity
nc -u -z -w3 host port

# DNS resolution
nslookup hostname
dig hostname +short
dig -x ip_address +short

# Latency test
ping -c 10 host
mtr --report host

# MTU discovery
ping -c 1 -M do -s 1472 host

# Port scanning
nmap -p 22,443,3389 host

# Capture traffic
tcpdump -i eth0 host target
tcpdump -i eth0 port 22

# Check routes
ip route get destination
traceroute destination

# Check listening ports
ss -tlnp
netstat -tlnp

# Check connections
ss -tn
ss -tn state established

# Check interface errors
ethtool -S eth0 | grep -i error
cat /sys/class/net/eth0/statistics/*errors
```

---

## External References

- WALLIX Documentation Portal: https://pam.wallix.one/documentation
- WALLIX Admin Guide: https://pam.wallix.one/documentation/admin-doc/bastion_en_administration_guide.pdf
- Pacemaker Documentation: https://clusterlabs.org/pacemaker/doc/
- Corosync Documentation: https://corosync.github.io/corosync/
- PostgreSQL Replication: https://www.postgresql.org/docs/current/high-availability.html

---

## Version Information

| Item | Value |
|------|-------|
| Document Version | 1.0 |
| WALLIX Bastion Version | 12.1.x |
| Last Updated | January 2026 |

---

## See Also

**Related Sections:**
- [46 - Fortigate Integration](../46-fortigate-integration/README.md) - Firewall rules and configurations
- [32 - Load Balancer](../32-load-balancer/README.md) - Health checks and load balancing
- [19 - System Requirements](../19-system-requirements/README.md) - Network requirements

**Related Documentation:**
- [Install Guide: Network Validation](/install/08-validation-testing.md) - Deployment validation
- [Install Guide: Architecture Diagrams](/install/09-architecture-diagrams.md) - Network topology

**Official Resources:**
- [WALLIX Documentation](https://pam.wallix.one/documentation)

---

## Next Steps

Continue to [48 - Security Hardening](../48-security-hardening/README.md) for post-installation security configuration.
