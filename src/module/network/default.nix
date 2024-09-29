{ lib, ... }:

{
  options = {
    dot = {
      networkInterface = lib.mkOption {
        type = lib.types.str;
        description = "ip address";
        example = "enp27s0";
      };
    };
  };

  config = {
    shared.dot = {
      desktopEnvironment.windowrules = [{
        rule = "float";
        selector = "class";
        arg = "nm-connection-editor";
      }];
    };

    system = {
      networking.nftables.enable = true;
      networking.firewall.enable = true;
      networking.networkmanager.enable = true;
      networking.nameservers = [ "1.1.1.1" "1.0.0.1" ];
      networking.networkmanager.dns = "none";
    };
  };
}
