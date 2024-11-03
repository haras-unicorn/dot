{ nixpkgs, ... }:

# TODO: importDir with metadata

let
  importDir = importDir: wrap: dir:
    nixpkgs.lib.attrsets.mapAttrs'
      (name: type: {
        name =
          if type == "regular"
          then (builtins.replaceStrings [ ".nix" ] [ "" ] name)
          else name;
        value =
          if type == "regular"
          then
            if nixpkgs.lib.hasSuffix ".nix" name
            then
              wrap
                {
                  __import = {
                    path = "${dir}/${name}";
                    type = "regular";
                    value = import "${dir}/${name}";
                  };
                }
            else
              wrap {
                __import = {
                  path = "${dir}/${name}";
                  type = "unknown";
                  value = null;
                };
              }
          else
            if builtins.pathExists "${dir}/default.nix"
            then
              wrap
                {
                  __import = {
                    path = "${dir}/default.nix";
                    type = "default";
                    value = import "${dir}/default.nix";
                  };
                }
            else importDir "${dir}/${name}";
      })
      (builtins.readDir dir);

  importDirWrap = importDir importDir;
in
{
  importDirWrap = importDirWrap;
  importDirMeta = importDirWrap (import: import);
  importDir = importDirWrap (import: import.__import.value);
}
