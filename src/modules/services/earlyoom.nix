{
  self.nixosModules.earlyoom.value =
    { config, pkgs, ... }:
    {
      services.earlyoom.enable = true;
    };
}
