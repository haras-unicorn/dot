{
  libAttrs.test.modules.commands =
    {
      specialArgs,
      config,
      lib,
      nodes,
      nodea,
      ...
    }:
    let
      cfg = config.dot.test.commands;

      textType = lib.types.oneOf [
        lib.types.str
        (lib.types.listOf lib.types.str)
        (lib.types.functionTo (lib.types.either lib.types.str (lib.types.listOf lib.types.str)))
      ];
    in
    {
      options.dot.test = {
        commands = {
          enable = lib.mkEnableOption "Test commands";

          prefix = lib.mkOption {
            type = textType;
            default = "start_all()";
            description = "Test script prefix";
          };

          perNode = lib.mkOption {
            type = lib.types.listOf (textType);
            default = [ ];
            description = ''
              Test script commands that are executed like:

              (c1-n1)
              (c1-n2)
              (c1-n3)
              ...

              (c2-n1)
              (c2-n2)
              (c2-n3)
              ...

              ...
            '';
          };

          suffix = lib.mkOption {
            type = textType;
            default = "";
            description = "Test script suffix";
          };
        };
      };

      config = lib.mkIf cfg.enable {
        testScript =
          let
            args = specialArgs // {
              inherit lib nodes nodea;
            };

            fixText =
              defaultArg: args: evaluatesToText:
              let
                evaluatesToTextCalled =
                  if lib.isFunction evaluatesToText then
                    if lib.functionArgs evaluatesToText == { } then evaluatesToText defaultArg else evaluatesToText args
                  else
                    evaluatesToText;
              in
              if builtins.isList evaluatesToTextCalled then
                builtins.concatStringsSep "\n" evaluatesToTextCalled
              else
                evaluatesToTextCalled;

            prefix = fixText nodes args cfg.prefix;

            content = builtins.concatStringsSep "\n" (
              lib.flatten (
                builtins.map (
                  command:
                  (builtins.map (node: ''
                    command_node = ${node.dot.host.name}
                    ${fixText node (
                      args
                      // {
                        inherit node;
                      }
                    ) command}
                  '') (builtins.attrValues nodes))
                ) cfg.perNode
              )
            );

            suffix = fixText nodes args cfg.suffix;
          in
          ''
            #### Test commands prefix
            print("Running test commands prefix...")

            ${prefix}


            #### Test commands content
            print("Running test commands content...")

            ${content}


            #### Test commands suffix
            print("Running test commands suffix...")

            ${suffix}
          '';
      };
    };
}
