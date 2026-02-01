# 04 - HA Active-Active Configuration

## Configuring Two-Node Active-Active Cluster

This guide covers setting up PAM4OT in Active-Active high availability mode where both nodes handle traffic simultaneously.

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
         |  PAM4OT NODE 1   |            |  PAM4OT NODE 2   |
         |  10.10.1.11      |            |  10.10.1.12      |
         |                  |            |                  |
         |  [Active]        |            |  [Active]        |
         |                  |            |                  |
         |  +------------+  |            |  +------------+  |
         |  | MariaDB |<-+-- Sync --->+->| MariaDB |  |
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

- [ ] Both PAM4OT nodes installed (Step 03)
- [ ] Both nodes can reach each other
- [ ] SSH keys exchanged between nodes
- [ ] Same SSL certificates on both nodes

### Verify Inter-Node Connectivity

```bash
# From Node 1:
ping pam4ot-node2.lab.local
nc -zv pam4ot-node2.lab.local 22
nc -zv pam4ot-node2.lab.local 3306

# From Node 2:
ping pam4ot-node1.lab.local
nc -zv pam4ot-node1.lab.local 22
nc -zv pam4ot-node1.lab.local 3306
```

---

## Step 1: Configure SSH Key Exchange

### On Node 1

```bash
# Generate SSH key (if not exists)
ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa -N ""

# Copy to Node 2
ssh-copy-id root@pam4ot-node2.lab.local

# Test
ssh root@pam4ot-node2.lab.local hostname
```

### On Node 2

```bash
# Generate SSH key
ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa -N ""

# Copy to Node 1
ssh-copy-id root@pam4ot-node1.lab.local

# Test
ssh root@pam4ot-node1.lab.local hostname
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

# For synchronous replication (Galera-style), uncomment:
# wsrep_on = ON
# wsrep_cluster_address = "gcomm://10.10.1.11,10.10.1.12"
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
    --host=pam4ot-node1.lab.local \
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
    MASTER_HOST='pam4ot-node1.lab.local',
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

## Step 3: Configure PAM4OT Cluster

### On Node 1

```bash
# Configure as cluster member
cat >> /etc/opt/wab/wabengine.conf << 'EOF'

[cluster]
enabled = true
node_name = pam4ot-node1
node_ip = 10.10.1.11
peer_nodes = pam4ot-node2.lab.local:10.10.1.12
cluster_mode = active-active
vip = 10.10.1.100
vip_interface = ens192

[replication]
mode = streaming
primary_host = pam4ot-node1.lab.local
EOF

# Restart PAM4OT
systemctl restart wallix-bastion
```

### On Node 2

```bash
# Configure as cluster member
cat >> /etc/opt/wab/wabengine.conf << 'EOF'

[cluster]
enabled = true
node_name = pam4ot-node2
node_ip = 10.10.1.12
peer_nodes = pam4ot-node1.lab.local:10.10.1.11
cluster_mode = active-active
vip = 10.10.1.100
vip_interface = ens192

[replication]
mode = streaming
primary_host = pam4ot-node1.lab.local
EOF

# Restart PAM4OT
systemctl restart wallix-bastion
```

---

## Step 4: Configure Pacemaker/Corosync (VIP Management)

### On Both Nodes

```bash
# Install cluster packages
apt install -y pacemaker corosync pcs

# Set cluster password
echo "hacluster:HaCluster123!" | chpasswd

# Enable services
systemctl enable pcsd corosync pacemaker
systemctl start pcsd
```

### On Node 1 (Cluster Setup)

```bash
# Authenticate nodes
pcs host auth pam4ot-node1.lab.local pam4ot-node2.lab.local -u hacluster -p HaCluster123!

# Create cluster
pcs cluster setup pam4ot-cluster pam4ot-node1.lab.local pam4ot-node2.lab.local

# Start cluster
pcs cluster start --all
pcs cluster enable --all

# Check status
pcs status
```

### Configure VIP Resource

```bash
# Create VIP resource
pcs resource create vip-pam4ot ocf:heartbeat:IPaddr2 \
    ip=10.10.1.100 \
    cidr_netmask=24 \
    nic=ens192 \
    op monitor interval=10s

