{ nixos-hardware, pkgs, self, vpnHost, vpnDomain, ... }:

{
  imports = [
    "${self}/src/module/grub"

    "${self}/src/module/location"
    "${self}/src/module/network"

    "${self}/src/module/sudo"
    "${self}/src/module/locate"

    "${self}/src/module/openssh"
    "${self}/src/module/openvpn-client"

    "${self}/src/distro/coreutils"
    "${self}/src/distro/diag"
    "${self}/src/distro/console"
  ];

  shared = {
    dot = {
      ram = 8;
      networkInterface = "eth0";
      groups = [ "mlocate" ];
      location.timeZone = "Europe/Zagreb";
      shell = { package = pkgs.nushell; bin = "nu"; module = "nushell"; };
      editor = { package = pkgs.helix; bin = "hx"; module = "helix"; };
      gpg = { package = pkgs.pinentry; bin = "pinentry-curses"; flavor = "curses"; };

      openssh.enable = true;
      openssh.authorizations = {
        haras = [ "hearth" "workbug" ];
      };

      openvpn.client.enable = true;
      openvpn.client.host = vpnHost;
      openvpn.client.domain = vpnDomain;
    };
  };

  system = {
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
  };
}
