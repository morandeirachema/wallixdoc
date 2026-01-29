# OT Integration Procedures

## Step-by-Step Integration Guides

This guide provides practical, tested procedures for integrating WALLIX with common OT systems.

---

## Historian Integration

### OSIsoft PI Integration

**Goal**: Enable WALLIX-proxied access to PI System and log access events to PI historian.

```
+==============================================================================+
|                   PI SYSTEM INTEGRATION                                       |
+==============================================================================+

  ARCHITECTURE
  ============

  Engineers                 WALLIX              PI System
  +--------+            +------------+      +------------------+
  |        |   HTTPS    |            |      |  PI Data Archive |
  | TIA    +------------>  Session   +----->|  PI Asset Fwk    |
  | Portal |            |  Manager   |      |  PI Vision       |
  +--------+            +-----+------+      +--------+---------+
                              |                      |
                              | Syslog               | PI Web API
                              v                      v
                        +------------+      +------------------+
                        |   SIEM     |      |  PI Integrator   |
                        +------------+      +------------------+

+==============================================================================+
```

**Step 1: Configure PI Interface Server Access**

```
# In WALLIX Admin UI

1. Create Domain:
   Configuration > Domains > Add
   - Name: PI-System
   - Description: OSIsoft PI Infrastructure

2. Add PI Interface Node:
   Configuration > Devices > Add
   - Name: pi-interface-01
   - Host: 10.100.50.10
   - Domain: PI-System

3. Add Services:
   Configuration > Devices > pi-interface-01 > Services

   SSH Service:
   - Type: SSH
   - Port: 22

   RDP Service:
   - Type: RDP
   - Port: 3389

   PI Data Archive (tunnel):
   - Type: SSH Tunnel
   - Local Port: 5450
   - Description: PI Data Archive access

4. Add Accounts:
   Configuration > Devices > pi-interface-01 > Accounts
   - Account: piadmin
   - Credentials: Password
   - Rotation: Weekly
```

**Step 2: Configure PI Vision Access**

```
# Add PI Vision Server

Configuration > Devices > Add
- Name: pi-vision-01
- Host: 10.100.50.20
- Domain: PI-System

Services:
- Type: HTTPS
- Port: 443
- URL Path: /PIVision

Accounts:
- Account: pivision-svc
- Auto-rotation: Disabled (service account)
```

**Step 3: Create Authorization**

```
Configuration > Authorizations > Add

Name: OT-Engineers-PI
User Group: OT-Engineers
Target Group: PI-System-Admin

Settings:
- Recording: Enabled
- Keystroke Logging: Enabled (for CLI access)
- Time Restriction: Business hours (08:00-18:00)
- Subprotocols: SSH Shell, RDP, HTTPS
```

**Step 4: Log PI Access to Historian (Advanced)**

```python
# Example: Send WALLIX session events to PI via PI Web API
# Save as: /opt/wallix/scripts/pi-logger.py

import requests
import json
from datetime import datetime

PI_WEB_API = "https://pi-server/piwebapi"
PI_TAG = "WALLIX.Sessions"

def log_session_to_pi(session_data):
    """Log WALLIX session start/end to PI historian"""

    timestamp = datetime.utcnow().isoformat() + "Z"

    # Format for PI Web API
    value = {
        "Timestamp": timestamp,
        "Value": json.dumps({
            "user": session_data["user"],
            "target": session_data["target"],
            "event": session_data["event"]
        })
    }

    # Get PI Point WebId
    point_url = f"{PI_WEB_API}/points?path=\\\\{PI_TAG}"
    response = requests.get(point_url, auth=('piuser', 'password'), verify=False)
    web_id = response.json()["WebId"]

    # Write value
    write_url = f"{PI_WEB_API}/streams/{web_id}/value"
    requests.post(write_url, json=value, auth=('piuser', 'password'), verify=False)

# Called from WALLIX syslog handler
```

---

### GE Proficy Historian Integration

**Step 1: Configure Historian Server Access**

```
Configuration > Devices > Add
- Name: ge-historian-01
- Host: 10.100.60.10
- Domain: OT-Historians

Services:
- Type: RDP (for Historian Admin)
  Port: 3389

- Type: SSH Tunnel (for OPC DA)
  Local Port: 135
  Remote Port: 135
  Description: OPC DCOM

- Type: SSH Tunnel (for Historian Data)
  Local Port: 14000
  Remote Port: 14000
  Description: Proficy Historian API

Accounts:
- Account: historian-admin
- Domain Account: OT-DOMAIN\hist-admin
- Rotation: Weekly (coordinate with service restart)
```

