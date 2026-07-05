{ inputs, ... }:

{
  machines.nixosModules.stylix =
    {
      config,
      pkgs,
      ...
    }:
    {
      stylix.enable = true;
      stylix.image = config.dot.wallpaper.image;
      stylix.imageScalingMode = "fill";
      stylix.polarity = "dark";
      stylix.base16Scheme = builtins.fromJSON (builtins.readFile config.dot.wallpaper.scheme);
      stylix.fonts.monospace.name = "JetBrainsMono Nerd Font";
      stylix.fonts.monospace.package = pkgs.nerd-fonts.jetbrains-mono;
      stylix.fonts.sansSerif.name = "Roboto";
      stylix.fonts.sansSerif.package = pkgs.roboto;
      stylix.fonts.serif.name = "Roboto Serif";
      stylix.fonts.serif.package = pkgs.roboto-serif;
      stylix.cursor.package = pkgs.pokemon-cursor;
      stylix.cursor.name = "Pokemon";
      stylix.cursor.size = 24;
      stylix.opacity.applications = 0.9;
      stylix.opacity.desktop = 0.0;
      stylix.opacity.terminal = 0.75;
      stylix.opacity.popups = 1.0;
    };

  machines.homeModules.desktop-stylix =
    {
      config,
      pkgs,
      ...
    }:
    let
      inspect-gtk = pkgs.writeShellApplication {
        name = "inspect-gtk";
        text = ''
          export GTK_DEBUG=interactive
          exec "$@"
        '';
      };

      inspect-qt = pkgs.writeShellApplication {
        name = "inspect-qt";
        runtimeInputs = [
          pkgs.gammaray
        ];
        text = ''
          exec gammaray "$@"
        '';
      };
    in
    {
      home.packages = [
        inspect-gtk
        inspect-qt
        inputs.stylix.packages.${pkgs.stdenv.hostPlatform.system}.palette-generator
      ];

      stylix.icons.enable = true;
      stylix.icons.package = pkgs.beauty-line-icon-theme;
      stylix.icons.dark = "BeautyLine";
      stylix.icons.light = "BeautyLine";
    };
}
