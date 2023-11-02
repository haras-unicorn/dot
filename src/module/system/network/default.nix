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

  # NOTE: https://github.com/NixOS/nixpkgs/issues/231038
  environment.etc."ppp/options".text = ''
    ipcp-accept-remote
  '';
  environment.etc."openfortivpn/config".text = ''
    trusted-cert = 679706703490caf5ce655c3fa98e2e95309823b93526d62a47441fbe34502ac9
  '';
  environment.systemPackages = with pkgs; [
    ppp
    openconnect_openssl
    networkmanager-openconnect
    openfortivpn
    networkmanager-fortisslvpn
  ];
}
