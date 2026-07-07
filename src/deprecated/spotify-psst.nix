{
  self.lib.deprecated.homeModules.spotify-psst =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.spotify-player
        pkgs.psst
      ];
    };
}
