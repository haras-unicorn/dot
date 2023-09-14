{ hardware, pkgs, ... }:

{
  home.packages = [
    (pkgs.writeShellApplication {
      name = "waybar-reload";
      runtimeInputs = [ pkgs.which pkgs.waybar ];
      text = ''
        pkill waybar || true
        which waybar
        nohup waybar >/dev/null 2>&1 &
      '';
    })
  ];
  programs.waybar.enable = true;
  programs.waybar.settings = [
    {
      output = hardware.mainMonitor;
    }
    (builtins.fromJSON (builtins.readFile ./config.json))
  ];
  programs.waybar.style = builtins.readFile ./style.css;

  wayland.windowManager.hyprland.extraConfig = ''
    exec-once = waybar
    exec = waybar-reload
  '';
}
