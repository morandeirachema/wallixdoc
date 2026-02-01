#!/usr/bin/env python3
"""
Custom Ansible filters for WALLIX Bastion automation.
Place in filter_plugins/ directory.
"""


def wallix_service_parse(service_string):
    """
    Parse service string "SSH:22" to dict format.

    Args:
        service_string: Format "NAME:PORT" or "NAME:PORT:PROTOCOL"

    Returns:
        dict: {"name": "SSH", "port": 22, "protocol": "SSH"}
    """
    if not service_string or not isinstance(service_string, str):
        return None

    parts = service_string.strip().split(':')
    if len(parts) < 2:
        return None

    name = parts[0].strip()
    try:
        port = int(parts[1].strip())
    except ValueError:
        return None

    # Default protocol mappings
    protocol_map = {
        'SSH': 'SSH',
        'RDP': 'RDP',
        'VNC': 'VNC',
        'HTTP': 'RAWTCPIP',
        'HTTPS': 'RAWTCPIP',
        'Modbus': 'RAWTCPIP',
        'PostgreSQL': 'RAWTCPIP',
        'MySQL': 'RAWTCPIP',
        'WinRM': 'RAWTCPIP',
    }

    protocol = parts[2].strip() if len(parts) > 2 else protocol_map.get(name, 'RAWTCPIP')

    return {
        'name': name,
        'port': port,
        'protocol': protocol
    }


def wallix_device_format(cmdb_record, field_mapping=None):
    """
    Transform CMDB record to WALLIX device format.

    Args:
        cmdb_record: Dict from CMDB (ServiceNow, CSV, etc.)
        field_mapping: Dict mapping CMDB fields to WALLIX fields

    Returns:
        dict: WALLIX device format
    """
    default_mapping = {
        'device_name': ['name', 'host_name', 'hostname', 'asset_tag'],
        'host': ['ip_address', 'fqdn', 'dns_name'],
        'description': ['short_description', 'description', 'comments'],
        'domain': ['environment', 'u_environment', 'category'],
    }

    mapping = field_mapping or default_mapping

    def get_field(record, field_names):
        """Get first matching field from record."""
        if isinstance(field_names, str):
            field_names = [field_names]
        for field in field_names:
            if field in record and record[field]:
                return record[field]
        return None

    device_name = get_field(cmdb_record, mapping['device_name'])
    if not device_name:
        return None

    # Sanitize device name
    import re
    device_name = re.sub(r'[^a-zA-Z0-9-]', '-', device_name.lower())

    return {
        'device_name': device_name,
        'host': get_field(cmdb_record, mapping['host']) or '',
        'description': get_field(cmdb_record, mapping['description']) or '',
        'domain': get_field(cmdb_record, mapping['domain']) or 'Default',
    }


def wallix_normalize_name(name, max_length=64):
    """
    Normalize name for WALLIX (lowercase, alphanumeric, hyphens only).

    Args:
        name: Input name string
        max_length: Maximum length (default 64)

    Returns:
        str: Normalized name
    """
    import re
    if not name:
        return ''

    # Convert to lowercase
    normalized = name.lower()

    # Replace spaces and underscores with hyphens
    normalized = re.sub(r'[\s_]+', '-', normalized)

    # Remove any character that's not alphanumeric or hyphen
    normalized = re.sub(r'[^a-z0-9-]', '', normalized)

    # Collapse multiple hyphens
    normalized = re.sub(r'-+', '-', normalized)

    # Remove leading/trailing hyphens
    normalized = normalized.strip('-')

    # Truncate if needed
    return normalized[:max_length]


def wallix_services_from_os(os_type):
    """
    Return default services based on OS type.

    Args:
        os_type: OS type string (linux, windows, etc.)

    Returns:
        list: List of service dicts
    """
    os_services = {
        'linux': [
            {'name': 'SSH', 'port': 22, 'protocol': 'SSH'}
        ],
        'windows': [
            {'name': 'RDP', 'port': 3389, 'protocol': 'RDP'},
            {'name': 'WinRM', 'port': 5985, 'protocol': 'RAWTCPIP'}
        ],
        'network': [
            {'name': 'SSH', 'port': 22, 'protocol': 'SSH'}
        ],
        'database': [
            {'name': 'SSH', 'port': 22, 'protocol': 'SSH'}
        ],
    }

    if not os_type:
        return os_services['linux']

    os_lower = os_type.lower()

    for key, services in os_services.items():
        if key in os_lower:
            return services

    # Check for specific OS names
    if any(x in os_lower for x in ['ubuntu', 'debian', 'centos', 'rhel', 'redhat']):
        return os_services['linux']
    if any(x in os_lower for x in ['windows', 'win']):
        return os_services['windows']
    if any(x in os_lower for x in ['cisco', 'juniper', 'fortinet']):
        return os_services['network']

    return os_services['linux']


class FilterModule:
    """Ansible filter module for WALLIX Bastion."""

    def filters(self):
        return {
            'wallix_service_parse': wallix_service_parse,
            'wallix_device_format': wallix_device_format,
            'wallix_normalize_name': wallix_normalize_name,
            'wallix_services_from_os': wallix_services_from_os,
        }
