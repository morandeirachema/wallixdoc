# Configuration Walkthroughs

## Step-by-Step Setup Procedures

These walkthroughs guide you through common configuration tasks with screenshots descriptions and CLI alternatives.

---

## Walkthrough 1: Add Your First Linux Server

**Goal**: Configure SSH access to a Linux server with password rotation

**Time**: 15 minutes

### Step 1: Create a Domain

```
+------------------------------------------------------------------------------+
| PATH: Configuration > Domains > Add Domain                                    |
+------------------------------------------------------------------------------+
|                                                                               |
| Domain Name:     [Linux-Production    ]                                       |
|                                                                               |
| Domain Type:     (x) Local Domain                                             |
|                  ( ) Global Domain                                            |
|                                                                               |
| Description:     [Production Linux servers              ]                     |
|                                                                               |
|                              [Cancel]  [Create Domain]                        |
+------------------------------------------------------------------------------+
```

**CLI Alternative:**
```bash
# Using WALLIX REST API
curl -X POST "https://bastion/api/domains" \
  -H "X-Auth-Token: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "domain_name": "Linux-Production",
    "domain_real_name": "Linux-Production",
    "description": "Production Linux servers"
  }'
```

### Step 2: Add the Device

```
+------------------------------------------------------------------------------+
| PATH: Configuration > Devices > Add Device                                    |
+------------------------------------------------------------------------------+
|                                                                               |
| Device Name:     [srv-web-01          ]                                       |
|                                                                               |
| Host:            [10.1.10.10          ]    [Test Connectivity]               |
|                                                                               |
| Domain:          [Linux-Production ▼  ]                                       |
|                                                                               |
| Description:     [Production web server                 ]                     |
|                                                                               |
| Alias:           [web1                ]  (optional short name)               |
|                                                                               |
|                              [Cancel]  [Create Device]                        |
+------------------------------------------------------------------------------+
```

**CLI Alternative:**
```bash
curl -X POST "https://bastion/api/devices" \
  -H "X-Auth-Token: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "device_name": "srv-web-01",
    "host": "10.1.10.10",
    "domain": "Linux-Production",
    "description": "Production web server",
    "alias": "web1"
  }'
```

### Step 3: Add SSH Service

```
+------------------------------------------------------------------------------+
| PATH: Configuration > Devices > srv-web-01 > Services > Add Service           |
+------------------------------------------------------------------------------+
|                                                                               |
| Service Type:    [SSH ▼               ]                                       |
|                                                                               |
| Port:            [22                  ]    (default: 22)                      |
|                                                                               |
| Connection Policy: [Standard ▼        ]                                       |
|                                                                               |
| Subprotocols:    [x] SSH Shell                                               |
|                  [x] SCP                                                      |
|                  [x] SFTP                                                     |
|                  [ ] X11 Forwarding                                          |
|                  [ ] Remote Commands                                         |
|                                                                               |
|                              [Cancel]  [Add Service]                          |
+------------------------------------------------------------------------------+
```

### Step 4: Add Root Account

```
+------------------------------------------------------------------------------+
| PATH: Configuration > Devices > srv-web-01 > Accounts > Add Account           |
+------------------------------------------------------------------------------+
|                                                                               |
| Account Name:    [root                ]                                       |
|                                                                               |
| Credential Type: (x) Password                                                |
|                  ( ) SSH Key                                                 |
|                  ( ) Certificate                                             |
|                                                                               |
| Password:        [********************]    [Generate]                        |
|                                                                               |
| ─── Password Rotation ────────────────────────────────────────────           |
|                                                                               |
| Auto-Rotate:     [x] Enable automatic rotation                               |
|                                                                               |
| Rotation Period: [Weekly ▼            ]                                       |
|                                                                               |
| Password Policy: [Linux-Strong ▼      ]                                       |
|                  - Length: 16+                                                |
|                  - Special chars: Required                                    |
|                  - Numbers: Required                                          |
|                                                                               |
| ─── Checkout Settings ────────────────────────────────────────────           |
|                                                                               |
| Allow Checkout:  [ ] Enable password checkout                                |
|                                                                               |
|                              [Cancel]  [Add Account]                          |
+------------------------------------------------------------------------------+
```

