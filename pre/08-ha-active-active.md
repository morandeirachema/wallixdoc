# 04 - HA Active-Active Configuration

## Configuring Two-Node Active-Active Cluster

This guide covers setting up WALLIX Bastion in Active-Active high availability mode where both nodes handle traffic simultaneously.

---

## Active-Active Architecture

```
+===============================================================================+
|                         ACTIVE-ACTIVE CLUSTER                                 |
+===============================================================================+

                            Users / Clients
                                   |
                        +----------+----------+
                        |                     |
                        |   LOAD BALANCER     |
                        |   or DNS Round      |
                        |   Robin             |
                        |                     |
                        +----------+----------+
                                   |
                  +----------------+----------------+
                  |                                 |
                  v                                 v
         +------------------+            +------------------+
         |  WALLIX Bastion NODE 1   |            |  WALLIX Bastion NODE 2   |
         |  10.10.1.11      |            |  10.10.1.12      |
         |                  |            |                  |
         |  [Active]        |            |  [Active]        |
         |                  |            |                  |
         |  +------------+  |            |  +------------+  |
         |  | MariaDB    |<-+-- Sync --->+->| MariaDB    |  |
         |  | (Primary)  |  |            |  | (Replica)  |  |
         |  +------------+  |            |  +------------+  |
         +------------------+            +------------------+
                  |                                 |
                  +----------------+----------------+
                                   |
                             Target Systems

  KEY POINTS:
  - Both nodes accept connections
  - Database synchronized via streaming replication
  - Sessions can be managed from either node
  - VIP (10.10.1.100) optional - can use load balancer

+===============================================================================+
```

---

## Prerequisites

- [ ] Both WALLIX Bastion nodes installed (Step 03)
- [ ] Both nodes can reach each other
- [ ] SSH keys exchanged between nodes
- [ ] Same SSL certificates on both nodes

### Verify Inter-Node Connectivity

```bash
# From Node 1:
ping wallix-node2.lab.local
nc -zv wallix-node2.lab.local 22
nc -zv wallix-node2.lab.local 3306

# From Node 2:
ping wallix-node1.lab.local
nc -zv wallix-node1.lab.local 22
nc -zv wallix-node1.lab.local 3306
```

---

## Step 1: Configure SSH Key Exchange

### On Node 1

```bash
# Generate SSH key (if not exists)
ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa -N ""

# Copy to Node 2
ssh-copy-id root@wallix-node2.lab.local

# Test
ssh root@wallix-node2.lab.local hostname
```

### On Node 2

```bash
# Generate SSH key
ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa -N ""

# Copy to Node 1
ssh-copy-id root@wallix-node1.lab.local

# Test
ssh root@wallix-node1.lab.local hostname
```

---

## Step 2: Configure MariaDB Streaming Replication

### On Node 1 (Primary)

```bash
# Configure MariaDB for replication
# Note: WALLIX Bastion uses `bastion-replication` for automated setup
cat > /etc/mysql/mariadb.conf.d/50-replication.cnf << 'EOF'
[mysqld]
# Server identification (unique per node)
server-id = 1

# Binary logging for replication
log_bin = /var/log/mysql/mariadb-bin
binlog_format = ROW
expire_logs_days = 7
max_binlog_size = 100M

# Enable GTID for easier failover
gtid_strict_mode = ON
log_slave_updates = ON

# Connection settings
bind-address = 0.0.0.0

# For synchronous replication, use bastion-replication Master/Master
# See: bastion-replication --configure-master-master
EOF

# Create replication user
sudo mysql << 'EOF'
CREATE USER 'replicator'@'10.10.1.%' IDENTIFIED BY 'ReplicatorPass123!';
GRANT REPLICATION SLAVE ON *.* TO 'replicator'@'10.10.1.%';
FLUSH PRIVILEGES;
EOF

# Restart MariaDB
systemctl restart mariadb
```

### On Node 2 (Replica)

