{
  libAttrs.test.modules.external =
    { lib, ... }:
    {
      options.dot.test = {
        external = lib.mkOption {
          default = { };
          description = "External services";
          type = lib.types.attrsOf (
            lib.types.submodule (
              { config, ... }:
              {
                options = {
                  node = lib.mkOption {
                    type = lib.types.str;
                    description = "Service node";
                  };

                  protocol = lib.mkOption {
                    type = lib.types.str;
                    description = "Service protocol";
                  };

                  connection = lib.mkOption {
                    description = "Service connection";
                    default = null;
                    type = lib.types.nullOr (
                      lib.types.submodule {
                        options = {
                          address = lib.mkOption {
                            type = lib.types.str;
                            description = "Address of the service";
                          };

                          port = lib.mkOption {
                            type = lib.types.port;
                            description = "Port of the services";
                          };
                        };
                      }
                    );
                  };

                  auth = lib.mkOption {
                    description = "Service authentication";
                    default = null;
                    type = lib.types.nullOr (
                      lib.types.submodule {
                        options = {

                          user = lib.mkOption {
                            type = lib.types.str;
                            description = "Service authentication user";
                          };

                          password = lib.mkOption {
                            type = lib.types.str;
                            description = "Service authentication password";
                          };
                        };
                      }
                    );
                  };

                  path = lib.mkOption {
                    type = lib.types.str;
                    default = "";
                    description = "Service absolute path";
                  };

                  parameters = lib.mkOption {
                    type = lib.types.attrsOf lib.types.raw;
                    default = { };
                    description = "Additional service parameters";
                  };

                  url = lib.mkOption {
                    type = lib.types.raw;
                    description = "Service URL";
                    default =
                      let
                        protocol = "${config.protocol}://";

                        auth = if config.auth != null then "${config.auth.user}:${config.auth.password}" else "";

                        delimiter = if auth != "" && connection != "" then "@" else "";

                        connection =
                          if config.connection != null then
                            "${config.connection.address}:${builtins.toString config.connection.port}"
                          else
                            "";

                        path = config.path;

                        parameters =
                          if config.parameters == { } then
                            ""
                          else
                            "?"
                            + builtins.concatStringsSep "&" (
                              builtins.map ({ name, value }: "${name}=${builtins.toString value}") (
                                lib.attrsToList config.parameters
                              )
                            );
                      in
                      protocol + auth + delimiter + connection + path + parameters;
                  };
                };
              }
            )
          );
        };
      };
    };
}
