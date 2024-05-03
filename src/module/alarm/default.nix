{ self, pkgs, ... }:

# TODO: figure out why the sound doesn't work

{
  imports = [
    "${self}/src/module/gstreamer"
  ];

  home.shared = {

    de.sessionStartup = [
      "${pkgs.alarm-clock-applet}/bin/alarm-clock-applet"
    ];

    home.packages = with pkgs; [ alarm-clock-applet ];
  };
}
