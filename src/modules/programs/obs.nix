{
  self.homeModules.obs.value =
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
      programs.obs-studio.plugins = [
        pkgs.obs-studio-plugins.wlrobs
        pkgs.obs-studio-plugins.obs-vaapi
        pkgs.obs-studio-plugins.obs-pipewire-audio-capture
      ];
    };
}
