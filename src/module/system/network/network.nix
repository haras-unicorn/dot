{ pkgs, ... }:

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

  # NOTE: https://github.com/adrienverge/openfortivpn/issues/1076
  environment.etc."ppp/options".text = ''
    ipcp-accept-remote
    usepeerdns
  '';
  environment.systemPackages = with pkgs; [
    ppp
    openconnect_openssl
    networkmanager-openconnect
    openfortivpn
    networkmanager-fortisslvpn
  ];
}
