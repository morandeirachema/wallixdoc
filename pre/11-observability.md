# 08 - Observability Stack

## Prometheus, Grafana, and Alertmanager Setup

This guide covers deploying a monitoring stack for WALLIX Bastion infrastructure visibility.

> **Lab configuration**: Prometheus and Grafana run on **monitor-lab (10.10.0.20)** in the **Management VLAN (VLAN 100)**. Scrape targets include the single Bastion node (10.10.1.11), FortiAuth (10.10.1.50), AD DC (10.10.1.60), SIEM (10.10.0.10), and target servers.

---

## Observability Architecture

```
+===============================================================================+
|                          OBSERVABILITY STACK                                  |
+===============================================================================+

  Management VLAN 100                       All VLANs (scrape via Fortigate)
  ====================                      ================================

                                            +------------------+
                                            | wallix-bastion   |
                                            | 10.10.1.11 :9100 |
                                            | (DMZ VLAN 110)   |
                                            +------------------+

  +----------------------------+            +------------------+
  |     monitor-lab            |   Scrape   | fortiauth        |
  |     10.10.0.20             |<---------->| 10.10.1.50 :9100 |
  |  Prometheus :9090          |            | (Cyber VLAN 120) |
  |  Grafana :3000             |            +------------------+
  |  Alertmanager :9093        |
  +----------------------------+            +------------------+
                                            | dc-lab           |
                                            | 10.10.1.60 :9182 |
                                            | (Cyber VLAN 120) |
                                            +------------------+

                                            +------------------+
                                            | siem-lab         |
                                            | 10.10.0.10 :9100 |
                                            | (Mgmt VLAN 100)  |
                                            +------------------+

  METRICS COLLECTED:
  - System: CPU, Memory, Disk, Network
  - WALLIX Bastion: Sessions, Authentications, API calls
  - MariaDB: Connections (single node)
  - HAProxy: Connection stats, VIP health

+===============================================================================+
```

---

## Step 1: Install Prometheus

### On monitor-lab (10.10.0.20, Management VLAN 100)

```bash
# Set hostname
hostnamectl set-hostname monitor-lab.lab.local

# Configure network
cat > /etc/netplan/00-installer-config.yaml << 'EOF'
network:
  version: 2
  ethernets:
    ens192:
      addresses: [10.10.0.20/24]
      routes:
        - to: default
          via: 10.10.0.1
      nameservers:
        addresses: [10.10.1.60]
        search: [lab.local]
EOF
netplan apply

# Create prometheus user
useradd --no-create-home --shell /bin/false prometheus

# Download Prometheus
cd /tmp
wget https://github.com/prometheus/prometheus/releases/download/v2.47.0/prometheus-2.47.0.linux-amd64.tar.gz
tar xzf prometheus-2.47.0.linux-amd64.tar.gz
cd prometheus-2.47.0.linux-amd64

# Install binaries
cp prometheus promtool /usr/local/bin/
chown prometheus:prometheus /usr/local/bin/prometheus /usr/local/bin/promtool

# Create directories
mkdir -p /etc/prometheus /var/lib/prometheus
cp -r consoles console_libraries /etc/prometheus/
chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
```

### Configure Prometheus

```bash
cat > /etc/prometheus/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - localhost:9093

rule_files:
  - "/etc/prometheus/rules/*.yml"

scrape_configs:
  # Prometheus self-monitoring
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  # WALLIX Bastion (single node)
  - job_name: 'wallix'
    static_configs:
      - targets:
        - '10.10.1.11:9100'
        labels:
          service: 'wallix'
          vlan: 'dmz'
          environment: 'lab'

  # WALLIX Bastion MariaDB (single node)
  - job_name: 'wallix-mariadb'
    static_configs:
      - targets:
        - '10.10.1.11:9104'
        labels:
          service: 'mariadb'

  # HAProxy nodes
  - job_name: 'haproxy'
    static_configs:
      - targets:
        - '10.10.1.5:8405'
        - '10.10.1.6:8405'
        labels:
          service: 'haproxy'
          vlan: 'dmz'

  # FortiAuthenticator (Cyber VLAN 120)
  - job_name: 'fortiauth'
    static_configs:
      - targets:
        - '10.10.1.50:9100'
        labels:
          service: 'fortiauth'
          vlan: 'cyber'

  # Active Directory DC (Cyber VLAN 120)
  - job_name: 'windows'
    static_configs:
      - targets:
        - '10.10.1.60:9182'
        labels:
          service: 'active-directory'
          vlan: 'cyber'

  # SIEM Server (Management VLAN 100)
  - job_name: 'siem'
    static_configs:
      - targets:
        - '10.10.0.10:9100'
        labels:
          service: 'siem'
          vlan: 'management'

  # Linux test targets (Targets VLAN 130)
  - job_name: 'test-targets'
    static_configs:
      - targets:
        - '10.10.2.20:9100'    # rhel10-srv
        - '10.10.2.21:9100'    # rhel9-srv
        labels:
          service: 'test-target'
          vlan: 'targets'
EOF

chown prometheus:prometheus /etc/prometheus/prometheus.yml
```

