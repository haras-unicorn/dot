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
    in
    lib.mkIf (hardware.visual && hardware.wayland) {
      dot.desktop.keybinds = [
        {
          mods = [ "super" ];
          key = "z";
          command = "${pkgs.keepmenu}/bin/keepmenu";
        }
        {
          mods = [
            "super"
            "shift"
          ];
          key = "z";
          command = "${pkgs.keepmenu}/bin/keepmenu -a '{PASSWORD}'";
        }
        {
          mods = [
            "super"
            "alt"
          ];
          key = "z";
          command = "${pkgs.keepmenu}/bin/keepmenu -a '{TOTP}'";
        }
      ];

      home.packages = [
        pkgs.keepmenu
        pkgs.wtype
      ];

      xdg.configFile."keepmenu/config.ini".text = ''
        [dmenu]
        dmenu_command = ${lib.getExe config.dot.programs.shell.dmenu}
        pinentry = ${lib.getExe osConfig.dot.programs.pinentry.package}
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
