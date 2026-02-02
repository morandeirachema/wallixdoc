# 07 - SIEM Integration

## Configuring Log Forwarding to SIEM Platform

This guide covers integrating WALLIX Bastion with Splunk or ELK for security monitoring.

---

## Integration Architecture

```
+===============================================================================+
|                            SIEM INTEGRATION                                   |
+===============================================================================+

  WALLIX Bastion Cluster                                   SIEM Platform
  ==============                                   =============

  +------------------+                        +-----------------------+
  |  wallix-node1    |----+                   |      siem-lab         |
  |  Syslog Client   |    |    Syslog/TLS     |                       |
  +------------------+    +------------------>|   Splunk Enterprise   |
                          |    Port 6514      |   or ELK Stack        |
  +------------------+    |                   |                       |
  |  wallix-node2    |----+                   |   - Log indexing      |
  |  Syslog Client   |                        |   - Dashboards        |
  +------------------+                        |   - Alerts            |
                                              +-----------------------+

  LOG TYPES FORWARDED:
  - Authentication events (login success/failure)
  - Session events (start, end, commands)
  - Administrative actions (config changes)
  - Password events (rotation, checkout)
  - System events (service status, errors)

+===============================================================================+
```

---

## Option A: Splunk Enterprise Setup

### Step 1: Install Splunk on siem-lab

```bash
# On siem-lab VM (10.10.1.50)

# Download Splunk Enterprise
wget -O splunk.deb "https://download.splunk.com/products/splunk/releases/9.1.0/linux/splunk-9.1.0-linux-2.6-amd64.deb"

# Install
dpkg -i splunk.deb

# Start Splunk
/opt/splunk/bin/splunk start --accept-license

# Set admin password when prompted: SplunkAdmin123!

# Enable boot start
/opt/splunk/bin/splunk enable boot-start

# Access: http://10.10.1.50:8000
```

### Step 2: Configure Splunk Syslog Input

```bash
# Create inputs.conf
cat > /opt/splunk/etc/system/local/inputs.conf << 'EOF'
[tcp://514]
connection_host = dns
sourcetype = syslog
index = wallix

[tcp-ssl://6514]
connection_host = dns
sourcetype = syslog
index = wallix
serverCert = /opt/splunk/etc/auth/server.pem
sslPassword = password
requireClientCert = false
EOF

# Create index
cat > /opt/splunk/etc/system/local/indexes.conf << 'EOF'
[wallix]
homePath = $SPLUNK_DB/wallix/db
coldPath = $SPLUNK_DB/wallix/colddb
thawedPath = $SPLUNK_DB/wallix/thaweddb
maxDataSize = auto_high_volume
EOF

# Restart Splunk
/opt/splunk/bin/splunk restart
```

### Step 3: Configure WALLIX Bastion Syslog

On **both WALLIX Bastion nodes**:

```bash
# Edit syslog configuration
cat >> /etc/opt/wab/wabengine.conf << 'EOF'

[syslog]
enabled = true
server = siem-lab.lab.local
port = 514
protocol = tcp
# For TLS: port = 6514, protocol = tls
format = cef
facility = local0
EOF

# Or configure via Web UI:
# System > Settings > Syslog
# - Server: siem-lab.lab.local
# - Port: 514
# - Protocol: TCP
# - Format: CEF

# Restart WALLIX Bastion
systemctl restart wallix-bastion
```

### Step 4: Splunk Search Queries

```spl
# All WALLIX Bastion events
index=wallix

# Login events
index=wallix "authentication"

# Failed logins
index=wallix "authentication failed"

# Session events
index=wallix "session"

# Admin actions
index=wallix "configuration changed"

# Password events
index=wallix "password" OR "rotation"
```

### Step 5: Splunk Dashboard

```xml
<!-- Save as: wallix_dashboard.xml -->
<dashboard>
  <label>WALLIX Bastion Security Dashboard</label>
  <row>
    <panel>
      <title>Login Activity (24h)</title>
      <chart>
        <search>
          <query>index=wallix "authentication" | timechart count by status</query>
          <earliest>-24h</earliest>
        </search>
      </chart>
    </panel>
    <panel>
      <title>Active Sessions</title>
      <single>
        <search>
          <query>index=wallix "session started" | stats count</query>
          <earliest>-1h</earliest>
        </search>
      </single>
    </panel>
  </row>
  <row>
    <panel>
      <title>Failed Logins</title>
      <table>
        <search>
          <query>index=wallix "authentication failed" | table _time user src_ip reason</query>
          <earliest>-24h</earliest>
        </search>
      </table>
    </panel>
  </row>
</dashboard>
```

### Step 6: Splunk Alerts