### Create Systemd Service

```bash
cat > /etc/systemd/system/prometheus.service << 'EOF'
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file=/etc/prometheus/prometheus.yml \
    --storage.tsdb.path=/var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries \
    --web.enable-lifecycle \
    --storage.tsdb.retention.time=30d

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable prometheus
systemctl start prometheus

# Verify
curl http://localhost:9090/-/healthy
```

---

## Step 2: Install Node Exporter on WALLIX Bastion Node

### On wallix-bastion (10.10.1.11, single node)

```bash
# Create user
useradd --no-create-home --shell /bin/false node_exporter

# Download and install
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz
tar xzf node_exporter-1.6.1.linux-amd64.tar.gz
cp node_exporter-1.6.1.linux-amd64/node_exporter /usr/local/bin/
chown node_exporter:node_exporter /usr/local/bin/node_exporter

# Create service
cat > /etc/systemd/system/node_exporter.service << 'EOF'
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter \
    --collector.systemd \
    --collector.processes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable node_exporter
systemctl start node_exporter

# Verify
curl http://localhost:9100/metrics | head
```

---

## Step 3: Install MariaDB Exporter

### On both WALLIX Bastion nodes

```bash
# Download
cd /tmp
wget https://github.com/prometheus-community/mysqld_exporter/releases/download/v0.15.0/mysqld_exporter-0.15.0.linux-amd64.tar.gz
tar xzf mysqld_exporter-0.15.0.linux-amd64.tar.gz
cp mysqld_exporter-0.15.0.linux-amd64/mysqld_exporter /usr/local/bin/
useradd --no-create-home --shell /bin/false mysqld_exporter

# Create environment file
cat > /etc/default/mysqld_exporter << 'EOF'
DATA_SOURCE_NAME="mariadb://wabadmin:PgAdmin123!@localhost:3306/wabdb?sslmode=disable"
EOF
chmod 600 /etc/default/mysqld_exporter

# Create service
cat > /etc/systemd/system/mysqld_exporter.service << 'EOF'
[Unit]
Description=Prometheus MariaDB Exporter
After=network.target

[Service]
User=mysqld_exporter
Group=mysqld_exporter
Type=simple
EnvironmentFile=/etc/default/mysqld_exporter
ExecStart=/usr/local/bin/mysqld_exporter

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable mysqld_exporter
systemctl start mysqld_exporter

# Verify
curl http://localhost:9104/metrics | grep mysql_up
```

---

## Step 4: Install Grafana

### On monitor-lab

```bash
# Add Grafana repository
apt install -y apt-transport-https software-properties-common
wget -q -O - https://packages.grafana.com/gpg.key | apt-key add -
echo "deb https://packages.grafana.com/oss/deb stable main" > /etc/apt/sources.list.d/grafana.list

# Install
apt update
apt install -y grafana

# Configure
cat > /etc/grafana/grafana.ini << 'EOF'
[server]
http_port = 3000
domain = monitor-lab.lab.local

[security]
admin_user = admin
admin_password = GrafanaAdmin123!

[auth.anonymous]
enabled = false

[alerting]
enabled = true
EOF

# Start
systemctl enable grafana-server
systemctl start grafana-server

# Access: http://10.10.1.60:3000
# Login: admin / GrafanaAdmin123!
```