```bash
# Stop MariaDB
systemctl stop mariadb

# Remove existing data
rm -rf /var/lib/mysql/*

# Clone from primary using mariabackup
mariabackup --backup --target-dir=/tmp/backup \
    --host=wallix-node1.lab.local \
    --user=replicator \
    --password=ReplicatorPass123!

# Prepare and restore backup
mariabackup --prepare --target-dir=/tmp/backup
mariabackup --copy-back --target-dir=/tmp/backup
chown -R mysql:mysql /var/lib/mysql

# Configure replica settings
cat > /etc/mysql/mariadb.conf.d/50-replication.cnf << 'EOF'
[mysqld]
# Server identification (must be unique)
server-id = 2

# Binary logging
log_bin = /var/log/mysql/mariadb-bin
binlog_format = ROW
expire_logs_days = 7

# GTID and replica settings
gtid_strict_mode = ON
log_slave_updates = ON
read_only = ON
EOF

# Start MariaDB
systemctl start mariadb

# Configure replication to primary
sudo mysql << 'SQL'
CHANGE MASTER TO
    MASTER_HOST='wallix-node1.lab.local',
    MASTER_USER='replicator',
    MASTER_PASSWORD='ReplicatorPass123!',
    MASTER_USE_GTID=slave_pos;
START SLAVE;
SQL
```

### Verify Replication

```bash
# On Node 1 (Primary):
sudo mysql -e "SHOW MASTER STATUS\G"
sudo mysql -e "SHOW SLAVE HOSTS\G"

# Expected output should show node2 connected

# On Node 2 (Replica):
sudo mysql -e "SHOW SLAVE STATUS\G"

# Should show:
# Slave_IO_Running: Yes
# Slave_SQL_Running: Yes
# Seconds_Behind_Master: 0
```

---

## Step 3: Configure WALLIX Bastion Cluster

### On Node 1

```bash
# Configure as cluster member
cat >> /etc/opt/wab/wabengine.conf << 'EOF'

[cluster]
enabled = true
node_name = wallix-node1
node_ip = 10.10.1.11
peer_nodes = wallix-node2.lab.local:10.10.1.12
cluster_mode = active-active
vip = 10.10.1.100
vip_interface = ens192

[replication]
mode = streaming
primary_host = wallix-node1.lab.local
EOF

# Restart WALLIX Bastion
systemctl restart wallix-bastion
```

### On Node 2

```bash
# Configure as cluster member
cat >> /etc/opt/wab/wabengine.conf << 'EOF'

[cluster]
enabled = true
node_name = wallix-node2
node_ip = 10.10.1.12
peer_nodes = wallix-node1.lab.local:10.10.1.11
cluster_mode = active-active
vip = 10.10.1.100
vip_interface = ens192

[replication]
mode = streaming
primary_host = wallix-node1.lab.local
EOF

# Restart WALLIX Bastion
systemctl restart wallix-bastion
```

---

## Step 4: Configure `bastion-replication` (VIP and Cluster Management)

### On Node 1 (Master Setup)

```bash
# Configure bastion-replication Master/Master on Node 1
bastion-replication --configure-master-master \
    --local-node wallix-node1.lab.local \
    --remote-node wallix-node2.lab.local \
    --vip 10.10.1.100/24 \
    --vip-interface ens192 \
    --ssh-port 2242

# Start replication
bastion-replication --start
```

### On Node 2 (Join Cluster)

```bash
# Join the cluster from Node 2
bastion-replication --join \
    --master-node wallix-node1.lab.local \
    --ssh-port 2242

# Start replication
bastion-replication --start
```

### Configure VIP Preference

```bash
# Prefer Node 1 for VIP (but allow failover)
bastion-replication --set-preferred-master wallix-node1.lab.local
```

---

## Step 5: Verify Cluster Status

```bash
# Check cluster status
bastion-replication --status

# Expected output:
# bastion-replication status
# Role: Master
# Peer: wallix-node2 (connected)
# VIP: 10.10.1.100 (active on wallix-node1)
# Replication: synchronized

# Check VIP
ip addr show ens192 | grep 10.10.1.100

# Check cluster resources
bastion-replication --monitoring
```

---

## Step 6: Test Failover

### Test 1: VIP Failover

```bash
# From external machine, start continuous ping to VIP
ping 10.10.1.100

# On Node 1 (current VIP holder), simulate failure
# Put node in maintenance (stop services on node)
systemctl stop wallix-keepalived

# Watch VIP move to Node 2
# Ping should continue with minimal interruption

# Restore Node 1
# Resume node (restart services on node)
systemctl start wallix-keepalived
```

### Test 2: Service Failover

```bash
# On Node 1, stop WALLIX Bastion service
systemctl stop wallix-bastion

# Verify web UI still accessible via VIP (served by Node 2)
curl -k https://10.10.1.100/

# Restart service
systemctl start wallix-bastion
```

### Test 3: Database Replication

