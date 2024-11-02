{ pkgs, lib, config, ... }:

let
  hasSoundcard =
    (builtins.hasAttr "sound" config.facter.report.hardware) &&
    ((builtins.length config.facter.report.hardware.sound) > 0);
in
{
  shared = lib.mkIf hasSoundcard {
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

  system = lib.mkIf hasSoundcard {
    services.pipewire.enable = true;
    services.pipewire.wireplumber.enable = true;
    services.pipewire.alsa.enable = true;
    services.pipewire.alsa.support32Bit = true;
    services.pipewire.jack.enable = true;
    services.pipewire.pulse.enable = true;
    programs.dconf.enable = true;
  };

  home = lib.mkIf hasSoundcard {
    home.packages = with pkgs; [
      pwvucontrol
      easyeffects
    ];

    services.easyeffects.enable = true;
    services.easyeffects.preset = "speakers";
  };
}
