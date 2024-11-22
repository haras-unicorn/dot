{ nixpkgs, ... }:

let
  parseFile = dir:
    if builtins.pathExists "${dir}/secrets.json" then
      let
        expr = builtins.fromJSON (builtins.readFile "${dir}/secrets.json");

        val = path:
          let
            val =
              if builtins.hasAttr path expr
              then nixpkgs.lib.attrByPath path null expr
              else null;
          in
          nixpkgs.lib.mkIf (val != null) val;
      in
      {
        ddns.coordinator = val [ "ddns" "coordinator" ];
        vpn.coordinator = val [ "vpn" "coordinator" ];
        vpn.ip = val [ "vpn" "ip" ];
        vpn.subnet.ip = val [ "vpn" "subnet" "ip" ];
        vpn.subnet.bits = val [ "vpn" "subnet" "bits" ];
        vpn.subnet.mask = val [ "vpn" "subnet" "mask" ];
        ddb.coordinator = val [ "ddb" "coordinator" ];
        nfs.coordinator = val [ "nfs" "coordinator" ];
        nfs.node = val [ "nfs" "node" ];
      }
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
