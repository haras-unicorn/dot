{
  self.homeModules.tenacity.value =
    {
      osConfig,
      lib,
      pkgs,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;

      package = pkgs.tenacity;
    in
    lib.mkIf hardware.browser {
      home.packages = [
        package
      ];
    };
}
