{
  flake.nixosModules.services-libinput =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      hasMouse = config.dot.hardware.mouse.enable;
      hasKeyboard = config.dot.hardware.keyboard.enable;
    in
    {
      config = lib.mkIf (hasMouse || hasKeyboard) {
        services.libinput.enable = true;

        environment.systemPackages = [ pkgs.libinput ];
      };
    };
}
