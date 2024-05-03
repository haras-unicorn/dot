{ self, ... }:

{
  imports = [
    "${self}/src/module/amd-cpu"
    "${self}/src/module/nvidia-gpu"
    "${self}/src/module/firmware"
    "${self}/src/module/swap"

    "${self}/src/module/grub"
    "${self}/src/module/plymouth"
    "${self}/src/module/zen"
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
    "${self}/src/module/sddm"
    "${self}/src/module/qtile"

    "${self}/src/module/virtual"
    "${self}/src/module/windows"

    "${self}/src/module/locate"
    "${self}/src/module/gvfs"
    "${self}/src/module/transmission"

    "${self}/src/distro/coreutils"
    "${self}/src/distro/diag"
    "${self}/src/distro/console"
    "${self}/src/distro/xserver"
    "${self}/src/distro/app"
  ];

  shared = {
    dot = {
      hardware.ram = 16;
      hardware.mainMonitor = "DVI-D-0";
      hardware.monitors = [ "DVI-D-0" "HDMI-0" ];
      hardware.networkInterface = "enp3s0";
      hardware.cpuHwmon = "/sys/class/hwmon/hwmon1/temp1_input";
      hardware.soundcardPciId = "08:00.3";
      hardware.nvidiaDriver.version = "legacy_470";
      hardware.nvidiaDriver.open = false;

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
