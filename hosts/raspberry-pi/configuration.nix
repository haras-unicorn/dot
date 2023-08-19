{ pkgs, ... }:

{
  nix.package = pkgs.nixFlakes;
  nix.extraOptions = "experimental-features = nix-command flakes";
  nixpkgs.config = import ../../assets/.config/nixpkgs/config.nix;

  services.openssh.enable = true;

  environment.systemPackages = with pkgs; [
    libraspberrypi
    raspberrypi-eeprom
    vim-full
    git
    man-pages
    man-pages-posix
  ];

  users.users.pi.isNormalUser = true;
  users.users.pi.initialPassword = "pi";
  users.users.pi.shell = pkgs.nushell;

  system.stateVersion = "23.11";
}
