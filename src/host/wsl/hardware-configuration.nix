{ nixos-wsl, username, ... }:

{
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  imports = [
    nixos-wsl.nixosModules.wsl
  ];

  wsl.enable = true;
  wsl.startMenuLaunchers = true;
  wsl.defaultUser = "${username}";
  wsl.interop.register = true;
}
