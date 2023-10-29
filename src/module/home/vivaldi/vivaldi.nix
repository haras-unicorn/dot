{ pkgs, ... }:

let
  vivaldi = pkgs.symlinkJoin {
    name = "vivaldi";
    paths = [ pkgs.vivaldi ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/vivaldi \
        --append-flags --use-gl=egl \
        --append-flags --ozone-platform-hint=auto \
        --append-flags --enable-features=VaapiVideoDecoder \
        --append-flags --disable-features=UseChromeOSDirectVideoDecoder \
        --append-flags --enable-flag=ignore-gpu-blocklist \
        --append-flags --enable-flag=enable-gpu-rasterization \
        --append-flags --enable-flag=enable-zero-copy
    '';
  };
in
{
  home.packages = [
    vivaldi
  ];

  wayland.windowManager.hyprland.extraConfig = ''
    env = BROWSER, vivaldi
    bind = super, w, exec, ${vivaldi}/bin/vivaldi 
  '';
}
