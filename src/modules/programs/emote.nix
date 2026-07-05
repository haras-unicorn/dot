{
  machines.homeModules.emote =
    {
      pkgs,
      lib,
      config,
      osConfig,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;

      emote = pkgs.writeShellApplication {
        name = "emote";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.smile
          config.dot.programs.shell.paste
          config.dot.programs.shell.type
        ];
        text = ''
          smile; type "$(paste)"
        '';
      };
    in
    lib.mkIf hardware.visual {
      dot.desktop.keybinds = [
        {
          mods = [ "super" ];
          key = "e";
          command = "${emote}/bin/emote";
        }
      ];

      dot.desktop.windowrules = [
        {
          rule = "float";
          selector = "class";
          arg = "it.mijorus.smile";
        }
      ];

      home.packages = [
        pkgs.smile
        emote
      ];
    };
}
