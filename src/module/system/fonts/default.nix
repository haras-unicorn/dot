{ pkgs, config, ... }:

# FIXME: fontfor not compiling

{
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
