{ pkgs, host, lib, config, ... }:

let
  hasNetwork = config.dot.hardware.network.enable;
  isArbitrator = config.dot.database.arbitrator.enable;

  wsrepProviderOptions = builtins.concatStringsSep ";" [
    "socket.ssl_key=/etc/mysql/host.key"
    "socket.ssl_cert=/etc/mysql/host.crt"
    "socket.ssl_ca=/etc/mysql/ca.crt"
  ];
in
{
  options = {
    database.arbitrator.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = {
    system = lib.mkIf (hasNetwork) {
      services.mysql.enable = true;
      services.mysql.package = pkgs.mariadb_110;
      services.mysql.initialScript = lib.mkIf isArbitrator "/etc/mysql/init.sql";
      services.mysql.configFile = pkgs.writeText "my.cnf" ''
        [mysqld]
        wsrep_on=ON
        wsrep_provider=${pkgs.mariadb-galera}/lib/libgalera_smm.so
        wsrep_sst_method=mariabackup
        wsrep_provider_options=${wsrepProviderOptions}

        !includedir /etc/mysql/conf.d/
      '';
      sops.secrets."${host}.sql" = lib.mkIf isArbitrator {
        path = "/etc/mysql/init.sql";
        owner = "mysql";
        group = "mysql";
        mode = "0400";
      };
      sops.secrets."${host}.galera" = {
        path = "/etc/mysql/conf.d/secret.cnf";
        owner = "mysql";
        group = "mysql";
        mode = "0400";
      };
      sops.secrets."shared.db.pub" = {
        path = "/etc/mysql/ca.crt";
        owner = "mysql";
        group = "mysql";
        mode = "0400";
      };
      sops.secrets."${host}.db.pub" = {
        path = "/etc/mysql/host.crt";
        owner = "mysql";
        group = "mysql";
        mode = "0400";
      };
      sops.secrets."${host}.db" = {
        path = "/etc/mysql/host.key";
        owner = "mysql";
        group = "mysql";
        mode = "0400";
      };
    };
  };
}
