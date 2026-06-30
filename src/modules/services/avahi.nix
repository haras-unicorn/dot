{
  machines.nixosModules.avahi =
    {
      config,
      lib,
      ...
    }:
    let
      hardware = config.dot.hardware;
    in
    lib.mkIf hardware.network {
      services.avahi.enable = true;
    };
}
