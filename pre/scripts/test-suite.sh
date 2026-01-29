#!/bin/bash
# test-suite.sh
# Comprehensive Test Suite for PAM4OT Pre-Production Lab
# Run from any Linux management workstation with network access to lab

set -e

#------------------------------------------------------------------------------
# Configuration
#------------------------------------------------------------------------------

# PAM4OT Configuration
PAM4OT_VIP="10.10.1.100"
PAM4OT_NODE1="10.10.1.11"
PAM4OT_NODE2="10.10.1.12"
PAM4OT_ADMIN_USER="admin"
PAM4OT_ADMIN_PASS="Pam4otAdmin123!"
PAM4OT_LDAP_USER="jadmin@lab.local"
PAM4OT_LDAP_PASS="JohnAdmin123!"

# Infrastructure
DC_HOST="10.10.1.10"
SIEM_HOST="10.10.1.50"
MONITORING_HOST="10.10.1.60"

# Test Targets
LINUX_TARGET="10.10.2.10"
WINDOWS_TARGET="10.10.2.20"
NETWORK_TARGET="10.10.2.30"
PLC_TARGET="10.10.3.10"

# Test output
LOG_FILE="/tmp/pam4ot-test-$(date +%Y%m%d-%H%M%S).log"
RESULTS_FILE="/tmp/pam4ot-results-$(date +%Y%m%d-%H%M%S).txt"

#------------------------------------------------------------------------------
# Helper Functions
#------------------------------------------------------------------------------

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

pass() {
    echo -e "${GREEN}[PASS]${NC} $1" | tee -a "$LOG_FILE"
    echo "PASS: $1" >> "$RESULTS_FILE"
}

