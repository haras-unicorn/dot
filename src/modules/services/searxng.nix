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
      dot.services.search.url = "http://${address}:${builtins.toString port}";

      services.searx = {
        enable = true;

        configureUwsgi = false;
        redisCreateLocally = false;
        limiterSettings.enabled = false;

        settings.server.port = port;
        settings.server.bind_address = address;
        settings.use_default_settings = true;
        settings.engines =
          (lib.listToAttrs (
            map
              (name: {
                name = name;
                value.enabled = true;
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
          ))
          // lib.listToAttrs (
            map
              (name: {
                name = name;
                value.enabled = false;
              })
              [
                "google"
                "duckduckgo"
              ]
          );
      };
    };
}
