{ pkgs, ... }:

{
  imports = [
    ../../module/system/grub/grub.nix
    ../../module/system/plymouth/plymouth.nix
    ../../module/system/location/location.nix
    ../../module/system/networking/networking.nix
    ../../module/system/pipewire/pipewire.nix
    ../../module/system/xserver/xserver.nix
    ../../module/system/fonts/fonts.nix
    ../../module/system/sudo/sudo.nix
  ];

  boot.kernelPackages = pkgs.linuxPackages_zen;
  services.ananicy.enable = true;
  services.earlyoom.enable = true;

  services.transmission.enable = true;
  services.transmission.openPeerPorts = true;

  programs.ssh.startAgent = true;
  services.openssh.enable = true;
  services.openssh.allowSFTP = true;
  security.pam.enableSSHAgentAuth = true;

  environment.systemPackages = with pkgs; [
    vim-full
    git
    pinentry
  ];
}
