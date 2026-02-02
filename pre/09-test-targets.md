# 06 - OT Test Targets Setup

## Configuring Industrial Systems for PAM4OT Testing

This guide covers setting up realistic OT/Industrial test targets including PLCs, RTUs, HMIs, SCADA systems, and industrial protocol simulators.

---

## OT Simulator Overview

All industrial protocols can be simulated on standard Linux VMs using open-source software. No specialized hardware is required for the lab.

```
+===============================================================================+
|  OT SIMULATION ARCHITECTURE                                                   |
+===============================================================================+
|                                                                               |
|  SINGLE LINUX VM CAN SIMULATE MULTIPLE PROTOCOLS:                             |
|                                                                               |
|  +-------------------------------------------------------------------------+  |
|  |  ot-sim-1 (Ubuntu 22.04)                                     10.10.4.10 |  |
|  |                                                                         |  |
|  |  +------------------+  +------------------+  +------------------+       |  |
|  |  | Modbus TCP:502   |  | S7comm:102       |  | OPC UA:4840      |       |  |
|  |  | (pymodbus)       |  | (snap7)          |  | (node-opcua)     |       |  |
|  |  +------------------+  +------------------+  +------------------+       |  |
|  |                                                                         |  |
|  |  +------------------+  +------------------+  +------------------+       |  |
|  |  | DNP3:20000       |  | EtherNet/IP:44818|  | IEC 61850:102    |       |  |
|  |  | (opendnp3)       |  | (pycomm3)        |  | (libiec61850)    |       |  |
|  |  +------------------+  +------------------+  +------------------+       |  |
|  |                                                                         |  |
|  +-------------------------------------------------------------------------+  |
|                                                                               |
+===============================================================================+
```

---

## Target Summary by Purdue Level

### Level 1 - Basic Control (PLCs/RTUs)

| Target | IP | Protocol | Simulator | Port |
|--------|-----|----------|-----------|------|
| plc-modbus | 10.10.4.10 | Modbus TCP | pymodbus | 502 |
| plc-s7 | 10.10.4.11 | S7comm | snap7 | 102 |
| rtu-dnp3-1 | 10.10.4.20 | DNP3 | opendnp3 | 20000 |
| rtu-dnp3-2 | 10.10.4.21 | DNP3 | opendnp3 | 20000 |
| plc-ethernetip | 10.10.4.30 | EtherNet/IP | pycomm3 | 44818 |

### Level 2 - Area Supervisory (HMIs/OPC)

| Target | IP | Protocol | Purpose | Port |
|--------|-----|----------|---------|------|
| hmi-panel-1 | 10.10.3.10 | RDP/VNC | Operator HMI | 3389 |
| hmi-panel-2 | 10.10.3.11 | RDP/VNC | Operator HMI | 3389 |
| opcua-server | 10.10.3.20 | OPC UA | Data aggregation | 4840 |

### Level 3 - Site Operations (SCADA/Engineering)

| Target | IP | Protocol | Purpose | Port |
|--------|-----|----------|---------|------|
| scada-server | 10.10.2.10 | RDP | SCADA (Ignition) | 3389 |
| eng-workstation | 10.10.2.20 | RDP | Engineering WS | 3389 |
| linux-jump | 10.10.2.40 | SSH | Jump server | 22 |

---

## Level 1: PLC/RTU Simulators

### Option A: All-in-One OT Simulator VM

Create a single Linux VM that runs all industrial protocols:

```bash
# On ot-sim-all VM (10.10.4.10)

# Base setup
hostnamectl set-hostname ot-sim-all.lab.local

cat > /etc/netplan/00-config.yaml << 'EOF'
network:
  version: 2
  ethernets:
    ens192:
      addresses: [10.10.4.10/24]
      routes:
        - to: default
          via: 10.10.4.1
      nameservers:
        addresses: [10.10.0.10]
        search: [lab.local]
EOF
netplan apply

# Install dependencies
apt update && apt install -y \
    python3 python3-pip python3-venv \
    build-essential cmake git \
    nodejs npm \
    openjdk-11-jre-headless

# Create virtual environment for Python simulators
python3 -m venv /opt/ot-sim
source /opt/ot-sim/bin/activate

# Install Python simulators
pip install pymodbus pycomm3 opcua
```

### Modbus TCP PLC Simulator (Port 502)

