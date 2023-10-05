{ pkgs, ... }:

{
  home.packages = [
    (pkgs.symlinkJoin {
      name = "brave";
      paths = [ pkgs.brave ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/brave \
          --append-flags --use-gl=egl \
          --append-flags --ozone-platform-hint=auto \
          --append-flags --enable-features=VaapiVideoDecoder \
          --append-flags --disable-features=UseChromeOSDirectVideoDecoder \
          --append-flags --enable-flag=ignore-gpu-blocklist \
          --append-flags --enable-flag=enable-gpu-rasterization \
          --append-flags --enable-flag=enable-zero-copy
      '';
    })
  ];

  wayland.windowManager.hyprland.extraConfig = ''
    env = BROWSER, brave

    bind = super, w, exec, brave
  '';
}
