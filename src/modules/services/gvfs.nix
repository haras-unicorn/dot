{
  machines.nixosModules.gvfs =
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
