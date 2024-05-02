{ pkgs, ... }:

# FIXME: fix not actually typing stuff in

{
  home.shared = {
    de.keybinds = [
      {
        mods = [ "super" ];
        key = "e";
        command = "${pkgs.emote}/bin/emote";
      }
    ];

    home.packages = with pkgs; [ emote ];
  };
}
