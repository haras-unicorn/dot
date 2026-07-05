{
  self.lib.deprecated.homeModules.betterlockscreen =
    {
      pkgs,
      lib,
      config,
      osConfig,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;
    in
    lib.mkIf (hardware.visual && !hardware.wayland) {
      dot.desktop.sessionStartup = [
        "${pkgs.betterlockscreen}/bin/betterlockscreen --update '${config.stylix.image}'"
      ];

      services.betterlockscreen.enable = true;
    };
}
