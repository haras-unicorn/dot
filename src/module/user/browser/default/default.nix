{ pkgs, lib, config, ... }:

# FIXME: hardware acceleration
# FIXME: chromium extensions https://github.com/NixOS/nixpkgs/issues/158449

let
  hasMonitor = config.dot.hardware.monior.enable;
in
{
  home = lib.mkIf hasMonitor {
    programs.chromium.enable = true;
    programs.chromium.package = pkgs.ungoogled-chromium;
    programs.chromium.dictionaries = with pkgs.hunspellDictsChromium; [
      en_US
    ];
    programs.chromium.extensions = [
      # ublock origin
      { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; }
      # dark reader
      { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; }
      # vimium c
      { id = "hfjbmagddngcpeloejdejnfgbamkjaeg"; }
      # vimium c new tab
      { id = "cglpcedifkgalfdklahhcchnjepcckfn"; }
    ];
  };
}
