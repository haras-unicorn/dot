{
  machines.nixosModules.binfmt =
    { lib, pkgs, ... }:
    {
      boot.binfmt.preferStaticEmulators = true;
      boot.binfmt.emulatedSystems = lib.mkMerge [
        (lib.mkIf (pkgs.stdenv.hostPlatform.system == "x86_64-linux") [
          "aarch64-linux"
        ])
        (lib.mkIf (pkgs.stdenv.hostPlatform.system == "aarch64-linux") [
          "x86_64-linux"
        ])
      ];
    };
}
