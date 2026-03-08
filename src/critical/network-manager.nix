{ self, ... }:

{
  flake.nixosModules.critical-network-manager =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      hasNetwork = config.dot.hardware.network.enable;
    in
    {
      config = lib.mkIf hasNetwork {
        networking.nftables.enable = true;
        networking.firewall.enable = true;

        networking.networkmanager.enable = true;
        systemd.network.wait-online.enable = false;

        programs.rust-motd.settings = {
          service_status = {
            Network = "systemd-networkd";
          };
        };
      };
    };

  flake.homeModules.critical-network-manager =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      hasNetwork = config.dot.hardware.network.enable;
      hasMonitor = config.dot.hardware.monitor.enable;
      hasMouse = config.dot.hardware.mouse.enable;

      network = lib.getExe config.services.network-manager-applet.package;
    in
    lib.mkIf (hasNetwork && hasMonitor && hasMouse) {
      services.network-manager-applet.enable = true;

      dot.desktopEnvironment.network = network;
    };

  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];
  perSystem =
    { pkgs, ... }:
    {
      checks.test-critical-network-manager = self.lib.test.mkTest pkgs {
        name = "critical-network-manager";
        nodes.machine = {
          imports = [
            self.nixosModules.critical-network-manager
          ];
        };
        dot.test.commands.suffix = ''
          machine.succeed("systemctl is-enabled nftables.service")
          machine.succeed("systemctl is-enabled NetworkManager.service")
        '';
      };
    };
}
