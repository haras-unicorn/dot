let
  host = "127.0.0.1";
  port = 8085;
in
{
  self.lib.deprecated.nixosModules.open-webui =
    { config, lib, ... }:
    let
      hardware = config.dot.hardware;
    in
    lib.mkIf hardware.browser {
      dot.nixpkgs.allowUnfreePredicates = [
        (
          package:
          let
            name = lib.getName package;
          in
          name == "open-webui"
        )
      ];

      services.open-webui = {
        inherit
          host
          port
          ;

        enable = true;

        environment = {
          ANONYMIZED_TELEMETRY = "False";
          DO_NOT_TRACK = "True";
          SCARF_NO_ANALYTICS = "True";
        };

        environmentFile = "/etc/open-webui/.env";
      };
    };

  self.lib.deprecated.homeModules.open-webui =
    { osConfig, lib, ... }:
    let
      hardware = osConfig.dot.hardware;

      openWebuiWeb = osConfig.dot.programs.chromium.launch {
        name = "open-webui";
        address = "http://${host}:${builtins.toString port}";
      };
    in
    {
      xdg.desktopEntries.open-webui = lib.mkIf hardware.browser {
        name = "OpenWebUI";
        exec = lib.getExe openWebuiWeb;
        terminal = false;
      };
    };
}
