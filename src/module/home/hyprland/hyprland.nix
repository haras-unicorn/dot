{ ... }:

{
  wayland.windowManager.hyprland = {
    enable = true;
    enableNvidiaPatches = true;
    xwayland.enable = true;
    extraConfig = ''
      bind = $mainMod, Q, exec, kitty
    '';
  };
}
