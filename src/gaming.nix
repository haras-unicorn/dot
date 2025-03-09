{ pkgs, config, lib, user, ... }:

# TODO: lutris packages

let
  hasMonitor = config.dot.hardware.monitor.enable;
  hasMouse = config.dot.hardware.mouse.enable;
  hasKeyboard = config.dot.hardware.keyboard.enable;
in
{
  branch.nixosModule.nixosModule = lib.mkIf (hasMonitor && hasMouse && hasKeyboard) {
    programs.steam.package = pkgs.steam.override {
      extraEnv = {
        MANGOHUD = "1";
      };
    };
    programs.steam.enable = true;
    programs.steam.extest.enable = true;
    programs.steam.protontricks.enable = true;
    programs.steam.extraCompatPackages = [
      pkgs.proton-ge-bin
    ];

    users.users.${user}.extraGroups = [
      "gamemode"
    ];

    programs.gamemode.enable = true;
  };

  branch.homeManagerModule.homeManagerModule = lib.mkIf (hasMonitor && hasMouse && hasKeyboard) {
    desktopEnvironment.windowrules = [{
      rule = "float";
      selector = "class";
      xselector = "wm_class";
      arg = "steam";
      xarg = "steam";
    }];

    programs.mangohud.enable = true;

    systemd.user.services.steam = {
      Unit = {
        Description = "Steam daemon";
        Requires = "tray.target";
        After = [ "graphical-session-pre.target" "tray.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service.ExecStart = "${pkgs.steam}/bin/steam -nochatui -nofriendsui -silent";
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
