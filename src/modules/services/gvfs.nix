{
  self.nixosModules.gvfs.value =
    {
      lib,
      config,
      ...
    }:
    let
      hardware = config.dot.hardware;
    in
    lib.mkIf hardware.graphics {
      services.gvfs.enable = true;
    };
}
