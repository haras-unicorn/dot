{ pkgs
, config
, lib
, nixpkgs
, ...
}:

# FIXME: hardware acceleration
# FIXME: duckduckgo - note that last time it was overwriting it
# NOTE: https://github.com/arkenfox/user.js/wiki
# NOTE: https://github.com/nix-community/nur-combined/blob/master/repos/rycee/pkgs/firefox-addons/addons.json

let
  hasMonitor = config.dot.hardware.monitor.enable;

  # fork = {
  #   package = pkgs.floorp;
  #   bin = "floorp";
  #   stylix = "floorp";
  #   stylixGnomeTheme = "firefoxGnomeTheme";
  #   home = "floorp";
  # };
  fork = {
    package = pkgs.firefox;
    bin = "firefox";
    stylix = "firefox";
    stylixGnomeTheme = "firefoxGnomeTheme";
    home = "firefox";
  };

  arkenfox-userjs = nixpkgs.fetchFromGitHub {
    owner = "arkenfox";
    repo = "user.js";
    rev = "v110.0";
    sha256 = "";
  };
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
          extensions.packages = [
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
      ".mozilla/firefox/personal/user.js".text = ''
        ${builtins.readFile "${arkenfox-userjs}/user.js"}
        ${builtins.readFile ./user-overrides.js}
      '';
      ".mozilla/firefox/alternative/user.js".text = ''
        ${builtins.readFile "${arkenfox-userjs}/user.js"}
        ${builtins.readFile ./user-overrides.js}
      '';
    };

    xdg.desktopEntries = {
      myfooddata = {
        name = "My Food Data";
        exec = "${fork.package}/bin/${fork.bin} -ssb --new-window https://myfooddata.com";
        terminal = false;
      };
    };
  };
}
