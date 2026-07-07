{
  self.lib.deprecated.homeModules.emote =
    {
      pkgs,
      lib,
      config,
      osConfig,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;

      smile = pkgs.smile;

      emote = pkgs.writeShellApplication {
        name = "emote";
        runtimeInputs = [ smile ];
        text = "smile";
      };
    in
    lib.mkIf hardware.visual {
      dot.programs.shell.emoji = emote;

      dot.desktop.windowrules = [
        {
          rule = "float";
          selector = "class";
          arg = "it.mijorus.smile";
        }
      ];

      home.packages = [
        smile
      ];
    };
}
