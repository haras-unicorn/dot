{
  libAttrs.test.modules.disabled-service =
    { config, lib, ... }:
    let
      cfg = config.dot.test.disabledService;
    in
    {
      options.dot.test = {
        disabledService = {
          enable = lib.mkEnableOption "Test disabled service";

          name = lib.mkOption {
            type = lib.types.str;
            description = "Name of service";
          };

          config = lib.mkOption {
            type = lib.types.str;
            description = "Path to config";
          };

          module = lib.mkOption {
            type = lib.types.deferredModule;
            description = "Module for the test machine";
          };
        };
      };

      config = lib.mkIf cfg.enable {
        nodes.machine = cfg.module;
        testScript = ''
          start_all();

          machine.fail("systemctl is-enabled ${cfg.name}");

          machine.fail("test -d ${cfg.config}");
        '';
      };
    };
}
