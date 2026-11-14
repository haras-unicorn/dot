{ inputs, ... }:

{
  self.nixosModules.stolon.value =
    { config, ... }:
    let
      hardware = config.dot.hardware;
    in
    {
      imports = [ inputs.stolon.nixosModules.default ];

      stolon.enable = true;
      stolon.device = hardware.disk;
      stolon.gc.retentionDays = 30;
    };
}