### Step 5: Create User Group

```
+------------------------------------------------------------------------------+
| PATH: Configuration > User Groups > Add User Group                            |
+------------------------------------------------------------------------------+
|                                                                               |
| Group Name:      [Linux-Admins        ]                                       |
|                                                                               |
| Description:     [Administrators with root access       ]                     |
|                                                                               |
| ─── Members ──────────────────────────────────────────────────────           |
|                                                                               |
| Available Users:              | Selected Users:                              |
| +-------------------+         | +-------------------+                        |
| | jsmith            | [>>]    | | admin             |                        |
| | mwilson           |         | |                   |                        |
| | bthompson         |         | |                   |                        |
| +-------------------+         | +-------------------+                        |
|                                                                               |
|                              [Cancel]  [Create Group]                         |
+------------------------------------------------------------------------------+
```

### Step 6: Create Target Group

```
+------------------------------------------------------------------------------+
| PATH: Configuration > Target Groups > Add Target Group                        |
+------------------------------------------------------------------------------+
|                                                                               |
| Group Name:      [Linux-Prod-Root     ]                                       |
|                                                                               |
| Description:     [Root accounts on production Linux     ]                     |
|                                                                               |
| ─── Accounts ─────────────────────────────────────────────────────           |
|                                                                               |
| Available Accounts:           | Selected Accounts:                           |
| +-------------------+         | +-------------------+                        |
| | srv-db-01/root    | [>>]    | | srv-web-01/root   |                        |
| | srv-app-01/root   |         | |                   |                        |
| | srv-app-02/root   |         | |                   |                        |
| +-------------------+         | +-------------------+                        |
|                                                                               |
|                              [Cancel]  [Create Group]                         |
+------------------------------------------------------------------------------+
```

### Step 7: Create Authorization

```
+------------------------------------------------------------------------------+
| PATH: Configuration > Authorizations > Add Authorization                      |
+------------------------------------------------------------------------------+
|                                                                               |
| Authorization Name: [Linux-Admins-Root ]                                      |
|                                                                               |
| User Group:      [Linux-Admins ▼      ]                                       |
| Target Group:    [Linux-Prod-Root ▼   ]                                       |
|                                                                               |
| ─── Session Settings ─────────────────────────────────────────────           |
|                                                                               |
| Recording:       [x] Record all sessions                                     |
| Keystroke Log:   [x] Log all keystrokes                                      |
|                                                                               |
| ─── Approval Workflow ────────────────────────────────────────────           |
|                                                                               |
| Require Approval: [ ] Require approval before access                          |
|                                                                               |
| ─── Time Restrictions ────────────────────────────────────────────           |
|                                                                               |
| Time Restriction: [ ] Limit access to specific times                          |
|                                                                               |
|                              [Cancel]  [Create Authorization]                 |
+------------------------------------------------------------------------------+
```

### Step 8: Test the Connection

```
1. Log out of admin interface
2. Log in as a user in Linux-Admins group
3. Click "My Targets" or "Authorizations"
4. Select srv-web-01 / root
5. Click Connect
6. Verify SSH session opens
7. Run: whoami (should return "root")
8. Run: exit
9. Verify session appears in Audit > Sessions > History
```

---

## Walkthrough 2: Configure Windows RDP Access

**Goal**: Set up RDP access with NLA and credential injection

**Time**: 20 minutes

### Step 1: Create Windows Domain

```
Configuration > Domains > Add
- Name: Windows-Production
- Type: Local Domain
- Description: Windows production servers
```

### Step 2: Add Windows Server

```
Configuration > Devices > Add
- Name: srv-dc-01
- Host: 10.1.20.10
- Domain: Windows-Production
- Description: Domain Controller
```

