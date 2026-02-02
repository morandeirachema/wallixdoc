# 47 - Fortigate Integration

## Fortigate Firewall and FortiAuthenticator MFA Integration with WALLIX Bastion

This section covers comprehensive integration of Fortinet products with WALLIX Bastion, including Fortigate firewall placement, SSL VPN integration, and FortiAuthenticator MFA configuration.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Fortigate Firewall Placement](#fortigate-firewall-placement)
3. [SSL VPN Integration](#ssl-vpn-integration)
4. [FortiAuthenticator MFA](#fortiauthenticator-mfa)
5. [Policy Routing to HAProxy](#policy-routing-to-haproxy)
6. [Fortigate HA Configuration](#fortigate-ha-configuration)
7. [Firewall Rules for WALLIX](#firewall-rules-for-wallix)
8. [VPN + MFA Authentication Flow](#vpn--mfa-authentication-flow)
9. [Fortigate Logging to WALLIX](#fortigate-logging-to-wallix)
10. [Troubleshooting](#troubleshooting)

---

## Architecture Overview

### 4-Site Synchronized Architecture

```
+===============================================================================+
|  FORTIGATE + WALLIX INTEGRATED ARCHITECTURE                                   |
+===============================================================================+
|                                                                               |
|                            +-------------------+                              |
|                            | FortiAuthenticator |                             |
|                            |    (MFA Server)    |                             |
|                            |   10.10.0.60       |                             |
|                            +--------+----------+                              |
|                                     | RADIUS                                  |
|        +-------------+-------------+-------------+-------------+              |
|        |             |             |             |             |              |
|  +-----v-----+ +-----v-----+ +-----v-----+ +-----v-----+                      |
|  | Fortigate | | Fortigate | | Fortigate | | Fortigate |                      |
|  |  Site 1   | |  Site 2   | |  Site 3   | |  Site 4   |                      |
|  +-----+-----+ +-----+-----+ +-----+-----+ +-----+-----+                      |
|        |             |             |             |                            |
|  +-----v-----+ +-----v-----+ +-----v-----+ +-----v-----+                      |
|  | HAProxy   | | HAProxy   | | HAProxy   | | HAProxy   |                      |
|  | HA Pair   | | HA Pair   | | HA Pair   | | HA Pair   |                      |
|  +-----+-----+ +-----+-----+ +-----+-----+ +-----+-----+                      |
|        |             |             |             |                            |
|  +-----v-----+ +-----v-----+ +-----v-----+ +-----v-----+                      |
|  | WALLIX    | | WALLIX    | | WALLIX    | | WALLIX    |                      |
|  | Bastion   | | Bastion   | | Bastion   | | Bastion   |                      |
|  | HA Pair   | | HA Pair   | | HA Pair   | | HA Pair   |                      |
|  +-----+-----+ +-----+-----+ +-----+-----+ +-----+-----+                      |
|        |             |             |             |                            |
|  +-----v-----+ +-----v-----+ +-----v-----+ +-----v-----+                      |
|  | WALLIX    | | WALLIX    | | WALLIX    | | WALLIX    |                      |
|  |   RDS     | |   RDS     | |   RDS     | |   RDS     |                      |
|  +-----------+ +-----------+ +-----------+ +-----------+                      |
|                                                                               |
+===============================================================================+
```

### Single Site Detail

```
+===============================================================================+
|  SINGLE SITE - FORTIGATE INTEGRATION                                          |
+===============================================================================+
|                                                                               |
|  INTERNET/WAN                                                                 |
|       |                                                                       |
|  +----v--------------------+                                                  |
|  |      FORTIGATE FW       |  Primary Perimeter Defense                       |
|  |  (FortiGate 100F/200F)  |  - Firewall policies                             |
|  |     10.10.1.1           |  - SSL VPN endpoint                              |
|  +-----------+-------------+  - FortiAuth RADIUS client                       |
|              |                                                                |
|  +-----------v-------------+     +--------------------+                       |
|  |     HAProxy-1 (VIP)     |<--->|     HAProxy-2      |  Keepalived VRRP      |
|  |     10.10.1.5           |     |     10.10.1.6      |  VIP: 10.10.1.100     |
|  +-----------+-------------+     +--------------------+                       |
|              |                                                                |
|  +-----------v-------------+     +--------------------+                       |
|  |   WALLIX Bastion-1      |<--->|  WALLIX Bastion-2  |  Active-Active HA     |
|  |     10.10.1.11          |     |    10.10.1.12      |  MariaDB Stream    |
|  +-----------+-------------+     +--------------------+                       |
|              |                                                                |
|  +-----------v-------------+                                                  |
|  |      WALLIX RDS         |  Windows Session Manager                         |
|  |     10.10.1.30          |  RDP Recording, OCR                              |
|  +-----------+-------------+                                                  |
|              |                                                                |
|  +-----------v-------------+     +--------------------+                       |
|  |  Windows Server 2022    |     |  RHEL 10 / RHEL 9  |  Target Systems       |
|  |   (RDP, WinRM)          |     |     (SSH)          |                       |
|  +-------------------------+     +--------------------+                       |
|                                                                               |
+===============================================================================+
```

---

## Fortigate Firewall Placement

### Network Topology

| Zone | VLAN | Subnet | Description |
|------|------|--------|-------------|
| WAN | - | Public IP | Internet-facing |
| DMZ | 110 | 10.10.1.0/24 | HAProxy, WALLIX, FortiAuth |
| Servers | 120 | 10.10.2.0/24 | Windows, RHEL targets |
| Management | 100 | 10.10.0.0/24 | AD, SIEM, Management |

### Fortigate Interface Configuration

```
config system interface
    edit "wan1"
        set vdom "root"
        set ip 203.0.113.1 255.255.255.0
        set allowaccess ping https ssh
        set type physical
        set alias "Internet"
    next
    edit "dmz"
        set vdom "root"
        set ip 10.10.1.1 255.255.255.0
        set allowaccess ping https ssh
        set type physical
        set alias "DMZ-WALLIX"
    next
    edit "servers"
        set vdom "root"
        set ip 10.10.2.1 255.255.255.0
        set allowaccess ping
        set type physical
        set alias "Server-Zone"
    next
    edit "management"
        set vdom "root"
        set ip 10.10.0.1 255.255.255.0
        set allowaccess ping https ssh
        set type physical
        set alias "Management"
    next
end
```

---

## SSL VPN Integration

### SSL VPN Portal Configuration

```
config vpn ssl web portal
    edit "WALLIX-Portal"
        set tunnel-mode enable
        set web-mode disable
        set ip-pools "SSL-VPN-Pool"
        set split-tunneling enable
        set split-tunneling-routing-address "10.10.1.0/24" "10.10.2.0/24"
        set dns-server1 10.10.0.10
        set dns-suffix "lab.local"
    next
end

config firewall address
    edit "SSL-VPN-Pool"
        set type iprange
        set start-ip 10.10.10.1
        set end-ip 10.10.10.254
    next
end
```

### SSL VPN Settings

```
config vpn ssl settings
    set servercert "Fortinet_Factory"
    set tunnel-ip-pools "SSL-VPN-Pool"
    set tunnel-ipv6-pools ""
    set dns-server1 10.10.0.10
    set source-interface "wan1"
    set source-address "all"
    set default-portal "WALLIX-Portal"
    set port 443
    set ssl-min-proto-ver tls1-2
    set algorithm high
    set idle-timeout 300
    set auth-timeout 43200
    set dtls-tunnel enable
end
```

### SSL VPN User Group with FortiAuth MFA

```
config user group
    edit "WALLIX-VPN-Users"
        set member "ldap-users"
        config match
            edit 1
                set server-name "FortiAuth-RADIUS"
                set group-name "WALLIX-Admins"
            next
        end
    next
end

config vpn ssl web user-group-bookmark
    edit "WALLIX-VPN-Users"
        config bookmarks
            edit "WALLIX-Web"
                set apptype web
                set url "https://10.10.1.100"
                set description "WALLIX Bastion Web UI"
            next
        end
    next
end
```

### VPN Policy

```
config firewall policy
    edit 100
        set name "SSL-VPN-to-DMZ"
        set srcintf "ssl.root"
        set dstintf "dmz"
        set srcaddr "SSL-VPN-Pool"
        set dstaddr "WALLIX-VIP" "WALLIX-Nodes"
        set action accept
        set schedule "always"
        set service "HTTPS" "SSH" "RDP"
        set logtraffic all
        set groups "WALLIX-VPN-Users"
        set ssl-ssh-profile "certificate-inspection"
    next
end
```

---

## FortiAuthenticator MFA

### RADIUS Server Configuration on Fortigate

```
config user radius
    edit "FortiAuth-RADIUS"
        set server "10.10.0.60"
        set secret ENC XXXXXXXXXXXX
        set radius-port 1812
        set acct-interim-interval 600
        set source-ip 10.10.1.1
        config accounting-server
            edit 1
                set status enable
                set server "10.10.0.60"
                set secret ENC XXXXXXXXXXXX
                set port 1813
            next
        end
    next
end
```

### FortiAuthenticator RADIUS Client for Fortigate

**On FortiAuthenticator Web UI:**

```
1. Login to FortiAuthenticator
   URL: https://10.10.0.60

2. Navigate to: Authentication > RADIUS Service > Clients

3. Create RADIUS Client for Fortigate:
   Name:           Fortigate-Site1
   Client IP/Name: 10.10.1.1
   Secret:         [Strong shared secret]
   Description:    Fortigate Firewall Site 1

   Authentication:
   [x] Enable
   [ ] Authorize only

   Profile:        Default

4. Click OK
```

### FortiAuthenticator RADIUS Client for WALLIX

```
1. Create RADIUS Client for WALLIX Node 1:
   Name:           WALLIX-Node1
   Client IP/Name: 10.10.1.11
   Secret:         [Strong shared secret - can be different from Fortigate]
   Description:    WALLIX Bastion Primary Node

2. Create RADIUS Client for WALLIX Node 2:
   Name:           WALLIX-Node2
   Client IP/Name: 10.10.1.12
   Secret:         [Same secret as Node 1]
   Description:    WALLIX Bastion Secondary Node
```

### FortiToken Mobile Configuration

```
1. Navigate to: Authentication > FortiToken > FortiToken Mobile

2. Create FortiToken provisioning:
   Provisioning Method: Email
   Token Timeout:       60 seconds

3. Enable Push Notifications:
   [x] Enable push
   Push Server:    FortiGuard

4. Assign tokens to users via:
   Authentication > User Management > Remote Users > [user] > FortiToken
```

---

## Policy Routing to HAProxy

### Virtual IP (VIP) Configuration

```
config firewall vip
    edit "WALLIX-HTTPS-VIP"
        set type static-nat
        set extip 203.0.113.10
        set mappedip "10.10.1.100"
        set extintf "wan1"
        set portforward enable
        set extport 443
        set mappedport 443
    next
    edit "WALLIX-SSH-VIP"
        set type static-nat
        set extip 203.0.113.10
        set mappedip "10.10.1.100"
        set extintf "wan1"
        set portforward enable
        set extport 22
        set mappedport 22
    next
    edit "WALLIX-RDP-VIP"
        set type static-nat
        set extip 203.0.113.10
        set mappedip "10.10.1.100"
        set extintf "wan1"
        set portforward enable
        set extport 3389
        set mappedport 3389
    next
end
```

### Address Objects

```
config firewall address
    edit "WALLIX-VIP"
        set type ipmask
        set subnet 10.10.1.100 255.255.255.255
    next
    edit "WALLIX-Node1"
        set type ipmask
        set subnet 10.10.1.11 255.255.255.255
    next
    edit "WALLIX-Node2"
        set type ipmask
        set subnet 10.10.1.12 255.255.255.255
    next
    edit "HAProxy-1"
        set type ipmask
        set subnet 10.10.1.5 255.255.255.255
    next
    edit "HAProxy-2"
        set type ipmask
        set subnet 10.10.1.6 255.255.255.255
    next
    edit "FortiAuthenticator"
        set type ipmask
        set subnet 10.10.0.60 255.255.255.255
    next
    edit "Windows-Servers"
        set type ipmask
        set subnet 10.10.2.0 255.255.255.240
    next
    edit "RHEL-Servers"
        set type ipmask
        set subnet 10.10.2.16 255.255.255.240
    next
end

config firewall addrgrp
    edit "WALLIX-Nodes"
        set member "WALLIX-Node1" "WALLIX-Node2"
    next
    edit "HAProxy-Cluster"
        set member "HAProxy-1" "HAProxy-2"
    next
    edit "Target-Servers"
        set member "Windows-Servers" "RHEL-Servers"
    next
end
```

---

## Fortigate HA Configuration

### HA Cluster (Active-Passive)

```
config system ha
    set group-id 10
    set group-name "WALLIX-FW-Cluster"
    set mode a-p
    set hbdev "port3" 50
    set session-pickup enable
    set session-pickup-connectionless enable
    set session-pickup-delay enable
    set link-failed-signal enable
    set ha-mgmt-status enable
    config ha-mgmt-interfaces
        edit 1
            set interface "mgmt"
            set gateway 10.10.0.1
        next
    end
    set override disable
    set priority 200
    set monitor "wan1" "dmz" "servers"
end
```

### HA Secondary Unit

```
# On secondary Fortigate:
config system ha
    set group-id 10
    set group-name "WALLIX-FW-Cluster"
    set mode a-p
    set hbdev "port3" 50
    set session-pickup enable
    set override disable
    set priority 100
    set monitor "wan1" "dmz" "servers"
end
```

---

## Firewall Rules for WALLIX

### Inbound Policies (WAN to DMZ)

```
config firewall policy
    edit 10
        set name "WAN-to-WALLIX-HTTPS"
        set srcintf "wan1"
        set dstintf "dmz"
        set srcaddr "all"
        set dstaddr "WALLIX-HTTPS-VIP"
        set action accept
        set schedule "always"
        set service "HTTPS"
        set logtraffic all
        set ssl-ssh-profile "certificate-inspection"
    next
    edit 11
        set name "WAN-to-WALLIX-SSH"
        set srcintf "wan1"
        set dstintf "dmz"
        set srcaddr "all"
        set dstaddr "WALLIX-SSH-VIP"
        set action accept
        set schedule "always"
        set service "SSH"
        set logtraffic all
    next
    edit 12
        set name "WAN-to-WALLIX-RDP"
        set srcintf "wan1"
        set dstintf "dmz"
        set srcaddr "all"
        set dstaddr "WALLIX-RDP-VIP"
        set action accept
        set schedule "always"
        set service "RDP"
        set logtraffic all
    next
end
```

### DMZ Internal Policies

```
config firewall policy
    edit 20
        set name "HAProxy-to-WALLIX"
        set srcintf "dmz"
        set dstintf "dmz"
        set srcaddr "HAProxy-Cluster"
        set dstaddr "WALLIX-Nodes"
        set action accept
        set schedule "always"
        set service "HTTPS" "SSH"
        set logtraffic all
    next
    edit 21
        set name "WALLIX-HA-Sync"
        set srcintf "dmz"
        set dstintf "dmz"
        set srcaddr "WALLIX-Nodes"
        set dstaddr "WALLIX-Nodes"
        set action accept
        set schedule "always"
        set service "MariaDB" "Corosync"
        set logtraffic all
    next
    edit 22
        set name "WALLIX-to-FortiAuth"
        set srcintf "dmz"
        set dstintf "management"
        set srcaddr "WALLIX-Nodes"
        set dstaddr "FortiAuthenticator"
        set action accept
        set schedule "always"
        set service "RADIUS" "RADIUS-Accounting"
        set logtraffic all
    next
end
```

### DMZ to Servers Policies

```
config firewall policy
    edit 30
        set name "WALLIX-to-Windows-RDP"
        set srcintf "dmz"
        set dstintf "servers"
        set srcaddr "WALLIX-Nodes"
        set dstaddr "Windows-Servers"
        set action accept
        set schedule "always"
        set service "RDP" "WinRM"
        set logtraffic all
    next
    edit 31
        set name "WALLIX-to-RHEL-SSH"
        set srcintf "dmz"
        set dstintf "servers"
        set srcaddr "WALLIX-Nodes"
        set dstaddr "RHEL-Servers"
        set action accept
        set schedule "always"
        set service "SSH"
        set logtraffic all
    next
end
```

### Service Definitions

```
config firewall service custom
    edit "MariaDB"
        set tcp-portrange 3306
    next
    edit "Corosync"
        set udp-portrange 5404-5406
    next
    edit "WinRM"
        set tcp-portrange 5985-5986
    next
    edit "RADIUS"
        set udp-portrange 1812
    next
    edit "RADIUS-Accounting"
        set udp-portrange 1813
    next
end
```

---

## VPN + MFA Authentication Flow

### Complete Authentication Flow

```
+===============================================================================+
|  FORTIGATE VPN + MFA AUTHENTICATION FLOW                                      |
+===============================================================================+
|                                                                               |
|  1. USER INITIATES VPN CONNECTION                                             |
|     +--------+     SSL VPN (443)      +------------+                          |
|     |  User  | --------------------->| Fortigate  |                           |
|     |        |                        |            |                          |
|     +--------+                        +-----+------+                          |
|                                             |                                 |
|  2. FORTIGATE REQUESTS MFA                  v                                 |
|     +--------+     Username/Password  +------------+                          |
|     |  User  | <---------------------| Fortigate  |                           |
|     +--------+                        +-----+------+                          |
|         |                                   |                                 |
|         | Credentials                       | RADIUS Request                  |
|         v                                   v                                 |
|     +--------+                        +------------+                          |
|     |  User  | ---------------------->| Fortigate  |----------------------->  |
|     +--------+                        +-----+------+    FortiAuthenticator    |
|                                             |           (10.10.0.60:1812)     |
|                                             |                                 |
|  3. FORTIAUTHENTICATOR SENDS PUSH                                             |
|     +--------+     Push Notification                                          |
|     |  User  | <--------------------------------------------+                 |
|     | Mobile |                                              |                 |
|     +---+----+                        +------------+   +----+-------+         |
|         |                             | Fortigate  |   | FortiAuth  |         |
|         |                             +-----+------+   +-----+------+         |
|         |                                   |               |                 |
|  4. USER APPROVES PUSH                      |               |                 |
|         | Approve                           |               |                 |
|         +---------------------------------------------------+                 |
|                                             |               |                 |
|  5. ACCESS GRANTED                          | RADIUS Accept |                 |
|                                             | <-------------+                 |
|     +--------+     VPN Connected      +-----v------+                          |
|     |  User  | <---------------------| Fortigate  |                           |
|     +--------+                        +------------+                          |
|                                                                               |
|  6. USER ACCESSES WALLIX (THROUGH VPN)                                        |
|     +--------+     HTTPS (443)        +------------+                          |
|     |  User  | --------------------->|  HAProxy   |                           |
|     +--------+                        |   VIP      |                          |
|                                       +-----+------+                          |
|                                             |                                 |
|  7. WALLIX REQUESTS MFA (SECOND FACTOR)     v                                 |
|     +--------+     Username/Password  +------------+                          |
|     |  User  | <---------------------| WALLIX     |                           |
|     +--------+                        | Bastion    |                          |
|         |                             +-----+------+                          |
|         | Credentials                       | RADIUS Request                  |
|         v                                   v                                 |
|     +--------+                        +------------+                          |
|     |  User  | ---------------------->| WALLIX     |----------------------->  |
|     +--------+                        +-----+------+    FortiAuthenticator    |
|                                             |                                 |
|  8. FORTIAUTHENTICATOR SENDS SECOND PUSH                                      |
|     +--------+     Push Notification                                          |
|     |  User  | <--------------------------------------------+                 |
|     | Mobile |                                              |                 |
|     +---+----+                        +------------+   +----+-------+         |
|         |                             | WALLIX     |   | FortiAuth  |         |
|         | Approve                     +-----+------+   +-----+------+         |
|         +---------------------------------------------------+                 |
|                                             |               |                 |
|  9. SESSION ESTABLISHED                     | RADIUS Accept |                 |
|                                             | <-------------+                 |
|     +--------+     PAM Session        +-----v------+                          |
|     |  User  | <---------------------| WALLIX     |                           |
|     +--------+                        | Bastion    |                          |
|                                       +------------+                          |
|                                                                               |
+===============================================================================+
```

### Single Sign-On Option

To avoid double MFA prompts, configure WALLIX to trust Fortigate-authenticated sessions:

```
# On WALLIX Bastion
# Configuration > Authentication > Trusted Sources

Trusted Source: Fortigate-VPN
  Source IP Range: 10.10.10.0/24  (SSL VPN pool)
  Trust Level: Authenticated
  Skip MFA: Yes (MFA already done at VPN)
  Session Timeout: 8 hours
```

---

## Fortigate Logging to WALLIX

### Syslog Configuration

```
config log syslogd setting
    set status enable
    set server "10.10.1.11"
    set port 514
    set facility local7
    set source-ip "10.10.1.1"
    set format default
end

config log syslogd filter
    set severity information
    set forward-traffic enable
    set local-traffic enable
    set multicast-traffic enable
    set sniffer-traffic disable
    set anomaly enable
    set voip disable
    set gtp disable
    set free-style enable
    config free-style
        edit 1
            set category traffic
            set filter "action==accept"
        next
        edit 2
            set category event
            set filter "subtype==vpn"
        next
    end
end
```

### WALLIX Syslog Receiver Configuration

```bash
# On WALLIX Bastion, configure syslog receiver
wabadmin syslog add-source \
    --name "Fortigate-FW" \
    --ip "10.10.1.1" \
    --port 514 \
    --protocol udp \
    --format syslog-rfc5424

# Enable correlation with VPN authentication events
wabadmin correlation add-rule \
    --name "VPN-Login-Correlation" \
    --source "Fortigate-FW" \
    --pattern "vpn.*tunnel-up" \
    --action "log-enrichment"
```

### FortiAnalyzer Integration (Optional)

```
config log fortianalyzer setting
    set status enable
    set server "10.10.0.70"
    set serial "FAZ-XXXXXXXXXXXX"
    set upload-option realtime
    set reliable enable
    set enc-algorithm high
    set ssl-min-proto-ver default
end
```

---

## Troubleshooting

### Common Issues

#### VPN Authentication Failures

```
# Check FortiAuthenticator logs
# FortiAuth > Monitor > Logs > Authentication

# Check Fortigate VPN debug
diagnose vpn ssl debug-filter src-addr 0.0.0.0/0
diagnose debug application sslvpn -1
diagnose debug enable

# Check RADIUS communication
diagnose test authserver radius FortiAuth-RADIUS mschap2 testuser testpass

# Verify RADIUS client on FortiAuth
# Authentication > RADIUS Service > Clients > [verify IP and secret]
```

#### RADIUS Timeout

```
# On Fortigate - check connectivity
execute ping 10.10.0.60
execute telnet 10.10.0.60 1812

# Verify RADIUS secret matches
config user radius
    edit "FortiAuth-RADIUS"
        show full-configuration
    end
end

# Increase timeout if needed
config user radius
    edit "FortiAuth-RADIUS"
        set timeout 60
    next
end
```

#### Push Notification Not Received

```
# On FortiAuthenticator:
# 1. Verify FortiToken Mobile registration
#    Authentication > FortiToken > FortiToken Mobile > [user's token]

# 2. Check push server connectivity
#    System > Administration > FortiGuard > FortiToken Push

# 3. Verify user's device has internet connectivity

# 4. Try OTP fallback:
#    User can enter 6-digit OTP from FortiToken Mobile app
```

#### WALLIX Cannot Reach FortiAuthenticator

```bash
# Test connectivity from WALLIX
nc -zvu 10.10.0.60 1812

# Check firewall rules on Fortigate
diagnose firewall packet-log enable
diagnose debug enable

# Verify policy allows WALLIX to FortiAuth
get firewall policy 22

# Test RADIUS from WALLIX
wabadmin auth radius test "FortiAuth-Primary"
```

### Debug Commands

#### Fortigate Debug

```
# VPN debug
diagnose debug application sslvpn -1
diagnose debug enable

# RADIUS debug
diagnose debug application radiusd -1
diagnose debug enable

# Firewall session debug
diagnose sys session filter src 10.10.1.11
diagnose sys session filter dst 10.10.0.60
diagnose sys session list
```

#### FortiAuthenticator Debug

```
# Check authentication logs
Monitor > Logs > Authentication

# Check RADIUS logs
Monitor > Logs > RADIUS

# Check system logs
Monitor > Logs > System

# Verify user token status
Authentication > User Management > [user] > FortiToken
```

#### WALLIX Debug

```bash
# Enable RADIUS debug
wabadmin log level radius debug

# View RADIUS logs
tail -f /var/log/wabengine/radius.log

# Test authentication
wabadmin auth test \
    --user "testuser" \
    --provider radius \
    --debug

# Disable debug
wabadmin log level radius info
```

---

## Quick Reference

### Port Reference

| Port | Protocol | Source | Destination | Description |
|------|----------|--------|-------------|-------------|
| 443 | TCP | Internet | Fortigate | SSL VPN |
| 443 | TCP | VPN Users | HAProxy VIP | WALLIX Web UI |
| 22 | TCP | VPN Users | HAProxy VIP | SSH Proxy |
| 3389 | TCP | VPN Users | HAProxy VIP | RDP Proxy |
| 1812 | UDP | Fortigate | FortiAuth | RADIUS Auth |
| 1813 | UDP | Fortigate | FortiAuth | RADIUS Accounting |
| 1812 | UDP | WALLIX | FortiAuth | RADIUS Auth |
| 1813 | UDP | WALLIX | FortiAuth | RADIUS Accounting |
| 3306 | TCP | WALLIX | WALLIX | MariaDB Replication |
| 5404-5406 | UDP | WALLIX | WALLIX | Corosync Cluster |

### Key IP Addresses

| Component | IP Address | Description |
|-----------|------------|-------------|
| Fortigate WAN | 203.0.113.1 | Public IP |
| Fortigate DMZ | 10.10.1.1 | DMZ gateway |
| HAProxy VIP | 10.10.1.100 | WALLIX entry point |
| WALLIX Node 1 | 10.10.1.11 | Primary Bastion |
| WALLIX Node 2 | 10.10.1.12 | Secondary Bastion |
| FortiAuthenticator | 10.10.0.60 | MFA Server |

### Essential Commands

```bash
# Fortigate - Check VPN users
get vpn ssl monitor

# Fortigate - Check HA status
get system ha status

# WALLIX - Check MFA status
wabadmin auth mfa status

# WALLIX - Test RADIUS
wabadmin auth radius test "FortiAuth-Primary"
```

---

## Related Documentation

| Topic | Link |
|-------|------|
| FortiAuthenticator Integration | [fortiauthenticator-integration.md](../06-authentication/fortiauthenticator-integration.md) |
| HAProxy Load Balancer | [../32-load-balancer/README.md](../32-load-balancer/README.md) |
| High Availability | [../11-high-availability/README.md](../11-high-availability/README.md) |
| Pre-Production Lab | [../../pre/04-fortiauthenticator-setup.md](../../../pre/04-fortiauthenticator-setup.md) |

---

<p align="center">
  <a href="../46-privileged-task-automation/README.md">← Previous: Privileged Task Automation</a>
</p>