**Step 2: OPC UA Access Configuration**

```
# For systems supporting OPC UA (recommended over OPC DA)

Configuration > Devices > ge-historian-01 > Services > Add

Service:
- Type: SSH Tunnel
- Local Port: 4840
- Remote Port: 4840
- Description: OPC UA Server

Authorization:
- Recording: Enabled
- Approval: Required for config changes
```

---

### Wonderware Historian Integration

```
# Device Configuration

Configuration > Devices > Add
- Name: wonderware-historian
- Host: 10.100.70.10
- Domain: OT-Historians

Services:
1. SQL Server Access:
   - Type: SSH Tunnel
   - Local Port: 1433
   - Description: SQL Server for Historian

2. InTouch Access:
   - Type: RDP
   - Port: 3389
   - Description: InTouch HMI

3. SMC (System Management):
   - Type: HTTPS
   - Port: 443
   - Description: System Management Console

Accounts:
- historian-sql (SQL auth)
- intouch-eng (Windows auth)
```

---

## HMI/DCS Integration

### Siemens WinCC Integration

**Step 1: WinCC Server Configuration**

```
+==============================================================================+
|                   WINCC INTEGRATION                                           |
+==============================================================================+

  WALLIX Access to WinCC:

  +------------------+        +----------------+        +------------------+
  | Control Engineer |  RDP   | WALLIX Session |  RDP   | WinCC Runtime    |
  | (TIA Portal)     +------->| Manager        +------->| Server           |
  +------------------+        +-------+--------+        +------------------+
                                      |
                                      | Recording
                                      v
                              +----------------+
                              | Session Archive|
                              +----------------+

+==============================================================================+
```

```
# Device Setup

Configuration > Devices > Add
- Name: wincc-srv-01
- Host: 192.168.100.10
- Domain: OT-Level2-SCADA

Services:
1. WinCC Runtime (RDP):
   - Type: RDP
   - Port: 3389
   - NLA: Enabled

2. TIA Portal (Tunnel):
   - Type: SSH Tunnel
   - Local Port: 102
   - Description: S7 communication for TIA Portal

3. SQL Server (for alarming):
   - Type: SSH Tunnel
   - Local Port: 1433

Accounts:
- wincc-operator (for monitoring)
- wincc-engineer (for configuration)
- wincc-admin (for system admin)
```

**Step 2: Credential Injection for WinCC**

```
# WinCC uses Windows authentication
# Configure domain account mapping

Authorization Settings:
- Credential Injection: Enabled
- Account Mapping: Personal (user's AD account)
- Or: Shared (wincc-operator for all operators)

# For shared accounts, enable credential injection:
Account Settings:
- Auto-logon: Enabled
- Show credentials to user: Disabled
```

---

### Rockwell FactoryTalk View Integration

```
# FactoryTalk View SE Server

Configuration > Devices > Add
- Name: ftview-srv-01
- Host: 192.168.110.10
- Domain: OT-Level2-SCADA

Services:
1. FactoryTalk View SE (RDP):
   - Type: RDP
   - Port: 3389

2. RSLinx (Tunnel):
   - Type: SSH Tunnel
   - Local Port: 44818
   - Description: EtherNet/IP for RSLinx

Accounts:
- ft-operator
- ft-engineer

# Authorization with time restrictions
Authorization:
- Name: Operators-FTView
- User Group: Plant-Operators
- Time Restriction: 24x7 (production environment)

Authorization:
- Name: Engineers-FTView
- User Group: Controls-Engineers
- Approval: Required for off-hours access
```

---

### AVEVA (Wonderware) InTouch Integration

```
Configuration > Devices > Add
- Name: intouch-node-01
- Host: 192.168.120.10
- Domain: OT-Level2-HMI

Services:
1. InTouch HMI (RDP):
   - Type: RDP
   - Port: 3389

2. WindowMaker (RDP):
   - Type: RDP
   - Port: 3389
   - Description: Development environment

Accounts:
- intouch-oper (operator mode)
- intouch-dev (development mode)

# Note: InTouch uses separate accounts for runtime vs development
# Create different authorizations:

Authorization 1: Operators-InTouch-Runtime
- Target: intouch-oper account
- Subprotocols: RDP only
- Recording: Enabled

Authorization 2: Engineers-InTouch-Dev
- Target: intouch-dev account
- Approval: Required
- 4-Eyes: Required for changes
```

