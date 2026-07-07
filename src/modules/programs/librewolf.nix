# NOTE: https://github.com/nix-community/nur-combined/blob/master/repos/rycee/pkgs/firefox-addons/addons.json

{
  machines.homeModules.librewolf =
    {
      pkgs,
      config,
      osConfig,
      lib,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;

      package = pkgs.librewolf;

      textarea-cache = pkgs.stdenvNoCC.mkDerivation {
        name = "textarea-cache";
        version = "5.0.7";

        src = pkgs.fetchurl {
          url = "https://addons.mozilla.org/firefox/downloads/file/4581492/textarea_cache-5.0.7.xpi";
          hash = "sha256-YIPRyyYXfHC01IUSJT5ne6/QyP6ginG2JOYWcENT7Ng=";
        };

        dontUnpack = true;

        installPhase = ''
          install -Dm644 $src \
            $out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/textarea-cache-lite@wildsky.cc.xpi
        '';

        meta = {
          description = "Saves textarea content automatically for recovery";
          homepage = "https://addons.mozilla.org/en-US/firefox/addon/textarea-cache/";
          license = lib.licenses.mit;
          platforms = lib.platforms.all;
        };
      };

      extensions =
        with pkgs.nur.repos.rycee.firefox-addons;
        [
          ublock-origin
          darkreader
          vimium-c
          i-dont-care-about-cookies
          bitwarden
          keepassxc-browser
        ]
        ++ [ textarea-cache ];

      settings = {
        "privacy.clearOnShutdown.cookies" = false;
        "privacy.clearOnShutdown.sessions" = false;
        "privacy.clearOnShutdown.siteSettings" = false;
        "privacy.clearOnShutdown.history" = false;
        "privacy.clearOnShutdown_v2.cookiesAndStorage" = false;
        "privacy.clearOnShutdown_v2.siteSettings" = false;
        "privacy.clearOnShutdown_v2.historyFormDataAndDownloads" = false;
      };

      profile = {
        extensions.force = true;
        extensions.packages = extensions;
      };

      profiles = [
        "personal"
        "work"
        "alternative"
      ];
    in
    lib.mkIf hardware.interface {
      dot.programs.browser.package = package;

      stylix.targets.librewolf = {
        profileNames = profiles;
        firefoxGnomeTheme.enable = true;
      };

      programs.librewolf = {
        enable = true;
        inherit package settings;
        profiles = builtins.listToAttrs (
          lib.imap0 (id: name: {
            inherit name;
            value = profile // {
              inherit name id;
              isDefault = id == 0;
            };
          }) profiles
        );
      };

      xdg.desktopEntries = builtins.listToAttrs (
        builtins.map (name: {
          inherit name;
          value = {
            name = "LibreWolf (${name})";
            exec = "${lib.getExe package} --profile ${name}";
            terminal = false;
          };
        }) (builtins.tail profiles)
      );
    };
}
