{
  meta.dot = {
    hardware.ram = 32;
    hardware.mainMonitor = "DP-1";
    hardware.monitors = [ "DP-1" ];
    hardware.networkInterface = "enp37s0";
    hardware.cpuHwmon = "/sys/class/hwmon/hwmon2/temp1_input";
    hardware.soundcardPciId = "2b:00.3";

    location.timeZone = "Europe/Zagreb";
    groups = [
      "libvirtd"
      "docker"
      "podman"
      "development"
      "mlocate"
      "video"
      "audio"
      "gaming"
    ];

    gpg = { pkg = "pinentry-gtk2"; bin = "pinentry-gtk-2"; flavor = "gtk2"; };
    shell = { pkg = "nushell"; bin = "nu"; module = "nushell"; };
    editor = { pkg = "helix"; bin = "hx"; module = "helix"; };
    visual = { pkg = "vscode"; bin = "code"; module = "code"; };
    term = { pkg = "kitty"; bin = "kitty"; module = "kitty"; };
    browser = { pkg = "firefox-bin"; bin = "firefox"; module = "firefox"; };

    font.nerd = { name = "JetBrainsMono Nerd Font"; pkg = "JetBrainsMono"; };
    font.mono = { name = "Roboto Mono"; pkg = "roboto-mono"; };
    font.slab = { name = "Roboto Slab"; pkg = "roboto-slab"; };
    font.sans = { name = "Roboto"; pkg = "roboto"; };
    font.serif = { name = "Roboto Serif"; pkg = "roboto-serif"; };
    font.script = { name = "Eunomia"; pkg = "dotcolon-fonts"; };
    font.emoji = { name = "Noto Color Emoji"; pkg = "noto-fonts-emoji"; };
    font.size = { small = 12; medium = 13; large = 16; };
  };

  hardware = { self, config, ... }: {
    imports = [
      "${self}/src/module/hardware/amd-cpu"
      "${self}/src/module/hardware/nvidia-gpu"
      "${self}/src/module/hardware/firmware"
    ];

    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

    boot.initrd.availableKernelModules = [
      "nvme"
      "xhci_pci"
      "ahci"
      "usb_storage"
      "usbhid"
      "sd_mod"
      "sr_mod"
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

    services.fstrim.enable = true;
  };

  system = { self, vpnHost, vpnDomain, ... }: {
    imports = [
      "${self}/src/module/system/grub"
      "${self}/src/module/system/plymouth"
      "${self}/src/module/system/rt"
      "${self}/src/module/system/development"

      "${self}/src/module/system/location"
      "${self}/src/module/system/network"
      "${self}/src/module/system/vpn"
      "${self}/src/module/system/smartmontools"

      "${self}/src/module/system/sudo"
      "${self}/src/module/system/keyring"
      "${self}/src/module/system/polkit"
      "${self}/src/module/system/locate"

      "${self}/src/module/system/pipewire"
      "${self}/src/module/system/fonts"
      "${self}/src/module/system/wayland"
      "${self}/src/module/system/audio"
      "${self}/src/module/system/gvfs"
      "${self}/src/module/system/transmission"

      "${self}/src/module/system/virtual"
      "${self}/src/module/system/gaming"
      "${self}/src/module/system/windows"
    ];

    networking.firewall.allowedTCPPorts = [
      8384 # syncthing
    ];

    services.openvpn.servers."${vpnHost}".config = ''
      client
      dev tun
      proto udp

      ca /etc/openvpn/${vpnHost}/root-ca.ssl.crt
      cert /etc/openvpn/${vpnHost}/client.ssl.crt
      key /etc/openvpn/${vpnHost}/client.ssl.key
      tls-auth /etc/openvpn/${vpnHost}/client.ta.key 1

      remote ${vpnDomain} 1194
      resolv-retry infinite
      nobind

      cipher AES-256-CBC
      auth SHA256
      remote-cert-tls server

      script-security 2
      up /etc/openvpn/update-resolv-conf
      down /etc/openvpn/update-resolv-conf

      verb 3
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
  };

  user = { self, ... }: {
    imports = [
      "${self}/src/distro/coreutils"
      "${self}/src/distro/diag"
      "${self}/src/distro/console"
      "${self}/src/distro/wayland"
      "${self}/src/distro/app"
      "${self}/src/distro/daw"
    ];
  };
}
