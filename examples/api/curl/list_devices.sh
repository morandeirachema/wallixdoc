#!/bin/bash
#
# List all devices from WALLIX Bastion using curl
#
# Usage:
#   export BASTION_HOST="bastion.example.com"
#   export BASTION_USER="admin"
#   export BASTION_API_KEY="your-api-key"
#   ./list_devices.sh
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
    echo "Usage:"
    echo "  export BASTION_HOST='bastion.example.com'"
    echo "  export BASTION_USER='admin'"
    echo "  export BASTION_API_KEY='your-api-key'"
    echo "  ./list_devices.sh"
    exit 1
fi

# Build authentication header
AUTH=$(echo -n "${BASTION_USER}:${BASTION_API_KEY}" | base64)

# API endpoint
URL="https://${BASTION_HOST}/api/${API_VERSION}/devices"

echo "Fetching devices from ${BASTION_HOST}..."
echo ""

# Make request
curl -s -k \
    -H "Authorization: Basic ${AUTH}" \
    -H "Accept: application/json" \
    "${URL}" | python3 -m json.tool

echo ""
echo "Done."
