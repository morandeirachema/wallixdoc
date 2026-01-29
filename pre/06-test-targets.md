# 06 - Test Targets Setup

## Configuring Target Systems for PAM4OT Testing

This guide covers setting up test target VMs for validating PAM4OT functionality.

---

## Target VM Summary

| Target | IP | OS | Protocol | Account |
|--------|----|----|----------|---------|
| linux-test | 10.10.2.10 | Ubuntu 22.04 | SSH | root |
| windows-test | 10.10.2.20 | Windows Server 2022 | RDP | Administrator |
| network-test | 10.10.2.30 | VyOS | SSH | vyos |
| plc-sim | 10.10.3.10 | Ubuntu + OpenPLC | Modbus/SSH | root |

---

## Linux Test Server (SSH Target)

### Installation

```bash
# On linux-test VM (10.10.2.10)

# Set hostname
hostnamectl set-hostname linux-test.lab.local

# Configure network
cat > /etc/netplan/00-installer-config.yaml << 'EOF'
network:
  version: 2
  ethernets:
    ens192:
      addresses: [10.10.2.10/24]
      routes:
        - to: default
          via: 10.10.2.1
      nameservers:
        addresses: [10.10.1.10]
        search: [lab.local]
EOF
netplan apply

# Enable root SSH login (for lab only!)
sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
systemctl restart sshd

# Set root password
echo "root:LinuxRoot123!" | chpasswd

# Create additional test accounts
useradd -m -s /bin/bash appuser
echo "appuser:AppUser123!" | chpasswd

useradd -m -s /bin/bash dbadmin
echo "dbadmin:DbAdmin123!" | chpasswd
```

### Add to PAM4OT

```
Configuration > Domains > Add
- Name: IT-Test-Servers
- Type: Local

Configuration > Devices > Add
- Name: linux-test
- Host: 10.10.2.10
- Domain: IT-Test-Servers
- Description: Linux SSH test target

Configuration > Devices > linux-test > Services > Add
- Type: SSH
- Port: 22
- Subprotocols: Shell, SCP, SFTP

Configuration > Devices > linux-test > Accounts > Add
- Account: root
- Password: LinuxRoot123!
- Auto-rotate: Enabled (weekly)

- Account: appuser
- Password: AppUser123!
```

---

## Windows Test Server (RDP Target)

### Installation

```powershell
# On windows-test VM (10.10.2.20)

# Set hostname
Rename-Computer -NewName "windows-test" -Restart

# Configure network
New-NetIPAddress -InterfaceAlias "Ethernet0" -IPAddress 10.10.2.20 -PrefixLength 24 -DefaultGateway 10.10.2.1
Set-DnsClientServerAddress -InterfaceAlias "Ethernet0" -ServerAddresses 10.10.1.10

# Enable RDP
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

# Enable NLA (Network Level Authentication)
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "UserAuthentication" -Value 1

# Join domain (optional)
# Add-Computer -DomainName "lab.local" -Credential (Get-Credential)

# Create local test users
$Password = ConvertTo-SecureString "LocalAdmin123!" -AsPlainText -Force
New-LocalUser -Name "localadmin" -Password $Password -FullName "Local Admin"
Add-LocalGroupMember -Group "Administrators" -Member "localadmin"
```

### Add to PAM4OT

```
Configuration > Devices > Add
- Name: windows-test
- Host: 10.10.2.20
- Domain: IT-Test-Servers
- Description: Windows RDP test target

Configuration > Devices > windows-test > Services > Add
- Type: RDP
- Port: 3389
- NLA: Enabled

Configuration > Devices > windows-test > Accounts > Add
- Account: Administrator
- Password: WinAdmin123!
- Auto-rotate: Enabled

- Account: localadmin
- Password: LocalAdmin123!
```

---

## Network Device (VyOS)

### Installation

```bash
# Install VyOS from ISO, then configure:

configure

# Set hostname
set system host-name network-test

# Configure management interface
set interfaces ethernet eth0 address 10.10.2.30/24
set protocols static route 0.0.0.0/0 next-hop 10.10.2.1
set system name-server 10.10.1.10

# Enable SSH
set service ssh port 22

# Create admin user
set system login user vyos authentication plaintext-password VyosAdmin123!
set system login user netadmin authentication plaintext-password NetAdmin123!
set system login user netadmin level admin

commit
save
```

### Add to PAM4OT

```
Configuration > Domains > Add
- Name: Network-Devices
- Type: Local

Configuration > Devices > Add
- Name: network-test
- Host: 10.10.2.30
- Domain: Network-Devices
- Description: VyOS network device test

Configuration > Devices > network-test > Services > Add
- Type: SSH
- Port: 22

Configuration > Devices > network-test > Accounts > Add
- Account: vyos
- Password: VyosAdmin123!

- Account: netadmin
- Password: NetAdmin123!
```

---

## PLC Simulator (OT Target)

### Installation with OpenPLC

```bash
# On plc-sim VM (10.10.3.10)

# Set hostname
hostnamectl set-hostname plc-sim.lab.local

# Configure network (OT VLAN)
cat > /etc/netplan/00-installer-config.yaml << 'EOF'
network:
  version: 2
  ethernets:
    ens192:
      addresses: [10.10.3.10/24]
      routes:
        - to: default
          via: 10.10.3.1
      nameservers:
        addresses: [10.10.1.10]
        search: [lab.local]
EOF
netplan apply

# Install OpenPLC Runtime
apt update && apt install -y git build-essential python3 python3-pip

git clone https://github.com/thiagoralves/OpenPLC_v3.git
cd OpenPLC_v3
./install.sh linux

# Start OpenPLC
./start_openplc.sh &

# OpenPLC runs on:
# - Web UI: http://10.10.3.10:8080 (admin/openplc)
# - Modbus: TCP port 502
```

