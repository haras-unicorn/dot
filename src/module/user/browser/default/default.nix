{ self, pkgs, lib, config, ... }:

# FIXME: hardware acceleration
# TODO: idk what to do with extensions

let
  hasMonitor = config.dot.hardware.monitor.enable;
in
{
  home = lib.mkIf hasMonitor {
    programs.chromium.enable = true;
    programs.chromium.package = self.lib.chromium.wrap pkgs.ungoogled-chromium "chromium";
    programs.chromium.dictionaries = with pkgs.hunspellDictsChromium; [
      en_US
    ];
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
