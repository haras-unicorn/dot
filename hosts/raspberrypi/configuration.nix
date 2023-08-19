{ pkgs, ... }:

{
  imports = [
    <nixpkgs/nixos/modules/installer/sd-card/sd-image-raspberrypi.nix>
  ];

  users.users.pi.isNormalUser = true;
  users.users.pi.initialPassword = "pi";
  users.users.pi.shell = pkgs.nushell;

  sdImage.compressImage = false;
  services.openssh.enabl = true;

  environment.systemPackages = with pkgs; [
    vim-full
    git
    man-pages
    man-pages-posix
  ];

  system.stateVersion = "23.11";
}
