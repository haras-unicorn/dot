{ self, pkgs, ... }:

# TODO: figure out why the sound doesn't work

{
  home.shared = {
    imports = [
      "${self}/src/module/home/gstreamer"
    ];

    de.sessionStartup = [
      "${pkgs.alarm-clock-applet}/bin/alarm-clock-applet"
    ];

    home.packages = with pkgs; [ alarm-clock-applet ];
  };
}
