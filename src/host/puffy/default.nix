{
  meta.dot = {
    hardware.ram = 8;
    hardware.networkInterface = "eth0";
    groups = [ "mlocate" ];
    location.timeZone = "Europe/Zagreb";
    shell = { pkg = "nushell"; bin = "nu"; module = "nushell"; };
    editor = { pkg = "helix"; bin = "hx"; module = "helix"; };
    gpg = { pkg = "pinentry"; bin = "pinentry-tty"; flavor = "tty"; };
  };

  hardware = { self, config, modulesPath, nixos-hardware, ... }: {
    imports = [
      # NITPICK: doesn't work without this for now
      # it should work with just `nixos-generate`
      "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
      nixos-hardware.nixosModules.raspberry-pi-4
    ];

    # NOTE: the normal nixos rpi4 hardware uses this boot loader
    boot.loader.generic-extlinux-compatible.enable = false;

    # NOTE: https://github.com/NixOS/nixpkgs/issues/154163#issuecomment-1008362877  
    nixpkgs.overlays = [
      (final: super: {
        makeModulesClosure = x:
          super.makeModulesClosure (x // { allowMissing = true; });
      })
    ];
  };

  system = { self, userName, hostName, vpnHost, vpnDomain, ... }: {
    imports = [
      "${self}/src/module/system/grub"

      "${self}/src/module/system/location"
      "${self}/src/module/system/network"

      "${self}/src/module/system/sudo"
      "${self}/src/module/system/locate"

      "${self}/src/module/system/openssh"
      "${self}/src/module/system/openvpn-client"
    ];

    dot.openssh.enable = true;
    dot.openssh.authorizations = {
      haras = [ "hearth" "workbug" ];
    };

    dot.openvpn.client.enable = true;
    dot.openvpn.client.host = vpnHost;
    dot.openvpn.client.domain = vpnDomain;
  };

  user = { self, ... }: {
    imports = [
      "${self}/src/distro/coreutils"
      "${self}/src/distro/diag"
      "${self}/src/distro/console"
    ];
  };
}
