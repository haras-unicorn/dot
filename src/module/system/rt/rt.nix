{ pkgs, hardware, ... }:

# NOTE: https://github.com/musnix/musnix

{
  boot.kernelPackages = pkgs.linux-rt_latest;
  boot.kernel.sysctl = { "vm.swappiness" = 10; };
  boot.kernelParams = [ "threadirq" ];
  boot.postBootCommands = ''
    ${pkgs.pciutils}/bin/setpci -v -d *:* latency_timer=b0
    ${pkgs.pciutils}/bin/setpci -v -s ${hardware.soundcardPciId} latency_timer=ff
  '';

  powerManagement.cpuFreqGovernor = "performance";

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

  services.das_watchdog.enable = true;
  services.ananicy.enable = true;
  services.earlyoom.enable = true;
  services.irqbalance.enable = true;

  security.rtkit.enable = true;
  security.pam.loginLimits = [
    { domain = "@audio"; item = "memlock"; type = "-"; value = "unlimited"; }
    { domain = "@audio"; item = "rtprio"; type = "-"; value = "99"; }
    { domain = "@audio"; item = "nofile"; type = "soft"; value = "99999"; }
    { domain = "@audio"; item = "nofile"; type = "hard"; value = "99999"; }
  ];
  services.udev.extraRules = ''
    KERNEL=="rtc0", GROUP="audio"
    KERNEL=="hpet", GROUP="audio"
  '';

  environment.systemPackages = with pkgs; [
    helix
    git
  ];
}
