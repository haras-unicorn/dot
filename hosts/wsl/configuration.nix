{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    vim-full
    git
    openssl
    man-pages
    man-pages-posix
  ];

  system.stateVersion = "23.11";
}
