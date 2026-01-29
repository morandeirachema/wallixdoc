# Hands-On Labs

## Practice Environments for WALLIX PAM4OT

These labs provide safe environments to learn WALLIX without affecting production systems.

---

## Lab Environment Overview

```
+===============================================================================+
|                   LAB ARCHITECTURE                                           |
+===============================================================================+

                        +------------------+
                        |   Your Machine   |
                        |   (Lab Host)     |
                        +--------+---------+
                                 |
                    +------------+------------+
                    |                         |
           +--------v--------+       +--------v--------+
           |  Docker Network |       |  VM Network     |
           |  (Quick Labs)   |       |  (Full Labs)    |
           +-----------------+       +-----------------+
                    |                         |
      +-------------+-------------+           |
      |             |             |           |
+-----v-----+ +-----v-----+ +-----v-----+  +--v--+
| WALLIX    | | Linux     | | Windows   |  | OT  |
| Container | | Target    | | Target    |  | Sim |
+-----------+ +-----------+ +-----------+  +-----+

+===============================================================================+
```

---

## Quick Start: Docker Lab (30 minutes)

### Prerequisites

- Docker and Docker Compose installed
- 8GB RAM available
- 20GB disk space

### Lab 1: Basic WALLIX Setup

**docker-compose.yml:**
```yaml
version: '3.8'

services:
  wallix:
    image: wallix/bastion:latest  # Or use official image
    container_name: wallix-lab
    hostname: wallix.lab.local
    ports:
      - "8443:443"      # Web UI
      - "2222:22"       # SSH proxy
      - "33389:3389"    # RDP proxy
    environment:
      - WALLIX_ADMIN_PASSWORD=LabAdmin123!
      - WALLIX_DB_PASSWORD=DbPassword123!
    volumes:
      - wallix-data:/var/lib/wallix
      - wallix-logs:/var/log/wallix
    networks:
      - lab-network
    depends_on:
      - postgres

  postgres:
    image: postgres:15
    container_name: wallix-db
    environment:
      - POSTGRES_DB=wallix
      - POSTGRES_USER=wallix
      - POSTGRES_PASSWORD=DbPassword123!
    volumes:
      - postgres-data:/var/lib/postgresql/data
    networks:
      - lab-network

  # Linux target for SSH labs
  linux-target:
    image: ubuntu:22.04
    container_name: linux-target
    hostname: linux-srv.lab.local
    command: >
      bash -c "apt-get update &&
               apt-get install -y openssh-server &&
               echo 'root:TargetPass123!' | chpasswd &&
               mkdir /run/sshd &&
               /usr/sbin/sshd -D"
    networks:
      - lab-network

  # Second Linux target
  linux-target2:
    image: ubuntu:22.04
    container_name: linux-target2
    hostname: linux-srv2.lab.local
    command: >
      bash -c "apt-get update &&
               apt-get install -y openssh-server &&
               echo 'root:TargetPass456!' | chpasswd &&
               mkdir /run/sshd &&
               /usr/sbin/sshd -D"
    networks:
      - lab-network

volumes:
  wallix-data:
  wallix-logs:
  postgres-data:

networks:
  lab-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.28.0.0/16
```

**Start the lab:**
```bash
# Start all containers
docker-compose up -d

# Wait for WALLIX to initialize (2-3 minutes)
sleep 180

# Check status
docker-compose ps

# Access WALLIX Web UI
# https://localhost:8443
# Username: admin
# Password: LabAdmin123!
```

---

## Lab Exercises

### Exercise 1: First Login and Navigation (15 min)

**Objective**: Familiarize with WALLIX web interface

**Steps**:
1. Open https://localhost:8443 in browser
2. Login as admin
3. Navigate to each section:
   - Audit > Sessions
   - Audit > Logs
   - Configuration > Domains
   - Configuration > Devices
   - Configuration > Users
   - Monitoring > Dashboard

**Checkpoint**: Can you find where to add a new device?

---

### Exercise 2: Add Your First Device (20 min)

**Objective**: Configure a Linux target in WALLIX

**Steps**:
1. Create a Domain:
   ```
   Configuration > Domains > Add
   - Name: Lab-Servers
   - Description: Lab environment servers
   ```

2. Create a Device:
   ```
   Configuration > Devices > Add
   - Name: linux-srv
   - Host: linux-target (Docker hostname)
   - Domain: Lab-Servers
   - Description: Lab Linux server
   ```

