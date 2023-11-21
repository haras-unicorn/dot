{
  meta.dot = {
    wsl = true;
    groups = [ "mlocate" "video" "audio" ];
    shell = { pkg = "nushell"; bin = "nu"; module = "nushell"; };
    editor = { pkg = "helix"; bin = "hx"; module = "helix"; };
    gpg = { pkg = "pinentry"; bin = "pinentry-tty"; flavor = "tty"; };
  };

  hardware = {
    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

    wsl.startMenuLaunchers = true;
    wsl.interop.register = true;
  };

  system = { self, ... }: {
    imports = [
      "${self}/src/module/system/location"
      "${self}/src/module/system/network"
      "${self}/src/module/system/sudo"
      "${self}/src/module/system/ssh"
      "${self}/src/module/system/keyring"
      "${self}/src/module/system/polkit"
      "${self}/src/module/system/locate"
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
