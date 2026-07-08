{
  machines.homeModules.keepmenu =
    {
      pkgs,
      lib,
      config,
      osConfig,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;

      package = pkgs.keepmenu;
    in
    lib.mkIf (hardware.visual && hardware.wayland) {
      dot.desktop.keybinds = [
        {
          mods = [ "super" ];
          key = "z";
          command = "${lib.getExe package}";
        }
        {
          mods = [
            "super"
            "shift"
          ];
          key = "z";
          command = "${lib.getExe package} -a '{PASSWORD}'";
        }
        {
          mods = [
            "super"
            "alt"
          ];
          key = "z";
          command = "${lib.getExe package} -a '{TOTP}'";
        }
      ];

      home.packages = [
        package
        pkgs.wtype
      ];

      xdg.configFile."keepmenu/config.ini".text = ''
        [dmenu]
        dmenu_command = ${lib.getExe config.dot.commands.dmenu}
        pinentry = ${lib.getExe osConfig.dot.commands.pinentry}
        title_path = False

        [dmenu_passphrase]
        obscure = True

        [database]
        database_1 = ~/.keepassxc.kdbx
        type_library = wtype
        pw_cache_period_min = 1
        autotype_default = {USERNAME}{TAB}{PASSWORD}
      '';
    };
}
