{
  machines.homeModules.playerctl =
    {
      lib,
      osConfig,
      pkgs,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;
    in
    lib.mkIf hardware.sound {
      dot.desktop.keybinds = lib.mkIf hardware.visual [
        {
          mods = [ "super" ];
          key = "v";
          command = "${pkgs.playerctl}/bin/playerctl play-pause";
        }
      ];

      home.packages = [
        pkgs.playerctl
      ];

      services.playerctld.enable = true;
    };
}
