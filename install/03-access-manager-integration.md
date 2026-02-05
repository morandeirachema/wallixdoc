# Access Manager Integration with WALLIX Bastion

> Integration guide for connecting 5 WALLIX Bastion sites to 2 Access Managers in HA configuration

---

## Table of Contents

1. [Access Manager Overview](#access-manager-overview)
2. [Integration Architecture](#integration-architecture)
3. [SSO Integration (SAML/OIDC)](#sso-integration-samlodc)
4. [MFA via FortiAuthenticator](#mfa-via-fortiauthenticator)
5. [Session Brokering Configuration](#session-brokering-configuration)
6. [License Integration](#license-integration)
7. [Network Connectivity Verification](#network-connectivity-verification)
8. [End-to-End Testing](#end-to-end-testing)
9. [Troubleshooting](#troubleshooting)

---

## Access Manager Overview

### What is WALLIX Access Manager?

WALLIX Access Manager (AM) is a centralized gateway that provides:

| Function | Description |
|----------|-------------|
| **Single Sign-On (SSO)** | SAML/OIDC identity provider integration |
| **Multi-Factor Authentication** | FortiAuthenticator integration for MFA |
| **Session Brokering** | Routes user sessions to appropriate Bastion site |
| **License Management** | Centralized license pool management (optional) |
| **User Portal** | Web-based access to resources across all sites |
| **Load Balancing** | Distributes sessions across Bastion sites |
| **Health Monitoring** | Tracks Bastion availability and capacity |

### Deployment Model

```
+===============================================================================+
|  ACCESS MANAGER HA DEPLOYMENT                                                 |
+===============================================================================+
|                                                                               |
|   +-------------------------------+    +-------------------------------+      |
|   |  Access Manager 1 (Primary)   |    |  Access Manager 2 (Standby)   |      |
|   |  Location: DC-A               |    |  Location: DC-B               |      |
|   |                               |    |                               |      |
|   |  - SSO (SAML/OIDC IdP)        |    |  - SSO (SAML/OIDC IdP)        |      |
|   |  - Session Broker             | HA |  - Session Broker             |      |
|   |  - License Server             |<-->|  - License Server             |      |
|   |  - Health Monitor             |    |  - Health Monitor             |      |
|   |  - RADIUS Proxy               |    |  - RADIUS Proxy               |      |
|   |                               |    |                               |      |
|   +---------------+---------------+    +---------------+---------------+      |
|                   |                                    |                      |
|                   +------------------------------------+                      |
|                                MPLS Network                                   |
|                   +------------------------------------+                      |
|                   |                |         |         |                      |
|            +------+------+   +-----+----+ +--+------+  |                      |
|            |             |   |          | |         |  |                      |
|   +--------v--------+  +-v-----------+  +-v-------+ +--v---------+            |
|   | Bastion Site 1  |  | Bastion     |  | Bastion | | Bastion    |            |
|   | (DC-1)          |  | Site 2      |  | Site 3  | | Site 4     |            |
|   | 2x Appliances   |  | (DC-2)      |  | (DC-3)  | | (DC-4)     |            |
|   +-----------------+  +-------------+  +---------+ +------------+            |
|                                                                               |
|            Bastion Site 5 (DC-5)                                              |
|            +-------------------------+                                        |
|            | 2x Appliances           |                                        |
|            +-------------------------+                                        |
|                                                                               |
+===============================================================================+
```

### Component Responsibilities

| Component | Managed By | Role |
|-----------|------------|------|
| **Access Manager (2x)** | Separate Team | SSO, MFA, session routing, licensing |
| **WALLIX Bastion (10x)** | Your Team | PAM enforcement, session recording, credential vault |
| **FortiAuthenticator** | Security Team | MFA provider (RADIUS) |
| **MPLS Network** | Network Team | Connectivity between AM and Bastion sites |

> **Important**: Access Managers are managed by a separate team. This guide covers **Bastion-side configuration only**.

---

## Integration Architecture

### Data Flow Overview

```
+===============================================================================+
|  END-TO-END AUTHENTICATION AND SESSION FLOW                                   |
+===============================================================================+
|                                                                               |
|  1. User Login                                                                |
|  +----------+                                                                 |
|  |  User    |                                                                 |
|  | Browser  |                                                                 |
|  +----+-----+                                                                 |
|       |                                                                       |
|       | HTTPS (443)                                                           |
|       |                                                                       |
|  2. SSO Redirect                                                              |
|       v                                                                       |
|  +--------------------+                                                       |
|  | Access Manager     |                                                       |
|  | - SAML/OIDC IdP    |                                                       |
|  | - User Portal      |                                                       |
|  +----+---------------+                                                       |
|       |                                                                       |
|       | 3. MFA Challenge                                                      |
|       v                                                                       |
|  +--------------------+                                                       |
|  | FortiAuthenticator |                                                       |
|  | - RADIUS Auth      |                                                       |
|  | - FortiToken Push  |                                                       |
|  +----+---------------+                                                       |
|       |                                                                       |
|       | 4. MFA Success                                                        |
|       v                                                                       |
|  +--------------------+                                                       |
|  | Access Manager     |                                                       |
|  | Session Broker     |                                                       |
|  +----+---------------+                                                       |
|       |                                                                       |
|       | 5. Route to Bastion Site                                              |
|       | (Based on: user location, site health, load)                          |
|       |                                                                       |
|       v                                                                       |
|  +--------------------+         +--------------------+                        |
|  | Bastion Site 1     |   ...   | Bastion Site 5     |                        |
|  | - Validate token   |         | - Validate token   |                        |
|  | - Check authz      |         | - Check authz      |                        |
|  | - Start session    |         | - Start session    |                        |
|  +--------------------+         +--------------------+                        |
|                                                                               |
+===============================================================================+
```

### Integration Points

| Integration Point | Protocol | Port | Direction | Purpose |
|-------------------|----------|------|-----------|---------|
| **SSO (SAML)** | HTTPS | 443 | Bidirectional | User authentication |
| **SSO (OIDC)** | HTTPS | 443 | Bidirectional | Token exchange |
| **MFA (RADIUS)** | UDP | 1812 | Bastion → FortiAuth | Authentication |
| **RADIUS Accounting** | UDP | 1813 | Bastion → FortiAuth | Audit logging |
| **Session Broker API** | HTTPS | 443 | Bidirectional | Session routing |
| **Health Check** | HTTPS | 443 | AM → Bastion | Availability monitoring |
| **License Query** | HTTPS | 443 | Bastion → AM | License validation |

---

## SSO Integration (SAML/OIDC)

### Overview

Access Manager acts as the **Identity Provider (IdP)** and each Bastion site acts as a **Service Provider (SP)**.

**Supported Protocols:**
- SAML 2.0 (recommended for enterprise)
- OpenID Connect (OIDC) - New in WALLIX 12.x

### Option 1: SAML 2.0 Integration

#### Step 1: Export Bastion Service Provider Metadata

On **each Bastion cluster**, export the SAML SP metadata:

```bash
# SSH to primary Bastion node
ssh admin@bastion-site1-node1.company.com

# Export SP metadata
wabadmin saml-export-metadata --output /tmp/bastion-site1-sp-metadata.xml

# View metadata
cat /tmp/bastion-site1-sp-metadata.xml
```

**Sample SP Metadata:**

```xml
<?xml version="1.0"?>
<EntityDescriptor xmlns="urn:oasis:names:tc:SAML:2.0:metadata"
                  entityID="https://bastion-site1.company.com">
  <SPSSODescriptor protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
    <NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress</NameIDFormat>
    <AssertionConsumerService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
                              Location="https://bastion-site1.company.com/saml/acs"
                              index="0"/>
  </SPSSODescriptor>
</EntityDescriptor>
```

#### Step 2: Register Bastion with Access Manager

**Coordinate with Access Manager team** to register each Bastion site:

```
Access Manager Configuration (Performed by AM Team):
=====================================================

1. Login to Access Manager admin console
   URL: https://accessmanager.company.com/admin

2. Navigate to: Configuration > Identity Providers > Service Providers

3. Add new Service Provider:
   Name:            WALLIX-Bastion-Site1
   Entity ID:       https://bastion-site1.company.com
   Metadata:        [Upload bastion-site1-sp-metadata.xml]

   Attribute Mapping:
   - NameID:        email
   - User ID:       sAMAccountName
   - Email:         mail
   - Display Name:  displayName
   - Groups:        memberOf

4. Repeat for Sites 2-5
```

#### Step 3: Configure Bastion to Trust Access Manager IdP

Download IdP metadata from Access Manager team:

```bash
# Obtain IdP metadata from AM team
# File: access-manager-idp-metadata.xml

# Import on each Bastion cluster
wabadmin saml-import-idp \
  --metadata /tmp/access-manager-idp-metadata.xml \
  --name "AccessManager-IdP" \
  --default-domain "company.com"

# Enable SAML authentication
wabadmin auth-config --enable-saml --idp "AccessManager-IdP"
```

**Via WALLIX Web UI:**

```
1. Login to WALLIX Admin: https://bastion-site1.company.com/admin

2. Navigate to: Configuration > Authentication > SAML

3. Configure SAML Settings:

   Identity Provider Configuration:
   +-- IdP Name:           AccessManager-IdP
   +-- IdP Entity ID:      https://accessmanager.company.com
   +-- IdP SSO URL:        https://accessmanager.company.com/saml/sso
   +-- IdP SLO URL:        https://accessmanager.company.com/saml/logout
   +-- IdP Certificate:    [Upload AM IdP certificate]

   Service Provider Configuration:
   +-- SP Entity ID:       https://bastion-site1.company.com
   +-- ACS URL:            https://bastion-site1.company.com/saml/acs
   +-- SLO URL:            https://bastion-site1.company.com/saml/logout

   Attribute Mapping:
   +-- User ID:            NameID
   +-- Email:              email
   +-- Display Name:       displayName
   +-- Groups:             groups

   Options:
   [x] Enforce SSO
   [x] Auto-create users
   [x] Update user attributes on login
   [ ] Allow local fallback (for emergency accounts only)

4. Click "Test SAML" to verify configuration

5. Click "Save"
```

#### Step 4: Test SAML Authentication

```bash
# Test SAML login flow
curl -v https://bastion-site1.company.com/login

# Expected: HTTP 302 redirect to Access Manager
# Location: https://accessmanager.company.com/saml/sso?SAMLRequest=...

# After MFA, user should be redirected back with SAML assertion
```

**Manual Browser Test:**

```
1. Open browser in incognito mode
2. Navigate to: https://bastion-site1.company.com
3. Click "Login"
4. Expected flow:
   - Redirect to Access Manager login page
   - Enter AD credentials
   - Complete MFA challenge (FortiToken push)
   - Redirect back to Bastion with active session
```

---

### Option 2: OpenID Connect (OIDC) Integration

> **New in WALLIX 12.x**: OIDC support for modern OAuth2-based SSO

#### Step 1: Register Bastion as OIDC Client

**Coordinate with Access Manager team:**

```
Access Manager OIDC Configuration (Performed by AM Team):
==========================================================

1. Navigate to: Configuration > Identity Providers > OIDC Clients

2. Add new OIDC Client:
   Client Name:        WALLIX-Bastion-Site1
   Client ID:          wallix-bastion-site1
   Client Secret:      [Generate strong secret - save this!]

   Redirect URIs:
   - https://bastion-site1.company.com/oidc/callback

   Grant Types:
   [x] Authorization Code
   [x] Refresh Token

   Scopes:
   [x] openid
   [x] profile
   [x] email
   [x] groups

3. Save and provide Client ID/Secret to Bastion team
```

#### Step 2: Configure OIDC on Bastion

```bash
# Configure OIDC via wabadmin
wabadmin oidc-config \
  --provider "AccessManager" \
  --issuer "https://accessmanager.company.com" \
  --client-id "wallix-bastion-site1" \
  --client-secret "YOUR_CLIENT_SECRET" \
  --redirect-uri "https://bastion-site1.company.com/oidc/callback" \
  --scopes "openid,profile,email,groups"

# Enable OIDC authentication
wabadmin auth-config --enable-oidc --provider "AccessManager"
```

**Via WALLIX Web UI:**

```
1. Login to WALLIX Admin

2. Navigate to: Configuration > Authentication > OpenID Connect

3. Configure OIDC Settings:

   Provider Configuration:
   +-- Provider Name:      AccessManager
   +-- Issuer URL:         https://accessmanager.company.com
   +-- Discovery URL:      https://accessmanager.company.com/.well-known/openid-configuration

   Client Configuration:
   +-- Client ID:          wallix-bastion-site1
   +-- Client Secret:      [Paste secret from AM team]
   +-- Redirect URI:       https://bastion-site1.company.com/oidc/callback

   Scopes:
   [x] openid
   [x] profile
   [x] email
   [x] groups

   Claim Mapping:
   +-- User ID:            sub
   +-- Email:              email
   +-- Display Name:       name
   +-- Groups:             groups

   Options:
   [x] Auto-create users
   [x] Update user attributes on login
   [x] Request refresh tokens

4. Click "Test OIDC" to verify

5. Click "Save"
```

#### Step 3: Test OIDC Authentication

```bash
# Test OIDC discovery endpoint
curl https://accessmanager.company.com/.well-known/openid-configuration

# Expected response: JSON with endpoints
{
  "issuer": "https://accessmanager.company.com",
  "authorization_endpoint": "https://accessmanager.company.com/oauth2/authorize",
  "token_endpoint": "https://accessmanager.company.com/oauth2/token",
  "jwks_uri": "https://accessmanager.company.com/oauth2/keys",
  ...
}

# Test OIDC login flow
curl -v https://bastion-site1.company.com/login

# Expected: HTTP 302 redirect to Access Manager OIDC authorize endpoint
```

---

## MFA via FortiAuthenticator

### Overview

Access Manager integrates with FortiAuthenticator to provide centralized MFA for all Bastion sites.

**Flow:**
1. User authenticates to Access Manager (username/password)
2. Access Manager triggers RADIUS challenge to FortiAuthenticator
3. FortiAuthenticator sends push notification or OTP request
4. User completes MFA
5. Access Manager issues session token to Bastion

### Architecture

```
+===============================================================================+
|  MFA INTEGRATION ARCHITECTURE                                                 |
+===============================================================================+
|                                                                               |
|  User Login Flow:                                                             |
|                                                                               |
|  +----------+       1. Login        +------------------+                      |
|  |  User    |--------------------->|  Access Manager   |                      |
|  | Browser  |                      |  (IdP)            |                      |
|  +----------+                      +--------+---------+                       |
|                                             |                                 |
|                                             | 2. RADIUS Auth Request          |
|                                             |    (User: jsmith)               |
|                                             v                                 |
|                                    +--------------------+                     |
|                                    | FortiAuthenticator |                     |
|                                    | - RADIUS Server    |                     |
|                                    | - FortiToken Mgmt  |                     |
|                                    +--------+-----------+                     |
|                                             |                                 |
|                                             | 3. Push to User's Device        |
|                                             v                                 |
|                                    +--------------------+                     |
|                                    |  User Mobile       |                     |
|                                    |  FortiToken App    |                     |
|                                    +--------+-----------+                     |
|                                             |                                 |
|                                             | 4. User Approves                |
|                                             v                                 |
|                                    +--------------------+                     |
|                                    | FortiAuthenticator |                     |
|                                    +--------+-----------+                     |
|                                             |                                 |
|                                             | 5. RADIUS Access-Accept         |
|                                             v                                 |
|                                    +--------------------+                     |
|                                    |  Access Manager    |                     |
|                                    +--------+-----------+                     |
|                                             |                                 |
|                                             | 6. Issue Session Token          |
|                                             v                                 |
|                                    +--------------------+                     |
|                                    |  Bastion Site 1-5  |                     |
|                                    +--------------------+                     |
|                                                                               |
+===============================================================================+
```

### Step 1: Configure FortiAuthenticator (Coordinated with Security Team)

**FortiAuthenticator Configuration (Performed by Security Team):**

```
1. Login to FortiAuthenticator
   URL: https://fortiauth.company.com

2. Navigate to: Authentication > RADIUS Service > Clients

3. Add RADIUS Client for Access Managers:

   Client 1:
   Name:           AccessManager-1
   Client IP:      10.20.1.10 (AM1 IP)
   Secret:         [Strong shared secret]
   Description:    Access Manager Primary

   Client 2:
   Name:           AccessManager-2
   Client IP:      10.20.1.11 (AM2 IP)
   Secret:         [Same shared secret]
   Description:    Access Manager Standby

4. Configure RADIUS Policy:
   Name:           AccessManager-MFA-Policy

   Matching Rules:
   - RADIUS Client: AccessManager-1, AccessManager-2

   Authentication:
   - First Factor:  LDAP (Active Directory)
   - Second Factor: FortiToken (Push or OTP)

   Options:
   [x] Allow Push Notification
   [x] Allow OTP (6-digit code)
   [x] Allow SMS (optional backup)

   Timeout: 60 seconds
   Max Retries: 3

5. Sync Users from AD:
   Navigate to: Authentication > User Management > Remote Users

   Configure:
   Server:         dc01.company.com
   Port:           636 (LDAPS)
   Base DN:        OU=Users,DC=company,DC=com
   Sync Schedule:  Every 15 minutes

6. Assign FortiTokens to Users:
   - FortiToken Mobile: Provision via email
   - Hardware Tokens: Import and assign
```

### Step 2: Configure Access Manager to Use RADIUS

**Access Manager Configuration (Performed by AM Team):**

```
1. Login to Access Manager admin console

2. Navigate to: Configuration > Authentication > RADIUS

3. Add RADIUS Server:
   Name:              FortiAuthenticator
   Server Address:    fortiauth.company.com
   Port:              1812
   Shared Secret:     [Secret from FortiAuth config]
   Timeout:           10 seconds
   Retries:           3

   Accounting:
   [x] Enable RADIUS Accounting
   Accounting Port:   1813

4. Configure Authentication Chain:
   Navigate to: Configuration > Authentication > Policies

   Policy Name:       MFA-Required-Policy

   Authentication Steps:
   1. LDAP/AD (primary)
   2. RADIUS (FortiAuth) - Challenge/Response

   Apply to:
   [x] All users
   [ ] Specific groups only

5. Test RADIUS connectivity:
   Tools > RADIUS Test

   Username:    jsmith
   Password:    [User's AD password]

   Expected:    Push notification sent to user's mobile device
```

### Step 3: Configure Bastion to Accept AM Sessions

Bastions validate sessions issued by Access Manager after MFA completion.

```bash
# Configure Bastion to trust Access Manager sessions
wabadmin session-broker \
  --enable \
  --broker-url "https://accessmanager.company.com/api/v1" \
  --api-key "YOUR_AM_API_KEY" \
  --verify-ssl

# Configure session validation
wabadmin auth-config \
  --trust-broker-sessions \
  --session-timeout 28800 \
  --reauth-interval 14400
```

**Via WALLIX Web UI:**

```
1. Navigate to: Configuration > Authentication > Session Broker

2. Configure:

   Broker Settings:
   +-- Enable Session Broker:     [x]
   +-- Broker URL:                https://accessmanager.company.com/api/v1
   +-- API Key:                   [Paste API key from AM team]
   +-- Health Check Interval:     60 seconds

   Session Validation:
   +-- Trust Broker Sessions:     [x]
   +-- Session Timeout:           8 hours (28800 sec)
   +-- Reauth Interval:           4 hours (14400 sec)
   +-- Validate MFA:              [x]

   Certificate Validation:
   [x] Verify SSL certificate
   [x] Check certificate revocation

3. Click "Test Connection"

4. Click "Save"
```

### Step 4: Test MFA Flow End-to-End

```bash
# Test 1: Verify RADIUS connectivity from Access Manager
# (Run by AM team)
ssh admin@accessmanager-1.company.com
radius-test --server fortiauth.company.com --user jsmith --password "test123"

# Expected: Push notification sent, Access-Accept received

# Test 2: Verify Bastion can validate AM sessions
ssh admin@bastion-site1-node1.company.com
wabadmin session-broker test --user jsmith

# Expected: Session validated successfully

# Test 3: End-to-end user login
# 1. User navigates to: https://bastion-site1.company.com
# 2. Redirects to Access Manager
# 3. Enter AD credentials
# 4. Receive FortiToken push notification
# 5. Approve on mobile device
# 6. Redirected to Bastion with active session
```

---

## Session Brokering Configuration

### Overview

Session brokering allows Access Manager to intelligently route users to the appropriate Bastion site based on:
- User location/affinity
- Site health and availability
- Current load (concurrent sessions)
- Resource availability (target systems)

### Architecture

```
+===============================================================================+
|  SESSION BROKERING ARCHITECTURE                                               |
+===============================================================================+
|                                                                               |
|  User Request:                                                                |
|  "Connect to server prod-db-01.company.com"                                   |
|                                                                               |
|  +-----------+                                                                |
|  |   User    |                                                                |
|  +-----------+                                                                |
|       |                                                                       |
|       | 1. Request target access                                              |
|       v                                                                       |
|  +--------------------+                                                       |
|  | Access Manager     |                                                       |
|  | Session Broker     |                                                       |
|  +---------+----------+                                                       |
|            |                                                                  |
|            | 2. Query site health and load                                    |
|            |                                                                  |
|     +------+------+------+------+------+                                      |
|     |             |      |      |      |                                      |
|     v             v      v      v      v                                      |
|  +------+  +------+  +------+  +------+  +------+                             |
|  |Site 1|  |Site 2|  |Site 3|  |Site 4|  |Site 5|                             |
|  | OK   |  | OK   |  |WARN  |  | OK   |  |ERROR |                             |
|  |Load:2|  |Load:5|  |Load:8|  |Load:3|  |Down  |                             |
|  +------+  +------+  +------+  +------+  +------+                             |
|     ^                                                                         |
|     |                                                                         |
|     | 3. Route to optimal site (Site 1 - lowest load, healthy)                |
|     |                                                                         |
|  +--------------------+                                                       |
|  | Bastion Site 1     |                                                       |
|  | Session started    |                                                       |
|  +--------------------+                                                       |
|                                                                               |
+===============================================================================+
```

### Step 1: Register Bastion Sites with Access Manager

**Access Manager Configuration (Performed by AM Team):**

```
1. Login to Access Manager admin console

2. Navigate to: Configuration > Session Broker > Bastion Sites

3. Add Bastion Site 1:
   Site Name:          WALLIX-Site1-DC-1
   Site ID:            site1
   Location:           Site 1 DC, Building A

   Endpoint Configuration:
   +-- Primary URL:    https://bastion-site1.company.com
   +-- API Endpoint:   https://bastion-site1.company.com/api/v1
   +-- API Key:        [Generated API key for AM access]
   +-- Health Check:   https://bastion-site1.company.com/health

   Load Balancing:
   +-- VIP (HAProxy):  10.10.1.10
   +-- Node 1:         10.10.1.11
   +-- Node 2:         10.10.1.12
   +-- Priority:       10 (higher = preferred)
   +-- Max Sessions:   100

   Health Monitoring:
   +-- Check Interval: 30 seconds
   +-- Timeout:        10 seconds
   +-- Failure Threshold: 3 consecutive failures

   Routing Rules:
   [x] Accept all users
   [ ] Restrict to specific groups
   [x] Allow failover to other sites

4. Repeat for Sites 2-5 with respective endpoints

5. Configure Routing Policy:
   Navigate to: Configuration > Session Broker > Policies

   Policy Name:       Default-Routing

   Routing Strategy:
   ( ) Round Robin
   ( ) Least Connections
   (x) Weighted (by priority and load)

   Affinity:
   [x] Prefer user's last site (session persistence)
   [x] Respect site priority
   [x] Exclude unhealthy sites

   Failover:
   [x] Auto-failover on site failure
   [x] Notify user of site switch
   Retry Delay: 5 seconds
```

### Step 2: Configure Bastion to Accept Broker Requests

On **each Bastion cluster**:

```bash
# Generate API key for Access Manager
wabadmin api-key create \
  --name "AccessManager-SessionBroker" \
  --permissions "session.create,session.query,health.read" \
  --validity 365

# Output: API Key: AM_abc123def456...

# Enable session brokering
wabadmin session-broker enable \
  --broker-url "https://accessmanager.company.com/api/v1" \
  --site-id "site1" \
  --api-key "YOUR_BASTION_API_KEY" \
  --health-check-port 443

# Configure health check endpoint
wabadmin health-check configure \
  --enable \
  --path "/health" \
  --checks "database,cluster,sessions,disk"

# Test health check
curl https://bastion-site1.company.com/health
```

**Expected Health Check Response:**

```json
{
  "status": "healthy",
  "site_id": "site1",
  "timestamp": "2026-02-05T10:30:00Z",
  "checks": {
    "database": {
      "status": "ok",
      "latency_ms": 5
    },
    "cluster": {
      "status": "ok",
      "nodes": 2,
      "nodes_online": 2
    },
    "sessions": {
      "status": "ok",
      "current": 15,
      "max": 100,
      "utilization_percent": 15
    },
    "disk": {
      "status": "ok",
      "used_percent": 45
    }
  }
}
```

**Via WALLIX Web UI:**

```
1. Navigate to: Configuration > Session Broker > Settings

2. Configure:

   Broker Registration:
   +-- Enable Session Broker:     [x]
   +-- Broker URL:                https://accessmanager.company.com/api/v1
   +-- Site ID:                   site1
   +-- Site Name:                 WALLIX-Site1-DC-1

   API Configuration:
   +-- Bastion API Key:           [Key for AM to call Bastion]
   +-- Broker API Key:            [Key for Bastion to call AM]
   +-- Health Check Interval:     30 seconds

   Capacity Limits:
   +-- Max Concurrent Sessions:   100
   +-- Warning Threshold:         80%
   +-- Critical Threshold:        95%

   Health Check:
   +-- Enabled:                   [x]
   +-- Endpoint:                  /health
   +-- Include Metrics:           [x]

3. Click "Register with Broker"

4. Verify registration status shows "Active"
```

### Step 3: Configure Session Callbacks

Access Manager needs to notify Bastions about session state changes:

```bash
# Configure callback endpoint on Bastion
wabadmin session-broker callbacks \
  --endpoint "https://bastion-site1.company.com/api/v1/callbacks" \
  --events "session.created,session.terminated,session.transferred" \
  --secret "YOUR_CALLBACK_SECRET"

# Test callback reception
wabadmin session-broker test-callback
```

### Step 4: Test Session Brokering

```bash
# Test 1: Health check visibility
ssh admin@accessmanager-1.company.com
session-broker sites --status

# Expected output:
# Site ID  Status    Load  Priority  Last Check
# site1    Healthy   15%   10        2026-02-05 10:30:01
# site2    Healthy   25%   10        2026-02-05 10:30:02
# site3    Warning   85%   10        2026-02-05 10:30:03
# site4    Healthy   30%   10        2026-02-05 10:30:04
# site5    Down      -     10        2026-02-05 10:28:45

# Test 2: Simulate session routing
session-broker route-test --user jsmith --target prod-db-01.company.com

# Expected: Routes to site1 (lowest load, healthy)

# Test 3: Manual failover test
# 1. Stop Bastion Site 1
systemctl stop wallix-bastion  # On site1-node1 and site1-node2

# 2. Wait for health check failure (3x30s = 90s)

# 3. Attempt login via Access Manager
# Expected: Auto-routes to Site 2 (next available)

# 4. Restart Site 1
systemctl start wallix-bastion

# 5. New sessions should route back to Site 1
```

---

## License Integration

### Overview

WALLIX supports two license pooling models:

| Model | Description | Use Case |
|-------|-------------|----------|
| **Separate Pools** | AM and Bastion each have their own license pools | Default, simpler management |
| **Shared Pool** | AM and Bastion share a unified license pool | Enterprise, maximize utilization |

### Architecture Options

#### Option 1: Separate License Pools (Default)

```
+===============================================================================+
|  SEPARATE LICENSE POOLS                                                       |
+===============================================================================+
|                                                                               |
|  +--------------------------+          +--------------------------+           |
|  | Access Manager License   |          | Bastion License Pool     |           |
|  | Pool: 500 sessions       |          | 450 sessions (shared)    |           |
|  |                          |          |                          |           |
|  | - AM1: 250 sessions      |          | Site 1: 90 sessions      |           |
|  | - AM2: 250 sessions (HA) |          | Site 2: 90 sessions      |           |
|  +--------------------------+          | Site 3: 90 sessions      |           |
|                                        | Site 4: 90 sessions      |           |
|                                        | Site 5: 90 sessions      |           |
|                                        +--------------------------+           |
|                                                                               |
|  Total Capacity: 950 concurrent sessions                                      |
|                                                                               |
+===============================================================================+
```

**Configuration:**
- No integration required
- Each component manages its own licenses
- Access Manager licenses user portal sessions
- Bastion licenses PAM sessions

#### Option 2: Unified License Pool (Advanced)

```
+===============================================================================+
|  UNIFIED LICENSE POOL                                                         |
+===============================================================================+
|                                                                               |
|  +----------------------------------------------------------------------+     |
|  |  Unified License Server                                              |     |
|  |  Total Pool: 1000 sessions                                           |     |
|  |                                                                      |     |
|  |  Dynamic Allocation:                                                 |     |
|  |  +------------------+    +--------------------------------------+    |     |
|  |  | Access Manager   |    | Bastion Sites 1-5                    |    |     |
|  |  | 200 sessions     |    | 800 sessions (dynamically shared)    |    |     |
|  |  | (reserved)       |    |                                      |    |     |
|  |  +------------------+    +--------------------------------------+    |     |
|  |                                                                      |     |
|  +----------------------------------------------------------------------+     |
|                                                                               |
|  Advantages:                                                                  |
|  - Maximize license utilization                                               |
|  - Automatic rebalancing                                                      |
|  - Reduced total license cost                                                 |
|                                                                               |
+===============================================================================+
```

### Step 1: Configure License Server (Unified Pool Only)

**Access Manager Configuration (Performed by AM Team):**

```
1. Login to Access Manager admin console

2. Navigate to: Configuration > Licensing > License Server

3. Configure License Pool:
   License Server Mode:   Centralized
   Server URL:            https://license.company.com:8443
   API Key:               [License server API key]

   Pool Configuration:
   Total Licenses:        1000
   Reserved for AM:       200
   Available for Bastion: 800

   Allocation Policy:
   ( ) Static - Fixed per site
   (x) Dynamic - On-demand

   Monitoring:
   [x] Alert at 80% utilization
   [x] Alert at 95% utilization
   [x] Enforce hard limit

4. Click "Save and Activate"
```

### Step 2: Configure Bastion to Query License Server (Unified Pool Only)

```bash
# Configure license client on each Bastion
wabadmin license-config \
  --mode "centralized" \
  --server "https://license.company.com:8443" \
  --api-key "YOUR_LICENSE_API_KEY" \
  --site-id "site1" \
  --query-interval 300

# Verify license pool connectivity
wabadmin license-status

# Expected output:
# License Mode:     Centralized
# Server:           https://license.company.com:8443
# Pool Capacity:    800 (Bastion pool)
# Used:             150
# Available:        650
# Site Allocation:  90 (soft limit)
# Status:           OK
```

**Via WALLIX Web UI:**

```
1. Navigate to: Configuration > Licensing

2. Select: Centralized License Pool

3. Configure:

   License Server:
   +-- Server URL:        https://license.company.com:8443
   +-- API Key:           [Key from AM team]
   +-- Site ID:           site1
   +-- Query Interval:    5 minutes

   Local Caching:
   [x] Cache license status locally
   Cache Duration:        30 minutes
   Offline Grace Period:  4 hours

   Limits:
   +-- Soft Limit:        90 sessions
   +-- Hard Limit:        110 sessions (burst)

   Alerts:
   [x] Alert at 80 sessions (90%)
   [x] Alert at 100 sessions (110%)

4. Click "Test Connection"

5. Click "Save"
```

### Step 3: Monitor License Usage

```bash
# View current license usage
wabadmin license-status --detailed

# View per-site breakdown
wabadmin license-status --by-site

# Expected output:
# Site    Used  Soft Limit  Hard Limit  Status
# site1   15    90          110         OK
# site2   25    90          110         OK
# site3   85    90          110         WARNING
# site4   30    90          110         OK
# site5   0     90          110         DOWN
# Total:  155   450         550         OK

# Query license history
wabadmin license-history --last 7d --format json
```

---

## Network Connectivity Verification

### Prerequisites

Before integration, verify network connectivity between components:

### Step 1: Verify MPLS Connectivity

```bash
# From each Bastion node, test MPLS connectivity to Access Managers

# Test 1: Ping Access Managers
ping -c 5 accessmanager-1.company.com
ping -c 5 accessmanager-2.company.com

# Expected: < 50ms latency, 0% packet loss

# Test 2: Traceroute to verify MPLS path
traceroute accessmanager-1.company.com

# Expected: Clean path through MPLS network, no public internet hops

# Test 3: MTU path discovery
ping -M do -s 1472 accessmanager-1.company.com

# Expected: Successful, no fragmentation needed
```

### Step 2: Verify Port Connectivity

```bash
# Test HTTPS (443) connectivity
curl -v https://accessmanager.company.com/health

# Expected: HTTP 200 OK

# Test RADIUS (1812/1813) connectivity to FortiAuthenticator
nc -zvu fortiauth.company.com 1812
nc -zvu fortiauth.company.com 1813

# Expected: Connection to fortiauth.company.com 1812 port [udp/*] succeeded!

# Test API endpoint
curl -H "Authorization: Bearer YOUR_API_KEY" \
  https://accessmanager.company.com/api/v1/health

# Expected: {"status": "healthy", ...}
```

### Step 3: DNS Resolution

```bash
# Verify DNS resolution for all components
nslookup accessmanager.company.com
nslookup accessmanager-1.company.com
nslookup accessmanager-2.company.com
nslookup fortiauth.company.com
nslookup bastion-site1.company.com

# Expected: Correct IP addresses returned

# Verify reverse DNS
nslookup 10.20.1.10  # AM1 IP
nslookup 10.20.1.11  # AM2 IP

# Expected: Correct hostnames returned
```

### Step 4: Certificate Validation

```bash
# Verify SSL certificates for all HTTPS endpoints
openssl s_client -connect accessmanager.company.com:443 -servername accessmanager.company.com

# Check:
# - Certificate is valid (not expired)
# - Certificate matches hostname
# - Certificate chain is complete
# - Issuer is trusted CA

# Test certificate from Bastion
curl --cacert /etc/ssl/certs/ca-certificates.crt \
  https://accessmanager.company.com/health

# Expected: No SSL errors
```

### Step 5: NTP Synchronization

```bash
# Verify time synchronization (critical for SAML/OIDC)
timedatectl status

# Expected: "System clock synchronized: yes"

# Check time difference with Access Manager
ssh admin@accessmanager-1.company.com "date +%s"
date +%s

# Expected: Difference < 5 seconds

# Verify NTP servers
chronyc sources

# Expected: At least 1 NTP server with '*' (selected)
```

### Step 6: Firewall Rules Verification

```bash
# Test firewall rules (should be pre-configured)

# From Bastion to Access Manager:
# - TCP 443 (HTTPS) ✓
curl -v https://accessmanager.company.com:443

# From Bastion to FortiAuthenticator:
# - UDP 1812 (RADIUS Auth) ✓
# - UDP 1813 (RADIUS Accounting) ✓
nc -zvu fortiauth.company.com 1812
nc -zvu fortiauth.company.com 1813

# From Access Manager to Bastion:
# - TCP 443 (HTTPS callbacks) ✓
# (Test from AM side)
ssh admin@accessmanager-1.company.com
curl -v https://bastion-site1.company.com:443/health
```

**Port Reference:**

| Source | Destination | Port | Protocol | Status Required |
|--------|-------------|------|----------|-----------------|
| Bastion | Access Manager | 443 | TCP | OPEN |
| Bastion | FortiAuthenticator | 1812 | UDP | OPEN |
| Bastion | FortiAuthenticator | 1813 | UDP | OPEN |
| Access Manager | Bastion | 443 | TCP | OPEN |
| Access Manager | FortiAuthenticator | 1812 | UDP | OPEN |
| Access Manager | FortiAuthenticator | 1813 | UDP | OPEN |
| Users | Access Manager | 443 | TCP | OPEN |
| Users | Bastion (direct) | 443 | TCP | OPEN (optional) |

---

## End-to-End Testing

### Test Suite

Run these tests to verify complete integration:

#### Test 1: SSO Authentication (SAML/OIDC)

```bash
# Automated test
wabadmin test sso \
  --user "jsmith" \
  --idp "AccessManager-IdP" \
  --verbose

# Expected output:
# [OK] SSO redirect to Access Manager
# [OK] SAML/OIDC assertion received
# [OK] User authenticated: jsmith
# [OK] Session created: sess_abc123
```

**Manual Test:**
1. Open browser: https://bastion-site1.company.com
2. Verify redirect to Access Manager
3. Login with AD credentials
4. Verify redirect back to Bastion with active session

#### Test 2: MFA Challenge

```bash
# Test FortiToken push notification
wabadmin test mfa \
  --user "jsmith" \
  --method "fortitoken-push" \
  --timeout 60

# Expected output:
# [OK] RADIUS challenge sent to FortiAuthenticator
# [OK] Push notification delivered to user's device
# [WAIT] Waiting for user approval...
# [OK] MFA approved by user
# [OK] RADIUS Access-Accept received
```

**Manual Test:**
1. Login via Access Manager
2. Enter AD credentials
3. Verify FortiToken push notification on mobile device
4. Approve notification
5. Verify successful login to Bastion

#### Test 3: Session Brokering

```bash
# Test session routing decision
wabadmin test session-broker \
  --user "jsmith" \
  --target "prod-db-01.company.com" \
  --verbose

# Expected output:
# [OK] Query Access Manager for routing decision
# [OK] Site health check:
#      Site1: Healthy (15% load) - SELECTED
#      Site2: Healthy (25% load)
#      Site3: Warning (85% load)
#      Site4: Healthy (30% load)
#      Site5: Down
# [OK] Routed to: site1 (bastion-site1.company.com)
# [OK] Session created on Site1
```

#### Test 4: License Validation (Unified Pool Only)

```bash
# Test license query
wabadmin test license \
  --verbose

# Expected output:
# [OK] Connected to license server
# [OK] Pool status:
#      Total: 1000
#      AM Reserved: 200
#      Bastion Pool: 800
#      Used: 150
#      Available: 650
# [OK] Site1 allocation: 15/90 (soft limit)
# [OK] License check: PASS
```

#### Test 5: Failover Test

```bash
# Simulate Access Manager failover
# 1. Stop primary AM
ssh admin@accessmanager-1.company.com
sudo systemctl stop wallix-access-manager

# 2. Wait for failover (typically 10-30 seconds)

# 3. Test user login
# Should automatically fail over to AM2

# 4. Verify in Bastion logs
tail -f /var/log/wallix/auth.log | grep "Access Manager"

# Expected:
# [WARN] Access Manager 1 unreachable, failing over to AM2
# [OK] Connected to Access Manager 2
# [OK] User authenticated via AM2

# 5. Restore AM1
ssh admin@accessmanager-1.company.com
sudo systemctl start wallix-access-manager
```

#### Test 6: End-to-End User Session

**Complete user workflow:**

```
1. User accesses Bastion portal:
   https://bastion-site1.company.com

2. Redirect to Access Manager SSO:
   https://accessmanager.company.com/saml/sso

3. User enters AD credentials:
   Username: jsmith
   Password: ********

4. MFA challenge (FortiToken push):
   Push notification sent to mobile device

5. User approves on FortiToken app:
   [Approve] button clicked

6. Redirect back to Bastion:
   https://bastion-site1.company.com/dashboard

7. User selects target system:
   Target: prod-db-01.company.com (SSH)

8. Session established:
   Session ID: sess_20260205_103045_jsmith
   Recording: Started
   Audit: Logged

9. User works on target system:
   Commands executed, session recorded

10. User disconnects:
    Session terminated gracefully
    Recording saved, audit logged
```

**Validation Points:**
- [ ] SSO redirect successful
- [ ] MFA challenge received and completed
- [ ] Session created on correct Bastion site
- [ ] Target system connection established
- [ ] Session recorded and audited
- [ ] Graceful disconnect logged

---

## Troubleshooting

### Common Integration Issues

#### Issue 1: SSO Redirect Fails

**Symptoms:**
- User is not redirected to Access Manager
- Error: "SSO not configured"

**Resolution:**

```bash
# Check SAML/OIDC configuration
wabadmin auth-config --show

# Verify IdP metadata
wabadmin saml-show-idp

# Test SAML endpoint
curl -v https://accessmanager.company.com/saml/sso

# Check Bastion logs
tail -f /var/log/wallix/auth.log | grep -i saml

# Verify certificate trust
openssl s_client -connect accessmanager.company.com:443 -showcerts
```

#### Issue 2: MFA Challenge Not Received

**Symptoms:**
- User completes primary auth but doesn't receive MFA challenge
- Error: "RADIUS timeout"

**Resolution:**

```bash
# Test RADIUS connectivity
nc -zvu fortiauth.company.com 1812

# Check RADIUS configuration
wabadmin radius-config --show

# Test RADIUS manually
radtest jsmith password123 fortiauth.company.com 0 sharedsecret

# Check FortiAuthenticator logs
ssh admin@fortiauth.company.com
tail -f /var/log/radius/radius.log

# Verify user has FortiToken assigned
# (Check in FortiAuthenticator UI)
```

#### Issue 3: Session Brokering Not Working

**Symptoms:**
- Sessions not routed to appropriate site
- Error: "Site unavailable"

**Resolution:**

```bash
# Check broker registration
wabadmin session-broker status

# Test health check endpoint
curl https://bastion-site1.company.com/health

# Verify API connectivity
curl -H "Authorization: Bearer YOUR_API_KEY" \
  https://accessmanager.company.com/api/v1/sites

# Check broker logs on AM side
ssh admin@accessmanager-1.company.com
tail -f /var/log/wallix/session-broker.log

# Re-register with broker
wabadmin session-broker register --force
```

#### Issue 4: License Validation Fails

**Symptoms:**
- Sessions rejected due to license limit
- Error: "No licenses available"

**Resolution:**

```bash
# Check license status
wabadmin license-status --detailed

# Verify license server connectivity
curl -v https://license.company.com:8443/status

# Check license allocation
wabadmin license-history --last 1h

# Force license refresh
wabadmin license-refresh --force

# Contact AM team to verify pool allocation
```

#### Issue 5: Certificate Validation Errors

**Symptoms:**
- SSL handshake failures
- Error: "Certificate verification failed"

**Resolution:**

```bash
# Verify certificate chain
openssl s_client -connect accessmanager.company.com:443 -showcerts

# Check certificate expiry
echo | openssl s_client -connect accessmanager.company.com:443 2>/dev/null | \
  openssl x509 -noout -dates

# Update CA trust store
sudo update-ca-certificates

# Add custom CA certificate
sudo cp access-manager-ca.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates

# Test after CA update
curl https://accessmanager.company.com/health
```

### Diagnostic Commands

```bash
# Comprehensive diagnostic report
wabadmin diagnostic --include-integration > /tmp/integration-diag.txt

# Check all integration points
wabadmin integration-check --verbose

# Export configuration for review
wabadmin config-export --section auth,session-broker,license \
  > /tmp/integration-config.json

# Network connectivity tests
wabadmin network-test --target accessmanager.company.com --all-ports

# View integration logs
tail -f /var/log/wallix/integration.log

# Enable debug logging for troubleshooting
wabadmin log-level --set debug --component auth,session-broker

# Disable debug logging after troubleshooting
wabadmin log-level --set info --component auth,session-broker
```

---

## Integration Checklist

### Pre-Integration

- [ ] Access Manager HA deployed and tested by separate team
- [ ] FortiAuthenticator RADIUS configuration completed
- [ ] MPLS connectivity established between AM and all Bastion sites
- [ ] DNS records created for all components
- [ ] SSL certificates obtained and installed
- [ ] Firewall rules configured and tested
- [ ] NTP synchronization verified across all sites

### SSO Integration

- [ ] SAML/OIDC provider configured on Access Manager
- [ ] Service Provider metadata exported from each Bastion site
- [ ] Bastion sites registered with Access Manager IdP
- [ ] IdP metadata imported to each Bastion
- [ ] Attribute mapping configured (user ID, email, groups)
- [ ] SSO login tested successfully for test users

### MFA Integration

- [ ] FortiAuthenticator RADIUS clients configured for Access Managers
- [ ] RADIUS authentication policy created for MFA
- [ ] Users synced from AD to FortiAuthenticator
- [ ] FortiTokens provisioned to test users
- [ ] Access Manager configured to use RADIUS for MFA
- [ ] Bastion configured to accept AM sessions post-MFA
- [ ] End-to-end MFA flow tested successfully

### Session Brokering

- [ ] Bastion sites registered with Access Manager session broker
- [ ] Health check endpoints configured on each Bastion
- [ ] API keys generated and exchanged (AM ↔ Bastion)
- [ ] Session callbacks configured
- [ ] Routing policy defined in Access Manager
- [ ] Load balancing tested across multiple sites
- [ ] Failover tested (site down scenario)

### License Integration (if using unified pool)

- [ ] License server configured in Access Manager
- [ ] License pool allocated (AM + Bastion)
- [ ] Each Bastion configured to query license server
- [ ] License usage monitoring configured
- [ ] Alerting configured for license thresholds
- [ ] License failover tested (offline scenario)

### Testing & Validation

- [ ] SSO authentication tested from external network
- [ ] MFA challenge tested with FortiToken push
- [ ] Session routing tested to all 5 sites
- [ ] Failover tested (AM1 → AM2)
- [ ] License limits tested (near capacity)
- [ ] Performance tested (concurrent logins)
- [ ] Audit logs verified in SIEM integration

### Documentation & Handoff

- [ ] Integration architecture diagram updated
- [ ] API keys and secrets documented (secure vault)
- [ ] Troubleshooting runbook created
- [ ] Handoff to operations team completed
- [ ] Monitoring dashboards configured
- [ ] Alerting rules configured for integration health

---

## Next Steps

After completing Access Manager integration:

1. **Deploy First Bastion Site**: Proceed to [04-site-deployment.md](04-site-deployment.md)
2. **Configure HAProxy**: See [05-haproxy-setup.md](05-haproxy-setup.md)
3. **Setup Bastion HA**: Choose [06-bastion-active-active.md](06-bastion-active-active.md) or [07-bastion-active-passive.md](07-bastion-active-passive.md)
4. **Replicate to Sites 2-5**: Repeat deployment process for remaining sites
5. **Final Testing**: See [10-testing-validation.md](10-testing-validation.md)

---

## Support Resources

### Internal Documentation
- [Authentication Overview](../docs/pam/06-authentication/README.md)
- [FortiAuthenticator Integration](../docs/pam/06-authentication/fortiauthenticator-integration.md)
- [API Reference](../docs/pam/17-api-reference/README.md)
- [Troubleshooting Guide](../docs/pam/13-troubleshooting/README.md)

### External Resources
- WALLIX Access Manager Documentation: https://pam.wallix.one/documentation/access-manager/
- WALLIX Bastion SSO Guide: https://pam.wallix.one/documentation/admin-doc/sso-configuration.pdf
- FortiAuthenticator RADIUS Guide: https://docs.fortinet.com/product/fortiauthenticator/6.4

### Contact Points
- **Access Manager Team**: am-team@company.com
- **Security Team (FortiAuth)**: security-ops@company.com
- **Network Team (MPLS)**: network-ops@company.com
- **WALLIX Support**: support@wallix.com

---

*Integration document version 1.0 - Last updated: 2026-02-05*
