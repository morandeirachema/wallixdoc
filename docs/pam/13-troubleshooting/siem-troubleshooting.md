# SIEM Integration Troubleshooting

## Diagnosing and Resolving Log Forwarding Issues

This guide covers troubleshooting when PAM4OT logs are not arriving in your SIEM.

---

## Quick Diagnosis Flowchart

```
+===============================================================================+
|                    SIEM TROUBLESHOOTING FLOWCHART                             |
+===============================================================================+

  Logs not appearing in SIEM?
            |
            v
  +-------------------+
  | Is syslog service |     NO
  | running on PAM4OT?|-----------> Start syslog service
  +-------------------+             systemctl start rsyslog
            | YES
            v
  +-------------------+
  | Can PAM4OT reach  |     NO
  | SIEM on port 514? |-----------> Check firewall/network
  +-------------------+
            | YES
            v
  +-------------------+
  | Is SIEM listening |     NO
  | on correct port?  |-----------> Configure SIEM input
  +-------------------+
            | YES
            v
  +-------------------+
  | Are logs being    |     NO
  | generated locally?|-----------> Check PAM4OT config
  +-------------------+
            | YES
            v
  +-------------------+
  | Is SIEM parsing   |     NO
  | logs correctly?   |-----------> Fix parser/sourcetype
  +-------------------+
            | YES
            v
  Check index/search query

+===============================================================================+
```

---

## Step 1: Verify PAM4OT Syslog Configuration

### Check Current Configuration

```bash
# SSH to PAM4OT node
ssh admin@pam4ot.company.com

# View syslog configuration
cat /etc/opt/wab/wabengine.conf | grep -A 10 "\[syslog\]"

# Expected output:
# [syslog]
# enabled = true
# server = siem.company.com
# port = 514
# protocol = tcp
# format = cef
# facility = local0
```

### Verify Syslog Service

```bash
# Check rsyslog status
systemctl status rsyslog

# If not running:
systemctl start rsyslog
systemctl enable rsyslog

# Check PAM4OT audit service
systemctl status wallix-bastion

# View syslog queue
wabadmin syslog status
```

### Test Local Log Generation

```bash
# Generate test event
wabadmin audit test-event

# Check if event appears locally
tail -f /var/log/wabaudit/audit.log

# Should see:
# 2026-01-29T10:15:30Z TEST Test audit event generated
```

---

## Step 2: Verify Network Connectivity

### Basic Connectivity Test

```bash
# Test TCP connectivity to SIEM
nc -zv siem.company.com 514
# Expected: Connection to siem.company.com 514 port [tcp/syslog] succeeded!

# Test UDP connectivity (if using UDP)
nc -zuv siem.company.com 514

# Test with timeout
timeout 5 bash -c 'cat < /dev/null > /dev/tcp/siem.company.com/514' && echo "OK" || echo "FAILED"
```

### Firewall Verification

```bash
# Check local firewall
iptables -L -n | grep 514

# Check if traffic is being sent
tcpdump -i any port 514 -n

# Send manual test message
logger -n siem.company.com -P 514 -p local0.info "PAM4OT test message $(date)"
```

### DNS Resolution

```bash
# Verify SIEM hostname resolves
nslookup siem.company.com
dig siem.company.com

# If DNS fails, add to hosts file temporarily:
echo "10.10.1.50 siem.company.com" >> /etc/hosts
```

---

## Step 3: Verify SIEM Is Receiving

### For Splunk

```bash
# On Splunk server, check if data is arriving
/opt/splunk/bin/splunk search 'index=* sourcetype=syslog | head 5' -auth admin:password

# Check inputs
cat /opt/splunk/etc/system/local/inputs.conf | grep -A 5 "\[tcp://514\]"

# Check Splunk is listening
netstat -tlnp | grep 514
ss -tlnp | grep 514

# Check Splunk internal logs
tail -f /opt/splunk/var/log/splunk/splunkd.log | grep -i "tcp input"
```

### For ELK/Logstash

```bash
# On Logstash server, check if data arriving
tail -f /var/log/logstash/logstash-plain.log

# Check Logstash is listening
ss -tlnp | grep 514

# Check Logstash pipeline status
curl -s localhost:9600/_node/stats/pipelines | jq '.pipelines'

# Test Logstash input manually
echo "CEF:0|WALLIX|PAM4OT|12.1|100|Test|1|msg=test" | nc -w1 localhost 514
```

### Check Packet Capture on SIEM

