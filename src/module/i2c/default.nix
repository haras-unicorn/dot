{ pkgs, ... }:

{
  system = {
    hardware.i2c.enable = true;

    services.ddccontrol.enable = true;
  };

  home.shared = {
    home.packages = with pkgs; [
      ddccontrol
      ddccontrol-db
    ];
  };
}