### Step 3: Add RDP Service

```
+------------------------------------------------------------------------------+
| PATH: Configuration > Devices > srv-dc-01 > Services > Add Service            |
+------------------------------------------------------------------------------+
|                                                                               |
| Service Type:    [RDP ▼               ]                                       |
|                                                                               |
| Port:            [3389                ]                                       |
|                                                                               |
| ─── RDP Settings ─────────────────────────────────────────────────           |
|                                                                               |
| Network Level Auth: [x] Enable NLA (recommended)                             |
|                                                                               |
| TLS Mode:        [TLS 1.2+ ▼          ]                                       |
|                                                                               |
| Subprotocols:    [x] Drive Mapping                                           |
|                  [x] Clipboard                                               |
|                  [ ] Printer Redirection                                     |
|                  [ ] USB Redirection                                         |
|                  [ ] Smart Card                                              |
|                                                                               |
|                              [Cancel]  [Add Service]                          |
+------------------------------------------------------------------------------+
```

### Step 4: Add Domain Administrator Account

```
+------------------------------------------------------------------------------+
| Account Configuration for Domain Account                                      |
+------------------------------------------------------------------------------+
|                                                                               |
| Account Name:    [administrator       ]                                       |
|                                                                               |
| Domain Account:  [x] This is a domain account                                |
|                                                                               |
| AD Domain:       [CORP                ]                                       |
| (NetBIOS or FQDN: CORP or corp.company.com)                                  |
|                                                                               |
| Credential Type: (x) Password                                                |
|                                                                               |
| Password:        [********************]                                       |
|                                                                               |
| ─── Password Rotation ────────────────────────────────────────────           |
|                                                                               |
| Auto-Rotate:     [x] Enable                                                  |
| Rotation Period: [30 days ▼           ]                                       |
| Target Type:     [Windows AD ▼        ]                                       |
|                                                                               |
| ─── Credential Injection ─────────────────────────────────────────           |
|                                                                               |
| Auto-Logon:      [x] Inject credentials automatically                        |
| Show Password:   [ ] Allow user to see password                              |
|                                                                               |
+------------------------------------------------------------------------------+
```

### Step 5: Configure Authorization with Recording

```
Authorization Settings:
- Recording: Enabled
- OCR Indexing: Enabled (allows searching RDP sessions for text)
- Screenshot Interval: 5 seconds
```

---

## Walkthrough 3: Bulk Device Import via CSV

**Goal**: Import 50+ devices from spreadsheet

**Time**: 30 minutes

### Step 1: Prepare CSV File

```csv
device_name,host,domain,description,services,accounts
srv-web-01,10.1.10.10,Linux-Production,Web server 1,SSH:22,root
srv-web-02,10.1.10.11,Linux-Production,Web server 2,SSH:22,root
srv-db-01,10.1.10.20,Linux-Production,Database server,SSH:22,root:postgres
srv-app-01,10.1.10.30,Linux-Production,App server 1,SSH:22,root:appuser
srv-app-02,10.1.10.31,Linux-Production,App server 2,SSH:22,root:appuser
win-srv-01,10.1.20.10,Windows-Production,Windows server,RDP:3389,administrator
win-srv-02,10.1.20.11,Windows-Production,Windows server,RDP:3389,administrator
```

### Step 2: Import via API Script

