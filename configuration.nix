{ config, pkgs, lib, ... }:

let
  user = "admin";
  password = "password";
  interface = "end0";
  hostname = "689ac0251bca8059aace06df";
in {
  nixpkgs.overlays = [
    (final: super: {
      makeModulesClosure = x:
        super.makeModulesClosure (x // { allowMissing = true; });
    })
  ];

  imports = [
     "${builtins.fetchGit { url = "https://github.com/NixOS/nixos-hardware.git"; rev="26ed7a0d4b8741fe1ef1ee6fa64453ca056ce113"; }}/raspberry-pi/4"
  ];
  
  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_rpi4;
    initrd.availableKernelModules = [ "xhci_pci" "usbhid" "usb_storage" ];
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = [ "noatime" ];
    };
  };

  system.autoUpgrade.flags = ["--max-jobs" "1" "--cores" "1"];

  networking = {
    hostName = "689ac0251bca8059aace06df";
    networkmanager.enable = true;
    nftables.enable = true;
  };

  environment.etc."nixos/configuration.nix" = {
    source = ./configuration.nix;
    mode = "0644";
  };

  environment.systemPackages = with pkgs; with rosPackages.humble; [ vim git wget inetutils ros-base roscore ];

  services.openssh.enable = true;

  users = {
    mutableUsers = false;
    users."${user}" = {
      isNormalUser = true;
      password = password;
      extraGroups = [ "wheel" ];
    };
  };

  # Services
  systemd.services.polyflow_startup = {
    description = "Clone the robot git repository and start ROS";
    wantedBy = [ "multi-user.target" ]; # Or a more specific target if needed
    after = [ "network-online.target" ]; # Ensure network is available
    serviceConfig = {
      ExecStart = "${pkgs.writeShellScript "clone-repo" ''
        export HOME=/home/${user}
        cd /home/${user}
        ${pkgs.git}/bin/git config --global --unset https.proxy
        ${pkgs.git}/bin/git clone https://github.com/drewswinney/polyflow_robot_689ac0251bca8059aace06df.git
        chown -R ${user}:users /home/admin/polyflow_robot_689ac0251bca8059aace06df
        cd polyflow_robot_689ac0251bca8059aace06df
      ''}";
      StandardError = "inherit"; # Merges stderr with stdout
    };
  };

  systemd.services.roscore = {
    description = "ROS Master";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.rosPackages.humble.roscore}/bin/roscore";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  services.vscode-server.enable = true;

  nix.settings.experimental-features = ["nix-command" "flakes" ];

  hardware.enableRedistributableFirmware = true;
  system.stateVersion = "23.11";
}
