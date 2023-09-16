{ self, pkgs, config, lule-src, ... }:

let
  lule = pkgs.rustPlatform.buildRustPackage {
    pname = "lule";
    version = "0.1";
    src = lule-src;
  };

  walapp = pkgs.writeShellApplication {
    name = "walapp";
    runtimeInputs = [ pkgs.coreutils-full pkgs.debianutils ];
    text = ''
      run-parts --arg="${config.xdg.cacheHome}/wal/" "${config.xdg.configHome}/walapp"
    '';
  };

  shwal =
    pkgs.writeShellApplication {
      name = "shwal";
      runtimeInputs = [ pkgs.coreutils-full pkgs.swww pkgs.pywal walapp ];
      text = ''
        image="$(find "${self}/assets/wallpapers" -type f | shuf -n 1)"
        swww img "$image"
        wal -steq -i "$image" -o walapp
      '';
    };
in
{
  home.packages = with pkgs; [
    lule
    pywal
    swww
    shwal
  ];

  wayland.windowManager.hyprland.extraConfig = ''
    exec-once = ${pkgs.swww}/bin/swww init
    exec = ${shwal}/bin/shwal

    misc {
      disable_hyprland_logo = true
    }
  '';
}
