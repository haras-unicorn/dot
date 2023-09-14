{ hardware, pkgs, config, ... }:

let
  waybar-reload = pkgs.writeShellApplication {
    name = "waybar-reload";
    runtimeInputs = [ pkgs.coreutils-full ];
    text = ''
      # NOTE: only kill those that don't match this script
      IFS=$'\n' read -r -a pids <<< "$(pgrep -f waybar)"
      for pid in "''${pids[@]}"; do
        if [[ $pid != "$$" ]]; then
          kill "$pid"
        fi
      done

      waybar >/dev/null 2>&1 & disown
    '';
  };
in
{
  home.packages = [
    waybar-reload
  ];

  programs.waybar.enable = true;
  programs.waybar.settings = [
    {
      output = hardware.mainMonitor;
      network = { interface = hardware.networkInterface; };
    }
    (builtins.fromJSON (builtins.readFile ./config.json))
  ];
  programs.waybar.style = ''
    @import "colors.css";

    ${builtins.readFile ./style.css}
  '';

  xdg.configFile."walapp/waybar".text = ''
    #!${pkgs.stdenv.shell}

    cp "$1/colors-waybar.css" "${config.xdg.configHome}/waybar/colors.css"
  '';
  xdg.configFile."walapp/waybar".executable = true;


  wayland.windowManager.hyprland.extraConfig = ''
    exec-once = ${pkgs.waybar}/bin/waybar
    exec = ${waybar-reload}/bin/waybar-reload
  '';
}
