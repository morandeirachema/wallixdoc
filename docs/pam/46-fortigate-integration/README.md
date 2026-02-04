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

### Complete FortiAuthenticator RADIUS Configuration

This section provides step-by-step FortiAuthenticator RADIUS setup for WALLIX integration.

#### Step 1: FortiAuthenticator RADIUS Client Setup

```
+===============================================================================+
|  STEP 1: CONFIGURE RADIUS CLIENTS ON FORTIAUTHENTICATOR                      |
+===============================================================================+

1. LOGIN TO FORTIAUTHENTICATOR
   URL: https://10.10.0.60
   Username: admin
   Password: [admin password]

2. NAVIGATE TO RADIUS SERVICE
   Authentication > RADIUS Service > Clients

3. CREATE RADIUS CLIENT FOR WALLIX NODE 1
   +----------------------------------------------------------------------+
   | Parameter        | Value                                             |
   +------------------+---------------------------------------------------+
   | Name             | WALLIX-Bastion-Node1                              |
   | Client IP/Name   | 10.10.1.11                                        |
   | Secret           | [Generate strong secret, e.g., 32 chars]          |
   | Confirm Secret   | [Same as above]                                   |
   | Description      | WALLIX Bastion Primary Node - Site 1             |
   | Authentication   | [x] Enable                                        |
   | Authorize Only   | [ ] (unchecked)                                   |
   | Profile          | Default                                           |
   | Vendor           | Default                                           |
   +------------------+---------------------------------------------------+

   Click: [OK]

4. CREATE RADIUS CLIENT FOR WALLIX NODE 2
   (Repeat step 3 with following changes:)
   Name:            WALLIX-Bastion-Node2
   Client IP/Name:  10.10.1.12
   Secret:          [SAME secret as Node 1]
   Description:     WALLIX Bastion Secondary Node - Site 1

   Click: [OK]

5. VERIFY RADIUS CLIENTS
   You should see two entries:
   - WALLIX-Bastion-Node1 (10.10.1.11)
   - WALLIX-Bastion-Node2 (10.10.1.12)

+===============================================================================+
```

#### Step 2: WALLIX RADIUS Configuration

```
+===============================================================================+
|  STEP 2: CONFIGURE RADIUS ON WALLIX BASTION                                  |
+===============================================================================+

METHOD A: WEB UI CONFIGURATION
==============================

1. LOGIN TO WALLIX WEB UI
   URL: https://10.10.1.100 (HAProxy VIP)
   Username: admin
   Password: [admin password]

2. NAVIGATE TO AUTHENTICATION SETTINGS
   Configuration > Authentication > RADIUS Servers

3. ADD RADIUS SERVER
   +----------------------------------------------------------------------+
   | Parameter              | Value                                       |
   +------------------------+---------------------------------------------+
   | Name                   | FortiAuthenticator-MFA                      |
   | Description            | FortiAuthenticator RADIUS for MFA           |
   | Primary Server         | 10.10.0.60                                  |
   | Primary Port           | 1812                                        |
   | Primary Secret         | [Secret from Step 1]                        |
   | Secondary Server       | (leave empty if single FA)                  |
   | Secondary Port         | 1812                                        |
   | Secondary Secret       | (leave empty)                               |
   | Timeout (seconds)      | 5                                           |
   | Retries                | 3                                           |
   | Accounting             | [x] Enable                                  |
   | Accounting Port        | 1813                                        |
   | NAS Identifier         | WALLIX-Bastion-Site1                        |
   +------------------------+---------------------------------------------+

   Click: [Save]

4. ASSIGN RADIUS TO AUTHENTICATION DOMAIN
   Configuration > Authentication > Domains > [Default Domain]

   Authentication Methods:
   [x] LDAP (Active Directory)
   [x] RADIUS (FortiAuthenticator-MFA)

   2FA Settings:
   [x] Require Multi-Factor Authentication
   MFA Provider: RADIUS (FortiAuthenticator-MFA)

   Click: [Save]

METHOD B: CLI CONFIGURATION (wabadmin)
======================================

1. SSH TO WALLIX BASTION
   ssh admin@10.10.1.11

2. CONFIGURE RADIUS SERVER
   wabadmin radius add \
     --name "FortiAuthenticator-MFA" \
     --host "10.10.0.60" \
     --port 1812 \
     --secret "[secret from Step 1]" \
     --timeout 5 \
     --retries 3 \
     --accounting-port 1813 \
     --nas-id "WALLIX-Bastion-Site1"

3. VERIFY CONFIGURATION
   wabadmin radius list

   Expected Output:
   Name: FortiAuthenticator-MFA
   Host: 10.10.0.60:1812
   Timeout: 5s
   Retries: 3
   Accounting: Enabled (port 1813)
   Status: Active

4. ENABLE RADIUS FOR AUTHENTICATION
   wabadmin auth domain-update default \
     --mfa-provider radius \
     --mfa-required yes

+===============================================================================+
```

