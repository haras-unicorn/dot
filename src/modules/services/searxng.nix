{
  machines.nixosModules.searxng =
    {
      config,
      lib,
      ...
    }:
    let
      address = "127.0.0.1";
      port = 8888;

      hardware = config.dot.hardware;
    in
    lib.mkIf hardware.network {
      dot.search.url = "http://${address}:${builtins.toString port}";

      services.searx = {
        enable = true;

        configureUwsgi = false;
        redisCreateLocally = false;
        limiterSettings.enabled = false;

        settings.server.port = port;
        settings.server.bind_address = address;
        settings.use_default_settings = true;
        settings.engines =
          (builtins.map
            (name: {
              inherit name;
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
          )
          ++ (builtins.map
            (name: {
              inherit name;
              engine = name;
              disabled = true;
            })
            [
              "google"
              "duckduckgo"
            ]
          );
      };
    };
}
