{ ... }:

{
  networking.nftables.enable = true;
  networking.firewall.enable = true;
  networking.networkmanager.enable = true;
  networking.firewall.allowedTCPPorts = [
    7860 # stable-diffusion
    8384 # syncthing
    5000 # aspnetcore http
    5001 # aspnetcore https
  ];
}
