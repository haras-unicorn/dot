{ nixpkgs, ... }:

let
  importDir = importDir: dir:
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
            then import "${dir}/${name}"
            else null
          else
            if builtins.pathExists "${dir}/default.nix"
            then import "${dir}/default.nix"
            else importDir "${dir}/${name}";
      })
      (builtins.readDir dir);
in
{
  importDir = importDir importDir;
}