```
Settings > Searches, Reports, and Alerts > New Alert

Alert 1: Multiple Failed Logins
- Search: index=wallix "authentication failed" | stats count by user | where count > 5
- Schedule: Every 5 minutes
- Trigger: When results > 0
- Action: Send email

Alert 2: After-Hours Session
- Search: index=wallix "session started" | where date_hour < 6 OR date_hour > 22
- Schedule: Real-time
- Action: Send email

Alert 3: Admin Config Change
- Search: index=wallix "configuration" "changed"
- Schedule: Real-time
- Action: Log to index, send email
```

---

## Option B: ELK Stack Setup

### Step 1: Install Elasticsearch

```bash
# On siem-lab VM

# Install Java
apt install -y openjdk-17-jdk

# Add Elastic repo
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
echo "deb https://artifacts.elastic.co/packages/8.x/apt stable main" > /etc/apt/sources.list.d/elastic-8.x.list
apt update

# Install Elasticsearch
apt install -y elasticsearch

# Configure
cat > /etc/elasticsearch/elasticsearch.yml << 'EOF'
cluster.name: wallix-lab
node.name: siem-lab
network.host: 0.0.0.0
discovery.type: single-node
xpack.security.enabled: false
EOF

systemctl enable elasticsearch
systemctl start elasticsearch
```

### Step 2: Install Logstash

```bash
apt install -y logstash

# Configure Logstash for WALLIX Bastion
cat > /etc/logstash/conf.d/wallix.conf << 'EOF'
input {
  syslog {
    port => 514
    type => "wallix"
  }
}

filter {
  if [type] == "wallix" {
    grok {
      match => { "message" => "%{SYSLOGTIMESTAMP:timestamp} %{HOSTNAME:source} %{DATA:program}: %{GREEDYDATA:log_message}" }
    }

    # Parse CEF format if used
    if [log_message] =~ /^CEF:/ {
      grok {
        match => { "log_message" => "CEF:%{INT:cef_version}\|%{DATA:vendor}\|%{DATA:product}\|%{DATA:version}\|%{DATA:signature_id}\|%{DATA:name}\|%{INT:severity}\|%{GREEDYDATA:extension}" }
      }
    }
  }
}

output {
  elasticsearch {
    hosts => ["localhost:9200"]
    index => "wallix-%{+YYYY.MM.dd}"
  }
}
EOF

systemctl enable logstash
systemctl start logstash
```

### Step 3: Install Kibana

```bash
apt install -y kibana

# Configure
cat > /etc/kibana/kibana.yml << 'EOF'
server.host: "0.0.0.0"
elasticsearch.hosts: ["http://localhost:9200"]
EOF

systemctl enable kibana
systemctl start kibana

# Access: http://10.10.1.50:5601
```

### Step 4: Kibana Index Pattern

1. Open Kibana: http://10.10.1.50:5601
2. Go to: Stack Management > Index Patterns
3. Create pattern: `wallix-*`
4. Time field: `@timestamp`

### Step 5: Kibana Dashboard

Create visualizations for:
- Login success/failure over time
- Sessions by user
- Sessions by target
- Failed login attempts by source IP

---

## Log Format Reference

### CEF Format (Common Event Format)

```
CEF:0|WALLIX|WALLIX Bastion|12.1|100|User Login|5|src=10.10.1.50 suser=jadmin outcome=success
CEF:0|WALLIX|WALLIX Bastion|12.1|101|User Login Failed|7|src=10.10.1.50 suser=baduser outcome=failure reason=invalid_password
CEF:0|WALLIX|WALLIX Bastion|12.1|200|Session Started|3|src=10.10.1.50 suser=jadmin dhost=linux-test duser=root protocol=SSH
CEF:0|WALLIX|WALLIX Bastion|12.1|201|Session Ended|3|src=10.10.1.50 suser=jadmin dhost=linux-test duration=300
```

### Syslog Format

```
Jan 29 10:15:23 wallix-node1 wallix-bastion[1234]: [AUTH] User jadmin authenticated successfully from 10.10.1.50
Jan 29 10:15:30 wallix-node1 wallix-bastion[1234]: [SESSION] User jadmin started SSH session to linux-test as root
Jan 29 10:20:30 wallix-node1 wallix-bastion[1234]: [SESSION] Session ended for user jadmin (duration: 5m0s)
```

---

## Verify Integration

```bash
# Generate test events
# 1. Login to WALLIX Bastion
# 2. Launch a session
# 3. End session

# On SIEM, search for events:

# Splunk:
index=wallix | head 10

# Elasticsearch:
curl -X GET "localhost:9200/wallix-*/_search?q=*&size=10&pretty"
```

---

## SIEM Integration Checklist

| Check | Status |
|-------|--------|
| SIEM platform installed | [ ] |
| Syslog input configured | [ ] |
| WALLIX Bastion syslog enabled | [ ] |
| Test log received | [ ] |
| Index/sourcetype created | [ ] |
| Basic searches work | [ ] |
| Dashboard created | [ ] |
| Alerts configured | [ ] |

---

<p align="center">
  <a href="./06-test-targets.md">← Previous</a> •
  <a href="./08-observability.md">Next: Observability Stack →</a>
</p>
