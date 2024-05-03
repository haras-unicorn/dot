{ pkgs, config, lib, ... }:

# TODO: hardware acceleration

let
  cfg = config.dot.browser;
in
{
  home.shared = {
    programs.chromium.enable = true;
    programs.chromium.package =
      (p: yes: no: lib.mkMerge [
        (lib.mkIf p yes)
        (lib.mkIf (!p) no)
      ])
        (cfg.bin == "vivaldi")
        cfg.package
        pkgs.vivaldi;

    programs.chromium.dictionaries = with pkgs; [
      hunspellDictsChromium.en_US
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
