{ pkgs, config, ... }:

{
  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = true;

  environment.systemPackages = with pkgs; [
    libraspberrypi
    raspberrypi-eeprom
    vim-full
    git
    man-pages
    man-pages-posix
    openssl
    age
    ssh-to-age
    sops
  ];

  services.postgresql.enable = true;
  services.postgresql.package = pkgs.postgresql_14;
  services.postgresql.extraPlugins = with config.services.postgresql.package.pkgs; [
    timescaledb
  ];
  services.postgresql.settings.shared_preload_libraries = "timescaledb";
  services.postgresql.ensureDatabases = [ "mess" ];
  services.postgresql.ensureUsers = [
    {
      name = "mess";
      ensurePermissions = {
        "DATABASE mess" = "ALL PRIVILEGES";
      };
      ensureClauses = {
        login = true;
      };
    }
  ];
  services.postgresql.authentication = pkgs.lib.mkOverride 10 ''
    # NOTE: do not remove local privileges because that breaks timescaledb
    # TYPE    DATABASE    USER        ADDRESS         METHOD        OPTIONS
    local     all         all                         trust
    host      all         all         samehost        trust
    hostssl   all         all         192.168.1.0/24  scram-sha-256
  '';
  services.postgresql.enableTCPIP = true;
  services.postgresql.port = 5432;
  networking.firewall.allowedTCPPorts = [ 5432 ];
  services.postgresql.settings.ssl = "on";
  services.postgresql.initialScript = "/var/lib/postgresql/14/passwords.sql";
}
