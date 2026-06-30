# NOTE: https://github.com/arkenfox/user.js/wiki
# NOTE: https://github.com/nix-community/nur-combined/blob/master/repos/rycee/pkgs/firefox-addons/addons.json
# TODO: https://addons.mozilla.org/en-US/firefox/addon/textarea-cache/

{
  machines.homeModules.firefox =
    {
      pkgs,
      config,
      osConfig,
      lib,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;

      package = pkgs.firefox;

      userJs = ''
        ${builtins.readFile ./user.js}

        // set ui dark theme same as stylix
        ${
          if config.stylix.polarity == "dark" then
            ''
              user_pref("ui.systemUsesDarkTheme", 1);
            ''
          else
            ''
              user_pref("ui.systemUsesDarkTheme", 0);
            ''
        }
      '';

      settings = builtins.fromJSON (
        builtins.readFile (
          pkgs.runCommand "settings"
            {
              buildInputs = [
                pkgs.nodejs
              ];
            }
            ''
              cat <<EOF | node - > $out
              settings = {};
              user_pref = (name, value) => settings[name] = value;
              ${userJs}
              console.log(JSON.stringify(settings));
              EOF
            ''
        )
      );

      # NOTE: just for future reference
      # searchJson = ''
      #   ${builtins.readFile ./search.json}
      # '';
      # searchJsonMozlz4 =
      #   pkgs.runCommand "wallpaper-image"
      #     {
      #       buildInputs = [
      #         pkgs.mozlz4a
      #       ];
      #     }
      #     ''
      #       cat <<EOF | mozlz4a - $out
      #       ${searchJson}
      #       EOF
      #     '';

      searchAttrs = builtins.fromJSON (builtins.readFile ./search.json);

      searchEngines = builtins.listToAttrs (
        builtins.map (
          engine:
          let
            fixedAttrsEngine = lib.mapAttrs' (name: value: {
              inherit value;
              name = builtins.replaceStrings [ "_" ] [ "" ] name;
            }) engine;
          in
          {
            name = fixedAttrsEngine.id;
            value = fixedAttrsEngine;
          }
        ) searchAttrs.engines
      );

      defaultSearchEngine = searchAttrs.metaData.defaultEngineId;

      extensions = [
        pkgs.nur.repos.rycee.firefox-addons.ublock-origin
        pkgs.nur.repos.rycee.firefox-addons.darkreader
        pkgs.nur.repos.rycee.firefox-addons.vimium-c
        pkgs.nur.repos.rycee.firefox-addons.i-dont-care-about-cookies
        pkgs.nur.repos.rycee.firefox-addons.bitwarden
      ];

      profileBase = {
        settings = settings;
        search.default = defaultSearchEngine;
        search.engines = searchEngines;
        search.force = true;
        extensions.force = true;
        extensions.packages = extensions;
      };
    in
    lib.mkIf hardware.interface {
      dot.programs.browser.package = package;

      stylix.targets.firefox = {
        profileNames = [
          "personal"
          "work"
          "alternative"
        ];
        firefoxGnomeTheme.enable = true;
      };

      programs.firefox = {
        enable = true;
        package = package;
        configPath = "${config.xdg.configHome}/mozilla/firefox";
        profiles = {
          personal = profileBase // {
            name = "personal";
            id = lib.mkForce 0;
            isDefault = lib.mkForce true;
          };
          alternative = profileBase // {
            name = "alternative";
            id = lib.mkForce 1;
            isDefault = lib.mkForce false;
          };
          work = profileBase // {
            name = "work";
            id = lib.mkForce 2;
            isDefault = lib.mkForce false;
          };
        };
      };

      xdg.desktopEntries = {
        firefox-work = {
          name = "Firefox (work)";
          exec = "${lib.getExe package} -P work";
          terminal = false;
        };
      };
    };
}
