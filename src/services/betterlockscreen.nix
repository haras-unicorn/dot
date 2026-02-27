# FIXME: lockscreen on xserver
{
  flake.homeModules.services-betterlockscreen =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      hasMonitor = config.dot.hardware.monitor.enable;
      hasWayland = config.dot.hardware.graphics.wayland;
      hasKeyboard = config.dot.hardware.keyboard.enable;
    in
    lib.mkIf (hasMonitor && hasKeyboard && !hasWayland) {
      dot.desktopEnvironment.sessionStartup = [
        "${pkgs.betterlockscreen}/bin/betterlockscreen --update '${config.stylix.image}'"
      ];

      services.betterlockscreen.enable = true;
    };
}
