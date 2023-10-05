{ pkgs, ... }:

{
  home.packages = [
    (pkgs.symlinkJoin {
      name = "brave";
      paths = [ pkgs.brave ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/brave \
          --append-flags \
            --use-gl=egl \
            --ozone-platform-hint=auto \
            --enable-features=VaapiVideoDecoder \
            --disable-features=UseChromeOSDirectVideoDecoder \
            --enable-flag=ignore-gpu-blocklist \
            --enable-flag=enable-gpu-rasterization \
            --enable-flag=enable-zero-copy
      '';
    })
  ];

  wayland.windowManager.hyprland.extraConfig = ''
    env = BROWSER, brave

    bind = super, w, exec, brave
  '';
}
