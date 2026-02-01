# 42 - Load Balancer Configuration Guide

## Table of Contents

1. [Load Balancing Overview](#load-balancing-overview)
2. [Architecture Patterns](#architecture-patterns)
3. [HAProxy Configuration](#haproxy-configuration)
4. [Nginx Configuration](#nginx-configuration)
5. [F5 BIG-IP Configuration](#f5-big-ip-configuration)
6. [AWS ALB/NLB Configuration](#aws-albnlb-configuration)
7. [Azure Load Balancer](#azure-load-balancer)
8. [Health Check Configuration](#health-check-configuration)
9. [SSL/TLS Best Practices](#ssltls-best-practices)
10. [Troubleshooting](#troubleshooting)

---

## Load Balancing Overview

### Why Load Balancing for WALLIX Bastion

Load balancing provides high availability, scalability, and optimal performance for WALLIX Bastion deployments. A properly configured load balancer ensures:

| Benefit | Description |
|---------|-------------|
| **High Availability** | Automatic failover when nodes become unhealthy |
| **Scalability** | Distribute load across multiple Bastion nodes |
| **Performance** | Optimize response times through intelligent routing |
| **Maintenance** | Perform rolling updates without downtime |
| **SSL Offloading** | Centralize certificate management |

### Traffic Types

WALLIX Bastion handles multiple traffic types requiring different load balancing strategies:

```
+===========================================================================+
|                     WALLIX BASTION TRAFFIC TYPES                          |
+===========================================================================+
|                                                                           |
|   TRAFFIC TYPE        PROTOCOL    PORT    LB MODE    SESSION AFFINITY    |
|   ============        ========    ====    =======    ================    |
|                                                                           |
|   Web Administration   HTTPS      443     Layer 7    Cookie-based        |
|   REST API             HTTPS      443     Layer 7    None (stateless)    |
|   WebSocket Console    WSS        443     Layer 7    Required            |
|   SSH Proxy            TCP        22      Layer 4    Source IP hash      |
|   RDP Proxy            TCP        3389    Layer 4    Source IP hash      |
|   VNC Proxy            TCP        5900    Layer 4    Source IP hash      |
|   Telnet Proxy         TCP        23      Layer 4    Source IP hash      |
|                                                                           |
+===========================================================================+
```

### Load Balancer Placement

```
+===========================================================================+
|                    LOAD BALANCER PLACEMENT OPTIONS                        |
+===========================================================================+
|                                                                           |
|   OPTION 1: Single Load Balancer (Most Common)                           |
|   ============================================                            |
|                                                                           |
|                         +------------------+                              |
|                         |  Load Balancer   |                              |
|                         |  (HAProxy/F5/    |                              |
|                         |   AWS ALB/NLB)   |                              |
|                         +--------+---------+                              |
|                                  |                                        |
|                    +-------------+-------------+                          |
|                    |             |             |                          |
|                    v             v             v                          |
|              +---------+   +---------+   +---------+                      |
|              | Bastion |   | Bastion |   | Bastion |                      |
|              | Node 1  |   | Node 2  |   | Node 3  |                      |
|              +---------+   +---------+   +---------+                      |
|                                                                           |
|   OPTION 2: HA Load Balancer Pair                                        |
|   ================================                                        |
|                                                                           |
|                    +------------------+                                   |
|                    |   Virtual IP     |                                   |
|                    |   (Keepalived)   |                                   |
|                    +--------+---------+                                   |
|                             |                                             |
|              +--------------+--------------+                              |
|              |                             |                              |
|              v                             v                              |
|        +-----------+               +-----------+                          |
|        |    LB 1   |<=============>|    LB 2   |                          |
|        |  (Active) |   VRRP/CARP   | (Standby) |                          |
|        +-----+-----+               +-----------+                          |
|              |                                                            |
|    +---------+---------+---------+                                        |
|    |         |         |         |                                        |
|    v         v         v         v                                        |
| +------+ +------+ +------+ +------+                                       |
| |Node 1| |Node 2| |Node 3| |Node 4|                                       |
| +------+ +------+ +------+ +------+                                       |
|                                                                           |
+===========================================================================+
```

---

## Architecture Patterns

### Layer 4 vs Layer 7 Load Balancing

```
+===========================================================================+
|                      L4 vs L7 LOAD BALANCING                              |
+===========================================================================+
|                                                                           |
|   LAYER 4 (Transport Layer)                                               |
|   =========================                                               |
|                                                                           |
|   +----------+        +----------+        +----------+                    |
|   |  Client  |  TCP   |   L4 LB  |  TCP   |  Server  |                    |
|   |          |------->|          |------->|          |                    |
|   +----------+        +----------+        +----------+                    |
|                                                                           |
|   Characteristics:                                                        |
|   * Operates on IP address and TCP/UDP port                              |
|   * Fast, low latency                                                    |
|   * Cannot inspect HTTP content                                          |
|   * Uses source IP hash for session persistence                          |
|   * Best for: SSH, RDP, VNC, Telnet traffic                              |
|                                                                           |
|   --------------------------------------------------------------------------
|                                                                           |
|   LAYER 7 (Application Layer)                                             |
|   ===========================                                             |
|                                                                           |
|   +----------+        +----------+        +----------+                    |
|   |  Client  | HTTPS  |   L7 LB  |  HTTP  |  Server  |                    |
|   |          |------->|          |------->|          |                    |
|   +----------+   |    +----------+        +----------+                    |
|                  |         |                                              |
|                  |    SSL Termination                                     |
|                  |    Content Inspection                                  |
|                  |    Cookie Insertion                                    |
|                  |    URL Routing                                         |
|                                                                           |
|   Characteristics:                                                        |
|   * Operates on HTTP/HTTPS content                                       |
|   * SSL termination and re-encryption                                    |
|   * Cookie-based session affinity                                        |
|   * URL path-based routing                                               |
|   * Best for: Web UI, REST API, WebSocket                                |
|                                                                           |
+===========================================================================+
```

### Active-Passive vs Active-Active

```
+===========================================================================+
|                    ACTIVE-PASSIVE ARCHITECTURE                            |
+===========================================================================+
|                                                                           |
|                         +-----------------+                               |
|                         |   Virtual IP    |                               |
|                         |   10.0.1.100    |                               |
|                         +--------+--------+                               |
|                                  |                                        |
|                                  v                                        |
|                    +-------------+-------------+                          |
|                    |                           |                          |
|               +----+----+                 +----+----+                     |
|               |         |                 |         |                     |
|               | Node 1  |   Heartbeat     | Node 2  |                     |
|               | ACTIVE  |<===============>| STANDBY |                     |
|               |         |                 |         |                     |
|               +---------+                 +---------+                     |
|                    |                                                      |
|               All traffic                     Idle                        |
|                                                                           |
|   VIP moves to standby on failure                                        |
|   Failover time: 30-60 seconds                                           |
|   Simple configuration                                                    |
|   Underutilized standby resources                                        |
|                                                                           |
+===========================================================================+
|                     ACTIVE-ACTIVE ARCHITECTURE                            |
+===========================================================================+
|                                                                           |
|                         +-----------------+                               |
|                         |  Load Balancer  |                               |
|                         |   10.0.1.100    |                               |
|                         +--------+--------+                               |
|                                  |                                        |
|            +---------------------+---------------------+                  |
|            |                     |                     |                  |
|            v                     v                     v                  |
|       +---------+           +---------+           +---------+             |
|       |         |           |         |           |         |             |
|       | Node 1  |           | Node 2  |           | Node 3  |             |
|       | ACTIVE  |           | ACTIVE  |           | ACTIVE  |             |
|       |  33%    |           |  33%    |           |  34%    |             |
|       +---------+           +---------+           +---------+             |
|            |                     |                     |                  |
|       +----+---------------------+---------------------+----+             |
|       |              Shared Database/Storage                |             |
|       +-----------------------------------------------------+             |
|                                                                           |
|   All nodes serve traffic simultaneously                                  |
|   Instant failover (no VIP migration)                                    |
|   Better resource utilization                                            |
|   Requires session affinity for stateful connections                     |
|                                                                           |
+===========================================================================+
```

### Recommended Architecture

```
+===========================================================================+
|              RECOMMENDED: HYBRID L4/L7 ARCHITECTURE                       |
+===========================================================================+
|                                                                           |
|                              CLIENTS                                      |
|                                 |                                         |
|                                 v                                         |
|                    +------------------------+                             |
|                    |                        |                             |
|                    |   External Firewall    |                             |
|                    |                        |                             |
|                    +------------------------+                             |
|                         |            |                                    |
|            +------------+            +------------+                       |
|            |                                      |                       |
|            v                                      v                       |
|   +------------------+                   +------------------+             |
|   |   L7 LB (HTTP)   |                   |   L4 LB (TCP)    |             |
|   |   Port 443       |                   |   Ports 22,3389  |             |
|   |                  |                   |   5900,23        |             |
|   | * SSL Termination|                   |                  |             |
|   | * Cookie affinity|                   | * Source IP hash |             |
|   | * Health checks  |                   | * TCP health     |             |
|   | * WAF (optional) |                   |                  |             |
|   +--------+---------+                   +--------+---------+             |
|            |                                      |                       |
|            +------------------+-------------------+                       |
|                               |                                           |
|              +----------------+----------------+                          |
|              |                |                |                          |
|              v                v                v                          |
|         +---------+      +---------+      +---------+                     |
|         | WALLIX  |      | WALLIX  |      | WALLIX  |                     |
|         | Node 1  |      | Node 2  |      | Node 3  |                     |
|         +---------+      +---------+      +---------+                     |
|              |                |                |                          |
|              +----------------+----------------+                          |
|                               |                                           |
|                    +----------+----------+                                |
|                    |   PostgreSQL HA     |                                |
|                    |   (Primary/Replica) |                                |
|                    +---------------------+                                |
|                                                                           |
+===========================================================================+
```

---

## HAProxy Configuration

### Complete HAProxy Configuration

```bash
# /etc/haproxy/haproxy.cfg
# HAProxy Configuration for WALLIX Bastion 12.x
# Version: 2.8+ recommended

#------------------------------------------------------------------------------
# GLOBAL SETTINGS
#------------------------------------------------------------------------------
global
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

    # Security settings
    ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384
    ssl-default-bind-ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256
    ssl-default-bind-options ssl-min-ver TLSv1.2 no-tls-tickets
    ssl-default-server-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256
    ssl-default-server-options ssl-min-ver TLSv1.2 no-tls-tickets

    # Tune for high connection counts
    maxconn 50000
    tune.ssl.default-dh-param 2048

#------------------------------------------------------------------------------
# DEFAULT SETTINGS
#------------------------------------------------------------------------------
defaults
    log     global
    mode    http
    option  httplog
    option  dontlognull
    option  forwardfor
    option  http-server-close
    timeout connect 10s
    timeout client  60s
    timeout server  60s
    timeout http-request 10s
    timeout http-keep-alive 10s
    timeout queue 60s
    timeout tunnel 3600s
    timeout client-fin 30s
    timeout server-fin 30s

    # Error files
    errorfile 400 /etc/haproxy/errors/400.http
    errorfile 403 /etc/haproxy/errors/403.http
    errorfile 408 /etc/haproxy/errors/408.http
    errorfile 500 /etc/haproxy/errors/500.http
    errorfile 502 /etc/haproxy/errors/502.http
    errorfile 503 /etc/haproxy/errors/503.http
    errorfile 504 /etc/haproxy/errors/504.http

#------------------------------------------------------------------------------
# HTTPS FRONTEND (Layer 7 - Web UI and API)
#------------------------------------------------------------------------------
frontend wallix_https
    bind *:443 ssl crt /etc/haproxy/certs/wallix.pem alpn h2,http/1.1
    bind *:80
    mode http

    # Redirect HTTP to HTTPS
    http-request redirect scheme https unless { ssl_fc }

    # Security headers
    http-response set-header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
    http-response set-header X-Frame-Options "SAMEORIGIN"
    http-response set-header X-Content-Type-Options "nosniff"
    http-response set-header X-XSS-Protection "1; mode=block"
    http-response set-header Referrer-Policy "strict-origin-when-cross-origin"

    # Add X-Forwarded headers
    http-request set-header X-Forwarded-Proto https if { ssl_fc }
    http-request set-header X-Real-IP %[src]

    # ACLs for routing
    acl is_api path_beg /api/
    acl is_websocket hdr(Upgrade) -i websocket
    acl is_health path /health
    acl is_stats path_beg /haproxy-stats

    # Route based on path
    use_backend wallix_api if is_api
    use_backend wallix_websocket if is_websocket
    use_backend wallix_health if is_health
    use_backend haproxy_stats if is_stats

    # Default backend
    default_backend wallix_web

#------------------------------------------------------------------------------
# SSH FRONTEND (Layer 4 - SSH Proxy)
#------------------------------------------------------------------------------
frontend wallix_ssh
    bind *:22
    mode tcp
    option tcplog

    # Timeout for long-running SSH sessions
    timeout client 4h
    timeout server 4h

    default_backend wallix_ssh_nodes

#------------------------------------------------------------------------------
# RDP FRONTEND (Layer 4 - RDP Proxy)
#------------------------------------------------------------------------------
frontend wallix_rdp
    bind *:3389
    mode tcp
    option tcplog

    # Timeout for long-running RDP sessions
    timeout client 4h
    timeout server 4h

    default_backend wallix_rdp_nodes

#------------------------------------------------------------------------------
# VNC FRONTEND (Layer 4 - VNC Proxy)
#------------------------------------------------------------------------------
frontend wallix_vnc
    bind *:5900
    mode tcp
    option tcplog

    timeout client 4h
    timeout server 4h

    default_backend wallix_vnc_nodes

#------------------------------------------------------------------------------
# TELNET FRONTEND (Layer 4 - Telnet Proxy)
#------------------------------------------------------------------------------
frontend wallix_telnet
    bind *:23
    mode tcp
    option tcplog

    timeout client 1h
    timeout server 1h

    default_backend wallix_telnet_nodes

#------------------------------------------------------------------------------
# WEB BACKEND (Layer 7)
#------------------------------------------------------------------------------
backend wallix_web
    mode http
    balance roundrobin

    # Health check
    option httpchk GET /health HTTP/1.1\r\nHost:\ localhost
    http-check expect status 200

    # Session affinity using cookie
    cookie WALLIXSRV insert indirect nocache httponly secure

    # Backend servers with SSL verification
    server wallix-node1 10.0.1.11:443 ssl verify required ca-file /etc/haproxy/certs/ca.pem check inter 5s fall 3 rise 2 cookie node1
    server wallix-node2 10.0.1.12:443 ssl verify required ca-file /etc/haproxy/certs/ca.pem check inter 5s fall 3 rise 2 cookie node2
    server wallix-node3 10.0.1.13:443 ssl verify required ca-file /etc/haproxy/certs/ca.pem check inter 5s fall 3 rise 2 cookie node3

#------------------------------------------------------------------------------
# API BACKEND (Layer 7 - Stateless)
#------------------------------------------------------------------------------
backend wallix_api
    mode http
    balance leastconn

    # Health check
    option httpchk GET /api/health HTTP/1.1\r\nHost:\ localhost
    http-check expect status 200

    # No session affinity needed for stateless API
    server wallix-node1 10.0.1.11:443 ssl verify required ca-file /etc/haproxy/certs/ca.pem check inter 5s fall 3 rise 2
    server wallix-node2 10.0.1.12:443 ssl verify required ca-file /etc/haproxy/certs/ca.pem check inter 5s fall 3 rise 2
    server wallix-node3 10.0.1.13:443 ssl verify required ca-file /etc/haproxy/certs/ca.pem check inter 5s fall 3 rise 2

#------------------------------------------------------------------------------
# WEBSOCKET BACKEND (Layer 7 - Session Required)
#------------------------------------------------------------------------------
backend wallix_websocket
    mode http
    balance source

    # WebSocket settings
    option http-server-close
    timeout tunnel 3600s

    # Health check
    option httpchk GET /health HTTP/1.1\r\nHost:\ localhost
    http-check expect status 200

    # Session affinity using source IP for WebSocket
    stick-table type ip size 100k expire 30m
    stick on src

    server wallix-node1 10.0.1.11:443 ssl verify required ca-file /etc/haproxy/certs/ca.pem check inter 5s fall 3 rise 2
    server wallix-node2 10.0.1.12:443 ssl verify required ca-file /etc/haproxy/certs/ca.pem check inter 5s fall 3 rise 2
    server wallix-node3 10.0.1.13:443 ssl verify required ca-file /etc/haproxy/certs/ca.pem check inter 5s fall 3 rise 2

#------------------------------------------------------------------------------
# HEALTH CHECK BACKEND
#------------------------------------------------------------------------------
backend wallix_health
    mode http
    balance roundrobin

    server wallix-node1 10.0.1.11:443 ssl verify none check inter 2s
    server wallix-node2 10.0.1.12:443 ssl verify none check inter 2s
    server wallix-node3 10.0.1.13:443 ssl verify none check inter 2s

#------------------------------------------------------------------------------
# SSH BACKEND (Layer 4)
#------------------------------------------------------------------------------
backend wallix_ssh_nodes
    mode tcp
    balance source

    # TCP health check
    option tcp-check
    tcp-check connect port 22

    # Stick table for session persistence
    stick-table type ip size 100k expire 4h
    stick on src

    server wallix-node1 10.0.1.11:22 check inter 10s fall 3 rise 2
    server wallix-node2 10.0.1.12:22 check inter 10s fall 3 rise 2
    server wallix-node3 10.0.1.13:22 check inter 10s fall 3 rise 2

#------------------------------------------------------------------------------
# RDP BACKEND (Layer 4)
#------------------------------------------------------------------------------
backend wallix_rdp_nodes
    mode tcp
    balance source

    # TCP health check
    option tcp-check
    tcp-check connect port 3389

    # Stick table for session persistence
    stick-table type ip size 100k expire 4h
    stick on src

    server wallix-node1 10.0.1.11:3389 check inter 10s fall 3 rise 2
    server wallix-node2 10.0.1.12:3389 check inter 10s fall 3 rise 2
    server wallix-node3 10.0.1.13:3389 check inter 10s fall 3 rise 2

#------------------------------------------------------------------------------
# VNC BACKEND (Layer 4)
#------------------------------------------------------------------------------
backend wallix_vnc_nodes
    mode tcp
    balance source

    option tcp-check
    tcp-check connect port 5900

    stick-table type ip size 100k expire 4h
    stick on src

    server wallix-node1 10.0.1.11:5900 check inter 10s fall 3 rise 2
    server wallix-node2 10.0.1.12:5900 check inter 10s fall 3 rise 2
    server wallix-node3 10.0.1.13:5900 check inter 10s fall 3 rise 2

#------------------------------------------------------------------------------
# TELNET BACKEND (Layer 4)
#------------------------------------------------------------------------------
backend wallix_telnet_nodes
    mode tcp
    balance source

    option tcp-check
    tcp-check connect port 23

    stick-table type ip size 50k expire 1h
    stick on src

    server wallix-node1 10.0.1.11:23 check inter 10s fall 3 rise 2
    server wallix-node2 10.0.1.12:23 check inter 10s fall 3 rise 2
    server wallix-node3 10.0.1.13:23 check inter 10s fall 3 rise 2

#------------------------------------------------------------------------------
# STATS PAGE
#------------------------------------------------------------------------------
backend haproxy_stats
    mode http
    stats enable
    stats uri /haproxy-stats
    stats refresh 10s
    stats auth admin:SecurePassword123!
    stats admin if TRUE
    stats show-legends
    stats show-node
```

### HAProxy SSL Certificate Setup

```bash
# Create combined PEM file for HAProxy
# Certificate chain order: server cert, intermediate(s), root CA
cat /etc/ssl/certs/wallix.crt \
    /etc/ssl/certs/intermediate.crt \
    /etc/ssl/private/wallix.key > /etc/haproxy/certs/wallix.pem

# Set permissions
chmod 600 /etc/haproxy/certs/wallix.pem
chown haproxy:haproxy /etc/haproxy/certs/wallix.pem

# Validate configuration
haproxy -c -f /etc/haproxy/haproxy.cfg

# Reload HAProxy
systemctl reload haproxy
```

---

## Nginx Configuration

### Complete Nginx Configuration

```nginx
# /etc/nginx/nginx.conf
# Nginx Configuration for WALLIX Bastion 12.x Load Balancing

user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 4096;
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Logging format
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for" '
                    'rt=$request_time uct="$upstream_connect_time" '
                    'uht="$upstream_header_time" urt="$upstream_response_time"';

    log_format json escape=json '{'
        '"time":"$time_iso8601",'
        '"remote_addr":"$remote_addr",'
        '"request":"$request",'
        '"status":$status,'
        '"body_bytes_sent":$body_bytes_sent,'
        '"request_time":$request_time,'
        '"upstream_response_time":"$upstream_response_time",'
        '"upstream_addr":"$upstream_addr"'
    '}';

    access_log /var/log/nginx/access.log main;

    # Performance settings
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml application/json application/javascript
               application/xml application/xml+rss text/javascript;

    # SSL Settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:50m;
    ssl_session_timeout 1d;
    ssl_session_tickets off;
    ssl_stapling on;
    ssl_stapling_verify on;

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api_limit:10m rate=100r/s;
    limit_conn_zone $binary_remote_addr zone=conn_limit:10m;

    #--------------------------------------------------------------------------
    # UPSTREAM DEFINITIONS
    #--------------------------------------------------------------------------

    # Web UI upstream (with session affinity)
    upstream wallix_web {
        ip_hash;
        server 10.0.1.11:443 weight=1 max_fails=3 fail_timeout=30s;
        server 10.0.1.12:443 weight=1 max_fails=3 fail_timeout=30s;
        server 10.0.1.13:443 weight=1 max_fails=3 fail_timeout=30s;
        keepalive 32;
    }

    # API upstream (round-robin, stateless)
    upstream wallix_api {
        least_conn;
        server 10.0.1.11:443 weight=1 max_fails=3 fail_timeout=30s;
        server 10.0.1.12:443 weight=1 max_fails=3 fail_timeout=30s;
        server 10.0.1.13:443 weight=1 max_fails=3 fail_timeout=30s;
        keepalive 64;
    }

    # WebSocket upstream (requires consistent hashing)
    upstream wallix_websocket {
        ip_hash;
        server 10.0.1.11:443 weight=1 max_fails=3 fail_timeout=30s;
        server 10.0.1.12:443 weight=1 max_fails=3 fail_timeout=30s;
        server 10.0.1.13:443 weight=1 max_fails=3 fail_timeout=30s;
        keepalive 16;
    }

    #--------------------------------------------------------------------------
    # HTTP to HTTPS REDIRECT
    #--------------------------------------------------------------------------
    server {
        listen 80;
        listen [::]:80;
        server_name wallix.company.com;

        # Redirect all HTTP to HTTPS
        return 301 https://$server_name$request_uri;
    }

    #--------------------------------------------------------------------------
    # HTTPS SERVER (Layer 7)
    #--------------------------------------------------------------------------
    server {
        listen 443 ssl http2;
        listen [::]:443 ssl http2;
        server_name wallix.company.com;

        # SSL certificates
        ssl_certificate /etc/nginx/ssl/wallix.crt;
        ssl_certificate_key /etc/nginx/ssl/wallix.key;
        ssl_trusted_certificate /etc/nginx/ssl/ca-chain.crt;

        # HSTS
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

        # Security headers
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header Referrer-Policy "strict-origin-when-cross-origin" always;

        # Client max body size for file uploads
        client_max_body_size 100M;

        # Health check endpoint (for external monitoring)
        location /nginx-health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }

        # Proxy health check endpoint
        location /health {
            proxy_pass https://wallix_web;
            proxy_ssl_verify on;
            proxy_ssl_trusted_certificate /etc/nginx/ssl/ca.crt;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # REST API endpoints
        location /api/ {
            limit_req zone=api_limit burst=50 nodelay;
            limit_conn conn_limit 100;

            proxy_pass https://wallix_api;
            proxy_ssl_verify on;
            proxy_ssl_trusted_certificate /etc/nginx/ssl/ca.crt;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header Connection "";

            # Timeouts
            proxy_connect_timeout 30s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;

            # Buffer settings
            proxy_buffering on;
            proxy_buffer_size 4k;
            proxy_buffers 8 16k;
        }

        # WebSocket endpoints
        location /ws/ {
            proxy_pass https://wallix_websocket;
            proxy_ssl_verify on;
            proxy_ssl_trusted_certificate /etc/nginx/ssl/ca.crt;
            proxy_http_version 1.1;

            # WebSocket headers
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;

            # WebSocket timeouts (longer for persistent connections)
            proxy_connect_timeout 30s;
            proxy_send_timeout 3600s;
            proxy_read_timeout 3600s;
        }

        # Web console (requires WebSocket support)
        location /webconsole/ {
            proxy_pass https://wallix_websocket;
            proxy_ssl_verify on;
            proxy_ssl_trusted_certificate /etc/nginx/ssl/ca.crt;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;

            proxy_connect_timeout 30s;
            proxy_send_timeout 3600s;
            proxy_read_timeout 3600s;
        }

        # Default location (Web UI)
        location / {
            proxy_pass https://wallix_web;
            proxy_ssl_verify on;
            proxy_ssl_trusted_certificate /etc/nginx/ssl/ca.crt;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header Connection "";

            # Cache static assets
            location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
                proxy_pass https://wallix_web;
                proxy_ssl_verify on;
                proxy_ssl_trusted_certificate /etc/nginx/ssl/ca.crt;
                expires 7d;
                add_header Cache-Control "public, immutable";
            }
        }
    }

    # Nginx status page (for monitoring)
    server {
        listen 127.0.0.1:8080;
        server_name localhost;

        location /nginx_status {
            stub_status on;
            access_log off;
            allow 127.0.0.1;
            deny all;
        }
    }
}

#------------------------------------------------------------------------------
# STREAM MODULE (Layer 4 - TCP Load Balancing)
#------------------------------------------------------------------------------
stream {
    log_format stream '$remote_addr [$time_local] $protocol $status '
                      '$bytes_sent $bytes_received $session_time '
                      '"$upstream_addr"';

    access_log /var/log/nginx/stream.log stream;

    # SSH upstream
    upstream wallix_ssh {
        hash $remote_addr consistent;
        server 10.0.1.11:22 weight=1 max_fails=3 fail_timeout=30s;
        server 10.0.1.12:22 weight=1 max_fails=3 fail_timeout=30s;
        server 10.0.1.13:22 weight=1 max_fails=3 fail_timeout=30s;
    }

    # RDP upstream
    upstream wallix_rdp {
        hash $remote_addr consistent;
        server 10.0.1.11:3389 weight=1 max_fails=3 fail_timeout=30s;
        server 10.0.1.12:3389 weight=1 max_fails=3 fail_timeout=30s;
        server 10.0.1.13:3389 weight=1 max_fails=3 fail_timeout=30s;
    }

    # VNC upstream
    upstream wallix_vnc {
        hash $remote_addr consistent;
        server 10.0.1.11:5900 weight=1 max_fails=3 fail_timeout=30s;
        server 10.0.1.12:5900 weight=1 max_fails=3 fail_timeout=30s;
        server 10.0.1.13:5900 weight=1 max_fails=3 fail_timeout=30s;
    }

    # SSH server
    server {
        listen 22;
        listen [::]:22;
        proxy_pass wallix_ssh;
        proxy_timeout 4h;
        proxy_connect_timeout 30s;
    }

    # RDP server
    server {
        listen 3389;
        listen [::]:3389;
        proxy_pass wallix_rdp;
        proxy_timeout 4h;
        proxy_connect_timeout 30s;
    }

    # VNC server
    server {
        listen 5900;
        listen [::]:5900;
        proxy_pass wallix_vnc;
        proxy_timeout 4h;
        proxy_connect_timeout 30s;
    }
}
```

### Nginx Verification Commands

```bash
# Test configuration
nginx -t

# Reload configuration
nginx -s reload

# Check upstream status
curl -s http://127.0.0.1:8080/nginx_status

# View error logs
tail -f /var/log/nginx/error.log
```

---

## F5 BIG-IP Configuration

### Virtual Server Configuration

```tcl
# F5 BIG-IP Configuration for WALLIX Bastion
# Version: BIG-IP 15.x / 16.x

#------------------------------------------------------------------------------
# NODES
#------------------------------------------------------------------------------
ltm node /Common/wallix-node1 {
    address 10.0.1.11
    monitor /Common/https_wallix
}

ltm node /Common/wallix-node2 {
    address 10.0.1.12
    monitor /Common/https_wallix
}

ltm node /Common/wallix-node3 {
    address 10.0.1.13
    monitor /Common/https_wallix
}

#------------------------------------------------------------------------------
# HEALTH MONITORS
#------------------------------------------------------------------------------
# HTTPS Monitor for Web/API
ltm monitor https /Common/https_wallix {
    adaptive disabled
    defaults-from /Common/https
    destination *:443
    interval 5
    ip-dscp 0
    recv "status.*healthy"
    recv-disable none
    send "GET /health HTTP/1.1\r\nHost: wallix.company.com\r\nConnection: close\r\n\r\n"
    time-until-up 0
    timeout 16
}

# TCP Monitor for SSH
ltm monitor tcp /Common/tcp_ssh {
    adaptive disabled
    defaults-from /Common/tcp
    destination *:22
    interval 10
    ip-dscp 0
    time-until-up 0
    timeout 31
}

# TCP Monitor for RDP
ltm monitor tcp /Common/tcp_rdp {
    adaptive disabled
    defaults-from /Common/tcp
    destination *:3389
    interval 10
    ip-dscp 0
    time-until-up 0
    timeout 31
}

#------------------------------------------------------------------------------
# POOLS
#------------------------------------------------------------------------------
# HTTPS Pool (Web UI and API)
ltm pool /Common/pool_wallix_https {
    load-balancing-mode round-robin
    members {
        /Common/wallix-node1:443 {
            address 10.0.1.11
            priority-group 1
        }
        /Common/wallix-node2:443 {
            address 10.0.1.12
            priority-group 1
        }
        /Common/wallix-node3:443 {
            address 10.0.1.13
            priority-group 1
        }
    }
    monitor /Common/https_wallix
    slow-ramp-time 10
}

# SSH Pool
ltm pool /Common/pool_wallix_ssh {
    load-balancing-mode least-connections-member
    members {
        /Common/wallix-node1:22 {
            address 10.0.1.11
        }
        /Common/wallix-node2:22 {
            address 10.0.1.12
        }
        /Common/wallix-node3:22 {
            address 10.0.1.13
        }
    }
    monitor /Common/tcp_ssh
}

# RDP Pool
ltm pool /Common/pool_wallix_rdp {
    load-balancing-mode least-connections-member
    members {
        /Common/wallix-node1:3389 {
            address 10.0.1.11
        }
        /Common/wallix-node2:3389 {
            address 10.0.1.12
        }
        /Common/wallix-node3:3389 {
            address 10.0.1.13
        }
    }
    monitor /Common/tcp_rdp
}

#------------------------------------------------------------------------------
# PERSISTENCE PROFILES
#------------------------------------------------------------------------------
# Cookie persistence for Web UI
ltm persistence cookie /Common/cookie_wallix {
    cookie-name WALLIXSRV
    defaults-from /Common/cookie
    expiration 0
    hash-length 0
    hash-offset 0
    match-across-pools disabled
    match-across-services disabled
    match-across-virtuals disabled
    method insert
    override-connection-limit disabled
    timeout 3600
}

# Source address persistence for SSH/RDP
ltm persistence source-addr /Common/source_wallix {
    defaults-from /Common/source_addr
    hash-algorithm default
    match-across-pools disabled
    match-across-services disabled
    match-across-virtuals disabled
    override-connection-limit disabled
    timeout 14400
}

#------------------------------------------------------------------------------
# SSL PROFILES
#------------------------------------------------------------------------------
# Client SSL Profile (Frontend)
ltm profile client-ssl /Common/clientssl_wallix {
    alert-timeout indefinite
    allow-expired-crl disabled
    cert /Common/wallix.company.com.crt
    cert-key-chain {
        wallix_chain {
            cert /Common/wallix.company.com.crt
            chain /Common/intermediate_ca.crt
            key /Common/wallix.company.com.key
        }
    }
    ciphers ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256
    defaults-from /Common/clientssl
    options { dont-insert-empty-fragments no-ssl no-tlsv1 no-tlsv1.1 }
    renegotiation enabled
}

# Server SSL Profile (Backend)
ltm profile server-ssl /Common/serverssl_wallix {
    ca-file /Common/internal_ca.crt
    cert /Common/f5_to_wallix.crt
    chain none
    ciphers DEFAULT
    defaults-from /Common/serverssl
    key /Common/f5_to_wallix.key
    options { dont-insert-empty-fragments }
    peer-cert-mode require
    server-name wallix.company.com
    sni-require true
}

#------------------------------------------------------------------------------
# IRULES
#------------------------------------------------------------------------------
# iRule for WebSocket support
ltm rule /Common/irule_websocket {
    when HTTP_REQUEST {
        if { [HTTP::header exists "Upgrade"] && [HTTP::header "Upgrade"] eq "websocket" } {
            HTTP::disable
            pool /Common/pool_wallix_https
        }
    }
}

# iRule for X-Forwarded headers
ltm rule /Common/irule_xff {
    when HTTP_REQUEST {
        HTTP::header remove X-Forwarded-For
        HTTP::header remove X-Real-IP
        HTTP::header insert X-Forwarded-For [IP::client_addr]
        HTTP::header insert X-Real-IP [IP::client_addr]
        HTTP::header insert X-Forwarded-Proto "https"
    }
}

#------------------------------------------------------------------------------
# VIRTUAL SERVERS
#------------------------------------------------------------------------------
# HTTPS Virtual Server (Web UI and API)
ltm virtual /Common/vs_wallix_https {
    destination /Common/10.0.1.100:443
    ip-protocol tcp
    mask 255.255.255.255
    persist {
        /Common/cookie_wallix {
            default yes
        }
    }
    pool /Common/pool_wallix_https
    profiles {
        /Common/clientssl_wallix {
            context clientside
        }
        /Common/serverssl_wallix {
            context serverside
        }
        /Common/http { }
        /Common/tcp { }
        /Common/websocket { }
    }
    rules {
        /Common/irule_xff
        /Common/irule_websocket
    }
    source 0.0.0.0/0
    source-address-translation {
        type automap
    }
    translate-address enabled
    translate-port enabled
}

# HTTP Redirect Virtual Server
ltm virtual /Common/vs_wallix_http_redirect {
    destination /Common/10.0.1.100:80
    ip-protocol tcp
    mask 255.255.255.255
    profiles {
        /Common/http { }
        /Common/tcp { }
    }
    rules {
        /Common/irule_http_redirect
    }
    source 0.0.0.0/0
}

# SSH Virtual Server (Layer 4)
ltm virtual /Common/vs_wallix_ssh {
    destination /Common/10.0.1.100:22
    ip-protocol tcp
    mask 255.255.255.255
    persist {
        /Common/source_wallix {
            default yes
        }
    }
    pool /Common/pool_wallix_ssh
    profiles {
        /Common/fastL4 { }
    }
    source 0.0.0.0/0
    source-address-translation {
        type automap
    }
    translate-address enabled
    translate-port enabled
}

# RDP Virtual Server (Layer 4)
ltm virtual /Common/vs_wallix_rdp {
    destination /Common/10.0.1.100:3389
    ip-protocol tcp
    mask 255.255.255.255
    persist {
        /Common/source_wallix {
            default yes
        }
    }
    pool /Common/pool_wallix_rdp
    profiles {
        /Common/fastL4 { }
    }
    source 0.0.0.0/0
    source-address-translation {
        type automap
    }
    translate-address enabled
    translate-port enabled
}
```

---

## AWS ALB/NLB Configuration

### Terraform Configuration for AWS

```hcl
# AWS Load Balancer Configuration for WALLIX Bastion
# terraform/aws-lb/main.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

#------------------------------------------------------------------------------
# VARIABLES
#------------------------------------------------------------------------------
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "vpc_id" {
  description = "VPC ID for the load balancer"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for ALB"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for NLB and targets"
  type        = list(string)
}

variable "wallix_instance_ids" {
  description = "List of WALLIX Bastion EC2 instance IDs"
  type        = list(string)
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

#------------------------------------------------------------------------------
# SECURITY GROUPS
#------------------------------------------------------------------------------
resource "aws_security_group" "alb" {
  name        = "wallix-alb-sg"
  description = "Security group for WALLIX ALB"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP redirect"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "wallix-alb-sg"
    Environment = var.environment
  }
}

resource "aws_security_group" "nlb" {
  name        = "wallix-nlb-sg"
  description = "Security group for WALLIX NLB targets"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from allowed networks"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  }

  ingress {
    description = "RDP from allowed networks"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "wallix-nlb-sg"
    Environment = var.environment
  }
}

#------------------------------------------------------------------------------
# APPLICATION LOAD BALANCER (Layer 7 - HTTPS)
#------------------------------------------------------------------------------
resource "aws_lb" "wallix_alb" {
  name               = "wallix-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = true
  enable_http2               = true

  access_logs {
    bucket  = aws_s3_bucket.alb_logs.id
    prefix  = "wallix-alb"
    enabled = true
  }

  tags = {
    Name        = "wallix-alb"
    Environment = var.environment
  }
}

# HTTPS Target Group
resource "aws_lb_target_group" "wallix_https" {
  name                 = "wallix-https-tg"
  port                 = 443
  protocol             = "HTTPS"
  vpc_id               = var.vpc_id
  target_type          = "instance"
  deregistration_delay = 30

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 15
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTPS"
    timeout             = 10
    unhealthy_threshold = 3
  }

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 3600
    enabled         = true
  }

  tags = {
    Name        = "wallix-https-tg"
    Environment = var.environment
  }
}

# Target Group Attachments
resource "aws_lb_target_group_attachment" "wallix_https" {
  count            = length(var.wallix_instance_ids)
  target_group_arn = aws_lb_target_group.wallix_https.arn
  target_id        = var.wallix_instance_ids[count.index]
  port             = 443
}

# HTTP Listener (Redirect to HTTPS)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.wallix_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# HTTPS Listener
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.wallix_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wallix_https.arn
  }
}

# WebSocket path-based routing rule
resource "aws_lb_listener_rule" "websocket" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wallix_https.arn
  }

  condition {
    path_pattern {
      values = ["/ws/*", "/webconsole/*"]
    }
  }
}

#------------------------------------------------------------------------------
# NETWORK LOAD BALANCER (Layer 4 - SSH/RDP)
#------------------------------------------------------------------------------
resource "aws_lb" "wallix_nlb" {
  name               = "wallix-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = var.public_subnet_ids

  enable_deletion_protection = true
  enable_cross_zone_load_balancing = true

  tags = {
    Name        = "wallix-nlb"
    Environment = var.environment
  }
}

# SSH Target Group
resource "aws_lb_target_group" "wallix_ssh" {
  name                 = "wallix-ssh-tg"
  port                 = 22
  protocol             = "TCP"
  vpc_id               = var.vpc_id
  target_type          = "instance"
  deregistration_delay = 30
  preserve_client_ip   = true

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    port                = "traffic-port"
    protocol            = "TCP"
    unhealthy_threshold = 3
  }

  stickiness {
    enabled = true
    type    = "source_ip"
  }

  tags = {
    Name        = "wallix-ssh-tg"
    Environment = var.environment
  }
}

# RDP Target Group
resource "aws_lb_target_group" "wallix_rdp" {
  name                 = "wallix-rdp-tg"
  port                 = 3389
  protocol             = "TCP"
  vpc_id               = var.vpc_id
  target_type          = "instance"
  deregistration_delay = 30
  preserve_client_ip   = true

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    port                = "traffic-port"
    protocol            = "TCP"
    unhealthy_threshold = 3
  }

  stickiness {
    enabled = true
    type    = "source_ip"
  }

  tags = {
    Name        = "wallix-rdp-tg"
    Environment = var.environment
  }
}

# SSH Target Group Attachments
resource "aws_lb_target_group_attachment" "wallix_ssh" {
  count            = length(var.wallix_instance_ids)
  target_group_arn = aws_lb_target_group.wallix_ssh.arn
  target_id        = var.wallix_instance_ids[count.index]
  port             = 22
}

# RDP Target Group Attachments
resource "aws_lb_target_group_attachment" "wallix_rdp" {
  count            = length(var.wallix_instance_ids)
  target_group_arn = aws_lb_target_group.wallix_rdp.arn
  target_id        = var.wallix_instance_ids[count.index]
  port             = 3389
}

# SSH Listener
resource "aws_lb_listener" "ssh" {
  load_balancer_arn = aws_lb.wallix_nlb.arn
  port              = "22"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wallix_ssh.arn
  }
}

# RDP Listener
resource "aws_lb_listener" "rdp" {
  load_balancer_arn = aws_lb.wallix_nlb.arn
  port              = "3389"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wallix_rdp.arn
  }
}

#------------------------------------------------------------------------------
# S3 BUCKET FOR ALB LOGS
#------------------------------------------------------------------------------
resource "aws_s3_bucket" "alb_logs" {
  bucket = "wallix-alb-logs-${var.environment}"

  tags = {
    Name        = "wallix-alb-logs"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    id     = "log-retention"
    status = "Enabled"

    expiration {
      days = 90
    }
  }
}

#------------------------------------------------------------------------------
# OUTPUTS
#------------------------------------------------------------------------------
output "alb_dns_name" {
  description = "ALB DNS name for HTTPS access"
  value       = aws_lb.wallix_alb.dns_name
}

output "nlb_dns_name" {
  description = "NLB DNS name for SSH/RDP access"
  value       = aws_lb.wallix_nlb.dns_name
}

output "alb_zone_id" {
  description = "ALB Zone ID for Route53"
  value       = aws_lb.wallix_alb.zone_id
}

output "nlb_zone_id" {
  description = "NLB Zone ID for Route53"
  value       = aws_lb.wallix_nlb.zone_id
}
```

---

## Azure Load Balancer

### Azure Resource Manager Template

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "location": {
      "type": "string",
      "defaultValue": "[resourceGroup().location]"
    },
    "publicIpName": {
      "type": "string",
      "defaultValue": "wallix-lb-pip"
    },
    "lbName": {
      "type": "string",
      "defaultValue": "wallix-lb"
    },
    "backendVmIds": {
      "type": "array",
      "metadata": {
        "description": "Array of WALLIX VM resource IDs"
      }
    }
  },
  "resources": [
    {
      "type": "Microsoft.Network/publicIPAddresses",
      "apiVersion": "2023-05-01",
      "name": "[parameters('publicIpName')]",
      "location": "[parameters('location')]",
      "sku": {
        "name": "Standard"
      },
      "properties": {
        "publicIPAllocationMethod": "Static",
        "dnsSettings": {
          "domainNameLabel": "wallix-bastion"
        }
      }
    },
    {
      "type": "Microsoft.Network/loadBalancers",
      "apiVersion": "2023-05-01",
      "name": "[parameters('lbName')]",
      "location": "[parameters('location')]",
      "sku": {
        "name": "Standard"
      },
      "dependsOn": [
        "[resourceId('Microsoft.Network/publicIPAddresses', parameters('publicIpName'))]"
      ],
      "properties": {
        "frontendIPConfigurations": [
          {
            "name": "LoadBalancerFrontEnd",
            "properties": {
              "publicIPAddress": {
                "id": "[resourceId('Microsoft.Network/publicIPAddresses', parameters('publicIpName'))]"
              }
            }
          }
        ],
        "backendAddressPools": [
          {
            "name": "wallix-backend-pool"
          }
        ],
        "probes": [
          {
            "name": "https-probe",
            "properties": {
              "protocol": "Https",
              "port": 443,
              "requestPath": "/health",
              "intervalInSeconds": 15,
              "numberOfProbes": 2
            }
          },
          {
            "name": "ssh-probe",
            "properties": {
              "protocol": "Tcp",
              "port": 22,
              "intervalInSeconds": 15,
              "numberOfProbes": 2
            }
          },
          {
            "name": "rdp-probe",
            "properties": {
              "protocol": "Tcp",
              "port": 3389,
              "intervalInSeconds": 15,
              "numberOfProbes": 2
            }
          }
        ],
        "loadBalancingRules": [
          {
            "name": "https-rule",
            "properties": {
              "frontendIPConfiguration": {
                "id": "[concat(resourceId('Microsoft.Network/loadBalancers', parameters('lbName')), '/frontendIPConfigurations/LoadBalancerFrontEnd')]"
              },
              "backendAddressPool": {
                "id": "[concat(resourceId('Microsoft.Network/loadBalancers', parameters('lbName')), '/backendAddressPools/wallix-backend-pool')]"
              },
              "probe": {
                "id": "[concat(resourceId('Microsoft.Network/loadBalancers', parameters('lbName')), '/probes/https-probe')]"
              },
              "protocol": "Tcp",
              "frontendPort": 443,
              "backendPort": 443,
              "enableFloatingIP": false,
              "idleTimeoutInMinutes": 30,
              "loadDistribution": "SourceIPProtocol",
              "disableOutboundSnat": true
            }
          },
          {
            "name": "ssh-rule",
            "properties": {
              "frontendIPConfiguration": {
                "id": "[concat(resourceId('Microsoft.Network/loadBalancers', parameters('lbName')), '/frontendIPConfigurations/LoadBalancerFrontEnd')]"
              },
              "backendAddressPool": {
                "id": "[concat(resourceId('Microsoft.Network/loadBalancers', parameters('lbName')), '/backendAddressPools/wallix-backend-pool')]"
              },
              "probe": {
                "id": "[concat(resourceId('Microsoft.Network/loadBalancers', parameters('lbName')), '/probes/ssh-probe')]"
              },
              "protocol": "Tcp",
              "frontendPort": 22,
              "backendPort": 22,
              "enableFloatingIP": false,
              "idleTimeoutInMinutes": 30,
              "loadDistribution": "SourceIP",
              "disableOutboundSnat": true
            }
          },
          {
            "name": "rdp-rule",
            "properties": {
              "frontendIPConfiguration": {
                "id": "[concat(resourceId('Microsoft.Network/loadBalancers', parameters('lbName')), '/frontendIPConfigurations/LoadBalancerFrontEnd')]"
              },
              "backendAddressPool": {
                "id": "[concat(resourceId('Microsoft.Network/loadBalancers', parameters('lbName')), '/backendAddressPools/wallix-backend-pool')]"
              },
              "probe": {
                "id": "[concat(resourceId('Microsoft.Network/loadBalancers', parameters('lbName')), '/probes/rdp-probe')]"
              },
              "protocol": "Tcp",
              "frontendPort": 3389,
              "backendPort": 3389,
              "enableFloatingIP": false,
              "idleTimeoutInMinutes": 30,
              "loadDistribution": "SourceIP",
              "disableOutboundSnat": true
            }
          }
        ],
        "outboundRules": [
          {
            "name": "outbound-rule",
            "properties": {
              "frontendIPConfigurations": [
                {
                  "id": "[concat(resourceId('Microsoft.Network/loadBalancers', parameters('lbName')), '/frontendIPConfigurations/LoadBalancerFrontEnd')]"
                }
              ],
              "backendAddressPool": {
                "id": "[concat(resourceId('Microsoft.Network/loadBalancers', parameters('lbName')), '/backendAddressPools/wallix-backend-pool')]"
              },
              "protocol": "All",
              "enableTcpReset": true,
              "idleTimeoutInMinutes": 4,
              "allocatedOutboundPorts": 10000
            }
          }
        ]
      }
    }
  ],
  "outputs": {
    "loadBalancerIP": {
      "type": "string",
      "value": "[reference(resourceId('Microsoft.Network/publicIPAddresses', parameters('publicIpName'))).ipAddress]"
    },
    "loadBalancerFqdn": {
      "type": "string",
      "value": "[reference(resourceId('Microsoft.Network/publicIPAddresses', parameters('publicIpName'))).dnsSettings.fqdn]"
    }
  }
}
```

### Azure Terraform Configuration

```hcl
# Azure Load Balancer for WALLIX Bastion
# terraform/azure-lb/main.tf

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "resource_group_name" {
  type    = string
  default = "wallix-rg"
}

variable "location" {
  type    = string
  default = "westeurope"
}

variable "wallix_vm_ids" {
  type = list(string)
}

# Public IP
resource "azurerm_public_ip" "wallix_lb" {
  name                = "wallix-lb-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "wallix-bastion"
}

# Load Balancer
resource "azurerm_lb" "wallix" {
  name                = "wallix-lb"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.wallix_lb.id
  }
}

# Backend Pool
resource "azurerm_lb_backend_address_pool" "wallix" {
  loadbalancer_id = azurerm_lb.wallix.id
  name            = "wallix-backend-pool"
}

# Health Probes
resource "azurerm_lb_probe" "https" {
  loadbalancer_id     = azurerm_lb.wallix.id
  name                = "https-probe"
  protocol            = "Https"
  port                = 443
  request_path        = "/health"
  interval_in_seconds = 15
  number_of_probes    = 2
}

resource "azurerm_lb_probe" "ssh" {
  loadbalancer_id     = azurerm_lb.wallix.id
  name                = "ssh-probe"
  protocol            = "Tcp"
  port                = 22
  interval_in_seconds = 15
  number_of_probes    = 2
}

resource "azurerm_lb_probe" "rdp" {
  loadbalancer_id     = azurerm_lb.wallix.id
  name                = "rdp-probe"
  protocol            = "Tcp"
  port                = 3389
  interval_in_seconds = 15
  number_of_probes    = 2
}

# Load Balancing Rules
resource "azurerm_lb_rule" "https" {
  loadbalancer_id                = azurerm_lb.wallix.id
  name                           = "https-rule"
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.wallix.id]
  probe_id                       = azurerm_lb_probe.https.id
  load_distribution              = "SourceIPProtocol"
  idle_timeout_in_minutes        = 30
  disable_outbound_snat          = true
}

resource "azurerm_lb_rule" "ssh" {
  loadbalancer_id                = azurerm_lb.wallix.id
  name                           = "ssh-rule"
  protocol                       = "Tcp"
  frontend_port                  = 22
  backend_port                   = 22
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.wallix.id]
  probe_id                       = azurerm_lb_probe.ssh.id
  load_distribution              = "SourceIP"
  idle_timeout_in_minutes        = 30
  disable_outbound_snat          = true
}

resource "azurerm_lb_rule" "rdp" {
  loadbalancer_id                = azurerm_lb.wallix.id
  name                           = "rdp-rule"
  protocol                       = "Tcp"
  frontend_port                  = 3389
  backend_port                   = 3389
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.wallix.id]
  probe_id                       = azurerm_lb_probe.rdp.id
  load_distribution              = "SourceIP"
  idle_timeout_in_minutes        = 30
  disable_outbound_snat          = true
}

# Outbound Rule
resource "azurerm_lb_outbound_rule" "wallix" {
  loadbalancer_id          = azurerm_lb.wallix.id
  name                     = "outbound-rule"
  protocol                 = "All"
  backend_address_pool_id  = azurerm_lb_backend_address_pool.wallix.id
  allocated_outbound_ports = 10000

  frontend_ip_configuration {
    name = "PublicIPAddress"
  }
}

output "load_balancer_ip" {
  value = azurerm_public_ip.wallix_lb.ip_address
}

output "load_balancer_fqdn" {
  value = azurerm_public_ip.wallix_lb.fqdn
}
```

---

## Health Check Configuration

### WALLIX Health Check Endpoints

```
+===========================================================================+
|                    WALLIX HEALTH CHECK ENDPOINTS                          |
+===========================================================================+
|                                                                           |
|   ENDPOINT                PROTOCOL   PURPOSE                              |
|   ========                ========   =======                              |
|                                                                           |
|   /health                 HTTPS      Main application health              |
|   /api/health             HTTPS      API service health                   |
|   /api/v2/status          HTTPS      Detailed system status               |
|                                                                           |
|   --------------------------------------------------------------------------
|                                                                           |
|   SAMPLE RESPONSE (/health)                                               |
|   =========================                                               |
|                                                                           |
|   HTTP/1.1 200 OK                                                         |
|   Content-Type: application/json                                          |
|                                                                           |
|   {                                                                       |
|       "status": "healthy",                                                |
|       "version": "12.1.3",                                                |
|       "node": "wallix-node1",                                             |
|       "timestamp": "2026-01-31T10:30:00Z",                                |
|       "components": {                                                     |
|           "database": "healthy",                                          |
|           "session_manager": "healthy",                                   |
|           "password_manager": "healthy",                                  |
|           "audit_service": "healthy"                                      |
|       }                                                                   |
|   }                                                                       |
|                                                                           |
|   HTTP STATUS CODES:                                                      |
|   200 - All components healthy                                            |
|   503 - One or more components unhealthy                                  |
|   500 - Health check failed                                               |
|                                                                           |
+===========================================================================+
```

### Custom Health Check Script

```bash
#!/bin/bash
# /usr/local/bin/wallix-health-check.sh
# Custom health check script for load balancer integration

set -euo pipefail

# Configuration
WALLIX_URL="https://localhost:443"
TIMEOUT=5
EXPECTED_STATUS="healthy"

# Perform health check
check_health() {
    local response
    local http_code

    response=$(curl -s -k -w "\n%{http_code}" \
        --connect-timeout "$TIMEOUT" \
        --max-time "$TIMEOUT" \
        "$WALLIX_URL/health" 2>/dev/null)

    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n-1)

    if [[ "$http_code" != "200" ]]; then
        echo "CRITICAL: HTTP status code $http_code"
        exit 2
    fi

    status=$(echo "$body" | jq -r '.status' 2>/dev/null)

    if [[ "$status" == "$EXPECTED_STATUS" ]]; then
        echo "OK: WALLIX Bastion is healthy"
        exit 0
    else
        echo "WARNING: Status is $status"
        exit 1
    fi
}

# Check individual services
check_services() {
    local services=("wabengine" "wabwebui" "nginx" "postgresql")
    local failed=0

    for service in "${services[@]}"; do
        if ! systemctl is-active --quiet "$service" 2>/dev/null; then
            echo "CRITICAL: Service $service is not running"
            ((failed++))
        fi
    done

    if [[ $failed -gt 0 ]]; then
        exit 2
    fi
}

# Main
check_services
check_health
```

### HAProxy Advanced Health Check

```bash
# /etc/haproxy/health-check.lua
-- Lua script for advanced health checking

local function health_check(txn)
    local s = core.tcp()
    s:settimeout(2)

    if s:connect("127.0.0.1", 443) then
        s:send("GET /health HTTP/1.1\r\nHost: localhost\r\n\r\n")
        local response = s:receive("*a")
        s:close()

        if response and response:match('"status":"healthy"') then
            return 1  -- Healthy
        end
    end

    return 0  -- Unhealthy
end

core.register_fetches("wallix_health", health_check)
```

---

## SSL/TLS Best Practices

### Certificate Management

```
+===========================================================================+
|                    SSL/TLS CERTIFICATE MANAGEMENT                         |
+===========================================================================+
|                                                                           |
|   CERTIFICATE CHAIN ORDER                                                 |
|   =======================                                                 |
|                                                                           |
|   +-------------------+                                                   |
|   |    Root CA        |  (May be omitted - clients have it)               |
|   +-------------------+                                                   |
|            |                                                              |
|            v                                                              |
|   +-------------------+                                                   |
|   | Intermediate CA   |  (Must be included)                               |
|   +-------------------+                                                   |
|            |                                                              |
|            v                                                              |
|   +-------------------+                                                   |
|   | Server Cert       |  (Must be first in chain file)                    |
|   +-------------------+                                                   |
|                                                                           |
|   RECOMMENDED SETTINGS                                                    |
|   ====================                                                    |
|                                                                           |
|   TLS Versions:        TLS 1.2, TLS 1.3 (disable TLS 1.0/1.1)            |
|   Key Size:            RSA 2048+ or ECDSA P-256+                          |
|   Certificate Type:    SAN certificate with all hostnames                |
|   Validity:            1 year maximum (automation recommended)            |
|   OCSP Stapling:       Enabled                                            |
|                                                                           |
+===========================================================================+
```

### Recommended Cipher Suites

```bash
# TLS 1.3 Cipher Suites (in order of preference)
TLS_AES_256_GCM_SHA384
TLS_CHACHA20_POLY1305_SHA256
TLS_AES_128_GCM_SHA256

# TLS 1.2 Cipher Suites (in order of preference)
ECDHE-ECDSA-AES256-GCM-SHA384
ECDHE-RSA-AES256-GCM-SHA384
ECDHE-ECDSA-CHACHA20-POLY1305
ECDHE-RSA-CHACHA20-POLY1305
ECDHE-ECDSA-AES128-GCM-SHA256
ECDHE-RSA-AES128-GCM-SHA256

# OpenSSL cipher string
ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256
```

### Security Headers Configuration

```nginx
# Nginx security headers
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self';" always;
add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
```

### Certificate Verification Script

```bash
#!/bin/bash
# /usr/local/bin/check-certificate.sh
# Verify SSL certificate validity and configuration

DOMAIN="${1:-wallix.company.com}"
PORT="${2:-443}"

echo "=========================================="
echo "SSL Certificate Check for $DOMAIN:$PORT"
echo "=========================================="

# Get certificate details
echo -e "\n[Certificate Information]"
echo | openssl s_client -connect "$DOMAIN:$PORT" -servername "$DOMAIN" 2>/dev/null | \
    openssl x509 -noout -subject -issuer -dates -fingerprint

# Check expiration
echo -e "\n[Expiration Check]"
expiry_date=$(echo | openssl s_client -connect "$DOMAIN:$PORT" -servername "$DOMAIN" 2>/dev/null | \
    openssl x509 -noout -enddate | cut -d= -f2)
expiry_epoch=$(date -d "$expiry_date" +%s)
current_epoch=$(date +%s)
days_remaining=$(( (expiry_epoch - current_epoch) / 86400 ))

if [[ $days_remaining -lt 30 ]]; then
    echo "WARNING: Certificate expires in $days_remaining days"
elif [[ $days_remaining -lt 0 ]]; then
    echo "CRITICAL: Certificate has expired!"
else
    echo "OK: Certificate expires in $days_remaining days"
fi

# Check cipher suites
echo -e "\n[Supported Cipher Suites]"
nmap --script ssl-enum-ciphers -p "$PORT" "$DOMAIN" 2>/dev/null | grep -E "TLSv|cipher:"

# Check for weak protocols
echo -e "\n[Protocol Check]"
for proto in ssl3 tls1 tls1_1 tls1_2 tls1_3; do
    result=$(echo | openssl s_client -connect "$DOMAIN:$PORT" -"$proto" 2>&1)
    if echo "$result" | grep -q "Cipher is"; then
        status="ENABLED"
    else
        status="DISABLED"
    fi
    echo "$proto: $status"
done
```

---

## Troubleshooting

### Common Issues and Solutions

```
+===========================================================================+
|                    TROUBLESHOOTING GUIDE                                  |
+===========================================================================+
|                                                                           |
|   ISSUE: 502 Bad Gateway                                                  |
|   =====================                                                   |
|                                                                           |
|   Symptoms:                                                               |
|   * Users see 502 error in browser                                       |
|   * Load balancer logs show connection refused                           |
|                                                                           |
|   Causes:                                                                 |
|   * Backend servers are down                                             |
|   * Health checks failing                                                |
|   * Firewall blocking LB to backend traffic                              |
|   * SSL certificate mismatch                                             |
|                                                                           |
|   Resolution:                                                             |
|   1. Check backend server status:                                        |
|      $ systemctl status wallix-bastion nginx postgresql                  |
|   2. Verify network connectivity:                                        |
|      $ curl -v https://10.0.1.11:443/health                              |
|   3. Check load balancer logs:                                           |
|      $ tail -f /var/log/haproxy.log                                      |
|   4. Verify SSL certificates:                                            |
|      $ openssl s_client -connect 10.0.1.11:443                           |
|                                                                           |
|   --------------------------------------------------------------------------
|                                                                           |
|   ISSUE: Session Persistence Not Working                                  |
|   =====================================                                   |
|                                                                           |
|   Symptoms:                                                               |
|   * Users logged out unexpectedly                                        |
|   * SSH/RDP sessions disconnecting                                       |
|   * API requests failing intermittently                                  |
|                                                                           |
|   Causes:                                                                 |
|   * Cookie not being set properly                                        |
|   * Source IP hash misconfigured                                         |
|   * Client behind NAT with changing IP                                   |
|                                                                           |
|   Resolution:                                                             |
|   1. Verify cookie insertion (HAProxy):                                  |
|      $ curl -v https://wallix.company.com 2>&1 | grep -i cookie          |
|   2. Check stick table (HAProxy):                                        |
|      $ echo "show table wallix_ssh_nodes" | socat stdio /run/haproxy/admin.sock |
|   3. For NAT environments, consider cookie-based persistence             |
|                                                                           |
|   --------------------------------------------------------------------------
|                                                                           |
|   ISSUE: WebSocket Connections Failing                                    |
|   ====================================                                    |
|                                                                           |
|   Symptoms:                                                               |
|   * Web console not loading                                              |
|   * Real-time updates not working                                        |
|   * Connection timeout errors                                            |
|                                                                           |
|   Causes:                                                                 |
|   * WebSocket upgrade not supported                                      |
|   * Timeout too short                                                    |
|   * Proxy buffering interfering                                          |
|                                                                           |
|   Resolution:                                                             |
|   1. Verify WebSocket headers are passed:                                |
|      proxy_set_header Upgrade $http_upgrade;                             |
|      proxy_set_header Connection "upgrade";                              |
|   2. Increase timeouts:                                                  |
|      proxy_read_timeout 3600s;                                           |
|   3. Disable buffering for WebSocket:                                    |
|      proxy_buffering off;                                                |
|                                                                           |
|   --------------------------------------------------------------------------
|                                                                           |
|   ISSUE: High Latency                                                     |
|   ===================                                                     |
|                                                                           |
|   Symptoms:                                                               |
|   * Slow page loads                                                      |
|   * Session lag                                                          |
|   * Timeout errors                                                       |
|                                                                           |
|   Causes:                                                                 |
|   * SSL/TLS handshake overhead                                           |
|   * Health check storm                                                   |
|   * Backend server overload                                              |
|   * Network congestion                                                   |
|                                                                           |
|   Resolution:                                                             |
|   1. Enable SSL session resumption                                       |
|   2. Reduce health check frequency                                       |
|   3. Enable keepalive connections                                        |
|   4. Check backend server resources                                      |
|                                                                           |
+===========================================================================+
```

### Verification Commands

```bash
#------------------------------------------------------------------------------
# HAProxy Verification
#------------------------------------------------------------------------------

# Check HAProxy status
systemctl status haproxy

# Validate configuration
haproxy -c -f /etc/haproxy/haproxy.cfg

# View stats via socket
echo "show stat" | socat stdio /run/haproxy/admin.sock

# Check backend health
echo "show servers state" | socat stdio /run/haproxy/admin.sock

# View stick tables
echo "show table wallix_ssh_nodes" | socat stdio /run/haproxy/admin.sock

# Real-time connection monitoring
watch -n1 'echo "show stat" | socat stdio /run/haproxy/admin.sock | cut -d, -f1,2,5,8,9,18'

#------------------------------------------------------------------------------
# Nginx Verification
#------------------------------------------------------------------------------

# Check Nginx status
systemctl status nginx

# Validate configuration
nginx -t

# Check upstream status (requires status module)
curl -s http://127.0.0.1:8080/nginx_status

# View active connections
ss -tlnp | grep nginx

# Check error logs
tail -f /var/log/nginx/error.log

#------------------------------------------------------------------------------
# SSL/TLS Verification
#------------------------------------------------------------------------------

# Test SSL connection
openssl s_client -connect wallix.company.com:443 -servername wallix.company.com

# Check certificate chain
openssl s_client -connect wallix.company.com:443 -showcerts

# Test TLS 1.3
openssl s_client -connect wallix.company.com:443 -tls1_3

# Verify HSTS header
curl -sI https://wallix.company.com | grep -i strict

#------------------------------------------------------------------------------
# Connectivity Testing
#------------------------------------------------------------------------------

# Test HTTPS health endpoint
curl -v -k https://wallix.company.com/health

# Test API endpoint
curl -v -k https://wallix.company.com/api/v2/status

# Test SSH connectivity through LB
ssh -v -p 22 wallix.company.com

# Test RDP connectivity through LB
nmap -sT -p 3389 wallix.company.com

# Measure response time
curl -w "@curl-format.txt" -o /dev/null -s https://wallix.company.com/health

#------------------------------------------------------------------------------
# Log Analysis
#------------------------------------------------------------------------------

# HAProxy - View recent errors
grep -E "(error|warning|alert)" /var/log/haproxy.log | tail -50

# HAProxy - Connection statistics
awk -F',' '{print $1,$2,$18,$33}' /var/log/haproxy.log | sort | uniq -c | sort -rn

# Nginx - Error summary
awk '{print $9}' /var/log/nginx/access.log | sort | uniq -c | sort -rn

# Find slow requests
awk '$10 > 5 {print $7,$10}' /var/log/nginx/access.log | sort -t' ' -k2 -rn | head -20
```

### Monitoring Checklist

```
+===========================================================================+
|                    LOAD BALANCER MONITORING CHECKLIST                     |
+===========================================================================+
|                                                                           |
|   METRIC                          ALERT THRESHOLD         CHECK INTERVAL  |
|   ======                          ===============         ==============  |
|                                                                           |
|   Backend Health                                                          |
|   [ ] All backends healthy        Any unhealthy           30 seconds      |
|   [ ] Health check latency        > 500ms                 1 minute        |
|                                                                           |
|   Connection Metrics                                                      |
|   [ ] Active connections          > 80% capacity          1 minute        |
|   [ ] Connection rate             > 1000/sec              1 minute        |
|   [ ] Queue depth                 > 10                    30 seconds      |
|                                                                           |
|   Error Rates                                                             |
|   [ ] 5xx error rate              > 1%                    1 minute        |
|   [ ] 4xx error rate              > 10%                   5 minutes       |
|   [ ] Connection timeouts         > 5/minute              1 minute        |
|                                                                           |
|   SSL/TLS                                                                 |
|   [ ] Certificate expiration      < 30 days               Daily           |
|   [ ] SSL handshake failures      > 10/minute             1 minute        |
|                                                                           |
|   Performance                                                             |
|   [ ] Response time (p95)         > 2 seconds             1 minute        |
|   [ ] Response time (p99)         > 5 seconds             1 minute        |
|   [ ] Throughput                  > 90% capacity          1 minute        |
|                                                                           |
|   Session Persistence                                                     |
|   [ ] Stick table entries         > 90% full              5 minutes       |
|   [ ] Session distribution        Uneven > 20%            5 minutes       |
|                                                                           |
+===========================================================================+
```

---

## Quick Reference

### Port Summary

| Port | Protocol | Service | LB Mode | Persistence |
|------|----------|---------|---------|-------------|
| 443 | HTTPS | Web UI / API | Layer 7 | Cookie |
| 22 | TCP | SSH Proxy | Layer 4 | Source IP |
| 3389 | TCP | RDP Proxy | Layer 4 | Source IP |
| 5900 | TCP | VNC Proxy | Layer 4 | Source IP |
| 23 | TCP | Telnet Proxy | Layer 4 | Source IP |

### Configuration Comparison

| Feature | HAProxy | Nginx | F5 BIG-IP | AWS ALB/NLB |
|---------|---------|-------|-----------|-------------|
| L4 Load Balancing | Yes | Yes (stream) | Yes | NLB |
| L7 Load Balancing | Yes | Yes | Yes | ALB |
| WebSocket Support | Yes | Yes | Yes | ALB |
| Health Checks | HTTP/TCP | HTTP/TCP | HTTP/TCP/Custom | HTTP/TCP |
| SSL Termination | Yes | Yes | Yes | ALB |
| Session Affinity | Cookie/IP | IP Hash | Cookie/IP | Cookie/IP |
| Stats Dashboard | Built-in | Module | Built-in | CloudWatch |

---

## Related Documentation

- [10 - High Availability & Disaster Recovery](../10-high-availability/README.md)
- [24 - Cloud Deployment](../24-cloud-deployment/README.md)
- [28 - System Requirements](../28-system-requirements/README.md)
- [Install - Architecture Diagrams](../../install/09-architecture-diagrams.md)

## External References

- [HAProxy Documentation](https://www.haproxy.com/documentation/)
- [Nginx Load Balancing](https://docs.nginx.com/nginx/admin-guide/load-balancer/)
- [F5 BIG-IP Documentation](https://techdocs.f5.com/)
- [AWS Elastic Load Balancing](https://docs.aws.amazon.com/elasticloadbalancing/)
- [Azure Load Balancer](https://docs.microsoft.com/en-us/azure/load-balancer/)
- [WALLIX Documentation Portal](https://pam.wallix.one/documentation)

---

## Version Information

| Item | Value |
|------|-------|
| Document Version | 1.0 |
| WALLIX Bastion Version | 12.1.x |
| Last Updated | January 2026 |
