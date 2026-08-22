{
  machines.nixosModules.searxng =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      address = "127.0.0.1";
      port = 8889;

      hardware = config.dot.hardware;

      searxng = pkgs.searxng.overridePythonAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ./raise-api-limit.patch ];
      });

      failingEngines = [
        # NOTE: these don't even pass a start check
        "torch"
        "ahmia"
        "wikidata"
        # NOTE: not sure why this didn't work
        "google cse"
        "google cse images"
        # NOTE: immediate captcha
        "startpage"
        "startpage news"
        "startpage images"
        # NOTE: immediate "too many requests"
        "brave"
        "brave.images"
        "brave.videos"
        "brave.news"
      ];
      defaultEngines = builtins.filter ({ name, ... }: !(builtins.elem name failingEngines)) (
        builtins.fromJSON (builtins.readFile ./engines.json)
      );
    in
    lib.mkIf hardware.network {
      dot.search = {
        type = "searxng";
        url = "http://${address}:${builtins.toString port}";
      };

      services.redis.package = pkgs.valkey;

      services.searx = {
        enable = true;

        package = searxng;

        configureUwsgi = false;
        redisCreateLocally = true;

        settings = {
          search.formats = [
            "html"
            "json"
          ];

          server = {
            port = port;
            bind_address = address;
            secret_key = "local-only";
            limiter = true;
          };

          use_default_settings.engines.remove = failingEngines;

          engines =
            defaultEngines
            ++ (builtins.map
              (
                engine:
                if builtins.isAttrs engine then
                  let
                    name = engine.name or (builtins.replaceStrings [ "_" ] [ " " ] engine.engine);
                    shortcut = engine.shortcut or (builtins.substring 0 4 name);
                  in
                  engine
                  // {
                    inherit name shortcut;
                    disabled = false;
                    inactive = false;
                  }
                else
                  let
                    name = builtins.replaceStrings [ "_" ] [ " " ] engine;
                    shortcut = builtins.substring 0 4 engine;
                  in
                  {
                    inherit engine name shortcut;
                    disabled = false;
                    inactive = false;
                  }
              )
              [
                # general
                "piratebay"
                "steam"

                # wikis and academic
                "crossref"
                "semantic_scholar"
                "annas_archive"
                "zlibrary"
                "openlibrary"
                "hackernews"
                "alpinelinux"
                "archlinux"
                {
                  name = "nixos wiki";
                  engine = "mediawiki";
                  base_url = "https://wiki.nixos.org/";
                }

                # packages
                "crates"
                "npm"
                "docker_hub"
                "huggingface"
                "github"
                {
                  engine = "github_code";
                  shortcut = "gitc";
                  ghc_auth = {
                    type = "none";
                    token = "token";
                  };
                }
                {
                  engine = "gitlab";
                  base_url = "https://gitlab.com";
                }
                "sourcehut"
                {
                  name = "codeberg";
                  engine = "gitea";
                  base_url = "https://codeberg.org";
                }
              ]
            );
        };
      };
    };
}
