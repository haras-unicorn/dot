{ config, pkgs, sweet-theme, ... }:

{
  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.loader.efi.canTouchEfiVariables = true;
  # TODO: switch to systemd-boot once you move everything to nixos
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.useOSProber = true;
  boot.initrd.systemd.enable = true;
  boot.initrd.verbose = false;
  boot.consoleLogLevel = 0;
  boot.kernelParams = [
    "quiet"
    "splash"
    "boot.shell_on_fail"
    "vt.global_cursor_default=0"
    "loglevel=3"
    "rd.systemd.show_status=false"
    "rd.udev.log_level=3"
    "udev.log_priority=3"
  ];
  boot.plymouth.enable = true;
  boot.plymouth.theme = "nixos-bgrt";
  boot.plymouth.themePackages = with pkgs; [
    nixos-bgrt-plymouth
  ];

  services.ananicy.enable = true;
  services.earlyoom.enable = true;
  security.rtkit.enable = true;

  location.provider = "geoclue2";
  time.timeZone = "Europe/Zagreb";
  i18n.defaultLocale = "en_US.UTF-8";
  console.useXkbConfig = true;

  networking.hostName = "KARBURATOR";
  networking.nftables.enable = true;
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [
    7860
  ];
  networking.networkmanager.enable = true;

  services.picom.enable = true;
  services.xserver.enable = true;
  services.xserver.layout = "us";
  services.xserver.libinput.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.displayManager.sddm.autoNumlock = true;
  services.xserver.displayManager.sddm.theme = "${sweet-theme}/kde/sddm";
  services.xserver.windowManager.qtile.enable = true;
  services.xserver.windowManager.qtile.extraPackages =
    python3Packages: with python3Packages; [
      psutil
    ];
  programs.dconf.enable = true;

  services.pipewire.enable = true;
  services.pipewire.wireplumber.enable = true;
  services.pipewire.alsa.enable = true;
  services.pipewire.jack.enable = true;
  services.pipewire.pulse.enable = true;

  services.qemuGuest.enable = true;
  virtualisation.libvirtd.enable = true;
  virtualisation.docker.enable = true;
  services.cockpit.enable = true;
  services.packagekit.enable = true;
  programs.steam.enable = true;

  security.sudo.package = pkgs.sudo.override { withInsults = true; };
  services.openssh.enable = true;
  services.openssh.allowSFTP = true;
  services.transmission.enable = true;
  services.transmission.openPeerPorts = true;
  services.transmission.settings.download-dir = "${config.services.transmission.home}/downloads";
  services.transmission.settings.incomplete-dir = "${config.services.transmission.home}/.incomplete";
  services.transmission.settings.watch-dir = "${config.services.transmission.home}/torrents";
  services.transmission.settings.watch-dir-enabled = true;

  environment.systemPackages = with pkgs; [
    pinentry
    vim-full
    lutris
    libsForQt5.qt5.qtgraphicaleffects
    libsForQt5.plasma-framework
    wget
    git
    python311
  ];

  users.users.virtuoso = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "virtuoso";
    shell = pkgs.nushell;
  };

  system.stateVersion = "23.11";
}