```bash
# Create Modbus simulator with realistic PLC data

cat > /opt/ot-sim/modbus_plc.py << 'EOF'
#!/usr/bin/env python3
"""
Modbus TCP PLC Simulator
Simulates a PLC with realistic industrial data
"""
import asyncio
import random
from pymodbus.server import StartAsyncTcpServer
from pymodbus.datastore import (
    ModbusSequentialDataBlock,
    ModbusSlaveContext,
    ModbusServerContext,
)

# Simulate realistic PLC registers
# Holding Registers (40001-40100): Setpoints, control values
# Input Registers (30001-30100): Sensor readings
# Coils (00001-00100): Digital outputs
# Discrete Inputs (10001-10100): Digital inputs

def create_plc_context():
    # Initialize with realistic values
    holding_registers = [0] * 100
    holding_registers[0] = 750   # Temperature setpoint (75.0°C)
    holding_registers[1] = 500   # Pressure setpoint (50.0 bar)
    holding_registers[2] = 1000  # Flow setpoint (100.0 L/min)
    holding_registers[3] = 1     # Mode (1=Auto, 0=Manual)

    input_registers = [0] * 100
    input_registers[0] = 745    # Actual temperature (74.5°C)
    input_registers[1] = 498    # Actual pressure (49.8 bar)
    input_registers[2] = 1005   # Actual flow (100.5 L/min)
    input_registers[3] = 0      # Alarm status

    coils = [0] * 100
    coils[0] = 1  # Pump 1 running
    coils[1] = 0  # Pump 2 stopped
    coils[2] = 1  # Valve 1 open
    coils[3] = 0  # Valve 2 closed

    discrete_inputs = [0] * 100
    discrete_inputs[0] = 1  # Emergency stop OK
    discrete_inputs[1] = 1  # Safety interlock OK
    discrete_inputs[2] = 0  # High level alarm
    discrete_inputs[3] = 0  # Low level alarm

    store = ModbusSlaveContext(
        di=ModbusSequentialDataBlock(0, discrete_inputs),
        co=ModbusSequentialDataBlock(0, coils),
        hr=ModbusSequentialDataBlock(0, holding_registers),
        ir=ModbusSequentialDataBlock(0, input_registers),
    )
    return ModbusServerContext(slaves=store, single=True)

async def update_values(context):
    """Simulate changing sensor values"""
    while True:
        # Get the slave context
        slave = context[0]

        # Simulate temperature fluctuation (±0.5°C)
        temp = slave.getValues(4, 0, 1)[0]  # Input register 0
        temp = temp + random.randint(-5, 5)
        temp = max(700, min(800, temp))  # Clamp to 70-80°C
        slave.setValues(4, 0, [temp])

        # Simulate pressure fluctuation (±0.2 bar)
        pressure = slave.getValues(4, 1, 1)[0]
        pressure = pressure + random.randint(-2, 2)
        pressure = max(480, min(520, pressure))
        slave.setValues(4, 1, [pressure])

        await asyncio.sleep(1)

async def run_server():
    context = create_plc_context()

    # Start value updater
    asyncio.create_task(update_values(context))

    print("Starting Modbus TCP PLC Simulator on port 502...")
    print("  Holding Registers: 40001-40100 (Setpoints)")
    print("  Input Registers: 30001-30100 (Sensors)")
    print("  Coils: 00001-00100 (Outputs)")
    print("  Discrete Inputs: 10001-10100 (Inputs)")

    await StartAsyncTcpServer(
        context=context,
        address=("0.0.0.0", 502),
    )

if __name__ == "__main__":
    asyncio.run(run_server())
EOF

chmod +x /opt/ot-sim/modbus_plc.py

# Create systemd service
cat > /etc/systemd/system/modbus-plc.service << 'EOF'
[Unit]
Description=Modbus TCP PLC Simulator
After=network.target

[Service]
Type=simple
ExecStart=/opt/ot-sim/bin/python /opt/ot-sim/modbus_plc.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable modbus-plc
systemctl start modbus-plc
```

### DNP3 RTU Simulator (Port 20000)

