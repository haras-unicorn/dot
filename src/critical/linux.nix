{ self, ... }:

{
  flake.nixosModules.critical-linux =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      isRpi4 = config.dot.hardware.rpi."4".enable;
      isLegacyNvidia =
        let
          version = config.dot.hardware.graphics.version;
          driver = config.dot.hardware.graphics.driver;
        in
        driver == "nvidia" && ((version != "latest") && (version != "production"));
    in
    {
      boot.binfmt.preferStaticEmulators = true;
      boot.binfmt.emulatedSystems = lib.mkIf (pkgs.stdenv.hostPlatform.system == "x86_64-linux") [
        "aarch64-linux"
      ];

      boot.kernelPackages =
        if isRpi4 then
          pkgs.linuxKernel.packages.linux_rpi4
        else if isLegacyNvidia then
          pkgs.linuxKernel.packages.linux_6_6
        else
          pkgs.linuxPackages_zen;
    };

  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];
  perSystem =
    { pkgs, ... }:
    {
      checks.test-critical-linux = self.lib.test.mkTest pkgs {
        name = "critical-linux-standard";
        nodes.machine = {
          imports = [
            self.nixosModules.critical-linux
          ];

          dot.hardware = {
            rpi."4".enable = false;
            graphics.driver = "nvidia";
            graphics.version = "latest";
          };
        };
        dot.test.commands.suffix = ''
          machine.succeed("readlink /run/booted-system/kernel | grep -qi zen")
          machine.succeed("systemctl is-system-running --wait")
        '';
      };

      checks.test-critical-linux-legacy-nvidia = self.lib.test.mkTest pkgs {
        name = "critical-linux-legacy-nvidia";
        nodes.machine = {
          imports = [
            self.nixosModules.critical-linux
          ];

          dot.hardware = {
            rpi."4".enable = false;
            graphics.driver = "nvidia";
            graphics.version = "legacy_470";
          };
        };
        dot.test.commands.suffix = ''
          machine.succeed("readlink /run/booted-system/kernel | grep -q '6.6'")
          machine.succeed("systemctl is-system-running --wait")
        '';
      };
    };
}
