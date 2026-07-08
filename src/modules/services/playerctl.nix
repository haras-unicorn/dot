{
  machines.homeModules.playerctl =
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

      play-pause = pkgs.writeShellApplication {
        name = "playerctl-play-pause";
        runtimeInputs = [ package ];
        text = ''
          exec playerctl play-pause "$@"
        '';
      };
    in
    lib.mkIf hardware.sound {
      dot.commands.play-pause = play-pause;

      home.packages = [ package ];

      services.playerctld.enable = true;
    };
}
