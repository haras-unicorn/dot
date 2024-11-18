{ pkgs, ... }:

{
  system = {
    services.vault.enable = true;
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
}