```bash
# Install OpenDNP3
apt install -y libboost-all-dev

git clone https://github.com/dnp3/opendnp3.git /opt/opendnp3
cd /opt/opendnp3
mkdir build && cd build
cmake .. -DDNP3_EXAMPLES=ON
make -j4

# Create DNP3 outstation simulator
cat > /opt/ot-sim/dnp3_rtu.py << 'EOF'
#!/usr/bin/env python3
"""
DNP3 Outstation (RTU) Simulator
Simulates a remote terminal unit for SCADA
"""
from pydnp3 import opendnp3, openpal, asiopal, asiodnp3

# Configuration
LISTEN_IP = "0.0.0.0"
LISTEN_PORT = 20000
LOCAL_ADDR = 10    # Outstation address
REMOTE_ADDR = 1    # Master address

class OutstationApplication(opendnp3.IOutstationApplication):
    def __init__(self):
        super(OutstationApplication, self).__init__()

    def SupportsWriteAbsoluteTime(self):
        return False

    def SupportsWriteTimeAndInterval(self):
        return False

    def SupportsAssignClass(self):
        return False

def main():
    print(f"Starting DNP3 RTU Simulator on port {LISTEN_PORT}...")
    print(f"  Local Address: {LOCAL_ADDR}")
    print(f"  Remote Address: {REMOTE_ADDR}")

    # Create manager
    manager = asiodnp3.DNP3Manager(1)

    # Create channel
    channel = manager.AddTCPServer(
        "server",
        opendnp3.levels.NORMAL,
        opendnp3.ServerAcceptMode.CloseNew,
        LISTEN_IP,
        LISTEN_PORT
    )

    # Outstation config
    config = asiodnp3.OutstationStackConfig(
        opendnp3.DatabaseSizes.AllTypes(10)
    )
    config.outstation.eventBufferConfig = opendnp3.EventBufferConfig.AllTypes(10)
    config.outstation.params.allowUnsolicited = True
    config.link.LocalAddr = LOCAL_ADDR
    config.link.RemoteAddr = REMOTE_ADDR

    # Create outstation
    outstation = channel.AddOutstation(
        "outstation",
        opendnp3.SuccessCommandHandler().Create(),
        OutstationApplication(),
        config
    )

    outstation.Enable()

    print("DNP3 RTU running. Press Ctrl+C to stop.")

    try:
        while True:
            import time
            time.sleep(1)
    except KeyboardInterrupt:
        print("Shutting down...")
    finally:
        manager.Shutdown()

if __name__ == "__main__":
    main()
EOF
```

### S7comm PLC Simulator (Port 102)

```bash
# Install Snap7 library
apt install -y libsnap7-1 libsnap7-dev

pip install python-snap7

# Create S7 PLC simulator
cat > /opt/ot-sim/s7_plc.py << 'EOF'
#!/usr/bin/env python3
"""
S7comm PLC Simulator (Siemens S7-300/400/1200/1500)
"""
import snap7
from snap7.server import Server
import struct
import threading
import time

# Data areas
DB1_SIZE = 256  # Data Block 1 size

class S7PLCServer:
    def __init__(self):
        self.server = Server()
        self.running = False

        # Initialize data block with realistic values
        self.db1 = bytearray(DB1_SIZE)

        # DB1.DBW0 - Temperature (INT) - 750 = 75.0°C
        struct.pack_into('>h', self.db1, 0, 750)
        # DB1.DBW2 - Pressure (INT) - 500 = 50.0 bar
        struct.pack_into('>h', self.db1, 2, 500)
        # DB1.DBW4 - Flow (INT) - 1000 = 100.0 L/min
        struct.pack_into('>h', self.db1, 4, 1000)
        # DB1.DBX10.0 - Pump running (BOOL)
        self.db1[10] = 0x01

        # Register data block
        self.server.register_area(snap7.types.srvAreaDB, 1, self.db1)

    def start(self):
        print("Starting S7comm PLC Simulator on port 102...")
        print("  CPU: S7-1200 simulation")
        print("  Data Block: DB1 (256 bytes)")

        self.server.start(tcpport=102)
        self.running = True

        # Start value update thread
        self.update_thread = threading.Thread(target=self._update_values)
        self.update_thread.start()

    def _update_values(self):
        """Simulate changing process values"""
        import random
        while self.running:
            # Simulate temperature fluctuation
            temp = struct.unpack_from('>h', self.db1, 0)[0]
            temp += random.randint(-5, 5)
            temp = max(700, min(800, temp))
            struct.pack_into('>h', self.db1, 0, temp)

            time.sleep(1)

    def stop(self):
        self.running = False
        self.server.stop()

if __name__ == "__main__":
    server = S7PLCServer()
    server.start()

    print("S7 PLC running. Press Ctrl+C to stop.")
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        server.stop()
EOF

# Create systemd service
cat > /etc/systemd/system/s7-plc.service << 'EOF'
[Unit]
Description=S7comm PLC Simulator
After=network.target

[Service]
Type=simple
ExecStart=/opt/ot-sim/bin/python /opt/ot-sim/s7_plc.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

### OPC UA Server (Port 4840)

```bash
# Install node-opcua
cd /opt
npm install node-opcua

