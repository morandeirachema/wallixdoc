# 22 - OT System Integration

## Table of Contents

1. [SIEM Integration](#siem-integration)
2. [CMDB Integration](#cmdb-integration)
3. [ITSM Integration](#itsm-integration)
4. [OT Monitoring Platforms](#ot-monitoring-platforms)
5. [Historian Integration](#historian-integration)
6. [LDAP/AD for OT](#ldapad-for-ot)
7. [API Automation](#api-automation)

---

## SIEM Integration

### Splunk Integration

```
+==============================================================================+
|                   SPLUNK INTEGRATION                                         |
+==============================================================================+

  ARCHITECTURE
  ============

  +------------------------------------------------------------------------+
  |                                                                        |
  |   WALLIX Bastion                              SPLUNK                   |
  |   +------------------+                    +------------------+         |
  |   |                  |   Syslog (TLS)     |                  |         |
  |   | Session Manager  +-------------------->  Splunk HEC     |         |
  |   |                  |   or HTTP Event    |  (Heavy Forwarder)         |
  |   +------------------+   Collector        +--------+---------+         |
  |                                                    |                   |
  |                                                    v                   |
  |                                           +------------------+         |
  |                                           |  Splunk Search   |         |
  |                                           |  Head (Indexer)  |         |
  |                                           +--------+---------+         |
  |                                                    |                   |
  |                                                    v                   |
  |                                           +------------------+         |
  |                                           |  Dashboards &    |         |
  |                                           |  Alerts          |         |
  |                                           +------------------+         |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  SYSLOG CONFIGURATION (WALLIX)
  =============================

  /etc/opt/wab/wabengine/wabengine.conf:

  +------------------------------------------------------------------------+
  | [syslog]                                                               |
  | enabled = true                                                         |
  | server = splunk-hec.company.com                                        |
  | port = 6514                                                            |
  | protocol = tcp+tls                                                     |
  | format = cef                                                           |
  | ca_cert = /etc/opt/wab/certs/splunk-ca.pem                             |
  |                                                                        |
  | # Event filtering                                                      |
  | log_authentications = true                                             |
  | log_authorizations = true                                              |
  | log_sessions = true                                                    |
  | log_password_changes = true                                            |
  | log_admin_actions = true                                               |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  CEF LOG FORMAT
  ==============

  Common Event Format (CEF) structure from WALLIX:

  +------------------------------------------------------------------------+
  | CEF:0|WALLIX|Bastion|12.1|100|User Authentication|5|                    |
  |   src=192.168.1.100                                                    |
  |   suser=jsmith                                                         |
  |   outcome=success                                                      |
  |   reason=MFA validated                                                 |
  |   cs1Label=UserGroup cs1=ot_engineers                                  |
  |   cs2Label=AuthMethod cs2=LDAP+TOTP                                    |
  |   rt=Jan 27 2024 14:32:15                                              |
  +------------------------------------------------------------------------+

  Event Types (Signature IDs):
  +------------------------------------------------------------------------+
  | ID    | Event Type                                                     |
  +-------+----------------------------------------------------------------+
  | 100   | User authentication (success/failure)                          |
  | 101   | MFA validation                                                 |
  | 200   | Session start                                                  |
  | 201   | Session end                                                    |
  | 202   | Session terminated by admin                                    |
  | 300   | Authorization granted                                          |
  | 301   | Authorization denied                                           |
  | 400   | Password checkout                                              |
  | 401   | Password rotation                                              |
  | 500   | Configuration change                                           |
  | 600   | Approval workflow triggered                                    |
  | 601   | Approval granted                                               |
  | 602   | Approval denied                                                |
  +-------+----------------------------------------------------------------+

  --------------------------------------------------------------------------

  SPLUNK SEARCHES (SPL EXAMPLES)
  ==============================

  Failed Authentication Attempts:
  +------------------------------------------------------------------------+
  | index=wallix sourcetype=wallix:cef outcome=failure                     |
  | | stats count by src, suser                                            |
  | | where count > 5                                                      |
  | | sort -count                                                          |
  +------------------------------------------------------------------------+

  OT System Access by Vendor:
  +------------------------------------------------------------------------+
  | index=wallix sourcetype=wallix:cef cs1="vendors"                       |
  | | stats count, values(dhost) as targets by suser                       |
  | | sort -count                                                          |
  +------------------------------------------------------------------------+

  Session Duration Analysis:
  +------------------------------------------------------------------------+
  | index=wallix sourcetype=wallix:cef (SignatureID=200 OR SignatureID=201)|
  | | transaction suser dhost startswith=(SignatureID=200)                 |
  |     endswith=(SignatureID=201)                                         |
  | | eval duration_mins=duration/60                                       |
  | | stats avg(duration_mins), max(duration_mins) by dhost                |
  +------------------------------------------------------------------------+

+==============================================================================+
```

### QRadar Integration

```
+==============================================================================+
|                   QRADAR INTEGRATION                                         |
+==============================================================================+

  QRADAR LOG SOURCE CONFIGURATION
  ===============================

  +------------------------------------------------------------------------+
  |                                                                        |
  | Log Source Type: Universal LEEF                                        |
  | Protocol: Syslog                                                       |
  | Log Source Identifier: WALLIX_Bastion                                  |
  |                                                                        |
  | Parsing:                                                               |
  | - Use LEEF format for QRadar native parsing                            |
  | - Or: Create custom DSM for CEF                                        |
  |                                                                        |
  +------------------------------------------------------------------------+

  WALLIX LEEF Configuration:
  +------------------------------------------------------------------------+
  | [syslog]                                                               |
  | enabled = true                                                         |
  | server = qradar.company.com                                            |
  | port = 514                                                             |
  | protocol = tcp                                                         |
  | format = leef                                                          |
  +------------------------------------------------------------------------+

  LEEF Log Example:
  +------------------------------------------------------------------------+
  | LEEF:2.0|WALLIX|Bastion|12.1|SessionStart|                              |
  |   src=192.168.1.100                                                    |
  |   dst=10.10.10.50                                                      |
  |   usrName=jsmith                                                       |
  |   proto=SSH                                                            |
  |   devTime=Jan 27 2024 14:32:15 UTC                                     |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  QRADAR RULE EXAMPLES
  ====================

  1. OT Access Outside Business Hours:
  +------------------------------------------------------------------------+
  | Rule Name: WALLIX_OT_AfterHours_Access                                 |
  | Condition:                                                             |
  |   Log Source = WALLIX_Bastion                                          |
  |   AND Event Name = SessionStart                                        |
  |   AND Destination Network = OT_Networks                                |
  |   AND Time NOT between 07:00 and 19:00                                 |
  | Response: Create Offense (High Priority)                               |
  +------------------------------------------------------------------------+

  2. Multiple Failed Logins:
  +------------------------------------------------------------------------+
  | Rule Name: WALLIX_Brute_Force_Attempt                                  |
  | Condition:                                                             |
  |   Log Source = WALLIX_Bastion                                          |
  |   AND Event Name = AuthenticationFailure                               |
  |   AND count >= 5 in 5 minutes                                          |
  |   AND same Source IP                                                   |
  | Response: Create Offense, Block IP (via reference set)                 |
  +------------------------------------------------------------------------+

  3. Vendor Access to Critical Systems:
  +------------------------------------------------------------------------+
  | Rule Name: WALLIX_Vendor_Critical_Access                               |
  | Condition:                                                             |
  |   Log Source = WALLIX_Bastion                                          |
  |   AND Event Name = SessionStart                                        |
  |   AND Username matches "vendor_*"                                      |
  |   AND Destination in Reference Set "Critical_OT_Assets"                |
  | Response: Create Offense (Medium), Email to OT Security                |
  +------------------------------------------------------------------------+

+==============================================================================+
```

---

## CMDB Integration

### ServiceNow CMDB Integration

```
+==============================================================================+
|                   SERVICENOW CMDB INTEGRATION                                |
+==============================================================================+

  INTEGRATION ARCHITECTURE
  ========================

  +------------------------------------------------------------------------+
  |                                                                        |
  |   WALLIX Bastion                          ServiceNow                   |
  |   +------------------+                    +------------------+         |
  |   |                  |   REST API         |                  |         |
  |   | Device Inventory +<------------------>+  CMDB            |         |
  |   |                  |   Bi-directional   |  (CI Database)   |         |
  |   +------------------+                    +------------------+         |
  |                                                                        |
  |   Sync Options:                                                        |
  |   1. WALLIX -> SNOW: Export OT assets discovered/managed               |
  |   2. SNOW -> WALLIX: Import CIs as WALLIX devices                      |
  |   3. Bidirectional: Reconcile both systems                             |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  SERVICENOW TO WALLIX SYNC
  =========================

  Use Case: Automatically create WALLIX devices from ServiceNow CMDB CIs.

  ServiceNow Flow Designer Configuration:
  +------------------------------------------------------------------------+
  | Trigger: CI Created/Updated in OT Category                             |
  | Condition: CI Class in (PLC, RTU, SCADA, HMI, DCS)                     |
  | Action: REST API call to WALLIX                                        |
  +------------------------------------------------------------------------+

  API Call to Create Device in WALLIX:
  +------------------------------------------------------------------------+
  | POST /api/devices                                                      |
  | Authorization: Bearer <api_token>                                      |
  | Content-Type: application/json                                         |
  |                                                                        |
  | {                                                                      |
  |   "device_name": "{{ci.name}}",                                        |
  |   "host": "{{ci.ip_address}}",                                         |
  |   "description": "Imported from ServiceNow: {{ci.sys_id}}",            |
  |   "alias": "{{ci.asset_tag}}",                                         |
  |   "domain": "ot_assets",                                               |
  |   "services": [                                                        |
  |     {                                                                  |
  |       "protocol": "SSH",                                               |
  |       "port": 22                                                       |
  |     }                                                                  |
  |   ]                                                                    |
  | }                                                                      |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  WALLIX TO SERVICENOW SYNC
  =========================

  Use Case: Update ServiceNow CMDB with session data from WALLIX.

  Scheduled Script (Python):
  +------------------------------------------------------------------------+
  | import requests                                                        |
  | import json                                                            |
  |                                                                        |
  | # Get sessions from WALLIX                                             |
  | wallix_api = "https://wallix.company.com/api"                          |
  | sessions = requests.get(                                               |
  |     f"{wallix_api}/sessions",                                          |
  |     headers={"Authorization": f"Bearer {WALLIX_TOKEN}"},               |
  |     params={"start_date": "2024-01-01", "end_date": "2024-01-31"}      |
  | ).json()                                                               |
  |                                                                        |
  | # Update ServiceNow CIs with last access time                          |
  | snow_api = "https://company.service-now.com/api/now/table/cmdb_ci"     |
  |                                                                        |
  | for session in sessions:                                               |
  |     ci_query = f"ip_address={session['target_host']}"                  |
  |     ci = requests.get(                                                 |
  |         snow_api,                                                      |
  |         headers={"Authorization": f"Bearer {SNOW_TOKEN}"},             |
  |         params={"sysparm_query": ci_query}                             |
  |     ).json()                                                           |
  |                                                                        |
  |     if ci['result']:                                                   |
  |         requests.patch(                                                |
  |             f"{snow_api}/{ci['result'][0]['sys_id']}",                  |
  |             headers={"Authorization": f"Bearer {SNOW_TOKEN}"},         |
  |             json={                                                     |
  |                 "u_last_pam_access": session['start_time'],            |
  |                 "u_last_pam_user": session['user']                     |
  |             }                                                          |
  |         )                                                              |
  +------------------------------------------------------------------------+

+==============================================================================+
```

---

## ITSM Integration

### Approval Workflow Integration

```
+==============================================================================+
|                   ITSM WORKFLOW INTEGRATION                                  |
+==============================================================================+

  SCENARIO: Integrate WALLIX approval workflows with ITSM ticketing systems.

  WORKFLOW ARCHITECTURE
  =====================

  +------------------------------------------------------------------------+
  |                                                                        |
  |   User                WALLIX              ITSM                Approver |
  |     |                   |                   |                    |     |
  |     | 1. Request        |                   |                    |     |
  |     |    access         |                   |                    |     |
  |     +------------------>|                   |                    |     |
  |     |                   |                   |                    |     |
  |     |                   | 2. Create ticket  |                    |     |
  |     |                   |    (webhook)      |                    |     |
  |     |                   +------------------>|                    |     |
  |     |                   |                   |                    |     |
  |     |                   |                   | 3. Notify          |     |
  |     |                   |                   +-------------------->     |
  |     |                   |                   |                    |     |
  |     |                   |                   | 4. Approve/Deny    |     |
  |     |                   |                   |<-------------------+     |
  |     |                   |                   |                    |     |
  |     |                   | 5. Update via API |                    |     |
  |     |                   |<------------------+                    |     |
  |     |                   |                   |                    |     |
  |     | 6. Access         |                   |                    |     |
  |     |    granted/denied |                   |                    |     |
  |     |<------------------+                   |                    |     |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  WALLIX WEBHOOK CONFIGURATION
  ============================

  Configure WALLIX to call ITSM API on approval request:

  /etc/opt/wab/wabengine/wabengine.conf:
  +------------------------------------------------------------------------+
  | [webhooks]                                                             |
  | enabled = true                                                         |
  |                                                                        |
  | [webhooks.approval_request]                                            |
  | url = https://itsm.company.com/api/tickets                             |
  | method = POST                                                          |
  | headers = {"Authorization": "Bearer ${ITSM_TOKEN}",                    |
  |            "Content-Type": "application/json"}                         |
  | body_template = {                                                      |
  |   "title": "PAM Access Request: ${user} -> ${target}",                 |
  |   "description": "User ${user} requests access to ${target}",          |
  |   "priority": "${priority}",                                           |
  |   "category": "Security/PAM",                                          |
  |   "assignment_group": "OT_Security",                                   |
  |   "custom_fields": {                                                   |
  |     "wallix_request_id": "${request_id}",                              |
  |     "requested_duration": "${duration}",                               |
  |     "target_type": "${target_type}"                                    |
  |   }                                                                    |
  | }                                                                      |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  ITSM CALLBACK TO WALLIX
  =======================

  When ticket is approved/denied, ITSM calls back to WALLIX:

  ServiceNow Business Rule (Approval Complete):
  +------------------------------------------------------------------------+
  | var wallix_api = "https://wallix.company.com/api";                     |
  | var request_id = current.u_wallix_request_id;                          |
  | var decision = current.approval == "approved" ? "approve" : "deny";    |
  |                                                                        |
  | var request = new sn_ws.RESTMessageV2();                               |
  | request.setEndpoint(wallix_api + "/approvals/" + request_id);          |
  | request.setHttpMethod("PATCH");                                        |
  | request.setRequestHeader("Authorization", "Bearer " + wallix_token);   |
  | request.setRequestBody(JSON.stringify({                                |
  |   "decision": decision,                                                |
  |   "approver": gs.getUserID(),                                          |
  |   "ticket_number": current.number,                                     |
  |   "comments": current.comments                                         |
  | }));                                                                   |
  | request.execute();                                                     |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  JIRA INTEGRATION EXAMPLE
  ========================

  Jira Automation Rule:
  +------------------------------------------------------------------------+
  | Trigger: Issue transitioned to "Approved"                              |
  | Condition: Project = "PAM-ACCESS"                                      |
  | Action: Send web request                                               |
  |                                                                        |
  | URL: https://wallix.company.com/api/approvals/{{issue.customfield_10001}}
  | Method: PATCH                                                          |
  | Headers:                                                               |
  |   Authorization: Bearer {{vault.WALLIX_API_TOKEN}}                     |
  |   Content-Type: application/json                                       |
  | Body:                                                                  |
  | {                                                                      |
  |   "decision": "approve",                                               |
  |   "approver": "{{initiator.accountId}}",                               |
  |   "ticket_number": "{{issue.key}}",                                    |
  |   "comments": "{{issue.summary}}"                                      |
  | }                                                                      |
  +------------------------------------------------------------------------+

+==============================================================================+
```

---

## OT Monitoring Platforms

### Claroty / Nozomi Integration

```
+==============================================================================+
|                   OT SECURITY PLATFORM INTEGRATION                           |
+==============================================================================+

  SCENARIO: Integrate WALLIX with OT security monitoring platforms
  (Claroty, Nozomi Networks, Dragos) for enhanced visibility.

  INTEGRATION ARCHITECTURE
  ========================

  +------------------------------------------------------------------------+
  |                                                                        |
  |                      OT NETWORK                                        |
  |                                                                        |
  |   +------------------+         +------------------+                    |
  |   |  WALLIX Bastion  |         |  OT Monitoring   |                    |
  |   |                  |         |  (Claroty/Nozomi)|                    |
  |   +--------+---------+         +--------+---------+                    |
  |            |                            |                              |
  |            |   API Integration          |   Network Monitoring         |
  |            |   +-------------------+    |   (Passive/SPAN)             |
  |            |   |                   |    |                              |
  |            +-->| Correlation       |<---+                              |
  |                | Engine            |                                   |
  |                +-------------------+                                   |
  |                                                                        |
  |   Benefits:                                                            |
  |   - Correlate user sessions with network activity                      |
  |   - Attribute anomalous traffic to specific users                      |
  |   - Detect unauthorized access attempts                                |
  |   - Unified OT security dashboard                                      |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  CLAROTY INTEGRATION
  ===================

  API Integration - Export Sessions to Claroty:
  +------------------------------------------------------------------------+
  | # Script to push WALLIX session data to Claroty                        |
  |                                                                        |
  | import requests                                                        |
  |                                                                        |
  | # Get active sessions from WALLIX                                      |
  | wallix_sessions = requests.get(                                        |
  |     "https://wallix.company.com/api/sessions/active",                  |
  |     headers={"Authorization": f"Bearer {WALLIX_TOKEN}"}                |
  | ).json()                                                               |
  |                                                                        |
  | # Post to Claroty as context enrichment                                |
  | for session in wallix_sessions:                                        |
  |     claroty_event = {                                                  |
  |         "source_ip": session['client_ip'],                             |
  |         "destination_ip": session['target_ip'],                        |
  |         "user": session['username'],                                   |
  |         "protocol": session['protocol'],                               |
  |         "session_id": session['id'],                                   |
  |         "start_time": session['start_time'],                           |
  |         "authorized": True,                                            |
  |         "pam_verified": True                                           |
  |     }                                                                  |
  |                                                                        |
  |     requests.post(                                                     |
  |         "https://claroty.company.com/api/v1/context",                  |
  |         headers={"Authorization": f"Bearer {CLAROTY_TOKEN}"},          |
  |         json=claroty_event                                             |
  |     )                                                                  |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  NOZOMI NETWORKS INTEGRATION
  ===========================

  Syslog Correlation:
  +------------------------------------------------------------------------+
  | Both WALLIX and Nozomi send logs to central SIEM                       |
  | SIEM correlates by:                                                    |
  |   - Source IP (client connecting through WALLIX)                       |
  |   - Destination IP (OT asset)                                          |
  |   - Timestamp (within session window)                                  |
  |                                                                        |
  | Nozomi Alert + WALLIX Session = Full attribution                       |
  |                                                                        |
  | Example SIEM Rule (Splunk):                                            |
  | +----------------------------------------------------------------+    |
  | | index=nozomi alert_type=* dest_ip=*                            |    |
  | | join dest_ip [                                                 |    |
  | |   search index=wallix SignatureID=200                          |    |
  | |   | rename target_ip as dest_ip                                |    |
  | |   | table suser, dest_ip, session_id, _time                    |    |
  | | ]                                                              |    |
  | | eval attributed_user=suser                                     |    |
  | | table _time, alert_type, dest_ip, attributed_user, session_id  |    |
  | +----------------------------------------------------------------+    |
  +------------------------------------------------------------------------+

+==============================================================================+
```

---

## Historian Integration

### OSIsoft PI / Aveva Integration

```
+==============================================================================+
|                   HISTORIAN INTEGRATION                                      |
+==============================================================================+

  SCENARIO: Secure access to industrial historians (OSIsoft PI, Aveva,
  Wonderware) through WALLIX.

  ACCESS ARCHITECTURE
  ===================

  +------------------------------------------------------------------------+
  |                                                                        |
  |   Users (Engineers, Analysts)                                          |
  |            |                                                           |
  |            v                                                           |
  |   +------------------+                                                 |
  |   |  WALLIX Bastion  |                                                 |
  |   +--------+---------+                                                 |
  |            |                                                           |
  |            | Protocol Proxy                                            |
  |            |                                                           |
  |   +--------+-----------------------------------------+                 |
  |   |                    |                             |                 |
  |   v                    v                             v                 |
  |                                                                        |
  | [PI Server]     [PI Vision/AF]     [ProcessBook Client]                |
  | (Data Archive)  (Web Interface)    (Desktop App)                       |
  |                                                                        |
  | Port 5450        Port 443           RDP to Jump Box                    |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  PI SYSTEM ACCESS SCENARIOS
  ==========================

  1. PI VISION WEB ACCESS
     +------------------------------------------------------------------+
     | Protocol: HTTPS (443)                                            |
     | Authorization: pi_analysts -> pi_vision_server                   |
     | Authentication: AD + MFA                                         |
     | Recording: Full session (web activity captured)                  |
     +------------------------------------------------------------------+

  2. PI PROCESSBOOK (DESKTOP)
     +------------------------------------------------------------------+
     | Protocol: RDP to Engineering Jump Box                            |
     | Jump Box has ProcessBook installed                                |
     | Authorization: pi_engineers -> pi_jump_box                       |
     | Authentication: AD + MFA                                         |
     | Recording: Full RDP session recording                            |
     |                                                                  |
     | Note: ProcessBook connects to PI server from jump box            |
     |       using Windows integrated authentication                    |
     +------------------------------------------------------------------+

  3. PI DATA ARCHIVE ADMINISTRATION
     +------------------------------------------------------------------+
     | Protocol: SSH or RDP to PI Server directly                       |
     | Authorization: pi_admins -> pi_server                            |
     | Authentication: AD + MFA + Approval required                     |
     | Recording: Full session + command logging                        |
     | Credential: PI admin account from WALLIX vault                   |
     +------------------------------------------------------------------+

  --------------------------------------------------------------------------

  AVEVA/WONDERWARE INTEGRATION
  ============================

  System Platform Access:
  +------------------------------------------------------------------------+
  |                                                                        |
  | Wonderware System Platform Components:                                 |
  |                                                                        |
  | +------------------+  +------------------+  +------------------+        |
  | | Galaxy Database  |  | InTouch HMI      |  | Historian Server |        |
  | | (GR Node)        |  | Runtime          |  |                  |        |
  | +--------+---------+  +--------+---------+  +--------+---------+        |
  |          |                     |                     |                 |
  |          +---------------------+---------------------+                 |
  |                                |                                       |
  |                                v                                       |
  |                       +------------------+                             |
  |                       |  WALLIX Bastion  |                             |
  |                       +------------------+                             |
  |                                                                        |
  | Access Methods:                                                        |
  | - Galaxy IDE: RDP to engineering workstation                           |
  | - InTouch ViewApp: RDP to HMI client                                   |
  | - Historian Client: RDP or HTTPS (if web-based)                        |
  |                                                                        |
  +------------------------------------------------------------------------+

  Authorization Configuration:
  +------------------------------------------------------------------------+
  | User Group        | Targets                    | Access Level          |
  +-------------------+----------------------------+-----------------------+
  | wonderware_ops    | InTouch Runtime HMIs       | View + Acknowledge    |
  | wonderware_eng    | Galaxy IDE, All HMIs       | Full engineering      |
  | wonderware_admin  | GR Node, Historian, All    | Full administration   |
  +-------------------+----------------------------+-----------------------+

+==============================================================================+
```

---

## LDAP/AD for OT

### Separate OT Directory Services

```
+==============================================================================+
|                   OT DIRECTORY SERVICES                                      |
+==============================================================================+

  ARCHITECTURE OPTIONS
  ====================

  +------------------------------------------------------------------------+
  |                                                                        |
  | OPTION 1: Corporate AD with OT OU                                      |
  | =====================================                                  |
  |                                                                        |
  |   +------------------+                                                 |
  |   |  Corporate AD    |                                                 |
  |   |                  |                                                 |
  |   |  OU=Corporate    |                                                 |
  |   |    OU=IT         |                                                 |
  |   |    OU=HR         |                                                 |
  |   |    OU=OT   <---- Separate OU for OT users/groups                   |
  |   |      OU=Operators                                                  |
  |   |      OU=Engineers                                                  |
  |   |      OU=Vendors                                                    |
  |   |                  |                                                 |
  |   +------------------+                                                 |
  |                                                                        |
  |   Pros: Single identity source, simplified management                  |
  |   Cons: IT/OT boundary less clear, AD outage affects OT                |
  |                                                                        |
  +------------------------------------------------------------------------+
  |                                                                        |
  | OPTION 2: Separate OT Directory (RECOMMENDED for high security)        |
  | ================================================================       |
  |                                                                        |
  |   +------------------+         +------------------+                    |
  |   |  Corporate AD    |         |   OT LDAP/AD     |                    |
  |   |  (IT Network)    |         |   (OT Network)   |                    |
  |   +--------+---------+         +--------+---------+                    |
  |            |                            |                              |
  |            |   NO TRUST                 |                              |
  |            |   (or one-way OT trusts IT)|                              |
  |            |                            |                              |
  |            +-------+    +---------------+                              |
  |                    |    |                                              |
  |                    v    v                                              |
  |            +------------------+                                        |
  |            |  WALLIX Bastion  |                                        |
  |            |  (Multiple auth  |                                        |
  |            |   sources)       |                                        |
  |            +------------------+                                        |
  |                                                                        |
  |   Pros: True IT/OT separation, OT continues if Corp AD fails           |
  |   Cons: Duplicate user management, sync complexity                     |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  WALLIX MULTI-DIRECTORY CONFIGURATION
  =====================================

  Configuration for multiple authentication sources:

  /etc/opt/wab/wabengine/wabengine.conf:
  +------------------------------------------------------------------------+
  | [authentication]                                                       |
  | # Priority order: local, OT_LDAP, Corp_AD                              |
  | sources = local, ot_ldap, corp_ad                                      |
  |                                                                        |
  | [authentication.local]                                                 |
  | # Local accounts (break-glass, service accounts)                       |
  | enabled = true                                                         |
  | priority = 1                                                           |
  |                                                                        |
  | [authentication.ot_ldap]                                               |
  | enabled = true                                                         |
  | priority = 2                                                           |
  | type = ldap                                                            |
  | server = ldap://ot-ldap.plant.local                                    |
  | port = 636                                                             |
  | ssl = true                                                             |
  | base_dn = dc=plant,dc=local                                            |
  | bind_dn = cn=wallix-svc,ou=service,dc=plant,dc=local                   |
  | user_filter = (&(objectClass=person)(sAMAccountName=%s))               |
  | group_filter = (&(objectClass=group)(member=%s))                       |
  |                                                                        |
  | [authentication.corp_ad]                                               |
  | enabled = true                                                         |
  | priority = 3                                                           |
  | type = ad                                                              |
  | server = ldap://corp-dc.company.com                                    |
  | port = 636                                                             |
  | ssl = true                                                             |
  | base_dn = ou=OT,dc=company,dc=com                                      |
  | bind_dn = cn=wallix-svc,ou=service,dc=company,dc=com                   |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  GROUP MAPPING
  =============

  Map directory groups to WALLIX groups:
  +------------------------------------------------------------------------+
  | Directory Group            | WALLIX Group        | Access Level        |
  +----------------------------+---------------------+---------------------+
  | CN=OT-Operators,OU=OT      | ot_operators        | HMI view access     |
  | CN=OT-Engineers,OU=OT      | ot_engineers        | Full OT access      |
  | CN=OT-Vendors,OU=OT        | ot_vendors          | Restricted access   |
  | CN=OT-Admins,OU=OT         | ot_admins           | WALLIX admin        |
  +----------------------------+---------------------+---------------------+

+==============================================================================+
```

---

## API Automation

### Ansible Integration

```
+==============================================================================+
|                   ANSIBLE AUTOMATION                                         |
+==============================================================================+

  USE CASE: Automate WALLIX configuration as part of OT infrastructure
  as code (IaC).

  ANSIBLE PLAYBOOK EXAMPLES
  =========================

  Device Provisioning:
  +------------------------------------------------------------------------+
  | ---                                                                    |
  | - name: Provision OT devices in WALLIX                                 |
  |   hosts: localhost                                                     |
  |   vars:                                                                |
  |     wallix_host: "wallix.company.com"                                  |
  |     wallix_token: "{{ vault_wallix_api_token }}"                       |
  |                                                                        |
  |   tasks:                                                               |
  |     - name: Create PLC device                                          |
  |       uri:                                                             |
  |         url: "https://{{ wallix_host }}/api/devices"                   |
  |         method: POST                                                   |
  |         headers:                                                       |
  |           Authorization: "Bearer {{ wallix_token }}"                   |
  |         body_format: json                                              |
  |         body:                                                          |
  |           device_name: "{{ item.name }}"                               |
  |           host: "{{ item.ip }}"                                        |
  |           domain: "ot_plcs"                                            |
  |           description: "{{ item.description }}"                        |
  |           services:                                                    |
  |             - protocol: "SSH"                                          |
  |               port: 22                                                 |
  |       loop:                                                            |
  |         - { name: "PLC-Line1", ip: "10.10.1.10", description: "Line 1" }
  |         - { name: "PLC-Line2", ip: "10.10.1.11", description: "Line 2" }
  |         - { name: "PLC-Line3", ip: "10.10.1.12", description: "Line 3" }
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  Account and Authorization Setup:
  +------------------------------------------------------------------------+
  | ---                                                                    |
  | - name: Configure OT accounts and authorizations                       |
  |   hosts: localhost                                                     |
  |   vars:                                                                |
  |     wallix_host: "wallix.company.com"                                  |
  |                                                                        |
  |   tasks:                                                               |
  |     - name: Create service account for PLC                             |
  |       uri:                                                             |
  |         url: "https://{{ wallix_host }}/api/accounts"                  |
  |         method: POST                                                   |
  |         headers:                                                       |
  |           Authorization: "Bearer {{ wallix_token }}"                   |
  |         body_format: json                                              |
  |         body:                                                          |
  |           account_name: "plc_admin"                                    |
  |           device: "PLC-Line1"                                          |
  |           credentials:                                                 |
  |             type: "password"                                           |
  |             password: "{{ vault_plc_password }}"                       |
  |                                                                        |
  |     - name: Create authorization                                       |
  |       uri:                                                             |
  |         url: "https://{{ wallix_host }}/api/authorizations"            |
  |         method: POST                                                   |
  |         headers:                                                       |
  |           Authorization: "Bearer {{ wallix_token }}"                   |
  |         body_format: json                                              |
  |         body:                                                          |
  |           authorization_name: "engineers_to_plcs"                      |
  |           user_group: "ot_engineers"                                   |
  |           target_group: "ot_plcs"                                      |
  |           is_recorded: true                                            |
  |           approval_required: false                                     |
  |           subprotocols:                                                |
  |             - "SSH_SHELL_SESSION"                                      |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  TERRAFORM PROVIDER
  ==================

  Example Terraform configuration (if provider available):
  +------------------------------------------------------------------------+
  | terraform {                                                            |
  |   required_providers {                                                 |
  |     wallix = {                                                         |
  |       source = "wallix/wallix"                                         |
  |     }                                                                  |
  |   }                                                                    |
  | }                                                                      |
  |                                                                        |
  | provider "wallix" {                                                    |
  |   host  = "wallix.company.com"                                         |
  |   token = var.wallix_api_token                                         |
  | }                                                                      |
  |                                                                        |
  | resource "wallix_device" "scada_server" {                              |
  |   name        = "SCADA-Primary"                                        |
  |   host        = "10.10.10.50"                                          |
  |   domain      = "ot_scada"                                             |
  |   description = "Primary SCADA Server"                                 |
  |                                                                        |
  |   service {                                                            |
  |     protocol = "RDP"                                                   |
  |     port     = 3389                                                    |
  |   }                                                                    |
  |                                                                        |
  |   service {                                                            |
  |     protocol = "SSH"                                                   |
  |     port     = 22                                                      |
  |   }                                                                    |
  | }                                                                      |
  +------------------------------------------------------------------------+

+==============================================================================+
```

---

## Next Steps

Continue to [23 - Industrial Best Practices](../23-industrial-best-practices/README.md) for comprehensive security guidelines.
