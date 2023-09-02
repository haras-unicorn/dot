{ pkgs, ... }:

{
  home.packages = with pkgs; [
    qtile
  ];

  xdg.configFile."qtile/config.py".source = ./config.py;
}
