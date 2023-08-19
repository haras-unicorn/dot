{ nixos-wsl, ... }:

{
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  imports = [
    nixos-wsl.nixosModules.wsl
  ];

  wsl.enable = true;
  wsl.startMenuLaunchers = true;
  wsl.defaultUser = "nixos";
  wsl.interop.register = true;

  system.stateVersion = "23.11";
}
