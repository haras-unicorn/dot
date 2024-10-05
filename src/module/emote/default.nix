{ pkgs, ... }:

# FIXME: fix not actually typing stuff in

{
  shared = {
    dot = {
      desktopEnvironment.keybinds = [
        {
          mods = [ "super" ];
          key = "e";
          # command = "${pkgs.emote}/bin/emote";
          command = "${pkgs.smile}/bin/smile";
        }
      ];
    };
  };

  home.shared = {
    home.packages = with pkgs; [
      # emote
      smile
    ];
  };
}
