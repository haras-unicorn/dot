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

  system = { self, userName, vpnHost, ... }: {
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

    users.users."${userName}".openssh.authorizedKeys.keys = [
      /etc/ssh/.ssh/authorized.pub
    ];
    sops.secrets."authorized.ssh.pub".path = "/home/${userName}/.ssh/authorized.pub";
    sops.secrets."authorized.ssh.pub".owner = "${userName}";
    sops.secrets."authorized.ssh.pub".group = "users";
    sops.secrets."authorized.ssh.pub".mode = "0600";

    services.openvpn.servers."${vpnHost}".config = ''
      port 1194
      dev tun
      proto udp

      ca /etc/openvpn/${vpnHost}/root-ca.ssl.crt
      cert /etc/openvpn/${vpnHost}/server.ssl.crt
      key /etc/openvpn/${vpnHost}/server.ssl.key
      tls-auth /etc/openvpn/${vpnHost}/server.ta.key 0
      dh /etc/openvpn/${vpnHost}/server.dhparam.pem

      server 10.8.0.0 255.255.255.0
      ifconfig-pool-persist /etc/openvpn/${vpnHost}/ipp.txt
      keepalive 10 120
      client-config-dir /etc/openvpn/${vpnHost}/ccd

      cipher AES-256-CBC
      auth SHA256

      user nobody
      group nogroup

      verb 3
      status /var/log/openvpn/status.log
      log-append /var/log/openvpn/openvpn.log
    '';
    sops.secrets."root.ssl.crt".path = "/etc/openvpn/root.ssl.crt";
    sops.secrets."root.ssl.crt".owner = "nobody";
    sops.secrets."root.ssl.crt".group = "nogroup";
    sops.secrets."root.ssl.crt".mode = "0600";
    sops.secrets."server.ssl.crt".path = "/etc/openvpn/server.ssl.crt";
    sops.secrets."server.ssl.crt".owner = "nobody";
    sops.secrets."server.ssl.crt".group = "nogroup";
    sops.secrets."server.ssl.crt".mode = "0600";
    sops.secrets."server.ssl.key".path = "/etc/openvpn/server.ssl.key";
    sops.secrets."server.ssl.key".owner = "nobody";
    sops.secrets."server.ssl.key".group = "nogroup";
    sops.secrets."server.ssl.key".mode = "0600";
    sops.secrets."server.ta.key".path = "/etc/openvpn/server.ta.key";
    sops.secrets."server.ta.key".owner = "nobody";
    sops.secrets."server.ta.key".group = "nogroup";
    sops.secrets."server.ta.key".mode = "0600";
    sops.secrets."server.dhparam.pem".path = "/etc/openvpn/server.dhparam.pem";
    sops.secrets."server.dhparam.pem".owner = "nobody";
    sops.secrets."server.dhparam.pem".group = "nogroup";
    sops.secrets."server.dhparam.pem".mode = "0600";
  };

  user = { self, ... }: {
    imports = [
      "${self}/src/distro/coreutils"
      "${self}/src/distro/diag"
      "${self}/src/distro/console"
    ];
  };
}
