# 03 - Load Balancer Setup

## High Availability Load Balancing for WALLIX Bastion

This guide covers two load balancing options for WALLIX Bastion:

- **Option A** — HAProxy + Keepalived (Linux-based, active/standby with VIP failover)
- **Option B** — FortiGate Virtual IP (firewall-based, no extra VMs required)

> **Lab note**: HAProxy has 2 nodes (Active-Passive with Keepalived VRRP) and its VIP failover is valid to test in the lab. The backend is a **single WALLIX Bastion node** (10.10.1.11 only) — there is no wallix-node2 in the lab. DNS for the HAProxy nodes uses the AD DC at 10.10.1.60 (Cyber VLAN).

Choose the option that fits your infrastructure. Both forward traffic to the single Bastion node.

---

---

# Option A — HAProxy + Keepalived

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
|                         +----------------+                                   |
|                         | WALLIX Bastion |                                   |
|                         | (single node)  |                                   |
|                         | 10.10.1.11     |                                   |
|                         +----------------+                                   |
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
    dns-nameservers 10.10.1.60
    dns-search lab.local
EOF

# Apply network
systemctl restart networking

# Update /etc/hosts
cat >> /etc/hosts << 'EOF'
10.10.1.5   haproxy-1.lab.local haproxy-1
10.10.1.6   haproxy-2.lab.local haproxy-2
10.10.1.11  wallix-bastion.lab.local wallix-bastion
10.10.1.100 wallix.lab.local wallix
10.10.1.60  dc-lab.lab.local dc-lab
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
    stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

    # Default SSL material locations
    ca-base /etc/ssl/certs
    crt-base /etc/ssl/private

    # SSL/TLS settings - Production-grade ciphers
    ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384
    ssl-default-bind-ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256
    ssl-default-bind-options ssl-min-ver TLSv1.2 no-tls-tickets

#---------------------------------------------------------------------
# Default settings
#---------------------------------------------------------------------
defaults
    log     global
    mode    tcp
    option  tcplog
    option  dontlognull
    option  redispatch
    timeout connect 10s
    timeout client  1h
    timeout server  1h
    timeout queue   30s
    timeout tunnel  1h
    timeout client-fin 30s
    timeout server-fin 30s
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
    stats refresh 30s
    stats show-legends
    stats admin if LOCALHOST
    stats auth admin:HAProxyStats2026!

#---------------------------------------------------------------------
# WALLIX Bastion HTTPS Frontend (Web UI)
#---------------------------------------------------------------------
frontend wallix_https
    bind 10.10.1.100:443
    mode tcp
    option tcplog
    default_backend wallix_https_backend

    # Connection limits
    maxconn 2000

backend wallix_https_backend
    mode tcp
    balance roundrobin
    option tcp-check
    option log-health-checks

    # Single Bastion node in lab (no Active-Active cluster)
    server wallix-bastion 10.10.1.11:443 check inter 5s rise 2 fall 3 maxconn 1000

#---------------------------------------------------------------------
# WALLIX Bastion SSH Proxy Frontend
#---------------------------------------------------------------------
frontend wallix_ssh
    bind 10.10.1.100:22
    mode tcp
    option tcplog
    default_backend wallix_ssh_backend

    # SSH connection limits
    maxconn 500

backend wallix_ssh_backend
    mode tcp
    balance leastconn
    option tcp-check
    option log-health-checks

    # Single Bastion node in lab
    server wallix-bastion 10.10.1.11:22 check inter 5s rise 2 fall 3

#---------------------------------------------------------------------
# WALLIX Bastion RDP Proxy Frontend
#---------------------------------------------------------------------
frontend wallix_rdp
    bind 10.10.1.100:3389
    mode tcp
    option tcplog
    default_backend wallix_rdp_backend

    # RDP connection limits
    maxconn 500

backend wallix_rdp_backend
    mode tcp
    balance leastconn
    option tcp-check
    option log-health-checks

    # Single Bastion node in lab
    server wallix-bastion 10.10.1.11:3389 check inter 5s rise 2 fall 3

