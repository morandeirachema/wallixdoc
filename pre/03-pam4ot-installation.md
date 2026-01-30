# 03 - PAM4OT Installation

## Base Installation on Both Nodes

This guide covers installing WALLIX PAM4OT on both cluster nodes before HA configuration.

---

## Prerequisites Checklist

Before starting, verify on **both nodes**:

- [ ] Debian 12 installed and updated
- [ ] Network configured (static IP)
- [ ] Hostname set correctly
- [ ] DNS resolution working
- [ ] NTP synchronized
- [ ] Can reach AD DC on port 636

```bash
# Quick verification
hostname -f                           # Should show FQDN
nslookup dc-lab.lab.local            # Should resolve
chronyc tracking                      # Should show synchronized
nc -zv dc-lab.lab.local 636          # Should succeed
```

---

## Step 1: System Preparation

### On Both Nodes

```bash
# Update system
apt update && apt upgrade -y

# Install required packages
apt install -y \
    curl wget gnupg2 ca-certificates \
    apt-transport-https lsb-release \
    software-properties-common \
    python3 python3-pip \
    openssl libssl-dev \
    mariadb-client \
    net-tools dnsutils \
    chrony ntp

# Configure system limits
cat >> /etc/security/limits.conf << 'EOF'
* soft nofile 65536
* hard nofile 65536
* soft nproc 65536
* hard nproc 65536
EOF

# Configure sysctl
cat >> /etc/sysctl.conf << 'EOF'
# PAM4OT optimizations
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.ip_local_port_range = 1024 65535
vm.swappiness = 10
EOF

sysctl -p
```

---

## Step 2: Prepare Data Disk

```bash
# List disks
lsblk

# Assuming /dev/sdb is the 150GB data disk
# Create partition
fdisk /dev/sdb << 'EOF'
n
p
1


w
EOF

# Create filesystem
mkfs.ext4 /dev/sdb1

# Create mount point and mount
mkdir -p /var/wab
echo '/dev/sdb1 /var/wab ext4 defaults 0 2' >> /etc/fstab
mount -a

# Verify
df -h /var/wab
```

---

## Step 3: Install PAM4OT Package

### Add WALLIX Repository

```bash
# Add WALLIX GPG key
curl -fsSL https://download.wallix.com/wallix.gpg | gpg --dearmor -o /usr/share/keyrings/wallix.gpg

# Add repository
echo "deb [signed-by=/usr/share/keyrings/wallix.gpg] https://download.wallix.com/debian stable main" > /etc/apt/sources.list.d/wallix.list

# Update package list
apt update
```

### Install PAM4OT

```bash
# Install WALLIX Bastion (PAM4OT base)
apt install -y wallix-bastion

# Or if using downloaded package:
# dpkg -i wallix-bastion_12.1.x_amd64.deb
# apt install -f  # Fix dependencies
```

---

## Step 4: Initial Configuration

### Run Setup Wizard

```bash
# Start initial configuration
wabadmin setup

# The wizard will prompt for:
# 1. Admin password (set to: Pam4otAdmin123!)
# 2. Database password (set to: PgAdmin123!)
# 3. Encryption key password (set a strong password, save it!)
# 4. License file (if available, or skip for trial)
```

### Manual Configuration (Alternative)

```bash
# If not using wizard, configure manually:

# Set admin password
wabadmin passwd admin Pam4otAdmin123!

# Initialize database
wabadmin db init --password PgAdmin123!

# Generate encryption keys
wabadmin keys generate

# Start services
systemctl enable wallix-bastion
systemctl start wallix-bastion
```

---

## Step 5: Configure SSL Certificate

### Option A: Self-Signed (Lab)

```bash
# Generate self-signed certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/opt/wab/ssl/server.key \
    -out /etc/opt/wab/ssl/server.crt \
    -subj "/C=US/ST=Lab/L=Lab/O=Lab/CN=pam4ot.lab.local" \
    -addext "subjectAltName=DNS:pam4ot.lab.local,DNS:pam4ot-node1.lab.local,DNS:pam4ot-node2.lab.local,IP:10.10.1.100,IP:10.10.1.11,IP:10.10.1.12"

# Set permissions
chmod 600 /etc/opt/wab/ssl/server.key
chmod 644 /etc/opt/wab/ssl/server.crt
chown wab:wab /etc/opt/wab/ssl/server.*

# Restart to apply
systemctl restart wallix-bastion
```

### Option B: Use Same Certificate on Both Nodes

```bash
# Generate on node1, then copy to node2
# On node1:
scp /etc/opt/wab/ssl/server.* root@pam4ot-node2:/etc/opt/wab/ssl/
```

---

## Step 6: Import AD CA Certificate

