{ ... }:

{
  wrap = pkgs: package: bin: pkgs.symlinkJoin {
    name = bin;
    paths = [ package ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/${bin} \
        --append-flags --enable-features=WebRTCPipeWireCapturer \
        --append-flags --enable-features=UseOzonePlatform \
        --append-flags --ozone-platform-hint=auto \
        --append-flags --use-gl=desktop
    '';
  };
}
