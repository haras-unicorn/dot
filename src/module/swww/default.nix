{ pkgs, lib, config, ... }:

{
  shared = {
    dot = {
      desktopEnvironment.sessionStartup = [
        "${pkgs.swww}/bin/swww-daemon"
      ];
    };
  };

  home.shared = {
    home.packages = with pkgs; [
      swww
    ];

    home.activation = {
      swwwImgAction = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run swww $VERBOSE_ARG img ${builtins.toPath config.dot.wallpaper}
      '';
    };
  };
}
