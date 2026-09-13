{ selfLib, ... }:

let
  host = "127.0.0.1";
  port = 3080;
in
{
  machines.nixosModules.librechat =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      hardware = config.dot.hardware;

      meilisearchMasterKey = "/etc/meilisearch/master-key";

      librechatEnv = "/etc/librechat/.env";

      librechatCredsKey = "/etc/librechat/creds-key";
      librechatCredsIv = "/etc/librechat/creds-iv";
      librechatJwtSecret = "/etc/librechat/jwt-secret";
      librechatJwtRefreshSecret = "/etc/librechat/jwt-refresh-secret";

      librechatCredentials = [
        {
          file = librechatCredsKey;
          env = "CREDS_KEY";
          length = 64;
        }
        {
          file = librechatCredsIv;
          env = "CREDS_IV";
          length = 32;
        }
        {
          file = librechatJwtSecret;
          env = "JWT_SECRET";
          length = 64;
        }
        {
          file = librechatJwtRefreshSecret;
          env = "JWT_REFRESH_SECRET";
          length = 64;
        }
      ];
    in
    lib.mkIf hardware.browser {
      dot.nixpkgs.allowUnfreePackageNames = [ "mongodb" ];

      services.meilisearch.masterKeyFile = meilisearchMasterKey;

      systemd.services.meilisearch-master-key-generator = {
        requiredBy = [ "meilisearch.service" ];
        before = [ "meilisearch.service" ];
        path = [ pkgs.openssl ];
        script = ''
          if [[ ! -f "${meilisearchMasterKey}" ]]; then
            mkdir -p "$(dirname "${meilisearchMasterKey}")"
            openssl rand -hex 32 > "${meilisearchMasterKey}"
            chmod 600 "${meilisearchMasterKey}"
          fi
        '';
      };

      systemd.services.librechat-credentials = {
        requiredBy = [ "librechat.service" ];
        before = [ "librechat.service" ];
        path = [ pkgs.openssl ];
        script = builtins.concatStringsSep "\n" (
          builtins.map (
            { file, length, ... }:
            # sh
            ''
              if [[ ! -f "${file}" ]]; then
                mkdir -p "$(dirname "${file}")"
                openssl rand -hex ${builtins.toString length} > "${file}"
                chmod 600 "${file}"
              fi
            ''
          ) librechatCredentials
        );
      };

      services.librechat = {
        enable = true;

        meilisearch.enable = true;

        enableLocalDB = true;

        env = {
          # NOTE: needed for first admin account
          ALLOW_REGISTRATION = true;
          ALLOW_SOCIAL_LOGIN = false;
          HOST = host;
          PORT = port;
        };

        # NOTE: it says credentialsFile but it just ends up
        # in EnvironmentFile
        credentialsFile = librechatEnv;

        credentials = builtins.listToAttrs (
          builtins.map ({ env, file, ... }: {
            name = env;
            value = file;
          }) librechatCredentials
        );

        settings = {
          version = "1.2.1";
          cache = true;

          webSearch = lib.optionalAttrs (config.dot.search.type == "searxng") {
            searchProvider = "searxng";
            searxngInstanceUrl = config.dot.search.url;
          };

          endpoints = {
            custom = [
              {
                name = "OpenRouter";
                apiKey = "\${OPENROUTER_KEY}";
                baseURL = selfLib.openrouter.profiles.default.url;
                models = {
                  default = [ selfLib.openrouter.profiles.default.model ];
                  fetch = true;
                };
                titleConvo = true;
                titleModel = selfLib.openrouter.profiles.default.model;
                # NOTE: needed for compatibility
                # https://www.librechat.ai/docs/configuration/librechat_yaml/ai_endpoints/openrouter
                dropParams = [ "stop" ];
                addParams = selfLib.openrouter.profiles.default.options;
              }
              {
                name = "OpenRouter (dev)";
                apiKey = "\${OPENROUTER_KEY}";
                baseURL = selfLib.openrouter.profiles.dev.url;
                models = {
                  default = [ selfLib.openrouter.profiles.dev.model ];
                  fetch = true;
                };
                titleConvo = true;
                titleModel = selfLib.openrouter.profiles.dev.model;
                # NOTE: needed for compatibility
                # https://www.librechat.ai/docs/configuration/librechat_yaml/ai_endpoints/openrouter
                dropParams = [ "stop" ];
                addParams = selfLib.openrouter.profiles.dev.options;
              }
            ];
          };

          interface = {
            privacyPolicy = {
              externalUrl = "https://librechat.ai/privacy-policy";
              openNewTab = true;
            };
          };
        };
      };
    };

  machines.homeModules.librechat =
    { osConfig, lib, ... }:
    let
      hardware = osConfig.dot.hardware;

      libreChat = osConfig.dot.programs.chromium.launch {
        name = "librechat";
        address = "http://${host}:${builtins.toString port}";
      };
    in
    {
      xdg.desktopEntries.librechat = lib.mkIf hardware.browser {
        name = "LibreChat";
        exec = lib.getExe libreChat;
        terminal = false;
      };
    };
}
