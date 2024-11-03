{ pkgs, config, ... }:

{
  shared = {
    dot = {
      desktopEnvironment.sessionStartup = [
        "${pkgs.swww}/bin/swww-daemon"
        "${pkgs.swww}/bin/swww $VERBOSE_ARG img ${builtins.toPath config.dot.wallpaper}"
      ];
    };
  };

  home = {
    home.packages = with pkgs; [
      swww
    ];
  };
}
