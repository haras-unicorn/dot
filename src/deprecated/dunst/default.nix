{
  self.lib.deprecated.homeModules.dunst =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      hardware = config.dot.hardware;
    in
    lib.mkIf (hardware.graphics && !hardware.wayland) {
      services.dunst.enable = true;
      services.dunst.configFile = ./dunstrc;
    };
}
