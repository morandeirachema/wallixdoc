# 35 - Performance Benchmarks and Capacity Planning

## Table of Contents

1. [Performance Overview](#performance-overview)
2. [Benchmark Methodology](#benchmark-methodology)
3. [Session Throughput](#session-throughput)
4. [Concurrent Session Limits](#concurrent-session-limits)
5. [Latency Metrics](#latency-metrics)
6. [Storage Calculations](#storage-calculations)
7. [Database Sizing](#database-sizing)
8. [Network Bandwidth Requirements](#network-bandwidth-requirements)
9. [Hardware Sizing Guide](#hardware-sizing-guide)
10. [Scaling Recommendations](#scaling-recommendations)
11. [Performance Tuning](#performance-tuning)
12. [Monitoring Metrics](#monitoring-metrics)
13. [Capacity Planning Calculator](#capacity-planning-calculator)

---

## Performance Overview

### Key Performance Indicators

```
+==============================================================================+
|                    PERFORMANCE OVERVIEW                                       |
+==============================================================================+

  KEY PERFORMANCE METRICS
  =======================

  +------------------------------------------------------------------------+
  | Metric Category        | Key Indicators                                |
  +------------------------+-----------------------------------------------+
  | Throughput             | Sessions/second, concurrent sessions          |
  | Latency                | Connection time, authentication time          |
  | Resource Utilization   | CPU, memory, disk I/O, network                |
  | Availability           | Uptime, failover time, error rate             |
  | Scalability            | Linear scaling factor, bottleneck points      |
  +------------------------+-----------------------------------------------+

  --------------------------------------------------------------------------

  PERFORMANCE ARCHITECTURE
  ========================

                         +------------------+
                         |   Load Balancer  |
                         |  (Entry Point)   |
                         +--------+---------+
                                  |
              +-------------------+-------------------+
              |                   |                   |
              v                   v                   v
    +------------------+ +------------------+ +------------------+
    |  Session Manager | |  Session Manager | |  Session Manager |
    |  (Protocol Proxy)| |  (Protocol Proxy)| |  (Protocol Proxy)|
    |                  | |                  | |                  |
    |  SSH  RDP  VNC   | |  SSH  RDP  VNC   | |  SSH  RDP  VNC   |
    +--------+---------+ +--------+---------+ +--------+---------+
             |                    |                    |
             +--------------------+--------------------+
                                  |
                    +-------------+-------------+
                    |                           |
                    v                           v
          +------------------+       +--------------------+
          |   PostgreSQL     |       |  Recording Storage |
          |   Database       |       |  (NAS/SAN)         |
          |                  |       |                    |
          |  - Auth data     |       |  - Session videos  |
          |  - Config        |       |  - Audit logs      |
          |  - Audit logs    |       |  - Keystroke data  |
          +------------------+       +--------------------+

  --------------------------------------------------------------------------

  FACTORS AFFECTING PERFORMANCE
  =============================

  +------------------------------------------------------------------------+
  | Factor                 | Impact Level | Affected Components            |
  +------------------------+--------------+--------------------------------+
  | Session Type (SSH/RDP) | High         | CPU, memory, bandwidth         |
  | Recording Enabled      | Medium       | Disk I/O, storage              |
  | OCR/Indexing Enabled   | High         | CPU during post-processing     |
  | MFA Complexity         | Low-Medium   | Authentication latency         |
  | Number of Policies     | Low          | Policy evaluation time         |
  | External Auth (LDAP)   | Medium       | Authentication latency         |
  | Concurrent Sessions    | High         | All resources                  |
  | Password Rotation      | Low          | Background CPU                 |
  | API Request Volume     | Medium       | CPU, database                  |
  | Replication Enabled    | Low-Medium   | Network, database I/O          |
  +------------------------+--------------+--------------------------------+

  --------------------------------------------------------------------------

  PERFORMANCE TIERS
  =================

  +------------------------------------------------------------------------+
  | Tier           | Concurrent  | Users    | Devices  | Use Case          |
  |                | Sessions    |          |          |                   |
  +----------------+-------------+----------+----------+-------------------+
  | Small          | < 100       | < 500    | < 200    | SMB, Department   |
  | Medium         | 100-500     | 500-2000 | 200-1000 | Mid-size Org      |
  | Large          | 500-1000    | 2000-5000| 1000-5000| Enterprise        |
  | Enterprise     | 1000-5000   | 5000+    | 5000+    | Global Enterprise |
  +----------------+-------------+----------+----------+-------------------+

+==============================================================================+
```

---

## Benchmark Methodology

### Test Environment and Procedures

```
+==============================================================================+
|                    BENCHMARK METHODOLOGY                                      |
+==============================================================================+

  TEST ENVIRONMENT SPECIFICATIONS
  ===============================

  Reference Hardware Configuration:
  +------------------------------------------------------------------------+
  | Component        | Small         | Medium        | Large/Enterprise    |
  +------------------+---------------+---------------+---------------------+
  | CPU              | 4 vCPU        | 8 vCPU        | 16-32 vCPU          |
  | Memory           | 16 GB         | 32 GB         | 64-128 GB           |
  | System Disk      | 100 GB SSD    | 100 GB SSD    | 200 GB NVMe         |
  | Data Disk        | 200 GB SSD    | 500 GB SSD    | 1 TB NVMe           |
  | Recording Disk   | 500 GB SSD    | 2 TB NAS      | 10 TB SAN           |
  | Network          | 1 Gbps        | 10 Gbps       | 10 Gbps bonded      |
  +------------------+---------------+---------------+---------------------+

  Software Configuration:
  +------------------------------------------------------------------------+
  | Component          | Version                                           |
  +--------------------+---------------------------------------------------+
  | WALLIX Bastion     | 12.1.x                                            |
  | Operating System   | Debian 12 (Bookworm)                              |
  | PostgreSQL         | 16.x with optimized settings                      |
  | Kernel             | 6.1.x with performance tuning                     |
  +--------------------+---------------------------------------------------+

  --------------------------------------------------------------------------

  TEST METHODOLOGY
  ================

  Test Tools:
  +------------------------------------------------------------------------+
  | Tool                     | Purpose                                      |
  +--------------------------+----------------------------------------------+
  | Custom session generator | Simulated SSH/RDP/VNC sessions               |
  | Apache JMeter            | API load testing                             |
  | sysbench                 | Database performance                         |
  | iperf3                   | Network throughput                           |
  | iostat/vmstat            | System resource monitoring                   |
  +------------------------------------------------------------------------+

  Test Scenarios:
  +------------------------------------------------------------------------+
  | Scenario              | Description                | Duration          |
  +-----------------------+----------------------------+-------------------+
  | Baseline              | Single session, no load    | 5 minutes         |
  | Ramp-Up               | Gradual increase to target | 30 minutes        |
  | Steady State          | Sustained target load      | 60 minutes        |
  | Spike Test            | 2x sudden increase         | 10 minutes        |
  | Endurance             | 80% capacity, extended     | 8 hours           |
  | Failover              | HA cluster failover        | 30 minutes        |
  +-----------------------+----------------------------+-------------------+

  --------------------------------------------------------------------------

  MEASUREMENT METHODOLOGY
  =======================

  Latency Measurements:
  +------------------------------------------------------------------------+
  |                                                                        |
  |  Timeline: Session Establishment                                       |
  |                                                                        |
  |  |<-- t1 -->|<-- t2 -->|<-- t3 -->|<-- t4 -->|                        |
  |  |          |          |          |          |                        |
  |  Client     Auth       Policy     Target     Session                  |
  |  Request    Check      Eval       Connect    Active                   |
  |                                                                        |
  |  t1 = Authentication latency (MFA, LDAP lookup)                       |
  |  t2 = Authorization latency (policy evaluation)                       |
  |  t3 = Target connection (network + handshake)                         |
  |  t4 = Session initialization (recording start)                        |
  |                                                                        |
  |  Total Connection Time = t1 + t2 + t3 + t4                            |
  |                                                                        |
  +------------------------------------------------------------------------+

  Throughput Measurements:
  +------------------------------------------------------------------------+
  | Metric                     | Measurement Method                        |
  +----------------------------+-------------------------------------------+
  | Sessions per second        | New sessions created per second           |
  | Max concurrent sessions    | Stable sessions at 85% resource usage     |
  | Transaction rate           | Completed operations per second           |
  | Error rate                 | Failed requests / total requests          |
  +----------------------------+-------------------------------------------+

  Statistical Reporting:
  +------------------------------------------------------------------------+
  | Percentile | Description                                               |
  +------------+-----------------------------------------------------------+
  | p50        | Median - 50% of requests faster than this                 |
  | p95        | 95th percentile - worst 5% excluded                       |
  | p99        | 99th percentile - worst 1% excluded                       |
  | p99.9      | Three nines - critical for SLA                            |
  +------------+-----------------------------------------------------------+

+==============================================================================+
```

---

## Session Throughput

### Sessions Per Second by Deployment Size

```
+==============================================================================+
|                    SESSION THROUGHPUT BENCHMARKS                              |
+==============================================================================+

  NEW SESSION ESTABLISHMENT RATE
  ==============================

  SSH Sessions (sessions/second):
  +------------------------------------------------------------------------+
  | Deployment Size    | p50     | p95     | p99     | Max Sustained       |
  +--------------------+---------+---------+---------+---------------------+
  | Small (4C/16GB)    | 12      | 10      | 8       | 15/sec              |
  | Medium (8C/32GB)   | 28      | 24      | 20      | 35/sec              |
  | Large (16C/64GB)   | 55      | 48      | 42      | 70/sec              |
  | Enterprise (32C)   | 110     | 95      | 85      | 140/sec             |
  +--------------------+---------+---------+---------+---------------------+

  RDP Sessions (sessions/second):
  +------------------------------------------------------------------------+
  | Deployment Size    | p50     | p95     | p99     | Max Sustained       |
  +--------------------+---------+---------+---------+---------------------+
  | Small (4C/16GB)    | 6       | 5       | 4       | 8/sec               |
  | Medium (8C/32GB)   | 14      | 12      | 10      | 18/sec              |
  | Large (16C/64GB)   | 28      | 24      | 21      | 35/sec              |
  | Enterprise (32C)   | 55      | 48      | 42      | 70/sec              |
  +--------------------+---------+---------+---------+---------------------+

  VNC Sessions (sessions/second):
  +------------------------------------------------------------------------+
  | Deployment Size    | p50     | p95     | p99     | Max Sustained       |
  +--------------------+---------+---------+---------+---------------------+
  | Small (4C/16GB)    | 8       | 7       | 6       | 10/sec              |
  | Medium (8C/32GB)   | 18      | 16      | 14      | 25/sec              |
  | Large (16C/64GB)   | 38      | 34      | 30      | 50/sec              |
  | Enterprise (32C)   | 75      | 68      | 60      | 100/sec             |
  +--------------------+---------+---------+---------+---------------------+

  --------------------------------------------------------------------------

  MIXED WORKLOAD THROUGHPUT
  =========================

  Typical Enterprise Mix (60% SSH, 30% RDP, 10% VNC):
  +------------------------------------------------------------------------+
  | Deployment Size    | Combined Rate | Peak Burst     | Sustained 1hr    |
  +--------------------+---------------+----------------+------------------+
  | Small (4C/16GB)    | 10/sec        | 18/sec (30s)   | 8/sec            |
  | Medium (8C/32GB)   | 24/sec        | 42/sec (30s)   | 20/sec           |
  | Large (16C/64GB)   | 48/sec        | 85/sec (30s)   | 40/sec           |
  | Enterprise (32C)   | 95/sec        | 170/sec (30s)  | 80/sec           |
  +--------------------+---------------+----------------+------------------+

  --------------------------------------------------------------------------

  THROUGHPUT VISUALIZATION
  ========================

  Sessions/Second vs CPU Cores (SSH Sessions):

     140 |                                              *
         |                                           *
         |                                        *
     120 |                                     *
         |                                  *
         |                               *
     100 |                            *
         |                         *
         |                      *
      80 |                   *
         |                *
         |             *
      60 |          *
         |       *
         |    *
      40 | *
         |
         +------------------------------------------------
           4    8   12   16   20   24   28   32   CPU Cores

  Note: Near-linear scaling up to 16 cores, diminishing returns above 24 cores

  --------------------------------------------------------------------------

  API THROUGHPUT
  ==============

  REST API Requests per Second:
  +------------------------------------------------------------------------+
  | Operation Type        | Small  | Medium | Large  | Enterprise         |
  +-----------------------+--------+--------+--------+--------------------+
  | GET (read)            | 300    | 600    | 1200   | 2500               |
  | POST (create)         | 100    | 200    | 400    | 800                |
  | PUT (update)          | 100    | 200    | 400    | 800                |
  | DELETE                | 150    | 300    | 600    | 1200               |
  | Bulk operations       | 25     | 50     | 100    | 200                |
  +-----------------------+--------+--------+--------+--------------------+

+==============================================================================+
```

---

## Concurrent Session Limits

### Maximum Concurrent Sessions by Configuration

```
+==============================================================================+
|                    CONCURRENT SESSION LIMITS                                  |
+==============================================================================+

  MAXIMUM CONCURRENT SESSIONS BY PROTOCOL
  ========================================

  SSH Sessions Only:
  +------------------------------------------------------------------------+
  | Configuration          | Max Sessions | Memory/Session | CPU/Session   |
  +------------------------+--------------+----------------+---------------+
  | 4 vCPU, 16 GB RAM      | 250          | 40 MB          | 0.8%          |
  | 8 vCPU, 32 GB RAM      | 600          | 40 MB          | 0.4%          |
  | 16 vCPU, 64 GB RAM     | 1200         | 40 MB          | 0.2%          |
  | 32 vCPU, 128 GB RAM    | 2500         | 40 MB          | 0.1%          |
  +------------------------+--------------+----------------+---------------+

  RDP Sessions Only:
  +------------------------------------------------------------------------+
  | Configuration          | Max Sessions | Memory/Session | CPU/Session   |
  +------------------------+--------------+----------------+---------------+
  | 4 vCPU, 16 GB RAM      | 100          | 120 MB         | 2.5%          |
  | 8 vCPU, 32 GB RAM      | 250          | 120 MB         | 1.2%          |
  | 16 vCPU, 64 GB RAM     | 500          | 120 MB         | 0.6%          |
  | 32 vCPU, 128 GB RAM    | 1000         | 120 MB         | 0.3%          |
  +------------------------+--------------+----------------+---------------+

  VNC Sessions Only:
  +------------------------------------------------------------------------+
  | Configuration          | Max Sessions | Memory/Session | CPU/Session   |
  +------------------------+--------------+----------------+---------------+
  | 4 vCPU, 16 GB RAM      | 150          | 80 MB          | 1.5%          |
  | 8 vCPU, 32 GB RAM      | 375          | 80 MB          | 0.8%          |
  | 16 vCPU, 64 GB RAM     | 750          | 80 MB          | 0.4%          |
  | 32 vCPU, 128 GB RAM    | 1500         | 80 MB          | 0.2%          |
  +------------------------+--------------+----------------+---------------+

  --------------------------------------------------------------------------

  MIXED WORKLOAD CAPACITY
  =======================

  Enterprise Mix (60% SSH, 30% RDP, 10% VNC):
  +------------------------------------------------------------------------+
  | Configuration          | SSH      | RDP      | VNC      | Total        |
  +------------------------+----------+----------+----------+--------------+
  | 4 vCPU, 16 GB RAM      | 90       | 30       | 15       | 135          |
  | 8 vCPU, 32 GB RAM      | 210      | 75       | 40       | 325          |
  | 16 vCPU, 64 GB RAM     | 450      | 150      | 75       | 675          |
  | 32 vCPU, 128 GB RAM    | 900      | 300      | 150      | 1350         |
  +------------------------+----------+----------+----------+--------------+

  OT/Industrial Mix (40% SSH, 20% RDP, 20% VNC, 20% Industrial):
  +------------------------------------------------------------------------+
  | Configuration          | SSH      | RDP      | VNC      | Industrial   |
  +------------------------+----------+----------+----------+--------------+
  | 8 vCPU, 32 GB RAM      | 160      | 50       | 60       | 80           |
  | 16 vCPU, 64 GB RAM     | 320      | 100      | 120      | 160          |
  | 32 vCPU, 128 GB RAM    | 640      | 200      | 240      | 320          |
  +------------------------+----------+----------+----------+--------------+

  --------------------------------------------------------------------------

  SESSION CAPACITY FORMULA
  ========================

  +------------------------------------------------------------------------+
  |                                                                        |
  |  Concurrent Session Capacity Formula:                                  |
  |                                                                        |
  |  Max Sessions = MIN(CPU Limit, Memory Limit)                           |
  |                                                                        |
  |  Where:                                                                |
  |    CPU Limit = (Available CPU %) / (CPU per Session %)                 |
  |    Memory Limit = (Available RAM - OS Overhead) / (Memory per Session) |
  |                                                                        |
  |  Example (16 vCPU, 64 GB, Mixed workload):                             |
  |    Available CPU = 85% of 1600% = 1360%                                |
  |    Available RAM = 64 GB - 8 GB (OS) = 56 GB                           |
  |                                                                        |
  |    SSH: 1360% / 0.2% = 6800 (CPU) vs 56000 MB / 40 MB = 1400 (RAM)     |
  |    RDP: 1360% / 0.6% = 2266 (CPU) vs 56000 MB / 120 MB = 466 (RAM)     |
  |                                                                        |
  |    Mixed (60/30/10):                                                   |
  |      SSH component: 0.6 x MIN(6800, 1400) = 840                        |
  |      RDP component: 0.3 x MIN(2266, 466) = 140                         |
  |      VNC component: 0.1 x MIN(4533, 700) = 70                          |
  |      Total = ~675 sessions (RAM limited for RDP)                       |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  RECORDING IMPACT ON CAPACITY
  ============================

  +------------------------------------------------------------------------+
  | Recording Mode         | Capacity Reduction | Additional Resources     |
  +------------------------+--------------------+--------------------------+
  | Recording Disabled     | 0%                 | None                     |
  | Text Only (SSH)        | 5%                 | +10 MB/session           |
  | Standard Recording     | 15%                | +30 MB/session, I/O      |
  | High Quality Recording | 25%                | +50 MB/session, I/O      |
  | OCR Enabled            | 35%                | +100 MB/session, CPU     |
  +------------------------+--------------------+--------------------------+

+==============================================================================+
```

---

## Latency Metrics

### Connection and Authentication Latency

```
+==============================================================================+
|                    LATENCY METRICS                                            |
+==============================================================================+

  SSH SESSION ESTABLISHMENT LATENCY
  =================================

  Component Breakdown:
  +------------------------------------------------------------------------+
  | Phase                  | p50      | p95      | p99      | p99.9        |
  +------------------------+----------+----------+----------+--------------+
  | Authentication (local) | 45 ms    | 85 ms    | 150 ms   | 300 ms       |
  | Authentication (LDAP)  | 120 ms   | 280 ms   | 450 ms   | 800 ms       |
  | Authentication (MFA)   | 180 ms   | 350 ms   | 550 ms   | 1000 ms      |
  | Policy Evaluation      | 15 ms    | 35 ms    | 60 ms    | 120 ms       |
  | Target Connection      | 80 ms    | 180 ms   | 350 ms   | 700 ms       |
  | Session Initialization | 50 ms    | 95 ms    | 160 ms   | 300 ms       |
  +------------------------+----------+----------+----------+--------------+
  | Total (Local Auth)     | 190 ms   | 395 ms   | 720 ms   | 1420 ms      |
  | Total (LDAP + MFA)     | 445 ms   | 940 ms   | 1570 ms  | 2920 ms      |
  +------------------------+----------+----------+----------+--------------+

  --------------------------------------------------------------------------

  RDP SESSION ESTABLISHMENT LATENCY
  =================================

  Component Breakdown:
  +------------------------------------------------------------------------+
  | Phase                  | p50      | p95      | p99      | p99.9        |
  +------------------------+----------+----------+----------+--------------+
  | Authentication         | 180 ms   | 350 ms   | 550 ms   | 1000 ms      |
  | Policy Evaluation      | 15 ms    | 35 ms    | 60 ms    | 120 ms       |
  | NLA Negotiation        | 350 ms   | 650 ms   | 1100 ms  | 2000 ms      |
  | Target Connection      | 250 ms   | 480 ms   | 800 ms   | 1500 ms      |
  | First Frame Display    | 400 ms   | 750 ms   | 1200 ms  | 2200 ms      |
  +------------------------+----------+----------+----------+--------------+
  | Total (First Frame)    | 1195 ms  | 2265 ms  | 3710 ms  | 6820 ms      |
  | Total (Usable Session) | 1800 ms  | 3200 ms  | 5000 ms  | 8000 ms      |
  +------------------------+----------+----------+----------+--------------+

  --------------------------------------------------------------------------

  VNC SESSION ESTABLISHMENT LATENCY
  =================================

  +------------------------------------------------------------------------+
  | Phase                  | p50      | p95      | p99      | p99.9        |
  +------------------------+----------+----------+----------+--------------+
  | Authentication         | 180 ms   | 350 ms   | 550 ms   | 1000 ms      |
  | Policy Evaluation      | 15 ms    | 35 ms    | 60 ms    | 120 ms       |
  | Target Connection      | 150 ms   | 320 ms   | 550 ms   | 1000 ms      |
  | First Frame Display    | 300 ms   | 580 ms   | 950 ms   | 1800 ms      |
  +------------------------+----------+----------+----------+--------------+
  | Total                  | 645 ms   | 1285 ms  | 2110 ms  | 3920 ms      |
  +------------------------+----------+----------+----------+--------------+

  --------------------------------------------------------------------------

  LATENCY UNDER LOAD
  ==================

  SSH Connection Time vs Concurrent Sessions:

  Latency (ms)
  |
  2500 |                                           *
       |                                        *
  2000 |                                     *
       |                                  *
  1500 |                              *
       |                          *
  1000 |                     *
       |                 *
   500 |         *   *
       |   *  *
   200 +---*-----------------------------------------------
       0    100   200   300   400   500   600   700   800
                                        Concurrent Sessions

  Note: Latency increases exponentially after 70% capacity

  +------------------------------------------------------------------------+
  | Load Level  | SSH p50 | SSH p99 | RDP p50 | RDP p99 | Recommendation  |
  +-------------+---------+---------+---------+---------+-----------------+
  | 25%         | 190 ms  | 350 ms  | 1.2 s   | 2.5 s   | Optimal         |
  | 50%         | 250 ms  | 480 ms  | 1.5 s   | 3.2 s   | Normal          |
  | 75%         | 420 ms  | 850 ms  | 2.2 s   | 4.5 s   | Acceptable      |
  | 85%         | 650 ms  | 1400 ms | 3.0 s   | 6.0 s   | Near limit      |
  | 95%         | 1200 ms | 2800 ms | 4.5 s   | 9.0 s   | Degraded        |
  +-------------+---------+---------+---------+---------+-----------------+

  --------------------------------------------------------------------------

  AUTHENTICATION LATENCY BY METHOD
  =================================

  +------------------------------------------------------------------------+
  | Auth Method               | p50      | p95      | Notes                |
  +---------------------------+----------+----------+----------------------+
  | Local Password            | 25 ms    | 60 ms    | Fastest              |
  | LDAP (same datacenter)    | 80 ms    | 180 ms   | Network dependent    |
  | LDAP (remote)             | 150 ms   | 400 ms   | Latency sensitive    |
  | Active Directory          | 100 ms   | 250 ms   | Kerberos adds 50ms   |
  | RADIUS                    | 90 ms    | 220 ms   | Network dependent    |
  | FortiToken     | 50 ms    | 120 ms   | Local validation     |
  | FortiAuthenticator            | 150 ms   | 350 ms   | Client dependent     |
  | Smart Card (X.509)        | 200 ms   | 450 ms   | PKI lookup           |
  | Combined (LDAP + FortiToken)    | 130 ms   | 300 ms   | Parallel possible    |
  +---------------------------+----------+----------+----------------------+

+==============================================================================+
```

---

## Storage Calculations

### Session Recording Storage Requirements

```
+==============================================================================+
|                    STORAGE CALCULATIONS                                       |
+==============================================================================+

  SESSION RECORDING STORAGE RATES
  ===============================

  SSH Session Recording:
  +------------------------------------------------------------------------+
  | Recording Mode     | MB/Hour  | GB/Day (8hr) | Characteristics          |
  +--------------------+----------+--------------+--------------------------+
  | Disabled           | 0        | 0            | No audit trail           |
  | Metadata Only      | 0.5      | 0.004        | Commands only            |
  | Text Capture       | 2-8      | 0.016-0.064  | Full I/O capture         |
  | Full Session       | 10-25    | 0.08-0.2     | With timing/metadata     |
  | High Detail        | 30-50    | 0.24-0.4     | Enhanced indexing        |
  +--------------------+----------+--------------+--------------------------+

  RDP Session Recording:
  +------------------------------------------------------------------------+
  | Recording Mode     | MB/Hour  | GB/Day (8hr) | Characteristics          |
  +--------------------+----------+--------------+--------------------------+
  | Disabled           | 0        | 0            | No audit trail           |
  | Low Quality        | 30-60    | 0.24-0.48    | 800x600, 8-bit, 5fps     |
  | Standard           | 80-150   | 0.64-1.2     | 1024x768, 16-bit, 10fps  |
  | High Quality       | 200-400  | 1.6-3.2      | 1920x1080, 24-bit, 15fps |
  | Ultra HD           | 500-1000 | 4.0-8.0      | 4K, 32-bit, 30fps        |
  | OCR Enabled        | +50%     | +50%         | Adds text extraction     |
  +--------------------+----------+--------------+--------------------------+

  VNC Session Recording:
  +------------------------------------------------------------------------+
  | Recording Mode     | MB/Hour  | GB/Day (8hr) | Characteristics          |
  +--------------------+----------+--------------+--------------------------+
  | Standard           | 50-100   | 0.4-0.8      | Compressed frames        |
  | High Quality       | 120-250  | 0.96-2.0     | Better frame rate        |
  +--------------------+----------+--------------+--------------------------+

  Industrial Protocol Recording:
  +------------------------------------------------------------------------+
  | Protocol           | MB/Hour  | GB/Day (8hr) | Notes                    |
  +--------------------+----------+--------------+--------------------------+
  | Modbus TCP         | 1-5      | 0.008-0.04   | Command/response pairs   |
  | OPC UA             | 5-20     | 0.04-0.16    | Depends on data volume   |
  | DNP3               | 2-10     | 0.016-0.08   | Event-driven             |
  +--------------------+----------+--------------+--------------------------+

  --------------------------------------------------------------------------

  MONTHLY STORAGE CALCULATOR
  ==========================

  +------------------------------------------------------------------------+
  |                                                                        |
  |  Storage Formula:                                                      |
  |                                                                        |
  |  Monthly Storage (GB) = Sum of all session types:                      |
  |                                                                        |
  |    For each protocol:                                                  |
  |      Sessions/Day x Avg Duration (hrs) x Storage Rate (GB/hr) x 30     |
  |                                                                        |
  |  Example Calculation:                                                  |
  |  +-----------------------------------------------------------------+  |
  |  | Protocol | Sessions/Day | Duration | Rate GB/hr | Monthly GB    |  |
  |  +----------+--------------+----------+------------+---------------+  |
  |  | SSH      | 200          | 2.5 hrs  | 0.015      | 225           |  |
  |  | RDP      | 100          | 3.0 hrs  | 0.12       | 1080          |  |
  |  | VNC      | 25           | 1.5 hrs  | 0.075      | 84            |  |
  |  +----------+--------------+----------+------------+---------------+  |
  |  | TOTAL    | 325          | -        | -          | 1389 GB/month |  |
  |  +-----------------------------------------------------------------+  |
  |                                                                        |
  |  Add 20% overhead for metadata and indexing: 1389 x 1.2 = 1667 GB     |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  STORAGE SIZING BY DEPLOYMENT
  ============================

  +------------------------------------------------------------------------+
  | Deployment   | Sessions/Day | Avg Duration | Monthly Raw | With Index  |
  +--------------+--------------+--------------+-------------+-------------+
  | Small        | 50           | 2.0 hrs      | 150 GB      | 180 GB      |
  | Medium       | 200          | 2.5 hrs      | 750 GB      | 900 GB      |
  | Large        | 500          | 3.0 hrs      | 2.2 TB      | 2.7 TB      |
  | Enterprise   | 2000         | 3.5 hrs      | 10 TB       | 12 TB       |
  +--------------+--------------+--------------+-------------+-------------+

  Annual Storage with Retention:
  +------------------------------------------------------------------------+
  | Deployment   | 30-Day      | 90-Day       | 180-Day     | 365-Day     |
  +--------------+-------------+--------------+-------------+-------------+
  | Small        | 180 GB      | 540 GB       | 1.1 TB      | 2.2 TB      |
  | Medium       | 900 GB      | 2.7 TB       | 5.4 TB      | 10.8 TB     |
  | Large        | 2.7 TB      | 8.1 TB       | 16.2 TB     | 32.4 TB     |
  | Enterprise   | 12 TB       | 36 TB        | 72 TB       | 144 TB      |
  +--------------+-------------+--------------+-------------+-------------+

  --------------------------------------------------------------------------

  STORAGE I/O REQUIREMENTS
  ========================

  +------------------------------------------------------------------------+
  | Concurrent Sessions | Write IOPS  | Read IOPS   | Throughput (MB/s)   |
  +---------------------+-------------+-------------+---------------------+
  | 50                  | 500         | 100         | 25                  |
  | 100                 | 1000        | 200         | 50                  |
  | 250                 | 2500        | 500         | 125                 |
  | 500                 | 5000        | 1000        | 250                 |
  | 1000                | 10000       | 2000        | 500                 |
  +---------------------+-------------+-------------+---------------------+

  Storage Technology Recommendations:
  +------------------------------------------------------------------------+
  | Concurrent Sessions | Recommended Storage                              |
  +---------------------+--------------------------------------------------+
  | < 100               | Local SSD or enterprise NAS                      |
  | 100-500             | Enterprise NAS (NFSv4.1) or iSCSI SAN            |
  | 500-1000            | High-performance SAN or all-flash NAS            |
  | > 1000              | All-flash SAN with dedicated storage network     |
  +---------------------+--------------------------------------------------+

+==============================================================================+
```

---

## Database Sizing

### PostgreSQL Requirements by Object Count

```
+==============================================================================+
|                    DATABASE SIZING                                            |
+==============================================================================+

  DATABASE SIZE BY OBJECT COUNT
  =============================

  Core Objects Storage:
  +------------------------------------------------------------------------+
  | Object Type          | Size per Object | 1000 Objects | 10000 Objects  |
  +----------------------+-----------------+--------------+----------------+
  | Users                | 5 KB            | 5 MB         | 50 MB          |
  | Devices              | 8 KB            | 8 MB         | 80 MB          |
  | Accounts             | 4 KB            | 4 MB         | 40 MB          |
  | Authorization Rules  | 3 KB            | 3 MB         | 30 MB          |
  | Groups               | 2 KB            | 2 MB         | 20 MB          |
  | Domains              | 1 KB            | 1 MB         | 10 MB          |
  +----------------------+-----------------+--------------+----------------+

  Audit and Session Data:
  +------------------------------------------------------------------------+
  | Data Type                | Size per Entry | Per Day (500 sessions)    |
  +--------------------------+----------------+---------------------------+
  | Session metadata         | 2 KB           | 1 MB                      |
  | Authentication logs      | 0.5 KB         | 2.5 MB (5000 attempts)    |
  | Authorization logs       | 0.3 KB         | 1.5 MB (5000 decisions)   |
  | Password checkout logs   | 0.4 KB         | 0.4 MB (1000 checkouts)   |
  | API audit logs           | 0.6 KB         | 6 MB (10000 calls)        |
  +--------------------------+----------------+---------------------------+

  --------------------------------------------------------------------------

  DATABASE SIZE FORMULA
  =====================

  +------------------------------------------------------------------------+
  |                                                                        |
  |  Total DB Size = Base Objects + Audit Data + Overhead                  |
  |                                                                        |
  |  Base Objects:                                                         |
  |    = (Users x 5KB) + (Devices x 8KB) + (Accounts x 4KB)                |
  |      + (Rules x 3KB) + (Groups x 2KB)                                  |
  |                                                                        |
  |  Audit Data (30-day retention):                                        |
  |    = Daily Audit Size x 30 days                                        |
  |    = (Sessions x 2KB + AuthLogs x 0.5KB + APILogs x 0.6KB) x 30        |
  |                                                                        |
  |  Overhead (indexes, WAL, temp):                                        |
  |    = (Base + Audit) x 0.4                                              |
  |                                                                        |
  |  Example (Medium deployment):                                          |
  |    Base: 1500 users, 800 devices, 2000 accounts, 500 rules             |
  |      = (1500x5) + (800x8) + (2000x4) + (500x3) + (200x2)               |
  |      = 7.5 + 6.4 + 8 + 1.5 + 0.4 = 23.8 MB                             |
  |                                                                        |
  |    Audit (500 sessions/day, 30 days):                                  |
  |      = (500x2 + 3000x0.5 + 8000x0.6) x 30                              |
  |      = (1000 + 1500 + 4800) x 30 = 219 MB                              |
  |                                                                        |
  |    Total = (23.8 + 219) x 1.4 = 340 MB                                 |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  RECOMMENDED DATABASE ALLOCATION
  ===============================

  +------------------------------------------------------------------------+
  | Deployment   | Users   | Devices | Sessions/Day | Recommended DB Size  |
  +--------------+---------+---------+--------------+----------------------+
  | Small        | 500     | 200     | 100          | 10 GB                |
  | Medium       | 2000    | 1000    | 500          | 50 GB                |
  | Large        | 5000    | 3000    | 1500         | 150 GB               |
  | Enterprise   | 15000   | 10000   | 5000         | 500 GB               |
  +--------------+---------+---------+--------------+----------------------+

  Note: Includes 90-day audit retention and 50% growth buffer

  --------------------------------------------------------------------------

  POSTGRESQL PERFORMANCE REQUIREMENTS
  ===================================

  Connection Pool Sizing:
  +------------------------------------------------------------------------+
  | Concurrent Sessions | Min Connections | Recommended | Max Connections  |
  +---------------------+-----------------+-------------+------------------+
  | 100                 | 50              | 100         | 200              |
  | 250                 | 100             | 200         | 400              |
  | 500                 | 150             | 300         | 600              |
  | 1000                | 250             | 500         | 1000             |
  | 2000                | 400             | 800         | 1500             |
  +---------------------+-----------------+-------------+------------------+

  Memory Allocation:
  +------------------------------------------------------------------------+
  | System RAM | shared_buffers | effective_cache_size | work_mem         |
  +------------+----------------+----------------------+------------------+
  | 16 GB      | 4 GB           | 12 GB                | 128 MB           |
  | 32 GB      | 8 GB           | 24 GB                | 256 MB           |
  | 64 GB      | 16 GB          | 48 GB                | 512 MB           |
  | 128 GB     | 32 GB          | 96 GB                | 1 GB             |
  +------------+----------------+----------------------+------------------+

  Disk IOPS Requirements:
  +------------------------------------------------------------------------+
  | Concurrent Sessions | Read IOPS | Write IOPS | Recommended Disk Type  |
  +---------------------+-----------+------------+------------------------+
  | < 100               | 500       | 200        | Enterprise SSD         |
  | 100-500             | 2000      | 800        | NVMe SSD               |
  | 500-1000            | 5000      | 2000       | NVMe RAID              |
  | > 1000              | 10000+    | 4000+      | Enterprise NVMe SAN    |
  +---------------------+-----------+------------+------------------------+

+==============================================================================+
```

---

## Network Bandwidth Requirements

### Bandwidth Calculations by Protocol

```
+==============================================================================+
|                    NETWORK BANDWIDTH REQUIREMENTS                             |
+==============================================================================+

  BANDWIDTH PER SESSION
  =====================

  Session Bandwidth (User to Bastion):
  +------------------------------------------------------------------------+
  | Protocol        | Minimum    | Typical    | High Activity | Peak       |
  +-----------------+------------+------------+---------------+------------+
  | SSH (text)      | 5 Kbps     | 20 Kbps    | 100 Kbps      | 500 Kbps   |
  | SSH (SCP/SFTP)  | 10 Kbps    | 1 Mbps     | 10 Mbps       | 100 Mbps   |
  | RDP (standard)  | 100 Kbps   | 500 Kbps   | 2 Mbps        | 10 Mbps    |
  | RDP (HD video)  | 500 Kbps   | 2 Mbps     | 8 Mbps        | 25 Mbps    |
  | RDP (RemoteFX)  | 1 Mbps     | 5 Mbps     | 15 Mbps       | 50 Mbps    |
  | VNC             | 100 Kbps   | 400 Kbps   | 1.5 Mbps      | 8 Mbps     |
  | HTTP/HTTPS      | 50 Kbps    | 200 Kbps   | 1 Mbps        | 5 Mbps     |
  +-----------------+------------+------------+---------------+------------+

  Industrial Protocol Bandwidth:
  +------------------------------------------------------------------------+
  | Protocol        | Minimum    | Typical    | Notes                      |
  +-----------------+------------+------------+----------------------------+
  | Modbus TCP      | 1 Kbps     | 10 Kbps    | Low bandwidth, bursty      |
  | OPC UA          | 10 Kbps    | 100 Kbps   | Depends on subscriptions   |
  | DNP3            | 5 Kbps     | 50 Kbps    | Event-driven traffic       |
  | IEC 61850       | 50 Kbps    | 500 Kbps   | GOOSE messages add load    |
  | EtherNet/IP     | 10 Kbps    | 100 Kbps   | Cyclic data dependent      |
  +-----------------+------------+------------+----------------------------+

  --------------------------------------------------------------------------

  TOTAL BANDWIDTH FORMULA
  =======================

  +------------------------------------------------------------------------+
  |                                                                        |
  |  Total Bandwidth = User Sessions + Replication + Management            |
  |                                                                        |
  |  User Session Bandwidth:                                               |
  |    = Sum of (Sessions per Type x Avg Bandwidth per Type)               |
  |                                                                        |
  |  Example (500 concurrent sessions, mixed):                             |
  |    SSH (300 sessions x 50 Kbps)  = 15 Mbps                             |
  |    RDP (150 sessions x 1 Mbps)   = 150 Mbps                            |
  |    VNC (50 sessions x 500 Kbps)  = 25 Mbps                             |
  |    Total Session Traffic         = 190 Mbps                            |
  |                                                                        |
  |  Add Recording Overhead (+15%):  = 190 x 1.15 = 218 Mbps               |
  |  Add HA Replication (+20%):      = 218 x 1.20 = 262 Mbps               |
  |  Add Management/API (+5%):       = 262 x 1.05 = 275 Mbps               |
  |                                                                        |
  |  Recommended Interface:          = 1 Gbps (with headroom)              |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  BANDWIDTH BY DEPLOYMENT SIZE
  ============================

  User-Facing Network (Users to Bastion):
  +------------------------------------------------------------------------+
  | Deployment   | Concurrent | Avg BW/Session | Total BW | Recommended    |
  +--------------+------------+----------------+----------+----------------+
  | Small        | 100        | 400 Kbps       | 40 Mbps  | 100 Mbps       |
  | Medium       | 350        | 500 Kbps       | 175 Mbps | 500 Mbps       |
  | Large        | 750        | 600 Kbps       | 450 Mbps | 1 Gbps         |
  | Enterprise   | 2000       | 700 Kbps       | 1.4 Gbps | 2x1 Gbps/10G   |
  +--------------+------------+----------------+----------+----------------+

  Target-Facing Network (Bastion to Targets):
  +------------------------------------------------------------------------+
  | Deployment   | Concurrent | Avg BW/Session | Total BW | Recommended    |
  +--------------+------------+----------------+----------+----------------+
  | Small        | 100        | 300 Kbps       | 30 Mbps  | 100 Mbps       |
  | Medium       | 350        | 400 Kbps       | 140 Mbps | 500 Mbps       |
  | Large        | 750        | 500 Kbps       | 375 Mbps | 1 Gbps         |
  | Enterprise   | 2000       | 600 Kbps       | 1.2 Gbps | 2x1 Gbps/10G   |
  +--------------+------------+----------------+----------+----------------+

  --------------------------------------------------------------------------

  HA REPLICATION BANDWIDTH
  ========================

  Cluster Synchronization:
  +------------------------------------------------------------------------+
  | Sync Type                | Bandwidth Required | Latency Sensitivity   |
  +--------------------------+--------------------+-----------------------+
  | PostgreSQL Streaming     | 1-10 Mbps          | < 5ms for sync mode   |
  | Configuration Sync       | 0.1-1 Mbps         | < 100ms               |
  | Session State (failover) | 5-50 Mbps          | < 10ms for seamless   |
  | Recording Replication    | 10-100 Mbps        | Async acceptable      |
  +--------------------------+--------------------+-----------------------+

  Multi-Site Replication:
  +------------------------------------------------------------------------+
  | Site Relationship        | Typical Bandwidth  | Latency Tolerance     |
  +--------------------------+--------------------+-----------------------+
  | Primary-Secondary (sync) | 10-50 Mbps         | < 20ms                |
  | Primary-DR (async)       | 5-25 Mbps          | < 200ms               |
  | Recording Archive        | Variable           | Async, scheduled OK   |
  +--------------------------+--------------------+-----------------------+

  --------------------------------------------------------------------------

  NETWORK ARCHITECTURE DIAGRAM
  ============================

                                     Internet/WAN
                                          |
                                    [ Firewall ]
                                          |
              +---------------------------+---------------------------+
              |                                                       |
         [ User LAN ]                                         [ Management ]
           1 Gbps                                                100 Mbps
              |                                                       |
    +---------+---------+                                             |
    |                   |                                             |
    v                   v                                             v
  +-------------------+-------------------+      +-------------------+
  |                   |                   |      |                   |
  |   WALLIX Node 1   |   WALLIX Node 2   |<---->|   Admin/SIEM      |
  |                   |                   |      |                   |
  +--------+----------+--------+----------+      +-------------------+
           |                   |
           |  Cluster Sync     |
           |  10 Gbps          |
           +---------+---------+
                     |
              +------+------+
              |             |
         [ Target LAN ]   [ Storage LAN ]
           1-10 Gbps        10 Gbps
              |                 |
              v                 v
         [ Servers ]       [ NAS/SAN ]

+==============================================================================+
```

---

## Hardware Sizing Guide

### CPU, RAM, and Disk Recommendations

```
+==============================================================================+
|                    HARDWARE SIZING GUIDE                                      |
+==============================================================================+

  SIZING TIERS
  ============

  TIER 1: SMALL DEPLOYMENT
  +------------------------------------------------------------------------+
  | Capacity: Up to 100 concurrent sessions, 500 users, 200 devices        |
  +------------------------------------------------------------------------+
  | Component        | Minimum          | Recommended       | Notes        |
  +------------------+------------------+-------------------+--------------+
  | CPU              | 4 cores          | 4-8 cores         | x86_64       |
  | RAM              | 16 GB            | 16-24 GB          | ECC pref.    |
  | System Disk      | 100 GB SSD       | 100 GB SSD        | OS + App     |
  | Data Disk        | 100 GB SSD       | 200 GB SSD        | Database     |
  | Recording Disk   | 250 GB           | 500 GB SSD        | 30-day ret.  |
  | Network          | 1 Gbps           | 1 Gbps            | Dual NIC     |
  | IOPS             | 1000             | 3000              | Combined     |
  +------------------+------------------+-------------------+--------------+

  TIER 2: MEDIUM DEPLOYMENT
  +------------------------------------------------------------------------+
  | Capacity: 100-500 concurrent sessions, 2000 users, 1000 devices        |
  +------------------------------------------------------------------------+
  | Component        | Minimum          | Recommended       | Notes        |
  +------------------+------------------+-------------------+--------------+
  | CPU              | 8 cores          | 8-12 cores        | x86_64       |
  | RAM              | 32 GB            | 32-48 GB          | ECC required |
  | System Disk      | 100 GB SSD       | 100 GB NVMe       | OS + App     |
  | Data Disk        | 250 GB SSD       | 500 GB NVMe       | Database     |
  | Recording Disk   | 1 TB             | 2 TB (NAS)        | 60-day ret.  |
  | Network          | 1 Gbps           | 10 Gbps           | Dual NIC     |
  | IOPS             | 3000             | 5000              | Combined     |
  +------------------+------------------+-------------------+--------------+

  TIER 3: LARGE DEPLOYMENT
  +------------------------------------------------------------------------+
  | Capacity: 500-1000 concurrent sessions, 5000 users, 3000 devices       |
  +------------------------------------------------------------------------+
  | Component        | Minimum          | Recommended       | Notes        |
  +------------------+------------------+-------------------+--------------+
  | CPU              | 16 cores         | 16-24 cores       | x86_64       |
  | RAM              | 64 GB            | 64-96 GB          | ECC required |
  | System Disk      | 100 GB NVMe      | 200 GB NVMe       | OS + App     |
  | Data Disk        | 500 GB NVMe      | 1 TB NVMe         | Database     |
  | Recording Disk   | 5 TB             | 10 TB (SAN)       | 90-day ret.  |
  | Network          | 10 Gbps          | 10 Gbps           | Bonded NICs  |
  | IOPS             | 8000             | 15000             | Combined     |
  +------------------+------------------+-------------------+--------------+

  TIER 4: ENTERPRISE DEPLOYMENT
  +------------------------------------------------------------------------+
  | Capacity: 1000+ concurrent sessions, 15000+ users, 10000+ devices      |
  +------------------------------------------------------------------------+
  | Component        | Minimum          | Recommended       | Notes        |
  +------------------+------------------+-------------------+--------------+
  | CPU              | 32 cores         | 32-64 cores       | x86_64       |
  | RAM              | 128 GB           | 128-256 GB        | ECC required |
  | System Disk      | 200 GB NVMe      | 200 GB NVMe       | OS + App     |
  | Data Disk        | 1 TB NVMe        | 2 TB NVMe RAID    | Database     |
  | Recording Disk   | 20 TB            | 50+ TB (SAN)      | 180-day ret. |
  | Network          | 10 Gbps          | 2x10 Gbps bonded  | Dedicated    |
  | IOPS             | 20000            | 40000+            | NVMe SAN     |
  +------------------+------------------+-------------------+--------------+

  --------------------------------------------------------------------------

  CPU SIZING FORMULA
  ==================

  +------------------------------------------------------------------------+
  |                                                                        |
  |  Required CPU Cores = Base + Session Load + Background                 |
  |                                                                        |
  |  Base (OS + Services):          2 cores                                |
  |  Session Load:                  Concurrent Sessions / 50               |
  |  Background (rotation, sync):   1 core per 500 managed accounts        |
  |  API Load:                      1 core per 200 req/sec                 |
  |                                                                        |
  |  Example (Large deployment):                                           |
  |    Base:       2 cores                                                 |
  |    Sessions:   750 / 50 = 15 cores                                     |
  |    Background: 4000 accounts / 500 = 8 cores (but capped at 4)         |
  |    API:        300 req/sec / 200 = 1.5 cores (round up to 2)           |
  |    Total:      2 + 15 + 4 + 2 = 23 cores (recommend 24)                |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  MEMORY SIZING FORMULA
  =====================

  +------------------------------------------------------------------------+
  |                                                                        |
  |  Required RAM = OS + PostgreSQL + Session Buffers + Cache              |
  |                                                                        |
  |  OS and Base Services:      4 GB                                       |
  |  PostgreSQL (shared_buffers): 25% of available for DB                  |
  |  Session Buffers:           Concurrent Sessions x Memory per Session   |
  |    SSH:  40 MB/session                                                 |
  |    RDP:  120 MB/session                                                |
  |    VNC:  80 MB/session                                                 |
  |  Application Cache:         10% of remaining                           |
  |                                                                        |
  |  Example (Large, 750 mixed sessions - 60/30/10):                       |
  |    OS:           4 GB                                                  |
  |    PostgreSQL:   16 GB (for 64 GB system)                              |
  |    SSH (450):    450 x 40 MB = 18 GB                                   |
  |    RDP (225):    225 x 120 MB = 27 GB                                  |
  |    VNC (75):     75 x 80 MB = 6 GB                                     |
  |    Cache:        5 GB                                                  |
  |    Total:        4 + 16 + 18 + 27 + 6 + 5 = 76 GB (recommend 96 GB)    |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  DISK SIZING AND PERFORMANCE
  ===========================

  System Disk Requirements:
  +------------------------------------------------------------------------+
  | Component            | Size         | IOPS     | Notes                 |
  +------------------------+------------+----------+-----------------------+
  | Operating System     | 20 GB        | 200      | Read-mostly           |
  | Application          | 10 GB        | 100      | Static files          |
  | Logs                 | 30 GB        | 500      | Write-intensive       |
  | Temp/Swap            | 40 GB        | 1000     | Burst writes          |
  +------------------------+------------+----------+-----------------------+
  | Total                | 100 GB       | 1800     | SSD minimum           |

  Data Disk Requirements:
  +------------------------------------------------------------------------+
  | Component            | Base Size    | Per 1000 Users | IOPS/1000 Users|
  +------------------------+------------+----------------+----------------|
  | PostgreSQL Data      | 10 GB        | 5 GB           | 500            |
  | PostgreSQL WAL       | 10 GB        | 2 GB           | 1000           |
  | Config/Policies      | 1 GB         | 0.5 GB         | 50             |
  | Encryption Keys      | 0.5 GB       | 0.1 GB         | 10             |
  +------------------------+------------+----------------+----------------|
  | Total                | 21.5 GB      | 7.6 GB         | 1560           |

  Recording Disk Requirements:
  +------------------------------------------------------------------------+
  | Retention    | 100 sess/day  | 500 sess/day  | 2000 sess/day         |
  +--------------+---------------+---------------+-----------------------+
  | 30 days      | 150 GB        | 750 GB        | 3 TB                  |
  | 60 days      | 300 GB        | 1.5 TB        | 6 TB                  |
  | 90 days      | 450 GB        | 2.25 TB       | 9 TB                  |
  | 180 days     | 900 GB        | 4.5 TB        | 18 TB                 |
  | 365 days     | 1.8 TB        | 9 TB          | 36 TB                 |
  +--------------+---------------+---------------+-----------------------+

+==============================================================================+
```

---

## Scaling Recommendations

### Vertical vs Horizontal Scaling

```
+==============================================================================+
|                    SCALING RECOMMENDATIONS                                    |
+==============================================================================+

  SCALING STRATEGY DECISION TREE
  ==============================

                    +---------------------------+
                    | Current Capacity Reached? |
                    +-------------+-------------+
                                  |
                    +-------------v-------------+
                    | Identify Bottleneck       |
                    +-------------+-------------+
                                  |
            +---------------------+---------------------+
            |                     |                     |
            v                     v                     v
    +-------+-------+     +-------+-------+     +-------+-------+
    | CPU Bound     |     | Memory Bound  |     | Storage/IO    |
    | (>85% usage)  |     | (>90% usage)  |     | (>80% util)   |
    +-------+-------+     +-------+-------+     +-------+-------+
            |                     |                     |
            v                     v                     v
    Scale Vertically      Scale Vertically      Upgrade Storage
    (Add CPU cores)       (Add RAM)             or Add Nodes
            |                     |                     |
            +----------+----------+----------+----------+
                       |                     |
         +-------------v-----------+    +----v----+
         | Still insufficient?      |    | Done    |
         +-------------+-----------+    +---------+
                       |
         +-------------v-----------+
         | Scale Horizontally      |
         | (Add cluster nodes)     |
         +-------------------------+

  --------------------------------------------------------------------------

  VERTICAL SCALING (SCALE UP)
  ===========================

  When to Scale Vertically:
  +------------------------------------------------------------------------+
  | Condition                              | Action                        |
  +----------------------------------------+-------------------------------+
  | CPU consistently > 75%                 | Add 50-100% more cores        |
  | Memory consistently > 80%              | Add 50-100% more RAM          |
  | DB queries slowing                     | Add RAM for cache             |
  | Single node < 1000 sessions            | Add resources first           |
  | Simple architecture preferred          | Maximize single node          |
  +----------------------------------------+-------------------------------+

  Vertical Scaling Limits:
  +------------------------------------------------------------------------+
  | Resource      | Practical Limit  | Diminishing Returns After          |
  +---------------+------------------+------------------------------------+
  | CPU Cores     | 64 cores         | 32 cores (context switching)       |
  | RAM           | 512 GB           | 256 GB (diminishing cache benefit) |
  | Single Node   | 2500 sessions    | 1500 sessions (recommended max)    |
  +---------------+------------------+------------------------------------+

  Upgrade Path:
  +------------------------------------------------------------------------+
  | From              | To                  | Capacity Gain                |
  +-------------------+---------------------+------------------------------+
  | 4C/16GB           | 8C/32GB             | +100% (2x sessions)          |
  | 8C/32GB           | 16C/64GB            | +80% (1.8x sessions)         |
  | 16C/64GB          | 32C/128GB           | +70% (1.7x sessions)         |
  | 32C/128GB         | 64C/256GB           | +50% (1.5x sessions)         |
  +-------------------+---------------------+------------------------------+

  --------------------------------------------------------------------------

  HORIZONTAL SCALING (SCALE OUT)
  ==============================

  When to Scale Horizontally:
  +------------------------------------------------------------------------+
  | Condition                              | Action                        |
  +----------------------------------------+-------------------------------+
  | Single node at practical limit         | Add cluster nodes             |
  | HA/DR requirements                     | Add nodes in different zones  |
  | Geographic distribution needed         | Multi-site deployment         |
  | > 1500 concurrent sessions             | Active-Active cluster         |
  | > 3000 concurrent sessions             | Multi-cluster architecture    |
  +----------------------------------------+-------------------------------+

  Horizontal Scaling Patterns:
  +------------------------------------------------------------------------+
  |                                                                        |
  |  PATTERN 1: ACTIVE-PASSIVE (HA)                                        |
  |  ==============================                                        |
  |                                                                        |
  |    Capacity: 1x single node (with failover)                            |
  |    Use case: High availability, not capacity                           |
  |                                                                        |
  |         +---------------+  +---------------+                           |
  |         |   Primary     |  |   Standby     |                           |
  |         |   (Active)    |  |   (Passive)   |                           |
  |         +---------------+  +---------------+                           |
  |                                                                        |
  |  PATTERN 2: ACTIVE-ACTIVE (CAPACITY)                                   |
  |  ===================================                                   |
  |                                                                        |
  |    Capacity: N x 80% single node (N = number of nodes)                 |
  |    Use case: Capacity and availability                                 |
  |                                                                        |
  |              +-------------------+                                     |
  |              |   Load Balancer   |                                     |
  |              +---------+---------+                                     |
  |                        |                                               |
  |         +--------------+--------------+                                |
  |         |              |              |                                |
  |    +----v----+    +----v----+    +----v----+                           |
  |    | Node 1  |    | Node 2  |    | Node 3  |                           |
  |    | Active  |    | Active  |    | Active  |                           |
  |    +---------+    +---------+    +---------+                           |
  |                                                                        |
  |  PATTERN 3: MULTI-SITE                                                 |
  |  =====================                                                 |
  |                                                                        |
  |    Capacity: Regional capacity with global failover                    |
  |    Use case: Geographic distribution, DR                               |
  |                                                                        |
  +------------------------------------------------------------------------+

  Cluster Sizing Guidelines:
  +------------------------------------------------------------------------+
  | Target Sessions | Nodes | Config per Node | Total Capacity             |
  +-----------------+-------+-----------------+----------------------------+
  | 500             | 2     | 8C/32GB         | 700 (with failover)        |
  | 1000            | 2     | 16C/64GB        | 1400 (with failover)       |
  | 2000            | 3     | 16C/64GB        | 2100 (N-1 resilience)      |
  | 3000            | 4     | 16C/64GB        | 2800 (N-1 resilience)      |
  | 5000            | 3     | 32C/128GB       | 4500 (N-1 resilience)      |
  +-----------------+-------+-----------------+----------------------------+

  --------------------------------------------------------------------------

  SCALING DECISION MATRIX
  =======================

  +------------------------------------------------------------------------+
  | Sessions  | Recommended Architecture       | Nodes | Per-Node Spec     |
  +-----------+--------------------------------+-------+-------------------+
  | < 100     | Single Node                    | 1     | 4C/16GB           |
  | 100-300   | Single Node                    | 1     | 8C/32GB           |
  | 300-700   | Single Node or HA Pair         | 1-2   | 16C/64GB          |
  | 700-1500  | HA Pair (Active-Passive)       | 2     | 16C/64GB          |
  | 1500-3000 | Active-Active Cluster          | 3-4   | 16C/64GB          |
  | 3000-5000 | Active-Active Cluster          | 4-6   | 32C/128GB         |
  | > 5000    | Multi-Cluster / Multi-Site     | 6+    | 32C/128GB         |
  +-----------+--------------------------------+-------+-------------------+

+==============================================================================+
```

---

## Performance Tuning

### PostgreSQL, Kernel, and Application Tuning

```
+==============================================================================+
|                    PERFORMANCE TUNING                                         |
+==============================================================================+

  POSTGRESQL OPTIMIZATION
  =======================

  Memory Configuration (/etc/postgresql/16/main/postgresql.conf):
  +------------------------------------------------------------------------+
  | # Memory Settings - Adjust based on total system RAM                   |
  |                                                                        |
  | # 25% of total RAM for database operations                             |
  | shared_buffers = 16GB                    # For 64GB system             |
  |                                                                        |
  | # 75% of total RAM for query planning estimates                        |
  | effective_cache_size = 48GB              # For 64GB system             |
  |                                                                        |
  | # Memory per sort/hash operation                                       |
  | work_mem = 256MB                         # Adjust for complex queries  |
  |                                                                        |
  | # Memory for maintenance (VACUUM, CREATE INDEX)                        |
  | maintenance_work_mem = 2GB               # 2-4GB for large DBs         |
  |                                                                        |
  | # Maximum memory for parallel query workers                            |
  | max_parallel_workers_per_gather = 4                                    |
  | max_parallel_workers = 8                                               |
  +------------------------------------------------------------------------+

  Connection and Performance Settings:
  +------------------------------------------------------------------------+
  | # Connection Management                                                |
  | max_connections = 500                    # Based on session count      |
  | superuser_reserved_connections = 5                                     |
  |                                                                        |
  | # Write-Ahead Log (WAL) Performance                                    |
  | wal_buffers = 64MB                       # 1/32 of shared_buffers      |
  | checkpoint_completion_target = 0.9       # Spread checkpoint I/O       |
  | checkpoint_timeout = 10min               # Reduce checkpoint frequency |
  | max_wal_size = 4GB                       # Allow larger WAL before CP  |
  | min_wal_size = 1GB                                                     |
  |                                                                        |
  | # Durability (adjust for performance vs safety trade-off)              |
  | synchronous_commit = on                  # Keep 'on' for production    |
  | wal_compression = on                     # Reduce WAL I/O              |
  |                                                                        |
  | # Query Planner (SSD optimized)                                        |
  | random_page_cost = 1.1                   # Default 4.0, use 1.1 for SSD|
  | effective_io_concurrency = 200           # Default 1, use 200 for SSD  |
  | default_statistics_target = 200          # Better query plans          |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  LINUX KERNEL TUNING
  ===================

  Network Settings (/etc/sysctl.conf):
  +------------------------------------------------------------------------+
  | # TCP Connection Handling                                              |
  | net.core.somaxconn = 65535                                             |
  | net.core.netdev_max_backlog = 65535                                    |
  | net.ipv4.tcp_max_syn_backlog = 65535                                   |
  | net.ipv4.ip_local_port_range = 1024 65535                              |
  |                                                                        |
  | # TCP Performance                                                      |
  | net.ipv4.tcp_tw_reuse = 1                                              |
  | net.ipv4.tcp_fin_timeout = 15                                          |
  | net.ipv4.tcp_slow_start_after_idle = 0                                 |
  | net.ipv4.tcp_mtu_probing = 1                                           |
  |                                                                        |
  | # TCP Keepalive (detect dead connections faster)                       |
  | net.ipv4.tcp_keepalive_time = 300                                      |
  | net.ipv4.tcp_keepalive_probes = 5                                      |
  | net.ipv4.tcp_keepalive_intvl = 15                                      |
  |                                                                        |
  | # Buffer Sizes                                                         |
  | net.core.rmem_max = 16777216                                           |
  | net.core.wmem_max = 16777216                                           |
  | net.ipv4.tcp_rmem = 4096 87380 16777216                                |
  | net.ipv4.tcp_wmem = 4096 65536 16777216                                |
  +------------------------------------------------------------------------+

  Memory Settings:
  +------------------------------------------------------------------------+
  | # Virtual Memory                                                       |
  | vm.swappiness = 10                       # Minimize swap usage         |
  | vm.dirty_ratio = 40                      # % of RAM for dirty pages    |
  | vm.dirty_background_ratio = 10           # Start flushing at 10%       |
  | vm.dirty_expire_centisecs = 3000         # Flush after 30 seconds      |
  | vm.vfs_cache_pressure = 50               # Balance inode/dentry cache  |
  |                                                                        |
  | # Huge Pages (for PostgreSQL large shared_buffers)                     |
  | vm.nr_hugepages = 8192                   # 16GB of huge pages          |
  +------------------------------------------------------------------------+

  File Descriptor Limits (/etc/security/limits.conf):
  +------------------------------------------------------------------------+
  | # WALLIX Service User                                                  |
  | wab soft nofile 131072                                                 |
  | wab hard nofile 131072                                                 |
  | wab soft nproc 65535                                                   |
  | wab hard nproc 65535                                                   |
  | wab soft memlock unlimited                                             |
  | wab hard memlock unlimited                                             |
  |                                                                        |
  | # PostgreSQL User                                                      |
  | postgres soft nofile 131072                                            |
  | postgres hard nofile 131072                                            |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  SESSION MANAGER TUNING
  ======================

  /etc/opt/wab/wabengine/wabengine.conf:
  +------------------------------------------------------------------------+
  | [performance]                                                          |
  | # Session Pool Configuration                                           |
  | max_concurrent_sessions = 2000           # Match hardware capacity     |
  | session_pool_size = 200                  # Pre-allocated session slots |
  | session_idle_timeout = 1800              # 30 min idle timeout         |
  | session_max_duration = 28800             # 8 hour max session          |
  |                                                                        |
  | # Recording Optimization                                               |
  | recording_buffer_size = 16MB             # Larger buffers, fewer writes|
  | recording_compression = true                                           |
  | recording_compression_level = 4          # Balance CPU vs compression  |
  | recording_flush_interval = 30            # Seconds between flushes     |
  |                                                                        |
  | # Database Connection Pool                                             |
  | db_pool_size = 100                       # Persistent connections      |
  | db_pool_max_overflow = 50                # Temporary additional conns  |
  | db_pool_timeout = 30                     # Seconds to wait for conn    |
  | db_pool_recycle = 3600                   # Recycle connections hourly  |
  |                                                                        |
  | # Authentication Caching                                               |
  | auth_cache_enabled = true                                              |
  | auth_cache_ttl = 300                     # 5 minute cache              |
  | auth_cache_size = 10000                  # Max cached entries          |
  |                                                                        |
  | # Policy Caching                                                       |
  | policy_cache_enabled = true                                            |
  | policy_cache_ttl = 60                    # 1 minute cache              |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  RECORDING STORAGE TUNING
  ========================

  NFS Mount Options (for recording storage):
  +------------------------------------------------------------------------+
  | # /etc/fstab entry for recording NAS                                   |
  | nas.company.com:/wallix/recordings /var/wab/recorded nfs4 \            |
  |     rw,hard,intr,noatime,nodiratime,rsize=1048576,wsize=1048576, \     |
  |     nconnect=8,proto=tcp,sec=sys 0 0                                   |
  |                                                                        |
  | Key Options Explained:                                                 |
  |   rsize/wsize=1048576  - 1MB read/write blocks (max throughput)        |
  |   nconnect=8           - Multiple TCP connections (NFSv4.1+)           |
  |   noatime,nodiratime   - Don't update access times (reduces I/O)       |
  |   hard                 - Retry indefinitely on NAS failure             |
  |   intr                 - Allow interrupt of hung operations            |
  +------------------------------------------------------------------------+

  I/O Scheduler (for local SSD):
  +------------------------------------------------------------------------+
  | # For NVMe devices, use 'none' scheduler                               |
  | echo none > /sys/block/nvme0n1/queue/scheduler                         |
  |                                                                        |
  | # For SATA SSD, use 'mq-deadline'                                      |
  | echo mq-deadline > /sys/block/sda/queue/scheduler                      |
  |                                                                        |
  | # Increase read-ahead for sequential recording writes                  |
  | blockdev --setra 4096 /dev/nvme0n1                                     |
  +------------------------------------------------------------------------+

+==============================================================================+
```

---

## Monitoring Metrics

### Key Metrics, Thresholds, and Alerting

```
+==============================================================================+
|                    MONITORING METRICS                                         |
+==============================================================================+

  CRITICAL SYSTEM METRICS
  =======================

  +------------------------------------------------------------------------+
  | Metric                 | Warning       | Critical      | Action        |
  +------------------------+---------------+---------------+---------------+
  | CPU Usage              | > 75%         | > 90%         | Scale/tune    |
  | CPU I/O Wait           | > 15%         | > 30%         | Check storage |
  | Memory Usage           | > 80%         | > 95%         | Scale/tune    |
  | Swap Usage             | > 10%         | > 25%         | Add RAM       |
  | Disk Usage             | > 75%         | > 90%         | Expand/purge  |
  | Disk I/O Latency       | > 10ms        | > 50ms        | Upgrade disk  |
  | Network Utilization    | > 70%         | > 90%         | Add bandwidth |
  | Load Average (1m)      | > cores       | > 2x cores    | Investigate   |
  +------------------------+---------------+---------------+---------------+

  APPLICATION METRICS
  ===================

  +------------------------------------------------------------------------+
  | Metric                     | Warning      | Critical     | Impact      |
  +----------------------------+--------------+--------------+-------------+
  | Active Sessions            | > 80% cap    | > 95% cap    | Capacity    |
  | Session Queue Depth        | > 50         | > 200        | User delay  |
  | Session Establishment Time | > 3 sec      | > 8 sec      | User exp.   |
  | Failed Sessions/min        | > 5          | > 20         | Availability|
  | Auth Failures/min          | > 10         | > 50         | Security    |
  | Recording Queue            | > 1000       | > 5000       | Data loss   |
  | API Response Time (p95)    | > 500ms      | > 2 sec      | Integration |
  | API Error Rate             | > 1%         | > 5%         | Integration |
  +----------------------------+--------------+--------------+-------------+

  DATABASE METRICS
  ================

  +------------------------------------------------------------------------+
  | Metric                     | Warning      | Critical     | Query       |
  +----------------------------+--------------+--------------+-------------+
  | Active Connections         | > 80% max    | > 95% max    | Check pools |
  | Connection Wait Time       | > 100ms      | > 500ms      | Add conns   |
  | Query Time (p95)           | > 100ms      | > 500ms      | Optimize    |
  | Cache Hit Ratio            | < 95%        | < 90%        | Add RAM     |
  | Replication Lag (seconds)  | > 5          | > 30         | Network/IO  |
  | Dead Tuples (%)            | > 10%        | > 25%        | Run VACUUM  |
  | Table Bloat (%)            | > 20%        | > 40%        | Maintenance |
  +----------------------------+--------------+--------------+-------------+

  --------------------------------------------------------------------------

  MONITORING QUERIES
  ==================

  System Resource Monitoring:
  +------------------------------------------------------------------------+
  | # Real-time resource usage                                             |
  | vmstat 5                                                               |
  | iostat -xz 5                                                           |
  | sar -n DEV 5                                                           |
  |                                                                        |
  | # Process-specific monitoring                                          |
  | pidstat -p $(pgrep -d, -f wallix) 5                                    |
  | ps aux --sort=-%mem | head -20                                         |
  +------------------------------------------------------------------------+

  PostgreSQL Monitoring:
  +------------------------------------------------------------------------+
  | -- Active connection count                                             |
  | SELECT count(*) FROM pg_stat_activity WHERE state != 'idle';           |
  |                                                                        |
  | -- Connection breakdown                                                |
  | SELECT state, count(*) FROM pg_stat_activity GROUP BY state;           |
  |                                                                        |
  | -- Long-running queries                                                |
  | SELECT pid, now() - pg_stat_activity.query_start AS duration, query    |
  | FROM pg_stat_activity                                                  |
  | WHERE state != 'idle' AND now() - pg_stat_activity.query_start > '30s';|
  |                                                                        |
  | -- Cache hit ratio                                                     |
  | SELECT round(100.0 * sum(heap_blks_hit) /                              |
  |   nullif(sum(heap_blks_hit) + sum(heap_blks_read), 0), 2)              |
  |   AS cache_hit_ratio FROM pg_statio_user_tables;                       |
  |                                                                        |
  | -- Replication status                                                  |
  | SELECT client_addr, state, sent_lsn, replay_lsn,                       |
  |   pg_wal_lsn_diff(sent_lsn, replay_lsn) AS lag_bytes                   |
  | FROM pg_stat_replication;                                              |
  |                                                                        |
  | -- Table bloat estimate                                                |
  | SELECT schemaname, tablename,                                          |
  |   pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)),  |
  |   n_dead_tup, n_live_tup,                                              |
  |   round(100.0 * n_dead_tup / nullif(n_live_tup, 0), 2) AS dead_pct     |
  | FROM pg_stat_user_tables ORDER BY n_dead_tup DESC LIMIT 10;            |
  +------------------------------------------------------------------------+

  WALLIX Application Monitoring:
  +------------------------------------------------------------------------+
  | # Active session count                                                 |
  | wabadmin sessions --active --count                                     |
  |                                                                        |
  | # Service status                                                       |
  | systemctl status wab* --no-pager                                       |
  |                                                                        |
  | # Recent authentication failures                                       |
  | wabadmin audit --type=auth --status=failed --last=100                  |
  |                                                                        |
  | # Recording queue status                                               |
  | wabadmin recording-queue --status                                      |
  |                                                                        |
  | # Cluster health                                                       |
  | wabadmin cluster-status                                                |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  ALERTING CONFIGURATION
  ======================

  Prometheus Alert Rules Example:
  +------------------------------------------------------------------------+
  | groups:                                                                |
  |   - name: wallix_alerts                                                |
  |     rules:                                                             |
  |       - alert: HighCPUUsage                                            |
  |         expr: 100 - (avg(irate(node_cpu_seconds_total{mode="idle"}     |
  |               [5m])) * 100) > 85                                       |
  |         for: 5m                                                        |
  |         labels:                                                        |
  |           severity: warning                                            |
  |                                                                        |
  |       - alert: HighMemoryUsage                                         |
  |         expr: (1 - (node_memory_MemAvailable_bytes /                   |
  |               node_memory_MemTotal_bytes)) * 100 > 90                  |
  |         for: 5m                                                        |
  |         labels:                                                        |
  |           severity: critical                                           |
  |                                                                        |
  |       - alert: SessionCapacityHigh                                     |
  |         expr: wallix_active_sessions / wallix_max_sessions > 0.85      |
  |         for: 10m                                                       |
  |         labels:                                                        |
  |           severity: warning                                            |
  |                                                                        |
  |       - alert: DatabaseReplicationLag                                  |
  |         expr: pg_replication_lag_seconds > 30                          |
  |         for: 5m                                                        |
  |         labels:                                                        |
  |           severity: critical                                           |
  +------------------------------------------------------------------------+

  SIEM Integration (Syslog Format):
  +------------------------------------------------------------------------+
  | # /etc/rsyslog.d/wallix.conf                                           |
  |                                                                        |
  | # Forward WALLIX logs to SIEM                                          |
  | if $programname startswith 'wallix' then @@siem.company.com:6514       |
  |                                                                        |
  | # Alert on high session establishment times                            |
  | if $msg contains 'session_establishment_time' and                      |
  |    $msg contains 'duration_ms' then {                                  |
  |    action(type="omfwd" target="siem.company.com" port="6514"           |
  |           protocol="tcp")                                              |
  | }                                                                       |
  +------------------------------------------------------------------------+

+==============================================================================+
```

---

## Capacity Planning Calculator

### Formulas and Interactive Calculator

```
+==============================================================================+
|                    CAPACITY PLANNING CALCULATOR                               |
+==============================================================================+

  MASTER SIZING FORMULA
  =====================

  +------------------------------------------------------------------------+
  |                                                                        |
  |  STEP 1: GATHER REQUIREMENTS                                           |
  |  ===========================                                           |
  |                                                                        |
  |  Input Variables:                                                      |
  |    U  = Total users                                                    |
  |    D  = Total devices/targets                                          |
  |    P  = Peak concurrent sessions                                       |
  |    S  = Average sessions per day                                       |
  |    T  = Average session duration (hours)                               |
  |    R  = Retention period (days)                                        |
  |    G  = Annual growth rate (decimal, e.g., 0.20 for 20%)               |
  |                                                                        |
  |  Session Mix (should total 100%):                                      |
  |    SSH_pct = Percentage SSH sessions                                   |
  |    RDP_pct = Percentage RDP sessions                                   |
  |    VNC_pct = Percentage VNC sessions                                   |
  |                                                                        |
  +------------------------------------------------------------------------+

  +------------------------------------------------------------------------+
  |                                                                        |
  |  STEP 2: CALCULATE HARDWARE REQUIREMENTS                               |
  |  =======================================                               |
  |                                                                        |
  |  CPU Cores:                                                            |
  |    Base = 2                                                            |
  |    Session_CPU = P * (SSH_pct*0.02 + RDP_pct*0.06 + VNC_pct*0.04)      |
  |    Background_CPU = MIN(4, CEIL(D / 500))                              |
  |    CPU_Required = CEIL((Base + Session_CPU + Background_CPU) * 1.25)   |
  |                                                                        |
  |  Memory (GB):                                                          |
  |    Base = 4                                                            |
  |    DB_Memory = 0.25 * Total_RAM  (set iteratively)                     |
  |    Session_Memory = P * (SSH_pct*0.04 + RDP_pct*0.12 + VNC_pct*0.08)   |
  |    Cache = 0.10 * Total_RAM                                            |
  |    RAM_Required = CEIL((Base + Session_Memory) / 0.65)  # 65% for app  |
  |                                                                        |
  |  Storage (GB):                                                         |
  |    System_Disk = 100                                                   |
  |    Data_Disk = 20 + (U * 0.005) + (D * 0.008) + (S * 30 * 0.01)        |
  |    Recording_Disk = S * T * (SSH_pct*0.015 + RDP_pct*0.12 +            |
  |                              VNC_pct*0.075) * R * 1.2                  |
  |                                                                        |
  +------------------------------------------------------------------------+

  +------------------------------------------------------------------------+
  |                                                                        |
  |  STEP 3: APPLY GROWTH PROJECTION                                       |
  |  ================================                                      |
  |                                                                        |
  |  For 3-year planning:                                                  |
  |    Growth_Factor = (1 + G) ^ 3                                         |
  |                                                                        |
  |    Future_Sessions = P * Growth_Factor                                 |
  |    Future_Users = U * Growth_Factor                                    |
  |    Future_Devices = D * Growth_Factor                                  |
  |                                                                        |
  |  Recalculate hardware with future values                               |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  EXAMPLE CALCULATION
  ===================

  +------------------------------------------------------------------------+
  |                                                                        |
  |  SCENARIO: Medium Enterprise                                           |
  |  ---------------------------                                           |
  |                                                                        |
  |  Inputs:                                                               |
  |    U = 2000 users                                                      |
  |    D = 1000 devices                                                    |
  |    P = 400 concurrent sessions (peak)                                  |
  |    S = 600 sessions/day                                                |
  |    T = 2.5 hours average duration                                      |
  |    R = 90 days retention                                               |
  |    G = 0.15 (15% annual growth)                                        |
  |                                                                        |
  |    SSH_pct = 0.60 (60%)                                                |
  |    RDP_pct = 0.30 (30%)                                                |
  |    VNC_pct = 0.10 (10%)                                                |
  |                                                                        |
  |  Calculations:                                                         |
  |                                                                        |
  |  CPU:                                                                  |
  |    Base = 2                                                            |
  |    Session_CPU = 400 * (0.60*0.02 + 0.30*0.06 + 0.10*0.04)             |
  |                = 400 * (0.012 + 0.018 + 0.004) = 400 * 0.034 = 13.6    |
  |    Background_CPU = MIN(4, CEIL(1000/500)) = MIN(4, 2) = 2             |
  |    CPU_Required = CEIL((2 + 13.6 + 2) * 1.25) = CEIL(22) = 22 cores    |
  |                                                                        |
  |  Memory:                                                               |
  |    Session_Memory = 400 * (0.60*0.04 + 0.30*0.12 + 0.10*0.08)          |
  |                   = 400 * (0.024 + 0.036 + 0.008) = 400 * 0.068 = 27.2 |
  |    RAM_Required = CEIL((4 + 27.2) / 0.65) = CEIL(48) = 48 GB           |
  |    --> Recommend: 64 GB (next standard size)                           |
  |                                                                        |
  |  Storage:                                                              |
  |    System_Disk = 100 GB                                                |
  |    Data_Disk = 20 + (2000*0.005) + (1000*0.008) + (600*30*0.01)        |
  |              = 20 + 10 + 8 + 180 = 218 GB --> 250 GB (rounded)         |
  |    Recording_Disk = 600 * 2.5 * (0.60*0.015 + 0.30*0.12 + 0.10*0.075)  |
  |                         * 90 * 1.2                                     |
  |                   = 1500 * (0.009 + 0.036 + 0.0075) * 108               |
  |                   = 1500 * 0.0525 * 108 = 8505 GB --> 9 TB             |
  |                                                                        |
  |  3-Year Projection (15% annual growth):                                |
  |    Growth_Factor = 1.15^3 = 1.52                                       |
  |    Future_Sessions = 400 * 1.52 = 608 concurrent                       |
  |    --> Recalculate for 608 sessions: ~32 cores, 96 GB RAM, 14 TB rec.  |
  |                                                                        |
  |  RECOMMENDATION:                                                       |
  |    Current: 24 cores, 64 GB RAM, 250 GB data, 10 TB recording          |
  |    3-Year:  32 cores, 128 GB RAM, 500 GB data, 20 TB recording         |
  |                                                                        |
  +------------------------------------------------------------------------+

  --------------------------------------------------------------------------

  QUICK REFERENCE TABLES
  ======================

  Concurrent Sessions to Hardware (Mixed Workload):
  +------------------------------------------------------------------------+
  | Sessions | CPU Cores | RAM (GB) | Data Disk | Recording (90-day)       |
  +----------+-----------+----------+-----------+--------------------------+
  | 50       | 4         | 16       | 50 GB     | 500 GB                   |
  | 100      | 6         | 24       | 75 GB     | 1 TB                     |
  | 200      | 10        | 32       | 100 GB    | 2 TB                     |
  | 400      | 18        | 64       | 200 GB    | 4 TB                     |
  | 600      | 24        | 96       | 300 GB    | 6 TB                     |
  | 800      | 32        | 128      | 400 GB    | 8 TB                     |
  | 1000     | 40        | 160      | 500 GB    | 10 TB                    |
  | 1500     | 56        | 256      | 750 GB    | 15 TB                    |
  | 2000     | 72        | 320      | 1 TB      | 20 TB                    |
  +----------+-----------+----------+-----------+--------------------------+

  Sessions per Day to Monthly Storage (Mixed Workload):
  +------------------------------------------------------------------------+
  | Sessions/Day | Avg Duration | Monthly Raw | With Index | With 90-day  |
  +--------------+--------------+-------------+------------+--------------+
  | 100          | 2.0 hrs      | 150 GB      | 180 GB     | 540 GB       |
  | 250          | 2.5 hrs      | 450 GB      | 540 GB     | 1.6 TB       |
  | 500          | 2.5 hrs      | 900 GB      | 1.1 TB     | 3.3 TB       |
  | 1000         | 3.0 hrs      | 2.1 TB      | 2.5 TB     | 7.5 TB       |
  | 2000         | 3.0 hrs      | 4.2 TB      | 5.0 TB     | 15 TB        |
  | 5000         | 3.5 hrs      | 12 TB       | 14.4 TB    | 43 TB        |
  +--------------+--------------+-------------+------------+--------------+

  --------------------------------------------------------------------------

  CAPACITY PLANNING WORKSHEET
  ===========================

  +------------------------------------------------------------------------+
  |  Organization: _____________________    Date: _______________          |
  |                                                                        |
  |  CURRENT STATE                                                         |
  |  +----------------------------------------------------------------+   |
  |  | Metric                    | Value            | Growth Rate (%) |   |
  |  +---------------------------+------------------+-----------------+   |
  |  | Total Users               | ____________     | ____________    |   |
  |  | Total Devices             | ____________     | ____________    |   |
  |  | Peak Concurrent Sessions  | ____________     | ____________    |   |
  |  | Average Sessions/Day      | ____________     | ____________    |   |
  |  | Average Session Duration  | ____________ hrs | N/A             |   |
  |  | SSH Session %             | ____________ %   | N/A             |   |
  |  | RDP Session %             | ____________ %   | N/A             |   |
  |  | VNC Session %             | ____________ %   | N/A             |   |
  |  +---------------------------+------------------+-----------------+   |
  |                                                                        |
  |  REQUIREMENTS                                                          |
  |  +----------------------------------------------------------------+   |
  |  | Retention Period (days)   | ____________                       |   |
  |  | Target Availability       | ____________ % (99.9%, 99.99%)     |   |
  |  | Planning Horizon          | ____________ years                 |   |
  |  | Geographic Distribution   | [ ] Single Site  [ ] Multi-Site   |   |
  |  +----------------------------------------------------------------+   |
  |                                                                        |
  |  CALCULATED REQUIREMENTS                                               |
  |  +----------------------------------------------------------------+   |
  |  | Resource              | Current Need   | Year 1  | Year 3       |   |
  |  +-----------------------+----------------+---------+--------------+   |
  |  | CPU Cores             | ____________   | _______ | ____________ |   |
  |  | RAM (GB)              | ____________   | _______ | ____________ |   |
  |  | Data Storage (GB)     | ____________   | _______ | ____________ |   |
  |  | Recording Storage (TB)| ____________   | _______ | ____________ |   |
  |  | Network (Gbps)        | ____________   | _______ | ____________ |   |
  |  | Cluster Nodes         | ____________   | _______ | ____________ |   |
  |  +-----------------------+----------------+---------+--------------+   |
  |                                                                        |
  |  RECOMMENDED CONFIGURATION                                             |
  |  +----------------------------------------------------------------+   |
  |  | [ ] Tier 1 (Small)     4-8C, 16-24GB, 1TB                      |   |
  |  | [ ] Tier 2 (Medium)    8-16C, 32-64GB, 5TB                     |   |
  |  | [ ] Tier 3 (Large)     16-32C, 64-128GB, 15TB                  |   |
  |  | [ ] Tier 4 (Enterprise) 32-64C, 128-256GB, 50TB+               |   |
  |  |                                                                |   |
  |  | [ ] Single Node                                                |   |
  |  | [ ] HA Pair (Active-Passive)                                   |   |
  |  | [ ] HA Cluster (Active-Active, ___ nodes)                      |   |
  |  | [ ] Multi-Site (___ sites)                                     |   |
  |  +----------------------------------------------------------------+   |
  |                                                                        |
  +------------------------------------------------------------------------+

+==============================================================================+
```

---

## Summary and Quick Reference

### Performance Quick Reference Card

```
+==============================================================================+
|                    PERFORMANCE QUICK REFERENCE                                |
+==============================================================================+

  HARDWARE SIZING CHEAT SHEET
  ===========================

  +------------------------------------------------------------------------+
  | Concurrent    | CPU    | RAM    | Data   | Recording | Network         |
  | Sessions      | Cores  | (GB)   | (GB)   | (90-day)  | (Gbps)          |
  +---------------+--------+--------+--------+-----------+-----------------+
  | 100           | 4-8    | 16-24  | 75     | 1 TB      | 1               |
  | 250           | 8-12   | 32     | 150    | 2.5 TB    | 1               |
  | 500           | 16-20  | 64     | 300    | 5 TB      | 1-10            |
  | 1000          | 32-40  | 128    | 600    | 10 TB     | 10              |
  | 2000          | 64-80  | 256    | 1000   | 20 TB     | 2x10            |
  +---------------+--------+--------+--------+-----------+-----------------+

  KEY PERFORMANCE THRESHOLDS
  ==========================

  +------------------------------------------------------------------------+
  | Metric                      | Target    | Warning   | Critical         |
  +-----------------------------+-----------+-----------+------------------+
  | SSH Connection Time         | < 1 sec   | > 2 sec   | > 5 sec          |
  | RDP Connection Time         | < 3 sec   | > 5 sec   | > 10 sec         |
  | CPU Utilization             | < 70%     | > 80%     | > 90%            |
  | Memory Utilization          | < 75%     | > 85%     | > 95%            |
  | Session Capacity Usage      | < 70%     | > 85%     | > 95%            |
  | DB Replication Lag          | < 1 sec   | > 5 sec   | > 30 sec         |
  | API Response Time (p95)     | < 200ms   | > 500ms   | > 2 sec          |
  +-----------------------------+-----------+-----------+------------------+

  STORAGE RATES (PER SESSION HOUR)
  =================================

  +------------------------------------------------------------------------+
  | Protocol        | Low Activity | Typical    | High Activity            |
  +-----------------+--------------+------------+--------------------------+
  | SSH             | 5 MB         | 15 MB      | 50 MB                    |
  | RDP (Standard)  | 80 MB        | 120 MB     | 250 MB                   |
  | RDP (HD)        | 200 MB       | 400 MB     | 800 MB                   |
  | VNC             | 50 MB        | 80 MB      | 150 MB                   |
  +-----------------+--------------+------------+--------------------------+

  SCALING DECISION QUICK GUIDE
  ============================

  CPU > 80%          --> Add cores or nodes
  Memory > 85%       --> Add RAM or nodes
  Disk I/O > 80%     --> Upgrade storage or add nodes
  Sessions > 85% cap --> Add nodes (horizontal scaling)
  Latency > 2x norm  --> Check bottleneck, scale accordingly

  TUNING PRIORITY ORDER
  =====================

  1. PostgreSQL memory (shared_buffers, effective_cache_size)
  2. Linux file descriptors and network buffers
  3. Session manager connection pools
  4. Recording storage optimization
  5. Caching (auth, policy)

+==============================================================================+
```

---

## Additional Resources

### Related Documentation

- [28 - System Requirements](../19-system-requirements/README.md) - Hardware and software prerequisites
- [10 - High Availability](../11-high-availability/README.md) - Clustering and failover configuration
- [30 - Operational Runbooks](../21-operational-runbooks/README.md) - Daily operations and maintenance
- [12 - Troubleshooting](../13-troubleshooting/README.md) - Diagnosing performance issues

### External References

- [WALLIX Documentation Portal](https://pam.wallix.one/documentation) - Official documentation
- [WALLIX Administration Guide](https://pam.wallix.one/documentation/admin-doc/bastion_en_administration_guide.pdf) - Administration procedures
- [PostgreSQL Performance Tuning](https://wiki.postgresql.org/wiki/Performance_Optimization) - Database optimization
- [Linux Performance Tuning](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/monitoring_and_managing_system_status_and_performance/index) - OS-level tuning

---

## Next Steps

Continue to [36 - Integration Patterns](../36-integration-patterns/README.md) for integration with external systems.
