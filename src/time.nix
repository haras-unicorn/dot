{ ... }:

{
  branch.nixosModule.nixosModule = {
    services.timesyncd.enable = false;
    services.chrony = {
      enable = true;
      enableNTS = true;
      servers = [
        "time.cloudflare.com"
        "time.google.com"
        "0.nixos.pool.ntp.org"
        "1.nixos.pool.ntp.org"
        "2.nixos.pool.ntp.org"
        "3.nixos.pool.ntp.org"
      ];
      initstepslew = {
        enabled = true;
        threshold = 0.1;
      };
      extraConfig = ''
        makestep 0.1 3
      '';
    };
  };
}
