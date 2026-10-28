{
  self.nixosModules.ydotool.value =
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

  self.homeModules.ydotool.value =
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
          ydotool type --file -
        '';
      };
    in
    lib.mkIf hardware.visual {
      dot.commands.type = type;
    };
}
