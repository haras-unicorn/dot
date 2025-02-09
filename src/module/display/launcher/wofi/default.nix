{ pkgs, lib, config, ... }:

# FIXME: conflicts with stylix

let
  bootstrap = config.dot.colors.bootstrap;

  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;
  hasKeyboard = config.dot.hardware.keyboard.enable;
in
{
  config = lib.mkIf (hasMonitor && hasKeyboard && hasWayland) {
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

  home = lib.mkIf (hasMonitor && hasKeyboard && hasWayland) {
    home.packages = [
      pkgs.keepmenu
      pkgs.wtype
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
  };
}
