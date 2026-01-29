# 11 - Migration from CyberArk

## Table of Contents

1. [Migration Overview](#migration-overview)
2. [Concept Mapping](#concept-mapping)
3. [Migration Strategies](#migration-strategies)
4. [Data Migration](#data-migration)
5. [User Migration](#user-migration)
6. [Coexistence Scenarios](#coexistence-scenarios)
7. [Validation & Testing](#validation--testing)
8. [Common Challenges](#common-challenges)

## Related Documents

- **[CyberArk vs WALLIX Comparison](./cyberark-wallix-comparison.md)** - Learn WALLIX through CyberArk comparison: architecture, CPM vs Password Manager, OT capabilities, feature matrix

---

## Migration Overview

### Migration Considerations

```
+============================================================================+
|                       MIGRATION CONSIDERATIONS                             |
+============================================================================+
|                                                                            |
|  KEY DIFFERENCES TO PLAN FOR                                               |
|  ===========================                                               |
|                                                                            |
|  +------------------+-----------------------+--------------------------+   |
|  | Aspect           | CyberArk              | WALLIX                   |   |
|  +------------------+-----------------------+--------------------------+   |
|  | Session Mgmt     | Agent-based (PSM)     | Proxy-based              |   |
|  | Architecture     | Multi-component       | Unified appliance        |   |
|  | Vault Storage    | Proprietary filesystem| PostgreSQL               |   |
|  | Connection       | Via PSM server        | Direct proxy             |   |
|  | Recording Format | PSM recording format  | .wab format              |   |
|  | Platform Concept | Explicit platforms    | Device + Service model   |   |
|  +------------------+-----------------------+--------------------------+   |
|                                                                            |
|  --------------------------------------------------------------------------|
|                                                                            |
|  MIGRATION PHASES                                                          |
|  ================                                                          |
|                                                                            |
|  +------------------------------------------------------------------------+|
|  |                                                                        ||
|  |  Phase 1         Phase 2         Phase 3         Phase 4              | |
|  |  -------         -------         -------         -------              | |
|  |                                                                        ||
|  |  Assessment  --> Preparation --> Migration  --> Validation            | |
|  |                                                                        ||
|  |  * Inventory     * Design         * Data move     * Testing           | |
|  |  * Mapping       * Setup WALLIX   * User migrate  * Validation        | |
|  |  * Gap analysis  * Parallel run   * Cutover       * Documentation     | |
|  |                                                                        ||
|  |  2-4 weeks       2-4 weeks        2-8 weeks       1-2 weeks           | |
|  |                                                                        ||
|  +------------------------------------------------------------------------+|
|                                                                            |
+============================================================================+
```

---

## Concept Mapping

### Complete Terminology Mapping

```
+============================================================================+
|                      CYBERARK TO WALLIX MAPPING                            |
+============================================================================+
|                                                                            |
|  ORGANIZATIONAL STRUCTURE                                                  |
|  ========================                                                  |
|                                                                            |
|  CyberArk                             WALLIX                               |
|  --------                             ------                               |
|                                                                            |
|  Safe                          -->    Domain                               |
|  (Logical container)                  (Logical container)                  |
|                                                                            |
|  Platform                      -->    Device Type + Service                |
|  (Connection definition)              (Target + Protocol)                  |
|                                                                            |
|  Account                       -->    Account                              |
|  (Privileged credential)              (Privileged credential)              |
|                                                                            |
|  --------------------------------------------------------------------------|
|                                                                            |
|  ACCESS CONTROL                                                            |
|  ==============                                                            |
|                                                                            |
|  Safe Member                   -->    Authorization                        |
|  (User access to Safe)                (User Group > Target Group)          |
|                                                                            |
|  Safe Permissions              -->    Authorization Settings               |
|  (Use/Retrieve/List)                  (Subprotocols, Recording)            |
|                                                                            |
|  Master Policy                 -->    Global Settings                      |
|  (Default behaviors)                  (System defaults)                    |
|                                                                            |
|  --------------------------------------------------------------------------|
|                                                                            |
|  SESSION MANAGEMENT                                                        |
|  ==================                                                        |
|                                                                            |
|  PSM Connection Component      -->    Service (Protocol)                   |
|  (How to connect)                     (SSH, RDP, etc.)                     |
|                                                                            |
|  PSM Server                    -->    Bastion (Proxy)                      |
|  (Session broker)                     (Session broker)                     |
|                                                                            |
|  PSM Recording                 -->    Session Recording                    |
|  (.avi, proprietary)                  (.wab format)                        |
|                                                                            |
|  --------------------------------------------------------------------------|
|                                                                            |
|  PASSWORD MANAGEMENT                                                       |
|  ===================                                                       |
|                                                                            |
|  CPM (Central Policy Mgr)      -->    Password Manager                     |
|  (Password rotation)                  (Rotation engine)                    |
|                                                                            |
|  CPM Plugin                    -->    Target Connector                     |
|  (Platform-specific)                  (Platform-specific)                  |
|                                                                            |
|  Reconciliation Account        -->    Reconciliation Account               |
|  (Recovery account)                   (Same concept)                       |
|                                                                            |
|  --------------------------------------------------------------------------|
|                                                                            |
|  WORKFLOWS                                                                 |
|  =========                                                                 |
|                                                                            |
|  Dual Control                  -->    Approval Workflow                    |
|  (Require approver)                   (Require approver)                   |
|                                                                            |
|  Exclusive Access              -->    Exclusive Checkout                   |
|  (One user at a time)                 (One user at a time)                 |
|                                                                            |
|  Ticketing Integration         -->    ITSM Integration                     |
|  (ServiceNow, etc.)                   (API/Webhooks)                       |
|                                                                            |
+============================================================================+
```

### Object Model Comparison

```
+============================================================================+
|                        OBJECT MODEL COMPARISON                             |
+============================================================================+
|                                                                            |
|  CYBERARK MODEL                         WALLIX MODEL                       |
|  ==============                         ============                       |
|                                                                            |
|  +--------------------+               +--------------------+               |
|  |       SAFE         |               |      DOMAIN        |               |
|  | "Production-Unix"  |      -->      | "Production-Unix"  |               |
|  +---------+----------+               +---------+----------+               |
|            |                                    |                          |
|            |                                    |                          |
|  +---------+----------+               +---------+----------+               |
|  |      ACCOUNT       |               |      DEVICE        |               |
|  | "root-srv-prod-01" |               |  "srv-prod-01"     |               |
|  |                    |      -->      |       |            |               |
|  | Platform: Unix SSH |               | +-----+-----+      |               |
|  | Address: srv-prod  |               | |  SERVICE  |      |               |
|  | Username: root     |               | |  SSH:22   |      |               |
|  | Password: *****    |               | +-----+-----+      |               |
|  |                    |               |       |            |               |
|  +--------------------+               | +-----+-----+      |               |
|                                       | |  ACCOUNT  |      |               |
|                                       | |   root    |      |               |
|                                       | |  *****    |      |               |
|                                       | +-----------+      |               |
|                                       +--------------------+               |
|                                                                            |
|  KEY DIFFERENCE:                                                           |
|  * CyberArk: Account is primary object, contains address                   |
|  * WALLIX: Device is primary object, contains accounts                     |
|                                                                            |
+============================================================================+
```

---

## Migration Strategies

### Strategy Options

```
+============================================================================+
|                         MIGRATION STRATEGIES                               |
+============================================================================+
|                                                                            |
|  STRATEGY 1: BIG BANG                                                      |
|  ====================                                                      |
|                                                                            |
|  +-------------+              +-------------+                              |
|  |   CyberArk  |              |   WALLIX    |                              |
|  |   (Active)  |   Cutover    |   (Active)  |                              |
|  |             | -----------> |             |                              |
|  |   100%      |   Weekend    |   100%      |                              |
|  |             |              |             |                              |
|  +-------------+              +-------------+                              |
|                                                                            |
|  Pros: Clean cutover, no coexistence complexity                            |
|  Cons: Higher risk, requires extensive testing                             |
|  Best for: Smaller environments, limited integrations                      |
|                                                                            |
|  --------------------------------------------------------------------------|
|                                                                            |
|  STRATEGY 2: PHASED MIGRATION                                              |
|  ============================                                              |
|                                                                            |
|  Phase 1        Phase 2        Phase 3        Phase 4                      |
|  -------        -------        -------        -------                      |
|                                                                            |
|  CyberArk 100%  CyberArk 75%   CyberArk 25%   CyberArk 0%                  |
|  WALLIX   0%    WALLIX   25%   WALLIX   75%   WALLIX   100%                |
|                                                                            |
|  Migrate by:                                                               |
|  * Environment (Dev > Staging > Prod)                                      |
|  * System type (Linux > Windows > Network)                                 |
|  * Business unit                                                           |
|                                                                            |
|  Pros: Lower risk, gradual learning                                        |
|  Cons: Longer duration, coexistence complexity                             |
|  Best for: Large environments, critical systems                            |
|                                                                            |
|  --------------------------------------------------------------------------|
|                                                                            |
|  STRATEGY 3: PARALLEL RUN                                                  |
|  ========================                                                  |
|                                                                            |
|  +-------------+     +-------------+                                       |
|  |   CyberArk  |     |   WALLIX    |                                       |
|  |   (Active)  |     |   (Active)  |   Both managing same targets          |
|  |             |<--->|             |   during validation period            |
|  |   100%      |     |   100%      |                                       |
|  +-------------+     +-------------+                                       |
|                                                                            |
|  Pros: Full validation before cutover                                      |
|  Cons: Double infrastructure, password sync needed                         |
|  Best for: High-security environments requiring extensive testing          |
|                                                                            |
+============================================================================+
```

---

## Data Migration

### Export from CyberArk

```
+============================================================================+
|                         CYBERARK DATA EXPORT                               |
+============================================================================+
|                                                                            |
|  ACCOUNTS EXPORT                                                           |
|  ===============                                                           |
|                                                                            |
|  Option 1: PVWA Export (GUI)                                               |
|  ---------------------------                                               |
|  1. Navigate to Accounts view                                              |
|  2. Select accounts to export                                              |
|  3. Actions > Export to CSV                                                |
|                                                                            |
|  Option 2: REST API Export                                                 |
|  -------------------------                                                 |
|                                                                            |
|  #!/bin/bash                                                               |
|  # Export accounts via CyberArk REST API                                   |
|                                                                            |
|  CYBERARK_URL="https://pvwa.company.com"                                   |
|  TOKEN=$(curl -s -X POST \                                                 |
|    "$CYBERARK_URL/PasswordVault/API/Auth/CyberArk/Logon" \                 |
|    -H "Content-Type: application/json" \                                   |
|    -d '{"username":"admin","password":"pass"}' | jq -r '.')                |
|                                                                            |
|  # Get all accounts                                                        |
|  curl -s -X GET "$CYBERARK_URL/PasswordVault/API/Accounts" \               |
|       -H "Authorization: $TOKEN" \                                         |
|       -H "Content-Type: application/json" > accounts.json                  |
|                                                                            |
|  Option 3: Vault CLI Export                                                |
|  --------------------------                                                |
|  # Using PACli or similar tool                                             |
|                                                                            |
|  --------------------------------------------------------------------------|
|                                                                            |
|  EXPORT DATA FORMAT                                                        |
|  ==================                                                        |
|                                                                            |
|  Required fields for WALLIX import:                                        |
|  * Account name (or generate from address + username)                      |
|  * Address/Hostname                                                        |
|  * Username                                                                |
|  * Password (if exporting with credentials)                                |
|  * Platform type (for protocol mapping)                                    |
|  * Safe name (for domain mapping)                                          |
|                                                                            |
|  CSV Format:                                                               |
|  safe,platform,address,username,password,port,description                  |
|  Production,Unix-SSH,srv-prod-01,root,*****,22,Production server           |
|                                                                            |
+============================================================================+
```

### Import to WALLIX

```python
#!/usr/bin/env python3
"""
CyberArk to WALLIX Migration Script
"""

import csv
import requests
import json

# Configuration
WALLIX_URL = "https://bastion.company.com"
WALLIX_API_KEY = "your-api-key"

# Platform to Service mapping
PLATFORM_MAP = {
    "Unix via SSH": {"protocol": "SSH", "port": 22},
    "Windows Server": {"protocol": "RDP", "port": 3389},
    "Windows Domain": {"protocol": "RDP", "port": 3389},
    "Cisco IOS": {"protocol": "SSH", "port": 22},
    "Oracle Database": {"protocol": "SSH", "port": 22},
    "MySQL Database": {"protocol": "SSH", "port": 22},
}

headers = {
    "X-Auth-Token": WALLIX_API_KEY,
    "Content-Type": "application/json"
}


def create_domain(safe_name):
    """Create WALLIX domain from CyberArk safe"""
    data = {
        "domain_name": safe_name,
        "description": f"Migrated from CyberArk Safe: {safe_name}"
    }
    response = requests.post(
        f"{WALLIX_URL}/api/domains",
        headers=headers,
        json=data
    )
    return response.status_code in [200, 201, 409]  # 409 = already exists


def create_device(hostname, domain):
    """Create WALLIX device"""
    data = {
        "device_name": hostname,
        "host": hostname,
        "domain": domain,
        "description": "Migrated from CyberArk"
    }
    response = requests.post(
        f"{WALLIX_URL}/api/devices",
        headers=headers,
        json=data
    )
    return response.status_code in [200, 201, 409]


def create_service(device_name, protocol, port):
    """Create service on device"""
    data = {
        "service_name": protocol,
        "protocol": protocol,
        "port": port
    }
    response = requests.post(
        f"{WALLIX_URL}/api/devices/{device_name}/services",
        headers=headers,
        json=data
    )
    return response.status_code in [200, 201, 409]


def create_account(device_name, username, password):
    """Create account on device"""
    account_name = f"{username}@{device_name}"
    data = {
        "account_name": account_name,
        "login": username,
        "device": device_name,
        "credentials": {
            "type": "password",
            "password": password
        }
    }
    response = requests.post(
        f"{WALLIX_URL}/api/accounts",
        headers=headers,
        json=data
    )
    return response.status_code in [200, 201]


def migrate_from_cyberark_export(csv_file):
    """Main migration function"""
    with open(csv_file, 'r') as f:
        reader = csv.DictReader(f)

        for row in reader:
            safe = row['safe']
            platform = row['platform']
            address = row['address']
            username = row['username']
            password = row.get('password', '')

            # Map platform to service
            service_info = PLATFORM_MAP.get(platform, {"protocol": "SSH", "port": 22})

            # Create domain (safe)
            if create_domain(safe):
                print(f"Domain created/exists: {safe}")

            # Create device
            if create_device(address, safe):
                print(f"  Device created/exists: {address}")

            # Create service
            if create_service(address, service_info['protocol'], service_info['port']):
                print(f"    Service created: {service_info['protocol']}")

            # Create account
            if password:
                if create_account(address, username, password):
                    print(f"    Account created: {username}@{address}")
            else:
                print(f"    Account skipped (no password): {username}@{address}")


if __name__ == "__main__":
    migrate_from_cyberark_export("cyberark_export.csv")
```

---

## User Migration

### User & Group Migration

```
+============================================================================+
|                           USER MIGRATION                                   |
+============================================================================+
|                                                                            |
|  MIGRATION APPROACH                                                        |
|  ==================                                                        |
|                                                                            |
|  Users typically authenticated via LDAP/AD in both systems:                |
|  * No user data migration needed                                           |
|  * Configure same LDAP/AD source in WALLIX                                 |
|  * Map AD groups to WALLIX user groups                                     |
|                                                                            |
|  --------------------------------------------------------------------------|
|                                                                            |
|  GROUP MAPPING                                                             |
|  =============                                                             |
|                                                                            |
|  CyberArk Safe Members         -->         WALLIX Authorization            |
|                                                                            |
|  +------------------------------------------------------------------------+|
|  | CyberArk Configuration:                                                ||
|  |                                                                        ||
|  | Safe: Production-Linux                                                 ||
|  | Members:                                                               ||
|  |   - AD Group: PAM-Linux-Admins (Use, Retrieve)                         ||
|  |   - AD Group: PAM-Linux-Viewers (List only)                            ||
|  |                                                                        ||
|  +------------------------------------------------------------------------+|
|                          |                                                 |
|                          v                                                 |
|  +------------------------------------------------------------------------+|
|  | WALLIX Configuration:                                                  ||
|  |                                                                        ||
|  | User Group: Linux-Admins                                               ||
|  |   - LDAP Mapping: CN=PAM-Linux-Admins,OU=Groups,DC=...                 ||
|  |                                                                        ||
|  | User Group: Linux-Viewers                                              ||
|  |   - LDAP Mapping: CN=PAM-Linux-Viewers,OU=Groups,DC=...                ||
|  |                                                                        ||
|  | Target Group: Production-Linux-Servers                                 ||
|  |   - Contains all accounts from Production-Linux domain                 ||
|  |                                                                        ||
|  | Authorization 1: linux-admins-full-access                              ||
|  |   - User Group: Linux-Admins                                           ||
|  |   - Target Group: Production-Linux-Servers                             ||
|  |   - Subprotocols: SHELL, SCP, SFTP                                     ||
|  |                                                                        ||
|  | Authorization 2: linux-viewers-readonly                                ||
|  |   - User Group: Linux-Viewers                                          ||
|  |   - Target Group: Production-Linux-Servers                             ||
|  |   - Subprotocols: SHELL only                                           ||
|  |                                                                        ||
|  +------------------------------------------------------------------------+|
|                                                                            |
+============================================================================+
```

---

## Coexistence Scenarios

### Running Both Systems

```
+============================================================================+
|                       COEXISTENCE ARCHITECTURE                             |
+============================================================================+
|                                                                            |
|  SCENARIO: Phased Migration with Coexistence                               |
|                                                                            |
|                          +-----------------+                               |
|                          |     USERS       |                               |
|                          +--------+--------+                               |
|                                   |                                        |
|                   +---------------+---------------+                        |
|                   |                               |                        |
|                   v                               v                        |
|          +-----------------+           +-----------------+                 |
|          |    CyberArk     |           |     WALLIX      |                 |
|          |     (Legacy)    |           |     (New)       |                 |
|          +--------+--------+           +--------+--------+                 |
|                   |                             |                          |
|          +--------+--------+           +--------+--------+                 |
|          |                 |           |                 |                 |
|          v                 v           v                 v                 |
|  +--------------+ +--------------+ +--------------+ +--------------+       |
|  |   Windows    | |   Legacy     | |    Linux     | |   Network    |       |
|  |   Servers    | |   Systems    | |   Servers    | |   Devices    |       |
|  |              | |              | | (Migrated)   | | (Migrated)   |       |
|  +--------------+ +--------------+ +--------------+ +--------------+       |
|                                                                            |
|  --------------------------------------------------------------------------|
|                                                                            |
|  CONSIDERATIONS FOR COEXISTENCE                                            |
|  ==============================                                            |
|                                                                            |
|  1. Password Synchronization                                               |
|     * Disable rotation in one system for shared accounts                   |
|     * Or: Use API to sync passwords between systems                        |
|                                                                            |
|  2. User Experience                                                        |
|     * Clear documentation on which system for which targets                |
|     * Consider unified portal (if available)                               |
|                                                                            |
|  3. Audit Trail                                                            |
|     * Maintain audit in both systems                                       |
|     * SIEM integration from both sources                                   |
|                                                                            |
|  4. Support                                                                |
|     * Staff trained on both systems                                        |
|     * Clear escalation paths                                               |
|                                                                            |
+============================================================================+
```

---

## Validation & Testing

### Testing Checklist

```
+============================================================================+
|                     MIGRATION VALIDATION CHECKLIST                         |
+============================================================================+
|                                                                            |
|  DATA VALIDATION                                                           |
|  ===============                                                           |
|                                                                            |
|  [ ] Account count matches between systems                                 |
|  [ ] All devices/targets created                                           |
|  [ ] All services configured correctly                                     |
|  [ ] Credentials are correct (test authentication)                         |
|  [ ] Domain/Safe structure mapped correctly                                |
|                                                                            |
|  ACCESS VALIDATION                                                         |
|  =================                                                         |
|                                                                            |
|  [ ] Users can authenticate to WALLIX                                      |
|  [ ] LDAP/AD integration working                                           |
|  [ ] MFA working correctly                                                 |
|  [ ] User group memberships correct                                        |
|  [ ] Authorizations grant correct access                                   |
|  [ ] Time-based restrictions working                                       |
|                                                                            |
|  SESSION VALIDATION                                                        |
|  ==================                                                        |
|                                                                            |
|  [ ] SSH sessions connect successfully                                     |
|  [ ] RDP sessions connect successfully                                     |
|  [ ] Session recording working                                             |
|  [ ] Session playback working                                              |
|  [ ] Real-time monitoring working                                          |
|                                                                            |
|  PASSWORD MANAGEMENT VALIDATION                                            |
|  ==============================                                            |
|                                                                            |
|  [ ] Password rotation working                                             |
|  [ ] Rotation schedules configured                                         |
|  [ ] Verification after rotation succeeds                                  |
|  [ ] Reconciliation working                                                |
|                                                                            |
|  INTEGRATION VALIDATION                                                    |
|  ======================                                                    |
|                                                                            |
|  [ ] SIEM receiving logs                                                   |
|  [ ] ITSM integration working                                              |
|  [ ] API access working                                                    |
|  [ ] Alerting working                                                      |
|                                                                            |
+============================================================================+
```

---

## Common Challenges

### Challenges and Solutions

```
+============================================================================+
|                      COMMON MIGRATION CHALLENGES                           |
+============================================================================+
|                                                                            |
|  CHALLENGE 1: Platform Mapping Complexity                                  |
|  ========================================                                  |
|                                                                            |
|  Problem: CyberArk platforms don't map 1:1 to WALLIX                       |
|                                                                            |
|  Solution:                                                                 |
|  * Create mapping table before migration                                   |
|  * Test each platform type thoroughly                                      |
|  * Document custom configurations                                          |
|                                                                            |
|  --------------------------------------------------------------------------|
|                                                                            |
|  CHALLENGE 2: PSM vs Proxy Behavior Differences                            |
|  ==============================================                            |
|                                                                            |
|  Problem: User experience differs between PSM and proxy                    |
|                                                                            |
|  Solution:                                                                 |
|  * User training on new connection methods                                 |
|  * Document new workflows                                                  |
|  * Highlight benefits (simpler, lighter)                                   |
|                                                                            |
|  --------------------------------------------------------------------------|
|                                                                            |
|  CHALLENGE 3: Recording Format Incompatibility                             |
|  =============================================                             |
|                                                                            |
|  Problem: Historical recordings can't be played in new system              |
|                                                                            |
|  Solution:                                                                 |
|  * Keep CyberArk recordings in archive                                     |
|  * Maintain read-only access to old system                                 |
|  * Document archive location for compliance                                |
|                                                                            |
|  --------------------------------------------------------------------------|
|                                                                            |
|  CHALLENGE 4: Password Rotation During Migration                           |
|  ===============================================                           |
|                                                                            |
|  Problem: Both systems might try to rotate same password                   |
|                                                                            |
|  Solution:                                                                 |
|  * Disable rotation in CyberArk for migrating accounts                     |
|  * Enable in WALLIX after migration                                        |
|  * Verify current password before enabling rotation                        |
|                                                                            |
|  --------------------------------------------------------------------------|
|                                                                            |
|  CHALLENGE 5: Integration Re-configuration                                 |
|  =========================================                                 |
|                                                                            |
|  Problem: Existing integrations (SIEM, ITSM) need reconfiguration          |
|                                                                            |
|  Solution:                                                                 |
|  * Inventory all integrations before migration                             |
|  * Plan reconfiguration for each                                           |
|  * Test integrations in parallel before cutover                            |
|                                                                            |
+============================================================================+
```

---

## Next Steps

Continue to [12 - Troubleshooting](../12-troubleshooting/README.md) for common issues and solutions.
