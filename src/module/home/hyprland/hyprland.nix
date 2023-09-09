{ ... }:

{
  wayland.windowManager.hyprland = {
    enable = true;
    enableNvidiaPatches = true;
    xwayland.enable = true;
    extraConfig = ''
      $mainMod = SUPER

      bind = $mainMod, Q, exec, kitty
    '';
  };
}
