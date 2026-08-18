{
  machines.nixosModules.umu-launcher =
    { pkgs, lib, ... }:
    lib.mkIf (pkgs.stdenv.hostPlatform.system == "x86_64-linux") {
      programs.steam.extraCompatPackages = [
        pkgs.proton-ge-bin
      ];
    };

  machines.homeModules.umu-launcher =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      nushell = pkgs.nushell;

      umuScriptText = pkgs.writeScriptBin "umu.nu" ''
        #!${nushell}

        let data = $"${config.xdg.dataHome}/umu"
        let prefixes = $"($data)/prefixes"
        let index = $"($data)/prefixes.json"

        # Display help for the umu TUI
        def "main" []: nothing -> nothing {
          nu $"($env.FILE_PWD)/umu.nu" --help
        }

        # Add umu prefix
        def "main add" []: nothing -> nothing {
          let id = (
            gum input
              --placeholder "Type the prefix ID you want to add"
          )

          let installer = (
            gum file
              --file
              --padding "5 4"
              --header "Pick the installer executable"
              $env.HOME
          )

          (script run umu $id $installer
            | complete
            | script handle result "installer")

          let exe = (
            gum file
              --file
              --padding "5 4"
              --header "Pick the prefix executable"
              $"($prefixes)/($id)"
          )

          let data = { exe: $exe }

          if not ($index | path exists) { { } } else { open $index }
            | upsert $id $data
            | save -f $index
        }

        # Select and run umu prefix
        def "main select" []: nothing -> nothing {
          if not ($index | path exists) {
            { } | to json | save -f $index
          }

          let ids = (
            (if not ($index | path exists) { { } } else { open $index }
              | transpose key value | get key)
              ++ (ls $prefixes | get name | path basename)
          ) | uniq
          if ($ids | is-empty) {
            print -e "No prefix ID's to select from."
            print -e "Please use the add command to add a new prefix."
            exit 1
          }

          let id = (
            $ids
              | str join "\n"
              | gum choose
                  --header "Pick the prefix ID"
          )

          mut data = { }
          if ($data | is-empty) and ($index | path exists) {
            $index | open | get --optional $id
          }

          if ($data | is-empty) and ($"($prefixes)/($id)" | path exists) {
            let exe = (
              gum file
                --file
                --padding "5 4"
                --header "Pick the prefix executable"
                $"($prefixes)/($id)"
            )
            $data = { exe: $exe }
            if not ($index | path exists) { { } } else { open $index }
              | upsert $id $data
              | save -f $index
          }

          if ($data | is-empty) {
            print -e $"Prefix ID '($id)' picked but no index record or exiting prefix found."
            exit 1
          }

          (script run umu $id $data.exe
            | complete
            | script handle result "Prefix executable execution")
        }

        def --wrapped "script run umu" [id: string, path: string, ...args: string] {
          let prefix = $"($prefixes)/($id)"
          with-env {
            GAMEID: $id
            WINEPREFIX: $prefix
          } {
            mkdir $prefix
            umu-run $path ...($args)
          }
        }

        def "script handle result" [command: string] {
          let result = $in
          if $result.exit_code != 0 {
            print -e $"($command) failed."
            print -e $"Exit code: ($result.exit_code)"
            print -e $"Stdout:\n($result.stdout)\n"
            print -e $"Stderr:\n($result.stderr)\n"
            exit 1
          }
          return $result.stdout
        }
      '';

      umuScript = pkgs.writeShellApplication {
        name = "umu";
        runtimeInputs = [
          nushell
          pkgs.umu-launcher
          pkgs.gum
        ];
        runtimeEnv = {
          SDL_VIDEODRIVER = "windows";
          PROTONPATH = lib.getOutput "steamcompattool" pkgs.proton-ge-bin;
        };
        text = ''nu "${umuScriptText}/bin/umu.nu" "$@"'';
      };
    in
    lib.mkIf (pkgs.stdenv.hostPlatform.system == "x86_64-linux") {
      home.packages = [
        umuScript
      ];

      programs.lutris.extraPackages = [
        pkgs.umu-launcher
      ];
      programs.lutris.protonPackages = [
        pkgs.proton-ge-bin
      ];
    };
}
