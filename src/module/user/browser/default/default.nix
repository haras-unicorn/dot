{ self, pkgs, lib, config, ... }:

# FIXME: hardware acceleration

let
  hasMonitor = config.dot.hardware.monitor.enable;

  package = self.lib.chromium.wrap pkgs pkgs.ungoogled-chromium "chromium";
in
{
  integrate.homeManagerModule.homeManagerModule = lib.mkIf hasMonitor {
    programs.chromium.enable = true;
    programs.chromium.package = package;
    programs.chromium.dictionaries = with pkgs.hunspellDictsChromium; [
      en_US
    ];
    # NOTE: keeping here just in case i need them again
    # programs.chromium.extensions = [
    #   # ublock origin
    #   { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; }
    #   # dark reader
    #   { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; }
    #   # vimium c
    #   { id = "hfjbmagddngcpeloejdejnfgbamkjaeg"; }
    #   # vimium c new tab
    #   { id = "cglpcedifkgalfdklahhcchnjepcckfn"; }
    # ];
  };
}
