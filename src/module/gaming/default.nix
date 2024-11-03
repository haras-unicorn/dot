{ pkgs, config, lib, ... }:

# TODO: lutris packages

{
  shared = lib.mkIf config.dot.hardware.monitor.enable {
    dot = {
      desktopEnvironment.sessionVariables = { MANGOHUD = 1; };
    };
  };

  system = lib.mkIf config.dot.hardware.monitor.enable {
    programs.steam.enable = true;
    programs.steam.extest.enable = true;
    programs.steam.protontricks.enable = true;
    programs.steam.extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];

    programs.gamemode.enable = true;
  };

  home = lib.mkIf config.dot.hardware.monitor.enable {
    programs.mangohud.enable = true;
    programs.mangohud.enableSessionWide = true;
  };
}
