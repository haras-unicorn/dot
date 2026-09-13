{
  self.nixosModules.avahi.value =
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
