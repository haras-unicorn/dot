{
  flake.homeModules.programs-obs =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      hasMonitor = config.dot.hardware.monitor.enable;
    in
    lib.mkIf hasMonitor {
      programs.obs-studio.enable = true;
      programs.obs-studio.plugins = with pkgs.obs-studio-plugins; [
        wlrobs
        obs-vaapi
        obs-pipewire-audio-capture
        obs-gstreamer
      ];
    };
}
