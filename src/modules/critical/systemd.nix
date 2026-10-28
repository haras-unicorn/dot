{
  self.nixosModules.systemd.value = {
    services.journald.extraConfig = ''
      SystemMaxUse=750M
      SystemMaxFileSize=100M
      MaxRetentionSec=1month
    '';
  };

  self.homeModules.systemd.value =
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
