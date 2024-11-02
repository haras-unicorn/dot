{ pkgs, lib, config, ... }:

let
  inherit (lib) types mkOption;

  facterReport = config.facter.report;

  optimization = config.dot.hardware.audio.optimization or { };
  optimizationEnable = optimization.enable or false;
  optimizationSoundcard = optimization.soundcard or null;

  soundDevices = facterReport.hardware.sound or [ ];

  targetSoundDevice =
    if optimizationSoundcard != null then
      builtins.head
        (lib.filter
          (device:
            lib.hasAttr "model" device && device.model ==
            optimizationSoundcard)
          soundDevices)
    else
      null;

  soundcardPciId =
    if targetSoundDevice != null then
      targetSoundDevice.sysfs_bus_id
    else
      null;

  totalRamKB =
    let
      memDevices = facterReport.hardware.memory or [ ];
      memDevice = builtins.head memDevices;
      memResources = memDevice.resources or [ ];
      memResource = builtins.head memResources;
      totalRamBytes = memResource.range or 0;
    in
    totalRamBytes / 1024;

  cpuList = facterReport.hardware.cpu or [ ];
  cpuInfo = builtins.head cpuList;
  cpuFeatures = cpuInfo.features or [ ];

  hasAvx2 = lib.elem "avx2" cpuFeatures;
in
{
  options = {
    hardware.audio.optimization.enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable hardware audio optimizations.
      '';
    };

    hardware.audio.optimization.soundcard = mkOption {
      type = types.str;
      default = null;
      description = ''
        Model name of the soundcard to optimize.
      '';
    };
  };

  config = {
    shared.dot = {
      desktopEnvironment.windowrules = [{
        rule = "float";
        selector = "class";
        xselector = "wm_class";
        arg = "com.saivert.pwvucontrol";
        xarg = "pwvucontrol";
      }];
    };

    system = {
      boot.postBootCommands = lib.optionalString optimizationEnable ''
        ${pkgs.pciutils}/bin/setpci -v -d *:* latency_timer=b0
      ''
      + (if soundcardPciId != null then ''
        ${pkgs.pciutils}/bin/setpci -v -s ${soundcardPciId} latency_timer=ff
      '' else "");

      users.groups.audio = lib.mkIf optimizationEnable { };

      security.rtkit.enable = optimizationEnable;

      security.pam.loginLimits = lib.mkIf optimizationEnable [
        { domain = "@audio"; item = "memlock"; type = "-"; value = "unlimited"; }
        { domain = "@audio"; item = "rtprio"; type = "-"; value = "99"; }
        { domain = "@audio"; item = "nofile"; type = "soft"; value = "524288"; }
        { domain = "@audio"; item = "nofile"; type = "hard"; value = "524288"; }
      ];

      services.udev.extraRules = lib.mkIf optimizationEnable ''
          KERNEL == "rtc0", GROUP="audio"
        KERNEL == "hpet", GROUP="audio"
      '';


      services.pipewire.enable = true;
      services.pipewire.wireplumber.enable = true;
      services.pipewire.alsa.enable = true;
      services.pipewire.alsa.support32Bit = true;
      services.pipewire.jack.enable = true;
      services.pipewire.pulse.enable = true;

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

      programs.dconf.enable = true;
    };

    home = {
      home.packages = with pkgs; [
        pwvucontrol
        easyeffects
      ];

      services.easyeffects.enable = true;
      services.easyeffects.preset = "speakers";
    };
  };
}
