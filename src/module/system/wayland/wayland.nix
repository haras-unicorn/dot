{ pkgs
, self
  # , sweet-theme
, ...
}:

{
  environment.sessionVariables = {
    # TODO: ferdium not working
    NIXOS_OZONE_WL = "1";
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  environment.systemPackages = with pkgs; [
    egl-wayland
    wl-clipboard
    wev
    gtklock
    # TODO: these no worky
    # sweet
    # beauty-line-icon-theme
    # numix-cursor-theme
    # (pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];
  security.pam.services.gtklock = { };

  programs.hyprland.enable = true;
  programs.hyprland.xwayland.enable = true;

  programs.regreet.enable = true;
  programs.regreet.settings = {
    background = {
      path = "${self}/assets/greeter.png";
      fit = "Cover";
    };
    GTK = {
      application_prefer_dark_theme = true;
      # TODO: these no worky
      # theme_name = "Sweet-Dark";
      # font_name = "JetBrainsMono Nerd Font";
      # icon_theme_name = "BeautyLine";
      # cursor_theme_name = "Numix-Cursor";
    };
  };

  # NOTE: says it requires xserver
  # services.xserver.displayManager.sddm.enable = true;
  # services.xserver.displayManager.sddm.autoNumlock = true;
  # services.xserver.displayManager.sddm.theme = "${sweet-theme}/kde/sddm";
  # services.xserver.displayManager.defaultSession = "hyprland";
  # security.pam.services.sddm.enableGnomeKeyring = true;
}
