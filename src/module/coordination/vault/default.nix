{ pkgs, lib, config, ... }:

let
  hasNetwork = config.dot.hardware.network.enable;
in
{
  system = lib.mkIf hasNetwork {
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

  home = lib.mkIf hasNetwork {
    home.packages = [
      pkgs.vault-bin
    ];
  };
}