#### Step 3: Test Authentication Flow

```
+===============================================================================+
|  STEP 3: TEST RADIUS AUTHENTICATION                                          |
+===============================================================================+

1. TEST FROM WALLIX CLI
   ------------------------
   wabadmin radius test \
     --server FortiAuthenticator-MFA \
     --username testuser \
     --password "userpassword" \
     --otp "123456"

   Expected Output (Success):
   [OK] RADIUS authentication successful
   Access-Accept received from 10.10.0.60
   User: testuser
   Session-Timeout: 3600

   Expected Output (Failure):
   [FAIL] RADIUS authentication failed
   Access-Reject received from 10.10.0.60
   Reject-Reason: Invalid OTP code

2. TEST FROM FORTIAUTHENTICATOR LOGS
   ------------------------------------
   On FortiAuthenticator:
   System > Log > Authentication

   Look for entries like:
   [2026-02-04 14:30:15] RADIUS Authentication Request
   Client: 10.10.1.11 (WALLIX-Bastion-Node1)
   User: testuser
   Result: Access-Accept
   OTP: Valid (FortiToken Mobile)

3. TEST END-USER LOGIN
   ---------------------
   a. User navigates to: https://10.10.1.100
   b. Enters username: testuser
   c. Enters LDAP password: [password]
   d. Prompted for MFA: "Enter FortiToken code:"
   e. Opens FortiToken Mobile app
   f. Enters 6-digit code from app
   g. Should successfully login to WALLIX

4. VERIFY SESSION ESTABLISHED
   ----------------------------
   On WALLIX CLI:
   wabadmin session list

   Should show active session for testuser with:
   Auth-Method: LDAP+RADIUS
   MFA-Status: Verified

+===============================================================================+
```

#### Step 4: Troubleshooting

```
+===============================================================================+
|  STEP 4: TROUBLESHOOTING RADIUS AUTHENTICATION                               |
+===============================================================================+

ISSUE 1: RADIUS Timeout (WAB-1007-RADIUS_TIMEOUT)
===================================================

Symptoms:
- Login hangs for 15-20 seconds
- Error: "RADIUS server timeout"

Diagnosis:
1. Check network connectivity:
   ping 10.10.0.60
   nc -uzv 10.10.0.60 1812

2. Check WALLIX to FortiAuth firewall rule:
   # On Fortigate:
   diagnose sniffer packet any 'host 10.10.0.60 and port 1812' 4 0 l

3. Verify RADIUS client IP on FortiAuthenticator

Resolution:
- Verify firewall allows UDP 1812/1813 from WALLIX to FortiAuth
- Check FortiAuthenticator RADIUS service is running:
  System > Services > RADIUS Service: [Running]
- Increase timeout on WALLIX: wabadmin radius update --timeout 10

ISSUE 2: Access-Reject with Valid Credentials
==============================================

Symptoms:
- User password is correct
- OTP code is valid
- Still receives Access-Reject

Diagnosis:
1. Check FortiAuthenticator logs:
   System > Log > Authentication
   Look for reject reason

2. Verify user has FortiToken assigned:
   Authentication > User Management > Remote Users > [user]
   FortiToken Status: [Active]

3. Check RADIUS client configuration:
   Authentication > RADIUS Service > Clients
   Verify IP 10.10.1.11 and 10.10.1.12 are configured

Resolution:
- Ensure user exists in FortiAuthenticator user database
- Verify FortiToken is provisioned and active
- Check RADIUS shared secret matches on both sides
- Verify "Authorize Only" is UNCHECKED on RADIUS client

ISSUE 3: RADIUS Works Intermittently
=====================================

Symptoms:
- Authentication succeeds sometimes, fails other times
- No clear pattern

Diagnosis:
1. Check which WALLIX node is handling request:
   wabadmin radius test --debug

2. Verify both nodes have identical RADIUS config:
   # On Node 1:
   wabadmin radius show FortiAuthenticator-MFA
   # On Node 2:
   wabadmin radius show FortiAuthenticator-MFA

3. Check FortiAuthenticator has both nodes configured

Resolution:
- Ensure BOTH WALLIX nodes (10.10.1.11 and 10.10.1.12) are configured
  as RADIUS clients on FortiAuthenticator
- Use SAME shared secret for both nodes
- Verify HA cluster is healthy: crm status

ISSUE 4: Kerberos Clock Skew Error
===================================

Symptoms:
- RADIUS auth works but Kerberos fails
- Error: "Clock skew too great"

Diagnosis:
date  # On WALLIX
date  # On FortiAuthenticator (if using Kerberos)
date  # On Active Directory DC

Resolution:
- Synchronize NTP on all systems
- Maximum allowed clock skew: 5 minutes (300 seconds)
- Configure NTP on WALLIX:
  wabadmin ntp server-add ntp.company.com
  wabadmin ntp sync-now

DIAGNOSTIC COMMANDS
===================

# Check RADIUS configuration
wabadmin radius list
wabadmin radius show FortiAuthenticator-MFA

# Test RADIUS connectivity
wabadmin radius test --server FortiAuthenticator-MFA --username test

# View RADIUS authentication logs
tail -f /var/log/wallix/auth.log | grep RADIUS

# Check firewall rule (on WALLIX)
iptables -L -n -v | grep 1812

# Verify UDP port reachability
nc -uzv 10.10.0.60 1812
nc -uzv 10.10.0.60 1813

# Packet capture on WALLIX
tcpdump -i any -n udp port 1812 or udp port 1813

+===============================================================================+
```