### Add Prometheus Data Source

```bash
# Via API
curl -X POST http://admin:GrafanaAdmin123!@localhost:3000/api/datasources \
    -H "Content-Type: application/json" \
    -d '{
        "name": "Prometheus",
        "type": "prometheus",
        "url": "http://localhost:9090",
        "access": "proxy",
        "isDefault": true
    }'
```

---

## Step 5: Install Alertmanager

### On monitor-lab

```bash
# Create user
useradd --no-create-home --shell /bin/false alertmanager

# Download
cd /tmp
wget https://github.com/prometheus/alertmanager/releases/download/v0.26.0/alertmanager-0.26.0.linux-amd64.tar.gz
tar xzf alertmanager-0.26.0.linux-amd64.tar.gz
cp alertmanager-0.26.0.linux-amd64/alertmanager /usr/local/bin/
cp alertmanager-0.26.0.linux-amd64/amtool /usr/local/bin/
mkdir -p /etc/alertmanager /var/lib/alertmanager
chown -R alertmanager:alertmanager /etc/alertmanager /var/lib/alertmanager
```

### Configure Alertmanager

```bash
cat > /etc/alertmanager/alertmanager.yml << 'EOF'
global:
  smtp_smarthost: 'smtp.lab.local:25'
  smtp_from: 'alertmanager@lab.local'

route:
  group_by: ['alertname', 'service']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  receiver: 'default'
  routes:
    - match:
        severity: critical
      receiver: 'critical'
    - match:
        service: wallix
      receiver: 'wallix-team'

receivers:
  - name: 'default'
    email_configs:
      - to: 'ops@lab.local'

  - name: 'critical'
    email_configs:
      - to: 'oncall@lab.local'

  - name: 'wallix-team'
    email_configs:
      - to: 'wallix-team@lab.local'

inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'instance']
EOF

chown alertmanager:alertmanager /etc/alertmanager/alertmanager.yml
```

### Create Service

```bash
cat > /etc/systemd/system/alertmanager.service << 'EOF'
[Unit]
Description=Alertmanager
Wants=network-online.target
After=network-online.target

[Service]
User=alertmanager
Group=alertmanager
Type=simple
ExecStart=/usr/local/bin/alertmanager \
    --config.file=/etc/alertmanager/alertmanager.yml \
    --storage.path=/var/lib/alertmanager/

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable alertmanager
systemctl start alertmanager
```

---

## Step 6: Create Prometheus Alert Rules

