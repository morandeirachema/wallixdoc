# 01 - Introduction to WALLIX PAM

## Table of Contents

1. [Company Overview](#company-overview)
2. [Product Portfolio](#product-portfolio)
3. [Market Positioning](#market-positioning)
4. [WALLIX vs CyberArk Overview](#wallix-vs-cyberark-overview)
5. [Licensing Model](#licensing-model)
6. [Certifications & Compliance](#certifications--compliance)

---

## Company Overview

### About WALLIX

**WALLIX** is a European cybersecurity company founded in **2003** and headquartered in **Paris, France**. The company specializes in Privileged Access Management (PAM) and Identity & Access Governance solutions.

### Key Facts

| Attribute | Detail |
|-----------|--------|
| **Founded** | 2003 |
| **Headquarters** | Paris, France |
| **Stock Exchange** | Euronext Paris (ALLIX) |
| **Employees** | 200+ |
| **Customers** | 2,000+ worldwide |
| **Market Focus** | Enterprise PAM, OT Security, Cloud Security |

### Geographic Presence

- **Strong presence**: Europe (France, Germany, UK, Benelux, Nordics)
- **Growing presence**: Middle East, Africa, Asia-Pacific
- **Americas**: Partner-led expansion

### Industry Recognition

- **Gartner Magic Quadrant**: Recognized in PAM Magic Quadrant
- **KuppingerCole**: Leadership Compass recognition
- **Forrester**: Included in PAM Wave reports

---

## Product Portfolio

### WALLIX Bastion

The **flagship PAM platform** providing comprehensive privileged access management.

```
+-------------------------------------------------------------+
|                     WALLIX BASTION                          |
+-------------------------------------------------------------+
|                                                             |
|  +-----------------+    +-----------------+                |
|  |  SESSION        |    |  PASSWORD       |                |
|  |  MANAGER        |    |  MANAGER        |                |
|  |                 |    |                 |                |
|  |  * Proxy-based  |    |  * Credential   |                |
|  |  * Recording    |    |    Vault        |                |
|  |  * Monitoring   |    |  * Rotation     |                |
|  |  * Audit        |    |  * Injection    |                |
|  +-----------------+    +-----------------+                |
|                                                             |
|  Protocols: RDP | SSH | HTTPS | VNC | Telnet | Custom      |
|                                                             |
+-------------------------------------------------------------+
```

**Key Capabilities:**
- Privileged session management and recording
- Credential vaulting and automatic rotation
- Real-time session monitoring and termination
- Comprehensive audit trail
- Multi-protocol support

---

### WALLIX PAM4OT (This Documentation)

**Privileged Access Management for Operational Technology** — WALLIX's unified PAM solution specifically designed for OT/industrial environments.

```
+-------------------------------------------------------------+
|                      WALLIX PAM4OT                          |
|              (Built on WALLIX Bastion Technology)           |
+-------------------------------------------------------------+
|                                                             |
|  +-------------------+    +-------------------+             |
|  | SECURE REMOTE     |    | JUST-IN-TIME      |             |
|  | ACCESS            |    | ACCESS            |             |
|  |                   |    |                   |             |
|  | * VPN-less access |    | * Approval        |             |
|  | * Vendor access   |    |   workflows       |             |
|  | * Browser-based   |    | * Time-limited    |             |
|  +-------------------+    +-------------------+             |
|                                                             |
|  +-------------------+    +-------------------+             |
|  | SESSION           |    | PASSWORD          |             |
|  | RECORDING         |    | MANAGEMENT        |             |
|  |                   |    |                   |             |
|  | * Full audit      |    | * Credential      |             |
|  | * Compliance      |    |   vault           |             |
|  | * Forensics       |    | * Least privilege |             |
|  +-------------------+    +-------------------+             |
|                                                             |
|  Industrial Protocols: Modbus | OPC UA | S7comm | DNP3      |
|  Standard Protocols:   RDP | SSH | VNC | HTTPS | Telnet     |
|                                                             |
+-------------------------------------------------------------+
```

**Key Features:**
- **Secure Remote Access**: VPN-less access for vendors and administrators
- **Strong Authentication**: MFA to prevent account takeover
- **Just-In-Time Access**: Privileges granted only when needed
- **Session Recording**: Full audit trail for compliance (IEC 62443, NIST 800-82)
- **Password Management**: Automated rotation, credential injection
- **Least Privilege**: Minimize standing privileged access

**Target Industries:**
- Industrial manufacturing
- Critical infrastructure (power, water, oil & gas)
- Smart cities and infrastructure
- Healthcare facilities

> **Product Website**: https://www.wallix.com/ot-security/ot-products/ot-pam4ot/

---

### WALLIX Inside

**Embedded OT Security** — White-label security technology for OEM integration.

**Features:**
- Plug & play secure connectivity for industrial systems
- Password and access management embedded in vendor products
- Security-by-design for industrial equipment manufacturers

> **Product Website**: https://www.wallix.com/ot-security/ot-products/ot-wallix-inside/

---

### WALLIX Access Manager

**Web-based access portal** providing clientless HTML5 access to privileged sessions.

**Features:**
- Browser-based RDP/SSH/VNC sessions
- No client software required
- Mobile device support
- Customizable portal interface
- SSO integration

**CyberArk Equivalent**: PVWA + PSM for Web

---

### WALLIX PEDM (Privilege Elevation & Delegation Management)

**Endpoint privilege management** for workstations and servers.

**Capabilities:**
- Just-in-time privilege elevation
- Application control
- Least privilege enforcement
- Session recording at endpoint level

**CyberArk Equivalent**: Endpoint Privilege Manager (EPM)

---

### WALLIX Trustelem

**Identity-as-a-Service (IDaaS)** platform for identity management and SSO.

**Features:**
- Single Sign-On (SSO)
- Multi-Factor Authentication (MFA)
- User lifecycle management
- Directory synchronization
- Application provisioning

**CyberArk Equivalent**: CyberArk Identity (formerly Idaptive)

---

### WALLIX BestSafe

**Endpoint Protection Platform** integrated with PAM capabilities.

**Features:**
- Privilege management for endpoints
- Application control
- Anti-ransomware protection

---

### Product Integration Matrix

```
+--------------+     +--------------+     +--------------+
|   WALLIX     |     |   WALLIX     |     |   WALLIX     |
|  Trustelem   |---->|   Bastion    |---->|    PEDM      |
|   (IDaaS)    |     |    (PAM)     |     |  (Endpoint)  |
+--------------+     +--------------+     +--------------+
       |                    |                    |
       |                    |                    |
       v                    v                    v
   +-------------------------------------------------+
   |              Unified Security Platform          |
   |                                                 |
   |  * Single pane of glass                        |
   |  * Consistent policy enforcement               |
   |  * End-to-end audit trail                      |
   +-------------------------------------------------+
```

---

## Market Positioning

### Target Markets

| Segment | Focus |
|---------|-------|
| **Enterprise** | Large-scale deployments, complex environments |
| **Mid-Market** | Growing organizations, compliance requirements |
| **OT/ICS** | Industrial environments, critical infrastructure |
| **Cloud** | Multi-cloud, hybrid environments |
| **MSP/MSSP** | Multi-tenant service providers |

### Competitive Advantages

1. **European Origin**
   - GDPR-native design
   - Data sovereignty compliance
   - ANSSI certification (French government)

2. **Simplified Architecture**
   - Single appliance deployment
   - Proxy-based (no agents on targets)
   - Faster time-to-value

3. **OT/ICS Focus**
   - Industrial protocol support
   - Air-gapped environment capabilities
   - OT-specific partnerships

4. **Total Cost of Ownership**
   - Simpler licensing
   - Reduced infrastructure requirements
   - Lower operational overhead

---

## WALLIX vs CyberArk Overview

### Philosophical Differences

| Aspect | CyberArk | WALLIX |
|--------|----------|--------|
| **Architecture** | Agent-based session management | Proxy-based session management |
| **Deployment** | Multiple components | Unified appliance |
| **Vault Design** | Proprietary file system | Database-backed (PostgreSQL)  |
| **Market Origin** | Israel/US | European (France) |
| **Primary Focus** | Enterprise secrets & PAM | PAM with OT/industrial focus |

### Component Mapping

| Function | CyberArk Component | WALLIX Component |
|----------|-------------------|------------------|
| Session Management | PSM (Privileged Session Manager) | Session Manager |
| Credential Vault | Digital Vault | Password Manager |
| Web Interface | PVWA | Access Manager / Web UI |
| Password Rotation | CPM (Central Policy Manager) | Password Manager |
| Endpoint Privilege | EPM | PEDM |
| Identity Management | CyberArk Identity | Trustelem |
| Discovery | Account Discovery | Discovery (built-in) |
| Threat Analytics | PTA | Audit & Analytics |

### Terminology Translation

| CyberArk | WALLIX | Notes |
|----------|--------|-------|
| Safe | Domain | Logical container |
| Platform | Device + Service | Target definition |
| Account | Account | Same concept |
| CPM Policy | Password Policy | Rotation rules |
| Connection Component | Protocol | Connection method |
| PSM Server | Bastion (Proxy) | Session broker |
| Master Policy | Global Settings | Default behaviors |
| Safe Member | Authorization | Access grant |
| Dual Control | Approval Workflow | 4-eyes principle |
| Recording | Session Recording | Same concept |

---

## Licensing Model

### WALLIX Licensing Structure

WALLIX uses a **modular licensing** approach:

```
+-------------------------------------------------------------+
|                    LICENSING MODEL                          |
+-------------------------------------------------------------+
|                                                             |
|  BASE LICENSE (Required)                                    |
|  +-- Session Manager                                        |
|  +-- Based on: Named Users OR Concurrent Sessions           |
|                                                             |
|  OPTIONAL MODULES                                           |
|  +-- Password Manager (credential vaulting & rotation)      |
|  +-- Access Manager (HTML5 web portal)                      |
|  +-- PEDM (endpoint privilege management)                   |
|  +-- High Availability                                      |
|                                                             |
+-------------------------------------------------------------+
```

### License Metrics

| Metric | Description | Best For |
|--------|-------------|----------|
| **Named Users** | Specific user count | Predictable user base |
| **Concurrent Sessions** | Simultaneous connections | Variable user base |
| **Managed Targets** | Number of target systems | Large target environments |

### Comparison with CyberArk Licensing

| Aspect | CyberArk | WALLIX |
|--------|----------|--------|
| **Base Metric** | User + Target based | User OR Session based |
| **Component Licensing** | Separate per component | Modular add-ons |
| **HA/DR** | Separate licensing | Often included or add-on |
| **Complexity** | More complex | Generally simpler |

> **Tip**: WALLIX licensing is typically more straightforward, but always validate specific requirements with WALLIX sales for accurate sizing.

---

## Certifications & Compliance

### Security Certifications

| Certification | Description | Significance |
|--------------|-------------|--------------|
| **ANSSI CSPN** | French National Cybersecurity Agency certification | Required for French government |
| **Common Criteria EAL3+** | International security certification | Global recognition |
| **ISO 27001** | Information security management | Company-level compliance |

### Compliance Framework Support

WALLIX Bastion provides audit capabilities supporting:

| Framework | Region | Key Requirements Addressed |
|-----------|--------|---------------------------|
| **GDPR** | EU | Data access logging, consent management |
| **NIS/NIS2** | EU | Critical infrastructure protection |
| **PCI-DSS** | Global | Requirement 7, 8, 10 (access control, audit) |
| **SOX** | US | IT controls, segregation of duties |
| **HIPAA** | US | PHI access controls |
| **SOC 2** | Global | Security, availability, confidentiality |
| **IEC 62443** | Industrial | OT/ICS security |

### Industry-Specific Certifications

- **Banking/Finance**: Support for EBA guidelines, DORA
- **Healthcare**: HIPAA-ready configurations
- **Industrial**: IEC 62443 alignment
- **Government**: ANSSI qualification (France), various national standards

---

## Next Steps

Continue to [02 - Architecture](../02-architecture/README.md) for deep dive into WALLIX technical architecture.