# Create OPC UA server
cat > /opt/ot-sim/opcua_server.js << 'EOF'
const { OPCUAServer, Variant, DataType, StatusCodes } = require("node-opcua");

async function main() {
    const server = new OPCUAServer({
        port: 4840,
        resourcePath: "/UA/OTServer",
        buildInfo: {
            productName: "OT Lab OPC UA Server",
            buildNumber: "1",
            buildDate: new Date()
        }
    });

    await server.initialize();

    const addressSpace = server.engine.addressSpace;
    const namespace = addressSpace.getOwnNamespace();

    // Create Process folder
    const processFolder = namespace.addFolder(addressSpace.rootFolder.objects, {
        browseName: "Process"
    });

    // Add variables
    let temperature = 75.0;
    let pressure = 50.0;
    let flowRate = 100.0;

    namespace.addVariable({
        componentOf: processFolder,
        browseName: "Temperature",
        dataType: "Double",
        value: {
            get: () => new Variant({ dataType: DataType.Double, value: temperature })
        }
    });

    namespace.addVariable({
        componentOf: processFolder,
        browseName: "Pressure",
        dataType: "Double",
        value: {
            get: () => new Variant({ dataType: DataType.Double, value: pressure })
        }
    });

    namespace.addVariable({
        componentOf: processFolder,
        browseName: "FlowRate",
        dataType: "Double",
        value: {
            get: () => new Variant({ dataType: DataType.Double, value: flowRate })
        }
    });

    // Simulate value changes
    setInterval(() => {
        temperature = 75.0 + (Math.random() - 0.5) * 2;
        pressure = 50.0 + (Math.random() - 0.5) * 1;
        flowRate = 100.0 + (Math.random() - 0.5) * 5;
    }, 1000);

    await server.start();

    console.log("OPC UA Server started on port 4840");
    console.log("  Endpoint: opc.tcp://0.0.0.0:4840/UA/OTServer");
    console.log("  Variables: Process/Temperature, Pressure, FlowRate");
}

main();
EOF

# Create systemd service
cat > /etc/systemd/system/opcua-server.service << 'EOF'
[Unit]
Description=OPC UA Server
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt
ExecStart=/usr/bin/node /opt/ot-sim/opcua_server.js
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

---

## Level 2: HMI Panels

### Windows 10 IoT HMI Simulator

```powershell
# On hmi-panel-1 VM (10.10.3.10)

# Set hostname
Rename-Computer -NewName "hmi-panel-1" -Restart

# Configure network
New-NetIPAddress -InterfaceAlias "Ethernet0" -IPAddress 10.10.3.10 -PrefixLength 24 -DefaultGateway 10.10.3.1
Set-DnsClientServerAddress -InterfaceAlias "Ethernet0" -ServerAddresses 10.10.0.10

# Enable RDP
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

# Create operator account
$Password = ConvertTo-SecureString "Operator123!" -AsPlainText -Force
New-LocalUser -Name "operator" -Password $Password -FullName "HMI Operator"
Add-LocalGroupMember -Group "Users" -Member "operator"

# Install web-based HMI (using ScadaBR or Ignition Edge)
# Option 1: ScadaBR (Java-based)
# Download from: https://github.com/ScadaBR/ScadaBR

# Option 2: Use simple HTML5 HMI
mkdir C:\HMI
# Copy HMI files or use Ignition Edge
```

### Add HMIs to PAM4OT

