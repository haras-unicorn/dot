{
  meta.dot = {
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

  hardware = { self, config, ... }: {
    imports = [
      "${self}/src/module/hardware/amd-cpu"
      "${self}/src/module/hardware/nvidia-gpu"
      "${self}/src/module/hardware/firmware"
    ];

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
      "${self}/src/module/system/zen"
      "${self}/src/module/system/development"

      "${self}/src/module/system/location"
      "${self}/src/module/system/network"
      "${self}/src/module/system/vpn"

      "${self}/src/module/system/sudo"
      "${self}/src/module/system/keyring"
      "${self}/src/module/system/polkit"

      "${self}/src/module/system/pipewire"
      "${self}/src/module/system/fonts"
      "${self}/src/module/system/xserver"

      "${self}/src/module/system/virtual"
      "${self}/src/module/system/windows"

      "${self}/src/module/system/locate"
      "${self}/src/module/system/gvfs"
      "${self}/src/module/system/transmission"
    ];

    networking.firewall.allowedTCPPorts = [
      8384 # syncthing
    ];
  };

  user = { self, ... }: {
    imports = [
      "${self}/src/distro/coreutils"
      "${self}/src/distro/diag"
      "${self}/src/distro/console"
      "${self}/src/distro/xserver"
      "${self}/src/distro/app"
    ];
  };
}
