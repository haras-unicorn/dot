{ ... }:

let
  args = [
    "--enable-features=WebRTCPipeWireCapturer"
    "--enable-features=UseOzonePlatform"
    "--ozone-platform-hint=auto"
    "--use-gl=egl"
  ];

  flags = builtins.concatStringsSep
    " "
    (builtins.map
      (x: "--append-flags ${x}")
      args);
in
{
  wrap = pkgs: package: bin: pkgs.symlinkJoin {
    name = bin;
    paths = [ package ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''wrapProgram $out/bin/${bin} ${flags}'';
  };

  args = builtins.concatStringsSep " " args;
}