```
Configuration > Domains > Add
- Name: OT-HMI-Panels
- Type: Local

Configuration > Devices > Add
- Name: hmi-panel-1
- Host: 10.10.3.10
- Domain: OT-HMI-Panels
- Description: Operator HMI Panel 1

Configuration > Devices > hmi-panel-1 > Services > Add
- Type: RDP
- Port: 3389

Configuration > Devices > hmi-panel-1 > Accounts > Add
- Account: operator
- Password: Operator123!
- Checkout: Enabled (operators check out access)
```

---

## Level 3: SCADA and Engineering

### SCADA Server (Ignition)

```powershell
# On scada-server VM (10.10.2.10)

# Download Ignition SCADA
# https://inductiveautomation.com/downloads/ignition

# Install Ignition (follow GUI installer)
# Default port: 8088 (HTTP), 8043 (HTTPS)

# Configure OPC UA connections to PLCs
# Gateway > Config > OPC-UA > Connections > Add
# - PLC Modbus: opc.tcp://10.10.4.10:4840
# - PLC S7: Add Siemens driver

# Create operator account for PAM4OT
$Password = ConvertTo-SecureString "ScadaAdmin123!" -AsPlainText -Force
New-LocalUser -Name "scada-admin" -Password $Password -FullName "SCADA Admin"
Add-LocalGroupMember -Group "Administrators" -Member "scada-admin"
```

### Engineering Workstation

```powershell
# On eng-workstation VM (10.10.2.20)

# This simulates an engineering workstation with:
# - TIA Portal (Siemens PLC programming)
# - Studio 5000 (Allen-Bradley programming)
# - FactoryTalk (Rockwell)

# For lab, install client tools:
# - Modbus Poll (Modbus testing)
# - UA Expert (OPC UA client)
# - Wireshark (protocol analysis)

# Create engineering accounts
$Password = ConvertTo-SecureString "Engineer123!" -AsPlainText -Force
New-LocalUser -Name "control-engineer" -Password $Password -FullName "Control Engineer"
Add-LocalGroupMember -Group "Administrators" -Member "control-engineer"

$Password2 = ConvertTo-SecureString "PLCProg123!" -AsPlainText -Force
New-LocalUser -Name "plc-programmer" -Password $Password2 -FullName "PLC Programmer"
Add-LocalGroupMember -Group "Administrators" -Member "plc-programmer"
```

---

## Adding OT Targets to PAM4OT

### Create OT Domains

```
Configuration > Domains > Add

1. OT-Control-Systems (Level 1)
   - Type: Local
   - Description: PLCs, RTUs, Controllers

2. OT-Supervisory (Level 2)
   - Type: Local
   - Description: HMIs, OPC Servers

3. OT-Operations (Level 3)
   - Type: Local
   - Description: SCADA, Engineering WS
```

### Create Devices

```
# Level 1 - PLCs/RTUs
Configuration > Devices > Add

Device: plc-modbus
- Host: 10.10.4.10
- Domain: OT-Control-Systems
- Services:
  - SSH (port 22) - Maintenance access
  - SSH Tunnel to 502 - Modbus TCP
- Accounts: root / PlcRoot123!

Device: plc-s7
- Host: 10.10.4.11
- Domain: OT-Control-Systems
- Services:
  - SSH (port 22)
  - SSH Tunnel to 102 - S7comm
- Accounts: root / S7Root123!

Device: rtu-dnp3-1
- Host: 10.10.4.20
- Domain: OT-Control-Systems
- Services:
  - SSH (port 22)
  - SSH Tunnel to 20000 - DNP3
- Accounts: root / RtuRoot123!

# Level 2 - HMIs
Device: hmi-panel-1
- Host: 10.10.3.10
- Domain: OT-Supervisory
- Services: RDP (3389)
- Accounts: operator / Operator123!

Device: opcua-server
- Host: 10.10.3.20
- Domain: OT-Supervisory
- Services:
  - SSH (port 22)
  - SSH Tunnel to 4840 - OPC UA
- Accounts: root / OpcRoot123!

# Level 3 - SCADA
Device: scada-server
- Host: 10.10.2.10
- Domain: OT-Operations
- Services: RDP (3389)
- Accounts: scada-admin / ScadaAdmin123!

Device: eng-workstation
- Host: 10.10.2.20
- Domain: OT-Operations
- Services: RDP (3389)
- Accounts:
  - control-engineer / Engineer123!
  - plc-programmer / PLCProg123!
```

### Create OT Authorizations