3. Add SSH Service:
   ```
   Configuration > Devices > linux-srv > Services > Add
   - Type: SSH
   - Port: 22
   ```

4. Add Account:
   ```
   Configuration > Devices > linux-srv > Accounts > Add
   - Account: root
   - Credentials: Password
   - Password: TargetPass123!
   ```

**Checkpoint**: Device shows green status?

---

### Exercise 3: Create User and Authorization (20 min)

**Objective**: Set up access control

**Steps**:
1. Create User Group:
   ```
   Configuration > User Groups > Add
   - Name: Lab-Admins
   - Description: Lab administrators
   ```

2. Create Test User:
   ```
   Configuration > Users > Add
   - Username: labuser
   - Password: LabUser123!
   - User Group: Lab-Admins
   ```

3. Create Target Group:
   ```
   Configuration > Target Groups > Add
   - Name: Lab-Linux-Root
   - Add Account: root@linux-srv
   ```

4. Create Authorization:
   ```
   Configuration > Authorizations > Add
   - Name: lab-admins-linux
   - User Group: Lab-Admins
   - Target Group: Lab-Linux-Root
   - Subprotocols: SSH Shell, SCP, SFTP
   - Recording: Enabled
   ```

**Checkpoint**: Authorization shows in list?

---

### Exercise 4: Launch Your First Session (15 min)

**Objective**: Connect through WALLIX and verify recording

**Steps**:
1. Logout from admin
2. Login as labuser (LabUser123!)
3. Go to "My Authorizations" or session launcher
4. Select linux-srv / root
5. Launch SSH session
6. Run some commands:
   ```bash
   whoami
   hostname
   cat /etc/os-release
   ls -la /
   exit
   ```

**Checkpoint**: Session appears in Audit > Sessions?

---

### Exercise 5: View Session Recording (10 min)

**Objective**: Review recorded session

**Steps**:
1. Login as admin
2. Go to Audit > Sessions
3. Find the session you just created
4. Click to view recording
5. Use playback controls:
   - Play/Pause
   - Speed adjustment
   - Jump to timestamp
6. Search for "whoami" in the recording

**Checkpoint**: Can you see the commands you typed?

---

## Lab 2: Password Management (45 min)

### Setup

Ensure Lab 1 is running and configured.

### Exercise 6: Configure Password Rotation

**Objective**: Set up automatic password rotation

**Steps**:
1. Edit account settings:
   ```
   Configuration > Accounts > root@linux-srv > Edit
   - Auto-rotation: Enabled
   - Rotation period: 1 day (for lab testing)
   - Password policy: Default
   ```

2. Trigger manual rotation:
   ```bash
   # Via CLI (if available)
   wabadmin account rotate root@linux-srv

   # Or via Web UI
   Configuration > Accounts > root@linux-srv > Rotate Now
   ```

3. Verify rotation:
   ```
   Configuration > Accounts > root@linux-srv
   - Check "Last Rotation" timestamp
   - Check "Next Rotation" timestamp
   ```

**Checkpoint**: Password rotated successfully?

---

### Exercise 7: Password Checkout

**Objective**: Retrieve password for out-of-band access

**Steps**:
1. Login as labuser
2. Go to My Authorizations
3. Find root@linux-srv
4. Click "Checkout Password"
5. Provide reason: "Testing checkout feature"
6. View the password (note: this would be logged)
7. Verify checkout appears in audit log

**Checkpoint**: Audit log shows password checkout event?

---

## Lab 3: OT Protocol Simulation (60 min)

### Add Modbus Simulator

**Update docker-compose.yml** (add this service):
```yaml
  modbus-sim:
    image: oitc/modbus-server
    container_name: modbus-plc
    hostname: plc-sim.lab.local
    ports:
      - "5020:5020"
    environment:
      - MODBUS_SERVER_PORT=5020
    networks:
      - lab-network
```

### Exercise 8: Configure OT Access

**Objective**: Access Modbus device through WALLIX

**Steps**:
1. Create OT Domain:
   ```
   Configuration > Domains > Add
   - Name: OT-Devices
   - Description: Industrial control systems
   ```

2. Add Modbus Device:
   ```
   Configuration > Devices > Add
   - Name: plc-line1
   - Host: modbus-plc
   - Domain: OT-Devices
   - Description: Production line PLC
   ```

