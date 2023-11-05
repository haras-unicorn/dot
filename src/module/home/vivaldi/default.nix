{ pkgs, ... }:

# TODO: wayland...

{
  de.sessionVariables = {
    BROWSER = "${pkgs.vivaldi}/bin/vivaldi";
  };

  wayland.windowManager.hyprland.extraConfig = ''
    bind = super, w, exec, ${pkgs.vivaldi}/bin/vivaldi
  '';

  programs.chromium.enable = true;
  programs.chromium.package = pkgs.vivaldi;
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
}

