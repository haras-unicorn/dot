{
  self.homeModules.losslesscut.value =
    {
      osConfig,
      lib,
      pkgs,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;

      package = pkgs.losslesscut;
    in
    lib.mkIf hardware.browser {
      home.packages = [
        package
      ];
    };
}
