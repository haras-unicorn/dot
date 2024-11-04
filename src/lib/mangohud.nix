{ ... }:

{
  wrap = pkgs: package: bin: value: pkgs.symlinkJoin {
    name = bin;
    paths = [ package ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/${bin} \
        --set MANGOHUD ${if value then "1" else "0"}
    '';
  };
}
