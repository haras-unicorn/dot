{
  self.lib.deprecated.homeModules.lutris =
    {
      pkgs,
      config,
      lib,
      osConfig,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;
    in
    lib.mkIf hardware.gaming {
      programs.lutris.enable = true;
      programs.lutris.defaultWinePackage = pkgs.proton-ge-bin;
    };
}
