# 10 - High Availability & Disaster Recovery

## Table of Contents

1. [HA Overview](#ha-overview)
2. [Clustering Modes](#clustering-modes)
3. [Active/Passive Configuration](#activepassive-configuration)
4. [Active/Active Configuration](#activeactive-configuration)
5. [Database High Availability](#database-high-availability)
6. [Disaster Recovery](#disaster-recovery)
7. [Backup & Restore](#backup--restore)
8. [Monitoring HA Health](#monitoring-ha-health)

---

## HA Overview

### High Availability Architecture

```
+===============================================================================+
|                    HIGH AVAILABILITY OVERVIEW                                 |
+===============================================================================+
|                                                                               |
|  AVAILABILITY TIERS                                                           |
|  =================                                                            |
|                                                                               |
|  +-----------------+----------------+----------------+---------------------+|
|  | Tier            | Configuration  | Uptime Target  | RTO/RPO             ||
|  +-----------------+----------------+----------------+---------------------+|
|  | Standalone      | Single node    | 99% (87 hrs/yr)| Hours/Hours         ||
|  | Active/Passive  | 2-node cluster | 99.9% (8.7 hrs)| Minutes/Minutes     ||
|  | Active/Active   | N-node cluster | 99.99% (52 min)| Seconds/Seconds     ||
|  | Multi-Site      | Geo-redundant  | 99.999% (5 min)| Minutes/Near-zero   ||
|  +-----------------+----------------+----------------+---------------------+|
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  COMPONENTS REQUIRING HA                                                      |
|  =======================                                                      |
|                                                                               |
|  +---------------------------------------------------------------------+|
|  | Component              | HA Method                                       ||
|  +------------------------+---------------------------------------------+|
|  | Bastion Application    | Cluster (Active/Passive or Active/Active)      ||
|  | PostgreSQL Database    | Streaming replication + automatic failover     ||
|  | Session Recordings     | Shared storage (NAS/SAN) or replication        ||
|  | Configuration Data     | Synchronized across cluster nodes              ||
|  | Encryption Keys        | Replicated with cluster                        ||
|  +------------------------+---------------------------------------------+|
|                                                                               |
+===============================================================================+
```

### CyberArk Comparison

> **CyberArk Equivalent: Vault DR, PSM Load Balancing, PVWA HA**

| Feature | CyberArk | WALLIX |
|---------|----------|--------|
| Vault HA | Primary/DR Vault | PostgreSQL replication |
| Session HA | PSM farm with LB | Active/Active cluster |
| Web HA | PVWA behind LB | Access Manager cluster |
| Failover Time | Minutes (DR activation) | Seconds (automatic) |
| Data Sync | Vault replication | Real-time sync |
| Geo-redundancy | DR Vault in remote site | Multi-site with sync |

**Key Differences:**
- WALLIX uses standard PostgreSQL clustering (proven, well-documented)
- CyberArk DR requires manual Vault activation; WALLIX is automatic
- WALLIX Active/Active allows read/write on all nodes simultaneously
- Session continuity: Active sessions can continue on failover with WALLIX

---

## Clustering Modes

### Mode Comparison

```
+===============================================================================+
|                      CLUSTERING MODE COMPARISON                               |
+===============================================================================+
|                                                                               |
|  ACTIVE/PASSIVE                                                               |
|  ==============                                                               |
|                                                                               |
|         +-----------------+         +-----------------+                      |
|         |   Node 1        |         |   Node 2        |                      |
|         |   (ACTIVE)      |<------->|   (STANDBY)     |                      |
|         |                 |  Sync   |                 |                      |
|         |  * Running      |         |  o Ready        |                      |
|         |  * Serving      |         |  o Monitoring   |                      |
|         +--------+--------+         +-----------------+                      |
|                  |                                                            |
|            All traffic                                                        |
|                                                                               |
|  Pros: Simple, lower cost                                                    |
|  Cons: Failover time, idle standby                                           |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  ACTIVE/ACTIVE                                                                |
|  =============                                                                |
|                                                                               |
|                     +-----------------+                                      |
|                     |  Load Balancer  |                                      |
|                     +--------+--------+                                      |
|                              |                                               |
|              +---------------+---------------+                               |
|              |               |               |                               |
|              v               v               v                               |
|    +-----------------+ +-----------------+ +-----------------+              |
|    |   Node 1        | |   Node 2        | |   Node 3        |              |
|    |   (ACTIVE)      | |   (ACTIVE)      | |   (ACTIVE)      |              |
|    |  * Serving      | |  * Serving      | |  * Serving      |              |
|    +-----------------+ +-----------------+ +-----------------+              |
|              |               |               |                               |
|              +---------------+---------------+                               |
|                              |                                               |
|                    +---------+---------+                                     |
|                    |  Shared Storage   |                                     |
|                    |  + Database       |                                     |
|                    +-------------------+                                     |
|                                                                               |
|  Pros: No failover, load distribution, scalability                           |
|  Cons: More complex, requires shared storage                                 |
|                                                                               |
+===============================================================================+
```

---

## Active/Passive Configuration

### Architecture

```
+===============================================================================+
|                    ACTIVE/PASSIVE CLUSTER                                     |
+===============================================================================+
|                                                                               |
|                          +-----------------+                                 |
|                          |  Virtual IP     |                                 |
|                          |  (Floating)     |                                 |
|                          |  192.168.1.10   |                                 |
|                          +--------+--------+                                 |
|                                   |                                          |
|                  +----------------+----------------+                         |
|                  |                                 |                         |
|                  v                                 v                         |
|  +-------------------------------+ +-------------------------------+        |
|  |        NODE 1 (PRIMARY)       | |       NODE 2 (STANDBY)        |        |
|  |                               | |                               |        |
|  |  IP: 192.168.1.11             | |  IP: 192.168.1.12             |        |
|  |                               | |                               |        |
|  |  +-------------------------+  | |  +-------------------------+  |        |
|  |  | WALLIX Bastion          |  | |  | WALLIX Bastion          |  |        |
|  |  | (Running)               |  | |  | (Standby)               |  |        |
|  |  +-------------------------+  | |  +-------------------------+  |        |
|  |                               | |                               |        |
|  |  +-------------------------+  | |  +-------------------------+  |        |
|  |  | PostgreSQL              |  | |  | PostgreSQL              |  |        |
|  |  | (Primary)               |<-+-+->| (Replica)               |  |        |
|  |  +-------------------------+  | |  +-------------------------+  |        |
|  |                               | |     Streaming Replication     |        |
|  +-------------------------------+ +-------------------------------+        |
|                  |                                 |                         |
|                  +----------------+----------------+                         |
|                                   |                                          |
|                          +--------+--------+                                 |
|                          | Shared Storage  |                                 |
|                          | (Recordings)    |                                 |
|                          | NFS/iSCSI       |                                 |
|                          +-----------------+                                 |
|                                                                               |
+===============================================================================+
```

### Failover Process

```
+===============================================================================+
|                      FAILOVER PROCESS                                         |
+===============================================================================+
|                                                                               |
|  AUTOMATIC FAILOVER SEQUENCE                                                  |
|  ===========================                                                  |
|                                                                               |
|  1. DETECTION                                                                 |
|     -----------                                                               |
|     * Heartbeat failure detected                                             |
|     * Health check fails (3 consecutive)                                     |
|     * Service unresponsive                                                   |
|                                                                               |
|                    |                                                          |
|                    v                                                          |
|                                                                               |
|  2. VALIDATION                                                                |
|     -----------                                                               |
|     * Confirm primary is truly down (avoid split-brain)                      |
|     * STONITH/fencing if configured                                          |
|     * Quorum check (if 3+ nodes)                                             |
|                                                                               |
|                    |                                                          |
|                    v                                                          |
|                                                                               |
|  3. DATABASE PROMOTION                                                        |
|     ----------------------                                                    |
|     * Promote PostgreSQL replica to primary                                  |
|     * Ensure data consistency                                                |
|     * Update connection strings                                              |
|                                                                               |
|                    |                                                          |
|                    v                                                          |
|                                                                               |
|  4. SERVICE ACTIVATION                                                        |
|     --------------------                                                      |
|     * Start WALLIX services on standby                                       |
|     * Verify service health                                                  |
|                                                                               |
|                    |                                                          |
|                    v                                                          |
|                                                                               |
|  5. VIP MIGRATION                                                             |
|     --------------                                                            |
|     * Move floating IP to new primary                                        |
|     * Update ARP tables                                                      |
|     * DNS update (if applicable)                                             |
|                                                                               |
|                    |                                                          |
|                    v                                                          |
|                                                                               |
|  6. NOTIFICATION                                                              |
|     ------------                                                              |
|     * Alert administrators                                                   |
|     * Log failover event                                                     |
|     * Update monitoring                                                      |
|                                                                               |
|  TYPICAL FAILOVER TIME: 30-120 seconds                                       |
|                                                                               |
+===============================================================================+
```

### Configuration Example

```bash
# /etc/wallix/cluster.conf

[cluster]
mode = active_passive
cluster_name = wallix-prod

[node1]
hostname = bastion-node1.company.com
ip_address = 192.168.1.11
role = primary

[node2]
hostname = bastion-node2.company.com
ip_address = 192.168.1.12
role = standby

[vip]
virtual_ip = 192.168.1.10
interface = eth0
netmask = 255.255.255.0

[heartbeat]
interval_seconds = 2
timeout_seconds = 10
failover_threshold = 3

[database]
replication_mode = streaming
sync_mode = synchronous

[storage]
type = nfs
path = nas.company.com:/wallix/recordings
mount_point = /var/wab/recorded
```

---

## Active/Active Configuration

### Architecture

```
+===============================================================================+
|                      ACTIVE/ACTIVE CLUSTER                                    |
+===============================================================================+
|                                                                               |
|                          +---------------------+                             |
|                          |    Load Balancer    |                             |
|                          |    (F5 / HAProxy)   |                             |
|                          |                     |                             |
|                          |  VIP: 192.168.1.10  |                             |
|                          +----------+----------+                             |
|                                     |                                        |
|             +-----------------------+-----------------------+                |
|             |                       |                       |                |
|             v                       v                       v                |
|  +------------------+   +------------------+   +------------------+         |
|  |    NODE 1        |   |    NODE 2        |   |    NODE 3        |         |
|  |                  |   |                  |   |                  |         |
|  | IP: 192.168.1.11 |   | IP: 192.168.1.12 |   | IP: 192.168.1.13 |         |
|  |                  |   |                  |   |                  |         |
|  | +--------------+ |   | +--------------+ |   | +--------------+ |         |
|  | |   WALLIX     | |   | |   WALLIX     | |   | |   WALLIX     | |         |
|  | |   Bastion    | |   | |   Bastion    | |   | |   Bastion    | |         |
|  | |   (Active)   | |   | |   (Active)   | |   | |   (Active)   | |         |
|  | +--------------+ |   | +--------------+ |   | +--------------+ |         |
|  +--------+---------+   +--------+---------+   +--------+---------+         |
|           |                      |                      |                    |
|           +----------------------+----------------------+                    |
|                                  |                                           |
|                    +-------------+-------------+                             |
|                    |                           |                             |
|                    v                           v                             |
|         +------------------+       +----------------------+                  |
|         |   PostgreSQL     |       |   Shared Storage     |                  |
|         |   Cluster        |       |   (NAS/SAN)          |                  |
|         |                  |       |                      |                  |
|         |  Primary + 2     |       |  /var/wab/recorded   |                  |
|         |  Replicas        |       |  /var/wab/shared     |                  |
|         +------------------+       +----------------------+                  |
|                                                                               |
+===============================================================================+
```

### Load Balancer Configuration

```
+===============================================================================+
|                    LOAD BALANCER CONFIGURATION                                |
+===============================================================================+
|                                                                               |
|  HAProxy Example Configuration                                                |
|  =============================                                                |
|                                                                               |
|  # /etc/haproxy/haproxy.cfg                                                  |
|                                                                               |
|  frontend wallix_https                                                        |
|      bind *:443 ssl crt /etc/ssl/wallix.pem                                  |
|      mode http                                                                |
|      default_backend wallix_nodes                                            |
|                                                                               |
|  frontend wallix_ssh                                                          |
|      bind *:22                                                                |
|      mode tcp                                                                 |
|      default_backend wallix_ssh_nodes                                        |
|                                                                               |
|  frontend wallix_rdp                                                          |
|      bind *:3389                                                              |
|      mode tcp                                                                 |
|      default_backend wallix_rdp_nodes                                        |
|                                                                               |
|  backend wallix_nodes                                                         |
|      mode http                                                                |
|      balance roundrobin                                                       |
|      option httpchk GET /health                                              |
|      cookie SERVERID insert indirect nocache                                 |
|      server node1 192.168.1.11:443 ssl check cookie node1                    |
|      server node2 192.168.1.12:443 ssl check cookie node2                    |
|      server node3 192.168.1.13:443 ssl check cookie node3                    |
|                                                                               |
|  backend wallix_ssh_nodes                                                     |
|      mode tcp                                                                 |
|      balance source                                                           |
|      option tcp-check                                                         |
|      server node1 192.168.1.11:22 check                                      |
|      server node2 192.168.1.12:22 check                                      |
|      server node3 192.168.1.13:22 check                                      |
|                                                                               |
|  backend wallix_rdp_nodes                                                     |
|      mode tcp                                                                 |
|      balance source                                                           |
|      option tcp-check                                                         |
|      server node1 192.168.1.11:3389 check                                    |
|      server node2 192.168.1.12:3389 check                                    |
|      server node3 192.168.1.13:3389 check                                    |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  SESSION PERSISTENCE                                                          |
|  ===================                                                          |
|                                                                               |
|  Protocol     | Persistence Method    | Reason                               |
|  -------------+-----------------------+------------------------------------  |
|  HTTPS (UI)   | Cookie-based          | User session state                   |
|  SSH          | Source IP hash        | Session continuity                   |
|  RDP          | Source IP hash        | Session continuity                   |
|                                                                               |
+===============================================================================+
```

---

## Database High Availability

### PostgreSQL Replication

```
+===============================================================================+
|                    POSTGRESQL HA CONFIGURATION                                |
+===============================================================================+
|                                                                               |
|  STREAMING REPLICATION                                                        |
|  =====================                                                        |
|                                                                               |
|         +---------------------+                                              |
|         |   PRIMARY           |                                              |
|         |   PostgreSQL        |                                              |
|         |                     |                                              |
|         |   Writes + Reads    |                                              |
|         +----------+----------+                                              |
|                    |                                                          |
|         +----------+----------+                                              |
|         |   WAL Streaming     |                                              |
|         |                     |                                              |
|         v                     v                                              |
|  +-----------------+   +-----------------+                                   |
|  |   REPLICA 1     |   |   REPLICA 2     |                                   |
|  |   (Sync)        |   |   (Async)       |                                   |
|  |                 |   |                 |                                   |
|  |   Reads only    |   |   Reads only    |                                   |
|  +-----------------+   +-----------------+                                   |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  PATRONI CLUSTER MANAGEMENT                                                   |
|  ==========================                                                   |
|                                                                               |
|  Patroni provides:                                                            |
|  * Automatic leader election                                                 |
|  * Automatic failover                                                        |
|  * REST API for management                                                   |
|  * Integration with etcd/Consul/ZooKeeper                                    |
|                                                                               |
|  # patroni.yml                                                               |
|  scope: wallix-cluster                                                        |
|  name: node1                                                                  |
|                                                                               |
|  restapi:                                                                     |
|    listen: 0.0.0.0:8008                                                      |
|    connect_address: 192.168.1.11:8008                                        |
|                                                                               |
|  etcd:                                                                        |
|    hosts:                                                                     |
|      - 192.168.1.21:2379                                                     |
|      - 192.168.1.22:2379                                                     |
|      - 192.168.1.23:2379                                                     |
|                                                                               |
|  bootstrap:                                                                   |
|    dcs:                                                                       |
|      synchronous_mode: true                                                  |
|      postgresql:                                                              |
|        parameters:                                                            |
|          max_connections: 200                                                |
|          synchronous_commit: on                                              |
|                                                                               |
+===============================================================================+
```

---

## Disaster Recovery

### Multi-Site Architecture

```
+===============================================================================+
|                    MULTI-SITE DISASTER RECOVERY                               |
+===============================================================================+
|                                                                               |
|     SITE A (PRIMARY)                         SITE B (DR)                     |
|     ================                         ==========                      |
|                                                                               |
|  +--------------------------+     +--------------------------+              |
|  |                          |     |                          |              |
|  |  +--------------------+  |     |  +--------------------+  |              |
|  |  |  WALLIX Cluster    |  |     |  |  WALLIX Cluster    |  |              |
|  |  |  (Active)          |  |     |  |  (Standby)         |  |              |
|  |  |                    |  |     |  |                    |  |              |
|  |  |  Node1  Node2      |  |     |  |  Node1  Node2      |  |              |
|  |  +---------+----------+  |     |  +---------+----------+  |              |
|  |            |             |     |            |             |              |
|  |  +---------+----------+  |     |  +---------+----------+  |              |
|  |  |  PostgreSQL        |<-+-----+->|  PostgreSQL        |  |              |
|  |  |  (Primary)         |  |     |  |  (Replica)         |  |              |
|  |  +--------------------+  |     |  +--------------------+  |              |
|  |                          |     |      Async Replication   |              |
|  |  +--------------------+  |     |  +--------------------+  |              |
|  |  |  Recording Storage |<-+-----+->|  Recording Storage |  |              |
|  |  |  (Primary)         |  |     |  |  (Replica)         |  |              |
|  |  +--------------------+  |     |  +--------------------+  |              |
|  |                          |     |      rsync/replication   |              |
|  +--------------------------+     +--------------------------+              |
|                                                                               |
|                          +-----------------+                                 |
|                          |  Global DNS /   |                                 |
|                          |  GSLB           |                                 |
|                          |                 |                                 |
|                          |  bastion.co.com |                                 |
|                          +-----------------+                                 |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  DR METRICS                                                                   |
|  ==========                                                                   |
|                                                                               |
|  +-------------------+---------------------------------------------------+  |
|  | Metric            | Target                                             |  |
|  +-------------------+---------------------------------------------------+  |
|  | RPO               | < 5 minutes (async replication lag)               |  |
|  | RTO               | < 30 minutes (manual failover)                    |  |
|  |                   | < 5 minutes (automated failover)                  |  |
|  | Replication Lag   | < 1 minute under normal conditions                |  |
|  +-------------------+---------------------------------------------------+  |
|                                                                               |
+===============================================================================+
```

### DR Failover Procedure

```
+===============================================================================+
|                    DR FAILOVER PROCEDURE                                      |
+===============================================================================+
|                                                                               |
|  STEP 1: ASSESS SITUATION                                                     |
|  ========================                                                     |
|                                                                               |
|  [ ] Confirm primary site is unavailable                                       |
|  [ ] Estimate recovery time for primary                                        |
|  [ ] Decision: Failover or wait?                                               |
|                                                                               |
|  STEP 2: PREPARE DR SITE                                                      |
|  =======================                                                      |
|                                                                               |
|  [ ] Check replication status                                                  |
|  [ ] Verify data consistency                                                   |
|  [ ] Confirm DR site resources are ready                                       |
|                                                                               |
|  STEP 3: PROMOTE DR SITE                                                      |
|  ======================                                                       |
|                                                                               |
|  [ ] Promote PostgreSQL replica to primary                                     |
|     $ patronictl failover wallix-cluster                                     |
|                                                                               |
|  [ ] Start WALLIX Bastion services                                             |
|     $ systemctl start wabengine                                              |
|                                                                               |
|  [ ] Verify services are running                                               |
|     $ systemctl status wab*                                                  |
|                                                                               |
|  STEP 4: UPDATE DNS/ROUTING                                                   |
|  ========================                                                     |
|                                                                               |
|  [ ] Update DNS records to point to DR site                                    |
|  [ ] Or update GSLB health checks                                              |
|  [ ] Clear DNS caches if needed                                                |
|                                                                               |
|  STEP 5: VERIFY                                                               |
|  =============                                                                |
|                                                                               |
|  [ ] Test user authentication                                                  |
|  [ ] Test session establishment                                                |
|  [ ] Verify recording functionality                                            |
|  [ ] Check password rotation                                                   |
|                                                                               |
|  STEP 6: NOTIFY                                                               |
|  =============                                                                |
|                                                                               |
|  [ ] Notify stakeholders of failover                                           |
|  [ ] Document incident timeline                                                |
|  [ ] Plan failback when primary recovers                                       |
|                                                                               |
+===============================================================================+
```

---

## Backup & Restore

### Backup Strategy

```
+===============================================================================+
|                        BACKUP STRATEGY                                        |
+===============================================================================+
|                                                                               |
|  BACKUP COMPONENTS                                                            |
|  =================                                                            |
|                                                                               |
|  +---------------------+-----------------+-----------------+---------------+|
|  | Component           | Method          | Frequency       | Retention     ||
|  +---------------------+-----------------+-----------------+---------------+|
|  | PostgreSQL Database | pg_dump/basebackup | Daily        | 30 days       ||
|  | Configuration Files | File backup     | Daily + changes | 90 days       ||
|  | Encryption Keys     | Secure export   | On change       | Indefinite    ||
|  | Session Recordings  | Rsync/snapshot  | Continuous      | Per policy    ||
|  | SSL Certificates    | File backup     | On change       | Indefinite    ||
|  +---------------------+-----------------+-----------------+---------------+|
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  BACKUP SCRIPT EXAMPLE                                                        |
|  =====================                                                        |
|                                                                               |
|  #!/bin/bash                                                                  |
|  # WALLIX Bastion Backup Script                                              |
|                                                                               |
|  BACKUP_DIR="/backup/wallix/$(date +%Y%m%d)"                                 |
|  mkdir -p $BACKUP_DIR                                                         |
|                                                                               |
|  # Database backup                                                            |
|  pg_dump -U wabadmin wabdb > $BACKUP_DIR/database.sql                        |
|                                                                               |
|  # Configuration backup                                                       |
|  tar -czf $BACKUP_DIR/config.tar.gz /etc/opt/wab/                            |
|                                                                               |
|  # Keys backup (encrypted)                                                    |
|  tar -czf - /var/opt/wab/keys/ | \                                           |
|    openssl enc -aes-256-cbc -salt -out $BACKUP_DIR/keys.tar.gz.enc           |
|                                                                               |
|  # Certificates backup                                                        |
|  tar -czf $BACKUP_DIR/certs.tar.gz /etc/ssl/wallix/                          |
|                                                                               |
|  # Verify backups                                                             |
|  sha256sum $BACKUP_DIR/* > $BACKUP_DIR/checksums.sha256                      |
|                                                                               |
+===============================================================================+
```

### Restore Procedure

```
+===============================================================================+
|                        RESTORE PROCEDURE                                      |
+===============================================================================+
|                                                                               |
|  FULL SYSTEM RESTORE                                                          |
|  ===================                                                          |
|                                                                               |
|  1. Install fresh WALLIX Bastion                                             |
|                                                                               |
|  2. Stop services                                                             |
|     $ systemctl stop wab*                                                    |
|                                                                               |
|  3. Restore database                                                          |
|     $ psql -U wabadmin wabdb < /backup/database.sql                          |
|                                                                               |
|  4. Restore configuration                                                     |
|     $ tar -xzf /backup/config.tar.gz -C /                                    |
|                                                                               |
|  5. Restore encryption keys                                                   |
|     $ openssl enc -d -aes-256-cbc -in /backup/keys.tar.gz.enc | \            |
|       tar -xzf - -C /                                                         |
|                                                                               |
|  6. Restore certificates                                                      |
|     $ tar -xzf /backup/certs.tar.gz -C /                                     |
|                                                                               |
|  7. Set permissions                                                           |
|     $ chown -R wabadmin:wabadmin /var/opt/wab/                               |
|                                                                               |
|  8. Start services                                                            |
|     $ systemctl start wab*                                                   |
|                                                                               |
|  9. Verify functionality                                                      |
|     $ wabcheck --full                                                        |
|                                                                               |
+===============================================================================+
```

---

## Monitoring HA Health

### Health Check Endpoints

```
+===============================================================================+
|                      HA HEALTH MONITORING                                     |
+===============================================================================+
|                                                                               |
|  HEALTH CHECK ENDPOINTS                                                       |
|  ======================                                                       |
|                                                                               |
|  GET /health                                                                  |
|  Response:                                                                    |
|  {                                                                            |
|      "status": "healthy",                                                     |
|      "node": "bastion-node1",                                                |
|      "cluster_role": "primary",                                              |
|      "components": {                                                          |
|          "database": "healthy",                                              |
|          "session_manager": "healthy",                                       |
|          "password_manager": "healthy",                                      |
|          "recording_storage": "healthy"                                      |
|      },                                                                       |
|      "cluster": {                                                             |
|          "nodes": 2,                                                          |
|          "healthy_nodes": 2,                                                  |
|          "replication_lag_seconds": 0                                        |
|      }                                                                        |
|  }                                                                            |
|                                                                               |
|  --------------------------------------------------------------------------- |
|                                                                               |
|  MONITORING METRICS                                                           |
|  =================                                                            |
|                                                                               |
|  Cluster Health:                                                              |
|  * Node status (up/down)                                                     |
|  * Cluster role (primary/standby)                                            |
|  * Replication lag                                                           |
|  * Split-brain detection                                                     |
|                                                                               |
|  Service Health:                                                              |
|  * Service response time                                                     |
|  * Active sessions count                                                     |
|  * Authentication success rate                                               |
|  * Recording storage capacity                                                |
|                                                                               |
|  Database Health:                                                             |
|  * Connection pool utilization                                               |
|  * Query response time                                                       |
|  * Replication status                                                        |
|  * Disk space                                                                |
|                                                                               |
+===============================================================================+
```

---

## Next Steps

Continue to [11 - Migration from CyberArk](../11-migration-from-cyberark/README.md) for migration strategies.
