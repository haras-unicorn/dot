{
  flake.nixosModules.services-xserver =
    {
      lib,
      config,
      ...
    }:
    let
      hasMonitor = config.dot.hardware.monitor.enable;
      hasWayland = config.dot.hardware.graphics.wayland;
    in
    lib.mkIf (hasMonitor && !hasWayland) {
      services.xserver.enable = true;
    };

  flake.homeModules.services-xserver =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      hasMonitor = config.dot.hardware.monitor.enable;
      hasWayland = config.dot.hardware.graphics.wayland;
    in
    lib.mkIf (hasMonitor && !hasWayland) {
      dot.desktopEnvironment.sessionVariables = {
        QT_QPA_PLATFORM = "xcb";
      };

      home.packages = [
        pkgs.libsForQt5.qt5ct
        pkgs.xclip
        pkgs.libnotify
      ];
    };
}
