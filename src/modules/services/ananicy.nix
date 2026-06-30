{
  machines.nixosModules.ananicy =
    { pkgs, ... }:
    {
      config = {
        services.ananicy.enable = true;
        services.ananicy.package = pkgs.ananicy-cpp;
        services.ananicy.rulesProvider = pkgs.ananicy-rules-cachyos;
      };
    };
}
