{ pkgs
, config
, lib
, arkenfox-userjs
, ...
}:

# FIXME: openai login
# FIXME: hardware acceleration
# FIXME: duckduckgo - note that last time it was overwriting it
# NOTE: https://github.com/arkenfox/user.js/wiki
# NOTE: https://github.com/nix-community/nur-combined/blob/master/repos/rycee/pkgs/firefox-addons/addons.json

let
  hasMonitor = config.dot.hardware.monitor.enable;
in
{
  config = {
    browser = { package = pkgs.firefox-bin; bin = "firefox"; };
  };

  home = lib.mkIf (hasMonitor) {
    programs.firefox.enable = true;
    programs.firefox.package = pkgs.firefox-bin;
    programs.firefox.profiles = {
      personal = {
        id = 0;
        name = "personal";
        isDefault = true;
        extensions = [
          pkgs.nur.repos.rycee.firefox-addons.ublock-origin
          pkgs.nur.repos.rycee.firefox-addons.darkreader
          pkgs.nur.repos.rycee.firefox-addons.vimium-c
          pkgs.nur.repos.rycee.firefox-addons.i-dont-care-about-cookies
        ];
      };
      alternarive = {
        id = 1;
        name = "alternative";
        extensions = [
          pkgs.nur.repos.rycee.firefox-addons.ublock-origin
          pkgs.nur.repos.rycee.firefox-addons.darkreader
          pkgs.nur.repos.rycee.firefox-addons.vimium-c
          pkgs.nur.repos.rycee.firefox-addons.i-dont-care-about-cookies
        ];
      };
    };
    home.file.".mozilla/firefox/personal/user.js".text = ''
      ${builtins.readFile "${arkenfox-userjs}/user.js"}
      ${builtins.readFile ./user-overrides.js}
    '';
    home.file.".mozilla/firefox/alternative/user.js".text = ''
      ${builtins.readFile "${arkenfox-userjs}/user.js"}
      ${builtins.readFile ./user-overrides.js}
    '';
    stylix.firefox.profileNames = [ "personal" "alternative" ];

    xdg.desktopEntries = {
      myfooddata = {
        name = "My Food Data";
        exec = "${pkgs.firefox}/bin/firefox -ssb --new-window https://myfooddata.com";
        terminal = false;
      };
    };
  };
}
