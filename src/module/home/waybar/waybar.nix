{ hardware, pkgs, config, ... }:

let
  waybare = pkgs.writeShellApplication {
    name = "waybare";
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
  programs.waybar.enable = true;
  programs.waybar.settings = [
    {
      output = hardware.mainMonitor;
      network = { interface = hardware.networkInterface; };
    }
    (builtins.fromJSON (builtins.readFile ./config.json))
  ];
  programs.waybar.style = ''
    @import "${config.xdg.configHome}/waybar/colors.css";

    ${builtins.readFile ./style.css}
  '';

  xdg.configFile."walapp/waybar".source = "${waybare}/bin/waybare";
  xdg.configFile."walapp/waybar".executable = true;
  programs.lulezojne.config = {
    plop = [
      {
        template = ''
          @define-color background {{ rgba (set-alpha ansi.main.black 0.3) }};
          @define-color magenta {{ hex ansi.main.magenta }};
        '';
        "in" = "${config.xdg.configHome}/waybar/colors.css";
      }
    ];
  };

  wayland.windowManager.hyprland.extraConfig = ''
    exec-once = ${pkgs.waybar}/bin/waybar
    exec = ${waybare}/bin/waybare
  '';
}
