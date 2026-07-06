# NOTE: this duplicates config in nixos and home-manager
# the reason is that flatpak requires the nixos configuration
# and it is totally safe to do it on both ends since the
# home-manager config will just override the nixos configuration
{
  machines.nixosModules.xdg-portal =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      hardware = config.dot.hardware;
    in
    lib.mkIf hardware.graphics {
      services.gnome.gnome-keyring.enable = true;

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
      # NOTE: needed to enable kde file chooser
      dot.desktop.sessionVariables = {
        GTK_USE_PORTAL = "1";
      };

      # NOTE: they seem to start at weird times and this fixes them
      # the services themselves are from packages so its kinda hard to
      # modify their start time from nix in a nice way
      dot.desktop.sessionStartup = [
        "${pkgs.systemd}/bin/systemctl restart --user *xdg-desktop-portal*"
      ];

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
