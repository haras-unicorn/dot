{
  self.nixosModules.polkit.value =
    {
      config,
      lib,
      ...
    }:
    let
      hardware = config.dot.hardware;
    in
    {
      config = lib.mkIf hardware.graphics {
        security.polkit.enable = true;
      };
    };

  self.homeModules.polkit.value =
    {
      osConfig,
      config,
      lib,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;
    in
    {
      config = lib.mkIf hardware.graphics {
        services.polkit-gnome.enable = lib.mkIf (!config.wayland.windowManager.hyprland.enable) true;
        services.hyprpolkitagent.enable = lib.mkIf config.wayland.windowManager.hyprland.enable true;
      };
    };
}
