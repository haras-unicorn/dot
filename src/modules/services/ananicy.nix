{
  self.nixosModules.ananicy.value =
    { pkgs, ... }:
    {
      config = {
        services.ananicy.enable = true;
        services.ananicy.package = pkgs.ananicy-cpp;
        services.ananicy.rulesProvider = pkgs.ananicy-rules-cachyos;
      };
    };
}
