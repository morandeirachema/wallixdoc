# 03 - HAProxy Load Balancer Setup

## High Availability Load Balancing for PAM4OT

This guide covers setting up two HAProxy load balancers in an active/standby configuration using Keepalived for VIP failover.

---

## Architecture

```
+===============================================================================+
|                    HAPROXY HA ARCHITECTURE                                    |
+===============================================================================+
|                                                                               |
|                            USERS / OPERATORS                                  |
|                                   |                                           |
|                                   v                                           |
|                          VIP: 10.10.1.100                                     |
|                                   |                                           |
|                    +--------------+--------------+                            |
|                    |                             |                            |
|              +----------+                  +----------+                       |
|              | HAProxy  |   Keepalived     | HAProxy  |                       |
|              |  LB-1    |<---------------->|  LB-2    |                       |
|              | (MASTER) |    VRRP Sync     | (BACKUP) |                       |
|              |10.10.1.5 |                  |10.10.1.6 |                       |
|              +----------+                  +----------+                       |
|                    |                             |                            |
|                    +-------------+---------------+                            |
|                                  |                                            |
|                    +-------------+-------------+                              |
|                    |                           |                              |
|              +----------+               +----------+                          |
|              | PAM4OT   |               | PAM4OT   |                          |
|              | Node 1   |               | Node 2   |                          |
|              |10.10.1.11|               |10.10.1.12|                          |
|              +----------+               +----------+                          |
|                                                                               |
+===============================================================================+
```

---

## Prerequisites

- 2x Debian 12 VMs for HAProxy (2 vCPU, 4GB RAM, 20GB disk)
- Network connectivity between all nodes
- VIP address reserved (10.10.1.100)

---

## HAProxy Node 1 (Primary)

### Step 1: Base Configuration

```bash
# Set hostname
hostnamectl set-hostname haproxy-1.lab.local

# Configure network
cat > /etc/network/interfaces << 'EOF'
auto lo
iface lo inet loopback

auto ens192
iface ens192 inet static
    address 10.10.1.5/24
    gateway 10.10.1.1
    dns-nameservers 10.10.0.10
    dns-search lab.local
EOF

# Apply network
systemctl restart networking

# Update /etc/hosts
cat >> /etc/hosts << 'EOF'
10.10.1.5   haproxy-1.lab.local haproxy-1
10.10.1.6   haproxy-2.lab.local haproxy-2
10.10.1.11  pam4ot-node1.lab.local pam4ot-node1
10.10.1.12  pam4ot-node2.lab.local pam4ot-node2
10.10.1.100 pam4ot.lab.local pam4ot
EOF
```

### Step 2: Install HAProxy and Keepalived

```bash
apt update && apt install -y haproxy keepalived

# Enable services
systemctl enable haproxy keepalived
```

### Step 3: Configure HAProxy

```bash
cat > /etc/haproxy/haproxy.cfg << 'EOF'
#---------------------------------------------------------------------
# Global settings
#---------------------------------------------------------------------
global
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

    # SSL/TLS settings
    ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256
    ssl-default-bind-options ssl-min-ver TLSv1.2 no-tls-tickets

#---------------------------------------------------------------------
# Default settings
#---------------------------------------------------------------------
defaults
    log     global
    mode    tcp
    option  tcplog
    option  dontlognull
    timeout connect 5000ms
    timeout client  50000ms
    timeout server  50000ms
    errorfile 400 /etc/haproxy/errors/400.http
    errorfile 403 /etc/haproxy/errors/403.http
    errorfile 408 /etc/haproxy/errors/408.http
    errorfile 500 /etc/haproxy/errors/500.http
    errorfile 502 /etc/haproxy/errors/502.http
    errorfile 503 /etc/haproxy/errors/503.http
    errorfile 504 /etc/haproxy/errors/504.http

#---------------------------------------------------------------------
# Stats page
#---------------------------------------------------------------------
listen stats
    bind *:8404
    mode http
    stats enable
    stats uri /stats
    stats refresh 10s
    stats admin if LOCALHOST

#---------------------------------------------------------------------
# PAM4OT HTTPS Frontend (Web UI)
#---------------------------------------------------------------------
frontend pam4ot_https
    bind *:443
    mode tcp
    option tcplog
    default_backend pam4ot_https_backend

backend pam4ot_https_backend
    mode tcp
    balance roundrobin
    option tcp-check
    server pam4ot-node1 10.10.1.11:443 check inter 5000 rise 2 fall 3
    server pam4ot-node2 10.10.1.12:443 check inter 5000 rise 2 fall 3 backup

#---------------------------------------------------------------------
# PAM4OT SSH Proxy Frontend
#---------------------------------------------------------------------
frontend pam4ot_ssh
    bind *:22
    mode tcp
    option tcplog
    default_backend pam4ot_ssh_backend

backend pam4ot_ssh_backend
    mode tcp
    balance roundrobin
    option tcp-check
    tcp-check connect port 22
    server pam4ot-node1 10.10.1.11:22 check inter 5000 rise 2 fall 3
    server pam4ot-node2 10.10.1.12:22 check inter 5000 rise 2 fall 3 backup

#---------------------------------------------------------------------
# PAM4OT RDP Proxy Frontend
#---------------------------------------------------------------------
frontend pam4ot_rdp
    bind *:3389
    mode tcp
    option tcplog
    default_backend pam4ot_rdp_backend

backend pam4ot_rdp_backend
    mode tcp
    balance roundrobin
    option tcp-check
    tcp-check connect port 3389
    server pam4ot-node1 10.10.1.11:3389 check inter 5000 rise 2 fall 3
    server pam4ot-node2 10.10.1.12:3389 check inter 5000 rise 2 fall 3 backup

#---------------------------------------------------------------------
# PAM4OT HTTP Redirect (optional)
#---------------------------------------------------------------------
frontend pam4ot_http
    bind *:80
    mode http
    redirect scheme https code 301

EOF
```

