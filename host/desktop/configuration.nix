{ config, pkgs, sweet-theme, ... }:

{
  imports = [
    ../../module/plymouth/plymouth.nix
    ../../module/pipewire/pipewire.nix
  ];

  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.useOSProber = true;

  boot.kernelPackages = pkgs.linuxPackages_zen;
  services.ananicy.enable = true;
  services.earlyoom.enable = true;

  security.rtkit.enable = true;

  location.provider = "geoclue2";
  time.timeZone = "Europe/Zagreb";
  i18n.defaultLocale = "en_US.UTF-8";

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
  console.useXkbConfig = true;

  fonts.fonts = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];
  fonts.fontDir.enable = true;
  fonts.enableDefaultFonts = true;

  services.qemuGuest.enable = true;
  virtualisation.libvirtd.enable = true;
  virtualisation.libvirtd.qemu.package = pkgs.qemu_kvm;
  virtualisation.libvirtd.qemu.ovmf.enable = true;
  virtualisation.libvirtd.qemu.ovmf.packages = [ pkgs.OVMFFull.fd ];
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

  environment.systemPackages = with pkgs; [
    vim-full
    git
    pinentry
    wineWowPackages.stable
    lutris
    virt-manager
    spice
    spice-vdagent
    virglrenderer
    win-virtio
    win-spice
    libsForQt5.qt5.qtgraphicaleffects
    libsForQt5.plasma-framework
    libsecret
  ];

  environment.etc = {
    "ovmf/edk2-x86_64-secure-code.fd" = {
      source = config.virtualisation.libvirtd.qemu.package + "/share/qemu/edk2-x86_64-secure-code.fd";
    };

    "ovmf/edk2-i386-vars.fd" = {
      source = config.virtualisation.libvirtd.qemu.package + "/share/qemu/edk2-i386-vars.fd";
    };
  };
}
