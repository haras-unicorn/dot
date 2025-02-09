{ pkgs, lib, config, ... }:

let
  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;
in
{
  home = lib.mkIf (hasMonitor && hasWayland) {
    services.mako.enable = true;
    services.mako.extraConfig = ''
      width=512
      height=256
      outer-margin=32
      margin=8
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
