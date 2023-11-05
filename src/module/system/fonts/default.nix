{ pkgs, config, ... }:

{
  fonts.fontDir.enable = true;
  fonts.fontconfig.enable = true;

  fonts.packages = [
    pkgs."${config.dot.font.sans.pkg}"
    pkgs."${config.dot.font.serif.pkg}"
    pkgs."${config.dot.font.emoji.pkg}"
    (pkgs.nerdfonts.override { fonts = [ config.dot.font.nerd.pkg ]; })
  ];
  fonts.enableDefaultPackages = true;
  fonts.enableGhostscriptFonts = true;

  fonts.defaultFonts.sansSerif = [ config.dot.font.sans.name ];
  fonts.defaultFonts.serif = [ config.dot.font.serif.name ];
  fonts.defaultFonts.emoji = [ config.dot.font.emoji.name ];
  fonts.defaultFonts.monospace = [ config.dot.font.nerd.name ];
}
