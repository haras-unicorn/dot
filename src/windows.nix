{
  pkgs,
  lib,
  config,
  ...
}:

let
  isRpi4 = config.dot.hardware.rpi."4".enable;
in
{
  branch.nixosModule.nixosModule = lib.mkIf (!isRpi4) {
    environment.systemPackages = with pkgs; [
      ntfs3g
      woeusb
    ];
  };
}