```bash
# Copy the CA certificate from AD DC
# (exported in previous step as lab-ca.pem)

# On PAM4OT nodes:
scp administrator@dc-lab.lab.local:/lab-ca.pem /tmp/

# Import to system trust store
cp /tmp/lab-ca.pem /usr/local/share/ca-certificates/lab-ca.crt
update-ca-certificates

# Verify
openssl s_client -connect dc-lab.lab.local:636 -CApath /etc/ssl/certs/
```

---

## Step 7: Basic Configuration File

```bash
# Main configuration file
cat > /etc/opt/wab/wabengine.conf << 'EOF'
[global]
# Hostname (will be updated for HA)
hostname = pam4ot-node1.lab.local

# Listen addresses
listen_address = 0.0.0.0
web_port = 443
ssh_port = 22
rdp_port = 3389

# Session settings
session_timeout = 3600
max_sessions = 100

# Recording
recording_enabled = true
recording_path = /var/wab/recorded

# Logging
log_level = INFO
syslog_enabled = true
syslog_server = siem-lab.lab.local
syslog_port = 514

[database]
host = localhost
port = 3306
name = wabdb
user = wabadmin
# password managed separately

[ssl]
certificate = /etc/opt/wab/ssl/server.crt
private_key = /etc/opt/wab/ssl/server.key
EOF
```

---

## Step 8: Verify Installation

### Check Services

```bash
# Check all services
systemctl status wallix-bastion
systemctl status mariadb

# Or use WALLIX command
wabadmin status
```

### Test Web Access

```bash
# Test from node itself
curl -k https://localhost/

# Should return HTML of login page
```

### Check Logs

```bash
# Main log
tail -f /var/log/wabengine/wabengine.log

# Audit log
tail -f /var/log/wabaudit/audit.log
```

---

## Step 9: Web UI Initial Access

1. Open browser to: `https://10.10.1.11/admin` (node1) or `https://10.10.1.12/admin` (node2)
2. Accept certificate warning (self-signed)
3. Login:
   - Username: `admin`
   - Password: `Pam4otAdmin123!`
4. Verify dashboard loads

### Initial Web UI Tasks

```
1. System > License
   - Upload license file (if available)
   - Or continue with trial

2. System > Settings
   - Verify hostname
   - Set timezone

3. System > Status
   - Verify all services green
```

---

## Node-Specific Settings

### Node 1 (pam4ot-node1)

```bash
# /etc/opt/wab/wabengine.conf
hostname = pam4ot-node1.lab.local

# /etc/hosts entry
10.10.1.11  pam4ot-node1.lab.local pam4ot-node1
10.10.1.12  pam4ot-node2.lab.local pam4ot-node2
```

### Node 2 (pam4ot-node2)

```bash
# /etc/opt/wab/wabengine.conf
hostname = pam4ot-node2.lab.local

# /etc/hosts entry
10.10.1.11  pam4ot-node1.lab.local pam4ot-node1
10.10.1.12  pam4ot-node2.lab.local pam4ot-node2
```

---

## Installation Checklist

### Node 1

| Check | Status |
|-------|--------|
| Debian 12 installed | [ ] |
| Network configured (10.10.1.11) | [ ] |
| Data disk mounted (/var/wab) | [ ] |
| PAM4OT package installed | [ ] |
| SSL certificate configured | [ ] |
| AD CA certificate imported | [ ] |
| Services running | [ ] |
| Web UI accessible | [ ] |
| Admin login works | [ ] |

### Node 2

| Check | Status |
|-------|--------|
| Debian 12 installed | [ ] |
| Network configured (10.10.1.12) | [ ] |
| Data disk mounted (/var/wab) | [ ] |
| PAM4OT package installed | [ ] |
| SSL certificate configured | [ ] |
| AD CA certificate imported | [ ] |
| Services running | [ ] |
| Web UI accessible | [ ] |
| Admin login works | [ ] |

---

## Troubleshooting

### Service Won't Start

```bash
# Check logs
journalctl -u wallix-bastion -f

# Check database
systemctl status mariadb
sudo mysql -e "SELECT 1"

# Check permissions
ls -la /var/wab/
ls -la /etc/opt/wab/
```

### Web UI Not Accessible

```bash
# Check if listening
ss -tuln | grep 443

# Check firewall
iptables -L -n

# Check certificate
openssl x509 -in /etc/opt/wab/ssl/server.crt -noout -dates
```

### Database Connection Error

```bash
# Check MariaDB is running
systemctl status mariadb

# Check connection
sudo mysql -e "SHOW DATABASES"

# Reset if needed
wabadmin db reset
```

---

<p align="center">
  <a href="./02-active-directory-setup.md">← Previous</a> •
  <a href="./04-ha-active-active.md">Next: HA Active-Active Configuration →</a>
</p>
