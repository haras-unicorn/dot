{ ... }:

{
  wayland.windowManager.hyprland = {
    enable = true;
    enableNvidiaPatches = true;
    xwayland.enable = true;
    extraConfig = ''
      $mainMod = SUPER

      bind = $mainMod, Q, exec, kitty
      bind = $mainMod, E, exec, wofi --show drun

      bind = $mainMod, right, movefocus, r
      bind = $mainMod, left, movefocus, l
      bind = $mainMod, up, movefocus, u
      bind = $mainMod, down, movefocus, d

      bind = $mainMod, R, submap, resize
      submap = resize
      binde = , right, resizeactive, 10 0
      binde = , left, resizeactive, -10 0
      binde = , up, resizeactive, 0 -10
      binde = , down, resizeactive, 0 10
      bind = , escape, submap, reset
      submap = reset
    '';
  };
}
