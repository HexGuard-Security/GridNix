# Sample configuration.nix for PLC emulation with GridNix
# This file demonstrates how to configure a GridNix system for PLC emulation
# Place this in /etc/nixos/configuration.nix or include it as an import

{ config, pkgs, ... }:

{
  # Enable required kernel modules for industrial hardware
  boot.kernelModules = [ "can" "can_raw" "can_dev" ];
  
  # Low-latency kernel settings for deterministic timing
  boot.kernelParams = [ 
    "isolcpus=1"      # Isolate CPU core 1 for real-time tasks
    "nohz_full=1"     # Disable timer interrupts on isolated core
    "rcu_nocbs=1"     # No RCU callbacks on isolated core
    "intel_pstate=disable" # Disable Intel P-state for more predictable performance
    "processor.max_cstate=1" # Limit CPU power states for lower latency
  ];
  
  # Install PLC emulation and industrial protocol tools
  environment.systemPackages = with pkgs; [
    # Protocol analysis
    plcscan
    modbuspal
    pymodbus
    
    # Emulation tools
    openplc
    python39Packages.pycomm3  # For Allen Bradley / EtherNet/IP
    
    # Utilities
    can-utils             # CAN bus utilities
    socat                 # For serial port redirection
    minicom               # Terminal for serial communication
    wireshark             # Network protocol analyzer
    tcpdump               # Command-line packet analyzer
    
    # Development tools
    gcc
    gnumake
    python39
    python39Packages.pip
  ];
  
  # Configure CAN interface (if hardware is present)
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
    
    # USB-to-RS485 adapters (FTDI based)
    SUBSYSTEM=="tty", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6001", SYMLINK+="rs485", MODE="0666"
    
    # USB-to-RS485 adapters (Prolific based)
    SUBSYSTEM=="tty", ATTRS{idVendor}=="067b", ATTRS{idProduct}=="2303", SYMLINK+="rs485_pl", MODE="0666"
    
    # USB-CAN adapters
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="1234", MODE="0666", GROUP="dialout"
  '';
  
  # Create a systemd service for a Modbus TCP server
  systemd.services.modbus-server = {
    description = "Modbus TCP Server";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    
    serviceConfig = {
      ExecStart = "${pkgs.python3}/bin/python3 -m pymodbus.server --host 0.0.0.0 --port 502 --store-type sequential --context-type memory";
      Restart = "always";
      User = "root";
    };
  };
  
  # Open firewall for industrial protocols
  networking.firewall.allowedTCPPorts = [ 
    502   # Modbus TCP
    102   # S7comm (Siemens S7)
    2222  # EtherNet/IP
    20000 # DNP3
    44818 # EtherNet/IP (Allen Bradley)
  ];
  
  # Enable real-time scheduling for industrial applications
  security.pam.loginLimits = [
    { domain = "@industrial"; type = "soft"; item = "rtprio"; value = "99"; }
    { domain = "@industrial"; type = "hard"; item = "rtprio"; value = "99"; }
    { domain = "@industrial"; type = "soft"; item = "memlock"; value = "unlimited"; }
    { domain = "@industrial"; type = "hard"; item = "memlock"; value = "unlimited"; }
  ];
  
  # Create industrial user group
  users.groups.industrial = {};
  
  # Example user configuration
  users.users.researcher = {
    isNormalUser = true;
    extraGroups = [ "wheel" "industrial" "dialout" "uucp" ];
    initialPassword = "changeme";
  };
  
  # System-wide environment variables for industrial tools
  environment.variables = {
    MODBUS_SERVER = "localhost";
    PYMODBUS_DEBUG = "1";
  };
  
  # Optional: Create a desktop shortcut for common tools
  environment.etc."xdg/autostart/industrial-tools.desktop".text = ''
    [Desktop Entry]
    Name=Industrial Tools
    Comment=Shortcuts to Industrial Control System Tools
    Exec=xfce4-terminal --title "Industrial Tools" --command "echo 'Welcome to GridNix Industrial Tools'; bash"
    Terminal=false
    Type=Application
    Icon=utilities-terminal
    Categories=Application;
  '';
}
