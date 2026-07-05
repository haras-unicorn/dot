{
  self.lib.deprecated.nixosModules.xserver =
    {
      lib,
      config,
      ...
    }:
    let
      hardware = config.dot.hardware;
    in
    lib.mkIf (hardware.graphics && !hardware.wayland) {
      services.xserver.enable = true;
    };

  self.lib.deprecated.homeModules.xserver =
    {
      lib,
      osConfig,
      pkgs,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;
    in
    lib.mkIf (hardware.graphics && !hardware.wayland) {
      dot.desktop.sessionVariables = {
        QT_QPA_PLATFORM = "xcb";
      };

      home.packages = [
        pkgs.libsForQt5.qt5ct
        pkgs.xclip
        pkgs.libnotify
      ];
    };
}
