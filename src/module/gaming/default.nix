{ pkgs, config, lib, user, ... }:

# TODO: lutris packages

let
  hasMonitor = config.dot.hardware.monitor.enable;
  hasMouse = config.dot.hardware.mouse.enable;
  hasKeyboard = config.dot.hardware.keyboard.enable;
in
{
  shared = lib.mkIf (hasMonitor && hasMouse && hasKeyboard) {
    dot = {
      desktopEnvironment.sessionVariables = { MANGOHUD = 1; };
    };
  };

  system = lib.mkIf (hasMonitor && hasMouse && hasKeyboard) {
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

  home = lib.mkIf (hasMonitor && hasMouse && hasKeyboard) {
    programs.mangohud.enable = true;
    programs.mangohud.enableSessionWide = true;
  };
}
