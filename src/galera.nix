{ pkgs, lib, config, ... }:

# TODO: mysqlbackup

# NOTE: run `sudo galera_new_cluster` when all nodes are down

let
  host = config.dot.host;

  hasNetwork = config.dot.hardware.network.enable;
  isCoordinator = config.dot.ddb.coordinator;

  wsrepProviderOptions = builtins.concatStringsSep ";" [
    "socket.ssl_ca=/etc/mysql/ca.crt"
    "socket.ssl_cert=/etc/mysql/host.crt"
    "socket.ssl_key=/etc/mysql/host.key"
    "pc.weight=${builtins.toString (if isCoordinator then 100 else 1)}"
    "pc.announce_timeout=PT10S"
  ];
in
{
  branch.nixosModule.nixosModule = {
    options.dot = {
      ddb.coordinator = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
    };

    config = lib.mkIf (hasNetwork && false) {
      systemd.services.mysql = {
        path = with pkgs; [
          bash
          gawk
          gnutar
          gzip
          inetutils
          iproute2
          netcat
          procps
          pv
          rsync
          socat
          stunnel
          which
        ];
      };

      networking.firewall.allowedTCPPorts = [ 3306 4444 4567 4568 ];
      networking.firewall.allowedUDPPorts = [ 4567 ];

      services.mysql.enable = true;
      systemd.services.mysql.after = [ "nebula@nebula.service" ];
      systemd.services.mysql.wants = [ "nebula@nebula.service" ];
      services.mysql.package = pkgs.mariadb;
      services.mysql.initialScript = lib.mkIf isCoordinator "/etc/mysql/init.sql";
      services.mysql.configFile = pkgs.writeText "my.cnf" ''
        [mysqld]
        bind_address="0.0.0.0"

        binlog_format="ROW"

        enforce_storage_engine="InnoDB"
        innodb_autoinc_lock_mode="2"

        wsrep_on="ON"
        wsrep_debug="NONE"
        wsrep_provider="${pkgs.mariadb-galera}/lib/libgalera_smm.so"
        wsrep_provider_options="${wsrepProviderOptions}"

        !includedir /etc/mysql/conf.d/
      '';
      sops.secrets."shared.ddb.ca.pub" = {
        path = "/etc/mysql/ca.crt";
        owner = "mysql";
        group = "mysql";
        mode = "0400";
      };
      sops.secrets."${host}.ddb.key.pub" = {
        path = "/etc/mysql/host.crt";
        owner = "mysql";
        group = "mysql";
        mode = "0400";
      };
      sops.secrets."${host}.ddb.key" = {
        path = "/etc/mysql/host.key";
        owner = "mysql";
        group = "mysql";
        mode = "0400";
      };
      sops.secrets."${host}.ddb.cnf" = {
        path = "/etc/mysql/conf.d/host.cnf";
        owner = "mysql";
        group = "mysql";
        mode = "0400";
      };
      sops.secrets."${host}.ddb.sql" = lib.mkIf isCoordinator {
        path = "/etc/mysql/init.sql";
        owner = "mysql";
        group = "mysql";
        mode = "0400";
      };
    };
  };
}
