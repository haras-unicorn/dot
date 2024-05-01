{
  meta.dot = {
    hardware.ram = 8;
    hardware.networkInterface = "eth0";
    groups = [ "mlocate" ];
    location.timeZone = "Europe/Zagreb";
    shell = { pkg = "nushell"; bin = "nu"; module = "nushell"; };
    editor = { pkg = "helix"; bin = "hx"; module = "helix"; };
    gpg = { pkg = "pinentry"; bin = "pinentry-curses"; flavor = "curses"; };
  };

  hardware = { self, config, nixos-hardware, ... }: {
    imports = [
      nixos-hardware.nixosModules.raspberry-pi-4
    ];

    # NOTE: the normal nixos rpi4 hardware uses this boot loader
    boot.loader.generic-extlinux-compatible.enable = false;

    boot.swraid.enable = true;
    boot.swraid.mdadmConf = ''
      DEVICE partitions
      ARRAY /dev/md0 UUID=1c6fe860:f4954185:81167fc2:fe4f5c15
      MAILADDR social@haras.anonaddy.me
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

    swapDevices = [
      {
        device = "/swap";
        size = 8 * 1024;
      }
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
