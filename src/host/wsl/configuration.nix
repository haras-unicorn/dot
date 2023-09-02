{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    vim-full
    git
    openssl
    man-pages
    man-pages-posix
  ];
}
