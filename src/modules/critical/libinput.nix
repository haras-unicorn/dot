{
  machines.nixosModules.libinput =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      hardware = config.dot.hardware;
    in
    {
      config = lib.mkIf (hardware.pointing || hardware.typing) {
        services.libinput.enable = true;

        environment.systemPackages = [ pkgs.libinput ];
      };
    };
}
