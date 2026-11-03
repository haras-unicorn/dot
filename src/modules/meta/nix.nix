{
  self.nixosModules.nix.value =
    { lib, ... }:
    {
      options.dot = {
        nix.gc = lib.mkEnableOption "Nix GC" // {
          default = true;
        };
      };
    };
}
