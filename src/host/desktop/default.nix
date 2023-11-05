# TODO: configuration.nix - gnu, gtk

{
  meta = {
    dot = {
      hardware = {
        ram = 32;
        mainMonitor = "DP-1";
        monitors = [ "DP-1" ];
        networkInterface = "enp37s0";
        cpuHwmon = "/sys/class/hwmon/hwmon1/temp1_input";
        soundcardPciId = "2b:00.3";
      };

      user.groups = [ "libvirtd" "docker" "podman" "video" "audio" "mlocate" ];
      user.shell = { pkg = "nushell"; bin = "nu"; };

      font.nerd = { name = "JetBrainsMono Nerd Font"; pkg = "JetBrainsMono"; };
      font.mono = { name = "Roboto Mono"; pkg = "roboto-mono"; };
      font.slab = { name = "Roboto Slab"; pkg = "roboto-slab"; };
      font.sans = { name = "Roboto"; pkg = "roboto"; };
      font.serif = { name = "Roboto Serif"; pkg = "roboto-serif"; };
      font.script = { name = "Eunomia"; pkg = "dotcolon-fonts"; };
      font.emoji = { name = "Noto Color Emoji"; pkg = "noto-fonts-emoji"; };
      font.size = { small = 12; medium = 13; large = 16; };

      editor = { pkg = "helix"; bin = "hx"; module = "helix"; };
      visual = { pkg = "vscodium-fhs"; bin = "codium"; module = "code"; };
      term = { pkg = "kitty"; bin = "kitty"; module = "kitty"; };
      browser = { pkg = "firefox-bin"; bin = "firefox"; module = "firefox"; };
      gpg = { pkg = "pinentry-gtk2"; bin = "pinentry-gtk-2"; flavor = "gtk2"; };
    };
  };

  hardware = { config, ... }: {
    hardware.enableAllFirmware = true;

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
  };

  system = { self, ... }: {
    imports = [
      "${self}/src/module/hardware/amd-cpu"
      "${self}/src/module/hardware/nvidia-gpu"

      "${self}/src/module/system/sudo"

      "${self}/src/module/system/grub"
      "${self}/src/module/system/plymouth"

      "${self}/src/module/system/rt"

      "${self}/src/module/system/location"
      "${self}/src/module/system/network"

      "${self}/src/module/system/ssh"
      "${self}/src/module/system/keyring"
      "${self}/src/module/system/polkit"

      "${self}/src/module/system/pipewire"

      "${self}/src/module/system/fonts"
      "${self}/src/module/system/wayland"

      "${self}/src/module/system/virtual"
      "${self}/src/module/system/windows"

      "${self}/src/module/system/locate"
      "${self}/src/module/system/gvfs"
      "${self}/src/module/system/transmission"
    ];
  };

  user = { self, ... }: {
    imports = [
      "${self}/src/distro/coreutils"
      "${self}/src/distro/info"
      "${self}/src/distro/diag"
      "${self}/src/distro/console"
      "${self}/src/distro/wayland"
      "${self}/src/distro/app"
    ];
  };
}
