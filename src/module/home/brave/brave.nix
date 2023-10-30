{ pkgs, ... }:

{
  systemd.user.sessionVariables = {
    BROWSER = "${pkgs.brave}/bin/brave";
  };

  wayland.windowManager.hyprland.extraConfig = ''
    bind = super, w, exec, ${pkgs.brave}/bin/brave
  '';

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
}
