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
  branch.nixosModule.nixosModule = lib.mkIf (hasMouse || hasKeyboard) {
    services.libinput.enable = true;

    environment.systemPackages = [ pkgs.libinput ];
  };
}
