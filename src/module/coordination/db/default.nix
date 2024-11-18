{ pkgs, host, lib, config, ... }:

let
  hasNetwork = config.dot.hardware.network.enable;
  isCoordinator = config.dot.db.coordinator.enable;

  wsrepProviderOptions = builtins.concatStringsSep ";" [
    "socket.ssl_ca=/etc/mysql/ca.crt"
    "socket.ssl_cert=/etc/mysql/host.crt"
    "socket.ssl_key=/etc/mysql/host.key"
    "pc.weight=${if isCoordinator then 100 else 1}"
  ];
in
{
  options = {
    db.coordinator.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = {
    system = lib.mkIf (hasNetwork) {
      services.mysql.enable = true;
      services.mysql.package = pkgs.mariadb;
      services.mysql.initialScript = lib.mkIf isCoordinator "/etc/mysql/init.sql";
      services.mysql.configFile = pkgs.writeText "my.cnf" ''
        [mysqld]
        wsrep_on=ON
        wsrep_provider=${pkgs.mariadb-galera}/lib/libgalera_smm.so
        wsrep_sst_method=mariabackup
        wsrep_provider_options="${wsrepProviderOptions}"

        !includedir /etc/mysql/conf.d/
      '';
      sops.secrets."shared.db.ca.pub" = {
        path = "/etc/mysql/ca.crt";
        owner = "mysql";
        group = "mysql";
        mode = "0400";
      };
      sops.secrets."${host}.db.key.pub" = {
        path = "/etc/mysql/host.crt";
        owner = "mysql";
        group = "mysql";
        mode = "0400";
      };
      sops.secrets."${host}.db.key" = {
        path = "/etc/mysql/host.key";
        owner = "mysql";
        group = "mysql";
        mode = "0400";
      };
      sops.secrets."${host}.db.cnf" = {
        path = "/etc/mysql/conf.d/host.cnf";
        owner = "mysql";
        group = "mysql";
        mode = "0400";
      };
      sops.secrets."${host}.db.sql" = lib.mkIf isCoordinator {
        path = "/etc/mysql/init.sql";
        owner = "mysql";
        group = "mysql";
        mode = "0400";
      };
    };
  };
}
