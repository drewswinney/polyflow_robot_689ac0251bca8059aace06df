{
  inputs = {
    nix-ros-overlay.url = "github:lopsided98/nix-ros-overlay/master";
    vscode-server.url = "github:nix-community/nixos-vscode-server";
    nix-ros-workspace.url = "github:hacker1024/nix-ros-workspace";
    # Ensure nixpkgs follows nix-ros-overlay's version to avoid compatibility issues
    nixpkgs.follows = "nix-ros-overlay/nixpkgs"; 
  };

  outputs = { self, nixpkgs, nix-ros-overlay, nix-ros-workspace, vscode-server, ... }@inputs:
    let
        ros-workspace = nix-ros-workspace.lib.buildROSWorkspace {
          name = "ros_workspace";
          devPackages = {
            inherit (nixpkgs) roscpp; # Example: roscpp under active development
          };
          prebuiltPackages = {
            inherit (nixpkgs) rviz2; # Example: rviz2 as a prebuilt dependency
          };
          prebuiltShellPackages = {
            inherit (nixpkgs) gdb; # Example: gdb for debugging
          };
        };
    in { 
      defaultPackage."aarch64-linux" = ros-workspace;
      nixosConfigurations."689ac0251bca8059aace06df" = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            # Base NixOS modules
            ./configuration.nix 
            vscode-server.nixosModules.default
            nix-ros-overlay.nixosModules.default
            # Add the nix-ros-overlay to your system overlays
            { nixpkgs.overlays = [ nix-ros-overlay.overlays.default nix-ros-workspace.overlay ]; }
            # You may also need to include nixos-hardware for specific Raspberry Pi 4 hardware support
            # nixos-hardware.nixosModules.raspberry-pi-4 
          ];
          # Further configuration specific to your Raspberry Pi and ROS needs
        };
        substituters = https://ros.cachix.org;
        trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= ros.cachix.org-1:dSyZxI8geDCJrwgvCOHDoAfOm5sV1wCPjBkKL+38Rvo=;
    };
}
