{
  # NOTE: shared by the machines, which enable it when their facter report has
  # the Wi-Fi stick, and the installer images, which have no report and always
  # enable it
  self.lib.rtl88x2bu.module =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.dot.rtl88x2bu;
    in
    {
      options.dot.rtl88x2bu = {
        enable = lib.mkEnableOption "the driver for the Realtek RTL88x2BU Wi-Fi stick";

        countryCode = lib.mkOption {
          type = lib.types.str;
          description = "Country code the driver uses for its regulatory domain.";
        };
      };

      config = lib.mkIf cfg.enable {
        boot.blacklistedKernelModules = [ "rtw88_8822bu" ];
        boot.extraModulePackages = [
          # NOTE: the nixpkgs version is heavily outdated
          (config.boot.kernelPackages.rtl88x2bu.overrideAttrs (
            final: prev: {
              version = "${config.boot.kernelPackages.kernel.version}-unstable-2026-10-02";
              src = pkgs.fetchFromGitHub {
                owner = "RinCat";
                repo = "RTL88x2BU-Linux-Driver";
                rev = "b4e4c1bf0c9866b958b2138504742d0060d9343f";
                hash = "sha256-zURAL+79SPuoWW8W5ZOz8On1g8LMVeaFNLRsQujwgV8=";
              };
            }
          ))
        ];
        boot.kernelModules = [ "88x2bu" ];
        # NOTE: automatically disable power save for the wifi usb
        boot.extraModprobeConfig =
          "options 88x2bu "
          + (builtins.concatStringsSep " " [
            "rtw_power_mgnt=0"
            "rtw_ips_mode=0"
            "rtw_country_code=${cfg.countryCode}"
            "rtw_80211d=1"
          ]);
      };
    };
}