```bash
mkdir -p /etc/prometheus/rules

cat > /etc/prometheus/rules/wallix.yml << 'EOF'
groups:
  - name: wallix
    rules:
      # Node Down
      - alert: WALLIX BastionNodeDown
        expr: up{job="wallix"} == 0
        for: 1m
        labels:
          severity: critical
          service: wallix
        annotations:
          summary: "WALLIX Bastion node {{ $labels.instance }} is down"
          description: "WALLIX Bastion node has been unreachable for more than 1 minute."

      # High CPU Usage
      - alert: WALLIX BastionHighCPU
        expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle",job="wallix"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
          service: wallix
        annotations:
          summary: "High CPU usage on {{ $labels.instance }}"
          description: "CPU usage is above 80% for 5 minutes."

      # High Memory Usage
      - alert: WALLIX BastionHighMemory
        expr: (1 - (node_memory_MemAvailable_bytes{job="wallix"} / node_memory_MemTotal_bytes{job="wallix"})) * 100 > 85
        for: 5m
        labels:
          severity: warning
          service: wallix
        annotations:
          summary: "High memory usage on {{ $labels.instance }}"
          description: "Memory usage is above 85%."

      # Disk Space Low
      - alert: WALLIX BastionDiskSpaceLow
        expr: (node_filesystem_avail_bytes{job="wallix",mountpoint="/var/wab"} / node_filesystem_size_bytes{job="wallix",mountpoint="/var/wab"}) * 100 < 20
        for: 5m
        labels:
          severity: warning
          service: wallix
        annotations:
          summary: "Low disk space on {{ $labels.instance }}"
          description: "Disk space is below 20% on /var/wab."

      # Disk Space Critical
      - alert: WALLIX BastionDiskSpaceCritical
        expr: (node_filesystem_avail_bytes{job="wallix",mountpoint="/var/wab"} / node_filesystem_size_bytes{job="wallix",mountpoint="/var/wab"}) * 100 < 10
        for: 1m
        labels:
          severity: critical
          service: wallix
        annotations:
          summary: "Critical disk space on {{ $labels.instance }}"
          description: "Disk space is below 10% on /var/wab."

  - name: mariadb
    rules:
      # MariaDB Down
      - alert: MariaDBDown
        expr: mysql_up{job="wallix-mariadb"} == 0
        for: 1m
        labels:
          severity: critical
          service: mariadb
        annotations:
          summary: "MariaDB is down on {{ $labels.instance }}"
          description: "MariaDB database is not responding."

      # Replication Lag
      - alert: MariaDBReplicationLag
        expr: mysql_slave_status_seconds_behind_master{job="wallix-mariadb"} > 60
        for: 5m
        labels:
          severity: warning
          service: mariadb
        annotations:
          summary: "MariaDB high lag on {{ $labels.instance }}"
          description: "MariaDB query lag is {{ $value }} seconds. (Note: lab uses single node — no replication)"

      # Too Many Connections
      - alert: MariaDBTooManyConnections
        expr: mysql_global_status_threads_connected{job="wallix-mariadb"} > 80
        for: 5m
        labels:
          severity: warning
          service: mariadb
        annotations:
          summary: "Too many MariaDB connections on {{ $labels.instance }}"
          description: "Current connections: {{ $value }}"

  - name: bastion
    rules:
      # Bastion node down (single node in lab)
      - alert: BastionNodeDown
        expr: absent(up{instance=~".*:9100",job="wallix"} == 1) or (sum(up{job="wallix"}) < 1)
        for: 2m
        labels:
          severity: critical
          service: wallix
        annotations:
          summary: "WALLIX Bastion node is down"
          description: "wallix-bastion (10.10.1.11) is not responding."
EOF

chown prometheus:prometheus /etc/prometheus/rules/wallix.yml

# Reload Prometheus
curl -X POST http://localhost:9090/-/reload
```

---

## Step 7: Create Grafana Dashboards

### WALLIX Bastion Overview Dashboard

```json
{
  "dashboard": {
    "title": "WALLIX Bastion Overview",
    "panels": [
      {
        "title": "Node Status",
        "type": "stat",
        "gridPos": {"x": 0, "y": 0, "w": 6, "h": 4},
        "targets": [
          {
            "expr": "sum(up{job=\"wallix\"})",
            "legendFormat": "Nodes Up"
          }
        ]
      },
      {
        "title": "CPU Usage",
        "type": "gauge",
        "gridPos": {"x": 6, "y": 0, "w": 6, "h": 4},
        "targets": [
          {
            "expr": "avg(100 - (avg by(instance) (rate(node_cpu_seconds_total{mode=\"idle\",job=\"wallix\"}[5m])) * 100))",
            "legendFormat": "CPU %"
          }
        ]
      },
      {
        "title": "Memory Usage",
        "type": "gauge",
        "gridPos": {"x": 12, "y": 0, "w": 6, "h": 4},
        "targets": [
          {
            "expr": "avg((1 - (node_memory_MemAvailable_bytes{job=\"wallix\"} / node_memory_MemTotal_bytes{job=\"wallix\"})) * 100)",
            "legendFormat": "Memory %"
          }
        ]
      },
      {
        "title": "Disk Usage (/var/wab)",
        "type": "gauge",
        "gridPos": {"x": 18, "y": 0, "w": 6, "h": 4},
        "targets": [
          {
            "expr": "avg((1 - (node_filesystem_avail_bytes{job=\"wallix\",mountpoint=\"/var/wab\"} / node_filesystem_size_bytes{job=\"wallix\",mountpoint=\"/var/wab\"})) * 100)",
            "legendFormat": "Disk %"
          }
        ]
      },
      {
        "title": "CPU Usage Over Time",
        "type": "graph",
        "gridPos": {"x": 0, "y": 4, "w": 12, "h": 8},
        "targets": [
          {
            "expr": "100 - (avg by(instance) (rate(node_cpu_seconds_total{mode=\"idle\",job=\"wallix\"}[5m])) * 100)",
            "legendFormat": "{{instance}}"
          }
        ]
      },
      {
        "title": "Memory Usage Over Time",
        "type": "graph",
        "gridPos": {"x": 12, "y": 4, "w": 12, "h": 8},
        "targets": [
          {
            "expr": "(1 - (node_memory_MemAvailable_bytes{job=\"wallix\"} / node_memory_MemTotal_bytes{job=\"wallix\"})) * 100",
            "legendFormat": "{{instance}}"
          }
        ]
      },
      {
        "title": "Network Traffic",
        "type": "graph",
        "gridPos": {"x": 0, "y": 12, "w": 12, "h": 8},
        "targets": [
          {
            "expr": "rate(node_network_receive_bytes_total{job=\"wallix\",device=\"ens192\"}[5m]) * 8",
            "legendFormat": "{{instance}} RX"
          },
          {
            "expr": "rate(node_network_transmit_bytes_total{job=\"wallix\",device=\"ens192\"}[5m]) * 8",
            "legendFormat": "{{instance}} TX"
          }
        ]
      },
      {
        "title": "MariaDB Connections",
        "type": "graph",
        "gridPos": {"x": 12, "y": 12, "w": 12, "h": 8},
        "targets": [
          {
            "expr": "mysql_global_status_threads_connected{job=\"wallix-mariadb\"}",
            "legendFormat": "{{instance}}"
          }
        ]
      }
    ]
  }
}
```

