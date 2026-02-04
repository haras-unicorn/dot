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
  nixosModule = {
    boot.binfmt.preferStaticEmulators = true;
    boot.binfmt.emulatedSystems = (lib.mkIf (pkgs.stdenv.hostPlatform.system == "x86_64-linux") [ "aarch64-linux" ]);

    boot.kernelPackages =
      if isRpi4 then
        pkgs.linuxKernel.packages.linux_rpi4
      else if isLegacyNvidia then
        pkgs.linuxKernel.packages.linux_6_6
      else
        pkgs.linuxPackages_zen;
  };
}
