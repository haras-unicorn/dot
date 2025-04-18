{ pkgs, lib, config, ... }:

# TODO: colors

let
  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;
  hasKeyboard = config.dot.hardware.keyboard.enable;
in
{
  branch.homeManagerModule.homeManagerModule = lib.mkIf (hasMonitor && hasKeyboard && !hasWayland) {
    dot.desktopEnvironment.keybinds = [
      {
        mods = [ "super" ];
        key = "return";
        command = "${pkgs.rofi}/bin/rofi -show drun -modi run,drun,window -config '${config.xdg.configHome}/rofi/launcher.rasi'";
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

    home.packages = [
      pkgs.keepmenu
    ];

    # NOTE: ln -s <db location> <home>/.keepmenu.kdbx
    xdg.configFile."keepmenu/config.ini".text = ''
      [dmenu]
      dmenu_command = ${pkgs.rofi}/bin/rofi -config ${config.xdg.configHome}/rofi/keepmenu.rasi
      pinentry = ${config.dot.pinentry.package}/bin/${config.dot.pinentry.bin}
      title_path = False

      [dmenu_passphrase]
      obscure = True

      [database]
      database_1 = ~/.keepmenu.kdbx
      pw_cache_period_min = 1
      autotype_default = {USERNAME}{TAB}{PASSWORD}
    '';

    programs.rofi.enable = true;
    xdg.configFile."rofi/launcher.rasi".source = ./launcher.rasi;
    xdg.configFile."rofi/colors.rasi".source = ./colors.rasi;
    xdg.configFile."rofi/keepmenu.rasi".source = ./keepmenu.rasi;
  };
}
