# Architecture Diagrams and Port Reference

> Complete network diagrams, data flows, and port matrix for 5-site WALLIX Bastion deployment

---

## Document Information

| Property | Value |
|----------|-------|
| **Purpose** | Comprehensive network architecture reference |
| **Scope** | 5 Bastion sites + per-site FortiAuth HA + per-site AD (AM is client-managed) |
| **Network Type** | MPLS (private network) + per-site VLAN segmentation |
| **Version** | WALLIX Bastion 12.1.x |
| **Last Updated** | April 2026 |

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

### 1.1 Full 5-Site Deployment

```
+===============================================================================+
|  COMPLETE 5-SITE WALLIX BASTION DEPLOYMENT                                    |
+===============================================================================+
|                                                                               |
|  CLIENT-MANAGED (External):                                                   |
|  +----------------------------+     +----------------------------+            |
|  | Access Manager 1 (Primary) |  HA | Access Manager 2 (Standby) |            |
|  | (client's datacenter A)    |<--->| (client's datacenter B)    |            |
|  | - SSO (SAML/OIDC)          |     | - SSO (SAML/OIDC)          |            |
|  | - Session Brokering        |     | - Session Brokering        |            |
|  +-------------+--------------+     +-------------+--------------+            |
|                |                                  |                           |
|                +----------------------------------+                           |
|                              MPLS NETWORK                                     |
|                (10 Gbps backbone, < 50ms latency)                             |
|                +----------------------------------+                           |
|         +------+------+------+------+             |                           |
|         |      |      |      |      |                                         |
|    +----v--+ +--v----+ +--v----+ +--v----+ +-------v+                         |
|    |Site 1 | |Site 2 | |Site 3 | |Site 4 | | Site 5 |                         |
|    |(DC-1) | |(DC-2) | |(DC-3) | |(DC-4) | | (DC-5) |                         |
|    +-------+ +-------+ +-------+ +-------+ +--------+                         |
|                                                                               |
|  Each site has 2 VLANs:                                                       |
|  - DMZ VLAN  (10.10.X.0/25):   HAProxy, Bastion, RDS                          |
|  - Cyber VLAN (10.10.X.128/25): FortiAuth HA pair, Active Directory DC        |
|  Fortigate handles inter-VLAN routing (DMZ <-> Cyber)                         |
|                                                                               |
|  KEY CHARACTERISTICS:                                                         |
|  ===================                                                          |
|  - 5 sites in datacenter buildings, connected via MPLS                        |
|  - NO direct Bastion-to-Bastion communication between sites                   |
|  - Per-site FortiAuth HA (NOT shared/centralized)                             |
|  - Per-site Active Directory DC (NOT shared/centralized)                      |
|  - Each site: 2x HAProxy + 2x Bastion + 1x RDS (DMZ) + 2x FortiAuth + 1x AD  |
|                                                                               |
+===============================================================================+
```

### 1.2 MPLS Connectivity Matrix

```
+===============================================================================+
|  MPLS CONNECTIVITY PATHS                                                      |
+===============================================================================+
|                                                                               |
|  Access Manager <-> Bastion Sites (via MPLS):                                 |
|  ==============================================                               |
|                                                                               |
|  AM (client DC-A) <--MPLS--> Site 1 (DC-1) [1 Gbps, HTTPS 443]               |
|  AM (client DC-A) <--MPLS--> Site 2 (DC-2) [1 Gbps, HTTPS 443]               |
|  AM (client DC-A) <--MPLS--> Site 3 (DC-3) [1 Gbps, HTTPS 443]               |
|  AM (client DC-A) <--MPLS--> Site 4 (DC-4) [1 Gbps, HTTPS 443]               |
|  AM (client DC-A) <--MPLS--> Site 5 (DC-5) [1 Gbps, HTTPS 443]               |
|  (AM2 at DC-B has same connectivity via MPLS)                                 |
|                                                                               |
|  Site-to-Site Connectivity (BLOCKED):                                         |
|  ====================================                                         |
|                                                                               |
|  Site 1 X Site 2 [NO CONNECTIVITY - no direct Bastion-to-Bastion]             |
|  Site 1 X Site 3 [NO CONNECTIVITY]                                            |
|  Site 1 X Site 4 [NO CONNECTIVITY]                                            |
|  Site 1 X Site 5 [NO CONNECTIVITY]                                            |
|                                                                               |
|  Per-Site Local Infrastructure (NO MPLS needed - same site):                 |
|  ===========================================================                  |
|                                                                               |
|  Bastion DMZ (X.11/12) --> FortiAuth Cyber VLAN (X.50/51) [inter-VLAN]        |
|  Bastion DMZ (X.11/12) --> AD Cyber VLAN (X.60) [inter-VLAN]                  |
|  FortiAuth Cyber (X.50/51) --> AD Cyber VLAN (X.60) [same VLAN]               |
|  FortiAuth Primary (X.50) <--> FortiAuth Secondary (X.51) [HA sync]           |
|  Note: Inter-VLAN routing via Fortigate firewall at each site                 |
|                                                                               |
|  SIEM (centralized or per-site):                                              |
|  ================================                                             |
|  All Bastion Sites --> SIEM  [syslog 514/UDP or 6514/TCP]                     |
|                                                                               |
+===============================================================================+
```

