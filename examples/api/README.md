# WALLIX Bastion REST API Examples

This directory contains examples for interacting with the WALLIX Bastion REST API.

## API Overview

WALLIX Bastion provides a comprehensive REST API for automation and integration. The API supports:

- User and group management
- Device and account management
- Authorization configuration
- Session monitoring
- Approval workflows
- Password operations

## Authentication

### API Key Generation

1. Log into WALLIX Bastion admin console
2. Navigate to **Configuration** → **API Keys**
3. Click **Add** to create a new API key
4. Optionally restrict to specific IP addresses
5. Save the generated key securely

### Using API Keys

Include the API key in request headers:

```http
Authorization: Basic base64(username:api_key)
```

Or use query parameter (less secure):

```http
GET /api/v3.12/resource?_auth=username:api_key
```

## API Versions

| API Version | WALLIX Bastion | Status |
|-------------|----------------|--------|
| v3.12 | 12.x | Current |
| v3.6 | 11.x | Supported |
| v3.3 | 10.x | Legacy |
| v2.x | < 10.x | Deprecated |

## Base URL

```
https://<bastion-host>/api/<version>/
```

Example:
```
https://bastion.example.com/api/v3.12/
```

## Common Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/devices` | GET | List all devices |
| `/devices/{id}` | GET | Get device details |
| `/devices` | POST | Create device |
| `/users` | GET | List users |
| `/usergroups` | GET | List user groups |
| `/targetgroups` | GET | List target groups |
| `/authorizations` | GET | List authorizations |
| `/sessions` | GET | List active sessions |
| `/approvals` | GET | List pending approvals |
| `/accounts` | GET | List accounts |

## Response Format

All responses are JSON:

```json
{
  "data": [...],
  "total": 100,
  "offset": 0,
  "limit": 50
}
```

## Error Handling

Error responses include:

```json
{
  "error": "error_code",
  "message": "Human-readable description"
}
```

Common HTTP status codes:
- `200` - Success
- `201` - Created
- `400` - Bad request
- `401` - Authentication failed
- `403` - Forbidden (insufficient permissions)
- `404` - Resource not found
- `500` - Server error

## Examples

### Python

See `python/` directory for complete examples:

- `list_devices.py` - List all devices
- `create_device.py` - Create a new device
- `get_sessions.py` - Get active sessions
- `bastion_client.py` - Reusable API client class

### curl

See `curl/` directory for shell script examples:

- `get_status.sh` - Check API status
- `list_devices.sh` - List devices
- `create_device.sh` - Create device

## Rate Limiting

The API may enforce rate limits. Handle `429 Too Many Requests` responses:

```python
if response.status_code == 429:
    retry_after = int(response.headers.get('Retry-After', 60))
    time.sleep(retry_after)
    # Retry request
```

## Resources

- [Official API Samples](https://github.com/wallix/wbrest_samples)
- [SCIM API Documentation](https://scim.wallix.com/scim/doc/Usage.html)
- [Terraform Provider](https://registry.terraform.io/providers/wallix/wallix-bastion) (uses API internally)
