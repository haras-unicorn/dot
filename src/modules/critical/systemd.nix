{
  machines.nixosModules.systemd = {
    services.journald.extraConfig = ''
      SystemMaxUse=750M
      SystemMaxFileSize=100M
      MaxRetentionSec=1month
    '';
  };

  machines.homeModules.systemd =
    { lib, pkgs, ... }:
    {
      dot.programs.shell.aliases = {
        lj = lib.getExe pkgs.lazyjournal;
      };

      home.packages = [
        pkgs.lazyjournal
      ];
    };
}
