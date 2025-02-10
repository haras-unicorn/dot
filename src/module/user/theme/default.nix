{ stylix, config, pkgs, lib, system, ... }:

# TODO: https://github.com/danth/stylix/pull/847

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

  wallpaper = pkgs.runCommand "wallpaper-image"
    {
      buildInputs = [ pkgs.file pkgs.ffmpeg pkgs.imagemagick_light ];
    }
    ''
      mkdir $out
      prev="${config.dot.wallpaper}"
      if file --mime-type "$prev" | grep -qE 'video/'; then
        ffmpeg -i "$prev" -vf "select=eq(n\,0)" -vsync vfr -q:v 2 "$out/image.png"
      else
        magick convert "$prev" "$out/image.png"
      fi
    '';
in
{
  home = lib.mkIf hasMonitor {
    home.packages = [
      inspect-gtk
      stylix.packages.${system}.palette-generator
    ];

    stylix.enable = true;
    stylix.image = "${wallpaper}/image.png";
    stylix.imageScalingMode = "fill";
    stylix.polarity = "dark";
    stylix.fonts.monospace.name = "JetBrainsMono Nerd Font";
    stylix.fonts.monospace.package = config.unstablePkgs.nerd-fonts.jetbrains-mono;
    stylix.cursor.package = pkgs.pokemon-cursor;
    stylix.cursor.name = "Pokemon";
    stylix.iconTheme.enable = true;
    stylix.iconTheme.package = pkgs.beauty-line-icon-theme;
    stylix.iconTheme.dark = "BeautyLine";
    stylix.iconTheme.light = "BeautyLine";
    stylix.opacity.applications = 0.9;
    stylix.opacity.desktop = 0.0;
    stylix.opacity.terminal = 0.75;
    stylix.opacity.popups = 1.0;
  };
}

