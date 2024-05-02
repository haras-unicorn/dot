{ self, pkgs, config, ... }:

# TODO: lulezojne

{
  imports = [
    "${self}/src/modules/gpg"
  ];

  home.shared = {
    de.keybinds = [
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

    home.packages = with pkgs; [
      keepmenu
    ];
    # NOTE: ln -s <db location> <home>/.keepmenu.kdbx
    xdg.configFile."keepmenu/config.ini".text = ''
      [dmenu]
      dmenu_command = ${pkgs.rofi}/bin/rofi -config ${config.xdg.configHome}/rofi/keepmenu.rasi
      pinentry = ${pkgs."${config.dot.gpg.pkg}"}/bin/${config.dot.gpg.bin}
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
