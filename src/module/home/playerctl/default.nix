{ pkgs, ... }:

# TODO: make the volume stuff work

{
  de.keybinds = [
    {
      mods = [ "super" ];
      key = "v";
      command = ''${pkgs.playerctl}/bin/playerctl play-pause'';
    }
    {
      mods = [ "super" "alt" ];
      key = "v";
      command = ''${pkgs.playerctl}/bin/playerctl volume 0.00'';
    }
    {
      mods = [ "super" "control" "shift" ];
      key = "v";
      command = ''${pkgs.playerctl}/bin/playerctl volume 0.05 +'';
    }
    {
      mods = [ "super" "control" ];
      key = "v";
      command = ''${pkgs.playerctl}/bin/playerctl volume 0.05 -'';
    }
  ];

  services.playerctld.enable = true;
}
