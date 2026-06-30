{
  self.lib.deprecated.nixosModules.sddm =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.dot.desktop;
      hardware = config.dot.hardware;
    in
    {
      config = lib.mkIf (hardware.visual && !hardware.wayland) {
        environment.systemPackages = [
          pkgs.libsForQt5.qt5.qtgraphicaleffects
          pkgs.libsForQt5.plasma-framework
        ];

        services.displayManager.sddm.enable = true;
        services.displayManager.sddm.autoNumlock = true;
        services.displayManager.sddm.theme = "${pkgs.sweet-nova.src}/kde/sddm";
        services.displayManager.defaultSession = "${(builtins.head cfg.startup).name}";
        security.pam.services.sddm.enableGnomeKeyring = true;
      };
    };
}
