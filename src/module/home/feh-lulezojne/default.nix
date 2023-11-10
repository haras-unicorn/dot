{ self, pkgs, ... }:

let
  wallpaper = pkgs.writeShellApplication {
    name = "wallpaper";
    runtimeInputs = [ pkgs.feh ];
    text = ''
      if [[ "''${1-x}" == "x" ]]; then
        image="$(find "${self}/assets/wallpapers" -type f | shuf -n 1)"
      else
        image="$1"
      fi
      feh --bg-fill "$image" || true
      lulezojne plop "$image" || true
    '';
  };
in
{
  home.packages = with pkgs; [
    feh
    wallpaper
  ];

  programs.lulezojne.enable = true;
}
