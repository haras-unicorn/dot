{ pkgs, lib, config, ... }:

let
  hasMonitor = config.dot.hardware.monitor.enable;
  hasKeyboard = config.dot.hardware.keyboard.enable;
in
{
  branch.homeManagerModule.homeManagerModule = {
    options.dot = {
      pinentry.package = lib.mkOption {
        type = lib.types.package;
        default =
          if hasMonitor
          then pkgs.pinentry-qt
          else pkgs.pinentry-curses;
      };
      pinentry.bin = lib.mkOption {
        type = lib.types.str;
        default =
          if hasMonitor
          then "pinentry-qt"
          else "pinentry-curses";
      };
    };

    config = {
      dot.desktopEnvironment.windowrules = lib.mkIf (hasMonitor && hasKeyboard) [{
        rule = "float";
        selector = "class";
        xselector = "wm_class";
        arg = "org.keepassxc.KeePassXC";
        xarg = "keepassxc";
      }];

      home.packages = lib.optionals hasMonitor [
        pkgs.pinentry-qt
      ] ++ lib.optionals (!hasMonitor) [
        pkgs.pinentry-curses
      ] ++ lib.optionals (hasMonitor && hasKeyboard) [
        pkgs.keepassxc
      ];

      services.gpg-agent.pinentry.package =
        lib.mkMerge [
          (lib.mkIf hasMonitor pkgs.pinentry-qt)
          (lib.mkIf (!hasMonitor) pkgs.pinentry-curses)
        ];

      xdg.configFile."keepassxc/keepassxc.ini" = lib.mkIf (hasMonitor && hasKeyboard) {
        text = ''
          [General]
          ConfigVersion=2
          NumberOfRememberedLastDatabases=1

          [GUI]
          ApplicationTheme=classic
          ColorPasswords=true
          MinimizeOnClose=true
          MinimizeToTray=true
          MinimizeOnStartup=true
          MonospaceNotes=true
          ShowTrayIcon=true
          TrayIconAppearance=monochrome-light

          [PasswordGenerator]
          AdvancedMode=true
          Length=32
          Logograms=true

          [Security]
          Security_HideNotes=true
        '';
      };

      systemd.user.services.keepassxc = lib.mkIf (hasMonitor && hasKeyboard) {
        Unit.Description = "KeePassXC daemon";
        Service.ExecStart = "${pkgs.keepassxc}/bin/keepassxc";
        Install.WantedBy = [ "tray.target" ];
      };
    };
  };
}
