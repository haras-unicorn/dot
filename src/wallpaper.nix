{ self, pkgs, lib, config, ... }:

let
  hasWayland = config.dot.hardware.graphics.wayland;
  hasMonitor = config.dot.hardware.monitor.enable;
  isStatic = config.dot.wallpaper.static;

  setWallpaperXorg = pkgs.writeShellApplication {
    name = "wallpaper";
    runtimeInputs = [ pkgs.feh ];
    text = ''
      feh --bg-fill "$@"
    '';
  };

  # TODO: adjust for images
  setWallpaperWayland = pkgs.writeShellApplication {
    name = "wallpaper";
    runtimeInputs = [ pkgs.mpvpaper ];
    text = ''
      mpvpaper \
        -o "video-unscaled=yes no-audio --loop-playlist" \
        '*' "$@"
    '';
  };

  # NOTE: to keep it from regenerating the pallete
  # whenever something changes in dot
  wallpaperContentDrv = pkgs.stdenv.mkDerivation {
    name = "wallpaper-content-file";
    src = config.dot.wallpaper.path;

    dontUnpack = true;
    dontBuild = true;
    dontConfigure = true;

    installPhase = ''
      mkdir -p $out
      cp $src $out/file
    '';
  };

  wallpaperImage = pkgs.runCommand "wallpaper-image"
    {
      buildInputs = [ pkgs.file pkgs.ffmpeg pkgs.imagemagick_light ];
    }
    ''
      mkdir $out
      prev="${wallpaperContentDrv}/file"
      if file --mime-type "$prev" | grep -qE 'video/'; then
        ffmpeg -i "$prev" -vf "select=eq(n\,0)" -vsync vfr -q:v 2 "$out/image.png"
      else
        magick convert "$prev" "$out/image.png"
      fi
    '';
in
{
  branch.homeManagerModule.homeManagerModule = {
    options.dot = {
      wallpaper.path = lib.mkOption {
        type = lib.types.str;
        default = "${self}/assets/wallpaper.mp4";
      };
      wallpaper.image = lib.mkOption {
        type = lib.types.str;
        default = "${wallpaperImage}/image.png";
      };
      wallpaper.static = lib.mkOption {
        type = lib.types.bool;
        default = !hasWayland;
      };
      wallpaper.final = lib.mkOption {
        type = lib.types.str;
        default =
          if isStatic
          then config.dot.wallpaper.image
          else config.dot.wallpaper.path;
      };
    };

    config = lib.mkIf hasMonitor {
      dot.desktopEnvironment.sessionStartup =
        lib.mkIf (hasWayland && !isStatic) [
          ''${setWallpaperWayland}/bin/wallpaper ${config.dot.wallpaper.final}''
        ];

      stylix.targets.hyprpaper.enable = lib.mkForce (hasWayland && isStatic);
      services.hyprpaper.enable = lib.mkForce (hasWayland && isStatic);

      stylix.targets.feh.enable = lib.mkForce ((!hasWayland) && isStatic);

      home.packages = lib.mkMerge [
        (lib.mkIf (hasWayland) [ setWallpaperWayland ])
        (lib.mkIf (!hasWayland) [ setWallpaperXorg ])
      ];
    };
  };
}
