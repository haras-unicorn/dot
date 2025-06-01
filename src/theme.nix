{ self, stylix, config, pkgs, unstablePkgs, ... }:

# TODO: https://github.com/danth/stylix/pull/847

let
  wallpaperImage = config.dot.wallpaper.image;
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
  branch.homeManagerModule.homeManagerModule = {
    home.packages = [
      inspect-gtk
      stylix.packages.${pkgs.system}.palette-generator
    ];

    stylix.enable = true;
    stylix.image = wallpaperImage;
    stylix.imageScalingMode = "fill";
    stylix.polarity = "dark";
    stylix.base16Scheme = builtins.fromJSON
      (builtins.readFile "${self}/assets/wallpaper.json");
    stylix.fonts.monospace.name = "JetBrainsMono Nerd Font";
    stylix.fonts.monospace.package = unstablePkgs.nerd-fonts.jetbrains-mono;
    stylix.fonts.sansSerif.name = "Roboto";
    stylix.fonts.sansSerif.package = pkgs.roboto;
    stylix.fonts.serif.name = "Roboto Serif";
    stylix.fonts.serif.package = pkgs.roboto-serif;
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

