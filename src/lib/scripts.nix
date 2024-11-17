{ ... }:

let
  parseBool = expr: name: if builtins.hasAttr name expr then builtins.getAttr name expr else false;

  parse = scripts:
    let
      expr = builtins.fromJSON (builtins.readFile scripts);
    in
    {
      ddnsCoordinator = parseBool expr "ddnsCoordinator";
      vpnCoordinator = parseBool expr "vpnCoordinator";
      dbCoordinator = parseBool expr "dbCoordinator";
    };

  mkModule = parsed: {
    dot = {
      ddns.coordinator.enable = parsed.ddnsCoordinator;
      vpn.coordinator.enable = parsed.vpnCoordinator;
      db.coordinator.enable = parsed.dbCoordinator;
    };
  };
in
{
  mkSystemModule = scripts: { inherits = [ (mkModule (parse scripts)) ]; };

  mkHmModule = scripts: { inherits = [ (mkModule (parse scripts)) ]; };
}
