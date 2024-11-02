{ lib, pkgs, config, ... }:

# TODO: https://github.com/NixOS/nixpkgs/issues/158449
# TODO: hardware acceleration

let
  hasMonitor =
    (builtins.hasAttr "monitor" config.facter.report.hardware) &&
    ((builtins.length config.facter.report.hardware.monitor) > 0);
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