#### Configuration Checklist

```
+===============================================================================+
|  FORTIAUTHENTICATOR RADIUS CONFIGURATION CHECKLIST                           |
+===============================================================================+

[ ] 1. FortiAuthenticator RADIUS clients created for both WALLIX nodes
        (10.10.1.11 and 10.10.1.12)

[ ] 2. Shared RADIUS secret matches on:
        - FortiAuthenticator RADIUS client config
        - WALLIX RADIUS server config (both nodes)

[ ] 3. Firewall rules allow UDP 1812/1813:
        - Source: WALLIX nodes (10.10.1.11, 10.10.1.12)
        - Destination: FortiAuthenticator (10.10.0.60)

[ ] 4. FortiAuthenticator users have FortiToken Mobile provisioned

[ ] 5. WALLIX authentication domain configured with:
        - Primary: LDAP (Active Directory)
        - MFA: RADIUS (FortiAuthenticator)

[ ] 6. RADIUS authentication tested successfully:
        - Test user can authenticate with password + OTP
        - Logs show Access-Accept from FortiAuthenticator

[ ] 7. NTP synchronized across all systems:
        - WALLIX Bastion nodes
        - FortiAuthenticator
        - Active Directory DCs

[ ] 8. RADIUS accounting enabled (optional but recommended):
        - Accounting port: 1813
        - NAS-Identifier configured

+===============================================================================+
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
    edit "LDAPS"
        set tcp-portrange 636
    next
    edit "LDAP"
        set tcp-portrange 389
    next
    edit "AD-Global-Catalog"
        set tcp-portrange 3268
    next
    edit "AD-Global-Catalog-SSL"
        set tcp-portrange 3269
    next
    edit "Kerberos"
        set tcp-portrange 88
        set udp-portrange 88
    next
    edit "Syslog-TLS"
        set tcp-portrange 6514
    next
    edit "Pacemaker"
        set tcp-portrange 2224
    next
end
```

### Complete Firewall Rule Set

This section provides the COMPLETE firewall rule set for a production WALLIX deployment.