```python
#!/usr/bin/env python3
"""
bulk_import.py - Import devices from CSV into WALLIX PAM4OT
"""

import csv
import requests
import urllib3
urllib3.disable_warnings()

WALLIX_URL = "https://bastion.company.com"
API_KEY = "your-api-key"

headers = {
    "X-Auth-Token": API_KEY,
    "Content-Type": "application/json"
}

def create_domain(domain_name):
    """Create domain if it doesn't exist"""
    response = requests.get(
        f"{WALLIX_URL}/api/domains/{domain_name}",
        headers=headers,
        verify=False
    )
    if response.status_code == 404:
        data = {
            "domain_name": domain_name,
            "domain_real_name": domain_name
        }
        requests.post(
            f"{WALLIX_URL}/api/domains",
            headers=headers,
            json=data,
            verify=False
        )
        print(f"Created domain: {domain_name}")

def create_device(device_data):
    """Create device with services and accounts"""

    # Create device
    device = {
        "device_name": device_data["device_name"],
        "host": device_data["host"],
        "domain": device_data["domain"],
        "description": device_data["description"]
    }

    response = requests.post(
        f"{WALLIX_URL}/api/devices",
        headers=headers,
        json=device,
        verify=False
    )

    if response.status_code not in [200, 201]:
        print(f"Failed to create device {device_data['device_name']}: {response.text}")
        return

    print(f"Created device: {device_data['device_name']}")

    # Add services
    for service_def in device_data["services"].split(":"):
        if ":" in device_data["services"]:
            parts = device_data["services"].split(":")
            service_type = parts[0]
            port = int(parts[1])
        else:
            service_type = "SSH"
            port = 22

        service = {
            "service_name": service_type.lower(),
            "protocol": service_type.upper(),
            "port": port
        }

        requests.post(
            f"{WALLIX_URL}/api/devices/{device_data['device_name']}/services",
            headers=headers,
            json=service,
            verify=False
        )

    # Add accounts
    for account_name in device_data["accounts"].split(":"):
        account = {
            "account_name": account_name,
            "credentials": [{"type": "password", "password": "ChangeMeNow123!"}],
            "auto_change_password": True
        }

        requests.post(
            f"{WALLIX_URL}/api/devices/{device_data['device_name']}/accounts",
            headers=headers,
            json=account,
            verify=False
        )

def main():
    # Read CSV
    with open("devices.csv", "r") as f:
        reader = csv.DictReader(f)
        devices = list(reader)

    # Create domains first
    domains = set(d["domain"] for d in devices)
    for domain in domains:
        create_domain(domain)

    # Create devices
    for device in devices:
        create_device(device)

    print(f"\nImported {len(devices)} devices")

if __name__ == "__main__":
    main()
```

### Step 3: Run Import

```bash
# Install dependencies
pip install requests

# Edit the script with your API key
nano bulk_import.py

# Run import
python3 bulk_import.py

# Verify in WALLIX
# Configuration > Devices should show all imported devices
```

### Step 4: Post-Import Tasks

```
After import, you still need to:

1. Set actual passwords for each account
   - Configuration > Accounts > [account] > Edit > Set Password

2. Test connectivity
   - Configuration > Devices > [device] > Test Connection

3. Trigger initial password rotation
   - Configuration > Accounts > [account] > Rotate Now

4. Create authorizations
   - Configuration > Authorizations > Add
```

---

## Walkthrough 4: Configure OT PLC Access with Tunneling

**Goal**: Enable engineering access to Siemens S7 PLC via TIA Portal

**Time**: 25 minutes

### Step 1: Create OT Domain

```
Configuration > Domains > Add
- Name: OT-Level1-PLCs
- Type: Local Domain
- Description: Level 1 PLCs and controllers
```

### Step 2: Add PLC Device

```
Configuration > Devices > Add
- Name: plc-line1-01
- Host: 192.168.50.10
- Domain: OT-Level1-PLCs
- Description: Assembly Line 1 Main PLC (S7-1500)
```

### Step 3: Configure SSH Tunneling for S7 Protocol

```
+------------------------------------------------------------------------------+
| Service Configuration: SSH Tunnel for S7comm                                  |
+------------------------------------------------------------------------------+
|                                                                               |
| Service Type:    [SSH ▼               ]                                       |
|                                                                               |
| Port:            [22                  ]                                       |
|                                                                               |
| ─── Tunneling Configuration ──────────────────────────────────────           |
|                                                                               |
| Enable Tunneling: [x] Allow port forwarding through this service             |
|                                                                               |
| Allowed Tunnels:                                                             |
|                                                                               |
| | Local Port | Remote Host    | Remote Port | Description       |           |
| |------------|----------------|-------------|-------------------|           |
| | 102        | 192.168.50.10  | 102         | S7comm Protocol   |           |
| | 4840       | 192.168.50.10  | 4840        | OPC UA (optional) |           |
|                                                                               |
|                              [+ Add Tunnel]                                   |
|                                                                               |
+------------------------------------------------------------------------------+
```

