{ pkgs, username, ... }:

{
  nix.package = pkgs.nixFlakes;
  nix.extraOptions = "experimental-features = nix-command flakes";
  nixpkgs.config = import ../../assets/.config/nixpkgs/config.nix;

  environment.systemPackages = with pkgs; [
    vim-full
    git
    openssl
    man-pages
    man-pages-posix
  ];

  system.stateVersion = "23.11";
}
