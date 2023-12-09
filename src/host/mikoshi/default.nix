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
      "${self}/src/module/system/locate"

      "${self}/src/module/system/openssh"
      "${self}/src/module/system/openvpn"
    ];

    boot.loader.grub.device = "/dev/vda";

    users.users.haras.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIldtUTZ5a9w3gKUkEvX0IF7OE03tEBK7e5gZTvWyjfc"
    ];

    services.openvpn.servers.mikoshi.config = ''
      port 1194
      proto udp
      dev tun

      ca /etc/openvpn/ca.crt
      cert /etc/openvpn/server.crt
      key /etc/openvpn/server.key
      dh /etc/openvpn/dh.pem
      tls-auth /etc/openvpn/ta.key 0

      server 10.8.0.0 255.255.255.0
      ifconfig-pool-persist ipp.txt
      # push "redirect-gateway def1" # redirect everything through the vpn
      push "dhcp-option DNS 8.8.8.8"
      keepalive 10 120

      cipher AES-256-CBC
      auth SHA256

      user nobody
      group nogroup

      status /var/log/openvpn/status.log
      log-append /var/log/openvpn/openvpn.log
      verb 3
    '';
  };

  user = { self, ... }: {
    imports = [
      "${self}/src/distro/coreutils"
      "${self}/src/distro/diag"
      "${self}/src/distro/console"
    ];
  };
}
