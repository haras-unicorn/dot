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

  baseUserJs = pkgs.fetchFromGitHub {
    owner = "pyllyukko";
    repo = "user.js";
    rev = "2fb67fb8485cdfbd1fe1b9543cf04c789b6e63a9";
    sha256 = "";
  };

  userJs = ''
    ${builtins.readFile "${baseUserJs}/user.js"}
    ${builtins.readFile ./user-overrides.js}

    // set ui dark theme same as stylix
    ${if config.stylix.polarity == "dark" then ''
    user_pref("ui.systemUsesDarkTheme", 1);
    '' else ''
    user_pref("ui.systemUsesDarkTheme", 0);
    ''}

    // enable userContent.css
    user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
  '';

  userContentCss = ''
    // set dark theme same as stylix
    ${if config.stylix.polarity == "dark" then ''
    @-moz-document url-prefix("http"), url-prefix("https") {
      html {
        color-scheme: dark !important;
      }
    }
    '' else ''
    @-moz-document url-prefix("http"), url-prefix("https") {
      html {
        color-scheme: light !important;
      }
    }
    ''}
  '';
in
{
  config = {
    browser = { package = fork.package; bin = fork.bin; };
  };

  home = lib.mkIf (hasMonitor) {
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
          extensions = [
            pkgs.nur.repos.rycee.firefox-addons.ublock-origin
            pkgs.nur.repos.rycee.firefox-addons.darkreader
            pkgs.nur.repos.rycee.firefox-addons.vimium-c
            pkgs.nur.repos.rycee.firefox-addons.i-dont-care-about-cookies
          ];
        };
        alternarive = {
          name = "alternative";
          id = lib.mkForce 1;
          isDefault = lib.mkForce false;
          extensions = [
            pkgs.nur.repos.rycee.firefox-addons.ublock-origin
            pkgs.nur.repos.rycee.firefox-addons.darkreader
            pkgs.nur.repos.rycee.firefox-addons.vimium-c
            pkgs.nur.repos.rycee.firefox-addons.i-dont-care-about-cookies
          ];
        };
      };
    };

    home.file = lib.mkIf (fork.home == "firefox") {
      ".mozilla/firefox/personal/user.js".text = userJs;
      ".mozilla/firefox/alternative/user.js".text = userJs;

      ".mozilla/firefox/personal/userContent.css".text = userContentCss;
      ".mozilla/firefox/alternative/userContent.css".text = userContentCss;
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
