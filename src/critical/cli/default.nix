{ lib, self, ... }:

{
  dot.cli = {
    makeRuntimeInputs = [
      (pkgs: [
        pkgs.gum
        pkgs.vault
      ])
    ];
    text =
      let
        scriptsText = builtins.concatStringsSep "\n\n" (
          builtins.map (script: builtins.readFile (lib.path.append ./. script)) (
            builtins.filter (lib.hasSuffix ".nu") (builtins.attrNames (builtins.readDir ./.))
          )
        );
      in
      ''
        $env.DOT_VAULT_SHARED = "${self.lib.vault.shared}"

        ${scriptsText}
      '';
  };

  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];
  perSystem =
    { lib, pkgs, ... }:
    let
      name = "dot";

      cli = self.lib.cli.mkCli pkgs { inherit name; };

      cliApp = {
        type = "app";
        program = lib.getExe cli;
        meta.description = "${name} CLI";
      };
    in
    {
      packages = {
        inherit cli;
        default = cli;
      };

      apps = {
        cli = cliApp;
        default = cliApp;
      };

      checks.test-critical-cli = self.lib.test.mkTest pkgs {
        name = "critcal-cli";
        nodes.machine = {
          imports = [ self.nixosModules.critical-cli ];
        };
        dot.test.commands.suffix = ''
          machine.succeed("${name}")
        '';
      };
    };

  flake.nixosModules.critical-cli =
    { pkgs, config, ... }:
    let
      capabilities = [
        "database"
        "domains"
        "hardware"
        "locality"
        "network"
        "services"
      ];

      hosts = builtins.map (
        host:
        (lib.filterAttrs (
          name: _: name != "hosts" && name != "hardware" && name != "secrets" && name != "system"
        ) host)
        // (builtins.listToAttrs (
          builtins.filter builtins.isAttrs (
            builtins.map (
              capability:
              let
                raw = host.system.dot.${capability};
                # NOTE: need this because we can't be sure
                # if some of the options are always going to be set
                eval = builtins.tryEval (builtins.deepSeq raw raw);
              in
              if eval.success then
                {
                  name = capability;
                  value = eval.value;
                }
              else
                null
            ) capabilities
          )
        ))
      ) config.dot.host.hosts;

      hostsJson = builtins.toJSON hosts;
    in
    {
      environment.systemPackages = [
        self.packages.${pkgs.stdenv.hostPlatform.system}.cli
      ];

      environment.variables = {
        DOT_HOSTS = builtins.replaceStrings [ "\\" "\n" "\"" ] [ "\\\\" "\\n" "\\\"" ] hostsJson;
      };
    };
}