### Step 4: Configure Keepalived (Primary)

```bash
cat > /etc/keepalived/keepalived.conf << 'EOF'
! Keepalived configuration for HAProxy HA

global_defs {
    router_id HAPROXY_LB1
    script_user root
    enable_script_security
}

vrrp_script check_haproxy {
    script "/usr/bin/killall -0 haproxy"
    interval 2
    weight 2
    fall 2
    rise 2
}

vrrp_instance VI_1 {
    state MASTER
    interface ens192
    virtual_router_id 51
    priority 101
    advert_int 1

    authentication {
        auth_type PASS
        auth_pass SecureVRRP2026!
    }

    virtual_ipaddress {
        10.10.1.100/24
    }

    track_script {
        check_haproxy
    }

    notify_master "/etc/keepalived/notify.sh master"
    notify_backup "/etc/keepalived/notify.sh backup"
    notify_fault  "/etc/keepalived/notify.sh fault"
}
EOF

# Create notify script
cat > /etc/keepalived/notify.sh << 'EOF'
#!/bin/bash
TYPE=$1
case $TYPE in
    master)
        logger "Keepalived: Became MASTER"
        systemctl start haproxy
        ;;
    backup)
        logger "Keepalived: Became BACKUP"
        ;;
    fault)
        logger "Keepalived: Entered FAULT state"
        ;;
esac
EOF
chmod +x /etc/keepalived/notify.sh
```

### Step 5: Enable IP Forwarding

```bash
echo "net.ipv4.ip_nonlocal_bind = 1" >> /etc/sysctl.conf
sysctl -p
```

### Step 6: Start Services

```bash
systemctl restart haproxy
systemctl restart keepalived
systemctl status haproxy keepalived
```

---

## HAProxy Node 2 (Backup)

### Step 1: Base Configuration

```bash
# Set hostname
hostnamectl set-hostname haproxy-2.lab.local

# Configure network
cat > /etc/network/interfaces << 'EOF'
auto lo
iface lo inet loopback

auto ens192
iface ens192 inet static
    address 10.10.1.6/24
    gateway 10.10.1.1
    dns-nameservers 10.10.0.10
    dns-search lab.local
EOF

systemctl restart networking

# Update /etc/hosts (same as node 1)
cat >> /etc/hosts << 'EOF'
10.10.1.5   haproxy-1.lab.local haproxy-1
10.10.1.6   haproxy-2.lab.local haproxy-2
10.10.1.11  pam4ot-node1.lab.local pam4ot-node1
10.10.1.12  pam4ot-node2.lab.local pam4ot-node2
10.10.1.100 pam4ot.lab.local pam4ot
EOF
```

### Step 2: Install and Configure HAProxy

```bash
apt update && apt install -y haproxy keepalived
systemctl enable haproxy keepalived

# Copy same haproxy.cfg from Node 1
# (Use the exact same configuration)
```

### Step 3: Configure Keepalived (Backup)

