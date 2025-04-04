# GridNix: Industrial Control Systems Security Research Platform

## Introduction

GridNix is a specialized NixOS-based operating system designed specifically for industrial control systems (ICS) and SCADA security research. It focuses on critical infrastructure security, providing researchers, penetration testers, and security professionals with a comprehensive toolkit for assessing and securing industrial environments.

## ICS/SCADA Security Use Cases

### 1. Protocol Analysis and Reconnaissance

Industrial control systems utilize specialized protocols that differ significantly from traditional IT networks. GridNix provides tools for:

- **Protocol Discovery**: Identify and map industrial protocols (Modbus, Profinet, EtherNet/IP, S7, DNP3, IEC 61850, etc.) across networks
- **Traffic Analysis**: Capture and analyze industrial protocol traffic to understand system behavior
- **Device Enumeration**: Discover PLCs, RTUs, HMIs, and other industrial components on the network
- **Vulnerability Scanning**: Identify known vulnerabilities in industrial devices and protocols

**Example Workflow**:
```bash
# Scan network for Modbus devices
plcscan --protocol modbus 192.168.1.0/24

# Capture and analyze industrial traffic
wireshark -i eth0 -k

# Scan Siemens S7 PLCs for vulnerabilities
s7scan --ip 192.168.1.10 --scan-vulnerabilities
```

### 2. Device Emulation and Simulation

Testing security controls often requires simulating industrial devices and networks:

- **PLC Emulation**: Create virtual PLCs to test attack scenarios
- **Protocol Simulation**: Generate industrial protocol traffic for testing detection systems
- **HMI Development**: Prototype and test human-machine interfaces
- **Grid Simulation**: Model power grid components and their interactions

**Example Workflow**:
```bash
# Start a Modbus simulator
modbuspal --config modbus_sim.mbp

# Run a power grid simulation
gridlab-d power_model.glm

# Launch a simple HMI prototype
pyHMI --config plant_hmi.json
```

### 3. Vulnerability Assessment and Exploitation

GridNix includes specialized tools for identifying and demonstrating security issues:

- **Firmware Analysis**: Extract and analyze PLC and RTU firmware
- **Protocol Exploitation**: Test industrial protocols for security weaknesses
- **Authentication Bypass**: Assess authentication mechanisms in industrial systems
- **Logic Manipulation**: Analyze and modify PLC logic securely in test environments

**Example Workflow**:
```bash
# Extract firmware from a binary image
binwalk -e firmware.bin

# Test for Modbus vulnerabilities
isf
use modbus/scanner/discover
set RHOSTS 192.168.1.0/24
run

# Scan CODESYS-based controllers for vulnerabilities
codesys-vulnerability-scanner --target 192.168.1.15
```

### 4. Hardware Interaction

Physical interfaces are crucial in industrial environments:

- **Serial Communication**: Interface with RS-232/485 industrial devices
- **CAN Bus Analysis**: Monitor and interact with CAN-based industrial networks
- **JTAG Debugging**: Access debug interfaces on industrial hardware
- **Signal Analysis**: Capture and decode electrical signals from industrial equipment

**Example Workflow**:
```bash
# Monitor CAN bus traffic
candump can0

# Communicate with a device over RS-485
minicom -D /dev/ttyUSB0 -b 9600

# Debug a PLC via JTAG
openocd -f interface/ftdi/olimex-arm-usb-ocd-h.cfg -f target/stm32f1x.cfg
```

### 5. Security Monitoring and Defense

GridNix also supports defensive security research:

- **Intrusion Detection**: Configure and test IDS systems with industrial protocol rules
- **Anomaly Detection**: Develop and test algorithms for detecting abnormal industrial behavior
- **Secure Architecture**: Design and test secure industrial network architectures
- **Incident Response**: Practice response procedures for industrial security incidents

**Example Workflow**:
```bash
# Configure Snort with ICS-specific rules
snort3 -c /etc/snort/snort.conf -i eth0

# Monitor industrial traffic for anomalies
python3 ics_anomaly_detector.py --interface eth0 --baseline baseline.json
```

## Sample Configuration.nix Snippets

### Basic PLC Emulation Setup

```nix
{ config, pkgs, ... }:

{
  # Enable required kernel modules for industrial hardware
  boot.kernelModules = [ "can" "can_raw" "can_dev" ];
  
  # Low-latency kernel settings for deterministic timing
  boot.kernelParams = [ "isolcpus=1" "nohz_full=1" "rcu_nocbs=1" ];
  
  # Install PLC emulation tools
  environment.systemPackages = with pkgs; [
    openplc
    modbuspal
    pymodbus
    python39Packages.pycomm3  # For Allen Bradley / EtherNet/IP
  ];
  
  # Configure CAN interface
  systemd.network.networks."40-can0" = {
    matchConfig.Name = "can0";
    networkConfig = {
      LinkLocalAddressing = "no";
    };
    extraConfig = ''
      [CAN]
      BitRate=250000
    '';
  };
  
  # Add udev rules for industrial hardware
  services.udev.extraRules = ''
    # Siemens USB-MPI adapter
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0908", ATTRS{idProduct}=="0004", MODE="0666", GROUP="dialout"
    
    # USB-to-RS485 adapters
    SUBSYSTEM=="tty", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6001", SYMLINK+="rs485", MODE="0666"
  '';
}
```

### Modbus Server Configuration

```nix
{ config, pkgs, ... }:

{
  # Create a systemd service for a Modbus TCP server
  systemd.services.modbus-server = {
    description = "Modbus TCP Server";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    
    serviceConfig = {
      ExecStart = "${pkgs.python3}/bin/python3 ${pkgs.python3Packages.pymodbus}/bin/pymodbus.server --host 0.0.0.0 --port 502 --store-type sequential --context-type memory";
      Restart = "always";
      User = "root";
    };
  };
  
  # Open firewall for Modbus TCP
  networking.firewall.allowedTCPPorts = [ 502 ];
}
```

### IEC 61850 Substation Configuration

```nix
{ config, pkgs, ... }:

{
  # Install IEC 61850 tools
  environment.systemPackages = with pkgs; [
    libiec61850
  ];
  
  # Create a systemd service for IEC 61850 server
  systemd.services.iec61850-server = {
    description = "IEC 61850 MMS Server";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    
    serviceConfig = {
      ExecStart = "${pkgs.libiec61850}/bin/server_example_basic_io";
      Restart = "always";
      User = "root";
    };
  };
  
  # Open firewall for MMS protocol (IEC 61850)
  networking.firewall.allowedTCPPorts = [ 102 ];
}
```

## Getting Started with GridNix for ICS Security

1. **Build or download** the GridNix ISO
2. **Boot** into the live environment or install to disk
3. **Configure** network interfaces for your industrial environment
4. **Connect** to industrial hardware or set up emulation environments
5. **Begin** your security research with the pre-installed tools

## Best Practices for ICS Security Research

1. **Never** connect GridNix directly to production industrial networks
2. **Always** use isolated test environments for security testing
3. **Document** all findings and share responsibly with vendors
4. **Consider** the potential physical impacts of security testing
5. **Follow** responsible disclosure procedures for any vulnerabilities discovered

## Contributing to GridNix

We welcome contributions to enhance GridNix's capabilities for industrial security research:

1. **Tool Integration**: Help package additional ICS security tools
2. **Hardware Support**: Contribute drivers and configurations for industrial hardware
3. **Documentation**: Improve guides and examples for ICS security testing
4. **Use Cases**: Share your GridNix workflows for specific industrial systems

Please see [CONTRIBUTING.md](CONTRIBUTING.md) for more details on how to contribute to the project.
