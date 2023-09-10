{ pkgs, ... }:

{
  home.pacakges = with pkgs; [
    libnotify
  ];

  services.mako.enable = true;
  services.mako.extraConfig = builtins.readFile ./config;
}
