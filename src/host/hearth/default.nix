{ self, pkgs, vpnHost, vpnDomain, ... }:

# TODO: put user in groups in modules
# TODO: modularize hardware more
# TODO: automatically import all modules and use enable

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

    "${self}/src/module/smartmontools"
    "${self}/src/module/bluetooth"
    "${self}/src/module/i2c"

    "${self}/src/module/location"
    "${self}/src/module/network"
    "${self}/src/module/vpn"
    "${self}/src/module/openvpn-client"
    "${self}/src/module/ddns"
    "${self}/src/module/transmission"

    "${self}/src/module/sudo"
    "${self}/src/module/keyring"
    "${self}/src/module/polkit"
    "${self}/src/module/locate"

    "${self}/src/module/pipewire"
    "${self}/src/module/audio"

    "${self}/src/module/fonts"
    "${self}/src/module/wayland"
    "${self}/src/module/gvfs"

    "${self}/src/module/virtual"
    "${self}/src/module/gaming"
    "${self}/src/module/windows"

    "${self}/src/distro/coreutils"
    "${self}/src/distro/diag"
    "${self}/src/distro/console"
    "${self}/src/distro/bling"
    "${self}/src/distro/wayland"
    "${self}/src/distro/app"
    "${self}/src/distro/daw"
  ];

  shared = {
    dot = {
      ram = 32;
      mainMonitor = "DP-3";
      monitors = [ "DP-3" ];
      networkInterface = "enp37s0";
      cpuHwmon = "/sys/class/hwmon/hwmon2/temp1_input";
      soundcardPciId = "2b:00.3";
      nvidiaDriver.open = false;

      location.timeZone = "Europe/Zagreb";
      groups = [
        "libvirtd"
        "docker"
        "podman"
        "development"
        "mlocate"
        "video"
        "audio"
        "games"
        "gamemode"
        "wireshark"
        "i2c"
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
      app-theme = { package = pkgs.materia-theme; name = "Lulezojne-dark"; };
      dark-mode = true;
      wallpaper = "dynamic";
    };
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
