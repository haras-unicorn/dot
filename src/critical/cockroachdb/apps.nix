{ self, ... }:

# TODO: login per host

{
  flake.nixosModules.critical-cockroachdb-apps =
    {
      lib,
      config,
      pkgs,
      utils,
      ...
    }:
    let
      hasNetwork = config.dot.hardware.network.enable;

      apps = builtins.mapAttrs (
        name: value: value // { certs = "/etc/cockroachdb/apps/${name}/certs"; }
      ) config.dot.database.apps;

      user = config.dot.host.user;
    in
    {
      config = lib.mkIf (hasNetwork && config.dot.cockroachdb.enable) {
        dot.database.instances = builtins.mapAttrs (name: value: {
          user = name;
          passwordSecret = "cockroach-${name}-pass";
          passwordPath = config.sops.secrets."cockroach-${name}-pass".path;
          name = name;
          parameters =
            "?sslmode=verify-full"
            + "&sslrootcert=${value.certs}/ca.crt"
            + "&sslcert=${value.certs}/client.${name}.crt"
            + "&sslkey=${value.certs}/client.${name}.key";
          urlPath = config.sops.secrets."cockroach-${name}-url".path;
          urlSecret = "cockroach-${name}-url";
        }) apps;

        sops.secrets = builtins.listToAttrs (
          lib.flatten (
            builtins.map (
              { name, value }:
              [
                {
                  name = "cockroach-${name}-pass";
                  value = {
                    owner = value.user;
                    group = value.group;
                    mode = "0400";
                  };
                }
                {
                  name = "cockroach-${name}-ca-public";
                  value = {
                    key = "cockroach-ca-public";
                    path = "${value.certs}/ca.crt";
                    owner = value.user;
                    group = value.group;
                    mode = "0400";
                  };
                }

                {
                  name = "cockroach-${name}-private";
                  value = {
                    path = "${value.certs}/client.${name}.key";
                    owner = value.user;
                    group = value.group;
                    mode = "0400";
                  };
                }
                {
                  name = "cockroach-${name}-public";
                  value = {
                    path = "${value.certs}/client.${name}.crt";
                    owner = value.user;
                    group = value.group;
                    mode = "0400";
                  };
                }
                {
                  name = "cockroach-${name}-url";
                  value = {
                    owner = value.user;
                    group = value.group;
                    mode = "0400";
                  };
                }
                {
                  name = "cockroach-${name}-init";
                  value = {
                    owner = config.services.cockroachdb.user;
                    group = config.services.cockroachdb.group;
                    mode = "0400";
                  };
                }
              ]
            ) (lib.attrsToList apps)
          )
        );

        cryl.sops.keys = lib.flatten (
          builtins.map (name: [
            "cockroach-${name}-pass"
            "cockroach-${name}-init"
            "cockroach-${name}-private"
            "cockroach-${name}-public"
            "cockroach-${name}-url"
          ]) (builtins.attrNames apps)
        );

        cryl.specification.generations =
          (builtins.map (name: {
            generator = "key";
            arguments = {
              name = "cockroach-${name}-pass";
            };
          }) (builtins.attrNames apps))
          ++ (lib.flatten (
            builtins.map (
              { name, value }:
              [
                {
                  generator = "key";
                  arguments = {
                    name = "cockroach-${name}-pass";
                  };
                }
                {
                  generator = "cockroach-client-cert";
                  arguments = {
                    renew = true;
                    ca_private = "cockroach-ca-private";
                    ca_public = "cockroach-ca-public";
                    private = "cockroach-${name}-private";
                    public = "cockroach-${name}-public";
                    user = name;
                  };
                }
                {
                  generator = "moustache";
                  arguments = {
                    name = "cockroach-${name}-url";
                    renew = true;
                    variables = {
                      COCKROACH_APP_PASS = "cockroach-${name}-pass";
                    };
                    template =
                      "postgresql://${name}:{{COCKROACH_APP_PASS}}"
                      + "@${config.services.cockroachdb.sql.address}"
                      + ":${builtins.toString config.services.cockroachdb.sql.port}"
                      + "/${name}"
                      + "?sslmode=verify-full"
                      + "&sslrootcert=${value.certs}/ca.crt"
                      + "&sslcert=${value.certs}/client.${name}.crt"
                      + "&sslkey=${value.certs}/client.${name}.key";
                  };
                }
                {
                  generator = "moustache";
                  arguments = {
                    name = "cockroach-${name}-init";
                    renew = true;
                    variables = {
                      COCKROACH_APP_PASS = "cockroach-${name}-pass";
                    }
                    // value.init.sql.secrets;
                    template = ''
                      create database if not exists ${name};

                      \c ${name}


                      create user if not exists ${name} password '{{COCKROACH_APP_PASS}}';

                      alter default privileges for all roles in schema public grant all on tables to ${name};
                      alter default privileges for all roles in schema public grant all on sequences to ${name};
                      alter default privileges for all roles in schema public grant all on functions to ${name};

                      grant all on all tables in schema public to ${name};
                      grant all on all sequences in schema public to ${name};
                      grant all on all functions in schema public to ${name};


                      alter default privileges for all roles in schema public grant all on tables to ${user};
                      alter default privileges for all roles in schema public grant all on sequences to ${user};
                      alter default privileges for all roles in schema public grant all on functions to ${user};

                      grant all on all tables in schema public to ${user};
                      grant all on all sequences in schema public to ${user};
                      grant all on all functions in schema public to ${user};


                      ${if value.init.sql.script != null then value.init.sql.script else ""}

                      ${if value.init.sql.file != null then "\i ${value.init.sql.file}" else ""}
                    '';
                  };
                }
              ]
            ) (lib.attrsToList apps)
          ));

        cryl.specification.imports = builtins.map (name: {
          importer = "vault-file";
          arguments = {
            path = self.lib.vault.shared;
            file = "cockroach-${name}-pass";
            allow_fail = true;
          };
        }) (builtins.attrNames apps);

        cryl.specification.exports = builtins.map (name: {
          exporter = "vault-file";
          arguments = {
            path = self.lib.vault.shared;
            file = "cockroach-${name}-pass";
          };
        }) (builtins.attrNames apps);

        services.cockroachdb.init.sql.files = lib.flatten (
          builtins.map (
            { name, value }:
            [
              config.sops.secrets."cockroach-${name}-init".path
            ]
          ) (lib.attrsToList apps)
        );

        services.cockroachdb.init.bash.scripts = builtins.filter builtins.isString (
          builtins.map (app: app.init.bash.script) (builtins.attrValues apps)
        );

        services.cockroachdb.init.bash.files = builtins.filter builtins.isString (
          builtins.map (app: app.init.bash.file) (builtins.attrValues apps)
        );
      };
    };
}