### 1.3 Network Topology Summary

```
+===============================================================================+
|  NETWORK TOPOLOGY SUMMARY                                                     |
+===============================================================================+
|                                                                               |
|  Total Network Segments per Site (2 VLANs per site):                          |
|  ===================================================                          |
|                                                                               |
|  Site 1 DMZ VLAN:    10.10.1.0/25   (HAProxy, Bastion, RDS)                   |
|  Site 1 Cyber VLAN:  10.10.1.128/25 (FortiAuth HA, Active Directory)          |
|                                                                               |
|  Site 2 DMZ VLAN:    10.10.2.0/25   (same layout as Site 1)                   |
|  Site 2 Cyber VLAN:  10.10.2.128/25                                           |
|                                                                               |
|  Site 3 DMZ VLAN:    10.10.3.0/25                                             |
|  Site 3 Cyber VLAN:  10.10.3.128/25                                           |
|                                                                               |
|  Site 4 DMZ VLAN:    10.10.4.0/25                                             |
|  Site 4 Cyber VLAN:  10.10.4.128/25                                           |
|                                                                               |
|  Site 5 DMZ VLAN:    10.10.5.0/25                                             |
|  Site 5 Cyber VLAN:  10.10.5.128/25                                           |
|                                                                               |
|  Access Manager Networks (client-managed):                                    |
|  - Managed by client team in their datacenters                                |
|  - Connected via MPLS to all Bastion sites (HTTPS 443)                        |
|                                                                               |
|  Target Networks:                                                             |
|  - Windows Targets: 10.30.0.0/16  (Windows Server 2022, ~100-200/site)        |
|  - Linux Targets:   10.40.0.0/16  (RHEL 9/10, ~100-200/site)                  |
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
|  SITE 1 (DC-1) - DETAILED ARCHITECTURE WITH DUAL VLAN                         |
+===============================================================================+
|                                                                               |
|  MPLS (to AM)  +                                                              |
|                |                                                              |
|  +-------------v-----------+                                                  |
|  |    Fortigate Firewall    | 10.10.1.1 / 10.10.1.129                         |
|  |  - Perimeter + IPS/IDS  | MPLS uplink + inter-VLAN routing                |
|  +---+-------------------+-+                                                  |
|      |                   |                                                    |
|      |  DMZ VLAN         |  Cyber VLAN                                        |
|      |  10.10.1.0/25     |  10.10.1.128/25                                    |
|      |                   |                                                    |
|  +---v-------------------v-------------------------------------------+       |
|  |  DMZ VLAN (10.10.1.0/25)                                          |       |
|  |  +-------------------+    +-------------------+                   |       |
|  |  | HAProxy-1 Primary |VRRP| HAProxy-2 Backup  |                   |       |
|  |  | 10.10.1.5         |<-->| 10.10.1.6         |                   |       |
|  |  | VIP: 10.10.1.100  |    | (Standby)         |                   |       |
|  |  +--------+----------+    +----------+--------+                   |       |
|  |           |                          |                            |       |
|  |           +------------+-------------+                            |       |
|  |                        | Load Balancing                           |       |
|  |        +---------------+---------------+                          |       |
|  |        |                               |                          |       |
|  |  +-----v-----------+         +---------v-----------+              |       |
|  |  | WALLIX Bastion-1|<------->| WALLIX Bastion-2    |              |       |
|  |  | 10.10.1.11      |  Sync   | 10.10.1.12          |              |       |
|  |  | - Session Mgr   |SSH+DB   | - Session Mgr       |              |       |
|  |  | - Cred Vault    |2242/TCP | - Cred Vault        |              |       |
|  |  | - MariaDB       |3306-7   | - MariaDB (replica) |              |       |
|  |  +-----------------+         +---------------------+              |       |
|  |        |                               |                          |       |
|  |        +---------------+---------------+                          |       |
|  |                        |                                          |       |
|  |               +--------v--------+                                 |       |
|  |               |  WALLIX RDS     |  10.10.1.30                     |       |
|  |               |  Windows 2022   |  RemoteApp jump host            |       |
|  |               +--------+--------+                                 |       |
|  |                        | RDP to OT targets                        |       |
|  +------------------------+------------------------------------------+       |
|                                                                               |
|  +--------------------------------------------------------------------+       |
|  |  Cyber VLAN (10.10.1.128/25)                                       |       |
|  |  +---------------------------+    +---------------------------+    |       |
|  |  | FortiAuth-1 (Primary)     |<-->| FortiAuth-2 (Secondary)   |    |       |
|  |  | 10.10.1.50                |HA  | 10.10.1.51                |    |       |
|  |  | VIP: 10.10.1.52 (HA)      |    | RADIUS 1812/1813 UDP      |    |       |
|  |  +-------------+-------------+    +---------------------------+    |       |
|  |                | LDAP (636)                                         |       |
|  |  +-------------v-------------+                                     |       |
|  |  | Active Directory DC       |  10.10.1.60                         |       |
|  |  | Windows Server 2022       |  LDAP 389, LDAPS 636, Kerberos 88   |       |
|  |  +---------------------------+                                     |       |
|  +--------------------------------------------------------------------+       |
|                                                                               |
|  VLAN Routing (Fortigate):                                                    |
|  - Bastion (DMZ) -> FortiAuth/AD (Cyber): RADIUS 1812, LDAP 636              |
|  - FortiAuth (Cyber) -> AD (Cyber): LDAP 636 (same VLAN, no routing needed)  |
|  - Bastion (DMZ) -> Targets: RDP 3389, SSH 22, WinRM 5985/5986               |
|  - Bastion (DMZ) -> AM via MPLS: HTTPS 443                                   |
|                                                                               |
+===============================================================================+
```