```bash
# On Node 1 (Primary), create test data
sudo mysql wabdb -c "CREATE TABLE test_replication (id serial, data text);"
sudo mysql wabdb -c "INSERT INTO test_replication (data) VALUES ('test from node1');"

# On Node 2 (Replica), verify data replicated
sudo mysql wabdb -c "SELECT * FROM test_replication;"

# Clean up
sudo mysql wabdb -c "DROP TABLE test_replication;"
```

---

## Step 7: Load Balancer Configuration (Alternative to VIP)

If using a load balancer instead of `bastion-replication` VIP:

### HAProxy Example

```bash
# /etc/haproxy/haproxy.cfg on load balancer

frontend wallix_https
    bind *:443
    mode tcp
    default_backend wallix_nodes

backend wallix_nodes
    mode tcp
    balance roundrobin
    option tcp-check
    server wallix-node1 10.10.1.11:443 check
    server wallix-node2 10.10.1.12:443 check

frontend wallix_ssh
    bind *:22
    mode tcp
    default_backend wallix_ssh_nodes

backend wallix_ssh_nodes
    mode tcp
    balance roundrobin
    server wallix-node1 10.10.1.11:22 check
    server wallix-node2 10.10.1.12:22 check
```

### DNS Round Robin (Simple Option)

```powershell
# On AD DC, add multiple A records
Add-DnsServerResourceRecordA -ZoneName "lab.local" -Name "wallix" -IPv4Address "10.10.1.11"
Add-DnsServerResourceRecordA -ZoneName "lab.local" -Name "wallix" -IPv4Address "10.10.1.12"
```

---

## HA Cluster Status Commands

```bash
# Quick status
bastion-replication status

# Detailed status
bastion-replication --monitoring

# Check replication lag (on replica)
sudo mysql -e "SHOW SLAVE STATUS\G" | grep Seconds_Behind_Master

# Promote a node to master (failover)
bastion-replication --elevate-master
```

---

## HA Checklist

| Check | Command | Expected |
|-------|---------|----------|
| Both nodes online | `bastion-replication status` | 2 nodes Online |
| VIP assigned | `ip addr show` | VIP on one node |
| VIP reachable | `ping 10.10.1.100` | Success |
| Web UI via VIP | `curl -k https://10.10.1.100/` | HTML response |
| Replication active | `SHOW SLAVE STATUS` | Node2 connected |
| Replication lag | `Seconds_Behind_Master` | < 60s |
| Failover works | Standby node1, check VIP | VIP moves to node2 |

---

## Troubleshooting

### Cluster Won't Form

```bash
# Check bastion-replication service
bastion-replication status
bastion-replication --monitoring

# Check SSH tunnel connectivity (port 2242)
ss -tlnp | grep 2242

# Check MariaDB replication port (3307)
ss -tlnp | grep 3307
```

### VIP Not Moving

```bash
# Restart Keepalived to recover VIP
systemctl restart keepalived

# Check cluster and VIP status
bastion-replication --status

# VIP managed by Keepalived - adjust priority or stop keepalived on current master
# to force VIP migration to wallix-node2
systemctl stop keepalived  # on current master
```

### Replication Broken

```bash
# On replica, check status
sudo mysql -e "SHOW SLAVE STATUS\G"

# Check replication connection
sudo mysql -e "SHOW SLAVE STATUS\G" | grep -E "(Slave_IO_Running|Slave_SQL_Running)"

# Re-sync from primary (destructive - data loss on replica)
systemctl stop mariadb
rm -rf /var/lib/mysql/*

# Backup from primary
mariabackup --backup --target-dir=/tmp/backup \
    --host=wallix-node1.lab.local \
    --user=replicator \
    --password=ReplicatorPass123!

# Prepare and restore
mariabackup --prepare --target-dir=/tmp/backup
mariabackup --copy-back --target-dir=/tmp/backup
chown -R mysql:mysql /var/lib/mysql

systemctl start mariadb

# Re-configure replication
sudo mysql << 'SQL'
CHANGE MASTER TO
    MASTER_HOST='wallix-node1.lab.local',
    MASTER_USER='replicator',
    MASTER_PASSWORD='ReplicatorPass123!',
    MASTER_USE_GTID=slave_pos;
START SLAVE;
SQL
```

---

<p align="center">
  <a href="./07-wallix-installation.md">← Previous: WALLIX Bastion Installation</a> •
  <a href="./09-test-targets.md">Next: Test Targets Setup →</a>
</p>