```
+===============================================================================+
|  COMPLETE FORTIGATE FIREWALL RULE SET FOR WALLIX                             |
+===============================================================================+

RULE 1: VPN Users → WALLIX Web UI
==================================

config firewall policy
    edit 100
        set name "VPN-Users-to-WALLIX-Web"
        set srcintf "ssl.root"                    # VPN interface
        set dstintf "dmz"
        set srcaddr "VPN-Users-Group"             # VPN address range
        set dstaddr "WALLIX-HAProxy-VIP"          # HAProxy VIP
        set action accept
        set schedule "always"
        set service "HTTPS" "HTTP"
        set utm-status enable
        set ssl-ssh-profile "certificate-inspection"
        set av-profile "default"
        set ips-sensor "default"
        set logtraffic all
        set comments "VPN users access WALLIX Web UI via HAProxy"
    next
end

RULE 2: VPN Users → WALLIX SSH/RDP Proxy
=========================================

config firewall policy
    edit 101
        set name "VPN-Users-to-WALLIX-Sessions"
        set srcintf "ssl.root"
        set dstintf "dmz"
        set srcaddr "VPN-Users-Group"
        set dstaddr "WALLIX-HAProxy-VIP"
        set action accept
        set schedule "always"
        set service "SSH" "RDP"
        set logtraffic all
        set comments "VPN users SSH/RDP sessions through WALLIX"
    next
end

RULE 3: WALLIX → Active Directory (LDAP/LDAPS)
===============================================

config firewall policy
    edit 110
        set name "WALLIX-to-AD-LDAP"
        set srcintf "dmz"
        set dstintf "management"
        set srcaddr "WALLIX-Nodes"                # Both nodes
        set dstaddr "AD-Domain-Controllers"       # All DCs
        set action accept
        set schedule "always"
        set service "LDAP" "LDAPS" "AD-Global-Catalog" "AD-Global-Catalog-SSL"
        set logtraffic all
        set comments "WALLIX LDAP/LDAPS authentication to AD"
    next
end

RULE 4: WALLIX → Active Directory (Kerberos)
=============================================

config firewall policy
    edit 111
        set name "WALLIX-to-AD-Kerberos"
        set srcintf "dmz"
        set dstintf "management"
        set srcaddr "WALLIX-Nodes"
        set dstaddr "AD-Domain-Controllers"
        set action accept
        set schedule "always"
        set service "Kerberos"
        set logtraffic all
        set comments "WALLIX Kerberos authentication (optional SSO)"
    next
end

RULE 5: WALLIX → FortiAuthenticator (RADIUS)
=============================================

config firewall policy
    edit 112
        set name "WALLIX-to-FortiAuth-RADIUS"
        set srcintf "dmz"
        set dstintf "management"
        set srcaddr "WALLIX-Nodes"
        set dstaddr "FortiAuthenticator"          # 10.10.0.60
        set action accept
        set schedule "always"
        set service "RADIUS" "RADIUS-Accounting"  # UDP 1812, 1813
        set logtraffic all
        set comments "WALLIX MFA via FortiAuthenticator RADIUS"
    next
end

RULE 6: WALLIX → Windows Target Servers
========================================

config firewall policy
    edit 120
        set name "WALLIX-to-Windows-Targets"
        set srcintf "dmz"
        set dstintf "servers"
        set srcaddr "WALLIX-Nodes"
        set dstaddr "Windows-Servers"             # Windows Server 2022
        set action accept
        set schedule "always"
        set service "RDP" "WinRM"                 # TCP 3389, 5985, 5986
        set logtraffic all
        set comments "WALLIX sessions to Windows targets"
    next
end

RULE 7: WALLIX → Linux Target Servers
======================================

config firewall policy
    edit 121
        set name "WALLIX-to-Linux-Targets"
        set srcintf "dmz"
        set dstintf "servers"
        set srcaddr "WALLIX-Nodes"
        set dstaddr "RHEL-Servers"                # RHEL 10/9
        set action accept
        set schedule "always"
        set service "SSH"                         # TCP 22
        set logtraffic all
        set comments "WALLIX sessions to Linux targets"
    next
end

RULE 8: WALLIX HA Replication (MariaDB)
========================================

config firewall policy
    edit 130
        set name "WALLIX-HA-MariaDB-Replication"
        set srcintf "dmz"
        set dstintf "dmz"
        set srcaddr "WALLIX-Nodes"
        set dstaddr "WALLIX-Nodes"
        set action accept
        set schedule "always"
        set service "MariaDB"                     # TCP 3306
        set logtraffic all
        set comments "WALLIX HA cluster database replication"
    next
end

RULE 9: WALLIX HA Cluster (Pacemaker/Corosync)
===============================================

config firewall policy
    edit 131
        set name "WALLIX-HA-Cluster-Communication"
        set srcintf "dmz"
        set dstintf "dmz"
        set srcaddr "WALLIX-Nodes"
        set dstaddr "WALLIX-Nodes"
        set action accept
        set schedule "always"
        set service "Corosync" "Pacemaker"        # UDP 5404-5406, TCP 2224
        set logtraffic all
        set comments "WALLIX HA cluster heartbeat and management"
    next
end

RULE 10: WALLIX → Infrastructure Services
==========================================

config firewall policy
    edit 140
        set name "WALLIX-to-Infrastructure"
        set srcintf "dmz"
        set dstintf "management"
        set srcaddr "WALLIX-Nodes"
        set dstaddr "Infrastructure-Services"     # DNS, NTP, SYSLOG
        set action accept
        set schedule "always"
        set service "DNS" "NTP" "Syslog-TLS"      # UDP/TCP 53, UDP 123, TCP 6514
        set logtraffic all
        set comments "WALLIX infrastructure dependencies"
    next
end

RULE 11: HAProxy → WALLIX Bastion Nodes
========================================

config firewall policy
    edit 150
        set name "HAProxy-to-WALLIX-Nodes"
        set srcintf "dmz"
        set dstintf "dmz"
        set srcaddr "HAProxy-Cluster"             # HAProxy HA pair
        set dstaddr "WALLIX-Nodes"
        set action accept
        set schedule "always"
        set service "HTTPS" "SSH" "RDP"
        set logtraffic all
        set comments "HAProxy load balancer to WALLIX backends"
    next
end

+===============================================================================+
```