3. Configure Universal Tunneling:
   ```
   Configuration > Devices > plc-line1 > Services > Add
   - Type: SSH (for tunneling)
   - Tunneling: Enabled
   - Tunnel target: localhost:5020
   ```

4. Create OT authorization:
   ```
   Configuration > Authorizations > Add
   - Name: ot-engineers-plc
   - User Group: Lab-Admins
   - Target Group: (create OT-PLCs group)
   - Recording: Enabled
   - Approval Required: Yes (optional)
   ```

**Checkpoint**: Can connect to PLC through WALLIX tunnel?

---

## Lab 4: Failure Scenarios (45 min)

### Exercise 9: Database Failure Recovery

**Objective**: Understand recovery from DB failure

**Steps**:
1. Note current active sessions count
2. Stop database container:
   ```bash
   docker stop wallix-db
   ```
3. Observe WALLIX behavior:
   - Can you login to web UI?
   - What error messages appear?
4. Restart database:
   ```bash
   docker start wallix-db
   ```
5. Verify recovery:
   - Login successful?
   - Data intact?

**Checkpoint**: Understand impact of DB failure?

---

### Exercise 10: Target Unreachable

**Objective**: Diagnose connection failures

**Steps**:
1. Stop a target:
   ```bash
   docker stop linux-target
   ```
2. Try to launch session to linux-srv
3. Note error message
4. Check device status in WALLIX
5. Restart target:
   ```bash
   docker start linux-target
   ```
6. Verify connectivity restored

**Checkpoint**: Understand how to diagnose target issues?

---

## Lab 5: API Automation (30 min)

### Exercise 11: Create Device via API

**Objective**: Automate device creation

**Script** (save as `create-device.py`):
```python
#!/usr/bin/env python3
import requests
import urllib3
urllib3.disable_warnings()

WALLIX_URL = "https://localhost:8443"
API_KEY = "your-api-key"  # Create in Web UI first

headers = {
    "X-Auth-Token": API_KEY,
    "Content-Type": "application/json"
}

# Create device
device = {
    "device_name": "api-created-server",
    "host": "linux-target2",
    "domain": "Lab-Servers",
    "description": "Created via API"
}

response = requests.post(
    f"{WALLIX_URL}/api/devices",
    headers=headers,
    json=device,
    verify=False
)

print(f"Status: {response.status_code}")
print(f"Response: {response.json()}")
```

**Steps**:
1. Create API key in Web UI:
   ```
   Configuration > API Keys > Add
   - Name: lab-automation
   - Permissions: devices:read, devices:write
   ```
2. Copy the API key
3. Update script with API key
4. Run script:
   ```bash
   python3 create-device.py
   ```
5. Verify device created in Web UI

**Checkpoint**: Device appears in Configuration > Devices?

---

## Lab Cleanup

```bash
# Stop all containers
docker-compose down

# Remove volumes (deletes all data)
docker-compose down -v

# Remove images (optional)
docker rmi wallix/bastion:latest
```

---

## Troubleshooting Labs

### Container won't start

```bash
# Check logs
docker-compose logs wallix

# Check resource usage
docker stats

# Verify ports not in use
ss -tuln | grep -E "(8443|2222|33389)"
```

### Can't access web UI

```bash
# Verify container running
docker ps | grep wallix

# Check container logs
docker logs wallix-lab

# Try direct container IP
docker inspect wallix-lab | grep IPAddress
```

### Session won't connect

```bash
# Verify target is reachable from WALLIX container
docker exec wallix-lab ping linux-target

# Check SSH on target
docker exec linux-target service ssh status

# Check WALLIX proxy logs
docker exec wallix-lab tail -f /var/log/wallix/session-proxy.log
```

---

## Next Steps

After completing these labs:

1. **Production Deployment**: [Install Guide](../../install/README.md)
2. **Advanced Configuration**: [Configuration Guide](../../docs/04-configuration/README.md)
3. **OT Deployment**: [OT Architecture](../../docs/16-ot-architecture/README.md)

---

<p align="center">
  <a href="../../docs/00-quick-start/README.md">Quick Start</a> •
  <a href="../../install/README.md">Installation</a> •
  <a href="../../docs/12-troubleshooting/README.md">Troubleshooting</a>
</p>
