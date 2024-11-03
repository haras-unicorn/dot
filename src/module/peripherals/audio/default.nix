{ pkgs, lib, config, ... }:

let
  hasSound = config.dot.hardware.sound.enable;
  hasMonitor = config.dot.hardware.monitor.enable;
in
{
  shared = lib.mkIf (hasSound && hasMonitor) {
    dot = {
      desktopEnvironment.windowrules = [{
        rule = "float";
        selector = "class";
        xselector = "wm_class";
        arg = "com.saivert.pwvucontrol";
        xarg = "pwvucontrol";
      }];
    };
  };

  system = lib.mkIf hasSound {
    services.pipewire.enable = true;
    services.pipewire.wireplumber.enable = true;
    services.pipewire.alsa.enable = true;
    services.pipewire.alsa.support32Bit = true;
    services.pipewire.jack.enable = true;
    services.pipewire.pulse.enable = true;
    programs.dconf.enable = true;
  };

  home = lib.mkIf (hasSound && hasMonitor) {
    home.packages = with pkgs; [
      pwvucontrol
      easyeffects
    ];

    services.easyeffects.enable = true;
    services.easyeffects.preset = "speakers";
  };
}
