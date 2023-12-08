# TODO: grub and ssh in modules

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

  system = { self, ... }: {
    imports = [
      "${self}/src/module/system/hardened"

      "${self}/src/module/system/location"
      "${self}/src/module/system/network"

      "${self}/src/module/system/sudo"
      "${self}/src/module/system/sshd"
      "${self}/src/module/system/locate"
    ];

    services.fstrim.enable = true;

    boot.loader.grub.device = "/dev/vda";

    users.users.haras.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIldtUTZ5a9w3gKUkEvX0IF7OE03tEBK7e5gZTvWyjfc"
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
