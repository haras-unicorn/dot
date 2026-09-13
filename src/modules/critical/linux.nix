{
  machines.nixosModules.linux =
    { pkgs, ... }:
    {
      boot.kernelPackages = pkgs.linuxPackages_zen;
      hardware.enableRedistributableFirmware = true;
      hardware.wirelessRegulatoryDatabase = true;
    };
}