```bash
cat > /etc/keepalived/keepalived.conf << 'EOF'
! Keepalived configuration for HAProxy HA (Backup)

global_defs {
    router_id HAPROXY_LB2
    script_user root
    enable_script_security
}

vrrp_script check_haproxy {
    script "/usr/bin/killall -0 haproxy"
    interval 2
    weight 2
    fall 2
    rise 2
}

vrrp_instance VI_1 {
    state BACKUP
    interface ens192
    virtual_router_id 51
    priority 100
    advert_int 1

    authentication {
        auth_type PASS
        auth_pass SecureVRRP2026!
    }

    virtual_ipaddress {
        10.10.1.100/24
    }

    track_script {
        check_haproxy
    }

    notify_master "/etc/keepalived/notify.sh master"
    notify_backup "/etc/keepalived/notify.sh backup"
    notify_fault  "/etc/keepalived/notify.sh fault"
}
EOF

# Create same notify script as Node 1
cat > /etc/keepalived/notify.sh << 'EOF'
#!/bin/bash
TYPE=$1
case $TYPE in
    master)
        logger "Keepalived: Became MASTER"
        systemctl start haproxy
        ;;
    backup)
        logger "Keepalived: Became BACKUP"
        ;;
    fault)
        logger "Keepalived: Entered FAULT state"
        ;;
esac
EOF
chmod +x /etc/keepalived/notify.sh

echo "net.ipv4.ip_nonlocal_bind = 1" >> /etc/sysctl.conf
sysctl -p

systemctl restart haproxy keepalived
```

---

## Verification

### Check VIP Assignment

```bash
# On the master node, verify VIP is assigned
ip addr show ens192 | grep 10.10.1.100

# Check Keepalived state
systemctl status keepalived
journalctl -u keepalived -n 20
```

### Check HAProxy Status

```bash
# Check HAProxy is running
systemctl status haproxy

# Check backend status via stats page
curl http://localhost:8404/stats

# Test connectivity through VIP
curl -k https://10.10.1.100/
ssh -o ConnectTimeout=5 test@10.10.1.100
```

### Test Failover

```bash
# On haproxy-1 (master), stop HAProxy
systemctl stop haproxy

# Check that haproxy-2 takes over the VIP
# On haproxy-2:
ip addr show ens192 | grep 10.10.1.100
# Should now show the VIP

# Verify services still work through VIP
curl -k https://10.10.1.100/

# Restart haproxy-1
systemctl start haproxy
# VIP should stay on haproxy-2 (non-preemptive)
# Or return to haproxy-1 if preempt is enabled
```

---

## Monitoring

### HAProxy Stats Page

Access the stats page at: `http://haproxy-1:8404/stats` or `http://haproxy-2:8404/stats`

### Log Monitoring

```bash
# HAProxy logs
tail -f /var/log/haproxy.log

# Keepalived logs
journalctl -u keepalived -f
```

### Prometheus Metrics (Optional)

Add to haproxy.cfg for Prometheus scraping:

```
frontend stats
    bind *:8405
    mode http
    http-request use-service prometheus-exporter if { path /metrics }
```

---

## SSL/TLS Configuration (Production)

For production, configure SSL termination:

```bash
# Combine certificate and key
cat /etc/ssl/certs/pam4ot.crt /etc/ssl/private/pam4ot.key > /etc/haproxy/pam4ot.pem

# Update frontend to use SSL
frontend pam4ot_https
    bind *:443 ssl crt /etc/haproxy/pam4ot.pem
    mode http
    # ... rest of config
```

---

## Troubleshooting

| Issue | Check | Solution |
|-------|-------|----------|
| VIP not assigned | `ip addr show` | Check Keepalived config, priority |
| HAProxy not starting | `journalctl -u haproxy` | Check config syntax: `haproxy -c -f /etc/haproxy/haproxy.cfg` |
| Backends down | Stats page | Check PAM4OT nodes are running |
| Failover not working | Keepalived logs | Check VRRP auth, interface name |

---

## Quick Reference

| Component | Node 1 | Node 2 |
|-----------|--------|--------|
| Hostname | haproxy-1 | haproxy-2 |
| IP Address | 10.10.1.5 | 10.10.1.6 |
| Role | MASTER (priority 101) | BACKUP (priority 100) |
| VIP | 10.10.1.100 (shared) | 10.10.1.100 (shared) |

| Port | Service |
|------|---------|
| 22 | SSH Proxy (to PAM4OT) |
| 80 | HTTP Redirect |
| 443 | HTTPS Web UI |
| 3389 | RDP Proxy |
| 8404 | HAProxy Stats |

---

<p align="center">
  <a href="./02-active-directory-setup.md">← Previous</a> •
  <a href="./03-pam4ot-installation.md">Next: PAM4OT Installation →</a>
</p>
