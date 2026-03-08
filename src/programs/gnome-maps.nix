{
  flake.homeModules.programs-gnome-maps =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      home.packages = lib.mkIf config.dot.hardware.monitor.enable [
        pkgs.gnome-maps
      ];
    };
}