#---------------------------------------------------------------------
# WALLIX Bastion HTTP Redirect
#---------------------------------------------------------------------
frontend wallix_http
    bind 10.10.1.100:80
    mode http
    http-request redirect scheme https code 301

#---------------------------------------------------------------------
# Prometheus Metrics (Optional)
#---------------------------------------------------------------------
frontend prometheus
    bind *:8405
    mode http
    http-request use-service prometheus-exporter if { path /metrics }

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
    dns-nameservers 10.10.1.60
    dns-search lab.local
EOF

systemctl restart networking

# Update /etc/hosts (same as node 1)
cat >> /etc/hosts << 'EOF'
10.10.1.5   haproxy-1.lab.local haproxy-1
10.10.1.6   haproxy-2.lab.local haproxy-2
10.10.1.11  wallix-bastion.lab.local wallix-bastion
10.10.1.100 wallix.lab.local wallix
10.10.1.60  dc-lab.lab.local dc-lab
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
cat /etc/ssl/certs/wallix.crt /etc/ssl/private/wallix.key > /etc/haproxy/wallix.pem

# Update frontend to use SSL
frontend wallix_https
    bind *:443 ssl crt /etc/haproxy/wallix.pem
    mode http
    # ... rest of config
```

---

## Troubleshooting

| Issue | Check | Solution |
|-------|-------|----------|
| VIP not assigned | `ip addr show` | Check Keepalived config, priority |
| HAProxy not starting | `journalctl -u haproxy` | Check config syntax: `haproxy -c -f /etc/haproxy/haproxy.cfg` |
| Backends down | Stats page | Check WALLIX Bastion nodes are running |
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
| 22 | SSH Proxy (to WALLIX Bastion) |
| 80 | HTTP Redirect |
| 443 | HTTPS Web UI |
| 3389 | RDP Proxy |
| 8404 | HAProxy Stats |

---

---

# Option B — FortiGate Virtual IP Load Balancing

## Architecture

```
+===============================================================================+
|               FORTIGATE VIP LOAD BALANCING ARCHITECTURE                       |
+===============================================================================+
|                                                                               |
|                            USERS / OPERATORS                                  |
|                                   |                                           |
|                                   v                                           |
|                          VIP: 10.10.1.100                                     |
|                     (FortiGate Virtual Server)                                |
|                                   |                                           |
|                    +==============+===============+                            |
|                    |       FortiGate Firewall     |                            |
|                    |        10.10.1.1             |                            |
|                    |   Virtual Server + Health    |                            |
|                    |   Monitor (TCP checks)       |                            |
|                    +==============+===============+                            |
|                                   |                                           |
|                                   |                                           |
|                         +-----------------+                                  |
|                         | WALLIX Bastion  |                                  |
|                         | (single node)   |                                  |
|                         | 10.10.1.11      |                                  |
|                         +-----------------+                                  |
|                                                                               |
+===============================================================================+
```

This option uses the FortiGate firewall as a Layer 4 load balancer via Virtual IPs, eliminating the need for separate HAProxy/Keepalived VMs.

---

## Prerequisites

- FortiGate firewall already deployed at site (FortiGate 100F/200F or equivalent)
- FortiOS 7.2+ recommended
- VIP address reserved (10.10.1.100) — same VIP as the HAProxy option
- Admin access to FortiGate CLI or GUI

---

## Step 1: Create Health Check Monitors

Health monitors verify that each Bastion node is responding before sending traffic to it.

### Via CLI

```bash
# HTTPS health check (Web UI / API)
config firewall ldb-monitor
    edit "wallix-https-monitor"
        set type tcp
        set interval 5
        set port 443
        set retry 3
        set timeout 2
    next

    # SSH health check
    edit "wallix-ssh-monitor"
        set type tcp
        set interval 5
        set port 22
        set retry 3
        set timeout 2
    next

    # RDP health check
    edit "wallix-rdp-monitor"
        set type tcp
        set interval 5
        set port 3389
        set retry 3
        set timeout 2
    next
