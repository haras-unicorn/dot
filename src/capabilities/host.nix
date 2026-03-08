let
  common =
    { lib, ... }:
    {
      options.dot = {
        host = {
          name = lib.mkOption {
            type = lib.types.str;
            description = ''
              Name of the host.
            '';
          };
          ip = lib.mkOption {
            type = lib.types.str;
            description = ''
              Host IP.
            '';
          };
          interface = lib.mkOption {
            type = lib.types.str;
            description = ''
              Host network interface.
            '';
          };
          hardware = lib.mkOption {
            type = lib.types.path;
            description = ''
              Host hardware information file path.
            '';
          };
          secrets = lib.mkOption {
            type = lib.types.path;
            description = ''
              Host encrypted secret file path.
            '';
          };
          user = lib.mkOption {
            type = lib.types.str;
            description = ''
              Main host user name.
            '';
          };
          group = lib.mkOption {
            type = lib.types.str;
            description = ''
              Main host group name.
            '';
          };
          uid = lib.mkOption {
            type = lib.types.ints.unsigned;
            description = ''
              Main host user id.
            '';
          };
          gid = lib.mkOption {
            type = lib.types.ints.unsigned;
            description = ''
              Main host group id.
            '';
          };
          home = lib.mkOption {
            type = lib.types.path;
            description = ''
              Main host user home path.
            '';
          };
          pass = lib.mkOption {
            type = lib.types.bool;
            description = ''
              Whether the host uses a generated password.
            '';
          };
          version = lib.mkOption {
            type = lib.types.str;
            description = ''
              Host system version.
            '';
          };
          hosts = lib.mkOption {
            type = lib.types.listOf lib.types.raw;
            default = [ ];
            description = ''
              All host configurations.
            '';
          };
        };
      };
    };
in
{
  flake.nixosModules.capabilities-host = {
    imports = [ common ];
  };

  flake.homeModules.capabilities-host = {
    imports = [ common ];
  };
}
