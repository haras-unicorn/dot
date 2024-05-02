{ self, pkgs, config, ... }:

{
  imports = [
    "${self}/src/modules/gpg"
  ];

  home.shared = {
    de.keybinds = [
      {
        mods = [ "super" ];
        key = "return";
        command = ''${pkgs.wofi}/bin/wofi --show drun --prompt "Hello!"'';
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

    programs.lulezojne.config.plop = [
      {
        template = ''
          @define-color background {{ rgba ansi.main.black }};
          @define-color foreground {{ hex ansi.main.bright_white }};

          @define-color black {{ rgba ansi.main.black }};
          @define-color gray {{ rgba ansi.main.bright_black }};
          @define-color white {{ rgba ansi.main.white }};

          @define-color red {{ hex ansi.main.red }};
          @define-color green {{ hex ansi.main.green }};
          @define-color blue {{ hex ansi.main.blue }};
          @define-color cyan {{ hex ansi.main.cyan }};
          @define-color yellow {{ hex ansi.main.yellow }};
          @define-color magenta {{ hex ansi.main.magenta }};

          @define-color bright-red {{ hex ansi.main.bright_red }};
          @define-color bright-green {{ hex ansi.main.bright_green }};
          @define-color bright-blue {{ hex ansi.main.bright_blue }};
          @define-color bright-cyan {{ hex ansi.main.bright_cyan }};
          @define-color bright-yellow {{ hex ansi.main.bright_yellow }};
          @define-color bright-magenta {{ hex ansi.main.bright_magenta }};
        '';
        "in" = "${config.xdg.configHome}/wofi/colors.css";
      }
    ];

    home.packages = with pkgs; [
      keepmenu
      wtype
    ];

    # NOTE: ln -s <db location> <home>/.keepmenu.kdbx
    xdg.configFile."keepmenu/config.ini".text = ''
      [dmenu]
      dmenu_command = ${pkgs.wofi}/bin/wofi --prompt "Be careful!"
      pinentry = ${config.dot.gpg.package}/bin/${config.dot.gpg.bin}
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
      @import "${config.xdg.configHome}/wofi/colors.css";

      * {
        font-family: '${config.dot.font.sans.name}';
        font-size: ${builtins.toString config.dot.font.size.large}px;
      }

      ${builtins.readFile ./style.css}
    '';
  };
}
