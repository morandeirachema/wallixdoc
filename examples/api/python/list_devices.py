#!/usr/bin/env python3
"""
List all devices from WALLIX Bastion.

Usage:
    export BASTION_HOST="bastion.example.com"
    export BASTION_USER="admin"
    export BASTION_API_KEY="your-api-key"
    python list_devices.py
"""

import os
import sys
from bastion_client import BastionClient


def main():
    # Get credentials from environment
    host = os.getenv("BASTION_HOST")
    username = os.getenv("BASTION_USER")
    api_key = os.getenv("BASTION_API_KEY")

    if not all([host, username, api_key]):
        print("Error: Set environment variables:")
        print("  BASTION_HOST - Bastion hostname")
        print("  BASTION_USER - API username")
        print("  BASTION_API_KEY - API key")
        sys.exit(1)

    # Create client
    client = BastionClient(
        host=host,
        username=username,
        api_key=api_key,
        verify_ssl=False  # Set to True for production with valid certs
    )

    # Fetch and display devices
    print("WALLIX Bastion Devices")
    print("=" * 60)

    devices = client.get_devices()

    if not devices:
        print("No devices found.")
        return

    # Header
    print(f"{'Device Name':<25} {'Host':<20} {'Description'}")
    print("-" * 60)

    # List devices
    for device in devices:
        name = device.get("device_name", "N/A")[:25]
        host = device.get("host", "N/A")[:20]
        desc = device.get("description", "")[:30]
        print(f"{name:<25} {host:<20} {desc}")

    print("-" * 60)
    print(f"Total: {len(devices)} devices")


if __name__ == "__main__":
    main()
