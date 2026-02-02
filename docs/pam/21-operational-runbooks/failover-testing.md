# Failover Testing Procedures

## Validating High Availability and Disaster Recovery

This document provides comprehensive procedures for testing WALLIX Bastion cluster failover capabilities.

---

## Failover Test Overview

```
+===============================================================================+
|                       FAILOVER TEST CATEGORIES                                |
+===============================================================================+

  1. PLANNED FAILOVER                   2. UNPLANNED FAILOVER
  ====================                  =====================
  - Maintenance window                  - Simulated node failure
  - Controlled VIP movement             - Network partition
  - Rolling updates                     - Service crash
  - Database switchover                 - Power loss simulation

  3. NETWORK FAILOVER                   4. APPLICATION FAILOVER
  ===================                   =======================
  - Load balancer failover              - WALLIX Bastion service restart
  - VIP failover (Pacemaker)            - MariaDB failover
  - DNS failover                        - Session continuity
  - Multi-site failover                 - Authentication continuity

+===============================================================================+
```

---

## Pre-Test Checklist

Before any failover testing:

```
PRE-TEST CHECKLIST
==================
[ ] Change window approved
[ ] Stakeholders notified
[ ] Monitoring alerts silenced (with timeout)
[ ] Backup verified and recent (< 24h)
[ ] Rollback procedure documented
[ ] Support contact available
[ ] No active critical sessions
[ ] Test plan reviewed by team
```

---

## Test 1: Planned VIP Failover (Pacemaker)

### Objective
Verify VIP moves cleanly between nodes during planned maintenance.

### Prerequisites
- Both WALLIX Bastion nodes healthy
- Pacemaker cluster running
- No active sessions (or users warned)

### Procedure

```bash
# Step 1: Check current cluster status
pcs status

# Expected output:
# Cluster name: wallix-cluster
# Online: [ wallix-node1 wallix-node2 ]
# Resources:
#   * vip-wallix (ocf::heartbeat:IPaddr2): Started wallix-node1

# Step 2: Identify which node has VIP
ip addr show | grep 10.10.1.100
# Shows on node1

# Step 3: Start continuous monitoring
# Terminal 1: Ping VIP
ping 10.10.1.100

# Terminal 2: Watch cluster status
watch -n 1 pcs status

# Terminal 3: Monitor web UI
while true; do
  curl -sk -o /dev/null -w "%{http_code} %{time_total}s\n" https://10.10.1.100/
  sleep 1
done

# Step 4: Initiate failover - put node1 in standby
pcs node standby wallix-node1

# Step 5: Observe failover
# - VIP should move to node2
# - Ping should continue with 1-3 packet loss
# - Web UI should recover within 10 seconds

# Step 6: Verify new state
pcs status
# vip-wallix should show: Started wallix-node2

# Step 7: Test functionality
# - Login to web UI
# - Verify authentication works
# - Start a test session

# Step 8: Restore node1
pcs node unstandby wallix-node1

# Step 9: Verify both nodes online
pcs status
```

### Expected Results

| Metric | Target | Acceptable |
|--------|--------|------------|
| VIP failover time | < 10 sec | < 30 sec |
| Packet loss | 0-3 packets | < 10 packets |
| Web UI recovery | < 15 sec | < 30 sec |
| Active sessions | Maintained | May need reconnect |

### Test Log Template

```
FAILOVER TEST LOG - VIP FAILOVER
================================
Date: ____________________
Tester: ____________________
Ticket: ____________________

Pre-Test Status:
- Node1 status: [ ] Online
- Node2 status: [ ] Online
- VIP location: Node ___
- Cluster health: [ ] Healthy

Test Execution:
- Standby initiated: __:__:__
- VIP moved: __:__:__
- Failover duration: ___ seconds
- Packets lost: ___

Post-Test Verification:
- [ ] VIP responding
- [ ] Web UI accessible
- [ ] Authentication working
- [ ] Session connectivity verified
- [ ] Node restored to cluster

Result: [ ] PASS  [ ] FAIL

Notes:
______________________________________
______________________________________
```

---

