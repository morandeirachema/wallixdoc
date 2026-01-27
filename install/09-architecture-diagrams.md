# Architecture Diagrams - Services & Ports Reference

## Complete Visual Reference for WALLIX Bastion 12.x Multi-Site Deployment

---

## Table of Contents

- [Complete Infrastructure Overview](#complete-infrastructure-overview)
- [Site A - Primary HA Cluster](#site-a---primary-ha-cluster)
- [Site B - Secondary HA Cluster](#site-b---secondary-ha-cluster)
- [Site C - Remote Standalone](#site-c---remote-standalone)
- [Network Flow Diagrams](#network-flow-diagrams)
- [Service Architecture](#service-architecture)
- [Port Reference Matrix](#port-reference-matrix)
- [Firewall Rules](#firewall-rules)

---

## Complete Infrastructure Overview

### Multi-Site Topology

```
                                    CORPORATE WAN / MPLS NETWORK
    =================================================================================================
                        |                           |                           |
                        |                           |                           |
                        v                           v                           v
    +-----------------------------------+-----------------------------------+-----------------------------------+
    |           SITE A - PRIMARY        |       SITE B - SECONDARY          |        SITE C - REMOTE            |
    |            Headquarters           |       Manufacturing Plant         |          Field Office             |
    +-----------------------------------+-----------------------------------+-----------------------------------+
    |                                   |                                   |                                   |
    |   +---------------------------+   |   +---------------------------+   |   +---------------------------+   |
    |   |      HA CLUSTER           |   |   |      HA CLUSTER           |   |   |       STANDALONE          |   |
    |   |    (Active-Active)        |   |   |   (Active-Passive)        |   |   |   (Offline-Capable)       |   |
    |   |                           |   |   |                           |   |   |                           |   |
    |   |  +---------+ +---------+  |   |   |  +---------+ +---------+  |   |   |      +---------+          |   |
    |   |  |wallix-a1| |wallix-a2|  |   |   |  |wallix-b1| |wallix-b2|  |   |   |      |wallix-c1|          |   |
    |   |  | Active  | | Active  |  |   |   |  | Active  | | Standby |  |   |   |      | Primary |          |   |
    |   |  |10.0.1.10| |10.0.1.11|  |   |   |  |10.0.2.10| |10.0.2.11|  |   |   |      |10.0.3.10|          |   |
    |   |  +----+----+ +----+----+  |   |   |  +----+----+ +----+----+  |   |   |      +----+----+          |   |
    |   |       |           |       |   |   |       |           |       |   |   |           |               |   |
    |   |       +-----+-----+       |   |   |       +-----+-----+       |   |   |           |               |   |
    |   |             |             |   |   |             |             |   |   |           |               |   |
    |   |        +----+----+        |   |   |        +----+----+        |   |   |      +----+----+          |   |
    |   |        |   VIP   |        |   |   |        |   VIP   |        |   |   |      |  Direct |          |   |
    |   |        |10.0.1.20|        |   |   |        |10.0.2.20|        |   |   |      |  Access |          |   |
    |   |        +----+----+        |   |   |        +----+----+        |   |   |      +----+----+          |   |
    |   +-------------|-----------+   |   +-------------|-----------+   |   +-----------|--------------+   |
    |                 |               |                 |               |               |                   |
    |   ==============|===============|   ==============|===============|   ============|==================|
    |             FIREWALL            |             FIREWALL            |            FIREWALL              |
    |   ==============|===============|   ==============|===============|   ============|==================|
    |                 |               |                 |               |               |                   |
    |   +-------------+-------------+ |   +-------------+-------------+ |   +-----------+---------------+   |
    |   |        OT NETWORK         | |   |        OT NETWORK         | |   |        OT NETWORK         |   |
    |   |       10.0.10.0/24        | |   |       10.0.20.0/24        | |   |       10.0.30.0/24        |   |
    |   |                           | |   |                           | |   |                           |   |
    |   | +-----+ +-----+ +-----+   | |   | +-----+ +-----+ +-----+   | |   | +-----+ +-----+           |   |
    |   | | PLC | | HMI | |SCADA|   | |   | | DCS | | PLC | | RTU |   | |   | | RTU | | PLC |           |   |
    |   | +-----+ +-----+ +-----+   | |   | +-----+ +-----+ +-----+   | |   | +-----+ +-----+           |   |
    |   +---------------------------+ |   +---------------------------+ |   +---------------------------+   |
    +-----------------------------------+-----------------------------------+-----------------------------------+
                        |                           |                           |
                        |<-------- Multi-Site Sync (HTTPS 443) ---------------->|
```

### Site Configuration Summary

| Site | Location | Configuration | Nodes | HA Mode | Connectivity | Primary Use Case |
|------|----------|---------------|-------|---------|--------------|------------------|
| **A** | Headquarters | HA Cluster | 2 | Active-Active | Always Online | Central management |
| **B** | Manufacturing | HA Cluster | 2 | Active-Passive | Always Online | Regional access |
| **C** | Field Office | Standalone | 1 | N/A | Intermittent | Edge access |

---

## Site A - Primary HA Cluster

### Detailed Node Architecture

```
+=====================================================================================+
|                        SITE A - PRIMARY HA CLUSTER (Active-Active)                  |
+=====================================================================================+
|                                                                                     |
|   MANAGEMENT NETWORK: 10.0.1.0/24              CLUSTER NETWORK: 192.168.100.0/24   |
|                                                                                     |
|   +------------------------------- LOAD BALANCER / VIP ----------------------------+|
|   |                                                                                ||
|   |                              +---------------+                                 ||
|   |                              | Virtual IP    |                                 ||
|   |                              | 10.0.1.20     |                                 ||
|   |                              | (Pacemaker)   |                                 ||
|   |                              +-------+-------+                                 ||
|   |                                      |                                         ||
|   |                           +----------+----------+                              ||
|   |                           |   Round-Robin LB    |                              ||
|   |                           +----------+----------+                              ||
|   |                                      |                                         ||
|   +--------------------------------------+----------------------------------------+|
|                                          |                                          |
|            +-----------------------------+-----------------------------+            |
|            |                                                           |            |
|            v                                                           v            |
|   +----------------------------------+    +----------------------------------+      |
|   |       NODE 1: wallix-a1          |    |       NODE 2: wallix-a2          |      |
|   |           (ACTIVE)               |    |           (ACTIVE)               |      |
|   +----------------------------------+    +----------------------------------+      |
|   |                                  |    |                                  |      |
|   | Management IP: 10.0.1.10         |    | Management IP: 10.0.1.11         |      |
|   | Cluster IP:    192.168.100.10    |    | Cluster IP:    192.168.100.11    |      |
|   |                                  |    |                                  |      |
|   | +------------------------------+ |    | +------------------------------+ |      |
|   | |         SERVICES             | |    | |         SERVICES             | |      |
|   | +------------------------------+ |    | +------------------------------+ |      |
|   | | wallix-bastion    (main)     | |    | | wallix-bastion    (main)     | |      |
|   | | postgresql        (primary)  |<======>| postgresql        (replica)  | |      |
|   | | nginx             (web)      | |DRBD| | nginx             (web)      | |      |
|   | | sshd              (access)   | |Sync| | sshd              (access)   | |      |
|   | | wabproxy          (sessions) | |    | | wabproxy          (sessions) | |      |
|   | | pacemaker         (cluster)  | |    | | pacemaker         (cluster)  | |      |
|   | | corosync          (comm)     | |    | | corosync          (comm)     | |      |
|   | +------------------------------+ |    | +------------------------------+ |      |
|   |                                  |    |                                  |      |
|   | +------------------------------+ |    | +------------------------------+ |      |
|   | |         STORAGE              | |    | |         STORAGE              | |      |
|   | +------------------------------+ |    | +------------------------------+ |      |
|   | | /              (LUKS)        |<======>| /              (LUKS)        | |      |
|   | | /var/lib/wallix (DRBD)       | |Block| /var/lib/wallix (DRBD)       | |      |
|   | | /var/lib/pgsql  (DRBD)       | |Sync| | /var/lib/pgsql  (DRBD)       | |      |
|   | +------------------------------+ |    | +------------------------------+ |      |
|   +----------------------------------+    +----------------------------------+      |
|                                                                                     |
|   +------------------------------- CLUSTER INTERCONNECT ---------------------------+|
|   |                                                                                ||
|   |   Node 1 (192.168.100.10)  <========================>  Node 2 (192.168.100.11)||
|   |                                                                                ||
|   |   Corosync:   UDP 5404-5406  (Cluster communication, heartbeat)               ||
|   |   DRBD:       TCP 7789       (Block-level data replication)                   ||
|   |   PostgreSQL: TCP 5432       (Database streaming replication)                 ||
|   |                                                                                ||
|   +--------------------------------------------------------------------------------+|
+=====================================================================================+
```

### Service Stack (Per Node)

```
+===========================================================================+
|                    WALLIX BASTION 12.x SERVICE STACK                      |
+===========================================================================+
|                                                                           |
|  +---------------------------------------------------------------------+  |
|  |                        APPLICATION LAYER                            |  |
|  |                                                                     |  |
|  |   +-------------+  +-------------+  +-------------+  +-------------+|  |
|  |   |   Web UI    |  |  REST API   |  |  SOAP API   |  | WebSocket   ||  |
|  |   |   (Admin)   |  |    (v2)     |  |  (Legacy)   |  | (Realtime)  ||  |
|  |   |  Port: 443  |  |  /api/v2/*  |  | /wabsoap/*  |  |   /ws/*     ||  |
|  |   +------+------+  +------+------+  +------+------+  +------+------+|  |
|  |          |                |                |                |       |  |
|  |          +----------------+----------------+----------------+       |  |
|  |                                   |                                 |  |
|  +-----------------------------------+--------------------------------+  |
|                                      |                                    |
|                                      v                                    |
|  +-----------------------------------+-----------------------------------+|
|  |                              NGINX                                    ||
|  |                         (Reverse Proxy)                               ||
|  |                     Port: 443 (HTTPS), 80 (HTTP)                      ||
|  +-----------------------------------+-----------------------------------+|
|                                      |                                    |
|  +-----------------------------------+-----------------------------------+|
|  |                          SESSION LAYER                                ||
|  |                                                                       ||
|  |  +-------------+  +-------------+  +-------------+  +-------------+   ||
|  |  | SSH Proxy   |  | RDP Proxy   |  | VNC Proxy   |  |Telnet Proxy |   ||
|  |  | Port: 22    |  | Port: 3389  |  | Port: 5900  |  | Port: 23    |   ||
|  |  +------+------+  +------+------+  +------+------+  +------+------+   ||
|  |         |                |                |                |          ||
|  |         +----------------+----------------+----------------+          ||
|  |                                  |                                    ||
|  +----------------------------------+------------------------------------+|
|                                     |                                     |
|                                     v                                     |
|  +----------------------------------+------------------------------------+|
|  |                        WALLIX BASTION CORE                            ||
|  |                                                                       ||
|  |  +-------------------+  +-------------------+  +-------------------+  ||
|  |  | Session Manager   |  | Access Manager    |  | Password Manager  |  ||
|  |  +-------------------+  +-------------------+  +-------------------+  ||
|  |  +-------------------+  +-------------------+  +-------------------+  ||
|  |  | Audit Engine      |  | Policy Engine     |  | Approval Workflow |  ||
|  |  +-------------------+  +-------------------+  +-------------------+  ||
|  +----------------------------------+------------------------------------+|
|                                     |                                     |
|  +----------------------------------+------------------------------------+|
|  |                            DATA LAYER                                 ||
|  |                                                                       ||
|  |  +---------------+  +---------------+  +---------------+              ||
|  |  | PostgreSQL    |  | Credential    |  | Session       |              ||
|  |  | Port: 5432    |  | Vault         |  | Storage       |              ||
|  |  | (Metadata)    |  | (AES-256-GCM) |  | (Recordings)  |              ||
|  |  +---------------+  +---------------+  +---------------+              ||
|  +-----------------------------------------------------------------------+|
|                                                                           |
|  +-----------------------------------------------------------------------+|
|  |                      HA CLUSTER LAYER (HA nodes only)                 ||
|  |                                                                       ||
|  |  +---------------+  +---------------+  +---------------+              ||
|  |  | Pacemaker     |  | Corosync      |  | DRBD          |              ||
|  |  | (Resource Mgr)|  | UDP 5404-5406 |  | TCP 7789      |              ||
|  |  +---------------+  +---------------+  +---------------+              ||
|  +-----------------------------------------------------------------------+|
+===========================================================================+
```

---

## Site B - Secondary HA Cluster

### Active-Passive Configuration

```
+===========================================================================+
|                SITE B - SECONDARY HA CLUSTER (Active-Passive)             |
+===========================================================================+
|                                                                           |
|   MANAGEMENT NETWORK: 10.0.2.0/24          CLUSTER NETWORK: 192.168.200.0/24
|                                                                           |
|                              +---------------+                            |
|                              | Virtual IP    |                            |
|                              | 10.0.2.20     |                            |
|                              | Points to     |                            |
|                              | ACTIVE only   |                            |
|                              +-------+-------+                            |
|                                      |                                    |
|                                      | (Failover only)                    |
|                                      |                                    |
|            +-------------------------+-------------------------+          |
|            |                                                   |          |
|            v                                                   v          |
|   +----------------------------------+    +----------------------------------+
|   |       NODE 1: wallix-b1          |    |       NODE 2: wallix-b2          |
|   |         ** ACTIVE **             |    |           STANDBY                |
|   +----------------------------------+    +----------------------------------+
|   |                                  |    |                                  |
|   | Management IP: 10.0.2.10         |    | Management IP: 10.0.2.11         |
|   | Cluster IP:    192.168.200.10    |    | Cluster IP:    192.168.200.11    |
|   |                                  |    |                                  |
|   | +------------------------------+ |    | +------------------------------+ |
|   | |    SERVICES (RUNNING)        | |    | |    SERVICES (STANDBY)        | |
|   | +------------------------------+ |    | +------------------------------+ |
|   | | wallix-bastion  [*] ACTIVE   | |    | | wallix-bastion  [ ] STOPPED  | |
|   | | postgresql      [*] PRIMARY  |<======>| postgresql      [ ] STANDBY  | |
|   | | nginx           [*] RUNNING  | |DRBD| | nginx           [ ] STOPPED  | |
|   | | wabproxy        [*] RUNNING  | |Sync| | wabproxy        [ ] STOPPED  | |
|   | | pacemaker       [*] RUNNING  | |    | | pacemaker       [*] RUNNING  | |
|   | | corosync        [*] RUNNING  | |    | | corosync        [*] RUNNING  | |
|   | | drbd            [*] PRIMARY  | |    | | drbd            [*] SECONDARY| |
|   | +------------------------------+ |    | +------------------------------+ |
|   |                                  |    |                                  |
|   | Storage: READ-WRITE              |    | Storage: READ-ONLY (sync)        |
|   +----------------------------------+    +----------------------------------+
|                                                                           |
|   +-----------------------------------------------------------------------+
|   |                        FAILOVER BEHAVIOR                              |
|   +-----------------------------------------------------------------------+
|   |                                                                       |
|   |   NORMAL OPERATION:                    AFTER FAILOVER:                |
|   |   -----------------                    ---------------                |
|   |                                                                       |
|   |   VIP --> Node 1 (Active)              VIP --> Node 2 (Now Active)    |
|   |           Node 2 (Standby)                     Node 1 (Failed)        |
|   |                                                                       |
|   |   Failover Time: 30-60 seconds                                        |
|   |   Data Loss: None (synchronous replication)                           |
|   |                                                                       |
|   +-----------------------------------------------------------------------+
+===========================================================================+
```

---

## Site C - Remote Standalone

### Standalone with Offline Capability

```
+===========================================================================+
|                 SITE C - REMOTE STANDALONE (Offline-Capable)              |
+===========================================================================+
|                                                                           |
|   MANAGEMENT NETWORK: 10.0.3.0/24                                         |
|                                                                           |
|   +-----------------------------------------------------------------------+
|   |                       SINGLE NODE DEPLOYMENT                          |
|   |                                                                       |
|   |                       +-------------------+                           |
|   |                       |    wallix-c1      |                           |
|   |                       |    10.0.3.10      |                           |
|   |                       +-------------------+                           |
|   |                       |                   |                           |
|   |                       |  +-------------+  |                           |
|   |                       |  |  SERVICES   |  |                           |
|   |                       |  +-------------+  |                           |
|   |                       |  |wallix-bastion| |                           |
|   |                       |  |postgresql    | |                           |
|   |                       |  |nginx         | |                           |
|   |                       |  |wabproxy      | |                           |
|   |                       |  |sshd          | |                           |
|   |                       |  +-------------+  |                           |
|   |                       |                   |                           |
|   |                       |  +-------------+  |                           |
|   |                       |  | LOCAL CACHE |  |                           |
|   |                       |  +-------------+  |                           |
|   |                       |  | Credentials | |                           |
|   |                       |  | Policies    | |                           |
|   |                       |  | Users       | |                           |
|   |                       |  | 24h TTL     | |                           |
|   |                       |  +-------------+  |                           |
|   |                       +-------------------+                           |
|   +-----------------------------------------------------------------------+
|                                                                           |
|   +-----------------------------------------------------------------------+
|   |                      OFFLINE OPERATION MODE                           |
|   +-----------------------------------------------------------------------+
|   |                                                                       |
|   |   ONLINE (Connected):                  OFFLINE (Disconnected):        |
|   |   -------------------                  ----------------------         |
|   |   * Real-time sync with primary        * Uses cached credentials      |
|   |   * Policy updates received            * Cached policies enforced     |
|   |   * Audit logs uploaded                * Audit logs queued locally    |
|   |   * Full functionality                 * Limited to cached users      |
|   |                                        * Sessions still recorded      |
|   |                                        * Auto-reconnect attempts      |
|   |                                                                       |
|   |   Sync Interval: 5 minutes             Cache TTL: 24 hours            |
|   |                                                                       |
|   +-----------------------------------------------------------------------+
+===========================================================================+
```

---

## Network Flow Diagrams

### User Access Flow

```
+===========================================================================+
|                            USER ACCESS FLOW                               |
+===========================================================================+
|                                                                           |
|   +--------+                                                  +--------+  |
|   |        |                                                  |        |  |
|   |  USER  |                                                  | TARGET |  |
|   |        |                                                  | DEVICE |  |
|   |Engineer|                                                  |        |  |
|   +---+----+                                                  | PLC    |  |
|       |                                                       | HMI    |  |
|       | 1. Connect (SSH/RDP/HTTPS)                            | RTU    |  |
|       |                                                       +---+----+  |
|       v                                                           ^       |
|   +---------------------------------------------------------------+----+  |
|   |                        WALLIX BASTION                              |  |
|   |                                                                    |  |
|   |  +----------+    +----------+    +------------+    +----------+   |  |
|   |  |          |    |          |    |            |    |          |   |  |
|   |  | 2. AUTH  |--->| 3. AUTHZ |--->| 4. CREDS   |--->| 5. PROXY |---+  |
|   |  |          |    |          |    |            |    |          |      |
|   |  | Validate |    | Check    |    | Retrieve   |    | Connect  |      |
|   |  | user     |    | policy   |    | from vault |    | to target|      |
|   |  | Check MFA|    | Check    |    | Decrypt    |    | Inject   |      |
|   |  | LDAP/AD  |    | time     |    |            |    | creds    |      |
|   |  | OIDC     |    | Approval?|    |            |    | Record   |      |
|   |  +----------+    +----------+    +------------+    +----------+      |
|   |       |               |               |                |             |
|   |       v               v               v                v             |
|   |  +----------------------------------------------------------------+  |
|   |  |                    6. AUDIT & RECORD                           |  |
|   |  |                                                                |  |
|   |  |  * Session video recording      * Keystroke logging           |  |
|   |  |  * Metadata capture             * Command extraction          |  |
|   |  |  * OCR text recognition         * File transfer logging       |  |
|   |  +----------------------------------------------------------------+  |
|   +----------------------------------------------------------------------+
|                                                                           |
|   FLOW SUMMARY:                                                           |
|   1. User connects to WALLIX (SSH:22, RDP:3389, HTTPS:443)               |
|   2. Authentication validated (local, LDAP, RADIUS, OIDC)                |
|   3. Authorization checked (policies, time windows, approvals)           |
|   4. Credentials retrieved from encrypted vault                          |
|   5. Proxied connection established to target device                     |
|   6. Session recorded and audited in real-time                           |
+===========================================================================+
```

### Multi-Site Synchronization Flow

```
+===========================================================================+
|                     MULTI-SITE SYNCHRONIZATION FLOW                       |
+===========================================================================+
|                                                                           |
|     SITE A (PRIMARY)           SITE B (SECONDARY)        SITE C (REMOTE)  |
|     ================           ==================        ===============  |
|                                                                           |
|   +------------------+       +------------------+       +------------------+
|   |                  |       |                  |       |                  |
|   |  MASTER CONFIG   |------>|  REPLICA CONFIG  |------>|  REPLICA CONFIG  |
|   |                  | HTTPS |                  | HTTPS |  (Cached)        |
|   |  * Users         | :443  |  * Users         | :443  |                  |
|   |  * Groups        |       |  * Groups        |       |  * Users (cache) |
|   |  * Policies      |       |  * Policies      |       |  * Policies      |
|   |  * Devices       |       |  * Devices       |       |  * Credentials   |
|   |  * Credentials   |       |  * Credentials   |       |                  |
|   +------------------+       +------------------+       +------------------+
|           |                          |                          |          |
|           v                          v                          v          |
|   +------------------+       +------------------+       +------------------+
|   |                  |       |                  |       |                  |
|   |   AUDIT LOGS     |<------|   AUDIT LOGS     |<------|   AUDIT LOGS     |
|   |   (Aggregated)   | HTTPS |   (Local+Upload) | HTTPS |   (Queued)       |
|   |                  | :443  |                  | :443  |                  |
|   |  * All sessions  |       |  * Local sessions|       |  * Local sessions|
|   |  * All sites     |       |  * Uploaded to A |       |  * Upload when   |
|   |  * Central search|       |                  |       |    connected     |
|   +------------------+       +------------------+       +------------------+
|                                                                           |
|   SYNC PROTOCOL:                                                          |
|   --------------                                                          |
|   Direction:     A ------> B ------> C     (Config push)                  |
|                  A <------ B <------ C     (Audit collection)             |
|   Protocol:      HTTPS (TLS 1.3)                                          |
|   Port:          443                                                      |
|   Auth:          Mutual TLS + API Keys                                    |
|   Frequency:     Real-time (config) / 5 min (audit batch)                 |
|   Encryption:    AES-256-GCM                                              |
+===========================================================================+
```

### HA Cluster Failover Flow

```
+===========================================================================+
|                        HA CLUSTER FAILOVER FLOW                           |
+===========================================================================+
|                                                                           |
|   NORMAL OPERATION                                                        |
|   ================                                                        |
|                                                                           |
|   +------------------+     Heartbeat (UDP 5404-5406)     +------------------+
|   |                  |<=================================>|                  |
|   |   NODE 1         |           every 1 second          |   NODE 2         |
|   |   ** ACTIVE **   |                                   |   STANDBY        |
|   |                  |        DRBD Sync (TCP 7789)       |                  |
|   |   VIP: 10.0.1.20 |<=================================>|                  |
|   |                  |           continuous              |                  |
|   +--------+---------+                                   +------------------+
|            |                                                      |         |
|            | Clients connect                                      | No traffic
|            v                                                      |         |
|       [ USERS ]                                                   |         |
|                                                                   |         |
|   ====================================================================      |
|                                                                             |
|   NODE 1 FAILURE DETECTED                                                   |
|   =======================                                                   |
|                                                                             |
|   T+0s:   Heartbeat missed                                                  |
|                                                                             |
|   +------------------+         X  No heartbeat  X        +------------------+
|   |                  |         X                X        |                  |
|   |   NODE 1         |                                   |   NODE 2         |
|   |   XX FAILED XX   |                                   |   DETECTING...   |
|   |                  |                                   |                  |
|   |   VIP: (lost)    |                                   |                  |
|   +------------------+                                   +------------------+
|                                                                             |
|   T+3s:   Failure confirmed (3 missed heartbeats)                           |
|   T+5s:   STONITH executed (if configured)                                  |
|   T+10s:  DRBD promoted to Primary on Node 2                                |
|   T+15s:  Services starting on Node 2                                       |
|   T+25s:  VIP migrated to Node 2                                            |
|   T+30s:  Node 2 fully active                                               |
|                                                                             |
|   ====================================================================      |
|                                                                             |
|   FAILOVER COMPLETE                                                         |
|   =================                                                         |
|                                                                             |
|   +------------------+                                   +------------------+
|   |                  |                                   |                  |
|   |   NODE 1         |                                   |   NODE 2         |
|   |   XX OFFLINE XX  |                                   |   ** ACTIVE **   |
|   |                  |                                   |                  |
|   |                  |                                   |   VIP: 10.0.1.20 |
|   +------------------+                                   +--------+---------+
|                                                                   |         |
|                                                                   | Clients |
|                                                                   v         |
|                                                              [ USERS ]      |
|                                                                             |
|   TOTAL FAILOVER TIME: ~30 seconds (Active-Passive)                         |
|                        ~10 seconds (Active-Active with session affinity)    |
+===========================================================================+
```

---

## Service Architecture

### Service Dependency Tree

```
+===========================================================================+
|                        SERVICE DEPENDENCY TREE                            |
+===========================================================================+
|                                                                           |
|   STARTUP ORDER (Bottom to Top)                                           |
|   =============================                                           |
|                                                                           |
|                                                                           |
|   LEVEL 5      +-------------+  +-------------+  +-------------+          |
|   (User        | SSH Proxy   |  | RDP Proxy   |  | VNC Proxy   |          |
|    Access)     | :22         |  | :3389       |  | :5900       |          |
|                +------+------+  +------+------+  +------+------+          |
|                       |                |                |                 |
|                       +----------------+----------------+                 |
|                                        |                                  |
|                                        | depends on                       |
|                                        v                                  |
|   LEVEL 4      +-------------+  +-------------+  +-------------+          |
|   (App)        | Web UI      |  | REST API    |  | Audit Svc   |          |
|                | :443        |  | :443/api    |  |             |          |
|                +------+------+  +------+------+  +------+------+          |
|                       |                |                |                 |
|                       +----------------+----------------+                 |
|                                        |                                  |
|                                        | depends on                       |
|                                        v                                  |
|   LEVEL 3      +------------------------------------------------+         |
|   (Core)       |              WALLIX BASTION                    |         |
|                |            (Core Application)                  |         |
|                +------------------------+-----------------------+         |
|                                         |                                 |
|                                         | depends on                      |
|                                         v                                 |
|   LEVEL 2      +-------------+    +-------------+                         |
|   (Infra)      |   NGINX     |    | PostgreSQL  |                         |
|                |   :443/:80  |    |   :5432     |                         |
|                +------+------+    +------+------+                         |
|                       |                  |                                |
|                       |                  | depends on (HA only)           |
|                       |                  v                                |
|   LEVEL 1             |           +-------------+  +-------------+        |
|   (HA/Cluster)        |           |    DRBD     |  |  Pacemaker  |        |
|                       |           |   :7789     |  |  /Corosync  |        |
|                       |           +------+------+  +------+------+        |
|                       |                  |                |               |
|                       +------------------+----------------+               |
|                                          |                                |
|                                          | depends on                     |
|                                          v                                |
|   LEVEL 0             +------------------------------------------+        |
|   (OS)                |          OPERATING SYSTEM                |        |
|                       |         (Debian 12 + LUKS)               |        |
|                       |                                          |        |
|                       |  * systemd                               |        |
|                       |  * networking                            |        |
|                       |  * dm-crypt (LUKS)                       |        |
|                       +------------------------------------------+        |
+===========================================================================+
```

---

## Port Reference Matrix

### Complete Port Listing

```
+===========================================================================+
|                         COMPLETE PORT REFERENCE                           |
+===========================================================================+

+=================================== USER ACCESS PORTS =====================+
|                                                                           |
|   Port    Protocol   Service          Direction    Description            |
|   ----    --------   -------          ---------    -----------            |
|   22      TCP        SSH Proxy        Inbound      SSH session access     |
|   23      TCP        Telnet Proxy     Inbound      Telnet session (legacy)|
|   80      TCP        HTTP             Inbound      Redirect to HTTPS      |
|   443     TCP        HTTPS            Inbound      Web UI, REST API, sync |
|   3389    TCP        RDP Proxy        Inbound      RDP session access     |
|   5900    TCP        VNC Proxy        Inbound      VNC session access     |
|                                                                           |
+===========================================================================+

+=================================== TARGET ACCESS PORTS ===================+
|                                                                           |
|   Port    Protocol   Service          Direction    Description            |
|   ----    --------   -------          ---------    -----------            |
|   22      TCP        SSH              Outbound     WALLIX -> SSH servers  |
|   23      TCP        Telnet           Outbound     WALLIX -> Telnet       |
|   3389    TCP        RDP              Outbound     WALLIX -> Windows/RDP  |
|   5900    TCP        VNC              Outbound     WALLIX -> VNC servers  |
|   5985    TCP        WinRM HTTP       Outbound     WALLIX -> WinRM        |
|   5986    TCP        WinRM HTTPS      Outbound     WALLIX -> WinRM (SSL)  |
|                                                                           |
+===========================================================================+

+=================================== OT PROTOCOL PORTS =====================+
|                                                                           |
|   Port    Protocol   Service          Direction    Description            |
|   ----    --------   -------          ---------    -----------            |
|   102     TCP        S7comm           Outbound     Siemens S7 PLC         |
|   502     TCP        Modbus TCP       Outbound     Modbus industrial      |
|   4840    TCP        OPC UA           Outbound     OPC Unified Arch       |
|   20000   TCP        DNP3             Outbound     DNP3 (SCADA)           |
|   44818   TCP/UDP    EtherNet/IP      Outbound     Allen-Bradley/Rockwell |
|   2222    TCP        EtherNet/IP      Outbound     EtherNet/IP explicit   |
|   102     TCP        IEC 61850 MMS    Outbound     Power systems          |
|                                                                           |
|   Note: OT ports accessed via Universal Tunneling through WALLIX          |
|                                                                           |
+===========================================================================+

+=================================== HA CLUSTER PORTS (Internal) ===========+
|                                                                           |
|   Port    Protocol   Service          Direction    Description            |
|   ----    --------   -------          ---------    -----------            |
|   2224    TCP        PCSD             Bidirect     Pacemaker web UI/API   |
|   3121    TCP        Pacemaker        Bidirect     Pacemaker remote       |
|   5403    TCP        Corosync QNet    Bidirect     Quorum device          |
|   5404    UDP        Corosync         Bidirect     Cluster multicast      |
|   5405    UDP        Corosync         Bidirect     Cluster unicast        |
|   5406    UDP        Corosync         Bidirect     Cluster communication  |
|   7789    TCP        DRBD             Bidirect     Block replication      |
|   5432    TCP        PostgreSQL       Bidirect     DB replication         |
|                                                                           |
+===========================================================================+

+=================================== AUTHENTICATION PORTS ==================+
|                                                                           |
|   Port    Protocol   Service          Direction    Description            |
|   ----    --------   -------          ---------    -----------            |
|   389     TCP        LDAP             Outbound     WALLIX -> LDAP/AD      |
|   636     TCP        LDAPS            Outbound     WALLIX -> LDAP (SSL)   |
|   88      TCP/UDP    Kerberos         Outbound     WALLIX -> Kerberos KDC |
|   464     TCP/UDP    Kerberos         Outbound     WALLIX -> Kerberos pwd |
|   1812    UDP        RADIUS Auth      Outbound     WALLIX -> RADIUS       |
|   1813    UDP        RADIUS Acct      Outbound     WALLIX -> RADIUS acct  |
|   443     TCP        OIDC/SAML        Outbound     WALLIX -> IdP          |
|                                                                           |
+===========================================================================+

+=================================== MANAGEMENT PORTS ======================+
|                                                                           |
|   Port    Protocol   Service          Direction    Description            |
|   ----    --------   -------          ---------    -----------            |
|   22      TCP        SSH (Admin)      Inbound      Admin SSH to WALLIX OS |
|   123     UDP        NTP              Outbound     Time synchronization   |
|   514     UDP        Syslog           Outbound     Log forwarding         |
|   6514    TCP        Syslog TLS       Outbound     Secure log forwarding  |
|   25      TCP        SMTP             Outbound     Email notifications    |
|   587     TCP        SMTP Submission  Outbound     Email (TLS)            |
|   161     UDP        SNMP             Inbound      SNMP monitoring        |
|   162     UDP        SNMP Trap        Outbound     SNMP traps to NMS      |
|                                                                           |
+===========================================================================+
```

### Port Summary by Function

```
+===========================================================================+
|                        PORT SUMMARY BY FUNCTION                           |
+===========================================================================+
|                                                                           |
|   ESSENTIAL PORTS (Must be open)                                          |
|   ==============================                                          |
|                                                                           |
|   +-----------------+-----------------+-----------------+-----------------+
|   | USER ACCESS     | ADMIN ACCESS    | AUTHENTICATION  | CLUSTER (HA)   |
|   +-----------------+-----------------+-----------------+-----------------+
|   | 443/tcp (HTTPS) | 22/tcp (SSH)    | 389/tcp (LDAP)  | 5404-5406/udp  |
|   | 22/tcp (SSH)    |                 | 636/tcp (LDAPS) | 7789/tcp (DRBD)|
|   | 3389/tcp (RDP)  |                 | 88/tcp (Kerb)   | 5432/tcp (PG)  |
|   +-----------------+-----------------+-----------------+-----------------+
|                                                                           |
|   OPTIONAL PORTS (Based on features used)                                 |
|   =======================================                                 |
|                                                                           |
|   +-----------------+-----------------+-----------------+-----------------+
|   | OT PROTOCOLS    | LEGACY ACCESS   | MONITORING      | NOTIFICATIONS  |
|   +-----------------+-----------------+-----------------+-----------------+
|   | 502/tcp (Modbus)| 23/tcp (Telnet) | 161/udp (SNMP)  | 25/tcp (SMTP)  |
|   | 4840/tcp (OPCUA)| 5900/tcp (VNC)  | 514/udp (Syslog)| 587/tcp (SMTP) |
|   | 102/tcp (S7comm)|                 | 6514/tcp (TLS)  |                |
|   | 20000/tcp (DNP3)|                 |                 |                |
|   +-----------------+-----------------+-----------------+-----------------+
+===========================================================================+
```

---

## Firewall Rules

### Site A Firewall Configuration

```
+===========================================================================+
|                 SITE A - FIREWALL RULES (iptables/nftables)               |
+===========================================================================+

# INBOUND RULES - From Users/Internet
# ====================================

# User Access (from corporate network)
-A INPUT -s 10.0.0.0/8 -p tcp --dport 443 -j ACCEPT      # HTTPS/API
-A INPUT -s 10.0.0.0/8 -p tcp --dport 22 -j ACCEPT       # SSH Proxy
-A INPUT -s 10.0.0.0/8 -p tcp --dport 3389 -j ACCEPT     # RDP Proxy
-A INPUT -s 10.0.0.0/8 -p tcp --dport 80 -j ACCEPT       # HTTP Redirect

# Admin Access (from admin network only)
-A INPUT -s 10.0.100.0/24 -p tcp --dport 22 -j ACCEPT    # SSH Admin

# Cluster Communication (from peer node only)
-A INPUT -s 192.168.100.11 -p udp --dport 5404:5406 -j ACCEPT  # Corosync
-A INPUT -s 192.168.100.11 -p tcp --dport 7789 -j ACCEPT       # DRBD
-A INPUT -s 192.168.100.11 -p tcp --dport 5432 -j ACCEPT       # PostgreSQL
-A INPUT -s 192.168.100.11 -p tcp --dport 2224 -j ACCEPT       # PCSD

# Multi-site Sync (from Site B and Site C)
-A INPUT -s 10.0.2.20 -p tcp --dport 443 -j ACCEPT       # Site B VIP
-A INPUT -s 10.0.3.10 -p tcp --dport 443 -j ACCEPT       # Site C


# OUTBOUND RULES - To Targets/Services
# =====================================

# Target Access (to OT network)
-A OUTPUT -d 10.0.10.0/24 -p tcp --dport 22 -j ACCEPT    # SSH to targets
-A OUTPUT -d 10.0.10.0/24 -p tcp --dport 3389 -j ACCEPT  # RDP to targets
-A OUTPUT -d 10.0.10.0/24 -p tcp --dport 502 -j ACCEPT   # Modbus
-A OUTPUT -d 10.0.10.0/24 -p tcp --dport 102 -j ACCEPT   # S7comm
-A OUTPUT -d 10.0.10.0/24 -p tcp --dport 4840 -j ACCEPT  # OPC UA

# Authentication (to AD/LDAP servers)
-A OUTPUT -d 10.0.1.2 -p tcp --dport 389 -j ACCEPT       # LDAP
-A OUTPUT -d 10.0.1.2 -p tcp --dport 636 -j ACCEPT       # LDAPS
-A OUTPUT -d 10.0.1.2 -p tcp --dport 88 -j ACCEPT        # Kerberos

# Monitoring & Logging
-A OUTPUT -d 10.0.1.5 -p udp --dport 514 -j ACCEPT       # Syslog
-A OUTPUT -d 10.0.1.6 -p tcp --dport 25 -j ACCEPT        # SMTP

# NTP
-A OUTPUT -p udp --dport 123 -j ACCEPT                   # NTP

+===========================================================================+
```

### Firewall Zone Diagram

```
+===========================================================================+
|                          FIREWALL ZONE MODEL                              |
+===========================================================================+
|                                                                           |
|   INTERNET / UNTRUSTED                                                    |
|   ====================                                                    |
|           |                                                               |
|           | BLOCKED (no direct access)                                    |
|           v                                                               |
|   ========================================================================|
|                            PERIMETER FIREWALL                             |
|   ========================================================================|
|           |                                                               |
|           | 443 (VPN/HTTPS only)                                          |
|           v                                                               |
|   +-----------------------------------------------------------------------+
|   |                    CORPORATE ZONE (Users)                             |
|   |                        10.0.0.0/8                                     |
|   |                                                                       |
|   |   Allowed TO WALLIX:  443, 22 (proxy), 3389, 5900                    |
|   +-----------------------------------------------------------------------+
|           |                                                               |
|           | 443, 22, 3389, 5900                                           |
|           v                                                               |
|   ========================================================================|
|                            IT/OT DMZ FIREWALL                             |
|   ========================================================================|
|           |                                                               |
|           v                                                               |
|   +-----------------------------------------------------------------------+
|   |                    DMZ ZONE (WALLIX Bastion)                          |
|   |                        10.0.1.0/24                                    |
|   |                                                                       |
|   |   +---------------------------------------------------------------+   |
|   |   |                    WALLIX BASTION                             |   |
|   |   |                                                               |   |
|   |   |   INBOUND:  443, 22, 3389, 5900 (from Corporate)             |   |
|   |   |   OUTBOUND: 22, 3389, 502, 102, 4840 (to OT)                 |   |
|   |   |            389, 636, 88 (to AD/LDAP)                         |   |
|   |   +---------------------------------------------------------------+   |
|   +-----------------------------------------------------------------------+
|           |                                                               |
|           | 22, 3389, 502, 102, 4840 (session traffic only)               |
|           v                                                               |
|   ========================================================================|
|                              OT FIREWALL                                  |
|   ========================================================================|
|           |                                                               |
|           v                                                               |
|   +-----------------------------------------------------------------------+
|   |                    OT ZONE (Protected Devices)                        |
|   |                        10.0.10.0/24                                   |
|   |                                                                       |
|   |   +-------+  +-------+  +-------+  +-------+  +-------+              |
|   |   |  PLC  |  |  HMI  |  | SCADA |  |  RTU  |  |  DCS  |              |
|   |   | :102  |  | :3389 |  |  :22  |  | :502  |  | :4840 |              |
|   |   +-------+  +-------+  +-------+  +-------+  +-------+              |
|   |                                                                       |
|   |   NO DIRECT ACCESS FROM CORPORATE - All traffic through WALLIX       |
|   +-----------------------------------------------------------------------+
|                                                                           |
+===========================================================================+
```

---

## Quick Reference Tables

### IP Address Summary

```
+===========================================================================+
|                       IP ADDRESS QUICK REFERENCE                          |
+===========================================================================+
|                                                                           |
|   SITE A - PRIMARY                                                        |
|   ----------------                                                        |
|   wallix-a1 (Management):     10.0.1.10                                   |
|   wallix-a1 (Cluster):        192.168.100.10                              |
|   wallix-a2 (Management):     10.0.1.11                                   |
|   wallix-a2 (Cluster):        192.168.100.11                              |
|   VIP (User Access):          10.0.1.20                                   |
|                                                                           |
|   SITE B - SECONDARY                                                      |
|   ------------------                                                      |
|   wallix-b1 (Management):     10.0.2.10                                   |
|   wallix-b1 (Cluster):        192.168.200.10                              |
|   wallix-b2 (Management):     10.0.2.11                                   |
|   wallix-b2 (Cluster):        192.168.200.11                              |
|   VIP (User Access):          10.0.2.20                                   |
|                                                                           |
|   SITE C - REMOTE                                                         |
|   ---------------                                                         |
|   wallix-c1 (Management):     10.0.3.10                                   |
|                                                                           |
|   INFRASTRUCTURE                                                          |
|   --------------                                                          |
|   AD/LDAP Server:             10.0.1.2                                    |
|   DNS Server:                 10.0.1.3                                    |
|   NTP Server:                 10.0.1.4                                    |
|   Syslog Server:              10.0.1.5                                    |
|   SMTP Server:                10.0.1.6                                    |
|                                                                           |
+===========================================================================+
```

### Service Status Commands

```bash
# Check all WALLIX services
systemctl status wallix-bastion wallix-* nginx postgresql

# Check cluster status (HA nodes)
crm status
pcs status

# Check DRBD status (HA nodes)
drbd-overview
cat /proc/drbd

# Check PostgreSQL replication
sudo -u postgres psql -c "SELECT * FROM pg_stat_replication;"

# Check listening ports
ss -tlnp | grep -E '(22|443|3389|5432|5900)'

# Check firewall rules
iptables -L -n -v
nft list ruleset
```

---

## Version Information

| Item | Value |
|------|-------|
| Document Version | 1.0 |
| WALLIX Version | 12.1.x |
| Last Updated | January 2026 |

---

<p align="center">
  <a href="./README.md">Back to Overview</a> |
  <a href="./HOWTO.md">Installation Guide</a>
</p>
