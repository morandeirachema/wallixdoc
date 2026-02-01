# 64 - Historian and Data Historian Access Patterns

## Table of Contents

1. [Historian Overview](#historian-overview)
2. [Historian Architecture](#historian-architecture)
3. [OSIsoft PI Access](#osisoft-pi-access)
4. [Wonderware/AVEVA Historian](#wonderwareaveva-historian)
5. [GE Proficy Historian](#ge-proficy-historian)
6. [Honeywell PHD](#honeywell-phd)
7. [Access Control Patterns](#access-control-patterns)
8. [Credential Management](#credential-management)
9. [Session Recording](#session-recording)
10. [Data Protection](#data-protection)
11. [Integration with Analytics](#integration-with-analytics)
12. [Compliance](#compliance)

---

## Historian Overview

### What Historians Do

```
+===============================================================================+
|                    HISTORIAN SYSTEM OVERVIEW                                  |
+===============================================================================+

  PURPOSE AND FUNCTION
  ====================

  Process historians (data historians) are specialized databases designed
  to collect, store, and retrieve time-series data from industrial processes.

  +------------------------------------------------------------------------+
  |                                                                        |
  |  KEY FUNCTIONS                                                         |
  |  =============                                                         |
  |                                                                        |
  |  * Data Collection: Gather values from PLCs, DCS, SCADA systems       |
  |  * Time-Series Storage: Optimize storage of timestamped values        |
  |  * Compression: Reduce storage through intelligent algorithms         |
  |  * Data Retrieval: Fast queries for trends, reports, analysis         |
  |  * Event Storage: Capture alarms, events, operator actions            |
  |  * Calculations: Perform aggregations, statistics on stored data      |
  |                                                                        |
  +------------------------------------------------------------------------+

  ---------------------------------------------------------------------------

  DATA SENSITIVITY
  ================

  +------------------------------------------------------------------------+
  |                                                                        |
  |  CRITICAL: Historian data reveals sensitive operational information   |
  |                                                                        |
  |  +------------------------------------------------------------------+  |
  |  | Data Type           | Sensitivity             | Risk if Exposed   |  |
  |  +---------------------+-------------------------+-------------------+  |
  |  | Production rates    | Trade secret            | Competitive loss  |  |
  |  | Process parameters  | Proprietary knowledge   | IP theft          |  |
  |  | Energy consumption  | Cost structure          | Pricing intel     |  |
  |  | Quality metrics     | Product performance     | Reputation damage |  |
  |  | Equipment health    | Maintenance strategy    | Sabotage planning |  |
  |  | Batch recipes       | Manufacturing IP        | Product copying   |  |
  |  | Alarm patterns      | System vulnerabilities  | Attack planning   |  |
  |  +---------------------+-------------------------+-------------------+  |
  |                                                                        |
  +------------------------------------------------------------------------+

  ---------------------------------------------------------------------------

  ACCESS RISKS
  ============

  +------------------------------------------------------------------------+
  |                                                                        |
  |  UNAUTHORIZED ACCESS SCENARIOS                                         |
  |                                                                        |
  |  1. DATA EXFILTRATION                                                  |
  |     - Bulk export of production data                                   |
  |     - Extraction of process parameters                                 |
  |     - Recipe and formula theft                                         |
  |                                                                        |
  |  2. RECONNAISSANCE                                                     |
  |     - Understanding system behavior for attack planning                |
  |     - Identifying peak/low activity periods                            |
  |     - Mapping process dependencies                                     |
  |                                                                        |
  |  3. DATA MANIPULATION                                                  |
  |     - Altering historical records (compliance fraud)                   |
  |     - Hiding evidence of process deviations                            |
  |     - Falsifying quality records                                       |
  |                                                                        |
  |  4. SYSTEM COMPROMISE                                                  |
  |     - Historian as pivot point to control systems                      |
  |     - Credential harvesting from historian connections                 |
  |     - Malware deployment via historian client tools                    |
  |                                                                        |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### Major Historian Platforms

```
+===============================================================================+
|                    MAJOR HISTORIAN PLATFORMS                                  |
+===============================================================================+

  MARKET LEADERS
  ==============

  +------------------------------------------------------------------------+
  |                                                                        |
  |  +--------------------------+----------------------------------------+  |
  |  | Platform                 | Vendor/Details                         |  |
  |  +--------------------------+----------------------------------------+  |
  |  | OSIsoft PI System        | Now part of AVEVA (acquired 2020)      |  |
  |  |                          | Market leader, 90%+ of Fortune 500     |  |
  |  |                          | Used in oil/gas, power, manufacturing  |  |
  |  +--------------------------+----------------------------------------+  |
  |  | AVEVA Historian          | Formerly Wonderware InSQL Historian    |  |
  |  |                          | Strong in discrete manufacturing       |  |
  |  |                          | SQL Server based                        |  |
  |  +--------------------------+----------------------------------------+  |
  |  | GE Proficy Historian     | GE Digital (formerly GE Fanuc)         |  |
  |  |                          | Strong in utilities, manufacturing     |  |
  |  |                          | Part of Proficy suite                  |  |
  |  +--------------------------+----------------------------------------+  |
  |  | Honeywell PHD            | Process History Database               |  |
  |  |                          | Strong in refining, petrochemicals     |  |
  |  |                          | Part of Experion PKS                   |  |
  |  +--------------------------+----------------------------------------+  |
  |  | Aspen InfoPlus.21        | AspenTech (now Emerson)                |  |
  |  |                          | Strong in chemicals, pharmaceuticals   |  |
  |  |                          | Advanced analytics integration         |  |
  |  +--------------------------+----------------------------------------+  |
  |  | Rockwell FactoryTalk     | Rockwell Automation                    |  |
  |  | Historian                | Allen-Bradley ecosystem integration    |  |
  |  |                          | SQL Server based                        |  |
  |  +--------------------------+----------------------------------------+  |
  |                                                                        |
  +------------------------------------------------------------------------+

+===============================================================================+
```

---

## Historian Architecture

### Data Flow and Access Points

```
+===============================================================================+
|                    HISTORIAN ARCHITECTURE                                     |
+===============================================================================+

  TYPICAL HISTORIAN DEPLOYMENT
  ============================

                                      +----------------------------------+
                                      |        ENTERPRISE ZONE           |
                                      |          (Level 4-5)             |
                                      |                                  |
                                      |  +-------------+  +------------+ |
                                      |  | ERP/MES     |  | Business   | |
                                      |  | Systems     |  | Analytics  | |
                                      |  +------+------+  +-----+------+ |
                                      |         |               |        |
                                      +---------+---------------+--------+
                                                |               |
                                                | Read-Only     | Analytics
                                                | Queries       | Queries
                                                |               |
  +-----------------------------------------------------------------------------------+
  |                                             |               |                     |
  |                                    +--------+---------------+--------+            |
  |                                    |     HISTORIAN DMZ               |            |
  |                                    |     (Level 3.5)                 |            |
  |   WALLIX BASTION <-----------------+                                 |            |
  |   Access Point                     |  +---------------------------+  |            |
  |                                    |  |   PI VISION / WEB CLIENT  |  |            |
  |                                    |  |   (Web Access Layer)      |  |            |
  |                                    |  +-------------+-------------+  |            |
  |                                    |                |                |            |
  |                                    +----------------+----------------+            |
  |                                                     |                             |
  +-----------------------------------------------------------------------------------+
                                                        |
  +-----------------------------------------------------------------------------------+
  |                                                     |                             |
  |                     +-------------------------------+-------------------------------+
  |                     |                                                               |
  |                     |              PROCESS HISTORIAN ZONE                           |
  |                     |              (Level 3)                                        |
  |                     |                                                               |
  |  WALLIX BASTION <---+  +------------------+     +------------------+               |
  |  Admin Access       |  | HISTORIAN SERVER |     | HISTORIAN SERVER |               |
  |                     |  | (Primary)        |     | (Secondary/DR)   |               |
  |                     |  |                  |     |                  |               |
  |                     |  | - Data Archive   |<--->| - Data Archive   |               |
  |                     |  | - Asset Model    |     | - Asset Model    |               |
  |                     |  | - Interfaces     |     | - Interfaces     |               |
  |                     |  +--------+---------+     +--------+---------+               |
  |                     |           |                        |                         |
  |                     +-----------+------------------------+-------------------------+
  |                                 |                        |
  +-----------------------------------------------------------------------------------+
                                    |                        |
                        Data Collection Interfaces           |
                                    |                        |
  +-----------------------------------------------------------------------------------+
  |                                 |                        |                         |
  |              +------------------+------------------------+------------------+      |
  |              |                                                              |      |
  |              |                    CONTROL ZONE (Level 2)                    |      |
  |              |                                                              |      |
  |              |  +-------------+  +-------------+  +-------------+          |      |
  |              |  | SCADA/DCS   |  | SCADA/DCS   |  | MES Server  |          |      |
  |              |  | Server 1    |  | Server 2    |  |             |          |      |
  |              |  +------+------+  +------+------+  +------+------+          |      |
  |              |         |                |                |                 |      |
  |              +---------+----------------+----------------+-----------------+      |
  |                        |                |                |                        |
  +-----------------------------------------------------------------------------------+
                           |                |                |
  +-----------------------------------------------------------------------------------+
  |                        |                |                |                         |
  |              +---------+----------------+----------------+------------+            |
  |              |                                                        |            |
  |              |              FIELD LEVEL (Level 0-1)                   |            |
  |              |                                                        |            |
  |              |  +--------+  +--------+  +--------+  +--------+       |            |
  |              |  |  PLC   |  |  PLC   |  |  RTU   |  |  DCS   |       |            |
  |              |  |   1    |  |   2    |  |   1    |  | Ctrlr  |       |            |
  |              |  +--------+  +--------+  +--------+  +--------+       |            |
  |              |                                                        |            |
  |              +--------------------------------------------------------+            |
  |                                                                                    |
  +-----------------------------------------------------------------------------------+

+===============================================================================+
```

### Access Points and Protocols

```
+===============================================================================+
|                    HISTORIAN ACCESS POINTS                                    |
+===============================================================================+

  ACCESS METHODS AND PROTOCOLS
  ============================

  +------------------------------------------------------------------------+
  |                                                                        |
  |  +------------------+------------------------------------------------+  |
  |  | Access Type      | Protocol/Port       | Purpose                  |  |
  |  +------------------+---------------------+--------------------------+  |
  |  |                  |                     |                          |  |
  |  | PI SDK/API       | TCP 5450-5460       | Native PI data access    |  |
  |  | PI Web API       | HTTPS 443           | RESTful data access      |  |
  |  | PI Vision        | HTTPS 443           | Web-based visualization  |  |
  |  | PI DataLink      | Excel Add-in        | Spreadsheet access       |  |
  |  |                  |                     |                          |  |
  |  +------------------+---------------------+--------------------------+  |
  |  |                  |                     |                          |  |
  |  | AVEVA Historian  | SQL 1433            | Direct database access   |  |
  |  | InTouch Trend    | HTTPS 443           | Web trending             |  |
  |  | System Platform  | Proprietary         | Full platform access     |  |
  |  |                  |                     |                          |  |
  |  +------------------+---------------------+--------------------------+  |
  |  |                  |                     |                          |  |
  |  | GE Historian     | TCP 14000           | Historian API            |  |
  |  | Web Client       | HTTPS 443           | Browser access           |  |
  |  | iHistorian       | OPC DA/UA           | OPC data access          |  |
  |  |                  |                     |                          |  |
  |  +------------------+---------------------+--------------------------+  |
  |  |                  |                     |                          |  |
  |  | Honeywell PHD    | Proprietary         | PHD data access          |  |
  |  | PHD Web          | HTTPS 443           | Web interface            |  |
  |  | Uniformance      | HTTPS 443           | Analytics platform       |  |
  |  |                  |                     |                          |  |
  |  +------------------+---------------------+--------------------------+  |
  |                                                                        |
  +------------------------------------------------------------------------+

  ---------------------------------------------------------------------------

  WALLIX ACCESS CONTROL POINTS
  ============================

  +------------------------------------------------------------------------+
  |                                                                        |
  |  +-------------------------------------------------------------------+ |
  |  |                     WALLIX INTEGRATION POINTS                     | |
  |  +-------------------------------------------------------------------+ |
  |  |                                                                   | |
  |  |  1. ADMINISTRATIVE ACCESS (RDP/SSH)                               | |
  |  |     +-----------------------------------------------------------+ | |
  |  |     | Target: Historian servers (Windows/Linux)                 | | |
  |  |     | Protocol: RDP (3389), SSH (22)                            | | |
  |  |     | Recording: Full video + keystroke                         | | |
  |  |     | Use Case: System administration, configuration            | | |
  |  |     +-----------------------------------------------------------+ | |
  |  |                                                                   | |
  |  |  2. CLIENT APPLICATION ACCESS (RDP to Engineering Station)       | |
  |  |     +-----------------------------------------------------------+ | |
  |  |     | Target: Engineering workstations with historian clients   | | |
  |  |     | Protocol: RDP (3389)                                      | | |
  |  |     | Recording: Full video + application capture               | | |
  |  |     | Use Case: Data analysis, trend review, configuration      | | |
  |  |     +-----------------------------------------------------------+ | |
  |  |                                                                   | |
  |  |  3. WEB ACCESS (HTTPS Proxy)                                     | |
  |  |     +-----------------------------------------------------------+ | |
  |  |     | Target: PI Vision, Historian Web clients                  | | |
  |  |     | Protocol: HTTPS (443)                                     | | |
  |  |     | Recording: Screenshots, URL logging                       | | |
  |  |     | Use Case: Read-only data access, dashboards               | | |
  |  |     +-----------------------------------------------------------+ | |
  |  |                                                                   | |
  |  |  4. DATABASE ACCESS (SQL Proxy)                                  | |
  |  |     +-----------------------------------------------------------+ | |
  |  |     | Target: SQL Server (AVEVA Historian)                      | | |
  |  |     | Protocol: SQL (1433)                                      | | |
  |  |     | Recording: Query logging                                  | | |
  |  |     | Use Case: Direct SQL queries, reporting                   | | |
  |  |     +-----------------------------------------------------------+ | |
  |  |                                                                   | |
  |  +-------------------------------------------------------------------+ |
  |                                                                        |
  +------------------------------------------------------------------------+

+===============================================================================+
```

---

## OSIsoft PI Access

### PI System Architecture

```
+===============================================================================+
|                    OSISOFT PI SYSTEM ACCESS                                   |
+===============================================================================+

  PI SYSTEM COMPONENTS
  ====================

  +------------------------------------------------------------------------+
  |                                                                        |
  |                        PI SYSTEM ARCHITECTURE                          |
  |                                                                        |
  |  +----------------------------------------------------------------+   |
  |  |                    CLIENT LAYER                                |   |
  |  |                                                                |   |
  |  |  +------------+  +------------+  +------------+  +-----------+ |   |
  |  |  | PI Vision  |  | PI DataLink|  | PI Manual  |  | PI Builder| |   |
  |  |  | (Web)      |  | (Excel)    |  | Logger     |  | (Config)  | |   |
  |  |  +------------+  +------------+  +------------+  +-----------+ |   |
  |  |                                                                |   |
  |  +----------------------------------------------------------------+   |
  |                                  |                                    |
  |                          PI Web API / PI SDK                          |
  |                                  |                                    |
  |  +----------------------------------------------------------------+   |
  |  |                    PI SERVER LAYER                             |   |
  |  |                                                                |   |
  |  |  +-----------------------+  +---------------------------+     |   |
  |  |  |   PI DATA ARCHIVE     |  |    PI ASSET FRAMEWORK     |     |   |
  |  |  |                       |  |         (PI AF)           |     |   |
  |  |  | - Time-series data    |  | - Asset hierarchy         |     |   |
  |  |  | - Point database      |  | - Element templates       |     |   |
  |  |  | - Archive files       |  | - Calculated attributes   |     |   |
  |  |  | - Compression         |  | - Event frames            |     |   |
  |  |  +-----------------------+  +---------------------------+     |   |
  |  |                                                                |   |
  |  +----------------------------------------------------------------+   |
  |                                  |                                    |
  |                          PI Interfaces                                |
  |                                  |                                    |
  |  +----------------------------------------------------------------+   |
  |  |                    INTERFACE LAYER                             |   |
  |  |                                                                |   |
  |  |  +----------+  +----------+  +----------+  +----------+       |   |
  |  |  |OPC DA/UA |  | Modbus   |  | PI-to-PI |  | Custom   |       |   |
  |  |  |Interface |  | Interface|  | Interface|  | Interface|       |   |
  |  |  +----------+  +----------+  +----------+  +----------+       |   |
  |  |                                                                |   |
  |  +----------------------------------------------------------------+   |
  |                                                                        |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### PI Vision Access Configuration

```
+===============================================================================+
|                    PI VISION ACCESS WITH WALLIX                               |
+===============================================================================+

  PI VISION WEB ACCESS
  ====================

  PI Vision provides browser-based access to PI System data through displays,
  trends, and dashboards.

  ARCHITECTURE
  ============

       +---------------+
       |   User        |
       | (Browser)     |
       +-------+-------+
               |
               | HTTPS (443)
               v
       +===============+
       |    WALLIX     |
       |   BASTION     |
       |               |
       | - MFA check   |
       | - Auth check  |
       | - Recording   |
       +-------+-------+
               |
               | HTTPS (443)
               v
       +---------------+
       |  PI VISION    |
       |  Web Server   |
       +-------+-------+
               |
               | PI Web API
               v
       +---------------+
       |  PI DATA      |
       |  ARCHIVE      |
       +---------------+


  WALLIX CONFIGURATION
  ====================

  Device Configuration:
  +------------------------------------------------------------------------+
  | wabadmin device create PI-VISION-01                                    |
  |   --domain "Historian-Systems"                                         |
  |   --host "pivision.company.local"                                      |
  |   --description "PI Vision Web Server"                                 |
  +------------------------------------------------------------------------+

  Service Configuration:
  +------------------------------------------------------------------------+
  | wabadmin service create PI-VISION-01/HTTPS                             |
  |   --protocol https                                                     |
  |   --port 443                                                           |
  |   --ssl-verification enabled                                           |
  +------------------------------------------------------------------------+

  Account Configuration:
  +------------------------------------------------------------------------+
  | # Read-only user for operations                                        |
  | wabadmin account create PI-VISION-01/pi_viewer                         |
  |   --service HTTPS                                                      |
  |   --credentials password                                               |
  |   --description "Read-only PI Vision access"                           |
  |                                                                        |
  | # Power user for engineering                                           |
  | wabadmin account create PI-VISION-01/pi_engineer                       |
  |   --service HTTPS                                                      |
  |   --credentials password                                               |
  |   --description "Engineering PI Vision access with write"              |
  +------------------------------------------------------------------------+

  Authorization Configuration:
  +------------------------------------------------------------------------+
  | # Read-only access for operators                                       |
  | wabadmin authorization create operations-pi-vision-view                |
  |   --user-group "Operations-Staff"                                      |
  |   --target "PI-VISION-01/HTTPS/pi_viewer"                             |
  |   --session-recording true                                             |
  |   --approval-required false                                            |
  |   --time-restriction "24x7"                                            |
  |                                                                        |
  | # Engineering access with approval                                     |
  | wabadmin authorization create engineering-pi-vision-full               |
  |   --user-group "Process-Engineers"                                     |
  |   --target "PI-VISION-01/HTTPS/pi_engineer"                           |
  |   --session-recording true                                             |
  |   --approval-required true                                             |
  |   --approval-group "Engineering-Managers"                              |
  |   --time-restriction "business-hours"                                  |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### PI AF Access Configuration

```
+===============================================================================+
|                    PI ASSET FRAMEWORK ACCESS                                  |
+===============================================================================+

  PI AF ADMINISTRATION
  ====================

  PI Asset Framework (PI AF) manages the asset hierarchy, templates, and
  calculated attributes. Changes to PI AF affect data organization across
  the enterprise.

  RISK LEVEL: HIGH
  - Changes affect all PI clients
  - Template modifications propagate to thousands of elements
  - Misconfiguration can cause data collection failures

  ---------------------------------------------------------------------------

  WALLIX ACCESS CONFIGURATION
  ===========================

  Access through Engineering Workstation with PI System Explorer:

  Device Configuration:
  +------------------------------------------------------------------------+
  | wabadmin device create PI-ENG-WORKSTATION-01                           |
  |   --domain "Historian-Systems"                                         |
  |   --host "pi-eng-ws01.company.local"                                   |
  |   --description "PI System Explorer Engineering Station"               |
  +------------------------------------------------------------------------+

  Service and Account:
  +------------------------------------------------------------------------+
  | wabadmin service create PI-ENG-WORKSTATION-01/RDP                      |
  |   --protocol rdp                                                       |
  |   --port 3389                                                          |
  |                                                                        |
  | wabadmin account create PI-ENG-WORKSTATION-01/pi_admin                 |
  |   --service RDP                                                        |
  |   --credentials auto-managed                                           |
  |   --rotate-password-days 30                                            |
  |   --description "PI System administration account"                     |
  +------------------------------------------------------------------------+

  Authorization with Dual Approval:
  +------------------------------------------------------------------------+
  | wabadmin authorization create pi-af-administration                     |
  |   --user-group "PI-Administrators"                                     |
  |   --target "PI-ENG-WORKSTATION-01/RDP/pi_admin"                       |
  |   --session-recording true                                             |
  |   --approval-required true                                             |
  |   --approval-workflow "dual-approval"                                  |
  |   --approval-groups "Engineering-Managers,IT-Security"                 |
  |   --min-approvals 2                                                    |
  |   --max-session-duration 4h                                            |
  |   --requires-comment true                                              |
  +------------------------------------------------------------------------+

  ---------------------------------------------------------------------------

  PI SYSTEM ACCOUNT TYPES
  =======================

  +------------------------------------------------------------------------+
  |                                                                        |
  |  +--------------------+-----------------------+-----------------------+  |
  |  | Account Type       | Permissions           | WALLIX Mapping        |  |
  |  +--------------------+-----------------------+-----------------------+  |
  |  | PIReader           | Read data only        | operations-viewer     |  |
  |  | PIWorld            | Basic read + write    | process-operators     |  |
  |  | PIEngineers        | Configuration access  | process-engineers     |  |
  |  | PIAdmins           | Full administrative   | pi-administrators     |  |
  |  | PIDataServices     | Interface/collection  | service-accounts      |  |
  |  +--------------------+-----------------------+-----------------------+  |
  |                                                                        |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### PI DataLink Access

```
+===============================================================================+
|                    PI DATALINK ACCESS                                         |
+===============================================================================+

  PI DATALINK OVERVIEW
  ====================

  PI DataLink is an Excel add-in that provides direct access to PI System data
  for reporting, analysis, and data manipulation.

  RISK CONSIDERATIONS:
  - Bulk data export capability
  - Direct connection to PI Server
  - Potential for large data extraction
  - Often runs with user credentials

  ---------------------------------------------------------------------------

  ACCESS CONTROL STRATEGY
  =======================

  +------------------------------------------------------------------------+
  |                                                                        |
  |  OPTION 1: CONTROLLED WORKSTATION ACCESS                               |
  |  ========================================                               |
  |                                                                        |
  |  Users access dedicated workstations with PI DataLink installed,       |
  |  through WALLIX Bastion.                                               |
  |                                                                        |
  |       +---------------+                                                |
  |       |   Analyst     |                                                |
  |       +-------+-------+                                                |
  |               | RDP                                                    |
  |               v                                                        |
  |       +=======+=======+                                                |
  |       |    WALLIX     |                                                |
  |       |   BASTION     |                                                |
  |       +=======+=======+                                                |
  |               | RDP (Recorded)                                         |
  |               v                                                        |
  |       +---------------+          +---------------+                     |
  |       | Analysis      |  PI SDK  |  PI DATA      |                     |
  |       | Workstation   +--------->|  ARCHIVE      |                     |
  |       | (DataLink)    |          |               |                     |
  |       +---------------+          +---------------+                     |
  |                                                                        |
  |  Configuration:                                                        |
  |  +--------------------------------------------------------------------+|
  |  | wabadmin device create PI-ANALYSIS-WS-01                           ||
  |  |   --host "pi-analysis01.company.local"                             ||
  |  |   --domain "Historian-Systems"                                     ||
  |  |                                                                    ||
  |  | wabadmin authorization create analysts-pi-datalink                 ||
  |  |   --user-group "Data-Analysts"                                     ||
  |  |   --target "PI-ANALYSIS-WS-01/RDP/analyst_user"                   ||
  |  |   --session-recording true                                         ||
  |  |   --max-session-duration 8h                                        ||
  |  |   --time-restriction "business-hours"                              ||
  |  +--------------------------------------------------------------------+|
  |                                                                        |
  +------------------------------------------------------------------------+
  |                                                                        |
  |  OPTION 2: WEB API ACCESS                                              |
  |  ========================                                              |
  |                                                                        |
  |  Modern approach using PI Web API instead of DataLink.                 |
  |                                                                        |
  |  Benefits:                                                             |
  |  - Centralized authentication                                          |
  |  - API-level access control                                            |
  |  - Query logging and rate limiting                                     |
  |  - No client software installation                                     |
  |                                                                        |
  +------------------------------------------------------------------------+

+===============================================================================+
```

---

## Wonderware/AVEVA Historian

### AVEVA Historian Architecture

```
+===============================================================================+
|                    AVEVA HISTORIAN ACCESS                                     |
+===============================================================================+

  AVEVA HISTORIAN COMPONENTS
  ==========================

  AVEVA Historian (formerly Wonderware InSQL) is built on SQL Server and
  provides industrial data storage with advanced analytics.

  +------------------------------------------------------------------------+
  |                                                                        |
  |                    AVEVA HISTORIAN ARCHITECTURE                        |
  |                                                                        |
  |  +----------------------------------------------------------------+   |
  |  |                    CLIENT LAYER                                |   |
  |  |                                                                |   |
  |  |  +------------+  +------------+  +------------+  +-----------+ |   |
  |  |  | InTouch    |  | Historian  |  | Information|  | Insight   | |   |
  |  |  | (HMI)      |  | Client     |  | Server     |  | (Reports) | |   |
  |  |  +------------+  +------------+  +------------+  +-----------+ |   |
  |  |                                                                |   |
  |  +----------------------------------------------------------------+   |
  |                                  |                                    |
  |                          SQL / ADO.NET                                |
  |                                  |                                    |
  |  +----------------------------------------------------------------+   |
  |  |                    HISTORIAN SERVER                            |   |
  |  |                                                                |   |
  |  |  +---------------------------+  +---------------------------+  |   |
  |  |  |    HISTORIAN ENGINE       |  |    SQL SERVER             |  |   |
  |  |  |                           |  |                           |  |   |
  |  |  | - Data compression        |  | - Runtime database        |  |   |
  |  |  | - Tag management          |  | - Configuration DB        |  |   |
  |  |  | - Retrieval engine        |  | - Stored procedures       |  |   |
  |  |  | - Calculation engine      |  | - Security                |  |   |
  |  |  +---------------------------+  +---------------------------+  |   |
  |  |                                                                |   |
  |  +----------------------------------------------------------------+   |
  |                                  |                                    |
  |                          IDAS Collectors                              |
  |                                  |                                    |
  |  +----------------------------------------------------------------+   |
  |  |                    DATA SOURCES                                |   |
  |  |                                                                |   |
  |  |  +----------+  +----------+  +----------+  +----------+       |   |
  |  |  |InTouch   |  |OPC       |  | System   |  | ArchestrA|       |   |
  |  |  |IDAS      |  |IDAS      |  | Platform |  | IDAS     |       |   |
  |  |  +----------+  +----------+  +----------+  +----------+       |   |
  |  |                                                                |   |
  |  +----------------------------------------------------------------+   |
  |                                                                        |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### InSQL/Historian Client Access

```
+===============================================================================+
|                    AVEVA HISTORIAN CLIENT ACCESS                              |
+===============================================================================+

  HISTORIAN CLIENT ACCESS PATTERNS
  ================================

  1. HISTORIAN CLIENT APPLICATION
  ===============================

  The Historian Client provides tag browsing, trend analysis, and query tools.

  WALLIX Configuration:
  +------------------------------------------------------------------------+
  | # Engineering workstation with Historian Client                        |
  | wabadmin device create AVEVA-ENG-WS-01                                 |
  |   --domain "Historian-Systems"                                         |
  |   --host "aveva-eng01.company.local"                                   |
  |   --description "AVEVA Engineering Workstation"                        |
  |                                                                        |
  | wabadmin service create AVEVA-ENG-WS-01/RDP                            |
  |   --protocol rdp                                                       |
  |   --port 3389                                                          |
  |                                                                        |
  | # Read-only account for data analysis                                  |
  | wabadmin account create AVEVA-ENG-WS-01/hist_analyst                   |
  |   --service RDP                                                        |
  |   --credentials auto-managed                                           |
  |   --description "Historian read-only analysis"                         |
  |                                                                        |
  | # Configuration account for administrators                             |
  | wabadmin account create AVEVA-ENG-WS-01/hist_admin                     |
  |   --service RDP                                                        |
  |   --credentials auto-managed                                           |
  |   --rotate-password-days 30                                            |
  |   --description "Historian administration"                             |
  +------------------------------------------------------------------------+

  ---------------------------------------------------------------------------

  2. SQL SERVER DIRECT ACCESS
  ===========================

  AVEVA Historian stores data in SQL Server. Direct SQL access may be
  required for custom reporting.

  WALLIX Configuration:
  +------------------------------------------------------------------------+
  | # Historian SQL Server                                                 |
  | wabadmin device create AVEVA-HISTORIAN-SQL                             |
  |   --domain "Historian-Systems"                                         |
  |   --host "aveva-hist-sql.company.local"                                |
  |   --description "AVEVA Historian SQL Server"                           |
  |                                                                        |
  | wabadmin service create AVEVA-HISTORIAN-SQL/SQL                        |
  |   --protocol sql                                                       |
  |   --port 1433                                                          |
  |                                                                        |
  | # Read-only SQL account                                                |
  | wabadmin account create AVEVA-HISTORIAN-SQL/sql_reader                 |
  |   --service SQL                                                        |
  |   --credentials auto-managed                                           |
  |   --sql-permissions "db_datareader on Runtime"                         |
  |   --description "Read-only SQL access for reporting"                   |
  +------------------------------------------------------------------------+

  ---------------------------------------------------------------------------

  3. INFORMATION SERVER (WEB ACCESS)
  ==================================

  AVEVA Information Server provides web-based access to historian data.

  WALLIX Configuration:
  +------------------------------------------------------------------------+
  | wabadmin device create AVEVA-INFO-SERVER                               |
  |   --domain "Historian-Systems"                                         |
  |   --host "aveva-infoserver.company.local"                              |
  |                                                                        |
  | wabadmin service create AVEVA-INFO-SERVER/HTTPS                        |
  |   --protocol https                                                     |
  |   --port 443                                                           |
  |                                                                        |
  | wabadmin authorization create operations-aveva-web                     |
  |   --user-group "Operations-Staff"                                      |
  |   --target "AVEVA-INFO-SERVER/HTTPS/viewer"                           |
  |   --session-recording true                                             |
  |   --approval-required false                                            |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### AVEVA Trend and Reporting Access

```
+===============================================================================+
|                    AVEVA TREND AND REPORTING                                  |
+===============================================================================+

  REPORTING ACCESS PATTERNS
  =========================

  AVEVA Insight (formerly Wonderware Historian Reports) provides
  operational reporting and trend analysis.

  ACCESS LEVELS
  =============

  +------------------------------------------------------------------------+
  |                                                                        |
  |  +--------------------+---------------------------------------------+  |
  |  | Access Level       | Description                                 |  |
  |  +--------------------+---------------------------------------------+  |
  |  | Report Viewer      | View published reports only                 |  |
  |  | Report Designer    | Create and modify report templates          |  |
  |  | Data Explorer      | Ad-hoc queries and trend analysis           |  |
  |  | Administrator      | System configuration, user management       |  |
  |  +--------------------+---------------------------------------------+  |
  |                                                                        |
  +------------------------------------------------------------------------+

  WALLIX AUTHORIZATION MAPPING
  ============================

  +------------------------------------------------------------------------+
  | # Operators - view reports only                                        |
  | wabadmin authorization create operators-aveva-reports                  |
  |   --user-group "Shift-Operators"                                       |
  |   --target "AVEVA-INSIGHT/HTTPS/report_viewer"                        |
  |   --session-recording true                                             |
  |   --approval-required false                                            |
  |   --time-restriction "shift-hours"                                     |
  |                                                                        |
  | # Analysts - design reports                                            |
  | wabadmin authorization create analysts-aveva-reports                   |
  |   --user-group "Process-Analysts"                                      |
  |   --target "AVEVA-INSIGHT/HTTPS/report_designer"                      |
  |   --session-recording true                                             |
  |   --approval-required false                                            |
  |   --time-restriction "business-hours"                                  |
  |                                                                        |
  | # Administrators - full access                                         |
  | wabadmin authorization create admins-aveva-reports                     |
  |   --user-group "Historian-Admins"                                      |
  |   --target "AVEVA-INSIGHT/HTTPS/administrator"                        |
  |   --session-recording true                                             |
  |   --approval-required true                                             |
  |   --approval-group "IT-Managers"                                       |
  +------------------------------------------------------------------------+

+===============================================================================+
```

---

## GE Proficy Historian

### Proficy Historian Architecture

```
+===============================================================================+
|                    GE PROFICY HISTORIAN ACCESS                                |
+===============================================================================+

  PROFICY HISTORIAN COMPONENTS
  ============================

  GE Proficy Historian is part of the GE Digital Proficy suite, commonly
  used in utilities and manufacturing.

  +------------------------------------------------------------------------+
  |                                                                        |
  |                    PROFICY HISTORIAN ARCHITECTURE                      |
  |                                                                        |
  |  +----------------------------------------------------------------+   |
  |  |                    CLIENT APPLICATIONS                         |   |
  |  |                                                                |   |
  |  |  +-------------+  +-------------+  +-------------+            |   |
  |  |  | Historian   |  | Web Client  |  | Excel       |            |   |
  |  |  | Admin       |  | (Browser)   |  | Add-In      |            |   |
  |  |  +-------------+  +-------------+  +-------------+            |   |
  |  |                                                                |   |
  |  |  +-------------+  +-------------+  +-------------+            |   |
  |  |  | Proficy     |  | Operations  |  | iFIX/CIMPLICITY         |   |
  |  |  | Troubleshooter  | Hub        |  | (HMI)       |            |   |
  |  |  +-------------+  +-------------+  +-------------+            |   |
  |  |                                                                |   |
  |  +----------------------------------------------------------------+   |
  |                                  |                                    |
  |                          Historian SDK/API                            |
  |                          TCP Port 14000                               |
  |                                  |                                    |
  |  +----------------------------------------------------------------+   |
  |  |                    HISTORIAN SERVER                            |   |
  |  |                                                                |   |
  |  |  +---------------------------+  +---------------------------+  |   |
  |  |  |    DATA ARCHIVER          |  |    CONFIGURATION          |  |   |
  |  |  |                           |  |                           |  |   |
  |  |  | - Time-series storage     |  | - Tag database            |  |   |
  |  |  | - Archive files           |  | - Collector config        |  |   |
  |  |  | - Compression             |  | - Security settings       |  |   |
  |  |  +---------------------------+  +---------------------------+  |   |
  |  |                                                                |   |
  |  +----------------------------------------------------------------+   |
  |                                  |                                    |
  |                          Collectors                                   |
  |                                  |                                    |
  |  +----------------------------------------------------------------+   |
  |  |                    DATA SOURCES                                |   |
  |  |                                                                |   |
  |  |  +----------+  +----------+  +----------+  +----------+       |   |
  |  |  | OPC      |  | CIMPLICITY|  | iFIX     |  | Simulation     |   |
  |  |  | Collector|  | Collector |  | Collector|  | Collector|       |   |
  |  |  +----------+  +----------+  +----------+  +----------+       |   |
  |  |                                                                |   |
  |  +----------------------------------------------------------------+   |
  |                                                                        |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### Historian Administrator Access

```
+===============================================================================+
|                    PROFICY HISTORIAN ADMINISTRATOR ACCESS                     |
+===============================================================================+

  HISTORIAN ADMINISTRATOR TOOL
  ============================

  The Historian Administrator is the primary configuration tool for
  Proficy Historian. It provides:

  - Tag creation and configuration
  - Collector management
  - Archive management
  - User security configuration
  - System monitoring

  RISK LEVEL: CRITICAL
  - Full system configuration access
  - Can create/delete tags affecting data collection
  - Security configuration control

  ---------------------------------------------------------------------------

  WALLIX CONFIGURATION
  ====================

  Device and Access Setup:
  +------------------------------------------------------------------------+
  | # Historian server for administrative access                           |
  | wabadmin device create PROFICY-HISTORIAN-01                            |
  |   --domain "Historian-Systems"                                         |
  |   --host "proficy-hist01.company.local"                                |
  |   --description "GE Proficy Historian Primary Server"                  |
  |                                                                        |
  | wabadmin service create PROFICY-HISTORIAN-01/RDP                       |
  |   --protocol rdp                                                       |
  |   --port 3389                                                          |
  |                                                                        |
  | # Administrator account                                                |
  | wabadmin account create PROFICY-HISTORIAN-01/hist_admin                |
  |   --service RDP                                                        |
  |   --credentials auto-managed                                           |
  |   --rotate-password-days 30                                            |
  |   --checkout-required true                                             |
  |   --description "Historian Administrator access"                       |
  +------------------------------------------------------------------------+

  Authorization with Approval:
  +------------------------------------------------------------------------+
  | wabadmin authorization create proficy-admin-access                     |
  |   --user-group "Historian-Administrators"                              |
  |   --target "PROFICY-HISTORIAN-01/RDP/hist_admin"                      |
  |   --session-recording true                                             |
  |   --approval-required true                                             |
  |   --approval-workflow "critical-system-access"                         |
  |   --approval-groups "OT-Security,IT-Infrastructure"                    |
  |   --min-approvals 1                                                    |
  |   --max-session-duration 4h                                            |
  |   --requires-comment true                                              |
  |   --description "Administrative access to Proficy Historian"           |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### Proficy Web Client Access

```
+===============================================================================+
|                    PROFICY WEB CLIENT ACCESS                                  |
+===============================================================================+

  WEB-BASED ACCESS
  ================

  Proficy Historian Web Client provides browser-based access to historian
  data for trending and analysis.

  ARCHITECTURE
  ============

       +---------------+
       |   User        |
       | (Browser)     |
       +-------+-------+
               |
               | HTTPS (443)
               v
       +===============+
       |    WALLIX     |
       |   BASTION     |
       +-------+-------+
               |
               | HTTPS (443)
               v
       +---------------+
       |  Proficy      |
       |  Web Client   |
       +-------+-------+
               |
               | Historian API (14000)
               v
       +---------------+
       |  Historian    |
       |  Server       |
       +---------------+


  WALLIX CONFIGURATION
  ====================

  +------------------------------------------------------------------------+
  | # Web client server                                                    |
  | wabadmin device create PROFICY-WEB-CLIENT                              |
  |   --domain "Historian-Systems"                                         |
  |   --host "proficy-web.company.local"                                   |
  |                                                                        |
  | wabadmin service create PROFICY-WEB-CLIENT/HTTPS                       |
  |   --protocol https                                                     |
  |   --port 443                                                           |
  |                                                                        |
  | # View-only access                                                     |
  | wabadmin account create PROFICY-WEB-CLIENT/viewer                      |
  |   --service HTTPS                                                      |
  |   --credentials password                                               |
  |   --description "View-only historian data access"                      |
  |                                                                        |
  | # Authorization for operators                                          |
  | wabadmin authorization create operators-proficy-web                    |
  |   --user-group "Plant-Operators"                                       |
  |   --target "PROFICY-WEB-CLIENT/HTTPS/viewer"                          |
  |   --session-recording true                                             |
  |   --approval-required false                                            |
  |   --time-restriction "24x7"                                            |
  +------------------------------------------------------------------------+

+===============================================================================+
```

---

## Honeywell PHD

### PHD Architecture

```
+===============================================================================+
|                    HONEYWELL PHD ACCESS                                       |
+===============================================================================+

  HONEYWELL PROCESS HISTORY DATABASE (PHD)
  =========================================

  PHD is part of Honeywell's Experion PKS (Process Knowledge System) and
  provides process data storage for refining and petrochemical industries.

  +------------------------------------------------------------------------+
  |                                                                        |
  |                    PHD ARCHITECTURE                                    |
  |                                                                        |
  |  +----------------------------------------------------------------+   |
  |  |                    CLIENT LAYER                                |   |
  |  |                                                                |   |
  |  |  +------------+  +------------+  +------------+  +-----------+ |   |
  |  |  | PHD Expert |  | PHD Web    |  | Uniformance|  | Excel     | |   |
  |  |  | (Thick)    |  | (Browser)  |  | PHD        |  | Add-in    | |   |
  |  |  +------------+  +------------+  +------------+  +-----------+ |   |
  |  |                                                                |   |
  |  +----------------------------------------------------------------+   |
  |                                  |                                    |
  |                          PHD API / Uniformance                        |
  |                                  |                                    |
  |  +----------------------------------------------------------------+   |
  |  |                    PHD SERVER                                  |   |
  |  |                                                                |   |
  |  |  +---------------------------+  +---------------------------+  |   |
  |  |  |    PHD ENGINE             |  |    CONFIGURATION          |  |   |
  |  |  |                           |  |                           |  |   |
  |  |  | - Data compression        |  | - Tag database            |  |   |
  |  |  | - Archive management      |  | - Security settings       |  |   |
  |  |  | - Calculation engine      |  | - Collector config        |  |   |
  |  |  +---------------------------+  +---------------------------+  |   |
  |  |                                                                |   |
  |  +----------------------------------------------------------------+   |
  |                                  |                                    |
  |                          Experion PKS                                 |
  |                                  |                                    |
  |  +----------------------------------------------------------------+   |
  |  |                    DATA SOURCES                                |   |
  |  |                                                                |   |
  |  |  +----------+  +----------+  +----------+  +----------+       |   |
  |  |  | Experion |  | C300     |  | OPC      |  | External |       |   |
  |  |  | Servers  |  | Controllers | DA/UA   |  | Systems  |       |   |
  |  |  +----------+  +----------+  +----------+  +----------+       |   |
  |  |                                                                |   |
  |  +----------------------------------------------------------------+   |
  |                                                                        |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### PHD Access Configuration

```
+===============================================================================+
|                    PHD ACCESS CONFIGURATION                                   |
+===============================================================================+

  PHD ACCESS PATTERNS
  ===================

  1. PHD EXPERT (THICK CLIENT)
  ============================

  PHD Expert is the primary analysis tool for PHD data.

  WALLIX Configuration:
  +------------------------------------------------------------------------+
  | # Engineering workstation with PHD Expert                              |
  | wabadmin device create PHD-ENG-WS-01                                   |
  |   --domain "Historian-Systems"                                         |
  |   --host "phd-eng01.company.local"                                     |
  |   --description "PHD Expert Engineering Station"                       |
  |                                                                        |
  | wabadmin service create PHD-ENG-WS-01/RDP                              |
  |   --protocol rdp                                                       |
  |   --port 3389                                                          |
  |                                                                        |
  | # Analyst account                                                      |
  | wabadmin account create PHD-ENG-WS-01/phd_analyst                      |
  |   --service RDP                                                        |
  |   --credentials auto-managed                                           |
  |   --description "PHD data analysis access"                             |
  |                                                                        |
  | wabadmin authorization create analysts-phd-expert                      |
  |   --user-group "Process-Analysts"                                      |
  |   --target "PHD-ENG-WS-01/RDP/phd_analyst"                            |
  |   --session-recording true                                             |
  |   --approval-required false                                            |
  |   --time-restriction "business-hours"                                  |
  +------------------------------------------------------------------------+

  ---------------------------------------------------------------------------

  2. PHD WEB ACCESS
  =================

  WALLIX Configuration:
  +------------------------------------------------------------------------+
  | wabadmin device create PHD-WEB-SERVER                                  |
  |   --domain "Historian-Systems"                                         |
  |   --host "phd-web.company.local"                                       |
  |                                                                        |
  | wabadmin service create PHD-WEB-SERVER/HTTPS                           |
  |   --protocol https                                                     |
  |   --port 443                                                           |
  |                                                                        |
  | # Read-only web access                                                 |
  | wabadmin account create PHD-WEB-SERVER/web_viewer                      |
  |   --service HTTPS                                                      |
  |   --credentials password                                               |
  |                                                                        |
  | wabadmin authorization create operations-phd-web                       |
  |   --user-group "Operations-Staff"                                      |
  |   --target "PHD-WEB-SERVER/HTTPS/web_viewer"                          |
  |   --session-recording true                                             |
  |   --approval-required false                                            |
  +------------------------------------------------------------------------+

  ---------------------------------------------------------------------------

  3. UNIFORMANCE SUITE ACCESS
  ===========================

  Uniformance provides advanced analytics on top of PHD data.

  WALLIX Configuration:
  +------------------------------------------------------------------------+
  | wabadmin device create UNIFORMANCE-SERVER                              |
  |   --domain "Historian-Systems"                                         |
  |   --host "uniformance.company.local"                                   |
  |                                                                        |
  | # Web access to Uniformance                                            |
  | wabadmin service create UNIFORMANCE-SERVER/HTTPS                       |
  |   --protocol https                                                     |
  |   --port 443                                                           |
  |                                                                        |
  | # Analytics user access                                                |
  | wabadmin authorization create analytics-uniformance                    |
  |   --user-group "Data-Scientists"                                       |
  |   --target "UNIFORMANCE-SERVER/HTTPS/analytics_user"                  |
  |   --session-recording true                                             |
  |   --approval-required false                                            |
  |   --time-restriction "business-hours"                                  |
  +------------------------------------------------------------------------+

+===============================================================================+
```

---

## Access Control Patterns

### Role-Based Access Patterns

```
+===============================================================================+
|                    HISTORIAN ACCESS CONTROL PATTERNS                          |
+===============================================================================+

  ACCESS LEVELS BY ROLE
  =====================

  +------------------------------------------------------------------------+
  |                                                                        |
  |  +--------------------+---------------------------------------------+  |
  |  | Access Level       | Permissions                                 |  |
  |  +--------------------+---------------------------------------------+  |
  |  |                    |                                             |  |
  |  | READ-ONLY          | - View historical data                      |  |
  |  | DATA ACCESS        | - Run pre-defined reports                   |  |
  |  |                    | - View trends and displays                  |  |
  |  |                    | - Export data (limited)                     |  |
  |  |                    |                                             |  |
  |  +--------------------+---------------------------------------------+  |
  |  |                    |                                             |  |
  |  | CONFIGURATION      | - Create/modify tags                        |  |
  |  | ACCESS             | - Configure collectors                      |  |
  |  |                    | - Modify displays/reports                   |  |
  |  |                    | - Asset hierarchy management                |  |
  |  |                    |                                             |  |
  |  +--------------------+---------------------------------------------+  |
  |  |                    |                                             |  |
  |  | ADMINISTRATIVE     | - User/security management                  |  |
  |  | ACCESS             | - System configuration                      |  |
  |  |                    | - Backup/restore operations                 |  |
  |  |                    | - Archive management                        |  |
  |  |                    |                                             |  |
  |  +--------------------+---------------------------------------------+  |
  |  |                    |                                             |  |
  |  | REPORTING          | - Create custom reports                     |  |
  |  | ACCESS             | - Schedule reports                          |  |
  |  |                    | - Bulk data export                          |  |
  |  |                    | - Ad-hoc queries                            |  |
  |  |                    |                                             |  |
  |  +--------------------+---------------------------------------------+  |
  |                                                                        |
  +------------------------------------------------------------------------+

  ---------------------------------------------------------------------------

  ROLE-TO-AUTHORIZATION MAPPING
  =============================

  +------------------------------------------------------------------------+
  |                                                                        |
  |  +----------------------+-------------------------------------------+  |
  |  | Role                 | WALLIX Authorization                      |  |
  |  +----------------------+-------------------------------------------+  |
  |  | Shift Operator       | historian-view-only                       |  |
  |  |                      | - Web client read-only                    |  |
  |  |                      | - No approval required                    |  |
  |  |                      | - 24x7 access                             |  |
  |  +----------------------+-------------------------------------------+  |
  |  | Process Engineer     | historian-engineering                     |  |
  |  |                      | - Client application access               |  |
  |  |                      | - Configuration changes                   |  |
  |  |                      | - Business hours                          |  |
  |  +----------------------+-------------------------------------------+  |
  |  | Data Analyst         | historian-analytics                       |  |
  |  |                      | - Export capabilities                     |  |
  |  |                      | - Report design                           |  |
  |  |                      | - Business hours                          |  |
  |  +----------------------+-------------------------------------------+  |
  |  | Historian Admin      | historian-administration                  |  |
  |  |                      | - Full administrative access              |  |
  |  |                      | - Approval required                       |  |
  |  |                      | - Change ticket required                  |  |
  |  +----------------------+-------------------------------------------+  |
  |  | Vendor Support       | historian-vendor-support                  |  |
  |  |                      | - Time-limited access                     |  |
  |  |                      | - Dual approval required                  |  |
  |  |                      | - Escorted session (monitoring)           |  |
  |  +----------------------+-------------------------------------------+  |
  |                                                                        |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### Authorization Configuration Examples

```
+===============================================================================+
|                    AUTHORIZATION CONFIGURATIONS                               |
+===============================================================================+

  EXAMPLE CONFIGURATIONS
  ======================

  1. READ-ONLY DATA ACCESS
  ========================

  {
      "authorization_name": "historian-view-only",
      "description": "Read-only access to historian data",

      "user_group": "Shift-Operators",
      "target_group": "Historian-Web-Clients",

      "is_recorded": true,
      "is_critical": false,
      "approval_required": false,

      "subprotocols": ["HTTPS"],

      "time_frames": ["24x7"],

      "session_settings": {
          "max_duration_hours": 8,
          "idle_timeout_minutes": 30
      }
  }

  ---------------------------------------------------------------------------

  2. CONFIGURATION ACCESS
  =======================

  {
      "authorization_name": "historian-engineering",
      "description": "Engineering access for historian configuration",

      "user_group": "Process-Engineers",
      "target_group": "Historian-Engineering-Stations",

      "is_recorded": true,
      "is_critical": true,
      "approval_required": true,
      "has_comment": true,

      "approval_workflow": {
          "approvers": ["Engineering-Managers"],
          "timeout_hours": 4
      },

      "subprotocols": ["RDP"],

      "time_frames": ["business-hours"],

      "session_settings": {
          "max_duration_hours": 4,
          "idle_timeout_minutes": 15,
          "post_session_password_rotation": true
      }
  }

  ---------------------------------------------------------------------------

  3. ADMINISTRATIVE ACCESS
  ========================

  {
      "authorization_name": "historian-administration",
      "description": "Full administrative access to historian systems",

      "user_group": "Historian-Administrators",
      "target_group": "Historian-Servers",

      "is_recorded": true,
      "is_critical": true,
      "approval_required": true,
      "has_comment": true,

      "approval_workflow": {
          "name": "dual-approval-historian",
          "approvers": ["OT-Security", "IT-Infrastructure"],
          "min_approvals": 2,
          "timeout_hours": 2
      },

      "subprotocols": ["RDP", "SSH"],

      "time_frames": ["business-hours-extended"],

      "session_settings": {
          "max_duration_hours": 2,
          "idle_timeout_minutes": 10,
          "post_session_password_rotation": true
      }
  }

  ---------------------------------------------------------------------------

  4. REPORTING/EXPORT ACCESS
  ==========================

  {
      "authorization_name": "historian-analytics",
      "description": "Data export and analytics access",

      "user_group": "Data-Analysts",
      "target_group": "Historian-Analytics-Stations",

      "is_recorded": true,
      "is_critical": true,
      "approval_required": true,

      "approval_workflow": {
          "approvers": ["Data-Governance-Team"],
          "timeout_hours": 24
      },

      "subprotocols": ["RDP"],

      "time_frames": ["business-hours"],

      "session_settings": {
          "max_duration_hours": 8,
          "idle_timeout_minutes": 30
      },

      "notes": "Data export activities must comply with data governance policy"
  }

+===============================================================================+
```

---

## Credential Management

### Service Account Management

```
+===============================================================================+
|                    HISTORIAN CREDENTIAL MANAGEMENT                            |
+===============================================================================+

  SERVICE ACCOUNT TYPES
  =====================

  +------------------------------------------------------------------------+
  |                                                                        |
  |  +----------------------+-------------------------------------------+  |
  |  | Account Type         | Purpose                                   |  |
  |  +----------------------+-------------------------------------------+  |
  |  | Data Collection      | Interface/collector service accounts      |  |
  |  | Service Account      | - Runs 24x7 on historian server           |  |
  |  |                      | - Connects to PLCs, DCS, SCADA            |  |
  |  |                      | - Read-only typically                     |  |
  |  +----------------------+-------------------------------------------+  |
  |  | User Access          | Interactive user sessions                 |  |
  |  | Credentials          | - Individual accountability               |  |
  |  |                      | - Role-based permissions                  |  |
  |  +----------------------+-------------------------------------------+  |
  |  | API/SDK              | Application integration                   |  |
  |  | Credentials          | - Analytics platforms                     |  |
  |  |                      | - Reporting systems                       |  |
  |  |                      | - Third-party applications                |  |
  |  +----------------------+-------------------------------------------+  |
  |  | Administrative       | System administration                     |  |
  |  | Credentials          | - Backup/restore                          |  |
  |  |                      | - Configuration changes                   |  |
  |  +----------------------+-------------------------------------------+  |
  |                                                                        |
  +------------------------------------------------------------------------+

  ---------------------------------------------------------------------------

  WALLIX CREDENTIAL VAULT CONFIGURATION
  =====================================

  Service Account for Data Collection:
  +------------------------------------------------------------------------+
  | # OPC collector service account                                        |
  | wabadmin account create HISTORIAN-01/svc_opc_collector                 |
  |   --service SSH                                                        |
  |   --credentials auto-managed                                           |
  |   --rotate-password-days 90                                            |
  |   --checkout-policy "no-concurrent"                                    |
  |   --description "OPC Data Collector Service Account"                   |
  |                                                                        |
  | # Rotation configuration for service accounts                          |
  | wabadmin credential-policy create historian-service-accounts           |
  |   --password-length 32                                                 |
  |   --complexity "upper,lower,number,special"                            |
  |   --rotation-days 90                                                   |
  |   --notification-before-days 14                                        |
  |   --notification-group "Historian-Admins"                              |
  +------------------------------------------------------------------------+

  API/SDK Credentials:
  +------------------------------------------------------------------------+
  | # API credentials for analytics platform                               |
  | wabadmin account create HISTORIAN-01/api_analytics                     |
  |   --service API                                                        |
  |   --credentials auto-managed                                           |
  |   --rotate-password-days 30                                            |
  |   --api-key-enabled true                                               |
  |   --description "Analytics platform API access"                        |
  |                                                                        |
  | # Checkout policy for API credentials                                  |
  | wabadmin checkout-policy create api-credential-checkout                |
  |   --duration-hours 24                                                  |
  |   --auto-checkin true                                                  |
  |   --notification-on-checkout true                                      |
  +------------------------------------------------------------------------+

  ---------------------------------------------------------------------------

  CREDENTIAL ROTATION STRATEGY
  ============================

  +------------------------------------------------------------------------+
  |                                                                        |
  |  +----------------------+--------------------+------------------------+  |
  |  | Account Type         | Rotation Frequency | Considerations        |  |
  |  +----------------------+--------------------+------------------------+  |
  |  | Interactive Users    | 90 days            | User notification     |  |
  |  | Service Accounts     | 90-180 days        | Coordinate with ops   |  |
  |  | API Credentials      | 30 days            | Update integrations   |  |
  |  | Admin Accounts       | 30 days            | Change management     |  |
  |  | Emergency/Break-glass| After each use     | Audit and reset       |  |
  |  +----------------------+--------------------+------------------------+  |
  |                                                                        |
  +------------------------------------------------------------------------+

+===============================================================================+
```

---

## Session Recording

### Recording Historian Sessions

```
+===============================================================================+
|                    HISTORIAN SESSION RECORDING                                |
+===============================================================================+

  RECORDING REQUIREMENTS
  ======================

  +------------------------------------------------------------------------+
  |                                                                        |
  |  WHAT TO RECORD                                                        |
  |  ===============                                                        |
  |                                                                        |
  |  1. Administrative Sessions                                            |
  |     - Full video recording (RDP)                                       |
  |     - Keystroke logging                                                |
  |     - Application activity capture                                     |
  |     - Command history (SSH)                                            |
  |                                                                        |
  |  2. Configuration Changes                                              |
  |     - Tag creation/modification                                        |
  |     - Collector configuration                                          |
  |     - Security settings changes                                        |
  |     - Asset hierarchy modifications                                    |
  |                                                                        |
  |  3. Data Access Sessions                                               |
  |     - Query patterns                                                   |
  |     - Data export activities                                           |
  |     - Report generation                                                |
  |     - Trend analysis sessions                                          |
  |                                                                        |
  +------------------------------------------------------------------------+

  ---------------------------------------------------------------------------

  RECORDING CONFIGURATION
  =======================

  +------------------------------------------------------------------------+
  | # Session recording policy for historian access                        |
  | wabadmin recording-policy create historian-full-recording              |
  |   --video-enabled true                                                 |
  |   --video-quality high                                                 |
  |   --keystroke-logging true                                             |
  |   --ocr-indexing true                                                  |
  |   --metadata-capture true                                              |
  |   --retention-days 365                                                 |
  |   --storage-path "/recordings/historian/"                              |
  |                                                                        |
  | # Apply to historian authorizations                                    |
  | wabadmin authorization update historian-administration                 |
  |   --recording-policy historian-full-recording                          |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### Query Auditing

```
+===============================================================================+
|                    HISTORIAN QUERY AUDITING                                   |
+===============================================================================+

  QUERY AUDIT REQUIREMENTS
  ========================

  +------------------------------------------------------------------------+
  |                                                                        |
  |  CAPTURE REQUIREMENTS                                                  |
  |  ====================                                                  |
  |                                                                        |
  |  For compliance and security, capture:                                 |
  |                                                                        |
  |  1. Query Metadata                                                     |
  |     - User identity                                                    |
  |     - Timestamp                                                        |
  |     - Source IP/system                                                 |
  |     - Query duration                                                   |
  |                                                                        |
  |  2. Query Content                                                      |
  |     - Tags/points accessed                                             |
  |     - Time range queried                                               |
  |     - Aggregation type                                                 |
  |     - Number of values returned                                        |
  |                                                                        |
  |  3. Export Activities                                                  |
  |     - Data volume exported                                             |
  |     - Destination of export                                            |
  |     - File format                                                      |
  |     - Tags included in export                                          |
  |                                                                        |
  +------------------------------------------------------------------------+

  ---------------------------------------------------------------------------

  AUDIT LOG INTEGRATION
  =====================

  Configure historians to send audit logs to SIEM:

  OSIsoft PI:
  +------------------------------------------------------------------------+
  | # PI Message Log configuration                                         |
  | # Configure in PI Data Archive tuning parameters                       |
  |                                                                        |
  | # Forward to WALLIX via syslog                                         |
  | wabadmin syslog-integration create pi-audit-logs                       |
  |   --source "PI-DATA-ARCHIVE"                                           |
  |   --port 514                                                           |
  |   --protocol tcp-tls                                                   |
  |   --format cef                                                         |
  +------------------------------------------------------------------------+

  AVEVA Historian:
  +------------------------------------------------------------------------+
  | # Configure SQL Server Audit                                           |
  | # Forward Windows Event Log to SIEM                                    |
  |                                                                        |
  | wabadmin syslog-integration create aveva-audit-logs                    |
  |   --source "AVEVA-HISTORIAN-SQL"                                       |
  |   --port 514                                                           |
  |   --protocol tcp-tls                                                   |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### Data Export Tracking

```
+===============================================================================+
|                    DATA EXPORT TRACKING                                       |
+===============================================================================+

  EXPORT CONTROL STRATEGY
  =======================

  +------------------------------------------------------------------------+
  |                                                                        |
  |  RISK: BULK DATA EXPORT                                                |
  |  ======================                                                |
  |                                                                        |
  |  Historians contain valuable operational data that could be:           |
  |  - Stolen for competitive advantage                                    |
  |  - Used for industrial espionage                                       |
  |  - Manipulated to hide process deviations                              |
  |  - Exported to unauthorized systems                                    |
  |                                                                        |
  +------------------------------------------------------------------------+

  WALLIX CONTROLS FOR EXPORT
  ==========================

  +------------------------------------------------------------------------+
  |                                                                        |
  |  1. CLIPBOARD RESTRICTIONS                                             |
  |     +--------------------------------------------------------------+   |
  |     | wabadmin service update HISTORIAN-WS/RDP                     |   |
  |     |   --clipboard-enabled false                                  |   |
  |     |   --drive-redirection false                                  |   |
  |     +--------------------------------------------------------------+   |
  |                                                                        |
  |  2. FILE TRANSFER CONTROLS                                             |
  |     +--------------------------------------------------------------+   |
  |     | # Disable file upload/download                               |   |
  |     | wabadmin authorization update historian-analytics            |   |
  |     |   --file-upload-enabled false                                |   |
  |     |   --file-download-enabled false                              |   |
  |     +--------------------------------------------------------------+   |
  |                                                                        |
  |  3. APPROVAL FOR EXPORT SESSIONS                                       |
  |     +--------------------------------------------------------------+   |
  |     | wabadmin authorization create historian-export-access        |   |
  |     |   --user-group "Data-Export-Users"                           |   |
  |     |   --target "HISTORIAN-EXPORT-WS/RDP/export_user"            |   |
  |     |   --approval-required true                                   |   |
  |     |   --approval-workflow "data-export-approval"                 |   |
  |     |   --has-comment true                                         |   |
  |     |   --session-recording true                                   |   |
  |     +--------------------------------------------------------------+   |
  |                                                                        |
  |  4. ALERT ON LARGE QUERIES                                             |
  |     +--------------------------------------------------------------+   |
  |     | # Configure historian-level alerts for bulk queries          |   |
  |     | # Forward alerts to security monitoring                      |   |
  |     +--------------------------------------------------------------+   |
  |                                                                        |
  +------------------------------------------------------------------------+

+===============================================================================+
```

---

## Data Protection

### Sensitive Data Access Controls

```
+===============================================================================+
|                    HISTORIAN DATA PROTECTION                                  |
+===============================================================================+

  SENSITIVE DATA CLASSIFICATION
  =============================

  +------------------------------------------------------------------------+
  |                                                                        |
  |  +----------------------+-------------------------------------------+  |
  |  | Classification       | Examples                                  |  |
  |  +----------------------+-------------------------------------------+  |
  |  | Highly Confidential  | - Proprietary formulas/recipes            |  |
  |  |                      | - Energy consumption (cost data)          |  |
  |  |                      | - Production rates (competitive intel)    |  |
  |  |                      | - Quality specifications                  |  |
  |  +----------------------+-------------------------------------------+  |
  |  | Confidential         | - Process parameters                      |  |
  |  |                      | - Equipment performance                   |  |
  |  |                      | - Maintenance indicators                  |  |
  |  +----------------------+-------------------------------------------+  |
  |  | Internal             | - General process data                    |  |
  |  |                      | - Standard operating conditions           |  |
  |  +----------------------+-------------------------------------------+  |
  |  | Public               | - Published performance metrics           |  |
  |  |                      | - Regulatory compliance data              |  |
  |  +----------------------+-------------------------------------------+  |
  |                                                                        |
  +------------------------------------------------------------------------+

  ---------------------------------------------------------------------------

  ACCESS CONTROL BY DATA CLASSIFICATION
  =====================================

  +------------------------------------------------------------------------+
  |                                                                        |
  |  HIGHLY CONFIDENTIAL DATA                                              |
  |  ========================                                              |
  |                                                                        |
  |  Access Requirements:                                                  |
  |  - Dual approval required                                              |
  |  - Limited user group                                                  |
  |  - Enhanced session recording                                          |
  |  - No bulk export capability                                           |
  |  - Audit review required                                               |
  |                                                                        |
  |  WALLIX Configuration:                                                 |
  |  +--------------------------------------------------------------------+|
  |  | wabadmin authorization create confidential-historian-access        ||
  |  |   --user-group "Authorized-Personnel-Only"                         ||
  |  |   --target "HISTORIAN-CONFIDENTIAL/RDP/restricted_user"           ||
  |  |   --approval-required true                                         ||
  |  |   --approval-workflow "dual-approval-confidential"                 ||
  |  |   --min-approvals 2                                                ||
  |  |   --session-recording true                                         ||
  |  |   --real-time-monitoring true                                      ||
  |  |   --max-session-duration 2h                                        ||
  |  +--------------------------------------------------------------------+|
  |                                                                        |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### IP Protection

```
+===============================================================================+
|                    INTELLECTUAL PROPERTY PROTECTION                           |
+===============================================================================+

  IP PROTECTION MEASURES
  ======================

  +------------------------------------------------------------------------+
  |                                                                        |
  |  PROCESS KNOWLEDGE PROTECTION                                          |
  |  ============================                                          |
  |                                                                        |
  |  Historian data often contains:                                        |
  |  - Proprietary process parameters                                      |
  |  - Optimized setpoints (years of tuning)                              |
  |  - Batch recipes and formulas                                         |
  |  - Equipment-specific configurations                                   |
  |                                                                        |
  |  PROTECTION STRATEGY                                                   |
  |  ===================                                                   |
  |                                                                        |
  |  1. Access Segregation                                                 |
  |     - Separate authorization for sensitive tag groups                  |
  |     - Role-based tag access (if historian supports)                    |
  |     - Area-specific permissions                                        |
  |                                                                        |
  |  2. Export Restrictions                                                |
  |     - Disable bulk export for sensitive data                           |
  |     - Approval workflow for any export                                 |
  |     - Watermarking of exported reports                                 |
  |                                                                        |
  |  3. Session Monitoring                                                 |
  |     - Real-time monitoring for sensitive access                        |
  |     - Alert on unusual query patterns                                  |
  |     - Review of recorded sessions                                      |
  |                                                                        |
  |  4. Time-Limited Access                                                |
  |     - Short session durations                                          |
  |     - Just-in-time access                                              |
  |     - Automatic session termination                                    |
  |                                                                        |
  +------------------------------------------------------------------------+

  ---------------------------------------------------------------------------

  VENDOR ACCESS TO PROPRIETARY DATA
  ==================================

  +------------------------------------------------------------------------+
  | # Vendor access to historian (limited visibility)                      |
  | wabadmin authorization create vendor-historian-support                 |
  |   --user-group "Historian-Vendor"                                      |
  |   --target "HISTORIAN-01/RDP/vendor_support"                          |
  |   --approval-required true                                             |
  |   --approval-workflow "vendor-access-approval"                         |
  |   --session-recording true                                             |
  |   --real-time-monitoring true                                          |
  |   --max-session-duration 2h                                            |
  |   --time-restriction "business-hours"                                  |
  |   --has-comment true                                                   |
  |   --comment-required true                                              |
  |                                                                        |
  | # Ensure vendor account has restricted tag access                      |
  | # Configure in historian security settings                             |
  +------------------------------------------------------------------------+

+===============================================================================+
```

---

## Integration with Analytics

### Data Science Access

```
+===============================================================================+
|                    ANALYTICS PLATFORM ACCESS                                  |
+===============================================================================+

  ANALYTICS USE CASES
  ===================

  +------------------------------------------------------------------------+
  |                                                                        |
  |  Modern industrial analytics require historian data access:            |
  |                                                                        |
  |  +-------------------------------------------------------------------+ |
  |  |                                                                   | |
  |  |  USE CASES                                                        | |
  |  |  =========                                                        | |
  |  |                                                                   | |
  |  |  1. Predictive Maintenance                                        | |
  |  |     - Equipment health analysis                                   | |
  |  |     - Failure prediction                                          | |
  |  |     - Maintenance optimization                                    | |
  |  |                                                                   | |
  |  |  2. Process Optimization                                          | |
  |  |     - Efficiency analysis                                         | |
  |  |     - Quality improvement                                         | |
  |  |     - Energy optimization                                         | |
  |  |                                                                   | |
  |  |  3. Anomaly Detection                                             | |
  |  |     - Process deviation identification                            | |
  |  |     - Security monitoring                                         | |
  |  |     - Quality control                                             | |
  |  |                                                                   | |
  |  +-------------------------------------------------------------------+ |
  |                                                                        |
  +------------------------------------------------------------------------+

  ---------------------------------------------------------------------------

  ARCHITECTURE FOR ANALYTICS ACCESS
  =================================

           +-------------------+
           |  Data Scientists  |
           +--------+----------+
                    |
                    | HTTPS
                    v
           +==================+
           |  WALLIX BASTION  |
           +========+=========+
                    |
        +-----------+-----------+
        |                       |
        v                       v
  +-----------+          +-----------+
  | Analytics |          | Historian |
  | Platform  |<-------->| API       |
  | (Jupyter, |  API     | Endpoint  |
  |  Databricks,|        |           |
  |  etc.)    |          |           |
  +-----------+          +-----------+


  ACCESS CONFIGURATION
  ====================

  +------------------------------------------------------------------------+
  | # Analytics workstation access                                         |
  | wabadmin device create ANALYTICS-WORKSTATION                           |
  |   --domain "Analytics-Systems"                                         |
  |   --host "analytics-ws.company.local"                                  |
  |                                                                        |
  | wabadmin service create ANALYTICS-WORKSTATION/RDP                      |
  |   --protocol rdp                                                       |
  |   --port 3389                                                          |
  |                                                                        |
  | # Data scientist account                                               |
  | wabadmin account create ANALYTICS-WORKSTATION/data_scientist           |
  |   --service RDP                                                        |
  |   --credentials auto-managed                                           |
  |                                                                        |
  | # Authorization with data governance approval                          |
  | wabadmin authorization create data-science-historian-access            |
  |   --user-group "Data-Scientists"                                       |
  |   --target "ANALYTICS-WORKSTATION/RDP/data_scientist"                 |
  |   --approval-required true                                             |
  |   --approval-group "Data-Governance"                                   |
  |   --session-recording true                                             |
  |   --time-restriction "business-hours"                                  |
  |   --has-comment true                                                   |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### ML/AI Platform Access

```
+===============================================================================+
|                    ML/AI PLATFORM ACCESS                                      |
+===============================================================================+

  ML/AI ACCESS PATTERNS
  =====================

  +------------------------------------------------------------------------+
  |                                                                        |
  |  PLATFORM TYPES                                                        |
  |  ==============                                                        |
  |                                                                        |
  |  +------------------------+---------------------------------------+   |
  |  | Platform               | Access Pattern                        |   |
  |  +------------------------+---------------------------------------+   |
  |  | On-Premises ML         | RDP to training workstations          |   |
  |  | (TensorFlow, PyTorch)  | API access to historian               |   |
  |  +------------------------+---------------------------------------+   |
  |  | Cloud ML               | Controlled API gateway                |   |
  |  | (AWS SageMaker,        | Data export with approval             |   |
  |  |  Azure ML, GCP AI)     | VPN/Private Link                      |   |
  |  +------------------------+---------------------------------------+   |
  |  | Edge ML                | Model deployment only                 |   |
  |  |                        | Training on-premises                  |   |
  |  +------------------------+---------------------------------------+   |
  |                                                                        |
  +------------------------------------------------------------------------+

  ---------------------------------------------------------------------------

  CLOUD ANALYTICS ACCESS CONTROL
  ==============================

  +------------------------------------------------------------------------+
  |                                                                        |
  |  CONTROLLED CLOUD ACCESS                                               |
  |                                                                        |
  |       +-------------------+                                            |
  |       |  Cloud Analytics  |                                            |
  |       |  (AWS/Azure/GCP)  |                                            |
  |       +--------+----------+                                            |
  |                |                                                       |
  |                | HTTPS (Approved endpoints only)                       |
  |                |                                                       |
  |       +========+=========+                                             |
  |       |    FIREWALL      |                                             |
  |       |   (Allowlist)    |                                             |
  |       +========+=========+                                             |
  |                |                                                       |
  |       +--------+----------+                                            |
  |       |  API Gateway /    |                                            |
  |       |  Data Export      |                                            |
  |       |  Service          |                                            |
  |       +--------+----------+                                            |
  |                |                                                       |
  |       +========+=========+                                             |
  |       |  WALLIX BASTION  |                                             |
  |       | (API Credential  |                                             |
  |       |  Management)     |                                             |
  |       +========+=========+                                             |
  |                |                                                       |
  |       +--------+----------+                                            |
  |       |   HISTORIAN       |                                            |
  |       +-------------------+                                            |
  |                                                                        |
  +------------------------------------------------------------------------+

  API CREDENTIAL MANAGEMENT
  =========================

  +------------------------------------------------------------------------+
  | # API credentials for cloud analytics                                  |
  | wabadmin account create HISTORIAN-API/cloud_analytics_svc              |
  |   --service API                                                        |
  |   --credentials auto-managed                                           |
  |   --api-key-enabled true                                               |
  |   --rotate-password-days 30                                            |
  |   --checkout-required true                                             |
  |   --checkout-duration-hours 24                                         |
  |   --description "Cloud analytics service account"                      |
  |                                                                        |
  | # Approval for API credential checkout                                 |
  | wabadmin authorization create cloud-analytics-api-access               |
  |   --user-group "ML-Engineers"                                          |
  |   --target "HISTORIAN-API/cloud_analytics_svc"                        |
  |   --approval-required true                                             |
  |   --approval-group "Data-Governance"                                   |
  |   --has-comment true                                                   |
  +------------------------------------------------------------------------+

+===============================================================================+
```

---

## Compliance

### FDA 21 CFR Part 11

```
+===============================================================================+
|                    FDA 21 CFR PART 11 COMPLIANCE                              |
+===============================================================================+

  ELECTRONIC RECORDS AND SIGNATURES
  ==================================

  21 CFR Part 11 establishes requirements for electronic records and
  signatures in FDA-regulated industries (pharmaceuticals, biotech,
  medical devices, food).

  WALLIX SUPPORT FOR PART 11
  ==========================

  +------------------------------------------------------------------------+
  |                                                                        |
  |  REQUIREMENT                          WALLIX IMPLEMENTATION            |
  |  ===========                          =====================            |
  |                                                                        |
  |  11.10(a) - Validation                System validation documentation  |
  |                                       IQ/OQ/PQ support                 |
  |                                                                        |
  |  11.10(b) - Accurate and Complete     Full session recording           |
  |             Records                   Tamper-evident audit logs        |
  |                                       Timestamp accuracy (NTP)         |
  |                                                                        |
  |  11.10(c) - Record Protection         Encrypted storage                |
  |                                       Access controls                  |
  |                                       Backup procedures                |
  |                                                                        |
  |  11.10(d) - Limited System Access     Role-based access control        |
  |                                       Individual accountability        |
  |                                       MFA authentication               |
  |                                                                        |
  |  11.10(e) - Audit Trail               Complete audit logging           |
  |                                       Session recordings               |
  |                                       Immutable audit records          |
  |                                                                        |
  |  11.10(g) - Authority Checks          Authorization policies           |
  |                                       Approval workflows               |
  |                                       Credential management            |
  |                                                                        |
  |  11.10(k) - Device Checks             Session source identification    |
  |                                       IP logging                       |
  |                                       Device fingerprinting            |
  |                                                                        |
  +------------------------------------------------------------------------+

  ---------------------------------------------------------------------------

  HISTORIAN-SPECIFIC PART 11 CONTROLS
  ====================================

  +------------------------------------------------------------------------+
  | # Part 11 compliant authorization for historian access                 |
  | wabadmin authorization create fda-historian-access                     |
  |   --user-group "Production-Personnel"                                  |
  |   --target "HISTORIAN-PHARMA/RDP/production_user"                     |
  |   --session-recording true                                             |
  |   --recording-policy "fda-compliant-recording"                         |
  |   --mfa-required true                                                  |
  |   --approval-required true                                             |
  |   --has-comment true                                                   |
  |   --comment-required true                                              |
  |   --electronic-signature-on-approval true                              |
  |                                                                        |
  | # Recording policy for Part 11                                         |
  | wabadmin recording-policy create fda-compliant-recording               |
  |   --video-enabled true                                                 |
  |   --keystroke-logging true                                             |
  |   --ocr-indexing true                                                  |
  |   --retention-days 2555  # 7 years                                     |
  |   --tamper-protection enabled                                          |
  |   --digital-signature enabled                                          |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### Data Integrity Requirements

```
+===============================================================================+
|                    DATA INTEGRITY (ALCOA+)                                    |
+===============================================================================+

  ALCOA+ PRINCIPLES
  =================

  +------------------------------------------------------------------------+
  |                                                                        |
  |  ALCOA+ is the data integrity framework for regulated industries:      |
  |                                                                        |
  |  +---------------+---------------------------------------------+      |
  |  | Principle     | WALLIX Implementation                       |      |
  |  +---------------+---------------------------------------------+      |
  |  | Attributable  | Individual user identification              |      |
  |  |               | No shared accounts                          |      |
  |  |               | Session attribution in recordings           |      |
  |  +---------------+---------------------------------------------+      |
  |  | Legible       | Clear session recordings                    |      |
  |  |               | Readable audit logs                         |      |
  |  |               | Structured log format                       |      |
  |  +---------------+---------------------------------------------+      |
  |  | Contemporaneous| Real-time recording                        |      |
  |  |               | Accurate timestamps                         |      |
  |  |               | NTP synchronization                         |      |
  |  +---------------+---------------------------------------------+      |
  |  | Original      | Recording preservation                      |      |
  |  |               | No modification of records                  |      |
  |  |               | Tamper-evident storage                      |      |
  |  +---------------+---------------------------------------------+      |
  |  | Accurate      | Full session capture                        |      |
  |  |               | OCR indexing for searchability              |      |
  |  |               | Complete audit trail                        |      |
  |  +---------------+---------------------------------------------+      |
  |  | Complete      | All sessions recorded                       |      |
  |  |               | No gaps in audit trail                      |      |
  |  |               | Comprehensive metadata                      |      |
  |  +---------------+---------------------------------------------+      |
  |  | Consistent    | Standardized recording policies             |      |
  |  |               | Uniform authorization structure             |      |
  |  |               | Repeatable processes                        |      |
  |  +---------------+---------------------------------------------+      |
  |  | Enduring      | Long-term retention                         |      |
  |  |               | Archive management                          |      |
  |  |               | Media migration support                     |      |
  |  +---------------+---------------------------------------------+      |
  |  | Available     | Quick retrieval capability                  |      |
  |  |               | Search and replay functions                 |      |
  |  |               | Audit response support                      |      |
  |  +---------------+---------------------------------------------+      |
  |                                                                        |
  +------------------------------------------------------------------------+

+===============================================================================+
```

### Audit Trail Requirements

```
+===============================================================================+
|                    AUDIT TRAIL REQUIREMENTS                                   |
+===============================================================================+

  AUDIT TRAIL CONTENT
  ===================

  +------------------------------------------------------------------------+
  |                                                                        |
  |  REQUIRED AUDIT INFORMATION                                            |
  |  ==========================                                            |
  |                                                                        |
  |  +--------------------+-------------------------------------------+   |
  |  | Element            | Details                                   |   |
  |  +--------------------+-------------------------------------------+   |
  |  | User Identity      | Unique user ID, not shared account        |   |
  |  | Timestamp          | Date/time with timezone (UTC preferred)   |   |
  |  | Action             | What was done (view, modify, delete)      |   |
  |  | Old Value          | Previous value (for modifications)        |   |
  |  | New Value          | New value after change                    |   |
  |  | Reason             | Justification/comment (if required)       |   |
  |  | Electronic Sig     | If signature required for action          |   |
  |  | System/Location    | Source system and access point            |   |
  |  +--------------------+-------------------------------------------+   |
  |                                                                        |
  +------------------------------------------------------------------------+

  ---------------------------------------------------------------------------

  WALLIX AUDIT TRAIL CONFIGURATION
  ================================

  +------------------------------------------------------------------------+
  | # Enable comprehensive audit logging                                   |
  | wabadmin audit-config update                                           |
  |   --log-level detailed                                                 |
  |   --include-session-metadata true                                      |
  |   --include-approval-details true                                      |
  |   --include-credential-checkout true                                   |
  |   --syslog-enabled true                                                |
  |   --syslog-destination "siem.company.local"                            |
  |   --syslog-protocol tcp-tls                                            |
  |   --syslog-format cef                                                  |
  |                                                                        |
  | # Retention configuration                                              |
  | wabadmin retention-policy create compliance-retention                  |
  |   --audit-log-days 2555    # 7 years                                   |
  |   --session-recording-days 2555                                        |
  |   --archive-enabled true                                               |
  |   --archive-destination "compliant-archive-storage"                    |
  |   --archive-encryption enabled                                         |
  +------------------------------------------------------------------------+

  ---------------------------------------------------------------------------

  AUDIT REPORT GENERATION
  =======================

  +------------------------------------------------------------------------+
  | # Generate compliance audit report                                     |
  | wabadmin audit-report generate                                         |
  |   --report-type "historian-access-compliance"                          |
  |   --start-date "2025-01-01"                                            |
  |   --end-date "2025-12-31"                                              |
  |   --include-sessions true                                              |
  |   --include-approvals true                                             |
  |   --include-credential-usage true                                      |
  |   --format pdf                                                         |
  |   --output "/reports/historian-audit-2025.pdf"                         |
  |                                                                        |
  | # Schedule regular compliance reports                                  |
  | wabadmin scheduled-report create monthly-historian-audit               |
  |   --report-type "historian-access-compliance"                          |
  |   --schedule "0 0 1 * *"    # First of each month                      |
  |   --recipients "compliance@company.com,audit@company.com"              |
  +------------------------------------------------------------------------+

+===============================================================================+
```

---

## Summary and Best Practices

### Historian Access Best Practices

```
+===============================================================================+
|                    HISTORIAN ACCESS BEST PRACTICES                            |
+===============================================================================+

  KEY RECOMMENDATIONS
  ===================

  +------------------------------------------------------------------------+
  |                                                                        |
  |  1. IMPLEMENT ROLE-BASED ACCESS                                        |
  |     - Define clear access levels (view, configure, admin)              |
  |     - Map roles to WALLIX authorization policies                       |
  |     - Use least privilege principle                                    |
  |                                                                        |
  |  2. REQUIRE APPROVAL FOR SENSITIVE ACCESS                              |
  |     - Configuration changes require approval                           |
  |     - Administrative access requires dual approval                     |
  |     - Data export requires data governance approval                    |
  |                                                                        |
  |  3. RECORD ALL SESSIONS                                                |
  |     - Enable full video recording for RDP sessions                     |
  |     - Capture keystrokes and commands                                  |
  |     - Retain recordings per compliance requirements                    |
  |                                                                        |
  |  4. PROTECT SENSITIVE DATA                                             |
  |     - Classify historian data by sensitivity                           |
  |     - Restrict bulk export capabilities                                |
  |     - Monitor for unusual query patterns                               |
  |                                                                        |
  |  5. MANAGE CREDENTIALS SECURELY                                        |
  |     - Store service account credentials in vault                       |
  |     - Rotate passwords automatically                                   |
  |     - Use checkout policies for administrative accounts                |
  |                                                                        |
  |  6. INTEGRATE WITH MONITORING                                          |
  |     - Forward audit logs to SIEM                                       |
  |     - Alert on suspicious activities                                   |
  |     - Enable real-time session monitoring                              |
  |                                                                        |
  |  7. COMPLY WITH REGULATIONS                                            |
  |     - Implement FDA 21 CFR Part 11 controls (if applicable)            |
  |     - Maintain ALCOA+ data integrity                                   |
  |     - Generate regular compliance reports                              |
  |                                                                        |
  +------------------------------------------------------------------------+

+===============================================================================+
```

---

## References

- OSIsoft PI System Documentation: https://docs.osisoft.com/
- AVEVA Historian Documentation: https://www.aveva.com/en/products/historian/
- GE Proficy Historian: https://www.ge.com/digital/applications/proficy-historian
- Honeywell PHD: https://www.honeywellprocess.com/
- FDA 21 CFR Part 11: https://www.fda.gov/regulatory-information/search-fda-guidance-documents/part-11-electronic-records-electronic-signatures-scope-and-application
- ISPE GAMP 5: https://ispe.org/publications/guidance-documents/gamp-5-guide-2nd-edition
- WALLIX Documentation: https://pam.wallix.one/documentation

---

## Next Steps

Continue to [65 - Industrial Protocol Deep Dive](../65-industrial-protocol-deep-dive/README.md) for detailed protocol-specific configurations.
