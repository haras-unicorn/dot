{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    vim-full
    git
    openssl
  ];
}
