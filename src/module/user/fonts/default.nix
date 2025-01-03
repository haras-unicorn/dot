{ lib, pkgs, config, ... }:

let
  mkFontOption = type: name: package: {
    name = lib.mkOption {
      type = lib.types.str;
      default = name;
      example = name;
    };
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.${package};
      example = pkgs.${package};
    };
  };

  hasMonitor = config.dot.hardware.monitor.enable;
in
{
  options.font = {
    nerd = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "JetBrainsMono Nerd Font";
        example = "JetBrainsMono Nerd Font";
      };
      label = lib.mkOption {
        type = lib.types.str;
        default = "JetBrainsMono";
        example = "JetBrainsMono";
      };
    };
    mono = mkFontOption "mono" "Roboto Mono" "roboto-mono";
    slab = mkFontOption "slab" "Roboto Slab" "roboto-slab";
    sans = mkFontOption "sans" "Roboto" "roboto";
    serif = mkFontOption "serif" "Roboto Serif" "roboto-serif";
    script = mkFontOption "script" "Eunomia" "dotcolon-fonts";
    emoji = mkFontOption "emoji" "Noto Color Emoji" "noto-fonts-emoji";
    extra = lib.mkOption {
      type = with lib.types; listOf package;
      default = [ ];
    };
    size = {
      small = lib.mkOption {
        type = lib.types.int;
        default = 12;
        example = 12;
      };
      medium = lib.mkOption {
        type = lib.types.int;
        default = 13;
        example = 13;
      };
      large = lib.mkOption {
        type = lib.types.int;
        default = 16;
        example = 16;
      };
    };
  };

  system = lib.mkIf hasMonitor {
    fonts.fontDir.enable = true;
    fonts.packages = [
      (pkgs.nerdfonts.override { fonts = [ config.dot.font.nerd.label ]; })
      config.dot.font.mono.package
      config.dot.font.slab.package
      config.dot.font.sans.package
      config.dot.font.serif.package
      config.dot.font.script.package
      config.dot.font.emoji.package
    ] ++ config.dot.font.extra;
    fonts.enableDefaultPackages = true;
    fonts.enableGhostscriptFonts = true;
  };

  home = lib.mkIf hasMonitor {
    fonts.fontconfig.enable = true;
    fonts.fontconfig.defaultFonts.sansSerif = [ config.dot.font.sans.name ];
    fonts.fontconfig.defaultFonts.serif = [ config.dot.font.serif.name ];
    fonts.fontconfig.defaultFonts.emoji = [ config.dot.font.emoji.name ];
    fonts.fontconfig.defaultFonts.monospace = [ config.dot.font.mono.name ];
    home.packages = [
      pkgs.fontfor
      pkgs.fontpreview
    ];
  };
}
