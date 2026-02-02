# OT Fundamentals for IT Professionals

Understanding Operational Technology from the ground up.

## What is Operational Technology?

Operational Technology (OT) refers to hardware and software that detects or causes changes through direct monitoring and control of physical devices, processes, and events.

```
┌──────────────────────────────────────────────────────────────────────┐
│                    OT vs IT Definition                               │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Information Technology (IT)                                        │
│   ─────────────────────────────                                      │
│   Manages DATA - stores, processes, transmits information            │
│   Examples: Email servers, databases, web applications               │
│                                                                      │
│   Operational Technology (OT)                                        │
│   ─────────────────────────────                                      │
│   Controls PHYSICAL PROCESSES - monitors and manipulates the         │
│   physical world                                                     │
│   Examples: Power grids, water treatment, manufacturing lines        │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

## The Physical World Connection

This is the most important concept to understand: **OT systems interact with the physical world**.

When an OT system fails or is compromised:
- A valve might open when it should close
- A pump might run dry and burn out
- A generator might spin too fast and explode
- A chemical mixture might become toxic
- A safety system might not respond

### Cyber-Physical Systems

OT systems are **cyber-physical systems** - they bridge the digital and physical worlds:

```
┌──────────────────────────────────────────────────────────────────────┐
│                    Cyber-Physical Loop                               │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│                        ┌───────────────┐                             │
│                        │   Controller  │                             │
│                        │   (PLC/DCS)   │                             │
│                        └───────┬───────┘                             │
│              Control           │           Sense                     │
│              Commands          │           Data                      │
│                   ┌────────────┴────────────┐                        │
│                   │                         │                        │
│                   ▼                         │                        │
│            ┌──────────────┐          ┌──────────────┐                │
│            │   Actuator   │          │    Sensor    │                │
│            │  (Valve,     │          │ (Temp, Flow, │                │
│            │   Motor)     │          │  Pressure)   │                │
│            └──────┬───────┘          └──────┬───────┘                │
│                   │                         │                        │
│                   ▼                         │                        │
│            ┌─────────────────────────────────┐                       │
│            │      PHYSICAL PROCESS           │                       │
│            │   (Chemical reaction, flow,     │                       │
│            │    temperature, pressure)       │                       │
│            └─────────────────────────────────┘                       │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

## Basic Control Theory

### The Feedback Loop

All OT systems operate on the principle of feedback control:

1. **Measure** - Sensors read current state (temperature, pressure, level, flow)
2. **Compare** - Controller compares measurement to desired setpoint
3. **Compute** - Controller calculates needed adjustment
4. **Act** - Actuators change the physical process
5. **Repeat** - Cycle runs continuously

### PID Control

Most industrial processes use **PID (Proportional-Integral-Derivative)** control:

```
┌──────────────────────────────────────────────────────────────────────┐
│                    PID Controller Explained                          │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Setpoint (SP) ──────────┬───────────────────────────────────────►  │
│                           │                                          │
│   Process Variable (PV) ──┼──►  Error = SP - PV                      │
│                           │                                          │
│                           ▼                                          │
│                    ┌─────────────┐                                   │
│                    │     PID     │                                   │
│                    │  Algorithm  │                                   │
│                    └──────┬──────┘                                   │
│                           │                                          │
│              ┌────────────┼────────────┐                             │
│              │            │            │                             │
│              ▼            ▼            ▼                             │
│         Proportional  Integral   Derivative                          │
│         (P)           (I)        (D)                                 │
│                                                                      │
│   P = How hard to react to CURRENT error                             │
│   I = How hard to react to ACCUMULATED error over time               │
│   D = How hard to react to RATE OF CHANGE of error                   │
│                                                                      │
│   Output = Kp*Error + Ki*∫Error + Kd*(dError/dt)                     │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

**Why does this matter for security?**

- Manipulating sensor values (the PV) causes the controller to make wrong decisions
- Changing setpoints causes the process to operate unsafely
- Altering PID parameters can make systems unstable
- Injecting delays causes oscillation and potentially damage

### Real-Time Requirements

OT systems operate in **real-time** - responses must happen within strict time limits:

| Response Category | Time Requirement | Example |
|-------------------|------------------|---------|
| **Safety Critical** | < 10 ms | Emergency shutdown |
| **Process Control** | 10 - 100 ms | Temperature regulation |
| **Supervisory** | 100 ms - 1 s | Operator displays |
| **Historical** | Seconds - Minutes | Data logging |

**Security implication**: Any security control that adds latency beyond these limits can cause process failures.

## Process States

Industrial processes operate in different states:

```
┌──────────────────────────────────────────────────────────────────────┐
│                    Process Operating States                          │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   SHUTDOWN ──► STARTUP ──► RUNNING ──► STEADY STATE                  │
│       ▲                                     │                        │
│       │                                     │                        │
│       │           UPSET CONDITION           │                        │
│       │                 │                   │                        │
│       │                 ▼                   │                        │
│       └──── EMERGENCY SHUTDOWN ◄────────────┘                        │
│                                                                      │
│   ─────────────────────────────────────────────────────────────────  │
│                                                                      │
│   STEADY STATE: Normal operation, process at target values           │
│   STARTUP: Bringing process online, most dangerous period            │
│   SHUTDOWN: Planned process stoppage                                 │
│   UPSET: Abnormal condition requiring intervention                   │
│   EMERGENCY: Safety system triggered, immediate halt                 │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

