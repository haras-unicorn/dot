{
  system = {
    services.vault.enable = true;
    services.vault.extraSettingsPaths = [ "/etc/vault/settings.hcl" ];
    services.vault.storageBackend = "mysql";
    sops.secrets."shared.vault" = {
      path = "/etc/vault/settings.hcl";
      owner = "vault";
      group = "vault";
      mode = "0400";
    };
  };
}
