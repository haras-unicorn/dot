{ ... }:

{
  networking.nftables.enable = true;
  networking.firewall.enable = true;
  networking.networkmanager.enable = true;
  networking.firewall.allowedTCPPorts = [
    7860 # Stable diffusion
    8384 # Syncthing
    5000 # ASP.NET Core HTTP
    5001 # ASP.NET Core HTTPS
  ];
}