**Startup and shutdown are the most dangerous periods** - this is when:
- Process variables are changing rapidly
- Safety margins are narrowest
- Operator intervention is most needed
- Cyber attacks have the greatest potential impact

## Common Industrial Processes

### Continuous Processes

Run 24/7, maintaining steady state:
- Oil refining
- Chemical production
- Power generation
- Water treatment

**Characteristics**:
- Small deviations from setpoint are normal
- Large changes happen slowly (hours to days)
- Shutdowns are expensive and risky

### Batch Processes

Run in discrete cycles:
- Pharmaceutical manufacturing
- Food/beverage production
- Specialty chemicals

**Characteristics**:
- Recipe-based (sequence of steps)
- Each batch may be different
- Clear start and end points

### Discrete Manufacturing

Produce individual items:
- Automotive assembly
- Electronics manufacturing
- Packaging lines

**Characteristics**:
- Count-based production
- Part tracking important
- Line speed optimization

## Physical Equipment Basics

### Sensors

Measure physical properties:

| Sensor Type | Measures | Common Technologies |
|-------------|----------|---------------------|
| **Temperature** | Heat | Thermocouple, RTD, thermistor |
| **Pressure** | Force per area | Strain gauge, capacitive |
| **Level** | Tank contents | Ultrasonic, radar, float |
| **Flow** | Fluid movement | Coriolis, magnetic, vortex |
| **Analytical** | Composition | pH, conductivity, chromatograph |
| **Vibration** | Mechanical health | Accelerometer |

**Security relevance**: Sensors can be spoofed by injecting false signals, or blinded by generating noise.

### Actuators

Change the physical process:

| Actuator Type | Function | Drive Technology |
|---------------|----------|------------------|
| **Valve** | Control flow | Pneumatic, electric, hydraulic |
| **Motor** | Rotate/move | AC, DC, servo, stepper |
| **Heater** | Add heat | Electric resistance, steam |
| **Pump** | Move fluids | Centrifugal, positive displacement |
| **Conveyor** | Move materials | Belt, chain, roller |

**Security relevance**: Commanding actuators directly can cause immediate physical damage.

### Variable Frequency Drives (VFDs)

Control motor speed electronically:

```
┌──────────────────────────────────────────────────────────────────────┐
│                    VFD in a System                                   │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐           │
│   │  Power  │───►│   VFD   │───►│  Motor  │───►│  Pump   │           │
│   │  (AC)   │    │         │    │         │    │         │           │
│   └─────────┘    └────┬────┘    └─────────┘    └─────────┘           │
│                       │                                              │
│                       │ Control                                      │
│                       │ Signal                                       │
│                       │                                              │
│                  ┌────┴────┐                                         │
│                  │   PLC   │                                         │
│                  └─────────┘                                         │
│                                                                      │
│   VFD controls motor speed by changing frequency                     │
│   Typically 0-60 Hz (or 0-50 Hz in Europe)                           │
│   Speed commands can be analog (4-20mA) or digital (Modbus)          │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

**VFDs were a target in Stuxnet** - the malware manipulated drive frequencies to damage centrifuges.

## Safety Systems

### Layers of Protection

Industrial safety uses multiple independent layers:

```
┌──────────────────────────────────────────────────────────────────────┐
│                    Layers of Protection Model                        │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│              ┌─────────────────────────────────┐                     │
│              │     Community Emergency         │ ◄── External        │
│              │        Response                 │     Response        │
│         ┌────┴─────────────────────────────────┴────┐                │
│         │       Plant Emergency Response            │                │
│    ┌────┴───────────────────────────────────────────┴────┐           │
│    │         Physical Protection (Relief Valves,         │           │
│    │              Containment, Dikes)                    │           │
│    ┌────────────────────────────────────────────────────────┐        │
│    │    Safety Instrumented System (SIS) - AUTOMATIC        │        │
│    ┌────────────────────────────────────────────────────────────┐    │
│    │         Alarms and Operator Intervention                   │    │
│    ┌────────────────────────────────────────────────────────────────┐│
│    │              Basic Process Control System (BPCS)               ││
│    ├────────────────────────────────────────────────────────────────┤│
│    │                    PROCESS                                     ││
│    └────────────────────────────────────────────────────────────────┘│
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

