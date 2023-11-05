{ pkgs, ... }:

# TODO: wayland...

{
  home.pointerCursor = {
    package = pkgs.numix-cursor-theme;
    name = "Numix-Cursor";
    gtk.enable = true;
  };
}
