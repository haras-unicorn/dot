{ self, vpnHost, vpnDomain, ... }:

{
  imports = [
    "${self}/src/module/amd-cpu"
    "${self}/src/module/nvidia-gpu"
    "${self}/src/module/firmware"
    "${self}/src/module/swap"

    "${self}/src/module/grub"
    "${self}/src/module/plymouth"
    "${self}/src/module/rt"
    "${self}/src/module/development"

    "${self}/src/module/location"
    "${self}/src/module/network"
    "${self}/src/module/vpn"
    "${self}/src/module/openvpn-client"
    "${self}/src/module/smartmontools"
    "${self}/src/module/bluetooth"

    "${self}/src/module/sudo"
    "${self}/src/module/keyring"
    "${self}/src/module/polkit"
    "${self}/src/module/locate"

    "${self}/src/module/pipewire"
    "${self}/src/module/audio"

    "${self}/src/module/fonts"
    "${self}/src/module/wayland"
    "${self}/src/module/tuigreet"
    "${self}/src/module/hyprland"
    "${self}/src/module/gtklock"
    "${self}/src/module/gvfs"

    "${self}/src/module/transmission"

    "${self}/src/module/virtual"
    "${self}/src/module/gaming"
    "${self}/src/module/windows"

    "${self}/src/distro/coreutils"
    "${self}/src/distro/diag"
    "${self}/src/distro/console"
    "${self}/src/distro/wayland"
    "${self}/src/distro/app"
    "${self}/src/distro/daw"
  ];

  shared = {
    ram = 32;
    mainMonitor = "DP-1";
    monitors = [ "DP-1" ];
    networkInterface = "enp37s0";
    cpuHwmon = "/sys/class/hwmon/hwmon2/temp1_input";
    soundcardPciId = "2b:00.3";

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
      "wireshark"
    ];

    gpg = { pkg = "pinentry-qt"; bin = "pinentry-qt"; flavor = "qt"; };
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

  system = {
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

    services.fstrim.enable = true;

    networking.firewall.allowedTCPPorts = [
      8384 # syncthing
    ];

    dot.openvpn.client.enable = true;
    dot.openvpn.client.host = vpnHost;
    dot.openvpn.client.domain = vpnDomain;
  };
}
