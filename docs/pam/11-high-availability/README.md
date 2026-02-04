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
9. [API Client Failover Best Practices](#api-client-failover-best-practices)

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
|  +-----------------+----------------+----------------+---------------------+  |
|  | Tier            | Configuration  | Uptime Target  | RTO/RPO             |  |
|  +-----------------+----------------+----------------+---------------------+  |
|  | Standalone      | Single node    | 99% (87 hrs/yr)| Hours/Hours         |  |
|  | Active/Passive  | 2-node cluster | 99.9% (8.7 hrs)| Minutes/Minutes     |  |
|  | Active/Active   | N-node cluster | 99.99% (52 min)| Seconds/Seconds     |  |
|  | Multi-Site      | Geo-redundant  | 99.999% (5 min)| Minutes/Near-zero   |  |
|  +-----------------+----------------+----------------+---------------------+  |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  COMPONENTS REQUIRING HA                                                      |
|  =======================                                                      |
|                                                                               |
|  +---------------------------------------------------------------------+      |
|  | Component              | HA Method                                  |      |
|  +------------------------+--------------------------------------------+      |
|  | Bastion Application    | Cluster (Active/Passive or Active/Active)  |      |
|  | MariaDB Database       | Streaming replication + automatic failover |      |
|  | Session Recordings     | Shared storage (NAS/SAN) or replication    |      |
|  | Configuration Data     | Synchronized across cluster nodes          |      |
|  | Encryption Keys        | Replicated with cluster                    |      |
|  +------------------------+--------------------------------------------+      |
|                                                                               |
+===============================================================================+
```

### CyberArk Comparison

> **CyberArk Equivalent: Vault DR, PSM Load Balancing, PVWA HA**

| Feature | CyberArk | WALLIX |
|---------|----------|--------|
| Vault HA | Primary/DR Vault | MariaDB replication |
| Session HA | PSM farm with LB | Active/Active cluster |
| Web HA | PVWA behind LB | Access Manager cluster |
| Failover Time | Minutes (DR activation) | Seconds (automatic) |
| Data Sync | Vault replication | Real-time sync |
| Geo-redundancy | DR Vault in remote site | Multi-site with sync |

**Key Differences:**
- WALLIX uses standard MariaDB clustering (proven, well-documented)
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
|         +-----------------+         +-----------------+                       |
|         |   Node 1        |         |   Node 2        |                       |
|         |   (ACTIVE)      |<------->|   (STANDBY)     |                       |
|         |                 |  Sync   |                 |                       |
|         |  * Running      |         |  o Ready        |                       |
|         |  * Serving      |         |  o Monitoring   |                       |
|         +--------+--------+         +-----------------+                       |
|                  |                                                            |
|            All traffic                                                        |
|                                                                               |
|  Pros: Simple, lower cost                                                     |
|  Cons: Failover time, idle standby                                            |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  ACTIVE/ACTIVE                                                                |
|  =============                                                                |
|                                                                               |
|                     +-----------------+                                       |
|                     |  Load Balancer  |                                       |
|                     +--------+--------+                                       |
|                              |                                                |
|              +---------------+---------------+                                |
|              |               |               |                                |
|              v               v               v                                |
|    +-----------------+ +-----------------+ +-----------------+                |
|    |   Node 1        | |   Node 2        | |   Node 3        |                |
|    |   (ACTIVE)      | |   (ACTIVE)      | |   (ACTIVE)      |                |
|    |  * Serving      | |  * Serving      | |  * Serving      |                |
|    +-----------------+ +-----------------+ +-----------------+                |
|              |               |               |                                |
|              +---------------+---------------+                                |
|                              |                                                |
|                    +---------+---------+                                      |
|                    |  Shared Storage   |                                      |
|                    |  + Database       |                                      |
|                    +-------------------+                                      |
|                                                                               |
|  Pros: No failover, load distribution, scalability                            |
|  Cons: More complex, requires shared storage                                  |
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
|                          +-----------------+                                  |
|                          |  Virtual IP     |                                  |
|                          |  (Floating)     |                                  |
|                          |  192.168.1.10   |                                  |
|                          +--------+--------+                                  |
|                                   |                                           |
|                  +----------------+----------------+                          |
|                  |                                 |                          |
|                  v                                 v                          |
|  +-------------------------------+ +-------------------------------+          |
|  |        NODE 1 (PRIMARY)       | |       NODE 2 (STANDBY)        |          |
|  |                               | |                               |          |
|  |  IP: 192.168.1.11             | |  IP: 192.168.1.12             |          |
|  |                               | |                               |          | 
|  |  +-------------------------+  | |  +-------------------------+  |          |
|  |  | WALLIX Bastion          |  | |  | WALLIX Bastion          |  |          |
|  |  | (Running)               |  | |  | (Standby)               |  |          |
|  |  +-------------------------+  | |  +-------------------------+  |          |
|  |                               | |                               |          |
|  |  +-------------------------+  | |  +-------------------------+  |          |
|  |  | MariaDB                 |  | |  | MariaDB                 |  |          |
|  |  | (Primary)               |<-+-+->| (Replica)               |  |          | 
|  |  +-------------------------+  | |  +-------------------------+  |          |
|  |                               | |     Streaming Replication     |          | 
|  +-------------------------------+ +-------------------------------+          |
|                  |                                 |                          |
|                  +----------------+----------------+                          |
|                                   |                                           |
|                          +--------+--------+                                  |
|                          | Shared Storage  |                                  |
|                          | (Recordings)    |                                  |
|                          | NFS/iSCSI       |                                  |
|                          +-----------------+                                  |
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
|     * Heartbeat failure detected                                              |
|     * Health check fails (3 consecutive)                                      |
|     * Service unresponsive                                                    |
|                                                                               |
|                    |                                                          |
|                    v                                                          |
|                                                                               |
|  2. VALIDATION                                                                |
|     -----------                                                               |
|     * Confirm primary is truly down (avoid split-brain)                       |
|     * STONITH/fencing if configured                                           |
|     * Quorum check (if 3+ nodes)                                              |
|                                                                               |
|                    |                                                          |
|                    v                                                          |
|                                                                               |
|  3. DATABASE PROMOTION                                                        |
|     ----------------------                                                    |
|     * Promote MariaDB replica to primary                                      |
|     * Ensure data consistency                                                 |
|     * Update connection strings                                               |
|                                                                               |
|                    |                                                          |
|                    v                                                          |
|                                                                               |
|  4. SERVICE ACTIVATION                                                        |
|     --------------------                                                      |
|     * Start WALLIX services on standby                                        |
|     * Verify service health                                                   |
|                                                                               |
|                    |                                                          |
|                    v                                                          |
|                                                                               |
|  5. VIP MIGRATION                                                             |
|     --------------                                                            |
|     * Move floating IP to new primary                                         |
|     * Update ARP tables                                                       |
|     * DNS update (if applicable)                                              |
|                                                                               |
|                    |                                                          |
|                    v                                                          |
|                                                                               |
|  6. NOTIFICATION                                                              |
|     ------------                                                              |
|     * Alert administrators                                                    |
|     * Log failover event                                                      |
|     * Update monitoring                                                       |
|                                                                               |
|  TYPICAL FAILOVER TIME: 30-120 seconds                                        |
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
|                          +---------------------+                              |
|                          |    Load Balancer    |                              |
|                          |    (F5 / HAProxy)   |                              |
|                          |                     |                              |
|                          |  VIP: 192.168.1.10  |                              |
|                          +----------+----------+                              |
|                                     |                                         |
|             +-----------------------+-----------------------+                 |
|             |                       |                       |                 |
|             v                       v                       v                 |
|  +------------------+   +------------------+   +------------------+           |
|  |    NODE 1        |   |    NODE 2        |   |    NODE 3        |           |
|  |                  |   |                  |   |                  |           |
|  | IP: 192.168.1.11 |   | IP: 192.168.1.12 |   | IP: 192.168.1.13 |           |
|  |                  |   |                  |   |                  |           |
|  | +--------------+ |   | +--------------+ |   | +--------------+ |           |
|  | |   WALLIX     | |   | |   WALLIX     | |   | |   WALLIX     | |           |
|  | |   Bastion    | |   | |   Bastion    | |   | |   Bastion    | |           |
|  | |   (Active)   | |   | |   (Active)   | |   | |   (Active)   | |           |
|  | +--------------+ |   | +--------------+ |   | +--------------+ |           |
|  +--------+---------+   +--------+---------+   +--------+---------+           |
|           |                      |                      |                     |
|           +----------------------+----------------------+                     |
|                                  |                                            |
|                    +-------------+-------------+                              |
|                    |                           |                              |
|                    v                           v                              |
|         +------------------+       +----------------------+                   |
|         |   MariaDB        |       |   Shared Storage     |                   |
|         |   Cluster        |       |   (NAS/SAN)          |                   |
|         |                  |       |                      |                   |
|         |  Primary + 2     |       |  /var/wab/recorded   |                   |
|         |  Replicas        |       |  /var/wab/shared     |                   |
|         +------------------+       +----------------------+                   |
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
|  # /etc/haproxy/haproxy.cfg                                                   |
|                                                                               |
|  frontend wallix_https                                                        |
|      bind *:443 ssl crt /etc/ssl/wallix.pem                                   |
|      mode http                                                                |
|      default_backend wallix_nodes                                             |
|                                                                               |
|  frontend wallix_ssh                                                          |
|      bind *:22                                                                |
|      mode tcp                                                                 |
|      default_backend wallix_ssh_nodes                                         |
|                                                                               |
|  frontend wallix_rdp                                                          |
|      bind *:3389                                                              |
|      mode tcp                                                                 |
|      default_backend wallix_rdp_nodes                                         |
|                                                                               |
|  backend wallix_nodes                                                         |
|      mode http                                                                |
|      balance roundrobin                                                       |
|      option httpchk GET /health                                               |
|      cookie SERVERID insert indirect nocache                                  |
|      server node1 192.168.1.11:443 ssl check cookie node1                     |
|      server node2 192.168.1.12:443 ssl check cookie node2                     |
|      server node3 192.168.1.13:443 ssl check cookie node3                     |
|                                                                               |
|  backend wallix_ssh_nodes                                                     |
|      mode tcp                                                                 |
|      balance source                                                           |
|      option tcp-check                                                         |
|      server node1 192.168.1.11:22 check                                       |
|      server node2 192.168.1.12:22 check                                       |
|      server node3 192.168.1.13:22 check                                       |
|                                                                               |
|  backend wallix_rdp_nodes                                                     |
|      mode tcp                                                                 |
|      balance source                                                           |
|      option tcp-check                                                         |
|      server node1 192.168.1.11:3389 check                                     |
|      server node2 192.168.1.12:3389 check                                     |
|      server node3 192.168.1.13:3389 check                                     |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  SESSION PERSISTENCE                                                          |
|  ===================                                                          |
|                                                                               |
|  Protocol     | Persistence Method    | Reason                                |
|  -------------+-----------------------+------------------------------------   |
|  HTTPS (UI)   | Cookie-based          | User session state                    |
|  SSH          | Source IP hash        | Session continuity                    |
|  RDP          | Source IP hash        | Session continuity                    |
|                                                                               |
+===============================================================================+
```

---

## Database High Availability

### MariaDB Replication

```
+===============================================================================+
|                    MARIADB HA CONFIGURATION                                   |
+===============================================================================+
|                                                                               |
|  STREAMING REPLICATION                                                        |
|  =====================                                                        |
|                                                                               |
|         +---------------------+                                               |
|         |   PRIMARY           |                                               |
|         |   MariaDB           |                                               |
|         |                     |                                               |
|         |   Writes + Reads    |                                               |
|         +----------+----------+                                               |
|                    |                                                          |
|         +----------+----------+                                               |
|         |   WAL Streaming     |                                               |
|         |                     |                                               |
|         v                     v                                               |
|  +-----------------+   +-----------------+                                    |
|  |   REPLICA 1     |   |   REPLICA 2     |                                    |
|  |   (Sync)        |   |   (Async)       |                                    |
|  |                 |   |                 |                                    |
|  |   Reads only    |   |   Reads only    |                                    |
|  +-----------------+   +-----------------+                                    |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  MAXSCALE/GALERA CLUSTER MANAGEMENT                                           |
|  ==================================                                           |
|                                                                               |
|  MaxScale/Galera provides:                                                    |
|  * Automatic leader election                                                  |
|  * Automatic failover                                                         |
|  * REST API for management                                                    |
|  * Integration with etcd/Consul/ZooKeeper                                     |
|                                                                               |
|  # maxscale.cnf                                                               |
|  scope: wallix-cluster                                                        |
|  name: node1                                                                  |
|                                                                               |
|  restapi:                                                                     |
|    listen: 0.0.0.0:8008                                                       |
|    connect_address: 192.168.1.11:8008                                         |
|                                                                               |
|  etcd:                                                                        |
|    hosts:                                                                     |
|      - 192.168.1.21:2379                                                      |
|      - 192.168.1.22:2379                                                      |
|      - 192.168.1.23:2379                                                      |
|                                                                               |
|  bootstrap:                                                                   |
|    dcs:                                                                       |
|      synchronous_mode: true                                                   |
|      mariadb:                                                                 |
|        parameters:                                                            |
|          max_connections: 200                                                 |
|          synchronous_commit: on                                               |
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
|     SITE A (PRIMARY)                         SITE B (DR)                      |
|     ================                         ==========                       |
|                                                                               |
|  +--------------------------+     +--------------------------+                |
|  |                          |     |                          |                |
|  |  +--------------------+  |     |  +--------------------+  |                |
|  |  |  WALLIX Cluster    |  |     |  |  WALLIX Cluster    |  |                |
|  |  |  (Active)          |  |     |  |  (Standby)         |  |                |
|  |  |                    |  |     |  |                    |  |                |
|  |  |  Node1  Node2      |  |     |  |  Node1  Node2      |  |                |
|  |  +---------+----------+  |     |  +---------+----------+  |                |
|  |            |             |     |            |             |                |
|  |  +---------+----------+  |     |  +---------+----------+  |                |
|  |  |  MariaDB           |<-+-----+->|  MariaDB           |  |                |
|  |  |  (Primary)         |  |     |  |  (Replica)         |  |                |
|  |  +--------------------+  |     |  +--------------------+  |                |
|  |                          |     |      Async Replication   |                |
|  |  +--------------------+  |     |  +--------------------+  |                |
|  |  |  Recording Storage |<-+-----+->|  Recording Storage |  |                |
|  |  |  (Primary)         |  |     |  |  (Replica)         |  |                |
|  |  +--------------------+  |     |  +--------------------+  |                |
|  |                          |     |      rsync/replication   |                |
|  +--------------------------+     +--------------------------+                |
|                                                                               |
|                          +-----------------+                                  |
|                          |  Global DNS /   |                                  |
|                          |  GSLB           |                                  |
|                          |                 |                                  |
|                          |  bastion.co.com |                                  |
|                          +-----------------+                                  |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  DR METRICS                                                                   |
|  ==========                                                                   |
|                                                                               |
|  +-------------------+---------------------------------------------------+    |
|  | Metric            | Target                                            |    |
|  +-------------------+---------------------------------------------------+    |
|  | RPO               | < 5 minutes (async replication lag)               |    |
|  | RTO               | < 30 minutes (manual failover)                    |    |
|  |                   | < 5 minutes (automated failover)                  |    |
|  | Replication Lag   | < 1 minute under normal conditions                |    |
|  +-------------------+---------------------------------------------------+    |
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
|  [ ] Confirm primary site is unavailable                                      |
|  [ ] Estimate recovery time for primary                                       |
|  [ ] Decision: Failover or wait?                                              |
|                                                                               |
|  STEP 2: PREPARE DR SITE                                                      |
|  =======================                                                      |
|                                                                               |
|  [ ] Check replication status                                                 |
|  [ ] Verify data consistency                                                  |
|  [ ] Confirm DR site resources are ready                                      |
|                                                                               |
|  STEP 3: PROMOTE DR SITE                                                      |
|  ======================                                                       |
|                                                                               |
|  [ ] Promote MariaDB replica to primary                                       |
|     $ mariadb-admin failover wallix-cluster                                   |
|                                                                               |
|  [ ] Start WALLIX Bastion services                                            |
|     $ systemctl start wabengine                                               |
|                                                                               |
|  [ ] Verify services are running                                              |
|     $ systemctl status wab*                                                   |
|                                                                               |
|  STEP 4: UPDATE DNS/ROUTING                                                   |
|  ========================                                                     |
|                                                                               |
|  [ ] Update DNS records to point to DR site                                   |
|  [ ] Or update GSLB health checks                                             |
|  [ ] Clear DNS caches if needed                                               |
|                                                                               |
|  STEP 5: VERIFY                                                               |
|  =============                                                                |
|                                                                               |
|  [ ] Test user authentication                                                 |
|  [ ] Test session establishment                                               |
|  [ ] Verify recording functionality                                           |
|  [ ] Check password rotation                                                  |
|                                                                               |
|  STEP 6: NOTIFY                                                               |
|  =============                                                                |
|                                                                               |
|  [ ] Notify stakeholders of failover                                          |
|  [ ] Document incident timeline                                               |
|  [ ] Plan failback when primary recovers                                      |
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
|  +---------------------+-----------------+-----------------+---------------+  |
|  | Component           | Method          | Frequency       | Retention     |  |
|  +---------------------+-----------------+-----------------+---------------+  |
|  | MariaDB Database    | mysqldump/mariabackup | Daily     | 30 days       |  |
|  | Configuration Files | File backup     | Daily + changes | 90 days       |  |
|  | Encryption Keys     | Secure export   | On change       | Indefinite    |  | 
|  | Session Recordings  | Rsync/snapshot  | Continuous      | Per policy    |  |
|  | SSL Certificates    | File backup     | On change       | Indefinite    |  |
|  +---------------------+-----------------+-----------------+---------------+  |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  BACKUP SCRIPT EXAMPLE                                                        |
|  =====================                                                        |
|                                                                               |
|  #!/bin/bash                                                                  |
|  # WALLIX Bastion Backup Script                                               |
|                                                                               |
|  BACKUP_DIR="/backup/wallix/$(date +%Y%m%d)"                                  |
|  mkdir -p $BACKUP_DIR                                                         |
|                                                                               |
|  # Database backup                                                            |
|  mysqldump -u wabadmin wabdb > $BACKUP_DIR/database.sql                       |
|                                                                               |
|  # Configuration backup                                                       |
|  tar -czf $BACKUP_DIR/config.tar.gz /etc/opt/wab/                             |
|                                                                               |
|  # Keys backup (encrypted)                                                    |
|  tar -czf - /var/opt/wab/keys/ | \                                            |
|    openssl enc -aes-256-cbc -salt -out $BACKUP_DIR/keys.tar.gz.enc            |
|                                                                               |
|  # Certificates backup                                                        |
|  tar -czf $BACKUP_DIR/certs.tar.gz /etc/ssl/wallix/                           |
|                                                                               |
|  # Verify backups                                                             |
|  sha256sum $BACKUP_DIR/* > $BACKUP_DIR/checksums.sha256                       |
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
|  1. Install fresh WALLIX Bastion                                              |
|                                                                               |
|  2. Stop services                                                             |
|     $ systemctl stop wab*                                                     |
|                                                                               |
|  3. Restore database                                                          |
|     $ mysql -u wabadmin wabdb < /backup/database.sql                          |
|                                                                               |
|  4. Restore configuration                                                     |
|     $ tar -xzf /backup/config.tar.gz -C /                                     |
|                                                                               |
|  5. Restore encryption keys                                                   |
|     $ openssl enc -d -aes-256-cbc -in /backup/keys.tar.gz.enc | \             |
|       tar -xzf - -C /                                                         |
|                                                                               |
|  6. Restore certificates                                                      |
|     $ tar -xzf /backup/certs.tar.gz -C /                                      |
|                                                                               |
|  7. Set permissions                                                           |
|     $ chown -R wabadmin:wabadmin /var/opt/wab/                                |
|                                                                               |
|  8. Start services                                                            |
|     $ systemctl start wab*                                                    |
|                                                                               |
|  9. Verify functionality                                                      |
|     $ wabcheck --full                                                         |
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
|      "node": "bastion-node1",                                                 |
|      "cluster_role": "primary",                                               |
|      "components": {                                                          |
|          "database": "healthy",                                               |
|          "session_manager": "healthy",                                        |
|          "password_manager": "healthy",                                       |
|          "recording_storage": "healthy"                                       |
|      },                                                                       |
|      "cluster": {                                                             |
|          "nodes": 2,                                                          |
|          "healthy_nodes": 2,                                                  |
|          "replication_lag_seconds": 0                                         |
|      }                                                                        |
|  }                                                                            |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|                                                                               |
|  MONITORING METRICS                                                           |
|  =================                                                            |
|                                                                               |
|  Cluster Health:                                                              |
|  * Node status (up/down)                                                      |
|  * Cluster role (primary/standby)                                             |
|  * Replication lag                                                            |
|  * Split-brain detection                                                      |
|                                                                               |
|  Service Health:                                                              |
|  * Service response time                                                      |
|  * Active sessions count                                                      |
|  * Authentication success rate                                                |
|  * Recording storage capacity                                                 |
|                                                                               |
|  Database Health:                                                             |
|  * Connection pool utilization                                                |
|  * Query response time                                                        |
|  * Replication status                                                         |
|  * Disk space                                                                 |
|                                                                               |
+===============================================================================+
```

---

## API Client Failover Best Practices

### Python HA Client Class

```python
import requests
import logging
import time
from typing import Optional, List, Dict, Any
from enum import Enum
from datetime import datetime, timedelta

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class NodeState(Enum):
    """Circuit breaker states for HA nodes"""
    HEALTHY = "healthy"
    DEGRADED = "degraded"
    FAILED = "failed"


class WallixHAClient:
    """
    High Availability client for WALLIX Bastion API

    Features:
    - Automatic failover between multiple nodes
    - Health checking before requests
    - Retry strategy with exponential backoff
    - Circuit breaker pattern
    - Connection pooling
    - Comprehensive error handling
    """

    def __init__(
        self,
        nodes: List[str],
        username: str,
        password: str,
        verify_ssl: bool = True,
        timeout: int = 10,
        max_retries: int = 3,
        retry_backoff: float = 1.0,
        health_check_interval: int = 60,
        circuit_breaker_threshold: int = 3,
        circuit_breaker_timeout: int = 60
    ):
        """
        Initialize HA client

        Args:
            nodes: List of WALLIX Bastion node URLs
                   (e.g., ['https://node1.example.com', 'https://node2.example.com'])
            username: API username
            password: API password
            verify_ssl: Verify SSL certificates
            timeout: Request timeout in seconds
            max_retries: Maximum retry attempts per request
            retry_backoff: Base backoff time for exponential backoff (seconds)
            health_check_interval: Seconds between health checks
            circuit_breaker_threshold: Failures before opening circuit
            circuit_breaker_timeout: Seconds before attempting circuit reset
        """
        self.nodes = nodes
        self.username = username
        self.password = password
        self.verify_ssl = verify_ssl
        self.timeout = timeout
        self.max_retries = max_retries
        self.retry_backoff = retry_backoff
        self.health_check_interval = health_check_interval
        self.circuit_breaker_threshold = circuit_breaker_threshold
        self.circuit_breaker_timeout = circuit_breaker_timeout

        # Node state tracking
        self.node_states: Dict[str, NodeState] = {
            node: NodeState.HEALTHY for node in nodes
        }
        self.node_failures: Dict[str, int] = {
            node: 0 for node in nodes
        }
        self.node_last_check: Dict[str, datetime] = {}
        self.node_circuit_opened: Dict[str, Optional[datetime]] = {
            node: None for node in nodes
        }

        # Session with connection pooling
        self.session = requests.Session()
        self.session.verify = verify_ssl

        # Adapter for connection pooling
        adapter = requests.adapters.HTTPAdapter(
            pool_connections=10,
            pool_maxsize=20,
            max_retries=0  # We handle retries manually
        )
        self.session.mount('http://', adapter)
        self.session.mount('https://', adapter)

        # Current active node index
        self.current_node_index = 0

        logger.info(f"Initialized HA client with {len(nodes)} nodes")

    def _get_healthy_node(self) -> Optional[str]:
        """
        Get next healthy node using round-robin with health checks

        Returns:
            URL of healthy node or None if all nodes are down
        """
        attempts = 0
        while attempts < len(self.nodes):
            node = self.nodes[self.current_node_index]

            # Check circuit breaker
            if self._check_circuit_breaker(node):
                # Check health
                if self._check_node_health(node):
                    logger.debug(f"Selected healthy node: {node}")
                    return node
                else:
                    logger.warning(f"Node {node} failed health check")
            else:
                logger.warning(f"Node {node} circuit breaker is open")

            # Move to next node
            self.current_node_index = (self.current_node_index + 1) % len(self.nodes)
            attempts += 1

        logger.error("All nodes are unhealthy or circuit breakers are open")
        return None

    def _check_circuit_breaker(self, node: str) -> bool:
        """
        Check if circuit breaker allows requests to this node

        Args:
            node: Node URL

        Returns:
            True if requests are allowed, False if circuit is open
        """
        circuit_opened = self.node_circuit_opened.get(node)

        if circuit_opened is None:
            return True  # Circuit is closed

        # Check if timeout has passed
        if datetime.now() - circuit_opened > timedelta(seconds=self.circuit_breaker_timeout):
            logger.info(f"Circuit breaker timeout expired for {node}, attempting reset")
            self.node_circuit_opened[node] = None
            self.node_failures[node] = 0
            self.node_states[node] = NodeState.DEGRADED
            return True

        return False  # Circuit still open

    def _open_circuit_breaker(self, node: str):
        """Open circuit breaker for a node"""
        logger.error(f"Opening circuit breaker for {node}")
        self.node_circuit_opened[node] = datetime.now()
        self.node_states[node] = NodeState.FAILED

    def _record_failure(self, node: str):
        """Record a failure for a node and potentially open circuit breaker"""
        self.node_failures[node] += 1
        logger.warning(f"Node {node} failure count: {self.node_failures[node]}")

        if self.node_failures[node] >= self.circuit_breaker_threshold:
            self._open_circuit_breaker(node)

    def _record_success(self, node: str):
        """Record a successful request to a node"""
        self.node_failures[node] = 0
        self.node_states[node] = NodeState.HEALTHY
        self.node_circuit_opened[node] = None

    def _check_node_health(self, node: str) -> bool:
        """
        Check if a node is healthy using health endpoint

        Args:
            node: Node URL

        Returns:
            True if healthy, False otherwise
        """
        # Check if we've checked recently
        last_check = self.node_last_check.get(node)
        if last_check:
            if datetime.now() - last_check < timedelta(seconds=self.health_check_interval):
                # Use cached state
                return self.node_states[node] != NodeState.FAILED

        # Perform health check
        try:
            response = self.session.get(
                f"{node}/api/health",
                timeout=5,
                verify=self.verify_ssl
            )

            self.node_last_check[node] = datetime.now()

            if response.status_code == 200:
                data = response.json()
                if data.get('status') == 'healthy':
                    self._record_success(node)
                    logger.debug(f"Health check passed for {node}")
                    return True
                else:
                    logger.warning(f"Health check degraded for {node}: {data}")
                    self.node_states[node] = NodeState.DEGRADED
                    return True  # Still usable, just degraded
            else:
                logger.warning(f"Health check failed for {node}: HTTP {response.status_code}")
                self._record_failure(node)
                return False

        except Exception as e:
            logger.error(f"Health check error for {node}: {e}")
            self._record_failure(node)
            return False

    def _authenticate(self, node: str) -> Optional[str]:
        """
        Authenticate to a node and get API token

        Args:
            node: Node URL

        Returns:
            API token or None on failure
        """
        try:
            response = self.session.post(
                f"{node}/api/auth/login",
                json={
                    "user": self.username,
                    "password": self.password
                },
                timeout=self.timeout
            )

            if response.status_code == 200:
                token = response.json().get('token')
                logger.info(f"Successfully authenticated to {node}")
                return token
            else:
                logger.error(f"Authentication failed: HTTP {response.status_code}")
                return None

        except Exception as e:
            logger.error(f"Authentication error: {e}")
            return None

    def request(
        self,
        method: str,
        endpoint: str,
        data: Optional[Dict[str, Any]] = None,
        params: Optional[Dict[str, Any]] = None
    ) -> Optional[requests.Response]:
        """
        Make an API request with automatic failover and retry

        Args:
            method: HTTP method (GET, POST, PUT, DELETE, etc.)
            endpoint: API endpoint (e.g., '/api/users')
            data: Request body data (for POST/PUT)
            params: Query parameters

        Returns:
            Response object or None on failure
        """
        for attempt in range(self.max_retries):
            # Get healthy node
            node = self._get_healthy_node()
            if not node:
                logger.error("No healthy nodes available")
                if attempt < self.max_retries - 1:
                    backoff = self.retry_backoff * (2 ** attempt)
                    logger.info(f"Retrying in {backoff} seconds...")
                    time.sleep(backoff)
                    continue
                return None

            # Authenticate
            token = self._authenticate(node)
            if not token:
                self._record_failure(node)
                if attempt < self.max_retries - 1:
                    backoff = self.retry_backoff * (2 ** attempt)
                    logger.info(f"Authentication failed, retrying in {backoff} seconds...")
                    time.sleep(backoff)
                    continue
                return None

            # Make request
            try:
                headers = {
                    'Authorization': f'Bearer {token}',
                    'Content-Type': 'application/json'
                }

                url = f"{node}{endpoint}"

                response = self.session.request(
                    method=method,
                    url=url,
                    json=data,
                    params=params,
                    headers=headers,
                    timeout=self.timeout
                )

                # Success
                if response.status_code < 500:
                    self._record_success(node)
                    return response
                else:
                    # Server error, try another node
                    logger.error(f"Server error from {node}: HTTP {response.status_code}")
                    self._record_failure(node)

            except requests.exceptions.ConnectionError as e:
                logger.error(f"Connection error to {node}: {e}")
                self._record_failure(node)
            except requests.exceptions.Timeout as e:
                logger.error(f"Timeout connecting to {node}: {e}")
                self._record_failure(node)
            except Exception as e:
                logger.error(f"Unexpected error with {node}: {e}")
                self._record_failure(node)

            # Exponential backoff before retry
            if attempt < self.max_retries - 1:
                backoff = self.retry_backoff * (2 ** attempt)
                logger.info(f"Retrying in {backoff} seconds (attempt {attempt + 1}/{self.max_retries})")
                time.sleep(backoff)

        logger.error("All retry attempts exhausted")
        return None

    def get(self, endpoint: str, params: Optional[Dict[str, Any]] = None) -> Optional[requests.Response]:
        """GET request wrapper"""
        return self.request('GET', endpoint, params=params)

    def post(self, endpoint: str, data: Optional[Dict[str, Any]] = None) -> Optional[requests.Response]:
        """POST request wrapper"""
        return self.request('POST', endpoint, data=data)

    def put(self, endpoint: str, data: Optional[Dict[str, Any]] = None) -> Optional[requests.Response]:
        """PUT request wrapper"""
        return self.request('PUT', endpoint, data=data)

    def delete(self, endpoint: str) -> Optional[requests.Response]:
        """DELETE request wrapper"""
        return self.request('DELETE', endpoint)

    def get_cluster_status(self) -> Dict[str, Any]:
        """Get status of all nodes in the cluster"""
        status = {
            'nodes': [],
            'healthy_count': 0,
            'total_count': len(self.nodes)
        }

        for node in self.nodes:
            node_status = {
                'url': node,
                'state': self.node_states[node].value,
                'failures': self.node_failures[node],
                'circuit_breaker_open': self.node_circuit_opened[node] is not None
            }
            status['nodes'].append(node_status)

            if self.node_states[node] == NodeState.HEALTHY:
                status['healthy_count'] += 1

        return status

    def close(self):
        """Close the session and clean up resources"""
        self.session.close()
        logger.info("HA client closed")


# Usage Example
if __name__ == "__main__":
    # Initialize HA client with multiple nodes
    client = WallixHAClient(
        nodes=[
            'https://bastion-node1.example.com',
            'https://bastion-node2.example.com',
            'https://bastion-node3.example.com'
        ],
        username='api_user',
        password='secure_password',
        verify_ssl=True,
        max_retries=3,
        retry_backoff=2.0,
        health_check_interval=60,
        circuit_breaker_threshold=3,
        circuit_breaker_timeout=60
    )

    try:
        # Make API requests - automatic failover and retry
        response = client.get('/api/users')
        if response and response.status_code == 200:
            users = response.json()
            print(f"Retrieved {len(users)} users")

        # Create a new user
        new_user = {
            'user_name': 'john.doe',
            'email': 'john.doe@example.com',
            'profile': 'user'
        }
        response = client.post('/api/users', data=new_user)
        if response and response.status_code == 201:
            print("User created successfully")

        # Check cluster status
        cluster_status = client.get_cluster_status()
        print(f"Cluster status: {cluster_status['healthy_count']}/{cluster_status['total_count']} nodes healthy")

    finally:
        client.close()
```

### Retry Strategy Implementation

```python
import time
import random
from functools import wraps


def simple_retry(max_attempts=3, delay=1.0):
    """
    Simple retry decorator with fixed delay

    Args:
        max_attempts: Maximum number of retry attempts
        delay: Fixed delay between retries in seconds
    """
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            for attempt in range(max_attempts):
                try:
                    return func(*args, **kwargs)
                except Exception as e:
                    if attempt == max_attempts - 1:
                        raise
                    logger.warning(f"Attempt {attempt + 1} failed: {e}. Retrying in {delay}s...")
                    time.sleep(delay)
        return wrapper
    return decorator


def exponential_backoff_retry(max_attempts=5, base_delay=1.0, max_delay=60.0, jitter=True):
    """
    Exponential backoff retry decorator

    Args:
        max_attempts: Maximum number of retry attempts
        base_delay: Base delay for exponential backoff
        max_delay: Maximum delay between retries
        jitter: Add random jitter to prevent thundering herd
    """
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            for attempt in range(max_attempts):
                try:
                    return func(*args, **kwargs)
                except Exception as e:
                    if attempt == max_attempts - 1:
                        raise

                    # Calculate exponential backoff
                    delay = min(base_delay * (2 ** attempt), max_delay)

                    # Add jitter (random value between 0 and delay)
                    if jitter:
                        delay = delay * (0.5 + random.random() / 2)

                    logger.warning(
                        f"Attempt {attempt + 1}/{max_attempts} failed: {e}. "
                        f"Retrying in {delay:.2f}s..."
                    )
                    time.sleep(delay)
        return wrapper
    return decorator


def circuit_breaker_retry(failure_threshold=3, recovery_timeout=60, expected_exception=Exception):
    """
    Circuit breaker pattern implementation

    Args:
        failure_threshold: Number of failures before opening circuit
        recovery_timeout: Seconds before attempting to close circuit
        expected_exception: Exception type to catch
    """
    def decorator(func):
        func.failure_count = 0
        func.last_failure_time = None
        func.circuit_open = False

        @wraps(func)
        def wrapper(*args, **kwargs):
            # Check if circuit is open
            if func.circuit_open:
                if func.last_failure_time:
                    time_since_failure = time.time() - func.last_failure_time
                    if time_since_failure >= recovery_timeout:
                        logger.info("Circuit breaker timeout expired, attempting reset")
                        func.circuit_open = False
                        func.failure_count = 0
                    else:
                        raise Exception(
                            f"Circuit breaker is OPEN. Retry in "
                            f"{recovery_timeout - time_since_failure:.0f}s"
                        )

            try:
                result = func(*args, **kwargs)
                # Success - reset failure count
                func.failure_count = 0
                func.circuit_open = False
                return result

            except expected_exception as e:
                func.failure_count += 1
                func.last_failure_time = time.time()

                logger.error(f"Function failed: {e} (failure count: {func.failure_count})")

                if func.failure_count >= failure_threshold:
                    func.circuit_open = True
                    logger.error(f"Circuit breaker OPENED after {failure_threshold} failures")

                raise

        return wrapper
    return decorator


# Usage Examples
@simple_retry(max_attempts=3, delay=2.0)
def fetch_with_simple_retry(url):
    response = requests.get(url, timeout=5)
    response.raise_for_status()
    return response.json()


@exponential_backoff_retry(max_attempts=5, base_delay=1.0, max_delay=30.0)
def fetch_with_exponential_backoff(url):
    response = requests.get(url, timeout=5)
    response.raise_for_status()
    return response.json()


@circuit_breaker_retry(failure_threshold=3, recovery_timeout=60)
def fetch_with_circuit_breaker(url):
    response = requests.get(url, timeout=5)
    response.raise_for_status()
    return response.json()
```

### Health Check Endpoint Integration

```python
import requests
from datetime import datetime, timedelta
from typing import Optional, Dict


class HealthAwareClient:
    """
    API client with health check integration
    """

    def __init__(self, base_url: str, health_check_ttl: int = 30):
        """
        Args:
            base_url: Base URL of WALLIX Bastion node
            health_check_ttl: Seconds to cache health check result
        """
        self.base_url = base_url
        self.health_check_ttl = health_check_ttl
        self.session = requests.Session()

        # Health check cache
        self._health_status: Optional[Dict] = None
        self._health_checked_at: Optional[datetime] = None

    def check_health(self, force: bool = False) -> bool:
        """
        Check if node is healthy using /api/health endpoint

        Args:
            force: Force health check even if cached result is valid

        Returns:
            True if healthy, False otherwise
        """
        # Check cache
        if not force and self._health_status and self._health_checked_at:
            age = (datetime.now() - self._health_checked_at).total_seconds()
            if age < self.health_check_ttl:
                return self._health_status.get('status') == 'healthy'

        # Perform health check
        try:
            response = self.session.get(
                f"{self.base_url}/api/health",
                timeout=5
            )

            if response.status_code == 200:
                self._health_status = response.json()
                self._health_checked_at = datetime.now()

                status = self._health_status.get('status')

                # Log component health
                components = self._health_status.get('components', {})
                unhealthy = [k for k, v in components.items() if v != 'healthy']

                if unhealthy:
                    logger.warning(f"Unhealthy components: {', '.join(unhealthy)}")

                return status == 'healthy'
            else:
                logger.error(f"Health check failed: HTTP {response.status_code}")
                return False

        except Exception as e:
            logger.error(f"Health check error: {e}")
            return False

    def request_with_health_check(self, method: str, endpoint: str, **kwargs):
        """
        Make a request with health check before execution

        Args:
            method: HTTP method
            endpoint: API endpoint
            **kwargs: Additional arguments for requests

        Returns:
            Response object
        """
        # Check health before request
        if not self.check_health():
            raise Exception("Node is unhealthy, request aborted")

        # Make request
        url = f"{self.base_url}{endpoint}"
        response = self.session.request(method, url, **kwargs)

        return response

    def get_health_status(self) -> Optional[Dict]:
        """Get detailed health status"""
        self.check_health(force=True)
        return self._health_status


# Usage Example
client = HealthAwareClient('https://bastion-node1.example.com')

# Check health before operations
if client.check_health():
    response = client.request_with_health_check('GET', '/api/users')
    print(f"Retrieved {len(response.json())} users")
else:
    print("Node is unhealthy, skipping operation")

# Get detailed health status
health = client.get_health_status()
print(f"Node health: {health}")
```

### Multi-Node Load Balancing

```python
import random
from typing import List, Optional
from collections import defaultdict
import threading


class LoadBalancedClient:
    """
    Client with multiple load balancing strategies
    """

    def __init__(self, nodes: List[str]):
        self.nodes = nodes
        self.current_index = 0
        self.lock = threading.Lock()

        # Connection tracking for least-connections
        self.active_connections = defaultdict(int)

    def round_robin(self) -> str:
        """
        Round-robin node selection

        Returns:
            Next node URL in round-robin order
        """
        with self.lock:
            node = self.nodes[self.current_index]
            self.current_index = (self.current_index + 1) % len(self.nodes)
            return node

    def random_selection(self) -> str:
        """
        Random node selection

        Returns:
            Randomly selected node URL
        """
        return random.choice(self.nodes)

    def least_connections(self) -> str:
        """
        Least connections node selection

        Returns:
            Node with fewest active connections
        """
        with self.lock:
            # Find node with minimum connections
            min_connections = min(
                self.active_connections.get(node, 0)
                for node in self.nodes
            )

            # Get all nodes with minimum connections
            candidates = [
                node for node in self.nodes
                if self.active_connections.get(node, 0) == min_connections
            ]

            # Random selection among candidates
            return random.choice(candidates)

    def health_aware_selection(
        self,
        health_checker: callable
    ) -> Optional[str]:
        """
        Health-aware node selection

        Args:
            health_checker: Function that checks if a node is healthy

        Returns:
            Healthy node URL or None if all unhealthy
        """
        # Shuffle nodes for randomness
        shuffled_nodes = self.nodes.copy()
        random.shuffle(shuffled_nodes)

        for node in shuffled_nodes:
            if health_checker(node):
                return node

        return None

    def weighted_selection(self, weights: Dict[str, int]) -> str:
        """
        Weighted random selection

        Args:
            weights: Dictionary mapping node URL to weight (higher = more likely)

        Returns:
            Selected node URL
        """
        total_weight = sum(weights.get(node, 1) for node in self.nodes)
        random_weight = random.uniform(0, total_weight)

        cumulative_weight = 0
        for node in self.nodes:
            cumulative_weight += weights.get(node, 1)
            if random_weight <= cumulative_weight:
                return node

        return self.nodes[-1]  # Fallback


# Usage Example
lb_client = LoadBalancedClient([
    'https://bastion-node1.example.com',
    'https://bastion-node2.example.com',
    'https://bastion-node3.example.com'
])

# Round-robin selection
for i in range(5):
    node = lb_client.round_robin()
    print(f"Request {i+1}: {node}")

# Least connections selection
node = lb_client.least_connections()
lb_client.active_connections[node] += 1  # Track connection
# ... make request ...
lb_client.active_connections[node] -= 1  # Release connection

# Health-aware selection
def check_health(node_url):
    try:
        response = requests.get(f"{node_url}/api/health", timeout=5)
        return response.status_code == 200
    except:
        return False

healthy_node = lb_client.health_aware_selection(check_health)
if healthy_node:
    print(f"Using healthy node: {healthy_node}")

# Weighted selection (e.g., more powerful nodes get higher weight)
weights = {
    'https://bastion-node1.example.com': 3,  # 3x capacity
    'https://bastion-node2.example.com': 2,  # 2x capacity
    'https://bastion-node3.example.com': 1   # 1x capacity
}
node = lb_client.weighted_selection(weights)
print(f"Weighted selection: {node}")
```

### Complete Integration Example

```python
"""
Production-ready WALLIX Bastion HA client with all best practices
"""

# Combine all patterns into a single production client
class ProductionHAClient(WallixHAClient):
    """
    Production HA client with load balancing and monitoring
    """

    def __init__(self, *args, load_balancing_strategy='health_aware', **kwargs):
        super().__init__(*args, **kwargs)
        self.load_balancing_strategy = load_balancing_strategy
        self.lb_client = LoadBalancedClient(self.nodes)

        # Metrics
        self.request_count = defaultdict(int)
        self.error_count = defaultdict(int)
        self.total_requests = 0

    def _select_node_with_strategy(self) -> Optional[str]:
        """Select node using configured load balancing strategy"""
        if self.load_balancing_strategy == 'round_robin':
            return self.lb_client.round_robin()
        elif self.load_balancing_strategy == 'least_connections':
            return self.lb_client.least_connections()
        elif self.load_balancing_strategy == 'health_aware':
            return self.lb_client.health_aware_selection(self._check_node_health)
        else:
            return self._get_healthy_node()

    def get_metrics(self) -> Dict[str, Any]:
        """Get client metrics"""
        return {
            'total_requests': self.total_requests,
            'requests_per_node': dict(self.request_count),
            'errors_per_node': dict(self.error_count),
            'cluster_status': self.get_cluster_status()
        }


# Production usage
if __name__ == "__main__":
    client = ProductionHAClient(
        nodes=[
            'https://bastion-node1.example.com',
            'https://bastion-node2.example.com'
        ],
        username='api_admin',
        password='secure_password',
        verify_ssl=True,
        max_retries=3,
        retry_backoff=2.0,
        health_check_interval=30,
        circuit_breaker_threshold=5,
        circuit_breaker_timeout=120,
        load_balancing_strategy='health_aware'
    )

    try:
        # Make requests with automatic HA
        response = client.get('/api/users')
        if response:
            print(f"Success: {response.status_code}")

        # Monitor metrics
        metrics = client.get_metrics()
        print(f"Metrics: {metrics}")

    finally:
        client.close()
```

### Best Practices Summary

```
+===============================================================================+
|                  API CLIENT FAILOVER BEST PRACTICES                           |
+===============================================================================+
|                                                                               |
|  1. HEALTH CHECKING                                                           |
|     ================                                                          |
|     * Check /api/health before requests                                       |
|     * Cache health status with TTL (30-60 seconds)                            |
|     * Failover immediately on unhealthy response                              |
|                                                                               |
|  2. RETRY STRATEGY                                                            |
|     ===============                                                           |
|     * Use exponential backoff (start: 1s, max: 60s)                           |
|     * Add jitter to prevent thundering herd                                   |
|     * Maximum 3-5 retry attempts                                              |
|     * Retry on: ConnectionError, Timeout, HTTP 5xx                            |
|     * Do NOT retry on: HTTP 4xx (client errors)                               |
|                                                                               |
|  3. CIRCUIT BREAKER                                                           |
|     ================                                                          |
|     * Open circuit after 3-5 consecutive failures                             |
|     * Keep circuit open for 60-120 seconds                                    |
|     * Attempt reset after timeout (half-open state)                           |
|     * Track failures per node independently                                   |
|                                                                               |
|  4. CONNECTION POOLING                                                        |
|     ===================                                                       |
|     * Reuse HTTP connections (requests.Session)                               |
|     * Pool size: 10-20 connections per node                                   |
|     * Connection timeout: 10 seconds                                          |
|     * Read timeout: 30 seconds                                                |
|                                                                               |
|  5. LOAD BALANCING                                                            |
|     ===============                                                           |
|     * Health-aware selection (preferred)                                      |
|     * Round-robin for even distribution                                       |
|     * Least-connections for varying request durations                         |
|     * Weighted for heterogeneous node capacity                                |
|                                                                               |
|  6. ERROR HANDLING                                                            |
|     ===============                                                           |
|     * Log all failures with node information                                  |
|     * Distinguish transient vs permanent errors                               |
|     * Implement graceful degradation                                          |
|     * Return meaningful error messages to callers                             |
|                                                                               |
|  7. MONITORING                                                                |
|     ===========                                                               |
|     * Track requests per node                                                 |
|     * Track errors per node                                                   |
|     * Monitor circuit breaker state                                           |
|     * Alert on all nodes unhealthy                                            |
|     * Log failover events                                                     |
|                                                                               |
+===============================================================================+
```

---

## See Also

**Related Sections:**
- [29 - Disaster Recovery](../29-disaster-recovery/README.md) - DR runbooks and procedures
- [30 - Backup & Restore](../30-backup-restore/README.md) - Backup strategies
- [32 - Load Balancer](../32-load-balancer/README.md) - HAProxy and load balancing

**Related Documentation:**
- [Install Guide](/install/HOWTO.md) - HA cluster deployment
- [Install: Architecture](/install/09-architecture-diagrams.md) - HA architecture diagrams

**Official Resources:**
- [WALLIX Documentation](https://pam.wallix.one/documentation)

---

## Next Steps

Continue to [11 - Monitoring & Observability](../12-monitoring-observability/README.md) for Prometheus, Grafana, and alerting configuration.
