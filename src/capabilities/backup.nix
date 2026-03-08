let
  backupSubmodule =
    { lib, config, ... }:
    let
      description = ''
        This should create a folder
        containing the unencrypted and uncompressed ${config.backupType} backup
        inside the current working directory.
      '';
    in
    {
      options = {
        scripts = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = ''
            Scripts to execute as part of the backup.

            ${description}
          '';
        };

        files = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = ''
            Files to execute as part of the backup.

            ${description}
          '';
        };

        backupType = lib.mkOption {
          type = lib.types.str;
          internal = true;
          description = ''Backup type'';
        };
      };
    };

  restoreSubmodule =
    { lib, config, ... }:
    let
      description = ''
        This should use a folder
        containing the unencrypted and uncompressed ${config.restoreType} backup
        inside the current working directory.
      '';
    in
    {
      options = {
        scripts = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = ''
            Scripts to execute as part of the restore.

            ${description}
          '';
        };

        files = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = ''
            Files to execute as part of the restore.

            ${description}
          '';
        };

        restoreType = lib.mkOption {
          type = lib.types.str;
          internal = true;
          description = ''Restore type'';
        };
      };
    };

  commonModule =
    { lib, ... }:
    {
      options.dot = {
        backup = {
          physical = lib.mkOption {
            description = ''Physical backup'';
            default = { };
            type = lib.types.submodule {
              imports = [ backupSubmodule ];
              backupType = "physical";
            };
          };

          logical = lib.mkOption {
            description = ''Logical backup'';
            default = { };
            type = lib.types.submodule {
              imports = [ backupSubmodule ];
              backupType = "logical";
            };
          };
        };

        restore = {
          physical = lib.mkOption {
            description = ''Physical restore'';
            default = { };
            type = lib.types.submodule {
              imports = [ restoreSubmodule ];
              restoreType = "physical";
            };
          };

          logical = lib.mkOption {
            description = ''Logical restore'';
            default = { };
            type = lib.types.submodule {
              imports = [ restoreSubmodule ];
              restoreType = "logical";
            };
          };
        };
      };
    };
in
{
  flake.nixosModules.capabilities-backup = {
    imports = [ commonModule ];
  };

  flake.homeModules.capabilities-backup =
    { osConfig, ... }:
    {
      imports = [ commonModule ];

      dot.backup = osConfig.dot.backup;
    };
}
