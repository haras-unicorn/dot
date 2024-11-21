{ nixpkgs, ... }:

let
  parseBool = expr: path:
    if builtins.hasAttr path expr
    then nixpkgs.lib.attrByPath path null expr
    else null;
  mkBool = bool: nixpkgs.lib.mkIf (bool != null) bool;
  mkParseBool = expr: path: mkBool (parseBool expr path);

  mkModule = scripts:
    let
      expr = builtins.fromJSON (builtins.readFile scripts);
    in
    {
      dot = {
        ddns.coordinator = mkParseBool expr [ "ddns" "coordinator" ];
        vpn.coordinator = mkParseBool expr [ "vpn" "coordinator" ];
        ddb.coordinator = mkParseBool expr [ "ddb" "coordinator" ];
        nfs.coordinator = mkParseBool expr [ "nfs" "coordinator" ];
      };
    };
in
{
  mkSystemModule = scripts: { imports = [ (mkModule scripts) ]; };

  mkHomeModule = scripts: { imports = [ (mkModule scripts) ]; };
}
