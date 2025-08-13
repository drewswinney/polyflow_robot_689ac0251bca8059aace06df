{ buildROSWorkspace, rviz2, roscpp, gdb}:

buildROSWorkspace {
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
