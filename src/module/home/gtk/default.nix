{ pkgs, ... }:

# TODO: lulezojne

{
  de.sessionVariables = {
    GTK_USE_PORTAL = 1;
  };

  gtk.enable = true;
  gtk.theme.name = "Sweet-Dark";
  gtk.theme.package = pkgs.sweet;
  gtk.font.package = pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" ]; };
  gtk.font.name = "JetBrainsMono Nerd Font";
  gtk.iconTheme.name = "BeautyLine";
  gtk.iconTheme.package = pkgs.beauty-line-icon-theme;
}