end
```

### Via GUI

1. Go to **Policy & Objects > Health Check**
2. Create New:
   - **Name**: `wallix-https-monitor`
   - **Type**: TCP
   - **Port**: 443
   - **Interval**: 5 seconds
   - **Timeout**: 2 seconds
   - **Retry**: 3
3. Repeat for SSH (port 22) and RDP (port 3389)

---

## Step 2: Create Real Server Pool

Define the two WALLIX Bastion backend nodes.

```bash
# Single Bastion node in lab
config firewall real-server
    edit 1
        set ip 10.10.1.11
        set port 443
        set status active
        set health-check enable
        set holddown-interval 30
    next
end
```

---

## Step 3: Configure Virtual IPs

### HTTPS Virtual IP (Port 443)

```bash
config firewall vip
    edit "wallix-vip-https"
        set type server-load-balance
        set extip 10.10.1.100
        set extintf "internal"
        set server-type tcp
        set extport 443
        set ldb-method round-robin
        set persistence source-ip
        set monitor "wallix-https-monitor"

        # Single Bastion node in lab
        config realservers
            edit 1
                set ip 10.10.1.11
                set port 443
                set status active
                set weight 100
                set max-connections 1000
                set health-check inherit
            next
        end
    next
end
```

### SSH Virtual IP (Port 22)

```bash
config firewall vip
    edit "wallix-vip-ssh"
        set type server-load-balance
        set extip 10.10.1.100
        set extintf "internal"
        set server-type tcp
        set extport 22
        set ldb-method least-session
        set persistence source-ip
        set monitor "wallix-ssh-monitor"

        # Single Bastion node in lab
        config realservers
            edit 1
                set ip 10.10.1.11
                set port 22
                set status active
                set weight 100
                set health-check inherit
            next
        end
    next
end
```

### RDP Virtual IP (Port 3389)

```bash
config firewall vip
    edit "wallix-vip-rdp"
        set type server-load-balance
        set extip 10.10.1.100
        set extintf "internal"
        set server-type tcp
        set extport 3389
        set ldb-method least-session
        set persistence source-ip
        set monitor "wallix-rdp-monitor"

        # Single Bastion node in lab
        config realservers
            edit 1
                set ip 10.10.1.11
                set port 3389
                set status active
                set weight 100
                set health-check inherit
            next
        end
    next
end
```

### HTTP Redirect (Port 80 → 443)

```bash
config firewall vip
    edit "wallix-vip-http-redirect"
        set type server-load-balance
        set extip 10.10.1.100
        set extintf "internal"
        set server-type tcp
        set extport 80
        set ldb-method round-robin
        set monitor "wallix-https-monitor"

        # Single Bastion node in lab
        config realservers
            edit 1
                set ip 10.10.1.11
                set port 443
                set status active
            next
        end
    next
end
```

---

## Step 4: Create Firewall Policies

Allow traffic from user networks to the Virtual IPs.

```bash
config firewall policy
    edit 0
        set name "Allow-WALLIX-VIP-HTTPS"
        set srcintf "internal"
        set dstintf "internal"
        set srcaddr "all"
        set dstaddr "wallix-vip-https"
        set action accept
        set schedule "always"
        set service "HTTPS"
        set logtraffic all
        set comments "WALLIX Bastion Web UI via VIP"
    next
    edit 0
        set name "Allow-WALLIX-VIP-SSH"
        set srcintf "internal"
        set dstintf "internal"
        set srcaddr "all"
        set dstaddr "wallix-vip-ssh"
        set action accept
        set schedule "always"
        set service "SSH"
        set logtraffic all
        set comments "WALLIX Bastion SSH Proxy via VIP"
    next
    edit 0
        set name "Allow-WALLIX-VIP-RDP"
        set srcintf "internal"
        set dstintf "internal"
        set srcaddr "all"
        set dstaddr "wallix-vip-rdp"
        set action accept
        set schedule "always"
        set service "RDP"
        set logtraffic all
        set comments "WALLIX Bastion RDP Proxy via VIP"
    next