---

## MES Integration

### SAP MII/ME Integration

```
Configuration > Devices > Add
- Name: sap-mes-01
- Host: 10.200.10.10
- Domain: MES-Systems

Services:
1. SAP Web Interface:
   - Type: HTTPS
   - Port: 443

2. SAP GUI (Tunnel):
   - Type: SSH Tunnel
   - Local Port: 3200-3299
   - Description: SAP GUI connections

Accounts:
- mes-operator (transactional)
- mes-admin (configuration)

Authorization:
- Recording: Enabled for all sessions
- OCR: Enabled for RDP sessions
- Time Restriction: None (24x7 production)
```

---

### Rockwell PharmaSuite (FactoryTalk ProductionCentre)

```
# Pharmaceutical MES with FDA 21 CFR Part 11

Configuration > Devices > Add
- Name: pharmasuite-srv
- Host: 10.200.20.10
- Domain: MES-Pharma

Services:
1. PharmaSuite Client (RDP):
   - Type: RDP
   - Port: 3389

2. SQL Server:
   - Type: SSH Tunnel
   - Local Port: 1433

Accounts:
- ps-operator
- ps-supervisor
- ps-admin

# FDA 21 CFR Part 11 Authorization
Authorization:
- Name: Pharma-Operators
- Recording: REQUIRED (regulatory)
- Keystroke Logging: REQUIRED
- Approval: Required for batch release
- Electronic Signature: Enabled

# Configure e-signature:
Authorization Settings:
- Re-authentication: Required before sensitive operations
- Comment Required: Yes (reason for access)
```

---

## Vendor Remote Access Integration

### Standard Vendor Access Procedure

```
+==============================================================================+
|                   VENDOR ACCESS WORKFLOW                                      |
+==============================================================================+

  1. VENDOR REQUEST           2. APPROVAL              3. ACCESS
  ================           =========              ======

  Vendor submits     --->    OT Manager     --->    Time-limited
  access request             reviews                 access granted
  via portal                 & approves

  +----------------+        +----------------+       +----------------+
  | Vendor Portal  |  --->  | Approval Queue |  --->| WALLIX Session |
  | - Target       |        | - Review scope |       | - Recording    |
  | - Time window  |        | - Check ticket |       | - 4-Eyes opt.  |
  | - Reason/ticket|        | - Approve/Deny |       | - Time-limited |
  +----------------+        +----------------+       +----------------+

+==============================================================================+
```

**Step 1: Create Vendor User Group**

```
Configuration > User Groups > Add
- Name: External-Vendors
- Description: Third-party maintenance vendors
```

**Step 2: Create Vendor Users**

```
Configuration > Users > Add
- Username: siemens-support
- Full Name: Siemens Remote Support
- User Group: External-Vendors
- Source: Local (not LDAP)
- MFA: Required
```

**Step 3: Create Time-Limited Authorization**

```
Configuration > Authorizations > Add

Name: Vendor-Siemens-PLCs
User Group: External-Vendors
Target Group: Siemens-PLCs

Settings:
- Approval: REQUIRED
- Approvers: OT-Managers
- Recording: REQUIRED
- 4-Eyes: Optional (approver can require)
- Time Limit: Maximum 4 hours
- Auto-disconnect: Enabled

Time Restrictions:
- Days: Monday-Friday
- Hours: 08:00-18:00
- Or: Approved maintenance window only
```

**Step 4: Approval Workflow**

```
# When vendor requests access:

1. Vendor logs into WALLIX user portal
2. Selects target system
3. Sees "Approval Required" message
4. Fills in:
   - Reason: "Firmware update per advisory SA-2026-001"
   - Ticket: "CHG-12345"
   - Duration: 2 hours
   - Scheduled time: 2026-01-30 14:00

5. OT Manager receives notification
6. Reviews request in WALLIX Admin:
   Configuration > Approvals > Pending

7. Approver can:
   - Approve (optionally require 4-eyes)
   - Deny (with reason)
   - Modify time window

8. Vendor receives notification
9. At scheduled time, vendor can connect
10. Session is recorded
```

