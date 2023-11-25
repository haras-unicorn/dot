{ pkgs, ... }:

# TODO: package https://github.com/theinvisible/openfortigui

{
  # NOTE: https://github.com/NixOS/nixpkgs/issues/231038
  environment.etc."ppp/options".text = ''
    ipcp-accept-remote
  '';

  environment.systemPackages = with pkgs; [
    ppp
    openconnect_openssl
    networkmanager-openconnect
    openfortivpn
    networkmanager-fortisslvpn
  ];

  services.logmein-hamachi.enable = true;
  programs.haguichi.enable = true;
}
