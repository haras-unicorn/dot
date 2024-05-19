{ pkgs, ... }:

{
  system = {
    hardware.i2c.enable = true;
  };

  home.shared = {
    home.packages = with pkgs; [
      ddccontrol
      ddccontrol-db
    ];
  };
}
