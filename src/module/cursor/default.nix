{ pkgs, ... }:

# TODO: wayland...
# TODO: meta
# TODO: https://github.com/ful1e5/pokemon-cursor

{
  home.shared = {
    home.pointerCursor = {
      package = pkgs.numix-cursor-theme;
      name = "Numix-Cursor";
      gtk.enable = true;
    };
  };
}
