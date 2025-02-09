{ pkgs, lib, config, ... }:

let
  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;
in
{
  config = lib.mkIf (hasMonitor && hasWayland) {
    desktopEnvironment.sessionStartup = [ "${pkgs.mako}/bin/mako" ];
  };

  home = lib.mkIf (hasMonitor && hasWayland) {
    home.packages = [
      pkgs.libnotify
      pkgs.mako
    ];

    xdg.configFile."mako/config".text = ''
      font="${config.dot.font.sans.name}" ${builtins.toString config.dot.font.size.large}
      width=512
      height=256

      margin=0,0,32,32
      padding=8
      border-size=2
      border-radius=4
      icons=1
      max-icon-size=128
      default-timeout=10000
      anchor=bottom-right
    '';


    home.activation = {
      makoReloadAction = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${pkgs.mako}/bin/makoctl reload
      '';
    };
  };
}
