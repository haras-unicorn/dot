{ ... }:

{
  home.shared = {
    de.sessionVariables = { MANGOHUD = 1; };

    programs.mangohud.enable = true;
    programs.mangohud.enableSessionWide = true;

    programs.mangohud.settingsPerApplication = {
      mpv = {
        no_display = true;
      };
    };
  };
}
