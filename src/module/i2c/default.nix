{ pkgs, ... }:

{
  system = {
    hardware.i2c.enable = true;

    services.ddccontrol.enable = true;
  };

  home = {
    home.packages = with pkgs; [
      ddcutil # NOTE: because ddccontrol might core dump with nvidia
      ddccontrol
      ddccontrol-db
    ];
  };
}
