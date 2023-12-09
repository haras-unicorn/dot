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

  system = { self, ... }: {
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

    services.openvpn.servers.mikoshi.config = ''
      client
      dev tun
      proto udp
      remote haras-unicorn.xyz 1194
      resolv-retry infinite # If connection to the server is lost, keep trying to resolve indefinitely.
      nobind # Do not bind to local address and port.
      ca ca.crt # The certificate authority (CA) certificate file.
      cert client.crt # The client certificate file, signed by the CA.
      key client.key # The client private key file.
      tls-auth ta.key 1 # The TLS key for HMAC signature verification (the second argument '1' indicates client).
      cipher AES-256-CBC # Encryption cipher - should match the server's setting.
      auth SHA256 # HMAC digest algorithm - should match the server's setting.
      remote-cert-tls server # Ensure the remote cert is from the server.
      verb 3 # Log verbosity level.
      script-security 2
      up /etc/openvpn/update-resolv-conf
      down /etc/openvpn/update-resolv-conf
    '';
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
