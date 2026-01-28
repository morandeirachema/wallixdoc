#!/bin/bash
#
# Get WALLIX Bastion status using curl
#
# Usage:
#   export BASTION_HOST="bastion.example.com"
#   export BASTION_USER="admin"
#   export BASTION_API_KEY="your-api-key"
#   ./get_status.sh
#

set -e

# Configuration
BASTION_HOST="${BASTION_HOST:-bastion.example.com}"
BASTION_USER="${BASTION_USER:-admin}"
BASTION_API_KEY="${BASTION_API_KEY:-}"
API_VERSION="${API_VERSION:-v3.12}"

# Check required variables
if [ -z "$BASTION_API_KEY" ]; then
    echo "Error: BASTION_API_KEY not set"
    exit 1
fi

# Build authentication header
AUTH=$(echo -n "${BASTION_USER}:${BASTION_API_KEY}" | base64)

echo "WALLIX Bastion Status"
echo "====================="
echo "Host: ${BASTION_HOST}"
echo ""

# Get status
curl -s -k \
    -H "Authorization: Basic ${AUTH}" \
    -H "Accept: application/json" \
    "https://${BASTION_HOST}/api/${API_VERSION}/status" | python3 -m json.tool

echo ""

# Get license info
echo "License Information"
echo "==================="
curl -s -k \
    -H "Authorization: Basic ${AUTH}" \
    -H "Accept: application/json" \
    "https://${BASTION_HOST}/api/${API_VERSION}/license" | python3 -m json.tool