## Test 2: Unplanned Node Failure

### Objective
Verify automatic failover when a node becomes unavailable.

### Procedure

```bash
# Step 1: Identify current VIP holder
pcs status | grep vip-wallix

# Step 2: Start monitoring (same as Test 1)

# Step 3: Simulate node failure (choose one method)

# Method A: Stop Pacemaker service
ssh wallix-node1 "systemctl stop pacemaker"

# Method B: Network disconnect (if VM)
# Disconnect network adapter from vSphere/Hyper-V

# Method C: Kernel panic (aggressive)
ssh wallix-node1 "echo c > /proc/sysrq-trigger"

# Step 4: Observe automatic failover
# Pacemaker should detect failure within 15-30 seconds
# VIP should move to surviving node

# Step 5: Verify services on surviving node
pcs status
curl -sk https://10.10.1.100/

# Step 6: Restore failed node
# - Power on / reconnect network
# - Start Pacemaker: systemctl start pacemaker
# - Verify node rejoins cluster

# Step 7: Verify cluster fully healthy
pcs status
```

### Expected Results

| Metric | Target | Acceptable |
|--------|--------|------------|
| Failure detection | < 15 sec | < 30 sec |
| VIP failover | < 30 sec | < 60 sec |
| Service recovery | < 45 sec | < 90 sec |
| Data loss | None | None |

---

## Test 3: MariaDB Failover

### Objective
Verify database replication and failover functionality.

### Pre-Test Verification

```bash
# Check replication status on primary
sudo mysql -e "SHOW MASTER STATUS;"

# Check if replica is in sync
sudo mysql -e "SHOW SLAVE STATUS\G" | grep -E "(Slave_IO_Running|Slave_SQL_Running|Seconds_Behind_Master)"
# Seconds_Behind_Master should be 0 or very low
```

### Procedure

```bash
# Step 1: Insert test data
sudo mysql wabdb -e "CREATE TABLE failover_test (id INT AUTO_INCREMENT PRIMARY KEY, ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP);"
sudo mysql wabdb -e "INSERT INTO failover_test () VALUES ();"

# Step 2: Verify data replicated
# On replica:
sudo mysql wabdb -e "SELECT * FROM failover_test;"

# Step 3: Simulate primary failure
# Stop MariaDB on primary
ssh wallix-node1 "systemctl stop mariadb"

# Step 4: Promote replica (if not automatic)
# On node2:
sudo mysql -e "STOP SLAVE; RESET SLAVE ALL;"

# Step 5: Verify new primary is operational
sudo mysql wabdb -e "INSERT INTO failover_test () VALUES ();"
sudo mysql wabdb -e "SELECT * FROM failover_test;"

# Step 6: Reconfigure old primary as replica
# On node1:
# 1. Remove old data
rm -rf /var/lib/mysql/*

# 2. Backup from new primary
mariabackup --backup --target-dir=/tmp/backup --host=wallix-node2 --user=replicator --password=xxx
mariabackup --prepare --target-dir=/tmp/backup
mariabackup --copy-back --target-dir=/tmp/backup
chown -R mysql:mysql /var/lib/mysql

# 3. Start MariaDB and configure replication
systemctl start mariadb
sudo mysql -e "CHANGE MASTER TO MASTER_HOST='wallix-node2', MASTER_USER='replicator', MASTER_PASSWORD='xxx', MASTER_AUTO_POSITION=1;"
sudo mysql -e "START SLAVE;"

# Step 7: Verify replication restored
# On new primary (node2):
sudo mysql -e "SHOW SLAVE HOSTS;"

# Step 8: Clean up test data
sudo mysql wabdb -e "DROP TABLE failover_test;"
```

---

## Test 4: Load Balancer Failover

### Objective
Verify load balancer handles backend failures correctly.

### For HAProxy

