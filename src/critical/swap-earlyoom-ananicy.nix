{ self, ... }:

{
  flake.nixosModules.critical-swap-earlyoom-ananicy =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      isRpi4 = config.dot.hardware.rpi."4".enable;
    in
    {
      config = {
        services.ananicy.enable = !isRpi4;
        services.ananicy.package = pkgs.ananicy-cpp;
        services.ananicy.rulesProvider = pkgs.ananicy-rules-cachyos;

        services.earlyoom.enable = true;

        zramSwap.enable = isRpi4;

        swapDevices = (
          lib.mkIf (!isRpi4) [
            {
              device = "/var/swap";
              size = config.dot.hardware.memory / 1000 / 1000;
            }
          ]
        );

        programs.rust-motd.settings = {
          memory = {
            swap_pos = "beside";
          };
          load_avg = {
            format = "Load (1, 5, 15 min.): {one:.02}, {five:.02}, {fifteen:.02}";
          };
        };
      };
    };

  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];
  perSystem =
    { pkgs, ... }:
    {
      checks.test-critical-swap-earlyoom-ananicy = self.lib.test.mkTest pkgs {
        name = "critical-swap-earlyoom-ananicy";
        nodes.machine = {
          imports = [
            self.nixosModules.critical-swap-earlyoom-ananicy
          ];

          dot.hardware.rpi."4".enable = false;
        };
        testScript = ''
          start_all()
          machine.wait_for_unit("multi-user.target")
          machine.succeed("systemctl is-enabled ananicy-cpp.service")
          machine.succeed("systemctl is-enabled earlyoom.service")
          # TODO: maybe vms don't allow swap?
          # machine.wait_for_unit("mkswap-var-swap.service")
          # machine.succeed("test -f /var/swap")
        '';
      };

      checks.test-critical-swap-earlyoom-ananicy-rpi4 = self.lib.test.mkTest pkgs {
        name = "critical-swap-earlyoom-ananicy-rpi4";
        nodes.machine = {
          imports = [
            self.nixosModules.critical-swap-earlyoom-ananicy
          ];

          dot.hardware.rpi."4".enable = true;
        };
        testScript = ''
          start_all()
          machine.wait_for_unit("multi-user.target")
          machine.fail("systemctl is-enabled ananicy-cpp.service")
          machine.succeed("systemctl is-enabled earlyoom.service")
          machine.fail("test -f /var/swap")
        '';
      };
    };
}