```bash
# Capture incoming syslog traffic
tcpdump -i any port 514 -A -c 20

# Should see CEF formatted messages:
# CEF:0|WALLIX|PAM4OT|12.1|100|User Login|5|src=10.10.1.50...
```

---

## Step 4: Verify Log Format and Parsing

### Expected CEF Format

```
CEF:0|WALLIX|PAM4OT|12.1|<event_id>|<event_name>|<severity>|<extensions>

Example events:
CEF:0|WALLIX|PAM4OT|12.1|100|User Login Success|3|src=10.10.1.100 suser=jadmin outcome=success
CEF:0|WALLIX|PAM4OT|12.1|101|User Login Failed|7|src=10.10.1.100 suser=baduser outcome=failure reason=invalid_password
CEF:0|WALLIX|PAM4OT|12.1|200|Session Started|3|src=10.10.1.100 suser=jadmin dhost=linux-test duser=root proto=SSH
```

### Splunk CEF Parsing

```bash
# Check if Splunk Add-on for CEF is installed
/opt/splunk/bin/splunk display app | grep -i cef

# If not installed:
/opt/splunk/bin/splunk install app /path/to/Splunk_TA_pam4ot.tgz

# Configure props.conf for CEF
cat >> /opt/splunk/etc/system/local/props.conf << 'EOF'
[source::syslog]
TRANSFORMS-cef = cef_header, cef_extension
TIME_FORMAT = %b %d %H:%M:%S
MAX_TIMESTAMP_LOOKAHEAD = 32

[pam4ot:cef]
SHOULD_LINEMERGE = false
TIME_FORMAT = %b %d %H:%M:%S
TRANSFORMS-cef = cef_header, cef_extension
EOF

# Restart Splunk
/opt/splunk/bin/splunk restart
```

### Logstash CEF Parsing

```ruby
# /etc/logstash/conf.d/pam4ot.conf
input {
  tcp {
    port => 514
    type => "pam4ot"
  }
}

filter {
  if [type] == "pam4ot" {
    # Parse syslog header
    grok {
      match => { "message" => "%{SYSLOGTIMESTAMP:syslog_timestamp} %{HOSTNAME:source_host} %{GREEDYDATA:cef_message}" }
    }

    # Parse CEF format
    if [cef_message] =~ /^CEF:/ {
      grok {
        match => { "cef_message" => "CEF:%{INT:cef_version}\|%{DATA:vendor}\|%{DATA:product}\|%{DATA:device_version}\|%{DATA:signature_id}\|%{DATA:name}\|%{INT:severity}\|%{GREEDYDATA:extension}" }
      }

      # Parse CEF extensions
      kv {
        source => "extension"
        field_split => " "
        value_split => "="
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
```

---

## Step 5: Common Issues and Solutions

### Issue: "No logs arriving at all"

**Diagnosis:**
```bash
# On PAM4OT, check if syslog is being generated
wabadmin syslog status
# Shows: Syslog queue: 0 messages, Last sent: Never

# Check syslog configuration
wabadmin config show syslog
```

**Solution:**
```bash
# Enable syslog forwarding
wabadmin config set syslog.enabled true
wabadmin config set syslog.server siem.company.com
wabadmin config set syslog.port 514
wabadmin config set syslog.protocol tcp
wabadmin config set syslog.format cef

# Restart service
systemctl restart wallix-bastion

# Verify
wabadmin syslog test
```

### Issue: "Logs arrive but aren't parsed"

**Diagnosis:**
```bash
# Splunk - check raw events
index=pam4ot | head 5 | table _raw

# If CEF fields not extracted, parsing failed
```

**Solution:**
```bash
# Splunk - Install CEF add-on
/opt/splunk/bin/splunk install app splunk-add-on-for-cef

# Or create manual extraction
cat >> /opt/splunk/etc/system/local/props.conf << 'EOF'
[pam4ot]
REPORT-cef = cef-fields
EOF

cat >> /opt/splunk/etc/system/local/transforms.conf << 'EOF'
[cef-fields]
REGEX = CEF:\d+\|([^|]+)\|([^|]+)\|([^|]+)\|([^|]+)\|([^|]+)\|(\d+)\|(.*)
FORMAT = vendor::$1 product::$2 version::$3 signature_id::$4 name::$5 severity::$6 extension::$7
EOF
```

### Issue: "Logs are delayed"

**Diagnosis:**
```bash
# Check syslog queue on PAM4OT
wabadmin syslog status

# If queue is growing:
# Syslog queue: 1532 messages, Last sent: 10 minutes ago
```

