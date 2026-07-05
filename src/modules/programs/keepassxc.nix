{
  machines.homeModules.keepassxc =
    {
      osConfig,
      config,
      lib,
      pkgs,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;
    in
    lib.mkIf hardware.interface {
      dot.desktop.windowrules = [
        {
          rule = "float";
          selector = "class";
          arg = "org.keepassxc.KeePassXC";
        }
      ];

      programs.keepassxc.enable = true;
      programs.keepassxc.settings = {
        General = {
          ConfigVersion = 2;
          NumberOfRememberedLastDatabases = 1;

        };
        GUI = {
          ApplicationTheme = "classic";
          ColorPasswords = true;
          MinimizeOnClose = true;
          MinimizeToTray = true;
          MinimizeOnStartup = true;
          MonospaceNotes = true;
          ShowTrayIcon = true;
          TrayIconAppearance = "monochrome-light";
        };
        PasswordGenerator = {
          AdvancedMode = true;
          Length = 32;
          Logograms = true;

        };
        Security = {
          Security_HideNotes = true;
        };
      };

      systemd.user.services.keepassxc = {
        Install.WantedBy = [ "graphical-session.target" ];
        Unit.After = [ "graphical-session.target" ];
        Unit.Requires = [ "graphical-session.target" ];
        Service.ExecStart = lib.getExe config.programs.keepassxc.package;
      };
    };
}
