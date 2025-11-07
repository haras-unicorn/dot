{
  lib,
  config,
  ...
}:

let
  hasNetwork = config.dot.hardware.network.enable;
  nameservers = [
    # Cloudflare
    "1.1.1.1"
    "1.0.0.1"
    # Google
    "8.8.8.8"
    "8.8.4.4"
  ];
in
{
  branch.nixosModule.nixosModule = lib.mkIf hasNetwork {
    networking.networkmanager.dns = "systemd-resolved";
    networking.nameservers = nameservers;

    services.resolved.enable = true;
    services.resolved.fallbackDns = [ ];
    services.resolved.dnssec = "allow-downgrade";
    services.resolved.dnsovertls = "opportunistic";
    services.resolved.llmnr = "false";
  };
}