**Solution:**
```bash
# Check network throughput
iperf3 -c siem.company.com -p 5201

# Switch from TCP to UDP if latency is issue
wabadmin config set syslog.protocol udp

# Increase batch size
wabadmin config set syslog.batch_size 100

# Check SIEM indexing speed (may need tuning on SIEM side)
```

### Issue: "TLS connection fails"

**Diagnosis:**
```bash
# Test TLS connection
openssl s_client -connect siem.company.com:6514

# Check certificate
echo | openssl s_client -connect siem.company.com:6514 2>/dev/null | openssl x509 -noout -dates
```

**Solution:**
```bash
# Import SIEM CA certificate
cp siem-ca.crt /usr/local/share/ca-certificates/
update-ca-certificates

# Configure PAM4OT for TLS
wabadmin config set syslog.protocol tls
wabadmin config set syslog.port 6514
wabadmin config set syslog.tls_verify true

# Test
wabadmin syslog test
```

### Issue: "Some events missing"

**Diagnosis:**
```bash
# Compare PAM4OT audit log with SIEM
# On PAM4OT:
wabadmin audit count --last 1h
# Output: 523 events

# On SIEM (Splunk):
index=pam4ot earliest=-1h | stats count
# Output: 498

# Missing 25 events!
```

**Solution:**
```bash
# Check for dropped messages
wabadmin syslog status --detail

# If UDP, packets may be dropped - switch to TCP
wabadmin config set syslog.protocol tcp

# If TCP, check queue overflow
wabadmin config set syslog.queue_size 10000

# Enable message acknowledgment
wabadmin config set syslog.reliable true
```

---

## Step 6: Testing and Validation

### Generate Test Events

```bash
# Generate various event types
wabadmin audit test-event --type login-success
wabadmin audit test-event --type login-failure
wabadmin audit test-event --type session-start
wabadmin audit test-event --type session-end
wabadmin audit test-event --type password-checkout

# Generate bulk test events
for i in {1..100}; do
  wabadmin audit test-event --type login-success
done
```

### Verify in SIEM

**Splunk:**
```spl
index=pam4ot sourcetype=pam4ot:cef earliest=-15m
| stats count by name
| sort -count
```

**Elasticsearch:**
```bash
curl -X GET "localhost:9200/pam4ot-*/_search" -H 'Content-Type: application/json' -d'
{
  "query": {
    "range": {
      "@timestamp": {
        "gte": "now-15m"
      }
    }
  },
  "aggs": {
    "event_types": {
      "terms": { "field": "name.keyword" }
    }
  }
}'
```

### Continuous Monitoring

```bash
# Create monitoring script
cat > /usr/local/bin/check-siem-integration.sh << 'EOF'
#!/bin/bash

# Count events in PAM4OT
LOCAL_COUNT=$(wabadmin audit count --last 1h 2>/dev/null)

# Count events in SIEM (adjust for your SIEM)
SIEM_COUNT=$(curl -s "http://siem:9200/pam4ot-*/_count" | jq '.count')

# Calculate difference
DIFF=$((LOCAL_COUNT - SIEM_COUNT))

if [ $DIFF -gt 10 ]; then
    echo "WARNING: $DIFF events missing in SIEM"
    exit 1
fi

echo "OK: PAM4OT=$LOCAL_COUNT, SIEM=$SIEM_COUNT, Diff=$DIFF"
exit 0
EOF

chmod +x /usr/local/bin/check-siem-integration.sh

# Add to cron
echo "*/15 * * * * /usr/local/bin/check-siem-integration.sh" | crontab -
```

---

## Appendix: Protocol Reference

### Syslog Ports

| Protocol | Port | Use Case |
|----------|------|----------|
| UDP | 514 | Low latency, may drop |
| TCP | 514 | Reliable delivery |
| TLS | 6514 | Encrypted, reliable |

### CEF Event IDs

| ID | Event | Severity |
|----|-------|----------|
| 100 | User Login Success | 3 (Low) |
| 101 | User Login Failed | 7 (High) |
| 102 | User Logout | 1 (Info) |
| 200 | Session Started | 3 (Low) |
| 201 | Session Ended | 1 (Info) |
| 202 | Session Command | 2 (Info) |
| 300 | Config Changed | 5 (Medium) |
| 400 | Password Checkout | 3 (Low) |
| 401 | Password Checkin | 1 (Info) |
| 402 | Password Rotated | 3 (Low) |

---

<p align="center">
  <a href="./README.md">← Back to Troubleshooting</a>
</p>
