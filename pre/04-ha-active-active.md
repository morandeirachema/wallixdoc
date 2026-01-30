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
# Edit MariaDB configuration
cat >> /etc/mysql/mariadb.conf.d/50-server.cnf << 'EOF'

# Replication Settings
wal_level = replica
max_wal_senders = 5
wal_keep_size = 1GB
hot_standby = on
synchronous_commit = on
synchronous_standby_names = 'pam4ot_node2'
EOF

# Configure replication access
cat >> /etc/mysql/mariadb.conf.d/50-server.cnf << 'EOF'

# Replication connections
host    replication     replicator      10.10.1.12/32      scram-sha-256
host    wabdb           wabadmin        10.10.1.12/32      scram-sha-256
EOF

# Create replication user
sudo mysql << 'EOF'
CREATE USER replicator WITH REPLICATION ENCRYPTED PASSWORD 'ReplicatorPass123!';
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

# Clone from primary
mariabackup -h pam4ot-node1.lab.local -D /var/lib/mysql -U replicator -P -Xs -R

# When prompted, enter: ReplicatorPass123!

# Configure as standby
cat > /var/lib/mysql/mariadb.auto.cnf << 'EOF'
primary_conninfo = 'host=pam4ot-node1.lab.local port=3306 user=replicator password=ReplicatorPass123! application_name=pam4ot_node2'
EOF

# Edit mariadb.cnf for hot standby
cat >> /etc/mysql/mariadb.conf.d/50-server.cnf << 'EOF'

# Hot Standby Settings
hot_standby = on
hot_standby_feedback = on
EOF

# Start MariaDB
systemctl start mariadb
```

### Verify Replication

```bash
# On Node 1 (Primary):
sudo mysql -c "SELECT * FROM SHOW SLAVE STATUS;"

# Expected output should show node2 connected

# On Node 2 (Replica):
sudo mysql -e "SHOW SLAVE STATUS\G"

# Should show replication slave is running
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

# Check replication lag
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

# Re-sync from primary (destructive)
systemctl stop mariadb
rm -rf /var/lib/mysql/*
mariabackup -h pam4ot-node1.lab.local -D /var/lib/mysql -U replicator -P -Xs -R
systemctl start mariadb
```

---

<p align="center">
  <a href="./03-pam4ot-installation.md">← Previous</a> •
  <a href="./05-ad-integration.md">Next: AD Integration →</a>
</p>
