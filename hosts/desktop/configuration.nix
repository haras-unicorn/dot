{ pkgs, ... }:

{
  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.useOSProber = true;
  boot.initrd.systemd.enable = true;
  boot.kernelParams = [
    "quiet"
    # "splash"
    # "vt.global_cursor_default=0"
    # "vga=current"
    # "loglevel=3"
    # "rd.systemd.show_status=auto"
    # "rd.udev.log_level=3"
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
  networking.firewall.package = pkgs.nftables;
  networking.networkmanager.enable = true;

  services.picom.enable = true;
  services.xserver.enable = true;
  services.xserver.layout = "us";
  services.xserver.libinput.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.displayManager.sddm.autoNumlock = true;
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
  programs.steam.enable = true;
  environment.systemPackages = with pkgs; [
    lutris
  ];

  services.openssh.enable = true;
  services.openssh.allowSFTP = true;

  users.users.virtuoso = {
    isNormalUser = true;
    extraGroups = [ "wheel" "libvirtd" "docker" ];
    initialPassword = "virtuoso";
    shell = pkgs.nushell;
  };
  security.pam.services.virtuoso.enableGnomeKeyring = true;

  system.stateVersion = "23.11";
}
