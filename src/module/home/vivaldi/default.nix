{ pkgs, ... }:

# TODO: hardware acceleration

{
  programs.chromium.enable = true;
  programs.chromium.package = pkgs.vivaldi;
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
}

