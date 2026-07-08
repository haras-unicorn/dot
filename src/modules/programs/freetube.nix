{
  machines.homeModules.freetube =
    { osConfig, lib, ... }:
    let
      hardware = osConfig.dot.hardware;
    in
    lib.mkIf hardware.browser {
      programs.freetube = {
        enable = true;
        settings = {
          checkForUpdates = false;
        };
      };
    };
}
