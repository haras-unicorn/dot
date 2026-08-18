# Search engine meta module — declares shared search options.
# Consumers (browsers, zeroclaw) read from dot.services.search.*.
# Providers (searxng) set the underlying options.
{ lib, ... }:
{
  options.dot.services.search = {
    url = lib.mkOption {
      type = lib.types.str;
      description = "URL of the active search engine instance.";
    };
  };
}
