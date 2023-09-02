{ pkgs, username, ... }:

{
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.efiSupport = true;

  location.provider = "geoclue2";
  i18n.defaultLocale = "en_US.UTF-8";
  console.useXkbConfig = true;

  services.ananicy.enable = true;
  services.earlyoom.enable = true;
  # fix no realtime group ?
  security.rtkit.enable = true;

  networking.hostName = "virtuoso";
  networking.nftables.enable = true;
  networking.firewall.package = pkgs.nftables;
  networking.networkmanager.enable = true;

  services.xserver.enable = true;
  services.xserver.layout = "us";
  services.xserver.libinput.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.windowManager.qtile.enable = true;

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

  users.users.virtuoso."${username}".extraGroups = [ "wheel" "libvirtd" "docker" ];

  security.pam.services.virtuoso.enableGnomeKeyring = true;

  environment.systemPackages = with pkgs; [
    vim
    git
    nushell

    dunst
    rofi
    flameshot
    lxde.lxtask
    lxde.lxrandr
    kitty
    brave
  ];
  system.stateVersion = "23.11";
}
