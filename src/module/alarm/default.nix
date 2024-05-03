{ self, pkgs, ... }:

# TODO: figure out why the sound doesn't work

{
  imports = [
    "${self}/src/module/gstreamer"
  ];

  shared = {
    dot = {
      desktopEnvironment.sessionStartup = [
        "${pkgs.alarm-clock-applet}/bin/alarm-clock-applet"
      ];
    };
  };

  home.shared = {
    home.packages = with pkgs; [ alarm-clock-applet ];
  };
}