end
```

> **Note**: Replace `"internal"` with the actual interface names for your site (e.g., `port1`, `lan`, `dmz`). Restrict `srcaddr` to specific admin/operator subnets in production.

---

## Step 5: Session Persistence Settings

FortiGate source-IP persistence ensures a user's session sticks to the same Bastion node (critical for SSH/RDP sessions).

```bash
# Adjust persistence timeout per VIP
config firewall vip
    edit "wallix-vip-ssh"
        set persistence source-ip
        set http-cookie-age 60
        # Source IP persistence timeout (minutes)
    next
    edit "wallix-vip-rdp"
        set persistence source-ip
    next
end
```

---

## Verification

### Check Virtual Server Status

```bash
# Via CLI
get firewall vip

# Detailed status of a specific VIP
diagnose firewall vip list

# Check real server health
diagnose server-load-balance real-server list
```

### Via GUI

1. Go to **Policy & Objects > Virtual IPs**
2. Check each VIP shows both real servers as **Up** (green)
3. Go to **FortiView > All Sessions** to monitor active connections

### Test Connectivity

```bash
# From a client machine, test through the VIP
curl -k https://10.10.1.100/
ssh -o ConnectTimeout=5 test@10.10.1.100
```

### Test Failover

```bash
# 1. Verify both backends are active
diagnose server-load-balance real-server list

# 2. Shutdown WALLIX Node 1 (or block port 443)
# On the Bastion node:
#   systemctl stop wabcore

# 3. Verify FortiGate detects the failure
diagnose server-load-balance real-server list
# Node 1 should show as DOWN after health check timeout

# 4. Test services still work through VIP
curl -k https://10.10.1.100/

# 5. Restart Node 1 and verify it rejoins the pool
#   systemctl start wabcore
diagnose server-load-balance real-server list
```

---

## Monitoring

### FortiGate SNMP Monitoring

```bash
config system snmp sysinfo
    set status enable
end

config system snmp community
    edit 1
        set name "wallix-monitoring"
        set events cpu-high mem-low
        config hosts
            edit 1
                set ip 10.10.0.50 255.255.255.255
            next
        end
    next
end
```

### Log Monitoring

```bash
# Check load balancer related logs
execute log filter category traffic
execute log filter field dstaddr 10.10.1.100
execute log display
```

---

## Troubleshooting

| Issue | Check | Solution |
|-------|-------|----------|
| VIP not responding | `diagnose firewall vip list` | Verify VIP config, check interface binding |
| Backend always DOWN | `diagnose server-load-balance real-server list` | Check health monitor, verify Bastion ports open |
| Asymmetric routing | `diagnose sniffer packet any 'host 10.10.1.100' 4` | Ensure return path goes through FortiGate |
| Session drops on failover | Check persistence config | Enable source-ip persistence on VIP |
| Uneven distribution | `diagnose server-load-balance service list` | Check weights, verify ldb-method |

---

## Comparison: HAProxy vs FortiGate VIP

| Feature | HAProxy + Keepalived | FortiGate VIP |
|---------|---------------------|---------------|
| **Extra VMs** | 2 per site | None |
| **HA** | VRRP (active-passive) | Built into FortiGate HA |
| **Layer 7 features** | Full (headers, cookies, ACLs) | Limited (TCP only) |
| **SSL termination** | Yes | Yes (with inspection license) |
| **Health checks** | Advanced (HTTP content match) | TCP / ICMP / HTTP basic |
| **Stats/metrics** | Built-in stats page, Prometheus | FortiView, SNMP, syslog |
| **Best for** | Complex routing, full visibility | Simple LB, minimal infra |

---

## Quick Reference

| VIP Name | Port | LB Method | Backends (lab: single node) |
|----------|------|-----------|----------|
| wallix-vip-https | 443 | round-robin | 10.10.1.11 |
| wallix-vip-ssh | 22 | least-session | 10.10.1.11 |
| wallix-vip-rdp | 3389 | least-session | 10.10.1.11 |
| wallix-vip-http-redirect | 80 → 443 | round-robin | 10.10.1.11 |

*Last updated: April 2026 | WALLIX Bastion 12.1.x | HAProxy backend: single Bastion node (10.10.1.11)*

---

<p align="center">
  <a href="./02-active-directory-setup.md">← Previous: Active Directory Setup</a> •
  <a href="./04-fortiauthenticator-setup.md">Next: FortiAuthenticator MFA Setup →</a>
</p>
