{ pkgs, config, gnupg, ... }:

# TODO: db location?

{
  home.packages = with pkgs; [
    keepmenu
    wtype
    pkgs."${gnupg.package}"
  ];

  xdg.configFile."keepmenu/config.ini".text = ''
    [dmenu]
    dmenu_command = ${pkgs.wofi}/bin/wofi --prompt "Be careful!"
    pinentry = ${pkgs."${gnupg.package}"}/bin/${gnupg.bin}
    title_path = False

    [dmenu_passphrase]
    obscure = True

    [database]
    database_1 = ~/sync/security/keys.kdbx
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

    ${builtins.readFile ./style.css}
  '';

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

  wayland.windowManager.hyprland.extraConfig = ''
    bind = super, return, exec, ${pkgs.wofi}/bin/wofi --show drun --prompt "Yes, darling?"
    bind = super, p, exec, ${pkgs.keepmenu}/bin/keepmenu
  '';
}
