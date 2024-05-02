{ pkgs, ... }:

# TODO: hardware acceleration

{
  home.shared = {
    programs.chromium.enable = true;
    programs.chromium.package = pkgs.brave;
    programs.chromium.dictionaries = with pkgs; [
      hunspellDictsChromium.en_US
    ];
    programs.chromium.extensions = [
      # dark reader
      { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; }
      # vimium c
      { id = "hfjbmagddngcpeloejdejnfgbamkjaeg"; }
      # vimium c new tab
      { id = "cglpcedifkgalfdklahhcchnjepcckfn"; }
    ];
  };
}
