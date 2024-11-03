{ pkgs
  # , self
, ...
}:

# TODO: lutris packages

{
  shared = {
    dot = {
      desktopEnvironment.sessionVariables = { MANGOHUD = 1; };
    };
  };

  system = {
    programs.steam.enable = true;
    programs.steam.extest.enable = true;
    programs.steam.protontricks.enable = true;
    programs.steam.extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];

    programs.gamemode.enable = true;
  };

  home = {
    programs.mangohud.enable = true;
    programs.mangohud.enableSessionWide = true;
  };
}
