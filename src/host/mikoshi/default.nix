{
  meta.dot = {
    hardware.ram = 1;
    hardware.networkInterface = "ens3";
    groups = [ "mlocate" ];
    location.timeZone = "Etc/UTC";
    shell = { pkg = "nushell"; bin = "nu"; module = "nushell"; };
    editor = { pkg = "helix"; bin = "hx"; module = "helix"; };
    gpg = { pkg = "pinentry"; bin = "pinentry-tty"; flavor = "tty"; };
  };

  hardware = { self, config, ... }: {
    imports = [
      "${self}/src/module/hardware/intel-cpu"
      "${self}/src/module/hardware/firmware"
    ];

    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

    boot.initrd.availableKernelModules = [
      "nvme"
      "ahci"
      "sd_mod"
    ];

    fileSystems."/" = {
      device = "/dev/disk/by-partlabel/nixroot";
      fsType = "ext4";
    };
    fileSystems."/boot" = {
      device = "/dev/disk/by-partlabel/nixboot";
      fsType = "vfat";
    };

    swapDevices = [
      {
        device = "/var/swap";
        size = config.dot.hardware.ram * 1024;
      }
    ];
  };

  system = { self, userName, hostName, ... }: {
    imports = [
      "${self}/src/module/system/hardened"

      "${self}/src/module/system/location"
      "${self}/src/module/system/network"

      "${self}/src/module/system/sudo"
      "${self}/src/module/system/locate"

      "${self}/src/module/system/openssh"
      "${self}/src/module/system/openvpn-server"
    ];

    boot.loader.grub.device = "/dev/vda";

    dot.openssh.enable = true;
    dot.openssh.authorizations = {
      haras = [ "hearth" ];
    };

    dot.openvpn.server.enable = true;
    dot.openvpn.server.host = hostName;
    dot.openvpn.server.clients = {
      "hearth" = "1";
      "workbug" = "2";
      "officer" = "3";
    };
  };

  user = { self, ... }: {
    imports = [
      # "${self}/src/distro/coreutils"
      # "${self}/src/distro/diag"
      # "${self}/src/distro/console"
    ];
  };
}
