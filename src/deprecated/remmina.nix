{
  self.lib.deprecated.homeModules.remmina =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      hardware = config.dot.hardware;
    in
    lib.mkIf hardware.browser {
      home.packages = [
        pkgs.remmina
      ];
    };
}
