{
  machines.nixosModules.nix =
    { lib, config, ... }:
    {
      options.dot = {
        nix.gc = lib.mkEnableOption "Nix GC" // {
          default = true;
        };
      };
    };
}
