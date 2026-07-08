{ self, ... }:

{
  machines.nixosModules.background =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      hardware = config.dot.hardware;

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
        path = "${self}/assets/wallpaper/background.mp4";
        image = "${wallpaperImage}/image.png";
        scheme = "${self}/assets/wallpaper/background.json";
        static = lib.mkDefault (!hardware.wayland);
        final = if isStatic then config.dot.wallpaper.image else config.dot.wallpaper.path;
      };
    };
}
