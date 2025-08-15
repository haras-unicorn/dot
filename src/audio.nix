{
  pkgs,
  lib,
  config,
  musnix,
  ...
}:

# TODO: laptop battery saving

let
  user = config.dot.user;

  hasSound = config.dot.hardware.sound.enable;
  hasMonitor = config.dot.hardware.monitor.enable;
in
{
  branch.nixosModule.nixosModule = {
    imports = [ musnix.nixosModules.musnix ];

    config = lib.mkIf hasSound {
      services.pulseaudio.package = pkgs.pulseaudioFull;

      services.pipewire.enable = true;
      services.pipewire.wireplumber.enable = true;
      services.pipewire.alsa.enable = true;
      services.pipewire.alsa.support32Bit = true;
      services.pipewire.jack.enable = true;
      services.pipewire.pulse.enable = true;

      programs.dconf.enable = true;

      security.rtkit.enable = true;

      users.users.${user}.extraGroups = [
        "audio"
      ];
      musnix.enable = true;
    };
  };

  branch.homeManagerModule.homeManagerModule = lib.mkIf (hasSound && hasMonitor) {
    dot.desktopEnvironment.windowrules = [
      {
        rule = "float";
        selector = "class";
        xselector = "wm_class";
        arg = "com.saivert.pwvucontrol";
        xarg = "pwvucontrol";
      }
    ];

    home.packages = [
      pkgs.pwvucontrol
    ];
  };
}
