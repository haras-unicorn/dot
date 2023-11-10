{ pkgs, ... }:

{
  de.keybinds = [
    {
      mods = [ ];
      key = "XF86AudioPlay";
      command = ''${pkgs.playerctl}/bin/playerctl play-pause'';
    }
    {
      mods = [ ];
      key = "XF86AudioPause";
      command = ''${pkgs.playerctl}/bin/playerctl play-pause'';
    }
    {
      mods = [ ];
      key = "XF86AudioMute";
      command = ''${pkgs.playerctl}/bin/playerctl volume 0.00'';
    }
    {
      mods = [ ];
      key = "XF86AudioLowerVolume";
      command = ''${pkgs.playerctl}/bin/playerctl volume 0.05 -'';
    }
    {
      mods = [ ];
      key = "XF86AudioRaiseVolume";
      command = ''${pkgs.playerctl}/bin/playerctl volume 0.05 +'';
    }
  ];

  services.playerctld.enable = true;
}
