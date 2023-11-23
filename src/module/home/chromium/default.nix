{ pkgs, ... }:

# TODO: https://github.com/NixOS/nixpkgs/issues/158449
# TODO: wayland...

{
  programs.chromium.enable = true;
  programs.chromium.package = pkgs.ungoogled-chromium;
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
