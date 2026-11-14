{ inputs, ... }:

{
  self.nixosModules.jan.value =
    { config, lib, ... }:
    let
      hardware = config.dot.hardware;
    in
    lib.mkIf hardware.browser {
      # NOTE: Jan asks this host for updates on every start, and the check is
      # built into the release, so blocking the host is the only way to stop
      # it. Jan then falls back to the latest release file on GitHub, which
      # gets no session from it
      networking.hosts."0.0.0.0" = [ "apps.jan.ai" ];
    };

  self.homeModules.jan.value =
    {
      config,
      lib,
      pkgs,
      unstablePkgs,
      osConfig,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;

      dataDir = "${config.xdg.dataHome}/Jan/data";
      workspaceDir = "${config.xdg.dataHome}/Jan/workspace";

      mcpConfig = pkgs.writeText "jan-mcp-config.json" (
        builtins.toJSON {
          mcpServers = builtins.mapAttrs (_: server: {
            command = server.command;
            args = server.args or [ ];
            env = server.env or { };
            active = true;
          }) config.programs.mcp.servers;
        }
      );

      # NOTE: the haraspkgs helpers are not in pkgs.harasPackages of a
      # downstream flake yet, so this extends pkgs with them like stolon does
      harasPackages = (pkgs.extend inputs.haraspkgs.overlays.default).harasPackages;

      # NOTE: Jan rewrites its MCP config from the UI, so this copies a fresh
      # one over it on every start instead of linking a read-only one. The MCP
      # servers are scoped to the directory they start in, so Jan starts in an
      # empty workspace of its own and not in the home directory
      jan = harasPackages.writeNushellApplication {
        name = "jan";
        runtimeInputs = [ unstablePkgs.jan ];
        text = ''
          def --wrapped main [...rest] {
            let data = r#'${dataDir}'#
            let workspace = r#'${workspaceDir}'#
            mkdir $data $workspace
            open --raw r#'${mcpConfig}'# | save --force ($data | path join mcp_config.json)
            cd $workspace
            exec Jan-Desktop ...$rest
          }
        '';
      };
    in
    lib.mkIf hardware.browser {
      xdg.desktopEntries.jan = {
        name = "Jan";
        exec = lib.getExe jan;
        terminal = false;
      };
    };
}
