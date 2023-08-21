{ pkgs, config, ... }:

{
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
  services.postgresql.enableTCPIP = true;

  users.users.pi.isNormalUser = true;
  users.users.pi.initialPassword = "pi";
  users.users.pi.extraGroups = [ "wheel" ];
  users.users.pi.shell = pkgs.nushell;

  system.stateVersion = "23.11";
}