```
# IEC 62443 Role-Based Access

Authorization: OT-Operator-HMI
- User Group: LDAP-OT-Operators
- Target Group: HMI-Panels
- Recording: Enabled
- Time Restriction: Shift hours only

Authorization: OT-Engineer-Full
- User Group: LDAP-OT-Engineers
- Target Group: All-OT-Devices
- Recording: Enabled
- Approval: Required for Level 1 devices

Authorization: Vendor-Maintenance
- User Group: LDAP-Vendors
- Target Group: Specific-PLC (vendor's equipment only)
- Recording: Enabled
- Time Limit: 4 hours
- Approval: Required
```

---

## Testing Industrial Protocols

### Modbus TCP Test

```bash
# Install modbus client
pip3 install pymodbus

# Test Modbus through PAM4OT
cat > /tmp/test_modbus.py << 'EOF'
from pymodbus.client import ModbusTcpClient

# Connect through PAM4OT tunnel
client = ModbusTcpClient('localhost', port=502)
client.connect()

# Read holding registers (setpoints)
result = client.read_holding_registers(0, 10)
print(f"Setpoints: {result.registers}")

# Read input registers (sensors)
result = client.read_input_registers(0, 10)
print(f"Sensors: {result.registers}")

# Read coils (digital outputs)
result = client.read_coils(0, 10)
print(f"Outputs: {result.bits}")

client.close()
EOF

# First establish PAM4OT session with tunnel
ssh -L 502:10.10.4.10:502 engineer@pam4ot.lab.local

# Then run test
python3 /tmp/test_modbus.py
```

### S7comm Test

```bash
pip3 install python-snap7

cat > /tmp/test_s7.py << 'EOF'
import snap7

# Connect through PAM4OT tunnel
client = snap7.client.Client()
client.connect('localhost', 0, 1)  # Rack 0, Slot 1

# Read DB1
data = client.db_read(1, 0, 10)
print(f"DB1 data: {data.hex()}")

# Read temperature (DB1.DBW0)
import struct
temp = struct.unpack('>h', data[0:2])[0] / 10.0
print(f"Temperature: {temp}°C")

client.disconnect()
EOF
```

### OPC UA Test

```bash
pip3 install opcua

cat > /tmp/test_opcua.py << 'EOF'
from opcua import Client

# Connect through PAM4OT tunnel
client = Client("opc.tcp://localhost:4840/UA/OTServer")
client.connect()

# Browse root
root = client.get_root_node()
print(f"Root: {root}")

# Read process variables
process = client.get_node("ns=2;s=Process")
for child in process.get_children():
    print(f"  {child.get_browse_name()}: {child.get_value()}")

client.disconnect()
EOF
```

---

## OT Target Checklist

| Target | Installed | Simulator Running | PAM4OT Config | Authorization | Test |
|--------|-----------|-------------------|---------------|---------------|------|
| plc-modbus | [ ] | [ ] | [ ] | [ ] | [ ] |
| plc-s7 | [ ] | [ ] | [ ] | [ ] | [ ] |
| rtu-dnp3-1 | [ ] | [ ] | [ ] | [ ] | [ ] |
| opcua-server | [ ] | [ ] | [ ] | [ ] | [ ] |
| hmi-panel-1 | [ ] | [ ] | [ ] | [ ] | [ ] |
| scada-server | [ ] | [ ] | [ ] | [ ] | [ ] |
| eng-workstation | [ ] | [ ] | [ ] | [ ] | [ ] |

---

## Quick Reference: OT Simulator Ports

| Protocol | Port | Simulator | Test Command |
|----------|------|-----------|--------------|
| Modbus TCP | 502 | pymodbus | `modbus_client -m tcp -t 3 -r 0 -c 10 IP` |
| S7comm | 102 | snap7 | `python3 -c "import snap7; ..."` |
| DNP3 | 20000 | opendnp3 | `dnp3_client IP 20000` |
| OPC UA | 4840 | node-opcua | `opcua-client opc.tcp://IP:4840` |
| EtherNet/IP | 44818 | pycomm3 | `python3 -c "from pycomm3 import ..."` |

---

<p align="center">
  <a href="./08-ha-active-active.md">← Previous: HA Active-Active Configuration</a> •
  <a href="./10-siem-integration.md">Next: SIEM Integration →</a>
</p>
