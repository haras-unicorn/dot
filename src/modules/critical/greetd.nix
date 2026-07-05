{
  machines.nixosModules.greetd =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.dot.desktop;

      hardware = config.dot.hardware;
    in
    lib.mkIf (hardware.visual && hardware.wayland) {
      services.greetd.enable = true;
      services.greetd.settings = {
        default_session = {
          command = cfg.login;
        };
      };
    };
}