### Address Object Definitions

```
config firewall address
    edit "WALLIX-Bastion-1"
        set subnet 10.10.1.11 255.255.255.255
    next
    edit "WALLIX-Bastion-2"
        set subnet 10.10.1.12 255.255.255.255
    next
    edit "HAProxy-1"
        set subnet 10.10.1.5 255.255.255.255
    next
    edit "HAProxy-2"
        set subnet 10.10.1.6 255.255.255.255
    next
    edit "WALLIX-HAProxy-VIP"
        set subnet 10.10.1.100 255.255.255.255
        set comment "HAProxy Keepalived VIP"
    next
    edit "FortiAuthenticator"
        set subnet 10.10.0.60 255.255.255.255
    next
    edit "AD-DC-1"
        set subnet 10.10.0.10 255.255.255.255
    next
    edit "AD-DC-2"
        set subnet 10.10.0.11 255.255.255.255
    next
end

config firewall addrgrp
    edit "WALLIX-Nodes"
        set member "WALLIX-Bastion-1" "WALLIX-Bastion-2"
    next
    edit "HAProxy-Cluster"
        set member "HAProxy-1" "HAProxy-2"
    next
    edit "AD-Domain-Controllers"
        set member "AD-DC-1" "AD-DC-2"
    next
    edit "Windows-Servers"
        set member "Win-Server-1" "Win-Server-2"
    next
    edit "RHEL-Servers"
        set member "RHEL10-Server-1" "RHEL9-Server-1"
    next
    edit "Infrastructure-Services"
        set member "DNS-Server" "NTP-Server" "Syslog-Server"
    next
end
```

### VPN Address Range

```
config firewall address
    edit "VPN-Users-Group"
        set type iprange
        set start-ip 10.100.0.1
        set end-ip 10.100.0.254
        set comment "SSL VPN user address pool"
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

## See Also

**Related Sections:**
- [06 - Authentication](../06-authentication/README.md) - MFA, LDAP, and authentication methods
- [36 - Network Validation](../36-network-validation/README.md) - Firewall rules and port requirements
- [32 - Load Balancer](../32-load-balancer/README.md) - HAProxy configuration for WALLIX
- [11 - High Availability](../11-high-availability/README.md) - HA cluster setup and failover
- [03 - Architecture](../03-architecture/README.md) - Multi-site architecture overview

**Related Documentation:**
- [Install Guide - Security Hardening](/install/07-security-hardening.md) - Fortigate security configuration
- [Pre-Production Lab - FortiAuthenticator Setup](/pre/04-fortiauthenticator-setup.md) - Lab environment setup

**Official Resources:**
- [Fortinet Documentation](https://docs.fortinet.com/)
- [WALLIX Documentation](https://pam.wallix.one/documentation)

---

<p align="center">
  <a href="../45-privileged-task-automation/README.md">← Previous: Privileged Task Automation</a>
</p>
