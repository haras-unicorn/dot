{
  machines.nixosModules.rtl88x2bu =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      detection = config.hardware.facter.detection;
      hasRtl88x2bu = builtins.any (
        interface:
        builtins.elem "rtw88_8822bu" interface.modules || builtins.elem "88x2bu" interface.modules
      ) detection.network.interfaces.byModel;
    in
    lib.mkIf hasRtl88x2bu {
      boot.blacklistedKernelModules = [
        "rtw88_8822bu"
        "rtw88_core"
        "rtw88_usb"
      ];
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
          "rtw_country_code=${config.dot.location.countryCode}"
          "rtw_80211d=1"
        ]);
    };
}
