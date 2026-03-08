{ inputs, self, ... }:

{
  libAttrs.test.modules.secrets =
    {
      lib,
      nodes,
      pkgs,
      config,
      ...
    }:
    let
      mkNodeSpecification =
        config:
        let
          imports = builtins.filter (_import: _import != null) (
            builtins.map (
              _import:
              if _import.importer == "vault" then
                null
              else if _import.importer == "vault-file" then
                if _import.arguments.path == self.lib.rumor.shared then
                  {
                    importer = "copy";
                    arguments = {
                      from = "../shared/${_import.arguments.file}";
                      to = _import.arguments.file;
                      allow_fail = _import.arguments.allow_fail or false;
                    };
                  }
                else
                  null
              else
                _import
            ) (if config.rumor != null then config.rumor.specification.imports else [ ])
          );

          exports = builtins.filter (export: export != null) (
            builtins.map (
              export:
              if export.exporter == "vault" then
                null
              else if export.exporter == "vault-file" then
                if export.arguments.path == self.lib.rumor.shared then
                  {
                    exporter = "copy";
                    arguments = {
                      from = export.arguments.file;
                      to = "../shared/${export.arguments.file}";
                    };
                  }
                else
                  null
              else
                export
            ) (if config.rumor != null then config.rumor.specification.exports else [ ])
          );

          generations = if config.rumor != null then config.rumor.specification.generations else [ ];

          sopsKeys = if config.rumor != null then config.rumor.sops.keys else [ ];
        in
        pkgs.writeText "specification" (
          builtins.toJSON {
            inherit imports exports;
            generations = generations ++ [
              {
                generator = "age-key";
                arguments = {
                  private = "age-private";
                  public = "age-public";
                };
              }
              {
                generator = "sops";
                arguments = {
                  age = "age-public";
                  private = "sops-private";
                  public = "sops-public";
                  secrets = builtins.listToAttrs (
                    builtins.map (file: {
                      name = file;
                      value = file;
                    }) sopsKeys
                  );
                };
              }
            ];
          }
        );

      secrets =
        let
          specification = pkgs.writeText "specification" (
            builtins.toJSON config.dot.test.rumor.shared.specification
          );

          nodeCommands = builtins.concatStringsSep "\n" (
            builtins.map (
              node:
              let
                specification = mkNodeSpecification node;
              in
              ''
                mkdir -p $out/${node.dot.host.name}
                cd $out/${node.dot.host.name}
                cat "${specification}" | rumor from-stdin json --stay --keep --nosandbox --allow-script
                cp -f age-private secrets.age
                cp -f sops-public secrets.yaml
              ''
            ) (builtins.attrValues nodes)
          );
        in
        pkgs.runCommand "secrets"
          {
            nativeBuildInputs = [ inputs.rumor.packages.${pkgs.stdenv.hostPlatform.system}.default ];
          }
          ''
            mkdir -p $out
            mkdir -p $out/shared

            cd $out/shared
            cat "${specification}" | rumor from-stdin json --stay --keep --nosandbox --allow-script

            ${nodeCommands}
          '';
    in
    {
      options.dot.test = {
        rumor.shared = {
          specification = {
            imports = lib.mkOption {
              type = lib.types.listOf lib.types.raw;
              default = [ ];
              description = lib.literalMD ''
                Rumor `imports` specification value.
              '';
            };

            generations = lib.mkOption {
              type = lib.types.listOf lib.types.raw;
              default = [ ];
              description = lib.literalMD ''
                Rumor `generations` specification value.
              '';
            };

            exports = lib.mkOption {
              type = lib.types.listOf lib.types.raw;
              default = [ ];
              description = lib.literalMD ''
                Rumor `exports` specification value.
              '';
            };
          };
        };
      };

      config = {
        defaults =
          { config, ... }:
          {
            imports = [
              inputs.sops-nix.nixosModules.default
              self.nixosModules.rumor
            ];

            config = lib.mkIf (config.rumor != null) {
              sops.defaultSopsFile = "${secrets}/${config.dot.host.name}/secrets.yaml";
              sops.age.keyFile = "/etc/sops/secrets.age";
              environment.etc."sops/secrets.age".source = "${secrets}/${config.dot.host.name}/secrets.age";
            };
          };
      };
    };
}
