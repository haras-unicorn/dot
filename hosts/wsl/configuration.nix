{ pkgs, ... }:

{
  nix.package = pkgs.nixFlakes;
  nix.extraOptions = "experimental-features = nix-command flakes";
  nixpkgs.config = import ../../assets/.config/nixpkgs/config.nix;

  environment.systemPackages = with pkgs; [
    vim-full
    git
    man-pages
    man-pages-posix
  ];

  users.users.nixos.shell = pkgs.nushell;

  system.stateVersion = "23.11";
}
