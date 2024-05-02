{
  meta.dot = {
    wsl = true;
    groups = [ "mlocate" "video" "audio" ];
    shell = { pkg = "nushell"; bin = "nu"; module = "nushell"; };
    editor = { pkg = "helix"; bin = "hx"; module = "helix"; };
    gpg = { pkg = "pinentry"; bin = "pinentry-curses"; flavor = "curses"; };
  };

  hardware = {
    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

    wsl.startMenuLaunchers = true;
    wsl.interop.register = true;
  };

  system = { self, ... }: {
    wsl.enable = true;

    imports = [
      "${self}/src/module/location"
      "${self}/src/module/network"
      "${self}/src/module/sudo"
      "${self}/src/module/ssh"
      "${self}/src/module/keyring"
      "${self}/src/module/polkit"
      "${self}/src/module/locate"
    ];
  };

  user = { self, ... }: {
    imports = [
      "${self}/src/distro/coreutils"
      "${self}/src/distro/diag"
      "${self}/src/distro/console"
    ];
  };
}
