{
  machines.homeModules.obs =
    {
      pkgs,
      osConfig,
      lib,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;
    in
    lib.mkIf hardware.browser {
      programs.obs-studio.enable = true;
      programs.obs-studio.plugins = with pkgs.obs-studio-plugins; [
        wlrobs
        obs-vaapi
        obs-pipewire-audio-capture
        obs-gstreamer
      ];
    };
}
