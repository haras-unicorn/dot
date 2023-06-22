{ config
, pkgs
, sweet-theme
, ...
}:

{
  nix.package = pkgs.nixFlakes;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

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
  programs.dconf.enable = true;
  services.xserver.enable = true;
  services.xserver.layout = "us";
  services.xserver.libinput.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.displayManager.sddm.autoNumlock = true;
  services.xserver.displayManager.sddm.theme = "${sweet-theme}/kde/sddm";
  services.xserver.displayManager.defaultSession = "xfce+qtile";
  services.xserver.desktopManager.xfce.enable = true;
  services.xserver.desktopManager.xfce.noDesktop = true;
  services.xserver.desktopManager.xfce.enableScreensaver = false;
  services.xserver.desktopManager.xfce.enableXfwm = false;
  services.xserver.windowManager.qtile.enable = true;
  services.xserver.windowManager.qtile.extraPackages =
    python3Packages: with python3Packages; [
      psutil
    ];

  fonts.fonts = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];
  fonts.fontDir.enable = true;
  fonts.enableDefaultFonts = true;

  services.pipewire.enable = true;
  services.pipewire.wireplumber.enable = true;
  services.pipewire.alsa.enable = true;
  services.pipewire.jack.enable = true;
  services.pipewire.pulse.enable = true;

  services.qemuGuest.enable = true;
  virtualisation.libvirtd.enable = true;
  virtualisation.libvirtd.qemu.ovmf.enable = true;
  virtualisation.libvirtd.qemu.ovmf.packages = [
    (pkgs.OVMF.override {
      secureBoot = true;
      tpmSupport = true;
    }).fd
  ];
  virtualisation.libvirtd.qemu.swtpm.enable = true;
  virtualisation.docker.enable = true;
  services.cockpit.enable = true;
  services.packagekit.enable = true;
  programs.steam.enable = true;

  services.gnome.gnome-keyring.enable = true;
  security.pam.services.sddm.enableGnomeKeyring = true;
  programs.seahorse.enable = true;
  security.sudo.package = pkgs.sudo.override { withInsults = true; };
  programs.ssh.startAgent = true;
  services.openssh.enable = true;
  services.openssh.allowSFTP = true;
  security.pam.enableSSHAgentAuth = true;
  services.transmission.enable = true;
  services.transmission.openPeerPorts = true;
  # FIX: Failed to set up mount namespacing
  # services.transmission.settings.download-dir = "${config.services.transmission.home}/downloads";
  # services.transmission.settings.incomplete-dir = "${config.services.transmission.home}/.incomplete";
  # services.transmission.settings.watch-dir = "${config.services.transmission.home}/torrents";
  # services.transmission.settings.watch-dir-enabled = true;

  environment.systemPackages = with pkgs; [
    vim-full
    git
    pinentry
    wineWowPackages.stable
    lutris
    virt-manager
    spice
    libsForQt5.qt5.qtgraphicaleffects
    libsForQt5.plasma-framework
    libsecret
  ];

  users.users.virtuoso = {
    isNormalUser = true;
    extraGroups = [ "wheel" "libvirtd" "docker" ];
    initialPassword = "virtuoso";
    shell = pkgs.nushell;
  };

  system.stateVersion = "23.11";
}
