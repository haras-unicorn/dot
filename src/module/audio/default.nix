{ pkgs, lib, config, ... }:

# FIXME: clashing nofile limits

# NOTE: https://github.com/musnix/musnix

{
  options = {
    dot = {
      soundcardPciId = lib.mkOption {
        type = lib.types.str;
        description = "lspci | grep -i audio";
        example = "2b:00.3";
      };
    };
  };

  config = {
    system = {
      boot.postBootCommands = ''
        ${pkgs.pciutils}/bin/setpci -v -d *:* latency_timer=b0
        ${pkgs.pciutils}/bin/setpci -v -s ${config.dot.soundcardPciId} latency_timer=ff
      '';

      environment.variables =
        let
          makePluginPath = format:
            (pkgs.lib.makeSearchPath format [
              "$HOME/.nix-profile/lib"
              "/run/current-system/sw/lib"
              "/etc/profiles/per-user/$USER/lib"
            ])
            + ":$HOME/.${format}";
        in
        {
          DSSI_PATH = makePluginPath "dssi";
          LADSPA_PATH = makePluginPath "ladspa";
          LV2_PATH = makePluginPath "lv2";
          LXVST_PATH = makePluginPath "lxvst";
          VST_PATH = makePluginPath "vst";
          VST3_PATH = makePluginPath "vst3";
        };

      users.groups.audio = { };

      security.pam.loginLimits = [
        { domain = "@audio"; item = "memlock"; type = "-"; value = "unlimited"; }
        { domain = "@audio"; item = "rtprio"; type = "-"; value = "99"; }
        { domain = "@audio"; item = "nofile"; type = "soft"; value = "524288"; }
        { domain = "@audio"; item = "nofile"; type = "hard"; value = "524288"; }
      ];

      services.udev.extraRules = ''
        KERNEL=="rtc0", GROUP="audio"
        KERNEL=="hpet", GROUP="audio"
      '';
    };
  };
}
