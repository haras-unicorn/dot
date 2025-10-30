{
  pkgs,
  config,
  lib,
  ...
}:

# TODO: lutris packages

let
  user = config.dot.user;

  hasMonitor = config.dot.hardware.monitor.enable;
  hasMouse = config.dot.hardware.mouse.enable;
  hasKeyboard = config.dot.hardware.keyboard.enable;
in
{
  branch.nixosModule.nixosModule = lib.mkIf (hasMonitor && hasMouse && hasKeyboard) {
    programs.steam.enable = true;
    programs.steam.protontricks.enable = true;
    programs.steam.extraCompatPackages = [
      pkgs.proton-ge-bin
    ];
    # NOTE: bitburner
    programs.steam.extraPackages = [
      pkgs.nss
      pkgs.gamemode
    ];

    users.users.${user}.extraGroups = [
      "gamemode"
    ];

    programs.gamemode.enable = true;
  };

  branch.homeManagerModule.homeManagerModule = lib.mkIf (hasMonitor && hasMouse && hasKeyboard) {
    dot.desktopEnvironment.windowrules = [
      {
        rule = "float";
        selector = "class";
        arg = "steam";
      }
    ];

    programs.mangohud.enable = true;

    systemd.user.services.steam = {
      Unit.Description = "Steam daemon";
      Service.ExecStart = "${pkgs.steam}/bin/steam -nochatui -nofriendsui -silent";
      Unit.After = [ "graphical-session.target" ];
      Unit.Requires = [ "graphical-session.target" ];
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
