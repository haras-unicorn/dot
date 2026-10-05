{
  machines.nixosModules.linux =
    { pkgs, config, ... }:
    {
      boot.kernelPackages = pkgs.linuxPackages_zen;
      hardware.enableRedistributableFirmware = true;
      hardware.wirelessRegulatoryDatabase = true;
      boot.kernelParams = [ "cfg80211.ieee80211_regdom=${config.dot.location.countryCode}" ];
    };
}
