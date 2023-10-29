{ pkgs, ... }:

{
  programs.chromium.enable = true;
  programs.chromium.package = pkgs.ungoogled-chromium;
  programs.chromium.commandLineArgs = [
    "--use-gl=egl"
    "--enable-features=UseOzonePlatform"
    "--ozone-platform=wayland"
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
    # ublock origin
    { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; }
    # dark reader
    { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; }
    # vimium c
    { id = "hfjbmagddngcpeloejdejnfgbamkjaeg"; }
    # vimium c new tab
    { id = "cglpcedifkgalfdklahhcchnjepcckfn"; }
  ];

  wayland.windowManager.hyprland.extraConfig = ''
    env = BROWSER, chromium
    bind = super, w, exec, ${pkgs.ungoogled-chromium}/bin/chromium
  '';
}
