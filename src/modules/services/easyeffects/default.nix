{
  machines.homeModules.easyeffects =
    {
      pkgs,
      lib,
      config,
      osConfig,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;

      # FIXME: https://github.com/wwmm/easyeffects/issues/4402
      toggleEasyeffectsBypass = pkgs.writeShellApplication {
        name = "toggle-easyeffects-bypass";
        runtimeInputs = [
          pkgs.easyeffects
          pkgs.coreutils
        ];
        text = ''
          if [ "$(easyeffects -b 3)" = "1" ]; then
            easyeffects -b 2
          else
            easyeffects -b 1
          fi
        '';
      };
    in
    lib.mkIf hardware.sound {
      dot.desktop.keybinds = lib.mkIf hardware.typing [
        {
          mods = [
            "shift"
            "super"
          ];
          key = "v";
          command = "${toggleEasyeffectsBypass}/toggle-easyeffects-bypass";
        }
      ];

      dot.desktop.windowrules = lib.mkIf hardware.graphics [
        {
          rule = "float";
          selector = "class";
          arg = "com.github.wwmm.easyeffects";
        }
      ];

      home.packages = [
        pkgs.easyeffects
      ];

      services.easyeffects.enable = true;

      xdg.dataFile."easyeffects/output/krk.json".source = ./krk.json;
    };
}
