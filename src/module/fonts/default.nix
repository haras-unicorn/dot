{ lib, pkgs, config, ... }:

# FIXME: fontfor not compiling

with lib;
let
  mkFontOption = type: name: pkg: {
    name = mkOption {
      type = with types; str;
      default = name;
      example = name;
    };
    pkg = mkOption {
      type = with types; str;
      default = pkg;
      example = pkg;
    };
  };
in
{
  options.dot.font = {
    nerd = mkFontOption "nerd" "JetBrainsMono Nerd Font" "JetBrainsMono";
    mono = mkFontOption "mono" "Roboto Mono" "roboto-mono";
    slab = mkFontOption "slab" "Roboto Slab" "roboto-slab";
    sans = mkFontOption "sans" "Roboto" "roboto";
    serif = mkFontOption "serif" "Roboto Serif" "roboto-serif";
    script = mkFontOption "script" "Eunomia" "dotcolon-fonts";
    emoji = mkFontOption "emoji" "Noto Color Emoji" "noto-fonts-emoji";
    extra = mkOption {
      type = with types; listOf str;
      default = [ ];

    };
    size = {
      small = mkOption {
        type = with types; int;
        default = 12;
        example = 12;
      };
      medium = mkOption {
        type = with types; int;
        default = 13;
        example = 13;
      };
      large = mkOption {
        type = with types; int;
        default = 16;
        example = 16;
      };
    };
  };

  system = {
    fonts.fontDir.enable = true;
    fonts.packages = [
      (pkgs.nerdfonts.override { fonts = [ config.dot.font.nerd.pkg ]; })
      pkgs."${config.dot.font.mono.pkg}"
      pkgs."${config.dot.font.slab.pkg}"
      pkgs."${config.dot.font.sans.pkg}"
      pkgs."${config.dot.font.serif.pkg}"
      pkgs."${config.dot.font.script.pkg}"
      pkgs."${config.dot.font.emoji.pkg}"
    ] ++ builtins.map (pkg: pkgs."${pkg}") config.dot.font.extra;
    fonts.enableDefaultPackages = true;
    fonts.enableGhostscriptFonts = true;

    fonts.fontconfig.enable = true;
    fonts.fontconfig.defaultFonts.sansSerif = [ config.dot.font.sans.name ];
    fonts.fontconfig.defaultFonts.serif = [ config.dot.font.serif.name ];
    fonts.fontconfig.defaultFonts.emoji = [ config.dot.font.emoji.name ];
    fonts.fontconfig.defaultFonts.monospace = [ config.dot.font.mono.name ];

    environment.systemPackages = with pkgs; [
      # fontfor
      fontpreview
    ];
  };
}
