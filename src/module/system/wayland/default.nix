{ pkgs
  # , self
  # , sweet-theme
, ...
}:

# TODO: figure out how to bind without referencing hyprland

{
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    WLR_NO_HARDWARE_CURSORS = "1";
    XDG_SESSION_TYPE = "wayland";
    MOZ_ENABLE_WAYLAND = "1";
    NIXOS_XDG_OPEN_USE_PORTAL = "1";
    GDK_BACKEND = "wayland";
    CLUTTER_BACKEND = "wayland";
    _JAVA_AWT_WM_NONREPARENTING = "1";
  };

  environment.systemPackages = with pkgs; [
    libsForQt5.qt5ct
    qt6.qtwayland
    libsForQt5.qt5.qtwayland
    egl-wayland
    wl-clipboard
    wev
    # TODO: find wayland alternative
    # wlprop requires sway
    # xorg.xprop
    # use hyprctl clients for now
    # TODO: these no worky
    # sweet
    # beauty-line-icon-theme
    # numix-cursor-theme
    # (pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];
  security.pam.services.gtklock = { };

  programs.hyprland.enable = true;
  programs.hyprland.xwayland.enable = true;

  # TODO: uncouple from hyprland
  services.greetd.enable = true;
  services.greetd.settings = {
    default_session = {
      command = "${pkgs.greetd.tuigreet}/bin/tuigreet --cmd ${pkgs.hyprland}/bin/Hyprland";
    };
  };

  # NOTE: fails with vulkan driver
  # programs.regreet.enable = true;
  # programs.regreet.settings = {
  #   background = {
  #     path = "${self}/assets/greeter.png";
  #     fit = "Cover";
  #   };
  #   GTK = {
  #     application_prefer_dark_theme = true;
  #     # TODO: these no worky
  #     # theme_name = "Sweet-Dark";
  #     # font_name = "JetBrainsMono Nerd Font";
  #     # icon_theme_name = "BeautyLine";
  #     # cursor_theme_name = "Numix-Cursor";
  #   };
  # };

  # NOTE: says it requires xserver
  # services.xserver.displayManager.sddm.enable = true;
  # services.xserver.displayManager.sddm.autoNumlock = true;
  # services.xserver.displayManager.sddm.theme = "${sweet-theme}/kde/sddm";
  # services.xserver.displayManager.defaultSession = "hyprland";
  # security.pam.services.sddm.enableGnomeKeyring = true;
}
