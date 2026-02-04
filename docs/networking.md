# WALLIX Bastion Networking & Ports Reference

## Document Information

| Property | Value |
|----------|-------|
| **Purpose** | Comprehensive networking requirements for WALLIX Bastion in client professional environments |
| **Version** | Aligned with WALLIX Bastion 12.1.x |
| **Last Updated** | February 2026 |
| **Target Systems** | Windows Server 2022, RHEL 9/10 |
| **Deployment Type** | On-premises only (bare metal and VMs) |

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Complete Port Reference Matrix](#complete-port-reference-matrix)
3. [Port Summary Tables](#port-summary-tables)
4. [FortiAuthenticator HA Configuration](#fortiauthenticator-ha-configuration)
5. [Firewall Rules & Zone Configuration](#firewall-rules--zone-configuration)
6. [Troubleshooting Port Matrix](#troubleshooting-port-matrix)
7. [Network Validation Checklist](#network-validation-checklist)
8. [Best Practices](#best-practices)
9. [Related Documentation References](#related-documentation-references)

---

## Architecture Overview

### 4-Site Synchronized Architecture (Single CPD)

```
+===============================================================================+
|  WALLIX BASTION 4-SITE ARCHITECTURE                                           |
+===============================================================================+
|                                                                               |
|                          +---------------------+                              |
|                          | FortiAuthenticator  |                              |
|                          |   (MFA Server)      |                              |
|                          |   10.10.0.60        |                              |
|                          +----------+----------+                              |
|                                     | RADIUS 1812/1813                         |
|          +--------------+----------+----------+----------+                    |
|          |              |          |          |          |                    |
|    +-----v-----+  +-----v-----+  +----v-----+  +-----v-----+                 |
|    | Fortigate |  | Fortigate |  | Fortigate|  | Fortigate |                 |
|    |  Site 1   |  |  Site 2   |  |  Site 3  |  |  Site 4   |                 |
|    +-----+-----+  +-----+-----+  +-----+----+  +-----+-----+                 |
|          |              |              |             |                        |
|    +-----v-----+  +-----v-----+  +-----v----+  +-----v-----+                 |
|    | HAProxy   |  | HAProxy   |  | HAProxy  |  | HAProxy   |                 |
|    | HA Pair   |  | HA Pair   |  | HA Pair  |  | HA Pair   |                 |
|    +-----+-----+  +-----+-----+  +-----+----+  +-----+-----+                 |
|          |              |              |             |                        |
|    +-----v-----+  +-----v-----+  +-----v----+  +-----v-----+                 |
|    | WALLIX    |  | WALLIX    |  | WALLIX   |  | WALLIX    |                 |
|    | Bastion   |  | Bastion   |  | Bastion  |  | Bastion   |                 |
|    | HA Pair   |  | HA Pair   |  | HA Pair  |  | HA Pair   |                 |
|    +-----+-----+  +-----+-----+  +-----+----+  +-----+-----+                 |
|          |              |              |             |                        |
|    +-----v-----+  +-----v-----+  +-----v----+  +-----v-----+                 |
|    | WALLIX    |  | WALLIX    |  | WALLIX   |  | WALLIX    |                 |
|    |   RDS     |  |   RDS     |  |   RDS    |  |   RDS     |                 |
|    +-----------+  +-----------+  +----------+  +-----------+                 |
|                                                                               |
|  All sites synchronized with cross-site replication (443/tcp, 3306/tcp)      |
|                                                                               |
+===============================================================================+
```

### Single Site Network Flow Detail

```
+===============================================================================+
|  SINGLE SITE - COMPLETE NETWORK FLOW                                          |
+===============================================================================+
|                                                                               |
|  INTERNET/WAN                                                                 |
|       |                                                                       |
|  +----v----------------------+                                                |
|  |    FORTIGATE FIREWALL     |  SSL VPN: 443/tcp                             |
|  |   (Perimeter Defense)     |  Admin: 10443/tcp                             |
|  |      10.10.1.1            |  RADIUS Proxy to FortiAuth                    |
|  +-----------+---------------+                                                |
|              |                                                                |
|  +-----------v---------------+      +--------------------+                   |
|  |    HAProxy-1 (Primary)    |<---->|    HAProxy-2       |                   |
|  |      10.10.1.5            | VRRP |      10.10.1.6     |                   |
|  |  VIP: 10.10.1.100         |112ip |                    |                   |
|  +-----------+---------------+      +--------------------+                   |
|              |                                                                |
|              | HTTPS:443  SSH:22  RDP:3389                                    |
|              |                                                                |
|  +-----------v---------------+      +--------------------+                   |
|  |  WALLIX Bastion-1         |<---->|  WALLIX Bastion-2  |                   |
|  |      10.10.1.11           |      |      10.10.1.12    |                   |
|  |                           |      |                    |                   |
|  |  MariaDB Replication: 3306/tcp (bi-directional)      |                   |
|  |  Corosync HA: 5404-5406/udp                           |                   |
|  |  PCSD: 2224/tcp, 3121/tcp                             |                   |
|  +-----------+---------------+      +--------------------+                   |
|              |                           |                                    |
|              +------------+--------------+                                    |
|                           |                                                   |
|                  +--------v---------+                                         |
|                  | FortiAuthenticator |                                       |
|                  |    10.10.0.60      |                                       |
|                  | RADIUS: 1812/1813  |                                       |
|                  +--------+-----------+                                       |
|                           |                                                   |
|                           | LDAPS: 636/tcp                                    |
|                           |                                                   |
|                  +--------v---------+                                         |
|                  |  Active Directory|                                         |
|                  |    10.10.0.10     |                                        |
|                  +------------------+                                         |
|                                                                               |
|  +-----------+---------------+      +--------------------+                   |
|  |    WALLIX RDS             |      | Target Systems     |                   |
|  |      10.10.1.30           |      |                    |                   |
|  | (Windows Session Manager) |      | Windows 2022: RDP  |                   |
|  +-----------+---------------+      | RHEL 9/10: SSH     |                   |
|              |                      +--------------------+                   |
|              |                           |                                    |
|              +------------+--------------+                                    |
|                           |                                                   |
|                  +--------v---------+                                         |
|                  |  Target Servers  |                                         |
|                  |                  |                                         |
|                  | Windows: 3389/tcp (RDP), 5985-5986/tcp (WinRM)           |
|                  | RHEL: 22/tcp (SSH)                                        |
|                  +------------------+                                         |
|                                                                               |
+===============================================================================+
```

### Network Segmentation Zones

```
+===============================================================================+
|  NETWORK ZONE MODEL                                                           |
+===============================================================================+
|                                                                               |
|  +-------------------------+                                                  |
|  | EXTERNAL ZONE           |                                                  |
|  | (Internet/WAN)          |                                                  |
|  | Access: SSL VPN only    |                                                  |
|  +------------+------------+                                                  |
|               |                                                               |
|               | Fortigate Firewall                                            |
|               v                                                               |
|  +-------------------------+                                                  |
|  | DMZ ZONE                |                                                  |
|  | HAProxy Load Balancers  |                                                  |
|  | 10.10.1.0/24            |                                                  |
|  +------------+------------+                                                  |
|               |                                                               |
|               | Internal Firewall/ACL                                         |
|               v                                                               |
|  +-------------------------+                                                  |
|  | MANAGEMENT ZONE         |                                                  |
|  | WALLIX Bastion Nodes    |                                                  |
|  | 10.10.1.0/24            |                                                  |
|  +------------+------------+                                                  |
|               |                                                               |
|               v                                                               |
|  +-------------------------+                                                  |
|  | AUTHENTICATION ZONE     |                                                  |
|  | FortiAuthenticator, AD  |                                                  |
|  | 10.10.0.0/24            |                                                  |
|  +-------------------------+                                                  |
|               |                                                               |
|               v                                                               |
|  +-------------------------+                                                  |
|  | TARGET ZONE             |                                                  |
|  | Windows & RHEL Servers  |                                                  |
|  | 10.10.2.0/24            |                                                  |
|  +-------------------------+                                                  |
|                                                                               |
+===============================================================================+
```

---

## Complete Port Reference Matrix

### 3.1 User Access Ports (Inbound to WALLIX)

```
+===============================================================================+
|  USER ACCESS PORTS (Inbound to WALLIX Bastion)                               |
+===============================================================================+
|                                                                               |
|  Port    Protocol   Service          Direction    Description                |
|  ----    --------   -------          ---------    -----------                |
|  22      TCP        SSH Proxy        Inbound      SSH session access         |
|  80      TCP        HTTP             Inbound      Redirect to HTTPS          |
|  443     TCP        HTTPS            Inbound      Web UI, REST API, sync     |
|  3389    TCP        RDP Proxy        Inbound      RDP session access         |
|  5900    TCP        VNC Proxy        Inbound      VNC session access (opt)   |
|                                                                               |
+===============================================================================+
```

### 3.2 WALLIX Access Manager Ports (Inbound to WALLIX)

```
+===============================================================================+
|  WALLIX ACCESS MANAGER PORTS (Inbound to WALLIX Bastion)                     |
+===============================================================================+
|                                                                               |
|  Port    Protocol   Service          Direction    Description                |
|  ----    --------   -------          ---------    -----------                |
|  443     TCP        HTTPS            Inbound      Access Manager API/UI      |
|  22      TCP        SSH              Inbound      Access Manager connections |
|  3389    TCP        RDP              Inbound      Access Manager RDP proxy   |
|  5900    TCP        VNC              Inbound      Access Manager VNC proxy   |
|                                                                               |
|  Note: WALLIX Access Manager provides web-based access to WALLIX Bastion     |
|  These ports must be accessible from Access Manager servers                  |
|                                                                               |
+===============================================================================+
```

### 3.3 Target Access Ports (Outbound from WALLIX)

```
+===============================================================================+
|  TARGET ACCESS PORTS (Outbound from WALLIX to Target Systems)                |
+===============================================================================+
|                                                                               |
|  WINDOWS SERVER 2022 TARGETS                                                  |
|  ===========================                                                  |
|  Port    Protocol   Service          Direction    Description                |
|  ----    --------   -------          ---------    -----------                |
|  3389    TCP        RDP              Outbound     Remote Desktop sessions    |
|  5985    TCP        WinRM HTTP       Outbound     Password rotation          |
|  5986    TCP        WinRM HTTPS      Outbound     Password rotation (SSL)    |
|                                                                               |
|  RED HAT (RHEL 9/10) TARGETS                                                  |
|  ============================                                                 |
|  Port    Protocol   Service          Direction    Description                |
|  ----    --------   -------          ---------    -----------                |
|  22      TCP        SSH              Outbound     SSH sessions, mgmt         |
|                                                                               |
|  LEGACY PROTOCOLS (Discouraged)                                               |
|  ===============================                                              |
|  Port    Protocol   Service          Direction    Description                |
|  ----    --------   -------          ---------    -----------                |
|  23      TCP        Telnet           Outbound     Legacy (not recommended)   |
|                                                                               |
+===============================================================================+
```

### 3.4 FortiAuthenticator MFA Ports

```
+===============================================================================+
|  FORTIAUTHENTICATOR MFA PORTS                                                 |
+===============================================================================+
|                                                                               |
|  FORTIAUTHENTICATOR PRIMARY SERVER                                            |
|  ==================================                                           |
|  Port    Protocol   Service          Direction    Description                |
|  ----    --------   -------          ---------    -----------                |
|  1812    UDP        RADIUS Auth      Outbound     WALLIX → FortiAuth Auth    |
|  1813    UDP        RADIUS Acct      Outbound     WALLIX → FortiAuth Acct    |
|  8443    TCP        FortiAuth Admin  Inbound      Admin UI access            |
|                                                                               |
|  FORTIAUTHENTICATOR TO ACTIVE DIRECTORY                                       |
|  =======================================                                      |
|  Port    Protocol   Service          Direction    Description                |
|  ----    --------   -------          ---------    -----------                |
|  389     TCP        LDAP             Outbound     FortiAuth → AD user sync   |
|  636     TCP        LDAPS            Outbound     FortiAuth → AD (SSL)       |
|                                                                               |
|  Note: FortiAuthenticator serves as central MFA provider for all sites        |
|                                                                               |
+===============================================================================+
```

### 3.5 Fortigate Firewall Ports

```
+===============================================================================+
|  FORTIGATE FIREWALL PORTS                                                     |
+===============================================================================+
|                                                                               |
|  FORTIGATE EXTERNAL ACCESS                                                    |
|  =========================                                                    |
|  Port    Protocol   Service          Direction    Description                |
|  ----    --------   -------          ---------    -----------                |
|  443     TCP        SSL VPN          Inbound      SSL VPN endpoint           |
|  10443   TCP        Admin UI         Inbound      Fortigate management       |
|                                                                               |
|  FORTIGATE RADIUS PROXY                                                       |
|  =======================                                                      |
|  Port    Protocol   Service          Direction    Description                |
|  ----    --------   -------          ---------    -----------                |
|  1812    UDP        RADIUS Auth      Outbound     Fortigate → FortiAuth      |
|  1813    UDP        RADIUS Acct      Outbound     Fortigate → FortiAuth      |
|                                                                               |
+===============================================================================+
```

### 3.6 HA Cluster Ports (Internal - Between WALLIX Nodes)

```
+===============================================================================+
|  HA CLUSTER PORTS (WALLIX Node-to-Node Communication)                        |
+===============================================================================+
|                                                                               |
|  PACEMAKER/COROSYNC CLUSTER                                                   |
|  ===========================                                                  |
|  Port    Protocol   Service          Direction    Description                |
|  ----    --------   -------          ---------    -----------                |
|  2224    TCP        PCSD             Bidirect     Pacemaker web UI/API       |
|  3121    TCP        Pacemaker        Bidirect     Pacemaker remote           |
|  5403    TCP        Corosync QNet    Bidirect     Quorum device              |
|  5404    UDP        Corosync         Bidirect     Cluster multicast          |
|  5405    UDP        Corosync         Bidirect     Cluster unicast            |
|  5406    UDP        Corosync         Bidirect     Cluster communication      |
|                                                                               |
|  DATABASE REPLICATION                                                         |
|  =====================                                                        |
|  Port    Protocol   Service          Direction    Description                |
|  ----    --------   -------          ---------    -----------                |
|  3306    TCP        MariaDB          Bidirect     Streaming replication      |
|                                                                               |
|  Note: These ports must ONLY be accessible between cluster nodes              |
|  Isolate on dedicated VLAN for security                                      |
|                                                                               |
+===============================================================================+
```

### 3.7 HAProxy Load Balancer Ports

```
+===============================================================================+
|  HAPROXY LOAD BALANCER PORTS                                                  |
+===============================================================================+
|                                                                               |
|  FRONTEND PORTS (User-Facing)                                                 |
|  =============================                                                |
|  Port    Protocol   Service          Direction    Description                |
|  ----    --------   -------          ---------    -----------                |
|  443     TCP        HTTPS            Inbound      Web UI, API (LB VIP)       |
|  22      TCP        SSH              Inbound      SSH Proxy (LB VIP)         |
|  3389    TCP        RDP              Inbound      RDP Proxy (LB VIP)         |
|                                                                               |
|  BACKEND HEALTH CHECKS                                                        |
|  ======================                                                       |
|  Port    Protocol   Service          Direction    Description                |
|  ----    --------   -------          ---------    -----------                |
|  443     TCP        HTTPS            Outbound     Health check to WALLIX     |
|  22      TCP        SSH              Outbound     SSH connectivity check     |
|                                                                               |
|  HAPROXY HA COMMUNICATION                                                     |
|  =========================                                                    |
|  Protocol  Service          Direction    Description                         |
|  --------  -------          ---------    -----------                         |
|  112/IP    VRRP             Bidirect     Keepalived heartbeat                |
|                                           (IP protocol 112, not TCP/UDP)     |
|                                                                               |
|  HAPROXY STATS (Optional)                                                     |
|  =========================                                                    |
|  Port    Protocol   Service          Direction    Description                |
|  ----    --------   -------          ---------    -----------                |
|  8404    TCP        Stats UI         Inbound      HAProxy statistics         |
|                                                                               |
+===============================================================================+
```

### 3.8 Authentication Ports (LDAP/AD)

```
+===============================================================================+
|  AUTHENTICATION PORTS (WALLIX to Active Directory/LDAP)                      |
+===============================================================================+
|                                                                               |
|  LDAP/ACTIVE DIRECTORY                                                        |
|  ======================                                                       |
|  Port    Protocol   Service          Direction    Description                |
|  ----    --------   -------          ---------    -----------                |
|  389     TCP        LDAP             Outbound     WALLIX → AD (plaintext)    |
|  636     TCP        LDAPS            Outbound     WALLIX → AD (SSL)          |
|  3268    TCP        Global Catalog   Outbound     Multi-domain forests       |
|  3269    TCP        GC SSL           Outbound     GC with SSL                |
|                                                                               |
|  SMB (For Domain Join, Optional)                                              |
|  ================================                                             |
|  Port    Protocol   Service          Direction    Description                |
|  ----    --------   -------          ---------    -----------                |
|  445     TCP        SMB              Outbound     Domain join operations     |
|                                                                               |
+===============================================================================+
```

### 3.9 Management & Monitoring Ports

```
+===============================================================================+
|  MANAGEMENT & MONITORING PORTS                                                |
+===============================================================================+
|                                                                               |
|  TIME SYNCHRONIZATION                                                         |
|  =====================                                                        |
|  Port    Protocol   Service          Direction    Description                |
|  ----    --------   -------          ---------    -----------                |
|  123     UDP        NTP              Outbound     Time synchronization       |
|                                                                               |
|  LOGGING & SIEM                                                               |
|  ===============                                                              |
|  Port    Protocol   Service          Direction    Description                |
|  ----    --------   -------          ---------    -----------                |
|  514     UDP        Syslog           Outbound     Log forwarding             |
|  6514    TCP        Syslog TLS       Outbound     Secure log forwarding      |
|  1514    TCP        Syslog (Custom)  Outbound     Alternative syslog port    |
|                                                                               |
|  EMAIL NOTIFICATIONS                                                          |
|  ====================                                                         |
|  Port    Protocol   Service          Direction    Description                |
|  ----    --------   -------          ---------    -----------                |
|  25      TCP        SMTP             Outbound     Email notifications        |
|  587     TCP        SMTP Submission  Outbound     Email with STARTTLS        |
|  465     TCP        SMTPS            Outbound     Email with SSL (legacy)    |
|                                                                               |
|  SNMP MONITORING                                                              |
|  ================                                                             |
|  Port    Protocol   Service          Direction    Description                |
|  ----    --------   -------          ---------    -----------                |
|  161     UDP        SNMP             Inbound      SNMP queries (NMS → WALLIX)|
|  162     UDP        SNMP Trap        Outbound     SNMP traps (WALLIX → NMS)  |
|                                                                               |
|  SSH ADMINISTRATION                                                           |
|  ===================                                                          |
|  Port    Protocol   Service          Direction    Description                |
|  ----    --------   -------          ---------    -----------                |
|  22      TCP        SSH              Inbound      Admin SSH to WALLIX OS     |
|                                                    (Different from proxy!)    |
|                                                                               |
|  PROMETHEUS/GRAFANA (Optional)                                                |
|  ==============================                                               |
|  Port    Protocol   Service          Direction    Description                |
|  ----    --------   -------          ---------    -----------                |
|  9100    TCP        Node Exporter    Inbound      Prometheus → WALLIX        |
|  9104    TCP        MariaDB Exporter Inbound      DB metrics (optional)      |
|  9090    TCP        Prometheus       Inbound      Prometheus server UI       |
|  3000    TCP        Grafana          Inbound      Grafana dashboard          |
|                                                                               |
+===============================================================================+
```

### 3.10 Cross-Site Synchronization Ports

```
+===============================================================================+
|  CROSS-SITE SYNCHRONIZATION PORTS                                             |
+===============================================================================+
|                                                                               |
|  CONFIGURATION SYNC                                                           |
|  ===================                                                          |
|  Port    Protocol   Service          Direction    Description                |
|  ----    --------   -------          ---------    -----------                |
|  443     TCP        HTTPS            Bidirect     Config sync (Site ↔ Site)  |
|                                                                               |
|  DATABASE REPLICATION (Multi-Site)                                            |
|  ==================================                                           |
|  Port    Protocol   Service          Direction    Description                |
|  ----    --------   -------          ---------    -----------                |
|  3306    TCP        MariaDB          Bidirect     Cross-site DB replication  |
|                                                                               |
|  Note: Cross-site replication latency should be < 100ms for optimal sync     |
|                                                                               |
+===============================================================================+
```

---

## Port Summary Tables

### 4.1 Inbound Ports to WALLIX (from Users/Internet)

| Port | Protocol | Service | Source | Description |
|------|----------|---------|--------|-------------|
| 22 | TCP | SSH Proxy | Users | SSH session access |
| 80 | TCP | HTTP | Users | Redirect to HTTPS |
| 443 | TCP | HTTPS | Users, API clients | Web UI, REST API |
| 3389 | TCP | RDP Proxy | Users | RDP session access |
| 5900 | TCP | VNC Proxy | Users | VNC session access (optional) |
| 443 | TCP | HTTPS | Access Manager | Access Manager API/UI |
| 22 | TCP | SSH | Access Manager | Access Manager connections |
| 3389 | TCP | RDP | Access Manager | Access Manager RDP proxy |
| 22 | TCP | SSH Admin | Admins | SSH to WALLIX OS |
| 161 | UDP | SNMP | NMS | SNMP monitoring |
| 9100 | TCP | Prometheus | Monitoring | Metrics collection |
| 3306 | TCP | MariaDB | HA Peer | Database replication (internal) |
| 2224 | TCP | PCSD | HA Peer | Pacemaker cluster management |
| 5404-5406 | UDP | Corosync | HA Peer | Cluster heartbeat |

### 4.2 Outbound Ports from WALLIX (to Targets/Services)

| Port | Protocol | Service | Destination | Description |
|------|----------|---------|-------------|-------------|
| 22 | TCP | SSH | RHEL targets | SSH sessions |
| 3389 | TCP | RDP | Windows targets | RDP sessions |
| 5985 | TCP | WinRM HTTP | Windows targets | Password rotation |
| 5986 | TCP | WinRM HTTPS | Windows targets | Password rotation (SSL) |
| 389 | TCP | LDAP | Active Directory | LDAP authentication |
| 636 | TCP | LDAPS | Active Directory | LDAPS authentication |
| 3268 | TCP | Global Catalog | Active Directory | Multi-domain forests |
| 3269 | TCP | GC SSL | Active Directory | GC with SSL |
| 1812 | UDP | RADIUS Auth | FortiAuthenticator | MFA authentication |
| 1813 | UDP | RADIUS Acct | FortiAuthenticator | MFA accounting |
| 123 | UDP | NTP | NTP servers | Time synchronization |
| 514 | UDP | Syslog | SIEM | Log forwarding |
| 6514 | TCP | Syslog TLS | SIEM | Secure log forwarding |
| 25 | TCP | SMTP | Mail relay | Email notifications |
| 587 | TCP | SMTP | Mail relay | Email with STARTTLS |
| 162 | UDP | SNMP Trap | NMS | SNMP traps |
| 443 | TCP | HTTPS | Remote sites | Cross-site sync |

### 4.3 Internal Cluster Ports (WALLIX ↔ WALLIX)

| Port | Protocol | Service | Direction | Description |
|------|----------|---------|-----------|-------------|
| 3306 | TCP | MariaDB | Bidirectional | Streaming replication |
| 2224 | TCP | PCSD | Bidirectional | Pacemaker web UI/API |
| 3121 | TCP | Pacemaker | Bidirectional | Pacemaker remote |
| 5403 | TCP | Corosync QNet | Bidirectional | Quorum device |
| 5404 | UDP | Corosync | Bidirectional | Cluster multicast |
| 5405 | UDP | Corosync | Bidirectional | Cluster unicast |
| 5406 | UDP | Corosync | Bidirectional | Cluster communication |
| 443 | TCP | HTTPS | Bidirectional | Cluster API/sync |

---

## FortiAuthenticator HA Configuration

### 5.1 Architecture Diagram

```
+===============================================================================+
|  FORTIAUTHENTICATOR HIGH AVAILABILITY ARCHITECTURE                            |
+===============================================================================+
|                                                                               |
|                         +------------------------+                            |
|                         | FortiAuthenticator-VIP |                            |
|                         |      10.10.0.60        |                            |
|                         +----------+-------------+                            |
|                                    |                                          |
|              +---------------------+---------------------+                    |
|              |                                           |                    |
|  +-----------v--------------+              +-------------v----------+         |
|  | FortiAuthenticator       |              | FortiAuthenticator     |         |
|  | Primary                  |<============>| Secondary              |         |
|  | 10.10.0.61               |  HA Sync     | 10.10.0.62             |         |
|  |                          |              |                        |         |
|  | Status: Active           |              | Status: Standby        |         |
|  | Priority: 200            |              | Priority: 100          |         |
|  +-----------+--------------+              +-------------+----------+         |
|              |                                           |                    |
|              +-------------------+  RADIUS  +------------+                    |
|                                  |  1812    |                                 |
|                                  |  1813    |                                 |
|                    +-------------v----------v-------------+                   |
|                    |         WALLIX BASTION               |                   |
|                    |  (Both nodes configured with         |                   |
|                    |   Primary and Secondary FortiAuth)   |                   |
|                    +--------------------------------------+                   |
|                                                                               |
+===============================================================================+
```

### 5.2 RADIUS Client Configuration

#### WALLIX Node 1 - Primary FortiAuthenticator

```bash
# Via WALLIX CLI
wabadmin auth radius add \
    --name "FortiAuth-Primary" \
    --server "10.10.0.61" \
    --port 1812 \
    --secret "[strong-shared-secret]" \
    --timeout 30 \
    --retries 3 \
    --priority 1
```

**Via Web UI:**

```
Configuration > Authentication > External Auth > Add RADIUS Server

Name:               FortiAuth-Primary
Server Address:     10.10.0.61
Authentication Port: 1812
Accounting Port:    1813
Shared Secret:      [32+ character secret]
Timeout:            30 seconds
Retries:            3
Priority:           1 (primary)
```

#### WALLIX Node 1 - Secondary FortiAuthenticator (Failover)

```bash
# Via WALLIX CLI
wabadmin auth radius add \
    --name "FortiAuth-Secondary" \
    --server "10.10.0.62" \
    --port 1812 \
    --secret "[same-shared-secret]" \
    --timeout 30 \
    --retries 3 \
    --priority 2
```

**Via Web UI:**

```
Configuration > Authentication > External Auth > Add RADIUS Server

Name:               FortiAuth-Secondary
Server Address:     10.10.0.62
Authentication Port: 1812
Accounting Port:    1813
Shared Secret:      [Same secret as primary]
Timeout:            30 seconds
Retries:            3
Priority:           2 (secondary/failover)
```

#### WALLIX Node 2 - Same Configuration

Both WALLIX nodes must have identical RADIUS configuration pointing to both FortiAuthenticator primary and secondary.

### 5.3 FortiAuthenticator RADIUS Clients

**On FortiAuthenticator Primary (10.10.0.61):**

```
Authentication > RADIUS Service > Clients

1. Create Client for WALLIX Node 1:
   Name:           WALLIX-Node1
   Client IP/Name: 10.10.1.11
   Secret:         [Strong shared secret - 32+ chars]
   Description:    WALLIX Bastion Primary Node Site 1

   Authentication:
   [x] Enable
   [ ] Authorize only

   Profile:        Default

2. Create Client for WALLIX Node 2:
   Name:           WALLIX-Node2
   Client IP/Name: 10.10.1.12
   Secret:         [Same secret as Node 1]
   Description:    WALLIX Bastion Secondary Node Site 1
```

**Repeat for all WALLIX nodes across all 4 sites.**

### 5.4 Failover Behavior

#### Automatic Failover Triggers

| Condition | Action | Recovery Time |
|-----------|--------|---------------|
| Primary FortiAuth unresponsive (3 timeouts) | Switch to Secondary | 30-60 seconds |
| Primary FortiAuth returns "unavailable" | Switch to Secondary | Immediate |
| Network partition detected | Use Secondary | Immediate |
| RADIUS request timeout (> 30s) | Retry on Secondary | 30 seconds |

#### Failover Configuration

```bash
# Enable automatic failover on WALLIX
wabadmin auth radius failover enable \
    --primary "FortiAuth-Primary" \
    --secondary "FortiAuth-Secondary" \
    --check-interval 30 \
    --failback-delay 300

# Configure failback behavior
wabadmin auth radius set-failback \
    --mode manual \
    --notification-email security@company.com
```

**Failback Options:**

- **Automatic**: Switch back to primary when it recovers (after 5-minute stabilization)
- **Manual**: Require administrator to manually fail back (recommended for production)

#### Manual Failover Procedures

```bash
# Check RADIUS server status
wabadmin auth radius status

# Force failover to secondary
wabadmin auth radius failover \
    --target "FortiAuth-Secondary" \
    --reason "Primary maintenance"

# Fail back to primary
wabadmin auth radius failback \
    --target "FortiAuth-Primary" \
    --verify-health
```

### 5.5 Health Check Mechanism

#### WALLIX Health Checks to FortiAuth

```
Check Type:      UDP connectivity check (RADIUS Access-Request)
Interval:        Every 30 seconds
Timeout:         5 seconds
Failure Threshold: 3 consecutive failures
Success Threshold: 2 consecutive successes (for failback)
```

**Health Check Test:**

```bash
# Test RADIUS connectivity from WALLIX
wabadmin auth radius test "FortiAuth-Primary"

# Test with specific user
wabadmin auth test \
    --provider radius \
    --server "FortiAuth-Primary" \
    --user "testuser" \
    --debug

# Check failover status
wabadmin auth radius failover-status
```

### 5.6 Port Requirements for HA

#### Between WALLIX and FortiAuthenticator

| Source | Destination | Port | Protocol | Purpose |
|--------|-------------|------|----------|---------|
| WALLIX Node 1 | FortiAuth Primary | 1812 | UDP | RADIUS Auth |
| WALLIX Node 1 | FortiAuth Primary | 1813 | UDP | RADIUS Acct |
| WALLIX Node 1 | FortiAuth Secondary | 1812 | UDP | RADIUS Auth (failover) |
| WALLIX Node 1 | FortiAuth Secondary | 1813 | UDP | RADIUS Acct (failover) |
| WALLIX Node 2 | FortiAuth Primary | 1812 | UDP | RADIUS Auth |
| WALLIX Node 2 | FortiAuth Primary | 1813 | UDP | RADIUS Acct |
| WALLIX Node 2 | FortiAuth Secondary | 1812 | UDP | RADIUS Auth (failover) |
| WALLIX Node 2 | FortiAuth Secondary | 1813 | UDP | RADIUS Acct (failover) |

#### Between FortiAuthenticator Nodes (HA Sync)

| Source | Destination | Port | Protocol | Purpose |
|--------|-------------|------|----------|---------|
| FortiAuth Primary | FortiAuth Secondary | 5199 | TCP | HA heartbeat |
| FortiAuth Primary | FortiAuth Secondary | 443 | TCP | Config sync |
| FortiAuth Primary | FortiAuth Secondary | 3306 | TCP | Database replication (if applicable) |

#### Firewall Rules Required

```bash
# On WALLIX nodes - allow outbound to both FortiAuth servers
iptables -A OUTPUT -d 10.10.0.61 -p udp --dport 1812 -j ACCEPT
iptables -A OUTPUT -d 10.10.0.61 -p udp --dport 1813 -j ACCEPT
iptables -A OUTPUT -d 10.10.0.62 -p udp --dport 1812 -j ACCEPT
iptables -A OUTPUT -d 10.10.0.62 -p udp --dport 1813 -j ACCEPT

# On FortiAuth servers - allow inbound RADIUS from all WALLIX nodes
# (Configure on Fortigate or FortiAuth itself)
```

### 5.7 Monitoring and Alerting

```bash
# Alert on FortiAuth failover event
wabadmin alert create \
    --name "FortiAuth-Failover" \
    --condition "radius_failover == true" \
    --action email \
    --recipient security@company.com \
    --severity high

# Alert on FortiAuth unavailable
wabadmin alert create \
    --name "FortiAuth-Down" \
    --condition "radius_servers_available < 1" \
    --action email,snmp \
    --recipient security@company.com \
    --severity critical

# Daily RADIUS health report
wabadmin report schedule \
    --type radius-health \
    --frequency daily \
    --recipient security@company.com
```

---

## Firewall Rules & Zone Configuration

### 6.1 Network Zones

```
+===============================================================================+
|  NETWORK ZONE DEFINITIONS                                                     |
+===============================================================================+
|                                                                               |
|  Zone Name          VLAN   Subnet           Purpose                           |
|  ----------         ----   ------           -------                           |
|  External           N/A    Public IPs       Internet-facing                   |
|  DMZ                110    10.10.1.0/24     HAProxy, Fortigate DMZ            |
|  Management         100    10.10.0.0/24     AD, FortiAuth, SIEM, DNS, NTP     |
|  PAM                120    10.10.1.0/24     WALLIX Bastion nodes              |
|  RDS                130    10.10.1.0/24     WALLIX RDS for Windows            |
|  Targets            140    10.10.2.0/24     Windows Server 2022, RHEL         |
|                                                                               |
+===============================================================================+
```

### 6.2 iptables Rules

#### Complete iptables Ruleset for WALLIX Bastion

```bash
#!/bin/bash
# /etc/wallix/firewall-rules.sh
# WALLIX Bastion 12.x iptables configuration
# For Debian 12 (Bookworm)

# Flush existing rules
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X

# Set default policies
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

#==============================================================================
# INPUT RULES (Inbound Traffic)
#==============================================================================

# Allow loopback
iptables -A INPUT -i lo -j ACCEPT

# Allow established/related connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

#------------------------------------------------------------------------------
# USER ACCESS PORTS
#------------------------------------------------------------------------------

# Allow HTTPS (Web UI, API)
iptables -A INPUT -p tcp --dport 443 -m state --state NEW -j ACCEPT

# Allow SSH Proxy
iptables -A INPUT -p tcp --dport 22 -m state --state NEW -j ACCEPT

# Allow RDP Proxy
iptables -A INPUT -p tcp --dport 3389 -m state --state NEW -j ACCEPT

# Allow VNC Proxy (optional)
iptables -A INPUT -p tcp --dport 5900 -m state --state NEW -j ACCEPT

# Allow HTTP (redirect to HTTPS)
iptables -A INPUT -p tcp --dport 80 -m state --state NEW -j ACCEPT

#------------------------------------------------------------------------------
# HA CLUSTER COMMUNICATION (from peer node only)
#------------------------------------------------------------------------------

# Replace 10.10.1.12 with your peer node IP
PEER_NODE="10.10.1.12"

# Corosync cluster communication
iptables -A INPUT -s ${PEER_NODE} -p udp --dport 5404 -j ACCEPT
iptables -A INPUT -s ${PEER_NODE} -p udp --dport 5405 -j ACCEPT
iptables -A INPUT -s ${PEER_NODE} -p udp --dport 5406 -j ACCEPT

# Pacemaker
iptables -A INPUT -s ${PEER_NODE} -p tcp --dport 2224 -j ACCEPT
iptables -A INPUT -s ${PEER_NODE} -p tcp --dport 3121 -j ACCEPT
iptables -A INPUT -s ${PEER_NODE} -p tcp --dport 5403 -j ACCEPT

# MariaDB streaming replication
iptables -A INPUT -s ${PEER_NODE} -p tcp --dport 3306 -j ACCEPT

#------------------------------------------------------------------------------
# CROSS-SITE SYNC (from remote sites)
#------------------------------------------------------------------------------

# Site 2
iptables -A INPUT -s 10.0.2.0/24 -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -s 10.0.2.0/24 -p tcp --dport 3306 -j ACCEPT

# Site 3
iptables -A INPUT -s 10.0.3.0/24 -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -s 10.0.3.0/24 -p tcp --dport 3306 -j ACCEPT

# Site 4
iptables -A INPUT -s 10.0.4.0/24 -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -s 10.0.4.0/24 -p tcp --dport 3306 -j ACCEPT

#------------------------------------------------------------------------------
# ADMIN ACCESS (from trusted management network only)
#------------------------------------------------------------------------------

ADMIN_NET="10.10.0.0/24"

# SSH administration (rate limited)
iptables -A INPUT -s ${ADMIN_NET} -p tcp --dport 22 -m state --state NEW \
    -m recent --set --name SSH
iptables -A INPUT -s ${ADMIN_NET} -p tcp --dport 22 -m state --state NEW \
    -m recent --update --seconds 60 --hitcount 4 --name SSH -j DROP
iptables -A INPUT -s ${ADMIN_NET} -p tcp --dport 22 -j ACCEPT

#------------------------------------------------------------------------------
# MONITORING
#------------------------------------------------------------------------------

# SNMP (from NMS only)
NMS_IP="10.10.0.50"
iptables -A INPUT -s ${NMS_IP} -p udp --dport 161 -j ACCEPT

# Prometheus node_exporter (from Prometheus server only)
PROMETHEUS_IP="10.10.0.51"
iptables -A INPUT -s ${PROMETHEUS_IP} -p tcp --dport 9100 -j ACCEPT

#------------------------------------------------------------------------------
# ICMP (Ping)
#------------------------------------------------------------------------------

# Allow ping from management network
iptables -A INPUT -s ${ADMIN_NET} -p icmp --icmp-type echo-request -j ACCEPT

#==============================================================================
# OUTPUT RULES (Outbound Traffic)
#==============================================================================

# Allow loopback
iptables -A OUTPUT -o lo -j ACCEPT

# Allow established/related connections
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

#------------------------------------------------------------------------------
# TARGET ACCESS
#------------------------------------------------------------------------------

TARGET_NET="10.10.2.0/24"

# SSH to RHEL targets
iptables -A OUTPUT -d ${TARGET_NET} -p tcp --dport 22 -j ACCEPT

# RDP to Windows targets
iptables -A OUTPUT -d ${TARGET_NET} -p tcp --dport 3389 -j ACCEPT

# WinRM to Windows targets (password rotation)
iptables -A OUTPUT -d ${TARGET_NET} -p tcp --dport 5985 -j ACCEPT
iptables -A OUTPUT -d ${TARGET_NET} -p tcp --dport 5986 -j ACCEPT

#------------------------------------------------------------------------------
# AUTHENTICATION
#------------------------------------------------------------------------------

# Active Directory
AD_SERVER="10.10.0.10"

iptables -A OUTPUT -d ${AD_SERVER} -p tcp --dport 389 -j ACCEPT  # LDAP
iptables -A OUTPUT -d ${AD_SERVER} -p tcp --dport 636 -j ACCEPT  # LDAPS
iptables -A OUTPUT -d ${AD_SERVER} -p tcp --dport 3268 -j ACCEPT # GC
iptables -A OUTPUT -d ${AD_SERVER} -p tcp --dport 3269 -j ACCEPT # GC SSL

# FortiAuthenticator (RADIUS MFA)
FORTIAUTH_PRIMARY="10.10.0.61"
FORTIAUTH_SECONDARY="10.10.0.62"

iptables -A OUTPUT -d ${FORTIAUTH_PRIMARY} -p udp --dport 1812 -j ACCEPT
iptables -A OUTPUT -d ${FORTIAUTH_PRIMARY} -p udp --dport 1813 -j ACCEPT
iptables -A OUTPUT -d ${FORTIAUTH_SECONDARY} -p udp --dport 1812 -j ACCEPT
iptables -A OUTPUT -d ${FORTIAUTH_SECONDARY} -p udp --dport 1813 -j ACCEPT

#------------------------------------------------------------------------------
# MANAGEMENT SERVICES
#------------------------------------------------------------------------------

# NTP
iptables -A OUTPUT -p udp --dport 123 -j ACCEPT

# DNS
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT

# Syslog to SIEM
SIEM_SERVER="10.10.0.100"
iptables -A OUTPUT -d ${SIEM_SERVER} -p udp --dport 514 -j ACCEPT
iptables -A OUTPUT -d ${SIEM_SERVER} -p tcp --dport 6514 -j ACCEPT

# SMTP (email notifications)
SMTP_RELAY="10.10.0.25"
iptables -A OUTPUT -d ${SMTP_RELAY} -p tcp --dport 25 -j ACCEPT
iptables -A OUTPUT -d ${SMTP_RELAY} -p tcp --dport 587 -j ACCEPT

# SNMP traps to NMS
iptables -A OUTPUT -d ${NMS_IP} -p udp --dport 162 -j ACCEPT

#------------------------------------------------------------------------------
# HA CLUSTER COMMUNICATION
#------------------------------------------------------------------------------

# To peer node
iptables -A OUTPUT -d ${PEER_NODE} -p udp --dport 5404 -j ACCEPT
iptables -A OUTPUT -d ${PEER_NODE} -p udp --dport 5405 -j ACCEPT
iptables -A OUTPUT -d ${PEER_NODE} -p udp --dport 5406 -j ACCEPT
iptables -A OUTPUT -d ${PEER_NODE} -p tcp --dport 2224 -j ACCEPT
iptables -A OUTPUT -d ${PEER_NODE} -p tcp --dport 3121 -j ACCEPT
iptables -A OUTPUT -d ${PEER_NODE} -p tcp --dport 5403 -j ACCEPT
iptables -A OUTPUT -d ${PEER_NODE} -p tcp --dport 3306 -j ACCEPT
iptables -A OUTPUT -d ${PEER_NODE} -p tcp --dport 443 -j ACCEPT

#------------------------------------------------------------------------------
# CROSS-SITE SYNC
#------------------------------------------------------------------------------

# To remote sites
iptables -A OUTPUT -d 10.0.2.0/24 -p tcp --dport 443 -j ACCEPT
iptables -A OUTPUT -d 10.0.2.0/24 -p tcp --dport 3306 -j ACCEPT
iptables -A OUTPUT -d 10.0.3.0/24 -p tcp --dport 443 -j ACCEPT
iptables -A OUTPUT -d 10.0.3.0/24 -p tcp --dport 3306 -j ACCEPT
iptables -A OUTPUT -d 10.0.4.0/24 -p tcp --dport 443 -j ACCEPT
iptables -A OUTPUT -d 10.0.4.0/24 -p tcp --dport 3306 -j ACCEPT

#==============================================================================
# LOGGING (Log dropped packets for troubleshooting)
#==============================================================================

iptables -A INPUT -m limit --limit 5/min -j LOG --log-prefix "iptables-INPUT-DROP: " --log-level 7
iptables -A OUTPUT -m limit --limit 5/min -j LOG --log-prefix "iptables-OUTPUT-DROP: " --log-level 7

#==============================================================================
# SAVE RULES
#==============================================================================

# Debian 12
iptables-save > /etc/iptables/rules.v4

echo "WALLIX Bastion firewall rules applied successfully."
```

**Make executable and apply:**

```bash
chmod +x /etc/wallix/firewall-rules.sh
/etc/wallix/firewall-rules.sh

# Enable on boot
echo "/etc/wallix/firewall-rules.sh" >> /etc/rc.local
chmod +x /etc/rc.local
```

### 6.3 nftables Rules

#### Modern nftables Configuration

```bash
#!/usr/sbin/nft -f
# /etc/nftables.conf
# WALLIX Bastion 12.x nftables configuration
# For Debian 12 (Bookworm) - Modern firewall syntax

# Flush existing ruleset
flush ruleset

#==============================================================================
# DEFINE VARIABLES
#==============================================================================

define PEER_NODE = 10.10.1.12
define ADMIN_NET = 10.10.0.0/24
define TARGET_NET = 10.10.2.0/24
define AD_SERVER = 10.10.0.10
define FORTIAUTH_PRIMARY = 10.10.0.61
define FORTIAUTH_SECONDARY = 10.10.0.62
define NMS_IP = 10.10.0.50
define PROMETHEUS_IP = 10.10.0.51
define SIEM_SERVER = 10.10.0.100
define SMTP_RELAY = 10.10.0.25

define SITE2_NET = 10.0.2.0/24
define SITE3_NET = 10.0.3.0/24
define SITE4_NET = 10.0.4.0/24

#==============================================================================
# CREATE TABLE
#==============================================================================

table inet filter {

    #==========================================================================
    # INPUT CHAIN
    #==========================================================================

    chain input {
        type filter hook input priority 0; policy drop;

        # Allow loopback
        iif "lo" accept

        # Allow established/related connections
        ct state established,related accept

        #----------------------------------------------------------------------
        # USER ACCESS PORTS
        #----------------------------------------------------------------------

        # HTTPS (Web UI, REST API)
        tcp dport 443 ct state new accept

        # SSH Proxy
        tcp dport 22 ct state new accept

        # RDP Proxy
        tcp dport 3389 ct state new accept

        # VNC Proxy (optional)
        tcp dport 5900 ct state new accept

        # HTTP (redirect to HTTPS)
        tcp dport 80 ct state new accept

        #----------------------------------------------------------------------
        # HA CLUSTER COMMUNICATION (peer node only)
        #----------------------------------------------------------------------

        # Corosync
        ip saddr $PEER_NODE udp dport { 5404, 5405, 5406 } accept

        # Pacemaker
        ip saddr $PEER_NODE tcp dport { 2224, 3121, 5403 } accept

        # MariaDB replication
        ip saddr $PEER_NODE tcp dport 3306 accept

        #----------------------------------------------------------------------
        # CROSS-SITE SYNC
        #----------------------------------------------------------------------

        # Site 2
        ip saddr $SITE2_NET tcp dport { 443, 3306 } accept

        # Site 3
        ip saddr $SITE3_NET tcp dport { 443, 3306 } accept

        # Site 4
        ip saddr $SITE4_NET tcp dport { 443, 3306 } accept

        #----------------------------------------------------------------------
        # ADMIN ACCESS (rate limited)
        #----------------------------------------------------------------------

        # SSH administration from management network
        ip saddr $ADMIN_NET tcp dport 22 ct state new \
            limit rate 4/minute accept

        #----------------------------------------------------------------------
        # MONITORING
        #----------------------------------------------------------------------

        # SNMP from NMS
        ip saddr $NMS_IP udp dport 161 accept

        # Prometheus node_exporter
        ip saddr $PROMETHEUS_IP tcp dport 9100 accept

        #----------------------------------------------------------------------
        # ICMP
        #----------------------------------------------------------------------

        # Allow ping from management network
        ip saddr $ADMIN_NET icmp type echo-request accept

        #----------------------------------------------------------------------
        # LOG DROPPED
        #----------------------------------------------------------------------

        limit rate 5/minute log prefix "nft-INPUT-DROP: "
    }

    #==========================================================================
    # OUTPUT CHAIN
    #==========================================================================

    chain output {
        type filter hook output priority 0; policy drop;

        # Allow loopback
        oif "lo" accept

        # Allow established/related connections
        ct state established,related accept

        #----------------------------------------------------------------------
        # TARGET ACCESS
        #----------------------------------------------------------------------

        # SSH to RHEL targets
        ip daddr $TARGET_NET tcp dport 22 accept

        # RDP to Windows targets
        ip daddr $TARGET_NET tcp dport 3389 accept

        # WinRM to Windows targets
        ip daddr $TARGET_NET tcp dport { 5985, 5986 } accept

        #----------------------------------------------------------------------
        # AUTHENTICATION
        #----------------------------------------------------------------------

        # Active Directory
        ip daddr $AD_SERVER tcp dport { 389, 636, 3268, 3269, 88, 464 } accept
        ip daddr $AD_SERVER udp dport { 88, 464 } accept

        # FortiAuthenticator RADIUS
        ip daddr { $FORTIAUTH_PRIMARY, $FORTIAUTH_SECONDARY } \
            udp dport { 1812, 1813 } accept

        #----------------------------------------------------------------------
        # MANAGEMENT SERVICES
        #----------------------------------------------------------------------

        # NTP
        udp dport 123 accept

        # DNS
        udp dport 53 accept
        tcp dport 53 accept

        # Syslog to SIEM
        ip daddr $SIEM_SERVER udp dport 514 accept
        ip daddr $SIEM_SERVER tcp dport 6514 accept

        # SMTP
        ip daddr $SMTP_RELAY tcp dport { 25, 587 } accept

        # SNMP traps to NMS
        ip daddr $NMS_IP udp dport 162 accept

        #----------------------------------------------------------------------
        # HA CLUSTER COMMUNICATION
        #----------------------------------------------------------------------

        # To peer node
        ip daddr $PEER_NODE udp dport { 5404, 5405, 5406 } accept
        ip daddr $PEER_NODE tcp dport { 2224, 3121, 5403, 3306, 443 } accept

        #----------------------------------------------------------------------
        # CROSS-SITE SYNC
        #----------------------------------------------------------------------

        ip daddr { $SITE2_NET, $SITE3_NET, $SITE4_NET } \
            tcp dport { 443, 3306 } accept

        #----------------------------------------------------------------------
        # LOG DROPPED
        #----------------------------------------------------------------------

        limit rate 5/minute log prefix "nft-OUTPUT-DROP: "
    }

    #==========================================================================
    # FORWARD CHAIN (Not used for WALLIX - no routing)
    #==========================================================================

    chain forward {
        type filter hook forward priority 0; policy drop;
    }
}

#==============================================================================
# NAT TABLE (If needed for specific scenarios)
#==============================================================================

# table ip nat {
#     chain prerouting {
#         type nat hook prerouting priority -100;
#     }
#
#     chain postrouting {
#         type nat hook postrouting priority 100;
#     }
# }
```

**Apply nftables configuration:**

```bash
# Load configuration
nft -f /etc/nftables.conf

# Enable nftables service
systemctl enable nftables
systemctl start nftables

# Verify rules
nft list ruleset

# Test configuration without making permanent
nft -c -f /etc/nftables.conf
```

### 6.4 firewalld Configuration

#### Zone-Based Firewall with firewalld

**Define Custom Zones:**

```bash
# Create custom zones for WALLIX
firewall-cmd --permanent --new-zone=wallix-public
firewall-cmd --permanent --new-zone=wallix-cluster
firewall-cmd --permanent --new-zone=wallix-targets
firewall-cmd --permanent --new-zone=wallix-admin
```

**Zone: wallix-public (User Access)**

```bash
# Public-facing services
firewall-cmd --permanent --zone=wallix-public \
    --add-service=https

firewall-cmd --permanent --zone=wallix-public \
    --add-service=ssh

firewall-cmd --permanent --zone=wallix-public \
    --add-service=rdp

firewall-cmd --permanent --zone=wallix-public \
    --add-service=vnc-server

# HTTP redirect
firewall-cmd --permanent --zone=wallix-public \
    --add-service=http

# Assign interface (if dedicated)
# firewall-cmd --permanent --zone=wallix-public \
#     --add-interface=eth0
```

**Zone: wallix-cluster (HA Communication)**

```bash
# Corosync cluster ports
firewall-cmd --permanent --zone=wallix-cluster \
    --add-port=5404-5406/udp

# Pacemaker ports
firewall-cmd --permanent --zone=wallix-cluster \
    --add-port=2224/tcp \
    --add-port=3121/tcp \
    --add-port=5403/tcp

# MariaDB replication
firewall-cmd --permanent --zone=wallix-cluster \
    --add-port=3306/tcp

# HTTPS for cluster API
firewall-cmd --permanent --zone=wallix-cluster \
    --add-service=https

# Restrict to peer node only
firewall-cmd --permanent --zone=wallix-cluster \
    --add-source=10.10.1.12/32
```

**Zone: wallix-targets (Target System Access)**

```bash
# SSH to RHEL targets
firewall-cmd --permanent --zone=wallix-targets \
    --add-service=ssh

# RDP to Windows targets
firewall-cmd --permanent --zone=wallix-targets \
    --add-service=rdp

# WinRM
firewall-cmd --permanent --zone=wallix-targets \
    --add-port=5985/tcp \
    --add-port=5986/tcp

# Target network
firewall-cmd --permanent --zone=wallix-targets \
    --add-source=10.10.2.0/24
```

**Zone: wallix-admin (Administration)**

```bash
# SSH administration (rate limited via rich rules)
firewall-cmd --permanent --zone=wallix-admin \
    --add-rich-rule='rule family="ipv4" source address="10.10.0.0/24" service name="ssh" limit value="4/m" accept'

# SNMP from NMS
firewall-cmd --permanent --zone=wallix-admin \
    --add-rich-rule='rule family="ipv4" source address="10.10.0.50" port port="161" protocol="udp" accept'

# Prometheus
firewall-cmd --permanent --zone=wallix-admin \
    --add-rich-rule='rule family="ipv4" source address="10.10.0.51" port port="9100" protocol="tcp" accept'

# Admin network
firewall-cmd --permanent --zone=wallix-admin \
    --add-source=10.10.0.0/24
```

**Define Custom Services:**

```bash
# Create custom service for WinRM
cat > /etc/firewalld/services/winrm.xml <<EOF
<?xml version="1.0" encoding="utf-8"?>
<service>
  <short>WinRM</short>
  <description>Windows Remote Management</description>
  <port protocol="tcp" port="5985"/>
  <port protocol="tcp" port="5986"/>
</service>
EOF

# Create custom service for RADIUS
cat > /etc/firewalld/services/radius-mfa.xml <<EOF
<?xml version="1.0" encoding="utf-8"?>
<service>
  <short>RADIUS MFA</short>
  <description>RADIUS Authentication and Accounting</description>
  <port protocol="udp" port="1812"/>
  <port protocol="udp" port="1813"/>
  <destination ipv4="10.10.0.61"/>
  <destination ipv4="10.10.0.62"/>
</service>
EOF

# Reload firewalld
firewall-cmd --reload
```

**Rich Rules for Complex Policies:**

```bash
# Rate limit SSH proxy connections
firewall-cmd --permanent --zone=wallix-public \
    --add-rich-rule='rule family="ipv4" service name="ssh" limit value="100/s" accept'

# Allow LDAPS only from WALLIX to AD
firewall-cmd --permanent --zone=wallix-public \
    --add-rich-rule='rule family="ipv4" destination address="10.10.0.10" port port="636" protocol="tcp" accept'

# Allow RADIUS to FortiAuthenticator
firewall-cmd --permanent --zone=wallix-public \
    --add-rich-rule='rule family="ipv4" destination address="10.10.0.61" port port="1812" protocol="udp" accept'

firewall-cmd --permanent --zone=wallix-public \
    --add-rich-rule='rule family="ipv4" destination address="10.10.0.62" port port="1812" protocol="udp" accept'

# Cross-site sync from Site 2
firewall-cmd --permanent --zone=wallix-public \
    --add-rich-rule='rule family="ipv4" source address="10.0.2.0/24" port port="443" protocol="tcp" accept'

firewall-cmd --permanent --zone=wallix-public \
    --add-rich-rule='rule family="ipv4" source address="10.0.2.0/24" port port="3306" protocol="tcp" accept'
```

**Apply All Changes:**

```bash
# Reload firewalld
firewall-cmd --reload

# Verify zones
firewall-cmd --get-active-zones

# List all rules
firewall-cmd --list-all-zones

# Check specific zone
firewall-cmd --zone=wallix-public --list-all
firewall-cmd --zone=wallix-cluster --list-all
```

### 6.5 Example Configurations by Scenario

#### Scenario 1: Single Site with DMZ

```
Zones:
- External → DMZ (HAProxy)
- DMZ → Management (WALLIX Bastion)
- Management → Targets

Firewall Policy:
- External can reach HAProxy VIP on 443, 22, 3389
- HAProxy can reach WALLIX nodes on 443, 22, 3389
- WALLIX can reach targets on 22 (SSH), 3389 (RDP), 5985/5986 (WinRM)
- WALLIX can reach AD on 636 (LDAPS), FortiAuth on 1812/1813 (RADIUS)
- HA cluster traffic isolated on dedicated VLAN
```

#### Scenario 2: Multi-Site with Cross-Site Sync

```
Additional Rules:
- Site 1 WALLIX → Site 2 WALLIX: 443 (HTTPS sync), 3306 (MariaDB replication)
- Site 1 WALLIX → Site 3 WALLIX: 443, 3306
- Site 1 WALLIX → Site 4 WALLIX: 443, 3306

Latency Requirements:
- Cross-site replication latency < 100ms

Firewall Rules:
- Allow 443/tcp bidirectional between all site WALLIX VIPs
- Allow 3306/tcp bidirectional for MariaDB multi-master replication
```

#### Scenario 3: Air-Gapped Environment (No Internet)

```
Excluded Services:
- No external NTP (use internal NTP server)
- No external DNS (internal DNS only)
- No outbound SMTP to external relays
- No software updates from internet

Additional Requirements:
- Local NTP server: 10.10.0.20
- Local DNS server: 10.10.0.10
- Local SMTP relay: 10.10.0.25
- Local software repository mirror

Firewall Rules:
- DENY all outbound traffic to 0.0.0.0/0
- ALLOW only to specific internal IPs
```

#### Scenario 4: Segmented Network with Multiple VLANs

```
VLAN Segmentation:
- VLAN 100: Management (AD, DNS, NTP)
- VLAN 110: DMZ (HAProxy, Fortigate)
- VLAN 120: PAM (WALLIX Bastion)
- VLAN 130: RDS (WALLIX RDS)
- VLAN 140: Windows Targets
- VLAN 150: RHEL Targets
- VLAN 160: Cluster Heartbeat (isolated)

Routing:
- All inter-VLAN traffic routed through firewall
- No direct communication between VLANs except via WALLIX

Firewall Rules:
- VLAN 120 → VLAN 100: LDAPS, RADIUS, DNS, NTP
- VLAN 120 → VLAN 140: RDP, WinRM
- VLAN 120 → VLAN 150: SSH
- VLAN 120 → VLAN 160: HA cluster (Corosync, MariaDB)
- Block all other inter-VLAN traffic
```

---

## Troubleshooting Port Matrix

### 7.1 Symptom-to-Port Mapping Table

| Symptom | Likely Cause | Port to Check | Verification Command |
|---------|--------------|---------------|---------------------|
| Cannot login to WALLIX Web UI | HTTPS port blocked | 443/tcp | `nc -zv wallix.company.com 443` |
| Web UI loads but login fails | LDAP/RADIUS unreachable | 636/tcp, 1812/udp | `nc -zv ad.company.com 636`<br>`nc -zuv 10.10.0.60 1812` |
| SSH proxy connection refused | SSH proxy port blocked | 22/tcp | `ssh -v user@wallix.company.com` |
| SSH proxy hangs after auth | Target SSH port blocked | 22/tcp (to target) | `nc -zv target.company.com 22` |
| RDP session fails to start | RDP port blocked to target | 3389/tcp | `nc -zv target.company.com 3389` |
| RDP session black screen | RDS unavailable | Check RDS status | `systemctl status wallix-rds` |
| MFA not working | RADIUS port blocked | 1812/1813 udp | `nc -zuv 10.10.0.60 1812` |
| MFA timeout | RADIUS server down/slow | 1812/1813 udp | `wabadmin auth radius test "FortiAuth-Primary"` |
| Password rotation fails (Windows) | WinRM ports blocked | 5985/5986 tcp | `nc -zv target.company.com 5985` |
| Password rotation fails (Linux) | SSH port blocked to target | 22/tcp | `nc -zv target.company.com 22` |
| LDAP authentication fails | LDAP/LDAPS port blocked | 389/636 tcp | `ldapsearch -H ldaps://ad.company.com -x` |
| Kerberos SSO not working | Kerberos port blocked | 88 tcp/udp | `nc -zuv ad.company.com 88` |
| HA cluster split-brain | Corosync ports blocked | 5404-5406 udp | `corosync-cfgtool -s` |
| HA cluster node offline | Cluster communication issue | 5404-5406 udp, 2224/3121 tcp | `crm status` |
| Database replication lag | MariaDB port blocked | 3306/tcp | `nc -zv peer-node.company.com 3306` |
| Database replication stopped | Replication failure | 3306/tcp | `mysql -e "SHOW SLAVE STATUS\G"` |
| Time drift issues | NTP port blocked | 123/udp | `chronyc tracking` |
| Logs not reaching SIEM | Syslog port blocked | 514/6514 tcp/udp | `logger -n siem.company.com -P 514 "test"` |
| Email notifications not sent | SMTP port blocked | 25/587 tcp | `nc -zv smtp.company.com 587` |
| SNMP monitoring not working | SNMP port blocked | 161/udp | `snmpget -v2c -c public wallix.company.com system.sysDescr.0` |
| Cross-site sync failing | HTTPS/MariaDB blocked | 443/3306 tcp | `nc -zv remote-site.company.com 443` |
| HAProxy health check failing | Backend unreachable | 443/22 tcp | `curl -k https://wallix-node1:443` |
| VIP not responding | VRRP blocked | IP protocol 112 | `tcpdump -i eth0 vrrp` |
| FortiAuth failover not working | Secondary RADIUS unreachable | 1812/1813 udp | `nc -zuv 10.10.0.62 1812` |
| Prometheus metrics missing | node_exporter port blocked | 9100/tcp | `curl http://wallix-node1:9100/metrics` |
| Cannot SSH to WALLIX OS | Admin SSH port blocked | 22/tcp (admin) | `ssh root@wallix-mgmt.company.com` |
| DNS resolution failing | DNS port blocked | 53 tcp/udp | `dig @10.10.0.10 wallix.company.com` |
| Session recording playback fails | Storage/network issue | NFS/iSCSI ports | `df -h /var/wab/recorded` |

### 7.2 Port Verification Commands

#### TCP Port Checks

```bash
# Using netcat (nc)
nc -zv <hostname> <port>

# Examples:
nc -zv wallix.company.com 443        # HTTPS
nc -zv wallix.company.com 22         # SSH
nc -zv 10.10.0.10 636                # LDAPS
nc -zv 10.10.2.50 3389               # RDP to target

# Batch check multiple ports
for port in 22 443 3389; do
    nc -zv wallix.company.com $port
done
```

#### UDP Port Checks

```bash
# Using netcat for UDP
nc -zuv <hostname> <port>

# Examples:
nc -zuv 10.10.0.60 1812              # RADIUS Auth
nc -zuv 10.10.0.60 1813              # RADIUS Acct
nc -zuv 10.10.0.20 123               # NTP
nc -zuv siem.company.com 514         # Syslog

# UDP check with timeout
timeout 5 nc -zuv 10.10.0.60 1812
```

#### Check Listening Ports

```bash
# On WALLIX node - check which ports are listening
ss -tulnp | grep LISTEN

# Check specific port
ss -tulnp | grep :443

# Alternative: netstat
netstat -tulnp | grep LISTEN

# Show all connections
ss -anp
```

#### Telnet Port Test

```bash
# Test TCP connectivity (interactive)
telnet wallix.company.com 443

# Exit telnet: Ctrl+] then type "quit"
```

#### Curl HTTP/HTTPS Test

```bash
# Test HTTPS connectivity
curl -k -v https://wallix.company.com

# Test with timeout
curl -k -v --connect-timeout 5 https://wallix.company.com

# Test specific HTTP method
curl -k -X HEAD https://wallix.company.com
```

#### LDAP Port Test

```bash
# Test LDAP connectivity
ldapsearch -H ldap://10.10.0.10:389 -x -b "" -s base

# Test LDAPS connectivity
ldapsearch -H ldaps://10.10.0.10:636 -x -b "" -s base
```

#### RADIUS Port Test

```bash
# From WALLIX node
wabadmin auth radius test "FortiAuth-Primary"

# With specific user
wabadmin auth test \
    --provider radius \
    --server "FortiAuth-Primary" \
    --user "testuser" \
    --debug
```

#### Database Port Test

```bash
# Test MariaDB connectivity
mysql -h 10.10.1.12 -u repl_user -p -e "SELECT 1;"

# Check replication status
mysql -e "SHOW SLAVE STATUS\G" | grep "Seconds_Behind_Master"
```

#### NTP Port Test

```bash
# Check NTP connectivity
chronyc tracking

# Manual NTP query
ntpdate -q 10.10.0.20
```

#### SMTP Port Test

```bash
# Test SMTP connectivity
telnet smtp.company.com 25

# Test with EHLO
nc smtp.company.com 25 <<EOF
EHLO wallix.company.com
QUIT
EOF
```

### 7.3 Traffic Capture for Port Analysis

```bash
# Capture traffic on specific port
tcpdump -i eth0 -n port 443 -w /tmp/https-traffic.pcap

# Capture RADIUS traffic
tcpdump -i eth0 -n "port 1812 or port 1813" -w /tmp/radius-traffic.pcap

# Capture cluster traffic
tcpdump -i eth1 -n "portrange 5404-5406 or port 3306" -w /tmp/cluster-traffic.pcap

# Capture and display in real-time
tcpdump -i eth0 -n port 443 -A

# Capture specific host
tcpdump -i eth0 -n host 10.10.0.60 -w /tmp/fortiauth-traffic.pcap
```

### 7.4 Nmap Port Scanning

```bash
# Scan common WALLIX ports
nmap -p 22,80,443,3389,5900 wallix.company.com

# Scan all ports
nmap -p- wallix.company.com

# Service version detection
nmap -sV -p 443 wallix.company.com

# Scan UDP ports (requires root)
sudo nmap -sU -p 1812,1813,514 10.10.0.60

# Fast scan
nmap -F wallix.company.com
```

### 7.5 Common Firewall Issues

#### Issue: Blocked Ports

**Symptoms:**
- Connection refused
- Connection timeout
- No route to host

**Diagnosis:**

```bash
# Check local firewall
iptables -L -n -v | grep <port>
nft list ruleset | grep <port>
firewall-cmd --list-all

# Check if port is listening
ss -tulnp | grep :<port>

# Test from source to destination
nc -zv <destination> <port>
```

**Resolution:**

```bash
# iptables - allow port
iptables -A INPUT -p tcp --dport <port> -j ACCEPT
iptables -A OUTPUT -p tcp --dport <port> -j ACCEPT
iptables-save > /etc/iptables/rules.v4

# nftables - allow port
nft add rule inet filter input tcp dport <port> accept
nft add rule inet filter output tcp dport <port> accept

# firewalld - allow port
firewall-cmd --permanent --add-port=<port>/tcp
firewall-cmd --reload
```

#### Issue: State Tracking Problems

**Symptoms:**
- Established connections drop
- Return traffic blocked

**Diagnosis:**

```bash
# Check connection tracking
cat /proc/net/nf_conntrack | grep <IP>

# Check conntrack table size
sysctl net.netfilter.nf_conntrack_count
sysctl net.netfilter.nf_conntrack_max
```

**Resolution:**

```bash
# Increase conntrack table size
sysctl -w net.netfilter.nf_conntrack_max=262144

# Make permanent
echo "net.netfilter.nf_conntrack_max = 262144" >> /etc/sysctl.conf
sysctl -p
```

#### Issue: NAT Configuration Problems

**Symptoms:**
- Return packets lost
- Asymmetric routing

**Diagnosis:**

```bash
# Check NAT rules
iptables -t nat -L -n -v

# Check routing
ip route show
```

**Resolution:**

```bash
# Ensure return path exists
# Add specific routes if needed
ip route add 10.10.0.0/24 via 10.10.1.1 dev eth0
```

#### Issue: MTU/MSS Clamping

**Symptoms:**
- Large packets drop
- SSH/RDP sessions freeze
- File transfers fail

**Diagnosis:**

```bash
# Check MTU
ip link show eth0 | grep mtu

# Test with large ping
ping -M do -s 1472 wallix.company.com
```

**Resolution:**

```bash
# Set MTU
ip link set eth0 mtu 1500

# MSS clamping (iptables)
iptables -t mangle -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

# MSS clamping (nftables)
nft add rule inet filter forward tcp flags syn tcp option maxseg size set rt mtu
```

---

## Network Validation Checklist

### 8.1 Pre-Deployment Validation

#### DNS Resolution

```bash
# Check forward DNS
nslookup wallix.company.com

# Check reverse DNS
nslookup 10.10.1.11

# Check all WALLIX node DNS
for node in wallix-node1 wallix-node2; do
    echo "Testing $node:"
    nslookup $node.company.com
done

# Verify DNS servers
cat /etc/resolv.conf

# Test DNS query time
dig wallix.company.com | grep "Query time"
```

**Expected Result:**
- Forward DNS resolves to correct IP
- Reverse DNS resolves to correct hostname
- Query time < 50ms

#### NTP Synchronization

```bash
# Check NTP status
chronyc tracking

# Check NTP sources
chronyc sources -v

# Force sync
chronyc makestep

# Verify time difference
timedatectl status
```

**Expected Result:**
- System clock synchronized: yes
- Time offset < 1 second

#### Firewall Rules Implementation

```bash
# Verify iptables rules
iptables -L -n -v

# Count rules
iptables -L INPUT -n | wc -l
iptables -L OUTPUT -n | wc -l

# Check if rules are loaded
iptables-save | grep -c "^-A"

# Test specific rule
iptables -L INPUT -n -v | grep "443"
```

**Expected Result:**
- All required rules present
- Default policy: DROP (for security)
- Correct source/destination IPs

#### Port Connectivity Tests

```bash
# Run comprehensive port test
#!/bin/bash
# /tmp/port-connectivity-test.sh

WALLIX_VIP="10.10.1.100"
AD_SERVER="10.10.0.10"
FORTIAUTH="10.10.0.60"
TARGET_WIN="10.10.2.10"
TARGET_RHEL="10.10.2.20"

echo "=== Testing WALLIX VIP ==="
nc -zv $WALLIX_VIP 443 && echo "✓ HTTPS OK" || echo "✗ HTTPS FAILED"
nc -zv $WALLIX_VIP 22 && echo "✓ SSH OK" || echo "✗ SSH FAILED"
nc -zv $WALLIX_VIP 3389 && echo "✓ RDP OK" || echo "✗ RDP FAILED"

echo "=== Testing Active Directory ==="
nc -zv $AD_SERVER 636 && echo "✓ LDAPS OK" || echo "✗ LDAPS FAILED"
nc -zv $AD_SERVER 389 && echo "✓ LDAP OK" || echo "✗ LDAP FAILED"

echo "=== Testing FortiAuthenticator ==="
nc -zuv $FORTIAUTH 1812 && echo "✓ RADIUS Auth OK" || echo "✗ RADIUS Auth FAILED"
nc -zuv $FORTIAUTH 1813 && echo "✓ RADIUS Acct OK" || echo "✗ RADIUS Acct FAILED"

echo "=== Testing Target Windows ==="
nc -zv $TARGET_WIN 3389 && echo "✓ RDP OK" || echo "✗ RDP FAILED"
nc -zv $TARGET_WIN 5985 && echo "✓ WinRM OK" || echo "✗ WinRM FAILED"

echo "=== Testing Target RHEL ==="
nc -zv $TARGET_RHEL 22 && echo "✓ SSH OK" || echo "✗ SSH FAILED"
```

#### MTU/MSS Optimization

```bash
# Check current MTU
ip link show | grep mtu

# Test path MTU
tracepath wallix.company.com

# Ping with DF (Don't Fragment) bit
ping -M do -s 1472 wallix.company.com

# If fails, try smaller size
ping -M do -s 1400 wallix.company.com
```

**Expected Result:**
- MTU 1500 for Ethernet
- MTU 1420-1450 for VPN/tunnels
- No fragmentation needed

### 8.2 Port Connectivity Matrix

#### Connectivity Test Checklist

| Source | Destination | Port | Protocol | Status | Notes |
|--------|-------------|------|----------|--------|-------|
| User Workstation | WALLIX VIP | 443 | TCP | ☐ | Web UI, API |
| User Workstation | WALLIX VIP | 22 | TCP | ☐ | SSH Proxy |
| User Workstation | WALLIX VIP | 3389 | TCP | ☐ | RDP Proxy |
| WALLIX Node 1 | WALLIX Node 2 | 3306 | TCP | ☐ | MariaDB replication |
| WALLIX Node 1 | WALLIX Node 2 | 5404-5406 | UDP | ☐ | Corosync cluster |
| WALLIX Node 1 | WALLIX Node 2 | 2224 | TCP | ☐ | Pacemaker PCSD |
| WALLIX Node 1 | Active Directory | 636 | TCP | ☐ | LDAPS |
| WALLIX Node 1 | Active Directory | 389 | TCP | ☐ | LDAP |
| WALLIX Node 1 | FortiAuth Primary | 1812 | UDP | ☐ | RADIUS Auth |
| WALLIX Node 1 | FortiAuth Primary | 1813 | UDP | ☐ | RADIUS Acct |
| WALLIX Node 1 | FortiAuth Secondary | 1812 | UDP | ☐ | RADIUS Auth (failover) |
| WALLIX Node 1 | FortiAuth Secondary | 1813 | UDP | ☐ | RADIUS Acct (failover) |
| WALLIX Node 1 | Windows Target | 3389 | TCP | ☐ | RDP sessions |
| WALLIX Node 1 | Windows Target | 5985 | TCP | ☐ | WinRM HTTP |
| WALLIX Node 1 | Windows Target | 5986 | TCP | ☐ | WinRM HTTPS |
| WALLIX Node 1 | RHEL Target | 22 | TCP | ☐ | SSH sessions |
| WALLIX Node 1 | NTP Server | 123 | UDP | ☐ | Time sync |
| WALLIX Node 1 | DNS Server | 53 | UDP/TCP | ☐ | Name resolution |
| WALLIX Node 1 | SIEM | 514 | UDP | ☐ | Syslog |
| WALLIX Node 1 | SIEM | 6514 | TCP | ☐ | Syslog TLS |
| WALLIX Node 1 | SMTP Relay | 587 | TCP | ☐ | Email notifications |
| WALLIX Node 1 | Site 2 WALLIX | 443 | TCP | ☐ | Cross-site sync |
| WALLIX Node 1 | Site 2 WALLIX | 3306 | TCP | ☐ | DB replication |
| NMS | WALLIX Node 1 | 161 | UDP | ☐ | SNMP monitoring |
| WALLIX Node 1 | NMS | 162 | UDP | ☐ | SNMP traps |
| Prometheus | WALLIX Node 1 | 9100 | TCP | ☐ | Metrics collection |
| Admin Workstation | WALLIX Node 1 | 22 | TCP | ☐ | SSH admin |
| HAProxy-1 | WALLIX Node 1 | 443 | TCP | ☐ | Health check |
| HAProxy-1 | HAProxy-2 | 112/IP | VRRP | ☐ | Keepalived |

### 8.3 Validation Scripts

#### Automated Network Validation Script

```bash
#!/bin/bash
# /usr/local/bin/wallix-network-validation.sh
# Comprehensive network validation for WALLIX Bastion deployment

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
WALLIX_VIP="10.10.1.100"
WALLIX_NODE1="10.10.1.11"
WALLIX_NODE2="10.10.1.12"
AD_SERVER="10.10.0.10"
FORTIAUTH_PRIMARY="10.10.0.61"
FORTIAUTH_SECONDARY="10.10.0.62"
TARGET_WIN="10.10.2.10"
TARGET_RHEL="10.10.2.20"
NTP_SERVER="10.10.0.20"
DNS_SERVER="10.10.0.10"
SIEM_SERVER="10.10.0.100"
SMTP_RELAY="10.10.0.25"

PASS_COUNT=0
FAIL_COUNT=0

# Test function
test_tcp_port() {
    local host=$1
    local port=$2
    local description=$3

    if timeout 5 nc -zv $host $port 2>&1 | grep -q "succeeded"; then
        echo -e "${GREEN}✓${NC} $description ($host:$port)"
        ((PASS_COUNT++))
        return 0
    else
        echo -e "${RED}✗${NC} $description ($host:$port)"
        ((FAIL_COUNT++))
        return 1
    fi
}

test_udp_port() {
    local host=$1
    local port=$2
    local description=$3

    if timeout 5 nc -zuv $host $port 2>&1 | grep -q "succeeded"; then
        echo -e "${GREEN}✓${NC} $description ($host:$port)"
        ((PASS_COUNT++))
        return 0
    else
        echo -e "${RED}✗${NC} $description ($host:$port)"
        ((FAIL_COUNT++))
        return 1
    fi
}

echo "=========================================="
echo "WALLIX Bastion Network Validation"
echo "=========================================="
echo

echo "=== Testing WALLIX VIP ==="
test_tcp_port $WALLIX_VIP 443 "HTTPS Web UI/API"
test_tcp_port $WALLIX_VIP 22 "SSH Proxy"
test_tcp_port $WALLIX_VIP 3389 "RDP Proxy"
echo

echo "=== Testing HA Cluster Communication ==="
test_tcp_port $WALLIX_NODE2 3306 "MariaDB replication"
test_udp_port $WALLIX_NODE2 5404 "Corosync multicast"
test_udp_port $WALLIX_NODE2 5405 "Corosync unicast"
test_udp_port $WALLIX_NODE2 5406 "Corosync communication"
test_tcp_port $WALLIX_NODE2 2224 "Pacemaker PCSD"
test_tcp_port $WALLIX_NODE2 3121 "Pacemaker remote"
echo

echo "=== Testing Active Directory ==="
test_tcp_port $AD_SERVER 636 "LDAPS"
test_tcp_port $AD_SERVER 389 "LDAP"
test_tcp_port $AD_SERVER 3268 "Global Catalog"
test_tcp_port $AD_SERVER 3269 "Global Catalog SSL"
echo

echo "=== Testing FortiAuthenticator MFA ==="
test_udp_port $FORTIAUTH_PRIMARY 1812 "RADIUS Auth (Primary)"
test_udp_port $FORTIAUTH_PRIMARY 1813 "RADIUS Acct (Primary)"
test_udp_port $FORTIAUTH_SECONDARY 1812 "RADIUS Auth (Secondary)"
test_udp_port $FORTIAUTH_SECONDARY 1813 "RADIUS Acct (Secondary)"
test_tcp_port $FORTIAUTH_PRIMARY 8443 "FortiAuth Admin UI"
echo

echo "=== Testing Target Systems ==="
test_tcp_port $TARGET_WIN 3389 "Windows RDP"
test_tcp_port $TARGET_WIN 5985 "Windows WinRM HTTP"
test_tcp_port $TARGET_WIN 5986 "Windows WinRM HTTPS"
test_tcp_port $TARGET_RHEL 22 "RHEL SSH"
echo

echo "=== Testing Management Services ==="
test_udp_port $NTP_SERVER 123 "NTP"
test_udp_port $DNS_SERVER 53 "DNS UDP"
test_tcp_port $DNS_SERVER 53 "DNS TCP"
test_udp_port $SIEM_SERVER 514 "Syslog UDP"
test_tcp_port $SIEM_SERVER 6514 "Syslog TLS"
test_tcp_port $SMTP_RELAY 587 "SMTP"
echo

echo "=== DNS Resolution Tests ==="
if nslookup wallix.company.com $DNS_SERVER > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} DNS forward lookup"
    ((PASS_COUNT++))
else
    echo -e "${RED}✗${NC} DNS forward lookup"
    ((FAIL_COUNT++))
fi

if nslookup $WALLIX_NODE1 $DNS_SERVER > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} DNS reverse lookup"
    ((PASS_COUNT++))
else
    echo -e "${RED}✗${NC} DNS reverse lookup"
    ((FAIL_COUNT++))
fi
echo

echo "=== NTP Synchronization ==="
if chronyc tracking | grep -q "Leap status     : Normal"; then
    echo -e "${GREEN}✓${NC} NTP synchronized"
    ((PASS_COUNT++))
else
    echo -e "${RED}✗${NC} NTP not synchronized"
    ((FAIL_COUNT++))
fi

OFFSET=$(chronyc tracking | grep "System time" | awk '{print $4}')
if (( $(echo "$OFFSET < 1.0" | bc -l) )); then
    echo -e "${GREEN}✓${NC} Time offset acceptable (${OFFSET}s)"
    ((PASS_COUNT++))
else
    echo -e "${RED}✗${NC} Time offset too high (${OFFSET}s)"
    ((FAIL_COUNT++))
fi
echo

echo "=== MTU Tests ==="
if ping -M do -s 1472 -c 1 $WALLIX_VIP > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} MTU 1500 (no fragmentation)"
    ((PASS_COUNT++))
else
    echo -e "${YELLOW}⚠${NC} MTU may need adjustment"
    ((FAIL_COUNT++))
fi
echo

echo "=========================================="
echo "Validation Summary"
echo "=========================================="
echo -e "Passed: ${GREEN}$PASS_COUNT${NC}"
echo -e "Failed: ${RED}$FAIL_COUNT${NC}"
echo

if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${GREEN}All tests passed! Network is ready for WALLIX deployment.${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed. Please review and fix issues before deployment.${NC}"
    exit 1
fi
```

**Run validation:**

```bash
chmod +x /usr/local/bin/wallix-network-validation.sh
/usr/local/bin/wallix-network-validation.sh
```

---

## Best Practices

### 9.1 Network Security

#### Principle of Least Privilege

```
Only open ports required for specific functions:

✓ User Access:
  - 443/tcp (HTTPS Web UI, REST API)
  - 22/tcp (SSH Proxy)
  - 3389/tcp (RDP Proxy)

✓ HA Cluster (isolated VLAN):
  - 3306/tcp (MariaDB)
  - 5404-5406/udp (Corosync)
  - 2224/tcp, 3121/tcp (Pacemaker)

✓ Authentication:
  - 636/tcp (LDAPS to AD)
  - 1812/1813 udp (RADIUS to FortiAuth)

✗ Unnecessary ports:
  - NO Telnet (23/tcp) unless required
  - NO VNC (5900/tcp) unless required
  - NO SNMP v1/v2 (use SNMPv3)
```

#### Network Segmentation

```
Isolate traffic by function:

1. User Traffic → DMZ (HAProxy)
2. DMZ → Management (WALLIX Bastion)
3. Management → Targets (Proxied only)
4. HA Cluster → Dedicated VLAN
5. Cross-Site Sync → Dedicated VLAN

Use separate VLANs:
- VLAN 100: Management (AD, DNS, NTP, FortiAuth)
- VLAN 110: DMZ (HAProxy, Fortigate)
- VLAN 120: PAM (WALLIX Bastion)
- VLAN 130: RDS (WALLIX RDS)
- VLAN 140: Targets
- VLAN 160: Cluster Heartbeat (isolated)
```

#### Encryption for External Communications

```
Always use encrypted protocols:

✓ LDAPS (636/tcp) instead of LDAP (389/tcp)
✓ HTTPS (443/tcp) for Web UI and API
✓ SSH (22/tcp) native encryption
✓ Syslog TLS (6514/tcp) instead of UDP (514/udp)
✓ SMTPS/STARTTLS (587/tcp) instead of plain SMTP (25/tcp)
✓ WinRM HTTPS (5986/tcp) instead of HTTP (5985/tcp)

Exception: RADIUS (UDP 1812/1813) - use shared secret + IPsec tunnel
```

#### Rate Limiting for Admin Access

```bash
# iptables - limit SSH admin connections
iptables -A INPUT -p tcp --dport 22 -m state --state NEW \
    -m recent --set --name SSH
iptables -A INPUT -p tcp --dport 22 -m state --state NEW \
    -m recent --update --seconds 60 --hitcount 4 --name SSH -j DROP

# nftables - limit SSH admin connections
nft add rule inet filter input tcp dport 22 ct state new \
    limit rate 4/minute accept

# firewalld - rate limit SSH
firewall-cmd --permanent --zone=wallix-admin \
    --add-rich-rule='rule family="ipv4" service name="ssh" limit value="4/m" accept'
```

#### IP Whitelisting for Admin Access

```bash
# Only allow admin access from specific IPs/subnets
ADMIN_NET="10.10.0.0/24"
ADMIN_WORKSTATION="10.10.0.99"

# iptables
iptables -A INPUT -s $ADMIN_NET -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -s $ADMIN_WORKSTATION -p tcp --dport 8404 -j ACCEPT

# nftables
nft add rule inet filter input ip saddr $ADMIN_NET tcp dport 22 accept

# firewalld
firewall-cmd --permanent --zone=wallix-admin --add-source=$ADMIN_NET
```

### 9.2 High Availability

#### Redundant Network Paths

```
Multiple network paths for critical components:

1. Dual NICs for WALLIX nodes:
   - eth0: Management (user access)
   - eth1: Cluster heartbeat (dedicated)
   - eth2: Storage (optional)

2. Multiple NTP sources:
   - Primary NTP: 10.10.0.20
   - Secondary NTP: 10.10.0.21
   - External NTP: pool.ntp.org (if internet available)

3. Multiple DNS servers:
   - Primary DNS: 10.10.0.10
   - Secondary DNS: 10.10.0.11
```

#### FortiAuthenticator HA Setup

```
Primary/Secondary RADIUS servers:

Primary FortiAuthenticator:   10.10.0.61
Secondary FortiAuthenticator: 10.10.0.62

WALLIX configuration:
- Both nodes configured with primary and secondary
- Automatic failover on timeout (30 seconds)
- Manual failback (after 5-minute stabilization)

Health checks:
- RADIUS Access-Request every 30 seconds
- 3 consecutive failures trigger failover
- 2 consecutive successes allow failback
```

#### HAProxy Keepalived Configuration

```
HAProxy HA with VRRP:

HAProxy-1: 10.10.1.5 (Priority 200)
HAProxy-2: 10.10.1.6 (Priority 100)
VIP:       10.10.1.100

VRRP heartbeat: IP protocol 112
Failover time: < 2 seconds
Health checks: Check WALLIX backend every 5 seconds

Firewall rule:
- Allow IP protocol 112 between HAProxy nodes
```

### 9.3 Monitoring

#### Port Availability Monitoring

```bash
# Nagios/Icinga check
define service {
    service_description     WALLIX HTTPS Port
    host_name               wallix.company.com
    check_command           check_tcp!443
    check_interval          5
    retry_interval          1
}

# Prometheus blackbox_exporter
scrape_configs:
  - job_name: 'wallix-ports'
    metrics_path: /probe
    params:
      module: [tcp_connect]
    static_configs:
      - targets:
        - wallix.company.com:443
        - wallix.company.com:22
        - wallix.company.com:3389
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: blackbox-exporter:9115
```

#### Network Latency Monitoring

```bash
# Smokeping configuration for latency tracking
*** Targets ***

+ WALLIX
menu = WALLIX Infrastructure
title = WALLIX Network Latency

++ WALLIX-VIP
menu = WALLIX VIP
title = WALLIX Load Balancer VIP
host = 10.10.1.100

++ WALLIX-Node1
menu = WALLIX Node 1
title = WALLIX Primary Node
host = 10.10.1.11

++ WALLIX-Node2
menu = WALLIX Node 2
title = WALLIX Secondary Node
host = 10.10.1.12

++ FortiAuth
menu = FortiAuthenticator
title = MFA Server
host = 10.10.0.60

# Alert on latency > 50ms
```

#### Bandwidth Utilization

```bash
# Monitor interface bandwidth with nload
nload -u M eth0

# Or with iftop
iftop -i eth0

# Collect metrics with collectd
LoadPlugin interface
<Plugin interface>
    Interface "eth0"
    Interface "eth1"
</Plugin>

# Alert on > 80% utilization
```

#### Failed Connection Attempts

```bash
# Monitor failed connections in logs
tail -f /var/log/wabengine/auth.log | grep "Failed"

# Count failed SSH proxy attempts
grep "Failed password" /var/log/wabengine/ssh.log | wc -l

# Alert on > 10 failures in 5 minutes
wabadmin alert create \
    --name "Failed-Connections" \
    --condition "failed_connections > 10 in 5m" \
    --action email \
    --recipient security@company.com
```

### 9.4 Documentation

#### Maintain Network Diagrams

```
Keep up-to-date diagrams:

1. Physical network topology
2. Logical network flow
3. VLAN layout
4. IP addressing scheme
5. Firewall zone model
6. Port matrix

Tools:
- Draw.io (diagrams.net)
- Microsoft Visio
- Lucidchart
- ASCII diagrams in docs

Update frequency:
- After any network change
- Quarterly review
- Annual full audit
```

#### Document Firewall Rule Changes

```
Change management process:

1. Document rule request
   - Who requested
   - Business justification
   - Source, destination, port
   - Temporary or permanent

2. Implement in test environment first

3. Document in firewall rules file
   # Comment above each rule
   # Added: 2026-02-04
   # Reason: Allow WALLIX to new RHEL 10 target
   # Ticket: CHG123456
   iptables -A OUTPUT -d 10.10.2.30 -p tcp --dport 22 -j ACCEPT

4. Update network documentation

5. Schedule review (quarterly)
```

#### Keep Port Inventory Updated

```
Port Inventory Spreadsheet:

| Port | Protocol | Service | Direction | Source | Destination | Status | Last Reviewed |
|------|----------|---------|-----------|--------|-------------|--------|---------------|
| 443  | TCP      | HTTPS   | Inbound   | Users  | WALLIX VIP  | Active | 2026-02-04    |
| 22   | TCP      | SSH     | Inbound   | Users  | WALLIX VIP  | Active | 2026-02-04    |
| ...  | ...      | ...     | ...       | ...    | ...         | ...    | ...           |

Review frequency:
- Quarterly for active ports
- Annually for all documented ports
- After major infrastructure changes
```

#### Record IP Address Allocations

```
IP Address Management (IPAM):

Document all IP allocations:

10.10.1.0/24 - Management Zone
  .1         - Gateway
  .5         - HAProxy-1
  .6         - HAProxy-2
  .10        - Reserved (future)
  .11        - WALLIX Node 1
  .12        - WALLIX Node 2
  .30        - WALLIX RDS
  .100       - VIP (HAProxy Keepalived)

10.10.0.0/24 - Authentication Zone
  .10        - Active Directory DC1
  .11        - Active Directory DC2
  .20        - NTP Server
  .50        - NMS (SNMP/monitoring)
  .51        - Prometheus
  .60        - FortiAuthenticator VIP
  .61        - FortiAuthenticator Primary
  .62        - FortiAuthenticator Secondary
  .100       - SIEM

10.10.2.0/24 - Target Zone
  .10-.29    - Windows Server 2022
  .30-.49    - RHEL 10
  .50-.69    - RHEL 9
  .100-.254  - Reserved

Tools:
- NetBox (open-source IPAM)
- phpIPAM
- Microsoft Excel/Google Sheets
```

---

## Related Documentation References

### Internal Documentation

| Topic | Location | Description |
|-------|----------|-------------|
| Architecture Diagrams | [install/09-architecture-diagrams.md](../install/09-architecture-diagrams.md) | Detailed architecture with port diagrams |
| Network Validation | [docs/pam/36-network-validation/README.md](pam/36-network-validation/README.md) | Network validation procedures, DNS/NTP config |
| Load Balancer Config | [docs/pam/32-load-balancer/README.md](pam/32-load-balancer/README.md) | HAProxy configuration and health checks |
| High Availability | [docs/pam/11-high-availability/README.md](pam/11-high-availability/README.md) | HA cluster networking and ports |
| FortiAuth Integration | [docs/pam/06-authentication/fortiauthenticator-integration.md](pam/06-authentication/fortiauthenticator-integration.md) | FortiAuthenticator MFA setup |
| Fortigate Integration | [docs/pam/46-fortigate-integration/README.md](pam/46-fortigate-integration/README.md) | Fortigate firewall and SSL VPN integration |
| System Requirements | [docs/pam/19-system-requirements/README.md](pam/19-system-requirements/README.md) | System requirements including network ports |
| Monitoring & Observability | [docs/pam/12-monitoring-observability/README.md](pam/12-monitoring-observability/README.md) | Prometheus/Grafana monitoring ports |
| Troubleshooting | [docs/pam/13-troubleshooting/README.md](pam/13-troubleshooting/README.md) | Network troubleshooting procedures |

### External Resources

| Resource | URL | Description |
|----------|-----|-------------|
| WALLIX Documentation | https://pam.wallix.one/documentation | Official WALLIX Bastion documentation |
| WALLIX Admin Guide | https://pam.wallix.one/documentation/admin-doc/ | Administration guide (PDF) |
| Fortinet FortiAuthenticator | https://docs.fortinet.com/product/fortiauthenticator | FortiAuthenticator documentation |
| Fortinet Fortigate | https://docs.fortinet.com/product/fortigate | Fortigate firewall documentation |
| HAProxy Documentation | https://www.haproxy.org/documentation.html | HAProxy load balancer docs |
| Keepalived Documentation | https://www.keepalived.org/documentation.html | Keepalived VRRP documentation |
| MariaDB Replication | https://mariadb.com/kb/en/replication/ | MariaDB replication documentation |
| Corosync/Pacemaker | https://clusterlabs.org/pacemaker/doc/ | HA cluster documentation |
| iptables Tutorial | https://www.frozentux.net/iptables-tutorial/ | Comprehensive iptables guide |
| nftables Wiki | https://wiki.nftables.org/ | nftables documentation and examples |

---

## Quick Reference Card

### Essential Ports

```
USER ACCESS:
  443/tcp   - HTTPS (Web UI, API)
  22/tcp    - SSH Proxy
  3389/tcp  - RDP Proxy

AUTHENTICATION:
  636/tcp   - LDAPS (Active Directory)
  1812/udp  - RADIUS Auth (FortiAuthenticator)
  1813/udp  - RADIUS Acct (FortiAuthenticator)

HA CLUSTER:
  3306/tcp  - MariaDB Replication
  5404-5406/udp - Corosync
  2224/tcp  - Pacemaker PCSD

MANAGEMENT:
  123/udp   - NTP
  53/udp    - DNS
  514/udp   - Syslog
  6514/tcp  - Syslog TLS
  587/tcp   - SMTP
```

### Quick Diagnostic Commands

```bash
# Check listening ports
ss -tulnp | grep LISTEN

# Test TCP connectivity
nc -zv <host> <port>

# Test UDP connectivity
nc -zuv <host> <port>

# Test RADIUS
wabadmin auth radius test "FortiAuth-Primary"

# Check cluster status
crm status
corosync-cfgtool -s

# Check MariaDB replication
mysql -e "SHOW SLAVE STATUS\G"

# Check NTP sync
chronyc tracking

# Check DNS
nslookup wallix.company.com

# Capture traffic
tcpdump -i eth0 -n port 443 -w /tmp/capture.pcap

# View firewall rules
iptables -L -n -v
nft list ruleset
firewall-cmd --list-all
```

---

**End of Document**

*For questions or updates to this document, contact the WALLIX infrastructure team.*
