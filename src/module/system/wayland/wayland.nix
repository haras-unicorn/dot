{ self, pkgs, ... }:

{
  environment.sessionVariables = {
    # TODO: ferdium not working
    NIXOS_OZONE_WL = "1";
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  environment.systemPackages = with pkgs; [
    wev
    sweet
    beauty-line-icon-theme
    numix-cursor-theme
    (pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
    gtklock
  ];
  security.pam.services.gtklock = { };

  programs.hyprland.enable = true;
  programs.hyprland.enableNvidiaPatches = true;
  programs.hyprland.xwayland.enable = true;

  programs.regreet.enable = true;
  programs.regreet.settings = {
    background = {
      path = "${self}/assets/greeter.png";
      fit = "Cover";
    };
    GTK = {
      application_prefer_dark_theme = true;
      theme_name = "Sweet-Dark";
      font_name = "JetBrainsMono Nerd Font";
      icon_theme_name = "BeautyLine";
      cursor_theme_name = "Numix-Cursor";
    };
  };
}
