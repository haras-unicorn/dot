{ nixpkgs, ... }:

let
  parseBool = expr: name: if builtins.hasAttr name expr then builtins.getAttr name expr else null;

  parse = scripts:
    let
      expr = builtins.fromJSON (builtins.readFile scripts);
    in
    {
      ddnsCoordinator = parseBool expr "ddnsCoordinator";
      vpnCoordinator = parseBool expr "vpnCoordinator";
      dbCoordinator = parseBool expr "dbCoordinator";
    };

  mkBool = bool: nixpkgs.lib.mkIf (bool != null) bool;

  mkModule = parsed: {
    dot = {
      ddns.coordinator.enable = mkBool parsed.ddnsCoordinator;
      vpn.coordinator.enable = mkBool parsed.vpnCoordinator;
      db.coordinator.enable = mkBool parsed.dbCoordinator;
    };
  };
in
{
  mkSystemModule = scripts: { imports = [ (mkModule (parse scripts)) ]; };

  mkHomeModule = scripts: { imports = [ (mkModule (parse scripts)) ]; };
}