### Safety Instrumented Systems (SIS)

Dedicated systems that prevent catastrophic failures:

| Term | Description |
|------|-------------|
| **SIS** | Safety Instrumented System - the overall safety system |
| **SIF** | Safety Instrumented Function - a specific protective action |
| **SIL** | Safety Integrity Level - reliability requirement (1-4) |
| **SRS** | Safety Requirements Specification - documentation |

**SIS is separate from the control system** - this is intentional:

```
┌──────────────────────────────────────────────────────────────────────┐
│                    SIS Independence                                  │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   ┌─────────────────┐              ┌─────────────────┐               │
│   │  Control System │              │ Safety System   │               │
│   │     (BPCS)      │              │     (SIS)       │               │
│   ├─────────────────┤              ├─────────────────┤               │
│   │ Purpose:        │              │ Purpose:        │               │
│   │ Run process     │              │ Prevent harm    │               │
│   │ efficiently     │              │ on failure      │               │
│   │                 │              │                 │               │
│   │ Failure mode:   │              │ Failure mode:   │               │
│   │ Process upset   │              │ Trips process   │               │
│   │ (recoverable)   │              │ (safe state)    │               │
│   └────────┬────────┘              └────────┬────────┘               │
│            │                                │                        │
│            │     INDEPENDENT SYSTEMS        │                        │
│            │     Different hardware         │                        │
│            │     Different networks         │                        │
│            │     Different power            │                        │
│            │                                │                        │
│            └────────────┬───────────────────┘                        │
│                         │                                            │
│                         ▼                                            │
│              ┌────────────────────┐                                  │
│              │  PHYSICAL PROCESS  │                                  │
│              └────────────────────┘                                  │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

**Critical security principle**: Never connect security controls to SIS networks. The SIS must remain independent.

## Process Examples

### Example 1: Water Treatment

```
┌──────────────────────────────────────────────────────────────────────┐
│                    Water Treatment Process                           │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Raw      ┌─────────┐   ┌─────────┐   ┌─────────┐   ┌─────────┐      │
│  Water───►│ Screen  │──►│ Coag/   │──►│ Filter  │──►│ Chlorine│──► Clean
│           │         │   │ Floc    │   │         │   │ Contact │    Water
│           └─────────┘   └────┬────┘   └────┬────┘   └────┬────┘      │
│                              │             │             │           │
│                         ┌────┴────┐   ┌────┴────┐   ┌────┴────┐      │
│                         │Chemical │   │Turbidity│   │ pH/Cl2  │      │
│                         │ Dosing  │   │ Monitor │   │ Monitor │      │
│                         └─────────┘   └─────────┘   └─────────┘      │
│                                                                      │
│   Key Control Loops:                                                 │
│   • Chemical dosing based on raw water turbidity                     │
│   • Chlorine dosing to maintain residual                             │
│   • Filter backwash based on differential pressure                   │
│                                                                      │
│   Security Concerns:                                                 │
│   • Over-chlorination = chemical hazard                              │
│   • Under-chlorination = public health risk                          │
│   • False sensor readings = wrong chemical dosing                    │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

### Example 2: Power Generation

