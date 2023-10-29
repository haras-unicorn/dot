{ pkgs, config, userjs, ... }:

# NOTE: https://github.com/arkenfox/user.js/wiki

{
  home.sessionVariables = {
    BROWSER = "${pkgs.firefox-bin}/bin/firefox";
  };

  wayland.windowManager.hyprland.extraConfig = ''
    bind = super, w, exec, ${pkgs.firefox-bin}/bin/firefox
  '';

  programs.firefox.enable = true;
  programs.firefox.package = pkgs.firefox-bin;

  programs.firefox.profiles = {
    personal = {
      id = 0;
      name = "Personal";
      isDefault = true;
      extensions = with config.nur.repos.rycee.firefox-addons; [
        ublock-origin
        darkreader
        vimium
      ];
      search = {
        default = "Google";
        engines = {
          "Bing".metaData.hidden = true;
          "Google".metaData.alias = "@g";
          "Nix Packages" = {
            urls = [{
              template = "https://search.nixos.org/packages";
              params = [
                { name = "type"; value = "packages"; }
                { name = "query"; value = "{searchTerms}"; }
              ];
            }];

            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = [ "@np" ];
          };
          "NixOS Wiki" = {
            urls = [{ template = "https://nixos.wiki/index.php?search={searchTerms}"; }];
            iconUpdateURL = "https://nixos.wiki/favicon.png";
            updateInterval = 24 * 60 * 60 * 1000; # every day
            definedAliases = [ "@nw" ];
          };
        };
      };
    };
  };

  xdg.configFile.".mozilla/firefox/personal/user.js".text = ''
    ${builtins.readFile "${userjs}/user.js"}

    ${builtins.readFile ./user.js}
  '';
}
