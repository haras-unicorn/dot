{ nixpkgs, ... }:

let
  parseFile = dir:
    if builtins.pathExists "${dir}/static.json" then
      builtins.fromJSON (builtins.readFile "${dir}/static.json")
    else { };

  parseDir = dir:
    builtins.listToAttrs
      (builtins.filter
        ({ type, ... }: type == "directory")
        (nixpkgs.mapAttrsToList
          (name: value: {
            inherit name;
            type = value;
            value = nixpkgs.lib.mkMerge [
              (parseFile "${dir}")
              (parseFile "${dir}/${name}")
            ];
          })
          (builtins.readDir dir)));
in
{
  parseFile = parseFile;

  parseDir = parseDir;
}