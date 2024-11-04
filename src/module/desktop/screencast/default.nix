{ pkgs, config, lib, ... }:

let
  hasMonitor = config.dot.hardware.monitor.enable;
in
{
  home = lib.mkIf hasMonitor {
    programs.obs-studio.enable = true;
    programs.obs-studio.plugins = with pkgs; [
      obs-studio-plugins.wlrobs
      obs-studio-plugins.obs-vaapi
      obs-studio-plugins.obs-pipewire-audio-capture
      obs-studio-plugins.obs-gstreamer
    ];
  };
}
