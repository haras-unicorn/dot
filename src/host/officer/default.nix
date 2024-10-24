{ self, pkgs, ... }:

{
  imports = [
    "${self}/src/module/amd-cpu"
    "${self}/src/module/nvidia-gpu"
    "${self}/src/module/firmware"
    "${self}/src/module/swap"

    "${self}/src/module/grub"
    "${self}/src/module/plymouth"
    "${self}/src/module/lts"
    "${self}/src/module/development"

    "${self}/src/module/location"
    "${self}/src/module/network"
    "${self}/src/module/vpn"

    "${self}/src/module/sudo"
    "${self}/src/module/keyring"
    "${self}/src/module/polkit"

    "${self}/src/module/pipewire"
    "${self}/src/module/fonts"
    "${self}/src/module/xserver"

    "${self}/src/module/virtual"
    "${self}/src/module/windows"

    "${self}/src/module/locate"
    "${self}/src/module/gvfs"
    "${self}/src/module/transmission"

    "${self}/src/distro/coreutils"
    "${self}/src/distro/diag"
    "${self}/src/distro/console"
    "${self}/src/distro/bling"
    "${self}/src/distro/xserver"
    "${self}/src/distro/app"
  ];

  shared = {
    dot = {
      ram = 16;
      mainMonitor = "DVI-D-0";
      mainMonitorWidth = 1920;
      mainMonitorDpi = 94;
      monitors = [ "DVI-D-0" ];
      networkInterface = "enp3s0";
      cpuHwmon = "/sys/class/hwmon/hwmon0/temp1_input";
      nvidiaDriver.version = "legacy_470";
      nvidiaDriver.open = false;

      location.timeZone = "Europe/Zagreb";
      groups = [
        "libvirtd"
        "docker"
        "podman"
        "development"
        "video"
        "audio"
        "mlocate"
        "wireshark"
      ];

      pinentry = { package = pkgs.pinentry-qt; bin = "pinentry-qt"; };
      shell = { package = pkgs.nushell; bin = "nu"; };
      editor = { package = pkgs.helix; bin = "hx"; };
      visual = { package = pkgs.vscode; bin = "code"; };
      terminal = { package = pkgs.kitty; bin = "kitty"; };
      browser = { package = pkgs.firefox-bin; bin = "firefox"; };

      font.nerd = { name = "JetBrainsMono Nerd Font"; label = "JetBrainsMono"; };
      font.mono = { name = "Roboto Mono"; package = pkgs.roboto-mono; };
      font.slab = { name = "Roboto Slab"; package = pkgs.roboto-slab; };
      font.sans = { name = "Roboto"; package = pkgs.roboto; };
      font.serif = { name = "Roboto Serif"; package = pkgs.roboto-serif; };
      font.script = { name = "Eunomia"; package = pkgs.dotcolon-fonts; };
      font.emoji = { name = "Noto Color Emoji"; package = pkgs.noto-fonts-emoji; };
      font.size = { small = 12; medium = 13; large = 16; };

      cursor-theme = { package = pkgs.pokemon-cursor; name = "Pokemon"; };
      icon-theme = { package = pkgs.beauty-line-icon-theme; name = "BeautyLine"; };
      wallpaper = "${self}/assets/wallpapers/elden-ring.png";
    };
  };

  system = {
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
      device = "/dev/disk/by-partlabel/nixroot";
      fsType = "ext4";
    };
    fileSystems."/boot" = {
      device = "/dev/disk/by-partlabel/nixboot";
      fsType = "vfat";
    };

    services.fstrim.enable = true;

    networking.firewall.allowedTCPPorts = [
      8384 # syncthing
    ];
  };
}
