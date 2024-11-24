{ pkgs, lib, config, ... }:

let
  hasNetwork = config.dot.hardware.network.enable;
  hasMonitor = config.dot.hardware.monitor.enable;
in
{
  system = lib.mkIf hasNetwork {
    services.vault.enable = true;
    users.users.vaultwarden.uid = 977;
    users.groups.vaultwarden.gid = 988;
    systemd.services.vault.after = [ "mysql.service" ];
    systemd.services.vault.wants = [ "mysql.service" ];
    services.vault.package = pkgs.vault-bin;
    services.vault.extraSettingsPaths = [ "/etc/vault/settings.hcl" ];
    services.vault.storageBackend = "mysql";
    services.vault.extraConfig = ''
      ui = true
    '';
    sops.secrets."shared.vault" = {
      path = "/etc/vault/settings.hcl";
      owner = "vault";
      group = "vault";
      mode = "0400";
    };
  };

  home = lib.mkIf hasNetwork {
    home.packages = [
      pkgs.vault-bin
    ];

    xdg.desktopEntries = lib.mkIf hasMonitor {
      vault = {
        name = "Vault";
        exec = "${config.dot.browser.package}/bin/${config.dot.browser.bin} --new-window localhost:8200";
        terminal = false;
      };
    };
  };
}
