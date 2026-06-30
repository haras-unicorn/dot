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
    lib.mkIf hardware.interface {
      home.packages = [
        pkgs.remmina
      ];
    };
}
