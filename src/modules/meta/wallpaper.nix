{
  machines.nixosModules.wallpaper =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      options.dot = {
        wallpaper = {
          path = lib.mkOption {
            type = lib.types.str;
            description = ''
              Path to the wallpaper (image or video).
            '';
          };
          image = lib.mkOption {
            type = lib.types.str;
            description = ''
              Path to the wallpaper image.
            '';
          };
          static = lib.mkOption {
            type = lib.types.bool;
            description = ''
              Whether the wallpaper should be a static image or video if possible.
            '';
          };
          final = lib.mkOption {
            type = lib.types.str;
            description = ''
              Final wallpaper path.
            '';
          };
          scheme = lib.mkOption {
            type = lib.types.path;
            description = ''
              Wallpaper color scheme path.
            '';
          };
        };
      };
    };
}
