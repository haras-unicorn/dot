{ pkgs, ... }:

# TODO: keybinds

{
  de.keybinds = [
    {
      mods = [ ];
      key = "XF86AudioPlay";
      command = ''${pkgs.playerctld}/bin/playerctl play-pause'';
    }
    {
      mods = [ ];
      key = "XF86AudioPause";
      command = ''${pkgs.playerctld}/bin/playerctl play-pause'';
    }
    {
      mods = [ ];
      key = "XF86AudioMute";
      command = ''${pkgs.playerctld}/bin/playerctl volume 0.00'';
    }
    {
      mods = [ ];
      key = "XF86AudioLowerVolume";
      command = ''${pkgs.playerctld}/bin/playerctl volume 0.05 -'';
    }
    {
      mods = [ ];
      key = "XF86AudioRaiseVolume";
      command = ''${pkgs.playerctld}/bin/playerctl volume 0.05 +'';
    }
  ];

  services.playerctld.enable = true;
}
