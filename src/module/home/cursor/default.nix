{ pkgs, ... }:

# TODO: wayland...
# TODO: meta

{
  home.shared = {
    home.pointerCursor = {
      package = pkgs.numix-cursor-theme;
      name = "Numix-Cursor";
      gtk.enable = true;
    };
  };
}
