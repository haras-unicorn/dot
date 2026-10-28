{
  self.homeModules.playerctl.value =
    {
      lib,
      osConfig,
      config,
      pkgs,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;

      package = config.services.playerctld.package;
    in
    lib.mkIf hardware.sound {
      dot.commands.play-pause = pkgs.harasPackages.play-pause;

      home.packages = [ package ];

      services.playerctld.enable = true;
    };
}