### Import Dashboard via API

```bash
# Save JSON to file and import
curl -X POST http://admin:GrafanaAdmin123!@localhost:3000/api/dashboards/db \
    -H "Content-Type: application/json" \
    -d @wallix-dashboard.json
```

---

## Step 8: Windows Exporter for AD DC

### On dc-lab (Windows Server)

```powershell
# Download Windows Exporter
Invoke-WebRequest -Uri "https://github.com/prometheus-community/windows_exporter/releases/download/v0.24.0/windows_exporter-0.24.0-amd64.msi" -OutFile "windows_exporter.msi"

# Install
msiexec /i windows_exporter.msi ENABLED_COLLECTORS="ad,cpu,cs,logical_disk,memory,net,os,service,system" /qn

# Verify
Test-NetConnection -ComputerName localhost -Port 9182

# Firewall rule
New-NetFirewallRule -DisplayName "Prometheus Windows Exporter" -Direction Inbound -Port 9182 -Protocol TCP -Action Allow
```

---

## Verification Commands

```bash
# Check Prometheus targets
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, instance: .labels.instance, health: .health}'

# Check alerts
curl -s http://localhost:9090/api/v1/alerts | jq '.data.alerts[]'

# Check Alertmanager
curl -s http://localhost:9093/api/v1/status

# Test Grafana
curl -s http://admin:GrafanaAdmin123!@localhost:3000/api/health
```

---

## Service URLs

| Service | URL | Credentials |
|---------|-----|-------------|
| Prometheus | http://10.10.1.60:9090 | None |
| Grafana | http://10.10.1.60:3000 | admin / GrafanaAdmin123! |
| Alertmanager | http://10.10.1.60:9093 | None |

---

## Observability Checklist

| Check | Status |
|-------|--------|
| Prometheus installed | [ ] |
| Node exporter on WALLIX Bastion nodes | [ ] |
| MariaDB exporter on wallix-bastion (single node) | [ ] |
| Grafana installed | [ ] |
| Prometheus data source configured | [ ] |
| Alertmanager installed | [ ] |
| Alert rules created | [ ] |
| Dashboard created | [ ] |
| Windows exporter on DC | [ ] |
| All targets healthy | [ ] |

*Last updated: April 2026 | WALLIX Bastion 12.1.x | monitor-lab: 10.10.0.20 (Management VLAN 100)*

---

<p align="center">
  <a href="./10-siem-integration.md">← Previous: SIEM Integration</a> •
  <a href="./12-validation-testing.md">Next: Validation Testing →</a>
</p>
