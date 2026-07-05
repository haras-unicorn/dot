{
  machines.nixosModules.earlyoom =
    { config, pkgs, ... }:
    {
      services.earlyoom.enable = true;
    };
}
