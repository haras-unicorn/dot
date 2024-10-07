{ self, pkgs, config, lib, ... }:

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
    '';
  };
in
{
  home.shared = {
    home.packages = [ wallpaper ];

    home.activation = {
      fehReloadAction = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${wallpaper}/bin/wallpaper '${config.dot.wallpaper}' || true
      '';
    };
  };
}