fail() {
    echo -e "${RED}[FAIL]${NC} $1" | tee -a "$LOG_FILE"
    echo "FAIL: $1" >> "$RESULTS_FILE"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"
    echo "WARN: $1" >> "$RESULTS_FILE"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

header() {
    echo "" | tee -a "$LOG_FILE"
    echo "============================================================" | tee -a "$LOG_FILE"
    echo "  $1" | tee -a "$LOG_FILE"
    echo "============================================================" | tee -a "$LOG_FILE"
}

#------------------------------------------------------------------------------
# Test Categories
#------------------------------------------------------------------------------

test_connectivity() {
    header "1. INFRASTRUCTURE CONNECTIVITY TESTS"

    local hosts=(
        "DC:$DC_HOST"
        "PAM4OT-Node1:$PAM4OT_NODE1"
        "PAM4OT-Node2:$PAM4OT_NODE2"
        "PAM4OT-VIP:$PAM4OT_VIP"
        "SIEM:$SIEM_HOST"
        "Monitoring:$MONITORING_HOST"
        "Linux-Target:$LINUX_TARGET"
        "Windows-Target:$WINDOWS_TARGET"
        "Network-Target:$NETWORK_TARGET"
        "PLC-Target:$PLC_TARGET"
    )

    for host_entry in "${hosts[@]}"; do
        IFS=':' read -r name ip <<< "$host_entry"
        if ping -c 1 -W 2 "$ip" &>/dev/null; then
            pass "$name ($ip) is reachable"
        else
            fail "$name ($ip) is unreachable"
        fi
    done
}

test_ports() {
    header "2. SERVICE PORT TESTS"

    # PAM4OT Services
    info "Testing PAM4OT services..."

    if nc -zv "$PAM4OT_VIP" 443 2>&1 | grep -q "succeeded\|open"; then
        pass "PAM4OT HTTPS (443)"
    else
        fail "PAM4OT HTTPS (443)"
    fi

    if nc -zv "$PAM4OT_VIP" 22 2>&1 | grep -q "succeeded\|open"; then
        pass "PAM4OT SSH (22)"
    else
        fail "PAM4OT SSH (22)"
    fi

    # AD Services
    info "Testing AD services..."

    if nc -zv "$DC_HOST" 636 2>&1 | grep -q "succeeded\|open"; then
        pass "LDAPS (636)"
    else
        fail "LDAPS (636)"
    fi

    if nc -zv "$DC_HOST" 88 2>&1 | grep -q "succeeded\|open"; then
        pass "Kerberos (88)"
    else
        fail "Kerberos (88)"
    fi

    # SIEM
    info "Testing SIEM services..."

    if nc -zv "$SIEM_HOST" 514 2>&1 | grep -q "succeeded\|open"; then
        pass "Syslog (514)"
    else
        fail "Syslog (514)"
    fi

    # Monitoring
    info "Testing monitoring services..."

    if nc -zv "$MONITORING_HOST" 9090 2>&1 | grep -q "succeeded\|open"; then
        pass "Prometheus (9090)"
    else
        fail "Prometheus (9090)"
    fi

    if nc -zv "$MONITORING_HOST" 3000 2>&1 | grep -q "succeeded\|open"; then
        pass "Grafana (3000)"
    else
        fail "Grafana (3000)"
    fi
}

test_pam4ot_auth() {
    header "3. PAM4OT AUTHENTICATION TESTS"

    # Local admin auth
    info "Testing local admin authentication..."

    response=$(curl -sk -X POST "https://$PAM4OT_VIP/api/auth" \
        -H "Content-Type: application/json" \
        -d "{\"user\": \"$PAM4OT_ADMIN_USER\", \"password\": \"$PAM4OT_ADMIN_PASS\"}" 2>/dev/null)

    if echo "$response" | grep -q "token"; then
        pass "Local admin authentication"
        API_TOKEN=$(echo "$response" | grep -o '"token":"[^"]*' | cut -d'"' -f4)
        export API_TOKEN
    else
        fail "Local admin authentication"
        info "Response: $response"
    fi

    # LDAP auth
    info "Testing LDAP authentication..."

    response=$(curl -sk -X POST "https://$PAM4OT_VIP/api/auth" \
        -H "Content-Type: application/json" \
        -d "{\"user\": \"$PAM4OT_LDAP_USER\", \"password\": \"$PAM4OT_LDAP_PASS\"}" 2>/dev/null)

    if echo "$response" | grep -q "token"; then
        pass "LDAP authentication (jadmin)"
    else
        fail "LDAP authentication (jadmin)"
        info "Response: $response"
    fi

    # Invalid auth (should fail)
    info "Testing invalid authentication (should fail)..."

    response=$(curl -sk -X POST "https://$PAM4OT_VIP/api/auth" \
        -H "Content-Type: application/json" \
        -d '{"user": "baduser", "password": "badpass"}' 2>/dev/null)

    if echo "$response" | grep -qi "error\|invalid\|failed"; then
        pass "Invalid auth rejected correctly"
    else
        warn "Invalid auth may not be properly rejected"
    fi
}

test_web_ui() {
    header "4. WEB UI TESTS"

    info "Testing web UI accessibility..."

    http_code=$(curl -sk -o /dev/null -w "%{http_code}" "https://$PAM4OT_VIP/" 2>/dev/null)

    if [ "$http_code" == "200" ] || [ "$http_code" == "302" ]; then
        pass "Web UI accessible (HTTP $http_code)"
    else
        fail "Web UI not accessible (HTTP $http_code)"
    fi

    # Test both nodes directly
    for node in "$PAM4OT_NODE1" "$PAM4OT_NODE2"; do
        http_code=$(curl -sk -o /dev/null -w "%{http_code}" "https://$node/" 2>/dev/null)
        if [ "$http_code" == "200" ] || [ "$http_code" == "302" ]; then
            pass "Web UI on $node (HTTP $http_code)"
        else
            fail "Web UI on $node (HTTP $http_code)"
        fi
    done
}

test_cluster() {
    header "5. HA CLUSTER TESTS"

    info "Testing cluster status..."

    # Check both nodes are responding
    node1_up=$(curl -sk -o /dev/null -w "%{http_code}" "https://$PAM4OT_NODE1/" 2>/dev/null)
    node2_up=$(curl -sk -o /dev/null -w "%{http_code}" "https://$PAM4OT_NODE2/" 2>/dev/null)

    if [ "$node1_up" == "200" ] || [ "$node1_up" == "302" ]; then
        pass "Node 1 is responding"
    else
        fail "Node 1 is not responding"
    fi

    if [ "$node2_up" == "200" ] || [ "$node2_up" == "302" ]; then
        pass "Node 2 is responding"
    else
        fail "Node 2 is not responding"
    fi

    # Check VIP is responding
    vip_up=$(curl -sk -o /dev/null -w "%{http_code}" "https://$PAM4OT_VIP/" 2>/dev/null)

    if [ "$vip_up" == "200" ] || [ "$vip_up" == "302" ]; then
        pass "VIP ($PAM4OT_VIP) is responding"
    else
        fail "VIP ($PAM4OT_VIP) is not responding"
    fi
}

test_api() {
    header "6. API TESTS"

    if [ -z "$API_TOKEN" ]; then
        # Get token
        response=$(curl -sk -X POST "https://$PAM4OT_VIP/api/auth" \
            -H "Content-Type: application/json" \
            -d "{\"user\": \"$PAM4OT_ADMIN_USER\", \"password\": \"$PAM4OT_ADMIN_PASS\"}" 2>/dev/null)
        API_TOKEN=$(echo "$response" | grep -o '"token":"[^"]*' | cut -d'"' -f4)
    fi

    if [ -z "$API_TOKEN" ]; then
        fail "Could not obtain API token"
        return
    fi

    info "Testing API endpoints..."

    # Test status endpoint
    response=$(curl -sk "https://$PAM4OT_VIP/api/status" \
        -H "X-Auth-Token: $API_TOKEN" 2>/dev/null)

    if [ -n "$response" ]; then
        pass "API status endpoint"
    else
        fail "API status endpoint"
    fi

    # Test version endpoint
    response=$(curl -sk "https://$PAM4OT_VIP/api/version" \
        -H "X-Auth-Token: $API_TOKEN" 2>/dev/null)

    if [ -n "$response" ]; then
        pass "API version endpoint"
        info "Version: $(echo "$response" | head -c 100)"
    else
        fail "API version endpoint"
    fi
}

test_ssl() {
    header "7. SSL/TLS TESTS"

    info "Testing SSL certificate..."

    # Check certificate
    cert_info=$(echo | openssl s_client -connect "$PAM4OT_VIP:443" 2>/dev/null | openssl x509 -noout -dates 2>/dev/null)

    if [ -n "$cert_info" ]; then
        pass "SSL certificate is valid"
        info "Certificate dates: $cert_info"
    else
        fail "SSL certificate check failed"
    fi

    # Check TLS versions
    info "Testing TLS versions..."

    for version in tls1_2 tls1_3; do
        result=$(echo | openssl s_client -connect "$PAM4OT_VIP:443" -"$version" 2>&1)
        if echo "$result" | grep -q "Cipher is"; then
            pass "TLS $version supported"
        else
            info "TLS $version not supported"
        fi
    done

    # TLS 1.0 and 1.1 should NOT be supported
    for version in tls1 tls1_1; do
        result=$(echo | openssl s_client -connect "$PAM4OT_VIP:443" -"$version" 2>&1)
        if echo "$result" | grep -q "Cipher is"; then
            warn "TLS $version is supported (should be disabled)"
        else
            pass "TLS $version correctly disabled"
        fi
    done
}

test_monitoring() {
    header "8. MONITORING INTEGRATION TESTS"

    info "Testing Prometheus..."

    # Check Prometheus is up
    response=$(curl -s "http://$MONITORING_HOST:9090/-/healthy" 2>/dev/null)

    if [ "$response" == "Prometheus Server is Healthy." ]; then
        pass "Prometheus is healthy"
    else
        fail "Prometheus health check failed"
    fi

    # Check PAM4OT targets
    targets=$(curl -s "http://$MONITORING_HOST:9090/api/v1/targets" 2>/dev/null | grep -o '"health":"up"' | wc -l)

    if [ "$targets" -gt 0 ]; then
        pass "Prometheus has $targets healthy targets"
    else
        warn "No healthy Prometheus targets found"
    fi

    info "Testing Grafana..."

    response=$(curl -s "http://$MONITORING_HOST:3000/api/health" 2>/dev/null)

    if echo "$response" | grep -q "ok"; then
        pass "Grafana is healthy"
    else
        fail "Grafana health check failed"
    fi
}

test_siem() {
    header "9. SIEM INTEGRATION TESTS"

    info "Testing SIEM connectivity..."

    # Check syslog port
    if nc -zv "$SIEM_HOST" 514 2>&1 | grep -q "succeeded\|open"; then
        pass "SIEM syslog port (514) is open"
    else
        fail "SIEM syslog port (514) is not accessible"
    fi

    # Note: Actual log verification requires SIEM access
    info "Note: Verify logs are appearing in SIEM manually"
}

test_performance() {
    header "10. PERFORMANCE TESTS"

    info "Testing API response times..."

    # Auth endpoint timing
    auth_time=$(curl -sk -X POST "https://$PAM4OT_VIP/api/auth" \
        -H "Content-Type: application/json" \
        -d "{\"user\": \"$PAM4OT_ADMIN_USER\", \"password\": \"$PAM4OT_ADMIN_PASS\"}" \
        -o /dev/null -w "%{time_total}" 2>/dev/null)

    info "Authentication time: ${auth_time}s"

    if (( $(echo "$auth_time < 2.0" | bc -l) )); then
        pass "Authentication response time acceptable (${auth_time}s)"
    else
        warn "Authentication response time slow (${auth_time}s)"
    fi

    # Web UI timing
    ui_time=$(curl -sk "https://$PAM4OT_VIP/" -o /dev/null -w "%{time_total}" 2>/dev/null)

    info "Web UI load time: ${ui_time}s"

    if (( $(echo "$ui_time < 3.0" | bc -l) )); then
        pass "Web UI response time acceptable (${ui_time}s)"
    else
        warn "Web UI response time slow (${ui_time}s)"
    fi
}

generate_report() {
    header "TEST SUMMARY"

    local total_pass=$(grep -c "^PASS:" "$RESULTS_FILE" 2>/dev/null || echo 0)
    local total_fail=$(grep -c "^FAIL:" "$RESULTS_FILE" 2>/dev/null || echo 0)
    local total_warn=$(grep -c "^WARN:" "$RESULTS_FILE" 2>/dev/null || echo 0)
    local total=$((total_pass + total_fail + total_warn))

    echo ""
    echo "Results:"
    echo -e "  ${GREEN}PASSED:${NC}  $total_pass"
    echo -e "  ${RED}FAILED:${NC}  $total_fail"
    echo -e "  ${YELLOW}WARNINGS:${NC} $total_warn"
    echo "  ---------------"
    echo "  TOTAL:   $total"
    echo ""

    if [ "$total_fail" -gt 0 ]; then
        echo -e "${RED}OVERALL: FAILED${NC}"
        echo ""
        echo "Failed tests:"
        grep "^FAIL:" "$RESULTS_FILE" | sed 's/^FAIL: /  - /'
    elif [ "$total_warn" -gt 0 ]; then
        echo -e "${YELLOW}OVERALL: PASSED WITH WARNINGS${NC}"
    else
        echo -e "${GREEN}OVERALL: PASSED${NC}"
    fi

    echo ""
    echo "Full log: $LOG_FILE"
    echo "Results:  $RESULTS_FILE"
}

#------------------------------------------------------------------------------
# Main
#------------------------------------------------------------------------------

main() {
    echo ""
    echo "============================================================"
    echo "  PAM4OT Pre-Production Lab - Test Suite"
    echo "  $(date)"
    echo "============================================================"
    echo ""

    # Initialize results file
    echo "PAM4OT Test Results - $(date)" > "$RESULTS_FILE"
    echo "" >> "$RESULTS_FILE"

    # Run all tests
    test_connectivity
    test_ports
    test_pam4ot_auth
    test_web_ui
    test_cluster
    test_api
    test_ssl
    test_monitoring
    test_siem
    test_performance

    # Generate report
    generate_report
}

# Run specific test or all
case "${1:-all}" in
    connectivity)   test_connectivity ;;
    ports)          test_ports ;;
    auth)           test_pam4ot_auth ;;
    web)            test_web_ui ;;
    cluster)        test_cluster ;;
    api)            test_api ;;
    ssl)            test_ssl ;;
    monitoring)     test_monitoring ;;
    siem)           test_siem ;;
    performance)    test_performance ;;
    all|*)          main ;;
esac
