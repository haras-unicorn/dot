{
  machines.nixosModules.journald = {
    services.journald.extraConfig = ''
      SystemMaxUse=750M
      SystemMaxFileSize=100M
      MaxRetentionSec=1month
    '';
  };
}
