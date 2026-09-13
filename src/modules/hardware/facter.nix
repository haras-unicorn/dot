{ self, ... }:

{
  self.nixosModules.facter.value =
    { config, lib, ... }:
    let
      report = "${self}/assets/hardware/${config.networking.hostName}.json";
    in
    {
      hardware.facter.reportPath = lib.mkIf (builtins.pathExists report) (lib.mkDefault report);

      nixpkgs.system = config.hardware.facter.report.system;
    };
}
