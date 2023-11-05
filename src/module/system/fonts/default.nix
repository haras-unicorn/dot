{ pkgs, config, ... }:

{
  fonts.fontDir.enable = true;
  fonts.packages = [
    pkgs."${config.dot.font.sans.pkg}"
    pkgs."${config.dot.font.serif.pkg}"
    pkgs."${config.dot.font.emoji.pkg}"
    (pkgs.nerdfonts.override { fonts = [ config.dot.font.nerd.pkg ]; })
  ];
  fonts.enableDefaultPackages = true;
  fonts.enableGhostscriptFonts = true;

  fonts.fontconfig.enable = true;
  fonts.fontconfig.defaultFonts.sansSerif = [ config.dot.font.sans.name ];
  fonts.fontconfig.defaultFonts.serif = [ config.dot.font.serif.name ];
  fonts.fontconfig.defaultFonts.emoji = [ config.dot.font.emoji.name ];
  fonts.fontconfig.defaultFonts.monospace = [ config.dot.font.nerd.name ];
}
