# 02 - High Availability Architecture Comparison

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Active-Active Configuration](#active-active-configuration)
3. [Active-Passive Configuration](#active-passive-configuration)
4. [Side-by-Side Comparison](#side-by-side-comparison)
5. [Decision Matrix](#decision-matrix)
6. [Recommendations](#recommendations)

---

## Executive Summary

Each WALLIX Bastion site contains **2 hardware appliances** that can be deployed in either **Active-Active** or **Active-Passive** high availability configurations. This document provides a detailed comparison to help you choose the optimal deployment model based on your site requirements.

### Quick Overview

| Aspect | Active-Active | Active-Passive |
|--------|---------------|----------------|
| **Capacity Utilization** | 100% (both nodes serve traffic) | 50% (standby idle) |
| **Failover Time** | < 1 second (transparent) | 30-60 seconds |
| **Complexity** | Medium (bastion-replication Master/Master) | Low (bastion-replication Master/Slave) |
| **Session Continuity** | Full (no interruption) | Partial (brief disruption) |
| **Best For** | High load (100+ sessions), maximum uptime | Lower load (<100 sessions), simplicity |

### Key Differences

```
+===============================================================================+
|  ARCHITECTURE COMPARISON AT A GLANCE                                          |
+===============================================================================+
|                                                                               |
|  ACTIVE-ACTIVE                          ACTIVE-PASSIVE                        |
|  ==============                         ================                      |
|                                                                               |
|  Load Balancer                          Virtual IP (Floating)                 |
|       |                                        |                              |
|    +--+--+                              +------+------+                       |
|    |     |                              |             |                       |
|    v     v                              v             v                       |
|  Node1 Node2                          Node1         Node2                     |
|  (50%) (50%)                          (100%)        (Idle)                    |
|  ACTIVE ACTIVE                        PRIMARY       STANDBY                   |
|                                                                               |
|  Both serving traffic                 Only primary serves traffic             |
|  Transparent failover                 Requires VIP migration                  |
|  Full capacity used                   50% capacity wasted                     |
|                                                                               |
+===============================================================================+
```

---

## Active-Active Configuration

### Architecture

```
+===============================================================================+
|  ACTIVE-ACTIVE CLUSTER ARCHITECTURE                                           |
+===============================================================================+
|                                                                               |
|                         +--------------------------+                          |
|                         |    HAProxy (HA Pair)     |                          |
|                         |  Load Balancer           |                          |
|                         |                          |                          |
|                         |  VIP: 10.x.x.10          |                          |
|                         |  Keepalived VRRP         |                          |
|                         +-----------+--------------+                          |
|                                     |                                         |
|                    +----------------+----------------+                        |
|                    |                                 |                        |
|                    v                                 v                        |
|  +--------------------------------+ +--------------------------------+        |
|  |  WALLIX BASTION NODE 1         | |  WALLIX BASTION NODE 2         |        |
|  |  (ACTIVE)                      | |  (ACTIVE)                      |        |
|  |                                | |                                |        |
|  |  IP: 10.x.x.11                 | |  IP: 10.x.x.12                 |        |
|  |  Load: 50% traffic             | |  Load: 50% traffic             |        |
|  |                                | |                                |        |
|  |  +---------------------------+ | |  +---------------------------+ |        |
|  |  | WALLIX Bastion            | | |  | WALLIX Bastion            | |        |
|  |  | Services (Running)        | | |  | Services (Running)        | |        |
|  |  |                           | | |  |                           | |        |
|  |  | - Session Manager         | | |  | - Session Manager         | |        |
|  |  | - Password Manager        | | |  | - Password Manager        | |        |
|  |  | - Web UI                  | | |  | - Web UI                  | |        |
|  |  +---------------------------+ | |  +---------------------------+ |        |
|  |                                | |                                |        |
|  |  +---------------------------+ | |  +---------------------------+ |        |
|  |  | MariaDB                   | | |  | MariaDB                   | |        |
|  |  | (PRIMARY)                 |<+-+->| (PRIMARY)                 | |        |
|  |  |                           | | |  |                           | |        |
|  |  | Multi-Master Replication  | | |  | Multi-Master Replication  | |        |
|  |  | bastion-replication       | | |  | bastion-replication       | |        |
|  |  +---------------------------+ | |  +---------------------------+ |        |
|  |                                | |                                |        |
|  +--------------------------------+ +--------------------------------+        |
|                    |                                 |                        |
|                    +----------------+----------------+                        |
|                                     |                                         |
|                         +-----------+--------------+                          |
|                         |  Shared Storage (NAS)    |                          |
|                         |  Session Recordings      |                          |
|                         |  /var/wab/recorded       |                          |
|                         +--------------------------+                          |
|                                                                               |
|  CLUSTER MANAGEMENT                                                           |
|  ==================                                                           |
|  - bastion-replication for database replication (Master/Master or Master/Slave)|
|  - SSH tunnel via autossh for secure replication channel                      |
|  - HAProxy/Keepalived for VIP management and load balancing                   |
|                                                                               |
+===============================================================================+
```

### How It Works

**Traffic Distribution:**
1. HAProxy load balancer receives all incoming connections
2. Distributes traffic using round-robin or least-connections algorithm
3. Both Bastion nodes actively serve requests simultaneously
4. Session persistence maintained via cookie (HTTPS) or source IP hash (SSH/RDP)

**Database Synchronization:**
1. `bastion-replication` in Master/Master mode provides multi-master replication
2. Both nodes can read and write to database
3. Synchronous replication ensures data consistency
4. Built-in conflict resolution managed by bastion-replication

**Failover Process:**
1. HAProxy health checks detect node failure (every 2-5 seconds)
2. Failed node removed from backend pool immediately
3. All new traffic directed to healthy node
4. Existing sessions continue uninterrupted (if session persistence used)
5. No manual intervention required

### Pros

**1. Full Capacity Utilization**
- Both nodes actively serve traffic
- No wasted hardware resources
- 100% compute capacity available
- Better ROI on hardware investment

**2. Transparent Failover**
- Sub-second failover time
- No service interruption
- Active sessions continue seamlessly
- Users unaware of node failures

**3. Load Distribution**
- Automatic traffic balancing
- Better performance under high load
- Horizontal scaling capability
- Can add more nodes if needed

**4. Maximum Availability**
- True 99.99% uptime achievable
- No single point of failure (with HA load balancer)
- Rolling updates possible without downtime
- Maintenance without service interruption

### Cons

**1. Configuration Considerations**
- MariaDB multi-master replication via `bastion-replication`
- Both nodes must be configured with `bastion-replication --create-conf-file` (Master/Master)
- HAProxy/Keepalived for load balancing and VIP management
- More components involved than Master/Slave mode

**2. Database Complexity**
- Multi-master conflicts possible
- Requires careful schema design
- Conflict resolution overhead
- Potential for data inconsistency if misconfigured

**3. Replication Monitoring**
- Replication health must be monitored via `bastion-replication --monitoring`
- Network issues between nodes can cause replication lag
- Notifications can be configured with `bastion-replication --install-notification`

**4. Troubleshooting Complexity**
- Harder to diagnose issues
- Replication lag monitoring required (`bastion-replication --monitoring`)
- Replication state management across both masters
- Need expertise in bastion-replication administration

**5. Resource Overhead**
- Replication overhead (network, CPU, disk I/O)
- Health check traffic (HAProxy + bastion-replication monitoring)
- Synchronization overhead between Master/Master nodes

### Use Cases

**Recommended for:**

1. **High Session Volume**
   - Sites with 100+ concurrent sessions
   - Peak loads exceeding single-node capacity
   - Need for horizontal scaling

2. **Maximum Availability Requirements**
   - Critical production environments
   - 99.99% uptime SLA requirements
   - Zero-tolerance for service interruptions
   - 24/7 operations

3. **Geographically Distributed Users**
   - Multiple user locations
   - Unpredictable load patterns
   - Need for load distribution

4. **Maintenance Windows Not Feasible**
   - Cannot afford downtime for patching
   - Need rolling updates
   - Continuous operations required

### Technical Requirements

**Infrastructure:**
- HAProxy 2.8+ in HA configuration (2 instances + Keepalived)
- WALLIX Bastion 12.1.x with built-in `bastion-replication` (Master/Master mode)
- Shared NFS/iSCSI storage for recordings
- Low-latency network between nodes (< 5ms RTT)

**Software Components:**
```bash
# Database HA (built into WALLIX Bastion)
bastion-replication     # Built-in replication tool (Master/Master mode)
                        # Manages MariaDB replication + SSH tunnel (autossh)

# Load Balancing
haproxy 2.8+            # Load balancer
keepalived              # VRRP for HAProxy HA
```

**Network Configuration:**
```
+===============================================================================+
|  NETWORK CONFIGURATION                                                        |
+===============================================================================+
|                                                                               |
|  Interface Bonding (Recommended):                                             |
|  - bond0: Primary traffic (active-backup or LACP)                             |
|  - bond1: Replication traffic (dedicated VLAN, recommended)                   |
|                                                                               |
|  IP Addressing:                                                               |
|  - Node 1: 10.x.x.11/24 (bond0)                                               |
|  - Node 2: 10.x.x.12/24 (bond0)                                               |
|  - VIP: 10.x.x.10/24 (HAProxy virtual IP)                                     |
|                                                                               |
|  Replication Network:                                                         |
|  - SSH tunnel port 2242 (autossh, managed by bastion-replication)             |
|  - MariaDB replication port 3306/3307                                         |
|  - Dedicated VLAN recommended for replication traffic                         |
|                                                                               |
+===============================================================================+
```

---

## Active-Passive Configuration

### Architecture

```
+===============================================================================+
|  ACTIVE-PASSIVE CLUSTER ARCHITECTURE                                          |
+===============================================================================+
|                                                                               |
|                         +--------------------------+                          |
|                         |  Virtual IP (Floating)   |                          |
|                         |  Keepalived VRRP         |                          |
|                         |                          |                          |
|                         |  VIP: 10.x.x.10          |                          |
|                         +-----------+--------------+                          |
|                                     |                                         |
|                    +----------------+                                         |
|                    |                                                          |
|                    v                                                          |
|  +--------------------------------+                                           |
|  |  WALLIX BASTION NODE 1         |                                           |
|  |  (PRIMARY - ACTIVE)            |                                           |
|  |                                |                                           |
|  |  IP: 10.x.x.11                 |          +-------------------------------+|
|  |  VIP: 10.x.x.10 (current)      |          |  WALLIX BASTION NODE 2        ||
|  |  Load: 100% traffic            |          |  (STANDBY - PASSIVE)          ||
|  |                                |          |                               ||
|  |  +---------------------------+ |          |  IP: 10.x.x.12                ||
|  |  | WALLIX Bastion            | |          |  VIP: - (not assigned)        ||
|  |  | Services (Running)        | |          |  Load: 0% (idle)              ||
|  |  |                           | |          |                               ||
|  |  | - Session Manager         | |          |  +--------------------------+ ||
|  |  | - Password Manager        | |          |  | WALLIX Bastion           | ||
|  |  | - Web UI                  | |          |  | Services (Stopped)       | ||
|  |  +---------------------------+ |          |  |                          | ||
|  |                                |          |  | - Session Manager        | ||
|  |  +---------------------------+ |          |  | - Password Manager       | ||
|  |  | MariaDB                   | |          |  | - Web UI                 | ||
|  |  | (PRIMARY)                 | |          |  +--------------------------+ ||
|  |  |                           | |          |                               ||
|  |  | Async Replication --------+-+--------->|  +---------------------------+||
|  |  |                           | |          |  | MariaDB                   |||
|  |  +---------------------------+ |          |  | (REPLICA - Read-only)     |||
|  |                                |          |  |                           |||
|  +--------------------------------+          |  +---------------------------+||
|                    |                         |                               ||
|                    |                         +-------------------------------+|
|                    |                                         |                |
|                    +----------------+------------------------+                |
|                                     |                                         |
|                         +-----------+--------------+                          |
|                         |  Shared Storage (NAS)    |                          |
|                         |  Session Recordings      |                          |
|                         |  /var/wab/recorded       |                          |
|                         +--------------------------+                          |
|                                                                               |
|  HEARTBEAT MONITORING                                                         |
|  ====================                                                         |
|  Node 1 <----- Heartbeat (every 2s) -----> Node 2                             |
|                                                                               |
|  If Node 1 fails:                                                             |
|    1. Node 2 detects missing heartbeat (3 consecutive = 6 seconds)            |
|    2. Node 2 promotes MariaDB replica to primary                              |
|    3. Node 2 starts WALLIX services                                           |
|    4. Node 2 assumes VIP 10.x.x.10                                            |
|    5. Node 2 sends gratuitous ARP                                             |
|                                                                               |
|  FAILOVER TIME: 30-60 seconds                                                 |
|                                                                               |
+===============================================================================+
```

### How It Works

**Normal Operation:**
1. Primary node (Node 1) owns the Virtual IP (VIP)
2. All traffic directed to VIP reaches primary node
3. WALLIX services run only on primary node
4. MariaDB on standby continuously replicates from primary
5. Heartbeat packets exchanged every 2 seconds

**Failover Process:**
1. **Detection (6 seconds):** Standby detects 3 consecutive missed heartbeats
2. **Validation (5 seconds):** Confirms primary is truly down (not network glitch)
3. **Database Promotion (10 seconds):** Run `bastion-replication --elevate-master` on standby
4. **Service Start (15 seconds):** Start WALLIX Bastion services on standby
5. **VIP Migration (5 seconds):** Keepalived assigns VIP to standby, send gratuitous ARP
6. **Service Ready (10 seconds):** Accept new connections

**Total Failover Time: 30-60 seconds**

**Failback (Manual):**
1. Repair original master node
2. Configure as new slave using `bastion-replication --add-slave`
3. Resync data if needed with `bastion-replication --dump-resync`
4. Wait for replication to catch up (`bastion-replication --monitoring`)
5. Optional: Fail back to original master (requires `bastion-replication --elevate-master`)

### Pros

**1. Simple Configuration**
- Single primary database (no multi-master complexity)
- `bastion-replication` Master/Slave mode handles all replication setup
- Straightforward configuration via `bastion-replication --create-conf-file`
- Easier to understand and maintain

**2. Fast Failover (Relative to Manual)**
- Automatic failover in 30-60 seconds
- No manual intervention required
- Tested and proven mechanism
- Predictable behavior

**3. Easier Troubleshooting**
- Clear primary/standby roles
- Simpler log analysis
- Single active node to debug
- Well-documented failure modes

**4. Lower Resource Overhead**
- No multi-master replication overhead
- Single node serving traffic (lower network utilization)
- Simpler bastion-replication management (Master/Slave)
- Fewer background processes

**5. Better Data Consistency**
- Single source of truth (primary database)
- No replication conflicts
- Simpler backup strategy
- Clear recovery point

### Cons

**1. 50% Capacity Waste**
- Standby node idle under normal conditions
- Hardware investment not fully utilized
- No performance benefit from second node
- Cannot handle more than single-node capacity

**2. Failover Interruption**
- 30-60 second outage during failover
- Active sessions disconnected
- Users must reconnect
- Brief service unavailability

**3. No Load Distribution**
- Single node handles all traffic
- No horizontal scaling
- Performance limited to one node
- Higher load on primary

**4. Maintenance Downtime**
- Patching primary requires failover
- Cannot perform rolling updates
- Maintenance windows needed
- Potential for service interruption

**5. Standby Drift Risk**
- Standby may lag behind primary (replication delay)
- Potential data loss if primary fails before replication completes
- Standby untested until failover occurs
- Configuration drift possible

### Use Cases

**Recommended for:**

1. **Lower Session Volume**
   - Sites with < 100 concurrent sessions
   - Single-node capacity sufficient
   - Predictable load patterns

2. **Simplicity Preferred**
   - Limited HA expertise in team
   - Easier operations priority
   - Faster initial deployment needed
   - Fewer resources for management

3. **Budget Constraints**
   - Lower operational complexity = lower cost
   - Acceptable to waste standby capacity
   - No immediate scaling needs

4. **Acceptable Downtime Window**
   - Can tolerate 30-60 second failover
   - Users can reconnect manually
   - Not mission-critical 24/7 operations

### Technical Requirements

**Infrastructure:**
- 2x WALLIX Bastion HW appliances (WALLIX Bastion 12.1.x)
- Shared NFS/iSCSI storage for recordings
- Dedicated replication network (recommended)

**Software Components:**
```bash
# Database HA (built into WALLIX Bastion)
bastion-replication     # Built-in replication tool (Master/Slave mode)
                        # Manages MariaDB replication + SSH tunnel (autossh)

# Virtual IP
keepalived              # VRRP for VIP management
```

**Network Configuration:**
```
+===============================================================================+
|  NETWORK CONFIGURATION                                                        |
+===============================================================================+
|                                                                               |
|  Interface Bonding (Recommended):                                             |
|  - bond0: Primary traffic (active-backup or LACP)                             |
|  - bond1: Replication traffic (dedicated VLAN, optional but recommended)      |
|                                                                               |
|  IP Addressing:                                                               |
|  - Node 1: 10.x.x.11/24 (bond0) - Primary (Master)                            |
|  - Node 2: 10.x.x.12/24 (bond0) - Standby (Slave)                             |
|  - VIP: 10.x.x.10/24 (Floating IP managed by Keepalived)                      |
|                                                                               |
|  Replication Network (Optional but Recommended):                              |
|  - SSH tunnel port 2242 (autossh, managed by bastion-replication)             |
|  - MariaDB replication port 3306/3307                                         |
|  - Dedicated VLAN for replication traffic                                     |
|  - Reduces impact on production network                                       |
|                                                                               |
+===============================================================================+
```

---

## Side-by-Side Comparison

### Capacity & Performance

```
+===============================================================================+
|  CAPACITY & PERFORMANCE COMPARISON                                            |
+===============================================================================+
|                                                                               |
|  +----------------------+---------------------+-----------------------------+ |
|  | Metric               | Active-Active       | Active-Passive              | |
|  +----------------------+---------------------+-----------------------------+ |
|  | Node Utilization     | 100% (both active)  | 50% (standby idle)          | |
|  | Max Sessions         | 2x single-node      | 1x single-node              | |
|  | Load Distribution    | Yes (50/50 split)   | No (100% on primary)        | |
|  | Horizontal Scaling   | Yes (add more nodes)| No (2 nodes max)            | |
|  | Performance Impact   | +100% capacity      | No improvement              | |
|  | Idle Resources       | 0%                  | 50% (entire standby node)   | |
|  +----------------------+---------------------+-----------------------------+ |
|                                                                               |
|  EXAMPLE: 200 Concurrent Sessions                                             |
|  ================================                                             |
|                                                                               |
|  Active-Active:                                                               |
|  - Node 1: 100 sessions (50% load)                                            |
|  - Node 2: 100 sessions (50% load)                                            |
|  - Result: Both nodes at moderate load, room for spikes                       |
|                                                                               |
|  Active-Passive:                                                              |
|  - Node 1: 200 sessions (100% load)                                           |
|  - Node 2: 0 sessions (0% load)                                               |
|  - Result: Primary at capacity, standby wasted                                |
|                                                                               |
+===============================================================================+
```

### Reliability & Availability

```
+===============================================================================+
|  RELIABILITY & AVAILABILITY COMPARISON                                        |
+===============================================================================+
|                                                                               |
|  +----------------------+---------------------+-----------------------------+ |
|  | Metric               | Active-Active       | Active-Passive              | |
|  +----------------------+---------------------+-----------------------------+ |
|  | Failover Time        | < 1 second          | 30-60 seconds               | |
|  | Session Continuity   | Yes (seamless)      | No (reconnect required)     | |
|  | Availability Target  | 99.99% (52 min/yr)  | 99.9% (8.7 hrs/yr)          | |
|  | Single Node Failure  | Transparent         | Brief outage                | |
|  | Planned Maintenance  | Zero downtime       | Requires failover (30-60s)  | |
|  | Rolling Updates      | Yes                 | No                          | |
|  | Data Loss Risk       | Near-zero (sync rep)| Minimal (async rep lag)     | |
|  +----------------------+---------------------+-----------------------------+ |
|                                                                               |
|  FAILOVER COMPARISON                                                          |
|  ===================                                                          |
|                                                                               |
|  Active-Active:                                                               |
|    0s --------> Node 1 fails                                                  |
|    0.5s ------> HAProxy removes from pool                                     |
|    1s --------> All traffic to Node 2                                         |
|    User Impact: None (transparent)                                            |
|                                                                               |
|  Active-Passive:                                                              |
|    0s --------> Node 1 fails                                                  |
|    6s --------> Heartbeat timeout detected                                    |
|    15s -------> Database promoted                                             |
|    30s -------> Services started                                              |
|    45s -------> VIP migrated                                                  |
|    60s -------> Ready for connections                                         |
|    User Impact: 30-60s outage, must reconnect                                 |
|                                                                               |
+===============================================================================+
```

### Complexity & Operations

```
+===============================================================================+
|  COMPLEXITY & OPERATIONS COMPARISON                                           |
+===============================================================================+
|                                                                               |
|  +----------------------+---------------------+-----------------------------+ |
|  | Metric               | Active-Active       | Active-Passive              | |
|  +----------------------+---------------------+-----------------------------+ |
|  | Setup Complexity     | High                | Medium                      | |
|  | Configuration        | Complex             | Simple                      | |
|  | Troubleshooting      | Difficult           | Easy                        | |
|  | Expertise Required   | bastion-replication  | Basic bastion-replication    | |
|  | Management Overhead  | High                | Low                         | |
|  | Monitoring Points    | Many                | Few                         | |
|  | Failure Modes        | Complex             | Well-understood             | |
|  | Database Conflicts   | Possible            | Not applicable              | |
|  | Split-Brain Risk     | N/A (no quorum)     | N/A                         | |
|  +----------------------+---------------------+-----------------------------+ |
|                                                                               |
|  OPERATIONAL TASKS                                                            |
|  =================                                                            |
|                                                                               |
|  +----------------------------------+---------------------------------------+ |
|  | Task                             | Active-Active | Active-Passive        | |
|  +----------------------------------+---------------+-----------------------+ |
|  | Add Cluster Node                 | 2-4 hours     | N/A (2 nodes max)     | |
|  | Patch Operating System           | 30 min (roll) | 60 min (failover 2x)  | |
|  | Database Maintenance             | Complex       | Simple (stop rep)     | |
|  | Restore from Backup              | Complex       | Simple                | |
|  | Troubleshoot Replication         | Difficult     | Easy                  | |
|  | Monitor Cluster Health           | Many metrics  | Few metrics           | |
|  | Resync After Failure             | --dump-resync | --dump-resync         | |
|  +----------------------------------+---------------+-----------------------+ |
|                                                                               |
+===============================================================================+
```

### Cost Analysis

```
+===============================================================================+
|  COST ANALYSIS                                                                |
+===============================================================================+
|                                                                               |
|  HARDWARE COSTS (Same for both)                                               |
|  ==============================                                               |
|  - 2x WALLIX Bastion HW Appliances                                            |
|  - Shared NFS/iSCSI storage                                                   |
|  - Network infrastructure                                                     |
|                                                                               |
|  OPERATIONAL COSTS                                                            |
|  =================                                                            |
|                                                                               |
|  +----------------------+---------------------+-----------------------------+ |
|  | Cost Factor          | Active-Active       | Active-Passive              | |
|  +----------------------+---------------------+-----------------------------+ |
|  | Initial Setup Time   | 3-5 days            | 1-2 days                    | |
|  | Training Required    | Advanced (1 week)   | Basic (2 days)              | |
|  | Ongoing Management   | 10-15 hrs/month     | 5-8 hrs/month               | |
|  | Monitoring Tools     | Prometheus, Grafana | Basic (built-in)            | |
|  | Support Level Needed | Expert              | Standard                    | |
|  | Troubleshooting Time | 2-4x higher         | Baseline                    | |
|  +----------------------+---------------------+-----------------------------+ |
|                                                                               |
|  ROI CALCULATION (200 Sessions)                                               |
|  ==============================                                               |
|                                                                               |
|  Active-Active:                                                               |
|    Hardware Utilization: 100% (both nodes serving traffic)                    |
|    Effective Cost per Session: $X per node / 100 sessions = $X/100            |
|    Downtime Cost Savings: High (near-zero downtime)                           |
|                                                                               |
|  Active-Passive:                                                              |
|    Hardware Utilization: 50% (standby idle)                                   |
|    Effective Cost per Session: $X per node / 100 sessions = $X/100            |
|    BUT: $X wasted on idle standby                                             |
|    Downtime Cost: Minimal (30-60s failover acceptable)                        |
|                                                                               |
+===============================================================================+
```

### Database Replication

```
+===============================================================================+
|  DATABASE REPLICATION COMPARISON                                              |
+===============================================================================+
|                                                                               |
|  ACTIVE-ACTIVE: MASTER/MASTER (bastion-replication)                           |
|  ==================================================                          |
|                                                                               |
|  Architecture:                                                                |
|    Node 1 MariaDB (Master) <===> Node 2 MariaDB (Master)                     |
|    Bidirectional replication via bastion-replication + SSH tunnel (port 2242)  |
|                                                                               |
|  Setup:                                                                       |
|    bastion-replication --create-conf-file   # Select Master/Master mode       |
|    bastion-replication --install            # Install and start replication    |
|    bastion-replication --install-monitoring # Enable health monitoring         |
|                                                                               |
|  Characteristics:                                                             |
|  + Both nodes can write                                                       |
|  + Replication managed entirely by bastion-replication                        |
|  + No external cluster manager required (built-in bastion-replication)       |
|  + SSH tunnel provides secure replication channel                             |
|  + Monitoring via bastion-replication --monitoring                            |
|  - Conflict possible (same row updated simultaneously)                        |
|  - Higher latency (sync overhead)                                             |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  ACTIVE-PASSIVE: MASTER/SLAVE (bastion-replication)                           |
|  ==================================================                          |
|                                                                               |
|  Architecture:                                                                |
|    Node 1 MariaDB (Master) -----> Node 2 MariaDB (Slave)                     |
|    Unidirectional replication via bastion-replication + SSH tunnel (port 2242) |
|                                                                               |
|  Setup:                                                                       |
|    bastion-replication --create-conf-file   # Select Master/Slave mode        |
|    bastion-replication --install            # Install and start replication    |
|    bastion-replication --install-monitoring # Enable health monitoring         |
|                                                                               |
|  Failover:                                                                    |
|    bastion-replication --elevate-master     # Promote slave to master          |
|                                                                               |
|  Characteristics:                                                             |
|  + Simple configuration via bastion-replication                               |
|  + No write conflicts (only master writes)                                    |
|  + Lower latency (async replication)                                          |
|  + Slave can lag during high load                                             |
|  - Potential data loss (if master fails before replication)                   |
|  - Slave read-only (cannot serve writes)                                      |
|                                                                               |
|  Replication Lag Example:                                                     |
|    Master: 1000 transactions/sec                                              |
|    Slave: 950 transactions/sec (50 TPS lag)                                   |
|    Lag Time: Grows during peak, catches up during low load                    |
|    Max Acceptable Lag: < 5 seconds                                            |
|    Monitor: bastion-replication --monitoring                                  |
|                                                                               |
+===============================================================================+
```

---

## Decision Matrix

### Session Load-Based Decision

```
+===============================================================================+
|  DECISION MATRIX: SESSION LOAD                                                |
+===============================================================================+
|                                                                               |
|  Concurrent Sessions  |  Recommended Model    | Justification                 |
|  --------------------+----------------------+-----------------------------    |
|  < 50                 |  Active-Passive       | Single node sufficient,       |
|                       |                       | simplicity preferred          |
|  --------------------+----------------------+-----------------------------    |
|  50 - 100             |  Active-Passive       | Single node capacity OK,      |
|                       |  (Consider A-A)       | but evaluate growth           |
|  --------------------+----------------------+-----------------------------    |
|  100 - 200            |  Active-Active        | Load distribution needed,     |
|                       |                       | single node near capacity     |
|  --------------------+----------------------+-----------------------------    |
|  > 200                |  Active-Active        | Mandatory for performance,    |
|                       |                       | horizontal scaling needed     |
|  --------------------+----------------------+-----------------------------    |
|                                                                               |
|  Note: Session count refers to peak concurrent sessions, not total users.     |
|                                                                               |
+===============================================================================+
```

### Availability Requirements Decision

```
+===============================================================================+
|  DECISION MATRIX: AVAILABILITY REQUIREMENTS                                   |
+===============================================================================+
|                                                                               |
|  Uptime SLA    | Allowed Downtime | Failover Req  | Recommended Model         |
|  -------------+------------------+---------------+------------------------    |
|  99%           | 87 hrs/year      | Manual        | Standalone (no HA)        |
|  99.9%         | 8.7 hrs/year     | < 60 seconds  | Active-Passive            |
|  99.95%        | 4.4 hrs/year     | < 30 seconds  | Active-Passive +          |
|                |                  |               | good monitoring           |
|  99.99%        | 52 min/year      | < 1 second    | Active-Active             |
|  99.999%       | 5 min/year       | Near-instant  | Active-Active +           |
|                |                  |               | Multi-site                |
|  -------------+------------------+---------------+------------------------    |
|                                                                               |
|  Additional Considerations:                                                   |
|  - Planned maintenance windows: Active-Active for zero-downtime updates       |
|  - Unplanned outages acceptable: Active-Passive sufficient                    |
|  - 24/7 operations: Active-Active recommended                                 |
|  - Business hours only: Active-Passive acceptable                             |
|                                                                               |
+===============================================================================+
```

### Team Capability Decision

```
+===============================================================================+
|  DECISION MATRIX: TEAM CAPABILITY                                             |
+===============================================================================+
|                                                                               |
|  Team Skill Level     | Experience              | Recommended Model           |
|  --------------------+------------------------+---------------------------    |
|  Junior/Mid-Level     | - Basic Linux admin     | Active-Passive              |
|                       | - Limited HA experience |                             |
|                       | - Small team (1-2)      |                             |
|  --------------------+------------------------+---------------------------    |
|  Senior               | - Advanced Linux        | Active-Active or            | 
|                       | - Some HA clustering    | Active-Passive              |
|                       | - Medium team (2-4)     | (based on other factors)    |
|  --------------------+------------------------+---------------------------    |
|  Expert/SRE Team      | - Distributed systems   | Active-Active               |
|                       | - Multi-master DB       |                             | 
|                       | - Large team (4+)       |                             |
|  --------------------+------------------------+---------------------------    |
|                                                                               |
|  Key Skills Required for Active-Active:                                       |
|  - bastion-replication Master/Master configuration and monitoring             |
|  - HAProxy advanced configuration and load balancing                          |
|  - Keepalived VRRP management                                                |
|  - Network troubleshooting (SSH tunnels, replication ports)                   |
|  - MariaDB replication troubleshooting                                        |
|  - bastion-replication --dump-resync for recovery scenarios                   |
|                                                                               |
|  Key Skills Required for Active-Passive:                                      |
|  - bastion-replication Master/Slave configuration                             |
|  - bastion-replication --elevate-master for failover                          |
|  - VIP/Keepalived configuration                                               |
|  - Standard Linux administration                                              |
|                                                                               |
+===============================================================================+
```

### Budget & Time Decision

```
+===============================================================================+
|  DECISION MATRIX: BUDGET & TIME CONSTRAINTS                                   |
+===============================================================================+
|                                                                               |
|  Constraint           | Scenario                | Recommended Model           |
|  --------------------+------------------------+---------------------------    |
|  Fast Deployment      | - Go-live in 1-2 weeks  | Active-Passive              |
|                       | - Limited prep time     |                             |
|                       | - Urgent requirement    |                             |
|  --------------------+------------------------+---------------------------    |
|  Normal Timeline      | - Go-live in 1 month    | Active-Active or            |
|                       | - Adequate testing      | Active-Passive              |
|                       | - Standard project      | (evaluate other factors)    |
|  --------------------+------------------------+---------------------------    |
|  Greenfield/Ideal     | - No time pressure      | Active-Active               |
|                       | - Full testing cycle    | (if load/availability       |  
|                       | - Best practices focus  | justify complexity)         |
|  --------------------+------------------------+---------------------------    |
|  Limited Budget       | - Minimize OPEX         | Active-Passive              |
|                       | - Smaller team          | (simpler, cheaper ops)      |
|                       | - Cost-conscious        |                             | 
|  --------------------+------------------------+---------------------------    |
|  Enterprise Budget    | - High OPEX acceptable  | Active-Active               | 
|                       | - Large support team    | (maximize availability)     |
|                       | - Best-in-class SLA     |                             |
|  --------------------+------------------------+---------------------------    |
|                                                                               |
|  DEPLOYMENT TIME COMPARISON                                                   |
|  ==========================                                                   |
|                                                                               |
|  Active-Passive:                                                              |
|  - Day 1-2: Base OS installation, network config                              |
|  - Day 3: bastion-replication Master/Slave setup                              |
|  - Day 4: VIP/Keepalived setup                                                |
|  - Day 5: Testing and validation                                              |
|  Total: 5 days                                                                |
|                                                                               |
|  Active-Active:                                                               |
|  - Day 1-2: Base OS installation, network config                              |
|  - Day 3-4: bastion-replication Master/Master setup                           |
|  - Day 5-6: HAProxy HA setup and testing                                      |
|  - Day 7-8: Failover testing, monitoring setup                                |
|  - Day 9-10: Comprehensive testing, tuning                                    |
|  Total: 10 days                                                               |
|                                                                               |
+===============================================================================+
```

### Comprehensive Decision Tree

```
+===============================================================================+
|  DECISION TREE: CHOOSING HA MODEL                                             |
+===============================================================================+
|                                                                               |
|  START                                                                        |
|    |                                                                          |
|    v                                                                          |
|  [ Peak Sessions > 100? ]                                                     |
|    |                                                                          |
|    +---YES---> ACTIVE-ACTIVE (Load distribution required)                     |
|    |                                                                          |
|    +---NO                                                                     |
|        |                                                                      |
|        v                                                                      |
|      [ Uptime SLA > 99.9%? ]                                                  |
|        |                                                                      |
|        +---YES---> [ Failover < 1 second required? ]                          |
|        |             |                                                        |
|        |             +---YES---> ACTIVE-ACTIVE (Near-instant failover)        |
|        |             |                                                        |
|        |             +---NO----> ACTIVE-PASSIVE OK (30-60s acceptable)        |
|        |                                                                      |
|        +---NO                                                                 |
|            |                                                                  |
|            v                                                                  |
|          [ 24/7 Operations? ]                                                 |
|            |                                                                  |
|            +---YES---> [ Zero-downtime maintenance needed? ]                  |
|            |             |                                                    |
|            |             +---YES---> ACTIVE-ACTIVE (Rolling updates)          |
|            |             |                                                    |
|            |             +---NO----> ACTIVE-PASSIVE (Maintenance windows OK)  |
|            |                                                                  |
|            +---NO                                                             |
|                |                                                              |
|                v                                                              |
|              [ Team has distributed systems expertise? ]                      |
|                |                                                              |
|                +---YES---> ACTIVE-ACTIVE (If beneficial)                      |
|                |                                                              |
|                +---NO----> ACTIVE-PASSIVE (Simpler operations)                |
|                                                                               |
|  RECOMMENDATION:                                                              |
|  - If multiple YES answers for ACTIVE-ACTIVE: Use Active-Active               |
|  - If mostly NO answers: Use Active-Passive                                   |
|  - If mixed: Evaluate cost vs benefit (see next section)                      |
|                                                                               |
+===============================================================================+
```

---

## Recommendations

### General Guidelines

```
+===============================================================================+
|  GENERAL RECOMMENDATIONS                                                      |
+===============================================================================+
|                                                                               |
|  CHOOSE ACTIVE-ACTIVE WHEN:                                                   |
|  ==========================                                                   |
|                                                                               |
|  1. High Session Volume (> 100 concurrent)                                    |
|     - Single node insufficient                                                |
|     - Load distribution critical                                              |
|     - Peak loads exceed single-node capacity                                  |
|                                                                               |
|  2. Maximum Availability Required (> 99.9% SLA)                               |
|     - Sub-second failover needed                                              |
|     - Zero-tolerance for interruptions                                        |
|     - Mission-critical 24/7 operations                                        |
|                                                                               |
|  3. Zero-Downtime Maintenance                                                 |
|     - Cannot afford maintenance windows                                       |
|     - Need rolling updates capability                                         |
|     - Continuous operations mandatory                                         |
|                                                                               |
|  4. Expert Team Available                                                     |
|     - Distributed systems expertise                                           |
|     - Multi-master database experience                                        |
|     - Dedicated operations team (4+ people)                                   |
|                                                                               |
|  5. Budget Allows Higher Complexity                                           |
|     - OPEX for advanced monitoring                                            |
|     - Training budget available                                               |
|     - Premium support contracts                                               |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  CHOOSE ACTIVE-PASSIVE WHEN:                                                  |
|  ===========================                                                  |
|                                                                               |
|  1. Lower Session Volume (< 100 concurrent)                                   |
|     - Single node sufficient                                                  |
|     - No immediate scaling needs                                              |
|     - Predictable load patterns                                               |
|                                                                               |
|  2. Moderate Availability Sufficient (99.5-99.9% SLA)                         |
|     - 30-60 second failover acceptable                                        |
|     - Brief outages tolerable                                                 |
|     - User reconnection acceptable                                            |
|                                                                               |
|  3. Simplicity Priority                                                       |
|     - Faster initial deployment                                               |
|     - Easier ongoing operations                                               |
|     - Limited HA expertise                                                    |
|                                                                               |
|  4. Small Operations Team (1-3 people)                                        |
|     - Limited operational bandwidth                                           |
|     - Standard Linux admin skills                                             |
|     - Occasional on-call acceptable                                           |
|                                                                               |
|  5. Cost-Conscious Deployment                                                 |
|     - Minimize OPEX                                                           |
|     - Lower operational complexity = lower cost                               |
|     - Acceptable to waste standby capacity                                    |
|                                                                               |
+===============================================================================+
```

### Site-Specific Recommendations (5-Site Deployment)

Given your 5-site multi-datacenter deployment with Access Manager integration:

```
+===============================================================================+
|  SITE-SPECIFIC RECOMMENDATIONS                                                |
+===============================================================================+
|                                                                               |
|  SCENARIO 1: ALL SITES HIGH LOAD                                              |
|  ===============================                                              |
|                                                                               |
|  If all 5 sites expect > 100 concurrent sessions:                             |
|  - Deploy Active-Active at ALL sites                                          |
|  - Justification: Maximum capacity utilization, consistent architecture       |
|  - Complexity: High, but consistent across sites                              |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  SCENARIO 2: MIXED LOAD ACROSS SITES                                          |
|  ===================================                                          |
|                                                                               |
|  If some sites have high load, others low:                                    |
|  - Option A: Active-Active for all (consistent architecture)                  |
|    + Same configuration everywhere                                            |
|    + Team learns one model                                                    |
|    - Overengineered for low-load sites                                        |
|                                                                               |
|  - Option B: Mixed deployment (Active-Active high, Active-Passive low)        |
|    + Optimized per site                                                       |
|    + Lower complexity for low-load sites                                      |
|    - Team must know both models                                               |
|    - Different runbooks per site                                              |
|                                                                               |
|  Recommendation: Option A (consistent architecture) if team expertise allows  |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  SCENARIO 3: ALL SITES LOW-MEDIUM LOAD                                        |
|  ======================================                                       |
|                                                                               |
|  If all 5 sites expect < 100 concurrent sessions:                             |
|  - Deploy Active-Passive at ALL sites                                         |
|  - Justification: Simplicity, faster deployment, lower OPEX                   |
|  - Future: Can migrate to Active-Active if load grows                         |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  SCENARIO 4: PHASED DEPLOYMENT (RECOMMENDED)                                  |
|  ===========================================                                  |
|                                                                               |
|  Phase 1: Deploy Site 1 with Active-Passive                                   |
|  - Faster go-live (1 week vs 2 weeks)                                         |
|  - Prove architecture works                                                   |
|  - Team learns basics                                                         |
|                                                                               |
|  Phase 2: Evaluate after 1 month                                              |
|  - Measure actual load                                                        |
|  - Assess team capability                                                     |
|  - Identify pain points                                                       |
|                                                                               |
|  Phase 3: Decide on Sites 2-5                                                 |
|  - If Site 1 load high: Upgrade to Active-Active, deploy A-A for others      |
|  - If Site 1 load low: Continue Active-Passive for all                        |
|                                                                               |
|  Benefit: De-risk deployment, data-driven decision                            |
|                                                                               |
+===============================================================================+
```

### Migration Path

If you start with Active-Passive and need to migrate to Active-Active:

```
+===============================================================================+
|  MIGRATION PATH: ACTIVE-PASSIVE TO ACTIVE-ACTIVE                              |
+===============================================================================+
|                                                                               |
|  PREREQUISITES                                                                |
|  =============                                                                |
|  - Active-Passive (Master/Slave) cluster running stably                       |
|  - Team trained on bastion-replication Master/Master concepts                 |
|  - HAProxy HA pair deployed                                                   |
|  - Maintenance window approved (2-4 hours)                                    |
|                                                                               |
|  MIGRATION STEPS                                                              |
|  ===============                                                              |
|                                                                               |
|  1. Prepare (1-2 days before)                                                 |
|     - Backup both nodes (database, config, keys)                              |
|     - Document current Master/Slave config                                    |
|     - Test HAProxy configuration in lab                                       |
|     - Prepare Master/Master configuration file                                |
|                                                                               |
|  2. Stop Current Replication (Maintenance Window Start)                       |
|     - Stop WALLIX services on both nodes                                      |
|     - bastion-replication --stop                                              |
|                                                                               |
|  3. Reconfigure bastion-replication for Master/Master (1-2 hours)             |
|     - bastion-replication --create-conf-file  # Select Master/Master mode     |
|     - bastion-replication --install           # Install new replication       |
|     - bastion-replication --monitoring        # Verify replication status     |
|                                                                               |
|  4. Configure HAProxy (1 hour)                                                |
|     - Add both Bastion nodes to backend pool                                  |
|     - Configure health checks                                                 |
|     - Set load balancing algorithm (roundrobin)                               |
|     - Enable session persistence (cookies for HTTPS)                          |
|                                                                               |
|  5. Start Services and Test (1-2 hours)                                       |
|     - Start WALLIX services on both nodes                                     |
|     - Verify both nodes show as active                                        |
|     - Test connections via HAProxy VIP                                        |
|     - Verify load distribution (check HAProxy stats)                          |
|     - Test session persistence                                                |
|     - Test failover (stop one node, verify seamless failover)                 |
|                                                                               |
|  6. Enable Monitoring and Notifications (30 min)                              |
|     - bastion-replication --install-monitoring                                |
|     - bastion-replication --install-notification                              |
|     - Verify monitoring via bastion-replication --monitoring                  |
|                                                                               |
|  7. Monitor and Validate (24 hours)                                           |
|     - Monitor replication status via bastion-replication --monitoring         |
|     - Check for replication lag/conflicts                                     |
|     - Verify load balancing working correctly                                 |
|     - Check session distribution across nodes                                 |
|                                                                               |
|  ROLLBACK PLAN                                                                |
|  =============                                                                |
|  If migration fails:                                                          |
|  - bastion-replication --stop                                                 |
|  - Restore database from backup (bastion-replication --dump-resync)           |
|  - bastion-replication --create-conf-file  # Select Master/Slave mode         |
|  - bastion-replication --install                                              |
|  - Re-enable VIP on primary node                                              |
|  - Start services                                                             |
|                                                                               |
|  TOTAL MIGRATION TIME: 2-4 hours (maintenance window)                         |
|                                                                               |
+===============================================================================+
```

### Final Recommendation Summary

**For Your 5-Site Deployment:**

1. **If you are unsure:** Start with **Active-Passive** (Master/Slave) for Site 1
   - Faster deployment (5 days vs 10 days)
   - Lower risk for initial rollout
   - Team learns bastion-replication basics
   - Can migrate to Active-Active (Master/Master) later if needed

2. **If you have clear high-load requirements (> 100 sessions per site):** Use **Active-Active** from the start
   - Avoid migration complexity later
   - Maximum performance from day one
   - Consistent architecture across all sites

3. **If you have mixed requirements:** Use **Active-Active for high-load sites, Active-Passive for low-load sites**
   - Optimized per site
   - BUT: Requires team to know both models

**Best Practice for Most Deployments:**
- **Start with Active-Passive**
- Validate architecture and load in production
- Migrate to Active-Active if justified by data
- This de-risks deployment and allows data-driven decisions

---

---

## FortiAuthenticator HA Options (Per Site)

Each site has an independent FortiAuthenticator HA pair in the Cyber VLAN. Like the Bastion cluster, FortiAuthenticator uses a Primary/Secondary (Active-Passive) model.

```
+===============================================================================+
|  FORTIAUTHENTICATOR HA MODEL (PER SITE)                                       |
+===============================================================================+
|                                                                               |
|  Cyber VLAN                                                                   |
|                                                                               |
|  +----------------------------------+  +----------------------------------+    |
|  |  FortiAuthenticator-1 (PRIMARY)  |  |  FortiAuthenticator-2 (SECONDARY)|    |
|  |  10.10.X.50                      |  |  10.10.X.51                      |    |
|  |  Role: Master (Active)           |  |  Role: Slave (Standby)           |    |
|  |  Handles: All RADIUS requests    |  |  Handles: Synced, ready to        |    |
|  |  Manages: Cluster VIP X.52      |<->|  promote if Primary fails        |    |
|  +----------------------------------+  +----------------------------------+    |
|                                                                               |
|  Failover: Automatic (FortiAuth HA built-in, ~30-60 second promotion)         |
|  Sync: User database, RADIUS clients, policies, FortiToken data               |
|  VIP: 10.10.X.52 (floats to active node for management)                       |
|                                                                               |
|  WALLIX Bastion configures BOTH X.50 and X.51 as RADIUS servers               |
|  (primary and secondary). Bastion retries secondary after timeout.            |
|                                                                               |
+===============================================================================+
```

### FortiAuthenticator HA vs Bastion HA

| Aspect | Bastion HA | FortiAuth HA |
|--------|-----------|--------------|
| Model | Active-Active OR Active-Passive | Active-Passive (Primary/Secondary) |
| Failover time | < 1s (A-A) or 30-60s (A-P) | ~30-60 seconds (automatic promotion) |
| Configuration | bastion-replication | FortiAuthenticator built-in HA |
| VLAN | DMZ VLAN | Cyber VLAN |
| Sync | MariaDB replication | FortiAuth sync (users, policies, tokens) |
| Client config | HAProxy load balances | Bastion configures both IPs as RADIUS servers |

### FortiAuth HA Mirrors Bastion HA per Site

Both components use Active-Passive HA at the site level. Both are independent per site — there is no cross-site FortiAuth or cross-site Bastion communication.

For full FortiAuthenticator HA setup, see [03-fortiauthenticator-ha.md](03-fortiauthenticator-ha.md).

---

## Next Steps

After choosing your HA model:

1. **For Active-Passive Bastion:** Proceed to [08-bastion-active-passive.md](08-bastion-active-passive.md)
2. **For Active-Active Bastion:** Proceed to [07-bastion-active-active.md](07-bastion-active-active.md)
3. **For FortiAuthenticator HA setup:** See [03-fortiauthenticator-ha.md](03-fortiauthenticator-ha.md)
4. **For load balancer setup:** See [06-haproxy-setup.md](06-haproxy-setup.md)
5. **For detailed HA concepts:** Review [/docs/pam/11-high-availability/README.md](../docs/pam/11-high-availability/README.md)

---

## Related Documentation

- [03-fortiauthenticator-ha.md](03-fortiauthenticator-ha.md) - Per-site FortiAuth HA pair setup
- [07-bastion-active-active.md](07-bastion-active-active.md) - Active-Active cluster setup
- [08-bastion-active-passive.md](08-bastion-active-passive.md) - Active-Passive cluster setup
- [11 - High Availability & Disaster Recovery](../docs/pam/11-high-availability/README.md) - Detailed HA concepts
- [32 - Load Balancer](../docs/pam/32-load-balancer/README.md) - HAProxy configuration
- [29 - Disaster Recovery](../docs/pam/29-disaster-recovery/README.md) - DR procedures
- [30 - Backup & Restore](../docs/pam/30-backup-restore/README.md) - Backup strategies

---

*Document Version: 2.0 | Last Updated: April 2026*
