# SearXNG - a privacy-respecting metasearch engine
#
# Aggregates results from Bing, Startpage, Brave, Wikipedia, and
# many other sources. Queries are never logged or profiled.
{
  machines.nixosModules.searxng =
    {
      config,
      lib,
      ...
    }:
    let
      hardware = config.dot.hardware;
      searchUrl = config.dot.services.search.url;
    in
    lib.mkIf hardware.network {
      services.searx = {
        enable = true;

        settings.server.port = config.dot.services.search.searxng.port;
        settings.server.bind_address = "127.0.0.1";

        # Built-in server — no uwsgi, no redis needed for local use
        configureUwsgi = false;
        redisCreateLocally = false;

        limiterSettings.enabled = false;

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
