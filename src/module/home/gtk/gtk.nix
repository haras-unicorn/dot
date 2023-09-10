{ pkgs, ... }:

{
  gtk.enable = true;
  gtk.theme.name = "Sweet-Dark";
  gtk.theme.package = pkgs.sweet;
  gtk.font.package = pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" ]; };
  gtk.font.name = "JetBrainsMono Nerd Font";
  gtk.iconTheme.name = "BeautyLine";
  gtk.iconTheme.package = pkgs.beauty-line-icon-theme;
  gtk.cursorTheme.name = "Numix-Cursor";
  gtk.cursorTheme.package = pkgs.numix-cursor-theme;
}