### Step 4: Add Engineering Account

```
Account Configuration:
- Name: plc-engineer
- Credentials: SSH Key (recommended for automation)
- Auto-Rotate: Disabled (PLC doesn't support rotation)
- Description: Engineering workstation account
```

### Step 5: Create OT Authorization with Approval

```
+------------------------------------------------------------------------------+
| Authorization: OT-Engineers-PLCs                                              |
+------------------------------------------------------------------------------+
|                                                                               |
| User Group:      [OT-Engineers ▼      ]                                       |
| Target Group:    [Level1-PLCs ▼       ]                                       |
|                                                                               |
| ─── Security Settings ────────────────────────────────────────────           |
|                                                                               |
| Recording:       [x] REQUIRED - All sessions recorded                        |
| Keystroke Log:   [x] Enabled                                                 |
|                                                                               |
| ─── Approval Workflow ────────────────────────────────────────────           |
|                                                                               |
| Require Approval: [x] Yes - Approval required for all access                  |
| Approvers:       [OT-Supervisors ▼    ]                                       |
|                                                                               |
| ─── 4-Eyes Control ───────────────────────────────────────────────           |
|                                                                               |
| 4-Eyes Required: [x] Supervisor must observe session                          |
| Supervisors:     [OT-Supervisors ▼    ]                                       |
|                                                                               |
| ─── Time Restrictions ────────────────────────────────────────────           |
|                                                                               |
| Maintenance Windows Only:                                                    |
| [x] Saturday 02:00 - 06:00                                                   |
| [x] Sunday 02:00 - 06:00                                                     |
|                                                                               |
| Or: Approved maintenance tickets                                             |
|                                                                               |
+------------------------------------------------------------------------------+
```

### Step 6: User Workflow

```
When engineer needs PLC access:

1. Log into WALLIX user portal
2. Select plc-line1-01 / plc-engineer
3. System shows "Approval Required"
4. Engineer fills request:
   - Reason: "Replace faulty sensor logic"
   - Ticket: CHG-2024-001234
   - Duration: 2 hours

5. OT Supervisor receives notification
6. Supervisor reviews and approves

7. Engineer launches session
8. WALLIX establishes SSH tunnel
9. Engineer opens TIA Portal
10. TIA Portal connects to localhost:102 (tunneled to PLC)
11. Session is recorded
12. 4-eyes supervisor can watch in real-time
```

---

## Walkthrough 5: LDAP/Active Directory Integration

**Goal**: Authenticate users via Active Directory

**Time**: 30 minutes

### Step 1: Gather AD Information

```
Required Information:
- Domain Controller: dc01.corp.company.com
- Port: 636 (LDAPS) or 389 (LDAP)
- Base DN: DC=corp,DC=company,DC=com
- Service Account: CN=wallix-svc,OU=Service Accounts,DC=corp,DC=company,DC=com
- Service Account Password: [secure password]
```

### Step 2: Configure LDAP Authentication

