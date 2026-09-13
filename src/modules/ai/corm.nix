{ inputs, selfLib, ... }:

{
  machines.nixosModules.corm =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      hardware = config.dot.hardware;

      disabledTools = [
        "github__actions_run_trigger"
        "github__get_teams"
        "github__get_team_members"
        "github__list_notifications"
        "github__get_notification_details"
        "github__dismiss_notification"
        "github__mark_all_notifications_read"
        "github__manage_notification_subscription"
        "github__manage_repository_notification_subscription"
        "github__projects_get"
        "github__projects_list"
        "github__projects_write"
        "github__list_starred_repositories"
        "github__star_repository"
        "github__unstar_repository"
        "github__list_repository_collaborators"
      ];
    in
    {
      imports = [ inputs.corm.nixosModules.corm ];

      config = lib.mkIf hardware.cuda {
        corm = {
          enable = true;

          settings.tools = lib.subtractLists disabledTools (
            builtins.fromJSON (builtins.readFile (inputs.corm.outPath + "/src/nix/services/tools.json"))
          );

          gpu-provider = {
            enable = true;
            model = pkgs.cormPackages.qwen-3-8-flash-next-iq2-xs;
          };

          remote-provider = {
            enable = true;
            baseUrl = selfLib.openrouter.profiles.default.url;
            model = selfLib.openrouter.profiles.default.model;
          };

          omw = {
            agent = "corm";
            environmentFile = "/etc/corm/.env";
          };
        };

        systemd.services.omw.script = lib.mkBefore ''
          export OMW__MEMORY__corm__corm_config_prompt="$(cat /etc/corm/prompt.md)"
        '';
      };
    };
}
