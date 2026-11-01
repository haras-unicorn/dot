{ inputs, selfLib, ... }:

{
  self.nixosModules.corm.value =
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

        systemd.services.omw = {
          requiredBy = lib.mkForce [ ];
          wantedBy = lib.mkForce [ "corm.target" ];
        };

        systemd.services.omw.script = lib.mkBefore ''
          export OMW__MEMORY__corm__corm_config_prompt="$(cat /etc/corm/prompt.md)"
        '';

        # NOTE: the GPU is shared by Steam games, the GPU provider (~10 GB of
        # VRAM) and opencode-corm, which talks to the provider but conflicts
        # with omw. This picks what runs from the process table alone:
        #
        #   game running            -> everything down
        #   opencode-corm running   -> provider up, omw down
        #   neither                 -> provider and omw up
        #
        # Deliberately not part of corm.target, so it outlives it.
        systemd.services.corm-gpu-arbiter = {
          description = "Share the GPU between games, corm and opencode-corm";
          wantedBy = [ "multi-user.target" ];
          path = [
            pkgs.forkstat
            pkgs.procps
          ];
          serviceConfig = {
            Restart = "always";
            RestartSec = 1;
          };
          script = ''
            set -o pipefail

            running() {
              if pgrep -f "$1" > /dev/null; then
                echo true
              else
                echo false
              fi
            }

            # NOTE: a pending job wins over the state, because right after a
            # --no-block call the unit still looks like it is in its old state
            going_up() {
              local unit type
              while read -r _ unit type _; do
                if [ "$unit" = "$1" ]; then
                  if [ "$type" = stop ]; then
                    return 1
                  fi
                  return 0
                fi
              done < <(systemctl list-jobs --no-legend)

              case "$(systemctl is-active "$1" || true)" in
                active | activating) return 0 ;;
                *) return 1 ;;
              esac
            }

            reconcile() {
              local game="$1" opencode="$2"

              if [ "$game" = true ]; then
                if going_up corm.target; then
                  echo "Stopping corm.target due to it running and a steam game running"
                  systemctl stop --no-block corm.target
                fi
                return
              fi

              if ! going_up corm.target; then
                echo "Starting corm.target due to it not running and no steam game running"
                systemctl start --no-block corm.target
              fi

              if [ "$opencode" = true ]; then
                if going_up omw.service; then
                  echo "Stopping omw.service due to it running and opencode-corm running"
                  systemctl stop --no-block omw.service
                fi
              elif ! going_up omw.service; then
                echo "Starting omw.service due to it not running and opencode-corm not running"
                systemctl start --no-block omw.service
              fi
            }

            # NOTE: the first line is the pass at startup, the rest are events
            {
              echo start
              forkstat -l -r -e exec,exit \
                | grep --line-buffered -E 'reaper|opencode-corm'
            } | while read -r _; do
              game="$(running 'reaper SteamLaunch AppId=')"
              opencode="$(running '/bin/opencode-corm( |$)')"
              reconcile "$game" "$opencode"
            done
          '';
        };
      };
    };

  self.homeModules.corm.value =
    {
      config,
      lib,
      pkgs,
      osConfig,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;

      gpu = osConfig.corm.gpu-provider;
      model = gpu.model.passthru.modelName;

      opencodeConfig = lib.escapeShellArg (
        builtins.toJSON {
          enabled_providers = [ "corm" ];
          model = "corm/${model}";
          small_model = "corm/${model}";
        }
      );

      # NOTE: opencode layers this inline config over the home-manager one, so
      # this is the same opencode with only the corm provider enabled. The
      # corm-gpu-arbiter service finds it by the name of this script.
      opencodeCorm = pkgs.writeShellApplication {
        name = "opencode-corm";
        runtimeInputs = [ config.programs.opencode.package ];
        # NOTE: the quotes in the JSON are meant literally
        excludeShellChecks = [
          "SC2089"
          "SC2090"
        ];
        text = ''
          OPENCODE_CONFIG_CONTENT=${opencodeConfig}
          export OPENCODE_CONFIG_CONTENT
          opencode "$@"
        '';
      };
    in
    lib.mkIf (hardware.cuda && hardware.editor) {
      home.packages = [ opencodeCorm ];

      programs.opencode.settings.provider.corm = {
        npm = "@ai-sdk/openai-compatible";
        name = "Corm GPU";
        options = {
          baseURL = "http://${gpu.host}:${builtins.toString gpu.port}/v1";
          apiKey = "corm";
        };
        models.${model} = {
          name = model;
          limit = {
            context = gpu.ctx;
            output = 8192;
          };
        };
      };
    };
}
