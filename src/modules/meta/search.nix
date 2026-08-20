{
  machines.nixosModules.search = { lib, ... }: {
    options.dot.search = {
      type = lib.mkOption {
        type = lib.types.enum [ "searxng" ];
        description = "Search provider type";
      };

      url = lib.mkOption {
        type = lib.types.str;
        description = "URL of the active search engine instance.";
      };
    };
  };
}
