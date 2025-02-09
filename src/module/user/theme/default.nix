{ config, pkgs, lib, ... }:

let
  hasMonitor = config.dot.hardware.monitor.enable;

  inspect-gtk = pkgs.writeShellApplication {
    name = "inspect-gtk";
    runtimeInputs = [ ];
    text = ''
      export GTK_DEBUG=interactive
      exec "$@"
    '';
  };
in
{
  home = lib.mkIf hasMonitor {
    home.packages = [
      inspect-gtk
    ];

    stylix.enable = true;
    stylix.image = config.dot.wallpaper;
    stylix.polarity = "dark";
    stylix.fonts.monospace.name = "JetBrainsMono Nerd Font";
    stylix.fonts.monospace.package = config.unstablePkgs.nerd-fonts.jetbrains-mono;
    stylix.cursor.package = pkgs.pokemon-cursor;
    stylix.cursor.name = "Pokemon";
    stylix.iconTheme.enable = true;
    stylix.icontheme.package = pkgs.beauty-line-icon-theme;
    stylix.iconTheme.dark = "BeautyLine";
    stylix.iconTheme.light = "BeautyLine";
  };
}

