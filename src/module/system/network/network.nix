{ ... }:

{
  networking.nftables.enable = true;
  networking.firewall.enable = true;
  networking.networkmanager.enable = true;
  networking.firewall.allowedTCPPorts = [
    7860 # Syncthing
    8384 # Stable diffusion
    5000 # ASP.NET Core HTTP
    5001 # ASP.NET Core HTTPS
  ];
}
