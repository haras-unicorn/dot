{ pkgs, ... }:

{
  home.sessionVariables = {
    BROWSER = "${pkgs.vivaldi}/bin/vivaldi";
  };

  wayland.windowManager.hyprland.extraConfig = ''
    bind = super, w, exec, ${pkgs.vivaldi}/bin/vivaldi
  '';

  programs.chromium.enable = true;
  programs.chromium.package = pkgs.vivaldi;
  programs.chromium.commandLineArgs = [
    "--enable-features=UseOzonePlatform"
    "--ozone-platform=wayland"
    "--use-gl=egl"
    "--enable-features=VaapiVideoDecoder"
    "--disable-features=UseChromeOSDirectVideoDecoder"
    "--enable-flag=ignore-gpu-blocklist"
    "--enable-flag=enable-gpu-rasterization"
    "--enable-flag=enable-zero-copy"
  ];
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
