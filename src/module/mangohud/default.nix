{ ... }:

{
  shared = {
    dot = {
      desktopEnvironment.sessionVariables = { MANGOHUD = 1; };
    };
  };

  home = {
    programs.mangohud.enable = true;
    programs.mangohud.enableSessionWide = true;
  };
}
