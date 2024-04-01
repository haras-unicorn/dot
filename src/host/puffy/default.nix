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

  # NOTE: use https://hydra.nixos.org/job/nixos/trunk-combined/nixos.iso_minimal_new_kernel_no_zfs.aarch64-linux to install

  hardware = { self, config, modulesPath, nixos-hardware, ... }: {
    imports = [
      nixos-hardware.nixosModules.raspberry-pi-4
    ];

    # NOTE: the normal nixos rpi4 hardware uses this boot loader
    boot.loader.generic-extlinux-compatible.enable = false;

    boot.swraid.enable = true;
    boot.swraid.mdadmConf = ''
      DEVICE partitions
      ARRAY /dev/md0 UUID=1c6fe860:f4954185:81167fc2:fe4f5c15
    '';

    fileSystems."/firmware" = {
      device = "/dev/disk/by-label/FIRMWARE";
      fsType = "vfat";
    };
    fileSystems."/boot" = {
      device = "/dev/disk/by-label/NIXBOOT";
      fsType = "vfat";
    };
    fileSystems."/" = {
      device = "/dev/md0";
      fsType = "ext4";
    };

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
