{ ... }:

let
  common =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      hasWayland = config.dot.hardware.graphics.wayland;

      isStatic = config.dot.wallpaper.static;

      wallpaperImage =
        pkgs.runCommand "wallpaper-image"
          {
            src = config.dot.wallpaper.path;

            buildInputs = [
              pkgs.file
              pkgs.ffmpeg
              pkgs.imagemagick_light
            ];
          }
          ''
            mkdir $out
            if file --mime-type "$src" | grep -q 'video/'; then
              ffmpeg -i "$src" -vf "select=eq(n\,0)" -vsync vfr -q:v 2 "$out/image.png"
            else
              magick "$src" "$out/image.png"
            fi
          '';
    in
    {
      dot.wallpaper = {
        path = "${./wallpaper.mp4}";
        image = "${wallpaperImage}/image.png";
        static = lib.mkDefault (!hasWayland);
        final = if isStatic then config.dot.wallpaper.image else config.dot.wallpaper.path;
      };
    };
in
{
  flake.nixosModules.desktop-wallpaper = {
    imports = [ common ];
  };

  flake.homeModules.desktop-wallpaper =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      hasWayland = config.dot.hardware.graphics.wayland;
      hasMonitor = config.dot.hardware.monitor.enable;
      isStatic = config.dot.wallpaper.static;

      setWallpaperXorg = pkgs.writeShellApplication {
        name = "wallpaper";
        runtimeInputs = [
          pkgs.feh
          pkgs.coreutils
        ];
        text = ''
          feh --bg-fill "$@"
        '';
      };

      # TODO: adjust for images
      setWallpaperWayland = pkgs.writeShellApplication {
        name = "wallpaper";
        runtimeInputs = [
          pkgs.mpvpaper
          pkgs.coreutils
        ];
        text = ''
          mpvpaper \
            -o "video-unscaled=yes no-audio --loop-playlist" \
            '*' "$@"
        '';
      };
    in
    {
      imports = [ common ];

      config = lib.mkIf hasMonitor {
        dot.desktopEnvironment.sessionStartup = lib.mkIf (hasWayland && !isStatic) [
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
