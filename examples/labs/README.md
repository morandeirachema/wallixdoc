# Hands-On Labs

## Practice Environments for WALLIX Bastion

These labs provide safe environments to learn WALLIX without affecting production systems.

> **Note**: These labs use virtual machines to match production deployment patterns. For the full pre-production lab environment, see [pre/README.md](../../pre/README.md).

---

## Lab Environment Overview

```
+===============================================================================+
|                   LAB ARCHITECTURE                                            |
+===============================================================================+
|                                                                               |
|                          +------------------+                                 |
|                          |   Your Machine   |                                 |
|                          |   (Lab Host)     |                                 |
|                          +--------+---------+                                 |
|                                   |                                           |
|                          +--------v--------+                                  |
|                          |   Hypervisor    |                                  |
|                          |  (VMware/Hyper-V|                                  |
|                          |   /Proxmox/KVM) |                                  |
|                          +-----------------+                                  |
|                                   |                                           |
|                    +--------------+--------------+                            |
|                    |              |              |                            |
|              +-----v-----+  +-----v-----+  +-----v-----+                      |
|              |  WALLIX   |  |  Linux    |  |  Windows  |                      |
|              |  Bastion  |  |  Target   |  |  Target   |                      |
|              |  VM       |  |  VM       |  |  VM       |                      |
|              +-----------+  +-----------+  +-----------+                      |
|                                                                               |
|  Network: 10.10.1.0/24 (Lab Network)                                          |
|                                                                               |
+===============================================================================+
```

---

## Prerequisites

### Hardware Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **CPU** | 8 cores | 16+ cores |
| **RAM** | 16 GB | 32 GB |
| **Storage** | 100 GB SSD | 200 GB SSD |

### Software Requirements

- **Hypervisor**: VMware Workstation/ESXi, Hyper-V, Proxmox VE, or KVM
- **ISO Images**: Debian 12, Windows Server 2019/2022 (optional)
- **Network**: Ability to create isolated virtual networks

---

## Quick Start: VM Lab Setup (60 minutes)

### Step 1: Create Lab Network

Create an isolated virtual network for your lab:

| Setting | Value |
|---------|-------|
| **Network Name** | Lab-Network |
| **Subnet** | 10.10.1.0/24 |
| **Gateway** | 10.10.1.1 |
| **DHCP** | Disabled |

### Step 2: Create WALLIX Bastion VM

**VM Configuration:**

| Setting | Value |
|---------|-------|
| **Name** | wallix-lab |
| **OS** | Debian 12 (Bookworm) |
| **vCPU** | 4 |
| **RAM** | 8 GB |
| **Disk** | 50 GB |
| **Network** | Lab-Network |
| **IP Address** | 10.10.1.10 |

**Installation:**

```bash
# After Debian installation, install WALLIX Bastion
# Follow the official deployment guide:
# https://marketplace-wallix.s3.amazonaws.com/bastion_12.0.2_en_deployment_guide.pdf

# Set hostname
hostnamectl set-hostname wallix-lab.lab.local

# Configure static IP
cat > /etc/network/interfaces << 'EOF'
auto lo
iface lo inet loopback

auto ens192
iface ens192 inet static
    address 10.10.1.10/24
    gateway 10.10.1.1
    dns-nameservers 8.8.8.8
    dns-search lab.local
EOF

systemctl restart networking

# Install WALLIX Bastion (requires valid license)
# Contact WALLIX for evaluation licenses
```

### Step 3: Create Linux Target VM

**VM Configuration:**

| Setting | Value |
|---------|-------|
| **Name** | linux-target |
| **OS** | Debian 12 or Ubuntu 22.04 |
| **vCPU** | 2 |
| **RAM** | 2 GB |
| **Disk** | 20 GB |
| **Network** | Lab-Network |
| **IP Address** | 10.10.1.20 |

**Configuration:**

```bash
# Set hostname
hostnamectl set-hostname linux-target.lab.local

# Configure static IP
cat > /etc/network/interfaces << 'EOF'
auto lo
iface lo inet loopback

auto ens192
iface ens192 inet static
    address 10.10.1.20/24
    gateway 10.10.1.1
    dns-search lab.local
EOF

systemctl restart networking

# Ensure SSH is installed and running
apt update && apt install -y openssh-server
systemctl enable ssh
systemctl start ssh

# Create test user
useradd -m -s /bin/bash testuser
echo 'testuser:TestPass123!' | chpasswd

# Allow root login (for lab only - not recommended for production)
echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
echo 'root:RootPass123!' | chpasswd
systemctl restart ssh
```

### Step 4: Update /etc/hosts

On all VMs, add:

```bash
cat >> /etc/hosts << 'EOF'
10.10.1.10  wallix-lab.lab.local wallix-lab
10.10.1.20  linux-target.lab.local linux-target
10.10.1.21  linux-target2.lab.local linux-target2
10.10.1.30  win-target.lab.local win-target
EOF
```

---

## Lab Exercises

### Exercise 1: First Login and Navigation (15 min)

**Objective**: Familiarize with WALLIX web interface

**Steps**:
1. Open https://10.10.1.10 in browser
2. Login as admin (use configured admin password)
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
   - Host: 10.10.1.20
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
   - Password: RootPass123!
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
   # Via CLI on WALLIX Bastion
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

For OT protocol labs, use the pre-production lab environment which includes protocol simulators:

- **Modbus TCP Simulator** - See [pre/06-test-targets.md](../../pre/06-test-targets.md)
- **OPC UA Server** - See [pre/06-test-targets.md](../../pre/06-test-targets.md)
- **S7comm Simulator** - See [pre/06-test-targets.md](../../pre/06-test-targets.md)

