{ pkgs, host, ... }:

let
  wsrepProviderOptions = builtins.concatStringsSep ";" [
    "socket.ssl_key=/etc/mysql/host.key"
    "socket.ssl_cert=/etc/mysql/host.crt"
    "socket.ssl_ca=/etc/mysql/ca.crt"
  ];
in
{
  system = {
    services.mysql.enable = true;
    services.mysql.package = pkgs.mariadb_110;
    services.mysql.initialScript = "/etc/mysql/init.sql";
    services.mysql.configFile = pkgs.writeText "my.cnf" ''
      [mysqld]
      wsrep_on=ON
      wsrep_provider=${pkgs.mariadb-galera}/lib/libgalera_smm.so
      wsrep_sst_method=mariabackup
      wsrep_provider_options=${wsrepProviderOptions}

      !includedir /etc/mysql/conf.d/
    '';
    sops.secrets."${host}.mysql" = {
      path = "/etc/mysql/init.sql";
      owner = "mysql";
      group = "mysql";
      mode = "0400";
    };
    sops.secrets."${host}.mycnf" = {
      path = "/etc/mysql/conf.d/secret.cnf";
      owner = "mysql";
      group = "mysql";
      mode = "0400";
    };
    sops.secrets."shared.myca" = {
      path = "/etc/mysql/ca.crt";
      owner = "mysql";
      group = "mysql";
      mode = "0400";
    };
    sops.secrets."${host}.mycrt" = {
      path = "/etc/mysql/host.crt";
      owner = "mysql";
      group = "mysql";
      mode = "0400";
    };
    sops.secrets."${host}.mykey" = {
      path = "/etc/mysql/host.key";
      owner = "mysql";
      group = "mysql";
      mode = "0400";
    };
  };
}
