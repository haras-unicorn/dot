{ inputs, ... }:

{
  machines.nixosModules.septabee =
    { config, lib, ... }:
    let
      hardware = config.dot.hardware;
    in
    {
      imports = [
        inputs.septabee.nixosModules.default
      ];

      config = lib.mkIf hardware.gaming {
        programs.septabee = {
          enable = true;
          wayland-deps = hardware.wayland;
        };
      };
    };
}