### Install Modbus Simulator (Alternative)

```bash
# Simple Modbus simulator
pip3 install pymodbus

# Create simulator script
cat > /opt/modbus_sim.py << 'EOF'
#!/usr/bin/env python3
from pymodbus.server import StartTcpServer
from pymodbus.datastore import ModbusSequentialDataBlock, ModbusSlaveContext, ModbusServerContext

# Create data store
store = ModbusSlaveContext(
    di=ModbusSequentialDataBlock(0, [0]*100),
    co=ModbusSequentialDataBlock(0, [0]*100),
    hr=ModbusSequentialDataBlock(0, [0]*100),
    ir=ModbusSequentialDataBlock(0, [0]*100)
)
context = ModbusServerContext(slaves=store, single=True)

# Start server
print("Starting Modbus server on port 502...")
StartTcpServer(context=context, address=("0.0.0.0", 502))
EOF

chmod +x /opt/modbus_sim.py

# Run as service
cat > /etc/systemd/system/modbus-sim.service << 'EOF'
[Unit]
Description=Modbus Simulator
After=network.target

[Service]
ExecStart=/usr/bin/python3 /opt/modbus_sim.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl enable modbus-sim
systemctl start modbus-sim
```

### Add to PAM4OT

```
Configuration > Domains > Add
- Name: OT-Devices
- Type: Local

Configuration > Devices > Add
- Name: plc-sim
- Host: 10.10.3.10
- Domain: OT-Devices
- Description: PLC Simulator (Modbus)

# SSH access for maintenance
Configuration > Devices > plc-sim > Services > Add
- Type: SSH
- Port: 22

# Modbus access via tunneling
Configuration > Devices > plc-sim > Services > Add
- Type: SSH Tunnel
- Local Port: 502
- Remote Port: 502
- Description: Modbus TCP

Configuration > Devices > plc-sim > Accounts > Add
- Account: root
- Password: PlcRoot123!
```

---

## Create Authorizations

### Target Groups

```
Configuration > Target Groups > Add

1. Linux-Root-Access
   - linux-test / root
   - linux-test / appuser

2. Windows-Admin-Access
   - windows-test / Administrator
   - windows-test / localadmin

3. Network-Admin-Access
   - network-test / vyos
   - network-test / netadmin

4. OT-PLC-Access
   - plc-sim / root
```

### Authorizations

```
Configuration > Authorizations > Add

1. Auth: Linux-Admins-Access
   - User Group: LDAP-Linux-Admins
   - Target Group: Linux-Root-Access
   - Recording: Enabled
   - Approval: Not required

2. Auth: Windows-Admins-Access
   - User Group: LDAP-Windows-Admins
   - Target Group: Windows-Admin-Access
   - Recording: Enabled
   - OCR: Enabled

3. Auth: Network-Team-Access
   - User Group: LDAP-Network-Admins
   - Target Group: Network-Admin-Access
   - Recording: Enabled

4. Auth: OT-Engineers-PLC
   - User Group: LDAP-OT-Engineers
   - Target Group: OT-PLC-Access
   - Recording: Enabled
   - Approval: Required (for lab, make optional)
```

---

## Test Connectivity

```bash
# From PAM4OT node, verify all targets reachable

echo "=== Linux Test ==="
nc -zv 10.10.2.10 22

echo "=== Windows Test ==="
nc -zv 10.10.2.20 3389

echo "=== Network Test ==="
nc -zv 10.10.2.30 22

echo "=== PLC Sim ==="
nc -zv 10.10.3.10 22
nc -zv 10.10.3.10 502
```

---

## Test Sessions

### SSH Session Test

```bash
# Login as AD user via PAM4OT
ssh jadmin@pam4ot.lab.local

# Select linux-test / root
# Run commands:
whoami
hostname
uname -a
exit
```

### RDP Session Test

1. Open browser to `https://pam4ot.lab.local`
2. Login as `jadmin`
3. Select windows-test / Administrator
4. Launch HTML5 RDP session
5. Verify Windows desktop appears
6. Run `whoami` in Command Prompt

### Modbus Test

```bash
# Install modbus client
pip3 install pymodbus

# Test Modbus through PAM4OT tunnel
# First establish SSH session with tunnel
ssh -L 502:10.10.3.10:502 jadmin@pam4ot.lab.local

# Then use modbus client to localhost:502
python3 -c "
from pymodbus.client import ModbusTcpClient
client = ModbusTcpClient('localhost', port=502)
client.connect()
result = client.read_holding_registers(0, 10)
print(result.registers)
"
```

---

## Target Checklist

| Target | Reachable | Added to PAM4OT | Authorization | Session Test |
|--------|-----------|-----------------|---------------|--------------|
| linux-test | [ ] | [ ] | [ ] | [ ] |
| windows-test | [ ] | [ ] | [ ] | [ ] |
| network-test | [ ] | [ ] | [ ] | [ ] |
| plc-sim | [ ] | [ ] | [ ] | [ ] |

---

<p align="center">
  <a href="./05-ad-integration.md">← Previous</a> •
  <a href="./07-siem-integration.md">Next: SIEM Integration →</a>
</p>
