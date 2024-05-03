{ self, ... }:

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
    shell = { pkg = "nushell"; bin = "nu"; module = "nushell"; };
    editor = { pkg = "helix"; bin = "hx"; module = "helix"; };
    gpg = { pkg = "pinentry"; bin = "pinentry-curses"; flavor = "curses"; };
  };

  system = {
    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

    wsl.enable = true;
    wsl.startMenuLaunchers = true;
    wsl.interop.register = true;
  };
}
