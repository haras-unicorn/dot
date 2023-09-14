{ self, pkgs, ... }:

let
  colorap = pkgs.writeShellApplication {
    name = "colorap";
    runtimeInputs = [ pkgs.coreutils-full ];
    text = ''
      # TODO: "event listener" API so other modules can hook into it
    '';
  };

  shwal =
    pkgs.writeShellApplication {
      name = "shwal";
      runtimeInputs = [ pkgs.coreutils-full pkgs.swww pkgs.pywal colorap ];
      text = ''
        image = "$(find "${self}/assets/wallpapers" -type f | shuf -n 1)"
        swww img "$image"
        wal -steq -i "$image" -o colorap
      '';
    };
in
{
  home.packages = with pkgs; [
    pywal
    swww
    shwal
    colorap
  ];

  wayland.windowManager.hyprland.extraConfig = ''
    exec-once = ${pkgs.swww}/bin/swww init
    exec = ${shwal}/bin/shwal

    misc {
      disable_hyprland_logo = true
    }
  '';
}
