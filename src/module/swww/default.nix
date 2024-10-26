{ pkgs, lib, config, ... }:

{
  home.shared = {
    home.packages = with pkgs; [
      swww
    ];

    home.activation = {
      swwwDaemonAction = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        "${pkgs.swww}/bin/swww-daemon"
      '';
      swwwImgAction = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${pkgs.swww}/bin/swww $VERBOSE_ARG img ${builtins.toPath config.dot.wallpaper}
      '';
    };
  };
}