```bash
# Step 1: Check current backend status
echo "show stat" | socat stdio /var/run/haproxy/admin.sock | grep wallix

# Step 2: Take one backend offline
echo "disable server wallix_nodes/wallix-node1" | socat stdio /var/run/haproxy/admin.sock

# Step 3: Verify traffic goes to remaining node
for i in {1..10}; do
  curl -sk https://wallix.company.com/ -o /dev/null -w "%{http_code}\n"
done
# All should return 200

# Step 4: Re-enable backend
echo "enable server wallix_nodes/wallix-node1" | socat stdio /var/run/haproxy/admin.sock

# Step 5: Verify both backends serving traffic
for i in {1..10}; do
  curl -sk https://wallix.company.com/ -o /dev/null -w "%{http_code}\n"
done
```

---

## Test 5: Full Site Failover (DR)

### Objective
Verify failover to secondary site works correctly.

### Prerequisites
- Secondary site configured and synchronized
- DNS TTL lowered (if using DNS failover)
- Change window approved

### Procedure

```bash
# Step 1: Verify secondary site health
ssh admin@wallix-dr.company.com "wabadmin status"

# Step 2: Check replication lag
# On DR site:
wabadmin sync-status

# Step 3: Simulate primary site failure
# - Stop all WALLIX Bastion services at primary
# - Or: Disconnect primary site network

# Step 4: Activate DR site
# On DR site:
wabadmin dr activate --force

# Step 5: Update DNS (if applicable)
# Change wallix.company.com to point to DR site IP

# Step 6: Verify DR site is operational
curl -sk https://wallix-dr.company.com/
wabadmin status

# Step 7: Test user authentication
# Login via web UI
# Start a test session

# Step 8: Document any data loss
# Compare last successful replication timestamp with current time
```

---

## Test 6: Session Continuity

### Objective
Verify active sessions survive failover.

### Procedure

```bash
# Step 1: Start a session through WALLIX Bastion
ssh jadmin@wallix.company.com
# Select target: linux-test / root

# Step 2: In the session, start a long-running command
top
# or
watch -n 1 date

# Step 3: Note session ID
# In another terminal:
wabadmin session list --user jadmin

# Step 4: Initiate failover (per Test 1 or 2)

# Step 5: Observe session behavior
# - SSH session may freeze briefly
# - Session should resume or reconnect
# - Commands should still be running

# Step 6: Verify session recording continued
wabadmin session show --id [session-id]
# Recording should have no gaps
```

---

## Test Schedule Template

```
QUARTERLY FAILOVER TEST SCHEDULE
================================

Q1 - January
  [ ] Week 2: Planned VIP failover (Test 1)
  [ ] Week 3: MariaDB failover (Test 3)

Q2 - April
  [ ] Week 2: Unplanned node failure (Test 2)
  [ ] Week 3: Load balancer failover (Test 4)

Q3 - July
  [ ] Week 2: Planned VIP failover (Test 1)
  [ ] Week 3: Session continuity (Test 6)

Q4 - October
  [ ] Week 2: Full site failover DR (Test 5)
  [ ] Week 3: Complete regression suite
```

---

## Rollback Procedures

### VIP Stuck on Wrong Node

```bash
# Force VIP back to preferred node
pcs resource move vip-wallix wallix-node1

# Clear location constraint after move
pcs resource clear vip-wallix
```

### MariaDB Split-Brain

```bash
# If both nodes think they're primary:
# 1. Stop MariaDB on both
systemctl stop mariadb

# 2. Determine which has more recent data
# Check binary log positions on both nodes

# 3. Designate correct primary
# 4. Rebuild replica from primary
```

### Cluster Won't Form

```bash
# Reset cluster completely
pcs cluster destroy --all
pcs cluster setup wallix-cluster wallix-node1 wallix-node2
pcs cluster start --all
pcs cluster enable --all
```

---

## Appendix: Monitoring Commands

```bash
# Cluster status
pcs status
crm_mon -1

# Resource status
pcs resource show

# Node status
pcs node status

# Cluster properties
pcs property list

# Recent cluster events
pcs status --full

# MariaDB replication
sudo mysql -e "SHOW SLAVE STATUS\G"

# VIP location
ip addr show | grep 10.10.1.100
```

---

<p align="center">
  <a href="./README.md">← Back to Runbooks</a>
</p>
