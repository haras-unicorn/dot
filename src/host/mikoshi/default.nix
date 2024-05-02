{
  meta.dot = {
    hardware.ram = 1;
    hardware.networkInterface = "ens3";
    groups = [ "mlocate" ];
    location.timeZone = "Etc/UTC";
    shell = { pkg = "nushell"; bin = "nu"; module = "nushell"; };
    editor = { pkg = "helix"; bin = "hx"; module = "helix"; };
    gpg = { pkg = "pinentry"; bin = "pinentry-curses"; flavor = "curses"; };
  };

  hardware = { self, config, ... }: {
    imports = [
      "${self}/src/module/intel-cpu"
      "${self}/src/module/firmware"
      "${self}/src/module/swap"
    ];

    virtualisation.hypervGuest.enable = true;

    boot.initrd.availableKernelModules = [
      "ata_piix"
      "uhci_hcd"
      "virtio_pci"
      "sr_mod"
      "virtio_blk"
    ];
    boot.initrd.kernelModules = [
      "ext4"
      "vfat"
    ];

    fileSystems."/" = {
      device = "/dev/disk/by-label/NIXROOT";
      fsType = "ext4";
    };
    fileSystems."/boot" = {
      device = "/dev/disk/by-label/NIXBOOT";
      fsType = "vfat";
    };
  };

  system = { self, userName, hostName, ... }: {
    imports = [
      "${self}/src/module/hardened"

      "${self}/src/module/location"
      "${self}/src/module/network"

      "${self}/src/module/sudo"
      "${self}/src/module/locate"

      "${self}/src/module/openssh"
      "${self}/src/module/openvpn-server"
    ];

    boot.loader.grub.device = "/dev/vda";

    dot.openssh.enable = true;
    dot.openssh.authorizations = {
      haras = [ "hearth" "workbug" ];
    };

    dot.openvpn.server.enable = true;
    dot.openvpn.server.host = hostName;
    dot.openvpn.server.domain = "mikoshi";
    dot.openvpn.server.clients = {
      "hearth" = "101";
      "workbug" = "102";
      "puffy" = "103";
    };
  };

  user = { self, ... }: {
    imports = [
      "${self}/src/distro/coreutils"
      "${self}/src/distro/diag"
      "${self}/src/distro/console"
    ];
  };
}
