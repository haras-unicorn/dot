{
  machines.homeModules.wofi =
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
          key = "return";
          command = "${pkgs.wofi}/bin/wofi --show drun --prompt run";
        }
        {
          mods = [ "super" ];
          key = "p";
          command = "${pkgs.keepmenu}/bin/keepmenu";
        }
        {
          mods = [
            "super"
            "shift"
          ];
          key = "p";
          command = "${pkgs.keepmenu}/bin/keepmenu -a '{PASSWORD}'";
        }
        {
          mods = [
            "super"
            "alt"
          ];
          key = "p";
          command = "${pkgs.keepmenu}/bin/keepmenu -a '{TOTP}'";
        }
      ];

      home.packages = [
        pkgs.keepmenu
        pkgs.wtype
      ];

      # NOTE: ln -s <db location> <home>/.keepmenu.kdbx
      xdg.configFile."keepmenu/config.ini".text = ''
        [dmenu]
        dmenu_command = ${pkgs.wofi}/bin/wofi --prompt "Be careful!"
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

      programs.wofi.enable = true;

      programs.wofi.settings = {
        allow_markup = true;
      };
    };
}
