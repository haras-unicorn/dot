{ pkgs
, config
, lib
, ...
}:

# FIXME: duckduckgo - note that last time it was overwriting it
# NOTE: https://github.com/arkenfox/user.js/wiki
# NOTE: https://github.com/nix-community/nur-combined/blob/master/repos/rycee/pkgs/firefox-addons/addons.json

let
  hasMonitor = config.dot.hardware.monitor.enable;

  fork = {
    package = pkgs.firefox;
    bin = "firefox";
    stylix = "firefox";
    stylixGnomeTheme = "firefoxGnomeTheme";
    home = "firefox";
  };

  userjs = ''
    ${builtins.readFile ./user.js}

    // set ui dark theme same as stylix
    ${if config.stylix.polarity == "dark" then ''
    user_pref("ui.systemUsesDarkTheme", 1);
    '' else ''
    user_pref("ui.systemUsesDarkTheme", 0);
    ''}
  '';
in
{
  branch.homeManagerModule.homeManagerModule = lib.mkIf (hasMonitor) {
    dot.browser = { package = fork.package; bin = fork.bin; };

    stylix.targets.${fork.stylix} = {
      profileNames = [ "personal" ];
      ${fork.stylixGnomeTheme}.enable = fork.stylix != "floorp";
    };

    programs.${fork.home} = {
      enable = true;
      package = fork.package;
      profiles = {
        personal = {
          name = "personal";
          id = lib.mkForce 0;
          isDefault = lib.mkForce true;
          extensions.packages = [
            pkgs.nur.repos.rycee.firefox-addons.ublock-origin
            pkgs.nur.repos.rycee.firefox-addons.darkreader
            pkgs.nur.repos.rycee.firefox-addons.vimium-c
            pkgs.nur.repos.rycee.firefox-addons.i-dont-care-about-cookies
          ];
        };
        alternative = {
          name = "alternative";
          id = lib.mkForce 1;
          isDefault = lib.mkForce false;
          extensions.packages = [
            pkgs.nur.repos.rycee.firefox-addons.ublock-origin
            pkgs.nur.repos.rycee.firefox-addons.darkreader
            pkgs.nur.repos.rycee.firefox-addons.vimium-c
            pkgs.nur.repos.rycee.firefox-addons.i-dont-care-about-cookies
          ];
        };
      };
    };

    home.file = lib.mkIf (fork.home == "firefox") {
      ".mozilla/firefox/personal/user.js".text = userjs;
      ".mozilla/firefox/alternative/user.js".text = userjs;
    };

    xdg.desktopEntries = {
      myfooddata = {
        name = "My Food Data";
        exec = "${fork.package}/bin/${fork.bin} --new-window https://myfooddata.com";
        terminal = false;
      };
    };
  };
}
