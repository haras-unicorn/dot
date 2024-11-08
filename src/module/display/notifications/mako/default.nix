{ pkgs, lib, config, ... }:

let
  bootstrap = config.dot.colors.bootstrap;

  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;
in
{
  shared = lib.mkIf (hasMonitor && hasWayland) {
    dot = {
      desktopEnvironment.sessionStartup = [ "${pkgs.mako}/bin/mako" ];
    };
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

      margin=32
      padding=8
      border-size=2
      border-radius=4
      icons=1
      max-icon-size=128
      default-timeout=10000
      anchor=bottom-right

      background-color=${bootstrap.background.normal.makoa "AA"}
      text-color=${bootstrap.text.normal.mako}
      border-color=${bootstrap.accent.normal.mako}
      progress-color=${bootstrap.success.normal.mako}
    '';


    home.activation = {
      makoReloadAction = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${pkgs.mako}/bin/makoctl reload
      '';
    };
  };
}
