# 07 - SIEM Integration

## Configuring Log Forwarding to SIEM Platform

This guide covers integrating PAM4OT with Splunk or ELK for security monitoring.

---

## Integration Architecture

```
+==============================================================================+
|                   SIEM INTEGRATION                                            |
+==============================================================================+

  PAM4OT Cluster                              SIEM Platform
  ==============                              =============

  +----------------+                     +----------------------+
  | pam4ot-node1   |---+                 |    siem-lab          |
  | Syslog Client  |   |   Syslog/TLS    |                      |
  +----------------+   +---------------->|  Splunk Enterprise   |
                       |   Port 6514     |  or ELK Stack        |
  +----------------+   |                 |                      |
  | pam4ot-node2   |---+                 |  - Log indexing      |
  | Syslog Client  |                     |  - Dashboards        |
  +----------------+                     |  - Alerts            |
                                         +----------------------+

  LOG TYPES FORWARDED:
  - Authentication events (login success/failure)
  - Session events (start, end, commands)
  - Administrative actions (config changes)
  - Password events (rotation, checkout)
  - System events (service status, errors)

+==============================================================================+
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
index = pam4ot

[tcp-ssl://6514]
connection_host = dns
sourcetype = syslog
index = pam4ot
serverCert = /opt/splunk/etc/auth/server.pem
sslPassword = password
requireClientCert = false
EOF

# Create index
cat > /opt/splunk/etc/system/local/indexes.conf << 'EOF'
[pam4ot]
homePath = $SPLUNK_DB/pam4ot/db
coldPath = $SPLUNK_DB/pam4ot/colddb
thawedPath = $SPLUNK_DB/pam4ot/thaweddb
maxDataSize = auto_high_volume
EOF

# Restart Splunk
/opt/splunk/bin/splunk restart
```

### Step 3: Configure PAM4OT Syslog

On **both PAM4OT nodes**:

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

# Restart PAM4OT
systemctl restart wallix-bastion
```

### Step 4: Splunk Search Queries

```spl
# All PAM4OT events
index=pam4ot

# Login events
index=pam4ot "authentication"

# Failed logins
index=pam4ot "authentication failed"

# Session events
index=pam4ot "session"

# Admin actions
index=pam4ot "configuration changed"

# Password events
index=pam4ot "password" OR "rotation"
```

### Step 5: Splunk Dashboard

```xml
<!-- Save as: pam4ot_dashboard.xml -->
<dashboard>
  <label>PAM4OT Security Dashboard</label>
  <row>
    <panel>
      <title>Login Activity (24h)</title>
      <chart>
        <search>
          <query>index=pam4ot "authentication" | timechart count by status</query>
          <earliest>-24h</earliest>
        </search>
      </chart>
    </panel>
    <panel>
      <title>Active Sessions</title>
      <single>
        <search>
          <query>index=pam4ot "session started" | stats count</query>
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
          <query>index=pam4ot "authentication failed" | table _time user src_ip reason</query>
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
- Search: index=pam4ot "authentication failed" | stats count by user | where count > 5
- Schedule: Every 5 minutes
- Trigger: When results > 0
- Action: Send email

Alert 2: After-Hours Session
- Search: index=pam4ot "session started" | where date_hour < 6 OR date_hour > 22
- Schedule: Real-time
- Action: Send email

Alert 3: Admin Config Change
- Search: index=pam4ot "configuration" "changed"
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
cluster.name: pam4ot-lab
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

# Configure Logstash for PAM4OT
cat > /etc/logstash/conf.d/pam4ot.conf << 'EOF'
input {
  syslog {
    port => 514
    type => "pam4ot"
  }
}

filter {
  if [type] == "pam4ot" {
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
    index => "pam4ot-%{+YYYY.MM.dd}"
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
3. Create pattern: `pam4ot-*`
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
CEF:0|WALLIX|PAM4OT|12.1|100|User Login|5|src=10.10.1.50 suser=jadmin outcome=success
CEF:0|WALLIX|PAM4OT|12.1|101|User Login Failed|7|src=10.10.1.50 suser=baduser outcome=failure reason=invalid_password
CEF:0|WALLIX|PAM4OT|12.1|200|Session Started|3|src=10.10.1.50 suser=jadmin dhost=linux-test duser=root protocol=SSH
CEF:0|WALLIX|PAM4OT|12.1|201|Session Ended|3|src=10.10.1.50 suser=jadmin dhost=linux-test duration=300
```

### Syslog Format

```
Jan 29 10:15:23 pam4ot-node1 wallix-bastion[1234]: [AUTH] User jadmin authenticated successfully from 10.10.1.50
Jan 29 10:15:30 pam4ot-node1 wallix-bastion[1234]: [SESSION] User jadmin started SSH session to linux-test as root
Jan 29 10:20:30 pam4ot-node1 wallix-bastion[1234]: [SESSION] Session ended for user jadmin (duration: 5m0s)
```

---

## Verify Integration

```bash
# Generate test events
# 1. Login to PAM4OT
# 2. Launch a session
# 3. End session

# On SIEM, search for events:

# Splunk:
index=pam4ot | head 10

# Elasticsearch:
curl -X GET "localhost:9200/pam4ot-*/_search?q=*&size=10&pretty"
```

---

## SIEM Integration Checklist

| Check | Status |
|-------|--------|
| SIEM platform installed | [ ] |
| Syslog input configured | [ ] |
| PAM4OT syslog enabled | [ ] |
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
