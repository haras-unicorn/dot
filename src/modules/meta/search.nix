# Search engine meta module — declares shared search options.
# Consumers (browsers, zeroclaw) read from dot.services.search.*.
# Providers (searxng) set the underlying options.
{ lib, ... }:
{
  options.dot.services.search = {
    searxng = {
      port = lib.mkOption {
        type = lib.types.port;
        default = 8889;
        description = "Port for the SearXNG instance.";
      };
    };

    url = lib.mkOption {
      type = lib.types.str;
      default = "http://127.0.0.1:${builtins.toString config.dot.services.search.searxng.port}";
      description = "URL of the active search engine instance.";
    };
  };
}
