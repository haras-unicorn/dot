{ pkgs, config, stdenv, ... }:

let
  mkCertificateCommand = { name, subject, ca }: ''
    #!/usr/bin/env bash

    mkdir -p "$(dirname ${name})";
  
    openssl genpkey -algorithm ED25519 \
      -out ${name}.key;

    openssl req -new \
      -key ${name}.key \
      -out ${name}.csr \
      -subj "/CN=${subject}";

    openssl x509 -req -in ${name}.csr \
      -CA ${ca}.crt -CAkey ${ca}.key -CAcreateserial \
      -out ${name}.crt \
      -days 400;
  '';

  mkCertificate = { name, subject, ca }:
    pkgs.runCommand name
      {
        buildInputs = with pkgs; [ openssl ];
      } ''
      ${
        mkCertificateCommand {
          name = name;
          subject = subject;
          ca = ca;
        }
      }
      dir="$(dirname "$out/etc/ssl/certs/${name}")"
      mkdir -p "$dir";
      cp ${name}.crt $dir;
      cp ${name}.key $dir;
    '';

  postgresCert = mkCertificate
    {
      name = "mess/postgres";
      subject = "Mess Raspberry Pi Postgres certificate";
      ca = "/etc/ssl/certs/mess/ca";
    };

  renewScript = mkCertificateCommand {
    name = "mess/postgres";
    subject = "Mess Raspberry Pi Postgres certificate";
    ca = "/etc/ssl/certs/mess/ca";
  };
in
{
  sops.defaultSopsFile = ../../secrets.yaml;
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";
  sops.age.generateKey = true;
  sops.secrets."ca.crt".path = "/etc/ssl/certs/mess/ca.crt";
  sops.secrets."ca.key".path = "/etc/ssl/certs/mess/ca.key";

  nix.package = pkgs.nixFlakes;
  nix.extraOptions = "experimental-features = nix-command flakes";
  nixpkgs.config = import ../../assets/.config/nixpkgs/config.nix;

  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = true;
  networking.hostName = "pi";

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
    postgresCert
  ];

  systemd.services.renew-postgres-cert.description = "Renew postgres SSL certificate";
  systemd.services.renew-postgres-cert.script = renewScript;
  systemd.timers.renew-postgres-cert.description = "Renew postgres SSL certificate";
  systemd.timers.renew-postgres-cert.wantedBy = [ "timers.target" ];
  systemd.timers.renew-postgres-cert.timerConfig.OnCalendar = "*-*-01 00:00:00";

  services.postgresql.enable = true;
  services.postgresql.package = pkgs.postgresql_14;
  services.postgresql.extraPlugins = with config.services.postgresql.package.pkgs; [
    timescaledb
  ];
  services.postgresql.settings.shared_preload_libraries = "timescaledb";
  services.postgresql.settings.ssl = "on";
  services.postgresql.settings.ssl_cert_file = "/etc/ssl/certs/mess/postgres.crt";
  services.postgresql.settings.ssl_key_file = "/etc/ssl/certs/mess/postgres.key";
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
    # TYPE    DATABASE    USER        ADDRESS         METHOD        OPTIONS
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
