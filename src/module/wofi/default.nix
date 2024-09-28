{ pkgs, config, ... }:

let
  bootstrap = config.dot.colors.bootstrap;
in
{
  shared = {
    dot = {
      desktopEnvironment.keybinds = [
        {
          mods = [ "super" ];
          key = "return";
          command = ''${pkgs.wofi}/bin/wofi --show drun --prompt run'';
        }
        {
          mods = [ "super" ];
          key = "p";
          command = "${pkgs.keepmenu}/bin/keepmenu";
        }
        {
          mods = [ "super" "shift" ];
          key = "p";
          command = "${pkgs.keepmenu}/bin/keepmenu -a '{PASSWORD}'";
        }
        {
          mods = [ "super" "alt" ];
          key = "p";
          command = "${pkgs.keepmenu}/bin/keepmenu -a '{TOTP}'";
        }
      ];
    };
  };

  home.shared = {
    home.packages = with pkgs; [
      keepmenu
      wtype
    ];

    # NOTE: ln -s <db location> <home>/.keepmenu.kdbx
    xdg.configFile."keepmenu/config.ini".text = ''
      [dmenu]
      dmenu_command = ${pkgs.wofi}/bin/wofi --prompt "Be careful!"
      pinentry = ${config.dot.pinentry.package}/bin/${config.dot.pinentry.bin}
      title_path = False

      [dmenu_passphrase]
      obscure = True

      [database]
      database_1 = ~/.keepmenu.kdbx
      type_library = wtype
      pw_cache_period_min = 1
      autotype_default = {USERNAME}{TAB}{PASSWORD}
    '';

    programs.wofi.enable = true;

    programs.wofi.settings = {
      allow_markup = true;
    };

    programs.wofi.style = ''
      @define-color background ${bootstrap.background};
      @define-color text ${bootstrap.text};
      @define-color accent ${bootstrap.accent};
      @define-color primary ${bootstrap.primary};
      @define-color selection ${bootstrap.selection};

      * {
        font-family: '${config.dot.font.sans.name}';
        font-size: ${builtins.toString config.dot.font.size.large}px;
      }

      ${builtins.readFile ./style.css}
    '';
  };
}
