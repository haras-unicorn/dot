{ pkgs, ... }:

# TODO: figure out why the sound doesn't work

{
  shared.dot = {
    desktopEnvironment.sessionStartup = [
      "${pkgs.alarm-clock-applet}/bin/alarm-clock-applet"
    ];
    desktopEnvironment.windowrules = [{
      rule = "float";
      selector = "class";
      xselector = "wm_class";
      arg = "alarm-clock-applet";
      xarg = "alarm-clock-applet";
    }];
  };

  home.shared = {
    home.packages = with pkgs; [ alarm-clock-applet ];
  };
}
