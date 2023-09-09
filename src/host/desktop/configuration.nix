{ self, pkgs, ... }:

{
  imports = [
    "${self}/src/module/system/grub/grub.nix"
    "${self}/src/module/system/plymouth/plymouth.nix"
    "${self}/src/module/system/location/location.nix"
    "${self}/src/module/system/network/network.nix"
    "${self}/src/module/system/pipewire/pipewire.nix"
    "${self}/src/module/system/xserver/xserver.nix"
    "${self}/src/module/system/fonts/fonts.nix"
    "${self}/src/module/system/sudo/sudo.nix"
    "${self}/src/module/system/virtual/virtual.nix"
    "${self}/src/module/system/windows/windows.nix"
  ];

  boot.kernelPackages = pkgs.linuxPackages_zen;
  services.ananicy.enable = true;
  services.earlyoom.enable = true;

  # TODO
  services.transmission.enable = true;
  services.transmission.openPeerPorts = true;

  programs.ssh.startAgent = true;
  services.openssh.enable = true;
  services.openssh.allowSFTP = true;
  security.pam.enableSSHAgentAuth = true;

  environment.systemPackages = with pkgs; [
    helix
    git
  ];
}
