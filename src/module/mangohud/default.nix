{ ... }:

{
  shared = {
    dot = {
      desktopEnvironment.sessionVariables = { MANGOHUD = 1; };
    };
  };

  home.shared = {
    programs.mangohud.enable = true;
    programs.mangohud.enableSessionWide = true;

    programs.mangohud.settingsPerApplication = {
      mpv = {
        no_display = true;
      };
    };
  };
}
