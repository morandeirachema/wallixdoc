# Network Design - 5-Site MPLS Topology with Access Manager Integration

> MPLS network architecture, connectivity matrix, and firewall rules for 5 WALLIX Bastion sites with 2 Access Manager datacenters

---

## Document Information

| Property | Value |
|----------|-------|
| **Purpose** | Network topology and connectivity requirements for 5-site deployment |
| **Deployment Model** | 5 Paris sites + 2 Access Manager datacenters (DC-A, DC-B) |
| **Network Type** | MPLS (Access Managers ↔ Bastions only) |
| **Version** | WALLIX Bastion 12.1.x |
| **Last Updated** | February 2026 |

---

## Table of Contents

1. [Network Topology Overview](#network-topology-overview)
2. [MPLS Architecture](#mpls-architecture)
3. [Site-Specific Network Details](#site-specific-network-details)
4. [Complete Port Matrix](#complete-port-matrix)
5. [Firewall Rules](#firewall-rules)
6. [DNS Requirements](#dns-requirements)
7. [NTP Configuration](#ntp-configuration)
8. [Network Testing Procedures](#network-testing-procedures)

---

## Network Topology Overview

### 1.1 High-Level Architecture

```
+===============================================================================+
|  5-SITE MPLS TOPOLOGY WITH ACCESS MANAGER INTEGRATION                        |
+===============================================================================+
|                                                                               |
|  DATACENTER A (DC-A)           DATACENTER B (DC-B)                            |
|  +---------------------+       +---------------------+                        |
|  | Access Manager 1    |       | Access Manager 2    |                        |
|  | 10.100.1.10         |  HA   | 10.100.2.10         |                        |
|  | - SSO/MFA           |<----->| - SSO/MFA           |                        |
|  | - Session Broker    |       | - Session Broker    |                        |
|  | - License Server    |       | - License Server    |                        |
|  +---------+-----------+       +-----------+---------+                        |
|            |                               |                                  |
|            +-------------------------------+                                  |
|                         MPLS NETWORK                                          |
|            +------+------+------+------+------+                               |
|            |      |      |      |      |      |                               |
|      +-----v-+  +-v----+ +v---+ +v---+ +v----+                               |
|      |Site 1 |  |Site 2| |Site| |Site| |Site |                               |
|      |Paris  |  |Paris | | 3  | | 4  | | 5  |                               |
|      |DC-P1  |  |DC-P2 | |P3  | |P4  | |P5  |                               |
|      +-------+  +------+ +----+ +----+ +-----+                               |
|                                                                               |
|  KEY PRINCIPLE: NO direct Bastion-to-Bastion communication between sites     |
|                 All inter-site traffic flows through Access Managers         |
|                                                                               |
+===============================================================================+
```

### 1.2 Single Site Detail

```
+===============================================================================+
|  SINGLE SITE ARCHITECTURE (Repeated at Each of 5 Paris Sites)                |
+===============================================================================+
|                                                                               |
|                          MPLS Network                                         |
|                               |                                               |
|                               v                                               |
|                    +---------------------+                                    |
|                    | Fortigate Firewall  |                                    |
|                    | Site Perimeter      |                                    |
|                    | 10.10.X.1           |                                    |
|                    +----------+----------+                                    |
|                               |                                               |
|          +--------------------+--------------------+                          |
|          |                                         |                          |
|    +-----v-------+                          +------v------+                   |
|    | HAProxy-1   |  VRRP (IP Proto 112)     | HAProxy-2   |                   |
|    | Primary     |<------------------------>| Backup      |                   |
|    | 10.10.X.5   |                          | 10.10.X.6   |                   |
|    | VIP: X.100  |                          |             |                   |
|    +------+------+                          +------+------+                   |
|           |                                        |                          |
|           +-------------------+--------------------+                          |
|                               |                                               |
|                  Load Balancing (443/22/3389)                                 |
|                               |                                               |
|          +--------------------+--------------------+                          |
|          |                                         |                          |
|    +-----v-----------+                      +------v----------+               |
|    | WALLIX Bastion-1|   HA Cluster Sync    | WALLIX Bastion-2|               |
|    | 10.10.X.11      |<-------------------->| 10.10.X.12      |               |
|    |                 | MariaDB: 3306/tcp    |                 |               |
|    |                 | Corosync: 5404-6 UDP |                 |               |
|    |                 | PCSD: 2224/tcp       |                 |               |
|    +-----------------+                      +-----------------+               |
|          |                                         |                          |
|          +-------------------+---------------------+                          |
|                              |                                                |
|                    +---------v----------+                                     |
|                    |  WALLIX RDS        |                                     |
|                    |  Jump Host         |                                     |
|                    |  10.10.X.30        |                                     |
|                    |  (OT RemoteApp)    |                                     |
|                    +--------------------+                                     |
|                              |                                                |
|                              v                                                |
|                    Target Systems (Windows 2022, RHEL 9/10)                  |
|                                                                               |
+===============================================================================+
```

---

## MPLS Architecture

### 2.1 MPLS Connectivity Matrix

```
+===============================================================================+
|  MPLS CONNECTIVITY PATHS                                                      |
+===============================================================================+
|                                                                               |
|  Access Manager 1 (DC-A)  <--MPLS-->  Site 1 (Paris DC-P1)                   |
|  Access Manager 1 (DC-A)  <--MPLS-->  Site 2 (Paris DC-P2)                   |
|  Access Manager 1 (DC-A)  <--MPLS-->  Site 3 (Paris DC-P3)                   |
|  Access Manager 1 (DC-A)  <--MPLS-->  Site 4 (Paris DC-P4)                   |
|  Access Manager 1 (DC-A)  <--MPLS-->  Site 5 (Paris DC-P5)                   |
|                                                                               |
|  Access Manager 2 (DC-B)  <--MPLS-->  Site 1 (Paris DC-P1)                   |
|  Access Manager 2 (DC-B)  <--MPLS-->  Site 2 (Paris DC-P2)                   |
|  Access Manager 2 (DC-B)  <--MPLS-->  Site 3 (Paris DC-P3)                   |
|  Access Manager 2 (DC-B)  <--MPLS-->  Site 4 (Paris DC-P4)                   |
|  Access Manager 2 (DC-B)  <--MPLS-->  Site 5 (Paris DC-P5)                   |
|                                                                               |
|  Access Manager 1 (DC-A)  <--HA-->  Access Manager 2 (DC-B)                  |
|                                                                               |
|  CRITICAL: NO Site-to-Site connectivity (Site 1 X Site 2, etc.)             |
|                                                                               |
+===============================================================================+
```

### 2.2 MPLS Requirements

| Requirement | Specification |
|-------------|---------------|
| **Bandwidth per Site** | Minimum 100 Mbps (recommend 1 Gbps) |
| **Latency** | < 50ms round-trip (Access Manager ↔ Bastion) |
| **Redundancy** | Dual MPLS paths recommended per site |
| **QoS** | Session traffic priority (DSCP EF/AF41) |
| **MTU** | 1500 bytes minimum (jumbo frames 9000 recommended) |
| **BGP/OSPF** | Dynamic routing required for failover |

### 2.3 MPLS IP Addressing

| Network | CIDR | Purpose | Location |
|---------|------|---------|----------|
| **Access Manager DC-A** | 10.100.1.0/24 | Access Manager 1 | Datacenter A |
| **Access Manager DC-B** | 10.100.2.0/24 | Access Manager 2 | Datacenter B |
| **Site 1 (Paris DC-P1)** | 10.10.1.0/24 | HAProxy, Bastion, RDS | Paris Building A |
| **Site 2 (Paris DC-P2)** | 10.10.2.0/24 | HAProxy, Bastion, RDS | Paris Building B |
| **Site 3 (Paris DC-P3)** | 10.10.3.0/24 | HAProxy, Bastion, RDS | Paris Building C |
| **Site 4 (Paris DC-P4)** | 10.10.4.0/24 | HAProxy, Bastion, RDS | Paris Building D |
| **Site 5 (Paris DC-P5)** | 10.10.5.0/24 | HAProxy, Bastion, RDS | Paris Building E |
| **Authentication Services** | 10.20.0.0/24 | FortiAuthenticator, AD/LDAP | Shared Infrastructure |
| **Target Systems (Win)** | 10.30.0.0/16 | Windows Server 2022 | Production |
| **Target Systems (Linux)** | 10.40.0.0/16 | RHEL 9/10 | Production |

---

## Site-Specific Network Details

### 3.1 Access Manager Datacenters

#### DC-A (Primary Access Manager)

| Component | IP Address | VLAN | Purpose |
|-----------|------------|------|---------|
| Access Manager 1 | 10.100.1.10 | VLAN 100 | SSO, MFA, Session Brokering |
| AM1 Management | 10.100.1.11 | VLAN 101 | Admin interface (out-of-band) |
| AM1 Gateway | 10.100.1.1 | VLAN 100 | Default gateway (MPLS router) |

#### DC-B (Secondary Access Manager)

| Component | IP Address | VLAN | Purpose |
|-----------|------------|------|---------|
| Access Manager 2 | 10.100.2.10 | VLAN 200 | SSO, MFA, Session Brokering |
| AM2 Management | 10.100.2.11 | VLAN 201 | Admin interface (out-of-band) |
| AM2 Gateway | 10.100.2.1 | VLAN 200 | Default gateway (MPLS router) |

### 3.2 Site 1 (Paris DC-P1)

| Component | IP Address | VLAN | Purpose |
|-----------|------------|------|---------|
| Fortigate Firewall | 10.10.1.1 | VLAN 11 | Perimeter security |
| HAProxy-1 (Primary) | 10.10.1.5 | VLAN 11 | Load balancer |
| HAProxy-2 (Backup) | 10.10.1.6 | VLAN 11 | Load balancer (VRRP) |
| HAProxy VIP | 10.10.1.100 | VLAN 11 | Virtual IP (user entry point) |
| WALLIX Bastion-1 | 10.10.1.11 | VLAN 11 | HA cluster node 1 |
| WALLIX Bastion-2 | 10.10.1.12 | VLAN 11 | HA cluster node 2 |
| WALLIX RDS | 10.10.1.30 | VLAN 11 | Jump host (OT RemoteApp) |
| Default Gateway | 10.10.1.1 | VLAN 11 | Fortigate internal interface |

### 3.3 Site 2 (Paris DC-P2)

| Component | IP Address | VLAN | Purpose |
|-----------|------------|------|---------|
| Fortigate Firewall | 10.10.2.1 | VLAN 12 | Perimeter security |
| HAProxy-1 (Primary) | 10.10.2.5 | VLAN 12 | Load balancer |
| HAProxy-2 (Backup) | 10.10.2.6 | VLAN 12 | Load balancer (VRRP) |
| HAProxy VIP | 10.10.2.100 | VLAN 12 | Virtual IP (user entry point) |
| WALLIX Bastion-1 | 10.10.2.11 | VLAN 12 | HA cluster node 1 |
| WALLIX Bastion-2 | 10.10.2.12 | VLAN 12 | HA cluster node 2 |
| WALLIX RDS | 10.10.2.30 | VLAN 12 | Jump host (OT RemoteApp) |
| Default Gateway | 10.10.2.1 | VLAN 12 | Fortigate internal interface |

### 3.4 Site 3 (Paris DC-P3)

| Component | IP Address | VLAN | Purpose |
|-----------|------------|------|---------|
| Fortigate Firewall | 10.10.3.1 | VLAN 13 | Perimeter security |
| HAProxy-1 (Primary) | 10.10.3.5 | VLAN 13 | Load balancer |
| HAProxy-2 (Backup) | 10.10.3.6 | VLAN 13 | Load balancer (VRRP) |
| HAProxy VIP | 10.10.3.100 | VLAN 13 | Virtual IP (user entry point) |
| WALLIX Bastion-1 | 10.10.3.11 | VLAN 13 | HA cluster node 1 |
| WALLIX Bastion-2 | 10.10.3.12 | VLAN 13 | HA cluster node 2 |
| WALLIX RDS | 10.10.3.30 | VLAN 13 | Jump host (OT RemoteApp) |
| Default Gateway | 10.10.3.1 | VLAN 13 | Fortigate internal interface |

### 3.5 Site 4 (Paris DC-P4)

| Component | IP Address | VLAN | Purpose |
|-----------|------------|------|---------|
| Fortigate Firewall | 10.10.4.1 | VLAN 14 | Perimeter security |
| HAProxy-1 (Primary) | 10.10.4.5 | VLAN 14 | Load balancer |
| HAProxy-2 (Backup) | 10.10.4.6 | VLAN 14 | Load balancer (VRRP) |
| HAProxy VIP | 10.10.4.100 | VLAN 14 | Virtual IP (user entry point) |
| WALLIX Bastion-1 | 10.10.4.11 | VLAN 14 | HA cluster node 1 |
| WALLIX Bastion-2 | 10.10.4.12 | VLAN 14 | HA cluster node 2 |
| WALLIX RDS | 10.10.4.30 | VLAN 14 | Jump host (OT RemoteApp) |
| Default Gateway | 10.10.4.1 | VLAN 14 | Fortigate internal interface |

### 3.6 Site 5 (Paris DC-P5)

| Component | IP Address | VLAN | Purpose |
|-----------|------------|------|---------|
| Fortigate Firewall | 10.10.5.1 | VLAN 15 | Perimeter security |
| HAProxy-1 (Primary) | 10.10.5.5 | VLAN 15 | Load balancer |
| HAProxy-2 (Backup) | 10.10.5.6 | VLAN 15 | Load balancer (VRRP) |
| HAProxy VIP | 10.10.5.100 | VLAN 15 | Virtual IP (user entry point) |
| WALLIX Bastion-1 | 10.10.5.11 | VLAN 15 | HA cluster node 1 |
| WALLIX Bastion-2 | 10.10.5.12 | VLAN 15 | HA cluster node 2 |
| WALLIX RDS | 10.10.5.30 | VLAN 15 | Jump host (OT RemoteApp) |
| Default Gateway | 10.10.5.1 | VLAN 15 | Fortigate internal interface |

### 3.7 Shared Infrastructure

| Component | IP Address | VLAN | Purpose |
|-----------|------------|------|---------|
| FortiAuthenticator (Primary) | 10.20.0.60 | VLAN 20 | MFA (RADIUS) |
| FortiAuthenticator (Secondary) | 10.20.0.61 | VLAN 20 | MFA (RADIUS backup) |
| Active Directory DC1 | 10.20.0.10 | VLAN 20 | LDAP/authentication |
| Active Directory DC2 | 10.20.0.11 | VLAN 20 | LDAP/authentication (backup) |
| NTP Server 1 | 10.20.0.20 | VLAN 20 | Time synchronization |
| NTP Server 2 | 10.20.0.21 | VLAN 20 | Time synchronization (backup) |
| SIEM (Splunk/Elastic) | 10.20.0.50 | VLAN 20 | Log aggregation |

---

## Complete Port Matrix

### 4.1 User Access Flows

#### Users → HAProxy (VIP)

| Source | Destination | Port | Protocol | Purpose |
|--------|-------------|------|----------|---------|
| End Users | HAProxy VIP (10.10.X.100) | 443 | TCP/HTTPS | Web UI, API access |
| End Users | HAProxy VIP (10.10.X.100) | 22 | TCP/SSH | SSH proxy sessions |
| End Users | HAProxy VIP (10.10.X.100) | 3389 | TCP/RDP | RDP proxy sessions |
| End Users | HAProxy VIP (10.10.X.100) | 80 | TCP/HTTP | HTTP → HTTPS redirect |

#### HAProxy → WALLIX Bastion (Backend)

| Source | Destination | Port | Protocol | Purpose |
|--------|-------------|------|----------|---------|
| HAProxy-1 (10.10.X.5) | Bastion-1 (10.10.X.11) | 443 | TCP/HTTPS | Load balanced HTTPS |
| HAProxy-1 (10.10.X.5) | Bastion-2 (10.10.X.12) | 443 | TCP/HTTPS | Load balanced HTTPS |
| HAProxy-1 (10.10.X.5) | Bastion-1 (10.10.X.11) | 22 | TCP/SSH | SSH health check |
| HAProxy-2 (10.10.X.6) | Bastion-1 (10.10.X.11) | 443 | TCP/HTTPS | Backup HAProxy path |
| HAProxy-2 (10.10.X.6) | Bastion-2 (10.10.X.12) | 443 | TCP/HTTPS | Backup HAProxy path |

### 4.2 Access Manager Integration

#### Access Manager → WALLIX Bastion (MPLS)

| Source | Destination | Port | Protocol | Purpose |
|--------|-------------|------|----------|---------|
| AM1 (10.100.1.10) | Bastion Site 1-5 | 443 | TCP/HTTPS | SSO callbacks, session brokering |
| AM1 (10.100.1.10) | Bastion Site 1-5 | 22 | TCP/SSH | SSH session brokering (optional) |
| AM2 (10.100.2.10) | Bastion Site 1-5 | 443 | TCP/HTTPS | SSO callbacks, session brokering |
| AM2 (10.100.2.10) | Bastion Site 1-5 | 22 | TCP/SSH | SSH session brokering (optional) |

#### WALLIX Bastion → Access Manager (MPLS)

| Source | Destination | Port | Protocol | Purpose |
|--------|-------------|------|----------|---------|
| Bastion Site 1-5 | AM1 (10.100.1.10) | 443 | TCP/HTTPS | SSO authentication requests |
| Bastion Site 1-5 | AM2 (10.100.2.10) | 443 | TCP/HTTPS | SSO authentication (failover) |
| Bastion Site 1-5 | AM1 (10.100.1.10) | 443 | TCP/HTTPS | License check-in/check-out |

#### Access Manager HA (DC-A ↔ DC-B)

| Source | Destination | Port | Protocol | Purpose |
|--------|-------------|------|----------|---------|
| AM1 (10.100.1.10) | AM2 (10.100.2.10) | 443 | TCP/HTTPS | Configuration sync |
| AM1 (10.100.1.10) | AM2 (10.100.2.10) | 3306 | TCP/MariaDB | Database replication |
| AM1 (10.100.1.10) | AM2 (10.100.2.10) | 5404-5406 | UDP/Corosync | Cluster heartbeat |

### 4.3 Authentication & MFA

#### WALLIX Bastion → FortiAuthenticator

| Source | Destination | Port | Protocol | Purpose |
|--------|-------------|------|----------|---------|
| Bastion Site 1-5 | FortiAuth (10.20.0.60) | 1812 | UDP/RADIUS | User authentication (MFA) |
| Bastion Site 1-5 | FortiAuth (10.20.0.60) | 1813 | UDP/RADIUS | Accounting/audit logs |
| Bastion Site 1-5 | FortiAuth (10.20.0.61) | 1812 | UDP/RADIUS | Failover authentication |
| Bastion Site 1-5 | FortiAuth (10.20.0.61) | 1813 | UDP/RADIUS | Failover accounting |

#### WALLIX Bastion → Active Directory

| Source | Destination | Port | Protocol | Purpose |
|--------|-------------|------|----------|---------|
| Bastion Site 1-5 | AD DC1 (10.20.0.10) | 389 | TCP/LDAP | User/group lookups |
| Bastion Site 1-5 | AD DC1 (10.20.0.10) | 636 | TCP/LDAPS | Secure LDAP (preferred) |
| Bastion Site 1-5 | AD DC1 (10.20.0.10) | 3268 | TCP/GC | Global Catalog queries |
| Bastion Site 1-5 | AD DC1 (10.20.0.10) | 3269 | TCP/GC-SSL | Secure Global Catalog |
| Bastion Site 1-5 | AD DC1 (10.20.0.10) | 88 | TCP/UDP | Kerberos authentication |
| Bastion Site 1-5 | AD DC2 (10.20.0.11) | 636 | TCP/LDAPS | Failover LDAP |

#### FortiAuthenticator → Active Directory

| Source | Destination | Port | Protocol | Purpose |
|--------|-------------|------|----------|---------|
| FortiAuth (10.20.0.60) | AD DC1 (10.20.0.10) | 389 | TCP/LDAP | User synchronization |
| FortiAuth (10.20.0.60) | AD DC1 (10.20.0.10) | 636 | TCP/LDAPS | Secure user sync |

### 4.4 WALLIX Bastion HA Cluster (Per Site)

#### Bastion-1 ↔ Bastion-2 (HA Sync)

| Source | Destination | Port | Protocol | Purpose |
|--------|-------------|------|----------|---------|
| Bastion-1 (10.10.X.11) | Bastion-2 (10.10.X.12) | 3306 | TCP/MariaDB | Database replication |
| Bastion-2 (10.10.X.12) | Bastion-1 (10.10.X.11) | 3306 | TCP/MariaDB | Database replication |
| Bastion-1 (10.10.X.11) | Bastion-2 (10.10.X.12) | 2224 | TCP/PCSD | Pacemaker management |
| Bastion-1 (10.10.X.11) | Bastion-2 (10.10.X.12) | 3121 | TCP/Pacemaker | Cluster communication |
| Bastion-1 (10.10.X.11) | Bastion-2 (10.10.X.12) | 5404 | UDP/Corosync | Cluster multicast |
| Bastion-1 (10.10.X.11) | Bastion-2 (10.10.X.12) | 5405 | UDP/Corosync | Cluster unicast |
| Bastion-1 (10.10.X.11) | Bastion-2 (10.10.X.12) | 5406 | UDP/Corosync | Cluster failover |

**CRITICAL**: These ports MUST be isolated on a dedicated VLAN or physically separate network for security.

### 4.5 HAProxy HA (Per Site)

#### HAProxy-1 ↔ HAProxy-2 (VRRP)

| Source | Destination | Port | Protocol | Purpose |
|--------|-------------|------|----------|---------|
| HAProxy-1 (10.10.X.5) | HAProxy-2 (10.10.X.6) | 112 | IP/VRRP | Keepalived heartbeat |

**Note**: VRRP uses IP protocol 112 (not TCP/UDP). Ensure firewalls allow this protocol.

### 4.6 Target System Access

#### WALLIX Bastion → Windows Targets

| Source | Destination | Port | Protocol | Purpose |
|--------|-------------|------|----------|---------|
| Bastion Site 1-5 | Windows (10.30.0.0/16) | 3389 | TCP/RDP | Remote Desktop sessions |
| Bastion Site 1-5 | Windows (10.30.0.0/16) | 5985 | TCP/WinRM | Password rotation (HTTP) |
| Bastion Site 1-5 | Windows (10.30.0.0/16) | 5986 | TCP/WinRM | Password rotation (HTTPS) |

#### WALLIX Bastion → Linux Targets

| Source | Destination | Port | Protocol | Purpose |
|--------|-------------|------|----------|---------|
| Bastion Site 1-5 | RHEL (10.40.0.0/16) | 22 | TCP/SSH | SSH sessions, password rotation |

#### WALLIX RDS → OT Targets

| Source | Destination | Port | Protocol | Purpose |
|--------|-------------|------|----------|---------|
| RDS (10.10.X.30) | OT Windows | 3389 | TCP/RDP | RemoteApp RDP sessions |

### 4.7 Management & Monitoring

#### WALLIX Bastion → NTP Servers

| Source | Destination | Port | Protocol | Purpose |
|--------|-------------|------|----------|---------|
| Bastion Site 1-5 | NTP1 (10.20.0.20) | 123 | UDP/NTP | Time synchronization |
| Bastion Site 1-5 | NTP2 (10.20.0.21) | 123 | UDP/NTP | Time sync (backup) |
| HAProxy Site 1-5 | NTP1 (10.20.0.20) | 123 | UDP/NTP | Time synchronization |

#### WALLIX Bastion → SIEM

| Source | Destination | Port | Protocol | Purpose |
|--------|-------------|------|----------|---------|
| Bastion Site 1-5 | SIEM (10.20.0.50) | 514 | UDP/Syslog | Audit log forwarding |
| Bastion Site 1-5 | SIEM (10.20.0.50) | 6514 | TCP/Syslog-TLS | Secure log forwarding |

#### Monitoring → WALLIX Bastion

| Source | Destination | Port | Protocol | Purpose |
|--------|-------------|------|----------|---------|
| Prometheus | Bastion Site 1-5 | 9100 | TCP/HTTP | Node Exporter metrics |
| SNMP NMS | Bastion Site 1-5 | 161 | UDP/SNMP | SNMP queries |

#### WALLIX Bastion → SMTP (Email Alerts)

| Source | Destination | Port | Protocol | Purpose |
|--------|-------------|------|----------|---------|
| Bastion Site 1-5 | Mail Server | 25 | TCP/SMTP | Email notifications |
| Bastion Site 1-5 | Mail Server | 587 | TCP/SMTP | SMTP with STARTTLS |

---

## Firewall Rules

### 5.1 Fortigate Firewall Rules (Per Site)

#### Policy 1: User Access (Inbound)

```
Source Zone: WAN/MPLS
Source Address: Any (authenticated users)
Destination Zone: DMZ
Destination Address: HAProxy VIP (10.10.X.100)
Service: HTTPS (443), SSH (22), RDP (3389)
Action: ACCEPT
NAT: None (routed)
IPS/AV: Enable
Logging: Enable
```

#### Policy 2: HAProxy to Bastion (Backend Health Checks)

```
Source Zone: DMZ
Source Address: HAProxy-1 (10.10.X.5), HAProxy-2 (10.10.X.6)
Destination Zone: Management
Destination Address: Bastion-1 (10.10.X.11), Bastion-2 (10.10.X.12)
Service: HTTPS (443), SSH (22)
Action: ACCEPT
NAT: None
Logging: Disable (high frequency)
```

#### Policy 3: Bastion to Access Manager (MPLS)

```
Source Zone: Management
Source Address: Bastion-1 (10.10.X.11), Bastion-2 (10.10.X.12)
Destination Zone: MPLS
Destination Address: AM1 (10.100.1.10), AM2 (10.100.2.10)
Service: HTTPS (443)
Action: ACCEPT
NAT: None (MPLS routed)
Logging: Enable
```

#### Policy 4: Access Manager to Bastion (MPLS)

```
Source Zone: MPLS
Source Address: AM1 (10.100.1.10), AM2 (10.100.2.10)
Destination Zone: Management
Destination Address: Bastion-1 (10.10.X.11), Bastion-2 (10.10.X.12)
Service: HTTPS (443), SSH (22)
Action: ACCEPT
NAT: None
Logging: Enable
```

#### Policy 5: Bastion to FortiAuthenticator

```
Source Zone: Management
Source Address: Bastion-1 (10.10.X.11), Bastion-2 (10.10.X.12)
Destination Zone: Authentication
Destination Address: FortiAuth (10.20.0.60, 10.20.0.61)
Service: RADIUS (1812/1813 UDP)
Action: ACCEPT
NAT: None
Logging: Enable
```

#### Policy 6: Bastion to Active Directory

```
Source Zone: Management
Source Address: Bastion-1 (10.10.X.11), Bastion-2 (10.10.X.12)
Destination Zone: Authentication
Destination Address: AD DC1 (10.20.0.10), AD DC2 (10.20.0.11)
Service: LDAPS (636), Global Catalog SSL (3269), Kerberos (88 TCP/UDP)
Action: ACCEPT
NAT: None
Logging: Enable
```

#### Policy 7: Bastion to Target Systems

```
Source Zone: Management
Source Address: Bastion-1 (10.10.X.11), Bastion-2 (10.10.X.12), RDS (10.10.X.30)
Destination Zone: Production
Destination Address: Windows (10.30.0.0/16), RHEL (10.40.0.0/16)
Service: RDP (3389), SSH (22), WinRM (5985/5986)
Action: ACCEPT
NAT: None
Logging: Enable (session recordings handled by WALLIX)
```

#### Policy 8: Bastion HA Cluster (Isolate on Dedicated VLAN)

```
Source Zone: HA_Cluster
Source Address: Bastion-1 (10.10.X.11)
Destination Zone: HA_Cluster
Destination Address: Bastion-2 (10.10.X.12)
Service: MariaDB (3306), PCSD (2224), Pacemaker (3121), Corosync (5404-5406 UDP)
Action: ACCEPT
NAT: None
Logging: Enable
```

**CRITICAL**: Create a dedicated VLAN/subnet for HA traffic (e.g., 10.10.X.128/27) isolated from user traffic.

#### Policy 9: Bastion to NTP

```
Source Zone: Management
Source Address: Bastion-1 (10.10.X.11), Bastion-2 (10.10.X.12), HAProxy (10.10.X.5/6)
Destination Zone: Infrastructure
Destination Address: NTP1 (10.20.0.20), NTP2 (10.20.0.21)
Service: NTP (123 UDP)
Action: ACCEPT
NAT: None
Logging: Disable
```

#### Policy 10: Bastion to SIEM

```
Source Zone: Management
Source Address: Bastion-1 (10.10.X.11), Bastion-2 (10.10.X.12)
Destination Zone: Infrastructure
Destination Address: SIEM (10.20.0.50)
Service: Syslog (514 UDP), Syslog-TLS (6514 TCP)
Action: ACCEPT
NAT: None
Logging: Disable
```

#### Policy 11: DENY All (Default Drop)

```
Source Zone: Any
Source Address: Any
Destination Zone: Any
Destination Address: Any
Service: Any
Action: DENY
Logging: Enable (security events)
```

### 5.2 ACL Rules Summary (Simplified View)

```
+===============================================================================+
|  FIREWALL ACL SUMMARY                                                         |
+===============================================================================+
|                                                                               |
|  ALLOW: Users → HAProxy VIP (443, 22, 3389)                                  |
|  ALLOW: HAProxy → Bastion (443, 22)                                          |
|  ALLOW: Bastion → Access Manager (443) via MPLS                              |
|  ALLOW: Access Manager → Bastion (443, 22) via MPLS                          |
|  ALLOW: Bastion → FortiAuthenticator (1812/1813 UDP)                         |
|  ALLOW: Bastion → Active Directory (636, 3269, 88)                           |
|  ALLOW: Bastion → Targets (3389, 22, 5985/5986)                              |
|  ALLOW: Bastion-1 ↔ Bastion-2 (3306, 2224, 3121, 5404-5406) [HA VLAN]       |
|  ALLOW: HAProxy-1 ↔ HAProxy-2 (IP proto 112) [VRRP]                          |
|  ALLOW: Bastion → NTP (123 UDP)                                              |
|  ALLOW: Bastion → SIEM (514 UDP, 6514 TCP)                                   |
|  ALLOW: Monitoring → Bastion (9100, 161)                                     |
|                                                                               |
|  DENY: Bastion Site 1 → Bastion Site 2 (NO direct site-to-site)             |
|  DENY: All other traffic (default drop)                                      |
|                                                                               |
+===============================================================================+
```

---

## DNS Requirements

### 6.1 Forward DNS Records (A/AAAA)

#### Access Manager Datacenters

```
am1.wallix.company.local        A    10.100.1.10   (Access Manager DC-A)
am2.wallix.company.local        A    10.100.2.10   (Access Manager DC-B)
am.wallix.company.local         A    10.100.1.10   (Primary alias)
am.wallix.company.local         A    10.100.2.10   (Secondary alias - round robin)
```

#### Site 1 (Paris DC-P1)

```
bastion-site1.wallix.company.local        A    10.10.1.100   (HAProxy VIP)
haproxy1-site1.wallix.company.local       A    10.10.1.5     (HAProxy Primary)
haproxy2-site1.wallix.company.local       A    10.10.1.6     (HAProxy Backup)
bastion1-site1.wallix.company.local       A    10.10.1.11    (Bastion Node 1)
bastion2-site1.wallix.company.local       A    10.10.1.12    (Bastion Node 2)
rds-site1.wallix.company.local            A    10.10.1.30    (RDS Jump Host)
```

#### Site 2 (Paris DC-P2)

```
bastion-site2.wallix.company.local        A    10.10.2.100
haproxy1-site2.wallix.company.local       A    10.10.2.5
haproxy2-site2.wallix.company.local       A    10.10.2.6
bastion1-site2.wallix.company.local       A    10.10.2.11
bastion2-site2.wallix.company.local       A    10.10.2.12
rds-site2.wallix.company.local            A    10.10.2.30
```

#### Site 3 (Paris DC-P3)

```
bastion-site3.wallix.company.local        A    10.10.3.100
haproxy1-site3.wallix.company.local       A    10.10.3.5
haproxy2-site3.wallix.company.local       A    10.10.3.6
bastion1-site3.wallix.company.local       A    10.10.3.11
bastion2-site3.wallix.company.local       A    10.10.3.12
rds-site3.wallix.company.local            A    10.10.3.30
```

#### Site 4 (Paris DC-P4)

```
bastion-site4.wallix.company.local        A    10.10.4.100
haproxy1-site4.wallix.company.local       A    10.10.4.5
haproxy2-site4.wallix.company.local       A    10.10.4.6
bastion1-site4.wallix.company.local       A    10.10.4.11
bastion2-site4.wallix.company.local       A    10.10.4.12
rds-site4.wallix.company.local            A    10.10.4.30
```

#### Site 5 (Paris DC-P5)

```
bastion-site5.wallix.company.local        A    10.10.5.100
haproxy1-site5.wallix.company.local       A    10.10.5.5
haproxy2-site5.wallix.company.local       A    10.10.5.6
bastion1-site5.wallix.company.local       A    10.10.5.11
bastion2-site5.wallix.company.local       A    10.10.5.12
rds-site5.wallix.company.local            A    10.10.5.30
```

#### Shared Infrastructure

```
fortiauth.wallix.company.local            A    10.20.0.60    (Primary)
fortiauth-ha.wallix.company.local         A    10.20.0.61    (Secondary)
ntp1.wallix.company.local                 A    10.20.0.20
ntp2.wallix.company.local                 A    10.20.0.21
siem.wallix.company.local                 A    10.20.0.50
```

### 6.2 Reverse DNS Records (PTR)

```
10.100.1.10    PTR    am1.wallix.company.local
10.100.2.10    PTR    am2.wallix.company.local

10.10.1.100    PTR    bastion-site1.wallix.company.local
10.10.1.11     PTR    bastion1-site1.wallix.company.local
10.10.1.12     PTR    bastion2-site1.wallix.company.local

10.10.2.100    PTR    bastion-site2.wallix.company.local
10.10.2.11     PTR    bastion1-site2.wallix.company.local
10.10.2.12     PTR    bastion2-site2.wallix.company.local

10.10.3.100    PTR    bastion-site3.wallix.company.local
10.10.3.11     PTR    bastion1-site3.wallix.company.local
10.10.3.12     PTR    bastion2-site3.wallix.company.local

10.10.4.100    PTR    bastion-site4.wallix.company.local
10.10.4.11     PTR    bastion1-site4.wallix.company.local
10.10.4.12     PTR    bastion2-site4.wallix.company.local

10.10.5.100    PTR    bastion-site5.wallix.company.local
10.10.5.11     PTR    bastion1-site5.wallix.company.local
10.10.5.12     PTR    bastion2-site5.wallix.company.local

10.20.0.60     PTR    fortiauth.wallix.company.local
10.20.0.61     PTR    fortiauth-ha.wallix.company.local
```

### 6.3 SSL Certificate Requirements

#### Wildcard Certificate (Recommended)

```
Common Name (CN): *.wallix.company.local
Subject Alternative Names (SAN):
  - *.wallix.company.local
  - wallix.company.local
  - bastion-site1.wallix.company.local
  - bastion-site2.wallix.company.local
  - bastion-site3.wallix.company.local
  - bastion-site4.wallix.company.local
  - bastion-site5.wallix.company.local
  - am1.wallix.company.local
  - am2.wallix.company.local
```

**Alternatively**: Use individual certificates per site with Let's Encrypt or internal CA.

---

## NTP Configuration

### 7.1 NTP Server Hierarchy

```
+===============================================================================+
|  NTP TIME SYNCHRONIZATION HIERARCHY                                           |
+===============================================================================+
|                                                                               |
|  Stratum 1 (External NTP Pool)                                                |
|       |                                                                       |
|       v                                                                       |
|  Stratum 2 (Internal NTP Servers)                                             |
|  +---------------------------+                                                |
|  | NTP1: 10.20.0.20          |                                                |
|  | NTP2: 10.20.0.21          |                                                |
|  +-------------+-------------+                                                |
|                |                                                              |
|                v                                                              |
|  Stratum 3 (All WALLIX Components)                                            |
|  +---------------------------+                                                |
|  | - Access Manager 1 & 2    |                                                |
|  | - Bastion Nodes (All)     |                                                |
|  | - HAProxy Servers (All)   |                                                |
|  | - RDS Jump Hosts (All)    |                                                |
|  +---------------------------+                                                |
|                                                                               |
+===============================================================================+
```

### 7.2 NTP Configuration (Chrony)

#### /etc/chrony/chrony.conf (All WALLIX Components)

```bash
# Primary NTP servers
server 10.20.0.20 iburst prefer
server 10.20.0.21 iburst

# Fallback to public NTP pool (internet required)
pool 2.debian.pool.ntp.org iburst

# Allow large time jumps on first sync
makestep 1.0 3

# Drift file
driftfile /var/lib/chrony/drift

# Log configuration
logdir /var/log/chrony
log measurements statistics tracking
```

#### Verify NTP Synchronization

```bash
# Check NTP sync status
chronyc tracking

# List NTP sources
chronyc sources -v

# Expected output: Leap status should be "Normal"
# System time should be within 100ms of source
```

### 7.3 Timezone Configuration

**All servers must use UTC timezone for consistency:**

```bash
# Set timezone to UTC
timedatectl set-timezone UTC

# Verify
timedatectl status
# Expected: Time zone: Etc/UTC (UTC, +0000)
```

---

## Network Testing Procedures

### 8.1 Pre-Deployment Network Validation

#### Test 1: MPLS Connectivity (Access Manager ↔ Bastion)

```bash
# From Access Manager 1 (10.100.1.10)
for site in 1 2 3 4 5; do
  echo "Testing Site $site:"
  ping -c 4 10.10.$site.11
  curl -k -m 5 https://10.10.$site.11/health || echo "HTTPS check failed"
done

# Expected: All pings succeed, HTTPS health checks return 200 OK
```

#### Test 2: Bastion to Access Manager (Reverse Path)

```bash
# From Bastion Site 1 (10.10.1.11)
echo "Testing Access Manager 1:"
ping -c 4 10.100.1.10
curl -k -m 5 https://10.100.1.10/health

echo "Testing Access Manager 2:"
ping -c 4 10.100.2.10
curl -k -m 5 https://10.100.2.10/health
```

#### Test 3: Verify NO Direct Site-to-Site Connectivity

```bash
# From Bastion Site 1 (10.10.1.11)
# Attempt to reach Site 2 - should FAIL
ping -c 2 10.10.2.11 && echo "ERROR: Site-to-site reachable!" || echo "OK: No site-to-site route"

# Expected: Destination Host Unreachable or Timeout (CORRECT)
```

#### Test 4: HAProxy VRRP Functionality

```bash
# From HAProxy-1 (10.10.1.5)
ip addr show | grep 10.10.1.100
# Expected: VIP present on primary

# Simulate HAProxy-1 failure (stop Keepalived)
systemctl stop keepalived

# From HAProxy-2 (10.10.1.6)
ip addr show | grep 10.10.1.100
# Expected: VIP migrated to backup within 3 seconds
```

#### Test 5: Bastion HA Cluster Communication

```bash
# From Bastion-1 (10.10.1.11)
# Test MariaDB replication port
nc -zv 10.10.1.12 3306
# Expected: Connection succeeded

# Test Pacemaker PCSD port
nc -zv 10.10.1.12 2224
# Expected: Connection succeeded

# Test Corosync ports (UDP)
timeout 2 nc -uzv 10.10.1.12 5405
# Expected: Connection succeeded (or timeout with UDP)
```

#### Test 6: FortiAuthenticator RADIUS Connectivity

```bash
# From Bastion Site 1 (10.10.1.11)
# Test RADIUS authentication port
nc -uzv 10.20.0.60 1812
# Expected: Connection succeeded

# Use radtest utility (if available)
radtest testuser testpass 10.20.0.60 0 sharedsecret
# Expected: Access-Accept or Access-Reject (not timeout)
```

#### Test 7: Active Directory LDAPS Connectivity

```bash
# From Bastion Site 1 (10.10.1.11)
# Test LDAPS port
openssl s_client -connect 10.20.0.10:636 -showcerts
# Expected: Certificate chain displayed, connection established

# Test LDAP query (requires ldapsearch)
ldapsearch -H ldaps://10.20.0.10:636 -x -b "dc=company,dc=local" "(objectclass=*)" -LLL
# Expected: LDAP entries returned
```

#### Test 8: NTP Time Synchronization

```bash
# From all WALLIX components
chronyc tracking
# Expected: "Leap status: Normal", Reference ID not 0.0.0.0

chronyc sources
# Expected: At least one source with '*' (synchronized)

# Check time offset
chronyc sourcestats
# Expected: Offset < 100ms
```

#### Test 9: DNS Resolution (Forward and Reverse)

```bash
# Forward DNS lookups
nslookup bastion-site1.wallix.company.local
nslookup am1.wallix.company.local
# Expected: Correct IP addresses returned

# Reverse DNS lookups
nslookup 10.10.1.11
nslookup 10.100.1.10
# Expected: Correct FQDNs returned
```

#### Test 10: SSL Certificate Validation

```bash
# Test HAProxy VIP certificate
echo | openssl s_client -connect 10.10.1.100:443 -servername bastion-site1.wallix.company.local 2>/dev/null | openssl x509 -noout -text
# Expected: Certificate CN/SAN matches domain, valid dates

# Check certificate chain
echo | openssl s_client -connect 10.10.1.100:443 -showcerts
# Expected: Complete chain with intermediate CA
```

### 8.2 Bandwidth and Latency Testing

#### Test 11: MPLS Link Bandwidth (iPerf3)

```bash
# On Access Manager 1 (10.100.1.10) - Server Mode
iperf3 -s -p 5201

# On Bastion Site 1 (10.10.1.11) - Client Mode
iperf3 -c 10.100.1.10 -p 5201 -t 30 -P 4
# Expected: Throughput >= 100 Mbps (preferably 1 Gbps)
```

#### Test 12: MPLS Latency Testing

```bash
# From Bastion Site 1 to Access Manager 1
ping -c 100 10.100.1.10 | tail -1
# Expected: avg < 50ms

# MTR (My Traceroute) for detailed path analysis
mtr -r -c 50 10.100.1.10
# Expected: Low packet loss (< 0.5%), consistent latency
```

#### Test 13: Jitter Testing (VoIP-style)

```bash
# Use fping for jitter measurement
fping -C 100 -q 10.100.1.10 2>&1 | tail -1
# Expected: Low jitter (< 10ms variation)
```

### 8.3 Firewall Rule Validation

#### Test 14: Allowed Traffic Verification

```bash
# From User Workstation to HAProxy VIP
curl -k https://10.10.1.100/health
# Expected: HTTP 200 OK

# From Bastion to Target (Windows RDP)
nc -zv 10.30.0.10 3389
# Expected: Connection succeeded

# From Bastion to Target (Linux SSH)
nc -zv 10.40.0.10 22
# Expected: Connection succeeded
```

#### Test 15: Blocked Traffic Verification (Security)

```bash
# Attempt Site-to-Site direct access (should FAIL)
# From Bastion Site 1 (10.10.1.11)
nc -zv 10.10.2.11 443
# Expected: Connection timeout or refused (CORRECT)

# Attempt direct Bastion HA port access from external (should FAIL)
# From User Workstation
nc -zv 10.10.1.11 3306
# Expected: Connection refused (firewall blocked)

# Attempt HAProxy stats access from untrusted network (should FAIL)
curl -k http://10.10.1.5:8404/stats
# Expected: Connection timeout or refused if not on management network
```

### 8.4 End-to-End User Session Testing

#### Test 16: SSH Proxy Session

```bash
# From user workstation
ssh -p 22 user@bastion-site1.wallix.company.local
# Expected: WALLIX login prompt, MFA challenge, successful authentication
```

#### Test 17: RDP Proxy Session

```bash
# From Windows workstation
mstsc /v:bastion-site1.wallix.company.local:3389
# Expected: WALLIX RDP gateway, credential prompt, target desktop displayed
```

#### Test 18: Web UI Access

```bash
# From browser
https://bastion-site1.wallix.company.local
# Expected: WALLIX web UI login page, valid SSL certificate, no errors
```

### 8.5 Post-Deployment Continuous Monitoring

#### Test 19: Automated Health Checks (Cron)

```bash
# Create monitoring script: /usr/local/bin/wallix-health-check.sh

#!/bin/bash
LOGFILE="/var/log/wallix-health.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# Check Access Manager reachability
for AM in 10.100.1.10 10.100.2.10; do
  if ! curl -k -s -m 5 https://$AM/health > /dev/null; then
    echo "[$DATE] ERROR: Access Manager $AM unreachable" >> $LOGFILE
  fi
done

# Check FortiAuthenticator RADIUS
if ! nc -uzv -w 2 10.20.0.60 1812 2>&1 | grep -q succeeded; then
  echo "[$DATE] ERROR: FortiAuth RADIUS unreachable" >> $LOGFILE
fi

# Check HA cluster status
if ! systemctl is-active --quiet corosync; then
  echo "[$DATE] ERROR: Corosync not running" >> $LOGFILE
fi

echo "[$DATE] Health check completed" >> $LOGFILE
```

```bash
# Install cron job (every 5 minutes)
echo "*/5 * * * * /usr/local/bin/wallix-health-check.sh" | crontab -
```

---

## Network Troubleshooting Quick Reference

### Common Issues and Resolution

| Issue | Symptoms | Resolution |
|-------|----------|------------|
| **MPLS Link Down** | Cannot reach Access Manager | Check MPLS router BGP/OSPF, verify physical links |
| **HAProxy VIP Not Responding** | Users cannot connect | Check Keepalived status, verify VRRP on both nodes |
| **Bastion HA Split-Brain** | Both nodes active | Check Corosync network, verify quorum, restart cluster |
| **RADIUS Timeout** | MFA authentication fails | Verify FortiAuth reachable, check RADIUS shared secret |
| **LDAP Bind Failures** | User lookups fail | Check AD connectivity (636), verify service account credentials |
| **Session Recording Lag** | RDP/SSH sessions slow | Check disk I/O on Bastion (recording storage), verify network throughput |
| **NTP Drift** | Time skew between nodes | Check NTP server reachability, verify firewall allows UDP 123 |
| **SSL Certificate Errors** | Browser warnings | Verify certificate CN/SAN matches FQDN, check expiration date |

### Network Diagnostics Commands

```bash
# Layer 2: ARP table
ip neigh show

# Layer 3: Routing table
ip route show

# Layer 4: Active connections
ss -tunap

# DNS resolution
dig bastion-site1.wallix.company.local

# Traceroute with TCP (bypass ICMP blocking)
tcptraceroute 10.100.1.10 443

# Packet capture (targeted)
tcpdump -i eth0 -n 'host 10.100.1.10 and port 443' -w capture.pcap

# Analyze RADIUS traffic
tcpdump -i any -n 'udp port 1812 or udp port 1813'
```

---

## References

### Internal Documentation

- [00-prerequisites.md](00-prerequisites.md) - Hardware and software requirements
- [02-ha-architecture.md](02-ha-architecture.md) - HA cluster design (Active-Active vs Active-Passive)
- [03-access-manager-integration.md](03-access-manager-integration.md) - Access Manager SSO/MFA integration
- [05-haproxy-setup.md](05-haproxy-setup.md) - HAProxy load balancer configuration
- [11-architecture-diagrams.md](11-architecture-diagrams.md) - Additional network diagrams

### External Resources

- WALLIX Bastion Network Requirements: https://pam.wallix.one/documentation/admin-doc/bastion_en_administration_guide.pdf
- FortiAuthenticator RADIUS Configuration: https://docs.fortinet.com/product/fortiauthenticator
- HAProxy VRRP Configuration: https://www.haproxy.org/
- Pacemaker Cluster Setup: https://clusterlabs.org/pacemaker/

---

**Document Version**: 1.0
**Last Updated**: February 2026
**Validated By**: Network Engineering Team
**Approval Status**: Pending Production Deployment
