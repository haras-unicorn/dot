{
  self.homeModules.pinta.value =
    {
      osConfig,
      lib,
      pkgs,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;

      package = pkgs.pinta;
    in
    lib.mkIf hardware.browser {
      home.packages = [
        package
      ];
    };
}
