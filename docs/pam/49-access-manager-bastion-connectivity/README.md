# 49 - Access Manager Bastion Connectivity

## Connecting WALLIX Access Manager to WALLIX Bastion

This section covers the connectivity features, protocols, and configuration patterns that WALLIX Access Manager uses to communicate with WALLIX Bastion instances. It details API integration, session brokering, credential injection, high availability routing, and multi-site federation.

---

## Table of Contents

1. [Connectivity Overview](#connectivity-overview)
2. [Communication Protocols](#communication-protocols)
3. [API Integration](#api-integration)
4. [Session Brokering](#session-brokering)
5. [Credential Injection](#credential-injection)
6. [Multi-Bastion Connectivity](#multi-bastion-connectivity)
7. [High Availability Routing](#high-availability-routing)
8. [Multi-Site Federation](#multi-site-federation)
9. [TLS and Certificate Management](#tls-and-certificate-management)
10. [Network Architecture](#network-architecture)
11. [Connection Health Monitoring](#connection-health-monitoring)
12. [Troubleshooting](#troubleshooting)
13. [Best Practices](#best-practices)

---

## Connectivity Overview

### How Access Manager Connects to Bastion

WALLIX Access Manager acts as a **web portal front-end** that communicates with one or more WALLIX Bastion instances to provide browser-based privileged access. The connection between Access Manager and Bastion relies on three main channels:

```
+===============================================================================+
|               ACCESS MANAGER - BASTION CONNECTIVITY MODEL                     |
+===============================================================================+
|                                                                               |
|  +-------------------+                          +-------------------+         |
|  |   Access Manager  |                          |  WALLIX Bastion   |         |
|  |                   |                          |                   |         |
|  |  +-------------+  |   REST API (HTTPS/443)   |  +-------------+  |         |
|  |  | API Client  |--|------------------------->|  | REST API    |  |         |
|  |  +-------------+  |                          |  +-------------+  |         |
|  |                   |                          |                   |         |
|  |  +-------------+  |   WebSocket (WSS/443)    |  +-------------+  |         |
|  |  | Session     |--|------------------------->|  | Session     |  |         |
|  |  | Broker      |  |                          |  | Manager     |  |         |
|  |  +-------------+  |                          |  +-------------+  |         |
|  |                   |                          |                   |         |
|  |  +-------------+  |   RDP/SSH Proxy (443)    |  +-------------+  |         |
|  |  | HTML5       |--|------------------------->|  | Protocol    |  |         |
|  |  | Gateway     |  |                          |  | Proxy       |  |         |
|  |  +-------------+  |                          |  +-------------+  |         |
|  |                   |                          |                   |         |
|  +-------------------+                          +-------------------+         |
|                                                                               |
|  Channel 1: REST API    - Authentication, authorization, target discovery     |
|  Channel 2: WebSocket   - Real-time session control, events, notifications    |
|  Channel 3: Proxy       - RDP/SSH/VNC session data via HTML5 rendering        |
|                                                                               |
+===============================================================================+
```

### Key Connectivity Features

| Feature | Description |
|---------|-------------|
| **REST API Integration** | Query targets, authorizations, users, and policies from Bastion |
| **Session Brokering** | Launch and manage RDP, SSH, VNC sessions through the browser |
| **Credential Injection** | Retrieve and inject checkout credentials transparently |
| **HTML5 Gateway** | Render protocol sessions (RDP/SSH) as HTML5 in the browser |
| **Multi-Bastion Support** | Connect to multiple Bastion instances from a single portal |
| **HA-Aware Routing** | Detect Bastion failover and redirect sessions automatically |
| **Mutual TLS** | Certificate-based authentication between components |

---

## Communication Protocols

### Protocol Stack

```
+===============================================================================+
|                    COMMUNICATION PROTOCOL STACK                               |
+===============================================================================+
|                                                                               |
|  Layer         Protocol         Purpose                  Port                 |
|  =========================================================================== |
|                                                                               |
|  Application   REST API         Target/user management   443                  |
|                WebSocket        Session events           443                  |
|                Guacamole        RDP/SSH rendering        443                  |
|                                                                               |
|  Session       HTTPS            All traffic encrypted    443                  |
|                                                                               |
|  Security      TLS 1.2/1.3     Transport encryption     -                    |
|                mTLS (optional)  Mutual authentication    -                    |
|                API Key          Request authentication   -                    |
|                                                                               |
|  Network       TCP              Reliable transport       443                  |
|                                                                               |
+===============================================================================+
```

### Port Requirements

```
+===============================================================================+
|            ACCESS MANAGER TO BASTION PORT MATRIX                              |
+===============================================================================+

FROM ACCESS MANAGER TO BASTION
================================

+-----------------------------------------------------------------------------+
| Port     | Protocol | Purpose                         | Required            |
+----------+----------+---------------------------------+---------------------+
| 443      | TCP/TLS  | REST API + WebSocket + Proxy    | Yes                 |
| 22       | TCP      | SSH tunneling (fallback)        | Optional            |
+----------+----------+---------------------------------+---------------------+

FROM BASTION TO ACCESS MANAGER (Callbacks)
============================================

+-----------------------------------------------------------------------------+
| Port     | Protocol | Purpose                         | Required            |
+----------+----------+---------------------------------+---------------------+
| 443      | TCP/TLS  | Webhook notifications           | Optional            |
| 8080     | TCP      | Health check endpoint           | Optional            |
+----------+----------+---------------------------------+---------------------+

+===============================================================================+
```

> **Note:** All traffic between Access Manager and Bastion is consolidated on port 443 using HTTPS. This simplifies firewall configuration and allows traversal through restrictive network environments.

---

## API Integration

### Bastion REST API Endpoints Used by Access Manager

Access Manager communicates with Bastion through the REST API to perform target discovery, authorization checks, and session management.

#### Target Discovery

```bash
# Access Manager queries available targets for a user
# API call: GET /api/targets/sessionrights
curl -s -H "Authorization: Bearer ${API_TOKEN}" \
  -H "Content-Type: application/json" \
  https://bastion.company.com/api/targets/sessionrights

# Response includes all authorized target/account/protocol combinations
# Access Manager uses this to populate the user's session launcher
```

#### User Authentication Passthrough

```bash
# Access Manager validates user credentials against Bastion
# API call: POST /api/auth
curl -s -X POST \
  -H "Content-Type: application/json" \
  -d '{"user": "john.doe", "password": "REDACTED"}' \
  https://bastion.company.com/api/auth

# On success, Bastion returns a session token
# Access Manager stores this token for subsequent API calls
```

#### Authorization Queries

```bash
# Check if user is authorized for a specific target
# API call: GET /api/authorizations
curl -s -H "Authorization: Bearer ${API_TOKEN}" \
  https://bastion.company.com/api/authorizations?user=john.doe

# Access Manager caches authorization results
# Cache TTL configurable (default: 300 seconds)
```

### API Service Account Configuration

```bash
# On WALLIX Bastion: create a dedicated API service account
wabadmin user add \
  --name am-service \
  --email am-service@company.com \
  --profile api-user \
  --ip-restriction 10.100.1.10,10.100.2.10

# Generate API key for the service account
wabadmin user api-key generate am-service

# On Access Manager: register the Bastion connection
sudo wallix-am bastion add \
  --name "Bastion-Site1" \
  --host bastion-site1.company.com \
  --port 443 \
  --api-user am-service \
  --api-key "$(cat /etc/wallix-am/bastion-site1.key)" \
  --tls-verify true

# Test the API connection
sudo wallix-am bastion test "Bastion-Site1"
# Expected output:
# ✓ API endpoint reachable
# ✓ Authentication successful
# ✓ Bastion version: 12.3.2
# ✓ License valid
# ✓ Targets available: 245
```

### API Rate Limiting and Caching

```bash
# Configure API request caching to reduce Bastion load
sudo wallix-am config set --api-cache-ttl 300
sudo wallix-am config set --api-cache-max-entries 10000

# Configure rate limiting
sudo wallix-am config set --api-rate-limit 100     # requests per second
sudo wallix-am config set --api-retry-max 3         # max retries on failure
sudo wallix-am config set --api-retry-delay 2       # seconds between retries
sudo wallix-am config set --api-timeout 30          # request timeout in seconds
```

---

## Session Brokering

### Session Launch Flow

Access Manager brokers privileged sessions between the user's browser and the target system through the Bastion proxy.

```
+===============================================================================+
|                    SESSION BROKERING FLOW                                      |
+===============================================================================+
|                                                                               |
|  Browser          Access Manager         Bastion            Target            |
|     |                   |                   |                  |              |
|     | 1. Click target   |                   |                  |              |
|     |------------------>|                   |                  |              |
|     |                   |                   |                  |              |
|     |                   | 2. POST /api/     |                  |              |
|     |                   |    sessions       |                  |              |
|     |                   |------------------>|                  |              |
|     |                   |                   |                  |              |
|     |                   | 3. Session ID +   |                  |              |
|     |                   |    connection URL  |                  |              |
|     |                   |<------------------|                  |              |
|     |                   |                   |                  |              |
|     | 4. WebSocket       |                   |                  |              |
|     |    upgrade         |                   |                  |              |
|     |------------------>|                   |                  |              |
|     |                   | 5. Proxy WS to    |                  |              |
|     |                   |    Bastion         |                  |              |
|     |                   |------------------>|                  |              |
|     |                   |                   | 6. Connect to    |              |
|     |                   |                   |    target        |              |
|     |                   |                   |----------------->|              |
|     |                   |                   |                  |              |
|     |<=================>|<=================>|<================>|              |
|     |        HTML5 rendered session (bidirectional)            |              |
|     |                   |                   |                  |              |
|     | 7. Close session  |                   |                  |              |
|     |------------------>| 8. DELETE /api/   |                  |              |
|     |                   |    sessions/{id}  |                  |              |
|     |                   |------------------>|                  |              |
|     |                   |                   | 9. Disconnect    |              |
|     |                   |                   |----------------->|              |
|                                                                               |
+===============================================================================+
```

### Supported Session Types

| Protocol | Bastion Proxy | AM Rendering | Features |
|----------|---------------|--------------|----------|
| **RDP** | RDP Gateway | HTML5 Canvas | Clipboard, file transfer, multi-monitor |
| **SSH** | SSH Proxy | HTML5 Terminal | Copy/paste, key forwarding |
| **VNC** | VNC Proxy | HTML5 Canvas | Screen sharing, remote control |
| **Telnet** | Telnet Proxy | HTML5 Terminal | Legacy device access |
| **RLOGIN** | RLOGIN Proxy | HTML5 Terminal | Unix system access |

### Session Configuration

```bash
# Configure session brokering parameters
sudo wallix-am config set --session-idle-timeout 900        # 15 minutes
sudo wallix-am config set --session-max-duration 28800      # 8 hours
sudo wallix-am config set --session-keepalive-interval 30   # seconds
sudo wallix-am config set --session-reconnect-enabled true
sudo wallix-am config set --session-reconnect-timeout 120   # seconds

# Configure HTML5 gateway settings
sudo wallix-am config set --html5-quality high
sudo wallix-am config set --html5-compression true
sudo wallix-am config set --html5-clipboard-enabled true
sudo wallix-am config set --html5-file-transfer-enabled true
sudo wallix-am config set --html5-audio-enabled false
sudo wallix-am config set --html5-printing-enabled false
```

---

## Credential Injection

### Transparent Credential Injection Flow

Access Manager retrieves credentials from the Bastion vault and injects them into sessions without exposing them to the end user.

```
+===============================================================================+
|                    CREDENTIAL INJECTION FLOW                                  |
+===============================================================================+
|                                                                               |
|  User               Access Manager           Bastion Vault                   |
|    |                      |                       |                           |
|    | 1. Launch session    |                       |                           |
|    |  (no password needed)|                       |                           |
|    |--------------------->|                       |                           |
|    |                      |                       |                           |
|    |                      | 2. GET /api/          |                           |
|    |                      |    credentials/       |                           |
|    |                      |    checkout           |                           |
|    |                      |---------------------->|                           |
|    |                      |                       |                           |
|    |                      | 3. Encrypted          |                           |
|    |                      |    credential          |                           |
|    |                      |<----------------------|                           |
|    |                      |                       |                           |
|    |                      | 4. Inject into        |                           |
|    |                      |    session (in-memory) |                           |
|    |                      |    Credential never    |                           |
|    |                      |    sent to browser     |                           |
|    |                      |                       |                           |
|    | 5. Session opens     |                       |                           |
|    |    (authenticated)   |                       |                           |
|    |<---------------------|                       |                           |
|    |                      |                       |                           |
|    |                      | 6. POST /api/         |                           |
|    |                      |    credentials/       |                           |
|    |                      |    checkin            |                           |
|    |                      |    (on disconnect)    |                           |
|    |                      |---------------------->|                           |
|                                                                               |
+===============================================================================+
```

### Credential Injection Modes

| Mode | Description | Use Case |
|------|-------------|----------|
| **Transparent** | Credential retrieved and injected automatically | Standard privileged sessions |
| **Approval-Based** | Credential released only after workflow approval | High-security targets |
| **Time-Bounded** | Credential valid for limited duration only | JIT access scenarios |
| **Rotation-Aware** | Access Manager detects credential rotation events | Password rotation policies |

### Configuration

```bash
# Enable credential injection
sudo wallix-am bastion credential-injection enable \
  --bastion "Bastion-Site1" \
  --mode transparent

# Configure credential caching (in-memory only, never on disk)
sudo wallix-am config set --credential-cache-ttl 60        # seconds
sudo wallix-am config set --credential-cache-encrypted true
sudo wallix-am config set --credential-memory-wipe true     # wipe on session end

# Enable checkout/checkin auditing
sudo wallix-am config set --credential-audit-checkout true
sudo wallix-am config set --credential-audit-checkin true
```

---

## Multi-Bastion Connectivity

### Connecting to Multiple Bastion Instances

A single Access Manager portal can connect to multiple Bastion instances across different environments or sites.

```
+===============================================================================+
|                  MULTI-BASTION CONNECTIVITY                                   |
+===============================================================================+
|                                                                               |
|                     +---------------------+                                   |
|                     |   Access Manager    |                                   |
|                     |   portal.company.com|                                   |
|                     +----+----+----+------+                                   |
|                          |    |    |                                           |
|              +-----------+    |    +-----------+                               |
|              |                |                |                               |
|     +--------v--------+ +----v---------+ +----v---------+                     |
|     | Bastion-Site1   | | Bastion-Site2 | | Bastion-Site3|                     |
|     | Production      | | Development   | | DR/Staging   |                     |
|     | 10.10.1.20      | | 10.10.2.20    | | 10.10.3.20   |                     |
|     | 350 targets     | | 120 targets   | | 200 targets  |                     |
|     +-----------------+ +---------------+ +--------------+                     |
|                                                                               |
|  User sees unified view:                                                      |
|  +-----------------------------------------------------------------+          |
|  | My Authorized Targets                                           |          |
|  +-----------------------------------------------------------------+          |
|  | Target          | Account   | Protocol | Bastion    | Site      |          |
|  +-----------------+-----------+----------+------------+-----------+          |
|  | web-srv-01      | admin     | SSH      | Site1      | Production|          |
|  | db-prod-01      | dba       | RDP      | Site1      | Production|          |
|  | dev-api-01      | deploy    | SSH      | Site2      | Development|         |
|  | dr-web-01       | admin     | SSH      | Site3      | DR/Staging|          |
|  +-----------------------------------------------------------------+          |
|                                                                               |
+===============================================================================+
```

### Configuration

```bash
# Register multiple Bastion instances
sudo wallix-am bastion add \
  --name "Bastion-Site1" \
  --host bastion-site1.company.com \
  --port 443 \
  --api-user am-service \
  --api-key "$(cat /etc/wallix-am/bastion-site1.key)" \
  --label "Production" \
  --priority 1

sudo wallix-am bastion add \
  --name "Bastion-Site2" \
  --host bastion-site2.company.com \
  --port 443 \
  --api-user am-service \
  --api-key "$(cat /etc/wallix-am/bastion-site2.key)" \
  --label "Development" \
  --priority 2

sudo wallix-am bastion add \
  --name "Bastion-Site3" \
  --host bastion-site3.company.com \
  --port 443 \
  --api-user am-service \
  --api-key "$(cat /etc/wallix-am/bastion-site3.key)" \
  --label "DR/Staging" \
  --priority 3

# List registered Bastion instances
sudo wallix-am bastion list

# Expected output:
# Name            Host                          Status    Targets  Label
# Bastion-Site1   bastion-site1.company.com     Online    350      Production
# Bastion-Site2   bastion-site2.company.com     Online    120      Development
# Bastion-Site3   bastion-site3.company.com     Online    200      DR/Staging

# Synchronize targets from all Bastion instances
sudo wallix-am bastion sync-all
```

### Target Aggregation and Deduplication

```bash
# Configure target aggregation across Bastion instances
sudo wallix-am config set --target-aggregation enabled
sudo wallix-am config set --target-dedup-strategy hostname
sudo wallix-am config set --target-refresh-interval 300    # seconds

# Configure per-Bastion sync schedule
sudo wallix-am bastion sync-schedule "Bastion-Site1" --interval 60
sudo wallix-am bastion sync-schedule "Bastion-Site2" --interval 300
sudo wallix-am bastion sync-schedule "Bastion-Site3" --interval 600
```

---

## High Availability Routing

### HA-Aware Bastion Connectivity

Access Manager detects Bastion HA failover events and automatically routes sessions to the active node.

```
+===============================================================================+
|                    HA-AWARE BASTION ROUTING                                    |
+===============================================================================+
|                                                                               |
|                     +---------------------+                                   |
|                     |   Access Manager    |                                   |
|                     |  Health Monitor     |                                   |
|                     +----+--------+-------+                                   |
|                          |        |                                            |
|            Health Check  |        |  Health Check                              |
|            (every 10s)   |        |  (every 10s)                               |
|                          |        |                                            |
|                +---------v--+  +--v---------+                                  |
|                |  Bastion   |  |  Bastion   |                                  |
|                |  Primary   |  |  Secondary |                                  |
|                | 10.10.1.20 |  | 10.10.1.21 |                                  |
|                |  [ACTIVE]  |  | [STANDBY]  |                                  |
|                +------+-----+  +------+-----+                                  |
|                       |               |                                        |
|                       +-------+-------+                                        |
|                               |                                                |
|                        +------v------+                                         |
|                        |  Keepalived |                                         |
|                        |  VIP:       |                                         |
|                        | 10.10.1.25  |                                         |
|                        +-------------+                                         |
|                                                                               |
|  Failover Scenario:                                                           |
|  1. Primary goes down                                                         |
|  2. Access Manager detects failure (health check timeout)                     |
|  3. VIP migrates to Secondary via Keepalived                                  |
|  4. Access Manager routes new sessions to Secondary                           |
|  5. Existing sessions reconnect automatically                                 |
|                                                                               |
+===============================================================================+
```

### HA Routing Configuration

```bash
# Configure Bastion HA cluster in Access Manager
sudo wallix-am bastion add \
  --name "Bastion-Site1-HA" \
  --host bastion-vip-site1.company.com \
  --port 443 \
  --api-user am-service \
  --api-key "$(cat /etc/wallix-am/bastion-site1.key)" \
  --ha-mode active-passive \
  --ha-nodes "10.10.1.20,10.10.1.21" \
  --ha-vip "10.10.1.25" \
  --health-check-interval 10 \
  --health-check-timeout 5 \
  --failover-threshold 3

# Configure session reconnection on failover
sudo wallix-am config set --session-reconnect-on-failover true
sudo wallix-am config set --session-reconnect-grace-period 60

# View HA status
sudo wallix-am bastion ha-status "Bastion-Site1-HA"
# Expected output:
# Cluster:    Bastion-Site1-HA
# Mode:       Active-Passive
# VIP:        10.10.1.25 (active on 10.10.1.20)
# Node 1:     10.10.1.20 [ACTIVE]  - Healthy (latency: 2ms)
# Node 2:     10.10.1.21 [STANDBY] - Healthy (latency: 3ms)
# Last Check: 2026-03-31 14:22:05
# Failovers:  0 (last 30 days)
```

---

## Multi-Site Federation

### Federated Access Across Sites

In multi-site deployments, Access Manager can federate access across geographically distributed Bastion instances, routing users to the nearest or most appropriate site.

```
+===============================================================================+
|                    MULTI-SITE FEDERATION                                      |
+===============================================================================+
|                                                                               |
|                      +---------------------+                                  |
|                      | Access Manager      |                                  |
|                      | (Central Portal)    |                                  |
|                      | portal.company.com  |                                  |
|                      +---+---------+---+---+                                  |
|                          |         |   |                                       |
|           +--------------+    +----+   +-------------+                         |
|           |                   |                      |                         |
|  +--------v--------+ +-------v--------+ +-----------v-----+                   |
|  | Site 1 - Madrid | | Site 2 - Paris | | Site 3 - London |                   |
|  | Bastion HA Pair | | Bastion HA Pair| | Bastion HA Pair |                   |
|  | 10.10.1.0/24    | | 10.10.2.0/24   | | 10.10.3.0/24    |                   |
|  +--------+--------+ +-------+--------+ +-----------+-----+                   |
|           |                   |                      |                         |
|  +--------v--------+ +-------v--------+ +-----------v-----+                   |
|  | Targets:        | | Targets:       | | Targets:        |                   |
|  | - Windows Srv   | | - Linux Srv    | | - Database Srv  |                   |
|  | - Network Equip | | - Cloud VMs    | | - Web Servers   |                   |
|  +-----------------+ +----------------+ +-----------------+                   |
|                                                                               |
|  Routing Policies:                                                            |
|  - Geographic proximity (user IP-based)                                       |
|  - Manual site assignment per user group                                      |
|  - Failover: redirect to alternate site if primary is down                    |
|                                                                               |
+===============================================================================+
```

### Federation Configuration

```bash
# Enable multi-site federation
sudo wallix-am config set --federation-enabled true
sudo wallix-am config set --federation-mode geographic

# Configure site routing rules
sudo wallix-am federation route add \
  --name "Europe-West" \
  --source-subnets "10.20.1.0/24,10.20.2.0/24" \
  --preferred-bastion "Bastion-Site1" \
  --fallback-bastion "Bastion-Site2,Bastion-Site3"

sudo wallix-am federation route add \
  --name "Europe-Central" \
  --source-subnets "10.20.3.0/24,10.20.4.0/24" \
  --preferred-bastion "Bastion-Site2" \
  --fallback-bastion "Bastion-Site1,Bastion-Site3"

# Configure group-based site assignment
sudo wallix-am federation assign \
  --group "DBA Team" \
  --bastion "Bastion-Site3" \
  --reason "Database servers located in London"

# View federation routing table
sudo wallix-am federation routes list
```

---

## TLS and Certificate Management

### Certificate Configuration for Bastion Connectivity

```
+===============================================================================+
|                    TLS TRUST CHAIN                                             |
+===============================================================================+
|                                                                               |
|  Access Manager                              Bastion                          |
|  +---------------------+                     +---------------------+          |
|  | CA Trust Store      |                     | Server Certificate  |          |
|  | - Corporate Root CA |  TLS Handshake      | - Signed by Corp CA |          |
|  | - Intermediate CA   |<------------------->| - CN: bastion.      |          |
|  +---------------------+                     |   company.com       |          |
|                                              +---------------------+          |
|  (Optional) mTLS:                                                             |
|  +---------------------+                     +---------------------+          |
|  | Client Certificate  |  Client Auth        | CA Trust Store      |          |
|  | - Signed by Corp CA |-------------------->| - Validates AM cert |          |
|  | - CN: am.company.com|                     +---------------------+          |
|  +---------------------+                                                      |
|                                                                               |
+===============================================================================+
```

### Certificate Setup

```bash
# Configure CA trust store for Bastion connections
sudo wallix-am cert trust add \
  --ca-cert /etc/wallix-am/certs/corporate-root-ca.crt \
  --name "Corporate Root CA"

sudo wallix-am cert trust add \
  --ca-cert /etc/wallix-am/certs/intermediate-ca.crt \
  --name "Intermediate CA"

# Enable mutual TLS (mTLS) for Bastion connectivity
sudo wallix-am bastion update "Bastion-Site1" \
  --mtls-enabled true \
  --client-cert /etc/wallix-am/certs/am-client.crt \
  --client-key /etc/wallix-am/certs/am-client.key

# Verify TLS connectivity
sudo wallix-am bastion tls-verify "Bastion-Site1"
# Expected output:
# ✓ TLS 1.3 connection established
# ✓ Server certificate valid (expires: 2027-06-15)
# ✓ Certificate chain trusted
# ✓ mTLS client certificate accepted
# ✓ No certificate warnings

# Configure certificate expiry alerts
sudo wallix-am cert alert \
  --threshold 30 \
  --notify admin@company.com
```

---

## Network Architecture

### Recommended Network Placement

```
+===============================================================================+
|                    NETWORK ARCHITECTURE                                        |
+===============================================================================+
|                                                                               |
|  INTERNET / CORPORATE WAN                                                     |
|       |                                                                       |
|  +----v---------------------------+                                           |
|  |  FortiGate Firewall            |                                           |
|  |  (Perimeter)                   |                                           |
|  +----+---------------------------+                                           |
|       |                                                                       |
|  =====|====== DMZ ZONE ==================================================    |
|       |                                                                       |
|  +----v---------------------------+                                           |
|  |  HAProxy / Load Balancer       |                                           |
|  |  VIP: 10.100.1.10              |                                           |
|  +----+---------------------------+                                           |
|       |                                                                       |
|  +----v---------------------------+                                           |
|  |  WALLIX Access Manager         |                                           |
|  |  10.100.1.11 / 10.100.1.12     |                                           |
|  |  (HA Pair)                     |                                           |
|  +----+---------------------------+                                           |
|       |                                                                       |
|  =====|====== INTERNAL ZONE =============================================    |
|       |                                                                       |
|  +----v---------------------------+                                           |
|  |  WALLIX Bastion                |                                           |
|  |  10.10.1.20 / 10.10.1.21      |                                           |
|  |  (HA Pair)                     |                                           |
|  +----+---------------------------+                                           |
|       |                                                                       |
|  =====|====== SERVER ZONE ===============================================    |
|       |                                                                       |
|  +----v---------------------------+                                           |
|  |  Target Servers                |                                           |
|  |  Windows, Linux, Network       |                                           |
|  |  10.10.1.0/24                  |                                           |
|  +--------------------------------+                                           |
|                                                                               |
+===============================================================================+
```

### Firewall Rules

```bash
# FortiGate firewall rules for Access Manager to Bastion connectivity

# Rule 1: Allow Access Manager to Bastion (API + Sessions)
# Source:      10.100.1.11, 10.100.1.12 (Access Manager HA)
# Destination: 10.10.1.20, 10.10.1.21   (Bastion HA)
# Port:        443/TCP
# Action:      ACCEPT
# Log:         Enable

# Rule 2: Allow Access Manager to Bastion VIP
# Source:      10.100.1.11, 10.100.1.12
# Destination: 10.10.1.25               (Bastion VIP)
# Port:        443/TCP
# Action:      ACCEPT
# Log:         Enable

# Rule 3: (Optional) Bastion webhook callbacks to Access Manager
# Source:      10.10.1.20, 10.10.1.21
# Destination: 10.100.1.11, 10.100.1.12
# Port:        443/TCP
# Action:      ACCEPT
# Log:         Enable

# Deny all other traffic between zones
# Source:      Any
# Destination: Any
# Action:      DENY
# Log:         Enable
```

---

## Connection Health Monitoring

### Health Check Configuration

```bash
# Configure health checks for all Bastion connections
sudo wallix-am monitor health-check configure \
  --interval 10 \
  --timeout 5 \
  --failure-threshold 3 \
  --recovery-threshold 2 \
  --method api-ping

# View real-time connection health
sudo wallix-am monitor health-check status

# Expected output:
# Bastion           Status   Latency  Last Check           Uptime
# Bastion-Site1     HEALTHY  3ms      2026-03-31 14:30:05  99.99%
# Bastion-Site2     HEALTHY  8ms      2026-03-31 14:30:05  99.97%
# Bastion-Site3     DEGRADED 45ms     2026-03-31 14:30:05  99.85%

# Configure alerts
sudo wallix-am monitor alert add \
  --metric bastion-latency \
  --threshold 100 \
  --notify admin@company.com

sudo wallix-am monitor alert add \
  --metric bastion-status \
  --condition down \
  --notify admin@company.com,ops-team@company.com
```

### Connection Metrics

```bash
# View connection statistics
sudo wallix-am monitor metrics show --bastion "Bastion-Site1"

# Expected output:
# Bastion-Site1 Connection Metrics (last 24h)
# ============================================
# API Requests:        12,450
# API Success Rate:    99.98%
# API Avg Latency:     3ms
# API P95 Latency:     8ms
# API P99 Latency:     15ms
#
# Active Sessions:     45
# Peak Sessions:       120 (at 10:30)
# Sessions Launched:   340
# Sessions Failed:     2 (0.59%)
#
# Credential Checkouts: 340
# Credential Checkins:  338
#
# WebSocket Messages:  45,200
# WS Reconnections:    0
# WS Avg Latency:      1ms

# Export metrics for Prometheus/Grafana
sudo wallix-am monitor metrics export \
  --format prometheus \
  --endpoint /metrics \
  --port 9090
```

---

## Troubleshooting

### Common Connectivity Issues

#### Issue 1: Access Manager Cannot Reach Bastion API

**Symptoms:**
- "Bastion unreachable" error in portal
- Targets not populating in user view
- Session launch fails

**Diagnosis:**

```bash
# Test network connectivity
ping bastion-site1.company.com
telnet bastion-site1.company.com 443

# Test API endpoint
curl -sk https://bastion-site1.company.com/api/status

# Check Access Manager logs
sudo wallix-am logs show --filter bastion --level error --last 1h

# Verify API credentials
sudo wallix-am bastion test "Bastion-Site1" --verbose
```

**Resolution:**

```bash
# Check firewall rules
sudo iptables -L -n -v | grep 443

# Update API credentials if expired
sudo wallix-am bastion update "Bastion-Site1" \
  --api-key "$(cat /etc/wallix-am/bastion-site1-new.key)"

# Restart connectivity service
sudo systemctl restart wallix-am-connector
```

#### Issue 2: Session Launch Fails

**Symptoms:**
- User clicks target but session does not open
- "Session timeout" or "Connection refused" errors

**Diagnosis:**

```bash
# Check session broker logs
sudo wallix-am logs show --filter session --level error --last 1h

# Verify Bastion session capacity
sudo wallix-am bastion status "Bastion-Site1" --detail

# Check WebSocket connectivity
sudo wallix-am test websocket --bastion "Bastion-Site1"
```

**Resolution:**

```bash
# Clear stale sessions
sudo wallix-am session cleanup --stale --older-than 1h

# Restart HTML5 gateway
sudo systemctl restart wallix-am-gateway

# Verify Bastion license allows more sessions
sudo wallix-am bastion license-check "Bastion-Site1"
```

#### Issue 3: Certificate Errors

**Symptoms:**
- "TLS handshake failed" in logs
- "Certificate not trusted" errors

**Diagnosis:**

```bash
# Verify certificate chain
openssl s_client -connect bastion-site1.company.com:443 \
  -CAfile /etc/wallix-am/certs/corporate-root-ca.crt

# Check certificate expiry
sudo wallix-am cert check --bastion "Bastion-Site1"

# Verify trust store
sudo wallix-am cert trust list
```

**Resolution:**

```bash
# Update CA trust store
sudo wallix-am cert trust add \
  --ca-cert /etc/wallix-am/certs/new-root-ca.crt

# Renew client certificate (mTLS)
sudo wallix-am cert renew --bastion "Bastion-Site1"

# Restart after certificate changes
sudo systemctl restart wallix-access-manager
```

#### Issue 4: High Latency or Timeouts

**Symptoms:**
- Sessions slow to launch
- API calls timing out
- Intermittent disconnections

**Diagnosis:**

```bash
# Check network latency
sudo wallix-am monitor ping --bastion "Bastion-Site1" --count 10

# Check API response times
sudo wallix-am bastion test "Bastion-Site1" --benchmark

# Check system resources
sudo wallix-am monitor system
```

**Resolution:**

```bash
# Increase timeout values
sudo wallix-am config set --api-timeout 60
sudo wallix-am config set --session-keepalive-interval 15

# Enable connection pooling
sudo wallix-am config set --api-connection-pool-size 20
sudo wallix-am config set --api-connection-keep-alive true

# Clear API cache if stale data is causing retries
sudo wallix-am cache flush --type api
```

---

## Best Practices

### Connectivity Best Practices

1. **Use VIP Addresses for HA Bastion**
   - Always point Access Manager to the Bastion VIP, not individual node IPs
   - Allows transparent failover without reconfiguration
   ```bash
   sudo wallix-am bastion add \
     --host bastion-vip-site1.company.com \
     --ha-vip 10.10.1.25
   ```

2. **Enable Mutual TLS**
   - Use mTLS for all Access Manager to Bastion connections
   - Prevents unauthorized API access even if API keys are compromised
   - Rotate client certificates annually

3. **Restrict API Service Account Permissions**
   - Create a dedicated API account with minimal required permissions
   - Restrict source IP to Access Manager addresses only
   - Enable API key rotation every 90 days
   ```bash
   wabadmin user update am-service \
     --ip-restriction 10.100.1.11,10.100.1.12 \
     --api-key-expiry 90d
   ```

4. **Configure Connection Pooling**
   - Use persistent connections to reduce TLS handshake overhead
   - Set pool size based on expected concurrent sessions
   ```bash
   sudo wallix-am config set --api-connection-pool-size 20
   ```

5. **Implement Health Monitoring**
   - Configure health checks with appropriate intervals
   - Set up alerts for latency spikes and connection failures
   - Forward metrics to central monitoring (Prometheus/Grafana)

6. **Cache API Responses**
   - Cache target lists and authorization data to reduce Bastion API load
   - Set TTL based on how frequently targets change
   - Invalidate cache on Bastion configuration changes

7. **Plan for Multi-Site Failover**
   - Define fallback Bastion instances for each site
   - Test cross-site failover quarterly
   - Document recovery procedures
   ```bash
   sudo wallix-am federation route add \
     --name "Site1-Failover" \
     --preferred-bastion "Bastion-Site1" \
     --fallback-bastion "Bastion-Site2"
   ```

8. **Audit All Connectivity Events**
   - Log API calls, session launches, credential checkouts
   - Forward audit logs to SIEM
   - Retain logs according to compliance requirements
   ```bash
   sudo wallix-am config set --audit-api-calls true
   sudo wallix-am config set --audit-syslog-target siem.company.com:514
   ```

---

## See Also

**Related Sections:**
- [47 - Access Manager Setup](../47-access-manager/README.md) - Installation and configuration
- [11 - High Availability](../11-high-availability/README.md) - HA deployment patterns
- [28 - Certificate Management](../28-certificate-management/README.md) - TLS and PKI
- [32 - Load Balancer](../32-load-balancer/README.md) - HAProxy configuration
- [29 - Disaster Recovery](../29-disaster-recovery/README.md) - DR procedures
- [10 - API Automation](../10-api-automation/README.md) - Bastion REST API reference

**Related Documentation:**
- [Install Guide](/install/HOWTO.md) - Multi-site installation
- [Pre-Production Lab](/pre/README.md) - Lab environment setup

**Official Resources:**
- [WALLIX Access Manager Documentation](https://pam.wallix.one/documentation/admin-doc/am-admin-guide_en.pdf)
- [WALLIX Bastion REST API Reference](https://pam.wallix.one/documentation/api-doc/api-reference_en.pdf)
- [WALLIX Documentation Portal](https://pam.wallix.one/documentation)

---

*Document Version: 1.0*
*Last Updated: March 2026*
*Applies to: WALLIX Access Manager 5.2.x, WALLIX Bastion 12.3.2*
