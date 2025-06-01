{ ... }:

{
  branch.nixosModule.nixosModule = {
    services.timesyncd = {
      servers = [
        "time.cloudflare.com"
        "time.google.com"
      ];
      # NOTE: fixes rpis having issues with contacting NTP servers
      extraConfig = ''
        RootDistanceMaxUSec=30
      '';
    };
  };
}
