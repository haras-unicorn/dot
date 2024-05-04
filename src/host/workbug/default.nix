{ self, pkgs, vpnHost, vpnDomain, ... }:

{
  imports = [
    "${self}/src/module/amd-cpu"
    "${self}/src/module/firmware"
    "${self}/src/module/swap"

    "${self}/src/module/grub"
    "${self}/src/module/plymouth"
    "${self}/src/module/zen"
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
    "${self}/src/module/fonts"
    "${self}/src/module/wayland"
    "${self}/src/module/tuigreet"
    "${self}/src/module/gtklock"
    "${self}/src/module/gvfs"
    "${self}/src/module/transmission"

    "${self}/src/module/virtual"
    "${self}/src/module/windows"
    "${self}/src/module/gaming"

    "${self}/src/distro/coreutils"
    "${self}/src/distro/diag"
    "${self}/src/distro/console"
    "${self}/src/distro/wayland"
    "${self}/src/distro/app"
  ];

  shared = {
    hardware.ram = 16;
    hardware.mainMonitor = "eDP-1";
    hardware.monitors = [ "eDP-1" ];
    hardware.networkInterface = "wlp1s0";
    hardware.cpuHwmon = "/sys/class/hwmon/hwmon0/temp1_input";
    hardware.soundcardPciId = "03:00.1";
    hardware.screenBrightnessDevice = "amdgpu_bl0";

    location.timeZone = "Europe/Zagreb";
    groups = [
      "libvirtd"
      "docker"
      "podman"
      "video"
      "audio"
      "development"
      "mlocate"
      "wireshark"
    ];

    pinentry = { packages = pkgs.pinentry-qt; bin = "pinentry-qt"; };
    shell = { packages = pkgs.nushell; bin = "nu"; };
    editor = { packages = pkgs.helix; bin = "hx"; };
    visual = { packages = pkgs.vscode; bin = "code"; };
    terminal = { packages = pkgs.kitty; bin = "kitty"; };
    browser = { packages = pkgs.firefox-bin; bin = "firefox"; };

    font.nerd = { name = "JetBrainsMono Nerd Font"; packages = pkgs.JetBrainsMono; };
    font.mono = { name = "Roboto Mono"; packages = pkgs.roboto-mono; };
    font.slab = { name = "Roboto Slab"; packages = pkgs.roboto-slab; };
    font.sans = { name = "Roboto"; packages = pkgs.roboto; };
    font.serif = { name = "Roboto Serif"; packages = pkgs.roboto-serif; };
    font.script = { name = "Eunomia"; packages = pkgs.dotcolon-fonts; };
    font.emoji = { name = "Noto Color Emoji"; packages = pkgs.noto-fonts-emoji; };
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

    dot.openvpn.client.host = vpnHost;
    dot.openvpn.client.domain = vpnDomain;
  };
}
