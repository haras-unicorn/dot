{ selfLib, ... }:

{
  self.homeModules.direnv.value =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      retention = builtins.toString selfLib.gc.retentionDays;

      # NOTE: a project counts as active when the reflog of its git HEAD moved
      # (commit, checkout, pull, rebase). Anything that is not a git
      # repository is left alone, because nothing says it is inactive
      direnvGc = pkgs.writeShellApplication {
        name = "direnv-gc";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.git
          pkgs.nix
        ];
        text = ''
          dry_run=false
          if [ "$1" = "--dry-run" ]; then
            dry_run=true
            shift
          fi
          max_age=$(($1 * 24 * 60 * 60))
          now="$(date +%s)"

          roots="$(nix-store --gc --print-roots)"
          declare -A direnv_dirs
          while IFS= read -r line; do
            root="''${line%% -> *}"
            root="''${root#\"}"
            root="''${root%\"}"
            case "$root" in
              */.direnv/*) direnv_dirs["''${root%%/.direnv/*}/.direnv"]=1 ;;
              *) ;;
            esac
          done <<< "$roots"

          for direnv_dir in "''${!direnv_dirs[@]}"; do
            [ -d "$direnv_dir" ] || continue
            project="$(dirname "$direnv_dir")"
            activity="$(git -C "$project" rev-parse \
              --path-format=absolute --git-path logs/HEAD)" || continue
            if [ ! -e "$activity" ]; then
              activity="$(git -C "$project" rev-parse \
                --path-format=absolute --git-path HEAD)"
            fi
            [ -e "$activity" ] || continue

            age=$((now - $(stat -c %Y "$activity")))
            if [ "$age" -le "$max_age" ]; then
              continue
            fi

            inactive_days=$((age / 60 / 60 / 24))
            if [ "$dry_run" = true ]; then
              echo "would remove $direnv_dir, inactive for $inactive_days days"
            else
              echo "removing $direnv_dir, inactive for $inactive_days days"
              rm -rf -- "$direnv_dir"
            fi
          done
        '';
      };
    in
    {
      programs.direnv.enable = true;
      programs.direnv.nix-direnv.enable = true;
      programs.direnv.config.whitelist.prefix = [ config.xdg.userDirs.projects ];

      home.packages = [ direnvGc ];

      systemd.user.services.direnv-gc = {
        Unit.Description = "Remove direnv roots of inactive projects";
        Service = {
          Type = "oneshot";
          ExecStart = "${lib.getExe direnvGc} ${retention}";
        };
      };

      systemd.user.timers.direnv-gc = {
        Unit.Description = "Remove direnv roots of inactive projects";
        Timer = {
          OnCalendar = "daily";
          Persistent = true;
        };
        Install.WantedBy = [ "timers.target" ];
      };
    };
}
