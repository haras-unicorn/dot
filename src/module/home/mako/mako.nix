{ pkgs, ... }:

{
  home.packages = with pkgs; [
    libnotify
  ];

  services.mako.enable = true;
  services.mako.extraConfig = builtins.readFile ./config;
}