### Quick Modbus Setup (Single VM)

If you want to add Modbus simulation to this basic lab:

**On a new VM (OT-Simulator, 10.10.1.40):**

```bash
# Install Python and pymodbus
apt update && apt install -y python3 python3-pip
pip3 install pymodbus

# Create Modbus server script
cat > /opt/modbus_server.py << 'EOF'
#!/usr/bin/env python3
"""Simple Modbus TCP Server for Lab Testing"""
from pymodbus.server import StartTcpServer
from pymodbus.datastore import ModbusSequentialDataBlock, ModbusSlaveContext, ModbusServerContext

# Initialize data stores
store = ModbusSlaveContext(
    di=ModbusSequentialDataBlock(0, [0]*100),   # Discrete Inputs
    co=ModbusSequentialDataBlock(0, [0]*100),   # Coils
    hr=ModbusSequentialDataBlock(0, [0]*100),   # Holding Registers
    ir=ModbusSequentialDataBlock(0, [0]*100)    # Input Registers
)
context = ModbusServerContext(slaves=store, single=True)

print("Starting Modbus TCP Server on port 502...")
StartTcpServer(context=context, address=("0.0.0.0", 502))
EOF

chmod +x /opt/modbus_server.py

# Create systemd service
cat > /etc/systemd/system/modbus-sim.service << 'EOF'
[Unit]
Description=Modbus TCP Simulator
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /opt/modbus_server.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable modbus-sim
systemctl start modbus-sim
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
   - Host: 10.10.1.40
   - Domain: OT-Devices
   - Description: Production line PLC
   ```

3. Configure Universal Tunneling:
   ```
   Configuration > Devices > plc-line1 > Services > Add
   - Type: SSH (for tunneling)
   - Tunneling: Enabled
   - Tunnel target: localhost:502
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

### Exercise 9: Service Failure Recovery

**Objective**: Understand recovery from service failure

**Steps**:
1. Note current active sessions count
2. Stop WALLIX service:
   ```bash
   # On WALLIX Bastion VM
   systemctl stop wallix-bastion
   ```
3. Observe behavior:
   - Can you login to web UI?
   - What happens to active sessions?
4. Restart service:
   ```bash
   systemctl start wallix-bastion
   ```
5. Verify recovery:
   - Login successful?
   - Service status healthy?

**Checkpoint**: Understand impact of service failure?

---

### Exercise 10: Target Unreachable

**Objective**: Diagnose connection failures

**Steps**:
1. Shutdown target VM:
   ```bash
   # On linux-target VM
   shutdown -h now
   ```
2. Try to launch session to linux-srv
3. Note error message
4. Check device status in WALLIX
5. Start target VM
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

WALLIX_URL = "https://10.10.1.10"
API_KEY = "your-api-key"  # Create in Web UI first

headers = {
    "X-Auth-Token": API_KEY,
    "Content-Type": "application/json"
}

# Create device
device = {
    "device_name": "api-created-server",
    "host": "10.10.1.21",
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
# On each VM, you can shutdown gracefully
shutdown -h now

# Or delete VMs from hypervisor
# VMware: Right-click > Delete from Disk
# Hyper-V: Remove-VM -Name "vm-name" -Force
# Proxmox: qm destroy <vmid>
```

---

## Troubleshooting Labs

### VM won't start

```bash
# Check hypervisor logs
# VMware: /var/log/vmware/
# Hyper-V: Get-WinEvent -LogName "Microsoft-Windows-Hyper-V*"

# Verify resources available
free -h
df -h
```

### Can't access web UI

```bash
# On WALLIX Bastion VM
systemctl status wallix-bastion

# Check network connectivity
ping 10.10.1.10

# Verify HTTPS is listening
ss -tuln | grep 443

# Check logs
journalctl -u wallix-bastion -n 50
```

### Session won't connect

```bash
# Verify target is reachable from WALLIX
# On WALLIX Bastion VM:
ping 10.10.1.20

# Check SSH on target
# On linux-target VM:
systemctl status ssh
ss -tuln | grep 22

# Check WALLIX proxy logs
tail -f /var/log/wallix/session-proxy.log
```

---

## Pre-Production Lab

For a complete pre-production environment matching real OT deployments, see:

| Guide | Description |
|-------|-------------|
| [pre/README.md](../../pre/README.md) | Full architecture with 22 VMs |
| [pre/06-test-targets.md](../../pre/06-test-targets.md) | OT protocol simulators |
| [pre/11-battery-tests.md](../../pre/11-battery-tests.md) | 48 comprehensive tests |

---

## Next Steps

After completing these labs:

1. **Production Deployment**: [Install Guide](../../install/README.md)
2. **Advanced Configuration**: [Configuration Guide](../../docs/05-configuration/README.md)
3. **OT Deployment**: [OT Architecture](../../docs/16-ot-architecture/README.md)

---

## Official Resources

| Resource | URL |
|----------|-----|
| **Deployment Guide** | https://marketplace-wallix.s3.amazonaws.com/bastion_12.0.2_en_deployment_guide.pdf |
| **Administration Guide** | https://pam.wallix.one/documentation/admin-doc/bastion_en_administration_guide.pdf |
| **REST API Samples** | https://github.com/wallix/wbrest_samples |

---

<p align="center">
  <a href="../../docs/01-quick-start/README.md">Quick Start</a> •
  <a href="../../install/README.md">Installation</a> •
  <a href="../../docs/13-troubleshooting/README.md">Troubleshooting</a>
</p>
