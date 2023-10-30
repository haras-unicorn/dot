{
  meta = {
    dot = {
      user.groups = [ "libvirtd" "docker" "podman" "video" "audio" ];
      user.shell = { pkg = "nushell"; bin = "nu"; };
      editor = { pkg = "helix"; bin = "hx"; module = "helix"; };
      visual = { pkg = "codium-fhs"; bin = "codium"; module = "code"; };
      term = { pkg = "kitty"; bin = "kitty"; module = "kitty"; };
      browser = { pkg = "firefox"; bin = "firefox"; module = "firefox"; };
      gnupg = { flavor = "gtk2"; package = "pinentry-gtk2"; bin = "pinentry-gtk-2"; };
      hardware = {
        ram = 32;
        mainMonitor = "DP-1";
        monitors = [ "DP-1" ];
        networkInterface = "enp27s0";
        hwmon = "/sys/class/hwmon/hwmon1/temp1_input";
        soundcardPciId = "2b:00.3";
      };
    };
  };

  system = { self, config, ... }: {
    imports = [
      "${self}/src/module/hardware/amd-cpu/amd-cpu.nix"
      "${self}/src/module/hardware/nvidia-gpu/nvidia-gpu.nix"

      "${self}/src/module/system/sudo/sudo.nix"

      "${self}/src/module/system/grub/grub.nix"
      "${self}/src/module/system/plymouth/plymouth.nix"

      "${self}/src/module/system/rt/rt.nix"

      "${self}/src/module/system/location/location.nix"
      "${self}/src/module/system/network/network.nix"

      "${self}/src/module/system/ssh/ssh.nix"
      "${self}/src/module/system/keyring/keyring.nix"
      "${self}/src/module/system/polkit/polkit.nix"

      "${self}/src/module/system/pipewire/pipewire.nix"

      "${self}/src/module/system/fonts/fonts.nix"
      # "${self}/src/module/system/xserver/xserver.nix"
      "${self}/src/module/system/wayland/wayland.nix"

      "${self}/src/module/system/virtual/virtual.nix"
      "${self}/src/module/system/windows/windows.nix"
    ];

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

    # TODO: per user?
    # services.transmission.enable = true;
    # services.transmission.openPeerPorts = true;
  };

  user = { self, ... }: {
    imports = [
      "${self}/src/distro/console/console.nix"

      # "${self}/src/distro/de-legacy/de-legacy.nix"
      "${self}/src/distro/de/de.nix"

      "${self}/src/distro/app/app.nix"
    ];
  };
}
