# 08 - Observability Stack

## Prometheus, Grafana, and Alertmanager Setup

This guide covers deploying a monitoring stack for WALLIX Bastion infrastructure visibility.

---

## Observability Architecture

```
+===============================================================================+
|                          OBSERVABILITY STACK                                  |
+===============================================================================+

  WALLIX Bastion Cluster                                  Monitoring Stack
  ==============                                  ================

  +------------------+                       +-------------------------+
  |  wallix-node1    |                       |     monitoring-lab      |
  |  Metrics Export  |----+                  |     10.10.1.60          |
  |  Port 9100       |    |                  |                         |
  +------------------+    |    Scrape        |  +-------------------+  |
                          +------------------->  |    Prometheus    |  |
  +------------------+    |    Port 9090     |  |    :9090          |  |
  |  wallix-node2    |----+                  |  +---------+---------+  |
  |  Metrics Export  |                       |            |            |
  |  Port 9100       |                       |            v            |
  +------------------+                       |  +-------------------+  |
                                             |  |    Grafana        |  |
  +------------------+                       |  |    :3000          |  |
  |  dc-lab          |----+                  |  +-------------------+  |
  |  Port 9182       |    |    Scrape        |                         |
  +------------------+    +-------------------> +-------------------+  |
                                             |  |   Alertmanager    |  |
  +------------------+                       |  |    :9093          |  |
  |  siem-lab        |----+                  |  +-------------------+  |
  |  Port 9100       |    |    Scrape        |                         |
  +------------------+    +------------------>-------------------------+

  METRICS COLLECTED:
  - System: CPU, Memory, Disk, Network
  - WALLIX Bastion: Sessions, Authentications, API calls
  - MariaDB: Connections, Replication lag
  - Cluster: Pacemaker status, VIP health

+===============================================================================+
```

---

## Step 1: Install Prometheus

### On monitoring-lab (10.10.1.60)

```bash
# Set hostname
hostnamectl set-hostname monitoring-lab.lab.local

# Configure network
cat > /etc/netplan/00-installer-config.yaml << 'EOF'
network:
  version: 2
  ethernets:
    ens192:
      addresses: [10.10.1.60/24]
      routes:
        - to: default
          via: 10.10.1.1
      nameservers:
        addresses: [10.10.1.10]
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

  # WALLIX Bastion Nodes
  - job_name: 'wallix'
    static_configs:
      - targets:
        - 'wallix-node1.lab.local:9100'
        - 'wallix-node2.lab.local:9100'
        labels:
          service: 'wallix'
          environment: 'lab'

  # WALLIX Bastion MariaDB
  - job_name: 'wallix-mariadb'
    static_configs:
      - targets:
        - 'wallix-node1.lab.local:9104'
        - 'wallix-node2.lab.local:9104'
        labels:
          service: 'mariadb'

  # WALLIX Bastion Application Metrics
  - job_name: 'wallix-app'
    static_configs:
      - targets:
        - 'wallix-node1.lab.local:9091'
        - 'wallix-node2.lab.local:9091'
        labels:
          service: 'wallix-app'

  # Active Directory DC
  - job_name: 'windows'
    static_configs:
      - targets:
        - 'dc-lab.lab.local:9182'
        labels:
          service: 'active-directory'

  # SIEM Server
  - job_name: 'siem'
    static_configs:
      - targets:
        - 'siem-lab.lab.local:9100'
        labels:
          service: 'siem'

  # Test Targets
  - job_name: 'test-targets'
    static_configs:
      - targets:
        - 'linux-test.lab.local:9100'
        labels:
          service: 'test-target'
          os: 'linux'
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

## Step 2: Install Node Exporter on WALLIX Bastion Nodes

### On both wallix-node1 and wallix-node2

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

### On monitoring-lab

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
domain = monitoring-lab.lab.local

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

### On monitoring-lab

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
          summary: "MariaDB replication lag on {{ $labels.instance }}"
          description: "Replication lag is {{ $value }} seconds."

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

  - name: cluster
    rules:
      # VIP Not Assigned
      - alert: ClusterVIPDown
        expr: absent(up{instance=~".*:9100",job="wallix"} == 1) or (sum(up{job="wallix"}) < 1)
        for: 2m
        labels:
          severity: critical
          service: wallix
        annotations:
          summary: "WALLIX Bastion cluster VIP may be down"
          description: "No WALLIX Bastion nodes are responding."
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
| MariaDB exporter on WALLIX Bastion nodes | [ ] |
| Grafana installed | [ ] |
| Prometheus data source configured | [ ] |
| Alertmanager installed | [ ] |
| Alert rules created | [ ] |
| Dashboard created | [ ] |
| Windows exporter on DC | [ ] |
| All targets healthy | [ ] |

---

<p align="center">
  <a href="./07-siem-integration.md">← Previous</a> •
  <a href="./09-validation-testing.md">Next: Validation Testing →</a>
</p>
