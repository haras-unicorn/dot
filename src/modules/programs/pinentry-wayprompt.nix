{
  machines.nixosModules.pinentry-wayprompt =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      hardware = config.dot.hardware;

      package =
        if hardware.graphics then
          if hardware.wayland then pkgs.wayprompt else pkgs.pinentry-qt
        else
          pkgs.pinentry-curses;
    in
    {
      options.dot = {
        pinentry = {
          package = lib.mkOption {
            type = lib.types.package;
            internal = true;
          };
        };
      };

      config = {
        dot.pinentry.package = package;

        dot.commands.pinentry = config.dot.pinentry.package;
      };
    };

  machines.homeModules.pinentry-wayprompt =
    {
      osConfig,
      pkgs,
      lib,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;

      processor = pkgs.writeShellApplication {
        name = "pinentry-processor";
        text = ''
          echo GETPIN \
            | ${lib.getExe osConfig.dot.pinentry.package} \
            | grep '^D ' \
            | cut -c3-
        '';
      };
    in
    {
      dot.processing.sources.pinentry = {
        note = "Capture a secure string (e.g. password or pin or key)";
        tags = [
          "password"
          "pin"
          "key"
          "secure"
          "string"
          "text"
        ];
        output = "text/plain";
        package = processor;
      };

      programs.wayprompt = lib.mkIf (hardware.wayland && hardware.graphics) {
        enable = true;
        package = osConfig.dot.pinentry.package;
      };
    };
}
