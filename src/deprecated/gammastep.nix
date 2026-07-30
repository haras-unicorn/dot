{
  self.lib.deprecated.homeModules.gammastep =
    { osConfig, lib, ... }:
    let
      hardware = osConfig.dot.hardware;
    in
    lib.mkIf (hardware.graphics && hardware.wayland) {
      services.gammastep.enable = true;
      services.gammastep.provider = "geoclue2";
      services.gammastep.tray = true;
    };
}