# For Active-Active, allow VIP to run on either node
pcs resource clone vip-pam4ot clone-max=1 clone-node-max=1

# Or use as floating VIP (preferred for web access)
# No cloning needed - VIP will float to one node
```

### Configure Resource Constraints

```bash
# Prefer Node 1 for VIP (but allow failover)
pcs constraint location vip-pam4ot prefers pam4ot-node1.lab.local=100

# Set no quorum policy (2-node cluster)
pcs property set no-quorum-policy=ignore

# Set stonith (fencing) - disable for lab, enable for production
pcs property set stonith-enabled=false
```

---

## Step 5: Verify Cluster Status

```bash
# Check cluster status
pcs status

# Expected output:
# Cluster name: pam4ot-cluster
# Status of pacemakerd: active
#
# Node List:
#   * Online: [ pam4ot-node1 pam4ot-node2 ]
#
# Full List of Resources:
#   * vip-pam4ot (ocf::heartbeat:IPaddr2): Started pam4ot-node1

# Check VIP
ip addr show ens192 | grep 10.10.1.100

# Check cluster resources
crm_mon -1
```

---

## Step 6: Test Failover

### Test 1: VIP Failover

```bash
# From external machine, start continuous ping to VIP
ping 10.10.1.100

# On Node 1 (current VIP holder), simulate failure
pcs node standby pam4ot-node1

# Watch VIP move to Node 2
# Ping should continue with minimal interruption

# Restore Node 1
pcs node unstandby pam4ot-node1
```

### Test 2: Service Failover

```bash
# On Node 1, stop PAM4OT service
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

If using a load balancer instead of Pacemaker VIP:

### HAProxy Example

```bash
# /etc/haproxy/haproxy.cfg on load balancer

frontend pam4ot_https
    bind *:443
    mode tcp
    default_backend pam4ot_nodes

backend pam4ot_nodes
    mode tcp
    balance roundrobin
    option tcp-check
    server pam4ot-node1 10.10.1.11:443 check
    server pam4ot-node2 10.10.1.12:443 check

frontend pam4ot_ssh
    bind *:22
    mode tcp
    default_backend pam4ot_ssh_nodes

backend pam4ot_ssh_nodes
    mode tcp
    balance roundrobin
    server pam4ot-node1 10.10.1.11:22 check
    server pam4ot-node2 10.10.1.12:22 check
```

### DNS Round Robin (Simple Option)

```powershell
# On AD DC, add multiple A records
Add-DnsServerResourceRecordA -ZoneName "lab.local" -Name "pam4ot" -IPv4Address "10.10.1.11"
Add-DnsServerResourceRecordA -ZoneName "lab.local" -Name "pam4ot" -IPv4Address "10.10.1.12"
```

---

## HA Cluster Status Commands

```bash
# Quick status
pcs status

# Detailed status
crm_mon -Afr

# Resource status
pcs resource show

# Node status
pcs node status

# Check replication lag (on replica)
sudo mysql -e "SHOW SLAVE STATUS\G" | grep Seconds_Behind_Master

# Cluster properties
pcs property list
```

---

## HA Checklist

| Check | Command | Expected |
|-------|---------|----------|
| Both nodes online | `pcs status` | 2 nodes Online |
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
# Check corosync
systemctl status corosync
journalctl -u corosync

# Check pacemaker
systemctl status pacemaker
journalctl -u pacemaker

# Check communication
corosync-cfgtool -s
```

### VIP Not Moving

```bash
# Check resource status
pcs resource debug-start vip-pam4ot

# Check constraints
pcs constraint list

# Force move
pcs resource move vip-pam4ot pam4ot-node2
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
    --host=pam4ot-node1.lab.local \
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
    MASTER_HOST='pam4ot-node1.lab.local',
    MASTER_USER='replicator',
    MASTER_PASSWORD='ReplicatorPass123!',
    MASTER_USE_GTID=slave_pos;
START SLAVE;
SQL
```

---

<p align="center">
  <a href="./07-pam4ot-installation.md">← Previous: PAM4OT Installation</a> •
  <a href="./09-test-targets.md">Next: Test Targets Setup →</a>
</p>
