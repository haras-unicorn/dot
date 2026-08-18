{ lib, ... }:

{
  options.dot.services.search = {
    url = lib.mkOption {
      type = lib.types.str;
      description = "URL of the active search engine instance.";
    };
  };
}
