# Access Manager Integration - Bastion-Side Configuration

> Bastion-side configuration for integrating with the client-managed WALLIX Access Manager HA pair

---

## Document Information

| Property | Value |
|----------|-------|
| **Purpose** | Register Bastion sites with Access Manager and configure Bastion-side integration |
| **Scope** | Bastion-side configuration ONLY — AM is managed by the client |
| **Prerequisites** | [05-site-deployment.md](05-site-deployment.md), all sites deployed and tested |
| **Version** | WALLIX Bastion 12.1.x |
| **Last Updated** | April 2026 |

---

> **IMPORTANT**: The WALLIX Access Manager (2x HA Active-Passive) is installed, configured, and managed by the **client's team**. This document covers only what needs to be configured on the **WALLIX Bastion side** to integrate with the client's Access Manager. Do not attempt to install or configure the Access Manager itself.

---

## Table of Contents

1. [Overview](#overview)
2. [What the Client Configures (AM Side)](#what-the-client-configures-am-side)
3. [What We Configure (Bastion Side)](#what-we-configure-bastion-side)
4. [Information Required from Client AM Team](#information-required-from-client-am-team)
5. [Registering Bastion Sites in Access Manager](#registering-bastion-sites-in-access-manager)
6. [SSO/SAML Configuration on Bastion Side](#ssosaml-configuration-on-bastion-side)
7. [Session Brokering Endpoint Configuration](#session-brokering-endpoint-configuration)
8. [Connectivity Verification](#connectivity-verification)
9. [Handoff Checklist](#handoff-checklist)

---

## Overview

### Architecture

```
+===============================================================================+
|  ACCESS MANAGER INTEGRATION - RESPONSIBILITY SPLIT                            |
+===============================================================================+
|                                                                               |
|  CLIENT-MANAGED (NOT our scope):                                              |
|  +-----------------------------------+  +-----------------------------------+  |
|  |  Access Manager 1 (DC-A)          |  |  Access Manager 2 (DC-B)          |  |
|  |  - SSO identity provider          |  |  - SSO identity provider          |  |
|  |  - Session brokering logic        |  |  - Session brokering logic        |  |
|  |  - User portal                    |  |  - User portal                    |  |
|  |  - License server                 |  |  - License server                 |  |
|  |  - AM HA replication              |  |  - AM HA replication              |  |
|  +-------------------+---------------+  +---------------+-------------------+  |
|                      |                                  |                      |
|                      +----------------------------------+                      |
|                              MPLS Network                                      |
|                      +----------------------------------+                      |
|                      |                |         |       |                      |
|                                                                               |
|  OUR SCOPE (Bastion side only):                                               |
|  +----------------+  +----------------+   ...   +----------------+             |
|  | Bastion Site 1 |  | Bastion Site 2 |         | Bastion Site 5 |             |
|  | - AM API key   |  | - AM API key   |         | - AM API key   |             |
|  | - SSO consumer |  | - SSO consumer |         | - SSO consumer |             |
|  | - Health check |  | - Health check |         | - Health check |             |
|  | endpoint       |  | endpoint       |         | endpoint       |             |
|  +----------------+  +----------------+         +----------------+             |
|                                                                               |
+===============================================================================+
```

### Scope Boundary

| Task | Responsible Party | Document |
|------|-------------------|----------|
| Install and configure AM | Client team | Client's own documentation |
| AM HA configuration | Client team | Client's own documentation |
| AM SSO identity provider setup | Client team | Client's own documentation |
| AM user portal configuration | Client team | Client's own documentation |
| Register Bastion sites in AM | Our team + client team | This document |
| Bastion SSO consumer configuration | Our team | This document |
| Bastion health check endpoint | Our team | This document |
| Connectivity verification | Our team + client team | This document |

---

## What the Client Configures (AM Side)

The client team is responsible for configuring the following on the Access Manager side. We need the output of these configurations to complete the Bastion side.

| Configuration Item | What Client Provides to Us |
|---------------------|---------------------------|
| AM primary URL | `https://am1.client.com` |
| AM secondary URL | `https://am2.client.com` |
| AM HTTPS CA certificate | PEM file for trust verification |
| SAML IdP metadata URL | `https://am1.client.com/saml/metadata` |
| SAML Entity ID | `https://am1.client.com` |
| API service account | Username + API key for Bastion registration |
| Session brokering API URL | `https://am1.client.com/api/v1/sessions` |
| MFA method configured in AM | RADIUS (FortiAuth) or native AM MFA |

Collect all of the above before starting Bastion-side configuration.

---

## What We Configure (Bastion Side)

On each WALLIX Bastion site (Sites 1-5), we configure:

1. Trust the AM HTTPS certificate (import CA cert)
2. Configure SSO: Bastion as SAML Service Provider (SP)
3. Configure health check endpoint (AM polls this to know Bastion is alive)
4. Register Bastion API endpoint with AM (client team adds it in AM)
5. Test the SSO login flow end-to-end

---

## Information Required from Client AM Team

Use the following form when coordinating with the client AM team. All fields are required.

```
+===============================================================================+
|  INFORMATION REQUEST - ACCESS MANAGER INTEGRATION                             |
+===============================================================================+

Project: WALLIX Bastion 5-Site Deployment
Requesting: Bastion-side integration parameters

1. Access Manager Endpoints
   AM1 (Primary) URL:        ___________________________
   AM1 IP Address:           ___________________________
   AM2 (Secondary) URL:      ___________________________
   AM2 IP Address:           ___________________________
   Current Active Node:      AM1 / AM2

2. HTTPS Certificates
   Root CA Certificate:      [file attachment]
   Intermediate CA:          [file attachment, if applicable]

3. SAML Configuration
   IdP Metadata URL:         ___________________________
   Entity ID:                ___________________________
   SSO Binding:              HTTP-POST / HTTP-Redirect
   Single Logout supported:  Yes / No
   Attribute mapping:
     Username attribute:     ___________________________
     Email attribute:        ___________________________
     Groups attribute:       ___________________________

4. API Integration
   API Base URL:             ___________________________
   API authentication:       Bearer token / OAuth2 / API key
   Service account name:     ___________________________
   API key / token:          [secure channel delivery]

5. Session Brokering
   Brokering API endpoint:   ___________________________
   Health check interval:    ___ seconds
   Capacity reporting:       Yes / No

6. MFA Configuration
   MFA enforced by AM:       Yes / No
   MFA method:               FortiAuthenticator RADIUS / native AM MFA
   Bypass for service accts: Yes / No

+===============================================================================+
```

---

## Registering Bastion Sites in Access Manager

The client team registers each Bastion site in the AM. We provide them with the following details for each site.

### Details to Provide for Each Site

| Field | Site 1 | Site 2 | Site 3 | Site 4 | Site 5 |
|-------|--------|--------|--------|--------|--------|
| Site name | bastion-site1 | bastion-site2 | bastion-site3 | bastion-site4 | bastion-site5 |
| Bastion URL (HAProxy VIP) | https://bastion-site1.company.com | (same pattern) | | | |
| Bastion IP (HAProxy VIP) | 10.10.1.100 | 10.10.2.100 | 10.10.3.100 | 10.10.4.100 | 10.10.5.100 |
| Health check URL | https://bastion-site1.company.com/health | | | | |
| API endpoint | https://bastion-site1.company.com/api/v3 | | | | |
| Approximate capacity (sessions) | ~25 | ~25 | ~25 | ~25 | ~25 |

> The client AM team adds these entries in the AM console. We do not have access to the AM administration interface.

---

## SSO/SAML Configuration on Bastion Side

Configure WALLIX Bastion as a SAML 2.0 Service Provider (SP). The Access Manager acts as the Identity Provider (IdP).

### Step 1: Import AM CA Certificate

On each Bastion node (Sites 1-5), import the CA certificate provided by the client team:

```bash
# Copy CA cert to Bastion trust store
cp /tmp/am-ca.pem /usr/local/share/ca-certificates/am-ca.crt
update-ca-certificates

# Verify import
openssl verify -CAfile /etc/ssl/certs/ca-certificates.crt /tmp/am-ca.pem
```

Via Web UI:

```
Configuration > Certificates > Certificate Authorities > Import

Upload: am-ca.pem
Type: CA Certificate
Usage: HTTPS verification
```

### Step 2: Configure SAML Identity Provider

```
Configuration > Authentication > SAML > Add Identity Provider

Name: ClientAccessManager
IdP Metadata URL: https://am1.client.com/saml/metadata
  (or upload metadata XML file)

Entity ID: https://am1.client.com
SSO URL: https://am1.client.com/saml/sso
SLO URL: https://am1.client.com/saml/slo  (if supported)

Attribute Mapping:
  Username attribute: uid  (confirm with AM team)
  Email attribute: mail
  Groups attribute: memberOf

Enabled: Yes
```

### Step 3: Generate SP Metadata

After configuring the IdP, download the Bastion SP metadata and provide it to the client AM team:

```
Configuration > Authentication > SAML > Service Provider Metadata > Download

Provide file to AM team for IdP-side configuration.
```

The SP metadata URL is:

```
https://bastion-siteX.company.com/auth/saml/metadata
```

### Step 4: Test SAML Authentication

```bash
# On Bastion
wabadmin auth test-saml --provider ClientAccessManager --user testuser@company.local

# Expected output:
# SAML assertion received
# Username: testuser
# Groups: PAM-Users
# Authentication: SUCCESS
```

---

## Session Brokering Endpoint Configuration

WALLIX Bastion exposes a health check endpoint and an API endpoint that the Access Manager uses for session routing.

### Health Check Endpoint

```bash
# Verify the health endpoint is accessible from AM
# (Test from AM side, or use curl)
curl -k https://bastion-site1.company.com/health

# Expected output:
# {"status": "ok", "version": "12.1.x", "sessions_active": 0}
```

### API Endpoint for Session Brokering

The Bastion REST API is available at:

```
https://bastion-siteX.company.com/api/v3
```

Generate a Bastion API key for the Access Manager:

```bash
# Create API key for AM integration
wabadmin apikey create \
  --name "AccessManager-Integration" \
  --profile "session-broker" \
  --description "API key for AM session brokering"

# Output: API_KEY = <generated key>
# Provide this key to the client AM team
```

The AM team configures this API key on their side to authenticate API calls to the Bastion.

### Configure AM API Credentials on Bastion

If the Bastion initiates calls to the AM (for example, SSO callbacks or health reports), configure the AM API credentials:

```
Configuration > External Services > Access Manager

AM Primary URL: https://am1.client.com
AM Secondary URL: https://am2.client.com
API Key: <provided by AM team>
CA Certificate: ClientAccessManager CA
Connection timeout: 10s
Health check interval: 30s
```

---

## Connectivity Verification

Perform these verification steps jointly with the client AM team after all configuration is complete.

### Test 1: Network Connectivity (MPLS)

```bash
# From each Bastion site, verify MPLS connectivity to AM
ping 10.100.1.10   # AM1 (adjust to actual AM IPs)
ping 10.100.2.10   # AM2

# Verify HTTPS port
curl -v --cacert /tmp/am-ca.pem https://am1.client.com/health

# Expected: HTTP 200
```

### Test 2: SAML SSO Login

```
1. Open browser: https://bastion-site1.company.com
2. Click "Login with SSO" (or equivalent)
3. Browser redirects to AM SSO URL
4. Authenticate with AD credentials + MFA (FortiToken)
5. AM redirects back to Bastion with SAML assertion
6. Bastion grants access and shows dashboard

Pass criteria: User reaches Bastion dashboard without error.
```

### Test 3: Session Brokering API

The client AM team verifies their side can reach the Bastion API:

```bash
# Tested from AM side (client team runs this)
curl -X GET https://bastion-site1.company.com/health \
  -H "X-Auth-Key: <bastion-api-key>"

# Expected: HTTP 200 with status JSON
```

### Test 4: AM Failover

```
1. Client team simulates AM1 (Primary) failure.
2. AM2 (Secondary) becomes active.
3. Verify Bastion SSO still works (SAML requests route to AM2).
4. Verify health checks succeed via AM2.

Pass criteria: SSO login succeeds within 60 seconds of AM1 failure.
```

---

## Handoff Checklist

Complete this checklist jointly with the client AM team before considering the integration done.

```
+===============================================================================+
|  ACCESS MANAGER INTEGRATION SIGN-OFF CHECKLIST                                |
+===============================================================================+

Bastion-Side Configuration:
[ ] AM CA certificate imported on all 5 Bastion sites
[ ] SAML IdP configured on all 5 Bastion sites
[ ] SP metadata provided to AM team for all 5 sites
[ ] AM API credentials configured on all 5 Bastion sites
[ ] Bastion API keys generated and provided to AM team

Connectivity Verification:
[ ] MPLS connectivity verified: AM <-> each Bastion site (443 TCP)
[ ] Health check endpoint accessible from AM side (all 5 sites)
[ ] API endpoint accessible from AM side (all 5 sites)

SSO Testing:
[ ] SAML SSO login tested for Site 1 (reference)
[ ] SAML SSO login tested for Sites 2-5
[ ] Group-to-profile mapping verified (users get correct Bastion access)
[ ] SSO logout tested (if SLO configured)

Session Brokering:
[ ] Session brokering tested by client AM team
[ ] Health check reports correct session capacity
[ ] AM routes sessions to correct Bastion site

Failover:
[ ] AM1 failover tested: SSO works via AM2 (client team test)
[ ] Bastion HA failover tested with AM: SSO resumes after Bastion failover

Documentation:
[ ] AM API endpoint URLs documented
[ ] API keys stored in secrets vault
[ ] Integration architecture diagram updated
[ ] Runbook for "AM unreachable" scenario agreed with client team

Sign-off:
[ ] Our team lead: ________________________ Date: _________
[ ] Client AM team lead: __________________ Date: _________

+===============================================================================+
```

---

## Cross-References

| Topic | Document |
|-------|----------|
| Full site deployment | [05-site-deployment.md](05-site-deployment.md) |
| Bastion HA configuration | [07-bastion-active-active.md](07-bastion-active-active.md) |
| Network and MPLS | [01-network-design.md](01-network-design.md) |
| Break glass when AM is unavailable | [14-break-glass-procedures.md](14-break-glass-procedures.md) |
| AM scenario in contingency plan | [13-contingency-plan.md](13-contingency-plan.md) |
| Testing validation | [11-testing-validation.md](11-testing-validation.md) |
| Bastion REST API reference | [../docs/pam/17-api-reference/README.md](../docs/pam/17-api-reference/README.md) |