```
┌──────────────────────────────────────────────────────────────────────┐
│                    Combined Cycle Power Plant                        │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│        ┌────────────────┐    ┌────────────────┐                      │
│   Gas─►│  Gas Turbine   │───►│   Generator    │──► Grid              │
│   Air─►│   (Combustion) │    │     #1         │    (Electricity)     │
│        └───────┬────────┘    └────────────────┘                      │
│                │                                                     │
│                │ Hot Exhaust                                         │
│                ▼                                                     │
│        ┌────────────────┐    ┌────────────────┐                      │
│        │     HRSG       │───►│ Steam Turbine  │                      │
│        │ (Heat Recovery │    │                │                      │
│        │  Steam Gen)    │    └───────┬────────┘                      │
│        └────────────────┘            │                               │
│                                      ▼                               │
│                              ┌────────────────┐                      │
│                              │   Generator    │──► Grid              │
│                              │     #2         │                      │
│                              └────────────────┘                      │
│                                                                      │
│   Key Control Points:                                                │
│   • Fuel flow rate (MW output)                                       │
│   • Steam temperature/pressure                                       │
│   • Generator frequency (must match grid: 50/60 Hz)                  │
│   • Voltage regulation                                               │
│                                                                      │
│   Security Concerns:                                                 │
│   • Frequency deviation = grid instability                           │
│   • Overspeed = catastrophic turbine failure                         │
│   • Grid synchronization attacks                                     │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

## Failure Modes

Understanding how things fail is critical for OT security:

### Equipment Failure Modes

| Component | Failure Mode | Security Relevance |
|-----------|--------------|-------------------|
| **Valve** | Fail open, fail closed, stuck | Know expected failure position |
| **Motor** | Overheat, overcurrent, mechanical | Current limits are protective |
| **Sensor** | Drift, stuck, noise | False readings mask attacks |
| **PLC** | Watchdog timeout, memory | PLCs fail to safe state |
| **Network** | Loss of comms, latency | Must plan for network failure |

### Fail-Safe Design

OT systems are designed to **fail to a safe state**:

```
┌──────────────────────────────────────────────────────────────────────┐
│                    Fail-Safe Examples                                │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   Equipment          Failure Mode        Safe State                  │
│   ─────────────────────────────────────────────────────────────────  │
│   Fuel valve         Loss of signal      CLOSES (stops fuel)         │
│   Emergency stop     Button pressed      ACTIVATES shutdown          │
│   Tank level         Sensor failure      ALARMS high                 │
│   Motor drive        Communication lost  STOPS or holds speed        │
│   Safety relay       Coil de-energized   TRIPS circuit               │
│                                                                      │
│   Key Principle: Systems should fail to least harmful state          │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

## Units and Measurements

OT uses engineering units. Know these:

### Process Units

| Measurement | US Units | Metric | Notes |
|-------------|----------|--------|-------|
| **Temperature** | °F | °C | °F = °C × 9/5 + 32 |
| **Pressure** | PSI, inHg | bar, kPa | 1 bar ≈ 14.5 PSI |
| **Flow** | GPM, SCFM | m³/h, L/min | "Standard" = at standard conditions |
| **Level** | ft, inches | m, mm | Often % of span |
| **Speed** | RPM | RPM | Revolutions per minute |

### Signal Types

| Signal Type | Range | Description |
|-------------|-------|-------------|
| **4-20 mA** | 4-20 milliamps | Most common analog signal |
| **0-10 V** | 0-10 volts | Voltage signal |
| **24 VDC** | On/Off | Digital discrete signal |
| **Thermocouple** | mV | Direct temperature sensor |
| **RTD** | Ohms | Resistance temperature |

**Why 4-20 mA?** The 4 mA "live zero" distinguishes wire break (0 mA) from minimum reading (4 mA).

## Key Takeaways

1. **OT controls the physical world** - cyber attacks have physical consequences
2. **Real-time is mandatory** - you cannot add latency to critical control loops
3. **Safety systems are separate** - never connect security controls to SIS
4. **Fail-safe is by design** - systems fail to known, safe states
5. **Startup/shutdown are dangerous** - most incidents occur during transitions
6. **Know the process** - you cannot secure what you don't understand

## Study Questions

1. A water treatment plant's chlorine sensor shows 0.5 mg/L residual. The setpoint is 1.0 mg/L. What will the PID controller do?

2. Why do industrial systems use 4-20 mA signals instead of 0-20 mA?

3. What is the difference between a safety shutdown initiated by SIS vs. a normal shutdown?

4. Why shouldn't security monitoring tools be placed on SIS networks?

5. A VFD is commanding a pump motor at 45 Hz. What happens if you send a command for 75 Hz?

## Next Steps

Continue to [02-control-systems-101.md](02-control-systems-101.md) to learn about the specific hardware and software that implements these control concepts.

## References

- ISA-95 Enterprise-Control System Integration
- IEC 61131-3 PLC Programming Languages
- IEC 61511 Safety Instrumented Systems for Process Industries
- NIST SP 800-82 Guide to Industrial Control Systems Security