### 2.2 Site Component Breakdown

```
+===============================================================================+
|  PER-SITE COMPONENT INVENTORY (ALL 5 SITES IDENTICAL)                         |
+===============================================================================+
|                                                                               |
|  DMZ VLAN (10.10.X.0/25):                                                     |
|  Component              | Quantity | IP              | Role                   |
|  ----------------------+----------+-----------------+----------------------   |
|  Fortigate Firewall     | 1        | 10.10.X.1       | Perimeter + VLAN gw   |
|  HAProxy Primary        | 1        | 10.10.X.5       | Load balancer         |
|  HAProxy Backup         | 1        | 10.10.X.6       | Load balancer (HA)    |
|  HAProxy VIP            | -        | 10.10.X.100     | Virtual IP (VRRP)     |
|  WALLIX Bastion-1       | 1        | 10.10.X.11      | PAM appliance         |
|  WALLIX Bastion-2       | 1        | 10.10.X.12      | PAM appliance (HA)    |
|  WALLIX RDS             | 1        | 10.10.X.30      | OT jump host          |
|                                                                               |
|  Cyber VLAN (10.10.X.128/25):                                                 |
|  Component              | Quantity | IP              | Role                   |
|  ----------------------+----------+-----------------+----------------------   |
|  Fortigate (Cyber iface)| -        | 10.10.X.129     | Cyber VLAN gateway    |
|  FortiAuth-1 (Primary)  | 1        | 10.10.X.50      | MFA primary (RADIUS)  |
|  FortiAuth-2 (Secondary)| 1        | 10.10.X.51      | MFA secondary (HA)    |
|  FortiAuth VIP          | -        | 10.10.X.52      | FortiAuth HA VIP      |
|  Active Directory DC    | 1        | 10.10.X.60      | LDAP/Kerberos         |
|                                                                               |
|  X = Site number (1-5)                                                        |
|                                                                               |
|  Total per site: 9 physical/virtual components                                |
|  Total across 5 sites:                                                        |
|  - 10x HAProxy servers              - 10x FortiAuthenticator nodes            |
|  - 10x WALLIX Bastion appliances    - 5x Active Directory DCs                 |
|  - 5x WALLIX RDS servers            - 5x Fortigate firewalls                  |
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
|  Step 1: User Login (AD credentials + FortiToken TOTP)                        |
|  =======================================================                     |
|                                                                               |
|  +------------+                                                               |
|  | End User   |                                                               |
|  | Workstation|                                                               |
|  +-----+------+                                                               |
|        | 1. HTTPS (443)                                                       |
|        |    URL: https://bastion-site1.company.com                            |
|        v                                                                      |
|  +-----+---------------+  DMZ VLAN (10.10.1.0/25)                             |
|  | HAProxy VIP         |                                                      |
|  | 10.10.1.100:443     |                                                      |
|  +-----+---------------+                                                      |
|        | 2. Load balance to Bastion                                           |
|        v                                                                      |
|  +-----+---------------+  DMZ VLAN                                            |
|  | WALLIX Bastion-1    |                                                      |
|  | 10.10.1.11:443      |                                                      |
|  +-----+---------------+                                                      |
|        | 3a. RADIUS Auth (TOTP) — inter-VLAN via Fortigate                    |
|        v                                                                      |
|  +-----+------------------+  Cyber VLAN (10.10.1.128/25)                      |
|  | FortiAuthenticator     |                                                   |
|  | 10.10.1.50 (Primary)   |                                                   |
|  | or VIP 10.10.1.52      |                                                   |
|  +-----+------------------+                                                   |
|        | 3b. LDAP user validation (same Cyber VLAN)                           |
|        v                                                                      |
|  +-----+------------------+  Cyber VLAN                                       |
|  | Active Directory DC    |                                                   |
|  | 10.10.1.60             |                                                   |
|  +-----+------------------+                                                   |
|        | 4. User enters TOTP code (FortiToken Mobile app)                     |
|        |    FortiAuth returns RADIUS Access-Accept                            |
|        v                                                                      |
|  (Optional: 3c. SSO via AM if configured — Bastion → AM via MPLS)             |
|  (AM is client-managed; SSO is optional, RADIUS is baseline)                 |
|                                                                               |
|  Step 2: Target Connection (SSH Example)                                      |
|  ========================================                                     |
|                                                                               |
|  +------------+                                                               |
|  | End User   |                                                               |
|  | (Authed)   |                                                               |
|  +-----+------+                                                               |
|        | 5. SSH (22) via Bastion portal                                       |
|        |    Target: prod-rhel-01.company.com                                  |
|        v                                                                      |
|  +-----+---------------+  DMZ VLAN                                            |
|  | WALLIX Bastion-1    |                                                      |
|  | Session Manager     |                                                      |
|  +-----+---------------+                                                      |
|        | 6. Retrieve credential from vault                                    |
|        | 7. Initiate SSH proxy connection                                     |
|        v                                                                      |
|  +-----+---------------+                                                      |
|  | Target: RHEL Server |                                                      |
|  | prod-rhel-01        |                                                      |
|  | 10.40.0.10:22       |                                                      |
|  +-------------------+                                                        |
|                                                                               |
|  Data Flow Summary:                                                           |
|  User → HAProxy (DMZ) → Bastion (DMZ) → RADIUS → FortiAuth (Cyber)            |
|  FortiAuth (Cyber) → LDAP → AD DC (Cyber)                                     |
|  User (authenticated) → Bastion → Target (SSH/RDP proxied)                    |
|  Optionally: Bastion (DMZ) → AM (MPLS) for SSO                                |
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

### 3.3 Inter-VLAN Authentication Flow (Per Site)

```
+===============================================================================+
|  INTER-VLAN AUTH FLOW - DMZ VLAN TO CYBER VLAN (VIA FORTIGATE)                |
+===============================================================================+
|                                                                               |
|  DMZ VLAN (10.10.X.0/25)              Cyber VLAN (10.10.X.128/25)             |
|  ========================             ==============================          |
|                                                                               |
|  +------------------+                 +------------------+                   |
|  | WALLIX Bastion   |                 | FortiAuth-1      |                   |
|  | 10.10.X.11       |  RADIUS 1812    | 10.10.X.50       |                   |
|  | (RADIUS client)  +---------------->| (RADIUS server)  |                   |
|  |                  |  UDP (Fortigate) |                  |                   |
|  |                  |<----------------| Access-Challenge  |                   |
|  |                  |  TOTP prompt    |     or            |                   |
|  |                  +---------------->| Access-Accept     |                   |
|  +------------------+  TOTP response  +--------+---------+                   |
|                                                | LDAP 636                     |
|                                       +--------v---------+                   |
|  +------------------+                 | Active Directory |                   |
|  | WALLIX Bastion   |  LDAPS 636      | 10.10.X.60       |                   |
|  | 10.10.X.11       +---------------->| User lookup      |                   |
|  | (LDAP client)    |  (Fortigate)    | Group membership |                   |
|  +------------------+                 +------------------+                   |
|                                                                               |
|  Fortigate Inter-VLAN Policies Required:                                      |
|  ========================================                                     |
|  FROM: DMZ VLAN (10.10.X.0/25)                                               |
|  TO:   Cyber VLAN (10.10.X.128/25)                                            |
|  PORTS: UDP 1812 (RADIUS), UDP 1813 (RADIUS acct), TCP 636 (LDAPS)            |
|  SOURCES: Bastion-1 (X.11), Bastion-2 (X.12)                                 |
|  DESTINATIONS: FortiAuth VIP (X.52), AD DC (X.60)                            |
|                                                                               |
|  FROM: Cyber VLAN (10.10.X.128/25)  (FortiAuth → AD, same VLAN, no routing)  |
|  FortiAuth uses AD directly within Cyber VLAN — no firewall policy needed     |
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
|  Bastion-1 (X.11)    | Bastion-2 (X.12)   | 2242     | TCP      | SSH Tunnel  |
|  Bastion-2 (X.12)    | Bastion-1 (X.11)   | 2242     | TCP      | SSH Tunnel  |
|  Bastion-1 (X.11)    | Bastion-2 (X.12)   | 3306     | TCP      | MariaDB     |
|  Bastion-2 (X.12)    | Bastion-1 (X.11)   | 3306     | TCP      | MariaDB     |
|  Bastion-1 (X.11)    | Bastion-2 (X.12)   | 3307     | TCP      | MariaDB Src |
|  Bastion-2 (X.12)    | Bastion-1 (X.11)   | 3307     | TCP      | MariaDB Src |
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
|  - 2242: SSH tunnel for DB replication (managed by autossh)                    |
|  - 3306: MariaDB replication (inbound, via SSH tunnel)                        |
|  - 3307: MariaDB replication source port (outbound)                           |
|                                                                               |
+===============================================================================+
```

### 4.5 Access Manager Integration Ports (MPLS)

```
+===============================================================================+
|  ACCESS MANAGER <-> BASTION (MPLS) — AM IS CLIENT-MANAGED                    |
+===============================================================================+
|                                                                               |
|  Source              | Destination        | Port  | Protocol | Purpose        |
|  --------------------+--------------------+-------+----------+-------------   |
|  AM (client DC-A)    | Bastion VIP X.100  | 443   | TCP/HTTPS| Health checks  |
|  AM (client DC-A)    | Bastion VIP X.100  | 443   | TCP/HTTPS| SSO callbacks  |
|  AM (client DC-B)    | Bastion VIP X.100  | 443   | TCP/HTTPS| SSO callbacks  |
|                                                                               |
|  Bastion Sites 1-5   | AM Primary URL     | 443   | TCP/HTTPS| SAML auth req  |
|  Bastion Sites 1-5   | AM Secondary URL   | 443   | TCP/HTTPS| SAML failover  |
|                                                                               |
|  Notes:                                                                       |
|  - AM IP addresses are in client's network — get from client team             |
|  - Bastion uses AM CA cert for HTTPS trust verification                       |
|  - AM manages its own HA replication — not our scope                          |
|                                                                               |
+===============================================================================+
```

### 4.6 Authentication & MFA Ports (Per-Site, Inter-VLAN)

```
+===============================================================================+
|  AUTHENTICATION SERVICES (PER-SITE FORTIAUTH + AD, CYBER VLAN)                |
+===============================================================================+
|                                                                               |
|  Note: X = site number (1-5)                                                  |
|  - Source Bastion is in DMZ VLAN (10.10.X.0/25)                               |
|  - FortiAuth/AD are in Cyber VLAN (10.10.X.128/25)                            |
|  - Traffic routes via Fortigate inter-VLAN policy (same site)                 |
|                                                                               |
|  RADIUS (FortiAuthenticator — per site):                                      |
|  Source              | Destination        | Port  | Protocol | Purpose        |
|  --------------------+--------------------+-------+----------+-------------   |
|  Bastion-1 (X.11)    | FortiAuth-1 (X.50) | 1812  | UDP      | RADIUS auth    |
|  Bastion-2 (X.12)    | FortiAuth-1 (X.50) | 1812  | UDP      | RADIUS auth    |
|  Bastion-1 (X.11)    | FortiAuth-1 (X.50) | 1813  | UDP      | RADIUS acct    |
|  Bastion-1 (X.11)    | FortiAuth-2 (X.51) | 1812  | UDP      | RADIUS backup  |
|  Bastion-2 (X.12)    | FortiAuth-2 (X.51) | 1812  | UDP      | RADIUS backup  |
|                                                                               |
|  FortiAuth HA Replication (within Cyber VLAN — no inter-VLAN routing):        |
|  Source              | Destination        | Port  | Protocol | Purpose        |
|  --------------------+--------------------+-------+----------+-------------   |
|  FortiAuth-1 (X.50)  | FortiAuth-2 (X.51) | 23    | TCP      | HA sync        |
|  FortiAuth-2 (X.51)  | FortiAuth-1 (X.50) | 23    | TCP      | HA sync        |
|                                                                               |
|  Active Directory LDAP (per site — inter-VLAN):                               |
|  Source              | Destination        | Port  | Protocol | Purpose        |
|  --------------------+--------------------+-------+----------+-------------   |
|  Bastion-1 (X.11)    | AD DC (X.60)       | 636   | TCP/LDAPS| Secure LDAP    |
|  Bastion-2 (X.12)    | AD DC (X.60)       | 636   | TCP/LDAPS| Secure LDAP    |
|  Bastion-1 (X.11)    | AD DC (X.60)       | 88    | TCP/UDP  | Kerberos       |
|  Bastion-1 (X.11)    | AD DC (X.60)       | 3268  | TCP      | Global Catalog |
|                                                                               |
|  FortiAuth → AD (within Cyber VLAN, same VLAN, no Fortigate needed):          |
|  Source              | Destination        | Port  | Protocol | Purpose        |
|  --------------------+--------------------+-------+----------+-------------   |
|  FortiAuth-1 (X.50)  | AD DC (X.60)       | 636   | TCP/LDAPS| User sync      |
|  FortiAuth-2 (X.51)  | AD DC (X.60)       | 636   | TCP/LDAPS| User sync      |
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
|  Bastion Sites 1-5   | NTP Server         | 123   | UDP/NTP  | Time sync      |
|  HAProxy Sites 1-5   | NTP Server         | 123   | UDP/NTP  | Time sync      |
|  FortiAuth/AD Sites  | NTP Server         | 123   | UDP/NTP  | Time sync      |
|                                                                               |
|  SIEM (Log Forwarding):                                                       |
|  Source              | Destination        | Port  | Protocol | Purpose        |
|  --------------------+--------------------+-------+----------+-------------   |
|  Bastion Sites 1-5   | SIEM               | 514   | UDP/Syslog| Audit logs    |
|  Bastion Sites 1-5   | SIEM               | 6514  | TCP/TLS  | Secure logs    |
|  HAProxy Sites 1-5   | SIEM               | 514   | UDP/Syslog| Access logs   |
|  FortiAuth Sites 1-5 | SIEM               | 514   | UDP/Syslog| Auth logs     |
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
|  23    | TCP         | FortiAuth-1 ↔ FortiAuth-2    | FortiAuth HA sync       |
|  80    | TCP/HTTP    | Users → HAProxy VIP          | HTTP→HTTPS redirect     |
|  88    | TCP/UDP     | Bastion → AD (Cyber VLAN)    | Kerberos auth           |
|  123   | UDP/NTP     | All → NTP Servers            | Time sync               | 
|  161   | UDP/SNMP    | NMS → Bastion                | SNMP queries            |
|  389   | TCP/LDAP    | Bastion → AD                 | LDAP queries            |
|  443   | TCP/HTTPS   | Users → HAProxy VIP          | Web UI/API              |
|  443   | TCP/HTTPS   | HAProxy → Bastion            | Backend pool            |
|  443   | TCP/HTTPS   | Bastion → AM (via MPLS)      | SAML auth / health chk  |
|  443   | TCP/HTTPS   | AM → Bastion (via MPLS)      | SSO callbacks           |
|  514   | UDP/Syslog  | Bastion → SIEM               | Audit logs              |
|  636   | TCP/LDAPS   | Bastion → AD (Cyber VLAN)    | Secure LDAP (inter-VLAN)|
|  636   | TCP/LDAPS   | FortiAuth → AD (Cyber VLAN)  | User sync (same VLAN)   |
|  1812  | UDP/RADIUS  | Bastion → FortiAuth (Cyber)  | RADIUS auth (inter-VLAN)|
|  1813  | UDP/RADIUS  | Bastion → FortiAuth (Cyber)  | RADIUS accounting       |
|  2242  | TCP/SSH     | Bastion-1 ↔ Bastion-2        | SSH tunnel (autossh)    |
|  3268  | TCP/GC      | Bastion → AD (Cyber VLAN)    | Global Catalog          |
|  3306  | TCP/MariaDB | Bastion-1 ↔ Bastion-2        | DB replication          |
|  3389  | TCP/RDP     | Users → HAProxy VIP          | RDP proxy sessions      |
|  3389  | TCP/RDP     | Bastion → Windows Targets    | RDP target access       |
|  3389  | TCP/RDP     | Bastion → RDS                | RDS jump host           |
|  3389  | TCP/RDP     | RDS → OT Targets             | OT RemoteApp            |
|  3307  | TCP/MariaDB | Bastion-1 ↔ Bastion-2        | Replication source      |
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
|  VLAN DESIGN - SITE 1 (REPEATED FOR ALL 5 SITES, X = SITE NUMBER)             |
+===============================================================================+
|                                                                               |
|  VLAN ID | Name            | Subnet             | Purpose                     |
|  --------+-----------------+--------------------+-------------------------    |
|  1X      | DMZ             | 10.10.X.0/25       | HAProxy, Bastion, RDS       |
|  1X1     | Cyber           | 10.10.X.128/25     | FortiAuth HA, AD DC         |
|  999     | Uplink          | MPLS               | MPLS uplink to core         |
|                                                                               |
|  VLAN 11 (DMZ) - User-Facing PAM Services:                                    |
|  ==========================================                                   |
|  Gateway (Fortigate):  10.10.1.1                                              |
|  HAProxy-1:            10.10.1.5                                              |
|  HAProxy-2:            10.10.1.6                                              |
|  HAProxy VIP:          10.10.1.100                                            |
|  WALLIX Bastion-1:     10.10.1.11                                             |
|  WALLIX Bastion-2:     10.10.1.12                                             |
|  WALLIX RDS:           10.10.1.30                                             |
|  Subnet:               10.10.1.0/25 (126 usable IPs)                         |
|  Allowed Inbound:      HTTPS(443), SSH(22), RDP(3389)                         |
|  Allowed Outbound:     RADIUS(1812) to Cyber, LDAPS(636) to Cyber             |
|                        SSH(22)/RDP(3389)/WinRM(5985) to targets               |
|                        HTTPS(443) to AM via MPLS                              |
|                                                                               |
|  VLAN 111 (Cyber) - Authentication Infrastructure:                            |
|  =================================================                           |
|  Gateway (Fortigate):  10.10.1.129                                            |
|  FortiAuth-1 (Primary):  10.10.1.50                                           |
|  FortiAuth-2 (Secondary):10.10.1.51                                           |
|  FortiAuth HA VIP:       10.10.1.52                                           |
|  Active Directory DC:    10.10.1.60                                           |
|  Subnet:               10.10.1.128/25 (126 usable IPs)                        |
|  Allowed Inbound:      RADIUS(1812/1813) from DMZ, LDAPS(636) from DMZ        |
|  Allowed Outbound:     LDAPS(636) to AD within Cyber VLAN                     |
|  Internal (no routing):  FortiAuth ↔ AD direct within Cyber VLAN              |
|                                                                               |
+===============================================================================+
```

### 5.2 Multi-Site VLAN Summary

```
+===============================================================================+
|  VLAN SUMMARY - ALL 5 SITES                                                   |
+===============================================================================+
|                                                                               |
|  Site  | DMZ VLAN  | DMZ Subnet     | Cyber VLAN | Cyber Subnet               |
|  ------+-----------+----------------+------------+---------------------------  |
|  1     | VLAN 11   | 10.10.1.0/25   | VLAN 111   | 10.10.1.128/25            |
|  2     | VLAN 12   | 10.10.2.0/25   | VLAN 121   | 10.10.2.128/25            |
|  3     | VLAN 13   | 10.10.3.0/25   | VLAN 131   | 10.10.3.128/25            |
|  4     | VLAN 14   | 10.10.4.0/25   | VLAN 141   | 10.10.4.128/25            |
|  5     | VLAN 15   | 10.10.5.0/25   | VLAN 151   | 10.10.5.128/25            |
|                                                                               |
|  Target Networks (shared across all sites via MPLS/routing):                  |
|  ============================================================                 |
|  Windows Targets:  10.30.0.0/16  (Windows Server 2022, ~100-200/site)         |
|  Linux Targets:    10.40.0.0/16  (RHEL 9/10, ~100-200/site)                   |
|                                                                               |
|  Routing Rules (Fortigate per site):                                          |
|  ====================================                                         |
|  DMZ VLANs → Cyber VLAN:         RADIUS(1812), LDAPS(636) only               |
|  DMZ VLANs → Target Networks:    SSH(22), RDP(3389), WinRM(5985/5986)        |
|  DMZ VLANs → MPLS:               HTTPS(443) to AM only                       |
|  Cyber VLANs:                    INTERNAL only — no inbound from targets      |
|  Site-to-Site:                   BLOCKED (no direct Bastion-to-Bastion)       |
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
|  Access Manager (Client-Managed — IPs to be confirmed with client team):      |
|  =======================================================================      |
|  AM Primary URL:   https://am1.client.com  (client provides actual IPs)       |
|  AM Secondary URL: https://am2.client.com  (client provides actual IPs)       |
|                                                                               |
|  Site 1 (DC-1):                                                               |
|  ===================================                                          |
|  DMZ VLAN 11:  10.10.1.0/25                                                   |
|    .1          Fortigate DMZ interface                                        |
|    .5          HAProxy-1                                                      |
|    .6          HAProxy-2                                                      |
|    .11         WALLIX Bastion-1                                               |
|    .12         WALLIX Bastion-2                                               |
|    .30         WALLIX RDS (Windows 2022)                                      |
|    .100        HAProxy VIP (VRRP)                                             |
|                                                                               |
|  Cyber VLAN 111:  10.10.1.128/25                                              |
|    .129        Fortigate Cyber VLAN interface                                 |
|    .50         FortiAuthenticator-1 (Primary)                                 |
|    .51         FortiAuthenticator-2 (Secondary)                               |
|    .52         FortiAuthenticator HA VIP                                      |
|    .60         Active Directory DC                                            |
|                                                                               |
|  Site 2 (DC-2): (same layout as Site 1, second octet stays 10.10.2.x)         |
|  ===================================                                          |
|  DMZ VLAN 12:  10.10.2.0/25       (X.5/6/11/12/30/100 same offsets)           |
|  Cyber VLAN 121: 10.10.2.128/25   (X.50/51/52/60 same offsets)                |
|                                                                               |
|  Site 3 (DC-3):                                                               |
|  ===================================                                          |
|  DMZ VLAN 13:  10.10.3.0/25                                                   |
|  Cyber VLAN 131: 10.10.3.128/25                                               |
|                                                                               |
|  Site 4 (DC-4):                                                               |
|  ===================================                                          |
|  DMZ VLAN 14:  10.10.4.0/25                                                   |
|  Cyber VLAN 141: 10.10.4.128/25                                               |
|                                                                               |
|  Site 5 (DC-5):                                                               |
|  ===================================                                          |
|  DMZ VLAN 15:  10.10.5.0/25                                                   |
|  Cyber VLAN 151: 10.10.5.128/25                                               |
|                                                                               |
|  Target Systems:                                                              |
|  ===============                                                              |
|  10.30.0.0/16    Windows Server 2022 targets (~100-200 per site)               |
|    .0.0/24       Production Windows                                           |
|    .1.0/24       OT Windows (isolated)                                        |
|                                                                               |
|  10.40.0.0/16    Linux targets (RHEL 9/10, ~100-200 per site)                  |
|    .0.0/24       Production RHEL 10                                           |
|    .1.0/24       Production RHEL 9 (legacy)                                   |
|                                                                               |
+===============================================================================+
```

### 6.2 DNS Records

```
+===============================================================================+
|  DNS FORWARD ZONE RECORDS                                                     |
+===============================================================================+
|                                                                               |
|  Access Manager (client-managed DNS, obtain from AM team):                    |
|  am1.client.com                        A    [client provides IP]              |
|  am2.client.com                        A    [client provides IP]              |
|                                                                               |
|  Site 1 (DC-1) — DMZ VLAN:                                                    |
|  bastion-site1.company.com             A    10.10.1.100  (HAProxy VIP)        |
|  haproxy1-site1.company.com            A    10.10.1.5                         |
|  haproxy2-site1.company.com            A    10.10.1.6                         |
|  bastion1-site1.company.com            A    10.10.1.11                        |
|  bastion2-site1.company.com            A    10.10.1.12                        |
|  rds-site1.company.com                 A    10.10.1.30                        |
|                                                                               |
|  Site 1 (DC-1) — Cyber VLAN:                                                  |
|  fortiauth1-site1.company.com          A    10.10.1.50                        |
|  fortiauth2-site1.company.com          A    10.10.1.51                        |
|  fortiauth-site1.company.com           A    10.10.1.52  (HA VIP)              |
|  dc-site1.company.com                  A    10.10.1.60                        |
|                                                                               |
|  Site 2 (DC-2) — DMZ VLAN:                                                    |
|  bastion-site2.company.com             A    10.10.2.100                       |
|  bastion1-site2.company.com            A    10.10.2.11                        |
|  bastion2-site2.company.com            A    10.10.2.12                        |
|  rds-site2.company.com                 A    10.10.2.30                        |
|                                                                               |
|  Site 2 (DC-2) — Cyber VLAN:                                                  |
|  fortiauth-site2.company.com           A    10.10.2.52  (HA VIP)              |
|  dc-site2.company.com                  A    10.10.2.60                        |
|                                                                               |
|  Sites 3-5: Same naming pattern (replace 2 with 3, 4, or 5)                  |
|                                                                               |
|  NTP / SIEM (centralized or per-site — adjust to actual infrastructure):      |
|  ntp1.company.com                      A    [NTP server IP]                   |
|  siem.company.com                      A    [SIEM server IP]                  |
|                                                                               |
|  Wildcard (for SSL certificate):                                              |
|  *.company.com                         CNAME [Certificate CN]                 |
|                                                                               |
+===============================================================================+
```

---

## References

### Related Documentation

- [00-prerequisites.md](00-prerequisites.md) - Hardware and software requirements
- [01-network-design.md](01-network-design.md) - Detailed network configuration
- [03-fortiauthenticator-ha.md](03-fortiauthenticator-ha.md) - Per-site FortiAuth HA
- [04-ad-per-site.md](04-ad-per-site.md) - Per-site Active Directory
- [11-testing-validation.md](11-testing-validation.md) - Testing procedures
- [HOWTO.md](HOWTO.md) - Main installation guide

---

**Document Version**: 2.0
**Last Updated**: April 2026

### External Resources

- WALLIX Bastion Network Requirements: https://pam.wallix.one/documentation
- HAProxy Configuration Guide: https://www.haproxy.org/
- WALLIX Bastion HA Database Replication: See deployment guide section 5

---

**Document Version**: 1.0
**Last Updated**: February 2026
**Validated By**: Network Architecture Team
**Approval Status**: Approved for Implementation
