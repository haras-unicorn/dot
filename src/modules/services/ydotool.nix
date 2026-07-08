{
  machines.nixosModules.ydotool =
    {
      config,
      lib,
      ...
    }:

    let
      user = config.dot.user.user;

      hardware = config.dot.hardware;
    in
    lib.mkIf hardware.visual {
      programs.ydotool.enable = true;

      users.users.${user}.extraGroups = [
        config.programs.ydotool.group
      ];
    };

  machines.homeModules.ydotool =
    {
      config,
      osConfig,
      lib,
      pkgs,
      ...
    }:

    let
      hardware = osConfig.dot.hardware;

      type = pkgs.writeShellApplication {
        name = "type";
        runtimeInputs = [
          pkgs.ydotool
        ];
        text = ''
          printf "%s" "type '$(cat /dev/stdin)'" | ydotool
        '';
      };
    in
    lib.mkIf hardware.visual {
      dot.commands.type = type;
    };
}
