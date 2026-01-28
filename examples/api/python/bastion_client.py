#!/usr/bin/env python3
"""
WALLIX Bastion REST API Client

A reusable Python client for interacting with the WALLIX Bastion REST API.
Based on patterns from: https://github.com/wallix/wbrest_samples

Usage:
    from bastion_client import BastionClient

    client = BastionClient(
        host="bastion.example.com",
        username="admin",
        api_key="your-api-key"
    )

    devices = client.get_devices()
"""

import requests
import urllib3
from typing import Optional, Dict, List, Any
from base64 import b64encode

# Disable SSL warnings for self-signed certificates (not recommended for production)
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


class BastionClient:
    """WALLIX Bastion REST API client."""

    def __init__(
        self,
        host: str,
        username: str,
        api_key: str,
        api_version: str = "v3.12",
        port: int = 443,
        verify_ssl: bool = True
    ):
        """
        Initialize the Bastion API client.

        Args:
            host: Bastion hostname or IP address
            username: Username for API authentication
            api_key: API key (generated in Bastion admin console)
            api_version: API version (default: v3.12)
            port: HTTPS port (default: 443)
            verify_ssl: Verify SSL certificates (default: True)
        """
        self.base_url = f"https://{host}:{port}/api/{api_version}"
        self.verify_ssl = verify_ssl

        # Prepare authentication header
        credentials = f"{username}:{api_key}"
        encoded = b64encode(credentials.encode()).decode()
        self.headers = {
            "Authorization": f"Basic {encoded}",
            "Content-Type": "application/json",
            "Accept": "application/json"
        }

    def _request(
        self,
        method: str,
        endpoint: str,
        data: Optional[Dict] = None,
        params: Optional[Dict] = None
    ) -> Dict[str, Any]:
        """
        Make an API request.

        Args:
            method: HTTP method (GET, POST, PUT, DELETE)
            endpoint: API endpoint (e.g., "/devices")
            data: Request body (for POST/PUT)
            params: Query parameters

        Returns:
            Response JSON as dictionary
        """
        url = f"{self.base_url}{endpoint}"

        response = requests.request(
            method=method,
            url=url,
            headers=self.headers,
            json=data,
            params=params,
            verify=self.verify_ssl
        )

        response.raise_for_status()

        if response.content:
            return response.json()
        return {}

    # -------------------------------------------------------------------------
    # Device Operations
    # -------------------------------------------------------------------------

    def get_devices(self, limit: int = 100, offset: int = 0) -> List[Dict]:
        """Get list of devices."""
        params = {"limit": limit, "offset": offset}
        result = self._request("GET", "/devices", params=params)
        return result.get("data", [])

    def get_device(self, device_id: str) -> Dict:
        """Get a specific device by ID."""
        return self._request("GET", f"/devices/{device_id}")

    def create_device(
        self,
        device_name: str,
        host: str,
        description: str = ""
    ) -> Dict:
        """Create a new device."""
        data = {
            "device_name": device_name,
            "host": host,
            "description": description
        }
        return self._request("POST", "/devices", data=data)

    def delete_device(self, device_id: str) -> None:
        """Delete a device."""
        self._request("DELETE", f"/devices/{device_id}")

    # -------------------------------------------------------------------------
    # User Operations
    # -------------------------------------------------------------------------

    def get_users(self, limit: int = 100, offset: int = 0) -> List[Dict]:
        """Get list of users."""
        params = {"limit": limit, "offset": offset}
        result = self._request("GET", "/users", params=params)
        return result.get("data", [])

    def get_user(self, user_name: str) -> Dict:
        """Get a specific user by name."""
        return self._request("GET", f"/users/{user_name}")

    # -------------------------------------------------------------------------
    # Session Operations
    # -------------------------------------------------------------------------

    def get_sessions(
        self,
        status: str = "current",
        limit: int = 100,
        offset: int = 0
    ) -> List[Dict]:
        """
        Get sessions.

        Args:
            status: Session status ("current", "closed", "all")
            limit: Maximum results
            offset: Pagination offset
        """
        params = {"status": status, "limit": limit, "offset": offset}
        result = self._request("GET", "/sessions", params=params)
        return result.get("data", [])

    def kill_session(self, session_id: str) -> None:
        """Terminate an active session."""
        self._request("DELETE", f"/sessions/{session_id}")

    # -------------------------------------------------------------------------
    # Authorization Operations
    # -------------------------------------------------------------------------

    def get_authorizations(self, limit: int = 100, offset: int = 0) -> List[Dict]:
        """Get list of authorizations."""
        params = {"limit": limit, "offset": offset}
        result = self._request("GET", "/authorizations", params=params)
        return result.get("data", [])

    # -------------------------------------------------------------------------
    # Approval Operations
    # -------------------------------------------------------------------------

    def get_approvals(
        self,
        status: str = "pending",
        limit: int = 100
    ) -> List[Dict]:
        """
        Get approval requests.

        Args:
            status: Approval status ("pending", "accepted", "rejected", "all")
        """
        params = {"status": status, "limit": limit}
        result = self._request("GET", "/approvals", params=params)
        return result.get("data", [])

    def approve_request(self, approval_id: str, comment: str = "") -> Dict:
        """Approve an access request."""
        data = {"action": "accept", "comment": comment}
        return self._request("PUT", f"/approvals/{approval_id}", data=data)

    def reject_request(self, approval_id: str, comment: str = "") -> Dict:
        """Reject an access request."""
        data = {"action": "reject", "comment": comment}
        return self._request("PUT", f"/approvals/{approval_id}", data=data)

    # -------------------------------------------------------------------------
    # Target Group Operations
    # -------------------------------------------------------------------------

    def get_targetgroups(self, limit: int = 100, offset: int = 0) -> List[Dict]:
        """Get list of target groups."""
        params = {"limit": limit, "offset": offset}
        result = self._request("GET", "/targetgroups", params=params)
        return result.get("data", [])

    # -------------------------------------------------------------------------
    # Health and Status
    # -------------------------------------------------------------------------

    def get_status(self) -> Dict:
        """Get Bastion status."""
        return self._request("GET", "/status")

    def get_license(self) -> Dict:
        """Get license information."""
        return self._request("GET", "/license")


# =============================================================================
# Example Usage
# =============================================================================
if __name__ == "__main__":
    import os

    # Get credentials from environment
    host = os.getenv("BASTION_HOST", "bastion.example.com")
    username = os.getenv("BASTION_USER", "admin")
    api_key = os.getenv("BASTION_API_KEY", "")

    if not api_key:
        print("Error: Set BASTION_API_KEY environment variable")
        exit(1)

    # Create client
    client = BastionClient(
        host=host,
        username=username,
        api_key=api_key,
        verify_ssl=False  # Set to True for production
    )

    # Example: List devices
    print("Devices:")
    print("-" * 40)
    for device in client.get_devices():
        print(f"  {device.get('device_name')}: {device.get('host')}")

    # Example: List active sessions
    print("\nActive Sessions:")
    print("-" * 40)
    for session in client.get_sessions(status="current"):
        print(f"  {session.get('user')}: {session.get('target')}")
