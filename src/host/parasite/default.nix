{ self, pkgs, ... }:

{
  imports = [
    "${self}/src/module/location"
    "${self}/src/module/network"
    "${self}/src/module/sudo"
    "${self}/src/module/ssh"
    "${self}/src/module/keyring"
    "${self}/src/module/polkit"
    "${self}/src/module/locate"

    "${self}/src/distro/coreutils"

    "${self}/src/distro/diag"
    "${self}/src/distro/console"
  ];

  shared = {
    wsl = true;
    groups = [ "mlocate" "video" "audio" ];
    shell = { package = pkgs.nushell; bin = "nu"; };
    editor = { package = pkgs.helix; bin = "hx"; };
    pinentry = { package = pkgs.pinentry; bin = "pinentry-curses"; };
  };

  system = {
    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

    wsl.enable = true;
    wsl.startMenuLaunchers = true;
    wsl.interop.register = true;
  };
}
