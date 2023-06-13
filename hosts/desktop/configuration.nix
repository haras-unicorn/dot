{ pkgs, ... }:

{
  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.efiSupport = true;

  location.provider = "geoclue2";
  time.timeZone = "Europe/Zagreb";
  i18n.defaultLocale = "en_US.UTF-8";
  console.useXkbConfig = true;

  services.ananicy.enable = true;
  services.earlyoom.enable = true;
  security.rtkit.enable = true;

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
  programs.dconf.enable = true;
  services.gvfs.enable = true;

  services.pipewire.enable = true;
  services.pipewire.wireplumber.enable = true;
  services.pipewire.alsa.enable = true;
  services.pipewire.jack.enable = true;
  services.pipewire.pulse.enable = true;

  services.qemuGuest.enable = true;
  virtualisation.libvirtd.enable = true;
  virtualisation.docker.enable = true;
  services.cockpit.enable = true;

  programs.gnupg.agent.enable = true;
  programs.gnupg.agent.enableSSHSupport = true;
  services.openssh.enable = true;
  services.openssh.allowSFTP = true;
  services.gnome.gnome-keyring.enable = true;
  programs.seahorse.enable = true;

  users.users.virtuoso = {
    isNormalUser = true;
    extraGroups = [ "wheel" "libvirtd" "docker" ];
    initialPassword = "virtuoso";
    shell = pkgs.nushell;
  };
  security.pam.services.virtuoso.enableGnomeKeyring = true;

  environment.systemPackages = with pkgs; [
    vim-full
    git
    dunst
    rofi
    flameshot
    networkmanagerapplet
    xclip
    xorg.xkill
    lxde.lxsession
    lxde.lxtask
    lxde.lxrandr
    pcmanfm
    xarchiver
  ];

  system.stateVersion = "23.11";
}