```
+------------------------------------------------------------------------------+
| PATH: Configuration > Authentication > LDAP > Add LDAP Source                 |
+------------------------------------------------------------------------------+
|                                                                               |
| Source Name:     [Corporate-AD        ]                                       |
|                                                                               |
| ─── Connection ───────────────────────────────────────────────────           |
|                                                                               |
| Host:            [dc01.corp.company.com                 ]                     |
| Port:            [636                 ]                                       |
| Use TLS:         [x] LDAPS (recommended)                                     |
| Certificate:     [x] Verify server certificate                               |
|                                                                               |
| ─── Bind Account ─────────────────────────────────────────────────           |
|                                                                               |
| Bind DN:         [CN=wallix-svc,OU=Service Accounts,DC=corp,DC=company,DC=com]|
| Bind Password:   [********************]                                       |
|                                                                               |
| ─── Search Configuration ─────────────────────────────────────────           |
|                                                                               |
| Base DN:         [DC=corp,DC=company,DC=com             ]                     |
| User Filter:     [(&(objectClass=user)(sAMAccountName=%s))  ]                 |
| Group Filter:    [(&(objectClass=group)(member=%s))         ]                 |
|                                                                               |
| ─── Attribute Mapping ────────────────────────────────────────────           |
|                                                                               |
| Username:        [sAMAccountName      ]                                       |
| Display Name:    [displayName         ]                                       |
| Email:           [mail                ]                                       |
| Groups:          [memberOf            ]                                       |
|                                                                               |
|                              [Test Connection]  [Save]                        |
+------------------------------------------------------------------------------+
```

### Step 3: Map AD Groups to WALLIX Groups

```
+------------------------------------------------------------------------------+
| Group Mapping Configuration                                                   |
+------------------------------------------------------------------------------+
|                                                                               |
| AD Group                          | WALLIX Group                             |
| ----------------------------------|------------------------------------------|
| CN=IT-Admins,OU=Groups,DC=...     | Linux-Admins                             |
| CN=Windows-Admins,OU=Groups,DC=...| Windows-Admins                           |
| CN=OT-Engineers,OU=Groups,DC=...  | OT-Engineers                             |
| CN=PAM-Admins,OU=Groups,DC=...    | WALLIX-Admins (full admin access)        |
|                                                                               |
+------------------------------------------------------------------------------+
```

### Step 4: Test Authentication

```bash
# Test LDAP connectivity from WALLIX
ldapsearch -x -H ldaps://dc01.corp.company.com:636 \
  -D "CN=wallix-svc,OU=Service Accounts,DC=corp,DC=company,DC=com" \
  -W \
  -b "DC=corp,DC=company,DC=com" \
  "(sAMAccountName=testuser)"

# Expected: User object with attributes
```

### Step 5: Verify User Login

```
1. User opens https://bastion.company.com
2. Enters AD username (e.g., jsmith)
3. Enters AD password
4. WALLIX queries AD to verify credentials
5. WALLIX checks AD group membership
6. User receives appropriate WALLIX group membership
7. User sees authorized targets
```

---

## Configuration Tips

### Naming Conventions

```
Recommended naming patterns:

Devices:
- srv-[function]-[number]     (srv-web-01, srv-db-02)
- [location]-[type]-[number]  (nyc-plc-01, chi-hmi-02)

Domains:
- [Environment]-[Type]        (Prod-Linux, Dev-Windows)
- [Location]-[Level]          (Plant-A-Level2, HQ-DMZ)

User Groups:
- [Team]-[Role]               (IT-Admins, OT-Engineers)
- [Function]-[Access]         (Database-ReadOnly, Network-Admin)

Target Groups:
- [Domain]-[Account]          (Linux-Prod-Root, Windows-Admin)
- [System]-[Role]             (Oracle-DBA, SAP-Basis)
```

### Common Mistakes to Avoid

| Mistake | Consequence | Fix |
|---------|-------------|-----|
| Forgetting to enable service | Sessions fail | Add service to device |
| Wrong port number | Connection timeout | Verify port with target admin |
| Missing authorization | "Access denied" | Create authorization linking user group to target group |
| Password policy mismatch | Rotation fails | Match policy to target requirements |
| NLA disabled on Windows | Security warning | Enable NLA on Windows target |

---

<p align="center">
  <a href="./README.md">Configuration Overview</a> •
  <a href="../00-quick-start/README.md">Quick Start</a> •
  <a href="../../examples/labs/README.md">Hands-On Labs</a>
</p>
