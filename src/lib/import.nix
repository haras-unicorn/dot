{ nixpkgs, ... }:

{
  importDir = (dir: nixpkgs.lib.attrsets.mapAttrs'
    (name: type: {
      name =
        if type == "regular" then
          (builtins.replaceStrings [ ".nix" ] [ "" ] name) else
          name;
      value = import "${dir}/${name}";
    })
    (builtins.readDir dir));
}
