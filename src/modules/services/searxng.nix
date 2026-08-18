{
  machines.nixosModules.searxng =
    {
      config,
      lib,
      ...
    }:
    let
      address = "127.0.0.1";
      port = 8889;

      hardware = config.dot.hardware;
    in
    lib.mkIf hardware.network {
      dot.search.url = "http://${address}:${builtins.toString port}";

      services.searx = {
        enable = true;

        configureUwsgi = false;
        redisCreateLocally = false;

        settings = {
          search.formats = [
            "html"
            "json"
          ];
          server = {
            port = port;
            bind_address = address;
            secret_key = "local-only";
            limiter = false;
          };
          use_default_settings.engines.remove = [
            "ahmia"
            "torch"
            "wikidata"
          ];
          engines = (
            builtins.map
              (
                engine:
                if builtins.isAttrs engine then
                  engine
                  // {
                    name = engine.name or builtins.replaceStrings [ "_" ] [ " " ] engine;
                    disabled = false;
                    inactive = false;
                  }
                else
                  {
                    inherit engine;
                    name = builtins.replaceStrings [ "_" ] [ " " ] engine;
                    disabled = false;
                    inactive = false;
                  }
              )
              [
                # general
                "findfiles"
                "freesound"
                "piratebay"
                "neocities"
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
