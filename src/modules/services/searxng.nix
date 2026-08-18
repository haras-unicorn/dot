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
        limiterSettings.enabled = false;

        settings = {
          server = {
            port = port;
            bind_address = address;
            secret_key = "local-only";
          };
          use_default_settings.engines.remove = [
            "google"
            "duckduckgo"
            "ahmie"
            "torch"
          ];
          engines = (
            builtins.map
              (name: {
                name = builtins.replaceStrings [ "_" ] [ " " ] name;
                engine = name;
                disabled = false;
              })
              [
                "bing"
                "startpage"
                "brave"
                "wikipedia"
                "arxiv"
                "crossref"
                "semantic_scholar"
              ]
          );
        };
      };
    };
}
