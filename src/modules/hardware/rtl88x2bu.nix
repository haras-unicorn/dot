{ selfLib, ... }:

{
  self.nixosModules.rtl88x2bu.value =
    { config, ... }:
    let
      detection = config.hardware.facter.detection;
      hasRtl88x2bu = builtins.any (
        interface:
        builtins.elem "rtw88_8822bu" interface.modules || builtins.elem "88x2bu" interface.modules
      ) detection.network.interfaces.byModel;
    in
    {
      imports = [ selfLib.rtl88x2bu.module ];

      dot.rtl88x2bu = {
        enable = hasRtl88x2bu;
        countryCode = config.dot.location.countryCode;
      };
    };
}
