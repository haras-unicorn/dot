{ self, pkgs, hostName, ... }:

{
  imports = [
    "${self}/src/module/intel-cpu"
    "${self}/src/module/firmware"
    "${self}/src/module/swap"

    "${self}/src/module/hardened"

    "${self}/src/module/location"
    "${self}/src/module/network"

    "${self}/src/module/sudo"
    "${self}/src/module/locate"

    "${self}/src/module/openssh"
    "${self}/src/module/openvpn-server"

    "${self}/src/distro/coreutils"
    "${self}/src/distro/diag"
    "${self}/src/distro/console"
  ];

  shared = {
    dot = {
      hardware.ram = 1;
      hardware.networkInterface = "ens3";
      groups = [ "mlocate" ];
      location.timeZone = "Etc/UTC";
      shell = { package = pkgs.nushell; bin = "nu"; };
      editor = { package = pkgs.helix; bin = "hx"; };
      gpg = { package = pkgs.pinentry; bin = "pinentry-curses"; flavor = "curses"; };
    };
  };

  system = {
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

    boot.loader.grub.device = "/dev/vda";

    dot.openssh.enable = true;
    dot.openssh.authorizations = {
      haras = [ "hearth" "workbug" ];
    };

    dot.openvpn.server.host = hostName;
    dot.openvpn.server.domain = "mikoshi";
    dot.openvpn.server.clients = {
      "hearth" = "101";
      "workbug" = "102";
      "puffy" = "103";
    };
  };
}
