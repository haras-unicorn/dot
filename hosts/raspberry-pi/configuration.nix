{ pkgs, config, ... }:

let
  mkCertificateCommand = { name, subject, ca }: ''
    #!/usr/bin/env bash
  
    openssl genpkey -algorithm ED25519 \
      -out /etc/ssl/certs/${name}.key;

    openssl req -new \
      -key /etc/ssl/certs/${name}.key \
      -out /etc/ssl/certs/${name}.csr \
      -subj "/CN=${subject}";

    openssl x509 -req -in ${name}.csr \
      -CA /etc/ssl/certs/${ca}.crt -CAkey /etc/ssl/certs/${ca}.key -CAcreateserial \
      -out /etc/ssl/certs/${name}.crt \
      -days 400;
  '';

  mkCertificate = { name, subject, ca }:
    pkgs.runCommandLocal name { } mkCertificateCommand {
      name = name;
      subject = subject;
      ca = ca;
    };
in
{
  nix.package = pkgs.nixFlakes;
  nix.extraOptions = "experimental-features = nix-command flakes";
  nixpkgs.config = import ../../assets/.config/nixpkgs/config.nix;

  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = true;
  networking.hostName = "pi";

  # environment.etc."ssl/certs/mess/ca.crt" = import ../../artifacts/ca.crt;
  # environment.etc."ssl/certs/mess/ca.key" = import ../../artifacts/ca.key;
  environment.systemPackages = with pkgs; [
    libraspberrypi
    raspberrypi-eeprom
    vim-full
    git
    openssl
    man-pages
    man-pages-posix
    age
    ssh-to-age
    # mkCertificate
    # {
    #   name = "mess/postgres";
    #   subject = "Mess Raspberry Pi Postgres certificate";
    #   ca = "mess/ca";
    # }
  ];

  systemd.services.renew-postgres-cert.description = "Renew postgres SSL certificate";
  systemd.services.renew-postgres-cert.script = mkCertificateCommand {
    name = "mess/postgres";
    subject = "Mess Raspberry Pi Postgres certificate";
    ca = "mess/ca";
  };
  systemd.timers.renew-postgres-cert.description = "Renew postgres SSL certificate";
  systemd.timers.renew-postgres-cert.wantedBy = [ "timers.target" ];
  systemd.timers.renew-postgres-cert.timerConfig.OnCalendar = "*-*-01 00:00:00";

  services.postgresql.enable = true;
  services.postgresql.package = pkgs.postgresql_14;
  services.postgresql.extraPlugins = with config.services.postgresql.package.pkgs; [
    timescaledb
  ];
  services.postgresql.settings.shared_preload_libraries = "timescaledb";
  # services.postgresql.settings.ssl = "on";
  # services.postgresql.settings.ssl_cert_file = "/etc/ssl/certs/mess/postgres.crt";
  # services.postgresql.settings.ssl_key_file = "/etc/ssl/certs/mess/postgres.key";
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
    # TYPE    DATABASE    USER        ADDRESS         METHOD  OPTIONS
    local     all         all                         scram-sha-256
    host      all         all         samehost        scram-sha-256
    hostssl   all         all         192.168.1.0/24  scram-sha-256
  '';
  services.postgresql.enableTCPIP = true;
  # services.postgresql.initialScript = import ../../artifacts/alter-passwords.sql;

  users.users.pi.isNormalUser = true;
  users.users.pi.initialPassword = "pi";
  users.users.pi.extraGroups = [ "wheel" ];
  users.users.pi.shell = pkgs.nushell;

  system.stateVersion = "23.11";
}
