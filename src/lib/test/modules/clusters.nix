{
  libAttrs.test.modules.clusters =
    { lib, config, ... }:
    let
      cfg = config.dot.test.clusters;

      clusters = builtins.map (
        name:
        cfg.${name}
        // {
          inherit name;
        }
      ) (builtins.filter (name: cfg.${name}.enable) (builtins.attrNames cfg));
    in
    {
      options.dot.test = {
        clusters = lib.mkOption {
          default = { };
          description = "Node clusters";
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                enable = lib.mkOption {
                  type = lib.types.bool;
                  default = true;
                  description = "Whether to enable this node cluster";
                };

                module = lib.mkOption {
                  type = lib.types.deferredModule;
                  description = "Common cluster node module";
                };

                amount = lib.mkOption {
                  type = lib.types.ints.unsigned;
                  description = "Amount of nodes";
                };
              };
            }
          );
        };
      };

      config = {
        nodes = builtins.listToAttrs (
          lib.flatten (
            builtins.map (
              cluster:
              builtins.map (number: {
                name = "${cluster.name}${builtins.toString number}";
                value =
                  { lib, ... }:
                  {
                    imports = [ cluster.module ];

                    options.dot.test = {
                      clusters = {
                        number = lib.mkOption {
                          type = lib.types.ints.unsigned;
                          description = "Cluster node number";
                        };
                      };
                    };

                    config = {
                      dot.test.clusters = {
                        number = number;
                      };
                    };
                  };
              }) (lib.range 1 cluster.amount)
            ) clusters
          )
        );
      };
    };
}
