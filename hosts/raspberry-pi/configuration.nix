{ pkgs, config, ... }:

{
  sops.defaultSopsFile = ../../secrets.yaml;
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";
  sops.age.generateKey = true;

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
  ];

  services.postgresql.enable = true;
  services.postgresql.package = pkgs.postgresql_15;
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
    # TYPE    DATABASE    USER        ADDRESS         METHOD        OPTIONS
    local     all         all                         trust
    host      all         all         samehost        trust
    hostssl   all         all         192.168.1.0/24  scram-sha-256
  '';
  services.postgresql.enableTCPIP = true;
  sops.secrets."server.crt".path = "/var/lib/pgsql/data/server.crt";
  sops.secrets."server.key".path = "/var/lib/pgsql/data/server.key";
  # TODO: passwords
  # services.postgresql.initialScript = import ../../artifacts/alter-passwords.sql;

  users.users.pi.isNormalUser = true;
  users.users.pi.initialPassword = "pi";
  users.users.pi.extraGroups = [ "wheel" ];
  users.users.pi.shell = pkgs.nushell;

  system.stateVersion = "23.11";
}
