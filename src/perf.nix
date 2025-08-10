{ pkgs, config, ... }:

# TODO: laptop battery saving

let
  isRpi4 = config.dot.hardware.rpi."4".enable;
in
{
  branch.nixosModule.nixosModule = {
    services.ananicy.enable = !isRpi4;
    services.ananicy.package = pkgs.ananicy-cpp;
  };
}
