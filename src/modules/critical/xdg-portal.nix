{
  machines.nixosModules.xdg-portal =
    {
      lib,
      config,
      ...
    }:
    let
      hardware = config.dot.hardware;
    in
    lib.mkIf hardware.graphics {
      environment.pathsToLink = [
        "/share/xdg-desktop-portal"
        "/share/applications"
      ];
    };

  machines.homeModules.xdg-portal =
    {
      pkgs,
      lib,
      osConfig,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;
    in
    lib.mkIf hardware.graphics {
      dot.desktop.sessionVariables = {
        GTK_USE_PORTAL = "1";
      };

      # NOTE: they seem to start at weird times and this fixes them
      # the services themselves are from packages so its kinda hard to
      # modify their start time from nix in a nice way
      dot.desktop.sessionStartup = [
        "${pkgs.systemd}/bin/systemctl restart --user *xdg-desktop-portal*"
      ];

      services.gnome-keyring.enable = true;

      xdg.portal.enable = true;
      xdg.portal.xdgOpenUsePortal = true;

      xdg.portal.extraPortals = [
        pkgs.xdg-desktop-portal-gtk
        pkgs.kdePackages.xdg-desktop-portal-kde
        pkgs.gnome-keyring
      ];
      xdg.portal.config.common = {
        default = [
          "gtk"
          "kde"
        ];
        "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "kde" ];
      };
    };
}
