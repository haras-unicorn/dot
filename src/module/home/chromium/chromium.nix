{ pkgs, ... }:

# TODO: fix attempting to compile

{
  home.sessionVariables = {
    BROWSER = "${pkgs.ungoogled-chromium}/bin/chromium";
  };

  wayland.windowManager.hyprland.extraConfig = ''
    bind = super, w, exec, ${pkgs.ungoogled-chromium}/bin/chromium
  '';

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
