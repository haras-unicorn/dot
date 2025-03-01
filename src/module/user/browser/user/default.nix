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
    browser = { package = pkgs.librewolf; bin = "librewolf"; };
  };

  home = lib.mkIf (hasMonitor) {
    programs.firefox.enable = true;
    programs.firefox.package = pkgs.librewolf;

    stylix.targets.firefox.profileNames = [ "personal" ];
    stylix.targets.firefox.firefoxGnomeTheme.enable = true;
    programs.firefox.profiles = {
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
    home.file.".mozilla/firefox/personal/user.js".text = ''
      ${builtins.readFile "${arkenfox-userjs}/user.js"}
      ${builtins.readFile ./user-overrides.js}
    '';
    home.file.".mozilla/firefox/alternative/user.js".text = ''
      ${builtins.readFile "${arkenfox-userjs}/user.js"}
      ${builtins.readFile ./user-overrides.js}
    '';

    xdg.desktopEntries = {
      myfooddata = {
        name = "My Food Data";
        exec = "${pkgs.firefox}/bin/firefox -ssb --new-window https://myfooddata.com";
        terminal = false;
      };
    };
  };
}