---

## SIEM Integration Procedures

### Splunk HEC Setup

**Step 1: Configure Splunk HEC**

```bash
# On Splunk server:
# Settings > Data Inputs > HTTP Event Collector > New Token

Token Name: wallix-pam4ot
Source Type: wallix:pam
Index: security

# Copy the token value
```

**Step 2: Configure WALLIX Syslog**

```
# In WALLIX Admin UI:
System > Settings > Syslog

Destination 1:
- Host: splunk-hec.company.com
- Port: 8088
- Protocol: HTTPS
- Format: JSON
- Certificate Verification: Enabled

# Or via CLI:
waconfig syslog add \
  --host splunk-hec.company.com \
  --port 8088 \
  --protocol https \
  --format json
```

**Step 3: Test Integration**

```bash
# Generate test event:
logger -n localhost -P 514 "WALLIX test message"

# Verify in Splunk:
index=security sourcetype=wallix:pam | head 10
```

---

### QRadar Integration

**Step 1: Configure Log Source**

```
# In QRadar:
Admin > Log Sources > Add

Log Source Type: Universal DSM
Protocol: Syslog
Log Source Identifier: wallix-pam4ot

# Configure parsing:
Admin > DSM Editor > Create New DSM
Name: WALLIX PAM4OT
```

**Step 2: WALLIX Syslog Configuration**

```
System > Settings > Syslog

Destination:
- Host: qradar-collector.company.com
- Port: 514
- Protocol: TCP/TLS
- Format: CEF (Common Event Format)
```

---

## ServiceNow ITSM Integration

### Ticket Validation

```python
# /opt/wallix/scripts/snow-validate.py
# Validates ticket numbers before session access

import requests

SNOW_INSTANCE = "company.service-now.com"
SNOW_USER = "wallix-api"
SNOW_PASS = "api-password"

def validate_ticket(ticket_number):
    """Verify ticket exists and is open in ServiceNow"""

    # Check incident
    url = f"https://{SNOW_INSTANCE}/api/now/table/incident"
    params = {
        "sysparm_query": f"number={ticket_number}^state!=7",  # Not closed
        "sysparm_limit": 1
    }

    response = requests.get(url, params=params,
                           auth=(SNOW_USER, SNOW_PASS))

    if response.json().get("result"):
        return True

    # Check change request
    url = f"https://{SNOW_INSTANCE}/api/now/table/change_request"
    params = {
        "sysparm_query": f"number={ticket_number}^state!=3",  # Not closed
        "sysparm_limit": 1
    }

    response = requests.get(url, params=params,
                           auth=(SNOW_USER, SNOW_PASS))

    return bool(response.json().get("result"))

# Usage in WALLIX authorization:
# Require ticket field
# Call this script via webhook on session start
```

---

## Integration Verification Checklist

After completing any integration:

| Check | How to Verify |
|-------|---------------|
| Sessions work | Launch test session to integrated system |
| Recording works | Review session in Audit > Sessions > History |
| Logs flow to SIEM | Check SIEM for WALLIX events |
| Approval workflow | Request access requiring approval, verify notification |
| Time restrictions | Attempt access outside window (should fail) |
| Credential rotation | Trigger rotation, verify target accepts new password |
| Tunnel connectivity | Connect through tunnel, access target application |

---

## Troubleshooting Integration Issues

### Tunnel Connection Fails

```bash
# Check WALLIX can reach target port
nc -zv target-ip target-port

# Check SSH tunnel is established
ss -tuln | grep local-port

# Check logs
tail -f /var/log/wabsessions/sessions.log | grep tunnel
```

### SIEM Not Receiving Logs

```bash
# Verify syslog is running
systemctl status rsyslog

# Test manual log
logger -n siem-server -P 514 "WALLIX test"

# Check network
tcpdump -i any port 514
```

### Historian Access Denied

```
1. Verify account credentials in WALLIX vault
2. Check if password rotation succeeded
3. Verify firewall allows tunnel ports
4. Check target application authentication logs
```

---

<p align="center">
  <a href="./README.md">OT Integration Overview</a> •
  <a href="../17-industrial-protocols/README.md">Industrial Protocols</a> •
  <a href="../12-troubleshooting/README.md">Troubleshooting</a>
</p>
