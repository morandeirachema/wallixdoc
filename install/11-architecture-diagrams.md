# Architecture Diagrams and Port Reference

> Complete network diagrams, data flows, and port matrix for 5-site WALLIX Bastion deployment

---

## Document Information

| Property | Value |
|----------|-------|
| **Purpose** | Comprehensive network architecture reference |
| **Scope** | 5 Bastion sites + 2 Access Managers + FortiAuthenticator |
| **Network Type** | MPLS (private network) |
| **Version** | WALLIX Bastion 12.1.x |
| **Last Updated** | February 2026 |

---

## Table of Contents

1. [Complete MPLS Topology](#complete-mpls-topology)
2. [Per-Site Architecture](#per-site-architecture)
3. [Network Data Flows](#network-data-flows)
4. [Complete Port Matrix](#complete-port-matrix)
5. [VLAN Design](#vlan-design)
6. [IP Addressing Scheme](#ip-addressing-scheme)

---

## Complete MPLS Topology

### 1.1 Full 5-Site Deployment with Access Managers

```
+===============================================================================+
|  COMPLETE 5-SITE WALLIX BASTION DEPLOYMENT WITH ACCESS MANAGER INTEGRATION    |
+===============================================================================+
|                                                                               |
|  DATACENTER A (External)                    DATACENTER B (External)           |
|  +----------------------------+             +----------------------------+    |
|  | Access Manager 1 (Primary) |             | Access Manager 2 (Standby) |    |
|  | 10.100.1.10                |    HA       | 10.100.2.10                |    |
|  |                            |<----------->|                            |    |
|  | - SSO (SAML/OIDC)          |  Sync       | - SSO (SAML/OIDC)          |    |
|  | - MFA (RADIUS Proxy)       |  3306/TCP   | - MFA (RADIUS Proxy)       |    |
|  | - Session Broker           |  5404-6/UDP | - Session Broker           |    |
|  | - License Server           |             | - License Server           |    |
|  +-------------+--------------+             +-------------+--------------+    |
|                |                                          |                   |
|                +------------------------------------------+                   |
|                              MPLS NETWORK                                     |
|                (10 Gbps backbone, < 50ms latency)                             |
|                +------------------------------------------+                   |
|                |              |              |            |                   |
|       +--------+------+  +----+------+  +----+------+  +--+-------+           |
|       |               |  |           |  |           |  |          |           |
|  +----v-------+  +----v-------+  +---v------+  +----v------+  +---v------+    |
|  | Site 1     |  | Site 2     |  | Site 3   |  | Site 4    |  | Site 5   |    |
|  | (DC-1)     |  | (DC-2)     |  | (DC-3)   |  | (DC-4)    |  | (DC-5)   |    |
|  +------------+  +------------+  +----------+  +-----------+  +----------+    |
|                                                                               |
|  KEY CHARACTERISTICS:                                                         |
|  ===================                                                          |
|  - 5 geographically separated sites (same city, different buildings)          |
|  - NO direct Bastion-to-Bastion communication between sites                   |
|  - All inter-site traffic routed through Access Managers via MPLS             |
|  - Each site: 2x HAProxy (HA) + 2x Bastion (HA) + 1x RDS                      |
|  - MPLS provides isolated, high-bandwidth connectivity                        |
|                                                                               |
+===============================================================================+
```

### 1.2 MPLS Connectivity Matrix

```
+===============================================================================+
|  MPLS CONNECTIVITY PATHS (FULL MESH FOR AM, STAR FOR SITES)                   |
+===============================================================================+
|                                                                               |
|  Access Manager Connectivity (FULL MESH):                                     |
|  ========================================                                     |
|                                                                               |
|  AM1 (DC-A) <--MPLS--> AM2 (DC-B)        [10 Gbps, HA replication]            |
|  AM1 (DC-A) <--MPLS--> Site 1 (DC-1) [1 Gbps]                                 |
|  AM1 (DC-A) <--MPLS--> Site 2 (DC-2) [1 Gbps]                                 |
|  AM1 (DC-A) <--MPLS--> Site 3 (DC-3) [1 Gbps]                                 |
|  AM1 (DC-A) <--MPLS--> Site 4 (DC-4) [1 Gbps]                                 |
|  AM1 (DC-A) <--MPLS--> Site 5 (DC-5) [1 Gbps]                                 |
|                                                                               |
|  AM2 (DC-B) <--MPLS--> Site 1 (DC-1) [1 Gbps]                                 |
|  AM2 (DC-B) <--MPLS--> Site 2 (DC-2) [1 Gbps]                                 |
|  AM2 (DC-B) <--MPLS--> Site 3 (DC-3) [1 Gbps]                                 |
|  AM2 (DC-B) <--MPLS--> Site 4 (DC-4) [1 Gbps]                                 |
|  AM2 (DC-B) <--MPLS--> Site 5 (DC-5) [1 Gbps]                                 |
|                                                                               |
|  Site-to-Site Connectivity (BLOCKED):                                         |
|  ====================================                                         |
|                                                                               |
|  Site 1 X Site 2 [NO CONNECTIVITY]                                            |
|  Site 1 X Site 3 [NO CONNECTIVITY]                                            |
|  Site 1 X Site 4 [NO CONNECTIVITY]                                            |
|  Site 1 X Site 5 [NO CONNECTIVITY]                                            |
|  (All inter-site must route through Access Managers)                          |
|                                                                               |
|  Shared Infrastructure:                                                       |
|  ======================                                                       |
|                                                                               |
|  All Sites <--MPLS--> FortiAuthenticator (10.20.0.60/61) [1 Gbps]             |
|  All Sites <--MPLS--> Active Directory (10.20.0.10/11)   [1 Gbps]             |
|  All Sites <--MPLS--> NTP Servers (10.20.0.20/21)        [100 Mbps]           |
|  All Sites <--MPLS--> SIEM (10.20.0.50)                  [1 Gbps]             |
|                                                                               |
+===============================================================================+
```

### 1.3 Network Topology Summary

```
+===============================================================================+
|  NETWORK TOPOLOGY SUMMARY                                                     |
+===============================================================================+
|                                                                               |
|  Total Network Segments:                                                      |
|  =======================                                                      |
|                                                                               |
|  Access Manager Networks (2):                                                 |
|  - DC-A: 10.100.1.0/24  (AM1, management subnet)                              |
|  - DC-B: 10.100.2.0/24  (AM2, management subnet)                              |
|                                                                               |
|  Bastion Site Networks (5):                                                   |
|  - Site 1: 10.10.1.0/24  (HAProxy, Bastion, RDS)                              |
|  - Site 2: 10.10.2.0/24  (HAProxy, Bastion, RDS)                              |
|  - Site 3: 10.10.3.0/24  (HAProxy, Bastion, RDS)                              |
|  - Site 4: 10.10.4.0/24  (HAProxy, Bastion, RDS)                              |
|  - Site 5: 10.10.5.0/24  (HAProxy, Bastion, RDS)                              |
|                                                                               |
|  Shared Infrastructure (1):                                                   |
|  - Auth/Infrastructure: 10.20.0.0/24  (FortiAuth, AD, NTP, SIEM)              |
|                                                                               |
|  Target Networks (2):                                                         |
|  - Windows Targets: 10.30.0.0/16  (Windows Server 2022)                       |
|  - Linux Targets:   10.40.0.0/16  (RHEL 9/10)                                 |
|                                                                               |
|  Total IP Space: 10.0.0.0/8 (private network)                                 |
|                                                                               |
+===============================================================================+
```

---

## Per-Site Architecture

### 2.1 Single Site Detailed Architecture (Site 1 Example)

```
+===============================================================================+
|  SITE 1 (PARIS DC-1) - DETAILED ARCHITECTURE                                  |
+===============================================================================+
|                                                                               |
|                          MPLS Network (10 Gbps)                               |
|                                   |                                           |
|                                   v                                           |
|                     +-----------------------------+                           |
|                     |   Fortigate Firewall        |                           |
|                     |   Site Perimeter            |                           |
|                     |   10.10.1.1                 |                           |
|                     |                             |                           |
|                     |   - SSL VPN Portal          |                           |
|                     |   - IPS/IDS                 |                           |
|                     |   - DDoS Protection         |                           |
|                     +-------------+---------------+                           |
|                                   |                                           |
|                +------------------+------------------+                        |
|                |                                     |                        |
|    +-----------v-----------+             +-----------v-----------+            |
|    |   HAProxy-1 Primary   |    VRRP     |   HAProxy-2 Backup    |            |
|    |   10.10.1.5           |<----------->|   10.10.1.6           |            |
|    |                       | (Proto 112) |                       |            |
|    |   +---------------+   |             |   +---------------+   |            |
|    |   | Keepalived    |   |             |   | Keepalived    |   |            |
|    |   | VIP: 10.10.1.100  |             |   | (Standby)     |   |            |
|    |   +---------------+   |             |   +---------------+   |            |
|    |                       |             |                       |            |
|    |   +---------------+   |             |   +---------------+   |            |
|    |   | HAProxy Stats |   |             |   | HAProxy Stats |   |            |
|    |   | Port: 8404    |   |             |   | Port: 8404    |   |            |
|    |   +---------------+   |             |   +---------------+   |            |
|    +-----------+-----------+             +-----------+-----------+            |
|                |                                     |                        |
|                +------------------+------------------+                        |
|                                   |                                           |
|                        Load Balancing (Round-Robin)                           |
|                         Session Persistence (Cookies)                         |
|                                   |                                           |
|         +-------------------------+-------------------------+                 |
|         |                                                   |                 |
|  +------v--------------+                         +----------v------------+    |
|  | WALLIX Bastion-1    |    HA Cluster Sync      | WALLIX Bastion-2      |    |
|  | 10.10.1.11          |<----------------------->| 10.10.1.12            |    |
|  |                     |  MariaDB: 3306/TCP      |                       |    |
|  | +-----------------+ |  Corosync: 5404-6/UDP   | +-----------------+   |    |
|  | | Session Manager | |  Pacemaker: 2224/TCP    | | Session Manager |   |    |
|  | | - SSH Proxy     | |  PCSD: 3121/TCP         | | - SSH Proxy     |   |    |
|  | | - RDP Proxy     | |                         | | - RDP Proxy     |   |    |
|  | | - VNC Proxy     | |                         | | - VNC Proxy     |   |    |
|  | +-----------------+ |                         | +-----------------+   |    |
|  |                     |                         |                       |    |
|  | +-----------------+ |                         | +-----------------+   |    |
|  | | Password Mgr    | |                         | | Password Mgr    |   |    |
|  | | - Credential    | |                         | | - Credential    |   |    |
|  | |   Vault         | |                         | |   Vault         |   |    |
|  | | - Auto-Rotation | |                         | | - Auto-Rotation |   |    |
|  | +-----------------+ |                         | +-----------------+   |    |
|  |                     |                         |                       |    |
|  | +-----------------+ |                         | +-----------------+   |    |
|  | | MariaDB 10.11   |<+----------------------->| | MariaDB 10.11    |   |    |
|  | | (Primary/Sync)  | | Galera Replication OR   | | (Primary/Sync)  |   |    |
|  | |                 | | Async Replication       | | (Replica)       |   |    |
|  | +-----------------+ |                         | +-----------------+   |    |
|  |                     |                         |                       |    |
|  | +-----------------+ |                         | +-----------------+   |    |
|  | | Pacemaker/      | |                         | | Pacemaker/      |   |    |
|  | | Corosync        | |                         | | Corosync        |   |    |
|  | +-----------------+ |                         | +-----------------+   |    |
|  +---------------------+                         +-----------------------+    |
|         |                                                   |                 |
|         +-------------------+-------------------------------+                 |
|                             |                                                 |
|                             |                                                 |
|                  +----------v---------+                                       |
|                  |  WALLIX RDS        |                                       |
|                  |  Jump Host         |                                       |
|                  |  10.10.1.30        |                                       |
|                  |                    |                                       |
|                  |  Windows Server    |                                       |
|                  |  2022              |                                       |
|                  |                    |                                       |
|                  |  - RemoteApp       |                                       |
|                  |  - RDS Licensing   |                                       |
|                  +----------+---------+                                       |
|                             |                                                 |
|                             v                                                 |
|                  Target Systems (OT)                                          |
|                  - OT Windows (RDP)                                           |
|                  - SCADA (RDP)                                                |
|                  - ICS (RDP)                                                  |
|                                                                               |
|  VLAN SEGMENTATION:                                                           |
|  ==================                                                           |
|  VLAN 11:  DMZ (HAProxy, Bastion, RDS)              10.10.1.0/24              |
|  VLAN 111: HA Cluster (Bastion-to-Bastion sync)     192.168.1.0/24            |
|  VLAN 112: Management (IPMI, out-of-band)           10.10.1.128/27            |
|                                                                               |
+===============================================================================+
```

### 2.2 Site Component Breakdown

```
+===============================================================================+
|  PER-SITE COMPONENT INVENTORY (ALL 5 SITES IDENTICAL)                         |
+===============================================================================+
|                                                                               |
|  Component              | Quantity | IP Range         | Role                  |
|  ----------------------+----------+------------------+---------------------   |
|  Fortigate Firewall     | 1        | 10.10.X.1        | Perimeter security    |
|  HAProxy Primary        | 1        | 10.10.X.5        | Load balancer         |
|  HAProxy Backup         | 1        | 10.10.X.6        | Load balancer (HA)    |
|  HAProxy VIP            | 1        | 10.10.X.100      | Virtual IP (VRRP)     |
|  WALLIX Bastion-1       | 1        | 10.10.X.11       | PAM appliance         |
|  WALLIX Bastion-2       | 1        | 10.10.X.12       | PAM appliance (HA)    |
|  WALLIX RDS             | 1        | 10.10.X.30       | Jump host (OT)        |
|  Default Gateway        | -        | 10.10.X.1        | Fortigate internal    |
|                                                                               |
|  X = Site number (1-5)                                                        |
|                                                                               |
|  Total per site:                                                              |
|  - 2x HAProxy servers (Active-Passive)                                        |
|  - 2x WALLIX Bastion HW appliances (Active-Active OR Active-Passive)          |
|  - 1x WALLIX RDS server (Windows Server 2022)                                 |
|  - 1x Fortigate firewall (perimeter)                                          |
|                                                                               |
|  Total across 5 sites:                                                        |
|  - 10x HAProxy servers                                                        |
|  - 10x WALLIX Bastion appliances                                              |
|  - 5x WALLIX RDS servers                                                      |
|  - 5x Fortigate firewalls                                                     |
|                                                                               |
+===============================================================================+
```

---

## Network Data Flows

### 3.1 User Access Flow (Native Windows/Linux)

```
+===============================================================================+
|  USER ACCESS FLOW - NATIVE SSH/RDP (NO JUMP HOST)                             |
+===============================================================================+
|                                                                               |
|  Step 1: User Login (SSO + MFA)                                               |
|  ===============================                                              |
|                                                                               |
|  +------------+                                                               |
|  | End User   |                                                               |
|  | Workstation|                                                               |
|  +-----+------+                                                               |
|        | 1. HTTPS (443)                                                       |
|        |    URL: https://bastion-site1.company.com                            |
|        v                                                                      |
|  +-----+---------------+                                                      |
|  | HAProxy VIP         |                                                      |
|  | 10.10.1.100:443     |                                                      |
|  +-----+---------------+                                                      |
|        | 2. Load balance to Bastion                                           |
|        v                                                                      |
|  +-----+---------------+                                                      |
|  | WALLIX Bastion-1    |                                                      |
|  | 10.10.1.11:443      |                                                      |
|  +-----+---------------+                                                      |
|        | 3. SSO Redirect (SAML/OIDC)                                          |
|        v                                                                      |
|  +-----+------------------+                                                   |
|  | Access Manager 1       |                                                   |
|  | 10.100.1.10:443        |                                                   |
|  +-----+------------------+                                                   |
|        | 4. RADIUS Auth (MFA)                                                 |
|        v                                                                      |
|  +-----+------------------+                                                   |
|  | FortiAuthenticator     |                                                   |
|  | 10.20.0.60:1812        |                                                   |
|  +-----+------------------+                                                   |
|        | 5. FortiToken Push                                                   |
|        v                                                                      |
|  +-----+-------------+                                                        |
|  | User Mobile Device |                                                       |
|  | FortiToken App     |                                                       |
|  +-----+-------------+                                                        |
|        | 6. User Approves                                                     |
|        v                                                                      |
|  (Back to FortiAuth → AM → Bastion → User: Session Token)                     |
|                                                                               |
|  Step 2: Target Connection (SSH Example)                                      |
|  ========================================                                     |
|                                                                               |
|  +------------+                                                               |
|  | End User   |                                                               |
|  | (Authed)   |                                                               |
|  +-----+------+                                                               |
|        | 7. SSH (22) via Bastion portal                                       |
|        |    Target: prod-rhel-01.company.com                                  |
|        v                                                                      |
|  +-----+---------------+                                                      |
|  | WALLIX Bastion-1    |                                                      |
|  | Session Manager     |                                                      |
|  +-----+---------------+                                                      |
|        | 8. Retrieve credential from vault                                    |
|        | 9. Initiate SSH proxy connection                                     |
|        v                                                                      |
|  +-----+---------------+                                                      |
|  | Target: RHEL Server |                                                      |
|  | prod-rhel-01        |                                                      |
|  | 10.40.0.10:22       |                                                      |
|  +-------------------+                                                        |
|                                                                               |
|  Data Flow Summary:                                                           |
|  User → HAProxy → Bastion → (SSO) → AM → (MFA) → FortiAuth → Bastion          |
|  User → Bastion (authenticated) → Target (SSH/RDP proxied)                    |
|                                                                               |
+===============================================================================+
```

### 3.2 OT Access Flow (via RDS Jump Host)

```
+===============================================================================+
|  OT ACCESS FLOW - VIA WALLIX RDS JUMP HOST (REMOTEAPP)                        |
+===============================================================================+
|                                                                               |
|  +------------+                                                               |
|  | End User   |                                                               |
|  | (OT Eng)   |                                                               |
|  +-----+------+                                                               |
|        | 1. HTTPS (443) to Bastion Web UI                                     |
|        v                                                                      |
|  +-----+---------------+                                                      |
|  | WALLIX Bastion      |                                                      |
|  | (Authenticated)     |                                                      |
|  +-----+---------------+                                                      |
|        | 2. User selects OT target                                            |
|        |    Protocol: RDP (RemoteApp)                                         |
|        v                                                                      |
|  +-----+---------------+                                                      |
|  | WALLIX Bastion      |                                                      |
|  | Session Broker      |                                                      |
|  +-----+---------------+                                                      |
|        | 3. RDP (3389) to WALLIX RDS                                          |
|        |    (First hop: Bastion → RDS)                                        |
|        v                                                                      |
|  +-----+---------------+                                                      |
|  | WALLIX RDS          |                                                      |
|  | Jump Host           |                                                      |
|  | 10.10.1.30          |                                                      |
|  +-----+---------------+                                                      |
|        | 4. RemoteApp session launched                                        |
|        |    Published app: OT Workstation Client                              |
|        v                                                                      |
|  +-----+---------------+                                                      |
|  | RDS establishes     |                                                      |
|  | RDP connection      |                                                      |
|  +-----+---------------+                                                      |
|        | 5. RDP (3389) to OT Target                                           |
|        |    (Second hop: RDS → OT Target)                                     |
|        v                                                                      |
|  +-----+---------------+                                                      |
|  | OT Workstation      |                                                      |
|  | ot-ws-01            |                                                      |
|  | 10.30.0.50:3389     |                                                      |
|  +-------------------+                                                        |
|                                                                               |
|  Recording:                                                                   |
|  ==========                                                                   |
|  - Hop 1 (Bastion → RDS): Recorded by Bastion                                 |
|  - Hop 2 (RDS → OT): Recorded by Bastion (via RDS proxy)                      |
|  - Full two-hop session captured end-to-end                                   |
|                                                                               |
|  Security:                                                                    |
|  =========                                                                    |
|  - User does NOT have direct access to OT target                              |
|  - All access mediated through RDS jump host                                  |
|  - RemoteApp isolation (user sees only published app, not full desktop)       |
|                                                                               |
+===============================================================================+
```

### 3.3 Session Brokering Flow

```
+===============================================================================+
|  SESSION BROKERING - ACCESS MANAGER ROUTING TO OPTIMAL SITE                   |
+===============================================================================+
|                                                                               |
|  +------------+                                                               |
|  | End User   |                                                               |
|  +-----+------+                                                               |
|        | 1. Login via Access Manager                                          |
|        |    URL: https://accessmanager.company.com                            |
|        v                                                                      |
|  +-----+-----------------+                                                    |
|  | Access Manager 1      |                                                    |
|  | Session Broker        |                                                    |
|  +-----+-----------------+                                                    |
|        | 2. Query site health and load                                        |
|        |                                                                      |
|        +-----+-----+-----+-----+-----+                                        |
|        |     |     |     |     |     |                                        |
|        v     v     v     v     v     v                                        |
|  +-----+  +--+--+ +-+--+ +-+--+ +--+-+ +--+--+                                |
|  |Site1|  |Site2| |Site3| |Site4| |Site5|                                     |
|  |Hlth |  |Hlth | |Hlth | |Hlth | |Hlth |                                     |
|  |Check|  |Check| |Check| |Check| |Check|                                     |
|  +-----+  +-----+ +-----+ +-----+ +-----+                                     |
|                                                                               |
|  Health Check Response:                                                       |
|  ======================                                                       |
|  Site 1: Status=OK,    Load=15%, Latency=10ms  [OPTIMAL]                      |
|  Site 2: Status=OK,    Load=25%, Latency=12ms                                 |
|  Site 3: Status=WARN,  Load=85%, Latency=15ms                                 |
|  Site 4: Status=OK,    Load=30%, Latency=11ms                                 |
|  Site 5: Status=ERROR, Load=N/A,  Latency=N/A  [DOWN]                         |
|                                                                               |
|        | 3. Routing decision algorithm                                        |
|        |    - Exclude Site 5 (down)                                           |
|        |    - Deprioritize Site 3 (high load)                                 |
|        |    - Select Site 1 (lowest load, best latency)                       |
|        v                                                                      |
|  +-----+---------------+                                                      |
|  | Routing Decision    |                                                      |
|  | Selected: Site 1    |                                                      |
|  +-----+---------------+                                                      |
|        | 4. Redirect user to Site 1                                           |
|        v                                                                      |
|  +-----+---------------+                                                      |
|  | WALLIX Bastion      |                                                      |
|  | Site 1 (10.10.1.11) |                                                      |
|  +-------------------+                                                        |
|                                                                               |
|  Routing Factors:                                                             |
|  ================                                                             |
|  1. Site health (UP/DOWN)                                                     |
|  2. Current load (session count)                                              |
|  3. Network latency (user → site)                                             |
|  4. Site priority/weight (configuration)                                      |
|  5. User affinity (prefer last used site)                                     |
|                                                                               |
+===============================================================================+
```

---

## Complete Port Matrix

### 4.1 User Access Ports

```
+===============================================================================+
|  USER ACCESS - EXTERNAL TO BASTION                                            |
+===============================================================================+
|                                                                               |
|  Source              | Destination        | Port  | Protocol | Purpose        |
|  --------------------+--------------------+-------+----------+-------------   |
|  End Users (Any)     | HAProxy VIP        | 443   | TCP/HTTPS| Web UI/API     |
|  End Users (Any)     | HAProxy VIP        | 22    | TCP/SSH  | SSH proxy      |
|  End Users (Any)     | HAProxy VIP        | 3389  | TCP/RDP  | RDP proxy      |
|  End Users (Any)     | HAProxy VIP        | 80    | TCP/HTTP | HTTP→HTTPS     |
|                                                                               |
|  Notes:                                                                       |
|  - Users always access via HAProxy VIP (not direct Bastion IPs)               |
|  - HTTP (80) automatically redirects to HTTPS (443)                           |
|  - VIP: 10.10.X.100 (where X = site number 1-5)                               |
|                                                                               |
+===============================================================================+
```

### 4.2 HAProxy to Bastion Ports

```
+===============================================================================+
|  HAPROXY LOAD BALANCING - BACKEND CONNECTIONS                                 |
+===============================================================================+
|                                                                               |
|  Source              | Destination        | Port  | Protocol | Purpose        |
|  --------------------+--------------------+-------+----------+-------------   |
|  HAProxy-1 (X.5)     | Bastion-1 (X.11)   | 443   | TCP/HTTPS| Backend pool   |
|  HAProxy-1 (X.5)     | Bastion-2 (X.12)   | 443   | TCP/HTTPS| Backend pool   |
|  HAProxy-1 (X.5)     | Bastion-1 (X.11)   | 22    | TCP/SSH  | Health check   |
|  HAProxy-1 (X.5)     | Bastion-2 (X.12)   | 22    | TCP/SSH  | Health check   |
|  HAProxy-2 (X.6)     | Bastion-1 (X.11)   | 443   | TCP/HTTPS| Backup path    |
|  HAProxy-2 (X.6)     | Bastion-2 (X.12)   | 443   | TCP/HTTPS| Backup path    |
|                                                                               |
|  HAProxy Health Check Configuration:                                          |
|  - Interval: 5 seconds                                                        |
|  - Timeout: 3 seconds                                                         |
|  - Rise: 2 (2 consecutive success = UP)                                       |
|  - Fall: 3 (3 consecutive failures = DOWN)                                    |
|                                                                               |
+===============================================================================+
```

### 4.3 HAProxy HA (VRRP)

```
+===============================================================================+
|  HAPROXY HA - VRRP HEARTBEAT                                                  |
+===============================================================================+
|                                                                               |
|  Source              | Destination        | Port  | Protocol | Purpose        |
|  --------------------+--------------------+-------+----------+-------------   |
|  HAProxy-1 (X.5)     | HAProxy-2 (X.6)    | N/A   | IP/112   | VRRP keepalive |
|  HAProxy-2 (X.6)     | HAProxy-1 (X.5)    | N/A   | IP/112   | VRRP keepalive |
|                                                                               |
|  Multicast (VRRP default):                                                    |
|  - Multicast Address: 224.0.0.18                                              |
|  - Virtual Router ID: 51 (configurable per site)                              |
|                                                                               |
|  CRITICAL:                                                                    |
|  - VRRP uses IP protocol 112 (NOT TCP or UDP)                                 |
|  - Firewalls must allow IP protocol 112 between HAProxy nodes                 |
|  - Alternatively, configure unicast VRRP (recommended for security)           |
|                                                                               |
+===============================================================================+
```

### 4.4 Bastion HA Cluster Ports

```
+===============================================================================+
|  BASTION HA CLUSTER - INTERNAL SYNCHRONIZATION                                |
+===============================================================================+
|                                                                               |
|  Source              | Destination        | Port     | Protocol | Purpose     |
|  --------------------+--------------------+----------+----------+----------   |
|  Bastion-1 (X.11)    | Bastion-2 (X.12)   | 3306     | TCP      | MariaDB     |
|  Bastion-2 (X.12)    | Bastion-1 (X.11)   | 3306     | TCP      | MariaDB     |
|  Bastion-1 (X.11)    | Bastion-2 (X.12)   | 2224     | TCP      | PCSD        |
|  Bastion-1 (X.11)    | Bastion-2 (X.12)   | 3121     | TCP      | Pacemaker   |
|  Bastion-1 (X.11)    | Bastion-2 (X.12)   | 5404     | UDP      | Corosync    |
|  Bastion-1 (X.11)    | Bastion-2 (X.12)   | 5405     | UDP      | Corosync    |
|  Bastion-1 (X.11)    | Bastion-2 (X.12)   | 5406     | UDP      | Corosync    |
|                                                                               |
|  SECURITY CRITICAL:                                                           |
|  ==================                                                           |
|  - HA cluster ports MUST be isolated on dedicated VLAN or physically          |
|    separate network (e.g., 192.168.X.0/24)                                    |
|  - These ports should NOT be accessible from DMZ or production networks       |
|  - Firewall rules MUST restrict to only Bastion-to-Bastion communication      |
|                                                                               |
|  Port Details:                                                                |
|  =============                                                                |
|  - 3306: MariaDB replication (Galera or Async)                                |
|  - 2224: PCSD (Pacemaker/Corosync configuration)                              |
|  - 3121: Pacemaker cluster communication                                      |
|  - 5404: Corosync multicast (cluster heartbeat)                               |
|  - 5405: Corosync unicast (cluster messaging)                                 |
|  - 5406: Corosync additional channel (optional)                               |
|                                                                               |
+===============================================================================+
```

### 4.5 Access Manager Integration Ports

```
+===============================================================================+
|  ACCESS MANAGER <-> BASTION (MPLS)                                            |
+===============================================================================+
|                                                                               |
|  Source              | Destination        | Port  | Protocol | Purpose        |
|  --------------------+--------------------+-------+----------+-------------   |
|  AM1 (100.1.10)      | Bastion Sites 1-5  | 443   | TCP/HTTPS| SSO callbacks  |
|  AM1 (100.1.10)      | Bastion Sites 1-5  | 22    | TCP/SSH  | SSH broker     |
|  AM2 (100.2.10)      | Bastion Sites 1-5  | 443   | TCP/HTTPS| SSO callbacks  |
|  AM2 (100.2.10)      | Bastion Sites 1-5  | 22    | TCP/SSH  | SSH broker     |
|                                                                               |
|  Bastion Sites 1-5   | AM1 (100.1.10)     | 443   | TCP/HTTPS| SSO auth req   |
|  Bastion Sites 1-5   | AM2 (100.2.10)     | 443   | TCP/HTTPS| SSO failover   |
|                                                                               |
|  Access Manager HA (DC-A <-> DC-B):                                           |
|  --------------------+--------------------+-------+----------+-------------   |
|  AM1 (100.1.10)      | AM2 (100.2.10)     | 443   | TCP/HTTPS| Config sync    |
|  AM1 (100.1.10)      | AM2 (100.2.10)     | 3306  | TCP      | DB replication |
|  AM1 (100.1.10)      | AM2 (100.2.10)     | 5404  | UDP      | Corosync       |
|  AM1 (100.1.10)      | AM2 (100.2.10)     | 5405  | UDP      | Corosync       |
|  AM1 (100.1.10)      | AM2 (100.2.10)     | 5406  | UDP      | Corosync       |
|                                                                               |
+===============================================================================+
```

### 4.6 Authentication & MFA Ports

```
+===============================================================================+
|  AUTHENTICATION SERVICES (FORTIAUTH, AD)                                      |
+===============================================================================+
|                                                                               |
|  RADIUS (FortiAuthenticator):                                                 |
|  Source              | Destination        | Port  | Protocol | Purpose        |
|  --------------------+--------------------+-------+----------+-------------   |
|  Bastion Sites 1-5   | FortiAuth Primary  | 1812  | UDP      | RADIUS auth    |
|  Bastion Sites 1-5   | FortiAuth Primary  | 1813  | UDP      | RADIUS acct    |
|  Bastion Sites 1-5   | FortiAuth Secondary| 1812  | UDP      | RADIUS backup  |
|  Bastion Sites 1-5   | FortiAuth Secondary| 1813  | UDP      | RADIUS backup  |
|  AM1/AM2             | FortiAuth Primary  | 1812  | UDP      | RADIUS auth    |
|  AM1/AM2             | FortiAuth Primary  | 1813  | UDP      | RADIUS acct    |
|                                                                               |
|  Active Directory (LDAP):                                                     |
|  Source              | Destination        | Port  | Protocol | Purpose        |
|  --------------------+--------------------+-------+----------+-------------   |
|  Bastion Sites 1-5   | AD DC1 (20.0.10)   | 389   | TCP/LDAP | User lookup    |
|  Bastion Sites 1-5   | AD DC1 (20.0.10)   | 636   | TCP/LDAPS| Secure LDAP    |
|  Bastion Sites 1-5   | AD DC1 (20.0.10)   | 3268  | TCP/GC   | Global Catalog |
|  Bastion Sites 1-5   | AD DC1 (20.0.10)   | 3269  | TCP/GC-SSL| GC Secure     |
|  Bastion Sites 1-5   | AD DC1 (20.0.10)   | 88    | TCP/UDP  | Kerberos       |
|  Bastion Sites 1-5   | AD DC2 (20.0.11)   | 636   | TCP/LDAPS| Failover LDAP  |
|                                                                               |
|  FortiAuth → AD (User Sync):                                                  |
|  --------------------+--------------------+-------+----------+-------------   |
|  FortiAuth (20.0.60) | AD DC1 (20.0.10)   | 389   | TCP/LDAP | User sync      |
|  FortiAuth (20.0.60) | AD DC1 (20.0.10)   | 636   | TCP/LDAPS| Secure sync    |
|                                                                               |
+===============================================================================+
```

### 4.7 Target System Ports

```
+===============================================================================+
|  BASTION -> TARGET SYSTEMS                                                    |
+===============================================================================+
|                                                                               |
|  Windows Targets (RDP):                                                       |
|  Source              | Destination        | Port  | Protocol | Purpose        |
|  --------------------+--------------------+-------+----------+-------------   |
|  Bastion Sites 1-5   | Windows (30.0.0/16)| 3389  | TCP/RDP  | Desktop access |
|  Bastion Sites 1-5   | Windows (30.0.0/16)| 5985  | TCP/WinRM| Password rot   |
|  Bastion Sites 1-5   | Windows (30.0.0/16)| 5986  | TCP/WinRM| Password rot   |
|                                                                               |
|  Linux Targets (SSH):                                                         |
|  Source              | Destination        | Port  | Protocol | Purpose        |
|  --------------------+--------------------+-------+----------+-------------   |
|  Bastion Sites 1-5   | RHEL (40.0.0/16)   | 22    | TCP/SSH  | Shell access   |
|                                                                               |
|  OT Targets (via RDS Jump Host):                                              |
|  Source              | Destination        | Port  | Protocol | Purpose        |
|  --------------------+--------------------+-------+----------+-------------   |
|  WALLIX RDS (X.30)   | OT Windows         | 3389  | TCP/RDP  | RemoteApp      |
|                                                                               |
|  Bastion -> RDS (Jump Host):                                                  |
|  Source              | Destination        | Port  | Protocol | Purpose        |
|  --------------------+--------------------+-------+----------+-------------   |
|  Bastion-1/2 (X.11/12)| RDS (X.30)        | 3389  | TCP/RDP  | RDS connection |
|                                                                               |
+===============================================================================+
```

### 4.8 Monitoring & Management Ports

```
+===============================================================================+
|  MONITORING, LOGGING, NTP                                                     |
+===============================================================================+
|                                                                               |
|  NTP (Time Synchronization):                                                  |
|  Source              | Destination        | Port  | Protocol | Purpose        |
|  --------------------+--------------------+-------+----------+-------------   |
|  Bastion Sites 1-5   | NTP1 (20.0.20)     | 123   | UDP/NTP  | Time sync      |
|  Bastion Sites 1-5   | NTP2 (20.0.21)     | 123   | UDP/NTP  | Time sync      |
|  HAProxy Sites 1-5   | NTP1 (20.0.20)     | 123   | UDP/NTP  | Time sync      |
|  AM1/AM2             | NTP1 (20.0.20)     | 123   | UDP/NTP  | Time sync      |
|                                                                               |
|  SIEM (Log Forwarding):                                                       |
|  Source              | Destination        | Port  | Protocol | Purpose        |
|  --------------------+--------------------+-------+----------+-------------   |
|  Bastion Sites 1-5   | SIEM (20.0.50)     | 514   | UDP/Syslog| Audit logs    |
|  Bastion Sites 1-5   | SIEM (20.0.50)     | 6514  | TCP/TLS  | Secure logs    |
|  HAProxy Sites 1-5   | SIEM (20.0.50)     | 514   | UDP/Syslog| Access logs   |
|                                                                               |
|  Monitoring (Prometheus):                                                     |
|  Source              | Destination        | Port  | Protocol | Purpose        |
|  --------------------+--------------------+-------+----------+-------------   |
|  Prometheus Server   | Bastion Sites 1-5  | 9100  | TCP/HTTP | Node metrics   |
|  Prometheus Server   | HAProxy Sites 1-5  | 8404  | TCP/HTTP | HAProxy stats  |
|                                                                               |
|  SNMP (Network Management):                                                   |
|  Source              | Destination        | Port  | Protocol | Purpose        |
|  --------------------+--------------------+-------+----------+-------------   |
|  SNMP NMS            | Bastion Sites 1-5  | 161   | UDP/SNMP | Device queries |
|                                                                               |
|  Email (Alerting):                                                            |
|  Source              | Destination        | Port  | Protocol | Purpose        |
|  --------------------+--------------------+-------+----------+-------------   |
|  Bastion Sites 1-5   | Mail Server        | 25    | TCP/SMTP | Alerts         |
|  Bastion Sites 1-5   | Mail Server        | 587   | TCP/SMTP | STARTTLS       |
|                                                                               |
+===============================================================================+
```

### 4.9 Complete Port Summary Table

```
+===============================================================================+
|  COMPLETE PORT MATRIX SUMMARY (ALL COMMUNICATION PATHS)                       |
+===============================================================================+
|                                                                               |
|  Port  | Protocol    | Source → Destination         | Purpose                 |
|  ------+-------------+------------------------------+--------------------     |
|  22    | TCP/SSH     | Users → HAProxy VIP          | SSH proxy sessions      |
|  22    | TCP/SSH     | HAProxy → Bastion            | Health check            |
|  22    | TCP/SSH     | Bastion → Linux Targets      | SSH target access       |
|  22    | TCP/SSH     | AM → Bastion                 | SSH brokering           |
|  80    | TCP/HTTP    | Users → HAProxy VIP          | HTTP→HTTPS redirect     |
|  88    | TCP/UDP     | Bastion → AD                 | Kerberos auth           |
|  123   | UDP/NTP     | All → NTP Servers            | Time sync               | 
|  161   | UDP/SNMP    | NMS → Bastion                | SNMP queries            |
|  389   | TCP/LDAP    | Bastion → AD                 | LDAP queries            |
|  443   | TCP/HTTPS   | Users → HAProxy VIP          | Web UI/API              |
|  443   | TCP/HTTPS   | HAProxy → Bastion            | Backend pool            |
|  443   | TCP/HTTPS   | Bastion → AM                 | SSO auth requests       |
|  443   | TCP/HTTPS   | AM → Bastion                 | SSO callbacks           | 
|  514   | UDP/Syslog  | Bastion → SIEM               | Audit logs              |
|  636   | TCP/LDAPS   | Bastion → AD                 | Secure LDAP             |
|  1812  | UDP/RADIUS  | Bastion → FortiAuth          | RADIUS auth             |
|  1813  | UDP/RADIUS  | Bastion → FortiAuth          | RADIUS accounting       |
|  2224  | TCP         | Bastion-1 ↔ Bastion-2        | PCSD (Pacemaker)        |
|  3121  | TCP         | Bastion-1 ↔ Bastion-2        | Pacemaker cluster       |
|  3268  | TCP/GC      | Bastion → AD                 | Global Catalog          |
|  3269  | TCP/GC-SSL  | Bastion → AD                 | GC Secure               |
|  3306  | TCP/MariaDB | Bastion-1 ↔ Bastion-2        | DB replication          |
|  3306  | TCP/MariaDB | AM1 ↔ AM2                    | AM DB replication       |
|  3389  | TCP/RDP     | Users → HAProxy VIP          | RDP proxy sessions      |
|  3389  | TCP/RDP     | Bastion → Windows Targets    | RDP target access       |
|  3389  | TCP/RDP     | Bastion → RDS                | RDS jump host           |
|  3389  | TCP/RDP     | RDS → OT Targets             | OT RemoteApp            |
|  5404  | UDP/Corosync| Bastion-1 ↔ Bastion-2        | Cluster heartbeat       |
|  5405  | UDP/Corosync| Bastion-1 ↔ Bastion-2        | Cluster messaging       |
|  5406  | UDP/Corosync| Bastion-1 ↔ Bastion-2        | Cluster additional      |
|  5985  | TCP/WinRM   | Bastion → Windows Targets    | Password rotation       | 
|  5986  | TCP/WinRM   | Bastion → Windows Targets    | Password rotation TLS   |
|  6514  | TCP/TLS     | Bastion → SIEM               | Secure syslog           |
|  8404  | TCP/HTTP    | Monitoring → HAProxy         | HAProxy stats           |
|  9100  | TCP/HTTP    | Monitoring → Bastion         | Node exporter           |
|  IP-112| VRRP        | HAProxy-1 ↔ HAProxy-2        | VRRP keepalive          |
|                                                                               |
+===============================================================================+
```

---

## VLAN Design

### 5.1 Per-Site VLAN Segmentation

```
+===============================================================================+
|  VLAN DESIGN - SITE 1 (REPEATED FOR ALL 5 SITES)                              |
+===============================================================================+
|                                                                               |
|  VLAN ID | Name            | Subnet          | Purpose                        |
|  --------+-----------------+-----------------+----------------------------    |
|  11      | DMZ             | 10.10.1.0/24    | HAProxy, Bastion, RDS          |
|  111     | HA-Cluster      | 192.168.1.0/24  | Bastion HA sync (isolated)     |
|  112     | Management      | 10.10.1.128/27  | IPMI, iLO, out-of-band         |
|  999     | Uplink          | MPLS            | MPLS uplink to core            |
|                                                                               |
|  VLAN 11 (DMZ) - User-Facing Services:                                        |
|  ======================================                                       |
|  Gateway:           10.10.1.1  (Fortigate internal interface)                 |
|  HAProxy-1:         10.10.1.5                                                 |
|  HAProxy-2:         10.10.1.6                                                 |
|  HAProxy VIP:       10.10.1.100                                               |
|  Bastion-1:         10.10.1.11                                                |
|  Bastion-2:         10.10.1.12                                                |
|  RDS:               10.10.1.30                                                |
|  Subnet:            10.10.1.0/24 (254 usable IPs)                             |
|  Allowed Traffic:   HTTPS(443), SSH(22), RDP(3389)                            |
|                                                                               |
|  VLAN 111 (HA-Cluster) - Bastion-to-Bastion Sync (ISOLATED):                  |
|  ================================================================             |
|  Bastion-1 HA:      192.168.1.11                                              |
|  Bastion-2 HA:      192.168.1.12                                              |
|  Subnet:            192.168.1.0/24 (254 usable IPs)                           |
|  Allowed Traffic:   MariaDB(3306), Pacemaker(2224,3121), Corosync(5404-6)     |
|  Security:          NO routing to other VLANs (physically isolated)           |
|                                                                               |
|  VLAN 112 (Management) - Out-of-Band Access:                                  |
|  ===========================================                                  |
|  Bastion-1 IPMI:    10.10.1.131                                               |
|  Bastion-2 IPMI:    10.10.1.132                                               |
|  HAProxy-1 IPMI:    10.10.1.133                                               |
|  HAProxy-2 IPMI:    10.10.1.134                                               |
|  Subnet:            10.10.1.128/27 (30 usable IPs)                            |
|  Allowed Traffic:   IPMI(623 UDP), HTTPS(443) for iLO/iDRAC                   |
|  Security:          Restricted to ops team IPs only                           |
|                                                                               |
+===============================================================================+
```

### 5.2 Multi-Site VLAN Summary

```
+===============================================================================+
|  VLAN SUMMARY - ALL 5 SITES                                                   |
+===============================================================================+
|                                                                               |
|  Site  | DMZ VLAN | HA Cluster VLAN | Management VLAN | Uplink VLAN           |
|  ------+----------+-----------------+-----------------+------------------     |
|  1     | VLAN 11  | VLAN 111        | VLAN 112        | VLAN 999              |
|  2     | VLAN 12  | VLAN 121        | VLAN 122        | VLAN 999              |
|  3     | VLAN 13  | VLAN 131        | VLAN 132        | VLAN 999              |
|  4     | VLAN 14  | VLAN 141        | VLAN 142        | VLAN 999              |
|  5     | VLAN 15  | VLAN 151        | VLAN 152        | VLAN 999              |
|                                                                               |
|  Shared Infrastructure VLANs:                                                 |
|  ============================                                                 |
|  VLAN 20:  Authentication (FortiAuth, AD, NTP) - 10.20.0.0/24                 |
|  VLAN 30:  Windows Targets (Prod) - 10.30.0.0/16                              |
|  VLAN 40:  Linux Targets (Prod) - 10.40.0.0/16                                |
|  VLAN 100: Access Manager DC-A - 10.100.1.0/24                                |
|  VLAN 200: Access Manager DC-B - 10.100.2.0/24                                |
|                                                                               |
|  Routing Rules:                                                               |
|  ==============                                                               |
|  - DMZ VLANs can route to: MPLS, Auth VLAN, Target VLANs                      |
|  - HA Cluster VLANs: ISOLATED (no routing to/from other VLANs)                |
|  - Management VLANs: Route to ops network only                                |
|  - NO routing between DMZ VLANs (Site 1 X Site 2 blocked)                     |
|                                                                               |
+===============================================================================+
```

---

## IP Addressing Scheme

### 6.1 Complete IP Address Allocation

```
+===============================================================================+
|  IP ADDRESS ALLOCATION - COMPLETE DEPLOYMENT                                  |
+===============================================================================+
|                                                                               |
|  Access Manager Datacenters:                                                  |
|  ===========================                                                  |
|  10.100.1.0/24   DC-A (Access Manager 1)                                      |
|    .1            Gateway (MPLS router)                                        |
|    .10           Access Manager 1 primary                                     |
|    .11           Access Manager 1 management (out-of-band)                    |
|                                                                               |
|  10.100.2.0/24   DC-B (Access Manager 2)                                      |
|    .1            Gateway (MPLS router)                                        |
|    .10           Access Manager 2 primary                                     |
|    .11           Access Manager 2 management (out-of-band)                    |
|                                                                               |
|  Site 1 (Site 1 DC, Building A):                                              |
|  ===================================                                          |
|  10.10.1.0/24    DMZ VLAN 11                                                  |
|    .1            Fortigate firewall                                           |
|    .5            HAProxy-1 primary                                            |
|    .6            HAProxy-2 backup                                             |
|    .100          HAProxy VIP (VRRP)                                           |
|    .11           WALLIX Bastion-1                                             |
|    .12           WALLIX Bastion-2                                             |
|    .30           WALLIX RDS (Windows 2022)                                    |
|                                                                               |
|  192.168.1.0/24  HA Cluster VLAN 111 (ISOLATED)                               |
|    .11           Bastion-1 HA interface                                       |
|    .12           Bastion-2 HA interface                                       |
|                                                                               |
|  10.10.1.128/27  Management VLAN 112                                          |
|    .131          Bastion-1 IPMI/iLO                                           |
|    .132          Bastion-2 IPMI/iLO                                           |
|    .133          HAProxy-1 IPMI                                               |
|    .134          HAProxy-2 IPMI                                               |
|                                                                               |
|  Site 2 (Site 2 DC, Building B):                                              |
|  ===================================                                          |
|  10.10.2.0/24    DMZ VLAN 12 (same layout as Site 1)                          |
|  192.168.2.0/24  HA Cluster VLAN 121                                          |
|  10.10.2.128/27  Management VLAN 122                                          |
|                                                                               |
|  Site 3 (Site 3 DC, Building C):                                              |
|  ===================================                                          |
|  10.10.3.0/24    DMZ VLAN 13                                                  |
|  192.168.3.0/24  HA Cluster VLAN 131                                          |
|  10.10.3.128/27  Management VLAN 132                                          |
|                                                                               |
|  Site 4 (Site 4 DC, Building D):                                              |
|  ===================================                                          |
|  10.10.4.0/24    DMZ VLAN 14                                                  |
|  192.168.4.0/24  HA Cluster VLAN 141                                          |
|  10.10.4.128/27  Management VLAN 142                                          |
|                                                                               |
|  Site 5 (Site 5 DC, Building E):                                              |
|  ===================================                                          |
|  10.10.5.0/24    DMZ VLAN 15                                                  |
|  192.168.5.0/24  HA Cluster VLAN 151                                          |
|  10.10.5.128/27  Management VLAN 152                                          |
|                                                                               |
|  Shared Infrastructure:                                                       |
|  ======================                                                       |
|  10.20.0.0/24    Authentication & Infrastructure                              |
|    .10           Active Directory DC1                                         |
|    .11           Active Directory DC2                                         |
|    .20           NTP Server 1                                                 |
|    .21           NTP Server 2                                                 |
|    .50           SIEM (Splunk/Elastic)                                        |
|    .60           FortiAuthenticator Primary                                   |
|    .61           FortiAuthenticator Secondary                                 |
|                                                                               |
|  Target Systems:                                                              |
|  ===============                                                              |
|  10.30.0.0/16    Windows Server 2022 targets                                  |
|    .0.0/24       Production Windows (DMZ)                                     |
|    .1.0/24       Production Windows (Internal)                                |
|    .2.0/24       OT Windows (isolated)                                        |
|                                                                               |
|  10.40.0.0/16    Linux targets (RHEL 9/10)                                    |
|    .0.0/24       Production RHEL 10                                           |
|    .1.0/24       Production RHEL 9 (legacy)                                   |
|    .2.0/24       Dev/Test Linux                                               |
|                                                                               |
+===============================================================================+
```

### 6.2 DNS Records

```
+===============================================================================+
|  DNS FORWARD ZONE RECORDS                                                     |
+===============================================================================+
|                                                                               |
|  Access Manager:                                                              |
|  am.company.com                        A    10.100.1.10                       |
|  am.company.com                        A    10.100.2.10  (round-robin)        |
|  am1.company.com                       A    10.100.1.10                       |
|  am2.company.com                       A    10.100.2.10                       |
|  accessmanager.company.com             CNAME am.company.com                   |
|                                                                               |
|  Site 1 (Site 1 DC):                                                          |
|  bastion-site1.company.com             A    10.10.1.100  (VIP)                |
|  haproxy1-site1.company.com            A    10.10.1.5                         |
|  haproxy2-site1.company.com            A    10.10.1.6                         |
|  bastion1-site1.company.com            A    10.10.1.11                        |
|  bastion2-site1.company.com            A    10.10.1.12                        |
|  rds-site1.company.com                 A    10.10.1.30                        |
|                                                                               |
|  Site 2 (Site 2 DC):                                                          |
|  bastion-site2.company.com             A    10.10.2.100                       |
|  haproxy1-site2.company.com            A    10.10.2.5                         |
|  haproxy2-site2.company.com            A    10.10.2.6                         |
|  bastion1-site2.company.com            A    10.10.2.11                        |
|  bastion2-site2.company.com            A    10.10.2.12                        |
|  rds-site2.company.com                 A    10.10.2.30                        |
|                                                                               |
|  Site 3 (Site 3 DC):                                                          |
|  bastion-site3.company.com             A    10.10.3.100                       |
|  [Similar pattern for Site 3]                                                 |
|                                                                               |
|  Site 4 (Site 4 DC):                                                          |
|  bastion-site4.company.com             A    10.10.4.100                       |
|  [Similar pattern for Site 4]                                                 |
|                                                                               |
|  Site 5 (Site 5 DC):                                                          |
|  bastion-site5.company.com             A    10.10.5.100                       |
|  [Similar pattern for Site 5]                                                 |
|                                                                               |
|  Shared Infrastructure:                                                       |
|  fortiauth.company.com                 A    10.20.0.60                        |
|  fortiauth-ha.company.com              A    10.20.0.61                        |
|  ad.company.com                        A    10.20.0.10                        |
|  ad.company.com                        A    10.20.0.11   (multi-value)        |
|  ntp1.company.com                      A    10.20.0.20                        |
|  ntp2.company.com                      A    10.20.0.21                        |
|  siem.company.com                      A    10.20.0.50                        |
|                                                                               |
|  Wildcard (for SSL certificate):                                              |
|  *.company.com                         CNAME [Certificate CN]                 |
|                                                                               |
+===============================================================================+
```

---

## References

### Related Documentation

- [00 - Prerequisites](00-prerequisites.md) - Hardware and software requirements
- [01 - Network Design](01-network-design.md) - Detailed network configuration
- [10 - Testing Validation](10-testing-validation.md) - Testing procedures
- [HOWTO.md](HOWTO.md) - Main installation guide

### External Resources

- WALLIX Bastion Network Requirements: https://pam.wallix.one/documentation
- HAProxy Configuration Guide: https://www.haproxy.org/
- Pacemaker Cluster Architecture: https://clusterlabs.org/pacemaker/

---

**Document Version**: 1.0
**Last Updated**: February 2026
**Validated By**: Network Architecture Team
**Approval Status**: Approved for Implementation
